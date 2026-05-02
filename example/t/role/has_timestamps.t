use strict;
use warnings;
use Test::More tests => 4;

{
    package TestTimestamped;
    use Moo;
    with 'MyApp::Role::HasTimestamps';
}

use_ok('MyApp::Role::HasTimestamps');

my $obj = TestTimestamped->new;
ok($obj->created_at, 'created_at set');
ok($obj->updated_at, 'updated_at set');

my $old = $obj->updated_at;
$obj->touch;
ok($obj->updated_at, 'updated_at changed after touch');
