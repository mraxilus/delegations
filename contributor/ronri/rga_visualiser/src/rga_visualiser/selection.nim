## Hold which objects are picked right now, as ordered fixed-capacity list of slots.
##
## Order is whole point, and reason this is list rather than set.
##   Operation reads operands positionally, so first slot picked is `m` and second is `n`.
## Selection is deliberately not part of `Scene`: view of scene, not content.
##   Never saved to `.rgascene`, never recorded on undo timeline.
##   Restored snapshot clears it outright, since snapshot's slot numbers need not match
##   what was picked.
## Plain fixed-size value type with no refs, like `History` beside it.
##   Copying one is value copy, so it can live in GUI's own state struct without allocator.
##
## Shared by desktop (`visualiser.nim`) and browser (`browser_bridge.nim`) render paths.
##   Browser drives it through `browser_bridge`'s `nimSelect*` exports rather than parallel
##   list in JavaScript, so every rule about membership, order and arity is written once.

{.experimental: "strictFuncs".}

import std/options

import ./[marker, scene]



#[ Type Definitions ]#

type Selection* = object ## Define slots picked, in order they were picked.
  slots: array[ITEMS_MAX, int] ## Picked slots, oldest pick first; first `count` are live.
  count: int ## Slots picked so far, <= ITEMS_MAX.
  count_changes: int ## How many times membership or order has changed; see `revision`.



#[ Reading Selection ]#

func len*(selection: Selection): int = selection.count
  ## Count slots picked.


func revision*(selection: Selection): int = selection.count_changes
  ## Report how many times this selection has changed.
  ##   Front-end holding last frame's meshes compares this, never whole selection.
  ##     Two selections compared as values walk `ITEMS_MAX` ints, and copying one to
  ##     remember it is `ITEMS_MAX` more, per frame, whatever is picked.


func at*(selection: Selection, position: int): int = selection.slots[position]
  ## Read slot picked at position, oldest pick first.
  ##   Position 0 is operand `m`, position 1 is `n`; callers bound themselves against `len`.


func contains*(selection: Selection, slot: int): bool =
  ## Report whether slot is picked.
  for position in 0 ..< selection.count:
    if selection.slots[position] == slot: return true
  false


func impliedArity*(selection: Selection): Arity =
  ## Read arity selection implies.
  ##   One slot names unary operation's operand; two or more name binary operation's `m`
  ##   and `n`.
  ##   Two *or more*: picker offering `m` and `n` still acts on first two of longer
  ##   selection, and reverting to unary would silently drop second operand.
  ##   Empty selection implies nothing, and reports unary only because `Arity` cannot say
  ##   neither; callers check `len` first.
  if selection.count >= 2: Arity.Two else: Arity.One


func isAllHidden*(selection: Selection, scene: Scene): bool =
  ## Report whether every picked object is hidden.
  ##   Lets control acting on whole selection name what it would do: `show` where all
  ##   hidden, `hide` otherwise.
  ##   Rule about selection rather than about either object, so it lives here instead of
  ##   each front-end folding `isVisible` its own way.
  ##   Empty selection is not hidden: nothing there to show.
  if selection.count == 0: return false
  for position in 0 ..< selection.count:
    if scene.isVisible(selection.slots[position]): return false
  true



#[ Editing Selection ]#

func clear*(selection: var Selection) =
  ## Drop every pick.
  if selection.count == 0: return
  selection.count = 0
  inc selection.count_changes


func selectOnly*(selection: var Selection, slot: int) =
  ## Replace whole selection with one slot.
  if selection.count == 1 and selection.slots[0] == slot: return
  selection.slots[0] = slot
  selection.count = 1
  inc selection.count_changes


func toggle*(selection: var Selection, slot: int) =
  ## Add slot to end of selection, or drop it where already picked.
  ##   Appending is what makes order meaningful: two objects picked become `m` and `n` in
  ##   order picked.
  for position in 0 ..< selection.count:
    if selection.slots[position] != slot: continue
    for shift in position ..< selection.count - 1:
      selection.slots[shift] = selection.slots[shift + 1]
    selection.count.dec
    inc selection.count_changes
    return
  if selection.count >= ITEMS_MAX: return # Every slot already picked; nothing to add.
  selection.slots[selection.count] = slot
  selection.count.inc
  inc selection.count_changes


