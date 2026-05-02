use strict;
use warnings;
use Test::More tests => 4;
use MyApp::Config;

my $config = MyApp::Config->new(env => 'test', data => { feature => 'on' });
ok($config->is_test, 'test environment');
ok(!$config->is_development, 'not development');
is($config->get('feature'), 'on', 'reads configured value');
is($config->get('missing', 'fallback'), 'fallback', 'returns fallback');
