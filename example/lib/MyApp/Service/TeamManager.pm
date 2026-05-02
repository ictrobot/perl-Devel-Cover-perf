package MyApp::Service::TeamManager;
use Moo;
use MyApp::Model::Team;
use MyApp::Repo::Team;

has repo   => (is => 'lazy');
has logger => (is => 'ro', required => 1);

sub _build_repo { MyApp::Repo::Team->new }

sub create_team {
    my ($self, %attrs) = @_;
    my $team = MyApp::Model::Team->new(%attrs);
    $self->repo->add($team);
    $self->logger->info("Created team: " . $team->name);
    return $team;
}

sub find_team    { $_[0]->repo->find($_[1]) }
sub all_teams    { $_[0]->repo->all }
sub delete_team  { $_[0]->repo->remove($_[1]) }

1;
