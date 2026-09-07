## Draw whole picture: two dancers, their connections, and how it moves.
##
##   Static figure is drawn from canonical pose.  Animated one samples
##     cycle of poses on one clock -- bodies carried rigidly by
##     transforms, reach re-routed each frame with one way round settled
##     for whole move -- so everything stays in one piece.
##     Cost of sampling: animation is as smooth as its samples, and every
##       sample is full routing.  Accepted -- routes are built once,
##       into markup, not per frame in browser.
##   State that rules say does not exist is refused, not drawn: `partsOf`
##     asserts `danceable`, so build fails rather than publishing wrap
##     that does not wrap (rule 7).
##     Cost of refusing at build time: page asking for impossible state
##       dies with assertion rather than showing gap.  Accepted --
##       gap is author's decision to make, not drawing's.

{.experimental: "strictFuncs".}

import std/[algorithm, math, options, sequtils, strformat, strutils]

import ./[body, geometry, pose, route, style, terms]


const
  WIDE = 160.0     ## Box picture with captions needs.
  SIZE = 116.0     ## And box it needs without them.

type Twists* = array[Arm, float]
  ## How far each connection has wound, in turns: what reach swings
  ## through (rules 27, 28).  Zero draws straight, half draws cross,
  ## whole draws diamond, one and one-half draws swan.
  ##   It once carried two more channels -- pigtail at lone reach's
  ##     middle and braid across pair -- which retired rotation page
  ##     owned.  Rule 16 took pigtail away, having no ceiling left for
  ##     it to mark, and rule 28's measured winding replaced braid with
  ##     geometry.  Neither has had caller since.

const NO_TWIST*: Twists = [0.0, 0.0]
  ## Nothing wound: every figure but turn pages'.



#[ Still Figure ]#

func twoTone*(runs: seq[Run]; mid: Point; lead_side, follow_side: Arm):
    seq[string] =
  ## Draw one reach in its two hands' own colours, meeting at its middle
  ## point (rule 9).
  ##   Each half is exactly mark it ends on: lead's in their arm's
  ##     ink and deep shade, follow's in theirs and plain one.
  ##   So line draws pair of colours that names which hands are joined,
  ##     instead of leaving it to two marks that go too small to read; and
  ##     shade still says which end is whose when both hands share one hue.
  let (near, far) = splitAt(runs, mid)
  @[reachMarkup(near, DEEP[lead_side]), reachMarkup(far, INK[follow_side])]


func ghosts*(holds: Holds; levels: Levels; ways: Ways):
    seq[tuple[who: Dancer, arm: Arm]] =
  ## List every hand that is not where its arm hangs.
  for arm in Arm:
    if holds[arm].isNone:
      continue
    let held = [(Dancer.Lead, arm), (Dancer.Follow, holds[arm].get)]
    for (who, own) in held:
      if slotOf(own, levels[arm], ways[arm]) != (own, Slot.Default):
        result.add (who, own)


func settled*(pose: Pose; holds: Holds; levels: Levels; ways: Ways): Pose =
  ## Get same pose with every hand put in slot its hold settles it
  ## in.
  ##   There is nothing to solve: settled hand is in one of six places, and
  ##     which one is decided by its own side and by level and way of
  ##     hold it is part of (rules 2 to 6).
  ##   Hand that is free, or held by hold that has not said both, stays
  ##     where arm hangs.  Hands still move smoothly between slots when
  ##     picture moves; it is settled state that is discrete.
  var wind: Winds
  for arm in Arm:
    if holds[arm].isNone:
      continue
    wind[Dancer.Lead][arm] = settledWind(arm, levels[arm], ways[arm])
    let own = holds[arm].get
    wind[Dancer.Follow][own] = settledWind(own, levels[arm], ways[arm])
  result = pose
  result.wind = wind


func bodiesOf(pose: Pose): tuple[lead, follow: route.Body] =
  ## See couple as routing does.
  ((pose.place[Dancer.Lead], pose.facing[Dancer.Lead]),
   (pose.place[Dancer.Follow], pose.facing[Dancer.Follow]))


