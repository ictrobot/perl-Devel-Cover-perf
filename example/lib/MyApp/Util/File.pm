package MyApp::Util::File;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(extension_of mime_type_for human_size);

my %MIME = (
    png  => 'image/png',
    jpg  => 'image/jpeg',
    gif  => 'image/gif',
    pdf  => 'application/pdf',
    txt  => 'text/plain',
    csv  => 'text/csv',
    json => 'application/json',
    html => 'text/html',
);

sub extension_of {
    return $_[0] =~ /\.(\w+)$/ ? lc $1 : '';
}

sub mime_type_for {
    my $ext = extension_of($_[0]);
    return $MIME{$ext} // 'application/octet-stream';
}

sub human_size {
    my $bytes = shift;
    return sprintf("%.1f KB", $bytes / 1024) if $bytes < 1048576;
    return sprintf("%.1f MB", $bytes / 1048576) if $bytes < 1073741824;
    return sprintf("%.1f GB", $bytes / 1073741824);
}

1;
