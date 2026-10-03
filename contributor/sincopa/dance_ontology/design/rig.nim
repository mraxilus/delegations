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
##     wound to its facing as `walk.stood` winds it, so viewer can lay simulation's
##     answer beside each cell.
##
##   Recording is kept with stamp of physics, jobs and this verb (`design/stamps`), and verb
##     whose stamp is unchanged records nothing again.  Page leaves stamp out, so page changes
##     only where recording does.
##
##   Usage: rig          writes design/rig.json

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/[cpuinfo, json, math, os, sequtils, strformat, strutils, typedthreads]

import ../simulation/[body, hold, rig, seen]
import ./[asks, stamps]


const KEPT_RIG* = currentSourcePath().parentDir / "rig.json"
  ## Where recording is kept, with its stamp.


type
  Cut = tuple[name: string, arms: seq[(Arm, Arm)], is_away: bool, band: Band]

  Job* = object  ## One recording: sweep by its place in `SHOWN`, or still by its ask.
    cut: int
    ask: StillAsk
    is_still: bool

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
  PLACE = 4  ## Decimal places kept.  Tenth of millimetre on lengths, and finer
            ## than any reading on angles; more is noise from solver's own jitter.
  BANDS = ["torso", "neck", "above"]


func figure(value: float): string =
  ## Shortest text that still says figure to `PLACE`, with no trailing nought.
  ##   Nought is written `0` rather than `0.0000`: file holds tens of thousands
  ##     of them and page reads both same way.
  if value == 0.0 or abs(value) < 0.5 / (10.0 ^ PLACE):
    return "0"
  result = formatFloat(value, ffDecimal, PLACE)
  result = result.strip(leading = false, chars = {'0'})
  if result.endsWith('.'): result.setLen(result.len - 1)

func jsonArray(values: seq[float]): string =
  ## Write figures as JSON array, each to `PLACE` decimal places.
  var bits: seq[string]
  for value in values: bits.add figure(value)
  "[" & bits.join(",") & "]"

func wrapped(text: string, width = 96): string =
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
  while i < text.len:
    var j = i
    while j < text.len and text[j] != ',': j += 1
    if j < text.len: j += 1
    let piece = text[i..<j]
    if line > 0 and line + piece.len > width:
      result.add '\n'
      line = 0
    result.add piece
    line += piece.len
    i = j


func flat(moment: Still): seq[float] =
  ## Every capsule's two ends, one after another.
  for bar in moment.bars:
    result.add [bar.a.x, bar.a.y, bar.a.z, bar.z.x, bar.z.y, bar.z.z]

func angles(moment: Still): seq[float] =
  ## Every arm's five joints, one arm after another.
  for arm in moment.arms:
    for dof in Dof: result.add arm.read[dof]

func looking(moment: Still): seq[float] =
  ## Each dancer's axis and which way they look, one after other.
  for who in Body:
    result.add [moment.faces[who].at.x, moment.faces[who].at.y,
                moment.faces[who].fore.x, moment.faces[who].fore.y]

func gripped(moment: Still): seq[float] =
  ## List every grip's three coordinates, one grip after another.
  for grip in moment.grips: result.add [grip.x, grip.y, grip.z]


proc bodyOfSweep(recording: Shown, key = ""): string =
  ## One sweep as page reads it, or one still, keyed by question it answers.
  var bits: seq[string]
  if key.len > 0:
    bits.add &"\"key\":\"{key}\""
  bits.add &"\"hold\":\"{recording.hold}\""
  bits.add &"\"band\":\"{BANDS[ord(recording.band)]}\""
  bits.add &"\"apart\":{figure(recording.apart)}"
  bits.add &"\"turns\":{figure(recording.turns)}"
  bits.add &"\"stopped\":" & (if recording.is_stopped: "true" else: "false")
  bits.add &"\"why\":\"{recording.why}\""
  bits.add "\"says\":\"" & (if key.len > 0 and recording.stills.len == 0:
                             "no pose holds at any distance"
                           else: recording.why.says) & "\""
  bits.add &"\"whose\":[{ord(recording.whose.body)},{ord(recording.whose.arm)}]"
  if recording.stills.len == 0:
    bits.add "\"stills\":[]"
    return "{" & bits.join(",\n") & "}"
  let first = recording.stills[0]
  var tag, radii: seq[string]
  for bar in first.bars:
    tag.add &"[{ord(bar.who)},{ord(bar.arm)},{ord(bar.mark)}]"
    radii.add figure(bar.radius)
  bits.add wrapped("\"tag\":[" & tag.join(",") & "]")
  bits.add wrapped("\"radii\":[" & radii.join(",") & "]")
  var owner, lower, upper: seq[string]
  for arm in first.arms:
    owner.add &"[{ord(arm.who)},{ord(arm.arm)}]"
    for dof in Dof:
      lower.add figure(arm.lower[dof])
      upper.add figure(arm.upper[dof])
  bits.add wrapped("\"arm\":[" & owner.join(",") & "]")
  bits.add wrapped("\"lower\":[" & lower.join(",") & "]")
  bits.add wrapped("\"upper\":[" & upper.join(",") & "]")
  var at, points, angles, grips, apart, look: seq[string]
  for moment in recording.stills:
    at.add figure(moment.at)
    look.add jsonArray(moment.looking)
    points.add jsonArray(moment.flat)
    angles.add jsonArray(moment.angles)
    grips.add jsonArray(moment.gripped)
    apart.add jsonArray(moment.apart)
  bits.add wrapped("\"at\":[" & at.join(",") & "]")
  bits.add wrapped("\"points\":[" & points.join(",") & "]")
  bits.add wrapped("\"angles\":[" & angles.join(",") & "]")
  bits.add wrapped("\"grips\":[" & grips.join(",") & "]")
  bits.add wrapped("\"gaps\":[" & apart.join(",") & "]")
  bits.add wrapped("\"faces\":[" & look.join(",") & "]")
  "{" & bits.join(",\n") & "}"


