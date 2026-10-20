## Time stand-ins of basis-set types as caller holding them in `seq` would (`exact-kinds`).
##   Evaluation compiles this against library at pin, at each algebra its claim names; exit code
##     says it ran, and figures it prints are evidence that never gates.
##   Stand-ins hold 3 to 16 floats, counts that basis-set types reach from rga3d to cga5d, under
##     natural, 16-byte and 64-byte alignment, so cost of each layout reads beside its padding.
##     Stand-in of 4 floats also takes 32 bytes, which `alignment` gives that count. Stand-ins
##     need no library.
##   Stand-in is summed and negated through operator of its own, returned by value. Raw loop
##     over elements of `var seq` parameter stays scalar, since each store may alias `seq` itself,
##     and so it shows no cost of layout.
##   `timeRounds` mirrors that of `timing.nim` in P05, P06 and P07; fix to one reaches each.
##   Each timed loop sits in procedure of its own, so compiler estimates it hot, as caller's.
##
##   Cost: `seq` stands for caller's heap storage, since layout of that storage is what is
##     measured; 1024 objects, 41 rounds, median nanoseconds per object.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[algorithm, monotimes, random, strutils, times]


const
  OBJECTS = 1024  ## Objects each round walks.
  ROUNDS = 41  ## Rounds timed; median is reported.
  SEED = 0  ## Seed of sample generator, so every run reads same objects.


template timeRounds(label: string, loop: untyped) =
  ## Run loop `ROUNDS` times and print median nanoseconds per object under label.
  var rounds: array[ROUNDS, float]
  for r in 0..<ROUNDS:
    let started = getMonoTime()
    loop
    rounds[r] = float((getMonoTime() - started).inNanoseconds) / float(OBJECTS)
  rounds.sort
  echo label, " ", formatFloat(rounds[ROUNDS div 2], ffDecimal, 3)


template declareStandIn(name: untyped; count, alignment: static int) =
  ## Declare stand-in of `count` floats at one of four alignments, with sum and negation.
  ##   Operators return by value and loop each coefficient.
  when alignment == 8:
    type name = object
      elements: array[count, float]
  elif alignment == 16:
    type name = object
      elements {.align(16).}: array[count, float]
  elif alignment == 32:
    type name = object
      elements {.align(32).}: array[count, float]
  else:
    type name = object
      elements {.align(64).}: array[count, float]

  func `+`(a, b: name): name =
    ## Add coefficient by coefficient.
    for k in 0..<count: result.elements[k] = a.elements[k] + b.elements[k]

  func `-`(a: name): name =
    ## Negate coefficient by coefficient.
    for k in 0..<count: result.elements[k] = -a.elements[k]


template timeStandIn(T: typedesc, label: string) =
  ## Time sum and negation of stand-in `T` over `seq`, element i paired with (7i + 3).
  block:
    proc run(pool: seq[T], results: var seq[T]) {.noinline.} =
      ## Time both operations in procedure of their own.
      timeRounds("stand-in " & label & " size " & $sizeof(T) & " add"):
        for i in 0..<OBJECTS:
          let j = (i * 7 + 3) mod OBJECTS
          results[i] = pool[i] + pool[j]
      timeRounds("stand-in " & label & " size " & $sizeof(T) & " negate"):
        for i in 0..<OBJECTS:
          results[i] = -pool[i]

    # Fill pool with seeded floats, then time.
    var
      pool = newSeq[T](OBJECTS)
      results = newSeq[T](OBJECTS)
    for i in 0..<OBJECTS:
      for k in 0..<pool[i].elements.len: pool[i].elements[k] = gauss()
    run(pool, results)


declareStandIn(StandIn3Natural, 3, 8)
declareStandIn(StandIn3Aligned16, 3, 16)
declareStandIn(StandIn3Aligned64, 3, 64)
declareStandIn(StandIn4Natural, 4, 8)
declareStandIn(StandIn4Aligned16, 4, 16)
declareStandIn(StandIn4Aligned64, 4, 64)
declareStandIn(StandIn4Aligned32, 4, 32)
declareStandIn(StandIn5Natural, 5, 8)
declareStandIn(StandIn5Aligned16, 5, 16)
declareStandIn(StandIn5Aligned64, 5, 64)
declareStandIn(StandIn6Natural, 6, 8)
declareStandIn(StandIn6Aligned16, 6, 16)
declareStandIn(StandIn6Aligned64, 6, 64)
declareStandIn(StandIn8Natural, 8, 8)
declareStandIn(StandIn8Aligned16, 8, 16)
declareStandIn(StandIn8Aligned64, 8, 64)
declareStandIn(StandIn10Natural, 10, 8)
declareStandIn(StandIn10Aligned16, 10, 16)
declareStandIn(StandIn10Aligned64, 10, 64)
declareStandIn(StandIn16Natural, 16, 8)
declareStandIn(StandIn16Aligned16, 16, 16)
declareStandIn(StandIn16Aligned64, 16, 64)


proc main() =
  ## Time each stand-in at each alignment.
  randomize(SEED)
  timeStandIn(StandIn3Natural, "3 natural")
  timeStandIn(StandIn3Aligned16, "3 align16")
  timeStandIn(StandIn3Aligned64, "3 align64")
  timeStandIn(StandIn4Natural, "4 natural")
  timeStandIn(StandIn4Aligned16, "4 align16")
  timeStandIn(StandIn4Aligned64, "4 align64")
  timeStandIn(StandIn4Aligned32, "4 align32")
  timeStandIn(StandIn5Natural, "5 natural")
  timeStandIn(StandIn5Aligned16, "5 align16")
  timeStandIn(StandIn5Aligned64, "5 align64")
  timeStandIn(StandIn6Natural, "6 natural")
  timeStandIn(StandIn6Aligned16, "6 align16")
  timeStandIn(StandIn6Aligned64, "6 align64")
  timeStandIn(StandIn8Natural, "8 natural")
  timeStandIn(StandIn8Aligned16, "8 align16")
  timeStandIn(StandIn8Aligned64, "8 align64")
  timeStandIn(StandIn10Natural, "10 natural")
  timeStandIn(StandIn10Aligned16, "10 align16")
  timeStandIn(StandIn10Aligned64, "10 align64")
  timeStandIn(StandIn16Natural, "16 natural")
  timeStandIn(StandIn16Aligned16, "16 align16")
  timeStandIn(StandIn16Aligned64, "16 align64")


when isMainModule:
  main()
