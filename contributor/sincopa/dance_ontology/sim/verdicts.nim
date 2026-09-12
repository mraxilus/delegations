## Write what sim says, as report, in words sheet uses.
##
##   Instrument run, not build step: `nim r tools/build.nim verdicts` writes
##     `sim/verdicts.md`.  Everything here is asked of `walk`, which stands couple
##     for turn they are about to take and walks them until something gives;
##     report only translates, once, and shows its translation table first.
##   Solver this once asked is gone.  What is asked has not changed; what answers
##     has, and figures in report are whatever it answers today.

{.experimental: "strictFuncs".}

import std/[math, options, strformat, strutils, tables, wordwrap]

import ./[body, hold, read, rig, rigid, vec, walk]


const
  BANDS = [("low", Band.Torso), ("high", Band.Neck), ("above", Band.Crown)]
    ## Sheet's word for each band, in order report tabulates them.
  HALVES = [-4, -3, -2, -1, 0, 1, 2, 3, 4] ## Turns asked, in half turns.
  WIDTH = 100 ## Columns report's prose wraps at.


func oneLink(a, b: Arm): seq[Link] =
  ## One connection, One's `a` to Two's `b`.
  @[Link(ends: [(Body.One, a), (Body.Two, b)])]

func twoLinks(a, b, c, d: Arm): seq[Link] =
  ## Both hands held: One's `a` to Two's `b`, One's `c` to Two's `d`.
  @[Link(ends: [(Body.One, a), (Body.Two, b)]),
    Link(ends: [(Body.One, c), (Body.Two, d)])]


func prose(text: string): string =
  ## Wrap paragraph at `WIDTH` columns, closing it with blank line.
  wrapWords(text, WIDTH, splitLongWords = false) & "\n\n"

func said(lying: Option[Lying]; band: Band): string =
  ## Write where held arm lies, in sheet's own words.
  ##   One translation table: across front = wrap, behind back = lock, torso band = low,
  ##     neck band = high, over crown = above; arm carried there but not pressing body is
  ##     *led*.
  if band == Band.Crown:
    return "above"
  if lying.isNone:
    return "open"
  let
    way = if lying.get.aspect == Aspect.Fore: "wrap" else: "lock"
    at = if lying.get.band == Band.Torso: "low" else: "high"
    held = if lying.get.pressing: "" else: " (led)"
    elbow =
      if lying.get.elbowFore and lying.get.aspect == Aspect.Aft: ", elbow forward" else: ""
  &"{way} {at}{held}{elbow}"

func dofName(dof: Dof): string =
  ## Name freedom in report's words.
  case dof
  of Dof.Extend: "behind"
  of Dof.Across: "across"
  of Dof.Twist: "twist"
  of Dof.Bend: "elbow"
  of Dof.Wrist: "wrist"

func whose(h: Hand): string =
  ## Name arm verdict is about: his or hers.
  if h.body == Body.One: "his" else: "her"

func why(w: Walk): string =
  ## Say what refuses, in words.
  if not w.stopped: return "holds"
  case w.why
  of Stop.None: "holds"
  of Stop.Reach: &"{whose(w.whose)} reach"
  of Stop.Swing: &"{whose(w.whose)} shoulder, swing"
  of Stop.Twist: &"{whose(w.whose)} shoulder, twist"
  of Stop.Elbow: &"{whose(w.whose)} elbow"
  of Stop.Wrist: &"{whose(w.whose)} wrist"
  of Stop.Through: &"{whose(w.whose)} arm through a body"
  of Stop.Arms: "arm through arm"

func turns(x: float): string = formatFloat(x, ffDecimal, 2)
  ## Render turns to two places.

func half(h: int): string =
  ## Render count of half turns as signed turns, e.g. `+1 1/2`.
  let sign = if h < 0: "-" elif h > 0: "+" else: ""
  let a = abs(h)
  sign & (if a mod 2 == 0: $(a div 2) else: (if a > 1: $(a div 2) & " 1/2" else: "1/2"))

