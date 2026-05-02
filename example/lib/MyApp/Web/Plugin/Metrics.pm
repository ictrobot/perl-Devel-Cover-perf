package MyApp::Web::Plugin::Metrics;
use Moo;
use Types::Standard qw(HashRef Int);

has counters   => (is => 'ro', isa => HashRef, default => sub { {} });
has histograms => (is => 'ro', isa => HashRef, default => sub { {} });

sub increment {
    my ($self, $name, $amount) = @_;
    $self->counters->{$name} = ($self->counters->{$name} // 0) + ($amount // 1);
}

sub observe {
    my ($self, $name, $value) = @_;
    push @{$self->histograms->{$name} //= []}, $value;
}

sub get_counter   { $_[0]->counters->{$_[1]} // 0 }
sub get_histogram { $_[0]->histograms->{$_[1]} // [] }

sub summary {
    my $self = shift;
    return {
        counters   => {%{$self->counters}},
        histograms => {map { $_ => scalar @{$self->histograms->{$_}} } keys %{$self->histograms}},
    };
}

1;
