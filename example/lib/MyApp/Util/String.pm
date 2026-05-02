package MyApp::Util::String;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(slugify truncate_str camelize snake_case titleize pluralize);

sub slugify {
    my $s = lc shift;
    $s =~ s/[^a-z0-9]+/-/g;
    $s =~ s/^-|-$//g;
    return $s;
}

sub truncate_str {
    my ($s, $len, $suffix) = @_;
    $len    //= 50;
    $suffix //= '...';
    return length($s) > $len ? substr($s, 0, $len) . $suffix : $s;
}

sub camelize {
    my $s = shift;
    $s =~ s/(?:^|_)(\w)/uc($1)/ge;
    return $s;
}

sub snake_case {
    my $s = shift;
    $s =~ s/([A-Z])/_\L$1/g;
    $s =~ s/^_//;
    return $s;
}

sub titleize {
    my $s = shift;
    $s =~ s/\b(\w)/uc($1)/ge;
    return $s;
}

sub pluralize {
    my $s = shift;
    return $s . 'es' if $s =~ /(?:s|x|z|ch|sh)$/;
    return $s . 's';
}

1;
