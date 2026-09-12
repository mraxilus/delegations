## Two dancers in rigid body engine, and what turning one of them does to their arms.
##
##   Solver this replaces proposed poses and checked them, with no motion between two
##     of them, so arms could never slide along one another and chain wound to one
##     crossing and stopped.  Here arms are bodies with mass, on joints with ends, and
##     turn is motion: sliding is what engine does rather than what it cannot say.
##   Engine stands Y up and project stands Z up.  `sim/engine` holds no translation on
##     purpose, so this module is that one place.  `asEngine` and `asWorld` are only
##     two doors between them and both are rotations, never swaps of two axes: swap
##     mirrors world, and mirrored swan is other-handed swan.
##   Joint axes are engine's own convention, read off its source rather than guessed.
##     Spherical joint twists about frame B's local z and cones about frame A's local
##     z; revolute joint hinges about frame A's local z.  So every link is built with
##     its own length along its local z, which puts humeral rotation onto shoulder's
##     twist by construction.
##   What each joint may do comes from `sim/rig`, which is tape and clinical tables.
##     Engine holds elbow's hinge and wrist's cone exactly.  Shoulder's swing it
##     cannot: rig gives extension and adduction as two ranges of their own, engine
##     offers one cone about rest.  Cone is left off rather than invented, and swing is
##     read back off pose and judged against rig.  Leaving it off also leaves arm's
##     elevation free, for which rig gives no range either.  Over crown, then, where
##     arms are clear of both bodies and swing is nowhere near its ends, twist is only
##     thing left to run out -- which is what Architect reports of dancing it.
##   Twist's ends are stated for right arm, in negative and out positive.  Left arm is
##     same joint seen in mirror, so its frame is not mirrored -- that would turn its
##     elbow backwards -- and its two ends are swapped instead.
##   Torso's section is stadium rather than ellipse: engine collides capsules, and two
##     of them side by side give stadium of same tape round at same flatness.  Neck and
##     head fall out of same formula, flatness of one leaving one capsule.

{.experimental: "strictFuncs".}

import std/math

import ./[body, hold, limb, rig, vec]
from ./engine as eng import nil


const
  HERTZ* = 240.0      ## Steps per second.  Arm is short and stiff; slower step lets
                      ## grip joint stretch before solver catches it.
  SUBSTEPS* = 8.cint  ## Engine's own inner steps, where joint limits are met.
  DENSITY = 1000.0    ## Flesh is about water, so links weigh what arms weigh.
  DAMP = 4.0          ## Linear and angular damping: arms settle, never ring.
  PARTED* = 0.02      ## Hands this far apart, in metres, are no longer joined.
  AT_END* = 0.02      ## Joint within this of its end, in radians, is at its end.
  SETTLE* = 3000      ## Steps given to first pose before anything is read off it.
                      ## Measured: twist still moving at 1000, settled by 3000.
  CLEAR* = 0.10       ## Least clear air between two torsos, metres.
  PACE* = 0.01        ## Couple step in or out by this, looking for room.
  EASE* = 1.0         ## Hertz of spring holding each joint toward its rest.
  EASE_DAMP* = 1.0    ## And its damping.  Soft: it biases pose, never drives it.


type
  Limb* {.pure.} = enum ## Three links of one arm, shoulder outward.
    Upper, Fore, Palm

  ArmRig = object ## One arm's bodies and its three joints.
    link: array[Limb, eng.BodyId]
    shoulder, elbow, wrist: eng.JointId

  Figure = object ## One dancer: trunk that is turned, and two arms that follow.
    trunk: eng.BodyId
    arm: array[Arm, ArmRig]

  Couple* = object ## Both dancers, their world, and connections between their hands.
    world: eng.WorldId
    rig*: Rig
    stance*: array[Body, Stance]
    band*: Band
    links*: seq[Link]
    who: array[Body, Figure]
    grip: seq[eng.JointId]

  Pose* = object ## Where one connection's two arms lie, and what their joints read.
    arms*: array[2, ArmPose]
    twist*, bend*, wrist*: array[2, float] ## Each arm's three joints, radians.
    apart*: float ## How far engine has pulled two hands apart, metres.


