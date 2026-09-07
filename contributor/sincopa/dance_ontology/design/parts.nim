## Build every figure four pages place, keyed by name each page uses.
##
##   Split as pages are: frame picture is one exploration,
##     turn sign another, and two turn mock-ups one each.
##   Inline assertions are part of build -- page whose orientations
##     collide or whose collapse figures differ is refused, not published.
##     Cost of asserting in builder: broken figure stops whole
##       build rather than one plate.  Accepted -- published page with one
##       wrong plate is worse than no page.

{.experimental: "strictFuncs".}

import std/[algorithm, math, options, sequtils, sets, strformat, strutils,
            tables]

import ./[rules, sign]
import ../src/dance_ontology/draw/[body, figure, geometry, pose, route, style]


type Parts* = OrderedTable[string, string]
  ## Every placed figure, in order it was built.


const ORIENTATIONS* = [
  (name: "face to face", lead_turn: 0.0, follow_turn: 0.0),
  (name: "the follow faces away", lead_turn: 0.0, follow_turn: 180.0),
  (name: "the lead faces away", lead_turn: 180.0, follow_turn: 0.0),
  (name: "back to back", lead_turn: 180.0, follow_turn: 180.0),
] ## Four ways couple can face, as pages walk them.

const HOLD*: Holds = [some Arm.L, none Arm]
  ## Workhorse hold: lead's Left to follow's left.

const SETTLINGS* = [
  (level: none Level, way: none Way, follow_turn: 0.0,
   caption: "no way said<br>— it stays at its side"),
  (level: some Level.Low, way: some Way.Lock, follow_turn: 0.0,
   caption: "<em>low</em> lock<br>face to face"),
  (level: some Level.High, way: some Way.Lock, follow_turn: 0.0,
   caption: "<em>high</em> lock<br>face to face"),
  (level: some Level.Low, way: some Way.Wrap, follow_turn: 180.0,
   caption: "<em>low</em> wrap<br>the follow turned away"),
  (level: some Level.High, way: some Way.Wrap, follow_turn: 180.0,
   caption: "<em>high</em> wrap<br>the follow turned away"),
] ## Each settling drawn in orientation that admits it, because most do
  ## not: lock or wrap only exists where line really goes round.

const GRID_STATES* = [
  (level: Level.High, way: Way.Wrap), (level: Level.Low, way: Way.Wrap),
  (level: Level.Low, way: Way.Lock), (level: Level.High, way: Way.Lock),
] ## Grid rule 7 implies: which states exist in which orientation.

const GRID_TURNS* = [0.0, 90.0, 180.0, 270.0]
  ## Follow's four bearings settling grid samples, one quarter apart.

const CHART_FACING* = 40.0
  ## Chart's body is turned off vertical, so spots visibly
  ## follow chevron and not page.


func said*(level: Option[Level]; arm = Arm.L): Levels =
  ## Say one arm's level, or nothing at all where nothing was said.
  result[arm] = level

func said*(way: Option[Way]; arm = Arm.L): Ways =
  ## Say one arm's way, or nothing at all where nothing was said.
  result[arm] = way


func replaceFirst*(s, sub, by: string): string =
  ## Replace only first occurrence, as figure post-passes need.
  let at = s.find(sub)
  if at < 0: s
  else: s[0 ..< at] & by & s[at + sub.len .. ^1]


func slotChart*(arm = Arm.L): string =
  ## Draw one body with all six spots on it, and this hand's four marked.
  ##   Drawn rather than tabulated because table is thing most likely
  ##     to be wrong -- and drawn on body turned off vertical, because
  ##     spots are measured off dancer's facing rather than off
  ##     page, and body facing up hides difference (rule 3).
  # Its own box rather than square every other figure uses: labels
  # are wide and body is small, so square would draw it tiny.
  var bits = @["""<svg viewBox="-80 -46 160 92" width="248" height="143">"""]
  var chart = rest()
  chart.place[Dancer.Lead] = (0.0, 0.0)
  chart.facing[Dancer.Lead] = CHART_FACING
  bits.add border(chart, Dancer.Lead)
  bits.add chevron((0.0, 0.0), CHART_FACING)
  var lands: seq[tuple[arm: Arm, slot: Slot]]
  for s in SETTLINGS:
    let landed = slotOf(arm, s.level, s.way)
    if landed notin lands:
      lands.add landed
  for place in Arm:
    for slot in Slot:
      let
        aim = CHART_FACING + slotBearing(place, slot)
        p = polar(0.0, 0.0, BODY_R, aim)
        # In this hand's own ink wherever it sits, because that is
        # whole point: Left hand carried to right side is still Left.
        used = (place, slot) in lands
      bits.add hand(p.x, p.y, leads = true, arm = arm, held = used,
                    level = none(Level),
                    free = (if used: Free.Fade else: Free.Grey))
      let
        label = polar(0.0, 0.0, BODY_R + HAND_R + 13, aim)
        anchor = if label.x < 0: "end" else: "start"
        text = if slot == Slot.Default: "side" else: word(slot)
      bits.add &"""<text x="{n(label.x)}" y="{n(label.y + 3)}"""" &
        &""" text-anchor="{anchor}"""" &
        " style=\"font: 8px ui-sans-serif, system-ui," &
        &""" sans-serif; fill: {FAINT}">{text}</text>"""
  bits.join("") & "</svg>"



