# Provenance

| Field   | Value |
|---------|-------|
| Harness | Claude Code |
| Author  | Claude |
| Date    | 2026-09-06 |
| Style   | CONSTITUTION.md and STYLE.md, followed. |
| Rules   | 6e80b1a8de3ee978 |
| Review  | **Unreviewed.** Nothing here has been read line by line by a human. |

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

**Every term is agreed with the Architect before it is written.** Each concept is set out with
candidate names and their costs, and only the selected name is written. The audit checks the
glossary's shape and never its words, so this holds by the Architect's reading alone.

**The sim is isolated in code, not in concepts.** It reuses agreed words wherever one fits
and coins its own only where none does; four are its own -- rig, pose, strain, block. What
keeps it a witness is that it imports nothing from `src/` and is told no answer, never that it
speaks another language. Care is needed only where the sim *measures* what the ontology
*asserts*: there the translation stays visible (`sim/verdicts.nim`), since an assumed identity
would be an echo.

**`wind` is `twist`, and the workbench still says `wind`.** `GLOSSARY.md` has listed `wind`
under Twist's _Avoid_ all along, and the workbench uses it in about fourteen identifiers and
across page prose, for the quantity the model calls twist. Architect confirmed the two are one
on 2026-09-07 and put the rename after the frame-position review, so captions do not move
while they are being ruled on. A unit differs where the word does not: the model counts twist
in half turns (`HalfTurns`), this glossary says quarter turns, and the workbench counts turns
as a real number. Which of the three the term means is the second thing that pass settles.

Held back by decision, not omission. The workbook, the base sheet and the vocabulary sheet
wait until the new sheet arrives, since nothing should be written about a file this project
has not seen. The review page waits on the same sheet; the ledger waits on the forty rules
being reconciled. Sweep, stance, moment, rest, room and verdict are the sim's method rather
than dance, and earn no entry; neither does the sim's `(led)` mark, nor its point where the
hands meet, `Grip` naming the manner of holding instead.

**`Block` describes the code.** The term says a turn stops "because no small move holds and
no reachable pose does"; in the engine a small move is the engine carrying the arms on for one
moment, and what stops it is one named thing, decided once in `rigid.stoppedBy` and read by
every sweep, still and page alike (Article II.1). Verified by `trigid.nim`: the turn a couple
are said to reach is the turn some distance carries, and every stop carries its name.

The agreed words disagree with the code in fourteen places, recorded rather than acted on.
From the hand-to-hand half: `frame.position` means the opposite of `Frame position`,
stripping `over` and returning the frame hold said aloud; `Frame` and `rotation.Posture`
split across the frame state rather than along it; `isFacing` returns the parity of twist
where facing is four-valued; twist is counted in quarters where `HalfTurns` is half turns;
`Level.Above` is `Overhead`; `Compound` is `Compound move`; the drawing chain's `route` and
`wind` are `Transition` and `Twist`. From the sim: `Band` is `Level` and its members Low, High
and Overhead; `Body.One` and `.Two` are Lead and Follow; `Aspect.Fore` and `.Aft` are Wrap and
Lock; `Link` is `Connection` and `page.Hold` is `Frame hold`, both words already on avoid
lines; and `Move`, `Twist`, `Chain`, `Way` and `overhead` each name something in the sim
unrelated to the agreed term of the same spelling.

**The review page's layout block was stale in five ways, and is corrected.** The curator left
one line for this project's hand -- the domain folder printed as `síncopa` where it is now
`sincopa`. Four more were false beside it: `transition.nim` was said to hold four primitives
where it holds two; `app/shell.nim` and `tools/review_prose.nim` were named though this
project's own earlier delivery moved them to `pages/`; and the build was invoked as `make`,
retired since. Going past one line was deliberate: the block named three files that do not
exist, two of them removed by this project, and the page is read by the Architect. Its wording
still uses `validator` and `primitives` where the agreed words are `Reference` and `Move`; that
is a vocabulary sweep of the whole page, not this fix.

**Two faults live in generated output, not merely pending renames.** `sim/verdicts.md` prints
`above` and `X`, both on avoid lines, where the agreed words are Overhead and Cross, and it
prints `her arm` and `his arm` in every sweep table, avoided for Follow and Lead. The
translation table stands in two copies, `sim/verdicts.nim` and `design/turns.nim`, and the
second drops the `elbow forward` clause the first adds (Article II.1).

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
drawing that is the same string, which is why every existing pin still matched. Cost: fewer
cells, and a larger page -- 6.9 MB where there were 4.2 -- since a walk shown whole is drawn
as well as its pieces, not instead of them. Every animation runs at one pace
(`WALK_SECONDS`), so the length of a loop says how far it goes rather than how fast: the
whole chain is six times an edge, which is a long loop and is flagged on the page as
something to shorten if it reads as slow. Verified by `tmarks.nim`, which drives the build and so
the gates: the 16 rounds are counted, each asserted to close where it set off, and the
whole-walk figures are held to the same hatch laws as the edges. Verified again by every
drawing on all five pages coming out byte-identical when `steps` and `back` took their
defaults.

