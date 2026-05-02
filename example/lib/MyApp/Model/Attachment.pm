package MyApp::Model::Attachment;
use Moo;
use Types::Standard qw(Str Int Maybe);

with 'MyApp::Role::HasUUID', 'MyApp::Role::HasTimestamps', 'MyApp::Role::Serializable';

has filename     => (is => 'ro', isa => Str, required => 1);
has content_type => (is => 'ro', isa => Str, required => 1);
has size         => (is => 'ro', isa => Int, required => 1);
has task_id      => (is => 'ro', isa => Str, required => 1);
has uploader_id  => (is => 'ro', isa => Maybe[Str]);
has url          => (is => 'rw', isa => Str, default => '');

sub extension {
    my $f = $_[0]->filename;
    return $f =~ /\.(\w+)$/ ? $1 : '';
}

sub is_image { $_[0]->content_type =~ m{^image/} }
sub human_size {
    my $s = $_[0]->size;
    return sprintf("%.1f KB", $s / 1024) if $s < 1048576;
    return sprintf("%.1f MB", $s / 1048576);
}

1;
