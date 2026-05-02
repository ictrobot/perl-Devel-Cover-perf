use strict;
use warnings;
use Test::More tests => 6;
use MyApp::Schema::LoaderPreview;
use DBIx::Class::Schema::Loader::RelBuilder;

isa_ok('MyApp::Schema::LoaderPreview', 'DBIx::Class::Schema::Loader');

my $options = MyApp::Schema::LoaderPreview->feature_options;
is($options->{naming}, 'current', 'uses current naming');
is($options->{use_namespaces}, 1, 'uses namespaces');
is($options->{use_moose}, 1, 'uses Moose loader feature');
is($options->{only_autoclean}, 1, 'uses only_autoclean feature');
can_ok('DBIx::Class::Schema::Loader::RelBuilder', 'new');
