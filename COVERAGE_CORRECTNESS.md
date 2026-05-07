# Coverage Correctness Risks

This note audits correctness failure modes:

- Devel::Cover bugs or blind spots
- things Devel::Cover cannot reliably infer from Perl's runtime/op-tree model
- nondeterministic or order-dependent attribution
- forkprove-specific problems caused by parent/child execution
- optimizer-specific problems in either normal `prove` mode or forkprove/cache
  mode

Expected feature differences between Devel::Cover versions, benchmark
performance, and operational problems such as stale `cover_db` reuse are out of
scope.

Source versions checked:

- Devel::Cover 1.38
- Devel::Cover 1.52

The main pipeline is the same in both versions: `check_files()` discovers CVs
with `walksymtable`, `_report()` calls `get_cover()` for main, BEGIN, CHECK,
END/INIT and discovered CVs, `get_cover()` uses `B::Deparse` to discover
statement/branch/condition structure, and `Devel::Cover::DB` merges counts into
summary percentages. The important 1.52 differences for this audit are the
false-filename guard in `use_file` and newer B::Deparse hooks.

Impact score is a pragmatic 1-5 scale for correctness impact if the issue is
hit:

- 1: cosmetic/report-only correctness issue
- 2: small local count, attribution, or text difference
- 3: can change a few file percentages
- 4: can affect many files or CI gates
- 5: can make coverage materially wrong for a run

## Devel::Cover Issues

These are stock Devel::Cover bugs, blind spots, or inherent inference limits.
They are ranked by correctness impact.

### 1. Locationless CVs can inherit stale `$File` and `$Line`

**Impact score:** 5/5.

**Versions:** 1.38 and 1.52.

**Chance:** Low in normal Perl modules; medium in generated code, Safe
compartments, eval-heavy code, or unusual B:: op shapes.

**More likely when:** a CV has no usable `START` COP, `sub_info()` cannot find a
normal first `nextstate`, or the deparse walker sees branch/condition ops before
a new COP updates the current location.

**Expected difference:** code can be attributed to the previous file/line, or a
locationless CV can be accepted/rejected based on stale file state. This can
change file percentages if selected and ignored files are interleaved, and can
make coverage for the affected files effectively meaningless.

Devel::Cover tracks location in package globals `$Devel::Cover::File` and
`$Devel::Cover::Line`. `get_location()` updates them from COPs, but many pieces
of `get_cover()` and the B::Deparse hooks read the current globals. If a CV or
op does not provide a fresh location, the previous location can remain in force.

This is stock behavior and explains why a discarded optimization that
pre-filtered CVs before `get_cover()` was unsafe: block CVs or CVs that
`get_cover()` later rejects can still update the current location before the
next accepted CV is processed. Removing them from the iteration changed which
stale location a later locationless CV inherited.

The current cache optimization leaves the real `get_cover()` entry path in
place and only replaces `deparse_sub`, which reduces this risk. It also refuses
to cache CVs unless the initial `get_cover()` call establishes a non-empty
location through `get_location($start)`. Locationless CVs are therefore handled
by stock `get_cover()` in the child, preserving whatever stale-location behavior
Devel::Cover would normally have had rather than replaying the parent's
cache-build location state. For cached CVs, it captures and restores
`File`/`Line` for each replayed branch/condition/statement call, then restores
the final `File`/`Line` state left by the cached CV.

This mitigates an optimizer-specific amplification of stale-location behavior;
it does not fix the underlying stock Devel::Cover issue for uncached or
locationless CVs.

### 2. Coverage can change program behavior through loaded dependencies

**Impact score:** 4/5.

**Versions:** 1.38 and 1.52.

**Chance:** Low for normal tests; high for tests that deliberately manipulate
`@INC` or assert optional dependency failures.

**More likely when:** code tests `require` failure paths for modules that
Devel::Cover itself loads, clears `@INC`, relies on module absence, or has
side-effects tied to whether modules such as `B`, `B::Deparse`, `Carp`, `Cwd`,
`Digest::MD5`, `File::Spec`, `Storable`, `JSON`, or `Sereal` are already
loaded.

