use strict;
use warnings;
use Test::More tests => 6;
use MyApp::Util::String qw(truncate_str);

is(truncate_str('short', 10), 'short', 'no truncation needed');
is(truncate_str('hello world', 5), 'hello...', 'basic truncate');
is(truncate_str('hello world', 5, '~'), 'hello~', 'custom suffix');
is(truncate_str('', 10), '', 'empty string');
is(truncate_str('exact', 5), 'exact', 'exact length');
is(truncate_str('abcdef', 3), 'abc...', 'short limit');
