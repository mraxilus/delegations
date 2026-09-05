## Connection between two hands: whether pose of it holds, and finding
## most comfortable one that does.
##
##   Connection is two arms meeting at one grip.  Where grip is, which
##     way each hand points off its wrist, and where each elbow sits on its
##     circle are nine numbers of pose; every other point follows from
##     rig.  Evaluating pose reads every joint against its range, every
##     link against both bodies and against other arm, and grip
##     against band hands are carried in.
##   Two measures, two jobs.  Whether pose *holds* is set of hard tests,
##     and where it fails largest failure is named -- joint, or
##     body part and whose.  Among poses that hold, pose returned is
##     one with least comfort cost: joints nearest their rest,
##     arm lowest, hands between two bodies on line between
##     their centrelines, and at whatever height within their band leaves
##     joints least constrained.  Cost is smooth, so neighbouring
##     turns get neighbouring poses.
##   Search is pattern search: try each number one step either way, keep
##     best improvement, halve steps when nothing improves.  Seeded
##     from grid over grip with each arm laid out independently, since
##     for fixed grip two arms only meet in arm-against-arm test.
##     Deterministic throughout: same question gets same answer.
##     Cost of local search: pose that holds may go unfound.  Accepted --
##       seed is grid, laws check coarse seed against fine one,
##       and block is reported with whether any pose exists there at all.
##   What search needs of world and never changes -- each body's shape
##     and shoulders -- is worked out once into `Scene` and handed down, and
##     loops that run millions of times allocate nothing and copy nothing
##     they need not: seed is tried joint by joint and given up at
##     first thing that fails, trial pose is one number changed in place,
##     and every verdict found is kept beside its pose rather than found
##     again.  Answers are same as they were when all that was done
##     plain way; laws and sweeps' written output check it.

{.experimental: "strictFuncs".}

import std/[math, options]

import ./[body, contact, limb, rig, vec]


type
  Link* = object ## One connection: which two hands it joins.
    ends*: array[2, Hand]

  Params* = object ## Nine numbers of connection's pose.
    g*: Vec ## Grip.
    h*: array[2, Vec] ## Unit: which way each hand points off its wrist.
    swivel*: array[2, float] ## Each elbow's place on its circle.

  Reason* {.pure.} = enum ## What stops pose, one thing at once.
    None,     ## Nothing: it holds.
    Reach,    ## Grip is further than arm is long.
    Shoulder, ## Upper arm too far behind or across.
    Twist,    ## Upper arm turned too far in or out.
    Elbow,    ## Bent past what elbow does.
    Wrist,    ## Hand too far off forearm.
    Through,  ## Link through body.
    Arms,     ## Two arms through each other.
    Band      ## Grip out of band hands are carried in.

  LinkFit* = object ## What evaluating one connection found.
    arms*: array[2, ArmPose]
    joints*: array[2, Joints]
    strain*: float ## Worst joint's strain, nought to one and past.
    strainedArm*: int
    strainedDof*: Dof

  Verdict* = object ## What evaluating whole state found.
    ok*: bool
    reason*: Reason
    part*: Part    ## For `Through`: which part.
    whose*: Body   ## For `Through`: whose.
    link*, arm*: int ## Which connection and which of its arms is at fault.
    dof*: Dof      ## For joint's refusal: which joint.
    worst*: float  ## Largest failure, in units of its own ease; nought when it holds.
    penalty*: float ## Every failure squared and summed: smooth, for climbing out.
    strain*: float ## Worst strain over every arm.
    cost*: float   ## Comfort cost, summed.
    fits*: array[2, LinkFit]
    n*: int        ## How many of `fits` are real.

  State* = object ## Whole world as one plain value.
    rig*: Rig
    stance*: array[Body, Stance]
    band*: Band
    links*: seq[Link]
    params*: seq[Params] ## One per link once solved; empty until then.
    overhead*: bool ## Whether hands over crown are held over `turning`'s
                    ## head rather than between shoulders: couple sets
                    ## hold up for turn they are about to do.
    turning*: Body

  Solved* = object ## State with its pose found, and what was found of it.
    state*: State
    verdict*: Verdict

  Scene* = object ## What every evaluation of state needs and none changes.
    shape*: array[Body, BodyShape]
    shoulder*: array[Body, array[Arm, Vec]]


