package MyApp::Service::TagManager;
use Moo;
use MyApp::Model::Tag;
use MyApp::Repo::Tag;

has repo   => (is => 'lazy');
has logger => (is => 'ro', required => 1);

sub _build_repo { MyApp::Repo::Tag->new }

sub create_tag {
    my ($self, %attrs) = @_;
    my $tag = MyApp::Model::Tag->new(%attrs);
    $self->repo->add($tag);
    $self->logger->info("Created tag: " . $tag->name);
    return $tag;
}

sub find_tag   { $_[0]->repo->find($_[1]) }
sub all_tags   { $_[0]->repo->all }
sub delete_tag { $_[0]->repo->remove($_[1]) }

1;
