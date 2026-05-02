package MyApp::Web::Plugin::RequestId;
use Moo;
use Digest::SHA qw(sha256_hex);

my $counter = 0;

sub generate {
    $counter++;
    return substr(sha256_hex($counter . time . $$), 0, 16);
}

sub reset_counter { $counter = 0 }

1;
