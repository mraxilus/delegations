# pga_benchmark

Benchmark and standing gap list for `pga`, the projective geometric algebra library
replicated from Eric Lengyel's *Projective Geometric Algebra Illuminated* and developed in
[replications][replications]. Every operation the library exports is a measurand, measured
against a hand-rolled typed reference derived from Lengyel's own optimal forms, on four
axes: allocations, bytes moved, multiply, divide and add counts, and time. The static
measurements are read out of the C the compiler emits, so any that grew is a deterministic
finding; the runtime measurements are taken by hand on a named machine.

The library is a pinned dependency restored by Atlas, never a copy. The reference is Nim
written here in 64-bit floats, so both implementations run the same scalar; Lengyel's
Terathon Math Library (MIT) was read to cross-check the forms and their counts, and nothing
from it is copied.

The list is [`gaps.md`](gaps.md): the causes, each decided by a rule with its evidence, then
one gap per measurand per algebra with both implementations' measurements and a stable
identifier from the docket. It is generated from `baseline/` and never edited by hand. The
words are in [`GLOSSARY.md`](GLOSSARY.md).

## Build and test

```sh
nim r koch ci                                     # repository root: audit, scope, commits
nim r koch tests contributor/ronri/pga_benchmark  # this project alone, on the pinned compiler
nim r tools/build.nim drive     # project directory: inspect, guard, hold gaps.md; what CI runs
nim r tools/build.nim bench     # runtime measurements into baseline/runtime_<algebra>.json
nim r tools/build.nim baseline  # re-record static measurements after an intended change
nim r tools/build.nim guard     # compare the last inspection against the baseline
nim r tools/build.nim gaps      # regenerate gaps.md and the docket from baseline/
nim r tools/build.nim sweep     # dense timings at two to six dimensions, never in CI
```

Builds on **Nim at commit `27763495b`**, and nothing has to be installed for it: koch resolves
the pin itself, from the compiler on `PATH` where it already serves, else one cached under
`~/.cache/koch/nim/<pin>/`, else a clone of `nim-lang/Nim` built at that commit and cached,
paid once per machine (`GUIDE.md`, Toolchain). CI resolves the same pin the same way. No
release will do: the `pga` library spells its operators with seven characters Nim learned to
lex in that commit, and no release carries it yet. The pin is exact, and a pin nothing can
serve is a finding naming the pin and the cache tried, never a fallback to another compiler.

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

Measured on the pinned compiler and library head `0bc4655`: one gap per measurand per
algebra, and the causes above them, every one over but the last, which nothing here can
read; `gaps.md` counts them. Unreviewed by a human. See `PROVENANCE.md` for the figures and
what each subsystem was checked against.

[replications]: https://gitlab.com/mraxilus/replications
