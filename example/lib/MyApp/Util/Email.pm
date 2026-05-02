package MyApp::Util::Email;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(is_valid_email normalize_email extract_domain);

sub is_valid_email {
    return $_[0] =~ /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/ ? 1 : 0;
}

sub normalize_email { lc $_[0] }

sub extract_domain {
    my ($email) = @_;
    return $email =~ /@(.+)$/ ? $1 : undef;
}

1;
