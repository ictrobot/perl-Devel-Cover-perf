package MyApp::Model::Label;
use Moo;
use Types::Standard qw(Str);

with 'MyApp::Role::HasUUID', 'MyApp::Role::Serializable';

has name        => (is => 'ro', isa => Str, required => 1);
has color       => (is => 'rw', isa => Str, default => '#3498db');
has description => (is => 'rw', isa => Str, default => '');
has project_id  => (is => 'ro', isa => Str, required => 1);

1;
