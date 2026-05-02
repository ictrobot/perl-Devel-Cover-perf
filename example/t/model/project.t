use strict;
use warnings;
use Test::More tests => 10;

use_ok('MyApp::Model::Project');

my $proj = MyApp::Model::Project->new(name => 'Alpha');
isa_ok($proj, 'MyApp::Model::Project');

is($proj->name, 'Alpha', 'name set');
is($proj->status, 'open', 'default status');
ok($proj->is_active, 'is active');
is($proj->member_count, 0, 'no members');

$proj->add_member('user-1');
$proj->add_member('user-2');
$proj->add_member('user-1');
is($proj->member_count, 2, 'no duplicate members');

$proj->remove_member('user-1');
is($proj->member_count, 1, 'member removed');

$proj->assign_owner('owner-1');
ok($proj->is_owned_by('owner-1'), 'owner assigned');
ok(!$proj->is_owned_by('other'), 'not owned by other');
