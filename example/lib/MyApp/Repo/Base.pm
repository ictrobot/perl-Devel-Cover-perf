package MyApp::Repo::Base;
use Moo;
use Types::Standard qw(HashRef ArrayRef);

with 'MyApp::Role::Pageable';

has _store => (is => 'ro', isa => HashRef, default => sub { {} });

sub add {
    my ($self, $item) = @_;
    my $id = $item->id;
    $self->_store->{$id} = $item;
    return $item;
}

sub find {
    my ($self, $id) = @_;
    return $self->_store->{$id};
}

sub all { [values %{$_[0]->_store}] }

sub remove {
    my ($self, $id) = @_;
    return delete $self->_store->{$id};
}

sub count { scalar keys %{$_[0]->_store} }

sub where {
    my ($self, $field, $value) = @_;
    return [grep { $_->can($field) && ($_->$field // '') eq $value } values %{$self->_store}];
}

sub exists { defined $_[0]->_store->{$_[1]} }

1;
