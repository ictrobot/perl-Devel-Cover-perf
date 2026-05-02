package MyApp::Schema::LoaderPreview;
use strict;
use warnings;
use base 'DBIx::Class::Schema::Loader';
use DBIx::Class::Schema::Loader::RelBuilder;

__PACKAGE__->loader_options(
    naming         => 'current',
    use_namespaces => 1,
    use_moose      => 1,
    only_autoclean => 1,
);

sub feature_options {
    return {
        naming         => 'current',
        use_namespaces => 1,
        use_moose      => 1,
        only_autoclean => 1,
    };
}

1;
