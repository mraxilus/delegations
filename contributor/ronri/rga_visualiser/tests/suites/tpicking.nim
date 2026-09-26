## Run `Picking` suite: one module of shared suite, which `../suites.nim` imports in order.

import ./fixtures
# Opened with `{.all.}`, so suite checks private helper directly: `isBeyondDisc` is broad phase
#   whose only property worth pinning, never rejecting hit meet would accept, is stated against
#   it directly.
import ../../src/rga_visualiser/picking {.all.}


suite "Picking":
  const (WIDTH_PICK, HEIGHT_PICK) = (800, 600)
  let CENTRE = ScreenPosition(x: float(WIDTH_PICK)/2.0, y: float(HEIGHT_PICK)/2.0, depth: 0.0)

  proc cameraFacingOrigin(distance = 10.0): Camera =
    ## Build camera looking at world origin, so pivot is known to project to screen centre.
    initCamera(
      pivot = Position(x: 0, y: 0, z: 0), distance = distance, azimuth = 0.0, elevation = 0.0
    )

  test "a zoom anchors on what is under the cursor only near the depth being looked at":
    # Camera tilted down at origin from ten units.
    #   Point on sight line below ground at one and half orbit distances is anchor; point
    #   eight off is passed over, and ground under cursor -- origin itself -- answers instead.
    let camera = initCamera(
      pivot = Position(x: 0, y: 0, z: 0), distance = 10.0, azimuth = 0.0, elevation = 0.3
    )
    let view_projection = camera.initMatrixViewProjection(WIDTH_PICK/HEIGHT_PICK)
    let scale = camera.drawExtentFor(HEIGHT_PICK)
    let eye = camera.eye
    var near = initScene()
    near.addObject(toMultivector(Position(x: -0.5*eye.x, y: 0, z: -0.5*eye.z)), "p", Ink.Rose)
    let anchor_near = anchorZoomAt(
      near, camera, scale, view_projection, WIDTH_PICK, HEIGHT_PICK, CENTRE,
    )
    check anchor_near.isSome and abs(anchor_near.get.at.z + 0.5*eye.z) < 1.0e-6
    var far = initScene()
    far.addObject(toMultivector(Position(x: -7.0*eye.x, y: 0, z: -7.0*eye.z)), "p", Ink.Rose)
    let anchor_far = anchorZoomAt(
      far, camera, scale, view_projection, WIDTH_PICK, HEIGHT_PICK, CENTRE,
    )
    check anchor_far.isSome and abs(anchor_far.get.at.x) < 1.0e-6 and
      abs(anchor_far.get.at.z) < 1.0e-6

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
      for handle in 0 ..< scene.bound:
        if scene.isAlive(handle) and toText(scene.labelAt(handle)) == "sol": handle_sol = handle
      check handle_sol >= 0
      let camera = initCamera(
        pivot = Position(x: 0, y: 0, z: 0), distance = 2.0*scene.radiusAt(handle_sol),
        azimuth = 0.9, elevation = 0.4,
      )
      let view_projection = camera.initMatrixViewProjection(WIDTH_PICK/HEIGHT_PICK)
      let scale = camera.drawExtentFor(HEIGHT_PICK)
      let pixels_sol =
        radiusPixelsAt(scene.radiusAt(handle_sol), Position(x: 0, y: 0, z: 0), scale.scale)
      check pixels_sol > 300.0
      for offset in [0.0, 100.0, 250.0]:
        let cursor = ScreenPosition(x: CENTRE.x + offset, y: CENTRE.y, depth: 0.0)
        check pickNearest(
          scene, camera, scale, view_projection, WIDTH_PICK, HEIGHT_PICK, cursor
        ) == some(handle_sol)
      # Well past disc, Sol is no longer answer.
      let outside = ScreenPosition(
        x: CENTRE.x + pixels_sol + RADIUS_PICK_POINT + 1.0, y: CENTRE.y, depth: 0.0
      )
      check pickNearest(
        scene, camera, scale, view_projection, WIDTH_PICK, HEIGHT_PICK, outside
      ) != some(handle_sol)

  test "a point behind a wider disc is not picked through it, and one in front is":
    # Disc hides what is behind it: star whose centre is nearer cursor than planet's.
    #   won on distance although planet's disc covered it, and tap meant for planet
    #   selected star through it. Moon in front of same disc is still picked.
    let camera = initCamera(
      pivot = Position(x: 0, y: 0, z: 0), distance = 2.0, azimuth = 0.0, elevation = 0.5
    )
    let view_projection = camera.initMatrixViewProjection(WIDTH_PICK/HEIGHT_PICK)
    let scale = camera.drawExtentFor(HEIGHT_PICK)
    let frame_camera = camera.frame
    let planet = Position(x: 0, y: 0, z: 0)
    check radiusPixelsAt(0.3, planet, scale.scale) > 60.0
    # Depth read off projection is depth along sight axis, what hiding compares.
    #   Relative tolerance: matrix is single precision, and radius of hundreds of pixels
    #   carries its rounding.
    for probe in [planet, Position(x: 1.5, y: -0.7, z: 0.4), Position(x: -3, y: 2, z: 1)]:
      let depth = dot(probe - scale.eye, scale.forward)
      check abs(depthAlongSight(view_projection, probe) - depth) < TOLERANCE_SINGLE*depth
      let pixels = radiusPixelsAt(0.3, probe, scale.scale)
      check abs(
        radiusPixelsAtDepth(0.3, depthAlongSight(view_projection, probe), scale.scale) -
        pixels
      ) < TOLERANCE_SINGLE*pixels
    # Star five units past planet, offset so it projects forty pixels off its centre.
    #   inside disc; moon half unit before it, offset same way.
    let behind = planet + 5.0*frame_camera.forward
    let star = behind + 40.0*worldPerPixelAt(behind, scale.scale)*frame_camera.axis_right
    let before = planet - 0.5*frame_camera.forward
    let moon = before + 40.0*worldPerPixelAt(before, scale.scale)*frame_camera.axis_right
    var hidden = initScene()
    hidden.addObject(toMultivector(planet), "planet", Ink.Cobalt, radius = 0.3)
    hidden.addObject(toMultivector(star), "star", Ink.Rose, radius = 0.001)
    let on_star = projectToScreen(view_projection, WIDTH_PICK, HEIGHT_PICK, star)
    check abs(on_star.x - CENTRE.x - 40.0) < 1.0
    let report_hidden = pickAt(
      hidden, camera, scale, view_projection, WIDTH_PICK, HEIGHT_PICK, on_star
    )
    check report_hidden.handle == some(0)
    check report_hidden.count_rivals == 1 # Hidden star is no rival either.
    var shown = initScene()
    shown.addObject(toMultivector(planet), "planet", Ink.Cobalt, radius = 0.3)
    shown.addObject(toMultivector(moon), "moon", Ink.Rose, radius = 0.02)
    let on_moon = projectToScreen(view_projection, WIDTH_PICK, HEIGHT_PICK, moon)
    let report_shown = pickAt(
      shown, camera, scale, view_projection, WIDTH_PICK, HEIGHT_PICK, on_moon
    )
    check report_shown.handle == some(1)
    check report_shown.count_rivals == 2 # Planet under moon is still rival to it.
    # Star straight behind moon, on same ray from eye: moon hides it from pick, and.
    #   being narrower than fingertip, not from crowd.
    let eye = camera.eye
    var lunar = initScene()
    lunar.addObject(toMultivector(moon), "moon", Ink.Rose, radius = 0.02)
    lunar.addObject(toMultivector(eye + 3.0*(moon - eye)), "star", Ink.Jade, radius = 0.001)
    check radiusPixelsAt(0.02, moon, scale.scale) < RADIUS_PICK_POINT
    let report_lunar = pickAt(
      lunar, camera, scale, view_projection, WIDTH_PICK, HEIGHT_PICK, on_moon
    )
    check report_lunar.handle == some(0)
    check report_lunar.count_rivals == 2
    # Cursor on disc near its rim, star's centre past rim within pixel reach: planet.
    #   Star used to win on distance to its own centre. Cursor off disc: star.
    let near_rim = behind + 130.0*worldPerPixelAt(behind, scale.scale)*frame_camera.axis_right
    var rim = initScene()
    rim.addObject(toMultivector(planet), "planet", Ink.Cobalt, radius = 0.3)
    rim.addObject(toMultivector(near_rim), "star", Ink.Rose, radius = 0.001)
    let pixels_planet = radiusPixelsAt(0.3, planet, scale.scale)
    check pixels_planet > 100.0 and pixels_planet < 125.0
    let on_disc = ScreenPosition(x: CENTRE.x + pixels_planet - 5.0, y: CENTRE.y, depth: 0.0)
    check pickNearest(
      rim, camera, scale, view_projection, WIDTH_PICK, HEIGHT_PICK, on_disc
    ) == some(0)
    let off_disc = ScreenPosition(x: CENTRE.x + pixels_planet + 5.0, y: CENTRE.y, depth: 0.0)
    check pickNearest(
      rim, camera, scale, view_projection, WIDTH_PICK, HEIGHT_PICK, off_disc
    ) == some(1)
    # Star past disc's edge is picked as ever: nothing covers it there.
    let far = behind + 160.0*worldPerPixelAt(behind, scale.scale)*frame_camera.axis_right
    var clear = initScene()
    clear.addObject(toMultivector(planet), "planet", Ink.Cobalt, radius = 0.3)
    clear.addObject(toMultivector(far), "star", Ink.Rose, radius = 0.001)
    let on_far = projectToScreen(view_projection, WIDTH_PICK, HEIGHT_PICK, far)
    check on_far.x - CENTRE.x > radiusPixelsAt(0.3, planet, scale.scale)
    check pickNearest(
      clear, camera, scale, view_projection, WIDTH_PICK, HEIGHT_PICK, on_far
    ) == some(1)

  test "a pick counts its rivals: two points in reach are two, a point over a plane is one":
    # What touch refuses to drag from; see `interaction.canConstructByTouch`.
    #   Rank decides first, so plane under point is no rival to it.
    #   Tilted, so ground plane is seen face on rather than edge on.
    let camera = initCamera(
      pivot = Position(x: 0, y: 0, z: 0), distance = 10.0, azimuth = 0.0, elevation = 0.5
    )
    let view_projection = camera.initMatrixViewProjection(WIDTH_PICK/HEIGHT_PICK)
    let scale = camera.drawExtentFor(HEIGHT_PICK)
    var alone = initScene()
    alone.addObject(toMultivector(Position(x: 0, y: 0, z: 0)), "p", Ink.Rose)
    alone.addObject(groundPlane(), "ground", Ink.Grid)
    let report_alone = pickAt(
      alone, camera, scale, view_projection, WIDTH_PICK, HEIGHT_PICK, CENTRE
    )
    check report_alone.handle == some(0)
    check report_alone.count_rivals == 1
    # Second point nearly behind first, their dots overlapping: still two, and one in.
    #   front is what is picked. Dot narrower than fingertip hides other from pick, not
    #   from crowd; see pick's hiding rule. Star field's crowds are exactly such dots.
    var crowd = initScene()
    crowd.addObject(toMultivector(Position(x: 0, y: 0, z: 0)), "p", Ink.Rose)
    crowd.addObject(toMultivector(Position(x: 0.05, y: 0, z: 0.05)), "q", Ink.Jade)
    crowd.addObject(groundPlane(), "ground", Ink.Grid)
    check radiusPixelsAt(RADIUS_OBJECT_DEFAULT, Position(x: 0, y: 0, z: 0), scale.scale) <
      RADIUS_PICK_POINT
    let report_crowd = pickAt(
      crowd, camera, scale, view_projection, WIDTH_PICK, HEIGHT_PICK, CENTRE
    )
    check report_crowd.handle == some(1) # Nearer eye, cursor inside its dot.
    check report_crowd.count_rivals == 2
    # Far from both, plane alone answers, as its own single candidate.
    let corner = ScreenPosition(x: CENTRE.x + 300.0, y: CENTRE.y + 200.0, depth: 0.0)
    let report_plane = pickAt(
      crowd, camera, scale, view_projection, WIDTH_PICK, HEIGHT_PICK, corner
    )
    check report_plane.handle == some(2)
    check report_plane.count_rivals == 1
    # Crowd reaches past pick.
    #   Second point inside `RADIUS_CROWD_TOUCH` but outside pick reach is rival, one past
    #   it is not. Placement along camera's own right axis.
    let per_pixel = worldPerPixelAt(Position(x: 0, y: 0, z: 0), scale.scale)
    let right = camera.frame.axis_right
    for (pixels, rivals) in [(50.0, 2), (100.0, 1)]:
      var apart = initScene()
      apart.addObject(toMultivector(Position(x: 0, y: 0, z: 0)), "p", Ink.Rose)
      apart.addObject(toMultivector(Position(x: 0, y: 0, z: 0) + (pixels*per_pixel)*right),
        "q", Ink.Jade)
      let report = pickAt(
        apart, camera, scale, view_projection, WIDTH_PICK, HEIGHT_PICK, CENTRE
      )
      check report.handle == some(0)
      check report.count_rivals == rivals
    # Point beside picked line is rival too: finger may have meant it.
    var mixed = initScene()
    mixed.addObject(POINTS[0] ∧ POINTS[1], "l", Ink.Rose)
    mixed.addObject(toMultivector(Position(x: 0, y: 0, z: 0) + (50.0*per_pixel)*right),
      "q", Ink.Jade)
    let report_mixed = pickAt(
      mixed, camera, scale, view_projection, WIDTH_PICK, HEIGHT_PICK, CENTRE
    )
    if report_mixed.handle == some(0): check report_mixed.count_rivals == 2
    # `pickNearest` is same walk's handle alone.
    check pickNearest(
      crowd, camera, scale, view_projection, WIDTH_PICK, HEIGHT_PICK, CENTRE
    ) == report_crowd.handle

  test "point at pivot is picked at screen centre":
    var scene = initScene()
    scene.addObject(toMultivector(Position(x: 0, y: 0, z: 0)), "p", Ink.Rose)
    let camera = cameraFacingOrigin()
    let view_projection = camera.initMatrixViewProjection(WIDTH_PICK/HEIGHT_PICK)
    check pickNearest(
      scene, camera, camera.drawExtentFor(HEIGHT_PICK), view_projection,
      WIDTH_PICK, HEIGHT_PICK, CENTRE
    ) == some(0)


  test "cursor far from every object picks nothing":
    var scene = initScene()
    scene.addObject(toMultivector(Position(x: 0, y: 0, z: 0)), "p", Ink.Rose)
    let camera = cameraFacingOrigin()
    let view_projection = camera.initMatrixViewProjection(WIDTH_PICK/HEIGHT_PICK)
    let corner = ScreenPosition(x: 5.0, y: 5.0, depth: 0.0)
    check pickNearest(
      scene, camera, camera.drawExtentFor(HEIGHT_PICK), view_projection,
      WIDTH_PICK, HEIGHT_PICK, corner
    ).isNone


  test "hidden object is never picked":
    var scene = initScene()
    scene.addObject(toMultivector(Position(x: 0, y: 0, z: 0)), "p", Ink.Rose)
    scene.setVisible(0, false)
    let camera = cameraFacingOrigin()
    let view_projection = camera.initMatrixViewProjection(WIDTH_PICK/HEIGHT_PICK)
    check pickNearest(
      scene, camera, camera.drawExtentFor(HEIGHT_PICK), view_projection,
      WIDTH_PICK, HEIGHT_PICK, CENTRE
    ).isNone


  test "line through pivot is picked at screen centre":
    var scene = initScene()
    let axis_z =
      toMultivector(Position(x: 0, y: 0, z: -1)) ∧ toMultivector(Position(x: 0, y: 0, z: 1))
    scene.addObject(axis_z, "axis_z", Ink.Jade)
    let camera = cameraFacingOrigin()
    let view_projection = camera.initMatrixViewProjection(WIDTH_PICK/HEIGHT_PICK)
    check pickNearest(
      scene, camera, camera.drawExtentFor(HEIGHT_PICK), view_projection,
      WIDTH_PICK, HEIGHT_PICK, CENTRE
    ) == some(0)


  test "a line's attitude is picked over the line it came from":
    # Attitude of line is horizon point, and `tessellate.addLine` runs.
    #   line out to *exactly* where `addPoint` draws that attitude, "with no gap" -- so
    #   two overlap on screen precisely and ranking is what has to separate them.
    #   Points outrank lines, so star must win. It did not: `pickNearest` built its
    #   `DrawExtent` fieldwise, leaving `scale.eye_point` zero multivector, so
    #   `anchorFor` answered none for every horizon point and whole branch was skipped
    #   before anything could be ranked.
    let camera = cameraFacingOrigin()
    let view_projection = camera.initMatrixViewProjection(WIDTH_PICK/HEIGHT_PICK)
    let frame_camera = camera.frame
    # Running away from eye but tilted off sight line, so line is streak.
    #   rather than dot and its vanishing point stands clear of screen's middle.
    let heading = normalize(frame_camera.forward + 0.3*Direction(x: 0, y: 0, z: 1))
    check heading.isSome
    let line = toMultivector(ORIGIN_WORLD) ∧ toMultivector(ORIGIN_WORLD + heading.get)
    let star = attitude(line)
    check isHorizon(star)

    # Where star is actually drawn, asked of same proc drawing asks.
    let place = anchorFor(star, camera.drawExtentFor(HEIGHT_PICK))
    check place.isSome
    let screen = projectToScreen(view_projection, WIDTH_PICK, HEIGHT_PICK, place.get)
    check screen.isInFront
    let at = ScreenPosition(x: screen.x, y: screen.y, depth: 0.0)

    # Line alone is picked there -- without this case would pass on cursor that.
    #   simply misses line, proving nothing about which of two wins.
    var scene_line = initScene()
    scene_line.addObject(line, "L", Ink.Jade)
    check pickNearest(
      scene_line, camera, camera.drawExtentFor(HEIGHT_PICK), view_projection,
      WIDTH_PICK, HEIGHT_PICK, at
    ) ==
      some(0)

    # With both in scene, star takes it.
    var scene = initScene()
    scene.addObject(line, "L", Ink.Jade)
    scene.addObject(star, "att", Ink.Cobalt)
    check pickNearest(
      scene, camera, camera.drawExtentFor(HEIGHT_PICK), view_projection,
      WIDTH_PICK, HEIGHT_PICK, at
    ) == some(1)


  test "point pick radius tolerates cursor imprecision, not unlimited slack":
    var scene = initScene()
    scene.addObject(toMultivector(Position(x: 0, y: 0, z: 0)), "p", Ink.Rose)
    let camera = cameraFacingOrigin()
    let view_projection = camera.initMatrixViewProjection(WIDTH_PICK/HEIGHT_PICK)
    # Point itself projects exactly to CENTRE; offsetting cursor instead of.
    #   point is what actually exercises radius bound.
    let near = ScreenPosition(x: CENTRE.x + RADIUS_PICK_POINT - 1.0, y: CENTRE.y, depth: 0.0)
    let far = ScreenPosition(x: CENTRE.x + RADIUS_PICK_POINT + 1.0, y: CENTRE.y, depth: 0.0)
    check pickNearest(
      scene, camera, camera.drawExtentFor(HEIGHT_PICK), view_projection,
      WIDTH_PICK, HEIGHT_PICK, near
    ) == some(0)
    check pickNearest(
      scene, camera, camera.drawExtentFor(HEIGHT_PICK), view_projection,
      WIDTH_PICK, HEIGHT_PICK, far
    ).isNone


  test "line pick radius tolerates cursor imprecision, not unlimited slack":
    var scene = initScene()
    let axis_z =
      toMultivector(Position(x: 0, y: 0, z: -1)) ∧ toMultivector(Position(x: 0, y: 0, z: 1))
    scene.addObject(axis_z, "axis_z", Ink.Jade)
    let camera = cameraFacingOrigin()
    let view_projection = camera.initMatrixViewProjection(WIDTH_PICK/HEIGHT_PICK)
    let near = ScreenPosition(x: CENTRE.x + RADIUS_PICK_LINE - 1.0, y: CENTRE.y, depth: 0.0)
    let far = ScreenPosition(x: CENTRE.x + RADIUS_PICK_LINE + 1.0, y: CENTRE.y, depth: 0.0)
    check pickNearest(
      scene, camera, camera.drawExtentFor(HEIGHT_PICK), view_projection,
      WIDTH_PICK, HEIGHT_PICK, near
    ) == some(0)
    check pickNearest(
      scene, camera, camera.drawExtentFor(HEIGHT_PICK), view_projection,
      WIDTH_PICK, HEIGHT_PICK, far
    ).isNone


  test "point wins a tie over a line through it":
    var scene = initScene()
    let axis_z =
      toMultivector(Position(x: 0, y: 0, z: -1)) ∧ toMultivector(Position(x: 0, y: 0, z: 1))
    scene.addObject(axis_z, "axis_z", Ink.Jade) # Index 0: line, passes straight through origin.
    scene.addObject(toMultivector(Position(x: 0, y: 0, z: 0)), "p", Ink.Rose) # Index 1: point.
    let camera = cameraFacingOrigin()
    let view_projection = camera.initMatrixViewProjection(WIDTH_PICK/HEIGHT_PICK)
    check pickNearest(
      scene, camera, camera.drawExtentFor(HEIGHT_PICK), view_projection,
      WIDTH_PICK, HEIGHT_PICK, CENTRE
    ) == some(1)


  test "line wins a tie over a plane behind it":
    var scene = initScene()
    let facing = (
      toMultivector(Position(x: 0, y: -3, z: -3)) ∧
      toMultivector(Position(x: 0, y: 3, z: -3)) ∧
      toMultivector(Position(x: 0, y: 0, z: 3))
    )
    let axis_z =
      toMultivector(Position(x: 0, y: 0, z: -1)) ∧ toMultivector(Position(x: 0, y: 0, z: 1))
    scene.addObject(facing, "facing", Ink.Olive) # Index 0: plane, spans view straight on.
    scene.addObject(axis_z, "axis_z", Ink.Jade) # Index 1: line, passes straight through origin.
    let camera = cameraFacingOrigin()
    let view_projection = camera.initMatrixViewProjection(WIDTH_PICK/HEIGHT_PICK)
    check pickNearest(
      scene, camera, camera.drawExtentFor(HEIGHT_PICK), view_projection,
      WIDTH_PICK, HEIGHT_PICK, CENTRE
    ) == some(1)


  test "point wins a tie over a plane behind it":
    var scene = initScene()
    let facing = (
      toMultivector(Position(x: 0, y: -3, z: -3)) ∧
      toMultivector(Position(x: 0, y: 3, z: -3)) ∧
      toMultivector(Position(x: 0, y: 0, z: 3))
    )
    scene.addObject(facing, "facing", Ink.Olive) # Index 0: plane, spans view straight on.
    scene.addObject(toMultivector(Position(x: 0, y: 0, z: 0)), "p", Ink.Rose) # Index 1: point.
    let camera = cameraFacingOrigin()
    let view_projection = camera.initMatrixViewProjection(WIDTH_PICK/HEIGHT_PICK)
    check pickNearest(
      scene, camera, camera.drawExtentFor(HEIGHT_PICK), view_projection,
      WIDTH_PICK, HEIGHT_PICK, CENTRE
    ) == some(1)


  test "plane misses where its sight ray lands outside the drawn rim":
    # Window corner is widest angle any ray reaches, off sight axis, and.
    #   camera stands far enough back (30 units, against `EXTENT_PLANE_F` of 8) that
    #   corner ray's own diagonal reach lands well outside drawn rim's fixed
    #   radius regardless of how far back camera stands, while centre ray still
    #   lands on support point well within it.
    var scene = initScene()
    let facing = (
      toMultivector(Position(x: 0, y: -3, z: -3)) ∧
      toMultivector(Position(x: 0, y: 3, z: -3)) ∧
      toMultivector(Position(x: 0, y: 0, z: 3))
    )
    scene.addObject(facing, "facing", Ink.Olive)
    let camera = cameraFacingOrigin(distance = 30.0)
    let view_projection = camera.initMatrixViewProjection(WIDTH_PICK/HEIGHT_PICK)
    check pickNearest(
      scene, camera, camera.drawExtentFor(HEIGHT_PICK), view_projection,
      WIDTH_PICK, HEIGHT_PICK, CENTRE
    ) == some(0)
    for (label, cx, cy) in [
      ("top-left corner", 0.0, 0.0),
      ("bottom-right corner", float(WIDTH_PICK), float(HEIGHT_PICK)),
    ]:
      let cursor = ScreenPosition(x: cx, y: cy, depth: 0.0)
      check pickNearest(
        scene, camera, camera.drawExtentFor(HEIGHT_PICK), view_projection,
        WIDTH_PICK, HEIGHT_PICK, cursor
      ).isNone


  test "the disc broad phase never rejects a cursor over the disc's own sphere":
    # `isBeyondDisc` may only skip meet meet would refuse. Every point of sphere.
    #   bounding disc projects onto cursor phase must let through -- sampled over
    #   fixed grid of directions, from cameras facing and oblique to disc.
    let centre = Position(x: 1.5, y: -2.0, z: 0.5)
    for (azimuth, elevation) in [(0.0, 0.0), (0.9, 0.4), (2.4, -0.7)]:
      let camera = initCamera(
        pivot = Position(x: 0, y: 0, z: 0), distance = 30.0, azimuth = azimuth,
        elevation = elevation,
      )
      let view_projection = camera.initMatrixViewProjection(WIDTH_PICK/HEIGHT_PICK)
      let tangent = camera.drawExtentFor(HEIGHT_PICK).tangent_half_view
      for i in 0 ..< 24:
        for j in 0 .. 12:
          let (theta, phi) = (float(i)*TAU/24.0, float(j)*PI/12.0)
          let on_sphere = Position(
            x: centre.x + EXTENT_PLANE_F*sin(phi)*cos(theta),
            y: centre.y + EXTENT_PLANE_F*sin(phi)*sin(theta),
            z: centre.z + EXTENT_PLANE_F*cos(phi),
          )
          let cursor = projectToScreen(view_projection, WIDTH_PICK, HEIGHT_PICK, on_sphere)
          check not isBeyondDisc(
            view_projection, WIDTH_PICK, HEIGHT_PICK, tangent, centre, EXTENT_PLANE_F, cursor,
          )
      # And phase is not inert: window's corner is well clear of disc this far off.
      let corner = ScreenPosition(x: 0.0, y: 0.0, depth: 0.0)
      check isBeyondDisc(
        view_projection, WIDTH_PICK, HEIGHT_PICK, tangent, centre, EXTENT_PLANE_F, corner,
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
        toMultivector(Position(x: 0, y: -3*facing, z: -3)),
        toMultivector(Position(x: 0, y: 3*facing, z: -3)),
        toMultivector(Position(x: 0, y: 0, z: 3)),
      ]
      scene.addObject(corners[0] ∧ corners[1] ∧ corners[2], "spanning", Ink.Olive)
      let camera = cameraFacingOrigin()
      let view_projection = camera.initMatrixViewProjection(WIDTH_PICK/HEIGHT_PICK)
      check pickNearest(
        scene, camera, camera.drawExtentFor(HEIGHT_PICK), view_projection,
        WIDTH_PICK, HEIGHT_PICK, CENTRE,
      ) == some(0)


  test "nearer plane wins over a farther one behind it":
    # Eye sits at (10, 0, 0) looking toward origin along -x, so plane at x=6 stands.
    #   nearer eye (distance 4) than one at x=3 (distance 7).
    var scene = initScene()
    let far_plane = (
      toMultivector(Position(x: 3, y: -3, z: -3)) ∧
      toMultivector(Position(x: 3, y: 3, z: -3)) ∧
      toMultivector(Position(x: 3, y: 0, z: 3))
    )
    let near_plane = (
      toMultivector(Position(x: 6, y: -3, z: -3)) ∧
      toMultivector(Position(x: 6, y: 3, z: -3)) ∧
      toMultivector(Position(x: 6, y: 0, z: 3))
    )
    scene.addObject(far_plane, "far", Ink.Olive) # Index 0.
    scene.addObject(near_plane, "near", Ink.Cobalt) # Index 1.
    let camera = cameraFacingOrigin()
    let view_projection = camera.initMatrixViewProjection(WIDTH_PICK/HEIGHT_PICK)
    check pickNearest(
      scene, camera, camera.drawExtentFor(HEIGHT_PICK), view_projection,
      WIDTH_PICK, HEIGHT_PICK, CENTRE
    ) == some(1)
