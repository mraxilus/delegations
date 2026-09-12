# Provenance

| Field  | Value |
|--------|-------|
| Agent  | Claude Code |
| Author | Claude |
| Date   | 2026-09-06 |
| Style  | CONSTITUTION.md and STYLE.md, followed. |
| Rules  | b4b063b2350a3645 |
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
without agreement were removed on 2026-09-06 and are in history. Forty-six are now agreed,
each concept set out with candidate names and their costs, and only selected name written.
Audit checks glossary's shape and never its words, so this holds by Architect's reading
alone.

**Sim is isolated in code, not in concepts.** It reuses agreed words wherever one fits and
coins its own only where none does; four are its own -- rig, pose, strain, block. What keeps
it witness is that it imports nothing from `src/` and is told no answer, never that it speaks
other language. Care is needed only where sim *measures* what ontology *asserts*: there
translation stays visible (`sim/verdicts.nim`), since assumed identity would be echo.

**`wind` is `twist`, and the workbench still says `wind`.** `GLOSSARY.md` has listed `wind`
under Twist's _Avoid_ all along, and the workbench uses it in about fourteen identifiers and
across page prose, for the quantity the model calls twist. Architect confirmed the two are one
on 2026-09-07 and put the rename after the frame-position review, so captions do not move
while they are being ruled on. A unit differs where the word does not: the model counts twist
in half turns (`HalfTurns`), this glossary says quarter turns, and the workbench counts turns
as a real number. Which of the three the term means is the second thing that pass settles.

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

**Rule 24 was measured at the corner, and a kink walked through it.** A settled reach picks
its way past the marks it must not touch by weighing three candidates -- the taut band let
go from the straight line, and a bow over each side -- on length and turns together
(`readingCost`). Until now the taut band was taken unweighed wherever it turned little and
turned smoothly, on the grounds that nothing could be plainer. It can be: the band hugs
whichever mark it meets, and a mark that sits near a hand puts the whole of that hug against
that hand, so the line runs dead straight to its far end and bends only there. The Architect
called out exactly that on B4 and B23 of the review sheet. **Measured**: their reach crested
0.88 of the way along its chord with 8.3 degrees at one corner, where every other bending
reach on the page crested between 0.40 and 0.60; the bow those two now take crests at 0.53
and 0.59 with 3.4 degrees, which is the shape of B7 beside them. All three candidates are
now weighed every time, and `crestOf` measures rule 24 along the reach as well as at its
sharpest corner -- a reach that leaves its chord must crest away from both hands. Rejected:
tuning a clearance to move the hug, which would have left the rule measuring half of itself.
Cost: three band relaxations per settled reach where one sometimes did, which is the mark
suite going from 20.9 to 23.3 seconds; and the bow beats the hug on those two by a hundredth
of a unit of line, so the preference is real but thin -- it is the review sheet's pins that
keep a flip from passing unseen. Verified: the fix moved exactly two drawings of the 148 on
the review page and eight of the 273 on the single-turn page, and nothing on the frame, sign
or hand-to-hand pages.

**The chain is walked, not jumped, so what lies between two positions is seen.** Past a whole
turn the pair stops sharing its swing evenly: one connection gives its bend up and runs
straight while the other snakes round it (rule 31). How *quickly* it gives it up was written
as a fast start, on the grounds that the third crossing wanted to arrive early. Measured, it
does not -- the third crossing arrives at the swan whatever the hand-over does. What the fast
start did instead was collapse the straight connection to a short stub for most of the walk,
so the diamond fell apart and the swan was built again rather than one opening into the other.
The Architect danced the figure and named the missing bend. The hand-over is now slow at the
start and quick at the end, so the connection keeps its bend nearly all the way and gives it
up at the last. Verified: no still moved -- the hand-over is nothing at a whole turn and
everything at a turn and a half, which is exactly where the chain's positions sit, so all 87
pinned cards passed unaltered and only the eight moving chain cells changed. A first pass eased the
hand-over at 3.5, which left the pair still crossing once between 1.28 and 1.38 turns -- one
arm laid flat over the other rather than going round it, which the Architect saw and named.
At 7.0 it never does: measured over the whole stretch at two-hundredths of a turn, the two
connections cross at least twice everywhere, and a check now walks that stretch and holds it.
What remains is smaller and of a different kind: the third crossing shows briefly around 1.38
to 1.40 turns, withdraws, and returns at 1.48. It is recorded rather than claimed fixed.

**A break that leaves a sliver draws a dot, and a dot says the opposite of a break.** A
connection is stroked with a round cap, so a painted piece of no length is still drawn -- as a
disc as wide as the line. Three places left such a piece. `gapFor` dropped a break only where
the gap would hang off the end of the reach, so a crossing a hair inside that threshold kept a
full-width gap and left the line joined to its hand by a stub of 0.01; the moving reach's dash
pattern left a hair of paint at the seam between a reach's two shades, and another where two
breaks nearly met; and the pattern is measured along the sampled polyline but spent along the
smoothed curve drawn through it, which is about half a per cent longer, so a gap stopping at
the polyline's end left the curve's own tail painted. Each drew a dot: at a hand it read as the
connection detached from it, and inside a break it sat on the crossing the break exists to
show, so the two connections read as passing through one another. The Architect saw both on the
hand-to-hand chain, swan to diamond. `SEEN_RUN` now names the least piece that reads as a line;
`gapFor` narrows a break rather than dropping it, keeping that much line at each hand, and gives
up only where the gap would be narrower than the line it hides; and the dash pattern gives any
shorter piece at a seam to the break, running it a stroke past the polyline's end. Rejected:
widening the suppression threshold, which would have drawn more crossings with no break at all
-- the opposite of what rule 14 asks. Verified by `tmarks.nim`, which drives the build: every
piece a break leaves is now nothing at all or at least `SEEN_RUN`, over every frame of every
edge of every manner. Cost: breaks near a hand are shorter than breaks in the middle, where
before they were all one length. The fix moved 12 of the 99 cards -- the four swan stills, whose
straight connection crosses close to a hand, and all eight moving chain cells.

