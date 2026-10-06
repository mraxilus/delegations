## Turn geometry into picture through algebra, handing plain places down to `mesh`.
##
## Reads what object is through algebra, places every point of its drawing through
## algebra, and hands places to `mesh` to pack into vertices.
## Geometry side of drawing.
##   Owns what thing is and where it stands: scene object, lattice line of picked plane,
##   world axis, and everything in horizon, where point becomes star, line becomes great
##   circle of directions it stands for, and plane becomes whole sky.
##   Those are geometric objects placed through library, which project exists to exercise.
## Does *not* own picture drawn to stand for them.
##   Disc is not plane and ribbon is not line: both are stand-ins sized for eye, built in
##   `mesh` out of ordinary arithmetic.
##   See `euclid.nim` header for split, and `boundary.nim` for one place two languages meet.
## Finite objects are tessellated about support point, i.e. point nearest origin.
##   Objects in horizon are drawn fixed to `DrawExtent.eye` at `DrawExtent.radiusHorizon`,
##   so orbiting or dollying leaves each in same apparent direction, as real star would.
## Every place handed to `mesh` is about frame's view origin, `DrawScale.origin`.
##   Placement and geometry are world's, so each world place is read about it once, where
##   it enters frame (`euclid.toView`): subtraction for each object, as record writer once
##   made. Eye, furniture and horizon are reckoned about it from start.
##   Lattice line decimetre apart two million units out has no world double, so nothing
##   is lifted back to world before it is written.
##
## Shared by desktop (`main.nim`) and browser (`bridge.nim`) render paths.

{.experimental: "codeReordering".}
{.experimental: "strictFuncs".}

import std/[math, options]

# `pga` arrives through `projections`, which stands in for four it has withdrawn.
import ./[boundary, mesh, projections, timings]

export mesh



#[ Type Definitions ]#

type
  DrawExtent* = object  ## Define frame's camera in both languages at once.
    ## Euclidean half is `mesh.DrawScale`, carried whole so caller holding extent still
    ## says `scale.eye`.
    ## Four multivector twins beside it are algebra's reading of same camera.
    ##   Derived once per frame in `camera.drawExtentFor`, so nothing downstream rebuilds
    ##   `toMultivector(eye)` per segment.
    scale*: DrawScale  ## Everything picture is measured against; see `mesh.DrawScale`.
    eye_point*: Multivector  ## Eye as unit-weight point.
    forward_point*: Multivector  ## Sight direction as horizon point.
    plane_eye*: Multivector  ## Unitized plane through eye perpendicular to sight.
      ## `depthAgainst` it is view depth, sign "in front".
    plane_near*: Multivector  ## Same plane pushed `depth_near` forward.
      ## Near clip as algebra states it, for `clipToEyeSide`'s meet.

  Case* {.pure.} = enum  ## Define which drawable algebra found, and its placement.
    Nothing  ## No drawable geometry at all; nothing is emitted.
    PointAt  ## Point standing somewhere in finite world.
    PointToward  ## Horizon point: direction, drawn as star on sky.
    LineThrough  ## Line through support, running along attitude.
    LineAcross  ## Horizon line: pencil of directions its two axes span.
    PlaneOn  ## Plane anchored somewhere, disc spanned by two arms.
    PlaneEverywhere  ## Horizon plane: whole sky, carrying no orientation.

  Placement* = object  ## Define everything *algebra* says about one object, and nothing else.
    ## Camera is not in it, and that is whole point.
    ##   Every reader here (`position`, `positionAnchor`, `direction`, `directionHorizon`,
    ##   `frame`, `spanPerpendicular`) is pure function of multivector, so one answer serves
    ##   every reader of its frame at that frame's camera.
    ##   Each frame places every object once, and its walks read that answer: reach, cull,
    ##   emission, pick. Next frame places every object again, and never reads these as its
    ##   own; each front-end keeps them one frame more, as frame before's
    ##   (`placementsPrevious`), for what reckons across two frames.
    ## Flat rather than variant object.
    ##   Copied per handle into `array[OBJECTS_MAX, Placement]`, and case object's tag would buy
    ##   nothing but narrower read. Which fields carry meaning is `kind`'s to say.
    kind*: Case
    at*: Position  ## Where it stands: point's place, line's support, plane's disc centre.
      ## Meaningless for two horizon kinds and `Nothing`.
    toward*: Direction  ## Direction it names: horizon point's heading, line's attitude.
      ## Meaningless for either plane kind and `Nothing`.
    axes*: FramePlane  ## Two arms disc or great circle is spanned by, and their normal.
      ## Carried by `PlaneOn` and `LineAcross` only.

  ViewBounds* = object  ## Define frustum points are tested against before emitting.
    ## Everything `isPointInView` reads, derived once per frame by `camera.viewBoundsFor`.
    ##   Scalars and directions alone, so test allocates nothing per point (Art. VII.1).
    origin*: Position  ## View origin, as world position, that `eye` is held about.
      ## Placement is world's, and test reads it about this; see `isPointInView`.
    eye*: Position  ## Where depth is measured from, about `origin`.
    forward*: Direction  ## Sight axis, depth is measured along.
    right*: Direction  ## View's +x, unit.
    up*: Direction  ## View's +y, unit.
    depth_near*: float  ## Nearest depth drawn; nearer is clipped by GPU as well.
    depth_far*: float  ## Furthest depth drawn; further is clipped by GPU as well.
    bound_width*: float  ## Half-width of view per unit of depth, sprite margin included.
    bound_height*: float  ## Half-height of view per unit of depth, sprite margin included.


