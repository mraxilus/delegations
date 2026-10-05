# rga_visualiser

The words that this project uses for itself. They are the parts of a drawn object, the
states a pointer can put it in, and the machinery that decides where each mark goes. Only
terms specific to this visualiser belong here. The vocabulary of the algebra itself belongs to
the `pga` library, and the words of the repository are in the top-level `GLOSSARY.md`.

## Standards

The root glossary holds the default standards, and this project has selected none of its own.

## Language

### The scene and what is in it

**Object**:
One thing in the scene: a multivector, with a colour, a label, a drawn radius, and whether
it lights others. `scene[handle]` gives you one.
_Avoid_: item, entity, body, element

**Handle**:
The stable integer that addresses an object. It outlives the object in it, and is reused
once that object is removed.
_Avoid_: slot, index, id, key

**Kind**:
Which geometry a multivector stands for: a point, a line or a plane.
_Avoid_: shape, type, class

**Case**:
Which of a placement's seven readings holds, and so which of that placement's fields carry
meaning.
_Avoid_: variant, tag, kind

**Placement**:
What the algebra alone says about one object. That is its kind, where it stands, which way
it points, and the arms that its disc is spanned by. The camera is not in it, so one placement
serves every pass of its frame. Each frame computes it again for every object.
_Avoid_: placed, derivation, resolution, geometry

**Revision**:
The forward-only counter saying that something changed, which anything cached checks instead
of comparing contents. A restore issues a fresh revision rather than reusing the one it
restores.
_Avoid_: version, generation, dirty flag, epoch

### Origins

**World origin**:
The point the scene is stored about, where the axes cross. Every coordinate that the panel shows
or takes, and every saved file, is relative to it.
_Avoid_: reference origin, global origin, scene origin, absolute origin

**View origin**:
The point near the camera that a frame is drawn about. It follows the camera every frame, and
nothing stores it.
_Avoid_: camera origin, precision origin, floating origin, records origin, centre

**Model origin**:
The point an operation holds its operands about while it builds its result: a point of one of
its operands. Nothing stores it.
_Avoid_: operation origin, local origin, home, anchor

### Drawing

**Veil**:
A translucent fill: a plane's disc, or the whole-sky dome. A veil writes no depth, so veils
blend in the order they are drawn.
_Avoid_: wash, glaze, fill, translucent

**Marker**:
The outline drawn around a selected or hovered object, shaped to echo what it surrounds. Not
a mark, which is a line on a diagnostics chart.
_Avoid_: highlight, halo, indicator, selection ring

**Preview**:
Anything drawn before it is committed. That is the object under edit, at the size it is
edited at, or the object that an operation would produce from its operands.
_Avoid_: ghost, phantom, provisional, staged

**Outcome**:
What became of an object once drawn: finite, lying in the horizon, or nothing drawable at
all.
_Avoid_: placement, result, status, disposition

### Camera

**Motor**:
One rigid motion: a turn and a slide together, held as eight coefficients of even grade. A
motor carries a point, a direction or another motor, and two motors compose into one.
_Avoid_: transform, rotor, matrix, screw

**Pivot**:
The point the camera's orbit turns about.
_Avoid_: target, focus, centre, look-at

**Stance**:
Where the camera stands: one rigid motion, and one depth. The motion carries where the eye
is and which way it faces. The depth is how far along the sight the pivot stands. The pivot
and both orbit angles are read out of the pair. The lens is not part of it, because a
reader's field of view is theirs and nothing aiming the camera may rewrite it.
_Avoid_: placement, pose, position, state

**Free flight**:
How the camera reads with nothing selected. It turns about its own eye and travels along its
own axes, in six degrees of freedom. With a selection it orbits instead.
_Avoid_: fly mode, first person, free camera, unconstrained

**Local scale**:
The distance the frustum, the depth mapping and the furniture take their size from. It is the
reach from the eye to the nearest drawn object ahead, and the separation from the pivot where
nothing is drawn there.
_Avoid_: near reach, working distance, world scale, zoom level

### The front-ends

**Wording**:
One piece of text a front-end shows a reader: a tooltip, the words on a control, a sentence
saying what an action did. Every wording is named, and named once, so both front-ends show the
same words.
_Avoid_: string, label, copy, caption, blurb

**Shell**:
The committed markup of the browser front-end, carrying the tokens the build fills.
_Avoid_: template, skeleton, index

**Bridge**:
The Nim module the browser reaches every derived value through. A value not behind the
bridge is being computed in the wrong language.
_Avoid_: binding, glue, interop, api

**Page**:
The one self-contained file the build assembles out of the shell, the bridge, the scripts
and the faces.
_Avoid_: bundle, artefact, output, document

**Panel**:
The chrome a reader edits the scene and the camera through. On the desktop it is a window
beside the scene, and on the page it is the drawer.
_Avoid_: sidebar, pane

**Drawer**:
The panel of the page: a sliding container. It comes in from the right on a wide screen, and
up from the bottom on a phone.
_Avoid_: sidebar, sheet, tray

**Section**:
One collapsible part of the panel: apply, objects, view, or diagnostics.
_Avoid_: panel, tab, pane, accordion

### Editing

**Step**:
One entry on the undo timeline: the whole scene it produced, and where the camera stood when
it did.
_Avoid_: state, snapshot, checkpoint, undo entry

**Drag**:
A press, a move and a release from one object to another, applying an operation between
them. Moving the camera about is not a drag.
_Avoid_: gesture, stroke, sweep, swipe

**Operation**:
One entry in the catalogue a reader may apply: a join, a meet, a projection.
_Avoid_: action, command, transform, function

**Operand**:
A selected object feeding an operation.
_Avoid_: argument, input, parameter, source

**Arity**:
How many operands an operation consumes.
_Avoid_: count, degree, valence

### The demo, and the diagnostics

**Orrery**:
The built arrangement of the real solar neighbourhood, at one of three sizes, so the build
can be looked at under load.
_Avoid_: demo, sample scene, stress scene, fixture

**Tick**:
One pass in which the diagnostics take new readings. It runs slower than the frame, and each
reading is split by the window it averages over.
_Avoid_: update, poll, refresh, sample

**Band**:
The colour step that a diagnostics row takes, by its share of the frame. It runs from cyan
at nothing to orange at half a frame or more.
_Avoid_: bucket, tier, level, zone

**Exceedance**:
The curve reading how often a frame ran longer than a given time. A tail measure, not an
average.
_Avoid_: percentile, histogram, distribution

**Mark**:
A labelled line on a diagnostics chart at a known frame rate, drawn so a reading can be
placed against it. Nothing is held to a mark: the goal is as fast as possible, not a
budget. Not a marker, which rings an object in the view.
_Avoid_: budget, threshold, target, goal
