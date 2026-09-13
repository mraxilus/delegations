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
                      ## Measured against leaps between moments: seven times this
                      ## took 232 mm to 204, so it is not what leaps were.
  PARTED* = 0.02      ## Hands this far apart, in metres, are no longer joined.
  AT_END* = 0.02      ## Joint within this of its end, in radians, is at its end.
  GIVE* = 0.1         ## How far past its end joint may sit and still hold, in that
                      ## end's ease.  Same reading, and same reason, old solver's
                      ## `TOLERANCE` had: under three degrees at joint is less than
                      ## flesh gives.  Without it arm cannot rest against its limit
                      ## and slide along it, which is what arm does: hold reads
                      ## blocked at very moment limit is first touched, and torque
                      ## that should push arm back never gets one step to act in.
  CONTACT = 0.125 * HERTZ * SUBSTEPS.float ## Hertz overlap is pushed apart at:
                      ## engine's own cap, eighth of its substep rate.  Its default
                      ## of thirty is softer than sim's own forces, and arms were
                      ## crushed through bodies with hands still joined -- forearm
                      ## 45 mm inside its own trunk, then popping out.  Architect:
                      ## arms "get crushed and phase through".  Measured over
                      ## crown sweep: 44.7 mm deepest at thirty, 7.9 at 120, 2.2 at
                      ## 240 and no less at 480, under engine's 5 mm slop.
  THROUGH* = 0.01     ## Overlap this deep, in metres, is arm through body: twice
                      ## engine's slop, where contact holding is never seen.
  GRIP = 30.0         ## Hertz joined hands hold at: half engine's default, and
                      ## softest thing in couple, so hold forced past what arms
                      ## can do gives at hands, in life as here, and parting is
                      ## what says which joint was at its end.  Measured through
                      ## forced whole turn at 0.40 m: at sixty, twist and wrist
                      ## carried three degrees past their ends' slack; at this
                      ## and at fifteen, nothing.  Held as stiffly as joints,
                      ## joints tore.
  HOLD = 0.25 * HERTZ * SUBSTEPS.float ## Hertz every joint but grip holds at: engine's
                      ## own cap, quarter of its substep rate, and above contact's,
                      ## so what gives first is contact and not joint.  At its
                      ## default of sixty, arm pressing own chest carried chest
                      ## 34 mm off hips' axis (16 at 240, 6 here and no less at
                      ## twice this), and once contact was stiff, joints tore
                      ## instead: elbow 42 degrees past straight, wrist 40 past
                      ## its cone, twist 27 past its end.
  SETTLE* = 3000      ## Steps given to first pose before anything is read off it.
                      ## Measured: twist still moving at 1000, settled by 3000.
  CLEAR* = 0.10       ## Least clear air between two torsos, metres.
  EASE* = 1.0         ## Hertz of spring holding each joint toward its rest.
  EASE_DAMP* = 1.0    ## And its damping.  Soft: it biases pose, never drives it.
  WRIST_EASE* = 5.0   ## Hertz of wrist's spring.  Hand weighs four hundred grams,
                      ## so at one hertz its spring is three hundredths of newton
                      ## metre per radian and wrist meets nothing before its cone:
                      ## joined at rest, wrists sat at sixty of sixty, and plainest
                      ## hold carried 0.56 where it had carried 1.04.  Passive
                      ## wrist stiffness is about one newton metre per radian,
                      ## which on that hand is five hertz; measured, wrists rest at
                      ## forty four degrees with room to spare.


