## Run `Camera` suite: one module of shared suite, which `../suites.nim` imports in order.

import ./fixtures


suite "Camera":
  test "the motor stance places the eye and the frame where the turntable does":
    # Whole claim of stance held as rigid motion: every placement that four turntable
    #   numbers name lands where trig and joins put it before.
    #   480 cases. Separation spans five decades, azimuth spans whole turn, and elevation
    #   reaches both clamps, which is where old joins were worst conditioned.
    var count = 0
    for i_pivot in 0 .. 3:
      for distance in [0.001, 1.0, 19.0, 4000.0]:
        for i_azimuth in 0 .. 5:
          for i_elevation in 0 .. 4:
            let
              pivot = Position(
                x: -7.0 + 5.0*float(i_pivot),
                y: 2.0*float(i_pivot) - 3.0,
                z: 1.5*float(i_pivot),
              )
              azimuth = -PI + TAU*float(i_azimuth)/6.0
              elevation = -ELEVATION_LIMIT + 2.0*ELEVATION_LIMIT*float(i_elevation)/4.0
              camera = initCamera(pivot, distance, azimuth, elevation)
              radius = distance*cos(elevation)
            # Eye against spherical closed form, which is what `eye` read before.
            check camera.eye =~ Position(
              x: pivot.x + radius*cos(azimuth),
              y: pivot.y + radius*sin(azimuth),
              z: pivot.z + distance*sin(elevation),
            )
            # Three axes against what turntable's own frame is at those two angles.
            let axes = camera.frame
            check axes.axis_right =~ Direction(x: -sin(azimuth), y: cos(azimuth), z: 0.0)
            check axes.axis_up =~ Direction(
              x: -cos(azimuth)*sin(elevation),
              y: -sin(azimuth)*sin(elevation),
              z: cos(elevation),
            )
            check axes.forward =~ Direction(
              x: -cos(elevation)*cos(azimuth),
              y: -cos(elevation)*sin(azimuth),
              z: -sin(elevation),
            )
            # Pivot and separation come back out of what carried them in.
            check camera.pivot =~ pivot
            check camera.distance =~ max(distance, DISTANCE_LIMIT_NEAR)
            inc count
    check count == 480

  test "one read of the stance gives the eye, the frame and the pivot that three reads give":
    # `sight` lifts motor and takes its antireverse once for eye and frame together.
    #   `eye`, `frame` and `pivot` read apart are reference; stances rolled and steep.
    for i in 0 ..< COUNT_GENERAL:
      var camera = initCamera(
        PLACES[i], 0.5 + 3.0*float(i), -PI + 0.5*float(i), -1.2 + 0.2*float(i)
      )
      camera.roll(0.3*float(i) - 1.0)
      let (eye, frame) = camera.sight
      check eye =~ camera.eye
      check frame.axis_right =~ camera.frame.axis_right
      check frame.axis_up =~ camera.frame.axis_up
      check frame.forward =~ camera.frame.forward
      check eye + camera.distance*frame.forward =~ camera.pivot


  test "an orbit repeated many times lands where the sum of its steps says":
    # `orbit` composes motion now, so loss accumulates over steps rather than being
    #   rebuilt away. Pivot and separation must survive every one, because both axes it
    #   turns about run through pivot.
    #   Axis is camera's own up, which its own turn leaves standing, so many steps and
    #   one turn of their sum are one motion.
    const (STEPS, TURN) = (2000, 0.004)
    let pivot = Position(x: 2.0, y: -1.0, z: 0.5)
    var stepped = initCamera(pivot, 19.0, 0.3, 0.2)
    for _ in 1 .. STEPS: stepped.orbit(TURN, 0.0)
    var once = initCamera(pivot, 19.0, 0.3, 0.2)
    once.orbit(float(STEPS)*TURN, 0.0)
    check stepped.eye =~ once.eye
    check stepped.frame.forward =~ once.frame.forward
    check stepped.frame.axis_up =~ once.frame.axis_up
    check stepped.pivot =~ pivot
    check abs(stepped.distance - 19.0) < 1.0e-9
    # Roll survives orbit now, which four turntable numbers could not carry.
    var rolled = initCamera(pivot, 19.0, 0.3, 0.2)
    rolled.roll(0.6)
    let axis_up_rolled = rolled.frame.axis_up
    rolled.orbit(0.4, 0.0)
    check dot(rolled.frame.axis_up, UP_WORLD) < dot(axis_up_rolled, UP_WORLD) + TOLERANCE_TEST
    check abs(rolled.frame.axis_right.z) > TOLERANCE_TEST
    check rolled.pivot =~ pivot

  test "the flat motor and the multivector say one motion, and it is unit":
    # `Camera` holds eight floats rather than multivector, so crossing must lose nothing.
    for i in 0 ..< COUNT_GENERAL:
      let camera = initCamera(PLACES[i], 1.0 + float(i), 0.2*float(i) - 1.0, 0.1*float(i))
      let lifted = toMultivector(camera.motor)
      check motorOf(lifted) == camera.motor
      check normWeight(lifted)[Basis.scalarAnti] =~ 1.0

  test "looking turns sight about the camera's own axes, and leaves the eye standing":
    # Free flight's whole claim: orientation moves and placement does not.
    let start = initCamera(Position(x: 2.0, y: -1.0, z: 0.5), 19.0, 0.3, 0.0)
    let (eye_start, axes_start) = (start.eye, start.frame)
    # Yaw at level horizon turns azimuth by exactly what was asked, since camera's own up
    #   is world up there.
    var turned = start
    turned.look(0.4, 0.0)
    check turned.eye =~ eye_start
    check abs(turned.azimuth - 0.7) < TOLERANCE_TEST
    check abs(turned.elevation) < TOLERANCE_TEST
    check turned.distance =~ start.distance
    # Pitch leaves across axis alone, and raises reading `orbit` would raise.
    var pitched = start
    pitched.look(0.0, 0.35)
    check pitched.eye =~ eye_start
    check pitched.frame.axis_right =~ axes_start.axis_right
    check abs(pitched.elevation - 0.35) < TOLERANCE_TEST
    # Frame stays orthonormal through turn no clamp guards.
    var steep = start
    steep.look(0.0, 1.5)
    let axes_steep = steep.frame
    check abs(dot(axes_steep.axis_right, axes_steep.axis_up)) < TOLERANCE_TEST
    check abs(dot(axes_steep.axis_up, axes_steep.forward)) < TOLERANCE_TEST
    check abs(norm(axes_steep.forward) - 1.0) < TOLERANCE_TEST

  test "a look and an orbit both pass the pole that the panel's own field stops short of":
    # What rotor buys: neither verb has clamp, because neither rebuilds from angles.
    var flown = initCamera(ORIGIN, 19.0, 0.0, 0.0)
    var orbited = flown
    for _ in 1 .. 8:
      flown.look(0.0, 0.25)
      orbited.orbit(0.0, 0.25)
    # Eight quarter-radian pitches compose to exactly two radians of turn, and two radians
    #   is past straight down, where old frame's joins collapsed.
    let forward_start = initCamera(ORIGIN, 19.0, 0.0, 0.0).frame.forward
    check abs(dot(flown.frame.forward, forward_start) - cos(2.0)) < TOLERANCE_TEST
    check abs(dot(orbited.frame.forward, forward_start) - cos(2.0)) < TOLERANCE_TEST
    check flown.frame.forward.x > 0.0
    # Panel's own field does rebuild from angles, so it alone is still held short.
    let typed = initCamera(ORIGIN, 19.0, 0.0, 0.0).placedAtElevation(2.0)
    check typed.elevation =~ ELEVATION_LIMIT
    check abs(norm(flown.frame.forward) - 1.0) < TOLERANCE_TEST

  test "a look and an orbit turn sight the same way, so one drag reads the same in either":
    # One left drag feeds either verb as selection comes and goes. Signs that disagreed
    #   would reverse gesture moment reader selected something.
    let start = initCamera(ORIGIN, 19.0, 0.0, 0.0)
    for step in [0.2, -0.2]:
      var looked = start
      var orbited = start
      looked.look(step, 0.0)
      orbited.orbit(step, 0.0)
      check dot(looked.frame.forward, orbited.frame.forward) > 0.0
      check dot(looked.frame.axis_right, orbited.frame.axis_right) > 0.0
      var raised = start
      var risen = start
      raised.look(0.0, step)
      risen.orbit(0.0, step)
      check raised.elevation =~ risen.elevation

  test "roll turns about the sight axis alone, and a whole turn returns every axis":
    var camera = initCamera(Position(x: 1.0, y: 2.0, z: -0.5), 7.0, 0.8, -0.3)
    let (eye_start, axes_start) = (camera.eye, camera.frame)
    camera.roll(0.5)
    # Sight and placement stand; only two axes across it move.
    check camera.eye =~ eye_start
    check camera.frame.forward =~ axes_start.forward
    check camera.distance =~ 7.0
    # Positive roll tips up axis toward across axis, which reads as clockwise.
    check dot(camera.frame.axis_up, axes_start.axis_right) > 0.0
    # Whole turn in steps lands back on frame it started from.
    var whole = initCamera(Position(x: 1.0, y: 2.0, z: -0.5), 7.0, 0.8, -0.3)
    for _ in 1 .. 64: whole.roll(TAU/64.0)
    check whole.frame.axis_up =~ axes_start.axis_up
    check whole.frame.axis_right =~ axes_start.axis_right

  test "travel moves along the camera's own axes, whatever roll it carries":
    var camera = initCamera(Position(x: -3.0, y: 4.0, z: 2.0), 11.0, 1.2, 0.4)
    camera.roll(0.9)
    let (eye_start, axes_start) = (camera.eye, camera.frame)
    camera.travel(2.0, -0.5, 0.25)
    # Every axis stands: travel slides and never turns.
    check camera.frame.forward =~ axes_start.forward
    check camera.frame.axis_up =~ axes_start.axis_up
    # Step is exactly sum asked for, read back against rolled frame.
    let step = camera.eye - eye_start
    check abs(dot(step, axes_start.forward) - 2.0) < TOLERANCE_TEST
    check abs(dot(step, axes_start.axis_right) + 0.5) < TOLERANCE_TEST
    check abs(dot(step, axes_start.axis_up) - 0.25) < TOLERANCE_TEST
    # Forward dives where sight dives, unlike `slideGround`, which holds height.
    check abs(step.z) > TOLERANCE_TEST

  test "the speed climbs toward its cap, and never reaches it":
    const CAP = 12.0
    check speedTravelling(0.0, CAP) =~ 0.0
    var before = 0.0
    for i in 1 .. 40:
      let speed = speedTravelling(0.1*float(i), CAP)
      check speed > before
      check speed < CAP
      before = speed
    # One time constant is 63 percent of cap, three are 95 percent.
    check abs(speedTravelling(SECONDS_SPEED_RISE, CAP)/CAP - 0.6321) < 1.0e-4
    check abs(speedTravelling(3.0*SECONDS_SPEED_RISE, CAP)/CAP - 0.9502) < 1.0e-4

  test "distance travelled is the integral, so halves sum to the whole":
    # What keeps 144 Hz reader beside 60 Hz one over one hold.
    const CAP = 12.0
    check distanceTravelled(0.0, 0.0, CAP) =~ 0.0
    for span in [0.5, 1.0, 4.0]:
      var walked = 0.0
      var age = 0.0
      # Same span in 120 frames must equal same span in one.
      for _ in 1 .. 120:
        walked += distanceTravelled(age, age + span/120.0, CAP)
        age += span/120.0
      check abs(walked - distanceTravelled(0.0, span, CAP)) < TOLERANCE_TEST
    # Long hold is cap times span, less cap times one time constant of lag.
    check abs(
      distanceTravelled(0.0, 20.0, CAP) - CAP*(20.0 - SECONDS_SPEED_RISE)
    ) < 1.0e-6

  test "the speed cap is the smaller of the local scale and the ceiling":
    # Pointer over something takes that depth as its scale.
    check capTravelling(some(19.0), 999.0, 1.0) =~ FACTOR_SPEED_LOCAL*19.0
    # Pointer over empty sky falls back to camera's own scale, never to ceiling.
    #   Ceiling alone there crossed solar system in half second.
    check capTravelling(none(float), 19.0, 1.0) =~ FACTOR_SPEED_LOCAL*19.0
    # Close work is slow, so reader inside moon's orbit is not thrown across it.
    check capTravelling(some(0.001), 19.0, 1.0) =~ FACTOR_SPEED_LOCAL*0.001
    # Far work is held at ceiling rather than scaled past it.
    check capTravelling(some(1.0e9), 1.0, 1.0) =~ SPEED_CEILING
    check capTravelling(none(float), 1.0e9, 1.0) =~ SPEED_CEILING
    # Haste multiplies both figures, so shift stays one multiplier on every rate.
    check capTravelling(some(2.0), 1.0, FACTOR_HASTE) =~
      FACTOR_SPEED_LOCAL*2.0*FACTOR_HASTE
    check capTravelling(some(1.0e9), 1.0, FACTOR_HASTE) =~ SPEED_CEILING*FACTOR_HASTE
    # Depth behind eye is refused rather than freezing camera at zero.
    check capTravelling(some(-5.0), 19.0, 1.0) =~ 0.0

  test "the far clip reaches the scene's farthest object however close the orbit is":
    var camera = initCamera(Position(x: 0, y: 0, z: 0), 10.0, 0.0, 0.0)
    check abs(camera.distanceFar - 10.0*FACTOR_CLIP_FAR) < 1.0e-9
    camera.reach_scene = 3000.0
    let eye = camera.eye
    check camera.distanceFar >= norm(eye - Position(x: 0, y: 0, z: 0)) + 3000.0
    # Near stays scaled whatever far reaches: depth is logarithmic, so ratio costs nothing.
    check camera.distanceNear =~ camera.distance*FACTOR_CLIP_NEAR
    var close = initCamera(Position(x: 0, y: 0, z: 0), 0.05, 0.0, 0.0)
    close.reach_scene = 3000.0
    check close.distanceNear =~ close.distance*FACTOR_CLIP_NEAR
    check close.distanceFar/close.distanceNear > 1.0e6
    # Reach is measured from what scene holds, point's own radius included.
    var scene = initScene()
    scene.addObject(toMultivector(Position(x: 300, y: 0, z: 0)), "p", Ink.Rose, radius = 2.5)
    check abs(reachOf(scene) - 302.5) < 1.0e-6

  test "the frustum takes its scale from the nearest drawn object, not from the separation":
    # Separation alone kept scale of stance reader set off from. Near clip is one
    #   four-hundredth of it, so camera flying from opening stance at planet met that
    #   plane long before planet.
    var camera = initCamera(ORIGIN, 19.0, 0.4, 0.3)
    check camera.scaleLocal =~ 19.0
    check camera.distanceNear =~ 19.0*FACTOR_CLIP_NEAR
    # Stamped reach takes over, and near clip follows it down by four decades.
    camera.reach_near = 0.002
    check camera.scaleLocal =~ 0.002
    check camera.distanceNear =~ 0.002*FACTOR_CLIP_NEAR
    # Far clip still reaches whole scene, since scene's own reach is its other term.
    camera.reach_scene = 6.5e6
    check camera.distanceFar >= norm(camera.eye - ORIGIN) + 6.5e6
    # Depth stays logarithmic across that range, and both ends still land where they must.
    check camera.depthOf(camera.distanceNear) =~ -1.0
    check camera.depthOf(camera.distanceFar) =~ 1.0
    # Zero hands scale back, so empty scene is unchanged.
    camera.reach_near = 0.0
    check camera.scaleLocal =~ 19.0
    # Floored, since every reader scales by it.
    var floored = initCamera(ORIGIN, DISTANCE_LIMIT_NEAR, 0.0, 0.0)
    check floored.scaleLocal > 0.0

  test "the nearest reach is read ahead of the eye, and never behind it":
    var scene = initScene()
    # Camera at origin looking along -x; one object ahead, one behind, one further ahead.
    let camera = initCamera(ORIGIN, 1.0, 0.0, 0.0)
    check camera.frame.forward =~ Direction(x: -1.0, y: 0.0, z: 0.0)
    scene.addObject(toMultivector(Position(x: -4.0, y: 0.0, z: 0.0)), "ahead", Ink.Rose)
    scene.addObject(toMultivector(Position(x: 9.0, y: 0.0, z: 0.0)), "behind", Ink.Jade)
    scene.addObject(toMultivector(Position(x: -30.0, y: 0.0, z: 0.0)), "far", Ink.Cobalt)
    var placed = newSeq[Placement](scene.bound)
    for handle in 0 ..< scene.bound:
      if scene.isAlive(handle):
        placed[handle] = placeObject(
          scene.geometryOf(handle), scene.anchorOverrideAt(handle)
        )
    let eye = camera.eye
    # Nearest ahead answers, and one behind is passed over however near it stands.
    #   Eye stands one unit out at +x, so depths are five and thirty one.
    check reachNearOf(placed, scene, eye, camera.frame.forward) =~ 5.0
    # Hidden objects are not drawn, so they set no scale.
    scene.setVisible(0, false)
    check reachNearOf(placed, scene, eye, camera.frame.forward) =~ 31.0
    # Nothing ahead at all reads zero, which hands scale back to separation.
    scene.setVisible(2, false)
    check reachNearOf(placed, scene, eye, camera.frame.forward) =~ 0.0

  test "records' origin holds until travel spends float32's precision about it":
    var camera = initCamera(ORIGIN, 19.0, 0.0, 0.0)
    let eye_start = camera.eye
    # Bound is quarter of near clip, divided by float32's own step.
    let reach_hold = FRACTION_ORIGIN_HOLD*camera.distanceNear/STEP_SINGLE
    check reach_hold > 1.0e5
    check camera.originHeld(eye_start) =~ eye_start
    # Travel well inside bound keeps origin exactly where it was.
    camera.travel(0.5*reach_hold, 0.0, 0.0)
    check camera.originHeld(eye_start) =~ eye_start
    # Travel past it moves origin onto eye, once.
    camera.travel(0.6*reach_hold, 0.0, 0.0)
    let moved = camera.originHeld(eye_start)
    check moved =~ camera.eye
    check camera.originHeld(moved) =~ moved
    # Close work draws bound in with near clip, so origin follows sooner.
    camera.reach_near = 0.002
    check FRACTION_ORIGIN_HOLD*camera.distanceNear/STEP_SINGLE < reach_hold

  test "a point is culled only where the frustum, sprite margin included, does not reach":
    # Bounds are camera's own frame; what is checked is test against them.
    let camera = initCamera(Position(x: 1, y: 2, z: 3), 10.0, 0.4, 0.3)
    let scale = camera.drawExtentFor(900)
    let bounds = camera.viewBoundsFor(scale, 16.0/9.0)
    const RADIUS = RADIUS_OBJECT_DEFAULT
    check isPointInView(placeObject(toMultivector(camera.pivot)), RADIUS, bounds)
    check not isPointInView(
      placeObject(toMultivector(bounds.eye - 1.0*bounds.forward)), RADIUS, bounds
    )
    # Sideways at pivot's depth: just inside half-width stays, just outside goes.
    let reach_across = camera.distance*bounds.bound_width
    let reach_above = camera.distance*bounds.bound_height
    check isPointInView(
      placeObject(toMultivector(camera.pivot + (0.9*reach_across)*bounds.right)), RADIUS,
      bounds,
    )
    check not isPointInView(
      placeObject(toMultivector(camera.pivot + (1.1*reach_across)*bounds.right)), RADIUS,
      bounds,
    )
    check isPointInView(
      placeObject(toMultivector(camera.pivot + (0.9*reach_above)*bounds.up)), RADIUS, bounds
    )
    check not isPointInView(
      placeObject(toMultivector(camera.pivot + (1.1*reach_above)*bounds.up)), RADIUS, bounds
    )
    # Point's own radius widens margin: same centre just past edge stays once its disc.
    #   reaches back in, exactly as far as radius says.
    let just_out = placeObject(toMultivector(camera.pivot + (1.1*reach_across)*bounds.right))
    check isPointInView(just_out, 0.2*reach_across, bounds)
    check not isPointInView(just_out, 0.05*reach_across, bounds)
    # Horizon point is tested by direction alone; every other kind passes untested.
    check isPointInView(
      Placement(kind: Case.PointToward, toward: bounds.forward), RADIUS, bounds
    )
    check not isPointInView(
      Placement(kind: Case.PointToward, toward: -bounds.forward), RADIUS, bounds
    )
    check isPointInView(Placement(kind: Case.LineThrough), RADIUS, bounds)

  test "the eye assembled through the algebra is the eye the trig names":
    # `camera.eye` places point as multivector sum; spherical closed form lives.
    #   HERE. Angles are parametrization -- what is checked is placement.
    var seed = 27.0
    proc pseudo(): float =
      seed = (seed*97.31 + 33.77) mod 41.0
      seed - 20.5
    for trial in 0 ..< 100:
      let
        pivot = Position(x: pseudo(), y: pseudo(), z: pseudo())
        distance = 1.0 + abs(pseudo())
        azimuth = pseudo()/7.0
        elevation = pseudo()/20.0
        camera = initCamera(pivot, distance, azimuth, elevation)
        radius = distance*cos(camera.elevation)
        classical = pivot + Direction(
          x: radius*cos(camera.azimuth),
          y: radius*sin(camera.azimuth),
          z: distance*sin(camera.elevation),
        )
      check camera.eye =~ classical


  test "frame is orthonormal and perpendicular to sight axis":
    for i in 0 ..< SAMPLES:
      let camera = initCamera(
        pivot = PLACES[i],
        distance = 2.0 + rand(20.0),
        azimuth = rand(2.0*PI),
        elevation = rand(-1.4 .. 1.4),
      )
      let axes = camera.frame
      check norm(axes.axis_right) =~ 1.0
      check norm(axes.axis_up) =~ 1.0
      check norm(axes.forward) =~ 1.0
      check dot(axes.axis_right, axes.axis_up) =~ 0
      check dot(axes.axis_right, axes.forward) =~ 0
      check dot(axes.axis_up, axes.forward) =~ 0
      check dot(axes.axis_up, UP_WORLD) > 0


  test "eye stands at orbit distance from pivot, and looks back at it":
    for i in 0 ..< SAMPLES:
      let camera = initCamera(
        pivot = PLACES[i], distance = 7.0, azimuth = rand(2.0*PI), elevation = rand(-1.4 .. 1.4)
      )
      check norm(camera.eye - camera.pivot) =~ camera.distance
      let heading = normalize(camera.pivot - camera.eye)
      check heading.isSome
      check dot(heading.get, camera.frame.forward) =~ 1.0


  test "view transform carries eye to origin and pivot down its own negative z":
    let camera = initCamera(
      pivot = Position(x: 1, y: -2, z: 0.5), distance = 9.0, azimuth = 0.7, elevation = 0.3
    )
    let view = initMatrixView(camera.eye, camera.frame)
    let (at_eye, at_pivot) = (
      transform(view, camera.eye, 1.0), transform(view, camera.pivot, 1.0)
    )
    check isNear(at_eye[0], 0) and isNear(at_eye[1], 0) and isNear(at_eye[2], 0)
    check isNear(at_pivot[0], 0) and isNear(at_pivot[1], 0)
    check isNear(at_pivot[2], -camera.distance)


  test "projection carries near plane to -1 and every depth beyond it under far plane":
    const NEAR = 0.25
    let projection = initMatrixProjection(45.0, 1.6, NEAR)
    let at_near = transform(projection, Position(x: 0, y: 0, z: -NEAR), 1.0)
    check isNear(at_near[3], NEAR) and isNear(at_near[2]/at_near[3], -1.0)
    # No far plane: depth climbs toward `1 - SLACK_CLIP_FAR` and never reaches it.
    var below = -1.0
    for depth in [1.0, 60.0, 1.0e3, 1.0e6, 1.0e9, 1.0e12]:
      let clipped = transform(projection, Position(x: 0, y: 0, z: -depth), 1.0)
      let mapped = clipped[2]/clipped[3]
      check mapped > below and mapped < 1.0 - 0.5*SLACK_CLIP_FAR
      below = mapped


  test "nothing far clips: the farthest star and the sky dome keep a float32 margin":
    # Bug this guards: with far plane at star field's reach, `(far + near)/(far - near)`
    #   put farthest stars and dome at 0.9 of far within two float32 ulps of far plane,
    #   and Android GPU's rounding clipped them, points flickering as camera moved and
    #   dome drawn in patches. Read as GPU reads: flattened float32 matrix, row dotted
    #   in float32, at demo's reach and four orbit distances down to one unit.
    when not defined(js):
      const REACH = 268557.0
      for distance in [122.0, 36.6, 5.0, 1.0]:
        var camera = initCamera(
          pivot = Position(x: 0, y: 0, z: 0), distance = distance, azimuth = 0.4,
          elevation = 0.3,
        )
        camera.reach_scene = REACH
        let
          flat = camera.initMatrixViewProjection(1.6).flattened
          eye = camera.eye
          forward = camera.frame.forward
        for (depth, name) in [(REACH, "star"), (0.9*camera.distanceFar, "dome")]:
          let at = eye + depth*forward
          var (z, w) = (0.0'f32, 0.0'f32)
          for (column, coordinate) in [(0, at.x), (1, at.y), (2, at.z)]:
            z += flat[column*4 + 2]*float32(coordinate)
            w += flat[column*4 + 3]*float32(coordinate)
          z += flat[14]
          w += flat[15]
          check w > 0.0'f32
          check w - z > float32(0.5*SLACK_CLIP_FAR)*w


  test "whole transform carries pivot to centre of view":
    for i in 0 ..< SAMPLES:
      let camera = initCamera(
        pivot = PLACES[i], distance = 11.0, azimuth = rand(2.0*PI), elevation = rand(-1.2 .. 1.2)
      )
      let clipped = transform(camera.initMatrixViewProjection(1.6), camera.pivot, 1.0)
      check clipped[3] > 0
      check isNear(clipped[0]/clipped[3], 0)
      check isNear(clipped[1]/clipped[3], 0)


  test "a transform about an origin agrees with the world one, and keeps a far close-up":
    # Records are stored about frame's origin (`mesh.clearMeshes`) and GPU takes transform.
    #   built about same point, so position about origin lands where world transform puts
    #   world position: storing relative to pivot is invisible on screen.
    for i in 0 ..< SAMPLES:
      let camera = initCamera(
        pivot = PLACES[i], distance = 3.0, azimuth = rand(2.0*PI), elevation = rand(-1.2 .. 1.2)
      )
      let place = camera.pivot +
        Direction(x: rand(-1.0 .. 1.0), y: rand(-1.0 .. 1.0), z: rand(-1.0 .. 1.0))
      let about_world = transform(camera.initMatrixViewProjection(1.6), place, 1.0)
      let about_pivot = transform(
        camera.initMatrixViewProjection(1.6, camera.pivot), ORIGIN + (place - camera.pivot), 1.0
      )
      for k in 0 .. 3:
        check abs(about_world[k] - about_pivot[k]) <= 1.0e-9*max(1.0, abs(about_world[k]))
    # Far out is where it matters: pivot million units off and moon thousandth of unit from.
    #   it, as demo's moons are. Float32 of world position steps by sixteenth there, so
    #   moon's whole offset is lost; float32 about pivot carries what close-up needs, and
    #   double matrix keeps translation column of world transform, which picking reads,
    #   exact too.
    let far = initCamera(
      pivot = Position(x: 1.0e6, y: -2.0e6, z: 3.0e5), distance = 0.004, azimuth = 0.3,
      elevation = 0.4,
    )
    let moon = far.pivot + Direction(x: 0.001, y: 0.0, z: 0.0)
    let stored_world = Position(
      x: float(float32(moon.x)), y: float(float32(moon.y)), z: float(float32(moon.z)),
    )
    let stored_pivot = Position(
      x: float(float32(moon.x - far.pivot.x)), y: float(float32(moon.y - far.pivot.y)),
      z: float(float32(moon.z - far.pivot.z)),
    )
    # C backend alone: JS backend keeps `float32` as double, and page's typed arrays round
    #   outside suite's reach.
    when not defined(js):
      check norm(stored_world - moon) > 0.5e-3
      check norm((far.pivot + (stored_pivot - ORIGIN)) - moon) < 1.0e-9
    let seen_world = transform(far.initMatrixViewProjection(1.6), moon, 1.0)
    let seen_pivot = transform(far.initMatrixViewProjection(1.6, far.pivot), stored_pivot, 1.0)
    for k in 0 .. 1:
      check abs(seen_world[k]/seen_world[3] - seen_pivot[k]/seen_pivot[3]) < 1.0e-6


  test "the clip planes follow the orbit distance, rather than where they were built":
    # Bug this guards: pair was stored at construction and kept its value through.
    #   every dolly, so far plane sat at fixed 400 while orbit could reach 500 --
    #   dollying past it clipped whole scene away, and well before that line's own far
    #   end came back inside frame and read as stopping in mid-air. Deriving both is
    #   also what let orbit ceiling go, so this is load-bearing twice over.
    var camera = initCameraDefault()
    let (near_opened, far_opened) = (camera.distanceNear, camera.distanceFar)
    camera.dolly(4.0)
    check camera.distanceNear =~ 4.0*near_opened
    check camera.distanceFar =~ 4.0*far_opened
    # Scale together, so frustum keeps its shape and depth buffer its precision.
    #   Precision is function of far-to-near ratio, however far camera stands.
    check camera.distanceFar/camera.distanceNear =~ far_opened/near_opened


  test "depth is logarithmic, so a moon before its planet and the sky behind a star stay apart":
    # Linear depth spent nearly all of buffer inside first few orbit distances, and with.
    #   far at star field's reach whole field and sky fell into its last steps: on device
    #   with coarse depth every star past few hundred thousand units failed test and
    #   vanished from beside far star. Pinned against sixteen-bit step, coarsest buffer
    #   WebGL may hand out, at demo's own camera and at moon's.
    const STEP_SIXTEEN_BIT = 2.0/65535.0
    var camera = initCamera(pivot = ORIGIN, distance = 122.0, azimuth = 1.0, elevation = 0.95)
    camera.reach_scene = 6.5e6
    check camera.depthOf(camera.distanceNear) =~ -1.0
    check camera.depthOf(camera.distanceFar) =~ 1.0
    # Star at million units stands clear of sky dome at nine tenths of far, and of star.
    #   at fifth of its distance.
    check camera.depthOf(0.9*camera.distanceFar) - camera.depthOf(1.0e6) > STEP_SIXTEEN_BIT
    check camera.depthOf(1.0e6) - camera.depthOf(2.0e5) > STEP_SIXTEEN_BIT
    # Io before Jupiter, from where occlusion check stands: three spans out, moon one in.
    var near = initCamera(pivot = ORIGIN, distance = 0.0085, azimuth = 1.0, elevation = 0.3)
    near.reach_scene = 6.5e6
    check near.depthOf(0.0085) - near.depthOf(0.0085 - 0.0028) > STEP_SIXTEEN_BIT
    # Monotone across every decade scene spans, and clipping planes still clip.
    var last = -2.0
    for exponent in -8 .. 6:
      let depth = pow(10.0, float(exponent))
      if depth <= camera.distanceNear or depth >= camera.distanceFar: continue
      let z = camera.depthOf(depth)
      check z > last and z > -1.0 and z < 1.0
      last = z
    check camera.depthOf(0.5*camera.distanceNear) < -1.0
    check camera.depthOf(2.0*camera.distanceFar) > 1.0
    check camera.depthLogScale =~ 2.0/log2(camera.distanceFar/camera.distanceNear)


  test "an orbit distance has a floor and no ceiling":
    # Floor is geometry: at zero eye coincides with its pivot and every direction.
    #   derived from line joining them collapses. Ceiling was round number, and
    #   reader who dollied out to look at something kilometre across simply stopped.
    check distanceHeld(0.0) =~ DISTANCE_LIMIT_NEAR
    check distanceHeld(-5.0) =~ DISTANCE_LIMIT_NEAR
    for distance in [1.0, 500.0, 5_000.0, 1.0e6]:
      check distanceHeld(distance) =~ distance
      check initCamera(ORIGIN, distance, 0.7, 0.3).distance =~ distance

    # Holding dolly out walks straight past where limit used to sit.
    var camera = initCameraDefault()
    for _ in 1 .. 6: camera.dolly(FACTOR_DOLLY_SECOND)
    check camera.distance > 5_000.0


  test "the camera still derives a frame and a transform a thousand kilometres out":
    # Nothing downstream of distance has ceiling of its own: both clip planes are.
    #   fractions of it, so frustum keeps its shape however far eye stands.
    let camera = initCamera(pivot = ORIGIN, distance = 1.0e6, azimuth = 0.9, elevation = 0.4)
    check camera.distance =~ 1.0e6
    let axes = camera.frame
    check isNear(norm(axes.axis_right), 1.0)
    check isNear(norm(axes.axis_up), 1.0)
    check isNear(norm(axes.forward), 1.0)
    check camera.distanceNear > 0.0
    check camera.distanceFar > camera.distanceNear
    let clipped = transform(camera.initMatrixViewProjection(1.6), camera.pivot, 1.0)
    check clipped[3] > 0
    check isNear(clipped[0]/clipped[3], 0)
    check isNear(clipped[1]/clipped[3], 0)


  test "a zoom aimed at the cursor keeps what is under it under it":
    # Map reading of wheel: reader points at something and arrives there, rather.
    #   than zooming at middle of frame and panning afterwards. Checked where it
    #   has to hold -- in pixels, against transform frame is actually drawn with.
    const (WIDTH_ZOOM, HEIGHT_ZOOM) = (1440, 900)
    for cursor in [
      ScreenPosition(x: 200.0, y: 700.0), ScreenPosition(x: 1300.0, y: 120.0),
      ScreenPosition(x: 720.0, y: 450.0),
    ]:
      for factor in [0.5, 2.0]:
        var camera = initCameraDefault()
        let anchor = positionUnderCursor(camera, WIDTH_ZOOM, HEIGHT_ZOOM, cursor)
        check anchor.isSome
        let before = projectToScreen(
          camera.initMatrixViewProjection(float(WIDTH_ZOOM)/float(HEIGHT_ZOOM)),
          WIDTH_ZOOM, HEIGHT_ZOOM, anchor.get,
        )
        camera.dollyToward(factor, anchor.get)
        let after = projectToScreen(
          camera.initMatrixViewProjection(float(WIDTH_ZOOM)/float(HEIGHT_ZOOM)),
          WIDTH_ZOOM, HEIGHT_ZOOM, anchor.get,
        )
        check after.isInFront
        check abs(after.x - before.x) <= 0.5 # Half pixel: what reader could not see.
        check abs(after.y - before.y) <= 0.5
        check camera.distance =~ 19.0*factor
        # Angles are what keep anchor on its own ray; zoom must not turn.
        check camera.azimuth =~ initCameraDefault().azimuth
        check camera.elevation =~ initCameraDefault().elevation


  test "zooming in and back out returns the camera exactly where it stood":
    # Wheel notch each way has to be round trip, or reader who overshoots and corrects.
    #   ends up somewhere they never chose -- and aimed zoom moves pivot as well as
    #   distance, so there is more to come back to than there used to be.
    var camera = initCameraDefault()
    let opening = camera
    let anchor = positionUnderCursor(camera, 1440, 900, ScreenPosition(x: 300.0, y: 640.0))
    check anchor.isSome
    camera.dollyToward(0.5, anchor.get)
    check not (camera.pivot =~ opening.pivot) # It really did move view, not just in.
    camera.dollyToward(2.0, anchor.get)
    check camera.pivot =~ opening.pivot
    check camera.distance =~ opening.distance


  test "a zoom with nothing under the cursor falls back to zooming at the middle":
    # Over sky there is no object, no ground ahead and no level to meet, so there is.
    #   no point to aim at. Answer is plain dolly wheel did before any of this,
    #   not refusal to zoom.
    var
      interaction = Interaction(is_enabled: true)
      camera = initCamera(pivot = ORIGIN, distance = 12.0, azimuth = 0.5, elevation = 0.05)
      scene = initScene()
    let cursor = ScreenPosition(x: 720.0, y: 60.0) # High in frame, from camera barely
      # above level it is looking at:
      #   that ray tilts up into sky and comes back down to neither ground nor pivot's own level.
    check positionUnderCursor(camera, 1440, 900, cursor).isNone
    check positionOnGround(camera, 1440, 900, cursor).isNone
    interaction.updateCursor(cursor.x, cursor.y)
    interaction.dollyAtCursor(
      camera, scene, 2.0, camera.drawExtentFor(900),
      camera.initMatrixViewProjection(1440.0/900.0), 1440, 900, has_selection = true,
    )
    check camera.distance =~ 24.0
    check camera.pivot =~ ORIGIN


  test "with no selection the wheel travels the pointer's own ray":
    # Free flight has no pivot to dolly about, so wheel carries eye along ray under
    #   pointer, whether or not anything stands there.
    const (WIDE, TALL) = (1440, 900)
    let cursor = ScreenPosition(x: 260.0, y: 720.0)
    var camera = initCamera(pivot = ORIGIN, distance = 12.0, azimuth = 0.5, elevation = 0.3)
    let (eye_start, axes_start) = (camera.eye, camera.frame)
    let heading = headingThrough(camera, axes_start, WIDE, TALL, cursor)
    var interaction = Interaction(is_enabled: true)
    interaction.updateCursor(cursor.x, cursor.y)
    interaction.dollyAtCursor(
      camera, initScene(), 0.5, camera.drawExtentFor(TALL),
      camera.initMatrixViewProjection(float(WIDE)/float(TALL)), WIDE, TALL,
      has_selection = false,
    )
    # Step lies along that ray, and not along sight: cursor is well off middle.
    let step = camera.eye - eye_start
    check dot(step, (1.0/norm(heading))*heading) =~ norm(step)
    check dot(step, axes_start.forward) < norm(step)
    # Scale halves with factor, as it does under turntable's own dolly.
    check camera.distance =~ 6.0
    # Nothing turned: wheel travels and never turns.
    check camera.frame.forward =~ axes_start.forward

  test "the wheel comes in to what the pointer is over, and stops at its surface":
    const (WIDE, TALL) = (1440, 900)
    let planet = Position(x: 3.0, y: 1.0, z: 0.0)
    var scene = initScene()
    scene.addObject(toMultivector(planet), "planet", Ink.Cobalt)
    let radius = scene.radiusAt(0)
    check radius > 0.0
    # Camera aimed straight at it, so middle of frame is over it.
    var camera = initCamera(pivot = planet, distance = 20.0, azimuth = 0.4, elevation = 0.5)
    let cursor = ScreenPosition(x: float(WIDE)/2.0, y: float(TALL)/2.0)
    var interaction = Interaction(is_enabled: true)
    interaction.updateCursor(cursor.x, cursor.y)
    # What is under pointer keeps its pixel through notch.
    let before = projectToScreen(
      camera.initMatrixViewProjection(float(WIDE)/float(TALL)), WIDE, TALL, planet,
    )
    interaction.dollyAtCursor(
      camera, scene, 0.5, camera.drawExtentFor(TALL),
      camera.initMatrixViewProjection(float(WIDE)/float(TALL)), WIDE, TALL,
      has_selection = false,
    )
    let after = projectToScreen(
      camera.initMatrixViewProjection(float(WIDE)/float(TALL)), WIDE, TALL, planet,
    )
    check after.isInFront
    check abs(after.x - before.x) <= 0.5
    check abs(after.y - before.y) <= 0.5
    check norm(camera.eye - planet) =~ 10.0
    # Notch after notch stops at object's own drawn radius, rather than passing through.
    for _ in 1 .. 40:
      interaction.dollyAtCursor(
        camera, scene, 0.5, camera.drawExtentFor(TALL),
        camera.initMatrixViewProjection(float(WIDE)/float(TALL)), WIDE, TALL,
        has_selection = false,
      )
    check norm(camera.eye - planet) =~ radius
    # Floor never pushes eye out again, however many notches follow.
    check dot(camera.eye - planet, camera.frame.forward) < 0.0

  test "a zoom onto a point brings the pivot to its depth, and onto ground or level does not":
    # Turntable follows what reader looks at: eye carried up to planet while pivot.
    #   stayed far behind left every orbit swinging planet across frame. Ground and
    #   level are fallbacks, and following either drifted pivot's height with every
    #   notch and moved it where pan and slide expect it held.
    const (WIDE, TALL) = (1440, 900)
    let planet = Position(x: 3.0, y: 1.0, z: 0.0)
    var scene = initScene()
    scene.addObject(toMultivector(planet), "planet", Ink.Cobalt)
    # Middle of frame over planet, camera aimed at it from afar: pinch's case.
    var camera = initCamera(pivot = planet, distance = 20.0, azimuth = 0.4, elevation = 0.5)
    camera = camera.placedAtPivot(Position(x: 3.0, y: 1.0, z: 0.0) + 10.0*camera.frame.forward)
    camera = camera.placedAtDistance(30.0) # Eye where it was, pivot ten units past planet.
    let eye_before = camera.eye
    dollyAtCentre(
      camera, scene, 0.5, camera.drawExtentFor(TALL),
      camera.initMatrixViewProjection(float(WIDE)/float(TALL)), WIDE, TALL,
      has_selection = true,
    )
    # Eye moved halfway to planet, and pivot now stands on it.
    check camera.pivot =~ planet
    check abs(camera.distance - 10.0) < 1.0e-6
    check camera.eye =~ (planet + 0.5*(eye_before - planet))
    # Over empty sky, level answers and pivot keeps its height: distance scales alone.
    var level = initCamera(pivot = ORIGIN, distance = 12.0, azimuth = 0.5, elevation = 0.05)
    var interaction = Interaction(is_enabled: true)
    interaction.updateCursor(720.0, 200.0)
    dollyAt(
      level, initScene(), 0.5, level.drawExtentFor(TALL),
      level.initMatrixViewProjection(float(WIDE)/float(TALL)), WIDE, TALL,
      ScreenPosition(x: 720.0, y: 200.0), has_selection = true,
    )
    check abs(level.distance - 6.0) < 1.0e-6
    check abs(level.pivot.z) < 1.0e-6
    # Over ground below raised pivot, ground answers and pivot slides halfway toward.
    #   it by map rule alone, not to ground's depth along sight line.
    var over_ground = initCamera(
      pivot = Position(x: 0.0, y: 0.0, z: 1.0), distance = 12.0, azimuth = 0.5,
      elevation = 0.5,
    )
    let under = ScreenPosition(x: 720.0, y: 700.0)
    check positionOnGround(over_ground, WIDE, TALL, under).isSome
    dollyAt(
      over_ground, initScene(), 0.5, over_ground.drawExtentFor(TALL),
      over_ground.initMatrixViewProjection(float(WIDE)/float(TALL)), WIDE, TALL, under,
      has_selection = true,
    )
    check abs(over_ground.distance - 6.0) < 1.0e-6
    check abs(over_ground.pivot.z - 0.5) < 1.0e-6


  test "a zoom aims at the object under the cursor, then the ground, then the level":
    # Order is rule: reader pointing at object means that object, at depth.
    #   it actually stands at. Anchored on plane through pivot instead, zoom crept
    #   past or short of it and what was under cursor slid away as wheel turned.
    const (WIDE, TALL) = (1440, 900)
    let
      camera = initCamera(pivot = ORIGIN, distance = 20.0, azimuth = 0.4, elevation = 0.5)
      view_projection = camera.initMatrixViewProjection(float(WIDE)/float(TALL))
      # Point standing well above ground, so aiming at *it* and aiming at ground.
      #   under cursor are different answers and test can tell them apart.
      raised = Position(x: 2.0, y: -1.0, z: 6.0)
      on_screen = projectToScreen(view_projection, WIDE, TALL, raised)
    var scene = initScene()
    scene.addObject(toMultivector(raised), "raised", inkCycled(0))

    # Over point: its own place, not ground below it nor pivot's level.
    let at_object = anchorZoomAt(
      scene, camera, camera.drawExtentFor(TALL), view_projection, WIDE, TALL,
      ScreenPosition(x: on_screen.x, y: on_screen.y),
    )
    check at_object.isSome
    check at_object.get.at =~ raised
    check at_object.get.is_standing

    # Cursor little off it falls through to ground, which is `z = 0` itself rather.
    #   than level pivot happens to sit on. Lower in frame, where ground stands within
    #   `FACTOR_ANCHOR_DEPTH` of orbit distance.
    var camera_raised = camera
    camera_raised = camera_raised.placedAtPivot(Position(x: 0.0, y: 0.0, z: 5.0))
    let
      elsewhere = ScreenPosition(x: on_screen.x + 200.0, y: on_screen.y + 400.0)
      at_ground = anchorZoomAt(
        scene, camera_raised, camera_raised.drawExtentFor(TALL),
        camera_raised.initMatrixViewProjection(float(WIDE)/float(TALL)),
        WIDE, TALL, elsewhere,
      )
    check at_ground.isSome
    check abs(at_ground.get.at.z) <= 1.0e-6
    check not at_ground.get.is_standing
    # Cursor toward horizon finds ground too far to zoom toward, and takes level.
    #   through pivot instead: zoom aimed there flew camera off across ground.
    let
      toward_horizon = ScreenPosition(x: on_screen.x + 200.0, y: on_screen.y + 60.0)
      at_level = anchorZoomAt(
        scene, camera_raised, camera_raised.drawExtentFor(TALL),
        camera_raised.initMatrixViewProjection(float(WIDE)/float(TALL)),
        WIDE, TALL, toward_horizon,
      )
    check at_level.isSome
    check abs(at_level.get.at.z - 5.0) <= 1.0e-6
    check not at_level.get.is_standing
    # And it is ground *cursor* is over, not ground below eye.
    check at_ground.get.at =~ positionOnGround(camera_raised, WIDE, TALL, elsewhere).get

    # Cursor whose ray reaches no ground still meets level through pivot, which.
    #   is last answer rather than first.
    let
      level = initCamera(pivot = ORIGIN, distance = 12.0, azimuth = 0.5, elevation = -0.4)
      upward = ScreenPosition(x: 720.0, y: 40.0)
    if positionOnGround(level, WIDE, TALL, upward).isNone:
      let at_level = anchorZoomAt(
        initScene(), level, level.drawExtentFor(TALL),
        level.initMatrixViewProjection(float(WIDE)/float(TALL)),
        WIDE, TALL, upward,
      )
      let at_pivot = positionUnderCursor(level, WIDE, TALL, upward)
      check at_level.isSome == at_pivot.isSome
      if at_level.isSome: check at_level.get.at =~ at_pivot.get

    # Plane under cursor is crossing, not place: anchored where ray meets it, but not.
    #   followed to depth, which is not plane's depth at middle of frame.
    var scene_floor = initScene()
    scene_floor.addObject(
      planeThrough(toMultivector(ORIGIN), toMultivector(Direction(x: 0, y: 0, z: 1))),
      "floor", inkCycled(1),
    )
    let at_plane = anchorZoomAt(
      scene_floor, camera_raised, camera_raised.drawExtentFor(TALL),
      camera_raised.initMatrixViewProjection(float(WIDE)/float(TALL)),
      WIDE, TALL, elsewhere,
    )
    check at_plane.isSome
    check abs(at_plane.get.at.z) <= 1.0e-6
    check not at_plane.get.is_standing


  test "a line is aimed at where the cursor crosses it, not at its stored support":
    # Cursor is ray and line is line, so in three dimensions two miss.
    #   point of line nearest ray is only answer both on line and under
    #   cursor, and it moves along line as cursor slides down it.
    let
      anchor = Position(x: 0.0, y: 0.0, z: 0.0)
      axis = Direction(x: 1.0, y: 0.0, z: 0.0)
      # Ray crossing that line from above, four units along it.
      found = positionOnLineNearest(
        anchor, axis, Position(x: 4.0, y: 0.0, z: 3.0), Direction(x: 0, y: 0, z: -1),
      )
    check found.isSome
    check found.get =~ Position(x: 4.0, y: 0.0, z: 0.0)
    # Ray running along line has whole direction of nearest points, not one.
    check positionOnLineNearest(
      anchor, axis, Position(x: 0.0, y: 1.0, z: 0.0), axis
    ).isNone


  test "the algebra's nearest point on a line agrees with the closed form":
    # `positionOnLineNearest` answers through joins and meet; classical two-dot.
    #   closed form lives HERE, in test -- checking algebra against it is
    #   project's purpose. Deterministic scatter of line/ray pairs, comfortably away
    #   from parallel, so failure names same pair on every run.
    var seed = 9.0
    proc pseudo(): float =
      seed = (seed*97.31 + 33.77) mod 41.0
      seed - 20.5
    proc someway(): Direction =
      var d = Direction(x: 0, y: 0, z: 0)
      while norm(d) < 0.1: d = Direction(x: pseudo(), y: pseudo(), z: pseudo())
      normalize(d).get
    for trial in 0 ..< 100:
      let
        anchor = Position(x: pseudo(), y: pseudo(), z: pseudo())
        axis = someway()
        ray_from = Position(x: pseudo(), y: pseudo(), z: pseudo())
        ray_along = someway()
        between = anchor - ray_from
        along_both = dot(axis, ray_along)
        denominator = 1.0 - along_both*along_both
      if abs(denominator) <= 1.0e-3: continue # Near-parallel pair proves nothing here.
      let
        step = (along_both*dot(ray_along, between) - dot(axis, between))/denominator
        classical = anchor + step*axis
        answered = positionOnLineNearest(anchor, axis, ray_from, ray_along)
      check answered.isSome
      if answered.isSome:
        check answered.get =~ classical


  test "the algebra's near clip agrees with the componentwise clip":
    # `clipToEyeSide` clips by plane depths and meet; componentwise interpolation.
    #   -- very formula `mesh.addSegment`'s boundary packing still performs -- lives
    #   HERE as reference, which also pins two clips to each other so
    #   deliberate boundary asymmetry cannot drift.
    var seed = 17.0
    proc pseudo(): float =
      seed = (seed*97.31 + 33.77) mod 41.0
      seed - 20.5
    proc someway(): Direction =
      var d = Direction(x: 0, y: 0, z: 0)
      while norm(d) < 0.1: d = Direction(x: pseudo(), y: pseudo(), z: pseudo())
      normalize(d).get
    for trial in 0 ..< 100:
      let
        tail = Position(x: pseudo(), y: pseudo(), z: pseudo())
        head = Position(x: pseudo(), y: pseudo(), z: pseudo())
        eye = Position(x: pseudo(), y: pseudo(), z: pseudo())
        forward = someway()
        near = 0.05 + abs(pseudo())/10.0
        plane_near = planeThrough(
          add(toMultivector(eye), wedge(near, toMultivector(forward))),
          toMultivector(forward),
        )
        answered = clipToEyeSide(tail, head, plane_near)
        # Componentwise reference, exactly as boundary's own packing clips.
        depth_tail = dot(tail - eye, forward)
        depth_head = dot(head - eye, forward)
      if depth_tail <= near and depth_head <= near:
        check answered.isNone
        continue
      check answered.isSome
      if answered.isNone: continue
      var (expected_tail, expected_head) = (tail, head)
      if depth_tail <= near:
        expected_tail =
          tail + ((near - depth_tail)/(depth_head - depth_tail))*(head - tail)
      elif depth_head <= near:
        expected_head =
          head + ((near - depth_head)/(depth_tail - depth_head))*(tail - head)
      check answered.get[0] =~ expected_tail
      check answered.get[1] =~ expected_head


  test "a right drag strafes along the camera's own axes in free flight":
    # Grab of level under pointer stood here, and camera stands on no plane now, so there
    #   was nothing left to take hold of. Rate was already this verb's fallback wherever
    #   that ray missed.
    const (WIDE, TALL) = (1440, 900)
    var camera = initCamera(
      pivot = Position(x: 0, y: 0, z: 1), distance = 19.0, azimuth = 1.05,
      elevation = 0.42,
    )
    let (eye_start, axes) = (camera.eye, camera.frame)
    let
      before = ScreenPosition(x: 700.0, y: 560.0)
      after = ScreenPosition(x: 940.0, y: 660.0)
    camera.panAcross(before, after, WIDE, TALL, has_selection = false)
    # Step lies wholly in plane of camera's own across and up: sight gains nothing.
    let step = camera.eye - eye_start
    check abs(dot(step, axes.forward)) < TOLERANCE_TEST
    # Drag right carries eye left, so what is under pointer travels with it.
    check dot(step, axes.axis_right) < 0.0
    # Drag down carries eye up, on same reading.
    check dot(step, axes.axis_up) > 0.0
    # Scaled by separation, and nothing turns.
    check abs(dot(step, axes.axis_right)) =~ FRACTION_PAN_PIXEL*19.0*240.0
    check camera.frame.forward =~ axes.forward
    check camera.distance =~ 19.0

  test "a right drag with a selection zooms down the frame and orbits across it":
    const (WIDE, TALL) = (1440, 900)
    let opening = initCamera(ORIGIN, 19.0, 1.05, 0.42)
    # Vertical alone zooms, and leaves sight where it was.
    var zoomed = opening
    zoomed.panAcross(
      ScreenPosition(x: 700.0, y: 500.0), ScreenPosition(x: 700.0, y: 600.0),
      WIDE, TALL, has_selection = true,
    )
    check zoomed.distance =~ 19.0*pow(FACTOR_DOLLY_PIXEL, 100.0)
    check zoomed.distance > 19.0
    check zoomed.frame.forward =~ opening.frame.forward
    check zoomed.pivot =~ opening.pivot
    # Drag up zooms in, and drag out and back returns exactly.
    var returned = zoomed
    returned.panAcross(
      ScreenPosition(x: 700.0, y: 600.0), ScreenPosition(x: 700.0, y: 500.0),
      WIDE, TALL, has_selection = true,
    )
    check returned.distance =~ 19.0
    # Horizontal alone orbits, leaving pivot and separation alone.
    var orbited = opening
    orbited.panAcross(
      ScreenPosition(x: 700.0, y: 500.0), ScreenPosition(x: 940.0, y: 500.0),
      WIDE, TALL, has_selection = true,
    )
    check orbited.pivot =~ opening.pivot
    check orbited.distance =~ 19.0
    # Sight swept exactly what pixels asked for, since frame is orthonormal.
    let swung = arccos(
      clamp(dot(orbited.frame.forward, opening.frame.forward), -1.0, 1.0)
    )
    check swung =~ SPEED_ORBIT_PIXEL*240.0

  test "an aimed zoom draws the pivot toward what it aimed at":
    # `dollyToward` scales pivot toward anchor by exactly factor distance.
    #   took, which is whole of why aimed zoom settles orbit centre onto what
    #   reader is zooming into. Aimed at ground, pivot comes down onto it
    #   rather than staying stranded on level it started at -- driven in shipped
    #   browser, eight notches over ground carried it from z 1.00 to 0.32, where before
    #   this it held at 1.00 however far in reader went.
    var camera = initCamera(
      pivot = Position(x: 0, y: 0, z: 4), distance = 20.0, azimuth = 0.3, elevation = 0.5
    )
    let
      opening = camera
      anchor = Position(x: 3.0, y: -2.0, z: 0.0)
    camera.dollyToward(0.5, anchor)
    let scale = camera.distance/opening.distance
    check camera.pivot =~ anchor + scale*(opening.pivot - anchor)
    check camera.pivot.z < opening.pivot.z
    # And back out along same line, so reader who overshoots loses nothing.
    camera.dollyToward(1.0/scale, anchor)
    check camera.pivot =~ opening.pivot
    check camera.distance =~ opening.distance


  test "an aimed zoom is held off the near floor, and stays a placement while it is":
    # `dollyToward` reads back what `distanceHeld` allowed rather than assuming its own.
    #   factor took, so zoom stopped by floor still describes where eye is.
    var camera = initCamera(pivot = ORIGIN, distance = 0.1, azimuth = 0.4, elevation = 0.5)
    let anchor = positionUnderCursor(camera, 1440, 900, ScreenPosition(x: 400.0, y: 600.0))
    check anchor.isSome
    # Factor far past floor, which is tiny; see `DISTANCE_LIMIT_NEAR`.
    camera.dollyToward(1.0e-12, anchor.get)
    check camera.distance =~ DISTANCE_LIMIT_NEAR
    check norm(camera.eye - camera.pivot) =~ camera.distance


  test "framing a selection wider than the old ceiling pulls back past it":
    # `distanceFitting` used to be clamped to same 500, so anything larger than.
    #   frame could hold at that distance was framed by giving up rather than by moving.
    let camera = initCamera(pivot = ORIGIN, distance = 19.0, azimuth = 1.0, elevation = 0.4)
    check distanceFitting(4_000.0, camera, 1440, 900, 0.0) > 500.0
