package MyApp::Service::TemplateRenderer;
use Moo;
use Types::Standard qw(Str);
use Template;

has project_template => (is => 'ro', isa => Str, default => sub {
    <<'TEMPLATE';
Project: [% project.name %]
Status: [% project.status %]
Members: [% project.member_count %]
Tasks:
[% FOREACH task IN tasks -%]
- [[% task.status %]] [% task.title %] ([% task.priority %])
[% END -%]
TEMPLATE
});

has task_table_template => (is => 'ro', isa => Str, default => sub {
    <<'TEMPLATE';
[% FOREACH task IN tasks -%]
[% task.title %]|[% task.status %]|[% task.priority %]|[% task.due_date %]
[% END -%]
TEMPLATE
});

has engine => (is => 'lazy');

sub _build_engine {
    return Template->new({
        INTERPOLATE => 0,
        EVAL_PERL   => 0,
        ABSOLUTE    => 0,
        RELATIVE    => 0,
    });
}

sub render_project_summary {
    my ($self, $project, $tasks) = @_;
    return $self->render_string($self->project_template, {
        project => $self->_object_data($project, qw(id name description status member_count prefix)),
        tasks   => [map { $self->_object_data($_, qw(id title status priority due_date story_points progress)) } @{$tasks // []}],
    });
}

sub render_task_table {
    my ($self, $tasks) = @_;
    return $self->render_string($self->task_table_template, {
        tasks => [map { $self->_object_data($_, qw(id title status priority due_date story_points progress)) } @{$tasks // []}],
    });
}

sub render_string {
    my ($self, $template, $vars) = @_;
    my $output = '';
    $self->engine->process(\$template, $vars // {}, \$output)
        or die "Template render failed: " . $self->engine->error;
    return $output;
}

sub _object_data {
    my ($self, $object, @fields) = @_;
    my %data;
    for my $field (@fields) {
        if (ref($object) eq 'HASH') {
            $data{$field} = $object->{$field};
        }
        elsif ($object && $object->can($field)) {
            $data{$field} = $object->$field;
        }
        else {
            $data{$field} = undef;
        }
    }
    return \%data;
}

1;
