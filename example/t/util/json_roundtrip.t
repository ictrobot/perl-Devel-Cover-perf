use strict;
use warnings;
use Test::More tests => 5;
use MyApp::Util::JSON qw(encode decode pretty_encode);

my $data = { name => 'test', items => [1, 2, 3], nested => { a => 1 } };
my $json = encode($data);
ok($json, 'encoded');

my $back = decode($json);
is($back->{name}, 'test', 'string roundtrip');
is(scalar @{$back->{items}}, 3, 'array roundtrip');
is($back->{nested}{a}, 1, 'nested roundtrip');

my $pretty = pretty_encode($data);
like($pretty, qr/\n/, 'pretty has newlines');
