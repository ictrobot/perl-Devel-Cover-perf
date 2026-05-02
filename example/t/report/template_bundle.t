use strict;
use warnings;
use Test::More tests => 4;
use MyApp::Report::TemplateBundle;

my $bundle = MyApp::Report::TemplateBundle->new;
is_deeply([$bundle->names], [qw(project_digest status_line)], 'lists bundled templates');

my $digest = $bundle->render('project_digest', {
    project      => { name => 'Digest Project', status => 'open' },
    total_tasks  => 4,
    total_points => 13,
});
like($digest, qr/Digest Project/, 'renders project name');
like($digest, qr/tasks=4 points=13/, 'renders counts');

my $line = $bundle->render('status_line', { statuses => [{ name => 'open', count => 2 }] });
like($line, qr/open=2/, 'renders status line');
