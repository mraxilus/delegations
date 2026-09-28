## Write what sim says, as report, in words sheet uses.
##
##   Instrument run, not build step: `nim r tools/build.nim verdicts` writes
##     `sim/verdicts.md`.  Everything here is asked of `walk`, which stands couple
##     for turn they are about to take and walks them until something gives;
##     report only translates, once, and shows its translation table first.
##   Report renders from readings (`readings`), kept with stamp of physics in
##     `sim/verdicts.json`: words alone render in seconds, and physics changed is
##     read again on every core.
##   Solver this once asked is gone.  What is asked has not changed; what answers
##     has, and figures in report are whatever it answers today.

{.experimental: "strictFuncs".}

import std/[math, options, sets, strformat, strutils, tables, wordwrap]

import ./[body, hold, readings, rig, rigid, walk, words]


const
  RUNGS = [(0.5, "cross"), (1.0, "diamond"), (1.5, "swan")]
    ## Name each rung of chain, in glossary's own words.
    ##   Once said `X`, which sits on avoid line of **Cross**, while
    ##     `design/parts` named same rung right: two namings of one chain, and
    ##     only one of them correct.  `tests/suites/tglossary` now reads both.
  WIDTH = 100 ## Columns report's prose wraps at.
  SEEN = ["ahead", "at right", "behind", "at left"]
    ## Say where one has other, by quarters clockwise (`body.quartersTo`).


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

func turns(x: float): string = formatFloat(x, ffDecimal, 2)
  ## Render turns to two places.

func half(h: int): string =
  ## Render count of half turns as signed turns, e.g. `+1 1/2`.
  let sign = if h < 0: "-" elif h > 0: "+" else: ""
  let a = abs(h)
  sign & (if a mod 2 == 0: $(a div 2) else: (if a > 1: $(a div 2) & " 1/2" else: "1/2"))

func strainWord(strain: float): string =
  ## Render strain with its nearness to edge.
  let s = formatFloat(strain, ffDecimal, 2)
  if strain >= 1.0: s & " (at edge)" elif strain >= 0.7: s & " (near it)" else: s

func whyOf(w: WayRead): string =
  ## Say what refuses, as `words.why` says it of walk.
  why(Walk(stopped: w.stopped, at: w.at, why: w.why, whose: w.whose))

func blockLine(w: WayRead; sign: string; apart = true): string =
  ## Say where sweep blocks one way and why, and how far apart couple stood for it.
  ##   Kept short: two of these sit in one table row under audit's hundred columns.
  ##   Stance is dropped where row names it, since repeating it there says nothing.
  let stood = if apart: &", {turns(w.apart)} m apart" else: ""
  if not w.stopped:
    return &"{sign}: free to {turns(MOST)} turns{stood}"
  &"{sign}{turns(w.at)}{stood}: {whyOf(w)}"

func blocks(sweep: SweepRead): string =
  ## Say both blocks of sweep as one wrapped paragraph.
  prose(&"Blocks: {blockLine(sweep.negative, \"-\")}; {blockLine(sweep.positive, \"+\")}.")

func restName(away: bool): string =
  ## Name facing couple rest at, read off stance sim stands them in.
  ##   Distance puts no one at other side of other, so any distance names it.
  facingName(restStance(HUMAN, 1.0, away)).get


#[ Readings, asked for by rendering ]#

# Mutable: render reads kept readings and gathers asks it lacks, and report renders
# through many routines, so each would carry them otherwise.
var
  READINGS_KEPT*: Readings ## Readings report renders from.
  SWEEPS_WANTED: seq[SweepAsk] ## Sweeps render asked for and `READINGS_KEPT` lacks, in order asked.
  RUNGS_WANTED: seq[RungAsk]
  KEYS_USED: HashSet[string] ## Keys render read, so file keeps nothing no render reads.

proc sweepOf(band: Band; links: seq[Link]; who = Body.Two; away = false;
             apart = 0.0): SweepRead =
  ## Kept reading of sweep; lacking it, ask for it and render blank for now.
  let
    ask = askOf(band, links, who, away, apart)
    key = keyOf(ask)
  KEYS_USED.incl key
  if key in READINGS_KEPT.sweeps: return READINGS_KEPT.sweeps[key]
  if ask notin SWEEPS_WANTED: SWEEPS_WANTED.add ask

