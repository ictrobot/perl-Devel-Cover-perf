package MyApp::Service::TaskManager;
use Moo;
use MyApp::Model::Task;
use MyApp::Repo::Task;

has repo      => (is => 'lazy');
has logger    => (is => 'ro', required => 1);
has event_bus => (is => 'ro');

sub _build_repo { MyApp::Repo::Task->new }

sub create_task {
    my ($self, %attrs) = @_;
    my $task = MyApp::Model::Task->new(%attrs);
    if ($task->is_valid) {
        $self->repo->add($task);
        $self->logger->info("Created task: " . $task->title);
        $self->event_bus->emit('task.created', $task) if $self->event_bus;
        return $task;
    }
    return undef;
}

sub find_task      { $_[0]->repo->find($_[1]) }
sub all_tasks      { $_[0]->repo->all }
sub delete_task    { $_[0]->repo->remove($_[1]) }
sub tasks_by_status { $_[0]->repo->where('status', $_[1]) }
sub tasks_by_project { $_[0]->repo->where('project_id', $_[1]) }

sub update_status {
    my ($self, $task_id, $status) = @_;
    my $task = $self->repo->find($task_id) or return undef;
    $task->change_status($status);
    $self->event_bus->emit('task.updated', $task) if $self->event_bus;
    return $task;
}

1;
