## Animate whole-cloth page's turns panel from body sim's sweeps.
##
##   Port of script hand-written inside `wholecloth.html`, kept byte for byte in
##     what it draws: page's markup is now hosted in Nim (`wholecloth_page`), so
##     its one program is too, compiled with `nim js` and spliced back in by
##     `wholecloth`.  Page only draws; every pose is one sim found natively.
##   Data stays where it is: `TURNS` (800 KB, spliced in before this script as
##     global) is read in place as `JsObject` through `std/jsffi`, never copied
##     into Nim objects, since every copy on JS backend is deep (STYLE.md §7).
##     Only scene at one moment is built as Nim value, interpolated afresh.
##   Holds and levels are closed domains (six by three), so both are enums and
##     every table over them is enum-indexed array (Article IV.6): sweep limits
##     and frame references are read once at load into `lut_hold_sweep`, which
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
##     binds without copy; `var` out-parameters (`lerp`, `sceneOf`,
##     `readSweep`) write into storage in place.  Shapes rejected after reading
##     them: `result = [x, y]` and constructor assigned to `result` (one deep
##     copy each), `Option[Scene]` (two per call), `for (px, py) in` over tuple
##     table (one per element per call), `Option[float]` clock (two per frame).

{.experimental: "strictFuncs".}

import std/[dom, jsffi, math]



#[ Domain ]#

type
  Arm {.pure.} = enum
    ## Define which arm of dancer.
    Left, Right

  Dancer {.pure.} = enum
    ## Define who: lead (him, square marks, deep ink) or follow (her, round, plain).
    Lead, Follow

  Hold {.pure.} = enum
    ## Define six holds page offers, lead's hand named first.
    LtoL, RtoR, LtoR, RtoL, LlRr, LrRl

  Level {.pure.} = enum
    ## Define three heights hands are held at.
    Low, High, Above

  Part {.pure.} = enum
    ## Define body parts drawn in side view, hip upward.
    Torso, Neck, Head

  View {.pure.} = enum
    ## Define projections: from above onto page, and from side along couple's line.
    Above, Side

  Rope = tuple[his, hers: Arm]
    ## Define one connection: lead's arm to follow's arm.

  HoldSpec = object
    ## Define one hold: key in data, name on button, ropes, rest turn and its words.
    key: cstring            ## Key of sweep in `TURNS.sweeps`, before `|level`.
    name: cstring
    from_rest: cstring      ## Where turns count from, for readout.
    ropes: array[2, Rope]
    rope_count: int         ## Live bound of `ropes`.
    rest: float             ## Turn at which nothing is wound.
    is_pair: bool           ## Two ropes, so readout names each.

  Limits = object
    ## Define where one sweep runs out each way, and why.
    neg, pos: float                       ## Turns reached each way, at most `MOST`.
    why_neg, why_pos: cstring             ## What refused, each way.
    is_stopped_neg, is_stopped_pos: bool  ## Blocked within `MOST`, not merely ended.
    does_rest_hold: bool                  ## Whether rest pose exists at all.

  Sweep = object
    ## Define one sweep as page reads it: limits, and moments as reference into `TURNS`.
    limits: Limits
    frames: JsObject

  Vec2 = array[2, float]
    ## Define point on page, or centre in millimetres.

  Vec3 = array[3, float]
    ## Define joint in millimetres: across, along, up.

  PartExtent = object
    ## Define one body part's half-extents and height band, in millimetres.
    across, deep, z_from, z_to: float

  BodyPose = object
    ## Define where one dancer stands and faces at one moment.
    centre: Vec2
    facing: float

  Connection = object
    ## Define one rope at one moment: four joints each side, and sim's words.
    him, her: array[4, Vec3]
    him_says, her_says: cstring
    cross: JsObject         ## Crossings from data, `undefined` where none; read in place.

  Scene = object
    ## Define everything drawn at one turn, interpolated between two moments.
    turn, strain: float
    is_ok, is_reseed: bool
    worst: cstring          ## Joint nearest its edge, or empty.
    bodies: array[Dancer, BodyPose]
    cn: array[2, Connection]
    cn_count: int           ## Live bound of `cn`.


