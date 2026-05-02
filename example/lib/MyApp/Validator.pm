package MyApp::Validator;
use Moo;
use Types::Standard qw(HashRef ArrayRef);

has rules  => (is => 'ro', isa => HashRef, default => sub { {} });
has errors => (is => 'rw', isa => ArrayRef, default => sub { [] });

sub add_rule {
    my ($self, $field, $check) = @_;
    push @{$self->rules->{$field} //= []}, $check;
}

sub validate {
    my ($self, $data) = @_;
    $self->errors([]);
    for my $field (keys %{$self->rules}) {
        for my $check (@{$self->rules->{$field}}) {
            my $result = $check->($data->{$field}, $data);
            push @{$self->errors}, "$field: $result" if $result;
        }
    }
    return scalar @{$self->errors} == 0;
}

sub required {
    return sub { defined $_[0] && length($_[0]) ? undef : 'is required' };
}

sub min_length {
    my $min = shift;
    return sub { defined $_[0] && length($_[0]) >= $min ? undef : "must be at least $min characters" };
}

sub max_length {
    my $max = shift;
    return sub { !defined $_[0] || length($_[0]) <= $max ? undef : "must be at most $max characters" };
}

1;
