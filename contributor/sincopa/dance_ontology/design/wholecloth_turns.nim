## Animate whole-cloth page's turns panel from body simulation's sweeps.
##
##   Port of script hand-written inside `wholecloth.html`, kept byte for byte in
##     what it draws: page's markup is now hosted in Nim (`wholecloth_page`), so
##     its one program is too, compiled with `nim js` and spliced back in by
##     `wholecloth`.  Page only draws; every pose is one simulation found natively.
##   Data stays where it is: `TURNS` (800 KB, spliced in before this script as
##     global) is read in place as `JsObject` through `std/jsffi`, never copied
##     into Nim objects, since every copy on JS backend is deep (STYLE.md §7).
##     Only scene at one moment is built as Nim value, interpolated afresh.
##   Holds and levels are closed domains (six by three), so both are enums and
##     every table over them is enum-indexed array (Article IV.6): sweep limits
##     and frame references are read once at load into `LUT_SWEEP_BY_HOLD`, which
##     replaces original's lazy string-keyed cache.
##     Cost: eighteen reads at load instead of on demand; negligible.
##     Rig's dozen measures are read in place per call instead, as original
##       did: run-time `let` counts as global state under `strictFuncs`, and
##       drawing stays `func`.
##   Numbers become text exactly as JavaScript made them: `toFixed` and `String`
##     are bound from JS (`$float` would write `2.0` where page wrote `2`), and
##     `Math.round` becomes `floor(x + 0.5)`, since JS rounds halves toward
##     +infinity where Nim's `round` goes away from zero.
##   Strings are `cstring` throughout: JS strings joined by `+`, never Nim
##     `string` (byte array decoded per frame).
##   Dropped from original: dead line computing `f[1]` on number in
##     `shoulderOf` (always `undefined`, overwritten at once); `sceneSvg`'s
##     unused fallback scene (both callers pass one); `markSvg`'s separate
##     `fill`/`faded` arguments, always derived from one boolean at both call
##     sites (IV.7: both enumerated), now one `is_held`.
##   Kept as hand-drawn, trap noted: `above` fill hatches with left-ink pattern
##     for either arm (`aLd`/`aL`), since parity beats correction here.
##   Cost read (Article VII.1): `grep -c nimCopy` on emitted JS (`nim js
##     -d:release`, 2026-09-05) gives 13, every one runtime's own (its
##     definition, exception messages, one `$` helper); none from this module.
##     Read call sites of each binding shape: by-value `Scene` parameter passes
##     by reference; `template` aliases into `scene.cn[i]` and
##     `lut_hold_sweep[hold][level]` read fields inline; `let` of call result
##     binds without copy; `var` out-parameters (`interpolate`, `sceneOf`,
##     `readSweep`) write into storage in place.  Shapes rejected after reading
##     them: `result = [x, y]` and constructor assigned to `result` (one deep
##     copy each), `Option[Scene]` (two per call), `for (px, py) in` over tuple
##     table (one per element per call), `Option[float]` clock (two per frame).

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/[dom, jsffi, math]



#[ Domain ]#

type
  Arm {.pure.} = enum  ## Define which arm of dancer.
    Left, Right

  Dancer {.pure.} = enum
    ## Define who: lead (square marks, deep ink) or follow (round marks, plain ink).
    Lead, Follow

  Hold {.pure.} = enum  ## Define six holds page offers, lead's hand named first.
    LeftToLeft, RightToRight, LeftToRight, RightToLeft, LeftToLeftRightToRight,
    LeftToRightRightToLeft

  Level {.pure.} = enum  ## Define three heights hands are held at.
    Low, High, Above

  Part {.pure.} = enum  ## Define body parts drawn in side view, hip upward.
    Torso, Neck, Head

  View {.pure.} = enum
    ## Define projections: from above onto page, and from side along couple's line.
    Above, Side

  Rope = tuple[lead, follow: Arm]  ## Define one connection: lead's arm to follow's arm.

  HoldDescription = object
    ## Define one hold: key in data, name on button, ropes, rest turn and its words.
    key: cstring  ## Key of sweep in `TURNS.sweeps`, before `|level`.
    name: cstring
    from_rest: cstring  ## Where turns count from, for readout.
    ropes: array[2, Rope]
    rope_count: int  ## Live bound of `ropes`.
    rest: float  ## Turn at which nothing is wound.
    is_pair: bool  ## Two ropes, so readout names each.

  Limits = object  ## Define where one sweep runs out each way, and why.
    negative, positive: float  ## Turns reached each way, at most `MOST`.
    why_negative, why_positive: cstring  ## What refused, each way.
    is_stopped_negative, is_stopped_positive: bool  ## Blocked within `MOST`, not merely ended.
    found_rest: bool  ## Whether rest pose exists at all.

  Sweep = object
    ## Define one sweep as page reads it: limits, and moments as reference into `TURNS`.
    limits: Limits
    frames: JsObject

  Vector2 = array[2, float]  ## Define point on page, or centre in millimetres.

  Vector3 = array[3, float]  ## Define joint in millimetres: across, along, up.

  PartExtent = object  ## Define one body part's half-extents and height band, in millimetres.
    across, deep, z_from, z_to: float

  BodyPose = object  ## Define where one dancer stands and faces at one moment.
    centre: Vector2
    facing: float

  Connection = object
    ## Define one rope at one moment: four joints each side, and simulation's words.
    lead, follow: array[4, Vector3]
    lead_says, follow_says: cstring
    cross: JsObject  ## Crossings from data, `undefined` where none; read in place.

  Scene = object  ## Define everything drawn at one turn, interpolated between two moments.
    turn, strain: float
    is_ok, is_reseed: bool
    worst: cstring  ## Joint nearest its edge, or empty.
    bodies: array[Dancer, BodyPose]
    connections: array[2, Connection]
    connection_count: int  ## Live bound of `connections`.


