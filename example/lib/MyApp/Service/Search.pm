package MyApp::Service::Search;
use Moo;
use Types::Standard qw(ArrayRef);

has sources => (is => 'rw', isa => ArrayRef, default => sub { [] });

sub add_source { push @{$_[0]->sources}, $_[1] }

sub search {
    my ($self, $query) = @_;
    my @results;
    for my $source (@{$self->sources}) {
        for my $item (@{$source->all}) {
            push @results, $item if $item->can('matches') && $item->matches($query);
        }
    }
    return \@results;
}

sub search_count { scalar @{$_[0]->search($_[1])} }

1;
