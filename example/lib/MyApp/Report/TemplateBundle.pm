package MyApp::Report::TemplateBundle;
use Moo;
use Template;

has templates => (is => 'ro', default => sub {
    {
        project_digest => <<'TEMPLATE',
[% project.name %] ([% project.status %])
tasks=[% total_tasks %] points=[% total_points %]
TEMPLATE
        status_line => <<'TEMPLATE',
[% FOREACH status IN statuses -%]
[% status.name %]=[% status.count %][% " " UNLESS loop.last %]
[% END -%]
TEMPLATE
    }
});

has engine => (is => 'lazy');

sub _build_engine {
    return Template->new({ EVAL_PERL => 0 });
}

sub names {
    my $self = shift;
    return sort keys %{$self->templates};
}

sub render {
    my ($self, $name, $vars) = @_;
    die "Unknown template: $name" unless exists $self->templates->{$name};
    my $output = '';
    $self->engine->process(\$self->templates->{$name}, $vars // {}, \$output)
        or die "Template render failed: " . $self->engine->error;
    return $output;
}

1;