func holdDescription(
  key, name, from_rest: cstring; ropes: openArray[Rope]; rest: float
): HoldDescription =
  ## Build hold's specification, deriving bound and pairing from ropes given.
  result = HoldDescription(
    key: key,
    name: name,
    from_rest: from_rest,
    rope_count: ropes.len,
    rest: rest,
    is_pair: ropes.len == 2,
  )
  for i, rope in ropes: result.ropes[i] = rope


const
  SCALE = 125.0  ## Page units per metre, from above.
  RIM = 20.0  ## Body radius on page.
  MOST = 2.0  ## Turns shown each way, however far sweep went.
  Z_SCALE = 62.5  ## Page units per metre of height, in side view.
  SIDE_Y = 200.0  ## Page line of floor in side view.
  STRIP_SLOTS = 11  ## Nine half turns and two blocks at most.
  CHEVRON: array[3, Vector2] = [[-5.0, -4.0], [0.0, 4.0], [5.0, -4.0]]
    ## Chevron's three points about body centre, before turning to facing.
  HOLDS: array[Hold, HoldDescription] = [
    Hold.LeftToLeft: holdDescription(
      "L-l",
      "Left to left",
      "Face-to-face",
      [(Arm.Left, Arm.Left)],
      -0.5,
    ),
    Hold.RightToRight: holdDescription(
      "R-r",
      "Right to right",
      "Face-to-face",
      [(Arm.Right, Arm.Right)],
      -0.5,
    ),
    Hold.LeftToRight: holdDescription(
      "L-r",
      "Left to right",
      "Face-to-face",
      [(Arm.Left, Arm.Right)],
      0.0,
    ),
    Hold.RightToLeft: holdDescription(
      "R-l",
      "Right to left",
      "Face-to-face",
      [(Arm.Right, Arm.Left)],
      0.0,
    ),
    Hold.LeftToLeftRightToRight: holdDescription(
      "L-l.R-r",
      "Left to left · Right to right",
      "Face-to-back",
      [(Arm.Left, Arm.Left), (Arm.Right, Arm.Right)],
      0.0,
    ),
    Hold.LeftToRightRightToLeft: holdDescription(
      "L-r.R-l",
      "Left to right · Right to left",
      "Face-to-face",
      [(Arm.Left, Arm.Right), (Arm.Right, Arm.Left)],
      0.0,
    ),
  ]
    ## Six holds in button order, as original listed them.
  LEVEL_NAMES: array[Level, cstring] = ["low", "high", "above"]
    ## Level's word: in data key, on button, in readout.
  INKS: array[Arm, cstring] = ["left", "right"]
    ## Arm's ink, i.e. CSS variable stem `--left`, `--right`.
  ARM_WORDS: array[Arm, cstring] = ["Left", "Right"]  ## Arm's word capitalised, for pair readout.



#[ Data ]#

func turns(): JsObject {.importjs: "TURNS@".}
  ## Read simulation's sweeps, global spliced in before this script.
  ##   Bare `@` with no arguments makes pattern emit name, not call.
  ##   Pure: data never changes after load, so `func` may read it.

func readSweep(sweep: var Sweep, hold: Hold, level: Level) =
  ## Read one sweep's limits into `sweep`, keeping its moments as reference.
  ##   Fills table's own slot: constructor returned or assigned would deep copy.
  let
    sweep_data = turns().sweeps[HOLDS[hold].key&"|"&LEVEL_NAMES[level]]
    negative = sweep_data.negative.to(float)
    positive = sweep_data.positive.to(float)
  sweep.limits.negative = min(MOST, negative)
  sweep.limits.positive = min(MOST, positive)
  sweep.limits.why_negative = sweep_data.whyNegative.to(cstring)
  sweep.limits.why_positive = sweep_data.why.to(cstring)
  sweep.limits.is_stopped_negative = sweep_data.stoppedNegative.to(bool) and negative < MOST
  sweep.limits.is_stopped_positive = sweep_data.stoppedPositive.to(bool) and positive < MOST
  sweep.limits.found_rest = sweep_data.restHolds.to(bool)
  sweep.frames = sweep_data.frames