const
  TOLERANCE* = 0.1 ## Failure smaller than this holds: under three degrees
                   ## at joint, under five millimetres at body -- less than
                   ## flesh gives.  Without it search converging onto
                   ## contact from outside never arrives.
  CENTRING = [2.0, 2.0, 0.5] ## Per band, weight of grip's distance
    ## from point between two bodies' axes.  Light over crown:
    ## hand held over head is held over turning partner's head, not
    ## between two.
  EXCUSE = 0.15  ## Two arms holding one grip may converge within this of it.
  SLACK = 0.05   ## Unit that reach or band overshoot is counted in, metres.
  DIRS14 = block:
    var d: seq[Vec]
    for x in [-1.0, 0.0, 1.0]:
      for y in [-1.0, 0.0, 1.0]:
        for z in [-1.0, 0.0, 1.0]:
          if (x == 0.0 and y == 0.0) or (x == 0.0 and z == 0.0) or
             (y == 0.0 and z == 0.0):
            if not (x == 0.0 and y == 0.0 and z == 0.0):
              d.add unit((x, y, z))
          elif x != 0.0 and y != 0.0 and z != 0.0:
            d.add unit((x, y, z))
    d
  DIRS26 = block:
    var d: seq[Vec]
    for x in [-1.0, 0.0, 1.0]:
      for y in [-1.0, 0.0, 1.0]:
        for z in [-1.0, 0.0, 1.0]:
          if not (x == 0.0 and y == 0.0 and z == 0.0):
            d.add unit((x, y, z))
    d


func sceneOf*(s: State): Scene =
  ## Bodies' shapes and shoulders at state's stance.
  for who in Body:
    result.shape[who] = shapeOf(s.rig, s.stance[who])
    for arm in Arm:
      result.shoulder[who][arm] = toWorld(result.shape[who].ax,
        (side(arm) * s.rig.shoulderOut, 0.0, s.rig.shoulderUp))


#[ Evaluating ]#

func worse(v: var Verdict; amount: float; reason: Reason; link, arm: int) =
  ## Record failure: into sum always, as largest if it is.
  v.penalty += amount * amount
  if amount > v.worst:
    v.worst = amount
    v.reason = reason
    v.link = link
    v.arm = arm


type ArmLay = object ## One arm laid to grip, and what it reads on its own.
  pose: ArmPose
  joints: Joints
  margin: array[Dof, float] ## Each joint's distance inside its range.
  over: float ## How far past arm's length wrist is; nought or less holds.
  cost: float ## Its comfort cost.


func layArm(s: State; sc: Scene; hand: Hand; g, h: Vec; swivel: float): ArmLay =
  ## Lay one arm to grip and read its joints, nothing about bodies yet.
  let chain = posed(s.rig, sc.shoulder[hand.body][hand.arm], g, h, swivel)
  result.pose = chain.pose
  result.joints = joints(sc.shape[hand.body].ax, hand.arm, chain.pose)
  result.over = chain.stretch - (s.rig.upper + s.rig.fore)
  for dof in Dof:
    result.margin[dof] = margin(s.rig.range[dof], reading(result.joints, dof))
  result.cost = comfort(s.rig, result.joints)


func reasonOf(dof: Dof): Reason =
  case dof
  of Dof.Extend, Dof.Across: Reason.Shoulder
  of Dof.Twist: Reason.Twist
  of Dof.Bend: Reason.Elbow
  of Dof.Wrist: Reason.Wrist


func armFaults(s: State; sc: Scene; hand: Hand; lay: ArmLay;
               v: var Verdict; link, arm: int) =
  ## Everything that fails about one laid arm, into verdict: its reach,
  ## its joints, its links through either body.
  if lay.over > 0.0:
    worse(v, lay.over / SLACK, Reason.Reach, link, arm)
  for dof in Dof:
    let m = lay.margin[dof]
    if m < 0.0:
      if -m > v.worst:
        v.dof = dof
      worse(v, -m, reasonOf(dof), link, arm)
  let p = lay.pose
  for (a, b) in [(p.s, p.e), (p.e, p.w), (p.w, p.g)]:
    for who in Body:
      let t = bodyGap(s.rig, sc.shape[who], a, b, own = who == hand.body)
      if t.gap < 0.0:
        if -t.gap / s.rig.limb > v.worst:
          v.part = t.part
          v.whose = who
        worse(v, -t.gap / s.rig.limb, Reason.Through, link, arm)


