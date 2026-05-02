use strict;
use warnings;
use Test::More tests => 5;
use MyApp::Util::CSV qw(generate_csv);

my @data = ({ name => 'Alice', score => 95 }, { name => 'Bob', score => 87 });
my $csv = generate_csv(\@data, 'name', 'score');

like($csv, qr/^name,score\n/, 'header');
like($csv, qr/Alice,95/, 'first row');
like($csv, qr/Bob,87/, 'second row');

my $empty_csv = generate_csv([], 'a', 'b');
is($empty_csv, "a,b\n", 'empty data');

my @missing = ({ name => 'X' });
my $partial = generate_csv(\@missing, 'name', 'age');
like($partial, qr/X,\n/, 'missing field is empty');
