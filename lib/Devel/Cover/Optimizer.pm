package Devel::Cover::Optimizer;
use strict;
use warnings;

# Monkey-patches Devel::Cover to reduce END-block overhead when many
# third-party modules are loaded.
#
# Background: Devel::Cover runs _report() in every process's END block.
# _report() walks the entire Perl symbol table (every package, every
# sub) to find CVs (code values) that might need coverage, then runs
# get_cover() on each one. Even with tight +select/+ignore filters
# (e.g. +select,^lib,+ignore,^), the filtering happens too late: Devel::Cover
# has already done expensive B:: introspection and regex matching on
# every CV before rejecting non-matching ones. The more third-party
# modules a process has loaded, the more wasted work this causes.
#
# The overhead is worst under forkprove, where every forked child
# inherits the full preloaded symbol table, but it affects any
# Devel::Cover run proportional to the number of loaded modules.
#
# This module injects earlier filtering so we skip non-matching code
# before doing expensive work.
#
# Usage:
#   perl -MDevel::Cover=... -MDevel::Cover::Optimizer ...
#   perl -MDevel::Cover=... -MDevel::Cover::Optimizer=debug ...
#
# Options:
#   no_walksymtable        — disable optimization 1 (walksymtable replacement)
#   cache                  — pre-cache deparse walks for preloaded CVs (requires PadWalker)
#   debug                  — log all filtering decisions to STDERR


