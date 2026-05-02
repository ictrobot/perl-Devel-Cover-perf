use strict;
use warnings;
use Test::More tests => 6;
use MyApp::Model::Webhook;

my $wh = MyApp::Model::Webhook->new(
    url => 'https://example.com/hook', project_id => 'p1',
    events => ['task.created', 'task.updated'],
);
isa_ok($wh, 'MyApp::Model::Webhook');
ok($wh->active, 'active by default');
ok($wh->listens_to('task.created'), 'listens to task.created');
ok(!$wh->listens_to('task.deleted'), 'does not listen to task.deleted');

$wh->disable;
ok(!$wh->active, 'disabled');
$wh->enable;
ok($wh->active, 'enabled again');
