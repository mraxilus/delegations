## Assert claims eye cannot check, instead of trusting them.
##
##   Everything pages argue is here as test: hands land where
##     rules put them, orbit collapses onto matching axis turn mark
##     for mark, every cycle closes, no reach enters body, bare border
##     carries no arm ink, and sign's geometry is even to tenth of
##     unit.
##   Each page's checker is ledger made executable: one block per rule,
##     each opening with rule in words it was given, each printing
##     one line on every build.  Rule that is only implemented and not
##     asserted is rule that quietly stops being true, which has happened
##     here more than once.
##     Cost of spoken ledger: one line of build noise per rule per page, and
##       there are twenty-nine of them now.  Accepted -- noise is
##       receipt.

{.experimental: "strictFuncs".}

import std/[algorithm, math, options, sequtils, sets, strformat, strutils,
            tables]

import ./[parts, rules, sign]
import ../src/dance_ontology/draw/[body, figure, geometry, pose, route, style]
# Qualified, and only here: rule 11 claims turn pages add no frame that
# app does not have, and only way to check *that* is to ask app's
# own model rather than list this file could let drift.
from ../src/dance_ontology/frame import nil


func decimal(x: float; places: int): string =
  ## Write float as report lines expect it.
  formatFloat(x, ffDecimal, places).strip(leading = false, chars = {'.'})



#[ Frame Page ]#

proc checkFrame*() =
  ## Check frame picture's claims, and say what was measured.
  const want = [
    (Dancer.Lead, Arm.L, (-20.0, 28.0)), (Dancer.Lead, Arm.R, (20.0, 28.0)),
    (Dancer.Follow, Arm.L, (20.0, -28.0)),
    (Dancer.Follow, Arm.R, (-20.0, -28.0)),
  ]
  let h = handsOf(rest())
  for (who, arm, at) in want:
    let got = h[who][arm]
    doAssert abs(got.x - at[0]) < 0.01 and abs(got.y - at[1]) < 0.01,
      &"A hand at rest sits off its column; got `{got}` for {who} {arm}."

  # Collapse: orbit lands where axis turn lands.  Follow who
  # walks quarter round lead keeping their face to them arrives at
  # state lead reaches by turning quarter on spot.
  let
    walked = relative(canonicalise(
      orbit(rest(), Dancer.Follow, 90, locked = true)))
    turned = relative(spinAbout(rest(), Dancer.Lead, -90))
  doAssert walked == turned,
    &"The orbit misses the axis turn; got `{walked}` against `{turned}`."

  # Both going round each other changes nothing about picture.
  doAssert relative(canonicalise(couple(rest(), 73))) == relative(rest()),
    "A couple rotation moved the picture."

  # And whole cycle comes back to exactly where it started.
  for m in MOVES:
    let poses = cycle(m.apply)
    doAssert relative(poses[^1]) == relative(rest()),
      &"A cycle does not close; got `{relative(poses[^1])}` for {m.name}."

  # Boundary is plain circle, and its two stretches tile it once: what
  # is drawn plus two hand gaps covers rim exactly, whatever
  # winding, and every stretch ends one hand-gap short of hand it meets.
  for d in countup(0, 359, 7):
    doAssert abs(outlineR(float(d)) - BODY_R) < 1e-9,
      &"The boundary is not a circle; got `{outlineR(float(d))}` at {d}."
  for (wl, wr) in [(0.0, 0.0), (45.0, 0.0), (0.0, 90.0)]:
    let
      right = ARM_REST + wr
      left = ARM_REST + wl
      edges = [right + HAND_GAP, 360 - left - HAND_GAP,
               360 - left + HAND_GAP, 360 + right - HAND_GAP]
    for i in 0 ..< edges.high:
      doAssert edges[i + 1] >= edges[i],
        &"The rim's stretches overlap; got `{edges}` at winding {wl}, {wr}."
    let drawn = (edges[1] - edges[0]) + (edges[3] - edges[2])
    doAssert abs(drawn + 4 * HAND_GAP - 360) < 1e-9,
      &"The rim does not tile; got `{drawn}` drawn at winding {wl}, {wr}."
  # Extreme winding squeezes back stretch away entirely; border skips
  # reversed stretch rather than drawing it backwards.
  var squeezed_wind: Winds
  squeezed_wind[Dancer.Lead] = [135.0, 0.0]
  let squeezed = border(rest(squeezed_wind), Dancer.Lead)
  doAssert squeezed.count("<path") == 1,
    &"Extreme winding should squeeze one stretch away; got `{squeezed.count(\"<path\")}`."

  # Centred chevron stays well inside its own rim.
  doAssert CHEV_OUT + RIM_W < BODY_R,
    &"The chevron reaches its rim; got `{CHEV_OUT + RIM_W}`."

  # Rim is quiet, always: no arm colour fills up around body, because
  # how far hand has been carried is said by connection wrapping it.
  for wind in [default(Winds), squeezed_wind]:
    let rimmed = border(rest(wind), Dancer.Lead)
    doAssert "var(--left" notin rimmed and "var(--right" notin rimmed,
      "The rim took an arm's colour."

  # Reach is two shades of one hue meeting at its middle: lead's end
  # deep, follow's plain, and both halves same length.
  let
    turned_pose = canonicalise(spinAbout(rest(), Dancer.Follow, 90))
    turned_hands = handsOf(turned_pose)
    ends: route.Ends = (
      turned_hands[Dancer.Lead][Arm.L], turned_hands[Dancer.Follow][Arm.L],
      (turned_pose.place[Dancer.Lead], turned_pose.facing[Dancer.Lead]),
      (turned_pose.place[Dancer.Follow], turned_pose.facing[Dancer.Follow]))
    pts = routed(ends).get.pts
    (near, far) = splitAt(@[pts], pts[pts.len div 2])
    lengths = (polylineLen(near[0]), polylineLen(far[0]))
  doAssert abs(lengths[0] - lengths[1]) < 0.05,
    &"The two shades are uneven; got `{lengths}`."
  doAssert near[0][0] == pts[0] and far[0][^1] == pts[^1],
    "The halves are out of order."
  doAssert near[0][^1] == far[0][0], "The halves do not meet."

  # Body turns way it turned: facings handed to animation never
  # step half turn, so nothing interpolating them can go long way.
  doAssert continuous(@[170.0, 175.0, -175.0]) == @[170.0, 175.0, 185.0],
    "Continuity breaks at the wrap."
  var biggest = 0.0
  for m in MOVES:
    let poses = cycle(m.apply)
    for who in Dancer:
      let steps = facings(poses, who)
      for i in 0 ..< steps.high:
        biggest = max(biggest, abs(steps[i + 1] - steps[i]))
  doAssert biggest < 90, &"A facing steps too far; got `{biggest}`."

  # And no reach ever crosses into body: every hold, every quarter-turn
  # orientation, sampled along route it would actually be drawn with.
  var
    worst = Inf
    ends_off = 0.0
  const held_sets: array[3, Holds] = [
    [some Arm.L, none Arm], [some Arm.R, none Arm], [some Arm.L, some Arm.R]]
  for holds in held_sets:
    for lead_turn in [0.0, 90.0, 180.0]:
      for follow_turn in [0.0, 90.0, 180.0]:
        let
          pose = canonicalise(spinAbout(
            spinAbout(rest(), Dancer.Lead, lead_turn),
            Dancer.Follow, follow_turn))
          pts_all = handsOf(pose)
        for arm in Arm:
          if holds[arm].isNone:
            continue
          let
            a = pts_all[Dancer.Lead][arm]
            b = pts_all[Dancer.Follow][holds[arm].get]
            span: route.Ends = (a, b,
              (pose.place[Dancer.Lead], pose.facing[Dancer.Lead]),
              (pose.place[Dancer.Follow], pose.facing[Dancer.Follow]))
            run = routed(span).get.pts
          doAssert run.len == ROUTE_N,
            &"A route has the wrong shape; got `{run.len}` points."
          if dist(a, b) > 2 * (HAND_R + CAP) + 3:
            ends_off = max(ends_off, max(
              abs(dist(run[0], a) - (HAND_R + CAP)),
              abs(dist(run[^1], b) - (HAND_R + CAP))))
          for q in run:
            for who in Dancer:
              let
                c = pose.place[who]
                f = pose.facing[who]
                depth = dist(q, c) - outlineR(
                  bearing(q.x - c.x, q.y - c.y) - f)
              worst = min(worst, depth)
  doAssert worst > -0.4, &"A reach enters a body; got `{worst}`."
  doAssert ends_off < 0.3, &"A reach misses its hand; got `{ends_off}`."
  echo &"  frame: hands at rest exact; orbit collapses onto axis at " &
    &"({walked.axis}, {walked.facing}); every cycle closes; every rim is " &
    &"quiet and breaks at its hands; a facing never steps more than " &
    &"{decimal(biggest, 1)} degrees a frame; every reach stays on or outside " &
    &"the bodies (margin {decimal(worst, 2)}) and starts {HAND_R + CAP} from its " &
    &"hand (off by {decimal(ends_off, 2)})"



