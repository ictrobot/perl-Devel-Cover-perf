use strict;
use warnings;
use Test::More tests => 4;
use MyApp::Model::Template;

my $t = MyApp::Model::Template->new(
    name => 'welcome', type => 'email',
    content => 'Hello {{name}}, welcome to {{app}}!',
    defaults => { app => 'MyApp' },
);
isa_ok($t, 'MyApp::Model::Template');
is($t->render(name => 'Alice'), 'Hello Alice, welcome to MyApp!', 'render with defaults');
is($t->render(name => 'Bob', app => 'TestApp'), 'Hello Bob, welcome to TestApp!', 'render with override');
is($t->type, 'email', 'type set');
