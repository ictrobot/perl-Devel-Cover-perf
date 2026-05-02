package MyApp::Repo::Sprint;
use Moo;
extends 'MyApp::Repo::Base';

sub entity_class { 'MyApp::Model::Sprint' }

1;
