use strict;
use warnings;
use Test::More tests => 6;
use MyApp::Util::String qw(slugify truncate_str camelize snake_case titleize pluralize);

is(slugify('Hello, Fixture!'), 'hello-fixture', 'slugifies punctuation');
is(truncate_str('abcdef', 3, '..'), 'abc..', 'truncates with suffix');
is(camelize('task_manager'), 'TaskManager', 'camelizes');
is(snake_case('TaskManager'), 'task_manager', 'snake cases');
is(titleize('small task'), 'Small Task', 'titleizes');
is(pluralize('box'), 'boxes', 'pluralizes es suffix');
