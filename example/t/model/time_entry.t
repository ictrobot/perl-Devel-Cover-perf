use strict;
use warnings;
use Test::More tests => 5;
use MyApp::Model::TimeEntry;

my $te = MyApp::Model::TimeEntry->new(task_id => 't1', user_id => 'u1', hours => 2.5, date => '2025-01-15');
isa_ok($te, 'MyApp::Model::TimeEntry');
is($te->hours, 2.5, 'hours set');
is($te->minutes, 150, 'minutes calculated');
ok($te->is_billable, 'billable by default');

$te->billable(0);
ok(!$te->is_billable, 'not billable');
