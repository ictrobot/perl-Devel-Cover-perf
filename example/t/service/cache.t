use strict;
use warnings;
use Test::More tests => 7;
use MyApp::Service::Cache;

my $cache = MyApp::Service::Cache->new(default_ttl => 300);
is($cache->count, 0, 'empty');

$cache->set('key1', 'value1');
is($cache->get('key1'), 'value1', 'get after set');
is($cache->count, 1, 'one entry');

$cache->set('key2', { data => 42 });
is($cache->count, 2, 'two entries');

$cache->delete('key1');
is($cache->count, 1, 'one after delete');
ok(!defined $cache->get('key1'), 'deleted key gone');

$cache->clear;
is($cache->count, 0, 'cleared');
