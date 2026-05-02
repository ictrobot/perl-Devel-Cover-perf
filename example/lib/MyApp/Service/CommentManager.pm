package MyApp::Service::CommentManager;
use Moo;
use MyApp::Model::Comment;
use MyApp::Repo::Comment;

has repo   => (is => 'lazy');
has logger => (is => 'ro', required => 1);

sub _build_repo { MyApp::Repo::Comment->new }

sub add_comment {
    my ($self, %attrs) = @_;
    my $c = MyApp::Model::Comment->new(%attrs);
    $self->repo->add($c);
    $self->logger->info("Comment added to task " . $c->task_id);
    return $c;
}

sub comments_for_task { $_[0]->repo->where('task_id', $_[1]) }
sub find_comment      { $_[0]->repo->find($_[1]) }
sub delete_comment    { $_[0]->repo->remove($_[1]) }

1;