proc rungOf(band: Band; turn: float): RungRead =
  ## Kept reading of rung; lacking it, ask for it and render blank for now.
  let
    ask = RungAsk(band: band, turn: turn)
    key = keyOf(ask)
  KEYS_USED.incl key
  if key in READINGS_KEPT.rungs: return READINGS_KEPT.rungs[key]
  if ask notin RUNGS_WANTED: RUNGS_WANTED.add ask

func glanceAt(sweep: SweepRead; t: float): Glance = sweep.glances[int(round(t * 2.0)) + 4]
  ## Moment report reads at `t` turns, which is half turn from -2 to 2.


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
    behind = int(round(HUMAN.range[Dof.Extend].upper * 180.0 / PI))
    twist_in = int(round(-HUMAN.range[Dof.Twist].lower * 180.0 / PI))
    twist_out = int(round(HUMAN.range[Dof.Twist].upper * 180.0 / PI))
    bend = int(round(HUMAN.range[Dof.Bend].upper * 180.0 / PI))
    wrist = int(round(HUMAN.range[Dof.Wrist].upper * 180.0 / PI))
    waist = int(round(HUMAN.waist.upper * 180.0 / PI))
  result.add &"| shoulder | {behind} degrees behind the frontal plane; across, trunk stops " &
    &"it; twist {twist_in} in to {twist_out} out |\n"
  result.add &"| elbow | 0 to {bend} degrees |\n"
  result.add &"| wrist | a {wrist} degree cone |\n"
  result.add &"| waist | {waist} degrees each way, sprung to square |\n"
  result.add &"| hands | low {HUMAN.band[Band.Torso].lo}-{HUMAN.band[Band.Torso].hi}, " &
    &"high {HUMAN.band[Band.Neck].lo}-{HUMAN.band[Band.Neck].hi}, " &
    &"above {HUMAN.band[Band.Crown].lo}-{HUMAN.band[Band.Crown].hi} m |\n"
  result.add "| stance | chosen for each turn, from clear of each other outward |\n\n"


proc singleHolds(): string =
  ## Tabulate every one-hand hold at every band, follow turned.
  result.add "## One hand held, the follow turned\n\n"
  result.add prose(&"Counted from {restName(false)}, in turns, anticlockwise seen from above " &
    "positive.  Each row is the pose the arms carry to that turn; *strain* is how far " &
    "into the last stretch before a joint's edge the worst joint is (1 is the edge).")
  for (a, b, name) in [(Arm.Left, Arm.Left, "L-l"), (Arm.Right, Arm.Right, "R-r"),
                       (Arm.Left, Arm.Right, "L-r"), (Arm.Right, Arm.Left, "R-l")]:
    let links = oneLink(a, b)
    for (word, band) in BANDS:
      let sweep = sweepOf(band, links)
      result.add &"### {name}, {word}\n\n"
      if not sweep.restHolds:
        result.add "No pose holds at the rest.\n\n"
        continue
      result.add blocks(sweep)
      result.add "| turn | follow's arm | lead's arm | strain | hands at |\n" &
        "|---|---|---|---|---|\n"
      for i, h in HALVES:
        let g = sweep.glances[i]
        if not g.got:
          result.add &"| {half(h)} | blocked | | | |\n"
          continue
        result.add &"| {half(h)} | {said(g.lies[0][Body.Two], band)} | " &
          &"{said(g.lies[0][Body.One], band)} | {strainWord(g.strain)} | {turns(g.handZ)} m |\n"
      result.add "\n"


proc floorClaim(): string =
  ## Tabulate floor's claim beside sim's answer.
  result.add "## The floor's claim\n\n"
  result.add prose("The floor: *everything gets a full turn before it blocks, except a low " &
    &"wrap, which gets half.*  L-l and L-r, turning the follow, from {restName(false)}.  For L-l " &
    "the lock way is negative and the wrap way positive; for L-r the wrap way is negative " &
    "and the lock way positive.")
  result.add "| hold | level | way | floor says | sim says | the sim names |\n" &
    "|---|---|---|---|---|---|\n"
  for (a, b, name, lockSign) in [(Arm.Left, Arm.Left, "L-l", -1.0),
                                 (Arm.Left, Arm.Right, "L-r", 1.0)]:
    for (word, band) in BANDS:
      let sweep = sweepOf(band, oneLink(a, b))
      for (way, sign) in [("lock way", lockSign), ("wrap way", -lockSign)]:
        let w = if sign < 0: sweep.negative else: sweep.positive
        let floor = if band == Band.Crown: "no block"
                    elif band == Band.Torso and way == "wrap way": "half a turn"
                    else: "a whole turn"
        let says = if w.stopped: &"blocks at {turns(w.at)}" else: "no block"
        let names = if w.stopped: whyOf(w) else: ""
        result.add &"| {name} | {word} | {way} | {floor} | {says} | {names} |\n"
  result.add "\n"


