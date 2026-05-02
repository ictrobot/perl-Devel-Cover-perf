package MyApp::Types;
use strict;
use warnings;
use Type::Library -base, -declare => qw(
    PositiveInt NonEmptyStr EmailStr StatusStr PriorityStr
    UUIDStr DateStr Percentage
);
use Type::Utils -all;
use Types::Standard -types;

declare PositiveInt, as Int, where { $_ > 0 };
declare NonEmptyStr, as Str, where { length($_) > 0 };
declare EmailStr, as Str, where { /\A[^@]+@[^@]+\.[^@]+\z/ };
declare StatusStr, as Str, where { /\A(?:open|in_progress|review|done|closed)\z/ };
declare PriorityStr, as Str, where { /\A(?:low|medium|high|critical)\z/ };
declare UUIDStr, as Str, where { /\A[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\z/i };
declare DateStr, as Str, where { /\A\d{4}-\d{2}-\d{2}\z/ };
declare Percentage, as Num, where { $_ >= 0 && $_ <= 100 };

1;
