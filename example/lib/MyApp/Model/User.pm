package MyApp::Model::User;
use Moo;
use Types::Standard qw(Str ArrayRef Maybe);
use MyApp::Types qw(EmailStr NonEmptyStr);

with 'MyApp::Role::HasUUID',
     'MyApp::Role::HasTimestamps',
     'MyApp::Role::Serializable',
     'MyApp::Role::Validatable',
     'MyApp::Role::Searchable';

has username     => (is => 'ro', isa => NonEmptyStr, required => 1);
has email        => (is => 'rw', isa => EmailStr, required => 1);
has display_name => (is => 'rw', isa => Str, default => '');
has role         => (is => 'rw', isa => Str, default => 'member');
has team_ids     => (is => 'rw', isa => ArrayRef, default => sub { [] });
has avatar_url   => (is => 'rw', isa => Maybe[Str]);
has active       => (is => 'rw', default => 1);

sub searchable_fields { qw(username email display_name) }

sub validate {
    my $self = shift;
    $self->add_error('Username too short') if length($self->username) < 3;
    $self->add_error('Invalid email') unless $self->email =~ /@/;
}

sub full_name { $_[0]->display_name || $_[0]->username }
sub is_admin  { $_[0]->role eq 'admin' }
sub deactivate { $_[0]->active(0); $_[0]->touch }

1;
