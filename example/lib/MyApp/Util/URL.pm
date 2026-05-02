package MyApp::Util::URL;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(build_query parse_query url_encode url_decode);

sub build_query {
    my %params = @_;
    return join '&', map { url_encode($_) . '=' . url_encode($params{$_}) }
                     sort keys %params;
}

sub parse_query {
    my $qs = shift // '';
    my %params;
    for my $pair (split /&/, $qs) {
        my ($k, $v) = split /=/, $pair, 2;
        $params{url_decode($k)} = url_decode($v // '');
    }
    return %params;
}

sub url_encode {
    my $s = shift // '';
    $s =~ s/([^A-Za-z0-9\-_.~])/sprintf("%%%02X", ord($1))/ge;
    return $s;
}

sub url_decode {
    my $s = shift // '';
    $s =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;
    return $s;
}

1;
