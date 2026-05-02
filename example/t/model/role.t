use strict;
use warnings;
use Test::More tests => 6;
use MyApp::Model::Role;

my $r = MyApp::Model::Role->new(name => 'editor');
isa_ok($r, 'MyApp::Model::Role');
is($r->name, 'editor', 'name set');
ok(!$r->has_permission('write'), 'no permission yet');

$r->grant('write');
$r->grant('read');
$r->grant('write');
is(scalar @{$r->permissions}, 2, 'no duplicate grants');
ok($r->has_permission('write'), 'has write');

$r->revoke('write');
ok(!$r->has_permission('write'), 'write revoked');
