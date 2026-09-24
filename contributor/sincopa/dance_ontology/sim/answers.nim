## Answer once every search rig's laws ask, and keep answers with stamp of what gave them.
##
##   Laws of `tests/trigid.nim` ask where couple stand.  For sweep that is distance each way
##     carries furthest, for still distance nearest ease, and for `reaches` whether any
##     distance carries at all.  Each is search over every distance couple may stand at,
##     and answer changes only when sim does.  Suite took 545 s under testament, and its
##     twenty laws that search for nothing took 22.8 s, each run alone: measured
##     2026-09-24 on four cores.
##   So they are answered here, by `tools/build.nim answers`, into `sim/answers.json`, and
##     laws read answers.  Law still stands or walks couple live, at answered distance and
##     with current code, so every pose law holds is sim's own on every run.  Only where to
##     stand is kept.
##   Kept answers are held to tree two ways.  Stamp is digest of every `sim/*.nim` and
##     engine's pinned commit, and law fails where answers carry any other: sim changed and
##     not answered again cannot pass.  And law walks kept answers again, live, and asks
##     same numbers of them: that is what catches compiler that answers otherwise.
##     Nim's version is not stamped.  Verbs of `tools/build.nim` run whichever `nim` is on
##     path and suite runs one koch pins, so stamp carrying it would agree on no machine
##     where they differ.  Answers from 2.2.4 walked same under 2.2.12, number for number,
##     measured 2026-09-24.
##   Cost: change to any `sim/*.nim`, words included, asks for answering again, which takes
##     minutes.  Accepted -- digest of every file is one rule, where list of which files move
##     answers would be second thing to keep true.
##   Questions live here, not in suite, so asked and answered are one list.

{.experimental: "strictFuncs".}

import std/[algorithm, atomics, cpuinfo, json, os, strutils, tables, typedthreads]

import ./[body, hold, rig, walk]


const
  HERE* = currentSourcePath().parentDir.parentDir
    ## Project directory, which every path below is relative to.
  KEPT* = HERE / "sim" / "answers.json"
    ## Where answers are kept.
  FNV_OFFSET = 0xcbf29ce484222325'u64
  FNV_PRIME = 0x100000001b3'u64

  SHAKE* = @[Link(ends: [(Body.One, Arm.Right), (Body.Two, Arm.Left)])]
    ## Plainest hold there is: one hand each, face to face.
  ASK* = 0.6 ## Turn laws put to that hold, in turns, turning her negative way.
    ## Chosen to make search work for its answer: measured 2026-09-13 with bodies
    ## solid, that hold carries 0.28 that way from first distance couple may stand
    ## at and 0.64 only from 0.70 to 0.72 m, so this is reached only by looking
    ## past first.  Turning her other way first distance carries most, 0.64, and
    ## search that gave up after one distance would answer correctly.  Before
    ## bodies were solid it carried 1.04, arm through torso.
  CHAIN* = @[Link(ends: [(Body.One, Arm.Left), (Body.Two, Arm.Left)]),
             Link(ends: [(Body.One, Arm.Right), (Body.Two, Arm.Right)])]
    ## Same-name chain, built pillion: hold that stops from every distance at
    ## torso height.  Turn no distance carries has to be asked of hold that has one.
  BEYOND* = 1.2 ## Turn no distance carries that chain; best of them is 0.92, measured
                ## 2026-09-13 with shoulder girdles giving, against 0.42 before them.
  WOUND* = @[Link(ends: [(Body.One, Arm.Left), (Body.Two, Arm.Right)]),
             Link(ends: [(Body.One, Arm.Right), (Body.Two, Arm.Left)])]
    ## Cross-name chain, whose stills reference draws wound to turn and half.
  FREE*: seq[Link] = @[] ## No hands joined.
  ONE_L* = @[Link(ends: [(Body.One, Arm.Left), (Body.Two, Arm.Left)])]
    ## Single hold, left to left.
  ONE_R* = @[Link(ends: [(Body.One, Arm.Right), (Body.Two, Arm.Left)])]
    ## Single hold, right to left: standard diagram's A4 wound half.
  L_R* = @[Link(ends: [(Body.One, Arm.Left), (Body.Two, Arm.Right)])]
    ## Single hold, left to right.
  R_R* = @[Link(ends: [(Body.One, Arm.Right), (Body.Two, Arm.Right)])]
    ## Single hold, right to right: left to left seen in mirror.


type
  SweepAsked* = tuple[key: string, band: Band, links: seq[Link], most: float]
    ## Hold swept both ways, each from distance that carries it furthest.
  WalkAsked* = tuple[key: string, band: Band, links: seq[Link], most, step: float]
    ## Hold walked one way from every distance, to hold search to argument maximum.
  ReachAsked* = tuple[key: string, band: Band, links: seq[Link], turns: float, away: bool]
    ## Whether any distance carries hold that far.
  StillAsked* = tuple[key: string, links: seq[Link], turns: float, away, either: bool]
    ## Still over crown, and distance couple stand at for it.

