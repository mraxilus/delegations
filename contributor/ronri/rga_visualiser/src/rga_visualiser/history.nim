## Undo and redo over scene-content edits, as one timeline ring plus cursor.
##
## `Scene` and `Camera` are plain fixed-size value types, so recording step is value copy,
## not diff or inverse-operation log.
##   One ring holding whole timeline plus one cursor does both jobs.
##     Entry at cursor always equals live state.
##     Undo and redo move cursor and copy entry back out.
##     Fresh edit truncates redo-able future before appending.
##   `slotOf` is only place timeline position becomes array index.
##   Cost: `CAPACITY_HISTORY` whole scenes of fixed reservation; see that constant.
## Camera rides along, never moves timeline by itself.
##   Each step records where camera stood when its edit was made, so undoing construction
##   puts view back where it was made from.
##   Step's camera belongs to *edit*, not state: stepping off step and stepping back onto
##   it restore that one camera.
##     Restoring camera of state arrived at hands back view *previous* edit was made from.
##   First entry is exception: no edit leads into seeded state, so its camera is never
##   restored. Kept anyway, so `Step` means one thing everywhere.
##   Orbit is not own undoable step: camera gesture emits event per pixel, so recording
##   one needs settle rule, and timeline is about scene content.
##     Cost: accidental orbit is not undoable on its own.
## Scoped to discrete scene-content edits: add, apply-operation, remove, visibility
## toggle, ink recolour.
##   Not covered: live label editing and coefficient drags, continuous inputs with no
##   clean commit boundary; recording every keystroke would flood timeline.
##
## Shared by desktop (`visualiser.nim`) and browser (`browser_bridge.nim`) render paths.

{.experimental: "strictFuncs".}

import std/strformat

import ./[camera, scene]



#[ History Configuration ]#

const CAPACITY_HISTORY* {.define: "visualiser.history_capacity".} = 32
  ## Fix how many steps of timeline are retained.
  ##   Costs `CAPACITY_HISTORY * sizeof(Step)` of fixed reservation, and `Step` is whole
  ##   `Scene`, so this scales with `scene.ITEMS_MAX`: not cheap.
  ##     Largest reservation binary makes, counted by `visualiser.BYTES_MEMORY_TOTAL`;
  ##     figures in `PROVENANCE.md`.
  ##   Kept at 32: depth costs nothing per edit (see `record`), so what remains is flat
  ##   reservation, linear per step. One lever to pull if page must be lighter.
  ##   Settable beside `visualiser.items_max` and `visualiser.label_max`, so suite runs
  ##   once at defaults and once at capacities small enough that test reaches them, e.g.
  ##   `--define:visualiser.history_capacity=8`.

static:
  doAssert CAPACITY_HISTORY >= 2,
    &"History must hold an initial state and one edit; got `{CAPACITY_HISTORY}`."



#[ Type Definitions ]#

type
  Step* = object ## Define one committed edit: scene it produced, and where camera stood.
    scene*: Scene
    camera*: Camera ## Where view stood as *this* step's edit was made.
      ## Camera to restore in either direction across this step, not on arriving at its
      ## scene. First entry's is never restored: no edit leads into it.

  History* = object ## Define fixed-capacity timeline of steps, with cursor onto live one.
    ## Array is ring: `count` and `cursor` are timeline positions, `first` says which slot
    ## holds oldest, and `slotOf` alone relates them.
    ##   Dropping oldest step moves one integer; see `record`.
    entries: array[CAPACITY_HISTORY, Step] ## Snapshot per committed edit, in ring order.
      ## Reach one through `slotOf`, never by indexing directly.
    first: int    ## Array slot holding oldest step, timeline position 0.
    count: int    ## Valid timeline entries so far, <= CAPACITY_HISTORY.
    cursor: int   ## Timeline position of entry equal to live scene right now.



#[ Ring Indexing ]#

func slotOf(history: History, position: int): int =
  ## Report array slot holding step at `position` along timeline, 0 being oldest retained.
  ##   Every read and write of `entries` goes through here.
  ##     Position is not array index, and two must never be spelled same way.
  (history.first + position) mod CAPACITY_HISTORY



#[ History Editing ]#

func initHistory*(history: var History, scene: Scene, camera: Camera) =
  ## Start fresh one-entry timeline anchored at current state.
  ##   Call whenever scene is reset (program start, load, clear), so undo never reaches
  ##   earlier than tracking began.
  ##   Fills timeline caller holds, field by field.
  ##     Returning `History` deep-copies every retained scene on JS backend, and `Step`
  ##     literal copies scene twice; caller owning storage is Art. IV.6.
  ##   `camera` completes entry rather than being read back; see `Step.camera`.
  history.entries[0].scene = scene
  history.entries[0].camera = camera
  history.first = 0
  history.count = 1
  history.cursor = 0


func record*(history: var History, scene: Scene, camera: Camera) =
  ## Commit current state as timeline's new latest entry, discarding redo-able future.
  ##   Call once, right after edit settles.
  ##   `camera` is where view stood as edit was made; it never appends step of own.
  history.cursor.inc
  if history.cursor >= CAPACITY_HISTORY:
    # Retire oldest entry by advancing `first`, handing its slot to step about to be written.
    #   Shifting every entry down instead was one scene copy per retained step per edit.
    history.first = (history.first + 1) mod CAPACITY_HISTORY
    history.cursor = CAPACITY_HISTORY - 1
  # Copy scene once, field by field; see `initHistory`.
  let slot = history.slotOf(history.cursor)
  history.entries[slot].scene = scene
  history.entries[slot].camera = camera
  history.count = history.cursor + 1


func canUndo*(history: History): bool = history.cursor > 0
  ## Report whether earlier entry exists to undo back to.


func canRedo*(history: History): bool = history.cursor < history.count - 1
  ## Report whether later entry exists to redo forward to.


func undo*(history: var History, scene: var Scene, camera: var Camera): bool
  {.discardable.} =
  ## Move cursor one entry earlier and copy that entry's scene back out.
  ##   Camera restored is one step just undone was made from.
  ##   Reports whether earlier entry existed.
  ##   Scene and camera come from *different* entries on purpose.
  ##     Scene is earlier state; camera belongs to step being stepped off, view whatever
  ##     vanished was last visible in.
  ##   Caller holding camera tween abandons it after this, or standing aim carries view
  ##   straight back off restored placement.
  if not history.canUndo: return false
  camera = history.entries[history.slotOf(history.cursor)].camera
  history.cursor.dec
  # Restore through `restoreFrom`, never assignment: revision must pass every one drawn.
  scene.restoreFrom(history.entries[history.slotOf(history.cursor)].scene)
  true


func redo*(history: var History, scene: var Scene, camera: var Camera): bool
  {.discardable.} =
  ## Move cursor one entry later and copy it back into scene and camera.
  ##   Reports whether later entry existed. Same tween caveat as `undo`.
  ##   Both come from entry arrived at, same step `undo` reads its camera from, so
  ##   crossing one step either way puts view in same place.
  if not history.canRedo: return false
  history.cursor.inc
  scene.restoreFrom(history.entries[history.slotOf(history.cursor)].scene)
  camera = history.entries[history.slotOf(history.cursor)].camera
  true
