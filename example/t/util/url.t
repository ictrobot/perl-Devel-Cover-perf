use strict;
use warnings;
use Test::More tests => 4;
use MyApp::Util::URL qw(build_query parse_query url_encode url_decode);

is(url_encode('hello world'), 'hello%20world', 'encode');
is(url_decode('hello%20world'), 'hello world', 'decode');

my $qs = build_query(foo => 'bar', baz => 'qux');
like($qs, qr/foo=bar/, 'build query');

my %parsed = parse_query('a=1&b=2');
is($parsed{a}, '1', 'parse query');
