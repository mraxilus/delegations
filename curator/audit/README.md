# audit

The checker of the repository, driven by `koch.nim` at the root. It reads the tree as git sees
it, and reports each broken rule as a finding. It also restores dependencies through Atlas,
and runs the suites of every project through testament.

What it enforces is listed once, in `CURATOR.md` under "Checks reference", and in the root
`README.md` under "Branches and checks".

Authority replicated: none. The checker holds the rules of this repository, and mirrors no
book, paper or standard.

## Build and test

```sh
nim r koch tests curator/audit # this project alone: testament over tests/t*.nim
nim r koch ci                  # from repository root: every check a pull request runs
```

This needs the compiler that the project pins in `audit.nimble`, and git. Atlas and testament
ship with Nim, and koch fetches the pinned compiler where nothing on the machine serves it.

## Published pages

None. The checker publishes no page.

## Where to start

Read the modules in the order that their `import` lines give, then `koch.nim` at the root.
`src/audit.nim` is the umbrella, and it does not restate that order, because a second copy
drifts. The rules are data at the top of each module, and `PROVENANCE.md` records why each one
is shaped as it is.

## Status

Each check module has its suite under `tests/`, run through testament on the compiler that
this project pins, and `checker.nim` reports a module without one. The shell steps of
`ledger.yml` and `watch.yml` have no suite. They are verified by hand through a stub for `gh`,
as `PROVENANCE.md` records. Unreviewed by a human.
