# Devel::Cover::Optimizer — Injectable Optimizations

## Overview

`Devel::Cover::Optimizer` is a monkey-patch module that reduces Devel::Cover's
END-block overhead when many third-party modules are loaded. The overhead
scales with the number of loaded modules, not just covered files — it
affects any Devel::Cover run, but is worst under forkprove where every
forked child inherits the full preloaded symbol table. It requires no
changes to Devel::Cover's source code.

Once `Devel::Cover::Optimizer` is installed or otherwise available on `@INC`,
load it alongside Devel::Cover:

```bash
PERL5OPT='-MDevel::Cover=+select,^lib,+ignore,^ -MDevel::Cover::Optimizer' \
  prove -lr t/
```

For `forkprove` with an application preload, put the optimizer on the
`forkprove` command line after the preload:

```bash
PERL5OPT='-MDevel::Cover=+select,^lib,+ignore,^' \
  forkprove -lr -MMyApp::Web -MDevel::Cover::Optimizer t/
```

In this repository, the optimizer module lives in the top-level `lib/`
directory and the benchmark application lives under `example/`. The explicit
benchmark invocation is:

```bash
cd example
PERL5OPT="-I$(pwd)/../lib -MDevel::Cover=+select,^lib,+ignore,^" \
  forkprove -lr -I. -MMyApp::Web -MDevel::Cover::Optimizer t/
```

From the repository root, the local wrapper script is equivalent for the
default optimizer mode:

```bash
./example/run-tests -fco
```

### Options

- `no_walksymtable` — disable optimization 1 (walksymtable replacement)
- `no_structure_cache` — disable optimization 3 (lazy structure DB handling)
- `cache` — enable optimization 2 (deparse cache, requires PadWalker)
- `debug`, `debug2`, `debug3` — log optimizer diagnostics to STDERR

## Benchmark Results (132 libs, 116 tests)

Timings below are from sequential runs in the `dco-test/alma8:dc-1.52`
container using Devel::Cover's default report criteria for this repository:
statement, branch, condition, and subroutine.

### Baselines (no coverage)

| Runner       | Time  |
|--------------|-------|
| `prove`      | 8.33s |
| `forkprove`  | 5.57s |

### Default mode

| Configuration              | `prove`    | `forkprove` |
|----------------------------|------------|-------------|
| stock (no Optimizer)          | 24.59s     | 33.61s      |
| **Devel::Cover::Optimizer**   | **20.28s** | **24.75s**  |

**-18%** with `prove` and **-26%** with `forkprove` vs stock.

### With `cache` (requires PadWalker)

| Configuration              | `prove`    | `forkprove` |
|----------------------------|------------|-------------|
| stock (no Optimizer)          | 24.59s     | 33.61s      |
| Optimizer (no cache)          | 20.28s     | 24.75s      |
| Optimizer + cache             | 24.82s     | **15.83s**  |

The cache is intended for `forkprove`. Under plain `prove`, each test process
starts fresh and there is no preloaded parent state to reuse, so cache-building
overhead makes the run slower. Under `forkprove` it eliminates ~9s of redundant
`B::Deparse` work inherited from the preloaded parent — a **-53%** reduction
vs stock and **-36%** vs Optimizer without cache.

## Optimization 1: Replace walksymtable with filtered version

**Target:** `check_files` → `walksymtable` → `B::GV::find_cv` (74% of
END-block overhead)

Stock `find_cv` calls `check_file` (→ `use_file`) for every CV in every GV
walked by `walksymtable`. With many loaded modules, this means tens of
thousands of B:: method calls + regex matches against `@Select_re`/`@Ignore_re`.

`B::walksymtable` is pure Perl. By replacing the copy imported into
`Devel::Cover`'s namespace, we can **skip entire package subtrees**: for
each `Foo::Bar::` package, check `$INC{"Foo/Bar.pm"}` against `use_file`.
If the module was loaded from outside the selected paths, skip the entire
subtree and all its symbols. This avoids iterating ~1,200 non-matching
packages.

Within descended packages, `find_cv` is called for every GV with a CV —
individual CVs are **not** filtered by file. This is necessary because stock
`find_cv` independently inspects both the outer CV and its PADLIST for inner
anonymous CVs, which can be from different files (e.g. via `#line`
directives). Filtering by the outer CV's file would miss selected inner CVs.

