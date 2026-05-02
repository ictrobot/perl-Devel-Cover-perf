package MyApp::Report::TaskMatrix;
use Moo;
use Template;

has template => (is => 'ro', default => sub {
    <<'TEMPLATE';
[% FOREACH row IN rows -%]
[% row.status %]: [% row.count %]
[% END -%]
TEMPLATE
});

has engine => (is => 'lazy');

sub _build_engine { Template->new({ EVAL_PERL => 0 }) }

sub counts {
    my ($self, $tasks) = @_;
    my %counts;
    for my $task (@{$tasks // []}) {
        my $status = $task->can('status') ? $task->status : 'unknown';
        $counts{$status}++;
    }
    return \%counts;
}

sub rows {
    my ($self, $tasks) = @_;
    my $counts = $self->counts($tasks);
    return [map { { status => $_, count => $counts->{$_} } } sort keys %$counts];
}

sub render {
    my ($self, $tasks) = @_;
    my $output = '';
    $self->engine->process(\$self->template, { rows => $self->rows($tasks) }, \$output)
        or die "Task matrix render failed: " . $self->engine->error;
    return $output;
}

1;
