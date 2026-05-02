use strict;
use warnings;
use Test::More tests => 5;
use MyApp::Util::HTML qw(escape_html strip_tags nl2br truncate_html);

is(escape_html('<b>"Hi"</b>'), '&lt;b&gt;&quot;Hi&quot;&lt;/b&gt;', 'escape');
is(strip_tags('<p>Hello <b>world</b></p>'), 'Hello world', 'strip');
is(nl2br("a\nb"), "a<br>\nb", 'nl2br');

my $long = '<p>' . ('x' x 300) . '</p>';
my $trunc = truncate_html($long, 50);
like($trunc, qr/\.\.\./, 'truncated');
is(length(truncate_html('<b>short</b>', 200)), 5, 'short not truncated');
