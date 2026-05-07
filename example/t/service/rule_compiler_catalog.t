use strict;
use warnings;
use Test::More tests => 4;
use MyApp::Service::RuleCompiler;

my $compiler = MyApp::Service::RuleCompiler->new;

is_deeply($compiler->available_rules, [qw(blocked high_priority)], 'lists configured rules');
ok($compiler->has_rule('blocked'), 'knows configured rule');
ok(!$compiler->has_rule('unknown'), 'rejects unknown rule');
ok(!MyApp::Service::RuleCompiler->can('_generated_rule_blocked'), 'catalog path does not compile rule code');
