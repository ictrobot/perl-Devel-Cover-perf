package MyApp::Service::UserManager;
use Moo;
use MyApp::Model::User;
use MyApp::Repo::User;

has repo   => (is => 'lazy');
has logger => (is => 'ro', required => 1);

sub _build_repo { MyApp::Repo::User->new }

sub create_user {
    my ($self, %attrs) = @_;
    my $user = MyApp::Model::User->new(%attrs);
    if ($user->is_valid) {
        $self->repo->add($user);
        $self->logger->info("Created user: " . $user->username);
        return $user;
    }
    return undef;
}

sub find_user     { $_[0]->repo->find($_[1]) }
sub all_users     { $_[0]->repo->all }
sub delete_user   { my $u = $_[0]->repo->remove($_[1]); $_[0]->logger->info("Deleted user $_[1]") if $u; $u }
sub find_by_email { @{$_[0]->repo->where('email', $_[1])}[0] }

1;
