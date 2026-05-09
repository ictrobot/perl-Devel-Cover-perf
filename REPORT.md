# Devel::Cover + forkprove Performance Investigation

## Summary

**Hypothesis confirmed:** Devel::Cover's END-block processing scales with the
total symbol table size, not just the files matching `+select`. When forkprove
preloads heavy modules (Moo, Types::Standard, Mojolicious), every forked child
pays ~0.25s in Devel::Cover cleanup — even for lightweight tests that don't
use those modules. This overhead erases (and reverses) forkprove's compilation
savings.

## Observed Performance (model codebase: 132 libs, 116 tests)

Measured with Hyperfine 1.19.0 on Perl 5.40.1 with Devel::Cover 1.52.
`Pod::Coverage` was not installed, so POD coverage was not included.

| Mode                | Time   | Notes                           |
|---------------------|--------|---------------------------------|
| `prove`             | 9.28s  | baseline                        |
| `forkprove`         | 6.45s  | 1.4x faster (preload saves ~3s) |
| `prove + cover`     | 26.80s |                                 |
| `forkprove + cover` | 37.64s | **slower** than prove + cover   |

Coverage timings measure the full `example/run-tests` workflow, including
`cover -delete -silent` before the test run and `cover -silent` report
generation afterwards.

## Note on forkprove Coverage Counts

When Devel::Cover is enabled via `PERL5OPT` and forkprove preloads an
application with `-M`, the preload runs in the forkprove parent while coverage
collection is already active. That changes what the raw counters mean.

In a plain `prove` coverage run, each test file starts a fresh Perl process.
Any module compile-time work, including `use` statements and `BEGIN` blocks,
runs in that test process, and Devel::Cover writes one run at process END. If a
module is loaded by 10 test files, its compile-time statements and `BEGIN`
blocks are counted about 10 times across the merged coverage database.

With forkprove, there is first a long-lived parent process. Devel::Cover is
already collecting in that parent, then forkprove loads the `-M` preload
modules. All compile-time work for those modules runs once in the parent before
any test child exists: `use` lines, imported modules, generated accessors,
`BEGIN` blocks, and any other selected code executed during preload all leave
non-zero Devel::Cover counters in the parent's memory.

The parent then forks one child per test job/file. Each child receives a
copy-on-write snapshot of those already non-zero counters. At child END,
Devel::Cover's `_report()` reads the inherited counters and writes a normal run
for that child. It has no way to distinguish "this count happened in the
preload parent" from "this count happened in this child". The same preload
counts are therefore written once by every child and then summed during report
generation.

This is why detailed forkprove reports often show much higher counts for
preload-time code. A `BEGIN` block or `use Some::Module` line that actually ran
once in the forkprove parent can appear with a count close to the number of
forked children. In a plain `prove` run, the same line is counted only in the
test processes that actually loaded that module. Runtime code executed after
the fork does not have this inherited-count shape; it is counted in the child
that executed it.

In the text report this manifests in two obvious places. The per-line table can
show inflated `stmt`/`sub` counts on compile-time lines such as `use strict`,
`use warnings`, `use Some::Dependency`, and generated accessor setup. The
covered-subroutines table can also show rows named `BEGIN` with counts near the
number of forked children, even though the corresponding `BEGIN` block executed
once in the parent. If a child later executes the same selected code after the
fork, its child-local count is added on top of the inherited preload count.

Usually this changes raw counts rather than coverage percentages: a line,
branch arm, condition, or subroutine that was already non-zero remains covered.
It can still change percentages when the preload executes selected code that a
plain `prove` run would not load or execute, or when it executes only one side
of a branch/condition before the child tests run.

## Note on forkprove POD Coverage

POD coverage has a separate forkprove sensitivity because Devel::Cover
delegates it to `Pod::Coverage`, which inspects package documentation and the
symbol table. This is secondary to the counter issue above, but it is another
stock forkprove difference rather than an optimizer difference.

The problem appears to be an `@INC` lifetime issue. `Pod::Coverage` can inspect
symbols from an already-loaded package, but when it looks for the POD source it
uses `Pod::Find` against the current `@INC`. It does not first resolve the file
from the package's `%INC` entry.

forkprove applies its `-l` / `-I` additions with a localized `@INC` while it is
loading and running the test file in the child. Devel::Cover writes coverage in
an END block, after that local scope has unwound. By then, modules loaded from
the test library are still present in the symbol table and `%INC`, but their
source directory may no longer be in the current `@INC`. `Pod::Coverage` then
sees the package symbols but fails to find the POD file, so documented methods
can be reported as POD-uncovered under stock forkprove even though the same
methods are covered under stock prove.

This is avoidable if the test library path is kept in the process-global
`@INC`, for example through `PERL5OPT=-Ilib`, because `Pod::Coverage` can still
find the file when Devel::Cover's END block runs. More robust fixes would be
for Devel::Cover to pass the already-known source file as `pod_from`, or for
`Pod::Coverage` to prefer `%INC` for loaded packages before searching `@INC`.

## Root Cause

Devel::Cover's `_report()` runs in every child process's END block. It does
three expensive things that scale with symbol table size, not covered-file
count:

### 1. `check_files` — symbol table walk (74% of overhead)

```perl
walksymtable(\%main::, "find_cv", sub { !$seen_pkg{$_[0]}++ })
```

This walks **every package** in the Perl symbol table. For each GV (glob value),
it calls `find_cv` → `check_file` → `use_file`, which runs regexes against
`@Select_re` and `@Ignore_re` to decide if the file should be covered.

