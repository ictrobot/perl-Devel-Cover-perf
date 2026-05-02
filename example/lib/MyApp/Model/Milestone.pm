package MyApp::Model::Milestone;
use Moo;
use Types::Standard qw(Str Maybe Int);

with 'MyApp::Role::HasUUID',
     'MyApp::Role::HasTimestamps',
     'MyApp::Role::Serializable',
     'MyApp::Role::Searchable';

has title       => (is => 'rw', isa => Str, required => 1);
has description => (is => 'rw', isa => Str, default => '');
has project_id  => (is => 'ro', isa => Str, required => 1);
has due_date    => (is => 'rw', isa => Maybe[Str]);
has completed   => (is => 'rw', default => 0);
has task_count  => (is => 'rw', isa => Int, default => 0);
has done_count  => (is => 'rw', isa => Int, default => 0);

sub searchable_fields { qw(title description) }
sub progress { $_[0]->task_count > 0 ? int($_[0]->done_count / $_[0]->task_count * 100) : 0 }
sub complete { $_[0]->completed(1); $_[0]->touch }

1;
