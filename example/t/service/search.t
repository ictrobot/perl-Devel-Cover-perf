use strict;
use warnings;
use Test::More tests => 5;

use_ok('MyApp::Service::Search');
use_ok('MyApp::Repo::Task');
use_ok('MyApp::Model::Task');

my $repo = MyApp::Repo::Task->new;
$repo->add(MyApp::Model::Task->new(title => 'Fix login bug'));
$repo->add(MyApp::Model::Task->new(title => 'Add search'));
$repo->add(MyApp::Model::Task->new(title => 'Update docs'));

my $search = MyApp::Service::Search->new;
$search->add_source($repo);

my $results = $search->search('login');
is(scalar @$results, 1, 'found one match');
is($results->[0]->title, 'Fix login bug', 'correct match');
