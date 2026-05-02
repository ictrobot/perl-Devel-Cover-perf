package MyApp::Service::DigestBuilder;
use Moo;
use MyApp::Report::ProjectSnapshot;
use MyApp::Report::TemplateBundle;
use MyApp::Report::TaskMatrix;

has snapshot => (is => 'lazy');
has bundle   => (is => 'lazy');
has matrix   => (is => 'lazy');

sub _build_snapshot { MyApp::Report::ProjectSnapshot->new }
sub _build_bundle   { MyApp::Report::TemplateBundle->new }
sub _build_matrix   { MyApp::Report::TaskMatrix->new }

sub build_project_digest {
    my ($self, $project, $tasks) = @_;
    my $snapshot = $self->snapshot->from_project($project, $tasks);
    return join "\n",
        $self->bundle->render('project_digest', $snapshot),
        $self->matrix->render($tasks);
}

1;
