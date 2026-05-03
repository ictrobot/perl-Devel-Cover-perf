package MyApp::Registry;
use Moo;
use Types::Standard qw(HashRef);

has _store => (is => 'ro', isa => HashRef, default => sub { {} });

sub register {
    my ($self, $name, $obj) = @_;
    $self->_store->{$name} = $obj;
}

sub resolve {
    my ($self, $name) = @_;
    return $self->_store->{$name};
}

sub has_service { exists $_[0]->_store->{$_[1]} }
sub services    { keys %{$_[0]->_store} }
sub count       { scalar keys %{$_[0]->_store} }

1;

__END__

=head1 NAME

MyApp::Registry - service registry for the example application

=head2 register

Store an object under a service name.

=head2 resolve

Return the object registered for a service name.

=head2 has_service

Check whether a service name has been registered.

=head1 TEST FIXTURE NOTE

This POD deliberately documents only part of the public API. Some methods are
left undocumented so the harness exercises both covered and uncovered POD
coverage entries.

=cut
