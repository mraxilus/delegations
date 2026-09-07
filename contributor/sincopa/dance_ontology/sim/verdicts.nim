## Ask sim questions ontology's sheet asks, and write down what it says, once, in sheet's
## words.
##
##   This is one place sim's answers meet ontology's vocabulary -- wrap, lock, low, high,
##     above -- and translation happens here, in one visible table, so model itself stays
##     vocabulary-free.  Instrument run, not build: answers land in `sim/verdicts.md`.
##   Floor's claims are printed beside sim's answers and nothing is tuned to make them
##     agree: where they disagree report says so, and which constraint sim names.
##   Report wraps its prose at 100 columns and keeps table rows under it (repository form
##     rule applies to generated Markdown too); standing table footnotes reachable poses.

{.experimental: "strictFuncs".}

import std/[math, options, strformat, strutils, tables, wordwrap]

import ./[body, limb, read, rig, solve, sweep, vec]


const
  APART = 0.40 ## Stance every question is asked at, in metres.
  BANDS = [("low", Band.Torso), ("high", Band.Neck), ("above", Band.Crown)]
    ## Sheet's word for each band.
  HALVES = [-4, -3, -2, -1, 0, 1, 2, 3, 4] ## Turns asked, in half turns.
  WIDTH = 100 ## Columns report's prose wraps at.
  BEYOND = " (a pose holds a step beyond, but not one the arms can reach)"
    ## Said of block where pose exists past it that arms cannot carry to.
  DAGGER = " †" ## Footnote mark standing table uses for `BEYOND`.


func oneLink(a, b: Arm; band: Band; apart = APART; away = false): State =
  ## Stand couple square with one connection, One's `a` to Two's `b`.
  result = State(rig: HUMAN, stance: facing(HUMAN, apart), band: band,
                 links: @[Link(ends: [(Body.One, a), (Body.Two, b)])])
  if away:
    result.stance[Body.Two].facing -= PI

func twoLinks(a, b, c, d: Arm; band: Band; away = false): State =
  ## Hold both hands: One's `a` to Two's `b`, One's `c` to Two's `d`.
  result = State(rig: HUMAN, stance: facing(HUMAN, APART), band: band,
                 links: @[Link(ends: [(Body.One, a), (Body.Two, b)]),
                          Link(ends: [(Body.One, c), (Body.Two, d)])])
  if away:
    result.stance[Body.Two].facing -= PI


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

func whose(s: State; v: Verdict): string =
  ## Name arm verdict is about: his or hers.
  if v.n == 0: return ""
  let hand = s.links[v.link].ends[v.arm]
  if hand.body == Body.One: "his" else: "her"

func why(s: State; v: Verdict): string =
  ## Say what refuses, in words.
  case v.reason
  of Reason.None: "holds"
  of Reason.Reach: &"{whose(s, v)} reach"
  of Reason.Shoulder: &"{whose(s, v)} shoulder, {dofName(v.dof)}"
  of Reason.Twist: &"{whose(s, v)} shoulder, twist"
  of Reason.Elbow: &"{whose(s, v)} elbow"
  of Reason.Wrist: &"{whose(s, v)} wrist"
  of Reason.Through:
    let part = case v.part
      of Part.Torso: "torso"
      of Part.Neck: "neck"
      of Part.Head: "head"
    &"{whose(s, v)} arm through " & (if v.whose == Body.One: "his " else: "her ") & part
  of Reason.Arms: "arm through arm"
  of Reason.Band: "the hands out of their band"

func turns(x: float): string = formatFloat(x, ffDecimal, 2)
  ## Render turns to two places.

func half(h: int): string =
  ## Render count of half turns as signed turns, e.g. `+1 1/2`.
  let sign = if h < 0: "-" elif h > 0: "+" else: ""
  let a = abs(h)
  sign & (if a mod 2 == 0: $(a div 2) else: (if a > 1: $(a div 2) & " 1/2" else: "1/2"))

func strainWord(v: Verdict): string =
  ## Render strain with its nearness to edge.
  let s = formatFloat(v.strain, ffDecimal, 2)
  if v.strain >= 1.0: s & " (at the edge)" elif v.strain >= 0.7: s & " (near it)" else: s

