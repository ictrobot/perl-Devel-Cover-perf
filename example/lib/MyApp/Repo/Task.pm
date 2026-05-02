package MyApp::Repo::Task;
use Moo;
extends 'MyApp::Repo::Base';

sub entity_class { 'MyApp::Model::Task' }

1;
