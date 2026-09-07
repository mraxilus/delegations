## Route connection as taut string around two bodies.
##
##   Each end pays out along its own outline until straight stretch
##     between free ends clears both bodies, so reach hugs rim
##     exactly as far as it must and no further.
##   Every route is resampled to one fixed number of points, which is what
##     lets animation morph reach instead of jumping it.
##     Cost of fixed count: long reach and short one spend their points
##       at different densities.  Accepted -- morph needs like for like.
##   Which way round whole move goes is settled once, before any of it is
##     drawn (`oneWayRound`), because rule 1 must hold at every instant
##     browser blends, not merely at frames move is sampled at.
##     Cost of settling once: move that would genuinely change sides
##       mid-flight cannot be drawn.  Accepted -- no rule asks for one.

{.experimental: "strictFuncs".}

import std/[algorithm, math, options, sequtils, strformat, strutils]

import ./[body, geometry, style, terms]


const ROUTE_N* = 33   ## Points in every emitted reach, so frames can morph.

type
  Body* = tuple ## One dancer, as routing sees them.
    centre: Point
    facing: float
  WayRound* = tuple ## How reach sets off round each body: one side or
                    ## other.
    a, b: float
  Run* = seq[Point] ## One unbroken stretch of drawn reach.
  Ends* = tuple ## One connection, as routing takes it.
    a, b: Point
    body_a, body_b: Body

const WAYS*: array[4, WayRound] = [
  (1.0, 1.0), (1.0, -1.0), (-1.0, 1.0), (-1.0, -1.0),
] ## Four ways reach can set off.  Which one whole move uses is
  ## settled once, before any of it is drawn -- see `oneWayRound`.

const BREAK* = 11.0   ## Length of gap cut in under reach at crossing.

const
  DIAMOND_ROOM* = 24.0 ## How wide diamond that wound pair holds opens at
                       ## its middle.
  WIND_NIP = 0.4     ## How far wound pair draws together between its
                      ## hands.
    ## Two strands wound round each other pull in where they are wound and
    ##   are held apart only at their ends, so pair nips in at its middle
    ##   -- which is also what turns wide flat lens into diamond.  At no
    ##   wind there is nothing to pull, so it comes on with winding.
  BAND_STEPS = 120   ## Points along reach relaxed past marks, before it.

const
  SWAN_FROM = 1.0    ## Turns of wind past which pair stops sharing its
                      ## swing evenly between two connections.
  SWAN_EASE = 0.45   ## How quickly it hands over, as power of way
                      ## through.
    ## Under one, so hand-over is quick at start: third crossing
    ##   arrives as soon as pair is past whole turn, and until one
    ##   connection is visibly straighter of two, three crossings
    ##   read as second diamond -- which is thing rule 30 refused.
  SWAN_SWING* = 1.3   ## How much swing snake ends up carrying, as
                      ## multiple of what one connection carries on its own.
    ## Over one, so snake plainly goes *round* straight connection
    ##   rather than wobbling beside it -- but not far over, so it keeps in
    ##   close (rule 35).  Taking whole of what straight one gives
    ##   up threw loops wider than pair itself.
    ## How wide is matter of looks and was settled by looking; what
    ##   check holds is only that snake goes round something and stays
    ##   inside its own figure.



#[ Swan Hand-Over ]#

func overArm*(turns: float): Arm =
  ## Get which of lead's arms wound pair keeps on top at first
  ## crossing, from sign of wind (rules 27, 29).
  if turns >= 0: Arm.L else: Arm.R


func straightArm*(turns: float): Arm =
  ## Get which connection runs straight through middle of swan while
  ## other snakes round it (rule 31).
  ##   Snake is arm that is **over** at first crossing, so straight one
  ##     is other: Architect's reading, 2026-09-07.  Position is named for
  ##     that same arm, so `Right over Left swan` has Right going round
  ##     and Right on top at lead's own crossover.
  ##   This file argued opposite until then -- that one on top dives only
  ##     once and so stays visibly straight, while one diving twice has
  ##     no centre left to be surrounded by anything.  Both draw, and
  ##     drawing cannot tell which is danced, so ruling settles it.
  other(overArm(turns))


func swanning*(turns: float): float =
  ## Measure how far pair is through hand-over to swan: none up to
  ## whole turn, all of it at one and one-half turns (rule 31).
  pow(clamp((abs(turns) - SWAN_FROM) / 0.5, 0.0, 1.0), SWAN_EASE)


func windShare*(turns: float; arm: Arm): float =
  ## Measure how much of wound pair's swing this connection carries
  ## (rule 31).
  ##   Evenly to whole turn, so frame, cross and diamond are drawn
  ##     exactly as they were.  Past that, pair cannot keep swinging
  ##     symmetrically -- wind two strands far enough and one pulls taut
  ##     through middle while other wraps it -- so share runs
  ##     off one of them and onto other.
  ##   Onto, not away: what straight one gives up snake takes, so
  ##     pair swings as much as it ever did and snake's loops open
  ##     wide enough to be thing going *round* rather than wobble.
  if arm == straightArm(turns): 1 - swanning(turns)
  else: 1 + (SWAN_SWING - 1) * swanning(turns)

