use strict;
use warnings;
use Test::More tests => 7;

use_ok('MyApp::Service::Auth');
use_ok('MyApp::Model::User');

my $auth = MyApp::Service::Auth->new;
my $user = MyApp::Model::User->new(username => 'alice', email => 'alice@test.com');

my $token = $auth->login($user, 'secret');
ok($token, 'got token');
ok($auth->validate_token($token), 'token valid');
is($auth->user_id_for_token($token), $user->id, 'correct user id');

ok($auth->logout($token), 'logged out');
ok(!$auth->validate_token($token), 'token invalid after logout');
