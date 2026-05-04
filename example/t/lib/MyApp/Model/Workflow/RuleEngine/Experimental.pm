package MyApp::Model::Workflow::RuleEngine::Experimental;
use strict;
use warnings;

sub has_rule {
    my ($workflow, $rule) = @_;
    return $workflow->id eq 'release' && $rule eq 'approval';
}

# Die during require so Perl leaves this module's %INC value as undef.
die "experimental workflow rule engine failed to initialize";

1;