type
  Limb* {.pure.} = enum ## Three links of one arm, shoulder outward.
    Upper, Fore, Palm

  ArmRig = object ## One arm's bodies and its three joints.
    link: array[Limb, eng.BodyId]
    shoulder, elbow, wrist: eng.JointId

  Figure = object ## One dancer: trunk that is turned, and two arms that follow.
    trunk: eng.BodyId ## Hips: kinematic, turned by sim, never pushed.
    chest: eng.BodyId ## What shoulders hang from: dynamic, yaws on hips.
    waist: eng.JointId ## Hinge between them, about trunk's up.
    arm: array[Arm, ArmRig]

  Mark* {.pure.} = enum ## What part of whom one capsule is.
    Trunk, Upper, Fore, Palm

  Shape* = object ## One capsule engine collides, as engine was given it.
    body*: eng.BodyId
    who*: Body  ## Whose.
    arm*: Arm   ## Which arm, where `mark` is not `Trunk`.
    mark*: Mark
    a*, z*: eng.Vec ## Its segment's two ends, in that body's own terms.
    r*: float       ## And radius round segment.

  Couple* = object ## Both dancers, their world, and connections between their hands.
    world: eng.WorldId
    rig*: Rig
    stance*: array[Body, Stance]
    band*: Band
    links*: seq[Link]
    turning*: Body ## Whose head hands are carried over, at crown.
    restTwist: float ## Couple's twist as built, so how far they have wound is known.
    restTip: seq[array[2, float]] ## Where each joined hand settled at rest, per
                                  ## connection and end, from which it rises.
    who: array[Body, Figure]
    grip: seq[eng.JointId]
    shapes*: seq[Shape] ## Every capsule above, kept as it was handed to engine.
      ## Recorded rather than worked out again, so anything drawing couple draws
      ## what is being simulated and cannot quietly disagree with it.

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

func trunkCapsules*(rig: Rig): seq[tuple[a, z: Vec, r: float]] =
  ## Every capsule of one trunk in body's own terms: x right, y fore, z up.
  ##   One list, handed to engine and to anything reading engine's world, so
  ##     what is collided and what is measured are one shape.  Reader's own
  ##     `contact` draws parts as cylinders with flat ends, and over torso's
  ##     dome of 125 mm that reads arm inside body where engine has it clear.
  for part in Part:
    let
      (r, spread) = stadium(rig, part)
      lo = bottom(rig, part) + r
      hi = rig.top[part] - r
      mid = (lo + hi) / 2.0
    for side in [-0.5, 0.5]:
      result.add ((side * spread, 0.0, (if hi > lo: lo else: mid)),
                  (side * spread, 0.0, (if hi > lo: hi else: mid)), r)
      if spread == 0.0:
        break

const
  WAIST_HI* = 40.0 * PI / 180.0 ## Thoracic rotation each way, clinical.
    ## Shoulders lag or lead hips by this much, sprung to neutral.  At every
    ## stop left before this, several joints sat at their ends at once, which is
    ## arm reaching where rigid trunk cannot help it; dancer winding chain turns
    ## shoulders ahead of or behind hips, and this is that.
    ##   Measured: every chain over crown free or past swan under every manner,
    ##     fifty six of fifty six chain questions, and every lower band up --
    ##     same-name chain at neck 1.00 to 1.12, at torso 0.88 to 1.06.  Low
    ##     wraps of single holds now stop, at 0.96 and 1.56, where they ran free
    ##     without it, which is nearer floor's half turn though still past it.

const
  TRUNK_BIT = 1'u64        ## Torso, neck and head.
  ARM_BIT: array[Body, uint64] = [2'u64, 4'u64] ## Lead's arms, follow's arms.
  EVERY = high(uint64)     ## Meets everything.

proc capsule(c: var Couple; b: eng.BodyId; who: Body; arm: Arm; mark: Mark;
             a, z: eng.Vec; r, density: float; group: cint) =
  ## Hang one capsule on body, with its own group so arm's own links pass.
  ##   Kept on couple as well as handed to engine: page draws this list, so shape
  ##     drawn and shape collided are one thing said once.
  var
    cap = eng.Capsule(center1: a, center2: z, radius: r.cfloat)
    sd = eng.defaultShape()
  sd.density = density.cfloat
  sd.filter.groupIndex = group
  sd.filter.categoryBits = (if mark == Mark.Trunk: TRUNK_BIT else: ARM_BIT[who])
  # Everything meets everything, arms of two dancers included.  Letting lead's
  # arms pass through follow's was tried, on Architect's point that lead gets his
  # own arm out of way, and it reached swan -- by letting arms occupy same place,
  # which no couple does.  Architect: it made sim worse.  Reverted.  Point stands
  # and wants real answer: lead who *moves* his arm, not one whose arm is absent.
  sd.filter.maskBits = EVERY
  discard eng.createCapsule(b, addr sd, addr cap)
  c.shapes.add Shape(body: b, who: who, arm: arm, mark: mark, a: a, z: z, r: r)