func holdSpec(key, name, from_rest: cstring; ropes: openArray[Rope]; rest: float): HoldSpec =
  ## Build hold's specification, deriving bound and pairing from ropes given.
  result = HoldSpec(
    key: key,
    name: name,
    from_rest: from_rest,
    rope_count: ropes.len,
    rest: rest,
    is_pair: ropes.len == 2,
  )
  for i, rope in ropes: result.ropes[i] = rope


const
  SCALE = 125.0       ## Page units per metre, from above.
  RIM = 20.0          ## Body radius on page.
  MOST = 2.0          ## Turns shown each way, however far sweep went.
  Z_SCALE = 62.5      ## Page units per metre of height, in side view.
  SIDE_Y = 200.0      ## Page line of floor in side view.
  STRIP_SLOTS = 11    ## Nine half turns and two blocks at most.
  CHEVRON: array[3, Vec2] = [[-5.0, -4.0], [0.0, 4.0], [5.0, -4.0]]
    ## Chevron's three points about body centre, before turning to facing.
  HOLDS: array[Hold, HoldSpec] = [
    Hold.LtoL: holdSpec("L-l", "Left to left", "face-to-face", [(Arm.Left, Arm.Left)], -0.5),
    Hold.RtoR: holdSpec("R-r", "Right to right", "face-to-face", [(Arm.Right, Arm.Right)], -0.5),
    Hold.LtoR: holdSpec("L-r", "Left to right", "face-to-face", [(Arm.Left, Arm.Right)], 0.0),
    Hold.RtoL: holdSpec("R-l", "Right to left", "face-to-face", [(Arm.Right, Arm.Left)], 0.0),
    Hold.LlRr: holdSpec(
      "L-l.R-r",
      "Left to left · Right to right",
      "pillion lead",
      [(Arm.Left, Arm.Left), (Arm.Right, Arm.Right)],
      0.0,
    ),
    Hold.LrRl: holdSpec(
      "L-r.R-l",
      "Left to right · Right to left",
      "face-to-face",
      [(Arm.Left, Arm.Right), (Arm.Right, Arm.Left)],
      0.0,
    ),
  ]
    ## Six holds in button order, as original listed them.
  LEVEL_NAMES: array[Level, cstring] = ["low", "high", "above"]
    ## Level's word: in data key, on button, in readout.
  INKS: array[Arm, cstring] = ["left", "right"]
    ## Arm's ink, i.e. CSS variable stem `--left`, `--right`.
  ARM_WORDS: array[Arm, cstring] = ["Left", "Right"]
    ## Arm's word capitalised, for pair readout.



#[ Data ]#

func turns(): JsObject {.importjs: "TURNS@".}
  ## Read sim's sweeps, global spliced in before this script.
  ##   Bare `@` with no arguments makes pattern emit name, not call.
  ##   Pure: data never changes after load, so `func` may read it.

func readSweep(sweep: var Sweep, hold: Hold, level: Level) =
  ## Read one sweep's limits into `sweep`, keeping its moments as reference.
  ##   Fills table's own slot: constructor returned or assigned would deep copy.
  let
    sw = turns().sweeps[HOLDS[hold].key & "|" & LEVEL_NAMES[level]]
    neg = sw.neg.to(float)
    pos = sw.pos.to(float)
  sweep.limits.neg = min(MOST, neg)
  sweep.limits.pos = min(MOST, pos)
  sweep.limits.why_neg = sw.whyNeg.to(cstring)
  sweep.limits.why_pos = sw.why.to(cstring)
  sweep.limits.is_stopped_neg = sw.stoppedNeg.to(bool) and neg < MOST
  sweep.limits.is_stopped_pos = sw.stoppedPos.to(bool) and pos < MOST
  sweep.limits.does_rest_hold = sw.restHolds.to(bool)
  sweep.frames = sw.frames


