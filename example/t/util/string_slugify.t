use strict;
use warnings;
use Test::More tests => 8;
use MyApp::Util::String qw(slugify);

is(slugify('Hello World'), 'hello-world', 'basic');
is(slugify('  spaces  '), 'spaces', 'trimmed');
is(slugify('CamelCase'), 'camelcase', 'lowercase');
is(slugify('foo---bar'), 'foo-bar', 'collapsed dashes');
is(slugify('a@b#c'), 'a-b-c', 'special chars');
is(slugify(''), '', 'empty');
is(slugify('already-good'), 'already-good', 'no change');
is(slugify('UPPER CASE WORDS'), 'upper-case-words', 'upper');
