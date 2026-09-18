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

import ../sim/[body, hold, limb, read, rig, rigid, vec, walk]


const
  SHAKE = @[Link(ends: [(Body.One, Arm.Right), (Body.Two, Arm.Left)])]
    ## Plainest hold there is: one hand each, face to face.
  APART = 1.10 ## One distance laws below that do not care where couple stand use.
    ## Was where that hold left joints freest standing still, back when that was
    ## how standing was chosen.  It is now only place to build couple at.
  GIVE_REST = 0.01 ## Metres shoulder may sit off tape at rest, girdle being on spring:
                   ## measured 6.3 mm, pushed by its own arm resting against torso.
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
  BEYOND = 1.2 ## Turn no distance carries that chain; best of them is 0.92, measured
               ## 2026-09-13 with shoulder girdles giving, against 0.42 before them.
  WOUND = @[Link(ends: [(Body.One, Arm.Left), (Body.Two, Arm.Right)]),
            Link(ends: [(Body.One, Arm.Right), (Body.Two, Arm.Left)])]
    ## Cross-name chain, whose stills reference draws wound to turn and half.

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
    ## Within `GIVE_REST`: shoulder girdle is on spring, and at rest it sits 6.3 mm
    ## off tape, pushed by its own arm resting against torso.  Tape is where
    ## shoulder hangs unloaded; centimetres would be shoulder placed wrong.
    let
      c = rest()
      p = c.poseOf(0)
    for k in 0 .. 1:
      let h = c.links[0].ends[k]
      check dist(p.arms[k].s, shoulder(HUMAN, c.chestStance(h.body), h.arm)) < GIVE_REST
    check abs(p.arms[0].s.z - HUMAN.shoulderUp) < GIVE_REST
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
    ## Checked while hold stands.  Turn is forced on by quarters at 1.10 m, and
    ## by half turn hands have parted by twenty centimetres: what wrist does
    ## then is no pose model reports, and it was carried nine degrees past its
    ## cone there once shoulder girdle could give.  Rest and first quarter, with
    ## wrists at twenty and twist at fifty, are what this holds.
    var checked = 0
    for band in Band:
      var c = rest(band)
      for quarter in 0 .. 3:
        let p = c.poseOf(0)
        if p.apart < PARTED:
          inc checked
          for k in 0 .. 1:
            let (lo, hi) = twistEnds(HUMAN, c.links[0].ends[k].arm)
            check p.twist[k] >= lo - SLACK
            check p.twist[k] <= hi + SLACK
            check p.bend[k] >= HUMAN.range[Dof.Bend].lo - SLACK
            check p.bend[k] <= HUMAN.range[Dof.Bend].hi + SLACK
            check p.wrist[k] <= HUMAN.range[Dof.Wrist].hi + SLACK
        c.turn(Body.Two, 0.25, 600)
      c.free()
    check checked >= 2 * 3

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
    ## out again afterwards.  Two trunks of four capsules, four shoulders of
    ## one, and four arms of three, is what `build` makes.
    let c = rest()
    check c.shapes.len == 2 * 4 + 4 + 4 * 3
    var trunks, girdles, limbs = 0
    for s in c.shapes:
      check s.r > 0.0
      case s.mark
      of Mark.Trunk: trunks += 1
      of Mark.Girdle: girdles += 1
      else: limbs += 1
    check trunks == 8
    check girdles == 4
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
          if s.mark in {Mark.Upper, Mark.Fore, Mark.Palm} and s.who == who and s.arm == arm:
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
    ##   And no held arm is carried to its swing's end on way there.  Architect,
    ##   watching viewer at 0.68 of cross-name turn: "no-one would let their arm
    ##   wrap behind their head like this".  Her arm sat at forty five degrees
    ##   behind frontal plane, swing's end, for six arm-moments of that sweep and
    ##   in its ease for fifty five, where going over top costs nothing: engine's
    ##   limits are walls and nothing preferred middle of range.
    for arms in [[Arm.Left, Arm.Left], [Arm.Left, Arm.Right]]:
      let
        links = @[Link(ends: [(Body.One, arms[0]), (Body.Two, arms[1])])]
        sw = swept(HUMAN, Band.Crown, links, most = 1.0)
      check sw.restHolds
      check not sw.pos.stopped
      check not sw.neg.stopped
      var atEnd = 0
      var peak = -Inf
      for w in [sw.pos, sw.neg]:
        for m in w.moments:
          for k in 0 .. 1:
            let
              h = links[0].ends[k]
              j = joints(m.stance[h.body], h.arm, m.arms[0][k])
            peak = max(peak, j.extend)
            if j.extend > HUMAN.range[Dof.Extend].hi - 5.0 * PI / 180.0: inc atEnd
      echo &"    {arms[0]}-{arms[1]}: extension peaks {peak * 180.0 / PI:.1f} degrees, " &
        &"{atEnd} arm-moments at swing's end"
      check atEnd == 0


