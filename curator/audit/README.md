# audit

Library of checks for the repository, driven by `koch.nim` at the root: it reads the tree as
git sees it and enforces the layout of the two project roots, the form and telegraphic-
comment rules of the constitution, the provenance header with its rules stamp, the glossary
shape, branch scope and Conventional Commits; it restores dependencies through Atlas and
drives every project's tests through testament.

## Build and test

```sh
nim r koch ci                  # from repository root: audit, scope, commits
nim r koch tests curator/audit # this project alone: testament over tests/t*.nim
```

Needs the compiler this project pins in `audit.nimble`, and git; Atlas and testament ship
with Nim.

## Reading order

`src/audit.nim` opens with the bootstrap diagram. Modules in that order: `findings`,
`domains`, `kinds`, `comments`, `prose`, `form`, `markdown`, `projects`, `dependencies`,
`layout`, `provenance`, `glossary`, `scope`, `commits`, `tree`, `audit`; then `koch.nim` at
the root. Rules are data at the top of each module; `PROVENANCE.md` records why each is
shaped as it is.

## Status

Every check verified by its suite under `tests/`, run through testament on this
project's pinned compiler.
Unreviewed by a human.