func danceable*(pose: Pose; holds: Holds;
    levels: Levels = default(Levels); ways: Ways = default(Ways)): bool =
  ## Test whether every lock and wrap in this hold really is one (rule 7).
  ##   Lock or wrap position may only be used when line goes round no
  ##     less than just under half circumference -- it does not mean
  ##     anything to have wrap without line actually going round
  ##     body.  So whether state exists at all depends on orientation,
  ##     and this is what says so.
  let
    put = settled(pose, holds, levels, ways)
    p = handsOf(put)
    (lead_body, follow_body) = bodiesOf(put)
  for arm in Arm:
    if holds[arm].isNone:
      continue
    if roundOf(levels[arm], ways[arm]).isNone:
      continue                     # nothing claimed, nothing to hold up
    let ends: route.Ends = (p[Dancer.Lead][arm],
                            p[Dancer.Follow][holds[arm].get],
                            lead_body, follow_body)
    if not wrapsEnough(ends, levels[arm], ways[arm]):
      return false
  true


func clearingMarks*(put: Pose; a, b: Point): seq[Mark] =
  ## List what settled reach between these two hands has to keep out of
  ## (rule 22).
  ##   Every hand mark but two it joins -- line through one says that
  ##     hand is held -- and both chevrons, which line through hides.
  ##   Each clearance is what that mark actually reaches, so daylight is
  ##     seen and not guessed; and this is sole list, read by drawing
  ##     and by check that measures it.
  ##   Hand is one disc, because hand's mark is compact.  Chevron is
  ##     thin V, so it is string of small discs walked along its own two
  ##     legs -- single disc over whole of it would cover middle
  ##     of body and push every reach outside it.
  let p = handsOf(put)
  for who in Dancer:
    let drawn = chevronPoints(put.place[who], put.facing[who])
    for leg in 0 .. 1:
      for step in 0 .. CHEVRON_STEPS:
        let part = float(step) / float(CHEVRON_STEPS)
        result.add ((drawn[leg].x + (drawn[leg + 1].x - drawn[leg].x) * part,
                     drawn[leg].y + (drawn[leg + 1].y - drawn[leg].y) * part),
                    CHEVRON_CLEAR)
    for side in Arm:
      let q = p[who][side]
      if min(dist(q, a), dist(q, b)) > 0.01:
        result.add (q, (if who == Dancer.Lead: LEAD_CLEAR else: FOLLOW_CLEAR))


func axisOf*(put: Pose): tuple[along, across: Point, bearing: float] =
  ## Get pair's own axis: way from lead to follow, way
  ## square to it, and bearing of first.
  let
    lead = put.place[Dancer.Lead]
    follow = put.place[Dancer.Follow]
    span = max(dist(lead, follow), 1e-9)
    along: Point = ((follow.x - lead.x) / span, (follow.y - lead.y) / span)
  (along, (-along.y, along.x), bearing(follow.x - lead.x, follow.y - lead.y))


func windOf*(put: Pose; holds: Holds; arm: Arm): tuple[phi, spread: float] =
  ## Measure how far one connection has wound, in degrees (rules 27, 28).
  ##   Each held hand sits on its own body's rim, and both bodies stand on
  ##     pair's axis, so angle hand makes with that axis is what
  ##     going round means here.  Where two ends make same angle,
  ##     pair is unwound; difference between them is wind.
  ##   Measured, never handed in: drawing told how far it has wound can
  ##     be told wrong, and has been twice: orbit that keeps its bearing
  ##     turns nobody and so winds nothing (rule 28), and orbit that
  ##     keeps its side to centre winds as far as it carries (rule 32).
  ##     Measuring survived both answers without being touched.
  let
    axis = axisOf(put)
    p = handsOf(put)
    a = p[Dancer.Lead][arm]
    b = p[Dancer.Follow][holds[arm].get]
    phi_a = bearing(a.x - put.place[Dancer.Lead].x,
                    a.y - put.place[Dancer.Lead].y) - axis.bearing
    phi_b = bearing(b.x - put.place[Dancer.Follow].x,
                    b.y - put.place[Dancer.Follow].y) - axis.bearing
  (phi_a, wrap180(phi_b - phi_a))


