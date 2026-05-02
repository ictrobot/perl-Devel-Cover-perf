use strict;
use warnings;
use Test::More tests => 6;
use MyApp::Model::Attachment;

my $a = MyApp::Model::Attachment->new(
    filename     => 'report.pdf',
    content_type => 'application/pdf',
    size         => 524288,
    task_id      => 't1',
);
isa_ok($a, 'MyApp::Model::Attachment');
is($a->extension, 'pdf', 'extension');
ok(!$a->is_image, 'pdf is not image');
like($a->human_size, qr/512\.0 KB/, 'human size');

my $img = MyApp::Model::Attachment->new(
    filename => 'photo.png', content_type => 'image/png', size => 1024, task_id => 't1',
);
ok($img->is_image, 'png is image');
is($img->extension, 'png', 'png extension');
