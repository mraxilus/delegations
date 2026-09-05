# intervals

Ordered pitch-class intervals, transposition and inversion in twelve-tone equal temperament.
A deliberately small first project: it exists to exercise the repository's contributor
process end to end, and to be correct while doing so.

Authority replicated: [Open Music Theory](https://openmusictheory.github.io/), pages
*Pitch (class)*, *Interval (class)*, *Transposition* and *Intervals*. Suites are named after
those pages and every assertion cites the claim it checks.

## Build and test

```sh
make check                      # from repository root: audit, then this project's tests
make -C abstand/intervals check # this project alone: testament over both spellings
```

Needs Nim 2.2.4, make and git. Tests run as a matrix over `-d:intervals.spelling=sharp` and
`-d:intervals.spelling=flat`.

## Status

Every operation verified by exhaustive enumeration of all 144 pitch-class and interval
pairs, in both spellings. Unreviewed by a human. Diatonic spelling and compound intervals
are out of scope by design; see `PROVENANCE.md`.

Probe of the merge process after the `make ci` change; this branch is never merged.