This is the highest-impact optimization because it reduces the package
iteration count, not just the per-iteration cost.

Three signals trigger descent into a package:

1. **Self-matched:** the package's own `.pm` file (via `%INC`) matches
   `use_file`. E.g. `MyApp::Config::` descends because
   `$INC{"MyApp/Config.pm"}` points to `lib/MyApp/Config.pm`.

2. **`%must_descend`:** a selected file is nested under this package. Built
   by scanning `%INC` for selected files and recording ancestor prefixes up
   to (but not including) the first self-matching ancestor. So with
   `+select,^lib/MyApp/Service,+ignore,^`, `MyApp::` is in `%must_descend`
   (needed to reach `MyApp::Service::`) but `MyApp::Service::Foo::` is not
   (covered by ancestor propagation from `MyApp::Service::`).

3. **`$ancestor_matched`:** an ancestor package's own `.pm` matched,
   propagated through recursion. Handles inline sub-packages (e.g.
   `MyApp::Config::Defaults::` defined inside `lib/MyApp/Config.pm`) and
   packages without `%INC` entries that live under a selected namespace.

With `+select,^lib,+ignore,^`, `MyApp::` self-matches (its own
`lib/MyApp.pm` matches), so `$ancestor_matched` propagates to all
sub-packages and `%must_descend` only needs entries for non-MyApp ancestors.

### Note: Devel::Cover calls `walksymtable` during CHECK

Devel::Cover calls `check_files()` → `walksymtable` during Perl's CHECK
phase, not just in the END block. At CHECK time,
very few modules are loaded — preloaded modules (`-MMyApp::Web`) haven't
been loaded yet, and `%INC` has only ~90 entries.

The walker rebuilds its `%must_descend` set on each top-level invocation to
ensure it uses the current `%INC` state. The CHECK-phase call sees minimal
`%INC`; the END-block call sees the full set.

### Limitation: %INC-to-package mapping is a heuristic

Subtree pruning decides whether to enter a package stash by predicting its
contents from `%INC` keys. This assumes conventional module layouts where the
`%INC` key (`Foo/Bar.pm`) maps to the package name (`Foo::Bar`). It can miss
selected CVs when this assumption doesn't hold:

- A selected file defines packages that don't match its `%INC` key (e.g.
  `lib/Plugin.pm` defines `MyApp::Service::Foo` — the walker records
  `Plugin::` as must-descend, not `MyApp::`)
- A single selected file defines packages in unrelated namespaces
- `eval`/source filters use `#line` to point CVs at selected files without
  corresponding `%INC` entries
- Runtime symbol table manipulation installs selected subs into namespaces
  not derivable from `%INC`
- A loader or package generator leaves a non-file value in `%INC` (for example
  a reference, a true sentinel such as `1`, or Moose's `(set by Moose)`
  sentinel). Those packages are descended conservatively, because
  Devel::Cover's filename normalisation expects a real filename. This also
  avoids undefined-value warnings in Devel::Cover 1.49 and older; Devel::Cover
  1.50 added its own guard for false filenames in `use_file`.

For conventional module layouts and broad exclusive selects like
`+select,^lib,+ignore,^`, this works correctly. Use `no_walksymtable` if you
encounter missing coverage with unusual module layouts.

## Optimization 2: Pre-cache deparse walks (`cache`, opt-in)

**Target:** `get_cover` → `B::Deparse::deparse_sub` per CV (redundant
B:: op tree walks in forked children)

Under forkprove, every forked child inherits the same preloaded CVs with
identical op trees. Stock Devel::Cover runs `B::Deparse->new` +
`deparse_sub` on each CV in every child, walking the same op tree to
discover statements, branches, and conditions. Only the runtime coverage
counts (`$Coverage`) differ between children — the *structure* of
`add_statement_cover`, `add_branch_cover`, and `add_condition_cover` calls
is identical.

