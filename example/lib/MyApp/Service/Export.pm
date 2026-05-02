package MyApp::Service::Export;
use Moo;

has logger => (is => 'ro', required => 1);

sub to_csv {
    my ($self, $items, @fields) = @_;
    my $csv = join(',', @fields) . "\n";
    for my $item (@$items) {
        $csv .= join(',', map { $item->can($_) ? ($item->$_ // '') : '' } @fields) . "\n";
    }
    return $csv;
}

sub to_json {
    my ($self, $items) = @_;
    require JSON::MaybeXS;
    return JSON::MaybeXS::encode_json([map { $_->can('to_hash') ? $_->to_hash : {} } @$items]);
}

1;
