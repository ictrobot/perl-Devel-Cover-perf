package MyApp::Report::Calendar;
use Moo;
use DateTime;

sub month_grid {
    my ($self, $year, $month) = @_;
    my $first = DateTime->new(year => $year, month => $month, day => 1, time_zone => 'UTC');
    my $cursor = $first->clone->subtract(days => $first->day_of_week - 1);
    my @weeks;

    for my $week (1..6) {
        my @days;
        for my $day (1..7) {
            push @days, {
                date     => $cursor->ymd,
                day      => $cursor->day,
                in_month => $cursor->month == $month ? 1 : 0,
                weekend  => $cursor->day_of_week >= 6 ? 1 : 0,
            };
            $cursor->add(days => 1);
        }
        push @weeks, \@days;
    }

    return \@weeks;
}

sub month_label {
    my ($self, $year, $month) = @_;
    return DateTime->new(year => $year, month => $month, day => 1, time_zone => 'UTC')->strftime('%B %Y');
}

1;
