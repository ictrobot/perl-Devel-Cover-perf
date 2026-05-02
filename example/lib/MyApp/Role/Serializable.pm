package MyApp::Role::Serializable;
use Moo::Role;

sub to_hash {
    my $self = shift;
    return { %$self };
}

sub to_json {
    my $self = shift;
    require JSON::MaybeXS;
    return JSON::MaybeXS::encode_json($self->to_hash);
}

1;