func sweepTable(): array[Hold, array[Level, Sweep]] =
  ## Read every sweep by hold and level.
  for hold in Hold:
    for level in Level: readSweep(result[hold][level], hold, level)

let lut_hold_sweep = sweepTable()
  ## Every sweep by hold and level, read once at load.


func partExtent(rig: JsObject, part: Part): PartExtent =
  ## Read one part's half-extents and height band from rig, in millimetres.
  ##   Fields assigned one by one: constructor assigned to `result` deep copies.
  let z = rig.z
  case part
  of Part.Torso:
    result.across = rig.torsoAcross.to(float)
    result.deep = rig.torsoDeep.to(float)
    result.z_from = z.hip.to(float)
    result.z_to = z.torso.to(float)
  of Part.Neck:
    result.across = rig.neck.to(float)
    result.deep = rig.neck.to(float)
    result.z_from = z.torso.to(float)
    result.z_to = z.neck.to(float)
  of Part.Head:
    result.across = rig.head.to(float)
    result.deep = rig.head.to(float)
    result.z_from = z.neck.to(float)
    result.z_to = z.head.to(float)



#[ Projection ]#

func toFixed(x: float, digits: int): cstring {.importjs: "(#).toFixed(#)".}
  ## Write number to `digits` decimals exactly as JavaScript does.

func jsStr(x: float): cstring {.importjs: "String(#)".}
  ## Write number as JavaScript's `String` does: `2`, not `2.0`.

func parseFloat(text: cstring): float {.importjs: "parseFloat(#)".}
  ## Read number from slider or attribute text, as original did.


func page(x, y: float): Vec2 =
  ## Project point in millimetres onto page from above, north up.
  ##   Elements assigned one by one: `result = [x, y]` deep copies on JS backend.
  result[0] = x / 1000.0 * SCALE
  result[1] = 25.0 - y / 1000.0 * SCALE

func side(p: Vec3): Vec2 =
  ## Project joint onto side view, looking along couple's line, lead on left.
  result[0] = p[1] / 1000.0 * SCALE - 25.0
  result[1] = SIDE_Y - p[2] / 1000.0 * Z_SCALE

template project(p: Vec3, view: static View): Vec2 =
  ## Project joint for chosen view; template so call lands as argument, uncopied.
  (when view == View.Above: page(p[0], p[1]) else: side(p))

func facingVec(a: float): Vec2 =
  ## Turn facing angle into page direction.
  result[0] = cos(a)
  result[1] = -sin(a)

func fmt(p: Vec2): cstring =
  ## Write page point to one decimal, i.e. `x,y`.
  p[0].toFixed(1) & "," & p[1].toFixed(1)

func pathOf(joints: array[4, Vec3], view: static View): cstring =
  ## Write four joints as SVG path data, i.e. `M x,y L x,y L x,y L x,y`.
  result = "M "
  for k in 0 ..< 4:
    if k > 0: result.add " L "
    result.add fmt(project(joints[k], view))

func lerp[N: static int](dest: var array[N, float]; a, b: JsObject; u: float) =
  ## Interpolate one vector between two moments into `dest`, reading both in place.
  ##   Writes into scene's own storage: returning array would copy it on assignment.
  for i in 0 ..< dest.len:
    let v = a[i].to(float)
    dest[i] = v + (b[i].to(float) - v) * u



#[ Marks And Bodies ]#

func markShape(m: Vec2, who: Dancer, style, extra: cstring): cstring =
  ## Draw mark's shape: square for lead, round for follow.
  case who
  of Dancer.Lead:
    "<rect x=\"" & (m[0] - 6.0).toFixed(1) & "\" y=\"" & (m[1] - 6.0).toFixed(1) &
      "\" width=\"12\" height=\"12\" rx=\"1.5\" style=\"" & style & "\"" & extra & "/>"
  of Dancer.Follow:
    "<circle cx=\"" & m[0].toFixed(1) & "\" cy=\"" & m[1].toFixed(1) &
      "\" r=\"6\" style=\"" & style & "\"" & extra & "/>"

