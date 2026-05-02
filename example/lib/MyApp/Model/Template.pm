package MyApp::Model::Template;
use Moo;
use Types::Standard qw(Str HashRef);

with 'MyApp::Role::HasUUID', 'MyApp::Role::HasTimestamps', 'MyApp::Role::Serializable';

has name     => (is => 'ro', isa => Str, required => 1);
has type     => (is => 'ro', isa => Str, required => 1);
has content  => (is => 'rw', isa => Str, default => '');
has defaults => (is => 'rw', isa => HashRef, default => sub { {} });

sub render {
    my ($self, %vars) = @_;
    my $out = $self->content;
    my %merged = (%{$self->defaults}, %vars);
    $out =~ s/\{\{(\w+)\}\}/$merged{$1} \/\/ ''/ge;
    return $out;
}

1;