func strainWord(t: Tight): string =
  ## Render strain with its nearness to edge.
  let s = formatFloat(t.strain, ffDecimal, 2)
  if t.strain >= 1.0: s & " (at the edge)" elif t.strain >= 0.7: s & " (near it)" else: s

func blockLine(w: Walk; sign: string): string =
  ## Say where sweep blocks one way and why, and where couple stood for it.
  if not w.stopped:
    return &"{sign}: no block within {turns(MOST)} turns, standing {turns(w.apart)} m"
  &"{sign}{turns(w.at)}: {why(w)}, standing {turns(w.apart)} m"

func blocks(sw: Swept): string =
  ## Say both blocks of sweep as one wrapped paragraph.
  prose(&"Blocks: {blockLine(sw.neg, \"-\")}; {blockLine(sw.pos, \"+\")}.")


#[ Sweeps, Once ]#

var sweeps: Table[string, Swept] ## Every sweep asked for, by what it is of.

func keyOf(band: Band; links: seq[Link]; who: Body; away: bool; apart: float): string =
  result = &"{ord(who)}|{ord(band)}|{away}|{apart}"
  for link in links:
    result.add &"|{ord(link.ends[0].arm)}{ord(link.ends[1].arm)}"

proc sweepOf(band: Band; links: seq[Link]; who = Body.Two; away = false;
             apart = 0.0): Swept =
  ## Read sweep of hold: from where it was asked before, else swept now.
  let key = keyOf(band, links, who, away, apart)
  if key notin sweeps:
    sweeps[key] = swept(HUMAN, band, links, who = who, most = MOST, away = away,
                        apart = apart)
  sweeps[key]

func momentAt(sw: Swept; t: float): Option[Moment] =
  ## Moment nearest `t` turns, from whichever way reaches it; none where neither does.
  let way = (if t < 0.0: sw.neg else: sw.pos)
  var best: Option[Moment]
  for m in way.moments:
    if abs(m.at - t) < 0.011 and (best.isNone or abs(m.at - t) < abs(best.get.at - t)):
      best = some m
  best


#[ Sections ]#

proc rigTable(): string =
  ## Tabulate rig's measurements.
  result.add "## The rig\n\n"
  result.add prose("Every measurement is a mixed-sex midpoint of ANSUR II medians; the " &
    "joints are the AAOS ranges held to what a dancer will do without pain.")
  result.add "| measure | value |\n|---|---|\n"
  result.add &"| torso round | {HUMAN.round[Part.Torso]} m, an ellipse " &
    &"{turns(2 * halfBreadth(HUMAN, Part.Torso))} across and " &
    &"{turns(2 * halfDepth(HUMAN, Part.Torso))} deep, hip {HUMAN.hip} to " &
    &"{HUMAN.top[Part.Torso]} m |\n"
  result.add &"| neck round | {HUMAN.round[Part.Neck]} m, radius " &
    &"{formatFloat(halfBreadth(HUMAN, Part.Neck), ffDecimal, 3)}, to {HUMAN.top[Part.Neck]} m |\n"
  result.add &"| head round | {HUMAN.round[Part.Head]} m, radius " &
    &"{formatFloat(halfBreadth(HUMAN, Part.Head), ffDecimal, 3)}, to {HUMAN.top[Part.Head]} m |\n"
  result.add &"| shoulders | {HUMAN.shoulderOut} m out, {HUMAN.shoulderUp} m up |\n"
  result.add &"| arm | upper {HUMAN.upper}, forearm {HUMAN.fore}, wrist to grip {HUMAN.hand}: " &
    &"reach {turns(reach(HUMAN))} m; limb radius {HUMAN.limb} |\n"
  let
    behind = int(round(HUMAN.range[Dof.Extend].hi * 180.0 / PI))
    twIn = int(round(-HUMAN.range[Dof.Twist].lo * 180.0 / PI))
    twOut = int(round(HUMAN.range[Dof.Twist].hi * 180.0 / PI))
    bend = int(round(HUMAN.range[Dof.Bend].hi * 180.0 / PI))
    wrist = int(round(HUMAN.range[Dof.Wrist].hi * 180.0 / PI))
  result.add &"| shoulder | {behind} degrees behind the frontal plane; across the body " &
    "the trunk is what stops it; " & &"twist {twIn} in to {twOut} out |\n"
  result.add &"| elbow | 0 to {bend} degrees |\n"
  result.add &"| wrist | a {wrist} degree cone |\n"
  result.add &"| hands | low {HUMAN.band[Band.Torso].lo}-{HUMAN.band[Band.Torso].hi}, " &
    &"high {HUMAN.band[Band.Neck].lo}-{HUMAN.band[Band.Neck].hi}, " &
    &"above {HUMAN.band[Band.Crown].lo}-{HUMAN.band[Band.Crown].hi} m |\n"
  result.add "| stance | chosen for each turn, from clear of each other outward |\n\n"


