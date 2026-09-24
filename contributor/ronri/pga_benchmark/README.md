# pga_benchmark

The benchmark and standing gap list for `pga`. That library is projective geometric algebra,
replicated from *Projective Geometric Algebra Illuminated* by Eric Lengyel, and developed in
[replications][replications].

Every operation that the library exports is a measurand. Each one is measured against a
hand-rolled typed reference, which is derived from Lengyel's own optimal forms. The four axes
are allocations, bytes moved, counts of multiply, divide and add, and time. The static
measurements are read out of the C that the compiler emits, so any one that grew is a
deterministic finding. The runtime measurements are taken by hand on a named machine.

The library is a pinned dependency that Atlas restores, and never a copy. The reference is
Nim, written here in 64-bit floats, so both implementations run the same scalar. Lengyel's
Terathon Math Library (MIT) was read to cross-check the forms and their counts, and nothing
from it is copied.

The list is [`gaps.md`](gaps.md). It holds the causes, each one decided by a rule with its
evidence. It then holds one gap for each measurand of each algebra, with the measurements of
both implementations and a stable identifier from the docket. It is generated from
`baseline/`, and never edited by hand. The words are in [`GLOSSARY.md`](GLOSSARY.md).

## Build and test

```sh
nim r koch check                                # repository root: every check a pull request runs
nim r koch test contributor/ronri/pga_benchmark  # this project alone, on the pinned compiler
nim r tools/build.nim drive     # project directory: inspect, guard, hold gaps.md; what CI runs
nim r tools/build.nim bench     # runtime measurements into baseline/runtime_<algebra>.json
nim r tools/build.nim baseline  # re-record static measurements after an intended change
nim r tools/build.nim guard     # compare the last inspection against the baseline
nim r tools/build.nim gaps      # regenerate gaps.md and the docket from baseline/
nim r tools/build.nim sweep     # dense timings at two to six dimensions, never in CI
```

The pin is **Nim at commit `27763495b`**, and no release serves it. Koch fetches and builds it
once for each machine (`GUIDE.md`, Toolchain). The record says which characters of `pga` need
it.

## Layout

```
src/pga_benchmark.nim              umbrella: algebra name and re-exports
src/pga_benchmark/catalogue.nim    every measurand as data, per algebra
src/pga_benchmark/reference/       Lengyel's typed objects and forms, rigid 4D and conformal 5D
src/pga_benchmark/widening.nim     typed objects into and out of the dense multivector
src/pga_benchmark/pools.nim        seeded operand pools, both implementations
src/pga_benchmark/measurements.nim timed loops emitted from the catalogue
src/pga_benchmark/bench.nim        entry: runtime measurements of every measurand
src/pga_benchmark/inspector.nim    static measurements read out of emitted C
src/pga_benchmark/model.nim        movement from counts and sizes
src/pga_benchmark/inspect.nim      entry: static measurements of one nimcache
src/pga_benchmark/guard.nim        compare static measurements against the baseline
src/pga_benchmark/gaps.nim         gaps, causes, docket, rendering
tools/build.nim                    driver verbs
baseline/                          committed measurements and docket
tests/                             suites, and the testament stubs that run them
```

## Status

Measured on the pinned compiler and on library head `9f9019b`. There is one gap for each
measurand of each algebra, with the causes above them. Every cause is over but the last,
which nothing here can read. `gaps.md` counts them. Unreviewed by a human. See
`PROVENANCE.md` for the figures, and for what each subsystem was checked against.

[replications]: https://gitlab.com/mraxilus/replications
