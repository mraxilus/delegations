## Time and count every catalogued probe, library side and reference side, from one entry.
##   Each probe becomes one timed loop over its pool, `ROUNDS` times, median and minimum
##   nanoseconds per object reported. Around every timed run, allocation counters are read
##   so any heap use shows as count, and every result is folded into one sink after timing
##   so nothing is optimised away; share of results carrying NaN is counted alongside, since
##   library's conformal norms return NaN on real objects and that is measured, not stated.
##   Operands are aliases into pools (template, never `let`), so loop reads pool slot and
##   writes result slot: what moves is operation's own traffic.
##
##   Instrument gates: allocation counts are live only under `-d:nimAllocStats`, and
##     `isAllocationMeasured` says so, since counter reading zero means nothing otherwise
##     (Article VII.4); driver runs plain build for timings and instrumented one for counts.
##   Cost: figures arrays hold one entry per probe per side; sink is one float.
##   Cost: pairing slot i with slot (7i + 3) mod OBJECTS costs integer ops both sides.

{.experimental: "strictFuncs".}

import std/[algorithm, macros, math, monotimes, strutils, times]

import pga

import ./[bridge, catalogue, kinds, pools]


type
  Side* {.pure.} = enum
    ## Define which implementation figure belongs to.
    Library, Reference
  Figure* = object
    ## Define figures of one probe on one side.
    is_measured*: bool
      ## False where side has no expression, i.e. reference absent.
    ns_median*, ns_min*: float
      ## Nanoseconds per object, median and minimum over rounds.
    allocations*: int
      ## Heap allocations counted over every round; meaningful only when instrument is live.
    nan_share*: float
      ## Share of results carrying NaN in any component.


var
  FIGURES*: array[Side, array[PROBES.len, Figure]]
    ## Figures of every probe, filled by `runProbes`.
  SINK*: float
    ## Fold of every result, printed so no result is dead.


func isAllocationMeasured*(): bool =
  ## Decide whether allocation counters are live in this build.
  defined(nimAllocStats)


func allocationsOf*(stats: AllocStats): int =
  ## Read allocation count out of counter difference.
  ##   `AllocStats` exports its fields to nobody and only `-` and default `$`, so count is
  ##   read back from its rendering, `(allocCount: N, deallocCount: M)`; tool side, after
  ##   timing, never on hot path.
  let text = $stats
  let start = text.find("allocCount: ") + "allocCount: ".len
  let stop = text.find(',', start)
  parseInt(text[start ..< stop])



#[ Folding ]#

func fold*(x: float): float {.inline.} =
  ## Fold scalar into sink.
  x

func fold*(x: Antiscalar): float {.inline.} =
  ## Fold antiscalar into sink.
  float(x)

func fold*(m: Multivector): float =
  ## Fold every component into sink.
  for b in Basis: result += m[b]

func fold*[T: object](x: T): float =
  ## Fold every field of typed object into sink, recursively.
  for _, value in x.fieldPairs: result += fold(value)

func hasNan*(x: float): bool {.inline.} =
  ## Decide whether scalar is NaN.
  x.isNaN

func hasNan*(x: Antiscalar): bool {.inline.} =
  ## Decide whether antiscalar is NaN.
  float(x).isNaN

func hasNan*(m: Multivector): bool =
  ## Decide whether any component is NaN.
  for b in Basis:
    if m[b].isNaN: return true

func hasNan*[T: object](x: T): bool =
  ## Decide whether any field of typed object is NaN, recursively.
  for _, value in x.fieldPairs:
    if hasNan(value): return true



#[ Timing ]#

func summarise*(rounds: openArray[int64]; objects: int): tuple[median, minimum: float] =
  ## Read median and minimum nanoseconds per object over rounds.
  var sorted = @rounds
  sorted.sort
  let mid = sorted.len div 2
  let median = if sorted.len mod 2 == 1: float(sorted[mid])
    else: (float(sorted[mid - 1]) + float(sorted[mid])) / 2.0
  (median: median / float(objects), minimum: float(sorted[0]) / float(objects))


template timeRounds(rounds: var array[ROUNDS, int64]; loop: untyped) =
  ## Run loop `ROUNDS` times, recording nanoseconds of each.
  for r in 0 ..< ROUNDS:
    let started = getMonoTime()
    loop
    rounds[r] = (getMonoTime() - started).inNanoseconds


macro emitProbe(index: static int; side: static Side; probe: static Probe): untyped =
  ## Emit timed run of one probe on one side into `FIGURES[side][index]`.
  let expression = if side == Side.Library: probe.spell else: probe.reference
  if expression.len == 0:
    let side_lit = newCall(ident"Side", newLit(ord(side)))
    return quote do:
      FIGURES[`side_lit`][`index`] = Figure(is_measured: false)
  let body = parseExpr(expression)
  let (m, n) = (ident"m", ident"n")  # plain idents, so expression binds them
  let side_lit = newCall(ident"Side", newLit(ord(side)))
  let pool_m = parseExpr(
    if side == Side.Library: libraryPoolName(probe.operands[0], probe.grade)
    else: referencePoolName(probe.operands[0])
  )
  let pool_n = parseExpr(
    if side == Side.Library: libraryPoolName(probe.operands[1], probe.grade)
    else: referencePoolName(probe.operands[1])
  )
  quote do:
    block:
      var results: array[OBJECTS, typeof(block:
        let `m` {.used.} = `pool_m`[0]
        let `n` {.used.} = `pool_n`[0]
        `body`)]
      var rounds: array[ROUNDS, int64]
      let stats_before = getAllocStats()
      timeRounds(rounds):
        for i in 0 ..< OBJECTS:
          let j = (i * 7 + 3) mod OBJECTS
          template `m`(): untyped {.used.} = `pool_m`[i]
          template `n`(): untyped {.used.} = `pool_n`[j]
          results[i] = `body`
      let stats_after = getAllocStats()
      var nan_count = 0
      for i in 0 ..< OBJECTS:
        if hasNan(results[i]): inc nan_count
        else: SINK += fold(results[i])
      let (median, minimum) = summarise(rounds, OBJECTS)
      FIGURES[`side_lit`][`index`] = Figure(
        is_measured: true,
        ns_median: median,
        ns_min: minimum,
        allocations: allocationsOf(stats_after - stats_before),
        nan_share: float(nan_count) / float(OBJECTS),
      )


macro emitProbes(): untyped =
  ## Emit every probe on both sides, in catalogue order.
  result = newStmtList()
  for index in 0 ..< PROBES.len:
    for side in [Side.Library, Side.Reference]:
      result.add newCall(
        bindSym"emitProbe",
        newLit(index),
        newCall(ident"Side", newLit(ord(side))),
        newTree(nnkBracketExpr, ident"PROBES", newLit(index)),
      )


proc runProbes*() =
  ## Time and count every probe on both sides; pools must be filled first.
  ##   First recorded round warms caches; median over rounds discounts it, minimum shows
  ##   warmed cost.
  emitProbes()
