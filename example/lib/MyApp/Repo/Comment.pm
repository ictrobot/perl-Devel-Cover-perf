package MyApp::Repo::Comment;
use Moo;
extends 'MyApp::Repo::Base';

sub entity_class { 'MyApp::Model::Comment' }

1;
