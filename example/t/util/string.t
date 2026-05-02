use strict;
use warnings;
use Test::More tests => 6;

use_ok('MyApp::Util::String', qw(slugify truncate_str camelize snake_case titleize));

is(slugify('Hello World!'), 'hello-world', 'slugify');
is(truncate_str('Hello World', 5), 'Hello...', 'truncate');
is(camelize('hello_world'), 'HelloWorld', 'camelize');
is(snake_case('HelloWorld'), 'hello_world', 'snake_case');
is(titleize('hello world'), 'Hello World', 'titleize');
