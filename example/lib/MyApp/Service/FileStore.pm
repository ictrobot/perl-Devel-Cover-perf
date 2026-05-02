package MyApp::Service::FileStore;
use Moo;
use Types::Standard qw(HashRef Str);

has _files   => (is => 'ro', isa => HashRef, default => sub { {} });
has base_dir => (is => 'ro', isa => Str, default => '/tmp/myapp/uploads');

sub store {
    my ($self, $name, $content) = @_;
    my $key = time . '_' . $name;
    $self->_files->{$key} = { name => $name, content => $content, stored_at => time };
    return $key;
}

sub retrieve  { $_[0]->_files->{$_[1]} }
sub delete    { delete $_[0]->_files->{$_[1]} }
sub file_list { [keys %{$_[0]->_files}] }
sub count     { scalar keys %{$_[0]->_files} }

1;
