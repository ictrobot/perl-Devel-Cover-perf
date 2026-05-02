use strict;
use warnings;
use Test::More tests => 4;
use MyApp::Service::DigestBuilder;
use MyApp::Model::Project;
use MyApp::Model::Task;

my $project = MyApp::Model::Project->new(name => 'Digest Builder Project');
my @tasks = (
    MyApp::Model::Task->new(title => 'Open digest', status => 'open', story_points => 2),
    MyApp::Model::Task->new(title => 'Done digest', status => 'done', story_points => 3),
);

my $digest = MyApp::Service::DigestBuilder->new->build_project_digest($project, \@tasks);
like($digest, qr/Digest Builder Project/, 'contains project');
like($digest, qr/tasks=2 points=5/, 'contains totals');
like($digest, qr/open: 1/, 'contains open matrix');
like($digest, qr/done: 1/, 'contains done matrix');
