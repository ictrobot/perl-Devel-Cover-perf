package MyApp::Schema::Result::Project;
use strict;
use warnings;
use base 'DBIx::Class::Core';

__PACKAGE__->table('projects');
__PACKAGE__->add_columns(
    id => {
        data_type => 'varchar',
        size      => 36,
    },
    name => {
        data_type => 'varchar',
        size      => 255,
    },
    status => {
        data_type     => 'varchar',
        size          => 32,
        default_value => 'open',
    },
    description => {
        data_type   => 'text',
        is_nullable => 1,
    },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many(tasks => 'MyApp::Schema::Result::Task', 'project_id');

1;
