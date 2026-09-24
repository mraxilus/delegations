discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on -d:danger $options $file"
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
##   Where couple stand is read from `sim/answers.json` (`sim/answers.nim`), not searched
##     for here.  Suite took 545 s under testament, and its twenty laws that search for
##     nothing took 22.8 s, each run alone, measured 2026-09-24 on four cores; answers
##     change only when sim does.  Every pose and walk law holds is still stood or walked
##     live, at answered distance and with current code.  Answers are held to tree by their
##     stamp, and by walking them again (suite "answers").

{.experimental: "strictFuncs".}

import std/[atomics, cpuinfo, math, os, random, strformat, strutils, tables, typedthreads,
          unittest]

import ../sim/[answers, body, hold, limb, read, rig, rigid, vec, walk]


const
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

var
  given: Answers   ## Answers as kept, read on first law that wants them.
  given_read = false

proc answered(): Answers =
  ## Every search's answer as kept (`sim/answers.json`), read once.
  if not given_read:
    given = kept()
    given_read = true
  given

type Went = object ## One walk walked live, reduced to numbers laws read of it.
  holds: bool      ## Whether hold stood at rest there.
  stopped: bool
  at: float        ## Turns reached when something gave.
  why: Stop
  moments: int
  deepest: float   ## Deepest any link sits in any body, metres; below nought is inside.
  leap: float      ## Furthest any point of held arm moves between two moments.
  leapAt: float    ## Turn where it does.
  peak: float      ## Furthest first connection's arms extend, radians.
  atEnd: int       ## Arm-moments of first connection at their swing's end.

proc live(key: string; pos: bool): Went
  ## Sweep of `SWEEPS` walked live one way, from distance its kept answer chose.

proc standOf(q: StillAsked): tuple[holds: bool, c: Couple] =
  ## Couple stood live for still, at distance and way about kept answer gives.
  let where = answered().stillOf(q.key)
  stood(HUMAN, Band.Crown, q.links, where.turns, q.away, Body.Two, where.apart)

func asked(key: string): StillAsked =
  ## Still of `STILLS` by its key.
  for q in STILLS:
    if q.key == key: return q
  raiseAssert "No still asked by that key; got `" & key & "`."

func carried(w: Walk): float =
  ## How far this walk went, counting one that never stopped as further than any
  ## that did.
  if not w.restHolds: -Inf elif w.stopped: w.at else: Inf

func carried(w: Way | Walked | Went): float =
  ## How far kept walk went, counted as live one is.
  if not w.holds: -Inf elif w.stopped: w.at else: Inf


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
    ##   To one step since 2026-09-18: stop is decided at moment something gives,
    ##   and search counts distances carrying within one step as carrying as far,
    ##   nearest keeping tie (`chosen`).  Exact, this law would fail from noise
    ##   fix was for: one build carries one step more from one distance than
    ##   another build does, and neither is wrong.
    ##   Both sides are kept answers: search's choice, and walk from every distance
    ##     (`sim/answers.nim`), each answered by sim at stamp suite "answers" holds.
    let sweep = answered().sweepOf("shake at torso")
    for (chose, every) in [(sweep.neg, "shake at torso, negative"),
                           (sweep.pos, "shake at torso, positive")]:
      check chose.holds
      let got = answered().walksOf(every)
      check got.len > 1
      for walk in got:
        check walk.carried <= chose.carried + STEP + 1e-9

  test "turn couple are said to reach is turn some distance carries":
    ## `reaches` answers at first distance that carries turn rather than at best of
    ## them, which is same answer for less work only so long as it looks at every
    ## distance before saying no.
    ##   `Inf` is how `carried` says walk never stopped, which is hold standing
    ##   at rest there and turn running whole way.
    var any = false
    for walk in answered().walksOf("shake at torso, asked"):
      if walk.carried == Inf: any = true
    check any
    check answered().reachOf("shake asked")
    check not answered().reachOf("chain beyond")

  test "at rest every joint is free to move either way":
    ## `freedom` is what `roomAt` reads with, and it counts both ends of range.
    ## On `margin`, which counts stop with no ease as costing nothing to lean on,
    ## straight elbow reads perfectly comfortable and every moment page draws
    ## reports room it does not have.
    let sweep = answered().sweepOf("shake at torso")
    for way in [sweep.neg, sweep.pos]:
      let c = rest(Band.Torso, way.apart)
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
    ##   Where couple stand each way is search's answer, kept; how far each walk
    ##     goes from there, and what stops it, is walked live (`live`).
    let
      a = answered().sweepOf("left to left at torso")
      b = answered().sweepOf("right to right at torso")
      (aPos, aNeg) = (live("left to left at torso", true), live("left to left at torso", false))
      (bPos, bNeg) = (live("right to right at torso", true), live("right to right at torso", false))
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
    check aPos.stopped == bNeg.stopped
    check aNeg.stopped == bPos.stopped
    ## Turn reached within one step, not exact, since bodies became solid:
    ## contact is where stop is decided now, and engine's contact is not mirror
    ## symmetric to step -- mirror-image holds stop one step apart from same
    ## distance, 0.02, measured 2026-09-13.  What stopped them is still exact.
    check abs(aPos.at - bNeg.at) < STEP + 1e-9
    check abs(aNeg.at - bPos.at) < STEP + 1e-9
    check aPos.why == bNeg.why
    check aNeg.why == bPos.why

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
    for key in ["left to left over crown", "left to right over crown"]:
      let (pos, neg) = (live(key, true), live(key, false))
      check pos.holds or neg.holds
      check not pos.stopped
      check not neg.stopped
      let
        peak = max(pos.peak, neg.peak)
        atEnd = pos.atEnd + neg.atEnd
      echo &"    {key}: extension peaks {peak * 180.0 / PI:.1f} degrees, " &
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

