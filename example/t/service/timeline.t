use strict;
use warnings;
use Test::More tests => 9;
use MyApp::Service::Timeline;
use MyApp::Model::Task;

my $timeline = MyApp::Service::Timeline->new(today => '2026-05-02');

is($timeline->days_until('2026-05-05'), 3, 'counts days until future date');
is($timeline->days_until('2026-05-01'), -1, 'counts overdue date');
is($timeline->status_for_due_date(undef), 'no_due_date', 'handles missing due date');
is($timeline->status_for_due_date('2026-05-01'), 'overdue', 'detects overdue');
is($timeline->status_for_due_date('2026-05-02'), 'due_today', 'detects due today');
is($timeline->status_for_due_date('2026-05-06'), 'due_soon', 'detects due soon');
is($timeline->working_days_between('2026-05-01', '2026-05-04'), 2, 'counts weekdays inclusively');

my @tasks = (
    MyApp::Model::Task->new(title => 'Alpha task', due_date => '2026-05-04'),
    MyApp::Model::Task->new(title => 'Beta task',  due_date => '2026-05-05'),
);
my $buckets = $timeline->bucket_tasks_by_due_week(\@tasks);
is(scalar keys %$buckets, 1, 'groups tasks into one week');
is(scalar @{(values %$buckets)[0]}, 2, 'keeps both tasks in the week');