**A verdict is given on a picture, so the picture is pinned.** `review_page.nim` lays out
every position the project draws as a card -- the standard diagrams and the one anticlockwise
counterpart, the distinct single-hand turn positions, both hand-to-hand chains, and every
animated edge of the last two -- each carrying the identifier to quote back and whatever has
been ruled on it. The identifiers the Architect has kept or
dropped are named in the module; what each was drawn as when it was ruled on is held as a
hash in `design/review-pins.json`, and the build refuses to write the page when a ruled
card's drawing has moved. Rejected: taking the verdict as given on the identifier, which is
how a mend that reached further than it meant to carried an approval nobody gave. The guard
was proved by widening a break's clearance and watching it name the twelve kept cards that
carry a crossing. Pins are rewritten only by `tools/build.nim pins`, a deliberate second
step: a verdict and its pin are added together or not at all, and running it to quiet a
complaint would hand the approval to the new picture. Cost: the verdicts live in the module,
so every ruling is a commit. Verified by `tmarks.nim`, which builds the page under
testament; by every pin regenerating identical in content when the page moved into the
workbench from the scratch generator that first drew it; and by the tally being counted off
the built page rather than kept while building it, so what the page says of itself cannot
drift from what it holds. The page prints that tally where a reader sees it, which is why no
number of it is written here.

## Body sim

**Two bodies of the average adult and their arms, sharing no code with the ontology.** The rig
(`rig.nim`) is mixed-sex midpoints of ANSUR II medians with AAOS and NASA-STD-3000 joint ranges,
every number with its derivation, and the ranges are what a dancer will do without pain rather than
what a joint can be forced to. A torso is a stadium of its tape round, three quarters as deep as it
is broad, because a round section of a chest's girth stands three centimetres too far out at the
front; the neck and head are round. An arm is three links, upper arm, forearm and hand, on a
shoulder that swings and twists, an elbow that hinges and a wrist that bends within a cone.
Extension is held to 45 degrees behind the frontal plane, adduction to the clinical horizontal
figure of 130 -- the hanging arm's 45 is what the belly stops, and raised, the arm passes in front
of the chest until the chest stops it, so either way the limit is the trunk, which the engine
collides, and the cap is set where the reading can never bind; humeral rotation 90 in and 105 out
with an ease of 25 degrees at either end, so that rotation costs nothing to 65 in and 80 out, about
the AAOS figures, and is refused past the AMA Guides' 90 in and Boone and Azen's 104 out -- the
tables disagree by about the ease's width, and the ease is where they disagree (assumed: which table
a dancer's shoulder follows); the elbow to 140; the wrist's flexion and extension taken as one 60
degree cone, since the forearm's own rotation can turn the plane it bends in. Hands are offered
three bands, torso 1.00 to 1.35 m, neck 1.40 to 1.50, crown 1.735 to 2.00, the crown starting a
limb's radius over the head so a hand carried there clears it by construction. Rejected: importing
anything from `src/`, because shorthand cannot check itself and the sim is what shorthand is for;
not rejected, and reversed since, sharing vocabulary. Verified by `tlimb.nim`: the tape and one
arm's forward kinematics over seeded random arms, and the contact test against a sampled truth.

