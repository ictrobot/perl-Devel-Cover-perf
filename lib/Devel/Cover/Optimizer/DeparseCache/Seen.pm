package Devel::Cover::Optimizer::DeparseCache::Seen;
use strict;
use warnings;

# These are the stable top-level %Seen buckets used by Devel::Cover 1.33-1.52.
# Tracking known inner buckets avoids keeping the outer %Seen hash tied during
# child replay.
our @BUCKETS = qw(statement other branch condition);

sub start_build {
    my ($seen_ref) = @_;
    return Devel::Cover::Optimizer::DeparseCache::Seen::BuildTracker->new($seen_ref);
}

sub start_replay {
    my ($seen_ref) = @_;
    return Devel::Cover::Optimizer::DeparseCache::Seen::ReplayTracker->new($seen_ref);
}

sub record_touches {
    my ($trace, $seen_touches, $occurrence) = @_;

    my ($seen_zero, $seen_nonzero, $seen_sets) = (0, 0, 0);
    my %local_seen_touch;

    my @trace_sets = (
        [$trace->{requires_zero},    \$seen_zero],
        [$trace->{requires_nonzero}, \$seen_nonzero],
        [$trace->{sets_true},        \$seen_sets],
    );

    for my $trace_set (@trace_sets) {
        my ($sets, $count_ref) = @$trace_set;
        for my $type (keys %$sets) {
            my $ops = $sets->{$type};
            $$count_ref += scalar keys %$ops;
            for my $op (keys %$ops) {
                # A single CV can read and then set the same key. Count it once
                # for private/shared classification of this report occurrence.
                next if $local_seen_touch{$type}{$op}++;
                my $touch = $seen_touches->{$type}{$op} ||= {
                    count      => 0,
                    occurrence => $occurrence,
                };
                $touch->{count}++;
            }
        }
    }

    return ($seen_zero, $seen_nonzero, $seen_sets);
}

sub has_any {
    my ($sets) = @_;
    for my $type (keys %$sets) {
        return 1 if keys %{$sets->{$type}};
    }
    return 0;
}

sub split_private_shared {
    my ($cache, $seen_touches) = @_;

    my %private_seen_owner;
    my %privacy_stats = (
        private_sets => 0,
        private_zero => 0,
        shared_sets  => 0,
        shared_zero  => 0,
    );

    for my $entry (values %$cache) {
        my (%shared_zero, %private_sets, %shared_sets, %requires_nonzero);

        # Private required-zero keys are safe to skip on the hit fast path. If an
        # uncached walk writes one first, invalidate only the owning entry.
        my $sets = $entry->{seen_requires_zero};
        for my $type (keys %$sets) {
            my $ops = $sets->{$type};
            for my $op (keys %$ops) {
                my $touch = $seen_touches->{$type}{$op};
                if ($touch
                    && $touch->{count} == 1
                    && $touch->{occurrence} == $entry->{occurrence})
                {
                    $private_seen_owner{$type}{$op} = $entry;
                    $privacy_stats{private_zero}++;
                } else {
                    push @{$shared_zero{$type}}, $op;
                    $privacy_stats{shared_zero}++;
                }
            }
        }

        $sets = $entry->{seen_sets_true};
        for my $type (keys %$sets) {
            my $ops = $sets->{$type};
            for my $op (keys %$ops) {
                my $touch = $seen_touches->{$type}{$op};
                if ($touch
                    && $touch->{count} == 1
                    && $touch->{occurrence} == $entry->{occurrence})
                {
                    push @{$private_sets{$type}}, $op;
                    $privacy_stats{private_sets}++;
                } else {
                    push @{$shared_sets{$type}}, $op;
                    $privacy_stats{shared_sets}++;
                }
            }
        }

        $sets = $entry->{seen_requires_nonzero};
        for my $type (keys %$sets) {
            # Required-true keys cannot use the same private shortcut: the cache
            # entry depends on the key already being true before replay starts.
            my @ops = keys %{$sets->{$type}};
            $requires_nonzero{$type} = \@ops if @ops;
        }

        $entry->{seen_requires_zero} = \%shared_zero;
        $entry->{seen_requires_nonzero} = \%requires_nonzero;
        $entry->{seen_sets_true} = \%shared_sets;
        $entry->{seen_private_sets_true} = \%private_sets;
        $entry->{private_invalid} = 0;
        $entry->{replayed} = 0;
    }

    return (\%private_seen_owner, \%privacy_stats);
}

sub validate_entry {
    my ($seen_data, $entry) = @_;

    return "replayed" if $entry->{replayed};
    return "private"  if $entry->{private_invalid};

    # Shared required-zero keys are the only zero assumptions checked on every
    # cache hit. Private zero assumptions are handled by lazy invalidation.
    my $sets = $entry->{seen_requires_zero};
    for my $type (keys %$sets) {
        my $bucket = $seen_data->{$type} or next;
        for my $op (@{$sets->{$type}}) {
            return "requires_zero" if $bucket->{$op};
        }
    }

    $sets = $entry->{seen_requires_nonzero};
    for my $type (keys %$sets) {
        my $bucket = $seen_data->{$type};
        return "requires_nonzero" unless $bucket;
        for my $op (@{$sets->{$type}}) {
            return "requires_nonzero" unless $bucket->{$op};
        }
    }

    return;
}

