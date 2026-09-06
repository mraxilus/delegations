## One arm: where its joints are for given hand, and what each joint reads.
##
##   Arm is three rigid links -- upper arm, forearm, hand -- on shoulder
##     that swings and twists, elbow that bends, and wrist that bends any
##     way.  Forearm's own rotation is left free: it turns palm, and
##     grip is one point.
##   Given shoulder and grip, pose has three freedoms: which way
##     hand points off wrist (two), and where elbow sits on
##     circle its two-link chain leaves it (one).  Everything else follows.  So
##     solver next door searches three numbers per arm, and every pose it
##     ever tries has its lengths right by construction.
##   Joints are read back off pose, in body's own terms, and
##     left arm is read in mirror so that one set of ranges serves both.
##     Shoulder's twist is read swing-and-twist: arm at rest hangs
##     down with elbow bending forward; at any other direction
##     resting plane is carried there by least rotation, and twist is
##     how far actual elbow plane is turned from it.  That reading is
##     continuous everywhere but vertical arm, which no hold reaches.
##     Cost: reading is convention, and anatomists have three.  Accepted
##       -- this one has its one singularity where no dancer's arm goes, and
##       ranges cited for it are ordinary clinical ones.

{.experimental: "strictFuncs".}

import std/math

import ./[body, rig, vec]


type
  ArmPose* = object ## Four points of one arm, in world.
    s*, e*, w*, g*: Vec ## Shoulder, elbow, wrist, grip.

  Joints* = object ## What each joint reads, radians, in body's own terms.
    extend*, across*, elev*: float ## Upper arm: behind, across, up.
    twist*, bend*, wrist*: float

  Chain* = object ## What laying out arm to grip found.
    pose*: ArmPose
    stretch*: float ## Shoulder to wrist: over `upper + fore` is out of reach.


const
  REST_DOWN = (0.0, 0.0, -1.0) ## Upper arm hanging: swing's rest.
  REST_PLANE = (1.0, 0.0, 0.0) ## Its elbow plane's normal at rest: bending
                               ## forward, with arm read as right arm.
  STRAIGHT = 5.0 * PI / 180.0  ## Under this bend elbow has no plane, so
                               ## no twist is read off it.


func shoulderLocal*(rig: Rig): Vec = (rig.shoulderOut, 0.0, rig.shoulderUp)
  ## Shoulder in body's mirrored terms: always right arm here.


type Circle* = object ## Circle elbow can sit on for one grip and hand.
  ##   Everything `posed` works out that does not depend on swivel, kept
  ##     so seed can try every swivel round it for price of one.
  s*, w*: Vec ## Shoulder and wrist.
  stretch*: float ## Shoulder to wrist.
  u*: Vec ## Unit, shoulder towards wrist; zero where two coincide.
  along*, rad*: float ## Circle's centre along `u`, and its radius.
  down*, side*: Vec ## Its basis: lowest point's direction, and across.


func circleOf*(rig: Rig; s, g, h: Vec): Circle =
  ## Elbow's circle for arm from shoulder `s` to grip `g` with
  ## hand pointing along unit `h`.
  result.s = s
  result.w = g - h * rig.hand
  result.stretch = dist(result.w, s)
  if result.stretch < 1e-9:
    return
  let d = result.stretch
  result.u = (result.w - s) * (1.0 / d)
  result.along = clamp((rig.upper * rig.upper - rig.fore * rig.fore + d * d) / (2.0 * d),
                       -rig.upper, rig.upper)
  result.rad = sqrt(max(0.0, rig.upper * rig.upper - result.along * result.along))
  var down = REST_DOWN - result.u * dot(REST_DOWN, result.u)
  if norm(down) < 1e-6:
    down = perp(result.u)
  else:
    down = unit(down)
  result.down = down
  result.side = cross(result.u, down)

func posedOn*(rig: Rig; c: Circle; g: Vec; c_swivel, s_swivel: float): Chain =
  ## Lay arm with its elbow on circle at swivel whose cosine and
  ## sine these are.
  result.stretch = c.stretch
  if c.stretch < 1e-9:
    result.pose = ArmPose(s: c.s, e: c.s + (0.0, 0.0, -rig.upper), w: c.w, g: g)
    return
  let e = c.s + c.u * c.along + c.down * (c.rad * c_swivel) + c.side * (c.rad * s_swivel)
  result.pose = ArmPose(s: c.s, e: e, w: c.w, g: g)

func posed*(rig: Rig; s, g, h: Vec; swivel: float): Chain =
  ## Lay arm from shoulder `s` to grip `g` with hand pointing along
  ## unit `h` and elbow at `swivel` round its circle, nought being
  ## lowest elbow can hang.
  ##   Out of reach is not refused here: elbow goes as far as it can and
  ##     forearm is left too long, so that searcher minimising
  ##     overshoot has something smooth to descend.
  posedOn(rig, circleOf(rig, s, g, h), g, cos(swivel), sin(swivel))