**The third crossing arrives once, and the snake pulls in before it opens.** From a whole turn
to a turn and a half the pair gains one crossing, so the picture reads two crossings and then
three, changing once; it used to read two, three, two, three, gaining one at 1.22 turns, losing
it again from 1.41 to 1.46 and taking it back at 1.47. The lost stretch is the third crossing
diving back under a hand mark, where no break can be drawn: **measured**, it sat 2.9 units from
the follow's hand at 1.42 where the reach is trimmed at 7.7.

The two connections do two different things past a whole turn, so they take two shapes rather
than one shared between them. The straight one **hinges**: it gives up its bend late and then
all at once (`SWAN_EASE`). The snake **pulls in** against it while the pair tightens
(`SWAN_DRAW_IN`, `SWAN_DRAWS_AT`) and only then **opens out** into loops that go round it
(`SWAN_SWING`, `SWAN_OPENS_AT`). That order is what does the work: the snake is at its tightest,
0.89 of one connection's swing, at exactly 1.42 turns, which is where the third crossing runs
nearest a hand, and it opens after. **Measured**: the crossing now keeps 8.5 clear of any hand
at its tightest against a trim of 7.7, where a snake that opens early drives it under the mark.
Rejected: one width for the whole stretch, which is what a single `SWAN_SWING` is — the widest
such swan that keeps the count monotonic bows 14.1, against the 22 the Architect had, because in
that shape width and crossing placement are one number. Cost: the snake gains 0.16 of its swing
over the last hundredth of a turn, 3.2 of line; looked at frame by frame, 1.43 to 1.50, it
reads as loops opening rather than as a jump — verified by looking, 2026-09-08, not by test.
Verified by `tmarks.nim`, which drives the build: a gate walks the stretch every hundredth of a
turn and fails if the count ever falls or rises other than once, and two more hold the snake to
drawing in before it opens. The swan bows 22 round its straight connection, which is the width
before this stretch was mended.

**The two connections keep clear of one another where they run alongside.** Short of the swan
they ran close enough to touch: at 1.37 turns their middles came 3.35 apart where the line is
3.4 wide, so the ink merged and the Architect read the Right connection as running *into* the
other rather than crossing it. The pinch now keeps growing past a whole turn — `WIND_NIP_MORE`
— where its own cap used to stop it at one, which is what drew the pair as though winding had
stopped; and the snake pulls in harder before opening wider (`SWAN_DRAW_IN` 0.65,
`SWAN_SWING` 1.50). **Measured** over the stretch every hundredth of a turn: at 1.37 the two
now keep 6.51 between their middles where they kept 3.35, the tightest anywhere they are not
crossing goes from 4.05 to 4.81, and the shallowest crossing goes from 16.1° to 28.9° — well
clear of `GRAZING`, below which a break can no longer cover what it hides. Verified by looking
at 1.35, 1.37 and 1.39, 2026-09-08. **No gate holds this**, and that is a gap rather than an
oversight: every measure of it that runs over the whole stretch is dominated by two other
effects — the width of a break at its own edge, and the arrival window below — so no threshold
separates the mended drawing from the faulty one with any margin. Stated here so a later pass
knows it is unfenced.

**Amplitude was believed unable to move a crossing, and that belief was false.** The argument
was that both connections carry the same sine about the pair's axis with opposite sign, so
they meet only where the sine vanishes and the size cancels. It compares the two reaches **at
the same point along each**, which is only their crossing condition when they share a chord.
They do not: the follow's two hands sit up to 20 units apart *along* the pair's axis wherever
the follow has turned off a half turn, so the two chords differ everywhere between the chain's
positions. **Measured**: holding both connections at one common share and sweeping it from 0.5
to 2.0 moves the count at 1.20 turns through 0, 2, 3 and 1. The belief stood while the whole
family was ruled out untried, and while crossings were counted through a fold that merged
them, so the sweep that would have refuted it was scored blind. It earns its line because
anyone re-deriving it reaches the same wrong place.

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
than once, recorded beside the rules). The five generated pages and the hand-drawn
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

**The four are a manner of turn, not a way of turning.** `Manner` and `MANNERS` replace
`TurnWay` and `WAYS_OF_TURNING` through the workbench, and the pages, checks and rule ledger
say "manner" wherever they meant one of the four. "Way" is kept for clockwise against
anticlockwise, which is what `wayOf` and `wayName` return, so the two senses the one word
carried are now two words. Rejected: renaming `Way` as well, which would have left the
turn's direction unnamed. Verified by every drawing on all five pages coming out
byte-identical across the rename -- 66, 56, 273, 62 and 148 figures -- so nothing but the
prose moved. Cost: nothing holds a page's prose to `GLOSSARY.md`; `tglossary.nim` reads the
`_Avoid_` lines but claims only against chain position names, so this rename can drift back
without a test noticing.

**The moving sections show a walk whole before they show it in pieces.** Sections E and F of
the review sheet drew one cell per edge -- 64 quarter-turn edges and 24 chain edges, 88 cells
of animation to scroll past. Each manner of each hold now takes two cells instead: the walk
entire, and the same walk step by step with a button per step. `turnWalk` gained `steps` and
`back`, so one builder makes a single rocking edge, a whole round of four quarters that
closes on itself and needs no return, and a whole chain of six halves out and back, which
does need one because the chain has ends. The switching is a radio button and a sibling
rule, so the page stays markup a browser draws with nothing running; rejected: script, which
these pages have never needed. The pin now covers every drawing in a cell rather than the
last one, since a verdict on a cell is a verdict on all of it -- and for a cell holding one
drawing that is the same string, which is why all 59 existing pins still matched. Cost: 99
cells where there were 147, but 6.9 MB where there were 4.2, since a walk shown whole is
drawn as well as its pieces, not instead of them. Every animation runs at one pace
(`WALK_SECONDS`), so the length of a loop says how far it goes rather than how fast: the
whole chain is six times an edge, which is a long loop and is flagged on the page as
something to shorten if it reads as slow. Verified by `tmarks.nim`, which drives the build and so
the gates: the 16 rounds are counted, each asserted to close where it set off, and the
whole-walk figures are held to the same hatch laws as the edges. Verified again by every
drawing on all five pages coming out byte-identical when `steps` and `back` took their
defaults.

