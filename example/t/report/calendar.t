use strict;
use warnings;
use Test::More tests => 5;
use MyApp::Report::Calendar;

my $calendar = MyApp::Report::Calendar->new;
is($calendar->month_label(2026, 5), 'May 2026', 'formats month label');

my $grid = $calendar->month_grid(2026, 5);
is(scalar @$grid, 6, 'six week rows');
is(scalar @{$grid->[0]}, 7, 'seven days per week');
is($grid->[0][4]{date}, '2026-05-01', 'places May first on Friday');
ok($grid->[0][5]{weekend}, 'marks weekend');