func divePlace*(pts: seq[Point]; meeting: Point): float =
  ## Say how far along reach its break for this crossing is centred.
  ##   Slid clear of both ends exactly as still reach's gap is
  ##     (`gapFor`), so moving figure breaks where its still breaks and
  ##     crossing near hand is still covered.
  let gap = gapFor(alongAt(pts, meeting), polylineLen(pts))
  (gap.opens + gap.shuts) / 2


func divesOf*(one, other: seq[Point]; turns: float): array[Arm, seq[Point]] =
  ## Share crossings of two wound reaches out: say which of them dives at
  ## each one.
  ##   Arm on top at first crossing stays on top there, so it is other one
  ##     that dives, and they swap at every crossing after -- which is what
  ##     makes diamond into twist and not overlap (rule 27).
  ##   Drawing and checks both ask here, so neither can hold its own idea
  ##     of which arm goes under where.
  let on_top = overArm(turns)
  for i, meeting in crossingsOf(one, other):
    let under = if (i mod 2 == 0) == (on_top == Arm.L): Arm.R else: Arm.L
    result[under].add meeting


func partsOf*(pose: Pose; holds: Holds; levels: Levels = default(Levels);
    over = none(Arm); free = Free.Fade; captions = true;
    ways: Ways = default(Ways); twist: Twists = NO_TWIST;
    clear_marks = false): seq[string] =
  ## Draw every element of one pose, in order picture is read from.
  ##   `clear_marks` asks straight reach to bend round marks it does
  ##     not join (rule 22).  It is off by default so that only pages
  ##     that have been looked at under rule take it: frame page's
  ##     straight and wrapping reaches are next piece of that work, and
  ##     this flag is where it will be turned on for them.
  # Lock or wrap that does not go round body is not one, and state
  # that cannot be danced is edge that is not drawn -- so this refuses
  # rather than drawing something rules say does not exist.
  doAssert danceable(pose, holds, levels, ways),
    &"Undanceable state asked for; got `{holds}` at `{levels}`, `{ways}`."
  # Every drawing path comes through here, so this is where hands are
  # put: pose handed in ready-made is settled exactly like one built below.
  let
    put = settled(pose, holds, levels, ways)
    p = handsOf(put)
    (lead_body, follow_body) = bodiesOf(put)

  var bits = @[ringOf(put), border(put, Dancer.Lead),
               border(put, Dancer.Follow)]
  for who in Dancer:
    bits.add chevron(put.place[who], put.facing[who])
  # Where each displaced hand came from, as grey outline of its own mark.
  # `back` carries locks, so hand no longer says by where it sits how far
  # it has been taken -- ghost of place it left says it instead, and
  # hand still at home has no ghost to confuse it with.
  for (who, arm) in ghosts(holds, levels, ways):
    let q = handPoint(put.place[who], put.facing[who], arm)
    bits.add hand(q.x, q.y, who == Dancer.Lead, arm, held = false,
                  free = Free.Grey)
  # Wound pair crosses: once by half turn, twice by whole one, with
  # cross or diamond that makes (rules 27, 28).
  let winding = holds[Arm.L].isSome and holds[Arm.R].isSome and
    abs(twist[Arm.L]) > 1e-9
  # And wound pair says which way it wound by which arm it keeps on top,
  # so wind names over-arm rather than caller saying it twice.
  let on_top = if not winding: over else: some(overArm(twist[Arm.L]))
  var routes: array[Arm, seq[Point]]
  for arm in Arm:
    if holds[arm].isNone:
      continue
    let ends: route.Ends = (p[Dancer.Lead][arm],
                            p[Dancer.Follow][holds[arm].get],
                            lead_body, follow_body)
    if levels[arm] == some(Level.Above):
      # Over head: nothing is in way from above, and wind is
      # said by crossing rather than by hugging (rules 1 and 14).
      routes[arm] =
        if winding:
          # Pose says where hands are and which way arm went
          # round; wind says how far.  Half turn's sweep is pose's
          # own -- hands really have swapped sides -- and whole turn's
          # is full round on top of it.
          wound(ends.a, ends.b, axisOf(put).across,
                degToRad(windOf(put, holds, arm).phi),
                2 * PI * twist[arm], share = windShare(twist[arm], arm))
        elif clear_marks:
          clearedReach(ends.a, ends.b, clearingMarks(put, ends.a, ends.b))
        else:
          straightReach(ends.a, ends.b)
    else:
      # What hold says, if it says anything; short way if not.
      routes[arm] = routed(ends, wayFor(ends, levels[arm], ways[arm])).get.pts
  # Wound pair meets more than once, and rope alternates: each strand
  # dives under at every second crossing.  So crossings are found once,
  # in order along line, and shared out between two arms.
  var dives: array[Arm, seq[Point]]
  if winding:
    dives = divesOf(routes[Arm.L], routes[Arm.R], twist[Arm.L])

  let order = if on_top == some(Arm.L): [Arm.R, Arm.L] else: [Arm.L, Arm.R]
  for arm in order:
    if holds[arm].isSome:
      let
        pts = routes[arm]
        runs =
          if winding: cutGapsAt(pts, dives[arm])
          elif on_top == some(other(arm)): cutGap(pts, routes[other(arm)])
          else: @[pts]
      bits.add twoTone(runs, pts[pts.len div 2], arm, holds[arm].get)
  for arm in Arm:
    let q = p[Dancer.Lead][arm]
    bits.add hand(q.x, q.y, leads = true, arm = arm,
                  held = holds[arm].isSome, level = levels[arm], free = free)
  for own in [Arm.R, Arm.L]:
    let
      q = p[Dancer.Follow][own]
      by = Arm.toSeq.filterIt(holds[it] == some(own))
      level = if by.len > 0: levels[by[0]] else: none(Level)
    bits.add hand(q.x, q.y, leads = false, arm = own, held = by.len > 0,
                  level = level, free = free)
  if captions:
    for arm in Arm:
      bits.add caption(put.place[Dancer.Lead], put.facing[Dancer.Lead], arm,
                       (if arm == Arm.L: "Left" else: "Right"),
                       put.wind[Dancer.Lead][arm], DEEP[arm])
    for own in [Arm.R, Arm.L]:
      bits.add caption(put.place[Dancer.Follow], put.facing[Dancer.Follow],
                       own, handName(own), put.wind[Dancer.Follow][own],
                       INK[own])
  bits.filterIt(it.len > 0)