**A verdict is given on a picture, so the picture is pinned.** `review_page.nim` lays out
every position the project draws as 147 cards -- the sixteen standard diagrams and the one
anticlockwise counterpart, the twenty-eight distinct single-hand turn positions, both
hand-to-hand chains, and every animated edge of the last two -- each carrying the identifier
to quote back and whatever has been ruled on it. The identifiers the Architect has kept or
dropped are named in the module; what each was drawn as when it was ruled on is held as a
hash in `design/review-pins.json`, and the build refuses to write the page when a ruled
card's drawing has moved. Rejected: taking the verdict as given on the identifier, which is
how a mend that reached further than it meant to carried an approval nobody gave. The guard
was proved by widening a break's clearance and watching it name the twelve kept cards that
carry a crossing. Pins are rewritten only by `tools/build.nim pins`, a deliberate second
step: a verdict and its pin are added together or not at all, and running it to quiet a
complaint would hand the approval to the new picture. Cost: the verdicts live in the module,
so every ruling is a commit. Verified by `tmarks.nim`, which builds the page under
testament; by all 55 pins regenerating identical in content when the page moved into the
workbench from the scratch generator that first drew it; and by the tally being counted off
the built page rather than kept while building it -- 55 kept, 0 dropped, 2 marked for a
mend, 92 still to rule on, of 147.

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
the floor's claims; the floor is printed beside the sim, and each of its seven claims is held
to what the sim answers today, so neither a mend nor a regression passes unseen
(`-d:floorIsLaw` holds the sim to the floor outright). Verified by `tlaws.nim`, 29 laws over
every moment of thirteen sweeps: nothing enters a body, joints inside every range, mirrors
agree, blocks bracketed with a name, and the clipped contact test against a sampled truth over
300 seeded random segments; the forward kinematics over 200 seeded random arms. The
optimisation that made the solver share a `Scene` and run side by side was measured before the
move as a pair, but the pair is not in this tree: **unmeasured** here.

