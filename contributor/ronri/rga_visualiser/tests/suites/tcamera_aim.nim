## Run `Camera Aim` suite: one module of shared suite, which `../suites.nim` imports in order.

import ./fixtures


suite "Camera Aim":
  let SCALE_AIM = DrawExtent(scale: DrawScale(
    extent_furniture: 100.0,
    eye: ORIGIN,
    radius_horizon: 90.0,
  )) ## No ribbon fields: nothing here tessellates anything, it only aims camera.

  const
    (WIDTH_AIM, HEIGHT_AIM) = (1440, 900) ## Frame centred box is measured in.
    AZIMUTHS_AIM = [0.0, 0.7, 1.6, 2.4, 3.1]
    ELEVATIONS_AIM = [-0.6, 0.2, 0.9]
      ## Sweep framing rule over these orientations.
      ##   Swept, not sampled at one camera: rule about screen geometry passing
      ##   single-orientation check can be plainly wrong from camera nobody looked from.

  proc marginsCentred(): (float, float) =
    ## Measure how far in centred box begins, across and down, in this suite's frame.
    ##   Read out of `camera.reachCentred` rather than written again here, so case
    ##   checking something *against* box cannot come to disagree with box.
    let (reach_across, reach_down) = reachCentred(WIDTH_AIM, HEIGHT_AIM, 0.0)
    (0.5*(float(WIDTH_AIM) - reach_across), 0.5*(float(HEIGHT_AIM) - reach_down))


  proc stanceAim(azimuth, elevation: float): Camera =
    ## Build camera orbiting origin at given angles, for sweeps below.
    initCamera(pivot = ORIGIN, distance = 12.0, azimuth = azimuth, elevation = elevation)

  proc sceneOf(objects: varargs[Multivector]): (Scene, Selection) =
    ## Build scene holding exactly these objects, with every one of them picked.
    var (scene, picked) = (initScene(), Selection())
    for m in objects:
      picked.toggle(scene.addObject(m, "m", Ink.Rose))
    (scene, picked)

  proc offerAim(
    tween: var CameraTween; camera: var Camera; scene: Scene; picked: Selection;
    staged: Option[Preview]; scale: DrawExtent; width, height: int; now, duration: float
  ) =
    ## Offer with no pointer pick, as list and keyboard picks do.
    ##   Overload for cases about framing rule alone; pointer rule's cases pass their own.
    var pointer = none(PointerPick)
    tween.offerAim(camera, scene, picked, staged, scale, width, height, now, duration, pointer)

  proc framedFor(
    scene: Scene, picked: Selection, camera: Camera
  ): CameraStance =
    ## Resolve where framing rule puts camera for whole selection.
    let aim = aimFor(scene, picked, none(Preview), camera.drawExtentFor(HEIGHT_AIM))
    check aim.isSome
    stanceFor(aim.get, camera, WIDTH_AIM, HEIGHT_AIM)


  test "on screen is not in view: the box is two thirds of the frame, not all of it":
    # What whole rule rests on. Object clinging to edge is visible without.
    #   being what view is about, and this is case that says so.
    let point = toMultivector(Position(x: 9.0, y: -7.0, z: 4.0))
    let camera = stanceAim(1.6, 0.2)
    let at = projectToScreen(
      camera.initMatrixViewProjection(WIDTH_AIM/HEIGHT_AIM), WIDTH_AIM, HEIGHT_AIM,
      anchorFor(point, camera.drawExtentFor(HEIGHT_AIM)).get,
    )
    check at.isInFront
    check at.x >= 0.0 and at.x <= float(WIDTH_AIM) # On screen ...
    check at.y >= 0.0 and at.y <= float(HEIGHT_AIM)
    check at.y < 0.5*(1.0 - FRACTION_VIEW_CENTRED)*float(HEIGHT_AIM) # ... above box.
    check not isShownCentrally(point, camera, WIDTH_AIM, HEIGHT_AIM)


  proc offsetFromPivot(camera: Camera; across, down: float): Multivector =
    ## Build point standing off camera's own pivot, sideways and downward.
    ##   By these fractions of its orbit distance, i.e. by those tangents from sight axis,
    ##   since offsets are square to it and so leave depth alone.
    let axes = camera.frame
    toMultivector(
      camera.pivot + (across*camera.distance)*axes.axis_right -
        (down*camera.distance)*axes.axis_up
    )


  test "a wider window does not widen what counts as in view":
    # Defect box's shape exists to prevent. Field of view is vertical, so.
    #   fraction of frame's *width* is `aspect` times as much world: on shipped
    #   build box reached 23.9 degrees off sight axis across 1440x900 window
    #   against 15.4 down, and 7.3 across 390x844 phone. Picking object on desktop
    #   therefore almost never moved camera, which is whole complaint. Every width
    #   from square to twice height now returns one verdict.
    for azimuth in AZIMUTHS_AIM:
      for elevation in ELEVATIONS_AIM:
        let camera = stanceAim(azimuth, elevation)
        for step in 1 .. 12:
          let place = offsetFromPivot(camera, 0.06*float(step), 0.0)
          let verdict = isShownCentrally(place, camera, HEIGHT_AIM, HEIGHT_AIM)
          for width in [HEIGHT_AIM, 1200, WIDTH_AIM, 2*HEIGHT_AIM]:
            check isShownCentrally(place, camera, width, HEIGHT_AIM) == verdict


  test "the box never reaches further across than it reaches down":
    # Property that makes one above true of *every* frame rather than of wide ones.
    #   only: tall frame keeps its own narrower reach across -- phone held upright is
    #   deliberately left as it was -- so rule is implication, not equality.
    for (width, height) in [(HEIGHT_AIM, HEIGHT_AIM), (WIDTH_AIM, HEIGHT_AIM), (390, 844)]:
      for azimuth in AZIMUTHS_AIM:
        let camera = stanceAim(azimuth, 0.2)
        for step in 1 .. 14:
          let reach = 0.06*float(step)
          if isShownCentrally(offsetFromPivot(camera, reach, 0.0), camera, width, height):
            check isShownCentrally(
              offsetFromPivot(camera, 0.0, reach), camera, width, height
            )


  test "on a wide frame the box is as far across as it is down, to the pixel":
    # Kind itself, measured rather than asserted: walk point out sideways until it.
    #   leaves box and check where it went. Edge stands at frame's *height*,
    #   not its width -- 300 px from middle of 1440x900 frame rather than 480 -- less
    #   room drawn dot takes.
    let camera = stanceAim(0.0, 0.0)
    let
      edge_measured = 0.5*FRACTION_VIEW_CENTRED*float(HEIGHT_AIM) - INSET_POINT_SHOWN
      edge_by_width = 0.5*FRACTION_VIEW_CENTRED*float(WIDTH_AIM) - INSET_POINT_SHOWN
    var reach_last = 0.0
    for step in 1 .. 2000:
      let reach = 0.001*float(step)
      if not isShownCentrally(
        offsetFromPivot(camera, reach, 0.0), camera, WIDTH_AIM, HEIGHT_AIM
      ): break
      reach_last = reach
    # Back out of tangent sweep stopped at into pixels it stands for.
    let edge_found = reach_last*0.5*float(HEIGHT_AIM) /
      tan(0.5*degToRad(camera.degrees_field_of_view))
    check abs(edge_found - edge_measured) < 2.0
    check abs(edge_found - edge_by_width) > 100.0


  test "a point and a plane have to fit inside the box; a line only to cross it":
    # Two criteria, stated apart, and split follows what each shape is *drawn* at.
    #   Line runs out to horizon, which moves with camera, so demanding it fit
    #   would demand camera pulled back until it was speck. Plane's disc is fixed
    #   `EXTENT_PLANE_F` across whatever camera does, so it is thing frame can hold.
    let camera = stanceAim(0.0, 0.2)
    let
      far_away = Position(x: 26.0, y: 0.0, z: 0.0)
      near_middle = Position(x: 0.0, y: 0.0, z: 0.4)
    let
      point = toMultivector(far_away)
      line = toMultivector(far_away) ∧ toMultivector(near_middle)
      plane = toMultivector(far_away) ∧ toMultivector(near_middle) ∧
        toMultivector(Position(x: 0.0, y: 1.0, z: 0.4))
    # All three reach that same far point; line alone is in view for merely doing so.
    check not isShownCentrally(point, camera, WIDTH_AIM, HEIGHT_AIM)
    check isShownCentrally(line, camera, WIDTH_AIM, HEIGHT_AIM)
    check not isShownCentrally(plane, camera, WIDTH_AIM, HEIGHT_AIM)


  test "a previewed construction carries where it is drawn and what it came from":
    # One statement of construction not yet committed, shared by drag's own.
    #   rubber-band answer and both apply pickers. Line joined with point is case
    #   that exercises every field at once: it makes plane, and that plane's disc is
    #   centred on construction's own point rather than on its closest approach to
    #   origin.
    var (scene, picked) = (initScene(), Selection())
    let
      line = GENERAL_FIRST[1]
      point = GENERAL_SECOND[0]
      handle_line = scene.addObject(line, "L", Ink.Rose)
      handle_point = scene.addObject(point, "p", Ink.Rose)
    let previewed = scene.previewApplying(Operation.Wedge, handle_line, handle_point)
    check previewed.get.geometry =~ applyOperation(Operation.Wedge, line, point)
    check previewed.get.operands == some((handle_line, handle_point))
    check previewed.get.anchor.get =~
      creationAnchor(Operation.Wedge, line, point, previewed.get.geometry).get
    check not (previewed.get.anchor.get =~ positionAnchor(previewed.get.geometry).get)

    # Nothing drawable, nothing previewed -- one test that covers pair of wrong.
    #   grades and pair already lying on each other alike.
    check scene.previewApplying(Operation.WedgeAnti, handle_point, handle_point).isNone
    # And nothing at all where picker is left open across delete.
    scene.removeObject(handle_point)
    check scene.previewApplying(Operation.Wedge, handle_line, handle_point).isNone

    # Edit session's own staged geometry is same type with neither field, which is.
    #   what keeps it out of framing rule below.
    check previewStaging(line, RADIUS_OBJECT_DEFAULT).anchor.isNone
    check previewStaging(line, RADIUS_OBJECT_DEFAULT).operands.isNone
    # Preview of point under edit is drawn at session's own radius, not default.
    check previewStaging(line, 0.03).radius == 0.03
    discard picked


  test "a staged preview is framed with the operands it names; an edit stands alone":
    # What reader is judging when picker previews operation is *result beside.
    #   its inputs*: plane that fits frame while two points that made it sit off
    #   edge answers nothing. Edit session is opposite case and must stay that
    #   way -- its staged geometry replaces very object it would be framed against.
    var scene = initScene()
    let
      handle_first = scene.addObject(
        toMultivector(Position(x: 16.0, y: -13.0, z: 4.0)), "m", Ink.Rose
      )
      handle_second = scene.addObject(
        toMultivector(Position(x: -12.0, y: 14.0, z: -6.0)), "n", Ink.Rose
      )
    let staged = scene.previewApplying(Operation.Wedge, handle_first, handle_second)
    check staged.isSome
    for azimuth in AZIMUTHS_AIM:
      for elevation in ELEVATIONS_AIM:
        let camera = stanceAim(azimuth, elevation)
        let aim = aimFor(scene, Selection(), staged, camera.drawExtentFor(HEIGHT_AIM))
        let framed = camera.placed(stanceFor(aim.get, camera, WIDTH_AIM, HEIGHT_AIM))
        check isShownAll(
          scene, Selection(), staged, framed, WIDTH_AIM, HEIGHT_AIM
        )
        # Each operand by name, not merely "everything watched" -- that is property.
        for handle in [handle_first, handle_second]:
          check isShownCentrally(
            scene.geometryOf(handle), framed, WIDTH_AIM, HEIGHT_AIM,
            scene.anchorOverrideAt(handle),
          )
        # Two points that far apart cannot both be framed by panning alone.
        check framed.distance > camera.distance

    # Edit-session case, over same pair: staging one of those points names no.
    #   operands, so other is left out and no pull-back is owed.
    let alone = some(previewStaging(scene.geometryOf(handle_first), RADIUS_OBJECT_DEFAULT))
    let camera = stanceAim(0.7, 0.2)
    let aim = aimFor(scene, Selection(), alone, camera.drawExtentFor(HEIGHT_AIM))
    let framed = camera.placed(stanceFor(aim.get, camera, WIDTH_AIM, HEIGHT_AIM))
    check isShownAll(scene, Selection(), alone, framed, WIDTH_AIM, HEIGHT_AIM)
    check framed.distance == camera.distance
    check not isShownCentrally(
      scene.geometryOf(handle_second), framed, WIDTH_AIM, HEIGHT_AIM
    )


  test "a plane is centred by its middle and bounded by its rim, against two bounds":
    # Two questions disc's own size forces apart. Its centre says whether plane is.
    #   what view is about, so it answers to centred box like any other position;
    #   its rim says only whether whole circle can be seen, so it answers to frame.
    #   Holding rim to box as well is what made picking demo's ground plane
    #   throw camera from 19 out to 29.9 where 19 already showed whole circle.
    let ground = toMultivector(ORIGIN) ∧ toMultivector(Position(x: 1.0, y: 0.0, z: 0.0)) ∧
      toMultivector(Position(x: 0.0, y: 1.0, z: 0.0))
    let (margin_x, margin_y) = marginsCentred()

    proc rimAt(place: Camera, centre: Position): tuple[is_past_box, is_off_frame: bool] =
      ## Walk drawn rim, reporting whether it reaches past centred box or leaves frame.
      ##   Two bounds this rule tells apart.
      let
        axes = frame(ground).get
        view_projection = place.initMatrixViewProjection(WIDTH_AIM/HEIGHT_AIM)
      for step in 0 ..< 96:
        let turn = (2.0*PI*float(step))/96.0
        let at = projectToScreen(
          view_projection, WIDTH_AIM, HEIGHT_AIM,
          centre + EXTENT_PLANE_F*(cos(turn)*axes.axis_first + sin(turn)*axes.axis_second),
        )
        if at.x < margin_x or at.x > float(WIDTH_AIM) - margin_x or
            at.y < margin_y or at.y > float(HEIGHT_AIM) - margin_y:
          result.is_past_box = true
        if at.x < 0.0 or at.x > float(WIDTH_AIM) or
            at.y < 0.0 or at.y > float(HEIGHT_AIM):
          result.is_off_frame = true

    # Standing where rim reaches past centred box and stays on screen: in view, and.
    #   *because* rim is only held to frame. Both halves asserted, neither assumed.
    var camera = stanceAim(0.0, 0.42)
    camera = camera.placedAtDistance(19.0)
    let spread = rimAt(camera, positionAnchor(ground).get)
    check spread.is_past_box
    check not spread.is_off_frame
    check isShownCentrally(ground, camera, WIDTH_AIM, HEIGHT_AIM)

    # Now far enough back that whole disc fits well inside frame, and walk where it.
    #   is drawn out sideways until its own centre leaves centred box. Rim is still
    #   wholly on screen there, so what refuses it is centre alone -- half
    #   rim-only test would miss.
    var afar = camera
    afar = afar.placedAtDistance(40.0)
    let projection_afar = afar.initMatrixViewProjection(WIDTH_AIM/HEIGHT_AIM)
    # Sideways along camera's own right, which at any elevation lies flat in plane.
    #   disc is drawn in -- so this walks where circle is centred without lifting it
    #   off its own plane, and moves it across screen rather than into distance.
    let across = afar.frame.axis_right
    var found_off_centre = false
    for step in 1 .. 60:
      let drawn = ORIGIN + float(step)*across
      let at = projectToScreen(projection_afar, WIDTH_AIM, HEIGHT_AIM, drawn)
      let is_centre_out = at.x < margin_x or at.x > float(WIDTH_AIM) - margin_x or
        at.y < margin_y or at.y > float(HEIGHT_AIM) - margin_y
      if not (is_centre_out and not rimAt(afar, drawn).is_off_frame): continue
      found_off_centre = true
      check not isShownCentrally(ground, afar, WIDTH_AIM, HEIGHT_AIM, some(drawn))
      break
    check found_off_centre # Walk really did straddle it, so check above ran.

    # And close in, where rim leaves frame, it is out of view however centred it is.
    var near = camera
    near = near.placedAtDistance(6.0)
    check rimAt(near, positionAnchor(ground).get).is_off_frame
    check not isShownCentrally(ground, near, WIDTH_AIM, HEIGHT_AIM)


  test "a plane filling the frame is not in view; framing pulls its whole disc in":
    # Complaint this rule was rewritten for: disc wide enough to cover box was.
    #   read as in view -- sight axis struck it, so picking it moved camera not at
    #   all -- while reader could see no edge of circle anywhere.
    # Sized by sphere holding its disc now, so it lands further out than its own pixel
    #   reading asked: that is what one bounding sphere costs.
    let ground = toMultivector(ORIGIN) ∧ toMultivector(Position(x: 1.0, y: 0.0, z: 0.0)) ∧
      toMultivector(Position(x: 0.0, y: 1.0, z: 0.0))
    let (scene, picked) = sceneOf(ground)
    for azimuth in AZIMUTHS_AIM:
      for elevation in ELEVATIONS_AIM:
        # Close in, where disc of radius `EXTENT_PLANE_F` cannot fit at all.
        var camera = stanceAim(azimuth, elevation)
        camera = camera.placedAtDistance(6.0)
        check not isShownCentrally(ground, camera, WIDTH_AIM, HEIGHT_AIM)
        let framed = camera.placed(framedFor(scene, picked, camera))
        check isShownCentrally(ground, framed, WIDTH_AIM, HEIGHT_AIM)
        check framed.distance > camera.distance # Only pull-back could have done it.
        # Every point of rim, not just two box's own axes happen to catch.
        let axes = frame(ground).get
        let view_projection =
          framed.initMatrixViewProjection(WIDTH_AIM/HEIGHT_AIM)
        let (margin_x, margin_y) = marginsCentred()
        for step in 0 ..< 96:
          let turn = (2.0*PI*float(step))/96.0
          let at = projectToScreen(
            view_projection, WIDTH_AIM, HEIGHT_AIM,
            positionAnchor(ground).get + EXTENT_PLANE_F*(
              cos(turn)*axes.axis_first + sin(turn)*axes.axis_second
            ),
          )
          check at.isInFront
          check at.x >= 0.0 and at.x <= float(WIDTH_AIM)
          check at.y >= 0.0 and at.y <= float(HEIGHT_AIM)
          # Whole rim is inside centred box as well, which is price of one bounding
          #   sphere: plane's own looser reading, rim merely on screen, no longer sizes
          #   framing. Sphere holding disc from every side is what does.
          check at.x >= margin_x and at.x <= float(WIDTH_AIM) - margin_x
          check at.y >= margin_y and at.y <= float(HEIGHT_AIM) - margin_y
        # It costs exactly what holding that sphere costs, and not step more.
        check norm(framed.eye - positionAnchor(ground).get) =~
          distanceFitting(EXTENT_PLANE_F, camera, WIDTH_AIM, HEIGHT_AIM, INSET_POINT_SHOWN)


  test "a plane reaching every corner of the frame is backdrop, and a lesser one is not":
    # Backdrop is what press falls through to camera on, so view can be moved off plane
    #   filling it. Rule asked disc to span frame's longer side, 1200 px, where reach to
    #   furthest corner is 750: plane covering every pixel still read as drag handle.
    const (WIDE, TALL) = (1200, 900)
    let corner = 0.5*hypot(float(WIDE), float(TALL))
    check corner =~ 750.0
    var scene = initScene()
    let ground = scene.addObject(
      toMultivector(ORIGIN) ∧ toMultivector(Position(x: 1.0, y: 0.0, z: 0.0)) ∧
        toMultivector(Position(x: 0.0, y: 1.0, z: 0.0)),
      "ground", inkCycled(0),
    )
    proc scaleAt(distance: float): DrawExtent =
      initCamera(
        pivot = ORIGIN, distance = distance, azimuth = 0.0, elevation = 0.9
      ).drawExtentFor(TALL)
    proc spanAt(distance: float): float =
      ## Read drawn disc's radius in pixels, as `isBackdropUnder` reads it.
      let scale = scaleAt(distance)
      let anchor = anchorFor(
        scene.geometryOf(ground), scene.anchorOverrideAt(ground), scale
      )
      check anchor.isSome
      EXTENT_PLANE_F/worldPerPixelAt(anchor.get, scale.scale)

    # Nine units off, disc spans 965.7 px: every pixel covered, and short of longer side.
    #   That band is whole of what was refused before.
    check spanAt(9.0) >= corner
    check spanAt(9.0) < float(max(WIDE, TALL))
    check scene.isBackdropUnder(ground, scaleAt(9.0), WIDE, TALL)
    # Twelve units off, disc spans 724.3 px and leaves corners bare, so it stays handle.
    check spanAt(12.0) < corner
    check not scene.isBackdropUnder(ground, scaleAt(12.0), WIDE, TALL)


  test "a plane is judged by the disc drawn, not by the one its support would carry":
    # `mesh.addPlane` centres disc on object's own creation anchor where it has one,
    #   and on demo scene's own planes two stand as far as 3.7 units apart against
    #   radius of 8 -- so test ringing support would frame circle nobody sees.
    let ground = toMultivector(ORIGIN) ∧ toMultivector(Position(x: 1.0, y: 0.0, z: 0.0)) ∧
      toMultivector(Position(x: 0.0, y: 1.0, z: 0.0))
    var camera = stanceAim(0.0, 0.9)
    camera = camera.placedAtDistance(32.0)
    # Fits about its own support at this distance, and does not once disc is drawn.
    #   long way off along plane instead.
    check isShownCentrally(ground, camera, WIDTH_AIM, HEIGHT_AIM)
    check not isShownCentrally(
      ground, camera, WIDTH_AIM, HEIGHT_AIM, some(Position(x: 14.0, y: 0.0, z: 0.0))
    )
    # And framing rule follows same anchor, object by object: same plane in.
    #   same scene at same camera costs nothing without one and moves view with it.
    let (scene_support, picked_support) = sceneOf(ground)
    check framedFor(scene_support, picked_support, camera) == camera.stanceOf

    var (scene_drawn, picked_drawn) = (initScene(), Selection())
    picked_drawn.toggle(scene_drawn.addObject(
      ground, "ground", Ink.Rose, 0.0, some(Position(x: 14.0, y: 0.0, z: 0.0))
    ))
    let framed = framedFor(scene_drawn, picked_drawn, camera)
    check not (framed == camera.stanceOf)
    # Panned toward circle actually drawn.
    check camera.placed(framed).pivot.x > camera.pivot.x
    check isShownAll(
      scene_drawn, picked_drawn, none(Preview), camera.placed(framed),
      WIDTH_AIM, HEIGHT_AIM,
    )


  test "a bound grows to hold a whole disc, and a disc swallowing it takes over":
    # `widened` over balls rather than points, which is what lets distance search.
    #   bracket plane at all: bounding plane by its anchor alone leaves search
    #   starting from sphere of radius nothing and never reaching far enough.
    let bound = SphereWorld(centre: ORIGIN, radius: 1.0)
    let held = bound.widened(Position(x: 5.0, y: 0.0, z: 0.0), 2.0)
    check held.radius =~ 4.0 # From -1 to +7 across, so eight wide.
    check held.centre =~ Position(x: 3.0, y: 0.0, z: 0.0)
    # Point is reach-nothing case, unchanged.
    check bound.widened(Position(x: 5.0, y: 0.0, z: 0.0), 0.0).radius =~ 3.0
    # Contained outright, either way round, including concentric -- where there is no.
    #   direction to slide centre along at all.
    check bound.widened(Position(x: 0.5, y: 0.0, z: 0.0), 0.25) == bound
    let swallowed = bound.widened(ORIGIN, 9.0)
    check swallowed.radius =~ 9.0
    check swallowed.centre =~ ORIGIN


  test "a point fits with its drawn dot inside the box, not only its middle":
    # `INSET_POINT_SHOWN`, stated as property it exists for: point whose centre lands.
    #   pixel inside box is not in view, because half its dot is not.
    let camera = stanceAim(0.0, 0.0)
    let margin_y = 0.5*(1.0 - FRACTION_VIEW_CENTRED)*float(HEIGHT_AIM)
    var found_edge = false
    # Walk point down frame until it crosses inset edge, then check that bare.
    #   centre test would have admitted it little sooner.
    for step in 0 .. 400:
      let place = toMultivector(Position(x: 0.0, y: 0.0, z: 0.02*float(step)))
      let at = projectToScreen(
        camera.initMatrixViewProjection(WIDTH_AIM/HEIGHT_AIM), WIDTH_AIM, HEIGHT_AIM,
        anchorFor(place, camera.drawExtentFor(HEIGHT_AIM)).get,
      )
      if at.y > margin_y and at.y < margin_y + INSET_POINT_SHOWN:
        check not isShownCentrally(place, camera, WIDTH_AIM, HEIGHT_AIM)
        found_edge = true
    check found_edge # Sweep really did straddle edge, so check above ran.


  test "every selected object is brought into view, not merely the first":
    # Rule, over orientations. Two points wide apart cannot both be framed by panning.
    #   alone, so this is also where pull-back earns its keep.
    let (scene, picked) = sceneOf(
      toMultivector(Position(x: 14.0, y: -11.0, z: 3.0)),
      toMultivector(Position(x: -9.0, y: 12.0, z: -5.0)),
    )
    for azimuth in AZIMUTHS_AIM:
      for elevation in ELEVATIONS_AIM:
        let camera = stanceAim(azimuth, elevation)
        let framed = camera.placed(framedFor(scene, picked, camera))
        check isShownAll(scene, picked, none(Preview), framed, WIDTH_AIM, HEIGHT_AIM)
        check framed.distance > camera.distance # Panning alone could not have done it.


  test "a selection already in view keeps the reader's own framing, and re-centres":
    # Least-movement rule, judged where camera *is*: judging it at centred.
    #   placement instead was bug that pulled view about on every pick of
    #   something already plainly visible. What survives of that is reader's own
    #   framing -- **distance and orbit do not move at all** -- while pivot
    #   comes to middle of what was picked, since turning about point is what
    #   orbit is and reader who picks objects means to turn about those.
    let (scene, picked) = sceneOf(
      toMultivector(Position(x: 2.0, y: 0.0, z: 0.0)),
      toMultivector(Position(x: -2.0, y: 0.0, z: 0.0)),
      toMultivector(Position(x: 0.0, y: 2.0, z: 0.0)),
    )
    # Mean of three, computed here classical way: algebra's answer is what.
    #   is under test, so arithmetic it is held against lives in test.
    let middle = Position(x: (2.0 - 2.0 + 0.0)/3.0, y: (0.0 + 0.0 + 2.0)/3.0, z: 0.0)
    for azimuth in AZIMUTHS_AIM:
      for elevation in ELEVATIONS_AIM:
        var camera = stanceAim(azimuth, elevation)
        check isShownAll(scene, picked, none(Preview), camera, WIDTH_AIM, HEIGHT_AIM)
        let framed = framedFor(scene, picked, camera)
        check camera.placed(framed).pivot =~ middle
        check framed.distance == camera.distance
        # Angles are computed floats: they pass through motor and back, so they land
        #   within ulp or two of what camera stands at rather than on it.
        check camera.placed(framed).azimuth =~ camera.azimuth
        check camera.placed(framed).elevation =~ camera.elevation
        # End to end: ease carries pivot there and leaves everything else alone.
        var tween: CameraTween
        tween.offerAim(
          camera, scene, picked, none(Preview), camera.drawExtentFor(HEIGHT_AIM),
      WIDTH_AIM, HEIGHT_AIM, 0.0, 0.35
        )
        tween.settle(camera)
        check camera.pivot =~ middle
        check camera.distance == stanceAim(azimuth, elevation).distance
        # Angles are read off sight direction now, so they land within ulp or two of
        #   what was asked rather than on it. Claim is that framing turned nothing.
        check camera.azimuth =~ stanceAim(azimuth, elevation).azimuth


  test "an object picked on its own is carried to the middle, and nothing else moves":
    # Single pick has one middle and it is object itself, so pivot lands on it.
    #   exactly -- and once it is centred there is nothing left for zoom or turn to
    #   fix, which is least-movement rule holding over everything reader set.
    let place = Position(x: 9.0, y: -7.0, z: 4.0)
    let (scene, picked) = sceneOf(toMultivector(place))
    for azimuth in AZIMUTHS_AIM:
      for elevation in ELEVATIONS_AIM:
        let camera = stanceAim(azimuth, elevation)
        let framed = framedFor(scene, picked, camera)
        check isShownAll(
          scene, picked, none(Preview), camera.placed(framed), WIDTH_AIM, HEIGHT_AIM
        )
        check camera.placed(framed).pivot =~ place
        check framed.distance == camera.distance
        check camera.placed(framed).azimuth =~ camera.azimuth
        check camera.placed(framed).elevation =~ camera.elevation


  test "a finite selection never turns the orbit":
    # Preference for pan and zoom over orbit, stated as property it is: finite.
    #   selection's move carries no turn at all, so no fraction of it does either.
    let scenes = [
      sceneOf(toMultivector(Position(x: 9.0, y: -7.0, z: 4.0))),
      sceneOf(
        toMultivector(Position(x: 14.0, y: -11.0, z: 3.0)),
        toMultivector(Position(x: -9.0, y: 12.0, z: -5.0)),
      ),
    ]
    for (scene, picked) in scenes:
      for azimuth in AZIMUTHS_AIM:
        for elevation in ELEVATIONS_AIM:
          let camera = stanceAim(azimuth, elevation)
          let framed = framedFor(scene, picked, camera)
          check camera.placed(framed).azimuth =~ camera.azimuth
          check camera.placed(framed).elevation =~ camera.elevation


  test "the camera pulls back only as far as it must, and never pulls in":
    let (scene, picked) = sceneOf(
      toMultivector(Position(x: 14.0, y: -11.0, z: 3.0)),
      toMultivector(Position(x: -9.0, y: 12.0, z: -5.0)),
    )
    for azimuth in AZIMUTHS_AIM:
      for elevation in ELEVATIONS_AIM:
        let camera = stanceAim(azimuth, elevation)
        let framed = framedFor(scene, picked, camera)
        check framed.distance >= camera.distance # Never pulls in ...
        # ... and not one step further than rule in force demands. Judged against that
        #   rule, and not against pixels: sphere criterion is what framing solves, and it
        #   is stricter than what each shape's own pixels would accept.
        let aim = aimFor(scene, picked, none(Preview), camera.drawExtentFor(HEIGHT_AIM))
        check aim.isSome
        check aim.get.isFramed(camera.placed(framed), WIDTH_AIM, HEIGHT_AIM)
        let short = camera.stanceOf.toward(framed, 0.999)
        check not aim.get.isFramed(camera.placed(short), WIDTH_AIM, HEIGHT_AIM)
        # Everything picked is on screen all same, which is what reader asked.
        check isShownAll(
          scene, picked, none(Preview), camera.placed(framed), WIDTH_AIM, HEIGHT_AIM
        )


  test "the step out is the least one that reaches its own distance":
    # Closed form frame rule solves, and what three searches over projections were doing
    #   before it. One quadratic, and its positive root is always answer.
    for reach in [0.002, 1.0, 19.0, 6.5e6]:
      for i in 0 .. 5:
        let
          turn = TAU*float(i)/6.0
          offset = Direction(x: 0.3*reach*cos(turn), y: 0.3*reach*sin(turn), z: 0.1*reach)
          heading = Direction(x: cos(turn), y: -sin(turn), z: 0.0)
          centre = Position(x: 1.5, y: -2.0, z: 0.5)
          eye = centre + offset
        let stepped = stepOutTo(eye, centre, heading, reach)
        check stepped > 0.0
        # It lands exactly on that distance, whichever way heading points.
        check norm(offset + stepped*heading) =~ reach
        let back = stepOutTo(eye, centre, -heading, reach)
        check back > 0.0
        check norm(offset + back*(-heading)) =~ reach
    # Already out that far costs nothing, which is what makes rule floor.
    check stepOutTo(Position(x: 20.0, y: 0.0, z: 0.0), ORIGIN, UP_WORLD, 19.0) =~ 0.0
    check stepOutTo(Position(x: 19.0, y: 0.0, z: 0.0), ORIGIN, UP_WORLD, 19.0) =~ 0.0

  test "the frame rule is a floor, and the camera slides along it":
    const (WIDE, TALL) = (WIDTH_AIM, HEIGHT_AIM)
    let (scene, picked) = sceneOf(
      toMultivector(Position(x: 6.0, y: -4.0, z: 1.0)),
      toMultivector(Position(x: -3.0, y: 5.0, z: -2.0)),
    )
    let opening = stanceAim(0.7, 0.35)
    let aim = aimFor(scene, picked, none(Preview), opening.drawExtentFor(TALL)).get
    let centre = aim.sphere.get.centre
    let reach = distanceFitting(aim.sphere.get.radius, opening, WIDE, TALL, INSET_POINT_SHOWN)
    # Framed, then flown well inside: rule is broken and floor answers.
    var camera = opening.placed(stanceFor(aim, opening, WIDE, TALL))
    check aim.isFramed(camera, WIDE, TALL)
    let axes_before = camera.frame
    camera.flyAhead(0.8*reach)
    check not aim.isFramed(camera, WIDE, TALL)
    let bearing_inside = (1.0/norm(camera.eye - centre))*(camera.eye - centre)
    camera.holdFramed(aim, WIDE, TALL)
    # Back out to exactly that floor, and no further.
    check norm(camera.eye - centre) =~ reach
    check aim.isFramed(camera, WIDE, TALL)
    # On way out it keeps whichever way round it had got to: eye goes back along its own
    #   sight, which passes through centre here, so its bearing there is untouched.
    check (1.0/norm(camera.eye - centre))*(camera.eye - centre) =~ bearing_inside
    # Nothing turns, and pivot is re-stamped at middle rather than left stale. Two points'
    #   middle is their sphere's centre; three that part them are case below.
    check camera.frame.forward =~ axes_before.forward
    check abs(dot(centre - camera.eye, camera.frame.forward) - camera.distance) <
      TOLERANCE_TEST
    # Standing further out is left alone: floor, not fit.
    var far = camera
    far.flyAhead(-3.0*reach)
    let eye_far = far.eye
    far.holdFramed(aim, WIDE, TALL)
    check far.eye =~ eye_far
    # Narrower frame asks for more room, and same floor supplies it.
    let reach_narrow = distanceFitting(
      aim.sphere.get.radius, opening, TALL div 2, TALL, INSET_POINT_SHOWN
    )
    check reach_narrow > reach
    var resized = opening.placed(stanceFor(aim, opening, WIDE, TALL))
    check not aim.isFramed(resized, TALL div 2, TALL)
    resized.holdFramed(aim, TALL div 2, TALL)
    check norm(resized.eye - centre) =~ reach_narrow

  test "the floor backs out along the sight, and keeps the pivot on the middle of three":
    # Orbit turns about middle of what is picked, so floor must not carry pivot off it.
    #   Two close together and one far off: sphere's centre lies well off their middle.
    #   Floor used to push eye straight out from sphere's centre, which slid view
    #   sideways and pivot with it, once sphere's centre and middle parted.
    const (WIDE, TALL) = (WIDTH_AIM, HEIGHT_AIM)
    let (scene, picked) = sceneOf(
      toMultivector(Position(x: 0.0, y: 0.0, z: 0.0)),
      toMultivector(Position(x: 0.5, y: 0.2, z: 0.0)),
      toMultivector(Position(x: 6.0, y: -1.0, z: 1.0)),
    )
    # Near enough that group does not fit, so rule pulls back and stands eye on floor.
    var camera = stanceAim(0.7, 0.35)
    camera.dollyTo(3.0)
    let aim = aimFor(scene, picked, none(Preview), camera.drawExtentFor(TALL)).get
    let middle = aim.centroid.get
    check norm(aim.sphere.get.centre - middle) > 0.5 # What this case is about.
    camera = camera.placed(stanceFor(aim, camera, WIDE, TALL))
    check camera.pivot =~ middle
    check camera.distance > 3.0 # Rule pulled back.
    # Reader pinches in past floor, so rule is broken and floor has to answer.
    camera.dolly(0.6)
    check not aim.isFramed(camera, WIDE, TALL)
    let forward = camera.frame.forward
    camera.holdFramed(aim, WIDE, TALL)
    check aim.isFramed(camera, WIDE, TALL)
    # Nothing turns, eye went back along its own sight, and pivot stayed on middle.
    check camera.frame.forward =~ forward
    check camera.pivot =~ middle
    let at = projectToScreen(
      camera.initMatrixViewProjection(float(WIDE)/float(TALL)), WIDE, TALL, middle
    )
    check abs(at.x - float(WIDE)/2.0) < 0.01
    check abs(at.y - float(TALL)/2.0) < 0.01
    # Same through orbit, whenever object leaves box as reader goes round.
    for step in 0 ..< 60:
      camera.orbit(0.05, 0.03)
      if not aim.isFramed(camera, WIDE, TALL): camera.holdFramed(aim, WIDE, TALL)
      check aim.isFramed(camera, WIDE, TALL)
      check camera.pivot =~ middle


  test "a selection tight enough to fit already keeps the reader's own scale":
    # Half of "only when it must" that spread selection cannot show: distance left.
    #   exactly alone, not merely one that did not grow much.
    let (scene, picked) = sceneOf(
      toMultivector(Position(x: 0.7, y: 0.4, z: 0.2)),
      toMultivector(Position(x: -0.6, y: -0.3, z: 0.5)),
    )
    for azimuth in AZIMUTHS_AIM:
      for elevation in ELEVATIONS_AIM:
        let camera = stanceAim(azimuth, elevation)
        let framed = framedFor(scene, picked, camera)
        check framed.distance == camera.distance


  test "a line's own support never drags the view off the point beside it":
    # Line has only to cross box, so where it stands is not where camera should.
    #   centre: support forty units away would pull view off point picked with
    #   it and force pull-back to drag that support back into frame, for nothing.
    let place = Position(x: 0.5, y: 0.2, z: 0.1)
    let support = Position(x: 0.0, y: 0.0, z: 40.0)
    let (point, line) = (
      toMultivector(place),
      toMultivector(support) ∧ toMultivector(Position(x: 1.0, y: 0.3, z: 40.0)),
    )
    let camera = stanceAim(0.0, 0.0)
    # Picked beside point, point alone decides where to look and what it costs:
    #   aim's sphere collapses onto it, so move is pan toward point, cut short
    #   moment its dot fits -- no dolly toward that distant support, ever.
    let (scene, picked) = sceneOf(point, line)
    let aim = aimFor(scene, picked, none(Preview), camera.drawExtentFor(HEIGHT_AIM))
    check aim.get.is_bound_by_fitted
    check aim.get.sphere.get.radius =~ 0.0
    let framed = framedFor(scene, picked, camera)
    check framed.distance == camera.distance
    check camera.placed(framed).azimuth =~ camera.azimuth
    check isShownAll(
      scene, picked, none(Preview), camera.placed(framed), WIDTH_AIM, HEIGHT_AIM
    )


  test "a horizon point is bound to the screen, and a horizon line to crossing it":
    # Star binds two freedoms: it has to be somewhere on screen. Horizon line binds one:
    #   its whole great circle has only to cross frame. Plane binds none.
    const (WIDE, TALL) = (WIDTH_AIM, HEIGHT_AIM)
    let star = attitude(
      toMultivector(Position(x: 4.0, y: 4.0, z: 1.0)) ∧
        toMultivector(Position(x: 5.0, y: 4.5, z: 1.4))
    )
    let (scene_star, picked_star) = sceneOf(star)
    let opening = stanceAim(0.5, 0.2)
    let aim_star = aimFor(
      scene_star, picked_star, none(Preview), opening.drawExtentFor(TALL)
    ).get
    check aim_star.heading.isSome
    check aim_star.normal_crossing.isNone
    # Faced, then turned well off: bound breaks, and least turn brings it back on screen.
    var camera = opening.placed(stanceFor(aim_star, opening, WIDE, TALL))
    check aim_star.isBounded(camera, WIDE, TALL)
    camera.look(1.1, 0.0)
    check not aim_star.isBounded(camera, WIDE, TALL)
    let axes_off = camera.frame
    camera.holdHorizon(aim_star, WIDE, TALL)
    check aim_star.isBounded(camera, WIDE, TALL)
    # It lands on that bound and no further in, which is what least turn means.
    let half = halfAngleCentred(camera, WIDE, TALL, INSET_POINT_SHOWN)
    check arccos(clamp(dot(camera.frame.forward, aim_star.heading.get), -1.0, 1.0)) =~ half
    # Eye stands: horizon object is direction, so bound turns and never moves.
    check camera.eye =~ opening.placed(stanceFor(aim_star, opening, WIDE, TALL)).eye
    # Turn is in plane of sight and star, so whatever crossed bound survives it.
    check abs(dot(camera.frame.forward, axes_off.axis_up)) < 1.0 + TOLERANCE_TEST
    # Already on screen costs nothing, which makes it bound rather than aim.
    let eye_held = camera.eye
    let forward_held = camera.frame.forward
    camera.holdHorizon(aim_star, WIDE, TALL)
    check camera.frame.forward =~ forward_held
    check camera.eye =~ eye_held

    # Horizon line keeps its circle's normal, and is bound to crossing frame alone.
    #   Attitude of plane is line at horizon; attitude of line is point at one.
    let along = attitude(
      toMultivector(ORIGIN) ∧ toMultivector(Position(x: 1.0, y: 0.0, z: 0.0)) ∧
        toMultivector(Position(x: 0.0, y: 1.0, z: 0.0))
    )
    check isHorizon(along)
    check kindOf(along) == some(Kind.Line)
    let (scene_line, picked_line) = sceneOf(along)
    let aim_line = aimFor(
      scene_line, picked_line, none(Preview), opening.drawExtentFor(TALL)
    ).get
    check aim_line.heading.isNone
    check aim_line.normal_crossing.isSome
    # Sight turned onto that circle's own normal is as far off as it gets.
    var turned = opening
    turned = turned.placed(stanceTurntable(
      turned.pivot, turned.distance,
      azimuthElevationFor(aim_line.normal_crossing.get)[0],
      clamp(
        azimuthElevationFor(aim_line.normal_crossing.get)[1],
        -ELEVATION_LIMIT, ELEVATION_LIMIT,
      ),
    ))
    check not aim_line.isBounded(turned, WIDE, TALL)
    turned.holdHorizon(aim_line, WIDE, TALL)
    check aim_line.isBounded(turned, WIDE, TALL)
    # It lands one box half-angle off that circle's plane, and not facing along it:
    #   crossing is all that is asked, so one freedom is bound and one is free.
    check abs(dot(turned.frame.forward, aim_line.normal_crossing.get)) =~ sin(half)

    # Anything finite wins outright: horizon demand goes unmet rather than fighting it.
    let (scene_both, picked_both) =
      sceneOf(star, toMultivector(Position(x: 3.0, y: -2.0, z: 1.0)))
    let aim_both = aimFor(
      scene_both, picked_both, none(Preview), opening.drawExtentFor(TALL)
    ).get
    check aim_both.sphere.isSome and aim_both.heading.isSome
    var pair = opening
    pair.look(2.6, 0.0) # Star well behind reader now.
    check aim_both.isBounded(pair, WIDE, TALL)
    let forward_pair = pair.frame.forward
    pair.holdHorizon(aim_both, WIDE, TALL)
    check pair.frame.forward =~ forward_pair

  test "a horizon object is turned toward only as far as it takes":
    # Star is drawn fixed to eye, so pan and zoom cannot bring it into view and.
    #   move is turn -- one place orbit is allowed, cut short like every other move.
    let star = attitude(
      toMultivector(Position(x: 4.0, y: 4.0, z: 1.0)) ∧
        toMultivector(Position(x: 5.0, y: 4.5, z: 1.4))
    )
    check isHorizon(star)
    let (scene_star, picked_star) = sceneOf(star)
    for azimuth in AZIMUTHS_AIM:
      let camera = stanceAim(azimuth, 0.3)
      let framed = framedFor(scene_star, picked_star, camera)
      check isShownCentrally(star, camera.placed(framed), WIDTH_AIM, HEIGHT_AIM)
      check camera.placed(framed).pivot =~ camera.pivot # Orbit turned; what it turns about did not.
      check framed.distance =~ camera.distance
      # Turn lands on star's own heading, rather than being searched toward it:
      #   rebuild names that turn outright, so there is no fraction of it to find.
      let aim = aimFor(
        scene_star, picked_star, none(Preview), camera.drawExtentFor(HEIGHT_AIM)
      )
      check aim.isSome and aim.get.heading.isSome
      let angles = azimuthElevationFor(aim.get.heading.get)
      check camera.placed(framed).azimuth =~ angles[0]
      check camera.placed(framed).elevation =~
        clamp(angles[1], -ELEVATION_LIMIT, ELEVATION_LIMIT)

    # Star already on screen keeps reader's own framing, as finite selection fitting does.
    #   Turn is floor like every other part of rule: it fires where bound is broken, and
    #   stands aside inside it. Re-centring one already in view pulled whole view about.
    let opening = stanceAim(AZIMUTHS_AIM[0], 0.3)
    var faced = opening.placed(framedFor(scene_star, picked_star, opening))
    let aim_faced = aimFor(
      scene_star, picked_star, none(Preview), faced.drawExtentFor(HEIGHT_AIM)
    ).get
    check aim_faced.isBounded(faced, WIDTH_AIM, HEIGHT_AIM)
    faced.look(0.03, 0.0) # Star stays on screen, so bound still holds.
    check aim_faced.isBounded(faced, WIDTH_AIM, HEIGHT_AIM)
    let forward_own = faced.frame.forward
    check faced.placed(
      stanceFor(aim_faced, faced, WIDTH_AIM, HEIGHT_AIM)
    ).frame.forward =~ forward_own

    # Beside anything finite, finite framing wins outright and angles stand: star.
    #   behind reader and point in front have no one placement showing both.
    let (scene_both, picked_both) =
      sceneOf(star, toMultivector(Position(x: 3.0, y: -2.0, z: 1.0)))
    let camera = stanceAim(0.7, 0.2)
    let framed = framedFor(scene_both, picked_both, camera)
    check camera.placed(framed).azimuth =~ camera.azimuth
    check camera.placed(framed).elevation =~ camera.elevation


  test "an empty selection withdraws the offer, and so does geometry that draws nothing":
    var camera = stanceAim(0.0, 0.2)
    var tween: CameraTween
    let (scene, picked) = sceneOf(toMultivector(Position(x: 3.0, y: -2.0, z: 1.5)))
    tween.offerAim(
      camera, scene, picked, none(Preview), camera.drawExtentFor(HEIGHT_AIM),
      WIDTH_AIM, HEIGHT_AIM, 0.0, 0.35
    )
    check tween.goal.isSome

    tween.offerAim(
      camera, scene, Selection(), none(Preview), camera.drawExtentFor(HEIGHT_AIM),
      WIDTH_AIM, HEIGHT_AIM, 0.1, 0.35
    )
    check tween.goal.isNone

    var empty: Multivector
    tween.offerAim(
      camera, scene, Selection(), some(previewStaging(empty, RADIUS_OBJECT_DEFAULT)),
      camera.drawExtentFor(HEIGHT_AIM), WIDTH_AIM, HEIGHT_AIM, 0.2, 0.35,
    )
    check tween.goal.isNone


  test "the whole selection is framed end to end, through the standing offer":
    # Driving rule way front-end does, rather than calling `stanceFor`.
    #   directly: offer, ease, and arrival, over whole animation.
    const DURATION = 0.35
    var camera = stanceAim(1.6, 0.2)
    var tween: CameraTween
    let (scene, picked) = sceneOf(
      toMultivector(Position(x: 14.0, y: -11.0, z: 3.0)),
      toMultivector(Position(x: -9.0, y: 12.0, z: -5.0)),
    )
    check not isShownAll(scene, picked, none(Preview), camera, WIDTH_AIM, HEIGHT_AIM)

    tween.offerAim(
      camera, scene, picked, none(Preview), camera.drawExtentFor(HEIGHT_AIM),
      WIDTH_AIM, HEIGHT_AIM, 0.0, DURATION
    )
    for frame in 1 .. 30:
      let now = DURATION*float(frame)/20.0
      tween.offerAim( # Re-offered every frame, exactly as front-end re-offers it.
        camera, scene, picked, none(Preview), camera.drawExtentFor(HEIGHT_AIM),
      WIDTH_AIM, HEIGHT_AIM, now, DURATION
      )
      tween.advance(camera, now, easeOutCubic)
    check tween.is_arrived
    check isShownAll(scene, picked, none(Preview), camera, WIDTH_AIM, HEIGHT_AIM)


  test "a pointer pick centres the object and ends at its fit":
    # What right-click promises: object clicked comes to middle of frame and becomes
    #   pivot, so orbit turns it where it stands, and dot (two pixels of radius, forty
    #   units out) comes in until its disc spans `FRACTION_HEIGHT_APPROACH_POINT` of
    #   frame's height.
    #   Held under pointer before, on whichever pixel was clicked. Pivot then stood on
    #   sight line at object's depth, units off object itself, and orbit swung object
    #   round screen.
    const
      DURATION = 0.35
      ASPECT = float(WIDTH_AIM)/float(HEIGHT_AIM)
      RADIUS = 0.08
    for azimuth in AZIMUTHS_AIM:
      for elevation in ELEVATIONS_AIM:
        var camera = stanceAim(azimuth, elevation)
        # Stand point forty units ahead and well off sight axis, so pixel is not middle.
        let
          eye = camera.eye
          axes = camera.frame
          place = eye + 40.0*axes.forward + 4.0*axes.axis_right - 2.0*axes.axis_up
        var (scene, picked) = sceneOf(toMultivector(place))
        scene.setRadius(picked.at(0), RADIUS)
        let pixel = projectToScreen(
          camera.initMatrixViewProjection(ASPECT), WIDTH_AIM, HEIGHT_AIM, place
        )
        var
          tween: CameraTween
          pointer = some(PointerPick(handle: picked.at(0)))
        tween.offerAim(
          camera, scene, picked, none(Preview), camera.drawExtentFor(HEIGHT_AIM),
          WIDTH_AIM, HEIGHT_AIM, 0.0, DURATION, pointer,
        )
        check pointer.isNone # Spent by offer.
        check pixel.x != float(WIDTH_AIM)/2.0 # Clicked well off middle.
        for step in 1 .. 5:
          tween.advance(camera, DURATION*float(step)/5.0, easeOutCubic)
        check tween.is_arrived
        # Object ends dead centre, whatever pixel was clicked.
        let settled_at = projectToScreen(
          camera.initMatrixViewProjection(ASPECT), WIDTH_AIM, HEIGHT_AIM, place
        )
        check abs(settled_at.x - float(WIDTH_AIM)/2.0) < 0.01
        check abs(settled_at.y - float(HEIGHT_AIM)/2.0) < 0.01
        # Pivot is object itself, so orbit turns it where it stands.
        check camera.pivot =~ place
        var turned = camera
        turned.orbit(0.7, 0.3)
        let after_turn = projectToScreen(
          turned.initMatrixViewProjection(ASPECT), WIDTH_AIM, HEIGHT_AIM, place
        )
        check abs(after_turn.x - float(WIDTH_AIM)/2.0) < 0.01
        check abs(after_turn.y - float(HEIGHT_AIM)/2.0) < 0.01
        # Angles are read off sight direction now, so they land within ulp or two of
        #   what was asked rather than on it. Claim is that framing turned nothing.
        check camera.azimuth =~ stanceAim(azimuth, elevation).azimuth
        check camera.elevation =~ stanceAim(azimuth, elevation).elevation
        let fit = depthSpanning(2.0*RADIUS, FRACTION_HEIGHT_APPROACH_POINT, camera)
        check abs(camera.distance - fit) < 1.0e-9
        # Separation is reach to object, because object is what pivot stands on.
        check abs(norm(place - camera.eye) - fit) < 1.0e-6


  test "a pointer pick never moves the eye further off than the object stands":
    # Object already nearer than its fit leaves reader's own scale alone: separation
    #   becomes its own reach and no more. Point seen at its size, and line, come in to
    #   orbit distance and no further; only floor dot comes in to its fit.
    let camera = stanceAim(0.7, 0.2)
    let
      eye = camera.eye
      axes = camera.frame
      scale = camera.drawExtentFor(HEIGHT_AIM)
      near = eye + 0.3*axes.forward + 0.02*axes.axis_right
      far = eye + 40.0*axes.forward + 3.0*axes.axis_up
    let placement_near = stanceApproaching(Kind.Point, 0.08, near, camera, scale)
    check placement_near.isSome
    check abs(placement_near.get.distance - norm(near - eye)) < 1.0e-9
    # Pivot is object, and it is centred: that is whole of what pick promises.
    check camera.placed(placement_near.get).pivot =~ near
    # Radius half unit stands forty out at thirteen pixels, plainly seen: orbit distance.
    let placement_seen = stanceApproaching(Kind.Point, 0.5, far, camera, scale)
    check placement_seen.isSome
    check abs(placement_seen.get.distance - camera.distance) < 1.0e-9
    let placement_line = stanceApproaching(Kind.Line, 0.0, far, camera, scale)
    check placement_line.isSome
    check abs(placement_line.get.distance - camera.distance) < 1.0e-9
    # Object behind reader is left to frame rule: centring it would slide camera back
    #   past it rather than turn.
    let behind = eye - 2.0*axes.forward
    let placement_behind = stanceApproaching(Kind.Point, 0.08, behind, camera, scale)
    check placement_behind.isNone


  test "a depth spanning a fraction of the frame is read off the lens":
    # Two units across at half of 45-degree frame: 2/(2*0.5*tan 22.5) = 4.83.
    let camera = stanceAim(0.0, 0.0)
    check abs(depthSpanning(2.0, 0.5, camera) - 2.0/(2.0*0.5*tan(degToRad(22.5)))) < 1.0e-9
    check depthSpanning(0.0, 0.5, camera) == DISTANCE_LIMIT_NEAR


  test "a plane picked by pointer is brought to its size, centred both ways":
    # Disc's centre comes to middle of frame, at reach where its diameter spans.
    #   `FRACTION_HEIGHT_APPROACH_PLANE` of that frame, from too far and from too near
    #   alike, with angles standing.
    const
      DURATION = 0.35
      ASPECT = float(WIDTH_AIM)/float(HEIGHT_AIM)
    let ground = planeThrough(toMultivector(ORIGIN), toMultivector(UP_WORLD))
    for distance in [12.0, 1.0]:
      var camera = initCamera(pivot = ORIGIN, distance = distance, azimuth = 0.7, elevation = 0.5)
      var (scene, picked) = sceneOf(ground)
      let scale = camera.drawExtentFor(HEIGHT_AIM)
      var
        tween: CameraTween
        pointer = some(PointerPick(handle: picked.at(0)))
      tween.offerAim(
        camera, scene, picked, none(Preview), scale, WIDTH_AIM, HEIGHT_AIM, 0.0, DURATION,
        pointer,
      )
      tween.settle(camera)
      let seat = anchorFor(ground, none(Position), scale)
      check seat.isSome
      let wanted = depthSpanning(2.0*EXTENT_PLANE_F, FRACTION_HEIGHT_APPROACH_PLANE, camera)
      check abs(camera.distance - wanted) < 1.0e-6
      # Disc's own centre is pivot, and pivot is middle of frame.
      check camera.pivot =~ seat.get
      let pixel = projectToScreen(
        camera.initMatrixViewProjection(ASPECT), WIDTH_AIM, HEIGHT_AIM, seat.get
      )
      check abs(pixel.x - float(WIDTH_AIM)/2.0) < 0.01
      check abs(pixel.y - float(HEIGHT_AIM)/2.0) < 0.01
      # Read off sight direction, so within ulp of what was asked; see above.
      check camera.azimuth =~ 0.7
      check camera.elevation =~ 0.5


  test "a group picked by pointer frames as ever":
    # Group has to fit, which one object's reach cannot promise: `stanceFor`.
    const DURATION = 0.35
    var camera = stanceAim(1.6, 0.2)
    let (scene_two, picked_two) = sceneOf(
      toMultivector(Position(x: 14.0, y: -11.0, z: 3.0)),
      toMultivector(Position(x: -9.0, y: 12.0, z: -5.0)),
    )
    var
      tween_two: CameraTween
      pointer = some(PointerPick(handle: picked_two.at(1)))
    tween_two.offerAim(
      camera, scene_two, picked_two, none(Preview), camera.drawExtentFor(HEIGHT_AIM),
      WIDTH_AIM, HEIGHT_AIM, 0.0, DURATION, pointer,
    )
    check tween_two.goal.isSome
    check tween_two.destination ==
      framedFor(scene_two, picked_two, camera)


  test "a drag inside the ease still lands the pivot on the group's middle":
    # Reader who adds object and turns at once turns about middle of what is picked.
    #   Drag used to mark ease arrived where it stood, and standing offer read held goal
    #   as answered, so pivot stopped partway and orbit swung about empty point.
    const DURATION = 0.35
    let
      one = Position(x: 2.0, y: 1.0, z: 0.5)
      two = Position(x: 0.0, y: 3.0, z: 1.5)
      middle = Position(x: 1.0, y: 2.0, z: 1.0)
    var camera = stanceAim(0.7, 0.3).placedAtPivot(one)
    let (scene, picked) = sceneOf(toMultivector(one), toMultivector(two))
    var tween: CameraTween
    tween.offerAim(
      camera, scene, picked, none(Preview), camera.drawExtentFor(HEIGHT_AIM),
      WIDTH_AIM, HEIGHT_AIM, 0.0, DURATION,
    )
    check not (tween.destination.motor == camera.motor) # Ease armed toward middle.
    tween.advance(camera, 0.2*DURATION, easeOutCubic)
    check norm(camera.pivot - middle) > 0.1 # Partway, not there yet.
    # Reader turns now, as drag does: every camera verb gives up ease first.
    tween.abandon()
    # Same turns on camera no ease carries, to read way round reader alone would face.
    var turned_alone = camera
    camera.orbit(0.4, 0.1)
    turned_alone.orbit(0.4, 0.1)
    for step in 3 .. 5:
      # Frame loop's order: ease first, then same standing offer, which must not re-arm.
      let now = DURATION*float(step)/5.0
      tween.advance(camera, now, easeOutCubic)
      tween.offerAim(
        camera, scene, picked, none(Preview), camera.drawExtentFor(HEIGHT_AIM),
        WIDTH_AIM, HEIGHT_AIM, now, DURATION,
      )
      camera.orbit(0.05, 0.0) # Drag goes on through rest of ease.
      turned_alone.orbit(0.05, 0.0)
    check tween.is_arrived
    check camera.pivot =~ middle
    # Turn stays reader's: ease carries pivot alone, never way round they faced.
    check camera.frame.forward =~ turned_alone.frame.forward
    check camera.frame.axis_up =~ turned_alone.frame.axis_up
    # Middle stands at middle of frame once pivot is there.
    let at = projectToScreen(
      camera.initMatrixViewProjection(float(WIDTH_AIM)/float(HEIGHT_AIM)),
      WIDTH_AIM, HEIGHT_AIM, middle,
    )
    check abs(at.x - float(WIDTH_AIM)/2.0) < 0.01
    check abs(at.y - float(HEIGHT_AIM)/2.0) < 0.01
    # Settling drag-held ease slides pivot home too, rather than undoing turn.
    var settled = stanceAim(0.7, 0.3).placedAtPivot(one)
    var held: CameraTween
    held.offerAim(
      settled, scene, picked, none(Preview), settled.drawExtentFor(HEIGHT_AIM),
      WIDTH_AIM, HEIGHT_AIM, 0.0, DURATION,
    )
    held.abandon()
    settled.orbit(0.4, 0.1)
    let forward_held = settled.frame.forward
    held.settle(settled)
    check settled.pivot =~ middle
    check settled.frame.forward =~ forward_held


  test "a pointer re-pick of an object the camera already holds aims afresh":
    # Standing offer ignores goal it holds, so same object picked again after wheel took.
    #   reader off went nowhere: "sometimes it doesn't zoom in".
    const DURATION = 0.35
    var camera = stanceAim(0.7, 0.2)
    let
      eye = camera.eye
      axes = camera.frame
      place = eye + 20.0*axes.forward + 2.0*axes.axis_right
    let (scene, picked) = sceneOf(toMultivector(place))
    var
      tween: CameraTween
      pointer = none(PointerPick)
    tween.offerAim(
      camera, scene, picked, none(Preview), camera.drawExtentFor(HEIGHT_AIM),
      WIDTH_AIM, HEIGHT_AIM, 0.0, DURATION, pointer,
    )
    tween.settle(camera)
    check tween.is_arrived
    camera.dolly(8.0) # Reader wheels out; offer stands answered.
    tween.abandon()
    tween.offerAim(
      camera, scene, picked, none(Preview), camera.drawExtentFor(HEIGHT_AIM),
      WIDTH_AIM, HEIGHT_AIM, 1.0, DURATION, pointer,
    )
    check tween.is_arrived # Same goal, no pointer: nothing re-armed.
    pointer = some(PointerPick(handle: picked.at(0)))
    tween.offerAim(
      camera, scene, picked, none(Preview), camera.drawExtentFor(HEIGHT_AIM),
      WIDTH_AIM, HEIGHT_AIM, 2.0, DURATION, pointer,
    )
    check not tween.is_arrived
    check tween.destination.distance < camera.distance


  test "a still camera a resize leaves out of frame eases back, though its goal is held":
    # Standing offer skips goal it holds, and was skipping it while frame rule was broken:
    #   narrowed window left camera unframed, since nothing moving it meant nothing held it.
    const (WIDE, TALL, DURATION) = (WIDTH_AIM, HEIGHT_AIM, 0.35)
    var camera = stanceAim(0.7, 0.35)
    let (scene, picked) = sceneOf(
      toMultivector(Position(x: 6.0, y: -4.0, z: 1.0)),
      toMultivector(Position(x: -3.0, y: 5.0, z: -2.0)),
    )
    var
      tween: CameraTween
      pointer = none(PointerPick)
    tween.offerAim(
      camera, scene, picked, none(Preview), camera.drawExtentFor(TALL),
      WIDE, TALL, 0.0, DURATION, pointer,
    )
    tween.settle(camera)
    let aim = tween.goal.get
    check aim.isFramed(camera, WIDE, TALL)
    check not aim.isFramed(camera, TALL div 2, TALL)
    tween.offerAim(
      camera, scene, picked, none(Preview), camera.drawExtentFor(TALL),
      TALL div 2, TALL, 1.0, DURATION, pointer,
    )
    check not tween.is_arrived
    tween.settle(camera)
    check aim.isFramed(camera, TALL div 2, TALL)
    # Once back in frame, same offer is answered again rather than re-armed.
    tween.offerAim(
      camera, scene, picked, none(Preview), camera.drawExtentFor(TALL),
      TALL div 2, TALL, 2.0, DURATION, pointer,
    )
    check tween.is_arrived


  test "a stance history restores stays while framed, and eases back where it is not":
    # Aim restored scene reads can be new, and new aim eases camera wherever it stands.
    #   Step has tween adopt it as delivered, so frame rule alone moves camera then.
    const (WIDE, TALL, DURATION) = (WIDTH_AIM, HEIGHT_AIM, 0.35)
    let (scene, picked) = sceneOf(
      toMultivector(Position(x: 6.0, y: -4.0, z: 1.0)),
      toMultivector(Position(x: -3.0, y: 5.0, z: -2.0)),
    )
    let opening = stanceAim(0.7, 0.35)
    let aim = aimFor(scene, picked, none(Preview), opening.drawExtentFor(TALL)).get
    var
      tween: CameraTween
      pointer = none(PointerPick)
    # Framed from further out than fit asks: nothing moves it.
    var camera = opening.placed(stanceFor(aim, opening, WIDE, TALL))
    camera.flyAhead(-5.0)
    let stance_far = camera.stanceOf
    check aim.isFramed(camera, WIDE, TALL)
    tween.adoptNext()
    tween.offerAim(
      camera, scene, picked, none(Preview), camera.drawExtentFor(TALL),
      WIDE, TALL, 0.0, DURATION, pointer,
    )
    check tween.is_arrived
    check camera.stanceOf == stance_far
    # Restored well inside fit: rule is broken, so ease backs camera out to it.
    camera.flyAhead(12.0)
    check not aim.isFramed(camera, WIDE, TALL)
    tween.adoptNext()
    tween.offerAim(
      camera, scene, picked, none(Preview), camera.drawExtentFor(TALL),
      WIDE, TALL, 1.0, DURATION, pointer,
    )
    check not tween.is_arrived
    tween.settle(camera)
    check aim.isFramed(camera, WIDE, TALL)
    # Nothing picked: adoption lapses with goal, so later pick aims afresh.
    tween.adoptNext()
    tween.offerAim(
      camera, scene, Selection(), none(Preview), camera.drawExtentFor(TALL),
      WIDE, TALL, 2.0, DURATION, pointer,
    )
    check tween.goal.isNone and not tween.is_adopting


  test "an aim widens by exactly the objects folded into it":
    let (a, b) = (Position(x: 3.0, y: 0.0, z: 0.0), Position(x: -3.0, y: 0.0, z: 0.0))
    let aim_one = none(CameraAim).aimIncluding(toMultivector(a), SCALE_AIM)
    check aim_one.get.sphere.get.centre =~ a
    check aim_one.get.sphere.get.radius =~ 0.0

    let aim_two = aim_one.aimIncluding(toMultivector(b), SCALE_AIM)
    check aim_two.get.sphere.get.centre =~ ORIGIN
    check aim_two.get.sphere.get.radius =~ 3.0
    # Bound cannot be widened by ball it already holds, so folding one in twice leaves.
    #   it exactly as it was: as *bound*, aim is set and not tally.
    check aim_two.aimIncluding(toMultivector(a), SCALE_AIM).get.sphere.get ==
      aim_two.get.sphere.get
    # Its **middle** is tally, because middle is: fold `a` again and mean of.
    #   three leans back toward it. That is why `framing.watched` yields each object once
    #   -- unary preview naming its own operand twice must not weigh it twice.
    check aim_two.get.centroid.get =~ ORIGIN
    # Sum's weight is count -- which is what lets one field say both.
    check aim_two.get.centroid_sum.get[Basis.E4] =~ 2.0
    let aim_thrice = aim_two.aimIncluding(toMultivector(a), SCALE_AIM)
    check aim_thrice.get.centroid.get =~ Position(x: 1.0, y: 0.0, z: 0.0)
    check aim_thrice.get.centroid_sum.get[Basis.E4] =~ 3.0

    let horizon = attitude(LINES[0]) # Line's attitude is horizon point.
    check isHorizon(horizon)
    let aim_star = none(CameraAim).aimIncluding(horizon, SCALE_AIM)
    check aim_star.get.heading.isSome
    check aim_star.get.sphere.isNone # Star is nowhere, so it widens nothing.


  test "an object that draws nothing aims at nothing":
    var empty: Multivector
    check aimFor(empty, SCALE_AIM).isNone


  proc aimOn(centre: Position, radius = 0.0): CameraAim =
    ## Name bare requirement for tween cases below.
    ##   Cases are about ease rather than about what any particular geometry asks for.
    CameraAim(sphere: some(SphereWorld(centre: centre, radius: radius)))

  proc placeOn(camera: Camera, pivot: Position): CameraStance =
    ## Move camera's placement onto pivot, leaving its orbit exactly as it stands.
    camera.stanceRepivoted(pivot)


  test "a tween eases toward its destination and lands on it exactly at the duration":
    const DURATION = 0.35
    var camera = initCamera(ORIGIN, 12.0, 0.0, 0.4)
    var tween: CameraTween
    let arrival = Position(x: 10.0, y: 0.0, z: 0.0)
    tween.aimAt(camera, aimOn(arrival), camera.placeOn(arrival), 0.0, DURATION)

    # Partway: strictly between start and destination, and monotonic toward it.
    var previous = 0.0
    for step in 1 .. 4:
      let now = DURATION*float(step)/5.0
      tween.advance(camera, now, easeOutCubic)
      check camera.pivot.x > previous
      check camera.pivot.x < arrival.x
      previous = camera.pivot.x

    tween.advance(camera, DURATION, easeOutCubic)
    check camera.pivot.x =~ arrival.x
    # Arrived, so nothing left to carry -- but goal is kept, not dropped, so.
    #   caller still offering it every frame is recognised rather than re-armed.
    check tween.is_arrived
    check tween.goal.isSome


  test "a tween eases its distance too, geometrically rather than linearly":
    # Distance is multiplicative quantity -- wheel and `FACTOR_DOLLY_PRESS` scale it.
    #   -- so midpoint of ease from 10 to 40 is 20, not 25.
    const DURATION = 0.35
    var camera = initCamera(ORIGIN, 10.0, 0.0, 0.4)
    var tween: CameraTween
    var arrival = camera.stanceOf
    arrival.distance = 40.0
    tween.aimAt(camera, aimOn(ORIGIN, 3.0), arrival, 0.0, DURATION)
    tween.advance(camera, DURATION*0.4, easeOutCubic)
    check camera.distance =~ 10.0*pow(4.0, easeOutCubic(0.4))
    check not (camera.distance =~ 10.0 + 30.0*easeOutCubic(0.4)) # Not linear reading.
    tween.advance(camera, DURATION, easeOutCubic)
    check camera.distance =~ 40.0


  test "repivoting mid-flight continues from where the camera reached":
    const DURATION = 0.35
    var camera = initCamera(ORIGIN, 12.0, 0.0, 0.4)
    var tween: CameraTween
    let first = Position(x: 10.0, y: 0, z: 0)
    tween.aimAt(camera, aimOn(first), camera.placeOn(first), 0.0, DURATION)
    tween.advance(camera, DURATION*0.5, easeOutCubic)
    let reached = camera.pivot.x
    check reached > 0.0 and reached < 10.0

    # Goal that moves must not snap camera back to where last ease began.
    let second = Position(x: 20.0, y: 0, z: 0)
    tween.aimAt(camera, aimOn(second), camera.placeOn(second), DURATION*0.5, DURATION)
    check camera.placed(tween.stance_from).pivot.x =~ reached
    tween.advance(camera, DURATION*0.5 + 0.001, easeOutCubic)
    check camera.pivot.x >= reached # Continues forward, never jumps backward.


  test "offering the goal it already holds does not restart the ease":
    const DURATION = 0.35
    var camera = initCamera(ORIGIN, 12.0, 0.0, 0.4)
    var tween: CameraTween
    let arrival = Position(x: 10.0, y: 0, z: 0)
    tween.aimAt(camera, aimOn(arrival), camera.placeOn(arrival), 0.0, DURATION)
    tween.advance(camera, DURATION*0.5, easeOutCubic)
    # Same goal, offered again -- and with destination read off camera as it now.
    #   stands, exactly as standing offer would recompute it.
    tween.aimAt(
      camera, aimOn(arrival), camera.placeOn(arrival), DURATION*0.5, DURATION
    )
    check tween.started == 0.0 # Clock untouched, so ease still ends on time.


  test "a tween turns the short way round the azimuth circle":
    # Angle just past -pi is next door to one just short of +pi, not most of turn.
    const DURATION = 0.35
    var camera = initCamera(ORIGIN, 12.0, 3.0, 0.0)
    var tween: CameraTween
    let arrival = stanceTurntable(ORIGIN, 12.0, -3.0, 0.0)
    tween.aimAt(camera, aimOn(Position(x: 1, y: 0, z: 0)), arrival, 0.0, DURATION)
    tween.advance(camera, DURATION*0.5, easeOutCubic)
    # Azimuth wraps to (-pi, pi] now, because it is read off sight direction through
    #   `arctan2`. Stored one ran on past +pi. So step is read on circle, not raw.
    var onward = camera.azimuth - 3.0
    if onward > PI: onward -= TAU
    if onward < -PI: onward += TAU
    check onward > 0.0 # Onward past +pi, not back down through zero.


  test "settle puts the camera on its destination at once":
    var camera = initCamera(ORIGIN, 12.0, 0.0, 0.4)
    var tween: CameraTween
    let arrival = stanceTurntable(ORIGIN, 30.0, 1.0, 0.5)
    tween.aimAt(camera, aimOn(ORIGIN, 2.0), arrival, 0.0, 0.35)
    tween.settle(camera)
    check camera.azimuth =~ 1.0
    check camera.elevation =~ 0.5
    check camera.distance =~ 30.0
    check tween.is_arrived


  test "an arrived tween stops writing, so the user's own camera move survives":
    # Bug this pins: aim rule offers selection's goal every frame. While.
    #   tween cleared its goal on arrival, that standing offer re-armed ease each frame
    #   from wherever user had just panned to, and dragged camera straight back --
    #   panning was dead for as long as anything stayed selected.
    var camera = initCamera(ORIGIN, 12.0, 0.0, 0.4)
    var tween: CameraTween
    let arrival = Position(x: 4, y: 1, z: 2)
    let goal = aimOn(arrival)
    tween.aimAt(camera, goal, camera.placeOn(arrival), 0.0, 0.35)
    tween.advance(camera, 0.35, easeOutCubic)
    check tween.is_arrived
    check camera.pivot =~ arrival

    # User moves camera, and same goal keeps being offered every frame after.
    camera.travel(0.0, 3.0, 2.0)
    let pivot_panned = camera.pivot
    for frame in 1 .. 10:
      let now = 0.35 + 0.016*float(frame)
      tween.aimAt(camera, goal, camera.placeOn(arrival), now, 0.35)
      tween.advance(camera, now, easeOutCubic)
    check camera.pivot =~ pivot_panned


  test "halt hands the camera to the user without re-arming the standing offer":
    # Pan places pivot itself, so ease stops outright and pivot stays where reader put it.
    #   `release` here would be actively wrong, and was: it clears goal, so aim.
    #   rule's own standing offer is seen as new on very next frame and takes
    #   camera straight back. Keeping goal and marking it done is what makes that
    #   offer read as already answered.
    var camera = initCamera(ORIGIN, 12.0, 0.0, 0.4)
    var tween: CameraTween
    let arrival = Position(x: 4, y: 1, z: 2)
    let goal = aimOn(arrival)
    tween.aimAt(camera, goal, camera.placeOn(arrival), 0.0, 0.35)
    tween.advance(camera, 0.10, easeOutCubic) # Mid-flight, nowhere near arrival.
    check not tween.is_arrived

    camera.travel(0.0, 3.0, 2.0)
    tween.halt()
    let pivot_panned = camera.pivot
    for frame in 1 .. 40:
      let now = 0.10 + 0.016*float(frame)
      tween.aimAt(camera, goal, camera.placeOn(arrival), now, 0.35)
      tween.advance(camera, now, easeOutCubic)
    check camera.pivot =~ pivot_panned


  test "release lets the same goal aim the camera again":
    # Withdrawing offer is what makes picking same object twice work: second.
    #   pick must aim afresh, not be recognised as one already delivered.
    var camera = initCamera(ORIGIN, 12.0, 0.0, 0.4)
    var tween: CameraTween
    let arrival = Position(x: 4, y: 1, z: 2)
    let goal = aimOn(arrival)
    tween.aimAt(camera, goal, camera.placeOn(arrival), 0.0, 0.35)
    tween.advance(camera, 0.35, easeOutCubic)
    camera.travel(0.0, 3.0, 2.0)
    let pivot_panned = camera.pivot

    tween.release()
    check tween.goal.isNone
    tween.aimAt(camera, goal, camera.placeOn(arrival), 1.0, 0.35)
    check tween.goal.isSome
    check not tween.is_arrived
    tween.advance(camera, 1.0 + 0.35, easeOutCubic)
    check camera.pivot =~ arrival
    check not (camera.pivot =~ pivot_panned)
