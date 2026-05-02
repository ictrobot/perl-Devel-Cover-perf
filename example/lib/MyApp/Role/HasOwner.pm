package MyApp::Role::HasOwner;
use Moo::Role;
use Types::Standard qw(Str Maybe);

has owner_id => (is => 'rw', isa => Maybe[Str]);

sub is_owned_by {
    my ($self, $user_id) = @_;
    return defined $self->owner_id && $self->owner_id eq $user_id;
}

sub assign_owner {
    my ($self, $user_id) = @_;
    $self->owner_id($user_id);
}

1;