func pruneDead*(selection: var Selection, scene: Scene) =
  ## Drop every picked slot scene no longer holds, keeping rest in pick order.
  ##   Call after removing object: freed slot is handed straight to next add, so stale
  ##   pick would silently reattach to unrelated new object.
  var kept = 0
  for position in 0 ..< selection.count:
    if not scene.isAlive(selection.slots[position]): continue
    selection.slots[kept] = selection.slots[position]
    kept.inc
  if kept == selection.count: return
  selection.count = kept
  inc selection.count_changes



#[ Pulse Clock ]#

const SECONDS_STEP_PULSE_MAX* = 0.1
  ## Treat any gap longer than this as absence rather than frame, for pulse.
  ##   Six frames at sixty per second: long enough that no honestly slow frame is clipped,
  ##   short enough that tab returning from background does not hand comet whole minute
  ##   of travel in one step.


type PulseClock* = object ## Define each selected object's orientation pulse between frames.
  ## Travel in screen pixels per slot, integrated and reduced, not position computed from
  ## clock. Two faults decided this; second is why units are pixels, not fraction.
  ##   Phase read off time meant `frac(now·speed ÷ around)`, and outline's length changes
  ##   whenever camera moves: after few laps one-percent change in length throws answer
  ##   most of lap and comet teleports.
  ##   Carrying phase across frames fixed that, but phase is *fraction of outline measured
  ##   this frame*, turned back into position by current length from current first point;
  ##   for line both are viewport-clip artefacts, so head still slid under camera.
  ##   Carried now is distance travelled from outline's anchor, in pixels, advanced by
  ##   `speed·seconds` with no camera quantity in advance, so fixed screen pace is true by
  ##   construction.
  ## Travel is reduced into current lap every frame, load-bearing.
  ##   Unbounded travel read as `travelled mod lap` amplifies one-percent change in lap by
  ##   laps accumulated, first fault in new units.
  ##   Reduced each frame amplification is exactly one; only discontinuity left is lap
  ##   arriving up to one frame's shrink early.
  ## Plain fixed array, like `Scene` and `MeshSet`, not arena allocation.
  ##   One float per slot with compile-time bound and program-long lifetime needs no arena
  ##   (see `arena.nim` header).
  ##   Not double buffered either: update reads and writes one slot and consults no
  ##   neighbour. `arena.nim` is desktop-only in any case.
  ## Here rather than `marker.nim` because indexed by *slot*, over exactly selected set,
  ## which is view of scene this module already is.
  travels: array[ITEMS_MAX, float] ## Each slot's travel along its marker's outline.
    ## In screen pixels from outline's anchor, always reduced below one lap.
  seconds_last: Option[float] ## Clock reading `tick` last saw, for step between frames.


func tick*(clock: var PulseClock, now: float) =
  ## Take frame's clock reading, so `advance` knows how long step was.
  ##   Call once per frame, before advancing any slot.
  ##   First call establishes reading and advances nothing.
  clock.seconds_last = some(now)


func secondsStep*(clock: PulseClock, now: float): float =
  ## Report seconds passed since reading `tick` last took.
  ##   Zero before first tick and for step that ran backwards, which caller restarting
  ##   clock can produce and no pulse should answer by rewinding.
  ##   Capped at `SECONDS_STEP_PULSE_MAX`.
  ##     Longer gap is backgrounded tab or moved clock, and carrying it would land comet
  ##     somewhere arbitrary, teleport this clock exists to prevent.
  if clock.seconds_last.isNone: return 0.0
  min(SECONDS_STEP_PULSE_MAX, max(0.0, now - clock.seconds_last.get))


func advance*(clock: var PulseClock; slot: int; lap, seconds: float) =
  ## Carry one slot's pulse forward by pixels `seconds` is worth, reduced into `lap`.
  ##   `lap` is what marker just shaped measured (`Marker.lap`) and enters only reduction,
  ##   never step: step is `SPEED_MARKER_PULSE*seconds` whatever camera does.
  ##   Reducing here keeps carried travel below one lap; see type's doc for why that is
  ##   load-bearing.
  if slot < 0 or slot >= ITEMS_MAX: return
  clock.travels[slot] = travelAdvanced(clock.travels[slot], lap, seconds)


func travelAt*(clock: PulseClock, slot: int): float =
  ## Read one slot's pulse travel, in screen pixels from outline's anchor.
  if slot < 0 or slot >= ITEMS_MAX: 0.0 else: clock.travels[slot]


func forget*(clock: var PulseClock, slot: int) =
  ## Send slot's pulse back to start of its lap.
  ##   Call where slot is handed to fresh object, so new selection begins comet at head
  ##   rather than inheriting wherever since-removed object had got to.
  if slot < 0 or slot >= ITEMS_MAX: return
  clock.travels[slot] = 0.0
