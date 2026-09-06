## Test scene items against cursor, so mouse action knows which object it touched.
##
## Every world-space derivation goes through algebra: rays as joins, hits as meets, depths
## as `depthAgainst`, nearest points and clips by library's operators.
##   Only *pixel* half of test is screen math: point or line is judged by pixel distance
##   to its projection, rasterisation question.
##   Line's endpoints are assembled as `tessellate.addLine` draws them, so hit agrees with
##   what is drawn.
## Plane is tested through algebra rather than around it.
##   Cursor's sight ray is RGA line (eye ∧ heading) met with plane directly, `ray ∨ plane`,
##   giving exact point struck.
##   Screen-space quad projection is trap: corner near eye sends its projection to
##   infinity, and point-in-polygon on blown-up quad accepts cursor nowhere near plane.
##   Meet in 3D fails cleanly (ray parallel, hit behind eye) instead of wrongly.
##
##   |------------|-------------------------------------------------------------------|
##   | Shape      | Tested against                                                    |
##   |------------|-------------------------------------------------------------------|
##   | Point      | Projected marker, by pixel distance.                              |
##   | Line       | Projected drawn segment, by distance to its nearest point.        |
##   | Plane      | Sight ray met with plane, by whether that point falls inside      |
##   |            |   drawn disc, and by distance from eye if it does.                |
##   |------------|-------------------------------------------------------------------|
##
## Point wins tie over line, and line over plane.
##   Smaller pivot should not be swallowed by larger one drawn behind or through it.
##
## Shared by desktop (`visualiser.nim`) and browser (`browser_bridge.nim`) render paths.

{.experimental: "strictFuncs".}
# `handle` names loop variable std's `typedthreads.handle` would win over: template body
#   reads it, and generic `some` instantiates with symbol captured at its own declaration.
#   Cost of naming object address `handle`; see `GLOSSARY.md`.
{.experimental: "openSym".}

import std/[math, options]

import pga
import ./[boundary, camera, euclid, tessellate, scene]



#[ Picking Configuration ]#

const
  FACTOR_ANCHOR_DEPTH* = 2.0
    ## Take object or ground as zoom anchor only within this factor of orbit distance.
    ##   Depth either way; otherwise level through pivot answers.
    ##   Anchor at depth of what reader looks at is what map zoom means. Star field put
    ##   some star under every pixel, and anchoring on one thousand units off carried
    ##   eye across field in few notches and clipped scene away behind it.
  RADIUS_PICK_POINT* = 34.0
    ## Bound how far, in pixels, cursor may sit from point's marker and still hit it.
    ##   Fingertip's contact patch is roughly this wide at phone density.
    ##   Shape priority (point beats line beats plane) keeps generous radius from
    ##   misfiring where targets overlap.
  RADIUS_PICK_LINE* = 24.0
    ## Bound how far, in pixels, cursor may sit from line's drawn segment and still hit it.
    ##   Widened with `RADIUS_PICK_POINT`, for same reason.
  RADIUS_CROWD_TOUCH* = 72.0
    ## Bound how far, in pixels, second item may stand from finger and still make crowd.
    ##   Wider than either pick reach: what is asked is not what finger hit but whether it
    ##   could have meant something else, and finger lands whole fingertip wide of where
    ##   reader aimed. At pick reach alone, star field still turned orbits into drags.
    ##   Rivals are counted here; what is picked stays at pick reach. See `PickReport`.



#[ In-View Configuration ]#

const
  INSET_POINT_SHOWN* = 0.5*float(DIAMETER_POINT_LEAST)
    ## Shrink centred box by this many pixels when asking whether *point* is in view.
    ##   Smallest drawn dot then fits inside rather than only its middle.
    ##   Least radius rather than point's own: sun filling half of frame is shown once its
    ##   centre is, and framing against its disc would push camera out to hold rim.
    ##   Deliberately not selection marker's radius.
    ##     That ring swells while touch hold fills (see `marker.clearanceTouch`), and box
    ##     breathing with gesture would re-frame view mid-hold.
    ##   Nothing equivalent for line, which has only to cross; `INSET_RIM_SHOWN` is plane's.

  INSET_RIM_SHOWN* = 0.5*float(WIDTH_LINE_OBJECT)
    ## Shrink *frame* by this many pixels when asking whether *plane* is in view.
    ##   Rim resting on edge then has whole stroke drawn rather than half clipped.
    ##   Half of what `mesh.addRing` strokes rim at, same relationship `INSET_POINT_SHOWN`
    ##   has to dot, and entire price of letting disc reach edge.



#[ Type Definitions ]#

type ScreenPosition* = object ## Define projected position, in window pixels, y downward.
  x*, y*: float ## Pixel coordinates.
  depth*: float ## View-space depth; positive and smaller is nearer eye.


func towards*(start, finish: ScreenPosition; fraction: float): ScreenPosition =
  ## Step `fraction` of way from `start` to `finish`, along screen.
  ##   Returns `finish` itself at fraction 1 rather than `start + 1.0*(finish - start)`.
  ##     Same point in arithmetic and not always same bits: overlay shortening segment
  ##     for animation has to land exactly on segment it drew before animation existed.
  if fraction >= 1.0: return finish
  ScreenPosition(
    x: start.x + fraction*(finish.x - start.x),
    y: start.y + fraction*(finish.y - start.y),
    depth: start.depth + fraction*(finish.depth - start.depth),
  )



#[ Screen Projection ]#

func projectToScreen*(
  view_projection: Matrix4; width, height: int; position: Position
): ScreenPosition =
  ## Project world position through clip space onto window pixels.
  ##   Written out rather than looped; hot proc.
  ##     Nested loops allocated two four-element arrays per call on JS backend, once per
  ##     live handle per pick, and copies dominated pick's profile.
  ##   Only three rows read are computed: depth is taken from w, which `isInFront` tests.
  let
    x = position.x
    y = position.y
    z = position.z
    clip_x = float(view_projection.at(0, 0))*x + float(view_projection.at(0, 1))*y +
      float(view_projection.at(0, 2))*z + float(view_projection.at(0, 3))
    clip_y = float(view_projection.at(1, 0))*x + float(view_projection.at(1, 1))*y +
      float(view_projection.at(1, 2))*z + float(view_projection.at(1, 3))
    clip_w = float(view_projection.at(3, 0))*x + float(view_projection.at(3, 1))*y +
      float(view_projection.at(3, 2))*z + float(view_projection.at(3, 3))
  ScreenPosition(
    x: ((clip_x/clip_w)*0.5 + 0.5) * float(width),
    y: (1.0 - ((clip_y/clip_w)*0.5 + 0.5)) * float(height),
    depth: clip_w,
  )


