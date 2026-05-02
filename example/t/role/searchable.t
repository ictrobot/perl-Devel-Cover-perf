use strict;
use warnings;
use Test::More tests => 4;
use MyApp::Model::User;

my $u = MyApp::Model::User->new(username => 'alice', email => 'alice@example.com', display_name => 'Alice Smith');
ok($u->matches('alice'), 'matches username');
ok($u->matches('example.com'), 'matches email');
ok($u->matches('Smith'), 'matches display name');
ok(!$u->matches('zzzzz'), 'no match');