func deepestOf(w: Walk; links: seq[Link]): float =
  ## Deepest any link of any held arm sits in any body, over every moment.
  ##   Read against trunk capsules where engine has them, with distance worked
  ##     out here and not engine's manifolds.  Arm hangs from its own girdle and
  ##     overlaps it by construction, so that one pair is left out.
  for m in w.moments:
    for i in 0 ..< links.len:
      for k in 0 .. 1:
        let h = links[i].ends[k]
        for (p, q, r) in linkCapsules(HUMAN, m.arms[i][k]):
          for who in Body:
            for (c0, c1, cr) in m.trunks[who]:
              result = min(result, between(p, q, c0, c1) - r - cr)
            for arm in Arm:
              if who == h.body and arm == h.arm: continue
              let (c0, c1, cr) = m.girdles[who][arm]
              result = min(result, between(p, q, c0, c1) - r - cr)

func leapIn(w: Walk; links: seq[Link]): tuple[most, at: float] =
  ## Furthest any point of any held arm moves between two moments, and where.
  ##   Worked out here rather than borrowed from `walk.leapOf`, so law does not
  ##     check sim against itself.
  for j in 1 ..< w.moments.len:
    for i in 0 ..< links.len:
      for k in 0 .. 1:
        let
          a = w.moments[j - 1].arms[i][k]
          b = w.moments[j].arms[i][k]
        for (p, q) in [(a.s, b.s), (a.e, b.e), (a.w, b.w), (a.g, b.g)]:
          if dist(p, q) > result.most:
            result = (dist(p, q), w.moments[j].at)

const SWING_END = HUMAN.range[Dof.Extend].hi - 5.0 * PI / 180.0
  ## Extension within five degrees of swing's end.

func extensionOf(w: Walk; links: seq[Link]): tuple[peak: float, atEnd: int] =
  ## Furthest first connection's two arms extend, and arm-moments at swing's end.
  result.peak = -Inf
  for m in w.moments:
    for k in 0 .. 1:
      let
        h = links[0].ends[k]
        j = joints(m.stance[h.body], h.arm, m.arms[0][k])
      result.peak = max(result.peak, j.extend)
      if j.extend > SWING_END: inc result.atEnd

func wentOf(w: Walk; links: seq[Link]): Went =
  ## Walk reduced to numbers laws read.
  let
    (most, at) = leapIn(w, links)
    (peak, atEnd) = extensionOf(w, links)
  Went(holds: w.restHolds, stopped: w.stopped, at: w.at, why: w.why,
       moments: w.moments.len, deepest: deepestOf(w, links), leap: most, leapAt: at,
       peak: peak, atEnd: atEnd)


#[ Live Walks, Every Core At Once ]#

