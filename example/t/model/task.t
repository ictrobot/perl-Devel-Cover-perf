use strict;
use warnings;
use Test::More tests => 14;

use_ok('MyApp::Model::Task');

my $task = MyApp::Model::Task->new(title => 'Do something');
isa_ok($task, 'MyApp::Model::Task');

is($task->status, 'open', 'default status');
is($task->priority, 'medium', 'default priority');
is($task->progress, 0, 'default progress');
ok($task->is_valid, 'valid task');
ok(!$task->is_done, 'not done');

$task->assign_to('user-1');
is($task->assignee_id, 'user-1', 'assigned');
is($task->audit_count, 1, 'audit recorded');

$task->change_status('done');
is($task->status, 'done', 'status changed');
is($task->progress, 100, 'progress set to 100');
ok($task->is_done, 'is done');
is($task->audit_count, 2, 'two audits');

my $bad = MyApp::Model::Task->new(title => 'X');
ok(!$bad->is_valid, 'short title invalid');