const
  BAND_PASSES = 240    ## Turns of pulling tight and pushing clear.
    ## Enough for band round marks that figure holds to stop moving:
    ##   pull travels one point per pass, so band of `BAND_STEPS` needs
    ##   several times its own length to settle end to end.
  SHOVES = 8           ## Shoves point gets per pass to leave every mark.
  BAND_PULL = 0.5      ## How far point goes towards its neighbours' middle.
    ## Half way is most that stays steady; further and band shivers
    ##   instead of settling.
  CLEAR_PASSES = 12    ## Times band may be widened to what it left clear.
    ## Widening mark moves band, which can hand shortfall to
    ##   mark next door, so settling takes some goes; `checks` measures
    ##   line that comes out rather than trusting that it did.
  CLEAR_ENOUGH = 0.01  ## Shortfall small enough to stop widening at.
    ## One hundredth of unit is one fiftieth of thinnest thing drawn, so
    ##   band that is this close is as clear as picture can show.

const
  BOW_SWELL = 2.0      ## Where bezier's control point starts, in apexes.
    ## Twice apex is what puts bezier's own middle on it, so this is
    ##   least swelling that could clear what hull touched.
  BOW_MORE = 0.35      ## And how much further out each try reaches.
  BOW_TRIES = 12       ## Tries before hull is kept after all.

const
  BEND_MIN = 12.0      ## Degrees turn must add up to before it is bend.
    ## Under this is wander of curve drawn as `ROUTE_N` straight bits,
    ##   which nobody reads as change of direction.
  BEND_COST* = 14.0     ## Line second bend must save to be worth making.
    ## About width of hand mark: turn reader has to follow should
    ##   buy at least as much as thing it is going round.
  SHARP_MAX* = 15.0     ## Degrees at one corner past which bend is break.
    ## Curve sampled at `ROUTE_N` turns few degrees per corner however far
    ##   round it goes, so anything this sharp is change of direction made
    ##   at one point -- which is what rule 24 rules out.



#[ Taut Around Bodies ]#

func segHits*(p, q: Point; body: Body): bool =
  ## Test whether this straight stretch passes inside body's outline.
  const steps = 32
  for i in 0 .. steps:
    let
      t = i / steps
      pt: Point = (p.x + (q.x - p.x) * t, p.y + (q.y - p.y) * t)
      off = bearing(pt.x - body.centre.x, pt.y - body.centre.y) - body.facing
    if dist(pt, body.centre) < outlineR(off) - 0.05:
      return true
  false


func taut*(ends: Ends; way: WayRound; cap = 90): Option[tuple[pts: seq[Point],
    length: float]] =
  ## Pull string tight from hand to hand around two bodies.
  ##   Each end pays out along its own outline, sample by sample, until
  ##     straight stretch between two free ends clears both bodies --
  ##     so reach hugs rim exactly as far as it has to, and where
  ##     straight way is already clear it never hugs at all.
  var
    ta = bearing(ends.a.x - ends.body_a.centre.x, ends.a.y - ends.body_a.centre.y)
    tb = bearing(ends.b.x - ends.body_b.centre.x, ends.b.y - ends.body_b.centre.y)
    arc_a = @[ends.a]
    arc_b = @[ends.b]
  for _ in 0 ..< cap:
    let
      pa = arc_a[^1]
      pb = arc_b[^1]
      ha = segHits(pa, pb, ends.body_a)
      hb = segHits(pa, pb, ends.body_b)
    if not ha and not hb:
      let
        step = degToRad(RIM_STEP) * BODY_R
        length = step * float(arc_a.len + arc_b.len - 2) + dist(pa, pb)
      var pts = arc_a
      for i in countdown(arc_b.high, 0):
        pts.add arc_b[i]
      return some (pts, length)
    if ha:
      ta += way.a * RIM_STEP
      arc_a.add outlinePoint(ends.body_a.centre, ends.body_a.facing, ta)
    if hb:
      tb += way.b * RIM_STEP
      arc_b.add outlinePoint(ends.body_b.centre, ends.body_b.facing, tb)
  none(tuple[pts: seq[Point], length: float])


func polylineLen*(pts: seq[Point]): float =
  ## Get drawn length of run.
  for i in 0 ..< pts.high:
    result += dist(pts[i], pts[i + 1])


func trimEnd(pts: seq[Point]; centre: Point; reach: float): seq[Point] =
  ## Cut path where it leaves hand's own mark, so ink starts on
  ## mark's border rather than under its middle.
  for i, q in pts:
    let d = dist(q, centre)
    if d >= reach:
      if i == 0:
        return pts
      let
        prev = pts[i - 1]
        pd = dist(prev, centre)
        t = if d > pd: (reach - pd) / (d - pd) else: 0.0
        crossing: Point = (prev.x + (q.x - prev.x) * t,
                           prev.y + (q.y - prev.y) * t)
      return @[crossing] & pts[i .. ^1]
  @[pts[^1]]


func reversed(pts: seq[Point]): seq[Point] =
  ## Walk same run from other end.
  for i in countdown(pts.high, 0):
    result.add pts[i]


func resample*(pts: seq[Point]; count: int): seq[Point] =
  ## Say same path as `count` evenly spaced points -- one shape for every
  ## frame of animation, so route can morph instead of jumping.
  var cum = @[0.0]
  for i in 0 ..< pts.high:
    cum.add cum[^1] + dist(pts[i], pts[i + 1])
  let total = if cum[^1] > 0: cum[^1] else: 1.0
  var j = 0
  for k in 0 ..< count:
    let target = total * float(k) / float(count - 1)
    while j < pts.len - 2 and cum[j + 1] < target:
      inc j
    let
      gap = cum[j + 1] - cum[j]
      span = if gap > 0: gap else: 1.0
      t = (target - cum[j]) / span
      p = pts[j]
      q = pts[j + 1]
    result.add (p.x + (q.x - p.x) * t, p.y + (q.y - p.y) * t)



