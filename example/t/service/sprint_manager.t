use strict;
use warnings;
use Test::More tests => 5;
use MyApp::Service::SprintManager;
use MyApp::Logger;

my $mgr = MyApp::Service::SprintManager->new(logger => MyApp::Logger->new);

my $s = $mgr->create_sprint(name => 'Sprint 1', project_id => 'p1', start_date => '2025-01-01', end_date => '2025-01-14');
ok($s, 'sprint created');
is($s->name, 'Sprint 1', 'name correct');

my $found = $mgr->find_sprint($s->id);
is($found->name, 'Sprint 1', 'found by id');

is(scalar @{$mgr->all_sprints}, 1, 'one sprint');
$mgr->delete_sprint($s->id);
is(scalar @{$mgr->all_sprints}, 0, 'deleted');
