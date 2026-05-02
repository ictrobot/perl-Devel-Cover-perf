use strict;
use warnings;
use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('MyApp::Web');
$t->ua->on(start => sub { $_[1]->req->headers->header(Authorization => 'Bearer test') });

$t->get_ok('/api/tasks')->status_is(200)->json_has('/tasks');

$t->get_ok('/api/tasks/1')->status_is(200)->json_is('/title' => 'Setup CI');
$t->get_ok('/api/tasks/999')->status_is(404);

$t->post_ok('/api/tasks' => json => { title => 'New task', priority => 'high' })
  ->status_is(201)
  ->json_is('/title' => 'New task');

$t->get_ok('/api/tasks?status=open')->status_is(200)->json_has('/tasks');

done_testing();