#[ Which Way Round ]#

func frontOf*(hand: Point; body: Body): Option[float] =
  ## Get way round rim, from this hand, that heads for its own
  ## dancer's front.
  ##   Hand's own side turns "front" or "back" into direction by itself,
  ##     so this is whole of what rule naming one has to work out.
  ##   Nothing where hand is dead ahead or dead behind and neither way
  ##     is more frontward than other -- typed absence, not zero
  ##     caller must know to test for.
  let off = wrap180(
    bearing(hand.x - body.centre.x, hand.y - body.centre.y) - body.facing)
  if abs(off) < 1e-9 or abs(abs(off) - 180) < 1e-9:
    return none(float)
  some(if off > 0: -1.0 else: 1.0)


func wayFor*(ends: Ends; level: Option[Level]; way: Option[Way]):
    Option[WayRound] =
  ## Get which way round both bodies this hold says its line goes.
  ##   Not what is shortest -- what dance says: both wraps come round
  ##     front, both locks round back (rules 4 to 6).  Hold that has
  ##     named no level or no way has no opinion, and `routed` takes
  ##     short way.
  let sends = roundOf(level, way)
  if sends.isNone:
    return none(WayRound)
  let sides = (a: frontOf(ends.a, ends.body_a), b: frontOf(ends.b, ends.body_b))
  if sides.a.isNone or sides.b.isNone:
    return none(WayRound)             # dead ahead or behind: neither way
  if sends.get == Sends.FrontWay:
    some (sides.a.get, sides.b.get)
  else:
    some (-sides.a.get, -sides.b.get)


func wrapArc*(ends: Ends; way: WayRound): Option[tuple[a, b: float]] =
  ## Measure how far round each body line actually hugs, in degrees.
  ##   `taut` walks these arcs already and throws count away; this keeps
  ##     it, because wrap that does not wrap is not wrap (rule 7) and
  ##     only way to know is to measure what was drawn.
  var
    ta = bearing(ends.a.x - ends.body_a.centre.x, ends.a.y - ends.body_a.centre.y)
    tb = bearing(ends.b.x - ends.body_b.centre.x, ends.b.y - ends.body_b.centre.y)
    pa = ends.a
    pb = ends.b
    na = 0
    nb = 0
  for _ in 0 ..< 240:
    let
      ha = segHits(pa, pb, ends.body_a)
      hb = segHits(pa, pb, ends.body_b)
    if not ha and not hb:
      return some (float(na) * RIM_STEP, float(nb) * RIM_STEP)
    if ha:
      ta += way.a * RIM_STEP
      pa = outlinePoint(ends.body_a.centre, ends.body_a.facing, ta)
      inc na
    if hb:
      tb += way.b * RIM_STEP
      pb = outlinePoint(ends.body_b.centre, ends.body_b.facing, tb)
      inc nb
  none(tuple[a, b: float])


func wrapsEnough*(ends: Ends; level: Option[Level]; way: Option[Way]): bool =
  ## Test whether this hold's line really does go round body far enough to
  ## be lock or wrap it claims to be (rule 7).
  let asked = wayFor(ends, level, way)
  if asked.isNone:
    return false
  let arcs = wrapArc(ends, asked.get)
  arcs.isSome and max(arcs.get.a, arcs.get.b) >= float(WRAP_MIN)


func straightReach*(a, b: Point): seq[Point] =
  ## Route reach that goes over everything instead of round it.
  ##   `above` connection passes over head, so from overhead there is
  ##     nothing in its way -- no head, no torso -- and it is drawn straight
  ##     across whatever it crosses (rule 1's one exception).
  ##   Trimmed and resampled like any other reach, so it has same shape
  ##     and animation can morph between it and wrapping one.
  let reach = min(HAND_R + CAP, dist(a, b) / 3)
  var pts = trimEnd(@[a, b], a, reach)
  pts = reversed(trimEnd(reversed(pts), b, reach))
  resample(pts, ROUTE_N)



#[ Settling Past Marks ]#

type Mark* = tuple ## Something settled reach must not run through.
  centre: Point
  clear: float


func alongAt*(pts: seq[Point]; q: Point): float =
  ## How far along line point nearest `q` lies.
  ##   Distance along, not distance away: line that comes back on itself
  ##     passes near same place twice, so nearness alone cannot say
  ##     where on line something is -- which is exactly what snaking
  ##     reach does (rule 31).
  var
    along = 0.0
    nearest = (d: Inf, at: 0.0)
  for i, p in pts:
    let d = dist(p, q)
    if d < nearest.d:
      nearest = (d, along)
    if i < pts.high:
      along += dist(p, pts[i + 1])
  nearest.at


func nearestOn*(pts: seq[Point]; q: Point): float =
  ## Measure how close drawn line comes to point, segments and all.
  ##   Sampled points alone would miss sag between them, which is
  ##     very place line that looks clear stops being clear.
  result = Inf
  for i in 0 ..< pts.high:
    let
      (a, b) = (pts[i], pts[i + 1])
      run = (x: b.x - a.x, y: b.y - a.y)
      square = run.x * run.x + run.y * run.y
      along = if square < 1e-12: 0.0
              else: clamp(((q.x - a.x) * run.x + (q.y - a.y) * run.y) / square,
                          0.0, 1.0)
      near: Point = (a.x + run.x * along, a.y + run.y * along)
    result = min(result, dist(near, q))


