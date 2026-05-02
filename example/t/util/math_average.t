use strict;
use warnings;
use Test::More tests => 5;
use MyApp::Util::Math qw(average);

is(average(1, 2, 3), 2, 'simple');
is(average(10), 10, 'single');
is(average(0, 0, 0), 0, 'zeros');
is(average(1, 2, 3, 4, 5, 6, 7, 8, 9, 10), 5.5, 'larger set');
is(average(), 0, 'empty');