func extent*(pose: Pose; captions = true): float =
  ## Measure how far this pose reaches from origin, ring and captions
  ## included.
  let edge = if captions: CAPTION_R + 20 else: BODY_R + HAND_R + 2
  for who in Dancer:
    result = max(result, hypot(pose.place[who].x, pose.place[who].y) + edge)
  if pose.ring.isSome:
    let (centre, radius) = pose.ring.get
    result = max(result, hypot(centre.x, centre.y) + radius + 4)


func view*(half: float): string =
  ## Write square viewBox figure fills.
  &"""viewBox="{n(-half)} {n(-half)} {n(2 * half)} {n(2 * half)}""""


func renderFigure*(classes: string; holds: Holds;
    levels: Levels = default(Levels); over = none(Arm); lead_turn = 0.0;
    follow_turn = 0.0; free = Free.Fade; captions = true; pose = none(Pose);
    half = none(float); ways: Ways = default(Ways); twist: Twists = NO_TWIST;
    clear_marks = false): string =
  ## Draw one picture, canonical unless pose is handed in already turned.
  let
    drawn = if pose.isSome: pose.get
            else: canonicalise(spinAbout(
              spinAbout(rest(), Dancer.Lead, lead_turn),
              Dancer.Follow, follow_turn))
    box = if half.isSome: half.get
          else: (if captions: WIDE else: SIZE) / 2
    bits = partsOf(
      drawn,
      holds,
      levels = levels,
      over = over,
      free = free,
      captions = captions,
      ways = ways,
      twist = twist,
      clear_marks = clear_marks,
    )
  &"""<svg class="{classes}" {view(box)}>""" & "\n        " &
    bits.join("\n        ") & "\n      </svg>"



#[ Animated Figure ]#

func series*(steps: seq[float]): string =
  ## Say one animated value's frames on one clock.
  steps.mapIt(n(it)).join(";")

