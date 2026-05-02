package MyApp::Schema::Result::User;
use strict;
use warnings;
use base 'DBIx::Class::Core';

__PACKAGE__->table('users');
__PACKAGE__->add_columns(
    id => {
        data_type => 'varchar',
        size      => 36,
    },
    username => {
        data_type => 'varchar',
        size      => 80,
    },
    email => {
        data_type => 'varchar',
        size      => 255,
    },
    role => {
        data_type     => 'varchar',
        size          => 32,
        default_value => 'member',
    },
    active => {
        data_type     => 'integer',
        default_value => 1,
    },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint(user_email => ['email']);

1;
