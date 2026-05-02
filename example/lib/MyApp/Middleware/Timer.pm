package MyApp::Middleware::Timer;
use Moo;
use Types::Standard qw(HashRef);
use Time::HiRes qw(gettimeofday tv_interval);

has _timers => (is => 'ro', isa => HashRef, default => sub { {} });

sub start {
    my ($self, $label) = @_;
    $self->_timers->{$label} = [gettimeofday];
}

sub stop {
    my ($self, $label) = @_;
    my $start = delete $self->_timers->{$label} or return 0;
    return tv_interval($start);
}

1;
