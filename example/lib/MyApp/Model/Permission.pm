package MyApp::Model::Permission;
use Moo;
use Types::Standard qw(Str);

with 'MyApp::Role::HasUUID', 'MyApp::Role::Serializable';

has resource => (is => 'ro', isa => Str, required => 1);
has action   => (is => 'ro', isa => Str, required => 1);
has scope    => (is => 'ro', isa => Str, default => 'own');

sub key         { $_[0]->resource . ':' . $_[0]->action }
sub is_global   { $_[0]->scope eq 'global' }
sub description { sprintf "Can %s %s (%s)", $_[0]->action, $_[0]->resource, $_[0]->scope }

1;
