use strict;
use warnings;
use Test::More tests => 6;
use MyApp::Util::Crypto qw(hash_password verify_password);

my $h1 = hash_password('secret');
ok($h1, 'hash produced');
like($h1, qr/\$/, 'contains salt separator');

ok(verify_password('secret', $h1), 'correct password');
ok(!verify_password('wrong', $h1), 'wrong password');
ok(!verify_password('', $h1), 'empty password');

my $h2 = hash_password('secret');
isnt($h1, $h2, 'different salt each time');
