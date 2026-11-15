## Comparison mockup: options of one open decision, and scenarios that set view up where they
## part, carried by page built with `-d:mockup` alone (`tools/build.nim mockup`).
##   Architect switches option, sets scenario up, does its steps, and rules on feel and figures
##   before chosen option is built for real. README, Comparison mockups, says how to write next.
##   Included by `bridge.nim`, so it reads page's own camera, scene and overlay, and page shipped
##   carries none of it. Bridge calls hooks below where options part from `main`.
##   Panel is `pages/mockup.html`: it reads `nimMockupSpec`, sets up, and measures.
##
##   Comparison now: what depth free flight's right drag holds where it begins over empty sky.

{.experimental: "strictFuncs".}

import std/[json, math]
import ../pga_visualiser/mesh

proc stampBorn(handle: int, born: float)  ## Defined in `bridge.nim`, below this include.



#[ Comparison ]#

type
  MeasureMockup {.pure.} = enum  ## Define what panel reads off scenario's steps.
    Pan = "pan"  ## Focus's travel on screen against pointer's, along drag.

  ScenarioMockup = object  ## Define one set-up where options part, and what reader does there.
    name: string  ## Name panel lists it by.
    steps: seq[string]  ## What reader does, in order.
    watch: string  ## What reader compares between options.
    measure: MeasureMockup  ## What panel reads off steps.
    drag: tuple[across, down: float]  ## Drag from each target, as share of frame; zero for none.

const
  TITLE_MOCKUP = "Pan Over Sky"  ## Name of comparison; build adds " Mockup" for page title.
  QUESTION_MOCKUP = "D1 of issue 910: what depth should a pan hold, where it begins over " &
    "empty sky with nothing selected?"
  OPTIONS_MOCKUP = [
    ("a", "Pivot's depth", "A pan over empty sky holds a point at the depth of the pivot. Key " &
      "flight carries the pivot along. Main does this."),
    ("b", "Reach taken", "A pan over empty sky holds a point at the reach of the point that " &
      "the last zoom took, as the zoom out and the pinch do."),
    ("c", "Local scale", "A pan over empty sky holds a point at the reach of the nearest " &
      "drawn object ahead, in view or not."),
    ("d", "Nothing moves", "A pan over empty sky moves nothing, as the wheel over empty sky " &
      "does nothing."),
  ]
  DRAG_MOCKUP = "Right-drag from the diamond along its chevrons, to their end."
  RIGHT_MOCKUP = (across: 0.25, down: 0.0)  ## Drag right by quarter of frame.
  SCENARIOS_MOCKUP = [
    ScenarioMockup(name: "At home", steps: @[
      "The view stands at home, on the small system. The diamond stands on empty sky.",
      DRAG_MOCKUP,
    ], watch: "Does the system move with the pointer?", measure: MeasureMockup.Pan,
      drag: RIGHT_MOCKUP),
    ScenarioMockup(name: "After a key flight", steps: @[
      "The eye stands where a held S leaves it, ten home distances behind home. The pivot " &
        "rode along with it.",
      DRAG_MOCKUP,
    ], watch: "Does the system keep up with the pointer?", measure: MeasureMockup.Pan,
      drag: RIGHT_MOCKUP),
    ScenarioMockup(name: "Far out", steps: @[
      "The eye stands a hundred home distances behind home. A star stands beside the eye, " &
        "out of view.",
      DRAG_MOCKUP,
    ], watch: "Does the system keep up with the pointer?", measure: MeasureMockup.Pan,
      drag: RIGHT_MOCKUP),
    ScenarioMockup(name: "In to a planet", steps: @[
      "The wheel took the eye twelve notches in to planet 1, in the middle.",
      DRAG_MOCKUP,
    ], watch: "Does planet 1 move with the pointer?", measure: MeasureMockup.Pan,
      drag: RIGHT_MOCKUP),
    ScenarioMockup(name: "In, then back", steps: @[
      "The wheel took the eye twelve notches in to planet 1. Then a held S carried the eye " &
        "back ten times as far.",
      DRAG_MOCKUP,
    ], watch: "Does planet 1 keep up with the pointer?", measure: MeasureMockup.Pan,
      drag: RIGHT_MOCKUP),
  ]
  HOW_MOCKUP = [
    "Pick a scenario and an option, then press Set up.",
    "Do the steps. The panel shows how far the focus moved for each pixel the pointer did.",
    "Press Set up again with the next option. The table keeps the last result of each.",
    "Compare how each option feels, as well as its figures.",
  ]

