## Comparison mockup: options of one open decision, and scenarios that set view up where they
## part, carried by page built with `-d:mockup` alone (`tools/build.nim mockup`).
##   Architect switches option, sets scenario up, does its steps, and rules on feel and figures
##   before chosen option is built for real. README, Comparison mockups, says how to write next.
##   Included by `bridge.nim`, so it reads page's own camera, scene and overlay, and page shipped
##   carries none of it. Bridge calls hooks below where options part from `main`.
##   Panel is `pages/mockup.html`: it reads `nimMockupSpec`, sets up, and measures.
##
##   Comparison now: D1 of repository issue 846, what free flight's zoom out takes as anchor
##   where object under pointer stands far past distance to pivot.

{.experimental: "strictFuncs".}

import std/[json, math]
import ../pga_visualiser/mesh

proc stampBorn(handle: int, born: float)  ## Defined in `bridge.nim`, below this include.

template placedMockup(): untyped = PLACEMENTS_FRAME[INDEX_FRAME]
  ## Placements of frame, as template `placements` of bridge reads them, which stands below.



#[ Comparison ]#

type
  MeasureMockup {.pure.} = enum  ## Define what panel reads off scenario's steps.
    Wheel = "wheel"  ## Eye's distance to Sol against what notches ask.
    Trip = "trip"  ## Eye's distance from where set-up stood it, in home distances.
    Pinch = "pinch"  ## Eye's distance to Sol against what fingers ask.

  ScenarioMockup = object  ## Define one set-up where options part, and what reader does there.
    name: string  ## Name panel lists it by.
    steps: seq[string]  ## What reader does, in order.
    watch: string  ## What reader compares between options.
    measure: MeasureMockup  ## What panel reads off steps.

const
  TITLE_MOCKUP = "Zoom-Out Rule"  ## Name of comparison; build adds " Mockup" for page title.
  QUESTION_MOCKUP = "D1 of issue 846: what should a zoom out take as its anchor, where the " &
    "object under the pointer stands far past the distance to the pivot?"
  OPTIONS_MOCKUP = [
    ("a", "Any depth", "A zoom out takes the object under the pointer, at any depth. Main " &
      "does this."),
    ("b", "Hold pivot distance", "Past twice the distance to the pivot, a zoom out holds " &
      "that distance on the pointer's ray. Key flight carries the pivot along."),
    ("d", "Local scale", "As b, with the pivot first moved to the reach of the nearest " &
      "drawn object ahead."),
    ("e", "Pivot stays put", "As b, with the pivot left on what the last zoom took. Key " &
      "flight leaves it there."),
  ]
  SCENARIOS_MOCKUP = [
    ScenarioMockup(name: "Far star at home", steps: @[
      "A far star stands under the ring, far behind the small system.",
      "Put the pointer in the ring, and scroll out one notch.",
    ], watch: "Does the small system shrink a little, or does the eye leave it?",
      measure: MeasureMockup.Wheel),
    ScenarioMockup(name: "After a key flight", steps: @[
      "The eye stands where a held S leaves it, ten home distances behind home. The pivot " &
        "rode along with it.",
      "Put the pointer in the ring, on Sol.",
      "Scroll out three notches.",
    ], watch: "Does the small system shrink as fast as three notches shrink it at home?",
      measure: MeasureMockup.Wheel),
    ScenarioMockup(name: "Far out", steps: @[
      "The eye stands a hundred home distances out. A far star stands under the ring.",
      "A star stands beside the eye, out of view.",
      "Put the pointer in the ring, and scroll out three notches.",
    ], watch: "Does each notch carry the eye out by about the same share?",
      measure: MeasureMockup.Wheel),
    ScenarioMockup(name: "Round trip", steps: @[
      "A far star stands under the ring. A star stands off its line, out of view.",
      "Put the pointer in the ring.",
      "Scroll in three notches, then out three notches.",
    ], watch: "Does the view come back to where it started?", measure: MeasureMockup.Trip),
    ScenarioMockup(name: "Pinch on a phone", steps: @[
      "A far star stands under each ring.",
      "Put two fingers on the rings, and pinch in until the gap is about half.",
    ], watch: "Does the small system shrink a little, or does the eye leave it?",
      measure: MeasureMockup.Pinch),
  ]
  HOW_MOCKUP = [
    "Pick a scenario and an option, then press Set up.",
    "Do the steps. The panel shows what they asked, and what the eye did.",
    "Press Set up again with the next option. The table keeps the last result of each.",
    "Compare how each option feels, as well as its figures.",
  ]

