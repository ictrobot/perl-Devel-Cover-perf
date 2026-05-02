use strict;
use warnings;
use Test::More tests => 6;

use_ok('MyApp::Service::ProjectManager');
use_ok('MyApp::Logger');

my $mgr = MyApp::Service::ProjectManager->new(logger => MyApp::Logger->new);

my $proj = $mgr->create_project(name => 'Test Project');
ok($proj, 'project created');

my @all = @{$mgr->all_projects};
is(scalar @all, 1, 'one project');

my @active = @{$mgr->active_projects};
is(scalar @active, 1, 'one active');

$mgr->delete_project($proj->id);
is(scalar @{$mgr->all_projects}, 0, 'deleted');