func sweepTable(): array[Hold, array[Level, Sweep]] =
  ## Read every sweep by hold and level.
  for hold in Hold:
    for level in Level: readSweep(result[hold][level], hold, level)

let LUT_SWEEP_BY_HOLD = sweepTable()  ## Every sweep by hold and level, read once at load.


func partExtent(rig: JsObject, part: Part): PartExtent =
  ## Read one part's half-extents and height band from rig, in millimetres.
  ##   Fields assigned one by one: constructor assigned to `result` deep copies.
  let heights = rig.heights
  case part
  of Part.Torso:
    result.across = rig.torsoAcross.to(float)
    result.deep = rig.torsoDeep.to(float)
    result.z_from = heights.hip.to(float)
    result.z_to = heights.torso.to(float)
  of Part.Neck:
    result.across = rig.neck.to(float)
    result.deep = rig.neck.to(float)
    result.z_from = heights.torso.to(float)
    result.z_to = heights.neck.to(float)
  of Part.Head:
    result.across = rig.head.to(float)
    result.deep = rig.head.to(float)
    result.z_from = heights.neck.to(float)
    result.z_to = heights.head.to(float)



#[ Projection ]#

func toFixed(number: float, digits: int): cstring {.importjs: "(#).toFixed(#)".}
  ## Write number to `digits` decimals exactly as JavaScript does.

func toText(number: float): cstring {.importjs: "String(#)".}
  ## Write number as JavaScript's `String` does: `2`, not `2.0`.

func parseFloat(text: cstring): float {.importjs: "parseFloat(#)".}
  ## Read number from slider or attribute text, as original did.


func page(x, y: float): Vector2 =
  ## Project point in millimetres onto page from above, north up.
  ##   Elements assigned one by one: `result = [x, y]` deep copies on JS backend.
  result[0] = x / 1000.0 * SCALE
  result[1] = 25.0 - y / 1000.0 * SCALE

func side(joint: Vector3): Vector2 =
  ## Project joint onto side view, looking along couple's line, lead on left.
  result[0] = joint[1] / 1000.0 * SCALE - 25.0
  result[1] = SIDE_Y - joint[2] / 1000.0 * Z_SCALE

template project(joint: Vector3, view: static View): Vector2 =
  ## Project joint for chosen view; template so call lands as argument, uncopied.
  (when view == View.Above: page(joint[0], joint[1]) else: side(joint))

func facingVector(facing: float): Vector2 =
  ## Turn facing angle into page direction.
  result[0] = cos(facing)
  result[1] = -sin(facing)

func pointText(point: Vector2): cstring =
  ## Write page point to one decimal, i.e. `x,y`.
  point[0].toFixed(1) & "," & point[1].toFixed(1)

func pathOf(joints: array[4, Vector3], view: static View): cstring =
  ## Write four joints as SVG path data, i.e. `M x,y L x,y L x,y L x,y`.
  result = "M "
  for k in 0..<4:
    if k > 0: result.add " L "
    result.add pointText(project(joints[k], view))

func interpolate[N: static int](destination: var array[N, float]; a, b: JsObject; u: float) =
  ## Interpolate one vector between two moments into `destination`, reading both in place.
  ##   Writes into scene's own storage: returning array would copy it on assignment.
  for i in 0..<destination.len:
    let value_a = a[i].to(float)
    destination[i] = value_a + (b[i].to(float) - value_a) * u



#[ Marks And Bodies ]#

func markShape(centre: Vector2; who: Dancer; style, extra: cstring): cstring =
  ## Draw mark's shape: square for lead, round for follow.
  case who
  of Dancer.Lead:
    "<rect x=\"" & (centre[0] - 6.0).toFixed(1) & "\" y=\"" & (centre[1] - 6.0).toFixed(1) &
        "\" width=\"12\" height=\"12\" rx=\"1.5\" style=\"" & style & "\"" & extra & "/>"
  of Dancer.Follow:
    "<circle cx=\"" & centre[0].toFixed(1) & "\" cy=\"" & centre[1].toFixed(1) &
        "\" r=\"6\" style=\"" & style & "\"" & extra & "/>"

