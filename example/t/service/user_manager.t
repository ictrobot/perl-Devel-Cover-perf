use strict;
use warnings;
use Test::More tests => 7;

use_ok('MyApp::Service::UserManager');
use_ok('MyApp::Logger');

my $mgr = MyApp::Service::UserManager->new(logger => MyApp::Logger->new);

my $user = $mgr->create_user(username => 'bob', email => 'bob@test.com');
ok($user, 'user created');
is($user->username, 'bob', 'correct username');

my $found = $mgr->find_user($user->id);
is($found->username, 'bob', 'found by id');

my $by_email = $mgr->find_by_email('bob@test.com');
is($by_email->username, 'bob', 'found by email');

$mgr->delete_user($user->id);
ok(!$mgr->find_user($user->id), 'deleted');
