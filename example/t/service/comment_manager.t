use strict;
use warnings;
use Test::More tests => 5;
use MyApp::Service::CommentManager;
use MyApp::Logger;

my $mgr = MyApp::Service::CommentManager->new(logger => MyApp::Logger->new);

my $c = $mgr->add_comment(body => 'Looks good', author_id => 'u1', task_id => 't1');
ok($c, 'comment created');
is($c->body, 'Looks good', 'body correct');

my $comments = $mgr->comments_for_task('t1');
is(scalar @$comments, 1, 'one comment for task');

my $found = $mgr->find_comment($c->id);
is($found->author_id, 'u1', 'found by id');

$mgr->delete_comment($c->id);
is(scalar @{$mgr->comments_for_task('t1')}, 0, 'deleted');