const
  SWEEPS*: array[6, SweepAsked] = [
    ("shake at torso", Band.Torso, SHAKE, 1.6),
    ("left to left at torso", Band.Torso, ONE_L, 0.8),
    ("right to right at torso", Band.Torso, R_R, 0.8),
    ("left to left over crown", Band.Crown, ONE_L, 1.0),
    ("left to right over crown", Band.Crown, L_R, 1.0),
    ("left to right at torso", Band.Torso, L_R, 1.0),
  ] ## Every sweep laws stand couple for.
  WALKS*: array[3, WalkAsked] = [
    ("shake at torso, negative", Band.Torso, SHAKE, 1.6, -STEP),
    ("shake at torso, positive", Band.Torso, SHAKE, 1.6, STEP),
    ("shake at torso, asked", Band.Torso, SHAKE, ASK, -STEP),
  ] ## Every walk laws read from every distance.
  REACHES*: array[2, ReachAsked] = [
    ("shake asked", Band.Torso, SHAKE, -ASK, false),
    ("chain beyond", Band.Torso, CHAIN, BEYOND, true),
  ] ## Every `reaches` laws ask.
  STILLS*: array[11, StillAsked] = [
    ("cross-name at -0.5", WOUND, -0.5, false, false),
    ("cross-name at +0.0", WOUND, 0.0, false, false),
    ("cross-name at +0.5", WOUND, 0.5, false, false),
    ("same-name at rest", CHAIN, 0.0, true, false),
    ("same-name at half, either way", CHAIN, -0.5, true, true),
    ("free, pillion", FREE, 0.5, false, false),
    ("left to left at quarter", ONE_L, 0.25, false, false),
    ("left to left at half", ONE_L, 0.5, false, false),
    ("same-name at half", CHAIN, -0.5, true, false),
    ("right to left at half", ONE_R, 0.5, false, false),
    ("right to left at half, either way", ONE_R, 0.5, false, true),
  ] ## Every still laws stand couple for.
  CORPUS* = 8
    ## First stills of `STILLS`, which every still law reads; rest answer one law each.


type
  Way* = object ## One way of sweep, from distance search chose.
    holds*: bool  ## Whether hold stood at rest from any distance.
    apart*: float ## Distance chosen, metres axis to axis.
    stopped*: bool
    at*: float    ## Turns reached when something gave.
    why*: Stop

  Ways* = object ## Both ways of one sweep.
    neg*, pos*: Way

  Walked* = object ## One walk from one distance, in numbers alone.
    apart*: float
    holds*: bool ## Whether hold stood at rest there.
    stopped*: bool
    at*: float

  Stand* = object ## Where couple stand for one still.
    holds*: bool
    apart*: float
    turns*: float ## Way couple were wound there, signed.

  Answers* = object ## Every search answered, and stamp of what answered it.
    stamp*: string
    sweeps*: OrderedTable[string, Ways]
    walks*: OrderedTable[string, seq[Walked]]
    reaches*: OrderedTable[string, bool]
    stills*: OrderedTable[string, Stand]


#[ Stamp ]#

func feed(h: var uint64; s: string) =
  ## Feed bytes to FNV-1a digest, with NUL after them so no two feeds run together.
  for c in s:
    h = (h xor uint64(ord(c))) * FNV_PRIME
  h = h * FNV_PRIME

func engineCommit*(build: string): string =
  ## Engine's pinned commit, read from `tools/build.nim` as text: first quoted forty
  ## hex digits after engine's name.  Empty where none is found, which stamp law
  ## refuses.
  const NAME = "\"box3d\""
  let at = build.find(NAME)
  if at < 0: return
  var opens = build.find('"', at + NAME.len)
  while opens >= 0:
    let shut = build.find('"', opens + 1)
    if shut < 0: return
    let quoted = build[opens + 1 ..< shut]
    if quoted.len == 40 and quoted.allCharsInSet(HexDigits): return quoted
    opens = build.find('"', shut + 1)

proc stamp*(dir = HERE): string =
  ## Digest of what answers depend on: every `sim/*.nim` by name, in name order, and
  ## engine's pinned commit.
  var files: seq[string]
  for f in walkFiles(dir / "sim" / "*.nim"): files.add f
  files.sort
  var h = FNV_OFFSET
  for f in files:
    h.feed f.extractFilename
    h.feed readFile(f)
  h.feed engineCommit(readFile(dir / "tools" / "build.nim"))
  h.toHex(16).toLowerAscii


#[ Reading ]#