# Read through to Euclidean half, so caller writes `scale.eye`, not `scale.scale.eye`.
#   Split is about which module may *name* multivector.
func extentFurniture*(d: DrawExtent): float = d.scale.extent_furniture
  ## Read how far furniture reaches.

func origin*(d: DrawExtent): lent Position = d.scale.origin
  ## Read view origin, as world position, that every place of frame is about.
  ##   `lent`: emission reads it once for each object, and value is copy on JS backend.

func eye*(d: DrawExtent): Position = d.scale.eye
  ## Read where eye stands, about view origin.

func radiusHorizon*(d: DrawExtent): float = d.scale.radius_horizon
  ## Read how far out horizon objects are drawn about eye.

func forward*(d: DrawExtent): Direction = d.scale.forward
  ## Read sight direction.

func axisRight*(d: DrawExtent): Direction = d.scale.axis_right
  ## Read camera's screen-right axis.

func axisUp*(d: DrawExtent): Direction = d.scale.axis_up
  ## Read camera's screen-up axis.

func tangentHalfView*(d: DrawExtent): float = d.scale.tangent_half_view
  ## Read tangent of half vertical field of view.

func heightPixels*(d: DrawExtent): int = d.scale.height_pixels
  ## Read framebuffer height in pixels.

func depthNear*(d: DrawExtent): float = d.scale.depth_near
  ## Read near clip depth.

func depthLog*(d: DrawExtent): float = d.scale.depth_log
  ## Read scale depth's logarithm maps by; see `camera.depthOf`.

# Convert whole half implicitly, so extent hands to any of `mesh`'s procs unwrapped.
#   Extent *is* scale with algebra's reading beside it, conversion runs one way, and no
#   second type could be confused for it.
converter toScale*(d: DrawExtent): DrawScale = d.scale


func algebraFilled*(scale: DrawExtent): DrawExtent =
  ## Return extent with its four multivector twins derived from its plain fields.
  ##   One derivation point: `camera.drawExtentFor` goes through here, and so must any
  ##   hand-built extent (test fixture, partial one).
  ##     Otherwise twins are zero multivectors and everything algebraic downstream silently
  ##     draws nothing; suite's fixtures once built extents fieldwise and lost lattice.
  result = scale
  result.eye_point = scale.eye.toMultivector
  result.forward_point = scale.forward.toMultivector
  result.plane_eye = planeThrough(result.eye_point, result.forward_point)
  result.plane_near = planeThrough(
    add(result.eye_point, wedge(scale.depthNear, result.forward_point)),
    result.forward_point,
  )



#[ Representative Point ]#

func anchorWorld*(m: Multivector): Option[Position] =
  ## Resolve one finite point standing for `m`, as world position.
  ##   Point's own place, and line's or plane's support point, what mesh anchors on.
  ##   For `anchorFor` reading multivector, which reads it about view origin; placement holds
  ##   same place as `Placement.at`.
  ##   None in horizon, and where `m` carries no drawable geometry.
  let kind = kindOf(m)
  if kind.isNone: return
  case kind.get
  of Kind.Point: position(m)
  of Kind.Line, Kind.Plane: positionAnchor(m)


func anchorFor*(m: Multivector, scale: DrawExtent): Option[Position] =
  ## Resolve one point standing for `m`, about view origin, for picking and cursor feedback.
  ##   Point uses own place, or own star position in horizon, matching where
  ##   `mesh.addPoint` draws it.
  ##   Line and plane use support point, what mesh anchors on.
  ##     Neither needs horizon anchor: `pickNearest` tests horizon line against great
  ##     circle it is drawn as and matches horizon plane outright.
  ##   Finite place is world's `anchorWorld`, read about `scale.origin`; star stands about
  ##   eye, which already is.
  ##   None where `m` carries no drawable geometry.
  let finite = anchorWorld(m)
  if finite.isSome: return some(finite.get.toView(scale.origin))
  if kindOf(m) != some(Kind.Point): return
  let heading = directionHorizon(m)
  if heading.isNone: return
  position(add(scale.eye_point, wedge(scale.radiusHorizon, heading.get.toMultivector)))


