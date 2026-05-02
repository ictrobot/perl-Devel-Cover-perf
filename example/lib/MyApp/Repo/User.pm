package MyApp::Repo::User;
use Moo;
extends 'MyApp::Repo::Base';

sub entity_class { 'MyApp::Model::User' }

1;