proc pairHolds(): string =
  ## Tabulate both two-hand holds at every band, follow turned.
  result.add "## Both hands held\n\n"
  result.add prose(&"L-r.R-l rests {restName(false)}; L-l.R-r rests {restName(true)} " &
    &"({restName(false)} its two connections lie through each other), and its turns count " &
    "from there.")
  for (links, away, name) in [
      (twoLinks(Arm.Left, Arm.Right, Arm.Right, Arm.Left), false, "L-r.R-l"),
      (twoLinks(Arm.Left, Arm.Left, Arm.Right, Arm.Right), true,
       "L-l.R-r, from " & restName(true))]:
    for (word, band) in BANDS:
      let sweep = sweepOf(band, links, away = away)
      result.add &"### {name}, {word}\n\n"
      if not sweep.restHolds:
        result.add "No pose holds at the rest.\n\n"
        continue
      result.add blocks(sweep)
      result.add "| turn | follow's first arm | follow's second arm | crossings | strain |\n" &
        "|---|---|---|---|---|\n"
      for i, h in HALVES:
        let g = sweep.glances[i]
        if not g.got:
          result.add &"| {half(h)} | blocked | | | |\n"
          continue
        var cross = ""
        for c in 0 ..< min(g.crossed, g.over.len):
          cross.add (if cross.len > 0: ", " else: "") &
            (if g.over[c] == 0: "first over" else: "second over")
        if cross.len == 0: cross = "none"
        result.add &"| {half(h)} | {said(g.lies[0][Body.Two], band)} | " &
          &"{said(g.lies[1][Body.Two], band)} | {cross} | {strainWord(g.strain)} |\n"
      result.add "\n"


proc chain(): string =
  ## Tabulate whether any pose holds at each rung of chain, asked still.
  result.add "## The chain, asked still\n\n"
  result.add prose("L-r.R-l wound to each rung and asked whether pose holds there standing " &
    "still -- not whether the arms carry to it at the pace of the turn, which the sweeps " &
    "above say.  Wound, not built there: a rung is a winding of the arms, which no facing " &
    "says, so the couple are turned to it with the hands lifted and then left to stand.  " &
    "Asked from every distance the couple may stand at, and shown from first that holds.")
  result.add "| level | rung | facing | holds | strain | crossings | standing |\n" &
    "|---|---|---|---|---|---|---|\n"
  for (word, band) in BANDS:
    for (turn, rung) in RUNGS:
      # Read off stance rung winds couple to, whether pose holds there or not.
      let
        facing = facingName(turned(restStance(HUMAN, 1.0), Body.Two, turn)).get
        r = rungOf(band, turn)
      if r.found:
        result.add &"| {word} | {rung} ({turns(turn)}) | {facing} | yes | " &
          &"{strainWord(r.strain)} | {r.crossed} | {turns(r.apart)} m |\n"
      else:
        result.add &"| {word} | {rung} ({turns(turn)}) | {facing} | no | | | no pose holds |\n"
  result.add "\n"


proc drawnRow(drawn: string; links: seq[Link]; who: Body; turn: float; band: Band): string =
  ## Tabulate one state whole-cloth page draws, asked of sim.
  let g = glanceAt(sweepOf(band, links, who = who), turn)
  if not g.got:
    return &"| {drawn} | {turns(turn)} | blocked before it | | | |\n"
  &"| {drawn} | {turns(turn)} | yes | {said(g.lies[0][Body.Two], band)} | " &
    &"{said(g.lies[0][Body.One], band)} | {strainWord(g.strain)} |\n"


proc drawnStates(): string =
  ## Tabulate every state whole-cloth page draws.
  result.add "## The states the whole-cloth page draws\n\n"
  result.add "| drawn as | turned | holds | follow's arm | lead's arm | strain |\n" &
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
  result.add drawnRow("Left-Lock-Low to left, lead turned -1",
    oneLink(Arm.Left, Arm.Left), Body.One, -1.0, Band.Torso)
  result.add drawnRow("Left-Lock-Low to left, lead turned +1",
    oneLink(Arm.Left, Arm.Left), Body.One, 1.0, Band.Torso)
  result.add "\n"


