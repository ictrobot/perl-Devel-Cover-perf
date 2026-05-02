use strict;
use warnings;
use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('MyApp::Web');

$t->get_ok('/')->status_is(200)->json_is('/app' => 'MyApp');
$t->get_ok('/health')->status_is(200)->json_has('/status');

done_testing();
