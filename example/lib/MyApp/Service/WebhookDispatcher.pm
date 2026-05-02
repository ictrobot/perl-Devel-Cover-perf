package MyApp::Service::WebhookDispatcher;
use Moo;
use Types::Standard qw(ArrayRef);

has webhooks    => (is => 'rw', isa => ArrayRef, default => sub { [] });
has dispatched  => (is => 'ro', isa => ArrayRef, default => sub { [] });
has logger      => (is => 'ro', required => 1);

sub register { push @{$_[0]->webhooks}, $_[1] }

sub dispatch {
    my ($self, $event, $payload) = @_;
    for my $wh (@{$self->webhooks}) {
        next unless $wh->active && $wh->listens_to($event);
        push @{$self->dispatched}, {
            webhook_id => $wh->id,
            event      => $event,
            payload    => $payload,
            sent_at    => scalar localtime,
        };
        $self->logger->info("Dispatched $event to webhook " . $wh->id);
    }
}

sub dispatch_count { scalar @{$_[0]->dispatched} }

1;