func anchorFor*(
  m: Multivector, anchor_override: Option[Position], scale: DrawExtent
): Option[Position] =
  ## Resolve one point standing for `m` as it is drawn.
  ##   For anything meeting object on screen: rubber-band leaving it, comet aimed from it,
  ##   menu hanging off it.
  ##   Reads `anchor_override` as `addPlane` and `marker.markerFor` do, so plane's disc has
  ##   one centre.
  ##     Stored creation anchor can stand units from support, so band from support left
  ##     from point nowhere on visible circle.
  ##   Ignored for every other kind, as `addObject` ignores it.
  ##   Override is world's, as scene stores it, so it is read about view origin too.
  if anchor_override.isSome and kindOf(m) == some(Kind.Plane):
    return some(anchor_override.get.toView(scale.origin))
  anchorFor(m, scale)


func anchorFor*(placed: Placement, scale: DrawExtent): Option[Position] =
  ## Resolve one point standing for placed object as it is drawn, about view origin.
  ##   Frame's twin of `anchorFor(m, anchor_override, scale)`, for every reader holding
  ##   frame's placement: it holds plane's override applied, point's place or heading, and
  ##   line's support, so nothing is classified or read out of algebra again.
  ##   Star stands about eye, which moves with camera, so it is read off heading as
  ##   emission reads it: eye plus `radius_horizon` along it.
  ##   None for horizon line, horizon plane and no geometry, as for multivector.
  ##   `placed` read in place, never copied (read in emitted JS).
  case placed.kind
  of Case.PointAt, Case.LineThrough, Case.PlaneOn: some(placed.at.toView(scale.origin))
  of Case.PointToward:
    position(add(scale.eye_point, wedge(scale.radiusHorizon, placed.toward.toMultivector)))
  of Case.LineAcross, Case.PlaneEverywhere, Case.Nothing: none(Position)



#[ Great Circle ]#

func addGreatCircle(
  meshes: var MeshSet;
  center: Position;
  axis_first, axis_second: Direction;
  radius: float;
  tint: Rgba;
) =
  ## Append closed ring of segments around `center` at `radius`, in plane two axes span.
  ##   Great circle horizon line traces across sky, standing for pencil of directions it
  ##   names.
  ##   Very circle `mesh.addRing` describes, delegated so two cannot drift.
  ##     Which plane arms span is algebra's answer (`spanPerpendicular`, at caller); ring
  ##     itself is arithmetic off fixed angle table; `picking.pickNearest` samples its copy
  ##     same way.
  meshes.addRing(center, axis_first, axis_second, radius, tint, WIDTH_LINE_OBJECT)



#[ World Furniture ]#

func placeChord(
  scratch: var DrawScratch;
  count_assembled: var int;
  centre, axis_point: Multivector;
  span: float;
  tint: Rgba;
  scale: DrawExtent;
) =
  ## Resolve one furniture line into `scratch.ribbons` as single piece.
  ##   Runs `span` either side of `centre` along `axis_point`, at full tint: fog fade runs
  ##   per fragment in shaders, against `mesh.alphaGridFade`.
  ##   Silently stops at scratch's end, for reason `placeGridFamily` gives.
  ##   Shared by grid and axes.
  ##   Whole line behind eye is culled here, not carried.
  ##     Shader refuses it anyway, but refused record still crossed wire and counted.
  ##     Depth along sight axis is linear along segment, so two behind-eye endpoints put
  ##     all of it behind.
  if count_assembled >= len(scratch.ribbons): return
  let
    tail = pointFrom(add(centre, wedge(-span, axis_point)))
    head = pointFrom(add(centre, wedge(span, axis_point)))
  if dot(tail - scale.eye, scale.forward) < scale.depthNear and
      dot(head - scale.eye, scale.forward) < scale.depthNear:
    return
  scratch.ribbons[count_assembled] = RibbonPiece(
    tail: tail,
    head: head,
    tint_tail: tint,
    tint_head: tint,
  )
  count_assembled += 1