func jobs*(): seq[Job] =
  ## Every recording, sweeps first then every still card in page's own order.
  for i in 0..<SHOWN.len: result.add Job(cut: i, is_still: false)
  for ask in stillAsks(): result.add Job(ask: ask, is_still: true)

# Mutable and global: thread takes one argument, so workers write into slots allotted here.
var
  RECORDING_TEXTS: seq[string]  ## Each recording's text, written by whichever worker did it.
  NOTES: seq[string]  ## And one line saying what it found.

proc work(slice: tuple[first, every: int]) {.thread.} =
  ## Record every `every`th job from `first` on.  Each worker lists jobs for
  ## itself, as `design/modelled` does: one list read by four threads raced on
  ## its strings' counts.
  {.cast(gcsafe).}:
    let all = jobs()
    var i = slice.first
    while i < all.len:
      let job = all[i]
      if job.is_still:
        let
          ask = job.ask
          recording = still(
            HUMAN,
            Band.Crown,
            ask.links,
            ask.key,
            ask.turns,
            is_away = ask.isRestAway,
            head = ask.head,
            is_either_way = ask.is_either_way,
            who = ask.who,
          )
        NOTES[i] =
          if recording.stills.len > 0:
            &"{ask.key}: {recording.turns:+.2f} turns, stood {recording.apart:.2f}"
          else: &"{ask.key}: {ask.turns:+.2f} turns, no pose holds"
        RECORDING_TEXTS[i] = bodyOfSweep(recording, ask.key)
      else:
        let cut = SHOWN[job.cut]
        var links: seq[Link] = @[]
        for (lead_arm, follow_arm) in cut.arms:
          links.add Link(ends: [(Body.One, lead_arm), (Body.Two, follow_arm)])
        let recording = shown(HUMAN, cut.band, links, cut.name, is_away = cut.is_away)
        NOTES[i] = &"{cut.name}, {BANDS[ord(cut.band)]}: stood {recording.apart:.2f}, " &
                   &"{recording.stills.len} moments, {recording.turns:.2f} {recording.why}"
        RECORDING_TEXTS[i] = bodyOfSweep(recording)
      i += slice.every


proc rigStamp*(): string =
  ## Stamp recording carries: physics, this verb, and every job.
  ##   Sweep job names only its place in `SHOWN`, and `SHOWN` is in this verb's source.
  stampOf(currentSourcePath(), jobs().mapIt($it))


when isMainModule:
  let stamp = rigStamp()
  if fileExists(KEPT_RIG) and readFile(KEPT_RIG).parseJson{"stamp"}.getStr == stamp:
    echo "design/rig.json is up to date: ", stamp
    quit(0)
  # Recorded on every core at once: sweeps and stills each build their own
  # worlds and share nothing but their two slots.
  let count = jobs().len
  RECORDING_TEXTS = newSeq[string](count)
  NOTES = newSeq[string](count)
  let cores = max(1, countProcessors())
  var workers = newSeq[Thread[tuple[first, every: int]]](cores)
  for worker in 0..<cores:
    createThread(workers[worker], work, (worker, cores))
  joinThreads(workers)
  for note in NOTES: echo note
  # Every still card, wound to its facing from distance that sits easiest.
  #   Recorded whole, one moment each, so viewer can lay simulation's answer beside
  #   each cell of reference; card no distance holds is recorded with no moment.
  let
    cuts = RECORDING_TEXTS[0..<SHOWN.len]
    stills = RECORDING_TEXTS[SHOWN.len..<count]
  var head: seq[string]
  head.add "\"stamp\":\"" & stamp & "\""
  head.add "\"upper\":" & figure(HUMAN.upper)
  head.add "\"fore\":" & figure(HUMAN.fore)
  head.add "\"hand\":" & figure(HUMAN.hand)
  head.add "\"dofs\":[\"extend\",\"across\",\"twist\",\"bend\",\"wrist\"]"
  head.add "\"marks\":[\"trunk\",\"upper\",\"fore\",\"palm\",\"girdle\"]"
  head.add "\"sweeps\":[\n" & cuts.join(",\n") & "]"
  head.add "\"stills\":[\n" & stills.join(",\n") & "]"
  writeFile(KEPT_RIG, "{" & head.join(",\n") & "}\n")
  echo "wrote design/rig.json"