sub import {
    my ($class, @args) = @_;
    my %opts = map { $_ => 1 } @args;

    unless (defined $Devel::Cover::VERSION) {
        die "Devel::Cover::Optimizer: Devel::Cover is not loaded\n";
    }

    # Ensure $debug is 0/1 as it is interpolated into an eval
    my $debug = delete $opts{debug} ? 1 : 0;
    if ($debug) {
        warn "Devel::Cover::Optimizer: debug enabled (Perl $], Devel::Cover $Devel::Cover::VERSION"
            . ($B::Deparse::VERSION ? ", B::Deparse $B::Deparse::VERSION" : "")
            . ")\n";
    }

    my $no_walksymtable       = delete $opts{no_walksymtable};
    my $cache_mode            = delete $opts{cache};

    no warnings 'redefine';

    # --- Optimization 1: replace walksymtable with filtered version ---
    #
    # Devel::Cover's check_files() calls B::walksymtable to walk every
    # package in %main::, invoking B::GV::find_cv on each glob value
    # (GV). find_cv then calls use_file() per CV. With many loaded
    # modules this means tens of thousands of B:: method calls for CVs
    # that will be rejected anyway.
    #
    # B::walksymtable is pure Perl (not XS), and Devel::Cover imports
    # it into its own namespace. By replacing *Devel::Cover::walksymtable
    # we can intercept the entire symbol table walk and skip entire package
    # subtrees whose files don't match +select.
    #
    # Subtree pruning converts package names to module paths via %INC
    # (Foo::Bar:: → Foo/Bar.pm) and checks use_file(). Three signals
    # trigger descent into a package:
    #   (a) Its own .pm file matches use_file ("self-matched").
    #   (b) %must_descend — any selected file is nested under this
    #       package. Only records ancestor prefixes up to the first
    #       self-matching ancestor, since (c) handles the rest.
    #   (c) $ancestor_matched — an ancestor package's own .pm matched,
    #       propagated through recursion. Handles inline sub-packages
    #       (e.g. MyApp::Config::Defaults defined in Config.pm).
    #
    # LIMITATION: subtree pruning uses %INC keys to predict which
    # packages contain selected code. This assumes conventional module
    # layouts where the %INC key (Foo/Bar.pm) maps to the package name
    # (Foo::Bar). It can miss selected CVs when:
    #   - A selected file defines packages that don't match its %INC
    #     key (e.g. lib/Plugin.pm defines MyApp::Service::Foo)
    #   - A single selected file defines packages in unrelated
    #     namespaces
    #   - eval/source filters use #line to point CVs at selected files
    #     without corresponding %INC entries
    #   - Runtime symbol table manipulation installs selected subs into
    #     namespaces not derivable from %INC
    #
    # For conventional module layouts and broad exclusive selects like
    # +select,^lib,+ignore,^ this works correctly.
    #
    # Within descended packages, find_cv is called for every GV with a
    # CV — we do NOT filter individual CVs by file. Stock find_cv
    # inspects both the outer CV and its PADLIST for inner anonymous
    # CVs, which can be from different files (e.g. via #line). Skipping
    # find_cv based on the outer CV's file would miss selected inner CVs.

    if (!$no_walksymtable) {
        my %must_descend;

        # Can't use __SUB__ (requires 5.16 feature), so we name the ref.
        my $walk;
        $walk = sub {
            # $symref, $method, $recurse, $prefix match stock walksymtable's signature.
            # $ancestor_matched is ours: true when an ancestor's own %INC file matched use_file.
            my ($symref, $method, $recurse, $prefix, $ancestor_matched) = @_;
            no strict 'refs';
            $prefix = '' unless defined $prefix;

            # On the top-level call (prefix is empty), rebuild the
            # must-descend set and package cache from current %INC.
            unless (length $prefix) {
                %must_descend = ();
                for my $mod (keys %INC) {
                    next unless $mod =~ /\.pm$/;
                    next unless Devel::Cover::use_file($INC{$mod});
                    (my $pkg_path = $mod) =~ s/\.pm$//;
                    my @parts = split m{/}, $pkg_path;
                    my $pfx = '';
                    for my $part (@parts) {
                        $pfx .= "${part}::";
                        (my $pfx_mod = $pfx) =~ s/::$/.pm/;
                        $pfx_mod =~ s!::!/!g;
                        last if exists $INC{$pfx_mod} && Devel::Cover::use_file($INC{$pfx_mod});
                        $must_descend{$pfx} = 1;
                    }
                }
                if ($debug) {
                    my $total_inc = scalar keys %INC;
                    my $n = scalar keys %must_descend;
                    warn "  [walk] %INC: $total_inc entries, must_descend: $n prefixes\n";
                }
            }

            for my $sym (sort keys %$symref) {
                # Accessing a stash entry vivifies the glob — this matches what stock walksymtable does.
                my $dummy = $symref->{$sym};
                my $fullname = "*main::${prefix}${sym}";
                if ($sym =~ /::$/) {
                    my $pkg = $prefix . $sym;
                    # Guard against self-recursion into main:: and skip the synthetic "<none>::" package.
                    next if B::svref_2object(\*$pkg)->NAME eq "main::";
                    next if $pkg eq "<none>::";
                    # $recurse is Devel::Cover's dedup callback (!$seen_pkg{$_[0]}++).
                    next unless $recurse->($pkg);

                    (my $mod = $pkg) =~ s/::$/.pm/;
                    $mod =~ s!::!/!g;
                    my $self_matched = exists $INC{$mod} && Devel::Cover::use_file($INC{$mod});
                    my $descend = $self_matched || $must_descend{$pkg} || $ancestor_matched;
                    if ($debug) {
                        warn $descend ? "  [walk] descend $pkg\n" : "  [walk] skip subtree $pkg\n";
                    }
                    next unless $descend;

                    $walk->(\%$fullname, $method, $recurse, $pkg, $self_matched || $ancestor_matched);
                } else {
                    my $gv = B::svref_2object(\*$fullname);
                    my $cv = $gv->CV;
                    # $$cv is the internal pointer address — 0 means no CV is attached to this glob.
                    next unless $$cv;
                    if ($debug) {
                        my $file = _cv_file($cv) // '?';
                        warn "  [walk] find_cv ${prefix}${sym} ($file)\n";
                    }
                    $gv->$method();
                }
            }
        };
        no warnings 'once';
        *Devel::Cover::walksymtable = $walk;
    }

    # --- Optimization 2: cache deparse walks for preloaded CVs ---
    #
    # Only useful under forkprove. When Devel::Cover processes a CV
    # (subroutine), it walks the entire compiled op tree via
    # B::Deparse to discover which statements, branches, and
    # conditions exist — then calls add_statement_cover,
    # add_branch_cover, add_condition_cover for each one. These
    # add_*_cover functions look up runtime execution counts from
    # $Coverage (populated by Devel::Cover's runtime instrumentation)
    # and record them into the coverage database.
    #
    # Under forkprove, every child inherits the same preloaded CVs
    # with identical op trees. The deparse walk discovers the same
    # structure every time — only the runtime counts in $Coverage
    # differ per child. This means every child redundantly re-walks
    # the same op trees just to arrive at the same add_*_cover calls.
    #
    # This optimization runs the deparse walk once in the parent
    # (before forking) and records the sequence of add_*_cover calls
    # each CV produces. In children, we wrap B::Deparse::deparse_sub:
    # for cached CVs, we replay the recorded calls instead of
    # re-walking the op tree. The replayed calls still read $Coverage
    # at call time, so each child gets its own correct counts.
    #
    # The cache is keyed by CV memory address ($$cv) and validated by
    # checking that START and ROOT op addresses haven't changed —
    # this guards against CVs that were recompiled or replaced after
    # cache building.
    #
    # Requires PadWalker because Devel::Cover's key state variables
    # ($Structure, $Coverage, %Run) are lexicals inside closures, not
    # package globals. PadWalker::closed_over lets us reach into those
    # closures to set up a temporary environment for the cache-building
    # pass, then restore the originals afterward.

    if ($cache_mode) {
        require PadWalker;

        if (${^GLOBAL_PHASE} eq 'RUN') {
            # Loaded at runtime (e.g. forkprove's -M flags after INIT has passed).
            # %Coverage is already expanded by CHECK, so we can build immediately.
            _install_deparse_cache($debug);
        } else {
            # Loaded at compile time (e.g. via PERL5OPT or use). %Coverage is still
            # (all => 1) — CHECK hasn't expanded it yet. Defer to INIT, which runs
            # after all CHECK blocks (FIFO order). String eval so the INIT block is
            # only registered when actually needed (avoids "Too late" warning).
            eval "INIT { _install_deparse_cache($debug) }";
        }
    }
}

