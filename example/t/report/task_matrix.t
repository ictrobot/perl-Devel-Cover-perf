use strict;
use warnings;
use Test::More tests => 5;
use MyApp::Report::TaskMatrix;
use MyApp::Model::Task;

my @tasks = (
    MyApp::Model::Task->new(title => 'One task', status => 'open'),
    MyApp::Model::Task->new(title => 'Two task', status => 'open'),
    MyApp::Model::Task->new(title => 'Done task', status => 'done'),
);

my $matrix = MyApp::Report::TaskMatrix->new;
my $counts = $matrix->counts(\@tasks);
is($counts->{open}, 2, 'counts open');
is($counts->{done}, 1, 'counts done');
is_deeply($matrix->rows(\@tasks)->[0], { status => 'done', count => 1 }, 'sorts rows');
like($matrix->render(\@tasks), qr/open: 2/, 'renders open row');
like($matrix->render(\@tasks), qr/done: 1/, 'renders done row');
