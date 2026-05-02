use strict;
use warnings;
use Test::More tests => 5;
use MyApp::Util::Math qw(median);

is(median(1, 3, 5), 3, 'odd count');
is(median(1, 2, 3, 4), 2.5, 'even count');
is(median(42), 42, 'single');
is(median(5, 1, 3), 3, 'unsorted');
is(median(), 0, 'empty');
