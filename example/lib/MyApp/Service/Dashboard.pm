package MyApp::Service::Dashboard;
use Moo;
use MyApp::Report::ProjectSnapshot;
use MyApp::Report::TaskMatrix;
use MyApp::Service::TemplateRenderer;
use MyApp::Service::Timeline;
use MyApp::Service::XmlReport;

has snapshot  => (is => 'lazy');
has matrix    => (is => 'lazy');
has renderer  => (is => 'lazy');
has timeline  => (is => 'lazy');
has xml_report => (is => 'lazy');

sub _build_snapshot   { MyApp::Report::ProjectSnapshot->new }
sub _build_matrix     { MyApp::Report::TaskMatrix->new }
sub _build_renderer   { MyApp::Service::TemplateRenderer->new }
sub _build_timeline   { MyApp::Service::Timeline->new }
sub _build_xml_report { MyApp::Service::XmlReport->new }

sub build {
    my ($self, $project, $tasks) = @_;
    return {
        snapshot => $self->snapshot->from_project($project, $tasks),
        summary  => $self->renderer->render_project_summary($project, $tasks),
        matrix   => $self->matrix->render($tasks),
        xml      => $self->xml_report->project_to_xml($project, $tasks),
    };
}

1;
