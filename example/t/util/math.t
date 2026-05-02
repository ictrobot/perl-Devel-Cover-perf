use strict;
use warnings;
use Test::More tests => 5;
use MyApp::Util::Math qw(average median percentage clamp);

is(average(1, 2, 3, 4), 2.5, 'average');
is(median(1, 3, 5), 3, 'median odd');
is(median(1, 2, 3, 4), 2.5, 'median even');
is(percentage(25, 100), '25.0', 'percentage');
is(clamp(15, 0, 10), 10, 'clamp');
