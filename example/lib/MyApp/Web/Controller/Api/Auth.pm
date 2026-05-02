package MyApp::Web::Controller::Api::Auth;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub check ($self) {
    my $token = $self->req->headers->header('Authorization') // '';
    $token =~ s/^Bearer\s+//;
    # In test mode, allow everything
    return 1 if $self->app->mode eq 'test' || $token;
    $self->render(json => { error => 'Unauthorized' }, status => 401);
    return 0;
}

sub login ($self) {
    my $body = $self->req->json // {};
    if ($body->{username} && $body->{password}) {
        $self->render(json => { token => 'test-token-' . time });
    } else {
        $self->render(json => { error => 'Invalid credentials' }, status => 401);
    }
}

1;
