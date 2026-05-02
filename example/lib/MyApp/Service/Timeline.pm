package MyApp::Service::Timeline;
use Moo;
use DateTime;

has today => (is => 'ro');

sub parse_date {
    my ($self, $date) = @_;
    die "Date must be YYYY-MM-DD" unless defined($date) && $date =~ /^(\d{4})-(\d{2})-(\d{2})$/;
    return DateTime->new(
        year      => $1,
        month     => $2,
        day       => $3,
        time_zone => 'UTC',
    );
}

sub days_until {
    my ($self, $date) = @_;
    my $target = $self->parse_date($date);
    my $today  = $self->_today;
    return int(($target->epoch - $today->epoch) / 86_400);
}

sub status_for_due_date {
    my ($self, $date) = @_;
    return 'no_due_date' unless defined $date && length $date;
    my $days = $self->days_until($date);
    return 'overdue'   if $days < 0;
    return 'due_today' if $days == 0;
    return 'due_soon'  if $days <= 7;
    return 'scheduled';
}

sub working_days_between {
    my ($self, $start, $end) = @_;
    my $cursor = $self->parse_date($start);
    my $finish = $self->parse_date($end);
    return 0 if DateTime->compare($cursor, $finish) > 0;

    my $days = 0;
    while (DateTime->compare($cursor, $finish) <= 0) {
        $days++ unless $cursor->day_of_week >= 6;
        $cursor->add(days => 1);
    }
    return $days;
}

sub bucket_tasks_by_due_week {
    my ($self, $tasks) = @_;
    my %buckets;
    for my $task (@{$tasks // []}) {
        next unless $task->can('due_date') && defined $task->due_date;
        my $date = $self->parse_date($task->due_date);
        my $key = sprintf('%04d-W%02d', $date->week_year, $date->week_number);
        push @{$buckets{$key}}, $task;
    }
    return \%buckets;
}

sub _today {
    my $self = shift;
    return defined($self->today)
        ? $self->parse_date($self->today)
        : DateTime->today(time_zone => 'UTC');
}

1;