func blockLine(s: State; b: Block; sign: string; beyond = BEYOND): string =
  ## Say where sweep blocks one way and why; `beyond` marks reachable pose past it.
  if not b.stopped:
    return &"{sign}{turns(b.at)}: no block within {turns(MOST)} turns"
  result = &"{sign}{turns(b.at)}: {why(s, b.why)}"
  if b.foundAnyway:
    result.add beyond

func blocks(sw: Sweep): string =
  ## Say both blocks of sweep as one wrapped paragraph.
  prose(&"Blocks: {blockLine(sw.rest, sw.neg, \"-\")}; {blockLine(sw.rest, sw.pos, \"+\")}.")



#[ Sweeps, Once ]#

var sweeps: Table[string, Sweep] ## Every sweep asked for, by what it is of.

func keyOf(s: State; who: Body): string =
  ## Say what sweep is sweep of: hold, band, stance, who turns.
  result = &"{ord(who)}|{ord(s.band)}|{s.stance[Body.Two].centre.y}|" &
    &"{s.stance[Body.Two].facing}"
  for link in s.links:
    result.add &"|{ord(link.ends[0].arm)}{ord(link.ends[1].arm)}"

proc sweepOf(s: State; who: Body): Sweep =
  ## Read sweep of hold: from batch where it was asked for there, else swept now.
  let key = keyOf(s, who)
  if key notin sweeps:
    sweeps[key] = swept(s, who)
  sweeps[key]

proc askAll(asks: openArray[(State, Body)]) =
  ## Sweep every hold sections will ask about, once each, side by side.
  var
    jobs: seq[Job]
    keys: seq[string]
  for (s, who) in asks:
    let key = keyOf(s, who)
    if key in sweeps or key in keys:
      continue
    keys.add key
    jobs.add Job(rest: s, who: who, most: MOST)
  let got = sweptAll(jobs)
  for i, key in keys:
    sweeps[key] = got[i]

proc askEverything() =
  ## Ask every sweep report reads, long ones -- over head -- first.
  var asks: seq[(State, Body)]
  for (word, band) in [BANDS[2], BANDS[1], BANDS[0]]:
    for (a, b) in [(Arm.Left, Arm.Left), (Arm.Right, Arm.Right),
                   (Arm.Left, Arm.Right), (Arm.Right, Arm.Left)]:
      asks.add (oneLink(a, b, band), Body.Two)
    asks.add (twoLinks(Arm.Left, Arm.Right, Arm.Right, Arm.Left, band), Body.Two)
    asks.add (twoLinks(Arm.Left, Arm.Left, Arm.Right, Arm.Right, band, away = true), Body.Two)
  asks.add (oneLink(Arm.Left, Arm.Left, Band.Torso), Body.One)
  for apart in [0.34, 0.50]:
    asks.add (oneLink(Arm.Left, Arm.Left, Band.Torso, apart = apart), Body.Two)
  askAll(asks)



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
  result.add "| shoulder | 45 degrees behind the frontal plane, 45 across the body, " &
    "twist 70 in to 90 out |\n"
  result.add "| elbow | 0 to 140 degrees |\n"
  result.add "| wrist | a 60 degree cone |\n"
  result.add &"| hands | low {HUMAN.band[Band.Torso].lo}-{HUMAN.band[Band.Torso].hi}, " &
    &"high {HUMAN.band[Band.Neck].lo}-{HUMAN.band[Band.Neck].hi}, " &
    &"above {HUMAN.band[Band.Crown].lo}-{HUMAN.band[Band.Crown].hi} m |\n"
  result.add &"| stance | {APART} m axis to axis |\n\n"