var
  OPTION_MOCKUP = "a"  ## Key of option reader picked.
  POINT_TAKEN_MOCKUP = none(Position)  ## World point last free-flight zoom took.
  IS_RETAKEN_MOCKUP = false  ## Whether pinch capped its places as fingers first closed.
  EYE_SET_UP_MOCKUP = none(Position)  ## World eye where last scenario stood it.



#[ Hooks ]#

proc forgetMockup() =
  ## Forget point last zoom took, as `home` and new scene do; next frame takes pivot.
  POINT_TAKEN_MOCKUP = none(Position)


proc frameMockup() =
  ## Take pivot as it stands, each frame, with selection or with no point taken.
  if SELECTION_PAGE.len > 0 or POINT_TAKEN_MOCKUP.isNone:
    POINT_TAKEN_MOCKUP = some(CAMERA_PAGE.pivot.toWorld(CAMERA_PAGE.originView))


proc repivotMockup(camera: var Camera) =
  ## Move pivot to depth option reads, before free flight zooms.
  ##   Option `d` reads reach to nearest drawn object ahead; `e`, distance to point last zoom
  ##   took.
  case OPTION_MOCKUP
  of "d": camera.repivotToDepth(camera.scaleLocal)
  of "e":
    if POINT_TAKEN_MOCKUP.isSome:
      camera.repivotToDepth(norm(camera.eye.toWorld(camera.originView) - POINT_TAKEN_MOCKUP.get))
  else: discard


func heldOnRay(eye, place: Position; forward: Direction; depth: float): Position =
  ## Read point on eye's ray through `place`, at `depth` along sight.
  let along = depth / depthAlong(eye, forward, place)
  Position(
    x: eye.x + along * (place.x - eye.x),
    y: eye.y + along * (place.y - eye.y),
    z: eye.z + along * (place.z - eye.z),
  )


proc dollyAtMockup(factor: float; width, height: int): bool =
  ## Zoom free flight by `factor` toward what cursor is over, under option picked.
  ##   False with selection, whose dolly stays `main`'s. Option `a` is `interaction.dollyAt`.
  ##   Options `b`, `d` and `e` hold pivot's depth on pointer's ray past twice it.
  if SELECTION_PAGE.len > 0: return false
  let anchor = anchorZoomAt(SCENE_PAGE, CAMERA_PAGE, SCALE_OVERLAY, VIEW_PROJECTION_OVERLAY,
    width, height, INTERACTION_PAGE.cursor, placedMockup, is_banded = false)
  if anchor.isNone: return true
  CAMERA_PAGE.repivotMockup()
  var
    at = anchor.get.at
    floor = anchor.get.floor_reach
  let (eye, frame) = CAMERA_PAGE.sight
  if OPTION_MOCKUP != "a" and factor > 1.0 and
      depthAlong(eye, frame.forward, at) > FACTOR_ANCHOR_DEPTH * CAMERA_PAGE.distance:
    at = heldOnRay(eye, at, frame.forward, CAMERA_PAGE.distance)
    floor = 0.0
  let taken = at.toWorld(CAMERA_PAGE.originView)
  CAMERA_PAGE.travelToward(factor, at, floor)
  let
    (eye_after, frame_after) = CAMERA_PAGE.sight
    depth = depthAlong(eye_after, frame_after.forward, at)
  if depth > 0.0: CAMERA_PAGE.repivotToDepth(depth)
  POINT_TAKEN_MOCKUP = some(taken)
  true


proc beginGripMockup() =
  ## Move pivot where option reads it, in free flight, before pinch takes its places.
  IS_RETAKEN_MOCKUP = false
  if SELECTION_PAGE.len == 0: CAMERA_PAGE.repivotMockup()


