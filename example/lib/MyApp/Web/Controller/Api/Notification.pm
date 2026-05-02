package MyApp::Web::Controller::Api::Notification;
use Mojo::Base 'Mojolicious::Controller', -signatures;

my @NOTIFICATIONS = (
    { id => '1', user_id => '1', type => 'mention',    message => 'You were mentioned', read => 0 },
    { id => '2', user_id => '1', type => 'assignment',  message => 'Task assigned',      read => 1 },
    { id => '3', user_id => '2', type => 'comment',     message => 'New comment',         read => 0 },
);

sub list ($self) {
    my $user_id = $self->param('user_id');
    my @filtered = $user_id ? grep { $_->{user_id} eq $user_id } @NOTIFICATIONS : @NOTIFICATIONS;
    $self->render(json => { notifications => \@filtered });
}

sub mark_read ($self) {
    my $id = $self->param('id');
    my ($n) = grep { $_->{id} eq $id } @NOTIFICATIONS;
    return $self->render(json => { error => 'Not found' }, status => 404) unless $n;
    $n->{read} = 1;
    $self->render(json => $n);
}

1;
