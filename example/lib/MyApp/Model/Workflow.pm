package MyApp::Model::Workflow;
use Moose;

has id => (is => 'ro', isa => 'Str', required => 1);
has steps => (is => 'ro', isa => 'ArrayRef', default => sub { [] });
has transitions => (is => 'ro', isa => 'ArrayRef', default => sub { [] });

sub add_step {
    my ($self, $name) = @_;
    my $step = MyApp::Model::Workflow::Step->new(name => $name);
    push @{$self->steps}, $step;
    return $step;
}

sub add_transition {
    my ($self, $from, $to) = @_;
    my $transition = MyApp::Model::Workflow::Transition->new(from => $from, to => $to);
    push @{$self->transitions}, $transition;
    return $transition;
}

sub step_count {
    my $self = shift;
    return scalar @{$self->steps};
}

sub has_rule {
    my ($self, $rule) = @_;
    my $ok = eval {
        require MyApp::Model::Workflow::RuleEngine::Experimental;
        1;
    };

    return $ok && MyApp::Model::Workflow::RuleEngine::Experimental::has_rule($self, $rule) ? 1 : 0;
}

__PACKAGE__->meta->make_immutable;

package MyApp::Model::Workflow::Step;
use Moose;

has name => (is => 'ro', isa => 'Str', required => 1);
has complete => (is => 'rw', isa => 'Bool', default => 0);

sub mark_complete {
    my $self = shift;
    $self->complete(1);
    return $self;
}

__PACKAGE__->meta->make_immutable;

package MyApp::Model::Workflow::Transition;
use Moose;

has from => (is => 'ro', required => 1);
has to   => (is => 'ro', required => 1);

sub label {
    my $self = shift;
    return $self->from->name . ' -> ' . $self->to->name;
}

__PACKAGE__->meta->make_immutable;

package Workflow::GeneratedRule;
use strict;
use warnings;

BEGIN {
    $INC{'Workflow/GeneratedRule.pm'} = 1;
}

sub matches {
    my ($class, $workflow, $rule) = @_;
    return $workflow->id eq 'release' && $rule eq 'approval';
}

1;

__END__

=head1 NAME

MyApp::Model::Workflow - workflow fixture with non-standard %INC values

=head1 TEST FIXTURE NOTE

This module intentionally defines multiple classes in one file, marks one
generated package with a true C<%INC> value, and tries to load an optional rule
engine that fails during compilation. The tests use that to exercise true
sentinels, Moose's C<(set by Moose)> sentinels, and C<undef> values in C<%INC>.

=cut
