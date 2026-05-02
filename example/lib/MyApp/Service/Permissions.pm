package MyApp::Service::Permissions;
use Moo;
use Types::Standard qw(HashRef);

has _grants => (is => 'ro', isa => HashRef, default => sub { {} });

sub grant {
    my ($self, $user_id, $permission) = @_;
    $self->_grants->{$user_id}{$permission} = 1;
}

sub revoke {
    my ($self, $user_id, $permission) = @_;
    delete $self->_grants->{$user_id}{$permission};
}

sub can_perform {
    my ($self, $user_id, $permission) = @_;
    return $self->_grants->{$user_id}{$permission} ? 1 : 0;
}

sub permissions_for {
    my ($self, $user_id) = @_;
    return [keys %{$self->_grants->{$user_id} // {}}];
}

1;
