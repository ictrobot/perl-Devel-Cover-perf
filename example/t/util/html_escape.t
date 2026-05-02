use strict;
use warnings;
use Test::More tests => 7;
use MyApp::Util::HTML qw(escape_html);

is(escape_html('<script>'), '&lt;script&gt;', 'tags');
is(escape_html('"quotes"'), '&quot;quotes&quot;', 'quotes');
is(escape_html('a & b'), 'a &amp; b', 'ampersand');
is(escape_html(''), '', 'empty');
is(escape_html(undef), '', 'undef');
is(escape_html('no special'), 'no special', 'passthrough');
is(escape_html('<a href="x">&</a>'), '&lt;a href=&quot;x&quot;&gt;&amp;&lt;/a&gt;', 'mixed');
