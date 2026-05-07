package Devel::Cover::Optimizer::StructureCache;
use strict;
use warnings;
no warnings 'once';

use Carp ();

# Optimization 3: avoid rereading and rewriting unchanged structure files.
#
# Devel::Cover keeps source structure under cover_db/structure, keyed by the
# source file digest. Stock read_all() eagerly reloads every structure file in
# every process, and write() rewrites every loaded structure file. Under
# forkprove that repeats the same IO in every child. This patch makes read_all()
# lazy, reads a digest only when a run asks for that file's structure, and skips
# writing a digest that already exists unless this process added structure for
# that source file.

my $INSTALLED;
my $DEBUG;
my $STATE = "__dco_structure_cache";

my $ORIG_READ;
my $ORIG_SET_SUBROUTINE;
my $ORIG_STORE_COUNTS;
my $ORIG_DELETE_FILE;
my $ORIG_WRITE;

sub install {
    my (%args) = @_;
    $DEBUG = $args{debug} || 0;

    return if $INSTALLED++;

    require Devel::Cover::DB::Structure;
    require Devel::Cover::DB::IO;

    $ORIG_READ           = \&Devel::Cover::DB::Structure::read;
    $ORIG_SET_SUBROUTINE = \&Devel::Cover::DB::Structure::set_subroutine;
    $ORIG_STORE_COUNTS   = \&Devel::Cover::DB::Structure::store_counts;
    $ORIG_DELETE_FILE    = \&Devel::Cover::DB::Structure::delete_file;
    $ORIG_WRITE          = \&Devel::Cover::DB::Structure::write;

    no warnings 'redefine';
    *Devel::Cover::DB::Structure::read_all       = \&_read_all;
    *Devel::Cover::DB::Structure::set_file       = \&_set_file;
    *Devel::Cover::DB::Structure::set_subroutine = \&_set_subroutine;
    *Devel::Cover::DB::Structure::store_counts   = \&_store_counts;
    *Devel::Cover::DB::Structure::delete_file    = \&_delete_file;
    *Devel::Cover::DB::Structure::write          = \&_write;

    _install_generated_methods();

    warn "  [structure] installed lazy structure DB handling\n" if $DEBUG >= 2;

    return;
}

# Stock Structure uses AUTOLOAD to generate get_*/add_* on first call. We
# install them eagerly so digest-based get_* and add_* methods can load existing
# structure before accessing $self->{f}, and so add_* can mark the file dirty.
sub _install_generated_methods {
    my %seen;
    my @criteria = grep !$seen{$_}++, @Devel::Cover::DB::Criteria, qw(sub_name file line);

    no strict 'refs';
    no warnings 'redefine';

    for my $criterion (@criteria) {
        my $get = "Devel::Cover::DB::Structure::get_$criterion";
        if ($criterion eq "sub_name" || $criterion eq "file" || $criterion eq "line") {
            *$get = sub { shift->{$criterion} };
        } else {
            my $field = $criterion eq "time" ? "statement" : $criterion;
            *$get = sub {
                my ($self, $digest) = @_;
                _load_digest($self, $digest);

                for my $fval (values %{ $self->{f} || {} }) {
                    next unless defined $fval->{digest};
                    return $fval->{$field} if defined $digest && $fval->{digest} eq $digest;
                }

                return;
            };
        }

        my $add = "Devel::Cover::DB::Structure::add_$criterion";
        *$add = sub {
            my $self = shift;
            my $file = shift;

            _load_file($self, $file);
            push @{ $self->{f}{$file}{$criterion} }, @_;
            _mark_dirty($self, $file);

            return;
        };
    }

    return;
}

# Stock read_all eagerly deserializes every structure file. This just verifies
# the directory exists and enables lazy mode; individual digests are loaded on
# demand by _load_file and _load_digest.
sub _read_all {
    my ($self) = @_;

    my $dir = "$self->{base}/structure";
    opendir my $dh, $dir or return;
    closedir $dh or die "Can't closedir $dir: $!";

    my $state = _state($self);
    $state->{lazy} = 1;

    return $self;
}

# Reimplemented rather than wrapped: stock set_file computes the digest, but
# the lazy path also needs the digest to load existing structure first.
# Wrapping would read the source file twice.
sub _set_file {
    my ($self, $file) = @_;

    $self->{file} = $file;
    my $digest = $self->digest($file);

    my $state = _active_state($self);
    if ($digest) {
        _load_digest($self, $digest);
        $self->{f}{$file}{digest} = $digest;
        push @{ $self->{digests}{$digest} }, $file;
    }
    $state->{loaded_file}{$file} = 1 if $state && defined $file;

    return $digest;
}