type Go = tuple[sweep: bool, index: int, pos: bool, apart: float]
  ## One walk to walk live: way of sweep of `SWEEPS`, or walk of `WALKS` from one
  ## distance, from `apart`.  Plain numbers, so threads share nothing but this list.

var
  goes: seq[Go]        ## Every walk, set before any thread starts.
  nextGo: Atomic[int]  ## Next walk not yet taken.
  wents: seq[Went]     ## Each walk's numbers, at its own index.
  drawn: seq[tuple[index: int, kept: Walked]] ## Walks drawn to walk again.

proc going(id: int) {.thread.} =
  ## Take walks until none is left.
  ##   Holds are constants, so each worker reads its own copy; each walk builds
  ##     its own world; only numbers come back.  List of strings and sequences
  ##     read by four threads is what `design/modelled.nim` records dying of.
  {.cast(gcsafe).}:
    while true:
      let i = nextGo.fetchAdd(1)
      if i >= goes.len: return
      let g = goes[i]
      if g.sweep:
        let q = SWEEPS[g.index]
        let w = walked(HUMAN, q.band, q.links, Body.Two, g.apart, q.most,
                       (if g.pos: STEP else: -STEP), false, Body.Two)
        wents[i] = wentOf(w, q.links)
      else:
        let q = WALKS[g.index]
        let w = walked(HUMAN, q.band, q.links, Body.Two, g.apart, q.most, q.step,
                       false, Body.Two)
        wents[i] = wentOf(w, q.links)

proc walkEveryWay() =
  ## Walk, on every core at once, every way of every sweep from its kept distance,
  ## and two walks of `WALKS` drawn by stamp from their kept distances.
  ##   Laws read ten of those twelve ways between them, and law of answers reads
  ##     all twelve; walked one after another they cost 14.5 s of one law's time,
  ##     measured 2026-09-24.  Way whose search found no distance is not walked.
  if goes.len > 0: return
  let a = answered()
  for i, q in SWEEPS:
    let sweep = a.sweepOf(q.key)
    for (pos, way) in [(true, sweep.pos), (false, sweep.neg)]:
      if way.holds: goes.add (true, i, pos, way.apart)
  var every: seq[tuple[index: int, kept: Walked]]
  for i, q in WALKS:
    for w in a.walksOf(q.key): every.add (i, w)
  var draw = initRand(fromHex[int](a.stamp[0 ..< 12]))
  for _ in 0 .. 1:
    let got = every[draw.rand(every.high)]
    drawn.add got
    goes.add (false, got.index, true, got.kept.apart)
  wents = newSeq[Went](goes.len)
  nextGo.store(0)
  let cores = max(1, countProcessors())
  var workers = newSeq[Thread[int]](cores)
  for w in 0 ..< cores: createThread(workers[w], going, w)
  joinThreads(workers)

proc live(key: string; pos: bool): Went =
  ## Walk is sim's own, on this build: only where couple stand comes from
  ##   answers.  `walked` builds its own world, so it walks exactly what search
  ##   walked from that distance.
  ##   Way whose search found no distance to stand at is not walked, and reads
  ##   as hold that did not stand.
  walkEveryWay()
  for i, q in SWEEPS:
    if q.key == key:
      for k, g in goes:
        if g.sweep and g.index == i and g.pos == pos: return wents[k]
      return Went(holds: false)
  raiseAssert "No sweep asked by that key; got `" & key & "`."

proc replayed(): seq[tuple[q: WalkAsked, kept: Walked, w: Went]] =
  ## Two walks of `WALKS` drawn by stamp, as kept and as walked again live.
  walkEveryWay()
  for k, g in goes:
    if not g.sweep:
      result.add (WALKS[g.index], drawn[result.len].kept, wents[k])

type Seen = tuple[name: string, band: Band, links: seq[Link], w: Went]

