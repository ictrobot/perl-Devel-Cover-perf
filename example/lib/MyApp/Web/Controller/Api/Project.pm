package MyApp::Web::Controller::Api::Project;
use Mojo::Base 'Mojolicious::Controller', -signatures;

my @PROJECTS = (
    { id => '1', name => 'Alpha', status => 'open', member_count => 5 },
    { id => '2', name => 'Beta',  status => 'open', member_count => 3 },
);

sub list ($self) {
    $self->render(json => { projects => \@PROJECTS });
}

sub show ($self) {
    my $id = $self->param('id');
    my ($proj) = grep { $_->{id} eq $id } @PROJECTS;
    return $self->render(json => { error => 'Not found' }, status => 404) unless $proj;
    $self->render(json => $proj);
}

sub create ($self) {
    my $body = $self->req->json // {};
    $body->{id} = scalar(@PROJECTS) + 1;
    push @PROJECTS, $body;
    $self->render(json => $body, status => 201);
}

1;