#[ Frame Page ]#

func frameParts*(): Parts =
  ## Build every SVG frame page places.
  result["f_none"] = renderFigure("f", HOLD)
  result["f_low"] = renderFigure("f", HOLD, said(some Level.Low))
  result["f_high"] = renderFigure("f", HOLD, said(some Level.High))
  result["f_above"] = renderFigure("f", HOLD, said(some Level.Above))
  result["f_over"] = renderFigure("f", [some Arm.L, some Arm.R],
                           [some Level.High, some Level.Low],
                           over = some Arm.L)

  # Four orientations, twice: with nothing held, where only colours
  # and chevrons can say it, and holding, where line is there too.
  var seen: HashSet[string]
  for i, o in ORIENTATIONS:
    result[&"or_free_{i}"] = renderFigure("f", default(Holds),
                                   lead_turn = o.lead_turn,
                                   follow_turn = o.follow_turn)
    result[&"or_held_{i}"] = renderFigure("f", HOLD, lead_turn = o.lead_turn,
                                   follow_turn = o.follow_turn)
    result[&"or_tiny_{i}"] = renderFigure("tiny", HOLD, lead_turn = o.lead_turn,
                                   follow_turn = o.follow_turn,
                                   captions = false)
    seen.incl result[&"or_free_{i}"]
  doAssert seen.len == ORIENTATIONS.len,
    &"Orientations collide; got `{seen.len}` distinct of `{ORIENTATIONS.len}`."

  # Free hands: keep hue, or go grey and lose orientation with it.
  result["free_fade"] = renderFigure("f", default(Holds), free = Free.Fade)
  result["free_grey"] = renderFigure("f", default(Holds), free = Free.Grey)
  result["free_fade_tiny"] = renderFigure("tiny", default(Holds), free = Free.Fade,
                                   captions = false)
  result["free_grey_tiny"] = renderFigure("tiny", default(Holds), free = Free.Grey,
                                   captions = false)

  # What pair of colours at two ends says.
  result["pair_ll"] = renderFigure("f", HOLD)
  result["pair_ll_turned"] = renderFigure("f", HOLD, follow_turn = 180)
  result["pair_lr"] = renderFigure("f", [some Arm.R, none Arm])
  result["pair_lr_turned"] = renderFigure("f", [some Arm.R, none Arm],
                                   follow_turn = 180)

  # Six spots, and five settlings that reach four of them.
  result["slot_chart"] = slotChart(Arm.L)
  var reached: seq[tuple[arm: Arm, slot: Slot]]
  for k, s in SETTLINGS:
    result[&"settle_{k}"] = renderFigure("f", HOLD, said(s.level),
                                  ways = said(s.way),
                                  follow_turn = s.follow_turn,
                                  captions = false)
    let landed = slotOf(Arm.L, s.level, s.way)
    if landed notin reached:
      reached.add landed
  # Left hand reaches four of six; other two belong to Right.
  doAssert reached.sorted == @[(Arm.L, Slot.Default), (Arm.L, Slot.Back),
                               (Arm.R, Slot.Front), (Arm.R, Slot.Back)].sorted,
    &"The settlings reach the wrong spots; got `{reached.sorted}`."
  # Both wraps share spot and are told apart by their fill alone.
  doAssert result["settle_3"] != result["settle_4"],
    "High and low wrap collide; got one drawing for both."

  # Routing each hold decides, on one orientation that admits all three.
  for (name, level, way) in [("route_wrap", Level.Low, Way.Wrap),
                             ("route_low", Level.Low, Way.Lock),
                             ("route_high", Level.High, Way.Lock)]:
    let turn = if way == Way.Wrap: 180.0 else: 0.0
    result[name] = renderFigure("f", HOLD, said(some level), ways = said(some way),
                         follow_turn = turn, captions = false)
  doAssert toHashSet([result["route_wrap"], result["route_low"],
                      result["route_high"]]).len == 3,
    "The three routes are not three distinct drawings."

  # And grid wrap rule implies: most states do not exist most of
  # time, which is worth drawing rather than asserting on its own.
  var drawn = 0
  for s in GRID_STATES:
    for turn in GRID_TURNS:
      let
        key = &"grid_{word(s.level)}_{word(s.way)}_{int(turn)}"
        pose = canonicalise(spinAbout(rest(), Dancer.Follow, turn))
      if danceable(pose, HOLD, said(some s.level), said(some s.way)):
        result[key] = renderFigure("tiny", HOLD, said(some s.level),
                            ways = said(some s.way), follow_turn = turn,
                            captions = false)
        inc drawn
      else:
        result[key] = ""             # edge that is not drawn
  doAssert drawn > 0 and drawn < GRID_STATES.len * GRID_TURNS.len,
    &"The grid should be partial; got `{drawn}` cells drawn."

  # `above` has no lock and no wrap, so it stays where arm hangs.
  result["above_plain"] = renderFigure("f", HOLD, said(some Level.Above),
                                captions = false)
  result["above_asked"] = renderFigure("f", HOLD, said(some Level.Above),
                                ways = said(some Way.Wrap), captions = false)
  doAssert result["above_plain"] == result["above_asked"],
    "Above took a wrap; the two drawings differ."

  # Orbit in two stages: follow travels, then world comes home.
  # Drawn twice -- orbit itself, where walker keeps their side to
  # centre (rule 32), and compound, which is that orbit with
  # counter-turn danced into it so walker keeps their own bearing.
  for (tag, locked) in [("orbit", true), ("compound", false)]:
    var stage_one = [0.0, 0.5, 1.0].mapIt(
      orbit(rest(), Dancer.Follow, 90 * it, locked = locked))
    stage_one[0].ring = none(Ring)     # nothing is travelling yet
    let landed = stage_one[^1]
    var stage_two = [0.5, 1.0].mapIt(canonicalise(landed, it))
    for q in stage_two.mitems:
      q.ring = none(Ring)
    let
      walk = stage_one & stage_two
      half = walk.mapIt(extent(it, captions = false)).max
    for k, q in walk:
      result[&"walk_{tag}_{k}"] = renderFigure("wide", HOLD, pose = some q,
                                        captions = false, half = some half)

  # What collapses, and what does not.  Compound -- orbit walked
  # while turning other way, so walker keeps their own bearing --
  # lands in one picture whichever dancer walks it: only pair's axis has
  # swung, and drawing cannot say who walked.
  var walked_by: array[Dancer, Pose]
  for who in Dancer:
    walked_by[who] = canonicalise(orbit(rest(), who, 90, locked = false))
    walked_by[who].ring = none(Ring)   # move is over
  result["collapse_follow_walked"] = renderFigure("f", HOLD,
                                           pose = some walked_by[Dancer.Follow])
  result["collapse_lead_walked"] = renderFigure("f", HOLD,
                                         pose = some walked_by[Dancer.Lead])
  doAssert result["collapse_follow_walked"] == result["collapse_lead_walked"],
    "Two compounds draw two pictures; the drawing can say who walked."

  # And orbit -- walker keeping their side to centre (rule 32) --
  # lands where their partner's own axis turn lands.  Compound does not,
  # which is what pair of figures is here to show.
  var orbited = canonicalise(orbit(rest(), Dancer.Follow, 90, locked = true))
  orbited.ring = none(Ring)
  result["collapse_orbit"] = renderFigure("f", HOLD, pose = some orbited)
  result["collapse_axis"] = renderFigure("f", HOLD, lead_turn = -90)
  doAssert relative(orbited) == relative(
    spinAbout(rest(), Dancer.Lead, -90)),
    "The orbit does not land on the axis turn's state."
  # Not merely equal numbers: both are same drawing, mark for mark.
  doAssert result["collapse_orbit"] == result["collapse_axis"],
    "The collapse differs: orbit and axis draw two pictures."
  doAssert result["collapse_follow_walked"] != result["collapse_axis"],
    "The compound lands on the axis turn, so the two are not two moves."

  # And same four moves, running.
  const MOVE_PX = 1.3  ## Pixels one unit takes in frame page's moving cells.
  for m in MOVES:
    let
      tag = m.name.replace(" ", "_").replace(",", "")
      half = cycle(m.apply).mapIt(extent(it, captions = false)).max
      style = &"""class="mv" style="width: {n(2 * half * MOVE_PX)}px;""" &
        &""" height: {n(2 * half * MOVE_PX)}px""""
    result[&"mv_{tag}"] = animated("mv", HOLD, m.apply, some half)
      .replaceFirst("class=\"mv\"", style)
    result[&"mv_{tag}_still"] = renderFigure("mv still", HOLD, captions = false,
                                      half = some half)
      .replaceFirst("class=\"mv still\"",
        &"""class="mv still" style="width: {n(2 * half * MOVE_PX)}px;""" &
          &""" height: {n(2 * half * MOVE_PX)}px"""")



#[ Single-Hand Turns Page ]#

const
  PX = 1.0        ## Pixels one unit takes in turn page's moving cell.
  STILL_PX = 0.72 ## And in still one, where figures are smaller.


func sized(svg, cls: string; half, px: float): string =
  ## Give cell room its row's box needs at its row's own scale.
  ##   Shared by both turn pages -- it was defined twice, byte for byte,
  ##     inside each builder before pages were read side by side.
  svg.replaceFirst(&"class=\"{cls}\"",
    &"""class="{cls}" style="width: {n(2 * half * px)}px;""" &
      &""" height: {n(2 * half * px)}px"""")


const SINGLES*: array[4, tuple[holds: Holds, name: string]] = [
  ([some Arm.L, none Arm], "Left to left"),
  ([some Arm.R, none Arm], "Left to right"),
  ([none Arm, some Arm.L], "Right to left"),
  ([none Arm, some Arm.R], "Right to right"),
] ## App's four single-hand frames, named as workbook names them.

const
  ABOVE_ONE*: Levels = [some Level.Above, none Level]
    ## Rule 17's assumption made visible on left arm: held arm is
    ## carried over head, sole level with no lock and no wrap in it
    ## (rule 8), and one that draws its connection straight over
    ## everything.
  ABOVE_OTHER*: Levels = [none Level, some Level.Above]
    ## Same assumption, for hold on other arm.

const
  QUARTERS_ROUND* = 4        ## Quarter turns in round, and so positions.
  QUARTER* = 90.0            ## Degrees in one of them.

type
  Family* {.pure.} = enum ## Which round of positions one way of turning walks.
    FollowFacing,         ## Follow comes round where they stand.
    PairSwung             ## Axis swings and follow's facing with it.
  TurnWay* {.pure.} = enum ## Four ways couple can turn quarter.
    FollowAxis, LeadAxis, FollowOrbit, LeadOrbit

const WAYS_OF_TURNING*: array[TurnWay, tuple[
    tag, title, blurb: string; who: Dancer; about: About]] = [
  (tag: "fa", title: "The follow turns on the spot",
   blurb: "The follow turns on their own axis and nobody travels. What " &
     "comes round is their <b>chevron</b>, and with it which of their " &
     "hands is nearer. The lead stands still, facing up, so there is " &
     "nothing to reorient afterwards: one stage, and it is over.",
   who: Dancer.Follow, about: About.Axis),
  (tag: "la", title: "The lead turns on the spot",
   blurb: "The lead turns on their own axis, and this is where the two " &
     "stages matter. <b>Stage one</b>: the lead turns and the room holds " &
     "still, so the picture leans off upright. <b>Stage two</b>: the " &
     "picture turns back until the lead faces up, which swings the follow " &
     "round them. Same turn, told in the order it is danced.",
   who: Dancer.Lead, about: About.Axis),
  (tag: "fo", title: "The follow orbits the lead",
   blurb: "The follow walks the ring round the lead, who stands still — " &
     "the dashed ring says so, and says who is standing. <b>Whatever side " &
     "of them faced the lead goes on facing them</b>, so they turn as far " &
     "as they travel (rule 32). The lead never moves and never turns, so " &
     "there is no second stage at all: what you see is the walk — and it " &
     "lands on the very pictures the <em>lead's own axis turn</em> lands " &
     "on, measured and asserted on every build.",
   who: Dancer.Follow, about: About.Orbit),
  (tag: "lo", title: "The lead orbits the follow",
   blurb: "The lead walks the ring round the follow, facing the centre the " &
     "same way. It is the one way of the four that takes the lead off " &
     "their spot, so it is the one whose second stage has anything to do. " &
     "It lands where the <em>follow's own axis turn</em> lands. Which " &
     "dancer walked is not something the drawing can say; only the path " &
     "can, which is why all four are animated.",
   who: Dancer.Lead, about: About.Orbit),
] ## What each way of turning is called on pages, who dances it, and
  ## about what.  Which round it walks is not restated here: `FAMILY_OF`
  ## carries that, measured -- second copy had crept into these rows and
  ## been one nothing read.

const FAMILY_OF*: array[TurnWay, Family] = [
  Family.FollowFacing, Family.PairSwung, Family.PairSwung,
  Family.FollowFacing,
] ## Which round each way walks, measured and asserted below.
  ##   Orbit that faces centre turns walker as far as it carries
  ##     them (rule 32), so it comes to same thing as their partner's
  ##     axis turn other way: two rounds between four ways, each
  ##     reached by one axis turn and one orbit.
  ##   Which is point of correction.  Half turn is then half
  ##     turn however it is danced, and ways can be equated.


func levelsFor*(holds: Holds): Levels =
  ## Say above on whichever single arm is holding.
  if holds[Arm.L].isSome: ABOVE_ONE else: ABOVE_OTHER


func quarterPose*(way: TurnWay; quarter: int): Pose =
  ## Get pose this way of turning reaches after so many quarters.
  ##   Drawn canonically, with lead facing up: that is what position
  ##     is, whatever stages turning took to arrive at it.
  ##   And without ring: dashed ring says *somebody is going round
  ##     somebody*, which is true of transition and not of place to
  ##     stand.  It is why orbit rounds draw as their axis partners do.
  ##   Framed on lead (rule 25), so they stand in same spot in
  ##     every cell of row and it is follow who is seen to move.
  let w = WAYS_OF_TURNING[way]
  result = canonicalise(turned(rest(), w.who, w.about,
                               QUARTER * float(quarter)), on = Anchor.Lead)
  result.ring = none(Ring)


func placeOf*(pose: Pose): tuple[axis, facing: float] =
  ## Get position as pair of numbers that compare cleanly.
  ##   `relative` can hand back 360 where another hands back 0, and
  ##     negative zero where another hands back positive one, so both are
  ##     brought into round before anything is compared.
  let r = relative(pose)
  (floorMod(r.axis, 360.0), floorMod(r.facing, 360.0))


func turnGlyph*(label: string; width = 44.0): string =
  ## Draw one edge of cycle: two-headed arrow, since turn reverses.
  ##   Arrow keeps its length whatever box; `width` is room for
  ##     label above it, which longer name needs more of.
  let
    mid = width / 2
    (tail, head) = (mid - 15, mid + 15)
  &"""<svg viewBox="0 0 {n(width)} 30" width="{n(width)}" height="30"""" &
    " aria-hidden=\"true\">" &
    &"""<text x="{n(mid)}" y="9" text-anchor="middle" style="font: 8px""" &
    &""" ui-sans-serif, system-ui, sans-serif; fill: {FAINT}">{label}""" &
    "</text>" &
    &"""<path d="M{n(tail)} 20 L{n(head)} 20 M{n(tail + 5)} 15""" &
    &""" L{n(tail)} 20 L{n(tail + 5)} 25 M{n(head - 5)} 15 L{n(head)} 20""" &
    &""" L{n(head - 5)} 25" fill="none" stroke="{QUIET}"""" &
    """ stroke-width="1.6" stroke-linecap="round"""" &
    """ stroke-linejoin="round"/></svg>"""


func singleTurnParts*(): Parts =
  ## Build every SVG single-hand turns page places.
  ##   Rule 16: single hand held above turns for ever, so no position is
  ##     ever refused and how far it has wound is not part of its state.
  ##     What is left is four quarter-turn orientations per connection.
  ##   Rule 19: four ways of turning reach them -- each dancer's own axis
  ##     turn and each dancer's orbit of other.
  ##   Rule 15: every position drawn, every edge animated.
  ##   Rule 25: framed on lead, who therefore falls on same spot in
  ##     every cell -- which only reads if cells beside each other hold
  ##     same box.
  ##     Row of positions takes one box for whole page, since every
  ##       position stands same distance apart.  Row of transitions
  ##       takes one box per way of turning, because lead who walks
  ##       ring needs room lead who stands still does not, and spending
  ##       that room on every cell of every row would shrink all of them.
  ##     Each cell is then given what its box needs at scale its own row
  ##       draws at, so marks stay size they were and it is
  ##       cells that grow.
  var
    walks: array[TurnWay, array[QUARTERS_ROUND, Walk]]
    still_half = 0.0
    walk_half: array[TurnWay, float]
  for way in TurnWay:
    let w = WAYS_OF_TURNING[way]
    for quarter in 0 ..< QUARTERS_ROUND:
      still_half = max(still_half,
                       extent(quarterPose(way, quarter), captions = false))
      walks[way][quarter] = turnWalk(quarterPose(way, quarter), w.who,
                                     w.about, QUARTER, on = Anchor.Lead)
      for put in walks[way][quarter].poses:
        walk_half[way] = max(walk_half[way], extent(put, captions = false))

  for way in TurnWay:
    let w = WAYS_OF_TURNING[way]
    for c, single in SINGLES:
      let levels = levelsFor(single.holds)

      # Every derived position of this way.
      for quarter in 0 ..< QUARTERS_ROUND:
        result[&"st_{w.tag}_{c}_{quarter}"] = sized(renderFigure("tiny",
          single.holds, levels, captions = false,
          pose = some quarterPose(way, quarter), half = some still_half,
          clear_marks = true), "tiny", still_half, STILL_PX)

      # And every edge, walked in stages rule 18 asks for.
      for quarter in 0 ..< QUARTERS_ROUND:
        let to = (quarter + 1) mod QUARTERS_ROUND
        result[&"tr_{w.tag}_{c}_{quarter}_{to}"] = sized(animatedPoses("mv",
          single.holds, walks[way][quarter].poses, some walk_half[way],
          levels, dur = 5.4, times = walks[way][quarter].times),
          "mv", walk_half[way], PX)
        # Still stands in where motion is turned off, so it is settled
        # picture and bends by rule 22; moving figure it replaces is
        # rule's own exemption and stays straight.
        result[&"tr_{w.tag}_{c}_{quarter}_{to}_still"] = sized(
          renderFigure("mv still", single.holds, levels, captions = false,
                pose = some quarterPose(way, quarter),
                half = some walk_half[way], clear_marks = true),
          "mv still", walk_half[way], PX)

  result["g_quarter"] = turnGlyph("&#188; turn")

  # Every position of round draws differently, or position it is not.
  for way in TurnWay:
    for c in 0 ..< SINGLES.len:
      var seen: seq[string]
      for quarter in 0 ..< QUARTERS_ROUND:
        let figure = result[&"st_{WAYS_OF_TURNING[way].tag}_{c}_{quarter}"]
        doAssert figure notin seen,
          &"Two quarters draw alike; got `{quarter}` of {way} on {c}."
        seen.add figure

  # Ways of one family walk one round of positions, and ways of different
  # families never meet except where every round meets, at rest.
  for way in TurnWay:
    for mate in TurnWay:
      var shared = 0
      for quarter in 0 ..< QUARTERS_ROUND:
        for other_quarter in 0 ..< QUARTERS_ROUND:
          if placeOf(quarterPose(way, quarter)) ==
              placeOf(quarterPose(mate, other_quarter)):
            inc shared
      let same_round = FAMILY_OF[way] == FAMILY_OF[mate]
      doAssert shared == (if same_round: QUARTERS_ROUND else: 1),
        &"A way left its family; got `{shared}` shared of {way} and {mate}."

  # And nothing on this page wraps body: reach is connection's own
  # stroke width, and one drawn with arc has walked round body.
  for key, figure in result:
    if not (key.startsWith("st_") or key.startsWith("tr_")):
      continue
    for piece in figure.split("<path "):
      if &"stroke-width=\"{LINK_W}\"" in piece:
        doAssert " A" notin piece,
          &"A reach walks round a body; got an arc in `{key}`."



#[ Hand-to-Hand Turns Page ]#

const
  HAND_TO_HAND*: Holds = [some Arm.R, some Arm.L]
    ## App's own two-hand frame: lead's Left in follow's right
    ## and lead's Right in follow's left, uncrossed.
  ABOVE_BOTH*: Levels = [some Level.Above, some Level.Above]
    ## Both arms over head, this scope's one level (rules 17, 21).
  HALF* = 180.0 ## Turn between one position and next (rule 28).

const STEPS* = [-1.5, -1.0, -0.5, 0.0, 0.5, 1.0, 1.5]
  ## One chain, in turns of wind from hold's own parallel state (rule 31).
  ##   Seven positions half turn apart: hold's own frame in middle,
  ##     rule 28's cross either side of it, rule 27's diamond beyond each
  ##     of those, and rule 13's extra arm twist -- **swan** -- at each end.
  ##   Steps are whole of chain; what differs between one hold
  ##     and another is only which facing sits at nothing wound, which is
  ##     half turn of offset rule 31 names, and that is measured rather
  ##     than written down here.

type Position* = tuple[wind: float, name, note: string]
  ## One place on chain: how far it is wound, and how page says so.


func windTwist*(wind: float): Twists =
  ## Say how far pair has wound, as drawing channel takes it.
  [wind, wind]


func posedAt*(wind, phase: float): Pose =
  ## Get pose hold stands in when it is wound this far from its own
  ## parallel state, that state being `phase` turns off face to face.
  ##   Follow's own axis turn is what poses are built from, so
  ##     half turn faces them away where they stand and whole turn brings
  ##     everything back.  Which dancer did turning is not something
  ##     position can say; page animates all of them.
  result = canonicalise(turned(rest(), Dancer.Follow, About.Axis,
                               2 * HALF * (wind + phase)), on = Anchor.Lead)
  result.ring = none(Ring)


func phaseOf*(holds: Holds): float =
  ## Say how far off face to face this hold's two connections run parallel:
  ## phase of chain it sits on (rule 31).
  ##   Measured, in rule 28's habit: hold is parallel where angle
  ##     its two ends make with pair's axis agree, and `windOf` is
  ##     already thing that measures that.
  ##   Two candidates and no more, because chain steps by half turns:
  ##     hand to hand runs parallel with partners facing one another,
  ##     crossed pair with one of them facing away, and those are
  ##     same chain read half turn apart.
  for phase in [0.0, 0.5]:
    let put = settled(posedAt(0.0, phase), holds, ABOVE_BOTH, default(Ways))
    if abs(windOf(put, holds, Arm.L).spread) < 1e-6:
      return phase
  raise newException(Defect, &"A hold runs parallel at neither phase; got `{holds}`.")


func chainFor*(holds: Holds): seq[Position] =
  ## Lay out chain one hold walks: every step of it, named and noted.
  ##   Shape is glossary's word for that step of chain -- **open**,
  ##     **cross**, **diamond**, **swan** -- which is why neither `x` nor
  ##     `box` appears here: glossary names both as words to avoid.
  ##   Which arm is over is preliminary and user's: position is called
  ##     for whichever of lead's arms passes over other at lead's
  ##     own crossover, and for shape pair makes there.
  # Asked for its refusal alone: hold that runs parallel at neither
  # phase cannot walk chain, and dies here rather than mid-table.
  discard phaseOf(holds)
  for wind in STEPS:
    let
      shape = case int(abs(wind) * 2)
              of 0: &"Left-to-{handName(holds[Arm.L].get)} and " &
                    &"Right-to-{handName(holds[Arm.R].get)}"
              of 1: "cross"
              of 2: "diamond"
              else: "swan"
      far = case int(abs(wind) * 2)
            of 0: "the app's frame"
            of 1: "a half turn"
            of 2: "a whole turn"
            else: "a turn and a half"
    # Which way partners face is pose's business and follows from
    # wind, so page says rule of it once in prose rather than
    # every caption saying it over: face to face at whole number of
    # turns, both one way at half.  It is also whole of offset
    # between this hold and its dual (rule 31).
    result.add (wind,
      # Middle of chain is glossary's **open**, and it alone says which
      # hands are joined, since every other position inherits that.
      if abs(wind) < 1e-9: &"{shape} open"
      elif wind > 0: &"Left over Right {shape}"
      else: &"Right over Left {shape}",
      far)


const
  HAND_PHASE* = phaseOf(HAND_TO_HAND)
    ## Hand to hand runs parallel with partners facing one another, so
    ## its chain sits at nothing -- measured on every build, not assumed.
  CHAIN* = chainFor(HAND_TO_HAND)
    ## Seven positions this page holds, in chain order.


func handPose*(wind = 0.0): Pose =
  ## Get pose one position of this page's chain stands in.
  posedAt(wind, HAND_PHASE)


func pairAt*(holds: Holds; wind, phase: float): array[Arm, seq[Point]] =
  ## Two reaches position draws, made as drawing makes them.
  let
    put = settled(posedAt(wind, phase), holds, ABOVE_BOTH, default(Ways))
    p = handsOf(put)
  for arm in Arm:
    result[arm] = wound(p[Dancer.Lead][arm], p[Dancer.Follow][holds[arm].get],
                        axisOf(put).across,
                        degToRad(windOf(put, holds, arm).phi),
                        2 * PI * wind, share = windShare(wind, arm))


func windSense*(way: TurnWay): float =
  ## Say which way along chain positive turn by this way winds.
  ##   Measured, not tabulated (rule 30, and rule 28's habit): turn
  ##     quarter from frame and read wind off farthest pose it
  ##     passes through.
  ##   Farthest, not last: walk rocks out to its turn and back
  ##     again, so it ends where it began and end says nothing.
  ##   Quarter, because half turn's wind sits exactly on `wrap180`'s
  ##     seam and so carries no sign to read.
  ##   Way that winds nothing at all would take forward sense, having
  ##     no end to walk off side of.  Since rule 32 there is no such
  ##     way -- every one of four winds -- and fallback stands only
  ##     so way that stopped winding could not silently freeze.
  let w = WAYS_OF_TURNING[way]
  var turned_by = 0.0
  for put in turnWalk(handPose(), w.who, w.about, HALF / 2,
                      on = Anchor.Lead).poses:
    let spread = windOf(settled(put, HAND_TO_HAND, ABOVE_BOTH, default(Ways)),
                        HAND_TO_HAND, Arm.L).spread
    if abs(spread) > abs(turned_by):
      turned_by = spread
  if turned_by < -1e-9: -1.0 else: 1.0


func handTurnParts*(): Parts =
  ## Build every SVG hand-to-hand turns page places.
  ##   Rules 28 and 31: seven positions, half turn apart -- frame,
  ##     cross either side of it, diamond beyond each cross, and swan
  ##     beyond each diamond.
  ##   Rule 15: every position drawn, every edge animated, by every way of
  ##     turning.
  ##   Rule 32: all four of them walk chain, since orbit that keeps
  ##     its side to centre winds pair as far as it carries
  ##     walker.  Which is measured rather than claimed, as it was when
  ##     answer was other one.
  var
    walks: array[TurnWay, array[CHAIN.len - 1, Walk]]
    still_half = 0.0
    walk_half: array[TurnWay, float]
  for position in CHAIN:
    still_half = max(still_half, extent(handPose(position.wind),
                                        captions = false))
  for way in TurnWay:
    let
      w = WAYS_OF_TURNING[way]
      sense = windSense(way)
    for i in 0 ..< CHAIN.len - 1:
      # Each edge starts where it starts and turns half, so way that
      # winds walks one step along chain and way that does not
      # simply carries pair out and back.
      #   Which way it turns is way that walks chain *inward*,
      #     because ends of chain are ends (rule 30): positive
      #     turn by lead unwinds what positive turn by follow
      #     winds, so turning both same way sent lead's edges off
      #     end into second diamond.
      walks[way][i] = turnWalk(handPose(CHAIN[i].wind), w.who, w.about,
                               HALF * sense, on = Anchor.Lead)
      for put in walks[way][i].poses:
        walk_half[way] = max(walk_half[way], extent(put, captions = false))

  # Chain, drawn once: all four ways reach these same seven (rule 32), so
  # drawing them per way would be same picture over again.
  for i, position in CHAIN:
    result[&"hh_{i}"] = sized(renderFigure("tiny", HAND_TO_HAND, ABOVE_BOTH,
      captions = false, pose = some handPose(position.wind),
      half = some still_half, twist = windTwist(position.wind),
      clear_marks = true), "tiny", still_half, STILL_PX)

  # And every edge of it, walked by every way of turning.
  for way in TurnWay:
    let w = WAYS_OF_TURNING[way]
    for i in 0 ..< CHAIN.len - 1:
      result[&"hw_{w.tag}_{i}"] = sized(animatedPoses("mv", HAND_TO_HAND,
        walks[way][i].poses, some walk_half[way], ABOVE_BOTH, dur = 5.4,
        times = walks[way][i].times, wound = CHAIN[i].wind),
        "mv", walk_half[way], PX)
      # Still stands in where motion is turned off, so it is
      # picture move sets off from (rule 22's exemption again).
      result[&"hw_{w.tag}_{i}_still"] = sized(renderFigure("mv still",
        HAND_TO_HAND, ABOVE_BOTH, captions = false,
        pose = some handPose(CHAIN[i].wind), half = some walk_half[way],
        twist = windTwist(CHAIN[i].wind), clear_marks = true),
        "mv still", walk_half[way], PX)

  # Narrow, because chain is seven long now and glyph stands
  # between every pair of them (rule 31).
  result["g_half"] = turnGlyph("a half turn", 52.0)

  # Every position draws differently, or they are not seven positions.
  for i in 0 ..< CHAIN.len:
    for j in 0 ..< i:
      doAssert result[&"hh_{i}"] != result[&"hh_{j}"],
        &"Two positions draw alike; got `{i}` and `{j}`."



#[ Turn Sign Page ]#

func signParts*(): Parts =
  ## Build every SVG turn-sign page places.
  let
    low_arms: SignArms = [(true, some Level.Low), (true, some Level.Low)]
    split_arms: SignArms = [(true, some Level.Low), (true, some Level.High)]
  # Quarters, packed up from foot.
  for k in 1 .. 4:
    result[&"q_lead_{k}"] = sign(newSeqWith(k, Row.Lead), arms = low_arms)
    result[&"q_foll_{k}"] = sign(newSeqWith(k, Row.Follow), arms = low_arms)
    result[&"q_lead_{k}_small"] = sign(newSeqWith(k, Row.Lead),
                                       arms = low_arms, scale = 0.72)
  for k in [1, 3]:                     # alternative: spread, not packed
    result[&"u_lead_{k}"] = sign(newSeqWith(k, Row.Lead), arms = low_arms,
                                 packed = false)

  # Whose quarter, and arms inside.
  result["s_split"] = sign(@[Row.Lead, Row.Lead], arms = split_arms)
  result["s_acw"] = sign(newSeqWith(3, Row.Lead), Lean.Acw, low_arms)
  result["s_one_hand"] = sign(@[Row.Follow, Row.Follow],
                              arms = [(true, some Level.Low),
                                      (false, none Level)])
  result["s_above"] = sign(newSeqWith(4, Row.Follow),
                           arms = [(true, some Level.Above),
                                   (true, some Level.Above)])
  result["s_unsaid"] = sign(@[Row.Lead])
  result["s_lead_small"] = sign(@[Row.Lead, Row.Lead], arms = low_arms,
                                scale = 0.72)
  result["s_foll_small"] = sign(@[Row.Follow, Row.Follow], arms = low_arms,
                                scale = 0.72)
  # Shade says whose quarter it is as well as shape does.
  doAssert result["s_lead_small"] != result["s_foll_small"],
    "Dancers collide: the two shades draw one sign."

  # Mixed, now that there is room for more than one split.
  result["m_11"] = sign(@[Row.Follow, Row.Lead], arms = low_arms)
  result["m_12"] = sign(@[Row.Follow, Row.Lead, Row.Lead], arms = low_arms)
  result["m_22"] = sign(@[Row.Follow, Row.Follow, Row.Lead, Row.Lead],
                        arms = low_arms)
  result["m_31"] = sign(@[Row.Follow, Row.Follow, Row.Follow, Row.Lead],
                        arms = low_arms)
  result["m_22_small"] = sign(@[Row.Follow, Row.Follow, Row.Lead, Row.Lead],
                              arms = low_arms, scale = 0.72)

  # Axis against orbit, on sign.
  result["o_axis"] = sign(@[Row.Lead, Row.Lead], arms = split_arms,
                          about = some About.Axis)
  result["o_orbit"] = sign(@[Row.Lead, Row.Lead], arms = split_arms,
                           about = some About.Orbit)
  result["o_orbit_acw"] = sign(newSeqWith(3, Row.Follow), Lean.Acw,
                               split_arms, about = some About.Orbit)
  result["o_axis_small"] = sign(@[Row.Lead, Row.Lead], arms = split_arms,
                                about = some About.Axis, scale = 0.72)
  result["o_orbit_small"] = sign(@[Row.Lead, Row.Lead], arms = split_arms,
                                 about = some About.Orbit, scale = 0.72)
  result["p_split"] = sign(@[Row.Follow, Row.Lead], arms = split_arms,
                           pip_about = @[About.Orbit, About.Axis])
  result["p_split_small"] = sign(@[Row.Follow, Row.Lead], arms = split_arms,
                                 pip_about = @[About.Orbit, About.Axis],
                                 scale = 0.72)

  # Five ways to say "any amount".
  result["any_full"] = sign(newSeqWith(4, Row.Lead), arms = low_arms)
  for (name, ending) in [("open", Ending.Open), ("spill", Ending.Spill),
                         ("ellipsis", Ending.EllipsisEnd),
                         ("repeat", Ending.RepeatEnd), ("loop", Ending.Loop)]:
    let
      count = if ending in [Ending.EllipsisEnd, Ending.RepeatEnd]: 3 else: 4
      base = newSeqWith(count, Row.Lead)
      foll = newSeqWith(count, Row.Follow)
    result[&"any_{name}"] = sign(base, arms = low_arms, ending = some ending)
    result[&"any_{name}_small"] = sign(base, arms = low_arms,
                                       ending = some ending, scale = 0.72)
    result[&"any_{name}_foll"] = sign(foll, arms = low_arms,
                                      ending = some ending)
