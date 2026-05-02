use strict;
use warnings;
use Test::More tests => 26;
use MyApp;
use MyApp::Container;
use MyApp::Model::Project;
use MyApp::Model::Task;

my $app = MyApp->new;
isa_ok($app->template_renderer, 'MyApp::Service::TemplateRenderer');
isa_ok($app->timeline, 'MyApp::Service::Timeline');
isa_ok($app->xml_report, 'MyApp::Service::XmlReport');
isa_ok($app->dashboard, 'MyApp::Service::Dashboard');
isa_ok($app->digest_builder, 'MyApp::Service::DigestBuilder');
isa_ok($app->release_planner, 'MyApp::Service::ReleasePlanner');
isa_ok($app->xml_exchange, 'MyApp::Service::XmlExchange');
isa_ok($app->orm_catalog, 'MyApp::Service::OrmCatalog');
isa_ok($app->schema_tooling, 'MyApp::Service::SchemaTooling');

my $project = MyApp::Model::Project->new(name => 'Integrated Project', status => 'open');
my @tasks = (
    MyApp::Model::Task->new(title => 'Render summary', status => 'open', due_date => '2026-05-04'),
);

like($app->render_project_summary($project, \@tasks), qr/Integrated Project/, 'app renders project summary');
like($app->project_xml_report($project, \@tasks), qr/<project_report/, 'app emits xml report');
like($app->due_status('2099-01-01'), qr/^(due_soon|scheduled)$/, 'app delegates due status');
like($app->build_digest($project, \@tasks), qr/Integrated Project/, 'app builds digest');
is($app->build_dashboard($project, \@tasks)->{snapshot}{total_tasks}, 1, 'app builds dashboard snapshot');
is($app->schema_summary->{schema}, 'MyApp::Schema', 'app exposes schema summary');
is(scalar @{$app->schema_summary->{sources}}, 3, 'schema summary includes sources');
is($app->schema_tooling_summary->{loader_options}{use_moose}, 1, 'app exposes Moose loader option');
is($app->schema_tooling_summary->{translated_to_yaml}, 1, 'app exposes SQL translator summary');

my $container = MyApp::Container->new->bootstrap;
ok($container->registry->has_service('template_renderer'), 'container registers template renderer');
ok($container->registry->has_service('timeline'), 'container registers timeline');
ok($container->registry->has_service('xml_report'), 'container registers xml report');
ok($container->registry->has_service('dashboard'), 'container registers dashboard');
ok($container->registry->has_service('xml_exchange'), 'container registers xml exchange');
ok($container->registry->has_service('orm_catalog'), 'container registers orm catalog');
ok($container->registry->has_service('schema_tooling'), 'container registers schema tooling');
is($container->registry->count, 12, 'container has original, reporting, ORM, and optional tooling services');