#[ Rules, Measured ]#

proc checkRules*() =
  ## Verify every rule as it was given, and say so, one line per rule.
  ##   Numbering matches ledger in README and `rules.RULES`;
  ##     wording of each heading is wording rule arrived in.
  var told: seq[string]

  # RULE 1.  `"the hands should only pass through the circle when the hand`
  # `positions are above"` -- and moving picture is not frames it is
  # sampled at, it is blend between them, point by point.  Two
  # neighbouring frames that disagree about which side of body line
  # goes round are drawn, in between, as line sweeping straight through
  # that body.  So this checks what is *drawn*: every consecutive pair, part
  # way between, with bodies interpolated too because they move as well.
  # Version of this that looked only at sampled frames let line
  # through middle of dancer, twice.
  var swept = Inf
  for m in MOVES:
    let
      poses = cycle(m.apply).mapIt(
        settled(it, HOLD, default(Levels), default(Ways)))
      hands = poses.mapIt(handsOf(it))
    var frames: seq[route.Ends]
    for i, hnd in hands:
      frames.add (hnd[Dancer.Lead][Arm.L], hnd[Dancer.Follow][Arm.L],
                  (poses[i].place[Dancer.Lead], poses[i].facing[Dancer.Lead]),
                  (poses[i].place[Dancer.Follow],
                   poses[i].facing[Dancer.Follow]))
    let
      way = oneWayRound(frames)
      runs = frames.mapIt(routed(it, some way).get.pts)
    for k in 0 ..< runs.high:
      let
        qa = poses[k]
        qb = poses[k + 1]
      for part in [0.25, 0.5, 0.75]:
        var drawn: seq[Point]
        for i, a in runs[k]:
          let b = runs[k + 1][i]
          drawn.add (a.x + (b.x - a.x) * part, a.y + (b.y - a.y) * part)
        for who in Dancer:
          let
            c: Point = (
              qa.place[who].x + (qb.place[who].x - qa.place[who].x) * part,
              qa.place[who].y + (qb.place[who].y - qa.place[who].y) * part)
            f = qa.facing[who] + part * (qb.facing[who] - qa.facing[who])
          for i in 0 ..< drawn.high:
            for j in 0 .. 8:
              let
                t = j / 8
                pt: Point = (
                  drawn[i].x + (drawn[i + 1].x - drawn[i].x) * t,
                  drawn[i].y + (drawn[i + 1].y - drawn[i].y) * t)
                deep = dist(pt, c) - outlineR(
                  bearing(pt.x - c.x, pt.y - c.y) - f)
              swept = min(swept, deep)
  doAssert swept > -0.3,
    &"A blended frame sweeps a line through a body; got `{decimal(swept, 2)}`."
  told.add &"only `above` crosses a body, at every instant drawn " &
    &"(worst {decimal(swept, 2)})"

  # RULE 2.  `"the hands can only move from their positions at the side of`
  # `the body only if a level is specified"`, and level alone is not enough:
  # way has to be said too, or there is no knowing which side it went to.
  for (level, way, moves) in [
      (none Level, none Way, false), (some Level.Low, none Way, false),
      (none Level, some Way.Wrap, false),
      (some Level.Low, some Way.Lock, true)]:
    let put = handsOf(settled(rest(), HOLD, said(level),
                              said(way)))[Dancer.Lead][Arm.L]
    doAssert (put != handsOf(rest())[Dancer.Lead][Arm.L]) == moves,
      &"A hand moved on half a say; got level `{level}`, way `{way}`."
  told.add "a hand moves only when a level *and* a way are named"

  # RULE 3.  `"the slots are relative to the front facing side of the`
  # `lead/follow, not from the diagram itself."`  Six spots: default, and one
  # slightly towards front and one slightly towards back, measured
  # off dancer's own facing and never off page.
  var places: seq[float]
  for arm in Arm:
    for slot in Slot:
      places.add slotBearing(arm, slot)
  var apart = 360.0
  for i, a in places:
    for b in places[i + 1 .. ^1]:
      apart = min(apart, abs(wrap180(a - b)))
  doAssert places.len == 6, &"Six spots expected; got `{places.len}`."
  doAssert apart > 2 * radToDeg(arcsin(HAND_R / BODY_R)),
    &"Two spots touch; got `{apart}` degrees apart."
  # And they turn with dancer: settle hold, turn follow, and every
  # hand is still exactly where its spot says relative to its own facing.
  for turn in [0.0, 90.0, 180.0, 270.0]:
    let pose = settled(canonicalise(spinAbout(rest(), Dancer.Follow, turn)),
                       HOLD, said(some Level.Low), said(some Way.Lock))
    for who in Dancer:
      let
        got = handBearing(0.0, Arm.L, pose.wind[who][Arm.L])
        landed = slotOf(Arm.L, some Level.Low, some Way.Lock)
      doAssert abs(wrap180(got - slotBearing(landed.arm, landed.slot))) <
        1e-9, &"A spot is page-relative; got `{got}` at turn {turn} for {who}."
  told.add &"six spots, {decimal(apart, 0)} degrees apart at the closest, " &
    "off each dancer's own facing"

  # RULES 4, 5 and 6.  `"high and low wraps go around to the front of the`
  # `other hand, low lock goes around the back to the back of the other hand"`
  # and `"in high lock the line goes around the back of the modified body"`,
  # to back of current hand.  Table here is rules
  # transcribed, held against settle table that drawing derives from.
  const WHERE = [
    (level: Level.High, way: Way.Wrap, whose: Whose.Other, spot: Slot.Front,
     sends: Sends.FrontWay),
    (level: Level.Low, way: Way.Wrap, whose: Whose.Other, spot: Slot.Front,
     sends: Sends.FrontWay),
    (level: Level.Low, way: Way.Lock, whose: Whose.Other, spot: Slot.Back,
     sends: Sends.BackWay),
    (level: Level.High, way: Way.Lock, whose: Whose.Own, spot: Slot.Back,
     sends: Sends.BackWay),
  ]
  for w in WHERE:
    for arm in Arm:
      let lands = if w.whose == Whose.Own: arm else: other(arm)
      doAssert slotOf(arm, some w.level, some w.way) == (lands, w.spot),
        &"A settle lands wrong; got `{slotOf(arm, some w.level, some w.way)}`."
    doAssert roundOf(some w.level, some w.way) == some w.sends,
      &"A hold sends its line the wrong way; got " &
        &"`{roundOf(some w.level, some w.way)}` for {w.level} {w.way}."
    # And drawn route really does set off that way, at both ends.
    let
      turn = if w.way == Way.Wrap: 180.0 else: 0.0
      pose = settled(canonicalise(spinAbout(rest(), Dancer.Follow, turn)),
                     HOLD, said(some w.level), said(some w.way))
      p = handsOf(pose)
      ends: route.Ends = (p[Dancer.Lead][Arm.L], p[Dancer.Follow][Arm.L],
        (pose.place[Dancer.Lead], pose.facing[Dancer.Lead]),
        (pose.place[Dancer.Follow], pose.facing[Dancer.Follow]))
      asked = wayFor(ends, some w.level, some w.way)
      towards = if w.sends == Sends.FrontWay: 1.0 else: -1.0
    doAssert asked == some (towards * frontOf(ends.a, ends.body_a).get,
                            towards * frontOf(ends.b, ends.body_b).get),
      &"The asked way is not the rule's way for {w.level} {w.way}."
    doAssert routed(ends, asked).get.way == asked.get,
      &"The drawn route disobeys its way for {w.level} {w.way}."
  told.add "both wraps land in front and go round the front; both locks " &
    "land behind and go round the back"

  # RULE 7.  `"lock/wrap positions can only be used when the connecting line`
  # `goes around no less than just under 1/2 of the circumference.  it`
  # `doesn't make sense to have a wrap or a lock without the line actually`
  # `going around the body."`
  var arc_seen: HashSet[float]
  for w in WHERE:
    for turn in [0.0, 90.0, 180.0, 270.0]:
      let
        pose = canonicalise(spinAbout(rest(), Dancer.Follow, turn))
        p = handsOf(settled(pose, HOLD, said(some w.level),
                            said(some w.way)))
        ends: route.Ends = (p[Dancer.Lead][Arm.L], p[Dancer.Follow][Arm.L],
          (pose.place[Dancer.Lead], pose.facing[Dancer.Lead]),
          (pose.place[Dancer.Follow], pose.facing[Dancer.Follow]))
        asked = wayFor(ends, some w.level, some w.way)
        arcs = if asked.isSome: wrapArc(ends, asked.get)
               else: none(tuple[a, b: float])
        ok = danceable(pose, HOLD, said(some w.level), said(some w.way))
      doAssert ok == (arcs.isSome and
                      max(arcs.get.a, arcs.get.b) >= float(WRAP_MIN)),
        &"Danceable and the measured arc disagree for {w.level} {w.way}."
      if arcs.isSome:
        arc_seen.incl max(arcs.get.a, arcs.get.b)
  # Arcs are quantised, and threshold sits in gap below one half.
  for v in arc_seen:
    doAssert v <= 141 or v >= 180,
      &"An arc falls between the quanta; got `{v}`."
  doAssert 141 < WRAP_MIN and WRAP_MIN < 180,
    &"The threshold left the gap; got `{WRAP_MIN}`."
  let quanta = arc_seen.toSeq.mapIt(int(it)).sorted
  told.add &"a lock or wrap needs {WRAP_MIN} degrees of wrap; the arcs " &
    &"this geometry makes are [{quanta.mapIt($it).join(\", \")}]"

  # RULE 8.  `"above has no locks/wraps and can only transition to upper wrap`
  # `or back to default (physical restrictions)."`  `upper wrap` is read as
  # high wrap; that reading is implementer's and not rule's.
  for way in [some Way.Lock, some Way.Wrap, none(Way)]:
    doAssert slotOf(Arm.L, some Level.Above, way) == (Arm.L, Slot.Default),
      &"Above settled away from home; got way `{way}`."
    doAssert roundOf(some Level.Above, way).isNone,
      &"Above sent its line round; got way `{way}`."
  # "leads only to" half rests on `FROM_ABOVE`, which is ledger data
  # nothing loads yet -- see TODO in `rules.nim`.  One doAssert used to
  # compare it to its own spelled-out copy here, which checked nothing;
  # what drawing can actually be held to is half above.
  told.add "`above` takes no lock or wrap, and leads only to high wrap " &
    "or default"

  # RULE 9.  Connecting line's two halves are its two hands' own
  # colours.  Shades are asked of palette rather than spelled out
  # here, so this measures drawing and not how colour is written:
  # spelled out, it broke when palette took its fallbacks.
  let crossed = renderFigure("f", [some Arm.R, none Arm], said(some Level.Low))
  doAssert DEEP[Arm.L] in crossed and INK[Arm.R] in crossed,
    "A crossed connection lost one of its two hands' colours."
  told.add "a connection is drawn in its two hands' own colours"

  for line in told:
    echo &"  rule: {line}"



