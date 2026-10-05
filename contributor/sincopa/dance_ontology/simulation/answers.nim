## Answer once every search rig's laws ask, and keep answers with stamp of what gave them.
##
##   Laws of `tests/test_rigid.nim` ask where couple stand.  For sweep that is distance each way
##     carries furthest, for still distance nearest ease, and for `reaches` whether any
##     distance carries at all.  Each is search over every distance couple may stand at,
##     and answer changes only when simulation does.  Suite took 545 s under testament, and its
##     twenty laws that search for nothing took 22.8 s, each run alone: measured
##     2026-09-24 on four cores.
##   So they are answered here, by `tools/build.nim answers`, into `simulation/answers.json`, and
##     laws read answers.  Law still stands or walks couple live, at answered distance and
##     with current code, so every pose law holds is simulation's own on every run.  Only where to
##     stand is kept.
##   Kept answers are held to tree two ways.  Stamp is digest of every `simulation/*.nim` and
##     engine's pinned commit, and law fails where answers carry any other: simulation changed and
##     not answered again cannot pass.  And law walks kept answers again, live, and asks
##     same numbers of them: that is what catches compiler that answers otherwise.
##     Nim's version is not stamped.  Verbs of `tools/build.nim` run whichever `nim` is on
##     path and suite runs one koch pins, so stamp carrying it would agree on no machine
##     where they differ.  Answers from 2.2.4 walked same under 2.2.12, number for number,
##     measured 2026-09-24.
##   Cost: change to any `simulation/*.nim`, words included, asks for answering again, which takes
##     minutes.  Accepted -- digest of every file is one rule, where list of which files move
##     answers would be second thing to keep true.
##   Questions live here, not in suite, so asked and answered are one list.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/[algorithm, json, os, strutils, tables]

import ./[body, hold, rig, walk]


const
  HERE* = currentSourcePath().parentDir.parentDir
    ## Project directory, which every path below is relative to.
  KEPT* = HERE / "simulation" / "answers.json"  ## Where answers are kept.
  HASH_OFFSET = 0xcbf29ce484222325'u64
  HASH_PRIME = 0x100000001b3'u64

  SHAKE* = @[Link(ends: [(Body.One, Arm.Right), (Body.Two, Arm.Left)])]
    ## Plainest hold there is: one hand each, face to face.
  ASK* = 0.6  ## Turn laws put to that hold, in turns, turning her negative way.
    ## Chosen to make search work for its answer: measured 2026-09-13 with bodies
    ## solid, that hold carries 0.28 that way from first distance couple may stand
    ## at and 0.64 only from 0.70 to 0.72 m, so this is reached only by looking
    ## past first.  Turning her other way first distance carries most, 0.64, and
    ## search that gave up after one distance would answer correctly.  Before
    ## bodies were solid it carried 1.04, arm through torso.
  CHAIN* = @[Link(ends: [(Body.One, Arm.Left), (Body.Two, Arm.Left)]),
             Link(ends: [(Body.One, Arm.Right), (Body.Two, Arm.Right)])]
    ## Same-name chain, built Face-to-back: hold that stops from every distance at
    ## torso height.  Turn no distance carries has to be asked of hold that has one.
  BEYOND* = 1.2  ## Turn no distance carries that chain; best of them is 0.92, measured
                ## 2026-09-13 with shoulder girdles giving, against 0.42 before them.
  WOUND* = @[Link(ends: [(Body.One, Arm.Left), (Body.Two, Arm.Right)]),
             Link(ends: [(Body.One, Arm.Right), (Body.Two, Arm.Left)])]
    ## Cross-name chain, whose stills reference draws wound to turn and half.
  FREE*: seq[Link] = @[]  ## No hands joined.
  LEFT_TO_LEFT* = @[Link(ends: [(Body.One, Arm.Left), (Body.Two, Arm.Left)])]
    ## Single hold, left to left.
  RIGHT_TO_LEFT* = @[Link(ends: [(Body.One, Arm.Right), (Body.Two, Arm.Left)])]
    ## Single hold, right to left: standard diagram's A04 wound half.
  LEFT_TO_RIGHT* = @[Link(ends: [(Body.One, Arm.Left), (Body.Two, Arm.Right)])]
    ## Single hold, left to right.
  RIGHT_TO_RIGHT* = @[Link(ends: [(Body.One, Arm.Right), (Body.Two, Arm.Right)])]
    ## Single hold, right to right: left to left seen in mirror.


