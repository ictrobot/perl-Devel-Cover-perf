use strict;
use warnings;
use Test::More tests => 7;
use MyApp::Util::CSV qw(parse_csv);

my $csv = "name,age,city\nAlice,30,NYC\nBob,25,LA\nCarol,35,SF\n";
my $records = parse_csv($csv);
is(scalar @$records, 3, 'three records');
is($records->[0]{name}, 'Alice', 'first name');
is($records->[0]{age}, '30', 'first age');
is($records->[1]{city}, 'LA', 'second city');
is($records->[2]{name}, 'Carol', 'third name');

my $empty = parse_csv("a,b\n");
is(scalar @$empty, 0, 'no data rows');

my $one = parse_csv("x\nval\n");
is($one->[0]{x}, 'val', 'single column');
