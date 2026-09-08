# probe

Domain-neutral test project under the curator root. It carries the full project shape
and exercises every mechanism the audit enforces: build-time configuration validated
statically, a distinct type over a range, a symbolic operator with a named alias, a
poisoned operator, a Unicode identifier, a section banner, a two-row test matrix, a nimble
file, provenance and glossary. It is also the standing target a merge-process change is
exercised against (CURATOR.md duty 2), since it is the smallest project the matrix can plan.
The throwaway pull request this paragraph once described — a probe branch opened only to be
closed once the jobs reported — was rejected in the same duty: it tested nothing the change's
own pull request and the `push` run after its merge had not.

## Build and test

```sh
nim r koch ci                   # from repository root: every check a pull request runs
nim r koch tests curator/probe  # this project alone, both ring sizes
```

Needs the compiler this project pins in `probe.nimble`, and git. Tests run as a matrix over
`-d:probe.modulus=4` and `-d:probe.modulus=5`.

## Status

Every ring law verified by exhaustive enumeration in both ring sizes. Unreviewed by a human.
