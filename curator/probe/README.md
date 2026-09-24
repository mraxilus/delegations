# probe

The domain-neutral worked example under the curator root. It carries the full project
shape, and it exercises the compile-time mechanisms that the constitution asks for:

- a build-time configuration validated statically;
- a distinct type over a range;
- a symbolic operator with a named alias, and a poisoned operator;
- a Unicode identifier, and a section banner;
- a test matrix over two ring sizes;
- a nimble file, provenance and glossary.

It replicates no authority, and it publishes no page. The static pass reads it on every run,
and `koch list-projects` names it when its own code changes.

## Build and test

```sh
nim r koch check               # from repository root: every check a pull request runs
nim r koch test curator/probe  # this project alone, both ring sizes
```

This needs the compiler that the project pins in `probe.nimble`, and git. The tests run as a
matrix over `-d:probe.modulus=4` and `-d:probe.modulus=5`.

## Status

Every ring law is verified by exhaustive enumeration, in both ring sizes. Unreviewed by a
human.
