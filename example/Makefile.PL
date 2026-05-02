use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'MyApp',
    VERSION_FROM => 'lib/MyApp.pm',
    PREREQ_PM    => {
        'Moo'                  => '2.005',
        'Type::Tiny'           => '2.0',
        'Mojolicious'          => '9.0',
        'namespace::autoclean' => 0,
        'JSON::MaybeXS'        => 0,
        'Template'             => 0,
        'XML::LibXML'          => 0,
        'DateTime'             => 0,
        'DBIx::Class'          => 0,
        'DBIx::Class::Schema::Loader' => 0,
        'SQL::Translator'      => 0,
        'Config::Any'          => 0,
        'Moose'                => 0,
        'MooseX::NonMoose'     => 0,
        'MooseX::MarkAsMethods' => 0,
    },
    TEST_REQUIRES => {
        'Test::More'      => 0,
        'Test::Exception' => 0,
        'Test::Deep'      => 0,
    },
    test => { TESTS => 't/*.t t/*/*.t t/*/*/*.t' },
);
