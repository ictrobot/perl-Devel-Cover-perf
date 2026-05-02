use strict;
use warnings;
use Test::More tests => 5;
use MyApp::Util::Email qw(is_valid_email normalize_email extract_domain);

ok(is_valid_email('alice@example.com'), 'valid email');
ok(!is_valid_email('not-an-email'), 'invalid email');
is(normalize_email('Alice@Example.COM'), 'alice@example.com', 'normalize');
is(extract_domain('alice@example.com'), 'example.com', 'domain');
is(extract_domain('nope'), undef, 'no domain');
