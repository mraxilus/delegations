## Plan couple's arms through turn: at each moment, comfiest pose near last one that keeps
## hands joined, every capsule clear of every other, every joint inside its range, and
## joined hands inside their band.  Engine then springs every joint toward plan and judges.
##
##   Why plan at all: engine carries arms where weak pulls on hands leave them, and arms
##     caught on head or on each other stay caught.  Dancer chooses whole arm, and so does
##     plan: elbow, shoulder's roll, collarbone, waist and where to stand, each moment.
##   Plan is geometry alone, same capsules and ranges engine has (`rigid`), so engine
##     springing toward plan meets nothing plan did not already keep clear.
##   Continuity: each moment starts from last and may move no point of any arm further
##     than its style's leap, under arm's own thickness.  Engine, following, carries arms
##     between moments as solid capsules, so arm that would pass through arm is stopped
##     and judged there.

{.experimental: "strictFuncs".}

import std/math

import ./[body, hold, rig, vector]
from ./rigid import trunkCapsules, GIRDLE_RADIUS, Matrix, ArmPlacing


const
  PER_ARM* = 9 ## Freedoms of one arm: two of collarbone, three of shoulder, elbow, three of wrist.
  SIZE* = 4 + 4 * PER_ARM ## Apart, sideways (held nought), two waists, four arms.

type
  Plan* = array[SIZE, float] ## One pose of couple, as planner holds it.

  Capsule* = tuple[a, z: Vector, radius: float]

  Shape = object ## One capsule's owner, as engine's filters read it.
    who: Body
    arm: int        ## Arm index nought to three, or -1 for trunk.
    part: int       ## Nought girdle, one upper, two fore, three palm; -1 trunk.

  Style* = object ## How couple go about turn: one way among several planner tries.
    gather*: float ## Newtons per metre, as weight, drawing two joined pairs to one point.
    leap*: float   ## Metres any point of arm may move between two moments.
    stay*: float   ## Weight holding each moment near last one.
    seed*: int     ## Which of fixed starting poses rest is sought from.
    margin*: float ## Radians plan keeps inside every joint's end engine holds.
    room*: float   ## Metres plan keeps inside band judge holds hands to.
    clearance*: float ## Metres plan keeps between capsules: engine's own slop under it.
    slack*: float  ## Weight on keeping well clear of arms and band's edges, beyond margins.

  Problem* = object ## What one moment asks: hold, rest, band, style.
    style*: Style
    links*: seq[Link]
    is_away*: bool
    lower*, upper*: float ## Band joined hands are held to, metres.
    shapes: seq[Shape]
    pairs: seq[(int, int)]

const
  REST: Matrix = [[1.0, 0.0, 0.0], [0.0, -1.0, 0.0], [0.0, 0.0, -1.0]]
    ## Upper arm's frame at rest, body's terms: right, back, down (`rigid.restFrame`).
  ROOMY = 0.04 ## Metres plan would sooner keep from arms and band's edges, where it can.
  FACE_WINDOW = 0.1 ## Of way up within which plan holds hands at torso band: twice judge's
                    ## `rigid.FACING`, so engine following plan has hands down when judged.

func armIndex*(who: Body; arm: Arm): int = 2 * ord(who) + ord(arm)
  ## Arm's place in plan: lead's left, lead's right, follow's left, follow's right.

func times(a, b: Matrix): Matrix =
  for i in 0 .. 2:
    for j in 0 .. 2:
      for k in 0 .. 2:
        result[i][j] += a[i][k] * b[k][j]

func transposed(a: Matrix): Matrix =
  for i in 0 .. 2:
    for j in 0 .. 2:
      result[i][j] = a[j][i]

func apply(a: Matrix; v: Vector): Vector =
  (a[0][0] * v.x + a[0][1] * v.y + a[0][2] * v.z,
   a[1][0] * v.x + a[1][1] * v.y + a[1][2] * v.z,
   a[2][0] * v.x + a[2][1] * v.y + a[2][2] * v.z)

func column(a: Matrix; j: int): Vector = (a[0][j], a[1][j], a[2][j])

func aboutUp(angle: float): Matrix =
  [[cos(angle), -sin(angle), 0.0], [sin(angle), cos(angle), 0.0], [0.0, 0.0, 1.0]]

func aboutFore(angle: float): Matrix =
  [[cos(angle), 0.0, sin(angle)], [0.0, 1.0, 0.0], [-sin(angle), 0.0, cos(angle)]]