#[ Single-Hand Turns ]#

proc checkSingleTurns*() =
  ## Verify single-hand turns page's rules as given, one line each.
  var told: seq[string]
  let built = singleTurnParts()

  # RULE 17.  `"all turns should be in the \"above\" position, not the high.`
  # `high/low causes wraps/locks, so we're currently making the assumption`
  # `to avoid those."`  Every held hand carries above hatch, and above is
  # level that cannot lock or wrap however couple is turned.
  var hatched = 0
  for key, figure in built:
    if not (key.startsWith("st_") or key.startsWith("tr_")):
      continue
    doAssert "r=\"2.7\"" notin figure,
      &"A high dot appears where above was asked for; got `{key}`."
    if "url(#h" in figure:
      inc hatched
  doAssert hatched > 0, "No above hatch drawn anywhere; the level is unsaid."
  for way in [none(Way), some Way.Lock, some Way.Wrap]:
    doAssert roundOf(some Level.Above, way).isNone,
      &"Above sent its line round; got way `{way}`."
    doAssert slotOf(Arm.L, some Level.Above, way) == (Arm.L, Slot.Default),
      &"Above settled off its own side; got way `{way}`."
  told.add &"every turn is held above, hatched on {hatched} figures: the " &
    "one level that cannot lock or wrap whichever way the couple turns"

  # RULE 11.  `"no additional frame positions, just the addition of`
  # `rotations that let us travel between them."`  Measured against app's
  # own model: single-hold frames are read out of `frame.FRAMES` rather
  # than from list this file used to keep, which asserted copy against
  # itself and would have missed app changing.
  var app_singles: seq[Holds]
  for laid in frame.FRAMES:
    if frame.countHolds(laid) != 1:
      continue
    var holds: Holds
    for side in frame.Side:
      if laid.hold[side].isSome:
        holds[if side == frame.Side.Left: Arm.L else: Arm.R] =
          some (if laid.hold[side].get == frame.Site.LeftHand: Arm.L
                else: Arm.R)
    app_singles.add holds
  doAssert app_singles.len == SINGLES.len,
    &"The app's single-hold frames moved; got `{app_singles.len}`."
  for single in SINGLES:
    doAssert single.holds in app_singles,
      &"A hold outside the app's four appears; got `{single.name}`."
  told.add &"every position is one of the app's {SINGLES.len} single-hand " &
    "frames, turned; nothing new is drawn"

  # RULE 19.  `"you should also include orbit turns not just the axis`
  # `turns."`  Four ways: each dancer's own axis turn and each dancer's orbit
  # of other -- orbits ringed, since ring says who is standing
  # still.  Which ways share round of positions is measured here rather
  # than taken from table, and table is held to measurement.
  var axis_ways, orbit_ways = 0
  for way in TurnWay:
    let w = WAYS_OF_TURNING[way]
    if w.about == About.Axis: inc axis_ways else: inc orbit_ways
    let ringed = built[&"tr_{w.tag}_0_0_1"].contains("stroke-dasharray")
    doAssert ringed == (w.about == About.Orbit),
      &"An orbit's ring is missing or an axis turn has one; got {way}."
  doAssert axis_ways == 2 and orbit_ways == 2,
    &"Four ways expected; got `{axis_ways}` axis and `{orbit_ways}` orbit."

  func roundOfWay(way: TurnWay): HashSet[tuple[axis, facing: float]] =
    ## Collect set of places one way of turning walks through.
    for quarter in 0 ..< QUARTERS_ROUND:
      result.incl placeOf(quarterPose(way, quarter))

  var rounds: seq[HashSet[tuple[axis, facing: float]]]
  for way in TurnWay:
    let walked = roundOfWay(way)
    # Table's claim about this way holds: it shares its round with
    # every way of its family, and with no other.
    for mate in TurnWay:
      let shares = roundOfWay(mate) == walked
      doAssert shares == (FAMILY_OF[mate] == FAMILY_OF[way]),
        &"A way left its family; got {way} against {mate}."
    if walked notin rounds:
      rounds.add walked
  doAssert rounds.len == 2,
    &"Two rounds expected of four ways; got `{rounds.len}`."
  told.add &"{axis_ways} axis turns and {orbit_ways} orbits, the orbits " &
    &"ringed; the four ways walk {rounds.len} rounds, each reached by one " &
    "axis turn and by the other dancer's orbit -- which is rule 32's own " &
    "consequence, and what lets the ways be equated"

  # RULE 18.  `"the leads' transitions should still be in the 2 stage form,`
  # `stage 1 is the lead turns with the original perspective stage 2 is`
  # `reorienting the perspective."`  Measured on walk: stage one leaves
  # picture off canonical -- leaning, or off centre, or both -- and
  # stage two brings it back.  Turn that leaves framing exactly as
  # it found it has no second stage to draw, and framed on lead
  # (rule 25) that is every turn but lead's own.
  for way in TurnWay:
    let
      w = WAYS_OF_TURNING[way]
      walk = turnWalk(quarterPose(way, 0), w.who, w.about, QUARTER,
                      on = Anchor.Lead)
    var
      leaned = 0.0
      strayed = 0.0
    for put in walk.poses:
      leaned = max(leaned, abs(wrap180(put.facing[Dancer.Lead])))
      for dancer in Dancer:
        let settled_place = canonicalise(put, on = Anchor.Lead).place[dancer]
        strayed = max(strayed, dist(put.place[dancer], settled_place))
    let re_framed = w.who == Dancer.Lead
    if re_framed:
      doAssert leaned > 45 or strayed > 1,
        &"A turn never left the canonical framing; got {way}."
      doAssert abs(wrap180(walk.poses[^1].facing[Dancer.Lead])) < 1e-9,
        &"A turn ended off upright; got {way}."
      doAssert dist(walk.poses[^1].place[Dancer.Lead],
                    canonicalise(walk.poses[^1], on = Anchor.Lead)
                      .place[Dancer.Lead]) < 1e-9,
        &"A turn ended off centre; got {way}."
    else:
      doAssert leaned < 1e-9 and strayed < 1e-9,
        &"A turn moved the framing with nothing to re-frame; got {way}."
  told.add "a turn that moves the framing is danced in two stages -- the " &
    "room holds still while it happens, then the picture is brought back " &
    "to the lead facing up and back on their own spot; framed on the lead, " &
    "only a lead's own move has anything to bring back"

  # RULE 16 and RULE 15.  Four orientations per connection, round
  # closing rather than refusing; every one of them drawn and every edge
  # between them animated.
  var statics, moving = 0
  for key in built.keys:
    if key.startsWith("st_"): inc statics
    if key.startsWith("tr_") and not key.endsWith("_still"): inc moving
  let want = (TurnWay.high.int + 1) * SINGLES.len * QUARTERS_ROUND
  doAssert statics == want,
    &"A position went undrawn; got `{statics}` of `{want}`."
  doAssert moving == want,
    &"An edge went unanimated; got `{moving}` of `{want}`."
  for way in TurnWay:
    doAssert placeOf(quarterPose(way, QUARTERS_ROUND)) ==
      placeOf(quarterPose(way, 0)),
      &"Four quarters do not close the round; got {way}."
  told.add &"a single hand above turns for ever: {QUARTERS_ROUND} " &
    &"orientations a way, the round closing rather than refusing, all " &
    &"{statics} positions drawn and all {moving} transitions animated"

  # RULE 32.  `"orbit should not maintain bearing, but instead keep whatever`
  # `side faces the center, facing the center."`  Measured through every orbit
  # walk: walker turns as far as they travel, so angle their facing
  # makes with line to centre never moves.  Which is what makes half
  # turn of orbit half turn of anything at all.
  var
    swung = 0.0
    held = 0.0
  for way in TurnWay:
    let
      w = WAYS_OF_TURNING[way]
      start = quarterPose(way, 0)
      walk = turnWalk(start, w.who, w.about, QUARTER, on = Anchor.Lead)
      other_one = if w.who == Dancer.Lead: Dancer.Follow else: Dancer.Lead
    var carried = 0.0
    for put in walk.poses:
      carried = max(carried,
        abs(wrap180(put.facing[w.who] - walk.poses[0].facing[w.who])))
    if w.about == About.Orbit:
      # Side of them that faces centre: angle between way
      # they face and way their partner lies from them.
      var facing_in = 0.0
      for put in walk.poses:
        let toward = bearing(put.place[other_one].x - put.place[w.who].x,
                             put.place[other_one].y - put.place[w.who].y)
        facing_in = max(facing_in, abs(wrap180(
          (toward - put.facing[w.who]) -
          (bearing(start.place[other_one].x - start.place[w.who].x,
                   start.place[other_one].y - start.place[w.who].y) -
           start.facing[w.who]))))
      doAssert facing_in < 1e-9,
        &"An orbit turned the walker off the centre; got " &
          &"`{decimal(facing_in, 1)}` for {way}."
      held = max(held, carried)
      swung = max(swung, abs(wrap180(
        placeOf(quarterPose(way, 1)).axis - placeOf(quarterPose(way, 0)).axis)))
    doAssert carried > 45,
      &"A way of turning never turned its dancer; got {way}."
  doAssert abs(swung - QUARTER) < 1e-9,
    &"An orbit swung the axis by the wrong amount; got `{decimal(swung, 1)}`."
  doAssert abs(held - QUARTER) < 1e-9,
    &"An orbit turned its walker by the wrong amount; got `{decimal(held, 1)}`."
  told.add &"an orbit faces the centre: the walker turns the same " &
    &"{decimal(held, 0)} degrees they travel, so whatever side of them faced " &
    &"their partner still does, and the pair's axis swings the whole " &
    &"{decimal(swung, 0)} -- which is what makes half a turn mean one thing " &
    "however it is danced"

  # RULE 21.  `"also, the animations should also have the above level as`
  # `that's the only valid one for the current scope."`  Moving hand says
  # its level as still one does: every held hand of every transition
  # carries above hatch.
  # RULE 33 goes with it: `"the above level hatching appears to be a`
  # `background that moves around a lot as the squares/circles move, it`
  # `should stay visually consistent during animation."`  Hatch is
  # pattern anchored to user space, so mark that animates its own
  # coordinates slides across hatch standing still.  Carried by
  # transform instead, hatch travels with it -- which is measured here
  # as mark animating nothing of its own: hatched element with no
  # children has no coordinates to animate.
  var
    moving_hatched = 0
    held_still = 0
  for key, figure in built:
    if not key.startsWith("tr_") or key.endsWith("_still"):
      continue
    doAssert "url(#h" in figure,
      &"A moving hand lost its level; got no hatch in `{key}`."
    for part in figure.split('<'):
      if "url(#h" notin part:
        continue
      doAssert "/>" in part,
        &"A hatched mark animates its own place, so its hatch will swim; " &
          &"got `{key}`."
      inc held_still
    inc moving_hatched
  doAssert moving_hatched == want,
    &"A transition went unhatched; got `{moving_hatched}` of `{want}`."
  told.add &"all {moving_hatched} animations carry the above hatch on " &
    &"their held hands, as the still figures beside them do -- and all " &
    &"{held_still} of those marks are carried by a transform rather than " &
    "animating their own place, so the hatch travels with the mark instead " &
    "of the mark sliding across it"

  # RULE 14.  Nothing wraps body: measured as how far reach bows off
  # chord between its own two hands, standing and turning alike.
  var bowed = 0.0
  for way in TurnWay:
    let w = WAYS_OF_TURNING[way]
    for single in SINGLES:
      for arm in Arm:
        if single.holds[arm].isNone:
          continue
        let walk = turnWalk(quarterPose(way, 0), w.who, w.about, QUARTER,
                            on = Anchor.Lead)
        var runs: seq[seq[Point]]
        for put in walk.poses:
          let p = handsOf(put)
          runs.add straightReach(p[Dancer.Lead][arm],
                                 p[Dancer.Follow][single.holds[arm].get])
          let
            head = runs[^1][0]
            tail = runs[^1][^1]
            reach = dist(head, tail)
          for q in runs[^1]:
            bowed = max(bowed, abs((tail.x - head.x) * (head.y - q.y) -
                                   (head.x - q.x) * (tail.y - head.y)) / reach)
        for k in 0 ..< runs.high:
          for part in [0.25, 0.5, 0.75]:
            var drawn: seq[Point]
            for i, a in runs[k]:
              let b = runs[k + 1][i]
              drawn.add (a.x + (b.x - a.x) * part, a.y + (b.y - a.y) * part)
            let span = dist(drawn[0], drawn[^1])
            for q in drawn:
              bowed = max(bowed,
                abs((drawn[^1].x - drawn[0].x) * (drawn[0].y - q.y) -
                    (drawn[0].x - q.x) * (drawn[^1].y - drawn[0].y)) / span)
  doAssert bowed < 0.5,
    &"A reach bows off its chord, which is a wrap; got `{decimal(bowed, 2)}`."
  told.add &"nothing wraps a body: every turning reach, and every instant " &
    &"drawn between its frames, is straight to within {decimal(bowed, 2)} of " &
    "its own chord"

  # RULE 22.  `"an arm shouldn't settle in a hand cell it's not connected to`
  # `... it should bend around all hand cells and chevrons as to not imply`
  # `connection and not obscure direction. it is however fine to animate`
  # `smoothly past it."`  Both halves are measured on line as drawn:
  # settled reach keeps daylight from every mark it does not join, and
  # moving one still runs straight through.
  # RULE 23.  `"prefer paths that have fewers bends (ideally 1) as well as`
  # `length."`  Counted on drawn line: how many turns each settled reach
  # asks reader to follow, and -- wherever one asks for more than
  # single turn -- that no other way past same marks would have asked
  # less, length and turns weighed together.
  # RULE 24.  `"prefer smooth long curves instead of sharp breaks."`  Curve
  # drawn as straight bits turns some degrees at each of them; break
  # turns many at one.  So sharpest single corner on page is what
  # is measured, over every settled reach.
  var
    turns: array[4, int]
    bought = 0.0
    sharpest = 0.0
  var
    daylight = Inf
    fouled = 0.0
    kept = 0
  for way in TurnWay:
    for single in SINGLES:
      for arm in Arm:
        if single.holds[arm].isNone:
          continue
        for quarter in 0 ..< QUARTERS_ROUND:
          let
            put = settled(quarterPose(way, quarter), single.holds,
                          levelsFor(single.holds), default(Ways))
            p = handsOf(put)
            (a, b) = (p[Dancer.Lead][arm], p[Dancer.Follow][single.holds[arm].get])
            marks = clearingMarks(put, a, b)
          let settled_reach = clearedReach(a, b, marks)
          turns[min(bendsIn(settled_reach), turns.high)] += 1
          sharpest = max(sharpest, sharpestIn(settled_reach))
          if bendsIn(settled_reach) > 1:
            # It kept second turn, so every plainer way past these marks
            # must have cost more line than turn is worth.
            for side in SIDES:
              let other = letGo(a, b, marks, side)
              doAssert readingCost(settled_reach) <= readingCost(other) + 1e-6,
                &"A plainer reach went untaken; got {way} on {single.name}."
              if bendsIn(other) < bendsIn(settled_reach):
                bought = max(bought,
                             polylineLen(other) - polylineLen(settled_reach))
          for (drawn, moving) in [(settled_reach, false),
                                  (straightReach(a, b), true)]:
            for mark in marks:
              # Measured as plain daylight: what is left between drawn
              # stroke and drawn mark once both their widths are taken
              # off, which is what reader actually sees.
              let gap = nearestOn(drawn, mark.centre) - mark.clear + SEEN_GAP
              if moving:
                fouled = max(fouled, -gap)
              else:
                daylight = min(daylight, gap)
                inc kept
  doAssert daylight > 0,
    &"A settled reach ran through a mark; got `{decimal(daylight, 2)}`."
  # And exemption is worth having: straight line these bends replace
  # really does foul something, so this is not bend drawn for nothing.
  doAssert fouled > SEEN_GAP,
    &"Nothing was ever in a reach's way; got `{decimal(fouled, 2)}`."
  told.add &"a settled reach bends round every mark it does not join: " &
    &"{kept} clearances measured, the tightest leaving {decimal(daylight, 2)} " &
    &"of daylight, where the straight line it replaces buries itself " &
    &"{decimal(fouled, 1)} into a mark; a turning reach stays straight and " &
    "passes smoothly across, as the rule allows"

  doAssert turns[3] == 0,
    &"A reach turned three times or more; got `{turns[3]}` of them."
  told.add &"a settled reach is the plainest way past those marks, not " &
    &"merely the shortest: {turns[0]} run straight, {turns[1]} turn once " &
    &"and {turns[2]} twice, and no plainer way past the same marks was " &
    &"passed over -- a second turn is kept only where going round in one " &
    &"would have cost more than {decimal(BEND_COST, 0)} of line" &
    (if bought > 0: &", which here reaches {decimal(bought, 1)}" else: "")

  doAssert sharpest < SHARP_MAX,
    &"A reach turns at a point rather than over a run; got " &
      &"`{decimal(sharpest, 1)}` degrees at one corner."
  told.add &"and it bends rather than breaks: the sharpest corner anywhere " &
    &"on the page turns {decimal(sharpest, 1)} degrees, so what turns, turns " &
    "over a run of the line and not at a point in it"

  # RULE 25.  `"lead position should remain fixed as much as possible ...`
  # `obviously this can't really be the case when the lead orbits."`
  # Measured through every walk: how far lead's own place travels from
  # first frame to last, and across four positions of every round.
  var re_entered: seq[string]
  for way in TurnWay:
    let w = WAYS_OF_TURNING[way]
    var moved = 0.0
    for quarter in 0 ..< QUARTERS_ROUND:
      let start = quarterPose(way, quarter)
      doAssert dist(start.place[Dancer.Lead],
                    quarterPose(way, 0).place[Dancer.Lead]) < 1e-9,
        &"The lead stands somewhere else in this position; got {way}."
      for put in turnWalk(start, w.who, w.about, QUARTER,
                          on = Anchor.Lead).poses:
        moved = max(moved, dist(put.place[Dancer.Lead],
                                start.place[Dancer.Lead]))
    # Only lead's own orbit may move them, and it must: walking round
    # somebody and staying put are not same act.
    let walks_off = w.who == Dancer.Lead and w.about == About.Orbit
    doAssert (moved > 1) == walks_off,
      &"The lead moved where they should not, or held where they " &
        &"cannot; got `{decimal(moved, 1)}` for {way}."
    if walks_off:
      re_entered.add w.title.toLowerAscii
  # RULE 26.  `"make the second animation stage quicker ... so it has less`
  # `emphasis."`  Measured on clock that markup actually carries:
  # interval where pair's own configuration changes is turn, one
  # where whole picture moves rigidly is re-framing, and one where
  # nothing moves at all is held beat.
  var slowest = 0.0
  for way in TurnWay:
    let
      w = WAYS_OF_TURNING[way]
      walk = turnWalk(quarterPose(way, 0), w.who, w.about, QUARTER,
                      on = Anchor.Lead)
    var turning, framing, beats = 0.0
    for i in 0 ..< walk.poses.high:
      let
        gap = walk.times[i + 1] - walk.times[i]
        (before, after) = (walk.poses[i], walk.poses[i + 1])
      if relative(before) != relative(after):
        turning += gap
      elif before.place == after.place and before.facing == after.facing:
        beats += gap
      else:
        framing += gap
    doAssert abs(turning + framing + beats - 1.0) < 1e-9,
      &"A move's clock does not add up; got `{turning + framing + beats}`."
    doAssert (framing > 0) == (w.who == Dancer.Lead),
      &"A move re-framed when it had nothing to re-frame; got {way}."
    if framing > 0:
      doAssert framing < turning / 2,
        &"The re-framing takes as long as the turn; got " &
          &"`{decimal(framing, 2)}` against `{decimal(turning, 2)}` for {way}."
      slowest = max(slowest, framing / turning)
  told.add &"and the turn is what a transition is of: where the picture " &
    &"has to be brought back afterwards it takes {decimal(100 * slowest, 0)} " &
    "per cent of the time the turn itself takes, after a held beat on the " &
    "landing, so it reads as the frame catching up rather than as a second " &
    "move"

  let ways = TurnWay.toSeq.len
  told.add &"the lead is the still point: they stand on the same spot in " &
    &"every position of every round, and never move through " &
    &"{ways - re_entered.len} of the {ways} ways of turning -- only " &
    &"""{re_entered.join(" and ")} takes them off it, and there the """ &
    "picture has to bring them back"

  for line in told:
    echo &"  rule: {line}"


