use strict;
use warnings;
use Test::More tests => 3;

use_ok('MyApp::Util::JSON', qw(encode decode));

my $data = { name => 'test', count => 42 };
my $json = encode($data);
ok($json, 'encoded');

my $decoded = decode($json);
is($decoded->{name}, 'test', 'decoded correctly');
