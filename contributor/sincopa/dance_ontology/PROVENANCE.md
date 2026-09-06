# Provenance

| Field  | Value |
|--------|-------|
| Agent  | Claude Code |
| Author | Claude |
| Date   | 2026-09-06 |
| Style  | CONSTITUTION.md and STYLE.md, followed. |
| Rules  | 73a6fa37de648f53 |
| Review | **Unreviewed.** Nothing here has been read line by line by a human. |

Origin: built from the Architect's workbook `ontology.partnerwork.xlsx` (sheets `base` and
`vocabulary`, held as data in `src/dance_ontology/workbook.nim`), the Architect's forty
drawing rules as given (held as data in `design/rules.nim`), and, for the body sim, the ANSUR
II medians with the AAOS and NASA-STD-3000 joint ranges (`sim/rig.nim`). No vendored source.

That workbook is **superseded**: the Architect has replaced it with a newer sheet this project
has not been given. Nothing is deleted, so nothing goes dark, but every finding the audit
reports is about a document no longer in use, and so is the sheet-facing half of the review
page. Transcription, audit, suite and page are replaced together in one delivery when the new
sheet arrives; until then they are stale by construction, not by neglect.

## Language

**Every term is agreed with Architect before it is written.** Forty-four terms written
without agreement were removed on 2026-09-06 and are in history. Thirty-seven are now agreed,
each concept set out with candidate names and their costs, and only selected name written.
Audit checks glossary's shape and never its words, so this holds by Architect's reading
alone.

**Sim is isolated in code, not in concepts.** It reuses agreed words wherever one fits and
coins its own only where none does; four are its own -- rig, pose, strain, block. What keeps
it witness is that it imports nothing from `src/` and is told no answer, never that it speaks
other language. Care is needed only where sim *measures* what ontology *asserts*: there
translation stays visible (`sim/verdicts.nim`), since assumed identity would be echo.

Held back by decision, not omission. Workbook, base sheet and vocabulary sheet wait until new
sheet arrives, since nothing should be written about file this project has not seen. Review
page waits on same sheet; ledger waits on forty rules being reconciled. Sweep, stance, moment,
rest, re-organised, room and verdict are sim's method rather than dance, and earn no entry;
neither does sim's `(led)` mark, nor its point where hands meet, `Grip` naming manner of
holding instead.

**`Block` now describes code rather than specifying it.** Term says turn stops "because no
small move holds and no reachable pose does", and that is **verified**: `tests/tcarry.nim`
walks every one-hand hold over the crown two whole turns each way and holds page to naming
what refuses wherever it stops. It was assumed until 2026-09-06, when page gated carried
poses through `agrees` where sweep accepted them, looked no further than coarse grid before
calling block, and never set `overhead` -- so hands above head were pulled to point between
two dancers instead of over head of whoever turns. `L-l` and `R-r` stopped after quarter of
turn where sweep found no block in two and half. Moment's decision is written once now, in
`sweep.advanced`, and both paths take it (Article II.1).

Agreed words disagree with code in fourteen places, recorded rather than acted on. From
hand-to-hand half: `frame.position` means opposite of `Frame position`, stripping `over` and
returning frame hold said aloud; `Frame` and `rotation.Posture` split across frame state
rather than along it; `isFacing` returns parity of twist where facing is four-valued; twist is
counted in quarters where `HalfTurns` is half turns; `Level.Above` is `Overhead`; `Compound`
is `Compound move`; drawing chain's `route` and `wind` are `Transition` and `Twist`. From sim:
`Band` is `Level` and its members Low, High and Overhead; `Body.One` and `.Two` are Lead and
Follow; `Aspect.Fore` and `.Aft` are Wrap and Lock; `Link` is `Connection` and `page.Hold` is
`Frame hold`, both words already on avoid lines; and `Move`, `Twist`, `Chain`, `Way` and
`overhead` each name something in sim unrelated to agreed term of same spelling.

**Review page's layout block was stale in five ways, and is corrected.** Curator left one
line for this project's hand -- domain folder printed as `síncopa` where it is now `sincopa`.
Four more were false beside it: `transition.nim` was said to hold four primitives where it
holds two; `app/shell.nim` and `tools/review_prose.nim` were named though this project's own
earlier delivery moved them to `pages/`; and build was invoked as `make`, retired since. Going
past one line was deliberate: block named three files that do not exist, two of them removed
by this project, and page is read by Architect. Its wording still uses `validator` and
`primitives` where agreed words are `Reference` and `Move`; that is vocabulary sweep of whole
page, not this fix.

