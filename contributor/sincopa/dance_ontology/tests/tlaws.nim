discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on -d:danger $options $file"
batchable: true
joinable: true
"""
## Hold body sim to its laws.
##
##   Every law here is about bodies, joints and arms, and none is about dance: sim is
##     witness, and witness that has been told what to say is no witness.  Floor's own
##     claims are printed beside what sim says, and each is held to what sim answers
##     today, so neither side moves unnoticed; `-d:floorIsLaw` holds sim to floor
##     outright, which three claims fail.
##   Sweeps are computed once and shared by suites: they are slow part, and laws are
##     about their every moment.
##   Cost: sweeps run on every core (`sweptAll`), so wall time follows core count;
##     22 s on four cores in danger build, measured 2026-09-05 (see PROVENANCE.md).

{.experimental: "strictFuncs".}

import std/[math, options, random, sequtils, strformat, strutils, unittest]

import ../sim/[body, contact, limb, read, rig, solve, sweep, vec]


const
  APART = 0.40
  LEFT = Arm.Left
  RIGHT = Arm.Right


func oneLink(a, b: Arm; band: Band; apart = APART; away = false): State =
  ## Stand couple square with one connection, One's `a` to Two's `b`.
  result = State(rig: HUMAN, stance: facing(HUMAN, apart), band: band,
                 links: @[Link(ends: [(Body.One, a), (Body.Two, b)])])
  if away:
    result.stance[Body.Two].facing -= PI

func twoLinks(a, b, c, d: Arm; band: Band; away = false): State =
  ## Both hands held: One's `a` to Two's `b`, One's `c` to Two's `d`.
  result = State(rig: HUMAN, stance: facing(HUMAN, APART), band: band,
                 links: @[Link(ends: [(Body.One, a), (Body.Two, b)]),
                          Link(ends: [(Body.One, c), (Body.Two, d)])])
  if away:
    result.stance[Body.Two].facing -= PI

func deg(r: float): string = $int(round(r * 180.0 / PI))

func drawn(v: Verdict; i: int): array[7, Vec] =
  ## One connection as seven points: shoulder to shoulder through grip.
  ##   Rebuilt here rather than borrowed from reader, which keeps its own copy
  ##     private: borrowing it would check reader against itself (Article II.9).
  let
    a = v.fits[i].arms[0]
    b = v.fits[i].arms[1]
  [a.s, a.e, a.w, a.g, b.w, b.e, b.s]

func nearestOn(line: array[7, Vec]; p: Vec): tuple[off, z: float] =
  ## How far `p` lies off polyline in plan, and how high polyline is there.
  result = (1e9, 0.0)
  for i in 0 ..< 6:
    let
      a = line[i]
      b = line[i + 1]
      dx = b.x - a.x
      dy = b.y - a.y
      run = dx * dx + dy * dy
    if run < 1e-18:
      continue
    let
      u = clamp(((p.x - a.x) * dx + (p.y - a.y) * dy) / run, 0.0, 1.0)
      off = sqrt((p.x - a.x - dx * u) ^ 2 + (p.y - a.y - dy * u) ^ 2)
    if off < result.off:
      result = (off, a.z + (b.z - a.z) * u)

proc turns(x: float): string = formatFloat(x, ffDecimal, 2)


#[ Sweeps, Once ]#

func job(rest: State; who = Body.Two): Job = Job(rest: rest, who: who, most: MOST)

let
  sweeps = sweptAll([ # Longest first: chains over head reach furthest of all.
    job(twoLinks(LEFT, RIGHT, RIGHT, LEFT, Band.Crown)),
    job(twoLinks(LEFT, LEFT, RIGHT, RIGHT, Band.Crown, away = true)),
    job(oneLink(LEFT, LEFT, Band.Crown)),
    job(oneLink(LEFT, RIGHT, Band.Crown)),
    job(oneLink(RIGHT, RIGHT, Band.Crown)),
    job(oneLink(RIGHT, LEFT, Band.Crown)),
    job(oneLink(LEFT, LEFT, Band.Torso)),
    job(oneLink(LEFT, LEFT, Band.Neck)),
    job(oneLink(LEFT, RIGHT, Band.Torso)),
    job(oneLink(LEFT, RIGHT, Band.Neck)),
    job(oneLink(RIGHT, RIGHT, Band.Torso)),
    job(oneLink(RIGHT, LEFT, Band.Torso)),
    job(oneLink(LEFT, LEFT, Band.Torso), Body.One),
    job(twoLinks(LEFT, RIGHT, RIGHT, LEFT, Band.Torso)),
    job(twoLinks(LEFT, LEFT, RIGHT, RIGHT, Band.Torso, away = true))])
  pairCrown = sweeps[0]
  crossedCrown = sweeps[1]
  llCrown = sweeps[2]
  lrCrown = sweeps[3]
  rrCrown = sweeps[4]
  rlCrown = sweeps[5]
  llTorso = sweeps[6]
  llNeck = sweeps[7]
  lrTorso = sweeps[8]
  lrNeck = sweeps[9]
  rrTorso = sweeps[10]
  rlTorso = sweeps[11]
  llByOne = sweeps[12]
  pairTorso = sweeps[13]
  crossedTorso = sweeps[14]
  SWEEPS = [("L-l torso", llTorso), ("L-l neck", llNeck), ("L-l crown", llCrown),
            ("L-r torso", lrTorso), ("L-r neck", lrNeck), ("L-r crown", lrCrown),
            ("R-r torso", rrTorso), ("R-r crown", rrCrown),
            ("R-l torso", rlTorso), ("R-l crown", rlCrown),
            ("L-l by One", llByOne),
            ("L-r.R-l torso", pairTorso), ("L-l.R-r torso, away", crossedTorso),
            ("L-r.R-l crown", pairCrown), ("L-l.R-r crown, away", crossedCrown)]


#[ Rig ]#

suite "the rig":
  test "a body's rounds are the tape's, and the radii follow":
    for part in Part:
      let
        a = halfBreadth(HUMAN, part)
        b = halfDepth(HUMAN, part)
        h = ((a - b) / (a + b)) ^ 2
        round = PI * (a + b) * (1.0 + 3.0 * h / (10.0 + sqrt(4.0 - 3.0 * h)))
      check abs(round - HUMAN.round[part]) < 1e-3
    check abs(halfBreadth(HUMAN, Part.Neck) - HUMAN.round[Part.Neck] / (2.0 * PI)) < 1e-9
    check halfDepth(HUMAN, Part.Torso) < halfBreadth(HUMAN, Part.Torso)

  test "the reach is the three links, and the bands are ordered":
    check abs(reach(HUMAN) - 0.64) < 1e-9
    check HUMAN.band[Band.Torso].hi < HUMAN.band[Band.Neck].lo
    check HUMAN.band[Band.Neck].hi <= HUMAN.band[Band.Crown].lo
    check HUMAN.band[Band.Crown].lo >= HUMAN.top[Part.Head] + HUMAN.limb - 1e-9
    for part in Part:
      check rig.bottom(HUMAN, part) < HUMAN.top[part]

  test "the shoulder stands outside its own torso, and a hanging arm clears it":
    check HUMAN.shoulderOut > halfBreadth(HUMAN, Part.Torso)
    let st = facing(HUMAN, APART)[Body.One]
    for arm in Arm:
      let s = shoulder(HUMAN, st, arm)
      check bodyGap(HUMAN, st, s, lifted(s, -HUMAN.upper), own = true).gap >= 0.0

  test "two bodies cannot stand closer than their chests":
    check abs(touching(HUMAN) - 2.0 * halfDepth(HUMAN, Part.Torso)) < 1e-9

  test "a hand is a quarter turn off the way its body faces":
    let st = facing(HUMAN, APART)
    let l1 = shoulder(HUMAN, st[Body.One], LEFT)
    let l2 = shoulder(HUMAN, st[Body.Two], LEFT)
    check abs(l1.x + HUMAN.shoulderOut) < 1e-9 and abs(l1.y) < 1e-9
    check abs(l2.x - HUMAN.shoulderOut) < 1e-9 and abs(l2.y - APART) < 1e-9
    check abs(l1.z - HUMAN.shoulderUp) < 1e-9


#[ One Arm ]#

suite "one arm, forward and back":
  let st = facing(HUMAN, APART)[Body.One]

  test "the elbow keeps both lengths on every swivel":
    var rng = initRand(7)
    for _ in 0 ..< 200:
      let
        s = shoulder(HUMAN, st, LEFT)
        g = s + (rng.rand(-0.5 .. 0.5), rng.rand(-0.5 .. 0.5), rng.rand(-0.5 .. 0.3))
        h = unit((rng.rand(-1.0 .. 1.0), rng.rand(-1.0 .. 1.0), rng.rand(-1.0 .. 1.0)))
        c = posed(HUMAN, s, g, h, rng.rand(0.0 .. 2.0 * PI))
      if c.stretch <= HUMAN.upper + HUMAN.fore and c.stretch >= abs(HUMAN.upper - HUMAN.fore):
        check abs(dist(c.pose.s, c.pose.e) - HUMAN.upper) < 1e-9
        check abs(dist(c.pose.e, c.pose.w) - HUMAN.fore) < 1e-9
      check abs(dist(c.pose.w, c.pose.g) - HUMAN.hand) < 1e-9

  test "the joints read back what they were set to":
    var worst = 0.0
    for arm in Arm:
      for az in [-60.0, -20.0, 20.0, 60.0, 120.0]:
        for el in [-70.0, -30.0, 10.0, 50.0]:
          for tw in [-50.0, 0.0, 60.0]:
            for bend in [20.0, 70.0, 120.0]:
              for wr in [0.0, 30.0]:
                let
                  u = unit((cos(el * PI / 180.0) * sin(az * PI / 180.0),
                            cos(el * PI / 180.0) * cos(az * PI / 180.0),
                            sin(el * PI / 180.0)))
                  p = placed(HUMAN, st, arm, u, tw * PI / 180.0, bend * PI / 180.0,
                             wr * PI / 180.0, 0.7)
                  j = joints(st, arm, p)
                worst = max(worst, abs(j.twist - tw * PI / 180.0))
                worst = max(worst, abs(j.bend - bend * PI / 180.0))
                worst = max(worst, abs(j.wrist - wr * PI / 180.0))
                worst = max(worst, abs(sin(j.elev) - u.z))
                worst = max(worst, abs(-sin(j.extend) - u.y))
                worst = max(worst, abs(-sin(j.across) - u.x))
    check worst < 1e-6

  test "the twist reads the same across the arm pointing forward":
    for arm in Arm:
      let
        a = joints(st, arm, placed(HUMAN, st, arm, unit((0.0, 1.0, 0.02)), 0.3, 1.2, 0.2, 0.0))
        b = joints(st, arm, placed(HUMAN, st, arm, unit((0.0, 1.0, -0.02)), 0.3, 1.2, 0.2, 0.0))
      check abs(a.twist - b.twist) < 0.05

  test "the left arm is the right arm in a mirror":
    let
      u = unit((0.4, 0.6, -0.3))
      r = joints(st, RIGHT, placed(HUMAN, st, RIGHT, u, -0.5, 1.4, 0.4, 0.3))
      l = joints(st, LEFT, placed(HUMAN, st, LEFT, u, -0.5, 1.4, 0.4, 0.3))
    check abs(r.twist - l.twist) < 1e-9 and abs(r.across - l.across) < 1e-9
    check abs(r.extend - l.extend) < 1e-9 and abs(r.bend - l.bend) < 1e-9

  test "a range's margin is an ease in, nought at the edge, negative past it":
    let r = HUMAN.range[Dof.Twist]
    check abs(margin(r, r.hi) - 0.0) < 1e-9
    check abs(margin(r, r.hi - r.easeHi) - 1.0) < 1e-9
    check margin(r, r.hi + 0.1) < 0.0
    check abs(margin(r, r.lo) - 0.0) < 1e-9
    let e = HUMAN.range[Dof.Bend]
    check margin(e, 0.0) > 1.0   # stop leant on costs nothing
    check margin(e, -0.1) < 0.0  # past stop refuses


#[ Contacts ]#

suite "nothing passes through anybody":
  test "the clipped test agrees with a sampled truth, and errs only wide":
    var rng = initRand(11)
    for _ in 0 ..< 300:
      let
        a: Vec = (rng.rand(-0.5 .. 0.5), rng.rand(-0.5 .. 0.5), rng.rand(0.6 .. 1.9))
        b: Vec = (rng.rand(-0.5 .. 0.5), rng.rand(-0.5 .. 0.5), rng.rand(0.6 .. 1.9))
        z0 = 0.8
        z1 = 1.36
        got = axisNear(a, b, z0, z1).d
      var truth = Inf
      for i in 0 .. 400:
        let p = a + (b - a) * (i.float / 400.0)
        if p.z >= z0 and p.z <= z1:
          truth = min(truth, sqrt(p.x * p.x + p.y * p.y))
      if truth == Inf:
        check got == Inf
      else:
        check got <= truth + 1e-9
        check got >= truth - 0.003

  test "over the crown there is nothing to hit":
    let st = facing(HUMAN, APART)[Body.Two]
    let top = HUMAN.top[Part.Head] + HUMAN.limb + 0.001
    check bodyGap(HUMAN, st, (0.0, 0.0, top), (0.0, 0.8, top), own = false).gap == Inf

  test "no link enters a body in any moment of any sweep":
    var least = Inf
    for (name, sw) in SWEEPS:
      for m in sw.moments:
        let v = m.verdict
        for i in 0 ..< v.n:
          for k in 0 .. 1:
            let
              hand = m.state.links[i].ends[k]
              p = v.fits[i].arms[k]
            for (a, b) in [(p.s, p.e), (p.e, p.w), (p.w, p.g)]:
              for who in Body:
                least = min(least, bodyGap(HUMAN, m.state.stance[who], a, b,
                                           own = who == hand.body).gap)
    echo "    the deepest any link presses into a body: " &
      &"{formatFloat(-least * 1000, ffDecimal, 1)} mm"
    check least >= -TOLERANCE * HUMAN.limb - 1e-9

  test "two arms keep an arm's thickness apart, except where the hands meet":
    for (name, sw) in SWEEPS:
      for m in sw.moments:
        check m.verdict.ok


#[ At Rest ]#

suite "at rest":
  test "every hold rests at every band":
    for band in Band:
      for (a, b) in [(LEFT, LEFT), (LEFT, RIGHT), (RIGHT, LEFT), (RIGHT, RIGHT)]:
        check settle(oneLink(a, b, band)).isSome
      check settle(twoLinks(LEFT, RIGHT, RIGHT, LEFT, band)).isSome
      check settle(twoLinks(LEFT, LEFT, RIGHT, RIGHT, band, away = true)).isSome

  test "every returned pose is inside every range":
    for (name, sw) in SWEEPS:
      for m in sw.moments:
        check m.verdict.ok
        check m.verdict.strain <= 1.0 + TOLERANCE + 1e-9

  test "L-l is R-r in a mirror, and L-r is R-l":
    ## Mirror of most comfortable pose is most comfortable pose, so costs agree;
    ## where two tie, grid may pick either, so poses themselves are only held to
    ## within hand's breadth.
    for (a, b) in [(llTorso, rrTorso), (lrTorso, rlTorso)]:
      let
        va = evaluate(a.rest)
        vb = evaluate(b.rest)
      check abs(va.cost - vb.cost) < 0.02 * max(va.cost, vb.cost) + 0.01
      for k in 0 .. 1:
        check abs(va.fits[0].arms[k].g.x + vb.fits[0].arms[k].g.x) < 0.15
        check abs(va.fits[0].arms[k].g.y - vb.fits[0].arms[k].g.y) < 0.15


#[ Turning ]#

suite "turning":
  test "the rest holds, and every sweep has its rest among its moments":
    for (name, sw) in SWEEPS:
      check sw.restHolds
      var hasRest = false
      for m in sw.moments:
        if abs(m.turn) < 1e-9: hasRest = true
      check hasRest

  test "no moment goes round a body another way than the one before":
    for (name, sw) in SWEEPS:
      for i in 1 ..< sw.moments.len:
        check sameRoute(sw.moments[i - 1].state, sw.moments[i].state)

  test "a moment's joints move no further than an arm can in a fiftieth of a turn":
    for (name, sw) in SWEEPS:
      var most = 0.0
      var big = 0
      for i in 1 ..< sw.moments.len:
        let j = jump(sw.moments[i - 1].state, sw.moments[i].state)
        most = max(most, j)
        if j > 0.30: inc big
      echo &"    {name}: furthest a joint moves between moments " &
        &"{formatFloat(most, ffDecimal, 2)} m, {big} moves over 0.30"
      check most < 0.80

  test "the block is bracketed with a name":
    for (name, sw) in SWEEPS:
      for (sign, blk) in [(-1.0, sw.neg), (1.0, sw.pos)]:
        if blk.stopped:
          check blk.why.reason != Reason.None
          check blk.at < MOST
          let edge = sw.at(sign * blk.at)
          check edge.isSome and edge.get.verdict.ok
        else:
          # No block means moment stands at every turn asked for, last one holding:
          # `at` alone says nothing, since unstopped sweep reports what it was asked.
          let edge = sw.at(sign * MOST)
          check edge.isSome
          check abs(abs(edge.get.turn) - MOST) < STEP
          check edge.get.verdict.ok
        let found = if blk.foundAnyway: " (a pose exists there, re-organised)" else: ""
        echo &"    {name} {(if sign < 0: \"-\" else: \"+\")}{turns(blk.at)}: " &
          (if blk.stopped: &"{blk.why.reason}" & found else: "no block")

  test "L-l is R-r in a mirror when turned, and L-r is R-l":
    for (a, b) in [(llTorso, rrTorso), (lrTorso, rlTorso),
                   (llCrown, rrCrown), (lrCrown, rlCrown)]:
      check abs(limit(a, -1.0) - limit(b, 1.0)) < 0.08
      check abs(limit(a, 1.0) - limit(b, -1.0)) < 0.08

  test "turning the lead of a same-name hold is turning the follow":
    ## Swap two bodies and same-name hold is itself, so what blocks lead turning
    ## anticlockwise blocks follow turning same way.
    check abs(llByOne.pos.at - llTorso.pos.at) < 0.08
    check abs(llByOne.neg.at - llTorso.neg.at) < 0.08

  test "far apart, reach is the block":
    check settle(oneLink(LEFT, RIGHT, Band.Torso, apart = 1.20)).isSome
    check settle(oneLink(LEFT, RIGHT, Band.Torso, apart = 1.34)).isNone

  test "an arm lies on its own body below the crown, and nowhere over it":
    ## Reader answers none at crown by early return, so same law is read at torso,
    ##   where it must do work: both aspects turn up over one sweep.
    for sw in [llCrown, lrCrown, rrCrown, rlCrown]:
      for m in sw.moments:
        check m.verdict.fits[0].arms[0].g.z > m.state.rig.top[Part.Head]
        for who in Body:
          check lyingOn(m.state, m.verdict, 0, who).isNone
    var
      lies = 0
      aspects: set[Aspect]
    for m in llTorso.moments:
      for who in Body:
        let lay = lyingOn(m.state, m.verdict, 0, who)
        if lay.isSome:
          inc lies
          aspects.incl lay.get.aspect
    echo &"    L-l torso: {lies} of {2 * llTorso.moments.len} readings lie on own body"
    check lies > 0
    check aspects == {Aspect.Fore, Aspect.Aft}


#[ Two Hands ]#

suite "two hands":
  test "the crossings are counted off the drawn arms, not assumed":
    ## Every crossing must sit on both connections in plan, and name which is higher
    ##   there.  Corpus is both two-hand holds at every band over five turns: sweeps
    ##   show no crossing at any moment they accept, so they cannot be corpus.
    var seen = 0
    for rest in [twoLinks(LEFT, RIGHT, RIGHT, LEFT, Band.Torso),
                 twoLinks(LEFT, LEFT, RIGHT, RIGHT, Band.Torso, away = true)]:
      for band in Band:
        for turn in [0.0, 0.25, 0.5, 0.75, 1.0]:
          var s = rest
          s.band = band
          s.stance = turned(rest.stance, Body.Two, turn)
          let got = settle(s)
          if got.isNone:
            continue
          let
            v = evaluate(got.get)
            p = drawn(v, 0)
            q = drawn(v, 1)
          for c in crossings(got.get, v):
            inc seen
            let
              i = int(c.along)
              on = p[i] + (p[i + 1] - p[i]) * (c.along - i.float)
              other = nearestOn(q, c.at)
            check abs(c.at.x - on.x) < 1e-9 and abs(c.at.y - on.y) < 1e-9
            check other.off < 1e-9
            check (c.over == 0) == (c.at.z >= other.z)
    echo &"    {seen} crossings read off two holds, three bands, five turns"
    check seen > 0

  test "a whole turn leaves a body's axes where they were":
    ## Solver reads stance's axes and never its lap count, so whole turn is no turn
    ##   to pose sought without history: diamond is rest to it, and swan is X.
    ##   Rungs past half turn are reached by sweep, which carries arms from moment to
    ##   moment, and both two-hand sweeps block by 0.58.
    let st = facing(HUMAN, APART)
    for laps in [-2.0, -1.0, 1.0, 2.0]:
      let
        there = turned(st, Body.Two, laps)
        here = axesOf(st[Body.Two])
        gone = axesOf(there[Body.Two])
      check dist(here.right, gone.right) < 1e-12
      check dist(here.fore, gone.fore) < 1e-12
      check abs(twist(there) - twist(st) - laps * 2.0 * PI) < 1e-12

  test "the chain is decided, rung by rung":
    for band in Band:
      for (turn, name) in [(0.5, "cross"), (1.0, "diamond"), (1.5, "swan")]:
        var s = twoLinks(LEFT, RIGHT, RIGHT, LEFT, band)
        s.stance = turned(s.stance, Body.Two, turn)
        let got = settle(s)
        var held = "no pose holds"
        if got.isSome:
          held = &"a pose holds, strain {formatFloat(evaluate(got.get).strain, ffDecimal, 2)}"
        echo &"    L-r.R-l {band} at {turns(turn)} ({name}): " & held
        check got.isSome


#[ Floor's Claims ]#

suite "the floor's claims":
  test "floor says / sim says, and which claims sim is short of":
    ## Floor is Architect's own, danced; where sim disagrees it is sim that is wrong.
    ##   `is_met` records which claims sim meets today, so neither side moves without
    ##     this going red: mending sim is what changes it to true.
    ##   `-d:floorIsLaw` holds sim to floor outright; three rows fail there today.
    let claims = [
      ("L-l low, the lock way, a whole turn", &"blocks at {turns(llTorso.neg.at)}",
       llTorso.neg.at >= 0.95 and llTorso.neg.at < 1.5, true),
      ("L-l low, the wrap way, half a turn", &"blocks at {turns(llTorso.pos.at)}",
       llTorso.pos.at >= 0.45 and llTorso.pos.at < 1.0, false),
      ("L-l high, a whole turn either way",
       &"blocks at -{turns(llNeck.neg.at)} +{turns(llNeck.pos.at)}",
       llNeck.neg.at >= 0.95 and llNeck.pos.at >= 0.95, false),
      ("L-l above, no block",
       &"blocks at -{turns(llCrown.neg.at)} +{turns(llCrown.pos.at)}",
       not llCrown.neg.stopped and not llCrown.pos.stopped, true),
      ("L-r low, the wrap way, half a turn", &"blocks at {turns(lrTorso.neg.at)}",
       lrTorso.neg.at >= 0.45 and lrTorso.neg.at < 1.0, true),
      ("L-r low, the lock way, a whole turn", &"blocks at {turns(lrTorso.pos.at)}",
       lrTorso.pos.at >= 0.95 and lrTorso.pos.at < 1.5, false),
      ("L-r.R-l low, half a turn",
       &"blocks at -{turns(pairTorso.neg.at)} +{turns(pairTorso.pos.at)}",
       pairTorso.neg.at >= 0.45 and pairTorso.pos.at >= 0.45, true)]
    for (claim, said, agrees, is_met) in claims:
      echo &"    {claim}: {said}" & (if agrees: "  (agrees)" else: "  (DISAGREES)")
      checkpoint(claim)
      check agrees == is_met
      when defined(floorIsLaw):
        check agrees



  test "no moment passes one connection through another":
    ## Crossings come and go in pairs where arms pass over one another, which
    ##   leaves writhe where it was, and singly only where one slides off end
    ##   of either connection. Lone crossing leaving middle of both is arms
    ##   through arms, and no moment of any sweep may do it.
    ##   Read on both chains, which are only sweeps carrying two connections;
    ##     one connection has no crossing to lose.
    ##   Both connections are read, not one: crossing sliding off second's end
    ##     sits mid-line along first, so `along` alone would call it middle
    ##     and this law would refuse move that is fair.
    ##   `evaluate` judges poses and never path between two of them, so this
    ##     is what stands in for that: pose either side of passing-through is
    ##     itself clear, and only wind says arms met.
    for (name, sw) in [("L-r.R-l crown", pairCrown), ("L-l.R-r crown", crossedCrown)]:
      var
        before = 0
        first = true
        seen: seq[Crossing]
      for m in sw.moments:
        let
          now = crossings(m.state, m.verdict)
          wound = writhe(m.state, m.verdict)
        if not first and abs(wound - before) == 1:
          # One crossing's worth of wind moved: it must have had an end to go by.
          let ends = (seen & now).anyIt(
            it.along < AT_END or it.along > 6.0 - AT_END or
            it.across < AT_END or it.across > 6.0 - AT_END)
          checkpoint(&"{name} at {turns(m.turn)} turns: wind {before} -> {wound}")
          check ends
        if not first:
          check abs(wound - before) < 2
        before = wound
        seen = now
        first = false

#[ Reference's Cards ]#

suite "the reference's chain cards":
  test "sim reaches every chain position Architect has kept":
    ## Reference page draws chain at seven winds half turn apart, both arms over
    ##   head, and Architect has ruled `C2`-`C6` and `D2`-`D6` kept -- so those
    ##   five winds of each chain are signed off, and reaching them is sim's job.
    ##   `C` is hold that rests face to face (L-r . R-l), `D` its dual, which
    ##     rests pillion lead (L-l . R-r): `design/parts`, sections `C` and `D`.
    ##   Count asked for is reference's own classifier rather than second rule:
    ##     `chainFor` names shape by `int(abs(wind) * 2)` -- open, cross,
    ##     diamond, swan -- and chain gains one crossing per half turn of wind.
    ##   Read as `writhe` rather than as tally, since tally cannot tell arms
    ##     wound round each other from two crossings of opposite sign, which
    ##     annihilate under small move and never were wind. Measured: both of
    ##     `C6`'s crossings carry same sign and survive twenty relaxations in
    ##     place, so its diamond is wound; three short cards read nought.
    ##   `is_met` says which sim reaches today, so neither side moves without
    ##     this going red.  Three do not: sim's pose at whole turn sits nearer
    ##     rest than its half turn one, arms having got out of wind by passing
    ##     over one another, which over head there is room to do.  Mending sim
    ##     is what turns those three true; regenerating this table is not.
    const
      WINDS = [-1.0, -0.5, 0.0, 0.5, 1.0]
        ## Winds of cards `2` to `6`, which are ones ruled on.
      MET = [[false, true, true, true, true],   # C2 C3 C4 C5 C6
             [false, true, true, true, false]]  # D2 D3 D4 D5 D6
        ## Which card sim draws as reference draws it, today.
    for (name, sw) in [("C", pairCrown), ("D", crossedCrown)]:
      let which = if name == "C": 0 else: 1
      for i, wind in WINDS:
        let
          id = &"{name}{i + 2}"
          want = int(abs(wind) * 2.0)
          got = sw.at(wind)
        checkpoint(id)
        var
          reaches = false
          said = "chain blocks before this turn"
        if got.isSome:
          let
            wound = writhe(got.get.state, got.get.verdict)
            crossed = crossings(got.get.state, got.get.verdict).len
          reaches = abs(wound) == want
          said = &"sim winds {abs(wound)} (writhe {wound}, {crossed} crossing(s))"
          # Tally and wind agree on every card reached today. Where they part,
          #   wind is what is meant, and this says so rather than leaving it.
          check crossed == abs(wound)
        echo &"    {id}: reference draws {want}, {said}" &
          (if reaches: "  (reaches)" else: "  (SHORT)")
        # Card out of reach is card not reached: no verdict, not an error here.
        check reaches == MET[which][i]