func placeAxes(scratch: var DrawScratch, extent: float, scale: DrawExtent): int =
  ## Resolve world axes into `scratch` and report how many pieces.
  ##   One through origin along each of x, y and z (x red, y green, z blue), so
  ##   orientation reads at glance.
  ##   Draws nothing; algebra's half of seam, as `placeGridFamily` is.
  ##   Faded out and cut off in lattice's own fog, rather than running full furniture
  ##   extent at flat alpha.
  ##     Axis reaching horizon at full strength was longest, brightest mark in frame, and
  ##     readers took them for drawn lines.
  ##     Sharing grid's fog puts all furniture inside one horizon, so reference reads as
  ##     neighbourhood around *reader*.
  ##   Each axis is drawn only over stretch inside fog: chord of sphere of radius
  ##   `radius_gone` about eye. Axis eye has flown clear of contributes nothing.
  ##   Axes run through world origin, read about view origin as eye is.
  const axes_world = [
    (Direction(x: 1, y: 0, z: 0), Ink.AxisX),
    (Direction(x: 0, y: 1, z: 0), Ink.AxisY),
    (Direction(x: 0, y: 0, z: 1), Ink.AxisZ),
  ]
  let
    fog = fogFurnitureFor(extent)
    origin_world = ORIGIN_WORLD.toView(scale.origin).toMultivector
  var count_assembled = 0
  for (axis, ink) in axes_world:
    # Solve chord of fog sphere along this axis, about eye's perpendicular foot on it.
    #   Foot is algebra's orthogonal projection of eye onto axis line.
    #   Chord half-length stays scalar solve, since sphere has no representative in rigid
    #   algebra: one documented exception.
    let
      axis_line = wedge(origin_world, axis.toMultivector)
      foot_raw = projectOrthogonal(scale.eye_point, axis_line)
      foot = position(foot_raw)
    if foot.isNone: continue
    let
      separation = distanceBetween(unitize(foot_raw), scale.eye_point)
      half_squared = fog.radius_gone * fog.radius_gone - separation * separation
    if half_squared <= 0.0: continue
    let
      half = sqrt(half_squared)
      tint = ink.colour
      foot_point = unitize(foot_raw)
      axis_point = axis.toMultivector
    # Place one piece for whole chord: fade and across both run in shaders.
    #   See `mesh.expandRibbon` and `mesh.alphaGridFade`.
    scratch.placeChord(count_assembled, foot_point, axis_point, half, tint, scale)

  count_assembled


proc addAxes*(meshes: var MeshSet, scratch: var DrawScratch, extent: float, scale: DrawExtent) =
  ## Append world axes; `placeAxes` says what each is and how far it runs.
  ##   Two calls, for reason `addGridFamily` gives.
  var count_assembled = 0
  timed(Side.Placing): count_assembled = placeAxes(scratch, extent, scale)
  timed(Side.Emitting):
    meshes.addRibbonPieces(
      scratch.ribbons.toOpenArray(0, count_assembled - 1),
      WIDTH_LINE_FURNITURE,
      is_fogged = true,
    )


func radiusOnPlaneFor*(extent: float, scale: DrawExtent, plane: Multivector): Option[float] =
  ## Solve how far lattice laid on `plane` reaches from eye's foot on it.
  ##   Fog is sphere about eye, so what it leaves on any plane is disc about that foot, of
  ##   radius `sqrt(radius_gone^2 - height^2)`, height being eye's depth against plane.
  ##     Algebra's answer for any plane, not ground's alone.
  ##   `plane` is about view origin, as eye is; `addLattice` builds one.
  ##   None where eye stands further off than fog reaches.
  let
    fog = fogFurnitureFor(extent)
    height = abs(depthAgainst(plane, scale.eye_point))
    radius_squared = fog.radius_gone * fog.radius_gone - height * height
  if radius_squared <= 0.0: return
  some(sqrt(radius_squared))


