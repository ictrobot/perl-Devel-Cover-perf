use strict;
use warnings;
use Test::More tests => 5;
use MyApp::Util::Math qw(average median percentage clamp);

is(average(2, 4, 6), 4, 'averages');
is(median(9, 1, 5), 5, 'median odd count');
is(median(1, 3, 5, 7), 4, 'median even count');
is(percentage(2, 8), '25.0', 'percentage');
is(clamp(10, 1, 5), 5, 'clamps high value');
