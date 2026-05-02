package MyApp::Model::Project;
use Moo;
use Types::Standard qw(Str ArrayRef Maybe);
use MyApp::Types qw(NonEmptyStr StatusStr);

with 'MyApp::Role::HasUUID',
     'MyApp::Role::HasTimestamps',
     'MyApp::Role::HasOwner',
     'MyApp::Role::Serializable',
     'MyApp::Role::Searchable',
     'MyApp::Role::Configurable';

has name        => (is => 'rw', isa => NonEmptyStr, required => 1);
has description => (is => 'rw', isa => Str, default => '');
has status      => (is => 'rw', isa => StatusStr, default => 'open');
has member_ids  => (is => 'rw', isa => ArrayRef, default => sub { [] });
has tag_ids     => (is => 'rw', isa => ArrayRef, default => sub { [] });
has prefix      => (is => 'ro', isa => Maybe[Str]);

sub searchable_fields { qw(name description) }

sub add_member {
    my ($self, $user_id) = @_;
    push @{$self->member_ids}, $user_id unless grep { $_ eq $user_id } @{$self->member_ids};
    $self->touch;
}

sub remove_member {
    my ($self, $user_id) = @_;
    $self->member_ids([grep { $_ ne $user_id } @{$self->member_ids}]);
    $self->touch;
}

sub member_count { scalar @{$_[0]->member_ids} }
sub is_active    { $_[0]->status ne 'closed' }

1;