func markSvg(centre: Vector2, who: Dancer, arm: Arm, level: Level, is_held: bool): cstring =
  ## Draw one mark at shoulder: filled by level when held, hollow and faded when free.
  let
    colour = INKS[arm] & (if who == Dancer.Lead: cstring("-deep") else: "")
    pattern: cstring = if who == Dancer.Lead: "aLd" else: "aL"
    fill =
      if not is_held: cstring("var(--mark-bg)")
      else:
        case level
        of Level.Low: "var(--" & colour & ")"
        of Level.High: cstring("var(--mark-bg)")
        of Level.Above: "url(#" & pattern & ")"
  result = markShape(centre, who, "fill:var(--mark-bg);stroke:none", "")
  result.add markShape(
    centre,
    who,
    "fill:" & fill & ";stroke:var(--" & colour & ");stroke-width:1.5",
    if is_held: cstring("") else: " opacity=\"0.45\"",
  )
  if is_held and level == Level.High:
    result.add "<circle cx=\"" & centre[0].toFixed(1) & "\" cy=\"" & centre[1].toFixed(1) &
        "\" r=\"2.7\" style=\"fill:var(--" & colour & ")\"/>"

func bodySvg(centre: Vector2, facing: Vector2): cstring =
  ## Draw one dancer from above: rim and chevron turned to facing.
  let angle = arctan2(facing[1], facing[0]) - PI / 2.0
  var points: cstring = ""
  for i in 0..<CHEVRON.len:
    let
      chevron_x = CHEVRON[i][0]
      chevron_y = CHEVRON[i][1]
      turned = [
        chevron_x * cos(angle) - chevron_y * sin(angle),
        chevron_x * sin(angle) + chevron_y * cos(angle),
      ]
    if i > 0: points.add " "
    points.add pointText([centre[0] + turned[0], centre[1] + turned[1]])
  "<circle cx=\"" & centre[0].toFixed(1) & "\" cy=\"" & centre[1].toFixed(1) & "\" r=\"" &
      RIM.toText & "\" class=\"rim\"/><polyline points=\"" & points & "\" class=\"chev\"/>"

func shoulderOf(centre: Vector2, facing: float, arm: Arm): Vector2 =
  ## Locate shoulder joint in metres: left arm's quarter turn anticlockwise of facing.
  let
    right = [sin(facing), -cos(facing)]
    k = (if arm == Arm.Left: -1.0 else: 1.0) * (turns().rig.shoulder.to(float) / 1000.0)
  result[0] = centre[0] / 1000.0 + right[0] * k
  result[1] = centre[1] / 1000.0 + right[1] * k

func sideBodies(scene: Scene): cstring =
  ## Draw both bodies from side: torso, neck and head as bands, wide as facing makes them.
  result = ""
  let rig = turns().rig
  for who in Dancer:
    # Alias into storage, never copy.
    template pose: untyped = scene.bodies[who]
    let
      c = cos(pose.facing)
      s = sin(pose.facing)
    for part in Part:
      let
        extent = partExtent(rig, part)
        across = extent.across / 1000.0
        deep = extent.deep / 1000.0
        half = sqrt(across * c * across * c + deep * s * deep * s) * SCALE
        left = pose.centre[1] / 1000.0 * SCALE - 25.0 - half
        top = SIDE_Y - extent.z_to / 1000.0 * Z_SCALE
        height = (extent.z_to - extent.z_from) / 1000.0 * Z_SCALE
      result.add "<rect x=\"" & left.toFixed(1) & "\" y=\"" & top.toFixed(1) & "\" width=\"" &
          (2.0 * half).toFixed(1) & "\" height=\"" & height.toFixed(1) &
          "\" class=\"rim\" style=\"fill:var(--wash, #eee);fill-opacity:0.5\"/>"



#[ Scene ]#