This optimization runs the deparse walk once in the parent process (after
preload, before forking) and records the sequence of `add_*_cover` calls
for each CV. In forked children, `B::Deparse::deparse_sub` is wrapped: if
a CV's address matches the cache (validated by checking that `START` and
`ROOT` op addresses haven't changed), the cached call sequence is replayed
instead of re-walking the op tree. The replayed calls read per-child
`$Coverage` at call time, so each child gets correct counts.

The same parent pass also records a cheaper cache entry for CVs where stock
`get_cover()` established an initial location and then returned from its own
`use_file()` check before deparse, subroutine, POD, or `%Seen` side effects. In
children, a small `get_cover()` wrapper can replay just the leaked `$Sub_name`,
`$File`, and `$Line` state for those observed early returns.

Under forkprove, `Devel::Cover::Optimizer` should be on the forkprove
command line (not in `PERL5OPT`) so it loads after the app preload:

```bash
PERL5OPT='-MDevel::Cover=+select,^lib,+ignore,^' \
  forkprove -lr -MMyApp::Web -MDevel::Cover::Optimizer=cache t/
```

For this repository's benchmark app, run the explicit command from
`example/` and add the top-level optimizer `lib/` to `PERL5OPT`:

```bash
cd example
PERL5OPT="-I$(pwd)/../lib -MDevel::Cover=+select,^lib,+ignore,^" \
  forkprove -lr -I. -MMyApp::Web -MDevel::Cover::Optimizer=cache t/
```

From the repository root, the local wrapper script is equivalent for the
benchmark:

```bash
./example/run-tests -fc -o cache
```

### Loading phase awareness

Cache building must happen after Devel::Cover's CHECK phase, which expands
`%Coverage` from `(all => 1)` to per-type flags (`statement => 1`,
`branch => 1`, etc.). The deparse walker gates statement, branch, and
condition discovery on these flags — building the cache before expansion
produces a call stream recorded under wrong gating conditions.

The module detects which phase it was loaded in via `${^GLOBAL_PHASE}`:

- **Runtime** (`${^GLOBAL_PHASE} eq 'RUN'`): loaded after INIT, typically
  via forkprove's `-M` flags. `%Coverage` is already expanded. The cache
  is built immediately during `import()`.

- **Compile time** (any other phase): loaded via `PERL5OPT` or `use`
  before CHECK has run. Cache building is deferred to an `INIT` block,
  which runs after all CHECK blocks (FIFO order).

A guard in `_install_deparse_cache` dies if `%Coverage` still contains
`all`, catching any case where the deferral logic fails.

### State management

Cache building uses `PadWalker::closed_over` to access Devel::Cover's
lexical variables from several closures:

| Variable       | Source closure           | Purpose                              |
|----------------|-------------------------|--------------------------------------|
| `$Structure`   | `add_statement_cover`   | Coverage DB schema object            |
| `$Coverage`    | `_report`               | Runtime execution counts             |
| `%Run`         | `add_statement_cover`   | Per-file coverage data and config    |
| `$Sub_count`   | `get_cover`             | Subroutine dedup counter             |
| `%Seen`        | `deparse`               | Duplicate op suppression             |
| `%Coverage`    | `add_statement_cover`   | Coverage type flags (guard only)     |
| `@Cvs`         | `_report`               | Named CVs from `check_files`         |
| `$Subs_only`   | `_report`               | Skip main/block CVs if set           |

A temporary `Devel::Cover::DB::Structure` is set up for the cache-building
pass, then all original state is restored. If the cache build fails, the
cache is cleared and the error is propagated — Devel::Cover continues to
function normally since its state has been restored.

### Replay correctness

Each deparse cache entry stores four things: the recorded `add_*_cover` call
sequence, `START`/`ROOT` op addresses for validation, the `%Seen`
assumptions and mutations from that CV's deparse walk, and the final
`$File`/`$Line` state left by `get_cover()`.