func series*(steps: seq[string]): string =
  ## Say one animated pair's frames on one clock, already written out.
  steps.join(";")


func beat*(t: float): string =
  ## Write one moment of animation's clock, finely enough to keep
  ## frames in order.
  ##   Not `n`, which writes tenths: whole move is one unit long here, so
  ##     one tenth would collapse whole stages of it into same instant.
  let written = formatFloat(t, ffDecimal, 4)
  result = written.strip(leading = false, chars = {'0'})
                  .strip(leading = false, chars = {'.'})
  if result.len == 0:
    result = "0"


func keyed*(times: seq[float]; count: int): string =
  ## Say when each frame of animation is due, where they are not evenly
  ## spread (rule 26).
  ##   Evenly spread is what browser assumes, so nothing is written for
  ##     it: move that spends its clock evenly says so by saying nothing,
  ##     and only move that ranks its stages carries extra attribute.
  if times.len != count or count < 2:
    return ""
  for i, t in times:
    if abs(t - float(i) / float(count - 1)) > 1e-9:
      return &""" keyTimes="{times.mapIt(beat(it)).join(";")}""""
  ""


func animate*(attr: string; steps: seq[float]; dur: float;
    times: seq[float] = @[]): string =
  ## Animate one attribute over cycle.
  &"""<animate attributeName="{attr}" values="{series(steps)}"""" &
    keyed(times, steps.len) &
    &""" dur="{dur}s" repeatCount="indefinite"/>"""


func paired*(markup, inner: string): string =
  ## Reopen self-closing element so it can carry its own animations.
  let tag = markup[1 ..< markup.find(' ')]
  markup[0 .. ^3] & ">" & inner & "</" & tag & ">"


const LONG_ENOUGH = 999.0
  ## Dash long enough to be rest of any reach on any page.

const GAPS_DRAWN = 2
  ## Breaks moving reach has room for, whether it uses them or not.
  ##   Two, because swan crosses three times and alternation puts two
  ##     of those on one connection (rule 31).  Every frame writes same
  ##     number of them, which is what lets pattern be animated at all.


func dashedAt*(pts: seq[Point]; dives: seq[float]; starts = 0.0):
    tuple[pattern, offset: string] =
  ## Say moving reach's break as dash pattern: how far it runs, how long
  ## break is, and then rest of it (rule 29).
  ##   Still reach is cut into runs where it dives under its partner, but
  ##     number of runs changes with number of crossings and path
  ##     that changes shape cannot be morphed between frames.  Dash puts
  ##     same break in same place and leaves path one piece.
  ##   Where this half of reach has no crossing in it, break is zero
  ##     long, which draws as no break at all -- so every frame says three
  ##     numbers whether it is broken or not, and nothing jumps.
  ##   Crossing that sits on join between two halves breaks both
  ##     of them, each by as much of gap as falls inside it, so
  ##     break slides across middle instead of hopping.
  ##   Which is why dive is given as how far along *whole* reach it
  ##     lies, with `starts` saying where this half begins: how near
  ##     crossing is in plane says nothing about where on line it
  ##     falls once line snakes back past itself (rule 31), and taking
  ##     nearness for position drew breaks where there was no crossing.
  ##   Pattern is written one gap longer than it needs and started one gap
  ##     in, which comes to same line and keeps first dash off
  ##     zero: zero-length dash under round cap is drawn as dot, and
  ##     break that begins at half's own start would leave one.
  ##   Room for `GAPS_DRAWN` of them, always written and mostly zero long:
  ##     swan crosses three times and alternation puts two of those on
  ##     one connection (rule 31), while frame has none at all, and
  ##     markup has to say same number of things either way.
  var runs = @[0.0]
  for i in 0 ..< pts.high:
    runs.add runs[^1] + dist(pts[i], pts[i + 1])
  # Where along this half each break falls, in order, so pattern reads
  # from one end to other.  Gap is centred on crossing and
  # clipped to this half's own ends, which is what lets it cross join
  # without flickering; crossing outside this half leaves nothing.
  var breaks: seq[tuple[opens, shuts: float]]
  for dive in dives:
    let
      opens = clamp(dive - starts - BREAK / 2, 0.0, runs[^1])
      shuts = clamp(dive - starts + BREAK / 2, 0.0, runs[^1])
    if shuts > opens:
      breaks.add (opens, shuts)
  breaks = breaks.sortedByIt(it.opens)
  # Run, gap, run, gap: one pair per break pattern has room for.
  var
    lens: seq[float]
    at = 0.0
  for k in 0 ..< GAPS_DRAWN:
    let
      gap = if k < breaks.len: max(breaks[k].shuts - breaks[k].opens, 0.0)
            else: 0.0
      # Break there is none of is parked one whole line past end, so
      # run before it is long rather than nothing: zero-length dash
      # under round cap is drawn as dot, and unused gap must leave
      # no mark at all.
      opens = if gap > 0: max(breaks[k].opens, at) else: at + LONG_ENOUGH
    lens.add opens - at
    lens.add gap
    at = opens + gap
  # Pattern is written one gap longer at front and started one gap in,
  # which comes to same line and keeps first dash off zero.
  var says = @[n(lens[0] + lens[1])]
  for k in 1 ..< lens.len:
    says.add n(lens[k])
  says.add n(LONG_ENOUGH)
  (says.join(" "), n(lens[1]))


