## Read what report says off simulation once, on every core, and keep it with stamp of physics.
##
##   Report (`verdicts`) is words over numbers.  Numbers take sweeps and stills that
##     walk turn through engine from every distance couple may stand at: 33 minutes on one
##     core, measured 2026-09-26, where words take none.  So numbers are read here into
##     plain readings and kept in `simulation/verdicts.json`, and report renders words from
##     them.  Change to words alone renders again in seconds.
##   Readings are held to physics by stamp: digest of every `simulation/*.nim` but those that
##     only say words or ask laws' questions (`LEAVING`), and engine's pinned commit.
##     Other stamp reads nothing kept, and everything is read again.
##   Readings are plain values, with no string and no sequence in them, so each worker
##     writes its own into place allotted before any thread starts, as `answers` does.
##   Report says which readings it wants by rendering: reading it lacks is asked for,
##     and render that lacked any is thrown away.  List of what report asks is never
##     written twice.

{.experimental: "strictFuncs".}

import std/[algorithm, atomics, cpuinfo, json, jsonutils, options, os, sequtils, tables,
            typedthreads]

import ./[answers, body, hold, read, rig, rigid, walk]


const
  KEPT_READINGS* = HERE / "simulation" / "verdicts.json"
    ## Where readings are kept, beside report they render.
  LEAVING* = ["verdicts.nim", "words.nim", "answers.nim"]
    ## Files stamp leaves out: report's words, words themselves, and laws' questions.
  HALVES* = [-4, -3, -2, -1, 0, 1, 2, 3, 4]  ## Turns report reads each sweep at, in halves.
  CROSSED = 8  ## Crossings one moment keeps, at most: two turns wound make four.


type
  Glance* = object  ## One moment of sweep, as report reads it.
    is_reached*: bool  ## Whether sweep reached this moment at all.
    lies*: array[2, array[Body, Option[Lying]]]
      ## Where each connection's arm lies on its own body, by body.
    strain*: float  ## Of tightest joint (`tightest`).
    hand_height*: float  ## Height of first connection's hand, metres.
    crossed*: int  ## How many times connections cross in plan.
    over*: array[CROSSED, int]  ## Which connection is over, at each crossing.

  WayRead* = object  ## One way of sweep, as report reads it.
    is_stopped*: bool
    at*, apart*: float
    why*: Stop
    whose*: Hand

  SweepRead* = object  ## Sweep of one hold, as report reads it.
    found_rest*: bool
    negative*, positive*: WayRead
    glances*: array[HALVES.len, Glance]

  RungRead* = object  ## One rung of chain asked still, as report reads it.
    found_pose*: bool  ## Whether pose holds there from any distance.
    apart*: float  ## First distance it holds from.
    strain*: float
    crossed*: int

  SweepAsk* = object  ## Sweep report asks for, as plain values.
    band*: Band
    links*: array[2, Link]
    count*: int  ## How many of `links` hold.
    who*: Body
    is_away*: bool
    apart*: float

  RungAsk* = object  ## Rung of cross-name chain report asks for.
    band*: Band
    turn*: float

  Readings* = object  ## Every reading kept, by what it is of, and stamp of physics.
    stamp*: string
    sweeps*: OrderedTable[string, SweepRead]
    rungs*: OrderedTable[string, RungRead]


const CHAIN* = [Link(ends: [(Body.One, Arm.Left), (Body.Two, Arm.Right)]),
                Link(ends: [(Body.One, Arm.Right), (Body.Two, Arm.Left)])]
  ## Cross-name chain, L-r.R-l, whose rungs report asks still.


func linksOf*(ask: SweepAsk): seq[Link] =
  ## Connections sweep asks for.
  for i in 0..<ask.count: result.add ask.links[i]

func askOf*(band: Band, links: seq[Link], who: Body, is_away: bool, apart: float): SweepAsk =
  ## Sweep ask as plain values.
  result = SweepAsk(band: band, count: links.len, who: who, is_away: is_away, apart: apart)
  for i, link in links: result.links[i] = link

func keyOf*(ask: SweepAsk): string =
  ## Name sweep by all it is of.
  result = $ord(ask.who) & "|" & $ord(ask.band) & "|" & $ask.is_away & "|" & $ask.apart
  for link in ask.linksOf:
    result.add "|" & $ord(link.ends[0].arm) & $ord(link.ends[1].arm)

func keyOf*(ask: RungAsk): string = $ord(ask.band) & "|" & $ask.turn
  ## Name rung by band and turn.



#[ Single Reading ]#

func momentAt*(sweep: Swept, at: float): Option[Moment] =
  ## Moment nearest `at` turns, from whichever way reaches it; none where neither does.
  let way = (if at < 0.0: sweep.negative else: sweep.positive)
  var best: Option[Moment]
  for moment in way.moments:
    if abs(moment.at - at) < 0.011 and (best.isNone or abs(moment.at - at) < abs(best.get.at - at)):
      best = some moment
  best

