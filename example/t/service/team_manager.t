use strict;
use warnings;
use Test::More tests => 5;
use MyApp::Service::TeamManager;
use MyApp::Logger;

my $mgr = MyApp::Service::TeamManager->new(logger => MyApp::Logger->new);

my $team = $mgr->create_team(name => 'Platform');
ok($team, 'team created');
is($team->name, 'Platform', 'name correct');

is(scalar @{$mgr->all_teams}, 1, 'one team');
my $found = $mgr->find_team($team->id);
is($found->name, 'Platform', 'found by id');

$mgr->delete_team($team->id);
is(scalar @{$mgr->all_teams}, 0, 'deleted');
