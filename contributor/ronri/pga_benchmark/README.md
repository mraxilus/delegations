# pga_benchmark

The benchmark and standing gap list for `pga`. That library is projective geometric algebra,
replicated from *Projective Geometric Algebra Illuminated* by Eric Lengyel, and developed in
[replications][replications].

The goal is one question, kept answered at library head. How far is each operation from what it
could spend, and which change closes the distance? Every operation that the library exports
is a measurand. Each one carries two lower bounds. The multivector lower bound is what the
algebra demands of any dense implementation. The type optimised lower bound is what a
hand-rolled typed reference spends, derived from Lengyel's own forms.

## Pages

Three kinds of page answer the question. Each one is built from committed files alone.
`drive` holds each file to the library at pin, and `head` holds the pin to library head.
`drive` also renders each page, and fails where a face of the system draws a character beyond
ASCII. A control page beside them proves that the render sees.

| Page | Kind | What it shows |
|------|------|---------------|
| [Gap docket][docket] | monitoring | every measurand at pin against both lower bounds |
| [Marginalia][marginalia] | monitoring | library at pin: changes tried, and notes in its margin |
| [Proposals][proposals] | list | every proposal, graph of what each blocks, each read in place |
| [P01 Cayley derivation][cayley-derivation] | proposal | every Cayley table derived from three |
| [P02 Typed multivectors][typed-multivectors] | withdrawn | k-vector types, folded into P04 |
| [P03 Partner sign][partner-sign] | proposal | sign of partner folded into its first table |
| [P04 Exact kinds][exact-kinds] | proposal | product returns exactly bases it reaches |
| [P05 Multivector align][multivector-align] | proposal | multivector aligned to one cache line |
| [P06 Float width][float-width] | proposal | width of each float as a build option |
| [P07 Part scale][part-scale] | proposal | each part compared at its own scale |

A **monitoring** page shows the library as it is. A **proposal** page shows a future state of
the library, argued in its `proposal.md` and checked by its evaluation. Each proposal has the
same shape, so the next exploration starts from the same frame. Each proposal page states what
the proposal depends on, and what its rejection blocks. The **list** page names every proposal,
draws the undecided ones as a graph, and shows each selected proposal in place.

## What pages are built from

| Directory | What it holds | Read by |
|-----------|---------------|---------|
| `baseline/` | measurements at pin, and the docket of identifiers | docket, `gaps.md` |
| `changes/` | one small change to the library for each file: why, then quoted edits | marginalia |
| `proposals/<NN>-<name>/` | `proposal.md`, `change.md` if any, `claims.json`, programs | its page |
| `evaluations/` | what each change or proposal measured when tried at pin | marginalia, proposals |
| `marginalia/notes.md` | notes on library source, each quoting the lines it is about | marginalia |
| `pages/` | shell every page is built in, figures that proposals embed, publications | every page |

A change, a proposal and a note quote the library, and never give a line number. A quote that
does not occur once at pin is a finding, so no file points at lines that say something else.
The list of gaps is [`gaps.md`](gaps.md), generated from `baseline/` and never edited by hand.
The words are in [`GLOSSARY.md`](GLOSSARY.md).

## When the library moves

`head` fails while the pin lags library head. The daily `head` workflow runs it and keeps
one issue open until the pin follows. To follow head:

1. Bump the commit in `pga_benchmark.nimble` and `atlas.lock`, and restore with
   `nim r koch fetch-deps`.
2. Re-take the static counts with `baseline`, and re-quote each change, proposal and note that
   `drive` names.
3. Run `restamp`. It moves each timed record whose builds emit the same C to the pin, and names
   each other one. Re-take those with `bench`, `sweep` or `evaluate <name>`.
4. Run `gaps` and `pages`, publish each page that `drive` names, and record each one with
   `published <name> <url>`.

## Build and test

