# The body sim

Two bodies and their arms, and nothing else. This directory shares no code with
the ontology next door: it has its own `Arm` and `Body` enums, its own vector
type, and it imports nothing from `../src`. That is the point of it. The
notation is a shorthand for two people with arms of a length, and a shorthand
cannot check itself — so this is the thing it is a shorthand *for*, kept apart
so that what it says is evidence rather than an echo.

It is not kept apart in its concepts. It reuses the project's agreed words
wherever one fits, and coins its own only where none does — the glossary holds
four that are its: rig, pose, strain and block. What makes it a witness is that
it imports no code and is told no answer, never that it speaks a different
language. The care needed is narrow: where the sim *measures* what the ontology
*asserts*, the translation is evidence, not identity, which is why
`verdicts.nim` still translates in one visible table rather than assuming.

## What it models

A body is a stack of three cylinders on one vertical axis — torso, neck, head
— each of the average adult's round, standing somewhere and facing some way.
The torso's section is an ellipse of its round, three quarters as deep as it
is broad, because a round section of a chest's girth stands three centimetres
too far out at the front, and the first thing a crossed hold does is lay a
forearm across a belly. The neck and head are round.

An arm is three rigid links — upper arm, forearm, hand to the grip — on a
shoulder that swings and twists, an elbow that bends, and a wrist that bends
any way. Every joint has the range a dancer will use without pain, cited to
the clinical tables, and **past a range is refused, with the joint named.**
The stretch before an edge is reported as *strain*, nought well inside and
one at the edge, so a pose near its limit is seen coming.

A connection is a grip: two hands at one point, which may be anywhere in the
band the hands are carried in — about the chest, about the neck, or over the
crown. Every link is a capsule as thick as an arm, and no link may pass
through either body nor through another arm; an arm may press on its own
body, as arms do.

**A pose is found, not drawn.** Given the shoulders and the grip, an arm has
three freedoms — which way the hand points off the wrist, and where the elbow
sits on the circle a two-link chain leaves it — and the sim searches them,
and the grip, for the most comfortable pose that holds: every joint nearest
its rest, the arms lowest, the grip between the two bodies on the line
between their centrelines, and at whatever height within its band leaves
the joints least constrained — the band is a bound, not a preference. The
search is a pattern search from a grid of seeds, and it is deterministic: the
same question gets the same answer.

**Turning is a path, not a pose.** From a rest that holds, a body is turned a
fiftieth of a turn at a time and the arms are carried on by small moves —
what a dancer's arms do. At every moment the pose is also sought afresh, and
taken where it is enough more comfortable to be worth the move *and the arms
can get there*: they go round the bodies the same way as before (read off how
far each arm sweeps round each body, below the crown) and cross each other the
same way. An arm that has gone round a body cannot get to a pose that has
not, however comfortable; that is what being wound is. Where no small move
holds and no reachable pose does, the turn is **blocked**, and the sim names
what fails a step beyond and whether a pose exists there that the arms
cannot reach.

A couple set a hold up for the turn they are about to do: of the few distinct
rests the search settles on, the sweep starts from the one that turns furthest
in a short trial each way, and a hand held over a head is held over the
turning partner's head.

## The numbers

Mixed-sex midpoints of ANSUR II medians, with the AAOS and NASA-STD-3000
ranges for the joints; every one is in `rig.nim` with its derivation.

| measure | value |
|---|---|
| torso round | 0.95 m: an ellipse 0.34 across, 0.26 deep; hip 0.80 to 1.36 m |
| neck round | 0.37 m; to 1.50 m |
| head round | 0.56 m; to 1.69 m |
| shoulders | 0.18 m out from the axis, 1.40 m up |
| arm | upper 0.31, forearm 0.25, wrist to grip 0.08: reach 0.64 m; radius 0.045 |
| shoulder | 45° behind the frontal plane; 45° across past the sagittal; twist 70° in, 90° out |
| elbow | 0 to 140° |
| wrist | a 60° cone |
| hands | chest 1.00–1.35, neck 1.40–1.50, crown 1.735–2.00 m |

The torso stops four centimetres under the shoulder joints, by the slope of
the shoulders, so a raised arm clears it. The crown band starts a limb's radius
over the head, so a hand there clears the head by construction.

## What comes out of it, rather than going in

- **Where a turn runs out**, and which joint or body stops it. Found by
  turning until something gives, so it moves when the arm or the torso does.
  Nothing holds the number.