type
  SweepAsked* = tuple[key: string, band: Band, links: seq[Link], most: float, is_raw: bool]
    ## Hold swept both ways, each from distance that carries it furthest.  Raw sweep is
    ## engine's own, where simulation answers mirror twin as other twin reflected
    ## (`walk.swept`).
  WalkAsked* = tuple[key: string, band: Band, links: seq[Link], most, step: float]
    ## Hold walked one way from every distance, to hold search to argument maximum.
  ReachAsked* = tuple[key: string, band: Band, links: seq[Link], turns: float, is_away: bool]
    ## Whether any distance carries hold that far.
  StillAsked* = tuple[key: string, links: seq[Link], turns: float, is_away, is_either_way: bool]
    ## Still over crown, and distance couple stand at for it.

  Way* = object  ## One way of sweep, from distance search chose.
    is_holding*: bool  ## Whether hold stood at rest from any distance.
    apart*: float  ## Distance chosen, metres axis to axis.
    is_stopped*: bool
    at*: float  ## Turns reached when something gave.
    why*: Stop

  Ways* = object  ## Both ways of one sweep.
    negative*, positive*: Way

  Walked* = object  ## One walk from one distance, in numbers alone.
    apart*: float
    is_holding*: bool  ## Whether hold stood at rest there.
    is_stopped*: bool
    at*: float

  Stand* = object  ## Where couple stand for one still.
    is_holding*: bool
    apart*: float
    turns*: float  ## Way couple were wound there, signed.

  Answers* = object  ## Every search answered, and stamp of what answered it.
    stamp*: string
    sweeps*: OrderedTable[string, Ways]
    walks*: OrderedTable[string, seq[Walked]]
    reaches*: OrderedTable[string, bool]
    stills*: OrderedTable[string, Stand]

  Job* = enum Sweep, WalkFrom, Reach, Still
  Task* = tuple[job: Job, index, far: int]  ## One search, or one walk from one distance.

const
  SWEEPS*: array[7, SweepAsked] = [
    ("shake at torso", Band.Torso, SHAKE, 1.6, false),
    ("left to left at torso", Band.Torso, LEFT_TO_LEFT, 0.8, false),
    ("right to right at torso", Band.Torso, RIGHT_TO_RIGHT, 0.8, true),
    ("left to left over crown", Band.Crown, LEFT_TO_LEFT, 1.0, false),
    ("left to right over crown", Band.Crown, LEFT_TO_RIGHT, 1.0, false),
    ("left to right at torso", Band.Torso, LEFT_TO_RIGHT, 1.0, false),
    ("left to right at torso, as far as shake", Band.Torso, LEFT_TO_RIGHT, 1.6, false),
  ]  ## Every sweep laws stand couple for.
    ##   Right to right is raw, so law of mirror holds engine's own search to that of left
    ##     to left.  Left to right as far as shake is shake's twin, which law of twins reads.
  WALKS*: array[3, WalkAsked] = [
    ("shake at torso, negative", Band.Torso, SHAKE, 1.6, -STEP),
    ("shake at torso, positive", Band.Torso, SHAKE, 1.6, STEP),
    ("shake at torso, asked", Band.Torso, SHAKE, ASK, -STEP),
  ]  ## Every walk laws read from every distance.
  REACHES*: array[2, ReachAsked] = [
    ("shake asked", Band.Torso, SHAKE, -ASK, false),
    ("chain beyond", Band.Torso, CHAIN, BEYOND, true),
  ]  ## Every `reaches` laws ask.
  STILLS*: array[11, StillAsked] = [
    ("cross-name at -0.5", WOUND, -0.5, false, false),
    ("cross-name at +0.0", WOUND, 0.0, false, false),
    ("cross-name at +0.5", WOUND, 0.5, false, false),
    ("same-name at rest", CHAIN, 0.0, true, false),
    ("same-name at half, either way", CHAIN, -0.5, true, true),
    ("free, Face-to-back", FREE, 0.5, false, false),
    ("left to left at quarter", LEFT_TO_LEFT, 0.25, false, false),
    ("left to left at half", LEFT_TO_LEFT, 0.5, false, false),
    ("same-name at half", CHAIN, -0.5, true, false),
    ("right to left at half", RIGHT_TO_LEFT, 0.5, false, false),
    ("right to left at half, either way", RIGHT_TO_LEFT, 0.5, false, true),
  ]  ## Every still laws stand couple for.
  CORPUS* = 8  ## First stills of `STILLS`, which every still law reads; rest answer one law each.



#[ Stamp ]#

func feed(digest: var uint64, text: string) =
  ## Feed bytes to FNV-1a digest, with NUL after them so no two feeds run together.
  for character in text:
    digest = (digest xor uint64(ord(character))) * HASH_PRIME
  digest = digest * HASH_PRIME

func engineCommit*(build: string): string =
  ## Engine's pinned commit, read from `tools/build.nim` as text: first quoted forty
  ## hex digits after engine's name.  Empty where none is found, which stamp law
  ## refuses.
  const name = "\"box3d\""
  let at = build.find(name)
  if at < 0: return
  var opens = build.find('"', at + name.len)
  while opens >= 0:
    let shut = build.find('"', opens + 1)
    if shut < 0: return
    let quoted = build[opens+1..<shut]
    if quoted.len == 40 and quoted.allCharsInSet(HexDigits): return quoted
    opens = build.find('"', shut + 1)

proc stamp*(directory = HERE, leaving: openArray[string] = []): string =
  ## Digest of what answers depend on: every `simulation/*.nim` by name, in name order, and
  ## engine's pinned commit.  `leaving` names files it passes over.
  var files: seq[string]
  for path in walkFiles(directory / "simulation" / "*.nim"):
    if path.extractFilename notin leaving: files.add path
  files.sort
  var digest = HASH_OFFSET
  for path in files:
    digest.feed path.extractFilename
    digest.feed readFile(path)
  digest.feed engineCommit(readFile(directory / "tools" / "build.nim"))
  digest.toHex(16).toLowerAscii