```sh
nim r koch check                                # repository root: every check a pull request runs
nim r koch test contributor/ronri/pga_benchmark  # this project alone, on the pinned compiler
nim r tools/build.nim types         # type-check the render harness, with no browser
nim r tools/build.nim drive         # project directory: every check CI runs, all at pin
nim r tools/build.nim head          # compare pin with library head, as the daily workflow does
nim r tools/build.nim bench         # five alternating runs into baseline/runtime_<algebra>.json
nim r tools/build.nim baseline      # re-record static measurements after an intended change
nim r tools/build.nim guard         # compare the last inspection against the baseline
nim r tools/build.nim gaps          # regenerate gaps.md and the docket from baseline/
nim r tools/build.nim evaluate all  # try every change and proposal at pin, into evaluations/
nim r tools/build.nim evaluate all --thorough  # the same, at rga3d and cga4d as well
nim r tools/build.nim restamp       # move timed records to the pin where their C is the same
nim r tools/build.nim pages         # build every page into build/<name>.html
nim r tools/build.nim sweep         # five runs at two to six dimensions, into baseline/sweep.json
```

`drive` fetches the Chromium that Playwright pins. Set `PGA_CHROMIUM` to the path of a Chromium
executable, and `drive` uses that one instead. `types` and `drive` need node and npm on `PATH`,
and `nim r tools/build.nim system` names every system package.

The pin is **Nim at commit `27763495b`**, and no release serves it. Koch fetches and builds it
once for each machine (`GUIDE.md`, Toolchain). The record says which characters of `pga` need
it.

## Layout

```
src/pga_benchmark.nim              umbrella: algebra name and re-exports
src/pga_benchmark/catalogue.nim    every measurand as data, per algebra
src/pga_benchmark/reference/       Lengyel's typed objects and forms, rigid 4D and conformal 5D
src/pga_benchmark/widening.nim     typed objects into and out of the dense multivector
src/pga_benchmark/pools.nim        seeded operand pools, every implementation
src/pga_benchmark/measurements.nim timed loops emitted from the catalogue
src/pga_benchmark/bench.nim        entry: runtime measurements of every measurand
src/pga_benchmark/inspector.nim    static measurements read out of emitted C
src/pga_benchmark/model.nim        movement from counts and sizes
src/pga_benchmark/bound.nim        multivector lower bound, derived from the algebra
src/pga_benchmark/dense.nim        dense form of each general measurand, from library's tables
src/pga_benchmark/inspect.nim      entry: static measurements of one nimcache
src/pga_benchmark/guard.nim        compare static measurements against the baseline
src/pga_benchmark/gaps.nim         gaps, causes, docket, rendering
src/pga_benchmark/markdown.nim     records read as blocks, and rendered for pages
src/pga_benchmark/changes.nim      changes: quoted edits, applied at pin
src/pga_benchmark/notes.nim        notes on library source, anchored by quote
src/pga_benchmark/proposals.nim    proposal directories: record, change, claims
src/pga_benchmark/evaluations.nim  try change or proposal on copy of library at pin
src/pga_benchmark/head.nim         hold pin to head, and every file and page to pin
src/pga_benchmark/pages/           shell assembly, one renderer per page kind, docket's search
tools/build.nim                    driver: every verb, standard library alone
tools/verbs.nim                    each verb that compiles project code, run through the driver
tools/drive/                       render harness: font stack of each element against faces shipped
tests/                             suites, the testament stubs that run them, and the render control
```

## Status

Measured on the pinned compiler and on library head `edb0c9d`, which is the pin. Times were
taken at `d9be8ae`, whose builds emit the same C. The library
stands above both lower bounds; `gaps.md` counts the gaps, and the docket shows each one.
Unreviewed by a human. See `PROVENANCE.md` for the figures, and for what each subsystem was
checked against.

[replications]: https://gitlab.com/mraxilus/replications
[docket]: https://claude.ai/artifact/XyT583x9RnTKixers2q4gT
[marginalia]: https://claude.ai/artifact/6WwLfdHiisCtGWUcFxibBM
[proposals]: https://claude.ai/artifact/CW9ZL5eotsVYrZPjMnTLoG
[cayley-derivation]: https://claude.ai/artifact/2fi2hTpobqChXSTPq4vB6q
[typed-multivectors]: https://claude.ai/artifact/V34TAWXNvrHBGN9fNBWYWX
[partner-sign]: https://claude.ai/artifact/2fUYLonsQo7ejouCvCnpWf
[exact-kinds]: https://claude.ai/artifact/UPfjVLGbsVLBz756DMkPJe
[multivector-align]: https://claude.ai/artifact/AB3BNtWPEzguWswwnx5ckh
[float-width]: https://claude.ai/artifact/Q3R1yz93Drk7Cwq5qhymDZ
[part-scale]: https://claude.ai/artifact/6hW9rjiotnjdjBVwatW5Dj
