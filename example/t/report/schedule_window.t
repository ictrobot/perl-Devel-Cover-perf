use strict;
use warnings;
use Test::More tests => 5;
use MyApp::Report::ScheduleWindow;

my $window = MyApp::Report::ScheduleWindow->new;
is_deeply($window->dates_between('2026-05-01', '2026-05-03'), ['2026-05-01', '2026-05-02', '2026-05-03'], 'expands dates');
ok($window->contains('2026-05-01', '2026-05-10', '2026-05-05'), 'contains date');
ok(!$window->contains('2026-05-01', '2026-05-10', '2026-05-11'), 'rejects outside date');

my $weeks = $window->week_labels('2026-05-01', '2026-05-10');
is($weeks->[0], '2026-W18', 'first week label');
ok(@$weeks >= 2, 'spans more than one week');
