use strict;
use warnings;
use Test::More tests => 6;
use MyApp::Config;

my $c = MyApp::Config->new(env => 'test', data => { db_host => 'localhost' });
is($c->env, 'test', 'env set');
ok($c->is_test, 'is test');
ok(!$c->is_production, 'not production');
is($c->app_name, 'MyApp', 'default app name');
is($c->get('db_host'), 'localhost', 'get data');
is($c->get('missing', 'default'), 'default', 'get with default');