**A rigid body engine is cloned, not vendored, and Nim alone speaks to it.** `tools/build.nim`
declares `box3d` in `SOURCES` with its repository, its commit
`47d7f7cc7e091142c08d11dc7d2e493c5d34f536`, its reason and its licence (MIT, read from the
repository's own `LICENSE` rather than assumed); `engine` clones there into `deps/`, refuses a
clone standing at any other commit, compiles its C files and archives them into `bin/libbox3d.a`.
The commit is what stands where a checksum stands for a fetched file. Nothing of it is committed:
`deps/` is ignored at the repository root, exactly as Atlas checkouts are. Rejected: its own
CMake, which would be a third build driver in a project whose registry admits no second, and
which nothing in its sources needs, since none is generated. Cost, stated: the build flags are this
project's rather than upstream's, and `-O2 -std=c17` is what upstream's own release build sets.
Measured: 24 s cold, and the verb returns at once where the archive already stands.
`sim/engine.nim` is the binding, Nim throughout, so the gated-language rule is never engaged. It
links the archive and declares what the rig needs: world, body, capsule with its surface
material, ball, hinge, weld and distance joints, contact manifolds, step, world point, angular
velocity. Importing it builds the archive first, at compile time, so a suite that drives the
engine drives its build too (Article IX.6). Verified by `tengine.nim`, which holds it to two laws
and no more: that a body falls half g t squared, which catches a struct laid out wrong where
linking would not, and that two limb-thick capsules started inside one another part to at least
two radii. **The engine stands Y up and this project stands Z up**, and the binding deliberately
does not translate: whatever calls it says which way is up, and `sim/rigid.nim` is the one place
that does.

**What the engine holds, and what it judges.** The elbow's hinge, the wrist's cone and the
shoulder's twist are the engine's own limits. The shoulder's swing is not: the rig gives extension
and adduction as two ranges of their own, and a spherical joint offers one symmetric cone about
rest, which would also bound elevation, for which the rig gives no range at all, and every hold
over the crown would block at once. So swing is read back off the pose in the dancer's own terms
and resisted by a torque, as the other joints are resisted by the engine, at 200 newton metres per
radian past either end (`SHOULDER_BACK`), stiff enough that an arm pressed against its end stays
within `GIVE` of it rather than sinking through. An arm rests against a limit and slides along it;
it blocks only when forced past by more than `GIVE`, which is the room a limit that pushes back
needs to push in. Torque is a pseudovector: each arm is worked out in the body's mirrored terms so
one set of ranges serves both sides, a mirrored frame is left-handed, and un-mirroring a torque as
a plain vector turns the correction into a shove -- the mirror law does not catch this, and the
sign rests on the physics. The stance travels with the turn step by step, since swing read against
a frame the dancer has already left judges every arm wrongly. Rejected: fitting a cone to the
pair of swing ranges.

**Comfort is a slope inside a range, not a wall at its end.** The engine's limits are walls and its
springs, at one hertz (`EASE`), are nothing, so every joint ran to an end and stayed: her arm sat
forty five degrees behind the frontal plane at the head's height for six arm-moments of a crown
turn, which the Architect refused on sight. Each joint's range carries an ease band before each end,
and inside it a torque grows with the lean: swing at the same 200 newton metres per radian as its
wall (`SWING_LEAN`, since at ten her arm still reached the wall), twist at 25 (`TWIST_LEAN`, about
the passive stiffness of a shoulder near the end of its rotation; at seven, three newton metres at
the ease's end was under what forty newtons of lift at reach puts on a shoulder, and joints sat at
their ends in most stills), the elbow at 15 (`ELBOW_LEAN`), the wrist at 6 (`WRIST_LEAN`, which
rings at twelve hertz on a hand); the three are assumed. The arms weigh nothing, and the one thing
weight does to a held arm's elbow -- turn it toward hanging below the line from shoulder to wrist --
is put back as one newton metre (`ELBOW_DOWN`); nothing else weight does is, so it neither loads the
rise nor pulls a hand down. A free arm gets none of it and rests with its elbow near straight
(`HANG_BEND`, assumed): the fixed moment about a hanging arm's near vertical line, against an engine
spring that gives twist next to nothing, an arm being thin about its own length, twisted every
hanging arm forty degrees and swung it forward twenty, forearm pointing at the partner, so a free
couple at rest stood with arms crossed between them. Verified by `trigid.nim`: a free couple at rest
hang every arm near plumb, elbow near straight, untwisted, no arm within its own thickness of the
other's, red first. A free arm's shoulder spring is five hertz (`HANG_HZ`, assumed), standing in for
the weight that holds a hanging arm plumb, about seventeen newton metres per radian for five
kilograms of arm at a third of a metre: at one hertz the spring gave about two, and the flank's
friction dragged her arms behind her slow half turn by forty nine degrees, creeping back to thirty
three through the settle, so A2 stood with her hand 413 mm off plumb; measured at two hertz, twenty
four and eight; at three, thirteen and five; at five, five and four. Verified by `trigid.nim`: a
free couple wound half a turn either way hang every arm within ten degrees of plumb, hand within 0.2
m of it, red first. The wrist's own spring is five hertz (`WRIST_EASE`), the passive stiffness of a
wrist, since at one hertz the wrists sat at their cone at rest once the elbow was turned down.
Friction where arm meets body is 0.2 (`FRICTION`), cloth on cloth: at the engine's 0.6 an arm lying
over a head was dragged round with it as she turned under, winding her shoulder to its end.
Rejected, each measured and each worse: gravity on the arms; higher damping; ramping the elbow;
raising the crown's floor; pulling the hands to a disc rather than a point. Verified by
`trigid.nim`: no held arm over the crown is carried to its swing's end, red first.

**The trunk twists at the waist and does not bend.** The hips are a kinematic body, turned and
never pushed, carrying nothing; every trunk capsule and both shoulders ride on a dynamic chest
hinged to the hips about the trunk's own up, sprung to neutral and stopped at forty degrees each
way (`Rig.waist`), clinical thoracic rotation, with an ease of fifteen (assumed, since the tables
give the end and not where it starts to cost) inside which the chest is turned back toward square
at 60 newton metres per radian (`WAIST_LEAN`, about what a trunk's passive stiffness gives near
that end; assumed). Verified by `trigid.nim`: shoulders yaw on hips no further than the thorax
turns, and rest square.

**Each shoulder is a girdle on a collarbone, and both give.** The shoulder joint sits at 0.18 m
out and 1.40 up, nine centimetres outside every capsule of its own torso, and with nothing there to
give the arms read as dislocated on the viewer. Each shoulder is its own body: a capsule of radius
0.06 (`GIRDLE_R`, an estimate and not tape) from the neck's side out to the joint, deltoid and
trapezius. It hangs on a collarbone, a body of its own at the neck's side (`COLLAR_R`, giving it
half a kilogram, a fifth of the girdle's, since at a fiftieth the solver let both girdles leave
their hinges by half a metre standing still), hinged to the chest about the trunk's up for
protraction and retraction and to the girdle about the trunk's fore for elevation and depression
(`Collar`), the two hinges in series being the universal joint the engine has no one joint for.
Each swing has its clinical range, Kapandji's 25 degrees fore and aft and 40 up and 10 down
(`Rig.collar`), with eases of 10 and 5 to 10 (assumed), is sprung to where tape puts the shoulder
at 4.5 hertz (`COLLAR_HZ`, about twenty newton metres per radian, so that one arm's pull rolls a
shoulder half way to its ease and costs from there; assumed) and is turned back inside its ease at
40 newton metres per radian (`COLLAR_LEAN`; assumed). A girdle was a weld on a linear spring with a
rope at five centimetres, which is a scapula hanging slack: every still with any pull on it had the
shoulder at the rope's end, and a spring alone let a free arm shoved by the other body carry its
girdle 251 mm into its own torso. Hinges also turn the glenoid with the shoulder's roll, which an
arm raised overhead twists by. The trunk and its own girdles share one collision group
(`ownGroup`), since a girdle lies through neck and torso by construction and, hung on a collarbone,
is no longer one joint from the chest; the engine skips bodies one joint joins and nothing else. A
girdle squeezed between two torsos is a shoulder through a body and stops the turn as an arm's
would. Verified by `trigid.nim`: every shoulder joint lies inside some capsule of its own body,
red first at 90 mm outside.

