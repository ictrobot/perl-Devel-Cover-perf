package MyApp::Role::Configurable;
use Moo::Role;
use Types::Standard qw(HashRef);

has settings => (is => 'rw', isa => HashRef, default => sub { {} });

sub get_setting {
    my ($self, $key, $default) = @_;
    return exists $self->settings->{$key} ? $self->settings->{$key} : $default;
}

sub set_setting {
    my ($self, $key, $value) = @_;
    $self->settings->{$key} = $value;
}

1;