**Expected difference:** not just coverage output; the program can take a
different runtime branch under coverage.

This is a real correctness issue because instrumentation changes the program
being measured. If a test is meant to exercise "module is absent" behavior,
Devel::Cover may already have loaded that module or one of its dependencies.
The coverage report can then describe a different execution path from the one
seen outside coverage.

The exact dependency list differs slightly: 1.38 also lists `B::Debug`, which
1.52 no longer loads. Optimizations do not cause this, though cache mode adds
dependencies such as `PadWalker`.

### 3. Redefined subroutines are a stock blind spot

**Impact score:** 4/5.

**Versions:** 1.38 and 1.52.

**Chance:** Low in ordinary app code; medium in test helpers and frameworks that
monkey-patch or generate methods.

**More likely when:** code redefines subs after initial compilation, installs
new CVs into existing globs, uses mocking frameworks, or uses modules that
replace methods at runtime.

**Expected difference:** original CVs can disappear from the final report, or
replacement CVs can be reported instead. The effect is usually local, but it
can make a file's subroutine coverage materially wrong.

Devel::Cover documents this limitation directly: if a subroutine is redefined,
the original subroutine may not be reported because Devel::Cover has not found
a way to locate the original CV. That is a correctness problem rather than a
formatting issue: the final report can describe the current symbol table, not
all code that existed or executed during the run.

Optimization 1 can make this worse only if the replacement lives in a package
subtree the `%INC` heuristic prunes. Optimization 2 generally turns redefined
CVs into cache misses because the CV address or START/ROOT addresses change.

### 4. `%Seen` makes stock coverage order-sensitive

**Impact score:** 3/5.

**Versions:** 1.38 and 1.52.

**Chance:** Low for ordinary named subs; medium around anonymous/generated code
or shared op traversal.

**More likely when:** the same op can be reached through more than one CV walk,
anonymous subs are nested, multiple CVs sort to the same line/name, or code
generation exposes the same op through more than one traversal path.

**Expected difference:** duplicate statement/branch/condition entries can be
suppressed under one attribution and emitted under another. The percentage
effect is usually local but can affect a file if generated code is dense.

Devel::Cover has a lexical `%Seen` hash in `Devel::Cover.pm`. The deparse
wrappers use op addresses as keys to avoid reporting the same statement, branch,
condition, or "other" op more than once. `%Seen` persists across the whole
report pass. It is not per-CV.

That makes report order part of the result. Stock `_report()` walks main,
BEGIN, CHECK, END/INIT, then `@Cvs`. `check_files()` sorts `@Cvs` by line and
name, but ties can still retain earlier hash/value ordering. A later CV may see
an op as already handled and omit structure that an earlier ordering would have
attributed differently.

### 5. B::Deparse mapping can make branch/condition structure fragile

**Impact score:** 3/5.

**Versions:** 1.38 and 1.52, with different exact hooks.

**Chance:** Low for simple statement/subroutine coverage; medium for
branch/condition coverage in syntax-heavy or generated code.

**More likely when:** code uses newer syntax, signatures, chained logical
operators, ternaries, empty elses, constants on the right side of short-circuit
ops, source filters, or generated code.

**Expected difference:** branch/condition structure can be attached to
surprising source text or line numbers. In some cases the number of reported
branch/condition paths can change, which can change summary percentages.

Devel::Cover maps runtime counters back to source by running B::Deparse with
localized overrides for `deparse`, `logop`, `logassignop`, and constant
handling. Version 1.52 adds hooks for `binop` and `const` to handle newer Perl
behavior, including newer xor handling. Version 1.38 also depends on
`B::Debug`, while 1.52 no longer does.

The correctness issue is broader than version comparison: Devel::Cover is
inferring source structure from a deparse traversal of the compiled op tree.
Some source shapes do not round-trip cleanly through that model. This is not
optimizer-specific. The cache optimization is safe only inside one parent/child
fork family where the op tree and B::Deparse implementation are the same.

