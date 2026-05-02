use strict;
use warnings;
use Test::More tests => 5;
use MyApp::Report::XmlArchive;
use MyApp::Service::XmlReport;
use MyApp::Model::Project;

my $xml_report = MyApp::Service::XmlReport->new;
my $one = $xml_report->project_to_xml(MyApp::Model::Project->new(name => 'One'), []);
my $two = $xml_report->project_to_xml(MyApp::Model::Project->new(name => 'Two'), []);

my $archive = MyApp::Report::XmlArchive->new;
my $xml = $archive->wrap_reports([$one, $two]);
like($xml, qr/<archive>/, 'creates archive root');
like($xml, qr/name="One"/, 'contains first report');
like($xml, qr/name="Two"/, 'contains second report');
is($archive->report_count($xml), 2, 'counts reports');
is_deeply($archive->project_names($xml), ['One', 'Two'], 'extracts names');
