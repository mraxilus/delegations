## Run `Interaction` suite: one module of shared suite, which `../suites.nim` imports in order.

import ./fixtures


suite "Interaction":
  test "drag operation maps to the catalogue entry it names":
    check DragOperation.Join.toOperation == Operation.Wedge
    check DragOperation.Meet.toOperation == Operation.WedgeAnti
    check DragOperation.Project.toOperation == Operation.ProjectOrthogonal


  test "drag applies the proposal and appends the result":
    var scene = initScene()
    scene.addObject(POINTS[0], "a", Ink.Rose)
    scene.addObject(POINTS[1], "b", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.index_hover = some(0)
    check interaction.beginDrag(arming = MenuArming.OnDwell, now = 0.0)
    interaction.index_hover = some(1)
    let outcome = interaction.endDrag(scene)
    check scene.len == 3
    # Two points propose `join`, and object that lands is that join -- not button's.
    #   choice, which is what this used to be.
    check outcome.choice == some(DragChoice.Join)
    check scene[2].geometry =~ (POINTS[0] ∧ POINTS[1])
    check not interaction.is_dragging
    check "gave" in outcome.message
    check outcome.index_created == some(2)
    check outcome.operands == some((source: 0, destination: 1))


  test "a finger over a crowd starts no drag, so the press moves the view instead":
    # Touch has no hover ring to say which of several it is over, so where gesture is.
    #   ambiguous movement wins and reader zooms in until it is not. Mouse saw its
    #   ring and keeps its drag over same crowd.
    var scene = initScene()
    scene.addObject(POINTS[0], "a", Ink.Rose)
    scene.addObject(POINTS[1], "b", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.index_hover = some(0)
    interaction.count_hover_rivals = 2
    check not interaction.canConstructByTouch
    check not interaction.beginDrag(arming = MenuArming.OnDwell, now = 0.0)
    check not interaction.is_dragging
    check interaction.beginDrag(arming = MenuArming.Never, now = 0.0)
    interaction.cancelDrag()
    check interaction.beginDrag(arming = MenuArming.Always, now = 0.0)
    interaction.cancelDrag()
    # Lone object under finger drags as ever.
    interaction.count_hover_rivals = 1
    check interaction.canConstructByTouch
    check interaction.beginDrag(arming = MenuArming.OnDwell, now = 0.0)
    interaction.cancelDrag()
    # Nothing hovered is not lone object either.
    interaction.index_hover = none(int)
    interaction.count_hover_rivals = 0
    check not interaction.canConstructByTouch


  test "the sky starts no drag, so a press on empty space still reaches the camera":
    # Regression this rule exists to prevent, held directly. `beginDrag` failing when.
    #   nothing is hovered is *entire* mechanism by which press on empty space
    #   becomes orbit -- and horizon plane is hovered wherever nothing else is,
    #   because it is drawn as dome over every direction. Were it to start drag, orbit
    #   and pan would stop working outright moment sky joined scene.
    var scene = initScene()
    scene.addObject(POINTS[0], "a", Ink.Rose)
    var interaction = Interaction(is_enabled: true)

    interaction.index_hover = some(0)
    interaction.is_hover_backdrop = true
    check not interaction.beginDrag(arming = MenuArming.OnDwell, now = 0.0)
    check not interaction.is_dragging

    # And same refusal at far end: release over sky commits nothing, rather.
    #   than quietly taking whole sky as operand.
    interaction.is_hover_backdrop = false
    check interaction.beginDrag(arming = MenuArming.OnDwell, now = 0.0)
    interaction.is_hover_backdrop = true
    check interaction.destinationOf.isNone
    let outcome = interaction.endDrag(scene)
    check outcome.index_created.isNone
    check outcome.message.len == 0

    # Finite plane filling view is backdrop too, read off scene by `updateHover`.
    #   From half unit above ground its disc spans frame, and press on it starting drag
    #   left view unmovable; from far off it is ordinary drag handle.
    var floor = initScene()
    floor.addObject(groundPlane(), "ground", Ink.Grid)
    for (distance, is_backdrop) in [(0.5, true), (40.0, false)]:
      let close = initCamera(pivot = ORIGIN, distance = distance, azimuth = 0.9, elevation = 0.9)
      var over = Interaction(is_enabled: true)
      over.updateCursor(400.0, 300.0)
      over.updateHover(
        floor, close, close.drawExtentFor(600), close.initMatrixViewProjection(800.0/600.0),
        800, 600,
      )
      check over.index_hover == some(0)
      check over.is_hover_backdrop == is_backdrop
      check over.beginDrag(arming = MenuArming.Never, now = 0.0) == not is_backdrop

    # Horizon *line* is ordinary drag pivot both ways: it is curve, not backdrop.
    interaction.is_hover_backdrop = false
    check interaction.beginDrag(arming = MenuArming.OnDwell, now = 0.0)


  test "a press that never moves is a click on what it came down on, not a drag":
    # Press over object has to start drag eagerly -- press target chooses.
    #   scheme -- so whether it *was* one is only answerable at release.
    var scene = initScene()
    scene.addObject(POINTS[0], "a", Ink.Rose)
    scene.addObject(POINTS[1], "b", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.updateCursor(200.0, 200.0)
    interaction.index_hover = some(0)
    interaction.beginPress(now = 10.0)
    check interaction.beginDrag(arming = MenuArming.OnDwell, now = 10.0)
    let outcome = interaction.endDrag(scene, 10.5)
    check outcome.index_clicked == some(0)
    check outcome.index_created.isNone
    check scene.len == 2 # Nothing built; click picks, it does not construct.


  test "a press that moves past the click slop is a drag, however briefly it lasted":
    var scene = initScene()
    scene.addObject(POINTS[0], "a", Ink.Rose)
    scene.addObject(POINTS[1], "b", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.updateCursor(200.0, 200.0)
    interaction.index_hover = some(0)
    interaction.beginPress(now = 10.0)
    check interaction.beginDrag(arming = MenuArming.OnDwell, now = 10.0)
    interaction.updateCursor(200.0 + 2.0*PIXELS_CLICK_SLOP, 200.0)
    # Back where it started: reading is latched, so pointer that swung out and.
    #   returned is still drag rather than click that happened to end where it began.
    interaction.updateCursor(200.0, 200.0)
    interaction.index_hover = some(1)
    let outcome = interaction.endDrag(scene, 10.5)
    check outcome.index_clicked.isNone
    check outcome.index_created == some(2)


  test "a press that never moved stays a click however long it is held":
    # **Regression case for shipped fault.** 0.35 s deadline stood in `isClick`.
    #   beside distance bound, so shift-clicking with press held even slightly long
    #   selected nothing at all and answered "Released on its own source; nothing done" --
    #   measured on built page at 600 ms holds, three objects, none of them picked.
    #   Nothing separates click from hold on mouse: dwell is touch-only.
    var scene = initScene()
    scene.addObject(POINTS[0], "a", Ink.Rose)
    scene.addObject(POINTS[1], "b", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.updateCursor(200.0, 200.0)
    interaction.index_hover = some(0)
    interaction.beginPress(now = 10.0)
    check interaction.beginDrag(arming = MenuArming.Never, now = 10.0)
    for held in [0.05, 0.35, 0.6, 5.0, 60.0]:
      check interaction.isClick(10.0 + held)
    let outcome = interaction.endDrag(scene, 10.0 + 60.0)
    check outcome.index_clicked == some(0)
    check scene.len == 2 # Still selection, not construction.


  test "a right press that never opened a wheel reports a click":
    # It could not once: any drag armed `Always` was refused click outright, on.
    #   reasoning that it had asked for menu. But wheel only opens over pivot
    #   *other* than source, so press that never left its own object never asked for
    #   anything -- and refusing it left right button doing nothing on plain click.
    var scene = initScene()
    scene.addObject(POINTS[0], "a", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.updateCursor(200.0, 200.0)
    interaction.index_hover = some(0)
    interaction.beginPress(now = 10.0)
    check interaction.beginDrag(arming = MenuArming.Always, now = 10.0)
    check interaction.isClick(10.5)
    check interaction.endDrag(scene, 10.5).index_clicked == some(0)


  test "a release with the wheel open commits the wheel, never a click":
    # Check other half of that rule.
    #   Once menu is open reader was offered choice, and answering with quiet selection
    #   instead would make button unreliable.
    var scene = initScene()
    scene.addObject(POINTS[0], "a", Ink.Rose)
    scene.addObject(POINTS[1], "b", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.updateCursor(200.0, 200.0)
    interaction.index_hover = some(0)
    interaction.beginPress(now = 10.0)
    check interaction.beginDrag(arming = MenuArming.Always, now = 10.0)
    interaction.index_hover = some(1)
    interaction.updateDrag(scene, now = 10.0)
    check interaction.menu.isSome # Armed `Always`, and now over another object.
    check interaction.endDrag(scene, 10.5).index_clicked.isNone


  test "the button that reveals the menu is the right one, and only it":
    # Both render paths and help panel read this; fourth copy anywhere is drift.
    check not revealsMenuOn(PointerButton.Left)
    check revealsMenuOn(PointerButton.Right)
    check not revealsMenuOn(PointerButton.Middle)


  test "a revealing click only reveals while a selection stands with its menu down":
    # Total over both booleans, so neither caller has unhandled case.
    check revealsWithoutPicking(has_selection = true, is_menu_shown = false)
    check not revealsWithoutPicking(has_selection = true, is_menu_shown = true)
    check not revealsWithoutPicking(has_selection = false, is_menu_shown = false)
    check not revealsWithoutPicking(has_selection = false, is_menu_shown = true)


  test "a wheel the cursor walks away from lets go, and re-aims onto the next object":
    # What makes wheel opened over wrong object recoverable. Before this it latched.
    #   its destination for rest of drag, so only way out was to release.
    var scene = initScene()
    scene.addObject(POINTS[0], "a", Ink.Rose)
    scene.addObject(POINTS[1], "b", Ink.Rose)
    scene.addObject(POINTS[2], "c", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.updateCursor(200.0, 200.0)
    interaction.index_hover = some(0)
    interaction.beginPress(now = 0.0)
    check interaction.beginDrag(arming = MenuArming.Always, now = 0.0)
    interaction.index_hover = some(1)
    interaction.updateDrag(scene, now = 0.0)
    check interaction.menu.isSome
    let centre = interaction.menu.get

    # Still inside radius: ordinary overshoot past wedge keeps its menu.
    interaction.updateCursor(centre.x + 0.5*PIXELS_MENU_DISENGAGE, centre.y)
    interaction.updateDrag(scene, now = 0.0)
    check interaction.menu.isSome

    # Past it: menu goes, and does not come back while cursor is still over that.
    #   same object -- otherwise disengaging would do nothing but move menu.
    interaction.updateCursor(centre.x + 2.0*PIXELS_MENU_DISENGAGE, centre.y)
    interaction.updateDrag(scene, now = 0.0)
    check interaction.menu.isNone
    interaction.updateDrag(scene, now = 0.0)
    check interaction.menu.isNone

    # On to third object: open again, for **original source** with new.
    #   destination. Pair re-aims; it never chains off object just left.
    interaction.index_hover = some(2)
    interaction.updateDrag(scene, now = 0.0)
    check interaction.menu.isSome
    check interaction.index_source == 0
    check destinationOf(interaction) == some(2)


  test "a wheel opens again on the object it was let go of, once the drag has left it":
    var scene = initScene()
    scene.addObject(POINTS[0], "a", Ink.Rose)
    scene.addObject(POINTS[1], "b", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.updateCursor(200.0, 200.0)
    interaction.index_hover = some(0)
    interaction.beginPress(now = 0.0)
    check interaction.beginDrag(arming = MenuArming.Always, now = 0.0)
    interaction.index_hover = some(1)
    interaction.updateDrag(scene, now = 0.0)
    let centre = interaction.menu.get
    interaction.updateCursor(centre.x + 2.0*PIXELS_MENU_DISENGAGE, centre.y)
    interaction.updateDrag(scene, now = 0.0)
    check interaction.menu.isNone
    # Off it entirely, then back: hold at arm's length is released by leaving.
    interaction.index_hover = none(int)
    interaction.updateDrag(scene, now = 0.0)
    interaction.index_hover = some(1)
    interaction.updateDrag(scene, now = 0.0)
    check interaction.menu.isSome


  test "the palette steps on every released construction, built or not":
    # Reader watched colour on band for whole drag; offering it again to.
    #   next attempt reads as gesture having never registered.
    var scene = initScene()
    scene.addObject(POINTS[0], "a", Ink.Rose)
    scene.addObject(POINTS[1], "b", Ink.Rose)
    let ink_first = scene.inkNext
    check scene.inkNext == ink_first # Peeking never walks cycle.

    # Release back on its own source builds nothing, and still steps.
    var interaction = Interaction(is_enabled: true)
    interaction.updateCursor(200.0, 200.0)
    interaction.index_hover = some(0)
    interaction.beginPress(now = 0.0)
    check interaction.beginDrag(arming = MenuArming.Never, now = 0.0)
    interaction.updateCursor(200.0 + 2.0*PIXELS_CLICK_SLOP, 200.0)
    let refused = interaction.endDrag(scene, 0.0)
    check refused.index_created.isNone
    check scene.inkNext != ink_first
    check scene.len == 2

    # Click is not construction, so it leaves cycle alone.
    let ink_after_refusal = scene.inkNext
    interaction.updateCursor(200.0, 200.0)
    interaction.index_hover = some(0)
    interaction.beginPress(now = 1.0)
    check interaction.beginDrag(arming = MenuArming.Never, now = 1.0)
    check interaction.endDrag(scene, 1.0).index_clicked == some(0)
    check scene.inkNext == ink_after_refusal


  test "a built object wears exactly the hue its drag was drawn in":
    # Band, comet and preview all read `inkOfDrag`, so what reader watched is.
    #   what they get. It used to be operation's own colour, which said nothing about
    #   object about to exist.
    var scene = initScene()
    scene.addObject(POINTS[0], "a", Ink.Rose)
    scene.addObject(POINTS[1], "b", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.updateCursor(200.0, 200.0)
    interaction.index_hover = some(0)
    check interaction.beginDrag(arming = MenuArming.Never, now = 0.0)
    interaction.index_hover = some(1)
    interaction.updateDrag(scene, now = 0.0)
    let promised = interaction.inkOfDrag(scene.inkNext)
    check promised == scene.inkNext
    let outcome = interaction.endDrag(scene, 0.0)
    check outcome.index_created.isSome
    check scene[outcome.index_created.get].ink == promised


  test "a drag driven without a press is never mistaken for a click":
    # Safe default `is_press_still` exists for: caller that never went through.
    #   `beginPress` gets behaviour that predates clicks, whatever clock reads.
    var scene = initScene()
    scene.addObject(POINTS[0], "a", Ink.Rose)
    scene.addObject(POINTS[1], "b", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.index_hover = some(0)
    check not interaction.isClick(0.0)
    check interaction.beginDrag(arming = MenuArming.OnDwell, now = 0.0)
    interaction.index_hover = some(1)
    check interaction.endDrag(scene, 0.0).index_created == some(2)


  test "drag cannot start without a hovered object":
    var interaction = Interaction(is_enabled: true)
    interaction.index_hover = none(int)
    check not interaction.beginDrag(arming = MenuArming.Always, now = 0.0)
    check not interaction.is_dragging


  test "releasing over empty space adds nothing":
    var scene = initScene()
    scene.addObject(POINTS[0], "a", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.index_hover = some(0)
    discard interaction.beginDrag(arming = MenuArming.OnDwell, now = 0.0)
    interaction.index_hover = none(int)
    let outcome = interaction.endDrag(scene)
    check scene.len == 1
    check not interaction.is_dragging
    check outcome.index_created.isNone
    # **And says nothing about it.** Drag let go of over empty space is commonest.
    #   thing reader does with gesture they thought better of, and it is plain on
    #   screen that nothing arrived; status line for it is message that fires all day.
    #   Refusals that *land on something* still speak, since those reader cannot read
    #   off screen -- see case below.
    check outcome.message.len == 0

    # Release that lands on object and still builds nothing does earn its message.
    interaction.index_hover = some(0)
    discard interaction.beginDrag(arming = MenuArming.OnDwell, now = 0.0)
    let refused = interaction.endDrag(scene)
    check refused.index_created.isNone
    check refused.message.len > 0


  test "releasing on its own source adds nothing":
    var scene = initScene()
    scene.addObject(POINTS[0], "a", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.index_hover = some(0)
    discard interaction.beginDrag(arming = MenuArming.OnDwell, now = 0.0)
    let outcome = interaction.endDrag(scene)
    check scene.len == 1
    check "own source" in outcome.message
    check outcome.index_created.isNone


  test "endDrag ignores a drag whose source was removed since it began":
    var scene = initScene()
    scene.addObject(POINTS[0], "a", Ink.Rose)
    scene.addObject(POINTS[1], "b", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.index_hover = some(0)
    discard interaction.beginDrag(arming = MenuArming.OnDwell, now = 0.0) # index_source = 0.
    scene.removeObject(0) # Source vanishes mid-drag -- e.g. removed by another input path.
    interaction.index_hover = some(1)
    let outcome = interaction.endDrag(scene)
    check "no longer exists" in outcome.message
    check outcome.index_created.isNone
    check not interaction.is_dragging
    check scene.len == 1


  test "endDrag ignores a drag whose destination was removed since it began":
    var scene = initScene()
    scene.addObject(POINTS[0], "a", Ink.Rose)
    scene.addObject(POINTS[1], "b", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.index_hover = some(0)
    discard interaction.beginDrag(arming = MenuArming.OnDwell, now = 0.0) # index_source = 0.
    scene.removeObject(1)
    interaction.index_hover = some(1) # Still reports now-dead handle as hovered.
    let outcome = interaction.endDrag(scene)
    check "no longer exists" in outcome.message
    check outcome.index_created.isNone
    check scene.len == 1


  test "cancelDrag clears state without applying anything":
    var scene = initScene()
    scene.addObject(POINTS[0], "a", Ink.Rose)
    scene.addObject(POINTS[1], "b", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.index_hover = some(0)
    discard interaction.beginDrag(arming = MenuArming.OnDwell, now = 0.0)
    interaction.cancelDrag()
    check not interaction.is_dragging
    check scene.len == 2


  test "endDrag with nothing dragging is a harmless no-op":
    var scene = initScene()
    scene.addObject(POINTS[0], "a", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    let outcome = interaction.endDrag(scene)
    check outcome.message == ""
    check outcome.index_created.isNone
    check outcome.choice.isNone
    check scene.len == 1


  test "a drag onto a pair that makes nothing refuses rather than adding a blank":
    # Plane dragged onto point: join overflows grade 4, meet falls short of antigrade.
    #   4, and projecting plane onto point gives nothing drawable. One pair in
    #   nine that offers no operation at all, and reason `proposalFor` is `Option`.
    var scene = initScene()
    scene.addObject(GENERAL_FIRST[2], "G", Ink.Rose)
    scene.addObject(GENERAL_SECOND[0], "f", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.index_hover = some(0)
    discard interaction.beginDrag(arming = MenuArming.OnDwell, now = 0.0)
    interaction.index_hover = some(1)
    let outcome = interaction.endDrag(scene)
    check scene.len == 2
    check outcome.index_created.isNone
    check outcome.choice.isNone
    check "nothing drawable" in outcome.message


  test "an insisted-on wedge that makes nothing refuses rather than adding a blank":
    # Two points at same place join to zero. Menu greys that wedge, so this is.
    #   only reachable by releasing on it anyway -- and what happens then is message and
    #   no object, never handle holding geometry with no shape.
    var scene = initScene()
    scene.addObject(GENERAL_FIRST[0], "a", Ink.Rose)
    scene.addObject(GENERAL_FIRST[0], "a again", Ink.Rose)
    check not isOffered(DragChoice.Join, GENERAL_FIRST[0], GENERAL_FIRST[0])
    var interaction = Interaction(is_enabled: true)
    interaction.index_hover = some(0)
    discard interaction.beginDrag(arming = MenuArming.OnDwell, now = 0.0)
    interaction.index_hover = some(1)
    let outcome = interaction.commitChoice(scene, DragChoice.Join, 0.0)
    check scene.len == 2
    check outcome.index_created.isNone
    check "nothing drawable" in outcome.message


  test "at most one of join and meet is offered, over every ordered pair of shapes":
    # Property whole design rests on: because join and meet are never both.
    #   drawable, `proposalFor` can be plain priority order rather than table of nine
    #   cases with tiebreak. Measured here rather than asserted in prose, over operands
    #   in general position -- earlier measurement used point lying *on* line it
    #   was crossed with and read zeros that came from fixture, not algebra.
    for m in GENERAL_FIRST:
      for n in GENERAL_SECOND:
        check not (isOffered(DragChoice.Join, m, n) and isOffered(DragChoice.Meet, m, n))
        # Whatever is proposed is drawable, so plain release never adds blank object.
        let proposal = proposalFor(m, n)
        if proposal.isSome: check resultOf(proposal.get, m, n).isSome
        # And `more…` is always there, which is what keeps menu from ever being empty.
        check isOffered(DragChoice.More, m, n)


  test "the proposal for each ordered pair of shapes is the measured one":
    # Table in `PROVENANCE.md`, pinned. Change to library's grades that moved.
    #   any cell would otherwise silently redefine what every plain drag builds.
    const lut_expected = [
      # point -> point, line, plane.
      some(DragChoice.Join), some(DragChoice.Join), some(DragChoice.Project),
      # line -> point, line, plane.
      some(DragChoice.Join), some(DragChoice.Project), some(DragChoice.Meet),
      # plane -> point, line, plane.
      none(DragChoice), some(DragChoice.Meet), some(DragChoice.Meet),
    ]
    var index = 0
    for m in GENERAL_FIRST:
      for n in GENERAL_SECOND:
        check proposalFor(m, n) == lut_expected[index]
        inc index


  test "a menu release picks the wedge the cursor is in, and nothing at its centre":
    for choice in DragChoice:
      let centre = ScreenPosition(x: 400.0, y: 300.0, depth: 0.0)
      check choiceAt(centre, anchorOf(centre, choice)) == some(choice)
    # Back at middle is how reader changes their mind without letting go.
    let centre = ScreenPosition(x: 400.0, y: 300.0, depth: 0.0)
    check choiceAt(centre, centre).isNone
    check choiceAt(
      centre, ScreenPosition(x: 400.0, y: 300.0 - 0.9*PIXELS_MENU_DEADZONE, depth: 0.0)
    ).isNone
    # Overshooting wedge still picks it, so fast throw is not punished.
    check choiceAt(
      centre, ScreenPosition(x: 400.0, y: 300.0 - 8.0*PIXELS_MENU_REACH, depth: 0.0)
    ) == some(DragChoice.Join)


  test "an open menu commits the wedge under the cursor, over its latched destination":
    var scene = initScene()
    scene.addObject(GENERAL_FIRST[0], "a", Ink.Rose)
    scene.addObject(GENERAL_SECOND[0], "b", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.updateCursor(400.0, 300.0)
    interaction.index_hover = some(0)
    check interaction.beginDrag(arming = MenuArming.Always, now = 0.0)
    interaction.index_hover = some(1)
    interaction.updateDrag(scene, 0.0)
    check interaction.menu.isSome
    # Wheel opened under cursor, so nothing is chosen yet and nothing is previewed.
    check interaction.proposal.isNone
    check interaction.preview.isNone
    # Reaching for wedge takes cursor off object; destination must survive it.
    interaction.index_hover = none(int)
    let south = anchorOf(interaction.menu.get, DragChoice.Project)
    interaction.updateCursor(south.x, south.y)
    interaction.updateDrag(scene, 0.0)
    check destinationOf(interaction) == some(1)
    check interaction.proposal == some(DragChoice.Project)
    let outcome = interaction.endDrag(scene)
    check outcome.choice == some(DragChoice.Project)
    check outcome.index_created == some(2)
    check scene[2].geometry =~ projectOrthogonal(GENERAL_FIRST[0], GENERAL_SECOND[0])


  test "the preview is the wedge being aimed at, not what a plain release would make":
    # Complaint this answers: with wheel open, preview was `proposalFor`'s own.
    #   answer whatever wedge cursor was in, so reader reaching for `project` watched
    #   preview of `join` and only found out what they had asked for after letting go.
    var scene = initScene()
    scene.addObject(GENERAL_FIRST[0], "a", Ink.Rose)
    scene.addObject(GENERAL_SECOND[0], "b", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.updateCursor(400.0, 300.0)
    interaction.index_hover = some(0)
    check interaction.beginDrag(arming = MenuArming.Always, now = 0.0)
    interaction.index_hover = some(1)
    interaction.updateDrag(scene, 0.0)
    let centre = interaction.menu.get
    # Take two points: `join` and `project` both make something, and different things.
    #   What lets preview be told apart from plain-release answer at all.
    check proposalFor(GENERAL_FIRST[0], GENERAL_SECOND[0]) == some(DragChoice.Join)
    check isOffered(DragChoice.Project, GENERAL_FIRST[0], GENERAL_SECOND[0])

    proc aimAt(interaction: var Interaction, scene: Scene, choice: DragChoice) =
      let at = anchorOf(centre, choice)
      interaction.updateCursor(at.x, at.y)
      interaction.updateDrag(scene, 0.0)

    interaction.aimAt(scene, DragChoice.Project)
    check interaction.choosing == some(DragChoice.Project)
    check interaction.preview.get.geometry =~
      projectOrthogonal(GENERAL_FIRST[0], GENERAL_SECOND[0])
    interaction.aimAt(scene, DragChoice.Join)
    check interaction.preview.get.geometry =~ (GENERAL_FIRST[0] ∧ GENERAL_SECOND[0])
    # And each of those is exactly what letting go there commits: one rule, drawn and then.
    #   obeyed, checked by actually releasing rather than by re-deriving answer.
    for choice in [DragChoice.Join, DragChoice.Project]:
      var trial = interaction
      var scene_trial = scene
      trial.aimAt(scene_trial, choice)
      let previewed = trial.preview.get.geometry
      let outcome = trial.endDrag(scene_trial)
      check outcome.index_created.isSome
      check scene_trial[outcome.index_created.get].geometry =~ previewed


  test "what a release would do has three answers, and the band's tint has three":
    # Reach all three effects over one pair with wheel open, without cursor leaving pivot.
    #   Two-way test could not carry it: centre and greyed wedge both have no answer, and
    #   they want opposite feedback.
    var scene = initScene()
    scene.addObject(GENERAL_FIRST[0], "a", Ink.Rose)
    scene.addObject(GENERAL_SECOND[0], "b", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.updateCursor(400.0, 300.0)
    interaction.index_hover = some(0)
    check interaction.beginDrag(arming = MenuArming.Always, now = 0.0)
    interaction.index_hover = some(1)
    interaction.updateDrag(scene, 0.0)
    let centre = interaction.menu.get

    # Back at wheel's own centre: releasing calls gesture off, so band goes.
    #   neutral rather than warning about refusal that is not going to happen.
    check interaction.effectOf == ReleaseEffect.Nothing
    check interaction.inkOfDrag(scene.inkNext) == Ink.Guide
    check interaction.preview.isNone

    for (choice, effect) in [
      (DragChoice.Join, ReleaseEffect.Builds),
      (DragChoice.Meet, ReleaseEffect.Refused), # Two points meet in nothing drawable.
      (DragChoice.Project, ReleaseEffect.Builds),
      (DragChoice.More, ReleaseEffect.Builds), # Builds nothing itself; picker will.
    ]:
      let at = anchorOf(centre, choice)
      interaction.updateCursor(at.x, at.y)
      interaction.updateDrag(scene, 0.0)
      check isOffered(choice, GENERAL_FIRST[0], GENERAL_SECOND[0]) ==
        (effect == ReleaseEffect.Builds)
      check interaction.effectOf == effect
      check interaction.inkOfDrag(scene.inkNext) ==
        (case effect
         of ReleaseEffect.Nothing: Ink.Guide
         of ReleaseEffect.Refused: Ink.Invalid
         of ReleaseEffect.Builds: scene.inkNext)
      # `More` builds nothing itself, so it previews nothing while still promising its hue.
      check interaction.preview.isSome ==
        (effect == ReleaseEffect.Builds and choice != DragChoice.More)


  test "with no wheel open the preview is still the plain-release answer":
    # Left button's own path, unchanged: it never opens wheel, so what it previews is.
    #   `proposalFor`'s answer exactly as before.
    var scene = initScene()
    scene.addObject(GENERAL_FIRST[0], "a", Ink.Rose)
    scene.addObject(GENERAL_SECOND[0], "b", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.updateCursor(400.0, 300.0)
    interaction.index_hover = some(0)
    check interaction.beginDrag(arming = MenuArming.Never, now = 0.0)
    interaction.index_hover = some(1)
    interaction.updateDrag(scene, 0.0)
    check interaction.menu.isNone
    check interaction.proposal == some(DragChoice.Join)
    check interaction.preview.get.geometry =~ (GENERAL_FIRST[0] ∧ GENERAL_SECOND[0])
    check interaction.effectOf == ReleaseEffect.Builds


  test "a previewed plane is centred where the committed one will be":
    # `mesh.addPlane` centres disc on object's own creation anchor, so preview drawn.
    #   without one sits somewhere object is about to leave -- measured at 2.1 units
    #   here, against disc of radius 8, and jump lands at moment reader is
    #   watching hardest.
    var scene = initScene()
    scene.addObject(GENERAL_FIRST[1], "L", Ink.Rose) # Line ...
    scene.addObject(GENERAL_SECOND[0], "p", Ink.Rose) # ... joined with point gives plane.
    var interaction = Interaction(is_enabled: true)
    interaction.updateCursor(400.0, 300.0)
    interaction.index_hover = some(0)
    check interaction.beginDrag(arming = MenuArming.Never, now = 0.0)
    interaction.index_hover = some(1)
    interaction.updateDrag(scene, 0.0)
    check interaction.proposal == some(DragChoice.Join)
    check kindOf(interaction.preview.get.geometry) == some(Kind.Plane)
    check interaction.preview.get.anchor.isSome
    # Read before releasing: `endDrag` clears drag's whole state on its way out.
    let previewed = interaction.preview.get.anchor.get
    # Not support, or there would have been nothing to fix.
    check not (previewed =~ positionAnchor(interaction.preview.get.geometry).get)
    let outcome = interaction.endDrag(scene)
    check outcome.index_created.isSome
    check scene[outcome.index_created.get].anchorOverride.get =~ previewed


  test "a menu release back at the centre commits nothing":
    var scene = initScene()
    scene.addObject(GENERAL_FIRST[0], "a", Ink.Rose)
    scene.addObject(GENERAL_SECOND[0], "b", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.updateCursor(400.0, 300.0)
    interaction.index_hover = some(0)
    discard interaction.beginDrag(arming = MenuArming.Always, now = 0.0)
    interaction.index_hover = some(1)
    interaction.updateDrag(scene, 0.0)
    let outcome = interaction.endDrag(scene)
    check scene.len == 2
    check outcome.index_created.isNone
    check "without choosing" in outcome.message


  test "`more…` builds nothing and hands both operands over, in drag order":
    var scene = initScene()
    scene.addObject(GENERAL_FIRST[0], "a", Ink.Rose)
    scene.addObject(GENERAL_SECOND[0], "b", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.updateCursor(400.0, 300.0)
    interaction.index_hover = some(0)
    discard interaction.beginDrag(arming = MenuArming.Always, now = 0.0)
    interaction.index_hover = some(1)
    interaction.updateDrag(scene, 0.0)
    let west = anchorOf(interaction.menu.get, DragChoice.More)
    interaction.updateCursor(west.x, west.y)
    let outcome = interaction.endDrag(scene)
    check scene.len == 2
    check outcome.choice == some(DragChoice.More)
    check outcome.index_created.isNone
    check outcome.operands == some((source: 0, destination: 1))


  test "a touch drag waits out the dwell before offering the menu; a right one never does":
    var scene = initScene()
    scene.addObject(GENERAL_FIRST[0], "a", Ink.Rose)
    scene.addObject(GENERAL_SECOND[0], "b", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.index_hover = some(0)
    discard interaction.beginDrag(arming = MenuArming.OnDwell, now = 1000.0)
    interaction.index_hover = some(1)
    interaction.updateDrag(scene, 1000.0)
    check interaction.menu.isNone
    interaction.updateDrag(scene, 1000.0 + 0.99*SECONDS_DWELL_MENU)
    check interaction.menu.isNone
    interaction.updateDrag(scene, 1000.0 + SECONDS_DWELL_MENU)
    check interaction.menu.isSome

    var forced = Interaction(is_enabled: true)
    forced.index_hover = some(0)
    discard forced.beginDrag(arming = MenuArming.Always, now = 1000.0)
    forced.index_hover = some(1)
    forced.updateDrag(scene, 1000.0)
    check forced.menu.isSome

    # And left button, which is one mouse spends nearly every drag on, never.
    #   reaches menu at all -- however long it is held still over its pivot. Dwell
    #   opening under hand that paused mid-gesture is exactly what it is for.
    var never = Interaction(is_enabled: true)
    never.index_hover = some(0)
    discard never.beginDrag(arming = MenuArming.Never, now = 1000.0)
    never.index_hover = some(1)
    never.updateDrag(scene, 1000.0)
    check never.menu.isNone
    never.updateDrag(scene, 1000.0 + 10.0*SECONDS_DWELL_MENU)
    check never.menu.isNone


  test "a dwell wheel nobody entered does not veto the release":
    # Touch gesture as finger actually does it: drag onto pivot, pause there.
    #   to aim -- wheel opens under finger, hidden by it -- and lift. Measured on
    #   phone before this rule: that release built nothing every time, which read as
    #   drag itself being broken.
    var scene = initScene()
    scene.addObject(POINTS[0], "a", Ink.Rose)
    scene.addObject(POINTS[1], "b", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.updateCursor(200.0, 200.0)
    interaction.index_hover = some(0)
    interaction.beginPress(now = 0.0)
    check interaction.beginDrag(arming = MenuArming.OnDwell, now = 0.0)
    interaction.updateCursor(400.0, 200.0)
    interaction.index_hover = some(1)
    interaction.updateDrag(scene, now = 0.0)
    interaction.updateDrag(scene, now = SECONDS_DWELL_MENU + 0.1)
    check interaction.menu.isSome
    # Pair's own answer keeps standing under unentered wheel, preview included, so.
    #   what band promises and what lift commits stay one thing.
    check interaction.proposal == some(DragChoice.Join)
    check interaction.preview.isSome
    let outcome = interaction.endDrag(scene, SECONDS_DWELL_MENU + 0.2)
    check outcome.index_created == some(2)
    check scene.len == 3


  test "a wedge walked into and left again cancels the release, dwell wheel included":
    # Other half of rule: entering wheel is engaging with it, so coming back.
    #   to centre afterwards is deliberate way out -- on dwell wheel exactly
    #   as on summoned one.
    var scene = initScene()
    scene.addObject(POINTS[0], "a", Ink.Rose)
    scene.addObject(POINTS[1], "b", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.updateCursor(200.0, 200.0)
    interaction.index_hover = some(0)
    interaction.beginPress(now = 0.0)
    check interaction.beginDrag(arming = MenuArming.OnDwell, now = 0.0)
    interaction.updateCursor(400.0, 200.0)
    interaction.index_hover = some(1)
    interaction.updateDrag(scene, now = 0.0)
    interaction.updateDrag(scene, now = SECONDS_DWELL_MENU + 0.1)
    check interaction.menu.isSome
    interaction.updateCursor(400.0 + PIXELS_MENU_REACH, 200.0) # Into east wedge...
    interaction.updateDrag(scene, now = SECONDS_DWELL_MENU + 0.2)
    interaction.updateCursor(400.0, 200.0) # ...and back to centre.
    interaction.updateDrag(scene, now = SECONDS_DWELL_MENU + 0.3)
    check interaction.proposal.isNone # No preview: band already says this lift cancels.
    let outcome = interaction.endDrag(scene, SECONDS_DWELL_MENU + 0.4)
    check outcome.index_created.isNone
    check scene.len == 2


  test "a summoned wheel still cancels at its own centre":
    # Arming distinction release rule turns on: right press asked for.
    #   wheel, so lifting back at its centre withdraws gesture even though no wedge
    #   was ever entered.
    var scene = initScene()
    scene.addObject(POINTS[0], "a", Ink.Rose)
    scene.addObject(POINTS[1], "b", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.updateCursor(200.0, 200.0)
    interaction.index_hover = some(0)
    interaction.beginPress(now = 0.0)
    check interaction.beginDrag(arming = MenuArming.Always, now = 0.0)
    interaction.updateCursor(400.0, 200.0)
    interaction.index_hover = some(1)
    interaction.updateDrag(scene, now = 0.0)
    check interaction.menu.isSome
    let outcome = interaction.endDrag(scene, 0.5)
    check outcome.index_created.isNone
    check scene.len == 2


  test "an overlay run covers exactly what was added after it was marked":
    # Mechanism selected object is drawn over everything with. Held here because.
    #   fault it guards against is silent: mesh nobody marked has to draw *entirely*
    #   depth-tested, and sentinel index of zero would have said opposite -- every
    #   line of furniture drawn over scene, on every frame.
    let scale = algebraFilled(DrawExtent(scale: DrawScale(
      extent_furniture: 10.0,
      radius_horizon: 10.0,
      tangent_half_view: 0.5,
      height_pixels: 600,
      depth_near: 0.1,
      forward: Direction(x: 0, y: 0, z: -1),
    )))
    var meshes: MeshSet
    clearMeshes(meshes)
    check meshes.points.index_overlay.isNone
    check meshes.ribbons.index_overlay.isNone
    check meshes.rings.index_overlay.isNone
    check meshes.veils.index_overlay.isNone
    discard meshes.addObject(SCRATCH, GENERAL_POINTS[0], Ink.Rose.colour, scale)
    let count_under = meshes.points.count_vertices
    check count_under > 0
    check meshes.points.index_overlay.isNone

    markOverlay(meshes)
    discard meshes.addObject(SCRATCH, GENERAL_POINTS[1], Ink.Jade.colour, scale)
    check meshes.points.index_overlay == some(count_under)
    check meshes.points.count_vertices > count_under
    # Stream nothing was added to after mark still reports mark, with empty.
    #   overlay -- which is what makes "drawn over" property of order rather than of
    #   which stream object happens to tessellate into.
    check meshes.ribbons.index_overlay == some(0)
    check meshes.ribbons.count == 0
    check meshes.rings.index_overlay == some(0)
    check meshes.rings.count == 0
    check meshes.veils.index_overlay == some(0)
    check meshes.veils.count == 0

    # Veil run never straddles mark: disc laid on each side of it lands in two.
    #   runs of one record, and only second is overlay's.
    meshes.addDisc(
      ORIGIN, Direction(x: 1.0, y: 0.0, z: 0.0), Direction(x: 0.0, y: 1.0, z: 0.0),
      1.0, Ink.Olive.colour,
    )
    check meshes.veils.count == 1
    clearMeshes(meshes)
    meshes.addDisc(
      ORIGIN, Direction(x: 1.0, y: 0.0, z: 0.0), Direction(x: 0.0, y: 1.0, z: 0.0),
      1.0, Ink.Olive.colour,
    )
    markOverlay(meshes)
    meshes.addDisc(
      ORIGIN, Direction(x: 1.0, y: 0.0, z: 0.0), Direction(x: 0.0, y: 1.0, z: 0.0),
      1.0, Ink.Jade.colour,
    )
    check meshes.veils.count == 2
    check meshes.veils.index_overlay == some(1)
    check meshes.veils.runs[0].count == 1 and meshes.veils.runs[1].count == 1

    # **Plane's rim needs its own mark.** Its fill and its rim are two streams now, and.
    #   selected plane is tessellated second time after mark; without this split
    #   second rim would be drawn depth-tested -- behind very translucent fill it
    #   is highlight for. Held on whole object rather than on `addRing` directly,
    #   since what must land on right side of mark is what `addObject` emits.
    clearMeshes(meshes)
    discard meshes.addObject(SCRATCH, PLANES[0], Ink.Olive.colour, scale)
    let count_rim_under = meshes.rings.count
    check count_rim_under == 1
    markOverlay(meshes)
    discard meshes.addObject(SCRATCH, PLANES[0], Ink.Jade.colour, scale)
    check meshes.rings.index_overlay == some(count_rim_under)
    check meshes.rings.count == count_rim_under + 1

    # And clearing forgets it, so one frame's selection cannot outlive its own frame.
    clearMeshes(meshes)
    check meshes.points.index_overlay.isNone
    check meshes.ribbons.index_overlay.isNone
    check meshes.rings.index_overlay.isNone
    check meshes.veils.index_overlay.isNone


  test "a mouse never waits: left decides, right asks, middle starts nothing":
    # One rule both render paths and help panel read, held here rather than left.
    #   to three copies agreeing by inspection.
    check armingOf(PointerButton.Left) == some(MenuArming.Never)
    check armingOf(PointerButton.Right) == some(MenuArming.Always)
    check armingOf(PointerButton.Middle).isNone
    # And no button reaches dwell, which belongs to one pointer with no second.
    #   button to ask with.
    for button in PointerButton:
      check armingOf(button) != some(MenuArming.OnDwell)


  test "stepping walks live handles in both directions and wraps at both ends":
    var scene = initScene()
    for i in 0 ..< 4: scene.addObject(GENERAL_POINTS[i], "p", Ink.Rose)
    check scene.handleStepped(none(int), 1) == some(0) # Nothing focused starts at first.
    check scene.handleStepped(none(int), -1) == some(3) # ...and backwards, at last.
    check scene.handleStepped(some(0), 1) == some(1)
    check scene.handleStepped(some(3), 1) == some(0) # Wraps rather than stopping dead: key
    check scene.handleStepped(some(0), -1) == some(3) #   that quietly stops working is worse.


  test "stepping skips handles whose objects have gone":
    var scene = initScene()
    for i in 0 ..< 4: scene.addObject(GENERAL_POINTS[i], "p", Ink.Rose)
    scene.removeObject(1)
    scene.removeObject(2)
    # Handles are sparse -- free list reuses holes in any order -- so this cannot be.
    #   arithmetic on handle number, and hole must not be place keyboard lands.
    check scene.handleStepped(some(0), 1) == some(3)
    check scene.handleStepped(some(3), 1) == some(0)


  test "stepping an empty scene lands nowhere rather than on a freed handle":
    var scene = initScene()
    check scene.handleStepped(none(int), 1).isNone
    check scene.handleStepped(some(0), 1).isNone
    scene.addObject(GENERAL_POINTS[0], "p", Ink.Rose)
    scene.removeObject(0)
    check scene.handleStepped(none(int), 1).isNone


  test "every key answers the binding table, and answers exactly one half of it":
    # Table has to be total: each render path translates its own naming and then trusts.
    #   this, so key with no answer would be case nobody handled. Halves also have
    #   to be disjoint -- key that both moved view while held and did something at
    #   press would do second thing again on every auto-repeat.
    for key in Key:
      let (motion, action) = (motionFor(key), actionFor(key))
      check not (motion.isSome and action.isSome)
      if key == Key.Shift:
        # One key that is neither: it multiplies every rate rather than binding one.
        check motion.isNone and action.isNone
      else:
        check motion.isSome or action.isSome
    check motionFor(Key.W) == some(Motion.Forward)
    check motionFor(Key.Left) == some(Motion.OrbitLeft)
    check actionFor(Key.F) == some(KeyAction.FrameSelection)
    check actionFor(Key.Home) == some(KeyAction.ViewHome)


  test "with a selection a held key orbits the sphere, and never slides":
    # Slide across ground stood here, and it had no reading once camera stopped being tied
    #   to that plane. W and space rise over what is picked, S and control fall, and
    #   sideways keys swing round it.
    var interaction = Interaction(is_enabled: true)
    let opening = initCamera(pivot = ORIGIN, distance = 20.0, azimuth = 0.4, elevation = 0.3)
    var risen = opening
    interaction.holdKey(Key.W)
    interaction.driveHeld(risen, 1.0, has_selection = true)
    # Pivot and separation both stand, because both axes run through pivot.
    check risen.pivot =~ opening.pivot
    check risen.distance =~ opening.distance
    # Eye rose over it, by exactly rate asked for.
    check risen.elevation > opening.elevation
    check arccos(clamp(dot(risen.frame.forward, opening.frame.forward), -1.0, 1.0)) =~
      RISE_SECOND
    # Space mirrors W, so either hand reaches it.
    var mirrored = opening
    interaction.releaseKey(Key.W)
    interaction.holdKey(Key.Space)
    interaction.driveHeld(mirrored, 1.0, has_selection = true)
    check mirrored.frame.forward =~ risen.frame.forward
    # Control mirrors S, and falls where W rose.
    var fallen = opening
    interaction.releaseKey(Key.Space)
    interaction.holdKey(Key.Control)
    interaction.driveHeld(fallen, 1.0, has_selection = true)
    check fallen.elevation < opening.elevation
    check fallen.pivot =~ opening.pivot
    # Sideways swings round, and turns by its own rate rather than rise's.
    var swung = opening
    interaction.releaseKey(Key.Control)
    interaction.holdKey(Key.D)
    interaction.driveHeld(swung, 1.0, has_selection = true)
    check swung.pivot =~ opening.pivot
    check swung.distance =~ opening.distance
    check arccos(clamp(dot(swung.frame.forward, opening.frame.forward), -1.0, 1.0)) =~
      TURN_SECOND


  test "a left drag looks with nothing picked, and orbits with something picked":
    # Both front-ends called `orbit` outright, so free flight's own `look` never reached
    #   drag at all: eye swung round pivot where reader meant to turn in place.
    let opening = initCamera(
      pivot = ORIGIN, distance = 20.0, azimuth = 0.4, elevation = 0.3
    )
    # Nothing picked: eye stands exactly, and sight turns by what was asked for.
    var flying = opening
    flying.turnAcross(0.25, 0.1, has_selection = false)
    check flying.eye =~ opening.eye
    check not (flying.frame.forward =~ opening.frame.forward)
    var looked = opening
    looked.look(0.25, 0.1)
    check flying.frame.forward =~ looked.frame.forward
    # Something picked: pivot and separation stand, and eye is what swings.
    var orbiting = opening
    orbiting.turnAcross(0.25, 0.1, has_selection = true)
    check orbiting.pivot =~ opening.pivot
    check orbiting.distance =~ opening.distance
    check not (orbiting.eye =~ opening.eye)
    var turned = opening
    turned.orbit(0.25, 0.1)
    check orbiting.eye =~ turned.eye


  test "a finger's drag holds its roll, where a mouse keeps what transport leaves":
    # Turning about camera's own axes carries roll round by solid angle drag encloses.
    #   That is geometry rather than mistake, and touch asks for none of it: finger
    #   wanders in curves, and has no roll key beside it.
    const LOOP = [(0.3, 0.0), (0.0, 0.3), (-0.3, 0.0), (0.0, -0.3)]
    for picked in [false, true]:
      # One loop leaves solid angle it encloses, which is what says this is geometry.
      var once = initCameraDefault()
      for (turn, rise) in LOOP: once.turnAcross(turn, rise, has_selection = picked)
      check once.rollHeld.isSome
      let enclosed = 0.3*0.3*cos(initCameraDefault().elevation)
      check abs(once.rollHeld.get - enclosed) < 0.02*enclosed
      # Four of them leave four times as much: 0.324 radians, 18.6 degrees of tilt.
      var carried = initCameraDefault()
      for round in 1 .. 4:
        for (turn, rise) in LOOP:
          carried.turnAcross(turn, rise, has_selection = picked)
      check abs(carried.rollHeld.get - 0.3242) < 1.0e-3
    # Finger's loop of pixels leaves none in either state, keeps roll reader set by twist,
    #   and brings camera back where it began.
    const (WIDE, TALL) = (390, 844)
    let corners = [
      ScreenPosition(x: 160.0, y: 390.0), ScreenPosition(x: 230.0, y: 390.0),
      ScreenPosition(x: 230.0, y: 460.0), ScreenPosition(x: 160.0, y: 460.0),
    ]
    for picked in [false, true]:
      for set_roll in [0.0, 0.5]:
        var opening = initCameraDefault()
        opening.roll(set_roll)
        var held = opening
        for round in 1 .. 4:
          for corner in 0 ..< 4:
            held.turnFollowing(corners[corner], corners[(corner + 1) mod 4], WIDE, TALL,
              has_selection = picked)
        check held.rollHeld.get =~ opening.rollHeld.get
        check held.eye =~ opening.eye
        check held.frame.forward =~ opening.frame.forward
        check held.frame.axis_up =~ opening.frame.axis_up


  test "a finger's orbit keeps the point it took hold of under it, pixel for pixel":
    # Rate turned orbit by angle that moved nothing under finger at its own pace: only
    #   what stood at one depth in front of pivot kept up. Point held on sphere about
    #   pivot is carried from pixel finger left to pixel it reached instead.
    const (WIDE, TALL) = (390, 844)
    proc heldUnder(camera: Camera; at: ScreenPosition; radius: float): Position =
      # Place point finger holds under pixel.
      pointHeld(camera.eye, camera.pivot, camera.headingThrough(camera.frame, WIDE, TALL, at),
        radius)
    var rolled = initCameraDefault()
    rolled.roll(0.5)
    let steep = initCamera(pivot = ORIGIN, distance = 19.0, azimuth = 1.05, elevation = -0.7)
    for opening in [initCameraDefault(), rolled, steep]:
      # Single point, held by least sphere; and wide selection, held by its own reach.
      for reach_selection in [0.0, 6.0]:
        let radius = opening.radiusHeld(WIDE, TALL, reach_selection)
        for (start, finish) in [
          (ScreenPosition(x: 195.0, y: 422.0), ScreenPosition(x: 250.0, y: 422.0)),
          (ScreenPosition(x: 170.0, y: 380.0), ScreenPosition(x: 220.0, y: 470.0)),
          (ScreenPosition(x: 240.0, y: 470.0), ScreenPosition(x: 160.0, y: 390.0)),
        ]:
          let taken = opening.heldUnder(start, radius)
          for steps in [1, 16]:
            var
              carried = opening
              at = start
            for step in 1 .. steps:
              let reached = float(step)/float(steps)
              let next = ScreenPosition(
                x: start.x + reached*(finish.x - start.x),
                y: start.y + reached*(finish.y - start.y),
              )
              carried.turnFollowing(at, next, WIDE, TALL, has_selection = true,
                reach_selection = reach_selection)
              at = next
            check carried.heldUnder(finish, radius) =~ taken
            check carried.pivot =~ opening.pivot
            check carried.distance =~ opening.distance
            check carried.rollHeld.get =~ opening.rollHeld.get
          # Drag that comes back brings camera back.
          var back = opening
          back.turnFollowing(start, finish, WIDE, TALL, has_selection = true,
            reach_selection = reach_selection)
          back.turnFollowing(finish, start, WIDE, TALL, has_selection = true,
            reach_selection = reach_selection)
          check back.eye =~ opening.eye
          check back.frame.axis_up =~ opening.frame.axis_up
    # Least sphere spans third of short side on screen; eye stays outside every one.
    let least = initCameraDefault().radiusHeld(WIDE, TALL, 0.0)
    let rim = projectToScreen(
      initCameraDefault().initMatrixViewProjection(float(WIDE)/float(TALL)), WIDE, TALL,
      initCameraDefault().pivot + least*initCameraDefault().frame.axis_right,
    )
    check abs((rim.x - float(WIDE)/2.0) - float(WIDE)/3.0) < 1.0
    check initCameraDefault().radiusHeld(WIDE, TALL, 100.0) < initCameraDefault().distance
    # Finger off sphere still turns view, with pivot standing.
    var outside = initCameraDefault()
    outside.turnFollowing(ScreenPosition(x: 20.0, y: 100.0), ScreenPosition(x: 60.0, y: 140.0),
      WIDE, TALL, has_selection = true)
    check not (outside.eye =~ initCameraDefault().eye)
    check outside.pivot =~ initCameraDefault().pivot


  test "a finger's free aim keeps what it took hold of under it, pixel for pixel":
    # Rate turned sight by angle screen does not show: 3.6 times as far as finger on 1200
    #   by 900 page. Carrying sky under one pixel to other keeps it under finger instead.
    const (WIDE, TALL) = (390, 844)
    proc seenThrough(camera: Camera; at: ScreenPosition): Direction =
      # Read unit sight through pixel.
      let heading = camera.headingThrough(camera.frame, WIDE, TALL, at)
      (1.0/norm(heading))*heading
    var rolled = initCameraDefault()
    rolled.roll(0.5)
    let steep = initCamera(pivot = ORIGIN, distance = 19.0, azimuth = 1.05, elevation = -0.7)
    for opening in [initCameraDefault(), rolled, steep]:
      for (start, finish) in [
        (ScreenPosition(x: 195.0, y: 422.0), ScreenPosition(x: 300.0, y: 422.0)),
        (ScreenPosition(x: 100.0, y: 200.0), ScreenPosition(x: 160.0, y: 700.0)),
        (ScreenPosition(x: 350.0, y: 800.0), ScreenPosition(x: 40.0, y: 100.0)),
      ]:
        let taken = opening.seenThrough(start)
        for steps in [1, 16]:
          var
            carried = opening
            at = start
          for step in 1 .. steps:
            let reached = float(step)/float(steps)
            let next = ScreenPosition(
              x: start.x + reached*(finish.x - start.x),
              y: start.y + reached*(finish.y - start.y),
            )
            carried.turnFollowing(at, next, WIDE, TALL, has_selection = false)
            at = next
          check carried.seenThrough(finish) =~ taken
          check carried.eye =~ opening.eye
          check carried.rollHeld.get =~ opening.rollHeld.get
        # Drag that comes back brings camera back.
        var back = opening
        back.turnFollowing(start, finish, WIDE, TALL, has_selection = false)
        back.turnFollowing(finish, start, WIDE, TALL, has_selection = false)
        check back.frame.forward =~ opening.frame.forward
        check back.frame.axis_up =~ opening.frame.axis_up


  test "a finger's drag passes over the pole, and the picture follows the finger past it":
    # Across axis stays level through pole, so sight turns in its own upright plane and
    #   camera comes down far side upside down, keeping its across.
    const (WIDE, TALL) = (390, 844)
    proc dragged(camera: Camera; picked: bool; across, down: float): Camera =
      # Drag finger from middle of canvas by these pixels, in one step.
      let middle = ScreenPosition(x: float(WIDE)/2.0, y: float(TALL)/2.0)
      result = camera
      result.turnFollowing(middle, ScreenPosition(x: middle.x + across, y: middle.y + down),
        WIDE, TALL, has_selection = picked)
    proc sweptBy(camera: Camera; across, down: float): (float, float) =
      # Read how far orbit's drag carries near side, between eye and pivot, across screen.
      let
        near_side = camera.eye + 0.4*camera.distance*camera.frame.forward
        aspect = float(WIDE)/float(TALL)
        was = projectToScreen(camera.initMatrixViewProjection(aspect), WIDE, TALL, near_side)
        swung = camera.dragged(true, across, down)
        now_at = projectToScreen(swung.initMatrixViewProjection(aspect), WIDE, TALL, near_side)
      (now_at.x - was.x, now_at.y - was.y)
    let opening = initCameraDefault()
    # Orbit climbs past straight down in drags down from middle, and near side follows
    #   finger on both sides.
    var over = opening
    for step in 1 .. 4: over = over.dragged(true, 0.0, 80.0)
    check dot(over.frame.axis_up, UP_WORLD) < 0.0
    check over.frame.axis_right =~ opening.frame.axis_right
    check over.pivot =~ opening.pivot
    for camera in [opening, over]:
      check camera.sweptBy(20.0, 0.0)[0] > 0.0
      check camera.sweptBy(0.0, 20.0)[1] > 0.0
    # Look passes under its feet same way: three drags up nearly whole canvas.
    var under = opening
    for step in 1 .. 3:
      under.turnFollowing(ScreenPosition(x: 195.0, y: 800.0), ScreenPosition(x: 195.0, y: 44.0),
        WIDE, TALL, has_selection = false)
    check dot(under.frame.axis_up, UP_WORLD) < 0.0
    check under.frame.axis_right =~ opening.frame.axis_right
    check under.eye =~ opening.eye
    # Sight exactly along world up names no level across, and camera's own stands in.
    var pole = opening
    pole.orbitCarrying(held = UP_WORLD, under = opening.eye - opening.pivot)
    check abs(dot(pole.frame.forward, UP_WORLD)) =~ 1.0
    let past = pole.dragged(true, 0.0, 60.0)
    check abs(dot(past.frame.forward, UP_WORLD)) < 1.0 - 1.0e-3
    check past.frame.axis_right =~ pole.frame.axis_right
    check past.pivot =~ pole.pivot
    let spun = pole.dragged(true, 60.0, 0.0)
    check spun.pivot =~ pole.pivot
    check abs(dot(spun.frame.axis_right, spun.frame.forward)) < TOLERANCE_TEST
    check abs(norm(spun.frame.forward) - 1.0) < TOLERANCE_TEST


  test "a roll carries the picture the way the reader turns":
    # Sign is about what reader sees, so it is read off screen rather than off axes.
    #   Twist sent its screen angle through unturned, and picture rolled against
    #   fingers.
    const (WIDE, TALL) = (1200, 900)
    var camera = initCameraDefault()
    let above = camera.pivot + 3.0*camera.frame.axis_up
    proc seenAt(c: Camera): float =
      projectToScreen(
        c.initMatrixViewProjection(float(WIDE)/float(TALL)), WIDE, TALL, above
      ).x
    let before = seenAt(camera)
    check before =~ float(WIDE)/2.0 # Straight above middle, so any swing is roll's.
    camera.roll(0.2)
    # Point above middle swings left, which reads anticlockwise: positive roll is
    #   anticlockwise, and pointer negates its clockwise screen angle to match.
    check seenAt(camera) < before
    # Eye and sight are untouched by it, which is what makes roll sixth freedom.
    check camera.eye =~ initCameraDefault().eye
    check camera.frame.forward =~ initCameraDefault().frame.forward


  test "held keys compose, and letting one go leaves the other running":
    var
      interaction = Interaction(is_enabled: true)
      camera = initCamera(pivot = ORIGIN, distance = 20.0, azimuth = 0.4, elevation = 0.3)
    interaction.holdKey(Key.W)
    interaction.holdKey(Key.Space)
    interaction.driveHeld(camera, 1.0, has_selection = true)
    let both = camera.pivot
    check both.z > 0.0
    check norm(Direction(x: both.x, y: both.y, z: 0)) > 0.0

    interaction.releaseKey(Key.Space)
    interaction.driveHeld(camera, 1.0, has_selection = true)
    check camera.pivot.z =~ both.z # Lift stopped exactly when its key was let go of.
    check norm(camera.pivot - both) > 0.0 # Slide did not.


  test "with no selection a held key flies along the camera's own axes":
    # Fly reading of movement key rather than map one: forward dives where sight dives,
    #   and up is camera's own up, so rolled camera rises toward its own ceiling.
    var interaction = Interaction(
      is_enabled: true, depth_pointer: some(20.0)
    )
    var camera = initCamera(ORIGIN, 20.0, 0.4, 0.9)
    camera.roll(0.7)
    let (eye_start, axes_start) = (camera.eye, camera.frame)
    interaction.holdKey(Key.W)
    interaction.driveHeld(camera, 1.0, has_selection = false)
    let step = camera.eye - eye_start
    # Whole step lies along sight, and sight is steeply down, so height is lost.
    check dot(step, axes_start.forward) =~ norm(step)
    check step.z < 0.0
    # Nothing turned: flight slides and never turns.
    check camera.frame.forward =~ axes_start.forward
    check camera.frame.axis_up =~ axes_start.axis_up
    # Separation gives up exactly what eye covered, so pivot stands where it stood.
    #   What keeps near clip and furniture's extent on scale reader flies into: near is
    #   one four-hundredth of separation, and separation kept would hold that of stance
    #   camera set off from.
    check camera.distance =~ 20.0 - norm(step)
    check camera.pivot =~ initCamera(ORIGIN, 20.0, 0.4, 0.9).pivot
    check camera.distanceNear =~ camera.distance*FACTOR_CLIP_NEAR

    # Strafe carries pivot along instead: what stands ahead keeps its depth.
    var strafed = initCamera(ORIGIN, 20.0, 0.4, 0.9)
    interaction.releaseKey(Key.W)
    interaction.holdKey(Key.D)
    interaction.driveHeld(strafed, 1.0, has_selection = false)
    check strafed.distance =~ 20.0
    interaction.releaseKey(Key.D)
    interaction.holdKey(Key.W)

    # Space rises along camera's own up, which roll has tipped off world up.
    var lifted = initCamera(ORIGIN, 20.0, 0.4, 0.9)
    lifted.roll(0.7)
    let axes_lifted = lifted.frame
    interaction.releaseKey(Key.W)
    interaction.holdKey(Key.Space)
    let eye_lifted = lifted.eye
    interaction.driveHeld(lifted, 1.0, has_selection = false)
    check dot(lifted.eye - eye_lifted, axes_lifted.axis_up) =~ norm(lifted.eye - eye_lifted)
    check abs(dot(lifted.eye - eye_lifted, UP_WORLD)) < norm(lifted.eye - eye_lifted)

  test "flight climbs toward its cap, and the pointer's depth sets that cap":
    # Two halves of one hold cover more ground than first half twice over, because speed
    #   is still climbing. What reads as spaceship rather than as constant rate.
    var interaction = Interaction(is_enabled: true, depth_pointer: some(20.0))
    interaction.holdKey(Key.W)
    var camera = initCamera(ORIGIN, 20.0, 0.0, 0.0)
    let eye_start = camera.eye
    interaction.driveHeld(camera, 0.5, has_selection = false)
    let first = norm(camera.eye - eye_start)
    let eye_middle = camera.eye
    interaction.driveHeld(camera, 0.5, has_selection = false)
    let second = norm(camera.eye - eye_middle)
    check second > first
    check first + second =~ distanceTravelled(0.0, 1.0, FACTOR_SPEED_LOCAL*20.0)

    # Pointer over something near caps speed low, which is what close work needs.
    var near_work = Interaction(is_enabled: true, depth_pointer: some(0.002))
    near_work.holdKey(Key.W)
    var close = initCamera(ORIGIN, 0.002, 0.0, 0.0)
    let eye_close = close.eye
    near_work.driveHeld(close, 1.0, has_selection = false)
    check norm(close.eye - eye_close) =~ distanceTravelled(
      0.0, 1.0, FACTOR_SPEED_LOCAL*0.002
    )

    # Letting go forgets speed reached, so flight taken up again starts from rest.
    near_work.releaseKey(Key.W)
    check near_work.seconds_travelling =~ 0.0

  test "roll reaches the camera in either state, and free turning in one":
    # `camera.orbit` composes motion now and carries roll through, so roll is granted
    #   with selection as without one.
    var interaction = Interaction(is_enabled: true)
    interaction.holdKey(Key.E)
    var flying = initCamera(ORIGIN, 20.0, 0.4, 0.3)
    var held = flying
    interaction.driveHeld(flying, 0.5, has_selection = false)
    interaction.driveHeld(held, 0.5, has_selection = true)
    let upright = initCamera(ORIGIN, 20.0, 0.4, 0.3)
    # Both rolled, by exactly as much, and neither turned sight or moved eye.
    check flying.frame.axis_up =~ held.frame.axis_up
    check abs(dot(flying.frame.axis_up, upright.frame.axis_right)) > TOLERANCE_TEST
    check flying.eye =~ held.eye
    check flying.frame.forward =~ upright.frame.forward
    check held.frame.forward =~ upright.frame.forward
    # Roll then orbit keeps that roll, which is what earns it selected state.
    held.orbit(0.3, 0.1)
    check abs(dot(held.frame.axis_right, UP_WORLD)) > TOLERANCE_TEST

    # Arrows turn in place with no selection, and orbit about pivot with one.
    interaction.releaseKeysAll()
    interaction.holdKey(Key.Left)
    var turning = initCamera(ORIGIN, 20.0, 0.4, 0.3)
    var orbiting = turning
    let eye_start = turning.eye
    interaction.driveHeld(turning, 0.5, has_selection = false)
    interaction.driveHeld(orbiting, 0.5, has_selection = true)
    check turning.eye =~ eye_start
    check norm(orbiting.eye - eye_start) > TOLERANCE_TEST
    # Both swing sight same way, so one key reads same in either state.
    check dot(turning.frame.forward, orbiting.frame.forward) > 0.0

  test "how far a hold travels depends on how long it was held":
    # Whole point of driving movement per frame: rate stated per second, multiplied.
    #   by frame's own elapsed time, so fast machine and slow one agree.
    var interaction = Interaction(is_enabled: true)
    interaction.holdKey(Key.W)
    var
      once = initCamera(ORIGIN, 20.0, 0.0, 0.3)
      twice = initCamera(ORIGIN, 20.0, 0.0, 0.3)
    interaction.driveHeld(once, 0.5, has_selection = true)
    interaction.driveHeld(twice, 1.0, has_selection = true)
    check norm(twice.pivot - ORIGIN) =~ 2.0*norm(once.pivot - ORIGIN)

    # Dolly is one that compounds rather than adding, so it takes rate to.
    #   power of elapsed seconds: two half-seconds must equal one whole one.
    interaction.releaseKey(Key.W)
    interaction.holdKey(Key.Minus)
    var
      halves = initCamera(ORIGIN, 20.0, 0.0, 0.3)
      whole = initCamera(ORIGIN, 20.0, 0.0, 0.3)
    interaction.driveHeld(halves, 0.5, has_selection = true)
    interaction.driveHeld(halves, 0.5, has_selection = true)
    interaction.driveHeld(whole, 1.0, has_selection = true)
    check halves.distance =~ whole.distance
    check whole.distance =~ 20.0*FACTOR_DOLLY_SECOND


  test "shift makes every movement key faster, and changes none of them":
    var interaction = Interaction(is_enabled: true)
    interaction.holdKey(Key.W)
    var
      plain = initCamera(ORIGIN, 20.0, 0.4, 0.3)
      hastened = initCamera(ORIGIN, 20.0, 0.4, 0.3)
    interaction.driveHeld(plain, 0.25, has_selection = true)
    interaction.holdKey(Key.Shift)
    interaction.driveHeld(hastened, 0.25, has_selection = true)
    # W orbits with selection, so read swing of sight rather than step of pivot.
    let upright = initCamera(ORIGIN, 20.0, 0.4, 0.3).frame.forward
    let risen = arccos(clamp(dot(plain.frame.forward, upright), -1.0, 1.0))
    let risen_fast = arccos(clamp(dot(hastened.frame.forward, upright), -1.0, 1.0))
    check risen_fast =~ FACTOR_HASTE*risen
    # Same direction, not different binding -- which is what shift+arrow used to mean.
    check hastened.elevation > plain.elevation

    var
      turned = initCamera(ORIGIN, 20.0, 0.4, 0.3)
      turned_fast = initCamera(ORIGIN, 20.0, 0.4, 0.3)
    interaction.releaseKeysAll()
    interaction.holdKey(Key.Left)
    interaction.driveHeld(turned, 0.25, has_selection = true)
    interaction.holdKey(Key.Shift)
    interaction.driveHeld(turned_fast, 0.25, has_selection = true)
    # Read swing of sight itself, not azimuth: orbit turns about camera's own up, which
    #   is not world up once elevation is off level, so azimuth is no longer linear in it.
    #   Frame is orthonormal, so sight sweeps exactly angle asked for.
    let forward_start = initCamera(ORIGIN, 20.0, 0.4, 0.3).frame.forward
    let swung = arccos(clamp(dot(turned.frame.forward, forward_start), -1.0, 1.0))
    let swung_fast = arccos(clamp(dot(turned_fast.frame.forward, forward_start), -1.0, 1.0))
    check swung_fast =~ FACTOR_HASTE*swung


  test "letting go of everything at once stops the camera, however it lost the release":
    # Window that loses focus never sees key up, and key left held moves camera.
    #   forever with no press able to stop it.
    var
      interaction = Interaction(is_enabled: true)
      camera = initCamera(pivot = ORIGIN, distance = 20.0, azimuth = 0.4, elevation = 0.3)
    interaction.holdKey(Key.W)
    interaction.holdKey(Key.Shift)
    check interaction.keys_held.len == 2
    interaction.releaseKeysAll()
    check interaction.keys_held.len == 0
    let standing = camera.pivot
    interaction.driveHeld(camera, 1.0, has_selection = true)
    check camera.pivot =~ standing


  test "each key that acts at a press does its own thing, and moves nothing while held":
    var scene = initScene()
    scene.addObject(GENERAL_POINTS[0], "a", Ink.Rose)
    var
      interaction = Interaction(is_enabled: true)
      camera = initCameraDefault()
    let opening = camera

    # Home returns to placement both builds open at, from wherever reader has gone.
    #   Stance alone: lens reader set stays theirs.
    camera.travel(3.0, 2.0, 1.0)
    camera.orbit(0.5, 0.2)
    camera.degrees_field_of_view = 70.0
    discard interaction.applyAction(camera, scene, KeyAction.ViewHome)
    check camera.pivot =~ opening.pivot
    check camera.distance =~ opening.distance
    check camera.azimuth =~ opening.azimuth
    check camera.elevation =~ opening.elevation
    check camera.degrees_field_of_view =~ 70.0

    # Framing is standing offer's own job, so key itself moves nothing: each front.
    #   end releases its tween's goal and `framing.offerAim` aims afresh next frame.
    check interaction.applyAction(camera, scene, KeyAction.FrameSelection).isNone
    check camera.pivot =~ opening.pivot
    check camera.distance =~ opening.distance

    # And key held down is not action at all, however long it is held.
    interaction.holdKey(Key.F)
    interaction.driveHeld(camera, 1.0, has_selection = true)
    check camera.pivot =~ opening.pivot


  test "enter reports the focused handle for the caller to select, and nothing before then":
    var scene = initScene()
    scene.addObject(GENERAL_POINTS[0], "a", Ink.Rose)
    scene.addObject(GENERAL_POINTS[1], "b", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    var camera = initCameraDefault()
    # Pressing enter before stepping anywhere is no-op, not select of handle zero.
    check interaction.applyAction(camera, scene, KeyAction.SelectFocused).isNone
    discard interaction.applyAction(camera, scene, KeyAction.FocusNext)
    check interaction.index_focus == some(0)
    check interaction.applyAction(camera, scene, KeyAction.SelectFocused) == some(0)


  test "a focus whose object is removed is dropped rather than left pointing at freed storage":
    var scene = initScene()
    scene.addObject(GENERAL_POINTS[0], "a", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    var camera = initCameraDefault()
    discard interaction.applyAction(camera, scene, KeyAction.FocusNext)
    check interaction.index_focus == some(0)
    scene.removeObject(0)
    interaction.pruneFocus(scene)
    check interaction.index_focus.isNone


  test "a camera move is not a hover, however much it sweeps the pointer past":
    # Hover is recomputed from cursor every frame, so pan drags ring across every.
    #   object it sweeps and held W lights up whatever slides under cursor standing
    #   still. Neither gesture is pointing at anything.
    var scene = initScene()
    let pivot = Position(x: 0, y: 0, z: 0)
    scene.addObject(toMultivector(pivot), "p", Ink.Rose)
    var
      interaction = Interaction(is_enabled: true)
      camera = initCamera(pivot = pivot, distance = 10.0, azimuth = 0.0, elevation = 0.0)
    let view_projection = camera.initMatrixViewProjection(800.0/600.0)
    proc hovering(interaction: var Interaction): Option[int] =
      interaction.updateHover(
        scene, camera, camera.drawExtentFor(600), view_projection, 800, 600,
      )
      interaction.index_hover
    interaction.updateCursor(400.0, 300.0) # Straight at object.
    check interaction.hovering == some(0)

    interaction.is_dragging_camera = true
    check interaction.hovering.isNone
    interaction.is_dragging_camera = false
    check interaction.hovering == some(0) # And back frame gesture ends.

    interaction.holdKey(Key.W)
    check interaction.hovering.isNone
    interaction.releaseKey(Key.W)
    check interaction.hovering == some(0)

    # Shift alone moves nothing, so it is not camera move and hover stands.
    interaction.holdKey(Key.Shift)
    check interaction.hovering == some(0)
    interaction.releaseKey(Key.Shift)

    # *construction* drag is opposite case: what it points at is whole gesture.
    check interaction.beginDrag(arming = MenuArming.OnDwell, now = 0.0)
    check interaction.hovering == some(0)


  test "keyboard focus is not hover, and a pointer moving does not erase it":
    # Whole reason `index_focus` is its own field: `updateHover` recomputes hover from.
    #   cursor every frame, so focus stored there would be gone before it was drawn.
    var scene = initScene()
    let pivot = Position(x: 0, y: 0, z: 0)
    scene.addObject(toMultivector(pivot), "p", Ink.Rose)
    scene.addObject(GENERAL_POINTS[5], "far", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    var camera = initCamera(pivot = pivot, distance = 10.0, azimuth = 0.0, elevation = 0.0)
    discard interaction.applyAction(camera, scene, KeyAction.FocusNext)
    check interaction.index_focus == some(0)
    interaction.updateCursor(799.0, 1.0) # Corner, away from everything.
    interaction.updateHover(
      scene, camera, camera.drawExtentFor(600),
      camera.initMatrixViewProjection(800.0/600.0), 800, 600,
    )
    check interaction.index_hover != interaction.index_focus
    check interaction.index_focus == some(0)


  test "a drag that keeps moving never opens its menu, however long it stays on pivot":
    # Dwell measures being *still*, not being over something. While it ran on presence.
    #   alone, slow finger crossing one large object -- plane's disc spans most of
    #   phone screen -- had menu open on it mid-gesture, and construction it was in
    #   middle of then released into menu and built nothing. Found by driving real
    #   touch drag, not by reading code.
    var scene = initScene()
    scene.addObject(GENERAL_FIRST[0], "a", Ink.Rose)
    scene.addObject(GENERAL_SECOND[0], "b", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.updateCursor(100.0, 100.0)
    interaction.index_hover = some(0)
    discard interaction.beginDrag(arming = MenuArming.OnDwell, now = 0.0)
    interaction.index_hover = some(1)
    for step in 1 .. 20:
      # Three times dwell, and never still for two frames together.
      interaction.updateCursor(100.0 + 2.0*PIXELS_TAP_SLOP*float(step), 100.0)
      interaction.updateDrag(scene, 0.15*SECONDS_DWELL_MENU*float(step))
      check interaction.menu.isNone
    # Stop moving, and same drag opens it dwell later -- clock is restarted, not.
    #   disabled, so gesture reader actually wanted still works.
    #   Dwell past last movement with room to spare: what is being checked here is
    #   that clock restarts rather than stops, not where its own boundary lies, and
    #   two tests below pin that boundary exactly.
    interaction.updateDrag(scene, 0.15*SECONDS_DWELL_MENU*20.0 + 1.5*SECONDS_DWELL_MENU)
    check interaction.menu.isSome


  test "a drift smaller than the tap slop still counts as holding still":
    # Other half of rule: hand shakes. Dwell that any tremor could restart is.
    #   dwell nobody can ever reach, which is why threshold is same fingertip
    #   slop that decides press from drag rather than exact equality.
    var scene = initScene()
    scene.addObject(GENERAL_FIRST[0], "a", Ink.Rose)
    scene.addObject(GENERAL_SECOND[0], "b", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.updateCursor(100.0, 100.0)
    interaction.index_hover = some(0)
    discard interaction.beginDrag(arming = MenuArming.OnDwell, now = 0.0)
    interaction.index_hover = some(1)
    for step in 1 .. 4:
      interaction.updateCursor(100.0 + 0.2*PIXELS_TAP_SLOP*float(step), 100.0)
      interaction.updateDrag(scene, 0.2*SECONDS_DWELL_MENU*float(step))
    interaction.updateDrag(scene, SECONDS_DWELL_MENU)
    check interaction.menu.isSome


  test "leaving the pivot restarts the dwell, so pausing on the way across never opens":
    var scene = initScene()
    scene.addObject(GENERAL_FIRST[0], "a", Ink.Rose)
    scene.addObject(GENERAL_SECOND[0], "b", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.index_hover = some(0)
    discard interaction.beginDrag(arming = MenuArming.OnDwell, now = 1000.0)
    interaction.index_hover = some(1)
    interaction.updateDrag(scene, 1000.0 + 0.9*SECONDS_DWELL_MENU)
    check interaction.menu.isNone
    interaction.index_hover = none(int) # Slipped off pivot.
    interaction.updateDrag(scene, 1000.0 + 0.95*SECONDS_DWELL_MENU)
    check interaction.preview.isNone
    interaction.index_hover = some(1) # And back on, with dwell owed in full again.
    interaction.updateDrag(scene, 1000.0 + 1.5*SECONDS_DWELL_MENU)
    check interaction.menu.isNone


  test "the rubber-band warns before the release, never after it":
    var scene = initScene()
    scene.addObject(GENERAL_FIRST[2], "G", Ink.Rose)
    scene.addObject(GENERAL_SECOND[0], "f", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.index_hover = some(0)
    discard interaction.beginDrag(arming = MenuArming.OnDwell, now = 0.0)
    # Crossing empty space says nothing either way.
    interaction.index_hover = none(int)
    interaction.updateDrag(scene, 0.0)
    check interaction.inkOfDrag(scene.inkNext) == Ink.Guide
    # Standing over pair that makes nothing wears reserved magenta, and shows no.
    #   preview -- two signals, so warning is never colour alone.
    interaction.index_hover = some(1)
    interaction.updateDrag(scene, 0.0)
    check interaction.inkOfDrag(scene.inkNext) == Ink.Invalid
    check interaction.preview.isNone


  test "disabled interaction never hovers":
    var scene = initScene()
    scene.addObject(POINTS[0], "a", Ink.Rose)
    var interaction = Interaction(is_enabled: false)
    let camera = initCamera(pivot = PLACES[0], distance = 10.0, azimuth = 0.0, elevation = 0.0)
    interaction.updateCursor(400.0, 300.0)
    interaction.updateHover(
      scene, camera, camera.drawExtentFor(600),
      camera.initMatrixViewProjection(800.0/600.0), 800, 600,
    )
    check interaction.index_hover.isNone


  test "enabled interaction hovers the object under the cursor":
    var scene = initScene()
    let pivot = Position(x: 0, y: 0, z: 0)
    scene.addObject(toMultivector(pivot), "p", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    let camera = initCamera(pivot = pivot, distance = 10.0, azimuth = 0.0, elevation = 0.0)
    interaction.updateCursor(400.0, 300.0)
    interaction.updateHover(
      scene, camera, camera.drawExtentFor(600),
      camera.initMatrixViewProjection(800.0/600.0), 800, 600,
    )
    check interaction.index_hover == some(0)


  test "a hold reports no progress until one is begun, and none again once cancelled":
    var interaction = Interaction(is_enabled: true)
    check progressHold(interaction, 1000.0) == 0.0
    check not isHoldMature(interaction, 1000.0)
    interaction.beginHold(3, 1000.0)
    # Measured past grow, which fill starts after; see `swellHold`.
    const FULL = 1000.0 + SECONDS_SWELL_GROW + SECONDS_LONG_PRESS
    check progressHold(interaction, FULL) == 1.0
    interaction.cancelHold()
    check progressHold(interaction, FULL) == 0.0
    check not isHoldMature(interaction, FULL)


  test "a hold fills linearly, is clamped at both ends, and is due exactly when full":
    var interaction = Interaction(is_enabled: true)
    interaction.beginHold(0, 1000.0)
    # Fill starts once marker has grown clear of finger, so every time below is.
    #   measured from end of that grow rather than from press.
    const FILLING = 1000.0 + SECONDS_SWELL_GROW
    # Linear, not eased: half wait is half fill. This is property that makes.
    #   marker clock reader can judge remaining time from, and it is what
    #   `easeOutCubic` here would break -- see `progressHold`'s own doc comment.
    check progressHold(interaction, FILLING + 0.5*SECONDS_LONG_PRESS) =~ 0.5
    check progressHold(interaction, FILLING + 0.25*SECONDS_LONG_PRESS) =~ 0.25
    # Nothing fills while marker is still getting out of way.
    check progressHold(interaction, 1000.0 + 0.5*SECONDS_SWELL_GROW) == 0.0
    var previous = 0.0
    for step in 0 .. 20:
      let progress = progressHold(
        interaction, FILLING + float(step)/20.0*SECONDS_LONG_PRESS
      )
      check progress >= previous
      previous = progress
    # Clamped below, so clock that steps backward cannot un-fill marker, and above, so.
    #   frame arriving late still draws whole one rather than overshooting past it.
    check progressHold(interaction, 900.0) == 0.0
    check progressHold(interaction, FILLING + 10.0*SECONDS_LONG_PRESS) == 1.0
    # Maturity lands exactly where fill completes, never frame either side of it.
    check not isHoldMature(interaction, FILLING + 0.999*SECONDS_LONG_PRESS)
    check isHoldMature(interaction, FILLING + SECONDS_LONG_PRESS)


  test "the swell grows, waits out the whole hold, and settles only once the finger lifts":
    # Defect this pins: swell used to be half sine over fill, so marker.
    #   was back to its true size at exactly moment selection landed -- shrinking
    #   while reader was still deciding, and gone when it mattered.
    var interaction = Interaction(is_enabled: true)
    interaction.beginHold(0, 1000.0)
    check swellHold(interaction, 1000.0) =~ 0.0
    check swellHold(interaction, 1000.0 + SECONDS_SWELL_GROW) =~ 1.0
    # Fully out before fill starts, so marker fills at size it will fill at.
    check swellHold(interaction, 1000.0 + SECONDS_SWELL_GROW) >=
      swellHold(interaction, 1000.0 + 0.5*SECONDS_SWELL_GROW)

    # Check swell stays out for whole fill, past maturity, and while finger stays down.
    #   Unreleased hold never settles, however long it is held.
    const MATURED = 1000.0 + SECONDS_SWELL_GROW + SECONDS_LONG_PRESS
    for now in [MATURED - 0.5*SECONDS_LONG_PRESS, MATURED, MATURED + 60.0]:
      check swellHold(interaction, now) =~ 1.0
      check not isHoldSpent(interaction, now)

    # And settles exactly one shrink after lift, not before and not later.
    interaction.releaseHold(MATURED + 5.0)
    check swellHold(interaction, MATURED + 5.0) =~ 1.0
    check swellHold(interaction, MATURED + 5.0 + SECONDS_SWELL_SHRINK) =~ 0.0
    check not isHoldSpent(interaction, MATURED + 5.0 + 0.5*SECONDS_SWELL_SHRINK)
    # Frame past shrink rather than exactly on it: subtracting two large timestamps.
    #   does not land on boundary exactly, and no caller asks at exact instant --
    #   they ask once frame. What matters is that it is not spent early and is spent.
    check isHoldSpent(interaction, MATURED + 5.0 + 1.1*SECONDS_SWELL_SHRINK)
    # Second lift is not second settle: first one owns clock.
    interaction.releaseHold(MATURED + 900.0)
    check isHoldSpent(interaction, MATURED + 5.0 + 1.1*SECONDS_SWELL_SHRINK)


  test "a matured hold is taken once, and never again however long it is held":
    # Regression this pins, measured: hold of 1.62 s selected its object and then lost.
    #   it within 50 ms of lift. Caller asked "is it mature" beside its own flag for
    #   "have I acted on that", cleared flag on release, and still-settling --
    #   still mature -- hold selected second time and toggled it straight back off.
    var interaction = Interaction(is_enabled: true)
    interaction.beginHold(4, 1000.0)
    const MATURED = 1000.0 + SECONDS_SWELL_GROW + SECONDS_LONG_PRESS
    # Nothing to take while it is still filling.
    check takeHold(interaction, MATURED - 0.01).isNone
    check takeHold(interaction, MATURED) == some(4)
    # Not second time, at any later moment of hold...
    for now in [MATURED, MATURED + 0.001, MATURED + 5.0, MATURED + 600.0]:
      check takeHold(interaction, now).isNone
    # ...nor across release and its whole settle, which is exactly where it fired.
    interaction.releaseHold(MATURED + 5.0)
    for now in [MATURED + 5.0, MATURED + 5.0 + 0.5*SECONDS_SWELL_SHRINK,
                MATURED + 5.0 + 2.0*SECONDS_SWELL_SHRINK]:
      check takeHold(interaction, now).isNone
    # Taking it does not end it: swell still has settle to run out.
    check swellHold(interaction, MATURED + 5.0) =~ 1.0

    # And fresh press is fresh hold, takeable on its own terms.
    #   Asked frame past boundary rather than exactly on it: summing large base
    #   with two small durations does not land there. Same arithmetic reads
    #   0.9999999999997817 from base of 2000 and 1.000000000000009 from 1000, and no
    #   caller asks at instant anyway -- they ask once frame.
    interaction.beginHold(7, 2000.0)
    check takeHold(interaction, 2000.0).isNone
    check takeHold(
      interaction, 2000.0 + SECONDS_SWELL_GROW + 1.01*SECONDS_LONG_PRESS
    ) == some(7)


  test "a cancelled hold snaps away rather than settling":
    # Cancelling is press that stopped being one -- moved into camera gesture, or.
    #   interrupted -- so there is nothing left for settle to be about.
    var interaction = Interaction(is_enabled: true)
    interaction.beginHold(0, 1000.0)
    check swellHold(interaction, 1000.0 + SECONDS_SWELL_GROW) =~ 1.0
    interaction.cancelHold()
    check swellHold(interaction, 1000.0 + SECONDS_SWELL_GROW) =~ 0.0
    check not isHoldSpent(interaction, 1000.0 + 10.0)


  test "the panel's speed is the one flight steps by, and none while nothing is held":
    var interaction = Interaction(is_enabled: true)
    let camera = initCameraDefault()
    check interaction.speedFlying(camera) == 0.0
    interaction.keys_held = {Key.W}
    interaction.seconds_travelling = SECONDS_SPEED_RISE
    let cap = capTravelling(interaction.depth_pointer, camera.distance, 1.0)
    check interaction.speedFlying(camera) =~ speedTravelling(SECONDS_SPEED_RISE, cap)
    # Shift is one multiplier on every rate, speed included.
    interaction.keys_held = {Key.W, Key.Shift}
    check interaction.speedFlying(camera) =~ FACTOR_HASTE*speedTravelling(SECONDS_SPEED_RISE, cap)