**Bodies are solid.** Contact is held at the engine's own cap, an eighth of the substep rate
(`CONTACT`, 240 hertz at `HERTZ` 240 and `SUBSTEPS` 8), since at the default thirty the sim's own
forces pressed arms through bodies by 45 mm. The upper arm collides with the chest it hangs from,
since the engine lets bodies one joint connects pass through each other unless told otherwise, and
the arm sank 67 mm into its own head unseen. Every joint but the grip holds at the engine's cap
(`HOLD`, 480 hertz); the grip alone at thirty (`GRIP`), the softest thing in the couple, so a hold
forced past what arms can do gives at the hands, in life as here -- at fifteen it fixed one law and
cost every still card. An arm deeper than a centimetre (`THROUGH`) in a body or in another arm,
read off the engine's manifolds every moment, is a stop; before, only the hands parting said so,
and a hold stood with an arm through a torso. The manifolds are read into the room the engine says
a body needs (`touchRoom`): read into room for eight, a forearm wound into a chain and touching nine
things dropped its deepest unseen, and two forearms stood 22 mm through each other with nothing
said. Verified by `tengine.nim`: a body touched by ten things reports every one, and eight when
given room for eight. The trunk's capsules and both girdles are recorded
where the engine has them, so a law reads the engine and never a copy. Verified by `trigid.nim`:
no arm sits inside any body in any moment of the laws' corpus, and every capsule the page draws is
one the engine was given.