#[ Doors between project's world and engine's ]#

func asEngine(p: Vec): eng.Vec = eng.vec(p.x, p.z, -p.y)
  ## Project's Z up into engine's Y up.  Rotation, so handedness survives.

func asWorld(v: eng.Vec): Vec = (v.x.float, -v.z.float, v.y.float)
  ## And back.

func asWorld(p: eng.Pos): Vec =
  let (x, y, z) = eng.at(p)
  (x, -z, y)

func asPlace(p: Vec): eng.Pos = eng.Pos(x: p.x, y: p.z, z: -p.y)


#[ Turns, as engine keeps them ]#

func qOf(x, y, z: eng.Vec): eng.Quat =
  ## Turn whose frame these three units are, given in parent's terms.
  let trace = x.x + y.y + z.z
  if trace > 0.0:
    let s = sqrt(trace + 1.0) * 2.0
    eng.Quat(v: eng.vec((y.z - z.y) / s, (z.x - x.z) / s, (x.y - y.x) / s),
             s: (0.25 * s).cfloat)
  elif x.x > y.y and x.x > z.z:
    let s = sqrt(1.0 + x.x - y.y - z.z) * 2.0
    eng.Quat(v: eng.vec(0.25 * s, (y.x + x.y) / s, (z.x + x.z) / s),
             s: ((y.z - z.y) / s).cfloat)
  elif y.y > z.z:
    let s = sqrt(1.0 + y.y - x.x - z.z) * 2.0
    eng.Quat(v: eng.vec((y.x + x.y) / s, 0.25 * s, (z.y + y.z) / s),
             s: ((z.x - x.z) / s).cfloat)
  else:
    let s = sqrt(1.0 + z.z - x.x - y.y) * 2.0
    eng.Quat(v: eng.vec((z.x + x.z) / s, (z.y + y.z) / s, 0.25 * s),
             s: ((x.y - y.x) / s).cfloat)

func qMul(a, b: eng.Quat): eng.Quat =
  ## One turn after another: `a` carrying `b`.
  eng.Quat(
    v: eng.vec(a.s * b.v.x + a.v.x * b.s + a.v.y * b.v.z - a.v.z * b.v.y,
               a.s * b.v.y - a.v.x * b.v.z + a.v.y * b.s + a.v.z * b.v.x,
               a.s * b.v.z + a.v.x * b.v.y - a.v.y * b.v.x + a.v.z * b.s),
    s: (a.s * b.s - a.v.x * b.v.x - a.v.y * b.v.y - a.v.z * b.v.z).cfloat)


#[ Building couple ]#

func stadium(rig: Rig; part: Part): tuple[r, spread: float] =
  ## Radius of section's round ends, and how far apart their two centres sit.
  ##   Tape gives round and flatness; stadium of that round at that flatness is
  ##     two capsules side by side.  Flatness of one gives spread of nought, so
  ##     neck and head come out of same line as one capsule each.
  let
    q = rig.flat[part]
    wide = rig.round[part] / (2.0 * PI * q + 4.0 * (1.0 - q))
  (wide * q, 2.0 * (wide - wide * q))

proc capsule(b: eng.BodyId; a, z: eng.Vec; r, density: float; group: cint) =
  ## Hang one capsule on body, with its own group so arm's own links pass.
  var
    cap = eng.Capsule(center1: a, center2: z, radius: r.cfloat)
    sd = eng.defaultShape()
  sd.density = density.cfloat
  sd.filter.groupIndex = group
  discard eng.createCapsule(b, addr sd, addr cap)

func standing(ax: Axes): eng.Quat =
  ## Turn carrying dancer's own axes onto world's, in engine's terms.
  ##   Engine's basis is not project's: body's forward is engine's negative z, and
  ##     its up is engine's y.  Frame is built from that correspondence, never from
  ##     project's three axes in project's order, which lays dancer down.
  qOf(asEngine(ax.right), asEngine((0.0, 0.0, 1.0)), asEngine(-ax.fore))