func bendsIn*(pts: seq[Point]): int =
  ## Count separate turns drawn line makes -- what it asks reader to
  ## follow, rather than how many corners it happens to be drawn from.
  ##   Bend is sustained turn one way round: it counts once its corners
  ##     have added up to `BEND_MIN`, however many of them there were, so
  ##     long smooth arc is one bend and not thirty.
  ##   Turning back only starts new bend once *that* has added up to
  ##     `BEND_MIN` too.  Without that, hair of opposite wander in
  ##     curve drawn as straight bits would end arc it is inside and
  ##     same arc would be counted again and again.
  var
    way = 0.0
    turned = 0.0
    against = 0.0
    counted = false
  for i in 1 ..< pts.high:
    let
      into = (x: pts[i].x - pts[i - 1].x, y: pts[i].y - pts[i - 1].y)
      away = (x: pts[i + 1].x - pts[i].x, y: pts[i + 1].y - pts[i].y)
      cross = into.x * away.y - into.y * away.x
      dot = into.x * away.x + into.y * away.y
      corner = radToDeg(arctan2(cross, dot))
    if corner == 0:
      continue
    if way == 0:
      way = sgn(corner).float
    if sgn(corner).float == way:
      turned += abs(corner)
      against = 0.0
    else:
      against += abs(corner)
      if against < BEND_MIN:
        continue
      way = -way
      turned = against
      against = 0.0
      counted = false
    if not counted and turned >= BEND_MIN:
      inc result
      counted = true
  result


func sharpestIn*(pts: seq[Point]): float =
  ## Measure worst break in drawn line: most it turns at any one
  ## of its corners (rule 24).
  ##   Curve drawn as `ROUTE_N` straight bits turns slightly at every one
  ##     of them; corner turns much at one.  So sharpest corner, and
  ##     not total turning, is what tells break from bend.
  for i in 1 ..< pts.high:
    let
      into = (x: pts[i].x - pts[i - 1].x, y: pts[i].y - pts[i - 1].y)
      away = (x: pts[i + 1].x - pts[i].x, y: pts[i + 1].y - pts[i].y)
      cross = into.x * away.y - into.y * away.x
      dot = into.x * away.x + into.y * away.y
    result = max(result, abs(radToDeg(arctan2(cross, dot))))


func readingCost*(pts: seq[Point]): float =
  ## Measure what drawn reach asks of reader: its length, and its turns.
  ##   Turn is worth `BEND_COST` of line: taking one has to save at least
  ##     that much to be worth following (rule 23).
  polylineLen(pts) + BEND_COST * float(bendsIn(pts))