proc retakeMockup(grip: var GripFingers; fingers: array[2, ScreenPosition]) =
  ## Hold places past twice pivot's depth at it, as fingers first close past slop.
  ##   Pinch takes places as second finger lands, before it knows its direction.
  if grip.is_orbit or OPTION_MOCKUP == "a" or IS_RETAKEN_MOCKUP: return
  let
    gap_landed = hypot(grip.landed[1].x - grip.landed[0].x, grip.landed[1].y - grip.landed[0].y)
    gap = hypot(fingers[1].x - fingers[0].x, fingers[1].y - fingers[0].y)
  if abs(gap - gap_landed) <= PIXELS_TAP_SLOP: return
  IS_RETAKEN_MOCKUP = true
  if gap >= gap_landed: return
  let
    (eye, frame) = grip.stance.sight
    cap = grip.stance.distance
    origin = grip.stance.originView
  var reaches = 0.0
  for finger in grip.fingers.mitems:
    var held = finger.place.toView(origin)
    if depthAlong(eye, frame.forward, held) > FACTOR_ANCHOR_DEPTH * cap:
      held = heldOnRay(eye, held, frame.forward, cap)
      finger.floor = 0.0
    finger.place = held.toWorld(origin)
    reaches += norm(held - eye)
  let reach = 0.5 * reaches
  if reach <= 0.0 or grip.reach <= 0.0: return
  # Slide already solved is in units of reach, so it stays where it stood.
  for unknown in 0..2: grip.solution[unknown] *= grip.reach / reach
  grip.reach = reach


proc takeGripMockup(grip: GripFingers) =
  ## Note nearer place pinch holds, once fingers zoom, as point last zoom took.
  if grip.is_orbit or grip.gap_from.isNone: return
  let (eye, frame) = CAMERA_PAGE.sight
  var least = Inf
  for finger in grip.fingers:
    let depth = depthAlong(eye, frame.forward, finger.place.toView(CAMERA_PAGE.originView))
    if depth < least:
      least = depth
      POINT_TAKEN_MOCKUP = some(finger.place)



#[ Scenes ]#

const
  RINGS_MOCKUP = [1.0, 2.0, 5.0, 9.0]  ## Radius of each planet's ring about sun, in world units.
  RADIUS_SUN_MOCKUP = 0.00465  ## Sun's drawn radius: Sol's own, in world units.
  RADIUS_PLANET_MOCKUP = 4.3e-5  ## Planet's drawn radius: Earth's own, in world units.
  DEPTH_STAR_FAR = 2.0e6  ## Depth far star stands at, as deep as demo's own stars.
  DEPTH_SKY = 4.0e6  ## Depth of stars filling sky, deeper than any scenario carries eye.
  DEPTH_BESIDE = 30.0  ## Depth along sight of star beside eye.
  ACROSS_BESIDE = 4.0e5  ## How far right of eye star beside eye stands, out of view.
  DEPTH_ASIDE = 3.0e5  ## Depth along sight of star off far star's line, once eye came in.
  ACROSS_ASIDE = 4.0e5  ## How far right of sight that star stands then, out of view.
  CLEAR_SKY = 160.0  ## Pixels sky keeps clear of each ring, past reach of finger.


func pointOnRay(eye: Position; heading: Direction; depth: float): Position =
  ## Read point `depth` along sight on ray of `heading`, as `headingThrough` scales it.
  Position(x: eye.x + depth * heading.x, y: eye.y + depth * heading.y,
    z: eye.z + depth * heading.z)


func offSight(from_eye: Position; frame: FrameCamera; depth, across: float): Position =
  ## Read point `depth` ahead of `from_eye` along sight, and `across` to its right.
  Position(
    x: from_eye.x + depth * frame.forward.x + across * frame.axis_right.x,
    y: from_eye.y + depth * frame.forward.y + across * frame.axis_right.y,
    z: from_eye.z + depth * frame.forward.z + across * frame.axis_right.z,
  )


proc addPointMockup(place: Position; label: string; role: Role; radius: float) =
  ## Add point at world `place` to page's scene, born at dawn of time, so not animated in.
  SCENE_PAGE.addObject(place.toMultivector, label, LUT_INK_BY_ROLE[role], radius = radius)


proc addSystemMockup() =
  ## Add small system standing in for Sol's: sun, four planets ringing it in ecliptic, line
  ## through sun and first planet, and ecliptic plane.
  ##   Line stands in for Sol's line in demo, read from its point nearest pivot.
  let sun = POSITION_ORRERY
  addPointMockup(sun, "Sol", Role.Sun, RADIUS_SUN_MOCKUP)
  var planets: seq[Multivector]
  for index, ring in RINGS_MOCKUP:
    let
      angle = 0.6 + 2.4 * float(index)
      place = Position(x: sun.x + ring * cos(angle), y: sun.y + ring * sin(angle), z: sun.z)
    addPointMockup(place, "planet " & $(index + 1), Role.Planet, RADIUS_PLANET_MOCKUP)
    planets.add place.toMultivector
  let sun_point = sun.toMultivector
  SCENE_PAGE.addObject(sun_point ∧ planets[0], "Sol ∧ planet 1", LUT_INK_BY_ROLE[Role.Derived])
  SCENE_PAGE.addObject(sun_point ∧ planets[0] ∧ planets[1], "ecliptic",
    LUT_INK_BY_ROLE[Role.Derived], anchor_override = some(sun))


