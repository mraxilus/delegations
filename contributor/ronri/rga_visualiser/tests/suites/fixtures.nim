## Draw shared pool and helpers every suite module checks against.
##   Drawn once from seeded generator, before any suite runs, so failure reproduces from
##   test name alone; see `../suites.nim` for why suites are modules of their own.

import std/[
  math, options, os, random, sets, strformat, strutils, tables, unicode, unittest,
]

# `pga` arrives through `projections`, which stands in for four it has withdrawn.
import ../../src/rga_visualiser/projections
import ../../src/rga_visualiser/[
  boundary, camera, format, framing, help, history, interaction, marker, message, motors,
  neighbourhood, objects, orrery, picking, scene, selection, starfield, storyboard, tessellate,
  wording,
]
# Arena, PNG encoder and GIF encoder are desktop-only: each binds C entry.
#   point JS backend has none of. Their own suites are guarded to match, below.
#   `std/endians` joins them because only desktop cases build scene-file bytes by
#   hand, and they write format's own byte order rather than host's.
when not defined(js):
  import std/endians
  import ../../src/desktop/[arena, gif, image]
# Re-exported, so each suite module imports this one module and names nothing twice.
export
  math, options, os, random, sets, strformat, strutils, tables, unicode, unittest,
  projections, boundary, camera, format, framing, help, history, interaction, marker, message,
  motors, neighbourhood, objects, orrery, picking, scene, selection, starfield, storyboard,
  tessellate, wording
when not defined(js):
  export endians, arena, gif, image

randomize(0)


const
  SAMPLES* = 64
  EXTENT_SAMPLE* = 5.0
  TOLERANCE_PLACES_TEST* {.define: "visualiser.tolerance_places".} = 9
  TOLERANCE_TEST* = 10.0.pow(-float(TOLERANCE_PLACES_TEST))
  TOLERANCE_SINGLE* = 1.0e-5
    ## Widen tolerance for values that passed through 32-bit storage.
    ##   Matrices and vertices are single precision, as that is what GPU consumes,
    ##   so comparing them against double-precision geometry at full tolerance is wrong.
  WIDTH_OPENED* = 1200
  HEIGHT_OPENED* = 800
    ## Frame most suites open camera on: wide enough that opening stands its least, 19 units.


let ORIGIN* = Position(x: 0, y: 0, z: 0)


func stanceAround*(pivot: Position; distance: float; out_to: Direction): CameraStance =
  ## Build stance facing `pivot` from `distance` away, along `out_to` from pivot to eye.
  ##   What case names: where view looks, how far off, and from which side. Level, as
  ##   `camera.stanceFacing` is; `out_to` need not be unit.
  stanceFacing(pivot + (distance/norm(out_to))*out_to, pivot)


proc randOutTo*(): Direction =
  ## Draw direction from pivot out to eye, from every side, never too short to name one.
  while result.norm < 0.1:
    result = Direction(x: rand(-1.0 .. 1.0), y: rand(-1.0 .. 1.0), z: rand(-1.0 .. 1.0))


func cameraAround*(pivot: Position; distance: float; out_to: Direction): Camera =
  ## Build camera at `stanceAround`, through 45 degree lens.
  initCamera(eye = pivot + (distance/norm(out_to))*out_to, pivot = pivot)


proc randPosition*(): Position =
  Position(
    x: rand(-EXTENT_SAMPLE .. EXTENT_SAMPLE),
    y: rand(-EXTENT_SAMPLE .. EXTENT_SAMPLE),
    z: rand(-EXTENT_SAMPLE .. EXTENT_SAMPLE),
  )

var
  PLACES*: array[SAMPLES, Position]
  POINTS*: array[SAMPLES, Multivector]
  LINES*: array[SAMPLES, Multivector]
  PLANES*: array[SAMPLES, Multivector]
for i in 0 ..< SAMPLES:
  PLACES[i] = randPosition()
  POINTS[i] = toMultivector(PLACES[i])
