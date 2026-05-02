use strict;
use warnings;
use Test::More tests => 5;
use MyApp::Model::Filter;
use MyApp::Model::Task;

my $f = MyApp::Model::Filter->new(name => 'Open tasks', owner_id => 'u1');
isa_ok($f, 'MyApp::Model::Filter');

$f->add_condition('status', 'eq', 'open');
is(scalar @{$f->conditions}, 1, 'one condition');

my @tasks = map { MyApp::Model::Task->new(title => "Task $_", status => $_ % 2 ? 'open' : 'done') } 1..6;
my $result = $f->apply(\@tasks);
is(scalar @$result, 3, 'filtered to open tasks');

$f->add_condition('priority', 'eq', 'medium');
is(scalar @{$f->conditions}, 2, 'two conditions');
my $result2 = $f->apply(\@tasks);
is(scalar @$result2, 3, 'all open tasks are medium priority by default');