#[ Couple Stand For Sweep ]#

suite "couple stand for sweep":
  ## Where couple stand for sweep is chosen from every distance walked, by what
  ## each carried and how its arms moved.  Both are chaotic: two walks differing
  ## in last bit answer differently, and same source built by another compiler
  ## differs in last bits.  Choice has to stand still under that.
  const
    ## Same-name single hold at torso, walked 0.8 of turn: distances carrying
    ## most and their largest leaps, measured 2026-09-18.  L-l turning her
    ## positive way and R-r her negative are one hold seen in mirror.  Nearer
    ## distances carry 0.46 at most, and 0.52 on carries 0.66.
    LL_POS: seq[Carry] = @[(0.44, 0.72, 0.125), (0.46, 0.72, 0.171),
                           (0.48, 0.72, 0.126), (0.50, 0.68, 0.121)]
    RR_NEG: seq[Carry] = @[(0.44, 0.72, 0.135), (0.46, 0.72, 0.174),
                           (0.48, 0.72, 0.106), (0.50, 0.72, 0.121)]
    ## Same walks from same source, built into another binary: leaps differ by
    ## up to thirty five per cent, and at 0.50 L-l carries 0.68 either way.
    LL_POS_ELSE: seq[Carry] = @[(0.44, 0.72, 0.114), (0.46, 0.72, 0.169),
                                (0.48, 0.72, 0.133), (0.50, 0.68, 0.163)]
    RR_NEG_ELSE: seq[Carry] = @[(0.44, 0.72, 0.116), (0.46, 0.72, 0.155),
                                (0.48, 0.72, 0.124), (0.50, 0.68, 0.159)]
    ## Same hold at neck, walked whole sweep: L-l carries 1.00 from 0.42 and
    ## 0.98 from 0.38, and R-r 0.98 from both -- one step, which is how exactly
    ## stop is decided.
    LL_HIGH: seq[Carry] = @[(0.36, 0.22, 0.045), (0.38, 0.98, 0.093),
                            (0.40, 0.96, 0.100), (0.42, 1.00, 0.099),
                            (0.44, 0.82, 0.114), (0.46, 0.96, 0.104)]
    RR_HIGH: seq[Carry] = @[(0.36, 0.22, 0.046), (0.38, 0.98, 0.099),
                            (0.40, 0.96, 0.097), (0.42, 0.98, 0.100),
                            (0.44, 0.82, 0.109), (0.46, 0.98, 0.104)]
    ## Same hold over crown, running free from first distance: chest to chest
    ## joined hands are pinned between torsos and pop up, 189 mm in one moment,
    ## and from 0.42 on arms move under 90 mm.
    LL_ABOVE: seq[Carry] = @[(0.36, Inf, 0.189), (0.38, Inf, 0.155),
                             (0.40, Inf, 0.131), (0.42, Inf, 0.086),
                             (0.44, Inf, 0.077), (0.46, Inf, 0.084)]

  func standAt(walks: openArray[Carry]): float = walks[chosen(walks)].apart

  test "stance chosen is same seen in mirror and built by another compiler":
    ## Red: five millimetres broke tie between 0.44 and 0.48 for R-r, leaps 135
    ## and 106, and held it for L-l, 125 and 126: stances two steps apart for
    ## one hold in mirror, and `rig is same seen in mirror` failed on this tree
    ## and not on last, nothing about rig having changed.
    for (a, b) in [(LL_POS, RR_NEG), (LL_POS, LL_POS_ELSE), (RR_NEG, RR_NEG_ELSE),
                   (LL_POS_ELSE, RR_NEG_ELSE), (LL_HIGH, RR_HIGH)]:
      check abs(standAt(a) - standAt(b)) < SEEK + 1e-9

  test "stance steps out from hands pinned between torsos":
    ## Kept from before: nearest distance that carries turn is chest to chest.
    check standAt(LL_ABOVE) >= 0.40
    check LL_ABOVE[chosen(LL_ABOVE)].leap * 2.0 <= LL_ABOVE[0].leap


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
            let h = links[i].ends[k]
            for (p, q, r) in linkCapsules(HUMAN, m.arms[i][k]):
              for who in Body:
                for (c0, c1, cr) in m.trunks[who]:
                  deepest = min(deepest, between(p, q, c0, c1) - r - cr)
                for arm in Arm:
                  # Arm hangs from its own girdle and overlaps it by construction.
                  if who == h.body and arm == h.arm: continue
                  let (c0, c1, cr) = m.girdles[who][arm]
                  deepest = min(deepest, between(p, q, c0, c1) - r - cr)
      echo &"    {name}: deepest any link sits in any body {-deepest * 1000:.1f} mm"
      check deepest > -THROUGH - 1e-9

  test "every shoulder hangs from its own body":
    ## Architect, on viewer at 1.68 of same-name crown turn: bodies "too rigid",
    ## arms "get dislocated because of it".  Measured, no joint parts
    ## by more than four millimetres; what reads as dislocation is that shoulder
    ## joint sits at 0.18 out and 1.40 up, where torso's stadium is 0.166 wide
    ## and its dome has dropped below 1.24, so arm hangs from point nine
    ## centimetres outside body with nothing between.  Rig had no shoulder girdle,
    ## in mass or in motion.  Shoulder joint must lie inside some capsule of its
    ## own body that is not arm.
    var c = build(HUMAN, facing(HUMAN, APART), Band.Torso, @[])
    c.settle()
    for who in Body:
      for arm in Arm:
        let s = c.armPoseOf(who, arm).s
        var gap = Inf
        for sh in c.shapes:
          if sh.who != who or sh.mark in {Mark.Upper, Mark.Fore, Mark.Palm}: continue
          let ends = c.endsOf(sh)
          gap = min(gap, between(s, s, ends.a, ends.z) - sh.r)
        echo &"    {who} {arm}: shoulder joint {gap * 1000:.0f} mm outside own body"
        check gap <= 0.0
    c.free()

  test "still asked past face to face has its joined hands in their band":
    ## Architect: face to face arms may be at any height, and once couple are no
    ## longer face to face hands must actually be above.  Still card was built at
    ## its facing and settled, and lift starts only after settling: over crown at
    ## half turn every joined hand hung at hip height, 0.87 m, so every still past
    ## face to face on reference was answered with hands nowhere near its band.
    var found = false
    for apart in stands(HUMAN):
      let (holds, c) = stood(HUMAN, Band.Crown, WOUND, 0.5, false, Body.Two, apart)
      if holds:
        found = true
        for ln in WOUND:
          for h in ln.ends:
            check c.armPoseOf(h.body, h.arm).g.z >= HUMAN.band[Band.Crown].lo - SAG
      c.free()
      if found: break
    check found

  test "still at diamond is wound where open is not":
    ## Winding is path, not facing.  Couple built at whole turn stand as they do
    ## at none: diamond read as open and swan as cross, and every wound still on
    ## reference was answered by unwound pose.  Turned there, diamond's two
    ## connections cross twice in plan where open's run clear.
    proc crossed(turns: float): int =
      ## How many times two connections cross, from first distance that holds.
      result = -1
      for apart in stands(HUMAN):
        let (holds, c) = stood(HUMAN, Band.Crown, WOUND, turns, false, Body.Two, apart)
        if holds:
          var arms: Arms
          for i in 0 ..< WOUND.len:
            arms.add c.poseOf(i).arms
          result = crossings(arms).len
        c.free()
        if holds: break
    check crossed(0.0) == 0
    check crossed(1.0) >= 2

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


