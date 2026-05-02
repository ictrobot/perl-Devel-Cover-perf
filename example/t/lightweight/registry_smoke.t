use strict;
use warnings;
use Test::More tests => 5;
use MyApp::Registry;

my $registry = MyApp::Registry->new;
$registry->register(alpha => 1);
$registry->register(beta  => 2);

is($registry->count, 2, 'counts services');
ok($registry->has_service('alpha'), 'has alpha');
ok($registry->has_service('beta'), 'has beta');
is($registry->resolve('alpha'), 1, 'resolves alpha');
is_deeply([sort $registry->services], [qw(alpha beta)], 'lists services');