func links3(p: ArmPose): array[3, (Vec, Vec)] =
  [(p.s, p.e), (p.e, p.w), (p.w, p.g)]


func armsApart(s: State; a, b: ArmPose; meet: Vec; excuse: float;
               v: var Verdict; link, arm: int) =
  ## Every link of one arm against every link of another.
  for (a0, a1) in links3(a):
    for (b0, b1) in links3(b):
      let gap = armGap(s.rig, a0, a1, b0, b1, meet, excuse)
      if gap < 0.0:
        worse(v, -gap / s.rig.limb, Reason.Arms, link, arm)


func fitLink(s: State; sc: Scene; i: int; p: Params; v: var Verdict) =
  ## Evaluate connection `i` at `p`, adding what it finds to `v`.
  var costs = 0.0
  v.fits[i] = LinkFit()
  for k in 0 .. 1:
    let lay = layArm(s, sc, s.links[i].ends[k], p.g, p.h[k], p.swivel[k])
    armFaults(s, sc, s.links[i].ends[k], lay, v, i, k)
    v.fits[i].arms[k] = lay.pose
    v.fits[i].joints[k] = lay.joints
    costs += lay.cost
    # Strain is least margin's, read off margins already taken.
    var
      least = Inf
      dof = Dof.Extend
    for d in Dof:
      if lay.margin[d] < least:
        least = lay.margin[d]
        dof = d
    let most = max(0.0, 1.0 - least)
    if most >= v.fits[i].strain:
      v.fits[i].strain = most
      v.fits[i].strainedArm = k
      v.fits[i].strainedDof = dof
  let band = s.rig.band[s.band]
  if p.g.z < band.lo:
    worse(v, (band.lo - p.g.z) / SLACK, Reason.Band, i, 0)
  elif p.g.z > band.hi:
    worse(v, (p.g.z - band.hi) / SLACK, Reason.Band, i, 0)
  # Within band hands take whatever height constrains joints
  # least: band is bound, not preference, and comfort cost --
  # every joint from its rest, arm's lift, centring -- decides.
  # Grip between two bodies, on line between their centrelines:
  # couple holds hands between them, not wherever both arms happen to hang
  # most easily.  Over crown and set up for turn, over turning
  # partner's head instead.
  let
    a = s.stance[Body.One].centre
    b = s.stance[Body.Two].centre
  var
    mid: Vec = ((a.x + b.x) / 2.0, (a.y + b.y) / 2.0, p.g.z)
    weight = CENTRING[ord(s.band)]
  if s.overhead and s.band == Band.Crown:
    mid = (s.stance[s.turning].centre.x, s.stance[s.turning].centre.y, p.g.z)
    weight = CENTRING[ord(Band.Torso)]
  let off = dist(p.g, mid) / reach(s.rig)
  costs += weight * off * off
  armsApart(s, v.fits[i].arms[0], v.fits[i].arms[1], p.g, EXCUSE, v, i, 0)
  v.cost += costs
  v.strain = max(v.strain, v.fits[i].strain)


func evaluate*(s: State; sc: Scene; ps: openArray[Params]): Verdict =
  ## Judge whole state at these poses, one per connection, scene
  ## already worked out.
  result.n = s.links.len
  for i in 0 ..< s.links.len:
    fitLink(s, sc, i, ps[i], result)
  if s.links.len == 2:
    # Arms of different connections, dancer's own two among them.
    for a in 0 .. 1:
      for b in 0 .. 1:
        armsApart(s, result.fits[0].arms[a], result.fits[1].arms[b],
                  ps[0].g, 0.0, result, 1, b)
  result.ok = result.worst <= TOLERANCE
  if result.ok:
    result.reason = Reason.None


