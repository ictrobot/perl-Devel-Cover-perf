package MyApp::Model::Team;
use Moo;
use Types::Standard qw(Str ArrayRef);
use MyApp::Types qw(NonEmptyStr);

with 'MyApp::Role::HasUUID',
     'MyApp::Role::HasTimestamps',
     'MyApp::Role::Serializable',
     'MyApp::Role::Searchable';

has name        => (is => 'rw', isa => NonEmptyStr, required => 1);
has description => (is => 'rw', isa => Str, default => '');
has member_ids  => (is => 'rw', isa => ArrayRef, default => sub { [] });
has lead_id     => (is => 'rw', isa => Str, default => '');

sub searchable_fields { qw(name description) }

sub add_member {
    my ($self, $uid) = @_;
    push @{$self->member_ids}, $uid unless grep { $_ eq $uid } @{$self->member_ids};
}

sub remove_member {
    my ($self, $uid) = @_;
    $self->member_ids([grep { $_ ne $uid } @{$self->member_ids}]);
}

sub member_count { scalar @{$_[0]->member_ids} }
sub has_member   { my ($s,$u)=@_; grep { $_ eq $u } @{$s->member_ids} }

1;
