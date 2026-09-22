# audit

The library of checks for the repository, driven by `koch.nim` at the root. It reads the tree
as git sees it, and it enforces:

- the layout of the two project roots;
- the form and telegraphic-comment rules of the constitution;
- the Simplified Technical English of the root documents and of every project record;
- the provenance header with its rules stamp, and the shape of a glossary;
- branch scope and Conventional Commits.

It also restores dependencies through Atlas, and drives the tests of every project through
testament.

## Build and test

```sh
nim r koch ci                  # from repository root: every check a pull request runs
nim r koch tests curator/audit # this project alone: testament over tests/t*.nim
```

This needs the compiler that the project pins in `audit.nimble`, and git. Atlas and testament
ship with Nim.

## Where to start

`src/audit.nim` opens with the bootstrap diagram. Read the modules in the order that it
gives, then `koch.nim` at the root. The order is not repeated here, because a second copy
drifts. This one had already lost `toolchain` and `plan` within a day of their arrival. The
rules are data at the top of each module, and `PROVENANCE.md` records why each one is shaped
as it is.

## Status

Every check is verified by its suite under `tests/`, run through testament on the compiler
that this project pins. Unreviewed by a human.
