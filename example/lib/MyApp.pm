package MyApp;
use Moo;
use Types::Standard qw(Str);
use MyApp::Service::TemplateRenderer;
use MyApp::Service::Timeline;
use MyApp::Service::XmlReport;
use MyApp::Service::Dashboard;
use MyApp::Service::DigestBuilder;
use MyApp::Service::ReleasePlanner;
use MyApp::Service::RuleCompiler;
use MyApp::Service::XmlExchange;
use MyApp::Service::OrmCatalog;
use MyApp::Service::SchemaTooling;

our $VERSION = '0.01';

has name    => (is => 'ro', isa => Str, default => 'MyApp');
has version => (is => 'ro', isa => Str, default => sub { $VERSION });
has template_renderer => (is => 'lazy');
has timeline          => (is => 'lazy');
has xml_report        => (is => 'lazy');
has dashboard         => (is => 'lazy');
has digest_builder    => (is => 'lazy');
has release_planner   => (is => 'lazy');
has rule_compiler     => (is => 'lazy');
has xml_exchange      => (is => 'lazy');
has orm_catalog       => (is => 'lazy');
has schema_tooling    => (is => 'lazy');

sub _build_template_renderer { MyApp::Service::TemplateRenderer->new }
sub _build_timeline          { MyApp::Service::Timeline->new }
sub _build_xml_report        { MyApp::Service::XmlReport->new }
sub _build_dashboard         { MyApp::Service::Dashboard->new }
sub _build_digest_builder    { MyApp::Service::DigestBuilder->new }
sub _build_release_planner   { MyApp::Service::ReleasePlanner->new }
sub _build_rule_compiler     { MyApp::Service::RuleCompiler->new }
sub _build_xml_exchange      { MyApp::Service::XmlExchange->new }
sub _build_orm_catalog       { MyApp::Service::OrmCatalog->new }
sub _build_schema_tooling    { MyApp::Service::SchemaTooling->new }

sub description { 'A task management application built with Moo and Mojolicious' }

sub render_project_summary {
    my ($self, $project, $tasks) = @_;
    return $self->template_renderer->render_project_summary($project, $tasks // []);
}

sub project_xml_report {
    my ($self, $project, $tasks) = @_;
    return $self->xml_report->project_to_xml($project, $tasks // []);
}

sub due_status {
    my ($self, $date) = @_;
    return $self->timeline->status_for_due_date($date);
}

sub build_dashboard {
    my ($self, $project, $tasks) = @_;
    return $self->dashboard->build($project, $tasks // []);
}

sub build_digest {
    my ($self, $project, $tasks) = @_;
    return $self->digest_builder->build_project_digest($project, $tasks // []);
}

sub task_matches_rule {
    my ($self, $rule, $task) = @_;
    return $self->rule_compiler->evaluate_rule($rule, $task);
}

sub schema_summary {
    my $self = shift;
    return $self->orm_catalog->describe_schema;
}

sub schema_tooling_summary {
    my $self = shift;
    return $self->schema_tooling->summary;
}

1;