proc corpus(): seq[Seen] =
  ## Two single holds walked one way from where couple choose to stand, which
  ## is what pages draw: crown is where arm goes over head, torso is where arms
  ## lie against bodies.
  ##   Walked live from kept answer (`live`), once, and read by two laws.
  @[("L-l above", Band.Crown, ONE_L, live("left to left over crown", true)),
    ("L-r low", Band.Torso, L_R, live("left to right at torso", true))]

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
      check w.holds
      check w.moments > 5
      echo &"    {name}: deepest any link sits in any body {-w.deepest * 1000:.1f} mm"
      check w.deepest > -THROUGH - 1e-9

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
    ##   Wound there whether or not pose holds, and from `DIAMOND`: what is
    ##   claimed here is path, not hold.  From `APART` whole turn ends with arm
    ##   through body and one crossing, measured 2026-09-18 with hands asked
    ##   down to mid torso facing; from 0.70 it comes round with nothing given.
    const DIAMOND = 0.70
    proc crossed(turns: float): int =
      ## How many times two connections cross, wound there from `DIAMOND`.
      var c = build(HUMAN, restStance(HUMAN, DIAMOND), Band.Crown, WOUND, Body.Two)
      c.settle()
      var at = 0.0
      while abs(at) + 1e-9 < abs(turns):
        c.turn(Body.Two, STEP, BEATS)
        at += STEP
      var arms: Arms
      for i in 0 ..< WOUND.len:
        arms.add c.poseOf(i).arms
      result = crossings(arms).len
      c.free()
    check crossed(0.0) == 0
    check crossed(1.0) >= 2

  test "no point of any arm leaps between two moments":
    for (name, band, links, w) in corpus():
      echo &"    {name}: furthest any point moves between moments {w.leap * 1000:.0f} mm, " &
        &"at {w.leapAt:.2f}"
      check w.leap < LEAP


#[ Every Still Stands At Ease ]#

const
  SLOP = 0.005 ## Engine's own linear slop, metres: overlap it never resolves.
  AT_EASE = 0.1 ## Strain no dancer feels: two degrees of twenty into ease that is
                ## assumed to begin there, under what its own start is known to.
  RAD = PI / 180.0 ## One degree.
  JOINED = 0.005 ## Metres joined hands may sit apart and still be joined: slop.
  PART = 0.002 ## Metres any joint of any arm may be pulled apart: dislocation past this.

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

type Posed = tuple[key: string, holds: bool, strain: Strain, depth: float, pair: string,
                   apart, parted: float]
  ## One still of corpus stood live once, and every measure two laws read of it.

var posed: seq[Posed] ## Corpus of stills, stood once.

proc poses(): seq[Posed] =
  ## Every still of corpus stood live at its kept answer, once: strain for one
  ## law; overlap, joined hands and parted joints for other.
  ##   Two laws stood same eight poses each, 6.2 s apiece, measured 2026-09-24.
  if posed.len == 0:
    for q in STILLS[0 ..< CORPUS]:
      let (holds, c) = standOf(q)
      var p: Posed = (q.key, holds, Strain(), 0.0, "", 0.0, 0.0)
      if holds:
        p.strain = c.strainOf
        (p.depth, p.pair) = c.overlapOf
        for i in 0 ..< q.links.len: p.apart = max(p.apart, c.poseOf(i).apart)
        for who in Body:
          for arm in Arm: p.parted = max(p.parted, max(c.partedAt(who, arm)))
      c.free()
      posed.add p
  posed

