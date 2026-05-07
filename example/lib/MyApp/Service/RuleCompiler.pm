package MyApp::Service::RuleCompiler;
use Moo;

my %RULES = (
    high_priority => q{return ($item->{priority} // '') eq 'high';},
    blocked       => q{return ($item->{status} // '') eq 'blocked';},
);

has _compiled_rules => (is => 'ro', default => sub { {} });

sub available_rules {
    return [sort keys %RULES];
}

sub has_rule {
    my ($self, $name) = @_;
    return exists $RULES{$name} ? 1 : 0;
}

sub evaluate_rule {
    my ($self, $name, $item) = @_;
    my $rule = $self->_compiled_rule($name);
    return $rule->($item // {}) ? 1 : 0;
}

sub _compiled_rule {
    my ($self, $name) = @_;

    die "Unknown rule: $name" unless exists $RULES{$name};
    return $self->_compiled_rules->{$name} if $self->_compiled_rules->{$name};

    my $sub_name = "_generated_rule_$name";
    $sub_name =~ s/[^A-Za-z0-9_]/_/g;

    my $source = $INC{'MyApp/Service/RuleCompiler.pm'} || __FILE__;
    my $line = __LINE__ + 4;
    my $perl = <<"PERL";
package MyApp::Service::RuleCompiler;
#line $line "$source"
sub $sub_name {
    my (\$item) = \@_;
    $RULES{$name}
}
1;
PERL

    eval $perl or die "Failed to compile rule $name: $@";

    no strict 'refs';
    return $self->_compiled_rules->{$name} = \&{"MyApp::Service::RuleCompiler::$sub_name"};
}

1;

__END__

=head1 NAME

MyApp::Service::RuleCompiler - lazy rule compiler fixture

=head1 TEST FIXTURE NOTE

This module intentionally compiles rule methods on demand with a C<#line>
directive pointing back at this source file. That models real policy or
validation systems which load normally, then add generated Perl code for a
source file after the file's base structure may already exist.

=head1 METHODS

=head2 available_rules

=head2 has_rule

=head2 evaluate_rule

=cut