sub apply_entry_sets {
    my ($seen_data, $entry) = @_;

    # Replaying add_* calls is not enough: later real deparse walks also need
    # the duplicate-suppression marks that the cached walk would have written.
    for my $field (qw(seen_sets_true seen_private_sets_true)) {
        my $sets = $entry->{$field};
        for my $type (keys %$sets) {
            my $bucket = $seen_data->{$type} ||= {};
            $bucket->{$_} = 1 for @{$sets->{$type}};
        }
    }

    return;
}

sub invalidate_private_owners {
    my ($private_seen_owner, $delta) = @_;

    my $invalidated = 0;
    for my $type (keys %$delta) {
        my $ops = $delta->{$type};
        for my $op (keys %$ops) {
            my $entry = $private_seen_owner->{$type}{$op} or next;
            next if $entry->{replayed} || $entry->{private_invalid};
            $entry->{private_invalid} = 1;
            $invalidated++;
        }
    }

    return $invalidated;
}

sub _new_trace {
    return {
        requires_zero    => {},
        requires_nonzero => {},
        sets_true        => {},
    };
}

sub _truth {
    my ($value) = @_;
    return defined($value) && $value ? 1 : 0;
}

# Tracks %Seen during the parent cache build, keeping normal truthy state while
# recording the assumptions made by the current CV.
package Devel::Cover::Optimizer::DeparseCache::Seen::BuildTracker;
use strict;
use warnings;

sub new {
    my ($class, $seen_ref) = @_;

    my $self = bless {
        seen_ref        => $seen_ref,
        data            => {},
        trace           => Devel::Cover::Optimizer::DeparseCache::Seen::_new_trace(),
        local_sets_true => {},
        tied_buckets    => {},
    }, $class;

    %$seen_ref = ();
    for my $bucket (@Devel::Cover::Optimizer::DeparseCache::Seen::BUCKETS) {
        my $data = $self->{data}{$bucket} ||= {};
        tie my %inner,
            "Devel::Cover::Optimizer::DeparseCache::Seen::BuildBucket",
            $self,
            $bucket;
        $seen_ref->{$bucket} = \%inner;
        $self->{tied_buckets}{$bucket} = \%inner;
    }

    return $self;
}

sub take_trace {
    my ($self) = @_;

    my $trace = $self->{trace};
    $self->{trace} = Devel::Cover::Optimizer::DeparseCache::Seen::_new_trace();
    $self->{local_sets_true} = {};

    return $trace;
}

sub restore_plain {
    my ($self) = @_;

    for my $bucket (keys %{$self->{tied_buckets}}) {
        my $href = $self->{tied_buckets}{$bucket};
        if (my $tied = tied %$href) {
            undef $tied;
            untie %$href;
        }
        $self->{seen_ref}{$bucket} = $self->{data}{$bucket} || {};
    }
    $self->{tied_buckets} = {};

    return;
}

sub get {
    my ($self, $bucket, $op) = @_;

    my $data = $self->{data}{$bucket};
    my $value = $data ? $data->{$op} : undef;
    if (Devel::Cover::Optimizer::DeparseCache::Seen::_truth($value)) {
        # If this CV made the key true earlier, requiring nonzero here is local
        # to the CV and does not need validating against the child start state.
        $self->{trace}{requires_nonzero}{$bucket}{$op} = 1
            unless $self->{local_sets_true}{$bucket}{$op};
    } else {
        $self->{trace}{requires_zero}{$bucket}{$op} = 1;
    }

    return $value;
}

sub set {
    my ($self, $bucket, $op, $new) = @_;

    $self->{data}{$bucket} ||= {};
    my $current = $self->{data}{$bucket};

    my $old = exists $current->{$op} ? $current->{$op} : undef;
    my $old_true = Devel::Cover::Optimizer::DeparseCache::Seen::_truth($old);
    my $new_true = Devel::Cover::Optimizer::DeparseCache::Seen::_truth($new);

    $current->{$op} = $new;
    if (!$old_true && $new_true) {
        $self->{trace}{requires_zero}{$bucket}{$op} = 1;
        $self->{trace}{sets_true}{$bucket}{$op} = 1;
        $self->{local_sets_true}{$bucket}{$op} = 1;
    }

    return $new;
}

# Inner tied hash used by BuildTracker for one known %Seen bucket.
package Devel::Cover::Optimizer::DeparseCache::Seen::BuildBucket;
use strict;
use warnings;

sub TIEHASH {
    my ($class, $tracker, $bucket) = @_;
    return bless { tracker => $tracker, bucket => $bucket }, $class;
}

