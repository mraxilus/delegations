## Read what report says off sim once, on every core, and keep it with stamp of physics.
##
##   Report (`verdicts`) is words over numbers.  Numbers take sweeps and stills that
##     walk turn through engine from every distance couple may stand at: 33 minutes on one
##     core, measured 2026-09-26, where words take none.  So numbers are read here into
##     plain readings and kept in `sim/verdicts.json`, and report renders words from
##     them.  Change to words alone renders again in seconds.
##   Readings are held to physics by stamp: digest of every `sim/*.nim` but those that
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
  KEPT_READINGS* = HERE / "sim" / "verdicts.json"
    ## Where readings are kept, beside report they render.
  LEAVING* = ["verdicts.nim", "words.nim", "answers.nim"]
    ## Files stamp leaves out: report's words, words themselves, and laws' questions.
  HALVES* = [-4, -3, -2, -1, 0, 1, 2, 3, 4] ## Turns report reads each sweep at, in halves.
  CROSSED = 8 ## Crossings one moment keeps, at most: two turns wound make four.


type
  Glance* = object ## One moment of sweep, as report reads it.
    got*: bool ## Whether sweep reached this moment at all.
    lies*: array[2, array[Body, Option[Lying]]]
      ## Where each connection's arm lies on its own body, by body.
    strain*: float ## Of tightest joint (`tightest`).
    handZ*: float  ## Height of first connection's hand, metres.
    crossed*: int  ## How many times connections cross in plan.
    over*: array[CROSSED, int] ## Which connection is over, at each crossing.

  WayRead* = object ## One way of sweep, as report reads it.
    stopped*: bool
    at*, apart*: float
    why*: Stop
    whose*: Hand

  SweepRead* = object ## Sweep of one hold, as report reads it.
    restHolds*: bool
    neg*, pos*: WayRead
    glances*: array[HALVES.len, Glance]

  RungRead* = object ## One rung of chain asked still, as report reads it.
    found*: bool   ## Whether pose holds there from any distance.
    apart*: float  ## First distance it holds from.
    strain*: float
    crossed*: int

  SweepAsk* = object ## Sweep report asks for, as plain values.
    band*: Band
    links*: array[2, Link]
    count*: int ## How many of `links` hold.
    who*: Body
    away*: bool
    apart*: float

  RungAsk* = object ## Rung of cross-name chain report asks for.
    band*: Band
    turn*: float

  Readings* = object ## Every reading kept, by what it is of, and stamp of physics.
    stamp*: string
    sweeps*: OrderedTable[string, SweepRead]
    rungs*: OrderedTable[string, RungRead]


const CHAIN* = [Link(ends: [(Body.One, Arm.Left), (Body.Two, Arm.Right)]),
                Link(ends: [(Body.One, Arm.Right), (Body.Two, Arm.Left)])]
  ## Cross-name chain, L-r.R-l, whose rungs report asks still.


func linksOf*(a: SweepAsk): seq[Link] =
  ## Connections sweep asks for.
  for i in 0 ..< a.count: result.add a.links[i]

func askOf*(band: Band; links: seq[Link]; who: Body; away: bool; apart: float): SweepAsk =
  ## Sweep ask as plain values.
  result = SweepAsk(band: band, count: links.len, who: who, away: away, apart: apart)
  for i, link in links: result.links[i] = link

func keyOf*(a: SweepAsk): string =
  ## Name sweep by all it is of.
  result = $ord(a.who) & "|" & $ord(a.band) & "|" & $a.away & "|" & $a.apart
  for link in a.linksOf:
    result.add "|" & $ord(link.ends[0].arm) & $ord(link.ends[1].arm)

func keyOf*(a: RungAsk): string = $ord(a.band) & "|" & $a.turn
  ## Name rung by band and turn.


#[ Reading one ]#

func momentAt*(sw: Swept; t: float): Option[Moment] =
  ## Moment nearest `t` turns, from whichever way reaches it; none where neither does.
  let way = (if t < 0.0: sw.neg else: sw.pos)
  var best: Option[Moment]
  for m in way.moments:
    if abs(m.at - t) < 0.011 and (best.isNone or abs(m.at - t) < abs(best.get.at - t)):
      best = some m
  best

