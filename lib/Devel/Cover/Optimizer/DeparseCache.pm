package Devel::Cover::Optimizer::DeparseCache;
use strict;
use warnings;

use Devel::Cover::Optimizer::DeparseCache::Seen ();

# Optimization 2: cache deparse walks for preloaded CVs.
#
# Only useful under forkprove. When Devel::Cover processes a CV, it walks the
# compiled op tree via B::Deparse to discover statements, branches, and
# conditions, then calls add_*_cover for each one. Under forkprove, every child
# inherits the same preloaded CVs with identical op trees, so the deparse walk
# discovers the same structure in every child. This optimization runs the walk
# once in the parent and replays the discovered add_*_cover calls in children.
sub install {
    my (%args) = @_;
    my $debug = $args{debug} || 0;

    require B;
    require B::Deparse;
    require PadWalker;

    if (${^GLOBAL_PHASE} eq 'RUN') {
        # Loaded at runtime, for example forkprove's -M flags after INIT passed.
        # %Coverage is already expanded by CHECK, so we can build immediately.
        _install_deparse_cache($debug);
    } else {
        # Loaded at compile time via PERL5OPT or use. %Coverage is still
        # (all => 1); defer to INIT, after all CHECK blocks have run.
        my $debug_literal = 0 + $debug;
        # String eval registers INIT only when this option is enabled, and avoids
        # compiling an INIT block after INIT has already passed.
        my $ok = eval "INIT { Devel::Cover::Optimizer::DeparseCache::_install_deparse_cache($debug_literal) } 1";
        die $@ unless $ok;
    }

    return;
}

