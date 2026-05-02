package MyApp::Role::Searchable;
use Moo::Role;

requires 'searchable_fields';

sub matches {
    my ($self, $query) = @_;
    my $q = lc $query;
    for my $field ($self->searchable_fields) {
        my $val = $self->$field // '';
        return 1 if index(lc($val), $q) >= 0;
    }
    return 0;
}

sub search_summary {
    my $self = shift;
    return join ' | ', map { "$_=" . ($self->$_ // '') } $self->searchable_fields;
}

1;
