package MyApp::Repo::Milestone;
use Moo;
extends 'MyApp::Repo::Base';

sub entity_class { 'MyApp::Model::Milestone' }

1;
