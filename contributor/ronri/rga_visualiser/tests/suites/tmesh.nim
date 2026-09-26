## Run `Mesh` suite: one module of shared suite, which `../suites.nim` imports in order.

import ./fixtures


suite "Mesh":
  const
    VERTICES_RIBBON = 6 ## Vertices one ribbon is wound from: two triangles over four.
      ## corners.
      ##   Stated here rather than imported so that change to how `addSegment` winds quad has to be
      ##   noticed here too.
    HEIGHT_SCALE_TEST = 900 ## Framebuffer height `SCALE_TEST` measures its widths in.

  let SCALE_TEST = block:
    let eye = Position(x: 5, y: -3, z: 7)
    # Looking back at origin, which is where every fixture below is built around; screen
    #   axes about that sight axis as camera's frame lays them, right level and up over it.
    let
      forward = direction(toMultivector(eye) ∧ toMultivector(ORIGIN)).get
      level = cross(forward, Direction(x: 0, y: 0, z: 1))
      right = (1.0/norm(level))*level
    # `algebraFilled`, as every hand-built extent must be, or multivector twins.
    #   tessellation reads are zero and it silently draws nothing.
    algebraFilled(DrawExtent(scale: DrawScale(
      extent_furniture: 30.0,
      eye: eye, radius_horizon: 50.0,
      forward: forward, axis_right: right, axis_up: cross(right, forward),
      tangent_half_view: tan(0.5*degToRad(45.0)),
      height_pixels: HEIGHT_SCALE_TEST,
      depth_near: 0.1,
    )))
  ## Hold eye off-origin deliberately, since horizon geometry is anchored to eye.
    ## mistake, instead of to `eye`, would fail every horizon check below.
    ##   `extent_furniture` held distinct from `EXTENT_PLANE_F` (plane's own fixed
    ##   radius, no longer part of `DrawExtent` at all), so line test checking against
    ##   wrong one of two would fail rather than pass by coincidence.
    ##   Radius held modest rather than close to real far clip distance (hundreds of
    ##   units): vertices round-trip through `Vertex`'s own `float32` storage, and
    ##   `isNear`'s tolerance is calibrated for coordinates near same scale every
    ##   other geometry test in this suite uses, not for additional rounding much
    ##   larger radius would carry through unrelated to anything this suite tests here.

  test "an object's drawn centre is its own anchor, and only a plane's disc moves":
    # One reader everything that has to meet object on screen goes through:
    #   rubber-band leaving it, comet aimed from it, menu hanging off it. Plane's
    #   disc is centred on its creation anchor and every other shape ignores one, which is
    #   exactly what `mesh.addObject` does with same argument.
    let elsewhere = Position(x: -4.0, y: 6.0, z: 2.0)
    let
      point = GENERAL_POINTS[0]
      line = GENERAL_POINTS[1] ∧ GENERAL_POINTS[2]
      plane = GENERAL_POINTS[3] ∧ GENERAL_POINTS[4] ∧ GENERAL_POINTS[5]
    check anchorFor(plane, some(elsewhere), SCALE_TEST).get =~ elsewhere
    for m in [point, line]:
      check anchorFor(m, some(elsewhere), SCALE_TEST).get =~ anchorFor(m, SCALE_TEST).get
    # And with nothing stored, every shape falls back to where it always stood.
    for m in [point, line, plane]:
      check anchorFor(m, none(Position), SCALE_TEST).get =~ anchorFor(m, SCALE_TEST).get


  proc isRibbonDrawn(corners: array[6, Vertex]): bool =
    ## Say whether expansion is drawable quad or shader's refusal.
    ##   Refusal is six coincident vertices, for segment wholly behind eye or one eye
    ##   stands on.
    corners[0].x != corners[1].x or corners[0].y != corners[1].y or
      corners[0].z != corners[1].z

  proc isInsideGuard(place: Position; scale: DrawExtent = SCALE_TEST): bool =
    ## Say whether `place` stands inside guard pyramid ribbons are cut to.
    ##   See `mesh.FACTOR_GUARD`; four planes through eye, kept side positive.
    let
      slope = FACTOR_GUARD*scale.tangentHalfView
      offset = place - scale.eye
    for normal in [
      slope*scale.forward + -scale.axisRight, slope*scale.forward + scale.axisRight,
      slope*scale.forward + -scale.axisUp, slope*scale.forward + scale.axisUp,
    ]:
      if dot(offset, normal) < 0.0: return false
    true

  proc ringEnds(meshes: MeshSet; index, segment: int): (Position, Position) =
    ## Recover segment `segment`-th piece of `index`-th ring was built around.
    ##   By `ribbonEnds`'s own midpoint argument, through `expandRingVertex`, reference of
    ##   shader that widens it, so what is read back is what is drawn.
    proc midpoint(a, b: Vertex): Position =
      Position(
        x: 0.5*(float(a.x) + float(b.x)),
        y: 0.5*(float(a.y) + float(b.y)),
        z: 0.5*(float(a.z) + float(b.z)),
      )
    let corners = expandRingVertex(meshes.rings.records[index], segment, toScale(SCALE_TEST))
    (
      midpoint(corners[0], corners[5]),
      midpoint(corners[1], corners[2]),
    )


  proc ribbonEnds(
    meshes: MeshSet, index: int, scale: DrawExtent = SCALE_TEST
  ): (Position, Position) =
    ## Recover segment `index`-th ribbon was built around.
    ##   Each end's own two corners sit equal step either side of it, so their midpoint
    ##   is endpoint again.
    ##   Also property being asserted whenever this is used to check where line was
    ##   drawn: ribbon not centred on its own line would fail every one of those checks.
    proc midpoint(a, b: Vertex): Position =
      Position(
        x: 0.5*(float(a.x) + float(b.x)),
        y: 0.5*(float(a.y) + float(b.y)),
        z: 0.5*(float(a.z) + float(b.z)),
      )
    # Read through `expandRibbon`, reference of shader that does widening.
    #   What is read back is then clipped ends, as expanded storage holds them.
    let corners = expandRibbon(meshes.ribbons.records[index], toScale(scale))
    (
      midpoint(corners[0], corners[5]),
      midpoint(corners[1], corners[2]),
    )

  setup:
    MESHES.clearMeshes

  test "clearing drops every vertex and every record":
    MESHES.addMarker(ORIGIN, RADIUS_OBJECT_DEFAULT, Ink.Rose.colour, 1.0)
    MESHES.addSegment(ORIGIN, PLACES[0], Ink.Jade.colour, WIDTH_LINE_OBJECT)
    MESHES.addDisc(
      ORIGIN, Direction(x: 1.0, y: 0.0, z: 0.0), Direction(x: 0.0, y: 1.0, z: 0.0),
      1.0, Ink.Olive.colour,
    )
    MESHES.addDome(ORIGIN, 5.0, Ink.Cobalt.colour)
    MESHES.clearMeshes
    check MESHES.points.count_vertices == 0
    check MESHES.ribbons.count == 0
    check MESHES.discs.count == 0
    check MESHES.domes.count == 0
    check MESHES.veils.count == 0

  test "every record is stored about the origin its frame was cleared with":
    # Five writers, one rule: subtract `origin` at float32 write, so what camera looks at.
    #   million units from world origin is stored exact; see `mesh.clearMeshes`.
    let origin = Position(x: 1.0e6, y: -2.0e6, z: 3.0e5)
    MESHES.clearMeshes(origin)
    check MESHES.origin =~ origin
    let at = origin + Direction(x: 0.25, y: 0.5, z: -0.125)
    MESHES.addMarker(at, RADIUS_OBJECT_DEFAULT, Ink.Rose.colour, 1.0)
    let vertex = MESHES.points.vertices[0]
    check float(vertex.x) == 0.25 and float(vertex.y) == 0.5 and float(vertex.z) == -0.125
    MESHES.addSegment(at, at + Direction(x: 1.0, y: 0.0, z: 0.0), Ink.Rose.colour, 1.0)
    let ribbon = MESHES.ribbons.records[0]
    check float(ribbon.tail_x) == 0.25 and float(ribbon.head_x) == 1.25
    check float(ribbon.tail_z) == -0.125 and float(ribbon.head_z) == -0.125
    MESHES.addDisc(
      at, Direction(x: 1.0, y: 0.0, z: 0.0), Direction(x: 0.0, y: 1.0, z: 0.0), 1.0,
      Ink.Rose.colour,
    )
    check float(MESHES.discs.records[0].centre_y) == 0.5
    MESHES.addRing(
      at, Direction(x: 1.0, y: 0.0, z: 0.0), Direction(x: 0.0, y: 1.0, z: 0.0), 1.0,
      Ink.Rose.colour, 1.0,
    )
    check float(MESHES.rings.records[0].centre_z) == -0.125
    MESHES.addDome(at, 5.0, Ink.Rose.colour)
    check float(MESHES.domes.records[0].centre_x) == 0.25
    # Cleared without one is world origin again: nothing stays relative by accident.
    MESHES.clearMeshes
    check MESHES.origin =~ ORIGIN_WORLD


  test "point becomes one marker where it stands":
    for i in 0 ..< SAMPLES:
      MESHES.clearMeshes
      check MESHES.addObject(SCRATCH, POINTS[i], Ink.Rose.colour, SCALE_TEST) == Outcome.Finite
      check MESHES.points.count_vertices == 1
      check 6*MESHES.ribbons.count == 0
      check isNear(MESHES.points.vertices[0].toPosition, PLACES[i])


  test "line becomes two segments, each running from support to a vanishing point":
    for line in LINES:
      MESHES.clearMeshes
      check MESHES.addObject(SCRATCH, line, Ink.Jade.colour, SCALE_TEST) == Outcome.Finite
      check 6*MESHES.ribbons.count == 2*VERTICES_RIBBON
      # No point marker: line's own segment already passes through its support, so.
      #   marking that point again would only add stray dot segment does not need.
      check MESHES.points.count_vertices == 0
      let (anchor, axis) = (positionAnchor(line), direction(line))
      check anchor.isSome and axis.isSome
      let
        (tail_first, head_first) = ribbonEnds(MESHES, 0)
        (tail_second, head_second) = ribbonEnds(MESHES, 1)
      # Both halves start on line, at its support, so they meet with no gap.
      check isNear(tail_first, anchor.get)
      check isNear(tail_second, anchor.get)
      # Each runs toward one of line's own two vanishing points, both fixed to.
      #   eye. It *reaches* that point only where point is in front of camera:
      #   ribbon is clipped to near plane first, since width proportional to
      #   depth is meaningless behind eye (see `addSegment`). So what is asserted is
      #   direction each half runs in, plus that its end stands in front.
      for (head, vanishing) in [
        (head_first, SCALE_TEST.eye + SCALE_TEST.radiusHorizon*axis.get),
        (head_second, SCALE_TEST.eye - SCALE_TEST.radiusHorizon*axis.get),
      ]:
        let
          toward = normalize(head - anchor.get)
          reach = normalize(vanishing - anchor.get)
        check toward.isSome and reach.isSome
        # Compared with tolerance rather than through `=~`: these are read back out of.
        #   `Vertex`'s own float32 storage, which `=~`'s exact-math tolerance is tighter
        #   than.
        check abs(toward.get.x - reach.get.x) < 1.0e-4
        check abs(toward.get.y - reach.get.y) < 1.0e-4
        check abs(toward.get.z - reach.get.z) < 1.0e-4
        check dot(head - SCALE_TEST.eye, SCALE_TEST.forward) >= SCALE_TEST.depthNear - 1e-6
        # And it is either vanishing point itself or short of it, never past.
        check norm(head - anchor.get) <= norm(vanishing - anchor.get)*(1.0 + 1e-5)


  test "a drawn line projects onto the true line, however far its ends leave it":
    # Each half has one end on line and one at `eye +- radius*axis`, so both lie in.
    #   plane through eye containing line. That plane projects to single
    #   screen line, which is what lets far ends sit well off line in world
    #   space -- displaced along view ray -- without drawing showing it.
    let camera = cameraAround(Position(x: 0, y: 0, z: 1), 19.0, Direction(x: 8, y: 14, z: 7))
    let
      eye = camera.eye
      frame_camera = camera.frame
      radius = radiusHorizonFor(camera.distanceFar(0.0))
    proc screen(p: Position): (float, float) =
      let v = p - eye
      (dot(v, frame_camera.axis_right)/dot(v, frame_camera.forward),
       dot(v, frame_camera.axis_up)/dot(v, frame_camera.forward))
    for line in LINES:
      let (anchor, axis) = (positionAnchor(line).get, direction(line).get)
      let
        (ax, ay) = screen(anchor)
        (bx, by) = screen(anchor + 5.0*axis) # Second point on TRUE line.
        length = hypot(bx - ax, by - ay)
        (ux, uy) = ((bx - ax)/length, (by - ay)/length)
      for reach in [radius, -radius]:
        let far_end = eye + reach*axis
        # Reject any end that falls behind eye, where projection is meaningless.
        if dot(far_end - eye, frame_camera.forward) <= camera.distanceNear: continue
        let (fx, fy) = screen(far_end)
        # Perpendicular screen distance of drawn end from true line's own ray.
        check abs((fx - ax)*uy - (fy - ay)*ux) < 1e-9


  test "a line's near crossing holds its place with the camera close on the line":
    # Crossing was stepped from end being cut away -- `head + fraction*(tail - head)`,
    #   fraction hair under one where head is far end -- so difference of two places
    #   decades apart carried whole rounding of far one. Line is drawn out to its
    #   vanishing point, `radius_horizon` away, which orrery puts half million units
    #   off, and near plane is four-hundredth of orbit distance: camera close on moon
    #   leaves that difference carrying hundreds of pixels at plane it lands on.
    #   Stepping from end crossing stands nearer keeps rounding proportional to short step.
    #   Holds reference alone; shaders carry same arithmetic and are read by driven check
    #   `driveLineCrossing`.
    const
      REACH_VANISHING = 530_000.0
        ## Reach orrery draws line to, its farthest star's own distance.
      DISTANCE_CLOSE = 1.0e-7
        ## Orbit distance of close-up on moon, well over `camera.DISTANCE_LIMIT_NEAR`.
    let
      eye_close = ORIGIN
      forward_close = Direction(x: 1.0, y: 0.0, z: 0.0)
      # Unit by construction, and slanted across sight axis so eye stands off line.
      along = Direction(x: 0.6, y: 0.8, z: 0.0)
      # Line runs through what camera looks at, and its anchor is unit out along it,
      #   which is where support point lands in orrery.
      through = eye_close + DISTANCE_CLOSE*forward_close
      SCALE_CLOSE = algebraFilled(DrawExtent(scale: DrawScale(
        extent_furniture: 30.0,
        eye: eye_close, radius_horizon: REACH_VANISHING,
        forward: forward_close,
        tangent_half_view: tan(0.5*degToRad(45.0)),
        height_pixels: HEIGHT_SCALE_TEST,
        depth_near: DISTANCE_CLOSE*FACTOR_CLIP_NEAR,
      )))
    MESHES.clearMeshes
    MESHES.addSegment(
      through + 1.0*along, eye_close - REACH_VANISHING*along, Ink.Jade.colour,
      WIDTH_LINE_OBJECT,
    )
    let corners = expandRibbon(MESHES.ribbons.records[0], toScale(SCALE_CLOSE))
    check isRibbonDrawn(corners)
    # Crossing as record itself stores its ends, stepped from end it stands nearer:
    #   what is under test is which end is stepped from, not what float32 storage kept.
    let
      record = MESHES.ribbons.records[0]
      stored_tail = Position(
        x: float(record.tail_x), y: float(record.tail_y), z: float(record.tail_z))
      stored_head = Position(
        x: float(record.head_x), y: float(record.head_y), z: float(record.head_z))
      depth_tail = dot(stored_tail - eye_close, forward_close)
      depth_head = dot(stored_head - eye_close, forward_close)
      toward_head = (SCALE_CLOSE.depthNear - depth_tail)/(depth_head - depth_tail)
      crossing = stored_tail + toward_head*(stored_head - stored_tail)
      (_, far_drawn) = ribbonEnds(MESHES, 0, SCALE_CLOSE)
    # Within one pixel of where it stands, measured at plane it lands on.
    check norm(far_drawn - crossing) <= worldPerPixelAt(far_drawn, toScale(SCALE_CLOSE))


  test "a ribbon is cut to the guard pyramid just where the algebra's planes cut it":
    # Ribbon crossing near plane close by eye projected its cut end million pixels off screen,
    #   and GPU's interpolation over so stretched quad ran colour off ink, depth 55% too near.
    #   Reference cuts to pyramid through eye, `FACTOR_GUARD` half-views wide; each drawn end
    #   is held here to meet of segment with plane, `clipToEyeSide` chained over near plane
    #   and four guard planes. 400 segments, long enough to leave pyramid on every side.
    let
      scale = toScale(SCALE_TEST)
      slope = FACTOR_GUARD*scale.tangentHalfView
      eye = toMultivector(scale.eye)
      planes = [
        planeThrough(
          add(eye, wedge(scale.depthNear, toMultivector(scale.forward))),
          toMultivector(scale.forward),
        ),
        planeThrough(eye, toMultivector(slope*scale.forward + -scale.axis_right)),
        planeThrough(eye, toMultivector(slope*scale.forward + scale.axis_right)),
        planeThrough(eye, toMultivector(slope*scale.forward + -scale.axis_up)),
        planeThrough(eye, toMultivector(slope*scale.forward + scale.axis_up)),
      ]
    var seed = 29.0
    proc pseudo(): float =
      seed = (seed*97.31 + 33.77) mod 41.0
      (seed - 20.5)/20.5
    var (count_cut, count_gone) = (0, 0)
    for trial in 0 ..< 400:
      MESHES.clearMeshes
      MESHES.addSegment(
        scale.eye + Direction(x: 40.0*pseudo(), y: 40.0*pseudo(), z: 40.0*pseudo()),
        scale.eye + Direction(x: 40.0*pseudo(), y: 40.0*pseudo(), z: 40.0*pseudo()),
        Ink.Jade.colour, WIDTH_LINE_OBJECT,
      )
      # Ends as record stores them, so both sides start from same float32 places.
      let record = MESHES.ribbons.records[0]
      var kept = some((
        Position(x: float(record.tail_x), y: float(record.tail_y), z: float(record.tail_z)),
        Position(x: float(record.head_x), y: float(record.head_y), z: float(record.head_z)),
      ))
      let whole = kept.get
      for plane in planes:
        if kept.isNone: break
        kept = clipToEyeSide(kept.get[0], kept.get[1], plane)
      let corners = expandRibbon(record, scale)
      if kept.isNone:
        inc count_gone
        check not isRibbonDrawn(corners)
        continue
      check isRibbonDrawn(corners)
      let (tail_drawn, head_drawn) = ribbonEnds(MESHES, 0)
      if norm(kept.get[0] - whole[0]) + norm(kept.get[1] - whole[1]) > 0.0: inc count_cut
      for (drawn, wanted) in [(tail_drawn, kept.get[0]), (head_drawn, kept.get[1])]:
        check norm(drawn - wanted) <= TOLERANCE_SINGLE*max(1.0, norm(wanted - scale.eye))
    # Sample reaches each case it claims to.
    check count_cut > 20
    check count_gone > 20


  test "line's own far end coincides exactly with where its attitude is drawn":
    # Property "lines look cut off" feedback chased: line and its own.
    #   attitude are two different objects (finite segment and horizon point)
    #   drawn through two different branches of `mesh`, so nothing forces them to
    #   agree geometrically unless segment's own far end is deliberately built to
    #   land on same point horizon marker would.
    for line in LINES:
      let attitude = ⊖ line
      MESHES.clearMeshes
      discard MESHES.addObject(SCRATCH, attitude, Ink.Cobalt.colour, SCALE_TEST)
      let star = MESHES.points.vertices[0].toPosition

      MESHES.clearMeshes
      discard MESHES.addObject(SCRATCH, line, Ink.Jade.colour, SCALE_TEST)
      let (_, far_first) = ribbonEnds(MESHES, 0)
      let (_, far_second) = ribbonEnds(MESHES, 1)
      proc headOf(index: int): Position =
        let record = MESHES.ribbons.records[index]
        Position(x: float(record.head_x), y: float(record.head_y), z: float(record.head_z))
      # Whichever half runs toward star has to land on it -- but only where star.
      #   itself stands in front of near plane. Ribbon is clipped there (see
      #   `mesh.addSegment`), so star behind camera is met by half that stops at
      #   near plane instead. Nothing is visible there either way; what would be
      #   real defect is gap between two *on screen*, which this still catches.
      #   Record's own far end is held to star wherever star stands in front; drawn end
      #   wherever star stands inside guard pyramid too, since past it drawing is cut
      #   (`mesh.FACTOR_GUARD`) eight half-views off screen.
      if dot(star - SCALE_TEST.eye, SCALE_TEST.forward) >= SCALE_TEST.depthNear:
        check isNear(headOf(0), star) or isNear(headOf(1), star)
        if isInsideGuard(star):
          check isNear(far_first, star) or isNear(far_second, star)


  test "disc is hit under a grazing eye nearer than the near plane, and boxed by its sphere":
    # Record as `addDisc` writes ecliptic's: radius eight about origin, in ground plane.
    let record = DiscRecord(arm_first_x: 8.0, arm_second_y: 8.0, fill_alpha: 1.0)
    let
      (right, up, forward) =
        (Direction(x: 0, y: -1, z: 0), Direction(x: 0, y: 0, z: 1), Direction(x: 1, y: 0, z: 0))
      height = 2.6e-6
      eye = Position(x: -0.13, y: 0.0, z: height)
      tangent = 0.443
    # Ray half way down view meets plane 1.2e-5 ahead, under near plane at 1/400 of 0.13:
    #   band fan's near cut lost, and ray finds.
    let down = rayThroughView(0.0, -0.5, right, up, forward, tangent, 1.0)
    let hit = hitDiscAlong(record, eye, down)
    check hit.isSome
    check isNear(hit.get, height/(0.5*tangent))
    check hit.get < 0.13*FACTOR_CLIP_NEAR
    # Ray half way up meets plane behind eye; ray along sight axis runs along plane.
    check hitDiscAlong(
      record, eye, rayThroughView(0.0, 0.5, right, up, forward, tangent, 1.0)
    ).isNone
    check hitDiscAlong(record, eye, forward).isNone
    # Sphere holds eye, so box is whole view.
    let box = viewBoxOfDisc(record, eye, right, up, forward, tangent, 1.0)
    check box.lo == (-1.0, -1.0) and box.hi == (1.0, 1.0)
    # From ten units above, disc of radius one subtends 5.74 degrees each way: box is its
    #   tangent over view's, aspect widening across; rim is hit just inside and missed just
    #   outside, at depth ten.
    let
      small = DiscRecord(arm_first_x: 1.0, arm_second_y: 1.0, fill_alpha: 1.0)
      above = Position(x: 0.0, y: 0.0, z: 10.0)
      (right_down, up_down, forward_down) =
        (Direction(x: 1, y: 0, z: 0), Direction(x: 0, y: 1, z: 0), Direction(x: 0, y: 0, z: -1))
      box_small = viewBoxOfDisc(small, above, right_down, up_down, forward_down, 0.5, 2.0)
      limb = tan(arcsin(0.1))
    check isNear(box_small.hi[0], limb/(0.5*2.0)) and isNear(box_small.lo[0], -limb/(0.5*2.0))
    check isNear(box_small.hi[1], limb/0.5) and isNear(box_small.lo[1], -limb/0.5)
    let inside = hitDiscAlong(small, above, Direction(x: 0.099, y: 0.0, z: -1.0))
    check inside.isSome and isNear(inside.get, 10.0)
    check hitDiscAlong(small, above, Direction(x: 0.101, y: 0.0, z: -1.0)).isNone
    # Corner lands on box's middle at `(0, 0)` and root two out at rim corner.
    let corner = expandDiscCorner(box_small, 1.0, 0.0)
    check isNear(corner[0], sqrt(2.0)*box_small.hi[0]) and isNear(corner[1], 0.0)
    check expandDiscCorner(box_small, 0.0, 0.0) == (0.0, 0.0)
    # Disc behind eye: box is empty.
    let box_behind = viewBoxOfDisc(
      small, Position(x: 0.0, y: 0.0, z: -10.0), right_down, up_down, forward_down, 0.5, 2.0
    )
    check box_behind.lo == box_behind.hi


  test "plane becomes a flat filled disc and a rim, every vertex on it":
    for plane in PLANES:
      MESHES.clearMeshes
      check MESHES.addObject(SCRATCH, plane, Ink.Olive.colour, SCALE_TEST) == Outcome.Finite
      const SEGMENTS_RING = SEGMENTS_CIRCLE_HORIZON
      # One disc record in one veil run: fan itself is shader's now, and.
      #   `expandDiscVertex` -- its reference -- is what its corners are read through.
      check MESHES.discs.count == 1
      check MESHES.veils.count == 1
      # Rim and nothing else, and rim is **one record**: ring, not.
      #   `SEGMENTS_CIRCLE_HORIZON` ribbons. Plane used to add one ribbon more for
      #   normal shaft out of its anchor; orientation now rides on selection marker's
      #   own pulse, so unselected plane draws no such thing -- and no ribbon at all.
      check MESHES.rings.count == 1
      check MESHES.ribbons.count == 0
      # No point marker at all: neither anchor marker nor normal arrowhead, so.
      #   plane never adds scattered dot beyond what fill and rim already draw.
      check MESHES.points.count_vertices == 0
      # Vertex lies on plane exactly when its offset from support is normal to normal.
      let (anchor, normal) = (positionAnchor(plane), directionNormal(plane))
      check anchor.isSome and normal.isSome
      # Disc is spanned over view box of its sphere and filled by fragment's own ray:
      #   `viewBoxOfDisc` and `hitDiscAlong` -- its references -- are what is read here.
      #   Every rim point in front of eye projects inside box, clamped to view as box is;
      #   ray through centre lands at centre's depth; alpha is veil's, flat.
      let
        record = MESHES.discs.records[0]
        (eye, right, up, forward) =
          (SCALE_TEST.eye, SCALE_TEST.axisRight, SCALE_TEST.axisUp, SCALE_TEST.forward)
        tangent = SCALE_TEST.tangentHalfView
        box = viewBoxOfDisc(record, eye, right, up, forward, tangent, 1.0)
      check isNear(float(record.fill_alpha), ALPHA_VEIL)
      for i in 0 .. SEGMENTS_CIRCLE_HORIZON:
        let
          (cos_angle, sin_angle) = (UNIT_CIRCLE_RIM[i].cos_angle, UNIT_CIRCLE_RIM[i].sin_angle)
          on_rim = Direction(
            x: float(record.centre_x) + cos_angle*float(record.arm_first_x) +
              sin_angle*float(record.arm_second_x) - eye.x,
            y: float(record.centre_y) + cos_angle*float(record.arm_first_y) +
              sin_angle*float(record.arm_second_y) - eye.y,
            z: float(record.centre_z) + cos_angle*float(record.arm_first_z) +
              sin_angle*float(record.arm_second_z) - eye.z,
          )
          depth = dot(on_rim, forward)
        if depth <= SCALE_TEST.depthNear: continue
        let
          across = clamp(dot(on_rim, right)/(depth*tangent), -1.0, 1.0)
          rise = clamp(dot(on_rim, up)/(depth*tangent), -1.0, 1.0)
        check across >= box.lo[0] - 1.0e-9 and across <= box.hi[0] + 1.0e-9
        check rise >= box.lo[1] - 1.0e-9 and rise <= box.hi[1] + 1.0e-9
      let
        to_centre = anchor.get - eye
        depth_centre = dot(to_centre, forward)
      let ray = rayThroughView(
        dot(to_centre, right)/(depth_centre*tangent), dot(to_centre, up)/(depth_centre*tangent),
        right, up, forward, tangent, 1.0,
      )
      # Record's floats are narrowed, and ray grazing plane multiplies that into depth,
      #   so plane met under six degrees is left to its box check alone.
      if depth_centre > SCALE_TEST.depthNear and
          abs(dot(ray, normal.get)) > 0.1*norm(ray)*norm(normal.get):
        let hit = hitDiscAlong(record, eye, ray)
        check hit.isSome and isNear(hit.get, depth_centre)
      # Rim is drawn as line is, so its own *corners* stand half line width off.
      #   plane -- step sideways is perpendicular to segment and to sight
      #   ray, which is only in plane when eye happens to lie in it. What is still
      #   exactly on plane, and at exactly plane's own radius, is segment each
      #   piece was built around; `ringEnds` recovers it.
      #   Every segment of one record is walked, which is what makes record's
      #   fourteen floats provably same circle ninety-six ribbons drew.
      #   Segment is read off record itself (`ribbonOfRing`), which guard never touches;
      #   drawn piece of it, where guard keeps any, through `ringEnds`.
      for i in 0 ..< SEGMENTS_RING:
        let
          piece = ribbonOfRing(MESHES.rings.records[0], i)
          tail = Position(x: float(piece.tail_x), y: float(piece.tail_y), z: float(piece.tail_z))
          head = Position(x: float(piece.head_x), y: float(piece.head_y), z: float(piece.head_z))
        for place in [tail, head]:
          check isNear(dot(place - anchor.get, normal.get), 0)
          check isNear(norm(place - anchor.get), EXTENT_PLANE_F)
        let corners = expandRingVertex(MESHES.rings.records[0], i, toScale(SCALE_TEST))
        # Segment drawn as nothing stands wholly behind near plane or outside guard.
        if not isRibbonDrawn(corners):
          check max(dot(tail - SCALE_TEST.eye, SCALE_TEST.forward),
            dot(head - SCALE_TEST.eye, SCALE_TEST.forward)) < SCALE_TEST.depthNear or
            not (isInsideGuard(tail) or isInsideGuard(head))
          continue
        # Drawn piece lies on that segment's own line, on plane.
        let (tail_drawn, head_drawn) = ringEnds(MESHES, 0, i)
        for place in [tail_drawn, head_drawn]:
          check isNear(dot(place - anchor.get, normal.get), 0)
        # And every corner stays within that half width of plane, so bulge is.
        #   fraction of pixel on screen rather than anything reader could see.
        let bound = 0.5*float(WIDTH_LINE_OBJECT)*
          max(worldPerPixelAt(tail, SCALE_TEST), worldPerPixelAt(head, SCALE_TEST))
        for j in 0 ..< VERTICES_RIBBON:
          check isNear(float(corners[j].alpha), Ink.Olive.colour.alpha)
          check abs(dot(corners[j].toPosition - anchor.get, normal.get)) <= bound + 1e-5


  test "the ring's static corners are the circle's own angles, in the ribbon's winding":
    # **One table both ring shaders read, and only part of rim they are not.
    #   handed.** Shader reads segment's two angles from here and record supplies
    #   everything else, so table that drifted would move drawn circle with nothing
    #   else changing -- exactly failure `mesh.ringCorners` exists in Nim to prevent.
    #   What it must be is stated twice over: angles are `UNIT_CIRCLE_RIM`'s own
    #   consecutive pairs, and `(end, side)` half is `expandRibbon`'s own winding,
    #   which is what makes rim widen like every other line.
    const WINDING = [(0.0, -1.0), (1.0, -1.0), (1.0, 1.0), (0.0, -1.0), (1.0, 1.0),
      (0.0, 1.0)]
    let corners = ringCorners()
    check len(corners) == 6*6*SEGMENTS_CIRCLE_HORIZON
    for segment in 0 ..< SEGMENTS_CIRCLE_HORIZON:
      for corner in 0 ..< 6:
        let at = 6*(6*segment + corner)
        check isNear(float(corners[at + 0]), UNIT_CIRCLE_RIM[segment].cos_angle)
        check isNear(float(corners[at + 1]), UNIT_CIRCLE_RIM[segment].sin_angle)
        check isNear(float(corners[at + 2]), UNIT_CIRCLE_RIM[segment + 1].cos_angle)
        check isNear(float(corners[at + 3]), UNIT_CIRCLE_RIM[segment + 1].sin_angle)
        check float(corners[at + 4]) == WINDING[corner][0]
        check float(corners[at + 5]) == WINDING[corner][1]
    # And ends those angles name are very ends `ribbonOfRing` derives, which is.
    #   join between this table and reference shaders expand: place ring
    #   whose arms are world's own axes and check every segment against it.
    MESHES.clearMeshes
    MESHES.addRing(
      ORIGIN, Direction(x: 1.0, y: 0.0, z: 0.0), Direction(x: 0.0, y: 1.0, z: 0.0),
      2.0, Ink.Olive.colour, float(WIDTH_LINE_OBJECT),
    )
    for segment in 0 ..< SEGMENTS_CIRCLE_HORIZON:
      let
        at = 6*6*segment
        record = ribbonOfRing(MESHES.rings.records[0], segment)
      check isNear(float(record.tail_x), 2.0*float(corners[at + 0]))
      check isNear(float(record.tail_y), 2.0*float(corners[at + 1]))
      check isNear(float(record.head_x), 2.0*float(corners[at + 2]))
      check isNear(float(record.head_y), 2.0*float(corners[at + 3]))
      # Ring's tint and width reach both ends of every segment, flat: it is what lets.
      #   shaders drop ribbon's two-end blend and read one `fill`.
      check isNear(float(record.width), float(WIDTH_LINE_OBJECT))
      check isNear(float(record.tail_alpha), Ink.Olive.colour.alpha)
      check isNear(float(record.head_alpha), Ink.Olive.colour.alpha)
      check record.tail_red == record.head_red and record.tail_blue == record.head_blue


  test "the disc is stepped in arithmetic, and lands where the algebra says":
    # **Algebra is reference, not implementation.** Disc is stand-in.
    #   drawn for plane, not plane, so its rim and its fan are stepped with
    #   `euclid.onCircle`; what that is held against is multivector sum it replaced --
    #   centre plus two scaled arms, read back out as place. Swept over real plane
    #   frames rather than one contrived pair, since arms come from `boundary.frame`
    #   and claim about them should hold wherever it puts them.
    for plane in PLANES:
      let
        anchor = positionAnchor(plane)
        axes = frame(plane)
      check anchor.isSome and axes.isSome
      let
        centre_point = toMultivector(anchor.get)
        radius = EXTENT_PLANE_F
        arm_first = radius*axes.get.axis_first
        arm_second = radius*axes.get.axis_second
        arm_first_point = wedge(radius, toMultivector(axes.get.axis_first))
        arm_second_point = wedge(radius, toMultivector(axes.get.axis_second))
      # Record's own rim beside plain stepping: arms `hitDiscAlong` reads are what both
      #   disc fragment shaders bound by, so record's narrowed floats too must land on
      #   multivector sums, corner for corner, and ray from ten radii above cast at point
      #   just inside each corner lands on disc where one just outside misses.
      MESHES.clearMeshes
      MESHES.addDisc(
        anchor.get, axes.get.axis_first, axes.get.axis_second, radius, Ink.Olive.colour
      )
      let
        record = MESHES.discs.records[0]
        normal = directionNormal(plane)
      check normal.isSome
      let above = anchor.get + 10.0*radius*normal.get
      for i in 0 ..< SEGMENTS_CIRCLE_HORIZON:
        let
          angle = (2.0*PI * float(i)) / float(SEGMENTS_CIRCLE_HORIZON)
          stepped = onCircle(anchor.get, arm_first, arm_second, angle)
          assembled = pointFrom(add(centre_point, add(
            wedge(cos(angle), arm_first_point), wedge(sin(angle), arm_second_point),
          )))
          on_record = Position(
            x: float(record.centre_x) + cos(angle)*float(record.arm_first_x) +
              sin(angle)*float(record.arm_second_x),
            y: float(record.centre_y) + cos(angle)*float(record.arm_first_y) +
              sin(angle)*float(record.arm_second_y),
            z: float(record.centre_z) + cos(angle)*float(record.arm_first_z) +
              sin(angle)*float(record.arm_second_z),
          )
          spoke = assembled - anchor.get
          inside = hitDiscAlong(record, above, (anchor.get + 0.999*spoke) - above)
        check stepped =~ assembled
        check isNear(on_record, assembled)
        check inside.isSome and isNear(inside.get, 1.0)
        check hitDiscAlong(record, above, (anchor.get + 1.001*spoke) - above).isNone


  test "horizon point becomes a star fixed at eye plus its own direction":
    for line in LINES:
      MESHES.clearMeshes
      let attitude = ⊖ line
      check MESHES.addObject(SCRATCH, attitude, Ink.Cobalt.colour, SCALE_TEST) == Outcome.Horizon
      check MESHES.points.count_vertices == 1
      let
        heading = directionHorizon(attitude)
        star = MESHES.points.vertices[0].toPosition
      check heading.isSome
      check isNear(star, SCALE_TEST.eye + SCALE_TEST.radiusHorizon*heading.get)


  test "horizon line becomes a great circle around eye, perpendicular to its normal":
    var count_showable = 0
    for plane in PLANES:
      MESHES.clearMeshes
      let attitude = ⊖ plane
      check MESHES.addObject(SCRATCH, attitude, Ink.Jade.colour, SCALE_TEST) == Outcome.Horizon
      # One record for whole circle now, drawn or not: segment wholly behind.
      #   camera is *shader's* to reject, and `expandRingVertex` -- its reference --
      #   reports it as six coincident vertices. About half circle stands behind
      #   eye, so drawn count must fall well short of full ring; both halves of
      #   that are held below rather than assumed.
      check MESHES.rings.count == 1
      check MESHES.ribbons.count == 0
      const SEGMENTS_RING = SEGMENTS_CIRCLE_HORIZON
      var count_drawn = 0
      # `directionNormalHorizon` reads straight off horizon line's own raw.
      #   coefficients; confirm it agrees with finite plane's own normal, read
      #   through wholly different pair of library operators, before trusting either
      #   to check where circle itself landed.
      let
        normal_from_plane = directionNormal(plane)
        normal_from_horizon = directionNormalHorizon(attitude)
      check normal_from_plane.isSome and normal_from_horizon.isSome
      check normal_from_plane.get =~ normal_from_horizon.get
      # Checked on segment each piece was built around rather than on its corners:
      #   corner stands half line width off that segment, so it is neither exactly on
      #   circle's own radius nor exactly in its plane. See plane rim above.
      var count_at_radius = 0
      # Whether any end stands in front and inside guard pyramid, which is where ring
      #   must show; past guard, drawing is cut (`mesh.FACTOR_GUARD`) off screen.
      var is_showable = false
      for i in 0 ..< SEGMENTS_RING:
        let piece = ribbonOfRing(MESHES.rings.records[0], i)
        for place in [
          Position(x: float(piece.tail_x), y: float(piece.tail_y), z: float(piece.tail_z)),
          Position(x: float(piece.head_x), y: float(piece.head_y), z: float(piece.head_z)),
        ]:
          let offset = place - SCALE_TEST.eye
          # Record's own segment is on circle exactly, drawn or not.
          check isNear(dot(offset, normal_from_plane.get), 0)
          check isNear(norm(offset), SCALE_TEST.radiusHorizon)
          if dot(offset, SCALE_TEST.forward) > SCALE_TEST.depthNear and isInsideGuard(place):
            is_showable = true
        # Skip what shader will not draw; coincident corners are its refusal.
        let corners = expandRingVertex(MESHES.rings.records[0], i, toScale(SCALE_TEST))
        if not isRibbonDrawn(corners): continue
        count_drawn += 1
        let (tail, head) = ringEnds(MESHES, 0, i)
        for place in [tail, head]:
          let offset = place - SCALE_TEST.eye
          # In circle's own plane exactly, clipped or not: clip slides point.
          #   along chord, which lies in that plane too.
          check isNear(dot(offset, normal_from_plane.get), 0)
          # And out at circle's own radius, unless clip pulled it in along that.
          #   chord -- never past it.
          check norm(offset) <= SCALE_TEST.radiusHorizon*(1.0 + 1e-5)
          if isNear(norm(offset), SCALE_TEST.radiusHorizon): inc count_at_radius
      # Half-behind claim, held rather than assumed: some of ring is drawn wherever some
      #   stands in view, and well under all of it.
      check count_drawn < SEGMENTS_RING
      if is_showable:
        inc count_showable
        check count_drawn >= 1
        check count_at_radius > 0
    # Sample reaches circles in view, so claims above are exercised, not skipped.
    check count_showable * 2 >= PLANES.len


  test "horizon plane becomes a dome over the whole sky around eye":
    # Every horizon plane is same universal object regardless of source (see.
    #   `objects.directionNormalHorizon`'s own doc comment), so two unrelated planes'
    #   own attitudes should both land dome at exactly same distance from eye,
    #   with nothing about either plane's own coefficients read to decide it.
    #   Attitude of plane (grade 3) gives horizon line, not plane: reaching
    #   horizon plane needs grade-4 volume first, built here from point wedged
    #   with unrelated plane it does not lie on.
    let
      volume_first = POINTS[10] ∧ PLANES[0]
      volume_second = POINTS[20] ∧ PLANES[7]
      attitude_first = ⊖ volume_first
      attitude_second = ⊖ volume_second
    check kindOf(attitude_first) == some(Kind.Plane) and isHorizon(attitude_first)
    check kindOf(attitude_second) == some(Kind.Plane) and isHorizon(attitude_second)

    check MESHES.addObject(SCRATCH, attitude_first, Ink.Cobalt.colour, SCALE_TEST) ==
      Outcome.Horizon
    # One dome record in one veil run: sphere itself is static geometry shader.
    #   widens, and `expandDomeVertex` -- its reference -- is what its corners are read
    #   through.
    check MESHES.domes.count == 1
    check MESHES.veils.count == 1
    let
      record_first = MESHES.domes.records[0]
      corners_dome = domeCorners()
    for i in 0 ..< 6*LATITUDES_HORIZON*LONGITUDES_HORIZON:
      let unit = Direction(
        x: float(corners_dome[3*i]),
        y: float(corners_dome[3*i + 1]),
        z: float(corners_dome[3*i + 2]),
      )
      let offset = expandDomeVertex(record_first, unit).toPosition - SCALE_TEST.eye
      check isNear(norm(offset), SCALE_TEST.radiusHorizon)

    MESHES.clearMeshes
    check MESHES.addObject(SCRATCH, attitude_second, Ink.Cobalt.colour, SCALE_TEST) ==
      Outcome.Horizon
    check MESHES.domes.count == 1
    # Same dome, field for field, regardless of which unrelated volume produced it.
    let record_second = MESHES.domes.records[0]
    check isNear(float(record_second.centre_x), float(record_first.centre_x))
    check isNear(float(record_second.centre_y), float(record_first.centre_y))
    check isNear(float(record_second.centre_z), float(record_first.centre_z))
    check isNear(float(record_second.radius), float(record_first.radius))


  test "multivector of no geometry becomes nothing at all":
    for empty in [1.0 ∧ initElement(Basis.scalar), 1.0 + POINTS[0]]:
      MESHES.clearMeshes
      check MESHES.addObject(SCRATCH, empty, Ink.Rose.colour, SCALE_TEST) == Outcome.Empty
      check MESHES.points.count_vertices == 0
      check MESHES.ribbons.count == 0
      check MESHES.discs.count == 0
      check MESHES.domes.count == 0


  test "a scene filled with planes fits the bounds the record meshes reserve":
    # Binding case for `RIBBONS_MAX` and `DISCS_MAX`: plane draws most ribbons.
    #   of any object and one disc besides, and every record append asserts rather than
    #   overflowing. Built rather than calculated, so bounds are checked against what
    #   is actually emitted rather than against arithmetic that could drift from it.
    MESHES.clearMeshes
    var built = 0
    for i in 0 ..< OBJECTS_MAX:
      let angle = 0.7*float(i)
      let plane =
        toMultivector(Position(x: 6.0*cos(angle), y: 6.0*sin(angle), z: 0.15*float(i))) ∧
        toMultivector(Position(x: 6.0*cos(angle + 0.4), y: 1.0, z: 2.0 + 0.1*float(i))) ∧
        toMultivector(Position(x: 1.0, y: 6.0*sin(angle + 0.9), z: -1.0))
      if MESHES.addObject(SCRATCH, plane, Ink.Olive.colour, SCALE_TEST) == Outcome.Finite:
        inc built
    check built == OBJECTS_MAX
    check MESHES.ribbons.count <= RIBBONS_MAX
    check MESHES.discs.count <= DISCS_MAX
    check MESHES.veils.count <= len(MESHES.veils.runs)


  func scaleFurnitureAt(eye: Position, extent: float): DrawExtent =
    ## Place eye somewhere, with stated furniture reach, for fog cases below.
    ##   `SCALE_TEST` cannot serve them: its fog reach is shorter than its eye's height,
    ##   so its fog never reaches ground and no grid is drawn at all.
    ##   Fog case needs eye standing inside its own fog, and several need it far from
    ##   origin, which is whole point of rule being checked.
    algebraFilled(DrawExtent(scale: DrawScale(
      extent_furniture: extent,
      eye: eye, radius_horizon: extent,
      # Looking little ahead and down, which every ground fixture below lies under.
      forward: direction(
        toMultivector(eye) ∧ toMultivector(Position(x: eye.x + 1.0, y: eye.y, z: 0.0))
      ).get,
      tangent_half_view: tan(0.5*degToRad(45.0)),
      height_pixels: HEIGHT_SCALE_TEST,
      depth_near: 0.1,
    )))

  let SCALE_FOG = scaleFurnitureAt(Position(x: 103, y: -97, z: 5), 300.0)
    ## Place eye inside its own fog.
    ##   Reach of 300 fades out well past five units eye stands above ground.
    ##   Stood few units off lattice crossing rather than anywhere convenient, so that
    ##   hundred-unit cell actually lays line through fog's solid core.
    ##     Nearest lines are three units away, and eye parked between crossings would
    ##     leave core empty and fade case with nothing to measure.


  test "world furniture stays inside the fog it is drawn in":
    MESHES.clearMeshes
    MESHES.addAxes(SCRATCH, SCALE_FOG.extentFurniture, SCALE_FOG)
    MESHES.addLattice(SCRATCH, SCALE_FOG.extentFurniture, SCALE_FOG, groundPlane())
    check 6*MESHES.ribbons.count > 0
    let fog = fogFurnitureFor(SCALE_FOG.extentFurniture)
    for i in 0 ..< MESHES.ribbons.count:
      # Expanded through reference of shader that now does widening, with.
      #   slack of one unit for half-width it steps each corner off by.
      let corners = expandRibbon(MESHES.ribbons.records[i], toScale(SCALE_FOG))
      if not isRibbonDrawn(corners): continue
      for vertex in corners:
        check norm(vertex.toPosition - SCALE_FOG.eye) <= fog.radius_gone + 1.0


  test "world furniture is fog about the camera, not a halo about the origin":
    # Rule this project had before: furniture was laid about world origin and.
    #   reader who panned away from it lost ground entirely. Both halves are checked,
    #   since either alone passes under old behaviour.
    let scale_afar = scaleFurnitureAt(Position(x: 1000, y: -700, z: 6), 300.0)
    MESHES.clearMeshes
    MESHES.addLattice(SCRATCH, scale_afar.extentFurniture, scale_afar, groundPlane())
    check 6*MESHES.ribbons.count > 0
    let fog = fogFurnitureFor(scale_afar.extentFurniture)
    for i in 0 ..< MESHES.ribbons.count:
      let corners = expandRibbon(MESHES.ribbons.records[i], toScale(scale_afar))
      if not isRibbonDrawn(corners): continue
      for vertex in corners:
        check norm(vertex.toPosition - scale_afar.eye) <= fog.radius_gone + 1.0
        check norm(vertex.toPosition - ORIGIN) > fog.radius_gone


  test "a lattice holds full alpha near the camera and fades to nothing at its reach":
    # Fade runs per fragment in shaders now, so what records carry is.
    #   grid's own full tint with fog *flag* set, and drawn alpha is that tint
    #   times `alphaGridFade` -- reference both fragment shaders are held to --
    #   evaluated here at each corner's own distance from eye, exactly as they do.
    MESHES.clearMeshes
    MESHES.addLattice(SCRATCH, SCALE_FOG.extentFurniture, SCALE_FOG, groundPlane())
    let fog = fogFurnitureFor(SCALE_FOG.extentFurniture)
    var
      alpha_near_min = 1.0
      alpha_far_max = 0.0
      count_near = 0
    for i in 0 ..< MESHES.ribbons.count:
      let record = MESHES.ribbons.records[i]
      check record.fog > 0.5
      check isNear(float(record.tail_alpha), Ink.Grid.colour.alpha*ALPHA_GRID)
      check isNear(float(record.head_alpha), Ink.Grid.colour.alpha*ALPHA_GRID)
      # Sampled *along* each record rather than at its corners alone: line is one.
      #   record spanning its whole chord now, and fade is fragment's, evaluated
      #   at every point of it -- so claim is checked where fragments are.
      let
        tail = Position(
          x: float(record.tail_x),
          y: float(record.tail_y),
          z: float(record.tail_z),
        )
        head = Position(
          x: float(record.head_x),
          y: float(record.head_y),
          z: float(record.head_z),
        )
        count_samples = 32
      for step in 0 .. count_samples:
        let
          t = float(step)/float(count_samples)
          at = tail + t*(head - tail)
          radius = norm(at - SCALE_FOG.eye)
          alpha_drawn = float(record.tail_alpha)*alphaGridFade(
            radius, fog.radius_full, fog.radius_gone)
        if radius <= fog.radius_full:
          alpha_near_min = min(alpha_near_min, alpha_drawn)
          inc count_near
        if radius >= fog.radius_gone - TOLERANCE_TEST:
          alpha_far_max = max(alpha_far_max, alpha_drawn)
    check count_near > 0
    check isNear(alpha_near_min, Ink.Grid.colour.alpha*ALPHA_GRID)
    check alpha_far_max <= TOLERANCE_SINGLE


  test "the grid reads as reference: dimmer than the ink an object of that colour takes":
    # `Ink.Grid` is also `INK_POOL_FREE`, so dimming has to live in grid rather.
    #   than in palette entry; object taking that ink must stay opaque.
    check ALPHA_GRID < 1.0
    check isNear(Ink.Grid.colour.alpha, 1.0)


  test "the join's normal is the classical cross product, sign included":
    # `mesh.directionAcross` IS join -- `directionNormal(tail ∧ head ∧ eye)` -- and.
    #   this holds algebra against classical cross product computed HERE, in
    #   test, which is project's purpose. **Sign included**: agreement up to sign
    #   would let ribbon's two edges swap sides without word from suite.
    var seed = 1.0
    proc pseudo(): float =
      # Deterministic scatter, so failure names same triple on every run.
      seed = (seed*97.31 + 33.77) mod 41.0
      seed - 20.5
    for trial in 0 ..< 200:
      let
        tail = Position(x: pseudo(), y: pseudo(), z: pseudo())
        head = Position(x: pseudo(), y: pseudo(), z: pseudo())
        eye = Position(x: pseudo(), y: pseudo(), z: pseudo())
        computed = directionAcross(tail, head, eye)
        # **Algebra is reference now, not implementation.** Shipped form is.
        #   cross product, because ribbon's width is picture's business and not
        #   geometry's; what it is held against is join it replaced -- one plane
        #   through segment and eye, read for its normal. Sign included: two
        #   agree exactly, or picture has quietly started flanking lines wrong way.
        algebraic = directionNormal(
          toMultivector(tail) ∧ toMultivector(head) ∧ toMultivector(eye)
        )
      check algebraic.isSome == computed.isSome
      if algebraic.isSome:
        check computed.get =~ algebraic.get
    # Check two refusals: segment of no length, and eye on segment's own line.
    #   Neither has side to step off toward.
    let (a, b) = (Position(x: 1, y: 2, z: 3), Position(x: 2, y: 4, z: 6))
    check directionAcross(a, a, b).isNone
    check directionAcross(a, b, Position(x: 3, y: 6, z: 9)).isNone


  test "grid cells are one fixed size, at every reach the camera asks for":
    # Size this replaced doubled with reach, so reader who dollied out found.
    #   ground silently re-scaled under them and no distance read off it was comparable
    #   with last. Checked by counting what is actually laid, at two reaches four
    #   doublings apart, against what fixed cell says should be there.
    check SIZE_CELL_GRID =~ 10.0
    for (extent, height) in [(1000.0, 60.0), (4000.0, 60.0)]:
      # Both reaches are inside what fixed cell covers, which is claim being made:
      #   nothing here is stepped cell `sizeCellGridFor` falls back on far out.
      # Straight down from high above lattice crossing, so every line fog reaches is.
      #   drawn whole: nothing falls behind near plane to be clipped, and count
      #   below is then exact arithmetic rather than reading of what happened to survive.
      let
        scale_above = scaleFurnitureAt(Position(x: 0, y: 0, z: height), extent)
        fog = fogFurnitureFor(extent)
        radius = sqrt(fog.radius_gone*fog.radius_gone - height*height)
        # Lines each way from eye, in each of two families, skipping one.
        #   through origin that coincides with world axis.
        lines = 4*int(floor(radius/SIZE_CELL_GRID))
      MESHES.clearMeshes
      MESHES.addLattice(SCRATCH, extent, scale_above, groundPlane())
      # One record per lattice line, since fog fade moved to fragment shader.
      check MESHES.ribbons.count == lines
      for i in 0 ..< MESHES.ribbons.count:
        let corners = expandRibbon(MESHES.ribbons.records[i], toScale(scale_above))
        if not isRibbonDrawn(corners): continue
        for vertex in corners:
          let
            at = vertex.toPosition
            off_x = abs(at.x - SIZE_CELL_GRID*round(at.x/SIZE_CELL_GRID))
            off_y = abs(at.y - SIZE_CELL_GRID*round(at.y/SIZE_CELL_GRID))
          check min(off_x, off_y) <= 1.0


  test "the fog fade is the shader's, held here to the reference it is a copy of":
    # **Successor to fade-piece budget's regression case.** Each grid line used.
    #   to be cut into fade pieces under segment budget, whose cost sawtoothed with
    #   camera distance -- measured at 154 segments/7.3 ms at orbit distance 19 against
    #   2,084/126.5 ms at 300 before budget, and ~920 per-boundary sums per moving
    #   frame under it. Line is one record now and `alphaGridFade` runs per fragment,
    #   so what is held is reference's own shape: full inside fade start, gone at
    #   reach, monotone between -- very curve both fragment shaders copy.
    let fog = fogFurnitureFor(SCALE_FOG.extentFurniture)
    check isNear(alphaGridFade(0.0, fog.radius_full, fog.radius_gone), 1.0)
    check isNear(alphaGridFade(fog.radius_full, fog.radius_full, fog.radius_gone), 1.0)
    check isNear(alphaGridFade(fog.radius_gone, fog.radius_full, fog.radius_gone), 0.0)
    check isNear(alphaGridFade(2.0*fog.radius_gone, fog.radius_full, fog.radius_gone), 0.0)
    var previous = 1.0
    for step in 0 .. 100:
      let at = fog.radius_full +
        (fog.radius_gone - fog.radius_full)*float(step)/100.0
      let fade = alphaGridFade(at, fog.radius_full, fog.radius_gone)
      check fade <= previous + TOLERANCE_SINGLE
      previous = fade


  test "the grid stays inside its line bound however far the camera pulls back":
    # Hold on what is actually laid rather than on rule alone.
    #   Line is one record, so grid's whole spend is its line count, which
    #   `CELLS_GRID_HALF_MAX` bounds per family through stepped cell.
    for (extent, height) in [
      (1.0e3, 6.0e1), (4.0e3, 6.0e1), (1.0e4, 5.0e2), (1.0e6, 5.0e4), (1.0e9, 5.0e7),
    ]:
      let scale_afar = scaleFurnitureAt(Position(x: 0, y: 0, z: height), extent)
      MESHES.clearMeshes
      MESHES.addLattice(SCRATCH, extent, scale_afar, groundPlane())
      check MESHES.ribbons.count <= 2*LINES_GRID_MAX
      check MESHES.ribbons.count > 0


  test "a camera dollied far out still has lattice under it, at a coarser cell":
    # Fault: fog's reach was capped at `CELLS_GRID_HALF_MAX` cells, so past 1,200.
    #   units ground stopped reaching what camera was looking at, and past twice
    #   that there was nothing drawn at all -- black void, axes included. Bound now
    #   steps *cell*, which lays same count of lines across reach camera
    #   actually has.
    check fogFurnitureFor(1.0e9).radius_gone =~ FRACTION_GRID_FADE_END*1.0e9
    check fogFurnitureFor(1.0e9).radius_full < fogFurnitureFor(1.0e9).radius_gone

    # Cell holds at its fixed size right up to reach it can cover, and steps only.
    #   past it -- reader working at any ordinary distance never meets step.
    let radius_fixed = float(CELLS_GRID_HALF_MAX)*SIZE_CELL_GRID
    check sizeCellGridFor(0.0) =~ SIZE_CELL_GRID
    check sizeCellGridFor(radius_fixed) =~ SIZE_CELL_GRID
    check sizeCellGridFor(1.5*radius_fixed) =~ 10.0*SIZE_CELL_GRID
    check sizeCellGridFor(15.0*radius_fixed) =~ 100.0*SIZE_CELL_GRID
    # By decades, so every line of coarser lattice is line of finer one and.
    #   step coarsens what is drawn without moving anything reader was measuring against.
    for radius in [2.0e3, 5.0e4, 3.0e6, 1.0e9]:
      let decades = log10(sizeCellGridFor(radius)/SIZE_CELL_GRID)
      check decades =~ round(decades)
      # And never more lines than bound, however far out camera has gone.
      check radius/sizeCellGridFor(radius) <= float(CELLS_GRID_HALF_MAX)

    # Ground is still drawn where it used to be gone entirely, and still within budget.
    for (extent, height) in [(1.0e4, 5.0e2), (1.0e6, 5.0e4), (1.0e9, 5.0e7)]:
      let scale_afar = scaleFurnitureAt(Position(x: 0, y: 0, z: height), extent)
      MESHES.clearMeshes
      MESHES.addLattice(SCRATCH, extent, scale_afar, groundPlane())
      check MESHES.ribbons.count > 0
      check MESHES.ribbons.count <= RIBBONS_MAX
      # Laid on world multiples of cell this reach asked for, so lattice is still.
      #   world's rather than one dragged along under camera.
      let
        fog = fogFurnitureFor(extent)
        size_cell = sizeCellGridFor(sqrt(fog.radius_gone*fog.radius_gone - height*height))
      for i in 0 ..< MESHES.ribbons.count:
        let corners = expandRibbon(MESHES.ribbons.records[i], toScale(scale_afar))
        if not isRibbonDrawn(corners): continue
        for vertex in corners:
          let
            at = vertex.toPosition
            off_x = abs(at.x - size_cell*round(at.x/size_cell))
            off_y = abs(at.y - size_cell*round(at.y/size_cell))
          # Within fiftieth of cell rather than exactly on it: line is drawn as.
          #   ribbon, so its vertices stand half its own screen width either side of
          #   lattice line, which in world units grows with distance it is drawn at.
          #   Measured at 0.005 of cell across all three reaches.
          check min(off_x, off_y) <= 0.02*size_cell


  test "a picked plane is ruled on itself, in its own frame, and nothing else is":
    # World rules no ground: lattice lies on plane picked, so tilted plane's lines lie in
    #   it, stepped by cell from its anchor along its own two axes.
    let
      normal = normalize(Direction(x: 1.0, y: 2.0, z: 2.0)).get
      through = Position(x: 2.0, y: -1.0, z: 3.0)
      plane = planeThrough(toMultivector(through), toMultivector(normal))
      scale_near = scaleFurnitureAt(through + 3.0*normal, 300.0)
    MESHES.clearMeshes
    MESHES.addLattice(SCRATCH, scale_near.extentFurniture, scale_near, plane)
    check MESHES.ribbons.count > 0
    let
      anchor = positionAnchor(plane).get
      axes = frame(plane).get
      fog = fogFurnitureFor(scale_near.extentFurniture)
      height = abs(depthAgainst(plane, toMultivector(scale_near.eye)))
      size_cell = sizeCellGridFor(sqrt(fog.radius_gone*fog.radius_gone - height*height))
    for i in 0 ..< MESHES.ribbons.count:
      let record = MESHES.ribbons.records[i]
      for at in [
        Position(x: record.tail_x, y: record.tail_y, z: record.tail_z),
        Position(x: record.head_x, y: record.head_y, z: record.head_z),
      ]:
        check abs(depthAgainst(plane, toMultivector(at))) < 1.0e-3
        # One of two plane coordinates sits on multiple of cell: line's own step.
        let
          first = dot(at - anchor, axes.axis_first)/size_cell
          second = dot(at - anchor, axes.axis_second)/size_cell
        check min(abs(first - round(first)), abs(second - round(second))) < 1.0e-3
    # Plane in horizon has no finite point to rule about.
    MESHES.clearMeshes
    MESHES.addLattice(SCRATCH, scale_near.extentFurniture, scale_near, 1.0.e321)
    check MESHES.ribbons.count == 0
    # Picked visible plane alone is ruled: point, and plane hidden, draw no lattice.
    var scene = initScene()
    var picked: Selection
    picked.toggle(scene.addObject(toMultivector(through), "p", Ink.Rose))
    picked.toggle(scene.addObject(plane, "shown", Ink.Rose))
    let hidden = scene.addObject(groundPlane(), "hidden", Ink.Rose)
    scene.setVisible(hidden, false)
    picked.toggle(hidden)
    MESHES.clearMeshes
    MESHES.addLatticesPicked(SCRATCH, scale_near, scene, picked)
    let count_picked = MESHES.ribbons.count
    MESHES.clearMeshes
    MESHES.addLattice(SCRATCH, scale_near.extentFurniture, scale_near, plane)
    check count_picked == MESHES.ribbons.count


  test "the axes fog too: the one the camera stands by is drawn, the far ones are not":
    # Fog applies to axes as well, so all furniture ends at one horizon rather.
    #   than grid stopping while axes run on. Eye thousand units out along x
    #   stands beside that axis and has flown clear of other two -- and both halves
    #   matter, since axis rule that draws nothing at all passes second alone.
    let
      scale_afar = scaleFurnitureAt(Position(x: 1000, y: 0, z: 6), 300.0)
      fog = fogFurnitureFor(scale_afar.extentFurniture)
    check norm(scale_afar.eye - ORIGIN) > fog.radius_gone
    MESHES.clearMeshes
    MESHES.addAxes(SCRATCH, scale_afar.extentFurniture, scale_afar)
    check 6*MESHES.ribbons.count > 0
    for i in 0 ..< MESHES.ribbons.count:
      let corners = expandRibbon(MESHES.ribbons.records[i], toScale(scale_afar))
      if not isRibbonDrawn(corners): continue
      for vertex in corners:
        let at = vertex.toPosition
        # Everything drawn lies on x axis: y and z axes are outside fog, and.
        #   stretch of x axis that is drawn is stretch inside it.
        check abs(at.y) <= 1.0 and abs(at.z) <= 1.0
        check norm(at - scale_afar.eye) <= fog.radius_gone + 1.0


  test "radiusHorizonFor scales with the camera's own far clip distance":
    check radiusHorizonFor(400.0) =~ 400.0*FRACTION_HORIZON


  test "extentFurnitureFor scales with the camera's own far clip distance":
    check extentFurnitureFor(400.0) =~ 400.0*FRACTION_FURNITURE


  test "muted colour blends toward its own luminance and cuts opacity by its fixed fraction":
    for ink in Ink:
      let
        base = ink.colour
        luminance = 0.299'f32*base.red + 0.587'f32*base.green + 0.114'f32*base.blue
        dimmed = muted(base)
      check isNear(dimmed.red, base.red + (luminance - base.red)*MUTE_DESATURATION)
      check isNear(dimmed.green, base.green + (luminance - base.green)*MUTE_DESATURATION)
      check isNear(dimmed.blue, base.blue + (luminance - base.blue)*MUTE_DESATURATION)
      check isNear(dimmed.alpha, base.alpha*FRACTION_DIMMED_ALPHA)


  test "the categorical run is contiguous, so a picker can walk it as one block":
    # Colour picker offers `COUNT_INK_CATEGORICAL` entries starting at.
    #   `lut_ink_to_name[INK_CATEGORICAL_FIRST]`, which is only correct while every
    #   categorical slot follows every structural one, with no gaps.
    check COUNT_INK_CATEGORICAL == 5
    check inkCategorical(0) == INK_CATEGORICAL_FIRST
    check inkCategorical(COUNT_INK_CATEGORICAL - 1) == Ink.high
    for index in 0 ..< COUNT_INK_CATEGORICAL:
      check categoricalIndex(inkCategorical(index)) == index


  test "a colour picker offers every categorical slot and no structural one":
    var offered: seq[string]
    for index in 0 ..< COUNT_INK_CATEGORICAL: offered.add($inkCategorical(index))
    check offered == @["Rose", "Copper", "Olive", "Jade", "Cobalt"]
    # `Invalid` is structural precisely so it can never be offered: status colour.
    #   caller could also pick for ordinary object would say nothing.
    for structural in [Ink.Backdrop, Ink.AxisX, Ink.AxisY, Ink.AxisZ, Ink.Grid,
                       Ink.Guide, Ink.Outline, Ink.Invalid]:
      check categoricalIndex(structural) < 0
    check $Ink.Invalid notin offered


  test "inkCycled stays inside the run a picker offers, and wraps within it":
    # Nothing may cycle to colour user could not have chosen themselves.
    for index in 0 ..< 3*COUNT_INK_CATEGORICAL:
      check categoricalIndex(inkCycled(index)) >= 0
      check categoricalIndex(inkCycled(index)) < COUNT_INK_CATEGORICAL
    check inkCycled(0) == INK_CATEGORICAL_FIRST
    check inkCycled(COUNT_INK_CATEGORICAL) == inkCycled(0)
