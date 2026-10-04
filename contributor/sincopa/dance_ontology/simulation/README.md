# The body simulation

Two bodies and their arms in a rigid body engine, and nothing else. This directory shares no code
with the ontology. It has its own `Arm` and `Body`, its own vector type, and it imports nothing
from `../src`. The notation is a shorthand for two people with arms of a given length, and a
shorthand cannot check itself. The simulation is what the notation is a shorthand for. It is kept
apart so that what it says is evidence, and not an echo.

It is not kept apart in its words. It uses the agreed words of the project where one fits, and
`GLOSSARY.md` holds the four that are its own: rig, pose, strain and block. It is a witness because
it imports no code and is told no answer. Where the simulation measures what the ontology states,
the translation is evidence and not identity. So `words.nim` holds that translation in one table,
and `verdicts.nim` uses it.

## What it is

The rig is two bodies of the average adult, with the joint ranges that a dancer uses without pain.
Every number is in `rig.nim`, with its source. Each body and each arm is a set of capsules in Box3D,
a rigid body engine that `tools/build.nim` clones at a fixed commit. There is no gravity, and the
arms weigh nothing. The question is where arms can be, and not what they weigh.

A joint resists as it comes near the end of its range, and does not stop at a wall. A turn is walked
a fiftieth of a turn at a time, and the engine carries the arms on. So an arm that has gone round a
body stays round it. Where the couple stand is chosen for each turn, and nothing is fixed except
that the two bodies stay apart.

Where the walk gives short, the turn is planned. The plan chooses every joint of both arms at each
moment, and keeps every capsule clear and every joint in its range. The engine then follows the
plan, and judges it as it judges a walk.

`PROVENANCE.md` records the design and the reason for each part of it. See Body rig, Rigid body
engine, Joints that give, Walk and lift, Stance and strain, and Planned turn.

## What it answers

- **How far a hold turns, and what stops it.** The simulation turns the hold until something gives,
  so the answer moves when the rig moves. No number is set by hand.
- **The pose at each moment of a turn.** It gives each joint, where the hands are, and which way
  each arm lies on its own body.
- **Which of two crossing arms is over.** It reads this from the drawn arms and does not assume it.
- **Whether a still holds, and where the couple stand for it.**
- **How the couple stand to each other.** It reads where each body sees the other, and `words.nim`
  names that facing among the sixteen.

`verdicts.md` is the record of what it answered. It prints each claim of the floor beside what the
simulation said, and nothing is tuned to make them agree.

## What it does not model

The two bodies are of one stature. In a walk, the couple stand at one distance for all of a turn,
so they do not step as they turn. In a planned turn, the follow steps as the plan does. The arms
weigh nothing. `PROVENANCE.md` gives the limits of the rig, joint by joint.

## Reading it

```
vector.nim   points, directions, and the two contact tests
rig.nim      every measurement, with its source
body.nim     two bodies standing and facing; where the shoulders are
limb.nim     one arm: forward kinematics, inverse kinematics, joint readings
contact.nim  arms against bodies and against arms, as geometry
hold.nim     what the couple is asked: which hands are joined, what may stop
engine.nim   the rigid body engine, bound; nothing above it knows it is C
rigid.nim    two dancers in that engine: capsules, joints, their ranges,
             and what stops a connection
walk.nim     a hold turned until something gives, from wherever the couple
             stand for that turn; whether a pose holds, whether a turn reaches;
             the engine steered along a planned turn
plan.nim     the arms of both dancers planned through a turn, moment by
             moment, as geometry, for the engine to follow
seen.nim     one sweep recorded whole -- every capsule, every joint -- for
             the rig viewer to draw
read.nim     what a pose says about itself, still in body words: crossings,
             lying, the tightest joint
words.nim    what the simulation reads, said in the agreed words, in one table
readings.nim what the report reads off the simulation, as plain numbers, on every core
verdicts.nim the simulation run as an instrument against the ontology's sheet
verdicts.json the readings it renders from, kept with a stamp of the physics
verdicts.md  what it said, translated once and generated, not edited
../tests/test_rigid.nim  the rig held to tape, geometry and the rows of the
             Architect's floor held above
../tests/suites/test_limb.nim  the tape's numbers and one arm's kinematics
../tests/test_read.nim   crossings read off the drawn arms, not assumed
../tests/test_plan.nim   the plan held to the engine: one place for each body,
             the mirror, a turn that keeps what it claims, and the engine on it
../design/rig_view.nim  the rig viewer, compiled to JS: every capsule the
             engine collides, and every joint beside its range
```

```
nim r koch test contributor/sincopa/dance_ontology  # the laws, with every other suite
nim r tools/build.nim pages       # every page, the rig viewer among them
nim r tools/build.nim modelled    # rewrite design/modelled.json: cards reached
nim r tools/build.nim rig         # rewrite design/rig.json: sweeps the viewer plays
nim r tools/build.nim turns       # rewrite design/turns.json: whole-cloth sweeps
nim r tools/build.nim verdicts    # rewrite verdicts.md: seconds for words, minutes for physics
```

## Running it

Run the laws before `nim r tools/build.nim pages`. A page that draws a model which has stopped
holding is worse than no page.

The search for where to stand costs time, and a plan costs more. The simulation walks the turn
again from many distances, two centimetres apart. A card that asks whether a turn is reached stops
at the first distance that reaches it. So an easy card costs one sweep, and only a card that nothing
reaches pays for the whole search. A card that no walk reaches is then planned. `PROVENANCE.md`,
Planned turn and Figures, gives what each planned card costs.

For that reason `modelled`, `rig` and `turns` each have a verb of their own, and their answers are
committed. So `pages` uses what was last recorded, and does not pay for it again. `modelled` and
`rig` keep a stamp of the physics with what they record, and record nothing again when it is the
same. `verdicts` keeps its readings in `verdicts.json`, with a stamp of the physics. So a change to
words renders the report again in seconds, and a change to the physics reads it again on every core.
A coarser physics does not rank the distances in the same order, so it cannot choose them.

## The rig viewer

The rig viewer plays the sweeps that `nim r tools/build.nim rig` records to `design/rig.json`.
`design/rig_page.nim` writes it to `build/design/rig.html`. It is an instrument, and not a page that
the project stands behind. Its address is in `../README.md`, with every other page the project
publishes.
