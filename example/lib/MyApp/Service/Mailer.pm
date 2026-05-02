package MyApp::Service::Mailer;
use Moo;
use Types::Standard qw(ArrayRef);

has outbox => (is => 'ro', isa => ArrayRef, default => sub { [] });
has logger => (is => 'ro', required => 1);

sub send {
    my ($self, %mail) = @_;
    push @{$self->outbox}, {
        to      => $mail{to},
        subject => $mail{subject},
        body    => $mail{body},
        sent_at => scalar localtime,
    };
    $self->logger->info("Mail sent to $mail{to}: $mail{subject}");
    return 1;
}

sub sent_count { scalar @{$_[0]->outbox} }
sub last_mail  { $_[0]->outbox->[-1] }

1;
