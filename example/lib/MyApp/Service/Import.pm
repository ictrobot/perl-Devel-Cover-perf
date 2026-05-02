package MyApp::Service::Import;
use Moo;

has logger => (is => 'ro', required => 1);

sub from_csv {
    my ($self, $csv_string) = @_;
    my @lines = split /\n/, $csv_string;
    my $header = shift @lines;
    my @fields = split /,/, $header;
    my @records;
    for my $line (@lines) {
        next unless $line =~ /\S/;
        my @values = split /,/, $line;
        my %record;
        @record{@fields} = @values;
        push @records, \%record;
    }
    $self->logger->info("Imported " . scalar(@records) . " records");
    return \@records;
}

1;