### 6. Shared structure files are last-writer-wins

**Impact score:** 3/5.

**Versions:** 1.38 and 1.52.

**Chance:** Low in serial test runs; medium when tests run in parallel and
different processes generate different structure for the same source file.

**More likely when:** two processes load the same digestable source file, then
compile different conditional `eval` blocks, generated methods, or optional
plugin code attributed back to that source file.

**Expected difference:** the final report can interpret one process's run
counts through another process's structure. This can merge generated subs,
drop structure for a generated sub, or attach branch/condition counts to the
wrong generated entry. The effect is usually local to generated code in one
file, but can change that file's percentages.

Devel::Cover writes per-process run counts under unique `cover_db/runs/...`
paths, but source structure is shared by digest under `cover_db/structure`.
Structure writes are atomic at the file level: the process writes a temporary
file and renames it into place. That prevents torn structure files, but it does
not merge two divergent structure variants for the same source digest.

If process A and process B both read the same clean structure, A adds generated
method `foo`, B adds generated method `bar`, and both write the same digest
file, the last rename wins. The final structure may contain `foo` but not
`bar`, or `bar` but not `foo`. Later report merging then combines all run
counts using whichever structure file survived.

The practical problem is that run files contain arrays of counts by criterion
index, while the structure file says what each index means. For example, a run
may say "condition index 2 was true three times"; the shared structure says
whether condition index 2 is `$item->{priority} // ""`, `$item->{status} //
""`, or something else. If the surviving structure file came from a process
with a different generated-code shape, the report can still merge the numeric
counts, but it may describe them using the wrong source text or generated
subroutine name.

There are two common outcomes:

- If two generated methods reused the same structure indexes, their counts can
  be merged and reported as one surviving method or condition. Coverage may
  look better than it should, because one generated path can cover another's
  reported structure.
- If one process allocated additional indexes that the surviving structure does
  not contain, those counts cannot be matched to source structure. The report
  can drop them or warn that it cannot locate structure for that criterion,
  making coverage look worse or incomplete.

This is stock Devel::Cover behavior, independent of this optimizer.

### 7. Anonymous sub attribution is approximate

**Impact score:** 3/5.

**Versions:** 1.38 and 1.52.

**Chance:** Medium in modern Perl codebases because anonymous callbacks and
generated closures are common.

**More likely when:** several anonymous subs appear on one line, generated
accessors/callbacks share source locations, or closures are produced by
frameworks and metaprogramming.

**Expected difference:** subroutine coverage entries can merge or move between
same-line anonymous subs. Statement/branch/condition coverage may still be
reasonable while subroutine names/locations are not very meaningful.

`sub_info()` normalizes anonymous GV names to `__ANON__`. `get_cover()` then has
a special case to merge consecutive anonymous subs with the same file, line, and
sub name. The source contains a TODO for multiple anonymous subs on the same
line in both versions.

This is an inherent limitation of mapping runtime CVs and op trees back to a
single source location. It is more visible in detailed reports than in
high-level percentages unless many anonymous subs are treated as uncovered.

## Forkprove Issues

These are caused by forkprove's parent/child execution model interacting with
Devel::Cover. They are ranked by correctness impact.

### 1. Inherited parent counters inflate counts and can mark preload code covered

**Impact score:** 4/5.

**Versions:** 1.38 and 1.52.

**Chance:** High for raw counts whenever Devel::Cover is active in the
forkprove parent and application modules are preloaded; low for percentage
changes when every preloaded module would also be loaded by at least one test.

**More likely when:** the preload loads selected files, executes `use` lines,
runs `BEGIN` blocks, builds generated accessors, or otherwise executes selected
code before child processes fork.

**Expected difference:** raw counts can scale roughly with the number of forked
children. Coverage percentages usually stay the same if every preloaded module
would also be loaded by a test, because the same items are covered in both
runner modes. Percentages can change if preload executes selected code that no
test would otherwise load, or executes only one side of a branch/condition.

