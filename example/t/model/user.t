use strict;
use warnings;
use Test::More tests => 12;
use Test::Exception;

use_ok('MyApp::Model::User');

my $user = MyApp::Model::User->new(username => 'alice', email => 'alice@example.com');
isa_ok($user, 'MyApp::Model::User');

ok($user->id, 'has generated id');
is($user->username, 'alice', 'username set');
is($user->email, 'alice@example.com', 'email set');
is($user->role, 'member', 'default role');
ok($user->active, 'active by default');
is($user->full_name, 'alice', 'full_name falls back to username');

$user->display_name('Alice Smith');
is($user->full_name, 'Alice Smith', 'full_name uses display_name');

ok($user->is_valid, 'valid user');
$user->deactivate;
ok(!$user->active, 'deactivated');

ok(!$user->is_admin, 'not admin');
