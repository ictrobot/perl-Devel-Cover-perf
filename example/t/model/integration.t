use strict;
use warnings;
use Test::More tests => 5;
use MyApp::Model::Integration;

my $i = MyApp::Model::Integration->new(provider => 'github', project_id => 'p1');
isa_ok($i, 'MyApp::Model::Integration');
ok($i->enabled, 'enabled by default');
like($i->display, qr/Github integration/, 'display');

$i->toggle;
ok(!$i->enabled, 'toggled off');
$i->toggle;
ok($i->enabled, 'toggled on');
