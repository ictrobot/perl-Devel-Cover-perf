use strict;
use warnings;
use Test::More tests => 5;

use_ok('MyApp::Model::Tag');

my $tag = MyApp::Model::Tag->new(name => 'High Priority');
isa_ok($tag, 'MyApp::Model::Tag');
is($tag->name, 'High Priority', 'name set');
is($tag->slug, 'high-priority', 'slug generated');
is($tag->color, '#808080', 'default color');