proc trunkOf(c: var Couple; who: Body): eng.BodyId =
  ## Torso, neck and head as one kinematic body: dancer is turned, never pushed.
  let
    st = c.stance[who]
    ax = axesOf(st)
  var bd = eng.defaultBody()
  bd.kind = eng.Kinematic
  bd.position = asPlace(ax.origin)
  bd.rotation = standing(ax)
  bd.enableSleep = false
  result = eng.createBody(c.world, addr bd)
  for part in Part:
    let
      (r, spread) = stadium(c.rig, part)
      lo = bottom(c.rig, part) + r
      hi = c.rig.top[part] - r
      mid = (lo + hi) / 2.0
    for side in [-0.5, 0.5]:
      let
        a = asEngine((side * spread, 0.0, (if hi > lo: lo else: mid)))
        z = asEngine((side * spread, 0.0, (if hi > lo: hi else: mid)))
      capsule(result, a, z, r, DENSITY, 0)
      if spread == 0.0:
        break

func restFrame(): eng.Quat =
  ## Shoulder's frame at rest, in trunk's own terms: arm hanging, elbow forward.
  ##   Its z is arm's length, which is what engine twists about.  Its x is elbow's
  ##     hinge, which points along body's right for both arms -- mirroring it would
  ##     bend left elbow backwards.  Twist's two ends are swapped instead.
  qOf(asEngine((1.0, 0.0, 0.0)), asEngine((0.0, -1.0, 0.0)), asEngine((0.0, 0.0, -1.0)))

func hingeFrame(): eng.Quat =
  ## Elbow's frame within upper arm: its z is hinge, upper arm's own x.
  qOf(eng.vec(0, 0, 1), eng.vec(0, -1, 0), eng.vec(1, 0, 0))

proc limbOf(c: var Couple; at: Vec; turn: eng.Quat; long: float;
            group: cint): eng.BodyId =
  ## One link: its own length along its local z, hung from `at`.
  var bd = eng.defaultBody()
  bd.kind = eng.Dynamic
  bd.position = asPlace(at)
  bd.rotation = turn
  bd.linearDamping = DAMP.cfloat
  bd.angularDamping = DAMP.cfloat
  bd.gravityScale = 0.0
  bd.enableSleep = false
  result = eng.createBody(c.world, addr bd)
  let r = c.rig.limb
  if long > 2.0 * r:
    capsule(result, eng.vec(0, 0, r), eng.vec(0, 0, long - r), r, DENSITY, group)
  else:
    let mid = eng.vec(0, 0, long / 2.0)
    capsule(result, mid, mid, long / 2.0, DENSITY, group)

