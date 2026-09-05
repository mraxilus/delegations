# probe

Domain-neutral test project under the curator root. It carries the full project shape
and exercises every mechanism the audit enforces: build-time configuration validated
statically, a distinct type over a range, a symbolic operator with a named alias, a
poisoned operator, a Unicode identifier, a section banner, a two-row test matrix, a nimble
file, provenance and glossary. It is also the standing target of merge-process probes
(CURATOR.md duty 2): a probe branch `curator/probe/probe-<name>` appends one line to this
file, opens a pull request, and is closed unmerged once the three jobs report.

## Build and test

```sh
nim r koch ci                 # from repository root: audit, scope, commits
nim r koch tests curator/probe  # this project alone, both ring sizes
```

Needs Nim 2.2.4 and git. Tests run as a matrix over `-d:probe.modulus=4` and
`-d:probe.modulus=5`.

## Status

Every ring law verified by exhaustive enumeration in both ring sizes. Unreviewed by a human.