func depthAlongSight*(view_projection: Matrix4; position: Position): float =
  ## Report how far `position` stands along sight axis, from eye; negative behind it.
  ##   Projection's own homogeneous weight, what perspective divides by, so same reading
  ##   `worldPerPixelAt` takes off eye and forward, without building offset per point.
  ##   Held equal to that dot product by suite case.
  float(view_projection.at(3, 0))*position.x + float(view_projection.at(3, 1))*position.y +
    float(view_projection.at(3, 2))*position.z + float(view_projection.at(3, 3))


func pixelsFromCursor*(
  view_projection: Matrix4; width, height: int; position: Position; cursor: ScreenPosition
): float =
  ## Report how many pixels `position` projects from `cursor`, or `Inf` behind eye.
  ##   Same projection as `projectToScreen`, answering only question point's hit test asks
  ##   and building nothing.
  ##     `ScreenPosition` per handle was allocation per handle per hover on full scene.
  ##     Distance is float, and float is free.
  ##   `Inf` rather than `Option[float]` for same reason.
  ##     Option is object too, and no real pixel distance is infinite, so sentinel cannot
  ##     collide with answer.
  let clip_w = float(view_projection.at(3, 0))*position.x +
    float(view_projection.at(3, 1))*position.y +
    float(view_projection.at(3, 2))*position.z + float(view_projection.at(3, 3))
  if clip_w <= 1.0e-6: return Inf # Behind eye; `isInFront`'s test.
  let
    clip_x = float(view_projection.at(0, 0))*position.x +
      float(view_projection.at(0, 1))*position.y +
      float(view_projection.at(0, 2))*position.z + float(view_projection.at(0, 3))
    clip_y = float(view_projection.at(1, 0))*position.x +
      float(view_projection.at(1, 1))*position.y +
      float(view_projection.at(1, 2))*position.z + float(view_projection.at(1, 3))
    x = ((clip_x/clip_w)*0.5 + 0.5) * float(width)
    y = (1.0 - ((clip_y/clip_w)*0.5 + 0.5)) * float(height)
  hypot(cursor.x - x, cursor.y - y)


func isInFront*(screen: ScreenPosition): bool = screen.depth > 1.0e-6
  ## Report whether projected position stands in front of eye.
  ##   Where perspective divide and every pixel distance from it are meaningful.



#[ Segment Test ]#

func clipToEyeSide*(
  tail, head: Position; plane_near: Multivector
): Option[(Position, Position)] =
  ## Clip segment `tail`-`head` to near side of `plane_near`.
  ##   Camera's near plane, `DrawExtent.plane_near`: same clip GPU performs when drawing.
  ##   Needed since screen-space hit test divides by each endpoint's depth, which
  ##   `tessellate.addLine`'s far reach can put at or behind eye while near half fills
  ##   screen.
  ##   Crossing is meet of segment's line with plane, and each end's side is its
  ##   `depthAgainst` sign.
  ##     Held equal to componentwise interpolation `tessellate.addSegment` still performs
  ##     by suite case.
  ##   Exported for `marker.markerRails`, which flanks exactly this run: marker drawn past
  ##   eye plane wraps to opposite side of screen.
  ##   None where whole segment lies behind plane.
  let
    depth_tail = depthAgainst(plane_near, toMultivector(tail))
    depth_head = depthAgainst(plane_near, toMultivector(head))
  if depth_tail <= 0.0 and depth_head <= 0.0: return
  if depth_tail > 0.0 and depth_head > 0.0: return some((tail, head))
  let crossing = position(wedgeAnti(
    wedge(toMultivector(tail), toMultivector(head)), plane_near
  ))
  if crossing.isNone: return # Unreachable with straddling signs; stated for reader.
  if depth_tail > 0.0: some((tail, crossing.get)) else: some((crossing.get, head))


func distanceToSegment(point, tail, head: ScreenPosition): float =
  ## Measure pixel distance from `point` to nearest point of segment `tail`-`head`.
  let
    (dx, dy) = (head.x - tail.x, head.y - tail.y)
    length_squared = dx*dx + dy*dy
  if length_squared <= 1.0e-9: return hypot(point.x - tail.x, point.y - tail.y)
  let t =
    clamp(((point.x - tail.x)*dx + (point.y - tail.y)*dy) / length_squared, 0.0, 1.0)
  hypot(point.x - (tail.x + t*dx), point.y - (tail.y + t*dy))



#[ Sight Ray ]#

func castRay*(
  camera: Camera; eye: Position; frame: FrameCamera; width, height: int; cursor: ScreenPosition
): Multivector =
  ## Build RGA line running from eye through cursor's pixel, into scene.
  ##   Undoes `initMatrixProjection`'s construction: cursor becomes NDC again, scaled by
  ##   same field-of-view tangent, composed from camera's right/up/forward.
  ##   Takes eye and frame precomputed.
  ##     One cursor tests against every item with same ray, and recomputing per item
  ##     repeats two joins and antiduals up to `ITEMS_MAX` times.
  let
    half_height = tan(0.5 * degToRad(camera.degrees_field_of_view))
    half_width = half_height * (float(width) / float(height))
    ndc_x = (cursor.x / float(width))*2.0 - 1.0
    ndc_y = 1.0 - (cursor.y / float(height))*2.0
    heading = (ndc_x*half_width)*frame.axis_right + (ndc_y*half_height)*frame.axis_up +
      frame.forward
  toMultivector(eye) ∧ toMultivector(heading)


