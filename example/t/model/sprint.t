use strict;
use warnings;
use Test::More tests => 7;
use MyApp::Model::Sprint;

my $s = MyApp::Model::Sprint->new(
    name => 'Sprint 1', project_id => 'p1',
    start_date => '2025-01-01', end_date => '2025-01-14',
);
isa_ok($s, 'MyApp::Model::Sprint');
is($s->task_count, 0, 'no tasks');

$s->add_task('t1');
$s->add_task('t2');
is($s->task_count, 2, 'two tasks');

$s->remove_task('t1');
is($s->task_count, 1, 'one task after remove');

is($s->goal, '', 'no goal');
$s->goal('Deliver MVP');
is($s->goal, 'Deliver MVP', 'goal set');
is($s->velocity, 0, 'default velocity');
