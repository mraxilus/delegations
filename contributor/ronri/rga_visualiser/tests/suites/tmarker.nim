## Run `Marker` suite: one module of shared suite, which `../suites.nim` imports in order.

import ./fixtures
# Opened with `{.all.}`, so suite checks private helper directly: `directionAcross` is whole of
#   why line's rails converge, worth asserting on its own terms rather than only through
#   markers it ends up shaping.
import ../../src/rga_visualiser/marker {.all.}


suite "Marker":
  const (WIDTH_MARK, HEIGHT_MARK) = (800, 600)
  const STEP_GLIDE = 0.005
    ## Bearing between samples of glide law: 1257 in each orbit.
    ##   Coarse enough to run in seconds on JS; fine enough that line's push turns through
    ##   third of what its law allows in one step, and plane's sampled top still hops.

  func outToward(bearing, rise: float): Direction =
    ## Name direction from origin out to eye: `bearing` round world up, `rise` over unit run.
    Direction(x: cos(bearing), y: sin(bearing), z: rise)

  proc setUpAt(
    out_to: Direction, distance: float
  ): (Camera, Matrix4, DrawExtent) =
    ## Build camera looking at origin from one placement, with transform and extent frame carries.
    ##   Orientation is parameter because marker's own worst case can lie along it:
    ##   line's rails flared threefold at one bearing while reading true at another, and
    ##   round that shipped that swept distance alone.
    let placement = cameraAround(ORIGIN, distance, out_to)
    let scale = placement.drawExtentFor(HEIGHT_MARK, 0.0)
    (placement, placement.initMatrixViewProjection(WIDTH_MARK/HEIGHT_MARK), scale)

  proc setUp(distance = 19.0): (Camera, Matrix4, DrawExtent) =
    ## Hold placement most of these cases read, at one orientation they were written against.
    setUpAt(outToward(0.9, 0.42), distance)

  proc shapedMarkerFor(
    geometry: Multivector; anchor: Option[Position]; scale: DrawExtent;
    placement: Camera; view_projection: Matrix4; width, height: int;
    progress: float = 1.0; is_touch: bool = false; travel: Option[float] = none(float);
    swell: float = 0.0
  ): Option[Marker] =
    ## Wrap `markerFor`'s fill-in-place shape as option, for suite's own reading.
    ##   Cases here read one answer many times over, and clarity outranks copy option
    ##   costs in test.
    var marker: Marker
    if markerFor(
      geometry, anchor, RADIUS_OBJECT_DEFAULT, scale, placement, view_projection, width, height,
      marker, progress, is_touch, travel, swell,
    ): some(marker)
    else: none(Marker)

  proc markerOf(
    geometry: Multivector, anchor = none(Position), progress = 1.0,
    travel = none(float), distance = 19.0
  ): Option[Marker] =
    let (placement, view_projection, scale) = setUp(distance)
    shapedMarkerFor(
      geometry, anchor, scale, placement, view_projection, WIDTH_MARK, HEIGHT_MARK,
      progress, is_touch = false, travel = travel,
    )

  func apartRails(marker: Marker): float =
    ## Measure widest two rails read apart anywhere along them, in screen pixels.
    ##   Perpendicular distance from one rail's own points to infinite line through
    ##   other's, sampled along both.
    ##   Never distance between two rails' drawn endpoints: `fractionLeavingView` cuts at
    ##   its own fraction per rail, so those endpoints are not at same place along line
    ##   and distance between them measures nothing.
    # Segments arrive side 0's two halves then side 1's; each side's halves share support.
    #   and run opposite ways, so either half's own line carries whole rail.
    if marker.count_segment < 4: return 0.0
    for (own, other) in [(0, 2), (1, 3), (2, 0), (3, 1)]:
      for step in 0 .. 2:
        let along = marker.segments[own][0].towards(
          marker.segments[own][1], float(step)/2.0
        )
        result = max(
          result,
          awayFromScreen(along, marker.segments[other][0], marker.segments[other][1]),
        )

  proc reachRails(marker: Marker): float =
    ## Sum screen length of every rail piece, which is what filling hold grows.
    for i in 0 ..< marker.count_segment:
      let piece = marker.segments[i]
      result += hypot(piece[1].x - piece[0].x, piece[1].y - piece[0].y)

  proc radiusLoop(marker: Marker): float =
    ## Measure greatest screen distance between two of loop's own points.
    ##   Stands in for its radius without needing centre it was built around.
    for i in 0 ..< marker.count_point:
      for j in i + 1 ..< marker.count_point:
        result = max(result, hypot(
          marker.points[j].x - marker.points[i].x, marker.points[j].y - marker.points[i].y
        ))

  let
    POINT_A = toMultivector(Position(x: 1.0, y: 0.0, z: 2.0))
    POINT_B = toMultivector(Position(x: 4.0, y: 1.0, z: 2.0))
    POINT_C = toMultivector(Position(x: 2.0, y: 5.0, z: 3.5))
    LINE = POINT_A ∧ POINT_B
    PLANE = POINT_A ∧ POINT_B ∧ POINT_C
    LINE_HORIZON = attitude(PLANE)
      ## Take plane's own attitude: pencil of directions it spans, lying in horizon.
    PLANE_HORIZON = attitude(
      toMultivector(Position(x: 0.0, y: 0.0, z: 0.0)) ∧ PLANE
    ) ## Whole sky, built way `storyboard`'s own step 11 builds it, as attitude.
      ## of grade-4 volume, which needs point genuinely *off* plane or wedge
      ## vanishes and there is no volume to take attitude of.

  test "each shape asks for the outline that echoes it":
    check markerOf(POINT_A).get.kind == MarkerKind.Ring
    check markerOf(LINE).get.kind == MarkerKind.Rails
    check markerOf(PLANE).get.kind == MarkerKind.Loop


  test "a point's ring clears the drawn point by the shared gap":
    # Ring hugs disc as drawn: point's world radius in pixels at its depth, or least.
    #   on-screen radius where that is larger, then shared gap.
    let (placement, view_projection, scale) = setUp(19.0)
    discard placement
    discard view_projection
    let marker = markerOf(POINT_A).get
    let anchor = anchorFor(POINT_A, scale).get
    check marker.radius =~
      radiusPixelsAt(RADIUS_OBJECT_DEFAULT, anchor, scale.scale) + GAP_MARKER
    check marker.radius > 0.5*float(DIAMETER_POINT_LEAST) + GAP_MARKER
    # Far point falls to least radius; huge one grows with its own.
    let (stance_far, view_projection_far, scale_far) = setUp(1900.0)
    var ring_far: Marker
    check markerFor(
      POINT_A, none(Position), RADIUS_OBJECT_DEFAULT, scale_far, stance_far,
      view_projection_far, WIDTH_MARK, HEIGHT_MARK, ring_far,
    )
    check ring_far.radius =~ 0.5*float(DIAMETER_POINT_LEAST) + GAP_MARKER
    var ring_huge: Marker
    check markerFor(
      POINT_A, none(Position), 100.0*RADIUS_OBJECT_DEFAULT, scale, placement,
      view_projection, WIDTH_MARK, HEIGHT_MARK, ring_huge,
    )
    check ring_huge.radius > 10.0*marker.radius


  const TOLERANCE_PIXEL_TILT = 0.25
    ## Measure what `directionAcross`'s own tilt out of projection plane is worth, in pixels.

  test "a line's rails hold their own gap, at every orientation":
    # Case previous two rounds needed and did not have. World offset hands.
    #   *rate* of convergence to perspective, and along half of line whose far point
    #   lies behind eye that is not convergence but flare -- measured at 45.6 px
    #   against stated 14.5. Ceiling that was tried against it capped gap at
    #   support only, and table that justified it swept camera *distance* at one
    #   orientation, which is one axis flare does not lie along.
    #   So this sweeps orientation, and asserts bound everywhere along rails
    #   rather than at one point on them. `OFFSET_MARKER_RAIL` is now ceiling on what
    #   reader ever sees rather than gap at support, so this is assertion
    #   that constant is defined by rather than one it happens to satisfy.
    for bearing in [0.2, 0.6, 1.6, 2.4, 4.0]:
      for rise in [0.05, 0.42, 1.26]:
        for distance in [8.0, 19.0, 30.0]:
          let (placement, view_projection, scale) =
            setUpAt(outToward(bearing, rise), distance)
          let marker = shapedMarkerFor(
            LINE, none(Position), scale, placement, view_projection, WIDTH_MARK,
            HEIGHT_MARK, progress = 1.0, is_touch = false, travel = none(float),
          )
          if marker.isNone: continue
          # Two-sided, which is whole property: pair reads its stated gap at its.
          #   widest -- never more, whatever perspective would have made of fixed world
          #   offset, and never so much less that marker stops saying anything. Over
          #   this sweep widest reading spans 14.2 to 14.5 px against stated 14.5.
          #   Quarter pixel of slack above, not `TOLERANCE_SINGLE`: stepping
          #   perpendicular to sight ray tilts hair out of plane perspective
          #   divides by -- see `marker.directionAcross`.
          let apart = apartRails(marker.get)
          check apart <= 2.0*OFFSET_MARKER_RAIL + TOLERANCE_PIXEL_TILT
          check apart >= 0.95*2.0*OFFSET_MARKER_RAIL


  test "a rail is one straight line, not two halves meeting at an angle":
    # Case that would have caught round that bought flat gap by offsetting rail's.
    #   two halves differently: measured on that build, one rail turned 2.66 degrees at its
    #   support and far end of one half strayed 7.3 px -- whole gap -- from
    #   straight continuation of other. It was invisible at one camera shots
    #   were taken from and obvious at another, so this sweeps orientation too.
    #   Straight is structural rather than lucky: rail's two halves run from one offset
    #   support to two vanishing points line shares with it, so they are two parts
    #   of one world line.
    for bearing in [0.2, 0.6, 1.6, 2.4, 4.0]:
      for rise in [0.05, 0.42, 1.26]:
        let (placement, view_projection, scale) = setUpAt(outToward(bearing, rise), 19.0)
        let marker = shapedMarkerFor(
          LINE, none(Position), scale, placement, view_projection, WIDTH_MARK,
          HEIGHT_MARK, progress = 1.0, is_touch = false, travel = none(float),
        )
        if marker.isNone or marker.get.count_segment < 4: continue
        # Segments 0 and 1 are one side's own two halves, sharing support at index 0.
        for side in [0, 2]:
          let (before, after) = (marker.get.segments[side], marker.get.segments[side + 1])
          # Far end of one half, against infinite line through other.
          check awayFromScreen(after[1], before[0], before[1]) < TOLERANCE_SINGLE


  test "a line's rails spend their spread rather than their visibility":
    # What world offset costs is that perspective, not reader, chooses how far apart.
    #   pair ends up: at one camera it read 45.6 px against stated 14.5. Offset
    #   is now settled until *widest* reading is stated gap, so what oblique
    #   view takes is gap at narrow end -- pair closing on its own line -- and
    #   never marker itself.
    proc apartAtSupport(out_to: Direction, distance: float): float =
      let (placement, view_projection, scale) = setUpAt(out_to, distance)
      let marker = shapedMarkerFor(
        LINE, none(Position), scale, placement, view_projection, WIDTH_MARK, HEIGHT_MARK,
        progress = 1.0, is_touch = false, travel = none(float),
      )
      if marker.isNone or marker.get.count_segment < 4: return 0.0
      hypot(
        marker.get.segments[2][0].x - marker.get.segments[0][0].x,
        marker.get.segments[2][0].y - marker.get.segments[0][0].y,
      )
    # Support is where world offset states its gap, and it is exactly what oblique.
    #   view now gives up: 4.5 px at camera below against 13.1 at squarer one.
    check apartAtSupport(outToward(0.2, 0.05), 12.0) < apartAtSupport(outToward(1.6, 1.26), 19.0)
    check apartAtSupport(outToward(0.2, 0.05), 12.0) < 2.0*OFFSET_MARKER_RAIL
    # And marker is still there to be seen, which sweep above holds everywhere: it.
    #   is *widest* reading that is pinned, so pair is that far apart somewhere by
    #   construction. No floor under narrowing is needed, and one tried at four tenths
    #   let 437 px splay through at camera this sweep does contain.
    check apartRails(markerOf(LINE, distance = 12.0).get) > OFFSET_MARKER_RAIL


  test "a line's rails are drawn in the halves the line itself is drawn in":
    let marker = markerOf(LINE).get
    check marker.count_segment == SEGMENTS_MARKER_RAILS


  test "an eye standing on the line has no side to flank it from":
    # Joining line with eye gives no plane to take normal of -- and there is.
    #   nothing pair of rails either side of it could mean to viewer inside it.
    let scale = setUp()[2]
    let through_eye = toMultivector(scale.eye) ∧
      toMultivector(scale.eye + Direction(x: 1.0, y: 0.0, z: 0.0))
    check markerOf(through_eye).isNone


  test "a plane's marker circle lies on that plane, at every one of its points":
    let (placement, _, scale) = setUp()
    let
      centre = positionAnchor(PLANE).get
      radius = radiusMarkerLoop(centre, scale, placement, HEIGHT_MARK)
      ring = positionsMarkerLoop(centre, frame(PLANE).get, radius)
    # Unitized point wedged with unitized plane leaves its own signed distance from.
    #   that plane on antiscalar, so this reads as `how far off surface`.
    for point in ring:
      check abs((unitize(toMultivector(point)) ∧ unitize(PLANE))[Basis.scalarAnti]) =~ 0.0


  test "a marker's ring is stepped in arithmetic, and lands where the algebra says":
    # **Algebra is reference, not implementation** -- rule disc rim.
    #   and great circle already follow, applied to marker rings that were
    #   overlay's last multivector cost. Held over real plane frames rather than one
    #   contrived pair, since arms come from `boundary.frame` and claim should
    #   hold wherever it puts them.
    let (_, _, scale_ring) = setUp()
    for plane in PLANES:
      let axes = frame(plane)
      let anchor = positionAnchor(plane)
      check axes.isSome and anchor.isSome
      let
        centre = anchor.get
        radius = radiusMarkerLoop(centre, scale_ring, setUp()[0], HEIGHT_MARK)
        ring = positionsMarkerLoop(centre, axes.get, radius)
        centre_point = toMultivector(centre)
        arm_first_point = wedge(radius, toMultivector(axes.get.axis_first))
        arm_second_point = wedge(radius, toMultivector(axes.get.axis_second))
      check len(ring) == SEGMENTS_MARKER_LOOP
      for i in 0 ..< SEGMENTS_MARKER_LOOP:
        let
          angle = (2.0*PI*float(i))/float(SEGMENTS_MARKER_LOOP)
          assembled = pointFrom(add(centre_point, add(
            wedge(cos(angle), arm_first_point), wedge(sin(angle), arm_second_point),
          )))
        check ring[i] =~ assembled

    # And ring bands are stepped from is same table's, at their own count:
    #   both rings are `euclid.unitRing`'s, so neither can drift from angles
    #   sums above take.
    for i in 0 ..< SEGMENTS_MARKER_LOOP:
      let angle = (2.0*PI*float(i))/float(SEGMENTS_MARKER_LOOP)
      check UNIT_RING_LOOP[i].cos_angle =~ cos(angle)
      check UNIT_RING_LOOP[i].sin_angle =~ sin(angle)
    for i in 0 ..< SEGMENTS_MARKER_BANDS:
      let angle = (2.0*PI*float(i))/float(SEGMENTS_MARKER_BANDS)
      check UNIT_RING_BANDS[i].cos_angle =~ cos(angle)
      check UNIT_RING_BANDS[i].sin_angle =~ sin(angle)


  test "a plane's marker circle clears the drawn rim by the shared gap":
    let (placement, _, scale) = setUp()
    let
      centre = positionAnchor(PLANE).get
      radius = radiusMarkerLoop(centre, scale, placement, HEIGHT_MARK)
      per_pixel = worldPerPixelAt(centre, scale)
    check (radius - EXTENT_PLANE_F)/per_pixel =~ GAP_MARKER


  test "a plane's marker follows its stored creation anchor, as its disc does":
    let elsewhere = positionAnchor(PLANE).get + 3.0*frame(PLANE).get.axis_first
    let
      centred = markerOf(PLANE).get
      shifted = markerOf(PLANE, some(elsewhere)).get
      moved = hypot(
        shifted.points[0].x - centred.points[0].x,
        shifted.points[0].y - centred.points[0].y,
      )
    check moved > 1.0


  test "a horizon line is flanked by bands, wrapping the sky as its own circle does":
    # Plane's own attitude is horizon line -- pencil of directions lying in it.
    let marker = markerOf(LINE_HORIZON).get
    check marker.kind == MarkerKind.Bands
    # Both bands survive here: this line crosses view, so each of its two flanking.
    #   circles has stretch of itself on screen.
    check marker.counts_band[0] > 0
    check marker.counts_band[1] > 0

    # Only what survives near plane *and* edge of window is reported, so every.
    #   point handed to overlay is one it can actually stroke and one reader can
    #   actually see -- `Loop`'s own rule, twice over and one cut further.
    for side in 0 .. 1:
      for i in 0 ..< marker.counts_band[side]:
        check marker.points_band[side][i].isInFront
        check marker.points_band[side][i].isWithinView(WIDTH_MARK, HEIGHT_MARK)

    # And it stops *at* edge rather than sample short of it: band's samples are.
    #   even in angle around sky and hundreds of pixels apart once projected, so
    #   crossing point is placed rather than rounded to last one inside.
    for side in 0 .. 1:
      let (first, last) = (
        marker.points_band[side][0],
        marker.points_band[side][marker.counts_band[side] - 1],
      )
      for at in [first, last]:
        check min(min(at.x, WIDTH_MARK.float - at.x), min(at.y, HEIGHT_MARK.float - at.y)) =~ 0.0


  test "a horizon line's bands lap in what the view can show, so its comet is seen":
    # Fault this guards: band is circle running out to line's own vanishing.
    #   points, and uncut it laps in hundreds of thousands of pixels of outline no camera
    #   can see -- measured at 396,102 against 1,490 on screen. Comet travelling at
    #   fixed screen pace was then off screen for all but four frames in thousand,
    #   which is what `the pulse does not work on horizon lines` meant.
    let
      bands = markerOf(LINE_HORIZON, travel = some(0.3*LENGTH_MARKER_COMET)).get
      rails = markerOf(LINE, travel = some(0.3*LENGTH_MARKER_COMET)).get
    # Within same order of magnitude as finite line's rails, which are bounded by.
    #   very same rule. Window's own diagonal is scale both are measuring.
    check bands.lap > 0.0
    check bands.lap < 4.0*rails.lap
    check bands.lap < hypot(WIDTH_MARK.float, HEIGHT_MARK.float)*2.0
    # Both bands pulse, and in step: one of pair lit and other not reads as.
    #   marker having broken rather than as direction.
    check bands.count_run_pulse == 2

    # Comet advances along band at screen pace, rather than standing still.
    #   because almost all of its lap is somewhere reader cannot look.
    var travel = 0.3*LENGTH_MARKER_COMET
    var heads: seq[ScreenPosition]
    for frame in 0 .. 3:
      let marker = markerOf(LINE_HORIZON, travel = some(travel)).get
      check marker.count_run_pulse > 0
      heads.add(marker.pulses[0][0])
      travel = travelAdvanced(travel, marker.lap, 1.0)
    for i in 1 ..< heads.len:
      let step = hypot(heads[i].x - heads[i - 1].x, heads[i].y - heads[i - 1].y)
      # Chord of gently curved band rather than arc along it, so within.
      #   fraction of percent of pace rather than exactly it.
      check abs(step - SPEED_MARKER_PULSE) < 0.01*SPEED_MARKER_PULSE
      check heads[i].isWithinView(WIDTH_MARK, HEIGHT_MARK)


  test "a cut arc still measures its pulse from the ring's own angle zero":
    # Twelve samples, arc emitted from sample 9, five of them surviving: angle zero is.
    #   fourth of those, since 9, 10, 11, 0 walks to it.
    check originAfterCut(12, 9, 5) == 3
    # Points placed ahead of samples -- crossing point at edge band enters.
    #   through -- shift it by however many there are, or comet would be anchored to
    #   cut rather than to object.
    check originAfterCut(12, 9, 5, count_before = 1) == 4
    # Angle zero cut away leaves nothing view-independent to measure from, and arc's.
    #   own start is what is left -- crossing point itself, where there is one.
    check originAfterCut(12, 9, 2) == 0
    check originAfterCut(12, 9, 2, count_before = 1) == 0


  test "one band is drawn from the longest stretch of it the window holds":
    # Ring can cross window more than once -- band seen nearly end on is circle.
    #   about vanishing point, entering and leaving twice. One outline per band is
    #   what marker holds, so largest piece is one drawn.
    let ring = [
      ScreenPosition(x: 10.0, y: 10.0, depth: 1.0),
      ScreenPosition(x: 20.0, y: 10.0, depth: 1.0),
      ScreenPosition(x: -50.0, y: 10.0, depth: 1.0),
      ScreenPosition(x: 30.0, y: 20.0, depth: 1.0),
      ScreenPosition(x: 420.0, y: 20.0, depth: 1.0),
      ScreenPosition(x: -60.0, y: 20.0, depth: 1.0),
    ]
    # Two stretches of two samples each: samples 0..1 spanning 10 pixels and samples 3..4.
    #   spanning 390. Longer one wins, and it is not one found first.
    check runShownLongest(ring, [true, true, false, true, true, false]) == (3, 2)
    # Stretch straddling sample zero is one stretch, not two index walk sees.
    check runShownLongest(ring, [true, false, false, false, true, true]) == (4, 3)
    # Ring wholly shown is one closed stretch from its own first sample.
    check runShownLongest(ring, [true, true, true, true, true, true]) == (0, 6)
    # And nothing shown is no stretch at all, which draws no band.
    check runShownLongest(ring, [false, false, false, false, false, false]) == (0, 0)


  test "a horizon line's bands close inward as its hold fills, from outside any view":
    let (_, _, scale) = setUp()
    let
      opening = angleMarkerBands(scale, 0.0, 0.0)
      midway = angleMarkerBands(scale, 0.5, 0.0)
      settled = angleMarkerBands(scale, 1.0, 0.0)
    # Quarter turn off line at start -- pole of its own sky, and so outside.
    #   any field of view this camera offers, which is what "arriving from outside" means
    #   for object that has no support to grow out from.
    check opening =~ ANGLE_MARKER_BANDS_OPEN
    check midway < opening
    check settled < midway
    # And settles at very gap finite line's rails keep, read as angle.
    check settled =~ OFFSET_MARKER_RAIL*radiansPerPixel(scale)


  test "a horizon plane is framed by the viewport, arriving as the screen's edge":
    # Attitude of grade-4 object is horizon plane -- whole sky.
    let marker = markerOf(PLANE_HORIZON).get
    check marker.kind == MarkerKind.Frame

    let
      (centre_x, centre_y) = (0.5*float(WIDTH_MARK), 0.5*float(HEIGHT_MARK))
      (inside_x, inside_y) =
        (float(WIDTH_MARK) - GAP_MARKER, float(HEIGHT_MARK) - GAP_MARKER)
    proc distancesFromCentre(marker: Marker): seq[float] =
      for i in 0 ..< marker.count_frame:
        let point = marker.points_frame[i]
        result.add(hypot(point.x - centre_x, point.y - centre_y))

    # Check finished frame is viewport's rectangle, standing `GAP_MARKER` inside it.
    #   Same clear space every other marker in family keeps from what it surrounds.
    #   Every point lies on that rectangle, and its extremes reach whole way to it.
    check marker.count_frame >= SEGMENTS_MARKER_FRAME
    var (reached_x, reached_y) = (false, false)
    for i in 0 ..< marker.count_frame:
      let point = marker.points_frame[i]
      check point.x >= GAP_MARKER - TOLERANCE_SINGLE
      check point.x <= inside_x + TOLERANCE_SINGLE
      check point.y >= GAP_MARKER - TOLERANCE_SINGLE
      check point.y <= inside_y + TOLERANCE_SINGLE
      # On rectangle, not merely within it: one coordinate is pinned to edge.
      check point.x =~ GAP_MARKER or point.x =~ inside_x or
        point.y =~ GAP_MARKER or point.y =~ inside_y
      if point.x =~ GAP_MARKER or point.x =~ inside_x: reached_x = true
      if point.y =~ GAP_MARKER or point.y =~ inside_y: reached_y = true
    check reached_x and reached_y

    # Barely started, it is circle about centre of view: every point stands.
    #   same distance out, which scaled rectangle never does. That is mechanic
    #   user asked for -- expanding outward from middle rather than shrinking inward
    #   from edge -- and it is opposite of bands above, which close in from
    #   outside any view at all.
    # Full reach is corners' own distance, so `progress` of it is circle's radius.
    #   for as long as circle is thing bounding it.
    let half_diagonal = hypot(centre_x - GAP_MARKER, centre_y - GAP_MARKER)
    proc reachAt(progress: float): float = progress*half_diagonal
    let opening = distancesFromCentre(markerOf(PLANE_HORIZON, progress = 0.1).get)
    for distance in opening: check distance =~ reachAt(0.1)
    check reachAt(0.1) < centre_y - GAP_MARKER # Still clear of nearest edge.

    # Part way, circle has passed short edges but not corners, so boundary.
    #   is edge in some directions and still circle in others -- which is what "highlights
    #   each part of edge as it gets there" means, checked rather than assumed.
    let partial = markerOf(PLANE_HORIZON, progress = 0.75).get
    var (count_on_edge, count_off_edge) = (0, 0)
    for i in 0 ..< partial.count_frame:
      let point = partial.points_frame[i]
      if point.x =~ GAP_MARKER or point.x =~ inside_x or
          point.y =~ GAP_MARKER or point.y =~ inside_y:
        inc count_on_edge
      else:
        inc count_off_edge
    check count_on_edge > 0
    check count_off_edge > 0
    # And part still short of edge is circular at that same shared reach, so.
    #   marker really is one expanding circle bitten into by screen, not two shapes.
    for i in 0 ..< partial.count_frame:
      let point = partial.points_frame[i]
      if point.x =~ GAP_MARKER or point.x =~ inside_x or
          point.y =~ GAP_MARKER or point.y =~ inside_y: continue
      check hypot(point.x - centre_x, point.y - centre_y) =~ reachAt(0.75)

    # Frame's four corners are sampled explicitly, so finished outline has real.
    #   corners rather than corners cut across by wherever even steps happened to land.
    var count_corner = 0
    for i in 0 ..< marker.count_frame:
      let point = marker.points_frame[i]
      if (point.x =~ GAP_MARKER or point.x =~ inside_x) and
          (point.y =~ GAP_MARKER or point.y =~ inside_y):
        inc count_corner
    check count_corner == CORNERS_MARKER_FRAME


  test "a touch hold swells every marker clear of the finger, and a mouse never sees it":
    # Reason swell exists: fingertip covers what it presses, so marker filling.
    #   underneath one says nothing to person filling it. How far out it stands is now
    #   plain scaling of swell, whose *shape* is `interaction.swellHold`'s to decide.
    const RADIUS_FINGER = 22.0 # Half 44-pixel minimum touch pivot.
    check clearanceTouch(0.0, is_touch = true) =~ 0.0
    check 0.5*float(DIAMETER_POINT_LEAST) + GAP_MARKER + clearanceTouch(1.0, is_touch = true) >
      RADIUS_FINGER
    for swell in [0.0, 0.25, 0.5, 0.75, 1.0]:
      check clearanceTouch(swell, is_touch = false) =~ 0.0


  test "a horizon point keeps its ring, on the star it is drawn as":
    # Its own star stands one horizon radius along its direction, so it is markable only.
    #   while camera is turned toward it -- behind eye it reports same
    #   "nothing to draw" every other unmarkable case does.
    proc ringAt(bearing: float): Option[Marker] =
      let placement = cameraAround(ORIGIN, 19.0, outToward(bearing, 0.42))
      let scale = placement.drawExtentFor(HEIGHT_MARK, 0.0)
      shapedMarkerFor(
        attitude(LINE), none(Position), scale, placement,
        placement.initMatrixViewProjection(WIDTH_MARK/HEIGHT_MARK), WIDTH_MARK, HEIGHT_MARK,
      )
    check ringAt(1.9).get.kind == MarkerKind.Ring
    check ringAt(0.0).isNone


  test "a plane's label sits above the true top of its circle and glides as the camera turns":
    # Sampled top hopped vertex to vertex as camera orbited, label with it; closed-form.
    #   top moves continuously: no step more than twice one before it and pixel, even
    #   where thin ellipse's top runs along its length. Label's top is never below any
    #   sampled vertex, and within segment's sag of lowest one.
    let lift = GAP_MARKER + 0.5*HEIGHT_MARKER_LABEL
    var
      hops_sampled = 0
      hops_label = 0
      x_sampled_before = none(float)
      x_label_before = none(float)
      step_sampled_before = 0.0
      step_label_before = 0.0
    var bearing = 0.0
    while bearing < 2.0*PI:
      let (placement, view_projection, scale) = setUpAt(outToward(bearing, 0.42), 19.0)
      let loop = shapedMarkerFor(
        PLANE, none(Position), scale, placement, view_projection, WIDTH_MARK, HEIGHT_MARK
      ).get
      check loop.kind == MarkerKind.Loop and loop.has_label and loop.is_closed
      var (x_sampled, y_lowest) = (0.0, Inf)
      for i in 0 ..< loop.count_point:
        if loop.points[i].y < y_lowest: (x_sampled, y_lowest) = (loop.points[i].x, loop.points[i].y)
      let top_y = loop.label_at.y + lift
      check top_y <= y_lowest + TOLERANCE_TEST
      check top_y >= y_lowest - 1.0
      if x_sampled_before.isSome:
        let
          step_sampled = abs(x_sampled - x_sampled_before.get)
          step_label = abs(loop.label_at.x - x_label_before.get)
        if step_sampled > 2.0*step_sampled_before + 1.0: inc hops_sampled
        if step_label > 2.0*step_label_before + 1.0: inc hops_label
        (step_sampled_before, step_label_before) = (step_sampled, step_label)
      (x_sampled_before, x_label_before) = (some(x_sampled), some(loop.label_at.x))
      bearing += STEP_GLIDE
    check hops_label == 0
    check hops_sampled > 0 # Failure this replaces, pinned.


  test "a plane's label passes through the flip without a jump":
    # Seen from just above, top is far rim; from just below, near rim. Label stands on.
    #   disc centre's column at top's height, and both go to plane's horizon as ellipse
    #   flattens: milliradian either side, labels stand under pixel apart. Disc off sight
    #   axis too, where far top and near top themselves part in x.
    let ground = planeThrough(toMultivector(ORIGIN), toMultivector(UP_WORLD))
    for anchor in [none(Position), some(Position(x: 3.0, y: -4.0, z: 0.0))]:
      var labels: seq[ScreenPosition]
      for rise in [0.001, -0.001]:
        let (placement, view_projection, scale) = setUpAt(outToward(0.9, rise), 19.0)
        let loop = shapedMarkerFor(
          ground, anchor, scale, placement, view_projection, WIDTH_MARK, HEIGHT_MARK
        ).get
        check loop.has_label
        labels.add(loop.label_at)
      check abs(labels[0].x - labels[1].x) < 1.0
      check abs(labels[0].y - labels[1].y) < 1.0


  test "the top of a circle facing the camera is its centre less its radius":
    # Same answer ring rule gives point, from closed form; none for circle behind eye.
    let (placement, view_projection, scale) = setUp()
    let
      eye = placement.eye
      axes = placement.frame
      centre = Position(x: 0.0, y: 0.0, z: 0.0)
    let top = topmostOnCircle(
      centre, 2.0*axes.axis_right, 2.0*axes.axis_up, view_projection, WIDTH_MARK, HEIGHT_MARK
    )
    check top.isSome
    let expected = projectToScreen(
      view_projection, WIDTH_MARK, HEIGHT_MARK, centre + 2.0*axes.axis_up
    )
    check abs(top.get.x - expected.x) < 1.0e-6
    check abs(top.get.y - expected.y) < 1.0e-6
    let behind = topmostOnCircle(
      eye - 2.0*axes.forward, 0.5*axes.axis_right, 0.5*axes.axis_up, view_projection,
      WIDTH_MARK, HEIGHT_MARK,
    )
    check behind.isNone


  test "a line's label keeps to the line's own left and glides through every turn":
    # Side of unoriented line flips at vertical, so old rule hopped rail to rail there.
    #   Side of line's own direction does not. Over full orbit at two heights, second
    #   carrying line through vertical twice, anchor never takes isolated step and push
    #   direction turns steadily.
    for rise in [0.42, 3.0]:
      var
        at_before = none(ScreenPosition)
        away_before = (0.0, 0.0)
        step_before = 0.0
      var bearing = 0.0
      while bearing < 2.0*PI:
        let (placement, view_projection, scale) = setUpAt(outToward(bearing, rise), 19.0)
        let rails = shapedMarkerFor(
          LINE, none(Position), scale, placement, view_projection, WIDTH_MARK, HEIGHT_MARK
        ).get
        check rails.kind == MarkerKind.Rails and rails.has_label and rails.is_label_beside
        check rails.label_at.x >= 0.0 and rails.label_at.x <= float(WIDTH_MARK)
        check rails.label_at.y >= 0.0 and rails.label_at.y <= float(HEIGHT_MARK)
        if at_before.isSome:
          let step = hypot(rails.label_at.x - at_before.get.x, rails.label_at.y - at_before.get.y)
          check step <= 2.0*step_before + 1.0
          check hypot(
            rails.label_away_x - away_before[0], rails.label_away_y - away_before[1]
          ) < 0.05
          step_before = step
        at_before = some(rails.label_at)
        away_before = (rails.label_away_x, rails.label_away_y)
        bearing += STEP_GLIDE


  test "a horizon line's label rides its band's left edge crossing through an orbit":
    # Highest point of either band hopped between view's two side edges, whose crossings.
    #   stand within pixel in height on level horizon, so label swapped sides frame to
    #   frame. Leftmost point is crossing on left edge itself, which glides.
    for rise in [0.2, 0.42]:
      var
        at_before = none(ScreenPosition)
        count_labelled = 0
        bearing = 0.0
      while bearing < 2.0*PI:
        let (placement, view_projection, scale) = setUpAt(outToward(bearing, rise), 19.0)
        let bands = shapedMarkerFor(
          LINE_HORIZON, none(Position), scale, placement, view_projection, WIDTH_MARK,
          HEIGHT_MARK,
        )
        bearing += 0.02
        if bands.isNone or not bands.get.has_label:
          at_before = none(ScreenPosition)
          continue
        inc count_labelled
        let at = bands.get.label_at
        # Margin right of leftmost point either band shows, and in view. Not left half of
        #   view: tilted horizon here leaves through top or bottom edge on right at some
        #   bearings, and whole visible stretch stands right of centre.
        check at.x >= MARGIN_LABEL_HORIZON - TOLERANCE_TEST and at.x <= float(WIDTH_MARK)
        for side in 0 .. 1:
          for i in 0 ..< bands.get.counts_band[side]:
            check bands.get.points_band[side][i].x >=
              at.x - MARGIN_LABEL_HORIZON - PIXELS_TIE_LEFTMOST - TOLERANCE_TEST
        if at_before.isSome:
          check hypot(at.x - at_before.get.x, at.y - at_before.get.y) < 40.0
        at_before = some(at)
      check count_labelled > 0


  test "a line's label stays in view when its support leaves it":
    # Camera looks twelve units along line from support: support projects off screen, or.
    #   behind eye, while line still crosses view. Anchor slides to visible stretch,
    #   margin in from edge, on line.
    let
      support = positionAnchor(LINE).get
      axis = direction(LINE).get
    for sign in [1.0, -1.0]:
      # Eye square to line, so support stands twelve units aside at eight of depth.
      let placement = cameraAround(
        support + (sign*12.0)*axis, 8.0,
        Direction(x: -axis.y, y: axis.x, z: 0.36*hypot(axis.x, axis.y)),
      )
      let scale = placement.drawExtentFor(HEIGHT_MARK, 0.0)
      let view_projection = placement.initMatrixViewProjection(WIDTH_MARK/HEIGHT_MARK)
      let projected = projectToScreen(view_projection, WIDTH_MARK, HEIGHT_MARK, support)
      check not projected.isWithinView(WIDTH_MARK, HEIGHT_MARK)
      let rails = shapedMarkerFor(
        LINE, none(Position), scale, placement, view_projection, WIDTH_MARK, HEIGHT_MARK
      ).get
      check rails.has_label and rails.is_label_beside
      let at = rails.label_at
      check at.isWithinView(WIDTH_MARK, HEIGHT_MARK)
      # On line: square distance to line through support and point along it vanishes.
      let along = projectToScreen(view_projection, WIDTH_MARK, HEIGHT_MARK, support + axis)
      check awayFromScreen(at, projected, along) < 0.5
      # Margin in from nearest edge, along line, is `MARGIN_LABEL_VIEW`.
      let room = min(min(at.x, float(WIDTH_MARK) - at.x), min(at.y, float(HEIGHT_MARK) - at.y))
      check room > 0.5*MARGIN_LABEL_VIEW - 1.0


  test "label is held wholly inside view, and centred where its box cannot fit":
    # Page 393 wide, 560 tall, label 80 wide: right edge, top edge, both corners, and free.
    const (WIDTH_PAGE, HEIGHT_PAGE, HALF) = (393.0, 560.0, 40.0)
    let
      half_height = 0.5*HEIGHT_MARKER_LABEL
      (lo_x, hi_x) = (MARGIN_LABEL_EDGE + HALF, WIDTH_PAGE - MARGIN_LABEL_EDGE - HALF)
      (lo_y, hi_y) =
        (MARGIN_LABEL_EDGE + half_height, HEIGHT_PAGE - MARGIN_LABEL_EDGE - half_height)
    check labelInView(390.0, 505.0, HALF, WIDTH_PAGE, HEIGHT_PAGE) == (hi_x, 505.0)
    check labelInView(100.0, 3.0, HALF, WIDTH_PAGE, HEIGHT_PAGE) == (100.0, lo_y)
    check labelInView(-20.0, 700.0, HALF, WIDTH_PAGE, HEIGHT_PAGE) == (lo_x, hi_y)
    check labelInView(100.0, 100.0, HALF, WIDTH_PAGE, HEIGHT_PAGE) == (100.0, 100.0)
    # Held box's edges: halo's stroke and one pixel of air stay inside.
    check hi_x + HALF == WIDTH_PAGE - MARGIN_LABEL_EDGE
    check MARGIN_LABEL_EDGE > WIDTH_MARKER_LABEL_HALO
    # Wider than view, or taller: centred on that axis.
    check labelInView(100.0, 100.0, 300.0, WIDTH_PAGE, HEIGHT_PAGE) == (0.5*WIDTH_PAGE, 100.0)
    check labelInView(100.0, 100.0, HALF, WIDTH_PAGE, 10.0) == (100.0, 5.0)


  test "a label pushed beside a line clears it by its own box":
    # Clearance is rail, gap, and box's half-extent along push: flat line uses half height,.
    #   vertical one half width.
    check abs(clearanceBeside(0.0, -1.0, 30.0) - (OFFSET_MARKER_RAIL + GAP_MARKER + 8.0)) < 1.0e-9
    check abs(clearanceBeside(1.0, 0.0, 30.0) - (OFFSET_MARKER_RAIL + GAP_MARKER + 30.0)) < 1.0e-9
    let diagonal = clearanceBeside(sqrt(0.5), sqrt(0.5), 30.0)
    check diagonal > OFFSET_MARKER_RAIL + GAP_MARKER + 8.0 and
      diagonal < OFFSET_MARKER_RAIL + GAP_MARKER + 30.0


  test "every marker places its name label above its own top, clear of the outline":
    # Where label sits is marker's decision, so both front-ends agree by construction.
    #   Ring: above its top. Rails: on line at support, pushed to line's left. Loop: above
    #   highest outline point. Bands: above leftmost, pushed in from edge. Frame is whole
    #   view, so label stands inside its bottom-left corner, in from edge, pushed rightward.
    let lift = GAP_MARKER + 0.5*HEIGHT_MARKER_LABEL
    let ring = markerOf(POINT_A).get
    check ring.has_label
    check ring.label_at.x =~ ring.centre.x
    check ring.label_at.y =~ ring.centre.y - ring.radius - lift
    # Swollen ring lifts its label by same swell.
    let (placement, view_projection, scale) = setUp()
    let swollen = shapedMarkerFor(
      POINT_A, none(Position), scale, placement, view_projection, WIDTH_MARK, HEIGHT_MARK,
      1.0, is_touch = true, travel = none(float), swell = 1.0,
    ).get
    check swollen.radius > ring.radius
    check swollen.label_at.y =~ swollen.centre.y - swollen.radius - lift
    let loop = markerOf(PLANE).get
    check loop.kind == MarkerKind.Loop and loop.has_label
    for i in 0 ..< loop.count_point:
      check loop.points[i].y >= loop.label_at.y + lift - TOLERANCE_TEST
    let rails = markerOf(LINE).get
    check rails.kind == MarkerKind.Rails and rails.has_label and rails.is_label_beside
    let support = projectToScreen(
      view_projection, WIDTH_MARK, HEIGHT_MARK, positionAnchor(LINE).get
    )
    # Anchor on line at support, push direction unit and square to line's screen direction.
    check abs(rails.label_at.x - support.x) < 1.0e-6
    check abs(rails.label_at.y - support.y) < 1.0e-6
    check abs(hypot(rails.label_away_x, rails.label_away_y) - 1.0) < 1.0e-9
    let along = projectToScreen(
      view_projection, WIDTH_MARK, HEIGHT_MARK, positionAnchor(LINE).get + 0.1*direction(LINE).get
    )
    check abs((along.x - support.x)*rails.label_away_x + (along.y - support.y)*rails.label_away_y) <
      1.0e-6*hypot(along.x - support.x, along.y - support.y)
    let bands = markerOf(LINE_HORIZON).get
    check bands.kind == MarkerKind.Bands and bands.has_label and bands.is_label_beside
    check bands.label_away_x =~ 1.0 and bands.label_away_y =~ 0.0
    for side in 0 .. 1:
      for i in 0 ..< bands.counts_band[side]:
        check bands.points_band[side][i].x >=
          bands.label_at.x - MARGIN_LABEL_HORIZON - PIXELS_TIE_LEFTMOST - TOLERANCE_TEST
    let frame = markerOf(PLANE_HORIZON).get
    check frame.kind == MarkerKind.Frame and frame.has_label and frame.is_label_beside
    check frame.label_at.x =~ GAP_MARKER + MARGIN_LABEL_HORIZON
    check frame.label_at.y =~
      float(HEIGHT_MARK) - MARGIN_LABEL_FOOT - MARGIN_LABEL_HORIZON - 0.5*HEIGHT_MARKER_LABEL
    check frame.label_away_x =~ 1.0 and frame.label_away_y =~ 0.0


  test "a marker at full progress is exactly the marker drawn with no progress asked for":
    # Property whole animation rests on: adding `progress` moved nothing for any.
    #   caller that is not animating hold. Held here as well as by storyboard's own
    #   byte comparison, so regression names itself rather than showing up as pixel.
    check markerOf(POINT_A, progress = 1.0).get.fraction == 1.0
    check reachRails(markerOf(LINE, progress = 1.0).get) =~ reachRails(markerOf(LINE).get)
    check radiusLoop(markerOf(PLANE, progress = 1.0).get) =~ radiusLoop(markerOf(PLANE).get)


  test "each shape fills the way its own outline is read":
    # Check each kind's fill: point sweeps, line runs outward, plane's circle opens.
    #   Point is drawn at one fixed size and has nothing to grow into; line runs toward
    #   its horizons; plane's circle opens from its centre.
    check markerOf(POINT_A, progress = 0.25).get.fraction =~ 0.25
    check markerOf(POINT_A, progress = 0.25).get.radius =~
      markerOf(POINT_A).get.radius # Swept, never shrunk.
    var
      reach_previous = 0.0
      radius_previous = 0.0
    for step in 1 .. 8:
      let progress = float(step)/8.0
      let (reach, radius) = (
        reachRails(markerOf(LINE, progress = progress).get),
        radiusLoop(markerOf(PLANE, progress = progress).get),
      )
      check reach > reach_previous
      check radius > radius_previous
      (reach_previous, radius_previous) = (reach, radius)


  test "a rail that is only part grown still lies along the rail it will become":
    # Growing rail must not slide it off line it flanks. Every partial head sits on.
    #   segment between finished rail's own two ends, which is line's own
    #   screen projection -- reason shortening is done after projecting, along
    #   that segment, rather than by scaling world reach anchored at eye.
    let whole = markerOf(LINE).get
    for step in 1 .. 4:
      let part = markerOf(LINE, progress = float(step)/4.0).get
      check part.count_segment == whole.count_segment
      for i in 0 ..< whole.count_segment:
        let
          (tail, head) = (whole.segments[i][0], whole.segments[i][1])
          grown = part.segments[i][1]
          along = hypot(head.x - tail.x, head.y - tail.y)
          # Distance from grown head to whole rail, as twice triangle's area.
          #   over its base: zero exactly when three points are collinear.
          area_twice = abs(
            (head.x - tail.x)*(grown.y - tail.y) - (head.y - tail.y)*(grown.x - tail.x)
          )
        check part.segments[i][0] == tail # Still starts where finished rail starts.
        check area_twice/along < TOLERANCE_SINGLE


  test "a line's rails grow across the view, both halves at a comparable rate":
    # Defect this pins: rail was shortened by fraction of its *own* projected.
    #   length, and that length runs to vanishing point. Measured on demo's own
    #   line, one half came to 1,140,706 pixels and other to 3,634 -- so one finished
    #   314 times sooner than other, and both were wholly off 900-pixel screen
    #   within first percent of hold. Growing toward vanishing point is growing
    #   into nothing; reach is measured against edge of view instead.
    proc lengthsAt(progress: float): seq[float] =
      let marker = markerOf(LINE, progress = progress).get
      for i in 0 ..< marker.count_segment:
        let (tail, head) = (marker.segments[i][0], marker.segments[i][1])
        result.add(hypot(head.x - tail.x, head.y - tail.y))

    let whole = lengthsAt(1.0)
    check len(whole) >= 2
    # No rail runs further than view's own diagonal: growth is all on screen.
    let diagonal = hypot(float(WIDTH_MARK), float(HEIGHT_MARK))
    for length in whole: check length <= diagonal

    # Halves stay within small factor of one another rather than wild one, and.
    #   each is straight multiple of progress -- one speed, from support, both ways.
    check max(whole)/max(min(whole), 1.0) < 4.0
    for step in 1 .. 3:
      let progress = float(step)/4.0
      let partial = lengthsAt(progress)
      check len(partial) == len(whole)
      for i in 0 ..< len(whole): check partial[i] =~ progress*whole[i]


  test "a rail bounded by the view stops at the edge it leaves through":
    const (WIDE, TALL) = (200.0, 100.0)
    let inside = ScreenPosition(x: 100.0, y: 50.0)
    # Straight out to right: half width away, so half of segment twice as long.
    check fractionLeavingView(
      inside, ScreenPosition(x: 300.0, y: 50.0), int(WIDE), int(TALL)
    ) =~ 0.5
    # Ending inside is not shortened at all.
    check fractionLeavingView(
      inside, ScreenPosition(x: 150.0, y: 60.0), int(WIDE), int(TALL)
    ) =~ 1.0
    # Starting outside and heading further out draws nothing, which is what can be seen.
    check fractionLeavingView(
      ScreenPosition(x: 400.0, y: 50.0), ScreenPosition(x: 900.0, y: 50.0),
      int(WIDE), int(TALL),
    ) =~ 0.0


  test "a pulse rides its own outline, and only where there is an orientation to state":
    proc pulsed(geometry: Multivector, travel: float): Marker =
      markerOf(geometry, travel = some(travel)).get

    # Plane's circle and line's rails both carry one; point has no orientation and.
    #   horizon plane carries no normal at all, so neither says anything.
    check pulsed(PLANE, 0.3).count_run_pulse > 0
    check pulsed(LINE, 0.3).count_run_pulse > 0
    # Horizon line's bands are cut to view at both ends, and their own angle zero.
    #   stands off screen here, so travel is measured from edge arc enters
    #   through -- third of pixel past which is comet with no tail yet, by same
    #   clamp that keeps arc's run from drawing chord across view. Read where
    #   comet is actually on its way round.
    check pulsed(LINE_HORIZON, 0.3*LENGTH_MARKER_COMET).count_run_pulse > 0
    check pulsed(POINT_A, 0.3).count_run_pulse == 0
    check pulsed(PLANE_HORIZON, 0.3).count_run_pulse == 0
    # Nothing pulses unless caller says object is selected by passing time.
    check markerOf(PLANE).get.count_run_pulse == 0

    # Every point of it lies on very outline it rides, to within its own half-width:
    #   run is sampled from marker's own points rather than traced on curve of
    #   its own, and then wrapped in ribbon standing off that spine either side.
    let marker = pulsed(PLANE, 0.3)
    proc distanceToLoop(point: ScreenPosition, marker: Marker): float =
      result = high(float)
      for i in 0 ..< marker.count_point:
        let (first, second) = (marker.points[i], marker.points[(i + 1) mod marker.count_point])
        let (dx, dy) = (second.x - first.x, second.y - first.y)
        let span = dx*dx + dy*dy
        let along =
          if span <= 0.0: 0.0
          else: clamp(((point.x - first.x)*dx + (point.y - first.y)*dy)/span, 0.0, 1.0)
        let on = first.towards(second, along)
        result = min(result, hypot(point.x - on.x, point.y - on.y))
    for run in 0 ..< marker.count_run_pulse:
      # Both sides and head's cap, so every run is one closed loop of them.
      check marker.counts_pulse[run] mod 2 == SEGMENTS_MARKER_CAP mod 2
      for i in 0 ..< marker.counts_pulse[run]:
        check distanceToLoop(marker.pulses[run][i], marker) <
          0.5*float(WIDTH_MARKER_COMET) + 1.0

    # Run tapers: its head stands off spine by half `WIDTH_MARKER_COMET`, and its.
    #   tail meets outline at outline's own width, so only head is edge.
    let outline = marker.pulses[0]
    let count = marker.counts_pulse[0]
    let spans = (count - SEGMENTS_MARKER_CAP) div 2
    proc widthAcross(i: int): float =
      hypot(outline[i].x - outline[2*spans - 1 - i].x,
        outline[i].y - outline[2*spans - 1 - i].y)
    check widthAcross(0) =~ float(WIDTH_MARKER_COMET)
    check widthAcross(spans - 1) =~ float(WIDTH_MARKER)
    # And it thins whole way, never swelling again behind its own head.
    for i in 1 ..< spans:
      check widthAcross(i) <= widthAcross(i - 1) + TOLERANCE_SINGLE


  test "a pulse is the same length whatever shape it rides":
    # Point of measuring run in pixels. Under fraction of outline it came out.
    #   96 px along line's rail against 334 px round plane's circle -- one constant,
    #   compact comet on one shape and long gradient on another.
    proc lengthOfRun(marker: Marker, run: int): float =
      # Down middle of ribbon, which recovers spine it was built around: its.
      #   own two edges splay wherever width changes, and are longer than run.
      let spans = (marker.counts_pulse[run] - SEGMENTS_MARKER_CAP) div 2
      proc middleAt(i: int): ScreenPosition =
        marker.pulses[run][i].towards(marker.pulses[run][2*spans - 1 - i], 0.5)
      for i in 1 ..< spans:
        let (a, b) = (middleAt(i - 1), middleAt(i))
        result += hypot(b.x - a.x, b.y - a.y)

    # Partway along, so no run is one shortened by end of open arc.
    for geometry in [PLANE, LINE, LINE_HORIZON]:
      let lap = markerOf(geometry, travel = some(0.0)).get.lap
      let shaped = markerOf(geometry, travel = some(0.4*lap)).get
      check shaped.count_run_pulse > 0
      for run in 0 ..< shaped.count_run_pulse:
        # Run laid along curve is chain of chords, so it falls hair short of.
        #   arc it covers; nothing else may.
        check lengthOfRun(shaped, run) <= LENGTH_MARKER_COMET + TOLERANCE_SINGLE
        check lengthOfRun(shaped, run) > 0.98*LENGTH_MARKER_COMET


  proc headOfRun(marker: Marker, run: int): ScreenPosition =
    ## Find where run's spine begins, recovered from middle of ribbon around it.
    ##   Its own edges ride wide of spine on outside of any bend.
    let spans = (marker.counts_pulse[run] - SEGMENTS_MARKER_CAP) div 2
    marker.pulses[run][0].towards(marker.pulses[run][2*spans - 1], 0.5)

  test "one step of travel carries the head that many pixels, on every shape":
    # Marker's half of constant screen speed, and whole point of units:
    #   step of travel buys same *pixels* on every shape, where step of phase bought
    #   share of whatever outline currently measured -- which is why same step
    #   moved head further on long rail than short one, and further still once
    #   camera had stretched it. How many seconds step takes is `PulseClock`'s half.
    for geometry in [PLANE, LINE, LINE_HORIZON]:
      let lap = markerOf(geometry, travel = some(0.0)).get.lap
      proc headAt(travelled: float): ScreenPosition =
        headOfRun(markerOf(geometry, travel = some(travelled)).get, 0)
      const STEP = 4.0
      let
        start = 0.4*lap
        crossed = hypot(
          headAt(start + STEP).x - headAt(start).x, headAt(start + STEP).y - headAt(start).y
        )
      # Chord, so hair under arc actually covered -- and no `lap` on either side of.
      #   comparison, which is assertion this case exists to make.
      check crossed <= STEP + TOLERANCE_SINGLE
      check crossed > 0.98*STEP


  test "a camera move slides a line's comet with the line, never along it":
    # **Case whose absence let this ship twice.** Every other pulse case pins one.
    #   camera, so head measured as fraction of viewport-clipped outline looked
    #   perfect standing still and slid moment view moved -- measured at time
    #   as median 3.76 px frame while orbiting, recorded as motion marker was
    #   "entitled to", and reported by reader who disagreed.
    #   Rail is straight on screen, so distance from its anchor to head *is*
    #   travel, exactly, with no chord error to allow for. That makes line shape this
    #   states most sharply -- and line is what was reported. Curved outline's chord is
    #   not its arc and its curvature moves with camera, so same assertion on
    #   plane would be measuring circle, not comet.
    const TRAVEL_CASE = 37.0
    var count_checked = 0
    for bearing in [0.2, 0.9, 1.7, 2.6, 3.4]:
      for rise in [-0.55, 0.42, 1.56]:
        for distance in [9.0, 19.0, 34.0]:
          let (placement, view_projection, scale) =
            setUpAt(outToward(bearing, rise), distance)
          let shaped = shapedMarkerFor(
            LINE, none(Position), scale, placement, view_projection,
            WIDTH_MARK, HEIGHT_MARK, 1.0, is_touch = false, travel = some(TRAVEL_CASE),
          )
          if shaped.isNone or shaped.get.count_run_pulse == 0: continue
          # Skip placement with too little rail left to hold travel, which laps it.
          if shaped.get.lap <= TRAVEL_CASE: continue
          for run in 0 ..< shaped.get.count_run_pulse:
            let
              head = headOfRun(shaped.get, run)
              anchor = shaped.get.anchors_pulse[run]
              reached = hypot(head.x - anchor.x, head.y - anchor.y)
            check abs(reached - TRAVEL_CASE) < 1.0
            inc count_checked
    # Sweep has to actually have exercised something, or checks above are vacuous.
    check count_checked >= 30


  test "a line wears one comet, not one for every piece it is drawn in":
    # Rail is drawn as two halves either side of line's support, and each used to.
    #   pulse on its own -- four comets at four unrelated places on one selected line.
    let lap = markerOf(LINE, travel = some(0.0)).get.lap
    let shaped = markerOf(LINE, travel = some(0.4*lap)).get
    check shaped.count_segment == 4
    check shaped.count_run_pulse == 2
    # And pair travels together rather than each rail keeping its own clock, so.
    #   two read as one comet crossing line rather than as two chasing each other.
    let heads = [headOfRun(shaped, 0), headOfRun(shaped, 1)]
    check hypot(heads[1].x - heads[0].x, heads[1].y - heads[0].y) < LENGTH_MARKER_COMET


  test "a line's rails pulse from their very first frame, and report a lap to reduce on":
    # Property browser-side deadlock turned on, kept and inverted. Every handle starts.
    #   at travel 0, and while travel was *fraction* that put line's head at very
    #   start of open outline with nothing behind it to light -- no run, and marker
    #   that also reported no length left clock unable to advance, so it never left 0.
    #   It cost selected line its comet outright on build whose suite was green.
    #   Measuring from support instead puts travel 0 in *middle* of rail, so
    #   run exists immediately and deadlock has no state to occupy at all. Lap must
    #   still be reported, because that is what clock reduces against.
    let stalled = markerOf(LINE, travel = some(0.0)).get
    check stalled.count_run_pulse == 2 # One per rail, from first frame.
    check stalled.lap > 0.0
    check travelAdvanced(0.0, stalled.lap, 1.0) > 0.0
    # Closed outline never entered that state and still does not.
    check markerOf(PLANE, travel = some(0.0)).get.count_run_pulse == 1


  test "a pulse laps rather than stopping":
    let lap = markerOf(PLANE, travel = some(0.0)).get.lap
    proc headAt(travelled: float): ScreenPosition =
      headOfRun(markerOf(PLANE, travel = some(travelled)).get, 0)

    let start = headAt(0.0)
    var moved = 0
    for step in 1 .. 5:
      if hypot(headAt(float(step)*lap/6.0).x - start.x,
        headAt(float(step)*lap/6.0).y - start.y) > 1.0: inc moved
    check moved == 5
    # Whole lap on is where it began, so motion is circulation rather than run.
    #   that ends somewhere.
    let lapped = headAt(lap)
    check hypot(lapped.x - start.x, lapped.y - start.y) < 1.0
    # And advance itself reduces rather than growing without bound: three laps' worth.
    #   of seconds lands exactly where one moment of it did. Reducing every step, rather
    #   than at point of use, is what stops change in lap being amplified by
    #   however many laps have gone by -- see `travelAdvanced`.
    const LAP = 300.0
    check travelAdvanced(0.25*LAP, LAP, 3.0*LAP/SPEED_MARKER_PULSE) =~ 0.25*LAP


  test "the drag band swells into its head, whichever way it runs":
    const SPANS = SEGMENTS_MARKER_PULSE
    for (dx, dy) in [(120.0, 0.0), (-120.0, 0.0), (0.0, 90.0), (-70.0, -70.0)]:
      let
        tail = ScreenPosition(x: 200.0, y: 150.0)
        head = ScreenPosition(x: tail.x + dx, y: tail.y + dy)
        drawn = cometFor(tail, head).get
      # Widest across point aimed at, thinning to band's own width behind it, so.
      #   swell itself is what says which end answer lands at.
      proc widthAcross(i: int): float =
        hypot(drawn[i].x - drawn[2*SPANS - 1 - i].x, drawn[i].y - drawn[2*SPANS - 1 - i].y)
      check widthAcross(0) =~ float(WIDTH_MARKER_COMET)
      check widthAcross(SPANS - 1) =~ float(WIDTH_MARKER)
      # Centred on band rather than swung to one side of it.
      for i in [0, SPANS div 2, SPANS - 1]:
        let middle = ScreenPosition(
          x: 0.5*(drawn[i].x + drawn[2*SPANS - 1 - i].x),
          y: 0.5*(drawn[i].y + drawn[2*SPANS - 1 - i].y),
        )
        check abs((middle.x - head.x)*dy - (middle.y - head.y)*dx) < TOLERANCE_SINGLE
      # Lying behind point aimed at, never past it, apart from head's own cap.
      for i in 0 ..< 2*SPANS:
        check (drawn[i].x - head.x)*dx + (drawn[i].y - head.y)*dy <= TOLERANCE_SINGLE

  test "a drag band shorter than the comet lights all of itself, and no more":
    # Otherwise head would reach back past very object drag started on.
    let
      tail = ScreenPosition(x: 100.0, y: 100.0)
      near = ScreenPosition(x: 100.0 + 0.5*LENGTH_MARKER_COMET, y: 100.0)
      drawn = cometFor(tail, near).get
    for point in drawn: check point.x >= tail.x - TOLERANCE_SINGLE


  test "a band with nowhere to point draws no head":
    # Cursor resting on its own source: ordinary moment in drag, not error.
    let at = ScreenPosition(x: 40.0, y: 90.0)
    check cometFor(at, at).isNone


  test "geometry standing for no shape gets no marker":
    check markerOf(POINT_A + PLANE).isNone
