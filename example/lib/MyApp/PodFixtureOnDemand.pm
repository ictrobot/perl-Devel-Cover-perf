package MyApp::PodFixtureOnDemand;
use strict;
use warnings;

sub documented_value {
    return 'on-demand documented';
}

sub undocumented_value {
    return 'on-demand undocumented';
}

1;

__END__

=head1 NAME

MyApp::PodFixtureOnDemand - on-demand POD coverage fixture

=head2 documented_value

Return a value from the fixture module loaded only by its test.

=head1 TEST FIXTURE NOTE

This POD deliberately documents only part of the public API. Some methods are
left undocumented so the harness exercises both covered and uncovered POD
coverage entries for a module that is not preloaded.

=cut
