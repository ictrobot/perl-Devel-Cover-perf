package MyApp::Model::Notification;
use Moo;
use Types::Standard qw(Str Bool Maybe);

with 'MyApp::Role::HasUUID', 'MyApp::Role::HasTimestamps', 'MyApp::Role::Serializable';

has user_id  => (is => 'ro', isa => Str, required => 1);
has type     => (is => 'ro', isa => Str, required => 1);
has message  => (is => 'ro', isa => Str, required => 1);
has read     => (is => 'rw', isa => Bool, default => 0);
has link     => (is => 'ro', isa => Maybe[Str]);

sub mark_read   { $_[0]->read(1); $_[0]->touch }
sub mark_unread { $_[0]->read(0) }
sub is_unread   { !$_[0]->read }

1;
