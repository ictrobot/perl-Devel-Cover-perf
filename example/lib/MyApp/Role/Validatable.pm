package MyApp::Role::Validatable;
use Moo::Role;
use Types::Standard qw(ArrayRef);

has errors => (is => 'rw', isa => ArrayRef, default => sub { [] });

sub is_valid {
    my $self = shift;
    $self->errors([]);
    $self->validate if $self->can('validate');
    return scalar @{$self->errors} == 0;
}

sub add_error {
    my ($self, $msg) = @_;
    push @{$self->errors}, $msg;
}

1;
