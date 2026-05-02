use strict;
use warnings;
use Test::More tests => 3;

use_ok('MyApp::Util::Date', qw(now_iso today days_between));

like(now_iso(), qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$/, 'now_iso format');
like(today(), qr/^\d{4}-\d{2}-\d{2}$/, 'today format');
