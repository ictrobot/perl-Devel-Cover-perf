package MyApp::Service::Auth;
use Moo;
use Types::Standard qw(HashRef);
use Digest::SHA qw(sha256_hex);

has sessions => (is => 'ro', isa => HashRef, default => sub { {} });
has tokens   => (is => 'ro', isa => HashRef, default => sub { {} });

sub login {
    my ($self, $user, $password) = @_;
    my $token = sha256_hex($user->id . time . rand);
    $self->sessions->{$token} = { user_id => $user->id, created => time };
    $self->tokens->{$user->id} = $token;
    return $token;
}

sub logout {
    my ($self, $token) = @_;
    if (my $sess = delete $self->sessions->{$token}) {
        delete $self->tokens->{$sess->{user_id}};
        return 1;
    }
    return 0;
}

sub validate_token {
    my ($self, $token) = @_;
    return $self->sessions->{$token};
}

sub user_id_for_token {
    my ($self, $token) = @_;
    my $sess = $self->sessions->{$token} or return undef;
    return $sess->{user_id};
}

1;
