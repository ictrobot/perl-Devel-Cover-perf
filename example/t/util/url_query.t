use strict;
use warnings;
use Test::More tests => 6;
use MyApp::Util::URL qw(build_query parse_query);

my $qs = build_query(a => '1', b => '2');
like($qs, qr/a=1/, 'has a');
like($qs, qr/b=2/, 'has b');
like($qs, qr/&/, 'joined');

my %p = parse_query('foo=bar&baz=qux');
is($p{foo}, 'bar', 'parse foo');
is($p{baz}, 'qux', 'parse baz');

my %empty = parse_query('');
is(scalar keys %empty, 0, 'empty query');
