## Draw one dancer: circle, with small chevron at its centre for
## facing.
##
##   Boundary is one polar function, `outlineR`, shared by drawing,
##     hands and routing -- so "on border" is true by
##     construction rather than by two pieces of code agreeing.
##     Cost of one polar boundary: every shape dancer could take must be
##       expressible as radius-by-bearing.  Accepted -- dancer seen from
##       above is round, and nothing on bench has wanted otherwise.
##   Rim is drawn quiet and whole, broken only where hand mark sits on
##     it: how far arm has been carried round is said by connection
##     wrapping body, not by second arc filling up around it.
##     Cost of quiet rim: arm carried past full turn looks like one
##       carried less.  Accepted while nothing on bench stores more than
##       one turn; README keeps question open.
##   Hands sit on rim, each in its own side's colour, lead's one shade
##     deeper than follow's.
##     Cost of hands on rim: hand cannot be drawn reaching across
##       body, so what arm does is said entirely by its connection.
##       Accepted -- rule 3 places hands at rim's slots and nowhere else.
##   Six spots of rule 3 are bearings off dancer's own facing, never
##     off page: turn dancer and their spots turn too.
##     Cost of dancer-relative bearings: reader comparing two dancers'
##       spots must turn one in their head.  Accepted -- rule is worded
##       from dancer's own front, and drawing follows rule.

{.experimental: "strictFuncs".}

import std/[math, options, strformat]

import ./[geometry, pose, style, terms]


const
  BODY_R* = 20.0     ## Dancer, seen from above; their hands sit on it.
  RIM_W* = 2.2       ## One width for whole boundary.

const
  CHEV_OUT* = 7.0    ## How far centred chevron reaches forward.
  CHEV_BACK = 1.0   ## And how little it reaches back.
  CHEV_HALF = 5.0   ## Half its width, well inside rim.
  CHEV_W = 1.6      ## Width its two legs are drawn at.

const
  RIM_STEP* = 3.0    ## Degrees between samples when route walks rim.
  ARM_REST* = 90.0   ## Resting hand, one quarter of rim from front.
  HAND_R* = 6.0      ## Hand mark's radius, or half its side.
  CAPTION_R* = BODY_R + HAND_R + 2   ## Just past hand that caption names.
  FREE_FADE* = 0.5   ## How far hand nobody holds fades, keeping its hue.

const SLOT_OFFSET* = 44.0
  ## How far round rim `front` and `back` sit from side.
  ##   Wide enough that no two marks ever touch -- two need 34.9 degrees on
  ##     this rim -- and narrow enough that spot still belongs to its own
  ##     side.  Drawn convention, not something dance says; README
  ##     keeps it on open list.

const HAND_GAP* = radToDeg(arcsin((HAND_R + CAP) / BODY_R))
  ## Rim's clearance around hand mark: same reach connection
  ## keeps, turned into arc, so boundary and reach stop at one border.

const
  MARK_STROKE* = 1.5   ## Width hand mark is outlined at.
  SEEN_GAP* = 1.2      ## Plain daylight between reach and what it clears.
  CHEVRON_STEPS* = 6   ## Discs along one leg of chevron, so V is kept
                       ## clear as shape it is.

const
  LEAD_CLEAR* = HAND_R * sqrt(2.0) + MARK_STROKE / 2 + CAP + SEEN_GAP
    ## How far settled reach stays off lead's hand: their mark is
    ## square, so its corner is far part of it (rule 22).
  FOLLOW_CLEAR* = HAND_R + MARK_STROKE / 2 + CAP + SEEN_GAP
    ## And off follow's, whose mark is circle.
  CHEVRON_CLEAR* = CHEV_W / 2 + CAP + SEEN_GAP
    ## And off chevron's stroke.
    ##   Chevron is kept clear along its own two legs rather than as one
    ##     disc over whole of it: it is thin V pointing forward, and
    ##     disc that covered its apex would swallow middle of body and
    ##     send every reach right round outside -- which is wrap
    ##     rule 14 forbids.  So shape is cleared as it is drawn.


type Free* {.pure.} = enum ## Say how hand nobody holds is drawn.
  Fade,                    ## Half strength, keeping its hue: free hand.
  Grey                     ## Quiet outline: ghost of place hand left.



#[ Six Spots ]#

func slotBearing*(arm: Arm; slot: Slot): float =
  ## Get where one of six spots sits, as bearing off body's facing.
  ##   Two sides, and on each place where arm hangs, one spot
  ##     slightly towards dancer's front and one slightly towards their
  ##     back -- rule 3's six, named for what they are.
  let
    base = if arm == Arm.L: -ARM_REST else: ARM_REST
    forward = if arm == Arm.L: SLOT_OFFSET else: -SLOT_OFFSET
  base + (case slot
          of Slot.Front: forward
          of Slot.Back: -forward
          of Slot.Default: 0.0)


