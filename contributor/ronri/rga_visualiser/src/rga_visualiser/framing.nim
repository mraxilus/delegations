## Frame whatever is being worked on: point camera so every selected object is in view.
##
## One rule, applied once per frame by both front-ends rather than at each event, so no
## path changing scene has to know camera exists. What it watches, in order:
##
##   |----------------------|-----------------------------------------------------------|
##   | Staged preview       | Thing being made, whatever is selected: open edit         |
##   |                      |   session's geometry alone, or apply picker's answer      |
##   |                      |   together with operands it names.                        |
##   | Selection            | Every picked object, together.                            |
##   | Neither              | Nothing; standing offer is withdrawn (`release`).         |
##   |----------------------|-----------------------------------------------------------|
##
## *In view* is `picking.isShownCentrally`: point's dot and finite plane's whole disc
## inside centred box, line merely crossing it.
## *Framed* means camera's pivot moves to middle of everything finite picked, and orbit
## distance grows until every one satisfies that test.
##   Grows only if it must, never shrinks.
## Lives above `picking` because folding selection needs `Selection`, and `picking` cannot
## import it: `selection` imports `marker`, which imports `picking`.
##
## Shared by desktop (`visualiser.nim`) and browser (`bridge.nim`) render paths.
##   Rule was once written out in each, duplication that drifted.

{.experimental: "strictFuncs".}

import std/[math, options]

import pga
import ./[boundary, camera, tessellate, picking, scene, selection]



#[ Framing Configuration ]#

const
  SLACK_FRAMED* = 1.0e-9
    ## Allow eye this fraction of fitting reach inside it, and still count as framed.
    ##   Frame rule is floor, and `camera.stepOutTo` solves for eye standing exactly on
    ##   that floor: bare `>=` against figure solver lands on fails by one ulp, and
    ##   framing then reported its own answer as unframed.
    ##   Relative, not absolute: reach spans thousandths of unit to millions of them.
    ##   Round trip is eye to motor to dolly and back, handful of operations on doubles,
    ##   so about 1e-14 of relative error. This is million times that, and still sixty
    ##   nanometres at one astronomical unit.
    ##   Three searches over projections stood here, and `camera.stepOutTo` replaced all
    ##   of them; their halving counts went with them.
  FRACTION_HEIGHT_APPROACH_POINT* = 0.01
    ## Fix how much of frame's height picked dot's disc spans once pointer pick has come in.
    ##   Chosen by eye: sixth of frame was too close, object filling view with nothing
    ##   about it, and twentieth still too close; hundredth is disc rather than dot, with
    ##   its neighbourhood in frame.
  FRACTION_HEIGHT_APPROACH_PLANE* = 0.40
    ## Fix how much of frame's height picked plane's disc spans once pick has come in.
    ##   Disc's major axis, whatever its tilt. Chosen by eye beside point's: plane that
    ##   only ever pulled back to keep its rim on screen never came to be looked at.


type PointerPick* = object ## Define pick made by pointer, awaiting camera's aim.
  ## Front-end records it beside selection change; `offerAim` consumes it next frame.
  ## What pointer picked is centred as camera comes in; see `stanceApproaching`.
  ##   Where pointer stood is not held: aim reads object's own anchor, not clicked pixel.
  handle*: int ## Object clicked or tapped.



#[ What Is Being Watched ]#

