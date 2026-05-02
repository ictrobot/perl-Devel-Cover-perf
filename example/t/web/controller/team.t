use strict;
use warnings;
use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('MyApp::Web');
$t->ua->on(start => sub { $_[1]->req->headers->header(Authorization => 'Bearer test') });

$t->get_ok('/api/teams')->status_is(200)->json_has('/teams');

my $teams = $t->tx->res->json->{teams};
ok(scalar @$teams >= 2, 'at least two teams');

done_testing();