func positionUnderCursor*(
  camera: Camera; width, height: int; cursor: ScreenPosition
): Option[Position] =
  ## Solve world point cursor is over: where its sight ray meets level plane through pivot.
  ##   None where ray never meets it: looking along it, or away at sky.
  ##   That plane rather than ground at `z = 0`.
  ##     It sits at height reader works at, what they mean by "there", and keeps hit at
  ##     sane distance where ground far below raised pivot puts it wildly far off.
  ##   For zoom keeping what is under cursor under cursor (`camera.dollyToward`).
  ##     Here rather than `camera` because it needs sight ray, and `camera` is what this
  ##     imports.
  let
    eye = camera.eye
    frame_camera = camera.frame(eye)
    ray = castRay(camera, eye, frame_camera, width, height, cursor)
    # Meet horizontal plane through pivot: `objects.levelPlaneThrough`.
    #   One spelling of what level means to algebra.
    hit = position(ray ∨ levelPlaneThrough(toMultivector(camera.pivot)))
  if hit.isNone: return
  # Refuse hit behind eye.
  #   Ray aimed at sky meets plane on far side of reader, and zoom toward it would fly
  #   camera backwards.
  let plane_eye = planeThrough(toMultivector(eye), toMultivector(frame_camera.forward))
  if depthAgainst(plane_eye, toMultivector(hit.get)) <= 1.0e-6: return
  hit


func positionOnLineNearest*(
  anchor: Position, axis: Direction, ray_from: Position, ray_along: Direction
): Option[Position] =
  ## Find point of line through `anchor` along `axis` nearest ray from `ray_from`.
  ##   What line-under-cursor means: cursor is ray, line is line, and in three
  ##   dimensions two miss each other.
  ##     Point of line nearest ray is only answer on line and under cursor at once.
  ##   None where two run parallel, which has no one nearest point.
  ##   Algebra's answer, in three moves.
  ##     Join of two lines' attitudes is horizon line through both directions, whose
  ##     normal is their common perpendicular: `directionNormalHorizon`'s reading,
  ##     vanishing where lines run parallel.
  ##     Plane `ray ∧ commonPerpendicular` contains ray and segment realising nearest
  ##     approach, so its meet with line is that approach's foot.
  ##     Held equal to classical two-dot closed form in suite over scatter of line/ray
  ##     pairs.
  let
    line = wedge(toMultivector(anchor), toMultivector(axis))
    ray = wedge(toMultivector(ray_from), toMultivector(ray_along))
    normal_common = directionNormalHorizon(wedge(attitude(line), attitude(ray)))
  if normal_common.isNone: return
  position(wedgeAnti(line, wedge(ray, toMultivector(normal_common.get))))


func positionOnItemUnder(
  geometry: Multivector, ray: Multivector, plane_eye: Multivector
): Option[Position] =
  ## Solve world point of one item cursor's sight `ray` is over.
  ##   Point stands where it stands, plane is met where ray crosses it, line is read at
  ##   nearest point to ray; see `positionOnLineNearest`.
  ##   Finite shapes only.
  ##     Object at horizon is drawn at `radius_horizon` about eye and is not *at* any
  ##     place, so nothing there to fly toward.
  ##   None also for hit behind eye (depth against `plane_eye`) and for ray with no
  ##   direction.
  if geometry.isHorizon: return
  let
    shaped = shape(geometry)
    heading = direction(ray)
  if shaped.isNone or heading.isNone: return
  var found = none(Position)
  case shaped.get
  of Shape.Point: found = positionAnchor(geometry)
  of Shape.Line:
    let (anchor, axis) = (positionAnchor(geometry), direction(geometry))
    if anchor.isSome and axis.isSome:
      # Read ray's two defining elements off ray multivector.
      #   Nearest-point question is then asked of exactly ray that was cast.
      let ray_from = positionSupport(ray)
      if ray_from.isSome:
        found = positionOnLineNearest(anchor.get, axis.get, ray_from.get, heading.get)
  of Shape.Plane: found = position(ray ∨ geometry)
  if found.isNone: return
  if depthAgainst(plane_eye, toMultivector(found.get)) <= 1.0e-6: return
  found


func positionOnGround*(
  camera: Camera; width, height: int; cursor: ScreenPosition
): Option[Position] =
  ## Solve where cursor's sight ray meets ground plane, `z = 0`.
  ##   None where ray never reaches it: running along ground, or aimed above horizon
  ##   where meet lands behind reader.
  let
    eye = camera.eye
    frame_camera = camera.frame(eye)
    ray = castRay(camera, eye, frame_camera, width, height, cursor)
    hit = position(ray ∨ groundPlane())
  if hit.isNone: return
  let plane_eye = planeThrough(toMultivector(eye), toMultivector(frame_camera.forward))
  if depthAgainst(plane_eye, toMultivector(hit.get)) <= 1.0e-6: return
  hit


func isBeyondDisc(
  view_projection: Matrix4; width, height: int; tangent_half_view: float;
  centre: Position; radius: float; cursor: ScreenPosition
): bool =
  ## Report whether cursor lies outside every pixel disc of `radius` about `centre` could cover.
  ##   Broad phase only, so plane's meet may be skipped: what it lets through, algebra
  ##   decides.
  ##   Bound is sphere about centre.
  ##     Point `c + r*u` projects within `f*r*(1 + |c_xy|/d)/(d - r)` pixels of centre's
  ##     projection, `d` being centre's depth and `f` focal length in pixels.
  ##     Never true with eye inside that sphere. Loose off-axis, which broad phase may be.
  ##     Checked numerically off screen as well as on; see `PROVENANCE.md`.
  ##   Without it every plane's meet ran per hover, for cursor nowhere near most discs.
  let depth = float(view_projection.at(3, 0))*centre.x +
    float(view_projection.at(3, 1))*centre.y +
    float(view_projection.at(3, 2))*centre.z + float(view_projection.at(3, 3))
  if depth <= radius: return false
  let
    clip_x = float(view_projection.at(0, 0))*centre.x +
      float(view_projection.at(0, 1))*centre.y +
      float(view_projection.at(0, 2))*centre.z + float(view_projection.at(0, 3))
    clip_y = float(view_projection.at(1, 0))*centre.x +
      float(view_projection.at(1, 1))*centre.y +
      float(view_projection.at(1, 2))*centre.z + float(view_projection.at(1, 3))
    x = ((clip_x/depth)*0.5 + 0.5)*float(width)
    y = (1.0 - ((clip_y/depth)*0.5 + 0.5))*float(height)
    lateral = tangent_half_view*hypot(clip_x/depth*float(width)/float(height), clip_y/depth)
    focal = float(height)/(2.0*tangent_half_view)
    bound = focal*radius*(1.0 + lateral)/(depth - radius)
  hypot(cursor.x - x, cursor.y - y) > bound