func letGo*(a, b: Point; marks: seq[Mark]; side: float): seq[Point] =
  ## Route settled reach as string pulled taut past marks in its
  ## way, and straight everywhere else (rule 22).
  ##   Line through hand cell it does not end on says that hand is
  ##     held; line through chevron hides facing.  So line is
  ##     band, pinned at two hands, that no mark may be inside.
  ##   It is found as band finds its own shape: start it somewhere,
  ##     then take turns pulling it tight -- each point drawn towards
  ##     midpoint of its neighbours -- and pushing whatever has ended up
  ##     inside mark back out to that mark's edge.  Where nothing is in
  ##     way, pulling wins outright and band is straight; where
  ##     something is, band lies along its edge and leaves on side
  ##     it was already passing.
  ##     Cost of relaxing rather than solving: shape is settled
  ##       state of one hundred small steps, not closed form, and mark
  ##       sitting exactly on straight line is turned either way by
  ##       arithmetic hair.  Accepted -- it is what real band does, and
  ##       result is measured rather than trusted.
  ##   `side` is where band is let go from, which is what decides which
  ##     way round each mark it settles: `0` starts it on straight line,
  ##     `1` and `-1` start it bowed clear over everything on one side or
  ##     other.  `clearedReach` is what chooses between them.
  ##   Reach is drawn as `ROUTE_N` points joined by straight segments, and
  ##     segment is chord across whatever band is bending round --
  ##     which falls inside curve it stands on.  So each mark is asked
  ##     for slightly more than it needs, by exactly that depth, and
  ##     drawn line is then measured against what marks really are.
  let span = dist(a, b)
  if marks.len == 0 or span < 1e-9:
    return straightReach(a, b)
  let
    along = ((b.x - a.x) / span, (b.y - a.y) / span)
    across = (-along[1], along[0])

  func asDrawn(pts: seq[Point]): seq[Point] =
    ## One way past marks, cut back to hands' own edges and sampled
    ## as every reach is, so any two of them can be compared -- and so
    ## animation can morph between one and wrapping reach.
    let reach = min(HAND_R + CAP, span / 3)
    var cut = trimEnd(pts, a, reach)
    cut = reversed(trimEnd(reversed(cut), b, reach))
    resample(cut, ROUTE_N)

  func placed(x, y: float): Point =
    ## Put point back where it belongs: so far along chord, so far off
    ## it.
    (a.x + along[0] * x + across[0] * y, a.y + along[1] * x + across[1] * y)

  func bowedPast(asked: seq[Mark]; side: float): seq[Point] =
    ## One-bend way past everything: single curve pinned at two
    ## hands and held to one side of chord (rules 23 and 24).
    ##   Marks are read as sky-line first: how far out string would
    ##     have to be at each step to clear everything reaching that far.
    ##     Its upper hull is taut string on that side -- shortest
    ##     line that turns one way only -- and its apex says where bulge
    ##     belongs and how far out it has to go.
    ##   Line drawn is not that hull, though.  Hull is polyline and
    ##     its apex is corner; rule 24 asks for curve.  So hull is
    ##     read as guide and reach is **one quadratic bezier** over
    ##     same apex, swelled until it clears every mark -- which turns
    ##     one way only, as bezier does, and has no break in it.
    ##     Cost of curve over hull: slightly more line, since
    ##       bezier passes short of its control point and has to reach
    ##       further out to clear what hull touched exactly.  Accepted
    ##       -- it is difference between bend and break.
    var sky = @[0.0]                   # pinned at hand it starts from
    for step in 1 ..< BAND_STEPS:
      let x = span * float(step) / float(BAND_STEPS)
      var pushed = 0.0
      for mark in asked:
        let
          to_mark = (mark.centre.x - a.x, mark.centre.y - a.y)
          xc = to_mark[0] * along[0] + to_mark[1] * along[1]
          yc = side * (to_mark[0] * across[0] + to_mark[1] * across[1])
          reach = mark.clear * mark.clear - (x - xc) * (x - xc)
        if reach > 0:
          pushed = max(pushed, yc + sqrt(reach))
      sky.add pushed
    sky.add 0.0                        # and at hand it ends on
    # Upper hull of sky-line, walked left to right: point stays
    # only while line to it still turns same way as one before.
    var hull: seq[int]
    for i in 0 .. sky.high:
      let x = span * float(i) / float(BAND_STEPS)
      while hull.len >= 2:
        let
          (p, q) = (hull[^2], hull[^1])
          (px, qx) = (span * float(p) / float(BAND_STEPS),
                      span * float(q) / float(BAND_STEPS))
        if (qx - px) * (sky[i] - sky[p]) - (sky[q] - sky[p]) * (x - px) <= 0:
          break
        discard hull.pop()
      hull.add i
    result = @[]
    for i in hull:
      result.add placed(span * float(i) / float(BAND_STEPS), side * sky[i])
    # Where hull stands furthest off chord is where curve wants
    # its control point.  Flat hull is straight reach and wants none.
    var apex = 0
    for i in hull:
      if sky[i] > sky[apex]:
        apex = i
    if sky[apex] < 1e-9:
      return
    let at = span * float(apex) / float(BAND_STEPS)

    func curveWith(swell: float): seq[Point] =
      ## Bezier from hand to hand over control point this far out.
      let hold = placed(at, side * swell * sky[apex])
      for step in 0 .. BAND_STEPS:
        let
          t = float(step) / float(BAND_STEPS)
          k = (1 - t) * (1 - t)
          m = 2 * (1 - t) * t
          n = t * t
        result.add (k * a.x + m * hold.x + n * b.x,
                    k * a.y + m * hold.y + n * b.y)

    # Bezier sags inside its control point, so it is swelled until it
    # really is clear of everything, and hull is kept for case --
    # mark sitting almost on hand -- where no swelling does it.
    for try_no in 0 .. BOW_TRIES:
      let
        curve = curveWith(BOW_SWELL + BOW_MORE * float(try_no))
        clear = asked.allIt(nearestOn(curve, it.centre) >= it.clear)
      if clear:
        return curve

  func drawnOver(asked: seq[Mark]): seq[Point] =
    ## Shortest way past marks: band let go from straight line
    ## and left to settle.
    var band: seq[Point]
    for step in 0 .. BAND_STEPS:
      band.add placed(span * float(step) / float(BAND_STEPS), 0.0)
    for pass_no in 1 .. BAND_PASSES:
      for i in 1 ..< band.high:
        let
          pull: Point = ((band[i - 1].x + band[i + 1].x) / 2,
                         (band[i - 1].y + band[i + 1].y) / 2)
        band[i] = (band[i].x + (pull.x - band[i].x) * BAND_PULL,
                   band[i].y + (pull.y - band[i].y) * BAND_PULL)
        # Pushed out of mark it is deepest inside, and then out of
        # whatever that put it into, and so on.  Marks overlap -- chevron
        # is row of them along its own legs -- so point shoved clear of
        # each in turn ends up inside one before; deepest first is
        # what actually leaves whole huddle.
        for shove in 1 .. SHOVES:
          var
            deepest = -1
            depth = 0.0
          for k, mark in asked:
            let into = mark.clear - dist(band[i], mark.centre)
            if into > depth:
              depth = into
              deepest = k
          if deepest < 0:
            break
          let mark = asked[deepest]
          # Out to edge, as it already lay; point exactly on
          # mark's centre has no way of its own, so it takes band's.
          var away = (x: band[i].x - mark.centre.x,
                      y: band[i].y - mark.centre.y)
          if hypot(away.x, away.y) < 1e-9:
            let run = (x: band[i + 1].x - band[i - 1].x,
                       y: band[i + 1].y - band[i - 1].y)
            away = (x: -run.y, y: run.x)
          let length = hypot(away.x, away.y)
          band[i] = (mark.centre.x + away.x / length * mark.clear,
                     mark.centre.y + away.y / length * mark.clear)
    band

  func sagged(asked: seq[Mark]; length: float): seq[Mark] =
    ## Same marks, each grown by how deep drawn chord across it cuts.
    let step = length / float(ROUTE_N - 1)
    for mark in asked:
      result.add (mark.centre, mark.clear + step * step / (8 * mark.clear))

  # Widened until line as drawn, and not merely band behind it,
  # really does clear every mark.
  var
    asked = marks
    length = span
  for _ in 0 .. CLEAR_PASSES:
    let grown = sagged(asked, length)
    result = asDrawn(
      if side == 0: drawnOver(grown) else: bowedPast(grown, side))
    length = polylineLen(result)
    var lost = 0.0
    for i, mark in marks:
      let short = mark.clear - nearestOn(result, mark.centre)
      if short > 0:
        asked[i].clear += short
        lost = max(lost, short)
    if lost < CLEAR_ENOUGH:
      break


