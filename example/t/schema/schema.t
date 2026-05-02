use strict;
use warnings;
use Test::More tests => 9;
use MyApp::Schema;

is_deeply([sort MyApp::Schema->sources], [qw(Project Task User)], 'loads DBIx result sources');

my $project = MyApp::Schema->source('Project');
is($project->from, 'projects', 'project table');
is_deeply([$project->primary_columns], ['id'], 'project primary key');
ok($project->has_relationship('tasks'), 'project has tasks relationship');

my $task = MyApp::Schema->source('Task');
is($task->from, 'tasks', 'task table');
ok($task->has_relationship('project'), 'task belongs to project');
is($task->column_info('story_points')->{data_type}, 'integer', 'task story points metadata');

my $user = MyApp::Schema->source('User');
is($user->from, 'users', 'user table');
is($user->column_info('email')->{size}, 255, 'user email metadata');