# Stock set_subroutine has three paths: reuse with existing entry (nothing
# new), reuse with additional entry (new structure), and first-time (new
# structure). Mark dirty only when structure was actually created.
sub _set_subroutine {
    my ($self, $sub_name, $file, $line, $scount) = @_;

    _load_file($self, $file);
    my $had_reuse = _has_cover_start($self, $file);
    my $had_entry = _has_subroutine_start($self, $file, $line, $sub_name, $scount);

    my $ret = $ORIG_SET_SUBROUTINE->(@_);
    _mark_dirty($self, $file) unless $had_reuse && $had_entry;

    return $ret;
}

# Stock store_counts writes the current per-criteria count indexes into
# __COVER__[0]. Those values can move backwards when a later process does not
# recreate generated structure seen by an earlier one, so compare values rather
# than just checking whether the keys already exist.
sub _store_counts {
    my ($self, $file) = @_;

    _load_file($self, $file);
    my $cover_start = _cover_start($self, $file);
    my (%before, %had_before);
    if ($cover_start) {
        for my $criterion ($self->criteria) {
            $had_before{$criterion} = exists $cover_start->{$criterion};
            $before{$criterion} = $cover_start->{$criterion};
        }
    }

    my $ret = $ORIG_STORE_COUNTS->(@_);
    $cover_start = _cover_start($self, $file);
    for my $criterion ($self->criteria) {
        my $has_after = $cover_start && exists $cover_start->{$criterion};
        if (!$had_before{$criterion} || !$has_after || !_same_value($before{$criterion}, $cover_start->{$criterion})) {
            _mark_dirty($self, $file);
            last;
        }
    }

    return $ret;
}

sub _delete_file {
    my ($self, $file) = @_;

    my $ret = $ORIG_DELETE_FILE->(@_);
    if (my $state = $self->{$STATE}) {
        delete $state->{dirty}{$file};
        delete $state->{loaded_file}{$file};
    }

    return $ret;
}

sub _write {
    my ($self, $dir) = @_;

    my $state = _active_state($self);
    return $ORIG_WRITE->(@_) unless $state;

    $dir .= "/structure";
    unless (mkdir $dir) {
        Carp::confess("Can't mkdir $dir: $!") unless -d $dir;
    }
    chmod 0777, $dir if $self->{loose_perms};

    my ($written, $failed, $skipped, $dirty, $missing, $no_digest) = (0, 0, 0, 0, 0, 0);
    for my $file (sort keys %{ $self->{f} || {} }) {
        $self->{f}{$file}{file} = $file;
        my $digest = $self->{f}{$file}{digest};
        $digest = $1 if defined $digest && $digest =~ /(.*)/; # ie tainting
        unless ($digest) {
            $no_digest++;
            warn "  [structure] no_digest: file=$file\n" if $DEBUG >= 3;
            print STDERR "Can't find digest for $file"
                unless $Devel::Cover::Silent
                    || $file =~ $Devel::Cover::DB::Ignore_filenames
                    || ($Devel::Cover::Self_cover && $file =~ q|/Devel/Cover[./]|);
            next;
        }

        my $df_final = "$dir/$digest";
        my $df_temp  = "$dir/.$digest.$$";
        # Skip clean files whose digest already exists on disk. Dirty files
        # are always written because this process may have appended structure.
        my $is_dirty = $state->{dirty}{$file};
        if (!$is_dirty && -e $df_final) {
            $skipped++;
            next;
        }
        $dirty++ if $is_dirty;
        $missing++ unless -e $df_final;
        if ($DEBUG >= 3 && $is_dirty) {
            warn "  [structure] write dirty: file=$file digest=$digest existing=" . (-e $df_final ? 1 : 0) . "\n";
        }

        my $io = Devel::Cover::DB::IO->new;
        $io->write($self->{f}{$file}, $df_temp);
        unless (rename $df_temp, $df_final) {
            unless ($Devel::Cover::Silent) {
                if (-e $df_final) {
                    print STDERR "Can't rename $df_temp to $df_final (which exists): $!";
                    $self->debuglog("Can't rename $df_temp to $df_final (which exists): $!")
                        if Devel::Cover::DB::Structure::DEBUG();
                } else {
                    print STDERR "Can't rename $df_temp to $df_final: $!";
                    $self->debuglog("Can't rename $df_temp to $df_final: $!")
                        if Devel::Cover::DB::Structure::DEBUG();
                }
            }
            unless (unlink $df_temp) {
                print STDERR "Can't remove $df_temp after failed rename: $!" unless $Devel::Cover::Silent;
                $self->debuglog("Can't remove $df_temp after failed rename: $!")
                    if Devel::Cover::DB::Structure::DEBUG();
            }
            $failed++;
            next;
        }
        $written++;
    }

    warn sprintf(
        "  [structure] write: written=%d failed=%d skipped=%d dirty=%d missing=%d no_digest=%d\n",
        $written,
        $failed,
        $skipped,
        $dirty,
        $missing,
        $no_digest,
    ) if $DEBUG;

    return;
}

