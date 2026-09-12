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
##   Usage: rig          writes design/rig.json

{.experimental: "strictFuncs".}

import std/[math, os, strformat, strutils]

import ../sim/[body, hold, rig, seen, walk]


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

func wrapped(s: string; width = 92): string =
  ## Break long run of figures across lines after commas.  Charter holds every
  ## committed file to hundred columns, and one sweep's points on one line runs
  ## to hundreds of thousands.
  ##   Only figures go through here, never text: hold's name carries comma of its
  ##     own, and breaking inside it would be breaking inside string.
  var line = 0
  for ch in s:
    result.add ch
    line += 1
    if ch == ',' and line >= width:
      result.add '\n'
      line = 0


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


proc bodyOfSweep(sh: Shown): string =
  ## One sweep as page reads it.
  var bits: seq[string]
  bits.add &"\"hold\":\"{sh.hold}\""
  bits.add &"\"band\":\"{BANDS[ord(sh.band)]}\""
  bits.add &"\"apart\":{num(sh.apart)}"
  bits.add &"\"turns\":{num(sh.turns)}"
  bits.add &"\"stopped\":" & (if sh.stopped: "true" else: "false")
  bits.add &"\"why\":\"{sh.why}\""
  bits.add "\"says\":\"" & sh.why.says & "\""
  bits.add &"\"whose\":[{ord(sh.whose.body)},{ord(sh.whose.arm)}]"
  if sh.stills.len == 0:
    bits.add "\"stills\":[]"
    return "{" & bits.join(",") & "}"
  let first = sh.stills[0]
  var tag, rad: seq[string]
  for b in first.bars:
    tag.add &"[{ord(b.who)},{ord(b.arm)},{ord(b.mark)}]"
    rad.add num(b.r)
  bits.add "\"tag\":" & wrapped("[" & tag.join(",") & "]")
  bits.add "\"rad\":" & wrapped("[" & rad.join(",") & "]")
  var owner, lo, hi: seq[string]
  for a in first.arms:
    owner.add &"[{ord(a.who)},{ord(a.arm)}]"
    for d in Dof:
      lo.add num(a.lo[d])
      hi.add num(a.hi[d])
  bits.add "\"arm\":" & wrapped("[" & owner.join(",") & "]")
  bits.add "\"lo\":" & wrapped("[" & lo.join(",") & "]")
  bits.add "\"hi\":" & wrapped("[" & hi.join(",") & "]")
  var at, pts, angs, grp, apart, look: seq[string]
  for s in sh.stills:
    at.add num(s.at)
    look.add arr(s.looking)
    pts.add arr(s.flat)
    angs.add arr(s.angles)
    grp.add arr(s.gripped)
    apart.add arr(s.apart)
  bits.add "\"at\":" & wrapped("[" & at.join(",") & "]")
  bits.add "\"p\":" & wrapped("[" & pts.join(",") & "]")
  bits.add "\"j\":" & wrapped("[" & angs.join(",") & "]")
  bits.add "\"g\":" & wrapped("[" & grp.join(",") & "]")
  bits.add "\"d\":" & wrapped("[" & apart.join(",") & "]")
  bits.add "\"f\":" & wrapped("[" & look.join(",") & "]")
  "{" & bits.join(",\n") & "}"


when isMainModule:
  var cuts: seq[string]
  for cut in SHOWN:
    var links: seq[Link] = @[]
    for (a, b) in cut.arms:
      links.add Link(ends: [(Body.One, a), (Body.Two, b)])
    let sh = shown(HUMAN, cut.band, links, cut.name, away = cut.away)
    echo &"{cut.name}, {BANDS[ord(cut.band)]}: stood {sh.apart:.2f}, " &
         &"{sh.stills.len} moments, {sh.turns:.2f} {sh.why}"
    cuts.add bodyOfSweep(sh)
  var head: seq[string]
  head.add "\"upper\":" & num(HUMAN.upper)
  head.add "\"fore\":" & num(HUMAN.fore)
  head.add "\"hand\":" & num(HUMAN.hand)
  head.add "\"dofs\":[\"extend\",\"across\",\"twist\",\"bend\",\"wrist\"]"
  head.add "\"marks\":[\"trunk\",\"upper\",\"fore\",\"palm\"]"
  head.add "\"sweeps\":[\n" & cuts.join(",\n") & "]"
  let path = "design" / "rig.json"
  writeFile(path, "{" & head.join(",\n") & "}\n")
  echo "wrote ", path
