use strict;
use warnings;
use Test::More tests => 4;
use MyApp::Util::Date qw(now_iso today days_between);

my $now = now_iso();
like($now, qr/^\d{4}-\d{2}-\d{2}T/, 'now_iso starts with date');
like($now, qr/T\d{2}:\d{2}:\d{2}$/, 'now_iso ends with time');

my $today = today();
like($today, qr/^\d{4}-\d{2}-\d{2}$/, 'today format');

my $days = days_between('2025-01-01', '2025-01-31');
is($days, 30, '30 days in January');