func slotOf*(arm: Arm; level: Option[Level]; way: Option[Way]):
    tuple[arm: Arm, slot: Slot] =
  ## Get one of six spots this hand settles in: whose side, how far round.
  ##   `above` never settles anywhere but its own side's default (rule 8).
  let settled = settleOf(level, way)
  if settled.isNone:
    return (arm, Slot.Default)
  ((if settled.get.whose == Whose.Own: arm else: other(arm)),
   settled.get.slot)


func roundOf*(level: Option[Level]; way: Option[Way]): Option[Sends] =
  ## Get which way round body this hold sends its line, where rules 4 to
  ## 6 say anything; none where nothing is said and short way is taken.
  let settled = settleOf(level, way)
  if settled.isSome: some settled.get.sends else: none(Sends)


func handBearing*(facing: float; arm: Arm; wind = 0.0): float =
  ## Get bearing hand sits at: round from front, past rest spot
  ## by however far arm has been carried.
  facing + (if arm == Arm.L: -1.0 else: 1.0) * (ARM_REST + wind)


func settledWind*(arm: Arm; level: Option[Level]; way: Option[Way]): float =
  ## Get winding that puts this hand in its slot.
  ##   Winding is measured off hand's own side and runs towards back
  ##     for either hand, so this is only place two conventions are
  ##     reconciled.
  let
    landed = slotOf(arm, level, way)
    aim = slotBearing(landed.arm, landed.slot)
  if arm == Arm.L: -ARM_REST - aim else: aim - ARM_REST


func handPoint*(centre: Point; facing: float; arm: Arm; wind = 0.0): Point =
  ## Get where one hand is on rim.
  polar(centre.x, centre.y, BODY_R, handBearing(facing, arm, wind))


func handsOf*(pose: Pose): array[Dancer, array[Arm, Point]] =
  ## Get where all four hands are.
  for who in Dancer:
    for arm in Arm:
      result[who][arm] = handPoint(
        pose.place[who], pose.facing[who], arm, pose.wind[who][arm])



#[ Boundary ]#

func outlineR*(delta: float): float =
  ## Get how far boundary is from centre at this bearing off
  ## front.
  ##   One function, used by drawing and by anything that has to stay
  ##     outside body -- so "on border" is true by construction.
  ##     Body is plain circle now; function stays because routing
  ##     reads boundary through it.
  BODY_R


func outlinePoint*(centre: Point; facing, theta: float): Point =
  ## Get boundary point at world bearing.
  polar(centre.x, centre.y, outlineR(theta - facing), theta)


func rim*(centre: Point; facing, a, b: float; width = RIM_W): string =
  ## Draw one stretch of boundary, once and by one owner.
  let
    span = b - a
    start = outlinePoint(centre, facing, a)
    stop = outlinePoint(centre, facing, b)
    large = if abs(span) > 180: 1 else: 0
    sweep = if span > 0: 1 else: 0
    d = &"M{xy(start)} A{n(BODY_R)} {n(BODY_R)} 0 {large} {sweep} {xy(stop)}"
  &"""<path d="{d}" fill="none" stroke="{QUIET}" stroke-width="{width}"""" &
    " stroke-linecap=\"round\" stroke-linejoin=\"round\"/>"


func chevronPoints*(centre: Point; facing: float): array[3, Point] =
  ## Get three points chevron is drawn through: wing, apex,
  ## other wing.
  ##   One source for shape, so drawing and anything that has to
  ##     keep off it read same V (rule 22).
  let
    rad = degToRad(facing)
    fwd = (x: sin(rad), y: -cos(rad))
    across = (x: cos(rad), y: sin(rad))
  [(centre.x - fwd.x * CHEV_BACK - across.x * CHEV_HALF,
    centre.y - fwd.y * CHEV_BACK - across.y * CHEV_HALF),
   (centre.x + fwd.x * CHEV_OUT, centre.y + fwd.y * CHEV_OUT),
   (centre.x - fwd.x * CHEV_BACK + across.x * CHEV_HALF,
    centre.y - fwd.y * CHEV_BACK + across.y * CHEV_HALF)]


func chevron*(centre: Point; facing: float): string =
  ## Say facing, small and at centre of body.
  ##   In middle rather than on rim, because rim breaks for
  ##     hands and carries nothing else.  Centre is only part of
  ##     dancer nothing else uses.
  let
    drawn = chevronPoints(centre, facing)
    (a, apex, b) = (drawn[0], drawn[1], drawn[2])
  &"""<polyline points="{n(a.x)},{n(a.y)} {n(apex.x)},{n(apex.y)}""" &
    &""" {n(b.x)},{n(b.y)}" fill="none" stroke="{QUIET}"""" &
    &" stroke-width=\"{n(CHEV_W)}\" stroke-linecap=\"round\"" &
    " stroke-linejoin=\"round\"/>"


