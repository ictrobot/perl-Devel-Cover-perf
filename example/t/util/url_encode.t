use strict;
use warnings;
use Test::More tests => 8;
use MyApp::Util::URL qw(url_encode url_decode);

is(url_encode('hello world'), 'hello%20world', 'space');
is(url_encode('a+b'), 'a%2Bb', 'plus');
is(url_encode('foo/bar'), 'foo%2Fbar', 'slash');
is(url_encode('safe-chars_here.ok~'), 'safe-chars_here.ok~', 'safe passthrough');

is(url_decode('hello%20world'), 'hello world', 'decode space');
is(url_decode('a%2Bb'), 'a+b', 'decode plus');
is(url_decode('no%encoding'), 'no%encoding', 'partial percent');
is(url_decode(''), '', 'empty');
