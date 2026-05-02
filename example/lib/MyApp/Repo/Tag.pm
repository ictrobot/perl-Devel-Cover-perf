package MyApp::Repo::Tag;
use Moo;
extends 'MyApp::Repo::Base';

sub entity_class { 'MyApp::Model::Tag' }

1;
