use strict;
use warnings;
use Test::More tests => 7;
use Test::Exception;
use MyApp::Result;

my $ok = MyApp::Result->ok(42);
ok($ok->is_ok, 'is ok');
ok(!$ok->is_error, 'not error');
is($ok->unwrap, 42, 'unwrap value');

my $err = MyApp::Result->fail('something broke');
ok(!$err->is_ok, 'not ok');
ok($err->is_error, 'is error');
is($err->error, 'something broke', 'error message');

dies_ok { $err->unwrap } 'unwrap on error dies';
