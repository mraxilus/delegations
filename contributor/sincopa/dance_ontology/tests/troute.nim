discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Test laws of finding where reaches cross, and of breaking one under other.
##   Break says which connection is under (rule 14), and it is only
##     reading of picture that says so.  So it has two jobs at once: it
##     must fall where lines cross, and it must leave reach still
##     reaching both its hands.  Reach stopping short of hand reads as
##     unfinished line, never as line passing beneath something.
##   Break can only fall where crossing is found, so finding them all is
##     first of two jobs and has its own suite below.
##   Laws are stated over every place crossing can fall, not over one
##     that happened to be awkward (Article IX.2).

{.experimental: "strictFuncs".}

import std/[math, sequtils, unittest]

import ../src/dance_ontology/draw/geometry
import ../src/dance_ontology/draw/route


const
  STEP = 2.0    ## Spacing of sampled line, close to what reach uses.
  N = 33        ## Points in it, which is `ROUTE_N`.

let
  line = (0 ..< N).mapIt((x: float(it) * STEP, y: 0.0))
    ## Straight sampled line standing in for reach: laws below are about
    ## where gap falls along line, and shape of line does not enter them.
  square = @[(x: 0.0, y: -20.0), (x: 0.0, y: 20.0)]
    ## Reach crossing it square on, so gap it asks for is plain shadow.

proc crossingAt(where: float): seq[Point] =
  ## Get reach crossing line square on, this far along it.
  ##   `proc` rather than `func` only because it reads module's own `square`.
  square.mapIt((x: where, y: it.y))


const
  WAVE_H = 8.0        ## How far waved reach swings either side of `line`.
  SPAN = float(N - 1) * STEP  ## Length `line` runs over.
  ON_ZEROS = 4 * STEP ## Wavelength whose zeros land on sampled points.
    ## Cosine of this wavelength is nought at every second sample, so each
    ##   crossing sits on vertex and is met by both segments sharing it --
    ##   which is duplicate fold exists to drop.
  WAVELENGTHS = [ON_ZEROS, 12.0, 16.0, 24.0]
    ## Wavelengths laws below are stated over: first meets every crossing
    ##   twice, rest meet each once, and spacing runs from under stroke's
    ##   width to well over `BREAK`.

func crossedBy(wavelength: float): seq[Point] =
  ## Get reach waving across `line`, crossing at every zero of its cosine.
  (0 ..< N).mapIt((x: float(it) * STEP,
                   y: WAVE_H * cos(float(it) * STEP * 2 * PI / wavelength)))

func zerosOf(wavelength: float): int =
  ## Count places cosine of this wavelength crosses nought over sampled span.
  ##   Derived from wavelength rather than counted off picture, so law is
  ##     stated against arithmetic and never against what drawing did.
  var at = wavelength / 4
  while at < SPAN:
    inc result
    at += wavelength / 2


suite "reach breaks":

  test "a break never eats either end of a reach":
    for i in 0 ..< N:
      let runs = cutGapsAt(line, crossingAt(float(i) * STEP), @[line[i]])
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
      let
        runs = cutGapsAt(line, crossingAt(float(i) * STEP), @[line[i]])
        gap = gapFor(at, span, hidesAt(line, crossingAt(at), line[i]))
        drawn = runs.mapIt(polylineLen(it)).foldl(a + b, 0.0)
      check runs.len == 2
      # Reach loses exactly its gap, no more and no less.  Bare test that
      # crossing sits in no run passed while gap was cut to whole samples
      # and so took more than it meant to.
      check abs(drawn - (span - (gap.shuts - gap.opens))) < 1e-6

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

  test "a break sits on its crossing, not beside it":
    # Break says this line passes under that one, and it says it where
    # they cross.  Gap pushed off to one side leaves crossing drawn whole
    # and puts hole in line where nothing happens.
    let span = float(N - 1) * STEP
    for i in 0 ..< N:
      let
        at = float(i) * STEP
        gap = gapFor(at, span, hidesAt(line, crossingAt(at), line[i]))
      if gap.shuts <= gap.opens:
        continue
      check abs((gap.opens + gap.shuts) / 2 - at) < 1e-9

  test "an uncrossed reach is drawn whole":
    let runs = cutGapsAt(line, square, @[])
    check runs.len == 1
    check runs[0] == line


suite "crossings found":

  test "crossings close together are still separate crossings":
    # Crossing is where two reaches swap which side of one another they lie,
    # so how many there are is how many times that happens -- and every one
    # of them earns break, whatever its spacing.  Reach held as `ROUTE_N`
    # points doubles back inside handful of them, which puts two crossings
    # within stroke of each other; picture merging them states one
    # over-under where there are two, which is opposite of what rule 14 asks.
    for wavelength in WAVELENGTHS:
      let met = crossingsOf(line, crossedBy(wavelength))
      check met.len == zerosOf(wavelength)  # rule 14

  test "one crossing met twice at one spot is reported once":
    # Vertex of one reach sitting exactly on other is met by both segments
    # that share it, at same point twice.  That, and only that, is duplicate
    # fold exists to drop, so wave sampled on its own zeros must still count
    # its crossings and no more.
    let met = crossingsOf(line, crossedBy(ON_ZEROS))
    check met.len == zerosOf(ON_ZEROS)  # rule 14

  test "crossings come out in order along first reach":
    # Which arm dives is alternated from first crossing to last (rule 27),
    # so order is load-bearing and not incidental.
    for wavelength in WAVELENGTHS:
      let met = crossingsOf(line, crossedBy(wavelength))
      for i in 1 ..< met.len:
        check met[i - 1].x < met[i].x  # rule 27