**Five of those laws could not fail, whatever the model did.** `check cs.len >= 0` on an
`int`; `check got.isSome or got.isNone` on an `Option`; a bare `check true` with the `agrees`
values above it computed and discarded; a `lyingOn(...).isNone` over the crown that only
re-asserted an unconditional early return; and an `if blk.stopped:` guard that ran no
assertion at all for a sweep which does not block, which is both crown sweeps and so exactly
the level of the fault
[#40](https://github.com/mraxilus/delegations/pull/40) mended. That fault was visible and
reproducible in twelve seconds and no law failed because of it. Each now asserts what its name
promises, and each was proved able to fail: the thing it claims was broken in the sim, the
suite run with `-d:nimUnittestAbortOnError:off`, and the law reddened. Four breaks touched
that law and nothing else; where a break could not be confined -- turning a body not quite a
whole turn moves every stance there is -- other laws reddened beside it. Cost: the suite takes
30.8 s on four cores in a danger build against 23.9 s before, measured 2026-09-08 on this
machine, and the two crown sweeps added to cover R-r and R-l are the difference. Second cost,
found while proving the laws fail: the suite is built `-d:danger` for that speed, so a model
change leaving a sweep with no moments segfaults it rather than reddening a law.

**The sim does not meet three of the floor's seven claims, and the floor is right.** The
Architect dances the floor, so where the two disagree the fault is the sim's: L-l low the wrap
way blocks at 0.30 against half a turn claimed; L-l high blocks at 0.41 the lock way against a
whole turn claimed, holding to 1.25 the other way; L-r low the lock way blocks at 0.87 against
a whole turn claimed. Rejected, again: moving a number to meet a claim. Each row instead
carries whether the sim meets it today, so mending one turns the suite red until the record
follows it. Measured 2026-09-08 on this tree, and `-d:floorIsLaw` compiles and fails at the
first of the three.

**A whole turn is no turn to a pose sought without history.** The solver reads a stance's axes
and never its lap count -- the couple's `twist` is read for display and by nothing else -- so
`settle` at a whole turn returns the rest pose: measured at 2.6e-16 m on the furthest joint,
for both two-hand holds, at rest and at half a turn. Only the sweep carries turn, moment by
moment, and both two-hand sweeps block by 0.58. So nothing here is evidence about the diamond
at a whole turn or the swan at a turn and a half: the rungs the chain law prints under those
names are the rest and the X. Verified by `tlaws.nim`, which now asserts the axes identity
outright rather than leaving it to be discovered. Cost: the sim cannot yet reach two of the
positions the drawn chain is built on.

**The crossing reader is exercised off settled poses, because no swept moment crosses.** Not
one of the 116 moments the two two-hand sweeps accept carries a crossing, so a law read off
them would assert nothing; the corpus is instead both holds at every band over five turns,
which gives 12 crossings, each held to sit on both connections in plan and to name which is
higher (furthest off its connections, 7e-17 m). Assumed, not measured: that `sameCrossings`,
which gates a fresh pose on the sweep, does useful work -- it compares nought with nought at
every accepted moment, and what it refused was not recorded. The reader is also knife-edge
where two arms lie along each other: two stances a whole turn apart, whose poses differ by
5.6e-17 m, read as four crossings and as one. Underneath it the search is sensitive too: the
same two stances at the neck settle 0.75 m apart at the furthest joint, off an axis difference
of 4.9e-16. Neither costs a verdict its determinism -- every law here answers the same on the
same code, and the suites seed explicitly -- but both say a law read at a knife edge would be
evidence about arithmetic rather than about bodies, so none of these is.

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

**Sim reaches seven of the ten chain cards the reference signs off, and falls short at three.**
The review page draws each chain at seven winds half a turn apart with both arms over head, and
the Architect has kept `C2`-`C6` and `D2`-`D6`. Swept from rest, the sim draws what the reference
draws at seven of those ten and falls short at `C2`, `D2` and `D6` -- every one a **diamond**,
every one drawn with no crossing where the reference draws two. Measured 2026-09-10 rather than
inferred, and three readings that each rule something out: loosening the crossing reader's
tolerance from 1e-9 to 1e-3 changes not one count, so the reader is not implicated; no moment in
range is reseeded, so it is not lost memory; and the pose the sim settles at a whole turn stands
0.7 cm (`D2`) and 3.0 cm (`C2`) from the rest pose, against 36-56 cm at a half turn. The arms get
out of the wind by passing over one another, which over head there is room to do -- **not**
through one another: the least clearance between the two connections anywhere in either sweep is
-0.45 cm, inside the give the model already allows for flesh, and no moment's verdict is anything
but `ok`. Whether a couple whose hands are joined can unwind an overhead chain that way is the
Architect's to say, and is asked rather than assumed, so no mend is made here. Rejected: refusing
the freshly settled pose wherever arms could be carried instead, which reaches `C2` and loses
`C6` -- three cards short either way, and a different three.

**The two connections were passing through one another, and the guard meant to stop it could
not see it.** `sameCrossings` refused a writhe change of two or more, on the premise its own
comment stated -- that two arms passing through each other change writhe by two. Measured
2026-09-11, that premise is false: the pair resting pillion lead sheds one crossing between 0.68
and 0.70 of a turn, sitting 1.53 along one connection and 4.24 along the other with neither near
an end, and mirrors it turning the other way. A lone crossing leaving the middle of both
connections is arms through arms; crossings come and go in pairs where arms pass over one
another, and singly only at an end. The change moves writhe by one, so the old test waved it
past. The fault hid because `Crossing` computed how far along the second connection a crossing
sits and discarded it: a crossing sliding off that one's end reads mid-line along the first, so
nothing could tell a fair end-slip from a pass-through. Kept now as `across`, and the guard reads
where crossings sit rather than how far their sum moved. Verified by a law that fails on the old
guard and passes on the new.

Four readings rule out what it is not, each measured rather than argued: the crossing reader is
not implicated, since loosening its tolerance from 1e-9 to 1e-3 changes not one count; it is not
lost memory, since no moment in range is reseeded; it is not coarse stepping, since sixteen times
finer gives the identical result; and it is not the solver hopping basins, since taking the trust
region from 0.15 to 0.02 changes nothing. `evaluate` judges poses and never the path between two
of them, which is why no sampling rate could have found it -- every pose either side of a
pass-through is itself clear.

**Cost of the mend, stated rather than implied: reach.** The chains now stop at 0.43 turns where
an arm would enter a body, at 1.07 where the arm is not long enough, at 0.76 and 0.77 where arm
meets arm; in all four a pose exists a step beyond and no path to it does. Ten rows of
`sim/verdicts.md` that read as reachable now read as blocked, and it was regenerated for that
(Article VII.6). They were only ever reached by passing arms through arms, so the smaller figure
is the true one. Kept chain cards go from seven of ten to six: `C3` joins `C2`, `D2` and `D6` as
short. That is the reference exposing how far the sim stands from it, which is what the reference
is for.

**The sim cannot reach the diamond at all, and no gate will change that.** Past 0.6 of a turn
every pose the solver accepts has writhe nought, measured over every start it tries at each of
twelve winds: the most this model winds is one crossing, and a diamond is two. The destination
does not exist, so the shortfall is not the guard's and never was. Two causes, both structural:
the sim proposes poses and checks them, with no notion of motion, so arms cannot slide along one
another as a couple's do; and the rig is rigid -- no lean, no torso bend, and `elev` is not a
`Dof`, which is the elbow bias already recorded above. Rejected: tuning the guard, which was
tried four ways and moved nothing.

**Over the head, twist is the only thing that should stop a turn, and in this sim it never
does.** Architect's rule, given 2026-09-12: overhead is the one level whose block is a twist
block, since over the head an arm goes round nothing. Measured the same day across all six
holds at all three bands, thirty-six sweep ends: `Reason.Twist` is what stops **none** of them.
Single holds overhead do not block at all, which agrees with the floor and with the sheet; the
two chains overhead block as `Through` at 0.43 of a turn, as `Arms` at 0.76 and 0.77, and as
`Reach` at 1.07 -- and `Through` overhead is an arm laid through a body, which is the one thing
the rule says cannot happen up there.

The limit is real and reachable, so this is not a range set too wide: twist runs from -70 to +90
degrees on this rig, and at the low and high bands it is driven to 104 per cent of that, held
only by the tolerance. Overhead it reaches 102 per cent for the pair resting pillion lead -- and
`Arms` still trips first -- 65 per cent for the pair resting face to face, and 29 per cent for a
single hold, which is nowhere near. So the constraint the Architect names as the only one that
should bind up there is, in this model, never the one that binds anywhere.

This is what the engine's joints are for. Box3D's ball joint carries a cone limit and a twist
limit separately, so a shoulder's reach and a shoulder's twist stop being one number: the rule
becomes something the rig expresses rather than something a cost function must be tuned into.
Recorded before that work rather than after, so these are the figures it is held to.

**Wind is read as writhe rather than as a tally of crossings.** A tally cannot tell arms wound
round one another from two crossings of opposite sign, which annihilate under a small move and
never were wind at all: measured 2026-09-10, the pair `D` carries just past a whole turn melts to
nothing when walked back 0.10 of a turn, eighty small moves, while `C6`'s two crossings share a
sign, survive twenty relaxations in place, and are wind. Tally and writhe agree on all ten kept
cards today and the law checks that they do, so the day they part is the day this is read again
rather than a day nobody notices. Rejected: keeping the tally as the reading, which would have
called `D` just past a whole turn a diamond.

**One reading is recorded without a diagnosis.** Turning the two ways should mirror, and for the
pair that rests pillion lead it does -- `D3` reads +1 and `D5` reads -1. For the pair that rests
face to face both halves read -1: `C3` and `C5` carry the same handedness. `C` is the crossed
hold and chiral, so this may be the hold's own asymmetry rather than a fault, and it is written
down as measured rather than argued either way. It is visible in the suite's own output, which
prints writhe beside the tally for every card.

**Both chains were swept at the torso alone, and the whole reference is drawn over head.**
`tests/tlaws.nim` built thirteen sweeps and neither two-hand hold among them stood at the crown,
so no law covered the one band every chain card is drawn in -- the same shape of fault as the
five laws that could not fail, found the same way. Both are swept there now, longest first since
they reach furthest: `tlaws` costs 13 s more for it and the whole runner 8 s more, the sweeps
sharing cores.

**A rigid body engine is cloned, not vendored, and Nim alone speaks to it.** `tools/build.nim`
declares `box3d` in `SOURCES` with its repository, its commit
`47d7f7cc7e091142c08d11dc7d2e493c5d34f536`, its reason and its licence (MIT, read from the
repository's own `LICENSE` rather than assumed); `engine` clones there into `deps/`, refuses a
clone standing at any other commit, compiles its fifty C files and archives them into
`bin/libbox3d.a`. The commit is what stands where a checksum stands for a fetched file. Nothing
of it is committed: `deps/` is ignored at the repository root, exactly as Atlas checkouts are.
Rejected: its own CMake, which would be a third build driver in a project whose registry admits
no second — the reason `make` was retired — and which nothing in fifty files needs, since none is
generated. Cost, stated: the build flags are this project's rather than upstream's, and `-O2
-std=c17` is what upstream's own release build sets. Measured: 50 files, 24 s cold, and the verb
returns at once where the archive already stands.

`sim/engine.nim` is the binding, and it is Nim throughout — the gated-language rule is never
engaged, because no C file of this project's own exists to argue for itself. It links the
archive and declares what the solver needs: world, body, capsule, ball joint, step, world point,
angular velocity. Importing it builds the archive first, at compile time, so a suite that drives
the engine drives its build too (Article IX.6) and no machine needs the verb run by hand.
`tests/tengine.nim` holds it to two laws and no more — that a body falls half g t squared, which
catches a struct laid out wrong where linking would not, and that two limb-thick capsules started
inside one another part to at least two radii. The second is the whole reason the engine is here.

**The engine stands Y up and this project stands Z up**, and the binding deliberately does not
translate: it is a binding and nothing else, so whatever calls it says which way is up and one
place holds that decision.

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

**The browser comes from the environment, and the declaration says what to install.** `shot`
drives Chromium through Playwright, and both used to be named by absolute path in
`design/shot.nim` — one of them with the browser's build number inside it, which pins a version
in the least durable place there is (issue 62). Neither path is in the source now.
`tools/build.nim` declares `nodejs` and `chromium` as data with what each is for, and a `system`
verb prints those names one per line for an installer; `shot.nim` takes Playwright from
`DANCE_PLAYWRIGHT` or the bare module name node resolves, and the browser from
`DANCE_CHROMIUM`, then from `chromium` beside Playwright's own store
(`PLAYWRIGHT_BROWSERS_PATH`), and otherwise lets Playwright resolve what it installed. Absent
Playwright stops with a finding naming the verb that says what to install, rather than as a
missing file. Rejected: pinning Playwright itself, which is a node package and would mean a
`package.json` beside its lock — that enrols the project in `koch types` and demands a `types`
verb, work the Architect has asked not be built while this half of the project may go. Cost,
stated rather than implied: **Playwright carries no pin here at all**, and the system packages
carry whatever version the machine has. Verified by running all four routes on this machine,
2026-09-08, Node 22 and Playwright's Chromium 1194: nothing set stops with the finding and exit
1; `DANCE_PLAYWRIGHT`, `NODE_PATH` and `DANCE_CHROMIUM` each write both themes' screenshots; a
path naming no browser fails loudly rather than silently. Not repeatable from a checkout — no
test drives `shot`, since the project carries no `drive` verb.

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

- `tlaws` alone, danger build: 31.7 s wall, 83.9 s CPU, four Xeon cores, Linux amd64
  container, Nim 2.2.12, 2026-09-10; compile 1.3 s warm, 11.1 s cold. Single figure, no
  pair: unmeasured as an optimisation.
- `tools/build.nim verdicts`: 50.2 s wall, 176 s CPU, same machine, Nim 2.2.12, 2026-09-10.
  It rewrites `sim/verdicts.md` byte for byte identically to what 2.2.4 wrote, which is the
  evidence that moving the pin moved no answer the sim gives -- worth having, since the
  search is sensitive enough to land 0.75 m away on a last-bit change of input.
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

**Every page ships the three faces it draws with, inlined.** Titles take Noto Serif, body
text Noto Sans, code and data Commit Mono, which are the Architect's standard three and what
Article X.8 names. Labels drawn inside figures take Noto Sans rather than Commit Mono: X.8's
"code, data and figures" reads as numbers, and a label naming a hand is interface text.
Seven faces are fetched by `tools/build.nim`'s `assets` verb into `build/fonts`, never
committed, each pinned by package version *and* SHA-256 — version because an unversioned
path serves whatever the host resolves that day, digest because the bytes are embedded in
what readers open. `design/faces.nim` inlines them as data URIs and `pages` dresses every
page it wrote, once, after every writer has run; doing it there rather than in each writer
is what keeps the suites free of the network, which is **verified**: the thirteen suites pass
with `build/` deleted outright.

Origin of all seven is `@fontsource` 5.3.0 by way of `cdn.jsdelivr.net`, all **SIL Open Font
License 1.1**, confirmed from each package's own `LICENSE` rather than assumed. Their
addresses and checksums are no longer this project's to hold: they are the `ASSETS` table in
`curator/audit/src/assets.nim`, the repository's shared store, and `assets` here names the
seven files it wants while `koch assets` answers with their paths. That is the settlement of
repository issue 116, which this project raised as its second consumer: four of these seven
were already pinned byte for byte by `rga_visualiser`, and Article II.9 calls two lists of
identical digests a copy no constraint forces. **Digest is the curator's, choice is this
project's** — the store never says which faces a page draws with, so nothing about
per-project autonomy moved. This project is the first to draw from it; `rga_visualiser` still
carries its own table.

The store keys entries by digest, so a face arrives under a name that is its hash; `assets`
restores the file name on the way into `build/fonts`, because everything downstream reads
faces by name. Verified 2026-09-10: all seven arrive, all seven carry the digest the store
declares, and every built page is byte-for-byte the size it was when this project fetched
them itself. Asking for a face the store does not declare fails with a finding naming it,
which is checked rather than assumed.

That check has to live in a suite, not only in the build: this project carries no `drive`
verb, so the runner never runs its `assets`, and a face named that the store lacks would
otherwise surface only when somebody built pages by hand. `tfaces.nim` reads the store's
declaration as text and holds every face named here against it — as text rather than by
import, so the law depends on the declaration and not on the curator's module keeping its
present shape, and so that this project imports no curator source, which none does.

Cost, measured 2026-09-10 on this container: **+224 kB per page**, 167,424 bytes of woff2
becoming 224,384 of base64, across ten pages, so `build/` grows from 6.9 MB to 9.1 MB.
Rejected: linking the host's copy, which names a face the reader may lack and needs network
at reading time; rejected: subsetting per page, which trades one shared block for ten that
drift. Commit Mono keeps its ligatures in `calt` rather than `liga` — **measured**, both
weights, 1932 glyphs in the latin subset — and `calt` is on by default only until something
sets `font-variant-ligatures`, so the emitted sheet sets `contextual` at root and no later
reset can lose them.

**What this changed in the drawings, and what it did not.** The label font is named inside
the figures, so every figure carrying a label changed its bytes. Of 516 figures across the
six pages, 495 are byte-identical, 21 differ **only** by the font name, and none differs any
other way — so no geometry moved. Those 21 were then read as pictures rather than as bytes:
97 labels measured in a browser, none outside its viewBox before or after, none newly
clipped, widest width change 0.9 px. Verified by hand in Chromium 1194, 2026-09-10, against
a before-and-after sheet of all 21. The change worth naming is the one that is not visible
in a diff: those labels used to render in whatever sans the reader's machine carried, so a
card approved on one machine was a different picture on another, which is the thing X.8
exists to stop.

## Toolchain

**Compiler pinned exactly, at the version this project was verified on.**
`requires "nim == 2.2.12"` in `dance_ontology.nimble`. It sat at 2.2.4 for two weeks because
2.2.8 onward crashed the compiler itself on six of the suites
(`field 'floatVal' is not accessible for type 'TFullReg' using 'kind = rkInt'`), and that was
recorded as an upper bound nobody had explained. The cause was one line here, not a fault of
the release: `polylineLen` in `draw/route.nim` read its float `result` with `+=` before
anything assigned it, and from 2.2.8 the virtual machine hands such a result an int register,
then reads `floatVal` off it. It bites only at compile time and only where the function is
reached in the VM, which is `const SCENES = buildScenes()` in `draw/scene.nim` -- so exactly
the six suites importing the umbrella module crashed, and the six importing `sim/`, `design/`
or submodules did not. `result = 0.0` first is the whole of it, and the line carries a comment
saying why, because it reads redundant and is not.

Verified here 2026-09-10, not assumed: five lines reproduce the crash with nothing from this
project -- a `func` accumulating into a float `result` and called from a `const` -- compiling
on 2.2.4 and crashing on 2.2.12 with that message; before the mend 6 of 12 suites crash on
2.2.12 in 2 m 28 s, after it all 13 pass in 2 m 11 s, and the same 13 pass on 2.2.4. Behaviour
is unchanged and that is measured rather than argued: every one of the 22 pages
`tools/build.nim pages` writes is byte-identical built with the line and without it, so no
page changes and none is republished. Verified by `troute.nim`, which takes a run's length in
a `const` so the compile-time path has a law naming it; without that, tidying the line away
would show up only as six suites failing to build. The diagnosis came from a curator's sweep
for stale versions, issue 106. Rejected: staying on 2.2.4, which kept a bound whose reason
lived in one sentence of this file. `result +=` on a float survives in `sim/`, `design/` and
`tools/`, none of which the VM evaluates today: latent, not urgent.

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

## Re-audit, 2026-09-06, compiler resolution

Audited by a curator against the rules change that has koch resolve each project's pin to its
own compiler and fetch one it lacks. Nothing here needed correcting: the pin itself is
unchanged, and what moved is how koch finds a compiler for it. The practical effect is that
`nim r koch ci` is green as one command on a machine holding any one Nim, so verifying a
change that touches every project no longer needs two compilers and two commands.

## Re-audit, 2026-09-06, published pages linked

Audited by a curator against the rules change requiring a published page to be linked rather
than described — in the pull request's verification section and in the message to the
Architect both. Raised by `contributor/sincopa/dance_ontology` as issue 42, after the
omission it describes happened in pull request 40.

## Re-audit, 2026-09-06, curator pass

Audited by a curator against the pass that corrected six pieces of drift, split compiler
acquisition out of `toolchain.nim`, and covered the two modules that had no test. One change
reaches this project: a change touching only its `README.md`, `PROVENANCE.md` or
`GLOSSARY.md` now compiles nothing, where a README change previously ran the whole suite.
Nothing here needed correcting.

## Re-audit, 2026-09-07, issue routing

Audited by a curator against the change that made the issue channel run both ways and gave each
session a queue. A session now reads the open issues labelled with its own role before any other
work; a curator who reads this project raises what they find as an issue rather than editing it,
since they may not; an issue labelled with a session's own role is that session's queue, work
decided and deferred where the next session here will see it rather than in a conversation that
ends; and a label is the role string exactly, copied and never composed, because applying a
label creates it and a misspelling makes a second label nobody filters on.

Nothing in this tree changes: the rule binds how the next session here starts. No issue is open
against this project today, so its filter starts empty, which is the answer the rule is meant
to give when there is nothing waiting.

## Re-audit, 2026-09-07, Article II.9 bound

Audited by a curator against the amendment to Article II.9, which bounds when target code may
be hand-written: the source language by default, the crossing kept narrow, and the target
language only where the source cannot reach at all or where crossing would forfeit what the
target gives for free — a check its own compiler makes over the bulk of a file, a cost the glue
would add to a hot path — with the file's opening comment saying which.

This project holds no target-language file, so the rule binds nothing here today. It binds the
moment one arrives, and the `not Nim because` gate already refuses one that argues nothing.

## Open questions


- `tlaws` costs 22 s of a four-core runner per audit; acceptable now, and the figure above
  is the one to watch as sweeps grow.
- **A crossing that has just arrived cannot carry its break, and five hundredths of a turn are
  drawn without one.** The third crossing enters through the end of a reach, so from 1.24 to
  1.28 turns it sits between 0.0 and 4.2 along from that end — nearer than half a break — and
  `gapFor` gives up rather than cut a gap narrower than the line it hides. Those frames draw
  two connections crossing with nothing saying which is over, against the standing rule that
  every crossing shows one. **Measured**: 5 of the 51 hundredths over the stretch, all of them
  at the arrival; before this pass the same crossing went unbroken for 16 of them, because the
  fold hid it entirely. It is not obviously mendable by tuning: a crossing entering through an
  endpoint is at the endpoint for some interval whatever the construction, and the choices are
  to let the break eat the end (which detaches the line from its hand) or to hold the crossing
  hidden until it can be broken (which means trimming the reach further, and that reaches every
  drawing). Left for the Architect to rule on.

- **The drawing does not yet build the chain the way the Architect describes it.** They danced
  the figure and stated the model: one connection **curls around** the other, and the other
  **hinges straight** -- a right angle at the joined hands opening until the two forearms are
  in line. The drawing still gives every connection a sine swung about the pair's axis, and
  takes the crossings from wherever two such curves meet. The count now behaves — see the
  third-crossing entry under Drawing chain — so
  this is a question about whether the picture is built from the movement or merely agrees
  with it at the positions checked. A prototype of the hinge-and-curl model gave the right
  counts and drew shapes that are not a swan -- two straight lines crossing in an X -- because
  it was scored before it was looked at. Anything that replaces the sine is drawn and looked
  at first.
## Re-audit, 2026-09-07, type check on runner

Audited by a curator against the rule that a project carrying `package.json` beside its lock
carries a `types` verb in `tools/build.nim`, and that CI runs it: `koch types` restores node
tools and drives that verb, scoped to projects one change asks for.

This project carries no node manifest, so nothing here is type-checked and the rule binds
nothing today. It binds the moment this project grows scripts of its own.

## Re-audit, 2026-09-07, system dependencies

Audited by a curator against the rule that system dependencies — a library the compiler links
against, a tool the build shells out to, a browser a driven check drives, a source clone no
package manager carries — are declared as data in the project's own `tools/build.nim`, each
entry carrying its reason, and reached by a verb. A source clone carries its commit; a system
package carries no pin that survives across distributions, and the record says so rather than
implying one; anything fetched at build time carries a checksum the build verifies. No
machine's paths in committed source.

Raised as issue 62, and answered: see "The browser comes from the environment" under Pages and
build.

## Re-audit, 2026-09-07, system and driven verbs

Audited against the rule as it now stands: system dependencies are declared as data in the
project's own `tools/build.nim` and reached by a verb **named `system`**, which prints the names
one per line and nothing else, since `koch system` feeds that output to an installer; and a
project enrols in the driven check by carrying a verb **named `drive`** in the same driver.

This project now carries `system`, and `koch system contributor/sincopa/dance_ontology` prints
what it declares. It carries no `drive` verb and no TypeScript, so the driven check does not
apply and nothing here is driven on the runner; `shot` stays a helper a person runs.

## Re-audit, 2026-09-08, draft while you finish

Audited against the rule that a pull request goes back to draft the moment another commit is
intended, and is marked ready again after. This project's branch carries no open pull request:
the Architect reads and merges the branch itself. Nothing to change; the rule is recorded so
that a pull request opened later is opened as draft and kept there while work continues.

## Re-audit, 2026-09-08, deterministic verdicts

Audited by a curator against the rule that a check gives the same verdict on the same code,
and that where it does not, the check is what is wrong.

This project complies today. Its sampled suites seed their generators explicitly —
`tests/tlaws.nim` uses `initRand(7)` and `initRand(11)` — so each run draws the same corpus,
and nothing in the suites reads a clock or a display. Nothing needed correcting.

It binds where this project is least protected: `design/shot.nim` drives a browser through
Playwright, and no `drive` verb enrols it in the runner's driven job, so that layer is neither
checked nor covered by this rule's evidence today. Whatever it becomes, it should settle on
what moved rather than on what has stopped changing.

## Re-audit, 2026-09-10, faces by element

Audited by a curator against the rules change that splits Article X.8's faces by element —
Noto Serif for headings and titles, Noto Sans for body and interface text, Commit Mono for
code with its ligatures enabled. **This one does bind here, and correcting it is this
project's work.** Every page sets system stacks (`ui-sans-serif`, `ui-monospace`, `ui-serif`)
and the whole-cloth mockup loads Fraunces, Instrument Sans and Spline Sans Mono from Google
Fonts, so no face is shipped and X.8's first clause — never naming one a viewer may lack — is
not kept either. `design/page.nim` writes every stack as the `font` shorthand, so it carries
no `font-family` at all.

The open question this record already parked — that font files are an unregistered kind and
cannot be committed — is answered by `rga_visualiser`: fetch at build time, pin every byte by
SHA-256, embed as base64, commit nothing. Repository issue 119 carries the reading.

**Done, and this note is kept only because it dates the fault rather than describes it.**
Every page now ships all three families inlined; the whole-cloth page fetches nothing from
Google; and the split the rule asks for is what the pages set. The one judgement the rule
left open, whether a label drawn inside a figure is a figure or interface text, is settled
the second way here: X.8's own clause reads "Noto Sans for body and interface text", and a
label naming a hand is interface text rather than a number.

## Re-audit, 2026-09-12, engine holds what it can and judges what it cannot

The pose search this project began with proposed poses and checked them, with no motion between
two of them, so arms could never slide along one another: it wound a chain to one crossing and
stopped, where the reference draws two crossings at a whole turn and three at a turn and a half.
Box3D replaces it. `sim/rigid.nim` builds both dancers from `sim/rig`'s tape, and `sim/walk.nim`
turns one of them and keeps every moment.

**What the engine can hold, and what it cannot.** Elbow's hinge and wrist's cone it holds exactly;
shoulder's twist too. Shoulder's *swing* it cannot: the rig gives extension and adduction as two
ranges of their own, and a spherical joint offers one symmetric cone about rest. Rejected: fitting
a cone to the pair. A cone about the hanging arm would also bound elevation, for which the rig
gives no range at all, and every hold over the crown would block at once. The cone is left off,
and swing is read back off the pose and judged against the rig.

That choice is why the crown behaves as the Architect reports it: arms over the head are clear of
both bodies and nowhere near either swing end, so twist is the only thing left to run out. It falls
out of the rig rather than being special-cased.

**A judged limit must still push back.** Judging swing after each step and never resisting it let
the engine walk an arm where no shoulder goes, and the hold then read as blocked -- where a dancer
would simply have put the arm elsewhere. Every one of nine sweeps blocked on `Swing`, including
the crown, at 0.28 of a turn where the floor says no block at all. The limit now applies a torque,
as the other three joints already get from the engine.

**And a limit that pushes back needs room to push in.** With the block declared the instant the
margin went negative, the torque engaged and the sweep stopped in the same step, and the figures
were bit-identical with the torque and without it. An arm rests against its limit and slides along
it; it blocks when it is forced past. `GIVE` is that room, and is the same reading, for the same
reason, that the old solver's `TOLERANCE` had.

**Torque is a pseudovector.** Each arm is worked out in the body's mirrored terms so one set of
ranges serves both sides. A mirrored frame is left-handed, so a cross product worked out in it
comes back negated: un-mirroring a torque as a plain vector gives exactly minus what is wanted, and
turns the correction into a shove. The mirror law in `tests/trigid.nim` does **not** catch this --
it passed with the sign wrong -- and the fix rests on the physics and on measurement instead.

**Stance travels with the turn.** Swing is read in the dancer's own terms, so leaving the stance
behind until a move finished judged every arm against a frame the dancer had already left.

**Where the couple stand decides everything else.** Measured, one hand held, low: at fifteen
centimetres of clear air the wrist sits four hundredths of its ease from its end; at forty it is
past it; at eighty-five it is nearly straight, with room of 2.80. The rule the page already stated
-- that they stand wherever the joints are furthest from their ends -- is load-bearing. It cannot
be read off `margin`, which counts a stop with no ease as costing nothing to lean on and so reads a
straight elbow as perfectly comfortable, sending the couple out to arm's length where the hands
part after six hundredths of a turn. `limb.room` already drew that distinction.

**Torso's section.** The engine collides capsules, so the ellipse the old contact test used is not
available. Two capsules side by side give a stadium of the same tape round at the same flatness,
and the neck and head fall out of the same line at a flatness of one.

**What it says now, against the floor.** The floor: *everything gets a full turn before it blocks,
except a low wrap, which gets half.* Turning the follow, from rest, at the distance each hold
settles to:

| hold | level | way | floor | old solver | engine |
|---|---|---|---|---|---|
| L-l | low | lock | a whole turn | 1.12 | 0.80 |
| L-l | low | wrap | half a turn | 0.30 | 0.32 |
| L-l | high | lock | a whole turn | 0.41 | 0.40 |
| L-l | high | wrap | a whole turn | 1.25 | 0.20 |
| L-l | above | either | no block | no block | no block |
| L-r | low | lock | a whole turn | 0.87 | 0.76 |
| L-r | low | wrap | half a turn | 0.56 | 0.38 |
| L-r | high | lock | a whole turn | 1.06 | 0.38 |
| L-r | high | wrap | a whole turn | 0.63 | 0.22 |
| L-r | above | either | no block | no block | no block |

Not tuned to it: every change above was argued from the rig or from the old model's own written
rules, and the figures are what came out. The crown agrees exactly. The neck band does not, and
is the open question -- the engine gives between a fifth and two fifths of a turn where the floor
says a whole one, and the old solver was nearer on three of those four.

**Chains, which are why the engine is here at all.** The old solver winds a chain to one crossing
and stops, so it can never draw a diamond or a swan. The engine, cross-name chain over the crown,
reaches **1.28 turns** -- past the diamond at one, short of the swan at one and a half. The
same-name chain at the neck band finds no pose at rest at all, which is a fault and not a finding.

**Rejected: reading anything into `L-l` and `L-r` agreeing.** With centring at two hundred newtons
per metre the two holds returned the same two figures reflected, which cannot be right -- face to
face `L-l` is a reach across one's own body and `L-r` is a straight one, and the reflection that
maps `L-l` anywhere maps it to `R-r`. It was an artefact of centring strong enough to flatten the
difference between them, and it went when centring was weakened: 0.32 and 0.80 against 0.76 and
0.38.

**The old solver stays until the engine is at least as close.** Deleting it now would replace a
model that roughly tracks the floor with one that does not, at the neck band. It goes when the
neck band is answered.
