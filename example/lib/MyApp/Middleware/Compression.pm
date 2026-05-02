package MyApp::Middleware::Compression;
use Moo;
use Types::Standard qw(Int);

has min_size  => (is => 'ro', isa => Int, default => 1024);
has algorithm => (is => 'ro', default => 'gzip');

sub should_compress {
    my ($self, $content_length, $content_type) = @_;
    return 0 if $content_length < $self->min_size;
    return 1 if $content_type =~ m{^(?:text/|application/json)};
    return 0;
}

1;
