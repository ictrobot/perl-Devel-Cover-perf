package MyApp::Service::ReleasePlanner;
use Moo;
use MyApp::Report::Burndown;
use MyApp::Report::Calendar;
use MyApp::Report::ScheduleWindow;

has burndown => (is => 'lazy');
has calendar => (is => 'lazy');
has window   => (is => 'lazy');

sub _build_burndown { MyApp::Report::Burndown->new }
sub _build_calendar { MyApp::Report::Calendar->new }
sub _build_window   { MyApp::Report::ScheduleWindow->new }

sub plan {
    my ($self, %args) = @_;
    my $start = $args{start};
    my $end   = $args{end};
    return {
        dates    => $self->window->dates_between($start, $end),
        weeks    => $self->window->week_labels($start, $end),
        burndown => $self->burndown->ideal_points($start, $end, $args{points} // 0),
    };
}

sub calendar_for {
    my ($self, $year, $month) = @_;
    return {
        label => $self->calendar->month_label($year, $month),
        weeks => $self->calendar->month_grid($year, $month),
    };
}

1;
