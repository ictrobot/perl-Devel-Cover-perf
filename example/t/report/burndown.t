use strict;
use warnings;
use Test::More tests => 4;
use MyApp::Report::Burndown;

my $series = MyApp::Report::Burndown->new->ideal_points('2026-05-01', '2026-05-04', 9);
is(scalar @$series, 4, 'creates inclusive series');
is($series->[0]{date}, '2026-05-01', 'starts on first date');
is($series->[0]{remaining}, '9.0', 'starts with all points');
is($series->[-1]{remaining}, '0.0', 'ends at zero');
