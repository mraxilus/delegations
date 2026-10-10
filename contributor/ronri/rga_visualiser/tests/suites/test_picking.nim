## Run `Picking` suite: one module of shared suite, which `../suites.nim` imports in order.

{.experimental: "strictFuncs".}

import ./fixtures
# Opened with `{.all.}`, so suite checks private helper directly: `isBeyondDisc` is broad phase
#   whose only property worth pinning, never rejecting hit meet would accept, is stated against
#   it directly.
import ../../src/rga_visualiser/picking {.all.}



suite "Picking":
  const (width_pick, height_pick) = (800, 600)
  let centre = ScreenPosition(x: float(width_pick) / 2.0, y: float(height_pick) / 2.0, depth: 0.0)

  proc cameraFacingOrigin(distance = 10.0): Camera =
    ## Build camera looking at world origin, so pivot is known to project to screen centre.
    cameraAround(Position(x: 0, y: 0, z: 0), distance, Direction(x: 1, y: 0, z: 0))


  test "a zoom with a selection anchors only near the depth looked at, and free flight at any":
    # Camera tilted down at origin from ten units.
    #   Point on sight line at one and half orbit distances is anchor; point eight off is
    #   passed over, and nothing else answers: world has no ground to fall back on.
    let
      camera = cameraAround(Position(x: 0, y: 0, z: 0), 10.0, Direction(x: 10, y: 0, z: 3))
      view_projection = camera.initMatrixViewProjection(width_pick / height_pick)
      scale = camera.drawExtentFor(height_pick, 0.0)
      eye = camera.eye
    var near = initScene()
    near.addObject(Position(x: -0.5 * eye.x, y: 0, z: -0.5 * eye.z).toMultivector, "p", Ink.Rose)
    let anchor_near = anchorZoomAt(
      near,
      camera,
      scale,
      view_projection,
      width_pick,
      height_pick,
      centre,
    )
    check anchor_near.isSome and abs(anchor_near.get.at.z + 0.5 * eye.z) < 1.0e-6
    var far = initScene()
    far.addObject(Position(x: -7.0 * eye.x, y: 0, z: -7.0 * eye.z).toMultivector, "p", Ink.Rose)
    let anchor_far = anchorZoomAt(
      far,
      camera,
      scale,
      view_projection,
      width_pick,
      height_pick,
      centre,
    )
    check anchor_far.isNone
    # Free flight takes it where it stands: wheel there refers to object under pointer, and
    #   band about separation would leave it nothing once flight moved on.
    let anchor_free = anchorZoomAt(
      far,
      camera,
      scale,
      view_projection,
      width_pick,
      height_pick,
      centre,
      is_banded = false,
    )
    check anchor_free.isSome and abs(anchor_free.get.at.z + 7.0 * eye.z) < 1.0e-6


  test "a star is picked where it is drawn, however far out the horizon stands":
    # Fault: horizon past `1 / TOLERANCE_ABS` read star's place as none, and pick passed it
    #   over. Camera 1e8 out stands horizon 1.8e9 off eye.
    let
      camera = cameraFacingOrigin(1.0e8)
      view_projection = camera.initMatrixViewProjection(width_pick / height_pick)
      scale = camera.drawExtentFor(height_pick, 0.0)
      star = Direction(x: -0.96, y: 0.12, z: 0.16).toMultivector
      heading = directionHorizon(star)
    check scale.radiusHorizon > 1.0 / TOLERANCE_ABS
    check heading.isSome
    let cursor = projectToScreen(
      view_projection, width_pick, height_pick, scale.eye + scale.radiusHorizon * heading.get
    )
    var scene = initScene()
    scene.addObject(star, "star", Ink.Rose)
    check pickNearest(
      scene, camera, scale, view_projection, width_pick, height_pick, cursor
    ) == some(0)


  test "a point drawn wide is picked anywhere on its disc, over the plane behind it":
    # Pick radius follows drawn disc: Sol seen from two of its own radii away spans about.
    #   360 pixels of radius on 600-pixel frame, and cursor anywhere inside picks Sol,
    #   not ecliptic disc it stands on. Two radii, since Sol is its real size, 0.00465.
    # Smallest arrangement; reduced-capacity build cannot hold it and skips whole.
    if OBJECTS_MAX < objectsOf(ScaleOrrery.Nearest):
      skip()
    else:
      var scene = initScene()
      constructOrrery(scene, ScaleOrrery.Nearest)
      var handle_sol = -1
      for handle in 0..<scene.bound:
        if scene.isAlive(handle) and scene.labelAt(handle).toText == "sol": handle_sol = handle
      check handle_sol >= 0
      let
        camera = cameraAround(
          ORIGIN, 2.0 * scene.radiusAt(handle_sol), Direction(x: 12, y: 15, z: 8)
        )
        view_projection = camera.initMatrixViewProjection(width_pick / height_pick)
        scale = camera.drawExtentFor(height_pick, 0.0)
        pixels_sol =
          radiusPixelsAt(scene.radiusAt(handle_sol), Position(x: 0, y: 0, z: 0), scale.scale)
      check pixels_sol > 300.0
      for offset in [0.0, 100.0, 250.0]:
        let cursor = ScreenPosition(x: centre.x + offset, y: centre.y, depth: 0.0)
        check pickNearest(
          scene, camera, scale, view_projection, width_pick, height_pick, cursor
        ) == some(handle_sol)
      # Well past disc, Sol is no longer answer.
      let outside = ScreenPosition(
        x: centre.x + pixels_sol + RADIUS_PICK_POINT + 1.0,
        y: centre.y,
        depth: 0.0,
      )
      check pickNearest(
        scene, camera, scale, view_projection, width_pick, height_pick, outside
      ) != some(handle_sol)


  test "a point behind a wider disc is not picked through it, and one in front is":
    # Disc hides what is behind it: star whose centre is nearer cursor than planet's.
    #   won on distance although planet's disc covered it, and tap meant for planet
    #   selected star through it. Moon in front of same disc is still picked.
    let
      camera = cameraAround(Position(x: 0, y: 0, z: 0), 2.0, Direction(x: 9, y: 0, z: 5))
      view_projection = camera.initMatrixViewProjection(width_pick / height_pick)
      scale = camera.drawExtentFor(height_pick, 0.0)
      frame_camera = camera.frame
      planet = Position(x: 0, y: 0, z: 0)
    check radiusPixelsAt(0.3, planet, scale.scale) > 60.0
    # Depth read off projection is depth along sight axis, what hiding compares.
    #   Relative tolerance: matrix is single precision, and radius of hundreds of pixels
    #   carries its rounding.
    for probe in [planet, Position(x: 1.5, y: -0.7, z: 0.4), Position(x: -3, y: 2, z: 1)]:
      let depth = dot(probe - scale.eye, scale.forward)
      check abs(depthAlongSight(view_projection, probe) - depth) < TOLERANCE_SINGLE * depth
      let pixels = radiusPixelsAt(0.3, probe, scale.scale)
      check abs(
        radiusPixelsAtDepth(0.3, depthAlongSight(view_projection, probe), scale.scale) - pixels,
      ) < TOLERANCE_SINGLE * pixels
    # Star five units past planet, offset so it projects forty pixels off its centre.
    #   inside disc; moon half unit before it, offset same way.
    let
      behind = planet + 5.0 * frame_camera.forward
      star = behind + 40.0 * worldPerPixelAt(behind, scale.scale) * frame_camera.axis_right
      before = planet - 0.5 * frame_camera.forward
      moon = before + 40.0 * worldPerPixelAt(before, scale.scale) * frame_camera.axis_right
    var hidden = initScene()
    hidden.addObject(planet.toMultivector, "planet", Ink.Cobalt, radius = 0.3)
    hidden.addObject(star.toMultivector, "star", Ink.Rose, radius = 0.001)
    let on_star = projectToScreen(view_projection, width_pick, height_pick, star)
    check abs(on_star.x - centre.x - 40.0) < 1.0
    let report_hidden = pickAt(
      hidden, camera, scale, view_projection, width_pick, height_pick, on_star
    )
    check report_hidden.handle == some(0)
    check report_hidden.count_rivals == 1  # Hidden star is no rival either.
    var shown = initScene()
    shown.addObject(planet.toMultivector, "planet", Ink.Cobalt, radius = 0.3)
    shown.addObject(moon.toMultivector, "moon", Ink.Rose, radius = 0.02)
    let
      on_moon = projectToScreen(view_projection, width_pick, height_pick, moon)
      report_shown = pickAt(shown, camera, scale, view_projection, width_pick, height_pick, on_moon)
    check report_shown.handle == some(1)
    check report_shown.count_rivals == 2  # Planet under moon is still rival to it.
    # Star straight behind moon, on same ray from eye: moon hides it from pick, and.
    #   being narrower than fingertip, not from crowd.
    let eye = camera.eye
    var lunar = initScene()
    lunar.addObject(moon.toMultivector, "moon", Ink.Rose, radius = 0.02)
    lunar.addObject(toMultivector(eye + 3.0 * (moon - eye)), "star", Ink.Jade, radius = 0.001)
    check radiusPixelsAt(0.02, moon, scale.scale) < RADIUS_PICK_POINT
    let report_lunar = pickAt(
      lunar, camera, scale, view_projection, width_pick, height_pick, on_moon
    )
    check report_lunar.handle == some(0)
    check report_lunar.count_rivals == 2
    # Cursor on disc near its rim, star's centre past rim within pixel reach: planet.
    #   Star used to win on distance to its own centre. Cursor off disc: star.
    let near_rim = behind + 130.0 * worldPerPixelAt(behind, scale.scale) * frame_camera.axis_right
    var rim = initScene()
    rim.addObject(planet.toMultivector, "planet", Ink.Cobalt, radius = 0.3)
    rim.addObject(near_rim.toMultivector, "star", Ink.Rose, radius = 0.001)
    let pixels_planet = radiusPixelsAt(0.3, planet, scale.scale)
    check pixels_planet > 100.0 and pixels_planet < 125.0
    let on_disc = ScreenPosition(x: centre.x + pixels_planet - 5.0, y: centre.y, depth: 0.0)
    check pickNearest(
      rim, camera, scale, view_projection, width_pick, height_pick, on_disc
    ) == some(0)
    let off_disc = ScreenPosition(x: centre.x + pixels_planet + 5.0, y: centre.y, depth: 0.0)
    check pickNearest(
      rim, camera, scale, view_projection, width_pick, height_pick, off_disc
    ) == some(1)
    # Star past disc's edge is picked as ever: nothing covers it there.
    let far = behind + 160.0 * worldPerPixelAt(behind, scale.scale) * frame_camera.axis_right
    var clear = initScene()
    clear.addObject(planet.toMultivector, "planet", Ink.Cobalt, radius = 0.3)
    clear.addObject(far.toMultivector, "star", Ink.Rose, radius = 0.001)
    let on_far = projectToScreen(view_projection, width_pick, height_pick, far)
    check on_far.x - centre.x > radiusPixelsAt(0.3, planet, scale.scale)
    check pickNearest(
      clear, camera, scale, view_projection, width_pick, height_pick, on_far
    ) == some(1)


  test "a pick counts its rivals: two points in reach are two, a point over a plane is one":
    # What touch refuses to drag from; see `interaction.isConstructibleByTouch`.
    #   Rank decides first, so plane under point is no rival to it.
    #   Tilted, so ground plane is seen face on rather than edge on.
    let
      camera = cameraAround(Position(x: 0, y: 0, z: 0), 10.0, Direction(x: 9, y: 0, z: 5))
      view_projection = camera.initMatrixViewProjection(width_pick / height_pick)
      scale = camera.drawExtentFor(height_pick, 0.0)
    var alone = initScene()
    alone.addObject(Position(x: 0, y: 0, z: 0).toMultivector, "p", Ink.Rose)
    alone.addObject(groundPlane(), "ground", Ink.Grid)
    let report_alone = pickAt(
      alone, camera, scale, view_projection, width_pick, height_pick, centre
    )
    check report_alone.handle == some(0)
    check report_alone.count_rivals == 1
    # Second point nearly behind first, their dots overlapping: still two, and one in.
    #   front is what is picked. Dot narrower than fingertip hides other from pick, not
    #   from crowd; see pick's hiding rule. Star field's crowds are exactly such dots.
    var crowd = initScene()
    crowd.addObject(Position(x: 0, y: 0, z: 0).toMultivector, "p", Ink.Rose)
    crowd.addObject(Position(x: 0.05, y: 0, z: 0.05).toMultivector, "q", Ink.Jade)
    crowd.addObject(groundPlane(), "ground", Ink.Grid)
    check radiusPixelsAt(RADIUS_OBJECT_DEFAULT, Position(x: 0, y: 0, z: 0), scale.scale) <
        RADIUS_PICK_POINT
    let report_crowd = pickAt(
      crowd, camera, scale, view_projection, width_pick, height_pick, centre
    )
    check report_crowd.handle == some(1)  # Nearer eye, cursor inside its dot.
    check report_crowd.count_rivals == 2
    # Far from both, plane alone answers, as its own single candidate.
    let
      corner = ScreenPosition(x: centre.x + 300.0, y: centre.y + 200.0, depth: 0.0)
      report_plane = pickAt(crowd, camera, scale, view_projection, width_pick, height_pick, corner)
    check report_plane.handle == some(2)
    check report_plane.count_rivals == 1
    # Crowd reaches past pick.
    #   Second point inside `RADIUS_CROWD_TOUCH` but outside pick reach is rival, one past
    #   it is not. Placement along camera's own right axis.
    let
      per_pixel = worldPerPixelAt(Position(x: 0, y: 0, z: 0), scale.scale)
      right = camera.frame.axis_right
    for (pixels, rivals) in [(50.0, 2), (100.0, 1)]:
      var apart = initScene()
      apart.addObject(Position(x: 0, y: 0, z: 0).toMultivector, "p", Ink.Rose)
      apart.addObject(toMultivector(Position(x: 0, y: 0, z: 0) + (pixels * per_pixel) * right),
        "q", Ink.Jade)
      let report = pickAt(apart, camera, scale, view_projection, width_pick, height_pick, centre)
      check report.handle == some(0)
      check report.count_rivals == rivals
    # Point beside picked line is rival too: finger may have meant it.
    var mixed = initScene()
    mixed.addObject(POINTS[0] ∧ POINTS[1], "l", Ink.Rose)
    mixed.addObject(toMultivector(Position(x: 0, y: 0, z: 0) + (50.0 * per_pixel) * right),
      "q", Ink.Jade)
    let report_mixed = pickAt(
      mixed, camera, scale, view_projection, width_pick, height_pick, centre
    )
    if report_mixed.handle == some(0): check report_mixed.count_rivals == 2
    # `pickNearest` is same walk's handle alone.
    check pickNearest(
      crowd, camera, scale, view_projection, width_pick, height_pick, centre
    ) == report_crowd.handle


  test "point at pivot is picked at screen centre":
    var scene = initScene()
    scene.addObject(Position(x: 0, y: 0, z: 0).toMultivector, "p", Ink.Rose)
    let
      camera = cameraFacingOrigin()
      view_projection = camera.initMatrixViewProjection(width_pick / height_pick)
    check pickNearest(
      scene, camera, camera.drawExtentFor(height_pick, 0.0), view_projection,
      width_pick, height_pick, centre
    ) == some(0)


  test "a point ahead of the eye reads in front, and is picked, at every separation held":
    # Ring, label, menu and every pick read `isInFront`, so its floor is camera's own,
    #   `DISTANCE_LIMIT_NEAR`: pointer pick of star at least radius stands 2.4e-7 off it.
    #   Point as far behind eye reads behind at every one of them.
    for power in -8..3:
      let depth = pow(10.0, float(power))
      var scene = initScene()
      scene.addObject(ORIGIN.toMultivector, "p", Ink.Rose)
      scene.setRadius(0, RADIUS_OBJECT_LEAST)
      let
        camera = cameraFacingOrigin(depth)
        view_projection = camera.initMatrixViewProjection(width_pick / height_pick)
        behind = Position(x: 2.0 * depth, y: 0.0, z: 0.0)
      check projectToScreen(view_projection, width_pick, height_pick, ORIGIN).isInFront
      check not projectToScreen(view_projection, width_pick, height_pick, behind).isInFront
      check pickNearest(
        scene, camera, camera.drawExtentFor(height_pick, 0.0), view_projection,
        width_pick, height_pick, centre
      ) == some(0)


  test "cursor far from every object picks nothing":
    var scene = initScene()
    scene.addObject(Position(x: 0, y: 0, z: 0).toMultivector, "p", Ink.Rose)
    let
      camera = cameraFacingOrigin()
      view_projection = camera.initMatrixViewProjection(width_pick / height_pick)
      corner = ScreenPosition(x: 5.0, y: 5.0, depth: 0.0)
    check pickNearest(
      scene, camera, camera.drawExtentFor(height_pick, 0.0), view_projection,
      width_pick, height_pick, corner
    ).isNone


  test "hidden object is never picked":
    var scene = initScene()
    scene.addObject(Position(x: 0, y: 0, z: 0).toMultivector, "p", Ink.Rose)
    scene.setVisible(0, false)
    let
      camera = cameraFacingOrigin()
      view_projection = camera.initMatrixViewProjection(width_pick / height_pick)
    check pickNearest(
      scene, camera, camera.drawExtentFor(height_pick, 0.0), view_projection,
      width_pick, height_pick, centre
    ).isNone


  test "line through pivot is picked at screen centre":
    var scene = initScene()
    let axis_z =
      Position(x: 0, y: 0, z: -1).toMultivector ∧ Position(x: 0, y: 0, z: 1).toMultivector
    scene.addObject(axis_z, "axis_z", Ink.Jade)
    let
      camera = cameraFacingOrigin()
      view_projection = camera.initMatrixViewProjection(width_pick / height_pick)
    check pickNearest(
      scene, camera, camera.drawExtentFor(height_pick, 0.0), view_projection,
      width_pick, height_pick, centre
    ) == some(0)


  test "a line's attitude is picked over the line it came from":
    # Attitude of line is horizon point, and `tessellate.addLine` runs.
    #   line out to *exactly* where `addPoint` draws that attitude, "with no gap" -- so
    #   two overlap on screen precisely and ranking is what has to separate them.
    #   Points outrank lines, so star must win. It did not: `pickNearest` built its
    #   `DrawExtent` fieldwise, leaving `scale.eye_point` zero multivector, so
    #   `anchorFor` answered none for every horizon point and whole branch was skipped
    #   before anything could be ranked.
    let
      camera = cameraFacingOrigin()
      view_projection = camera.initMatrixViewProjection(width_pick / height_pick)
      frame_camera = camera.frame
    # Running away from eye but tilted off sight line, so line is streak.
    #   rather than dot and its vanishing point stands clear of screen's middle.
    let heading = normalize(frame_camera.forward + 0.3 * Direction(x: 0, y: 0, z: 1))
    check heading.isSome
    let
      line = ORIGIN_WORLD.toMultivector ∧ toMultivector(ORIGIN_WORLD + heading.get)
      star = attitude(line)
    check isHorizon(star)

    # Where star is actually drawn, asked of same proc drawing asks.
    let place = anchorFor(star, camera.drawExtentFor(height_pick, 0.0))
    check place.isSome
    let screen = projectToScreen(view_projection, width_pick, height_pick, place.get)
    check screen.isInFront
    let at = ScreenPosition(x: screen.x, y: screen.y, depth: 0.0)

    # Line alone is picked there -- without this case would pass on cursor that.
    #   simply misses line, proving nothing about which of two wins.
    var scene_line = initScene()
    scene_line.addObject(line, "L", Ink.Jade)
    check pickNearest(
      scene_line, camera, camera.drawExtentFor(height_pick, 0.0), view_projection,
      width_pick, height_pick, at
    ) ==
      some(0)

    # With both in scene, star takes it.
    var scene = initScene()
    scene.addObject(line, "L", Ink.Jade)
    scene.addObject(star, "att", Ink.Cobalt)
    check pickNearest(
      scene, camera, camera.drawExtentFor(height_pick, 0.0), view_projection,
      width_pick, height_pick, at
    ) == some(1)


  test "point pick radius tolerates cursor imprecision, not unlimited slack":
    var scene = initScene()
    scene.addObject(Position(x: 0, y: 0, z: 0).toMultivector, "p", Ink.Rose)
    let
      camera = cameraFacingOrigin()
      view_projection = camera.initMatrixViewProjection(width_pick / height_pick)
    # Point itself projects exactly to centre; offsetting cursor instead of.
    #   point is what actually exercises radius bound.
    let
      near = ScreenPosition(x: centre.x + RADIUS_PICK_POINT - 1.0, y: centre.y, depth: 0.0)
      far = ScreenPosition(x: centre.x + RADIUS_PICK_POINT + 1.0, y: centre.y, depth: 0.0)
    check pickNearest(
      scene, camera, camera.drawExtentFor(height_pick, 0.0), view_projection,
      width_pick, height_pick, near
    ) == some(0)
    check pickNearest(
      scene, camera, camera.drawExtentFor(height_pick, 0.0), view_projection,
      width_pick, height_pick, far
    ).isNone


  test "line pick radius tolerates cursor imprecision, not unlimited slack":
    var scene = initScene()
    let axis_z =
      Position(x: 0, y: 0, z: -1).toMultivector ∧ Position(x: 0, y: 0, z: 1).toMultivector
    scene.addObject(axis_z, "axis_z", Ink.Jade)
    let
      camera = cameraFacingOrigin()
      view_projection = camera.initMatrixViewProjection(width_pick / height_pick)
      near = ScreenPosition(x: centre.x + RADIUS_PICK_LINE - 1.0, y: centre.y, depth: 0.0)
      far = ScreenPosition(x: centre.x + RADIUS_PICK_LINE + 1.0, y: centre.y, depth: 0.0)
    check pickNearest(
      scene, camera, camera.drawExtentFor(height_pick, 0.0), view_projection,
      width_pick, height_pick, near
    ) == some(0)
    check pickNearest(
      scene, camera, camera.drawExtentFor(height_pick, 0.0), view_projection,
      width_pick, height_pick, far
    ).isNone


  test "point wins a tie over a line through it":
    var scene = initScene()
    let axis_z =
      Position(x: 0, y: 0, z: -1).toMultivector ∧ Position(x: 0, y: 0, z: 1).toMultivector
    scene.addObject(axis_z, "axis_z", Ink.Jade)  # Index 0: line, passes straight through origin.
    scene.addObject(Position(x: 0, y: 0, z: 0).toMultivector, "p", Ink.Rose)  # Index 1: point.
    let
      camera = cameraFacingOrigin()
      view_projection = camera.initMatrixViewProjection(width_pick / height_pick)
    check pickNearest(
      scene, camera, camera.drawExtentFor(height_pick, 0.0), view_projection,
      width_pick, height_pick, centre
    ) == some(1)


  test "line wins a tie over a plane behind it":
    var scene = initScene()
    let facing = (
      Position(x: 0, y: -3, z: -3).toMultivector ∧
      Position(x: 0, y: 3, z: -3).toMultivector ∧
      Position(x: 0, y: 0, z: 3).toMultivector
    )
    let axis_z =
      Position(x: 0, y: 0, z: -1).toMultivector ∧ Position(x: 0, y: 0, z: 1).toMultivector
    scene.addObject(facing, "facing", Ink.Olive)  # Index 0: plane, spans view straight on.
    scene.addObject(axis_z, "axis_z", Ink.Jade)  # Index 1: line, passes straight through origin.
    let
      camera = cameraFacingOrigin()
      view_projection = camera.initMatrixViewProjection(width_pick / height_pick)
    check pickNearest(
      scene, camera, camera.drawExtentFor(height_pick, 0.0), view_projection,
      width_pick, height_pick, centre
    ) == some(1)


  test "point wins a tie over a plane behind it":
    var scene = initScene()
    let facing = (
      Position(x: 0, y: -3, z: -3).toMultivector ∧
      Position(x: 0, y: 3, z: -3).toMultivector ∧
      Position(x: 0, y: 0, z: 3).toMultivector
    )
    scene.addObject(facing, "facing", Ink.Olive)  # Index 0: plane, spans view straight on.
    scene.addObject(Position(x: 0, y: 0, z: 0).toMultivector, "p", Ink.Rose)  # Index 1: point.
    let
      camera = cameraFacingOrigin()
      view_projection = camera.initMatrixViewProjection(width_pick / height_pick)
    check pickNearest(
      scene, camera, camera.drawExtentFor(height_pick, 0.0), view_projection,
      width_pick, height_pick, centre
    ) == some(1)


  test "plane misses where its sight ray lands outside the drawn rim":
    # Window corner is widest angle any ray reaches, off sight axis, and.
    #   camera stands far enough back (30 units, against `EXTENT_PLANE_F` of 8) that
    #   corner ray's own diagonal reach lands well outside drawn rim's fixed
    #   radius regardless of how far back camera stands, while centre ray still
    #   lands on support point well within it.
    var scene = initScene()
    let facing = (
      Position(x: 0, y: -3, z: -3).toMultivector ∧
      Position(x: 0, y: 3, z: -3).toMultivector ∧
      Position(x: 0, y: 0, z: 3).toMultivector
    )
    scene.addObject(facing, "facing", Ink.Olive)
    let
      camera = cameraFacingOrigin(distance = 30.0)
      view_projection = camera.initMatrixViewProjection(width_pick / height_pick)
    check pickNearest(
      scene, camera, camera.drawExtentFor(height_pick, 0.0), view_projection,
      width_pick, height_pick, centre
    ) == some(0)
    for (label, corner_x, corner_y) in [
      ("top-left corner", 0.0, 0.0),
      ("bottom-right corner", float(width_pick), float(height_pick)),
    ]:
      let cursor = ScreenPosition(x: corner_x, y: corner_y, depth: 0.0)
      check pickNearest(
        scene, camera, camera.drawExtentFor(height_pick, 0.0), view_projection,
        width_pick, height_pick, cursor
      ).isNone


  test "the disc broad phase never rejects a cursor over the disc's own sphere":
    # `isBeyondDisc` may only skip meet meet would refuse. Every point of sphere.
    #   bounding disc projects onto cursor phase must let through -- sampled over
    #   fixed grid of directions, from cameras facing and oblique to disc.
    let centre = Position(x: 1.5, y: -2.0, z: 0.5)
    for out_to in [
      Direction(x: 1, y: 0, z: 0), Direction(x: 6, y: 8, z: 4), Direction(x: -6, y: 5, z: -6),
    ]:
      let
        camera = cameraAround(ORIGIN, 30.0, out_to)
        view_projection = camera.initMatrixViewProjection(width_pick / height_pick)
        tangent = camera.drawExtentFor(height_pick, 0.0).tangent_half_view
      for i in 0..<24:
        for j in 0..12:
          let
            (theta, phi) = (float(i) * TAU / 24.0, float(j) * PI / 12.0)
            on_sphere = Position(
              x: centre.x + EXTENT_PLANE_F * sin(phi) * cos(theta),
              y: centre.y + EXTENT_PLANE_F * sin(phi) * sin(theta),
              z: centre.z + EXTENT_PLANE_F * cos(phi),
            )
            cursor = projectToScreen(view_projection, width_pick, height_pick, on_sphere)
          check not isBeyondDisc(
            view_projection,
            width_pick,
            height_pick,
            tangent,
            centre,
            EXTENT_PLANE_F,
            cursor,
          )
      # And phase is not inert: window's corner is well clear of disc this far off.
      let corner = ScreenPosition(x: 0.0, y: 0.0, depth: 0.0)
      check isBeyondDisc(
        view_projection,
        width_pick,
        height_pick,
        tangent,
        centre,
        EXTENT_PLANE_F,
        corner,
      )


  test "a plane is picked from either side of it, whichever way its normal points":
    # **Regression case for shipped fault.** Plane's hit test read depth of.
    #   raw `ray ∨ plane` meet, whose weight carries which side ray crossed from,
    #   not where crossing is. `unitize` divides by that weight's *norm* and so keeps
    #   its sign, and `depthAgainst` is linear in its point -- so every plane met from
    #   behind its own normal reported its distance ahead of eye negated, was read as
    #   standing behind eye, and went unpickable at every pixel of disc it was
    #   plainly drawn at. Measured on built page: plane joined from three of
    #   opening scene's own points could not be picked anywhere on 900x800 canvas, so
    #   no drag could reach one; ground plane, whose normal happens to face eye,
    #   picked fine and hid fault.
    #   Held from both sides of one plane rather than on one built to fail: pair is
    #   what makes *sign* subject, and either alone passes on coin flip.
    for facing in [1.0, -1.0]:
      var scene = initScene()
      # Three points spanning x = 0. Ordered by `facing`, so two runs differ in.
      #   nothing but orientation of very same plane.
      let corners = [
        Position(x: 0, y: -3 * facing, z: -3).toMultivector,
        Position(x: 0, y: 3 * facing, z: -3).toMultivector,
        Position(x: 0, y: 0, z: 3).toMultivector,
      ]
      scene.addObject(corners[0] ∧ corners[1] ∧ corners[2], "spanning", Ink.Olive)
      let
        camera = cameraFacingOrigin()
        view_projection = camera.initMatrixViewProjection(width_pick / height_pick)
      check pickNearest(
        scene,
        camera,
        camera.drawExtentFor(height_pick, 0.0),
        view_projection,
        width_pick,
        height_pick,
        centre,
      ) == some(0)


  test "a plane a camera stands millionths off is picked, and found under the pointer":
    # Hit stands at camera's own separation, under millionth yet over camera's floor.
    #   In front is judged against hit's own reach from eye, so it reads in front.
    #   Plane as far behind eye answers neither.
    let corners = [
      Position(x: 0, y: -3, z: -3).toMultivector,
      Position(x: 0, y: 3, z: -3).toMultivector,
      Position(x: 0, y: 0, z: 3).toMultivector,
    ]
    for power in -8 .. -7:
      let depth = pow(10.0, float(power))
      var (scene, behind) = (initScene(), initScene())
      scene.addObject(corners[0] ∧ corners[1] ∧ corners[2], "spanning", Ink.Olive)
      let shift = Direction(x: 2.0 * depth, y: 0.0, z: 0.0).toMultivector
      behind.addObject(
        (corners[0] + shift) ∧ (corners[1] + shift) ∧ (corners[2] + shift), "behind", Ink.Olive
      )
      let
        camera = cameraFacingOrigin(depth)
        view_projection = camera.initMatrixViewProjection(width_pick / height_pick)
        scale = camera.drawExtentFor(height_pick, 0.0)
      check pickNearest(
        scene, camera, scale, view_projection, width_pick, height_pick, centre
      ) == some(0)
      let under = positionUnderPointerOn(scene, 0, camera, scale, width_pick, height_pick, centre)
      check under.isSome
      check norm(under.get - ORIGIN) <= 1.0e-3 * depth
      check pickNearest(
        behind, camera, scale, view_projection, width_pick, height_pick, centre
      ).isNone
      check positionUnderPointerOn(behind, 0, camera, scale, width_pick, height_pick, centre).isNone


  test "nearer plane wins over a farther one behind it":
    # Eye sits at (10, 0, 0) looking toward origin along -x, so plane at x=6 stands.
    #   nearer eye (distance 4) than one at x=3 (distance 7).
    var scene = initScene()
    let far_plane = (
      Position(x: 3, y: -3, z: -3).toMultivector ∧
      Position(x: 3, y: 3, z: -3).toMultivector ∧
      Position(x: 3, y: 0, z: 3).toMultivector
    )
    let near_plane = (
      Position(x: 6, y: -3, z: -3).toMultivector ∧
      Position(x: 6, y: 3, z: -3).toMultivector ∧
      Position(x: 6, y: 0, z: 3).toMultivector
    )
    scene.addObject(far_plane, "far", Ink.Olive)  # Index 0.
    scene.addObject(near_plane, "near", Ink.Cobalt)  # Index 1.
    let
      camera = cameraFacingOrigin()
      view_projection = camera.initMatrixViewProjection(width_pick / height_pick)
    check pickNearest(
      scene, camera, camera.drawExtentFor(height_pick, 0.0), view_projection,
      width_pick, height_pick, centre
    ) == some(1)
