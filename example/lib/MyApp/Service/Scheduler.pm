package MyApp::Service::Scheduler;
use Moo;
use Types::Standard qw(ArrayRef);

has jobs => (is => 'ro', isa => ArrayRef, default => sub { [] });

sub add_job {
    my ($self, %job) = @_;
    $job{id} = scalar @{$self->jobs} + 1;
    $job{status} = 'pending';
    push @{$self->jobs}, \%job;
    return \%job;
}

sub pending_jobs { [grep { $_->{status} eq 'pending' } @{$_[0]->jobs}] }
sub run_pending {
    my $self = shift;
    for my $job (@{$self->pending_jobs}) {
        $job->{callback}->() if $job->{callback};
        $job->{status} = 'completed';
    }
}

1;