func placeGridFamily(
  scratch: var DrawScratch;
  scale: DrawExtent;
  tint: Rgba;
  radius_ground, size_cell: float;
  along, across: Direction;
  origin: Position;
): int =
  ## Resolve one family of lattice lines into `scratch`, one piece per line; report count.
  ##   Every line runs along `along`, stepped by `size_cell` along `across`, within
  ##   `radius_ground` of eye's foot on plane two span.
  ##   Draws nothing: algebra's half of seam, all multivector work.
  ##     Per-piece fade colours moved to fragment shader with fog (`mesh.alphaGridFade`),
  ##     taking family from boundary sum per fade piece to two per line.
  ##   Lattice is laid on any plane through `origin` spanned by `along` and `across`; see
  ##   `addLattice`, which lays one on each selected plane.
  ##     `origin` is about view origin, as eye is, so line decimetre apart far out keeps its
  ##     place: world double there steps by tens of metres.
  ##   Cell is passed in rather than read from `SIZE_CELL_GRID`, so both families lie on
  ##   one `sizeCellGridFor` answered for this frame's disc.
  ##   Lines sit on *world* multiples of cell size, not offsets from camera.
  ##     What slides past as reader moves is world going by, and line stays where it was.
  # Resolve eye onto two lattice axes.
  #   Depth against plane through origin perpendicular to each: algebra's statement of
  #   coordinate. One plane per family per frame.
  let
    origin_point = origin.toMultivector
    along_point = along.toMultivector
    across_point = across.toMultivector
    centre_across = depthAgainst(planeThrough(origin_point, across_point), scale.eye_point)
    centre_along = depthAgainst(planeThrough(origin_point, along_point), scale.eye_point)
    first = int(ceil((centre_across - radius_ground) / size_cell))
    last = int(floor((centre_across + radius_ground) / size_cell))
    # Line through origin lies on world axis where origin is world's and `along` is axis.
    #   It would fight that axis for depth, or hide its colour under grid grey.
    is_on_axis = norm(origin - ORIGIN_WORLD.toView(scale.origin)) <= TOLERANCE_ABS and
        max(abs(along.x), max(abs(along.y), abs(along.z))) >= 1.0 - TOLERANCE_ABS
  var count_assembled = 0
  for i in first..last:
    if i == 0 and is_on_axis: continue
    let
      offset = float(i) * size_cell
      reach_squared = radius_ground * radius_ground -
          (offset - centre_across) * (offset - centre_across)
    if reach_squared <= 0.0: continue
    let
      reach = sqrt(reach_squared)
      base = add(origin_point, add(wedge(offset, across_point), wedge(centre_along, along_point)))
    # Assemble, not draw; see `placeChord`, which stops silently at scratch's end.
    #   `mesh.LINES_GRID_MAX` sizes it from bound `CELLS_GRID_HALF_MAX` puts on
    #   `first .. last`, so full buffer means bound was raised and this was not.
    scratch.placeChord(count_assembled, base, along_point, reach, tint, scale)

  count_assembled


proc addGridFamily*(
  meshes: var MeshSet;
  scratch: var DrawScratch;
  scale: DrawExtent;
  tint: Rgba;
  radius_ground, size_cell: float;
  along, across: Direction;
  origin: Position = ORIGIN_WORLD;
) =
  ## Append one family of lattice lines; `placeGridFamily` says what family is.
  ##   `origin` is about view origin; default is view origin itself.
  ##   Seam, as two calls.
  ##     Where pieces go is worked out by one proc and drawn by another, so line between
  ##     algebra and picture runs between two functions, and each side is timed by bracket
  ##     enclosing none of other's work. See `timings`.
  var count_assembled = 0
  timed(Side.Placing):
    count_assembled = placeGridFamily(
      scratch,
      scale,
      tint,
      radius_ground,
      size_cell,
      along,
      across,
      origin,
    )
  timed(Side.Emitting):
    meshes.addRibbonPieces(
      scratch.ribbons.toOpenArray(0, count_assembled - 1),
      WIDTH_LINE_FURNITURE,
      is_fogged = true,
    )


proc addLattice*(
  meshes: var MeshSet,
  scratch: var DrawScratch,
  extent: float,
  scale: DrawExtent,
  plane: Multivector,
) =
  ## Append lattice on `plane`, so distance and direction on it stay judgeable.
  ##   For each selected plane; world itself carries no ground, since its origin is Sol
  ##   and no plane through it is anybody's floor.
  ##   Laid on plane's own frame from its anchor, world origin's foot on it, so lines
  ##   stand on world's multiples of cell rather than following camera. Plane whose normal
  ##   is world axis is ruled along other two world axes; see `boundary.frame`.
  ##   Fog, not halo.
  ##     Every line is faded by its endpoints' distance from eye and cut off at
  ##     `fogFurnitureFor`'s outer radius, so plane is solid near eye and gone in distance.
  ##     Cutting geometry rather than drawing ever-fainter alpha: past that radius cells
  ##     crowd into so few pixels that even faint line aliases.
  ##   Disc fog sphere leaves about eye's foot on plane; see `radiusOnPlaneFor`.
  ##     Eye further off than fog reaches sees none.
  ##   Dimmed by `ALPHA_GRID` on top of fade, so ruling reads as reference rather than
  ##   content; see that constant.
  ##   Nothing for plane in horizon, which has no finite point to rule about.
  ##   `plane` is world's, as scene stores it; lattice is laid about view origin, from
  ##   plane's anchor read about it and its own normal.
  ##   Frame is spanned here from multivector; twin below takes placement's.
  let axes = frame(plane)
  if axes.isNone: return
  meshes.addLattice(scratch, extent, scale, plane, axes.get)


