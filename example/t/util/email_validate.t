use strict;
use warnings;
use Test::More tests => 8;
use MyApp::Util::Email qw(is_valid_email);

ok(is_valid_email('user@example.com'), 'standard');
ok(is_valid_email('foo+bar@baz.co.uk'), 'plus and subdomain');
ok(is_valid_email('a@b.c'), 'minimal');
ok(!is_valid_email('noatsign'), 'no @');
ok(!is_valid_email('@nodomain'), 'no local part');
ok(!is_valid_email('no@'), 'no domain');
ok(!is_valid_email(''), 'empty');
ok(!is_valid_email('spaces in@email.com'), 'spaces');
