use strict;
use warnings;
use Test::More tests => 5;
use MyApp::Service::Dashboard;
use MyApp::Model::Project;
use MyApp::Model::Task;

my $project = MyApp::Model::Project->new(name => 'Dashboard Project');
my @tasks = (
    MyApp::Model::Task->new(title => 'Dashboard task', status => 'open'),
);

my $dashboard = MyApp::Service::Dashboard->new->build($project, \@tasks);
is($dashboard->{snapshot}{total_tasks}, 1, 'includes snapshot');
like($dashboard->{summary}, qr/Dashboard Project/, 'includes summary');
like($dashboard->{matrix}, qr/open: 1/, 'includes matrix');
like($dashboard->{xml}, qr/<project_report/, 'includes xml');
like($dashboard->{xml}, qr/Dashboard task/, 'xml includes task');