func standing(ax: Axes): eng.Quat =
  ## Turn carrying dancer's own axes onto world's, in engine's terms.
  ##   Engine's basis is not project's: body's forward is engine's negative z, and
  ##     its up is engine's y.  Frame is built from that correspondence, never from
  ##     project's three axes in project's order, which lays dancer down.
  qOf(asEngine(ax.right), asEngine((0.0, 0.0, 1.0)), asEngine(-ax.fore))

func upFrame(): eng.Quat =
  ## Frame whose z is trunk's own up, for hinge that yaws.
  ##   Trunk's local frame has up on its y (`standing`), and revolute hinges
  ##     about frame A's local z, so hinge frame turns local z onto local y.
  qOf(eng.vec(1, 0, 0), eng.vec(0, 0, -1), eng.vec(0, 1, 0))

proc trunkOf(c: var Couple; who: Body): tuple[hips, chest: eng.BodyId,
                                             waist: eng.JointId] =
  ## Hips as kinematic body, turned and never pushed, carrying nothing; every
  ## capsule on dynamic chest hinged to them about trunk's up, sprung to neutral
  ## and stopped at thoracic rotation.  Shoulders hang from chest.
  let
    st = c.stance[who]
    ax = axesOf(st)
  var bd = eng.defaultBody()
  bd.kind = eng.Kinematic
  bd.position = asPlace(ax.origin)
  bd.rotation = standing(ax)
  bd.enableSleep = false
  result.hips = eng.createBody(c.world, addr bd)
  var cd = eng.defaultBody()
  cd.kind = eng.Dynamic
  cd.position = asPlace(ax.origin)
  cd.rotation = standing(ax)
  cd.linearDamping = DAMP.cfloat
  cd.angularDamping = DAMP.cfloat
  cd.gravityScale = 0.0
  cd.enableSleep = false
  result.chest = eng.createBody(c.world, addr cd)
  var hinge = eng.defaultHinge()
  hinge.base.bodyIdA = result.hips
  hinge.base.bodyIdB = result.chest
  hinge.base.localFrameA = eng.Frame(p: eng.vec(0, 0, 0), q: upFrame())
  hinge.base.localFrameB = eng.Frame(p: eng.vec(0, 0, 0), q: upFrame())
  hinge.base.constraintHertz = HOLD.cfloat
  hinge.enableSpring = true
  hinge.hertz = EASE.cfloat
  hinge.dampingRatio = EASE_DAMP.cfloat
  hinge.targetAngle = 0.0
  hinge.enableLimit = true
  hinge.lowerAngle = (-WAIST_HI).cfloat
  hinge.upperAngle = WAIST_HI.cfloat
  result.waist = eng.createHinge(c.world, addr hinge)
  let body = result.chest
  for (a, z, r) in trunkCapsules(c.rig):
    capsule(c, body, who, Arm.Left, Mark.Trunk, asEngine(a), asEngine(z), r, DENSITY, 0)

const MARKS = [Mark.Upper, Mark.Fore, Mark.Palm]
  ## Which mark each of arm's three links carries, in `Limb`'s own order.

func restFrame(): eng.Quat =
  ## Shoulder's frame at rest, in trunk's own terms: arm hanging, elbow forward.
  ##   Its z is arm's length, which is what engine twists about.  Its x is elbow's
  ##     hinge, which points along body's right for both arms -- mirroring it would
  ##     bend left elbow backwards.  Twist's two ends are swapped instead.
  qOf(asEngine((1.0, 0.0, 0.0)), asEngine((0.0, -1.0, 0.0)), asEngine((0.0, 0.0, -1.0)))

func hingeFrame(): eng.Quat =
  ## Elbow's frame within upper arm: its z is hinge, upper arm's own x.
  qOf(eng.vec(0, 0, 1), eng.vec(0, -1, 0), eng.vec(1, 0, 0))

