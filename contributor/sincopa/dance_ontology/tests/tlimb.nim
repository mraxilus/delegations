discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on -d:danger $options $file"
batchable: true
joinable: true
"""
## Rig's tape and one arm's geometry, held to what they claim.
##
##   Two suites kept from `tlaws.nim` when solver it tested was retired: neither
##     ever asked solver anything.  Rig's suite holds tape's numbers to their
##     own arithmetic; arm's holds `placed` and `joints` to each other, forward
##     kinematics against reading, so what one sets other reads back.

{.experimental: "strictFuncs".}

import std/[math, random, unittest]

import ../sim/[body, contact, limb, rig, vec]


const
  APART = 0.40
  LEFT = Arm.Left
  RIGHT = Arm.Right


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
  ## Two laws kept from `tlaws.nim` that asked solver nothing: they hold
  ## `contact` and `vec` alone, which engine's own contact does not replace,
  ## since reader still asks them whether arm presses body.
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
