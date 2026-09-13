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

## Build and test

```sh
nim r koch ci                                     # repository root: audit, scope, commits
nim r koch tests contributor/ronri/pga_benchmark  # this project alone, every configuration
```

Needs **Nim built from commit `27763495b`** on `PATH`, and git. No release will do: the
`pga` library spells its operators with seven characters Nim learned to lex in that commit,
and no release carries it yet. Build it with `git clone https://github.com/nim-lang/Nim &&
git checkout 27763495b && sh build_all.sh`; koch and CI do the same and cache the result
per commit. The pin is exact and the audit enforces it: running the suites on any other
compiler is a finding, not a warning.

## Status

Project shape only; nothing measured yet. Unreviewed by a human.

[replications]: https://gitlab.com/mraxilus/replications
