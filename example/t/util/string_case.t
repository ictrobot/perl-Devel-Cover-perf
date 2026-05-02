use strict;
use warnings;
use Test::More tests => 8;
use MyApp::Util::String qw(camelize snake_case titleize);

is(camelize('hello_world'), 'HelloWorld', 'basic camelize');
is(camelize('foo'), 'Foo', 'single word');
is(camelize('a_b_c'), 'ABC', 'short segments');

is(snake_case('HelloWorld'), 'hello_world', 'basic snake');
is(snake_case('FooBar'), 'foo_bar', 'two words');
is(snake_case('ABC'), 'a_b_c', 'acronym');

is(titleize('hello world'), 'Hello World', 'basic titleize');
is(titleize('foo bar baz'), 'Foo Bar Baz', 'three words');