proc armOf(c: var Couple; who: Body; arm: Arm; group: cint): ArmRig =
  ## Three links on shoulder, elbow and wrist, laid out hanging.
  let
    st = c.stance[who]
    ax = axesOf(st)
    trunkQ = standing(ax)
    frame = restFrame()
    turn = qMul(trunkQ, frame)
    top = shoulder(c.rig, st, arm)
    long = [c.rig.upper, c.rig.fore, c.rig.hand]
  var at = top
  for l in Limb:
    result.link[l] = limbOf(c, at, turn, long[ord(l)], group)
    at = at + (0.0, 0.0, -long[ord(l)])

  var ball = eng.defaultBall()
  ball.base.bodyIdA = c.who[who].trunk
  ball.base.bodyIdB = result.link[Limb.Upper]
  ball.base.localFrameA = eng.Frame(
    p: asEngine((side(arm) * c.rig.shoulderOut, 0.0, c.rig.shoulderUp)), q: frame)
  ball.base.localFrameB = eng.Frame(p: eng.vec(0, 0, 0), q: eng.IDENTITY)
  ball.enableSpring = true
  ball.hertz = EASE.cfloat
  ball.dampingRatio = EASE_DAMP.cfloat
  ball.targetRotation = eng.IDENTITY
  ball.enableTwistLimit = true
  let tw = c.rig.range[Dof.Twist]
  if arm == Arm.Right:
    ball.lowerTwistAngle = tw.lo.cfloat
    ball.upperTwistAngle = tw.hi.cfloat
  else:
    ball.lowerTwistAngle = (-tw.hi).cfloat
    ball.upperTwistAngle = (-tw.lo).cfloat
  result.shoulder = eng.createBall(c.world, addr ball)

  var hinge = eng.defaultHinge()
  hinge.base.bodyIdA = result.link[Limb.Upper]
  hinge.base.bodyIdB = result.link[Limb.Fore]
  hinge.base.localFrameA = eng.Frame(p: eng.vec(0, 0, c.rig.upper.cfloat), q: hingeFrame())
  hinge.base.localFrameB = eng.Frame(p: eng.vec(0, 0, 0), q: hingeFrame())
  hinge.enableSpring = true
  hinge.hertz = EASE.cfloat
  hinge.dampingRatio = EASE_DAMP.cfloat
  hinge.targetAngle = c.rig.range[Dof.Bend].neutral.cfloat
  hinge.enableLimit = true
  hinge.lowerAngle = c.rig.range[Dof.Bend].lo.cfloat
  hinge.upperAngle = c.rig.range[Dof.Bend].hi.cfloat
  result.elbow = eng.createHinge(c.world, addr hinge)

  var cuff = eng.defaultBall()
  cuff.base.bodyIdA = result.link[Limb.Fore]
  cuff.base.bodyIdB = result.link[Limb.Palm]
  cuff.base.localFrameA = eng.Frame(p: eng.vec(0, 0, c.rig.fore.cfloat), q: eng.IDENTITY)
  cuff.base.localFrameB = eng.Frame(p: eng.vec(0, 0, 0), q: eng.IDENTITY)
  cuff.enableSpring = true
  cuff.hertz = EASE.cfloat
  cuff.dampingRatio = EASE_DAMP.cfloat
  cuff.targetRotation = eng.IDENTITY
  cuff.enableConeLimit = true
  cuff.coneAngle = c.rig.range[Dof.Wrist].hi.cfloat
  result.wrist = eng.createBall(c.world, addr cuff)

proc build*(rig: Rig; stance: array[Body, Stance]; band: Band;
            links: seq[Link]): Couple =
  ## Stand two dancers, hang four arms, and join hands each link names.
  ##   No gravity.  Question reference asks is where arms can be, not what they
  ##     weigh, and weightless arms stay where turn leaves them, so pose at one
  ##     moment is pose before it carried forward rather than found afresh.
  var wd = eng.defaultWorld()
  wd.gravity = eng.vec(0, 0, 0)
  wd.enableSleep = false
  wd.enableContinuous = true
  result.world = eng.createWorld(addr wd)
  result.rig = rig
  result.stance = stance
  result.band = band
  result.links = links
  for b in Body:
    let t = trunkOf(result, b)
    result.who[b].trunk = t
  var group = 1.cint
  for b in Body:
    for a in Arm:
      let built = armOf(result, b, a, -group)
      result.who[b].arm[a] = built
      group += 1
  for ln in links:
    var g = eng.defaultBall()
    g.base.bodyIdA = result.who[ln.ends[0].body].arm[ln.ends[0].arm].link[Limb.Palm]
    g.base.bodyIdB = result.who[ln.ends[1].body].arm[ln.ends[1].arm].link[Limb.Palm]
    g.base.localFrameA = eng.Frame(p: eng.vec(0, 0, rig.hand.cfloat), q: eng.IDENTITY)
    g.base.localFrameB = eng.Frame(p: eng.vec(0, 0, rig.hand.cfloat), q: eng.IDENTITY)
    result.grip.add eng.createBall(result.world, addr g)

proc free*(c: Couple) = eng.destroyWorld(c.world)
  ## Give engine its world back.


#[ Turning, and reading what came of it ]#

const
  LIFT = 400.0 ## Newtons per metre couple carry joined hands toward their band by.
  FALL = 40.0  ## And damping on it, so hands arrive rather than swing.

