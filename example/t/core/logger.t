use strict;
use warnings;
use Test::More tests => 6;
use MyApp::Logger;

my $log = MyApp::Logger->new(level => 'info');
ok(!$log->debug('debug msg'), 'debug suppressed');
ok($log->info('info msg'), 'info logged');
ok($log->error('error msg'), 'error logged');

is(scalar @{$log->messages}, 2, 'two messages');
like($log->messages->[0], qr/INFO.*info msg/, 'info format');

$log->clear;
is(scalar @{$log->messages}, 0, 'cleared');
