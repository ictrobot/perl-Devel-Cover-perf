package MyApp::Web::Plugin::RateLimit;
use Moo;
use Types::Standard qw(HashRef Int);

has limits  => (is => 'ro', isa => HashRef, default => sub { {} });
has max_rpm => (is => 'ro', isa => Int, default => 60);

sub check {
    my ($self, $client_id) = @_;
    my $now = int(time / 60);
    my $key = "$client_id:$now";
    $self->limits->{$key} = ($self->limits->{$key} // 0) + 1;
    return $self->limits->{$key} <= $self->max_rpm;
}

sub remaining {
    my ($self, $client_id) = @_;
    my $now = int(time / 60);
    my $used = $self->limits->{"$client_id:$now"} // 0;
    return $self->max_rpm - $used;
}

1;
