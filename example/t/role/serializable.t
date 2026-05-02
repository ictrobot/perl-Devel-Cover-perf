use strict;
use warnings;
use Test::More tests => 3;

use_ok('MyApp::Model::Tag');

my $tag = MyApp::Model::Tag->new(name => 'Bug', color => '#ff0000');
my $hash = $tag->to_hash;
ok(ref $hash eq 'HASH', 'to_hash returns hashref');

my $json = $tag->to_json;
ok($json, 'to_json produces output');
