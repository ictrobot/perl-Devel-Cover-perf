package MyApp::Web::Controller::Api::Milestone;
use Mojo::Base 'Mojolicious::Controller', -signatures;

my @MILESTONES = (
    { id => '1', title => 'v1.0 Release',  project_id => '1', completed => 0 },
    { id => '2', title => 'Beta Launch',    project_id => '1', completed => 1 },
    { id => '3', title => 'v2.0 Planning',  project_id => '2', completed => 0 },
);

sub list ($self) {
    $self->render(json => { milestones => \@MILESTONES, total => scalar @MILESTONES });
}

sub show ($self) {
    my $id = $self->param('id');
    my ($m) = grep { $_->{id} eq $id } @MILESTONES;
    return $self->render(json => { error => 'Not found' }, status => 404) unless $m;
    $self->render(json => $m);
}

1;