**`$File`/`$Line` globals:** Several `add_*_cover` functions read the
package globals `$Devel::Cover::File` and `$Devel::Cover::Line` in
addition to (or instead of) their explicit arguments. For example,
`add_branch_cover` takes `$file`/`$line` args but uses the global `$File`
for the branch vec; `add_condition_cover` reads both entirely from globals.
The cache captures `$File` and `$Line` at each call site during recording
and restores them (via `local`) before each replayed call. The cache only stores
entries where the initial `get_cover()` call established location state via
`get_location($start)`. The implementation observes the real stock call rather
than predicting from `$cv->START`, and only marks the entry location-safe after
the first `get_location()` call for the CV is the direct
`Devel::Cover::get_cover` call and it has left a non-empty normalized `$File`.
That preserves Devel::Cover's eval and `#line` filename handling while tying
the predicate to call order, not just caller identity.
This relies on stock `get_cover()` making `get_location($start)` its only direct
`get_location()` call, and doing so before `deparse_sub()`.

The predicate is deliberately about the initial `get_cover()` location call, not
any later `get_location()` call during deparse. Later statement locations can be
inside localized deparse scopes, and branch/condition hooks may already have
captured inherited stale `$File`/`$Line` before a later statement establishes a
real location. Locationless CVs can depend on whatever `$File`/`$Line` the child
report has inherited at that point, so they are left uncached rather than
replaying the parent's inherited cache-build state. For cached entries, replay
restores the final `$File`/`$Line` state left by stock `get_cover()`, because
later locationless CVs can depend on Devel::Cover's leaked last location state.

**`%Seen` replay:** `%Seen` suppresses duplicate statement, branch, condition,
and "other" discoveries across the entire report pass. It is lexical to
Devel::Cover's deparse closure, and it persists across CVs rather than being
reset per CV. During replay, cached CVs bypass the deparse walker, so `%Seen`
would not be populated for their ops unless the cache replays those effects too.
If a later uncached CV's deparse walk encounters ops that stock Devel::Cover
would have suppressed, it can otherwise produce extra coverage entries.

The cache builder walks CVs in stock `_report` order with `%Seen` accumulating
persistently: main, BEGIN, CHECK, END/INIT, then `@Cvs`. During each
`get_cover()` pass, it ties the known inner `%Seen` buckets (`statement`,
`other`, `branch`, `condition`) and records three sets:

```perl
seen_requires_zero    # keys read as false
seen_requires_nonzero # keys read as true, excluding true values set by this CV
seen_sets_true        # keys changed from false to true
```

The inner key is the op address Devel::Cover uses (`$$op`). This bucket/key
model was checked against Devel::Cover 1.33 through 1.52: `%Seen` is lexical,
the bucket names are stable, report order is stable, relevant accesses use
`$Seen{...}{$$op}`, and Devel::Cover uses the values as truth state rather than
meaningful numeric counters. Devel::Cover 1.49-1.52 add another `condition`
write path for newer xor handling, but the implementation tracks the hash
itself rather than assuming a particular B::Deparse hook.

After the build pass, keys touched by exactly one report occurrence are treated
as private to that occurrence; keys touched by more than one occurrence are
shared. During replay:

1. `START` and `ROOT` op addresses validate that the CV has not been replaced.
2. Entries already replayed, or invalidated by an uncached walk, miss.
3. Shared `seen_requires_zero` keys are checked; any true value means miss.
4. All `seen_requires_nonzero` keys are checked; any false value means miss.
5. Recorded `add_*_cover` calls are replayed.
6. Shared and private `seen_sets_true` keys are written directly to backing
   `%Seen` hashrefs.
7. The final `$Devel::Cover::File` and `$Devel::Cover::Line` state is restored.

Private required-zero keys are not scanned on every hit. If no uncached deparse
walk writes one before its owner replays, no other cached entry can observe it
first. If an uncached miss writes one first, the miss temporarily ties the known
inner `%Seen` buckets, records false-to-true writes, and invalidates only the
future cached entry that privately owned that key. This keeps cache-hit replay
on plain hashrefs instead of paying tied-hash dispatch for every cached write.

`seen_sets_true` alone is not enough. A read-as-zero can affect whether a later
add call is produced, even if the CV eventually writes a different key; some
Devel::Cover paths check `statement` and `other` together. A read-as-nonzero
matters too: if the parent skipped an add call because a key was already true,
replaying that skip is wrong when the child key is false. A false-to-true write
usually implies a zero requirement for the same key, so both are recorded and
then reduced by the private/shared split.

CVs that produce no `add_*_cover` calls but do change `%Seen` from false to true
are still cached with an empty call list, because their duplicate-suppression
state can affect later uncached walks. CVs with no calls and no `%Seen` effects
are omitted, unless stock `get_cover()` reached its own ignored-file early
return.