#[ Every Still Stands At Ease ]#

const
  SLOP = 0.005 ## Engine's own linear slop, metres: overlap it never resolves.
  AT_EASE = 0.1 ## Strain no dancer feels: two degrees of twenty into ease that is
                ## assumed to begin there, under what its own start is known to.
  RAD = PI / 180.0 ## One degree.
  JOINED = 0.005 ## Metres joined hands may sit apart and still be joined: slop.
  PART = 0.002 ## Metres any joint of any arm may be pulled apart: dislocation past this.
  FREE: seq[Link] = @[] ## No hands joined.
  ONE_L = @[Link(ends: [(Body.One, Arm.Left), (Body.Two, Arm.Left)])]
    ## Single hold over crown, left to left.
  ONE_R = @[Link(ends: [(Body.One, Arm.Right), (Body.Two, Arm.Left)])]
    ## Single hold over crown, right to left: standard diagram's A4 wound half.

iterator stills(): tuple[name: string, links: seq[Link], turns: float, away: bool] =
  ## Corpus of stills: both chains from cross to cross, free frame stood pillion,
  ## and single hold at quarter and half.
  ##   Chains are what reference draws wound: cross-name rests face to face,
  ##     same-name pillion (`WOUND`, `CHAIN`).  Reference draws seven rungs each,
  ##     half turn apart, swan at either end; diamonds stand fifth of way into
  ##     her wrist's ease and swans hold nowhere, which `PROVENANCE.md` records
  ##     under body sim, so corpus stops at cross until model reaches further.
  for (tag, links, away) in [("cross-name", WOUND, false), ("same-name", CHAIN, true)]:
    for w in [-0.5, 0.0, 0.5]:
      yield (&"{tag} at {w:+.1f}", links, w, away)
  yield ("free, pillion", FREE, 0.5, false)
  yield ("left to left at quarter", ONE_L, 0.25, false)
  yield ("left to left at half", ONE_L, 0.5, false)

