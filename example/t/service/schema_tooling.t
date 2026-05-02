use strict;
use warnings;
use Test::More tests => 12;
use MyApp::Service::SchemaTooling;

my $tooling = MyApp::Service::SchemaTooling->new;
isa_ok($tooling, 'MyApp::Service::SchemaTooling');

my $requirements = $tooling->optional_feature_requirements;
ok($requirements->{'Moose'}, 'requires Moose for loader feature');
ok($requirements->{'MooseX::NonMoose'}, 'requires MooseX::NonMoose for loader feature');
ok($requirements->{'MooseX::MarkAsMethods'}, 'requires MooseX::MarkAsMethods for loader feature');
ok(exists $requirements->{'Config::Any'}, 'requires Config::Any for dbicdump config feature');

my $status = $tooling->optional_feature_status;
is($status->{use_moose}, 1, 'use_moose requirements are available');
is($status->{dbicdump_config}, 1, 'dbicdump config requirements are available');

my $options = $tooling->loader_options;
is($options->{use_moose}, 1, 'loader uses Moose option');
is($options->{only_autoclean}, 1, 'loader uses only_autoclean option');

my $yaml = $tooling->schema_yaml;
like($yaml, qr/^---/, 'translates schema to yaml');
like($yaml, qr/projects:/, 'yaml includes projects table');

my $summary = $tooling->summary;
is($summary->{translated_to_yaml}, 1, 'summary records yaml translation');
