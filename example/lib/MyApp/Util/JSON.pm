package MyApp::Util::JSON;
use strict;
use warnings;
use Exporter 'import';
use JSON::MaybeXS ();

our @EXPORT_OK = qw(encode decode pretty_encode);

sub encode        { JSON::MaybeXS::encode_json($_[0]) }
sub decode        { JSON::MaybeXS::decode_json($_[0]) }
sub pretty_encode { JSON::MaybeXS->new(pretty => 1, canonical => 1)->encode($_[0]) }

1;
