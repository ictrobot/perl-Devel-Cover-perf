package MyApp::Service::SchemaTooling;
use Moo;
use Types::Standard qw(Str);
use MyApp::Schema;
use MyApp::Schema::LoaderPreview;
use DBIx::Class::Schema::Loader;
use DBIx::Class::Schema::Loader::RelBuilder;
use DBIx::Class::Schema::Loader::Optional::Dependencies;
use SQL::Translator;
use SQL::Translator::Parser::DBIx::Class;
use SQL::Translator::Producer::YAML;
use Config::Any;
use Moose ();
use MooseX::NonMoose ();
use MooseX::MarkAsMethods ();

BEGIN {
    require DBIx::Class::Schema::Loader::Optional::Dependencies;
    DBIx::Class::Schema::Loader::Optional::Dependencies
        ->die_unless_req_ok_for([qw(use_moose dbicdump_config)]);
}

has schema_class => (is => 'ro', isa => Str, default => 'MyApp::Schema');
has loader_class => (is => 'ro', isa => Str, default => 'MyApp::Schema::LoaderPreview');

sub optional_feature_requirements {
    return DBIx::Class::Schema::Loader::Optional::Dependencies
        ->req_list_for([qw(use_moose dbicdump_config)]);
}

sub optional_feature_status {
    return {
        use_moose       => DBIx::Class::Schema::Loader::Optional::Dependencies->req_ok_for('use_moose') ? 1 : 0,
        dbicdump_config => DBIx::Class::Schema::Loader::Optional::Dependencies->req_ok_for('dbicdump_config') ? 1 : 0,
    };
}

sub loader_options {
    my $self = shift;
    return $self->loader_class->feature_options;
}

sub schema_yaml {
    my $self = shift;
    my $translator = SQL::Translator->new(
        parser      => 'SQL::Translator::Parser::DBIx::Class',
        producer    => 'YAML',
        parser_args => { dbic_schema => $self->schema_class },
    );
    my $yaml = $translator->translate;
    die "Schema translation failed: " . $translator->error unless $yaml;
    return $yaml;
}

sub summary {
    my $self = shift;
    my $requirements = $self->optional_feature_requirements;
    return {
        schema_class       => $self->schema_class,
        loader_class       => $self->loader_class,
        optional_features  => $self->optional_feature_status,
        requirement_count  => scalar keys %$requirements,
        loader_options     => $self->loader_options,
        translated_to_yaml => $self->schema_yaml =~ /^---/ ? 1 : 0,
    };
}

1;