- **The pose at every moment of the turn**: each joint's reading, where the
  hands are, which way each arm lies on its own body — across the front or
  behind the back, pressing it or merely carried there.
- **Which of two crossing arms is over**, read off the heights where the
  drawn arms cross in plan.
- **That a pair of hands binds at the half turn** at the chest and at the
  neck, and that one hand over the head turns without end either way.

`sim/verdicts.md` is the record, and it says where the sim agrees with the
floor and where it does not; the floor's claims are printed beside the sim's
answers and nothing is tuned to make them agree.

## What it will not say

The shoulder girdle is rigid: rolling a shoulder forward adds several
centimetres to a real reach and none here, so a wrap that a dancer gets by
that is refused a little early. The trunk twists at the waist, forty degrees
each way and sprung to square, and does not bend. The couple stand for each
turn wherever it carries furthest, from clear of each other outward, so a
stance is found rather than given and two ways of one turn may stand at two
distances; what they cannot do is step as they turn, or take a hammerlock's
own footwork. Every arm is there, held or free, and every capsule
of every arm meets every other body's, so a wrap going under or over the
*other* arm is what the engine says it is. The bodies are one stature. And a
torso is a stadium of its round, which is a tape's shape and not a chest's.

## Reading it

```
vec.nim      points, directions, and the two contact tests
rig.nim      every measurement, with its source
body.nim     two bodies standing and facing; where the shoulders are
limb.nim     one arm: forward kinematics, inverse kinematics, joint readings
contact.nim  arms against bodies and against arms, as geometry
hold.nim     what the couple is asked: which hands are joined, what may stop
engine.nim   the rigid body engine, bound; nothing above it knows it is C
rigid.nim    two dancers in that engine: capsules, joints, their ranges,
             and what stops a connection
walk.nim     a hold turned until something gives, from wherever the couple
             stand for that turn; whether a pose holds, whether a turn reaches
seen.nim     one sweep recorded whole -- every capsule, every joint -- for
             the rig viewer to draw
read.nim     what a pose says about itself, still in body words: crossings,
             lying, the tightest joint
../tests/trigid.nim  the rig held to tape, geometry and the Architect's floor
../tests/tlimb.nim   the tape's numbers and one arm's kinematics
../tests/tread.nim   crossings read off the drawn arms, not assumed
verdicts.nim the sim run as an instrument against the ontology's sheet
verdicts.md  what it said, translated once and generated, not edited
../design/rig_view.nim  the rig viewer, compiled to JS: every capsule the
             engine collides, and every joint beside its range
```

```
nim r koch tests contributor/sincopa/dance_ontology  # the laws, with every other suite
nim r tools/build.nim pages       # every page, the rig viewer among them
nim r tools/build.nim modelled    # rewrite design/modelled.json: cards reached
nim r tools/build.nim rig         # rewrite design/rig.json: sweeps the viewer plays
nim r tools/build.nim turns       # rewrite design/turns.json: whole-cloth sweeps
nim r tools/build.nim verdicts    # rewrite verdicts.md from the current model
```

`verdicts.nim` is where the sim's measurements meet the ontology's claims —
wrap, lock, low, high — and the translation happens in its report, in one
visible table. Not because the sim speaks a different language: it reuses the
agreed words. Because here it *measures* what the ontology *asserts*, and a
translation kept visible is evidence, where an assumed identity would be an
echo. The laws run under `nim r koch tests`; run them before
`nim r tools/build.nim pages`, because a page drawing a model that has stopped
holding is worse than no page. The floor's claims are read beside the sim's
answers in `verdicts.md`, and nothing is tuned to make them agree; where they
disagree the record says which, and `PROVENANCE.md` says what was done about
it.

What costs is the search for where to stand. A sweep is run whole at every
distance the couple may stand at, two centimetres apart from clear of each
other outward, and only the one that carries furthest is kept; a card asking
whether a turn is reached is answered at the first distance that reaches it,
so an easy card costs one sweep and only a card nothing reaches pays for the
whole search. Ranking distances on a coarser physics and sweeping only the
winner at full resolution was measured and rejected: it does not rank them
the same. The three recorders -- `modelled`, `rig`, `turns` -- are their own
verbs for that reason, and their answers are committed, so `pages` folds what
was last recorded rather than paying for it again.

The rig viewer is one of two pages the project stands behind, rather than a
mock-up: `design/rig_page.nim` writes `build/design/rig.html` from
`design/rig.json`, and its URL is listed with every other published page in
`../README.md`.
