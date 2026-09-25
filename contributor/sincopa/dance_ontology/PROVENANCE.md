# Provenance

| Field   | Value |
|---------|-------|
| Harness | Claude Code |
| Author  | Claude |
| Date    | 2026-09-06 |
| Style   | CONSTITUTION.md and STYLE.md, followed. |
| Rules   | be54792c5171ff9d |
| Pruned  | bba4c7f8fc306df2a89d81ea3e8e42620d235486 |
| Review  | **Unreviewed.** Nothing here has been read line by line by a human. |

Origin: built from three sources.

- The workbook of the Architect, `ontology.partnerwork.xlsx`, sheets `base` and `vocabulary`, held
  as data in `src/dance_ontology/workbook.nim`.
- The forty drawing rules of the Architect as given, held as data in `design/rules.nim`.
- For the body sim, the ANSUR II medians with the AAOS and NASA-STD-3000 joint ranges, in
  `sim/rig.nim`.

There is no vendored source.

That workbook is **superseded**. The Architect has replaced it with a newer sheet that this project
has not been given. Nothing is deleted, so nothing goes dark. But every finding that the audit
reports is about a document no longer in use, and so is the sheet-facing half of the review page.
The transcription, the audit, the suite and the page are replaced together in one delivery when the
new sheet arrives. Until then they are stale by construction, and not by neglect.

## Language

**Every term is agreed with the Architect before it is written.** Each concept is set out with
candidate names and their costs, and only the selected name is written. The audit checks the shape
of the glossary and never its words, so this holds by the reading of the Architect alone.

**The sim is isolated in code, and not in concepts.** It reuses agreed words wherever one fits, and
coins its own only where none does. Four are its own: rig, pose, strain and block. What keeps it a
witness is that it imports nothing from `src/` and is told no answer. It is not that it speaks
another language.

Care is needed only where the sim *measures* what the ontology *asserts*. There the translation
stays visible, in one module that is named for it (`sim/words.nim`), because an assumed identity
would be an echo.

**`wind` is `twist`, and the workbench still says `wind`.** `GLOSSARY.md` has listed `wind` under
the _Avoid_ line of Twist all along. The workbench uses it in about fourteen identifiers for the
quantity that the model calls twist. The Architect confirmed on 2026-09-07 that the two are one.
No page says it in that sense now, and the build's own notes still do. The rename comes after the
frame-position review, so that captions do not move while they are ruled on.

A unit differs where the word does not. The model counts twist in half turns (`HalfTurns`), this
glossary says quarter turns, and the workbench counts turns as a real number. Which of the three the
term means is the second thing that pass settles.

Held back by decision, and not by omission. The workbook, the base sheet and the vocabulary sheet
wait until the new sheet arrives. Nothing should be written about a file that this project has not
seen. The review page waits on the same sheet, and the ledger waits on the reconciliation of the
forty rules.

Sweep, stance, moment, rest, room and verdict are the method of the sim rather than dance, and earn
no entry. Neither does the `(led)` mark of the sim, nor its point where the hands meet, because
`Grip` names the manner of holding instead.

**`Block` describes the code.** The term says that a turn stops "because no small move holds and no
reachable pose does". In the engine a small move is the engine carrying the arms on for one moment,
and what stops it is one named thing. That thing is decided once in `rigid.stoppedBy`, and read by
every sweep, still and page alike (Article II.1). Verified by `trigid.nim`: the turn that a couple
are said to reach is the turn that some distance carries, and every stop carries its name.

**The glossary agrees eight facings, and the model holds four.** The case of a name says which
dancer it places: `Pillion` stands the Lead behind, and `pillion` stands the Follow there. The four
the sim and the drawings hold are Face-to-face, Back-to-back and both cases of Pillion. The four
states of Sidecar are named and not modelled, so nothing draws them and no law reads them.

The agreed words disagree with the code in thirteen places, recorded rather than acted on. From the
hand-to-hand half:

- `frame.position` means the opposite of `Frame position`. It strips `over` and returns the frame
  hold said aloud.
- `Frame` and `rotation.Posture` split across the frame state rather than along it.
- `isFacing` returns the parity of twist, where facing is four-valued.
- Twist is counted in quarters, where `HalfTurns` is half turns.
- `Compound` is `Compound move`.
- The `route` and `wind` of the drawing chain are `Transition` and `Twist`.

From the sim:

- `Band` is `Level`, and its members are Low, High and Above.
- `Body.One` and `.Two` are Lead and Follow.
- `Aspect.Fore` and `.Aft` are Wrap and Lock.
- `Link` is `Connection`, and `page.Hold` is `Frame hold`. Both words already sit on avoid lines.
- `Move`, `Twist`, `Chain` and `Way` each name something in the sim that is unrelated to the agreed
  term of the same spelling.

**The layout block of the review page was stale in five ways, and is corrected.** The curator left
one line for the hand of this project: the domain folder printed as `síncopa` where it is now
`sincopa`. Four more were false beside it. `transition.nim` was said to hold four primitives, where
it holds two. `app/shell.nim` and `tools/review_prose.nim` were named, though an earlier delivery of
this project moved them to `pages/`. The build was invoked as `make`, which is retired.

To go past one line was deliberate. The block named three files that do not exist, two of them
removed by this project, and the Architect reads the page. Its wording still uses `validator` and
`primitives`, where the agreed words are `Reference` and `Move`. That is a vocabulary sweep of the
whole page, and not this fix.

**No recorded sweep names a dancer with a gendered word.** `design/turns.json` keys each arm `lead`
and `follow`, and `sim/verdicts.md` heads its tables the same way. Both files were rewritten by
their own verbs, and the numbers reproduced. The new `turns.json` is the old one with four keys and
two words renamed. Verified by `suites/tglossary.nim`, which now reads `sim` as well as `design` and
`app`.

**One translation table, because two of them drifted.** The report and the page data each held
their own copy, so that the translation stayed visible in both. The copies then disagreed. The
report named an elbow folded forward and the page did not, so one pose carried two answers.
`sim/words.nim` holds the table now, and both read it (Article II.1).

**The report called a rung `X`, and the glossary calls it Cross.** `design/parts` named the same
rung correctly, so one chain had two namings and one of them was wrong. Verified by
`tglossary.nim`, which reads the rungs back out of `sim/verdicts.md`. It failed on all three rows
before the fix, and the words of the report are now read rather than assumed (Article IX.5).

That law reads the words of the report, and never its numbers. Nothing in the audit runs the
sweeps again. One run of them takes about nineteen minutes, and a check that slow is a check that
gets skipped (Article IX.8). So the report can hold a figure that the code no longer writes, and
only a delegate who runs the verb will see it.

**The table that the report prints was a stale summary, in two rows.** The report opens by printing
the translation, so a reader knows what each phrase means. That printed table is written out by
hand, and it is a derived view of `said` (Article I.4). Nothing read it back, so it fell behind the
code twice: `said` says `elbow forward` and `open`, and the table named neither. `twords.nim` now
walks every phrase that `said` can return, strikes out each term the table names, and refuses any
residue.

**`open` is what one arm is, and the middle of the chain is a neutral twist.** The word named two
things. One is the middle of the chain, where the pair carries no twist. The other is an arm that
lies on neither face of its own body. Article VI.8 asks for one meaning for each word. The
Architect ruled that `open` keeps the arm, and named the middle of the chain **Neutral**.

The ruling first read that the two were one concept, because an open twist means both arms are
open. The recorded sweeps refuse that, in both directions, and the ruling followed the measurement.

**Measured** over all 1,233 moments of the twelve low and high sweeps in `design/turns.json`. The
six `above` sweeps are left out, because `said` answers with the band there. 147 moments have every
held arm saying `open`, and 139 of them stand at a turn that is not nought. `R-r` low reads open out
to +0.40 turns, and `L-l` high reads open again at -1.60. At nought turns, four of the twelve sweeps
carry arms that are not open. `L-l` high and `R-r` high read `wrap high (led)`, and the same-name
pair reads `lock` on the arms of the Follow.

A pair holds four arms, and they disagree, which is what breaks the equivalence rather than a
threshold set a little wrong. The same-name pair rests Pillion, so the Lead reaches forward while
the Follow reaches behind their own back. One moment of it reads `open`, `lock low (led)`, `open`,
`lock low (led)`.

The ruling also overrides an earlier choice of words. `neutral` sat on the avoid line of Open, and
it is now half of the agreed term. Verified by `suites/tglossary.nim`, which reads the ruling from
`GLOSSARY.md` rather than restating it. The old name fails both of its laws: the position says a
word the glossary rejects, and it carries no word the glossary agrees.

Issue #235 holds the whole table of where every arm reads open, sweep by sweep.

**An avoid line cannot be held by matching the word.** The glossary rejects `wind` for the quantity
that Twist names. The pages also use `wind` as a verb, where the arms wind, and that use is right.
A check that matched the word would refuse both, so the avoid line of Twist holds by reading alone.
The avoid lines of the chain and of the two dancers hold by law, because every word on them is
wrong in every use.

## Model

**One state and one relation, and everything else derived.** A `Frame` is what each hand of the lead
holds, and how the arms lie where they overlap. A move exists between two frames exactly when their
difference is one primitive: `collect` adds a connection, and `drop` removes one. The two compounds,
`place` and `cut`, are the pairs of primitives that the vocabulary marks with an asterisk. Names,
keys, slugs, routes and reflection are all read off the frame (`frame.nim`, `transition.nim`).

Rejected: to name frames for what a dance calls them, which puts the hand-to-hand frame and the
empty frame under one word (`open`). The empty frame is `free`. Cost: `closed` and `half-closed`,
which rest a hand on a body, have no frame here, and wait on a vocabulary for places on the body.

Verified by `suites/tframe.nim` and `suites/ttransition.nim` over every pair of the eight frames,
which is 64 pairs, exhaustive. They cover validity, naming round trips, reversibility, mirror
symmetry, one law for each primitive, and full connectivity.

**The workbook is data, audited, and never trusted.** `workbook.nim` holds the states and cells of
the `base` sheet, and the words of the `vocabulary` sheet, as constants. It derives findings by
kind. A cell names a move the model lacks, or the model has a move the sheet lacks. A helper word
differs, or a cell waits on the body.

Verified by `suites/tworkbook.nim`. Eighteen of twenty-seven cells are checkable today, and all
eighteen name the primitive that the model derives, with nothing missing and nothing spare. The nine
deferred cells are counted, and not hidden.

**Rotation is provisional and off the page.** `rotation.nim` holds twist, the three arm heights, the
two ceilings, blockers, wraps and locks. It also holds the measured fact that a low wrap holds half
a turn, where everything else holds a whole one. `axle.nim` draws its postures as one line, placed
by the twist itself.

The views do not show it. 148 postures render as 16 distinct pictures, because level, contact and
twist beyond its parity have no marks. A validator whose picture cannot tell two states apart is not
validating. Verified by `suites/trotation.nim` and `suites/taxle.nim`. The capacity constants are
witnessed by the sim (`sim/verdicts.md`), which is evidence, and not authority.

## Drawing chain

**One drawing chain serves the validator, the review page and the workbench, so they cannot drift.**
`draw/` builds the picture of a frame from the couple seen from above. There are two plain circles
with a chevron for facing, and the lead is at the bottom facing up.

Squares stand for the hands of the lead, and circles for the hands of the follow. Each one takes the
hue of its side and the shade of its owner: deep for the lead, and plain for the follow. So shape
and colour say whose hand it is at any size, and no caption is needed.

A connection meets at its middle in the inks of both hands. It goes **round** a body and never
through one. It is a taut string that hugs the rim only where the straight way would cross a body.
Only `above` runs straight, because it is over the head.

The way round of a move is settled once for the whole move (`oneWayRound`). No two animated frames
can then disagree about which side of a body the line passes. Rejected: per-frame routing with a
side bias and hysteresis. It drew lines that swept straight through a body, in the blend of the
browser between two frames.

Level is a fill on both ends: hollow unsaid, solid low, dotted high, and hatched above. A hand that
has left its default leaves a grey ghost. The lead always faces up, because poses live in world
coordinates and are drawn through `canonicalise`, so every equal configuration is one picture.

Cost: the picture of every frame is built at compile time. The browser then ships finished markup
and none of the routing, at the price of compile time. Verified by `suites/tdiagram.nim`, where
every picture says what its frame is, at any size. Verified by the gates of the workbench
(`design/checks.nim`), with 102 assertions on the pages.

**Rule 24 was measured at the corner, and a kink walked through it.** A settled reach picks its way
past the marks it must not touch. It weighs three candidates on length and turns together
(`readingCost`): the taut band let go from the straight line, and a bow over each side. Until now
the taut band was taken unweighed wherever it turned little and turned smoothly, on the grounds that
nothing could be plainer.

