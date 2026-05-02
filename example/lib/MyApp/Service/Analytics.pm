package MyApp::Service::Analytics;
use Moo;
use List::Util qw(sum);

has task_repo => (is => 'ro', required => 1);

sub task_summary {
    my $self = shift;
    my @tasks = @{$self->task_repo->all};
    my %by_status;
    $by_status{$_->status}++ for @tasks;
    return {
        total     => scalar @tasks,
        by_status => \%by_status,
    };
}

sub velocity {
    my ($self, $sprint_tasks) = @_;
    return sum(map { $_->story_points } grep { $_->is_done } @$sprint_tasks) // 0;
}

sub completion_rate {
    my $self = shift;
    my @tasks = @{$self->task_repo->all};
    return 0 unless @tasks;
    my $done = grep { $_->is_done } @tasks;
    return int($done / scalar(@tasks) * 100);
}

1;