const SIDES* = [0.0, 1.0, -1.0]
  ## Where settled reach may be let go from, shortest first (rule 23).



#[ Winding and Crossings ]#

func wound*(a, b: Point; across: Point; phi_a, sweep: float;
    radius = BODY_R; share = 1.0): seq[Point] =
  ## Route one reach of wound pair: shadow wound arm casts from
  ## above (rules 27 and 28).
  ##   Two held hands sit on their own bodies' rims, one body's radius off
  ##     pair's axis, and winding pair carries them round that axis.
  ##     From above all that is left of going round is how far off axis
  ##     arm is, which swings with angle -- so reach's offset is
  ##     `radius * sin` of angle that runs from what one hand makes with
  ##     axis to what other does, long way round if pair has
  ##     wound further.
  ##   That is whole of drawing.  At no wind, angle holds still
  ##     and reach is straight.  At half turn it sweeps half way round
  ##     and offset crosses axis once: pair makes **cross**.  At
  ##     whole turn it sweeps whole way and crosses twice, once by
  ##     each dancer, with **diamond** between: rule 27's shape, arrived
  ##     at rather than imposed.
  ##   Nothing else moves off chord, so ends stay exactly on their
  ##     hands and turn's frames blend into one another without jump --
  ##     which is what rule 28 asks for.
  ##   `share` is how much of pair's swing this reach carries, which is
  ##     all of it until pair is wound past whole turn (rule 31).  At
  ##     none it is plain chord between its two hands, which is
  ##     straight connection swan is built round.
  var pts: seq[Point]
  let
    swing = radius * share
    off_a = swing * sin(phi_a)
    off_b = swing * sin(phi_a + sweep)
    # Wound strands pull in on each other where they are wound, and are
    # held apart only where they are held: at hands.
    nip = WIND_NIP * min(abs(sweep) / (2 * PI), 1.0)
  for step in 0 .. BAND_STEPS:
    let
      t = float(step) / float(BAND_STEPS)
      drawn_in = swing * (1 - nip * sin(PI * t))
      # Chord's own offset taken out and swung one put in, so
      # two ends are hands however far middle has gone round.
      swung = drawn_in * sin(phi_a + sweep * t) -
              (off_a + (off_b - off_a) * t)
    pts.add (a.x + (b.x - a.x) * t + across.x * swung,
             a.y + (b.y - a.y) * t + across.y * swung)
  let reach = min(HAND_R + CAP, dist(a, b) / 3)
  var cut = trimEnd(pts, a, reach)
  cut = reversed(trimEnd(reversed(cut), b, reach))
  resample(cut, ROUTE_N)


func clearedReach*(a, b: Point; marks: seq[Mark]): seq[Point] =
  ## Route settled reach plainest way past marks it does not join
  ## (rules 22 and 23).
  ##   Band let go from straight line finds *shortest* way past
  ##     marks -- which can be weave, one mark passed on left and
  ##     next on right, and reader has to follow every one of
  ##     those turns.  Length is not only thing picture costs.
  ##   So band is also let go from bow right over one side, and from
  ##     one right over other, and three are judged on **length and
  ##     turns together** (`readingCost`): turn has to save more than
  ##     `BEND_COST` of line to be worth making reader follow it.  In most
  ##     of these figures one bend does whole job for some units more.
  ##   Reach that already turns once or not at all, and turns smoothly, is
  ##     as plain as line gets, so nothing else is tried for it.  Break
  ##     is not plain however few of them there are (rule 24), so reach
  ##     with one in is weighed against curves even so.
  result = letGo(a, b, marks, SIDES[0])
  if bendsIn(result) <= 1 and sharpestIn(result) < SHARP_MAX:
    return
  var least = readingCost(result)
  for side in SIDES[1 .. ^1]:
    let tried = letGo(a, b, marks, side)
    if readingCost(tried) < least:
      least = readingCost(tried)
      result = tried


func crossingsOf*(one, other: seq[Point]): seq[Point] =
  ## Find where two drawn reaches cross, so each crossing can be broken.
  ##   Segment against segment, and where they really cross rather than
  ##     where their sampled points come close.  Two lines crossing steeply
  ##     pass between one another's points without any pair of them being
  ##     near at all, which is how one cross went unbroken.
  ##   In order along `one`, so arm that dives can be alternated from
  ##     first crossing to last (rules 14, 27, 29).
  for i in 0 ..< one.high:
    for j in 0 ..< other.high:
      let
        p = one[i]
        q = other[j]
        r = (x: one[i + 1].x - p.x, y: one[i + 1].y - p.y)
        s = (x: other[j + 1].x - q.x, y: other[j + 1].y - q.y)
        turn_of = r.x * s.y - r.y * s.x
      if abs(turn_of) < 1e-12:
        continue                     # running parallel, never meeting
      let
        gap = (x: q.x - p.x, y: q.y - p.y)
        along = (gap.x * s.y - gap.y * s.x) / turn_of
        across = (gap.x * r.y - gap.y * r.x) / turn_of
      if along < 0 or along > 1 or across < 0 or across > 1:
        continue                     # lines meet, drawn bits do not
      let at: Point = (p.x + r.x * along, p.y + r.y * along)
      # One point per crossing: two segments of one reach can both meet
      # same segment of other where they turn across it.
      if result.len == 0 or dist(result[^1], at) > BREAK:
        result.add at


