discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Test laws of breaking one reach where another crosses over it.
##   Break says which connection is under (rule 14), and it is only
##     reading of picture that says so.  So it has two jobs at once: it
##     must fall where lines cross, and it must leave reach still
##     reaching both its hands.  Reach stopping short of hand reads as
##     unfinished line, never as line passing beneath something.
##   Laws are stated over every place crossing can fall, not over one
##     that happened to be awkward (Article IX.2).

{.experimental: "strictFuncs".}

import std/[sequtils, unittest]

import ../src/dance_ontology/draw/geometry
import ../src/dance_ontology/draw/route


const
  STEP = 2.0    ## Spacing of sampled line, close to what reach uses.
  N = 33        ## Points in it, which is `ROUTE_N`.

let line = (0 ..< N).mapIt((x: float(it) * STEP, y: 0.0))
  ## Straight sampled line standing in for reach: laws below are about
  ## where gap falls along line, and shape of line does not enter them.


suite "reach breaks":

  test "a break never eats either end of a reach":
    for i in 0 ..< N:
      let runs = cutGapsAt(line, @[line[i]])
      check runs.len > 0
      check runs[0][0] == line[0]
      check runs[^1][^1] == line[^1]

  test "a break falls where the lines cross":
    # Crossing nearer than half break to either hand cannot be covered
    # and still leave reach whole; every other one is covered.
    let span = float(N - 1) * STEP
    for i in 0 ..< N:
      let at = float(i) * STEP
      if at < BREAK / 2 or at > span - BREAK / 2:
        continue
      let runs = cutGapsAt(line, @[line[i]])
      check runs.len == 2
      check not runs.anyIt(line[i] in it)

  test "a reach that crosses nothing is not broken":
    # Break says this line passes under that one.  Where there is no
    # crossing there is nothing to pass under, so break there states
    # something no picture means.
    let beside = line.mapIt((x: it.x, y: 20.0))
    check cutGap(line, beside) == @[line]

  test "a reach that is crossed is broken where it is crossed":
    let across = @[(x: 30.0, y: -20.0), (x: 30.0, y: 20.0)]
    let runs = cutGap(line, across)
    check runs.len == 2
    check runs[0][0] == line[0]
    check runs[^1][^1] == line[^1]

  test "no gap is wider than the piece of reach beside it":
    # Piece shorter than gap next to it reads as debris left behind by
    # break rather than as line carrying on past one.  Crossing near hand
    # is where that bites: gap of full width there leaves nub.
    let span = float(N - 1) * STEP
    for i in 0 ..< N:
      let
        gap = gapFor(float(i) * STEP, span)
        width = gap.shuts - gap.opens
      check gap.opens >= width
      check span - gap.shuts >= width

  test "an uncrossed reach is drawn whole":
    let runs = cutGapsAt(line, @[])
    check runs.len == 1
    check runs[0] == line
