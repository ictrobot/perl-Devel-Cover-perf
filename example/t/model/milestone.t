use strict;
use warnings;
use Test::More tests => 7;
use MyApp::Model::Milestone;

my $m = MyApp::Model::Milestone->new(title => 'v1.0', project_id => 'p1');
isa_ok($m, 'MyApp::Model::Milestone');
is($m->progress, 0, 'no progress');
ok(!$m->completed, 'not completed');

$m->task_count(10);
$m->done_count(3);
is($m->progress, 30, '30% progress');

$m->done_count(10);
is($m->progress, 100, '100% progress');

$m->complete;
ok($m->completed, 'completed');
is($m->title, 'v1.0', 'title preserved');