func rayPlaneHit(
  ray, plane_eye: Multivector; plane: Multivector; anchor: Position; extent: float
): Option[float] =
  ## Meet cursor's sight ray with `plane`; report view depth where it lands inside disc.
  ##   Nearer plane can then be preferred over farther one behind it.
  ##   None where ray misses plane, hit falls behind eye (depth against `plane_eye`), or
  ##   lands outside drawn disc.
  ##   Meet is read back as point it names before anything signed is asked of it.
  ##     Meet's weight carries orientation of crossing, and `unitize` divides by weight's
  ##     *norm*, so sign survives it.
  ##     `depthAgainst` is linear in its point, so meet left as it came reports distance
  ##     negated on every plane met from behind its normal, refusing each such plane at
  ##     every pixel of its disc.
  ##     `position` divides by signed weight and `toMultivector` restates answer at
  ##     weight one.
  let met = wedgeAnti(ray, plane)
  let where = position(met)
  if where.isNone: return
  let hit = toMultivector(where.get)

  let distance = depthAgainst(plane_eye, hit)
  if distance <= 1.0e-6: return

  # Bound circularly, matching `mesh.addRing`: hit test agrees with what is drawn.
  if distanceBetween(hit, toMultivector(anchor)) > extent: return
  some(distance)



#[ Item Hit Testing ]#

type PickReport* = object ## Define what one pick found under cursor.
  handle*: Option[int] ## Nearest item of winning rank; none where nothing is in reach.
  count_rivals*: int ## How many items of winner's rank or better stood within
    ## `RADIUS_CROWD_TOUCH`, winner included; zero where nothing was picked.
    ## One where pick is unambiguous. Touch has no hover ring to say which of several
    ## finger is over, so its drag refuses to start above one; see
    ## `interaction.beginDrag`.
    ## Winner's rank or better: point beside picked line is rival, since finger may have
    ## meant it; plane under picked point is not, since rank already decides.
    ## Point hidden behind drawn disc is not either; see `pickAt`.


const HIDERS_MAX = 8
  ## Bound how many drawn discs under cursor one pick keeps, nearest first found.
  ##   Discs stacked under one pixel are planet and its moons at most; ninth is dropped.


type
  Hider = object ## Define one drawn disc cursor lies inside, as seen on screen.
    depth: float ## Along sight axis, from eye.
    x, y, radius: float ## Centre and radius in pixels.

  Hiders = object ## Define drawn discs under cursor, in fixed storage.
    ##   Fixed array rather than sequence: pick runs per pointer event, and sequence per
    ##   event was allocation per event.
    discs: array[HIDERS_MAX, Hider]
    count: int

  PickWalk = object ## Define what one walk of scene under cursor found.
    report: PickReport ## Winner and its rivals, less whatever `hiders` given hid.
    depth_best: float ## Winner's depth along sight axis; `Inf` where nothing won.
    hiders: Hiders ## Drawn discs cursor lay inside, gathered as walk went.


func widest(hiders: Hiders): float =
  ## Measure widest disc under cursor, in pixels; 0 where there is none.
  result = 0.0
  for i in 0 ..< hiders.count: result = max(result, hiders.discs[i].radius)


func coverOf(hiders: Hiders, depth: float, at: ScreenPosition): float =
  ## Measure widest disc covering point at `depth` projecting to `at`, in pixels; 0 if none.
  ##   Disc hides point where it is nearer eye and its drawn disc covers point's centre;
  ##   disc merely under cursor beside point hides nothing of it.
  ##   For rival counting: point behind fingertip-wide cover is not what finger could
  ##   have meant; see `pickAt`.
  result = 0.0
  for i in 0 ..< hiders.count:
    let disc = hiders.discs[i]
    if disc.depth < depth and hypot(at.x - disc.x, at.y - disc.y) <= disc.radius:
      result = max(result, disc.radius)


func add(hiders: var Hiders, hider: Hider) =
  ## Keep one more disc under cursor, dropping it where storage is full.
  if hiders.count >= HIDERS_MAX: return
  hiders.discs[hiders.count] = hider
  inc hiders.count