sub _install_deparse_cache {
    my ($debug) = @_;

    my $install_start = $debug ? _time() : 0;
    warn "  [cache] install: starting in phase ${^GLOBAL_PHASE}\n" if $debug;

    my $rpt_co = PadWalker::closed_over(\&Devel::Cover::_report);

    # %Coverage starts as (all => 1) and gets expanded to per-type flags during
    # CHECK. Building before expansion produces wrong results.
    my $Coverage_ref = PadWalker::closed_over(\&Devel::Cover::add_statement_cover)->{'%Coverage'};
    if (exists $Coverage_ref->{all}) {
        die "Devel::Cover::Optimizer: cache called before %Coverage expanded (loaded too early?)\n";
    }

    # Populate @Cvs with currently loaded CVs from selected packages.
    my $check_files_start = $debug ? _time() : 0;
    Devel::Cover::check_files();
    my $Cvs_ref       = $rpt_co->{'@Cvs'};
    my $Subs_only_ref = $rpt_co->{'$Subs_only'};
    if ($debug) {
        warn sprintf "  [cache] check_files: %.3fs, %d CVs selected\n", _time() - $check_files_start, scalar @$Cvs_ref;
    }

    my %cache;
    my %filtered_cache;
    my $build_start = $debug ? _time() : 0;
    my ($Seen_ref, $private_seen_owner) = _build_deparse_cache(
        \%cache,
        \%filtered_cache,
        $Cvs_ref,
        $Subs_only_ref,
        $debug,
    );
    my $build_elapsed = $debug ? _time() - $build_start : 0;

    warn "  [cache] install: no cache entries built\n" if $debug && !%cache && !%filtered_cache;
    return unless %cache || %filtered_cache;

    my $seen_replay = Devel::Cover::Optimizer::DeparseCache::Seen::start_replay($Seen_ref);
    # Cache hits update these plain backing hashrefs directly. We only tie
    # %Seen inner buckets when a real uncached deparse walk runs.
    my $Seen_data = $seen_replay->data;

    my $Structure_ref = PadWalker::closed_over(\&Devel::Cover::add_statement_cover)->{'$Structure'};
    my $get_cover_co = PadWalker::closed_over(\&Devel::Cover::get_cover);
    my $Sub_name_ref = $get_cover_co->{'$Sub_name'};
    my $orig_get_cover = \&Devel::Cover::get_cover;
    my $orig_deparse_sub = \&B::Deparse::deparse_sub;

    my $cache_hits          = 0;
    my $cache_misses        = 0;
    my $cache_stale_misses  = 0;
    my $cache_seen_misses   = 0;
    my $private_invalidations = 0;
    my %cache_seen_miss_reason;
    my $replay_calls   = 0;
    my $replay_time    = 0;
    my $uncached_time  = 0;
    my $filtered_hits   = 0;
    my $filtered_stale  = 0;

    no warnings 'redefine';
    *Devel::Cover::get_cover = sub {
        my $cv = $_[0];
        if (@_ == 1 && $$Structure_ref && ref($cv) && $cv->isa("B::CV") && exists $filtered_cache{$$cv}) {
            my $entry = $filtered_cache{$$cv};
            my $root = $cv->ROOT;
            if (${$cv->START} == $entry->{start} && ref($root) && $$root == $entry->{root}) {
                # This replays the state left by stock get_cover() immediately
                # before its observed early return from the use_file() check.
                $$Sub_name_ref = $entry->{final_sub_name};
                ($Devel::Cover::File, $Devel::Cover::Line) = ($entry->{final_file}, $entry->{final_line});
                $filtered_hits++ if $debug;
                return;
            }
            $filtered_stale++ if $debug;
        }

        return $orig_get_cover->(@_);
    };

    *B::Deparse::deparse_sub = sub {
        my $cv = $_[1];
        my $is_cover_get_cover = 0;
        if ($$Structure_ref && ref($cv) && $cv->isa("B::CV")) {
            # B::Deparse is a public module. Only replace Devel::Cover's
            # get_cover() path; unrelated deparse callers should see stock behavior.
            # caller(1) is the frame that invoked this deparse_sub wrapper.
            my $caller_sub = (caller(1))[3] // "";
            $is_cover_get_cover = $caller_sub eq "Devel::Cover::get_cover";
        }

        if ($is_cover_get_cover && exists $cache{$$cv}) {
            my $entry = $cache{$$cv};
            if (${$cv->START} == $entry->{start} && ${$cv->ROOT} == $entry->{root}) {
                # CV identity is not enough: Devel::Cover's %Seen is global
                # duplicate-suppression state, so a child-only miss can change
                # whether the cached call stream is still valid.
                my $seen_mismatch = Devel::Cover::Optimizer::DeparseCache::Seen::validate_entry($Seen_data, $entry);

                if (defined $seen_mismatch) {
                    if ($debug) {
                        $cache_seen_misses++;
                        $cache_seen_miss_reason{$seen_mismatch}++;
                    }
                } else {
                    my $replay_start = $debug ? _time() : 0;
                    $cache_hits++ if $debug;
                    $replay_calls += scalar @{$entry->{calls}} if $debug;

                    for my $c (@{$entry->{calls}}) {
                        local $Devel::Cover::File = $c->{file};
                        local $Devel::Cover::Line = $c->{line};
                        $c->{func}->(@{$c->{args}});
                    }

                    Devel::Cover::Optimizer::DeparseCache::Seen::apply_entry_sets($Seen_data, $entry);
                    $entry->{replayed} = 1;

                    # Stock get_cover() leaves $File/$Line as state for later
                    # CVs. Cache entries are only built for CVs whose initial
                    # get_cover() location was established, so this is a real
                    # CV-local final state rather than inherited parent state.
                    ($Devel::Cover::File, $Devel::Cover::Line) = ($entry->{final_file}, $entry->{final_line});

                    $replay_time += _time() - $replay_start if $debug;
                    return "";
                }
            } else {
                $cache_stale_misses++ if $debug;
            }
        }

        if ($is_cover_get_cover) {
            # Stale cache entries are counted above as stale, then here as
            # misses too, because they fall back to the uncached deparse path.
            my $uncached_start = $debug ? _time() : 0;
            $cache_misses++ if $debug;

            # Run the stock deparse path, but collect false-to-true %Seen writes
            # so cached entries with private assumptions can be invalidated.
            $seen_replay->start_delta;
            my ($deparsed, $err);
            my $ok = eval {
                $deparsed = $orig_deparse_sub->(@_);
                1;
            };
            $err = $@;
            my $delta = $seen_replay->finish_delta;

            my $invalidated = Devel::Cover::Optimizer::DeparseCache::Seen::invalidate_private_owners(
                $private_seen_owner,
                $delta,
            );
            $private_invalidations += $invalidated if $debug;
            $uncached_time += _time() - $uncached_start if $debug;

            die $err unless $ok;
            return $deparsed;
        }

        return $orig_deparse_sub->(@_);
    };

    if ($debug) {
        warn sprintf "  [cache] install: ready in %.3fs (build %.3fs, entries %d, filtered %d)\n",
            _time() - $install_start, $build_elapsed, scalar keys %cache, scalar keys %filtered_cache;
    }

    if ($debug) {
        my $orig_report = \&Devel::Cover::report;
        my $log_replay_summary = sub {
            my ($report_start) = @_;
            warn sprintf(
                "  [cache] replay: hits=%d misses=%d stale=%d seen_misses=%d (zero=%d nonzero=%d private=%d replayed=%d) calls=%d filtered_hits=%d filtered_stale=%d replay_time=%.3fs uncached_time=%.3fs report_time=%.3fs\n",
                $cache_hits,
                $cache_misses,
                $cache_stale_misses,
                $cache_seen_misses,
                $cache_seen_miss_reason{requires_zero} // 0,
                $cache_seen_miss_reason{requires_nonzero} // 0,
                $cache_seen_miss_reason{private} // 0,
                $cache_seen_miss_reason{replayed} // 0,
                $replay_calls,
                $filtered_hits,
                $filtered_stale,
                $replay_time,
                $uncached_time,
                _time() - $report_start,
            );
            warn sprintf(
                "  [cache] replay detail: private_invalidations=%d\n",
                $private_invalidations,
            ) if $debug >= 2;
        };

        *Devel::Cover::report = sub {
            my $report_start = _time();
            my $wantarray = wantarray;
            if ($wantarray) {
                my @ret = $orig_report->(@_);
                $log_replay_summary->($report_start);
                return @ret;
            } elsif (defined $wantarray) {
                my $ret = $orig_report->(@_);
                $log_replay_summary->($report_start);
                return $ret;
            } else {
                $orig_report->(@_);
                $log_replay_summary->($report_start);
                return;
            }
        };
    }

    return;
}

