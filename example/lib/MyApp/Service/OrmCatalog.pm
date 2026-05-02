package MyApp::Service::OrmCatalog;
use Moo;
use Types::Standard qw(Str);
use MyApp::Schema;

has schema_class => (is => 'ro', isa => Str, default => 'MyApp::Schema');

sub result_sources {
    my $self = shift;
    return [sort $self->schema_class->sources];
}

sub table_for {
    my ($self, $source_name) = @_;
    return $self->_source($source_name)->from;
}

sub columns_for {
    my ($self, $source_name) = @_;
    return [$self->_source($source_name)->columns];
}

sub primary_columns_for {
    my ($self, $source_name) = @_;
    return [$self->_source($source_name)->primary_columns];
}

sub relationships_for {
    my ($self, $source_name) = @_;
    return [sort $self->_source($source_name)->relationships];
}

sub describe_source {
    my ($self, $source_name) = @_;
    return {
        source        => $source_name,
        table         => $self->table_for($source_name),
        columns       => $self->columns_for($source_name),
        primary_key   => $self->primary_columns_for($source_name),
        relationships => $self->relationships_for($source_name),
    };
}

sub describe_schema {
    my $self = shift;
    return {
        schema  => $self->schema_class,
        sources => [map { $self->describe_source($_) } @{$self->result_sources}],
    };
}

sub column_info {
    my ($self, $source_name, $column) = @_;
    return { %{$self->_source($source_name)->column_info($column)} };
}

sub _source {
    my ($self, $source_name) = @_;
    return $self->schema_class->source($source_name);
}

1;