proc carry(c: Couple) =
  ## Couple's own intent: hold each pair of joined hands at middle of their band.
  ##   Lift is spread over whole arm, never put on hand alone.  Hand alone levers
  ##     wrist, which then sits at its cone while shoulder and elbow do nothing --
  ##     dancer raising joined hands raises arm.
  let want = (c.rig.band[c.band].lo + c.rig.band[c.band].hi) / 2.0
  for ln in c.links:
    for k in 0 .. 1:
      let
        a = c.who[ln.ends[k].body].arm[ln.ends[k].arm]
        tip = asWorld(eng.pointOf(a.link[Limb.Palm], eng.vec(0, 0, c.rig.hand.cfloat)))
        rise = asWorld(eng.driftOf(a.link[Limb.Palm])).z
        f = (LIFT * (want - tip.z) - FALL * rise) / Limb.high.float
      for l in Limb:
        eng.push(a.link[l], asEngine((0.0, 0.0, f)), true)

proc advance*(c: Couple; steps: int) =
  ## Run engine on, carrying hands toward their band all through.
  for _ in 1 .. steps:
    carry(c)
    eng.step(c.world, (1.0 / HERTZ).cfloat, SUBSTEPS)

proc settle*(c: Couple) = advance(c, SETTLE)
  ## Let first pose come to rest before anything is read off it.

proc turn*(c: var Couple; who: Body; by: float; steps: int) =
  ## Turn one dancer on their own spot, anticlockwise seen from above.
  let rate = by * 2.0 * PI * HERTZ / steps.float
  eng.setSpin(c.who[who].trunk, asEngine((0.0, 0.0, rate)))
  advance(c, steps)
  eng.setSpin(c.who[who].trunk, asEngine((0.0, 0.0, 0.0)))
  c.stance = turned(c.stance, who, by)

proc poseOf*(c: Couple; i: int): Pose =
  ## Where one connection's two arms lie, and what engine says their joints read.
  for k in 0 .. 1:
    let
      h = c.links[i].ends[k]
      a = c.who[h.body].arm[h.arm]
    result.arms[k] = ArmPose(
      s: asWorld(eng.pointOf(a.link[Limb.Upper], eng.vec(0, 0, 0))),
      e: asWorld(eng.pointOf(a.link[Limb.Fore], eng.vec(0, 0, 0))),
      w: asWorld(eng.pointOf(a.link[Limb.Palm], eng.vec(0, 0, 0))),
      g: asWorld(eng.pointOf(a.link[Limb.Palm], eng.vec(0, 0, c.rig.hand.cfloat))))
    result.twist[k] = eng.twistAngleOf(a.shoulder).float
    result.bend[k] = eng.angleOf(a.elbow).float
    result.wrist[k] = eng.coneAngleOf(a.wrist).float
  result.apart = eng.partedBy(c.grip[i]).float

func twistEnds*(rig: Rig; arm: Arm): tuple[lo, hi: float] =
  ## Humeral rotation's two ends for one arm.  Rig states them for right arm,
  ## in negative and out positive; left arm is same joint mirrored, so swapped.
  let tw = rig.range[Dof.Twist]
  if arm == Arm.Right: (tw.lo, tw.hi) else: (-tw.hi, -tw.lo)

proc metBy(c: Couple; i: int): Stop =
  ## What one connection's arms are against, if anything.
  ##   Upper arm lying on its own side is how arms hang, not block, so only
  ##     forearm and hand count against body.
  var seen: array[8, eng.Touch]
  for k in 0 .. 1:
    let h = c.links[i].ends[k]
    for l in Limb:
      let
        me = c.who[h.body].arm[h.arm].link[l]
        n = eng.touches(me, addr seen[0], 8.cint)
      for t in 0 ..< n:
        let other = (if eng.bodyOf(seen[t].shapeIdA) == me: eng.bodyOf(seen[t].shapeIdB)
                     else: eng.bodyOf(seen[t].shapeIdA))
        var trunk = false
        for b in Body:
          if other == c.who[b].trunk:
            trunk = true
        if trunk:
          if l != Limb.Upper:
            return Stop.Through
        else:
          return Stop.Arms
  Stop.None