**Filtered `get_cover()` replay:** A filtered entry is recorded only after the
parent has run stock `get_cover()` in normal report order and observed all of
the following: the initial `get_location($start)` established location state,
the final file is rejected by `use_file()`, no `add_*_cover` calls were made,
no `%Seen` writes happened, and the rejection came from `use_file()`'s
configured rejecting filters (`ignore` or `@INC`), with select precedence
preserved, not from any fallback or special-case path. That means `get_cover()`
returned before the subroutine, POD, and deparse work that would affect
coverage structure.

In children, `Devel::Cover::get_cover` is wrapped for one-argument CV calls. If
the CV address has a filtered entry and `START`/`ROOT` still match, replay sets
only `$Sub_name`, `$File`, and `$Line`, then returns. It does not write
structure, counts, POD, or `%Seen`. It also deliberately skips the empty
`$Run{vec}` slots that stock `get_location()` would have created before
`use_file()` rejected the file: under static select/ignore options those entries
are removed as ignored files at the end of `_report`, and they carry no counts
or structure. If the CV is stale or not in the filtered cache, stock
`get_cover()` runs. This is deliberately not a CV-list pre-filter: cache
construction still lets stock Devel::Cover make the selection decision and
record the state it leaked. Files rejected only by `use_file()`'s fallback path
or other internal special cases are left uncached.

In the example workload the split is heavily skewed toward private keys. A
debug run showed about 9.5k private required-zero keys versus 6 shared
required-zero keys, and about 4.8k private writes versus 4 shared writes. The
expected cost is a slower parent cache build and a small cache-hit validation
overhead; this is acceptable because forkprove builds the cache once but pays
child replay cost many times.

Rejected `%Seen` variants:

- Full preflight: check every recorded `seen_requires_zero`,
  `seen_requires_nonzero`, and `seen_sets_true` key before each hit. This was
  straightforward but repeated too much work on the child hot path.
- Child-tied validation state: keep `%Seen` tied throughout the child and
  update per-entry validity as keys become true. This made hit validation
  cheaper in theory, but pushed tied-hash overhead and watcher fanout into the
  child path and reduced cache hit rate in the initial experiment.
- Same-order dirty fast path: skip validation while the child is replaying the
  same clean prefix as the parent. This is attractive, but easy to get subtly
  wrong once uncached misses appear between cached entries.

### CI coverage comparison

The harness writes two coverage artifacts with different purposes:

- `summary.txt` is generated from the requested percentage criteria which are
  safe to compare across runners: statement, branch, condition, subroutine, and
  POD when requested. It deliberately uses the summary report, which excludes
  raw execution counts, so it is compared to the stock `prove` baseline for
  every runner mode, including `forkprove`.
- `detailed.txt` is generated from the full requested criterion list and
  includes raw counts. When `pod` is requested it also includes POD coverage.
  This output is compared within the matching runner family: `opt` against
  `baseline`, and `fork-opt` / `fork-opt-cache` against `fork`.

The family split is necessary because forkprove preloads application modules in
the parent. Devel::Cover counters from that preload are inherited by each child,
so detailed raw counts for preload-time code are expected to differ from a
plain `prove` run. If POD coverage is requested, stock `forkprove` can also
produce different POD entries from the same tests under `prove`, as described
in `REPORT.md`, unless the library path remains in process-global `@INC`.
These checks use that `@INC` setup for all modes, so POD percentages in
`summary.txt` are compared to the `prove` baseline, while detailed output is
still compared against the corresponding stock runner rather than against a
runner with different fork/preload counter semantics.

### CV sources and walk order

CVs are walked in the same order as stock `_report` (unless `$Subs_only`
is set, which skips the first four groups):

1. `main_cv` + `main_root` — seeds `%Seen` but is not cached (not keyed
   by CV address)
2. `B::begin_av` — BEGIN blocks
3. `B::check_av` — CHECK blocks
4. `Devel::Cover::get_ends` — END/INIT blocks
5. `@Cvs` — named CVs discovered by `check_files`

