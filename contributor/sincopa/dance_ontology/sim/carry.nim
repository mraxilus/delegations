## Turn couple as sim turns them, apart from any page that shows it.
##
##   Model behind browser page lives here so it can be driven under test:
##     `page.nim` reaches for `std/dom`, so it builds only on JS backend and
##     no suite can import it.  Everything that decides what arms do is here;
##     everything that draws or listens is there.
##   Controls are dance's freedoms and none of rig's: which hands are held,
##     at which level, and one quarter turn per move for either dancer -- on
##     their own axis, or in orbit round their partner, where walker keeps
##     facing centre and so turns as far as they travel (project's rule 32).
##     Bodies are average adult's and do not change.
##   How far apart couple stand is not control either: they stand, and go on
##     standing as they turn, wherever joints are furthest from their limits
##     -- stepping in or out one centimetre each time whenever that leaves
##     arms freer, and never closer than ten centimetres of clear air between
##     torsos, whichever way they face.
##   Quarter is walked in small moves, as sweeps walk turn, so wound arm stays
##     wound; where no small move holds whole quarter is refused -- couple are
##     put back where they started it, and page says how far it got and what
##     blocked it -- so tallies are always whole quarters.
##   Pose is never settled afresh mid-turn -- fresh pose has no memory, and
##     would lay arm through body as happily as round it -- except one
##     re-organisation sweep allows too, to pose that goes round bodies same
##     way.  Changing hands or level settles pose afresh, face to face.
##   Levels carry sheet's names -- low, high, above -- which is one
##     translation this makes, as `sim/verdicts` makes it; model underneath
##     knows only torso, neck and crown.
##   State is module's own, since one page shows one couple; test drives it
##     through same doors page does.

{.experimental: "strictFuncs".}

import std/[math, options, strformat, strutils]

import ./[body, draw, limb, read, rig, solve, sweep, vec]


type
  Hold* = object ## One way of holding hands: which of his to which of hers.
    name*: string
    links: seq[tuple[a, b: Arm]] ## Lead's hand, follow's hand.
    away: bool ## Rests with follow turned away: its connections lie
               ## through each other face to face.

  Way* {.pure.} = enum ## Four ways quarter can be turned.
    LeadAxis, FollowAxis, FollowOrbit, LeadOrbit

  Move* = object ## One quarter, one way, one sense.
    way*: Way
    sign*: float ## Anticlockwise seen from above positive.


const
  HOLDS* = [
    Hold(name: "L–l", links: @[(Arm.Left, Arm.Left)]),
    Hold(name: "R–r", links: @[(Arm.Right, Arm.Right)]),
    Hold(name: "L–r", links: @[(Arm.Left, Arm.Right)]),
    Hold(name: "R–l", links: @[(Arm.Right, Arm.Left)]),
    Hold(name: "L–l · R–r", links: @[(Arm.Left, Arm.Left), (Arm.Right, Arm.Right)], away: true),
    Hold(name: "L–r · R–l", links: @[(Arm.Left, Arm.Right), (Arm.Right, Arm.Left)]),
  ] ## Base set: lead's hand first, in capitals, follow's after.
  LEVELS* = [("low", Band.Torso), ("high", Band.Neck), ("above", Band.Crown)]
  WAYS*: array[Way, string] = ["lead turns", "follow turns",
                              "follow orbits the lead", "lead orbits the follow"]
  QUARTER = 0.25 ## Turns per press.
  REST_APART = 0.40 ## Where couple stand before arms have say.
  APART_STEP = 0.01 ## How far they step in or out each time.
  APART_MOST = 0.90 ## Further than this no hold reaches anyway.
  GAP = 0.10 ## Least clear air between torsos, metres.
  PER_FRAME = 8 ## Small moves made per frame before page is redrawn.
  SHIFTS = 3 ## Steps in or out tried after each small move of turn.
  SETTLING_SHIFTS = 40 ## And from fresh rest, before first turn.


var
  hold* = 2 ## Into `HOLDS`.
  level* = 0 ## Into `LEVELS`.
  carried*: Option[Solved] ## Pose arms are in, where bodies are.
  carriedKey* = "" ## What that pose is of, so changed hold settles afresh.
  restApart* = REST_APART ## Where couple stood at last fresh rest.
  tally*: array[Way, float] ## Turns made each way since rest, signed.
  inFlight*: Option[Move] ## Quarter being walked, if one is.
  done* = 0.0 ## How much of it has been walked, nought to one.
  moveStart*: Option[Solved] ## Where quarter in flight set off from.
  tallyStart*: array[Way, float] ## And tallies then.
  reseedsStart* = 0
  blocked*: Option[Verdict] ## What refused last quarter asked for.
  blockedWay = Way.LeadAxis ## Which quarter that was,
  blockedAfter = 0.0 ## and how far into it arms got, in turns.
  reseeds* = 0 ## Fresh poses taken since rest where no small move held.


