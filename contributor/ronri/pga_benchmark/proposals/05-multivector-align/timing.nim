## Time library operations and kinds as caller holding them in `seq` would (`multivector-align`).
##   Evaluation compiles this against changed library at each algebra its claim names; exit code
##     says it ran, and figures it prints are evidence that never gates.
##   Built against pin and against changed library, one program gives each pair proposal reports.
##   Kinds hold 3 to 16 floats, counts that kinds of P02 hold, under natural, 16-byte and 64-byte
##     alignment, so cost of each layout reads beside its padding. They need no library, so
##     both builds print same rows.
##   Kind is summed and negated through operator of its own, returned by value, as library
##     writes its operators. Raw loop over slots of `var seq` parameter stays scalar, since
##     each store may alias `seq` itself, and so it shows no cost of layout.
##   Each timed loop sits in procedure of its own, so compiler estimates it hot, as caller's.
##
##   Cost: `seq` stands for caller's heap storage, since layout of that storage is what is
##     measured; 1024 objects, 41 rounds, median nanoseconds per object.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/[algorithm, monotimes, random, strutils, times]

import pga


const
  OBJECTS = 1024  ## Objects each round walks.
  ROUNDS = 41  ## Rounds timed; median is reported.
  SEED = 0  ## Seed of sample generator, so every run reads same objects.


template timeRounds(label: string; loop: untyped) =
  ## Run loop `ROUNDS` times and print median nanoseconds per object under label.
  var rounds: array[ROUNDS, float]
  for r in 0..<ROUNDS:
    let started = getMonoTime()
    loop
    rounds[r] = float((getMonoTime() - started).inNanoseconds) / float(OBJECTS)
  rounds.sort
  echo label, " ", formatFloat(rounds[ROUNDS div 2], ffDecimal, 3)


template timeLibrary(label: string; body: untyped) =
  ## Time one library operation over `seq` of multivectors, slot i paired with (7i + 3).
  block:
    proc run(pool: seq[Multivector]; results: var seq[Multivector]) {.noinline.} =
      ## Time operation in procedure of its own.
      timeRounds("library " & label):
        for i in 0..<OBJECTS:
          let j = (i * 7 + 3) mod OBJECTS
          template m(): untyped {.used.} = pool[i]  # Read by `body`.
          template n(): untyped {.used.} = pool[j]  # Read by binary `body`.
          results[i] = body
    var
      pool = newSeq[Multivector](OBJECTS)
      results = newSeq[Multivector](OBJECTS)
    for i in 0..<OBJECTS:
      for b in Basis: pool[i][b] = gauss()
    run(pool, results)


template defineKind(name: untyped; count: static int; alignment: static int) =
  ## Define kind of `count` floats at one of three alignments, with sum and negation.
  ##   Operators return by value and loop each slot, as library writes its own.
  when alignment == 8:
    type name = object
      elements: array[count, float]
  elif alignment == 16:
    type name = object
      elements {.align(16).}: array[count, float]
  else:
    type name = object
      elements {.align(64).}: array[count, float]

  func `+`(a, b: name): name =
    ## Add slot by slot.
    for k in 0..<count: result.elements[k] = a.elements[k] + b.elements[k]

  func `-`(a: name): name =
    ## Negate slot by slot.
    for k in 0..<count: result.elements[k] = -a.elements[k]


template timeKind(T: typedesc; label: string) =
  ## Time sum and negation of kind over `seq`, slot i paired with (7i + 3).
  block:
    proc run(pool: seq[T]; results: var seq[T]) {.noinline.} =
      ## Time both operations in procedure of their own.
      timeRounds("kind " & label & " size " & $sizeof(T) & " add"):
        for i in 0..<OBJECTS:
          let j = (i * 7 + 3) mod OBJECTS
          results[i] = pool[i] + pool[j]
      timeRounds("kind " & label & " size " & $sizeof(T) & " negate"):
        for i in 0..<OBJECTS:
          results[i] = -pool[i]
    var
      pool = newSeq[T](OBJECTS)
      results = newSeq[T](OBJECTS)
    for i in 0..<OBJECTS:
      for k in 0..<pool[i].elements.len: pool[i].elements[k] = gauss()
    run(pool, results)


defineKind(Kind3Natural, 3, 8); defineKind(Kind3Line16, 3, 16); defineKind(Kind3Line64, 3, 64)
defineKind(Kind4Natural, 4, 8); defineKind(Kind4Line16, 4, 16); defineKind(Kind4Line64, 4, 64)
defineKind(Kind5Natural, 5, 8); defineKind(Kind5Line16, 5, 16); defineKind(Kind5Line64, 5, 64)
defineKind(Kind6Natural, 6, 8); defineKind(Kind6Line16, 6, 16); defineKind(Kind6Line64, 6, 64)
defineKind(Kind8Natural, 8, 8); defineKind(Kind8Line16, 8, 16); defineKind(Kind8Line64, 8, 64)
defineKind(Kind10Natural, 10, 8); defineKind(Kind10Line16, 10, 16)
defineKind(Kind10Line64, 10, 64)
defineKind(Kind16Natural, 16, 8); defineKind(Kind16Line16, 16, 16)
defineKind(Kind16Line64, 16, 64)


proc main() =
  ## Time library operations at this algebra, then each kind at each alignment.
  randomize(SEED)
  timeLibrary("add", m + n)
  timeLibrary("negate", -m)
  timeLibrary("complement", / m)
  timeLibrary("dual", ★ m)
  timeLibrary("dot", m ∙ n)
  timeLibrary("wedge", m ∧ n)
  timeLibrary("geometric", m ⟑ n)
  timeKind(Kind3Natural, "3 natural"); timeKind(Kind3Line16, "3 align16")
  timeKind(Kind3Line64, "3 align64")
  timeKind(Kind4Natural, "4 natural"); timeKind(Kind4Line16, "4 align16")
  timeKind(Kind4Line64, "4 align64")
  timeKind(Kind5Natural, "5 natural"); timeKind(Kind5Line16, "5 align16")
  timeKind(Kind5Line64, "5 align64")
  timeKind(Kind6Natural, "6 natural"); timeKind(Kind6Line16, "6 align16")
  timeKind(Kind6Line64, "6 align64")
  timeKind(Kind8Natural, "8 natural"); timeKind(Kind8Line16, "8 align16")
  timeKind(Kind8Line64, "8 align64")
  timeKind(Kind10Natural, "10 natural"); timeKind(Kind10Line16, "10 align16")
  timeKind(Kind10Line64, "10 align64")
  timeKind(Kind16Natural, "16 natural"); timeKind(Kind16Line16, "16 align16")
  timeKind(Kind16Line64, "16 align64")


main()
