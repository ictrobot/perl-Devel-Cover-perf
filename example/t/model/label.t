use strict;
use warnings;
use Test::More tests => 4;
use MyApp::Model::Label;

my $l = MyApp::Model::Label->new(name => 'Bug', project_id => 'p1');
isa_ok($l, 'MyApp::Model::Label');
is($l->name, 'Bug', 'name set');
is($l->color, '#3498db', 'default color');

$l->color('#ff0000');
is($l->color, '#ff0000', 'color changed');
