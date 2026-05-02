use strict;
use warnings;
use Test::More tests => 8;
use MyApp::Util::File qw(extension_of mime_type_for human_size);

is(extension_of('photo.jpg'), 'jpg', 'jpg');
is(extension_of('archive.tar.gz'), 'gz', 'double ext');
is(extension_of('noext'), '', 'no extension');

is(mime_type_for('test.png'), 'image/png', 'png mime');
is(mime_type_for('test.html'), 'text/html', 'html mime');
is(mime_type_for('test.xyz'), 'application/octet-stream', 'unknown mime');

like(human_size(500), qr/0\.\d+ KB/, 'bytes');
like(human_size(5_000_000_000), qr/GB/, 'gigabytes');