func glanceOf(band: Band; links: seq[Link]; mo: Moment): Glance =
  ## Read one moment as report reads it.
  result.got = true
  for k in 0 ..< links.len:
    for who in Body:
      result.lies[k][who] = lyingOn(HUMAN, band, links, mo.stance, mo.arms, k, who)
  result.strain = tightest(HUMAN, mo.stance, links, mo.arms).strain
  result.handZ = mo.arms[0][0].g.z
  for c in crossings(mo.arms):
    if result.crossed < CROSSED: result.over[result.crossed] = c.over
    inc result.crossed

func wayOf(w: Walk): WayRead =
  WayRead(stopped: w.stopped, at: w.at, apart: w.apart, why: w.why, whose: w.whose)

proc readSweep*(a: SweepAsk): SweepRead =
  ## Sweep hold, and read it as report reads it.
  let
    links = a.linksOf
    sw = swept(HUMAN, a.band, links, who = a.who, most = MOST, away = a.away,
               apart = a.apart)
  result.restHolds = sw.restHolds
  result.neg = wayOf(sw.neg)
  result.pos = wayOf(sw.pos)
  for i, h in HALVES:
    let m = momentAt(sw, float(h) / 2.0)
    if m.isSome: result.glances[i] = glanceOf(a.band, links, m.get)

proc readRung*(a: RungAsk): RungRead =
  ## Wind cross-name chain to rung and ask whether pose holds there standing, from
  ## every distance, and read first that holds.
  let links = @CHAIN
  for apart in stands(HUMAN):
    let (holds, c) = stood(HUMAN, a.band, links, a.turn, false, Body.Two, apart)
    if holds:
      var arms: Arms
      for i in 0 ..< links.len: arms.add c.poseOf(i).arms
      result = RungRead(
        found: true,
        apart: apart,
        strain: tightest(HUMAN, c.stance, links, arms).strain,
        crossed: crossings(arms).len,
      )
    c.free()
    if result.found: return


#[ Reading all, every core at once ]#

# Mutable and global: thread takes one argument, so workers read asks and write readings
# into slots allotted here before any thread starts.
var
  SWEEP_ASKS: seq[SweepAsk]  ## Set before any thread starts, then only read.
  RUNG_ASKS: seq[RungAsk]
  SWEEP_READS: seq[SweepRead] ## Each worker writes its own into place allotted.
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

proc readAll*(sweeps: seq[SweepAsk]; rungs: seq[RungAsk]): tuple[sweeps: seq[SweepRead],
    rungs: seq[RungRead]] =
  ## Read every ask, on every core at once, in order asked.
  SWEEP_ASKS = sweeps
  RUNG_ASKS = rungs
  SWEEP_READS = newSeq[SweepRead](sweeps.len)
  RUNG_READS = newSeq[RungRead](rungs.len)
  ASK_NEXT.store(0)
  var workers = newSeq[Thread[int]](max(1, countProcessors()))
  for w in 0 ..< workers.len: createThread(workers[w], working, w)
  joinThreads(workers)
  (SWEEP_READS, RUNG_READS)


#[ Keeping ]#

proc physics*(dir = HERE): string = stamp(dir, LEAVING)
  ## Stamp of what readings depend on.

proc keptReadings*(path = KEPT_READINGS): Readings =
  ## Readings as kept, or none where file is missing or stamp is other.
  if not fileExists(path): return
  let got = parseFile(path).jsonTo(Readings)
  if got.stamp == physics(): got else: Readings()

proc keep*(r: Readings; path = KEPT_READINGS) =
  ## Write readings, sorted by key so file changes only where readings do.
  var sorted = Readings(stamp: r.stamp)
  var keys = toSeq(r.sweeps.keys)
  keys.sort
  for k in keys: sorted.sweeps[k] = r.sweeps[k]
  keys = toSeq(r.rungs.keys)
  keys.sort
  for k in keys: sorted.rungs[k] = r.rungs[k]
  writeFile(path, pretty(sorted.toJson) & "\n")
