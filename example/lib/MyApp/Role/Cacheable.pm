package MyApp::Role::Cacheable;
use Moo::Role;
use Types::Standard qw(Int);

has cache_ttl => (is => 'ro', isa => Int, default => 300);

sub cache_key {
    my $self = shift;
    my $class = ref $self;
    my $id = $self->can('id') ? $self->id : refaddr($self);
    return "${class}::${id}";
}

sub is_cache_expired {
    my ($self, $cached_at) = @_;
    return (time - $cached_at) > $self->cache_ttl;
}

1;
