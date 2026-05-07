use strict;
use warnings;
use Test::More;

plan skip_all => 'skipping generated-structure race fixture'
    if $ENV{DCO_SKIP_RACY_STRUCTURE_FIXTURE};

plan tests => 8;

use MyApp::Service::RuleCompiler;

my $compiler = MyApp::Service::RuleCompiler->new;

ok(!MyApp::Service::RuleCompiler->can('_generated_rule_high_priority'), 'generated rule is absent before first use');

ok($compiler->evaluate_rule('high_priority', { priority => 'high', status => 'open' }), 'matches high priority task');
ok(!$compiler->evaluate_rule('high_priority', { priority => 'low', status => 'open' }), 'rejects low priority task');
ok(MyApp::Service::RuleCompiler->can('_generated_rule_high_priority'), 'generated rule is installed after first use');

ok(!MyApp::Service::RuleCompiler->can('_generated_rule_blocked'), 'second generated rule is still absent');
ok($compiler->evaluate_rule('blocked', { priority => 'low', status => 'blocked' }), 'matches blocked task');
ok(!$compiler->evaluate_rule('blocked', { priority => 'high', status => 'open' }), 'rejects unblocked task');
ok(MyApp::Service::RuleCompiler->can('_generated_rule_blocked'), 'second generated rule is installed on demand');
