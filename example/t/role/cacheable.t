use strict;
use warnings;
use Test::More tests => 4;

{
    package TestCacheable;
    use Moo;
    with 'MyApp::Role::HasUUID', 'MyApp::Role::Cacheable';
}

my $obj = TestCacheable->new(cache_ttl => 60);
is($obj->cache_ttl, 60, 'ttl set');
ok($obj->cache_key, 'has cache key');
ok(!$obj->is_cache_expired(time), 'not expired');
ok($obj->is_cache_expired(time - 120), 'expired');