proc limbOf(c: var Couple; who: Body; arm: Arm; mark: Mark; at: Vec;
            turn: eng.Quat; long: float; group: cint): eng.BodyId =
  ## One link: its own length along its local z, hung from `at`.
  var bd = eng.defaultBody()
  bd.kind = eng.Dynamic
  bd.position = asPlace(at)
  bd.rotation = turn
  bd.linearDamping = DAMP.cfloat
  bd.angularDamping = DAMP.cfloat
  bd.gravityScale = 1.0
  bd.enableSleep = false
  result = eng.createBody(c.world, addr bd)
  let r = c.rig.limb
  if long > 2.0 * r:
    capsule(c, result, who, arm, mark, eng.vec(0, 0, r), eng.vec(0, 0, long - r),
            r, DENSITY, group)
  else:
    let mid = eng.vec(0, 0, long / 2.0)
    capsule(c, result, who, arm, mark, mid, mid, long / 2.0, DENSITY, group)

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
    result.link[l] = limbOf(c, who, arm, MARKS[ord(l)], at, turn, long[ord(l)], group)
    at = at + (0.0, 0.0, -long[ord(l)])

  var ball = eng.defaultBall()
  ball.base.bodyIdA = c.who[who].chest
  ball.base.bodyIdB = result.link[Limb.Upper]
  ball.base.localFrameA = eng.Frame(
    p: asEngine((side(arm) * c.rig.shoulderOut, 0.0, c.rig.shoulderUp)), q: frame)
  ball.base.localFrameB = eng.Frame(p: eng.vec(0, 0, 0), q: eng.IDENTITY)
  # Engine lets bodies one joint connects pass through each other unless told
  # otherwise, and upper arm hung from chest sank into own torso, neck and head
  # unseen: 67 mm inside own head by capsule geometry while engine reported no
  # touch.  Shoulder joint sits three centimetres outside torso, less than
  # limb's radius, so hanging arm now rests against its side, abducted by what
  # that takes -- about three degrees at elbow.
  ball.base.collideConnected = true
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
  ball.base.constraintHertz = HOLD.cfloat
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
  hinge.base.constraintHertz = HOLD.cfloat
  result.elbow = eng.createHinge(c.world, addr hinge)

  var cuff = eng.defaultBall()
  cuff.base.bodyIdA = result.link[Limb.Fore]
  cuff.base.bodyIdB = result.link[Limb.Palm]
  cuff.base.localFrameA = eng.Frame(p: eng.vec(0, 0, c.rig.fore.cfloat), q: eng.IDENTITY)
  cuff.base.localFrameB = eng.Frame(p: eng.vec(0, 0, 0), q: eng.IDENTITY)
  cuff.enableSpring = true
  cuff.hertz = WRIST_EASE.cfloat
  cuff.dampingRatio = EASE_DAMP.cfloat
  cuff.targetRotation = eng.IDENTITY
  cuff.enableConeLimit = true
  cuff.coneAngle = c.rig.range[Dof.Wrist].hi.cfloat
  cuff.base.constraintHertz = HOLD.cfloat
  result.wrist = eng.createBall(c.world, addr cuff)

proc build*(rig: Rig; stance: array[Body, Stance]; band: Band;
            links: seq[Link]; turning = Body.Two): Couple =
  ## Stand two dancers, hang four arms, and join hands each link names.
  ##   No gravity.  Question reference asks is where arms can be, not what they
  ##     weigh, and weightless arms stay where turn leaves them, so pose at one
  ##     moment is pose before it carried forward rather than found afresh.
  var wd = eng.defaultWorld()
  wd.gravity = eng.vec(0, 0, 0)
  wd.contactHertz = CONTACT.cfloat
  wd.enableSleep = false
  wd.enableContinuous = true
  result.world = eng.createWorld(addr wd)
  result.rig = rig
  result.stance = stance
  result.restTwist = twist(stance)
  result.band = band
  result.links = links
  result.turning = turning
  for b in Body:
    let (hips, chest, waist) = trunkOf(result, b)
    result.who[b].trunk = hips
    result.who[b].chest = chest
    result.who[b].waist = waist
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
    g.base.constraintHertz = GRIP.cfloat
    result.grip.add eng.createBall(result.world, addr g)

proc chestStance*(c: Couple; who: Body): Stance =
  ## Where shoulders stand: hips' stance, turned by waist.
  ##   Every reading of arm in body's own terms goes through this, since arm
  ##     hangs from chest and not from hips.
  result = c.stance[who]
  result.facing += eng.angleOf(c.who[who].waist).float