proc pickWalk(
  scene: Scene; camera: Camera; scale: DrawExtent; view_projection: Matrix4;
  width, height: int; cursor: ScreenPosition; placed: openArray[Placed];
  hiders_known: Hiders; is_points_only: bool
): PickWalk =
  ## Walk every visible item once, ranking what stands within reach of cursor.
  ##   `pickAt`'s one pass; see it for rule. Points `hiders_known` hide are passed over,
  ##   as winner and as rival; discs under cursor met on way are gathered for caller.
  ##   `is_points_only` skips every other kind, for second pass whose winner is already
  ##   known to be point.
  ##   Exceeds 60-line default: three shape branches are irreducibly different geometry,
  ##   each minimal, sharing `eye`/`frame_camera`/`ray`/`scale` setup computed once.

  # Build eye, camera frame and sight ray once: they depend on camera and cursor alone.
  #   `scale` is this camera's own extent, built by `drawExtentFor` this frame; deriving
  #   fresh one here ran `algebraFilled` third time per frame.
  let
    eye = scale.eye
    frame_camera = camera.frame(eye)
    ray = castRay(camera, eye, frame_camera, width, height, cursor)

  var
    handle_best = none(int)
    priority_best = high(int)
    distance_best = Inf
    depth_best = Inf
    hiders: Hiders
    counts_crowd: array[5, int] # Per rank, within `RADIUS_CROWD_TOUCH`.

  template crowd(priority: int) = inc counts_crowd[priority]

  # Rank within kind by what is literally under pointer.
  #   Disc cursor lies inside beats every point it does not, and among those nearest eye
  #   wins; among rest, nearest cursor in pixels. Reach in pixels is for imprecision
  #   where nothing is under pointer.
  var is_under_best = false
  template consider(priority: int, distance, depth: float, is_under: bool) =
    let is_better =
      if priority != priority_best: priority < priority_best
      elif is_under != is_under_best: is_under
      elif is_under: depth < depth_best
      else: distance < distance_best
    if is_better:
      priority_best = priority
      distance_best = distance
      depth_best = depth
      is_under_best = is_under
      handle_best = some(handle)
  # Ask once whether caller brought whole frame's placements; cannot change mid-walk.
  let is_placed_held = placed.len >= ITEMS_MAX
  var placed_here: Placed # Filled per handle only where caller brought none.

  # Walk by handle to `bound`, not to capacity.
  #   Runs per pointer move, and pool walked to capacity tests every empty handle to rank
  #   few live ones.
  #   `placed` stays indexed by handle and sized to capacity: handle is address.
  #   By-handle readers, never `pairs`, which copies whole scene per live handle on JS backend.
  for handle in 0 ..< scene.bound:
    if not scene.isAlive(handle) or not scene.isVisible(handle): continue
    if not is_placed_held:
      placed_here = placeObject(scene.geometryOf(handle), scene.anchorOverrideAt(handle))
    # Read in place, never bound.
    #   `Placed` holds five multivectors, and binding to `let` deep-copies on JS backend.
    #   Both aliases expand to read at each use; confirmed in generated JavaScript that
    #   neither copies.
    template place: untyped = (if is_placed_held: placed[handle] else: placed_here)
    template geometry: untyped = scene.geometryOf(handle)

    case place.kind
    of PlacedKind.Nothing: continue

    of PlacedKind.PointAt:
      # Measure through `pixelsFromCursor`, not `projectToScreen`.
      #   Branch almost every handle takes wants distance, not projected position to
      #   measure one from.
      # Widen to disc drawn where that is larger than generous default.
      #   Sun hundred pixels across is picked anywhere on it, not only near middle.
      # Read depth off projection, and drawn radius off depth.
      #   Neither builds anything per point; see `depthAlongSight`.
      let depth = depthAlongSight(view_projection, place.at)
      if depth <= 1.0e-6: continue # Behind eye; `isInFront`'s test.
      let distance = pixelsFromCursor(view_projection, width, height, place.at, cursor)
      let radius_drawn = radiusPixelsAtDepth(scene.radiusAt(handle), depth, scale.scale)
      let radius_pick = max(RADIUS_PICK_POINT, radius_drawn)
      if distance > max(RADIUS_CROWD_TOUCH, radius_pick): continue
      # Project only what is within reach, which is few; see `pixelsFromCursor`.
      let at = projectToScreen(view_projection, width, height, place.at)
      let is_under = distance <= radius_drawn
      if is_under: hiders.add(Hider(depth: depth, x: at.x, y: at.y, radius: radius_drawn))
      # Behind body wider than fingertip: neither winner nor rival.
      if hiders_known.coverOf(depth, at) >= RADIUS_PICK_POINT: continue
      if distance <= radius_pick: consider(0, distance, depth, is_under)
      crowd(0)

    of PlacedKind.PointToward:
      # Pick direction point where its star is drawn.
      #   One part of point's anchor depending on eye, so not in placement. Matches
      #   `tessellate.anchorFor`.
      let star = position(add(
        scale.eye_point, wedge(scale.radiusHorizon, toMultivector(place.toward)),
      ))
      if star.isNone: continue
      let distance = pixelsFromCursor(view_projection, width, height, star.get, cursor)
      if distance > RADIUS_CROWD_TOUCH: continue
      # Star sits at horizon, deeper than any disc, and is dot cursor is never inside.
      if hiders_known.coverOf(
        scale.radiusHorizon, projectToScreen(view_projection, width, height, star.get)
      ) >= RADIUS_PICK_POINT: continue
      if distance <= RADIUS_PICK_POINT: consider(0, distance, scale.radiusHorizon, false)
      crowd(0)

    of PlacedKind.LineAcross:
      if is_points_only: continue
      # Test against great circle it is drawn as, sampled as `tessellate.addGreatCircle` does.
      #   Hit then agrees with what is drawn.
      #   Stepped off same fixed table: which plane arms span is placement's answer, ring
      #   itself is arithmetic. Sums per candidate per pointer move were price of drift.
      let
        arm_first = scale.radiusHorizon*place.axes.axis_first
        arm_second = scale.radiusHorizon*place.axes.axis_second
      var
        distance_nearest = Inf
        previous = none(ScreenPosition)
      for i in 0 .. SEGMENTS_CIRCLE_HORIZON:
        let entry = UNIT_CIRCLE_RIM[i mod SEGMENTS_CIRCLE_HORIZON]
        let here = projectToScreen(
          view_projection, width, height,
          onCircleAt(scale.eye, arm_first, arm_second, entry.cos_angle, entry.sin_angle),
        )
        if here.isInFront and previous.isSome:
          distance_nearest = min(
            distance_nearest, distanceToSegment(cursor, previous.get, here)
          )
        previous = if here.isInFront: some(here) else: none(ScreenPosition)
      if distance_nearest <= RADIUS_PICK_LINE: consider(2, distance_nearest, Inf, false)
      if distance_nearest <= RADIUS_CROWD_TOUCH: crowd(2)

    of PlacedKind.LineThrough:
      if is_points_only: continue
      # Test both halves `tessellate.addLine` draws, support out to each vanishing point.
      #   Which half is on screen changes as camera orbits.
      var distance_nearest = Inf
      for reach in [scale.radiusHorizon, -scale.radiusHorizon]:
        let clipped = clipToEyeSide(
          place.at,
          pointFrom(add(scale.eye_point, wedge(reach, toMultivector(place.toward)))),
          scale.plane_near,
        )
        if clipped.isNone: continue
        let (position_tail, position_head) = clipped.get
        let
          tail = projectToScreen(view_projection, width, height, position_tail)
          head = projectToScreen(view_projection, width, height, position_head)
        if not (tail.isInFront and head.isInFront): continue
        distance_nearest = min(distance_nearest, distanceToSegment(cursor, tail, head))
      if distance_nearest <= RADIUS_PICK_LINE: consider(1, distance_nearest, Inf, false)
      if distance_nearest <= RADIUS_CROWD_TOUCH: crowd(1)

    of PlacedKind.PlaneOn:
      if is_points_only: continue
      # Meet only where disc could reach cursor at all; see `isBeyondDisc`.
      #   Frame guard is kind's to say: `placeObject` reaches `PlaneOn` only with anchor
      #   and frame in hand, anchor carrying override where disc is actually centred.
      if isBeyondDisc(
        view_projection, width, height, scale.tangentHalfView, place.at, EXTENT_PLANE_F,
        cursor,
      ): continue
      let hit = rayPlaneHit(ray, scale.plane_eye, geometry, place.at, EXTENT_PLANE_F)
      if hit.isSome:
        consider(3, hit.get, Inf, false)
        crowd(3)

    of PlacedKind.PlaneEverywhere:
      if is_points_only: continue
      # Match whole sky last of all, with no distance to measure, so anything else wins.
      #   Asked of geometry, not kind: finite plane whose frame algebra cannot give lands
      #   on this kind, and it was never drawn.
      if geometry.isHorizon:
        consider(4, 0.0, Inf, false)
        crowd(4)

  # Sum crowd of winner's rank and every better one; nothing picked, nothing counted.
  var count_rivals = 0
  if handle_best.isSome:
    for priority in 0 .. priority_best: count_rivals += counts_crowd[priority]
  PickWalk(
    report: PickReport(handle: handle_best, count_rivals: count_rivals),
    depth_best: depth_best, hiders: hiders,
  )


