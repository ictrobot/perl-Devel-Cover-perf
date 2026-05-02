use strict;
use warnings;
use Test::More tests => 5;
use MyApp::Report::ProjectSnapshot;
use MyApp::Model::Project;
use MyApp::Model::Task;

my $project = MyApp::Model::Project->new(name => 'Snapshot Project', status => 'open');
my @tasks = (
    MyApp::Model::Task->new(title => 'Open task', status => 'open', story_points => 3),
    MyApp::Model::Task->new(title => 'Done task', status => 'done', story_points => 5),
);

my $snapshot = MyApp::Report::ProjectSnapshot->new->from_project($project, \@tasks);
is($snapshot->{project}{name}, 'Snapshot Project', 'captures project name');
is($snapshot->{total_tasks}, 2, 'counts tasks');
is($snapshot->{total_points}, 8, 'sums story points');
is($snapshot->{by_status}{open}, 1, 'counts open tasks');
is($snapshot->{by_status}{done}, 1, 'counts done tasks');