func esc*(text: string): string =
  text.multiReplace(("&", "&amp;"), ("<", "&lt;"), (">", "&gt;"))


#[ World ]#

proc world*(apart = REST_APART): State =
  ## Hold at rest, face to face -- or follow away, where hold
  ## rests so -- with nothing solved yet.
  let h = HOLDS[hold]
  result = State(rig: HUMAN, stance: facing(HUMAN, apart), band: LEVELS[level][1])
  if h.away:
    result.stance[Body.Two].facing = result.stance[Body.Two].facing - PI
  for (a, b) in h.links:
    result.links.add Link(ends: [(Body.One, a), (Body.Two, b)])

func keyOf*(s: State): string =
  ## What pose is pose of, apart from where bodies are.
  result = &"{ord(s.band)}"
  for link in s.links:
    result.add &"/{ord(link.ends[0].arm)}{ord(link.ends[1].arm)}"

func apartOf(st: array[Body, Stance]): float =
  let
    dx = st[Body.Two].centre.x - st[Body.One].centre.x
    dy = st[Body.Two].centre.y - st[Body.One].centre.y
  sqrt(dx * dx + dy * dy)

func withStance(s: State; st: array[Body, Stance]): State =
  result = s
  result.stance = st

func orbited(st: array[Body, Stance]; who: Body; by: float): array[Body, Stance] =
  ## `who` walked round their partner by `by` radians, keeping whatever
  ## side of them faced centre facing it: their facing turns as far as
  ## they travel (rule 32).
  let
    pivot = st[if who == Body.One: Body.Two else: Body.One].centre
    dx = st[who].centre.x - pivot.x
    dy = st[who].centre.y - pivot.y
    c = cos(by)
    s = sin(by)
  result = st
  result[who].centre = (pivot.x + dx * c - dy * s, pivot.y + dx * s + dy * c)
  result[who].facing = st[who].facing + by

func stanceAfter(st: array[Body, Stance]; m: Move; frac: float): array[Body, Stance] =
  ## Bodies after `frac` of quarter move's way.
  let turns = m.sign * frac * QUARTER
  case m.way
  of Way.LeadAxis: turned(st, Body.One, turns)
  of Way.FollowAxis: turned(st, Body.Two, turns)
  of Way.FollowOrbit: orbited(st, Body.Two, turns * 2.0 * PI)
  of Way.LeadOrbit: orbited(st, Body.One, turns * 2.0 * PI)

func shifted(st: array[Body, Stance]; by: float): array[Body, Stance] =
  ## Follow moved `by` metres away from lead along line between
  ## their axes, lead standing still.
  let
    apart = apartOf(st)
    ux = (st[Body.Two].centre.x - st[Body.One].centre.x) / apart
    uy = (st[Body.Two].centre.y - st[Body.One].centre.y) / apart
  result = st
  result[Body.Two].centre = (st[Body.Two].centre.x + ux * by,
                             st[Body.Two].centre.y + uy * by)


func leastApart(rig: Rig; st: array[Body, Stance]): float =
  ## Closest two may stand, axis to axis, with `GAP` of clear air
  ## between their torsos along line between them, whichever way each
  ## faces: each torso's half-extent along that line, and gap.
  let
    apart = apartOf(st)
    dx = (st[Body.Two].centre.x - st[Body.One].centre.x) / apart
    dy = (st[Body.Two].centre.y - st[Body.One].centre.y) / apart
    a = halfBreadth(rig, Part.Torso)
    b = halfDepth(rig, Part.Torso)
  result = GAP
  for who in Body:
    let
      dr = dx * sin(st[who].facing) - dy * cos(st[who].facing)
      df = dx * cos(st[who].facing) + dy * sin(st[who].facing)
    result += sqrt((a * dr) * (a * dr) + (b * df) * (b * df))


#[ Carrying ]#

func agrees(here: Solved; there: Option[Solved]): bool =
  ## Whether pose found at next stance is one arms can be carried
  ## to from here: it holds, goes round bodies same way, and
  ## crosses same way.
  there.isSome and
    sameRoute(here.state, here.verdict, there.get.state, there.get.verdict) and
    sameCrossings(here.state, here.verdict, there.get.state, there.get.verdict)