proc chestStances*(c: Couple): array[Body, Stance] =
  for who in Body: result[who] = c.chestStance(who)

proc free*(c: Couple) = eng.destroyWorld(c.world)
  ## Give engine its world back.


#[ Turning, and reading what came of it ]#

const
  LIFT = 400.0 ## Newtons per metre couple carry joined hands toward their band by.
  RAISE = 0.25 ## Turns over which hands rise from where they rest to their band.
    ## Hands go up before head passes under, which is at quarter turn, and they
    ## go up as arm moves and not as switch is thrown: asked for band's edge
    ## outright, hand crossed 359 mm in first fiftieth of turn, which page draws
    ## as leap.  Architect: watch for sharp movements.  Rise starts from where
    ## each hand settled, and pull is not eased in on top of it: eased in, hand
    ## lagged ramp and caught up in one burst of 200 mm.
  FALL = 40.0  ## And damping on it, so hands arrive rather than swing.
  DRAW = [40.0, 40.0, 10.0] ## Per band, newtons per metre hands are drawn toward
    ## where couple mean to carry them.  Weighted as old solver's `CENTRING` was,
    ## two to two to one half, and weak on purpose: this is preference couple have,
    ## not constraint.  Strong, it drags hands to one spot and arms trail into
    ## swings no shoulder makes, and hold reads blocked when only hands were held
    ## wrongly.  Measured at two hundred newtons per metre: crown blocked at 0.34
    ## of turn where floor says it never blocks.
  SHOULDER_BACK = 200.0 ## Newton metres per radian arm is past its swing.
    ## Stiff, so arm pressed against its end stays within `GIVE` of it rather than
    ## sinking through.  Upper arm's inertia is about 0.074, so this rings at some
    ## eight hertz, well inside step of two hundred and forty.
    ## Swing is only range engine was never given.  Judging it after each step and
    ## never resisting it let engine walk arm into places no shoulder goes and made
    ## hold read blocked where dancer would simply have put arm elsewhere.  Torque
    ## is what other three joints already get from engine; this gives swing same.

func tipOf(c: Couple; a: ArmRig): Vec =
  ## Fingertip, which band is asked of.
  ##   Fingertip alone, forearm's lower end not too: asked of elbow as well over
  ##     crown, so forearm would clear head outright, every rise went in bursts,
  ##     elbow alone asked to climb swinging upper arm and hand at end of forearm
  ##     going three times as far -- 289 mm in one moment.  Forearm meeting head
  ##     is contact's to answer, and contact is stiff enough to now.
  asWorld(eng.pointOf(a.link[Limb.Palm], eng.vec(0, 0, c.rig.hand.cfloat)))

proc carry(c: Couple) =
  ## Couple's own intent: keep each pair of joined hands somewhere in their band.
  ##   Band's two edges are held; everything between them is free.  Architect:
  ##     hand height is for turn, and nothing is fixed but keeping bodies apart.
  ##     Held at middle instead, couple spend on height reach turn wanted, and
  ##     card is answered about pose couple would never have chosen.
  ##   Lift is spread over whole arm, never put on hand alone.  Hand alone levers
  ##     wrist, which then sits at its cone while shoulder and elbow do nothing --
  ##     dancer raising joined hands raises arm.
  ##   Hands are drawn toward point between two bodies as well as to their band.
  ##     Without it grip floats off sideways and arms trail away behind, which
  ##     reads as shoulder giving out when it is only hands left unheld.
  let
    band = c.rig.band[c.band]
    # Height is asked of couple only as they leave face to face.  Architect:
    # face to face arms may be at any height, and it is once they are no longer
    # face to face that hands must actually be above -- which is clearance,
    # since only then would arm have to pass through body to stay low.  Lower
    # edge rises with couple's winding, from where hand settled at rest to
    # where band puts it, and is there by `RAISE`; nothing is asked until rest
    # has settled and been read.
    wound = abs(twist(c.stance) - c.restTwist) / (2.0 * PI)
    risen = min(1.0, wound / RAISE)
    one = axesOf(c.stance[Body.One]).origin
    two = axesOf(c.stance[Body.Two]).origin
    mid = (if c.band == Band.Crown: axesOf(c.stance[c.turning]).origin
           else: (one + two) * 0.5)
      ## Over crown, hands go over head of dancer who turns, not between two:
      ## couple setting hold up put them there, and pulling them to midpoint
      ## instead makes both reach across their own body and spends adduction
      ## they need for turn.
  for i, ln in c.links:
    for k in 0 .. 1:
      let
        a = c.who[ln.ends[k].body].arm[ln.ends[k].arm]
        tip = tipOf(c, a)
        drift = asWorld(eng.driftOf(a.link[Limb.Palm]))
      # While hand rises it is carried along its rise, held to it from both
      # sides.  Risen, band is what holds: nought anywhere inside it, hands
      # pressed back toward whichever edge they left, and left alone between
      # them.  Nothing is asked until rest has settled and been read.
      var off = 0.0
      if c.restTip.len > 0:
        let lo = c.restTip[i][k] + (band.lo - c.restTip[i][k]) * risen
        if risen < 1.0: off = lo - tip.z
        elif tip.z < band.lo: off = band.lo - tip.z
        elif tip.z > band.hi: off = band.hi - tip.z
      let
        lift = (LIFT * off - FALL * drift.z) / 3.0
        pull = DRAW[ord(c.band)] / 3.0
        toward: Vec = ((mid.x - tip.x) * pull - drift.x * FALL / 3.0,
                       (mid.y - tip.y) * pull - drift.y * FALL / 3.0, lift)
      for l in Limb:
        eng.push(a.link[l], asEngine(toward), true)

