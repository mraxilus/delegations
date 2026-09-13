## Time and count every catalogued measurand in both implementations, from one entry.
##   Each measurand becomes one timed loop over its pool, `ROUNDS` times, median and minimum
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
##   Cost: measurements arrays hold one entry per measurand per implementation; sink is float.
##   Cost: pairing slot i with slot (7i + 3) mod OBJECTS costs integer ops in both.

{.experimental: "strictFuncs".}

import std/[algorithm, macros, math, monotimes, strutils, times]

import pga

import ./[catalogue, kinds, pools, widening]


type
  Implementation* {.pure.} = enum
    ## Define which implementation measurement belongs to.
    Library, Reference
  Measurement* = object
    ## Define measurements of one measurand in one implementation.
    is_measured*: bool
      ## False where implementation has no expression, i.e. reference absent.
    ns_median*, ns_min*: float
      ## Nanoseconds per object, median and minimum over rounds.
    allocations*: int
      ## Heap allocations counted over every round; meaningful only when instrument is live.
    nan_share*: float
      ## Share of results carrying NaN in any component.


var
  MEASUREMENTS*: array[Implementation, array[CATALOGUE.len, Measurement]]
    ## Measurements of every measurand, filled by `measureCatalogue`.
  SINK*: float
    ## Fold of every result, printed so no result is dead.


func isAllocationMeasured*(): bool =
  ## Decide whether allocation counters are live in this build.
  defined(nimAllocStats)


func allocationsOf*(stats: AllocStats): int =
  ## Read allocation count out of counter difference.
  ##   `AllocStats` exports its fields to nobody and only `-` and default `$`, so count is
  ##   read back from its rendering, `(allocCount: N, deallocCount: M)`; tool it, after
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


macro emitMeasurand(
  index: static int; it: static Implementation; measurand: static Measurand
): untyped =
  ## Emit timed run of one measurand in one implementation into `MEASUREMENTS[it][index]`.
  let expression = if it == Implementation.Library: measurand.expression else: measurand.reference
  if expression.len == 0:
    let it_lit = newCall(ident"Implementation", newLit(ord(it)))
    return quote do:
      MEASUREMENTS[`it_lit`][`index`] = Measurement(is_measured: false)
  let body = parseExpr(expression)
  let (m, n) = (ident"m", ident"n")  # plain idents, so expression binds them
  let it_lit = newCall(ident"Implementation", newLit(ord(it)))
  let pool_m = parseExpr(
    if it == Implementation.Library: libraryPoolName(measurand.operands[0], measurand.grade)
    else: referencePoolName(measurand.operands[0])
  )
  let pool_n = parseExpr(
    if it == Implementation.Library: libraryPoolName(measurand.operands[1], measurand.grade)
    else: referencePoolName(measurand.operands[1])
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
      MEASUREMENTS[`it_lit`][`index`] = Measurement(
        is_measured: true,
        ns_median: median,
        ns_min: minimum,
        allocations: allocationsOf(stats_after - stats_before),
        nan_share: float(nan_count) / float(OBJECTS),
      )


macro emitCatalogue(): untyped =
  ## Emit every measurand in both implementations, in catalogue order.
  result = newStmtList()
  for index in 0 ..< CATALOGUE.len:
    for it in [Implementation.Library, Implementation.Reference]:
      result.add newCall(
        bindSym"emitMeasurand",
        newLit(index),
        newCall(ident"Implementation", newLit(ord(it))),
        newTree(nnkBracketExpr, ident"CATALOGUE", newLit(index)),
      )


proc measureCatalogue*() =
  ## Time and count every measurand in both implementations; pools must be filled first.
  ##   First recorded round warms caches; median over rounds discounts it, minimum shows
  ##   warmed cost.
  emitCatalogue()
