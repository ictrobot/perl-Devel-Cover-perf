package MyApp::Service::XmlReport;
use Moo;
use XML::LibXML;

sub project_to_xml {
    my ($self, $project, $tasks) = @_;
    my $doc  = XML::LibXML::Document->new('1.0', 'UTF-8');
    my $root = $doc->createElement('project_report');
    $doc->setDocumentElement($root);

    $root->setAttribute(name   => $self->_value($project, 'name') // '');
    $root->setAttribute(status => $self->_value($project, 'status') // '');
    $root->setAttribute(id     => $self->_value($project, 'id') // '');

    my $description = $doc->createElement('description');
    $description->appendText($self->_value($project, 'description') // '');
    $root->appendChild($description);

    my $task_list = $doc->createElement('tasks');
    for my $task (@{$tasks // []}) {
        my $task_node = $doc->createElement('task');
        $task_node->setAttribute(id       => $self->_value($task, 'id') // '');
        $task_node->setAttribute(status   => $self->_value($task, 'status') // '');
        $task_node->setAttribute(priority => $self->_value($task, 'priority') // '');
        $task_node->setAttribute(due_date => $self->_value($task, 'due_date') // '');

        my $title = $doc->createElement('title');
        $title->appendText($self->_value($task, 'title') // '');
        $task_node->appendChild($title);

        $task_list->appendChild($task_node);
    }
    $root->appendChild($task_list);

    return $doc->toString(0);
}

sub summarize {
    my ($self, $xml) = @_;
    my $doc  = XML::LibXML->load_xml(string => $xml);
    my $root = $doc->documentElement;
    my @tasks = $doc->findnodes('/project_report/tasks/task');
    return {
        name       => $root->getAttribute('name'),
        status     => $root->getAttribute('status'),
        task_count => scalar @tasks,
    };
}

sub task_titles {
    my ($self, $xml) = @_;
    my $doc = XML::LibXML->load_xml(string => $xml);
    return [map { $_->textContent } $doc->findnodes('/project_report/tasks/task/title')];
}

sub _value {
    my ($self, $object, $field) = @_;
    return $object->{$field} if ref($object) eq 'HASH';
    return $object->$field if $object && $object->can($field);
    return undef;
}

1;