var
  OPTION_MOCKUP = "a"  ## Key of option reader picked.
  FOCUS_MOCKUP = POSITION_ORRERY  ## World point scenario asks reader to watch.
  FRAME_MOCKUP = (width: 0, height: 0)  ## Canvas frame last set-up read, in CSS pixels.



#[ Hooks ]#

proc grabPanMockup() =
  ## Hold depth option reads, where right drag begins over nothing in free flight.
  ##   Option `a` leaves what `interaction.grabPan` took: pivot's depth.
  if SELECTION_PAGE.len > 0 or INTERACTION_PAGE.depth_pointer.isSome: return
  case OPTION_MOCKUP
  of "b": INTERACTION_PAGE.depth_pan = CAMERA_PAGE.reachTaken
  of "c": INTERACTION_PAGE.depth_pan = CAMERA_PAGE.scaleLocal
  of "d": INTERACTION_PAGE.depth_pan = 0.0
  else: discard



#[ Scenes ]#

const
  RINGS_MOCKUP = [1.0, 2.0, 5.0, 9.0]  ## Radius of each planet's ring about sun, in world units.
  RADIUS_SUN_MOCKUP = 0.00465  ## Sun's drawn radius: Sol's own, in world units.
  RADIUS_PLANET_MOCKUP = 4.3e-5  ## Planet's drawn radius: Earth's own, in world units.
  DEPTH_SKY = 4.0e6  ## Depth of stars filling sky, deeper than any scenario carries eye.
  DEPTH_BESIDE = 30.0  ## Depth along sight of star beside eye.
  ACROSS_BESIDE = 4.0e5  ## How far right of eye star beside eye stands, out of view.
  NOTCHES_IN = 12  ## Notches wheel took eye in to planet 1.
  CLEAR_SKY = 160.0  ## Pixels sky keeps clear of each target, past reach of pointer.
  CLEAR_OBJECT = 90.0  ## Pixels target keeps clear of each object of system.


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


proc addSystemMockup(): seq[Position] =
  ## Add small system standing in for Sol's, sun and four planets ringing it, and report places.
  ##   No line and no plane: either spans sky, where pan here must begin over nothing.
  let sun = POSITION_ORRERY
  addPointMockup(sun, "Sol", Role.Sun, RADIUS_SUN_MOCKUP)
  result.add sun
  for index, ring in RINGS_MOCKUP:
    let
      angle = 0.6 + 2.4 * float(index)
      place = Position(x: sun.x + ring * cos(angle), y: sun.y + ring * sin(angle), z: sun.z)
    addPointMockup(place, "planet " & $(index + 1), Role.Planet, RADIUS_PLANET_MOCKUP)
    result.add place


proc screenMockup(width, height: int; place: Position): Option[ScreenPosition] =
  ## Find pixel world `place` stands on, where it stands ahead of eye.
  let seen = projectToScreen(CAMERA_PAGE.initMatrixViewProjection(float(width) / float(height)),
    width, height, place.toView(CAMERA_PAGE.originView))
  if seen.isInFront: some(ScreenPosition(x: seen.x, y: seen.y)) else: none(ScreenPosition)


proc pixelClear(width, height: int; places: openArray[Position]): Option[ScreenPosition] =
  ## Find pixel clear of each place shown, for drag to begin on.
  ##   Middle of frame, right of panel, which stands at left; drag runs right from it.
  for (across, down) in [(0.5, 0.82), (0.5, 0.18), (0.42, 0.86), (0.58, 0.14), (0.45, 0.66),
      (0.45, 0.34)]:
    let pixel = ScreenPosition(x: across * float(width), y: down * float(height))
    var is_clear = true
    for place in places:
      let seen = screenMockup(width, height, place)
      if seen.isSome and hypot(seen.get.x - pixel.x, seen.get.y - pixel.y) < CLEAR_OBJECT:
        is_clear = false
    if is_clear: return some(pixel)


proc addSkyMockup(width, height: int; rings: openArray[ScreenPosition]) =
  ## Add stars filling sky behind scene, each kept clear of every target.
  let (eye, frame) = CAMERA_PAGE.sight
  for row in 0..3:
    for column in 0..4:
      let pixel = ScreenPosition(
        x: float(width) * (0.1 + 0.2 * float(column)) + 17.0 * float(row),
        y: float(height) * (0.125 + 0.25 * float(row)),
      )
      var is_clear = true
      for ring in rings:
        if hypot(ring.x - pixel.x, ring.y - pixel.y) < CLEAR_SKY: is_clear = false
      if not is_clear: continue
      let heading = CAMERA_PAGE.headingThrough(frame, width, height, pixel)
      addPointMockup(pointOnRay(eye, heading, DEPTH_SKY).toWorld(CAMERA_PAGE.originView), "star",
        Role.Sun, RADIUS_OBJECT_LEAST)


