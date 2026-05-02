use strict;
use warnings;
use Test::More tests => 8;

use_ok('MyApp::Service::TaskManager');
use_ok('MyApp::Logger');
use_ok('MyApp::EventBus');

my $bus = MyApp::EventBus->new;
my $events = 0;
$bus->on('task.created', sub { $events++ });
$bus->on('task.updated', sub { $events++ });

my $mgr = MyApp::Service::TaskManager->new(logger => MyApp::Logger->new, event_bus => $bus);

my $task = $mgr->create_task(title => 'Build feature');
ok($task, 'task created');
is($events, 1, 'created event fired');

my $found = $mgr->find_task($task->id);
is($found->title, 'Build feature', 'found by id');

$mgr->update_status($task->id, 'done');
is($events, 2, 'updated event fired');
is($found->status, 'done', 'status updated');
