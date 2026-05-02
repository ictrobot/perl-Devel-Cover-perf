package MyApp::Repo::Project;
use Moo;
extends 'MyApp::Repo::Base';

sub entity_class { 'MyApp::Model::Project' }

1;
