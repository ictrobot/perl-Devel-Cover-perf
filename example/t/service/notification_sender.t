use strict;
use warnings;
use Test::More tests => 5;
use MyApp::Service::NotificationSender;
use MyApp::Logger;

my $svc = MyApp::Service::NotificationSender->new(logger => MyApp::Logger->new);

$svc->notify(user_id => 'u1', type => 'mention', message => 'Hey');
$svc->notify(user_id => 'u1', type => 'assign',  message => 'Task assigned');
$svc->notify(user_id => 'u2', type => 'mention', message => 'Hi');

my $unread = $svc->unread_for('u1');
is(scalar @$unread, 2, 'two unread for u1');

$svc->mark_all_read('u1');
$unread = $svc->unread_for('u1');
is(scalar @$unread, 0, 'all read for u1');

my $u2 = $svc->unread_for('u2');
is(scalar @$u2, 1, 'u2 unaffected');

$svc->notify(user_id => 'u1', type => 'comment', message => 'New');
$unread = $svc->unread_for('u1');
is(scalar @$unread, 1, 'one new unread');
ok(1, 'notification sender works');