func markSvg(m: Vec2, who: Dancer, arm: Arm, level: Level, is_held: bool): cstring =
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
  result = markShape(m, who, "fill:var(--mark-bg);stroke:none", "")
  result.add markShape(
    m,
    who,
    "fill:" & fill & ";stroke:var(--" & colour & ");stroke-width:1.5",
    if is_held: cstring("") else: " opacity=\"0.45\"",
  )
  if is_held and level == Level.High:
    result.add "<circle cx=\"" & m[0].toFixed(1) & "\" cy=\"" & m[1].toFixed(1) &
      "\" r=\"2.7\" style=\"fill:var(--" & colour & ")\"/>"

func bodySvg(c: Vec2, f: Vec2): cstring =
  ## Draw one dancer from above: rim and chevron turned to facing.
  let a = arctan2(f[1], f[0]) - PI / 2.0
  var points: cstring = ""
  for i in 0 ..< CHEVRON.len:
    let
      px = CHEVRON[i][0]
      py = CHEVRON[i][1]
      q = [px * cos(a) - py * sin(a), px * sin(a) + py * cos(a)]
    if i > 0: points.add " "
    points.add fmt([c[0] + q[0], c[1] + q[1]])
  "<circle cx=\"" & c[0].toFixed(1) & "\" cy=\"" & c[1].toFixed(1) & "\" r=\"" & jsStr(RIM) &
    "\" class=\"rim\"/><polyline points=\"" & points & "\" class=\"chev\"/>"

func shoulderOf(centre: Vec2, facing: float, arm: Arm): Vec2 =
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
    template b: untyped = scene.bodies[who]
    let
      c = cos(b.facing)
      s = sin(b.facing)
    for part in Part:
      let
        e = partExtent(rig, part)
        a = e.across / 1000.0
        d = e.deep / 1000.0
        half = sqrt(a * c * a * c + d * s * d * s) * SCALE
        x0 = b.centre[1] / 1000.0 * SCALE - 25.0 - half
        y0 = SIDE_Y - e.z_to / 1000.0 * Z_SCALE
        h = (e.z_to - e.z_from) / 1000.0 * Z_SCALE
      result.add "<rect x=\"" & x0.toFixed(1) & "\" y=\"" & y0.toFixed(1) & "\" width=\"" &
        (2.0 * half).toFixed(1) & "\" height=\"" & h.toFixed(1) &
        "\" class=\"rim\" style=\"fill:var(--wash, #eee);fill-opacity:0.5\"/>"



#[ Scene ]#

func sceneOf(scene: var Scene, frames: JsObject, turn: float): bool =
  ## Fill `scene` at `turn`: joints interpolated between moments either side, words from nearer.
  ##   False, and `scene` untouched, for empty sweep: rest pose that never held draws nothing.
  ##   Fills caller's storage rather than returning `Option[Scene]`, which deep copied
  ##     scene twice per call on JS backend (read in emitted JS: `some` copies its
  ##     parameter into constructor, then constructor into result).
  let count = frames.length.to(int)
  if count == 0: return false

  # Find moments either side of `turn` by bisection on their turns.
  var
    lo = 0
    hi = count - 1
  while hi - lo > 1:
    let mid = (lo + hi) shr 1
    if frames[mid].t.to(float) <= turn: lo = mid else: hi = mid

  # Weigh later moment by where `turn` falls between; exact equality only guards division.
  let
    a = frames[lo]
    b = frames[hi]
    t_a = a.t.to(float)
    t_b = b.t.to(float)
    u = if t_b == t_a: 0.0 else: max(0.0, min(1.0, (turn - t_a) / (t_b - t_a)))
    near = if u < 0.5: a else: b
    strain_a = a.strain.to(float)
  scene.turn = turn
  scene.is_ok = near.ok.to(bool)
  scene.is_reseed = near.reseed.to(bool)
  scene.strain = strain_a + (b.strain.to(float) - strain_a) * u
  scene.worst = near.worst.to(cstring)
  scene.cn_count = a.cn.length.to(int)

  # Interpolate bodies, then every joint of every rope; words come from nearer moment.
  for who in Dancer:
    let
      body_a = a.bodies[ord(who)]
      body_b = b.bodies[ord(who)]
      facing_a = body_a.f.to(float)
    lerp(scene.bodies[who].centre, body_a.c, body_b.c, u)
    scene.bodies[who].facing = facing_a + (body_b.f.to(float) - facing_a) * u
  for i in 0 ..< scene.cn_count:
    let
      cn_a = a.cn[i]
      cn_b = b.cn[i]
      cn_near = near.cn[i]
    for k in 0 ..< 4:
      lerp(scene.cn[i].him[k], cn_a.him[k], cn_b.him[k], u)
      lerp(scene.cn[i].her[k], cn_a.her[k], cn_b.her[k], u)
    scene.cn[i].him_says = cn_near.himSays.to(cstring)
    scene.cn[i].her_says = cn_near.herSays.to(cstring)
    scene.cn[i].cross = cn_near.cross
  true


