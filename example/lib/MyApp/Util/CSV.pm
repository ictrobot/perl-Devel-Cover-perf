package MyApp::Util::CSV;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(parse_csv generate_csv);

sub parse_csv {
    my $text = shift;
    my @lines = split /\n/, $text;
    my @header = split /,/, shift @lines;
    my @records;
    for my $line (@lines) {
        next unless $line =~ /\S/;
        my @vals = split /,/, $line, -1;
        my %rec;
        @rec{@header} = @vals;
        push @records, \%rec;
    }
    return \@records;
}

sub generate_csv {
    my ($records, @fields) = @_;
    my $out = join(',', @fields) . "\n";
    for my $rec (@$records) {
        $out .= join(',', map { $rec->{$_} // '' } @fields) . "\n";
    }
    return $out;
}

1;