`check_files()` is called at the start of cache building to populate `@Cvs`
with currently-loaded CVs from selected packages. This uses stock
Devel::Cover discovery (including the patched `walksymtable` from
optimization 1) rather than custom `%INC`/stash scanning, ensuring the CV
list and sort order match what `_report` will see.

Under `prove` (no preload), this has minimal effect — children start fresh
and the cache is empty. Under `forkprove` with preloaded modules, the
savings are substantial: the deparse walk is the dominant remaining cost
after optimization 1, and this eliminates it for all cached CVs.

The filtered `get_cover()` replay is a smaller win on the example app. Local
A/B runs against the previous committed cache implementation measured about
3-5% faster in both run orders (`19.23s` -> `18.67s`, and `19.49s` -> `18.59s`
in reverse order). A shorter post-guard sample measured `18.80s` -> `17.90s`.
A debug run saw about 4,000 filtered early-return hits per child and no stale
filtered hits.

### Why opt-in

This is opt-in (`cache` flag) primarily because it only helps under
forkprove (no effect under `prove`), and because the implementation makes
additional assumptions beyond the other optimizations: it uses
`PadWalker::closed_over` to reach into Devel::Cover's lexical state, sets
up a temporary `Structure` object to run the cache-building deparse pass,
and replays recorded call sequences rather than re-discovering them from
the op tree. These assumptions are validated (op addresses are checked,
`%Coverage` is guarded, state is saved/restored), but they couple more
tightly to Devel::Cover's internals than optimization 1.

## Optimization 3: Lazy structure DB reads and clean write skips

**Target:** `Devel::Cover::DB::Structure->read_all` and `->write`

Devel::Cover stores source structure in `cover_db/structure`, keyed by source
file digest. Stock `read_all()` eagerly deserializes every known structure file
into every reporting process. Later, `write()` serializes every structure entry
that was loaded into memory, even if the process only reused existing structure
and the digest file already exists on disk.

This is particularly wasteful under forkprove: each child starts with the same
source tree and usually needs only a small subset of the existing structure
database, then many children rewrite identical digest files.

The optimizer replaces `read_all()` with a lazy marker. Before operations that
need existing structure for a source file, it computes that source file's digest
and reads only `cover_db/structure/$digest` if it exists:

- `set_file`
- `set_subroutine`
- `store_counts`
- generated `get_*` structure lookups by digest
- generated `add_*` structure mutations

`set_file` is implemented directly rather than wrapping the stock method,
because the stock method also computes the digest. The lazy path needs the
digest to decide whether to read existing structure, so calling the stock method
afterward would read the source file twice.

Write skipping is intentionally conservative. It cannot simply skip every digest
file that already exists, because a process can discover extra structure for an
existing source digest, such as conditional `eval`, generated methods, or
additional subroutine instances for the same file. In that case the digest file
exists but the in-memory structure has genuinely changed.

The current implementation tracks dirty source files instead:

- generated `add_*` methods mark the file dirty, because they append structure;
- `set_subroutine` marks dirty only when it is creating a new structure entry,
  not when it reuses an existing `(file, line, sub_name, count)` entry;
- `store_counts` marks dirty only when the `__COVER__` start entry is missing
  or its active per-criterion count indexes change;
- `delete_file` keeps stock deletion semantics for the in-memory structure.

During `write()`, an existing digest file is skipped only when the source file
is clean. Dirty files, missing digest files, and files without a usable digest
fall back to stock-style behavior.

The implementation also tracks loaded digests as well as source filenames,
avoiding repeated reads when the same digest is reached through different
paths. Generated `get_*` methods are patched too, so lazy `read_all()` also
works for report-time structure lookup by digest if the optimizer is loaded
there.

Focused local A/B benchmarks against the committed `no_structure_cache` escape
hatch showed plain `prove` improving by about 7%, forkprove without the deparse
cache staying effectively neutral, and the intended forkprove + deparse-cache
path improving by about 7%. In that last case, system time dropped from
`4.427s` to `3.521s` in this example.

## Discarded approaches

### Pre-filter CV lists in `get_cover_progress`

Wrapped `get_cover_progress` to skip ignored CVs before `get_cover` runs.
The fast path used `$cv->START->file` for B::COP CVs and
`Devel::Cover::sub_info` for the rest.

