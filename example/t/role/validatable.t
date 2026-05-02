use strict;
use warnings;
use Test::More tests => 5;

use_ok('MyApp::Model::User');

my $valid = MyApp::Model::User->new(username => 'alice', email => 'a@b.com');
ok($valid->is_valid, 'valid user');
is(scalar @{$valid->errors}, 0, 'no errors');

my $invalid = MyApp::Model::User->new(username => 'ab', email => 'a@b.com');
ok(!$invalid->is_valid, 'invalid user - short name');
ok(scalar @{$invalid->errors} > 0, 'has errors');