proc holdSwing(c: Couple) =
  ## Resist upper arm that has gone past extension or adduction.
  ##   Torque turns arm back toward range it left, about axis that carries its
  ##     own direction toward one it should not have passed.  Body's own terms
  ##     throughout, then back to world, then to engine.
  for who in Body:
    let ax = axesOf(c.chestStance(who))
    for arm in Arm:
      let
        a = c.who[who].arm[arm]
        s = asWorld(eng.pointOf(a.link[Limb.Upper], eng.vec(0, 0, 0)))
        e = asWorld(eng.pointOf(a.link[Limb.Upper], eng.vec(0, 0, c.rig.upper.cfloat)))
        u = ownTerms(ax, arm, e) - ownTerms(ax, arm, s)
        dir = unit(u)
      var back: Vec = (0.0, 0.0, 0.0)
      let
        extend = arcsin(clamp(-dir.y, -1.0, 1.0))
        across = arcsin(clamp(-dir.x, -1.0, 1.0))
        outExtend = extend - c.rig.range[Dof.Extend].hi
        outAcross = across - c.rig.range[Dof.Across].hi
      if outExtend > 0.0:
        back = back + cross(dir, (0.0, 1.0, 0.0)) * (SHOULDER_BACK * outExtend)
      if outAcross > 0.0:
        back = back + cross(dir, (1.0, 0.0, 0.0)) * (SHOULDER_BACK * outAcross)
      if back.x != 0.0 or back.y != 0.0 or back.z != 0.0:
        # Torque is pseudovector.  Mirrored frame is left handed, so cross product
        # worked out in it comes back negated: un-mirroring it as plain vector
        # gives exactly minus what is wanted, and turns correction into shove.
        let own: Vec = (if arm == Arm.Left: (x: back.x, y: -back.y, z: -back.z)
                        else: back)
        eng.twistBy(a.link[Limb.Upper],
                    asEngine(ax.right * own.x + ax.fore * own.y + (0.0, 0.0, own.z)),
                    true)

const ELBOW_DOWN = 1.0 ## Newton metres elbow is turned down by: upper arm's
  ## weight about that line at half its lever, two kilograms at five centimetres.
  ## Measured: at nought, elbow crossed 280 mm between moments and arms rested
  ## twisted fifty four degrees to keep wrists straight; at two, wrists rested
  ## seventeen degrees twisted; at this, four, and no point of any held arm
  ## crossed 71 mm over three low and crown walks.

