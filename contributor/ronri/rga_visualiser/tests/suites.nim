## Check invariants of visualiser against deterministically sampled pool of RGA objects.
##
## Suites are named after visualiser's modules rather than Lengyel's chapters:
##   visualiser is tool built on library, not replication of published equations.
##
## Pool is drawn once from seeded generator, so failure reproduces from test name alone.
##   Points are sampled inside box drawn extent covers, so nothing is degenerate.
##   Lines and planes are joined from those points, so collinear cases stay improbable.
##
## `renderer`, `gui` and `panel` are absent, deliberately:
##   each needs live OpenGL context, which test runner has no business opening.
##   What they would test sits below them:
##   `mesh` holds tessellation, `scene` operations and formatting, `camera` transforms.

when compileOption("profiler"):
  import std/nimprof

import std/[
  math, options, os, random, sets, strformat, strutils, tables, unicode, unittest,
]

# `pga` arrives through `projections`, which stands in for four it has withdrawn.
import ../src/rga_visualiser/projections
# Open `marker` and `picking` with `{.all.}`, so suite checks private helpers directly.
#   `directionAcross` is whole of why line's rails converge, worth asserting on its own
#   terms rather than only through markers it ends up shaping.
#   `isBeyondDisc` is broad phase whose only property worth pinning, never rejecting hit
#   meet would accept, is stated against it directly.
import ../src/rga_visualiser/[
  boundary, camera, format, framing, help, history, interaction, lighting,
  marker {.all.}, neighbourhood, objects, orrery, picking {.all.}, scene, selection,
  starfield, storyboard, tessellate,
]
# Arena, PNG encoder and GIF encoder are desktop-only: each binds C entry.
#   point JS backend has none of. Their own suites are guarded to match, below.
#   `std/endians` joins them because only desktop cases build scene-file bytes by
#   hand, and they write format's own byte order rather than host's.
when not defined(js):
  import std/endians
  import ../desktop/[arena, gif, image]

randomize(0)


const
  SAMPLES = 64
  EXTENT_SAMPLE = 5.0
  TOLERANCE_PLACES_TEST {.define: "visualiser.tolerance_places".} = 9
  TOLERANCE_TEST = 10.0.pow(-float(TOLERANCE_PLACES_TEST))
  TOLERANCE_SINGLE = 1.0e-5
    ## Widen tolerance for values that passed through 32-bit storage.
    ##   Matrices and vertices are single precision, as that is what GPU consumes,
    ##   so comparing them against double-precision geometry at full tolerance is wrong.


let ORIGIN = Position(x: 0, y: 0, z: 0)


proc randPosition(): Position =
  Position(
    x: rand(-EXTENT_SAMPLE .. EXTENT_SAMPLE),
    y: rand(-EXTENT_SAMPLE .. EXTENT_SAMPLE),
    z: rand(-EXTENT_SAMPLE .. EXTENT_SAMPLE),
  )

var
  PLACES: array[SAMPLES, Position]
  POINTS: array[SAMPLES, Multivector]
  LINES: array[SAMPLES, Multivector]
  PLANES: array[SAMPLES, Multivector]
for i in 0 ..< SAMPLES:
  PLACES[i] = randPosition()
  POINTS[i] = toMultivector(PLACES[i])
for i in 0 ..< SAMPLES:
  let (j, k) = ((i + 1) mod SAMPLES, (i + 2) mod SAMPLES)
  LINES[i] = POINTS[i] ∧ POINTS[j]
  PLANES[i] = POINTS[i] ∧ POINTS[j] ∧ POINTS[k]

const COUNT_GENERAL = 12
  ## Hold points enough for two disjoint families of one point, one line and one plane.

func generalPlace(index: int): Position =
  ## Place one of family of points in **general position**:
  ##   no three collinear and no four coplanar, so shape built from any of them is incident with
  ##   none of rest.
  ##   Read off moment curve (t, t², t³), where that is theorem rather than hope:
  ##   4x4 matrix of (1, t, t², t³) over four distinct parameters is Vandermonde and
  ##   so never singular. Scaled to extent rest of suite works at.
  let t = -1.1 + 0.2*float(index)
  Position(x: 4.0*t, y: 4.0*t*t, z: 4.0*t*t*t)

var
  GENERAL_POINTS: array[COUNT_GENERAL, Multivector]
  GENERAL_FIRST: array[3, Multivector] ## Point, line, plane, in grade order.
  GENERAL_SECOND: array[3, Multivector] ## Second such triple, sharing no point with
    ## first -- so test walking every ordered pair of shapes crosses two *different*
    ## objects even on diagonal.
    ##   Kept separate from `POINTS`/`LINES`/`PLANES` above, which are random and whose
    ## `LINES[i]` is built out of neighbouring `POINTS`, so every one of them lies on
    ## points suite would otherwise pair it against. First measurement of drag
    ## proposal table did exactly that -- crossed point with line running through it,
    ## and read zeros that came from fixture rather than from algebra. Two
    ## families in general position are what make zero here mean something.
for i in 0 ..< COUNT_GENERAL:
  GENERAL_POINTS[i] = toMultivector(generalPlace(i))
GENERAL_FIRST = [
  GENERAL_POINTS[0],
  GENERAL_POINTS[1] ∧ GENERAL_POINTS[2],
  GENERAL_POINTS[3] ∧ GENERAL_POINTS[4] ∧ GENERAL_POINTS[5],
]
GENERAL_SECOND = [
  GENERAL_POINTS[6],
  GENERAL_POINTS[7] ∧ GENERAL_POINTS[8],
  GENERAL_POINTS[9] ∧ GENERAL_POINTS[10] ∧ GENERAL_POINTS[11],
]

# Mesh storage is far too large for stack frame, exactly as it is in application.
var MESHES: MeshSet

# Where tessellation step assembles its ribbon pieces before emitting them.
#   application carves this from frame arena on desktop and holds fixed buffer on
#   browser; suite has neither, and one shared array is same shape as both.
var SCRATCH: DrawScratch


func `=~`(a, b: float): bool =
  ## Compare approximate equality between scalars.
  abs(a - b) <= TOLERANCE_TEST * max(1.0, max(abs(a), abs(b)))


func `=~`(p, q: Position): bool =
  ## Compare approximate equality between positions.
  p.x =~ q.x and p.y =~ q.y and p.z =~ q.z


func `=~`(d, e: Direction): bool =
  ## Compare approximate equality between directions.
  d.x =~ e.x and d.y =~ e.y and d.z =~ e.z


func isNear(a, b: float): bool =
  ## Compare scalars that passed through 32-bit storage.
  abs(a - b) <= TOLERANCE_SINGLE * max(1.0, max(abs(a), abs(b)))


func isNear(p, q: Position): bool =
  ## Compare positions that passed through 32-bit storage.
  isNear(p.x, q.x) and isNear(p.y, q.y) and isNear(p.z, q.z)


func toPosition(vertex: Vertex): Position =
  ## Read vertex back as position, for checking where tessellation put it.
  Position(x: float(vertex.x), y: float(vertex.y), z: float(vertex.z))


func transform(matrix: Matrix4, p: Position, weight: float): array[4, float] =
  ## Apply transform to homogeneous point, so matrices can be checked by what they do.
  let coordinates = [p.x, p.y, p.z, weight]
  for row in 0 .. 3:
    for column in 0 .. 3:
      result[row] += float(matrix.at(row, column)) * coordinates[column]


proc formatMultivectorString(m: Multivector): string =
  ## Format into stack buffer exactly as panel does, then read it back as `string`.
  ##   Test can compare against that; production code never takes this last step.
  var
    buffer: array[128, char]
    cursor = 0
  formatMultivector(m, buffer, cursor)
  finishChars(buffer, cursor)
  toText(buffer)


suite "Objects":
  test "position inverts toMultivector":
    for place in PLACES:
      let recovered = position(toMultivector(place))
      check recovered.isSome
      check recovered.get =~ place


  test "position ignores scale of homogeneous point":
    for point in POINTS:
      for scale in [-7.5, -1.0, 0.25, 3.0]:
        let (plain, scaled) = (position(point), position(scale * point))
        check plain.isSome and scaled.isSome
        check plain.get =~ scaled.get


  test "shape follows grade":
    for i in 0 ..< SAMPLES:
      check shape(POINTS[i]) == some(Shape.Point)
      check shape(LINES[i]) == some(Shape.Line)
      check shape(PLANES[i]) == some(Shape.Plane)
    check shape(1.0 + POINTS[0]).isNone


  test "support lies on its object":
    for i in 0 ..< SAMPLES:
      for geometry in [LINES[i], PLANES[i]]:
        let anchor = positionAnchor(geometry)
        check anchor.isSome
        check toMultivector(anchor.get) ∧ geometry =~ 0


  test "support of line is perpendicular to its direction":
    for line in LINES:
      let (anchor, axis) = (positionAnchor(line), direction(line))
      check anchor.isSome and axis.isSome
      check dot(anchor.get - ORIGIN, axis.get) =~ 0


  test "direction of line is unit and lies at its horizon":
    for line in LINES:
      let axis = direction(line)
      check axis.isSome
      check norm(axis.get) =~ 1.0
      check toMultivector(axis.get) ∧ line =~ 0


  test "frame of plane is orthonormal, inside plane, and normal to its normal":
    for plane in PLANES:
      let axes = frame(plane)
      check axes.isSome
      let (axis_first, axis_second, normal) =
        (axes.get.axis_first, axes.get.axis_second, axes.get.normal)
      check norm(axis_first) =~ 1.0
      check norm(axis_second) =~ 1.0
      check norm(normal) =~ 1.0
      check dot(axis_first, axis_second) =~ 0
      check dot(axis_first, normal) =~ 0
      check dot(axis_second, normal) =~ 0
      check toMultivector(axis_first) ∧ plane =~ 0
      check toMultivector(axis_second) ∧ plane =~ 0
      # Frame's own normal is same one `directionNormal` derives independently.
      check normal =~ directionNormal(plane).get


  test "object at horizon yields no anchor":
    for line in LINES:
      let attitude = ⊖ line
      check attitude.isHorizon
      check positionAnchor(attitude).isNone
      check directionHorizon(attitude).isSome


  test "the incidence vocabulary answers what the classical forms answer, sign included":
    # Classical forms live HERE, in test, and algebra lives in `objects.nim`.
    #   -- holding two equal is project's purpose, and it is also what pins every
    #   sign and argument order before anything downstream leans on them. Deterministic
    #   scatter, so failure names same case on every run.
    var seed = 3.0
    proc pseudo(): float =
      seed = (seed*97.31 + 33.77) mod 41.0
      seed - 20.5
    proc somewhere(): Position =
      Position(x: pseudo(), y: pseudo(), z: pseudo())
    proc someway(): Direction =
      var d = Direction(x: 0, y: 0, z: 0)
      while norm(d) < 0.1: d = Direction(x: pseudo(), y: pseudo(), z: pseudo())
      normalize(d).get

    # One fixed pin first: point one unit along plane's own construction.
    #   direction reads exactly +1 -- `plane ∨ point`, in that order; other order
    #   negates and must not be what ships.
    let plane_pin = planeThrough(
      toMultivector(Position(x: 0, y: 0, z: 2)),
      toMultivector(Direction(x: 0, y: 0, z: 1)),
    )
    check depthAgainst(plane_pin, toMultivector(Position(x: 0, y: 0, z: 3))) =~ 1.0
    check depthAgainst(plane_pin, toMultivector(Position(x: 0, y: 0, z: 2))) =~ 0.0
    check depthAgainst(plane_pin, toMultivector(Position(x: 5, y: -4, z: 1))) =~ -1.0
    # Doubled construction direction must change nothing: `planeThrough` unitizes, so.
    #   depth read is metric whatever length caller's direction happened to have.
    let plane_doubled = planeThrough(
      toMultivector(Position(x: 0, y: 0, z: 2)),
      toMultivector(Direction(x: 0, y: 0, z: 2)),
    )
    check depthAgainst(plane_doubled, toMultivector(Position(x: 0, y: 0, z: 3))) =~ 1.0

    for trial in 0 ..< 100:
      let
        at = somewhere()
        along = someway()
        probe = somewhere()
        other = somewhere()
      # `depthAgainst` `planeThrough` is classical signed distance along normal.
      check depthAgainst(
        planeThrough(toMultivector(at), toMultivector(along)), toMultivector(probe)
      ) =~ dot(probe - at, along)
      # `distanceBetween` is classical Euclidean distance.
      check distanceBetween(toMultivector(probe), toMultivector(other)) =~
        norm(probe - other)

    # Two ground spellings agree with each other and with what "ground" means.
    check depthAgainst(groundPlane(), toMultivector(Position(x: 3, y: -8, z: 5.5))) =~ 5.5
    let level = levelPlaneThrough(toMultivector(Position(x: 1, y: 2, z: 4)))
    check depthAgainst(level, toMultivector(Position(x: -9, y: 6, z: 7))) =~ 3.0

    # Centroid, folded one place at time, against mean written out here. Sum.
    #   of unit-weight points carries weight n and total of coordinates, so
    #   division `position` already does *is* averaging -- which is claim.
    let places = [
      Position(x: 3.0, y: -1.0, z: 2.0), Position(x: -5.0, y: 4.0, z: 0.5),
      Position(x: 1.0, y: 9.0, z: -3.5), Position(x: 8.0, y: -2.0, z: 6.0),
    ]
    # Fold starts from first point itself -- one place is its own middle -- and.
    #   carries running sum as multivector, so nothing has to be told count.
    var middle = toMultivector(places[0])
    check position(middle).get =~ places[0]
    for counted in 1 .. places.high:
      middle = centroidFolded(middle, toMultivector(places[counted]))
      var (sum_x, sum_y, sum_z) = (0.0, 0.0, 0.0)
      for i in 0 .. counted:
        sum_x += places[i].x
        sum_y += places[i].y
        sum_z += places[i].z
      # Every prefix, not only whole: incremental fold that is right at end and.
      #   wrong halfway is right by luck, and camera reads it at every length.
      check position(middle).get =~ Position(
        x: sum_x/float(counted + 1),
        y: sum_y/float(counted + 1),
        z: sum_z/float(counted + 1),
      )
      # And sum's own weight *is* how many places it is middle of -- which is what.
      #   lets running total stand in for count nobody carries.
      check middle[Basis.E4] =~ float(counted + 1)



