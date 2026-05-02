package MyApp::Middleware::ErrorHandler;
use Moo;

has logger => (is => 'ro', required => 1);

sub handle {
    my ($self, $error) = @_;
    if (ref $error && $error->isa('MyApp::Error')) {
        $self->logger->error($error->to_string);
        return { status => $error->code, error => $error->message };
    }
    $self->logger->error("Unhandled: $error");
    return { status => 500, error => 'Internal Server Error' };
}

1;