proc standing(): string =
  ## Tabulate block at three stances told, beside one couple choose.
  result.add "## Standing closer, and further\n\n"
  result.add prose("L-l low, turning the follow, at three stances told rather than chosen: " &
    "what the block does when the couple are made to step in or out.  The row above them is " &
    "where they stand when left to choose.")
  result.add "| apart | lock way | wrap way |\n|---|---|---|\n"
  let links = oneLink(Arm.Left, Arm.Left)
  let chosen = sweepOf(Band.Torso, links)
  result.add &"| chosen | {blockLine(chosen.negative, \"-\")} | " &
    &"{blockLine(chosen.positive, \"+\")} |\n"
  for apart in [0.36, 0.50, 0.70]:
    let sweep = sweepOf(Band.Torso, links, apart = apart)
    if not sweep.restHolds:
      result.add &"| {apart} m | no rest | |\n"
      continue
    result.add &"| {apart} m | {blockLine(sweep.negative, \"-\", apart = false)} | " &
      &"{blockLine(sweep.positive, \"+\", apart = false)} |\n"
  result.add "\n"


proc report(): string =
  ## Write whole report.
  result.add "# What the sim says\n\n"
  result.add prose("Generated by `nim r tools/build.nim verdicts` from `sim/verdicts.nim`; " &
    "do not edit by hand.  The sim answers in its own physical words, and `sim/words.nim` " &
    "translates once.  The whole-cloth page reads that same table, so the page and this " &
    "report cannot give one pose two answers:")
  result.add "| the sim says | the sheet says |\n|---|---|\n"
  result.add "| the arm out in front, on neither face of its own body | open |\n"
  result.add "| the hand across the front of its own body | wrap |\n"
  result.add "| the hand behind its own back | lock |\n"
  result.add "| the hands in the torso band | low |\n"
  result.add "| the hands in the neck band | high |\n"
  result.add "| the hands over the crown | above |\n"
  result.add "| the arm carried there but not pressing the body | led |\n"
  result.add "| the elbow in front of the body, on an arm behind the back | elbow forward |\n"
  for (seen, name) in FACINGS:
    result.add &"| the lead has the follow {SEEN[seen[0]]}, the follow has the lead " &
      &"{SEEN[seen[1]]} | {name} |\n"
  result.add "\n"
  result.add prose("Read with the model's limits in mind: the shoulder girdle is rigid, so " &
    "a reach a dancer gets by rolling a shoulder forward is refused here; the trunk twists " &
    "at the waist and does not bend; a torso is a stadium of its round; and the couple " &
    "stand for each turn wherever it carries furthest, never inside each other.  A " &
    "*blocks* is therefore a little early, and a *holds* says the pose exists without " &
    "any of that help.")
  result.add rigTable()
  result.add singleHolds()
  result.add floorClaim()
  result.add pairHolds()
  result.add chain()
  result.add drawnStates()
  result.add standing()


proc render*(): string =
  ## Write whole report from `READINGS_KEPT`.  Reading it lacks is asked for (`lacking`), and
  ## rendered blank.
  SWEEPS_WANTED.setLen 0
  RUNGS_WANTED.setLen 0
  KEYS_USED.clear
  report().strip(leading = false) & "\n"

proc lacking*(): int = SWEEPS_WANTED.len + RUNGS_WANTED.len
  ## How many readings last render lacked.


when isMainModule:
  READINGS_KEPT = keptReadings()
  var text = render()
  if lacking() > 0:
    echo "reading ", SWEEPS_WANTED.len, " sweeps and ", RUNGS_WANTED.len, " rungs"
    let got = readAll(SWEEPS_WANTED, RUNGS_WANTED)
    READINGS_KEPT.stamp = physics()
    for i, a in SWEEPS_WANTED: READINGS_KEPT.sweeps[keyOf(a)] = got.sweeps[i]
    for i, a in RUNGS_WANTED: READINGS_KEPT.rungs[keyOf(a)] = got.rungs[i]
    text = render()
    doAssert lacking() == 0, "Report still lacks readings once all are read."
  # Keep only what report reads, so file holds no reading nothing renders.
  var keeping = Readings(stamp: READINGS_KEPT.stamp)
  for k, v in READINGS_KEPT.sweeps:
    if k in KEYS_USED: keeping.sweeps[k] = v
  for k, v in READINGS_KEPT.rungs:
    if k in KEYS_USED: keeping.rungs[k] = v
  keep(keeping)
  writeFile("sim/verdicts.md", text)
  echo "wrote sim/verdicts.md"