# Build the deparse cache by running get_cover() on preloaded CVs in the parent
# process. For each CV, record the add_*_cover calls the deparse walk produces.
#
# CVs are walked in the same order as stock _report: main_cv, begin_av,
# check_av, get_ends, then @Cvs. %Seen accumulates persistently across CVs,
# matching stock behavior. During cache building, known inner %Seen buckets are
# tied so each CV records the true/false assumptions it made and the entries it
# changed from false to true. After the build we split those keys into shared
# keys, which are checked/written on replay, and private keys, which are written
# immediately but only invalidated if uncached deparse reaches them before their
# cached owner replays.
sub _build_deparse_cache {
    my ($cache, $filtered_cache, $Cvs_ref, $Subs_only_ref, $debug) = @_;

    my $build_start = $debug ? _time() : 0;
    warn "  [cache] build: locating Devel::Cover state\n" if $debug >= 2;

    my $asc_co = PadWalker::closed_over(\&Devel::Cover::add_statement_cover);
    my $gc_co  = PadWalker::closed_over(\&Devel::Cover::get_cover);
    my $rpt_co = PadWalker::closed_over(\&Devel::Cover::_report);
    my $dep_co = PadWalker::closed_over(\&Devel::Cover::deparse);
    my $uf_co  = PadWalker::closed_over(\&Devel::Cover::use_file);

    my $Structure_ref = $asc_co->{'$Structure'};
    my $Coverage_ref  = $rpt_co->{'$Coverage'};
    my $Run_ref       = $asc_co->{'%Run'};
    my $Sub_name_ref  = $gc_co->{'$Sub_name'};
    my $Sub_count_ref = $gc_co->{'$Sub_count'};
    my $Seen_ref      = $dep_co->{'%Seen'};
    my $Pod_ref       = $gc_co->{'$Pod'};
    my $Pod_cache_ref = $gc_co->{'%Pod'};
    my $Select_re_ref = $uf_co->{'@Select_re'} || [];
    my $Ignore_re_ref = $uf_co->{'@Ignore_re'} || [];
    my $Inc_re_ref    = $uf_co->{'@Inc_re'}    || [];

    # Save originals so we can restore after cache building.
    my $save_Structure = $$Structure_ref;
    my $save_Coverage  = $$Coverage_ref;
    my %save_Run       = %$Run_ref;
    my $save_Sub_count = $$Sub_count_ref;
    my $save_Pod       = $Pod_ref ? $$Pod_ref : undef;
    my %save_Pod_cache = $Pod_cache_ref ? %$Pod_cache_ref : ();
    my %save_Seen      = %$Seen_ref;

    require Devel::Cover::DB::Structure;
    my @collected = Devel::Cover::get_coverage();
    warn "  [cache] build: creating temporary structure for " . join(",", @collected) . "\n" if $debug >= 2;

    # Cache building runs real get_cover(), which has side effects on Structure,
    # Coverage, Run, Sub_count, Seen, and POD state. Swap in disposable state so
    # the parent prepass cannot leak coverage data into the real report.
    my $tmp_base = "/tmp/dcf_cache_$$";
    $$Structure_ref = Devel::Cover::DB::Structure->new(base => $tmp_base);
    $$Structure_ref->add_criteria(@collected);
    $$Coverage_ref  = {};
    %$Run_ref       = (collected => \@collected);
    $$Sub_count_ref = {};

    my @calls;
    my $orig_add_stmt = \&Devel::Cover::add_statement_cover;
    my $orig_add_br   = \&Devel::Cover::add_branch_cover;
    my $orig_add_cond = \&Devel::Cover::add_condition_cover;
    my $orig_get_location = \&Devel::Cover::get_location;
    my %seen_touches;
    my %stats = (
        candidates   => 0,
        cached       => 0,
        calls        => 0,
        duplicates   => 0,
        empty        => 0,
        failed       => 0,
        filtered     => 0,
        invalid_cv   => 0,
        no_location  => 0,
        main         => 0,
        no_root      => 0,
        processed    => 0,
        seen_nonzero => 0,
        seen_sets    => 0,
        seen_only    => 0,
        seen_zero    => 0,
    );
    my $seen_tracker;
    my $initial_location_set;
    my $had_get_location_call;

    eval {
        no warnings 'redefine';
        no strict 'refs';

        # Capture $File and $Line for every call type. Several add_*_cover
        # functions read the package globals in addition to, or instead of,
        # explicit arguments.
        local *Devel::Cover::add_statement_cover = sub {
            push @calls, {
                func => $orig_add_stmt,
                args => [@_],
                file => $Devel::Cover::File,
                line => $Devel::Cover::Line,
            };
            $orig_add_stmt->(@_);
        };
        local *Devel::Cover::add_branch_cover = sub {
            push @calls, {
                func => $orig_add_br,
                args => [@_],
                file => $Devel::Cover::File,
                line => $Devel::Cover::Line,
            };
            $orig_add_br->(@_);
        };
        local *Devel::Cover::add_condition_cover = sub {
            push @calls, {
                func => $orig_add_cond,
                args => [@_],
                file => $Devel::Cover::File,
                line => $Devel::Cover::Line,
            };
            $orig_add_cond->(@_);
        };
        local *Devel::Cover::get_location = sub {
            # Only the first get_location() call, when it is the direct
            # get_cover() -> get_location($start) call, proves this CV
            # established its own location before deparse replayable
            # branch/condition calls. If any earlier get_location() happened,
            # this is no longer the initial location for the CV.
            # This relies on stock get_cover() making get_location($start) its
            # only direct get_location() call, before deparse_sub().
            my $caller_sub = (caller(1))[3] // "";
            my $is_initial_get_cover_location =
                $caller_sub eq "Devel::Cover::get_cover"
                && !$had_get_location_call
                && $_[0]
                && $_[0]->can("file");

            $had_get_location_call = 1;

            my $ret = $orig_get_location->(@_);
            # Let stock get_location handle eval/#line normalization first; the
            # resulting non-empty $File is what stock get_cover will use for
            # use_file() and as the baseline for the deparse walk.
            $initial_location_set = 1
                if $is_initial_get_cover_location
                && defined $Devel::Cover::File
                && length $Devel::Cover::File;

            return $ret;
        };

        no warnings 'once';
        local $Devel::Cover::Collect = 1;

        %$Seen_ref = ();
        $seen_tracker = Devel::Cover::Optimizer::DeparseCache::Seen::start_build($Seen_ref);

        my @report_cvs;
        unless ($$Subs_only_ref) {
            push @report_cvs, ['main', B::main_cv(), B::main_root()];
            my @av_funcs = (\&B::begin_av);
            push @av_funcs, \&B::check_av if exists &B::check_av;
            push @av_funcs, \&Devel::Cover::get_ends;
            for my $av_func (@av_funcs) {
                my $av = $av_func->();
                next unless ref($av) && $av->isa("B::AV");
                push @report_cvs, map ['cv', $_], $av->ARRAY;
            }
        }
        push @report_cvs, map ['cv', $_], @$Cvs_ref;

        $stats{candidates} = scalar @report_cvs;
        if ($debug >= 2) {
            warn sprintf(
                "  [cache] build: processing %d report CV entries (%d from check_files)\n",
                $stats{candidates},
                scalar @$Cvs_ref,
            );
        }

        my $progress_every = 500;
        for my $item (@report_cvs) {
            $stats{processed}++;
            if ($debug >= 2 && $stats{processed} % $progress_every == 0) {
                warn sprintf(
                    "  [cache] build: progress %d/%d entries, %d cached\n",
                    $stats{processed},
                    $stats{candidates},
                    $stats{cached},
                );
            }

            @calls = ();
            $initial_location_set = 0;
            $had_get_location_call = 0;

            my $cv_start = $debug >= 3 ? _time() : 0;
            my $ok = eval {
                if ($item->[0] eq 'main') {
                    Devel::Cover::get_cover($item->[1], $item->[2]);
                } else {
                    Devel::Cover::get_cover($item->[1]);
                }
                1;
            };
            unless ($ok) {
                $stats{failed}++;
                warn "  [cache] get_cover failed: $@\n" if $debug;
                next;
            }

            my ($final_file, $final_line) = ($Devel::Cover::File, $Devel::Cover::Line);
            my $final_sub_name = $$Sub_name_ref;

            my $seen_trace = $seen_tracker->take_trace;
            my ($seen_zero, $seen_nonzero, $seen_sets) = Devel::Cover::Optimizer::DeparseCache::Seen::record_touches(
                $seen_trace,
                \%seen_touches,
                $stats{processed},
            );

            if ($item->[0] eq 'main') {
                $stats{main}++;
                if ($debug >= 3) {
                    warn sprintf(
                        "  [cache] build: main_cv calls=%d seen_sets=%d elapsed=%.3fs\n",
                        scalar @calls,
                        $seen_sets,
                        _time() - $cv_start,
                    );
                }
                next;
            }

            my $cv = $item->[1];
            unless (ref($cv) eq "B::CV" && $$cv) {
                $stats{invalid_cv}++;
                next;
            }
            if (exists $cache->{$$cv} || exists $filtered_cache->{$$cv}) {
                $stats{duplicates}++;
                next;
            }
            my $root = $cv->ROOT;
            unless (ref($root) && !$root->isa("B::NULL")) {
                $stats{no_root}++;
                next;
            }

            unless (
                @calls
                || Devel::Cover::Optimizer::DeparseCache::Seen::has_any(
                    $seen_trace->{sets_true},
                )
            ) {
                if ($initial_location_set
                    && defined $final_file
                    && length $final_file
                    && !Devel::Cover::use_file($final_file)
                    && _file_matches_rejecting_filter($final_file, $Select_re_ref, $Ignore_re_ref, $Inc_re_ref))
                {
                    # Stock get_cover() returned from its use_file() check
                    # before deparse_sub(). Replaying only the leaked state is
                    # enough; no structure, counts, POD, or %Seen effects happened.
                    $filtered_cache->{$$cv} = {
                        start          => ${$cv->START},
                        root           => $$root,
                        final_sub_name => $final_sub_name,
                        final_file     => $final_file,
                        final_line     => $final_line,
                    };
                    $stats{filtered}++;
                    next;
                }

                # No calls and no %Seen effects means replaying this CV cannot
                # affect later coverage discovery.
                $stats{empty}++;
                next;
            }
            unless ($initial_location_set) {
                # Locationless CVs inherit $File/$Line from the current report
                # state. Replaying the parent's inherited state can misattribute
                # branch/condition calls or change what later CVs inherit.
                $stats{no_location}++;
                next;
            }

            $cache->{$$cv} = {
                start   => ${$cv->START},
                root    => $$root,
                calls   => [@calls],
                occurrence => $stats{processed},
                seen_requires_zero    => $seen_trace->{requires_zero},
                seen_requires_nonzero => $seen_trace->{requires_nonzero},
                seen_sets_true        => $seen_trace->{sets_true},
                final_file => $final_file,
                final_line => $final_line,
            };
            $stats{cached}++;
            $stats{calls}        += scalar @calls;
            $stats{seen_zero}    += $seen_zero;
            $stats{seen_nonzero} += $seen_nonzero;
            $stats{seen_sets}    += $seen_sets;
            $stats{seen_only}++
                if !@calls
                && Devel::Cover::Optimizer::DeparseCache::Seen::has_any(
                    $seen_trace->{sets_true},
                );

            if ($debug >= 3) {
                warn sprintf(
                    "  [cache] build: cached CV %d/%d calls=%d seen_sets=%d elapsed=%.3fs\n",
                    $stats{processed},
                    $stats{candidates},
                    scalar @calls,
                    $seen_sets,
                    _time() - $cv_start,
                );
            }
        }

        1;
    };
    my $build_err = $@;

    # Restore Devel::Cover's lexicals before propagating any build failure. A
    # failed speculative cache build should leave the real report path intact.
    $seen_tracker->restore_plain if $seen_tracker;
    $$Structure_ref = $save_Structure;
    $$Coverage_ref  = $save_Coverage;
    %$Run_ref       = %save_Run;
    $$Sub_count_ref = $save_Sub_count;
    %$Seen_ref      = %save_Seen;
    $$Pod_ref       = $save_Pod       if $Pod_ref;
    %$Pod_cache_ref = %save_Pod_cache if $Pod_cache_ref;

    if ($build_err) {
        %$cache = ();
        die "Devel::Cover::Optimizer: cache build failed: $build_err";
    }

    die "Devel::Cover::Optimizer: unexpected disk write during cache build: $tmp_base\n"
        if -d $tmp_base;

    my ($private_seen_owner, $privacy_stats) = Devel::Cover::Optimizer::DeparseCache::Seen::split_private_shared(
        $cache,
        \%seen_touches,
    );

    if ($debug) {
        warn sprintf(
            "  [cache] build: cached %d/%d CVs in %.3fs (%d filtered, %d calls, %d seen-only)\n",
            $stats{cached},
            $stats{candidates},
            _time() - $build_start,
            $stats{filtered},
            $stats{calls},
            $stats{seen_only},
        );
    }
    if ($debug >= 2) {
        warn sprintf(
            "  [cache] build detail: processed=%d failed=%d main=%d duplicate=%d invalid=%d no_root=%d empty=%d filtered=%d no_location=%d seen_zero=%d seen_nonzero=%d seen_sets=%d private_zero=%d shared_zero=%d private_sets=%d shared_sets=%d\n",
            $stats{processed},
            $stats{failed},
            $stats{main},
            $stats{duplicates},
            $stats{invalid_cv},
            $stats{no_root},
            $stats{empty},
            $stats{filtered},
            $stats{no_location},
            $stats{seen_zero},
            $stats{seen_nonzero},
            $stats{seen_sets},
            $privacy_stats->{private_zero},
            $privacy_stats->{shared_zero},
            $privacy_stats->{private_sets},
            $privacy_stats->{shared_sets},
        );
    }

    return ($Seen_ref, $private_seen_owner);
}

sub _file_matches_rejecting_filter {
    my ($file, $Select_re_ref, $Ignore_re_ref, $Inc_re_ref) = @_;

    # use_file() has fallback and special-case rejection paths with extra
    # behavior. Only cache false returns attributable to configured rejecting
    # filters, preserving Devel::Cover's select-before-ignore precedence.
    # The caller already observed !use_file($file), so a selected file should
    # not reach here, but keep the precedence check explicit for safety.
    for my $re (@$Select_re_ref) { return 0 if $file =~ $re }
    for my $re (@$Ignore_re_ref) { return 1 if $file =~ $re }
    for my $re (@$Inc_re_ref)    { return 1 if $file =~ $re }

    return 0;
}

# Late imports do not affect bare `time` ops compiled earlier, so debug timing
# calls Time::HiRes directly while keeping the module off the non-debug path.
sub _time {
    require Time::HiRes;
    return Time::HiRes::time();
}

1;
