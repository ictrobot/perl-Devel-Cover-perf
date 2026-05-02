package MyApp::Web::Controller::Api::Team;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub list ($self) {
    $self->render(json => { teams => [
        { id => '1', name => 'Backend', member_count => 4 },
        { id => '2', name => 'Frontend', member_count => 3 },
    ]});
}

1;