This is stock Devel::Cover plus fork semantics, not optimizer-specific. With
forkprove, the parent can execute selected code while coverage counters are
active. Each child inherits those already non-zero counters and writes them at
END. The merged report then sums the same parent counts once per child.

It is especially visible on compile-time lines and subroutines named `BEGIN`.
In the local benchmark output, the detailed text report shows many `use` lines
and `BEGIN` rows changing from per-test counts like `10`, `12`, or `23` under
`prove` to about `117` under forkprove. The coverage percentages remain stable
in that run because those items were covered in both modes.

So the usual forkprove preload effect is count inflation, not percentage
inflation. It becomes a coverage correctness issue only when the parent preload
covers selected code that no child test would have loaded or executed in the
same way.

### 2. POD lookup depends on END-time `@INC`

**Impact score:** 3/5.

**Versions:** 1.38 and 1.52.

**Chance:** Medium when POD coverage is enabled under forkprove.

**More likely when:** test libraries are added with localized `-I`/`-l`
handling, packages remain loaded after the test scope, and `Pod::Coverage` has
to locate source by searching the current `@INC`.

**Expected difference:** POD percentages for affected packages can change from
covered to uncovered. Non-POD statement/branch/condition/subroutine coverage is
not directly affected.

Devel::Cover delegates POD coverage to `Pod::Coverage` or
`Pod::Coverage::CountParents`. The package symbols can still exist at END, but
`Pod::Coverage` may search the current `@INC` to find the POD source. If
forkprove has unwound a localized test-library `@INC` by then, the module is in
the symbol table and `%INC`, but the file is no longer findable by `Pod::Find`.

Keeping the selected library path in process-global `@INC` avoids this. A more
direct Devel::Cover-side fix would be to pass `pod_from` from the already-known
source filename. The option spelling differs around this area: 1.38 parses
`trust_me`, while 1.52 parses `trustme`.

## Optimizer Issues

These are risks introduced by the experimental optimizer. Package pruning and
structure caching can apply in either normal `prove` mode or forkprove mode.
Cache replay risks apply when cache mode is enabled. They are ranked by
correctness impact.

### 1. Package pruning can miss selected CVs when `%INC` does not predict packages

**Impact score:** 5/5.

**Versions:** risk exists against both 1.38 and 1.52; this is optimizer-specific.

**Chance:** Low for conventional `Foo/Bar.pm` -> `Foo::Bar` codebases with broad
`+select,^lib,+ignore,^`; medium for generated/plugin-heavy code.

**More likely when:** a selected file defines packages unrelated to its `%INC`
key, one file defines multiple unrelated namespaces, `#line` points generated
CVs at selected files without matching `%INC`, or runtime symbol manipulation
installs selected subs into unexpected stashes.

**Expected difference:** can omit whole files or groups of subs from coverage.
If the omitted code was uncovered, coverage can look better than it should; if
it was covered, expected files can disappear.

Stock `check_files()` enters every package stash with `B::walksymtable`, then
filters individual CVs through `use_file`. Optimization 1 prunes whole package
subtrees earlier. To decide whether to descend into `Foo::Bar::`, it predicts a
module key such as `Foo/Bar.pm` and checks the corresponding `%INC` value.

That is a heuristic. It is correct for ordinary module layouts, and the current
implementation is deliberately conservative for unknown `%INC` values: refs,
undef, true sentinels such as `1`, or strings such as `(set by Moose)` cause a
descent rather than a skip. But if `lib/A/B.pm` defines `package C::D`, and
nothing else selected makes the walker enter `C::`, the optimizer has no cheap
way to know that `C::D` contains selected code without doing the full walk it is
trying to avoid.

This is the main coverage-risk tradeoff in optimization 1. It is avoidable only
by being conservative enough to lose some speed, or by falling back to stock
`walksymtable` for unusual layouts.

### 2. Cache replay depends on matching current `%Seen` state