func aboutRight(angle: float): Matrix =
  [[1.0, 0.0, 0.0], [0.0, cos(angle), -sin(angle)], [0.0, sin(angle), cos(angle)]]

func turnAbout*(x, y, z: float): Matrix =
  ## Rodrigues: turn about vector by its length.
  let angle = sqrt(x * x + y * y + z * z)
  result = [[1.0, 0, 0], [0.0, 1, 0], [0.0, 0, 1]]
  if angle < 1e-12: return
  let
    k = [x / angle, y / angle, z / angle]
    skew: Matrix = [[0.0, -k[2], k[1]], [k[2], 0.0, -k[0]], [-k[1], k[0], 0.0]]
    square = times(skew, skew)
  for i in 0 .. 2:
    for j in 0 .. 2:
      result[i][j] += sin(angle) * skew[i][j] + (1.0 - cos(angle)) * square[i][j]

func shoulderTurn*(plan: Plan; i: int): Matrix =
  ## Upper arm's turn from rest in frame of its girdle: what engine's ball reads.
  let base = 4 + PER_ARM * i
  times(transposed(REST), times(turnAbout(plan[base + 2], plan[base + 3], plan[base + 4]), REST))

func wristTurn*(plan: Plan; i: int): Matrix =
  ## Hand's turn in frame of its forearm: what engine's wrist reads.
  let base = 4 + PER_ARM * i
  turnAbout(plan[base + 6], plan[base + 7], plan[base + 8])

func twistOf(turn: Matrix): float = arctan2(turn[1][0] - turn[0][1], turn[0][0] + turn[1][1])
  ## Engine's twist of ball's turn about its own z (`b3GetTwistAngle`).


type
  ArmPlaced* = object ## One arm placed in world, and what its joints read.
    shoulder*, elbow*, wrist*, grip*: Vector
    capsules*: array[4, Capsule]
    twist*, bend*, cone*, extend*, protract*, elevate*: float

  Placed* = object ## Whole couple placed.
    arms*: array[4, ArmPlaced]
    trunks*: array[Body, seq[Capsule]]


func facingOf*(plan: Plan; who: Body; wind: float; is_away: bool): float =
  ## Way chest faces: lead along y, follow back along it, follow turned by wind.
  if who == Body.One: PI / 2.0 + plan[2]
  else: -PI / 2.0 + 2.0 * PI * wind + (if is_away: PI else: 0.0) + plan[3]

func place*(rig: Rig; plan: Plan; wind: float; is_away: bool): Placed =
  ## Every capsule and joint reading of couple at this plan and wind.
  let neck = halfBreadth(rig, Part.Neck)
  for who in Body:
    let
      facing = facingOf(plan, who, wind, is_away)
      origin: Vector = (if who == Body.One: (0.0, 0.0, 0.0) else: (plan[1], plan[0], 0.0))
      right: Vector = (sin(facing), -cos(facing), 0.0)
      fore: Vector = (cos(facing), sin(facing), 0.0)
    func world(p: Vector): Vector = origin + right * p.x + fore * p.y + (0.0, 0.0, p.z)
    for (a, z, radius) in trunkCapsules(rig):
      result.trunks[who].add (world(a), world(z), radius)
    for arm in Arm:
      let
        i = armIndex(who, arm)
        base = 4 + PER_ARM * i
        sd = side(arm)
        root: Vector = (sd * neck, 0.0, rig.top[Part.Torso])
        reach: Vector = (sd * (rig.shoulder_out - neck), 0.0, rig.shoulder_up - rig.top[Part.Torso])
        girdle = times(aboutUp(sd * plan[base]), aboutFore(-sd * plan[base + 1]))
        shoulder = root + apply(girdle, reach)
        upper = times(girdle,
                      times(turnAbout(plan[base + 2], plan[base + 3], plan[base + 4]), REST))
        elbow = shoulder + column(upper, 2) * rig.upper
        forearm = times(upper, aboutRight(plan[base + 5]))
        wrist = elbow + column(forearm, 2) * rig.fore
        hand = times(forearm, wristTurn(plan, i))
        grip = wrist + column(hand, 2) * rig.hand
        direction = column(upper, 2)
      var placed: ArmPlaced
      placed.shoulder = world(shoulder)
      placed.elbow = world(elbow)
      placed.wrist = world(wrist)
      placed.grip = world(grip)
      placed.capsules = [
        (world(root), world(shoulder), GIRDLE_RADIUS),
        (world(shoulder + direction * rig.limb),
         world(shoulder + direction * (rig.upper - rig.limb)),
         rig.limb),
        (world(elbow + column(forearm, 2) * rig.limb),
         world(elbow + column(forearm, 2) * (rig.fore - rig.limb)), rig.limb),
        (world(wrist + column(hand, 2) * (rig.hand / 2.0)),
         world(wrist + column(hand, 2) * (rig.hand / 2.0)), rig.hand / 2.0),
      ]
      placed.twist = twistOf(shoulderTurn(plan, i))
      placed.bend = plan[base + 5]
      placed.cone = arccos(clamp(dot(column(forearm, 2), column(hand, 2)), -1.0, 1.0))
      placed.extend = arcsin(clamp(-direction.y, -1.0, 1.0))
      placed.protract = plan[base]
      placed.elevate = plan[base + 1]
      result.arms[i] = placed

