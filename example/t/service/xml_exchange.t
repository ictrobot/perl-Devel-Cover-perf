use strict;
use warnings;
use Test::More tests => 6;
use MyApp::Service::XmlExchange;
use MyApp::Service::XmlReport;
use MyApp::Model::Project;

my $exchange = MyApp::Service::XmlExchange->new;
my $tasks_xml = $exchange->export_tasks([{ title => 'Round trip', status => 'open', priority => 'high' }]);
like($tasks_xml, qr/title="Round trip"/, 'exports tasks');

my $tasks = $exchange->import_tasks($tasks_xml);
is($tasks->[0]{title}, 'Round trip', 'imports task title');
is($tasks->[0]{priority}, 'high', 'imports priority');

my $report = MyApp::Service::XmlReport->new->project_to_xml(MyApp::Model::Project->new(name => 'Exchange Project'), []);
my $archive = $exchange->export_archive([$report]);
like($archive, qr/<archive>/, 'exports archive');
is_deeply($exchange->archive_names($archive), ['Exchange Project'], 'reads archive names');
like($archive, qr/name="Exchange Project"/, 'archive includes project');
