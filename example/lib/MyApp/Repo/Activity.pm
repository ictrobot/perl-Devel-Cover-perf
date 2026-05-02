package MyApp::Repo::Activity;
use Moo;
extends 'MyApp::Repo::Base';

sub entity_class { 'MyApp::Model::Activity' }

1;
