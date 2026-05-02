package MyApp::Report::XmlTaskReader;
use Moo;
use XML::LibXML;

sub parse_tasks {
    my ($self, $xml) = @_;
    my $doc = XML::LibXML->load_xml(string => $xml);
    my @tasks;

    for my $node ($doc->findnodes('/tasks/task')) {
        push @tasks, {
            title    => $node->getAttribute('title') || $node->findvalue('./title'),
            status   => $node->getAttribute('status') || 'open',
            priority => $node->getAttribute('priority') || 'medium',
            due_date => $node->getAttribute('due_date') || undef,
        };
    }

    return \@tasks;
}

sub tasks_to_xml {
    my ($self, $tasks) = @_;
    my $doc = XML::LibXML::Document->new('1.0', 'UTF-8');
    my $root = $doc->createElement('tasks');
    $doc->setDocumentElement($root);

    for my $task (@{$tasks // []}) {
        my $node = $doc->createElement('task');
        $node->setAttribute(title    => $task->{title}    // '');
        $node->setAttribute(status   => $task->{status}   // 'open');
        $node->setAttribute(priority => $task->{priority} // 'medium');
        $node->setAttribute(due_date => $task->{due_date} // '');
        $root->appendChild($node);
    }

    return $doc->toString(0);
}

1;