It can be. The band hugs whichever mark it meets, and a mark that sits near a hand puts the whole of
that hug against that hand. So the line runs dead straight to its far end, and bends only there. The
Architect called out exactly that on B4 and B23 of the review sheet.

**Measured**: their reach crested 0.88 of the way along its chord, with 8.3 degrees at one corner.
Every other bending reach on the page crested between 0.40 and 0.60. The bow that those two now take
crests at 0.53 and 0.59, with 3.4 degrees, which is the shape of B7 beside them.

All three candidates are now weighed every time. `crestOf` measures rule 24 along the reach as well
as at its sharpest corner. A reach that leaves its chord must crest away from both hands. Rejected:
to tune a clearance to move the hug, which would have left the rule measuring half of itself.

Cost: three band relaxations for each settled reach, where one sometimes did, which takes the mark
suite from 20.9 to 23.3 seconds. The bow beats the hug on those two by a hundredth of a unit of
line, so the preference is real but thin. It is the pins of the review sheet that keep a flip from
passing unseen.

Verified: the fix moved exactly two drawings of the 148 on the review page, and eight of the 273 on
the single-turn page. It moved nothing on the frame, sign or hand-to-hand pages.

**The chain is walked, and not jumped, so what lies between two positions is seen.** Past a whole
turn the pair stops sharing its swing evenly. One connection gives its bend up and runs straight,
while the other snakes round it (rule 31). How *quickly* it gives it up was written as a fast start,
on the grounds that the third crossing wanted to arrive early.

Measured, it does not: the third crossing arrives at the swan whatever the hand-over does. What the
fast start did instead was collapse the straight connection to a short stub for most of the walk. So
the diamond fell apart, and the swan was built again rather than one opening into the other. The
Architect danced the figure and named the missing bend.

The hand-over is now slow at the start and quick at the end. The connection then keeps its bend
nearly all the way, and gives it up at the last. Verified: no still moved. The hand-over is nothing
at a whole turn and everything at a turn and a half. That is exactly where the positions of the
chain sit, so all 87 pinned cards passed unaltered, and only the eight moving chain cells changed.

A first pass eased the hand-over at 3.5, which left the pair still crossing once between 1.28 and
1.38 turns. One arm lay flat over the other rather than went round it, which the Architect saw and
named. At 7.0 it never does. Measured over the whole stretch at two-hundredths of a turn, the two
connections cross at least twice everywhere. A check now walks that stretch and holds it.

What remains is smaller and of a different kind. The third crossing shows briefly around 1.38 to
1.40 turns, withdraws, and returns at 1.48. It is recorded rather than claimed fixed.

**A break that leaves a sliver draws a dot, and a dot says the opposite of a break.** A connection
is stroked with a round cap. A painted piece of no length is still drawn, as a disc as wide as the
line. Three places left such a piece.

- `gapFor` dropped a break only where the gap would hang off the end of the reach. So a crossing a
  hair inside that threshold kept a full-width gap, and left the line joined to its hand by a stub
  of 0.01.
- The dash pattern of the moving reach left a hair of paint at the seam between the two shades of a
  reach. It left another where two breaks nearly met.
- The pattern is measured along the sampled polyline, but spent along the smoothed curve drawn
  through it, which is about half a per cent longer. So a gap that stopped at the end of the
  polyline left the tail of the curve painted.

Each one drew a dot. At a hand it read as the connection detached from it. Inside a break it sat on
the crossing that the break exists to show, so the two connections read as passing through one
another. The Architect saw both on the hand-to-hand chain, swan to diamond.

`SEEN_RUN` now names the least piece that reads as a line. `gapFor` narrows a break rather than
drops it, and keeps that much line at each hand. It gives up only where the gap would be narrower
than the line it hides. The dash pattern gives any shorter piece at a seam to the break, and runs it
a stroke past the end of the polyline.

Rejected: to widen the suppression threshold. That would have drawn more crossings with no break at
all, which is the opposite of what rule 14 asks. Verified by `suites/tmarks.nim`, which drives the
build. Every piece that a break leaves is now nothing at all, or at least `SEEN_RUN`, over every
frame of every edge of every manner.

Cost: breaks near a hand are shorter than breaks in the middle, where before they were all one
length. The fix moved 12 of the 99 cards. Those are the four swan stills, whose straight connection
crosses close to a hand, and all eight moving chain cells.

**The third crossing arrives once, and the snake pulls in before it opens.** From a whole turn to a
turn and a half the pair gains one crossing. So the picture reads two crossings and then three, and
changes once. It used to read two, three, two, three. It gained one at 1.22 turns, lost it again
from 1.41 to 1.46, and took it back at 1.47.

The lost stretch is the third crossing that dives back under a hand mark, where no break can be
drawn. **Measured**: it sat 2.9 units from the hand of the follow at 1.42, where the reach is
trimmed at 7.7.

The two connections do two different things past a whole turn, so they take two shapes rather than
one shared between them. The straight one **hinges**: it gives up its bend late and then all at once
(`SWAN_EASE`). The snake **pulls in** against it while the pair tightens (`SWAN_DRAW_IN`,
`SWAN_DRAWS_AT`), and only then **opens out** into loops that go round it (`SWAN_SWING`,
`SWAN_OPENS_AT`).

That order is what does the work. The snake is at its tightest, 0.89 of the swing of one connection,
at exactly 1.42 turns. That is where the third crossing runs nearest a hand, and the snake opens
after. **Measured**: the crossing now keeps 8.5 clear of any hand at its tightest, against a trim of
7.7. A snake that opens early drives it under the mark.

Rejected: one width for the whole stretch, which is what a single `SWAN_SWING` is. The widest such
swan that keeps the count monotonic bows 14.1, against the 22 that the Architect had. In that shape,
width and crossing placement are one number.

Cost: the snake gains 0.16 of its swing over the last hundredth of a turn, which is 3.2 of line.
Looked at frame by frame, 1.43 to 1.50, it reads as loops opening rather than as a jump. That was
verified by looking, 2026-09-08, and not by test.

Verified by `suites/tmarks.nim`, which drives the build. A gate walks the stretch every hundredth of
a turn, and fails if the count ever falls, or rises other than once. Two more hold the snake to
drawing in before it opens. The swan bows 22 round its straight connection, which is the width
before this stretch was mended.

**The two connections keep clear of one another where they run alongside.** Short of the swan they
ran close enough to touch. At 1.37 turns their middles came 3.35 apart, where the line is 3.4 wide.
So the ink merged, and the Architect read the Right connection as running *into* the other rather
than crossing it.

The pinch now keeps growing past a whole turn (`WIND_NIP_MORE`), where its own cap used to stop it
at one. That cap is what drew the pair as though the winding had stopped. The snake pulls in harder
before it opens wider (`SWAN_DRAW_IN` 0.65, `SWAN_SWING` 1.50).

**Measured** over the stretch every hundredth of a turn: at 1.37 the two now keep 6.51 between their
middles, where they kept 3.35. The tightest anywhere they are not crossing goes from 4.05 to 4.81.
The shallowest crossing goes from 16.1° to 28.9°, which is well clear of `GRAZING`. Below `GRAZING`
a break can no longer cover what it hides. Verified by looking at 1.35, 1.37 and 1.39, 2026-09-08.

**No gate holds this**, and that is a gap rather than an oversight. Every measure of it that runs
over the whole stretch is dominated by two other effects. Those are the width of a break at its own
edge, and the arrival window below. So no threshold separates the mended drawing from the faulty one
with any margin. It is stated here so that a later pass knows it is unfenced.

**Amplitude was believed unable to move a crossing, and that belief was false.** The argument was
that both connections carry the same sine about the axis of the pair, with opposite sign. So they
meet only where the sine vanishes and the size cancels. It compares the two reaches **at the same
point along each**, which is only their crossing condition where they share a chord.

They do not share one. The two hands of the follow sit up to 20 units apart *along* the axis of the
pair. That holds wherever the follow has turned off a half turn, so the two chords differ everywhere
between the positions of the chain.

**Measured**: hold both connections at one common share, and sweep it from 0.5 to 2.0. The count at
1.20 turns moves through 0, 2, 3 and 1. The belief stood while the whole family was ruled out
untried, and while crossings were counted through a fold that merged them. So the sweep that would
have refuted it was scored blind. It earns its line because anyone who re-derives it reaches the
same wrong place.

**The map and the spokes are the same picture at two distances.** `map.nim` draws the whole ontology
with every line laid down before any word. Names are cut into the line with round caps, and never
painted over. A hole in a line now means that a connection passes underneath. The order of the tower
is fixed once (`towerOrder`), so the matrix and the map read the same way.

`spokes.nim` draws only the frame held and every way out of it. `motion.nim` says when each drawing
moves and for how long, so the page waits on the schedule of the drawing itself. Verified by
`tmap.nim` and `tspokes.nim`. The window that a move ends in is the window that the frame is given
when still. Where it leaves the frame standing is the place that the frame is given when still. That
is what makes the swap of one drawing for the next invisible.

## Validator

**Three views, in the order that a reader wants them.** Atlas is every frame, drawn and counted, and
the page opens there. Dance is the state machine from `free`. Matrix is every move at once, drawn
rather than tabulated. Both axes carry the pictures of the frames at one size, and a cell is the
same mark that the map uses. Only what the ontology derives can be clicked, and a compound dances
both its moves in turn.

The close drawing hands its geometry to the stylesheet as bare numbers, and takes back one unit.
That unit is registered with `@property`, so a recentre animates the scale. It stops shrinking when
names reach 8 px, and scrolls instead. `--wide` is the width at which the map is worth opening on.
It is written once in the stylesheet, and read by the script.

Keyboard: every control is reachable, focus returns after each move, and a live region outside the
rewritten region announces what was danced. Verified by hand in a browser at 390, 600 and 1200 px
before the move. The mark and the frame land in the same place either side of the swap. It has not
been driven again since, so it is **assumed**. Which browser, and on what date, was not recorded, so
this cannot be repeated from a checkout. Whoever next touches the shell drives it again, and writes
both down.

The shell is the committed file `pages/app/index.html`, copied out by `tools/pages`. The bundle
(`tools/bundle.nim`) folds `app.js` into it as one self-contained file for publishing. It is titled
from `tools/title.nim`, so that a gallery sorts the body of work together.

## Review page

**Every number and picture on the page is a marker filled from the model.** The prose lives in the
committed file `pages/review/review.html`. `tools/review.nim` fills the markers, and inks every term
of art in the hands it names. It writes the page and one SVG for each frame into a directory that it
clears first. A renamed frame can then leave no old picture behind.

Rejected: to commit the generated page and hold it fresh by a test. This repository cannot do that,
because it reads only registered file kinds. The page is a build product and cannot be stale, and
the test drives the build instead (Article IX.6).

Cost: nothing in the tree shows the history of the page. The published copy is not the record
either, because it can be deleted, and seven were on 2026-09-06. The log is the record.

Verified by `suites/treview.nim`. Every marker is filled. The page and the pictures are written and
read back. Every frame is named, and every move and compound is counted in the matrix. No picture
fixes a colour of its own, slugs are unique, and stale pictures are removed.

## Design workbench

**Rules are data, and the pages are held to them.** The forty-one rules as given live in
`design/rules.nim`, in the words they arrived in, and `design/README.md` quotes each one.
`checks.nim` asserts what each page claims, between the build of its parts and the write. The build
refuses to write a page whose claims fail. Rejected: rules that are implemented and not asserted,
which quietly stop being true. The section on the rules of the drawing gives the check of each.

**Each page's parts are built once, and a check reads what its page placed.** A page, its check and
the review page all need the parts of the two walked pages. Routing is most of what the build costs,
so `marks.nim` keeps the parts of every page it has built. The page suite ran for 14.05 s with each
built three times, and runs for 7.11 s now, debug build, on 2026-09-24. Verified by the five pages,
which are the same byte for byte by sha256, and by every line the checks print, which is the same.

The five generated pages and the hand-drawn whole-cloth page are build products under
`build/design/`. The whole-cloth markup is the committed file `mockups/wholecloth.html`. Its turns
panel is `wholecloth_turns.nim`, compiled to JavaScript, and `wholecloth.nim` splices markup, the
sweeps of the sim (`turns.nim`) and the panel into one page.

Verified by `suites/tmarks.nim`, which drives the build of every page under testament. The
whole-cloth port was verified by a driven comparison under Playwright of the old page against the
new: 707 states equal. See Figures for what was compared.