suite "Camera":
  test "the far clip reaches the scene's farthest object however close the orbit is":
    var camera = initCamera(Position(x: 0, y: 0, z: 0), 10.0, 0.0, 0.0)
    check abs(camera.distanceFar - 10.0*FACTOR_CLIP_FAR) < 1.0e-9
    camera.reach_scene = 3000.0
    let eye = camera.eye
    check camera.distanceFar >= norm(eye - Position(x: 0, y: 0, z: 0)) + 3000.0
    # Near rises with far, holding ratio, and never past half orbit distance.
    check camera.distanceFar/camera.distanceNear <= RATIO_CLIP_MAX*(1.0 + 1.0e-9)
    check camera.distanceNear <= 0.5*camera.distance
    var close = initCamera(Position(x: 0, y: 0, z: 0), 0.05, 0.0, 0.0)
    close.reach_scene = 3000.0
    check close.distanceNear <= 0.5*close.distance
    # Reach is measured from what scene holds, point's own radius included.
    var scene = initScene()
    scene.addItem(toMultivector(Position(x: 300, y: 0, z: 0)), "p", Ink.Rose, radius = 2.5)
    check abs(reachOf(scene) - 302.5) < 1.0e-6

  test "a point is culled only where the frustum, sprite margin included, does not reach":
    # Bounds are camera's own frame; what is checked is test against them.
    let camera = initCamera(Position(x: 1, y: 2, z: 3), 10.0, 0.4, 0.3)
    let scale = camera.drawExtentFor(900)
    let bounds = camera.viewBoundsFor(scale, 16.0/9.0)
    const RADIUS = RADIUS_ITEM_DEFAULT
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
      Placed(kind: PlacedKind.PointToward, toward: bounds.forward), RADIUS, bounds
    )
    check not isPointInView(
      Placed(kind: PlacedKind.PointToward, toward: -bounds.forward), RADIUS, bounds
    )
    check isPointInView(Placed(kind: PlacedKind.LineThrough), RADIUS, bounds)

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
      let axes = camera.frame(camera.eye)
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
      check dot(heading.get, camera.frame(camera.eye).forward) =~ 1.0


  test "view transform carries eye to origin and pivot down its own negative z":
    let camera = initCamera(
      pivot = Position(x: 1, y: -2, z: 0.5), distance = 9.0, azimuth = 0.7, elevation = 0.3
    )
    let view = initMatrixView(camera.eye, camera.frame(camera.eye))
    let (at_eye, at_pivot) = (
      transform(view, camera.eye, 1.0), transform(view, camera.pivot, 1.0)
    )
    check isNear(at_eye[0], 0) and isNear(at_eye[1], 0) and isNear(at_eye[2], 0)
    check isNear(at_pivot[0], 0) and isNear(at_pivot[1], 0)
    check isNear(at_pivot[2], -camera.distance)


  test "projection carries clip planes to depth bounds":
    const (NEAR, FAR) = (0.25, 60.0)
    let projection = initMatrixProjection(45.0, 1.6, NEAR, FAR)
    for (depth, expected) in [(NEAR, -1.0), (FAR, 1.0)]:
      let clipped = transform(projection, Position(x: 0, y: 0, z: -depth), 1.0)
      check isNear(clipped[3], depth)
      check isNear(clipped[2]/clipped[3], expected)


  test "whole transform carries pivot to centre of view":
    for i in 0 ..< SAMPLES:
      let camera = initCamera(
        pivot = PLACES[i], distance = 11.0, azimuth = rand(2.0*PI), elevation = rand(-1.2 .. 1.2)
      )
      let clipped = transform(camera.initMatrixViewProjection(1.6), camera.pivot, 1.0)
      check clipped[3] > 0
      check isNear(clipped[0]/clipped[3], 0)
      check isNear(clipped[1]/clipped[3], 0)


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
    let axes = camera.frame(camera.eye)
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
      camera.initMatrixViewProjection(1440.0/900.0), 1440, 900,
    )
    check camera.distance =~ 24.0
    check camera.pivot =~ ORIGIN


  test "a zoom onto a point brings the pivot to its depth, and onto ground or level does not":
    # Turntable follows what reader looks at: eye carried up to planet while pivot.
    #   stayed far behind left every orbit swinging planet across frame. Ground and
    #   level are fallbacks, and following either drifted pivot's height with every
    #   notch and moved it where pan and slide expect it held.
    const (WIDE, TALL) = (1440, 900)
    let planet = Position(x: 3.0, y: 1.0, z: 0.0)
    var scene = initScene()
    scene.addItem(toMultivector(planet), "planet", Ink.Cobalt)
    # Middle of frame over planet, camera aimed at it from afar: pinch's case.
    var camera = initCamera(pivot = planet, distance = 20.0, azimuth = 0.4, elevation = 0.5)
    camera.pivot = Position(x: 3.0, y: 1.0, z: 0.0) + 10.0*camera.frame(camera.eye).forward
    camera.distance = 30.0 # Eye where it was, pivot ten units past planet.
    let eye_before = camera.eye
    dollyAtCentre(
      camera, scene, 0.5, camera.drawExtentFor(TALL),
      camera.initMatrixViewProjection(float(WIDE)/float(TALL)), WIDE, TALL,
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
      ScreenPosition(x: 720.0, y: 200.0),
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
    scene.addItem(toMultivector(raised), "raised", inkCycled(0))

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
    camera_raised.pivot = Position(x: 0.0, y: 0.0, z: 5.0)
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
    scene_floor.addItem(
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


  test "a pan grabs the level under the pointer and carries it to the cursor":
    # Fault: pan of so many hundredths of orbit distance per pixel is right at.
    #   one depth and one tilt and wrong everywhere else -- driven, 200-pixel drag
    #   carried scene 288 -- and it slid pivot within plane *facing eye*,
    #   which is tilted, so same drag lifted pivot from z 1.00 to 6.40.
    const (WIDE, TALL) = (1440, 900)
    var camera = initCamera(
      pivot = Position(x: 0, y: 0, z: 1), distance = 19.0, azimuth = 1.05,
      elevation = 0.42,
    )
    let
      before = ScreenPosition(x: 700.0, y: 560.0)
      after = ScreenPosition(x: 940.0, y: 660.0)
      grabbed = positionUnderCursor(camera, WIDE, TALL, before)
      height_opening = camera.pivot.z
    check grabbed.isSome
    camera.panAcross(before, after, WIDE, TALL)
    # Very point that was under pointer is now under where pointer went.
    let landed = projectToScreen(
      camera.initMatrixViewProjection(float(WIDE)/float(TALL)), WIDE, TALL, grabbed.get
    )
    check hypot(landed.x - after.x, landed.y - after.y) < 0.5
    # And orbit centre keeps its height exactly, whatever direction drag went.
    check camera.pivot.z =~ height_opening
    for step in [
      (ScreenPosition(x: 700.0, y: 560.0), ScreenPosition(x: 700.0, y: 260.0)),
      (ScreenPosition(x: 200.0, y: 800.0), ScreenPosition(x: 1300.0, y: 300.0)),
    ]:
      var camera_step = camera
      camera_step.panAcross(step[0], step[1], WIDE, TALL)
      check camera_step.pivot.z =~ camera.pivot.z


  test "a pan takes hold no further out than its own bound":
    # Horizontal level meets ray aimed near horizon very long way off, and one.
    #   pixel of drag there is hundreds of world units. Hold point is clamped, so
    #   drag high in frame is governed rather than thrown across scene.
    const (WIDE, TALL) = (1440, 900)
    var camera = initCamera(
      pivot = ORIGIN, distance = 19.0, azimuth = 0.0, elevation = 0.06
    )
    # Walk up middle of frame for first row whose ray grazes level far.
    #   enough out to be governed, rather than naming pixel that change in field of
    #   view would quietly move off case being checked.
    var grazing = none(ScreenPosition)
    for row in countdown(450, 360):
      let at = ScreenPosition(x: 720.0, y: float(row))
      let hit = positionUnderCursor(camera, WIDE, TALL, at)
      # Four times past bound, not merely over it: at bound itself clamp.
      #   barely bites and there is no governing to see.
      if hit.isSome and
          norm(hit.get - camera.eye) > 4.0*FACTOR_PAN_REACH_MAX*camera.distance:
        grazing = some(at)
        break
    check grazing.isSome
    let
      opening = camera
      lower = ScreenPosition(x: 720.0, y: grazing.get.y + 30.0)
      unbounded = norm(
        positionUnderCursor(camera, WIDE, TALL, grazing.get).get -
        positionUnderCursor(camera, WIDE, TALL, lower).get
      )
    camera.panAcross(grazing.get, lower, WIDE, TALL)
    let moved = norm(camera.pivot - opening.pivot)
    # It moves -- governed pan is still pan -- but by fraction of what ungoverned.
    #   grab would have thrown view, and never past what two bounded holds can span.
    check moved > 0.0
    check moved < 0.5*unbounded
    check moved <= 2.0*FACTOR_PAN_REACH_MAX*opening.distance
    check camera.pivot.z =~ opening.pivot.z


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
    camera.dollyToward(0.001, anchor.get)
    check camera.distance =~ DISTANCE_LIMIT_NEAR
    check norm(camera.eye - camera.pivot) =~ camera.distance


  test "framing a selection wider than the old ceiling pulls back past it":
    # `distanceFitting` used to be clamped to same 500, so anything larger than.
    #   frame could hold at that distance was framed by giving up rather than by moving.
    let camera = initCamera(pivot = ORIGIN, distance = 19.0, azimuth = 1.0, elevation = 0.4)
    check distanceFitting(4_000.0, camera, 1440, 900, 0.0) > 500.0


suite "Mesh":
  const
    VERTICES_RIBBON = 6 ## Vertices one ribbon is wound from: two triangles over four.
      ## corners.
      ##   Stated here rather than imported so that change to how `addSegment` winds quad has to be
      ##   noticed here too.
    HEIGHT_SCALE_TEST = 900 ## Framebuffer height `SCALE_TEST` measures its widths in.

  let SCALE_TEST = block:
    let eye = Position(x: 5, y: -3, z: 7)
    # `algebraFilled`, as every hand-built extent must be, or multivector twins.
    #   tessellation reads are zero and it silently draws nothing.
    algebraFilled(DrawExtent(scale: DrawScale(
      extent_furniture: 30.0,
      eye: eye, radius_horizon: 50.0,
      # Looking back at origin, which is where every fixture below is built around.
      forward: direction(toMultivector(eye) ∧ toMultivector(ORIGIN)).get,
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

  test "an item's drawn centre is its own anchor, and only a plane's disc moves":
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


  proc ribbonEnds(meshes: MeshSet, index: int): (Position, Position) =
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
    let corners = expandRibbon(meshes.ribbons.records[index], toScale(SCALE_TEST))
    (
      midpoint(corners[0], corners[5]),
      midpoint(corners[1], corners[2]),
    )

  setup:
    MESHES.clearMeshes

  test "clearing drops every vertex and every record":
    MESHES.addMarker(ORIGIN, RADIUS_ITEM_DEFAULT, LIGHT_NONE, Ink.Rose.colour, 1.0)
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
    check MESHES.washes.count == 0


  test "point becomes one marker where it stands":
    for i in 0 ..< SAMPLES:
      MESHES.clearMeshes
      check MESHES.addObject(SCRATCH, POINTS[i], Ink.Rose.colour, SCALE_TEST) == Placement.Finite
      check MESHES.points.count_vertices == 1
      check 6*MESHES.ribbons.count == 0
      check isNear(MESHES.points.vertices[0].toPosition, PLACES[i])


  test "line becomes two segments, each running from support to a vanishing point":
    for line in LINES:
      MESHES.clearMeshes
      check MESHES.addObject(SCRATCH, line, Ink.Jade.colour, SCALE_TEST) == Placement.Finite
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
    let camera = initCamera(Position(x: 0, y: 0, z: 1), 19.0, 1.05, 0.42)
    let
      eye = camera.eye
      frame_camera = camera.frame(eye)
      radius = radiusHorizonFor(camera.distanceFar)
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
      # Whichever half runs toward star has to land on it -- but only where star.
      #   itself stands in front of near plane. Ribbon is clipped there (see
      #   `mesh.addSegment`), so star behind camera is met by half that stops at
      #   near plane instead. Nothing is visible there either way; what would be
      #   real defect is gap between two *on screen*, which this still catches.
      if dot(star - SCALE_TEST.eye, SCALE_TEST.forward) >= SCALE_TEST.depthNear:
        check isNear(far_first, star) or isNear(far_second, star)


  test "plane becomes a flat filled disc and a rim, every vertex on it":
    for plane in PLANES:
      MESHES.clearMeshes
      check MESHES.addObject(SCRATCH, plane, Ink.Olive.colour, SCALE_TEST) == Placement.Finite
      const SEGMENTS_RING = SEGMENTS_CIRCLE_HORIZON
      # One disc record in one wash run: fan itself is shader's now, and.
      #   `expandDiscVertex` -- its reference -- is what its corners are read through.
      check MESHES.discs.count == 1
      check MESHES.washes.count == 1
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
      let corners_disc = discCorners()
      for i in 0 ..< 3*SEGMENTS_CIRCLE_HORIZON:
        let vertex = expandDiscVertex(
          MESHES.discs.records[0],
          float(corners_disc[2*i]), float(corners_disc[2*i + 1]),
        )
        check isNear(dot(vertex.toPosition - anchor.get, normal.get), 0)
        check isNear(float(vertex.alpha), ALPHA_WASH)
        # Every fill vertex is either fan's own centre or out at plane's own.
        #   fixed radius -- flat alpha throughout, so unlike old fading disc there
        #   is no band strictly between two to rule out.
        let radius_vertex = norm(vertex.toPosition - anchor.get)
        check isNear(radius_vertex, 0) or isNear(radius_vertex, EXTENT_PLANE_F)
      # Rim is drawn as line is, so its own *corners* stand half line width off.
      #   plane -- step sideways is perpendicular to segment and to sight
      #   ray, which is only in plane when eye happens to lie in it. What is still
      #   exactly on plane, and at exactly plane's own radius, is segment each
      #   piece was built around; `ringEnds` recovers it.
      #   Every segment of one record is walked, which is what makes record's
      #   fourteen floats provably same circle ninety-six ribbons drew.
      for i in 0 ..< SEGMENTS_RING:
        let (tail, head) = ringEnds(MESHES, 0, i)
        for place in [tail, head]:
          check isNear(dot(place - anchor.get, normal.get), 0)
          check isNear(norm(place - anchor.get), EXTENT_PLANE_F)
        # And every corner stays within that half width of plane, so bulge is.
        #   fraction of pixel on screen rather than anything reader could see.
        let bound = 0.5*float(WIDTH_LINE_OBJECT)*
          max(worldPerPixelAt(tail, SCALE_TEST), worldPerPixelAt(head, SCALE_TEST))
        for j in 0 ..< VERTICES_RIBBON:
          let corner = expandRingVertex(MESHES.rings.records[0], i, toScale(SCALE_TEST))[j]
          check isNear(float(corner.alpha), Ink.Olive.colour.alpha)
          check abs(dot(corner.toPosition - anchor.get, normal.get)) <= bound + 1e-5


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
      # Record's own expansion beside plain stepping: `expandDiscVertex` is.
      #   reference both disc-fill vertex shaders are held to, so it too must land on
      #   multivector sums, corner for corner, through record's narrowed floats.
      MESHES.clearMeshes
      MESHES.addDisc(
        anchor.get, axes.get.axis_first, axes.get.axis_second, radius, Ink.Olive.colour
      )
      for i in 0 ..< SEGMENTS_CIRCLE_HORIZON:
        let
          angle = (2.0*PI * float(i)) / float(SEGMENTS_CIRCLE_HORIZON)
          stepped = onCircle(anchor.get, arm_first, arm_second, angle)
          assembled = pointFrom(add(centre_point, add(
            wedge(cos(angle), arm_first_point), wedge(sin(angle), arm_second_point),
          )))
          expanded = expandDiscVertex(MESHES.discs.records[0], cos(angle), sin(angle))
        check stepped =~ assembled
        check isNear(expanded.toPosition, assembled)


  test "point at horizon becomes a star fixed at eye plus its own direction":
    for line in LINES:
      MESHES.clearMeshes
      let attitude = ⊖ line
      check MESHES.addObject(SCRATCH, attitude, Ink.Cobalt.colour, SCALE_TEST) == Placement.Horizon
      check MESHES.points.count_vertices == 1
      let
        heading = directionHorizon(attitude)
        star = MESHES.points.vertices[0].toPosition
      check heading.isSome
      check isNear(star, SCALE_TEST.eye + SCALE_TEST.radiusHorizon*heading.get)


  test "line at horizon becomes a great circle around eye, perpendicular to its normal":
    for plane in PLANES:
      MESHES.clearMeshes
      let attitude = ⊖ plane
      check MESHES.addObject(SCRATCH, attitude, Ink.Jade.colour, SCALE_TEST) == Placement.Horizon
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
      for i in 0 ..< SEGMENTS_RING:
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
      check count_at_radius > 0
      # Half-behind claim, held rather than assumed: some of ring is drawn, and.
      #   well under all of it.
      check count_drawn in 1 ..< SEGMENTS_RING


  test "plane at horizon becomes a dome over the whole sky around eye":
    # Every plane at horizon is same universal object regardless of source (see.
    #   `objects.directionNormalHorizon`'s own doc comment), so two unrelated planes'
    #   own attitudes should both land dome at exactly same distance from eye,
    #   with nothing about either plane's own coefficients read to decide it.
    #   Attitude of plane (grade 3) gives line at horizon, not plane: reaching
    #   plane at horizon needs grade-4 volume first, built here from point wedged
    #   with unrelated plane it does not lie on.
    let
      volume_first = POINTS[10] ∧ PLANES[0]
      volume_second = POINTS[20] ∧ PLANES[7]
      attitude_first = ⊖ volume_first
      attitude_second = ⊖ volume_second
    check shape(attitude_first) == some(Shape.Plane) and isHorizon(attitude_first)
    check shape(attitude_second) == some(Shape.Plane) and isHorizon(attitude_second)

    check MESHES.addObject(SCRATCH, attitude_first, Ink.Cobalt.colour, SCALE_TEST) ==
      Placement.Horizon
    # One dome record in one wash run: sphere itself is static geometry shader.
    #   widens, and `expandDomeVertex` -- its reference -- is what its corners are read
    #   through.
    check MESHES.domes.count == 1
    check MESHES.washes.count == 1
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
      Placement.Horizon
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
      check MESHES.addObject(SCRATCH, empty, Ink.Rose.colour, SCALE_TEST) == Placement.Empty
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
    for i in 0 ..< ITEMS_MAX:
      let angle = 0.7*float(i)
      let plane =
        toMultivector(Position(x: 6.0*cos(angle), y: 6.0*sin(angle), z: 0.15*float(i))) ∧
        toMultivector(Position(x: 6.0*cos(angle + 0.4), y: 1.0, z: 2.0 + 0.1*float(i))) ∧
        toMultivector(Position(x: 1.0, y: 6.0*sin(angle + 0.9), z: -1.0))
      if MESHES.addObject(SCRATCH, plane, Ink.Olive.colour, SCALE_TEST) == Placement.Finite:
        inc built
    check built == ITEMS_MAX
    check MESHES.ribbons.count <= RIBBONS_MAX
    check MESHES.discs.count <= DISCS_MAX
    check MESHES.washes.count <= len(MESHES.washes.runs)


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
    MESHES.addGrid(SCRATCH, SCALE_FOG.extentFurniture, SCALE_FOG)
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
    MESHES.addGrid(SCRATCH, scale_afar.extentFurniture, scale_afar)
    check 6*MESHES.ribbons.count > 0
    let fog = fogFurnitureFor(scale_afar.extentFurniture)
    for i in 0 ..< MESHES.ribbons.count:
      let corners = expandRibbon(MESHES.ribbons.records[i], toScale(scale_afar))
      if not isRibbonDrawn(corners): continue
      for vertex in corners:
        check norm(vertex.toPosition - scale_afar.eye) <= fog.radius_gone + 1.0
        check norm(vertex.toPosition - ORIGIN) > fog.radius_gone


  test "ground grid holds full alpha near the camera and fades to nothing at its reach":
    # Fade runs per fragment in shaders now, so what records carry is.
    #   grid's own full tint with fog *flag* set, and drawn alpha is that tint
    #   times `alphaGridFade` -- reference both fragment shaders are held to --
    #   evaluated here at each corner's own distance from eye, exactly as they do.
    MESHES.clearMeshes
    MESHES.addGrid(SCRATCH, SCALE_FOG.extentFurniture, SCALE_FOG)
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
      MESHES.addGrid(SCRATCH, extent, scale_above)
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
      MESHES.addGrid(SCRATCH, extent, scale_afar)
      check MESHES.ribbons.count <= 2*LINES_GRID_MAX
      check MESHES.ribbons.count > 0


  test "a camera dollied far out still has ground under it, at a coarser cell":
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
      MESHES.addGrid(SCRATCH, extent, scale_afar)
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


suite "Scene":
  test "the startup scene gives every seed point a colour of its own":
    # Four points wearing one hue say they are one kind of thing, which is opposite of.
    #   what categorical palette is for; hand-added object takes next hue, so these
    #   should too. `ground` and `o` keep hues reader learns to find them by.
    var scene = initScene()
    constructSeeds(scene)
    var inks: seq[Ink]
    for handle in 0 ..< scene.len:
      case toText(scene.labelAt(handle))
      of "ground": check scene.inkAt(handle) == INK_SEED_GROUND
      of "o": check scene.inkAt(handle) == INK_SEED_ORIGIN
      else: inks.add(scene.inkAt(handle))
    check inks.len == 3
    for i in 0 ..< inks.len:
      check inks[i] notin [INK_SEED_GROUND, INK_SEED_ORIGIN]
      for j in i + 1 ..< inks.len: check inks[i] != inks[j]


  test "items are held in order added":
    var scene = initScene()
    for i in 0 ..< 5:
      scene.addItem(POINTS[i], "p" & $i, inkCycled(i))
    check scene.len == 5
    var count_seen = 0
    for item in scene:
      check item.geometry =~ POINTS[count_seen]
      check item.isVisible
      inc count_seen
    check count_seen == 5


  test "removeItem drops one handle without moving any other item":
    var scene = initScene()
    for i in 0 ..< 5:
      scene.addItem(POINTS[i], "p" & $i, inkCycled(i))
    scene.removeItem(2)
    check scene.len == 4
    check not scene.isAlive(2)
    for handle in [0, 1, 3, 4]:
      check scene.isAlive(handle)
      check scene[handle].geometry =~ POINTS[handle]


  test "freed handle is reused by the next addItem, most recently freed first":
    var scene = initScene()
    for i in 0 ..< 5:
      scene.addItem(POINTS[i], "p" & $i, inkCycled(i))
    scene.removeItem(2)
    scene.removeItem(0)
    check scene.addItem(POINTS[5 mod SAMPLES], "p5", Ink.Rose) == 0
    check scene.addItem(POINTS[6 mod SAMPLES], "p6", Ink.Rose) == 2


  test "scene drains to empty regardless of removal order":
    var scene = initScene()
    for i in 0 ..< 5:
      scene.addItem(POINTS[i], "p" & $i, inkCycled(i))
    for handle in [2, 0, 4, 1, 3]:
      scene.removeItem(handle)
    check scene.len == 0
    check not scene.isFull


  test "isAlive rejects a removed handle and any handle out of range":
    var scene = initScene()
    discard scene.addItem(POINTS[0], "a", Ink.Rose)
    check scene.isAlive(0)
    scene.removeItem(0)
    check not scene.isAlive(0)
    check not scene.isAlive(-1)
    check not scene.isAlive(ITEMS_MAX)


  test "scene fills to capacity and reports it":
    var scene = initScene()
    for i in 0 ..< ITEMS_MAX:
      check not scene.isFull
      scene.addItem(POINTS[i mod SAMPLES], "p", Ink.Rose)
    check scene.isFull
    check scene.len == ITEMS_MAX


  test "unary operations ignore their second operand":
    for operation in Operation:
      if lut_operation_to_arity[operation] != Arity.One: continue
      for i in 0 ..< SAMPLES:
        let (m, n, o) = (POINTS[i], LINES[i], PLANES[i])
        check applyOperation(operation, m, n) =~ applyOperation(operation, m, o)


  test "every operation names itself and is offered once":
    var seen: array[Operation, int]
    for operation in Operation:
      check len(lut_operation_to_notation[operation]) > 0
      inc seen[operation]
    for operation in Operation:
      check seen[operation] == 1
    check COUNT_OPERATION == ord(Operation.high) + 1


  test "join and meet recover the geometry they are named for":
    for i in 0 ..< SAMPLES:
      let
        j = (i + 1) mod SAMPLES
        line = applyOperation(Operation.Wedge, POINTS[i], POINTS[j])
        plane = applyOperation(Operation.Wedge, line, POINTS[(i + 2) mod SAMPLES])
        crossed = applyOperation(Operation.WedgeAnti, plane, PLANES[(i + 7) mod SAMPLES])
      check shape(line) == some(Shape.Line)
      check shape(plane) == some(Shape.Plane)
      check shape(crossed) == some(Shape.Line)
      # Both seed points must lie on line joining them.
      check POINTS[i] ∧ line =~ 0
      check POINTS[j] ∧ line =~ 0


  test "meet finds where a line crosses a plane even far outside its own drawn disc":
    # `mesh.addPlane`'s disc is only rendering choice -- plane it represents is.
    #   same infinite object algebraically either way, and `WedgeAnti` (meet) reads
    #   straight off that Multivector, never consulting `EXTENT_PLANE_F` or anything
    #   drawn. Crossing plane three disc-radii out from its own drawn centre, well
    #   outside circle `mesh.addPlane` actually fills, exercises that directly.
    for i in 0 ..< SAMPLES:
      let
        plane = PLANES[i]
        anchor = positionAnchor(plane)
        axes = frame(plane)
      check anchor.isSome
      check axes.isSome
      let
        far_on_plane = anchor.get + (3.0*EXTENT_PLANE_F)*axes.get.axis_first
        off_plane = toMultivector(far_on_plane + axes.get.normal)
        line = toMultivector(far_on_plane) ∧ off_plane
        crossing = applyOperation(Operation.WedgeAnti, line, plane)
      check shape(crossing) == some(Shape.Point)
      let place = position(crossing)
      check place.isSome
      check place.get =~ far_on_plane


  test "orthogonal projection lands on the object projected onto":
    for i in 0 ..< SAMPLES:
      # Point must not be one of three that built plane, or it lies on it already.
      let
        plane = PLANES[i]
        point = POINTS[(i + 9) mod SAMPLES]
        projected = applyOperation(Operation.ProjectOrthogonal, point, plane)
      check shape(projected) == some(Shape.Point)
      let place = position(projected)
      check place.isSome
      check toMultivector(place.get) ∧ plane =~ 0


  test "creation anchor for a plane wedged from a line and a point sits at their midpoint":
    for i in 0 ..< SAMPLES:
      let
        line = LINES[i]
        point = POINTS[(i + 5) mod SAMPLES]
        plane = applyOperation(Operation.Wedge, line, point)
        anchor = creationAnchor(Operation.Wedge, line, point, plane)
        anchor_swapped = creationAnchor(Operation.Wedge, point, line, plane)
        expected = position(add(unitize(point), unitize(projectOrthogonal(point, line))))
      check anchor.isSome
      check anchor_swapped.isSome
      check expected.isSome
      check anchor.get =~ expected.get
      check anchor_swapped.get =~ expected.get


  test "creation anchor for a perpendicular plane sits where its line pierces it":
    for i in 0 ..< SAMPLES:
      let
        point = POINTS[i]
        line = LINES[(i + 11) mod SAMPLES]
        plane = applyOperation(Operation.ExpandWeight, point, line)
        anchor = creationAnchor(Operation.ExpandWeight, point, line, plane)
        anchor_swapped = creationAnchor(Operation.ExpandWeight, line, point, plane)
        expected = position(wedgeAnti(line, plane))
      check anchor.isSome
      check anchor_swapped.isSome
      check expected.isSome
      check anchor.get =~ expected.get
      check anchor_swapped.get =~ expected.get


  test "creation anchor is none for operations or shapes it does not special-case":
    check creationAnchor(Operation.WedgeAnti, PLANES[0], PLANES[1], LINES[0]).isNone
    check creationAnchor(Operation.Wedge, POINTS[0], POINTS[1], LINES[0]).isNone
    check creationAnchor(Operation.Wedge, PLANES[0], POINTS[0], PLANES[0]).isNone
    check creationAnchor(Operation.ProjectOrthogonal, POINTS[0], PLANES[0], POINTS[0]).isNone


  test "notation substitutes real operand names for the table's own bold placeholders":
    # One table serves both render paths, so this is also what browser's own.
    #   `nimOperationNotation` hands out -- there is no second table to keep in step.
    check notationSubstituted(Operation.Wedge, "a", "b") == "a ∧ b"
    check notationSubstituted(Operation.Attitude, "L", "unused") == "L⊖"
    # English name after symbols is full of ordinary m's and n's and must never.
    #   reach label; only symbolic prefix is substituted.
    check notationSubstituted(Operation.DualWeight, "g", "unused") == "g☆"
    check "weight dual" notin notationSubstituted(Operation.DualWeight, "g", "unused")
    # `𝐧` appears twice in projections, and both occurrences take operand name.
    check notationSubstituted(Operation.ProjectCentral, "a", "G") == "G ∨ (a ∧ G★)"
    # Operand whose own name contains placeholder letters survives untouched.
    check notationSubstituted(Operation.Wedge, "mn", "nm") == "mn ∧ nm"


  test "labels truncate and stay terminated":
    var storage: Label
    toChars("short", storage)
    check toText(storage) == "short"
    toChars('x'.repeat(LABEL_MAX*2), storage)
    check len(toText(storage)) <= LABEL_MAX - 1
    check toText(storage).endsWith("…") # Says it was shortened rather than reading whole.


  test "a truncated label never splits a character, whatever the buffer lands on":
    # Bug this pins: bytes were copied until buffer filled, so three-byte.
    #   operator could be cut in half. Invalid tail reached browser as literal
    #   `%e2%8a` where glyph belonged -- Nim's JS backend percent-escapes what it cannot
    #   decode -- which is how it was found, in screenshot of objects list.
    #   Every offset is walked, so whichever byte of operator cut lands on is
    #   covered rather than whichever one this test's own text happens to produce.
    for pad in 0 .. 6:
      var storage: Label
      let text = 'x'.repeat(pad) & "∧∨⊖".repeat(LABEL_MAX)
      toChars(text, storage)
      let kept = toText(storage)
      check kept.validateUtf8 == -1 # -1 is "valid throughout"; any other value is index.
      check kept.endsWith("…")
      check len(kept) <= LABEL_MAX - 1

    # Text that fits exactly is left alone: no mark, nothing dropped.
    var storage: Label
    let exact = "∧".repeat((LABEL_MAX - 1) div 3)
    toChars(exact, storage)
    check toText(storage) == exact


  # Every magnitude two front-ends show has to read same in both, and values.
  #   most likely to break that are exact binary ties -- coefficient of 10.125 or 12345,
  #   which user can simply type. C rounds tie to even and JavaScript rounds it away
  #   from zero, so formatter that delegates to runtime disagrees with itself across
  #   backends. Measured before rule was stated here: 330 of 7000 values differed.
  const MAGNITUDES = [
    0.0, 1.0, -1.0, 3.5, -2.0, 0.25, 1664.0, 1234567.0, 0.00012345, 1e-7, 1e7,
    99999.0, 0.099999, 123.456, -0.0001, 1e-5, 9.9999e-5, 1000.0, 999.95, 6.02e23,
    10.125, 12345.0, 0.125, 1.0005, 9999.6, -10.125, 2.5, 0.5, 1.5, 1012.5,
  ]

  test "magnitudes read the same whichever backend formats them":
    # Pinned as text rather than against reference backend supplies, because that is.
    #   exactly what differs. These are what C's own `%.4g` writes, verified against it.
    check formatMagnitude(10.125) == "10.12"   # Tie, rounds to even.
    check formatMagnitude(-10.125) == "-10.12"
    check formatMagnitude(12345.0) == "1.234e+04"
    check formatMagnitude(0.125) == "0.125"
    check formatMagnitude(2.5) == "2.5"
    check formatMagnitude(1012.5) == "1012"    # Tie at fourth digit, rounds to even.
    check formatMagnitude(9999.6) == "1e+04"   # Rounding carries into another digit.
    check formatMagnitude(0.0) == "0"
    check formatMagnitude(-0.0) == "0"         # Sign on nothing reads as bug.

  test "magnitudesAgree: the browser's own formatter answers what C's does":
    # One rule, two mechanisms: desktop reaches C's `%.4g` through `snprintf`, which.
    #   browser build has no runtime for, so `formatMagnitude` states same rule in
    #   plain Nim. Only this test holds two together -- run it before changing either.
    #   Skipped on JS backend, which has no `snprintf` to compare against; test
    #   above is what runs there, and it pins text rather than second mechanism.
    when not defined(js):
      for value in MAGNITUDES:
        if value == 0.0: continue  # C signs zero, this does not; pinned above.
        var
          storage: array[64, char]
          cursor = 0
        appendMagnitude(storage, cursor, value)
        check formatMagnitude(value) == toText(storage)


  test "multivectors print every term they carry, and nothing else":
    # Significant digits, not fixed decimal places: whole number reads as one, and.
    #   coefficient keeps only digits it actually carries. Basis elements are named
    #   as library's own `$` names them, which is what keeps two GUIs 1-1.
    check formatMultivectorString(initElement(Basis.scalar, 0.0)) == "0 𝟏"
    check formatMultivectorString(toMultivector(Position(x: 2, y: 0, z: -3))) ==
      "2 𝐞₁ - 3 𝐞₃ + 1 𝐞₄"
    check formatMultivectorString(toMultivector(Position(x: 3.5, y: 0, z: 0))) ==
      "3.5 𝐞₁ + 1 𝐞₄"
    check formatMultivectorString(initElement(Basis.scalar, 0.00012345)) == "0.0001234 𝟏"
    # Match every basis name against what library writes for that element on its own.
    #   Never trusted to table transcribed by hand.
    for b in Basis:
      let named = ($initElement(b, 1.0)).strip()
      check lut_basis_to_name[b] == named
    for i in 0 ..< SAMPLES:
      check shapeText(POINTS[i]) == "point"
      check shapeText(LINES[i]) == "line"
      check shapeText(PLANES[i]) == "plane"
      # Attitude of line is its direction, which is point standing at horizon.
      check shapeText(⊖ LINES[i]) == "point at horizon"
    check shapeText(1.0 + POINTS[0]) == "mixed grade, nothing to draw"


  test "handlesCreated walks creation order, whatever order the handles fell in":
    # Arena reuses most recently freed handle, so handle order stops being creation.
    #   order moment anything is removed. This is what save path walks, and what
    #   `born`-sorted list could not answer: two items added in one frame share reading,
    #   and replayed item's own born is stamped into future.
    var scene = initScene()
    for i in 0 ..< 6:
      discard scene.addItem(POINTS[i], "p" & $i, inkCycled(i))
    scene.removeItem(4)
    scene.removeItem(1)
    let handle_first = scene.addItem(POINTS[6], "seventh", Ink.Rose)  # lands in handle 1
    let handle_second = scene.addItem(POINTS[7], "eighth", Ink.Rose)  # lands in handle 4
    check handle_first == 1
    check handle_second == 4

    var handles: array[ITEMS_MAX, int]
    let count = scene.handlesCreated(handles)
    check count == scene.len
    var labels: seq[string]
    for position in 0 ..< count:
      labels.add(toText(scene.labelAt(handles[position])))
    check labels == @["p0", "p2", "p3", "p5", "seventh", "eighth"]
    # Which is ordinals in order, and every one of them distinct.
    for position in 1 ..< count:
      check scene.orderOf(handles[position]) > scene.orderOf(handles[position - 1])

    # Empty scene fills nothing rather than reporting handle that is not there.
    let empty = initScene()
    check empty.handlesCreated(handles) == 0


  test "handlesCreated orders a scrambled arena of hundreds, not just a handful":
    # Heapsort has cases insertion sort never exercised: many items, handles freed and.
    #   refilled throughout, so ordinals sit nowhere near their handles.
    var scene = initScene()
    let count_wanted = min(ITEMS_MAX, 300)
    for i in 0 ..< count_wanted:
      discard scene.addItem(POINTS[i mod SAMPLES], "p", Ink.Rose)
    var rng = initRand(7)
    for _ in 0 ..< count_wanted div 2:
      let handle = rng.rand(count_wanted - 1)
      if scene.isAlive(handle): scene.removeItem(handle)
    for i in 0 ..< count_wanted div 3:
      discard scene.addItem(POINTS[i mod SAMPLES], "r", Ink.Rose)
    var handles: array[ITEMS_MAX, int]
    let count = scene.handlesCreated(handles)
    check count == scene.len
    for position in 1 ..< count:
      check scene.orderOf(handles[position]) > scene.orderOf(handles[position - 1])


  test "revisionPlacingAt stamps the handle an edit touched, and every handle after a restore":
    # Front-end re-places only handles stamped past what it holds, so stamp must move for.
    #   exactly handles whose placing inputs did.
    var scene = initScene()
    for i in 0 ..< 4: discard scene.addItem(POINTS[i], "p" & $i, inkCycled(i))
    let revision_built = scene.revision
    for handle in 0 ..< 4: check scene.revisionPlacingAt(handle) <= revision_built
    scene.setGeometryAt(2, POINTS[5])
    check scene.revisionPlacingAt(2) == scene.revision
    for handle in [0, 1, 3]: check scene.revisionPlacingAt(handle) < scene.revision
    # Ink and visibility change nothing about placement.
    scene.setInk(1, Ink.Rose)
    scene.setVisible(3, false)
    for handle in [0, 1, 3]: check scene.revisionPlacingAt(handle) < scene.revision
    # Restore may change any handle, so every live one is stamped at new revision.
    var snapshot = initScene()
    for i in 0 ..< 3: discard snapshot.addItem(POINTS[i + 5], "s" & $i, inkCycled(i))
    scene.restoreFrom(snapshot)
    check scene.len == 3
    for handle in 0 ..< 3: check scene.revisionPlacingAt(handle) == scene.revision


  test "restoreFrom lands on a revision no earlier state carried":
    # Assignment restored snapshot's own revision, and bump after it landed on very.
    #   number of edit being undone -- so front-end holding meshes on it drew
    #   undone object until camera moved. Measured on built page.
    var scene = initScene()
    discard scene.addItem(POINTS[0], "a", Ink.Rose)
    let snapshot = scene
    discard scene.addItem(POINTS[1], "b", Ink.Rose)
    let revision_edit = scene.revision
    scene.restoreFrom(snapshot)
    check scene.len == 1
    check scene.revision > revision_edit
    # And from snapshot ahead of live scene, past that snapshot's own.
    var ahead = snapshot
    for i in 0 ..< 5: discard ahead.addItem(POINTS[i], "x" & $i, Ink.Rose)
    scene.restoreFrom(ahead)
    check scene.len == 6
    check scene.revision > ahead.revision
    check scene.revision > revision_edit


  # Where versions 2 to 5 wrote `Rose`: one past today's, palette then holding retired.
  #   structural slot `Algebra` at ordinal 7 before every hue; see `scene.upgradedFrom5`.
  const ORDINAL_INK_ROSE_V5 = ord(Ink.Rose) + 1
  const ORDINAL_INK_ALGEBRA_V5 = 7

  proc savedWith(ordinal: int, radius = RADIUS_ITEM_DEFAULT, shines = false): ItemSaved =
    ## Build item differing from its neighbours only in palette slot, radius and shine.
    ##   Three fields version boundaries have ever changed; radius and shine default,
    ##   since most cases care about palette alone.
    ItemSaved(
      ink_ordinal: ordinal, is_visible: true, label: "x", geometry: POINTS[0],
      radius: radius, shines: shines,
    )


  test "an item already at this version is carried up unchanged":
    # Chain has to be no-op on file this build wrote, or every save/load round.
    #   trip quietly rewrites something.
    for ordinal in ord(Ink.low) .. ord(Ink.high):
      let carried = itemUpgraded(savedWith(ordinal), VERSION_SCENE)
      check carried.isSome
      check carried.get.ink_ordinal == ordinal
      check carried.get.is_visible
      check carried.get.label == "x"
      check carried.get.geometry =~ POINTS[0]
      check carried.get.radius == RADIUS_ITEM_DEFAULT
    # And ordinal no palette answers to is refused rather than clamped into one.
    check itemUpgraded(savedWith(ord(Ink.high) + 1), VERSION_SCENE).isNone
    check itemUpgraded(savedWith(-1), VERSION_SCENE).isNone
    # Radius this build keeps is whatever file said, so long as it could draw something.
    check itemUpgraded(savedWith(0, 2.5), VERSION_SCENE).get.radius == 2.5
    check itemUpgraded(savedWith(0, 2.5, shines = true), VERSION_SCENE).get.shines
    check itemUpgraded(savedWith(0, 0.0), VERSION_SCENE).isNone
    check itemUpgraded(savedWith(0, -1.0), VERSION_SCENE).isNone
    check itemUpgraded(savedWith(0, NaN), VERSION_SCENE).isNone


  test "a version-3 item is given the radius version 3 drew everything at":
    # Version 3 wrote no radius, so whatever reader had in field is overwritten, not.
    #   trusted: parser passing garbage or zero there must still land on default.
    for stale in [0.0, -1.0, 7.0, NaN]:
      let carried = itemUpgraded(savedWith(ORDINAL_INK_ROSE_V5, stale), 3'u8)
      check carried.isSome
      check carried.get.radius == RADIUS_ITEM_DEFAULT
      check carried.get.ink_ordinal == ord(Ink.Rose)
    # Same for every older version: radius joins chain at its boundary, once.
    for version in VERSION_SCENE_LEAST ..< VERSION_SCENE_RADIUS:
      check not hasRadius(version)
      # First hue in each version's own palette; see `ORDINAL_INK_ROSE_V5`.
      let ordinal = if version == 1'u8: ORDINAL_INK_CATEGORICAL_V1 else: ORDINAL_INK_ROSE_V5
      check itemUpgraded(savedWith(ordinal, 0.0), version).get.radius == RADIUS_ITEM_DEFAULT
    check hasRadius(VERSION_SCENE)


  test "a version-4 item is given no sun, whatever the parser had in the field":
    for version in VERSION_SCENE_LEAST ..< VERSION_SCENE_SHINE:
      check not hasShine(version)
      let carried = itemUpgraded(savedWith(ORDINAL_INK_ROSE_V5, shines = true), version)
      check carried.isSome
      check not carried.get.shines
    check hasShine(VERSION_SCENE)


  test "a version-5 hue past the retired debug slot moves one down, and the slot is refused":
    # Version 6 dropped structural `Algebra` from palette; ordinals past it shift, ones.
    #   before it stand, and byte naming slot no build ever assigned is corrupt.
    for ordinal in 0 ..< ORDINAL_INK_ALGEBRA_V5:
      check itemUpgraded(savedWith(ordinal), 5'u8).get.ink_ordinal == ordinal
    check itemUpgraded(savedWith(ORDINAL_INK_ALGEBRA_V5), 5'u8).isNone
    for ordinal in ORDINAL_INK_ALGEBRA_V5 + 1 .. ord(Ink.high) + 1:
      check itemUpgraded(savedWith(ordinal), 5'u8).get.ink_ordinal == ordinal - 1
    check itemUpgraded(savedWith(ORDINAL_INK_ROSE_V5), 5'u8).get.ink_ordinal == ord(Ink.Rose)
    # Past what version 5 could name is refused, as ever.
    check itemUpgraded(savedWith(ord(Ink.high) + 2), 5'u8).isNone


  test "a version-2 item needs nothing doing to it but is walked all the same":
    # Version 2 and 3 differ only in what item *sequence* promises, so item's own.
    #   fields come through untouched -- and must not be folded by version-1 step.
    #   Compared field by field rather than through `==`, which `Multivector` makes
    #   compile error on purpose; geometry is checked with approximate operator.
    # Palette ordinals are version 5's, one past today's beyond retired slot, so.
    #   both walks land on same hue only where they start from what each wrote.
    for ordinal in ord(Ink.low) .. ord(Ink.high) + 1:
      if ordinal == ORDINAL_INK_ALGEBRA_V5: continue
      let
        today = if ordinal > ORDINAL_INK_ALGEBRA_V5: ordinal - 1 else: ordinal
        from_two = itemUpgraded(savedWith(ordinal), 2'u8)
        from_three = itemUpgraded(savedWith(today), VERSION_SCENE)
      check from_two.isSome
      check from_three.isSome
      check from_two.get.ink_ordinal == today
      check from_two.get.ink_ordinal == from_three.get.ink_ordinal
      check from_two.get.is_visible == from_three.get.is_visible
      check from_two.get.label == from_three.get.label
      check from_two.get.geometry =~ from_three.get.geometry


  test "a version-1 item is carried onto today's palette, hue by hue":
    # Version 1 had no `Invalid` and three more hues, so every ordinal it could hold is.
    #   walked here rather than only two ends.
    for ordinal in 0 ..< ORDINAL_INK_CATEGORICAL_V1:
      # Structural slots are unmoved to this day.
      let carried = itemUpgraded(savedWith(ordinal), 1'u8)
      check carried.isSome
      check carried.get.ink_ordinal == ordinal
    for step in 0 ..< 8:
      # Its eight hues all land on hue -- never on `Invalid`, never off end.
      let carried = itemUpgraded(savedWith(ORDINAL_INK_CATEGORICAL_V1 + step), 1'u8)
      check carried.isSome
      let ink = Ink(carried.get.ink_ordinal)
      check ink == inkCycled(step)
      check ink != Ink.Invalid
      check ink in inkCategorical(0) .. inkCategorical(COUNT_INK_CATEGORICAL - 1)
    # Deliberately *not* pinned to fixed shift from version 1's own start. Structural.
    #   slot reserved since -- `Invalid`, then `Algebra` -- moves every hue along by one
    #   more while leaving fold correct, so such assertion fails on legitimate
    #   palette change and catches no real fault. Where each hue lands is stated above,
    #   through `inkCycled`, which is what fold actually promises.
    # Ordinals version 1 could never have written are corrupt file, not another hue.
    check itemUpgraded(savedWith(ORDINAL_INK_HIGH_V1 + 1), 1'u8).isNone
    check itemUpgraded(savedWith(-1), 1'u8).isNone
    # Everything that is not palette rides through whole chain untouched.
    let carried = itemUpgraded(savedWith(ORDINAL_INK_HIGH_V1), 1'u8)
    check carried.get.label == "x"
    check carried.get.geometry =~ POINTS[0]


  test "a version outside what this build reads is refused by the chain itself":
    # Guard lives with walk rather than only at each call site, so caller that.
    #   forgets to check `readsSceneVersion` still cannot get half-upgraded item.
    check itemUpgraded(savedWith(ord(Ink.Rose)), 0'u8).isNone
    check itemUpgraded(savedWith(ord(Ink.Rose)), VERSION_SCENE + 1'u8).isNone
    for version in VERSION_SCENE_LEAST .. VERSION_SCENE:
      check readsSceneVersion(version)
      # First hue in each version's own palette; see `ORDINAL_INK_ROSE_V5`.
      let ordinal =
        if version == 1'u8: ORDINAL_INK_CATEGORICAL_V1
        elif version < VERSION_SCENE: ORDINAL_INK_ROSE_V5
        else: ord(Ink.Rose)
      check itemUpgraded(savedWith(ordinal), version).isSome


  test "bornReplaying staggers an arrival in order and never runs past the cap":
    const CLOCK = 12.5
    # Handful of objects get full beat: legible, and short enough to still overlap.
    check bornReplaying(0, 4, CLOCK) =~ CLOCK
    for index in 1 ..< 4:
      check bornReplaying(index, 4, CLOCK) =~ CLOCK + float(index)*SECONDS_REPLAY_STEP
    # Single object arriving alone has nothing to stagger against.
    check bornReplaying(0, 1, CLOCK) =~ CLOCK
    # However many arrive, last of them lands within cap -- and in order.
    for count in 1 .. ITEMS_MAX:
      var previous = low(float)
      for index in 0 ..< count:
        let born = bornReplaying(index, count, CLOCK)
        check born > previous
        check born >= CLOCK
        previous = born
      check previous - CLOCK <= SECONDS_REPLAY_WHOLE + TOLERANCE_TEST
    # And beat only ever shortens to make that fit, never lengthens.
    check bornReplaying(1, ITEMS_MAX, CLOCK) - CLOCK < SECONDS_REPLAY_STEP


  test "replayFrom restamps a whole scene into an arrival, in creation order":
    # What opening scene and demo preset both go through: built all at once, then.
    #   handed to reader as construction it is. Handle order is scrambled first, so
    #   this pins that restamp follows creation order rather than arena's layout.
    var scene = initScene()
    for i in 0 ..< 5:
      discard scene.addItem(POINTS[i], "p" & $i, inkCycled(i), 99.0)
    scene.removeItem(1)
    let handle_late = scene.addItem(POINTS[5], "late", Ink.Rose, 99.0)
    check handle_late == 1

    const CLOCK = 7.5
    scene.replayFrom(CLOCK)
    var handles: array[ITEMS_MAX, int]
    let count = scene.handlesCreated(handles)
    check count == 5
    check scene.bornAt(handles[0]) =~ CLOCK
    for position in 1 ..< count:
      check scene.bornAt(handles[position]) > scene.bornAt(handles[position - 1])
    check toText(scene.labelAt(handles[count - 1])) == "late"
    check scene.bornAt(handles[count - 1]) - CLOCK <= SECONDS_REPLAY_WHOLE + TOLERANCE_TEST
    # Same beat file of this size would arrive on -- one rule, not two.
    for position in 0 ..< count:
      check scene.bornAt(handles[position]) =~ bornReplaying(position, count, CLOCK)

    # Empty scene has nothing to restamp and must not fall over reaching for handle zero.
    var empty = initScene()
    empty.replayFrom(CLOCK)
    check empty.len == 0


  test "the opening scene arrives as a replay rather than all at once":
    # Startup seeds are construction somebody else made, exactly as loaded file.
    #   is, so both front-ends stagger them. `constructSeeds` itself deliberately does
    #   not: `runStoryboard` calls it too and sweeps each step on clock of its own.
    const CLOCK = 4.0
    var placed = initScene()
    constructSeeds(placed, CLOCK)
    for handle in 0 ..< placed.len:
      check placed.bornAt(handle) == CLOCK # Untouched by constructor itself.

    var opened = initScene()
    constructSeeds(opened, CLOCK)
    opened.replayFrom(CLOCK)
    check opened.len >= 2
    for handle in 1 ..< opened.len:
      check opened.bornAt(handle) > opened.bornAt(handle - 1)
    # Still on screen quickly: opening scene reader waits through is worse opening.
    #   scene than one that simply appeared.
    check opened.bornAt(opened.len - 1) - CLOCK <= SECONDS_REPLAY_WHOLE + TOLERANCE_TEST


  test "a replay stamp in the future draws its object at no size yet":
    # What makes stagger visible rather than merely recorded: `mesh.animationProgress`.
    #   reads born clock has not reached as zero progress, so object waiting its
    #   turn is drawn at nothing and grows in when its beat arrives.
    const CLOCK = 3.0
    let born_second = bornReplaying(1, 4, CLOCK)
    check animationProgress(CLOCK, born_second) == 0.0
    check animationProgress(born_second, born_second) == 0.0
    check animationProgress(born_second + ANIMATION_SECONDS, born_second) == 1.0
    check animationProgress(CLOCK, bornReplaying(0, 4, CLOCK)) == 0.0


  # Saving and loading name filesystem, which browser has none of: `scene.nim`.
  #   declares that pair for desktop backend alone, so their tests are guarded to
  #   match. Every other invariant in this suite holds on both backends and is checked
  #   on both.
  when not defined(js):
    test "save then load reproduces every live item, compacting freed handles":
      var original = initScene()
      discard original.addItem(POINTS[0], "a", Ink.Rose)
      discard original.addItem(POINTS[1], "bb", Ink.Jade, radius = 0.6, shines = true)
      let handle_doomed = original.addItem(POINTS[2], "doomed", Ink.Olive)
      original.removeItem(handle_doomed) # leaves hole fresh load must not reproduce
      let handle_last = original.addItem(POINTS[3], "d", Ink.Cobalt)
      original.setVisible(handle_last, false)

      let path = getTempDir() / "visualiser_suite_scene.rgascene"
      check saveScene(original, path).contains("Saved 3")
      defer: removeFile(path)

      var loaded = initScene()
      discard loaded.addItem(POINTS[9], "stale", Ink.Cobalt) # load must replace, not merge
      check loadScene(loaded, path).contains("Loaded 3")
      check loaded.len == 3

      # Freed handle 2 is compacted away: loaded items land at handles 0, 1, 2 in save order.
      check loaded[0].geometry =~ POINTS[0]
      check toText(loaded[0].label) == "a"
      check loaded[0].ink == Ink.Rose
      check loaded[0].isVisible
      check loaded[0].born == 0.0 # dawn of time, not mid-appear-in-animation
      check loaded[0].radius == RADIUS_ITEM_DEFAULT

      check loaded[1].geometry =~ POINTS[1]
      check toText(loaded[1].label) == "bb"
      check loaded[1].ink == Ink.Jade
      check loaded[1].isVisible
      check loaded[1].radius == 0.6
      check loaded[1].shines
      check not loaded[0].shines

      check loaded[2].geometry =~ POINTS[3]
      check toText(loaded[2].label) == "d"
      check loaded[2].ink == Ink.Cobalt
      check not loaded[2].isVisible


    test "every multi-byte field is written little-endian, whatever the host":
      # Bytes themselves, not round trip: round trip passes on any byte order as.
      #   long as one build writes and reads it, and second implementation of this
      #   format is `glue.js`, which hands `DataView` explicit `true` at every call and
      #   cannot be asked what desktop felt like doing. Pinning layout here is what
      #   keeps two from drifting apart on host that is not little-endian.
      var scene = initScene()
      var geometry: Multivector
      geometry[Basis.low] = 2.0 # 0x4000000000000000, whose bytes are unambiguous either way
      discard scene.addItem(geometry, "e", Ink.Rose)
      let path = getTempDir() / "visualiser_suite_scene_endian.rgascene"
      check saveScene(scene, path).contains("Saved 1")
      defer: removeFile(path)

      let bytes = readFile(path)
      check bytes[0 ..< len(MAGIC_SCENE)] == MAGIC_SCENE
      check uint8(bytes[len(MAGIC_SCENE)]) == VERSION_SCENE

      # Item count, four bytes straight after magic, version and basis count.
      let start_count = len(MAGIC_SCENE) + 2
      check uint8(bytes[start_count]) == 1'u8
      for offset in 1 .. 3: check uint8(bytes[start_count + offset]) == 0'u8

      # First coefficient, past count and this item's ink, visibility, label length and.
      #   one byte of label itself.
      let start_first = start_count + 4 + 3 + 1
      check uint8(bytes[start_first + 6]) == 0x00'u8
      check uint8(bytes[start_first + 7]) == 0x40'u8 # High byte last: little-endian.


    test "empty scene round-trips":
      let original = initScene()
      let path = getTempDir() / "visualiser_suite_scene_empty.rgascene"
      check saveScene(original, path).contains("Saved 0")
      defer: removeFile(path)

      var loaded = initScene()
      discard loaded.addItem(POINTS[0], "will be cleared", Ink.Rose)
      check loadScene(loaded, path).contains("Loaded 0")
      check loaded.len == 0


    test "loading a foreign file leaves scene untouched and reports why":
      var scene = initScene()
      discard scene.addItem(POINTS[0], "keep", Ink.Rose)
      let path = getTempDir() / "visualiser_suite_scene_bogus.rgascene"
      writeFile(path, "not a scene file at all")
      defer: removeFile(path)

      check loadScene(scene, path).contains("not a scene file")
      check scene.len == 1
      check toText(scene[0].label) == "keep"


    test "loading a file saved under a different PGA dimension is rejected":
      var scene = initScene()
      discard scene.addItem(POINTS[0], "keep", Ink.Rose)
      let path = getTempDir() / "visualiser_suite_scene_wrongbasis.rgascene"
      writeFile(path, "RGAS" & char(2) & char(99)) # no build here carries 99 basis terms
      defer: removeFile(path)

      check loadScene(scene, path).contains("different PGA dimension")
      check scene.len == 1


    proc sceneFileOf(version: uint8, items: seq[(int, bool, string, Multivector)]): string =
      ## Build bytes of scene file by hand, at whatever version is asked for.
      ##   Hand-built rather than saved by this build, because point of cases
      ##   below is to read version this build can no longer *write*: asking `saveScene`
      ##   for one would only ever produce today's, and reading it exercised would be
      ##   its own writing spelled backwards. Ink is taken as raw ordinal for same
      ##   reason -- old file's ordinals name enum that is gone.
      result = MAGIC_SCENE & char(version) & char(ord(Basis.high) + 1)
      var count = uint32(len(items))
      var count_bytes = newString(4)
      littleEndian32(addr count_bytes[0], addr count)
      result &= count_bytes
      for (ordinal, is_visible, label, geometry) in items:
        result &= char(ordinal) & char(ord(is_visible)) & char(len(label)) & label
        for b in Basis:
          var
            coefficient = geometry[b]
            bytes = newString(8)
          littleEndian64(addr bytes[0], addr coefficient)
          result &= bytes
        # Radius only from version that carries one; older bytes stop at geometry.
        if hasRadius(version):
          var
            radius = 2.0*RADIUS_ITEM_DEFAULT
            bytes = newString(8)
          littleEndian64(addr bytes[0], addr radius)
          result &= bytes
        # Shine byte only from version that carries one, set so reader can tell.
        if hasShine(version): result &= char(1)


    test "a scene file from before the palette changed is read, not refused":
      # Item's ink is stored as `Ink`'s own ordinal, and reserving `Invalid` renumbered.
      #   that enum -- version-1 file's bytes name different colours now. Reading it
      #   through palette it was written under is what keeps somebody's scene;
      #   three hues that no longer exist fold onto ones that do, which is recoverable
      #   wrong colour rather than unrecoverable refusal.
      var scene = initScene()
      discard scene.addItem(POINTS[9], "replaced", Ink.Rose)
      let path = getTempDir() / "visualiser_suite_scene_v1.rgascene"
      writeFile(path, sceneFileOf(1'u8, @[
        (4, true, "grid-hued", POINTS[0]),  # Structural slot, unmoved between palettes.
        (7, true, "was rose", POINTS[1]),   # First categorical hue of old palette.
        (11, false, "was cobalt", POINTS[2]),
        (13, true, "was magenta", POINTS[3]), # Retired; folds onto hue that survives.
      ]))
      defer: removeFile(path)

      check loadScene(scene, path).contains("Loaded 4")
      check scene.len == 4
      check scene[0].ink == Ink.Grid
      check scene[1].ink == Ink.Rose
      check scene[2].ink == Ink.Cobalt
      check scene[3].ink == inkCycled(13 - ORDINAL_INK_CATEGORICAL_V1)
      # Everything but colour of retired hue comes back exactly.
      for handle in 0 ..< 4:
        check scene[handle].geometry =~ POINTS[handle]
      check toText(scene[1].label) == "was rose"
      check scene[1].isVisible
      check not scene[2].isVisible


    test "a version-2 file's hues come down past the retired debug slot, nothing folded":
      # Version 2 and 3 differ only in what item *sequence* promises, so version-2.
      #   file's ordinals must not be folded through version-1 rule; they are version
      #   5's, one past today's beyond retired `Algebra` slot, and `upgradedFrom5` alone
      #   takes them down.
      var scene = initScene()
      let path = getTempDir() / "visualiser_suite_scene_v2.rgascene"
      writeFile(path, sceneFileOf(2'u8, @[
        (ord(Ink.Grid), true, "structural", POINTS[0]),
        (ord(Ink.Rose) + 1, true, "first hue", POINTS[1]),
        (ord(Ink.Cobalt) + 1, false, "last hue", POINTS[2]),
      ]))
      defer: removeFile(path)

      check loadScene(scene, path).contains("Loaded 3")
      check scene[0].ink == Ink.Grid
      check scene[1].ink == Ink.Rose
      check scene[2].ink == Ink.Cobalt
      check not scene[2].isVisible


    test "a version-3 file is read with every item at the default radius":
      # Version 3 stopped at geometry, so bytes run straight from one item's last.
      #   coefficient into next item's ink: reading radius there would parse whole
      #   rest of file from wrong offset.
      var scene = initScene()
      let path = getTempDir() / "visualiser_suite_scene_v3.rgascene"
      writeFile(path, sceneFileOf(3'u8, @[
        (ord(Ink.Rose), true, "first", POINTS[0]),
        (ord(Ink.Cobalt), false, "second", POINTS[1]),
      ]))
      defer: removeFile(path)

      check loadScene(scene, path).contains("Loaded 2")
      check scene[0].radius == RADIUS_ITEM_DEFAULT
      check scene[1].radius == RADIUS_ITEM_DEFAULT
      check scene[1].geometry =~ POINTS[1]
      check toText(scene[1].label) == "second"
      check not scene[1].isVisible
      # And today's file carries radius through, wherever writer put it.
      let path_now = getTempDir() / "visualiser_suite_scene_v4.rgascene"
      writeFile(path_now, sceneFileOf(VERSION_SCENE, @[
        (ord(Ink.Rose), true, "sized", POINTS[0]),
      ]))
      defer: removeFile(path_now)
      check loadScene(scene, path_now).contains("Loaded 1")
      check scene[0].radius == 2.0*RADIUS_ITEM_DEFAULT
      check scene[0].shines
      # Version-4 file stops at radius: nothing shines, and bytes parse from right offset.
      let path_four = getTempDir() / "visualiser_suite_scene_v4_only.rgascene"
      writeFile(path_four, sceneFileOf(4'u8, @[
        (ord(Ink.Rose), true, "sized", POINTS[0]),
        (ord(Ink.Cobalt), false, "second", POINTS[1]),
      ]))
      defer: removeFile(path_four)
      check loadScene(scene, path_four).contains("Loaded 2")
      check scene[0].radius == 2.0*RADIUS_ITEM_DEFAULT
      check not scene[0].shines
      check not scene[1].isVisible


    test "a file from a version this build predates is refused rather than guessed at":
      # Floor never rises, so only ceiling can refuse: later format may mean.
      #   anything at all by these bytes, and there is nothing honest to do but say so.
      var scene = initScene()
      discard scene.addItem(POINTS[0], "keep", Ink.Rose)
      let path = getTempDir() / "visualiser_suite_scene_ahead.rgascene"
      writeFile(path, sceneFileOf(VERSION_SCENE + 1'u8, @[
        (ord(Ink.Rose), true, "future", POINTS[1]),
      ]))
      defer: removeFile(path)

      check loadScene(scene, path).contains("version this build cannot read")
      check scene.len == 1
      check toText(scene[0].label) == "keep"
      check not readsSceneVersion(0'u8) # Version byte of zero was never written either.


    test "a saved scene keeps creation order however its handles were reused":
      # What version 3 is for. Removing and re-adding drops new item into freed.
      #   handle, so handle order and creation order disagree -- and it is creation order
      #   replay has to walk, or file plays back construction that never happened.
      var original = initScene()
      for i in 0 ..< 4:
        discard original.addItem(POINTS[i], "p" & $i, inkCycled(i))
      original.removeItem(1)
      discard original.addItem(POINTS[4], "late", Ink.Rose) # reuses handle 1
      check original.len == 4

      let path = getTempDir() / "visualiser_suite_scene_order.rgascene"
      check saveScene(original, path).contains("Saved 4")
      defer: removeFile(path)

      var loaded = initScene()
      check loadScene(loaded, path).contains("Loaded 4")
      check toText(loaded[0].label) == "p0"
      check toText(loaded[1].label) == "p2"
      check toText(loaded[2].label) == "p3"
      check toText(loaded[3].label) == "late"
      # And order survives second trip, since loading rebuilds ordinals from.
      #   file's own sequence rather than from wherever handles landed.
      check saveScene(loaded, path).contains("Saved 4")
      var again = initScene()
      check loadScene(again, path).contains("Loaded 4")
      for handle in 0 ..< 4:
        check toText(again[handle].label) == toText(loaded[handle].label)


    test "a loaded scene arrives one object at a time, replaying its construction":
      # Load stamps borns from caller's clock forward, which is what makes each.
      #   object still be growing in when next arrives (`mesh.animationProgress` reads
      #   born in future as zero size). Checked against file, not against
      #   scene it came from: whole point is that replay is reconstructed from
      #   sequence rather than from clock reading nobody saved.
      var original = initScene()
      for i in 0 ..< 5:
        discard original.addItem(POINTS[i], "p" & $i, inkCycled(i))
      let path = getTempDir() / "visualiser_suite_scene_replay.rgascene"
      check saveScene(original, path).contains("Saved 5")
      defer: removeFile(path)

      const CLOCK = 40.0
      var loaded = initScene()
      check loadScene(loaded, path, CLOCK).contains("Loaded 5")
      check loaded[0].born =~ CLOCK
      for handle in 1 ..< 5:
        check loaded[handle].born > loaded[handle - 1].born
        # Still growing in as next one lands, rather than queue of separate pop-ins.
        check loaded[handle].born - loaded[handle - 1].born < ANIMATION_SECONDS
      check loaded[4].born - loaded[0].born <= SECONDS_REPLAY_WHOLE

      # No clock, no replay: caller with nothing to animate for gets grown scene.
      var batched = initScene()
      check loadScene(batched, path).contains("Loaded 5")
      check batched[0].born == 0.0


    test "loading a missing path reports cleanly and leaves scene untouched":
      var scene = initScene()
      discard scene.addItem(POINTS[0], "keep", Ink.Rose)
      let path = getTempDir() / "visualiser_suite_scene_does_not_exist.rgascene"

      check loadScene(scene, path).contains("No such file")
      check scene.len == 1


    test "loading a file naming more items than this build's capacity is rejected":
      var scene = initScene()
      discard scene.addItem(POINTS[0], "keep", Ink.Rose)

      var
        count = uint32(ITEMS_MAX + 1)
        count_bytes = newString(4)
      copyMem(addr count_bytes[0], addr count, 4)
      let path = getTempDir() / "visualiser_suite_scene_toobig.rgascene"
      writeFile(path, "RGAS" & char(2) & char(ord(Basis.high) + 1) & count_bytes)
      defer: removeFile(path)

      check loadScene(scene, path).contains("more than")
      check scene.len == 1



suite "History":
  proc scenesEqual(a, b: Scene): bool =
    ## Compare two scenes item by item, rather than through plain `==`:
    ##   `Scene` embeds `Multivector`, whose own `==` is intentional compile error (see
    ##   `pga/multivectors.nim`) steering every other caller toward `=~`'s tolerance -- this is that
    ##   same comparison, just folded field by field over whole scene rather than one multivector at
    ##   time.
    if a.len != b.len: return false
    for handle in 0 ..< ITEMS_MAX:
      if a.isAlive(handle) != b.isAlive(handle): return false
      if not a.isAlive(handle): continue
      let (item_a, item_b) = (a[handle], b[handle])
      if not (item_a.geometry =~ item_b.geometry): return false
      if item_a.label != item_b.label: return false
      if item_a.ink != item_b.ink: return false
      if item_a.isVisible != item_b.isVisible: return false
    true


  test "undo and redo retrace every recorded state exactly, and canUndo/canRedo agree":
    var scene = initScene()
    var camera = initCameraDefault()
    var history: History
    history.initHistory(scene, camera)
    var snapshots = @[scene] # Index 0 is seeded initial state.
    for i in 0 ..< CAPACITY_HISTORY - 1:
      scene.addItem(POINTS[i mod SAMPLES], "p" & $i, inkCycled(i))
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
    var camera = initCameraDefault()
    var history: History
    history.initHistory(scene, camera)
    var snapshots = @[scene]
    for i in 0 ..< CAPACITY_HISTORY + 4: # Four states past what timeline retains.
      scene.addItem(POINTS[i mod SAMPLES], "p" & $i, inkCycled(i))
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
    var camera = initCameraDefault()
    var history: History
    history.initHistory(scene, camera)
    scene.addItem(POINTS[0], "a", Ink.Rose)
    history.record(scene, camera)
    let state_a = scene

    scene.addItem(POINTS[1], "b", Ink.Rose)
    history.record(scene, camera) # State undo will later discard, never redone.

    discard history.undo(scene, camera)
    check scenesEqual(scene, state_a)
    check history.canRedo

    scene.addItem(POINTS[2], "c", Ink.Rose) # Diverges from discarded state above.
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
    var camera = initCameraDefault()
    var history: History
    history.initHistory(scene, camera)

    # Two edits, each made from its own distinctly different viewpoint.
    camera.azimuth = 0.25
    camera.distance = 11.0
    scene.addItem(POINTS[0], "a", Ink.Rose)
    history.record(scene, camera)
    let camera_a = camera

    camera.azimuth = 1.75
    camera.distance = 29.0
    camera.elevation = -0.4
    scene.addItem(POINTS[1], "b", Ink.Rose)
    history.record(scene, camera)
    let camera_b = camera

    # Orbiting after fact records nothing of its own, so step ignores wherever.
    #   camera has drifted to since.
    camera.azimuth = -2.5
    camera.distance = 3.0
    camera.elevation = 1.1

    # Undoing `b` takes scene back to one item and view back to where `b` was.
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
    check not (camera.azimuth =~ initCameraDefault().azimuth)


  test "undo and redo each advance the revision past every one the timeline has seen":
    # Front-end holds meshes and placements on revision; step that landed on.
    #   number it had already drawn showed nothing until camera moved.
    var scene = initScene()
    var camera = initCameraDefault()
    var history: History
    history.initHistory(scene, camera)
    var seen = @[scene.revision]
    for i in 0 ..< 3:
      scene.addItem(POINTS[i], "p" & $i, Ink.Rose)
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


  proc placementAim(azimuth, elevation: float): Camera =
    ## Build camera orbiting origin at given angles, for sweeps below.
    initCamera(pivot = ORIGIN, distance = 12.0, azimuth = azimuth, elevation = elevation)

  proc sceneOf(objects: varargs[Multivector]): (Scene, Selection) =
    ## Build scene holding exactly these objects, with every one of them picked.
    var (scene, picked) = (initScene(), Selection())
    for m in objects:
      picked.toggle(scene.addItem(m, "m", Ink.Rose))
    (scene, picked)

  proc offerAim(
    tween: var CameraTween; camera: Camera; scene: Scene; picked: Selection;
    staged: Option[Preview]; scale: DrawExtent; width, height: int; now, duration: float
  ) =
    ## Offer with no pointer pick, as list and keyboard picks do.
    ##   Overload for cases about framing rule alone; pointer rule's cases pass their own.
    var pointer = none(PointerPick)
    tween.offerAim(camera, scene, picked, staged, scale, width, height, now, duration, pointer)

  proc framedFor(
    scene: Scene, picked: Selection, camera: Camera
  ): CameraPlacement =
    ## Resolve where framing rule puts camera for whole selection.
    let aim = aimFor(scene, picked, none(Preview), camera.drawExtentFor(HEIGHT_AIM))
    check aim.isSome
    placementFor(aim.get, scene, picked, none(Preview), camera, WIDTH_AIM, HEIGHT_AIM)


  test "on screen is not in view: the box is two thirds of the frame, not all of it":
    # What whole rule rests on. Object clinging to edge is visible without.
    #   being what view is about, and this is case that says so.
    let point = toMultivector(Position(x: 9.0, y: -7.0, z: 4.0))
    let camera = placementAim(1.6, 0.2)
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
    let axes = camera.frame(camera.eye)
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
        let camera = placementAim(azimuth, elevation)
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
        let camera = placementAim(azimuth, 0.2)
        for step in 1 .. 14:
          let reach = 0.06*float(step)
          if isShownCentrally(offsetFromPivot(camera, reach, 0.0), camera, width, height):
            check isShownCentrally(
              offsetFromPivot(camera, 0.0, reach), camera, width, height
            )


  test "on a wide frame the box is as far across as it is down, to the pixel":
    # Shape itself, measured rather than asserted: walk point out sideways until it.
    #   leaves box and check where it went. Edge stands at frame's *height*,
    #   not its width -- 300 px from middle of 1440x900 frame rather than 480 -- less
    #   room drawn dot takes.
    let camera = placementAim(0.0, 0.0)
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
    let camera = placementAim(0.0, 0.2)
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
      handle_line = scene.addItem(line, "L", Ink.Rose)
      handle_point = scene.addItem(point, "p", Ink.Rose)
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
    scene.removeItem(handle_point)
    check scene.previewApplying(Operation.Wedge, handle_line, handle_point).isNone

    # Edit session's own staged geometry is same type with neither field, which is.
    #   what keeps it out of framing rule below.
    check previewStaging(line, RADIUS_ITEM_DEFAULT).anchor.isNone
    check previewStaging(line, RADIUS_ITEM_DEFAULT).operands.isNone
    # Ghost of point under edit is drawn at session's own radius, not default.
    check previewStaging(line, 0.03).radius == 0.03
    discard picked


  test "a staged preview is framed with the operands it names; an edit stands alone":
    # What reader is judging when picker previews operation is *result beside.
    #   its inputs*: plane that fits frame while two points that made it sit off
    #   edge answers nothing. Edit session is opposite case and must stay that
    #   way -- its staged geometry replaces very object it would be framed against.
    var scene = initScene()
    let
      handle_first = scene.addItem(
        toMultivector(Position(x: 16.0, y: -13.0, z: 4.0)), "m", Ink.Rose
      )
      handle_second = scene.addItem(
        toMultivector(Position(x: -12.0, y: 14.0, z: -6.0)), "n", Ink.Rose
      )
    let staged = scene.previewApplying(Operation.Wedge, handle_first, handle_second)
    check staged.isSome
    for azimuth in AZIMUTHS_AIM:
      for elevation in ELEVATIONS_AIM:
        let camera = placementAim(azimuth, elevation)
        let aim = aimFor(scene, Selection(), staged, camera.drawExtentFor(HEIGHT_AIM))
        let framed = camera.placed(placementFor(
          aim.get, scene, Selection(), staged, camera, WIDTH_AIM, HEIGHT_AIM
        ))
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
    let alone = some(previewStaging(scene.geometryOf(handle_first), RADIUS_ITEM_DEFAULT))
    let camera = placementAim(0.7, 0.2)
    let aim = aimFor(scene, Selection(), alone, camera.drawExtentFor(HEIGHT_AIM))
    let framed = camera.placed(placementFor(
      aim.get, scene, Selection(), alone, camera, WIDTH_AIM, HEIGHT_AIM
    ))
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
    var camera = placementAim(0.0, 0.42)
    camera.distance = 19.0
    let spread = rimAt(camera, positionAnchor(ground).get)
    check spread.is_past_box
    check not spread.is_off_frame
    check isShownCentrally(ground, camera, WIDTH_AIM, HEIGHT_AIM)

    # Now far enough back that whole disc fits well inside frame, and walk where it.
    #   is drawn out sideways until its own centre leaves centred box. Rim is still
    #   wholly on screen there, so what refuses it is centre alone -- half
    #   rim-only test would miss.
    var afar = camera
    afar.distance = 40.0
    let projection_afar = afar.initMatrixViewProjection(WIDTH_AIM/HEIGHT_AIM)
    # Sideways along camera's own right, which at any elevation lies flat in plane.
    #   disc is drawn in -- so this walks where circle is centred without lifting it
    #   off its own plane, and moves it across screen rather than into distance.
    let across = afar.frame(afar.eye).axis_right
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
    near.distance = 6.0
    check rimAt(near, positionAnchor(ground).get).is_off_frame
    check not isShownCentrally(ground, near, WIDTH_AIM, HEIGHT_AIM)


  test "a plane filling the frame is not in view; framing pulls its whole disc in":
    # Complaint this rule was rewritten for: disc wide enough to cover box was.
    #   read as in view -- sight axis struck it, so picking it moved camera not at
    #   all -- while reader could see no edge of circle anywhere.
    let ground = toMultivector(ORIGIN) ∧ toMultivector(Position(x: 1.0, y: 0.0, z: 0.0)) ∧
      toMultivector(Position(x: 0.0, y: 1.0, z: 0.0))
    let (scene, picked) = sceneOf(ground)
    for azimuth in AZIMUTHS_AIM:
      for elevation in ELEVATIONS_AIM:
        # Close in, where disc of radius `EXTENT_PLANE_F` cannot fit at all.
        var camera = placementAim(azimuth, elevation)
        camera.distance = 6.0
        check not isShownCentrally(ground, camera, WIDTH_AIM, HEIGHT_AIM)
        let framed = camera.placed(framedFor(scene, picked, camera))
        check isShownCentrally(ground, framed, WIDTH_AIM, HEIGHT_AIM)
        check framed.distance > camera.distance # Only pull-back could have done it.
        # Every point of rim, not just two box's own axes happen to catch.
        let axes = frame(ground).get
        let view_projection =
          framed.initMatrixViewProjection(WIDTH_AIM/HEIGHT_AIM)
        let (margin_x, margin_y) = marginsCentred()
        var is_past_box = false
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
          # ... and rim is allowed to reach past *centred box* on way, which is.
          #   whole of what this rule loosened. Without this case would pass just as
          #   well under stricter one and say nothing about which is in force.
          if at.x < margin_x or at.x > float(WIDTH_AIM) - margin_x or
              at.y < margin_y or at.y > float(HEIGHT_AIM) - margin_y:
            is_past_box = true
        check is_past_box
        # And it costs strictly less than making disc fit that box would have.
        check framed.distance <
          distanceFitting(EXTENT_PLANE_F, camera, WIDTH_AIM, HEIGHT_AIM, 0.0)


  test "a plane is judged by the disc drawn, not by the one its support would carry":
    # `mesh.addPlane` centres disc on item's own creation anchor where it has one,
    #   and on demo scene's own planes two stand as far as 3.7 units apart against
    #   radius of 8 -- so test ringing support would frame circle nobody sees.
    let ground = toMultivector(ORIGIN) ∧ toMultivector(Position(x: 1.0, y: 0.0, z: 0.0)) ∧
      toMultivector(Position(x: 0.0, y: 1.0, z: 0.0))
    var camera = placementAim(0.0, 0.9)
    camera.distance = 32.0
    # Fits about its own support at this distance, and does not once disc is drawn.
    #   long way off along plane instead.
    check isShownCentrally(ground, camera, WIDTH_AIM, HEIGHT_AIM)
    check not isShownCentrally(
      ground, camera, WIDTH_AIM, HEIGHT_AIM, some(Position(x: 14.0, y: 0.0, z: 0.0))
    )
    # And framing rule follows same anchor, item by item: same plane in.
    #   same scene at same camera costs nothing without one and moves view with it.
    let (scene_support, picked_support) = sceneOf(ground)
    check framedFor(scene_support, picked_support, camera) == camera.placementOf

    var (scene_drawn, picked_drawn) = (initScene(), Selection())
    picked_drawn.toggle(scene_drawn.addItem(
      ground, "ground", Ink.Rose, 0.0, some(Position(x: 14.0, y: 0.0, z: 0.0))
    ))
    let framed = framedFor(scene_drawn, picked_drawn, camera)
    check not (framed == camera.placementOf)
    check framed.pivot.x > camera.pivot.x # Panned toward circle actually drawn.
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
    let camera = placementAim(0.0, 0.0)
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
        let camera = placementAim(azimuth, elevation)
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
        var camera = placementAim(azimuth, elevation)
        check isShownAll(scene, picked, none(Preview), camera, WIDTH_AIM, HEIGHT_AIM)
        let framed = framedFor(scene, picked, camera)
        check framed.pivot =~ middle
        check framed.distance == camera.distance
        check framed.azimuth == camera.azimuth
        check framed.elevation == camera.elevation
        # End to end: ease carries pivot there and leaves everything else alone.
        var tween: CameraTween
        tween.offerAim(
          camera, scene, picked, none(Preview), camera.drawExtentFor(HEIGHT_AIM),
      WIDTH_AIM, HEIGHT_AIM, 0.0, 0.35
        )
        tween.settle(camera)
        check camera.pivot =~ middle
        check camera.distance == placementAim(azimuth, elevation).distance
        check camera.azimuth == placementAim(azimuth, elevation).azimuth


  test "an object picked on its own is carried to the middle, and nothing else moves":
    # Single pick has one middle and it is object itself, so pivot lands on it.
    #   exactly -- and once it is centred there is nothing left for zoom or turn to
    #   fix, which is least-movement rule holding over everything reader set.
    let place = Position(x: 9.0, y: -7.0, z: 4.0)
    let (scene, picked) = sceneOf(toMultivector(place))
    for azimuth in AZIMUTHS_AIM:
      for elevation in ELEVATIONS_AIM:
        let camera = placementAim(azimuth, elevation)
        let framed = framedFor(scene, picked, camera)
        check isShownAll(
          scene, picked, none(Preview), camera.placed(framed), WIDTH_AIM, HEIGHT_AIM
        )
        check framed.pivot =~ place
        check framed.distance == camera.distance
        check framed.azimuth == camera.azimuth
        check framed.elevation == camera.elevation


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
          let camera = placementAim(azimuth, elevation)
          let framed = framedFor(scene, picked, camera)
          check framed.azimuth == camera.azimuth
          check framed.elevation == camera.elevation


  test "the camera pulls back only as far as it must, and never pulls in":
    let (scene, picked) = sceneOf(
      toMultivector(Position(x: 14.0, y: -11.0, z: 3.0)),
      toMultivector(Position(x: -9.0, y: 12.0, z: -5.0)),
    )
    for azimuth in AZIMUTHS_AIM:
      for elevation in ELEVATIONS_AIM:
        let camera = placementAim(azimuth, elevation)
        let framed = framedFor(scene, picked, camera)
        check framed.distance >= camera.distance # Never pulls in ...
        # ... and not step further than it takes, pan and zoom judged together: tenth.
        #   of way back along very move fails.
        let short = camera.placementOf.toward(framed, 0.9)
        check not isShownAll(
          scene, picked, none(Preview), camera.placed(short), WIDTH_AIM, HEIGHT_AIM
        )


  test "a selection tight enough to fit already keeps the reader's own scale":
    # Half of "only when it must" that spread selection cannot show: distance left.
    #   exactly alone, not merely one that did not grow much.
    let (scene, picked) = sceneOf(
      toMultivector(Position(x: 0.7, y: 0.4, z: 0.2)),
      toMultivector(Position(x: -0.6, y: -0.3, z: 0.5)),
    )
    for azimuth in AZIMUTHS_AIM:
      for elevation in ELEVATIONS_AIM:
        let camera = placementAim(azimuth, elevation)
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
    let camera = placementAim(0.0, 0.0)
    # Picked beside point, point alone decides where to look and what it costs:
    #   aim's sphere collapses onto it, so move is pan toward point, cut short
    #   moment its dot fits -- no dolly toward that distant support, ever.
    let (scene, picked) = sceneOf(point, line)
    let aim = aimFor(scene, picked, none(Preview), camera.drawExtentFor(HEIGHT_AIM))
    check aim.get.is_bound_by_fitted
    check aim.get.sphere.get.radius =~ 0.0
    let framed = framedFor(scene, picked, camera)
    check framed.distance == camera.distance
    check framed.azimuth == camera.azimuth
    check isShownAll(
      scene, picked, none(Preview), camera.placed(framed), WIDTH_AIM, HEIGHT_AIM
    )


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
      let camera = placementAim(azimuth, 0.3)
      let framed = framedFor(scene_star, picked_star, camera)
      check isShownCentrally(star, camera.placed(framed), WIDTH_AIM, HEIGHT_AIM)
      check framed.pivot =~ camera.pivot # Orbit turned; what it turns about did not.
      check framed.distance =~ camera.distance
      if isShownCentrally(star, camera, WIDTH_AIM, HEIGHT_AIM): continue
      let short = camera.placementOf.toward(framed, 0.9)
      check not isShownCentrally(star, camera.placed(short), WIDTH_AIM, HEIGHT_AIM)

    # Beside anything finite, finite framing wins outright and angles stand: star.
    #   behind reader and point in front have no one placement showing both.
    let (scene_both, picked_both) =
      sceneOf(star, toMultivector(Position(x: 3.0, y: -2.0, z: 1.0)))
    let camera = placementAim(0.7, 0.2)
    let framed = framedFor(scene_both, picked_both, camera)
    check framed.azimuth == camera.azimuth
    check framed.elevation == camera.elevation


  test "an empty selection withdraws the offer, and so does geometry that draws nothing":
    var camera = placementAim(0.0, 0.2)
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
      camera, scene, Selection(), some(previewStaging(empty, RADIUS_ITEM_DEFAULT)),
      camera.drawExtentFor(HEIGHT_AIM), WIDTH_AIM, HEIGHT_AIM, 0.2, 0.35,
    )
    check tween.goal.isNone


  test "the whole selection is framed end to end, through the standing offer":
    # Driving rule way front-end does, rather than calling `placementFor`.
    #   directly: offer, ease, and arrival, over whole animation.
    const DURATION = 0.35
    var camera = placementAim(1.6, 0.2)
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


  test "a pointer pick keeps the object's pixel through the ease and ends at its fit":
    # What right-click promises: object clicked stays under pointer while camera comes.
    #   in, and dot (two pixels of radius, forty units out) comes in until its disc
    #   spans `FRACTION_HEIGHT_APPROACH_POINT` of frame's height.
    const
      DURATION = 0.35
      ASPECT = float(WIDTH_AIM)/float(HEIGHT_AIM)
      RADIUS = 0.08
    for azimuth in AZIMUTHS_AIM:
      for elevation in ELEVATIONS_AIM:
        var camera = placementAim(azimuth, elevation)
        # Stand point forty units ahead and well off sight axis, so pixel is not middle.
        let
          eye = camera.eye
          axes = camera.frame(eye)
          place = eye + 40.0*axes.forward + 4.0*axes.axis_right - 2.0*axes.axis_up
        var (scene, picked) = sceneOf(toMultivector(place))
        scene.setRadius(picked.at(0), RADIUS)
        let pixel = projectToScreen(
          camera.initMatrixViewProjection(ASPECT), WIDTH_AIM, HEIGHT_AIM, place
        )
        var
          tween: CameraTween
          pointer = some(PointerPick(handle: picked.at(0), cursor: pixel))
        tween.offerAim(
          camera, scene, picked, none(Preview), camera.drawExtentFor(HEIGHT_AIM),
          WIDTH_AIM, HEIGHT_AIM, 0.0, DURATION, pointer,
        )
        check pointer.isNone # Spent by offer.
        check tween.anchor_held.isSome
        for step in 1 .. 5:
          tween.advance(camera, DURATION*float(step)/5.0, easeOutCubic)
          let now_at = projectToScreen(
            camera.initMatrixViewProjection(ASPECT), WIDTH_AIM, HEIGHT_AIM, place
          )
          check abs(now_at.x - pixel.x) < 0.01
          check abs(now_at.y - pixel.y) < 0.01
        check tween.is_arrived
        check camera.azimuth == placementAim(azimuth, elevation).azimuth
        check camera.elevation == placementAim(azimuth, elevation).elevation
        let fit = depthSpanning(2.0*RADIUS, FRACTION_HEIGHT_APPROACH_POINT, camera)
        check abs(camera.distance - fit) < 1.0e-9
        # Pivot at anchor's depth: point and pivot equally far along sight.
        let eye_settled = camera.eye
        check abs(dot(place - eye_settled, camera.frame(eye_settled).forward) - fit) < 1.0e-6


  test "a pointer pick never moves the eye further off than the object stands":
    # Object already nearer than its fit leaves picture as it is: pivot alone comes to.
    #   its depth. Point seen at its size, and line, come in to orbit distance and no
    #   further; only floor dot comes in to its fit.
    let camera = placementAim(0.7, 0.2)
    let
      eye = camera.eye
      axes = camera.frame(eye)
      scale = camera.drawExtentFor(HEIGHT_AIM)
      near = eye + 0.3*axes.forward + 0.02*axes.axis_right
      far = eye + 40.0*axes.forward + 3.0*axes.axis_up
    let placed_near = placementUnderPointer(near, Shape.Point, 0.08, near, camera, scale)
    check placed_near.isSome
    check abs(placed_near.get.distance - 0.3) < 1.0e-9
    check camera.placed(placed_near.get).eye =~ eye
    # Radius half unit stands forty out at thirteen pixels, plainly seen: orbit distance.
    let placed_seen = placementUnderPointer(far, Shape.Point, 0.5, far, camera, scale)
    check placed_seen.isSome
    check abs(placed_seen.get.distance - camera.distance) < 1.0e-9
    let placed_line = placementUnderPointer(far, Shape.Line, 0.0, far, camera, scale)
    check placed_line.isSome
    check abs(placed_line.get.distance - camera.distance) < 1.0e-9
    let behind = eye - 2.0*axes.forward
    let placed_behind = placementUnderPointer(behind, Shape.Point, 0.08, behind, camera, scale)
    check placed_behind.isNone


  test "a depth spanning a fraction of the frame is read off the lens":
    # Two units across at half of 45-degree frame: 2/(2*0.5*tan 22.5) = 4.83.
    let camera = placementAim(0.0, 0.0)
    check abs(depthSpanning(2.0, 0.5, camera) - 2.0/(2.0*0.5*tan(degToRad(22.5)))) < 1.0e-9
    check depthSpanning(0.0, 0.5, camera) == DISTANCE_LIMIT_NEAR


  test "a plane picked by pointer is brought to its size both ways, crossing held":
    # Disc's centre comes to depth where its diameter spans.
    #   `FRACTION_HEIGHT_APPROACH_PLANE` of frame, from too far and from too near alike,
    #   while place under pointer keeps its pixel and angles stand.
    const
      DURATION = 0.35
      ASPECT = float(WIDTH_AIM)/float(HEIGHT_AIM)
    let ground = planeThrough(toMultivector(ORIGIN), toMultivector(UP_WORLD))
    for distance in [12.0, 1.0]:
      var camera = initCamera(pivot = ORIGIN, distance = distance, azimuth = 0.7, elevation = 0.5)
      var (scene, picked) = sceneOf(ground)
      let cursor = ScreenPosition(x: 0.62*float(WIDTH_AIM), y: 0.58*float(HEIGHT_AIM))
      let scale = camera.drawExtentFor(HEIGHT_AIM)
      let crossing =
        positionUnderPointerOn(scene, picked.at(0), camera, scale, WIDTH_AIM, HEIGHT_AIM, cursor)
      check crossing.isSome
      var
        tween: CameraTween
        pointer = some(PointerPick(handle: picked.at(0), cursor: cursor))
      tween.offerAim(
        camera, scene, picked, none(Preview), scale, WIDTH_AIM, HEIGHT_AIM, 0.0, DURATION,
        pointer,
      )
      check tween.anchor_held.isSome
      tween.settle(camera)
      let eye = camera.eye
      let depth_centre = dot(ORIGIN - eye, camera.frame(eye).forward)
      let wanted = depthSpanning(2.0*EXTENT_PLANE_F, FRACTION_HEIGHT_APPROACH_PLANE, camera)
      check abs(depth_centre - wanted) < 1.0e-6
      check camera.azimuth == 0.7
      check camera.elevation == 0.5
      let pixel = projectToScreen(
        camera.initMatrixViewProjection(ASPECT), WIDTH_AIM, HEIGHT_AIM, crossing.get
      )
      check abs(pixel.x - cursor.x) < 0.01
      check abs(pixel.y - cursor.y) < 0.01


  test "a group picked by pointer frames as ever":
    # Group has to fit, which holding one pixel cannot promise: `placementFor`, no anchor.
    const DURATION = 0.35
    var camera = placementAim(1.6, 0.2)
    let (scene_two, picked_two) = sceneOf(
      toMultivector(Position(x: 14.0, y: -11.0, z: 3.0)),
      toMultivector(Position(x: -9.0, y: 12.0, z: -5.0)),
    )
    var
      tween_two: CameraTween
      pointer = some(PointerPick(
        handle: picked_two.at(1), cursor: ScreenPosition(x: 700.0, y: 450.0)
      ))
    tween_two.offerAim(
      camera, scene_two, picked_two, none(Preview), camera.drawExtentFor(HEIGHT_AIM),
      WIDTH_AIM, HEIGHT_AIM, 0.0, DURATION, pointer,
    )
    check tween_two.goal.isSome
    check tween_two.anchor_held.isNone
    check tween_two.destination ==
      framedFor(scene_two, picked_two, camera)


  test "a pointer re-pick of an object the camera already holds aims afresh":
    # Standing offer ignores goal it holds, so same object picked again after wheel took.
    #   reader off went nowhere: "sometimes it doesn't zoom in".
    const DURATION = 0.35
    var camera = placementAim(0.7, 0.2)
    let
      eye = camera.eye
      axes = camera.frame(eye)
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
    let pixel = projectToScreen(
      camera.initMatrixViewProjection(float(WIDTH_AIM)/float(HEIGHT_AIM)),
      WIDTH_AIM, HEIGHT_AIM, place,
    )
    pointer = some(PointerPick(handle: picked.at(0), cursor: pixel))
    tween.offerAim(
      camera, scene, picked, none(Preview), camera.drawExtentFor(HEIGHT_AIM),
      WIDTH_AIM, HEIGHT_AIM, 2.0, DURATION, pointer,
    )
    check not tween.is_arrived
    check tween.destination.distance < camera.distance


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

    let horizon = attitude(LINES[0]) # Line's attitude is point at horizon.
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

  proc placeOn(camera: Camera, pivot: Position): CameraPlacement =
    ## Move camera's placement onto pivot, leaving its orbit exactly as it stands.
    result = camera.placementOf
    result.pivot = pivot


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
    var arrival = camera.placementOf
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
    check tween.placement_from.pivot.x =~ reached
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
    var arrival = camera.placementOf
    arrival.azimuth = -3.0
    tween.aimAt(camera, aimOn(Position(x: 1, y: 0, z: 0)), arrival, 0.0, DURATION)
    tween.advance(camera, DURATION*0.5, easeOutCubic)
    check camera.azimuth > 3.0 # Onward past +pi, not back down through zero.


  test "settle puts the camera on its destination at once":
    var camera = initCamera(ORIGIN, 12.0, 0.0, 0.4)
    var tween: CameraTween
    var arrival = camera.placementOf
    (arrival.azimuth, arrival.elevation, arrival.distance) = (1.0, 0.5, 30.0)
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

    # User pans, and same goal keeps being offered every frame after.
    camera.pan(3.0, 2.0)
    let pivot_panned = camera.pivot
    for frame in 1 .. 10:
      let now = 0.35 + 0.016*float(frame)
      tween.aimAt(camera, goal, camera.placeOn(arrival), now, 0.35)
      tween.advance(camera, now, easeOutCubic)
    check camera.pivot =~ pivot_panned


  test "abandon hands the camera to the user without re-arming the standing offer":
    # `release` here would be actively wrong, and was: it clears goal, so aim.
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

    camera.pan(3.0, 2.0)
    tween.abandon()
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
    camera.pan(3.0, 2.0)
    let pivot_panned = camera.pivot

    tween.release()
    check tween.goal.isNone
    tween.aimAt(camera, goal, camera.placeOn(arrival), 1.0, 0.35)
    check tween.goal.isSome
    check not tween.is_arrived
    tween.advance(camera, 1.0 + 0.35, easeOutCubic)
    check camera.pivot =~ arrival
    check not (camera.pivot =~ pivot_panned)



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
    check clock.travelAt(ITEMS_MAX) == 0.0
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
    scene.addItem(POINTS[0], "a", Ink.Rose)
    scene.addItem(POINTS[1], "b", Ink.Rose)
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
    for handle in 0 ..< ITEMS_MAX: selection.toggle(handle)
    check selection.len == ITEMS_MAX
    selection.toggle(ITEMS_MAX) # Out of range; capacity is already spent.
    check selection.len == ITEMS_MAX


  test "pruneDead drops removed handles and keeps the rest in pick order":
    # Removed handle goes straight back to free list, so stale pick left behind.
    #   would silently reattach itself to whatever object is added next.
    var scene = initScene()
    for i in 0 ..< 3: discard scene.addItem(POINTS[i], "p" & $i, inkCycled(i))
    var selection: Selection
    for handle in [2, 0, 1]: selection.toggle(handle)
    scene.removeItem(0)
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



# Arena is desktop-only -- it casts pointer over global and carves typed slices.
#   from it, which JS backend cannot do -- so its own suite runs on that backend alone.
when not defined(js):
  suite "Arena Swap":
    # Two blocks big enough to tell apart by what is written into them, and small enough.
    #   that filling one is test rather than wait.
    var backing_first: array[512, byte]
    var backing_second: array[512, byte]

    test "a frame carves from one block while the other holds the frame before it":
      # Pair's whole promise: what this frame writes is still readable next frame.
      var pair = initArenaSwap(backing_first, backing_second)
      let written = pair.current.push[:int32](4)
      for i in 0 ..< 4: written[i] = int32(100 + i)
      check pair.current.used == 4*sizeof(int32)

      pair.swap()
      # Last frame's block, untouched by swap that reclaimed other one.
      let carried = cast[ptr UncheckedArray[int32]](addr backing_first[0])
      for i in 0 ..< 4: check carried[i] == int32(100 + i)
      check pair.previous.used == 4*sizeof(int32)

    test "the block a frame begins on holds nothing, whatever was in it":
      var pair = initArenaSwap(backing_first, backing_second)
      discard pair.current.push[:int32](8)
      pair.swap()
      discard pair.current.push[:int32](2)
      check pair.current.used == 2*sizeof(int32)
      # Swap again: first block comes back current and is reclaimed on way in.
      #   What "starts completely clean" means; not reclaimed on way out, since that
      #   would take last frame's bytes away while they were still wanted.
      pair.swap()
      check pair.current.used == 0
      check pair.previous.used == 2*sizeof(int32)

    test "a carve outlives exactly one swap and no more":
      # Two frames is lifetime. On second swap block is current again and its.
      #   offset is back to zero, so next carve hands out very same bytes.
      var pair = initArenaSwap(backing_first, backing_second)
      let first = pair.current.push[:int32](1)
      pair.swap()
      pair.swap()
      let again = pair.current.push[:int32](1)
      check cast[int](first) == cast[int](again)

    test "the pair reports both blocks, and the high-water mark of either":
      var pair = initArenaSwap(backing_first, backing_second)
      check pair.capacitySwap == len(backing_first) + len(backing_second)
      discard pair.current.push[:int32](6)
      pair.swap()
      discard pair.current.push[:int32](2)
      # Larger of two, never their sum: they hold one frame's work each, so sum.
      #   would name quantity no single frame ever reached.
      check pair.peakUsedSwap == 6*sizeof(int32)
      check pair.usedSwap == 2*sizeof(int32)



# PNG and GIF encoding, and arena backing both, are desktop-only: each binds C.
#   entry point JS backend has none of, so these run on that backend alone.
when not defined(js):
  suite "Image":
    var buffer_arena: array[1024*1024, byte]

    test "written file is a PNG carrying the size it was given":
      const (WIDTH, HEIGHT) = (37, 21)
      var pixels = newSeq[uint8](WIDTH*HEIGHT*3)
      for i in 0 ..< len(pixels): pixels[i] = uint8((i*7) mod 256)

      var test_arena = initArena(buffer_arena)
      let path = getTempDir() / "visualiser_suite.png"
      writePng(test_arena, path, WIDTH, HEIGHT, pixels)
      defer: removeFile(path)
      let document = readFile(path)

      check len(document) > 8
      check document[0 .. 7] == "\x89PNG\r\n\x1A\n"
      check document[12 .. 15] == "IHDR"
      check document[16 .. 19] == "\0\0\0" & char(WIDTH)
      check document[20 .. 23] == "\0\0\0" & char(HEIGHT)
      check document[24] == char(8) # Bit depth.
      check document[25] == char(2) # Colour type: truecolour.
      check document.find("IDAT") > 0
      check document[^8 .. ^5] == "IEND"


    test "chunk lengths and checksums agree end to end":
      const (WIDTH, HEIGHT) = (16, 9)
      var pixels = newSeq[uint8](WIDTH*HEIGHT*3)
      var test_arena = initArena(buffer_arena)
      let path = getTempDir() / "visualiser_suite_chunks.png"
      writePng(test_arena, path, WIDTH, HEIGHT, pixels)
      defer: removeFile(path)
      let document = readFile(path)

      # Walk chunks by their own lengths; landing exactly on end proves each is sound.
      var
        offset = 8
        names: seq[string]
      while offset < len(document):
        var length = 0
        for i in 0 .. 3: length = length*256 + int(uint8(document[offset + i]))
        names.add(document[offset + 4 .. offset + 7])
        offset += 12 + length
      check offset == len(document)
      check names == @["IHDR", "IDAT", "IEND"]



  suite "Gif":
    var buffer_arena: array[1024*1024, byte]

    test "written file carries the size and frame count it was given":
      const (WIDTH, HEIGHT) = (12, 8)
      var frames = newSeq[uint8](3*WIDTH*HEIGHT*3)
      var test_arena = initArena(buffer_arena)
      let path = getTempDir() / "visualiser_suite.gif"
      writeGif(test_arena, path, WIDTH, HEIGHT, frames, 3, 8)
      defer: removeFile(path)
      let document = readFile(path)

      check document[0 .. 5] == "GIF89a"
      check uint8(document[6]) == uint8(WIDTH) and uint8(document[7]) == 0
      check uint8(document[8]) == uint8(HEIGHT) and uint8(document[9]) == 0
      check document[^1] == char(0x3B)

      # Walk every frame's own blocks by their own lengths, landing exactly on.
      #   trailer proves each frame's sub-blocks are sound, exactly as PNG test does.
      # Signature, logical screen, colour table, application extension.
      const HEADER_LEN = 6 + 7 + 256*3 + 19
      var
        offset = HEADER_LEN
        count_frames = 0
      while document[offset] == '\x21':
        offset += 8 # Graphic Control Extension is fixed length.
        check document[offset] == '\x2C' # Image Descriptor.
        offset += 10 + 1 # Image Descriptor fields, then LZW minimum code size byte.
        while true:
          let length = int(uint8(document[offset]))
          offset += 1
          if length == 0: break
          offset += length
        inc count_frames
      check count_frames == 3
      check offset == len(document) - 1
      check document[offset] == char(0x3B)


    proc decodeGifFrame(data: seq[uint8]): seq[uint8] =
      ## Decode one frame's own LZW sub-block stream back to palette indices.
      ##   By exactly algorithm any GIF89a reader implements, mirroring `gif.nim`'s
      ##   encoder, not calling into it, so this stands as independent check of what it
      ##   wrote.
      ##   Widens its own code width one step earlier than encoder does.
      ##     GIF's LZW is asymmetric here by design ("early change"), since decoder's
      ##     dictionary always trails encoder's by one entry it has not yet been told
      ##     about.
      const
        BITS_CODE = 8
        COUNT_TABLE = 1 shl BITS_CODE
        CODE_CLEAR = COUNT_TABLE
        CODE_END = CODE_CLEAR + 1
        CODE_MAX = 4096
      var
        pos_bit = 0
        dict: Table[int, seq[uint8]]
        next_code = CODE_END + 1
        width = BITS_CODE + 1
        prev: seq[uint8]
        has_prev = false

      proc readCode(width: int): int =
        for i in 0 ..< width:
          let (byte_index, bit_index) = ((pos_bit + i) div 8, (pos_bit + i) mod 8)
          if byte_index < len(data):
            result = result or (int((data[byte_index].int shr bit_index) and 1) shl i)
        pos_bit += width

      while true:
        let code = readCode(width)
        if code == CODE_CLEAR:
          dict.clear()
          next_code = CODE_END + 1
          width = BITS_CODE + 1
          has_prev = false
          continue
        if code == CODE_END: break

        var entry: seq[uint8]
        if code < COUNT_TABLE: entry = @[uint8(code)]
        elif dict.hasKey(code): entry = dict[code]
        elif code == next_code and has_prev: entry = prev & @[prev[0]]
        else: doAssert false, &"Bad LZW code {code}."
        result.add(entry)
        if has_prev and next_code < CODE_MAX:
          dict[next_code] = prev & @[entry[0]]
          inc next_code
          if next_code >= (1 shl width) and width < 12: inc width
        prev = entry
        has_prev = true


    test "written frame decodes back to what it was quantized to, past a code-width growth":
      ## Guard against growing LZW code width one symbol too early.
      ##   Packs bits real reader disagrees with, corrupting every code from there on.
      ##   Flat or small image never reaches dictionary sizes where that bites, so this
      ##   drives enough distinct colour pairs to grow code width at least once.
      const (WIDTH, HEIGHT) = (64, 64)
      var frame = newSeq[uint8](WIDTH*HEIGHT*3)
      for i in 0 ..< WIDTH*HEIGHT:
        frame[i*3] = uint8((i*173) mod 256)
        frame[i*3 + 1] = uint8((i*97) mod 256)
        frame[i*3 + 2] = uint8((i*211) mod 256)

      # `writeGif` takes rows bottom-up and writes them top-down, exactly as `writePng`.
      #   does; build expected indices in that same written order, not source's.
      var expected: seq[uint8]
      for row_top in 0 ..< HEIGHT:
        let row_source = HEIGHT - 1 - row_top
        for column in 0 ..< WIDTH:
          let at = (row_source*WIDTH + column)*3
          expected.add(paletteIndex(frame[at], frame[at + 1], frame[at + 2]))

      var test_arena = initArena(buffer_arena)
      let path = getTempDir() / "visualiser_suite_growth.gif"
      writeGif(test_arena, path, WIDTH, HEIGHT, frame, 1, 8)
      defer: removeFile(path)
      let document = readFile(path)

      const HEADER_LEN = 6 + 7 + 256*3 + 19
      var offset = HEADER_LEN + 8 + 10 # Past Graphic Control Extension and Image Descriptor.
      let width_code = uint8(document[offset])
      check width_code == 8
      offset += 1

      var sub_blocks: seq[uint8]
      while true:
        let length = int(uint8(document[offset]))
        offset += 1
        if length == 0: break
        for i in 0 ..< length: sub_blocks.add(uint8(document[offset + i]))
        offset += length

      let decoded = decodeGifFrame(sub_blocks)
      check len(decoded) == WIDTH*HEIGHT
      check decoded == expected



suite "Help":
  test "every entry lands in exactly one tab, and the tabs account for the whole table":
    # What stops reflow that quietly drops row to make rest fit. `countOf` is what.
    #   both front-ends size tab from, so summing it is summing what is actually drawn.
    var total = 0
    for path in HelpPath: total += countOf(path)
    check total == len(lut_help_entries)


  test "no tab holds more than fits the smallest screen this help supports":
    # Asserted at compile time too, in `help.nim`'s own `static` block; stated here as well.
    #   because that assertion is invisible in passing run, and this is property
    #   whole tab split exists to hold.
    #   Two paths have bounds of their own. `keys` describes keyboard, and screen this
    #   bound is proxy for is phone; `operations` *is* catalogue, one row per
    #   operation, and only bound worth holding it to is that size exactly.
    for path in HelpPath:
      let entries_max =
        case path
        of HelpPath.Operations: ENTRIES_MAX_PATH_CATALOGUE
        of HelpPath.Keys: ENTRIES_MAX_PATH_KEYS
        else: ENTRIES_MAX_PATH
      check countOf(path) in 1 .. entries_max


  test "the help records every operation the build offers, by the name it offers it under":
    # Generated from catalogue rather than transcribed, so this cannot drift -- and.
    #   case is here to say that if anyone ever transcribes it, drift fails build.
    for operation in Operation:
      var is_listed = false
      for entry in lut_help_entries:
        if entry.path == HelpPath.Operations and entry.action == notationSymbolic(operation):
          check entry.outcome == notationNamed(operation)
          is_listed = true
      check is_listed
    check countOf(HelpPath.Operations) == COUNT_OPERATION


  test "the help records every key, every motion and every action the view answers":
    # What "up to date" has to mean if it is to stay true: binding added without row.
    #   fails build day it is added, rather than being noticed by reader who
    #   went looking for it and found nothing.
    let text = block:
      var joined = ""
      for entry in lut_help_entries: joined &= entry.action & " " & entry.outcome & " "
      joined
    for key in Key:
      check nameOf(key) in text
    # Every motion and action is *described* by some row; rows group them by job, so.
    #   this asks for words reader would look for rather than enum's own name.
    for phrase in [
      "slide the view", "lower or raise", "orbit", "further out", "faster",
      "previous or next object", "select", "back into view", "back where it started",
    ]:
      check phrase in text


  test "a tab's entries are contiguous, so neither UI renders one tab twice":
    var
      seen: set[HelpPath]
      path_last = none(HelpPath)
    for entry in lut_help_entries:
      if path_last == some(entry.path): continue
      check entry.path notin seen
      seen.incl(entry.path)
      path_last = some(entry.path)


  test "every action and outcome is written, so no row draws as a blank line":
    for entry in lut_help_entries:
      check len(entry.action) > 0
      check len(entry.outcome) > 0


  test "every tab says what it is about, so none opens on rows with no context":
    # Check line above rows, carrying what two-column row cannot.
    #   Which menu this is, what wedge is; path added without one would render that line
    #   blank, which reads as gap rather than as omission.
    for path in HelpPath:
      check len(descriptionOf(path)) > 0
      # Sentence, not label: tab strip already carries short form.
      check len(descriptionOf(path)) > len(titleOf(path))


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
    near.addItem(toMultivector(Position(x: -0.5*eye.x, y: 0, z: -0.5*eye.z)), "p", Ink.Rose)
    let anchor_near = anchorZoomAt(
      near, camera, scale, view_projection, WIDTH_PICK, HEIGHT_PICK, CENTRE,
    )
    check anchor_near.isSome and abs(anchor_near.get.at.z + 0.5*eye.z) < 1.0e-6
    var far = initScene()
    far.addItem(toMultivector(Position(x: -7.0*eye.x, y: 0, z: -7.0*eye.z)), "p", Ink.Rose)
    let anchor_far = anchorZoomAt(
      far, camera, scale, view_projection, WIDTH_PICK, HEIGHT_PICK, CENTRE,
    )
    check anchor_far.isSome and abs(anchor_far.get.at.x) < 1.0e-6 and
      abs(anchor_far.get.at.z) < 1.0e-6

  test "a sun drawn wide is picked anywhere on its disc, over the plane behind it":
    # Pick radius follows drawn disc: Sol at 0.6 units from 1.2 units away spans about.
    #   360 pixels of radius on 600-pixel frame, and cursor anywhere inside picks Sol,
    #   not ecliptic disc it stands on.
    # Smallest arrangement; reduced-capacity build cannot hold it and skips whole.
    if ITEMS_MAX < itemsOf(ScaleOrrery.Nearest):
      skip()
    else:
      var scene = initScene()
      constructOrrery(scene, ScaleOrrery.Nearest)
      var handle_sol = -1
      for handle in 0 ..< scene.bound:
        if scene.isAlive(handle) and toText(scene.labelAt(handle)) == "sol": handle_sol = handle
      check handle_sol >= 0
      let camera = initCamera(
        pivot = Position(x: 0, y: 0, z: 0), distance = 1.2, azimuth = 0.9, elevation = 0.4
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
    let frame_camera = camera.frame(camera.eye)
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
    hidden.addItem(toMultivector(planet), "planet", Ink.Cobalt, radius = 0.3)
    hidden.addItem(toMultivector(star), "star", Ink.Rose, radius = 0.001)
    let on_star = projectToScreen(view_projection, WIDTH_PICK, HEIGHT_PICK, star)
    check abs(on_star.x - CENTRE.x - 40.0) < 1.0
    let report_hidden = pickAt(
      hidden, camera, scale, view_projection, WIDTH_PICK, HEIGHT_PICK, on_star
    )
    check report_hidden.handle == some(0)
    check report_hidden.count_rivals == 1 # Hidden star is no rival either.
    var shown = initScene()
    shown.addItem(toMultivector(planet), "planet", Ink.Cobalt, radius = 0.3)
    shown.addItem(toMultivector(moon), "moon", Ink.Rose, radius = 0.02)
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
    lunar.addItem(toMultivector(moon), "moon", Ink.Rose, radius = 0.02)
    lunar.addItem(toMultivector(eye + 3.0*(moon - eye)), "star", Ink.Jade, radius = 0.001)
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
    rim.addItem(toMultivector(planet), "planet", Ink.Cobalt, radius = 0.3)
    rim.addItem(toMultivector(near_rim), "star", Ink.Rose, radius = 0.001)
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
    clear.addItem(toMultivector(planet), "planet", Ink.Cobalt, radius = 0.3)
    clear.addItem(toMultivector(far), "star", Ink.Rose, radius = 0.001)
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
    alone.addItem(toMultivector(Position(x: 0, y: 0, z: 0)), "p", Ink.Rose)
    alone.addItem(groundPlane(), "ground", Ink.Grid)
    let report_alone = pickAt(
      alone, camera, scale, view_projection, WIDTH_PICK, HEIGHT_PICK, CENTRE
    )
    check report_alone.handle == some(0)
    check report_alone.count_rivals == 1
    # Second point nearly behind first, their dots overlapping: still two, and one in.
    #   front is what is picked. Dot narrower than fingertip hides other from pick, not
    #   from crowd; see pick's hiding rule. Star field's crowds are exactly such dots.
    var crowd = initScene()
    crowd.addItem(toMultivector(Position(x: 0, y: 0, z: 0)), "p", Ink.Rose)
    crowd.addItem(toMultivector(Position(x: 0.05, y: 0, z: 0.05)), "q", Ink.Jade)
    crowd.addItem(groundPlane(), "ground", Ink.Grid)
    check radiusPixelsAt(RADIUS_ITEM_DEFAULT, Position(x: 0, y: 0, z: 0), scale.scale) <
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
    #   it is not. Placed along camera's own right axis.
    let per_pixel = worldPerPixelAt(Position(x: 0, y: 0, z: 0), scale.scale)
    let right = camera.frame(camera.eye).axis_right
    for (pixels, rivals) in [(50.0, 2), (100.0, 1)]:
      var apart = initScene()
      apart.addItem(toMultivector(Position(x: 0, y: 0, z: 0)), "p", Ink.Rose)
      apart.addItem(toMultivector(Position(x: 0, y: 0, z: 0) + (pixels*per_pixel)*right),
        "q", Ink.Jade)
      let report = pickAt(
        apart, camera, scale, view_projection, WIDTH_PICK, HEIGHT_PICK, CENTRE
      )
      check report.handle == some(0)
      check report.count_rivals == rivals
    # Point beside picked line is rival too: finger may have meant it.
    var mixed = initScene()
    mixed.addItem(POINTS[0] ∧ POINTS[1], "l", Ink.Rose)
    mixed.addItem(toMultivector(Position(x: 0, y: 0, z: 0) + (50.0*per_pixel)*right),
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
    scene.addItem(toMultivector(Position(x: 0, y: 0, z: 0)), "p", Ink.Rose)
    let camera = cameraFacingOrigin()
    let view_projection = camera.initMatrixViewProjection(WIDTH_PICK/HEIGHT_PICK)
    check pickNearest(
      scene, camera, camera.drawExtentFor(HEIGHT_PICK), view_projection,
      WIDTH_PICK, HEIGHT_PICK, CENTRE
    ) == some(0)


  test "cursor far from every item picks nothing":
    var scene = initScene()
    scene.addItem(toMultivector(Position(x: 0, y: 0, z: 0)), "p", Ink.Rose)
    let camera = cameraFacingOrigin()
    let view_projection = camera.initMatrixViewProjection(WIDTH_PICK/HEIGHT_PICK)
    let corner = ScreenPosition(x: 5.0, y: 5.0, depth: 0.0)
    check pickNearest(
      scene, camera, camera.drawExtentFor(HEIGHT_PICK), view_projection,
      WIDTH_PICK, HEIGHT_PICK, corner
    ).isNone


  test "hidden item is never picked":
    var scene = initScene()
    scene.addItem(toMultivector(Position(x: 0, y: 0, z: 0)), "p", Ink.Rose)
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
    scene.addItem(axis_z, "axis_z", Ink.Jade)
    let camera = cameraFacingOrigin()
    let view_projection = camera.initMatrixViewProjection(WIDTH_PICK/HEIGHT_PICK)
    check pickNearest(
      scene, camera, camera.drawExtentFor(HEIGHT_PICK), view_projection,
      WIDTH_PICK, HEIGHT_PICK, CENTRE
    ) == some(0)


  test "a line's attitude is picked over the line it came from":
    # Attitude of line is point at horizon, and `tessellate.addLine` runs.
    #   line out to *exactly* where `addPoint` draws that attitude, "with no gap" -- so
    #   two overlap on screen precisely and ranking is what has to separate them.
    #   Points outrank lines, so star must win. It did not: `pickNearest` built its
    #   `DrawExtent` fieldwise, leaving `scale.eye_point` zero multivector, so
    #   `anchorFor` answered none for every horizon point and whole branch was skipped
    #   before anything could be ranked.
    let camera = cameraFacingOrigin()
    let view_projection = camera.initMatrixViewProjection(WIDTH_PICK/HEIGHT_PICK)
    let frame_camera = camera.frame(camera.eye)
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
    scene_line.addItem(line, "L", Ink.Jade)
    check pickNearest(
      scene_line, camera, camera.drawExtentFor(HEIGHT_PICK), view_projection,
      WIDTH_PICK, HEIGHT_PICK, at
    ) ==
      some(0)

    # With both in scene, star takes it.
    var scene = initScene()
    scene.addItem(line, "L", Ink.Jade)
    scene.addItem(star, "att", Ink.Cobalt)
    check pickNearest(
      scene, camera, camera.drawExtentFor(HEIGHT_PICK), view_projection,
      WIDTH_PICK, HEIGHT_PICK, at
    ) == some(1)


  test "point pick radius tolerates cursor imprecision, not unlimited slack":
    var scene = initScene()
    scene.addItem(toMultivector(Position(x: 0, y: 0, z: 0)), "p", Ink.Rose)
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
    scene.addItem(axis_z, "axis_z", Ink.Jade)
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
    scene.addItem(axis_z, "axis_z", Ink.Jade) # Index 0: line, passes straight through origin.
    scene.addItem(toMultivector(Position(x: 0, y: 0, z: 0)), "p", Ink.Rose) # Index 1: point.
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
    scene.addItem(facing, "facing", Ink.Olive) # Index 0: plane, spans view straight on.
    scene.addItem(axis_z, "axis_z", Ink.Jade) # Index 1: line, passes straight through origin.
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
    scene.addItem(facing, "facing", Ink.Olive) # Index 0: plane, spans view straight on.
    scene.addItem(toMultivector(Position(x: 0, y: 0, z: 0)), "p", Ink.Rose) # Index 1: point.
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
    scene.addItem(facing, "facing", Ink.Olive)
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
      scene.addItem(corners[0] ∧ corners[1] ∧ corners[2], "spanning", Ink.Olive)
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
    scene.addItem(far_plane, "far", Ink.Olive) # Index 0.
    scene.addItem(near_plane, "near", Ink.Cobalt) # Index 1.
    let camera = cameraFacingOrigin()
    let view_projection = camera.initMatrixViewProjection(WIDTH_PICK/HEIGHT_PICK)
    check pickNearest(
      scene, camera, camera.drawExtentFor(HEIGHT_PICK), view_projection,
      WIDTH_PICK, HEIGHT_PICK, CENTRE
    ) == some(1)



suite "Lighting":
  func isDark(light: Direction): bool = light.x == 0.0 and light.y == 0.0 and light.z == 0.0
    ## Report whether light is `LIGHT_NONE`; `Direction` refuses `==` on purpose.

  test "a point is lit from its nearest sun, and a sun or a sunless scene is lit from nowhere":
    let suns = [Position(x: 10, y: 0, z: 0), Position(x: 0, y: 3, z: 0)]
    let light = lightToward(Position(x: 0, y: 0, z: 0), suns, 2)
    check abs(light.y - 1.0) < 1.0e-12 and abs(light.x) < 1.0e-12
    check abs(norm(light) - 1.0) < 1.0e-12
    check isDark(lightToward(Position(x: 0, y: 0, z: 0), suns, 0))
    check isDark(lightToward(Position(x: 0, y: 3, z: 0), suns, 2)) # Standing on it.
    # Through scene: sun shines on planet, is unlit itself, and hidden sun sheds nothing.
    var scene = initScene()
    let handle_sun = scene.addItem(toMultivector(Position(x: 0, y: 0, z: 0)), "sun", Ink.Copper,
      shines = true)
    let handle_planet = scene.addItem(toMultivector(Position(x: 4, y: 0, z: 0)), "p", Ink.Cobalt)
    let handle_line = scene.addItem(POINTS[0] ∧ POINTS[1], "l", Ink.Rose)
    var cache: LightCache
    refreshLights(cache, scene, none(int))
    check abs(cache.lights[handle_planet].x + 1.0) < 1.0e-12
    check isDark(cache.lights[handle_sun])
    check isDark(cache.lights[handle_line])
    # Hidden sun sheds nothing; suns changed, so every light is redone whatever revision.
    scene.setVisible(handle_sun, false)
    refreshLights(cache, scene, some(scene.revision - 1))
    check isDark(cache.lights[handle_planet])
    scene.setVisible(handle_sun, true)
    refreshLights(cache, scene, some(scene.revision - 1))
    check abs(cache.lights[handle_planet].x + 1.0) < 1.0e-12
    # Placed variant answers same as placing one.
    var placed: array[ITEMS_MAX, Placed]
    for handle in 0 ..< scene.bound:
      if scene.isAlive(handle):
        placed[handle] = placeObject(scene.geometryOf(handle), scene.anchorOverrideAt(handle))
    var cache_placed: LightCache
    refreshLights(cache_placed, scene, placed, none(int))
    check cache_placed.lights[handle_planet].x == cache.lights[handle_planet].x
    check cache_placed.lights[handle_planet].y == cache.lights[handle_planet].y
    # Edit that moves planet alone relights that planet and leaves rest untouched.
    let revision_before = scene.revision
    scene.setGeometryAt(handle_planet, toMultivector(Position(x: 0, y: 5, z: 0)))
    refreshLights(cache, scene, some(revision_before))
    check abs(cache.lights[handle_planet].y + 1.0) < 1.0e-12
    check isDark(cache.lights[handle_sun])
    # Moving sun relights everything, revision or not.
    let revision_sun = scene.revision
    scene.setGeometryAt(handle_sun, toMultivector(Position(x: 0, y: 10, z: 0)))
    refreshLights(cache, scene, some(revision_sun))
    check abs(cache.lights[handle_planet].y - 1.0) < 1.0e-12



suite "Interaction":
  test "drag operation maps to the catalogue entry it names":
    check DragOperation.Join.toOperation == Operation.Wedge
    check DragOperation.Meet.toOperation == Operation.WedgeAnti
    check DragOperation.Project.toOperation == Operation.ProjectOrthogonal


  test "drag applies the proposal and appends the result":
    var scene = initScene()
    scene.addItem(POINTS[0], "a", Ink.Rose)
    scene.addItem(POINTS[1], "b", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.index_hover = some(0)
    check interaction.beginDrag(arming = MenuArming.OnDwell, now = 0.0)
    interaction.index_hover = some(1)
    let outcome = interaction.endDrag(scene)
    check scene.len == 3
    # Two points propose `join`, and item that lands is that join -- not button's.
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
    scene.addItem(POINTS[0], "a", Ink.Rose)
    scene.addItem(POINTS[1], "b", Ink.Rose)
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
    #   becomes orbit -- and plane at horizon is hovered wherever nothing else is,
    #   because it is drawn as dome over every direction. Were it to start drag, orbit
    #   and pan would stop working outright moment sky joined scene.
    var scene = initScene()
    scene.addItem(POINTS[0], "a", Ink.Rose)
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
    floor.addItem(groundPlane(), "ground", Ink.Grid)
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
    scene.addItem(POINTS[0], "a", Ink.Rose)
    scene.addItem(POINTS[1], "b", Ink.Rose)
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
    scene.addItem(POINTS[0], "a", Ink.Rose)
    scene.addItem(POINTS[1], "b", Ink.Rose)
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
    scene.addItem(POINTS[0], "a", Ink.Rose)
    scene.addItem(POINTS[1], "b", Ink.Rose)
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
    scene.addItem(POINTS[0], "a", Ink.Rose)
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
    scene.addItem(POINTS[0], "a", Ink.Rose)
    scene.addItem(POINTS[1], "b", Ink.Rose)
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
    scene.addItem(POINTS[0], "a", Ink.Rose)
    scene.addItem(POINTS[1], "b", Ink.Rose)
    scene.addItem(POINTS[2], "c", Ink.Rose)
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
    scene.addItem(POINTS[0], "a", Ink.Rose)
    scene.addItem(POINTS[1], "b", Ink.Rose)
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
    scene.addItem(POINTS[0], "a", Ink.Rose)
    scene.addItem(POINTS[1], "b", Ink.Rose)
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
    # Band, comet and ghost all read `inkOfDrag`, so what reader watched is.
    #   what they get. It used to be operation's own colour, which said nothing about
    #   object about to exist.
    var scene = initScene()
    scene.addItem(POINTS[0], "a", Ink.Rose)
    scene.addItem(POINTS[1], "b", Ink.Rose)
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
    scene.addItem(POINTS[0], "a", Ink.Rose)
    scene.addItem(POINTS[1], "b", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.index_hover = some(0)
    check not interaction.isClick(0.0)
    check interaction.beginDrag(arming = MenuArming.OnDwell, now = 0.0)
    interaction.index_hover = some(1)
    check interaction.endDrag(scene, 0.0).index_created == some(2)


  test "drag cannot start without a hovered item":
    var interaction = Interaction(is_enabled: true)
    interaction.index_hover = none(int)
    check not interaction.beginDrag(arming = MenuArming.Always, now = 0.0)
    check not interaction.is_dragging


  test "releasing over empty space adds nothing":
    var scene = initScene()
    scene.addItem(POINTS[0], "a", Ink.Rose)
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
    scene.addItem(POINTS[0], "a", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.index_hover = some(0)
    discard interaction.beginDrag(arming = MenuArming.OnDwell, now = 0.0)
    let outcome = interaction.endDrag(scene)
    check scene.len == 1
    check "own source" in outcome.message
    check outcome.index_created.isNone


  test "endDrag ignores a drag whose source was removed since it began":
    var scene = initScene()
    scene.addItem(POINTS[0], "a", Ink.Rose)
    scene.addItem(POINTS[1], "b", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.index_hover = some(0)
    discard interaction.beginDrag(arming = MenuArming.OnDwell, now = 0.0) # index_source = 0.
    scene.removeItem(0) # Source vanishes mid-drag -- e.g. removed by another input path.
    interaction.index_hover = some(1)
    let outcome = interaction.endDrag(scene)
    check "no longer exists" in outcome.message
    check outcome.index_created.isNone
    check not interaction.is_dragging
    check scene.len == 1


  test "endDrag ignores a drag whose destination was removed since it began":
    var scene = initScene()
    scene.addItem(POINTS[0], "a", Ink.Rose)
    scene.addItem(POINTS[1], "b", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.index_hover = some(0)
    discard interaction.beginDrag(arming = MenuArming.OnDwell, now = 0.0) # index_source = 0.
    scene.removeItem(1)
    interaction.index_hover = some(1) # Still reports now-dead handle as hovered.
    let outcome = interaction.endDrag(scene)
    check "no longer exists" in outcome.message
    check outcome.index_created.isNone
    check scene.len == 1


  test "cancelDrag clears state without applying anything":
    var scene = initScene()
    scene.addItem(POINTS[0], "a", Ink.Rose)
    scene.addItem(POINTS[1], "b", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.index_hover = some(0)
    discard interaction.beginDrag(arming = MenuArming.OnDwell, now = 0.0)
    interaction.cancelDrag()
    check not interaction.is_dragging
    check scene.len == 2


  test "endDrag with nothing dragging is a harmless no-op":
    var scene = initScene()
    scene.addItem(POINTS[0], "a", Ink.Rose)
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
    scene.addItem(GENERAL_FIRST[2], "G", Ink.Rose)
    scene.addItem(GENERAL_SECOND[0], "f", Ink.Rose)
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
    #   no item, never handle holding geometry with no shape.
    var scene = initScene()
    scene.addItem(GENERAL_FIRST[0], "a", Ink.Rose)
    scene.addItem(GENERAL_FIRST[0], "a again", Ink.Rose)
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
        # Whatever is proposed is drawable, so plain release never adds blank item.
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
    scene.addItem(GENERAL_FIRST[0], "a", Ink.Rose)
    scene.addItem(GENERAL_SECOND[0], "b", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.updateCursor(400.0, 300.0)
    interaction.index_hover = some(0)
    check interaction.beginDrag(arming = MenuArming.Always, now = 0.0)
    interaction.index_hover = some(1)
    interaction.updateDrag(scene, 0.0)
    check interaction.menu.isSome
    # Wheel opened under cursor, so nothing is chosen yet and nothing is ghosted.
    check interaction.proposal.isNone
    check interaction.preview.isNone
    # Reaching for wedge takes cursor off item; destination must survive it.
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


  test "the ghost is the wedge being aimed at, not what a plain release would make":
    # Complaint this answers: with wheel open, ghost was `proposalFor`'s own.
    #   answer whatever wedge cursor was in, so reader reaching for `project` watched
    #   ghost of `join` and only found out what they had asked for after letting go.
    var scene = initScene()
    scene.addItem(GENERAL_FIRST[0], "a", Ink.Rose)
    scene.addItem(GENERAL_SECOND[0], "b", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.updateCursor(400.0, 300.0)
    interaction.index_hover = some(0)
    check interaction.beginDrag(arming = MenuArming.Always, now = 0.0)
    interaction.index_hover = some(1)
    interaction.updateDrag(scene, 0.0)
    let centre = interaction.menu.get
    # Take two points: `join` and `project` both make something, and different things.
    #   What lets ghost be told apart from plain-release answer at all.
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
      let ghosted = trial.preview.get.geometry
      let outcome = trial.endDrag(scene_trial)
      check outcome.index_created.isSome
      check scene_trial[outcome.index_created.get].geometry =~ ghosted


  test "what a release would do has three answers, and the band's tint has three":
    # Reach all three effects over one pair with wheel open, without cursor leaving pivot.
    #   Two-way test could not carry it: centre and greyed wedge both have no answer, and
    #   they want opposite feedback.
    var scene = initScene()
    scene.addItem(GENERAL_FIRST[0], "a", Ink.Rose)
    scene.addItem(GENERAL_SECOND[0], "b", Ink.Rose)
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
      # `More` builds nothing itself, so it ghosts nothing while still promising its hue.
      check interaction.preview.isSome ==
        (effect == ReleaseEffect.Builds and choice != DragChoice.More)


  test "with no wheel open the ghost is still the plain-release answer":
    # Left button's own path, unchanged: it never opens wheel, so what it ghosts is.
    #   `proposalFor`'s answer exactly as before.
    var scene = initScene()
    scene.addItem(GENERAL_FIRST[0], "a", Ink.Rose)
    scene.addItem(GENERAL_SECOND[0], "b", Ink.Rose)
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


  test "a ghosted plane is centred where the committed one will be":
    # `mesh.addPlane` centres disc on item's own creation anchor, so ghost drawn.
    #   without one sits somewhere object is about to leave -- measured at 2.1 units
    #   here, against disc of radius 8, and jump lands at moment reader is
    #   watching hardest.
    var scene = initScene()
    scene.addItem(GENERAL_FIRST[1], "L", Ink.Rose) # Line ...
    scene.addItem(GENERAL_SECOND[0], "p", Ink.Rose) # ... joined with point gives plane.
    var interaction = Interaction(is_enabled: true)
    interaction.updateCursor(400.0, 300.0)
    interaction.index_hover = some(0)
    check interaction.beginDrag(arming = MenuArming.Never, now = 0.0)
    interaction.index_hover = some(1)
    interaction.updateDrag(scene, 0.0)
    check interaction.proposal == some(DragChoice.Join)
    check shape(interaction.preview.get.geometry) == some(Shape.Plane)
    check interaction.preview.get.anchor.isSome
    # Read before releasing: `endDrag` clears drag's whole state on its way out.
    let ghosted = interaction.preview.get.anchor.get
    # Not support, or there would have been nothing to fix.
    check not (ghosted =~ positionAnchor(interaction.preview.get.geometry).get)
    let outcome = interaction.endDrag(scene)
    check outcome.index_created.isSome
    check scene[outcome.index_created.get].anchorOverride.get =~ ghosted


  test "a menu release back at the centre commits nothing":
    var scene = initScene()
    scene.addItem(GENERAL_FIRST[0], "a", Ink.Rose)
    scene.addItem(GENERAL_SECOND[0], "b", Ink.Rose)
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
    scene.addItem(GENERAL_FIRST[0], "a", Ink.Rose)
    scene.addItem(GENERAL_SECOND[0], "b", Ink.Rose)
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
    scene.addItem(GENERAL_FIRST[0], "a", Ink.Rose)
    scene.addItem(GENERAL_SECOND[0], "b", Ink.Rose)
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
    scene.addItem(POINTS[0], "a", Ink.Rose)
    scene.addItem(POINTS[1], "b", Ink.Rose)
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
    # Pair's own answer keeps standing under unentered wheel, ghost included, so.
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
    scene.addItem(POINTS[0], "a", Ink.Rose)
    scene.addItem(POINTS[1], "b", Ink.Rose)
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
    check interaction.proposal.isNone # No ghost: band already says this lift cancels.
    let outcome = interaction.endDrag(scene, SECONDS_DWELL_MENU + 0.4)
    check outcome.index_created.isNone
    check scene.len == 2


  test "a summoned wheel still cancels at its own centre":
    # Arming distinction release rule turns on: right press asked for.
    #   wheel, so lifting back at its centre withdraws gesture even though no wedge
    #   was ever entered.
    var scene = initScene()
    scene.addItem(POINTS[0], "a", Ink.Rose)
    scene.addItem(POINTS[1], "b", Ink.Rose)
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
    check meshes.washes.index_overlay.isNone
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
    check meshes.washes.index_overlay == some(0)
    check meshes.washes.count == 0

    # Wash run never straddles mark: disc laid on each side of it lands in two.
    #   runs of one record, and only second is overlay's.
    meshes.addDisc(
      ORIGIN, Direction(x: 1.0, y: 0.0, z: 0.0), Direction(x: 0.0, y: 1.0, z: 0.0),
      1.0, Ink.Olive.colour,
    )
    check meshes.washes.count == 1
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
    check meshes.washes.count == 2
    check meshes.washes.index_overlay == some(1)
    check meshes.washes.runs[0].count == 1 and meshes.washes.runs[1].count == 1

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
    check meshes.washes.index_overlay.isNone


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
    for i in 0 ..< 4: scene.addItem(GENERAL_POINTS[i], "p", Ink.Rose)
    check scene.handleStepped(none(int), 1) == some(0) # Nothing focused starts at first.
    check scene.handleStepped(none(int), -1) == some(3) # ...and backwards, at last.
    check scene.handleStepped(some(0), 1) == some(1)
    check scene.handleStepped(some(3), 1) == some(0) # Wraps rather than stopping dead: key
    check scene.handleStepped(some(0), -1) == some(3) #   that quietly stops working is worse.


  test "stepping skips handles whose items have gone":
    var scene = initScene()
    for i in 0 ..< 4: scene.addItem(GENERAL_POINTS[i], "p", Ink.Rose)
    scene.removeItem(1)
    scene.removeItem(2)
    # Handles are sparse -- free list reuses holes in any order -- so this cannot be.
    #   arithmetic on handle number, and hole must not be place keyboard lands.
    check scene.handleStepped(some(0), 1) == some(3)
    check scene.handleStepped(some(3), 1) == some(0)


  test "stepping an empty scene lands nowhere rather than on a freed handle":
    var scene = initScene()
    check scene.handleStepped(none(int), 1).isNone
    check scene.handleStepped(some(0), 1).isNone
    scene.addItem(GENERAL_POINTS[0], "p", Ink.Rose)
    scene.removeItem(0)
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


  test "a held key slides the view across the ground, never through it":
    # **map** reading of movement key rather than fly one: forward keeps.
    #   camera's height whatever it is looking at. Judged from camera tilted well down,
    #   where slide along raw sight direction would plainly lose height.
    var
      interaction = Interaction(is_enabled: true)
      camera = initCamera(pivot = ORIGIN, distance = 20.0, azimuth = 0.4, elevation = 0.9)
    let opening = camera
    interaction.holdKey(Key.W)
    interaction.driveHeld(camera, 1.0)
    check camera.pivot.z =~ opening.pivot.z
    check camera.distance =~ opening.distance
    check camera.azimuth =~ opening.azimuth
    check camera.elevation =~ opening.elevation
    # Forward is way camera faces, flattened: move lies along it exactly.
    let moved = camera.pivot - opening.pivot
    check norm(moved) =~ SLIDE_SECOND*opening.distance
    check dot(moved, opening.headingGround) =~ norm(moved)

    # Sideways is perpendicular to that, and level with it.
    interaction.releaseKey(Key.W)
    interaction.holdKey(Key.D)
    var sideways = initCamera(ORIGIN, 20.0, 0.4, 0.9)
    interaction.driveHeld(sideways, 1.0)
    check sideways.pivot.z =~ 0.0
    check abs(dot(sideways.pivot - ORIGIN, sideways.headingGround)) <= TOLERANCE_TEST

    # Up and down are world up, and nothing else.
    interaction.releaseKey(Key.D)
    interaction.holdKey(Key.E)
    var lifted = initCamera(ORIGIN, 20.0, 0.4, 0.9)
    interaction.driveHeld(lifted, 1.0)
    check lifted.pivot.x =~ 0.0
    check lifted.pivot.y =~ 0.0
    check lifted.pivot.z =~ SLIDE_SECOND*lifted.distance


  test "held keys compose, and letting one go leaves the other running":
    var
      interaction = Interaction(is_enabled: true)
      camera = initCamera(pivot = ORIGIN, distance = 20.0, azimuth = 0.4, elevation = 0.3)
    interaction.holdKey(Key.W)
    interaction.holdKey(Key.E)
    interaction.driveHeld(camera, 1.0)
    let both = camera.pivot
    check both.z > 0.0
    check norm(Direction(x: both.x, y: both.y, z: 0)) > 0.0

    interaction.releaseKey(Key.E)
    interaction.driveHeld(camera, 1.0)
    check camera.pivot.z =~ both.z # Lift stopped exactly when its key was let go of.
    check norm(camera.pivot - both) > 0.0 # Slide did not.


  test "how far a hold travels depends on how long it was held":
    # Whole point of driving movement per frame: rate stated per second, multiplied.
    #   by frame's own elapsed time, so fast machine and slow one agree.
    var interaction = Interaction(is_enabled: true)
    interaction.holdKey(Key.W)
    var
      once = initCamera(ORIGIN, 20.0, 0.0, 0.3)
      twice = initCamera(ORIGIN, 20.0, 0.0, 0.3)
    interaction.driveHeld(once, 0.5)
    interaction.driveHeld(twice, 1.0)
    check norm(twice.pivot - ORIGIN) =~ 2.0*norm(once.pivot - ORIGIN)

    # Dolly is one that compounds rather than adding, so it takes rate to.
    #   power of elapsed seconds: two half-seconds must equal one whole one.
    interaction.releaseKey(Key.W)
    interaction.holdKey(Key.Minus)
    var
      halves = initCamera(ORIGIN, 20.0, 0.0, 0.3)
      whole = initCamera(ORIGIN, 20.0, 0.0, 0.3)
    interaction.driveHeld(halves, 0.5)
    interaction.driveHeld(halves, 0.5)
    interaction.driveHeld(whole, 1.0)
    check halves.distance =~ whole.distance
    check whole.distance =~ 20.0*FACTOR_DOLLY_SECOND


  test "shift makes every movement key faster, and changes none of them":
    var interaction = Interaction(is_enabled: true)
    interaction.holdKey(Key.W)
    var
      plain = initCamera(ORIGIN, 20.0, 0.4, 0.3)
      hastened = initCamera(ORIGIN, 20.0, 0.4, 0.3)
    interaction.driveHeld(plain, 0.25)
    interaction.holdKey(Key.Shift)
    interaction.driveHeld(hastened, 0.25)
    check norm(hastened.pivot - ORIGIN) =~ FACTOR_HASTE*norm(plain.pivot - ORIGIN)
    # Same direction, not different binding -- which is what shift+arrow used to mean.
    check dot(hastened.pivot - ORIGIN, plain.headingGround) > 0.0

    var
      turned = initCamera(ORIGIN, 20.0, 0.4, 0.3)
      turned_fast = initCamera(ORIGIN, 20.0, 0.4, 0.3)
    interaction.releaseKeysAll()
    interaction.holdKey(Key.Left)
    interaction.driveHeld(turned, 0.25)
    interaction.holdKey(Key.Shift)
    interaction.driveHeld(turned_fast, 0.25)
    check (turned_fast.azimuth - 0.4) =~ FACTOR_HASTE*(turned.azimuth - 0.4)


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
    interaction.driveHeld(camera, 1.0)
    check camera.pivot =~ standing


  test "each key that acts at a press does its own thing, and moves nothing while held":
    var scene = initScene()
    scene.addItem(GENERAL_POINTS[0], "a", Ink.Rose)
    var
      interaction = Interaction(is_enabled: true)
      camera = initCameraDefault()
    let opening = camera

    # Home returns to placement both builds open at, from wherever reader has gone.
    camera.slideGround(3.0, 2.0, 1.0)
    camera.orbit(0.5, 0.2)
    discard interaction.applyAction(camera, scene, KeyAction.ViewHome)
    check camera.pivot =~ opening.pivot
    check camera.distance =~ opening.distance
    check camera.azimuth =~ opening.azimuth
    check camera.elevation =~ opening.elevation

    # Framing is standing offer's own job, so key itself moves nothing: each front.
    #   end releases its tween's goal and `framing.offerAim` aims afresh next frame.
    check interaction.applyAction(camera, scene, KeyAction.FrameSelection).isNone
    check camera.pivot =~ opening.pivot
    check camera.distance =~ opening.distance

    # And key held down is not action at all, however long it is held.
    interaction.holdKey(Key.F)
    interaction.driveHeld(camera, 1.0)
    check camera.pivot =~ opening.pivot


  test "enter reports the focused handle for the caller to select, and nothing before then":
    var scene = initScene()
    scene.addItem(GENERAL_POINTS[0], "a", Ink.Rose)
    scene.addItem(GENERAL_POINTS[1], "b", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    var camera = initCameraDefault()
    # Pressing enter before stepping anywhere is no-op, not select of handle zero.
    check interaction.applyAction(camera, scene, KeyAction.SelectFocused).isNone
    discard interaction.applyAction(camera, scene, KeyAction.FocusNext)
    check interaction.index_focus == some(0)
    check interaction.applyAction(camera, scene, KeyAction.SelectFocused) == some(0)


  test "a focus whose item is removed is dropped rather than left pointing at freed storage":
    var scene = initScene()
    scene.addItem(GENERAL_POINTS[0], "a", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    var camera = initCameraDefault()
    discard interaction.applyAction(camera, scene, KeyAction.FocusNext)
    check interaction.index_focus == some(0)
    scene.removeItem(0)
    interaction.pruneFocus(scene)
    check interaction.index_focus.isNone


  test "a camera move is not a hover, however much it sweeps the pointer past":
    # Hover is recomputed from cursor every frame, so pan drags ring across every.
    #   object it sweeps and held W lights up whatever slides under cursor standing
    #   still. Neither gesture is pointing at anything.
    var scene = initScene()
    let pivot = Position(x: 0, y: 0, z: 0)
    scene.addItem(toMultivector(pivot), "p", Ink.Rose)
    var
      interaction = Interaction(is_enabled: true)
      camera = initCamera(pivot = pivot, distance = 10.0, azimuth = 0.0, elevation = 0.0)
    let view_projection = camera.initMatrixViewProjection(800.0/600.0)
    proc hovering(interaction: var Interaction): Option[int] =
      interaction.updateHover(
        scene, camera, camera.drawExtentFor(600), view_projection, 800, 600,
      )
      interaction.index_hover
    interaction.updateCursor(400.0, 300.0) # Straight at item.
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
    scene.addItem(toMultivector(pivot), "p", Ink.Rose)
    scene.addItem(GENERAL_POINTS[5], "far", Ink.Rose)
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
    scene.addItem(GENERAL_FIRST[0], "a", Ink.Rose)
    scene.addItem(GENERAL_SECOND[0], "b", Ink.Rose)
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
    scene.addItem(GENERAL_FIRST[0], "a", Ink.Rose)
    scene.addItem(GENERAL_SECOND[0], "b", Ink.Rose)
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
    scene.addItem(GENERAL_FIRST[0], "a", Ink.Rose)
    scene.addItem(GENERAL_SECOND[0], "b", Ink.Rose)
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
    scene.addItem(GENERAL_FIRST[2], "G", Ink.Rose)
    scene.addItem(GENERAL_SECOND[0], "f", Ink.Rose)
    var interaction = Interaction(is_enabled: true)
    interaction.index_hover = some(0)
    discard interaction.beginDrag(arming = MenuArming.OnDwell, now = 0.0)
    # Crossing empty space says nothing either way.
    interaction.index_hover = none(int)
    interaction.updateDrag(scene, 0.0)
    check interaction.inkOfDrag(scene.inkNext) == Ink.Guide
    # Standing over pair that makes nothing wears reserved magenta, and shows no.
    #   ghost -- two signals, so warning is never colour alone.
    interaction.index_hover = some(1)
    interaction.updateDrag(scene, 0.0)
    check interaction.inkOfDrag(scene.inkNext) == Ink.Invalid
    check interaction.preview.isNone


  test "disabled interaction never hovers":
    var scene = initScene()
    scene.addItem(POINTS[0], "a", Ink.Rose)
    var interaction = Interaction(is_enabled: false)
    let camera = initCamera(pivot = PLACES[0], distance = 10.0, azimuth = 0.0, elevation = 0.0)
    interaction.updateCursor(400.0, 300.0)
    interaction.updateHover(
      scene, camera, camera.drawExtentFor(600),
      camera.initMatrixViewProjection(800.0/600.0), 800, 600,
    )
    check interaction.index_hover.isNone


  test "enabled interaction hovers the item under the cursor":
    var scene = initScene()
    let pivot = Position(x: 0, y: 0, z: 0)
    scene.addItem(toMultivector(pivot), "p", Ink.Rose)
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
    # Regression this pins, measured: hold of 1.62 s selected its item and then lost.
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


suite "Marker":
  const (WIDTH_MARK, HEIGHT_MARK) = (800, 600)

  proc setUpAt(
    azimuth, elevation, distance: float
  ): (Camera, Matrix4, DrawExtent) =
    ## Build camera looking at origin from one placement, with transform and extent frame carries.
    ##   Orientation is parameter because marker's own worst case can lie along it:
    ##   line's rails flared threefold at one azimuth while reading true at another, and
    ##   round that shipped that swept distance alone.
    let placement = initCamera(
      pivot = Position(x: 0, y: 0, z: 0), distance = distance, azimuth = azimuth,
      elevation = elevation,
    )
    let scale = placement.drawExtentFor(HEIGHT_MARK)
    (placement, placement.initMatrixViewProjection(WIDTH_MARK/HEIGHT_MARK), scale)

  proc setUp(distance = 19.0): (Camera, Matrix4, DrawExtent) =
    ## Hold placement most of these cases read, at one orientation they were written against.
    setUpAt(azimuth = 0.9, elevation = 0.4, distance = distance)

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
      geometry, anchor, RADIUS_ITEM_DEFAULT, scale, placement, view_projection, width, height,
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
      ## Take plane's own attitude: pencil of directions lying in it, at horizon.
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
      radiusPixelsAt(RADIUS_ITEM_DEFAULT, anchor, scale.scale) + GAP_MARKER
    check marker.radius > 0.5*float(DIAMETER_POINT_LEAST) + GAP_MARKER
    # Far point falls to least radius; huge one grows with its own.
    let (placement_far, view_projection_far, scale_far) = setUp(1900.0)
    var ring_far: Marker
    check markerFor(
      POINT_A, none(Position), RADIUS_ITEM_DEFAULT, scale_far, placement_far,
      view_projection_far, WIDTH_MARK, HEIGHT_MARK, ring_far,
    )
    check ring_far.radius =~ 0.5*float(DIAMETER_POINT_LEAST) + GAP_MARKER
    var ring_huge: Marker
    check markerFor(
      POINT_A, none(Position), 100.0*RADIUS_ITEM_DEFAULT, scale, placement,
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
    for azimuth in [0.2, 0.6, 1.6, 2.4, 4.0]:
      for elevation in [0.05, 0.4, 0.9]:
        for distance in [8.0, 19.0, 30.0]:
          let (placement, view_projection, scale) = setUpAt(azimuth, elevation, distance)
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
    for azimuth in [0.2, 0.6, 1.6, 2.4, 4.0]:
      for elevation in [0.05, 0.4, 0.9]:
        let (placement, view_projection, scale) = setUpAt(azimuth, elevation, 19.0)
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
    proc apartAtSupport(azimuth, elevation, distance: float): float =
      let (placement, view_projection, scale) = setUpAt(azimuth, elevation, distance)
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
    check apartAtSupport(0.2, 0.05, 12.0) < apartAtSupport(1.6, 0.9, 19.0)
    check apartAtSupport(0.2, 0.05, 12.0) < 2.0*OFFSET_MARKER_RAIL
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


  test "a line at horizon is flanked by bands, wrapping the sky as its own circle does":
    # Plane's own attitude is line at horizon -- pencil of directions lying in it.
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


  test "a plane at horizon is framed by the viewport, arriving as the screen's edge":
    # Attitude of grade-4 object is plane at horizon -- whole sky.
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


  test "a point at horizon keeps its ring, on the star it is drawn as":
    # Its own star stands one horizon radius along its direction, so it is markable only.
    #   while camera is turned toward it -- behind eye it reports same
    #   "nothing to draw" every other unmarkable case does.
    proc ringAt(azimuth: float): Option[Marker] =
      let placement = initCamera(
        pivot = Position(x: 0, y: 0, z: 0), distance = 19.0, azimuth = azimuth,
        elevation = 0.4,
      )
      let scale = placement.drawExtentFor(HEIGHT_MARK)
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
    var azimuth = 0.0
    while azimuth < 2.0*PI:
      let (placement, view_projection, scale) = setUpAt(azimuth, 0.4, 19.0)
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
      azimuth += 0.002
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
      for elevation in [0.001, -0.001]:
        let (placement, view_projection, scale) = setUpAt(0.9, elevation, 19.0)
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
      axes = placement.frame(eye)
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
    #   Side of line's own direction does not. Over full orbit at two elevations, second
    #   carrying line through vertical twice, anchor never takes isolated step and push
    #   direction turns steadily.
    for elevation in [0.4, 1.25]:
      var
        at_before = none(ScreenPosition)
        away_before = (0.0, 0.0)
        step_before = 0.0
      var azimuth = 0.0
      while azimuth < 2.0*PI:
        let (placement, view_projection, scale) = setUpAt(azimuth, elevation, 19.0)
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
        azimuth += 0.002


  test "a line's label stays in view when its support leaves it":
    # Camera looks twelve units along line from support: support projects off screen, or.
    #   behind eye, while line still crosses view. Anchor slides to visible stretch,
    #   margin in from edge, on line.
    let
      support = positionAnchor(LINE).get
      axis = direction(LINE).get
    for sign in [1.0, -1.0]:
      # Eye square to line, so support stands twelve units aside at eight of depth.
      let placement = initCamera(
        pivot = support + (sign*12.0)*axis, distance = 8.0,
        azimuth = arctan2(axis.y, axis.x) + 0.5*PI, elevation = 0.35,
      )
      let scale = placement.drawExtentFor(HEIGHT_MARK)
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
    #   Ring: above its top. Rails: on line at support, pushed to line's left. Loop and
    #   bands: above highest outline point. Frame is whole view, so label sits just inside
    #   top edge.
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
    let frame = markerOf(PLANE_HORIZON).get
    check frame.kind == MarkerKind.Frame and frame.has_label
    check frame.label_at.x =~ 0.5*float(WIDTH_MARK)
    check frame.label_at.y > 0.0 and frame.label_at.y < 3.0*lift


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
    #   plane at horizon carries no normal at all, so neither says anything.
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
    for azimuth in [0.2, 0.9, 1.7, 2.6, 3.4]:
      for elevation in [-0.5, 0.4, 1.0]:
        for distance in [9.0, 19.0, 34.0]:
          let (placement, view_projection, scale) =
            setUpAt(azimuth = azimuth, elevation = elevation, distance = distance)
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



# Orrery needs room for its default size, and one configuration here deliberately compiles.
#   much smaller pool to exercise pool's own limits. Guarded rather than shrunk:
#   arrangement scaled down would no longer be stress case these cases exist to check.
when ITEMS_MAX >= itemsOf(SCALE_ORRERY_DEFAULT):
  suite "Orrery":
    ## Check demo preset, heaviest scene this build draws, against world it claims.
    ##   Real solar neighbourhood: these stars stand where they really stand.
    ##   That claim needs checking as much as counting does, and it is one thing no
    ##   amount of looking at picture would catch.

    const SCALES_HELD = block:
      ## Name which sizes this build's pool can actually hold.
      ##   Every size at shipped capacity; at reduced one suite is skipped whole by guard
      ##   above, so this only ever narrows for capacity between two.
      var held: seq[ScaleOrrery]
      for scale in ScaleOrrery:
        if ITEMS_MAX >= itemsOf(scale): held.add(scale)
      held

    test "every size fills its own target exactly, and the largest leaves two handles":
      # **Walk lands on count rather than near it.** It passes over system too.
      #   large for room left instead of stopping on it, which is only reason three
      #   unrelated pivots can each come out exact; when it stopped, size hit its pivot
      #   only where item counts happened to sum to it. Checked at every size, because
      #   one size landing exactly says nothing about another.
      #   Handles above largest size are deliberate headroom -- reader can still
      #   build on top of loaded demo rather than meeting refusal, and two is
      #   shortest construction there is: add point, then join it to something.
      for scale in SCALES_HELD:
        var scene = initScene()
        constructOrrery(scene, scale)
        checkpoint(&"{scale}: {scene.len} items, {ITEMS_MAX - scene.len} free")
        check scene.len == itemsOf(scale)
        check not scene.isFull
        if scale == ScaleOrrery.high: check ITEMS_MAX - scene.len == 2

    test "every object it builds draws something":
      # Three collinear points wedge to multivector of no clean grade, which takes handle.
      #   and renders nothing while scene still counts it. Seven objects did that across
      #   two earlier rounds, so this counts *shapes* rather than items.
      var scene = initScene()
      constructOrrery(scene)
      var without: seq[string] = @[]
      for handle in 0 ..< scene.bound:
        if not scene.isAlive(handle): continue
        if shape(scene.geometryOf(handle)).isNone: without.add(toText(scene.labelAt(handle)))
      check without == newSeq[string]()

    test "every size carries every drawable kind, at horizon as well as in the finite world":
      # **Property that makes smallest size usable check at all.** Quick pass.
      #   over 60 objects is only worth running if it exercises what big one does, and
      #   block at horizon is fragile part -- it is built from attitudes of Sol's own
      #   objects and `addHorizon` refuses pair spanning nothing, so size too small to
      #   carry arrangement fails here rather than quietly drawing less.
      var counted: array[ScaleOrrery, tuple[points, planes: int]]
      for scale in SCALES_HELD:
        var scene = initScene()
        constructOrrery(scene, scale)
        var tally: array[Shape, int]
        var at_horizon: array[Shape, int]
        for handle in 0 ..< scene.bound:
          if not scene.isAlive(handle): continue
          let geometry = scene.geometryOf(handle)
          let kind = shape(geometry)
          if kind.isNone: continue
          inc tally[kind.get]
          if isHorizon(geometry): inc at_horizon[kind.get]
        checkpoint(&"{scale}: {tally[Shape.Point]} points, {tally[Shape.Line]} lines, " &
          &"{tally[Shape.Plane]} planes")
        for kind in Shape: check tally[kind] > 0
        # **Ceiling as well as floor, and lines are only kind with one.** They are cut.
        #   to three that mean something -- two in Sol and one at horizon -- because
        #   line is infinite and crosses whole frame whatever it joins. Floor alone
        #   would let them creep back one edit at time. Same three at every size, since
        #   only Sol carries finite lines.
        check tally[Shape.Line] in 3 .. 4
        check at_horizon[Shape.Point] == 2 # Two, and only one of them can make plane.
        check at_horizon[Shape.Line] == 1
        check at_horizon[Shape.Plane] == 1
        counted[scale] = (tally[Shape.Point], tally[Shape.Plane])
      # Points and planes are what bigger size buys, so both have to rise with it. Stated.
      #   as slope rather than as floor per size: three sets of magic numbers would be
      #   three things to keep true, and what is actually being claimed is that reaching
      #   further into catalogue reaches more stars and more of systems that earn
      #   plane. Discs are expensive kind, so second half is where stress in
      #   stress case lives.
      for index in 1 ..< len(SCALES_HELD):
        let (smaller, larger) = (SCALES_HELD[index - 1], SCALES_HELD[index])
        check counted[larger].points > counted[smaller].points
        check counted[larger].planes > counted[smaller].planes

    test "the stars stand where the catalogue says they stand":
      # **Claim this arrangement makes about world.** Every object after Sol is real.
      #   star placed from its real right ascension, declination and distance, so thing
      #   worth checking is conversion -- not that layout looks spread out. Measured
      #   against `starfield.STARS` itself, which is shipped snapshot and one layer
      #   that says where anything is.
      #   Run at largest size this build holds, which is only one that reaches far
      #   enough into catalogue for claim to be worth much.
      let scale = SCALES_HELD[^1]
      var scene = initScene()
      constructOrrery(scene, scale)
      var placed: Table[string, Multivector]
      for handle in 0 ..< scene.bound:
        if not scene.isAlive(handle): continue
        placed[toText(scene.labelAt(handle))] = scene.geometryOf(handle)
      let sol = placed[SOL[0].name]
      var worst = 0.0
      var worst_name = ""
      var seen = 0
      # Catalogue carries more stars than scene has room for, so what is checked is.
      #   every star that *was* placed -- and, below, that ones placed are nearest.
      for star in STARS:
        if star.name notin placed: continue
        inc seen
        let
          drawn = distanceBetween(placed[star.name], sol)
          wanted = star.parsecs*UNITS_PER_PARSEC
          off = abs(drawn - wanted)
        if off > worst:
          worst = off
          worst_name = star.name
      checkpoint(&"{scale}: {seen} stars placed; worst is `{worst_name}`, " &
        &"off by {worst:.6f} units")
      # Most of what size spends goes on stars, so most of what it holds should be one.
      #   Folded from size rather than written down, so it survives next one.
      check seen > (itemsOf(scale) - ITEMS_FIXED_ORRERY) div 2
      check worst <= TOLERANCE_SINGLE
      # And they really are ordered outward, which is what both `RADIUS_ORRERY` and.
      #   nearest-first fill rely on.
      for index in 1 ..< len(STARS):
        check STARS[index].parsecs >= STARS[index - 1].parsecs
      # **Nearest-first, and no longer strict prefix -- by bounded amount.** Walk.
      #   passes over system too large for room left rather than stopping on it, which
      #   is only reason three unrelated sizes can each land on their count exactly.
      #   price is that right at end nearer multi-item system can give way to further
      #   single star. Slack is bounded and bound is derived: once system needing
      #   `k` items is passed over there are fewer than `k` handles left, and every star costs
      #   at least one, so at most `k - 1` stars can follow it in.
      var missing_from = len(STARS)
      for index, star in STARS:
        if star.name notin placed:
          missing_from = index
          break
      var slack = 0
      for index in missing_from ..< len(STARS):
        if STARS[index].name in placed: inc slack
      var widest = 0
      for star in STARS: widest = max(widest, itemsOf(star))
      checkpoint(&"{slack} stars placed beyond the first gap; the widest system is " &
        &"{widest} items, so at most {widest - 1} can be")
      check slack <= widest - 1

    test "the star catalogue is a snapshot, and holds together as one":
      # Everything about shipped table that can be checked without network. It is.
      #   generated, so what is worth asserting is that generator's own claims survive:
      #   bound it queried to, order fill relies on, no star listed twice, and
      #   every planet range landing inside `neighbourhood.PLANETS` exactly once.
      var names = initHashSet[string]()
      var carried, planets_claimed = 0
      var covered = newSeq[int](len(PLANETS))
      for star in STARS:
        check star.name notin names
        names.incl(star.name)
        check star.parsecs > 0.0 and star.parsecs <= 31.53
        if star.planets == 0: continue
        inc carried
        planets_claimed += star.planets
        check star.first >= 0 and star.first + star.planets <= len(PLANETS)
        for which in star.first ..< star.first + star.planets: inc covered[which]
      checkpoint(&"{len(STARS)} stars, {carried} carrying {planets_claimed} planets")
      # Planet hosts are all here, and between them they claim every archive planet once.
      check carried == len(NEIGHBOURS)
      check planets_claimed == len(PLANETS)
      for which, times in covered: check times == 1

    test "no point in it is a hub for the rest of the scene":
      # Fault that broke arrangement before this one: every line and plane joined.
      #   through single star, so scene drew as starburst. Counted, because "it looks
      #   like starburst" is not something suite can see.
      #   Gather joiners once instead of re-reading whole pool for every point. Ten
      #   thousand objects of which barely hundred are lines or planes made this hundred
      #   million handle reads for same answer, and on JS backend each of those reads
      #   copies `Multivector` -- case stopped finishing at all.
      var scene = initScene()
      constructOrrery(scene)
      var planes: seq[Multivector]
      var lines: seq[Multivector]
      for handle in 0 ..< scene.bound:
        if not scene.isAlive(handle): continue
        let geometry = scene.geometryOf(handle)
        if isHorizon(geometry): continue
        case shape(geometry).get(Shape.Point)
        of Shape.Plane: planes.add(unitize(geometry))
        of Shape.Line: lines.add(geometry)
        of Shape.Point: discard
      var worst = 0
      var worst_label = ""
      for handle in 0 ..< scene.bound:
        if not scene.isAlive(handle): continue
        let point = scene.geometryOf(handle)
        if shape(point) != some(Shape.Point) or isHorizon(point): continue
        let place = unitize(point)
        var through = 0
        for plane in planes:
          if abs(depthAgainst(plane, place)) <= TOLERANCE_SINGLE: inc through
        for line in lines:
          let spanned = wedge(line, place)
          var apart = 0.0
          for b in Basis: apart = max(apart, abs(spanned[b]))
          if apart <= TOLERANCE_SINGLE: inc through
        if through > worst:
          worst = through
          worst_label = toText(scene.labelAt(handle))
      checkpoint(&"worst point is `{worst_label}`, carrying {worst} lines and planes")
      check worst <= 6

    test "every body is drawn at its real radius on the square-root scale, clear of its moons":
      # Sizes are what reader compares by eye, so what is pinned is order and ratio.
      #   Sol over Earth compresses from 109 to about ten, and every moon ring starts
      #   outside its planet's drawn disc.
      var scene = initScene()
      constructOrrery(scene)
      var radii: Table[string, float]
      var places: Table[string, Multivector]
      for handle in 0 ..< scene.bound:
        if not scene.isAlive(handle): continue
        radii[toText(scene.labelAt(handle))] = scene.radiusAt(handle)
        places[toText(scene.labelAt(handle))] = scene.geometryOf(handle)
      check radii["sol"] =~ 0.6
      check radii["sol"] > radii["jupiter"]
      check radii["jupiter"] > radii["saturn"]
      check radii["saturn"] > radii["earth"]
      check radii["earth"] > radii["luna"]
      check radii["luna"] > radii["phobos"]
      check abs(radii["sol"]/radii["earth"] - sqrt(695_700.0/6_371.0)) < 1.0e-9
      for body in SOL: check radii[body.name] =~ radiusDrawnOf(body.kilometres_radius)
      # Every body stays above what editor accepts, so none is pinned at least dot for good.
      for moon in MOONS: check radii[moon.name] >= RADIUS_ITEM_LEAST
      # Moon's ring clears planet's disc and its own: two discs never overlap.
      for moon in MOONS:
        let parent = SOL[moon.parent].name
        let apart = distanceBetween(places[moon.name], places[parent])
        check apart > radii[parent] + radii[moon.name]
      # Neighbour suns and planets take Sol's and Earth's, having no radii of their own.
      check radii[STARS[0].name] =~ radii["sol"]
      # Suns shine and nothing else does; see `lighting`.
      var shining: Table[string, bool]
      for handle in 0 ..< scene.bound:
        if scene.isAlive(handle): shining[toText(scene.labelAt(handle))] = scene.shinesAt(handle)
      check shining["sol"]
      check shining[STARS[0].name]
      for body in SOL:
        if body.role == Role.Planet: check not shining[body.name]
      for moon in MOONS: check not shining[moon.name]
      for planet in PLANETS:
        if planet.name in radii: check radii[planet.name] =~ radii["earth"]


    test "every object wears its own type's colour, and no two types share one":
      # Moon and planet are two identical dots and hue is only thing separating.
      #   them, so role collapsing onto another's handle is silent loss of their one signal.
      var scene = initScene()
      constructOrrery(scene)
      for role in Role.Sun .. Role.Derived:
        for other in Role.Sun .. Role.Derived:
          if role != other: check lut_role_to_ink[role] != lut_role_to_ink[other]
      # Roles come from tables that placed objects -- `SOL` for our own system and.
      #   `NEIGHBOURS`/`PLANETS` for real ones -- rather than from second set of name
      #   rules that could drift from them.
      var roles: Table[string, Role]
      for body in SOL: roles[body.name] = body.role
      for moon in MOONS: roles[moon.name] = Role.Moon
      for star in STARS: roles[star.name] = Role.Sun
      for planet in PLANETS: roles[planet.name] = Role.Planet
      var bodies: array[Role, int]
      for handle in 0 ..< scene.bound:
        if not scene.isAlive(handle): continue
        let label = toText(scene.labelAt(handle))
        let role = roles.getOrDefault(label, Role.Derived)
        check scene.inkAt(handle) == lut_role_to_ink[role]
        inc bodies[role]
      for role in [Role.Sun, Role.Planet, Role.Moon, Role.Derived]:
        check bodies[role] > 0

    test "two finite lines in the whole scene, and only one joins a star to a planet":
      # State layout instruction as assertion.
      #   Asked geometrically, which lines pass through which bodies, so renaming
      #   something cannot make it pass.
      var scene = initScene()
      constructOrrery(scene)
      var roles: Table[string, Role]
      for body in SOL: roles[body.name] = body.role
      for moon in MOONS: roles[moon.name] = Role.Moon
      for star in STARS: roles[star.name] = Role.Sun
      for planet in PLANETS: roles[planet.name] = Role.Planet
      var suns, planets: seq[Multivector] = @[]
      var lines: seq[string] = @[]
      for handle in 0 ..< scene.bound:
        if not scene.isAlive(handle): continue
        let
          label = toText(scene.labelAt(handle))
          geometry = scene.geometryOf(handle)
        if isHorizon(geometry): continue
        case shape(geometry).get(Shape.Point)
        of Shape.Line: lines.add(label)
        of Shape.Point:
          case roles.getOrDefault(label, Role.Derived)
          of Role.Sun: suns.add(geometry)
          of Role.Planet: planets.add(geometry)
          else: discard
        of Shape.Plane: discard
      check lines == @["sol ∧ earth", "earth ∧ luna"]
      proc lies(line, point: Multivector): bool =
        let place = unitize(point)
        for b in Basis:
          if abs(wedge(line, place)[b]) > TOLERANCE_SINGLE: return false
        true
      var joining = 0
      for handle in 0 ..< scene.bound:
        if not scene.isAlive(handle): continue
        let geometry = scene.geometryOf(handle)
        if isHorizon(geometry) or shape(geometry) != some(Shape.Line): continue
        for sun in suns:
          if not lies(geometry, sun): continue
          for planet in planets:
            if lies(geometry, planet): inc joining
      check joining == 1

    test "of the two points at horizon, only the one off the ecliptic makes the plane":
      # **Why there are two.** Earth lies in Sol's ecliptic, so direction Sol-to-Earth.
      #   lies along that plane and therefore *on* line at horizon it gives -- wedging it
      #   back with that line adds nothing. Luna's ring is tipped out, so its direction is off
      #   line and spans plane with it. Both halves are checked, because whole
      #   construction turns on difference between them.
      var scene = initScene()
      constructOrrery(scene)
      var at_horizon: Table[string, Multivector]
      for handle in 0 ..< scene.bound:
        if not scene.isAlive(handle): continue
        let geometry = scene.geometryOf(handle)
        if isHorizon(geometry): at_horizon[toText(scene.labelAt(handle))] = geometry
      let
        line = at_horizon["att(ecliptic sol)"]
        on_it = at_horizon["att(sol ∧ earth)"]
        off_it = at_horizon["att(earth ∧ luna)"]
      var along, across = 0.0
      for b in Basis:
        along = max(along, abs(wedge(line, on_it)[b]))
        across = max(across, abs(wedge(line, off_it)[b]))
      checkpoint(&"earth's direction spans {along:.9f} with the line, luna's {across:.9f}")
      check along <= TOLERANCE_SINGLE # On line: it adds nothing.
      check across > TOLERANCE_SINGLE # Off it: it spans plane.
      check shape(line ∧ off_it) == some(Shape.Plane)
      check isHorizon(line ∧ off_it)

    test "the framing radius holds the systems it claims, and the rest run past it":
      var scene = initScene()
      constructOrrery(scene)
      # `RADIUS_ORRERY` is fitted to Sol and nearest few, and claim worth checking.
      #   is not exact count -- handful of real stars happen to fall inside radius
      #   fitted to their neighbours -- but that overwhelming majority lie *beyond* it.
      #   That is what makes crossing neighbourhood journey rather than nudge.
      var held, beyond = 0
      for star in STARS:
        if star.parsecs*UNITS_PER_PARSEC > RADIUS_ORRERY: inc beyond else: inc held
      checkpoint(&"{held} stars inside the opening frame, {beyond} beyond it")
      check held >= FRAMED_ORRERY - 1 # Sol is framed too, and is not in this table.
      check beyond >= 9*len(STARS) div 10
      check RADIUS_ORRERY > 0.0


    test "the preset both front-ends open on is one preset":
      # `showOrrery` is whole thing demo button loads -- arrangement, its replayed.
      #   arrival and camera that holds it -- and browser's bridge and desktop's
      #   `--demo` both call it. It used to live inline in bridge, where desktop
      #   could not reach it and nothing could check it, so camera half of preset
      #   was untested on either side.
      var scene = initScene()
      var camera = initCameraDefault()
      camera.azimuth = 1.25 # Left alone by preset, so it has to survive it.
      showOrrery(scene, camera, 1440, 900)
      check scene.len == itemsOf(SCALE_ORRERY_DEFAULT)
      check camera.pivot =~ POSITION_ORRERY
      check camera.elevation =~ ELEVATION_ORRERY_SHOWN
      check camera.azimuth =~ 1.25
      # Standing back far enough to hold arrangement is point of solve, and.
      #   standing *inside* it is failure it exists to prevent -- opening camera,
      #   placed for seed scene, sits within this one.
      check camera.distance > RADIUS_ORRERY
      check camera.distance =~
        distanceFitting(RADIUS_ORRERY, camera, 1440, 900, INSET_ORRERY_SHOWN)
      # Narrower window has to stand further back, since fit is bounded by whichever.
      #   of two axes runs out first.
      var camera_narrow = initCameraDefault()
      showOrrery(scene, camera_narrow, 640, 900)
      check camera_narrow.distance > camera.distance