proc addStarUnder(width, height: int; pixel: ScreenPosition; depth: float; label: string) =
  ## Add star at `depth` along sight under `pixel`, as camera stands.
  let
    (eye, frame) = CAMERA_PAGE.sight
    heading = CAMERA_PAGE.headingThrough(frame, width, height, pixel)
  addPointMockup(pointOnRay(eye, heading, depth).toWorld(CAMERA_PAGE.originView), label,
    Role.Sun, RADIUS_OBJECT_LEAST)


proc addSkyMockup(width, height: int; rings: openArray[ScreenPosition]) =
  ## Add stars filling sky behind scene, each kept clear of every ring.
  for row in 0..3:
    for column in 0..4:
      let pixel = ScreenPosition(
        x: float(width) * (0.1 + 0.2 * float(column)) + 17.0 * float(row),
        y: float(height) * (0.125 + 0.25 * float(row)),
      )
      var is_clear = true
      for ring in rings:
        if hypot(ring.x - pixel.x, ring.y - pixel.y) < CLEAR_SKY: is_clear = false
      if is_clear: addStarUnder(width, height, pixel, DEPTH_SKY, "star")


proc addBesideMockup() =
  ## Add star beside eye, out of view, nearer along sight than anything in view.
  let (eye, frame) = CAMERA_PAGE.sight
  addPointMockup(offSight(eye, frame, DEPTH_BESIDE, ACROSS_BESIDE).toWorld(CAMERA_PAGE.originView),
    "star beside eye", Role.Sun, RADIUS_OBJECT_LEAST)


proc addAsideMockup(width, height: int; pixel: ScreenPosition) =
  ## Add star off line to far star under `pixel`, out of view, standing nearer along sight
  ## than half that star's depth once three notches have carried eye toward it.
  let
    (eye, frame) = CAMERA_PAGE.sight
    star = pointOnRay(eye, CAMERA_PAGE.headingThrough(frame, width, height, pixel),
      DEPTH_STAR_FAR)
    share = 1.0 - pow(FACTOR_DOLLY_NOTCH, -3.0)
    come = Position(x: eye.x + share * (star.x - eye.x), y: eye.y + share * (star.y - eye.y),
      z: eye.z + share * (star.z - eye.z))
  addPointMockup(offSight(come, frame, DEPTH_ASIDE, ACROSS_ASIDE).toWorld(CAMERA_PAGE.originView),
    "star aside", Role.Sun, RADIUS_OBJECT_LEAST)


proc standFarOut(home: Camera) =
  ## Stand camera hundred home distances out from home's pivot, still facing it.
  let
    pivot = home.pivot.toWorld(home.originView)
    eye = home.eye.toWorld(home.originView)
  CAMERA_PAGE = CAMERA_PAGE.placed(stanceFacing(Position(
    x: pivot.x + 100.0 * (eye.x - pivot.x),
    y: pivot.y + 100.0 * (eye.y - pivot.y),
    z: pivot.z + 100.0 * (eye.z - pivot.z),
  ), pivot))


proc pixelSun(width, height: int): seq[ScreenPosition] =
  ## Find pixel sun stands on, where it stands ahead of eye.
  let seen = projectToScreen(CAMERA_PAGE.initMatrixViewProjection(float(width) / float(height)),
    width, height, POSITION_ORRERY.toView(CAMERA_PAGE.originView))
  if seen.isInFront: result.add ScreenPosition(x: seen.x, y: seen.y)


