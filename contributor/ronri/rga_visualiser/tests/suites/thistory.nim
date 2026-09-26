## Run `History` suite: one module of shared suite, which `../suites.nim` imports in order.

import ./fixtures


suite "History":
  proc scenesEqual(a, b: Scene): bool =
    ## Compare two scenes object by object, rather than through plain `==`:
    ##   `Scene` embeds `Multivector`, whose own `==` is intentional compile error (see
    ##   `pga/multivectors.nim`) steering every other caller toward `=~`'s tolerance -- this is that
    ##   same comparison, just folded field by field over whole scene rather than one multivector at
    ##   time.
    if a.len != b.len: return false
    for handle in 0 ..< OBJECTS_MAX:
      if a.isAlive(handle) != b.isAlive(handle): return false
      if not a.isAlive(handle): continue
      let (object_a, object_b) = (a[handle], b[handle])
      if not (object_a.geometry =~ object_b.geometry): return false
      if object_a.label != object_b.label: return false
      if object_a.ink != object_b.ink: return false
      if object_a.isVisible != object_b.isVisible: return false
    true


  test "stepping either way restores where the view stood, and never the lens":
    # `CameraStance` says lens is reader's setting, and that nothing aiming camera may
    #   rewrite it. Stepping is aiming camera, so it owes that too.
    #   Field of view is only lens field, and reader reaches it from both front-ends.
    var scene = initScene()
    var camera = initCameraDefault(WIDTH_OPENED, HEIGHT_OPENED)
    var history: History
    camera.degrees_field_of_view = 90.0
    history.initHistory(scene, camera)
    scene.addObject(toMultivector(PLACES[0]), "a", Ink.Cobalt)
    history.record(scene, camera)
    # Reader widens lens, then steps back over edit they made at other lens.
    camera.degrees_field_of_view = 30.0
    check history.undo(scene, camera)
    check camera.degrees_field_of_view =~ 30.0
    check history.redo(scene, camera)
    check camera.degrees_field_of_view =~ 30.0
    # Stance itself still crosses, which is what stepping is for.
    check camera.pivot =~ initCameraDefault(WIDTH_OPENED, HEIGHT_OPENED).pivot

  test "a step either way keeps each pick that still names the object it named":
    # Frame rule binds only while something is picked, so step must not drop picks it
    #   need not. Handle alone is no name: freed handle is refilled by next add.
    var scene = initScene()
    var camera = initCameraDefault(WIDTH_OPENED, HEIGHT_OPENED)
    var history: History
    let (a, b) = (scene.addObject(POINTS[0], "a", Ink.Cobalt), scene.addObject(POINTS[1], "b",
      Ink.Rose))
    history.initHistory(scene, camera)
    let c = scene.addObject(POINTS[2], "c", Ink.Olive)
    history.record(scene, camera)
    var picked: Selection
    picked.toggle(b)
    picked.toggle(c)
    picked.toggle(a)
    # Undo takes `c` away and keeps rest, in order picked.
    check history.undo(scene, camera, picked)
    check picked.len == 2
    check picked.at(0) == b and picked.at(1) == a
    # Redo brings `c` back, but reader had let it go: nothing re-picks it.
    check history.redo(scene, camera, picked)
    check picked.len == 2
    # Remove `a`, add `d` into its freed handle, and pick `d` alone.
    scene.removeObject(a)
    history.record(scene, camera)
    let d = scene.addObject(POINTS[3], "d", Ink.Cobalt)
    history.record(scene, camera)
    check d == a
    picked.clear()
    picked.toggle(d)
    # Undo empties that handle; second undo refills it with `a`, which is not `d`.
    check history.undo(scene, camera, picked)
    check picked.len == 0
    picked.toggle(d)
    check history.undo(scene, camera, picked)
    check scene.isAlive(d)
    check picked.len == 0


  test "undo and redo retrace every recorded state exactly, and canUndo/canRedo agree":
    var scene = initScene()
    var camera = initCameraDefault(WIDTH_OPENED, HEIGHT_OPENED)
    var history: History
    history.initHistory(scene, camera)
    var snapshots = @[scene] # Index 0 is seeded initial state.
    for i in 0 ..< CAPACITY_HISTORY - 1:
      scene.addObject(POINTS[i mod SAMPLES], "p" & $i, inkCycled(i))
      history.record(scene, camera)
      snapshots.add(scene)

    # Cursor sits at last recorded state: nothing to redo yet, everything to undo.
    check not history.canRedo
    check history.canUndo

    # Walk all way back, checking scene equality against what was actually recorded.
    #   at each step, and that canUndo agrees with undo's own success, right up to
    #   seeded state undo can never reach past.
    for i in countdown(len(snapshots) - 1, 1):
      check history.canUndo
      check history.undo(scene, camera)
      check scenesEqual(scene, snapshots[i - 1])
    check not history.canUndo
    check not history.undo(scene, camera)
    check scenesEqual(scene, snapshots[0])

    # Walk all way forward again, same way.
    for i in 1 ..< len(snapshots):
      check history.canRedo
      check history.redo(scene, camera)
      check scenesEqual(scene, snapshots[i])
    check not history.canRedo
    check not history.redo(scene, camera)


  test "recording past capacity drops the oldest entry instead of growing":
    var scene = initScene()
    var camera = initCameraDefault(WIDTH_OPENED, HEIGHT_OPENED)
    var history: History
    history.initHistory(scene, camera)
    var snapshots = @[scene]
    for i in 0 ..< CAPACITY_HISTORY + 4: # Four states past what timeline retains.
      scene.addObject(POINTS[i mod SAMPLES], "p" & $i, inkCycled(i))
      history.record(scene, camera)
      snapshots.add(scene)

    # Only most recent CAPACITY_HISTORY states are still reachable: undoing all.
    #   way back lands on oldest still-retained one, CAPACITY_HISTORY - 1 steps back
    #   from latest, not on very first state ever recorded.
    var count_undone = 0
    while history.undo(scene, camera): inc count_undone
    check count_undone == CAPACITY_HISTORY - 1
    check scenesEqual(scene, snapshots[^CAPACITY_HISTORY])

    # Every retained step in turn, not just far end of walk. Timeline is.
    #   ring, so wrapped one has its oldest step somewhere in middle of array
    #   and its newest just behind it; index that forgets wrap still lands
    #   count and can still land two ends, and misorders everything between them.
    for i in 1 ..< CAPACITY_HISTORY:
      check history.canRedo
      check history.redo(scene, camera)
      check scenesEqual(scene, snapshots[len(snapshots) - CAPACITY_HISTORY + i])
    check not history.canRedo
    for i in countdown(CAPACITY_HISTORY - 2, 0):
      check history.canUndo
      check history.undo(scene, camera)
      check scenesEqual(scene, snapshots[len(snapshots) - CAPACITY_HISTORY + i])
    check not history.canUndo


  test "a fresh record after undo truncates the redo-able future":
    var scene = initScene()
    var camera = initCameraDefault(WIDTH_OPENED, HEIGHT_OPENED)
    var history: History
    history.initHistory(scene, camera)
    scene.addObject(POINTS[0], "a", Ink.Rose)
    history.record(scene, camera)
    let state_a = scene

    scene.addObject(POINTS[1], "b", Ink.Rose)
    history.record(scene, camera) # State undo will later discard, never redone.

    discard history.undo(scene, camera)
    check scenesEqual(scene, state_a)
    check history.canRedo

    scene.addObject(POINTS[2], "c", Ink.Rose) # Diverges from discarded state above.
    history.record(scene, camera)
    check not history.canRedo
    check not history.redo(scene, camera)

    check history.canUndo
    discard history.undo(scene, camera)
    check scenesEqual(scene, state_a)


  test "crossing a step either way restores the view that step's own edit was made from":
    # Whole point of carrying camera: whatever step adds or takes away has to be.
    #   on screen as it happens, which means under view that edit was made from -- not
    #   under wherever camera has since been orbited to, and not under view
    #   *previous* edit happened to be made from however long ago.
    template checkAimedLike(taken, wanted: Camera) =
      check taken.azimuth =~ wanted.azimuth
      check taken.elevation =~ wanted.elevation
      check taken.distance =~ wanted.distance

    var scene = initScene()
    var camera = initCameraDefault(WIDTH_OPENED, HEIGHT_OPENED)
    var history: History
    history.initHistory(scene, camera)

    # Two edits, each made from its own distinctly different viewpoint.
    camera = camera.placed(stanceAround(camera.pivot, 11.0, Direction(x: 9, y: 2, z: 3)))
    scene.addObject(POINTS[0], "a", Ink.Rose)
    history.record(scene, camera)
    let camera_a = camera

    camera = camera.placed(stanceAround(camera.pivot, 29.0, Direction(x: -1, y: 5, z: -2)))
    scene.addObject(POINTS[1], "b", Ink.Rose)
    history.record(scene, camera)
    let camera_b = camera

    # Orbiting after fact records nothing of its own, so step ignores wherever.
    #   camera has drifted to since.
    camera = camera.placed(stanceAround(camera.pivot, 3.0, Direction(x: -4, y: -3, z: 9)))

    # Undoing `b` takes scene back to one object and view back to where `b` was.
    #   built -- `b` is what vanishes, so `b`'s own view is one to watch it from.
    check history.undo(scene, camera)
    checkAimedLike(camera, camera_b)
    check scene.len == 1

    # Redoing it crosses same step other way, and lands on same view.
    check history.redo(scene, camera)
    checkAimedLike(camera, camera_b)
    check scene.len == 2

    # Back past `a` in turn: its own view, not default timeline was seeded under.
    check history.undo(scene, camera)
    check history.undo(scene, camera)
    checkAimedLike(camera, camera_a)
    check scene.len == 0
    check not (camera.azimuth =~ initCameraDefault(WIDTH_OPENED, HEIGHT_OPENED).azimuth)


  test "undo and redo each advance the revision past every one the timeline has seen":
    # Front-end holds meshes and placements on revision; step that landed on.
    #   number it had already drawn showed nothing until camera moved.
    var scene = initScene()
    var camera = initCameraDefault(WIDTH_OPENED, HEIGHT_OPENED)
    var history: History
    history.initHistory(scene, camera)
    var seen = @[scene.revision]
    for i in 0 ..< 3:
      scene.addObject(POINTS[i], "p" & $i, Ink.Rose)
      history.record(scene, camera)
      seen.add(scene.revision)
    for _ in 0 ..< 3:
      check history.undo(scene, camera)
      check scene.revision > max(seen)
      seen.add(scene.revision)
    for _ in 0 ..< 3:
      check history.redo(scene, camera)
      check scene.revision > max(seen)
      seen.add(scene.revision)
