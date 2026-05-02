package MyApp::Model::Comment;
use Moo;
use Types::Standard qw(Str Maybe);
use MyApp::Types qw(NonEmptyStr);

with 'MyApp::Role::HasUUID',
     'MyApp::Role::HasTimestamps',
     'MyApp::Role::Serializable';

has body      => (is => 'rw', isa => NonEmptyStr, required => 1);
has author_id => (is => 'ro', isa => Str, required => 1);
has task_id   => (is => 'ro', isa => Str, required => 1);
has parent_id => (is => 'ro', isa => Maybe[Str]);
has edited    => (is => 'rw', default => 0);

sub edit {
    my ($self, $new_body) = @_;
    $self->body($new_body);
    $self->edited(1);
    $self->touch;
}

sub is_reply     { defined $_[0]->parent_id }
sub word_count   { scalar split /\s+/, $_[0]->body }
sub preview      { substr($_[0]->body, 0, 100) . (length($_[0]->body) > 100 ? '...' : '') }

1;
