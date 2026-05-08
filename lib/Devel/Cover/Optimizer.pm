package Devel::Cover::Optimizer;
use strict;
use warnings;

# Monkey-patches Devel::Cover to reduce END-block overhead when many
# third-party modules are loaded.
#
# Usage:
#   perl -MDevel::Cover=... -MDevel::Cover::Optimizer ...
#   perl -MDevel::Cover=... -MDevel::Cover::Optimizer=debug ...
#   perl -MDevel::Cover=... -MDevel::Cover::Optimizer=cache,debug2 ...
#
# Options:
#   no_walksymtable        - disable optimization 1 (walksymtable replacement)
#   no_structure_cache     - disable optimization 3 (lazy structure DB handling)
#   cache                  - pre-cache deparse walks for preloaded CVs
#   no_filtered_get_cover  - with cache, disable ignored-file get_cover replay
#   debug                  - log summary diagnostics to STDERR
#   debug2                 - log cache/walk phases and aggregate detail
#   debug3                 - log verbose per-package and per-CV detail

sub import {
    my ($class, @args) = @_;

    my %known_opts = map { $_ => 1 } qw(
        cache
        no_filtered_get_cover
        no_structure_cache
        no_walksymtable
    );
    my %opts;
    my $debug = 0;
    for my $arg (@args) {
        # debug2/debug3 work cleanly via -MDevel::Cover::Optimizer=cache,debug2.
        # debug=N is also accepted for callers that invoke import directly.
        if ($arg =~ /\Adebug(?:=(\d+))?\z/) {
            $debug = defined $1 ? $1 : 1;
        } elsif ($arg =~ /\Adebug([0-9]\d*)\z/) {
            $debug = $1;
        } else {
            $opts{$arg} = 1;
        }
    }

    my @unknown = sort grep !$known_opts{$_}, keys %opts;
    if (@unknown) {
        die "Devel::Cover::Optimizer: unknown option"
            . (@unknown == 1 ? "" : "s")
            . ": " . join(", ", @unknown) . "\n";
    }

    my $no_walksymtable = delete $opts{no_walksymtable};
    my $no_structure_cache = delete $opts{no_structure_cache};
    my $cache_mode = delete $opts{cache};
    my $no_filtered_get_cover = delete $opts{no_filtered_get_cover};

    die "Devel::Cover::Optimizer: no_filtered_get_cover requires cache\n"
        if $no_filtered_get_cover && !$cache_mode;

    unless (defined $Devel::Cover::VERSION) {
        die "Devel::Cover::Optimizer: Devel::Cover is not loaded\n";
    }

    if ($debug) {
        no warnings 'once';
        my @option_text = (
            $cache_mode ? "cache" : (),
            $no_filtered_get_cover ? "no_filtered_get_cover" : (),
            $no_structure_cache ? "no_structure_cache" : (),
            $no_walksymtable ? "no_walksymtable" : (),
        );
        my $option_text = @option_text ? join(",", @option_text) : "default";
        warn "Devel::Cover::Optimizer: debug level $debug enabled"
            . " (options $option_text"
            . "; Perl $]"
            . ", Devel::Cover $Devel::Cover::VERSION"
            . ($B::Deparse::VERSION ? ", B::Deparse $B::Deparse::VERSION" : "")
            . ")\n";
    }

    unless ($no_walksymtable) {
        require Devel::Cover::Optimizer::Walksymtable;
        Devel::Cover::Optimizer::Walksymtable::install(debug => $debug);
    }

    unless ($no_structure_cache) {
        require Devel::Cover::Optimizer::StructureCache;
        Devel::Cover::Optimizer::StructureCache::install(debug => $debug);
    }

    if ($cache_mode) {
        require Devel::Cover::Optimizer::DeparseCache;
        Devel::Cover::Optimizer::DeparseCache::install(
            debug => $debug,
            filtered_get_cover => !$no_filtered_get_cover,
        );
    }

    return;
}

1;