func evaluate*(s: State; ps: openArray[Params]): Verdict =
  ## Judge whole state at these poses, one per connection.
  evaluate(s, sceneOf(s), ps)


func evaluate*(s: State): Verdict =
  ## Judge state at poses it carries.
  evaluate(s, s.params)


#[ Seeding ]#

func seedHolds(s: State; sc: Scene; hand: Hand; c: Circle; g: Vec;
               c_swivel, s_swivel: float; best: float; cost: var float): bool =
  ## Whether one arm laid so holds within tolerance and is cheaper than
  ## `best`, giving up at first thing that says no.
  ##   Same question `evaluate` answers about one arm, asked in
  ##     order that fails soonest and costs least to ask: reach, then each
  ##     joint with twist last, then cost, and only then links
  ##     against bodies.  Answer is same because pose holds
  ##     when its largest failure is within tolerance, and that is when
  ##     every failure is.
  let chain = posedOn(s.rig, c, g, c_swivel, s_swivel)
  let over = chain.stretch - (s.rig.upper + s.rig.fore)
  if over > 0.0 and over / SLACK > TOLERANCE:
    return false
  # Joints as `swing` reads them, one by one, wrist first:
  # hand's direction is one of few on grid, and most miss cone.
  let
    ax = sc.shape[hand.body].ax
    pose = chain.pose
    s0 = ownTerms(ax, hand.arm, pose.s)
    e0 = ownTerms(ax, hand.arm, pose.e)
    w0 = ownTerms(ax, hand.arm, pose.w)
    g0 = ownTerms(ax, hand.arm, pose.g)
    u = unit(e0 - s0)
    f = unit(w0 - e0)
    h = unit(g0 - w0)
  var j: Joints
  j.wrist = angleBetween(f, h)
  if margin(s.rig.range[Dof.Wrist], j.wrist) < -TOLERANCE:
    return false
  j.bend = angleBetween(u, f)
  if margin(s.rig.range[Dof.Bend], j.bend) < -TOLERANCE:
    return false
  j.extend = arcsin(clamp(-u.y, -1.0, 1.0))
  if margin(s.rig.range[Dof.Extend], j.extend) < -TOLERANCE:
    return false
  j.across = arcsin(clamp(-u.x, -1.0, 1.0))
  if margin(s.rig.range[Dof.Across], j.across) < -TOLERANCE:
    return false
  j.elev = arcsin(clamp(u.z, -1.0, 1.0))
  j.twist = twistOf(Swing(joints: j, u: u, f: f))
  if margin(s.rig.range[Dof.Twist], j.twist) < -TOLERANCE:
    return false
  let c0 = comfort(s.rig, j)
  if not (c0 < best):
    return false
  let p = chain.pose
  for (a, b) in [(p.s, p.e), (p.e, p.w), (p.w, p.g)]:
    for who in Body:
      let t = bodyGap(s.rig, sc.shape[who], a, b, own = who == hand.body)
      if t.gap < 0.0 and -t.gap / s.rig.limb > TOLERANCE:
        return false
  cost = c0
  true


func armSeed(s: State; sc: Scene; hand: Hand; g: Vec; fine: bool): Option[(Vec, float)] =
  ## Most comfortable hand direction and swivel for one arm at grip `g`,
  ## taken on its own; none if no pair holds.
  let
    dirs = if fine: DIRS26 else: DIRS14
    turns = if fine: 24 else: 12
  var best = Inf
  for h in dirs:
    let c = circleOf(s.rig, sc.shoulder[hand.body][hand.arm], g, h)
    for j in 0 ..< turns:
      let swivel = j.float * 2.0 * PI / turns.float
      var cost: float
      if seedHolds(s, sc, hand, c, g, cos(swivel), sin(swivel), best, cost):
        best = cost
        result = some((h, swivel))