proc pickAt*(
  scene: Scene; camera: Camera; scale: DrawExtent; view_projection: Matrix4;
  width, height: int; cursor: ScreenPosition; placed: openArray[Placed] = []
): PickReport =
  ## Find visible item nearest cursor and count its rivals.
  ##   Prefers points over lines over planes; see `PickReport`.
  ##   `placed` is frame's own placements, where caller kept them.
  ##     `tessellate.placeObject` already answers what object is and where, and
  ##     front-end holding frame's worth of answers (`browser_bridge.PLACEMENTS`) hands them
  ##     over instead of having walk ask again.
  ##     Pick then ranks *what was drawn*, off one derivation, and stops running placing
  ##     side per live handle per pointer event.
  ##   Pass nothing and every handle is placed here instead: desktop path and every suite
  ##   case. Partial array is treated as none: cache is frame's whole answer or not one.
  ##   None where nothing visible falls within its shape's pick radius.
  ##   Every drawn shape is pickable, horizon or not, ranked point, finite line, horizon
  ##   line, finite plane, horizon plane.
  ##     Thin things beat wide ones, and sky comes last: drawn as dome filling every
  ##     direction, it matches every ray and would swallow scene from any other rank.
  ##   Horizon plane being pickable means cursor is over *something* almost everywhere.
  ##     `interaction.beginDrag` refuses to start drag on it for exactly that reason, or
  ##     orbit and pan stop working moment sky is in scene.
  ##   What is under pointer is what is meant. Where cursor lies inside drawn disc of
  ##   some point, nearest such disc to eye wins over every point cursor is not inside,
  ##   however near their centres: star beside planet's rim, and star behind its disc,
  ##   both lost to planet. Pixel reach `RADIUS_PICK_POINT` decides only where cursor is
  ##   inside nothing. Rival counting follows finger, not eye: point covered by nearer
  ##   disc narrower than fingertip is still rival, since two dots overlapping are one
  ##   blob to finger; point covered by fingertip-wide body is not, star behind planet
  ##   being no ambiguity for finger on planet; see `coverOf`. Point covered by disc
  ##   cursor is not inside is left alone: it is reachable from beside its cover, and
  ##   knowing it covered would take every disc, not ones under cursor.
  ##     Discs under cursor are only known once walk is over, and covered rivals only
  ##     then, so second walk where fingertip-wide disc lies under cursor, points only:
  ##     winner is already that disc, and no line or plane needs meeting again. Common
  ##     case is one walk; candidate list per walk was allocation per pointer event, and
  ##     star field puts dozens within reach.
  let first = pickWalk(
    scene, camera, scale, view_projection, width, height, cursor, placed,
    hiders_known = Hiders(), is_points_only = false,
  )
  if first.hiders.widest < RADIUS_PICK_POINT: return first.report
  pickWalk(
    scene, camera, scale, view_projection, width, height, cursor, placed,
    hiders_known = first.hiders, is_points_only = true,
  ).report


proc pickNearest*(
  scene: Scene; camera: Camera; scale: DrawExtent; view_projection: Matrix4;
  width, height: int; cursor: ScreenPosition; placed: openArray[Placed] = []
): Option[int] =
  ## Find visible item nearest cursor, preferring points over lines over planes.
  ##   `pickAt`'s handle alone, for caller with no use for rival count.
  pickAt(scene, camera, scale, view_projection, width, height, cursor, placed).handle


func coversView*(
  centre: Position, radius: float, scale: DrawExtent, width, height: int
): bool =
  ## Report whether disc of `radius` about `centre` spans at least frame's longer side.
  ##   Cursor over such disc has no empty glass beside it to press instead, so it is
  ##   treated as backdrop; see `isBackdropUnder`.
  radius/worldPerPixelAt(centre, scale.scale) >= float(max(width, height))


func isBackdropUnder*(
  scene: Scene, handle: int, scale: DrawExtent, width, height: int
): bool =
  ## Report whether hovered item is backdrop: plane at horizon, or plane filling view.
  ##   Backdrop is click and hold pivot, never drag handle: press on it falls through to
  ##   camera, or view cannot be moved while plane fills every pixel.
  let geometry = scene.geometryOf(handle)
  if geometry.isHorizonPlane: return true
  if shape(geometry) != some(Shape.Plane): return false
  let anchor = anchorFor(geometry, scene.anchorOverrideAt(handle), scale)
  anchor.isSome and coversView(anchor.get, EXTENT_PLANE_F, scale, width, height)


func isAnchorNear(anchor: Position, camera: Camera, scale: DrawExtent): bool =
  ## Report whether anchor's depth is within `FACTOR_ANCHOR_DEPTH` of orbit distance.
  let depth = dot(anchor - scale.eye, scale.forward)
  depth >= camera.distance/FACTOR_ANCHOR_DEPTH and depth <= camera.distance*FACTOR_ANCHOR_DEPTH


type AnchorZoom* = object ## Define what zoom holds still, and whether it stands somewhere.
  at*: Position ## World point that keeps its pixel through zoom.
  is_standing*: bool ## Whether `at` is where point or line stands, not crossing of ray.
    ## What stands somewhere is what reader looks at, so turntable's pivot follows its
    ## depth (`camera.repivotToDepth`). Plane, ground and level are crossings, met where
    ## ray happens to fall: their depth under cursor is not their depth at middle of
    ## frame, and pivot lifted to it stood off plane being zoomed onto. Those three
    ## are followed by map rule alone, pivot sliding toward `at`; see `camera.dollyToward`.