func pairsOf*(problem: Problem): seq[(int, int)] = problem.pairs
  ## Every pair of capsules engine collides, by index into `capsulesOf`.

func capsulesOf*(placed: Placed): seq[Capsule] =
  ## Every capsule, trunks first, then each arm's girdle, upper, fore, palm.
  for who in Body:
    for capsule in placed.trunks[who]: result.add capsule
  for i in 0 .. 3:
    for capsule in placed.arms[i].capsules: result.add capsule


func problemOf*(rig: Rig; links: seq[Link]; is_away: bool): Problem =
  ## Hold, and every pair of capsules engine collides, by its own filters.
  result = Problem(links: links, is_away: is_away, lower: 0.0, upper: 3.0)
  for who in Body:
    for _ in trunkCapsules(rig):
      result.shapes.add Shape(who: who, arm: -1, part: -1)
  for i in 0 .. 3:
    for part in 0 .. 3:
      result.shapes.add Shape(who: (if i < 2: Body.One else: Body.Two), arm: i, part: part)
  var joined: seq[(int, int)]
  for link in links:
    let
      a = armIndex(link.ends[0].body, link.ends[0].arm)
      b = armIndex(link.ends[1].body, link.ends[1].arm)
    joined.add (a, b)
    joined.add (b, a)
  for i in 0 ..< result.shapes.len:
    for j in i + 1 ..< result.shapes.len:
      let (p, q) = (result.shapes[i], result.shapes[j])
      # Own trunk and own girdles share one group.
      if p.who == q.who and (p.arm < 0 or p.part == 0) and (q.arm < 0 or q.part == 0):
        continue
      # One arm's own links never meet; girdle meets them but not upper arm it holds.
      if p.arm >= 0 and p.arm == q.arm:
        if p.part != 0 and q.part != 0: continue
        if (p.part == 0 and q.part == 1) or (p.part == 1 and q.part == 0): continue
      # Joined palms are one joint apart.
      if p.part == 3 and q.part == 3 and (p.arm, q.arm) in joined: continue
      result.pairs.add (i, j)


func ease(value, lower, upper, ease_lower, ease_upper: float): float =
  ## Squared fraction into either ease band: comfort's cost.
  var cost = 0.0
  if ease_upper > 0.0: cost += max(0.0, value - (upper - ease_upper)) / ease_upper
  if ease_lower > 0.0: cost += max(0.0, (lower + ease_lower) - value) / ease_lower
  cost * cost

func twistEnds(rig: Rig; i: int): (float, float) =
  ## Rig states right arm's ends; left arm's are mirrored.
  let twist_range = rig.range[Dof.Twist]
  if i mod 2 == 1: (twist_range.lower, twist_range.upper)
  else: (-twist_range.upper, -twist_range.lower)

func comfort*(rig: Rig; placed: Placed; plan: Plan): float =
  ## Sum of every joint's squared way into its ease, as `rigid.strainOf` reads them.
  let
    twist_range = rig.range[Dof.Twist]
    bend_range = rig.range[Dof.Bend]
    wrist_range = rig.range[Dof.Wrist]
    extend_range = rig.range[Dof.Extend]
  for i in 0 .. 3:
    let
      a = placed.arms[i]
      (lower, upper) = twistEnds(rig, i)
    result += ease(a.twist, lower, upper, twist_range.ease_lower, twist_range.ease_upper)
    result += ease(a.bend, bend_range.lower, bend_range.upper, 0.0, bend_range.ease_upper)
    result += ease(a.cone, 0.0, wrist_range.upper, 0.0, wrist_range.ease_upper)
    result += ease(a.extend, -PI, extend_range.upper, 0.0, extend_range.ease_upper)
    for (value, collar) in [(a.protract, rig.collar[Collar.Fore]),
                            (a.elevate, rig.collar[Collar.Up])]:
      result += ease(value, collar.lower, collar.upper, collar.ease_lower, collar.ease_upper)
  for w in [plan[2], plan[3]]:
    result += ease(w, rig.waist.lower, rig.waist.upper, rig.waist.ease_lower, rig.waist.ease_upper)

