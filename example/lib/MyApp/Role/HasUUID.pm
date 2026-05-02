package MyApp::Role::HasUUID;
use Moo::Role;
use Types::Standard qw(Str);

has id => (is => 'ro', isa => Str, default => sub {
    my @h = ('0'..'9','a'..'f');
    join '', map { $h[rand @h] } 1..8, '-', 1..4, '-', 1..4, '-', 1..4, '-', 1..12;
});

1;
