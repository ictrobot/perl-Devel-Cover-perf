use strict;
use warnings;
use Test::More tests => 6;
use MyApp::Util::Crypto qw(generate_token hmac_sign);

my $t1 = generate_token(16);
is(length($t1), 16, '16 chars');

my $t2 = generate_token(32);
is(length($t2), 32, '32 chars');

my $t3 = generate_token();
is(length($t3), 32, 'default 32');

isnt($t1, generate_token(16), 'unique tokens');

my $sig1 = hmac_sign('hello', 'secret');
my $sig2 = hmac_sign('hello', 'secret');
is($sig1, $sig2, 'deterministic hmac');

my $sig3 = hmac_sign('hello', 'other');
isnt($sig1, $sig3, 'different key different sig');