func seeds*(s: State; i: int; fine = false; keep = 5): seq[Params] =
  ## First poses for connection `i` from grid over grip, cheapest
  ## few, cheapest first; empty where none holds.
  ##   Several rather than one, because cheapest grid point need not lie
  ##     in basin of cheapest pose; caller refines each and
  ##     keeps best.
  let
    sc = sceneOf(s)
    a = sc.shoulder[s.links[i].ends[0].body][s.links[i].ends[0].arm]
    b = sc.shoulder[s.links[i].ends[1].body][s.links[i].ends[1].arm]
    r = reach(s.rig)
    band = s.rig.band[s.band]
    step = if fine: 0.08 else: 0.12
    mid: Vec = ((a.x + b.x) / 2.0, (a.y + b.y) / 2.0, 0.0)
    span = int(r / step) + 1
    layers = int((band.hi - band.lo) / step) + 1
  var
    costs: seq[float]
    one = s ## State with this connection alone, made once.
  one.links = @[s.links[i]]
  # Grid about point between shoulders, which is always on it, up
  # through band with its top layer on it too.
  for iz in 0 .. layers:
    let z = min(band.lo + 0.01 + iz.float * step, band.hi - 0.005)
    for iy in -span .. span:
      let y = mid.y + iy.float * step
      for ix in -span .. span:
        let x = mid.x + ix.float * step
        let g: Vec = (x, y, z)
        if dist(g, a) <= r and dist(g, b) <= r:
          let
            p0 = armSeed(s, sc, s.links[i].ends[0], g, fine)
            p1 = armSeed(s, sc, s.links[i].ends[1], g, fine)
          if p0.isSome and p1.isSome:
            let p = Params(g: g, h: [p0.get[0], p1.get[0]],
                           swivel: [p0.get[1], p1.get[1]])
            let v = evaluate(one, sc, [p])
            if v.ok:
              # Keep cheapest few, in order.
              var at = costs.len
              while at > 0 and costs[at - 1] > v.cost:
                dec at
              if at < keep:
                costs.insert(v.cost, at)
                result.insert(p, at)
                if costs.len > keep:
                  costs.setLen(keep)
                  result.setLen(keep)


#[ Refining ]#

type Moves* = object ## Steps pattern search is taking.
  dist*, angle*: float


func moved(p: Params; which: int; sign: float; m: Moves): Params =
  ## Pose `p` with one of its nine numbers stepped.
  ##   0..2 grip; 3..4 and 6..7 each hand turned about two axes across
  ##   it; 5 and 8 each swivel.
  result = p
  case which
  of 0: result.g.x += sign * m.dist
  of 1: result.g.y += sign * m.dist
  of 2: result.g.z += sign * m.dist
  else:
    let k = if which < 6: 0 else: 1
    case (which - 3) mod 3
    of 0: result.h[k] = spun(p.h[k], perp(p.h[k]), sign * m.angle)
    of 1: result.h[k] = spun(p.h[k], cross(p.h[k], perp(p.h[k])), sign * m.angle)
    else: result.swivel[k] += sign * m.angle


func better(a, b: Verdict; feasible: bool): bool =
  ## Whether `a` beats `b`: by cost among poses that hold, else by failure.
  if feasible:
    a.ok and (not b.ok or a.cost < b.cost - 1e-12)
  else:
    if abs(a.penalty - b.penalty) > 1e-12: a.penalty < b.penalty
    else: a.cost < b.cost - 1e-12


func within(p, home: Params; trust: float): bool =
  ## Whether pose is still within trust region of where it started.
  if trust >= Inf:
    return true
  if dist(p.g, home.g) > trust:
    return false
  let turn = trust * 7.0 # radians: one tenth of metre allows forty degrees
  for k in 0 .. 1:
    if angleBetween(p.h[k], home.h[k]) > turn or
       abs(p.swivel[k] - home.swivel[k]) > turn:
      return false
  true


