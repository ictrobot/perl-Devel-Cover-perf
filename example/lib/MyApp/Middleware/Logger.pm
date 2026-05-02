package MyApp::Middleware::Logger;
use Moo;
use Types::Standard qw(ArrayRef);

has entries => (is => 'ro', isa => ArrayRef, default => sub { [] });

sub log_request {
    my ($self, $method, $path, $status, $duration) = @_;
    push @{$self->entries}, {
        method   => $method,
        path     => $path,
        status   => $status,
        duration => $duration,
        time     => scalar localtime,
    };
}

sub recent { my ($s,$n)=@_; $n//=10; [splice @{[@{$s->entries}]}, -$n] }

1;