sub FETCH {
    my ($self, $op) = @_;
    return $self->{tracker}->get($self->{bucket}, $op);
}

sub STORE {
    my ($self, $op, $value) = @_;
    return $self->{tracker}->set($self->{bucket}, $op, $value);
}

sub EXISTS {
    my ($self, $op) = @_;
    my $data = $self->{tracker}{data}{ $self->{bucket} };
    return $data && exists $data->{$op};
}

sub FIRSTKEY {
    my ($self) = @_;
    my $data = $self->{tracker}{data}{ $self->{bucket} } || {};
    keys %$data;
    return each %$data;
}

sub NEXTKEY {
    my ($self) = @_;
    my $data = $self->{tracker}{data}{ $self->{bucket} } || {};
    return each %$data;
}

sub DELETE {
    die "Devel::Cover::Optimizer: %Seen build tracker does not support delete\n";
}

sub CLEAR {
    die "Devel::Cover::Optimizer: %Seen build tracker does not support clear\n";
}

# Owns the child replay %Seen backing hashes. Cache hits use data() directly;
# uncached misses temporarily tie the same buckets via start_delta().
package Devel::Cover::Optimizer::DeparseCache::Seen::ReplayTracker;
use strict;
use warnings;

sub new {
    my ($class, $seen_ref) = @_;

    my %data;
    for my $type (keys %$seen_ref) {
        my $bucket = $seen_ref->{$type};
        next unless ref($bucket) eq "HASH";
        $data{$type} = { %$bucket };
    }

    # Replace Devel::Cover's hash with our backing hashes, but leave them untied
    # for the normal cached replay path.
    %$seen_ref = ();
    for my $type (keys %data) {
        $seen_ref->{$type} = $data{$type};
    }
    for my $bucket (@Devel::Cover::Optimizer::DeparseCache::Seen::BUCKETS) {
        $data{$bucket} ||= {};
        $seen_ref->{$bucket} = $data{$bucket};
    }

    return bless {
        seen_ref     => $seen_ref,
        data         => \%data,
        delta        => {},
        tied_buckets => {},
    }, $class;
}

sub data {
    my ($self) = @_;
    return $self->{data};
}

sub start_delta {
    my ($self) = @_;

    $self->{delta} = {};
    for my $bucket (@Devel::Cover::Optimizer::DeparseCache::Seen::BUCKETS) {
        my $data = $self->{data}{$bucket} ||= {};
        tie my %inner,
            "Devel::Cover::Optimizer::DeparseCache::Seen::DeltaBucket",
            $data,
            ($self->{delta}{$bucket} ||= {});
        $self->{seen_ref}{$bucket} = \%inner;
        $self->{tied_buckets}{$bucket} = \%inner;
    }

    return;
}

sub finish_delta {
    my ($self) = @_;

    # Untie immediately after the miss so following cache hits go back to plain
    # hash access.
    for my $bucket (keys %{$self->{tied_buckets}}) {
        my $href = $self->{tied_buckets}{$bucket};
        if (my $tied = tied %$href) {
            undef $tied;
            untie %$href;
        }
        $self->{seen_ref}{$bucket} = $self->{data}{$bucket} || {};
        delete $self->{delta}{$bucket}
            unless keys %{$self->{delta}{$bucket} || {}};
    }
    $self->{tied_buckets} = {};

    my $delta = $self->{delta};
    $self->{delta} = {};
    return $delta;
}

# Inner tied hash used only around an uncached child deparse miss. It records
# false-to-true writes so private cached entries can be invalidated.
package Devel::Cover::Optimizer::DeparseCache::Seen::DeltaBucket;
use strict;
use warnings;

sub TIEHASH {
    my ($class, $data, $delta) = @_;
    return bless { data => $data, delta => $delta }, $class;
}

sub FETCH {
    my ($self, $op) = @_;
    return $self->{data}{$op};
}

sub STORE {
    my ($self, $op, $value) = @_;

    my $old = exists $self->{data}{$op} ? $self->{data}{$op} : undef;
    $self->{data}{$op} = $value;
    $self->{delta}{$op} = 1
        if !Devel::Cover::Optimizer::DeparseCache::Seen::_truth($old)
        && Devel::Cover::Optimizer::DeparseCache::Seen::_truth($value);

    return $value;
}

sub EXISTS {
    my ($self, $op) = @_;
    return exists $self->{data}{$op};
}

sub FIRSTKEY {
    my ($self) = @_;
    keys %{$self->{data}};
    return each %{$self->{data}};
}

sub NEXTKEY {
    my ($self) = @_;
    return each %{$self->{data}};
}

sub DELETE {
    die "Devel::Cover::Optimizer: %Seen delta tracker does not support delete\n";
}

sub CLEAR {
    die "Devel::Cover::Optimizer: %Seen delta tracker does not support clear\n";
}

1;