iterator watched*(
  scene: Scene, picked: Selection, staged: Option[Preview]
): (Multivector, Option[Position]) =
  ## Walk whatever camera is asked to show, in order module doc states.
  ##   Each comes beside anchor its disc is drawn about where it has one: plane's creation
  ##   anchor, see `scene.creationAnchor`.
  ##   Something staged takes whole offer: it is thing being made, and selection beside it
  ##   is not what reader looks at.
  ##   What goes with it depends on where it came from, which `Preview.operands` says.
  ##     Preview named operands, so they are framed *with* it: result judged without
  ##     objects it was applied to is half picture.
  ##     Open edit session names none, and must not: its staged geometry *replaces* object
  ##     selected beside it.
  ##   Skips handles gone dead since selection was made.
  ##     Selection outlives removal of what it names, and operand can go same way with
  ##     picker left open across delete.
  if staged.isSome:
    yield (staged.get.geometry, staged.get.anchor)
    if staged.get.operands.isSome:
      let (first, second) = staged.get.operands.get
      # Yield unary operation's operand once.
      #   Bound cannot be widened by ball it holds, but middle folded twice is pulled
      #   toward, and camera turns about that middle.
      for handle in (if first == second: @[first] else: @[first, second]):
        if scene.isAlive(handle):
          yield (scene.geometryOf(handle), scene.anchorOverrideAt(handle))
  else:
    for position in 0 ..< picked.len:
      let handle = picked.at(position)
      if scene.isAlive(handle):
        yield (scene.geometryOf(handle), scene.anchorOverrideAt(handle))


func reachOfPlacement(placed: Placement, radius: float): float =
  ## Measure how far one placed object stands from world origin, disc's reach included.
  ##   Zero for horizon kinds and nothing: neither has place to clip.
  ##   `radius` is point's drawn radius, added so far clip holds whole disc.
  case placed.kind
  of Case.PointAt:
    norm(placed.at - Position(x: 0, y: 0, z: 0)) + radius
  of Case.LineThrough:
    norm(placed.at - Position(x: 0, y: 0, z: 0))
  of Case.PlaneOn:
    norm(placed.at - Position(x: 0, y: 0, z: 0)) + EXTENT_PLANE_F
  else: 0.0


func reachOf*(placed: openArray[Placement], scene: Scene): float =
  ## Measure how far scene's farthest visible finite object stands from origin.
  ##   For `Camera.reach_scene`, from placements caller already holds; browser path.
  ##   Sibling of `reachOf(scene)`, which places for itself.
  result = 0.0
  for handle in 0 ..< scene.bound:
    if not scene.isAlive(handle) or not scene.isVisible(handle): continue
    result = max(result, reachOfPlacement(placed[handle], scene.radiusAt(handle)))


func reachNearOf*(
  placed: openArray[Placement], scene: Scene; eye: Position, forward: Direction
): float =
  ## Measure how near nearest drawn object stands ahead of eye, along sight.
  ##   For `Camera.reach_near`, from placements caller already holds.
  ##   Depth along sight, never distance, and never behind eye.
  ##     What reader turned away from is not drawn, and scale read off it would follow
  ##     that.
  ##   Object's own middle, with no drawn radius taken off: camera at planet's surface
  ##   then reads that planet's radius rather than zero, and near clip of one
  ##   four-hundredth of it still holds whole planet.
  ##   Horizon kinds answer nothing, as they do for `reachOfPlacement`: neither stands
  ##   anywhere.
  ##   Zero where nothing is drawn ahead, which hands scale back to separation.
  result = 0.0
  for handle in 0 ..< scene.bound:
    if not scene.isAlive(handle) or not scene.isVisible(handle): continue
    let place = placed[handle]
    if place.kind notin {Case.PointAt, Case.LineThrough, Case.PlaneOn}: continue
    let depth = dot(place.at - eye, forward)
    if depth <= 0.0: continue
    if result <= 0.0 or depth < result: result = depth


proc reachOf*(scene: Scene): float =
  ## Measure how far scene's farthest visible finite object stands from origin.
  ##   For `Camera.reach_scene` on path holding no placements; desktop, once per scene
  ##   change. Sibling of `reachOf(placed, scene)`.
  result = 0.0
  for handle, one in scene.pairs:
    if not one.isVisible: continue
    result = max(
      result, reachOfPlacement(placeObject(one.geometry, one.anchorOverride), one.radius)
    )