func cramped*(rig: Rig; problem: Problem; placed: Placed): float =
  ## How near this pose sits to what it must keep, inside its margins: capsules nearer
  ## than `ROOMY` and joined hands nearer band's edge than `ROOMY` cost by square.
  let capsules = capsulesOf(placed)
  for (i, j) in problem.pairs:
    let
      p = capsules[i]
      q = capsules[j]
      gap = closest(p.a, p.z, q.a, q.z).gap - p.radius - q.radius
    if gap < ROOMY: result += (ROOMY - gap) ^ 2
  for link in problem.links:
    for hand in link.ends:
      let z = placed.arms[armIndex(hand.body, hand.arm)].grip.z
      result += max(0.0, problem.lower + ROOMY - z) ^ 2 + max(0.0, z - problem.upper + ROOMY) ^ 2

func violation*(rig: Rig; problem: Problem; placed: Placed; before: seq[Capsule]): float =
  ## Sum of squares by which this pose breaks what plan must keep.
  let capsules = capsulesOf(placed)
  for link in problem.links:
    let
      a = placed.arms[armIndex(link.ends[0].body, link.ends[0].arm)].grip
      b = placed.arms[armIndex(link.ends[1].body, link.ends[1].arm)].grip
      apart = distance(a, b)
    result += apart * apart
    for grip in [a, b]:
      result += max(0.0, problem.lower - grip.z) ^ 2 + max(0.0, grip.z - problem.upper) ^ 2
  for (i, j) in problem.pairs:
    let
      p = capsules[i]
      q = capsules[j]
      gap = closest(p.a, p.z, q.a, q.z).gap - p.radius - q.radius
    if gap < problem.style.clearance: result += (problem.style.clearance - gap) ^ 2
  for i in 0 .. 3:
    let
      a = placed.arms[i]
      (lower, upper) = twistEnds(rig, i)
    result += max(0.0, lower + problem.style.margin - a.twist) ^ 2 +
              max(0.0, a.twist - upper + problem.style.margin) ^ 2
    result += max(0.0, a.cone - rig.range[Dof.Wrist].upper + problem.style.margin) ^ 2
    result += max(0.0, a.extend - rig.range[Dof.Extend].upper + problem.style.margin) ^ 2
  if before.len > 0:
    let first_arm = 2 * trunkCapsules(rig).len
    for k in first_arm ..< capsules.len:
      for (now, then) in [(capsules[k].a, before[k].a), (capsules[k].z, before[k].z)]:
        result += max(0.0, distance(now, then) - problem.style.leap) ^ 2


type Bounds = array[SIZE, (float, float)]

func boundsOf(rig: Rig; margin: float): Bounds =
  ## Each freedom's ends: collarbones, waists and elbow at engine's own, sideways held nought.
  let near = touching(rig) + 0.10
  result[0] = (near, near + 1.0)
  result[1] = (0.0, 0.0)
  result[2] = (rig.waist.lower, rig.waist.upper)
  result[3] = (rig.waist.lower, rig.waist.upper)
  for i in 0 .. 3:
    let
      base = 4 + PER_ARM * i
      (fore, up) = (rig.collar[Collar.Fore], rig.collar[Collar.Up])
    result[base] = (fore.lower, fore.upper)
    result[base + 1] = (up.lower, up.upper)
    for k in [2, 3, 4, 6, 7, 8]: result[base + k] = (-7.0, 7.0)
    result[base + 5] = (rig.range[Dof.Bend].lower, rig.range[Dof.Bend].upper - margin)

func clamped(plan: Plan; bounds: Bounds): Plan =
  for k in 0 ..< SIZE: result[k] = clamp(plan[k], bounds[k][0], bounds[k][1])


type Solved* = object ## One moment planned.
  plan*: Plan
  broken*: float ## Violation left: nought kept everything.
  cost*: float   ## Comfort there.

