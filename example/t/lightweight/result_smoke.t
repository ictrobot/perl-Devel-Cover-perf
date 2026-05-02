use strict;
use warnings;
use Test::More tests => 5;
use MyApp::Result;

my $ok = MyApp::Result->ok({ id => 1 });
ok($ok->is_ok, 'ok result');
ok(!$ok->is_error, 'ok is not error');
is($ok->unwrap->{id}, 1, 'unwrap returns value');

my $fail = MyApp::Result->fail('broken');
ok($fail->is_error, 'failed result');
is($fail->error, 'broken', 'stores error');
