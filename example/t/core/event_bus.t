use strict;
use warnings;
use Test::More tests => 5;
use MyApp::EventBus;

my $bus = MyApp::EventBus->new;
my @received;

$bus->on('test', sub { push @received, $_[0] });
$bus->on('test', sub { push @received, 'second' });

my $count = $bus->emit('test', 'hello');
is($count, 2, 'two listeners fired');
is(scalar @received, 2, 'two events received');
is($received[0], 'hello', 'payload passed');

$bus->off('test');
$bus->emit('test', 'gone');
is(scalar @received, 2, 'no more events after off');

is(scalar $bus->events, 0, 'no events registered');