func refined*(s: State; start: seq[Params]; feasible: bool;
              first = Moves(dist: 0.04, angle: 15.0 * PI / 180.0);
              trust = Inf): tuple[params: seq[Params], verdict: Verdict] =
  ## Pattern-search from `start`: by comfort among poses that hold when
  ## `feasible`, else by largest failure until nothing fails.
  ##   One trial pose is kept and one of its numbers changed and put back
  ##     for each move tried; best move of round is remembered as
  ##     one move and made once at round's end.
  let sc = sceneOf(s)
  var
    ps = start
    trial = start
    m = first
    v = evaluate(s, sc, ps)
  const
    LEAST_DIST = 0.001
    LEAST_ANGLE = 0.5 * PI / 180.0
  var rounds = 0
  while (m.dist >= LEAST_DIST or m.angle >= LEAST_ANGLE) and rounds < 400:
    inc rounds
    var
      bestV = v
      bestI, bestWhich = 0
      bestSign = 0.0
      improved = false
    for i in 0 ..< ps.len:
      for which in 0 .. 8:
        for sign in [-1.0, 1.0]:
          trial[i] = moved(ps[i], which, sign, m)
          if within(trial[i], start[i], trust):
            let tv = evaluate(s, sc, trial)
            if better(tv, bestV, feasible):
              bestV = tv
              bestI = i
              bestWhich = which
              bestSign = sign
              improved = true
          trial[i] = ps[i]
    if improved:
      ps[bestI] = moved(ps[bestI], bestWhich, bestSign, m)
      trial[bestI] = ps[bestI]
      v = bestV
      if not feasible and v.ok:
        break
    else:
      m.dist /= 2.0
      m.angle /= 2.0
  (ps, v)


#[ Settling ]#

func jump*(va, vb: Verdict): float =
  ## Furthest any joint moves between two verdicts on same links.
  for i in 0 ..< va.n:
    for k in 0 .. 1:
      let
        p = va.fits[i].arms[k]
        q = vb.fits[i].arms[k]
      for (x, y) in [(p.e, q.e), (p.w, q.w), (p.g, q.g)]:
        result = max(result, dist(x, y))

func jump*(a, b: State): float =
  ## Furthest any joint moves between two solved states of same links.
  jump(evaluate(a), evaluate(b))


func restingsWith*(s: State; fine = false): seq[Solved] =
  ## Distinct poses search settles on, most comfortable first, each
  ## with its verdict; empty where some connection has no pose that holds.
  ##   Each connection's few best seeds are refined on their own; every
  ##     distinct pose of first connection is kept, paired with best
  ##     of second, and with two connections pair is refined
  ##     together.  Distinct means joint sits more than hand's breadth
  ##     from where it sits in every pose already kept.
  var perLink: seq[seq[Params]]
  for i in 0 ..< s.links.len:
    var one = s
    one.links = @[s.links[i]]
    var kept: seq[(float, Params, Verdict)]
    for seed in seeds(s, i, fine):
      let got = refined(one, @[seed], feasible = true)
      if not got.verdict.ok:
        continue
      var fresh = true
      for (_, _, v) in kept:
        if jump(v, got.verdict) < 0.10:
          fresh = false
      if fresh:
        var at = kept.len
        while at > 0 and kept[at - 1][0] > got.verdict.cost:
          dec at
        kept.insert((got.verdict.cost, got.params[0], got.verdict), at)
    if kept.len == 0:
      return
    var ps: seq[Params]
    for (_, p, _) in kept: ps.add p
    perLink.add ps
  for first in perLink[0]:
    var starts = @[first]
    for i in 1 ..< s.links.len:
      starts.add perLink[i][0]
    var got = (params: starts, verdict: evaluate(s, starts))
    if s.links.len > 1:
      got = refined(s, starts, feasible = true)
      if not got.verdict.ok:
        # Settled apart, two may lie through each other; work free first.
        got = refined(s, starts, feasible = false)
        if got.verdict.ok:
          got = refined(s, got.params, feasible = true)
    if got.verdict.ok:
      var done = Solved(state: s, verdict: got.verdict)
      done.state.params = got.params
      var at = result.len
      while at > 0 and result[at - 1].verdict.cost > got.verdict.cost:
        dec at
      result.insert(done, at)


func restings*(s: State; fine = false): seq[State] =
  ## Distinct poses search settles on, most comfortable first;
  ## empty where some connection has no pose that holds.
  for got in restingsWith(s, fine):
    result.add got.state


func settled*(s: State; fine = false): Option[Solved] =
  ## Most comfortable pose of every connection, from nothing, with its
  ## verdict; none where some connection has no pose that holds.
  let all = restingsWith(s, fine)
  if all.len == 0: none(Solved) else: some(all[0])