func sceneSvg(hold: Hold, level: Level, scene: Scene): cstring =
  ## Draw scene: bodies, ropes and marks from above, then same moment from side.
  ##   Hot path: once per animated frame, and once per figure of strip.
  result = ""
  let cls: cstring = if scene.is_ok: "cn" else: "cn no"

  # Bodies from above.
  for who in Dancer:
    template b: untyped = scene.bodies[who]
    result.add bodySvg(page(b.centre[0], b.centre[1]), facingVec(b.facing))

  # Ropes from above, each with elbow and wrist ringed.
  #   Constant: two bodies, four marks, six side rects.  Linear: ropes (bound `cn_count`,
  #   at most two), each four joints projected twice.  Allocates: JS strings for every
  #   `&` and `add`, and one two-element array per projected point; no Nim object copies
  #   (read in emitted JS: parameters and `template` aliases pass by reference).
  for i in 0 ..< scene.cn_count:
    template c: untyped = scene.cn[i]
    let
      deep = INKS[HOLDS[hold].ropes[i].his] & "-deep"
      plain = INKS[HOLDS[hold].ropes[i].hers]
    result.add "<path d=\"" & pathOf(c.him, View.Above) & "\" class=\"" & cls &
      "\" style=\"stroke:var(--" & deep & ")\"/>"
    result.add "<path d=\"" & pathOf(c.her, View.Above) & "\" class=\"" & cls &
      "\" style=\"stroke:var(--" & plain & ")\"/>"
    for k in 1 .. 2:
      let q = page(c.him[k][0], c.him[k][1])
      result.add "<circle cx=\"" & q[0].toFixed(1) & "\" cy=\"" & q[1].toFixed(1) &
        "\" r=\"1.6\" style=\"fill:var(--mark-bg);stroke:var(--" & deep &
        ");stroke-width:0.8\"/>"
    for k in 1 .. 2:
      let q = page(c.her[k][0], c.her[k][1])
      result.add "<circle cx=\"" & q[0].toFixed(1) & "\" cy=\"" & q[1].toFixed(1) &
        "\" r=\"1.6\" style=\"fill:var(--mark-bg);stroke:var(--" & plain &
        ");stroke-width:0.8\"/>"

  # Marks at every shoulder, filled where that arm is held.
  var
    held_his: array[Arm, bool]
    held_hers: array[Arm, bool]
  for i in 0 ..< scene.cn_count:
    held_his[HOLDS[hold].ropes[i].his] = true
    held_hers[HOLDS[hold].ropes[i].hers] = true
  for arm in Arm:
    let
      his = shoulderOf(scene.bodies[Dancer.Lead].centre, scene.bodies[Dancer.Lead].facing, arm)
      hers = shoulderOf(
        scene.bodies[Dancer.Follow].centre, scene.bodies[Dancer.Follow].facing, arm)
    result.add markSvg(page(his[0] * 1000.0, his[1] * 1000.0), Dancer.Lead, arm, level,
      held_his[arm])
    result.add markSvg(page(hers[0] * 1000.0, hers[1] * 1000.0), Dancer.Follow, arm, level,
      held_hers[arm])

  # Same moment from side, looking along couple's line, lead on left.
  result.add "<g class=\"side\">" & sideBodies(scene)
  for i in 0 ..< scene.cn_count:
    template c: untyped = scene.cn[i]
    let
      deep = INKS[HOLDS[hold].ropes[i].his] & "-deep"
      plain = INKS[HOLDS[hold].ropes[i].hers]
    result.add "<path d=\"" & pathOf(c.him, View.Side) & "\" class=\"" & cls &
      "\" style=\"stroke:var(--" & deep & ")\"/>"
    result.add "<path d=\"" & pathOf(c.her, View.Side) & "\" class=\"" & cls &
      "\" style=\"stroke:var(--" & plain & ")\"/>"
  result.add "</g>"


