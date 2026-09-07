## Turn geometry into picture through algebra, handing plain places down to `mesh`.
##
## Reads what object is through algebra, places every point of its drawing through
## algebra, and hands places to `mesh` to pack into vertices.
## Geometry side of drawing.
##   Owns what thing is and where it stands: scene object, lattice line of ground grid,
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
##
## Shared by desktop (`visualiser.nim`) and browser (`bridge.nim`) render paths.

{.experimental: "codeReordering".}
{.experimental: "strictFuncs".}

import std/[math, options]

# `pga` arrives through `projections`, which stands in for four it has withdrawn.
import ./projections
import ./[boundary, mesh, timings]

export mesh



#[ Type Definitions ]#

type
  DrawExtent* = object ## Define frame's camera in both languages at once.
    ## Euclidean half is `mesh.DrawScale`, carried whole so caller holding extent still
    ## says `scale.eye`.
    ## Four multivector twins beside it are algebra's reading of same camera.
    ##   Derived once per frame in `camera.drawExtentFor`, so nothing downstream rebuilds
    ##   `toMultivector(eye)` per segment.
    scale*: DrawScale ## Everything picture is measured against; see `mesh.DrawScale`.
    eye_point*: Multivector ## Eye as unit-weight point.
    forward_point*: Multivector ## Sight direction as horizon point.
    plane_eye*: Multivector ## Unitized plane through eye perpendicular to sight.
      ## `depthAgainst` it is view depth, sign "in front".
    plane_near*: Multivector ## Same plane pushed `depth_near` forward.
      ## Near clip as algebra states it, for `clipToEyeSide`'s meet.


# Read through to Euclidean half, so caller writes `scale.eye`, not `scale.scale.eye`.
#   Split is about which module may *name* multivector.
func extentFurniture*(d: DrawExtent): float = d.scale.extent_furniture
  ## Read how far furniture reaches.

func eye*(d: DrawExtent): Position = d.scale.eye
  ## Read where eye stands.

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

# Convert whole half implicitly, so extent hands to any of `mesh`'s procs unwrapped.
#   Extent *is* scale with algebra's reading beside it, conversion runs one way, and no
#   second type could be confused for it.
converter toScale*(d: DrawExtent): DrawScale = d.scale


func algebraFilled*(scale: DrawExtent): DrawExtent =
  ## Return extent with its four multivector twins derived from its plain fields.
  ##   One derivation point: `camera.drawExtentFor` goes through here, and so must any
  ##   hand-built extent (test fixture, partial one).
  ##     Otherwise twins are zero multivectors and everything algebraic downstream silently
  ##     draws nothing; suite's fixtures once built extents fieldwise and lost ground grid.
  result = scale
  result.eye_point = toMultivector(scale.eye)
  result.forward_point = toMultivector(scale.forward)
  result.plane_eye = planeThrough(result.eye_point, result.forward_point)
  result.plane_near = planeThrough(
    add(result.eye_point, wedge(scale.depthNear, result.forward_point)),
    result.forward_point,
  )



#[ Representative Point ]#

func anchorFor*(m: Multivector, scale: DrawExtent): Option[Position] =
  ## Resolve one point standing for `m`, for picking point and for cursor feedback.
  ##   Point uses own place, or own star position in horizon, matching where
  ##   `mesh.addPoint` draws it.
  ##   Line and plane use support point, what mesh anchors on.
  ##     Neither needs horizon anchor: `pickNearest` tests horizon line against great
  ##     circle it is drawn as and matches horizon plane outright.
  ##   None where `m` carries no drawable geometry.
  let kind = kindOf(m)
  if kind.isNone: return
  case kind.get
  of Kind.Point:
    let place = position(m)
    if place.isSome: return place
    let heading = directionHorizon(m)
    if heading.isNone: return
    position(add(
      scale.eye_point, wedge(scale.radiusHorizon, toMultivector(heading.get))
    ))
  of Kind.Line, Kind.Plane:
    positionAnchor(m)


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
  if anchor_override.isSome and kindOf(m) == some(Kind.Plane): return anchor_override
  anchorFor(m, scale)



#[ Segments and Circles ]#

