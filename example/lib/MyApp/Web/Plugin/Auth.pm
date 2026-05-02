package MyApp::Web::Plugin::Auth;
use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub register ($self, $app, $conf = {}) {
    $app->helper(current_user => sub {
        my $c = shift;
        return $c->stash('current_user');
    });
    $app->helper(is_authenticated => sub {
        my $c = shift;
        return defined $c->stash('current_user');
    });
}

1;
