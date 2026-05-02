use strict;
use warnings;
use Test::More tests => 5;
use MyApp::Service::TagManager;
use MyApp::Logger;

my $mgr = MyApp::Service::TagManager->new(logger => MyApp::Logger->new);

my $tag = $mgr->create_tag(name => 'Urgent');
ok($tag, 'tag created');
is($tag->name, 'Urgent', 'name correct');

is(scalar @{$mgr->all_tags}, 1, 'one tag');
my $found = $mgr->find_tag($tag->id);
is($found->name, 'Urgent', 'found by id');

$mgr->delete_tag($tag->id);
is(scalar @{$mgr->all_tags}, 0, 'deleted');
