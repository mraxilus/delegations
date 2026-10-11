## Time and count every catalogued measurand in every implementation, from one entry.
##   Each measurand becomes one timed loop over its pool, `ROUNDS` times, median and minimum
##   nanoseconds per object reported. Around every timed run, allocation counters are read
##   so any heap use shows as count, and every result is folded into one sink after timing
##   so nothing is optimised away; share of results carrying NaN is counted alongside, since
##   library's radius norm returns NaN where 𝐦 ∘ 𝐦 is negative and that is measured, not stated.
##   Operands are aliases into pools (template, never `let`), so loop reads pool slot and
##   writes result slot: what moves is operation's own traffic.
##   Result slots start uninitialised (`noinit`): array filled with zeros would let C compiler
##     drop each zero store that inlined operation repeats, and so time fewer stores than any
##     caller pays.
##   Result of three floats or fewer returns by value, so loop binds it before storing it.
##     Assigned straight into slot, it passes through temporary that call site zero-fills, and
##     in large function compiler keeps that fill as out-of-line `rep stos`, about 11 ns per
##     object that no caller of normal size pays. Suite `Internal: Inspector` holds it.
##   Each measurand times in procedure of its own per implementation, as caller's function
##     would call it. In one function holding every loop, error check after each call drains
##     compiler's estimate of reaching code below it to zero from second measurand on; code
##     estimated cold is optimised for size, so library's loops stay scalar while straight-line
##     forms still vectorise. Suite `Internal: Inspector` holds it.
##   Result slots align to cache line, so every implementation writes same layout; alignment
##     alone moves time of identical code by up to one fifth.
##
##   Instrument gates: allocation counts are live only under `-d:nimAllocStats`, and
##     `isAllocationMeasured` says so, since counter reading zero means nothing otherwise
##     (Article VII.4); driver runs plain build for timings and instrumented one for counts.
##   Dense form runs beside library on general measurand, from same pools, and never on typed
##     one; reference runs on typed measurand alone. Build under
##     `-d:pga_benchmark.has_forms_dense=false` neither imports nor times dense forms, since they
##     read tables by name at pin and change may rename them; evaluation builds so.
##
##   Cost: measurements arrays hold one entry per measurand per implementation; sink is float.
##   Cost: pairing slot i with slot (7i + 3) mod OBJECTS costs integer ops in both.

{.experimental: "strictFuncs".}

import std/[algorithm, macros, math, monotimes, strutils, times]

import pga

import ./[catalogue, kinds, pools, widening]


const HAS_FORMS_DENSE* {.booldefine: "pga_benchmark.has_forms_dense".} = true
  ## Whether build emits and times dense forms; evaluation compares library with pin alone.

when HAS_FORMS_DENSE: import ./dense


type
  Implementation* {.pure.} = enum  ## Define which implementation measurement belongs to.
    Library, Reference, Dense
  Measurement* = object  ## Define measurements of one measurand in one implementation.
    is_measured*: bool
      ## False where implementation has no expression.
      ##   Reference has none on general measurand, and dense form has none on typed one.
    ns_median*, ns_min*: float  ## Nanoseconds per object, median and minimum over rounds.
    allocations*: int
      ## Heap allocations counted over every round; meaningful only when instrument is live.
    share_nan*: float  ## Share of results carrying NaN in any component.


var
  MEASUREMENTS*: array[Implementation, array[CATALOGUE.len, Measurement]]
    ## Measurements of every measurand, filled by `measureCatalogue`.
  SINK*: float  ## Fold of every result, printed so no result is dead.


func isAllocationMeasured*(): bool =
  ## Decide whether allocation counters are live in this build.
  defined(nimAllocStats)


func allocationsOf*(stats: AllocStats): int =
  ## Read allocation count out of counter difference.
  ##   `AllocStats` exports its fields to nobody and only `-` and default `$`, so count is
  ##   read back from its rendering, `(allocCount: N, deallocCount: M)`; tool it, after
  ##   timing, never on hot path.
  let
    text = $stats
    start = text.find("allocCount: ") + "allocCount: ".len
    stop = text.find(',', start)
  parseInt(text[start..<stop])



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

func isAnyNan*(x: float): bool {.inline.} =
  ## Decide whether scalar is NaN.
  x.isNaN

func isAnyNan*(x: Antiscalar): bool {.inline.} =
  ## Decide whether antiscalar is NaN.
  float(x).isNaN

func isAnyNan*(m: Multivector): bool =
  ## Decide whether any component is NaN.
  for b in Basis:
    if m[b].isNaN: return true

func isAnyNan*[T: object](x: T): bool =
  ## Decide whether any field of typed object is NaN, recursively.
  for _, value in x.fieldPairs:
    if isAnyNan(value): return true



#[ Timing ]#

