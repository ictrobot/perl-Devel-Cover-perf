package MyApp::Repo::Template;
use Moo;
extends 'MyApp::Repo::Base';

sub entity_class { 'MyApp::Model::Template' }

1;
