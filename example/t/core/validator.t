use strict;
use warnings;
use Test::More tests => 5;
use MyApp::Validator;

my $v = MyApp::Validator->new;
$v->add_rule('name', MyApp::Validator::required());
$v->add_rule('name', MyApp::Validator::min_length(3));
$v->add_rule('email', MyApp::Validator::required());

ok(!$v->validate({}), 'empty fails');
ok(scalar @{$v->errors} > 0, 'has errors');

ok(!$v->validate({ name => 'ab', email => 'x@y.com' }), 'short name fails');

ok($v->validate({ name => 'alice', email => 'a@b.com' }), 'valid passes');
is(scalar @{$v->errors}, 0, 'no errors');
