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
## *Framed* means camera's target moves to middle of everything finite picked, and orbit
## distance grows until every one satisfies that test.
##   Grows only if it must, never shrinks.
## Lives above `picking` because folding selection needs `Selection`, and `picking` cannot
## import it: `selection` imports `marker`, which imports `picking`.
##
## Shared by desktop (`visualiser.nim`) and browser (`browser_bridge.nim`) render paths.
##   Rule was once written out in each, duplication that drifted.

{.experimental: "strictFuncs".}

import std/options

import pga
import ./[boundary, camera, tessellate, picking, scene, selection]



#[ Framing Configuration ]#

const
  ROUNDS_DISTANCE_FIT* = 8
    ## Fix halvings run when searching least orbit distance bringing selection into view.
    ##   Eight lands within 1/256 of bracket, itself distance at which selection exactly
    ##   fills box, so residue is fraction of percent of spread framed.
    ##   Finer than reader sees; each halving costs projection of every selected object.
  STEPS_PLACEMENT_LEAST* = 12
    ## Fix fractions of full framing move tried, evenly spaced, when cutting it back.
    ##   Coarse on purpose: they only bracket crossing, which halvings then close on, and
    ##   each step costs projection of every selected object.
  ROUNDS_PLACEMENT_LEAST* = 5
    ## Fix halvings run inside bracketed step.
    ##   Five puts answer within 1/384 of full move, under pixel of any pan or turn here.
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
  ## What pointer picked stays under pointer as camera comes in; see `placementUnderPointer`.
  handle*: int ## Object clicked or tapped.
  cursor*: ScreenPosition ## Where pointer stood, window pixels.



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


func reachOfPlaced(placed: Placed, radius: float): float =
  ## Measure how far one placed object stands from world origin, disc's reach included.
  ##   Zero for horizon kinds and nothing: neither has place to clip.
  ##   `radius` is point's drawn radius, added so far clip holds whole disc.
  case placed.kind
  of PlacedKind.PointAt:
    norm(placed.at - Position(x: 0, y: 0, z: 0)) + radius
  of PlacedKind.LineThrough:
    norm(placed.at - Position(x: 0, y: 0, z: 0))
  of PlacedKind.PlaneOn:
    norm(placed.at - Position(x: 0, y: 0, z: 0)) + EXTENT_PLANE_F
  else: 0.0


func reachOf*(placed: openArray[Placed], scene: Scene): float =
  ## Measure how far scene's farthest visible finite object stands from origin.
  ##   For `Camera.reach_scene`, from placements caller already holds; browser path.
  ##   Sibling of `reachOf(scene)`, which places for itself.
  result = 0.0
  for handle in 0 ..< scene.bound:
    if not scene.isAlive(handle) or not scene.isVisible(handle): continue
    result = max(result, reachOfPlaced(placed[handle], scene.radiusAt(handle)))


