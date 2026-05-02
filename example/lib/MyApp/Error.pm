package MyApp::Error;
use Moo;
use Types::Standard qw(Str Int);

has message => (is => 'ro', isa => Str, required => 1);
has code    => (is => 'ro', isa => Int, default => 500);
has type    => (is => 'ro', isa => Str, default => 'internal_error');

sub is_client_error { $_[0]->code >= 400 && $_[0]->code < 500 }
sub is_server_error { $_[0]->code >= 500 }
sub to_string       { sprintf "[%s] %s (code: %d)", $_[0]->type, $_[0]->message, $_[0]->code }

package MyApp::Error::NotFound;
use Moo;
extends 'MyApp::Error';
has '+code' => (default => 404);
has '+type' => (default => 'not_found');

package MyApp::Error::Unauthorized;
use Moo;
extends 'MyApp::Error';
has '+code' => (default => 401);
has '+type' => (default => 'unauthorized');

package MyApp::Error::Forbidden;
use Moo;
extends 'MyApp::Error';
has '+code' => (default => 403);
has '+type' => (default => 'forbidden');

package MyApp::Error::Validation;
use Moo;
extends 'MyApp::Error';
has '+code' => (default => 422);
has '+type' => (default => 'validation_error');

1;
