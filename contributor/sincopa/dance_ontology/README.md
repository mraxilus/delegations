# dance_ontology

An executable ontology of the frames that a couple can hold in partner dance, and the moves
between them. It is written for salsa, but nothing in it is specific to salsa. It is two
humanoid bodies, four hands, and the geometry of a face-to-face position.

The model has one state and one relation. A **frame** is what each hand of the lead holds,
and how the arms lie where they overlap. A **move** exists between two frames exactly when
the difference between them is one primitive. Everything else is derived from those two
things: the names, the routes, the audit of the source workbook, the drawings and the browser
validator.

```
                   Right to left               Right-to-right over Left-to-left
                          ^                              ^
                        pass                            cut
                          │                              │
free ── collect ──> Left to left ── collect ──> Left-to-left over Right-to-right
```

The drawings stack this as a tower. `free` is at the foot, and both hands held at the head,
so a collect climbs and a drop falls. `free` is the frame with nothing held, four free hands,
which is where the name comes from.

It is deliberately **not** called `open`. Dancers use "open position" for the hand-to-hand
frame, which this ontology calls `Left-to-right and Right-to-left`. To name the empty frame
`open` would put the two of them under one word. Nothing else here is named for what a dance
calls it, and a frame is named for the hands it holds.

Hands only. A hand that rests on the body of a partner is real, and deliberately absent. It
adds no frame, it takes a turn away, and it is where a wound arm lands. So it belongs with
rotation rather than here.

Beside the ontology stands a body simulator (`sim/`). It is two bodies of the measurements of
the average adult, with jointed arms, and it shares no code with the ontology on purpose. The
notation is a shorthand for two people with arms of a length, and a shorthand cannot check
itself. So the sim is the thing that the notation is a shorthand *for*. It is kept apart in
code, so that what it says is evidence rather than an echo.

It is not kept apart in concepts. It reuses the agreed words of this project wherever one
fits, and coins its own only where none does. To share a word costs the witness nothing,
where to share an assumption would cost it everything. The sim is a witness, and never an
authority. Where its answers meet the words of the ontology (`sim/verdicts.md`), the
translation is printed in one table, and nothing is tuned to make them agree.

## Authority replicated

- The workbook of the Architect, `ontology.partnerwork.xlsx`, sheets `base` and
  `vocabulary`. It is held as data in `src/dance_ontology/workbook.nim`, and audited against
  the derived model by `tests/suites/tworkbook.nim`. **Superseded.** The Architect has replaced it
  with a newer sheet that this project has not been given. So what the audit reports, and the
  sheet-facing half of the review page, are findings about a document no longer in use. Both
  stay running until the new sheet arrives and replaces the transcription.
- The forty drawing rules of the Architect as given, held as data in `design/rules.nim`, and
  mirrored entry for entry in `design/README.md`. `design/checks.nim` holds the pages to them.
- For the body sim, the ANSUR II medians with the AAOS and NASA-STD-3000 joint ranges. Every
  one is in `sim/rig.nim` with its derivation, and `tests/trigid.nim`, `tests/tread.nim` and
  `tests/suites/tlimb.nim` hold the sim to them.

## Build and test

```sh
nim r koch check                                   # root: every check a pull request runs
nim r koch test contributor/sincopa/dance_ontology  # this project alone, every suite of it
nim r tools/build.nim assets                           # faces every page ships, into build/fonts
nim r tools/build.nim pages                            # every page, picture and script, into build/
nim r tools/build.nim verdicts                         # rewrite sim/verdicts.md from the model
nim r tools/build.nim shot                             # screenshot helper, for node and Playwright
```

The first two run from the repository root, and the rest from this directory. This needs
git, and the compiler that this project pins in `dance_ontology.nimble`.

Hand-written pages are committed files. The shells and the prose of the review page live
under `pages/`, and the one hand-drawn proposal under `mockups/`. `tools/build.nim pages`
copies, fills and splices them under `build/`, beside the scripts compiled for them. What a
build emits is never committed, because its lines run far past any width a file may have. To
publish a page is to republish its built file to the URL it already has, listed below.

## Published pages

The validator is the page that the project stands behind. Every other one is a mock-up or an
instrument, kept for reference. `CONTRIBUTOR.md` draws the same line between `pages/` and
`mockups/`, and every published title carries it. A gallery that holds both then says which
is which before either one is opened.

What the project stands behind:

| built file, under `build/` | published at |
| --- | --- |
| app/artifact.html | https://claude.ai/artifact/3skKNwADdEG256v9ucpnvt |

Mock-ups and instruments:

| built file, under `build/` | published at |
| --- | --- |
| design/frames.html | https://claude.ai/artifact/TuDxCFEpKGQBpsLdWvTEq1 |
| design/signs.html | https://claude.ai/artifact/2KCtSbNHhpUwncJRj8Nf9y |
| design/turns-single.html | https://claude.ai/artifact/3DavQ5JHpEPEirY9Xqyb1R |
| design/turns-hands.html | https://claude.ai/artifact/2A95Vd5ydYYX52bQY26owy |
| design/review.html | https://claude.ai/artifact/8dpKVyaBu9qJnXg3hsUyRe |
| design/rig.html | https://claude.ai/artifact/MARvX6rpxW4NQvvvi2xHJa |
| design/wholecloth.html | https://claude.ai/artifact/46HxPCET9ne8c1UNXCKPMb |
| review/review.html | https://claude.ai/artifact/D5D4b2nVNpDFShggYkqi8S |

An old link can refuse a publish until the whole of its live page is read back, and a page then
takes a new link. The change that publishes a page to a new link puts that link in this list.

A page taken out of use keeps whatever URL it was last published at, and is not listed here.
The repository does not rely on a published copy as its record. What a retired page claimed
is in the log, and in `PROVENANCE.md` where it still bears on the design.

## Layout

```
src/dance_ontology.nim             umbrella: bootstrap order, re-exports
src/dance_ontology/frame.nim       frames, their laws, their names, reflection
src/dance_ontology/transition.nim  the two primitives, the two compounds, the routes
src/dance_ontology/diagram.nim     one drawing of a frame, for everything that shows one
src/dance_ontology/map.nim         the whole graph as one picture: frames and moves
src/dance_ontology/spokes.nim      the frame held and every way out of it, and no more
src/dance_ontology/motion.nim      when a drawing moves: the phases and their times
src/dance_ontology/workbook.nim    the base sheet as data, and the audit against it
src/dance_ontology/rotation.nim    the unfinished rotation axis: twist, body, wraps
src/dance_ontology/axle.nim        the rotation axis drawn as an axle of postures
src/dance_ontology/draw/           the shared drawing chain: geometry, style, pose,
                                   body, figure, route, scene, and its own terms
app/app.nim                        the browser validator's script
design/                            the mock-up workbench: rules first, pages after
sim/                               the body sim, standalone on purpose
tools/audit.nim                    the same audit, printed
pages/                             hand-written pages this project stands behind:
                                   app and sim shells, review page's prose
mockups/                           wholecloth.html, hand-drawn proposal to react to
tools/review.nim                   fills the review page's markers from the model
tools/pages.nim, tools/bundle.nim  copy the shells in; fold a page into one file
tools/build.nim                    this project's verbs: pages, modelled, rig, turns,
                                   verdicts, shot, clean
tests/                             the sim's laws (trigid, tread) and the engine's
                                   (tengine); tsaid, in JavaScript; tsuites, which runs
                                   every other suite as one binary from suites/: the laws
                                   over every pair of frames, the tape's (tlimb), the
                                   workbench's gates (tmarks) and the review page
                                   rendered whole (treview)
build/                             every page, picture and script; ignored by git
```

## The validator

`build/app/index.html` shows three things, and so does `artifact.html`, which is the same
page as one self-contained file. It shows the frame you are in, and every frame one primitive
away with the phrase that leads it. It also shows every frame that is *not*, with the way
there spelled out a move at a time. Only what is offered can be clicked, so a move that the
ontology does not derive cannot be danced.

There are three views. **Atlas** is every frame there is, drawn, named and counted. **Dance**
walks the state machine from `free`. **Matrix** is every move there is at once. The page is
usable from the keyboard, and a live region says what was danced, for a reader who cannot see
the drawing.

What the model has to say about the spreadsheet is not in the app. It is a finding about a
document, and it lives in the review page (`build/review/review.html`) and in
`tools/audit.nim`.

The rotation half (`rotation.nim`, `axle.nim`, `tests/suites/trotation.nim`) is on the bench, and
not in the app. 148 postures render as 16 distinct pictures. Level, contact and twist beyond
its parity have no marks yet. The workbench pages (`design/`) are where those marks get
worked out, and the views wait until they are decided.

## What it says

Eight frames exist, and twenty moves join them, each one adding or removing one connection.
Two named compounds, `place` and `cut`, are pairs of those moves that a lead thinks of as
one. They are the two that the vocabulary marks with an asterisk.

The `base` sheet names nine states, seven of them hand-to-hand, and eighteen of its
twenty-seven cells hold between those seven. All eighteen name the same primitive that the
model derives independently. They are every move that exists between those seven states:
nothing missing, and nothing spare.

Three things are outstanding, and the review page sets them out. `free` has no row. `closed`
and `half-closed` need a vocabulary for places on the body. Two words have drifted between
the `base` and `vocabulary` sheets.

Rotation is not modelled beyond what the hand-to-hand model forces. What it forces is in the
review page, along with the four cells worth dancing to settle the rest.

## Status

Every law is under test through testament, on the compiler that this project pins. Those are
the frame and transition laws over every pair of frames, the workbook audit cell by cell, and
the drawings against the model. They are also the laws of the sim over every moment of every
sweep, and the gates of the workbench on every page.

Unreviewed by a human. The design decisions, what was rejected and what each one costs are in
`PROVENANCE.md`. The language of the project is in `GLOSSARY.md`.