proc reachOf*(scene: Scene): float =
  ## Measure how far scene's farthest visible finite object stands from origin.
  ##   For `Camera.reach_scene` on path holding no placements; desktop, once per scene
  ##   change. Sibling of `reachOf(placed, scene)`.
  result = 0.0
  for handle, item in scene.pairs:
    if not item.isVisible: continue
    result = max(
      result, reachOfPlaced(placeObject(item.geometry, item.anchorOverride), item.radius)
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

func placementFor*(
  aim: CameraAim; scene: Scene; picked: Selection; staged: Option[Preview];
  camera: Camera; width, height: int
): CameraPlacement =
  ## Resolve `aim` against camera as it stands into placement ease should end at.
  ##   Least movement, pan, zoom and orbit together, putting every picked object in view;
  ##   none at all where they all already are.
  ##   Full move it is cut back from: target to middle of everything finite picked, angles
  ##   facing horizon objects only where nothing finite was, distance pulled back only as
  ##   far as fitting demands and never in.
  ##     Orbit is preferred *against* by construction: finite selection's full move
  ##     carries no turn, so no fraction of it does; horizon-only selection's move is turn
  ##     because pan and zoom cannot bring star into view.
  ##   Finite framing wins outright over facing star, since two can disagree.
  ##     Star behind reader and point in front have no placement showing both, and
  ##     selection with something finite is one reader works on.
  ##     Star picked beside point may stay out of view.
  # Charge nothing for fitting where everything is already in view, judged where camera is.
  #   Judging at centred placement pulled view about on every pick of something plainly
  #   visible.
  #   Target still comes to middle of what was picked: reader who picks object and turns
  #   means to turn about *it*.
  #   Aim compares equal from next frame on, so ease runs once per pick; see `CameraAim`
  #   and `CameraTween.abandon`.
  if isShownAll(scene, picked, staged, camera, width, height):
    var held = camera.placementOf
    if aim.centroid.isSome: held.target = aim.centroid.get
    return held

  let angles =
    if aim.sphere.isSome or aim.heading.isNone: (camera.azimuth, camera.elevation)
    else: azimuthElevationFor(aim.heading.get)
  var settled = CameraPlacement(
    # Aim at middle of what was picked, not middle of bound holding it.
    #   Bound still decides *distance*.
    target: if aim.centroid.isSome: aim.centroid.get else: camera.target,
    distance: camera.distance,
    azimuth: angles[0],
    # Clamp as orbit drag is.
    #   Past pole camera's up runs along sight axis and frame collapses.
    elevation: clamp(angles[1], -ELEVATION_LIMIT, ELEVATION_LIMIT),
  )
  if aim.sphere.isSome and
      not isShownAll(scene, picked, staged, camera.placed(settled), width, height):
    # Bracket with distance at which whole sphere fits, then halve into it for least.
    #   Closed form alone over-dollies: line whose support stands hundred units away needs
    #   no pulling back if it already crosses frame, and flat disc seen at angle needs far
    #   less room than sphere holding it from every side.
    var
      near = camera.distance
      far = max(
        camera.distance,
        distanceFitting(aim.sphere.get.radius, camera, width, height, INSET_POINT_SHOWN),
      )
    settled.distance = far
    # Halve soundly because test is monotone in distance.
    #   Everything converges on middle of frame as eye pulls back.
    if isShownAll(scene, picked, staged, camera.placed(settled), width, height):
      for _ in 1 .. ROUNDS_DISTANCE_FIT:
        let middle = 0.5*(near + far)
        settled.distance = middle
        if isShownAll(scene, picked, staged, camera.placed(settled), width, height):
          far = middle
        else: near = middle
      settled.distance = far

  # Stand whole where even full move shows nothing.
  #   Selection wider than world may be viewed from, or two stars facing opposite ways.
  if not isShownAll(scene, picked, staged, camera.placed(settled), width, height):
    return settled

  # Cut whole move back to least fraction already showing everything.
  #   Searched along path ease travels (`toward`), each candidate verified at own trial
  #   placement so partial pan and partial zoom cannot admit fraction that fails.
  #   Step-then-halve handles path not being strictly monotone.
  # Start from where camera stands but already centred.
  #   Re-centring is not concession to fitting, and in path search would find fraction of
  #   nothing shows everything.
  var start = camera.placementOf
  start.target = settled.target
  var (lower, upper) = (0.0, 1.0)
  for step in 1 .. STEPS_PLACEMENT_LEAST:
    let fraction = float(step)/float(STEPS_PLACEMENT_LEAST)
    if isShownAll(
      scene, picked, staged, camera.placed(start.toward(settled, fraction)), width, height
    ):
      (lower, upper) = (float(step - 1)/float(STEPS_PLACEMENT_LEAST), fraction)
      break
  for _ in 1 .. ROUNDS_PLACEMENT_LEAST:
    let middle = 0.5*(lower + upper)
    if isShownAll(
      scene, picked, staged, camera.placed(start.toward(settled, middle)), width, height
    ):
      upper = middle
    else: lower = middle
  start.toward(settled, upper)



func placementUnderPointer*(
  anchor: Position; shaped: Shape; radius: float; centre: Position; camera: Camera;
  scale: DrawExtent
): Option[CameraPlacement] =
  ## Resolve where camera ends after pointer pick, `anchor` kept on its pixel.
  ##   Wheel's own move (`camera.dollyToward` then `retargetToDepth`): eye comes in along
  ##   its line to anchor, angles untouched, target set on sight line at anchor's depth.
  ##   How far in depends on shape and on what reader could see.
  ##     Point drawn at floor dot (`DIAMETER_POINT_LEAST`) is only place, so camera comes
  ##     in until its disc spans `FRACTION_HEIGHT_APPROACH_POINT` of frame's height: moon
  ##     picked from 168 units out becomes moon.
  ##     Point seen at its size, and line, come in no further than orbit distance: reader
  ##     at working scale picking operands keeps that scale, as ever.
  ##     Neither moves eye further off than anchor already stands: pick of object already
  ##     close leaves picture as it is, target alone moving to its depth.
  ##     Plane is framed both ways, disc's `centre` brought to depth where its diameter
  ##     spans `FRACTION_HEIGHT_APPROACH_PLANE`, crossing under pointer held meanwhile.
  ##       Eye moving along its line to anchor by factor `s` puts centre at depth
  ##       `d_c - d_a + s*d_a`, so anchor ends at `D - d_c + d_a`.
  ##   Written out rather than through `dollyToward`, whose near floor scales eye's move
  ##   by less than factor asked and would leave target short of anchor's depth.
  ##   None where anchor is not ahead of eye, or plane's centre stands further behind
  ##   crossing than its depth to be, leaving caller `placementFor`.
  let
    eye = camera.eye
    forward = camera.frame(eye).forward
    depth_now = dot(anchor - eye, forward)
  if depth_now <= 1.0e-6: return
  var depth_end = min(depth_now, camera.distance)
  case shaped
  of Shape.Point:
    let is_dot =
      radius < 0.5*float(DIAMETER_POINT_LEAST)*worldPerPixelAt(anchor, scale.scale)
    if is_dot:
      depth_end = min(
        depth_now, depthSpanning(2.0*radius, FRACTION_HEIGHT_APPROACH_POINT, camera)
      )
  of Shape.Plane:
    let depth_centre = dot(centre - eye, forward)
    depth_end = depthSpanning(2.0*EXTENT_PLANE_F, FRACTION_HEIGHT_APPROACH_PLANE, camera) -
      depth_centre + depth_now
    if depth_end <= 1.0e-6: return
  of Shape.Line: discard
  depth_end = distanceHeld(depth_end)
  # Assemble eye as anchor plus offset back toward where it stood, scaled by depths.
  let eye_settled = position(add(
    toMultivector(anchor),
    wedge(depth_end/depth_now, subtract(toMultivector(eye), toMultivector(anchor))),
  ))
  if eye_settled.isNone: return
  some(CameraPlacement(
    target: Position(
      x: eye_settled.get.x + depth_end*forward.x,
      y: eye_settled.get.y + depth_end*forward.y,
      z: eye_settled.get.z + depth_end*forward.z,
    ),
    distance: depth_end,
    azimuth: camera.azimuth,
    elevation: camera.elevation,
  ))



#[ Standing Offer ]#

func offerAim*(
  tween: var CameraTween; camera: Camera; scene: Scene; picked: Selection;
  staged: Option[Preview]; scale: DrawExtent; width, height: int; now, duration: float;
  pointer: var Option[PointerPick]
) =
  ## Offer camera whatever is being worked on to look at.
  ##   One call both front-ends and storyboard make, once per frame.
  ##   Standing offer, re-made every frame: `aimAt` ignores goal it already holds, so
  ##   unchanged scene costs nothing while moving one (coefficient being dragged) reads as
  ##   one continuous chase.
  ##   Anything drawing nothing, empty selection included, aims at nothing and releases,
  ##   which lets picking same object again aim at it afresh.
  ##   `isGoalHeld` guard keeps `placementFor`'s search off hot path: offer is re-made
  ##   every frame selection stands.
  ##   `pointer` is pick made since last offer, consumed here whatever comes of it.
  ##     Guard is skipped for it: object already held, picked again, is taken to again.
  ##     Where selection is exactly that object and nothing is staged, destination keeps
  ##     it under pointer (`placementUnderPointer`); group and horizon shape frame as
  ##     ever, since group has to fit, which holding one pixel cannot promise.
  # Take caller's extent, not second derivation.
  #   Building another here ran `algebraFilled` and `camera.frame`'s joins twice per frame.
  let aim = aimFor(scene, picked, staged, scale)
  let pick = pointer
  pointer = none(PointerPick)
  if aim.isNone:
    tween.release()
    return
  if pick.isNone and tween.isGoalHeld(aim.get): return
  var
    destination = none(CameraPlacement)
    anchor = none(Position)
  if pick.isSome and staged.isNone and picked.len == 1 and picked.at(0) == pick.get.handle and
      scene.isAlive(pick.get.handle):
    let
      m = scene.geometryOf(pick.get.handle)
      shaped = shape(m)
      # Size plane by disc it is drawn as, about its stored anchor.
      centre = anchorFor(m, scene.anchorOverrideAt(pick.get.handle), scale)
    if shaped.isSome and not isHorizon(m) and centre.isSome:
      anchor = positionUnderPointerOn(
        scene, pick.get.handle, camera, scale, width, height, pick.get.cursor
      )
      if anchor.isSome:
        destination = placementUnderPointer(
          anchor.get, shaped.get, scene.radiusAt(pick.get.handle), centre.get, camera, scale
        )
  if destination.isNone:
    anchor = none(Position)
    destination = some(placementFor(aim.get, scene, picked, staged, camera, width, height))
  tween.aimAt(
    camera, aim.get, destination.get, now, duration, anchor_held = anchor,
    is_renewed = pick.isSome,
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
  offerAim(
    tween, camera, alone, Selection(), some(previewStaging(m, RADIUS_ITEM_DEFAULT)),
    camera.drawExtentFor(height), width, height, now, duration, pointer,
  )