func inkOf(figure, ink: string): float =
  ## Measure how much line of one shade figure actually draws.
  ##   Counting pieces one reach is drawn in cannot see break that falls
  ##     where two shades meet -- it makes one piece of each rather than
  ##     two of one.  Length can see it wherever it falls: broken reach
  ##     draws one `BREAK` less than whole one.
  ##   Reach is drawn as quadratics through midpoints between its
  ##     sampled points (rule 35), and every one of those points is
  ##     control point of curve -- so reading `M`, each `Q`'s
  ##     control and closing `L` gives back very polyline that
  ##     routing produced, and measure is what it always was.
  for part in figure.split("<path "):
    if &"stroke=\"{ink}\"" notin part:
      continue
    const opens = "d=\""
    let at = part.find(opens)
    if at < 0:
      continue
    let drawn = part[at + opens.len ..< part.find('"', at + opens.len)]
    for subpath in drawn.split('M'):
      if subpath.len == 0:
        continue
      var
        last = none(Point)
        anchors: seq[Point]
      for step in subpath.split({'Q', 'L'}):
        let says: seq[string] = step.strip.split(' ')
        if says.len < 2:
          continue
        # `Q` carries its control point first and place that curve
        # passes through second; control is routed point.
        anchors.add (parseFloat(says[0]), parseFloat(says[1]))
      for here in anchors:
        if last.isSome:
          result += dist(last.get, here)
        last = some here



