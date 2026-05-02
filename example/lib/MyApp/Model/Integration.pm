package MyApp::Model::Integration;
use Moo;
use Types::Standard qw(Str HashRef Bool);

with 'MyApp::Role::HasUUID', 'MyApp::Role::HasTimestamps', 'MyApp::Role::Configurable';

has provider   => (is => 'ro', isa => Str, required => 1);
has project_id => (is => 'ro', isa => Str, required => 1);
has enabled    => (is => 'rw', isa => Bool, default => 1);
has credentials=> (is => 'rw', isa => HashRef, default => sub { {} });

sub toggle  { $_[0]->enabled(!$_[0]->enabled) }
sub display { sprintf "%s integration for %s", ucfirst($_[0]->provider), $_[0]->project_id }

1;