func fillScene(scene: var Scene, frames: JsObject, turn: float): bool =
  ## Fill `scene` at `turn`: joints interpolated between moments either side, words from nearer.
  ##   False, and `scene` untouched, for empty sweep: rest pose that never held draws nothing.
  ##   Fills caller's storage rather than returning `Option[Scene]`, which deep copied
  ##     scene twice per call on JS backend (read in emitted JS: `some` copies its
  ##     parameter into constructor, then constructor into result).
  let count = frames.length.to(int)
  if count == 0: return false

  # Find moments either side of `turn` by bisection on their turns.
  var
    lower = 0
    upper = count - 1
  while upper - lower > 1:
    let middle = (lower + upper) shr 1
    if frames[middle].turn.to(float) <= turn: lower = middle else: upper = middle

  # Weigh later moment by where `turn` falls between; exact equality only guards division.
  let
    moment_a = frames[lower]
    moment_b = frames[upper]
    turn_a = moment_a.turn.to(float)
    turn_b = moment_b.turn.to(float)
    u = if turn_b == turn_a: 0.0 else: max(0.0, min(1.0, (turn - turn_a) / (turn_b - turn_a)))
    near = if u < 0.5: moment_a else: moment_b
    strain_a = moment_a.strain.to(float)
  scene.turn = turn
  scene.is_ok = near.ok.to(bool)
  scene.is_reseed = near.reseed.to(bool)
  scene.strain = strain_a + (moment_b.strain.to(float) - strain_a) * u
  scene.worst = near.worst.to(cstring)
  scene.connection_count = moment_a.connections.length.to(int)

  # Interpolate bodies, then every joint of every rope; words come from nearer moment.
  for who in Dancer:
    let
      body_a = moment_a.bodies[ord(who)]
      body_b = moment_b.bodies[ord(who)]
      facing_a = body_a.facing.to(float)
    interpolate(scene.bodies[who].centre, body_a.centre, body_b.centre, u)
    scene.bodies[who].facing = facing_a + (body_b.facing.to(float) - facing_a) * u
  for i in 0..<scene.connection_count:
    let
      connection_a = moment_a.connections[i]
      connection_b = moment_b.connections[i]
      connection_near = near.connections[i]
    for k in 0..<4:
      interpolate(scene.connections[i].lead[k], connection_a.lead[k], connection_b.lead[k], u)
      interpolate(scene.connections[i].follow[k], connection_a.follow[k], connection_b.follow[k], u)
    scene.connections[i].lead_says = connection_near.leadSays.to(cstring)
    scene.connections[i].follow_says = connection_near.followSays.to(cstring)
    scene.connections[i].cross = connection_near.cross
  true


func sceneSvg(hold: Hold, level: Level, scene: Scene): cstring =
  ## Draw scene: bodies, ropes and marks from above, then same moment from side.
  ##   Hot path: once per animated frame, and once per figure of strip.
  result = ""
  let classes: cstring = if scene.is_ok: "cn" else: "cn no"

  # Bodies from above.
  for who in Dancer:
    # Alias into storage, never copy.
    template pose: untyped = scene.bodies[who]
    result.add bodySvg(page(pose.centre[0], pose.centre[1]), facingVector(pose.facing))

  # Ropes from above, each with elbow and wrist ringed.
  #   Constant: two bodies, four marks, six side rects.  Linear: ropes (bound `connection_count`,
  #   at most two), each four joints projected twice.  Allocates: JS strings for every
  #   `&` and `add`, and one two-element array per projected point; no Nim object copies
  #   (read in emitted JS: parameters and `template` aliases pass by reference).
  for i in 0..<scene.connection_count:
    # Alias into storage, never copy.
    template connection: untyped = scene.connections[i]
    let
      deep = INKS[HOLDS[hold].ropes[i].lead] & "-deep"
      plain = INKS[HOLDS[hold].ropes[i].follow]
    result.add "<path d=\"" & pathOf(connection.lead, View.Above) & "\" class=\"" & classes &
        "\" style=\"stroke:var(--" & deep & ")\"/>"
    result.add "<path d=\"" & pathOf(connection.follow, View.Above) & "\" class=\"" & classes &
        "\" style=\"stroke:var(--" & plain & ")\"/>"
    for k in 1..2:
      let joint = page(connection.lead[k][0], connection.lead[k][1])
      result.add "<circle cx=\"" & joint[0].toFixed(1) & "\" cy=\"" & joint[1].toFixed(1) &
          "\" r=\"1.6\" style=\"fill:var(--mark-bg);stroke:var(--" & deep &
          ");stroke-width:0.8\"/>"
    for k in 1..2:
      let joint = page(connection.follow[k][0], connection.follow[k][1])
      result.add "<circle cx=\"" & joint[0].toFixed(1) & "\" cy=\"" & joint[1].toFixed(1) &
          "\" r=\"1.6\" style=\"fill:var(--mark-bg);stroke:var(--" & plain &
          ");stroke-width:0.8\"/>"

  # Marks at every shoulder, filled where that arm is held.
  var
    held_lead: array[Arm, bool]
    held_follow: array[Arm, bool]
  for i in 0..<scene.connection_count:
    held_lead[HOLDS[hold].ropes[i].lead] = true
    held_follow[HOLDS[hold].ropes[i].follow] = true
  for arm in Arm:
    let
      at_lead = shoulderOf(scene.bodies[Dancer.Lead].centre, scene.bodies[Dancer.Lead].facing, arm)
      at_follow = shoulderOf(
        scene.bodies[Dancer.Follow].centre,
        scene.bodies[Dancer.Follow].facing,
        arm,
      )
    result.add markSvg(
      page(at_lead[0] * 1000.0, at_lead[1] * 1000.0),
      Dancer.Lead,
      arm,
      level,
      held_lead[arm],
    )
    result.add markSvg(
      page(at_follow[0] * 1000.0, at_follow[1] * 1000.0),
      Dancer.Follow,
      arm,
      level,
      held_follow[arm],
    )

  # Same moment from side, looking along couple's line, lead on left.
  result.add "<g class=\"side\">" & sideBodies(scene)
  for i in 0..<scene.connection_count:
    # Alias into storage, never copy.
    template connection: untyped = scene.connections[i]
    let
      deep = INKS[HOLDS[hold].ropes[i].lead] & "-deep"
      plain = INKS[HOLDS[hold].ropes[i].follow]
    result.add "<path d=\"" & pathOf(connection.lead, View.Side) & "\" class=\"" & classes &
        "\" style=\"stroke:var(--" & deep & ")\"/>"
    result.add "<path d=\"" & pathOf(connection.follow, View.Side) & "\" class=\"" & classes &
        "\" style=\"stroke:var(--" & plain & ")\"/>"
  result.add "</g>"


