use strict;
use warnings;
use Test::More tests => 5;
use MyApp::Util::Email qw(extract_domain normalize_email);

is(extract_domain('alice@example.com'), 'example.com', 'simple');
is(extract_domain('bob@sub.domain.co.uk'), 'sub.domain.co.uk', 'subdomain');
is(extract_domain('nope'), undef, 'no @');

is(normalize_email('Alice@Example.COM'), 'alice@example.com', 'normalize');
is(normalize_email('BOB@TEST.ORG'), 'bob@test.org', 'all caps');
