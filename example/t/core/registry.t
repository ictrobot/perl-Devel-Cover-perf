use strict;
use warnings;
use Test::More tests => 6;
use MyApp::Registry;

my $r = MyApp::Registry->new;
is($r->count, 0, 'empty');

$r->register('logger', { name => 'test' });
is($r->count, 1, 'one service');
ok($r->has_service('logger'), 'has logger');
ok(!$r->has_service('missing'), 'no missing');

my $svc = $r->resolve('logger');
is($svc->{name}, 'test', 'resolved');

my @services = $r->services;
is(scalar @services, 1, 'one service listed');
