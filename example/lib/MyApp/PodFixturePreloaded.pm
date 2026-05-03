package MyApp::PodFixturePreloaded;
use strict;
use warnings;

sub documented_value {
    return 'preloaded documented';
}

sub undocumented_value {
    return 'preloaded undocumented';
}

1;

__END__

=head1 NAME

MyApp::PodFixturePreloaded - preloaded POD coverage fixture

=head2 documented_value

Return a value from the fixture module loaded by the forkprove preload.

=head1 TEST FIXTURE NOTE

This POD deliberately documents only part of the public API. Some methods are
left undocumented so the harness exercises both covered and uncovered POD
coverage entries for a preloaded module.

=cut
