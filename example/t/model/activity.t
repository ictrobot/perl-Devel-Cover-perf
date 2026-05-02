use strict;
use warnings;
use Test::More tests => 3;
use MyApp::Model::Activity;

my $a = MyApp::Model::Activity->new(
    actor_id => 'u1', action => 'created', target_type => 'task', target_id => 't1',
);
isa_ok($a, 'MyApp::Model::Activity');
like($a->summary, qr/u1 created task/, 'summary');
is($a->action, 'created', 'action set');
