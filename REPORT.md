# Devel::Cover + forkprove Performance Investigation

## Summary

**Hypothesis confirmed:** Devel::Cover's END-block processing scales with the
total symbol table size, not just the files matching `+select`. When forkprove
preloads heavy modules (Moo, Types::Standard, Mojolicious), every forked child
pays ~0.25s in Devel::Cover cleanup — even for lightweight tests that don't
use those modules. This overhead erases (and reverses) forkprove's compilation
savings.

## Observed Performance (model codebase: 130 libs, 115 tests)

| Mode               | Time  | Notes                           |
|--------------------|-------|---------------------------------|
| `prove`            | 9.9s  | baseline                        |
| `forkprove`        | 7.2s  | 1.4x faster (preload saves ~3s) |
| `prove + cover`    | 26.9s |                                 |
| `forkprove + cover`| 36.0s | **slower** than prove + cover   |

## Note on forkprove Coverage Counts

When Devel::Cover is enabled via `PERL5OPT` and forkprove preloads an
application with `-M`, the preload runs in the forkprove parent while coverage
collection is already active. The resulting counters are inherited by every
forked test child, so detailed reports can show much higher raw execution
counts for preload-time statements and `BEGIN` blocks than a plain `prove`
coverage run.

This usually changes counts rather than coverage percentages: the same lines,
branches, conditions, and subroutines are present, but preload-time code is
counted once per child instead of once per test process that loaded it. It can
change covered/uncovered status if the preload executes selected code that the
plain `prove` run would not otherwise load or execute. For correctness checks,
compare detailed `forkprove` optimizer output against stock `forkprove`, not
against stock `prove`.

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

At 115 tests: **28.75s** in `_report` alone.

## Why forkprove + cover is Slower: The Math

```
prove + cover:
  Per-test _report:          ~0.05s × 115 = 5.75s
  Per-test module compile:   ~0.18s × 69 heavy tests = 12.4s
  Actual test execution + other overhead: ~8.8s
  Total: ~27s ✓

forkprove + cover:
  Per-test _report:          ~0.25s × 115 = 28.75s  (preload bloats this)
  Per-test module compile:   0s (preloaded)
  Actual test execution + other overhead: ~7.3s
  Total: ~36s ✓

Delta: forkprove loses 23s in _report, saves 12.4s from no recompile = 10.6s slower
Actual: 9s slower ✓
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