proc overlapOf(c: Couple): tuple[depth: float, pair: string] =
  ## Deepest any two capsules engine collides sit in each other, by geometry
  ## worked out here and not engine's manifolds, and which two.
  ##   Pairs engine never collides are left out: capsules of one body, one arm's
  ##     own links, girdle and upper arm it hangs from, trunk and girdles of one
  ##     dancer, and two joined palms.
  proc skipped(a, b: Shape): bool =
    if a.body == b.body: return true
    if a.who == b.who:
      let limbs = {Mark.Upper, Mark.Fore, Mark.Palm}
      if a.mark notin limbs and b.mark notin limbs: return true
      if a.arm == b.arm and a.mark in limbs and b.mark in limbs: return true
      if a.arm == b.arm and {a.mark, b.mark} == {Mark.Girdle, Mark.Upper}: return true
    if a.mark == Mark.Palm and b.mark == Mark.Palm:
      for ln in c.links:
        let (p, q) = (ln.ends[0], ln.ends[1])
        if (p == (a.who, a.arm) and q == (b.who, b.arm)) or
           (q == (a.who, a.arm) and p == (b.who, b.arm)): return true
    false
  result = (0.0, "")
  for i in 0 ..< c.shapes.len:
    for k in i + 1 ..< c.shapes.len:
      let (a, b) = (c.shapes[i], c.shapes[k])
      if skipped(a, b): continue
      let
        ea = c.endsOf(a)
        eb = c.endsOf(b)
        depth = a.r + b.r - between(ea.a, ea.z, eb.a, eb.z)
      if depth > result.depth:
        result = (depth, &"{a.who} {a.arm} {a.mark} against {b.who} {b.arm} {b.mark}")