func glanceOf(band: Band, links: seq[Link], moment: Moment): Glance =
  ## Read one moment as report reads it.
  result.is_reached = true
  for k in 0..<links.len:
    for who in Body:
      result.lies[k][who] = lyingOn(HUMAN, band, links, moment.stance, moment.arms, k, who)
  result.strain = tightest(HUMAN, moment.stance, links, moment.arms).strain
  result.hand_height = moment.arms[0][0].grip.z
  for crossing in crossings(moment.arms):
    if result.crossed < CROSSED: result.over[result.crossed] = crossing.over
    inc result.crossed

func wayOf(walk: Walk): WayRead =
  ## Read one way of sweep as report reads it.
  WayRead(
    is_stopped: walk.is_stopped,
    at: walk.at,
    apart: walk.apart,
    why: walk.why,
    whose: walk.whose,
  )

proc readSweep*(ask: SweepAsk): SweepRead =
  ## Sweep hold, and read it as report reads it.
  let
    links = ask.linksOf
    sweep = swept(
      HUMAN,
      ask.band,
      links,
      who = ask.who,
      most = MOST,
      is_away = ask.is_away,
      apart = ask.apart,
    )
  result.found_rest = sweep.found_rest
  result.negative = wayOf(sweep.negative)
  result.positive = wayOf(sweep.positive)
  for i, half_turns in HALVES:
    let moment = momentAt(sweep, float(half_turns) / 2.0)
    if moment.isSome: result.glances[i] = glanceOf(ask.band, links, moment.get)

proc readRung*(ask: RungAsk): RungRead =
  ## Wind cross-name chain to rung and ask whether pose holds there standing, from
  ## every distance, and read first that holds.
  let links = @CHAIN
  for apart in stands(HUMAN):
    let (is_holding, couple) = stood(HUMAN, ask.band, links, ask.turn, false, Body.Two, apart)
    if is_holding:
      var arms: Arms
      for i in 0..<links.len: arms.add couple.poseOf(i).arms
      result = RungRead(
        found_pose: true,
        apart: apart,
        strain: tightest(HUMAN, couple.stance, links, arms).strain,
        crossed: crossings(arms).len,
      )
    couple.free()
    if result.found_pose: return



#[ Parallel Reading ]#

# Mutable and global: thread takes one argument, so workers read asks and write readings
# into slots allotted here before any thread starts.
var
  SWEEP_ASKS: seq[SweepAsk]  ## Set before any thread starts, then only read.
  RUNG_ASKS: seq[RungAsk]
  SWEEP_READS: seq[SweepRead]  ## Each worker writes its own into place allotted.
  RUNG_READS: seq[RungRead]
  ASK_NEXT: Atomic[int]

proc working(id: int) {.thread.} =
  ## Take asks until none is left.  Rungs first: rung no distance holds walks every one.
  {.cast(gcsafe).}:
    while true:
      let i = ASK_NEXT.fetchAdd(1)
      if i >= RUNG_ASKS.len + SWEEP_ASKS.len: return
      if i < RUNG_ASKS.len: RUNG_READS[i] = readRung(RUNG_ASKS[i])
      else: SWEEP_READS[i - RUNG_ASKS.len] = readSweep(SWEEP_ASKS[i - RUNG_ASKS.len])

proc readAll*(sweeps: seq[SweepAsk], rungs: seq[RungAsk]): tuple[sweeps: seq[SweepRead],
    rungs: seq[RungRead]] =
  ## Read every ask, on every core at once, in order asked.
  SWEEP_ASKS = sweeps
  RUNG_ASKS = rungs
  SWEEP_READS = newSeq[SweepRead](sweeps.len)
  RUNG_READS = newSeq[RungRead](rungs.len)
  ASK_NEXT.store(0)
  var workers = newSeq[Thread[int]](max(1, countProcessors()))
  for worker in 0..<workers.len: createThread(workers[worker], working, worker)
  joinThreads(workers)
  (SWEEP_READS, RUNG_READS)



#[ Kept Readings ]#

proc physics*(directory = HERE): string = stamp(directory, LEAVING)
  ## Stamp of what readings depend on.

proc keptReadings*(path = KEPT_READINGS): Readings =
  ## Readings as kept, or none where file is missing or stamp is other.
  ##   Stamp is read before shape: readings of other physics may be of other shape.
  if not fileExists(path): return
  let node = parseFile(path)
  if node{"stamp"}.getStr == physics(): node.jsonTo(Readings) else: Readings()

proc keep*(readings: Readings, path = KEPT_READINGS) =
  ## Write readings, sorted by key so file changes only where readings do.
  var
    sorted = Readings(stamp: readings.stamp)
    keys = readings.sweeps.keys.toSeq
  keys.sort
  for key in keys: sorted.sweeps[key] = readings.sweeps[key]
  keys = readings.rungs.keys.toSeq
  keys.sort
  for key in keys: sorted.rungs[key] = readings.rungs[key]
  writeFile(path, pretty(sorted.toJson) & "\n")