func aimFor*(
  scene: Scene, picked: Selection, staged: Option[Preview], scale: DrawExtent
): Option[CameraAim] =
  ## Resolve what camera is asked to bring into view, or none where nothing is.
  ##   Pure function of geometry: see `CameraAim`, whose worth is that caller re-offering
  ##   same selection every frame offers something comparing equal.
  result = none(CameraAim)
  for (m, anchor) in watched(scene, picked, staged):
    result = result.aimIncluding(m, scale, anchor)


func isShownAll*(
  scene: Scene; picked: Selection; staged: Option[Preview];
  placement: Camera; width, height: int
): bool =
  ## Report whether every watched object is in view at once, each by own criterion.
  ##   True of nothing at all: camera asked to show no objects shows all of them.
  for (m, anchor) in watched(scene, picked, staged):
    if not isShownCentrally(m, placement, width, height, anchor): return false
  true



#[ Resolving Placement ]#

func isFramed*(aim: CameraAim; camera: Camera; width, height: int): bool =
  ## Report whether camera already holds every finite object `aim` names.
  ##   One comparison against one bounding sphere, and no projection of anything.
  ##   True where `aim` names nothing finite: horizon objects are bound by their own rule,
  ##   and camera asked to hold no finite object holds them all.
  if aim.sphere.isNone: return true
  let reach = distanceFitting(
    aim.sphere.get.radius, camera, width, height, INSET_POINT_SHOWN
  )
  norm(camera.eye - aim.sphere.get.centre) >= reach*(1.0 - SLACK_FRAMED)


func headingFacing*(aim: CameraAim): Option[Direction] =
  ## Read direction camera should face to show horizon objects `aim` names, or none.
  ##   Horizon point is faced along its own direction. Where only lines were asked for,
  ##   first axis spanning perpendicular to their circle's normal is faced, which puts some
  ##   of that circle in view.
  ##   Point wins where both were asked for, because point is stricter.
  if aim.heading.isSome: return aim.heading
  if aim.normal_crossing.isNone: return none(Direction)
  let axes = spanPerpendicular(ORIGIN_WORLD, aim.normal_crossing.get)
  if axes.isNone: return none(Direction)
  some(axes.get[0])


func isBounded*(aim: CameraAim; camera: Camera; width, height: int): bool =
  ## Report whether camera already satisfies every horizon bound `aim` names.
  ##   True where anything finite was asked for: finite framing wins outright, and horizon
  ##   object then stays selected with its own demand unmet. Two can disagree, and star
  ##   behind reader beside point in front has no placement showing both.
  ##   True where no horizon object was asked for, and for horizon plane, which is in view
  ##   at every orientation.
  if aim.sphere.isSome: return true
  let
    forward = camera.frame.forward
    half = halfAngleCentred(camera, width, height, INSET_POINT_SHOWN)
  # Star has to be on screen: sight within box's half-angle of it. Two freedoms bound.
  if aim.heading.isSome:
    return dot(forward, aim.heading.get) >= cos(half) - SLACK_FRAMED
  if aim.normal_crossing.isNone: return true
  # Circle has to cross screen: sight within that half-angle of circle's own plane. One.
  abs(dot(forward, aim.normal_crossing.get)) <= sin(half) + SLACK_FRAMED