sub _install_deparse_cache {
    my ($debug) = @_;

    my $rpt_co = PadWalker::closed_over(\&Devel::Cover::_report);

    # %Coverage gates the deparse walker's discovery logic. It starts as (all => 1) and
    # gets expanded to per-type flags (statement, branch, ...) during CHECK. Building the
    # cache before expansion produces wrong results. This should not happen — the caller
    # defers via INIT or checks ${^GLOBAL_PHASE} — but guard against it.
    my $Coverage_ref = PadWalker::closed_over(\&Devel::Cover::add_statement_cover)->{'%Coverage'};
    if (exists $Coverage_ref->{all}) {
        die "Devel::Cover::Optimizer: cache called before %Coverage expanded (loaded too early?)\n";
    }

    # Populate @Cvs with currently-loaded CVs from selected packages. Stock Devel::Cover
    # calls this in CHECK and again in _report; we call it here so the cache sees all CVs
    # loaded by this point (important when forkprove preloads after CHECK).
    Devel::Cover::check_files();
    my $Cvs_ref      = $rpt_co->{'@Cvs'};
    my $Subs_only_ref = $rpt_co->{'$Subs_only'};

    my %cache;
    my $Seen_ref = _build_deparse_cache(\%cache, $Cvs_ref, $Subs_only_ref, $debug);

    return unless %cache;

    my $Structure_ref =
        PadWalker::closed_over(\&Devel::Cover::add_statement_cover)->{'$Structure'};
    my $orig_deparse_sub = \&B::Deparse::deparse_sub;
    my $cache_hits = 0;
    my $cache_misses = 0;

    no warnings 'redefine';
    *B::Deparse::deparse_sub = sub {
        my $cv = $_[1];
        if ($$Structure_ref && ref($cv) && $cv->isa("B::CV") && exists $cache{$$cv}) {
            my $entry = $cache{$$cv};
            if (${$cv->START} == $entry->{start} && ${$cv->ROOT} == $entry->{root}) {
                $cache_hits++;
                for my $c (@{$entry->{calls}}) {
                    local $Devel::Cover::File = $c->{file};
                    local $Devel::Cover::Line = $c->{line};
                    $c->{func}->(@{$c->{args}});
                }
                # Replay %Seen delta so later non-cached CVs see the same
                # duplicate-suppression state as a non-cached run.
                while (my ($type, $ops) = each %{$entry->{seen}}) {
                    @{$Seen_ref->{$type}}{keys %$ops} = values %$ops;
                }
                return "";
            }
        }
        $cache_misses++;
        $orig_deparse_sub->(@_);
    };

    if ($debug) {
        my $orig_report = \&Devel::Cover::report;
        *Devel::Cover::report = sub {
            $orig_report->(@_);
            warn "  [cache] replay: $cache_hits hits, $cache_misses misses\n";
        };
    }
}