proc addLattice*(
  meshes: var MeshSet,
  scratch: var DrawScratch,
  extent: float,
  scale: DrawExtent,
  plane: Multivector,
  axes: FramePlane,
) =
  ## Append lattice on finite `plane`, on frame `axes` its placement holds; see twin above.
  ##   For frame's walk of selection, which read plane as placed: frame is not spanned
  ##   again, and plane is known finite.
  ##   Support is read here, since placement holds disc's centre, which creation anchor
  ##   can move off it.
  let anchor_world = positionAnchor(plane, is_horizon = false)
  if anchor_world.isNone: return
  let
    anchor = anchor_world.get.toView(scale.origin)
    reach = radiusOnPlaneFor(
      extent, scale, planeThrough(anchor.toMultivector, axes.normal.toMultivector)
    )
  if reach.isNone: return
  let
    base = Ink.Grid.colour
    tint = base.fade(base.alpha * ALPHA_GRID)
    radius = reach.get
    size_cell = sizeCellGridFor(radius)
    (first, second) = (axes.axis_first, axes.axis_second)
  # Lay one family at time through one scratch.
  #   Buffer is sized for larger family rather than both.
  meshes.addGridFamily(
    scratch,
    scale,
    tint,
    radius,
    size_cell,
    along = first,
    across = second,
    origin = anchor,
  )
  meshes.addGridFamily(
    scratch,
    scale,
    tint,
    radius,
    size_cell,
    along = second,
    across = first,
    origin = anchor,
  )



#[ Object Tessellation ]#

func placeUntimed(placed: var Placement, geometry: Multivector, anchor_override: Option[Position]) =
  ## Ask algebra what object is and where, into `placed`: derivation `placeInto` times.
  ##   Nothing here reads camera; see `Placement`.
  ##   `anchor_override` centres plane's disc there instead of on support; ignored for
  ##   point or line.
  ##   Plane whose support or frame algebra cannot give lands on `PlaneEverywhere`, what
  ##   infinite plane is: sky.
  ##   Tests horizon at most once, and hands answer to every read that asks it; suite holds
  ##   each exit to one test and to answers reads standing alone give.
  ##   Written field by field, never assigned whole: frame places every object, and
  ##   `Placement` or `Option` built and assigned is copy on JS backend (read in emitted JS).
  ##     Coordinates go one by one (`euclid.setTo`), so `placed` shares no storage with any
  ##     input. Fields `kind` leaves meaningless keep whatever they held.
  var kind = Kind.Point
  if not geometry.kindInto(kind):
    placed.kind = Case.Nothing
    return
  case kind
  of Kind.Point:
    # Place point where weight allows; horizon test only where it does not.
    if geometry.positionInto(placed.at):
      placed.kind = Case.PointAt
      return
    let heading = directionHorizon(geometry, is_horizon = geometry.isHorizon)
    if heading.isSome:
      placed.kind = Case.PointToward
      placed.toward.setTo(heading.get)
      return
  of Kind.Line:
    # Test horizon once, and hand answer to each read.
    let
      is_horizon = geometry.isHorizon
      anchor = positionAnchor(geometry, is_horizon = is_horizon)
      axis = direction(geometry, is_horizon = is_horizon)
    if anchor.isSome and axis.isSome:
      placed.kind = Case.LineThrough
      placed.at.setTo(anchor.get)
      placed.toward.setTo(axis.get)
      return
    let normal = directionNormalHorizon(geometry, is_horizon = is_horizon)
    if normal.isSome:
      # Span great circle's plane at origin.
      #   Which plane depends on line, not eye, so circle is centred on eye when drawn
      #   rather than when placed.
      let spanned = spanPerpendicular(ORIGIN_WORLD, normal.get)
      if spanned.isSome:
        placed.kind = Case.LineAcross
        placed.axes.axis_first.setTo(spanned.get[0])
        placed.axes.axis_second.setTo(spanned.get[1])
        placed.axes.normal.setTo(normal.get)
        return
  of Kind.Plane:
    # Test horizon once, and read support once: frame spans about it, and override moves
    #   only disc's centre.
    #   Sky where support, normal or span is none, as where frame itself gave none.
    let
      is_horizon = geometry.isHorizon
      support = positionAnchor(geometry, is_horizon = is_horizon)
      normal = directionNormal(geometry, is_horizon = is_horizon)
    if support.isNone or normal.isNone:
      placed.kind = Case.PlaneEverywhere
      return
    let axes = frame(support.get, normal.get)
    if axes.isNone:
      placed.kind = Case.PlaneEverywhere
      return
    placed.kind = Case.PlaneOn
    placed.at.setTo(if anchor_override.isSome: anchor_override.get else: support.get)
    placed.axes.axis_first.setTo(axes.get.axis_first)
    placed.axes.axis_second.setTo(axes.get.axis_second)
    placed.axes.normal.setTo(axes.get.normal)
    return
  placed.kind = Case.Nothing