**Three faults live in generated output, not merely pending renames.** `sim/verdicts.md`
prints `above` and `X`, both on avoid lines, where agreed words are Overhead and Cross. It
prints `her arm` and `his arm` in every sweep table, avoided for Follow and Lead. Translation
table stands in three copies -- `sim/verdicts.nim`, `design/turns.nim`, `sim/page.nim` -- and
has drifted: `turns.nim` dropped `elbow forward` clause `verdicts.nim` adds (Article II.1).
Two reader surfaces also disagree, `verdicts.nim` translating to wrap and lock where sim
page's `lies` prints "across the front" untranslated.

## Model

**One state and one relation, everything else derived.** A `Frame` is what each of the
lead's hands holds and how the arms lie where they overlap; a move exists between two frames
exactly when their difference is one primitive (`collect` adds a connection, `drop` removes
one), and the two compounds (`place`, `cut`) are the pairs of primitives the vocabulary marks
with an asterisk. Names, keys, slugs, routes and reflection are all read off the frame
(`frame.nim`, `transition.nim`). Rejected: naming frames for what a dance calls them, which
puts the hand-to-hand frame and the empty frame under one word (`open`); the empty frame is
`free`. Cost: `closed` and `half-closed`, which rest a hand on a body, have no frame here and
wait on a vocabulary for places on the body. Verified by `tframe.nim` and `ttransition.nim`
over every pair of the eight frames (64 pairs, exhaustive): validity, naming round trips,
reversibility, mirror symmetry, one law per primitive, full connectivity.

**The workbook is data, audited, never trusted.** `workbook.nim` holds the `base` sheet's
states and cells and the `vocabulary` sheet's words as constants and derives findings by kind
(cell names a move the model lacks, model has a move the sheet lacks, helper word differs,
cell waits on the body). Verified by `tworkbook.nim`: eighteen of twenty-seven cells are
checkable today and all eighteen name the primitive the model derives, nothing missing and
nothing spare; the nine deferred cells are counted, not hidden.

**Rotation is provisional and off the page.** `rotation.nim` holds twist, the three arm
heights, the two ceilings, blockers, wraps and locks, and the measured fact that a low wrap
holds half a turn where everything else holds a whole one; `axle.nim` draws its postures as
one line placed by the twist itself. The views do not show it: 148 postures render as 16
distinct pictures because level, contact and twist beyond its parity have no marks, and a
validator whose picture cannot tell two states apart is not validating. Verified by
`trotation.nim` and `taxle.nim`; the capacity constants are witnessed by the sim
(`sim/verdicts.md`), which is evidence, not authority.

## Drawing chain

**One drawing chain serves the validator, the review page and the workbench, so they cannot
drift.** `draw/` builds a frame's picture from the couple seen from above: two plain circles
with a chevron for facing, the lead at the bottom facing up; squares for the lead's hands and
circles for the follow's, each in its side's hue and its owner's shade (deep for the lead,
plain for the follow), so shape and colour say whose hand it is at any size and no caption
is needed. A connection meets at its middle in both hands' inks and goes **round** a body,
never through one, as a taut string that hugs the rim only where the straight way would
cross a body; only `above` runs straight, being over the head. A move's way round is settled
once for the whole move (`oneWayRound`), so no two animated frames can disagree about which
side of a body the line passes; rejected: per-frame routing with a side bias and hysteresis,
which drew lines sweeping straight through a body in the browser's blend between two frames.
Level is a fill on both ends (hollow unsaid, solid low, dotted high, hatched above); a hand
that has left its default leaves a grey ghost. The lead always faces up: poses live in world
coordinates and are drawn through `canonicalise`, so every equal configuration is one
picture. Cost: every frame's picture is built at compile time, so the browser ships finished
markup and none of the routing, at the price of compile time. Verified by `tdiagram.nim`
(every picture says what its frame is, at any size) and by the workbench's gates
(`design/checks.nim`, 102 assertions on the pages).

**The map and the spokes are the same picture at two distances.** `map.nim` draws the whole
ontology with every line laid down before any word, names cut into the line with round caps
(never painted over, since a hole in a line now means a connection passes underneath), and
the tower's order fixed once (`towerOrder`) so the matrix and the map read the same way.
`spokes.nim` draws only the frame held and every way out of it, and `motion.nim` says when
each drawing moves and for how long, so the page waits on the drawing's own schedule.
Verified by `tmap.nim` and `tspokes.nim`: the window a move ends in and where it leaves the
frame standing are the window and place that frame is given when still, which is what makes
the page's swap of one drawing for the next invisible.

