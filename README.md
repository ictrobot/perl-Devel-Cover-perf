# Devel::Cover optimization experiment

This repository is an experiment in reducing `Devel::Cover` report-time
overhead for large Perl applications, especially when tests run under
`forkprove` with an application preload.

The optimizer is deliberately implemented as an injectable monkey-patch module:
it does not require changes to `Devel::Cover` itself. The goal is to make the
problem and possible optimizations concrete enough to evaluate.

## Disclaimer

This repository, including the code, documentation, example application, test fixtures,
benchmark harness, and much of the analysis, is substantially LLM-written.

The results and compatibility claims should be independently verified before relying on
this approach in a real coverage workflow.

## What is here

- [`lib/Devel/Cover/Optimizer.pm`](lib/Devel/Cover/Optimizer.pm) contains the
  experimental optimizations.
- [`example/`](example/) is a synthetic application used for benchmarking and
  compatibility checks.
- [`ci/harness`](ci/harness) builds the compatibility containers, runs the
  coverage modes, and compares the resulting reports.
- [`REPORT.md`](REPORT.md) describes the underlying coverage/reporting problem.
- [`OPTIMIZATIONS.md`](OPTIMIZATIONS.md) describes the implemented
  optimizations, trade-offs, discarded approaches, and detailed benchmark data.
- [`COVERAGE_CORRECTNESS.md`](COVERAGE_CORRECTNESS.md) documents coverage
  correctness risks, including Devel::Cover blind spots, forkprove effects, and
  optimizer-specific failure modes.

## Current results

Representative sequential timings from the `dco-test/alma8:dc-1.52` container,
using 132 example modules, 116 tests, and coverage for statement, branch,
condition, and subroutine:

| Configuration | `prove` | `forkprove` |
| --- | ---: | ---: |
| no coverage | 8.33s | 5.57s |
| stock `Devel::Cover` | 24.59s | 33.61s |
| `Devel::Cover::Optimizer` | 20.28s | 24.75s |
| `Devel::Cover::Optimizer=cache` | 24.82s | 15.83s |

The default optimizer is about 18% faster with `prove` and 26% faster with
`forkprove` in this benchmark. The `cache` option is intended for `forkprove`
with a preload; there it is about 53% faster than stock `Devel::Cover` and 36%
faster than the optimizer without cache. Under plain `prove`, `cache` is slower
because there is no preloaded parent process to reuse.

## Usage

For plain `prove`:

```bash
PERL5OPT='-MDevel::Cover=+select,^lib,+ignore,^ -MDevel::Cover::Optimizer' \
  prove -lr t/
```

For `forkprove`, load the optimizer after the application preload. Use `cache`
when the parent process preloads a significant amount of application code:

```bash
PERL5OPT='-MDevel::Cover=+select,^lib,+ignore,^' \
  forkprove -lr -MMyApp::Web -MDevel::Cover::Optimizer=cache t/
```

## Compatibility

[`ci/harness`](ci/harness) has been used to check compatibility on EL8, EL9, EL10, and
`perl:stable` container images across `Devel::Cover` versions 1.33 through
1.52.

```bash
./ci/harness --os all --dc all
```

The same harness compares summary coverage across `prove` and `forkprove`, and
compares detailed coverage within the corresponding runner family.
