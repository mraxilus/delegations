# knoller

The fixers of Nim source that read the text of one file alone, and the checks that those
fixers clear. `koch fix` runs them through `curator/audit`, which keeps each fixer that asks the
compiler. `audit` imports knoller by a relative path.

Authority replicated: none. The rules are those of `CONSTITUTION.md` and `STYLE.md`.

## Build and test

```sh
nim r koch test curator/knoller  # this project alone: every suite, as one program
nim r koch check                 # every check a pull request runs
```

This needs the compiler that the project pins in `knoller.nimble`, and git.

## Published pages

None. Knoller publishes no page.

## Status

The project holds its shape and the suite of its imports. Unreviewed by a human.
