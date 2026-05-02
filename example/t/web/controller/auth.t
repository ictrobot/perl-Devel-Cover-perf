use strict;
use warnings;
use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('MyApp::Web');

$t->post_ok('/api/login' => json => { username => 'alice', password => 'secret' })
  ->status_is(200)
  ->json_has('/token');

$t->post_ok('/api/login' => json => {})
  ->status_is(401)
  ->json_has('/error');

done_testing();
