discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Hold axle drawing to its own claims.
##
## Axle has no page yet -- app's Dance view is graph-first and
## rotation exploration lives in design workbench -- so these laws are
## what keeps it from rotting while it waits: drawing still says what
## its header says it says.

{.experimental: "strictFuncs".}

import std/[options, strutils, unittest]

import ../src/dance_ontology

suite "the axle":
  test "the axle is one line: a twist's place is affine in the twist":
    # Placed by twist itself rather than by index, so distance
    # between two postures on drawing is size of turn between
    # them, wherever it is taken.
    let stood = FRAMES[1].rest
    let places = standing(stood)
    check places.len > 1
    var gap = 0
    for i in 1 ..< places.len:
      let
        (ax, ay) = centreOf(stood, places[i - 1])
        (bx, by) = centreOf(stood, places[i])
      check bx > ax  # laid out in order they are turned into
      check ay == by  # one line, one row
      let step = (bx - ax) div (places[i] - places[i - 1])
      if gap == 0: gap = step
      check step == gap

  test "the couple stand on one posture, and a refusal is drawn refused":
    # Header's claim: drawing can show turn and refuse it in
    # same breath, so refused arcs are present and marked.
    let drawn = renderAxle(FRAMES[1].rest)
    check drawn.count("class=\"node here\"") == 1
    check "class=\"turn refused\"" in drawn
    check "class=\"node reachable\"" in drawn

  test "the axle is as wide as it says it is":
    check ("viewBox=\"0 0 " & $axleWidth() & " ") in renderAxle(FRAMES[1].rest)
