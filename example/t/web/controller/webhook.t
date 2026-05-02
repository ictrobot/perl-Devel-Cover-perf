use strict;
use warnings;
use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('MyApp::Web');

$t->get_ok('/api/webhooks')->status_is(200)->json_is('/webhooks' => []);

done_testing();