**Every page says its prose in Simplified Technical English, and a hand-drawn figure claims nothing
of the sim.** The Architect ruled that the prose did not read, and asked for it again from the
charter's subset (`GUIDE.md`, Article VI.8). Two rules of that subset can be counted, and
`design/plain.nim` counts them off the markup. A sentence of prose holds at most `WORDS` words, and
a paragraph at most `SENTENCES` sentences. Prose is the text of a `p` or an `li` alone, because a
caption or a swatch label is a fragment rather than a sentence.

The rest of the subset, from the approved word to the active voice, is read rather than counted.

Verified by `suites/tmarks.nim` over every page the workbench writes and over the committed
whole-cloth markup, and by `suites/treview.nim` over the reference page. Both laws were proved able
to fail. One sentence lengthened past the bound reddens the page it sits on. A seventh sentence
added to a full paragraph reddens the markup that holds it.

**The reader stepped over every paragraph that stands behind a drawing.** A page names each drawn
element with a tag that opens as `p` or `li` does, such as `path` and `line`. The reader met one,
then looked for the closing tag of the kind it wanted, which is the next paragraph's own. So it
skipped that paragraph. The sign page holds 24 blocks of prose and the reader saw 14. Verified by
`tplain.nim`, which reads prose off markup written for it, where the count is known.

**The rig viewer and the Reference are counted now, and the Reference was over the bounds.** Each
one writes its prose in the browser rather than into markup the workbench renders, so `tmarks`
reaches neither. `tsaid.nim` reaches both, on the JS target, because both pages import `std/dom`.

It reaches them two ways, because they are built two ways. The Reference builds its markup in pure
functions that return it, so the law calls them and reads what they return (Article IX.5). The
viewer writes its sentences straight into elements, so they are held in one table,
`rig_view.VERDICTS`, which the law reads instead.

The Reference held nine long sentences and two long paragraphs when the law first ran. The worst
sentence held 44 words, in the note of the matrix. The two long paragraphs held 7 and 11 sentences,
against a bound of 6. Every one is rewritten and the information is kept: the notes of the spokes
and of the map are now two and three paragraphs. Proved able to fail on both paths, by lengthening
one sentence of the Reference and one verdict of the viewer past the bound.

The earlier record said that a count for both needed the browser, and that was wrong. Nothing the
law calls touches the document. It also said that the viewer measured clean by hand, which held,
and that nothing measured the Reference, which was true and hid nine faults.

One line is counted by nothing still. The fourth verdict of the viewer opens `Stops at N turns:`
and closes with a reason the sim recorded, so it never stands as one whole string. Those reasons
come from `hold.says`, and the longest of them holds eight words.

**The two counted rules passed while the prose still did not read.** Every page sat inside both
bounds while the words were still wrong. One page said that a stage `collides` a capsule. Another
said that a cell `stands as it stands there`. The bounds are a floor, and nothing but a reading
catches a word used outside its meaning.

