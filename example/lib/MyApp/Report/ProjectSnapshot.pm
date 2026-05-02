package MyApp::Report::ProjectSnapshot;
use Moo;

sub from_project {
    my ($self, $project, $tasks) = @_;
    my %by_status;
    my $points = 0;

    for my $task (@{$tasks // []}) {
        my $status = $self->_value($task, 'status') // 'unknown';
        $by_status{$status}++;
        $points += $self->_value($task, 'story_points') // 0;
    }

    return {
        project => {
            id           => $self->_value($project, 'id'),
            name         => $self->_value($project, 'name'),
            status       => $self->_value($project, 'status'),
            description  => $self->_value($project, 'description'),
            member_count => $self->_value($project, 'member_count') // 0,
        },
        total_tasks  => scalar @{$tasks // []},
        total_points => $points,
        by_status    => \%by_status,
    };
}

sub _value {
    my ($self, $object, $field) = @_;
    return $object->{$field} if ref($object) eq 'HASH';
    return $object->$field if $object && $object->can($field);
    return undef;
}

1;
