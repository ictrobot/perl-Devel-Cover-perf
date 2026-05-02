package MyApp::Service::ProjectManager;
use Moo;
use MyApp::Model::Project;
use MyApp::Repo::Project;

has repo   => (is => 'lazy');
has logger => (is => 'ro', required => 1);

sub _build_repo { MyApp::Repo::Project->new }

sub create_project {
    my ($self, %attrs) = @_;
    my $project = MyApp::Model::Project->new(%attrs);
    $self->repo->add($project);
    $self->logger->info("Created project: " . $project->name);
    return $project;
}

sub find_project    { $_[0]->repo->find($_[1]) }
sub all_projects    { $_[0]->repo->all }
sub delete_project  { $_[0]->repo->remove($_[1]) }
sub active_projects { [grep { $_->is_active } @{$_[0]->repo->all}] }

1;