**Turning is a path, walked a fiftieth of a turn at a time.** One dancer's hips are spun for 200
engine steps per moment (`walk.BEATS`, `STEP`), slow enough to stay quasi-static, and the arms are
carried on by the engine: a pose at each moment is the pose before it carried on, so an arm that
has gone round a body stays round it. Joined hands rise from where each settled at rest along a
ramp over the first quarter turn of wind (`RAISE`) to their band's lower edge, held to the ramp from
both sides, since asked for the band outright a weightless hand crossed 359 mm in one moment;
risen, the band's two edges are held (`LIFT` 400 newtons per metre, `FALL` 40 damping it) and
everything between them is free -- the band is a bound, not a preference, and face to face at rest
nothing is asked. The rise is keyed to how far the couple have wound from their rest (`wound`,
`risen`), whole turns and all, and to the rest itself for a hold that rests pillion, which is not
face to face: keyed to the distance from face to face instead, which folds whole turns away, the
lift let the hands down onto her head through the second half of every whole turn, and every
diamond and swan was wound with hands at shoulder height; keyed to the hold's own rest, every
same-name still was wound from hands at the hip. Verified by `trigid.nim`: hands are risen through
the second half of a whole turn and from rest pillion, red first. The lift and the draw are put on
as muscle, torque at the shoulder and at the elbow carrying the wrist, with the equal and opposite
torque on the link inside and the shoulder's on the girdle (`muscle`), and never as force on a
hand: force on links alone pulled the whole chain up through the shoulder and dragged every girdle
to its rope's end, and torque at the wrist too bent every wrist to its cone in the first moments of
a rise, the hand being the lightest link. What one arm carries its wrist with is capped at forty
newtons (`MUSCLE`, the arm's own weight, which a dancer lifts an arm against and plainly can;
assumed): uncapped, a hand twenty centimetres under its rise pulled with eighty. Hands are drawn
toward a point as they rise, weakly (`DRAW`, 40 newtons per metre at the torso and neck, 10 over
the crown): between the two bodies below the crown, and over the crown to the axis of whoever
turns, since couple setting a hold up put them there and pulling both to the midpoint spends the
adduction the turn wants. What stops a turn is one thing, asked in order over every arm, held or
free: swing past its range by more than `GIVE`; an arm through a body or an arm (`Stop.Through`,
`Stop.Arms`), a free arm crushed between two torsos being as much a stop as a held one; then, and
only once the hands have parted by `PARTED`, which of twist, elbow or wrist sits at its end, what
the arm was against, or reach; and, once risen, any joined hand further under its band's edge than
the lift's own slack (`SAG`, `Stop.Reach`), since a hold whose hands never rose is a hold at some
other height. Verified by `trigid.nim`: hands that are joined stay joined, no joint goes past what
the rig allows while the hold stands, capsules move where the couple move, and no point of any held
arm leaps more than an arm's reach plus its own move between two moments, 193 mm on the laws'
corpus.

**Where the couple stand is chosen for the turn, and every distance is tried.** The Architect's
ruling: stand for the turn, hand height for the turn, everything for the turn; nothing is fixed but
keeping bodies apart. Standing had been chosen at rest, wherever the joints were freest, and the
couple walked straight out of it: the rest-chosen distance turned 0.22 where 0.36 m turned 1.12.
Every distance from clear of each other (`CLEAR`) outward over a metre (`ROOM`), two centimetres
apart (`SEEK`, since the measured landscape is plateaus four centimetres wide), is swept whole; a
card that asks whether the couple carry a turn (`reaches`) is answered at the first distance that
does, and a sweep shown for its own sake (`furthest`) stands at the nearest distance that carries
the turn as far as any to one step (`chosen`), stepping out only for a stance whose arms move less
than half as far between moments (`SMOOTHER`), and looking a tenth of a metre on once the turn runs
free (`LOOK`) -- since the nearest distance that carried a turn was chest to chest, with joined
hands pinned between the torsos and popping up between the heads: 189 mm in one moment at 0.36 m
over the crown against 86 mm at 0.42, measured 2026-09-18. To one step, since a stop is decided at
the moment something gives and mirror-image holds give a moment apart from the same distance: exact,
L-l stood at 0.42 m for 1.00 of a turn at the neck and R-r at 0.38 m for 0.98. The tie had been
broken toward the stance whose arms moved least, within five millimetres, and the largest leap of a
walk is chaotic: seen in mirror it differs by up to a fifth, and built from the same source by
another compiler by up to thirty five per cent (125 and 114 mm from one distance, 121 and 163 from
another), the last bits of two binaries differing and the engine amplifying them. Five millimetres
stood L-l at 0.44 m and R-r at 0.48 for one hold seen in mirror, and would have stood one hold two
steps apart built twice. Verified by `trigid.nim`: the sums measured that day, put to `chosen`,
stand within one step for the mirror pair, for the pair built twice and for the neck pair whose turn
reached differs by a step, and the stance over the crown steps out from the pinned hands to under
half their leap; red first. A still stands where its pose sits easiest: every distance is wound to
it and the one nearest to ease is kept, a distance at ease outright ending the search and the nearer
keeping a tie, since the first distance that held was chest to chest and a couple asked pillion
there had her free arm crushed between two torsos, shoulder at its rope's end, twist at its end,
waist at forty, with nothing held. Strain is read as the worst over every joint of every arm, both
waists and every collarbone's two swings (`strainOf`, `Strain`): nought outside every ease, one at
some end, more past it, a stop with no ease costing nothing to lean on and counting only past half a
degree (`SLACK`, the engine solving its limits rather than clamping them). A still whose card fixes
no way about -- the standard diagram's frames turned half a turn, which draw the same picture turned
either way -- is wound either way at every distance and takes whichever way sits easier (`either`),
since the card claims a position and not a path: the single hold wound the way asked stood at 0.48 m
with her twist a third of the way into its ease, and the other way about at 0.36 m at ease outright.
Verified by `trigid.nim`: the free way is never worse than the way asked, and is at ease, red first.
Rejected: ranking distances on a cheaper physics and sweeping only the winner, which costs a fifth
as much and does not rank them the same. Verified by `trigid.nim`: no distance carries a turn more
than one step further than the one chosen, the couple are never offered a place inside each other,
and the mirror law holds turn reached within one step and what stopped it exact.