func border*(pose: Pose; who: Dancer): string =
  ## Draw dancer's whole boundary: one quiet outline, broken at hands.
  ##   It says nothing but *here is body*.  Rim used to fill up in
  ##     arm's colour as that arm wound round -- second progress ring
  ##     saying what connection already says by wrapping -- so ring
  ##     is gone and line keeps job.
  let
    centre = pose.place[who]
    facing = pose.facing[who]
    wind = pose.wind[who]
    right = ARM_REST + wind[Arm.R]
    left = ARM_REST + wind[Arm.L]
    # Every stretch stops one hand-gap short of hand, so boundary never
    # runs through mark -- and stretch that extreme winding has squeezed
    # away is simply not drawn.
    stretches = [
      (right + HAND_GAP, 360 - left - HAND_GAP),        # behind
      (360 - left + HAND_GAP, 360 + right - HAND_GAP),  # across front
    ]
  for (a, b) in stretches:
    if b - a > 0.01:
      result.add rim(centre, facing, facing + a, facing + b)



#[ Hands and Furniture ]#

func fillOf*(level: Option[Level]; arm: Arm; deep = false): string =
  ## Get fill that level draws as -- only place level becomes fill,
  ## so hands and pips cannot drift.
  if level == some(Level.Low):
    return if deep: DEEP[arm] else: INK[arm]
  if level == some(Level.Above):
    return &"url(#h{arm}{(if deep: \"d\" else: \"\")})"
  "none"


func hand*(cx, cy: float; leads: bool; arm: Arm; held = true;
    level = none(Level); free = Free.Fade): string =
  ## Draw one hand, in its own side's ink: lead's deep, follow's
  ## plain.
  let
    ink = if leads: DEEP[arm] else: INK[arm]
    stroke = if held or free == Free.Fade: ink else: QUIET
    fill = if held: fillOf(level, arm, leads) else: "none"
    faded = if held or free != Free.Fade: ""
            else: &" opacity=\"{FREE_FADE}\""
    dot = if level == some(Level.High):
            &"""<circle cx="{n(cx)}" cy="{n(cy)}" r="2.7" fill="{stroke}"/>"""
          else: ""
    style = &"fill: {fill}; stroke: {stroke}; stroke-width: 1.5"
    shape =
      if leads:
        &"""<rect x="{n(cx - HAND_R)}" y="{n(cy - HAND_R)}"""" &
          &""" width="{n(2 * HAND_R)}"""" &
          &""" height="{n(2 * HAND_R)}" rx="1.5" style="{style}"{faded}/>"""
      else:
        &"""<circle cx="{n(cx)}" cy="{n(cy)}" r="{n(HAND_R)}" style="{style}"""" &
          &"{faded}/>"
  shape & dot


func ringOf*(pose: Pose): string =
  ## Draw orbit, only while one is happening.
  ##   Nothing else in picture is dashed, so dashed circle says one
  ##     thing: somebody is going round somebody.  It is centred on whoever
  ##     is standing still -- partner, or midpoint when both travel.
  if pose.ring.isNone:
    return ""
  let (centre, radius) = pose.ring.get
  &"""<circle cx="{n(centre.x)}" cy="{n(centre.y)}" r="{n(radius)}"""" &
    &""" fill="none" stroke="{QUIET}" stroke-width="1"""" &
    """ stroke-dasharray="3 4"/>"""


func caption*(centre: Point; facing: float; arm: Arm; text: string;
    wind = 0.0; ink = FAINT): string =
  ## Set hand's name just past it, growing outwards, in that hand's own ink.
  ##   Caption names one hand, and hand is drawn in colour that says
  ##     whose it is, so word that names it is written in same one --
  ##     mark and its name are then one thing said twice rather than
  ##     two things reader has to pair up.
  ##   Lead's captions take deep shade and follow's plain,
  ##     as marks below them do.
  let
    p = polar(centre.x, centre.y, CAPTION_R, handBearing(facing, arm, wind))
    dx = p.x - centre.x
    (anchor, dy) =
      if dx < -2: ("end", 3.0)
      elif dx > 2: ("start", 3.0)
      else: ("middle", if p.y < centre.y: -3.0 else: 8.0)
  &"""<text x="{n(p.x)}" y="{n(p.y + dy)}" text-anchor="{anchor}"""" &
    " style=\"font: 8px 'Noto Sans', ui-sans-serif, system-ui, sans-serif;" &
    &""" fill: {ink}">{text}</text>"""
