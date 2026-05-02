use strict;
use warnings;
use Test::More tests => 9;
use MyApp::Model::Team;

my $team = MyApp::Model::Team->new(name => 'Backend');
isa_ok($team, 'MyApp::Model::Team');
is($team->name, 'Backend', 'name set');
is($team->member_count, 0, 'no members');

$team->add_member('u1');
$team->add_member('u2');
$team->add_member('u1');
is($team->member_count, 2, 'no duplicates');
ok($team->has_member('u1'), 'has member');
ok(!$team->has_member('u3'), 'does not have member');

$team->remove_member('u1');
is($team->member_count, 1, 'member removed');
ok(!$team->has_member('u1'), 'removed member gone');
ok($team->has_member('u2'), 'other member still there');