func addGreatCircle(
  meshes: var MeshSet; center: Position; axis_first, axis_second: Direction;
  radius: float; tint: Rgba
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
  scratch: var DrawScratch; count_assembled: var int; centre, axis_point: Multivector;
  span: float; tint: Rgba; scale: DrawExtent
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
  ##   Faded out and cut off in ground grid's own fog, rather than running full furniture
  ##   extent at flat alpha.
  ##     Axis reaching horizon at full strength was longest, brightest mark in frame, and
  ##     readers took them for drawn lines.
  ##     Sharing grid's fog puts all furniture inside one horizon, so reference reads as
  ##     neighbourhood around *reader*.
  ##   Each axis is drawn only over stretch inside fog: chord of sphere of radius
  ##   `radius_gone` about eye. Axis eye has flown clear of contributes nothing.
  const AXES_WORLD = [
    (Direction(x: 1, y: 0, z: 0), Ink.AxisX),
    (Direction(x: 0, y: 1, z: 0), Ink.AxisY),
    (Direction(x: 0, y: 0, z: 1), Ink.AxisZ),
  ]
  let fog = fogFurnitureFor(extent)
  var count_assembled = 0
  for (axis, ink) in AXES_WORLD:
    # Solve chord of fog sphere along this axis, about eye's perpendicular foot on it.
    #   Foot is algebra's orthogonal projection of eye onto axis line.
    #   Chord half-length stays scalar solve, since sphere has no representative in rigid
    #   algebra: one documented exception.
    let
      axis_line = wedge(toMultivector(ORIGIN_WORLD), toMultivector(axis))
      foot_raw = projectOrthogonal(scale.eye_point, axis_line)
      foot = position(foot_raw)
    if foot.isNone: continue
    let
      separation = distanceBetween(unitize(foot_raw), scale.eye_point)
      half_squared = fog.radius_gone*fog.radius_gone - separation*separation
    if half_squared <= 0.0: continue
    let
      half = sqrt(half_squared)
      tint = ink.colour
      foot_point = unitize(foot_raw)
      axis_point = toMultivector(axis)
    # Place one piece for whole chord: fade and across both run in shaders.
    #   See `mesh.expandRibbon` and `mesh.alphaGridFade`.
    scratch.placeChord(count_assembled, foot_point, axis_point, half, tint, scale)

  count_assembled


proc addAxes*(
  meshes: var MeshSet, scratch: var DrawScratch, extent: float, scale: DrawExtent
) =
  ## Append world axes; `placeAxes` says what each is and how far it runs.
  ##   Two calls, for reason `addGridFamily` gives.
  var count_assembled = 0
  timed(Side.Placing): count_assembled = placeAxes(scratch, extent, scale)
  timed(Side.Emitting):
    meshes.addRibbonPieces(
      scratch.ribbons.toOpenArray(0, count_assembled - 1), WIDTH_LINE_FURNITURE,
      is_fogged = true,
    )


func radiusOnPlaneFor*(extent: float, scale: DrawExtent, plane: Multivector): Option[float] =
  ## Solve how far lattice laid on `plane` reaches from eye's foot on it.
  ##   Fog is sphere about eye, so what it leaves on any plane is disc about that foot, of
  ##   radius `sqrt(radius_gone^2 - height^2)`, height being eye's depth against plane.
  ##     Algebra's answer for any plane, not ground's alone.
  ##   None where eye stands further off than fog reaches.
  let
    fog = fogFurnitureFor(extent)
    height = abs(depthAgainst(plane, scale.eye_point))
    radius_squared = fog.radius_gone*fog.radius_gone - height*height
  if radius_squared <= 0.0: return
  some(sqrt(radius_squared))


func radiusGroundFor*(extent: float, scale: DrawExtent): Option[float] =
  ## Solve how far ground grid reaches from point directly below eye, in world units.
  ##   For camera whose furniture extends `extent`.
  ##   Disc fog sphere leaves on ground, height read as eye's depth against
  ##   `objects.groundPlane`. None where eye stands higher than fog reaches.
  ##   Stated here rather than inside `addGrid` because cell size shown on scale bar has to
  ##   be cell grid was drawn with; two derivations of same disc are two chances to
  ##   disagree.
  radiusOnPlaneFor(extent, scale, groundPlane())


func sizeCellGridAt*(extent: float, scale: DrawExtent): Option[float] =
  ## Report cell size ground grid is laid on for this camera, in world units.
  ##   None where no ground is drawn. One answer both grid and scale bar read.
  let radius_ground = radiusGroundFor(extent, scale)
  if radius_ground.isNone: return
  some(sizeCellGridFor(radius_ground.get))


func placeGridFamily(
  scratch: var DrawScratch; scale: DrawExtent; tint: Rgba;
  radius_ground, size_cell: float; along, across: Direction; origin: Position
): int =
  ## Resolve one family of lattice lines into `scratch`, one piece per line; report count.
  ##   Every line runs along `along`, stepped by `size_cell` along `across`, within
  ##   `radius_ground` of eye's foot on plane two span.
  ##   Draws nothing: algebra's half of seam, all multivector work.
  ##     Per-piece fade colours moved to fragment shader with fog (`mesh.alphaGridFade`),
  ##     taking family from boundary sum per fade piece to two per line.
  ##   Lattice is laid on any plane through `origin` spanned by `along` and `across`;
  ##     ground is that case with `origin` at world origin and two world axes for span.
  ##   Cell is passed in rather than read from `SIZE_CELL_GRID`, so both families lie on
  ##   one `sizeCellGridFor` answered for this frame's disc.
  ##   Lines sit on *world* multiples of cell size, not offsets from camera.
  ##     What slides past as reader moves is world going by, and line stays where it was.
  # Resolve eye onto two lattice axes.
  #   Depth against plane through origin perpendicular to each: algebra's statement of
  #   coordinate. One plane per family per frame.
  let
    origin_point = toMultivector(origin)
    along_point = toMultivector(along)
    across_point = toMultivector(across)
    centre_across = depthAgainst(planeThrough(origin_point, across_point), scale.eye_point)
    centre_along = depthAgainst(planeThrough(origin_point, along_point), scale.eye_point)
    first = int(ceil((centre_across - radius_ground)/size_cell))
    last = int(floor((centre_across + radius_ground)/size_cell))
  var count_assembled = 0
  for i in first .. last:
    # Skip lattice line through world origin.
    #   It coincides with world axis, and would fight it for depth or hide its colour
    #   under grid grey.
    if i == 0: continue
    let
      offset = float(i)*size_cell
      reach_squared = radius_ground*radius_ground -
        (offset - centre_across)*(offset - centre_across)
    if reach_squared <= 0.0: continue
    let
      reach = sqrt(reach_squared)
      base = add(origin_point,
        add(wedge(offset, across_point), wedge(centre_along, along_point)))
    # Assemble, not draw; see `placeChord`, which stops silently at scratch's end.
    #   `mesh.LINES_GRID_MAX` sizes it from bound `CELLS_GRID_HALF_MAX` puts on
    #   `first .. last`, so full buffer means bound was raised and this was not.
    scratch.placeChord(count_assembled, base, along_point, reach, tint, scale)

  count_assembled


proc addGridFamily*(
  meshes: var MeshSet; scratch: var DrawScratch; scale: DrawExtent; tint: Rgba;
  radius_ground, size_cell: float; along, across: Direction;
  origin: Position = ORIGIN_WORLD
) =
  ## Append one family of lattice lines; `placeGridFamily` says what family is.
  ##   Seam, as two calls.
  ##     Where pieces go is worked out by one proc and drawn by another, so line between
  ##     algebra and picture runs between two functions, and each side is timed by bracket
  ##     enclosing none of other's work. See `timings`.
  var count_assembled = 0
  timed(Side.Placing):
    count_assembled = placeGridFamily(
      scratch, scale, tint, radius_ground, size_cell, along, across, origin,
    )
  timed(Side.Emitting):
    meshes.addRibbonPieces(
      scratch.ribbons.toOpenArray(0, count_assembled - 1), WIDTH_LINE_FURNITURE,
      is_fogged = true,
    )


proc addGrid*(
  meshes: var MeshSet, scratch: var DrawScratch, extent: float, scale: DrawExtent
) =
  ## Append reference grid on ground, so distance and direction stay judgeable.
  ##   Laid at `sizeCellGridFor` cells around wherever camera stands.
  ##   Fog, not halo.
  ##     Every line is faded by its endpoints' distance from eye and cut off at
  ##     `fogFurnitureFor`'s outer radius, so ground is solid underfoot and gone in
  ##     distance.
  ##     Cutting geometry rather than drawing ever-fainter alpha: past that radius cells
  ##     crowd into so few pixels that even faint line aliases.
  ##   Disc fog sphere leaves about point below eye, of radius
  ##   `sqrt(radius_gone^2 - height^2)`.
  ##     Camera high above ground sees less of it, and eye higher than fog reaches sees
  ##     none.
  ##   Dimmed by `ALPHA_GRID` on top of fade, so ruled ground reads as reference rather
  ##   than content; see that constant.
  let
    base = Ink.Grid.colour
    tint = base.fade(base.alpha*ALPHA_GRID)
    # Take disc and cell both through `radiusGroundFor`.
    #   What reader is told cell is and what grid is drawn with cannot come apart.
    reach = radiusGroundFor(extent, scale)
  if reach.isNone: return
  let
    radius_ground = reach.get
    size_cell = sizeCellGridFor(radius_ground)
  # Lay one family at time through one scratch.
  #   Buffer is sized for larger family rather than both.
  meshes.addGridFamily(
    scratch, scale, tint, radius_ground, size_cell,
    along = Direction(x: 0, y: 1, z: 0), across = Direction(x: 1, y: 0, z: 0),
  )
  meshes.addGridFamily(
    scratch, scale, tint, radius_ground, size_cell,
    along = Direction(x: 1, y: 0, z: 0), across = Direction(x: 0, y: 1, z: 0),
  )



#[ Object Tessellation ]#

type
  Case* {.pure.} = enum ## Define which drawable algebra found, and its placement.
    Nothing ## No drawable geometry at all; nothing is emitted.
    PointAt ## Point standing somewhere in finite world.
    PointToward ## Horizon point: direction, drawn as star on sky.
    LineThrough ## Line through support, running along attitude.
    LineAcross ## Horizon line: pencil of directions its two axes span.
    PlaneOn ## Plane anchored somewhere, disc spanned by two arms.
    PlaneEverywhere ## Horizon plane: whole sky, carrying no orientation.

  Placement* = object ## Define everything *algebra* says about one object, and nothing else.
    ## Camera is not in it, and that is whole point.
    ##   Every reader here (`position`, `positionAnchor`, `direction`, `directionHorizon`,
    ##   `frame`, `spanPerpendicular`) is pure function of multivector, so this stays true
    ##   while camera orbits.
    ##   Caller that can say when object last changed places it once and emits every
    ##   frame; `bridge` is that caller.
    ##     Placing was most of moving frame's scene phase, recomputed per orbit frame for
    ##     objects nobody touched.
    ## Flat rather than variant object.
    ##   Copied per handle into `array[OBJECTS_MAX, Placement]`, and case object's tag would buy
    ##   nothing but narrower read. Which fields carry meaning is `kind`'s to say.
    kind*: Case
    at*: Position ## Where it stands: point's place, line's support, plane's disc centre.
      ## Meaningless for two horizon kinds and `Nothing`.
    toward*: Direction ## Direction it names: horizon point's heading, line's attitude.
      ## Meaningless for either plane kind and `Nothing`.
    axes*: FramePlane ## Two arms disc or great circle is spanned by, and their normal.
      ## Carried by `PlaneOn` and `LineAcross` only.

  ViewBounds* = object ## Define frustum points are tested against before emitting.
    ## Everything `isPointInView` reads, derived once per frame by `camera.viewBoundsFor`.
    ##   Scalars and directions alone, so test allocates nothing per point (Art. VII.1).
    eye*: Position ## Where depth is measured from.
    forward*: Direction ## Sight axis, depth is measured along.
    right*: Direction ## View's +x, unit.
    up*: Direction ## View's +y, unit.
    depth_near*: float ## Nearest depth drawn; nearer is clipped by GPU as well.
    depth_far*: float ## Furthest depth drawn; further is clipped by GPU as well.
    bound_width*: float ## Half-width of view per unit of depth, sprite margin included.
    bound_height*: float ## Half-height of view per unit of depth, sprite margin included.


proc placeObject*(
  geometry: Multivector, anchor_override: Option[Position] = none(Position)
): Placement =
  ## Ask algebra what object is and where: whole placing side of cut, none of emitting.
  ##   Split from `addObject` so caller may keep answer.
  ##     Nothing here reads camera, so answer changes only when object does. See `Placement`.
  ##   `anchor_override` centres plane's disc there instead of on support; ignored for
  ##   point or line.
  ##   Plane whose support or frame algebra cannot give lands on `PlaneEverywhere`, what
  ##   infinite plane is: sky.
  timed(Side.Placing):
    let kind = kindOf(geometry)
    if kind.isNone: return Placement(kind: Case.Nothing)
    case kind.get
    of Kind.Point:
      let place = position(geometry)
      if place.isSome: return Placement(kind: Case.PointAt, at: place.get)
      let heading = directionHorizon(geometry)
      if heading.isSome: return Placement(kind: Case.PointToward, toward: heading.get)
    of Kind.Line:
      let
        anchor = positionAnchor(geometry)
        axis = direction(geometry)
      if anchor.isSome and axis.isSome:
        return Placement(kind: Case.LineThrough, at: anchor.get, toward: axis.get)
      let normal = directionNormalHorizon(geometry)
      if normal.isSome:
        # Span great circle's plane at origin.
        #   Which plane depends on line, not eye, so circle is centred on eye when drawn
        #   rather than when placed.
        let spanned = spanPerpendicular(ORIGIN_WORLD, normal.get)
        if spanned.isSome:
          return Placement(kind: Case.LineAcross, axes: FramePlane(
            axis_first: spanned.get[0],
            axis_second: spanned.get[1],
            normal: normal.get,
          ))
    of Kind.Plane:
      let
        anchor = if anchor_override.isSome: anchor_override else: positionAnchor(geometry)
        axes = frame(geometry)
      if anchor.isSome and axes.isSome:
        return Placement(kind: Case.PlaneOn, at: anchor.get, axes: axes.get)
      return Placement(kind: Case.PlaneEverywhere)
  Placement(kind: Case.Nothing)


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
  var rx, ry, rz: float
  case placed.kind
  of Case.PointAt:
    rx = placed.at.x - bounds.eye.x
    ry = placed.at.y - bounds.eye.y
    rz = placed.at.z - bounds.eye.z
  of Case.PointToward:
    rx = placed.toward.x
    ry = placed.toward.y
    rz = placed.toward.z
  else:
    return true
  let depth = rx*bounds.forward.x + ry*bounds.forward.y + rz*bounds.forward.z
  if depth <= 0.0: return false
  if placed.kind == Case.PointAt and
      (depth < bounds.depth_near or depth > bounds.depth_far):
    return false
  let across = rx*bounds.right.x + ry*bounds.right.y + rz*bounds.right.z
  if abs(across) > depth*bounds.bound_width + radius: return false
  let above = rx*bounds.up.x + ry*bounds.up.y + rz*bounds.up.z
  abs(above) <= depth*bounds.bound_height + radius


proc emitObject*(
  meshes: var MeshSet, placed: var Placement, tint: Rgba, scale: DrawExtent,
  progress: float = 1.0, radius: float = RADIUS_OBJECT_DEFAULT, light: Direction = LIGHT_NONE
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
  ##   `light` is direction finite point is shaded from; see `lighting`. Horizon point is
  ##   never shaded: it is direction, not body.
  ##   `placed` is `var` because nothing here writes it (Art. VII.1).
  ##     Under JS backend value parameter is deep-copied at every call, and caller
  ##     emitting thousand held placements per frame would copy thousand nested objects.
  ##     Invisible to allocation grep because parameter looks like read.
  ##     Nothing here assigns to it, and nothing may.
  ##   Two steps are still charged to placing side, deliberately.
  ##     Horizon marker's stand-off and line's two vanishing points are multivector
  ##     arithmetic about where eye is: placing work that depends on camera and cannot be
  ##     cached. Cut is by *kind of work*, not by which proc it sits in.
  case placed.kind
  of Case.Nothing:
    Outcome.Empty

  of Case.PointAt:
    timed(Side.Emitting):
      meshes.addMarker(placed.at, radius, light, tint, tint.alpha*progress)
    Outcome.Finite

  of Case.PointToward:
    # Place star effectively infinitely far.
    #   Keeps apparent direction as camera pans or dollies, moving only as eye does.
    var star = ORIGIN_WORLD
    timed(Side.Placing):
      star = pointFrom(add(scale.eye_point,
        wedge(progress*scale.radiusHorizon, toMultivector(placed.toward))))
    timed(Side.Emitting):
      meshes.addMarker(star, radius, LIGHT_NONE, tint, tint.alpha*progress)
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
        reach = progress*scale.radiusHorizon
        axis_point = toMultivector(placed.toward)
      far_ahead = pointFrom(add(scale.eye_point, wedge(reach, axis_point)))
      far_behind = pointFrom(add(scale.eye_point, wedge(-reach, axis_point)))
    let tint_progress = tint.fade(tint.alpha*progress)
    timed(Side.Emitting):
      meshes.addSegment(placed.at, far_ahead, tint_progress, WIDTH_LINE_OBJECT)
      meshes.addSegment(placed.at, far_behind, tint_progress, WIDTH_LINE_OBJECT)
    Outcome.Finite

  of Case.LineAcross:
    # Trace pencil of directions across sky as great circle around eye.
    timed(Side.Emitting):
      meshes.addGreatCircle(
        scale.eye, placed.axes.axis_first, placed.axes.axis_second,
        progress*scale.radiusHorizon, tint.fade(tint.alpha*progress),
      )
    Outcome.Horizon

  of Case.PlaneOn:
    # Fill first, so plane reads as surface; rim drawn over it marks edge.
    #   Fill is one disc record and rim one ring record, both fanned out by own vertex
    #   shaders.
    let
      extent = progress*EXTENT_PLANE_F
      tint_progress = tint.fade(tint.alpha*progress)
    timed(Side.Emitting):
      meshes.addDisc(
        placed.at, placed.axes.axis_first, placed.axes.axis_second, extent,
        tint.fade(ALPHA_WASH*progress),
      )
      meshes.addRing(
        placed.at, placed.axes.axis_first, placed.axes.axis_second, extent, tint_progress,
        WIDTH_LINE_OBJECT,
      )
    Outcome.Finite

  of Case.PlaneEverywhere:
    # Emit one dome record vertex shader widens over static unit sphere; see `mesh.addDome`.
    timed(Side.Emitting):
      meshes.addDome(
        scale.eye, progress*scale.radiusHorizon, tint.fade(ALPHA_WASH_SKY*progress),
      )
    Outcome.Horizon


proc addObject*(
  meshes: var MeshSet, scratch: var DrawScratch, geometry: Multivector, tint: Rgba,
  scale: DrawExtent, progress: float = 1.0,
  anchor_override: Option[Position] = none(Position),
  bounds: Option[ViewBounds] = none(ViewBounds), radius: float = RADIUS_OBJECT_DEFAULT,
  light: Direction = LIGHT_NONE
): Outcome =
  ## Append object, dispatching on geometry its grade stands for.
  ##   Place then emit in one call, for every caller with nothing to gain by keeping
  ##   placement: desktop path, storyboard, suite.
  ##     Caller drawing same unchanged object frame after frame holds `Placement` and calls
  ##     `emitObject`; see `placeObject`.
  ##   Empty where multivector carries no drawable geometry.
  ##   `progress` defaults to fully appeared, for caller with nothing to animate against.
  ##   `anchor_override` centres plane's disc there instead of support; ignored otherwise.
  ##   `scratch` is taken for shape every other tessellation entry point has.
  ##   `bounds`, where given, skips point outside view before it costs emitting; Empty
  ##   then. See `isPointInView`.
  ##   `radius` is point's drawn radius and `light` its sun's direction; see `emitObject`.
  discard scratch
  var placed = placeObject(geometry, anchor_override)
  if bounds.isSome and not isPointInView(placed, radius, bounds.get): return Outcome.Empty
  meshes.emitObject(placed, tint, scale, progress, radius, light)
