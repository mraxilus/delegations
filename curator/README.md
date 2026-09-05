# curator

Audit tooling for the repository: one Nim program, `audit`, that reads the tree as git sees
it and enforces the layout, the form and telegraphic-comment rules of the constitution, the
provenance header with its rules stamp, the glossary shape, branch scope and Conventional
Commits, then drives every project's own `make check`.

## Build and test

```sh
make check            # from repository root: build audit, audit tree, run every project
make -C curator check # this project alone: testament over tests/t*.nim
```

Needs Nim 2.2.4 (pinned in `.github/workflows/check.yml`), make and git.

## Reading order

`src/audit.nim` opens with the bootstrap diagram. Modules in that order: `findings`,
`domains`, `kinds`, `comments`, `prose`, `form`, `markdown`, `layout`, `provenance`,
`glossary`, `scope`, `commits`, `tree`, `projects`, `audit`. Rules are data at the top of
each module; `PROVENANCE.md` records why each is shaped as it is.

## Status

Every check verified by its suite under `tests/`, run through testament on Nim 2.2.4.
Unreviewed by a human.
