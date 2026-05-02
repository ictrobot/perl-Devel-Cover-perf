use strict;
use warnings;
use Test::More tests => 5;
use MyApp::Util::URL qw(build_query parse_query url_encode url_decode);

is(url_encode('a b+c'), 'a%20b%2Bc', 'encodes reserved characters');
is(url_decode('a%20b%2Bc'), 'a b+c', 'decodes reserved characters');
like(build_query(b => 2, a => 1), qr/(?:a=1&b=2|b=2&a=1)/, 'builds query');
my %parsed = parse_query('a=1&b=two');
is_deeply(\%parsed, { a => '1', b => 'two' }, 'parses query');
my %empty = parse_query('empty=');
is_deeply(\%empty, { empty => '' }, 'keeps empty values');
