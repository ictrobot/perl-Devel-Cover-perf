use strict;
use warnings;
use Test::More tests => 3;
use MyApp::Service::Export;
use MyApp::Logger;
use MyApp::Model::Tag;

my $export = MyApp::Service::Export->new(logger => MyApp::Logger->new);
my @tags = (
    MyApp::Model::Tag->new(name => 'Bug', color => '#ff0000'),
    MyApp::Model::Tag->new(name => 'Feature', color => '#00ff00'),
);

my $csv = $export->to_csv(\@tags, 'name', 'color');
like($csv, qr/name,color/, 'csv header');
like($csv, qr/Bug/, 'csv contains Bug');

my $json = $export->to_json(\@tags);
like($json, qr/Bug/, 'json contains Bug');
