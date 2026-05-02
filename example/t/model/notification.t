use strict;
use warnings;
use Test::More tests => 7;
use MyApp::Model::Notification;

my $n = MyApp::Model::Notification->new(user_id => 'u1', type => 'mention', message => 'Hello');
isa_ok($n, 'MyApp::Model::Notification');
is($n->type, 'mention', 'type set');
ok($n->is_unread, 'unread by default');
ok(!$n->read, 'read is false');

$n->mark_read;
ok($n->read, 'marked read');
ok(!$n->is_unread, 'no longer unread');

$n->mark_unread;
ok($n->is_unread, 'marked unread again');
