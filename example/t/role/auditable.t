use strict;
use warnings;
use Test::More tests => 5;

{
    package TestAuditable;
    use Moo;
    with 'MyApp::Role::Auditable';
}

my $obj = TestAuditable->new;
is($obj->audit_count, 0, 'no audits');

$obj->record_change('status', 'open', 'closed');
is($obj->audit_count, 1, 'one audit');
is($obj->audit_log->[0]{field}, 'status', 'field recorded');
is($obj->audit_log->[0]{old_value}, 'open', 'old value');

$obj->record_change('priority', 'low', 'high');
is($obj->audit_count, 2, 'two audits');
