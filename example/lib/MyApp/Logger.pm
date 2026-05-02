package MyApp::Logger;
use Moo;
use Types::Standard qw(Str Int ArrayRef);

has level    => (is => 'rw', isa => Str, default => 'info');
has messages => (is => 'ro', isa => ArrayRef, default => sub { [] });

my %LEVELS = (debug => 0, info => 1, warn => 2, error => 3, fatal => 4);

sub _log {
    my ($self, $lvl, $msg) = @_;
    return if ($LEVELS{$lvl} // 0) < ($LEVELS{$self->level} // 0);
    my $entry = sprintf("[%s] [%s] %s", scalar localtime, uc $lvl, $msg);
    push @{$self->messages}, $entry;
    return $entry;
}

sub debug { $_[0]->_log('debug', $_[1]) }
sub info  { $_[0]->_log('info',  $_[1]) }
sub warn  { $_[0]->_log('warn',  $_[1]) }
sub error { $_[0]->_log('error', $_[1]) }
sub fatal { $_[0]->_log('fatal', $_[1]) }
sub clear { @{$_[0]->messages} = () }

1;
