## Time comparison and grade under rule of changed library against rule of pin, at width of
##   this build (`part-scale`).
##   Evaluation compiles this against changed library at rga4d, at default width and at 32
##     bits; exit code says it ran, and figures it prints are evidence that never gates.
##   Rule of pin is copied here, since claim builds against changed library alone.
##   Equal pairs read every coefficient under both rules. Unequal pairs differ in scalar, so
##     both rules stop at first coefficient, where rule of change reads its part for scale.
##   Stray pairs are points about 1000 units out, one holding stray of 50 tolerances in its
##     plane slot: rule of change calls them equal, and rule of pin stops there and does not.
##   Each timed loop sits in procedure of its own, so compiler estimates it hot, as caller's.
##
##   Cost: `seq` stands for caller's heap storage; 1024 pairs, 41 rounds, median nanoseconds
##     per pair.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/[algorithm, monotimes, options, random, strutils, times]

import pga


const
  OBJECTS = 1024  ## Pairs each round walks.
  ROUNDS = 41  ## Rounds timed; median is reported.
  SEED = 0  ## Seed of sample generator, so every run reads same objects.


func isEqualNow(m, n: Multivector): bool =
  ## Compare as pin does: each coefficient against max(1, |x|, |y|) of its own.
  for basis in Basis:
    let bound = TOLERANCE_ABS * max(Coefficient(1), max(abs(m[basis]), abs(n[basis])))
    if abs(m[basis] - n[basis]) > bound: return false
  true


func gradeNow(m: Multivector): Option[Grade] =
  ## Get grade as pin does: each coefficient at most tolerance counts as zero.
  var is_found = false
  for basis in Basis:
    if abs(m[basis]) <= TOLERANCE_ABS: continue
    if not is_found:
      is_found = true
      result = some(basis.grade)
    elif int(result.get) != int(basis.grade):
      return none(Grade)
  if not is_found: result = some(Grade(0))


template timeRounds(label: string, loop: untyped) =
  ## Run loop `ROUNDS` times and print median nanoseconds per pair under label.
  var rounds: array[ROUNDS, float]
  for r in 0..<ROUNDS:
    let started = getMonoTime()
    loop
    rounds[r] = float((getMonoTime() - started).inNanoseconds) / float(OBJECTS)
  rounds.sort
  echo label, " ", formatFloat(rounds[ROUNDS div 2], ffDecimal, 2)


proc timeEqual(label: string; left, right: seq[Multivector]) {.noinline.} =
  ## Time both comparisons over pairs, counting equal ones so no loop folds away.
  var count = 0
  timeRounds(label & " now"):
    for i in 0..<OBJECTS:
      if isEqualNow(left[i], right[i]): inc count
  timeRounds(label & " part"):
    for i in 0..<OBJECTS:
      if left[i] =~ right[i]: inc count
  echo label, " equal ", count div (2 * ROUNDS), " of ", OBJECTS


proc timeGrade(label: string, objects: seq[Multivector]) {.noinline.} =
  ## Time both grades over objects, counting grades found so no loop folds away.
  var count = 0
  timeRounds(label & " now"):
    for i in 0..<OBJECTS:
      if gradeNow(objects[i]).isSome: inc count
  timeRounds(label & " part"):
    for i in 0..<OBJECTS:
      if objects[i].grade.isSome: inc count
  echo label, " graded ", count div (2 * ROUNDS), " of ", OBJECTS


proc main() =
  ## Print width of this build, then time each comparison and grade under both rules.
  randomize(SEED)
  echo "width ", FLOAT_WIDTH, " tolerance ", FLOAT_TOLERANCE
  var left, right, unequal = newSeq[Multivector](OBJECTS)
  for i in 0..<OBJECTS:
    for basis in Basis:
      left[i][basis] = Coefficient(gauss())
    right[i] = left[i]
    unequal[i] = left[i]
    unequal[i][Basis.scalar] = left[i][Basis.scalar] + 1
  timeEqual("equal", left, right)
  timeEqual("unequal", left, unequal)
  timeGrade("grade_mixed", left)
  var points, strays = newSeq[Multivector](OBJECTS)
  for i in 0..<OBJECTS:
    points[i][Basis.E1] = Coefficient(gauss(0.0, 1000.0))
    points[i][Basis.E2] = Coefficient(gauss(0.0, 1000.0))
    points[i][Basis.E3] = Coefficient(gauss(0.0, 1000.0))
    points[i][Basis.E4] = 1
    strays[i] = points[i]
    strays[i][Basis.E321] = TOLERANCE_ABS * 50
  timeEqual("stray", points, strays)
  timeGrade("grade_point", points)
  timeGrade("grade_stray", strays)


main()
