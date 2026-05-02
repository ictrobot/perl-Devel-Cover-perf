package MyApp::Service::MilestoneManager;
use Moo;
use MyApp::Model::Milestone;
use MyApp::Repo::Milestone;

has repo   => (is => 'lazy');
has logger => (is => 'ro', required => 1);

sub _build_repo { MyApp::Repo::Milestone->new }

sub create_milestone {
    my ($self, %attrs) = @_;
    my $m = MyApp::Model::Milestone->new(%attrs);
    $self->repo->add($m);
    $self->logger->info("Created milestone: " . $m->title);
    return $m;
}

sub find_milestone   { $_[0]->repo->find($_[1]) }
sub all_milestones   { $_[0]->repo->all }
sub delete_milestone { $_[0]->repo->remove($_[1]) }

1;