func facings*(poses: seq[Pose]; who: Dancer): seq[float] =
  ## Get dancer's facing through cycle, continuous so it turns way
  ## it turned.
  ##   Wrapped angles step from 179 to -179 at half turn and are read as
  ##     most of one turn other way -- body spinning backwards while its
  ##     own hands, placed absolutely, travel right way.
  continuous(poses.mapIt(it.facing[who]))


func animatedPoses*(classes: string; holds: Holds; walk: seq[Pose];
    half = none(float); levels: Levels = default(Levels);
    ways: Ways = default(Ways); dur = 9.6;
    times: seq[float] = @[]; wound = 0.0): string =
  ## Draw one picture moving through walk of poses handed in.
  ##   Every moving figure comes through here, whether its walk is whole
  ##     move's cycle or one edge of state graph rocked back and forth.
  ##   `times` says when each frame is due, for move that ranks its own
  ##     stages (rule 26); without it frames are evenly spread, which
  ##     is what browser does anyway.
  ##   `wound` says how far pair was already wound at first frame.
  ##     What drawing can measure for itself is how far wind
  ##     *changes*, since whole turn puts every hand back where it was --
  ##     so whole turns already in hold are one thing walk has
  ##     to be told (rule 28).
  let
    poses = walk.mapIt(settled(it, holds, levels, ways))
    box = if half.isSome: half.get
          else: poses.mapIt(extent(it, captions = false)).max
    hands = poses.mapIt(handsOf(it))

  var bits: seq[string]
  # Ring is drawn only where one is happening.  Move nobody orbits in
  # has no ring at all, rather than ring of no radius: mark says
  # *somebody is going round somebody*, and mark that is always there,
  # invisible, says it of every move.
  if poses.anyIt(it.ring.isSome):
    var ring_cx, ring_cy, ring_r: seq[float]
    for p in poses:
      let ring = p.ring.get((centre: (0.0, 0.0), radius: 0.0))
      ring_cx.add ring.centre.x
      ring_cy.add ring.centre.y
      ring_r.add ring.radius
    bits.add paired(
      &"""<circle cx="0" cy="0" r="0" fill="none" stroke="{QUIET}"""" &
        """ stroke-width="1" stroke-dasharray="3 4"/>""",
      animate("cx", ring_cx, dur, times) & animate("cy", ring_cy, dur, times) &
        animate("r", ring_r, dur, times))

  # Body is rigid: only where it is and which way it faces ever change.  So
  # it is drawn once, at origin facing up, and carried about by pair of
  # transforms -- which is exact, and spares markup one boundary per frame.
  for who in Dancer:
    var still = rest()
    still.place[who] = (0.0, 0.0)
    still.facing[who] = 0.0
    still.wind[who] = poses[0].wind[who]
    let places = poses.mapIt(&"{n(it.place[who].x)} {n(it.place[who].y)}")
    bits.add "<g>" &
      """<animateTransform attributeName="transform" type="translate"""" &
      &""" values="{series(places)}"""" & keyed(times, poses.len) &
      &""" dur="{dur}s" repeatCount="indefinite"/>""" &
      """<animateTransform attributeName="transform" type="rotate"""" &
      &""" additive="sum" values="{series(facings(poses, who))}"""" &
      keyed(times, poses.len) &
      &""" dur="{dur}s" repeatCount="indefinite"/>""" &
      border(still, who) & chevron(still.place[who], still.facing[who]) &
      "</g>"

  # One reach per frame, every frame same number of points, and -- this
  # is whole of it -- **one way round both bodies for entire move**
  # (rule 1).  What browser draws between two sample frames is two
  # reaches blended point by point, so two neighbouring frames that disagree
  # about which side of body line passes are drawn, in between, as
  # line sweeping straight through that body.  Only `above` connection may
  # ever do that.  Settling way round once, before any frame is routed,
  # makes disagreement impossible rather than unlikely.  Halves are
  # split at fixed index, which even resampling makes middle of
  # line, so both shades morph as one shape.
  #
  # Both arms are routed before either is drawn, because crossing is
  # fact about two of them together and each has to know where it dives
  # under other (rule 29).
  var
    routes: array[Arm, seq[seq[Point]]]
    winds: array[Arm, seq[float]]
  for arm in Arm:
    if holds[arm].isNone:
      continue
    let site = holds[arm].get
    var frames: seq[route.Ends]
    for i, h in hands:
      frames.add (h[Dancer.Lead][arm], h[Dancer.Follow][site],
                  (poses[i].place[Dancer.Lead],
                   poses[i].facing[Dancer.Lead]),
                  (poses[i].place[Dancer.Follow],
                   poses[i].facing[Dancer.Follow]))
    if levels[arm] == some(Level.Above):
      # Over head: from above nothing is in way, and nothing hugs
      # (rules 1, 14).
      # Pair winds as it turns, and drawing follows rather than being
      # told (rule 28).  How far it has wound is measured on every frame
      # and read as one continuous turning, so reach that has gone right
      # round is not mistaken for one that has not moved -- and so nothing
      # jumps between two frames.
      if holds[other(arm)].isSome:
        let seen = continuous(poses.mapIt(windOf(it, holds, arm).spread))
        # Measured from where it started, and started from where
        # hold says: two together are whole of winding.
        winds[arm] = seen.mapIt(it + 360 * wound - seen[0])
        for i, f in frames:
          routes[arm].add wound(f.a, f.b, axisOf(poses[i]).across,
                                degToRad(windOf(poses[i], holds, arm).phi),
                                degToRad(winds[arm][i]),
                                share = windShare(winds[arm][i] / 360, arm))
      else:
        routes[arm] = frames.mapIt(straightReach(it.a, it.b))
    else:
      # Hold that says which way round says it for every frame at once:
      # slot is fixed relative to its facing, so direction is too.
      # Where it says nothing, one way is picked for whole move instead.
      let
        said = wayFor(frames[0], levels[arm], ways[arm])
        way = if said.isSome: said.get else: oneWayRound(frames)
      routes[arm] = frames.mapIt(routed(it, some(way)).get.pts)

  # Where pair crosses, one of them dives, and it is same one
  # still figure breaks: crossings in order along reach, diving
  # arm alternating from first, and first named by `overArm` -- same
  # answer still figure alternates from (rule 29).  Moving reach cannot be
  # cut into runs -- number of them would change from frame to frame and
  # path that changes shape
  # cannot morph -- so it keeps its one piece and wears break as dash.
  # Swan crosses three times, so arm can dive more than once and every
  # crossing is kept rather than only first (rule 31).
  # Kept as how far along its own reach each dive lies, not as where it is
  # on page: snake passes near its own line again further along.
  var dives: array[Arm, seq[seq[float]]]
  if holds[Arm.L].isSome and holds[Arm.R].isSome:
    for i in 0 ..< poses.len:
      var mine: array[Arm, seq[float]]
      let
        turned_by = if winds[Arm.L].len == poses.len: winds[Arm.L][i]
                    else: 0.0
        # In turns, since every other reader of wind counts them; `winds`
        # counts degrees.
        on_top = overArm(turned_by / 360)
      for k, meeting in crossingsOf(routes[Arm.L][i], routes[Arm.R][i]):
        let under = if (k mod 2 == 0) == (on_top == Arm.L): Arm.R else: Arm.L
        mine[under].add divePlace(routes[under][i], meeting)
      for arm in Arm:
        dives[arm].add mine[arm]

  for arm in Arm:
    if holds[arm].isNone:
      continue
    let
      site = holds[arm].get
      middle = routes[arm][0].len div 2
    for (ink, lo, hi) in [(DEEP[arm], 0, middle), (INK[site], middle,
                          routes[arm][0].high)]:
      var
        paths: seq[string]
        dashes, offsets: seq[string]
      for i, pts in routes[arm]:
        let part = pts[lo .. hi]
        paths.add smoothed(part)
        if dives[arm].len == poses.len:
          let dashed = dashedAt(part, dives[arm][i],
                                starts = polylineLen(pts[0 .. lo]))
          dashes.add dashed.pattern
          offsets.add dashed.offset
      bits.add paired(
        &"""<path d="{paths[0]}" fill="none" stroke="{ink}"""" &
          (if dashes.len == 0: ""
           else: &""" stroke-dasharray="{dashes[0]}"""" &
             &""" stroke-dashoffset="{offsets[0]}"""") &
          &""" stroke-width="{LINK_W}" stroke-linecap="round"""" &
          """ stroke-linejoin="round"/>""",
        &"""<animate attributeName="d" values="{series(paths)}"""" &
          keyed(times, poses.len) &
          &""" dur="{dur}s" repeatCount="indefinite"/>""" &
          (if dashes.len == 0: ""
           else: &"""<animate attributeName="stroke-dasharray"""" &
             &""" values="{dashes.join(";")}"""" & keyed(times, poses.len) &
             &""" dur="{dur}s" repeatCount="indefinite"/>""" &
             &"""<animate attributeName="stroke-dashoffset"""" &
             &""" values="{offsets.join(";")}"""" & keyed(times, poses.len) &
             &""" dur="{dur}s" repeatCount="indefinite"/>"""))

  # Moving hand says its level, as still one does (rule 21) -- and it
  # has to say it same way throughout.
  #   So hand is drawn once at origin and *carried* by transform,
  #     exactly as body is, rather than animating its own coordinates.
  #     `above` hatch is pattern anchored to user space, so mark
  #     that slides through user space slides across hatch that stands
  #     still, and fill swims about inside its own outline.  Carried by
  #     transform, hatch is carried with it and holds its place.
  #   It also lets mark keep its own dot rather than having one
  #     animated alongside it: group can hold two elements where
  #     `paired` reopens one.
  func carried(mark: string; pts: seq[Point]): string =
    let places = pts.mapIt(xy(it))
    "<g>" &
      """<animateTransform attributeName="transform" type="translate"""" &
      &""" values="{series(places)}"""" & keyed(times, pts.len) &
      &""" dur="{dur}s" repeatCount="indefinite"/>""" & mark & "</g>"

  for arm in Arm:
    bits.add carried(hand(0, 0, leads = true, arm = arm,
                          held = holds[arm].isSome, level = levels[arm]),
                     hands.mapIt(it[Dancer.Lead][arm]))
  for own in [Arm.R, Arm.L]:
    let
      by = Arm.toSeq.filterIt(holds[it] == some(own))
      held = by.len > 0
    bits.add carried(
      hand(0, 0, leads = false, arm = own, held = held,
           level = (if held: levels[by[0]] else: none(Level))),
      hands.mapIt(it[Dancer.Follow][own]))
  &"""<svg class="{classes}" {view(box)}>""" & "\n        " &
    bits.join("\n        ") & "\n      </svg>"


func animated*(classes: string; holds: Holds; move: MoveApply;
    half = none(float); levels: Levels = default(Levels);
    ways: Ways = default(Ways); dur = 9.6; samples = 14): string =
  ## Draw same picture, moving: stage one travels, stage two comes home.
  let walk = cycle(move, samples)
  animatedPoses(classes, holds, walk.poses, half, levels, ways, dur,
                times = walk.times)
