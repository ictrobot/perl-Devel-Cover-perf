package MyApp::Role::HasTimestamps;
use Moo::Role;
use Types::Standard qw(Str);

has created_at => (is => 'ro', isa => Str, default => sub { scalar localtime });
has updated_at => (is => 'rw', isa => Str, default => sub { scalar localtime });

sub touch { $_[0]->updated_at(scalar localtime) }

1;