proc singleHolds(): string =
  ## Tabulate every one-hand hold at every band, follow turned.
  result.add "## One hand held, the follow turned\n\n"
  result.add prose("Counted from face-to-face, in turns, anticlockwise seen from above " &
    "positive.  Each row is the pose the arms carry to that turn; *strain* is how far " &
    "into the last stretch before a joint's edge the worst joint is (1 is the edge).")
  for (a, b, name) in [(Arm.Left, Arm.Left, "L-l"), (Arm.Right, Arm.Right, "R-r"),
                       (Arm.Left, Arm.Right, "L-r"), (Arm.Right, Arm.Left, "R-l")]:
    let links = oneLink(a, b)
    for (word, band) in BANDS:
      let sw = sweepOf(band, links)
      result.add &"### {name}, {word}\n\n"
      if not sw.restHolds:
        result.add "No pose holds at the rest.\n\n"
        continue
      result.add blocks(sw)
      result.add "| turn | her arm | his arm | strain | hands at |\n|---|---|---|---|---|\n"
      for h in HALVES:
        let t = h.float / 2.0
        let m = momentAt(sw, t)
        if m.isNone:
          result.add &"| {half(h)} | blocked | | | |\n"
          continue
        let
          mo = m.get
          tight = tightest(HUMAN, mo.stance, links, mo.arms)
          g = mo.arms[0][0].g
        result.add &"| {half(h)} | " &
          &"{said(lyingOn(HUMAN, band, links, mo.stance, mo.arms, 0, Body.Two), band)} | " &
          &"{said(lyingOn(HUMAN, band, links, mo.stance, mo.arms, 0, Body.One), band)} | " &
          &"{strainWord(tight)} | {turns(g.z)} m |\n"
      result.add "\n"


proc floorClaim(): string =
  ## Tabulate floor's claim beside sim's answer.
  result.add "## The floor's claim\n\n"
  result.add prose("The floor: *everything gets a full turn before it blocks, except a low " &
    "wrap, which gets half.*  L-l and L-r, turning her, from face-to-face.  For L-l the " &
    "lock way is negative and the wrap way positive; for L-r the wrap way is negative and " &
    "the lock way positive.")
  result.add "| hold | level | way | floor says | sim says | the sim names |\n" &
    "|---|---|---|---|---|---|\n"
  for (a, b, name, lockSign) in [(Arm.Left, Arm.Left, "L-l", -1.0),
                                 (Arm.Left, Arm.Right, "L-r", 1.0)]:
    for (word, band) in BANDS:
      let sw = sweepOf(band, oneLink(a, b))
      for (way, sign) in [("lock way", lockSign), ("wrap way", -lockSign)]:
        let w = if sign < 0: sw.neg else: sw.pos
        let floor = if band == Band.Crown: "no block"
                    elif band == Band.Torso and way == "wrap way": "half a turn"
                    else: "a whole turn"
        let says = if w.stopped: &"blocks at {turns(w.at)}" else: "no block"
        let names = if w.stopped: why(w) else: ""
        result.add &"| {name} | {word} | {way} | {floor} | {says} | {names} |\n"
  result.add "\n"


