use strict;
use warnings;
use Test::More tests => 5;
use MyApp::Util::Math qw(clamp percentage);

is(clamp(5, 0, 10), 5, 'in range');
is(clamp(-5, 0, 10), 0, 'below');
is(clamp(15, 0, 10), 10, 'above');
is(percentage(1, 4), '25.0', 'quarter');
is(percentage(0, 100), '0.0', 'zero');
