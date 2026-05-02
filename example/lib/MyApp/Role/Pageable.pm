package MyApp::Role::Pageable;
use Moo::Role;

sub paginate {
    my ($self, $items, %opts) = @_;
    my $page     = $opts{page} || 1;
    my $per_page = $opts{per_page} || 20;
    my $start    = ($page - 1) * $per_page;
    my @slice    = splice @{[@$items]}, $start, $per_page;
    return {
        items       => \@slice,
        page        => $page,
        per_page    => $per_page,
        total       => scalar @$items,
        total_pages => int((scalar @$items + $per_page - 1) / $per_page),
    };
}

1;
