package MyApp::Web::Controller::Api::User;
use Mojo::Base 'Mojolicious::Controller', -signatures;

my @USERS = (
    { id => '1', username => 'alice', email => 'alice@example.com', role => 'admin' },
    { id => '2', username => 'bob',   email => 'bob@example.com',   role => 'member' },
    { id => '3', username => 'carol', email => 'carol@example.com', role => 'member' },
);

sub list ($self) {
    $self->render(json => { users => \@USERS, total => scalar @USERS });
}

sub show ($self) {
    my $id = $self->param('id');
    my ($user) = grep { $_->{id} eq $id } @USERS;
    return $self->render(json => { error => 'Not found' }, status => 404) unless $user;
    $self->render(json => $user);
}

sub create ($self) {
    my $body = $self->req->json // {};
    $body->{id} = scalar(@USERS) + 1;
    push @USERS, $body;
    $self->render(json => $body, status => 201);
}

1;
