package MyApp::Model::Tag;
use Moo;
use Types::Standard qw(Str Maybe);
use MyApp::Types qw(NonEmptyStr);

with 'MyApp::Role::HasUUID', 'MyApp::Role::Serializable';

has name  => (is => 'ro', isa => NonEmptyStr, required => 1);
has color => (is => 'rw', isa => Str, default => '#808080');
has slug  => (is => 'lazy', isa => Str);

sub _build_slug {
    my $s = lc $_[0]->name;
    $s =~ s/[^a-z0-9]+/-/g;
    $s =~ s/^-|-$//g;
    return $s;
}

1;
