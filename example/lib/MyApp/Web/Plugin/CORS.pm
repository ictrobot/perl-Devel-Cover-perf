package MyApp::Web::Plugin::CORS;
use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub register ($self, $app, $conf = {}) {
    my $origins = $conf->{origins} // ['*'];
    $app->hook(before_dispatch => sub ($c) {
        $c->res->headers->header('Access-Control-Allow-Origin'  => join(',', @$origins));
        $c->res->headers->header('Access-Control-Allow-Methods' => 'GET, POST, PUT, DELETE, OPTIONS');
        $c->res->headers->header('Access-Control-Allow-Headers' => 'Content-Type, Authorization');
    });
}

1;
