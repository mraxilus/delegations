# Provenance

| Field   | Value |
|---------|-------|
| Harness | Claude Code |
| Author  | Claude |
| Date    | 2026-09-06 |
| Style   | CONSTITUTION.md and STYLE.md, followed. |
| Rules   | 125f0baf69b4f5ec |
| Pruned  | f07b7566aac6619f19090f8341936158bf0e9800 |
| Review  | **Unreviewed.** Nothing here has been read line by line by a human. |

Origin: built from three sources.

- The workbook of the Architect, `ontology.partnerwork.xlsx`, sheets `base` and `vocabulary`.
  `src/dance_ontology/workbook.nim` holds the `base` sheet as data, and reads the words that the
  `vocabulary` sheet gives for a move.
- The drawing rules of the Architect as given, held as data in `design/rules.nim`.
- For the body simulation, the ANSUR II medians with the AAOS and NASA-STD-3000 joint ranges, in
  `simulation/rig.nim`.

There is no vendored source.

That workbook is **superseded**. The Architect has replaced it with a newer sheet that this project
has not been given. Nothing is deleted, so nothing goes dark. But every finding that the audit
reports is about a document no longer in use. The transcription, the audit and the suite are
replaced together in one delivery when the new sheet arrives. Until then they are stale by
construction, and not by neglect.

## Language

**Every term is agreed with the Architect before it is written.** Each concept is set out with
candidate names and their costs, and only the selected name is written. The audit checks the shape
of the glossary and never its words, so this holds by the reading of the Architect alone.

**The simulation is isolated in code, and not in concepts.** It reuses agreed words wherever one
fits, and coins its own only where none does. Its own words have entries too, such as rig, pose,
strain, block, band, sweep, walk, path, style and verdict. What keeps it a witness is that it
imports nothing from `src/` and is told no answer. It is not that it speaks another language.

Care is needed only where the simulation *measures* what the ontology *asserts*. There the
translation stays visible, in one module that is named for it (`simulation/words.nim`), because an
assumed identity would be an echo.

**`wind` is `twist`, and the workbench still says `wind`.** `GLOSSARY.md` lists `wind` under the
_Avoid_ line of Twist. The workbench uses it in about fourteen identifiers for the quantity that the
model calls twist. The Architect confirmed on 2026-09-07 that the two are one. No page says it in
that sense, and the build's own notes still do. The rename comes after the review of the frame
states, so that captions do not move while they are ruled on.

A unit differs where the word does not. The model counts twist in half turns (`HalfTurns`), this
glossary says quarter turns, and the workbench counts turns as a real number. This glossary holds
the quarter turns and the real number as one concept at two grains. So which unit the model keeps is
the second thing that pass settles.

Held back by decision, and not by omission. The workbook, the base sheet and the vocabulary sheet
wait until the new sheet arrives. Nothing should be written about a file that this project has not
seen. The ledger waits on the reconciliation of the drawing rules.

