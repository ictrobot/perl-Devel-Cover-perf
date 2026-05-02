use strict;
use warnings;
use Test::More tests => 5;
use MyApp::Service::Mailer;
use MyApp::Logger;

my $mailer = MyApp::Service::Mailer->new(logger => MyApp::Logger->new);
is($mailer->sent_count, 0, 'no mail');

$mailer->send(to => 'alice@test.com', subject => 'Hello', body => 'World');
is($mailer->sent_count, 1, 'one sent');
is($mailer->last_mail->{to}, 'alice@test.com', 'correct recipient');

$mailer->send(to => 'bob@test.com', subject => 'Hi', body => 'There');
is($mailer->sent_count, 2, 'two sent');
is($mailer->last_mail->{subject}, 'Hi', 'last mail subject');