proc standIn(home: Camera; planet: Position) =
  ## Stand eye where twelve notches in to `planet` from home leave it, facing it.
  ##   Placed facing planet, so pivot and point last zoom took stand on it, as zoom leaves them.
  let
    eye = home.eye.toWorld(home.originView)
    share = pow(FACTOR_DOLLY_NOTCH, -float(NOTCHES_IN))
  CAMERA_PAGE = CAMERA_PAGE.placed(stanceFacing(Position(
    x: planet.x + share * (eye.x - planet.x),
    y: planet.y + share * (eye.y - planet.y),
    z: planet.z + share * (eye.z - planet.z),
  ), planet))


proc sceneMockup(index, width, height: int): seq[ScreenPosition] =
  ## Build scene of scenario `index`, stand camera in it, and report pixel to begin drag on.
  ##   Scene holds only what its case needs: small system, sky, and star where option
  ##   misreads scale.
  TWEEN_CAMERA.abandon()
  SCENE_PAGE.restoreFrom initScene()
  let
    places = addSystemMockup()
    home = initCameraDefault(width, height)
  CAMERA_PAGE = CAMERA_PAGE.placed(home.stance)
  FOCUS_MOCKUP = places[0]
  case index
  of 0: discard
  of 1:
    # Held `s` carries pivot along; point last zoom took stays on home's pivot.
    CAMERA_PAGE.travel(-10.0 * home.distance, 0.0, 0.0)
  of 2:
    CAMERA_PAGE.travel(-100.0 * home.distance, 0.0, 0.0)
    let (eye, frame) = CAMERA_PAGE.sight
    addPointMockup(offSight(eye, frame, DEPTH_BESIDE, ACROSS_BESIDE).toWorld(
      CAMERA_PAGE.originView), "star beside eye", Role.Sun, RADIUS_OBJECT_LEAST)
  of 3, 4:
    FOCUS_MOCKUP = places[1]
    home.standIn(FOCUS_MOCKUP)
    if index == 4: CAMERA_PAGE.travel(-10.0 * CAMERA_PAGE.distance, 0.0, 0.0)
  else: discard
  let start = pixelClear(width, height, places)
  if start.isSome: result.add start.get
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
  ## Pick option by its key; next drag reads it as it begins.
  OPTION_MOCKUP = $key


proc nimMockupSetUp(index, width, height: cint): cstring {.exportc.} =
  ## Build scenario `index`'s scene, and report pixel to begin on, drag from it, and home's
  ## distance, as JSON.
  ##   `width` x `height` is canvas's frame in CSS pixels, as pointer reports cursor.
  FRAME_MOCKUP = (width: int(width), height: int(height))
  let targets = sceneMockup(int(index), int(width), int(height))
  if targets.len == 0:
    return cstring($ %*{"error":
      "No clear sky for this scenario on this frame. Resize, and set up again."})
  let drag = SCENARIOS_MOCKUP[int(index)].drag
  var pixels, drags = newJArray()
  for target in targets:
    pixels.add %*[target.x, target.y]
    drags.add %*[drag.across * float(width), drag.down * float(height)]
  cstring($ %*{"targets": pixels, "drags": drags,
    "home": initCameraDefault(int(width), int(height)).distance})


proc nimMockupReadout(): cstring {.exportc.} =
  ## Report what panel measures, as JSON: eye's distance to Sol, distance to pivot, local
  ## scale, distance to point last zoom took, and pixel focus stands on, or empty for none.
  let
    eye = CAMERA_PAGE.eye.toWorld(CAMERA_PAGE.originView)
    seen = screenMockup(FRAME_MOCKUP.width, FRAME_MOCKUP.height, FOCUS_MOCKUP)
  var focus = newJArray()
  if seen.isSome and FRAME_MOCKUP.width > 0:
    focus.add %seen.get.x
    focus.add %seen.get.y
  cstring($ %*{"sol": norm(eye - POSITION_ORRERY), "pivot": CAMERA_PAGE.distance,
    "scale": CAMERA_PAGE.scaleLocal, "taken": CAMERA_PAGE.reachTaken, "focus": focus,
    "option": OPTION_MOCKUP})
