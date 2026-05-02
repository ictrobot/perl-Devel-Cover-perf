use strict;
use warnings;
use Test::More tests => 7;
use MyApp::Service::TemplateRenderer;
use MyApp::Model::Project;
use MyApp::Model::Task;

my $renderer = MyApp::Service::TemplateRenderer->new;
my $project = MyApp::Model::Project->new(
    name        => 'Tooling Fixture',
    description => 'A deliberately noisy project',
    status      => 'open',
);
my @tasks = (
    MyApp::Model::Task->new(title => 'Expand modules', status => 'open', priority => 'high', due_date => '2026-05-04'),
    MyApp::Model::Task->new(title => 'Write tests', status => 'done', priority => 'medium', due_date => '2026-05-06'),
);

my $summary = $renderer->render_project_summary($project, \@tasks);
like($summary, qr/Project: Tooling Fixture/, 'renders project name');
like($summary, qr/Status: open/, 'renders project status');
like($summary, qr/\[open\] Expand modules/, 'renders open task');
like($summary, qr/\[done\] Write tests/, 'renders done task');

my $table = $renderer->render_task_table(\@tasks);
like($table, qr/Expand modules\|open\|high\|2026-05-04/, 'renders pipe table row');
like($table, qr/Write tests\|done\|medium\|2026-05-06/, 'renders second table row');

is($renderer->render_string('Hello [% name %]', { name => 'Template' }), 'Hello Template', 'renders ad hoc template');
