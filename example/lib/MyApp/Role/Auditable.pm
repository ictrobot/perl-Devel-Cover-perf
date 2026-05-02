package MyApp::Role::Auditable;
use Moo::Role;
use Types::Standard qw(ArrayRef);

has audit_log => (is => 'ro', isa => ArrayRef, default => sub { [] });

sub record_change {
    my ($self, $field, $old, $new) = @_;
    push @{$self->audit_log}, {
        field     => $field,
        old_value => $old,
        new_value => $new,
        timestamp => scalar localtime,
    };
}

sub audit_count { scalar @{$_[0]->audit_log} }

1;