suite "every still stands at ease":
  ## Architect: every state is easily doable in reality without any strain,
  ## effort or forcing; no clipping, no dislocations, no cheating.  Read where
  ## couple stand for each still: nothing at any end past `AT_EASE`, nothing
  ## through anything, nothing pulled apart, hands joined.

  test "still couple stand for has nothing at its end":
    ## Strain is nought outside every ease band, one at some end.  Every arm,
    ## held or free, both waists, every collarbone: free arm shoved to its end
    ## by partner's trunk is strain couple feel, as much as held one's.
    ##   Where to stand is kept answer; pose there is stood live (`poses`).
    for p in poses():
      let where = answered().stillOf(p.key)
      check where.holds
      check p.holds
      echo &"    {p.key}: stood {where.apart:.2f}, strain {p.strain.most:.2f} " &
        &"at {p.strain.what} {p.strain.whose.body} {p.strain.whose.arm}"
      check p.strain.most <= AT_EASE

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

  test "free couple wound half a turn hang their arms by their sides":
    ## Same, wound to A2: her arms come along with her turn and hang again once
    ## it stops.  Before this, shoulder's spring at one hertz held hanging arm
    ## with two newton metres per radian, and her arms lagged her slow half
    ## turn by twenty five and forty nine degrees, then crept back through
    ## settle to eighteen and thirty three, hand 413 mm off plumb -- flank's
    ## friction against spring nothing like weight of arm.
    for turns in [-0.5, 0.5]:
      let (holds, c) = stood(HUMAN, Band.Crown, FREE, turns, false, Body.Two, 0.48)
      check holds
      for who in Body:
        for arm in Arm:
          let
            j = c.jointsOf(who, arm).j
            p = c.armPoseOf(who, arm)
            hang = p.g - p.s
          echo &"    wound {turns:+.1f} {who} {arm}: extend {j.extend * 180.0 / PI:.1f}, " &
            &"hand {sqrt(hang.x * hang.x + hang.y * hang.y) * 1000:.0f} mm off plumb"
          check abs(j.extend) <= 10.0 * RAD
          check sqrt(hang.x * hang.x + hang.y * hang.y) <= 0.2
      c.free()

  test "no capsule of any arm sits in any other, hands joined, no joint parted":
    ## Read against every capsule engine collides, with distance worked out here
    ## and not engine's manifolds, so engine is not asked to mark its own work.
    ## Deeper than slop is one thing in another; hands further apart than slop
    ## are not joined; joint pulled further than `PART` is dislocation.
    for p in poses():
      check answered().stillOf(p.key).holds
      check p.holds
      if not p.holds: continue
      echo &"    {p.key}: deepest {p.depth * 1000:.1f} mm ({p.pair}), hands " &
        &"{p.apart * 1000:.1f} mm apart, joints parted {p.parted * 1000:.1f} mm"
      check p.depth <= SLOP
      check p.apart <= JOINED
      check p.parted <= PART

  test "hands are above whenever couple are not face to face, from rest on":
    ## Architect: face to face arms may be at any height; once couple are no
    ## longer face to face hands must actually be above.  Hold that rests
    ## pillion is not face to face, so its hands are above at its rest, as its
    ## card draws them.  Keyed to hold's own rest instead, every same-name still
    ## was wound from hold at hip.
    let q = asked("same-name at rest")
    check answered().stillOf(q.key).holds
    let (holds, c) = standOf(q)
    check holds
    for ln in answers.CHAIN:
      for h in ln.ends:
        check c.armPoseOf(h.body, h.arm).g.z >= HUMAN.band[Band.Crown].lo - SAG
    c.free()

  test "hands are up only while couple are not face to face, whole turns and all":
    ## Architect, on A9, wound half turn from pillion rest to face to face with
    ## hands still over heads: modelled but unnatural.  Relaxed position facing
    ## is hands at mid torso; pillion or back to back they have to be above;
    ## facing, arms naturally come down.  Whole turns fold away: couple wound
    ## whole turn face each other again and their hands are down again, which
    ## `risen` keyed to wind from rest never let them be -- and swan may be
    ## reached only so, one connection straightening out as arms come down.
    ##   Nought face to face, one from `RAISE` of turn away, whole turns and
    ##   all.  Going up hands rise over her head as they always did; coming
    ##   back they come forward off her crown first and then down: let down
    ##   straight from over crown to mid torso, they passed through her head.
    var c = build(HUMAN, restStance(HUMAN, 0.44), Band.Crown, WOUND, Body.Two)
    for w in [0.0, 0.1, 0.2, 0.3, 0.5, 0.7, 0.9, 1.0, 1.5]:
      c.stance = turned(restStance(HUMAN, 0.44), Body.Two, w)
      check abs(c.wound - w) < 1e-9
      let away = min(w mod 1.0, 1.0 - w mod 1.0)
      check abs(c.up - min(1.0, away / 0.25)) < 1e-6
      if away > 1e-6 and away < 0.5 - 1e-6: check c.leaving == (w < 0.5)
      check c.height >= c.up
      if c.leaving: check c.over == 1.0
    c.free()
    var p = build(HUMAN, restStance(HUMAN, 0.44, away = true), Band.Crown, answers.CHAIN, Body.Two,
                  away = true)
    check p.wound == 0.0
    check p.up == 1.0
    check p.height == 1.0
    p.free()

  test "facing couple rest their joined hands at mid torso":
    ## Same ruling, on couple as they stand: cross-name chain at its face to
    ## face rest, and same-name chain wound half turn from pillion rest to face
    ## to face (A9), hold with every joined hand in torso band.  Before, A9
    ## stood at 0.60 m with every hand over crown.
    for name in ["cross-name at +0.0", "same-name at half"]:
      let
        q = asked(name)
        links = q.links
        where = answered().stillOf(name)
      check where.holds
      let (holds, c) = standOf(q)
      check holds
      for ln in links:
        for h in ln.ends:
          let z = c.armPoseOf(h.body, h.arm).g.z
          echo &"    {name}: {h.body} {h.arm} hand at {z:.2f} m, stood {where.apart:.2f}"
          check z >= HUMAN.band[Band.Torso].lo - SAG
          check z <= HUMAN.band[Band.Torso].hi + SAG
      c.free()

  test "still that fixes no way about is wound whichever way sits easier":
    ## Card whose picture is same turned either way claims position, not path:
    ## couple take whichever way there sits easier, and answer is never worse
    ## than way asked alone.
    ##   Both searches' answers are kept; each pose is stood live there.
    let
      (askedHolds, askedAt) = standOf(asked("right to left at half"))
      (freeHolds, freeAt) = standOf(asked("right to left at half, either way"))
      (askedWay, freeWay) = (answered().stillOf("right to left at half"),
                             answered().stillOf("right to left at half, either way"))
      (askedStrain, freeStrain) = (askedAt.strainOf, freeAt.strainOf)
    echo &"    right to left at half: asked way stood {askedWay.apart:.2f} strain " &
      &"{askedStrain.most:.2f}; either way stood {freeWay.apart:.2f} at " &
      &"{freeWay.turns:+.1f} strain {freeStrain.most:.2f}"
    check askedHolds
    check freeHolds
    check freeStrain.most <= askedStrain.most
    check freeStrain.most <= AT_EASE
    askedAt.free()
    freeAt.free()

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