func holdHorizon*(camera: var Camera; aim: CameraAim; width, height: int) =
  ## Turn camera least it takes to satisfy every horizon bound `aim` names.
  ##   Turn about line through eye, because horizon object is direction and eye stands.
  ##   Least turn is along great circle from sight toward what is demanded, so whatever
  ##   reader turned across bound survives, and only part through it is given
  ##   up: camera slides along bound rather than stopping dead.
  ##   Refuses outright where finite framing is also asked for; see `isBounded`.
  if aim.sphere.isSome: return
  if aim.isBounded(camera, width, height): return
  let
    forward = camera.frame.forward
    half = halfAngleCentred(camera, width, height, INSET_POINT_SHOWN)
  let toward =
    if aim.heading.isSome: aim.heading.get
    elif aim.normal_crossing.isSome: aim.normal_crossing.get
    else: return
  # Axis is sight crossed with what is demanded, which is what turns one into other.
  #   Parallel pair names no axis, and none is needed: sight already points at it.
  let axis = normalize(Direction(
    x: forward.y*toward.z - forward.z*toward.y,
    y: forward.z*toward.x - forward.x*toward.z,
    z: forward.x*toward.y - forward.y*toward.x,
  ))
  if axis.isNone: return
  let angle_now = arccos(clamp(dot(forward, toward), -1.0, 1.0))
  let angle_held =
    if aim.heading.isSome: half
    # Circle's plane is what sight must come near, so target is quarter turn off normal,
    #   on whichever side sight already stands.
    else: (
      if dot(forward, toward) >= 0.0: 0.5*PI - half else: 0.5*PI + half
    )
  # Positive turn about sight crossed with what is demanded carries sight toward it, so
  #   overshoot is what is given back.
  camera.turnAboutEye(axis.get, angle_now - angle_held)


func holdFramed*(camera: var Camera; aim: CameraAim; width, height: int) =
  ## Carry eye back out until it holds every finite object `aim` names.
  ##   Floor, not fit: reader standing further out is left alone, and only nearer than
  ##   fitting reach is refused.
  ##   Eye goes straight out from sphere's centre, which is least move restoring rule.
  ##     That keeps whichever way round reader had got to, so camera slides along bound
  ##     rather than stopping dead against it.
  ##     Along their own step instead would land further back than rule asks, and would
  ##     need step threaded through every verb.
  ##   Pivot is re-stamped onto centre, so separation follows eye rather than going stale.
  ##   Nothing finite named means no bound; horizon objects are bound by their own rule.
  if aim.sphere.isNone: return
  let
    reach = distanceFitting(
      aim.sphere.get.radius, camera, width, height, INSET_POINT_SHOWN
    )
    centre = aim.sphere.get.centre
    offset = camera.eye - centre
    span = norm(offset)
  if span >= reach*(1.0 - SLACK_FRAMED): return
  # Eye sitting on centre has no way out to choose, so back along sight.
  let heading = if span > 0.0: (1.0/span)*offset else: -camera.frame.forward
  camera.slideBy(wedge(reach - span, toMultivector(heading)))
  let depth = dot(centre - camera.eye, camera.frame.forward)
  if depth > 0.0: camera.repivotToDepth(depth)


func stanceFor*(aim: CameraAim; camera: Camera; width, height: int): CameraStance =
  ## Resolve `aim` against camera as it stands into placement ease should end at.
  ##   Pivot to middle of everything finite picked, and separation pulled back only as far
  ##   as frame rule demands. Never in: rule is floor, so reader standing further out
  ##   keeps their own framing.
  ##   Angles face horizon objects only where nothing finite was.
  ##     Finite framing wins outright over facing star, since two can disagree. Star
  ##     behind reader and point in front have no placement showing both, and selection
  ##     with something finite is one reader works on.
  ##   Pivot comes to middle of what was picked even where nothing is pulled back: reader
  ##   who picks object and turns means to turn about *it*. Bound still decides separation.
  ##   Two searches stood here, and both are gone.
  ##     One bisected separation between where camera stood and distance whole sphere fits,
  ##     running `isShownAll` at each halving. `camera.stepOutTo` answers in closed form.
  ##     Other bisected fraction of whole move already showing everything. Move is least by
  ##     construction now: pivot goes to centroid, and separation gives up exactly what
  ##     rule demands.
  ##   Price is named in `CameraAim`: one bounding sphere frames line further out than
  ##   crossing frame would need.
  let pivot = if aim.centroid.isSome: aim.centroid.get else: camera.pivot
  # Framing something finite turns nothing, so whole motion crosses and roll with it.
  let settled = camera.stanceRepivoted(pivot)
  if aim.sphere.isNone:
    # Horizon object alone, and it turns only where its own bound is broken: one already
    #   in view keeps reader's own framing, as finite selection already fitting does.
    let facing = aim.headingFacing
    if facing.isNone or aim.isBounded(camera, width, height): return settled
    # Turntable rebuild is what names that turn. Roll is given up here, because direction
    #   alone names no roll to keep. Clamped as `camera.placedAtElevation` is: past pole
    #   rebuilt frame collapses.
    let angles = azimuthElevationFor(facing.get)
    return stanceTurntable(
      pivot, camera.distance, angles[0],
      clamp(angles[1], -ELEVATION_LIMIT, ELEVATION_LIMIT),
    )
  # Pull eye back along its own sight, by least step carrying it out to fitting reach.
  #   Sphere's centre is not pivot, so separation is not that reach; quadratic is what
  #   accounts for offset between them.
  let
    placed = camera.placed(settled)
    axes = placed.frame
    reach = distanceFitting(
      aim.sphere.get.radius, placed, width, height, INSET_POINT_SHOWN
    )
    back = stepOutTo(placed.eye - aim.sphere.get.centre, -axes.forward, reach)
  if back <= 0.0: return settled
  camera.stanceDollied(settled, settled.distance + back)


