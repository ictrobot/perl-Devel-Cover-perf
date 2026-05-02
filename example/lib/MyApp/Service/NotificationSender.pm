package MyApp::Service::NotificationSender;
use Moo;
use MyApp::Model::Notification;
use MyApp::Repo::Notification;

has repo   => (is => 'lazy');
has logger => (is => 'ro', required => 1);

sub _build_repo { MyApp::Repo::Notification->new }

sub notify {
    my ($self, %attrs) = @_;
    my $n = MyApp::Model::Notification->new(%attrs);
    $self->repo->add($n);
    $self->logger->info("Sent notification to " . $n->user_id);
    return $n;
}

sub unread_for { [grep { $_->is_unread } @{$_[0]->repo->where('user_id', $_[1])}] }
sub mark_all_read {
    my ($self, $user_id) = @_;
    $_->mark_read for @{$self->repo->where('user_id', $user_id)};
}

1;
