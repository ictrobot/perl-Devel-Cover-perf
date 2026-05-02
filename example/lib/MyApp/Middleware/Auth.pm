package MyApp::Middleware::Auth;
use Moo;
use Types::Standard qw(ArrayRef);

has public_paths => (is => 'ro', isa => ArrayRef, default => sub { ['/login', '/health', '/'] });
has auth_service => (is => 'ro', required => 1);

sub check {
    my ($self, $path, $token) = @_;
    return 1 if grep { $_ eq $path } @{$self->public_paths};
    return 0 unless $token;
    return defined $self->auth_service->validate_token($token);
}

1;
