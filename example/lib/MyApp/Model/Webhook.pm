package MyApp::Model::Webhook;
use Moo;
use Types::Standard qw(Str ArrayRef Bool);

with 'MyApp::Role::HasUUID', 'MyApp::Role::HasTimestamps', 'MyApp::Role::Serializable';

has url        => (is => 'ro', isa => Str, required => 1);
has events     => (is => 'rw', isa => ArrayRef, default => sub { [] });
has secret     => (is => 'ro', isa => Str, default => '');
has active     => (is => 'rw', isa => Bool, default => 1);
has project_id => (is => 'ro', isa => Str, required => 1);

sub listens_to { my ($s,$e) = @_; grep { $_ eq $e } @{$s->events} }
sub disable    { $_[0]->active(0) }
sub enable     { $_[0]->active(1) }

1;
