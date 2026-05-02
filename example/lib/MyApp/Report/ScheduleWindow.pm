package MyApp::Report::ScheduleWindow;
use Moo;
use DateTime;

sub parse_date {
    my ($self, $date) = @_;
    die "Date must be YYYY-MM-DD" unless defined($date) && $date =~ /^(\d{4})-(\d{2})-(\d{2})$/;
    return DateTime->new(year => $1, month => $2, day => $3, time_zone => 'UTC');
}

sub dates_between {
    my ($self, $start, $end) = @_;
    my $cursor = $self->parse_date($start);
    my $finish = $self->parse_date($end);
    my @dates;

    while (DateTime->compare($cursor, $finish) <= 0) {
        push @dates, $cursor->ymd;
        $cursor->add(days => 1);
    }

    return \@dates;
}

sub contains {
    my ($self, $start, $end, $date) = @_;
    my $target = $self->parse_date($date);
    return DateTime->compare($self->parse_date($start), $target) <= 0
        && DateTime->compare($target, $self->parse_date($end)) <= 0;
}

sub week_labels {
    my ($self, $start, $end) = @_;
    my %seen;
    my @labels;
    for my $ymd (@{$self->dates_between($start, $end)}) {
        my $date = $self->parse_date($ymd);
        my $label = sprintf('%04d-W%02d', $date->week_year, $date->week_number);
        push @labels, $label unless $seen{$label}++;
    }
    return \@labels;
}

1;