func summarise*(rounds: openArray[int64], objects: int): tuple[median, minimum: float] =
  ## Read median and minimum nanoseconds per object over rounds.
  var sorted = @rounds
  sorted.sort
  let
    middle = sorted.len div 2
    median = if sorted.len mod 2 == 1: float(sorted[middle])
      else: (float(sorted[middle-1]) + float(sorted[middle])) / 2.0
  (median: median / float(objects), minimum: float(sorted[0]) / float(objects))


template timeRounds(rounds: var array[ROUNDS, int64], loop: untyped) =
  ## Run loop `ROUNDS` times, recording nanoseconds of each.
  for r in 0..<ROUNDS:
    let started = getMonoTime()
    loop
    rounds[r] = (getMonoTime() - started).inNanoseconds


macro emitMeasurand(
  index: static int, implementation: static Implementation, measurand: static Measurand
): untyped =
  ## Emit timed run of one measurand in one implementation.
  ##   Result lands in `MEASUREMENTS[implementation][index]`.
  let expression =
    case implementation
    of Implementation.Library: measurand.expression
    of Implementation.Reference: measurand.reference
    of Implementation.Dense:
      if not HAS_FORMS_DENSE or measurand.reference.len > 0: ""
      elif measurand.arity == 2: measurand.nameDenseOf & "(m, n)"
      else: measurand.nameDenseOf & "(m)"
  if expression.len == 0:
    let implementation_literal = newCall(ident"Implementation", newLit(ord(implementation)))
    return quote do:
      MEASUREMENTS[`implementation_literal`][`index`] = Measurement(is_measured: false)
  let
    body = parseExpr(expression)
    (m, n) = (ident"m", ident"n")  # plain idents, so expression binds them
    implementation_literal = newCall(ident"Implementation", newLit(ord(implementation)))
    pool_m = parseExpr(
      if implementation == Implementation.Reference: namePoolReference(measurand.operands[0])
      else: namePoolLibrary(measurand.operands[0], measurand.grade),
    )
    pool_n = parseExpr(
      if implementation == Implementation.Reference: namePoolReference(measurand.operands[1])
      else: namePoolLibrary(measurand.operands[1], measurand.grade),
    )
  quote do:
    block:
      var
        results {.noinit, align(64).}: array[OBJECTS, typeof(block:
          let
            `m` {.used.} = `pool_m`[0]  # Read by `body`.
            `n` {.used.} = `pool_n`[0]  # Read by `body` of binary measurand; unary leaves it.
          `body`)]
        rounds: array[ROUNDS, int64]
      let statistics_before = getAllocStats()
      # Hot path, per pool slot: index and pool reads constant; work linear in `OBJECTS` times
      #   `ROUNDS`; nothing allocates but `body`, and `allocations` counts what it does.
      timeRounds(rounds):
        for i in 0..<OBJECTS:
          let j = (i * 7 + 3) mod OBJECTS
          template `m`(): untyped {.used.} = `pool_m`[i]  # Read by `body`.
          template `n`(): untyped {.used.} = `pool_n`[j]  # Read by binary `body`; unary leaves it.
          when typeof(results[0]) is object and sizeof(results[0]) <= 3 * sizeof(float):
            # Result returned by value: bind first, so call site fills no temporary.
            let value = `body`
            results[i] = value
          else:
            results[i] = `body`
      let statistics_after = getAllocStats()
      var count_nan = 0
      for i in 0..<OBJECTS:
        if isAnyNan(results[i]): inc count_nan
        else: SINK += fold(results[i])
      let (median, minimum) = summarise(rounds, OBJECTS)
      MEASUREMENTS[`implementation_literal`][`index`] = Measurement(
        is_measured: true,
        ns_median: median,
        ns_min: minimum,
        allocations: allocationsOf(statistics_after - statistics_before),
        share_nan: float(count_nan) / float(OBJECTS),
      )


macro emitCatalogue(): untyped =
  ## Emit one procedure per measurand per implementation, then `measureCatalogue` calling each.
  ##   Calls follow catalogue order, and implementations of one measurand run back to back, so
  ##   machine drift lands on each alike.
  result = newStmtList()
  let calls = newStmtList()
  for index in 0..<CATALOGUE.len:
    for implementation in Implementation:
      let
        name = ident("measure" & $index & $implementation)
        timed = newCall(
          bindSym"emitMeasurand",
          newLit(index),
          newCall(ident"Implementation", newLit(ord(implementation))),
          newTree(nnkBracketExpr, ident"CATALOGUE", newLit(index)),
        )
      result.add quote do:
        proc `name`() {.noinline.} =
          `timed`
      calls.add newCall(name)
  result.add quote do:
    proc measureCatalogue*() =
      ## Time and count every measurand in every implementation; pools must be filled first.
      ##   First recorded round warms caches; median over rounds discounts it, minimum shows
      ##   warmed cost.
      `calls`


emitCatalogue()