**A still is wound, not built.** A card that draws the couple at half a turn or a turn and a half
draws a winding of the arms, and no facing says that: built at the facing, the couple at a whole
turn stand exactly as at none, so the diamond read as the open frame and the swan as the cross,
and every joined hand hung at hip height, the lift never having started. `walk.stood` turns the
couple there from rest at the walk's own pace, hands lifted as they leave face to face, then lets
them stand, from the distance that sits easiest. Verified by `trigid.nim`: a still asked past
face to face has every joined hand in its band, and the diamond crosses where the open does not,
both red first.

**The reference is asked of the model cell by cell, and the answer is a claim until the Architect
confirms it.** `design/asks.nim` is one list of what every still card asks -- which hands, how far
turned, whose crown the hands go over -- read by `design/modelled`, which answers each and writes
`design/modelled.json`, and by `design/rig`, which records each still. Moving cards ask whether the
couple carry the turn under one manner of the four; an orbit is the other dancer turned the other
way about, so its sense is flipped, and hands are raised over whoever walks under. The page counts
turns clockwise seen from above and the sim anticlockwise, and every wind is flipped in one place
before it is asked (`asked`): flipped for the chains alone, A16 was stood in C5's pose and A17 in
C3's, the mirror of what each card draws, and every single-hand and moving card likewise; the
recorded stills showed it, A16's joint points byte for byte C3's. Verified by `tasks.nim`: one
picture is one question whichever section draws it, A16 being C5 and A17 C3, red first. The
questions are answered on every core at once, each worker listing the questions for itself and
building its own worlds, the engine keeping its worlds in one table it neither locks nor guards, so
making and destroying them is locked in `sim/rigid` (`worlds`): unlocked, two threads took one slot
for two worlds and the verb died of an illegal instruction inside the engine every other run. Every
cell of the reference carries the sim's tag beside the Architect's: *not modelled* where the sim
reaches no pose, *unconfirmed* where it reaches one the Architect has not yet held against their own
body on the viewer, *modelled* only once they have, by name in `CONFIRMED` beside `KEPT`. A
confirmation is of one still, so a confirmed cell whose still moves comes out of the list. The tag
sits outside every drawing and moves no pin. What the sim reaches today is counted off the built
page rather than written here. Two readings of section A come apart at A9 and A11, which draw the
same-name pair face to face, the position the project's own rule 31 says has its connections lying
through each other; wound there from pillion as the card says, the model now stands them at ease,
one connection over the other, which is a finding against the rule's reading and not a number bent
toward the page. Sections B and E being whole is a weak result: every card in them is over the
crown, where a single hold sweeps free past two turns, so they test the model hardly at all; the
cards that discriminate are the chains under wind.

**The viewer draws what the engine collides, beside the cell it answers.** `design/rig` records
every still and eight sweeps as capsule ends the engine reports, at the radius it collides on, and
`design/rig_page` lays every still cell of the built reference page -- drawing, badges and caption,
cut from the page itself so what is compared is what was ruled on -- beside the sim's still of it,
one list of entries walked by two buttons or the arrow keys, with the reference's own drawing next
to the joint readouts on the stage. Orthographic on purpose, so a capsule's outline is exactly a
stadium; painter's order by depth, half weight where two capsules overlap rather than pretending
otherwise; hue is side, shade is whose. A capsule of no length -- each palm is a sphere -- is filled
as a disc rather than stroked as a line of no length (`drawn`), since browsers disagree on what that
is: Chromium draws the round caps as a disc and WebKit draws nothing, and on the Architect's phone
every hand vanished, each forearm ending 118 mm short of the grip it was joined at, seen on A7 on
2026-09-18. Verified by `tdrawn.nim`, red first.

**Against the floor, which is the Architect's.** The floor says everything gets a whole turn before
it blocks, except a low wrap, which gets half. Nothing is tuned to it; every change is argued from
the rig or from the Architect's ruling, and `sim/verdicts.md` prints what came out beside each
claim, so a mend and a regression are both seen. Standing for the turn met seven of the floor's
eight single-hand claims where standing at rest met none, which is the strongest evidence so far
that the floor was right and the model wrong rather than the other way about. With bodies solid
the crown is free both ways, both low lock ways and the cross-name high lock go past the floor's
whole turn by her wrist, and the wraps stop between half and a whole turn by her twist or his
wrist; each disagreement is printed and is the Architect's to rule on.