**The READMEs of the project are counted as its pages are.** Article VI.8 binds every Markdown
file, and the `english` check of the repository reads only the three records at the root of a
project. So that check reads neither `sim/README.md` nor `design/README.md` (issue #239).
`design/plain.nim` reads Markdown as that check does, and `treadme.nim` holds both READMEs with the
two numbers the pages keep. `WRITTEN` names the files held, and a README joins it when it is written
again.

**The rules that `design/README.md` quotes are held to the ledger, and not to the two numbers.**
They are the words of the Architect, so a quotation is never rewritten. A `>` quotation carries no
prose, so neither check counts it. `treadme.nim` holds each one to its entry in `RULES` instead,
word for word, once each and in order. Verified by `suites/treadme.nim`, which fails on a changed
word, a missing rule and a missing quotation.

**The reader of Markdown is copied from the check, and not imported.** A suite compiled against the
check of the curator would break whenever the curator changed that check. Duty 3 forbids the
curator to do that to a project. The cost is two copies that must agree. Verified against the check
on nine documents of the repository: the two agree on all 1158 blocks and all 2746 sentences. Six
laws in `tplain.nim` pin the copy, and each was broken on purpose and caught its own break.

**`sim/README.md` described a solver that was gone, because it said the model a second time.** It
said that a pattern search from seeds finds each pose, and that each moment seeks the pose again.
Both were `solve.nim` and `sweep.nim`, which 4d5241a removed. It also said that a joint past its
range is refused, and that the girdle has no range. When the design moved only this record
followed, so a README points at it and at `rig.nim`, and does not say the model again.
Verified by reading each claim that `sim/README.md` keeps against the code or this record.

**No string a page shows says a gendered word for a dancer.** The glossary rejects one for each
dancer, and `tglossary.nim` reads that ruling rather than restates it. It holds every string literal
of `design` and `app`, and the two pages this project writes by hand. A literal that a colon follows
is a key of recorded data, so the check steps over it. Verified by `suites/tglossary.nim`, and
proved able to fail. The readout said `her arm` and a block reason said `his reach` while every
other law passed.

The hand-drawn dial of the whole-cloth page came out. It stated blocks and turns from a sweep of the
solver that this project has deleted, and the generated panel below it disagreed. A figure drawn by
hand cannot follow the sim. The page now points at that panel and at `sim/verdicts.md`, and the
captions of its hand-drawn plates describe the drawing alone. Rejected: to keep the dial with a note
that it may lag, which leaves a wrong number on the page.

**That comparison cannot be repeated here.** Playwright, TypeScript and any package manifest are
absent from this repository, and the date it ran was not recorded. So the 707 figure rests on a
session that nobody can re-enter. To restore it means to bring the harness in as a project of its
own.

The page module records three reflow deviations. There are 37 breaks inside `aria-label` values, and
the accessible names were verified equal. There is one whitespace-free row, with its character
references decoded. The fonts URL is held as its own constant, joined at compile time. Cost: the
`doAssert` gates of the workbench are the check, so its tests are a debug build.

**The build dressed a page it did not write, and the page grew by 223 kB each time.** `dress()`
walks every page under `build/`, and not only the pages the run wrote. `build/sim/artifact.html` is
written by no verb that this project still holds, so every `pages` run put another block of faces
into it. It stood at 10.9 MB and reached 11.4 MB in four runs of one session. That climbs toward
the size a published page must stay under.

The law that covers this was already written, and it could not fail. `tfaces.nim` held a test named
"dressing is not doubled where it runs twice" that dressed once and counted the faces. It now
dresses twice, over both shapes of page, and demands the same bytes. `faceStyle` marks its block
`<style data-faces>`, and `withFaces` takes an earlier block out before it puts the new one in.
Replaced rather than skipped, so a page dressed before a face changed takes the new bytes.

Verified: two `pages` runs over one tree now give ten pages that compare equal, byte for byte. The
orphan pages under `build/sim/` are gone, and no verb writes them again.

**The four are a manner of turn, and not a way of turning.** `Manner` and `MANNERS` replace
`TurnWay` and `WAYS_OF_TURNING` through the workbench. The pages, the checks and the rule ledger say
"manner" wherever they meant one of the four. "Way" is kept for clockwise against anticlockwise,
which is what `wayOf` and `wayName` return. The one word carried two senses, and they are now two
words. Rejected: to rename `Way` as well, which would have left the direction of the turn unnamed.

Verified by every drawing on all five pages coming out byte-identical across the rename: 66, 56,
273, 62 and 148 figures. So nothing but the prose moved. Cost: nothing holds the prose of a page to
`GLOSSARY.md`. `tglossary.nim` reads the `_Avoid_` lines, but claims only against chain position
names. So this rename can drift back without a test noticing.

**The moving sections show a walk whole before they show it in pieces.** Sections E and F of the
review sheet drew one cell for each edge. That is 64 quarter-turn edges and 24 chain edges, which is
88 cells of animation to scroll past. Each manner of each hold now takes two cells instead. Those
are the walk entire, and the same walk step by step, with a button for each step.

`turnWalk` gained `steps` and `back`. One builder now makes three things. They are a single rocking
edge, a whole round of four quarters, and a whole chain of six halves out and back. The round closes
on itself and needs no return. The chain does need one, because it has ends.

The switching is a radio button and a sibling rule, so the page stays markup that a browser draws
with nothing running. Rejected: script, which these pages have never needed.

The pin now covers every drawing in a cell, rather than the last one. A verdict on a cell is a
verdict on all of it. For a cell that holds one drawing that is the same string, which is why every
existing pin still matched.

Cost: fewer cells, and a larger page, at 6.9 MB where there were 4.2. A walk shown whole is drawn as
well as its pieces, and not instead of them.

Every animation runs at one pace (`WALK_SECONDS`), so the length of a loop says how far it goes
rather than how fast. The whole chain is six times an edge, which is a long loop. The page flags it
as something to shorten if it reads as slow.

Verified by `suites/tmarks.nim`, which drives the build and so the gates. The 16 rounds are counted,
and each one is asserted to close where it set off. The whole-walk figures are held to the same
hatch laws as the edges. Verified again by every drawing on all five pages coming out byte-identical
when `steps` and `back` took their defaults.

**A verdict is given on a picture, so the picture is pinned.** `review_page.nim` lays out every
position that the project draws as a card. Those are the standard diagrams and the one anticlockwise
counterpart. They are also the distinct single-hand turn positions, both hand-to-hand chains, and
every animated edge of the last two. Each card carries the identifier to quote back, and whatever
has been ruled on it.

The identifiers that the Architect has kept or dropped are named in the module. What each one was
drawn as when it was ruled on is held as a hash in `design/review-pins.json`. The build refuses to
write the page when the drawing of a ruled card has moved.

Rejected: to take the verdict as given on the identifier. That is how a mend which reached further
than it meant to carried an approval that nobody gave. The guard was proved by a widened clearance
on a break. It then named the twelve kept cards that carry a crossing.

Pins are rewritten only by `tools/build.nim pins`, which is a deliberate second step. A verdict and
its pin are added together or not at all. To run it to quiet a complaint would hand the approval to
the new picture. Cost: the verdicts live in the module, so every ruling is a commit.

Verified by `suites/tmarks.nim`, which builds the page under testament. Verified by every pin
regenerating identical in content when the page moved into the workbench from the scratch generator
that first drew it. Verified by the tally being counted off the built page, rather than kept while
it is built. What the page says of itself cannot then drift from what it holds. The page prints that
tally where a reader sees it, which is why no number of it is written here.

## Rules of the drawing

**The workbench is a mock-up, and its checks hold a drawing to a rule as written.**
`design/rules.nim` holds every rule the drawing was given, in the words it arrived in, and
`design/README.md` quotes each one. `design/checks.nim` checks each standing rule on every build and
prints one line for it. A check verifies that a drawing follows a rule as it is written. It never
verifies that a couple can dance what the drawing shows. The Architect trusts only a reference cell
that is kept, modelled and confirmed, and `CONFIRMED` in `design/review_page.nim` holds none yet.

**A rule that is implemented and not checked stops being true, so each rule drawn has a check.** A
check names its rules in a comment in `checks.nim` that opens `RULE`. Nothing in the workbench
checks rules 36 to 40, and the sim reports in their words. Nothing checks rule 41.
`tests/suites/treadme.nim` holds every quotation in the README to `RULES` word for word, so the two
copies cannot drift. The checks do not quote `RULES`, because their printed lines say what was
measured.

**A moving picture is checked where it is drawn, and not only at its frames (rule 1).** A browser
blends two frames point by point. So two frames that disagree about which side of a body a line
passes are drawn, between them, as a line through that body. `oneWayRound` in `route.nim` chooses
the way round once for a whole move, and every frame of the move uses it. Verified by `checkRules`,
which samples each blend part way between two frames.

**A hand leaves its side only when its hold names a level and a way (rules 2 to 6).** A level alone
does not say which side a hand goes to, so the hold must say lock or wrap as well. A hand settles in
one of six places, each a bearing off its own dancer's facing (rule 3). `SLOT_OFFSET` in `body.nim`
sets them 44 degrees apart, and two marks need 34.9 degrees, so no two marks touch.

Both wraps go round the front to the front of the other hand, and both locks go round the back
(rules 4 to 6). A high lock goes round to the back of its own shoulder, which is a hammerlock (rule
37). Verified by `checkRules`, which checks where each hold settles and which way its route sets
off.

**A lock or a wrap needs its line to go round the body (rule 7), except a high lock (rule 41).** The
arc a drawn line hugs takes one of five values: 0, 51, 90, 141 and 180 degrees. So `WRAP_MIN`, at
170 degrees, admits 180 alone, and the build refuses to draw a lock or a wrap that falls short.
Verified by `checkRules`, which checks that `danceable` agrees with the measured arc.

The drawing does not follow rule 41. It holds a high lock to `WRAP_MIN` too. So it refuses a high
lock with the follow a quarter turned, where the arc is 141 degrees. The workbench is a mock-up, so
that is left as it is.

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
level. Assumed, and read by the sim rather than by the workbench.

**Rules 10 to 14 were given for a rotation page that is gone.** Where a later rule replaces one of
them, the README says which. Rule 11 stands on the turn pages, whose positions are frames of the app
in their four orientations. Rule 14 stands as far as nothing wraps a body at high. Its pigtail is
gone, because rule 16 removed the limit the pigtail marked. Both are verified by
`checkSingleTurns`.

**A turn page shows each position it derives, and each move between two of them (rules 15 and
16).** The counts are checked against the graph of states, and not against a number typed in. A
single hand held high turns without end either way (rule 16). So how far it has turned is not part
of its state, and only its orientation is. Verified by `checkSingleTurns`.

**Every turn is drawn above (rules 17 and 21).** Above is the one level rule 8 gives no lock and no
wrap, and the one whose line runs straight over everything. A moving hand carries the above hatch,
as a still one does. Verified by `checkSingleTurns` and `checkHandTurns`, which count the hatch on
every move.

**A turn by the lead is drawn in two stages (rule 18).** The room holds still while the lead turns.
Then the picture turns back so that the lead faces up. A turn by the follow leaves the lead facing
up already, so it needs one stage, and that is measured. Verified by `checkSingleTurns`.

**Four manners of turn: each dancer turns on their own axis, or goes round the other (rule 19).** An
orbit is marked by a dashed ring while it happens, and nothing else is dashed. An orbiter keeps
their side to the centre (rule 32). So an orbit winds the pair as far as it carries them, and every
manner steps one position for each half turn. Rule 32 replaces rule 20, under which an orbit wound
nothing and two manners did not walk the chain at all. Verified by `checkSingleTurns` and
`checkHandTurns`.

An orbit lands where the axis turn of the other dancer lands. So the four manners walk two rounds of
positions, and not three. All four are drawn, because which dancer walked is a fact about the path,
and only the path can show it.

**A settled reach passes clear of every mark it does not join (rule 22).** It is a line pulled taut
past both chevrons and every hand but its own two, bent round each and straight elsewhere. The gap
is taken from what is drawn, with half the width of the line added. A moving reach may pass a mark,
as the rule allows. Verified by `checkSingleTurns`, which checks both halves. The frame page does
not follow rule 22 yet, because its figures do not pass `clear_marks`.

**A reach is judged on its length and its bends together (rule 23).** The shortest way past the
marks weaves, and a reader must follow each change of way. So a bend costs `BEND_COST` of length,
and the taut line held to each side of the chord is tried as well. Each of those bends once, by
construction. A route that bends once or not at all is left alone. Verified by `checkSingleTurns`,
which checks that no reach bends three times.

**A route that bends is drawn as one smooth curve (rule 24).** The hull of the marks shows where the
bulge goes and how far out it must reach. The line over it is one quadratic curve, widened until it
clears every mark. A curve of that kind turns one way only, so the route still bends once, with no
corner in it. Verified by `checkSingleTurns`, which checks the corner of the stored line.

**A reach is drawn as curves through its sampled points (rule 35).** A reach is held as `ROUTE_N`
points, so that it can move from one shape to the next. Drawn with straight pieces, a swan turns
back inside a few points and shows its facets. So `route.smoothed` makes each sampled point a
control point and draws through the midpoints between them. The ends stay on their hands, and the
checks measure the lengths they measured before. Verified by `checkHandTurns`.

**How wide the swan swings is set by eye, and not by a check (rules 33 to 35).** `SWAN_SWING` in
`route.nim` holds it. Rule 34 took back the width that rule 33 asked for, and rule 35 set it again.
The check on it is a backstop: the snake goes round something and stays inside its figure.

**The turn pages frame on the place of the lead (rule 25).** `canonicalise` turns the world about an
`Anchor`, and the turn pages use `Anchor.Lead`. So the lead holds one spot, and an orbit by the
follow needs no second stage. Only an orbit by the lead has anything to bring back. Verified by
`checkSingleTurns`. The frame page still frames on the middle of the couple, and does not follow
rule 25 yet.

**The turn back to the lead is quicker and quieter than the turn itself (rule 26).** A `Walk`
carries the time each frame is due, and the markup says so in `keyTimes`. So how long a stage lasts
is a choice of the drawing. The turn back is paced at `RE_FRAME_PACE` of the turn, and
`ARRIVAL_HOLD` holds a beat where the turn lands. Verified by `checkSingleTurns`, which reads the
clock in the markup and checks that the turn back takes less than half the turn.

**A hatched mark moves with its hand (rule 33).** An above fill is a pattern fixed to the drawing,
and not to the shape. So a moving hand is drawn once and carried by a transform, as a body is, and
the hatch travels with the mark. Verified by `checkSingleTurns` and `checkHandTurns`, which check
that a hatched mark moves nothing of its own.

**The holds of two hands walk a chain of seven positions, a half turn apart (rules 28, 30 and 31).**
The seven are swan, diamond, X, the frame, X, diamond and swan. The chain has ends, and is not a
cycle (rule 30). Hand to hand and the crossed pair walk the same chain, and differ only in the
facing where the hold is unwound (rule 31). `parts.phaseOf` finds that facing, and `parts.chainFor`
lays the seven out from it. Verified by `checkHandTurns`.

**The wind is measured from the pose, and is not told (rule 28).** Each held hand sits on the rim of
its body, and both bodies stand on the axis of the pair. So the angle a hand makes with that axis
says how far round it has gone. The difference between the two ends is the wind. A reach is the
shadow of a wound arm from above: straight at no wind, an X at a half, a diamond at a whole.
Verified by `checkHandTurns`.

**The crossings alternate, so a connection over at one crossing is under at the next (rule 27).**
That is what being wound together means. Rule 28 measures the diamond that rule 27 drew. Verified by
`checkHandTurns`.

**A moving reach shows its breaks as the still does (rule 29).** A still reach is cut where it dives
under its partner. A moving reach keeps one path, and shows the break as a dash that travels with
its crossing. The crossings are found segment against segment, as the stills find them. Verified by
`checkHandTurns`, which checks that a moving figure and the still it lands on break the same arm.

**Each way of turning finds its own sense, so no move walks off the end of the chain (rule 30).**
The sim turns a quarter from the frame, and reads the wind at the furthest pose the walk reaches.
Verified by `checkHandTurns`, which reads the wind on every frame of every move.

**Past a whole turn, one connection runs straight and the other goes round it (rule 31).** That is
the swan. `route.windShare` gives the swing of the straight one to the snake. So at a turn and a
half, one reach is the plain chord between its hands. The straight one is on top at the first
crossing, so it dives once. Verified by `checkHandTurns`.

**The sheet of the Architect gives rules 36 to 40, and the workbench checks none of them.** The sim
reports in their words, through `sim/words.nim`, and that is not a check. Rule 37 says what a lock
is, and makes a high lock a hammerlock. Rule 38 says a wrap crosses the other arm of its
dancer. The drawing does not show that crossing yet, because rule 22 keeps a settled reach away from
that hand.

Rule 39 makes modifiers belong to each arm, for either dancer. The drawing holds one level and one
way for each connection. Rule 40 is the one filled rotation row of the sheet. `sim/verdicts.md`
gives what the sim finds for Left to left held low, turned from face to face.

## The frame picture

**Each hand is drawn in the colour of its side and the shade of its dancer.** Left is blue and right
is orange, for both dancers. The lead's hands are in the deep shade, and the follow's in the plain
one. Each of the four is a named colour with a fallback. So a picture follows the page it is on, and
draws in its own ink when opened alone, as the app's figures in `doc/frames/` are. Verified by
`treview.nim`, which checks that every ink is a named colour with a fallback.

**The shape of a mark says whose hand it is.** The lead's hands are squares, and the follow's are
circles. The mark carries this itself, so it holds at any size. Which column a hand sits in follows
from the way its dancer faces. So the four facings are distinct without a new mark.

**A level is a fill on both ends of a connection.** Hollow is no level, solid is low, a dot at the
centre is high, and hatched is above. A crossed hold keeps its drawn break as well, because the
break still shows at node size. A hand that nobody holds fades to half strength and keeps its hue.
The free frame is four free hands, and to grey them would hide the one thing that shows orientation.

**A body is a plain circle, with a small chevron at its centre for its facing.** The centre is the
one part of a dancer that nothing else uses. `outlineR` in `body.nim` is the one function for the
edge, so the routing and the drawing agree on it. The rim says only that a body is there. It is one
quiet stroke, broken round each hand by `HAND_GAP`, and it carries no colour of a side. Verified by
`checkFrame`.

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

**A position cannot tell an orbit from an axis turn.** A quarter orbit lands on the picture that the
quarter axis turn of the other dancer lands on. So which of the two was danced belongs to the move,
and not to the position. An orbit walked while turning back, so that the walker keeps their bearing,
lands on one picture whichever dancer walks it. It lands apart from the axis turn, so those two are
two moves. Verified by `checkFrame`.

## The turn sign

**A turn is shown as a leaning box that holds exactly one full turn.** Its rows are quarter turns,
packed up from the foot. So an amount reads as how full the box is, before it reads as a count. The
columns are the lead's two arms, in the order and the inks of the frame picture.

**A pip says whose quarter it is twice, by its shape and by its shade.** A leaning square is the
lead, and a circle is the follow. The fill of a pip is the level of its arm, as a hand's fill is.
Rows may mix the two dancers, with the follow's rows on top, so a turn they share is one sign.

**A dashed outline marks a turn that goes round the couple.** It labels a move and not a position,
as the frame picture does. There is no sign for a turn that is refused. A turn that cannot be danced
is a move that is not drawn. Verified by `checkSign`, for the geometry of the sign alone.

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
nothing to 65 in and 80 out, which is about the AAOS figures. It is refused past the 90 in of the
AMA Guides and the 104 out of Boone and Azen. The tables disagree by about the width of the ease,
and the ease is where they disagree. Assumed: which table the shoulder of a dancer follows.

The elbow goes to 140. The flexion and extension of the wrist are taken as one 60 degree cone. The
rotation of the forearm can turn the plane it bends in.

Hands are offered three bands: torso 1.00 to 1.35 m, neck 1.40 to 1.50, and crown 1.735 to 2.00. The
crown starts one radius of a limb over the head, so a hand carried there clears it by construction.

Rejected: to import anything from `src/`, because a shorthand cannot check itself, and the sim is
what a shorthand is for. Not rejected, and reversed since: to share vocabulary. Verified by
`tlimb.nim`: the tape and the forward kinematics of one arm over seeded random arms, and the contact
test against a sampled truth.

## Rigid body engine

**A rigid body engine is cloned, and not vendored, and Nim alone speaks to it.** `tools/build.nim`
declares `box3d` in `SOURCES`, with its repository, its commit
`47d7f7cc7e091142c08d11dc7d2e493c5d34f536`, its reason and its licence. The licence is MIT, read
from the `LICENSE` of the repository itself rather than assumed. `engine` clones there into `deps/`,
refuses a clone standing at any other commit, compiles its C files, and archives them into
`bin/libbox3d.a`. The commit is what stands where a checksum stands for a fetched file.

Nothing of it is committed. `deps/` is ignored at the repository root, exactly as Atlas checkouts
are. Rejected: its own CMake. That would be a third build driver in a project whose registry admits
no second. Nothing in its sources needs one, because none is generated.

Cost, stated: the build flags are this project's rather than those of upstream, and `-O2 -std=c17`
is what the release build of upstream sets. Measured: 24 s cold, and the verb returns at once where
the archive already stands.

`sim/engine.nim` is the binding, Nim throughout, so the gated-language rule is never engaged. It
links the archive and declares what the rig needs. That is world, body, capsule with its surface
material, ball, hinge, weld and distance joints, contact manifolds, step, world point and angular
velocity. To import it builds the archive first, at compile time, so a suite that drives the engine
drives its build too (Article IX.6).

Verified by `tengine.nim`, which holds it to two laws and no more. A body falls half g t squared,
which catches a struct laid out wrong where linking would not. Two limb-thick capsules started
inside one another part to at least two radii.

**The engine stands Y up and this project stands Z up**, and the binding deliberately does not
translate. Whatever calls it says which way is up, and `sim/rigid.nim` is the one place that does.

**What the engine holds, and what it judges.** The hinge of the elbow, the cone of the wrist and the
twist of the shoulder are the limits of the engine itself. The swing of the shoulder is not. The rig
gives extension and adduction as two ranges of their own. A spherical joint offers one symmetric
cone about rest, which would also bound elevation, and the rig gives no range for that at all. Every
hold over the crown would then block at once.

So swing is read back off the pose in the terms of the dancer, and resisted by a torque. The engine
resists the other joints the same way. It is 200 newton metres per radian past either end
(`SHOULDER_BACK`). That is stiff enough that an arm pressed against its end stays within `GIVE` of
it, rather than sinks through.

An arm rests against a limit and slides along it. It blocks only when forced past by more than
`GIVE`, which is the room that a limit which pushes back needs to push in.

Torque is a pseudovector. Each arm is worked out in the mirrored terms of the body, so one set of
ranges serves both sides. A mirrored frame is left-handed, and to un-mirror a torque as a plain
vector turns the correction into a shove. The mirror law does not catch this, and the sign rests on
the physics.

The stance travels with the turn step by step. Swing read against a frame that the dancer has
already left judges every arm wrongly. Rejected: to fit a cone to the pair of swing ranges.

**Bodies are solid.** Contact is held at the cap of the engine itself, an eighth of the substep rate
(`CONTACT`, 240 hertz at `HERTZ` 240 and `SUBSTEPS` 8). At the default thirty, the forces of the sim
itself pressed arms through bodies by 45 mm.

The upper arm collides with the chest it hangs from. The engine lets bodies that one joint connects
pass through each other, unless told otherwise. The arm sank 67 mm into its own head unseen.

Every joint but the grip holds at the cap of the engine (`HOLD`, 480 hertz). The grip alone holds at
thirty (`GRIP`), which makes it the softest thing in the couple. A hold forced past what arms can do
then gives at the hands, in life as here. At fifteen it fixed one law and cost every still card.

An arm deeper than a centimetre (`THROUGH`) in a body or in another arm is a stop. That is read off
the manifolds of the engine every moment. Before, only the hands parting said so, and a hold stood
with an arm through a torso.

The manifolds are read into the room that the engine says a body needs (`touchRoom`). Read into room
for eight, a forearm wound into a chain and touching nine things dropped its deepest unseen. Two
forearms then stood 22 mm through each other with nothing said. Verified by `tengine.nim`: a body
touched by ten things reports every one, and eight when given room for eight.

The capsules of the trunk and both girdles are recorded where the engine has them, so a law reads
the engine and never a copy. Verified by `trigid.nim`. No arm sits inside any body in any moment of
the corpus of the laws. Every capsule that the page draws is one that the engine was given.

## Joints that give

**Comfort is a slope inside a range, and not a wall at its end.** The limits of the engine are
walls, and its springs, at one hertz (`EASE`), are nothing. So every joint ran to an end and stayed.
Her arm sat forty five degrees behind the frontal plane at the height of the head, for six
arm-moments of a crown turn. The Architect refused that on sight.

The range of each joint carries an ease band before each end, and inside it a torque grows with the
lean.

- Swing takes the same 200 newton metres per radian as its wall (`SWING_LEAN`), because at ten her
  arm still reached the wall.
- Twist takes 25 (`TWIST_LEAN`), which is about the passive stiffness of a shoulder near the end of
  its rotation. At seven, three newton metres at the end of the ease was under what forty newtons of
  lift at reach puts on a shoulder. Joints then sat at their ends in most stills.
- The elbow takes 15 (`ELBOW_LEAN`).
- The wrist takes 6 (`WRIST_LEAN`), which rings at twelve hertz on a hand.

The last three are assumed.

The arms weigh nothing. Weight does one thing to the elbow of a held arm: it turns the elbow toward
hanging below the line from shoulder to wrist. That is put back as one newton metre (`ELBOW_DOWN`).
Nothing else that weight does is put back, so it neither loads the rise nor pulls a hand down.

A free arm gets none of it, and rests with its elbow near straight (`HANG_BEND`, assumed). The fixed
moment about the near vertical line of a hanging arm twisted every hanging arm forty degrees, and
swung it forward twenty. The engine spring gives twist next to nothing, because an arm is thin about
its own length. The forearm then pointed at the partner, so a free couple at rest stood with arms
crossed between them.

Verified by `trigid.nim`. A free couple at rest hang every arm near plumb, elbow near straight, and
untwisted. No arm is within its own thickness of the other's. Red first.

The shoulder spring of a free arm is five hertz (`HANG_HZ`, assumed). It stands in for the weight
that holds a hanging arm plumb. That is about seventeen newton metres per radian, for five kilograms
of arm at a third of a metre.

At one hertz the spring gave about two. The friction of the flank then dragged her arms behind her
slow half turn by forty nine degrees. They crept back to thirty three through the settle, so A2
stood with her hand 413 mm off plumb. Measured at two hertz: twenty four and eight. At three:
thirteen and five. At five: five and four.

Verified by `trigid.nim`. A free couple wound half a turn either way hang every arm within ten
degrees of plumb, and the hand within 0.2 m of it. Red first.

The spring of the wrist itself is five hertz (`WRIST_EASE`), which is the passive stiffness of a
wrist. At one hertz the wrists sat at their cone at rest, once the elbow was turned down.

Friction where arm meets body is 0.2 (`FRICTION`), cloth on cloth. At the 0.6 of the engine, an arm
lying over a head was dragged round with it as she turned under. That wound her shoulder to its end.

Rejected, each one measured and each one worse: gravity on the arms, higher damping, and a ramp on
the elbow. Rejected too: a raised floor for the crown, and a pull of the hands to a disc rather than
to a point. Verified by `trigid.nim`: no held arm over the crown is carried to the end of its swing.
Red first.

**The trunk twists at the waist and does not bend.** The hips are a kinematic body, turned and never
pushed, and they carry nothing. Every trunk capsule and both shoulders ride on a dynamic chest. That
chest is hinged to the hips about the up of the trunk, and sprung to neutral. It is stopped at forty
degrees each way (`Rig.waist`), which is clinical thoracic rotation.

The ease is fifteen, and it is assumed, because the tables give the end and not where it starts to
cost. Inside the ease the chest is turned back toward square at 60 newton metres per radian
(`WAIST_LEAN`). That is about what the passive stiffness of a trunk gives near that end, and it is
assumed. Verified by `trigid.nim`: shoulders yaw on hips no further than the thorax turns, and rest
square.

**Each shoulder is a girdle on a collarbone, and both give.** The shoulder joint sits at 0.18 m out
and 1.40 up, which is nine centimetres outside every capsule of its own torso. With nothing there to
give, the arms read as dislocated on the viewer.

Each shoulder is its own body. It is a capsule of radius 0.06 from the side of the neck out to the
joint, which is deltoid and trapezius. `GIRDLE_R` is an estimate, and not tape.

It hangs on a collarbone, which is a body of its own at the side of the neck (`COLLAR_R`). That
gives it half a kilogram, a fifth of the girdle's. At a fiftieth, the solver let both girdles leave
their hinges by half a metre standing still.

The collarbone is hinged to the chest about the up of the trunk, for protraction and retraction. It
is hinged to the girdle about the fore of the trunk, for elevation and depression (`Collar`). The
two hinges in series are the universal joint that the engine has no one joint for.

Each swing has its clinical range: 25 degrees fore and aft, and 40 up and 10 down, from Kapandji
(`Rig.collar`). The eases are 10 and 5 to 10, and they are assumed. It is sprung to where tape puts
the shoulder at 4.5 hertz (`COLLAR_HZ`), which is about twenty newton metres per radian. The pull of
one arm then rolls a shoulder half way to its ease, and costs from there. That is assumed. It is
turned back inside its ease at 40 newton metres per radian (`COLLAR_LEAN`), which is also assumed.

A girdle was a weld on a linear spring with a rope at five centimetres, which is a scapula hanging
slack. Every still with any pull on it had the shoulder at the end of the rope. A spring alone let a
free arm shoved by the other body carry its girdle 251 mm into its own torso.

Hinges also turn the glenoid with the roll of the shoulder, which an arm raised overhead twists by.

The trunk and its own girdles share one collision group (`ownGroup`). A girdle lies through neck and
torso by construction, and, hung on a collarbone, it is no longer one joint from the chest. The
engine skips bodies that one joint joins, and nothing else.

A girdle squeezed between two torsos is a shoulder through a body, and stops the turn as an arm
would. Verified by `trigid.nim`: every shoulder joint lies inside some capsule of its own body. Red
first at 90 mm outside.

## Walk and lift

**Turning is a path, walked a fiftieth of a turn at a time.** The hips of one dancer are spun for
200 engine steps in each moment (`walk.BEATS`, `STEP`), which is slow enough to stay quasi-static.
The arms are carried on by the engine. A pose at each moment is the pose before it, carried on, so
an arm that has gone round a body stays round it.

Joined hands rise from where each one settled at rest, to the lower edge of their band. They rise
along a ramp over the first quarter turn of wind (`RAISE`). They are held to the ramp from both
sides, because asked for the band outright a weightless hand crossed 359 mm in one moment. Risen,
the two edges of the band are held (`LIFT` 400 newtons per metre, `FALL` 40 damping it), and
everything between them is free. The band is a bound, and not a preference.

Asked over the crown, the hands are held to the torso band while the couple face each other. They
are held to the crown band from a quarter turn away, and blended between (`up`, `bandNow`,
`height`).

The Architect ruled on A9. That is the same-name chain wound half a turn from its pillion rest to
face to face, with the hands still over the heads. It was modelled but unnatural. The relaxed
position facing is hands at mid torso. Pillion or back to back are where they have to be above.
Facing, the arms naturally come down, and the swan may be reached only so, with one connection
straightening out as the arms come down.

`up` is how far the couple are from face to face, with whole turns folded away. So a couple wound a
whole turn have their hands down again.

Going up, the hands rise over her head. Coming back, they come forward off her crown first, to
between the two bodies, and then down (`leaving`, `over`). Let down straight from over the crown
they pass through her head. The rise from rest keeps a key of its own, which is the wind (`wound`,
`risen`). Rejected: that rise keyed to facing too. It let the hands down onto her head through the
second half of every whole turn.

Facing, a hand over the crown is a hold at some other height, as a hand under its band always was
(`FACING`). It has five centimetres of slack over the top of the torso band (`OVER`, assumed). Wound
arms press the hands up against the forty newtons of the lift. The same-name chain come round to
face to face sat at 1.37 to 1.39 m, against 1.35.

Asked at a lower band, the rise from where the hands settled over the first quarter turn of wind
stands as it was. It stands whole from the rest for a hold that rests pillion.

Verified by `trigid.nim`. `up` is nought face to face, and one from a quarter turn away, at every
wind of a turn and a half. The cross-name chain at rest and the same-name chain wound to face to
face hold with every joined hand in the torso band. A9 now stands at 0.76 m, with every hand between
1.23 and 1.35 m. It stood at 0.60 m, with every hand at 1.73 to 1.76. Red first.

Under this rule the diamonds no longer stand. With the hands asked to mid torso after a whole turn
they hold at no distance. The wind gives at a wrist, a twist or a hand under the crown band before
it comes round. Where it comes round, the pose left to stand gives too. With the hands left over the
crown they stood at 0.48 m.

Six centimetres of sag under the crown band instead of three stood neither, and that was measured,
so that margin is not it. The same-name chain come round to face to face stands one way about at
ease. The other way about, it stands a third of the way into the ease of a wrist at best. So the
corpus asks it either way, as its cards do.

One law says that the connections of a diamond cross twice, where the connections of an open hold
run clear. It now winds the couple there whether or not the pose holds, because what it claims is
the path. What the Architect describes, one connection straightening out as the arms come down, is
nothing the hold can do yet, and is the next question.

The lift and the draw are put on as muscle (`muscle`). That is torque at the shoulder, and at the
elbow that carries the wrist. The equal and opposite torque goes on the link inside, and the torque
of the shoulder goes on the girdle. They are never put on as force on a hand. Force on links alone
pulled the whole chain up through the shoulder, and dragged every girdle to the end of its rope.
Torque at the wrist too bent every wrist to its cone in the first moments of a rise, because the
hand is the lightest link.

What one arm carries its wrist with is capped at forty newtons (`MUSCLE`). That is the weight of the
arm itself, which a dancer lifts an arm against and plainly can, and it is assumed. Uncapped, a hand
twenty centimetres under its rise pulled with eighty.

Hands are drawn toward a point as they rise, weakly (`DRAW`, 40 newtons per metre at the torso and
neck, and 10 over the crown). Below the crown that point is between the two bodies. Over the crown
it is the axis of whoever turns. A couple setting a hold up put them there, and to pull both to the
midpoint spends the adduction that the turn wants.

What stops a turn is one thing, asked in order over every arm, held or free:

- swing past its range by more than `GIVE`;
- an arm through a body or through an arm (`Stop.Through`, `Stop.Arms`). A free arm crushed between
  two torsos is as much a stop as a held one;
- then, once the hands have parted by `PARTED`: which of twist, elbow or wrist sits at its end, what
  the arm was against, or reach;
- once risen, any joined hand further under the edge of its band than the slack of the lift itself
  (`SAG`, `Stop.Reach`). A hold whose hands never rose is a hold at some other height.

Verified by `trigid.nim`. Hands that are joined stay joined. No joint goes past what the rig allows
while the hold stands. Capsules move where the couple move. Between two moments, no point of any
held arm leaps more than the reach of an arm plus its own move. That is 193 mm on the corpus of the
laws.

## Stance and strain

**Where the couple stand is chosen for the turn, and every distance is tried.** The ruling of the
Architect: stand for the turn, hand height for the turn, everything for the turn. Nothing is fixed
but to keep the bodies apart.

Rejected: a stance chosen at rest, wherever the joints sit freest. The couple walk straight out of
it, and that stance turned 0.22, where 0.36 m turned 1.12.

Every distance from clear of each other (`CLEAR`) outward over a metre (`ROOM`) is swept whole, two
centimetres apart (`SEEK`). The measured landscape is plateaus four centimetres wide.

A card that asks whether the couple carry a turn (`reaches`) is answered at the first distance that
does. A sweep shown for its own sake (`furthest`) stands at the nearest distance that carries the
turn as far as any, to one step (`chosen`). It steps out only for a stance whose arms move less than
half as far between moments (`SMOOTHER`). It looks a tenth of a metre on once the turn runs free
(`LOOK`).

The nearest distance that carried a turn was chest to chest, with joined hands pinned between the
torsos and popping up between the heads. That is 189 mm in one moment at 0.36 m over the crown,
against 86 mm at 0.42, measured 2026-09-18.

To one step, because a stop is decided at the moment something gives, and mirror-image holds give a
moment apart from the same distance. Exact: L-l stood at 0.42 m for 1.00 of a turn at the neck, and
R-r at 0.38 m for 0.98.

Rejected: a tie broken toward the stance whose arms move least, within five millimetres. The
largest leap of a walk is chaotic. Seen in mirror it differs by up to a fifth. Built from the same
source by another compiler, it differs by up to thirty five per cent. That is 125 and 114 mm from
one distance, and 121 and 163 from another.

The last bits of two binaries differ, and the engine amplifies them. Five millimetres stood L-l at
0.44 m and R-r at 0.48 for one hold seen in mirror. That rule stands one hold two steps apart, built
twice.

Verified by `trigid.nim`. The sums measured that day, put to `chosen`, stand within one step in
three cases. Those are the mirror pair, the pair built twice, and the neck pair whose turn reached
differs by a step. The stance over the crown steps out from the pinned hands, to under half their
leap. Red first.

A still stands where its pose sits easiest. Every distance is wound to it, and the one nearest to
ease is kept. A distance at ease outright ends the search, and the nearer one keeps a tie. The first
distance that held was chest to chest. A couple asked pillion there had her free arm crushed between
two torsos. Her shoulder sat at the end of its rope, her twist at its end, and her waist at forty,
with nothing held.

Strain is read as the worst over every joint of every arm, both waists, and the two swings of every
collarbone (`strainOf`, `Strain`). It is nought outside every ease, one at some end, and more past
it. A stop with no ease costs nothing to lean on, and counts only past half a degree (`SLACK`). The
engine solves its limits rather than clamps them.

A still whose card fixes no way about is wound either way at every distance, and takes whichever way
sits easier (`either`). Those are the frames of the standard diagram turned half a turn, which draw
the same picture turned either way. The card claims a position and not a path. The single hold wound
the way asked stood at 0.48 m, with her twist a third of the way into its ease. The other way about
it stood at 0.36 m, at ease outright.

Verified by `trigid.nim`: the free way is never worse than the way asked, and is at ease. Red first.

Rejected: to rank distances on a cheaper physics and sweep only the winner. That costs a fifth as
much, and does not rank them the same. Verified by `trigid.nim`. No distance carries a turn more
than one step further than the one chosen, and the couple are never offered a place inside each
other. The mirror law holds turn reached within one step, and what stopped it exact.

**A still is wound, and not built.** A card that draws the couple at half a turn or a turn and a
half draws a winding of the arms. No facing says that. Built at the facing, the couple at a whole
turn stand exactly as at none. So the diamond read as the open frame, and the swan as the cross.
Every joined hand hung at hip height, because the lift had never started.

`walk.stood` turns the couple there from rest, at the pace of the walk itself, with the hands lifted
as they leave face to face. It then lets them stand, from the distance that sits easiest. Verified
by `trigid.nim`. A still asked past face to face has every joined hand in its band. The diamond
crosses where the open does not. Both red first.

## Asks of the reference

**The reference is asked of the model cell by cell, and the answer is a claim until the Architect
confirms it.** `design/asks.nim` is one list of what every still card asks: which hands, how far
turned, and whose crown the hands go over. `design/modelled` reads it, answers each one, and writes
`design/modelled.json`. `design/rig` reads it and records each still.

Moving cards ask whether the couple carry the turn under one manner of the four. An orbit is the
other dancer turned the other way about, so its sense is flipped, and hands are raised over whoever
walks under.

The page counts turns clockwise seen from above, and the sim anticlockwise. Every wind is flipped in
one place before it is asked (`asked`). Flipped for the chains alone, A16 was stood in the pose of
C5, and A17 in that of C3. That is the mirror of what each card draws.

Every single-hand and moving card was flipped likewise. The recorded stills showed it, because the
joint points of A16 matched those of C3 byte for byte. Verified by `suites/tasks.nim`: one picture
is one question whichever section draws it, A16 being C5 and A17 C3, red first.

The questions are answered on every core at once. Each worker lists the questions for itself and
builds its own worlds. The engine keeps its worlds in one table that it neither locks nor guards, so
to make and destroy them is locked in `sim/rigid` (`worlds`). Unlocked, two threads took one slot
for two worlds, and the verb died of an illegal instruction inside the engine every other run.

Every cell of the reference carries the tag of the sim beside that of the Architect. It reads *not
modelled* where the sim reaches no pose. It reads *unconfirmed* where the sim reaches one that the
Architect has not yet held against their own body on the viewer. It reads *modelled* only once they
have, by name in `CONFIRMED` beside `KEPT`.

A confirmation is of one still, so a confirmed cell whose still moves comes out of the list. The tag
sits outside every drawing and moves no pin. What the sim reaches today is counted off the built
page, rather than written here.

Two readings of section A come apart at A9 and A11, which draw the same-name pair face to face. Rule
31 of the project itself says that this position has its connections lying through each other. Wound
there from pillion as the card says, the model now stands them at ease, one connection over the
other. That is a finding against the reading of the rule, and not a number bent toward the page.

Sections B and E being whole is a weak result. Every card in them is over the crown, where a single
hold sweeps free past two turns, so they test the model hardly at all. The cards that discriminate
are the chains under wind.

## Rig viewer

**The viewer draws what the engine collides, beside the cell it answers.** `design/rig` records
every still and eight sweeps as capsule ends that the engine reports, at the radius it collides on.
`design/rig_page` lays every still cell of the built reference page beside the still of the sim for
it. That cell is the drawing, the badges and the caption, cut from the page itself, so what is
compared is what was ruled on. It is one list of entries, walked by two buttons or the arrow keys.
The drawing of the reference sits next to the joint readouts on the stage.

It is orthographic on purpose, so the outline of a capsule is exactly a stadium. Order is the
painter's, by depth. Each capsule is cut into pieces no longer than 40 mm, and each piece is ordered
by the depth of its own middle (`drawOrder`, `DAB`). A whole capsule ordered by its nearer end
painted an arm hanging from a shoulder over the torso all the way down. Its lower half showed
through the silhouette of the torso from near overhead, which is A5, the report of the Architect,
2026-09-18.

Hue is side, and shade is whose. Each body is lit from its own front (`litAt`, `mixHex`). The side
toward where the dancer faces is light, and the other side is dark. A body that faces the eye is
light all over.

The gradient runs square to each piece (`lightAcross`). Run along the facing as it fell, a torso
showed bands where the light end of one piece met the dark end of the next. So facing is read from
the body itself. The chevron on the floor and the line at shoulder height that said it before are
gone, because the Architect found them noise.

A capsule of no length, such as a palm, which is a sphere, is filled as a disc. It is not stroked as
a line of no length (`drawn`), because browsers disagree on what that is. Chromium draws the round
caps as a disc, and WebKit draws nothing. On the phone of the Architect every hand vanished, and
each forearm ended 118 mm short of the grip it was joined at. That was seen on A7 on 2026-09-18.

Verified by `suites/tdrawn.nim`. A capsule of no length is a disc. An arm hanging beside a torso is
painted behind it where it is behind. The front of each body is lighter than its back. Light runs
across each piece and never along it. The first two and the last were red first.

## Against the floor

**Against the floor, which is the Architect's.** The floor says that everything gets a whole turn
before it blocks, except a low wrap, which gets half. Nothing is tuned to it. Every change is argued
from the rig or from a ruling of the Architect. `sim/verdicts.md` prints what came out beside each
claim, so a mend and a regression are both seen.

Standing for the turn met seven of the eight single-hand claims of the floor, where standing at rest
met none. That is the strongest evidence so far that the floor was right and the model wrong, rather
than the other way about.

With bodies solid the crown is free both ways. Both low lock ways, and the cross-name high lock, go
past the whole turn of the floor by her wrist. The wraps stop between half and a whole turn, by her
twist or his wrist. Each disagreement is printed, and is the Architect's to rule on.

**Verdicts are an instrument run, assumed current.** `sim/verdicts.nim` asks the sim what the sheet
asks. It writes `sim/verdicts.md` in the words of the sheet, through one visible translation table,
wrapped at 100 columns. The chain rungs there are wound to, as stills are.

No test compares the committed record with the model. So it is current as of its last run, and stale
until it is run again. It is run again in the same delivery as any change to the model.

**Known and not mended: the crossing reader is a knife edge where two arms lie along each other.**
`read.crossings` counts where two connections cross in plan, by a segment intersection. Two poses
differing by less than the precision of a float have read as four crossings, and as one. That
happens when a crossing sits at a vertex of both polylines.

The verdicts tables and the diamond law read it on poses well away from that edge. To loosen its
tolerance six orders of magnitude changed no count on any kept chain card. A law that samples arms
laid along each other on purpose is owed, and the fold rule is repository issue 88.

## The swan

**The swan is the position the model does not reach, and its cause is measured this far.** No
distance holds a swan. The diamonds now stand nowhere either. That follows the rule that rests the
hands at mid torso facing, which the walk and lift section records.

The corpus law in `trigid.nim` holds every still it walks to a strain of 0.1 (`AT_EASE`). That is
two degrees of a twenty degree ease. It walks both chains from cross to cross, and the same-name
chain either way about at half. It walks the free frame pillion too, and the single hold at quarter
and half. It stops at the cross until the model reaches further. Every other still that holds stands
at ease, or within a fifth of an ease band at its worst joint, measured 2026-09-18.

They wind from every distance and give short. The cross-name gives at 0.74 to 0.88 of a turn, with
hands under their band or an arm against an arm. The same-name gives at 1.22 to 1.26, with an arm
against an arm, her collarbone retracted to its end, and her chest at forty.

The film of the wind shows why. From the cross on, her arms wrap round her head at the height of the
neck, rather than pass over it. Hands are carried at the lower edge of the band, a radius of a hand
over the crown. That leaves no room for a forearm to cross above the head.

Carried a hand's breadth higher, or on up through the band, the cross-name swan winds to 1.14 and
the same-name gives early by twist. Those lofts are assumed. The reference draws the two joins of
the swan at one point, one pair under the other. The two pairs of joined hands gathered together
over the crown that way winds the cross-name to 1.34, with her collarbone at its end.

Eight one-line changes on the lofted model were each measured on both swans at four distances, with
five held stills as control. None stands a swan. A stiffer grip and a finer step carry the
cross-name furthest, to 1.16 and 1.32, with hands parting or her wrist at its cone. A wider wrist
cone and a firmer draw carry the same-name furthest, to 1.42 and 1.38, arm against arm. A softer
collarbone, wider extension or a stronger loft lose a diamond.

Rejected outright: the arms of the lead passing through those of the follow. That reached the swan
by letting two arms occupy one place.

What the swan is in the body stays the open question below. The drawing of the reference itself puts
both joins at one point, with the right-over-left connection under. It reads as the extra turn
beyond the cross, which lives between two stacked pairs of hands that turn about each other. The
model has no hold that turns so.

## Pages and build

**Published titles say which pages the project stands behind.** The validator does, titled
`Dance Ontology — …`. Every other page is a mock-up or an instrument, and is titled
`Dance Ontology Mockup — …`. That is the line `CONTRIBUTOR.md` already draws between `pages/` and
`mockups/`. A gallery that holds both then says which is which before either one is opened.

The page of the body sim was the second that stood behind, and it went with the solver it drove. The
viewer that replaced it plays sweeps recorded here, and is titled as the exploration it is.

The name is spelt once, in `tools/title.nim`, and the mock-up form is derived from it (Article
II.1). `design/page.nim`, `tools/bundle.nim`, `tools/review.nim` and `design/wholecloth.nim` all
read it. Before this it was written twice, and drifting.

`tests/suites/tmarks.nim` and `tests/suites/treview.nim` assert that the built pages carry the
mock-up form and never the plain one. They assert it against the constant, rather than against a
repeated literal. **Verified**, by a break of the constant, and a watch of both suites failing.

Every title reads in title case, which `tests/suites/tmarks.nim` holds each page to. It reads the
title that the page was written with, rather than a list. Red first on the viewer, which shipped
with a sentence for a title while every page beside it was cased.

Rejected: to agree a project term for the two categories. That would have overloaded the `Artifact`
of the charter, which is a file a build writes under `build/`. It would otherwise have coined a word
for what `CONTRIBUTOR.md` already says in plain English.

Cost: the review page and the whole-cloth mock-up now hold a `{{title}}` marker instead of their own
names. To open either committed file no longer shows what the page is called. The name is one file
away, and the alternative was to spell it in four places.

**The browser comes from the environment, and the declaration says what to install.** `shot` drives
Chromium through Playwright. Both used to be named by absolute path in `design/shot.nim`, and one of
them with the build number of the browser inside it. That pins a version in the least durable place
there is (issue 62). Neither path is in the source now.

`tools/build.nim` declares `nodejs` and `chromium` as data, with what each one is for. A `system`
verb prints those names one to a line, for an installer.

`shot.nim` takes Playwright from `DANCE_PLAYWRIGHT`, or from the bare module name that node
resolves. It takes the browser from `DANCE_CHROMIUM`, then from `chromium` beside the store of
Playwright itself (`PLAYWRIGHT_BROWSERS_PATH`), and otherwise lets Playwright resolve what it
installed. Absent Playwright stops with a finding that names the verb that says what to install,
rather than as a missing file.

Rejected: to pin Playwright itself. It is a node package, and that would mean a `package.json`
beside its lock. That enrols the project in `koch check-types` and demands a `types` verb. The
Architect has asked not to have that work built while this half of the project may go.

Cost, stated rather than implied: **Playwright carries no pin here at all**, and the system packages
carry whatever version the machine has. Verified by a run of all four routes on this machine,
2026-09-08, Node 22 and Chromium 1194 of Playwright. Nothing set stops with the finding and exit 1.
`DANCE_PLAYWRIGHT`, `NODE_PATH` and `DANCE_CHROMIUM` each write the screenshots of both themes. A
path that names no browser fails loudly rather than silently. Not repeatable from a checkout: no
test drives `shot`, because the project carries no `drive` verb.

**URLs are listed once.** The URL of every published page is in the `README.md` of this project, in
two tables that carry the same split. `design/README.md` and `sim/README.md` point at it rather than
repeat it, as they used to (Article II.1). A page taken out of use keeps its URL and is not listed.
The repository does not treat a published copy as its record, because the log does that. Cost: a URL
is no longer beside the subsystem that builds the page.

**Hand-written pages are committed files, and everything a build emits is not.** The shell of the
validator is `pages/app/index.html`. The prose of the review page, with one marker for each derived
figure, is `pages/review/review.html`. The hand-drawn proposal is `mockups/wholecloth.html`.

`tools/build.nim pages` copies both shells into `build/`, and compiles the script of each page
beside it. It folds each one into a single file with `tools/bundle.nim`. It fills the markers of
review with `tools/review.nim`, and splices the two scripts of the mock-up with
`design/wholecloth.nim`. Generated pages stay uncommittable, because their lines run to thousands of
characters.

Tool binaries land in `bin/`, and pages under `build/`. The root ignore file covers both at any
depth, with test binaries beside their sources.

The 213 lines of inline JavaScript of the whole-cloth page were ported to the JS backend of Nim.
Rejected: to host markup in Nim string constants. That was forced while the repository read no
markup kind, and it cost one string-literal edit for every change of style.

Cost: `design/wholecloth.nim` checked its two markers at compile time while the markup was constant
(Article IV.4). Markup read at run time carries only a run-time check, which echoes the marker and
refuses to write a page without its data. Verified: `pages` run either side of the move writes the
same 22 files, with equal SHA-256 sums.

**Whole-cloth markup is held within width by the audit now, and not by a script.** Every line fits
100 runes except one, the Google Fonts request. That is one whitespace-free token of 179 runes on a
line of 202, and it passes on the unbreakable-token exemption.

Breaks fall only at whitespace that the rendering ignores. That is between tags, between attributes,
inside CSS, inside list-valued attributes (`d`, `points`, `class`, `style`), and inside `aria-label`
prose, whose whitespace the accessible-name computation collapses. One line of turn ticks holds no
such whitespace, so its character references are decoded to characters, which the parser does
anyway.

`reflow_wholecloth.py` applied those breaks while the markup was a Nim literal. It was a migration
tool, and it is not in the tree. Python is not a registered kind, and it is not wanted back, because
the form check now enforces directly what it enforced by hand. Cost: an edit that lengthens a line
past 100 runes is caught by the audit, rather than repaired by a script.

**The verbs of the project live in a compiled driver, because make is retired.** `tools/build.nim`
takes one command and runs it from the project directory. Each one is named and explained in the
table at the head of the file. They are the pages and their assets, the engine, and the four
recordings that rewrite committed data nothing else may edit (`modelled`, `rig`, `turns`,
`verdicts`). They are also the pins, the screenshot helper, the system declaration, and `clean`.
Koch drives the tests, and holds no verb for pages.

Rejected: a nimble task, which would put build logic in the virtual machine of the compiler.
Rejected: to ask koch for a verb specific to a project. Cost: the driver runs from the project
directory, because every path in it is relative. Each recording costs minutes, which is why none
runs under `pages`.

**Every page ships the three faces it draws with, inlined.** Titles take Noto Serif, body text takes
Noto Sans, and code and data take Commit Mono. Those are the standard three of the Architect, and
what Article X.8 names.

Labels drawn inside figures take Noto Sans rather than Commit Mono. The "code, data and figures" of
X.8 reads as numbers, and a label that names a hand is interface text.

Seven faces are fetched by the `assets` verb of `tools/build.nim` into `build/fonts`, and never
committed. Each one is pinned by package version *and* SHA-256. The version is pinned because an
unversioned path serves whatever the host resolves that day. The digest is pinned because the bytes
are embedded in what readers open.

`design/faces.nim` inlines them as data URIs, and `pages` dresses every page it wrote, once, after
every writer has run. To do it there rather than in each writer is what keeps the suites free of the
network. That is **verified**: every suite passes with `build/` deleted outright.

The origin of all seven is `@fontsource` 5.3.0, by way of `cdn.jsdelivr.net`. All are under the
**SIL Open Font License 1.1**, confirmed from the `LICENSE` of each package rather than assumed.

Their addresses and checksums are no longer this project's to hold. They are the `ASSETS` table in
`curator/audit/src/assets.nim`, which is the shared store of the repository. `assets` here names the
seven files it wants, and `koch fetch-assets` answers with their paths.

That is the settlement of repository issue 116, which this project raised as its second consumer.
Four of these seven were already pinned byte for byte by `rga_visualiser`. Article II.9 calls two
lists of identical digests a copy that no constraint forces.

**The digest is the curator's, and the choice is this project's.** The store never says which faces
a page draws with, so nothing about the autonomy of a project moved. This project was the first to
draw from it, and `rga_visualiser` draws from it too.

The store keys entries by digest, so a face arrives under a name that is its hash. `assets` restores
the file name on the way into `build/fonts`, because everything downstream reads faces by name.

Verified 2026-09-10. All seven arrive, and all seven carry the digest that the store declares. Every
built page is byte-for-byte the size it was when this project fetched them itself. To ask for a face
that the store does not declare fails with a finding that names it, which is checked rather than
assumed.

That check has to live in a suite, and not only in the build. This project carries no `drive` verb,
so the runner never runs its `assets`. A face named that the store lacks would otherwise surface
only when somebody built pages by hand.

`tfaces.nim` reads the declaration of the store as text, and holds every face named here against it.
It reads it as text rather than by import. The law then depends on the declaration, and not on the
module of the curator keeping its present shape. It also means that this project imports no curator
source, which none does.

Cost, measured 2026-09-10 on this container: **+224 kB for each page**. 167,424 bytes of woff2
become 224,384 of base64, across ten pages, so `build/` grows from 6.9 MB to 9.1 MB.

Rejected: to link the copy of the host, which names a face the reader may lack, and needs the
network at reading time. Rejected: to subset for each page, which trades one shared block for ten
that drift.

Commit Mono keeps its ligatures in `calt` rather than `liga`. That is **measured**, on both weights,
over 1932 glyphs in the latin subset. `calt` is on by default only until something sets
`font-variant-ligatures`, so the emitted sheet sets `contextual` at root, and no later reset can
lose them.

**What this changed in the drawings, and what it did not.** The label font is named inside the
figures, so every figure that carries a label changed its bytes. Of 516 figures across the six
pages, 495 are byte-identical, and 21 differ **only** by the font name. None differs in any other
way, so no geometry moved.

Those 21 were then read as pictures rather than as bytes. 97 labels were measured in a browser. None
sat outside its viewBox before or after, none was newly clipped, and the widest width change was 0.9
px. Verified by hand in Chromium 1194, 2026-09-10, against a before-and-after sheet of all 21.

The change worth naming is the one that is not visible in a diff. Those labels used to render in
whatever sans the machine of the reader carried. A card approved on one machine was a different
picture on another, which is the thing X.8 exists to stop.

## Kept answers

**The rig suite reads where the couple stand, and searches for nothing.** Each sweep, still and
`reaches` that a law asks is a search over every distance the couple may stand at. Its answer
changes only when the sim changes. So `sim/answers.nim` answers each search once, on every core,
and writes `sim/answers.json`, and `nim r tools/build.nim answers` runs it. The questions live in
`sim/answers.nim` too, so what is asked and what is answered are one list.

**Every pose and walk that a law holds is still made live.** Only where to stand is kept. A law
walks or stands the couple at the kept distance, with the code of the tree, and checks what the
sim does there. `walked` builds its own world, so it walks exactly what the search walked from that
distance.

**The kept answers are held to the tree in two ways.** The stamp is a digest of every `sim/*.nim`
and of the pinned commit of the engine. A law fails when the answers carry another stamp, so a sim
that changed and was not answered again cannot pass. And a law walks every kept sweep and two drawn
walks again, live, and asks for the same numbers. Verified by `trigid.nim`, suite "answers".

Each of those three laws failed on a break made on purpose. The breaks were a comment added to
`sim/vec.nim`, a distance moved off the grid by 1 mm, and a kept turn changed by one step.

**The laws that read answers fail when the answers are wrong.** Five breaks were made on purpose,
and each failed the law that reads it. A chosen turn was cut to 0.10, and a `reaches` was flipped.
A still was marked as not holding, a mirror distance was moved by 4 cm, and an answer was deleted.
Verified by `trigid.nim`, on 2026-09-24.

**The version of Nim is not stamped.** The verbs of `tools/build.nim` run the `nim` on the path,
and the suite runs the one that koch pins. A stamp with the version would agree on no machine
where the two differ. Answers from Nim 2.2.4 walked the same under 2.2.12, number for number, on
2026-09-24.

**The live walks run on every core at once.** They are the twelve ways of six sweeps and two drawn
walks. Each worker reads the holds as constants and gives back numbers alone (`Went`). A list of
strings and sequences read by four threads is what `design/modelled.nim` records dying of. Every
line the suite prints is the same as when they ran one after another. That run took 38.7 s, and
this one takes 28.6 s.

Cost: a change to any `sim/*.nim`, words included, asks for the answers again. That took 140 s on
four cores, compile included, on 2026-09-24. A digest of every file is one rule. A list of the
files that move the answers would be a second thing to keep true.

A change to comments alone gives the same answers and a new stamp. Two comments in
`sim/verdicts.nim` and `sim/words.nim` changed, and every answer came back the same number. Of the
last 40 commits to `sim/*.nim` on 2026-09-24, two changed comments alone. So a stamp that skips
comments would rarely save a run.

**The replay is exact on the runner too.** Its law passed there on `5975d93`, on 2026-09-24, so the
runner walks every kept sweep and both drawn walks to the numbers this container kept.

## Tests

**Testament over `tests/t*.nim` from the project directory, with five binaries.** `tengine.nim`,
`tread.nim` and `trigid.nim` link the C archive of the engine. `tsaid.nim` compiles to JavaScript.
`tsuites.nim` imports every other suite from `tests/suites/`, and each of them runs at import under
its own suite name. `trigid.nim` and `tread.nim` add `-d:danger`, because the sweeps are the slow
part and `doAssert` survives it.

**The suites that need no engine and no browser compile once.** Each binary compiled the standard
library and its own imports again. Sixteen of them compiled for 31.4 s and ran for 0.8 s, and all
nineteen took 62.4 s under testament. The one binary passes 209 laws, which is the sum that the
nineteen passed.

Joined, and with the pages built once, they take 18.5 s cold. That is 11.1 s of compile and 7.4 s of
running, and 7.1 s of the running is the page suite. Measured on 2026-09-24, on four cores of a
Linux amd64 container, with Nim 2.2.12.

**It builds in debug, because compile is most of a cold run.** The runner keeps no cache, so each
run compiles cold. Cold, on four cores on 2026-09-24, the debug build took 14.1 s to 16.4 s. A
`-d:release` build took 20.8 s, of which 19.1 s was compile. A release build keeps `doAssert`,
`assert`, bounds and overflow checks too, so the choice is about time alone.

`tasks` and `tlimb` were `-d:danger`, which drops bounds, overflow and `assert` checks. Here they
keep all three.

Not taken: to turn stack traces off. That took 11.2 s to 11.8 s cold, and it keeps every check. But
a test that fails on an exception it did not expect then prints no trace of where it came from.

**Every failure shows in one run.** `tsuites.nim` leaves out `-d:nimUnittestAbortOnError:on`, as
STYLE.md §6 asks, so a failing check does not stop the suites after it.

Cost: a suite under `tests/suites/` is not run alone by testament. It runs as part of `tsuites.nim`,
or alone by name as an argument to that binary.

**The review page counts the laws of every suite, joined or not.** It reads every `t*.nim` under
`tests/`, so a suite that moves into a folder is still counted. Verified by `suites/treview.nim`,
which counts the laws of each stub and of the suites it imports, and reads the page against them.

Test binaries inherit the working directory of testament. So `build/review`, `build/design` and
the `tests/` of the review page's count resolve only from the project directory. The runner of
koch runs testament there, and to run it from the repository root breaks them.

Cost: a model change that leaves a sweep with no moments crashes a danger build, rather than
reddens a law.

## Figures

- `trigid.nim`, danger build, on 2026-09-24, in one session on four cores. Its run took 385.1 s with
  every search, and takes 28.6 s reading kept answers. Under `nim r koch check` it took 40.76 s,
  compile included, and the whole of `koch check` took 110 s.
- `trigid.nim` on the runner, under testament, compile included: 43.71 s on `5975d93`, against
  503.91 s and 504.66 s with every search. The project job took 2 min 29 s in all.
- The whole of `nim r koch check`, with the kept answers and the joined suites: 57 s and 66 s, in
  two runs on 2026-09-24. `trigid.nim` took 30.4 s and 30.5 s of it, `tsuites.nim` 10.7 s and
  12.8 s, and `tread.nim` 9.3 s and 9.2 s.
- `trigid.nim`, danger build, under `nim r koch check`: 331 s wall. That is four Xeon cores
  shared with nothing else, on a Linux amd64 container, Nim 2.2.12, 2026-09-13. `tmarks` takes
  12.6 s, `tread` 7.9 s, and `tengine` 3.3 s. Every other suite is under 2 s. It is a single
  figure with no pair, so it is unmeasured as an optimisation.
- `tools/build.nim modelled`: 913 s wall, on the same machine and day, with two other recordings
  sharing its cores. Unmeasured alone.
- `tools/build.nim rig`: 523 s wall, on the same day, sharing cores with the suite. Unmeasured
  alone.
- `tools/build.nim verdicts`: 1079 s wall, on the same day, sharing cores with two other recordings.
  It took 50.2 s on 2026-09-10 with the pose search that preceded the engine. That is a pair across
  two models, and not an optimisation.
- `tools/build.nim pages`, every page with faces from the shared store: 26 s wall, same day.
- `tools/build.nim engine`: 24 s cold, and at once where the archive stands.
- Whole-cloth port parity, driven under Chromium with fonts stubbed and `requestAnimationFrame`
  replaced by a stepped queue on both pages: 707 states, 0 mismatches. The body outside the turns
  panel with whitespace collapsed, the head without title, and the full-body accessibility snapshot
  were equal at load. The markup and slider value of the panel were equal at load. They were equal
  for 6 holds by 3 levels, after the buttons, over 15 slider moments, on both exact blocks. That is
  324 panel states, plus 54 animation states. Those are 300 frames playing, 120 to rest, and 120
  after a strip-figure click, compared every ten.
- No console or page errors appeared on either page of the whole-cloth port. `grep -c nimCopy` on
  the emitted `wholecloth_turns.js` gives 13, all of them the runtime's own. None comes from module
  code, after five binding shapes were read and rejected, where 35 came before.

## Rules deferred

Declared unmet, so the Style row above stays true (Article VIII.1):

- VI.1: a few declarations in `sim/verdicts.nim` carried no doc when the driver moved. The ones
  touched since gained one, and the rest keep `## TODO: Document.` in spirit but not in text. Cost:
  a reader opens the body.
- X.2: banner tiers are unmarked, and every banner is spaced as second tier.
- VII.1: readings of emitted code exist for the whole-cloth port only. The validator and the viewer
  were written before the rule, and their binding shapes are unread. Cost: a copy in a hot path may
  hide there.

## Toolchain

**The compiler is pinned exactly, at the version this project was verified on.**
`requires "nim == 2.2.12"` in `dance_ontology.nimble`. It sat at 2.2.4 for two weeks, because 2.2.8
onward crashed the compiler itself on six of the suites, with
`field 'floatVal' is not accessible for type 'TFullReg' using 'kind = rkInt'`. That was recorded as
an upper bound that nobody had explained.

The cause was one line here, and not a fault of the release. `polylineLen` in `draw/route.nim` read
its float `result` with `+=` before anything assigned it. From 2.2.8 the virtual machine hands such
a result an int register, and then reads `floatVal` off it.

It bites only at compile time, and only where the function is reached in the VM. That is
`const SCENES = buildScenes()` in `draw/scene.nim`. So exactly the six suites that import the
umbrella module crashed, and the six that import `sim/`, `design/` or submodules did not.
`result = 0.0` first is the whole of it, and the line carries a comment saying why, because it reads
redundant and is not.

Verified here 2026-09-10, and not assumed. Five lines reproduce the crash with nothing from this
project: a `func` that accumulates into a float `result`, and is called from a `const`. It compiles
on 2.2.4 and crashes on 2.2.12 with that message. Before the mend, 6 of 12 suites crash on 2.2.12 in
2 m 28 s. After it, all 13 pass in 2 m 11 s, and the same 13 pass on 2.2.4.

Behaviour is unchanged, and that is measured rather than argued. Every one of the 22 pages that
`tools/build.nim pages` writes is byte-identical built with the line and without it. So no page
changes, and none is republished.

Verified by `suites/troute.nim`, which takes the length of a run in a `const`, so the compile-time
path has a law that names it. Without that, to tidy the line away would show up only as six suites
failing to build.

The diagnosis came from a sweep by a curator for stale versions, issue 106. Rejected: to stay on
2.2.4, which kept a bound whose reason lived in one sentence of this file. `result +=` on a float
survives in `sim/`, `design/` and `tools/`, none of which the VM evaluates today. That is latent,
and not urgent.

## Open questions

- **A crossing that has just arrived cannot carry its break, and five hundredths of a turn are drawn
  without one.** The third crossing enters through the end of a reach. So from 1.24 to 1.28 turns it
  sits between 0.0 and 4.2 along from that end, which is nearer than half a break. `gapFor` gives up
  rather than cut a gap narrower than the line it hides. Those frames draw two connections crossing
  with nothing saying which is over, against the standing rule that every crossing shows one.
- **Measured**: 5 of the 51 hundredths over the stretch, all of them at the arrival. Before this
  pass the same crossing went unbroken for 16 of them, because the fold hid it entirely. It is not
  obviously mendable by tuning. A crossing that enters through an endpoint is at the endpoint for
  some interval, whatever the construction.
- There are two choices. One is to let the break eat the end, which detaches the line from its
  hand. The other is to hold the crossing hidden until it can be broken, which means to trim the
  reach further, and that reaches every drawing. Left for the Architect to rule on.
- **The drawing does not yet build the chain the way the Architect describes it.** They danced the
  figure and stated the model. One connection **curls around** the other, and the other **hinges
  straight**. That is a right angle at the joined hands, which opens until the two forearms are in
  line. The drawing still gives every connection a sine swung about the axis of the pair, and takes
  the crossings from wherever two such curves meet.
- The count now behaves, as the third-crossing entry under Drawing chain says. So this is a question
  about whether the picture is built from the movement, or merely agrees with it at the positions
  checked. A prototype of the hinge-and-curl model gave the right counts, and drew shapes that are
  not a swan: two straight lines crossing in an X. It was scored before it was looked at. Anything
  that replaces the sine is drawn and looked at first.
- **What the swan is in the body.** The reference draws it pillion with all four hands above. Asked
  about a hammerlock, the Architect described a low one. The arm goes down, the shoulder rotates in
  as the hand goes behind the back, and the elbow bends behind to an L.
- Two questions decide the four still cards the model does not reach, and every moving card into
  them. Which one the swan over the crown is. Whether the extra full turn beyond the cross lives
  in the wrists and the hand hold, or in the arms wrapping each other. Asked.
- The drawing of the reference itself puts both joins at one point, with the right-over-left
  connection under. It reads as the turn living between two stacked pairs of hands. The hands of the
  model, carried at the edge of the band, wrap her arms round her head instead. The levers tried are
  recorded under the body sim.
- **Every still awaits the confirmation of the Architect against their own body.** They have said
  that many are wrong, and will say what is wrong with each, cell by cell on the viewer. The tags
  read *unconfirmed* until then.
- **The floor at the low and neck bands.** The wraps stop between half and a whole turn, by her
  twist or his wrist, where the floor says half or whole. The low locks go past the whole turn of
  the floor. Whether a hammerlock goes a whole turn, and what moves in the body when it does, is the
  Architect's.
- **The radius of the girdle, 60 mm, is an estimate and not tape.**
- **Two one-moment flips in the cross-name crown turn.** They are 370 mm as his arm straightens over
  at 0.28, and 220 mm as hers turns over at 1.18. Weightless links with springs this weak do that at
  no cost. The corpus of the leap law does not include that sweep, and says so.
- **The crossing reader at a knife edge**, with arms laid along each other, repository issue 88.
- **Whether the cards of section A are a question a body can be asked.** A9 and A11 draw the
  same-name pair face to face, which rule 31 says has its connections lying through each other. The
  model refusing them agrees with the rule.

**Open in the workbench, and on the side of the Architect.** Each one waits on a ruling, and the
workbench draws the current reading meanwhile.

- **Whether the "upper wrap" of rule 8 is the high wrap.** It is the one reading in the ledger that
  is not the words of a rule.
- **How far round the rim `SLOT_OFFSET` sets front and back from a side.** It is a drawn convention,
  and not something the dance says.
- **The mark for any amount of turn.** The sign page draws the candidates, and none is chosen.
- **Whether the turn sign is kept at all.** An orbit and an axis turn now differ as moves, and the
  frame pictures can show that as they move.
- **Whether `rotation.nim` holds a facing for each dancer.** `isFacing` reads only whether `twist`
  is even, so it cannot tell face to face from back to back. The two relative facings the drawing is
  built on are the pair the model would need.
- **Whether an arm carried past some limit is marked at all.** Nothing on the rim counts now, and
  the amount is where the hand sits.
- **The bow for contact with the body, the staff for sequences, what an orbit stores, and when an
  arm above the head blocks.**
- **How the crossing of a wrap with its dancer's other arm is drawn (rule 38).** Rule 22 keeps a
  settled reach away from that hand. So to draw it needs the other arm in the picture, and a ruling
  on how far rule 22 reaches. Until then a low wrap and a high one differ only by their fill.
- **Whether the model holds a modifier for each arm (rule 39).** The sheet gives either dancer up to
  one modified arm. The drawing holds one level and one way for each connection, and settles only
  the follow. That waits on whether the list in the sheet is the shape wanted. It is the same
  question as whether the variants of `Left to left` and `Right to right` that differ in which arm
  is over merge.
