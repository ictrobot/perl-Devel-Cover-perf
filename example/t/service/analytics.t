use strict;
use warnings;
use Test::More tests => 4;
use MyApp::Service::Analytics;
use MyApp::Repo::Task;
use MyApp::Model::Task;

my $repo = MyApp::Repo::Task->new;
$repo->add(MyApp::Model::Task->new(title => 'T1', status => 'done'));
$repo->add(MyApp::Model::Task->new(title => 'T2', status => 'open'));
$repo->add(MyApp::Model::Task->new(title => 'T3', status => 'done'));
$repo->add(MyApp::Model::Task->new(title => 'T4', status => 'in_progress'));

my $analytics = MyApp::Service::Analytics->new(task_repo => $repo);

my $summary = $analytics->task_summary;
is($summary->{total}, 4, 'total tasks');
is($summary->{by_status}{done}, 2, 'two done');
is($analytics->completion_rate, 50, '50% completion');

my @sprint_tasks = @{$repo->all};
my $v = $analytics->velocity(\@sprint_tasks);
is($v, 0, 'zero velocity with no story points');