proc elbowDown(c: Couple) =
  ## Turn each elbow toward hanging below line from shoulder to wrist.
  ##   Arm has no weight here, so nothing chose where elbow swivelled about that
  ##     line and it wandered: elbow crossed 280 mm between moments with hand
  ##     moving 77.  This is what weight does to elbow about that line and
  ##     nothing else weight does -- it neither loads raise nor pulls hand down.
  for who in Body:
    for arm in Arm:
      let
        a = c.who[who].arm[arm]
        s = asWorld(eng.pointOf(a.link[Limb.Upper], eng.vec(0, 0, 0)))
        e = asWorld(eng.pointOf(a.link[Limb.Upper], eng.vec(0, 0, c.rig.upper.cfloat)))
        w = asWorld(eng.pointOf(a.link[Limb.Fore], eng.vec(0, 0, c.rig.fore.cfloat)))
        line = w - s
      if dot(line, line) < 1e-4: continue
      let
        axis = unit(line)
        off = (e - s) - axis * dot(e - s, axis)
        down: Vec = (0.0, 0.0, -1.0)
        under = down - axis * dot(down, axis)
      if dot(off, off) < 1e-4 or dot(under, under) < 1e-4: continue
      let turn = cross(unit(off), unit(under))
      eng.twistBy(a.link[Limb.Upper], asEngine(turn * ELBOW_DOWN), true)

proc advance*(c: Couple; steps: int) =
  ## Run engine on, carrying hands toward their band all through.
  for _ in 1 .. steps:
    carry(c)
    holdSwing(c)
    elbowDown(c)
    eng.step(c.world, (1.0 / HERTZ).cfloat, SUBSTEPS)

proc settle*(c: var Couple) =
  ## Let first pose come to rest before anything is read off it, and read where
  ## each joined hand settled, which is where its rise starts.
  advance(c, SETTLE)
  c.restTip = @[]
  for ln in c.links:
    var tip: array[2, float]
    for k in 0 .. 1:
      tip[k] = tipOf(c, c.who[ln.ends[k].body].arm[ln.ends[k].arm]).z
    c.restTip.add tip

proc turn*(c: var Couple; who: Body; by: float; steps: int) =
  ## Turn one dancer on their own spot, anticlockwise seen from above.
  ##   Stance is carried along step by step rather than set at end: swing is read
  ##     in dancer's own terms, so leaving stance behind for whole move judges
  ##     every arm against frame dancer has already left.
  let rate = by * 2.0 * PI * HERTZ / steps.float
  eng.setSpin(c.who[who].trunk, asEngine((0.0, 0.0, rate)))
  for _ in 1 .. steps:
    carry(c)
    holdSwing(c)
    elbowDown(c)
    eng.step(c.world, (1.0 / HERTZ).cfloat, SUBSTEPS)
    c.stance = turned(c.stance, who, by / steps.float)
  eng.setSpin(c.who[who].trunk, asEngine((0.0, 0.0, 0.0)))

proc armPoseOf*(c: Couple; who: Body; arm: Arm): ArmPose =
  ## Four points of one arm, joined or not.
  ##   Every arm, not only ones holding: arm hanging free is still arm, and
  ##     anything drawing couple has to draw it.
  let a = c.who[who].arm[arm]
  ArmPose(
    s: asWorld(eng.pointOf(a.link[Limb.Upper], eng.vec(0, 0, 0))),
    e: asWorld(eng.pointOf(a.link[Limb.Fore], eng.vec(0, 0, 0))),
    w: asWorld(eng.pointOf(a.link[Limb.Palm], eng.vec(0, 0, 0))),
    g: asWorld(eng.pointOf(a.link[Limb.Palm], eng.vec(0, 0, c.rig.hand.cfloat))))

proc jointsOf*(c: Couple; who: Body; arm: Arm): tuple[j: Joints, tw, bd, wr: float] =
  ## What one arm's joints read: three swings worked off its pose, and three
  ## engine states its own joints in.
  let a = c.who[who].arm[arm]
  (joints(c.chestStance(who), arm, c.armPoseOf(who, arm)),
   eng.twistAngleOf(a.shoulder).float, eng.angleOf(a.elbow).float,
   eng.coneAngleOf(a.wrist).float)

proc endsOf*(c: Couple; s: Shape): tuple[a, z: Vec] =
  ## Where one capsule's segment lies in world now.
  ##   Asked of engine rather than worked out from stance, so drawing cannot
  ##     drift from what is being simulated.
  (asWorld(eng.pointOf(s.body, s.a)), asWorld(eng.pointOf(s.body, s.z)))