func positionUnderPointerOn*(
  scene: Scene; handle: int; camera: Camera; scale: DrawExtent; width, height: int;
  cursor: ScreenPosition
): Option[Position] =
  ## Solve where one object stands under `cursor`.
  ##   Point at its place, line at its point nearest sight ray, plane where ray crosses it.
  ##   For zoom's anchor and for pointer pick's aim, both holding that place on its pixel.
  ##   None for horizon shapes and hits behind eye; see `positionOnItemUnder`.
  ##   No nearness filter: caller wanting one applies `isAnchorNear`.
  let
    frame_camera = camera.frame(scale.eye)
    ray = castRay(camera, scale.eye, frame_camera, width, height, cursor)
  positionOnItemUnder(scene.geometryOf(handle), ray, scale.plane_eye)


proc anchorZoomAt*(
  scene: Scene; camera: Camera; scale: DrawExtent; view_projection: Matrix4;
  width, height: int; cursor: ScreenPosition; placed: openArray[Placed] = []
): Option[AnchorZoom] =
  ## Solve world point zoom aimed at `cursor` should hold still.
  ##   Whatever finite object cursor is over, else ground under it, else level pivot
  ##   sits on. In that order, and order is rule.
  ##     Reader pointing at object means that object at depth it stands at; zoom
  ##     anchored on plane through pivot crept past or short of it.
  ##     Failing object, ground is what reader means by there, what every map zooms
  ##     against.
  ##     Level through pivot survives as last answer, for cursor on empty sky.
  ##   Object or ground far from what reader looks at is passed over for level through
  ##   pivot; see `FACTOR_ANCHOR_DEPTH`.
  ##   `pickNearest` ranks horizon plane last and matches it everywhere, so sky is under
  ##   cursor almost always; `positionOnItemUnder` refuses horizon shapes for exactly
  ##   that reason, and fall-through does work.
  ##   None where none of three answers, leaving caller to zoom at middle of frame.
  # Take caller's extent.
  #   Wheel handler holds overlay cache's extent for exactly this camera, and deriving
  #   fresh one ran `algebraFilled` and joins per wheel notch.
  let handle = pickNearest(
    scene, camera, scale, view_projection, width, height, cursor, placed,
  )
  if handle.isSome:
    let found = positionUnderPointerOn(scene, handle.get, camera, scale, width, height, cursor)
    if found.isSome and isAnchorNear(found.get, camera, scale):
      let is_standing = shape(scene.geometryOf(handle.get)) != some(Shape.Plane)
      return some(AnchorZoom(at: found.get, is_standing: is_standing))
  let ground = positionOnGround(camera, width, height, cursor)
  if ground.isSome and isAnchorNear(ground.get, camera, scale):
    return some(AnchorZoom(at: ground.get, is_standing: false))
  let level = positionUnderCursor(camera, width, height, cursor)
  if level.isNone: return none(AnchorZoom)
  some(AnchorZoom(at: level.get, is_standing: false))



#[ In View ]#

func marginCentred(width, height: int; inset: float): (float, float) =
  ## Measure how far in, across and down, centred box begins.
  ##   `inset` pulls both margins further in, for caller asking whether something of its
  ##   own size fits.
  ##   Box itself is `camera.reachCentred`'s to shape, so pixel test here and cone
  ##   `camera.distanceFitting` solves cannot disagree about in view.
  let (reach_across, reach_down) = reachCentred(width, height, inset)
  (0.5*(float(width) - reach_across), 0.5*(float(height) - reach_down))


func isWithinCentre(screen: ScreenPosition; width, height: int; inset: float): bool =
  ## Report whether projected point falls inside centred box, in front of eye.
  if not screen.isInFront: return false
  let (margin_x, margin_y) = marginCentred(width, height, inset)
  screen.x >= margin_x and screen.x <= float(width) - margin_x and
    screen.y >= margin_y and screen.y <= float(height) - margin_y


func isWithinFrame(screen: ScreenPosition; width, height: int; inset: float): bool =
  ## Report whether projected point falls on screen at all, in front of eye.
  ##   Looser of two bounds, one plane's rim answers to: disc reaching edge is still
  ##   wholly *visible*.
  ##   What makes plane thing being looked at is its centre, held to `isWithinCentre`.
  if not screen.isInFront: return false
  screen.x >= inset and screen.x <= float(width) - inset and
    screen.y >= inset and screen.y <= float(height) - inset


func isCrossingCentre(tail, head: ScreenPosition; width, height: int): bool =
  ## Report whether any part of screen segment `tail`-`head` falls inside centred box.
  ##   Both ends are taken as already in front of eye; callers clip first.
  ##   Clipped rather than sampled: straight segment either crosses axis-aligned box or
  ##   not, asked exactly for less than sampling enough points to be sure of near-miss.
  # Use no inset: line and plane have only to cross box, never fit inside it.
  let
    (margin_x, margin_y) = marginCentred(width, height, 0.0)
    (dx, dy) = (head.x - tail.x, head.y - tail.y)
  var (enter, leave) = (0.0, 1.0)
  # Cut back run that could still be inside against each edge, Liang-Barsky.
  #   Entering where segment heads into edge, leaving where it heads out; parallel edge
  #   admits or rejects outright.
  for (rate, room) in [
    (-dx, tail.x - margin_x), (dx, float(width) - margin_x - tail.x),
    (-dy, tail.y - margin_y), (dy, float(height) - margin_y - tail.y),
  ]:
    if rate == 0.0:
      if room < 0.0: return false
      continue
    let crossing = room/rate
    if rate < 0.0:
      if crossing > enter: enter = crossing
    elif crossing < leave:
      leave = crossing
    if enter > leave: return false
  true


func isRingCrossingCentre(
  centre: Position; axis_first, axis_second: Direction; radius: float;
  view_projection: Matrix4; width, height: int
): bool =
  ## Report whether world circle, sampled as project draws one, crosses centred box.
  let
    centre_point = toMultivector(centre)
    arm_first = wedge(radius, toMultivector(axis_first))
    arm_second = wedge(radius, toMultivector(axis_second))
  var previous = none(ScreenPosition)
  for i in 0 .. SEGMENTS_CIRCLE_HORIZON:
    let turn =
      (2.0*PI*float(i mod SEGMENTS_CIRCLE_HORIZON))/float(SEGMENTS_CIRCLE_HORIZON)
    let here = projectToScreen(
      view_projection, width, height,
      pointFrom(add(centre_point,
        add(wedge(cos(turn), arm_first), wedge(sin(turn), arm_second)))),
    )
    if here.isInFront and previous.isSome and
        isCrossingCentre(previous.get, here, width, height):
      return true
    previous = if here.isInFront: some(here) else: none(ScreenPosition)
  false


