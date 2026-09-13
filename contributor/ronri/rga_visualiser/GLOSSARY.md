# rga_visualiser

The words this project uses for itself: the parts of a drawn object, the states a pointer
can put it in, and the machinery that decides where each mark goes. Terms specific to this
visualiser only — the algebra's own vocabulary belongs to the `pga` library, and the
repository's words are in the top-level `GLOSSARY.md`.

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
What the algebra alone says about one object: its kind, where it stands, which way it
points, and the arms its disc is spanned by. The camera is not in it, which is why a
placement survives an orbit and is computed once rather than every frame.
_Avoid_: placed, derivation, resolution, geometry

**Revision**:
The forward-only counter saying that something changed, which anything cached checks instead
of comparing contents. A restore issues a fresh revision rather than reusing the one it
restores.
_Avoid_: version, generation, dirty flag, epoch

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
Anything drawn before it is committed: the object being edited, at the size it is being
edited, or the object an operation would produce from its operands.
_Avoid_: ghost, phantom, provisional, staged

**Outcome**:
What became of an object once drawn: finite, lying in the horizon, or nothing drawable at
all.
_Avoid_: placement, result, status, disposition

### Camera

**Pivot**:
The point the camera's orbit turns about.
_Avoid_: target, focus, centre, look-at

**Stance**:
Where the camera stands: its pivot, its distance, and its two orbit angles. The lens is not
part of it, because a reader's field of view is theirs and nothing aiming the camera may
rewrite it.
_Avoid_: placement, pose, position, state

### The front-ends

**Wording**:
One piece of text a front-end shows a reader: a tooltip, the words on a control, a sentence
saying what an action did. Every wording is named, and named once, so both front-ends show the
same words.
_Avoid_: string, label, copy, caption, blurb

**Front-end**:
One of the two things built from the shared geometry code: the browser page, or the desktop
application.
_Avoid_: target, backend, client, build

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

**Drawer**:
The sliding container of chrome: in from the right on a wide screen, up from the bottom on a
phone.
_Avoid_: panel, sidebar, sheet, tray

**Section**:
One collapsible part of the drawer — apply, objects, view, or diagnostics.
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
The diagnostics panel's periodic refresh of its readings, deliberately slower than the frame
and split by averaging window.
_Avoid_: update, poll, refresh, sample

**Band**:
The colour step a diagnostics row takes according to its share of the frame, from cyan at
nothing to orange at half a frame or more.
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