#[ Hand-to-Hand Turns ]#

proc checkHandTurns*() =
  ## Verify hand-to-hand turns page's rules as given, one line each.
  var told: seq[string]
  let built = handTurnParts()

  func pairOf(wind: float): array[Arm, seq[Point]] =
    ## Pair as this position draws it, both reaches at once.
    pairAt(HAND_TO_HAND, wind, HAND_PHASE)

  # RULE 28 and RULE 31.  `"add the half turns which should actually form an`
  # `X overhead ... as states in-between the outside 2"`, and `"hand to hand`
  # `actually has an extra half turn on both ends"`.  Seven positions, half
  # turn apart, and wind is measured off drawing rather than taken
  # on trust.
  doAssert CHAIN.len == 7, &"Seven positions expected; got `{CHAIN.len}`."
  var drawn: seq[string]
  for i, position in CHAIN:
    doAssert built[&"hh_{i}"] notin drawn,
      &"Two positions draw alike; got `{position.name}`."
    drawn.add built[&"hh_{i}"]
    # Pose each position stands in really is wound that far: measured as
    # angle each held hand makes with pair's own axis.
    let put = settled(handPose(position.wind), HAND_TO_HAND, ABOVE_BOTH,
                      default(Ways))
    for arm in Arm:
      let turned_by = windOf(put, HAND_TO_HAND, arm).spread / 360
      doAssert abs(wrap180(360 * (turned_by - position.wind))) < 1e-6,
        &"A position is not wound what it says; got " &
          &"`{decimal(turned_by, 2)}` for `{position.name}`."
    # And facing alternates down chain: partners face one
    # another where wind is whole number of turns and same way
    # where it is half of one, which is what makes cross what it is and is
    # half turn of offset at which other pattern is read (rule 31).
    let facing_apart = abs(wrap180(
      put.facing[Dancer.Follow] - put.facing[Dancer.Lead]))
    doAssert abs(facing_apart - (if int(abs(position.wind) * 2) mod 2 == 1:
                                   0.0 else: 180.0)) < 1e-6,
      &"A position faces the wrong way about; got `{position.name}`."
  told.add &"{CHAIN.len} positions, a half turn apart, each wound exactly " &
    "what it claims -- measured as the angle each held hand makes with the " &
    "pair's own axis, not taken on trust"

  # RULE 27 and RULE 28.  Crossings are what wind makes: none at
  # frame, one at half turn -- cross -- and two at whole one, one
  # by each dancer, with diamond between.
  var
    smallest = Inf
    apart = Inf
  for position in CHAIN:
    let
      pair = pairOf(position.wind)
      meetings = crossingsOf(pair[Arm.L], pair[Arm.R])
      want = int(abs(position.wind) * 2)
    doAssert meetings.len == want,
      &"A position crosses the wrong number of times; got " &
        &"`{meetings.len}` of `{want}` in `{position.name}`."
    if meetings.len != 2:
      continue
    let
      put = settled(handPose(position.wind), HAND_TO_HAND, ABOVE_BOTH,
                    default(Ways))
      by_lead = dist(meetings[0], put.place[Dancer.Lead]) <
                dist(meetings[1], put.place[Dancer.Lead])
      by_follow = dist(meetings[0], put.place[Dancer.Follow]) <
                  dist(meetings[1], put.place[Dancer.Follow])
    doAssert by_lead != by_follow,
      &"Both crossovers fell on one dancer; got `{position.name}`."
    apart = min(apart, dist(meetings[0], meetings[1]))
    # What both reaches enclose between crossings: diamond.
    var ring: seq[Point]
    for run in [pair[Arm.L], reversed(pair[Arm.R])]:
      for q in run:
        if dist(q, meetings[0]) + dist(q, meetings[1]) <
            dist(meetings[0], meetings[1]) + DIAMOND_ROOM:
          ring.add q
    var twice = 0.0
    for k in 0 ..< ring.high:
      twice += ring[k].x * ring[k + 1].y - ring[k + 1].x * ring[k].y
    twice += ring[^1].x * ring[0].y - ring[0].x * ring[^1].y
    smallest = min(smallest, abs(twice) / 2)
  doAssert smallest > 2 * DIAMOND_ROOM,
    &"The diamond pinched shut; got `{decimal(smallest, 0)}` of room in it."

  # RULE 31.  `"don't draw it as a double box, draw it as one connection`
  # `being straight and the other snaking around it."`  At turn and half,
  # pair stops sharing its swing: one reach is plain chord between
  # its hands and other carries all of it, which is three crossings held
  # round straight line rather than two diamonds stacked.
  var
    swans = 0
    flattest = Inf
    snakiest = Inf
  for position in CHAIN:
    let pair = pairOf(position.wind)
    var bowed: array[Arm, float]
    for arm in Arm:
      # How far this reach leaves straight line between its own hands.
      let chord = @[pair[arm][0], pair[arm][^1]]
      for q in pair[arm]:
        bowed[arm] = max(bowed[arm], nearestOn(chord, q))
    if int(abs(position.wind) * 2) != 3:
      # Everything short of swan shares evenly, so neither reach is
      # straight one and pair stays symmetric.
      doAssert abs(bowed[Arm.L] - bowed[Arm.R]) < 1e-6,
        &"A pair short of a swan drew lopsided; got `{position.name}`."
      continue
    let
      straight = straightArm(position.wind)
      snake = other(straight)
    doAssert bowed[straight] < MARK_STROKE,
      &"A swan's straight connection is not straight; got " &
        &"`{decimal(bowed[straight], 1)}` of bow in `{position.name}`."
    # Wide enough to be going round straight one, and not so wide that
    # it has left figure altogether.  How wide within that is matter
    # of looks and was settled by looking (rules 33 to 35), so bounds
    # are only backstops -- what was actually wrong with swan was that
    # it was drawn with straight bits, which is checked below.
    let
      put = settled(posedAt(position.wind, HAND_PHASE), HAND_TO_HAND,
                    ABOVE_BOTH, default(Ways))
      apart = dist(put.place[Dancer.Lead], put.place[Dancer.Follow])
    doAssert bowed[snake] > DIAMOND_ROOM / 2,
      &"A swan's snake does not go round anything; got " &
        &"`{decimal(bowed[snake], 1)}` of bow in `{position.name}`."
    doAssert bowed[snake] < apart,
      &"A swan's snake bows clean out of the figure; got " &
        &"`{decimal(bowed[snake], 1)}` against `{decimal(apart, 1)}` in " &
        &"`{position.name}`."
    flattest = min(flattest, bowed[straight])
    snakiest = min(snakiest, bowed[snake])
    inc swans
  doAssert swans == 2, &"Two swans expected; got `{swans}`."

  # RULE 35.  `"make it smoother (a simpler curved, right now it looks`
  # `jagged/sharp)."`  Reach is held as points so it can morph, and drawn
  # as curves through them so it does not read as polygon it is stored
  # as -- everywhere, still and moving alike, since corner is corner
  # wherever it falls.
  var curved = 0
  for key, figure in built:
    for part in figure.split("<path "):
      if &"stroke-width=\"{LINK_W}\"" notin part:
        continue
      const opens = "d=\""
      let at = part.find(opens)
      if at < 0:
        continue
      let drawn = part[at + opens.len ..< part.find('"', at + opens.len)]
      # One straight tail closes each run, and nothing else may be one.
      doAssert drawn.count(" Q") > drawn.count(" L"),
        &"A reach is drawn as straight bits rather than curves; got " &
          &"`{key}`."
      inc curved
  told.add &"and every one of the {curved} reaches on the page is drawn as " &
    "curves through its own sampled points rather than as the polygon it " &
    "is stored as, so what turns hard reads as turning rather than as a " &
    "run of corners"

  # And crossing is drawn as crossing: reach that dives loses one
  # `BREAK` of its own length, and reach that dives twice loses two --
  # which is alternation, measured rather than assumed.
  for i, position in CHAIN:
    let
      figure = built[&"hh_{i}"]
      pair = pairOf(position.wind)
      on_top = overArm(position.wind)
    # Alternation that drawing uses, worked out rather than trusted:
    # with three crossings it is two dives on one arm and one on other.
    var cuts: array[Arm, seq[Point]]
    for k, meeting in crossingsOf(pair[Arm.L], pair[Arm.R]):
      cuts[if (k mod 2 == 0) == (on_top == Arm.L): Arm.R
           else: Arm.L].add meeting
    for arm in Arm:
      var ink = 0.0
      for shade in [DEEP[arm], INK[HAND_TO_HAND[arm].get]]:
        ink += inkOf(figure, shade)
      let
        whole = polylineLen(pair[arm])
        lost = whole - ink
        # What breaking this reach where it dives takes out of it: cut
        # drops whole sampled points, and one against end of reach
        # drops fewer, so length is worked out rather than counted.
        want_lost = whole - cutGapsAt(pair[arm], cuts[arm])
          .mapIt(polylineLen(it)).foldl(a + b, 0.0)
      doAssert abs(lost - want_lost) < 0.5,
        &"A reach is not drawn broken where it dives; got `{decimal(lost, 1)}` " &
          &"missing from {arm} for `{decimal(want_lost, 1)}` of breaking at " &
          &"`{cuts[arm].len}` dives in `{position.name}`."
  told.add &"the wind makes the crossings: none at the frame, one at a " &
    &"half turn -- the cross the partners make facing the same way -- and " &
    &"two at a whole one, one by each dancer, holding a diamond of " &
    &"{decimal(smallest, 0)} square units with its points {decimal(apart, 0)} apart"

  # RULE 28 again.  `"the animations are very jankey and tied to the final`
  # `visual representations."`  Nothing is told how far it has wound now, so
  # test is that drawing moves smoothly: no frame of any walk
  # shifts reach further than one step of turn itself would.
  var jump = 0.0
  for way in TurnWay:
    let w = WAYS_OF_TURNING[way]
    for i in 0 ..< CHAIN.len - 1:
      let walk = turnWalk(handPose(CHAIN[i].wind), w.who, w.about, HALF,
                          on = Anchor.Lead)
      for arm in Arm:
        let spun = continuous(walk.poses.mapIt(
          windOf(settled(it, HAND_TO_HAND, ABOVE_BOTH, default(Ways)),
                 HAND_TO_HAND, arm).spread))
        for k in 0 ..< spun.high:
          jump = max(jump, abs(spun[k + 1] - spun[k]))
  doAssert jump < HALF / 4,
    &"A walk's wind jumps between frames; got `{decimal(jump, 0)}` degrees."
  told.add &"and the wind is read off the drawing rather than handed to " &
    &"it: through every frame of every walk it never moves more than " &
    &"{decimal(jump, 0)} degrees at a step, so nothing snaps"

  # RULE 19, RULE 28 and RULE 32.  Which ways of turning walk chain:
  # all of them, now that orbit faces centre and so turns walker
  # relative to their partner.  Half turn is half turn however danced,
  # which is whole of rule 32's reason.
  var winders: seq[string]
  for way in TurnWay:
    let
      w = WAYS_OF_TURNING[way]
      landed = canonicalise(turned(handPose(), w.who, w.about, HALF),
                            on = Anchor.Lead)
      put = settled(landed, HAND_TO_HAND, ABOVE_BOTH, default(Ways))
      spun = windOf(put, HAND_TO_HAND, Arm.L).spread
    # Half turn of wind, whichever way round it went.
    doAssert abs(abs(wrap180(spun)) - HALF) < 1e-6,
      &"A way of turning did not wind a half turn; got " &
        &"`{decimal(spun, 1)}` for {way}."
    winders.add w.title.toLowerAscii
  # No count assert: `winders` gains one entry per way unconditionally, so
  # counting it against `TurnWay` could never fail.  doAssert in
  # loop is check -- way that does not wind stops build there.
  told.add &"all {winders.len} ways wind the pair a half turn and so walk " &
    "the chain, orbits as much as axis turns -- because an orbit that keeps " &
    "its side to the centre turns the walker relative to their partner, " &
    "which is what lets the ways be equated at all"

  # RULE 29.  `"the animations don't have the proper breaks that the static`
  # `images do ... they end up on the wrong z order."`  Moving reach cannot
  # be cut into runs, so it wears its break as dash -- and what is
  # measured here is that dash is really there, on right arm, at
  # right place, on every frame.
  func gapsIn(figure, shade: string): seq[seq[tuple[opens, shuts: float]]] =
    ## Where breaks fall along one shade of one connection, frame by
    ## frame, read back off dash pattern that drawing wrote.
    ##   Read as places rather than counted, because break that lands on
    ##     join between two shades is drawn as piece of each and
    ##     is one break, not two.
    for part in figure.split("<path "):
      if &"stroke=\"{shade}\"" notin part:
        continue
      const opens = "attributeName=\"stroke-dasharray\" values=\""
      let at = part.find(opens)
      if at < 0:
        continue
      let
        listed = part[at + opens.len ..< part.find('"', at + opens.len)]
        frames: seq[string] = listed.split(';')
      for frame in frames:
        # Run, gap, run, gap, rest -- with first run written one gap
        # longer and whole pattern started one gap in, so first run
        # is difference of those two.
        let says: seq[string] = frame.split(' ')
        var
          lens = @[parseFloat(says[0]) - parseFloat(says[1])]
          here: seq[tuple[opens, shuts: float]]
          along = 0.0
        for k in 1 ..< says.high:
          lens.add parseFloat(says[k])
        for k, run in lens:
          if k mod 2 == 1 and run > 0:
            here.add (along, along + run)
          along += run
        result.add here

  var gaps = 0
  for way in TurnWay:
    let w = WAYS_OF_TURNING[way]
    for edge in 0 ..< CHAIN.len - 1:
      let
        figure = built[&"hw_{w.tag}_{edge}"]
        walk = turnWalk(handPose(CHAIN[edge].wind), w.who, w.about,
                        HALF * windSense(way), on = Anchor.Lead)
        put = walk.poses.mapIt(settled(it, HAND_TO_HAND, ABOVE_BOTH,
                                       default(Ways)))
      var shades: array[Arm, array[2, seq[seq[tuple[opens, shuts: float]]]]]
      for arm in Arm:
        for k, shade in [DEEP[arm], INK[HAND_TO_HAND[arm].get]]:
          shades[arm][k] = gapsIn(figure, shade)
          doAssert shades[arm][k].len == walk.poses.len,
            &"A break does not run the whole move; got " &
              &"`{shades[arm][k].len}` of `{walk.poses.len}` in {way}."
      # Every crossing broken exactly once, frame by frame, and broken on
      # arm that alternation names: crossing with none or with two is
      # picture that does not say which connection is on top.
      var first_cuts: array[Arm, seq[Point]]
      for i in 0 ..< put.len:
        var
          routes: array[Arm, seq[Point]]
          spun: array[Arm, float]
        for arm in Arm:
          let
            seen = continuous(put.mapIt(windOf(it, HAND_TO_HAND, arm).spread))
            hands = handsOf(put[i])
          spun[arm] = seen[i] + 360 * CHAIN[edge].wind - seen[0]
          routes[arm] = wound(hands[Dancer.Lead][arm],
                              hands[Dancer.Follow][HAND_TO_HAND[arm].get],
                              axisOf(put[i]).across,
                              degToRad(windOf(put[i], HAND_TO_HAND, arm).phi),
                              degToRad(spun[arm]),
                              share = windShare(spun[arm] / 360, arm))
        let
          meetings = crossingsOf(routes[Arm.L], routes[Arm.R])
          # Drawing reads wind off Left connection to name
          # which is on top, so check has to read it off same one.
          on_top = overArm(spun[Arm.L])
        for arm in Arm:
          let
            middle = routes[arm].len div 2
            deep = polylineLen(routes[arm][0 .. middle])
          # Every break that drawing wrote, put into one measure along
          # whole reach: light shade's own distances run on from where
          # deep one leaves off.
          var marks: seq[tuple[opens, shuts: float]]
          for k in 0 .. 1:
            for mark in shades[arm][k][i]:
              let along = if k == 1: deep else: 0.0
              marks.add (mark.opens + along, mark.shuts + along)
          # And where this reach dives, in same measure: crossings
          # in order, diving arm alternating from first.
          var dips: seq[float]
          for k, meeting in meetings:
            let under = if (k mod 2 == 0) == (on_top == Arm.L): Arm.R
                        else: Arm.L
            if under == arm:
              dips.add alongAt(routes[arm], meeting)
          # Each dive wears one break, and no break is worn anywhere else --
          # which together are what crossing being drawn as crossing
          # means, however break happened to fall across two
          # shades (rules 29, 31).
          for at in dips:
            doAssert marks.anyIt(at >= it.opens - 1 and at <= it.shuts + 1),
              &"A crossing is drawn without a break; got a dive at " &
                &"`{decimal(at, 1)}` on {arm} outside every break in {way} " &
                &"edge {edge} frame {i}."
          for mark in marks:
            doAssert dips.anyIt(it >= mark.opens - BREAK and
                                it <= mark.shuts + BREAK),
              &"A break is drawn without a crossing; got one at " &
                &"`{decimal(mark.opens, 1)}` on {arm} in {way} edge {edge} " &
                &"frame {i}."
          gaps += dips.len
          if i == 0:
            for k, meeting in meetings:
              let under = if (k mod 2 == 0) == (on_top == Arm.L): Arm.R
                          else: Arm.L
              if under == arm:
                first_cuts[arm].add meeting
      # And arm it breaks is arm its still breaks, and as many
      # times -- which is disagreement this rule was given for.
      # Measured as length lost, so break that lands where two
      # shades meet is still seen.
      let still = built[&"hw_{w.tag}_{edge}_still"]
      for arm in Arm:
        var ink = 0.0
        for shade in [DEEP[arm], INK[HAND_TO_HAND[arm].get]]:
          ink += inkOf(still, shade)
        let
          settled_pair = pairOf(CHAIN[edge].wind)[arm]
          whole = polylineLen(settled_pair)
          # What its still would lose if it were cut where move's own
          # first frame dives: same arm, same places, same
          # length gone.
          want_lost = whole - cutGapsAt(settled_pair, first_cuts[arm])
            .mapIt(polylineLen(it)).foldl(a + b, 0.0)
        doAssert abs(whole - ink - want_lost) < 0.5,
          &"The moving figure breaks a different arm from its still, or in " &
            &"different places; got `{decimal(whole - ink, 1)}` missing from " &
            &"the still for `{decimal(want_lost, 1)}` of the move's " &
            &"`{first_cuts[arm].len}` dives on {arm} in {way} edge {edge}."
  told.add &"a moving reach carries the break a still one does: {gaps} of " &
    "them drawn across the page, one at every crossing on every frame, on " &
    "the same arm the still breaks -- worn as a dash, since a reach cut " &
    "into pieces could not be morphed at all"

  # RULE 30 and RULE 31.  `"the boxes/diamonds are the ends of the turn chain`
  # `... that double box is not allowed"`, and then `"hand to hand actually has`
  # `an extra half turn on both ends"`.  Rule was that chain has ends
  # and they hold, never that ends sit at whole turn: they are
  # swans now, so no frame of any animation may be found past turn and
  # half -- and every edge has to walk chain rather than off side of
  # it.  What rule 30 refused, double box, is refused by swan being
  # drawn as swan, which is asserted above.
  var
    winding = 0
    reach = 0.0
  for way in TurnWay:
    let w = WAYS_OF_TURNING[way]
    var winds_at_all = false
    for edge in 0 ..< CHAIN.len - 1:
      let
        walk = turnWalk(handPose(CHAIN[edge].wind), w.who, w.about,
                        HALF * windSense(way), on = Anchor.Lead)
        put = walk.poses.mapIt(settled(it, HAND_TO_HAND, ABOVE_BOTH,
                                       default(Ways)))
      for arm in Arm:
        let
          seen = continuous(put.mapIt(windOf(it, HAND_TO_HAND, arm).spread))
          spun = seen.mapIt(it + 360 * CHAIN[edge].wind - seen[0])
        # Rule itself: nowhere past end of chain, on any frame.
        for i, turned_by in spun:
          doAssert abs(turned_by) < 360 * abs(STEPS[^1]) + 1e-6,
            &"An animation winds past the end of the chain; got " &
              &"`{decimal(turned_by / 360, 2)}` turns at frame `{i}` of " &
              &"{way} edge {edge}."
        # And it starts and turns where chain says, so edges are
        # chain: out to next position along, and back as it came.
        doAssert abs(spun[0] - 360 * CHAIN[edge].wind) < 1e-6 and
            abs(spun[^1] - 360 * CHAIN[edge].wind) < 1e-6,
          &"An edge does not start and end on its own position; got " &
            &"`{decimal(spun[0] / 360, 2)}` to `{decimal(spun[^1] / 360, 2)}` in " &
            &"{way} edge {edge}."
        let far = spun[spun.mapIt(abs(it)).maxIndex]
        if abs(abs(far) - abs(360 * CHAIN[edge].wind)) > 1e-6:
          winds_at_all = true
          doAssert abs(far - 360 * CHAIN[edge + 1].wind) < 1e-6,
            &"An edge turns away from the next position instead of " &
              &"towards it; got `{decimal(far / 360, 2)}` for " &
              &"`{CHAIN[edge + 1].name}` in {way} edge {edge}."
        reach = max(reach, abs(far))
      # And it really travels, or sense that was measured for it has
      # quietly frozen it in place.
      doAssert walk.poses.anyIt(
          it.place[Dancer.Follow] != walk.poses[0].place[Dancer.Follow] or
          it.facing[Dancer.Follow] != walk.poses[0].facing[Dancer.Follow]),
        &"A transition does not move at all; got {way} edge {edge}."
    if winds_at_all:
      inc winding
  told.add &"the chain has ends and they hold: {winding} of " &
    &"{TurnWay.toSeq.len} ways wind, every edge rocks out to the next " &
    &"position along and back, and nothing anywhere is drawn past " &
    &"{decimal(reach / 360, 2)} of a turn -- the swans, which are the ends"
  told.add &"and the two patterns are one chain read half a turn apart: " &
    &"hand to hand runs parallel with the partners facing one another, " &
    &"measured at a phase of {decimal(HAND_PHASE, 2)} of a turn, and its " &
    &"{CHAIN.len} positions step by halves from there to a turn and a half " &
    &"each way, where one connection runs straight to within " &
    &"{decimal(flattest, 2)} and the other snakes {decimal(snakiest, 0)} round it"

  # RULE 17, RULE 21 and RULE 33.  Above on every hand, still and moving
  # alike -- and moving hand's hatch stays where it is in mark, which
  # it does by mark being carried rather than animating its own place.
  var
    hatched = 0
    hatch_still = 0
  for key, figure in built:
    if not (key.startsWith("hh_") or key.startsWith("hw_")):
      continue
    doAssert "r=\"2.7\"" notin figure,
      &"A high dot appears where above was asked for; got `{key}`."
    doAssert "url(#h" in figure,
      &"A hand lost its level; got no hatch in `{key}`."
    for part in figure.split('<'):
      if "url(#h" notin part:
        continue
      doAssert "/>" in part,
        &"A hatched mark animates its own place, so its hatch will swim; " &
          &"got `{key}`."
      inc hatch_still
    inc hatched
  told.add &"every hand on all {hatched} figures carries the above hatch, " &
    &"moving and still alike, and every one of the {hatch_still} marks " &
    "holds its hatch still inside its own outline while it travels"

  for line in told:
    echo &"  rule: {line}"