func turnWord(turn: float): cstring =
  ## Write turn in halves, i.e. `+1½`, `−½`, `0`; halves rounded as `Math.round` does.
  let
    halves = int(floor(turn * 2.0 + 0.5))
    sign: cstring = if halves < 0: "−" elif halves > 0: "+" else: ""
    magnitude = abs(halves)
    word =
      if magnitude mod 2 == 0: float(magnitude div 2).toText
      elif magnitude > 1: float(magnitude div 2).toText & "½"
      else: cstring("½")
  sign & word

func turnFigure(turn: float): cstring =
  ## Write turn to two decimals with its sign, i.e. `+0.31`, `−1.12`.
  (if turn < 0.0: cstring("−") else: "+") & abs(turn).toFixed(2)

func holdOfKey(key: cstring): Hold =
  ## Find hold by data key, i.e. button's `data-k`.
  for hold in Hold:
    if HOLDS[hold].key == key: return hold
  doAssert false, "No hold has key; got `" & $key & "`."

func levelOfName(name: cstring): Level =
  ## Find level by its word, i.e. button's `data-l`.
  for level in Level:
    if LEVEL_NAMES[level] == name: return level
  doAssert false, "No level has name; got `" & $name & "`."



#[ Panel ]#

# Mutable: panel's state, which every handler reads and changes.  Browser calls
# handlers with nothing of their own, so state lives here.
var
  HOLD_SHOWN = Hold.LeftToLeft  ## Hold on show.
  LEVEL_SHOWN = Level.Low  ## Height on show.
  TURN_DRAWN = -0.5  ## Turn drawn now.
  TURN_TARGET = -0.5  ## Turn eased toward while not playing.
  IS_PLAYING = false  ## Sweeping between blocks.
  DIRECTION_PLAY = 1.0  ## Way play sweeps: `+1` toward `positive` block, `-1` other way.
  NOW_PREV = 0.0  ## Timestamp of previous frame; seeded by `start`.
  SCENE_STORAGE: Scene  ## One scene's storage, refilled per draw; never reallocated.

let
  STAGE_ELEMENT = document.getElementById("stage")
    ## Drawing of hold at `TURN_DRAWN`, from above and from side.
  READOUT_ELEMENT = document.getElementById("readout")
    ## Words beside stage: hold, turn, simulation's verdicts, blocks.
  STRIP_ELEMENT = document.getElementById("strip")
    ## Row of small figures, every half turn and both blocks.
  SLIDER_ELEMENT = InputElement(document.getElementById("turn"))
    ## Turn control, `-2` to `2` by `0.005`.
  HOLD_BOX = document.getElementById("hold-buttons")  ## Holder of one button per hold.
  LEVEL_BOX = document.getElementById("level-buttons")  ## Holder of one button per level.


proc clampTurn(turn: float): float =
  ## Keep turn within blocks of hold and level on show.
  template limits: untyped = LUT_SWEEP_BY_HOLD[HOLD_SHOWN][LEVEL_SHOWN].limits
  max(-limits.negative, min(limits.positive, turn))


