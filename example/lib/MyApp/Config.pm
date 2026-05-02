package MyApp::Config;
use Moo;
use Types::Standard qw(HashRef Str Int);

has env      => (is => 'ro', isa => Str, default => 'development');
has app_name => (is => 'ro', isa => Str, default => 'MyApp');
has port     => (is => 'ro', isa => Int, default => 3000);
has data     => (is => 'ro', isa => HashRef, default => sub { {} });

sub is_production  { $_[0]->env eq 'production' }
sub is_development { $_[0]->env eq 'development' }
sub is_test        { $_[0]->env eq 'test' }

sub get {
    my ($self, $key, $default) = @_;
    return exists $self->data->{$key} ? $self->data->{$key} : $default;
}

1;
