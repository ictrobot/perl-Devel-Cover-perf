package MyApp::Model::Report;
use Moo;
use Types::Standard qw(Str HashRef ArrayRef);

with 'MyApp::Role::HasUUID', 'MyApp::Role::HasTimestamps', 'MyApp::Role::Serializable';

has title      => (is => 'ro', isa => Str, required => 1);
has type       => (is => 'ro', isa => Str, required => 1);
has project_id => (is => 'ro', isa => Str, required => 1);
has parameters => (is => 'rw', isa => HashRef, default => sub { {} });
has data       => (is => 'rw', isa => ArrayRef, default => sub { [] });
has generated  => (is => 'rw', default => 0);

sub generate {
    my $self = shift;
    $self->generated(1);
    $self->touch;
}

sub row_count { scalar @{$_[0]->data} }

1;
