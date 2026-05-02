use strict;
use warnings;
use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('MyApp::Web');
$t->ua->on(start => sub { $_[1]->req->headers->header(Authorization => 'Bearer test') });

$t->get_ok('/api/users')->status_is(200)->json_has('/users')->json_has('/total');

$t->get_ok('/api/users/1')->status_is(200)->json_is('/username' => 'alice');
$t->get_ok('/api/users/2')->status_is(200)->json_is('/username' => 'bob');
$t->get_ok('/api/users/999')->status_is(404);

$t->post_ok('/api/users' => json => { username => 'dave', email => 'dave@test.com' })
  ->status_is(201)
  ->json_is('/username' => 'dave');

done_testing();