func freedom(r: Range; value: float; bothEnds: bool): float =
  ## How far value sits from nearer end of range, in that end's ease.
  ##   Not `margin`: margin counts stop with no ease as costing nothing to lean
  ##     on, so straight elbow reads infinitely comfortable.  Choosing where to
  ##     stand asks what arm is free to do, and straight elbow cannot straighten
  ##     further however painless it is, so both ends count here.  `limb.room`
  ##     draws same distinction, for same reason.
  let
    easeLo = if r.easeLo > 0.0: r.easeLo else: r.easeHi
    easeHi = if r.easeHi > 0.0: r.easeHi else: r.easeLo
  result = (r.hi - value) / easeHi
  if bothEnds:
    result = min(result, (value - r.lo) / easeLo)

func roomAt*(c: Couple; p: Pose; i: int): float =
  ## How free this connection's tightest joint still is to move either way.
  ##   Read off engine's own joints rather than off pose again, and without
  ##     swing, which engine was never given.  Wrist's range is cone, so its
  ##     nought is middle of it and only its edge counts.
  result = Inf
  for k in 0 .. 1:
    let
      tw = c.rig.range[Dof.Twist]
      (lo, hi) = twistEnds(c.rig, c.links[i].ends[k].arm)
      turning = Range(lo: lo, hi: hi, easeLo: tw.easeLo, easeHi: tw.easeHi)
    result = min(result, freedom(turning, p.twist[k], true))
    result = min(result, freedom(c.rig.range[Dof.Bend], p.bend[k], true))
    result = min(result, freedom(c.rig.range[Dof.Wrist], p.wrist[k], false))

proc roomAt*(rig: Rig; band: Band; links: seq[Link]; apart: float): float =
  ## Build couple that far apart, settle, and report their least room.
  ##   Least of several starts at infinity.  Starting it at nought, which is what
  ##     float comes as, made every distance score nought and sent couple to
  ##     closest one there was, whatever their joints said.
  result = Inf
  var c = build(rig, facing(rig, apart), band, links)
  c.settle()
  for i in 0 ..< links.len:
    let p = c.poseOf(i)
    if p.apart > PARTED:
      c.free()
      return -Inf
    result = min(result, roomAt(c, p, i))
  if links.len == 0: result = 0.0
  c.free()

proc restApart*(rig: Rig; band: Band; links: seq[Link]): float =
  ## How far apart couple stand for this hold: wherever joints are furthest from
  ## their ends, stepping by `PACE`, never inside `CLEAR` of clear air.
  ##   Found once, at rest, and kept through turn, as page before this one did:
  ##     couple who have taken hold do not step to and fro as they turn.
  let least = touching(rig) + CLEAR
  result = least
  var best = -Inf
  var apart = least
  while apart <= least + 1.0:
    let room = roomAt(rig, band, links, apart)
    if room > best:
      best = room
      result = apart
    apart += PACE

proc stopOf*(c: Couple; i: int): Stop =
  ## Why one connection's hands came apart, if they did.
  ##   Engine's own joints are asked first, since engine is what held them; swing
  ##     is read off pose and judged against rig, which engine was not given.
  let p = poseOf(c, i)
  if p.apart <= PARTED:
    return Stop.None
  for k in 0 .. 1:
    let
      h = c.links[i].ends[k]
      (lo, hi) = twistEnds(c.rig, h.arm)
    if p.twist[k] <= lo + AT_END or p.twist[k] >= hi - AT_END:
      return Stop.Twist
    if p.bend[k] >= c.rig.range[Dof.Bend].hi - AT_END:
      return Stop.Elbow
    if p.wrist[k] >= c.rig.range[Dof.Wrist].hi - AT_END:
      return Stop.Wrist
  for k in 0 .. 1:
    let
      h = c.links[i].ends[k]
      j = joints(c.stance[h.body], h.arm, p.arms[k])
    if margin(c.rig.range[Dof.Extend], j.extend) < 0.0 or
       margin(c.rig.range[Dof.Across], j.across) < 0.0:
      return Stop.Swing
  let met = metBy(c, i)
  if met != Stop.None: met else: Stop.Reach