# Build the deparse cache by running get_cover() on preloaded CVs in
# the parent process. For each CV, we record what add_*_cover calls
# the deparse walk produces — that's the "structure" of the CV's
# coverage (which lines, branches, conditions exist). Children will
# replay these calls instead of re-walking the op tree.
#
# CVs are walked in the same order as stock _report: main_cv,
# begin_av, check_av, get_ends, then @Cvs (from check_files).
# %Seen accumulates persistently across CVs (cleared once at the
# start, not per-CV), matching stock behavior. After each CV we
# compute the %Seen delta and store only that with the cache entry.
# During replay, children merge the delta to preserve duplicate-
# suppression semantics without re-deparsing.
#
# The challenge is that get_cover() and add_*_cover() depend on
# Devel::Cover's internal state ($Structure for the coverage DB
# schema, $Coverage for runtime counts, %Run for config, $Sub_count
# for dedup). These are lexical variables captured in closures, not
# package globals, so we use PadWalker to get references to them.
#
# We can't run get_cover() against the real state — it would record
# coverage data before any tests run. Instead we swap in a temporary
# $Structure (backed by a throwaway DB directory), empty $Coverage,
# and minimal %Run, run the deparse walks, then restore everything.
# The add_*_cover calls during cache building write into the
# throwaway Structure, which we discard.
sub _build_deparse_cache {
    my ($cache, $Cvs_ref, $Subs_only_ref, $debug) = @_;

    my $asc_co = PadWalker::closed_over(\&Devel::Cover::add_statement_cover);
    my $gc_co  = PadWalker::closed_over(\&Devel::Cover::get_cover);
    my $rpt_co = PadWalker::closed_over(\&Devel::Cover::_report);
    my $dep_co = PadWalker::closed_over(\&Devel::Cover::deparse);

    my $Structure_ref = $asc_co->{'$Structure'};
    my $Coverage_ref  = $rpt_co->{'$Coverage'};
    my $Run_ref       = $asc_co->{'%Run'};
    my $Sub_count_ref = $gc_co->{'$Sub_count'};
    my $Seen_ref      = $dep_co->{'%Seen'};

    # Save originals so we can restore after cache building.
    my $save_Structure = $$Structure_ref;
    my $save_Coverage  = $$Coverage_ref;
    my %save_Run       = %$Run_ref;
    my $save_Sub_count = $$Sub_count_ref;
    # %Seen suppresses duplicate statement/branch/condition discovery during deparse.
    # Without saving/restoring it, the real report pass would skip entries the cache
    # building pass already "saw", producing incorrect coverage.
    my %save_Seen      = %$Seen_ref;

    # Set up throwaway state. Structure needs a real object (add_*_cover calls methods on it),
    # but it only accumulates in memory — disk writes happen during _report, which we don't call.
    require Devel::Cover::DB::Structure;
    my $tmp_base = "/tmp/dcf_cache_$$";
    $$Structure_ref = Devel::Cover::DB::Structure->new(base => $tmp_base);
    $$Coverage_ref  = {};
    %$Run_ref       = (collected => [qw(statement branch condition subroutine time)]);
    $$Sub_count_ref = {};

    # Intercept add_*_cover calls to record what each CV produces
    # We use `local` so the wrappers are automatically removed when the eval block exits, even on error.
    my @calls;
    my $orig_add_stmt = \&Devel::Cover::add_statement_cover;
    my $orig_add_br   = \&Devel::Cover::add_branch_cover;
    my $orig_add_cond = \&Devel::Cover::add_condition_cover;

    eval {
        no warnings 'redefine';
        no strict 'refs';

        # Capture $File and $Line for every call type. Several add_*_cover functions
        # read the package globals $File/$Line in addition to (or instead of) their explicit
        # arguments — e.g. add_branch_cover takes $file/$line args but uses $File for vec,
        # add_condition_cover reads $File/$Line entirely from globals, and add_statement_cover
        # sets them via get_location() internally. Capturing uniformly ensures replay
        # reproduces the exact global state the deparse walker had at each call site.
        local *Devel::Cover::add_statement_cover = sub {
            push @calls, {
                func => $orig_add_stmt, args => [@_],
                file => $Devel::Cover::File, line => $Devel::Cover::Line,
            };
            $orig_add_stmt->(@_);
        };
        local *Devel::Cover::add_branch_cover = sub {
            push @calls, {
                func => $orig_add_br, args => [@_],
                file => $Devel::Cover::File, line => $Devel::Cover::Line,
            };
            $orig_add_br->(@_);
        };
        local *Devel::Cover::add_condition_cover = sub {
            push @calls, {
                func => $orig_add_cond, args => [@_],
                file => $Devel::Cover::File, line => $Devel::Cover::Line,
            };
            $orig_add_cond->(@_);
        };

        # get_cover() checks this flag and short-circuits if false.
        no warnings 'once';
        local $Devel::Cover::Collect = 1;

        # Walk CVs in the same order as stock _report (see Devel::Cover lines 748-763).
        # %Seen accumulates persistently across CVs, matching stock behavior.
        %$Seen_ref = ();
        my %seen_shadow;

        # Build CV list in stock _report order.
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

        for my $item (@report_cvs) {
            @calls = ();

            my $ok = eval {
                if ($item->[0] eq 'main') {
                    Devel::Cover::get_cover($item->[1], $item->[2]);
                } else {
                    Devel::Cover::get_cover($item->[1]);
                }
                1;
            };
            unless ($ok) {
                warn "  [cache] get_cover failed: $@" if $debug;
                next;
            }

            my $seen_delta = _seen_delta($Seen_ref, \%seen_shadow);

            # main_cv is not keyed by CV address — skip caching it, but its
            # %Seen and call effects have already accumulated.
            next if $item->[0] eq 'main';

            my $cv = $item->[1];
            next unless ref($cv) eq "B::CV" && $$cv;
            next if exists $cache->{$$cv};
            my $root = $cv->ROOT;
            next unless ref($root) && !$root->isa("B::NULL");

            # Cache if this CV produced calls OR had a non-empty %Seen delta.
            # CVs with only a seen delta still need replay to preserve
            # duplicate-suppression state for later non-cached CVs.
            next unless @calls || %$seen_delta;

            $cache->{$$cv} = {
                start => ${$cv->START},
                root  => $$root,
                calls => [@calls],
                seen  => $seen_delta,
            };
        }
        1;
    };
    my $build_err = $@;

    $$Structure_ref = $save_Structure;
    $$Coverage_ref  = $save_Coverage;
    %$Run_ref       = %save_Run;
    $$Sub_count_ref = $save_Sub_count;
    %$Seen_ref      = %save_Seen;

    if ($build_err) {
        %$cache = ();
        die "Devel::Cover::Optimizer: cache build failed: $build_err";
    }

    die "Devel::Cover::Optimizer: unexpected disk write during cache build: $tmp_base\n" if -d $tmp_base;

    if ($debug) {
        my $n = scalar keys %$cache;
        my $total_calls = 0;
        $total_calls += scalar @{$_->{calls}} for values %$cache;
        my $seen_only = grep { !@{$_->{calls}} && %{$_->{seen}} } values %$cache;
        warn "  [cache] built deparse cache: $n CVs ($seen_only seen-only), $total_calls cached calls\n";
    }

    return $Seen_ref;
}

sub _seen_delta {
    my ($seen, $shadow) = @_;
    my %delta;
    for my $type (keys %$seen) {
        for my $op (keys %{$seen->{$type}}) {
            my $val = $seen->{$type}{$op};
            next if exists $shadow->{$type}{$op}
                 && $shadow->{$type}{$op} == $val;
            $delta{$type}{$op} = $val;
            $shadow->{$type}{$op} = $val;
        }
    }
    return \%delta;
}

# Used only by debug logging — not on the hot path.
sub _cv_file {
    my ($cv) = @_;
    return unless ref($cv) eq "B::CV";
    my $op = $cv->START;
    return unless ref($op) eq "B::COP";
    $op->file;
}

1;
