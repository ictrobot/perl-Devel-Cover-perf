use strict;
use warnings;
use Test::More tests => 6;
use MyApp::Service::Permissions;

my $perms = MyApp::Service::Permissions->new;
ok(!$perms->can_perform('u1', 'task:create'), 'no permission');

$perms->grant('u1', 'task:create');
$perms->grant('u1', 'task:read');
ok($perms->can_perform('u1', 'task:create'), 'granted');

my $list = $perms->permissions_for('u1');
is(scalar @$list, 2, 'two permissions');

$perms->revoke('u1', 'task:create');
ok(!$perms->can_perform('u1', 'task:create'), 'revoked');
is(scalar @{$perms->permissions_for('u1')}, 1, 'one left');

ok(!$perms->can_perform('u2', 'anything'), 'unknown user');