proc solve*(rig: Rig; problem: Problem; start, last: Plan; wind: float; before: seq[Capsule];
            stay = -1.0; iterations = 200; bias: Plan = default(Plan)): Solved =
  ## Comfiest pose near `last`, by penalty on what must be kept, on growing weight.
  ##   Limited-memory quasi-Newton on numerical gradient, bounds by clamping.
  let
    bounds = boundsOf(rig, problem.style.margin)
    holding = (if stay >= 0.0: stay else: problem.style.stay)
  var x = clamped(start, bounds)
  for stage in 0 .. 2:
    let weight = [1e3, 1e5, 1e7][stage]
    proc cost(y: Plan): float =
      let placed = place(rig, y, wind, problem.is_away)
      result = comfort(rig, placed, y) + weight * violation(rig, problem, placed, before)
      for k in 0 ..< SIZE: result += holding * (y[k] - last[k]) ^ 2 + bias[k] * y[k]
      if problem.style.slack > 0.0:
        result += problem.style.slack * cramped(rig, problem, placed)
      if problem.style.gather > 0.0 and problem.links.len == 2:
        let
          (one, two) = (problem.links[0].ends[0], problem.links[1].ends[0])
          first = placed.arms[armIndex(one.body, one.arm)].grip
          second = placed.arms[armIndex(two.body, two.arm)].grip
        result += problem.style.gather * distance(first, second) ^ 2
    proc gradient(y: Plan; at: float): Plan =
      for k in 0 ..< SIZE:
        if bounds[k][0] == bounds[k][1]: continue
        var z = y
        z[k] += 1e-7
        result[k] = (cost(z) - at) / 1e-7
    const MEMORY = 8
    var
      steps: seq[Plan]
      changes: seq[Plan]
      fx = cost(x)
      g = gradient(x, fx)
    for iteration in 0 ..< iterations:
      # Two-loop recursion for search direction.
      var
        q = g
        alphas = newSeq[float](steps.len)
      for m in countdown(steps.len - 1, 0):
        var sy, sq = 0.0
        for k in 0 ..< SIZE:
          sy += steps[m][k] * changes[m][k]
          sq += steps[m][k] * q[k]
        alphas[m] = sq / sy
        for k in 0 ..< SIZE: q[k] -= alphas[m] * changes[m][k]
      if steps.len > 0:
        var sy, yy = 0.0
        for k in 0 ..< SIZE:
          sy += steps[^1][k] * changes[^1][k]
          yy += changes[^1][k] * changes[^1][k]
        for k in 0 ..< SIZE: q[k] *= sy / yy
      for m in 0 ..< steps.len:
        var yq, sy = 0.0
        for k in 0 ..< SIZE:
          yq += changes[m][k] * q[k]
          sy += steps[m][k] * changes[m][k]
        let beta = yq / sy
        for k in 0 ..< SIZE: q[k] += steps[m][k] * (alphas[m] - beta)
      var slope = 0.0
      for k in 0 ..< SIZE: slope -= g[k] * q[k]
      if slope >= 0.0:
        # Not descent: forget history, fall back to steepest descent.
        steps.setLen 0
        changes.setLen 0
        q = g
        slope = 0.0
        for k in 0 ..< SIZE: slope -= g[k] * g[k]
      # Backtracking line search.
      var
        length = (if steps.len == 0: min(1.0, 0.1 / max(1e-12, sqrt(-slope))) else: 1.0)
        is_accepted = false
        y: Plan
        fy: float
      for tries in 0 ..< 30:
        for k in 0 ..< SIZE: y[k] = x[k] - length * q[k]
        y = clamped(y, bounds)
        fy = cost(y)
        if fy <= fx + 1e-4 * length * slope:
          is_accepted = true
          break
        length *= 0.5
      if not is_accepted: break
      let gy = gradient(y, fy)
      var
        step, change: Plan
        curvature = 0.0
      for k in 0 ..< SIZE:
        step[k] = y[k] - x[k]
        change[k] = gy[k] - g[k]
        curvature += step[k] * change[k]
      if curvature > 1e-12:
        steps.add step
        changes.add change
        if steps.len > MEMORY:
          steps.delete 0
          changes.delete 0
      let improvement = fx - fy
      x = y
      fx = fy
      g = gy
      if improvement < 1e-12 * max(1.0, abs(fx)): break
  result.plan = x
  let placed = place(rig, x, wind, problem.is_away)
  result.broken = violation(rig, problem, placed, before)
  result.cost = comfort(rig, placed, x)



#[ Path ]#