proc kept*(path = KEPT): Answers =
  ## Answers as kept.
  let node = parseFile(path)
  node.to(Answers)

proc sweepOf*(a: Answers; key: string): Ways =
  ## Kept sweep, or failure naming verb that answers it.
  doAssert key in a.sweeps, "No sweep answered; run `nim r tools/build.nim answers`: got `" &
    key & "`."
  a.sweeps[key]

proc walksOf*(a: Answers; key: string): seq[Walked] =
  ## Kept walks from every distance, nearest first.
  doAssert key in a.walks, "No walks answered; run `nim r tools/build.nim answers`: got `" &
    key & "`."
  a.walks[key]

proc reachOf*(a: Answers; key: string): bool =
  ## Kept answer of `reaches`.
  doAssert key in a.reaches, "No reach answered; run `nim r tools/build.nim answers`: got `" &
    key & "`."
  a.reaches[key]

proc stillOf*(a: Answers; key: string): Stand =
  ## Kept distance couple stand at for still.
  doAssert key in a.stills, "No still answered; run `nim r tools/build.nim answers`: got `" &
    key & "`."
  a.stills[key]


#[ Answering, Every Core At Once ]#

func wayOf(w: Walk): Way =
  ## Strip walk to numbers laws read.
  Way(holds: w.restHolds, apart: w.apart, stopped: w.stopped, at: w.at, why: w.why)

type
  Job = enum Sweep, WalkFrom, Reach, Still
  Task = tuple[job: Job, index, far: int] ## One search, or one walk from one distance.

var
  tasks: seq[Task]     ## Every task, longest first, set before any thread starts.
  next: Atomic[int]    ## Next task not yet taken.
  fars: seq[float]     ## Every distance couple may stand at.
  swepts: array[SWEEPS.len, Ways]
  walkeds: array[WALKS.len, seq[Walked]]
  reached: array[REACHES.len, bool]
  stoods: array[STILLS.len, Stand]

proc working(id: int) {.thread.} =
  ## Take tasks until none is left, and put each answer where it belongs.
  ##   Questions are constants, so each worker reads its own copy of every hold and
  ##     no list is shared between threads.  Each walk and search builds its own
  ##     world and frees it.  Answers are plain numbers, each written to place
  ##     allotted before any thread starts.
  {.cast(gcsafe).}:
    while true:
      let i = next.fetchAdd(1)
      if i >= tasks.len: return
      let t = tasks[i]
      case t.job
      of Sweep:
        let q = SWEEPS[t.index]
        let sw = swept(HUMAN, q.band, q.links, most = q.most)
        swepts[t.index] = Ways(neg: wayOf(sw.neg), pos: wayOf(sw.pos))
      of WalkFrom:
        let q = WALKS[t.index]
        let w = walked(HUMAN, q.band, q.links, Body.Two, fars[t.far], q.most, q.step,
                       false, Body.Two)
        walkeds[t.index][t.far] = Walked(apart: fars[t.far], holds: w.restHolds,
                                         stopped: w.stopped, at: w.at)
      of Reach:
        let q = REACHES[t.index]
        reached[t.index] = reaches(HUMAN, q.band, q.links, q.turns, q.away)
      of Still:
        let q = STILLS[t.index]
        let got = standing(HUMAN, Band.Crown, q.links, q.turns, q.away, Body.Two, q.either)
        stoods[t.index] = Stand(holds: got.holds, apart: got.apart, turns: got.turns)

proc answer*(): Answers =
  ## Answer every question, on every core at once.
  ##   Searches are taken first and single walks last, so walks fill cores that
  ##     searches leave idle at end.  `reaches` of hold no distance carries walks
  ##     every distance, so it is taken first of all.
  for far in stands(HUMAN): fars.add far
  for i in 0 ..< REACHES.len: tasks.add (Reach, i, 0)
  for i in 0 ..< SWEEPS.len: tasks.add (Sweep, i, 0)
  for i in 0 ..< STILLS.len: tasks.add (Still, i, 0)
  for i in 0 ..< WALKS.len:
    walkeds[i] = newSeq[Walked](fars.len)
    for k in 0 ..< fars.len: tasks.add (WalkFrom, i, k)
  next.store(0)
  let cores = max(1, countProcessors())
  var workers = newSeq[Thread[int]](cores)
  for w in 0 ..< cores: createThread(workers[w], working, w)
  joinThreads(workers)
  result.stamp = stamp()
  for i, q in SWEEPS: result.sweeps[q.key] = swepts[i]
  for i, q in WALKS: result.walks[q.key] = walkeds[i]
  for i, q in REACHES: result.reaches[q.key] = reached[i]
  for i, q in STILLS: result.stills[q.key] = stoods[i]


when isMainModule:
  let got = answer()
  writeFile(KEPT, pretty(%got) & "\n")
  echo "wrote ", KEPT
