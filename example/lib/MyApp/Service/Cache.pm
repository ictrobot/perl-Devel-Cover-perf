package MyApp::Service::Cache;
use Moo;
use Types::Standard qw(HashRef Int);

has _data => (is => 'ro', isa => HashRef, default => sub { {} });
has _ttls => (is => 'ro', isa => HashRef, default => sub { {} });
has default_ttl => (is => 'ro', isa => Int, default => 300);

sub get {
    my ($self, $key) = @_;
    return undef unless exists $self->_data->{$key};
    if (exists $self->_ttls->{$key} && time > $self->_ttls->{$key}) {
        delete $self->_data->{$key};
        delete $self->_ttls->{$key};
        return undef;
    }
    return $self->_data->{$key};
}

sub set {
    my ($self, $key, $value, $ttl) = @_;
    $self->_data->{$key} = $value;
    $self->_ttls->{$key} = time + ($ttl // $self->default_ttl);
}

sub delete { delete $_[0]->_data->{$_[1]}; delete $_[0]->_ttls->{$_[1]} }
sub clear  { %{$_[0]->_data} = (); %{$_[0]->_ttls} = () }
sub count  { scalar keys %{$_[0]->_data} }

1;