proc poseOf*(c: Couple; i: int): Pose =
  ## Where one connection's two arms lie, and what engine says their joints read.
  for k in 0 .. 1:
    let
      h = c.links[i].ends[k]
      a = c.who[h.body].arm[h.arm]
    result.arms[k] = c.armPoseOf(h.body, h.arm)
    result.twist[k] = eng.twistAngleOf(a.shoulder).float
    result.bend[k] = eng.angleOf(a.elbow).float
    result.wrist[k] = eng.coneAngleOf(a.wrist).float
  result.apart = eng.partedBy(c.grip[i]).float

func twistEnds*(rig: Rig; arm: Arm): tuple[lo, hi: float] =
  ## Humeral rotation's two ends for one arm.  Rig states them for right arm,
  ## in negative and out positive; left arm is same joint mirrored, so swapped.
  let tw = rig.range[Dof.Twist]
  if arm == Arm.Right: (tw.lo, tw.hi) else: (-tw.hi, -tw.lo)

proc deepest(c: Couple; i: int): tuple[depth: float, met: Stop, k: int] =
  ## Deepest any link of one connection's arms sits in anything, by engine's
  ## own manifolds, and whether that is body or arm.
  ##   Asked whatever hands are doing: hold that stands with arm through body
  ##     is not hold couple have, and before this only hands parting said so.
  result = (0.0, Stop.None, -1)
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
          if other == c.who[b].chest:
            trunk = true
        let folds = cast[ptr UncheckedArray[eng.Manifold]](seen[t].manifolds)
        for m in 0 ..< seen[t].manifoldCount:
          for p in 0 ..< folds[m].pointCount:
            let depth = -folds[m].points[p].separation.float
            if depth > result.depth:
              result = (depth, (if trunk: Stop.Through else: Stop.Arms), k)

proc metBy(c: Couple; i: int): Stop =
  ## What one connection's arms are against, if anything, once hands have parted.
  let d = deepest(c, i)
  if d.depth > 0.0: d.met else: Stop.None

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

func restStance*(rig: Rig; apart: float; away = false): array[Body, Stance] =
  ## Where couple start.  Same-name pair is built pillion: face to face its two
  ## connections lie through each other, so couple would not collect it there.
  result = facing(rig, apart)
  if away: result = turned(result, Body.Two, 0.5)

proc stoppedBy*(c: Couple; i: int): tuple[why: Stop, k: int] =
  ## What stops this connection here, if anything does, and at which of its two arms.
  ##   Swing is asked first and whatever hands are doing, because engine was never
  ##     given it: nothing else in model holds extension or adduction, so asking
  ##     only once hands had parted left them unheld through every hold that stood.
  ##   Everything else engine itself enforces, so it can only be reached by hands
  ##     coming apart, and then engine's own joints say which gave.
  let p = poseOf(c, i)
  for k in 0 .. 1:
    let
      h = c.links[i].ends[k]
      j = joints(c.chestStance(h.body), h.arm, p.arms[k])
    if margin(c.rig.range[Dof.Extend], j.extend) < -GIVE or
       margin(c.rig.range[Dof.Across], j.across) < -GIVE:
      return (Stop.Swing, k)
  let deep = deepest(c, i)
  if deep.depth > THROUGH:
    return (deep.met, deep.k)
  if p.apart <= PARTED:
    return (Stop.None, -1)
  for k in 0 .. 1:
    let
      h = c.links[i].ends[k]
      (lo, hi) = twistEnds(c.rig, h.arm)
    if p.twist[k] <= lo + AT_END or p.twist[k] >= hi - AT_END:
      return (Stop.Twist, k)
    if p.bend[k] >= c.rig.range[Dof.Bend].hi - AT_END:
      return (Stop.Elbow, k)
    if p.wrist[k] >= c.rig.range[Dof.Wrist].hi - AT_END:
      return (Stop.Wrist, k)
  let met = metBy(c, i)
  if met != Stop.None: (met, 0) else: (Stop.Reach, 0)

proc stopOf*(c: Couple; i: int): Stop = stoppedBy(c, i).why
  ## What stops this connection here, if anything does.