## Validator

**Three views, in the order a reader wants them.** Atlas (every frame, drawn and counted,
where the page opens), Dance (the state machine from `free`), Matrix (every move at once,
drawn rather than tabulated: both axes carry the frames' pictures at one size, and a cell is
the same mark the map uses). Only what the ontology derives can be clicked; a compound dances
both its moves in turn. The close drawing hands its geometry to the stylesheet as bare
numbers and takes back one unit, registered with `@property` so recentring animates the
scale; it stops shrinking when names reach 8 px and scrolls instead. `--wide`, the width at
which the map is worth opening on, is written once in the stylesheet and read by the script.
Keyboard: every control reachable, focus returned after each move, a live region outside the
rewritten region announcing what was danced. Verified by hand in a browser at 390, 600 and
1200 px before the move (mark and frame land in the same place either side of the swap) and
not re-driven since: **assumed**. Which browser, and on what date, was not recorded, so this
cannot be repeated from a checkout; whoever next touches the shell re-drives it and writes
down both. The shell is the committed file `pages/app/index.html`,
copied out by `tools/pages`; the bundle (`tools/bundle.nim`) folds `app.js` into it as one
self-contained file for publishing, titled from `tools/title.nim` so a gallery sorts the body
of work together.

## Review page

**Every number and picture on the page is a marker filled from the model.** The prose lives
in the committed file `pages/review/review.html`; `tools/review.nim` fills the markers, inks
every term of art in the hands it names, and writes the page and one SVG per frame into a
directory it clears
first, so a renamed frame cannot leave its old picture behind. Rejected: committing the
generated page and holding it fresh by a test, which this repository cannot do because it
reads only registered file kinds; the page is a build product and cannot be stale, and the
test drives the build instead (Article IX.6). Cost: nothing in the tree shows the page's
history, and the published copy is not the record either: it can be deleted, and seven were
on 2026-09-06. The log is. Verified by `treview.nim`: every marker filled,
page and pictures written and read back, every frame named and every move and compound
counted in the matrix, no picture fixing a colour of its own, slugs unique, stale pictures
removed.

## Design workbench

**Rules are data and the pages are held to them.** The forty rules as given live in
`design/rules.nim` in the words they arrived in, mirrored entry for entry in
`design/README.md`; `checks.nim` asserts what each page claims between building its parts
and writing it, and the build refuses to write a page whose claims fail. Rejected: rules
that are implemented and not asserted, which quietly stop being true (it happened here more
than once, recorded beside the rules). The four generated pages and the hand-drawn
whole-cloth page are build products under `build/design/`; the whole-cloth markup is the committed
file `mockups/wholecloth.html`, its turns panel is `wholecloth_turns.nim` compiled to JavaScript,
and `wholecloth.nim` splices markup, the sim's sweeps (`turns.nim`) and the panel into one
page. Verified by `tmarks.nim`, which drives the build of every page under testament, and
for the whole-cloth port by a driven comparison under Playwright of the old page against the
new: 707 states equal (see Figures for what was compared). **That comparison cannot be
repeated here**: Playwright, TypeScript and any package manifest are absent from this
repository, and the date it ran was not recorded, so the 707 figure rests on a session
nobody can re-enter. Restoring it means bringing the harness in as a project of its own.
Reflow deviations the page module
records: 37 breaks inside `aria-label` values (accessible names verified equal), one
whitespace-free row with its character references decoded, and the fonts URL held as its own
constant joined at compile time. Cost: the workbench's `doAssert` gates are the
check, so its tests are a debug build.

## Body sim

**Two bodies of the average adult and their arms, sharing no code with ontology.** The
rig (`rig.nim`) is mixed-sex midpoints of ANSUR II medians with AAOS and NASA-STD-3000 joint
ranges, every number with its derivation; a torso is an ellipse three quarters as deep as it
is broad because a round section of a chest's girth stands three centimetres too far out at
the front. An arm is three rigid links on a shoulder that swings and twists, an elbow and a
wrist, and past a range is refused with the joint named; the stretch before an edge is
reported as strain. No link passes through a body or another arm; an arm may press its own
body. Rejected: importing anything from `src/`, because shorthand cannot check itself and sim
is what shorthand is for. Not rejected, and reversed since: sharing vocabulary. Sim reuses
agreed words where one fits and coins its own only where none does; what keeps it witness is
that it imports no code and is told no answer, never that it speaks different language.