const
  KEPT* = 1e-6 ## Violation under which plan counts as keeping everything: millimetre squared.
  STRIDE* = 0.02 ## Turns between two moments of plan, as walk's own step.

type Path* = object ## Planned turn: one pose per moment, and how far it got.
  winds*: seq[float]
  plans*: seq[Plan]
  is_reached*: bool
  problem*: Problem ## What was planned, so moment can be planned again from engine's pose.
  direction*: float

func awayOf(wind: float; is_away: bool): float =
  ## How far couple are from face to face, turns, nought to half.
  let turned = floorMod(wind + (if is_away: 0.5 else: 0.0), 1.0)
  min(turned, 1.0 - turned)

func bandAt*(rig: Rig; wind, direction: float; is_away: bool; room: float):
    tuple[lower, upper: float] =
  ## Band plan holds joined hands to: judge's own where judge reads it, with margin, and
  ## continuous between, as carry lets hands down and lifts them.
  ##   Facing (`rigid.FACING` of way up): torso band and its slack.  Risen going up, from
  ##     quarter turn away: crown band less its sag.  Coming back, crown band to half way.
  let
    torso = rig.band[Band.Torso]
    crown = rig.band[Band.Crown]
    low_torso = torso.lower - 0.03 + room
    high_torso = torso.upper + 0.05 - room
    low_crown = crown.lower - 0.03 + room
    high_crown = crown.upper - room
    up = min(1.0, awayOf(wind, is_away) / 0.25)
    turned = floorMod(wind + (if is_away: 0.5 else: 0.0), 1.0)
    is_leaving = abs(wind) < 1e-9 or ((turned < 0.5) == (direction > 0.0))
  const window = FACE_WINDOW
  if up <= window: return (low_torso, high_torso)
  if is_leaving:
    (low_torso + (low_crown - low_torso) * clamp((up - window) / (1.0 - window), 0.0, 1.0),
     high_torso + (high_crown - high_torso) * clamp((up - window) / 0.2, 0.0, 1.0))
  else:
    (low_torso + (low_crown - low_torso) * clamp((up - window) / (0.5 - window), 0.0, 1.0),
     high_torso + (high_crown - high_torso) * clamp((up - window) / (0.5 - window), 0.0, 1.0))

func spread(x: float): float = x - floor(x)
  ## Fractional part: deterministic scatter for starts and nudges.

func hanging*(apart: float): Plan =
  ## Every arm hanging, elbow soft, couple `apart` metres axis to axis.
  result[0] = apart
  for i in 0 .. 3: result[4 + PER_ARM * i + 5] = 30.0 * PI / 180.0

proc restOf*(rig: Rig; problem: var Problem; tries = 8): tuple[plan: Plan, broken: float] =
  ## Comfiest rest pose found from several starts: couple stand where rest sits easiest.
  ##   Starts are fixed, so plan is same on every build and every core.
  let (lower, upper) = bandAt(rig, 0.0, 1.0, problem.is_away, problem.style.room)
  problem.lower = lower
  problem.upper = upper
  result.broken = Inf
  var best = Inf
  for k in 0 ..< tries:
    var start = hanging(0.45 + 0.06 * float((k + problem.style.seed) mod tries))
    # Deterministic spread of starting arms, by golden ratio.
    for j in 4 ..< SIZE:
      start[j] += 0.4 *
                  (spread(float(j * (k + 1 + 17 * problem.style.seed)) * 0.6180339887) - 0.5) *
                  float(min(k + problem.style.seed, 1))
    let solved = solve(rig, problem, start, start, 0.0, @[], stay = 0.0, iterations = 400)
    if solved.broken < KEPT and solved.cost < best:
      best = solved.cost
      result = (solved.plan, solved.broken)

