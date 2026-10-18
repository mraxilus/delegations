## Build every figure two turn pages place, keyed by name each page uses.
##
##   Split as pages are: one turn mock-up for each kind of hold.
##   Inline assertions are part of build -- page whose quarters
##     or positions draw alike is refused, not published.
##     Cost of asserting in builder: broken figure stops whole
##       build rather than one plate.  Accepted -- published page with one
##       wrong plate is worse than no page.

{.experimental: "strictFuncs".}

import std/[math, options, sequtils, strformat, strutils, tables]

import ./rules
import ../src/dance_ontology/draw/[body, figure, geometry, pose, route, style]
from ../src/dance_ontology/rotation import Facing, facing, name, Seen
  # Rotation's `Dancer` would meet drawing's, so only facing's words come in.
export Facing, name


type
  Parts* = OrderedTable[string, string]  ## Every placed figure, in order it was built.

  Round* {.pure.} = enum  ## Which round of positions one manner of turn walks.
    FollowFacing,  ## Follow comes round where they stand.
    PairSwung  ## Axis swings and follow's facing with it.
  Manner* {.pure.} = enum  ## Four manners of turn couple can take.
    FollowAxis, LeadAxis, FollowOrbit, LeadOrbit

  Position* = tuple[wind: float, name, note: string]
    ## One place on chain: how far it is wound, and how page says so.


func onQuarter(degrees: float): Option[int] =
  ## Get bearing as whole quarters clockwise, none where it falls between.
  let quarters = floorMod(degrees, 360.0) / 90.0
  if abs(quarters - round(quarters)) < 1e-6: some(int(round(quarters)) mod 4)
  else: none(int)


func facingOf*(pose: Pose): Option[Facing] =
  ## Name facing drawn pose stands in, read off where each dancer sees other.
  ##   `relative` holds follow's place and facing against lead.  Follow sees
  ##     lead back across that axis: half turn round, less follow's own facing.
  ##   None between quarters, where dancer sees other at no one side.
  let
    relation = relative(pose)
    lead = onQuarter(relation.axis)
    follow = onQuarter(relation.axis + 180.0 - relation.facing)
  if lead.isNone or follow.isNone: none(Facing)
  else: some(facing([Seen(lead.get), Seen(follow.get)]))


func turnedFacing*(lead_turn, follow_turn: float): Option[Facing] =
  ## Name facing each dancer's turn on spot from Face-to-face draws, in degrees.
  facingOf(
    canonicalise(spinAbout(spinAbout(rest(), Dancer.Lead, lead_turn), Dancer.Follow, follow_turn)),
  )


const HOLD*: Holds = [some Arm.Left, none Arm]  ## Workhorse hold: lead's Left to follow's left.


func said*(level: Option[Level], arm = Arm.Left): Levels =
  ## Say one arm's level, or nothing at all where nothing was said.
  result[arm] = level

func said*(modifier: Option[Modifier], arm = Arm.Left): Modifiers =
  ## Say one arm's modifier, or nothing at all where nothing was said.
  result[arm] = modifier


func replaceFirst*(text, pattern, by: string): string =
  ## Replace only first occurrence, as figure post-passes need.
  let at = text.find(pattern)
  if at < 0: text
  else: text[0..<at] & by & text[at+pattern.len .. ^1]



#[ Single-Hand Turns Page ]#

const
  PIXELS = 1.0  ## Pixels one unit takes in turn page's moving cell.
  STILL_PIXELS = 0.72  ## And in still one, where figures are smaller.
  WALK_SECONDS = 5.4  ## Clock one edge of state graph takes, out and back.
    ## Walk of several edges takes multiple of it, so every animation on
    ##   these pages runs at one pace and length of loop says how far it
    ##   goes rather than how fast.