proc pairHolds(): string =
  ## Tabulate both two-hand holds at every band, follow turned.
  result.add "## Both hands held\n\n"
  result.add prose("L-r.R-l rests face-to-face; L-l.R-r rests pillion lead " &
    "(face-to-face its two connections lie through each other), and its turns count " &
    "from there.")
  for (links, away, name) in [
      (twoLinks(Arm.Left, Arm.Right, Arm.Right, Arm.Left), false, "L-r.R-l"),
      (twoLinks(Arm.Left, Arm.Left, Arm.Right, Arm.Right), true,
       "L-l.R-r, from pillion lead")]:
    for (word, band) in BANDS:
      let sw = sweepOf(band, links, away = away)
      result.add &"### {name}, {word}\n\n"
      if not sw.restHolds:
        result.add "No pose holds at the rest.\n\n"
        continue
      result.add blocks(sw)
      result.add "| turn | her first arm | her second arm | crossings | strain |\n" &
        "|---|---|---|---|---|\n"
      for h in HALVES:
        let t = h.float / 2.0
        let m = momentAt(sw, t)
        if m.isNone:
          result.add &"| {half(h)} | blocked | | | |\n"
          continue
        let
          mo = m.get
          tight = tightest(HUMAN, mo.stance, links, mo.arms)
        var cross = ""
        for c in crossings(mo.arms):
          cross.add (if cross.len > 0: ", " else: "") &
            (if c.over == 0: "first over" else: "second over")
        if cross.len == 0: cross = "none"
        result.add &"| {half(h)} | " &
          &"{said(lyingOn(HUMAN, band, links, mo.stance, mo.arms, 0, Body.Two), band)} | " &
          &"{said(lyingOn(HUMAN, band, links, mo.stance, mo.arms, 1, Body.Two), band)} | " &
          &"{cross} | {strainWord(tight)} |\n"
      result.add "\n"


proc chain(): string =
  ## Tabulate whether any pose holds at each rung of chain, asked still.
  result.add "## The chain, asked still\n\n"
  result.add prose("L-r.R-l turned to each rung and asked afresh whether any pose holds " &
    "there at all -- not whether the arms can carry to it, which the sweeps above say.  " &
    "Asked from every distance the couple may stand at, and shown from first that holds.")
  result.add "| level | rung | holds | strain | crossings | standing |\n" &
    "|---|---|---|---|---|---|\n"
  let links = twoLinks(Arm.Left, Arm.Right, Arm.Right, Arm.Left)
  for (word, band) in BANDS:
    for (turn, rung) in [(0.5, "X"), (1.0, "diamond"), (1.5, "swan")]:
      var found = false
      for apart in stands(HUMAN):
        var c = build(HUMAN, turned(restStance(HUMAN, apart), Body.Two, turn), band, links)
        c.settle()
        var holds = true
        var arms: Arms
        for i in 0 ..< links.len:
          if c.stopOf(i) != Stop.None: holds = false
          arms.add c.poseOf(i).arms
        if holds:
          let tight = tightest(HUMAN, c.stance, links, arms)
          result.add &"| {word} | {rung} ({turns(turn)}) | yes | {strainWord(tight)} | " &
            &"{crossings(arms).len} | {turns(apart)} m |\n"
          found = true
        c.free()
        if found: break
      if not found:
        result.add &"| {word} | {rung} ({turns(turn)}) | no | | | no pose holds |\n"
  result.add "\n"


proc drawnRow(drawn: string; links: seq[Link]; who: Body; turn: float; band: Band): string =
  ## Tabulate one state whole-cloth page draws, asked of sim.
  let m = momentAt(sweepOf(band, links, who = who), turn)
  if m.isNone:
    return &"| {drawn} | {turns(turn)} | blocked before it | | | |\n"
  let
    mo = m.get
    tight = tightest(HUMAN, mo.stance, links, mo.arms)
  &"| {drawn} | {turns(turn)} | yes | " &
    &"{said(lyingOn(HUMAN, band, links, mo.stance, mo.arms, 0, Body.Two), band)} | " &
    &"{said(lyingOn(HUMAN, band, links, mo.stance, mo.arms, 0, Body.One), band)} | " &
    &"{strainWord(tight)} |\n"