proc singleHolds(): string =
  ## Tabulate every one-hand hold at every band, follow turned.
  result.add "## One hand held, the follow turned\n\n"
  result.add prose("Counted from face-to-face, in turns, anticlockwise seen from above " &
    "positive.  Each row is the pose the arms carry to that turn; *strain* is how far " &
    "into the last stretch before a joint's edge the worst joint is (1 is the edge).")
  for (a, b, name) in [(Arm.Left, Arm.Left, "L-l"), (Arm.Right, Arm.Right, "R-r"),
                       (Arm.Left, Arm.Right, "L-r"), (Arm.Right, Arm.Left, "R-l")]:
    for (word, band) in BANDS:
      let sw = sweepOf(oneLink(a, b, band), Body.Two)
      result.add &"### {name}, {word}\n\n"
      if not sw.restHolds:
        result.add "No pose holds at the rest.\n\n"
        continue
      result.add blocks(sw)
      result.add "| turn | her arm | his arm | strain | hands at |\n|---|---|---|---|---|\n"
      for h in HALVES:
        let t = h.float / 2.0
        let m = sw.at(t)
        if m.isNone or abs(m.get.turn - t) > 0.011:
          result.add &"| {half(h)} | blocked | | | |\n"
          continue
        let
          v = m.get.verdict
          g = v.fits[0].arms[0].g
        result.add &"| {half(h)} | {said(lyingOn(m.get.state, v, 0, Body.Two), band)} | " &
          &"{said(lyingOn(m.get.state, v, 0, Body.One), band)} | {strainWord(v)} | " &
          &"{turns(g.z)} m |\n"
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
      let sw = sweepOf(oneLink(a, b, band), Body.Two)
      for (way, sign) in [("lock way", lockSign), ("wrap way", -lockSign)]:
        let blk = if sign < 0: sw.neg else: sw.pos
        let floor = if band == Band.Crown: "no block"
                    elif band == Band.Torso and way == "wrap way": "half a turn"
                    else: "a whole turn"
        let says = if blk.stopped: &"blocks at {turns(blk.at)}" else: "no block"
        let names = if blk.stopped: why(sw.rest, blk.why) else: ""
        result.add &"| {name} | {word} | {way} | {floor} | {says} | {names} |\n"
  result.add "\n"


proc pairHolds(): string =
  ## Tabulate both two-hand holds at every band, follow turned.
  result.add "## Both hands held\n\n"
  result.add prose("L-r.R-l rests face-to-face; L-l.R-r rests pillion lead " &
    "(face-to-face its two connections lie through each other), and its turns count " &
    "from there.")
  for (links, name) in [
      (twoLinks(Arm.Left, Arm.Right, Arm.Right, Arm.Left, Band.Torso), "L-r.R-l"),
      (twoLinks(Arm.Left, Arm.Left, Arm.Right, Arm.Right, Band.Torso, away = true),
       "L-l.R-r, from pillion lead")]:
    for (word, band) in BANDS:
      var s = links
      s.band = band
      let sw = sweepOf(s, Body.Two)
      result.add &"### {name}, {word}\n\n"
      if not sw.restHolds:
        result.add "No pose holds at the rest.\n\n"
        continue
      result.add blocks(sw)
      result.add "| turn | her first arm | her second arm | crossings | strain |\n" &
        "|---|---|---|---|---|\n"
      for h in HALVES:
        let t = h.float / 2.0
        let m = sw.at(t)
        if m.isNone or abs(m.get.turn - t) > 0.011:
          result.add &"| {half(h)} | blocked | | | |\n"
          continue
        let v = m.get.verdict
        var cross = ""
        for c in crossings(m.get.state, v):
          cross.add (if cross.len > 0: ", " else: "") &
            (if c.over == 0: "first over" else: "second over")
        if cross.len == 0: cross = "none"
        result.add &"| {half(h)} | {said(lyingOn(m.get.state, v, 0, Body.Two), band)} | " &
          &"{said(lyingOn(m.get.state, v, 1, Body.Two), band)} | {cross} | {strainWord(v)} |\n"
      result.add "\n"


proc chain(): string =
  ## Tabulate whether any pose holds at each rung of chain, asked still.
  result.add "## The chain, asked still\n\n"
  result.add prose("L-r.R-l turned to each rung and asked afresh whether any pose holds " &
    "there at all -- not whether the arms can carry to it, which the sweeps above say.")
  result.add "| level | rung | holds | strain | crossings | what refuses |\n" &
    "|---|---|---|---|---|---|\n"
  for (word, band) in BANDS:
    for (turn, rung) in [(0.5, "X"), (1.0, "diamond"), (1.5, "swan")]:
      var s = twoLinks(Arm.Left, Arm.Right, Arm.Right, Arm.Left, band)
      s.stance = turned(s.stance, Body.Two, turn)
      let got = settle(s, fine = true)
      if got.isSome:
        let v = evaluate(got.get)
        result.add &"| {word} | {rung} ({turns(turn)}) | yes | {strainWord(v)} | " &
          &"{crossings(got.get, v).len} | |\n"
      else:
        result.add &"| {word} | {rung} ({turns(turn)}) | no | | | no pose holds |\n"
  result.add "\n"


