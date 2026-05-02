use strict;
use warnings;
use Test::More tests => 8;
use MyApp::Service::XmlReport;
use MyApp::Model::Project;
use MyApp::Model::Task;

my $report = MyApp::Service::XmlReport->new;
my $project = MyApp::Model::Project->new(
    name        => 'XML Project',
    description => 'Serializes task state',
    status      => 'open',
);
my @tasks = (
    MyApp::Model::Task->new(title => 'Parse feed',  status => 'open', priority => 'high', due_date => '2026-05-03'),
    MyApp::Model::Task->new(title => 'Emit report', status => 'done', priority => 'low',  due_date => '2026-05-04'),
);

my $xml = $report->project_to_xml($project, \@tasks);
like($xml, qr/<project_report/, 'creates root node');
like($xml, qr/name="XML Project"/, 'sets project name');
like($xml, qr/<title>Parse feed<\/title>/, 'adds first task title');
like($xml, qr/status="done"/, 'adds task status attribute');

my $summary = $report->summarize($xml);
is($summary->{name}, 'XML Project', 'summarizes name');
is($summary->{status}, 'open', 'summarizes status');
is($summary->{task_count}, 2, 'summarizes task count');

is_deeply($report->task_titles($xml), ['Parse feed', 'Emit report'], 'extracts task titles');