sub _state {
    my ($self) = @_;

    return $self->{$STATE} ||= {
        lazy          => 0,
        dirty         => {},
        loaded_file   => {},
        loaded_digest => {},
    };
}

# Returns undef when lazy mode is not enabled, disabling the lazy-specific work.
# In that case wrappers either delegate to stock or run stock-equivalent logic.
# This happens when read_all was never called or the structure directory does
# not exist.
sub _active_state {
    my ($self) = @_;

    my $state = $self->{$STATE};
    return $state && $state->{lazy} ? $state : undef;
}

sub _load_file {
    my ($self, $file) = @_;

    my $state = _active_state($self) or return;
    return unless defined $file;
    return if $state->{loaded_file}{$file};

    if (my $digest = $self->digest($file)) {
        _load_digest($self, $digest);
    }
    $state->{loaded_file}{$file} = 1;

    return;
}

sub _load_digest {
    my ($self, $digest) = @_;

    my $state = _active_state($self) or return;
    return unless defined $digest && length $digest;
    return if $state->{loaded_digest}{$digest}++;

    my $path = "$self->{base}/structure/$digest";
    return unless -e $path;

    warn "  [structure] load digest: digest=$digest path=$path\n" if $DEBUG >= 3;
    $ORIG_READ->($self, $digest);

    # read() gives us the source filename from the stored structure, which may
    # differ textually from the current caller's path. Mark any matching file as
    # loaded so later operations do not repeat the same digest read.
    for my $file (keys %{ $self->{f} || {} }) {
        next unless defined $self->{f}{$file}{digest};
        $state->{loaded_file}{$file} = 1 if $self->{f}{$file}{digest} eq $digest;
    }

    return;
}

sub _mark_dirty {
    my ($self, $file) = @_;

    my $state = _active_state($self) or return;
    $state->{dirty}{$file} = 1 if defined $file;

    return;
}

# Probe stock structure layout: $self->{f}{$file}{start}{-1}{__COVER__}[0]
# holds per-criteria counts set by store_counts and checked by reuse().
sub _cover_start {
    my ($self, $file) = @_;

    return unless defined $file && exists $self->{f} && exists $self->{f}{$file};
    my $start = $self->{f}{$file}{start};
    return unless ref($start) eq "HASH";
    my $line = $start->{-1};
    return unless ref($line) eq "HASH";
    my $cover = $line->{__COVER__};
    return unless ref($cover) eq "ARRAY";

    return $cover->[0];
}

sub _has_cover_start {
    my ($self, $file) = @_;

    return defined _cover_start($self, $file);
}

# Probe stock structure layout: $self->{f}{$file}{start}{$line}{$sub_name}[$scount]
# holds per-criteria counts for a specific subroutine instance.
sub _has_subroutine_start {
    my ($self, $file, $line, $sub_name, $scount) = @_;

    return unless defined $file && exists $self->{f} && exists $self->{f}{$file};
    my $start = $self->{f}{$file}{start};
    return unless ref($start) eq "HASH";
    my $by_line = $start->{$line};
    return unless ref($by_line) eq "HASH";
    my $by_name = $by_line->{$sub_name};
    return unless ref($by_name) eq "ARRAY";

    return exists $by_name->[$scount];
}

sub _same_value {
    my ($left, $right) = @_;

    return 1 if !defined($left) && !defined($right);
    return 0 if !defined($left) || !defined($right);
    return $left eq $right;
}

1;
