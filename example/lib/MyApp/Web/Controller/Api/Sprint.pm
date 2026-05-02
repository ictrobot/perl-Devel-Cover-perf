package MyApp::Web::Controller::Api::Sprint;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub list ($self) {
    $self->render(json => { sprints => [
        { id => '1', name => 'Sprint 1', start_date => '2025-01-01', end_date => '2025-01-14' },
        { id => '2', name => 'Sprint 2', start_date => '2025-01-15', end_date => '2025-01-28' },
    ]});
}

1;
