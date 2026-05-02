use strict;
use warnings;
use Test::More tests => 5;
use MyApp::Model::Report;

my $r = MyApp::Model::Report->new(title => 'Weekly', type => 'summary', project_id => 'p1');
isa_ok($r, 'MyApp::Model::Report');
ok(!$r->generated, 'not generated');
is($r->row_count, 0, 'no data');

$r->data([{a => 1}, {a => 2}, {a => 3}]);
is($r->row_count, 3, 'three rows');

$r->generate;
ok($r->generated, 'generated');