func placed*(rig: Rig; st: Stance; arm: Arm; u: Vec;
             twist, bend, wrist, roll: float): ArmPose =
  ## Build arm from its joints: upper arm along unit `u` in
  ## body's mirrored terms, twisted, bent at elbow, hand off
  ## forearm by `wrist` in direction `roll` turns it to.
  ##   Forward kinematics, for laws: what `joints` reads must be what
  ##     was set here.
  let
    plane = spun(carried(REST_PLANE, REST_DOWN, u), u, twist)
    f = u * cos(bend) + cross(plane, u) * sin(bend)
    m = spun(plane, f, roll)
    h = f * cos(wrist) + m * sin(wrist)
    s = shoulderLocal(rig)
    e = s + u * rig.upper
    w = e + f * rig.fore
    g = w + h * rig.hand
    ax = axesOf(st)
  if arm == Arm.Left:
    ArmPose(s: toWorld(ax, mirrored(s)), e: toWorld(ax, mirrored(e)),
            w: toWorld(ax, mirrored(w)), g: toWorld(ax, mirrored(g)))
  else:
    ArmPose(s: toWorld(ax, s), e: toWorld(ax, e), w: toWorld(ax, w), g: toWorld(ax, g))


type Swing* = object ## Joints read before twist, and what twist needs.
  joints*: Joints ## Everything but `twist`, which is nought here.
  u*, f*: Vec ## Unit: upper arm and forearm, in body's mirrored terms.


func ownTerms*(ax: Axes; arm: Arm; p: Vec): Vec =
  ## World point in body's mirrored terms: right arm's, always.
  let q = toBody(ax, p)
  if arm == Arm.Left: mirrored(q) else: q

func swing*(ax: Axes; arm: Arm; pose: ArmPose): Swing =
  ## Read every joint but twist off pose, in body's own terms.
  ##   Twist is dear one to read, and one each seed asks for last,
  ##     so it is read apart.
  let
    s = ownTerms(ax, arm, pose.s)
    e = ownTerms(ax, arm, pose.e)
    w = ownTerms(ax, arm, pose.w)
    g = ownTerms(ax, arm, pose.g)
    u = unit(e - s)
    f = unit(w - e)
    h = unit(g - w)
  result.u = u
  result.f = f
  result.joints.extend = arcsin(clamp(-u.y, -1.0, 1.0))
  result.joints.across = arcsin(clamp(-u.x, -1.0, 1.0))
  result.joints.elev = arcsin(clamp(u.z, -1.0, 1.0))
  result.joints.bend = angleBetween(u, f)
  result.joints.wrist = angleBetween(f, h)

func twistOf*(sw: Swing): float =
  ## Shoulder's twist, read off elbow's plane; nought where
  ## elbow is too straight to have one.
  if sw.joints.bend > STRAIGHT:
    let
      rest = carried(REST_PLANE, REST_DOWN, sw.u)
      plane = unit(cross(sw.u, sw.f))
    signedAngle(rest, plane, sw.u)
  else:
    0.0

func joints*(ax: Axes; arm: Arm; pose: ArmPose): Joints =
  ## Read every joint off pose, in body's own terms, body's
  ## axes already worked out.
  let sw = swing(ax, arm, pose)
  result = sw.joints
  result.twist = twistOf(sw)

func joints*(st: Stance; arm: Arm; pose: ArmPose): Joints =
  ## Read every joint off pose, in body's own terms.
  joints(axesOf(st), arm, pose)


func reading*(j: Joints; dof: Dof): float =
  ## One value of joints that range applies to.
  case dof
  of Dof.Extend: j.extend
  of Dof.Across: j.across
  of Dof.Twist: j.twist
  of Dof.Bend: j.bend
  of Dof.Wrist: j.wrist

func margins*(rig: Rig; j: Joints): array[Dof, float] =
  ## Each freedom's distance inside its range, in its ease.
  for dof in Dof:
    result[dof] = margin(rig.range[dof], reading(j, dof))

func strain*(rig: Rig; j: Joints): tuple[most: float, dof: Dof] =
  ## How far into last stretch before edge arm is: nought well
  ## inside, one at edge, more past it; and which joint that is.
  result = (0.0, Dof.Extend)
  var least = Inf
  for dof in Dof:
    let m = margin(rig.range[dof], reading(j, dof))
    if m < least:
      least = m
      result.dof = dof
  result.most = max(0.0, 1.0 - least)

func room*(rig: Rig; j: Joints): float =
  ## How far nearest joint is from *either* end of its range, in that
  ## end's ease: freedom arm has to move any way at all.
  ##   Unlike `margin`, stop with no ease counts as end here --
  ##     straight elbow cannot straighten further, however painless it is.
  ##     Wrist's range is cone, so its nought is its middle, not
  ##     end, and only cone's edge counts.
  result = Inf
  for dof in Dof:
    let
      r = rig.range[dof]
      value = reading(j, dof)
      unitLo = if r.easeLo > 0.0: r.easeLo else: r.easeHi
      unitHi = if r.easeHi > 0.0: r.easeHi else: r.easeLo
    result = min(result, (r.hi - value) / unitHi)
    if dof != Dof.Wrist:
      result = min(result, (value - r.lo) / unitLo)

func comfort*(rig: Rig; j: Joints): float =
  ## Smooth cost of pose: how far every joint sits from its rest,
  ## squared and summed, with arm's lift counted too.
  ##   Minimised by solver among poses that hold, so that neighbouring
  ##     turns get neighbouring poses and hanging arm is preferred to
  ##     raised one where both would do.
  for dof in Dof:
    let d = eased(rig.range[dof], reading(j, dof))
    result += d * d
  let lift = (j.elev + PI / 2.0) / PI
  result += lift * lift
