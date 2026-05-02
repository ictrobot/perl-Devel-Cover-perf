package MyApp::Container;
use Moo;
use MyApp::Config;
use MyApp::Logger;
use MyApp::Registry;
use MyApp::EventBus;
use MyApp::Service::TemplateRenderer;
use MyApp::Service::Timeline;
use MyApp::Service::XmlReport;
use MyApp::Service::Dashboard;
use MyApp::Service::DigestBuilder;
use MyApp::Service::ReleasePlanner;
use MyApp::Service::XmlExchange;
use MyApp::Service::OrmCatalog;
use MyApp::Service::SchemaTooling;

has config            => (is => 'lazy');
has logger            => (is => 'lazy');
has registry          => (is => 'lazy');
has event_bus         => (is => 'lazy');
has template_renderer => (is => 'lazy');
has timeline          => (is => 'lazy');
has xml_report        => (is => 'lazy');
has dashboard         => (is => 'lazy');
has digest_builder    => (is => 'lazy');
has release_planner   => (is => 'lazy');
has xml_exchange      => (is => 'lazy');
has orm_catalog       => (is => 'lazy');
has schema_tooling    => (is => 'lazy');

sub _build_config            { MyApp::Config->new }
sub _build_logger            { MyApp::Logger->new }
sub _build_registry          { MyApp::Registry->new }
sub _build_event_bus         { MyApp::EventBus->new }
sub _build_template_renderer { MyApp::Service::TemplateRenderer->new }
sub _build_timeline          { MyApp::Service::Timeline->new }
sub _build_xml_report        { MyApp::Service::XmlReport->new }
sub _build_dashboard         { MyApp::Service::Dashboard->new }
sub _build_digest_builder    { MyApp::Service::DigestBuilder->new }
sub _build_release_planner   { MyApp::Service::ReleasePlanner->new }
sub _build_xml_exchange      { MyApp::Service::XmlExchange->new }
sub _build_orm_catalog       { MyApp::Service::OrmCatalog->new }
sub _build_schema_tooling    { MyApp::Service::SchemaTooling->new }

sub bootstrap {
    my $self = shift;
    $self->logger->info("Bootstrapping " . $self->config->app_name);
    $self->registry->register(config    => $self->config);
    $self->registry->register(logger    => $self->logger);
    $self->registry->register(event_bus => $self->event_bus);
    $self->registry->register(template_renderer => $self->template_renderer);
    $self->registry->register(timeline          => $self->timeline);
    $self->registry->register(xml_report        => $self->xml_report);
    $self->registry->register(dashboard         => $self->dashboard);
    $self->registry->register(digest_builder    => $self->digest_builder);
    $self->registry->register(release_planner   => $self->release_planner);
    $self->registry->register(xml_exchange      => $self->xml_exchange);
    $self->registry->register(orm_catalog       => $self->orm_catalog);
    $self->registry->register(schema_tooling    => $self->schema_tooling);
    return $self;
}

1;
