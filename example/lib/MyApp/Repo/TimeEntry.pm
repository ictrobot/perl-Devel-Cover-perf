package MyApp::Repo::TimeEntry;
use Moo;
extends 'MyApp::Repo::Base';

sub entity_class { 'MyApp::Model::TimeEntry' }

1;
