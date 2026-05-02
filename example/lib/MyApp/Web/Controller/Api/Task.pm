package MyApp::Web::Controller::Api::Task;
use Mojo::Base 'Mojolicious::Controller', -signatures;

my @TASKS = (
    { id => '1', title => 'Setup CI',        status => 'done',        priority => 'high' },
    { id => '2', title => 'Write tests',      status => 'in_progress', priority => 'high' },
    { id => '3', title => 'Update docs',      status => 'open',        priority => 'low' },
    { id => '4', title => 'Fix login bug',    status => 'review',      priority => 'critical' },
);

sub list ($self) {
    my $status = $self->param('status');
    my @filtered = $status ? grep { $_->{status} eq $status } @TASKS : @TASKS;
    $self->render(json => { tasks => \@filtered, total => scalar @filtered });
}

sub show ($self) {
    my $id = $self->param('id');
    my ($task) = grep { $_->{id} eq $id } @TASKS;
    return $self->render(json => { error => 'Not found' }, status => 404) unless $task;
    $self->render(json => $task);
}

sub create ($self) {
    my $body = $self->req->json // {};
    $body->{id} = scalar(@TASKS) + 1;
    $body->{status} //= 'open';
    push @TASKS, $body;
    $self->render(json => $body, status => 201);
}

sub update_status ($self) {
    my $id = $self->param('id');
    my ($task) = grep { $_->{id} eq $id } @TASKS;
    return $self->render(json => { error => 'Not found' }, status => 404) unless $task;
    $task->{status} = $self->req->json->{status} // $task->{status};
    $self->render(json => $task);
}

1;
