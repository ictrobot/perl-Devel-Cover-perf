package MyApp::EventBus;
use Moo;
use Types::Standard qw(HashRef);

has _listeners => (is => 'ro', isa => HashRef, default => sub { {} });

sub on {
    my ($self, $event, $cb) = @_;
    push @{$self->_listeners->{$event} //= []}, $cb;
}

sub emit {
    my ($self, $event, @args) = @_;
    my $listeners = $self->_listeners->{$event} // [];
    $_->(@args) for @$listeners;
    return scalar @$listeners;
}

sub off {
    my ($self, $event) = @_;
    delete $self->_listeners->{$event};
}

sub events { keys %{$_[0]->_listeners} }

1;
