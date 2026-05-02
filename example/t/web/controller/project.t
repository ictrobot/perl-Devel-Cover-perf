use strict;
use warnings;
use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('MyApp::Web');
$t->ua->on(start => sub { $_[1]->req->headers->header(Authorization => 'Bearer test') });

$t->get_ok('/api/projects')->status_is(200)->json_has('/projects');

$t->get_ok('/api/projects/1')->status_is(200)->json_is('/name' => 'Alpha');
$t->get_ok('/api/projects/999')->status_is(404);

$t->post_ok('/api/projects' => json => { name => 'Gamma', status => 'open' })
  ->status_is(201)
  ->json_is('/name' => 'Gamma');

done_testing();