proc placeInto*(placed: var Placement, geometry: Multivector, anchor_override: Option[Position]) =
  ## Ask algebra what object is and where, into `placed`: whole placing side, none of emitting.
  ##   Split from `addObject` so frame places once and reads answer in each walk.
  ##   Derivation is `placeUntimed`'s, one call inside stretch, so each answer it leaves by
  ##   is charged: `timed` refuses `return`; see `timings.timed`.
  timed(Side.Placing): placed.placeUntimed(geometry, anchor_override)


proc placeObject*(geometry: Multivector, anchor_override = none(Position)): Placement =
  ## Ask algebra what object is and where, as fresh answer; see `placeInto`.
  ##   For caller placing one object where it draws it: preview, `addObject`, suite.
  result.placeInto(geometry, anchor_override)


func placementOf*(geometry: Multivector, anchor_override = none(Position)): Placement =
  ## Ask algebra what object is and where, as fresh answer charged to no timing side.
  ##   For `func` reading object outside any frame's placements, which cannot read clock:
  ##   camera's aim at staged preview, and caller handing no frame's placements.
  result.placeUntimed(geometry, anchor_override)


func isPointInView*(placed: Placement, radius: float, bounds: ViewBounds): bool =
  ## Report whether point lands inside frustum, own `radius` and least margin included.
  ##   True for every other kind: line crosses whole frame whatever its support, and disc
  ##   reaches past its centre, so neither is tested.
  ##   Radius widens side bounds by itself, in world units: disc whose centre is just
  ##   past edge still shows its near half.
  ##   Horizon point stands along its direction from eye, so its offset is direction
  ##   alone and only sides are tested: its depth is `radius_horizon` scaled by appear
  ##   progress, inside clip either way.
  ##   Components rather than `Direction` difference: object per point per frame on JS
  ##   backend (Art. VII.1). Parameters are read in place, never bound (read in emitted JS).
  ##   Placement is world's: its place is read about view origin first, then against eye.
  var offset_x, offset_y, offset_z: float
  case placed.kind
  of Case.PointAt:
    offset_x = (placed.at.x - bounds.origin.x) - bounds.eye.x
    offset_y = (placed.at.y - bounds.origin.y) - bounds.eye.y
    offset_z = (placed.at.z - bounds.origin.z) - bounds.eye.z
  of Case.PointToward:
    offset_x = placed.toward.x
    offset_y = placed.toward.y
    offset_z = placed.toward.z
  else:
    return true
  let depth = offset_x * bounds.forward.x + offset_y * bounds.forward.y +
      offset_z * bounds.forward.z
  if depth <= 0.0: return false
  if placed.kind == Case.PointAt and
      (depth < bounds.depth_near or depth > bounds.depth_far):
    return false
  let across = offset_x * bounds.right.x + offset_y * bounds.right.y + offset_z * bounds.right.z
  if abs(across) > depth * bounds.bound_width + radius: return false
  let above = offset_x * bounds.up.x + offset_y * bounds.up.y + offset_z * bounds.up.z
  abs(above) <= depth * bounds.bound_height + radius