func turnWord(turn: float): cstring =
  ## Write turn in halves, i.e. `+1½`, `−½`, `0`; halves rounded as `Math.round` does.
  let
    h = int(floor(turn * 2.0 + 0.5))
    sign: cstring = if h < 0: "−" elif h > 0: "+" else: ""
    a = abs(h)
    word =
      if a mod 2 == 0: jsStr(float(a div 2))
      elif a > 1: jsStr(float(a div 2)) & "½"
      else: cstring("½")
  sign & word

func turnNum(turn: float): cstring =
  ## Write turn to two decimals with its sign, i.e. `+0.31`, `−1.12`.
  (if turn < 0.0: cstring("−") else: "+") & abs(turn).toFixed(2)

func holdOfKey(key: cstring): Hold =
  ## Find hold by data key, i.e. button's `data-k`.
  for h in Hold:
    if HOLDS[h].key == key: return h
  doAssert false, "No hold has key; got `" & $key & "`."

func levelOfName(name: cstring): Level =
  ## Find level by its word, i.e. button's `data-l`.
  for l in Level:
    if LEVEL_NAMES[l] == name: return l
  doAssert false, "No level has name; got `" & $name & "`."



#[ Panel ]#

var
  hold = Hold.LtoL          ## Hold on show.
  level = Level.Low         ## Height on show.
  turn = -0.5               ## Turn drawn now.
  target = -0.5             ## Turn eased toward while not playing.
  is_playing = false        ## Sweeping between blocks.
  direction = 1.0           ## Way play sweeps: `+1` toward `pos` block, `-1` toward `neg`.
  last_now = 0.0            ## Timestamp of previous frame; seeded by `start`.
  scene: Scene              ## One scene's storage, refilled per draw; never reallocated.

let
  stage = document.getElementById("stage")
    ## Drawing of hold at `turn`, from above and from side.
  readout = document.getElementById("readout")
    ## Words beside stage: hold, turn, sim's verdicts, blocks.
  strip = document.getElementById("strip")
    ## Row of small figures, every half turn and both blocks.
  slider = InputElement(document.getElementById("turn"))
    ## Turn control, `-2` to `2` by `0.005`.
  hold_box = document.getElementById("hold-buttons")
    ## Holder of one button per hold.
  level_box = document.getElementById("level-buttons")
    ## Holder of one button per level.


proc clampT(t: float): float =
  ## Keep turn within blocks of hold and level on show.
  template limits: untyped = lut_hold_sweep[hold][level].limits
  max(-limits.neg, min(limits.pos, t))


