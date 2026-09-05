# The body sim

Two bodies and their arms, and nothing else. This directory shares no code and
no vocabulary with the ontology next door: it has its own `Arm` and `Body`
enums, its own vector type, and it imports nothing from `../src`. That is the
point of it. The notation is a shorthand for two people with arms of a length,
and a shorthand cannot check itself — so this is the thing it is a shorthand
*for*, kept separate so that what it says is evidence rather than an echo.

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
that is refused a little early. The trunk does not twist or bend. The couple
never step apart: every question is asked at one stance, and a hammerlock is
danced closer than it. A free arm is not there at all, so whether a wrap goes
under or over the *other* arm cannot be read for a one-hand hold. The bodies
are one stature. The search is local: a block is reported with whether any
pose exists a step beyond, and a pose that exists but was not found would
show there as *re-organised*. And a torso is an ellipse of its round, which
is a tape's shape and not a chest's.

## Reading it

```
vec.nim      points, directions, and the two contact tests
rig.nim      every measurement, with its source
body.nim     two bodies standing and facing; where the shoulders are
limb.nim     one arm: forward kinematics, inverse kinematics, joint readings
contact.nim  arms against bodies and against arms
solve.nim    a pose evaluated, seeded, refined, settled; routing
sweep.nim    turning, moment by moment, until something gives
read.nim     what a pose says about itself, still in body words
draw.nim     a state as two pictures: from above, and from the side
page.nim     the browser page, compiled to JS: a hold, a level, and a
             quarter turn at a time by buttons, on axis or in orbit; each
             quarter is carried the same way and stops where the arms do,
             and the couple stand wherever the joints have the most room
../tests/tlaws.nim  what the model is held to, all of it about bodies and arms
verdicts.nim the sim run as an instrument against the ontology's sheet
verdicts.md  what it said, translated once and generated, not edited
shell.nim    the page's shell and style, hosted in Nim; written out by `make pages`
```

```
make check          # the laws, with every other suite, from the project directory
make pages          # the page, into build/sim/
make verdicts       # rewrite verdicts.md from the current model
```

`verdicts.nim` is the one place the sim's answers meet the ontology's words —
wrap, lock, low, high, above, led — and the translation happens in its report,
in one visible table, so the model itself stays vocabulary-free. The laws run
under `make check`; run it before `make pages`, because a page drawing a model
that has stopped holding is worse than no page. The floor's claims are a suite of their
own that only asserts they are *decided*; `-d:floorIsLaw` makes them hard.

The solver is built to be asked millions of times a sweep without the answers
depending on it. What a state has that no evaluation changes -- each body's
axes, its parts' sections and height bands, its shoulders -- is worked out
once into a `Scene` and handed down; a seed is tried reach first, then joint
by joint with the dear twist last, then by cost, and only then against the
bodies, giving up at the first refusal, which is the same verdict `evaluate`
reaches in full; a trial pose in the pattern search is one number changed in
place and put back; and every pose the sweep carries is carried with the
verdict that found it. Sweeps of different holds share nothing, so
`sweptAll` runs them side by side on the cores there are, in a fixed order.
None of it moves a number: the laws, `verdicts.md` and the whole-cloth page's
`turns.js` come out byte for byte as they did when all of it was done the
plain way, and that is the test of any change here.

Published at <https://claude.ai/code/artifact/2944bc6a-551e-4b86-a258-7df1bfa83629>;
republishing `build/sim/artifact.html` to that URL is the whole release step.