**`GLOSSARY.md` holds the vocabulary as the Architect ruled it.** A contradiction is a word that
meets an agreed entry, or that carries more than one meaning. The rulings of each contradiction, of
2026-10-04, are word for word in [the comment on #226][rulings]. By them, sweep, rest and verdict
each have an entry, with the other words that they ruled on.

[rulings]: https://github.com/mraxilus/delegations/issues/226#issuecomment-5982118469

Stance, moment and room are the method of the simulation rather than dance, and earn no entry.
Neither does the `(led)` mark of the simulation, nor its point where the hands meet, because `Grip`
names the manner of holding instead. The code calls that point the join, and the joint that holds
it the tie (`TIE`), as ruling 7 of #226 asks. So Grip keeps its sense in the code too. The
simulation models every grip from the palm grip to the finger grip (Body rig).

**`Block` describes the code.** The term says that a turn stops where a body or a twist blocks it,
where "no small move holds, and no reachable pose does". In the engine a small move is the engine
carrying the arms on for one moment, and what stops it is one named thing. That thing is decided
once, in `rigid.stoppedBy` or for a free arm in `rigid.stoppedFree`, and read by every sweep, still
and page alike (Article II.1). Verified
by `test_rigid.nim`: the turn that a couple are said to reach is the turn that some distance
carries. Every walk that stops names what stopped it, as kept and as walked again live.

`seen.still` marks a still that holds at no distance and in no plan as stopped, and names no stop.
The rig viewer then says that no pose holds at any distance (`design/rig.nim`). No law stands such a
still, because every still card holds a pose. The law that every card is modelled
(`suites/test_asks.nim`) leaves out the six moving cards that the edge of the shoulder refuses. No
still is among them (Planned turn).

The agreed words disagree with the code in the places below, recorded rather than acted on. From the
hand-to-hand half:

- `frame.position` means the opposite of `Frame position`. It strips `over` and returns the frame
  hold said aloud.
- `Frame` holds the frame hold and one part of the frame position, which arm is over.
  `rotation.FrameState` holds the rest of the frame state beside it.
- `isFacing` returns the parity of twist, where facing has sixteen values, as `Facing` holds them.
- Twist is counted in quarters, where `HalfTurns` is half turns.
- `Compound` is `Compound move`.
- `transition.route` returns a transition, which the avoid line of Transition never calls a route.
- The `wind` of the drawing chain is `Twist`.

From the simulation:

- `Body.One` and `.Two` are Lead and Follow.
- `Aspect.Fore` and `.Aft` are Wrap and Lock.
- `Link` is `Connection`, a word that already sits on its avoid line.
- `Twist` and `Chain` each name something in the simulation that is unrelated to the agreed term of
  the same spelling.

`Band` has an entry of its own, as the height range where the simulation holds a level. Its members
are `Torso`, `Neck` and `Crown`, and the pages and this record say low, high and above. Verified by
a search of the text of every built page on 2026-10-04. There, torso and neck name only parts of a
body, or quote the sheet.

**No string that writes a recorded sweep names a dancer with a gendered word.**
`simulation/verdicts.md` heads the arms of its tables by the lead and the follow, and its own verb
writes it. Verified by `suites/test_glossary.nim`, which reads each string literal of the `.nim`
files under `simulation`, `design` and `app`. It does not read the report. Verified by hand with GNU
grep 3.11, 2026-10-04: the report holds no word that the glossary rejects for a dancer.

**One translation table, which the report and the laws read.** `simulation/words.nim` holds the
table (Article II.1). Rejected: a copy for each reader, which keeps the translation visible in each,
but drifts until one pose has two answers.

**The report names each rung with the word of the glossary.** Verified by
`suites/test_glossary.nim`, which reads the rungs back out of `simulation/verdicts.md` (Article
IX.5).

That law reads the words of the report, and never its numbers. Nothing in the audit runs the
sweeps again, and the numbers come from readings kept in `simulation/verdicts.json` (Kept answers).
So the report can hold a figure that the physics no longer gives, and only a delegate who runs the
verb will see it.

**The table that the report prints names every phrase that `said` can return.** The report opens
with the translation, so a reader knows what each phrase means. The table is written by hand, and it
is a derived view of `said` (Article I.4). Verified by `suites/test_words.nim`: it walks every
phrase, strikes out each term that the table names, and refuses any residue.

**`open` is what one arm is, and the middle of the chain is a neutral twist.** The word named two
things. One is the middle of the chain, where the pair carries no twist. The other is an arm that
lies on neither face of its own body. Article VI.8 asks for one meaning for each word. The
Architect ruled that `open` keeps the arm, and named the middle of the chain **Neutral**.

Rejected: one concept for both meanings, on the grounds that an open twist means both arms are open.
The sweeps measured below refuse it in both directions.

**Measured** over all 1,469 moments of the twelve low and high sweeps of six frame holds kept at
`d41e790a`, with Python 3.11 on 2026-10-09. The six `above` sweeps are left out, because `said`
answers with the level there. 211 moments have every held arm saying `open`, and 202 of them stand
at a turn that is not nought. `R-r` low reads open out to +0.48 turns, and `L-l` low out to -0.48.
At nought turns, three of the twelve sweeps carry arms that are not open. `R-r` high reads
`wrap high (led)`, and the same-name pair reads `lock` on the arms of the Follow.

A pair holds four arms, and they disagree, which is what breaks the equivalence rather than a
threshold set a little wrong. The same-name pair rests Face-to-back, so the Lead reaches forward
while the Follow reaches behind their own back. One moment of it reads `open`, `lock low (led)`,
`open`, `lock low (led)`.

`neutral` is half of the agreed term, so the avoid line of Open does not hold it. Verified by
`suites/test_glossary.nim`, which reads the ruling from `GLOSSARY.md` rather than restating it. The
old name fails both of its laws. The step says a word the glossary rejects, and it carries no word
the glossary agrees.

Issue #235 holds a table, sweep by sweep, of where every arm reads open on 2026-09-23. Nine of its
twelve rows do not match the twelve low and high sweeps kept at `e1dfe667`.

**An avoid line cannot be held by matching the word.** The glossary rejects `wind` for the quantity
that Twist names. The pages also use `wind` as a verb, where the arms wind, and that use is right.
A check that matched the word would refuse both, so the avoid line of Twist holds by reading alone.
The avoid lines of the chain and of the two dancers hold by law, because every word on them is
wrong in every use.

## Facings

**The model names all sixteen facings, from the side each dancer turns to the other.**
`rotation.Facing` holds sixteen states, and `facing` reads one off where each dancer sees the
other: ahead, right, behind or left. That is the side each turns to the other: face, starboard,
back or port. A name gives the side of the Lead, then the side of the Follow. So a quarter turn by
the Follow to their right is `Face-to-port`. The Architect ruled so (#289).

**Port and starboard name the sides of a body, so a facing never reads as a hold.** Left and right
name hands, as in the hold `Right-to-left`. Side by side, with the Follow at the right of the Lead,
would take that name too, so it is `Starboard-to-port`. Rejected: Pillion and Sidecar kept as
names for groups of states. A group word alone does not say which state, and the glossary gives
each state one name.

**A facing needs the turn of each dancer, and not twist alone.** A dancer who turns on the spot
changes what they see, and nothing that the other sees. Twist is the Follow's turn less the Lead's,
so it is the same for Face-to-face and Back-to-back. That is why a facing takes four bits.

Verified by `suites/test_rotation.nim`, suite "Internal: Facings". The law writes out the table
of #289, and holds each state to the name in it. Each name gives the side of the Lead, then the
side of the Follow, in the words of the glossary. Each law failed on a break made on purpose. The
breaks swapped starboard and port, named the Follow first, and set the side of the Follow in
capitals. One more listed the sides of the glossary in another order.

**The drawings name a facing by reading the pose back through the model.** `facingDrawn` in
`parts.nim` reads a drawn pose back as a facing, from where each dancer sees the other.
`turnedFacing` names the facing that a turn on the spot of each dancer draws from Face-to-face. The
Reference says through it which facing each standard diagram draws.

Verified by `suites/test_marks.nim`, suite "Internal: The sixteen facings, drawn". Its law holds
`turnedFacing` over all sixteen facings. Its domain is `ORIENTATIONS`, which finds in the model
the turns on the spot that reach each facing from Face-to-face.

**The rests and the chain name their facing.** A hold rests where its two connections run parallel
and cross nothing (rule 31). `parts.facingRest` names that facing, read off the pose through the
model: Face-to-face for hand to hand, and Face-to-back for the crossed pair. `parts.facingAt` names
the facing of each step of the chain in the same way. The Reference takes each name from there,
and the rig viewer reads its headings from the Reference. Each card of the Reference carries its
rest as a `Facing`.

**The simulation reads its own facing, and `simulation/words.nim` names it.** The simulation imports
nothing from the model, so it cannot be told a facing. `body.quartersTo` reads where each body sees
the other, in quarter turns clockwise from its own front. `words.FACINGS` names each of the sixteen
states from its own words for the four sides. The report names each rest and each rung of the chain
through that table, and prints the table with the rest of the translation.

**The simulation rests a couple at two of the sixteen.** It stands them Face-to-face, or with the
follow turned half, which is Face-to-back. Where the hands rest is keyed to twist alone (`up`), and
twist does not tell Back-to-back from Face-to-face. So `asks.isRestAway` refuses every other rest,
and no card asks one. Where the hands rest when a dancer turns a side to the other is not ruled.

Verified by `suites/test_words.nim`. In each of the sixteen states on a quarter, the name the
simulation gives is the name the model gives. Verified by `suites/test_asks.nim`: each chain rests
where rule 31 says, and the simulation stands each card at the rest that the card names. Verified by
`suites/test_glossary.nim`: each rung of the report stands at the facing that the model gives its
turn. Verified by `suites/test_marks.nim`: the Reference prints the names that the model gives.

**No page and no report names a facing by a name that the glossary replaced.** The entry for Facing
rejects Pillion and Sidecar. `suites/test_glossary.nim` reads the whole report, and each string that
a page shows, for each capitalised word that the entry rejects. Its lower-case words, such as
`front`, are left out, because a page says them in their own sense. The law failed when the label of
one hold said `Pillion`, and when the entry dropped the names.

## Model

**One state and one relation, and everything else derived.** A `Frame` is what each hand of the lead
holds, and how the arms lie where they overlap. A move exists between two frames exactly when their
difference is one connection: `collect` adds it, and `drop` removes it. The two compound moves,
`place` and `cut`, are the pairs of moves that the vocabulary marks with an asterisk. Names,
keys, transitions and reflection are all read off the frame (`frame.nim`, `transition.nim`).

Rejected: to name frames for what a dance calls them, which puts the hand-to-hand frame and the
empty frame under one word (`open`). The empty frame is `free`. Cost: `closed` and `half-closed`,
which rest a hand on a body, have no frame here, and wait on a vocabulary for places on the body.

Verified by `suites/test_frame.nim` and `suites/test_transition.nim` over every pair of the eight
frames, which is 64 pairs, exhaustive. They cover validity, naming round trips, reversibility,
mirror symmetry, one law for each move, and full connectivity.

**The workbook is data, audited, and never trusted.** `workbook.nim` holds the states and cells of
the `base` sheet as constants, and reads the words that the `vocabulary` sheet gives for a move. It
derives findings by kind. A cell names a move the model lacks, or the model has a move the sheet
lacks. A helper word differs, or a cell waits on the body.

Verified by `suites/test_workbook.nim`. Eighteen of twenty-seven cells are checkable today, and all
eighteen name the move that the model derives, with nothing missing and nothing spare. The nine
deferred cells are counted, and not hidden.

**Rotation is provisional and off the page.** `rotation.nim` holds twist, the three arm heights, the
two blocks, blockers, wraps and locks. It also holds the measured fact that a low wrap holds half
a turn, where everything else holds a whole one. `axle.nim` draws its frame states as one line,
placed by the twist itself.

The views do not show it. 148 frame states render as 17 distinct pictures, because level, contact
and twist beyond its parity have no marks, but for one frame. `Left-to-right and Right-to-left`
draws half a turn of twist one way apart from half a turn the other way. Measured by hand on
2026-10-02, with `renderFrame` over `frameStates()`. An Explorer whose picture cannot tell two
states apart cannot check them. The capacity constants are witnessed by the simulation
(`simulation/verdicts.md`), which is evidence, and not authority.

## Drawing chain

**One drawing chain serves the Explorer and the workbench, so they cannot drift.**
`draw/` builds the picture of a frame from the couple seen from above. There are two plain circles
with a chevron for facing, and the lead is at the bottom facing up.

Squares stand for the hands of the lead, and circles for the hands of the follow. Each one takes the
hue of its side and the shade of its owner: deep for the lead, and plain for the follow. So shape
and colour say whose hand it is at any size, and no caption is needed.

A connection meets at its middle in the inks of both hands. It goes **round** a body and never
through one. It is a taut string that hugs the rim only where the straight way would cross a body.
Only `above` never hugs a rim, because it is over the head. It runs straight, unless the pair winds
it (`route.wound`) or it bends past a mark (`route.clearedReach`).

The way round of a move is settled once for the whole move (`oneWayRound`). No two animated frames
can then disagree about which side of a body the line passes. Rejected: per-frame routing with a
side bias and hysteresis. It drew lines that swept straight through a body, in the blend of the
browser between two frames.

Level is a fill on both ends: hollow unsaid, solid low, dotted high, and hatched above. A hand that
has left its default leaves a grey ghost. The lead always faces up, because poses live in world
coordinates and are drawn through `canonicalise`, so every equal configuration is one picture.

Cost: the picture of every frame is built at compile time. The browser then ships finished markup
and none of the routing, at the price of compile time. Verified by `suites/test_diagram.nim`, where
every picture says what its frame is, at any size. Verified by the gates of the workbench
(`design/checks.nim`), which assert on the Reference.

**Rule 24 is measured along the reach, and not only at its sharpest corner.** A settled reach picks
its way past the marks it must not touch. It weighs three candidates on length and turns together
(`readingCost`): the taut string, and a bow over each side. `crestReach` measures rule 24 along the
reach. A reach that leaves its chord must crest away from both hands.

Rejected: the taut string taken unweighed where it turns little. It hugs a mark near a hand, so it
bends only at its far end. **Measured** on B04 and B23 of the Reference, 2026-10-08: that hug
crests 0.88 along its chord, with 6.5 degrees at one corner. The bow crests at 0.59 on both, with
0.6 degrees. Other bending reaches crest between 0.40 and 0.60. Rejected: to tune a clearance to
move the hug, which leaves the rule measuring half of itself.

Cost: three relaxations of the string for each settled reach, where one sometimes did, which
takes the mark suite from 20.9 to 23.3 seconds. The bow beats the hug on those two by a hundredth
of a unit of line, so the preference is real but thin. It is the fixtures of the Reference that
keep a flip from passing unseen.

**The chain is walked, and not jumped, so what lies between two frame states is seen.** Past a
whole turn the pair stops sharing its swing evenly. One connection gives its bend up and runs
straight, while the other snakes round it (rule 31).

Rejected: a fast start. It does not bring the third crossing on sooner. It shrinks the straight
connection to a stub for most of the walk, so the swan does not open out of the diamond.

The hand-over is slow at the start and quick at the end. The connection then keeps its bend nearly
all the way, and gives it up at the last. The hand-over is nothing at a whole turn and everything at
a turn and a half. That is exactly where the frame states of the chain sit, so no still depends on
it. Verified by the fixtures of the Reference, which hold every ruled card to what it was drawn
as (`design/reference_page.nim`). `suites/test_marks.nim` builds that page, so the fixtures run with
the suite.

The ease of the hand-over is 7.0 (`SWAN_EASE`). A softer ease lets one arm lie flat over the other
near 1.3 turns. Measured over the stretch at two-hundredths of a turn, the connections cross at
least twice everywhere. A check walks that stretch and holds it.

**A break never leaves a sliver, because a sliver draws a dot, and a dot says the opposite of a
break.** A round cap draws a piece of no length as a disc as wide as the line. At a hand, the dot
reads as a detached connection. Inside a break, it reads as two connections that pass through each
other.

Three places can leave such a piece. One is a crossing near the end of a reach. One is a seam
between two shades of a reach, or between two breaks. The last is the tail of the smoothed curve.
The dash pattern is measured along the polyline and spent along that curve, which is about half a
per cent longer.

`SEEN_RUN` names the least piece that reads as a line. `gapFor` narrows a break rather than drops
it, and keeps that much line at each hand. It gives up only where the gap would be narrower than the
line it hides. The dash pattern gives any shorter piece at a seam to the break, and runs it a stroke
past the end of the polyline.

Rejected: to widen the suppression threshold. That draws more crossings with no break at all, which
is the opposite of what rule 14 asks. Verified by `suites/test_marks.nim`, which drives the build.
Every piece that a break leaves is nothing at all, or at least `SEEN_RUN`, over every frame of every
edge of every manner.

Cost: a break near a hand is shorter than a break in the middle.

**The third crossing arrives once, and the snake pulls in before it opens.** From a whole turn to a
turn and a half the pair gains one crossing. So the picture reads two crossings and then three, and
changes once. A crossing that dives under a hand mark can take no break, so the count falls there.

The two connections do two different things past a whole turn, so they take two shapes rather than
one shared between them. The straight one **hinges**: it gives up its bend late and then all at once
(`SWAN_EASE`). The snake **pulls in** against it while the pair tightens (`SWAN_DRAW_IN`,
`SWAN_DRAWS_AT`), and only then **opens out** into loops that go round it (`SWAN_SWING`,
`SWAN_OPENS_AT`).

That order is what does the work. The snake is at its tightest, 0.82 of the swing of one connection,
at 1.42 turns, and opens after. **Measured** every hundredth of a turn with `parts.pairAt` and
`route.crossings`, 2026-10-08: the third crossing arrives at 1.24 turns. There it is 7.74 from the
centre of the nearest hand, against a trim of 7.7. It moves away, then comes back to 12.6 from the
centre of a hand at 1.43, while the snake is still at 0.82. A snake that opens early drives it under
the mark.

Rejected: one width for the whole stretch, which is what a single `SWAN_SWING` is. The widest such
swan that keeps the count monotonic bows 14.1, against the 22 that the Architect had. In that shape,
width and crossing placement are one number.

Cost: the snake gains 0.26 of its swing (`windShare`) over the last hundredth of a turn, which is
5.2 of line. Looked at frame by frame, 1.43 to 1.50, it reads as loops opening rather than as a
jump. That was verified by looking, 2026-09-08, and not by test.

Verified by `suites/test_marks.nim`, which drives the build. A gate walks the stretch every
hundredth of a turn, and fails if the count ever falls, or rises other than once. Two more hold the
snake to drawing in before it opens. The swan bows 22 round its straight connection.

**The two connections keep clear of each other where they run alongside.** Where their middles come
closer than the line width, 3.4, the ink merges. One connection then seems to run into the other,
and not across it. The pinch keeps growing past a whole turn (`WIND_NIP_MORE`). Rejected: a cap on
the pinch at one turn, which draws the winding as stopped. The snake pulls in toward `SWAN_DRAW_IN`
0.65, and reaches 0.82 at 1.42 turns, before it opens to `SWAN_SWING` 1.50.

**Measured** over the stretch every hundredth of a turn: at 1.37 the middles keep 6.51 apart. The
tightest gap where they do not cross is 4.81. The shallowest crossing is 28.9°, which is well clear
of `GRAZING`. Below `GRAZING` a break cannot cover what it hides. Verified by looking at 1.35, 1.37
and 1.39, 2026-09-08.

**No gate holds this**, and that is a gap rather than an oversight. Every measure of it that runs
over the whole stretch is dominated by two other effects. Those are the width of a break at its own
edge, and the arrival window below. So no threshold separates the mended drawing from the faulty one
with any margin. It is stated here so that a later pass knows it is unfenced.

**Amplitude moves a crossing, though a short argument says it cannot.** The argument is that both
connections carry the same sine about the axis of the pair, with opposite sign. So they meet only
where the sine vanishes and the size cancels. It compares the two reaches **at the same point along
each**, which is only their crossing condition where they share a chord.

They do not share one. The two hands of the follow sit up to 40 units apart *along* the axis of the
pair, the full width of the body. That holds wherever the follow has turned off a half turn, so the
two chords differ everywhere between the frame states of the chain.

**Measured**: hold both connections at one common share, and sweep it from 0.5 to 2.0. The count at
1.20 turns moves through 0, 2, 3 and 1. The argument earns its line, because anyone who derives it
again reaches the same wrong place.

**The map and the spokes are the same picture at two distances.** `map.nim` draws the whole ontology
with every line laid down before any word. Names are cut into the line with round caps, and never
painted over. A hole in a line means that a connection passes underneath. The order of the tower is
fixed once (`towerOrder`), so the matrix and the map read the same way.

`spokes.nim` draws only the frame held and every way out of it. `motion.nim` says when each drawing
moves and for how long, so the page waits on the schedule of the drawing itself. Verified by
`test_map.nim` and `test_spokes.nim`. The window that a move ends in is the window that the frame is
given when still. Where it leaves the frame standing is the place that the frame is given when
still. That is what makes the swap of one drawing for the next invisible.

## Explorer

**Three views, in the order that a reader wants them.** Atlas is every frame, drawn and counted, and
the page opens there. Dance is the state machine from `free`. Matrix is every move at once, drawn
rather than tabulated. Both axes carry the pictures of the frames at one size, and a matrix cell is
the same mark that the map uses. Only what the ontology derives can be clicked, and a compound move
dances both its moves in turn.

The close drawing hands its geometry to the style sheet as bare numbers, and takes back one unit.
That unit is registered with `@property`, so a recentre animates the scale. It stops shrinking when
names reach 8 px, and scrolls instead. `--wide` is the width at which the map is worth opening on.
It is written once in the style sheet, and read by the script.

Keyboard: every control is reachable, focus returns after each move, and a live region outside the
rewritten region announces what was danced. Verified by hand in a browser at 390, 600 and 1200 px
before the move. The mark and the frame land in the same place either side of the swap. It has not
been driven again since, so it is **assumed**. Which browser, and on what date, was not recorded, so
this cannot be repeated from a checkout. Whoever next touches the shell drives it again, and writes
both down.

The shell is the committed file `pages/app/index.html`, copied out by `tools/pages`. The bundle
(`tools/bundle.nim`) folds `app.js` into it as one self-contained file for publishing. It is titled
from `tools/title.nim`, so that a gallery sorts the body of work together.

## Design workbench

**Rules are data, and the Reference is held to them.** The rules as given live in
`design/rules.nim`, in the words they arrived in, and `design/README.md` quotes each one.
`checks.nim` asserts what the rules ask of the drawing, of the single-hand turns and of the
hand-to-hand chain.
`checkRulings` asserts what the Reference claims. Both run between the build of its parts and
the write, and the build refuses to write the page where a claim fails.

Rejected: rules that are implemented and not asserted, which quietly stop being true. The section on
the rules of the drawing gives the check of each.

**The parts of the walked turns are built once, and each check reads what the Reference placed.**
The Reference places the single-hand turns and the hand-to-hand chain, and `checkSingleTurns` and
`checkHandTurns` read them. Routing is most of what the build costs, so `marks.nim` keeps the parts
of each that it has built. Each check reads the parts of its own turns, and not the merged parts of
the page. `checkHandTurns` walks every figure that it is given, so the merged parts would widen its
law. What the kept parts save on the Reference alone is unmeasured.

The Reference and the rig viewer are build products under `build/design/`.
`suites/test_marks.nim` drives the build of each page of `marks.PAGES` under testament, so every
check runs with the suites.

**Every page says its prose in Simplified Technical English.** The Architect requires the prose in
the subset of the charter (`GUIDE.md`, Article VI.8). Two rules of that subset can be counted, and
`design/plain.nim` counts them off the markup. A sentence of prose holds at most `WORDS` words, and
a paragraph at most `SENTENCES` sentences. Prose is the text of a `p` or an `li` alone, because a
caption or a swatch label is a fragment rather than a sentence.

The rest of the subset, from the approved word to the active voice, is read rather than counted.

Verified by `suites/test_marks.nim` over each page of `marks.PAGES`. Both laws were proved able to
fail on the Reference, 2026-10-18. One sentence lengthened past the bound reddens the page it
sits on. A seventh sentence added to a full paragraph reddens it too.

**The reader of prose steps over a tag that only opens as `p` or `li` does.** A page names each
drawn element with such a tag, as `path` and `line`. A reader that takes one for a paragraph looks
for its closing tag. It finds the closing tag of the next paragraph, and so skips that paragraph.
Verified by `suites/test_plain.nim`, which reads prose off markup with a known count.

**The sentences that the Explorer and the rig viewer write in the browser are counted.** No page on
disk carries those sentences as prose, so `test_marks` reaches none of them. `test_said.nim` reaches
both, on the JS target, because both pages import `std/dom`.

It reaches them two ways, because they are built two ways. The Explorer builds its markup in pure
functions that return it, so the law calls them and reads what they return (Article IX.5). The
viewer writes its sentences straight into elements, so they are held in one table,
`rig_view.VERDICTS`, which the law reads instead.

Proved able to fail on both paths, by lengthening one sentence of the Explorer and one verdict of
the viewer past the bound.

Nothing the law calls touches the document, so a count for both needs no browser.

Some prose is counted by nothing still. `rig_page.nim` writes the fixed prose of the rig viewer into
its markup, and no law counts it. By the count of `plain.nim`, one paragraph there holds seven
sentences, and one sentence holds 26 words, measured on 2026-10-08. The Explorer writes what its
live region says straight into the element, so no law reaches it either. The fourth verdict of the
viewer opens `Stops at N turns:` and closes with a reason the simulation recorded, so it never
stands as one whole string. Those reasons come from `hold.says`, and the longest of them holds eight
words.

**The two counted rules are a floor, and only a reading catches a word used outside its meaning.** A
page can stay inside both bounds and still say that a stage `collides` a capsule.

**The READMEs of the project are counted as its pages are.** Article VI.8 binds every Markdown
file, and the `english` check of the repository reads only the three records at the root of a
project. So that check reads neither `simulation/README.md` nor `design/README.md` (issue #239).
`design/plain.nim` reads Markdown as that check does, and `test_readme.nim` holds both READMEs with
the two numbers the pages keep. `WRITTEN` names the files held, and a README joins it when it is
written again.

**The rules that `design/README.md` quotes are held to the ledger, and not to the two numbers.**
They are the words of the Architect, so a quotation is never rewritten. A `>` quotation carries no
prose, so neither check counts it. `test_readme.nim` holds each one to its entry in `RULES` instead,
word for word, once each and in order. Verified by `suites/test_readme.nim`, which fails on a
changed word, a missing rule and a missing quotation.

**The reader of Markdown is copied from the check, and not imported.** A suite compiled against the
check of the curator would break whenever the curator changed that check. Duty 3 forbids the
curator to do that to a project. The cost is two copies that must agree. Verified against the check
on nine documents of the repository: the two agree on all 1158 blocks and all 2746 sentences. Six
laws in `test_plain.nim` hold the copy, and each was broken on purpose and caught its own break.

**`simulation/README.md` points at this record and at `rig.nim`, and does not say the model again.**
A second account of the model goes stale when the design moves. Verified by reading each claim that
`simulation/README.md` keeps against the code or this record.

**No string a page shows says a gendered word for a dancer.** The glossary rejects one for each
dancer, and `test_glossary.nim` reads that ruling rather than restates it. It holds every string
literal of `design`, `app` and `simulation`, and the page this project writes by hand, the shell of
the Explorer. A literal that a colon follows is a key of recorded data, so the check steps over
it. Verified by `suites/test_glossary.nim`, which fails on a page string such as `her arm` or
`his reach`.

**No string a page shows calls a page by a word that the glossary rejects for it.** The glossary
rejects validator, app, demo and viewer for the Explorer, and card review and review page for the
Reference. `test_glossary.nim` reads those words from the glossary, and holds every string literal
of `design`, `app` and `simulation` to them. A literal of one word names an element or a key, as
`app` does, so the check steps over it. The project calls the third page the rig viewer, and that
name holds `viewer`. So the check takes the name out of a string before it reads it.

Verified by `suites/test_glossary.nim`. Red first on 2026-10-21, on the sources before the fix: it
failed at five strings. One was `the app's frame` on card C04, and one was `the viewer` in the prose
of the Reference. Three were messages of the rig viewer that said `Viewer page`.

Cost: the shell of the Explorer is not read. Its markup names the element `app` and the script
`app.js`, and its one line of text is its title. Cost: a word that names a page in a comment or in
the record is held by reading alone.

**To dress a page twice gives the same bytes as to dress it once.** `dress()` walks every page under
`build/app` and `build/design`, and not only the pages of the run. So a page that the run did not
write is dressed again. `fontFaceStyle` marks its block `<style data-font-faces>`, and
`withFontFaces` removes an earlier block before it adds the new one. Rejected: to skip a dressed
page, which keeps old font faces after a font face changes.

Verified by `suites/test_font_faces.nim`, test "dressing is not doubled where it runs twice", which
dresses both shapes of page twice and demands the same bytes. Verified by hand on 2026-10-02: two
`pages` runs over one tree gave pages that compare equal by `cmp`, byte for byte. No verb writes a
page under `build/simulation/`.

**The four are a manner of turn, and not a way of turning.** `Manner` and `MANNERS` name the four
through the workbench. The pages, the checks and the ledger say "manner". "Way" names clockwise
against anticlockwise, as `wayTurn` and `wayName` return it. Rejected: one word for both senses.
Rejected: a rename of `Way` as well, which leaves the direction of the turn unnamed.

The lock or wrap of the drawing is `terms.Modifier`, so `Way` names the direction alone
(`rotation.Way`).

Cost: no test reads the `_Avoid_` line of the manner of turn. `test_glossary.nim` reads the
`_Avoid_` lines of the steps of the chain, of the lead and the follow, and of the facing. It also
reads those of the Explorer and the Reference, and no others. So "way" can drift back into the sense
of "manner" without a test noticing.

**The moving sections show a walk whole before they show it in pieces.** Each manner of each hold
takes two cells in sections E, F and G of the Reference. Those are the whole walk, and the same
walk step by step, with a button for each step. Rejected: a cell for each edge, which gives 112
cells of animation to scroll past. Section E holds 64 animated edges, and sections F and G hold 24
each.

`turnWalk` takes `steps` and `has_return`, so one builder makes three things. They are a single
rocking edge, a whole round of four quarters, and a whole chain of six halves out and back. The
round closes on itself and needs no return. The chain does need one, because it has ends.

The switching is a radio button and a sibling rule, so the page stays markup that a browser draws
with nothing running. Rejected: script, which these pages have never needed.

The fixture covers every drawing in a cell, because a ruling on a cell is a ruling on all of it.

Cost: fewer cells, and a larger page. A walk shown whole is drawn as well as its pieces, and not
instead of them. Of the 10.2 MB of the Reference, the walks shown whole take 4.3 MB. Measured on
2026-10-08, on the page that `suites/test_marks.nim` writes without font faces.

Every animation runs at one pace (`WALK_SECONDS`), so the length of a loop says how far it goes
rather than how fast. The whole chain is six times an edge, which is a long loop.

Verified by `suites/test_marks.nim`, which drives the build and so the gates. The 16 rounds are
counted, and each one is asserted to close where it set off. The whole-walk figures are held to the
same hatch laws as the edges.

**A ruling is given on a picture, so the picture is held as a fixture.** `reference_page.nim` lays
out every frame state that the project draws as a card. Those are the standard diagrams and the one
anticlockwise counterpart. They are also the distinct single-hand turn frame states, both
hand-to-hand chains, and every animated edge of the last two. Each card carries the identifier to
quote back, and whatever has been ruled on it.

**Each identifier is the letter of its section and two digits, from A01 to G08.** So no identifier
reads as a decision of a sign-off, which `GUIDE.md` numbers from `D1`. The Architect ruled this on
2026-10-04. The questions of sections A, C and D take the same names, because each question is keyed
by its card. Verified by `suites/test_marks.nim`, which reads each identifier off the written page.
It failed on 57 of 107 cards, which had one digit.

Rejected: the decisions numbered D01, with the cards left as they were. The Architect chose the
cards.

A rename of the cards changes no answer of the simulation. After it, each recording was the one
before to the last bit, apart from its names and its stamp, compared on 2026-10-04. The store of
answers keys each answer by what it asks, and not by the name of its card (`walk.Store`).

The identifiers that the Architect has kept or dropped are named in the module. What each one was
drawn as when it was ruled on is its fixture, held as a hash in `design/review-fixtures.json`. The
build refuses to write the page when the drawing of a ruled card has moved.

Rejected: a ruling taken as given on the identifier, because a mend that reaches too far then
carries an approval that nobody gave. The guard was proved by a widened clearance on a break. It
then named the twelve kept cards that carry a crossing.

Fixtures are rewritten only by `tools/build.nim fixtures`, which is a deliberate second step. A
ruling and its fixture are added together or not at all. To run it to quiet a complaint would hand
the approval to the new picture. Cost: the rulings live in the module, so every ruling is a commit.

Verified by `suites/test_marks.nim`, which builds the page under testament. Verified by the tally
being counted off the built page, rather than kept while it is built. What the page says of itself
cannot then drift from what it holds. The page prints that tally where a reader sees it, which is
why no number of it is written here.

## Rules of the drawing

**The checks of the workbench hold a drawing to a rule as written.**
`design/rules.nim` holds every rule the drawing was given, in the words it arrived in, and
`design/README.md` quotes each one. `design/checks.nim` checks each standing rule on every build and
prints one line for it. A check verifies that a drawing follows a rule as it is written. It never
verifies that a couple can dance what the drawing shows. The Architect trusts only a cell of the
Reference that is kept, modelled and confirmed, and `CONFIRMED` in `design/reference_page.nim`
names each one.

**A rule that is implemented and not checked stops being true, so each rule drawn has a check.** A
check names its rules in a comment in `checks.nim` that opens `RULE`. Nothing in the workbench
checks rules 36 to 40, and the simulation reports in their words. `tests/suites/test_readme.nim`
holds every quotation in the README to `RULES` word for word, so the two copies cannot drift. The
checks do not quote `RULES`, because their printed lines say what was measured.

**A moving picture is checked where it is drawn, and not only at its frames (rule 1).** A browser
blends two frames point by point. So two frames that disagree about which side of a body a line
passes are drawn, between them, as a line through that body. `oneWayRound` in `route.nim` chooses
the way round once for a whole move, and every frame of the move uses it. Verified by `checkRules`,
which samples each blend part way between two frames.

**A hand leaves its side only when its hold names a level and a modifier (rules 2 to 5).** A level
alone does not say which side a hand goes to, so the hold must say lock or wrap as well. A hand
settles in one of six places, each a bearing off its own dancer's facing (rule 3). `SLOT_OFFSET` in
`body.nim` sets them 44 degrees apart, and two marks need 34.9 degrees, so no two marks touch.

Both wraps go round the front to the front of the other hand, and a low lock goes round the back
(rules 4 and 5). A high lock folds the arm in front, so its hand settles in the front slot of its
own side (Architect, 2026-10-22). No rule sends its line round a body, so the line takes the short
way. Rule 6 sent it round the back, and the Architect retired it. Verified by `checkRules`, which
checks where each hold settles, and which way its route sets off where a rule sends it. Red first on
2026-10-22: the check failed against the old settle table, which put a high lock in the back slot.

**A lock or a wrap needs its line to go round the body (rule 7), except a high lock (rule 41).** On
the four single holds, at quarter turns of the follow, the larger arc takes seven values. They are
0, 51, 90, 132, 135, 141 and 180 degrees. So `WRAP_MIN`, at 170 degrees, admits 180 alone. A still
figure refuses to draw a lock or a wrap that rule 7 binds and that falls short. A moving figure asks
no such question, and no page moves a lock or a wrap.

Verified by `checkRules`, on each single hold at each quarter turn of the follow. It checks that
`isDanceable` agrees with the measured arc, for every lock and wrap but a high lock. It prints the
arcs that it meets.

**A high lock stands whatever arc its line hugs (rule 41).** A high lock folds the arm at the elbow,
with the elbow in front of the shoulder. The hand rests on top of the same shoulder (Architect,
2026-10-22). So no line round the body makes it. `terms.isMadeRoundBody` names the locks and wraps
that rule 7 binds, and `isDanceable` asks the arc of those alone. Rejected: a lower threshold for a
high lock, which would still refuse the arcs below it, where rule 41 refuses none.

Verified by `checkRules`, which draws a high lock on each of the four single holds at each quarter
turn of the follow. It prints how many hug less than rule 7 asks, and at which arcs. On 2026-10-22
it was all sixteen, at 0, 48, 51, 87 or 90 degrees, because the line takes the short way. The check
demands at least one such, so it cannot pass while it holds nothing that rule 7 does not. Red first
on 2026-10-22: before the fix, the drawing refused a high lock on Left to left with the follow
turned a quarter.

Cost: the drawing refuses no high lock for its arc. The simulation reads a high lock on the arm of
the follow at half and whole turns (`simulation/verdicts.md`), and no law holds those rows. Nothing
asks it about a high lock at a quarter turn, so nothing says which of the drawn ones a couple can
dance. No page draws a lock or a wrap yet.

Between quarter turns, a high lock finds a route at each whole degree that the follow turns, on each
single hold. Verified by `checkRules`, which routes all of them. Red first on 2026-10-22, against
the back way of rule 6, which found no route on Left to right from 275 to 298 degrees. Some low
locks that `isDanceable` admits find no route between quarter turns. The build then fails on an
empty value, and does not refuse with a message (#688).

**Above takes no lock and no wrap, and its line passes over the body (rule 8).** Above is over the
head, so from overhead nothing is under it, and `straightReach` draws its line straight. Verified by
`checkRules` for that half. `FROM_ABOVE` in `rules.nim` holds where above may go next, and nothing
checks it. Assumed: the "upper wrap" of rule 8 is the high wrap. That is a reading, and not the
words of the rule.

**A connection is drawn in the colours of its two hands, which meet at its middle (rule 9).** So the
line says which named hands are joined, where two marks at node size could not. The half of the
lead is in the deep shade, so the line says which end is the lead's when both hands share a hue.
Verified by `checkRules`.

**Every level is a height (rule 36).** Low is below the shoulder, high is above it, and above is
over the head. Which arm lies over which is part of what a wrap is (rule 38), and not part of the
level. Assumed, and read by the simulation rather than by the workbench.

**Rules 10 to 14 name a rotation page that the workbench does not draw.** Where a later rule
replaces one of them, the README says which. Rule 11 stands on the single-hand turns of the
Reference, whose frame states are frames of the Explorer in their four orientations. Rule 14 stands
as far as nothing wraps a body, and rule 17 moves its level to above. It draws no pigtail, because
rule 16 lifts the limit that the pigtail marks. Both are verified by `checkSingleTurns`.

**The single-hand turns draw each frame state they derive, and each move between two of them
(rules 15 and 16).** The counts are checked against the graph of states, and not against a number
typed in. A single hand held high turns without end either way (rule 16). So how far it has turned
is not part of its state, and only its orientation is. Verified by `checkSingleTurns`.

**Every turn is drawn above (rules 17 and 21).** Above is the one level rule 8 gives no lock and no
wrap, and the one whose line runs straight over everything. A moving hand carries the above hatch,
as a still one does. Verified by `checkSingleTurns` and `checkHandTurns`, which count the hatch on
every move.

**A turn by the lead is drawn in two stages (rule 18).** The room holds still while the lead turns.
Then the picture turns back so that the lead faces up. A turn by the follow leaves the lead facing
up already, so it needs one stage, and that is measured. Verified by `checkSingleTurns`.

**Four manners of turn: each dancer turns on their own axis, or goes round the other (rule 19).** An
orbit is marked by a dashed ring while it happens, and nothing else is dashed but the breaks of a
moving reach. An orbiter keeps their side to the centre (rule 32). So an orbit winds the pair as far
as it carries them, and every manner steps one frame state for each half turn. Rule 32 replaces rule
20, under which an orbit wound nothing and two manners did not walk the chain at all. Verified by
`checkSingleTurns` and `checkHandTurns`.

An orbit lands where the axis turn of the other dancer lands. So the four manners walk two rounds of
frame states, and not three. All four are drawn, because which dancer walked is a fact about the
move, and only a moving picture can show it.

**A settled reach passes clear of every mark it does not join (rule 22).** It is a line pulled taut
past both chevrons and every hand but its own two, bent round each and straight elsewhere. The gap
is taken from what is drawn, with half the width of the line added. A moving reach may pass a mark,
as the rule allows. Verified by `checkSingleTurns`, which checks both halves. The frame picture
does not follow rule 22 yet, because it does not pass `should_clear_marks`.

**A reach is judged on its length and its bends together (rule 23).** The shortest way past the
marks weaves, and a reader must follow each change of way. So a bend costs `BEND_COST` of length,
and the taut line held to each side of the chord is tried as well. Each of those bends once, by
construction. All three are weighed every time, and the one that costs least in length and bends
together is drawn. Verified by `checkSingleTurns`, which checks that no reach bends three times.

**A route that bends is drawn as one smooth curve (rule 24).** The hull of the marks shows where the
bulge goes and how far out it must reach. The line over it is one quadratic curve, widened until it
clears every mark. A curve of that kind turns one way only, so the route still bends once, with no
corner in it. Verified by `checkSingleTurns`, which checks the corner of the stored line.

**A reach is drawn as curves through its sampled points (rule 35).** A reach is held as
`ROUTE_COUNT` points, so that it can move from one shape to the next. Drawn with straight pieces, a
swan turns back inside a few points and shows its facets. So `route.smoothed` makes each sampled
point a control point and draws through the midpoints between them. The ends stay on their hands,
and the checks measure the stored points, and not the drawn curve. Verified by `checkHandTurns`.

**How wide the swan swings is set by eye, and not by a check (rules 33 to 35).** `SWAN_SWING` in
`route.nim` holds it. Rule 34 took back the width that rule 33 asked for, and rule 35 set it again.
The check on it is a backstop: the snake goes round something and stays inside its figure.

**The turn figures frame on the place of the lead (rule 25).** `canonicalise` turns the world about
an `Anchor`, and the turn figures use `Anchor.Lead`. So the lead holds one spot, and an orbit by the
follow needs no second stage. Only an orbit by the lead takes them off that spot, and there the
picture brings them back. Verified by `checkSingleTurns`.

**The turn back to the lead is quicker and quieter than the turn itself (rule 26).** A `Walk`
carries the time each frame is due, and the markup says so in `keyTimes`. So how long a stage lasts
is a choice of the drawing. The turn back is paced at `RE_FRAME_PACE` of the turn, and
`ARRIVAL_HOLD` holds a beat where the turn lands. Verified by `checkSingleTurns`, which reads the
clock in the markup and checks that the turn back takes less than half the turn.

**A hatched mark moves with its hand (rule 33).** An above fill is a pattern fixed to the drawing,
and not to the shape. So a moving hand is drawn once and carried by a transform, as a body is, and
the hatch travels with the mark. Verified by `checkSingleTurns` and `checkHandTurns`, which check
that a hatched mark moves nothing of its own.

**The holds of two hands walk a chain of seven frame states, a half turn apart (rules 28, 30 and
31).**
The seven are swan, diamond, cross, neutral, cross, diamond and swan. The chain has ends, and is not
a cycle (rule 30). Hand to hand and the crossed pair walk the same chain, and differ only in the
facing where the hold is unwound (rule 31). `parts.facingRest` names that facing, and
`parts.chainFor` lays the seven out from it. Verified by `checkHandTurns`, which measures the chain
of hand to hand alone.

**The twist is measured from the pose, and is not told (rule 28).** Each held hand sits on the rim
of its body, and both bodies stand on the axis of the pair. So the angle a hand makes with that axis
says how far round it has gone. The difference between the two ends is the twist. A reach is the
shadow of a wound arm from above: straight at neutral, a cross at a half, and a diamond at a whole.
Verified by `checkHandTurns`.

**The crossings alternate, so a connection over at one crossing is under at the next (rule 27).**
That is what being wound together means. Rule 28 measures the diamond that rule 27 drew. Verified by
`checkHandTurns`.

**A moving reach shows its breaks as the still does (rule 29).** A still reach is cut where it dives
under its partner. A moving reach keeps one path, and shows the break as a dash that travels with
its crossing. The crossings are found segment against segment, as the stills find them. Verified by
`checkHandTurns`, which checks that a moving figure and the still it lands on break the same arm.

**Each manner of turn finds its own sense, so no move walks off the end of the chain (rule 30).**
`parts.windSense` turns each manner a quarter from the frame, and reads the twist at the furthest
pose the walk reaches. Verified by `checkHandTurns`, which reads the twist on every frame of every
move.

**Past a whole turn, one connection runs straight and the other goes round it (rule 31).** That is
the swan. `route.windShare` gives the swing of the straight one to the snake. So at a turn and a
half, one reach is the plain chord between its hands. The straight one is on top at the first
crossing, so it dives once. Verified by `checkHandTurns`.

**The sheet of the Architect gives rules 36 to 40, and the workbench checks none of them.** The
simulation reports in their words, through `simulation/words.nim`, and that is not a check. Rule 37
says what a lock is, and bends the arm of a high lock to the shoulder of the same arm. Rule 38 says
a wrap crosses the other arm of its dancer. The drawing does not show that crossing yet, because
rule 22 keeps a settled reach away from that hand.

Rule 39 makes modifiers belong to each arm, for either dancer. The drawing holds one level and one
modifier for each connection. Rule 40 is the one filled rotation row of the sheet.
`simulation/verdicts.md` gives what the simulation finds for Left to left held low, turned from face
to face.

## The frame picture

**Each hand is drawn in the colour of its side and the shade of its dancer.** Left is blue and right
is orange, for both dancers. The lead's hands are in the deep shade, and the follow's in the plain
one. Each of the four is a named colour with a fallback. So a picture follows the page it is on, and
draws in its own ink when opened alone. Verified by `suites/test_diagram.nim`, which checks that
every ink is a named colour with a fallback.

**The shape of a mark says whose hand it is.** The lead's hands are squares, and the follow's are
circles. The mark carries this itself, so it holds at any size. Where a hand sits on the rim follows
from the way its dancer faces. So the sixteen facings are distinct without a new mark.

**A level is a fill on both ends of a connection.** Hollow is no level, solid is low, a dot at the
centre is high, and hatched is above. A crossed hold keeps its drawn break as well, because the
break still shows at node size. A hand that nobody holds fades to half strength and keeps its hue.
The free frame is four free hands, and to grey them would hide the one thing that shows orientation.

**A body is a plain circle, with a small chevron at its centre for its facing.** The centre is the
one part of a dancer that nothing else uses. `outlineRadius` in `body.nim` is the one function for
the edge, so the routing and the drawing agree on it. The rim says only that a body is there. It is
one quiet stroke, broken round each hand by `HAND_GAP`, and it carries no colour of a side. Verified
by `checkFrame`.

**The rim shows no progress.** The connection shows the wrap already, so a ring that filled in the
colour of an arm would say the same thing twice. One sign is enough.

**A reach is a taut string.** It starts on the edge of its own hand's mark, and it hugs the rim only
where a straight line would cross a body. Everywhere else it is straight. With nothing said, it
takes the short way, and there is no standing preference for the front of a dancer. Verified by
`checkFrame`, which checks that no reach enters a body and that each ends on its hand.

**Where a hand has left its place, the place it left is drawn as a grey outline.** So a picture
shows both where a hand is and where it came from (`figure.ghosts`). No check holds this, and none
holds that a mark stays clear of the outline it left.

**The lead always faces up.** A pose lives in world coordinates, and `canonicalise` turns the world
until the lead faces up. So every pose of the same shape is the same picture. The whole state is two
numbers: where the follow stands round from the lead, and how the follow faces. Verified by
`checkFrame`.

**A move is drawn in two stages: the travel, and then the turn back to the lead.** A cycle of go,
home, back and home closes exactly, so a moving picture loops without a jump. Bodies are rigid and
are carried by transforms, on a facing that does not wrap (`geometry.continuous`). A facing that
steps from 179 to minus 179 degrees would be drawn as most of a turn backwards. Verified by
`checkFrame`.

**A frame state cannot tell an orbit from an axis turn.** A quarter orbit lands on the picture that
the quarter axis turn of the other dancer lands on. So which of the two was danced belongs to the
move, and not to the frame state. Verified by `checkFrame`.

## Body rig

**Two bodies of the average adult and their arms, and they share no code with the ontology.** The
rig (`rig.nim`) is mixed-sex midpoints of ANSUR II medians, with AAOS and NASA-STD-3000 joint
ranges. Every number carries its derivation. The ranges are what a dancer will do without pain,
rather than what a joint can be forced to.

A torso is a stadium of its tape round, three quarters as deep as it is broad. A round section of
the girth of a chest stands three centimetres too far out at the front. The neck and head are round.
An arm is three links: upper arm, forearm and hand. They sit on a shoulder that swings and twists,
an elbow that hinges, and a wrist that bends within a cone.

Extension is held to 45 degrees behind the frontal plane, and adduction to the clinical horizontal
figure of 130. The 45 of a hanging arm is what the belly stops. Raised, the arm passes in front of
the chest until the chest stops it. Either way the limit is the trunk, which the engine collides,
and the cap is set where the reading can never bind.

Humeral rotation is 90 in and 105 out, with an ease of 25 degrees at either end. So rotation costs
nothing to 65 in and 80 out, which is about the AAOS figures. It is refused past 90 in, as the AMA
Guides give, and past 105 out, near the 104 of Boone and Azen. The tables disagree by about the
width of the ease, and the ease is where they disagree. Assumed: which table the shoulder of a
dancer follows.

The elbow goes to 140. The flexion and extension of the wrist are taken as one 60 degree cone. The
rotation of the forearm can turn the plane it bends in.

**The shoulder sets an edge on where its upper arm points, from two studies (#611).** The engine
holds every arm to it, the judge stops at it, and the plan keeps inside it (Rigid body engine,
Planned turn). `simulation/shoulder.nim` reads the direction from the moving shoulder joint
to the elbow, in the terms of the chest. There x points out to the side of the arm, y fore and z up.
It reads a left arm in mirror, so one edge serves both arms.

The direction goes onto the mean joint axes of Engin and Chen 1987 (AAMRL-TR-87-011, Table 3.1). A
direction is allowed where one of their ten men reached it by his own effort. That is the largest of
the ten edges of Table 3.3 on its meridian (Equation 3.2.1). On the lower front quarter, from 180 to
270 degrees of meridian, the arms of their men met the trunk (page 55).

There a direction is also allowed where one of the 16 adults of Haering 2015 reached it (Figure
15a). Nowhere else do the adults decide, as the Architect ruled in variant V2.

The print of Table 3.3 has two faults. Printed rows 1 and 2 belong to men 2 and 1. Each row fits
the edge of its own man in Table 3.2, carried onto the mean axes, and no other row does. The worst
own fit is 0.555 degrees, and the nearest other fit is 3.867. C10 of man 10 prints -0.11297, and
the printed mean and variance need -0.12297.

The theta of subject 3 in Table 3.1 prints broken, and the printed mean and deviation need 81.61.
Verified by `suites/test_shoulder.nim`, which holds each of these corrections to the print.

**The edge of the adults comes from the outline of the figure, at compile time.** Step 1 of #611
read the outline of Figure 15a, one degree of plane apart (`OUTLINE_ADULTS`). On each plane of
elevation it gives the largest elevation of the union. The module traces each meridian out from the
pole to where the run of the union ends. It closes each break narrower than 3 degrees, which is
inside the reading error of the figure. Knots stand one degree apart, and a knot goes between two
wherever their chord misses the trace by more than 0.01 degrees.

So the edge keeps the jumps of the run, for example 5.5 degrees near 186.1 degrees of meridian.

Rejected: a table of the run per half degree, joined straight. Between two rows it leaves the
union by up to 5.5 degrees, from 186.08 to 186.49 degrees of meridian. Cost: about 0.7 s of compile
time in each binary that imports the module. A small importer built in 2.46 s and 2.51 s, against
1.72 s and 1.87 s with the table, on four cores on 2026-10-11. Verified by
`suites/test_shoulder.nim`: a trace of its own, at every hundredth of a degree, lies within 0.05
degrees of the edge.

**The edge is hard, and its margin is polar.** Past the edge a direction is refused, and no ease
leads up to it. The margin is theta less the edge on the same meridian, positive outside
(`Outside.angle`). It is not the shortest arc to the edge. Of the recorded arms within 10 degrees of
the edge, 67 in 100 have an arc less than 0.6 degrees shorter. Beside the seam at 270 degrees, the
arc is up to 8.6 degrees shorter, measured 2026-10-11.

The edge steps at the two seams of the quarter, by how far the adults went past the men there. The
step is 42.1 degrees at 180 and 8.6 at 270. The arm straight up lies 5.16 degrees outside, by the
edge of the men. The arm that hangs plumb lies on the seam at 180, because `y_jt` is horizontal. It
is inside by the adults alone, and one degree behind plumb the men refuse it by about 10 degrees.
Verified by `suites/test_shoulder.nim`.

**An arm, held or free, may lie 2 degrees past the edge and still hold (`GIVE_EDGE`).** That is
the give of the judge on swing, a tenth of the 20 degree ease at either end. An arm that leans on
its wall sits that far past it, and slides along it. The Architect kept this give on the hard edge
(#611, D3).

A law of `suites/test_shoulder.nim` holds every arm-moment of `design/rig.json` to the edge within
this give, and reads no other recording (Rig viewer). It reads all four arms of every sweep and
every still: 2924 arm-moments of the sweeps of the rig, and 228 of its stills. A probe outside the
tree that prints what the law reads counted them on 2026-10-12. None lies past the give, and 203 lie
past the edge, counted 2026-10-20 by the law on this tree. How far the furthest lies past the edge
is unmeasured. The twist of the upper arm is no part of this edge (#622).

The sweeps of the rig record the moment that they stop at (`seen.shownAsked`). So a sweep that the
judge stops at the edge records an arm past the give, and this law fails on it. The design allows
that stop, and the law does not. No sweep of the rig stops so on 2026-10-12. The Architect rules
which one holds (Open questions).

Hands are offered three bands, one for each level: low 1.00 to 1.35 m, high 1.40 to 1.50, and above
1.735 to 2.00. The code names them `Torso`, `Neck` and `Crown`. The band for above starts one radius
of a limb over the head, so a hand carried there clears it by construction.

**The hand has its true size (#440).** It is 0.19 m from the crease of the wrist to the fingertip,
with a palm of 0.11 m. Both are ANSUR II midpoints: hand length 0.193 and 0.180 m, and palm length
0.116 and 0.108 m.

Its section is a stadium, a flat palm and back with round edges. The round of the hand, 0.20 m, and
its breadth, 0.083 m, give a thickness of 0.030 m (`handThick`). Three capsules side by side across
the breadth hold that section within 8.2 mm (`rigid.handCapsules`). Rejected: one capsule as thick
as the hand, which is a third as broad as a hand. Rejected: a ball as broad as the hand, which is
2.8 times as thick.

A palm grip joins two hands at the middle of the palm, 0.055 m past the wrist (`gripAtPalm`). A
finger grip joins them at the end of the hand, 0.175 m past the wrist, where hooked fingers hold
(`gripAtTips`). So the span of an arm with everything straight runs to the fingertips of a finger
grip, 0.735 m. The fingers past the join curl round the hand of the partner, about one thickness of
a hand deep. The capsules of a held hand end there (`handLong`).

Two palms pressed together tilt off facing by up to 30 degrees, and the fingers turn off opposed by
up to 60 degrees (`GRIP_CONE_PALM`, `GRIP_TWIST_PALM`). Held by the fingertips, two hands turn
freely. Between the two, the freedom grows in step with the depth of the grip (`gripFreedom`).

No study measures either figure, so both are derived. The tilt is the slip limit of dry palm skin
pressed flat. The arctan of its friction, 0.5 to 0.62, is 27 to 32 degrees (Derler and Gerhardt
2012; Zhang and Mak 1999). Each hand presses along its own palm onto the other, so the angle between
the palms is the angle of that press.

The turn of 60 degrees is a stop where the two hands meet, and not the end of comfort. The arms turn
the hands by their own joints, so the stop is that of the skin alone. A finger pad twisted on glass
slips whole at 16 to 59 degrees, as the mean of each person (du Bois de Dunilac, 2023). The comfort
of the forearm and the wrist ends near 30 degrees (Kee and Karwowski 2001; Khan 2009). Assumed: the
step between the palm and the fingertips.

**A free hand hangs relaxed, its fingers curled toward its palm (#440).** The Architect ruled so on
2026-10-04. Its fingertip lies 0.15 m from the crease of the wrist, 30 degrees off the line of the
hand toward the palm (`relaxed`, `curled`, `rigid.relaxedCapsules`). The planner lays it the same
way.

Lee and Jung measured the resting middle finger of 40 adults with the arm hanging (2010). Its
three joints rest at 32, 27 and 10 degrees. Garrett measured that a relaxed hanging hand
shortens to 0.77 of its straight length (1971). Curled further to that length, the chain of the
finger reaches 0.15 m. No study measures that distance, so it is derived, and the band of the
derivation is 0.14 to 0.16 m.

**A hand is carried at the centre of its grip, 0.08 m past the wrist, and each band is asked of
that point (`carry`, `pointCarried`).** The tape gives that centre (`rig.nim`). It lies between the
join of a palm grip and that of a finger grip, and neither join serves as that point.

Measured 2026-10-08. Asked of the fingertips, where the hands meet, the band lets the wrist and
elbow of the follow pass at head height. Left to right above then stops by swing at 0.40 to 0.42 of
a turn, from 0.36 to 0.46 m. From 0.48 m it turns free, with the arm of the follow behind the head,
at the end of its swing. Left to right at the torso leaps 244 mm in one moment.

Asked of the middle of the palm, the same-name chain wound half a turn holds from no distance. Asked
of the centre of the grip, both hold.

**Each head carries a face, and every arm keeps clear of every face (#375).** The face is a sphere
of 6 cm radius, half the length of a face from brow to chin (`rigid.faceCapsule`). Its centre sits 6
cm ahead of the axis of the head. It sits 4 cm under the centre of the head, midway from brow to
chin. So its front reaches 12 cm ahead of the axis, where the nose sits by the head length of ANSUR
II, 0.20 and 0.19 m.

The sphere is 12 cm across, about as wide as a face. The head is its own capsule, so an arm that is
clear of both is clear of the face. Assumed: the size and the place of the sphere, which are
estimates and not tape.

The sphere covers the face alone, as the Architect asked on 2026-10-04. Rejected: a sphere of the
radius of the head, 5 cm ahead of the centre of the head. Its front reached 2 cm past the nose, and
beside the head it stood 1.3 cm out of the head. Rejected: no face, under which a raised forearm
lies across its own face.

Verified by `suites/test_asks.nim`: no arm sits more than 5 mm inside a face at any recorded moment
of any still or sweep. That is the slop of the engine. A second law holds the sphere to the face:
its front reaches the nose, and it is no wider than a face.

Rejected: to import anything from `src/`, because a shorthand cannot check itself, and the
simulation is what a shorthand is for. Verified by `suites/test_limb.nim`: the tape and the forward
kinematics of one arm over seeded random arms, and the contact test against a sampled truth.

## Rigid body engine

**A rigid body engine is cloned, and not vendored, and Nim alone speaks to it.** `tools/build.nim`
declares `box3d` in `SOURCES`, with its repository, its commit
`47d7f7cc7e091142c08d11dc7d2e493c5d34f536`, its reason and its licence. The licence is MIT, read
from the `LICENSE` of the repository itself rather than assumed. `engine` clones there into
`dependencies/`, refuses a clone standing at any other commit, compiles its C files, and archives
them into `binaries/libbox3d.a`. The commit is what stands where a checksum stands for a fetched
file.

Nothing of it is committed, because the root ignore file ignores `dependencies/`, where Atlas
checkouts sit too. Rejected: its own CMake. That would be a third build driver in a project
whose registry admits no second. Nothing in its sources needs one, because none is generated.

Cost, stated: the build flags are this project's, `-O2 -std=c17`, rather than those of upstream. On
Linux, the release build of upstream sets `-O3 -DNDEBUG -std=gnu17 -ffp-contract=off` (its
`CMakeLists.txt` and `CMakePresets.json` at the pinned commit). Measured on four cores of a 2.8 GHz
Xeon, 2026-10-10: 32 s cold, and 0.2 s where the archive already stands.

`simulation/engine.nim` is the binding, Nim throughout, so the gated-language rule is never engaged.
It links the archive and declares what the rig needs. That is world, body, capsule with its surface
material, ball and hinge joints with their springs, contact manifolds, step and torque. The rig also
needs the readings of a joint, and the place, world point and velocities of a body. A capsule can be
read and laid again, and a joint can take new frames and a limit of its cone.

The binding also declares weld and distance joints, `engine.push` and `engine.turnOf`, which nothing
calls. To import it builds the archive first, at compile time, so a suite that drives the engine
drives its build too (Article IX.6).

Verified by `test_engine.nim`, which holds it to what the rig needs of it and no more. A body falls
half g t squared, which catches a struct laid out wrong where linking would not. Two limb-thick
capsules started inside one another part to at least two radii. Its law on the contacts of a body
touched by many things is below. The capsule laid again, and the frames and cone of a tie, are held
by `test_plan.nim` and `test_rigid.nim` (Planned grip, Body rig).

**The engine stands Y up and this project stands Z up**, and the binding deliberately does not
translate. Whatever calls it says which way is up, and `simulation/rigid.nim` is the one place that
does.

**What the engine holds, and what it judges.** The hinge of the elbow, the cone of the wrist and the
twist of the shoulder are the limits of the engine itself. The swing of the shoulder is not. The rig
gives extension and adduction as two ranges of their own. The edge of the shoulder bounds the
direction of the upper arm on each meridian round its pole (Body rig). On most meridians it lies
more than 90 degrees from the pole.

A spherical joint offers one symmetric cone about rest, of 90 degrees at most. It would also bound
elevation, and the rig gives no range for that at all. Every hold above would then block at once.

So swing is read back off the pose in the terms of the dancer, and resisted by a torque. The engine
resists the other joints the same way. Past either end of extension and adduction, the torque is
200 newton metres per radian (`SHOULDER_BACK`). That is stiff enough that an arm pressed against its
end stays within `GIVE` of it, rather than sinks through.

An arm rests against a limit and slides along it. It blocks only when forced past by more than
`GIVE`, which is the room that a limit which pushes back needs to push in.

Torque is a pseudovector. Each arm is worked out in the mirrored terms of the body, so one set of
ranges serves both sides. A mirrored frame is left-handed, and to un-mirror a torque as a plain
vector turns the correction into a shove. The mirror law of `test_rigid.nim` catches this, because
the shove then acts on the left arm alone.

The stance travels with the turn step by step. Swing read against a frame that the dancer has
already left judges every arm wrongly. Rejected: to fit a cone to the pair of swing ranges.

**The edge of the shoulder has a wall of its own, and the judge reads every arm against it (#611).**
Past the edge, a torque turns the upper arm toward the pole, along its own meridian (`holdSwing`).
It acts on all four arms, held or free, at every step, steered or not. No source gives an ease for
the edge, so the wall has none to lean through first.

At its give the wall holds what the end of the swing holds at its own give. That is the lean
through the ease and the wall together, 83.8 newton metres at 2 degrees past. So the wall is 2400
newton metres per radian, twelve times `SHOULDER_BACK`. Past the give the torque stays at 83.8,
because there the judge has stopped the walk.

Rejected: the wall at `SHOULDER_BACK`. The carry and the tie pushed the arm of the follow past the
give. Left to right above, from 0.36 m, the arm lay 6.3 degrees past at 0.42 of a turn. There the
wall of 2400 holds it 1.5 degrees past. Measured 2026-10-11 by a probe outside the tree.

A damper takes off the speed at which the arm already moves back toward the pole. It is critical on
the inertia of the upper arm about the shoulder, read off its capsule (`inertiaUpper`). That is
0.0555 kilogram square metres. The damper reads the angular velocity of the upper arm against the
chest (`engine.spinOf`).

Verified by `test_rigid.nim`: the engine weighs each upper link of a couple as `inertiaUpper` does,
to one part in ten thousand. Verified by `test_engine.nim`: a body given an angular velocity reads
it back.

Cost: the forearm and the hand hang on the upper arm, so the whole arm is damped under critical. The
ratio is 0.34 with the arm straight, and 0.43 with the elbow at a right angle. That comes from the
weight that the engine gives each link, on 2026-10-11. How the arm rings at that ratio is
unmeasured.

Rejected: a ratio of two, as the engine damps its own limits. A torque put on once a step is stable
only while `(w h)^2 + 2 z w h` stays under four. Here w is how fast the wall rings, h is the step,
and z is the ratio. On the upper arm alone, a ratio of two gives 4.2, computed and not run on the
recordings. Run on the turn of the six cards that are not modelled, it stops the positive way at
0.70 of a turn (Open questions).

Rejected: no damper. Left to right low, which the leap law walks at the torso, then moves a point
181 mm in one moment. With the damper it moves 137 mm, and the bound is 195 mm. Measured 2026-10-12
by a probe outside the tree, on the wall with its slope at 270.

The judge stops a connection where one of its arms lies past the edge by more than `GIVE_EDGE`.
It stops a swing past its range by more than `GIVE` the same way (`stoppedBy`, `Stop.Swing`). It
stops a walk and a still at a free arm past the edge too (`stoppedFree`). That stop names the hand
of the free arm, and no connection. The stop says that the upper arm swings no further
(`hold.says`), and the report says "shoulder, swing" (`words.why`).

Verified by `test_plan.nim`: at 64 seeded poses that the plan stands, held and free, the judge stops
at each arm past the give. It names the end that holds the arm, or the hand of a free arm. It stops
no arm that lies inside the edge and inside both ranges of the swing. Red first, with no reading of
the edge in the judge.

The wall does not hold every arm within the give. Left to left low, from the stances that the report
tells, stops three times at the edge (`simulation/verdicts.md`, Standing closer, and further). From
0.36 m, the held left arm of the follow lies 4.8 degrees past at -0.46 of a turn. The free right arm
of the follow lies 5.1 past at +0.40, and from 0.50 m it lies 2.3 past at +0.44. Each lies inside
both ranges of the swing. Measured 2026-10-11 by a probe outside the tree.

Rejected: the cone of the engine, aimed at the pole. It is circular and 90 degrees at most, and its
frame carries the zero of the twist, which #622 holds.

**Bodies are solid.** Contact is held at the cap of the engine itself, an eighth of the substep rate
(`CONTACT`, 240 hertz at `HERTZ` 240 and `SUBSTEPS` 8). At the default thirty, the forces of the
simulation itself pressed arms through bodies by 45 mm.

The upper arm collides with the chest it hangs from. The engine lets bodies that one joint connects
pass through each other, unless told otherwise. Without that setting, an upper arm sinks 67 mm into
its own head and nothing reports it.

Every joint but the tie holds at the cap of the engine (`HOLD`, 480 hertz). The tie that joins two
hands alone holds at thirty (`TIE`), which makes it the softest thing in the couple. A hold forced
past what arms can do then gives at the hands, in life as here. At fifteen it fixed one law and cost
every still card.

An arm deeper than a centimetre (`THROUGH`) in a body or in another arm is a stop. That is read off
the manifolds of the engine every moment.

The face meets the arms of both dancers and the girdles of the partner (`FACE_BIT`). Its own girdles
share its group, so they pass it. The trunks keep two heads apart. Chest to chest, the two faces
stand 9.5 mm apart, computed from the tape (`rigid.stadium`, `rigid.faceCapsule`), so no face can
meet another. The face sits on the chest and weighs nothing, because the head carries its weight. So
an arm deeper than `THROUGH` in a face is a stop, as in a body.

**Each dancer's own arms cross below the elbow, and their elbows keep their order.** A dancer
crosses their arms at the hands or the forearms, up to just before the elbow. Their elbows rarely if
ever cross over. The Architect said so on 2026-10-04, and ruled the same day that the rule binds the
two arms of one dancer alone. Partners are free of it: a crossed half turn lays the forearm of the
lead on the upper arm of the follow.

So the judge of a still stops two poses (`Stop.Crossed`). In the first, the right elbow of a dancer
passes more than 2 cm to the left of the left elbow (`ELBOWS_APART`). The judge reads left and right
across the chest of that dancer. In the second, one arm of a dancer lies on their other upper arm
(`ON_UPPER`). It lies there more than one radius of an arm before the elbow (`ELBOW_END`).

Measured 2026-10-04. Without the rule, D02 passes the elbows of the follow by 37 mm. It also lays
the upper arms of the follow on each other, 9 cm before the elbow. The crossed half turn stands the
elbows of the follow side by side, 9 to 17 mm past each other. In `design/rig.json`, A17 and C03 lay
the left forearm of the follow across the right elbow, and not on the upper arm before it. Measured
2026-10-11 by a probe outside the tree.

Rejected: elbows kept in order with no slip, since the crossed half turn passes them by up to 17 mm.
Rejected: 9 cm of each upper arm kept clear before the elbow, under which C03 and C05 stood the
other connection over. Rejected: the rule on the arms of both partners, which the Architect ruled
out.

The judge of a sweep does not read the rule, as the Architect ruled on 2026-10-04 (D5 on #375). A
sweep stays as the engine carries it, and can cross the elbows, until it is planned. The plan keeps
the rule on every path that it plans (Planned turn).

Verified by `suites/test_asks.nim`: in every moment of every still, the arms of each dancer cross
below the elbow alone. The law reads the recorded capsules, and not the judge.

The manifolds are read into the room that the engine says a body needs (`touchRoom`). Rejected: a
fixed room for eight, which drops unseen the deepest contact of a forearm that touches nine things.
Verified by `test_engine.nim`: a body touched by ten things reports every one, and eight when given
room for eight.

The capsules of the trunk and both girdles are recorded where the engine has them, so a law reads
the engine and never a copy. Verified by `test_rigid.nim`. No arm sits inside any body in any moment
of the corpus of the laws. Every capsule that the page draws is one that the engine was given.

## Wall at the seams

**The edge steps at its two seams, and the wall pushes along each seam.** The meridian runs along
the seam, so the wall never pushes an arm across it.

**At 270 degrees the wall climbs back from the step, one degree for each degree of meridian (#611,
D1).** The step there is an arm across the chest, at the height of the shoulder. On the side of the
adults the edge lies 8.6 degrees further from the pole than the edge of the men past the seam. So
the wall holds an edge of its own (`edgeWall`), which is the edge of the shoulder cut back near the
seam.

At the seam the edge of the wall is the edge of the men. Back from the seam it climbs one degree for
each degree of meridian (`SLOPE_SEAM`).

The judge reads the edge as ruled. An arm that the wall carries across the seam then meets the whole
wall over the give of its travel. That is how an arm meets the edge head on. A wall on the step acts
only after the crossing. So the arm lies past the give at once, and the moment after it stops the
walk.

Verified by `test_rigid.nim`. Left to left above is walked the positive way from each of 50
distances. No arm that crosses the seam at 270 from within the give lands past it, in 109 crossings.
A second law holds that the edge of the wall lies nowhere outside the edge of the shoulder, and does
not step at 270.

Red first, with no wall: 35 of 120 crossings landed 3.7 to 17.0 degrees past. With the wall on the
step, 4 of 96 crossings landed 2.7 to 7.9 degrees past, and each stopped its walk. From 0.46 m that
walk stopped at 0.38 of a turn.

Measured 2026-10-11 and 2026-10-12 by a probe outside the tree, over 200 walks of the two single
holds above, both ways, from every distance. With the wall on the step, 7 walks stop at an arm just
past the seam. With the slope, none does. The walks that stop at the edge fall from 31 to 24, and
those that run free rise from 110 to 117.

Cost: the wall leans on an arm inside the edge of the shoulder, on a wedge beside the seam. The
wedge is 9.5 degrees of meridian wide, and 8.6 degrees deep at the seam. In `design/rig.json`, 40
arm-moments lie within 3 degrees of meridian of that seam, between its two edges. Measured
2026-10-12 on the recordings of this tree, by a probe outside the tree.

The slope moves the holds over the crown, and L-l and R-r held high, and no hold at the torso. It
moves 8 of the 18 sweeps of six frame holds at three levels. In `design/rig.json` it moves 3 of the
8 sweeps and 14 of the 95 stills. A17 and C03 move 4.0 mm at most. The stills of single holds in
section B move up to 44.6 mm (`st_lo_0_3`). Measured 2026-10-12 against the wall on the step, on a
recording of the slope alone, by a probe outside the tree.

The slope costs the walk of the chains held above some of their reach. Measured on the same two
recordings, both ways, and walked without the rule that keeps the hands over the crown (Walk and
lift):

- the same-name chain turns to -1.66 from 0.64 m, where an arm meets an arm. On the step it turned
  to -1.88 from 0.72 m, where the wrist of the follow stopped it;
- the cross-name chain turns to 1.60 either way from 0.86 m, where the wrist of the follow stops it.
  On the step it turned to 1.68 from 0.56 m, where an arm met an arm;
- the positive way of the same-name chain turns further, to +1.88 from 0.74 m, where it turned to
  +1.82 from 0.60 m.

The hands over the crown then take more of that reach (Walk and lift).

**At 180 degrees the wall keeps the step of the edge.** The step runs from plumb into the trunk. A
free arm hangs about 13 degrees out of plumb, against its flank. There it lies 5.0 degrees inside
the edge of the men, and the wall never acts on it. Measured in the settle by a probe outside the
tree, 2026-10-11.

No arm-moment of `design/rig.json` lies within 3 degrees of meridian of that seam, between its two
edges. Walks of three holds at the torso and of the two above make 500 walks from every distance.
No walk of them stops at an arm just past that seam. Measured 2026-10-12 by a probe outside the
tree.

Rejected: the same slope at 180. It leans on arms in front of plumb, over up to 42 degrees of
meridian, and moves the holds at the torso. Left to right low then moves a point 180 mm in one
moment, where it moves 137 mm. Measured 2026-10-11 by a probe outside the tree.

Rejected, each measured 2026-10-11 by a probe outside the tree:

- the wall with no cap past the give. It grows as the end of the swing does, and holds more arms
  within the give. But it moves the holds at the torso. Left to right low then moves a point 191 mm
  in one moment, 4 mm under the bound;
- the reaction of the wall on the girdle. Each torque of a joint acts on both links that it joins,
  but there the girdle swings on the soft springs of its collarbone. The turn of the lead under the
  same-name chain above stops at 0.66 of a turn at most, mostly at the wrist;
- a push toward the nearest point of the edge. Fewer walks stop by swing, and more stop by twist,
  by a wrist or with an arm through a body.

**No wall carries the turn of the lead under the same-name chain held above to +1.0, except by
chance (#611, D1).** Each wall below walked that turn to +1.0 from 200 distances, 5 mm apart:

- the wall of this tree, and the wall on the step at 270 that it replaces;
- the wall on the step with no damper, and with a damper on an arm that moves out alone;
- the wall with no cap past the give, 1.5 times as stiff, and 2 and 4 times as stiff past the give;
- the wall with its reaction on the girdle;
- the wall with a slope at both seams, and with a slope and no cap;
- the wall that pushes toward the nearest point of the edge, with a slope.

The walls carry +1.0 from 0 to 4 of the 200 distances. Each of those 26 walks moves a point 395 to
774 mm in one moment. Every other walk stops between 0.08 and 0.90 of a turn. Most stop at 0.48 to
0.50 or at 0.58 to 0.72, by swing, twist, a wrist or arm against arm. The wall with its reaction on
the girdle carries no walk past 0.66.

The wall of this tree carries +1.0 from 1 of the 200, 0.548 m, and from none of the 50 distances
that the search walks. Measured 2026-10-11 and 2026-10-12 by probes outside the tree, on the walk
before it kept the hands over the crown, and unmeasured since. So the edge refuses those cards
(Planned turn).

## Joints that give

**Comfort is a slope inside a range, and not a wall at its end.** The limits of the engine are
walls, and its springs, at one hertz (`EASE`), are nothing. With walls alone, every joint runs to an
end and stays there.

The range of each joint carries an ease before an end, and inside it a torque grows with the lean.
An end with no ease, such as the straight elbow, is a stop that costs nothing to lean on (`Range`).
The edge of the shoulder has no ease either, because no source gives one. Its wall is stiffer to
make up for that (Rigid body engine).

- Swing takes the same 200 newton metres per radian as its wall (`SWING_LEAN`), because at ten the
  arm of the follow still reached the wall.
- Twist takes 25 (`TWIST_LEAN`), which is about the passive stiffness of a shoulder near the end of
  its rotation. At seven, three newton metres at the end of the ease was under what forty newtons of
  lift at full stretch puts on a shoulder. Joints then sat at their ends in most stills.
- The elbow takes 15 (`ELBOW_LEAN`).
- The wrist takes 6 (`WRIST_LEAN`), which rings at six hertz on a hand of true size.

The last three are assumed.

The arms weigh nothing. Weight does one thing to the elbow of a held arm: it turns the elbow toward
hanging below the line from shoulder to wrist. That is put back as one newton metre (`ELBOW_DOWN`).
Nothing else that weight does is put back, so it neither loads the rise nor pulls a hand down.

A free arm gets none of it, and rests with its elbow near straight (`HANG_BEND`, assumed). Rejected:
`ELBOW_DOWN` on a free arm. It twists a hanging arm forty degrees and swings it twenty forward. The
engine spring gives twist next to nothing, because an arm is thin about its own length. The forearm
then points at the partner, so the arms of a free couple cross.

Verified by `test_rigid.nim`. A free couple at rest hang every arm near plumb, elbow near straight,
and untwisted. No arm is within its own thickness of the other's. Red first.

The shoulder spring of a free arm is five hertz (`HANG_HERTZ`, assumed). It stands in for the weight
that holds a hanging arm plumb. That is about seventeen newton metres per radian, for five kilograms
of arm at a third of a metre.

Rejected: a softer spring. The friction of the flank then drags the arms of the follow behind a slow
half turn. **Measured** at one, two, three and five hertz, the arms lag 49, 24, 13 and 5 degrees.
After the settle they lag 33, 8, 5 and 4. At one hertz, A02 stands with the hand of the follow 413
mm off plumb.

Verified by `test_rigid.nim`. A free couple wound half a turn either way hang every arm within ten
degrees of plumb, and the hand within 0.2 m of it. Red first.

The spring of the wrist itself is five hertz (`WRIST_EASE`). The engine sizes it from the hand and
the forearm that it joins. On the hand of true size, 0.376 kg, it is 0.89 newton metres per radian,
which is about the passive stiffness of a wrist. At one hertz the wrists sat at their cone at
rest, once the elbow was turned down.

Friction where arm meets body is 0.2 (`FRICTION`), cloth on cloth. At the 0.6 of the engine, an arm
lying over a head was dragged round with it as the follow turned under. That wound the shoulder of
the follow to its end.

Rejected, each one measured and each one worse: gravity on the arms, higher damping, and a ramp on
the elbow. Rejected too: a raised floor for the band of above, and a pull of the hands to a disc
rather than to a point. Verified by `test_rigid.nim`: no arm held above is carried to the end of its
swing. Red first.

**The trunk twists at the waist and does not bend.** The hips are a kinematic body, turned and never
pushed, and they carry nothing. Every trunk capsule and both shoulders ride on a dynamic chest. That
chest is hinged to the hips about the up of the trunk, and sprung to neutral. It is stopped at forty
degrees each way (`Rig.waist`), which is clinical thoracic rotation.

The ease is fifteen, and it is assumed, because the tables give the end and not where it starts to
cost. Inside the ease the chest is turned back toward square at 60 newton metres per radian
(`WAIST_LEAN`). That is about what the passive stiffness of a trunk gives near that end, and it is
assumed. Verified by `test_rigid.nim`: shoulders yaw on hips no further than the thorax turns, and
rest square.

**Each shoulder is a girdle on a collarbone, and both give.** The shoulder joint sits at 0.18 m out
and 1.40 up, which is nine centimetres outside every capsule of its own torso. With nothing there to
give, the arms read as dislocated on the viewer.

Each shoulder is its own body. It is a capsule of radius 0.06 from the side of the neck out to the
joint, which is deltoid and trapezius. `GIRDLE_RADIUS` is an estimate, and not tape.

It hangs on a collarbone, which is a body of its own at the side of the neck (`COLLAR_RADIUS`). Its
capsule has the radius and the length of the girdle's, so the two weigh 2.35 kg each. With a
collarbone of radius 0.01 m, a fiftieth of that mass, both girdles stay on their hinges standing
still. But each shoulder of a free couple at rest then rises 15 degrees, against 7 at the full mass.
Measured 2026-10-09 at `e1dfe667`.

The collarbone is hinged to the chest about the up of the trunk, for protraction and retraction. It
is hinged to the girdle about the fore of the trunk, for elevation and depression (`Collar`). The
two hinges in series are the universal joint that the engine has no one joint for.

Each swing has its clinical range: 25 degrees fore and aft, and 40 up and 10 down, from Kapandji
(`Rig.collar`). The eases are 10 and 5 to 10, and they are assumed. It is sprung to where tape puts
the shoulder at 4.5 hertz (`COLLAR_HERTZ`), which is assumed. The engine sizes that spring from the
inertias of the two bodies that each hinge joins. So it is about 7 newton metres per radian fore and
aft, and 4 up and down, computed from their capsules.

The collarbone is turned back inside its ease at 40 newton metres per radian (`COLLAR_LEAN`), which
is also assumed. A walk can roll a shoulder to an end of its range, as every sweep of
`design/rig.json` does. Measured 2026-10-09.

Rejected: a girdle welded on a linear spring. With a rope at five centimetres, the shoulder sits at
the end of the rope in every pulled still. Without a rope, a pushed arm carries its girdle 251 mm
into its torso.

Hinges also turn the glenoid with the roll of the shoulder, which an arm raised overhead twists by.

The trunk and its own girdles share one collision group (`ownGroup`). A girdle lies through neck and
torso by construction, and, hung on a collarbone, it is two joints from the chest. The engine skips
bodies that one joint joins, and nothing else.

A girdle squeezed between two torsos is a shoulder through a body, and stops the turn as an arm
would. Verified by `test_rigid.nim`: every shoulder joint lies inside some capsule of its own body.
Red first at 90 mm outside.

## Walk and lift

**Turning is a walk, a fiftieth of a turn at a time.** The hips of one dancer are spun for
200 engine steps in each moment (`walk.BEATS`, `STEP`), which is slow enough to stay quasi-static.
The arms are carried on by the engine. A pose at each moment is the pose before it, carried on, so
an arm that has gone round a body stays round it.

Joined hands rise from where each one settled at rest, to the lower edge of their band. They rise
along a ramp over the first quarter turn of twist (`RAISE`). They are held to the ramp from both
sides, because asked for the band outright a weightless hand crossed 359 mm in one moment. Risen,
the two edges of the band are held (`LIFT` 400 newtons per metre, `FALL` 40 damping it), and
everything between them is free. The band is a bound, and not a preference.

Asked above, the hands are held to the `Torso` band while the couple face each other. They are
held to the `Crown` band from a quarter turn away, and blended between (`up`, `bandNow`,
`height`).

The Architect ruled on A09. That is the same-name chain wound half a turn from its Face-to-back rest
to face to face, with the hands still over the heads. The Architect rules it modelled but
unnatural. Facing, relaxed
hands are at mid torso. Face-to-back or Back-to-back are where they have to be above.
Facing, the arms naturally come down, and the swan may be reached only so, with one connection
straightening out as the arms come down.

`up` is how far the couple are from face to face, with whole turns folded away. So a couple wound a
whole turn have their hands down again.

Going up, the hands rise over the head of the dancer who turns. Coming back, they come forward off
that crown first, to between the two bodies, and then down (`isLeavingCrown`, `over`). Let down
straight from over the crown they pass through the head. The rise from rest keeps a key of its own,
which is the twist (`wound`, `risen`). Rejected: that rise keyed to facing too. It let the hands
down onto the head through the second half of every whole turn.

Facing, a hand over the crown is a hold at some other height, as a hand under its band is
(`FACING`). It has five centimetres of slack over the top of the `Torso` band (`OVER`, assumed).
Wound arms press the hands up against the forty newtons of the lift. The same-name chain come
round to face to face sat at 1.37 to 1.39 m, against 1.35.

Asked at a lower level, the hands rise from where they settled, over the first quarter turn of
twist. That rise is whole from the rest for a hold that rests Face-to-back.

Verified by `test_rigid.nim`. `up` is nought face to face, and one from a quarter turn away, at
every twist up to a turn and a half. The cross-name chain at rest and the same-name chain wound to
face to face hold with every joined hand in the `Torso` band. A09 stands at 0.66 m, with every hand
at 1.35 m, measured 2026-10-11. Red first.

Under this rule no diamond stands. With the hands asked to mid torso after a whole turn they hold at
no distance. The turn gives at a wrist, a twist or a hand under the `Crown` band before it comes
round. Where it comes round, the pose left to stand gives too. Rejected: six centimetres of sag
under the `Crown` band, and not three. Measured, it stands neither diamond.

The same-name chain come round to face to face stands one way about at ease. The other way about,
the carried walk holds it at no distance, so the corpus asks it either way about. A planned turn
stands it the other way at a strain of 0.01 (A11 and D03 in `design/rig.json`). Its cards fix their
way about, because each names the connection over (A09 and A11).

One law says that the connections of a diamond cross twice, where the connections of an open hold
run clear. It winds the couple there whether or not the pose holds, because what it claims is the
winding. What the Architect describes, one connection straightening out as the arms come down, is
nothing the hold can do yet, and is the next question.

The lift and the draw are put on as muscle (`muscle`). That is torque at the shoulder, and at the
elbow that carries the wrist. The equal and opposite torque goes on the link inside, and the torque
of the shoulder goes on the girdle. They are never put on as force on a hand. Rejected: force on
links alone, which pulls the chain up through the shoulder. Rejected: torque at the wrist too, which
bends every wrist to its cone early in a rise, because the hand is the lightest link.

What one arm carries its wrist with is capped at forty newtons (`MUSCLE`). That is the weight of the
arm itself, which a dancer lifts an arm against and plainly can, and it is assumed. Uncapped, a hand
twenty centimetres under its rise pulled with eighty.

Hands are drawn toward a point as they rise, weakly (`DRAW`, 40 newtons per metre held low
or high, and 10 held above). Held low or high, that point is between the two bodies. Held above, it
is the axis of whoever turns. A couple setting a hold up put them there, and to pull both to the
midpoint spends the adduction that the turn wants.

What stops a turn is one thing, asked in order over every arm, held or free:

- swing past its range by more than `GIVE`;
- an upper arm, held or free, past the edge of the shoulder by more than `GIVE_EDGE`;
- an arm through a body or through an arm (`Stop.Through`, `Stop.Arms`). A free arm crushed between
  two torsos is as much a stop as a held one;
- then, once the hands have parted by `PARTED`: which of twist, elbow or wrist sits at its end, what
  the arm was against, or span;
- once risen, any joined hand further under the edge of its band than the slack of the lift itself
  (`SAG`, `Stop.Band`). A hold whose hands never rose is a hold at some other height. A still
  reads this from the end of the rise (`height`). A walk reads it over the crown alone, once the
  couple are not face to face (below).

Verified by `test_rigid.nim`. Hands that are joined stay joined. No joint goes past what the rig
allows while the hold stands. Capsules move where the couple move.

Between two moments, no joint of any held arm, nor its join, leaps more than the length of an arm
plus its own move. That is 195 mm on the corpus of the laws. The breadth of the hand is not read
(#605). In L-r low its edge moves 150 mm in one moment, at 0.38 of a turn, where the join moves 137.
Measured 2026-10-11 by a probe outside the tree.

**Over the crown, a walk keeps the joined hands above the heads once the couple are not face to
face (#611, D2).** The Architect ruled that this holds in every moment of a sweep, as in every
still. A joined hand that sinks under the `Crown` band by more than `SAG` stops the walk. That
holds from a quarter turn away from face to face (`up` whole), at every wind.

One rule serves the still and the walk (`handUnder`). It reads the point where each hand is
carried, as the laws of the stills do, and not the join.

**Face to face ends a quarter of a turn away, as the judge of the walk reads it (pull request
629, D2).** The Architect ruled on 2026-10-12. From a quarter turn away from face to face, the
joined hands must be above, as the judge of the walk reads it. The law of the hands keeps that
reading, and its doc says so. On the way back, the still holds the band from an eighth of a turn
away (`height`), and the walk and the law do not.

The stop has a name of its own, `Stop.Band`, which says that the joined hands leave their band.
The still gives it too. Rejected: the name of a span, which says that the hands pull apart because
the arms are not long enough. A hand that sank has not pulled away from its partner. Rejected:
`Height`, a word that the glossary keeps off a level.

The search for where to stand passes over each distance where a hand sinks. The single holds above
then turn free to 2.5 turns both ways, stood 0.42 to 0.46 m apart, where the carry keeps the hands
up. The same-name chain held above turns to -1.66 and +1.80. The cross-name chain held above turns
to 1.26 either way, from 0.54 m, where a joined hand of the follow leaves its band. Read 2026-10-20
in `simulation/verdicts.md`, which prints each of these walks. The rig keeps a planned turn for both
chains, which carries each further (Planned sweep).

Cost: on the wall with its slope at 270, walked without this rule, the cross-name chain held above
turns to 1.60, from 0.86 m. Its hands then sit as low as 1.594 m, and under the band at 26 moments
of the rig. The positive way of the same-name chain turns to +1.88 there, from 0.74 m. Measured
2026-10-12 on a recording of that wall alone, by a probe outside the tree. Where the walk falls
short, the plan carries the sweep on (Planned sweep).

Verified by `suites/test_asks.nim`. It reads `design/rig.json` alone (Rig viewer). It reads every
moment that a sweep over the crown holds, the planned moments among them. That is 241 moments, on
the way that each sweep turns positive. Each joined hand is carried at 1.731 m at least, against
1.705 m, in `One hand, same name · above` at 0.44 of a turn. Measured 2026-10-20 by a copy of the
reading of the law in Python 3.11.

Red first, on the recording of the wall alone: 64 of 212 moments of the rig held a joined hand under
the band. Read 2026-10-12.

The law holds the carried point to the lower edge of the band less `SAG`, 1.705 m, as the laws of
the stills do. The ruling quotes the band itself, 1.735 to 2.00 m. Read against 1.735 m, the joins
of `Chain, cross name · above` lie under it at one moment of the rig, at 1.714 and 1.727 m. That
moment is at 1.2525 of a turn, in a planned turn.

The carried points of 29 moments of the rig lie between 1.705 and 1.735 m. Measured 2026-10-12 by a
probe outside the tree.

The law allows for the rounding of the rig, 0.3 mm in `design/rig.json`. A sweep of the rig also
keeps the moment that it stops at, where something gave, and the law leaves that moment out (Open
questions). A planned sweep keeps no such moment. The law reads the hands of each moment, and not
how far a sweep turns. The law of the planned sweep holds how far (Planned sweep).

## Stance and strain

**Where the couple stand is chosen for the turn, and every distance is tried.** The ruling of the
Architect: stand for the turn, hand height for the turn, everything for the turn. Nothing is fixed
but to keep the bodies apart.

Rejected: a stance chosen at rest, wherever the joints sit freest. The couple walk straight out of
it, and that stance turned 0.22, where 0.36 m turned 1.12.

Every distance from clear of each other (`CLEAR`) outward over a metre (`ROOM`) is swept whole, two
centimetres apart (`SEEK`). The measured landscape is plateaus four centimetres wide.

A card that asks whether the couple carry a turn (`walk.isReaching`) is answered at the first
distance that does. A sweep shown for its own sake (`furthest`) stands at the nearest distance that
carries the turn as far as any, to one step (`chosen`). It steps out only for a stance whose arms
move less than half as far between moments (`SMOOTHER`). It looks a tenth of a metre on once the
turn runs free (`LOOK`).

The nearest distance that carried a turn was chest to chest, with joined hands pinned between the
torsos and popping up between the heads. That is 189 mm in one moment at 0.36 m held above,
against 86 mm at 0.42, measured 2026-09-18.

To one step, because a stop is decided at the moment something gives, and mirror-image holds give a
moment apart from the same distance. Exact: L-l stood at 0.42 m for 1.00 of a turn held high, and
R-r at 0.38 m for 0.98.

Rejected: of the stances that carry the turn as far, the one whose arms move least, within five
millimetres. The largest leap of a walk is chaotic. Seen in mirror it differs by up to a fifth.
Built from the same source by another compiler, it differs by up to thirty five per cent. That is
125 and 114 mm from one distance, and 121 and 163 from another.

The last bits of two binaries differ, and the engine amplifies them. Five millimetres stood L-l at
0.44 m and R-r at 0.48 for one hold seen in mirror. That rule stands one hold two steps apart, built
twice.

Verified by `test_rigid.nim`. The sums measured that day, put to `chosen`, stand within one step in
five pairs. Those are the mirror pair in each build, each hold built twice, and the pair held high
whose turn reached differs by a step. The stance held above steps out from the pinned hands, to
under half their leap. Red first.

A still stands where its pose sits easiest. Every distance is wound to it, and the one nearest to
ease is kept. A distance at ease outright ends the search, and of two equal ones the nearer is kept.

Rejected: the first distance that holds. It is chest to chest, so a couple asked for `Face-to-back`
crush the free arm of the follow between two torsos.

Strain is read as the worst over every joint of every arm, both waists, and the two swings of every
collarbone (`strainWorst`, `Strain`). It is nought outside every ease, one at some end, and more
past it. A stop with no ease costs nothing to lean on, and counts only past half a degree (`SLACK`).
The engine solves its limits rather than clamps them.

Strain does not read the edge of the shoulder. So a still can stand with an arm on that wall and
read at ease. The search for where to stand does not weigh the edge either (Open questions).

The report reads strain off a pose alone, from the joints of the held arms. `read.tightest` names
the joint nearest its edge, and that joint gives the strain.
It reads each arm by `limb.margins`, against the ranges that the rig states. `limb.joints` reads a
left arm in mirror, so the twist of a left arm is already in the terms of a right arm. So the
reader keeps the ends of the twist as the rig states them, for both arms. Only the reading of the
engine, which is not mirrored, swaps those ends for a left arm (`rigid.twistEnds`).

Verified by `test_read.nim`, over the couples that it settles, one single hold at rest, and arms
that `limb.placed` builds. Every joint of every held arm has at least the margin of the joint that
`tightest` names. A pose and its mirror image name the same joint, with the same room, on the
mirrored arm. That law sweeps the twist of one held arm from -106 to 106 degrees, past both ends of
its range, -90 and 105. Both laws fail on a reader that swaps the ends of the twist of a left arm a
second time. The first law also fails on a reader that leaves an end of each connection unread.

A still whose card fixes no way about is wound either way at every distance, and takes whichever way
sits easier (`is_either_way`). Those are the frames of the standard diagram turned half a turn,
which draw the same picture turned either way and name no connection over. The card claims a frame
state and not a turn. For the single hold at half a turn, `simulation/answers.json` keeps where the
couple stand the way asked, and where they stand with either way free. The law below prints each
distance and its strain.

Verified by `test_rigid.nim`: the free way is never worse than the way asked, and is at ease. Red
first.

Rejected: to rank distances on a cheaper physics and sweep only the winner. That costs a fifth as
much, and does not rank them the same. Verified by `test_rigid.nim`. No distance carries a turn more
than one step further than the one chosen, and the couple are never offered a place inside each
other. The mirror law holds turn reached within one step, and what stopped it exact.

**A still is wound, and not built.** A card that draws the couple at half a turn or a turn and a
half draws a winding of the arms. No facing says that. Rejected: a still built at the facing. At a
whole turn, the couple then stand as at none, so the diamond reads as neutral and the swan as the
cross.

`walk.stood` turns the couple there from rest, at the pace of the walk itself, with the hands lifted
as they leave face to face. It then lets them stand, from the distance that sits easiest. Verified
by `test_rigid.nim`. A still asked past face to face has every joined hand in its band. The diamond
crosses where the open does not. Both red first.

## Asks of the Reference

**The Reference is asked of the model cell by cell, and the answer is a claim until the Architect
confirms it.** `design/asks.nim` is one list of what every still card asks: which hands, how far
turned, and whose crown the hands go over. `design/modelled` reads it, answers each one, and writes
`design/modelled.json`. `design/rig` reads it and records each still.

Moving cards ask whether the couple carry the turn under one manner of the four.

**A card turns the dancer that it draws turning, and the hands go over their crown.** The simulation
turns one dancer on their own spot, and the partner keeps their facing. A planned turn also steps
the follow nearer or further, on the line between the two (Planned turn). So a lead who turns a
quarter has the follow at their side, and a follow who turns a quarter is still ahead. Who turns is
half of what a card asks.

An orbit keeps the walker facing the centre (rule 32). So the relation of the walker to the
connection never changes, and the dancer at the centre turns against it. Physically, an orbit is
the dancer at the centre turning the other way about. That is the reading of the Architect. The
connection goes round the dancer who turns, so the hands go over their crown. `asks.turner` holds
this one rule for stills and for moving cards.

The page walks each single-hand move clockwise for every manner, as its caption says, and the chain
by the sense of its manner.

Verified by `suites/test_asks.nim`, each law red first. Every single-hand card stands the follow
where its cell draws them, facing as drawn. The two cards of one cell turn one dancer. Every card
carries its hands over the crown of the dancer who turns. Every single-hand move ends where the walk
of its cell ends.

**A crossed pair fixes its way about.** A frame that names one connection over turns whichever way
puts that one over, as the chain names its frame states (`route.overArm`). Its drawing is the same
either way about, because the drawing puts the named connection over whichever way the couple
turned. Rejected: a crossed still asked either way about, which can stand it in the mirror crossing
of its card.

Verified by `suites/test_asks.nim`, both red first. A09 is the D05 of the chain, and A11 its D03.
Every crossed still lays the connection that its card names over, at the crossing of the lead. That
crossing is the one nearest the lead along both connections.

**A still that answers a crossed card lays the connection that the card names over.** The search
for a still keeps only a pose that crosses the arms of the lead as the card draws them
(`walk.standsAt`, `walk.plannedStill`). Each card names the arm of the lead on top in `asks`
(`over`), and a card that draws no crossing names none. A reflected twin names the other arm. The
search reads the crossing as the law reads it (`read.crossings`). So a pose that crosses nothing, or
crosses the other way, is another frame state than the card draws, and does not answer it.

A wound frame of two connections names its arm by its wind, as the chain does (`route.overArm`).
So A16 and A17 name what C05 and C03 name, and each pair is one question. A frame that names its
own connection over winds whichever way puts it over, so its wind names that same arm.

Measured 2026-10-04, under the smaller face. Nearest to ease, C03 and C05 stand 0.44 m apart at a
strain of 0.036, and cross nothing. Crossed as their cards draw them, they stand 0.36 m apart at a
strain of 0.064. Rejected: the easiest pose, whatever it crosses, which showed C03 and C05 with no
crossing. Verified by `suites/test_asks.nim`: the law of the crossed still above fails on C03 and
C05 where the search keeps any pose. It fails on A16 and A17 where they name no arm, and so does
the law that one picture is one question.

The page counts turns clockwise seen from above, and the simulation anticlockwise. `asked` flips
every twist in one place, before the simulation answers, for every card and not for the chains
alone. Verified by `suites/test_asks.nim`: one picture is one question whichever section
draws it, A16 being C05 and A17 C03, red first.

The questions are answered on every core at once. Each worker lists the questions for itself and
builds its own worlds. The engine keeps its worlds in one table that it neither locks nor guards, so
to make and destroy them is locked in `simulation/rigid` (`LOCK_WORLDS`). Unlocked, two threads took
one slot for two worlds, and the verb died of an illegal instruction inside the engine every other
run.

Every cell of the Reference carries the badge of the simulation beside that of the Architect. It
reads *not modelled* where the simulation reaches no pose. It reads *unconfirmed* where the
simulation reaches one that the Architect has not yet held against their own body on the viewer.
It reads *modelled* only once they have, by name in `CONFIRMED` beside `KEPT`.

A confirmation is of one still, so a confirmed cell whose still moves comes out of the list. The
badge sits outside every drawing and moves no fixture. What the simulation reaches today is
counted off the built page, rather than written here. No cell is confirmed, and each waits for the
Architect to hold its still again (#440).

**Each confirmed cell is held to the still it was confirmed on.** `design/confirmed-fixtures.json`
holds a hash of the points of that still, in `rig.json`, for each ask of the cell. The build of the
Reference stops when a confirmed cell shows another still, or carries no fixture. A reflected twin
answers to the still of the twin it mirrors. A twin that no other cell answers keeps its own still.

`tools/build.nim confirmed` writes the fixtures from the built page, as `fixtures` does for the
drawings. To run it again would hand the confirmation to the new still, so it runs only when a cell
is confirmed. Cost: a change that moves a confirmed still fails the build until the Architect sees
that still again.

Verified by `suites/test_marks.nim`, which builds the Reference. Red first: another hash for A05
stops the build, and so does no fixture for B04. With no cell confirmed, the check runs on none
until the Architect confirms one.

**The stills that the C cards show stand as they are, and a watch reports each move (#611).** The
Architect kept C01 to C07 at a first look, and they are not confirmed. Every law holds their moments
as it holds any other. `design/watched-fixtures.json` holds each capsule end of the still that each
of these cards shows, as the rig viewer shows it. So a twin card holds the still that it names,
mirrored, and a card that comes to show another still moves too.

A move past 1 mm fails, and names the card, the capsule, the end, the move and the verb. A card
whose still comes to hold no pose, or to hold one, is named the same way. `tools/build.nim watched`
writes the fixture again, by hand, in the pull request that moves the stills. So its diff shows each
end before and after, and it never runs to quiet the watch. Verified by `suites/test_asks.nim`.

Cost: a still where no pose holds stops the build of the driver itself, because
`design/reference_page.nim` reads the points of every still at compile time. So the verb cannot
write such a still until that changes.

Two joined pairs of one still may stand close, and may touch. Only pairs that hook or tangle are
connected or interlocked. So A10 stands, where the two pairs almost meet over the head, as the
Architect ruled.

Two readings of section A come apart at A09 and A11, which draw the same-name pair face to face.
Rule 31 of the project itself says that this frame state has its connections lying through each
other.
Wound there from `Face-to-back` as the card says, the model stands them at ease, one connection over
the other. That is a finding against the reading of the rule, and not a number bent toward the page.

Sections B and E being whole is a weak result. Every card in them is held above, where a single
hold sweeps free past two turns, so they test the model hardly at all. The cards that discriminate
are the chains under twist.

## Rig viewer

**The viewer draws what the engine collides, beside the card it answers.** `design/rig` records
every still and eight sweeps as capsule ends that the engine reports, at the radius it collides on.
`design/rig_page` lays every still card of the built Reference beside the still of the
simulation for it. That card is the drawing, the badges and the caption, cut from the page itself,
so what is compared is what was ruled on. It is one list of entries, walked by two buttons or the
arrow keys. The drawing of the Reference sits next to the joint readouts on the stage.

A reflected twin card is the still that its mirror twin keeps, mirrored, as `design/rig_page`
folds it in (Mirror twins).

It is orthographic on purpose, so the outline of a capsule is exactly a stadium. Order is the
painter's, by depth. Each capsule is cut into pieces no longer than 40 mm, and each piece is ordered
by the depth of its own middle (`drawOrder`, `DAB`). Rejected: a whole capsule ordered by its nearer
end. It paints a hanging arm over the torso, and from near overhead the arm shows through the torso.

Hue is side, and shade is whose. Each body is lit from its own front (`litAt`, `mixColours`). The
side toward where the dancer faces is light, and the other side is dark. A body that faces the eye
is light all over.

The gradient runs square to each piece (`lightAcross`). Rejected: a gradient along the facing, which
shows stripes on a torso where pieces meet. Rejected: a floor chevron or a shoulder line for facing,
which the Architect rules noise. So facing is read from the body itself.

A capsule of no length, such as the face, which is a sphere, is filled as a disc. It is not stroked
as a line of no length (`drawn`), because browsers disagree on what that is. Chromium draws the
round caps as a disc, and WebKit draws nothing. Seen in WebKit on A07, on the phone of the
Architect, 2026-09-18.

Verified by `suites/test_drawn.nim`. A capsule of no length is a disc. An arm hanging beside a torso
is painted behind it where it is behind. The front of each body is lighter than its back. Light runs
across each piece and never along it. The first two and the last were red first.

**The caption says how far apart the couple stand at the moment shown.** It reads the distance
between the axes of the two dancers off where the recording has each stand then (`apartAt`). A walk
keeps one distance, and a planned sweep moves the couple as the plan has them (Planned sweep).
Rejected: the distance where a sweep starts (`apart`), which is wrong at most moments of a planned
sweep. Verified by `test_said.nim`, which reads every moment of `design/rig.json` through node. Red
first: 338 of 788 moments said a wrong distance, each in one of the two planned sweeps.

**The laws of the edge, of the hands, of the planned sweep and of the step read `design/rig.json`
alone (Architect, issue 651, 2026-10-20).** Rejected: a recording of both ways of every hold at
every level, which no page reads, and which each change to the physics records again.

Cost: these laws read no way of a sweep that the viewer does not play. Those are 13 ways:

- the negative way of L-l, L-r and L-l.R-r, held low, high and above;
- the positive way of L-l and L-r, held low and high.

The ways of R-r and R-l reflect those of L-l and L-r, and the negative way of L-r.R-l reflects its
positive way (Mirror twins). So the law of the edge reads 7460 fewer arm-moments, and the law of the
hands reads 733 fewer moments. Counted 2026-10-20 at `2c6c9b62`. No floor holds how far the plan
carries a way that turns negative (`TURNS_PLANNED`). The laws of `tests/test_rigid.nim` read both
ways of the single holds over the crown, walked alone (`simulation/answers.json`). The report prints
how far the walk carries each way, and no law reads its numbers.

## Against the floor

**Against the floor, which is the Architect's.** The floor says that everything gets a whole turn
before it blocks, except a low wrap, which gets half. Nothing is tuned to it. Every change is argued
from the rig or from a ruling of the Architect.

`simulation/verdicts.md`, section The floor's claim, prints each claim of the floor beside the
answer of the simulation and what stops it. So a gain and a regression are both seen. A recording
can move any row, so this record cites the report and does not restate it. Where a row disagrees
with the floor, the ruling is the Architect's.

Held above, nothing stops either single hold within a whole turn, either way. Those are the rows of
the floor held above. Verified by `test_rigid.nim`, test "held above, nothing stops single hold
turning". No law holds the rows held low and high, which the report prints alone.

**Verdicts are an instrument run, assumed current.** `simulation/verdicts.nim` asks the simulation
what the sheet asks. It writes `simulation/verdicts.md` in the words of the sheet, through one
visible translation table, wrapped at 100 columns. The chain rungs there are wound to, as stills
are.

No test compares the kept readings with the physics. So the report is current as of its last run,
and stale until it is run again. It is run again in the same delivery as any change to the model.
A law holds the report to the readings that it renders from (Kept answers).

**The crossing reader gives one answer at a knife edge.** `read.crossings` counts where two
connections cross in plan. Two segments cross where each has the ends of the other on opposite sides
of its line. A point within `ON_LINE` of a line counts as on its positive side.

So a vertex that two segments share counts for one of them alone. An arm laid along the other
crosses it once, where it leaves to the far side. Rejected: an intersection read from the two lines
alone, which counts a crossing at a vertex of both connections four times.

Verified by `test_read.nim`, test "crossing reader gives one answer at knife edge". A crossing at a
vertex of both connections reads as one crossing, and so does an arm laid along the other. Each
reads the same in every one of `TRIALS_JITTER` seeded trials, with each point moved up to 1e-13 m in
plan.

## The swan

**The carried walk does not reach the swan, and a planned turn does.** A planned turn reaches the
four swans, which the walk does not (Planned turn). What follows is why the
walk gives short. It is the reason that the planned turn exists.

The corpus law in `test_rigid.nim` holds every still it walks to a strain of 0.1 (`AT_EASE`). That
is two degrees of a twenty degree ease. It walks both chains from cross to cross, and the same-name
chain either way about at half. It walks the free frame Face-to-back too, and the single hold at
quarter and half. It stops at the cross. Every other still that the walk holds stands at ease, or
within a fifth of an ease at its worst joint, measured 2026-09-18.

Turned as `walk.stood` turns a still to its facing, the swans give short. The cross-name gives at
0.22 to 1.00 of a turn, from each of the 50 distances that `walk.stands` offers. At 35 of them the
hands sit outside their band, mostly under it. At 14, the arms of one dancer cross above the elbow.
At the last, an arm meets an arm.

The same-name stands at rest from 45 of those distances. D01 gives at 0.04 to 0.50 of a turn, and
D07, turned the other way, at 0.06 to 0.90. Each time, the arms of one dancer cross above the elbow,
or the hands sit outside their band. Under the rule that rests the hands at mid torso facing, the
walk stands no diamond either. Measured 2026-10-09 at `e1dfe66`, by a probe outside the tree that
turns each swan as `walk.stood` does.

The film of the cross-name in that probe shows why. Hands are carried at the lower edge of the band,
45 mm over the crown, which is one radius of an arm (`HUMAN.band`, `HUMAN.limb`). That leaves no
room for a forearm to cross above the head. From 0.76 m out, the hands stay there until they sag
under the band, and no forearm of the follow passes over the head. Nearer, at 15 of 20 distances, a
hand is carried above 1.80 m, and a forearm of the follow crosses over the head at 9. There the arms
of one dancer mostly cross above the elbow.

Carried a hand's breadth higher, or on up through the band, the cross-name swan winds to 1.14 and
the same-name gives early by twist. Those lofts are assumed. The Reference draws the two joins of
the swan at one point, one pair under the other. The two pairs of joined hands gathered together
over the crown that way winds the cross-name to 1.34, with the follow's collarbone at its end.

Eight one-line changes on the lofted model were each measured on both swans at four distances, with
five held stills as control. None stands a swan. A stiffer tie and a finer step carry the
cross-name furthest, to 1.16 and 1.32, with hands parting or the follow's wrist at its cone. A wider
wrist cone and a firmer draw carry the same-name furthest, to 1.42 and 1.38, arm against arm. A
softer collarbone, wider extension or a stronger loft lose a diamond.

Rejected outright: the arms of the lead passing through those of the follow. That reached the swan
by letting two arms occupy one place.

## Planned turn

**A turn that the carried walk does not reach is planned, and the engine follows the plan.** The
carried walk moves the arms only by weak pulls on the hands. So an arm caught on a head or on
another arm stays caught. A dancer chooses the whole arm, and so does the plan. It chooses the
collarbone, the roll of the shoulder, the elbow, the wrist, the waist and where to stand.

Every turn of the Reference is led over the head (#375). Face to face at rest, the hands come down
between the bodies.

`simulation/plan.nim` plans the arms of both dancers a fiftieth of a turn at a time (`STRIDE`). At
each moment it takes the pose nearest to ease, close to the last pose, that keeps five things.

The hands stay joined. Every capsule stays 20 mm clear of every other (`clearance`). Each joint that
the judge stops at stays six degrees inside its end (`margin`), and each waist and collarbone stays
within its range. Each upper arm stays the same six degrees inside the edge of the shoulder, read in
both cost paths from one term (`ArmPlaced.outside`, `marginsArm`). The joined hands stay 30 mm
inside their band (`room`). They turn against each other no further than their grip lets, with the
same six degrees to spare (`gripBroken`, Planned grip).

Each face is a capsule of the plan too. The arms and the girdles of the partner keep clear of it,
as in the engine. Verified by `test_plan.nim`: the plan pairs each face with every capsule that the
face of the engine meets.

The plan keeps the elbow rule of the judge too (Rigid body engine). It adds a cost where the upper
arm of a dancer comes within 1 cm of their other arm (`CROSS_ROOM`). The cost is nought at the end
of the elbow, and it grows over one radius of an arm. So an arm that lies just before the elbow
costs nothing. It adds a cost where the elbows of a dancer come within 1 cm of the order that the
judge holds (`ELBOW_ROOM`).

For an arm on an upper arm, the room under the limit of the judge is the 5 mm slop of the engine
(`CROSS_ROOM`). For the order of the elbows, it is 1 cm (`ELBOW_ROOM`). Verified by `test_plan.nim`:
the cost of each step that the planner keeps is the plain cost, to the last bit, with these terms in
it.

The plan is geometry alone. It uses the capsules, the ranges and the bands of the engine and the
judge. So the engine meets nothing that the plan did not keep clear. No point of an arm moves more
than 60 mm between two moments (`leap`), which is less than the thickness of an arm. `walk.replay`
stands each moment afresh (`standAt`), so between two moments only the leap bounds where an arm
goes. Sprung after the plan (`walk.follow`), the engine carries the arms as solid capsules, and
stops an arm that would pass through another.

The plan also keeps the arms 40 mm clear where it can, at a cost (`ROOMY`, `slack`). It holds the
hands at the `Torso` band until the couple are a fortieth of a turn from face to face. That is twice
the window of the judge (`FACE_WINDOW`), so the hands are down when the judge reads them.

When the plan stops, it goes back some moments, moves the arms a little, and goes on. At each third
stop it goes back to the last moment that the couple faced each other. It arranges the arms again
there, and then goes on. The way down into facing decides the way up out of it.

**The engine stands every planned moment, and the judge is the one of every walk.** `walk.replay`
stands every body where the plan has it at one moment, with nothing moving (`standAt`). It aims
every joint at the plan, lets the engine take two steps to find every contact (`STEPS_STAND`), and
judges (`gives`). Then it takes the next moment. A planned moving card holds where the engine stands
every moment of its plan. A planned still must also hold after the pose settles at its end
(`SETTLE`, `should_stand`).

Each moment is stood afresh from the plan, so the engine judges the plan itself. Sprung after the
plan instead (`walk.follow`), the answer turned on the drift of the springs. D01 and D07 held or not
on the last bit of one sum.

The lead's turn of the same-name chain to its swan gave at 0.46 to 1.11 of a turn, sprung. It gave
in every style whose plan reached the swan. Stood a moment at a time, with the gap to a palm read
true, every such plan held: 4 of 8 tries each way. Measured 2026-10-02.

The plan holds every capsule clear at each moment, and no point leaps further than its style lets
it between two moments. So the replay judges a path, and not a list of poses.

**The engine can also follow the plan, sprung after it.** `walk.follow` stands every body exactly
where the plan starts (`placeBodies`). It then aims every joint at the plan with a spring of 30
hertz (`steer`, `STEER`). The wrist spring is three times as stiff, because the hand
is the lightest link (`WRIST_STEER`). The engine turns the dancer that the plan turns, and steps
the follow, as the plan does (`turnStepping`). The judge is `gives`, and nothing in it changes.

At each moment the planner reads the pose of the engine (`poseVector`). It plans the moment again
from that pose (`corrected`), so the drift of the engine is answered at each moment. The target
moves across the moment from where the couple are to the plan (`turnStepping`). That is a choice,
and not a need that was measured. Measured on 2026-10-02, with the target at the end of the moment
from its first step. D07 stands too, with a strain of 0.33 against 0.34, and so does the cross of
the test.

While the couple are steered, the lift, the draw, the weight of the elbow and the ease torques are
off. The plan already holds what they do. The walls past the end of each swing stay on.

`test_plan.nim` holds the springs to one planned turn, so this way stays able to follow a plan.
No card is answered by it.

**A planned still stands in the easiest plan that holds.** The planner tries sixteen styles
(`STYLES`). A style sets how hard the two joined pairs are drawn to one point. It also sets how hard
each moment is held near the last, and one of four starts at rest. A hold that is its own mirror
image also tries the mirror image of the plan for the other way about (`mirrored`). A still that
fixes no way about tries both ways.

The engine stands every plan, and the rig viewer shows the one that holds nearest to ease
(`walk.plannedStill`, `seen.still`). The search ends early only at a plan at ease, which no other
plan betters. `design/rig.json` keeps the strain of each plan that it tried, and null for a plan
that gave (`tried`). The viewer shows the still alone, and not its strain. `design/modelled` asks
only whether a plan holds, so it stops at the first (`isPlannedHolding`).

Cost: a still short of ease stands every candidate. In the full recording of `f39968a8` on four
cores, with four jobs at once, D01 took 383 s, C01 358 s and C02 225 s. With the plain cost on
2026-10-03, they took 12,688 s, 10,856 s and 3,152 s. C07 and C06 take the stills of C01 and C02,
reflected (Mirror twins). D07 rests face to back, and took 29 s, because it plans the 32 paths of
D01, which the run keeps (Kept answers). Measured 2026-10-04.

Rejected: the first plan that holds. It stood C06 with the waist of the follow at its end, strain
1.00, where another path of the same style held at 0.19. Measured 2026-10-03. Verified by
`suites/test_asks.nim`: each still stands at the least strain of all that it tried, and a still
short of ease tried every candidate.

**The gap to a point is read from the nearest point of each segment.** The planner holds each face
as a point with a radius, as the engine does. Verified by `test_plan.nim`, red first.

`vector.closest` read the gap from the start of the other segment when that segment was a point. A
palm was a point then. A plan of the drawn D01 kept 5.8 cm between a palm and a forearm, where the
palm sat 5.4 cm inside it. The engine stood that palm 4.3 cm inside the forearm and gave.

The planned turn answers cards that the walk does not, the four swans among them.
`design/rig.json` marks seven stills `planned`: A11, C01, C02, D01, D03, D06 and D07. C06 and C07
take the stills of C02 and C01, reflected (Mirror twins). Which moving cards the plan alone answers
is unmeasured on this physics.

**No plan inside the edge carries the lead's turn of the same-name chain past 0.71 of a turn.** In
each of the 16 styles and their mirror paths, the plan of +1.5 stops between 0.37 and 0.70 of a
turn. With the edge kept at no margin, it stops between 0.38 and 0.71. So do the plans of -1.0 and
-1.5. Measured 2026-10-11 by a probe outside the tree.

With the edge left out of the plan, plans reach +1.5. From about 0.42 of a turn they raise both
upper arms of the follow up and behind the head. By 0.65 of a turn those arms lie up to 57 degrees
past the edge, and by +1.5 up to 90. The engine stops each such plan by swing.

The walk carries one way of that turn, the positive one, to 0.70 of a turn, from 0.54 m. There
the left wrist of the follow stops it. The walk carries the other way to 1.5 turns. Measured
2026-10-12 by a probe outside the tree, on the physics of this tree. So `design/modelled.json`
answers +1.0 and +1.5 no, asked as the turn of the lead and as the orbit of the follow.

**The edge refuses the cards of that turn to +1.0 and +1.5 (#611, D1).** The Architect ruled that a
card that the edge stops is refused, once a better wall is tried for the two cards at +1.0. No wall
carries +1.0 except by chance (Wall at the seams). So the law names six refused cards, each with
its reason (`CARDS_REFUSED` in `suites/test_asks.nim`):

- `pw_la_4` and `pw_fo_4`, the turn to +1.0. No plan inside the edge passes 0.71 of a turn, and no
  wall that was tried carries the walk there except by chance;
- `pc_la`, `pw_la_5`, `pc_fo` and `pw_fo_5`, the turn to +1.5. The plans that reach it lift the
  upper arms of the follow behind the head, up to 90 degrees past the edge.

`la` is the turn of the lead, and `fo` is the orbit of the follow, which asks the same
(`asks.turner`). The Reference reads the same answers. It shows not modelled on G03 and G05, and on
the last two steps of G04 and G06, and on no other cell. Read by a probe outside the tree on the
copy of the Reference that the suites write, 2026-10-12.

The plan of D07 that `design/rig.json` keeps puts the couple 0.60 m apart. It holds its two joins
0.23 m from each other, at 1.25 m and 1.28 m, in the upper third of the `Torso` band. Measured on
2026-10-11.

**Two planned stills stand at an end, and none is at ease.** Strain is nought at ease and one at an
end. In the easiest plan that holds, D03, A11, C02 and C06 read 0.01. D06 reads 0.50, D01 and D07
0.80, and C01 and C07 1.00. Measured on 2026-10-11 from `design/rig.json`.

Each of those strains is a waist. In C01 and C07, both dancers turn the chest 40.0 degrees against
the hips, which is the end of the waist. In D01 and D07, the waist of the follow turns 37.0 degrees
and that of the lead 32.9. In D06 the waist of the follow turns 32.5. Read off the facings in
`design/rig.json` on 2026-10-11, by a probe outside the tree.

Rejected: to let the arms settle toward ease at the end of the turn, a leap at a time. With the
engine sprung after the plan, that took C01 from 0.56 to 0.53 and left D07 as it was.

The spring is 30 hertz because of what was measured on D07 on 2026-10-01. At 15 hertz the engine
gave by twist at 1.47 of a turn. At 25, 30 and 40 hertz it stood, with a strain of 0.33 to 0.34 at
the extension of the left shoulder of the follow.

Rejected, each measured on the cards that the walk does not reach, on 2026-10-01:

- torque that holds the twist of each shoulder to the plan, at 30 and 100 newton metres for each
  radian. C01 gave at the same moments as without it, and D07 gave at 1.26 of a turn, not 1.46;
- a softer spring on the arms of the follow, a tenth and three tenths of the spring of the lead.
  C01 gave between 0.60 and 1.37 of a turn, by an elbow, a swing, a wrist or span;
- arms with no friction. The plan of C01 stopped at the same moment, and D01 gave at 0.96 of a turn,
  against 0.98 with friction;
- two times the engine steps for each moment. D07 gave at the same moments, 0.71 and 1.31 of a turn;
- capsules of true size in the plan alone, 33 mm for the forearm and 16 mm for the palm. Each plan
  of the same-name swans then stopped at 0.59 to 0.70 of a turn. With the capsules of the engine,
  the same plans went to 0.71 to 1.17. That was measured with the gap to a palm read wrongly.

Verified by `test_plan.nim`. The engine stands every joint where the plan places it, and reads the
plan back, within 0.1 mm over 128 poses. A third of them are at rest. The others are 0.3 of a turn
past rest, turned by the follow or by the lead.

The mirror image of a plan stands every point at its reflection. A planned turn of the cross-name
chain to its cross keeps the hands joined, the capsules apart and no point leaping. The engine
follows it and stands there.

Each law failed on a break made on purpose. The breaks were the lift read back with the wrong sign,
and a sign kept in the mirror. Others were the joined hands left out of the plan, and the shoulder
aimed outside its rest frame. The last was the bodies placed turning the follow whatever the plan
turns, which put a point 1.25 m off the plan.

`suites/test_asks.nim` holds that the simulation models every card that the Reference draws, except
the six cards that the edge refuses. It also holds that each refused card stays unmodelled, so a
change that models one lifts its refusal. 225 of 231 cards are modelled, measured 2026-10-12.

## Planner's cost

**The planner weighs a step of one freedom by what that step moves, and the cost is the same to the
last bit.** The solver finds its gradient by a step of each free freedom in turn. They are 39 of the
pose, and the depth of each held hand. In one plan of D03 on 39 freedoms, its gradients were 99% of
its 543,619 weighings, measured 2026-10-04. A step of an arm freedom moves that arm alone, from the
first link that the freedom moves. A step of how far apart the couple stand, or of either waist,
moves one body and no other.

So the planner keeps every term of the pose (`Reckoning`). A step places again only what it moves.
It reckons again only the pairs and joints that the moved capsules are in. Each sum then runs over
the kept terms in the order of the plain cost.

The planner does not reckon a pair whose two balls keep it further apart than every threshold,
because no sum adds it. A mask of the pairs near enough to add lets each sum skip the rest, in the
same order.

Verified by `test_plan.nim`, suite "Internal: Planner's cost". At 96 seeded poses, each step and a
long step of each freedom and back cost the plain cost to the last bit. Each of seven breaks made on
purpose failed it.

The paths of D03 and A11, in six styles and both mirror paths, are those of the plain cost, to the
bit. No law holds them. Verified on 2026-10-04 by a probe outside the tree, which prints every bit
of each planned path. It ran on the tree before this planner and on the tree with it. At `4e54fceb`,
which holds this planner, every kept file was the bytes of those of `9bbf656`, apart from its stamp,
verified 2026-10-04.

The first plan of D03 took 10.73 s, and 0.87 s with this planner on 39 freedoms, measured
2026-10-04. In a run of four planned
stills at once, rig D01 took 12,688 s with the plain cost on 2026-10-03. With this one, it took 544
s on 2026-10-04.

Rejected: a gradient from the derivative of each term. Its speed is unmeasured. It is not the
difference that the solver finds now, so every plan would move, and the Architect would judge every
card again.

## Planned grip

**The plan holds how far past the wrist each held hand grips, and the engine stands each hand at
that depth (#440).** Each held hand has one more freedom in the plan, the depth of its grip
(`DEPTHS`). It runs from the middle of the palm to the fingertips. A free hand holds nothing, and it
hangs relaxed (Body rig). The grip of the two that is held nearer the fingertips sets how far two
joined hands turn (`rig.gripFreedom`).

The engine sets each tie at the planned depths, and shortens each held hand to its grip
(`rigid.setTie`). It holds the cone of the grip within a quarter turn, where its swing is the tilt
of the plan to the last bit. The plan alone holds a wider cone, and the twist. The engine measures
twist about the second palm after the swing, and the plan as the angle between the finger lines.
With the palms tilted far apart, the two part by up to 35 degrees. A connection that nobody planned
holds at the fingertips, where two hands turn freely, so the engine sets no limit there.

Verified by `test_plan.nim`. Stood at each moment of the planned turn and sprung toward it for one
moment of walk, the engine parts no tie. With the twist limited by the measure of the engine, it
parted the joined hands by 0.84 mm. The engine shortens each held hand to the length of its grip,
within 2 mm, and holds the capsule that the couple records. Two hands held at two depths turn as far
as the one nearer the fingertips lets.

## Planned sweep

**Where the walk over the crown stops short of all that a sweep asks, the rig keeps the planned way
(pull request 629, D1).** The Architect ruled on 2026-10-12. Where the walk alone lets the joined
hands sink, the plan lifts them. The recording keeps the planned turn where the walk falls short.
The cross-name chain held above then stops near 1.53 turns, where the edge forbids more.

**The plan answers every stop of the walk over the crown, and not only a hand that sinks (pull
request 629, D1 of its notes).** The Architect ruled on 2026-10-12 (`ways`). So the same-name
chain held above is planned too. The wrist of the lead stops its walk at +1.80, and arm through arm
stops it at -1.66. The plan carries it to 2.5 turns both ways. Rejected: a plan for a sinking hand
alone, which leaves that chain at -1.66 and +1.80, where the walk stops it.

A way over the crown that the walk stops short of 2.5 turns is planned toward 2.5 turns
(`plannedWay`). Each style is tried in its order, own path and mirrored path, as a planned still
tries them (`pathsFor`). The engine stands each moment of each path afresh, and the judge of the
still reads it (`replayedWay`, `gives`). A path is cut at its first moment that gives. The
furthest path is kept, and of two as far, the earlier. The way keeps it where its last moment lies
further on than the last moment that the walk holds (`turnsHeld`).

The plan holds the joined hands inside their band, and every upper arm six degrees inside the edge
(Planned turn). So a planned way keeps the hands over the crown by construction. Its judge holds
them from a quarter turn going out, and from an eighth coming back.

The distance is free, because the plan places the couple at each moment. The rig writes where its
path starts, and the rig viewer says the distance at each moment (Rig viewer). Rejected: the
distance of the walk. There every style tried stalled, at 0.19 to 1.75 turns. Measured 2026-10-11 by
a probe outside the tree, on the physics of that day, and unmeasured on the physics of this tree.

Of the recordings, only the rig asks for this (`swept`, `should_plan`). It sweeps both ways, and
keeps the way that turns positive (`seen.shownAsked`). The report and the kept answers read the walk
alone (Open questions).

The rig stands each moment of the kept path again from its plan (`seen.shown`), and marks the sweep
`planned`. A planned way keeps no moment that gave. A way that ends short of 2.5 turns names nothing
that gave, because no planned pose stands further on. The rig viewer says "no plan carries the turn
further". Which stop such a way names is open (Open questions).

Rejected: a stop read off the terms of the plan. One solve past the end of the cross-name chain
broke several terms at once, each by about a millimetre. Those were hands apart, arms within their
clearance, and a hand under the edge of its band. Measured 2026-10-12 by a probe outside the
tree.

**A planned way can stand several poses at one turn, and the rig keeps each of them.** When the plan
stops, it goes back, poses the arms again and goes on (Planned turn). The rig keeps each such
moment, at one turn, and the rig viewer plays every moment.

**The plan carries the cross-name chain held above to 1.5275 turns, and the same-name chain to
2.5.** The cross-name chain stands from 0.957 m, by style 13 and its mirror. Of its 139 moments, 48
stand at a wind already stood. The same-name chain stands from 0.417 m, by style 4 and its mirror.
Of its 207 moments, 57 stand at a wind already stood. Measured 2026-10-12 in `design/rig.json`, on
the way that turns positive.

The walk alone carries them to 1.26, and to -1.66 and +1.80, read 2026-10-20 in
`simulation/verdicts.md`. The single
holds run free on the walk, so the plan is not asked. It carries each of them to 2.5 turns too,
measured 2026-10-12 by `tools/build.nim floors`. That run planned each hold over the crown both
ways, and the negative way of each reached as far as its positive way. Each way that the rig keeps
over the crown is a row of `TURNS_PLANNED`.

**The edge holds the cross-name chain near 1.53 turns.** Over the last part of the turn an upper arm
rides the six degrees that the plan keeps inside the edge. At 38 of the 91 turns that the rig
stands, from 0.45 of a turn on, the nearest arm lies 5.9 to 6.1 degrees inside. No arm of the rig
comes nearer than 5.98 degrees.

With the edge margin of the plan at 0 or 3 degrees, and its other margins kept, no path stands past
1.540 or 1.526 turns. So the margin of six degrees costs about a hundredth of a turn. With no edge
term at all, 15 of 32 paths plan past 1.5275, to 1.6225 at most. The engine stands none of them
past 1.4475. Each lays an upper arm past the give of the edge, and the engine stops it by swing
there. Measured 2026-10-12 by probes outside the tree.

**Between two moments, the planned ways leap less than the walks that they replace.** In
`design/rig.json`, no end of a capsule of an arm of either chain moves more than 62 mm from one
moment to the next. In the rig recording of `bc656d30`, which walked both chains, the ends moved up
to 596 mm and 570 mm. Measured 2026-10-20 with Python 3.11, the same way on both.

Cost: the rig plans 64 paths over the crown, for both chains toward both ways in every style
(`planAhead`). With them, a full `tools/build.nim record` took 24 min 8 s on 2026-10-20 (Figures).
Without them, its time on this tree is unmeasured.

Verified by `suites/test_asks.nim`. Every way over the crown that the rig keeps holds as far as the
plan carries it (`TURNS_PLANNED`), less half the rounding of the rig. Those are the four ways that
turn positive, and the law reads no other recording (Rig viewer). The law reads the furthest moment
that each way holds. The law of the edge reads every planned moment, and the law of the hands each
one past a quarter turn.

Red first, on the recordings of `bc656d30`: 2 of the 4 ways of the rig fell short. The cross-name
chain held to 1.24, and the same-name chain to +1.78.

Verified by `suites/test_asks.nim` too: every sweep of the rig starts at rest, and steps no more
than one moment from there to its end. So no way leaves out a moment between rest and where it ends.
It passes on this tree.

A copy of the rig recording of `cd9ec9a8` has the moments from 0.80 to 1.20 of a turn cut out of
`Chain, cross name · above`. On that copy the law names the one gap, from +0.7900 to +1.2125. Read
2026-10-20 by a probe outside the tree. Red first: on such a copy every other law passes, read
2026-10-12.

`tools/build.nim floors` measures each floor again (`design/floors`). It plans each sweep of the rig
over the crown, the way that the rig keeps, which turns positive. It prints the row of
`TURNS_PLANNED` for each sweep, keyed by its card, and the style and start of its path. Its rows
come in the order of `design/rig.SHOWN`, and the table holds the values that it printed on
2026-10-12. On 2026-10-20 it printed the same rows, styles and starts again. It took 7 min 7 s, and
25 min 39 s of user time, on four cores.

Cost: the law reads each floor as a figure, and does not plan again. A change that carries a chain
less far fails the law. A change that carries it further passes, and its floor stays short until
`floors` runs again.

## Pages and build

**Every published title is the name of the work, then the name of the page.** The project stands
behind each of the three pages that it publishes, so every title takes this one form. A gallery then
sorts the pages of the work together.

Each page takes its own name after the name of the work:

- the Explorer is `Dance Ontology Explorer`
- the Reference is `Dance Ontology Reference`
- the rig viewer is `Dance Ontology Simulation`.

Inside the project the third page is the rig viewer, because simulation already names the body
simulation.

The name of the work is spelt once, as `WORK` in `tools/title.nim` (Article II.1).
`design/page.nim` and `tools/bundle.nim` put it in front of the name of each page, with a space
and no dash.
The heading of each page shows the same title. The workbench takes it from `page.titled`, and the
Explorer takes it from `WORK` in `app/app.nim`.

`tests/suites/test_marks.nim` asserts that each page it builds carries the name of the work, then
its own name. It asserts it against the constant, rather than against a repeated literal.
**Verified** on 2026-10-21: a dash put back into `page.titled` reddens that suite.

Every title reads in title case. `tests/suites/test_marks.nim` holds each page of the workbench to
it. It reads the title that the page was written with, rather than a list. It reads the title of
the rig viewer from its constant (`rig_page.TITLE`). Red first, on a title in sentence case. No law
holds the title of the Explorer to title case.

**The browser comes from the environment, and the declaration says what to install.** `shot` drives
Chromium through Playwright. Rejected: an absolute path for either in `design/shot.nim`, which pins
a version in the least durable place there is (issue 62).

`tools/build.nim` declares `git`, `binutils`, `nodejs`, `libbrotli1` and `chromium` as data, each
with what it is for and whether an installer takes it (`SYSTEM`). A `system` verb prints those that
an installer takes, one to a line: `git`, `binutils`, `nodejs` and `libbrotli1`. The `shot` verb
prints `chromium` as what the helper needs, since a person runs the helper by hand.

`libbrotli1` serves `koch drive`, which reads the `cmap` of each font face that a page ships
(Drive). The two font faces of Commit Mono ship as `woff2`, which keeps its tables in one Brotli
stream. Verified by a run of `nim r tools/build.nim system` on 2026-10-23, which prints the four
names.

`shot.nim` takes Playwright from `DANCE_PLAYWRIGHT`, or from the bare module name that node
resolves. It takes the browser from `DANCE_CHROMIUM`, then from `chromium` beside the store of
Playwright itself (`PLAYWRIGHT_BROWSERS_PATH`), and otherwise lets Playwright resolve what it
installed. Absent Playwright stops with a finding that names the verb that says what to install,
rather than as a missing file.

`package-lock.json` pins Playwright for `drive`, and `npm ci` installs it where node resolves the
bare module name. So `shot` finds the pinned Playwright with no variable set.

Cost, stated rather than implied: the system packages carry whatever version the machine has.
Verified by a run of four routes on this machine, 2026-09-08, Node 22 and Chromium 1194 of
Playwright. With nothing set and no Playwright in the project, `shot` stops with the finding and
exit 1. `DANCE_PLAYWRIGHT`, `NODE_PATH` and `DANCE_CHROMIUM` each write the screenshots of both
themes. A path that names no browser fails loudly rather than silently. No test drives `shot`, since
`drive` renders pages and takes no screenshot.

**URLs are listed once.** The URL of every published page is in the `README.md` of this project, in
one table. `design/README.md` and `simulation/README.md` point at it rather than repeat it (Article
II.1). A page taken out of use is not listed, and its published copy can be deleted. The repository
does not treat a published copy as its record, because the log does that. Cost: a URL is not beside
the subsystem that builds the page.

**Hand-written pages are committed files, and everything a build emits is not.** The shell of the
Explorer is `pages/app/index.html`, a page that the project stands behind.

`tools/build.nim pages` copies the one shell, that of the Explorer, into `build/app/`, and compiles
the script of the Explorer beside it. It folds the two into a single file with `tools/bundle.nim`.
Generated pages stay uncommittable, because their lines run to thousands of characters.

Tool binaries land in `binaries/`, and pages land under `build/`. Test binaries land beside their
sources. The root ignore file covers all three at any depth.

Rejected: markup in Nim string constants, which costs one string-literal edit for every change of
style.

Cost: markup read at run time takes a run-time check, and not a compile-time one (Article IV.4).
`tools/bundle.nim` refuses to write the Explorer where its shell does not load the script that it
folds in.

**The verbs of the project live in a compiled driver, and not in make.** `tools/build.nim` takes one
command and runs it from the project directory. The table at the head of the file names and explains
each one except `engine` and `system`.

The verbs are the pages and their assets, the type check of the harness (`types`), and the verb that
renders every page for `koch drive` (`drive`). They are also the recordings that rewrite committed
data nothing else may edit (`modelled`, `rig`, `verdicts`, `answers`), and `record`, which runs them
all. The rest are the fixtures (`fixtures`, `confirmed`, `watched`), the floors of the planned sweep
(`floors`), the engine, the screenshot helper, the system declaration, and `clean`. Koch drives the
tests, and holds no verb for pages.

Rejected: a nimble task, which would put build logic in the virtual machine of the compiler.
Rejected: to ask koch for a verb specific to a project. Cost: the driver runs from the project
directory, because every path in it is relative. Each recording costs minutes, which is why none
runs under `pages`.

## Font faces

**Every page ships the font faces it draws with, inlined.** Headings and titles take Noto Serif,
body text takes Noto Sans, and code and data take Commit Mono. Those are the standard three of the
Architect, and what Article X.8 names. Every heading rule of every style sheet names the serif
stack. Verified by `suites/test_font_faces.nim`, test "every heading takes serif font family".

Labels drawn inside figures take Noto Sans rather than Commit Mono. The "code, data and figures" of
X.8 reads as numbers, and a label that names a hand is interface text. Every label that the code
draws names Noto Sans first. The check in `curator/audit/src/font_families.nim` joins the literals
that `&` carries across a line end, so it reads each label (#412). It holds a label only to a first
family that X.8 names, so reading alone holds it to Noto Sans. Verified by hand with a search of the
source on 2026-10-18, which finds Noto Sans first in every stack of a label.

**No font family of the three draws every character that the pages draw, so each stack names two
more.** Noto Sans and Noto Serif draw no arrow, and Commit Mono draws no `⇄`. Noto Sans Math draws
all five arrows, and Commit Mono draws marks such as `✓` that the text font families lack. So a
stack names its own font family, then Noto Sans Math, then Commit Mono. That is the merge by
codepoint range of X.8. The maps were read with fontconfig 2.15.0 on 2026-10-03, from the whole
font faces with the digests of the store.

The wiring is verified by `suites/test_font_faces.nim`, test "every stack falls back to font
families that draw what its own font family lacks". The coverage is verified by `koch drive`
(Drive), on every page that `pages` writes, except the Explorer before `bundle` folds its script in.
That page loads `app.js` from beside it, and its hosted copy finds none there. The bundled Explorer,
`app/artifact.html`, is the same page as published, and `drive` renders it.

Rejected: Commit Mono alone, which draws no `⇄`. Rejected: another mark for `place`, which would
change the design.

**Suites write pages apart from the directories that `pages` writes.** A page that a suite writes
carries no font faces. So `test_marks` writes under `build/suites/`, and `pages` dresses only
`build/app` and `build/design`. A suite page that stands where a published page stands could be
published without its font faces. `drive` renders only what `pages` dresses, and the control page
of `koch drive`.

**A dressed page that declares no charset declares UTF-8.** The Reference, the rig viewer and the
bundled Explorer are fragments, and publishing wraps each one in a document. Opened from a file,
a fragment declares no charset, so the browser guesses one from the bytes before the first
non-ASCII byte. The font face block is 5,655,720 bytes of ASCII. Behind it, Chromium 141 reads an
undeclared page as windows-1250.

So `withFontFaces` puts `<meta charset="utf-8">` first in a page that declares none. Verified by
`suites/test_font_faces.nim`, and by hand in Chromium 141 on 2026-10-02: every page read as UTF-8.

**Each Noto font face ships whole, as the TrueType of its own release.** Noto was chosen so that no
character of a page falls outside its font faces. A Latin subset undoes that (Article X.8, as #425
rules it). Commit Mono is no Noto, and keeps its Latin subset. Each rule declares the media type and
the format of its own file, which `formatDeclared` reads off its extension.

Verified by `suites/test_font_faces.nim`, test "every Noto font face ships whole, as TrueType of its
own release". With the Noto subsets of `@fontsource` back in its rows, that law fails on each of the
six Noto font faces. The test "each font face declares media type and format of its own file" holds
the formats.

**The hinted build of each font face of Noto Sans and Noto Serif ships, by the ruling of the
Architect on 2026-10-03 (#428).** Hinting snaps each letter to the pixel grid at small sizes, so
small text stays sharp on a screen of low density. The unhinted build of the same release holds the
same characters, and lacks the tables `cvt`, `fpgm`, `prep` and `gasp`. It also lacks the
instruction program in each glyph. So it is about 32 percent smaller: Noto Sans Regular is 610,392
bytes hinted and 418,820 unhinted. Rejected: the unhinted build of these five font faces, which
would save about 1.5 MB on each page.

Compared by hand on 2026-10-09, for Noto Sans Regular. fontconfig 2.15.0 reads the same charset from
both builds. Their tables differ in those four, in `glyf`, `head`, `loca` and `maxp`, and in the
version string of `name`.

Noto Sans Math ships its unhinted build, the file that the store declares, and the ruling keeps the
files of the store. From the Noto release 2.539, its hinted build is 966,008 bytes and its unhinted
build 646,728, fetched 2026-10-08.

Eight font faces are fetched by the `assets` verb of `tools/build.nim` into `build/fonts`, and never
committed. Each one is pinned by package or release version *and* SHA-256. The version is pinned
because an unversioned path serves whatever the host resolves that day. The digest is pinned
because the bytes are embedded in what readers open.

`design/font_faces.nim` inlines them as data URIs, and `pages` dresses every page it wrote, once,
after every writer has run. To do it there rather than in each writer is what keeps the suites free
of the network. That is **verified**: every suite passes with `build/` deleted outright.

The two font faces of Commit Mono come from `@fontsource` 5.3.0, by way of `cdn.jsdelivr.net`. The
six Noto font faces come whole from the releases of the Noto project, by the same host. They are
2.013 for Noto Sans and Noto Serif, and 2.539 for Noto Sans Math. All are under the
**SIL Open Font License 1.1**. For Commit Mono that is confirmed from the `LICENSE` of its package,
rather than assumed. For each Noto font face it is confirmed from the licence in its own `name`
table.

Their addresses and checksums are the `ASSETS` table in `curator/audit/src/assets.nim`, the shared
store (issue 116). `assets` names the eight files it wants, and `koch fetch-assets` gives their
paths. One store stops two projects from pinning one font face twice (Article II.9).

**The digest is the curator's, and the choice is this project's.** The store never says which
font faces a page draws with, so each project keeps its own choice.

The store keys entries by digest, so a font face arrives under a name that is its hash. `assets`
restores the file name on the way into `build/fonts`, because everything downstream reads font faces
by name.

Verified 2026-10-03. All eight arrive, and each one carries the digest that the store declares. To
ask for a font face that the store does not declare fails with a finding that names it, which is
checked rather than assumed.

That check also lives in a suite. A suite reads no network, so it fails on a checkout before
`drive` asks the store.

`test_font_faces.nim` reads the declaration of the store as text, and holds every font face named
here against it. It reads it as text rather than by import. The law then depends on the declaration,
and not on the module of the curator keeping its present shape. It also means that this project
imports no curator source, which none does.

Cost, measured 2026-10-03 on this container: the font face block is **5,655,720 bytes on each
page**, where the Latin subsets made it 535,702. The eight files are 4,240,892 bytes, and the six
whole Noto font faces are 4,145,460 of them. So each page grows by 5,120,018 bytes. Built from
`e1dfe66` on 2026-10-09, the bundled Explorer is 6,014,331 bytes, and the Reference is 15,904,530.

Rejected: to link the copy of the host, which names a font face the reader may lack, and needs the
network at reading time. Rejected: to subset for each page, which trades one shared block for one
on each page, which drift apart.

Commit Mono keeps its ligatures in `calt` rather than `liga`. That is **measured**, on both weights,
over 1932 glyphs in the latin subset. `calt` is on by default only until something sets
`font-variant-ligatures`. So the emitted style sheet sets `contextual` at root, and no later reset
can lose them.

**A shipped label font face makes a card one picture on every machine.** A label in the reader's own
sans draws a card differently on each machine, and X.8 forbids that. Verified by hand in
Chromium 1194, 2026-09-10: none of 97 measured labels sits outside its viewBox.

## Drive

**`koch drive` proves the font faces of every page, as `CONTRIBUTOR.md`, Pages and assets, asks.**
It writes a control page to `build/font-faces/control.html`, then runs `drive`. `drive` builds every
page, and renders each one in Chromium as the publish host serves it. One collector reads each page
and the control page. It writes `build/font-faces/written.json`, in the shape that
`curator/audit/src/font_stacks.nim` gives, and names the control page `control`. Then `koch drive`
resolves that file, writes `found.json` beside it, and reports each finding.

A character beyond ASCII that a font face of the system draws on a page is a finding. The finding
names the page, the element and the codepoint. A font face that the browser does not load is a
finding too. So is a numeral of the control page that the collector does not read.

The harness is TypeScript under `tools/drive/`. TypeScript is admitted for the host API of a test
driver. It checks each expression that runs inside the page against the types of the DOM. The
harness resolves nothing and judges nothing. `koch drive` reads the `cmap` of each font face,
matches each weight and walks each font stack, once for every project.

**No copy of the check stands here, and this project names no other project (Architect, issue 670,
2026-10-21).** The curator holds the one check of font faces in `koch drive`, for every project
(issue 671). This project keeps its collector, its pages and its choice of font faces.

Rejected: a harness in Nim compiled to JavaScript, as `shot` is, where each of those expressions is
an unchecked string.

**The control page is the curator's, and it proves the collector on each run.** It holds the Chinese
numerals one to five, each in one kind of place where text stands. Those places are a paragraph, the
placeholder of a field, a `::before`, SVG text, and text that a script writes on load. No font face
of the store maps any of them. So each numeral that the collector reads is in `found.json`, and a
numeral that is missing names the place that the collector skips.

`drive` reads the control page as `koch drive` writes it, outside the skeleton of the host. The page
declares its own charset, and the skeleton adds no place where text stands. Where no control page
stands, as when `drive` runs alone on a fresh build, `written.json` holds the pages alone, and
`drive` says so. Verified by a run of `nim r tools/build.nim drive` alone on 2026-10-23.

**Each rule names a file that holds the bytes of its font face.** The resolver of `koch drive` reads
the `cmap` out of a file, and each font face is inlined as a `data:` source. So the collector writes
the bytes of each source once into `build/font-faces/files/`, named by their SHA-256. Then
`koch drive` reads the bytes that a viewer receives, from the page itself and not from the store.

**Each page is rendered inside the document skeleton that the publish host wraps it in.** So the
charset and the viewport are the ones that a viewer gets. `SKELETON_HOST` was read off the
Reference, version 11, on 2026-10-05. It is the host's own, so it can change. The style sheet of the
host is left out, because its body stack leads with font families of the system, which X.8 forbids
here.

No check is lost by that. An element that inherits no stack from its page takes the default of the
browser. That default is a font family of the system too, so `koch drive` finds it either way.

Verified by `suites/test_render.nim`, which holds each page inside the skeleton of the host, and the
skeleton to no font family. Verified by `nim r koch drive contributor/sincopa/dance_ontology` on
2026-10-23, in Chromium 153 (revision 1243) under Playwright 1.63.0. It gave no finding. No page
that `pages` wrote draws a character from a font face of the system, and every font face loaded.
Each of the five numerals of the control page was in `found.json`, at the element that holds it.

Two breaks, each made by hand on 2026-10-23 and then reverted, show that the check sees. With the
read of `placeholder` taken out of the collector, `koch drive` fails, and names `U+4E8C` in the
placeholder of a field. With the two font faces of Commit Mono taken out of `FONT_FACES`, it fails
with ten findings. Each one names the page, the element and the codepoint, as `button#next` of
`design-rig` draws `U+2192`.

Cost: a page is read at one viewport, in the state it opens on. Text that a script writes only after
the reader acts, as the Explorer writes the moves of a frame, is not read. The `⇄` that the Explorer
writes is such text, and Noto Sans Math alone maps it. So `koch drive` passes with Noto Sans Math
taken out of `FONT_FACES`, and the static check of coverage reports that `⇄` instead. Both were
measured by hand on 2026-10-23.

Cost: the time that `drive` takes over the kept pages is unmeasured.

**`package-lock.json` pins the node tools, and git ignores their checkout.** The project commits
`package.json` and `package-lock.json`, which pin these versions. `typescript` 7.0.2 type-checks the
harness, and `@playwright/test` 1.63.0 drives Chromium. Both are Microsoft's, under Apache-2.0.
`@types/node` 22.20.2 is DefinitelyTyped's, under MIT, and types the node surface that the harness
reaches. The `license` field of each entry in `package-lock.json` gives these licences, and the
licences of what they bring.

**Chromium is the one that Playwright pins, unless `DANCE_CHROMIUM` names one.** `package-lock.json`
pins `@playwright/test`, and that version pins the revision of the browser. `drive` fetches it with
`npx playwright install chromium`. Playwright publishes no checksum, so the bytes arrive on TLS
alone. The run above used revision 1243, which Playwright 1.63.0 pins, with no `DANCE_CHROMIUM` set.

**`types` compiles this driver, and the project code that it imports, on the compiler of koch.**
That holds while the pin of this project is the pin of koch, 2.2.12 for both. A pin that moves first
splits the driver.

## Mirror twins

**Two mirror twins are one question, and the simulation answers it once.** Two frame holds are
mirror twins where each is the other seen in a mirror: each hand on the other arm, at opposite
turns. Of two mirror twins, the simulation answers the one whose first connection is on the left arm
of the lead. It reflects that answer for the other, the reflected twin (`walk.twinAnswering`). Of a
frame hold that is its own mirror, it answers the way that turns positive, and reflects it for the
other way.

The Architect chose this on 2026-10-04, so that a recording walks one twin of each pair. The rig
suite asks one reflected twin raw, R-r held low, so that a law holds the engine to its mirror
(below).

A real couple holds on its left side as it holds on its right. So a hold that is proven for one
mirror twin holds for the other, as the Architect ruled on 2026-10-04. Where the engine stands a
reflected twin raw with other figures, the difference comes from the engine, and not from the
couple.

A frame hold that rests face to back has no twin. Its rest turns the follow half a turn one way
(`rigid.restStance`). So the mirror image of that rest is the rest turned the other way, which is
another rest. The same-name chain at minus half a turn unwinds to face to face. At plus half a turn,
it winds a whole turn. So the simulation answers each way of such a frame hold on its own.

Rejected: a twin for a frame hold that rests face to back too. The same-name chain at minus half a
turn then takes the answer of the plus half, reflected, which held from no distance on 2026-10-09.
That is unmeasured since the edge of the shoulder. Asked on its own, it holds 0.66 m apart
(`simulation/answers.json`, 2026-10-11).

The simulation reflects each answer that a law or the report reads: a sweep, a walk, and the search
of a still (`walk.twinAnswering`). The reflection flips every point across the line of the couple.
Each arm takes the points of the other arm, and each twist turns the other way. That is because the
rig states the ends of the left arm mirrored. The simulation reflects a facing about the way that
its body faces at rest, so a wound turn keeps its laps.

**The rig viewer shows each reflected twin as the still that its mirror twin keeps, mirrored, and
each arm recoloured.** The rig recording keeps each answered still once. A twin card keeps no still
of its own. It names the card that keeps the still that it mirrors (`mirror`). Where no card asks
that answer, the twin card keeps it itself, and names itself. A02, A04 and A06 do so, counted
2026-10-04.

The page builder flips each point of that still across the line of the couple (`design/twins`). It
names the capsules of each arm as those of the other arm, so the page paints them in the colour of
the other arm. The readings of each arm move to the place of the other arm, and the twist and its
two ends turn the other way. The two capsules of each torso trade places, so the left one stays
first (`rigid.trunkCapsules`). The Architect chose this on 2026-10-04. Rejected: a still reflected
by the simulation and kept in the recording, which kept 41 stills that a mirror gives.

Verified on 2026-10-04 by a probe outside the tree, against the recording of `6cfc7bc1`. Each of the
41 twin cards shows the still that the simulation reflected there, field for field. Only the order
of the capsules, of the joined hands and of the strains tried differs. Verified by
`suites/test_asks.nim`: each twin card names the card that keeps its answer, and the mirror undoes
itself. Each girdle stands on the side that its arm names, in every still that the page shows. Each
of those laws failed on a break made on purpose: arms not recoloured, points not flipped, and a twin
card that named another card.

Without the trade of the torso, the right of each chest on a twin card points to its left. A law
that reads the face from the chest then finds it behind the head. Verified by
`suites/test_asks.nim`: each still that the page shows lists the left capsule of its torso first.

The engine is not mirror exact, so a reflected twin shows other figures than the engine gives it.
These are the largest differences between the recordings of `9bbf656`, which reflect nothing, and
those of `6cfc7bc1`, which reflect each twin, compared 2026-10-04:

- Held above, L-r.R-l stops at minus 1.06 turns in `9bbf656`, and at minus 1.34 in `6cfc7bc1`, as at
  plus 1.34.
- Held high, at plus one turn, R-r shows the arm of the follow in a lock in `9bbf656`, and in a wrap
  in `6cfc7bc1`.
- Held above, at plus one turn, R-l and R-r strain 0.63 and 0.70 in `9bbf656`, and to the end of a
  joint in `6cfc7bc1`.
- In the rig, the still `st_fo_3_1` stands 0.60 m apart in `9bbf656`, and 0.36 m apart in
  `6cfc7bc1`.

Other differences are smaller. In the sweeps of `9bbf656`, shake held low reaches 1.36 turns one
way, and left to right reaches 1.34 turns the other way. In `design/rig.json` there, C05 stands at
ease, where C03 has a strain of 0.0019.

In every recording, a reflected twin takes its poses, distances and stops from its mirror twin,
reflected, unless a law asks it raw. But `simulation/verdicts.json` and `simulation/verdicts.md`
hold its strain as read again from its own pose (`tightest`). That reader holds both arms to the
same ranges (Stance and strain), so a twin reads the strain of its mirror twin. In
`simulation/verdicts.md`, the one exception is the rest of L-l and R-r high, at 0.09 and 0.12. Its
couples stand 398 and 358 mm apart, so it is no mirror image. Measured 2026-10-10 on the recording
of `8556fcc0`, and read 2026-10-20 in the report.

Of the 95 stills of the rig, 41 are reflected twins, and 11 rest face to back, counted by
`walk.twinAnswering` on 2026-10-04.

Verified on 2026-10-04 against the recordings of `9bbf656`: every answer that the simulation
computes is the same, to the last bit. Those are 54 stills of the rig, all 231 modelled badges, and
every way of a sweep that it walks. C06 and C07 are the same there too, because the engine stood C01
and C02 mirror exact.

The rig suite asks R-r held low raw, so its search and its walks are those of the engine
(`answers.SWEEPS`). So `test_rigid.nim` holds the engine to its mirror: each way of R-r stands
within one step of the search grid of L-l. It reaches the turn of L-l within one step, and it stops
for the same reason.

A second law holds the kept sweep of shake, a reflected twin, to that of its mirror twin, ways
swapped, to the last bit. That twin is left to right as far as shake. Swept raw, shake gives the
kept sweep of that twin too, ways swapped, to the last bit, measured 2026-10-09. So the law passes
even where the simulation reflects no twin.

Every law that stands a kept still stands each reflected twin as the twin that it reflects
(`standLive`), which is what the simulation answers. With each reflected twin stood raw, every law
of the rig suite passed too on 2026-10-09, before the edge of the shoulder. On this physics one twin
stood raw does not hold (below), so a law that stood it raw would fail.

Cross-name at minus half a turn, stood raw at its kept 0.40 m, holds at ease, and so does its twin.
Right to left at half, either way, stood raw at its kept 0.38 m and wound minus half a turn, does
not hold. It strains 1.54. Stood as its twin there, it holds at ease. Measured 2026-10-11 by a
probe outside the tree.

In the recordings of `9bbf656`, its own search stood right to left at half, either way, 0.40 m
apart.

## Kept answers

**The rig suite reads where the couple stand, and searches for nothing.** Each sweep, still and
`reaches` that a law asks is a search over every distance the couple may stand at. Its answer
changes only when the simulation changes. So the recorder answers each search once, as a job of its
queue (`design/record.nim`), and writes `simulation/answers.json`. `nim r tools/build.nim answers`
runs it. The questions live in `simulation/answers.nim`, so what is asked and what is answered are
one list.

**Every pose and walk that a law holds is still made live.** Only where to stand is kept. A law
walks or stands the couple at the kept distance, with the code of the tree, and checks what the
simulation does there. `walked` builds its own world, so it walks exactly what the search walked
from that distance.

**The kept answers are held to the tree in two ways.** The stamp is a digest of every
`simulation/*.nim` and of the pinned commit of the engine. A law fails when the answers carry
another stamp, so a simulation that changed and was not answered again cannot pass. And a law walks
every kept sweep and two drawn walks again, live, and asks for the same numbers. Verified by
`test_rigid.nim`, suite "Internal: Answers".

Each of those three laws failed on a break made on purpose. The breaks were a comment added to
`simulation/vector.nim`, a distance moved off the grid by 1 mm, and a kept turn changed by one step.

**The laws that read answers fail when the answers are wrong.** Five breaks were made on purpose,
and each failed the law that reads it. A chosen turn was cut to 0.10, and a `reaches` was flipped.
A still was marked as not holding, a mirror distance was moved by 4 cm, and an answer was deleted.
Verified by `test_rigid.nim`, on 2026-09-24.

**The version of Nim is not stamped.** The verbs of `tools/build.nim` run the `nim` on the path,
and the suite runs the one that koch pins. A stamp with the version would agree on no machine
where the two differ. Answers from Nim 2.2.4 walked the same under 2.2.12, number for number, on
2026-09-24.

**The live walks run on every core at once.** They are the fourteen ways of seven sweeps and two
drawn walks. The suite walks each way of a raw sweep raw, as its search walked it. Each worker reads
the holds as constants and gives back numbers alone (`Went`). A list of strings and sequences read
by four threads is what `design/record.nim` records dying of.

When they were the twelve ways of six sweeps, every line the suite printed was the same as when they
ran one after another. That took 38.7 s, where every core at once took 28.6 s, on 2026-09-24.

Cost: a change to any `simulation/*.nim`, words included, asks for the answers again. The full
recording asks them with every other kept file, and took 24 min 8 s on 2026-10-20 (Figures).
A digest of every file is one rule. A list of the files that move the answers would be a second
thing to keep true.

A change to comments alone gives the same answers and a new stamp. Two comments in
`simulation/verdicts.nim` and `simulation/words.nim` changed, and every answer came back the same
number. Of the last 40 commits to `simulation/*.nim` on 2026-09-24, two changed comments alone. So a
stamp that skips comments would rarely save a run.

**The report keeps its readings, and renders its words from them.** `simulation/readings.nim` reads
each sweep and each rung that the report asks for into plain numbers. It keeps them in
`simulation/verdicts.json`, with a stamp of the physics. The stamp leaves out the files that only
say words or ask the questions of the laws (`LEAVING`). The report renders its words from the
readings, and it asks for a reading by rendering. So the list of what it asks is written once.

A change to words alone renders the report again in 2.8 s to 3.9 s, compile included, on four cores
on 2026-10-08.
After a change to the physics, the recorder takes a new reading of each sweep and rung that the
report lacks. Each one is a job (`design/record.nim`). Each job gives its reading as text, and the
report reads each text back to the reading that it was written from.

Verified by `suites/test_words.nim`: the report is what its kept readings render. The law failed on
three breaks made on purpose. One changed a word of the renderer, one deleted a reading, and one
changed a number that the report prints. The law does not read the stamp, so readings of older
physics still render the report they gave.

**The stamp of the kept readings is read before their fields.** A rename in `simulation/` changes
the names of the fields and the stamp. So a kept file of other physics can have other fields.
`keptReadings` reads the stamp from the parsed file, and it converts only a file of this physics. A
file with another stamp gives no readings, whatever its fields, and `verdicts` reads each reading
again. A file with this stamp and other fields still stops the verb, because its stamp says that it
is current.

Rejected: a conversion that allows missing and extra fields. It would also accept a broken file of
this stamp, with zeros for the readings that it lacks.

Verified by `suites/test_words.nim`, suite "Internal: Kept readings of other physics are read
again". Its law of other fields fails with `ValueError` where the file is converted before the
stamp is read.

**The recordings that pages read are kept with a stamp too.** `design/modelled.json` and
`design/rig.json` each carry one (`design/stamps.nim`). Each stamp is a digest of the physics of the
readings of the report, and of the source of its module, `design/rig.nim` or `design/modelled.nim`.
A verb whose stamp is the same records nothing again.

From no recording, the time of each verb alone is unmeasured. With the stamp the same, each verb
took 0.25 s to 0.33 s on four cores on 2026-10-08. Where it compiled first, each took 2.8 s to
3.9 s. All of them from one queue took 24 min 8 s on 2026-10-20 (Figures).

Each question that the verb asks goes into the stamp as text, and not the source of
`design/asks.nim`. So a change to how the questions are listed that asks the same questions records
nothing again. The rig viewer leaves the stamp out, so the page changes only where the recording
does.

A law fails when a recording carries a stamp other than the one that the tree gives. Without it, a
page could show the answers of other physics as those of this tree. Verified by
`suites/test_asks.nim`. Each law failed on a stamp changed in its file, a comment in
`simulation/vector.nim`, and a comment in its module, `design/rig.nim` or `design/modelled.nim`.
Both failed when one question was asked over another crown, and the law of the page failed when the
page kept the stamp. A comment in `simulation/words.nim` failed none of the three.

**The recordings come from one queue, slowest job first, and a stopped run goes on where it stopped
(#447).** `design/record.nim` puts every job of these recordings in one queue:

- the stills and sweeps of the rig viewer
- the modelled badges of the Reference
- the answers of the rig suite
- the readings of the report.

Each worker takes the next job as it ends one. The jobs measured slowest start first (`SLOWEST`), so
the four workers end near the same time. Each result is kept under the stamp of its recording as it
comes, in `build/record/`. A run that stops then asks only the jobs with no result. Each kept file
is assembled in the order of its recording.

Rejected: each verb splits its own jobs by worker. Two slow jobs can then fall to one worker, while
the others stand idle. On 2026-10-03, the time of each job gave that split 8.7 h, where one queue
took 6.3 h.

The order is measured, and it goes stale as the simulation changes. A wrong order costs time, and
never changes an answer. A file renamed into place leaves no result where a worker stops mid-write.
That is intended, because no law stops a worker mid-write.

Verified by `suites/test_record.nim`, on stub jobs. A run in two parts asks each job once, and keeps
the bytes of a run in one. The slowest jobs go first, in their order. Each law failed on a break
made on purpose.

Every kept file is the same bytes from run to run, and with either width of batch, apart from its
stamp. Verified 2026-10-04 by three full runs from no kept file.

**One run asks each question once, and every job that asks it again takes the answer.** The jobs of
the recordings ask the same questions. Rig and modelled stand the same stills, field for field. The
report walks 18 sweeps, six frame holds at three levels. The rig viewer sweeps 8 of those, and takes
each walk that the report asks. D01 and D07 plan the same 32 paths.

So one run keeps each answer by every argument of its question, for every thread
(`walk.keepAnswers`). These are the answers that it keeps:

- each path planned
- each sweep, and each walk from one distance
- each search of distances for a still, and each still itself (`seen.still`)
- each answer of whether a turn is reached
- each answer of whether a planned still holds, or a planned turn reaches.

A job that asks what another job is answering waits for it (`Store`).

Each routine answers from its arguments alone, so the answer kept is the answer that the routine
gives again, to the last bit. A float in a key is its bits, so nought and minus nought are two keys.
The recorder keeps answers. Every law asks afresh, so no law reads an answer that another law made.

**A walk to a lesser turn is the first part of a walk to a greater one.** `walkedRaw` turns one step
at a time from one distance, and `most` only ends its loop. So a walk kept to 2.5 turns gives a walk
to any lesser turn, cut where that walk would end (`cut`). A walk that stopped gives every walk from
that distance. The sweeps of the report and of the rig viewer walk each distance that they try, to
2.5 turns. A question of whether a turn is reached, and the walks of the kept answers, then ask each
distance again, to their own turn.

Verified on 2026-10-04: 36 of 36 walks cut short were the walk asked afresh, at three distances,
both ways and six turns.

**A planned card plans its paths on every core, and folds them in its own order.** `walk.planAhead`
plans every path that the card may try, on every core, before the card tries them. The card then
folds them as one thread would, so the earlier of two equal plans is kept. Each thread passes over a
path that another thread is planning, and the fold waits for it. Rig D01 and D07 ask the same 32
paths, so the threads of both plan them together.

**A search walks its distances on the cores that no job holds.** A search of distances walks the
next distance only when the last one did not give its answer. It walks a batch of distances at once,
each on its own thread (`walk.onEveryCore`), and takes their answers in their order. So its answer
is the answer of one thread, to the last bit. A batch is one distance, and one more for each worker
that found the queue empty (`walk.SPARE`). The searches that do this are these:

- `walk.furthest`, the walk of a sweep from where it carries furthest
- `walk.standingSearched`, the search of distances for a still
- `walk.isReachingSearched`, whether a turn is reached
- `readings.readRung`, the rungs of the report.

While every worker has a job, no core walks a distance past the answer. As the queue empties, the
last jobs take the cores that the other workers leave.

Cost: growing batches made a recording 31 s slower here, 4%, in one run of each from no kept file
on 2026-10-04. Growing batches took 14 min 26 s and 3,224 s of the four cores, at 93% busy. Batches
as wide as the machine took 13 min 55 s and 3,298 s, at 99% busy. A worker that waits on the answer
of another job leaves its core idle, and no batch counts that core.

Rejected: a batch as wide as the machine, for its 74 s more of the four cores. While every worker
has a job, it walks distances past an answer, and growing batches do not. It also runs the square
of the cores in walks at once, as `walk.planAhead` does in both designs. What that costs is
unmeasured. The Architect chose growing batches on 2026-10-04.

**The replay is exact on the runner too.** Its law passed there on `5975d93`, on 2026-09-24, so the
runner walks every kept sweep and both drawn walks to the numbers this container kept.

## Tests

**Testament over `tests/t*.nim` from the project directory, with one binary for each.**
`test_engine.nim`, `test_plan.nim`, `test_read.nim` and `test_rigid.nim` link the C archive of the
engine. `test_said.nim` compiles to JavaScript. `test_suites.nim` imports every other suite from
`tests/suites/`, and each of them runs at import under its own suite name. `test_suites.nim` links
the C archive of the engine too, through `simulation/rigid.nim`, and calls nothing in it.
`test_plan.nim`, `test_rigid.nim` and `test_read.nim` add `-d:danger`, because the sweeps are the
slow part and `doAssert` survives it.

**`test_read.nim` settles its thirty couples on every core at once.** Each worker builds and settles
its own couple, and gives back the arm poses alone. The laws read them on one thread. Its run took
8.1 s with the couples settled one after another, and takes 2.3 s, on four cores on 2026-09-26. It
prints the same lines. It failed on three breaks made on purpose: the reader of the arm over turned
round, one connection given back twice, and no couple settled.

**The suites that drive no engine and no browser compile once.** Each binary compiled the standard
library and its own imports again. Sixteen of them compiled for 31.4 s and ran for 0.8 s, and all
nineteen took 62.4 s under testament.

Joined, and with the pages built once, they take 18.5 s cold. That is 11.1 s of compile and 7.4 s of
running, and 7.1 s of the running is the page suite. Measured on 2026-09-24, on four cores of a
Linux amd64 container, with Nim 2.2.12.

**It builds in debug, because compile is most of a cold run.** The runner keeps no cache, so each
run compiles cold. Cold, on four cores on 2026-09-24, the debug build took 14.1 s to 16.4 s. A
`-d:release` build took 20.8 s, of which 19.1 s was compile. A release build keeps `doAssert`,
`assert`, bounds and overflow checks too, so the choice is about time alone.

`test_asks` and `test_limb` do not take `-d:danger`, so they keep bounds, overflow and `assert`
checks.

Not taken: to turn stack traces off. That took 11.2 s to 11.8 s cold, and it keeps every check. But
a test that fails on an exception it did not expect then prints no trace of where it came from.

**Every failure shows in one run.** `test_suites.nim` leaves out `-d:nimUnittestAbortOnError:on`, as
STYLE.md §6 asks, so a failing check does not stop the suites after it.

Cost: a suite under `tests/suites/` is not run alone by testament. It runs as part of
`test_suites.nim`, or alone by name as an argument to that binary.

**Computed floats compare through `=~` (Article IV.5).** `tests/fixtures.nim` defines it as
STYLE.md §4 does: a relative tolerance with an absolute floor. `-d:dance_ontology.tolerance_places`
sets the count of places, and the default is 9. The name of the file does not open with `t`, so
testament does not run it. Verified by a run of `test_suites.nim` at 16 places, under the precision
of a double, where the lengths of the arm in `suites/test_limb.nim` fail. At 15 places, and at 9,
every suite passes.

A bound with a physical margin, such as 0.05 m, ten degrees or 1 mm of a measured girth, stays a
bound. It is a law of its own, and not an equality. A value that a clamp, an empty sum or a stored
literal gives exactly keeps `==`.

**The suites of the simulation open with `Internal:` too (Article IX.10).** The standards of the
body give values to `simulation/rig.nim`, and no suite mirrors a chapter of them. The suites of
`suites/test_workbook.nim` mirror the base sheet, which is an authority, and keep its names.

`suites/test_marks.nim` holds each page of the workbench in a law of its own, named by the page. A
law there reads those names off the file and holds them to `PAGES`, so a new page cannot go
unbuilt. It failed when the law of one page was taken out.

Test binaries inherit the working directory of testament. So `build/suites/design`, where
`test_marks` writes, resolves only from the project directory. The runner of koch runs testament
there, and to run it from the repository root breaks it.

Cost: a model change that leaves a sweep with no moments crashes a danger build, rather than
reddens a law.

## Figures

- `test_rigid.nim`, danger build, on 2026-09-24, in one session on four cores. Its run took 385.1 s
  with every search, and takes 28.6 s reading kept answers. Under `nim r koch check` it took 40.76
  s, compile included.
- `test_rigid.nim` on the runner, under testament, compile included: 43.71 s on `5975d93`, against
  503.91 s and 504.66 s with every search. The project job took 2 min 29 s in all.
- The whole of `nim r koch check`, with the kept answers, the joined suites and
  `tests/test_plan.nim`: 102 s and 86 s. Those are two runs on four cores, on 2026-10-03.
- `tools/build.nim record`, every recording from one queue, with no result kept, on four cores of a
  2.8 GHz Xeon, compile included. On 2026-10-20 it took 24 min 8 s, and 90 min 9 s of user time.
  It asked all 534 jobs, and each kept file came out byte for byte as committed.
- `design/record`, rig and modelled alone, with each still planned by the plain cost: 6.3 h on
  four cores on 2026-10-03 (Kept answers).
- `tools/build.nim verdicts`, with its readings kept: 2.8 s to 3.9 s after a change to words,
  compile included, on four cores on 2026-10-08.
- `tools/build.nim pages`, with font faces from the shared store: 15.2 s wall on four cores of a
  2.8 GHz Xeon, 2026-10-18. It wrote the Explorer, the Reference and the rig viewer. Each tool had
  been built on that tree before, and a build from a cold cache is unmeasured.
- `tools/build.nim engine`: 32 s cold, and 0.2 s where the archive stands, on four cores of a
  2.8 GHz Xeon, 2026-10-10.

## Rules deferred

Declared unmet, so the Style row above stays true (Article VIII.1):

- VI.1: some declarations in `simulation/verdicts.nim` carry no doc. Cost: a reader opens the body.
- X.2: many routines of several lines stand one blank line apart, where X.2 asks two. No check
  counts those blank lines.
- IV.5: `==` is not poisoned on floats. The floats of this project are plain `float`, and a
  distinct type for each measure reaches every module of the simulation and the drawing. The tests
  compare computed floats through `=~`. Cost: a routine of the library can compare two computed
  floats exactly, and no check stops it.
- VII.1: no reading of emitted code exists. The binding shapes of the Explorer and the viewer are
  unread. Cost: a copy in a hot path may hide there.

## Form of the source

**The source follows the charter of #257, rule by rule, but for the sites below.** Every global is
in SCREAMING_SNAKE_CASE, and each mutable one says why it is global. Every conversion is a prefix
call. A routine has a doc, or stands in a stack under one group comment (VI.1). A one-line template
that aliases storage says so in a comment instead. A module declares its types in one section,
before its routines.

Three nested routines have no doc: `asked` twice in `simulation/walk.nim`, and `page` in
`tests/suites/test_asks.nim`. These modules declare a type after a routine: `simulation/plan.nim`,
`simulation/walk.nim`, `simulation/rigid.nim`, `simulation/readings.nim` and `tests/test_rigid.nim`.
All but `tests/test_rigid.nim` declare types in several sections. Verified by the audit of #302, and
by a scan of every global, conversion, routine and type section on 2026-10-09.

**A name spells its words out, but for a few that wait.** The Architect ruled so on #305, past the
closed list of V.6. `Vector`, `Position` and `Quaternion` are in full, and so is each name of the
engine binding. The C name stays in its pragma, as in `vector* {.importc: "v".}`. A name that joins
one-letter symbols is spelled out, as `delta_x` for `dx`. The names that wait are `cond`, a field
of `walk.Store`, and `cu`, `su`, `cf` and `sf`, which join symbols in `rigid.poseVector`.

The planner spells out its names too, as `handedness` and `cost_x`. The search names each product
of its two loops, as `curvature_pair` and `projection_step`. An acronym stays only where a glossary
lists it (V.9).
The glossary of this project lists `Dof` as a term, and `svg`, `html`, `css` and `js` as standards.

**A path is a name too.** The simulation is in `simulation/`, and the build folders are
`dependencies/` and `binaries/`. The root ignore file ignores both, so this project has no ignore
file of its own. Verified by `git check-ignore` in git 2.43.0, 2026-09-29. Each test file is
`test_<name>.nim`. That is a full word, and it still matches the `tests/t*.nim` that the runner and
the root ignore file read.

**A one-letter name follows V.6.** A field, an enum value, a parameter and a local that stand for a
word take the word. A symbol of a formula and the index of a short loop stay, such as `a`, `b`, `t`
and `i`. `Arm.Left` and `Arm.Right` keep the letters `L` and `R` as their text, because markup
builds keys from them.

The Architect ruled on the case of a lookup table too. At module level it is in
SCREAMING_SNAKE_CASE, as V.1 says, and not in the lower case of the form in V.5. The example in
STYLE §3 is in SCREAMING_SNAKE_CASE too (`LUT_GRADE_BY_BASIS`).

**A global named after its own type is that type, in Nim.** Nim compares two names by the first
letter exactly, and by the rest with no case and no underscore. So `DRAWING` is `Drawing`, and each
such global takes a qualifier, such as `DRAWING_SHOWN`. The compiler says so as a redefinition.

**Each local, parameter and field is in snake_case, and each boolean says what it is.** The
Architect ruled so on #308, by V.1 and V.4. A boolean value takes `is_`, `as_`, `should_`, `found_`
or `has_`. A function that answers yes or no takes `is...`, as the names check of #371 reads V.4.
So `isOverlapping` says whether two forearms lie on each other. A `proc` that answers reports an
action, so `hasRoomForMap` keeps its name.

One concept keeps one name in each module, such as `is_away`, `is_holding`, `is_stopped` and
`found_rest`.

**A predicate never takes the word of a value that it meets.** Nim reads `is_away` and `isAway` as
one name, as it reads `DRAWING` and `Drawing`. So the routine that says whether a rest is
Face-to-back is `isRestAway`, and the field is `is_away`. `isPressingBody` and `isLeavingCrown`
follow the same rule.

**A name that another program reads stays as that program spells it.** Playwright reads
`colorScheme`, `fullPage` and `executablePath`. Each is a name of that program, and not a name that
this source declares.

**`nimsuggest` misses some uses, so a rename also needs the compiler and a scan of the text.** It
reports a use in a format string at the start of the string. It reports an enum value after its type
one column early. It reads a dynamic field of a browser object as a local of that name, and misses
some fields in constructors. It sees no local inside the `suite` and `test` templates of `unittest`.
A rename of case that keeps the first letter keeps the same name in Nim, so the compiler finds no
missed use.

**A rename in `simulation/` computes every kept file again.** Each stamp is a digest of source text,
so a change of names alone computes the physics again. That is a full recording, which took
24 min 8 s on four cores on 2026-10-20 (Figures).

That is the cost of a stamp that reads text and not the program, and it is accepted. Renames of the
simulation are rare.

A rename alone keeps every kept answer to the last bit, and moves only the stamps and the words.
Verified for the rename of `Stop.Reach` to `Stop.Span`, with jq 1.7 and GNU diff 3.10, on
2026-10-04. There, the rig recording labels its sweeps low and high, and every other figure is the
same. A change of docs alone keeps every kept file to the last bit but its stamp, verified by git
diff on 2026-10-11.

## Toolchain

**The compiler is pinned exactly, at the version this project was verified on.**
`requires "nim == 2.2.12"` in `dance_ontology.nimble`.

**A float `result` gets a value before `+=`.** From Nim 2.2.8, the VM gives an unassigned float
`result` an int register, and then reads `floatVal` from that register. The compiler then stops with
`field 'floatVal' is not accessible for type 'TFullReg' using 'kind = rkInt'`. The crash occurs only
at compile time, and only where the VM reaches the function. That is `polylineLength` in
`draw/route.nim`, through `const SCENES = buildScenes()` in `draw/scene.nim`. So `result = 0.0`
comes first there, with a comment, because the line reads redundant and is not.

Five lines reproduce the crash on 2.2.12 with nothing from this project, verified 2026-09-10 (issue
106). Verified by `suites/test_route.nim`, which takes a run length in a `const`. Without that law,
to tidy the line away shows up only as suites that fail to build. `result +=` on a float survives in
`limb.comfort`, `plan.comfort`, `plan.cramped`, `plan.gripBroken`, `plan.violation` and
`checks.inkLength`, none of which the VM evaluates today. That is latent, and not urgent.

## Open questions

- **A crossing that has just arrived cannot carry its break, and five hundredths of a turn are drawn
  without one.** The third crossing enters through the end of a reach. So from 1.24 to 1.28 turns it
  sits between 0.0 and 4.2 along from that end, which is nearer than half a break. `gapFor` gives up
  rather than cut a gap narrower than the line it hides. Those frames draw two connections crossing
  with nothing saying which is over, against the standing rule that every crossing shows one.
- **Measured**: 5 of the 51 hundredths over the stretch, all of them at the arrival. It is not
  obviously mendable by tuning. A crossing that enters through an endpoint is at the endpoint for
  some interval, whatever the construction.
- There are two choices. One is to let the break eat the end, which detaches the line from its hand.
  The other is to hold the crossing hidden until it can be broken, which means to trim the reach
  further, and that reaches every drawing. Left for the Architect to rule on.
- **The drawing does not yet build the chain the way the Architect describes it.** They danced the
  figure and stated the model. One connection **curls around** the other, and the other **hinges
  straight**. That is a right angle at the joined hands, which opens until the two forearms are in
  line. The drawing still gives every connection a sine swung about the axis of the pair, and takes
  the crossings from wherever two such curves meet.
- The count behaves (Drawing chain). So the question is whether the picture is built from the
  movement, or only agrees with it where checked. Rejected: a hinge-and-curl prototype, which gives
  the right counts but draws an X. Anything that replaces the sine is drawn and looked at first.
- **What the swan is in the body.** The Reference draws the cross-name swans, C01 and C07, at
  `Face-to-back`, and the same-name swans, D01 and D07, at `Face-to-face`. All four hands are above
  in both. The lock that the Architect describes is low. The arm goes down, the shoulder rotates in
  as the hand goes behind the back, and the elbow bends behind to an L.
- The model reaches the four swans by a planned turn, and each one waits for the Architect to hold
  it against their own body.
- The drawing of the Reference itself puts both joins at one point, with the right-over-left
  connection under. The planned D07 holds its two joins 0.23 m apart. The carried walk, with its
  hands at the edge of the band, wraps the arms of the follow round the head instead.
- **The swans are reached, but not at ease.** In the easiest plan that holds, C01 and C07 read 1.00,
  and D01 and D07 0.80, in `design/rig.json` (Planned turn).
- **The swans wrap the connection that the card draws straight.** The card draws the connection over
  at the first crossing as the snake, and the other one straight (`route.straightArm`). Seen from
  above in `design/rig.json`, the connection that C01 draws straight runs 3.11 times its line
  between the shoulders, and the other 1.60. In D01 they run 2.16 and 1.69, and C07 and D07 are
  their mirror images. Measured 2026-10-11 by a probe outside the tree, which reads D01 at 2.12 and
  1.52 on the recording before the edge.
- **The figures of a palm grip are derived, and not measured.** No study measures how far two palms
  tilt or turn against each other (Body rig).
- **A relaxed wrist rests at 16 degrees of extension, and the law of a free couple at rest holds it
  within 10.** Lee and Jung measured the 16 degrees with the arm hanging (2010). The wrist of a free
  hand stays straight until the Architect rules which one holds.
- **The same-name chain wound to face to face holds from few distances.** It holds from 1 of 50
  distances, 0.66 m. At 39 others a joined hand leaves its band, and at 9 the arms of one dancer
  cross above the elbow. At 0.48 m an upper arm lies past the edge. Measured 2026-10-11 by a probe
  outside the tree. Before the edge of the shoulder, it held from 2 of 50, 0.82 and 0.84 m.
- **Every still awaits the confirmation of the Architect against their own body.** They have said
  that many are wrong, and will say what is wrong with each, card by card on the viewer. The badges
  read *unconfirmed* until then.
- **The floor held low and high.** `simulation/verdicts.md` prints each claim of the floor
  there beside the answer of the simulation and what stops it (Against the floor). Where the two
  disagree, the ruling is the Architect's. So is whether a high lock goes a whole turn, and what
  moves in the body when it does.
- **The radius of the girdle, 60 mm, is an estimate and not tape.**
- **The breadth of the hand is not held to the bound of a leap (#605).** In L-r low, the edge of a
  held hand moves 150 mm at most in one moment, at 0.38 of a turn. The join moves 137 there.
  Measured 2026-10-11 by a probe outside the tree. Before the edge of the shoulder, it moved 218 mm
  at 0.58, where the join moved 187, past the bound.
- **Left to left at the waist meets the stops of the floor only in part (#601).** The floor stops
  the follow at half a turn into the wrap and a whole turn into the lock, because further is
  uncomfortable. The simulation stops the wrap way at 0.84 of a turn, where an arm meets an arm. It
  stops the lock way at 0.94, short of the floor, by the wrist of the follow
  (`simulation/verdicts.md`, L-l low). #601 asks that a turn stop where a joint leaves its
  comfortable range, as a published share of that range. The readings of the shoulder in the rig do
  not give those two stops, and #601 holds the measurement.
- **The cross-name chain, asked still, holds at no distance at its low and high cross.** Before the
  edge of the shoulder, both held at a strain of 1.00 (`simulation/verdicts.md`, The chain, asked
  still).
- **The way that reaches is chaotic near the edge.** The negative way of the turn of the lead under
  the same-name chain held above reaches 1.5 turns, and the positive way does not. Its rest is
  wound half a turn, so the two ways are two questions and not mirror images. The answer moves with
  the last bits of the wall. A slope that starts 1e-9 radians past the seam carries +1.0 from
  0.40 m, and +1.5 to 1.48 there. The wall of this tree carries neither, measured 2026-10-11 and
  2026-10-12 by probes outside the tree.
- **A sweep of the rig keeps the moment that it stops at, and two laws read it apart.** That moment
  is where something gave (`seen.shownAsked`). The law of the edge reads it, so a sweep that the
  judge stops at the edge would fail that law (Body rig). None stops so on 2026-10-12. The law of
  the hands over the crown leaves it out (Walk and lift).

  No sweep over the crown keeps such a moment on 2026-10-12. The single holds and the same-name
  chain run free, and the cross-name chain ends on a planned moment that stands (Planned sweep).
  Each of the four sweeps at the lower bands keeps one, and the law of the edge reads it.

  The Architect rules two things. Does a sweep keep the moment of its stop? Does each law read it?
- **A planned way that ends short of all that a sweep asks names no stop.** It ends where its last
  moment stands, with `Stop.None`, and `design/rig` says in its own words that no plan carries the
  turn further. A member of `Stop` for a plan that ends would say only that it ends. A stop read off
  the terms of the plan one solve past its end would say which term gave. But that solve broke
  several terms at once (Planned sweep). The Architect rules which, if either (`walk.plannedWay`).
- **A planned way is kept in a `Walk`, and the glossary says that a walk is carried from one
  distance.** A planned way stands the poses of a plan, each at the distance of the plan. The
  Architect rules whether the glossary widens the term, or a planned way takes a name of its own.
- **The report reads the walk alone over the crown, where the rig keeps the planned turn.** The
  report says that the cross-name chain held above is blocked at a turn and a half, by a hand off
  its band at 1.26. The rig carries it to 1.5275. The report says that the same-name chain held
  above stops at -1.66 and +1.80, and the plan carries it to 2.5 both ways (Planned sweep). Read
  2026-10-20 in `simulation/verdicts.md`. The Architect rules whether the report reads the planned
  turn too.

  If it does, its reading of strain takes the twist off four points of the arm (`read.tightest`). On
  planned poses that twist lies -101 to +76 degrees from the twist of the engine. So the reading
  gives 1.00 where the engine is well inside the ends. Measured 2026-10-12 by a probe outside the
  tree. Right arms differ too, so the swapped ends of the left arm (#610) are not all of it. The
  reading could take the joint frame of the engine, and a ruling picks whether it does.
- **Strain, the rig viewer and the report do not read the edge.** `strainWorst`, `read.tightest`,
  the joint bars of the viewer and `simulation/verdicts.md` read extension, adduction and twist. A
  still can lean on the wall of the edge and read at ease. The reading needs a unit for the edge,
  which has no ease to count in.
- **One stop names a swing past its range and an arm past the edge.** `Stop.Swing` covers both,
  and says that the upper arm swings no further. In L-l low, from the stances that the report tells,
  all three stops by swing are at the edge (Rigid body engine). A stop of its own for the edge would
  add a member to `Stop`, with words in `hold.says` and `words.why`, and waits on a ruling.
  `Stop.Band` is such a member, for a joined hand off its band, and no ruling names it yet (Walk
  and lift).
- **The roll of a hand is free past the human range, and no page shows it (#612).** No range of the
  rig holds the roll of the forearm. In C01 on 2026-10-09, before the edge of the shoulder moved it,
  the left forearm of the follow sat at 167 degrees of supination. Three equal capsules drew that
  hand as one at 13 to 17 degrees of pronation, as #612 measures it. Both are unmeasured since.
- **The neck of the model pinches to a point where it meets the head (#613).** The neck capsule and
  the head capsule meet at one point, at 1.50 m. So a hand can sit 25 mm inside a neck of its own
  girth, and the engine reads no depth. Measured 2026-10-09, in the high cross-name chain.

**Open in the workbench, and on the side of the Architect.** Each one waits on a ruling, and the
workbench draws the current reading meanwhile.

- **Whether the "upper wrap" of rule 8 is the high wrap.** It is the one reading in the ledger that
  is not the words of a rule.
- **How far round the rim `SLOT_OFFSET` sets front and back from a side.** It is a drawn convention,
  and not something the dance says.
- **Whether an arm carried past some limit is marked at all.** Nothing on the rim counts, and the
  amount is where the hand sits.
- **The bow for contact with the body, what an orbit stores, and when an arm above the head
  blocks.**
- **How the crossing of a wrap with its dancer's other arm is drawn (rule 38).** Rule 22 keeps a
  settled reach away from that hand. So to draw it needs the other arm in the picture, and a ruling
  on how far rule 22 reaches. Until then a low wrap and a high one differ only by their fill.
- **Whether the model holds a modifier for each arm (rule 39).** The sheet gives either dancer up to
  one modified arm. The drawing holds one level and one modifier for each connection, and settles
  only the follow. That waits on whether the list in the sheet is the shape wanted. It is the same
  question as whether the variants of `Left to left` and `Right to right` that differ in which arm
  is over merge.