proc renderStage() =
  ## Redraw stage and readout at `TURN_DRAWN`, and move slider there.
  ##   Hot path: once per animated frame.  Constant: one scene refilled in place.
  ##     Allocates markup strings only; browser's parse of stage and readout dominates.
  template sweep: untyped = LUT_SWEEP_BY_HOLD[HOLD_SHOWN][LEVEL_SHOWN]
  # Alias into storage, never copy.
  template limits: untyped = sweep.limits
  let found_scene = fillScene(SCENE_STORAGE, sweep.frames, TURN_DRAWN)
  STAGE_ELEMENT.innerHTML =
    if found_scene: sceneSvg(HOLD_SHOWN, LEVEL_SHOWN, SCENE_STORAGE) else: ""
  SLIDER_ELEMENT.value = TURN_DRAWN.toText
  let head = "<b>" & HOLDS[HOLD_SHOWN].name & "</b> · " & LEVEL_NAMES[LEVEL_SHOWN] & " · @ " &
      turnFigure(TURN_DRAWN) & " from " & HOLDS[HOLD_SHOWN].from_rest
  if not found_scene or not limits.found_rest:
    READOUT_ELEMENT.innerHTML = head & "<br>no pose holds at the rest"
    return

  # One line per rope: follow's arm word, lead's where not open, crossings where any.
  let
    is_at_negative = TURN_DRAWN <= -limits.negative + 1e-6 and limits.is_stopped_negative
    is_at_positive = TURN_DRAWN >= limits.positive - 1e-6 and limits.is_stopped_positive
  var lines: cstring = ""
  for i in 0..<SCENE_STORAGE.connection_count:
    # Alias into storage, never copy.
    template connection: untyped = SCENE_STORAGE.connections[i]
    # Alias into storage, never copy.
    template rope: untyped = HOLDS[HOLD_SHOWN].ropes[i]
    let name =
      if HOLDS[HOLD_SHOWN].is_pair: ARM_WORDS[rope.lead] & " to " & INKS[rope.follow] & ": "
      else: cstring("")
    var crossing: cstring = ""
    if not connection.cross.isUndefined:
      crossing = " <span class=\"say\">("
      for k in 0..<connection.cross.length.to(int):
        if k > 0: crossing.add ", "
        crossing.add (if connection.cross[k].over.to(int) == 0: cstring("the first")
                      else: "the second") &
          " over"
      crossing.add ")</span>"
    lines.add "<br>" & name & "the follow's arm <b>" & connection.follow_says & "</b>" &
      (if connection.lead_says != "open": ", the lead's arm <b>" & connection.lead_says & "</b>"
       else: cstring("")) &
      crossing

  # Then strain, then both blocks, flagged where turn stands on one.
  lines.add "<br>strain <b>" & SCENE_STORAGE.strain.toFixed(2) & "</b>" &
    (if SCENE_STORAGE.worst.len > 0: " at " & SCENE_STORAGE.worst else: cstring("")) &
    (if SCENE_STORAGE.is_reseed: cstring(" <span class=\"say\">(the arms re-posed here)</span>")
     else: "")
  const unstopped: cstring = " (not within two turns)"
    ## Block's word where sweep ran out of range before any joint refused.
  var blocks = "blocks at " & turnFigure(-limits.negative) &
      (if limits.is_stopped_negative: " (" & limits.why_negative & ")" else: unstopped) &
      " and " & turnFigure(limits.positive) &
      (if limits.is_stopped_positive: " (" & limits.why_positive & ")" else: unstopped)
  if is_at_negative or is_at_positive:
    blocks = "<b class=\"bad\">blocked here</b> — " &
        (if is_at_negative: limits.why_negative else: limits.why_positive) & "; " & blocks
  lines.add "<br>" & blocks
  READOUT_ELEMENT.innerHTML = head & lines


proc renderStrip() =
  ## Redraw strip of small figures: every half turn and both blocks, in order.
  template sweep: untyped = LUT_SWEEP_BY_HOLD[HOLD_SHOWN][LEVEL_SHOWN]
  var
    shown: array[STRIP_SLOTS, float]
    count = 0
  for half in -4..4:
    shown[count] = float(half) / 2.0
    inc count
  if sweep.limits.is_stopped_negative:
    shown[count] = -sweep.limits.negative
    inc count
  if sweep.limits.is_stopped_positive:
    shown[count] = sweep.limits.positive
    inc count

  # Sort ascending; insertion suits eleven values and keeps equal ones in order.
  for i in 1..<count:
    var j = i
    while j > 0 and shown[j-1] > shown[j]:
      swap(shown[j-1], shown[j])
      dec j

  # One figure per turn: crossed out beyond blocks, else scene with simulation's words.
  var html: cstring = ""
  for i in 0..<count:
    let
      turn = shown[i]
      is_half = abs(turn * 2.0 - floor(turn * 2.0 + 0.5)) < 1e-6
    if turn < -sweep.limits.negative - 1e-6 or turn > sweep.limits.positive + 1e-6 or
        not sweep.limits.found_rest:
      html.add "<figure class=\"mini blocked\" data-t=\"" & turn.toText &
          "\"><div class=\"x\">&#10005;</div><figcaption><b>@ " & turnWord(turn) &
          "</b><br><span class=\"say\">blocked — " &
          (if turn < 0.0: sweep.limits.why_negative else: sweep.limits.why_positive) &
          "</span></figcaption></figure>"
      continue
    doAssert fillScene(SCENE_STORAGE, sweep.frames, turn),
      "Sweep within its blocks must have moments."
    var words: cstring = ""
    for k in 0..<SCENE_STORAGE.connection_count:
      if k > 0: words.add " · "
      words.add SCENE_STORAGE.connections[k].follow_says
    let
      is_rest = abs(turn - HOLDS[HOLD_SHOWN].rest) < 1e-6
      is_limit = not is_half
    html.add "<figure class=\"mini" & (if is_limit: cstring(" limit") else: "") &
        "\" data-t=\"" & turn.toText & "\"><svg viewBox=\"-52 -56 104 112\" width=\"70\">" &
        sceneSvg(HOLD_SHOWN, LEVEL_SHOWN, SCENE_STORAGE) & "</svg>" & "<figcaption><b>@ " &
        (if is_half: turnWord(turn) else: turnFigure(turn)) & "</b>" &
        (if is_rest: cstring(" rest") else: "") & (if is_limit: cstring(" the block") else: "") &
        "<br><span class=\"say\">" & words & "</span></figcaption></figure>"
  STRIP_ELEMENT.innerHTML = html
  for figure in STRIP_ELEMENT.querySelectorAll(".mini:not(.blocked)"):
    figure.addEventListener("click", proc (event: Event) =
      IS_PLAYING = false
      TURN_TARGET = parseFloat(event.currentTarget.getAttribute("data-t")))