**Verdicts are an instrument run, assumed current.** `sim/verdicts.nim` asks the sim what the sheet
asks and writes `sim/verdicts.md` in the sheet's words through one visible translation table,
wrapped at 100 columns; the chain rungs there are wound to, as stills are. No test compares the
committed record with the model, so it is current as of its last run and stale until rerun, and
it is rerun in the same delivery as any change to the model.

**The swan is the position the model does not reach, and its cause is measured this far.** With the
lift keyed to the wind, both diamonds stand, C2 and C6 at 0.48 m with her wrist a fifth of the way
into its ease, where before they wound with hands at shoulder height and failed, and the four swans
are the only stills of the reference no distance holds. Every other still stands at ease or within a
degree of it: the corpus law in `trigid.nim` holds both chains from cross to cross, the free frame
pillion and the single hold at quarter and half to a strain of 0.05, one degree of a twenty degree
ease, and stops at the cross until the model reaches further. They wind from every distance and give
short: cross-name at 0.74 to 0.88 of a turn, hands under their band or an arm against an arm;
same-name at 1.22 to 1.26, an arm against an arm with her collarbone retracted to its end and her
chest at forty. The film of the wind shows why: from the cross on, her arms wrap round her head at
the neck's height rather than pass over it, since hands carried at the band's lower edge, a hand's
radius over the crown, leave no room for a forearm to cross above the head. Carried a hand's breadth
higher, or on up through the band (assumed lofts), the cross-name swan winds to 1.14 and the
same-name gives early by twist; the two pairs of joined hands gathered together over the crown, as
the reference draws the swan's two joins at one point, one pair under the other, winds the
cross-name to 1.34 with her collarbone at its end. Eight one-line changes on the lofted model, each
measured on both swans at four distances with five held stills as control: none stands a swan; a
stiffer grip and a finer step carry the cross-name furthest, to 1.16 and 1.32, hands parting or her
wrist at its cone; a wider wrist cone and a firmer draw carry the same-name furthest, to 1.42 and
1.38, arm against arm; a softer collarbone, wider extension or a stronger loft lose a diamond.
Rejected outright: the lead's arms passing through the follow's, which reached the swan by letting
two arms occupy one place. What the swan is in the body stays the open question below; the
reference's own drawing of it, both joins at one point with the right-over-left connection under,
reads as the extra turn beyond the cross living between two stacked pairs of hands turning about
each other, and the model has no hold that turns so.

**Known and not mended: the crossing reader is a knife edge where two arms lie along each other.**
`read.crossings` counts where two connections cross in plan by a segment intersection, and two
poses differing by less than a float's precision have read as four crossings and as one when a
crossing sits at a vertex of both polylines. The verdicts tables and the diamond law read it on
poses well away from that edge (loosening its tolerance six orders of magnitude changed no count
on any kept chain card); a law that samples arms laid along each other on purpose is owed, and
the fold rule is repository issue 88.

## Pages and build

**Published titles say which pages the project stands behind.** The validator does, titled
`Dance Ontology — …`; every other page is a mock-up or an instrument and is titled
`Dance Ontology Mockup — …`, which is the line `CONTRIBUTOR.md` already draws between
`pages/` and `mockups/`, so a gallery holding both says which is which before either is
opened. The body sim's page was the second that stood behind, and it went with the solver it
drove; the viewer that replaced it plays sweeps recorded here and is titled as the
exploration it is. The name is spelt once, in `tools/title.nim`, and the mock-up form is
derived from it (Article II.1); `design/page.nim`, `tools/bundle.nim`, `tools/review.nim` and
`design/wholecloth.nim` all read it, and before this it was written twice and drifting.
`tests/tmarks.nim` and `tests/treview.nim` assert the built pages carry the mock-up form and
never the plain one, against the constant rather than against a repeated literal:
**verified**, by breaking the constant and watching both suites fail. Every title reads in
title case, which `tests/tmarks.nim` holds each page to, off the title the page was written
with rather than off a list: red first on the viewer, which shipped with a sentence for a
title while every page beside it was cased.
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
validator's shell is `pages/app/index.html`, the review page's prose
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

**The project's verbs live in a compiled driver, since make is retired.** `tools/build.nim`
takes one command and runs it from the project directory, each named and explained in the
table at the head of the file: the pages and their assets, the engine, the four recordings
(`modelled`, `rig`, `turns`, `verdicts`) that rewrite committed data nothing else may edit,
the pins, the screenshot helper, the system declaration and `clean`; koch drives the tests and
holds no verb for pages. Rejected: a nimble task, which would put build logic in the compiler's
virtual machine; asking koch for a project-specific verb. Cost: the driver runs from the
project directory, since every path in it is relative, and each recording costs minutes, which
is why none runs under `pages`.