func roomOf(rig: Rig; v: Verdict): float =
  ## Least room any held arm's joints have, either way.
  result = Inf
  for i in 0 ..< v.n:
    for k in 0 .. 1:
      result = min(result, room(rig, v.fits[i].joints[k]))

func freer(rig: Rig; a, b: Verdict): bool =
  ## Whether `a` leaves joints freer than `b`: nearest joint further
  ## from either end of its range first, and more comfortable where that
  ## is equal.
  ##   Freedom, not comfort, is what stance is chosen for: couple who
  ##     stood where arms hang easiest would stand at arm's length with
  ##     elbows straight, and straight elbow is joint with nowhere
  ##     to go.
  let
    ra = roomOf(rig, a)
    rb = roomOf(rig, b)
  if abs(ra - rb) > 1e-9: ra > rb
  else: a.cost < b.cost - 1e-9


proc steppedIn(here: var Solved): bool =
  ## Step couple in or out by one step where that leaves arms
  ## freer; whether they did.
  ##   Each way is first judged cheaply -- pose as it is, with
  ##     bodies moved -- and only way that promises is followed for
  ##     real, and taken only if it delivers.
  let
    apart = apartOf(here.state.stance)
    least = leastApart(here.state.rig, here.state.stance)
  var
    best = here.verdict
    by = 0.0
  for step in [-APART_STEP, APART_STEP]:
    if apart + step < least or apart + step > APART_MOST:
      continue
    let guess = evaluate(withStance(here.state, shifted(here.state.stance, step)))
    if freer(here.state.rig, guess, best):
      best = guess
      by = step
  if by == 0.0:
    return false
  let got = followed(withStance(here.state, shifted(here.state.stance, by)), here.state)
  if agrees(here, got) and freer(here.state.rig, got.get.verdict, here.verdict):
    here = got.get
    return true
  false


proc settleFresh*() =
  ## Hold at rest, solved from nothing, and couple stepped in or
  ## out from there until arms are as free as they get.
  var s = world()
  let least = leastApart(s.rig, s.stance)
  if apartOf(s.stance) < least:
    s = world(least)
  carried = settled(s)
  carriedKey = keyOf(s)
  for w in Way: tally[w] = 0.0
  inFlight = none(Move)
  moveStart = none(Solved)
  done = 0.0
  blocked = none(Verdict)
  reseeds = 0
  if carried.isSome:
    var here = carried.get
    for i in 0 ..< SETTLING_SHIFTS:
      if not steppedIn(here):
        break
    carried = some(here)
    restApart = apartOf(here.state.stance)


proc walked*(): bool =
  ## Walk quarter in flight on by several small moves; whether it has
  ## arrived or stopped.
  ##   Small move that no small motion reaches is tried once more as
  ##     sweep tries it, by fresh search held to same way round
  ##     bodies; failing that whole quarter is refused: couple go
  ##     back to where they set off from, and how far arms got and what
  ##     refused them is kept for page to say.
  if inFlight.isNone or carried.isNone:
    return true
  let m = inFlight.get
  var moves = 0
  while moves < PER_FRAME:
    if done >= 1.0 - 1e-9:
      inFlight = none(Move)
      return true
    let
      here = carried.get
      frac = min(1.0, done + CREEP / QUARTER)
      next = withStance(here.state, stanceAfter(here.state.stance, m, frac - done))
    var got = followed(next, here.state)
    if not agrees(here, got):
      got = settled(next)
      if agrees(here, got):
        inc reseeds
      else:
        blocked = some(reason(next, here.state))
        blockedWay = m.way
        blockedAfter = done * QUARTER
        carried = moveStart
        tally = tallyStart
        reseeds = reseedsStart
        inFlight = none(Move)
        return true
    var now = got.get
    tally[m.way] += m.sign * (frac - done) * QUARTER
    done = frac
    for i in 0 ..< SHIFTS:
      if not steppedIn(now):
        break
    carried = some(now)
    inc moves
  false


#[ Words ]#

func deg(r: float): string = $int(round(r * 180.0 / PI))

func turns*(x: float): string = formatFloat(x, ffDecimal, 2)

func whoseName(s: State; link, arm: int): string =
  if s.links[link].ends[arm].body == Body.One: "the lead" else: "the follow"

func dofName(dof: Dof): string =
  case dof
  of Dof.Extend: "shoulder, behind"
  of Dof.Across: "shoulder, across"
  of Dof.Twist: "shoulder, twist"
  of Dof.Bend: "elbow"
  of Dof.Wrist: "wrist"

