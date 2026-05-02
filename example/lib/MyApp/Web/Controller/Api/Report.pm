package MyApp::Web::Controller::Api::Report;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub list ($self) {
    $self->render(json => { reports => [
        { id => '1', title => 'Weekly Summary', type => 'summary' },
        { id => '2', title => 'Velocity Report', type => 'velocity' },
    ]});
}

1;
