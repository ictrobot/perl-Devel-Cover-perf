package MyApp::Util::Date;
use strict;
use warnings;
use Exporter 'import';
use POSIX qw(strftime);

our @EXPORT_OK = qw(now_iso today days_between format_date parse_date);

sub now_iso   { strftime('%Y-%m-%dT%H:%M:%S', localtime) }
sub today     { strftime('%Y-%m-%d', localtime) }

sub days_between {
    my ($d1, $d2) = @_;
    my $t1 = _to_epoch($d1);
    my $t2 = _to_epoch($d2);
    return int(abs($t2 - $t1) / 86400);
}

sub format_date {
    my ($epoch, $fmt) = @_;
    $fmt //= '%Y-%m-%d';
    return strftime($fmt, localtime($epoch));
}

sub _to_epoch {
    my $d = shift;
    if ($d =~ /^(\d{4})-(\d{2})-(\d{2})$/) {
        require Time::Local;
        return Time::Local::timelocal(0, 0, 0, $3, $2 - 1, $1);
    }
    return time;
}

1;