func sized(svg, classes: string; half, pixels: float): string =
  ## Give cell room its row's bounds need at its row's own scale.
  ##   Shared by both turn pages -- it was defined twice, byte for byte,
  ##     inside each builder before pages were read side by side.
  svg.replaceFirst(&"class=\"{classes}\"",
    &"""class="{classes}" style="width: {numeral(2 * half * pixels)}px;""" &
    &""" height: {numeral(2 * half * pixels)}px"""")


const SINGLES*: array[4, tuple[holds: Holds, name: string]] = [
  ([some Arm.Left, none Arm], "Left to left"),
  ([some Arm.Right, none Arm], "Left to right"),
  ([none Arm, some Arm.Left], "Right to left"),
  ([none Arm, some Arm.Right], "Right to right"),
]  ## App's four single-hand frames, named as workbook names them.

const
  ABOVE_ONE*: Levels = [some Level.Above, none Level]
    ## Rule 17's assumption made visible on left arm: held arm is
    ## carried over head, sole level with no lock and no wrap in it
    ## (rule 8), and one that draws its connection straight over
    ## everything.
  ABOVE_OTHER*: Levels = [none Level, some Level.Above]  ## Same assumption, for hold on other arm.

const
  QUARTERS_ROUND* = 4  ## Quarter turns in round, and so positions.
  QUARTER* = 90.0  ## Degrees in one of them.


const MANNERS*: array[Manner, tuple[
    tag, title, blurb: string, who: Dancer, about: About]] = [
  (tag: "fa", title: "The follow turns on the spot",
   blurb: "The follow turns on their own axis, and nobody travels. Their " &
       "<b>chevron</b> comes round, and with it the hand that stands nearer. " &
       "The lead stands still and faces up, so nothing needs to come back " &
       "afterward. One stage, and it is over.",
   who: Dancer.Follow, about: About.Axis),
  (tag: "la", title: "The lead turns on the spot",
   blurb: "The lead turns on their own axis, and here the two stages " &
       "matter. <b>Stage one</b>: the lead turns, the room holds still, and " &
       "the picture leans off upright. <b>Stage two</b>: the picture turns " &
       "back until the lead faces up, which swings the follow round them. It " &
       "is one turn, told in the order it is danced.",
   who: Dancer.Lead, about: About.Axis),
  (tag: "fo", title: "The follow orbits the lead",
   blurb: "The follow walks the ring round the lead, who stands still. The " &
       "dashed ring says so, and says who stands. <b>Whichever side of them " &
       "faced the lead goes on facing them</b>, so they turn as far as they " &
       "travel (rule 32). The lead never moves and never turns, so there is " &
       "no second stage: the walk is the whole figure. It lands on the " &
       "pictures the <em>axis turn of the lead</em> reaches, and every " &
       "build measures that.",
   who: Dancer.Follow, about: About.Orbit),
  (tag: "lo", title: "The lead orbits the follow",
   blurb: "The lead walks the ring round the follow, and faces the centre " &
       "the same way. It is the one manner of the four that takes the lead " &
       "off their spot. Its second stage has something to do. It lands " &
       "where the <em>axis turn of the follow</em> lands. The drawing cannot " &
       "say which dancer walked, and only the path says that, so all four " &
       "are drawn in motion.",
   who: Dancer.Lead, about: About.Orbit),
]  ## What each manner of turn is called on pages, who dances it, and
  ## about what.  Which round it walks is not restated here: `LUT_ROUND_BY_MANNER`
  ## carries that, measured -- second copy had crept into these rows and
  ## been one nothing read.

const LUT_ROUND_BY_MANNER*: array[Manner, Round] = [
  Round.FollowFacing, Round.PairSwung, Round.PairSwung,
  Round.FollowFacing,
]  ## Which round each manner walks, measured and asserted below.
  ##   Orbit that faces centre turns walker as far as it carries
  ##     them (rule 32), so it comes to same thing as their partner's
  ##     axis turn other way: two rounds between four manners, each
  ##     reached by one axis turn and one orbit.
  ##   Which is point of correction.  Half turn is then half
  ##     turn however it is danced, and manners can be equated.


func levelsFor*(holds: Holds): Levels =
  ## Say above on whichever single arm is holding.
  if holds[Arm.Left].isSome: ABOVE_ONE else: ABOVE_OTHER


func quarterPose*(manner: Manner, quarter: int): Pose =
  ## Get pose this manner of turn reaches after so many quarters.
  ##   Drawn canonically, with lead facing up: that is what position
  ##     is, whatever stages turning took to arrive at it.
  ##   And without ring: dashed ring says *somebody is going round
  ##     somebody*, which is true of transition and not of place to
  ##     stand.  It is why orbit rounds draw as their axis partners do.
  ##   Framed on lead (rule 25), so they stand in same spot in
  ##     every cell of row and it is follow who is seen to move.
  let description = MANNERS[manner]
  result = canonicalise(
    turned(rest(), description.who, description.about, QUARTER * float(quarter)),
    on = Anchor.Lead,
  )
  result.ring = none(Ring)


func placeOf*(pose: Pose): tuple[axis, facing: float] =
  ## Get position as pair of numbers that compare cleanly.
  ##   `relative` can hand back 360 where another hands back 0, and
  ##     negative zero where another hands back positive one, so both are
  ##     brought into round before anything is compared.
  let relation = relative(pose)
  (floorMod(relation.axis, 360.0), floorMod(relation.facing, 360.0))


func turnGlyph*(label: string, width = 44.0): string =
  ## Draw one edge of cycle: two-headed arrow, since turn reverses.
  ##   Arrow keeps its length whatever bounds; `width` is room for
  ##     label above it, which longer name needs more of.
  let
    middle = width / 2
    (tail, head) = (middle - 15, middle + 15)
  &"""<svg viewBox="0 0 {numeral(width)} 30" width="{numeral(width)}" height="30"""" &
      " aria-hidden=\"true\">" &
      &"""<text x="{numeral(middle)}" y="9" text-anchor="middle" style="font: 8px""" &
      &""" 'Noto Sans', ui-sans-serif, system-ui, sans-serif; fill: {FAINT}">{label}""" &
      "</text>" &
      &"""<path d="M{numeral(tail)} 20 L{numeral(head)} 20 M{numeral(tail + 5)} 15""" &
      &""" L{numeral(tail)} 20 L{numeral(tail + 5)} 25""" &
      &""" M{numeral(head - 5)} 15 L{numeral(head)} 20""" &
      &""" L{numeral(head - 5)} 25" fill="none" stroke="{QUIET}"""" &
      """ stroke-width="1.6" stroke-linecap="round"""" &
      """ stroke-linejoin="round"/></svg>"""


func singleTurnParts*(): Parts =
  ## Build every SVG single-hand turns page places.
  ##   Rule 16: single hand held above turns for ever, so no position is
  ##     ever refused and how far it has wound is not part of its state.
  ##     What is left is four quarter-turn orientations per connection.
  ##   Rule 19: four manners of turn reach them -- each dancer's own axis
  ##     turn and each dancer's orbit of other.
  ##   Rule 15: every position drawn, every edge animated.
  ##   Rule 25: framed on lead, who therefore falls on same spot in
  ##     every cell -- which only reads if cells beside each other hold
  ##     same bounds.
  ##     Row of positions takes one set of bounds for whole page, since every
  ##       position stands same distance apart.  Row of transitions
  ##       takes one set of bounds per manner of turn, because lead who walks
  ##       ring needs room lead who stands still does not, and spending
  ##       that room on every cell of every row would shrink all of them.
  ##     Each cell is then given what its bounds need at scale its own row
  ##       draws at, so marks stay size they were and it is
  ##       cells that grow.
  var
    walks: array[Manner, array[QUARTERS_ROUND, Walk]]
    still_half = 0.0
    walk_half: array[Manner, float]
  for manner in Manner:
    let description = MANNERS[manner]
    for quarter in 0..<QUARTERS_ROUND:
      still_half = max(still_half, extent(quarterPose(manner, quarter), has_captions = false))
      walks[manner][quarter] = turnWalk(
        quarterPose(manner, quarter),
        description.who,
        description.about,
        QUARTER,
        on = Anchor.Lead,
      )
      for put in walks[manner][quarter].poses:
        walk_half[manner] = max(walk_half[manner], extent(put, has_captions = false))

  # Whole round, walked in one figure.  Four quarters close it (rule 16), so
  # it needs no return leg: it ends where it set off.
  #   Its poses are ones four edges already pass through, so it asks bounds for
  #     nothing new -- which is measured here rather than assumed.
  var rounds: array[Manner, Walk]
  for manner in Manner:
    let description = MANNERS[manner]
    rounds[manner] = turnWalk(
      quarterPose(manner, 0),
      description.who,
      description.about,
      QUARTER,
      on = Anchor.Lead,
      steps = QUARTERS_ROUND,
      has_return = false,
    )
    for put in rounds[manner].poses:
      walk_half[manner] = max(walk_half[manner], extent(put, has_captions = false))

  for manner in Manner:
    let description = MANNERS[manner]
    for single_index, single in SINGLES:
      let levels = levelsFor(single.holds)

      # Every derived position of this manner.
      for quarter in 0..<QUARTERS_ROUND:
        result[&"st_{description.tag}_{single_index}_{quarter}"] = sized(
          renderFigure(
            "tiny",
            single.holds,
            levels,
            has_captions = false,
            pose = some quarterPose(manner, quarter),
            half = some still_half,
            should_clear_marks = true,
          ),
          "tiny",
          still_half,
          STILL_PIXELS,
        )

      # And every edge, walked in stages rule 18 asks for.
      for quarter in 0..<QUARTERS_ROUND:
        let to = (quarter + 1) mod QUARTERS_ROUND
        result[&"tr_{description.tag}_{single_index}_{quarter}_{to}"] = sized(
          animatedPoses(
            "mv",
            single.holds,
            walks[manner][quarter].poses,
            some walk_half[manner],
            levels,
            duration = WALK_SECONDS,
            times = walks[manner][quarter].times,
          ),
          "mv",
          walk_half[manner],
          PIXELS,
        )
        # Still stands in where motion is turned off, so it is settled
        # picture and bends by rule 22; moving figure it replaces is
        # rule's own exemption and stays straight.
        result[&"tr_{description.tag}_{single_index}_{quarter}_{to}_still"] = sized(
          renderFigure(
            "mv still",
            single.holds,
            levels,
            has_captions = false,
            pose = some quarterPose(manner, quarter),
            half = some walk_half[manner],
            should_clear_marks = true,
          ),
          "mv still",
          walk_half[manner],
          PIXELS,
        )

      # And whole round in one figure, at pace its own quarters run at:
      # four legs where edge has two, so twice their clock.
      result[&"rd_{description.tag}_{single_index}"] = sized(
        animatedPoses(
          "mv",
          single.holds,
          rounds[manner].poses,
          some walk_half[manner],
          levels,
          duration = 2 * WALK_SECONDS,
          times = rounds[manner].times,
        ),
        "mv",
        walk_half[manner],
        PIXELS,
      )
      result[&"rd_{description.tag}_{single_index}_still"] = sized(
        renderFigure(
          "mv still",
          single.holds,
          levels,
          has_captions = false,
          pose = some quarterPose(manner, 0),
          half = some walk_half[manner],
          should_clear_marks = true,
        ),
        "mv still",
        walk_half[manner],
        PIXELS,
      )

  result["g_quarter"] = turnGlyph("&#188; turn")

  # Every position of round draws differently, or position it is not.
  for manner in Manner:
    for single_index in 0..<SINGLES.len:
      var seen: seq[string]
      for quarter in 0..<QUARTERS_ROUND:
        let figure = result[&"st_{MANNERS[manner].tag}_{single_index}_{quarter}"]
        doAssert figure notin seen,
          &"Two quarters draw alike; got `{quarter}` of `{manner}` on `{single_index}`."
        seen.add figure

  # Manners of one round walk it together, and manners of different rounds never
  # meet except where every round meets, at rest.
  for manner in Manner:
    for mate in Manner:
      var shared = 0
      for quarter in 0..<QUARTERS_ROUND:
        for other_quarter in 0..<QUARTERS_ROUND:
          if placeOf(quarterPose(manner, quarter)) ==
              placeOf(quarterPose(mate, other_quarter)):
            inc shared
      let is_same_round = LUT_ROUND_BY_MANNER[manner] == LUT_ROUND_BY_MANNER[mate]
      doAssert shared == (if is_same_round: QUARTERS_ROUND else: 1),
        &"A manner left its round; got `{shared}` shared of `{manner}` and `{mate}`."

  # And nothing on this page wraps body: reach is connection's own
  # stroke width, and one drawn with arc has walked round body.
  for key, figure in result:
    if not (key.startsWith("st_") or key.startsWith("tr_")):
      continue
    for piece in figure.split("<path "):
      if &"stroke-width=\"{LINK_WIDTH}\"" in piece:
        doAssert " A" notin piece,
          &"A reach walks round a body; got an arc in `{key}`."



#[ Hand-to-Hand Turns Page ]#

const
  HAND_TO_HAND*: Holds = [some Arm.Right, some Arm.Left]
    ## App's own two-hand frame: lead's Left in follow's right
    ## and lead's Right in follow's left, uncrossed.
  ABOVE_BOTH*: Levels = [some Level.Above, some Level.Above]
    ## Both arms over head, this scope's one level (rules 17, 21).
  HALF* = 180.0  ## Turn between one position and next (rule 28).

const STEPS* = [-1.5, -1.0, -0.5, 0.0, 0.5, 1.0, 1.5]
  ## One chain, in turns of wind from hold's own parallel state (rule 31).
  ##   Seven positions half turn apart: hold's own frame in middle,
  ##     rule 28's cross either side of it, rule 27's diamond beyond each
  ##     of those, and rule 13's extra arm twist -- **swan** -- at each end.
  ##   Steps are whole of chain; what differs between one hold
  ##     and another is only which facing sits at nothing wound, which is
  ##     half turn of offset rule 31 names, and that is measured rather
  ##     than written down here.


func windTwist*(wind: float): Twists =
  ## Say how far pair has wound, as drawing channel takes it.
  [wind, wind]


func posedAt*(wind, phase: float): Pose =
  ## Get pose hold stands in when it is wound this far from its own
  ## parallel state, that state being `phase` turns off Face-to-face.
  ##   Follow's own axis turn is what poses are built from, so
  ##     half turn faces them away where they stand and whole turn brings
  ##     everything back.  Which dancer did turning is not something
  ##     position can say; page animates all of them.
  result = canonicalise(
    turned(rest(), Dancer.Follow, About.Axis, 2 * HALF * (wind + phase)),
    on = Anchor.Lead,
  )
  result.ring = none(Ring)


func phaseOf*(holds: Holds): float =
  ## Say how far off Face-to-face this hold's two connections run parallel:
  ## phase of chain it sits on (rule 31).
  ##   Measured, in rule 28's habit: hold is parallel where angle
  ##     its two ends make with pair's axis agree, and `windOf` is
  ##     already thing that measures that.
  ##   Two candidates and no more, because chain steps by half turns:
  ##     hand to hand runs parallel with partners Face-to-face,
  ##     crossed pair Face-to-back, and those are
  ##     same chain read half turn apart.
  for phase in [0.0, 0.5]:
    let put = settled(posedAt(0.0, phase), holds, ABOVE_BOTH, default(Modifiers))
    if abs(windOf(put, holds, Arm.Left).spread) < 1e-6:
      return phase
  raise newException(Defect, &"A hold runs parallel at neither phase; got `{holds}`.")


func facingAt*(holds: Holds, wind: float): Option[Facing] =
  ## Name facing hold's chain stands at `wind` turns from its rest, read off
  ## pose through model.
  facingOf(posedAt(wind, phaseOf(holds)))


func restOf*(holds: Holds): Facing =
  ## Name facing hold rests at (rule 31).
  ##   Hold rests where its two connections run parallel and cross nothing,
  ##     which `phaseOf` measures: Face-to-face for hand to hand, Face-to-back
  ##     for crossed pair.  Hold with fewer than two connections has no such state,
  ##     and rests Face-to-face.
  if holds.countIt(it.isSome) < 2: Facing.FaceToFace
  else: facingAt(holds, 0.0).get


func chainFor*(holds: Holds): seq[Position] =
  ## Lay out chain one hold walks: every step of it, named and noted.
  ##   Shape is glossary's word for that step of chain -- **neutral**,
  ##     **cross**, **diamond**, **swan** -- which is why neither `x` nor
  ##     `box` appears here: glossary names both as words to avoid.
  ##   Middle said `open` until Architect ruled otherwise: `open` is what one
  ##     arm is, on neither face of its own body, and sweeps show arm open at
  ##     many twists while pair carrying no twist may hold two wrapped arms.
  ##   Which arm is over is preliminary and user's: position is called
  ##     for whichever of lead's arms passes over other at lead's
  ##     own crossover, and for shape pair makes there.
  # Asked for its refusal alone: hold that runs parallel at neither
  # phase cannot walk chain, and dies here rather than mid-table.
  discard phaseOf(holds)
  for wind in STEPS:
    let
      shape = case int(abs(wind) * 2)
              of 0: &"Left-to-{handName(holds[Arm.Left].get)} and " &
                  &"Right-to-{handName(holds[Arm.Right].get)}"
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
    # every caption saying it over: Face-to-face at whole number of
    # turns, Face-to-back at half.  It is also whole of offset
    # between this hold and its dual (rule 31).
    result.add (wind,
      # Middle of chain is glossary's **neutral**, and it alone says
      # which hands are joined, since every other position inherits that.
      if abs(wind) < 1e-9: &"{shape} neutral"
      elif wind > 0: &"Left over Right {shape}"
      else: &"Right over Left {shape}",
      far)


const
  HAND_PHASE* = phaseOf(HAND_TO_HAND)
    ## Hand to hand runs parallel with partners facing one another, so
    ## its chain sits at nothing -- measured on every build, not assumed.
  CHAIN* = chainFor(HAND_TO_HAND)  ## Seven positions this page holds, in chain order.


func handPose*(wind = 0.0): Pose =
  ## Get pose one position of this page's chain stands in.
  posedAt(wind, HAND_PHASE)


func pairAt*(holds: Holds; wind, phase: float): array[Arm, seq[Point]] =
  ## Two reaches position draws, made as drawing makes them.
  let
    put = settled(posedAt(wind, phase), holds, ABOVE_BOTH, default(Modifiers))
    hands = handsOf(put)
  for arm in Arm:
    result[arm] = wound(
      hands[Dancer.Lead][arm],
      hands[Dancer.Follow][holds[arm].get],
      axisOf(put).across,
      degToRad(windOf(put, holds, arm).phi),
      2 * PI * wind,
      share = windShare(wind, arm),
    )


func windSense*(manner: Manner): float =
  ## Say which way along chain positive turn by this manner winds.
  ##   Measured, not tabulated (rule 30, and rule 28's habit): turn
  ##     quarter from frame and read wind off farthest pose it
  ##     passes through.
  ##   Farthest, not last: walk rocks out to its turn and back
  ##     again, so it ends where it began and end says nothing.
  ##   Quarter, because half turn's wind sits exactly on `wrap180`'s
  ##     seam and so carries no sign to read.
  ##   Manner that winds nothing at all would take forward sense, having
  ##     no end to walk off side of.  Since rule 32 there is no such
  ##     manner -- every one of four winds -- and fallback stands only
  ##     so manner that stopped winding could not silently freeze.
  let description = MANNERS[manner]
  var turned_by = 0.0
  for put in turnWalk(handPose(), description.who, description.about, HALF / 2,
                      on = Anchor.Lead).poses:
    let spread = windOf(
      settled(put, HAND_TO_HAND, ABOVE_BOTH, default(Modifiers)),
      HAND_TO_HAND,
      Arm.Left,
    ).spread
    if abs(spread) > abs(turned_by):
      turned_by = spread
  if turned_by < -1e-9: -1.0 else: 1.0


const PAIRED*: Holds = [some Arm.Left, some Arm.Right]
  ## Same-name chain: lead's left to follow's left, right to right.  Index is
  ## lead's arm and value is follow's it joins, as `HAND_TO_HAND` is read.
  ##   Rests Face-to-back rather than Face-to-face, since Face-to-face its two
  ##     connections lie through each other (rule 31).


func chainTurnParts*(holds: Holds, key: string): Parts =
  ## Build every SVG one chain's turns page places, keyed under `key`.
  ##   Two chains are drawn -- hand to hand, and same-name pair -- and they
  ##     differ only in which hands are joined and where chain rests.  Written
  ##     once and called twice rather than copied: what is true of walking one
  ##     is true of walking other, and second copy is second thing to get wrong.
  ##   Rules 28 and 31: seven positions, half turn apart -- frame,
  ##     cross either side of it, diamond beyond each cross, and swan
  ##     beyond each diamond.
  ##   Rule 15: every position drawn, every edge animated, by every manner
  ##     of turn.
  ##   Rule 32: all four of them walk chain, since orbit that keeps
  ##     its side to centre winds pair as far as it carries
  ##     walker.  Which is measured rather than claimed, as it was when
  ##     answer was other one.
  let
    chain = chainFor(holds)
    phase = phaseOf(holds)
  var
    walks: array[Manner, seq[Walk]]
    still_half = 0.0
    walk_half: array[Manner, float]
  for position in chain:
    still_half = max(still_half, extent(posedAt(position.wind, phase), has_captions = false))
  for manner in Manner:
    let
      description = MANNERS[manner]
      sense = windSense(manner)
    walks[manner] = newSeq[Walk](chain.len - 1)
    for i in 0 ..< chain.len - 1:
      # Each edge starts where it starts and turns half, so manner that
      # winds walks one step along chain and manner that does not
      # simply carries pair out and back.
      #   Which way it turns is manner that walks chain *inward*,
      #     because ends of chain are ends (rule 30): positive
      #     turn by lead unwinds what positive turn by follow
      #     winds, so turning both same way sent lead's edges off
      #     end into second diamond.
      walks[manner][i] = turnWalk(
        posedAt(chain[i].wind, phase),
        description.who,
        description.about,
        HALF * sense,
        on = Anchor.Lead,
      )
      for put in walks[manner][i].poses:
        walk_half[manner] = max(walk_half[manner], extent(put, has_captions = false))

  # Whole chain, walked in one figure: six halves out from one swan to
  # other, and back.  Chain has ends (rule 30), so unlike round it cannot
  # close and takes return leg.
  var chains: array[Manner, Walk]
  for manner in Manner:
    let description = MANNERS[manner]
    chains[manner] = turnWalk(
      posedAt(chain[0].wind, phase),
      description.who,
      description.about,
      HALF * windSense(manner),
      on = Anchor.Lead,
      steps = chain.len - 1,
    )
    for put in chains[manner].poses:
      walk_half[manner] = max(walk_half[manner], extent(put, has_captions = false))

  # Chain, drawn once: all four manners reach these same seven (rule 32), so
  # drawing them per manner would be same picture over again.
  for i, position in chain:
    result[&"{key}h_{i}"] = sized(
      renderFigure(
        "tiny",
        holds,
        ABOVE_BOTH,
        has_captions = false,
        pose = some posedAt(position.wind, phase),
        half = some still_half,
        twist = windTwist(position.wind),
        should_clear_marks = true,
      ),
      "tiny",
      still_half,
      STILL_PIXELS,
    )

  # And every edge of it, walked by every manner of turn.
  for manner in Manner:
    let description = MANNERS[manner]
    for i in 0 ..< chain.len - 1:
      result[&"{key}w_{description.tag}_{i}"] = sized(
        animatedPoses(
          "mv",
          holds,
          walks[manner][i].poses,
          some walk_half[manner],
          ABOVE_BOTH,
          duration = WALK_SECONDS,
          times = walks[manner][i].times,
          wound = chain[i].wind,
        ),
        "mv",
        walk_half[manner],
        PIXELS,
      )
      # Still stands in where motion is turned off, so it is
      # picture move sets off from (rule 22's exemption again).
      result[&"{key}w_{description.tag}_{i}_still"] = sized(
        renderFigure(
          "mv still",
          holds,
          ABOVE_BOTH,
          has_captions = false,
          pose = some posedAt(chain[i].wind, phase),
          half = some walk_half[manner],
          twist = windTwist(chain[i].wind),
          should_clear_marks = true,
        ),
        "mv still",
        walk_half[manner],
        PIXELS,
      )

    # And whole chain in one figure, at pace its own edges run at: six legs
    # out and six back where edge has one of each.
    result[&"{key}c_{description.tag}"] = sized(
      animatedPoses(
        "mv",
        holds,
        chains[manner].poses,
        some walk_half[manner],
        ABOVE_BOTH,
        duration = float(chain.len - 1) * WALK_SECONDS,
        times = chains[manner].times,
        wound = chain[0].wind,
      ),
      "mv",
      walk_half[manner],
      PIXELS,
    )
    result[&"{key}c_{description.tag}_still"] = sized(
      renderFigure(
        "mv still",
        holds,
        ABOVE_BOTH,
        has_captions = false,
        pose = some posedAt(chain[0].wind, phase),
        half = some walk_half[manner],
        twist = windTwist(chain[0].wind),
        should_clear_marks = true,
      ),
      "mv still",
      walk_half[manner],
      PIXELS,
    )

  # Narrow, because chain is seven long now and glyph stands
  # between every pair of them (rule 31).
  result["g_half"] = turnGlyph("a half turn", 52.0)

  # Every position draws differently, or they are not seven positions.
  for i in 0..<chain.len:
    for j in 0..<i:
      doAssert result[&"{key}h_{i}"] != result[&"{key}h_{j}"],
        &"Two positions draw alike; got `{i}` and `{j}` under `{key}`."


func handTurnParts*(): Parts = chainTurnParts(HAND_TO_HAND, "h")
  ## Hand-to-hand chain: sections C and F.

func pairTurnParts*(): Parts = chainTurnParts(PAIRED, "p")
  ## Same-name pair's chain: sections D and G.
