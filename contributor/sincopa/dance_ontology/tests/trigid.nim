discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on -d:danger $options $file"
batchable: true
joinable: false
"""
## Hold rig built on engine to what tape and clinical tables say, and to geometry.
##
##   Every law here failed on tree before it passed on this one.  First caught rig laid
##     flat on floor: trunk's turn was built from project's three axes in project's
##     order, where engine's basis puts body's forward on its negative z, and both
##     dancers lay down with shoulders at ankle height.
##   Second law is why engine's readings may be trusted at all: engine reports wrist's
##     cone, and same angle is worked out from three drawn points.  They agree, so
##     every other law may ask engine rather than measure pose again.
##     Law itself was wrong first time it ran, and rig was right: `angleBetween` takes
##     units, and raw vectors gave it constant eighty-nine degrees whatever pose was.
##   Not joinable: it links C archive, which testament's joined binary cannot share.

{.experimental: "strictFuncs".}

import std/[math, strformat, unittest]

import ../sim/[body, hold, limb, rig, rigid, vec, walk]


const
  SHAKE = @[Link(ends: [(Body.One, Arm.Right), (Body.Two, Arm.Left)])]
    ## Plainest hold there is: one hand each, face to face.
  APART = 1.10 ## One distance laws below that do not care where couple stand use.
    ## Was where that hold left joints freest standing still, back when that was
    ## how standing was chosen.  It is now only place to build couple at.
  SLACK = 3.0 * PI / 180.0 ## Engine's limits are solved, not clamped, so joint may
                           ## stand this far past its end for one step and come back.


proc rest(band = Band.Torso; apart = APART): Couple =
  result = build(HUMAN, facing(HUMAN, apart), band, SHAKE)
  result.settle()

const
  ASK = 0.6 ## Turn laws below put to that hold, in turns, turning her negative way.
    ## Chosen to make search work for its answer: measured 2026-09-13 with bodies
    ## solid, that hold carries 0.28 that way from first distance couple may stand
    ## at and 0.64 only from 0.70 to 0.72 m, so this is reached only by looking
    ## past first.  Turning her other way first distance carries most, 0.64, and
    ## search that gave up after one distance would answer correctly.  Before
    ## bodies were solid it carried 1.04, arm through torso.
  CHAIN = @[Link(ends: [(Body.One, Arm.Left), (Body.Two, Arm.Left)]),
            Link(ends: [(Body.One, Arm.Right), (Body.Two, Arm.Right)])]
    ## Same-name chain, built pillion: hold that stops from every distance at
    ## torso height, which plain hold no longer does.  Turn no distance carries
    ## has to be asked of hold that has one.
  BEYOND = 0.5 ## Turn no distance carries that chain; best of them is 0.42.

let CHOSEN = block:
  ## Where that hold stands to turn each way at torso height, and how far it
  ## carries from there.  Found once: laws below want it, and finding it sweeps
  ## every distance couple may stand at.
  let sw = swept(HUMAN, Band.Torso, SHAKE, most = 1.6)
  [sw.neg, sw.pos]

func carried(w: Walk): float =
  ## How far this walk went, counting one that never stopped as further than any
  ## that did.
  if not w.restHolds: -Inf elif w.stopped: w.at else: Inf


suite "two dancers in rigid body engine":

  test "each dancer stands where tape puts them":
    let
      c = rest()
      p = c.poseOf(0)
    for k in 0 .. 1:
      let h = c.links[0].ends[k]
      check dist(p.arms[k].s, shoulder(HUMAN, c.chestStance(h.body), h.arm)) < 0.001
    check abs(p.arms[0].s.z - HUMAN.shoulderUp) < 0.001
    c.free()

  test "shoulders yaw on hips no further than thorax turns, and rest square":
    ## Chest is what shoulders hang from.  With hold pulling it yields, sprung,
    ## and never past clinical thoracic rotation; with nothing pulling it sits
    ## square on hips.
    var c = rest()
    for who in Body:
      let yaw = c.chestStance(who).facing - c.stance[who].facing
      check abs(yaw) <= 40.0 * PI / 180.0 + SLACK
    c.turn(Body.Two, 0.5, 600)
    for who in Body:
      let yaw = c.chestStance(who).facing - c.stance[who].facing
      check abs(yaw) <= 40.0 * PI / 180.0 + SLACK
    c.free()
    var free = build(HUMAN, facing(HUMAN, APART), Band.Torso, @[])
    free.settle()
    for who in Body:
      check abs(free.chestStance(who).facing - free.stance[who].facing) < 1e-3
    free.free()

  test "engine's own reading of wrist is angle its three points make":
    for apart in [0.6, 0.9, 1.1]:
      let
        c = rest(apart = apart)
        p = c.poseOf(0)
      for k in 0 .. 1:
        let
          a = p.arms[k]
          drawn = angleBetween(unit(a.w - a.e), unit(a.g - a.w))
        check abs(p.wrist[k] - drawn) < 0.01
      c.free()

  test "hands that are joined stay joined":
    for band in Band:
      let
        c = rest(band)
        p = c.poseOf(0)
      check p.apart < PARTED
      check c.stopOf(0) == Stop.None
      c.free()

  test "no joint goes past what rig allows it, at rest or through quarter":
    for band in Band:
      var c = rest(band)
      for quarter in 0 .. 3:
        let p = c.poseOf(0)
        for k in 0 .. 1:
          let (lo, hi) = twistEnds(HUMAN, c.links[0].ends[k].arm)
          check p.twist[k] >= lo - SLACK
          check p.twist[k] <= hi + SLACK
          check p.bend[k] >= HUMAN.range[Dof.Bend].lo - SLACK
          check p.bend[k] <= HUMAN.range[Dof.Bend].hi + SLACK
          check p.wrist[k] <= HUMAN.range[Dof.Wrist].hi + SLACK
        c.turn(Body.Two, 0.25, 600)
      c.free()

  test "couple are never offered place inside each other":
    ## Only thing fixed about where couple stand.  Architect: stand for turn, hand
    ## height for turn, everything for turn, nothing fixed but preventing
    ## collisions.  So this is whole of what constrains standing, and if it does
    ## not hold nothing does.
    var count = 0
    for apart in stands(HUMAN):
      check apart >= touching(HUMAN) + CLEAR
      count += 1
    check count > 1

  test "no distance couple could stand at carries turn further than one they chose":
    ## Standing was chosen at rest before this: wherever joints were freest standing
    ## still.  Couple walked straight out of it -- measured, chain over crown stood
    ## at 0.96 and turned 0.22 where standing at 0.36 turns 1.12 -- because room to
    ## move standing still is not what turning spends.
    ##   Law is argument maximum itself, so search broken any way at all fails here:
    ##   best started at infinity, sign of step dropped, range stopping short, rest
    ##   that never held counted as carrying.
    for way in 0 .. 1:
      let
        step = (if way == 0: -STEP else: STEP)
        chose = CHOSEN[way]
      check chose.restHolds
      for apart in stands(HUMAN):
        let w = walked(HUMAN, Band.Torso, SHAKE, Body.Two, apart, 1.6, step,
                       false, Body.Two)
        check w.carried <= chose.carried

  test "turn couple are said to reach is turn some distance carries":
    ## `reaches` answers at first distance that carries turn rather than at best of
    ## them, which is same answer for less work only so long as it looks at every
    ## distance before saying no.
    var any = false
    for apart in stands(HUMAN):
      let w = walked(HUMAN, Band.Torso, SHAKE, Body.Two, apart, ASK, -STEP,
                     false, Body.Two)
      if w.restHolds and not w.stopped: any = true
    check any
    check reaches(HUMAN, Band.Torso, SHAKE, -ASK)
    check not reaches(HUMAN, Band.Torso, CHAIN, BEYOND, away = true)

  test "at rest every joint is free to move either way":
    ## `freedom` is what `roomAt` reads with, and it counts both ends of range.
    ## On `margin`, which counts stop with no ease as costing nothing to lean on,
    ## straight elbow reads perfectly comfortable and every moment page draws
    ## reports room it does not have.
    for way in 0 .. 1:
      let c = rest(Band.Torso, CHOSEN[way].apart)
      check roomAt(c, c.poseOf(0), 0) > 0.0
      c.free()

  test "no arm swings past what rig allows while hold still stands":
    ## Engine holds elbow, wrist and twist.  Extension and adduction across body
    ## it was never given -- rig states them as two ranges of their own and engine
    ## offers one cone -- so nothing holds them but this reading.  Asking only once
    ## hands had parted meant nothing held them at all: follow could turn two whole
    ## turns and more with their arm wrapped away behind them, and sweep called it
    ## free.
    ##   `GIVE` is what arm resting against its end may sink by, and is claim in its
    ##   own right: torque holding arm back has to be stiff enough that pressed arm
    ##   stays within it.  Slackening this figure to make suite pass would be
    ##   weakening test; it is here because model now says arm may lean on its end,
    ##   and it still fails outright if that lean is not held.
    let sw = swept(HUMAN, Band.Torso, SHAKE, most = 1.5, apart = APART)
    check sw.restHolds
    for w in [sw.pos, sw.neg]:
      for m in w.moments:
        for k in 0 .. 1:
          let
            h = SHAKE[0].ends[k]
            j = joints(m.stance[h.body], h.arm, m.arms[0][k])
          check margin(HUMAN.range[Dof.Extend], j.extend) >= -GIVE
          check margin(HUMAN.range[Dof.Across], j.across) >= -GIVE

  test "every capsule page draws is one engine was given":
    ## Page is debug view, so its honesty rests on this: list it draws from is
    ## list handed to engine, recorded as it was handed over rather than worked
    ## out again afterwards.  Two trunks of four capsules, and four arms of
    ## three, is what `build` makes.
    let c = rest()
    check c.shapes.len == 2 * 4 + 4 * 3
    var trunks, limbs = 0
    for s in c.shapes:
      check s.r > 0.0
      if s.mark == Mark.Trunk: trunks += 1 else: limbs += 1
    check trunks == 8
    check limbs == 12
    c.free()

  test "arm's three capsules run end to end":
    ## Drawing that lets links drift apart draws arm nobody has.  Far end of one
    ## link and near end of next are same joint, so they meet within what solver
    ## lets joint separate.
    let c = rest()
    for who in Body:
      for arm in Arm:
        var run: seq[tuple[a, z: Vec]]
        for s in c.shapes:
          if s.mark != Mark.Trunk and s.who == who and s.arm == arm:
            run.add c.endsOf(s)
        check run.len == 3
        for i in 0 ..< run.len - 1:
          check dist(run[i].z, run[i + 1].a) < 2.0 * HUMAN.limb + 0.01
    c.free()

  test "capsules move where couple move":
    ## Guards drawing frozen at rest: ends are asked of engine each moment, so
    ## turning one dancer has to move their arms and leave other's trunk alone.
    var c = rest()
    let before = c.endsOf(c.shapes[0])
    var wasArm: seq[tuple[a, z: Vec]]
    for s in c.shapes:
      if s.mark != Mark.Trunk and s.who == Body.Two: wasArm.add c.endsOf(s)
    c.turn(Body.Two, 0.25, 600)
    var nowArm: seq[tuple[a, z: Vec]]
    for s in c.shapes:
      if s.mark != Mark.Trunk and s.who == Body.Two: nowArm.add c.endsOf(s)
    var moved = 0.0
    for i in 0 ..< wasArm.len:
      moved = max(moved, dist(wasArm[i].a, nowArm[i].a))
    check moved > 0.05
    ## Other dancer's trunk may yaw on hips as hold pulls, and nothing else:
    ## each capsule end keeps its distance from hip axis and its height.  That
    ## still catches drawing frozen, and catches trunk carried off or tilted,
    ## which "stays put" also caught and yaw does not break.  To tenth of
    ## millimetre, not micron: waist is soft constraint, and chest under hold
    ## measured ten microns off hip axis (9.7e-6 m, 2026-09-12).
    let
      hip = axesOf(c.stance[Body.One]).origin
      after = c.endsOf(c.shapes[0]).a
      radiusWas = sqrt((before.a.x - hip.x) ^ 2 + (before.a.y - hip.y) ^ 2)
      radiusNow = sqrt((after.x - hip.x) ^ 2 + (after.y - hip.y) ^ 2)
    check abs(radiusWas - radiusNow) < 1e-4
    check abs(before.a.z - after.z) < 1e-4
    c.free()

  test "rig is same seen in mirror":
    ## Lead's left to follow's left, reflected, is lead's right to follow's right,
    ## and turning one way reflects to turning other.  Anything applied per arm in
    ## body's mirrored terms has to say whether it is vector or pseudovector:
    ## torque is pseudovector, and mirroring it as vector turned left arm's own
    ## correction into shove further out.
    let
      same = @[Link(ends: [(Body.One, Arm.Left), (Body.Two, Arm.Left)])]
      other = @[Link(ends: [(Body.One, Arm.Right), (Body.Two, Arm.Right)])]
      a = swept(HUMAN, Band.Torso, same, most = 0.8)
      b = swept(HUMAN, Band.Torso, other, most = 0.8)
    ## Standing distance is chosen per way, so it is compared per way, as every
    ## other figure here is.  `Swept.apart` is whichever way went furthest, and
    ## when both run free they tie and it takes positive way for both -- which
    ## mirror does not equate, since positive way of one is negative way of
    ## other.  Comparing it passed only while ways did not tie.
    ## Within one step of search grid, not exact.  Chest is dynamic and its yaw
    ## mirrors to two ten-thousandths of degree at rest and six thousandths at
    ## 0.60 metres, but at 0.40 it sits four centimetres from contact and
    ## engine's iteration order, which differs between mirror-image holds,
    ## is amplified there to six tenths of degree.  Two distances that carry
    ## equally far then tie one way for one hold and other way for its mirror.
    ## Turn reached and what stopped it are still held exact below, which is
    ## what caught torque mirrored as vector.
    check abs(a.pos.apart - b.neg.apart) < SEEK + 1e-9
    check abs(a.neg.apart - b.pos.apart) < SEEK + 1e-9
    check a.pos.stopped == b.neg.stopped
    check a.neg.stopped == b.pos.stopped
    ## Turn reached within one step, not exact, since bodies became solid:
    ## contact is where stop is decided now, and engine's contact is not mirror
    ## symmetric to step -- mirror-image holds stop one step apart from same
    ## distance, 0.02, measured 2026-09-13.  What stopped them is still exact.
    check abs(a.pos.at - b.neg.at) < STEP + 1e-9
    check abs(a.neg.at - b.pos.at) < STEP + 1e-9
    check a.pos.why == b.neg.why
    check a.neg.why == b.pos.why

  test "over crown nothing stops single hold turning":
    ## Architect, who dances it: above is level that blocks by twist alone, and
    ## floor's own table says no block either way for either single hold there.
    ## Arms are clear of both bodies and swing is nowhere near its ends, so this
    ## is what rig should say without being told.
    ##   Red before crown's own rule was put back: joined hands over crown go over
    ##   turning dancer's head, not between two bodies.  Pulled to midpoint, both
    ##   dancers reach across themselves, spend their adduction, and hold blocks at
    ##   0.28 of turn.
    ##   Whole turn, not turn and half: with bodies solid, cross-name hold winds
    ##   her shoulder to its end at 1.20 to 1.30 turning one way from every
    ##   distance, which is twist alone and past every card.  Turn and half was
    ##   free only with arm through head.  Architect's to say whether that wind
    ##   is real.
    for arms in [[Arm.Left, Arm.Left], [Arm.Left, Arm.Right]]:
      let
        links = @[Link(ends: [(Body.One, arms[0]), (Body.Two, arms[1])])]
        sw = swept(HUMAN, Band.Crown, links, most = 1.0)
      check sw.restHolds
      check not sw.pos.stopped
      check not sw.neg.stopped


#[ Arms Move As Arms Do ]#

const
  LEAP = 2.0 * PI * STEP * (HUMAN.shoulderOut + reach(HUMAN)) + 0.08
    ## Furthest any point of arm may move between two moments: point carried at
    ## arm's reach from turning axis goes 113 mm in one fiftieth of turn, and
    ## arm moving on its own at one metre per second while couple turn at
    ## quarter turn per second adds eight centimetres, both at once and along
    ## one line.  Measured before: 245 to 891 mm, hands pinned between torsos
    ## popping up between heads, arms sliding off head's dome, and elbow of
    ## weightless arm wandering about line from shoulder to wrist.  After: 83
    ## and 161 mm, second being wrist dragged in last moment before swing gives.

func between(a, b, c, d: Vec): float =
  ## Least distance between two segments, worked out here so law borrows
  ## nothing from what it checks.
  let
    u = b - a
    v = d - c
    w = a - c
    uu = dot(u, u)
    uv = dot(u, v)
    vv = dot(v, v)
    uw = dot(u, w)
    vw = dot(v, w)
    den = uu * vv - uv * uv
  var s = 0.0
  var t = 0.0
  if den > 1e-12:
    s = clamp((uv * vw - vv * uw) / den, 0.0, 1.0)
  t = (uv * s + vw) / max(vv, 1e-12)
  if t < 0.0:
    t = 0.0
    s = clamp(-uw / max(uu, 1e-12), 0.0, 1.0)
  elif t > 1.0:
    t = 1.0
    s = clamp((uv - uw) / max(uu, 1e-12), 0.0, 1.0)
  dist(a + u * s, c + v * t)

func linkCapsules(rig: Rig; a: ArmPose): seq[tuple[p, q: Vec, r: float]] =
  ## Arm's three links as engine holds them: capsule set in from each joint by
  ## its radius, and hand too short for that as ball at its middle.
  for (s, e, long) in [(a.s, a.e, rig.upper), (a.e, a.w, rig.fore), (a.w, a.g, rig.hand)]:
    let dir = unit(e - s)
    if long > 2.0 * rig.limb:
      result.add (s + dir * rig.limb, e - dir * rig.limb, rig.limb)
    else:
      result.add ((s + e) * 0.5, (s + e) * 0.5, long / 2.0)

iterator corpus(): tuple[name: string, band: Band, links: seq[Link], w: Walk] =
  ## Two single holds walked one way from where couple choose to stand, which
  ## is what pages draw: crown is where arm goes over head, torso is where arms
  ## lie against bodies.
  for (name, band, arms) in [("L-l above", Band.Crown, [Arm.Left, Arm.Left]),
                             ("L-r low", Band.Torso, [Arm.Left, Arm.Right])]:
    let links = @[Link(ends: [(Body.One, arms[0]), (Body.Two, arms[1])])]
    let sw = swept(HUMAN, band, links, most = 1.0)
    yield (name, band, links, sw.pos)

suite "arms move as arms do":
  ## Architect, watching viewer: bodies too rigid, arms crushed and passing
  ## through them, sharp moves between frames.  Measured before these laws:
  ## forearm 45 mm inside its own trunk with nothing said, and hand crossing
  ## 359 mm between first two moments.

  test "no arm sits inside any body in any moment":
    ## Read against trunk capsules where engine has them, with distance worked
    ## out here and not engine's manifolds, so engine is not asked to mark its
    ## own work (Article II.9).  Not reader's `bodyGap` either: it draws parts
    ## as cylinders with flat ends, and over torso's dome reads arm 37 mm inside
    ## body at rest where engine has it clear.  Own body counts as other does:
    ## engine collides own arm with own trunk.  Deeper than `THROUGH` is what
    ## model itself calls arm through body and stops at, so no recorded moment
    ## may be deeper; engine once reported no touch with upper arm 67 mm inside
    ## own head, which is what this is for.
    for (name, band, links, w) in corpus():
      check w.restHolds
      check w.moments.len > 5
      var deepest = 0.0
      for m in w.moments:
        for i in 0 ..< links.len:
          for k in 0 .. 1:
            for (p, q, r) in linkCapsules(HUMAN, m.arms[i][k]):
              for who in Body:
                for (c0, c1, cr) in m.trunks[who]:
                  deepest = min(deepest, between(p, q, c0, c1) - r - cr)
      echo &"    {name}: deepest any link sits in any body {-deepest * 1000:.1f} mm"
      check deepest > -THROUGH - 1e-9

  test "no point of any arm leaps between two moments":
    for (name, band, links, w) in corpus():
      var most = 0.0
      var where = 0.0
      for j in 1 ..< w.moments.len:
        for i in 0 ..< links.len:
          for k in 0 .. 1:
            let
              a = w.moments[j - 1].arms[i][k]
              b = w.moments[j].arms[i][k]
            for (p, q) in [(a.s, b.s), (a.e, b.e), (a.w, b.w), (a.g, b.g)]:
              if dist(p, q) > most:
                most = dist(p, q)
                where = w.moments[j].at
      echo &"    {name}: furthest any point moves between moments {most * 1000:.0f} mm, " &
        &"at {where:.2f}"
      check most < LEAP
