use strict;
use warnings;
use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('MyApp::Web');
$t->ua->on(start => sub { $_[1]->req->headers->header(Authorization => 'Bearer test') });

$t->get_ok('/api/reports')->status_is(200)->json_has('/reports');

done_testing();