func stanceApproaching*(
  shaped: Kind; radius: float; centre: Position; camera: Camera; scale: DrawExtent
): Option[CameraStance] =
  ## Resolve where camera ends after pointer pick: object centred, and come in to.
  ##   Pivot goes onto object's own anchor, so it sits at middle of frame and orbit turns
  ##   about it rather than about empty point beside it.
  ##     Held under pointer before, on whichever pixel reader clicked. Pivot then stood on
  ##     sight line at that object's depth, units away from object itself, and every orbit
  ##     swung object round screen rather than turning it where it stood.
  ##   Camera slides rather than turns, so angles and roll both survive; see
  ##   `camera.stanceRepivoted`.
  ##   How far in depends on shape and on what reader could see.
  ##     Point drawn at floor dot (`DIAMETER_POINT_LEAST`) is only place, so camera comes
  ##     in until its disc spans `FRACTION_HEIGHT_APPROACH_POINT` of frame's height: moon
  ##     picked from 168 units out becomes moon.
  ##     Point seen at its size, and line, come in no further than orbit distance: reader
  ##     at working scale picking operands keeps that scale, as ever.
  ##     Neither moves eye further off than object already stands: pick of one already
  ##     close leaves reader's own scale alone.
  ##     Plane comes in until its whole disc spans `FRACTION_HEIGHT_APPROACH_PLANE`, which
  ##     is reach its own centre asks for rather than one any crossing does.
  ##   None where object is not ahead of eye, leaving caller `stanceFor`. Centring one
  ##   behind reader would slide camera back past it rather than turn, which is jump
  ##   nobody asked for; frame rule turns nothing and handles it by its own bound.
  let reach_now = norm(centre - camera.eye)
  if dot(centre - camera.eye, camera.frame.forward) <= 1.0e-6: return
  var depth_end = min(reach_now, camera.distance)
  case shaped
  of Kind.Point:
    let is_dot =
      radius < 0.5*float(DIAMETER_POINT_LEAST)*worldPerPixelAt(centre, scale.scale)
    if is_dot:
      depth_end = min(
        reach_now, depthSpanning(2.0*radius, FRACTION_HEIGHT_APPROACH_POINT, camera)
      )
  of Kind.Plane:
    depth_end = depthSpanning(2.0*EXTENT_PLANE_F, FRACTION_HEIGHT_APPROACH_PLANE, camera)
    if depth_end <= 1.0e-6: return
  of Kind.Line: discard
  some(camera.stanceDollied(camera.stanceRepivoted(centre), distanceHeld(depth_end)))



