# pga_benchmark

Benchmark and standing gap list for `pga`, the projective geometric algebra library
replicated from Eric Lengyel's *Projective Geometric Algebra Illuminated* and developed in
[replications][replications]. Every operation the library exports is measured against a
hand-rolled typed reference derived from Lengyel's own optimal forms, on four axes:
allocations, data movement and copies, multiply and add counts, and time. The counts are
read out of the C the compiler emits, so a regression in them is a deterministic finding;
the timings are figures taken by hand on a named machine.

The library is a pinned dependency restored by Atlas, never a copy. The reference is Nim
written here in 64-bit floats, so both sides run the same scalar; Lengyel's Terathon Math
Library (MIT) was read to cross-check the forms and their counts, and nothing from it is
copied.

The list is [`gaps.md`](gaps.md): ten design gaps decided by rule, then one row per
operation per algebra with both sides' figures and a stable identifier. It is generated from
`baseline/` and never edited by hand.

## Build and test

```sh
nim r koch ci                                     # repository root: audit, scope, commits
nim r koch tests contributor/ronri/pga_benchmark  # this project alone, every configuration
nim r tools/build.nim drive     # project directory: inspect, check, hold gaps.md; what CI runs
nim r tools/build.nim bench     # time every probe, record baseline/bench_<algebra>.json
nim r tools/build.nim baseline  # re-record counts after an intended change to the library
nim r tools/build.nim gaps      # regenerate gaps.md and the ledger from baseline/
nim r tools/build.nim sweep     # dense timings at two to six dimensions, never in CI
```

Needs **Nim built from commit `27763495b`** on `PATH`, and git. No release will do: the
`pga` library spells its operators with seven characters Nim learned to lex in that commit,
and no release carries it yet. Build it with `git clone https://github.com/nim-lang/Nim &&
git checkout 27763495b && sh build_all.sh`; koch and CI do the same and cache the result
per commit. The pin is exact and the audit enforces it: running the suites on any other
compiler is a finding, not a warning.

## Layout

```
src/pga_benchmark.nim            umbrella: configuration name and re-exports
src/pga_benchmark/catalogue.nim  every operation as data, per algebra
src/pga_benchmark/reference/     Lengyel's typed objects and forms, rigid 4D and conformal 5D
src/pga_benchmark/bridge.nim     typed objects into and out of the dense multivector
src/pga_benchmark/pools.nim      seeded operand pools, both sides
src/pga_benchmark/probes.nim     timed loops emitted from the catalogue
src/pga_benchmark/bench.nim      entry: run every probe, write figures
src/pga_benchmark/inspector.nim  read counts out of emitted C
src/pga_benchmark/model.nim      bytes moved from counts and sizes
src/pga_benchmark/inspect.nim    entry: read one nimcache, write counts
src/pga_benchmark/baseline.nim   compare counts against baseline
src/pga_benchmark/gaps.nim       rows, ledger, design gaps, rendering
tools/build.nim                  driver verbs
baseline/                        committed counts, bench records and ledger
tests/                           suites and one testament stub per algebra
```

## Status

Measured on the pinned compiler and library head `0bc4655`: 315 rows across four algebras,
ten design gaps, all open but the last, which nothing here can read. Unreviewed by a human.
See `PROVENANCE.md` for the figures and what each subsystem was checked against.

[replications]: https://gitlab.com/mraxilus/replications