proc emitObject*(
  meshes: var MeshSet,
  placed: var Placement,
  tint: Rgba,
  scale: DrawExtent,
  progress = 1.0,
  radius: float = RADIUS_OBJECT_DEFAULT,
): Outcome =
  ## Turn one placed object into this frame's records, at this frame's camera.
  ##   Other half of `placeObject`: takes no multivector, so what object *is* was settled
  ##   before and cannot be re-decided here.
  ##   `progress` is how much of appear animation object has completed, from
  ##   `mesh.animationProgress`.
  ##     Fades every kind in, grows plane's disc from nothing, pushes horizon object out
  ##     to full reach.
  ##   `radius` is how large point is drawn, in world units; every other kind ignores it.
  ##     Horizon point stands at `radius_horizon`, where any radius falls to least
  ##     on-screen size, so star reads as dot whatever its object says.
  ##   `placed` is `var` because nothing here writes it (Art. VII.1).
  ##     Under JS backend value parameter is deep-copied at every call, and caller
  ##     emitting thousand placements per frame would copy thousand nested objects.
  ##     Invisible to allocation grep because parameter looks like read.
  ##     Nothing here assigns to it, and nothing may.
  ##   Two steps are still charged to placing side, deliberately.
  ##     Horizon marker's stand-off and line's two vanishing points are multivector
  ##     arithmetic about where eye is: placing work that depends on camera. Cut is by
  ##     *kind of work*, not by which proc it sits in.
  ##   Placement is world's; its place is read about view origin as it enters frame, once.
  case placed.kind
  of Case.Nothing:
    Outcome.Empty

  of Case.PointAt:
    timed(Side.Emitting):
      meshes.addMarker(placed.at.toView(scale.origin), radius, tint, tint.alpha * progress)
    Outcome.Finite

  of Case.PointToward:
    # Place star effectively infinitely far.
    #   Keeps apparent direction as camera pans or dollies, moving only as eye does.
    var star = ORIGIN_WORLD
    timed(Side.Placing):
      star = pointFrom(add(scale.eye_point,
        wedge(progress * scale.radiusHorizon, placed.toward.toMultivector)))
    timed(Side.Emitting):
      meshes.addMarker(star, radius, tint, tint.alpha * progress)
    Outcome.Horizon

  of Case.LineThrough:
    # Draw two segments meeting at support, each running to one of line's vanishing points.
    #   Vanishing point is `scale.eye` plus or minus `scale.radiusHorizon` along attitude,
    #   exactly where horizon marker draws attitude, so line reaches it with no gap.
    #   Two because vanishing point is property of *eye*: end anchored fixed reach from
    #   support stops short by eye-to-line separation over that reach.
    #   Each segment has one end on true line and one at `eye +- radius*axis`, so both
    #   lie in plane through eye containing line, which projects to one screen line.
    #   Cost is depth: far ends are displaced along view ray, so occlusion there is
    #   approximate. Rebuilt against current eye every frame, so not part of `Placement`.
    var far_ahead, far_behind = ORIGIN_WORLD
    timed(Side.Placing):
      let
        reach = progress * scale.radiusHorizon
        axis_point = placed.toward.toMultivector
      far_ahead = pointFrom(add(scale.eye_point, wedge(reach, axis_point)))
      far_behind = pointFrom(add(scale.eye_point, wedge(-reach, axis_point)))
    let
      tint_progress = tint.fade(tint.alpha * progress)
      support = placed.at.toView(scale.origin)
    timed(Side.Emitting):
      meshes.addSegment(support, far_ahead, tint_progress, WIDTH_LINE_OBJECT)
      meshes.addSegment(support, far_behind, tint_progress, WIDTH_LINE_OBJECT)
    Outcome.Finite

  of Case.LineAcross:
    # Trace pencil of directions across sky as great circle around eye.
    timed(Side.Emitting):
      meshes.addGreatCircle(
        scale.eye,
        placed.axes.axis_first,
        placed.axes.axis_second,
        progress * scale.radiusHorizon,
        tint.fade(tint.alpha * progress),
      )
    Outcome.Horizon

  of Case.PlaneOn:
    # Fill first, so plane reads as surface; rim drawn over it marks edge.
    #   Fill is one disc record and rim one ring record, both fanned out by own vertex
    #   shaders.
    let
      extent = progress * EXTENT_PLANE_F
      tint_progress = tint.fade(tint.alpha * progress)
      centre = placed.at.toView(scale.origin)
    timed(Side.Emitting):
      meshes.addDisc(
        centre,
        placed.axes.axis_first,
        placed.axes.axis_second,
        extent,
        tint.fade(ALPHA_VEIL * progress),
      )
      meshes.addRing(
        centre,
        placed.axes.axis_first,
        placed.axes.axis_second,
        extent,
        tint_progress,
        WIDTH_LINE_OBJECT,
      )
    Outcome.Finite

  of Case.PlaneEverywhere:
    # Emit one dome record vertex shader widens over static unit sphere; see `mesh.addDome`.
    timed(Side.Emitting):
      meshes.addDome(
        scale.eye,
        progress * scale.radiusHorizon,
        tint.fade(ALPHA_VEIL_SKY * progress),
      )
    Outcome.Horizon


proc addObject*(
  meshes: var MeshSet,
  scratch: var DrawScratch,
  geometry: Multivector,
  tint: Rgba,
  scale: DrawExtent,
  progress = 1.0,
  anchor_override = none(Position),
  bounds = none(ViewBounds),
  radius: float = RADIUS_OBJECT_DEFAULT,
): Outcome =
  ## Append object, dispatching on geometry its grade stands for.
  ##   Place then emit in one call, for caller with no other reader of placement: preview,
  ##   storyboard, suite.
  ##     Frame that placed its scene already reads those placements and calls `emitObject`;
  ##     see `placeObject`.
  ##   Empty where multivector carries no drawable geometry.
  ##   `progress` defaults to fully appeared, for caller with nothing to animate against.
  ##   `anchor_override` centres plane's disc there instead of support; ignored otherwise.
  ##   `scratch` is taken for shape every other tessellation entry point has.
  ##   `bounds`, where given, skips point outside view before it costs emitting; Empty
  ##   then. See `isPointInView`.
  ##   `radius` is point's drawn radius; see `emitObject`.
  discard scratch
  var placed = placeObject(geometry, anchor_override)
  if bounds.isSome and not isPointInView(placed, radius, bounds.get): return Outcome.Empty
  emitObject(meshes, placed, tint, scale, progress, radius)
