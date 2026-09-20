# probe

The domain-neutral test project under the curator root. It carries the full project shape,
and it exercises every mechanism that the audit enforces:

- a build-time configuration validated statically;
- a distinct type over a range;
- a symbolic operator with a named alias, and a poisoned operator;
- a Unicode identifier, and a section banner;
- a two-row test matrix;
- a nimble file, provenance and glossary.

It is also the standing target for a merge-process change (CURATOR.md duty 2). It is the
smallest project that the matrix can plan. This paragraph once described a throwaway pull
request, opened only to be closed once the jobs reported. The same duty rejected that. It
tested nothing that the change's own pull request and the later `push` run had not tested.

## Build and test

```sh
nim r koch ci                   # from repository root: every check a pull request runs
nim r koch tests curator/probe  # this project alone, both ring sizes
```

This needs the compiler that the project pins in `probe.nimble`, and git. The tests run as a
matrix over `-d:probe.modulus=4` and `-d:probe.modulus=5`.

## Status

Every ring law is verified by exhaustive enumeration, in both ring sizes. Unreviewed by a
human.
