use strict;
use warnings;
use Test::More tests => 4;

{
    package TestConfigurable;
    use Moo;
    with 'MyApp::Role::Configurable';
}

my $obj = TestConfigurable->new;
is($obj->get_setting('theme', 'dark'), 'dark', 'default value');

$obj->set_setting('theme', 'light');
is($obj->get_setting('theme'), 'light', 'set value');

$obj->set_setting('lang', 'en');
is($obj->get_setting('lang'), 'en', 'another setting');
is($obj->get_setting('missing', 42), 42, 'missing with default');
