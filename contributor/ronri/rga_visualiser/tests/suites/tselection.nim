## Run `Selection` suite: one module of shared suite, which `../suites.nim` imports in order.

import ./fixtures


suite "Selection":
  proc ordered(selection: Selection): seq[int] =
    ## Read whole selection out in pick order.
    ##   Test can then state order it expects in one line rather than indexing position
    ##   by position.
    for position in 0 ..< selection.len: result.add(selection.at(position))


  test "a pulse covers the same ground however many frames it is cut into":
    # Frame-rate independence, which is whole reason travel advances by elapsed.
    #   seconds rather than by step frame. Driven on browser too: 3 s of clock
    #   moved head 178.3 px at 36 fps, 179.0 at 60 and 179.6 at 144, against 180.
    proc travelAfter(seconds_total: float, frames: int, lap: float): float =
      var clock: PulseClock
      var seconds = 0.0
      clock.tick(seconds)
      for _ in 0 ..< frames:
        seconds += seconds_total/float(frames)
        let step = clock.secondsStep(seconds)
        clock.tick(seconds)
        clock.advance(0, lap, step)
      clock.travelAt(0)

    # One second at shared speed is `SPEED_MARKER_PULSE` pixels, whatever it laps on.
    for frames in [12, 60, 144, 600]:
      check travelAfter(1.0, frames, 900.0) =~ SPEED_MARKER_PULSE

    # **And same pixels on short outline as on long one.** This is what units.
    #   buy and what phase could not: phase advanced by `speed/around`, so one second
    #   bought three times share of 300-px outline that it bought of 900-px one,
    #   and head's screen pace was whatever camera had most recently made
    #   outline. Comet is supposed to travel at speed, not at lap time.
    check travelAfter(1.0, 60, 300.0) =~ travelAfter(1.0, 60, 900.0)

  test "a pulse ignores an absence, rather than travelling all of it at once":
    # Backgrounded tab stops its animation callbacks; gap it comes back with is not.
    #   frame, and spending it in one step would land comet anywhere.
    var clock: PulseClock
    clock.tick(0.0)
    check clock.secondsStep(1.0/60.0) =~ 1.0/60.0
    check clock.secondsStep(90.0) =~ SECONDS_STEP_PULSE_MAX
    # And clock that ran backwards rewinds nothing.
    check clock.secondsStep(-5.0) == 0.0

  test "each handle keeps its own pulse, and a reused handle starts afresh":
    var clock: PulseClock
    clock.tick(0.0)
    # Step is read before tick that consumes it, which is order both frame.
    #   loops use: one reading, then every handle advanced by it.
    let step = clock.secondsStep(1.0)
    clock.tick(1.0)
    clock.advance(3, 600.0, step)
    check clock.travelAt(3) > 0.0
    check clock.travelAt(4) == 0.0 # Untouched, so still at head of its own lap.
    clock.forget(3)
    check clock.travelAt(3) == 0.0
    # Out of range is question with no answer, not crash.
    check clock.travelAt(-1) == 0.0
    check clock.travelAt(OBJECTS_MAX) == 0.0
    # And carried travel is kept below one lap rather than accumulating, which is what.
    #   stops change in lap being multiplied by however many laps have gone by --
    #   original teleport, which unreduced pixel offset would have reproduced.
    var carried: PulseClock
    carried.tick(0.0)
    for frame in 1 .. 600:
      let seconds = float(frame)/60.0
      let step = carried.secondsStep(seconds)
      carried.tick(seconds)
      carried.advance(0, 120.0, step)
      check carried.travelAt(0) < 120.0


  test "every operator reads in the library's own symbols, not an ASCII stand-in":
    # Drag used to name what it built with `^`, `v` and `->` while panel named.
    #   same pair with catalogue's symbols, so one object list carried both.
    check notationSubstituted(Operation.Wedge, "a", "b") == "a ∧ b"
    check notationSubstituted(Operation.WedgeAnti, "L", "G") == "L ∨ G"
    check notationSymbolic(Operation.Wedge) == "𝐦 ∧ 𝐧"
    # Picker offers symbols alone; English name after them is what made.
    #   popover wider than hand can reach.
    for operation in Operation:
      check not notationSymbolic(operation).contains("  ")
    # Drag wedges carry that same picker text, so wheel and picker are one.
    #   vocabulary rather than two reader has to map between. Words survive only
    #   where three are *taught*, in drawer's own legend, which prints both.
    check labelOf(DragChoice.Join) == notationSymbolic(Operation.Wedge)
    check labelOf(DragChoice.Project) == notationSymbolic(Operation.ProjectOrthogonal)
    check wordOf(DragChoice.Join) == "join"
    # Way out to rest of catalogue is bare ellipsis: beside three pieces of.
    #   notation word is odd one out, and no operation is written with one.
    check labelOf(DragChoice.More) == "…"

  test "a picker opens on what was last applied at its own arity":
    var memory: OperationMemory
    check memory.lastOf(Arity.One) == OPERATION_FIRST_UNARY
    check memory.lastOf(Arity.Two) == OPERATION_FIRST_BINARY
    memory.remember(Operation.WedgeAnti)
    check memory.lastOf(Arity.Two) == Operation.WedgeAnti
    # Remembering binary leaves unary picker where it was: two lists are.
    #   disjoint, so one arity's choice can say nothing about other's.
    check memory.lastOf(Arity.One) == OPERATION_FIRST_UNARY
    memory.remember(Operation.Bulk)
    check memory.lastOf(Arity.One) == Operation.Bulk
    check memory.lastOf(Arity.Two) == Operation.WedgeAnti


  test "a selection is hidden only when every one of its objects is":
    # What one hide/show button on both front-ends reads to name what it would do.
    var scene = initScene()
    scene.addObject(POINTS[0], "a", Ink.Rose)
    scene.addObject(POINTS[1], "b", Ink.Rose)
    var selection: Selection
    check not selection.isAllHidden(scene) # Nothing picked: nothing to show.
    selection.toggle(0)
    selection.toggle(1)
    check not selection.isAllHidden(scene)
    scene.setVisible(0, false)
    check not selection.isAllHidden(scene) # One of two still drawn.
    scene.setVisible(1, false)
    check selection.isAllHidden(scene)


  test "toggle appends in pick order, so the first two picks name m and n":
    var selection: Selection
    selection.toggle(4)
    selection.toggle(1)
    selection.toggle(7)
    check ordered(selection) == @[4, 1, 7]
    check selection.at(0) == 4 # Operand m.
    check selection.at(1) == 1 # Operand n.


  test "toggling a picked handle drops it and closes the gap, leaving order intact":
    var selection: Selection
    for handle in [4, 1, 7]: selection.toggle(handle)
    selection.toggle(1)
    check ordered(selection) == @[4, 7]
    check not selection.contains(1)
    selection.toggle(1) # Re-picking appends at end, not back at its old position.
    check ordered(selection) == @[4, 7, 1]


  test "selectOnly replaces the whole selection, and clear empties it":
    var selection: Selection
    for handle in [4, 1, 7]: selection.toggle(handle)
    selection.selectOnly(2)
    check ordered(selection) == @[2]
    selection.clear()
    check selection.len == 0
    check not selection.contains(2)


  test "every change to a selection advances its revision, and nothing else does":
    var selection: Selection
    let scene = initScene()
    let revision_fresh = selection.revision
    selection.clear() # Empty already: nothing changed.
    check selection.revision == revision_fresh
    selection.toggle(3)
    check selection.revision > revision_fresh
    var last = selection.revision
    selection.selectOnly(3) # Already exactly that one handle.
    check selection.revision == last
    selection.selectOnly(4)
    check selection.revision > last
    last = selection.revision
    discard selection.contains(4)
    discard selection.len
    check selection.revision == last
    selection.pruneDead(scene) # Handle 4 is dead in empty scene.
    check selection.len == 0
    check selection.revision > last
    last = selection.revision
    selection.pruneDead(scene) # Nothing left to drop.
    check selection.revision == last
    selection.toggle(1)
    selection.toggle(1)
    check selection.revision == last + 2


  test "every handle can be picked at once, and picking past that adds nothing":
    var selection: Selection
    for handle in 0 ..< OBJECTS_MAX: selection.toggle(handle)
    check selection.len == OBJECTS_MAX
    selection.toggle(OBJECTS_MAX) # Out of range; capacity is already spent.
    check selection.len == OBJECTS_MAX


  test "pruneDead drops removed handles and keeps the rest in pick order":
    # Removed handle goes straight back to free list, so stale pick left behind.
    #   would silently reattach itself to whatever object is added next.
    var scene = initScene()
    for i in 0 ..< 3: discard scene.addObject(POINTS[i], "p" & $i, inkCycled(i))
    var selection: Selection
    for handle in [2, 0, 1]: selection.toggle(handle)
    scene.removeObject(0)
    selection.pruneDead(scene)
    check ordered(selection) == @[2, 1]
    check not selection.contains(0)


  test "implied arity is unary at one pick and binary at two or more":
    var selection: Selection
    selection.toggle(3)
    check selection.impliedArity == Arity.One
    selection.toggle(5)
    check selection.impliedArity == Arity.Two
    selection.toggle(6) # Three picked still names binary operation, on first two.
    check selection.impliedArity == Arity.Two
