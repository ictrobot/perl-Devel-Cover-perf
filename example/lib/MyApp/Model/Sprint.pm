package MyApp::Model::Sprint;
use Moo;
use Types::Standard qw(Str ArrayRef Int);

with 'MyApp::Role::HasUUID',
     'MyApp::Role::HasTimestamps',
     'MyApp::Role::Serializable',
     'MyApp::Role::Searchable';

has name       => (is => 'rw', isa => Str, required => 1);
has project_id => (is => 'ro', isa => Str, required => 1);
has start_date => (is => 'ro', isa => Str, required => 1);
has end_date   => (is => 'ro', isa => Str, required => 1);
has goal       => (is => 'rw', isa => Str, default => '');
has task_ids   => (is => 'rw', isa => ArrayRef, default => sub { [] });
has velocity   => (is => 'rw', isa => Int, default => 0);

sub searchable_fields { qw(name goal) }

sub add_task    { push @{$_[0]->task_ids}, $_[1] }
sub remove_task { $_[0]->task_ids([grep { $_ ne $_[1] } @{$_[0]->task_ids}]) }
sub task_count  { scalar @{$_[0]->task_ids} }
sub is_active   { my $now = substr(scalar localtime, 0, 10); $_[0]->start_date le $now && $now le $_[0]->end_date }

1;