#[ Reading ]#

proc kept*(path = KEPT): Answers =
  ## Answers as kept.
  let node = parseFile(path)
  node.to(Answers)

proc sweepOf*(answers: Answers, key: string): Ways =
  ## Kept sweep, or failure naming verb that answers it.
  doAssert key in answers.sweeps, "No sweep answered; run `nim r tools/build.nim answers`: got `" &
      key & "`."
  answers.sweeps[key]

proc walksOf*(answers: Answers, key: string): seq[Walked] =
  ## Kept walks from every distance, nearest first.
  doAssert key in answers.walks, "No walks answered; run `nim r tools/build.nim answers`: got `" &
      key & "`."
  answers.walks[key]

proc isReaching*(answers: Answers, key: string): bool =
  ## Kept answer of `reaches`.
  doAssert key in answers.reaches, "No reach answered; run `nim r tools/build.nim answers`: got `" &
      key & "`."
  answers.reaches[key]

proc stillOf*(answers: Answers, key: string): Stand =
  ## Kept distance couple stand at for still.
  doAssert key in answers.stills, "No still answered; run `nim r tools/build.nim answers`: got `" &
      key & "`."
  answers.stills[key]



#[ Parallel Answers ]#

func wayOf(walk: Walk): Way =
  ## Strip walk to numbers laws read.
  Way(
    is_holding: walk.found_rest,
    apart: walk.apart,
    is_stopped: walk.is_stopped,
    at: walk.at,
    why: walk.why,
  )


proc farsOf(): seq[float] =
  ## Every distance couple may stand at.
  for far in stands(HUMAN): result.add far

proc tasks*(): seq[Task] =
  ## Every task, in order asked: searches first and single walks last, so walks fill cores
  ## that searches leave idle at end.  `reaches` of hold no distance carries walks every
  ## distance, so it is taken first of all.
  for i in 0..<REACHES.len: result.add (Reach, i, 0)
  for i in 0..<SWEEPS.len: result.add (Sweep, i, 0)
  for i in 0..<STILLS.len: result.add (Still, i, 0)
  let count = farsOf().len
  for i in 0..<WALKS.len:
    for k in 0..<count: result.add (WalkFrom, i, k)

proc taskText*(task: Task): string =
  ## Answer one task, as text its file keeps.
  ##   Questions are constants, so each worker reads its own copy of every hold, and each
  ##     walk and search builds its own world and frees it.
  case task.job
  of Sweep:
    let
      question = SWEEPS[task.index]
      sweep = swept(HUMAN, question.band, question.links, most = question.most,
                    is_raw = question.is_raw)
    $(%Ways(negative: wayOf(sweep.negative), positive: wayOf(sweep.positive)))
  of WalkFrom:
    let
      question = WALKS[task.index]
      apart = farsOf()[task.far]
      walk = walked(
        HUMAN,
        question.band,
        question.links,
        Body.Two,
        apart,
        question.most,
        question.step,
        false,
        Body.Two,
      )
    $(%Walked(apart: apart, is_holding: walk.found_rest, is_stopped: walk.is_stopped,
              at: walk.at))
  of Reach:
    let question = REACHES[task.index]
    $(%isReaching(HUMAN, question.band, question.links, question.turns, question.is_away))
  of Still:
    let
      question = STILLS[task.index]
      got = standing(
        HUMAN,
        Band.Crown,
        question.links,
        question.turns,
        question.is_away,
        Body.Two,
        question.is_either_way,
      )
    $(%Stand(is_holding: got.is_holding, apart: got.apart, turns: got.turns))

proc assembled*(texts: seq[string]): string =
  ## Whole kept file from each task's text, in order of `tasks`.
  ##   Text is read back to answer it was written from: numbers are written shortest that
  ##     reads back same, so file is one that answers themselves would make.
  var
    swepts: array[SWEEPS.len, Ways]
    walkeds: array[WALKS.len, seq[Walked]]
    reached: array[REACHES.len, bool]
    stoods: array[STILLS.len, Stand]
  let count = farsOf().len
  for i in 0..<WALKS.len: walkeds[i] = newSeq[Walked](count)
  for i, task in tasks():
    let node = parseJson(texts[i])
    case task.job
    of Sweep: swepts[task.index] = node.to(Ways)
    of WalkFrom: walkeds[task.index][task.far] = node.to(Walked)
    of Reach: reached[task.index] = node.getBool
    of Still: stoods[task.index] = node.to(Stand)
  var got = Answers(stamp: stamp())
  for i, question in SWEEPS: got.sweeps[question.key] = swepts[i]
  for i, question in WALKS: got.walks[question.key] = walkeds[i]
  for i, question in REACHES: got.reaches[question.key] = reached[i]
  for i, question in STILLS: got.stills[question.key] = stoods[i]
  pretty(%got) & "\n"