const
  DAYLIGHT = 0.6      ## Space left between cut end and what it passes under.
  GRAZING = 0.25      ## Least sine of crossing angle break is sized from.
    ## Two reaches meeting almost head on hide unbounded length of one
    ##   another; gap that long is hole in picture, so angle is floored
    ##   and grazing pair takes widest break drawing will draw.

func headingAt(pts: seq[Point]; at: Point): float =
  ## Say which way reach is going where it passes nearest this point.
  var near = (d: Inf, i: 0)
  for i, q in pts:
    let d = dist(q, at)
    if d < near.d:
      near = (d, i)
  let
    a = pts[max(near.i - 1, 0)]
    b = pts[min(near.i + 1, pts.high)]
  arctan2(b.y - a.y, b.x - a.x)


func hidesAt*(under, over: seq[Point]; at: Point): float =
  ## Say how wide gap in under reach is where over one crosses it.
  ##   Break is **shadow of line crossing over it**.  That line covers its
  ##     own width square on and more at slant, which is its width over
  ##     sine of angle between them.
  ##   Round caps put half width back on each end of gap, so what is
  ##     written is shadow plus one whole width, and `DAYLIGHT` either
  ##     side so cut ends do not touch what they pass beneath.
  ##   Break sized any other way is number rather than shadow, and reads
  ##     as gap in line wherever it is wider than thing it hides.
  var between = abs(headingAt(under, at) - headingAt(over, at))
  while between > PI:
    between = 2 * PI - between
  if between > PI / 2:
    between = PI - between
  LINK_W / max(sin(between), GRAZING) + LINK_W + 2 * DAYLIGHT


func gapFor*(at, span, wide: float): tuple[opens, shuts: float] =
  ## Say where gap for crossing this far along reach opens and shuts.
  ##   Gap slides rather than hangs off end.  Crossing lying within half
  ##     break of hand would leave stub too short to draw at all, and
  ##     reach stopping short of its hand reads as unfinished line, never
  ##     as one passing beneath something -- which is whole of what break
  ##     is for (rule 14).
  ##   Sliding rather than shortening, so every gap is same length and
  ##     one break reads like every other.  Gap still covers its crossing
  ##     wherever crossing is half break clear of both ends, which is
  ##     every case that can be drawn whole.
  ##   Centred on its crossing, always.  Break says line passes under
  ##     another one, and it says it where they cross; gap pushed to one
  ##     side leaves crossing drawn whole and puts hole in line where
  ##     nothing happens.
  ##   Crossing with less than half gap either side of it carries none:
  ##     there is no room to put break in without hanging it off end, and
  ##     reach stopping short of its hand reads as unfinished line rather
  ##     than as one passing beneath (rule 14).
  if at <= wide / 2 or span - at <= wide / 2:
    return (at, at)
  (at - wide / 2, at + wide / 2)


func alongOf(pts: seq[Point]): seq[float] =
  ## Measure how far along reach each of its points sits.
  result = @[0.0]
  for i in 0 ..< pts.high:
    result.add result[^1] + dist(pts[i], pts[i + 1])


func atAlong(pts: seq[Point]; along: seq[float]; want: float): Point =
  ## Get point this far along reach, reading between two samples where it
  ## falls between them.
  for i in 0 ..< pts.high:
    if along[i + 1] >= want:
      let step = along[i + 1] - along[i]
      if step <= 0:
        return pts[i]
      let part = (want - along[i]) / step
      return (x: pts[i].x + (pts[i + 1].x - pts[i].x) * part,
              y: pts[i].y + (pts[i + 1].y - pts[i].y) * part)
  pts[^1]


func runsOutside(pts: seq[Point]; along: seq[float];
    gaps: seq[tuple[opens, shuts: float]]): seq[Run] =
  ## Collect what is left of reach once its gaps are taken out.
  ##   Each piece is cut exactly on its gap's edge, between samples where
  ##     that is where edge lies.  Dropping whole samples instead widened
  ##     every gap by up to one step at each end and took as much off
  ##     pieces beside it, which is what left stub too short to read
  ##     however gap was placed.
  ##   Gap of no width is no gap, and takes nothing out.
  var shut: seq[tuple[opens, shuts: float]]
  for gap in gaps:
    if gap.shuts > gap.opens:
      shut.add gap
  shut.sort(proc (a, b: tuple[opens, shuts: float]): int = cmp(a.opens, b.opens))
  var
    keep: seq[tuple[from_here, to_there: float]]
    at = 0.0
  for gap in shut:
    if gap.opens > at:
      keep.add (at, gap.opens)
    at = max(at, gap.shuts)
  if at < along[^1]:
    keep.add (at, along[^1])
  for stretch in keep:
    if stretch.to_there <= stretch.from_here:
      continue
    var run = @[atAlong(pts, along, stretch.from_here)]
    for i, q in pts:
      if along[i] > stretch.from_here and along[i] < stretch.to_there:
        run.add q
    run.add atAlong(pts, along, stretch.to_there)
    if run.len > 1:
      result.add run