func says*(s: State; v: Verdict): string =
  ## Say what refuses, in words rather than name.
  case v.reason
  of Reason.None: "holds"
  of Reason.Reach: whoseName(s, v.link, v.arm) & "'s reach"
  of Reason.Shoulder, Reason.Twist, Reason.Elbow, Reason.Wrist:
    whoseName(s, v.link, v.arm) & "'s " & dofName(v.dof)
  of Reason.Through:
    let part = case v.part
      of Part.Torso: "torso"
      of Part.Neck: "neck"
      of Part.Head: "head"
    whoseName(s, v.link, v.arm) & "'s arm through " &
      (if v.whose == Body.One: "the lead's " else: "the follow's ") & part
  of Reason.Arms: "arm through arm"
  of Reason.Band: "the hands out of their height"

func lies(l: Option[Lying]): string =
  ## Where arm lies on its own body, in body's words.
  if l.isNone:
    return "out in front"
  (if l.get.aspect == Aspect.Fore: "across the front" else: "behind the back") &
    (if l.get.pressing: ", pressing" else: ", clear of the body") &
    (if l.get.elbowFore: ", elbow forward" else: "")

proc linkName(i: int): string =
  ## Which hands connection `i` of hold joins.
  let (a, b) = HOLDS[hold].links[i]
  (if a == Arm.Left: "L" else: "R") & "–" & (if b == Arm.Left: "l" else: "r")


proc readout*(s: State; v: Verdict): string =
  ## Say what model makes of pose, arm by arm, and where couple
  ## have got to.
  var rows = ""
  for i in 0 ..< v.n:
    for k in 0 .. 1:
      let
        j = v.fits[i].joints[k]
        st = strain(s.rig, j)
        who = whoseName(s, i, k)
        ink = draw.INKS[i mod draw.INKS.len]
      rows.add &"""<tr><td><b style="color: {ink}">{esc(linkName(i))}</b> {who}</td>""" &
        &"<td>{deg(j.extend)}&deg; / {deg(j.across)}&deg;</td><td>{deg(j.twist)}&deg;</td>" &
        &"<td>{deg(j.bend)}&deg;</td><td>{deg(j.wrist)}&deg;</td>" &
        &"""<td class="{(if st.most >= 1.0: "short" else: "spare")}">""" &
        &"""{formatFloat(st.most, ffDecimal, 2)} ({dofName(st.dof)})</td>""" &
        &"<td>{lies(lyingOn(s, v, i, s.links[i].ends[k].body))}</td></tr>"
  var cross = ""
  for c in crossings(s, v):
    cross.add "<li>the connections cross in plan at (" &
      &"{formatFloat(c.at.x, ffDecimal, 2)}, {formatFloat(c.at.y, ffDecimal, 2)}); " &
      &"<b>{esc(linkName(c.over))}</b> is over</li>"
  var made = ""
  for w in Way:
    if abs(tally[w]) > 1e-9:
      made.add (if made.len > 0: ", " else: "") & &"{WAYS[w]} <b>{turns(tally[w])}</b>"
  if made.len == 0:
    made = if HOLDS[hold].away: "at rest, the follow turned away" else: "at rest, face to face"
  &"""<table class="says"><tr><th>arm</th><th>behind / across</th><th>twist</th>""" &
    "<th>elbow</th><th>wrist</th><th>strain</th><th>lies</th></tr>" & rows &
    "</table>" &
    &"""<p class="limit"><b>{esc(HOLDS[hold].name)}</b>, {LEVELS[level][0]}: {made}; """ &
    &"""the couple's twist is <b>{turns(twist(s.stance) / (2.0 * PI))} turns</b>, """ &
    &"""they stand <b>{turns(apartOf(s.stance))} m</b> apart, """ &
    &"""and the hands are at <b>{turns(s.params[0].g.z)} m</b>. """ &
    &"""The pose <b class="{(if v.ok: "spare" else: "short")}">{says(s, v)}</b>.""" &
    (if reseeds > 0: &" On the way here the arms re-organised " &
      &"{(if reseeds == 1: \"once\" else: $reseeds & \" times\")}: a fresh pose, " &
      &"the same way round the bodies, where no small move held." else: "") &
    (if blocked.isSome: &""" <b class="short">The next quarter that way is blocked</b> """ &
      &"""({WAYS[blockedWay]}): after {turns(blockedAfter)} of it, {says(s, blocked.get)}; """ &
      &"""the couple stay where they were.""" else: "") &
    "</p>" &
    (if cross.len > 0: &"<ul class=\"met\">{cross}</ul>" else: "")