proc renderStage() =
  ## Redraw stage and readout at `turn`, and move slider there.
  ##   Hot path: once per animated frame.  Constant: one scene refilled in place.
  ##     Allocates markup strings only; browser's parse of stage and readout dominates.
  template limits: untyped = lut_hold_sweep[hold][level].limits
  let has_scene = sceneOf(scene, lut_hold_sweep[hold][level].frames, turn)
  stage.innerHTML = if has_scene: sceneSvg(hold, level, scene) else: ""
  slider.value = jsStr(turn)
  let head = "<b>" & HOLDS[hold].name & "</b> · " & LEVEL_NAMES[level] & " · @ " &
    turnNum(turn) & " from " & HOLDS[hold].from_rest
  if not has_scene or not limits.does_rest_hold:
    readout.innerHTML = head & "<br>no pose holds at the rest"
    return

  # One line per rope: her arm's word, his where not open, crossings where any.
  let
    is_at_neg = turn <= -limits.neg + 1e-6 and limits.is_stopped_neg
    is_at_pos = turn >= limits.pos - 1e-6 and limits.is_stopped_pos
  var lines: cstring = ""
  for i in 0 ..< scene.cn_count:
    template c: untyped = scene.cn[i]
    template rope: untyped = HOLDS[hold].ropes[i]
    let name =
      if HOLDS[hold].is_pair: ARM_WORDS[rope.his] & " to " & INKS[rope.hers] & ": "
      else: cstring("")
    var crossing: cstring = ""
    if not c.cross.isUndefined:
      crossing = " <span class=\"say\">("
      for k in 0 ..< c.cross.length.to(int):
        if k > 0: crossing.add ", "
        crossing.add (if c.cross[k].over.to(int) == 0: cstring("the first") else: "the second") &
          " over"
      crossing.add ")</span>"
    lines.add "<br>" & name & "her arm <b>" & c.her_says & "</b>" &
      (if c.him_says != "open": ", his arm <b>" & c.him_says & "</b>" else: cstring("")) &
      crossing

  # Then strain, then both blocks, flagged where turn stands on one.
  lines.add "<br>strain <b>" & scene.strain.toFixed(2) & "</b>" &
    (if scene.worst.len > 0: " at " & scene.worst else: cstring("")) &
    (if scene.is_reseed: cstring(" <span class=\"say\">(the arms re-posed here)</span>") else: "")
  const UNSTOPPED: cstring = " (not within two turns)"
    ## Block's word where sweep ran out of range before any joint refused.
  var blocks = "blocks at " & turnNum(-limits.neg) &
    (if limits.is_stopped_neg: " (" & limits.why_neg & ")" else: UNSTOPPED) &
    " and " & turnNum(limits.pos) &
    (if limits.is_stopped_pos: " (" & limits.why_pos & ")" else: UNSTOPPED)
  if is_at_neg or is_at_pos:
    blocks = "<b class=\"bad\">blocked here</b> — " &
      (if is_at_neg: limits.why_neg else: limits.why_pos) & "; " & blocks
  lines.add "<br>" & blocks
  readout.innerHTML = head & lines


proc renderStrip() =
  ## Redraw strip of small figures: every half turn and both blocks, in order.
  template sweep: untyped = lut_hold_sweep[hold][level]
  var
    shown: array[STRIP_SLOTS, float]
    count = 0
  for h in -4 .. 4:
    shown[count] = float(h) / 2.0
    inc count
  if sweep.limits.is_stopped_neg:
    shown[count] = -sweep.limits.neg
    inc count
  if sweep.limits.is_stopped_pos:
    shown[count] = sweep.limits.pos
    inc count

  # Sort ascending; insertion suits eleven values and keeps equal ones in order.
  for i in 1 ..< count:
    var j = i
    while j > 0 and shown[j - 1] > shown[j]:
      swap(shown[j - 1], shown[j])
      dec j

  # One figure per turn: crossed out beyond blocks, else scene with sim's words.
  var html: cstring = ""
  for i in 0 ..< count:
    let
      t = shown[i]
      is_half = abs(t * 2.0 - floor(t * 2.0 + 0.5)) < 1e-6
    if t < -sweep.limits.neg - 1e-6 or t > sweep.limits.pos + 1e-6 or
        not sweep.limits.does_rest_hold:
      html.add "<figure class=\"mini blocked\" data-t=\"" & jsStr(t) &
        "\"><div class=\"x\">&#10005;</div><figcaption><b>@ " & turnWord(t) &
        "</b><br><span class=\"say\">blocked — " &
        (if t < 0.0: sweep.limits.why_neg else: sweep.limits.why_pos) &
        "</span></figcaption></figure>"
      continue
    doAssert sceneOf(scene, sweep.frames, t), "Sweep within its blocks must have moments."
    var words: cstring = ""
    for k in 0 ..< scene.cn_count:
      if k > 0: words.add " · "
      words.add scene.cn[k].her_says
    let
      is_rest = abs(t - HOLDS[hold].rest) < 1e-6
      is_limit = not is_half
    html.add "<figure class=\"mini" & (if is_limit: cstring(" limit") else: "") &
      "\" data-t=\"" & jsStr(t) & "\"><svg viewBox=\"-52 -56 104 112\" width=\"70\">" &
      sceneSvg(hold, level, scene) & "</svg>" & "<figcaption><b>@ " &
      (if is_half: turnWord(t) else: turnNum(t)) & "</b>" &
      (if is_rest: cstring(" rest") else: "") & (if is_limit: cstring(" the block") else: "") &
      "<br><span class=\"say\">" & words & "</span></figcaption></figure>"
  strip.innerHTML = html
  for figure in strip.querySelectorAll(".mini:not(.blocked)"):
    figure.addEventListener("click", proc (ev: Event) =
      is_playing = false
      target = parseFloat(ev.currentTarget.getAttribute("data-t")))


