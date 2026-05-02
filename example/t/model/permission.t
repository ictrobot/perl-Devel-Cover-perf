use strict;
use warnings;
use Test::More tests => 5;
use MyApp::Model::Permission;

my $p = MyApp::Model::Permission->new(resource => 'task', action => 'create');
isa_ok($p, 'MyApp::Model::Permission');
is($p->key, 'task:create', 'key');
ok(!$p->is_global, 'not global by default');
like($p->description, qr/Can create task/, 'description');

my $g = MyApp::Model::Permission->new(resource => 'project', action => 'delete', scope => 'global');
ok($g->is_global, 'global scope');
