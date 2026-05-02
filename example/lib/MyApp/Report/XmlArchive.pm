package MyApp::Report::XmlArchive;
use Moo;
use XML::LibXML;

sub wrap_reports {
    my ($self, $reports) = @_;
    my $doc = XML::LibXML::Document->new('1.0', 'UTF-8');
    my $root = $doc->createElement('archive');
    $doc->setDocumentElement($root);

    for my $xml (@{$reports // []}) {
        my $report_doc = XML::LibXML->load_xml(string => $xml);
        my $imported = $doc->importNode($report_doc->documentElement, 1);
        $root->appendChild($imported);
    }

    return $doc->toString(0);
}

sub project_names {
    my ($self, $archive_xml) = @_;
    my $doc = XML::LibXML->load_xml(string => $archive_xml);
    return [map { $_->value } $doc->findnodes('/archive/project_report/@name')];
}

sub report_count {
    my ($self, $archive_xml) = @_;
    my $doc = XML::LibXML->load_xml(string => $archive_xml);
    my @reports = $doc->findnodes('/archive/project_report');
    return scalar @reports;
}

1;