| Metric              | No preload | With preload | Factor |
|---------------------|-----------|-------------|--------|
| Packages walked     | 70        | 1,302       | 18.6x  |
| `check_file` calls  | 9,380     | 42,240      | 4.5x   |
| `use_file` calls    | 4,651     | 35,018      | 7.5x   |
| Cache misses        | 192       | 6,201       | 32x    |
| Wall time (2 calls) | 0.026s    | 0.160s      | 6.2x   |

The filter does work — `%Cvs` is empty in both cases for a lightweight test.
But the walk itself is the cost.

### 2. `get_cover_progress` — B::Deparse of CVs (26% of overhead)

After the symtable walk, `_report` iterates all BEGIN-block CVs and remaining
CVs, calling `get_cover` on each. Each call:

1. Creates `B::Deparse->new`
2. Calls `sub_info` (walks the B:: op tree)
3. Calls `get_location`
4. Calls `use_file` (regex matching)

With preloaded modules: **4,454 calls, 4,232 early returns (95% wasted)**.

| Phase                  | No preload    | With preload     |
|------------------------|--------------|-----------------|
| BEGIN block CVs        | 398           | 4,315            |
| CV entries             | 6             | 116              |
| Total `get_cover` time | 0.012s        | 0.100s           |

### 3. DB write — negligible

Database writes are ~0.004s regardless of preload state.

## Per-child Cost Breakdown (forkprove + cover)

Measured by forking from a preloaded parent with Devel::Cover active:

| Phase                      | Time   |
|----------------------------|--------|
| Test execution             | 0.04s  |
| `_report` → `check_files` | 0.16s  |
| `_report` → `get_cover`   | 0.10s  |
| `_report` → DB write      | 0.005s |
| **Total per child**        | **0.25s** |

At 116 tests: **29.0s** in `_report` alone.

## Why forkprove + cover is Slower: The Math

```
No coverage:
  prove:                     9.28s
  forkprove:                 6.45s
  preload saving:            2.83s

Coverage:
  prove + cover:             26.80s
  forkprove + cover:         37.64s
  forkprove penalty:         10.84s

Coverage overhead:
  prove:                     26.80s - 9.28s = 17.52s
  forkprove:                 37.64s - 6.45s = 31.19s
  extra forkprove overhead:  13.67s

Net:
  forkprove saves ~2.8s without coverage, then loses ~13.7s of extra
  coverage overhead, so the coverage run is ~10.8s slower overall.
```

## Potential Optimizations

### In Devel::Cover itself

1. **Early package-level filtering in `walksymtable`**. The third argument to
   `walksymtable` is a filter callback that receives the package name. Currently
   it only deduplicates (`!$seen_pkg{$_[0]}++`). If `@Select_re` is set, this
   callback could skip entire package subtrees whose files can't possibly match.
   This would avoid entering 1,200+ irrelevant packages.

2. **Skip `B::Deparse->new` in `get_cover` for filtered files**. Currently
   `get_cover` creates a new B::Deparse object before checking `use_file`. The
   file check could be hoisted before the Deparse allocation.

3. **Cache `sub_info` results**. The same CVs are inspected by both
   `check_files` (for sorting) and `get_cover_progress`. The op-tree walk and
   file lookup could be cached by CV address.

### Note on `+select`/`+ignore` configuration

Even with the tightest possible configuration — e.g.
`+select,^lib,+ignore,^` ("only cover `lib/`, ignore everything else") —
the problem persists. Devel::Cover has all the information it needs to skip
non-`lib/` code, but the select/ignore filters are applied per-CV inside
`use_file`, which is called *after* `walksymtable` has already descended into
every package and extracted every GV. The filtering happens too late — the
expensive work (B:: op tree inspection, GV extraction) has already been done.

Adding more `+ignore` patterns (e.g., `+ignore,Moo,+ignore,Type`) does not
help meaningfully because the cost is in the walk and CV extraction, not the
regex matching itself.

### At the user/tooling level

4. **Don't preload under coverage**. Use plain `prove` for coverage runs,
   accepting the per-test compilation cost (which is less than the `_report`
   overhead a large preload would introduce). In this repository the benchmark
   application lives under `example/`, so run these commands from there:

   ```bash
   cd example

   # Fast tests: preload
   forkprove -lr -I. -MMyApp::Web t/

   # Coverage: don't preload
   PERL5OPT='-MDevel::Cover=+select,^lib,+ignore,^' prove -lr t/
   cover -silent
   ```

5. **Split coverage runs**. Run coverage only on a subset of tests that exercise
   the code under test, rather than the full suite. This reduces the number of
   `_report` invocations.

## Extrapolation to Larger Codebases

At production scale (hundreds of dependencies, thousands of test files), the
per-child `_report` cost grows significantly. A larger symbol table means more
packages to walk, more CVs to inspect, more `use_file` cache misses. The
`walksymtable` cost could easily reach 1-2s per child, and with hundreds of
test files this alone could dominate total coverage runtime — regardless of
whether `prove` or `forkprove` is used as the runner.

For a real-world codebase showing `prove` ~180s, `forkprove` ~60s, but
coverage ~800s with either runner: the coverage overhead is likely dominated
by `_report` END-block costs that are proportional to dependency tree size
rather than test count or covered-code size.

## Methodology

- Individual test timing with `time(1)` and `Time::HiRes`
- Monkey-patched Devel::Cover internals to time `check_files`, `get_cover`,
  `_report`, `DB::write`, and to count `check_file`/`use_file` invocations and
  cache hit rates
- NYTProf profiling of a single test under Devel::Cover with preloaded modules
- Simulated forkprove behavior with manual `fork()` to isolate per-child costs
- Symbol table size measured via `B::walksymtable`
- All measurements on Perl 5.40, Devel::Cover 1.52, Moo 2.x, Mojolicious 9.x
