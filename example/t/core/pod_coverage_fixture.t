use strict;
use warnings;
use Test::More tests => 4;
use MyApp::PodFixtureOnDemand;
use MyApp::PodFixturePreloaded;

is(
    MyApp::PodFixturePreloaded::documented_value(),
    'preloaded documented',
    'preloaded documented fixture method'
);
is(
    MyApp::PodFixturePreloaded::undocumented_value(),
    'preloaded undocumented',
    'preloaded undocumented fixture method'
);
is(
    MyApp::PodFixtureOnDemand::documented_value(),
    'on-demand documented',
    'on-demand documented fixture method'
);
is(
    MyApp::PodFixtureOnDemand::undocumented_value(),
    'on-demand undocumented',
    'on-demand undocumented fixture method'
);
