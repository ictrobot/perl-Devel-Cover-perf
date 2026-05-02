use strict;
use warnings;
use Test::More tests => 4;
use MyApp::Service::Import;
use MyApp::Logger;

my $import = MyApp::Service::Import->new(logger => MyApp::Logger->new);
my $csv = "name,color\nBug,#ff0000\nFeature,#00ff00\n";

my $records = $import->from_csv($csv);
is(ref $records, 'ARRAY', 'returns array');
is(scalar @$records, 2, 'two records');
is($records->[0]{name}, 'Bug', 'first name');
is($records->[1]{color}, '#00ff00', 'second color');