proc drawnStates(): string =
  ## Tabulate every state whole-cloth page draws.
  result.add "## The states the whole-cloth page draws\n\n"
  result.add "| drawn as | turned | holds | her arm | his arm | strain |\n" &
    "|---|---|---|---|---|---|\n"
  result.add drawnRow("Left to left, open",
    oneLink(Arm.Left, Arm.Left), Body.Two, 0.0, Band.Torso)
  result.add drawnRow("Left to right-wrap-low @ 1/2",
    oneLink(Arm.Left, Arm.Right), Body.Two, -0.5, Band.Torso)
  result.add drawnRow("Left to right-wrap-high @ 1/2",
    oneLink(Arm.Left, Arm.Right), Body.Two, -0.5, Band.Neck)
  result.add drawnRow("Left to left-lock-low @ -1",
    oneLink(Arm.Left, Arm.Left), Body.Two, -1.0, Band.Torso)
  result.add drawnRow("Left to left-lock-high @ -1",
    oneLink(Arm.Left, Arm.Left), Body.Two, -1.0, Band.Neck)
  result.add drawnRow("Left to left @ above, +1",
    oneLink(Arm.Left, Arm.Left), Body.Two, 1.0, Band.Crown)
  result.add drawnRow("Left-Lock-Low to left, him turned -1",
    oneLink(Arm.Left, Arm.Left), Body.One, -1.0, Band.Torso)
  result.add drawnRow("Left-Lock-Low to left, him turned +1",
    oneLink(Arm.Left, Arm.Left), Body.One, 1.0, Band.Torso)
  result.add "\n"


proc standing(): string =
  ## Tabulate block at three stances told, beside one couple choose.
  result.add "## Standing closer, and further\n\n"
  result.add prose("L-l low, turning her, at three stances told rather than chosen: what " &
    "the block does when the couple are made to step in or out.  The row above them is " &
    "where they stand when left to choose.")
  result.add "| apart | lock way | wrap way |\n|---|---|---|\n"
  let links = oneLink(Arm.Left, Arm.Left)
  let chosen = sweepOf(Band.Torso, links)
  result.add &"| chosen | {blockLine(chosen.neg, \"-\")} | {blockLine(chosen.pos, \"+\")} |\n"
  for apart in [0.36, 0.50, 0.70]:
    let sw = sweepOf(Band.Torso, links, apart = apart)
    if not sw.restHolds:
      result.add &"| {apart} m | no rest | |\n"
      continue
    result.add &"| {apart} m | {blockLine(sw.neg, \"-\")} | {blockLine(sw.pos, \"+\")} |\n"
  result.add "\n"


proc report(): string =
  ## Write whole report.
  result.add "# What the sim says\n\n"
  result.add prose("Generated by `nim r tools/build.nim verdicts` from `sim/verdicts.nim`; " &
    "do not edit by hand.  The sim answers in its own physical words and this report " &
    "translates once:")
  result.add "| the sim says | the sheet says |\n|---|---|\n"
  result.add "| the hand across the front of its own body | wrap |\n"
  result.add "| the hand behind its own back | lock |\n"
  result.add "| the hands in the torso band | low |\n"
  result.add "| the hands in the neck band | high |\n"
  result.add "| the hands over the crown | above |\n"
  result.add "| the arm carried there but not pressing the body | led |\n\n"
  result.add prose("Read with the model's limits in mind: the shoulder girdle is rigid and " &
    "the trunk does not twist, so a reach a dancer gets by rolling a shoulder forward is " &
    "refused here; a torso is a stadium of its round; and the couple stand for each turn " &
    "wherever it carries furthest, never inside each other.  A *blocks* is therefore a " &
    "little early, and a *holds* says the pose exists without any of that help.")
  result.add rigTable()
  result.add singleHolds()
  result.add floorClaim()
  result.add pairHolds()
  result.add chain()
  result.add drawnStates()
  result.add standing()


when isMainModule:
  writeFile("sim/verdicts.md", report())
  echo "wrote sim/verdicts.md"