for i in 0 ..< SAMPLES:
  let (j, k) = ((i + 1) mod SAMPLES, (i + 2) mod SAMPLES)
  LINES[i] = POINTS[i] ∧ POINTS[j]
  PLANES[i] = POINTS[i] ∧ POINTS[j] ∧ POINTS[k]

const COUNT_GENERAL* = 12
  ## Hold points enough for two disjoint families of one point, one line and one plane.

func generalPlace*(index: int): Position =
  ## Place one of family of points in **general position**:
  ##   no three collinear and no four coplanar, so shape built from any of them is incident with
  ##   none of rest.
  ##   Read off moment curve (t, t², t³), where that is theorem rather than hope:
  ##   4x4 matrix of (1, t, t², t³) over four distinct parameters is Vandermonde and
  ##   so never singular. Scaled to extent rest of suite works at.
  let t = -1.1 + 0.2*float(index)
  Position(x: 4.0*t, y: 4.0*t*t, z: 4.0*t*t*t)

var
  GENERAL_POINTS*: array[COUNT_GENERAL, Multivector]
  GENERAL_FIRST*: array[3, Multivector] ## Point, line, plane, in grade order.
  GENERAL_SECOND*: array[3, Multivector] ## Second such triple, sharing no point with
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
var MESHES*: MeshSet

# Where tessellation step assembles its ribbon pieces before emitting them.
#   application carves this from frame arena on desktop and holds fixed buffer on
#   browser; suite has neither, and one shared array is same shape as both.
var SCRATCH*: DrawScratch


func `=~`*(a, b: float): bool =
  ## Compare approximate equality between scalars.
  abs(a - b) <= TOLERANCE_TEST * max(1.0, max(abs(a), abs(b)))


func `=~`*(p, q: Position): bool =
  ## Compare approximate equality between positions.
  p.x =~ q.x and p.y =~ q.y and p.z =~ q.z


func `=~`*(d, e: Direction): bool =
  ## Compare approximate equality between directions.
  d.x =~ e.x and d.y =~ e.y and d.z =~ e.z


func `=~`*(a, b: CameraStance): bool =
  ## Compare approximate equality between stances, coefficient by coefficient.
  ##   Pivot is read off sight, so stance slid onto pivot it stands at moves by rounding.
  let (m, n) = (a.motor, b.motor)
  m.turn_x =~ n.turn_x and m.turn_y =~ n.turn_y and m.turn_z =~ n.turn_z and
    m.slide_x =~ n.slide_x and m.slide_y =~ n.slide_y and m.slide_z =~ n.slide_z and
    m.scalar =~ n.scalar and m.antiscalar =~ n.antiscalar and a.distance =~ b.distance


func isNear*(a, b: float): bool =
  ## Compare scalars that passed through 32-bit storage.
  abs(a - b) <= TOLERANCE_SINGLE * max(1.0, max(abs(a), abs(b)))


func isNear*(p, q: Position): bool =
  ## Compare positions that passed through 32-bit storage.
  isNear(p.x, q.x) and isNear(p.y, q.y) and isNear(p.z, q.z)


func toPosition*(vertex: Vertex): Position =
  ## Read vertex back as position, for checking where tessellation put it.
  Position(x: float(vertex.x), y: float(vertex.y), z: float(vertex.z))


func transform*(matrix: Matrix4, p: Position, weight: float): array[4, float] =
  ## Apply transform to homogeneous point, so matrices can be checked by what they do.
  let coordinates = [p.x, p.y, p.z, weight]
  for row in 0 .. 3:
    for column in 0 .. 3:
      result[row] += float(matrix.at(row, column)) * coordinates[column]


proc formatMultivectorString*(m: Multivector): string =
  ## Format into stack buffer exactly as panel does, then read it back as `string`.
  ##   Test can compare against that; production code never takes this last step.
  var
    buffer: array[128, char]
    cursor = 0
  formatMultivector(m, buffer, cursor)
  finishChars(buffer, cursor)
  toText(buffer)
