package MyApp::Web::Controller::Api::Webhook;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub list ($self) {
    $self->render(json => { webhooks => [] });
}

1;
