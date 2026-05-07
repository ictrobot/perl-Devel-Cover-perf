package Devel::Cover::Optimizer::Walksymtable;
use strict;
use warnings;

use B ();

# Optimization 1: replace walksymtable with a filtered version.
#
# Devel::Cover's check_files() calls B::walksymtable to walk every package in
# %main::, invoking B::GV::find_cv on each glob value. find_cv then calls
# use_file() per CV. With many loaded modules this means tens of thousands of B
# method calls for CVs that will be rejected anyway.
#
# B::walksymtable is pure Perl, and Devel::Cover imports it into its own
# namespace. By replacing *Devel::Cover::walksymtable we can intercept the
# symbol table walk and skip whole package subtrees whose files don't match
# +select.
sub install {
    my (%args) = @_;
    my $debug = $args{debug} || 0;

    my %must_descend;

    # Can't use __SUB__ (requires 5.16 feature), so we name the ref.
    my $walk;
    $walk = sub {
        # $symref, $method, $recurse, $prefix match stock walksymtable's
        # signature. $ancestor_matched is ours: true when an ancestor's %INC
        # entry matched use_file, or had a non-file value we descend through
        # conservatively.
        my ($symref, $method, $recurse, $prefix, $ancestor_matched) = @_;
        no strict 'refs';
        $prefix = '' unless defined $prefix;

        # On the top-level call, rebuild the must-descend set from current %INC.
        unless (length $prefix) {
            %must_descend = ();
            for my $mod (keys %INC) {
                next unless $mod =~ /\.pm$/;
                next unless _inc_requires_descend($mod);

                (my $pkg_path = $mod) =~ s/\.pm$//;
                my @parts = split m{/}, $pkg_path;
                my $pfx = '';
                for my $part (@parts) {
                    $pfx .= "${part}::";
                    (my $pfx_mod = $pfx) =~ s/::$/.pm/;
                    $pfx_mod =~ s!::!/!g;
                    last if _inc_requires_descend($pfx_mod);
                    $must_descend{$pfx} = 1;
                }
            }

            if ($debug >= 2) {
                my $total_inc = scalar keys %INC;
                my $n = scalar keys %must_descend;
                warn "  [walk] %INC: $total_inc entries, must_descend: $n prefixes\n";
            }
        }

        for my $sym (sort keys %$symref) {
            # Accessing a stash entry vivifies the glob, matching stock
            # walksymtable.
            my $dummy = $symref->{$sym};
            my $fullname = "*main::${prefix}${sym}";

            if ($sym =~ /::$/) {
                my $pkg = $prefix . $sym;

                # Guard against self-recursion into main:: and skip the
                # synthetic "<none>::" package.
                next if B::svref_2object(\*$pkg)->NAME eq "main::";
                next if $pkg eq "<none>::";

                # $recurse is Devel::Cover's dedup callback.
                next unless $recurse->($pkg);

                (my $mod = $pkg) =~ s/::$/.pm/;
                $mod =~ s!::!/!g;
                my $self_requires_descend = _inc_requires_descend($mod);
                my $descend =
                    $self_requires_descend || $must_descend{$pkg} || $ancestor_matched;

                if ($debug >= 3) {
                    warn($descend ? "  [walk] descend $pkg\n"
                                  : "  [walk] skip subtree $pkg\n");
                }
                next unless $descend;

                $walk->(
                    \%$fullname,
                    $method,
                    $recurse,
                    $pkg,
                    $self_requires_descend || $ancestor_matched,
                );
            }
            else {
                my $gv = B::svref_2object(\*$fullname);
                my $cv = $gv->CV;
                # $$cv is the internal pointer address; 0 means no CV is attached.
                next unless $$cv;

                if ($debug >= 3) {
                    my $file = _cv_file($cv) // '?';
                    warn "  [walk] find_cv ${prefix}${sym} ($file)\n";
                }
                $gv->$method();
            }
        }
    };

    no warnings 'redefine';
    no warnings 'once';
    *Devel::Cover::walksymtable = $walk;

    return;
}

# Return true when a %INC key should make us descend into the corresponding
# package stash. We only ask Devel::Cover::use_file about values that look like
# the actual module file for that key. Some loaders and package generators leave
# refs, undef, true sentinels such as 1, or strings such as "(set by Moose)" in
# %INC; passing those into Devel::Cover::use_file can drive filename
# normalisation with bogus values, so we treat them as unknown and descend
# conservatively.
sub _inc_requires_descend {
    my ($mod) = @_;
    return 0 unless exists $INC{$mod};

    my $file = $INC{$mod};
    return 1 unless _inc_value_looks_like_module_file($mod, $file);

    return Devel::Cover::use_file($file) ? 1 : 0;
}

# Treat the %INC value as a filename only if the value contains the module key.
sub _inc_value_looks_like_module_file {
    my ($mod, $file) = @_;
    return 0 unless defined $file && !ref($file) && length($file);

    (my $path = $file) =~ s!\\!/!g;
    return $path eq $mod || $path =~ m!(?:^|/)\Q$mod\E\z!;
}

# Used only by debug logging, not on the hot path.
sub _cv_file {
    my ($cv) = @_;
    return unless ref($cv) eq "B::CV";
    my $op = $cv->START;
    return unless ref($op) eq "B::COP";
    return $op->file;
}

1;
