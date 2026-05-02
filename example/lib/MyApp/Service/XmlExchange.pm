package MyApp::Service::XmlExchange;
use Moo;
use MyApp::Report::XmlArchive;
use MyApp::Report::XmlTaskReader;

has archive => (is => 'lazy');
has reader  => (is => 'lazy');

sub _build_archive { MyApp::Report::XmlArchive->new }
sub _build_reader  { MyApp::Report::XmlTaskReader->new }

sub export_archive {
    my ($self, $reports) = @_;
    return $self->archive->wrap_reports($reports);
}

sub archive_names {
    my ($self, $xml) = @_;
    return $self->archive->project_names($xml);
}

sub import_tasks {
    my ($self, $xml) = @_;
    return $self->reader->parse_tasks($xml);
}

sub export_tasks {
    my ($self, $tasks) = @_;
    return $self->reader->tasks_to_xml($tasks);
}

1;