#[ Standing Offer ]#

func offerAim*(
  tween: var CameraTween; camera: var Camera; scene: Scene; picked: Selection;
  staged: Option[Preview]; scale: DrawExtent; width, height: int; now, duration: float;
  pointer: var Option[PointerPick]; is_moving_camera = false
) =
  ## Offer camera whatever is being worked on to look at.
  ##   One call both front-ends and storyboard make, once per frame.
  ##   Standing offer, re-made every frame: `aimAt` ignores goal it already holds, so
  ##   unchanged scene costs nothing while moving one (coefficient being dragged) reads as
  ##   one continuous chase.
  ##   Anything drawing nothing, empty selection included, aims at nothing and releases,
  ##   which lets picking same object again aim at it afresh.
  ##   `isGoalHeld` guard skips re-offering aim already held, and is passed over while
  ##   frame rule is broken: that is how resize corrects itself.
  ##   `pointer` is pick made since last offer, consumed here whatever comes of it.
  ##     Guard is skipped for it: object already held, picked again, is taken to again.
  ##     Where selection is exactly that object and nothing is staged, destination centres
  ##     it and comes in to it (`stanceApproaching`); group and horizon shape frame as
  ##     ever, since group has to fit, which one object's reach cannot promise.
  # Take caller's extent, not second derivation.
  #   Building another here ran `algebraFilled` and `camera.frame`'s joins twice per frame.
  let aim = aimFor(scene, picked, staged, scale)
  let pick = pointer
  pointer = none(PointerPick)
  if aim.isNone:
    tween.release()
    return
  # Hold frame rule, in whichever way suits what reader is doing.
  #   Reader moving camera is cut back at once: ease would fight their own drag, and they
  #   are one in control.
  #   Still camera eases back in instead, which is what window resized and selection grown
  #   both get, through same standing offer.
  let is_framed = aim.get.isFramed(camera, width, height) and
    aim.get.isBounded(camera, width, height)
  if not is_framed and is_moving_camera:
    camera.holdFramed(aim.get, width, height)
    camera.holdHorizon(aim.get, width, height)
    return
  if pick.isNone and is_framed and tween.isGoalHeld(aim.get): return
  var destination = none(CameraStance)
  if pick.isSome and staged.isNone and picked.len == 1 and picked.at(0) == pick.get.handle and
      scene.isAlive(pick.get.handle):
    let
      m = scene.geometryOf(pick.get.handle)
      shaped = kindOf(m)
      # Size plane by disc it is drawn as, about its stored anchor.
      centre = anchorFor(m, scene.anchorOverrideAt(pick.get.handle), scale)
    if shaped.isSome and not isHorizon(m) and centre.isSome:
      destination = stanceApproaching(
        shaped.get, scene.radiusAt(pick.get.handle), centre.get, camera, scale
      )
  if destination.isNone:
    destination = some(stanceFor(aim.get, camera, width, height))
  tween.aimAt(
    camera, aim.get, destination.get, now, duration, is_renewed = pick.isSome,
  )


func offerAimAt*(
  tween: var CameraTween; camera: Camera; m: Multivector;
  width, height: int; now, duration: float
) =
  ## Offer camera one object, outside any scene.
  ##   For storyboard, whose captures aim at step's derived multivector before selection
  ##   could name it.
  ##   Same rule, so captured frame and interactive one agree on where object is worth
  ##   looking from.
  ##   Empty scene and selection are never read: `previewStaging` names no operands, so
  ##   `watched` yields one object and stops.
  ##     Cost is one zeroed `Scene` per capture, storyboard's rather than frame loop's.
  var alone: Scene
  var pointer = none(PointerPick)
  var held = camera
  offerAim(
    tween, held, alone, Selection(), some(previewStaging(m, RADIUS_OBJECT_DEFAULT)),
    camera.drawExtentFor(height), width, height, now, duration, pointer,
  )
