package MyApp::Model::Task;
use Moo;
use Types::Standard qw(Str Int ArrayRef Maybe);
use MyApp::Types qw(NonEmptyStr StatusStr PriorityStr Percentage);

with 'MyApp::Role::HasUUID',
     'MyApp::Role::HasTimestamps',
     'MyApp::Role::HasOwner',
     'MyApp::Role::Serializable',
     'MyApp::Role::Validatable',
     'MyApp::Role::Searchable',
     'MyApp::Role::Auditable';

has title       => (is => 'rw', isa => NonEmptyStr, required => 1);
has description => (is => 'rw', isa => Str, default => '');
has status      => (is => 'rw', isa => StatusStr, default => 'open');
has priority    => (is => 'rw', isa => PriorityStr, default => 'medium');
has project_id  => (is => 'ro', isa => Maybe[Str]);
has sprint_id   => (is => 'rw', isa => Maybe[Str]);
has assignee_id => (is => 'rw', isa => Maybe[Str]);
has tag_ids     => (is => 'rw', isa => ArrayRef, default => sub { [] });
has story_points=> (is => 'rw', isa => Int, default => 0);
has progress    => (is => 'rw', isa => Percentage, default => 0);
has due_date    => (is => 'rw', isa => Maybe[Str]);

sub searchable_fields { qw(title description) }

sub validate {
    my $self = shift;
    $self->add_error('Title too short') if length($self->title) < 2;
    $self->add_error('Invalid story points') if $self->story_points < 0;
}

sub assign_to {
    my ($self, $user_id) = @_;
    my $old = $self->assignee_id;
    $self->assignee_id($user_id);
    $self->record_change('assignee_id', $old, $user_id);
    $self->touch;
}

sub change_status {
    my ($self, $new_status) = @_;
    my $old = $self->status;
    $self->status($new_status);
    $self->record_change('status', $old, $new_status);
    $self->progress(100) if $new_status eq 'done';
    $self->touch;
}

sub is_overdue {
    my $self = shift;
    return 0 unless $self->due_date;
    return $self->due_date lt substr(scalar localtime, 0, 10);
}

sub is_done { $_[0]->status eq 'done' || $_[0]->status eq 'closed' }

1;
