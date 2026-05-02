package MyApp::Model::TimeEntry;
use Moo;
use Types::Standard qw(Str Num Maybe);

with 'MyApp::Role::HasUUID', 'MyApp::Role::HasTimestamps', 'MyApp::Role::Serializable';

has task_id     => (is => 'ro', isa => Str, required => 1);
has user_id     => (is => 'ro', isa => Str, required => 1);
has hours       => (is => 'rw', isa => Num, required => 1);
has description => (is => 'rw', isa => Str, default => '');
has date        => (is => 'ro', isa => Str, required => 1);
has billable    => (is => 'rw', default => 1);

sub minutes    { $_[0]->hours * 60 }
sub is_billable { $_[0]->billable }

1;