func isRingWithinFrame(
  centre: Position; axis_first, axis_second: Direction; radius: float;
  view_projection: Matrix4; width, height: int
): bool =
  ## Report whether every point of world circle, sampled as project draws one, is on screen.
  ##   Rim alone answers for disc it bounds: disc is flat and frame convex, so rim wholly
  ##   inside carries interior with it.
  ##   False moment any sample falls behind eye: disc reaching past eye has no screen
  ##   extent to fit at any distance without first turning to face it.
  let
    centre_point = toMultivector(centre)
    arm_first = wedge(radius, toMultivector(axis_first))
    arm_second = wedge(radius, toMultivector(axis_second))
  for i in 0 ..< SEGMENTS_CIRCLE_HORIZON:
    let turn = (2.0*PI*float(i))/float(SEGMENTS_CIRCLE_HORIZON)
    let here = projectToScreen(
      view_projection, width, height,
      pointFrom(add(centre_point,
        add(wedge(cos(turn), arm_first), wedge(sin(turn), arm_second)))),
    )
    if not isWithinFrame(here, width, height, INSET_RIM_SHOWN): return false
  true


func isLineShownCentrally(
  m: Multivector; scale: DrawExtent; view_projection: Matrix4; width, height: int
): bool =
  ## Report whether grade-2 object reaches centred box, at horizon or finite.
  if m.isHorizon:
    let normal = directionNormalHorizon(m)
    if normal.isNone: return false
    let axes = spanPerpendicular(ORIGIN_WORLD, normal.get)
    if axes.isNone: return false
    return isRingCrossingCentre(
      scale.eye, axes.get[0], axes.get[1], scale.radiusHorizon,
      view_projection, width, height,
    )

  # Test both halves `tessellate.addLine` draws, clipped to eye side as `pickNearest` clips.
  #   Half can sit behind eye while other half fills frame.
  let (anchor, axis) = (positionAnchor(m), direction(m))
  if anchor.isNone or axis.isNone: return false
  for reach in [scale.radiusHorizon, -scale.radiusHorizon]:
    let clipped = clipToEyeSide(
      anchor.get,
      pointFrom(add(scale.eye_point, wedge(reach, toMultivector(axis.get)))),
      scale.plane_near,
    )
    if clipped.isNone: continue
    let
      tail = projectToScreen(view_projection, width, height, clipped.get[0])
      head = projectToScreen(view_projection, width, height, clipped.get[1])
    if tail.isInFront and head.isInFront and isCrossingCentre(tail, head, width, height):
      return true
  false


func isPlaneShownCentrally(
  m: Multivector; anchor_override: Option[Position];
  view_projection: Matrix4; width, height: int
): bool =
  ## Report whether grade-3 object is in view: disc centred in centred box, rim on screen.
  ##   Two bounds, because disc has middle and extent answering different questions.
  ##     Centre says whether plane is what view is about, so it is held to same box as
  ##     every position.
  ##     Rim says only whether reader sees whole circle, so it is held to frame: disc
  ##     made to fit *centred box* had to be pushed half again further away than showing
  ##     whole circle needed.
  ##   Plane at horizon is whole sky, in view from every camera.
  ##   `anchor_override` centres disc there instead of support, as `tessellate.addPlane`
  ##   reads it; two can stand units apart against disc's radius.
  if m.isHorizon: return true
  let
    anchor = if anchor_override.isSome: anchor_override else: positionAnchor(m)
    axes = frame(m)
  if anchor.isNone or axes.isNone: return false
  # Use no inset on centre: nothing is drawn there, rim alone marks disc.
  if not isWithinCentre(
    projectToScreen(view_projection, width, height, anchor.get), width, height, 0.0
  ):
    return false
  isRingWithinFrame(
    anchor.get, axes.get.axis_first, axes.get.axis_second, EXTENT_PLANE_F,
    view_projection, width, height,
  )


func isShownCentrally*(
  m: Multivector; camera: Camera; width, height: int;
  anchor_override: Option[Position] = none(Position)
): bool =
  ## Report whether `m` is in view, in sense camera framing selection has to satisfy:
  ##
  ##   |--------|---------------------------------------------------------------------|
  ##   | Point  | Its dot fits inside centred box.                                     |
  ##   | Line   | It merely crosses centred box.                                       |
  ##   | Plane  | Its disc is centred in centred box, and its rim is on screen.        |
  ##   |--------|---------------------------------------------------------------------|
  ##
  ##   Three readings, following what each shape is drawn at rather than grade.
  ##     Point's dot and plane's disc are drawn at fixed size camera does not set, so
  ##     each is bounded thing frame can hold.
  ##     Line is drawn out to horizon, which moves with camera, so it has no size to
  ##     fit; crossing middle of frame is what seeing it means.
  ##     Plane splits question in two; see `isPlaneShownCentrally`.
  ##   Each shape is tested against exactly what `tessellate.addObject` puts on screen,
  ##   `anchor_override` included, rule `pickNearest` follows for same reason.
  ##   Only *ratio* of `width` to `height` matters, so caller holding aspect and one
  ##   dimension may pass any pair in that ratio.
  ##   False where `m` draws nothing at all.
  let shape_m = shape(m)
  if shape_m.isNone: return false
  let
    scale = camera.drawExtentFor(height)
    view_projection = camera.initMatrixViewProjection(float(width)/float(height))
  case shape_m.get
  of Shape.Point:
    let anchor = anchorFor(m, scale)
    anchor.isSome and isWithinCentre(
      projectToScreen(view_projection, width, height, anchor.get),
      width, height, INSET_POINT_SHOWN,
    )
  of Shape.Line: isLineShownCentrally(m, scale, view_projection, width, height)
  of Shape.Plane:
    isPlaneShownCentrally(m, anchor_override, view_projection, width, height)