**Every page ships the three faces it draws with, inlined.** Titles take Noto Serif, body
text Noto Sans, code and data Commit Mono, which are the Architect's standard three and what
Article X.8 names. Labels drawn inside figures take Noto Sans rather than Commit Mono: X.8's
"code, data and figures" reads as numbers, and a label naming a hand is interface text.
Seven faces are fetched by `tools/build.nim`'s `assets` verb into `build/fonts`, never
committed, each pinned by package version *and* SHA-256 — version because an unversioned
path serves whatever the host resolves that day, digest because the bytes are embedded in
what readers open. `design/faces.nim` inlines them as data URIs and `pages` dresses every
page it wrote, once, after every writer has run; doing it there rather than in each writer
is what keeps the suites free of the network, which is **verified**: every suite passes
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
per-project autonomy moved. This project was the first to draw from it, and
`rga_visualiser` draws from it too.

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

## Tests

**Testament over `tests/t*.nim` from the project directory, one stub per suite.** Each stub
carries the curator's header; `trigid.nim` adds `-d:danger` because the sweeps are the slow part
and `doAssert` survives it, and is not joinable, since it links the engine's C archive, which
testament's joined binary cannot share. Test binaries inherit testament's working directory, so
`build/review`, `build/design` and `walkFiles("tests/t*.nim")` resolve only when testament runs
from the project directory, as koch's runner does; running it from the repository root breaks
them. Cost: `trigid` is nearly the whole of the suite's wall time, and a model change that leaves
a sweep with no moments crashes a danger build rather than reddening a law.

## Figures

- `trigid.nim`, danger build, under `nim r koch ci`: 331 s wall, four Xeon cores shared with
  nothing else, Linux amd64 container, Nim 2.2.12, 2026-09-13. `tmarks` 12.6 s, `tread` 7.9 s,
  `tengine` 3.3 s, every other suite under 2 s. Single figure, no pair: unmeasured as an
  optimisation.
- `tools/build.nim modelled`: 913 s wall, same machine and day, with two other recordings
  sharing its cores; unmeasured alone.
- `tools/build.nim rig`: 523 s wall, same day, sharing cores with the suite; unmeasured alone.
- `tools/build.nim verdicts`: 1079 s wall, same day, sharing cores with two other recordings;
  50.2 s on 2026-09-10 with the pose search that preceded the engine, which is a pair across two
  models and not an optimisation.
- `tools/build.nim pages`, every page with faces from the shared store: 26 s wall, same day.
- `tools/build.nim engine`: 24 s cold, at once where the archive stands.
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

Declared unmet, so the Style row above stays true (Article VIII.1):

- VI.1: a few declarations in `sim/verdicts.nim` carried no doc when the driver moved; the ones
  touched since gained one, the rest keep `## TODO: Document.` in spirit but not in text. Cost: a
  reader opens the body.
- X.2: banner tiers are unmarked; every banner is spaced as second tier.
- VII.1: emitted-code readings exist for the whole-cloth port only; the validator and the
  viewer were written before the rule and their binding shapes are unread. Cost: a copy in a
  hot path may hide there.

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

## Open questions

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

- **What the swan is in the body.** The reference draws it pillion with all four hands above;
  asked about a hammerlock, the Architect described a low one -- arm down, shoulder rotating in
  as the hand goes behind the back, elbow bending behind to an L. Which the swan over the crown
  is, and whether the extra full turn beyond the cross lives in the wrists and the hand hold or
  in the arms wrapping each other, decides the four still cards the model does not reach and
  every moving card into them. Asked. Meanwhile the reference's own drawing of the swan, both
  joins at one point with the right-over-left connection under, reads as the turn living between
  two stacked pairs of hands, and the model's hands, carried at the band's edge, wrap her arms
  round her head instead; the levers tried are recorded under the body sim.
- **Every still awaits the Architect's confirmation against their own body.** They have said
  many are wrong and will say what is wrong with each, cell by cell on the viewer; the tags
  read *unconfirmed* until then.
- **The floor at the low and neck bands.** The wraps stop between half and a whole turn by her
  twist or his wrist where the floor says half or whole, and the low locks go past the floor's
  whole turn; whether a hammerlock goes a whole turn, and what moves in the body when it does,
  is the Architect's.
- **The girdle's radius, 60 mm, is an estimate and not tape.**
- **Two one-moment flips in the cross-name crown turn**, 370 mm as his arm straightens over at
  0.28 and 220 mm as hers turns over at 1.18, which weightless links with springs this weak do
  at no cost; the leap law's corpus does not include that sweep and says so.
- **The crossing reader at a knife edge**, arms laid along each other, repository issue 88.
- **Whether section A's cards are a question a body can be asked.** A9 and A11 draw the
  same-name pair face to face, which rule 31 says has its connections lying through each
  other; the model refusing them agrees with the rule.