suite "every still stands at ease":
  ## Architect: every state is easily doable in reality without any strain,
  ## effort or forcing; no clipping, no dislocations, no cheating.  Read where
  ## couple stand for each still: nothing at any end past `AT_EASE`, nothing
  ## through anything, nothing pulled apart, hands joined.

  test "still couple stand for has nothing at its end":
    ## Strain is nought outside every ease band, one at some end.  Every arm,
    ## held or free, both waists, every collarbone: free arm shoved to its end
    ## by partner's trunk is strain couple feel, as much as held one's.
    for (name, links, turns, away) in stills():
      let where = standing(HUMAN, Band.Crown, links, turns, away, Body.Two)
      echo &"    {name}: stood {where.apart:.2f}, strain {where.strain.most:.2f} " &
        &"at {where.strain.what} {where.strain.whose.body} {where.strain.whose.arm}"
      check where.holds
      check where.strain.most <= AT_EASE

  test "free couple at rest hang their arms by their sides":
    ## Architect: with nothing held, arms are down by sides and look joined to
    ## nothing.  Every arm hangs near plumb, out by what its own flank pushes it,
    ## elbow near straight, untwisted, and no arm comes within its own thickness
    ## of other dancer's arms.  Before this, hanging arms were twisted forty degrees and
    ## swung forward twenty by fixed elbow moment, forearms pointing at partner,
    ## and free couple at rest stood with arms crossed between them.
    let (holds, c) = stood(HUMAN, Band.Crown, FREE, 0.0, false, Body.Two, 0.36)
    check holds
    var nearest = Inf
    for who in Body:
      for arm in Arm:
        let
          (j, tw, bd, wr) = c.jointsOf(who, arm)
          p = c.armPoseOf(who, arm)
          hang = p.g - p.s
        echo &"    {who} {arm}: extend {j.extend * 180.0 / PI:.1f}, across " &
          &"{j.across * 180.0 / PI:.1f}, twist {tw * 180.0 / PI:.1f}, bend " &
          &"{bd * 180.0 / PI:.1f}, wrist {wr * 180.0 / PI:.1f}, hand " &
          &"{sqrt(hang.x * hang.x + hang.y * hang.y) * 1000:.0f} mm off plumb"
        check abs(j.extend) <= 10.0 * RAD
        check abs(tw) <= 15.0 * RAD
        check bd <= 20.0 * RAD
        check wr <= 10.0 * RAD
        check sqrt(hang.x * hang.x + hang.y * hang.y) <= 0.2
    for a in c.shapes:
      for b in c.shapes:
        if a.who == b.who or a.mark notin {Mark.Upper, Mark.Fore, Mark.Palm} or
           b.mark notin {Mark.Upper, Mark.Fore, Mark.Palm}: continue
        let (ea, eb) = (c.endsOf(a), c.endsOf(b))
        nearest = min(nearest, between(ea.a, ea.z, eb.a, eb.z) - a.r - b.r)
    echo &"    nearest two arms of different dancers come: {nearest * 1000:.0f} mm"
    check nearest >= 2.0 * HUMAN.limb
    c.free()

  test "no capsule of any arm sits in any other, hands joined, no joint parted":
    ## Read against every capsule engine collides, with distance worked out here
    ## and not engine's manifolds, so engine is not asked to mark its own work.
    ## Deeper than slop is one thing in another; hands further apart than slop
    ## are not joined; joint pulled further than `PART` is dislocation.
    for (name, links, turns, away) in stills():
      let where = standing(HUMAN, Band.Crown, links, turns, away, Body.Two)
      check where.holds
      if not where.holds: continue
      let (holds, c) = stood(HUMAN, Band.Crown, links, turns, away, Body.Two, where.apart)
      check holds
      let (depth, pair) = c.overlapOf
      var apart = 0.0
      for i in 0 ..< links.len: apart = max(apart, c.poseOf(i).apart)
      var parted = 0.0
      for who in Body:
        for arm in Arm: parted = max(parted, max(c.partedAt(who, arm)))
      echo &"    {name}: deepest {depth * 1000:.1f} mm ({pair}), hands {apart * 1000:.1f} mm " &
        &"apart, joints parted {parted * 1000:.1f} mm"
      check depth <= SLOP
      check apart <= JOINED
      check parted <= PART
      c.free()

  test "hands are above whenever couple are not face to face, from rest on":
    ## Architect: face to face arms may be at any height; once couple are no
    ## longer face to face hands must actually be above.  Hold that rests
    ## pillion is not face to face, so its hands are above at its rest, as its
    ## card draws them.  Keyed to hold's own rest instead, every same-name still
    ## was wound from hold at hip.
    let where = standing(HUMAN, Band.Crown, CHAIN, 0.0, true, Body.Two)
    check where.holds
    let (holds, c) = stood(HUMAN, Band.Crown, CHAIN, 0.0, true, Body.Two, where.apart)
    check holds
    for ln in CHAIN:
      for h in ln.ends:
        check c.armPoseOf(h.body, h.arm).g.z >= HUMAN.band[Band.Crown].lo - SAG
    c.free()

  test "hands are risen through second half of whole turn, and from rest pillion":
    ## Head that passes under joined hands is under them at every wind past
    ## first quarter, whole turns and all.  Keyed to distance from face to face,
    ## which folds whole turns away, lift let hands down onto her head through
    ## second half of every whole turn, and every diamond and swan was wound
    ## with hands at shoulder.  Hold resting pillion is not face to face, and
    ## its hands are risen from its rest on.
    var c = build(HUMAN, restStance(HUMAN, 0.44), Band.Crown, WOUND, Body.Two)
    for w in [0.0, 0.1, 0.3, 0.6, 0.8, 1.0, 1.4]:
      c.stance = turned(restStance(HUMAN, 0.44), Body.Two, w)
      check abs(c.wound - w) < 1e-9
      check c.risen == (if w >= 0.25: 1.0 else: w / 0.25)
    c.free()
    var p = build(HUMAN, restStance(HUMAN, 0.44, away = true), Band.Crown, CHAIN, Body.Two,
                  away = true)
    check p.wound == 0.0
    check p.risen == 1.0
    p.free()

  test "still that fixes no way about is wound whichever way sits easier":
    ## Card whose picture is same turned either way claims position, not path:
    ## couple take whichever way there sits easier, and answer is never worse
    ## than way asked alone.
    let
      asked = standing(HUMAN, Band.Crown, ONE_R, 0.5, false, Body.Two)
      free = standing(HUMAN, Band.Crown, ONE_R, 0.5, false, Body.Two, either = true)
    echo &"    right to left at half: asked way stood {asked.apart:.2f} strain " &
      &"{asked.strain.most:.2f}; either way stood {free.apart:.2f} at {free.turns:+.1f} " &
      &"strain {free.strain.most:.2f}"
    check free.holds
    check free.strain.most <= asked.strain.most
    check free.strain.most <= AT_EASE

  test "same still from same distance answers same twice":
    ## Check gives same verdict on same code.  Winding is chaotic enough that
    ## distances differing in their last bit answer differently, so what is
    ## held is exact repetition: same distance, same numbers.
    for i in 0 .. 1:
      var got: array[2, float]
      for run in 0 .. 1:
        let (holds, c) = stood(HUMAN, Band.Crown, WOUND, 1.0, false, Body.Two, 0.44)
        got[run] = (if holds: c.strainOf.most else: -1.0)
        c.free()
      check got[0] == got[1]
