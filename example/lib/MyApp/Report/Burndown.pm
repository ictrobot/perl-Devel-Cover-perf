package MyApp::Report::Burndown;
use Moo;
use DateTime;

sub ideal_points {
    my ($self, $start, $end, $points) = @_;
    my $start_date = $self->_parse($start);
    my $end_date   = $self->_parse($end);
    my $total_days = int(($end_date->epoch - $start_date->epoch) / 86_400) || 1;
    my @series;

    for my $offset (0..$total_days) {
        my $date = $start_date->clone->add(days => $offset);
        my $remaining = $points - (($points / $total_days) * $offset);
        push @series, {
            date      => $date->ymd,
            remaining => sprintf('%.1f', $remaining < 0 ? 0 : $remaining),
        };
    }

    return \@series;
}

sub _parse {
    my ($self, $date) = @_;
    die "Date must be YYYY-MM-DD" unless defined($date) && $date =~ /^(\d{4})-(\d{2})-(\d{2})$/;
    return DateTime->new(year => $1, month => $2, day => $3, time_zone => 'UTC');
}

1;
