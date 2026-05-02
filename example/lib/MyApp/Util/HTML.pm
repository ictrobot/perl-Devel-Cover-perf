package MyApp::Util::HTML;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(escape_html strip_tags nl2br truncate_html);

sub escape_html {
    my $s = shift // '';
    $s =~ s/&/&amp;/g;
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    $s =~ s/"/&quot;/g;
    return $s;
}

sub strip_tags {
    my $s = shift // '';
    $s =~ s/<[^>]*>//g;
    return $s;
}

sub nl2br {
    my $s = shift // '';
    $s =~ s/\n/<br>\n/g;
    return $s;
}

sub truncate_html {
    my ($s, $len) = @_;
    $len //= 200;
    my $plain = strip_tags($s);
    return length($plain) > $len ? substr($plain, 0, $len) . '...' : $plain;
}

1;
