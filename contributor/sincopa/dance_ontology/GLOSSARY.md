# dance_ontology

The words that this project uses for itself. The Architect agreed each one before it was
written. The language is proposed one theme at a time, and a term is written here only once
it is agreed.

## Language

**Lead**:
The dancer whose hands are named first, written capitalised.
_Avoid_: leader, man, he

**Follow**:
The dancer whose hands are named second, written in lower case.
_Avoid_: follower, woman, she

**Connection**:
A hand of the Lead that holds a hand of the Follow, named by the two hands, such as
`Left to right`.
_Avoid_: grip, link, contact, handhold

**Frame**:
The overall concept of connection between two dancers.
_Avoid_: embrace, shape, position, hold, state

**Frame hold**:
Which hands are connected.
_Avoid_: hold, grip, connections

**Frame position**:
The manner and orientation in which hands are connected. That is facing (face-to-face,
back-to-back, pillion lead, pillion follow), twist (quarter turns, clockwise or
anticlockwise), and shorthands such as over and under.
_Avoid_: orientation, manner, posture

**Facing**:
Which way the two dancers are turned with respect to one another. It is one of face-to-face,
back-to-back, pillion lead and pillion follow. Four states need two bits, so a twist parity
alone cannot say which of them a frame is in.
_Avoid_: orientation, direction, front

**Face-to-face**:
The facing where each dancer looks at the other.
_Avoid_: facing, front-to-front, opposed, closed

**Back-to-back**:
The facing where each dancer has their back to the other.
_Avoid_: reversed, apart, turned away, back to front

**Pillion lead**:
The facing where both dancers face one way with the Lead behind, so the Lead looks at the
Follow's back.
_Avoid_: face-to-back, same way, lead behind

**Pillion follow**:
The facing where both dancers face one way with the Follow behind, so the Follow looks at the
Lead's back.
_Avoid_: back-to-face, same way, follow behind

**Frame state**:
One specific unique instance of a frame hold and a frame position, grip aside.
_Avoid_: posture, configuration, instance

**Grip**:
The manner in which the Lead holds the hand of the Follow, such as a palm grip or a finger
grip. It is part of a frame position, but no frame state depends on it. Two frames that
differ only in grip are one frame state. It is defined so that the word is not overloaded,
and it is used for nothing here.
_Avoid_: hold, grasp, handhold, contact point

**Free**:
The frame hold with no hands connected.
_Avoid_: empty, neutral, apart

**Move**:
A change of exactly one connection.
_Avoid_: primitive, step, change

**Collect**:
The move that adds a connection.
_Avoid_: take, grab, catch

**Drop**:
The move that removes a connection.
_Avoid_: release, let go, flick

**Compound move**:
Two moves that a lead leads as one. They change which hands are held, and not how many.
_Avoid_: compound, combination, combo, macro, sequence

**Transition**:
A chain of moves from one frame state to another. Where several exist, the app offers the
shortest.
_Avoid_: route, path, sequence, walk

**Level**:
The height a connection is carried at: low, high or overhead.
_Avoid_: height, tier, zone

**Modifier**:
What a wound arm ends in: a wrap or a lock.
_Avoid_: blocker, decoration, variant

**Twist**:
Stored rotational tension between the pair, counted in quarter turns clockwise or
anticlockwise.
_Avoid_: wind, rotation, tension, turns

**Low**:
A connection held below shoulder level, about the torso.
_Avoid_: waist, hip

**High**:
A connection held above shoulder level, about the neck.
_Avoid_: chest, shoulder level

**Overhead**:
A connection held above the head, on the axis that the couple turn about. It is the one
level that carries no modifier, because there is nothing there to wind around.
_Avoid_: above, upper, top, crown

**Wrap**:
An arm crossed around the front of its own body, under its other arm when low, over it when
high.
_Avoid_: hug, coil, cuddle

**Lock**:
An arm bent behind its own back when low, or to the shoulder of the same arm when high. A
low lock is entered only from a low position, for safety.
_Avoid_: pin, twist, hammerlock

**Turn**:
A dancer who rotates, about their own axis or round their partner.
_Avoid_: rotation, spin, revolution

**Manner of turn**:
Which of the four ways the couple can turn. Two are the Follow on their own axis, and the
Lead on theirs. Two are the Follow in orbit of the Lead, and the Lead in orbit of the Follow.
Each one is a
dancer paired with an axis turn or an orbit. "Way" is kept for clockwise against
anticlockwise.
_Avoid_: way of turning, way, mode, style

**Clockwise**:
The way round that a turn goes when it goes the way the hands of a clock do, seen from
above. It is named from above rather than from either dancer, so it means one thing whichever
of them turns.
_Avoid_: cw, right, forward, with the clock

**Anticlockwise**:
The other way round, seen from above.
_Avoid_: acw, ccw, counterclockwise, left, backward

**Axis turn**:
A turn about the own axis of the dancer, while the partner stands still.
_Avoid_: axis, spin, pivot, solo turn

**Orbit**:
A turn walked round the partner. Whichever side faces the centre keeps facing it, so the
walker turns as far as they travel.
_Avoid_: circle, walk-around, revolution

**Compound turn**:
Two turns danced as one: an orbit with a counter-turn danced into it, so the walker keeps
their own bearing.
_Avoid_: compound, bearing-keeping orbit, locked orbit

**Chain**:
The seven arrangements that two held hands pass through under whole turns, a half turn
apart: swan, diamond, cross, open, cross, diamond, swan. It is a chain with ends, and never a
cycle.
_Avoid_: cycle, ring, ladder

**Open**:
The middle of the chain, where the pair is unwound.
_Avoid_: unwound, neutral, rest

**Cross**:
Half a turn from open, where the pair crosses once and the partners face the same way.
_Avoid_: x, half box

**Diamond**:
A whole turn from open, where the pair crosses twice with a diamond between.
_Avoid_: box, double cross

**Swan**:
A turn and a half from open, at either end of the chain. One connection is straight, and the
other snakes around it.
_Avoid_: double box, triple cross, coil

**Reference**:
The browser page that offers exactly the moves that the ontology derives, so a move it does
not derive cannot be danced.
_Avoid_: validator, app, demo, viewer

**Chevron**:
The mark at the centre of a dancer that says which way they face.
_Avoid_: arrow, nose, pointer, tick

**Rig**:
Every measurement that the sim stands on: rounds, heights, arm lengths, joint ranges and
hand bands, each one with its source.
_Avoid_: body model, skeleton, anthropometry

**Pose**:
Where every joint of a held arm is. A search finds the most comfortable arrangement that
holds, and nobody draws it by hand.
_Avoid_: posture, configuration, arm position

**Strain**:
How close the worst joint of a pose is to its limit: nought comfortable, one at the edge.
_Avoid_: stress, effort, discomfort

**Block**:
Where a turn stops because no small move holds and no reachable pose does.
_Avoid_: stuck, limit, failure


### Drawing

**Tower**:
Every frame hold stacked by how much is held, free at the foot and both hands at the head.
It fixes every axis that the drawings read down.
_Avoid_: lattice, graph, tree, ladder
