## Record sweeps for viewer page, as `design/rig.json`.
##
##   Run at build time, natively: engine is C, page is script in browser, so every
##     figure page draws is found here and played there.  Same arrangement
##     `design/turns` uses.
##   Written beside source rather than under `build/`, and run by its own verb, as
##     `design/modelled.json` is: recording costs eight stance searches, and every
##     `pages` run would pay for it.  `rig_page` folds it into page, which is
##     published as single document and so may leave nothing to fetch.
##   What is constant through sweep is written once -- radius and owner of each
##     capsule, and each joint's two ends -- and only what moves is written per
##     moment.  Straight transcription ran to four megabytes; this is fifth of
##     that and says exactly as much.
##
##   Every still card of reference is recorded beside sweeps, one moment each,
##     wound to its facing as `walk.stood` winds it, so viewer can lay sim's
##     answer beside each cell.
##
##   Usage: rig          writes design/rig.json

{.experimental: "strictFuncs".}

import std/[cpuinfo, math, os, strformat, strutils, typedthreads]

import ../sim/[body, hold, rig, seen]
import ./asks


type Cut = tuple[name: string, arms: seq[(Arm, Arm)], away: bool, band: Band]

const SHOWN: seq[Cut] = @[
  ("One hand, same name", @[(Arm.Left, Arm.Left)], false, Band.Crown),
  ("One hand, cross name", @[(Arm.Left, Arm.Right)], false, Band.Crown),
  ("Chain, cross name", @[(Arm.Left, Arm.Right), (Arm.Right, Arm.Left)],
   false, Band.Crown),
  ("Chain, same name", @[(Arm.Left, Arm.Left), (Arm.Right, Arm.Right)],
   true, Band.Crown),
  ("Chain, cross name", @[(Arm.Left, Arm.Right), (Arm.Right, Arm.Left)],
   false, Band.Neck),
  ("Chain, same name", @[(Arm.Left, Arm.Left), (Arm.Right, Arm.Right)],
   true, Band.Neck),
  ("Chain, cross name", @[(Arm.Left, Arm.Right), (Arm.Right, Arm.Left)],
   false, Band.Torso),
  ("Chain, same name", @[(Arm.Left, Arm.Left), (Arm.Right, Arm.Right)],
   true, Band.Torso)]
  ## Eight sweeps worth watching: four holds over crown, where whole reference is
  ## drawn, and two chains at each lower band, where floor and engine still argue.

const
  PLACE = 4 ## Decimal places kept.  Tenth of millimetre on lengths, and finer
            ## than any reading on angles; more is noise from solver's own jitter.
  BANDS = ["torso", "neck", "above"]


func num(x: float): string =
  ## Shortest text that still says figure to `PLACE`, with no trailing nought.
  ##   Nought is written `0` rather than `0.0000`: file holds tens of thousands
  ##     of them and page reads both same way.
  if x == 0.0 or abs(x) < 0.5 / (10.0 ^ PLACE):
    return "0"
  result = formatFloat(x, ffDecimal, PLACE)
  result = result.strip(leading = false, chars = {'0'})
  if result.endsWith('.'): result.setLen(result.len - 1)

func arr(xs: seq[float]): string =
  var bits: seq[string]
  for x in xs: bits.add num(x)
  "[" & bits.join(",") & "]"

func wrapped(s: string; width = 96): string =
  ## Whole field is wrapped, name and all: wrapped after its name, first line
  ## ran to 102 once shoulders were capsules too.
  ## Break long run of figures across lines after commas.  Charter holds every
  ## committed file to hundred columns, and one sweep's points on one line runs
  ## to hundreds of thousands.
  ##   Break is decided before piece is written, not after: deciding after lets
  ##     line run one whole figure past width, which is how first try still left
  ##     twenty one lines over hundred.
  ##   Only figures go through here, never text: hold's name carries comma of its
  ##     own, and breaking inside it would be breaking inside string.
  var
    line = 0
    i = 0
  while i < s.len:
    var j = i
    while j < s.len and s[j] != ',': j += 1
    if j < s.len: j += 1
    let piece = s[i ..< j]
    if line > 0 and line + piece.len > width:
      result.add '\n'
      line = 0
    result.add piece
    line += piece.len
    i = j


func flat(s: Still): seq[float] =
  ## Every capsule's two ends, one after another.
  for b in s.bars:
    result.add [b.a.x, b.a.y, b.a.z, b.z.x, b.z.y, b.z.z]

func angles(s: Still): seq[float] =
  ## Every arm's five joints, one arm after another.
  for a in s.arms:
    for d in Dof: result.add a.read[d]

func looking(s: Still): seq[float] =
  ## Each dancer's axis and which way they look, one after other.
  for who in Body:
    result.add [s.faces[who].at.x, s.faces[who].at.y,
                s.faces[who].fore.x, s.faces[who].fore.y]

func gripped(s: Still): seq[float] =
  for g in s.grips: result.add [g.x, g.y, g.z]


