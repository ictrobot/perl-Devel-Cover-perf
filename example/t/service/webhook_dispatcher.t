use strict;
use warnings;
use Test::More tests => 4;
use MyApp::Service::WebhookDispatcher;
use MyApp::Model::Webhook;
use MyApp::Logger;

my $d = MyApp::Service::WebhookDispatcher->new(logger => MyApp::Logger->new);
my $wh = MyApp::Model::Webhook->new(
    url => 'https://example.com/hook', project_id => 'p1',
    events => ['task.created'],
);
$d->register($wh);

$d->dispatch('task.created', { id => 't1' });
is($d->dispatch_count, 1, 'one dispatch');

$d->dispatch('task.updated', { id => 't1' });
is($d->dispatch_count, 1, 'no dispatch for unregistered event');

$d->dispatch('task.created', { id => 't2' });
is($d->dispatch_count, 2, 'two dispatches');

$wh->disable;
$d->dispatch('task.created', { id => 't3' });
is($d->dispatch_count, 2, 'no dispatch when disabled');
