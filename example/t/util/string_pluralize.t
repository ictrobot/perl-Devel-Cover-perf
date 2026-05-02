use strict;
use warnings;
use Test::More tests => 5;
use MyApp::Util::String qw(pluralize);

is(pluralize('task'), 'tasks', 'regular');
is(pluralize('box'), 'boxes', 'ends in x');
is(pluralize('church'), 'churches', 'ends in ch');
is(pluralize('brush'), 'brushes', 'ends in sh');
is(pluralize('quiz'), 'quizes', 'ends in z');