**A pose is found, not drawn, and turning is a path, not a pose.** Given shoulders and grip
an arm has three freedoms, searched with the grip by a deterministic pattern search from a
grid of seeds for the most comfortable pose that holds: joints nearest rest, arms lowest,
grip between the bodies on the line between their centrelines, at whatever height in its
band leaves the joints least constrained. A body turns a fiftieth of a turn at a time and the
arms are carried by small moves; a pose is sought afresh each moment and taken only where it
is enough more comfortable and the arms can get there the same way round the bodies. Where
no small move holds and no reachable pose does, the turn is blocked and named. What no
evaluation changes is worked out once into a `Scene`; a seed is tried reach first, then joint
by joint, then by cost, then against the bodies, giving up at the first refusal; sweeps of
different holds run side by side on every core (`sweptAll`). Rejected: tuning any number to
the floor's claims; the floor is printed beside the sim and only asserted to be decided
(`-d:floorIsLaw` makes it hard). Verified by `tlaws.nim`, 28 laws over every moment of
eleven sweeps: nothing enters a body, joints inside every range, mirrors agree, blocks
bracketed with a name, and the clipped contact test against a sampled truth over 300 seeded
random segments; the forward kinematics over 200 seeded random arms. The optimisation that
made the solver share a `Scene` and run side by side was measured before the move as a
pair, but the pair is not in this tree: **unmeasured** here.

**The sim page turns by whole quarters and stands where the arms are freest.** Buttons turn
the lead or the follow a quarter on axis or in orbit (the walker keeps facing the centre,
rule 32); a quarter is animated as small moves and either completes or is refused whole,
the couple restored to where they were, so tallies are always multiples of a quarter. Hands
prefer to lie between the bodies near the centrelines, within the level's band at whichever
height minimises constraints. The distance apart is not a control: after every settle the
page steps the couple in or out to the stance with the most joint room, never closer than
ten centimetres of air between the torsos, read off the torso ellipses along the line
between the axes. Body sizes are static. Verified before the move by driven check in a
browser (four quarters of the follow refused at the fourth with the tally holding at 0.75;
distance never under the extents plus 0.10 m); not re-driven since: **assumed**. Browser and
date unrecorded, so this too cannot be repeated from a checkout.

**Verdicts are an instrument run, assumed current.** `sim/verdicts.nim` asks the sim what the
sheet asks and writes `sim/verdicts.md` in the sheet's words through one visible translation
table, wrapped at 100 columns; no test compares the committed record with the model, so it
is current as of 2026-09-05 (`tools/build.nim verdicts`, 42.3 s wall on this machine) and
stale until rerun. Rerun during move reproduced committed file byte for byte.

**Couple step as they turn, in sweep as on page.** Stepping in or out a centimetre at a time
wherever that leaves the joints freer was the page's alone; the sweep held one stance, so it
refused turns a real couple take by shifting their feet. Both do it now, from one place in
`sim/sweep`. Cost, measured rather than guessed: three block positions moved, by 0.02 turns
at most (`-0.65` to `-0.63`, `-0.59` to `-0.58`), and the crossed pair above went from
`+1.09` on arm through arm to `+1.07` on reach. No floor claim changed side. Three poses that
were reported *(led)* no longer are, having gained the room. `verdicts.md` was regenerated for
this and its diff read, since nothing keeps it honest by itself.

**One pressure on the elbow is recorded, not tuned.** Nothing in `comfort` rewards raising or
flaring an elbow, and two terms weighted 1.0 punish both: `lift` rises with elevation, and
`across` costs 1.0 at full abduction. `elev` is not a `Dof` at all, so shoulder elevation is
unbounded and unpenalised except through `lift`. The solver therefore settles the elbow low
and tucked toward the body's own midline, which is where the neck and head are, and that is
the likely mechanism behind the high-band blocks reported as *arm through head*. It is a
pressure, not the crown fault: with `overhead` set, the same rig and the same bias block
nothing there. Changing it would move every figure again and wants its own evidence.

## Pages and build

