package MyApp::Result;
use Moo;
use Types::Standard qw(Any Bool Str Maybe);

has value   => (is => 'ro', isa => Any);
has error   => (is => 'ro', isa => Maybe[Str]);
has success => (is => 'ro', isa => Bool, default => 1);

sub ok {
    my ($class, $value) = @_;
    return $class->new(value => $value, success => 1);
}

sub fail {
    my ($class, $error) = @_;
    return $class->new(error => $error, success => 0);
}

sub is_ok    { $_[0]->success }
sub is_error { !$_[0]->success }

sub unwrap {
    my $self = shift;
    die "Unwrap on error result: " . ($self->error // 'unknown') unless $self->success;
    return $self->value;
}

1;
