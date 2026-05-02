package MyApp::Model::Activity;
use Moo;
use Types::Standard qw(Str Maybe HashRef);

with 'MyApp::Role::HasUUID', 'MyApp::Role::HasTimestamps', 'MyApp::Role::Serializable';

has actor_id    => (is => 'ro', isa => Str, required => 1);
has action      => (is => 'ro', isa => Str, required => 1);
has target_type => (is => 'ro', isa => Str, required => 1);
has target_id   => (is => 'ro', isa => Str, required => 1);
has metadata    => (is => 'ro', isa => HashRef, default => sub { {} });
has project_id  => (is => 'ro', isa => Maybe[Str]);

sub summary { sprintf "%s %s %s", $_[0]->actor_id, $_[0]->action, $_[0]->target_type }

1;