The only expensive thing `get_cover` does for ignored CVs is
`B::Deparse->new` (~1μs) and `sub_info` (cheap op tree walk) — it already
returns before `deparse_sub` thanks to its own `use_file` check. So the
pre-filter saves microseconds per CV. At the same time, stock `get_cover`
relies on `$File`/`$Line` state accumulated across iterations: it calls
`get_location` on each CV's start op, and CVs without a discoverable
location inherit stale `$File` from the previous iteration. Removing ignored
CVs from the iteration changes what stale `$File` a locationless CV sees,
causing it to be accepted and misattributed against a selected file.

A correct implementation that preserves the `$File`/`$Line` state sequence
was built (calling `get_location` for skipped CVs, falling back to
`sub_info` for non-B::COP cases, guarding against GV edge cases on newer
Perls). It was correct across Perl 5.26/5.32/5.40 and DC 1.33-1.52, but
benchmarked identically to running without it — the overhead of maintaining
state parity cancelled out the savings from skipping `B::Deparse->new`.

The implemented filtered `get_cover()` replay above is narrower: it does not
remove CVs before stock `get_cover()` sees them during cache construction, and
only replays observed stock early returns after `START`/`ROOT` validation.

### Per-CV file check in walksymtable

An earlier version of the walksymtable replacement also filtered individual
CVs by file before calling `find_cv`. This was removed because stock
`find_cv` independently inspects the CV's PADLIST for inner anonymous CVs,
which can be from a different file than the outer CV (e.g. via `#line`
directives). Skipping `find_cv` based on the outer CV's file misses selected
inner CVs in that scenario.

The per-CV check contributed ~1s on `prove` and ~1-2s on `forkprove` — minor
compared to subtree pruning's ~5-10s savings. The correctness risk was not
worth the marginal speedup.

### Cache `sub_info` results

**Target:** `sub_info` called twice per CV — once in `check_files` (for
sorting) and once in `get_cover`.

`sub_info` walks the B:: op tree (`->GV`, `->ROOT`, `->first`, etc.) to
extract the sub name and start op. Caching by CV address (`$$cv`) avoids
redundant B:: method calls.

Benchmarked at 22.1s `prove` / 21.7s `forkprove` with optimization 1
active — no measurable effect. The 33.7% cache hit rate is lower than the
theoretical 50% because BEGIN-block CVs go through `get_cover` but not
`check_files` sorting.

### Wrap `find_cv` with file-level cache

Wrapped `B::GV::find_cv` with a per-file cache: extract the CV's `START` op
file, check `use_file` once per unique file, and skip the original `find_cv`
for CVs in rejected files. For matching files, delegate to the original.

Benchmarked at 27.1s `prove` / 34.9s `forkprove` (vs 27.0s / 35.4s stock) —
negligible improvement because the dominant cost is the walksymtable
iteration itself, not the per-CV `use_file` call.

Also has a correctness issue: stock `find_cv` independently inspects nested
anonymous CVs in the outer CV's PADLIST, which can be from a different file.
The early return for non-matching outer CVs skips this PADLIST inspection,
potentially missing selected anonymous subs defined inside ignored outer subs
via `#line` directives.

**Key constraint discovered:** Devel::Cover's `%Cvs` and `@Cvs` are `my`
(lexical) variables, inaccessible from outside the package. Writing to
`$Devel::Cover::Cvs{$cv}` silently writes to a different (package) variable,
resulting in empty `@Cvs` and broken branch/condition coverage (100% stmt,
`n/a` bran/cond everywhere). This is why this approach must delegate to the
original for matching files.

### Fully replace `find_cv` via PadWalker

Used `PadWalker::peek_sub(\&Devel::Cover::check_files)->{'%Cvs'}` to get a
writable reference to the lexical `%Cvs`, then populated it directly. This
avoids the lexical-variable constraint and does handle PADLIST independently.

Benchmarked at 24.8s `prove` / 27.6s `forkprove` — better than the
find_cv wrapper but still slower than walksymtable (21.5s / 23.2s) because
the dominant cost is the walksymtable iteration, which this doesn't address.
Requires an extra dependency (PadWalker) for less benefit.
