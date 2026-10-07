## Time library operations as caller holding them in `seq` would (`multivector-align`).
##   Evaluation compiles this against changed library at each algebra its claim names; exit code
##     says it ran, and figures it prints are evidence that never gates.
##   Built against pin and against changed library, one program gives each pair proposal reports.
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


template timeRounds(label: string, loop: untyped) =
  ## Run loop `ROUNDS` times and print median nanoseconds per object under label.
  var rounds: array[ROUNDS, float]
  for r in 0..<ROUNDS:
    let started = getMonoTime()
    loop
    rounds[r] = float((getMonoTime() - started).inNanoseconds) / float(OBJECTS)
  rounds.sort
  echo label, " ", formatFloat(rounds[ROUNDS div 2], ffDecimal, 3)


template timeLibrary(label: string, body: untyped) =
  ## Time one library operation over `seq` of multivectors, slot i paired with (7i + 3).
  block:
    proc run(pool: seq[Multivector], results: var seq[Multivector]) {.noinline.} =
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


proc main() =
  ## Time library operations at this algebra.
  randomize(SEED)
  timeLibrary("add", m + n)
  timeLibrary("negate", -m)
  timeLibrary("complement", /m)
  timeLibrary("dual", ★m)
  timeLibrary("dot", m ∙ n)
  timeLibrary("wedge", m ∧ n)
  timeLibrary("geometric", m ⟑ n)


main()
