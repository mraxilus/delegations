# pga_benchmark

The benchmark and standing gap list for `pga`. That library is projective geometric algebra,
replicated from *Projective Geometric Algebra Illuminated* by Eric Lengyel, and developed in
[replications][replications].

The goal is one question, kept answered at library head: how far is each operation from what
it could spend, and which change closes the distance? Every operation that the library exports
is a measurand. Each one carries two lower bounds. The multivector lower bound is what the
algebra demands of any dense implementation. The type optimised lower bound is what a
hand-rolled typed reference spends, derived from Lengyel's own forms.

## Pages

Three kinds of page answer the question. Each one is built from committed files alone, and
`drive` holds each file to the library at pin, and the pin to library head.

| Page | Kind | What it shows |
|------|------|---------------|
| [Gap docket][docket] | monitoring | every measurand at pin against both lower bounds |
| [Marginalia][marginalia] | monitoring | library at pin: changes tried, and notes in its margin |
| [Cayley derivation][cayley-derivation] | design | every Cayley table derived from three |
| [Typed multivectors][typed-multivectors] | design | concrete k-vector types for any dimension |

A **monitoring** page shows the library as it is. A **design** page shows a future state of
the library, argued in its `design.md` and checked by its trial. Each design has the same shape,
so the next exploration starts from the same frame.

## What pages are built from

| Directory | What it holds | Read by |
|-----------|---------------|---------|
| `baseline/` | measurements at pin, and the docket of identifiers | docket, `gaps.md` |
| `changes/` | one small change to the library for each file: why, then quoted edits | marginalia |
| `designs/<name>/` | `design.md`, optional `change.md`, `claims.json`, and programs | design page |
| `trials/` | what each change or design measured when tried at pin | marginalia, designs |
| `marginalia/notes.md` | notes on library source, each quoting the lines it is about | marginalia |
| `pages/` | shell every page is built in, and register of published pages | every page |

A change, a design and a note quote the library, and never give a line number. A quote that
does not occur once at pin is a finding, so no file points at lines that say something else.
The list of gaps is [`gaps.md`](gaps.md), generated from `baseline/` and never edited by hand.
The words are in [`GLOSSARY.md`](GLOSSARY.md).

## When the library moves

`drive` fails while the pin lags library head. To follow head:

1. Bump the commit in `pga_benchmark.nimble` and `atlas.lock`, and restore with
   `nim r koch deps`.
2. Re-take every measurement: `baseline`, then `bench`, then `gaps`.
3. Re-quote each change, design and note that `drive` names, then run `trial all`.
4. Run `pages`, publish each page that `drive` names, and record each one with
   `published <name> <url>`.

## Build and test

```sh
nim r koch check                                # repository root: every check a pull request runs
nim r koch test contributor/ronri/pga_benchmark  # this project alone, on the pinned compiler
nim r tools/build.nim drive      # project directory: every check CI runs, head included
nim r tools/build.nim bench      # runtime measurements into baseline/runtime_<algebra>.json
nim r tools/build.nim baseline   # re-record static measurements after an intended change
nim r tools/build.nim guard      # compare the last inspection against the baseline
nim r tools/build.nim gaps       # regenerate gaps.md and the docket from baseline/
nim r tools/build.nim trial all  # try every change and design at pin, into trials/
nim r tools/build.nim pages      # build every page into build/<name>.html
nim r tools/build.nim sweep      # dense timings at two to six dimensions, never in CI
```

The pin is **Nim at commit `27763495b`**, and no release serves it. Koch fetches and builds it
once for each machine (`GUIDE.md`, Toolchain). The record says which characters of `pga` need
it.

## Layout

```
src/pga_benchmark.nim              umbrella: algebra name and re-exports
src/pga_benchmark/catalogue.nim    every measurand as data, per algebra
src/pga_benchmark/reference/       Lengyel's typed objects and forms, rigid 4D and conformal 5D
src/pga_benchmark/widening.nim     typed objects into and out of the dense multivector
src/pga_benchmark/pools.nim        seeded operand pools, both implementations
src/pga_benchmark/measurements.nim timed loops emitted from the catalogue
src/pga_benchmark/bench.nim        entry: runtime measurements of every measurand
src/pga_benchmark/inspector.nim    static measurements read out of emitted C
src/pga_benchmark/model.nim        movement from counts and sizes
src/pga_benchmark/bound.nim        multivector lower bound, derived from the algebra
src/pga_benchmark/inspect.nim      entry: static measurements of one nimcache
src/pga_benchmark/guard.nim        compare static measurements against the baseline
src/pga_benchmark/gaps.nim         gaps, causes, docket, rendering
src/pga_benchmark/markdown.nim     records read as blocks, and rendered for pages
src/pga_benchmark/changes.nim      changes: quoted edits, applied at pin
src/pga_benchmark/notes.nim        notes on library source, anchored by quote
src/pga_benchmark/designs.nim      design directories: record, change, claims
src/pga_benchmark/trials.nim       try change or design on copy of library at pin
src/pga_benchmark/head.nim         hold pin to head, and every file and page to pin
src/pga_benchmark/pages/           shell assembly, and one renderer per page kind
tools/build.nim                    driver verbs
tests/                             suites, and the testament stubs that run them
```

## Status

Measured on the pinned compiler and on library head `bd6b23c`, which is the pin. The library
stands above both lower bounds; `gaps.md` counts the gaps, and the docket shows each one.
Unreviewed by a human. See `PROVENANCE.md` for the figures, and for what each subsystem was
checked against.

[replications]: https://gitlab.com/mraxilus/replications
[docket]: https://claude.ai/artifact/XyT583x9RnTKixers2q4gT
[marginalia]: https://claude.ai/artifact/6WwLfdHiisCtGWUcFxibBM
[cayley-derivation]: https://claude.ai/artifact/2fi2hTpobqChXSTPq4vB6q
[typed-multivectors]: https://claude.ai/artifact/V34TAWXNvrHBGN9fNBWYWX
