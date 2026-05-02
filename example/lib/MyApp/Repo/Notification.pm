package MyApp::Repo::Notification;
use Moo;
extends 'MyApp::Repo::Base';

sub entity_class { 'MyApp::Model::Notification' }

1;