#[ Turn Sign ]#

proc checkSign*() =
  ## Check numbers eye cannot: equal sides, margins, gaps,
  ## clearance.
  let
    y_foot = PAD + OVER
    y_bot = y_foot + HEIGHT
  for rows in 1 .. QUARTERS:
    var
      sides: HashSet[float]
      margins: HashSet[float]
      clear: HashSet[float]
      gaps: seq[float]
      edges: seq[tuple[top, bottom: float]]
    for place in 0 ..< rows:
      let
        top = y_bot - GAP_X - float(place) * (PIP + GAP_X) - PIP +
          (PIP - PIP * LEAN_COS) / 2
        left = PAD + (y_bot - top) * TAN
        ax = left + GAP_X
        pts: array[4, Point] = [
          (ax, top), (ax + PIP, top),
          (ax + PIP - PIP * LEAN_SIN, top + PIP * LEAN_COS),
          (ax - PIP * LEAN_SIN, top + PIP * LEAN_COS)]
      for i in 0 .. 3:
        let
          p = pts[i]
          q = pts[(i + 1) mod 4]
        sides.incl round(hypot(q.x - p.x, q.y - p.y), 3)
      let bottom_left = PAD + (y_bot - (top + PIP * LEAN_COS)) * TAN
      margins.incl round(pts[0].x - left, 3)
      margins.incl round(pts[3].x - bottom_left, 3)
      margins.incl round(left + SIGN_BODY - (pts[1].x + PIP + GAP_X), 3)
      # Circle has no corners to tuck under lean, so its clearance is
      # measured square to edge rather than across page.
      for col in [0.0, 1.0]:
        let across = GAP_X + col * (PIP + GAP_X) + PIP / 2
        clear.incl round(
          min(across, SIGN_BODY - across) * LEAN_COS - PIP / 2, 3)
      edges.add (y_bot - GAP_X - float(place) * (PIP + GAP_X) - PIP,
                 y_bot - GAP_X - float(place) * (PIP + GAP_X))
    edges.sort
    gaps.add round(edges[0].top - y_foot, 3)             # to lid
    for i in 0 ..< edges.high:
      gaps.add round(edges[i + 1].top - edges[i].bottom, 3)
    gaps.add round(y_bot - edges[^1].bottom, 3)          # to foot
    doAssert sides == toHashSet([PIP]), &"Uneven pip sides; got `{sides}`."
    doAssert margins == toHashSet([GAP_X]),
      &"Uneven margins; got `{margins}`."
    doAssert clear.toSeq.min > 0, &"A circle touches the lean; got `{clear}`."
    doAssert gaps[1 .. ^1].toHashSet == toHashSet([GAP_X]),
      &"Uneven gaps; got `{gaps}`."
    if rows == QUARTERS:
      doAssert gaps[0] == GAP_X, &"The lid gap is off; got `{gaps[0]}`."
    let
      sides_said = sides.toSeq.sorted.mapIt($it).join(", ")
      margins_said = margins.toSeq.sorted.mapIt($it).join(", ")
      gaps_said = gaps.mapIt($it).join(", ")
      clear_said = clear.toSeq.sorted.mapIt($it).join(", ")
    echo &"  {rows}/4: sides [{sides_said}] margins [{margins_said}] " &
      &"gaps [{gaps_said}] circle clearance [{clear_said}]"
