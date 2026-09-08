# audit

Library of checks for the repository, driven by `koch.nim` at the root: it reads the tree as
git sees it and enforces the layout of the two project roots, the form and telegraphic-
comment rules of the constitution, the provenance header with its rules stamp, the glossary
shape, branch scope and Conventional Commits; it restores dependencies through Atlas and
drives every project's tests through testament.

## Build and test

```sh
nim r koch ci                  # from repository root: every check a pull request runs
nim r koch tests curator/audit # this project alone: testament over tests/t*.nim
```

Needs the compiler this project pins in `audit.nimble`, and git; Atlas and testament ship
with Nim.

## Reading order

`src/audit.nim` opens with the bootstrap diagram; read the modules in the order it gives,
then `koch.nim` at the root. The order is not repeated here: a second copy drifts, and this
one had already lost `toolchain` and `plan` within a day of their arrival. Rules are data at
the top of each module; `PROVENANCE.md` records why each is shaped as it is.

## Status

Every check verified by its suite under `tests/`, run through testament on this
project's pinned compiler.
Unreviewed by a human.