func cutGapsAt*(pts, over: seq[Point]; centres: seq[Point]): seq[Run] =
  ## Break reach at every place it runs under another, not only first.
  ##   Each gap is as wide as what hides it there, which is why reach that
  ##     crosses over is wanted here and not only its crossings.
  if centres.len == 0:
    return @[pts]
  let along = alongOf(pts)
  var gaps: seq[tuple[opens, shuts: float]]
  for centre in centres:
    var nearest = (d: Inf, at: 0.0)
    for i, p in pts:
      let d = dist(p, centre)
      if d < nearest.d:
        nearest = (d, along[i])
    gaps.add gapFor(nearest.at, along[^1], hidesAt(pts, over, centre))
  runsOutside(pts, along, gaps)



#[ Emitted Reach ]#

func routed*(ends: Ends; way = none(WayRound)):
    Option[tuple[pts: seq[Point], way: WayRound]] =
  ## Route one reach: hand border to hand border, wrapping wherever it must.
  ##   With nothing said it takes short way round.  Hand it one of `WAYS`
  ##     and it takes that one instead, whatever length -- which is how
  ##     whole move keeps to one side of body from first frame to last.
  var best = none(tuple[pts: seq[Point], length: float, way: WayRound])
  for combo in (if way.isSome: @[way.get] else: @WAYS):
    let pulled = taut(ends, combo)
    if pulled.isSome and (best.isNone or pulled.get.length < best.get.length):
      best = some (pulled.get.pts, pulled.get.length, combo)
  if best.isNone:
    return none(tuple[pts: seq[Point], way: WayRound])
  let reach = min(HAND_R + CAP, polylineLen(best.get.pts) / 3)
  var pts = trimEnd(best.get.pts, ends.a, reach)
  pts = reversed(trimEnd(reversed(pts), ends.b, reach))
  some (resample(pts, ROUTE_N), best.get.way)


func oneWayRound*(frames: seq[Ends]): WayRound =
  ## Settle single way round whole move is drawn with.
  ##   Moving reach is interpolated between frames it is sampled at, so
  ##     two neighbouring frames that disagree about which side of body
  ##     line passes are drawn, in between, as line sweeping straight
  ##     through that body.  One way for whole move makes that
  ##     impossible: no two frames can disagree if there is only one answer.
  ##   It has to be way every frame can actually be routed, so ones
  ##     that fail anywhere are dropped and shortest of rest wins.
  var best = none(tuple[way: WayRound, total: float])
  for combo in WAYS:
    var
      total = 0.0
      served = true
    for ends in frames:
      let pulled = taut(ends, combo)
      if pulled.isNone:
        served = false
        break
      total += polylineLen(pulled.get.pts)
    if served and (best.isNone or total < best.get.total):
      best = some (combo, total)
  doAssert best.isSome,
    &"No way round serves every frame of this move; got `{frames.len}` frames."
  best.get.way


func splitAt*(runs: seq[Run]; mid: Point): tuple[near, far: seq[Run]] =
  ## Cut reach in two at point nearest `mid`, so it can be drawn in two
  ## shades that meet there.
  ##   Two halves share that point, so join is join and not gap;
  ##     and any break over-and-under crossing has already cut stays cut,
  ##     because runs are split rather than rebuilt.
  var best = (d: Inf, i: 0, j: 0)
  for i, run in runs:
    for j, q in run:
      let d = dist(q, mid)
      if d < best.d:
        best = (d, i, j)
  var near = runs[0 ..< best.i] & @[runs[best.i][0 .. best.j]]
  var far = @[runs[best.i][best.j .. ^1]] & runs[best.i + 1 .. ^1]
  for run in near:
    if run.len > 1:
      result.near.add run
  for run in far:
    if run.len > 1:
      result.far.add run


func smoothed*(run: Run): string =
  ## Say run of points as one smooth curve instead of chain of straight
  ## bits (rule 35).
  ##   Reach is stored as `ROUTE_N` points because that is what lets it
  ##     morph, and drawn between them it is polygon.  Where it hardly
  ##     turns nobody can tell; where it turns hard -- swan's lobes, which
  ##     double back inside handful of points -- polygon is exactly
  ##     what is seen, and it reads as jagged.
  ##   So points become *control* points of quadratics and
  ##     midpoints between them become places curve passes through.  Every
  ##     corner is rounded by half its own segments, ends stay exactly
  ##     on their hands, and line that turns couple of degrees per corner
  ##     moves by fraction of its own width.
  ##   Command count follows point count, which is fixed, so
  ##     smoothed reach morphs exactly as straight-sided one did.
  result = "M" & xy(run[0])
  for i in 1 ..< run.high:
    let mid: Point = ((run[i].x + run[i + 1].x) / 2,
                      (run[i].y + run[i + 1].y) / 2)
    result.add " Q" & xy(run[i]) & " " & xy(mid)
  result.add " L" & xy(run[^1])


func reachMarkup*(runs: seq[Run]; ink: string): string =
  ## Draw one shade's worth of reach as single path.
  var pieces: seq[string]
  for run in runs:
    if run.len > 1:
      pieces.add smoothed(run)
  let d = pieces.join(" ")
  &"""<path d="{d}" fill="none" stroke="{ink}"""" &
    &""" stroke-width="{LINK_W}" stroke-linecap="round"""" &
    """ stroke-linejoin="round"/>"""


func cutGap*(pts: seq[Point]; over: seq[Point]): seq[Run] =
  ## Break under reach where over one crosses it.
  ##   Where they cross, and nowhere else: break says reach passes
  ##     beneath something, so pair that never meets carries none.
  ##     Cutting at whichever point came nearest instead broke every
  ##     parallel pair, at end nearest point ties on.
  ##   Same crossings and same gaps as wound pair's, through same two
  ##     funcs, since one break should read like every other.
  cutGapsAt(pts, over, crossingsOf(pts, over))