proc sceneMockup(index, width, height: int): seq[ScreenPosition] =
  ## Build scene of scenario `index`, stand camera in it, and report pixels to aim at.
  ##   Scene holds only what its case needs: small system, stars steps aim at, and star
  ##   where option misreads scale.
  TWEEN_CAMERA.abandon()
  SCENE_PAGE.restoreFrom initScene()
  addSystemMockup()
  let
    home = initCameraDefault(width, height)
    top = ScreenPosition(x: 0.5 * float(width), y: 0.25 * float(height))
  CAMERA_PAGE = CAMERA_PAGE.placed(home.stance)
  POINT_TAKEN_MOCKUP = some(CAMERA_PAGE.pivot.toWorld(CAMERA_PAGE.originView))
  case index
  of 0:
    addStarUnder(width, height, top, DEPTH_STAR_FAR, "far star")
    result.add top
  of 1:
    # Held `s` carries pivot along; point last zoom took stays on home's pivot.
    CAMERA_PAGE.travel(-10.0 * home.distance, 0.0, 0.0)
    result = pixelSun(width, height)
  of 2:
    standFarOut(home)
    addStarUnder(width, height, top, DEPTH_STAR_FAR, "far star")
    addBesideMockup()
    result.add top
  of 3:
    addStarUnder(width, height, top, DEPTH_STAR_FAR, "far star")
    addAsideMockup(width, height, top)
    result.add top
  of 4:
    let half = min(80.0, 0.25 * float(width))
    for across in [-half, half]:
      let finger = ScreenPosition(x: 0.5 * float(width) + across, y: 0.2 * float(height))
      addStarUnder(width, height, finger, DEPTH_STAR_FAR, "far star")
      result.add finger
  else: discard
  addSkyMockup(width, height, result)
  for handle in 0..<SCENE_PAGE.len: stampBorn(handle, SCENE_PAGE.bornAt(handle))
  SELECTION_PAGE.clear()
  HISTORY_PAGE.initHistory(SCENE_PAGE, CAMERA_PAGE)



#[ Panel ]#

proc nimMockupSpec(): cstring {.exportc.} =
  ## Describe comparison to panel, as JSON: question, options, scenarios, how to compare.
  var options = newJArray()
  for (key, name, text) in OPTIONS_MOCKUP:
    options.add %*{"key": key, "name": name, "text": text}
  var scenarios = newJArray()
  for scenario in SCENARIOS_MOCKUP:
    scenarios.add %*{"name": scenario.name, "steps": scenario.steps, "watch": scenario.watch,
      "measure": $scenario.measure}
  cstring($ %*{"title": TITLE_MOCKUP, "question": QUESTION_MOCKUP, "how": HOW_MOCKUP,
    "options": options, "scenarios": scenarios, "factor_notch": FACTOR_DOLLY_NOTCH})


proc nimMockupSetOption(key: cstring) {.exportc.} =
  ## Pick option by its key. Point last zoom took stands, so set-up need not run again.
  OPTION_MOCKUP = $key


proc nimMockupSetUp(index, width, height: cint): cstring {.exportc.} =
  ## Build scenario `index`'s scene, and report pixels to aim at and home's distance, as JSON.
  ##   `width` x `height` is canvas's frame in CSS pixels, as pointer reports cursor.
  let targets = sceneMockup(int(index), int(width), int(height))
  EYE_SET_UP_MOCKUP = some(CAMERA_PAGE.eye.toWorld(CAMERA_PAGE.originView))
  if targets.len == 0:
    return cstring($ %*{"error":
      "No spot for this scenario on this frame. Resize, and set up again."})
  var pixels = newJArray()
  for target in targets: pixels.add %*[target.x, target.y]
  cstring($ %*{"targets": pixels, "home": initCameraDefault(int(width), int(height)).distance})


proc nimMockupReadout(): cstring {.exportc.} =
  ## Report what panel measures, as JSON: eye's distance to Sol and from set-up's eye,
  ## distance to pivot, local scale, and distance to point last zoom took, or -1 for none.
  let
    eye = CAMERA_PAGE.eye.toWorld(CAMERA_PAGE.originView)
    from_set_up = (if EYE_SET_UP_MOCKUP.isSome: norm(eye - EYE_SET_UP_MOCKUP.get) else: -1.0)
    taken = (if POINT_TAKEN_MOCKUP.isSome: norm(eye - POINT_TAKEN_MOCKUP.get) else: -1.0)
  cstring($ %*{"sol": norm(eye - POSITION_ORRERY), "from_set_up": from_set_up,
    "pivot": CAMERA_PAGE.distance, "scale": CAMERA_PAGE.scaleLocal, "taken": taken,
    "option": OPTION_MOCKUP})
