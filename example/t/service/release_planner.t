use strict;
use warnings;
use Test::More tests => 9;
use MyApp::Service::ReleasePlanner;

my $planner = MyApp::Service::ReleasePlanner->new;
my $plan = $planner->plan(start => '2026-05-01', end => '2026-05-03', points => 6);
is_deeply($plan->{dates}, ['2026-05-01', '2026-05-02', '2026-05-03'], 'plans date range');
is($plan->{burndown}[0]{remaining}, '6.0', 'starts burndown');
is($plan->{burndown}[-1]{remaining}, '0.0', 'ends burndown');
ok(@{$plan->{weeks}} >= 1, 'includes weeks');

my $calendar = $planner->calendar_for(2026, 5);
is($calendar->{label}, 'May 2026', 'calendar label');
is(scalar @{$calendar->{weeks}}, 6, 'calendar grid');

my $workflow = $planner->workflow_for('release-2026.05', qw(draft review ship));
isa_ok($workflow, 'MyApp::Model::Workflow');
is($workflow->step_count, 3, 'builds a release workflow');
is(scalar @{$workflow->transitions}, 0, 'workflow starts without transitions');
