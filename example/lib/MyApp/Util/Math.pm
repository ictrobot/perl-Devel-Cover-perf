package MyApp::Util::Math;
use strict;
use warnings;
use Exporter 'import';
use List::Util qw(sum min max);

our @EXPORT_OK = qw(average median percentage clamp);

sub average {
    my @nums = @_;
    return 0 unless @nums;
    return sum(@nums) / scalar @nums;
}

sub median {
    my @sorted = sort { $a <=> $b } @_;
    return 0 unless @sorted;
    my $mid = int(@sorted / 2);
    return @sorted % 2 ? $sorted[$mid] : ($sorted[$mid-1] + $sorted[$mid]) / 2;
}

sub percentage {
    my ($part, $total) = @_;
    return 0 unless $total;
    return sprintf("%.1f", $part / $total * 100);
}

sub clamp {
    my ($val, $lo, $hi) = @_;
    return max($lo, min($hi, $val));
}

1;