proc bodyOfSweep(sh: Shown; key = ""): string =
  ## One sweep as page reads it, or one still, keyed by question it answers.
  var bits: seq[string]
  if key.len > 0:
    bits.add &"\"key\":\"{key}\""
  bits.add &"\"hold\":\"{sh.hold}\""
  bits.add &"\"band\":\"{BANDS[ord(sh.band)]}\""
  bits.add &"\"apart\":{num(sh.apart)}"
  bits.add &"\"turns\":{num(sh.turns)}"
  bits.add &"\"stopped\":" & (if sh.stopped: "true" else: "false")
  bits.add &"\"why\":\"{sh.why}\""
  bits.add "\"says\":\"" & (if key.len > 0 and sh.stills.len == 0:
                             "no pose holds at any distance"
                           else: sh.why.says) & "\""
  bits.add &"\"whose\":[{ord(sh.whose.body)},{ord(sh.whose.arm)}]"
  if sh.stills.len == 0:
    bits.add "\"stills\":[]"
    return "{" & bits.join(",\n") & "}"
  let first = sh.stills[0]
  var tag, rad: seq[string]
  for b in first.bars:
    tag.add &"[{ord(b.who)},{ord(b.arm)},{ord(b.mark)}]"
    rad.add num(b.r)
  bits.add wrapped("\"tag\":[" & tag.join(",") & "]")
  bits.add wrapped("\"rad\":[" & rad.join(",") & "]")
  var owner, lo, hi: seq[string]
  for a in first.arms:
    owner.add &"[{ord(a.who)},{ord(a.arm)}]"
    for d in Dof:
      lo.add num(a.lo[d])
      hi.add num(a.hi[d])
  bits.add wrapped("\"arm\":[" & owner.join(",") & "]")
  bits.add wrapped("\"lo\":[" & lo.join(",") & "]")
  bits.add wrapped("\"hi\":[" & hi.join(",") & "]")
  var at, pts, angs, grp, apart, look: seq[string]
  for s in sh.stills:
    at.add num(s.at)
    look.add arr(s.looking)
    pts.add arr(s.flat)
    angs.add arr(s.angles)
    grp.add arr(s.gripped)
    apart.add arr(s.apart)
  bits.add wrapped("\"at\":[" & at.join(",") & "]")
  bits.add wrapped("\"p\":[" & pts.join(",") & "]")
  bits.add wrapped("\"j\":[" & angs.join(",") & "]")
  bits.add wrapped("\"g\":[" & grp.join(",") & "]")
  bits.add wrapped("\"d\":[" & apart.join(",") & "]")
  bits.add wrapped("\"f\":[" & look.join(",") & "]")
  "{" & bits.join(",\n") & "}"


type Job = object ## One recording: sweep by its place in `SHOWN`, or still by its ask.
  cut: int
  ask: StillAsk
  still: bool

func jobs(): seq[Job] =
  ## Every recording, sweeps first then every still card in page's own order.
  for i in 0 ..< SHOWN.len: result.add Job(cut: i, still: false)
  for a in stillAsks(): result.add Job(ask: a, still: true)

var
  bodies: seq[string] ## Each recording's text, written by whichever worker did it.
  notes: seq[string]  ## And one line saying what it found.

proc work(slice: tuple[first, every: int]) {.thread.} =
  ## Record every `every`th job from `first` on.  Each worker lists jobs for
  ## itself, as `design/modelled` does: one list read by four threads raced on
  ## its strings' counts.
  {.cast(gcsafe).}:
    let all = jobs()
    var i = slice.first
    while i < all.len:
      let j = all[i]
      if j.still:
        let a = j.ask
        let sh = still(HUMAN, Band.Crown, a.links, a.key, a.turns, away = a.away,
                       head = a.head, either = a.either)
        notes[i] = (if sh.stills.len > 0: &"{a.key}: {sh.turns:+.2f} turns, stood {sh.apart:.2f}"
                    else: &"{a.key}: {a.turns:+.2f} turns, no pose holds")
        bodies[i] = bodyOfSweep(sh, a.key)
      else:
        let cut = SHOWN[j.cut]
        var links: seq[Link] = @[]
        for (a, b) in cut.arms:
          links.add Link(ends: [(Body.One, a), (Body.Two, b)])
        let sh = shown(HUMAN, cut.band, links, cut.name, away = cut.away)
        notes[i] = &"{cut.name}, {BANDS[ord(cut.band)]}: stood {sh.apart:.2f}, " &
                   &"{sh.stills.len} moments, {sh.turns:.2f} {sh.why}"
        bodies[i] = bodyOfSweep(sh)
      i += slice.every


when isMainModule:
  # Recorded on every core at once: sweeps and stills each build their own
  # worlds and share nothing but their two slots.
  let count = jobs().len
  bodies = newSeq[string](count)
  notes = newSeq[string](count)
  let cores = max(1, countProcessors())
  var workers = newSeq[Thread[tuple[first, every: int]]](cores)
  for w in 0 ..< cores:
    createThread(workers[w], work, (w, cores))
  joinThreads(workers)
  for n in notes: echo n
  # Every still card, wound to its facing from distance that sits easiest.
  #   Recorded whole, one moment each, so viewer can lay sim's answer beside
  #   each cell of reference; card no distance holds is recorded with no moment.
  let
    cuts = bodies[0 ..< SHOWN.len]
    stills = bodies[SHOWN.len ..< count]
  var head: seq[string]
  head.add "\"upper\":" & num(HUMAN.upper)
  head.add "\"fore\":" & num(HUMAN.fore)
  head.add "\"hand\":" & num(HUMAN.hand)
  head.add "\"dofs\":[\"extend\",\"across\",\"twist\",\"bend\",\"wrist\"]"
  head.add "\"marks\":[\"trunk\",\"upper\",\"fore\",\"palm\",\"girdle\"]"
  head.add "\"sweeps\":[\n" & cuts.join(",\n") & "]"
  head.add "\"stills\":[\n" & stills.join(",\n") & "]"
  let path = "design" / "rig.json"
  writeFile(path, "{" & head.join(",\n") & "}\n")
  echo "wrote ", path
