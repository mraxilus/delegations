# dance_ontology

An executable ontology of the frames a couple can hold in partner dance, and the moves
between them. Written for salsa, but nothing in it is salsa-specific: it is two humanoid
bodies, four hands and the geometry of facing each other.

The model has one state and one relation. A **frame** is what each of the lead's hands
holds and how the arms lie where they overlap. A **move** exists between two frames exactly
when the difference between them is one primitive. Everything else, the names, the routes,
the audit of the source workbook, the drawings and the browser validator, is derived from
those two things.

```
                   Right to left               Right-to-right over Left-to-left
                          ^                              ^
                        pass                            cut
                          │                              │
free ── collect ──> Left to left ── collect ──> Left-to-left over Right-to-right
```

The drawings stack this as a tower: `free` at the foot, both hands held at the head, so a
collect climbs and a drop falls. `free` is the frame with nothing held, four free hands,
which is where the name comes from. It is deliberately **not** called `open`: dancers use
"open position" for the hand-to-hand frame, which this ontology calls `Left-to-right and
Right-to-left`, so naming the empty frame `open` would put the two of them under one word.
Nothing else here is named for what a dance calls it; a frame is named for the hands it
holds.

Hands only. A hand resting on a partner's body is real and deliberately absent: it adds no
frame, it takes a turn away, and it is where a wound arm lands, so it belongs with rotation
rather than here.

Beside the ontology stands a body simulator (`sim/`): two bodies of the average adult's
measurements with jointed arms, sharing no code and no vocabulary with the ontology on
purpose. The notation is a shorthand for two people with arms of a length, and a shorthand
cannot check itself, so the sim is the thing it is a shorthand *for*, kept separate so that
what it says is evidence rather than an echo. The sim is a witness, never an authority:
where its answers meet the ontology's words (`sim/verdicts.md`) the translation is printed
in one table and nothing is tuned to make them agree.

## Authority replicated

- The Architect's workbook `ontology.partnerwork.xlsx`, sheets `base` and `vocabulary`, held
  as data in `src/dance_ontology/workbook.nim` and audited against the derived model by
  `tests/tworkbook.nim`. **Superseded.** The Architect has replaced it with a newer sheet
  this project has not been given, so what the audit reports, and the sheet-facing half of the
  review page, are findings about a document no longer in use. Both stay running until the
  new sheet arrives and replaces the transcription.
- The Architect's forty drawing rules as given, held as data in `design/rules.nim` and
  mirrored entry for entry in `design/README.md`; `design/checks.nim` holds the pages to them.
- For the body sim, the ANSUR II medians with the AAOS and NASA-STD-3000 joint ranges,
  every one in `sim/rig.nim` with its derivation; `tests/tlaws.nim` holds the sim to them.

## Build and test

```sh
nim r koch ci                                          # repository root: audit, scope, commits
nim r koch tests contributor/síncopa/dance_ontology    # this project alone, its eleven suites
nim r tools/build.nim pages                            # every page, picture and script, into build/
nim r tools/build.nim verdicts                         # rewrite sim/verdicts.md from the model
nim r tools/build.nim shot                             # screenshot helper, for node and Playwright
```

The first two run from the repository root, the rest from this directory. Needs Nim 2.2.4
and git. Hand-written pages are committed files: the shells and the review page's prose live
under `pages/`, the one hand-drawn proposal under `mockups/`, and `tools/build.nim pages`
copies, fills and splices them under `build/` beside the scripts compiled for them. What a
build emits is never committed, its lines running far past any width a file may have.
Publishing a page is republishing its built file to the artifact URL listed in
`design/README.md` or `sim/README.md`.

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
tools/build.nim                    this project's verbs: pages, verdicts, shot, clean
tests/                             the laws, over every pair of frames; the sim's laws
                                   (tlaws); the workbench's gates (tmarks); the review
                                   page rendered whole (treview)
build/                             every page, picture and script; ignored by git
```

## The validator

`build/app/index.html` (and `artifact.html`, the same page as one self-contained file) shows
the frame you are in, every frame one primitive away with the phrase that leads it, and
every frame that is *not*, with the way there spelled out a move at a time. Only what is
offered can be clicked, so a move the ontology does not derive cannot be danced. Three
views: **Atlas** is every frame there is, drawn, named and counted; **Dance** walks the
state machine from `free`; **Matrix** is every move there is at once. The page is usable
from the keyboard, and a live region says what was danced for a reader who cannot see the
drawing. What the model has to say about the spreadsheet is not in the app: it is a finding
about a document, and it lives in the review page (`build/review/review.html`) and in
`tools/audit.nim`.

The rotation half (`rotation.nim`, `axle.nim`, `tests/trotation.nim`) is on the bench and
not in the app: 148 postures render as 16 distinct pictures, because level, contact and
twist beyond its parity have no marks yet. The marks are being worked out on the workbench
pages (`design/`), and the views wait until they are decided.

## What it says

Eight frames exist and twenty moves join them, each adding or removing one connection. Two
named compounds, `place` and `cut`, the two the vocabulary marks with an asterisk, are pairs
of those moves that a lead thinks of as one. The `base` sheet names nine states, seven of
them hand-to-hand, and eighteen of its twenty-seven cells hold between those seven. All
eighteen name the same primitive the model derives independently, and they are every move
that exists between those seven states: nothing missing, nothing spare.

Three things are outstanding, set out in the review page: `free` has no row, `closed` and
`half-closed` need a vocabulary for places on the body, and two words have drifted between
the `base` and `vocabulary` sheets. Rotation is not modelled beyond what the hand-to-hand
model forces; what it forces is in the review page, along with the four cells worth dancing
to settle the rest.

## Status

Every law under test through testament on Nim 2.2.4: the frame and transition laws over
every pair of frames, the workbook audit cell by cell, the drawings against the model, the
sim's laws over every moment of every sweep, and the workbench's gates on every page.
Unreviewed by a human. Design decisions, what was rejected and what each costs are in
`PROVENANCE.md`; the project's language is in `GLOSSARY.md`.
