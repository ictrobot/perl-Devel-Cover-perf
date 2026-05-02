package MyApp::Model::Role;
use Moo;
use Types::Standard qw(Str ArrayRef);

with 'MyApp::Role::HasUUID', 'MyApp::Role::Serializable';

has name        => (is => 'ro', isa => Str, required => 1);
has permissions => (is => 'rw', isa => ArrayRef, default => sub { [] });

sub has_permission {
    my ($self, $perm) = @_;
    return grep { $_ eq $perm } @{$self->permissions};
}

sub grant  { my ($s,$p)=@_; push @{$s->permissions}, $p unless $s->has_permission($p) }
sub revoke { my ($s,$p)=@_; $s->permissions([grep { $_ ne $p } @{$s->permissions}]) }

1;
