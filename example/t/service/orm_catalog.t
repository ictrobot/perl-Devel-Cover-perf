use strict;
use warnings;
use Test::More tests => 11;
use MyApp::Service::OrmCatalog;

my $catalog = MyApp::Service::OrmCatalog->new;
is_deeply($catalog->result_sources, [qw(Project Task User)], 'lists sources');
is($catalog->table_for('Project'), 'projects', 'finds project table');
is($catalog->table_for('Task'), 'tasks', 'finds task table');
is_deeply($catalog->primary_columns_for('User'), ['id'], 'finds primary key');
is_deeply($catalog->relationships_for('Project'), ['tasks'], 'finds project relationships');
is_deeply($catalog->relationships_for('Task'), ['project'], 'finds task relationships');

my $task_columns = $catalog->columns_for('Task');
ok(grep { $_ eq 'story_points' } @$task_columns, 'task columns include story points');
is($catalog->column_info('Task', 'due_date')->{data_type}, 'date', 'returns column info');

my $source = $catalog->describe_source('Project');
is($source->{source}, 'Project', 'describes source name');
is($source->{table}, 'projects', 'describes table name');

my $schema = $catalog->describe_schema;
is(scalar @{$schema->{sources}}, 3, 'describes schema sources');
