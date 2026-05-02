package MyApp::Plugin;
use Moo::Role;
use Types::Standard qw(Str);

requires 'register';

has plugin_name    => (is => 'ro', isa => Str, required => 1);
has plugin_version => (is => 'ro', isa => Str, default => '1.0');

sub plugin_info {
    my $self = shift;
    return { name => $self->plugin_name, version => $self->plugin_version };
}

1;
