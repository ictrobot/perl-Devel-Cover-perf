use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 15;

use MyApp::Model::Workflow;

my $workflow = MyApp::Model::Workflow->new(id => 'release');
isa_ok($workflow, 'MyApp::Model::Workflow');

my $draft = $workflow->add_step('draft');
my $review = $workflow->add_step('review');
is($workflow->step_count, 2, 'records workflow steps');

$draft->mark_complete;
ok($draft->complete, 'marks a step complete');

my $transition = $workflow->add_transition($draft, $review);
is($transition->label, 'draft -> review', 'labels transitions');

ok(!exists $INC{'MyApp/Model/Workflow/RuleEngine/Experimental.pm'}, 'optional backend is not loaded before rule lookup');
ok(!$workflow->has_rule('approval'), 'missing optional backend means workflow has no external rules');
ok(Workflow::GeneratedRule->matches($workflow, 'approval'), 'generated workflow rule is usable');

is($INC{'MyApp/Model/Workflow/Step.pm'}, '(set by Moose)', 'nested Moose class is marked loaded');
is($INC{'MyApp/Model/Workflow/Transition.pm'}, '(set by Moose)', 'second nested Moose class is marked loaded');
is($INC{'Workflow/GeneratedRule.pm'}, 1, 'generated rule leaves a true %INC value');
ok(exists $INC{'MyApp/Model/Workflow/RuleEngine/Experimental.pm'}
    && !defined $INC{'MyApp/Model/Workflow/RuleEngine/Experimental.pm'},
    'optional backend has undef %INC value');
like($INC{'MyApp/Model/Workflow.pm'}, qr{MyApp/Model/Workflow\.pm\z}, 'main module has a normal source path');

ok(MyApp::Model::Workflow::Step->can('meta'), 'nested step class has Moose metadata');
ok(MyApp::Model::Workflow::Transition->can('meta'), 'nested transition class has Moose metadata');
ok(MyApp::Model::Workflow::Transition->can('new'), 'nested transition class is usable');