**Published titles say which pages the project stands behind.** Two do — the reference and the
body sim — and the other six are mock-ups, which is the line `CONTRIBUTOR.md` already draws
between `pages/` and `mockups/`. The first two are titled `Dance Ontology — …`, the rest
`Dance Ontology Mockup — …`, in title case throughout, so a gallery holding both says which is
which before either is opened. The name is spelt once, in `tools/title.nim`, and the mock-up
form is derived from it (Article II.1); `design/page.nim`, `tools/bundle.nim`,
`tools/review.nim` and `design/wholecloth.nim` all read it, and before this it was written
twice and drifting. `tests/tmarks.nim` and `tests/treview.nim` assert the built pages carry the
mock-up form and never the plain one, against the constant rather than against a repeated
literal: **verified**, by breaking the constant and watching both suites fail.
Rejected: agreeing a project term for the two categories, which would have overloaded the
charter's `Artifact` (a file a build writes, under `build/`) or coined a word for what
`CONTRIBUTOR.md` already says in plain English. Cost: the review page and the whole-cloth
mock-up now hold a `{{title}}` marker instead of their own names, so opening either committed
file no longer shows what the page is called; the name is one file away, and the alternative
was spelling it in four places.

**URLs are listed once.** Every published page's URL is in this project's `README.md`, in two
tables that carry the same split; `design/README.md` and `sim/README.md` point at it rather
than repeating it, as they used to (Article II.1). A page taken out of use keeps its URL and is
not listed, and the repository does not treat a published copy as its record: the log does that.
Cost: a URL is no longer beside the subsystem that builds the page.

**Hand-written pages are committed files; everything a build emits is not.** The validator's and
body sim's shells are `pages/app/index.html` and `pages/sim/index.html`, the review page's prose
with one marker per derived figure is `pages/review/review.html`, and the hand-drawn proposal is
`mockups/wholecloth.html`. `tools/build.nim pages` copies both shells into `build/`, compiles each
page's script beside it, folds each into one file with `tools/bundle.nim`, fills review's markers
with `tools/review.nim`, and splices mock-up's two scripts with `design/wholecloth.nim`. Generated
pages stay uncommittable: their lines run to thousands of characters. Tool binaries land in `bin/`,
pages under `build/`; root ignore file covers both at any depth, with test binaries beside their
sources. The whole-cloth page's 213 lines of inline JavaScript were ported to Nim's JS backend.
Rejected: hosting markup in Nim string constants, which was forced while repository read no markup
kind, and cost one string-literal edit for every change of style. Cost: `design/wholecloth.nim`
checked its two markers at compile time while markup was constant (Article IV.4); markup read at
run time carries only run-time check, which echoes marker and refuses to write page without its
data. Verified: `pages` run either side of move writes same 22 files with equal SHA-256 sums.

**Whole-cloth markup is held within width by audit now, not by script.** Every line fits 100 runes
except one, the Google Fonts request, which is one whitespace-free token of 179 runes on a line of
202 and passes on the unbreakable-token exemption. Breaks fall only at whitespace rendering
ignores -- between tags, between attributes, inside CSS, inside list-valued attributes (`d`,
`points`, `class`, `style`), and inside `aria-label` prose, whose whitespace accessible-name
computation collapses -- and one line of turn ticks holds no such whitespace, so its character
references are decoded to characters, which parser does anyway. `reflow_wholecloth.py`, which
applied those breaks while markup was a Nim literal, was migration tool and is not in tree; Python
is not registered kind and it is not wanted back, since form check now enforces directly what it
enforced by hand. Cost: an edit that lengthens a line past 100 runes is caught by audit rather than
repaired by script.

**Project's verbs live in compiled driver, since make is retired.** `tools/build.nim` takes
one command (`pages`, `verdicts`, `shot`, `clean`) and runs exactly what each Makefile
recipe ran, same programs and arguments in same order; koch drives tests, and holds no verb
for pages. Rejected: nimble task, which would put build logic in compiler's virtual machine;
asking koch for project-specific verb. Cost: driver runs from project directory, since every
path in it is relative. Verified by running each: `pages` writes every artefact in 58.4 s
against Makefile's 57.3 s, `verdicts` rewrote `sim/verdicts.md` byte-identical to committed
file in 42.3 s, `shot` emits `build/design/shot.js`, `clean` leaves source only, unknown
command exits 2.

## Tests

**Testament over `tests/t*.nim` from the project directory, one stub per suite.** Each stub
carries the curator's header; `tlaws.nim` adds `-d:danger` because the sweeps are the slow
part and `doAssert` survives it. Test binaries inherit testament's working directory, so
`build/review`, `build/design` and `walkFiles("tests/t*.nim")` resolve only when testament
runs from the project directory, as koch's runner does; running it from the repository root
breaks them. Cost: `tlaws` runs on every core and its wall time
follows the core count.

## Figures