#[ Answers ]#

suite "answers":
  ## Laws above read where couple stand from `sim/answers.json`, and search for
  ## nothing.  These hold that file to tree: every question laws ask is answered
  ## there, by sim as it is now.

  test "answers carry stamp of sim that gave them":
    ## Stamp is digest of every `sim/*.nim` and engine's pinned commit
    ## (`answers.stamp`).  Sim changed and not answered again reads other stamp
    ## here, and fails until `nim r tools/build.nim answers` is run.
    check engineCommit(readFile(HERE / "tools" / "build.nim")).len == 40
    check answered().stamp == stamp()

  test "every question is answered, at distance couple may stand at":
    ## Kept distance off grid of `stands` would stand couple where search never
    ## looked, and walk from there would be no walk search made.
    var fars: seq[float]
    for far in stands(HUMAN): fars.add far
    let a = answered()
    check a.sweeps.len == SWEEPS.len
    check a.walks.len == WALKS.len
    check a.reaches.len == REACHES.len
    check a.stills.len == STILLS.len
    for q in SWEEPS:
      let sweep = a.sweepOf(q.key)
      for way in [sweep.neg, sweep.pos]:
        if way.holds: check way.apart in fars
    for q in WALKS:
      let got = a.walksOf(q.key)
      check got.len == fars.len
      for i in 0 ..< min(got.len, fars.len): check got[i].apart == fars[i]
    for q in REACHES: discard a.reachOf(q.key)
    for q in STILLS:
      let where = a.stillOf(q.key)
      if where.holds: check where.apart in fars

  test "kept answers are what sim answers now":
    ## Walk from kept distance is search's own walk from there (`live`), so it
    ## has to hold, carry and stop as kept one did, number for number.  And two
    ## walks from single distances, drawn by stamp, are walked again.  Stamp
    ## says sim has not changed; this says answers came from it.
    let a = answered()
    for q in SWEEPS:
      let sweep = a.sweepOf(q.key)
      for (pos, kept) in [(true, sweep.pos), (false, sweep.neg)]:
        if not kept.holds: continue
        let w = live(q.key, pos)
        check w.holds
        check w.stopped == kept.stopped
        check w.at == kept.at
        check w.why == kept.why
    for (q, kept, w) in replayed():
      echo &"    {q.key}, from {kept.apart:.2f}: kept {kept.carried:.2f}, " &
        &"walked {w.carried:.2f}"
      check w.holds == kept.holds
      check w.stopped == kept.stopped
      check w.at == kept.at