proc renderButtons() =
  ## Redraw hold and level buttons, marking those on show, and wire their clicks.
  var html: cstring = ""
  for h in Hold:
    html.add "<button class=\"" & (if h == hold: cstring("on") else: "") & "\" data-k=\"" &
      HOLDS[h].key & "\">" & HOLDS[h].name & "</button>"
  hold_box.innerHTML = html
  html = ""
  for l in Level:
    html.add "<button class=\"" & (if l == level: cstring("on") else: "") & "\" data-l=\"" &
      LEVEL_NAMES[l] & "\">" & LEVEL_NAMES[l] & "</button>"
  level_box.innerHTML = html
  for button in hold_box.querySelectorAll("button"):
    button.addEventListener("click", proc (ev: Event) =
      hold = holdOfKey(ev.currentTarget.getAttribute("data-k"))
      turn = clampT(HOLDS[hold].rest)
      target = turn
      renderButtons()
      renderStrip()
      renderStage())
  for button in level_box.querySelectorAll("button"):
    button.addEventListener("click", proc (ev: Event) =
      level = levelOfName(ev.currentTarget.getAttribute("data-l"))
      turn = clampT(turn)
      target = turn
      renderButtons()
      renderStrip()
      renderStage())


proc tick(now: float) =
  ## Advance one frame: sweep between blocks while playing, else ease toward `target`.
  ##   Redraws only when `turn` moved (Article VII.3); frame time capped at 50 ms.
  let dt = min(0.05, (now - last_now) / 1000.0)
  last_now = now
  if is_playing:
    template limits: untyped = lut_hold_sweep[hold][level].limits
    turn += direction * dt * 0.35
    if turn >= limits.pos:
      turn = limits.pos
      direction = -1.0
    elif turn <= -limits.neg:
      turn = -limits.neg
      direction = 1.0
    target = turn
    renderStage()
  elif abs(target - turn) > 0.002:
    let away = target - turn
    turn += (if away < 0.0: -1.0 else: 1.0) * min(abs(away), dt * 0.9)
    renderStage()
  discard window.requestAnimationFrame(tick)

proc start(now: float) =
  ## Seed frame clock on first frame, then tick: first `dt` is nought, as original's was.
  ##   Replaces original's `null` clock, sparing `Option[float]` and its copy per frame.
  last_now = now
  tick(now)


slider.addEventListener("input", proc (ev: Event) =
  is_playing = false
  turn = clampT(parseFloat(slider.value))
  target = turn
  renderStage())
document.getElementById("play").addEventListener("click", proc (ev: Event) =
  is_playing = not is_playing)
document.getElementById("to-rest").addEventListener("click", proc (ev: Event) =
  is_playing = false
  target = clampT(HOLDS[hold].rest))

renderButtons()
renderStrip()
renderStage()
discard window.requestAnimationFrame(start)