**Impact score:** 4/5.

**Versions:** risk exists against both 1.38 and 1.52; this is optimizer-specific.

**Chance:** Low for separate ordinary modules; medium around generated or
nested CVs when children load more code after cache build.

**More likely when:** the child has an earlier uncached CV that was not present
during cache building, that CV can reach an op also seen by a later cached CV,
or tests create END blocks, anonymous closures, or generated methods after the
forkprove parent cache has been built.

**Expected difference:** if not detected, duplicate statement/branch/condition
structure relative to a fully uncached report. This can change percentages if
the duplicated or shifted structure is uncovered.

The cache build walks CVs in stock `_report()` order and records both the
`add_*_cover` calls and the `%Seen` assumptions for each cached CV. That is
correct when the child replays the same CVs in the same relative order, and it
is still safe when mismatched `%Seen` state is detected and treated as a cache
miss.

The awkward case is a mixed run. Suppose cache build records an add call for
cached CV `A` because `%Seen` had not seen that op yet. In the child, an earlier
uncached CV `B` might be present and might reach the same op first. Stock
Devel::Cover would mark `%Seen` in `B` and suppress the later add call in `A`.

The current replay path records keys read as false, keys read as true, and keys
changed from false to true during cache building. Shared assumptions are checked
against the child `%Seen` state before replay, and required-true assumptions are
always checked. Private false-to-true writes are applied immediately on cache
hit; if an uncached walk writes a private required-false key first, the future
owning cache entry is invalidated and misses. This mitigates the
straightforward duplicate-add failure mode; the remaining risk is an untracked
future Devel::Cover `%Seen` access pattern or a cached call stream that no
longer matches what `B::Deparse` would produce in the child.

### 3. Cache replay depends on the child matching the parent deparse stream

**Impact score:** 4/5.

**Versions:** risk exists against both 1.38 and 1.52; this is optimizer-specific.

**Chance:** Low in forked children when op trees are inherited unchanged; higher
if preloaded code mutates relevant global deparse behavior after cache build.

**More likely when:** selected subs are redefined after cache build, source
filters or evals create unusual op trees, `B::Deparse` is monkey-patched after
cache build, or a cached CV is stale but not detected by the START/ROOT address
checks.

**Expected difference:** statement, branch, or condition structure for affected
CVs can change. Subroutine and POD coverage are less exposed because the real
`get_cover()` path still performs those steps before `deparse_sub` is replayed.

The cache records the sequence of `add_statement_cover`,
`add_branch_cover`, and `add_condition_cover` calls produced by
`B::Deparse::deparse_sub` in the forkprove parent. In children it wraps
`B::Deparse::deparse_sub` only when the direct caller is
`Devel::Cover::get_cover`. For a cache hit it validates the CV's `START` and
`ROOT` op addresses, then replays those recorded calls against the child's real
runtime `$Coverage`.

The main correctness dependencies are:

- the child sees the same op objects and B::Deparse traversal for cached CVs
- `$Devel::Cover::File` and `$Devel::Cover::Line` are restored for each replayed
  call and to the final state left by the cached CV
- cached CVs have an initial location established by stock
  `get_cover() -> get_location($start)`, so replayed branch/condition calls are
  not based on an inherited parent-side location
- `%Seen` is updated as if the deparse walker had really traversed the CV
- speculative cache building does not leave behind `%Run`, `$Structure`,
  `$Sub_count`, `%Seen`, `$Pod`, or `%Pod` side effects

The current implementation addresses those points: it captures per-call and
final `File`/`Line` state, records `%Seen` true/false assumptions, checks shared
state and all required-true state before replay, writes private `%Seen` effects
immediately, invalidates private owners when real deparse reaches their keys
first, validates `START`/`ROOT`, uses temporary structure/run state during cache
build, and saves/restores POD state. The remaining risk is inherent in replay:
if Devel::Cover or B::Deparse would have made a different call stream in the
child, the replay path can be wrong. Locationless CVs are now outside the cache
hit surface, so this risk is concentrated on CVs whose initial location was
established normally.