proc planPath*(rig: Rig; links: seq[Link]; is_away: bool; turns: float; style: Style): Path =
  ## Plan couple from rest to `turns` of wind, moment by moment, as far as plan keeps
  ## everything.  Stuck, it backs off, nudges arms at standing wind and tries again.
  var problem = problemOf(rig, links, is_away)
  problem.style = style
  let rest = restOf(rig, problem)
  if rest.broken >= KEPT: return
  let direction = (if turns >= 0.0: 1.0 else: -1.0)
  result.problem = problem
  result.direction = direction
  result.winds = @[0.0]
  result.plans = @[rest.plan]
  var
    stride = STRIDE
    failures = 0
    bias: Plan
    biased = 0
  while abs(result.winds[^1]) < abs(turns) - 1e-9:
    if biased > 0:
      dec biased
      if biased == 0: bias = default(Plan)
    let
      wind = result.winds[^1]
      last = result.plans[^1]
      target = wind + direction * min(stride, abs(turns) - abs(wind))
      (lower, upper) = bandAt(rig, target, direction, is_away, style.room)
    problem.lower = lower
    problem.upper = upper
    let
      before = capsulesOf(place(rig, last, wind, is_away))
      solved = solve(rig, problem, last, last, target, before, bias = bias)
    if solved.broken < KEPT:
      result.winds.add target
      result.plans.add solved.plan
      stride = min(STRIDE, stride * 2.0)
      continue
    if stride > STRIDE / 16.0:
      stride /= 2.0
      continue
    inc failures
    if failures > 24: return
    # Every third time stuck, go back to last moment couple faced and rearrange arms there
    # at standing wind, many leaps, before going on: way down into facing decides way up.
    if failures mod 3 == 0:
      var facing_at = -1
      for k in countdown(result.winds.len - 1, 0):
        if min(1.0, awayOf(result.winds[k], is_away) / 0.25) <= FACE_WINDOW:
          facing_at = k
          break
      if facing_at > 0:
        result.winds.setLen(facing_at + 1)
        result.plans.setLen(facing_at + 1)
        let
          at = result.winds[^1]
          (lower_at, upper_at) = bandAt(rig, at, direction, is_away, style.room)
        problem.lower = lower_at
        problem.upper = upper_at
        for walk in 0 ..< 12:
          var start = result.plans[^1]
          for j in 4 ..< SIZE:
            start[j] += 0.3 * (spread(float(j * (walk + 5) + 31 * failures +
                                            17 * problem.style.seed) * 0.6180339887) - 0.5) * 2.0
          let
            here = capsulesOf(place(rig, result.plans[^1], at, is_away))
            moved = solve(rig, problem, start, result.plans[^1], at, here, stay = 0.0)
          if moved.broken < KEPT:
            result.winds.add at
            result.plans.add moved.plan
        stride = STRIDE
        continue
    # Back off, and nudge arms at that wind within one leap.
    let back = min(result.winds.len - 1, 2 * failures)
    result.winds.setLen(result.winds.len - back)
    result.plans.setLen(result.plans.len - back)
    let
      at = result.winds[^1]
      (lower_at, upper_at) = bandAt(rig, at, direction, is_away, style.room)
    problem.lower = lower_at
    problem.upper = upper_at
    for nudge in 0 ..< 4:
      var start = result.plans[^1]
      for j in 4 ..< SIZE:
        start[j] += 0.1 * sqrt(float(failures)) *
                    (spread(float(j * (nudge + 7 * failures)) * 0.7548776662) - 0.5) * 2.0
      let
        here = capsulesOf(place(rig, result.plans[^1], at, is_away))
        nudged = solve(rig, problem, start, result.plans[^1], at, here, stay = 0.02)
      if nudged.broken < KEPT:
        result.winds.add at
        result.plans.add nudged.plan
    for j in 4 ..< SIZE:
      bias[j] = 0.02 * float(failures) *
                (spread(float(j * (3 + 11 * failures + 13 * problem.style.seed)) *
                        0.5698402910) - 0.5) * 2.0
    biased = 15
    stride = STRIDE
  result.is_reached = true


proc corrected*(rig: Rig; path: Path; i: int; now: Plan): Plan =
  ## Moment `i` of path planned again from pose engine actually holds: nearest pose to
  ## plan's that keeps everything, one leap from where couple are, or plan's own where
  ## none is found.
  ##   Planned again from engine's own pose, so engine's drift from plan is answered at
  ##     each moment rather than carried to next.
  var problem = path.problem
  let
    wind = path.winds[i]
    (lower, upper) = bandAt(rig, wind, path.direction, problem.is_away, problem.style.room)
  problem.lower = lower
  problem.upper = upper
  let
    before = capsulesOf(place(rig, now, path.winds[max(0, i - 1)], problem.is_away))
    solved = solve(rig, problem, now, path.plans[i], wind, before)
  if solved.broken < KEPT: solved.plan else: path.plans[i]


#[ Mirror ]#

