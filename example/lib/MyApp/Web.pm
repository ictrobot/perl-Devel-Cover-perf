package MyApp::Web;
use Mojo::Base 'Mojolicious', -signatures;
use MyApp::Container;

sub startup ($self) {
    my $container = MyApp::Container->new->bootstrap;

    $self->helper(container => sub { $container });
    $self->helper(logger    => sub { $container->logger });

    my $r = $self->routes;
    $r->get('/')->to('root#index');
    $r->get('/health')->to('root#health');

    my $auth = $r->under('/api')->to('api-auth#check');
    $auth->get('/users')->to('api-user#list');
    $auth->post('/users')->to('api-user#create');
    $auth->get('/users/:id')->to('api-user#show');

    $auth->get('/projects')->to('api-project#list');
    $auth->post('/projects')->to('api-project#create');
    $auth->get('/projects/:id')->to('api-project#show');

    $auth->get('/tasks')->to('api-task#list');
    $auth->post('/tasks')->to('api-task#create');
    $auth->get('/tasks/:id')->to('api-task#show');
    $auth->put('/tasks/:id/status')->to('api-task#update_status');

    $auth->get('/teams')->to('api-team#list');
    $auth->get('/sprints')->to('api-sprint#list');
    $auth->get('/reports')->to('api-report#list');

    $r->post('/api/login')->to('api-auth#login');
    $r->get('/api/webhooks')->to('api-webhook#list');
}

1;
