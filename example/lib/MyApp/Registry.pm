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