### 4. Structure write skipping depends on dirty tracking

**Impact score:** 4/5.

**Versions:** risk exists against both 1.38 and 1.52; this is optimizer-specific.

**Chance:** Low for the checked Devel::Cover 1.38 and 1.52 code paths.

**More likely when:** a future Devel::Cover version mutates `DB::Structure`
through methods the optimizer does not wrap, a new criterion uses a different
structure-update path, or the same source file is reached through multiple
textual paths in a way that separates the dirty filename from the filename later
written.

**Expected difference:** only if a real structure mutation is missed. In that
case, `write()` can treat an existing digest file as clean and skip an update it
should have written. Later report merging can then miss statement, branch,
condition, subroutine, or POD structure for affected files, producing warnings
such as "can't locate structure" or changing percentages for those files.

Stock `DB::Structure->read_all()` eagerly loads every structure file, and
`write()` rewrites all loaded entries. The structure-cache optimization changes
that write policy: if a digest file already exists and the current process has
not changed the corresponding source structure, it skips rewriting the same
structure. The correctness boundary is therefore the dirty flag, not whether the
codebase uses generated methods, conditional `eval`, or other dynamic loading.

Those dynamic cases are expected to work when they go through Devel::Cover's
normal structure APIs. If they add structure through generated `add_*`,
`set_subroutine`, or `store_counts`, the optimizer marks the source file dirty
and writes the digest normally. Dirty files, missing digest files, and files
without a usable digest all fall back to stock-style writes.

The residual risk is an optimizer bug or Devel::Cover internal change: a
structure mutation happens, but no wrapped path marks the file dirty. That
would be coverage-silent stale structure, because counts for the new structure
could be written while the old digest file remains on disk. This is not expected
for the checked 1.38 and 1.52 paths, but it is a real risk because
`DB::Structure` does not provide an explicit dirty flag.

This optimization does not attempt to fix Devel::Cover's stock last-writer-wins
structure semantics. If two processes concurrently write different dirty
structure variants for the same digest, the final structure file is still
whichever complete file was renamed last.

There is a separate operational boundary around lazy reads: code that genuinely
expects `read_all()` to populate all of `$Structure->{f}` for enumeration will
see different behavior while the optimizer is loaded. The intended use is the
test process coverage write path, where Devel::Cover normally looks up
structure by digest or by the current source file. Use `no_structure_cache` if a
workflow needs stock eager structure loading.

## Overall Assessment

The highest-impact stock Devel::Cover issue is stale location state: if a CV or
op is attributed through an old `$File`/`$Line`, coverage for the affected files
can stop meaning what it appears to mean.

The highest-impact optimizer-specific issue is package pruning. It is logically
sound for conventional module layouts and broad selected roots, but it cannot
be perfect without doing the full symbol-table walk. The current conservative
handling of non-file `%INC` values is the right tradeoff because it chooses
extra work over missing coverage.

Cache replay is the more invasive optimization, but its coverage surface is
narrower than it first appears: `get_cover()` still performs file selection,
subroutine coverage, and POD coverage in the child. The replay replaces only
the expensive B::Deparse discovery of statement/branch/condition call streams.
The critical things to preserve are `%Seen` and `File`/`Line` state, because
those are stock Devel::Cover side effects rather than explicit return values.

The structure DB cache is less invasive than deparse replay, but it introduces
a different kind of risk: stale on-disk structure if dirty tracking ever misses
a mutation. The current wrappers cover the checked 1.38 and 1.52 mutation
paths, and `no_structure_cache` provides a direct fallback to stock eager
structure handling.

The largest expected differences between `prove` and `forkprove` are not caused
by either optimization. They come from forked counter inheritance and, when POD
is enabled, END-time POD lookup. Detailed text reports are therefore best
compared within runner family for raw counts, while summary percentages can be
compared across runner family only when the runner is configured so selected
code coverage status is expected to be the same.
