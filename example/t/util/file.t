use strict;
use warnings;
use Test::More tests => 4;
use MyApp::Util::File qw(extension_of mime_type_for human_size);

is(extension_of('report.pdf'), 'pdf', 'extension');
is(mime_type_for('image.png'), 'image/png', 'mime png');
is(mime_type_for('data.json'), 'application/json', 'mime json');
like(human_size(2097152), qr/2\.0 MB/, 'human size');