- `tlaws` alone, danger build: 22.0 s wall, 59.0 s CPU, four Xeon cores, Linux amd64
  container, Nim 2.2.4, 2026-09-05; compile 2.3 s. Single figure, no pair: unmeasured as an
  optimisation.
- `tools/build.nim verdicts`: 42.3 s wall, same machine, 2026-09-05, after move; 44.6 s wall
  and 151 s CPU before it, under retired `make verdicts`.
- Eleven testament stubs, under `make check` before move: 52.7 s wall, 93.3 s CPU, same
  machine and date; `tlaws` 23.0 s and `tmarks` 11.5 s of it. Not re-measured alone since;
  whole-repository figure is in `curator/audit/PROVENANCE.md`.
- `tools/build.nim pages`, every page including the turns sweep: 58.4 s wall, same machine,
  after move; 57.3 s under retired `make pages`.
- Whole-cloth port parity, driven under Chromium with fonts stubbed and `requestAnimationFrame`
  replaced by a stepped queue on both pages: 707 states, 0 mismatches. Body outside the turns
  panel with whitespace collapsed, head without title, and the full-body accessibility snapshot
  equal at load; the panel's markup and slider value equal at load and for 6 holds × 3 levels ×
  (after the buttons, 15 slider moments, both exact blocks), 324 panel states, plus 54 animation
  states (300 frames playing, 120 to rest, 120 after a strip-figure click, compared every ten).
  No console or page errors on either page. `grep -c nimCopy` on the emitted
  `wholecloth_turns.js`: 13, all the runtime's own; none from module code, after five binding
  shapes were read and rejected (35 before).

## Rules deferred

Declared unmet by this move, so the Style row above stays true (Article VIII.1):

- VI.1: a few declarations in `tests/tlaws.nim` and `sim/verdicts.nim` carried no doc when
  the move began; the ones touched gained one, the rest keep `## TODO: Document.` in spirit
  but not in text. Cost: a reader opens the body.
- X.2: banner tiers are unmarked; every banner is spaced as second tier.
- VII.1: emitted-code readings exist for the whole-cloth port only; the validator and the
  sim page were written before the rule and their binding shapes are unread. Cost: a copy in
  a hot path may hide there.
- STYLE §2: `-d:floorIsLaw` predates the `{.define.}` naming convention and stays as the
  bare define the README names.
- X.8: pages name system font stacks; the whole-cloth page loads Fraunces, Instrument Sans
  and Spline Sans Mono from Google. Font files are unregistered kinds and cannot be shipped
  here; see Open questions.

## Toolchain

**Compiler pinned exactly, at the version this project was verified on.**
`requires "nim == 2.2.4"` in `dance_ontology.nimble`. CONTRIBUTOR.md now demands an exact
pin rather than a lower bound, and this project is the reason an upper bound is needed at
all: 2.2.8 and 2.2.10 crash the compiler itself on six of the eleven suites
(`field 'floatVal' is not accessible for type 'TFullReg'`), reported by the contributor of
`rga_visualiser` while checking which release the whole repository could take. Assumed, not
re-verified here: that report, which was measured on their machine and not on this one.
The eleven suites pass on 2.2.4, which is what the pin records. Moving it is this project's
own work, and it now moves nothing else.

## Re-audit, 2026-09-06

Audited by a curator against the rules change that registers C++ and C and puts a check
behind the gated-language rule. This project carries Nim, Markdown, a nimble file and
hand-written HTML; none of those is a gated kind, so the new rule binds nothing here and
nothing needed correcting. The stamp moves because the charter did.

## Re-audit, 2026-09-06, TypeScript conventions

Audited by a curator against the rules change that added the TypeScript and Node section to
CONTRIBUTOR.md. This project carries no `.ts` file, so the section binds nothing here and
nothing needed correcting; the stamp moves because the charter did.

## Re-audit, 2026-09-06, draft pull requests

Audited by a curator against the rules change that asks every pull request to open as a
draft and be marked ready only when it is. It binds how this project's next pull request is
opened, not anything in the tree; nothing needed correcting. The stamp moves because the
charter did.

## Open questions


- Answered for fonts: binaries are never committed, and a project records each one's origin,
  version, licence and checksum, then fetches it with an `assets` verb in `tools/build.nim`.
  Satisfying X.8 means fetching Noto Sans, Noto Serif and Commit Mono that way and dropping
  the Google request; until then the page keeps its remote fonts and system stacks.
- `tlaws` costs 22 s of a four-core runner per audit; acceptable now, and the figure above
  is the one to watch as sweeps grow.
