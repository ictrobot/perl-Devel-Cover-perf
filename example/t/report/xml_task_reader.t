use strict;
use warnings;
use Test::More tests => 6;
use MyApp::Report::XmlTaskReader;

my $reader = MyApp::Report::XmlTaskReader->new;
my $tasks = $reader->parse_tasks('<tasks><task title="Import me" status="open" priority="high" due_date="2026-05-04" /></tasks>');
is(scalar @$tasks, 1, 'parses one task');
is($tasks->[0]{title}, 'Import me', 'parses title');
is($tasks->[0]{status}, 'open', 'parses status');
is($tasks->[0]{priority}, 'high', 'parses priority');

my $xml = $reader->tasks_to_xml([{ title => 'Export me', status => 'done', priority => 'low', due_date => '2026-05-05' }]);
like($xml, qr/title="Export me"/, 'exports title');
like($xml, qr/status="done"/, 'exports status');
