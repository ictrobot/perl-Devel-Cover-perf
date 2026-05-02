use strict;
use warnings;
use Test::More tests => 4;
use MyApp::Util::CSV qw(parse_csv generate_csv);

my $csv = "name,age\nAlice,30\nBob,25\n";
my $records = parse_csv($csv);
is(scalar @$records, 2, 'two records');
is($records->[0]{name}, 'Alice', 'first name');

my $out = generate_csv($records, 'name', 'age');
like($out, qr/name,age/, 'header');
like($out, qr/Alice,30/, 'data');