func mirrored*(plan: Plan): Plan =
  ## Same pose seen in mirror across couple's line: each dancer's left arm is their right.
  ##   Reflection `M` flips body's right.  Collarbone's two angles are unchanged by it,
  ##     elbow too, and turn `R(v)` becomes `M R M = R(-M v)`, so shoulder's and wrist's
  ##     vectors keep x and change sign in y and z.  Waists turn other way.
  result[0] = plan[0]
  result[1] = -plan[1]
  result[2] = -plan[2]
  result[3] = -plan[3]
  for i in 0 .. 3:
    let
      from_base = 4 + PER_ARM * i
      to_base = 4 + PER_ARM * (i xor 1)
    result[to_base] = plan[from_base]
    result[to_base + 1] = plan[from_base + 1]
    result[to_base + 2] = plan[from_base + 2]
    result[to_base + 3] = -plan[from_base + 3]
    result[to_base + 4] = -plan[from_base + 4]
    result[to_base + 5] = plan[from_base + 5]
    result[to_base + 6] = plan[from_base + 6]
    result[to_base + 7] = -plan[from_base + 7]
    result[to_base + 8] = -plan[from_base + 8]

func mirrored*(link: Link): Link =
  ## One connection seen in mirror: each hand on other arm.
  for k in 0 .. 1:
    result.ends[k] = (link.ends[k].body,
                      (if link.ends[k].arm == Arm.Left: Arm.Right else: Arm.Left))

func isMirrorSame*(links: seq[Link]): bool =
  ## Whether hold seen in mirror is same hold: true of both two-hand holds, not single ones.
  for link in links:
    let image = mirrored(link)
    var is_found = false
    for other in links:
      if (other.ends[0] == image.ends[0] and other.ends[1] == image.ends[1]) or
         (other.ends[0] == image.ends[1] and other.ends[1] == image.ends[0]):
        is_found = true
    if not is_found: return false
  true

func mirrored*(path: Path): Path =
  ## Planned turn seen in mirror: same couple winding other way.
  result = path
  result.direction = -path.direction
  for i in 0 ..< path.winds.len:
    result.winds[i] = -path.winds[i]
    result.plans[i] = mirrored(path.plans[i])


func placings*(rig: Rig; plan: Plan; wind: float; is_away: bool):
    tuple[chests: array[Body, Stance], arms: array[4, ArmPlacing]] =
  ## Where every body of couple stands at this plan, as engine places bodies: what
  ## `rigid.placeBodies` is handed so couple start where plan starts.
  let neck = halfBreadth(rig, Part.Neck)
  const TRUNK_AXES: Matrix = [[1.0, 0.0, 0.0], [0.0, 0.0, -1.0], [0.0, 1.0, 0.0]]
    ## Trunk's and girdle's own axes in body's terms: right, up, back (`rigid.standing`).
  for who in Body:
    let
      facing = facingOf(plan, who, wind, is_away)
      origin: Vector = (if who == Body.One: (0.0, 0.0, 0.0) else: (plan[1], plan[0], 0.0))
      right: Vector = (sin(facing), -cos(facing), 0.0)
      fore: Vector = (cos(facing), sin(facing), 0.0)
      world: Matrix = [[right.x, fore.x, 0.0], [right.y, fore.y, 0.0], [0.0, 0.0, 1.0]]
    result.chests[who] = Stance(centre: (origin.x, origin.y), facing: facing)
    func toWorld(p: Vector): Vector = origin + right * p.x + fore * p.y + (0.0, 0.0, p.z)
    for arm in Arm:
      let
        i = armIndex(who, arm)
        base = 4 + PER_ARM * i
        sd = side(arm)
        root: Vector = (sd * neck, 0.0, rig.top[Part.Torso])
        reach: Vector = (sd * (rig.shoulder_out - neck), 0.0, rig.shoulder_up - rig.top[Part.Torso])
        collar = aboutUp(sd * plan[base])
        girdle = times(collar, aboutFore(-sd * plan[base + 1]))
        shoulder = root + apply(girdle, reach)
        upper = times(girdle,
                      times(turnAbout(plan[base + 2], plan[base + 3], plan[base + 4]), REST))
        elbow = shoulder + column(upper, 2) * rig.upper
        forearm = times(upper, aboutRight(plan[base + 5]))
        wrist = elbow + column(forearm, 2) * rig.fore
        hand = times(forearm, wristTurn(plan, i))
      result.arms[i] = ArmPlacing(
        root: toWorld(root), shoulder: toWorld(shoulder), elbow: toWorld(elbow),
        wrist: toWorld(wrist),
        collar: times(world, times(collar, TRUNK_AXES)),
        girdle: times(world, times(girdle, TRUNK_AXES)),
        upper: times(world, upper), fore: times(world, forearm), palm: times(world, hand))
