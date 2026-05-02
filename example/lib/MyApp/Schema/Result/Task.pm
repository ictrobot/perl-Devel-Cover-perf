package MyApp::Schema::Result::Task;
use strict;
use warnings;
use base 'DBIx::Class::Core';

__PACKAGE__->table('tasks');
__PACKAGE__->add_columns(
    id => {
        data_type => 'varchar',
        size      => 36,
    },
    project_id => {
        data_type   => 'varchar',
        size        => 36,
        is_nullable => 1,
    },
    title => {
        data_type => 'varchar',
        size      => 255,
    },
    status => {
        data_type     => 'varchar',
        size          => 32,
        default_value => 'open',
    },
    priority => {
        data_type     => 'varchar',
        size          => 32,
        default_value => 'medium',
    },
    story_points => {
        data_type     => 'integer',
        default_value => 0,
    },
    due_date => {
        data_type   => 'date',
        is_nullable => 1,
    },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to(project => 'MyApp::Schema::Result::Project', 'project_id', { join_type => 'left' });

1;
