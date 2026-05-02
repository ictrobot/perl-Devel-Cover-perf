package MyApp::Repo::Team;
use Moo;
extends 'MyApp::Repo::Base';

sub entity_class { 'MyApp::Model::Team' }

1;
