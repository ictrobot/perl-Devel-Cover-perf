package MyApp::Web::Controller::Root;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub index ($self) {
    $self->render(json => { app => 'MyApp', version => '0.01' });
}

sub health ($self) {
    $self->render(json => { status => 'ok', uptime => time });
}

1;
