use strict;
use warnings;
use Test::More tests => 8;

use_ok('MyApp::Model::Comment');

my $c = MyApp::Model::Comment->new(body => 'Hello world', author_id => 'u1', task_id => 't1');
isa_ok($c, 'MyApp::Model::Comment');

is($c->body, 'Hello world', 'body set');
ok(!$c->is_reply, 'not a reply');
ok(!$c->edited, 'not edited');
is($c->word_count, 2, 'word count');

$c->edit('Updated body');
is($c->body, 'Updated body', 'body updated');
ok($c->edited, 'marked as edited');
