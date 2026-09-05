# dance_ontology

The frames a couple can hold in partner dance and the moves between them, as one executable
model with a body simulator that witnesses what the notation claims.

## Language

**Frame**:
What each of the lead's hands holds and how the arms lie where they overlap; the model's one
state, named for the hands it holds.
_Avoid_: position, hold, pose, state

**Free**:
The frame with nothing held: four free hands, and the one frame nothing has to lead up to.
_Avoid_: open, empty, neutral

**Connection**:
A hand of the lead holding a hand of the follow, named by the two hands, e.g. `Left to
right`.
_Avoid_: grip, link, contact, handhold

**Primitive**:
A change of exactly one connection, in one of two directions: a collect or a drop.
_Avoid_: transition, step, action

**Collect**:
The primitive that adds one connection; drawn climbing the tower.
_Avoid_: take, grab, catch

**Drop**:
The primitive that removes one connection; drawn falling down the tower.
_Avoid_: release, let go

**Compound**:
Two primitives a lead thinks of as one move, named `place` or `cut`; changes what is held
without changing how much.
_Avoid_: combo, macro, sequence

**Move**:
What exists between two frames exactly when their difference is one primitive; the model's
one relation.
_Avoid_: edge, transition, arrow

**Route**:
The shortest chain of moves from one frame to another, named a step at a time against the
frame each step leaves.
_Avoid_: path, sequence, walk

**Tower**:
The drawing of every frame stacked with `free` at the foot and both hands held at the head,
which fixes every axis the pictures read down.
_Avoid_: lattice, graph, tree

**Level**:
The height a connection is held at: low, high or above; never which arm lies over which.
_Avoid_: height, position, tier

**Low**:
Held below the shoulder, about the torso.
_Avoid_: waist, hip

**High**:
Held above the shoulder, about the neck.
_Avoid_: chest, shoulder level

**Above**:
Held over the head; the one level with no lock and no wrap, where a hand turns without end.
_Avoid_: overhead, upper, top

**Wrap**:
An arm crossed around the front of its own body, under (low) or over (high) the other arm.
_Avoid_: hug, coil, cuddle

**Lock**:
An arm bent behind its own back (low) or up to the shoulder of the same arm (high); a
hammerlock.
_Avoid_: hold, pin, twist

**Axis turn**:
A dancer turning about their own axis, the partner standing still.
_Avoid_: spin, pivot, solo turn

**Orbit**:
A dancer walking round the partner, keeping whichever side faces the centre facing it, so
they turn as far as they travel.
_Avoid_: circle, walk-around, revolution

**Compound turn**:
An orbit walked while counter-turning, so the walker keeps their own bearing; the sum of an
orbit and an axis turn.
_Avoid_: bearing-keeping orbit, locked orbit

**Wind**:
How far two held arms have twisted about the pair's axis, measured off the hands, never
handed over; what a whole turn leaves behind.
_Avoid_: twist count, wrap count, turns

**Chain**:
The seven positions two held hands pass through under whole turns: swan, diamond, X, the
frame, X, diamond, swan; a chain with ends, never a cycle.
_Avoid_: cycle, ring, ladder

**X**:
The position half a turn from unwound, where the pair crosses once with the partners facing
the same way.
_Avoid_: cross, half box

**Diamond**:
The position a whole turn from unwound, where the pair crosses twice with a diamond between.
_Avoid_: box, double cross

**Swan**:
The position a turn and a half from unwound: one connection straight, the other snaking round
it.
_Avoid_: double box, triple cross

**Lead**:
The dancer whose hands are named first, drawn at the bottom facing up, whose arms collect
and drop; marks are squares in the deep shade.
_Avoid_: leader, man, he

**Follow**:
The dancer whose hands are named second; marks are circles in the plain shade.
_Avoid_: follower, woman, she

**Workbook**:
The owner's spreadsheet `ontology.partnerwork.xlsx`, whose `base` sheet names the states and
cells and whose `vocabulary` sheet names the moves; held as data and audited, never trusted.
_Avoid_: spreadsheet, sheet, source of truth

**Base sheet**:
The workbook sheet whose rows are states and whose cells name the move between two states.
_Avoid_: matrix sheet, main sheet

**Vocabulary sheet**:
The workbook sheet whose words name the primitives and mark the compounds with an asterisk.
_Avoid_: glossary sheet, terms sheet

**Validator**:
The browser page that offers exactly the moves the ontology derives from the frame held, so a
move the model does not derive cannot be danced.
_Avoid_: app, demo, viewer

**Review page**:
The generated page saying what the workbook says and what is outstanding, every figure and
picture derived from the model.
_Avoid_: report, findings page, audit page

**Ledger**:
The forty rules for the drawing, in the words they arrived in, held as data and mirrored
entry for entry in the workbench's README.
_Avoid_: spec, requirements, rulebook

### Body sim

**Rig**:
Every measurement of the average adult the sim stands on: rounds, heights, arm lengths, joint
ranges, hand bands, each with its source.
_Avoid_: body model, skeleton, anthropometry

**Body**:
A stack of three parts on one vertical axis, torso, neck and head, standing somewhere and
facing some way; the torso an ellipse of its round.
_Avoid_: dancer, figure, character

**Pose**:
Where every joint of a held arm is, found by search as the most comfortable arrangement that
holds, never drawn by hand.
_Avoid_: posture, configuration, arm position

**Grip**:
The point where two held hands meet, anywhere within the band the hands are carried in.
_Avoid_: connection, hand position, contact point

**Band**:
The range of heights a grip may be carried in: torso, neck or crown; a bound, never a
preference.
_Avoid_: level, zone, layer

**Strain**:
How far into the last stretch before a joint's edge the worst joint of a pose is, nought
well inside and one at the edge.
_Avoid_: stress, effort, discomfort

**Sweep**:
A body turned a fiftieth of a turn at a time from a rest that holds, the arms carried on by
small moves, until something gives each way.
_Avoid_: rotation, scan, simulation run

**Moment**:
One turn of a sweep with the pose the arms carry to it.
_Avoid_: frame, step, sample

**Blocked**:
Where a sweep stops because no small move holds and no reachable pose does, named for what
refuses a step beyond.
_Avoid_: stuck, limit, failure

**Re-organised**:
A pose that exists a step beyond a block but that the arms cannot reach from where they are,
because it goes round a body the other way.
_Avoid_: found anyway, alternative pose

**Verdict**:
What the sim says about one question the ontology's sheet asks, translated once into the
sheet's words and recorded in `sim/verdicts.md`.
_Avoid_: result, answer, finding

**Stance**:
Where the two bodies stand and face; the sim page chooses the distance apart that leaves
the joints the most room, never closer than ten centimetres of air between the torsos.
_Avoid_: distance, spacing, position
