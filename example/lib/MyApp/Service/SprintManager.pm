package MyApp::Service::SprintManager;
use Moo;
use MyApp::Model::Sprint;
use MyApp::Repo::Sprint;

has repo   => (is => 'lazy');
has logger => (is => 'ro', required => 1);

sub _build_repo { MyApp::Repo::Sprint->new }

sub create_sprint {
    my ($self, %attrs) = @_;
    my $sprint = MyApp::Model::Sprint->new(%attrs);
    $self->repo->add($sprint);
    $self->logger->info("Created sprint: " . $sprint->name);
    return $sprint;
}

sub find_sprint    { $_[0]->repo->find($_[1]) }
sub all_sprints    { $_[0]->repo->all }
sub delete_sprint  { $_[0]->repo->remove($_[1]) }

1;
