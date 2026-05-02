use strict;
use warnings;
use Test::More tests => 5;
use MyApp::Util::HTML qw(strip_tags);

is(strip_tags('<p>hello</p>'), 'hello', 'simple');
is(strip_tags('<b>bold</b> and <i>italic</i>'), 'bold and italic', 'multiple');
is(strip_tags('no tags'), 'no tags', 'passthrough');
is(strip_tags(''), '', 'empty');
is(strip_tags('<div class="x"><span>nested</span></div>'), 'nested', 'nested');