func settle*(s: State; fine = false): Option[State] =
  ## Most comfortable pose of every connection, from nothing; none where
  ## some connection has no pose that holds.
  let got = settled(s, fine)
  if got.isNone: none(State) else: some(got.get.state)


func followed*(s: State; before: State; trust = 0.15): Option[Solved] =
  ## Pose of `s` reached from `before`'s pose by small moves, with its
  ## verdict: what arm does when body turns slightly.  None where no
  ## small move holds.
  var ps = before.params
  var v = evaluate(s, ps)
  let gentle = Moves(dist: 0.01, angle: 5.0 * PI / 180.0)
  if not v.ok:
    let back = refined(s, ps, feasible = false, first = gentle, trust = trust)
    if not back.verdict.ok:
      return none(Solved)
    ps = back.params
  let got = refined(s, ps, feasible = true, first = gentle, trust = trust)
  var done = Solved(state: s, verdict: got.verdict)
  done.state.params = got.params
  some(done)

func follow*(s: State; before: State; trust = 0.15): Option[State] =
  ## Pose of `s` reached from `before`'s pose by small moves.
  let got = followed(s, before, trust)
  if got.isNone: none(State) else: some(got.get.state)


func reason*(s: State; before: State; trust = Inf): Verdict =
  ## Why no small move from `before` holds in `s`: failure that remains
  ## when largest has been made as small as it can.
  refined(s, before.params, feasible = false,
          first = Moves(dist: 0.01, angle: 5.0 * PI / 180.0),
          trust = trust).verdict


#[ Routing ]#

func sweptRound(rig: Rig; v: Verdict; i, k: int; st: Stance): float =
  ## Angle one arm sweeps round body's axis, seen from above, signed,
  ## counting only arm below crown: how far round that body arm
  ## goes, where body is.
  ##   Above crown arm is round nothing, and may pass over head
  ##     from one side to other; below it sweep changes only by
  ##     small amounts under small moves, and by whole half turn only when
  ##     arm has passed through body.  Over shoulder is beside
  ##     neck, which is off axis, so that too is small move.
  let
    p = v.fits[i].arms[k]
    z1 = rig.top[Part.Head] + rig.limb
  for (a, b) in [(p.s, p.e), (p.e, p.w), (p.w, p.g)]:
    let dz = b.z - a.z
    var lo, hi: float
    if abs(dz) < 1e-12:
      if a.z > z1:
        continue
      lo = 0.0
      hi = 1.0
    else:
      lo = (z1 - a.z) / dz
      if dz > 0.0:
        hi = min(lo, 1.0)
        lo = 0.0
      else:
        lo = max(lo, 0.0)
        hi = 1.0
      if lo >= hi:
        continue
    let
      ax = a.x + (b.x - a.x) * lo - st.centre.x
      ay = a.y + (b.y - a.y) * lo - st.centre.y
      bx = a.x + (b.x - a.x) * hi - st.centre.x
      by = a.y + (b.y - a.y) * hi - st.centre.y
    result += arctan2(ax * by - ay * bx, ax * bx + ay * by)


func routing*(s: State; v: Verdict): seq[float] =
  ## Every arm's sweep round every body: shape of pose that no
  ## small motion changes.
  for i in 0 ..< s.links.len:
    for k in 0 .. 1:
      for who in Body:
        result.add sweptRound(s.rig, v, i, k, s.stance[who])

func routing*(s: State): seq[float] =
  ## Same, state judged here.
  routing(s, evaluate(s))


func sameRoute*(a: State; va: Verdict; b: State; vb: Verdict): bool =
  ## Whether two judged poses of same links go round bodies
  ## same way, so that one can become other without arm passing
  ## through anybody.
  ##   Arm that has gone round body cannot get to pose that has not,
  ##     however comfortable; that is what being wound is.
  let
    ra = routing(a, va)
    rb = routing(b, vb)
  if ra.len != rb.len:
    return false
  for i in 0 ..< ra.len:
    if abs(ra[i] - rb[i]) >= PI:
      return false
  true

func sameRoute*(a, b: State): bool =
  ## Same, states judged here.
  sameRoute(a, evaluate(a), b, evaluate(b))
