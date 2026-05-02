use strict;
use warnings;
use Test::More tests => 5;

use_ok('MyApp::Util::Crypto', qw(hash_password verify_password generate_token hmac_sign));

my $hash = hash_password('secret');
ok($hash, 'hash generated');
ok(verify_password('secret', $hash), 'password verified');
ok(!verify_password('wrong', $hash), 'wrong password rejected');

my $token = generate_token(16);
is(length($token), 16, 'token correct length');