proc drawnRow(drawn: string; s: State; who: Body; turn: float; band: Band): string =
  ## Tabulate one state whole-cloth page draws, asked of sim.
  let sw = sweepOf(s, who)
  let m = sw.at(turn)
  if m.isNone or abs(m.get.turn - turn) > 0.011:
    return &"| {drawn} | {turns(turn)} | blocked before it | | | |\n"
  let v = m.get.verdict
  &"| {drawn} | {turns(turn)} | yes | {said(lyingOn(m.get.state, v, 0, Body.Two), band)} | " &
    &"{said(lyingOn(m.get.state, v, 0, Body.One), band)} | {strainWord(v)} |\n"


proc drawnStates(): string =
  ## Tabulate every state whole-cloth page draws.
  result.add "## The states the whole-cloth page draws\n\n"
  result.add "| drawn as | turned | holds | her arm | his arm | strain |\n" &
    "|---|---|---|---|---|---|\n"
  result.add drawnRow("Left to left, open",
    oneLink(Arm.Left, Arm.Left, Band.Torso), Body.Two, 0.0, Band.Torso)
  result.add drawnRow("Left to right-wrap-low @ 1/2",
    oneLink(Arm.Left, Arm.Right, Band.Torso), Body.Two, -0.5, Band.Torso)
  result.add drawnRow("Left to right-wrap-high @ 1/2",
    oneLink(Arm.Left, Arm.Right, Band.Neck), Body.Two, -0.5, Band.Neck)
  result.add drawnRow("Left to left-lock-low @ -1",
    oneLink(Arm.Left, Arm.Left, Band.Torso), Body.Two, -1.0, Band.Torso)
  result.add drawnRow("Left to left-lock-high @ -1",
    oneLink(Arm.Left, Arm.Left, Band.Neck), Body.Two, -1.0, Band.Neck)
  result.add drawnRow("Left to left @ above, +1",
    oneLink(Arm.Left, Arm.Left, Band.Crown), Body.Two, 1.0, Band.Crown)
  result.add drawnRow("Left-Lock-Low to left, him turned -1",
    oneLink(Arm.Left, Arm.Left, Band.Torso), Body.One, -1.0, Band.Torso)
  result.add drawnRow("Left-Lock-Low to left, him turned +1",
    oneLink(Arm.Left, Arm.Left, Band.Torso), Body.One, 1.0, Band.Torso)
  result.add "\n"


proc standing(): string =
  ## Tabulate block at three stances; `†` footnotes reachable pose beyond block.
  result.add "## Standing closer, and further\n\n"
  result.add prose("L-l low, turning her, at three stances: what the block does when the " &
    "couple step in or out.")
  result.add "| apart | lock way | wrap way |\n|---|---|---|\n"
  for apart in [0.34, 0.40, 0.50]:
    let sw = sweepOf(oneLink(Arm.Left, Arm.Left, Band.Torso, apart = apart), Body.Two)
    if not sw.restHolds:
      result.add &"| {apart} m | no rest | |\n"
      continue
    result.add &"| {apart} m | {blockLine(sw.rest, sw.neg, \"-\", DAGGER)} | " &
      &"{blockLine(sw.rest, sw.pos, \"+\", DAGGER)} |\n"
  result.add "\n† a pose holds a step beyond, but not one the arms can reach\n"


proc report(): string =
  ## Write whole report.
  result.add "# What the sim says\n\n"
  result.add prose("Generated by `make verdicts` from `sim/verdicts.nim`; do not edit by " &
    "hand.  The sim answers in its own physical words and this report translates once:")
  result.add "| the sim says | the sheet says |\n|---|---|\n"
  result.add "| the hand across the front of its own body | wrap |\n"
  result.add "| the hand behind its own back | lock |\n"
  result.add "| the hands in the torso band | low |\n"
  result.add "| the hands in the neck band | high |\n"
  result.add "| the hands over the crown | above |\n"
  result.add "| the arm carried there but not pressing the body | led |\n\n"
  result.add prose("Read with the model's limits in mind: the shoulder girdle is rigid and " &
    "the trunk does not twist, so a reach a dancer gets by rolling a shoulder forward is " &
    "refused here; the couple never step apart; a torso is an ellipse of its round.  A " &
    "*blocks* is therefore a little early, and a *holds* says the pose exists without any " &
    "of that help.")
  askEverything()
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
