package MyApp::Model::Filter;
use Moo;
use Types::Standard qw(Str HashRef ArrayRef);

with 'MyApp::Role::HasUUID', 'MyApp::Role::Serializable';

has name       => (is => 'ro', isa => Str, required => 1);
has owner_id   => (is => 'ro', isa => Str, required => 1);
has conditions => (is => 'rw', isa => ArrayRef, default => sub { [] });
has sort_by    => (is => 'rw', isa => Str, default => 'created_at');
has sort_order => (is => 'rw', isa => Str, default => 'desc');

sub add_condition {
    my ($self, $field, $op, $value) = @_;
    push @{$self->conditions}, { field => $field, op => $op, value => $value };
}

sub apply {
    my ($self, $items) = @_;
    my @result = @$items;
    for my $cond (@{$self->conditions}) {
        @result = grep {
            my $f = $cond->{field};
            my $v = $_->can($f) ? $_->$f : undef;
            _match($v, $cond->{op}, $cond->{value});
        } @result;
    }
    return \@result;
}

sub _match {
    my ($val, $op, $target) = @_;
    return 0 unless defined $val;
    return $val eq $target     if $op eq 'eq';
    return $val ne $target     if $op eq 'ne';
    return index($val, $target) >= 0 if $op eq 'contains';
    return 0;
}

1;