proc renderButtons() =
  ## Redraw hold and level buttons, marking those on show, and wire their clicks.
  var html: cstring = ""
  for hold in Hold:
    html.add "<button class=\"" & (if hold == HOLD_SHOWN: cstring("on") else: "") & "\" data-k=\"" &
        HOLDS[hold].key & "\">" & HOLDS[hold].name & "</button>"
  HOLD_BOX.innerHTML = html
  html = ""
  for level in Level:
    html.add "<button class=\"" & (if level == LEVEL_SHOWN: cstring("on") else: "") &
        "\" data-l=\"" & LEVEL_NAMES[level] & "\">" & LEVEL_NAMES[level] & "</button>"
  LEVEL_BOX.innerHTML = html
  for button in HOLD_BOX.querySelectorAll("button"):
    button.addEventListener("click", proc (event: Event) =
      HOLD_SHOWN = holdOfKey(event.currentTarget.getAttribute("data-k"))
      TURN_DRAWN = clampTurn(HOLDS[HOLD_SHOWN].rest)
      TURN_TARGET = TURN_DRAWN
      renderButtons()
      renderStrip()
      renderStage())
  for button in LEVEL_BOX.querySelectorAll("button"):
    button.addEventListener("click", proc (event: Event) =
      LEVEL_SHOWN = levelOfName(event.currentTarget.getAttribute("data-l"))
      TURN_DRAWN = clampTurn(TURN_DRAWN)
      TURN_TARGET = TURN_DRAWN
      renderButtons()
      renderStrip()
      renderStage())


proc tick(now: float) =
  ## Advance one frame: sweep between blocks while playing, else ease toward `TURN_TARGET`.
  ##   Redraws only when `TURN_DRAWN` moved (Article VII.3); frame time capped at 50 ms.
  let elapsed = min(0.05, (now - NOW_PREV) / 1000.0)
  NOW_PREV = now
  if IS_PLAYING:
    # Alias into storage, never copy.
    template limits: untyped = LUT_SWEEP_BY_HOLD[HOLD_SHOWN][LEVEL_SHOWN].limits
    TURN_DRAWN += DIRECTION_PLAY * elapsed * 0.35
    if TURN_DRAWN >= limits.positive:
      TURN_DRAWN = limits.positive
      DIRECTION_PLAY = -1.0
    elif TURN_DRAWN <= -limits.negative:
      TURN_DRAWN = -limits.negative
      DIRECTION_PLAY = 1.0
    TURN_TARGET = TURN_DRAWN
    renderStage()
  elif abs(TURN_TARGET - TURN_DRAWN) > 0.002:
    let away = TURN_TARGET - TURN_DRAWN
    TURN_DRAWN += (if away < 0.0: -1.0 else: 1.0) * min(abs(away), elapsed * 0.9)
    renderStage()
  discard window.requestAnimationFrame(tick)

proc start(now: float) =
  ## Seed frame clock on first frame, then tick: first `elapsed` is nought, as original's was.
  ##   Replaces original's `null` clock, sparing `Option[float]` and its copy per frame.
  NOW_PREV = now
  tick(now)


SLIDER_ELEMENT.addEventListener("input", proc (event: Event) =
  IS_PLAYING = false
  TURN_DRAWN = clampTurn(parseFloat(SLIDER_ELEMENT.value))
  TURN_TARGET = TURN_DRAWN
  renderStage())
document.getElementById("play").addEventListener("click", proc (event: Event) =
  IS_PLAYING = not IS_PLAYING)
document.getElementById("to-rest").addEventListener("click", proc (event: Event) =
  IS_PLAYING = false
  TURN_TARGET = clampTurn(HOLDS[HOLD_SHOWN].rest))

renderButtons()
renderStrip()
renderStage()
discard window.requestAnimationFrame(start)
