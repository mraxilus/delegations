## Hold axle drawing to its own claims.
##
## Axle has no page yet -- Explorer's Dance view is graph-first and
## rotation exploration lives in design workbench -- so these laws are
## what keeps it from rotting while it waits: drawing still says what
## its header says it says.

{.experimental: "strictFuncs".}

import std/[options, sequtils, strutils, unittest]

import ../../src/dance_ontology



func heldAbove(target: Frame): FrameState =
  ## Get frame at rest, each arm that holds carried above.
  result = target.rest
  for side in Side:
    if target.hold[side].isSome:
      result.level[side] = Level.Above



suite "Internal: The axle":
  test "the axle is one line: a twist's place is affine in the twist":
    # Placed by twist itself rather than by index, so distance
    # between two frame states on drawing is size of turn between
    # them, wherever it is taken.
    let
      stood = FRAMES[1].rest
      places = standing(stood)
    check places.len > 1
    var gap = 0
    for i in 1..<places.len:
      let
        (prev_x, prev_y) = centre(stood, places[i-1])
        (curr_x, curr_y) = centre(stood, places[i])
      check curr_x > prev_x  # laid out in order they are turned into
      check prev_y == curr_y  # one line, one row
      let step = (curr_x - prev_x) div (places[i] - places[i-1])
      if gap == 0: gap = step
      check step == gap


  test "the couple stand on one frame state, and a refusal is drawn refused":
    # Header's claim: drawing can show turn and refuse it in
    # same breath, so refused arcs are present and marked.
    let drawn = renderAxle(FRAMES[1].rest)
    check drawn.count("class=\"node here\"") == 1
    check "class=\"turn refused\"" in drawn
    check "class=\"node reachable\"" in drawn


  test "the axle is as wide as it says it is":
    check ("viewBox=\"0 0 " & $axleWidth() & " ") in renderAxle(FRAMES[1].rest)


  test "an arc names its turn clockwise or anticlockwise, and never right or left":
    # One arc stands for two landings, follow's turn one way and lead's turn other, so right
    # or left is wrong for half of what it names.  Frame states on axle are named from above
    # too (`turnName`).  Red with arcs named right and left, measured 2026-10-22
    # (issue #698): `Right to left` at rest drew `half a turn right`.
    #   Single hand above keeps orientation alone (rule 16): its one arc stands for half turn
    #     and turn and half, either way, so it names size alone.
    var told: seq[string] = @[]
    for stood in frameStates():
      for chunk in renderAxle(stood).split("class=\"turn-name\"")[1 .. ^1]:
        let
          said = chunk[0..<chunk.find("</text>")]
          name = said[said.find('>') + 1 .. ^1]
        if name notin told:
          told.add name
    let ways = told.filterIt(it.split(' ')[^1] in ["clockwise", "anticlockwise"])
    check ways.len == 2 * MOST_TURN  # Every size of turn, either way.
    check told.filterIt(it notin ways) == @["half a turn"]
    for name in told:
      let words = name.split(' ')
      check "right" notin words
      check "left" notin words


  test "held above, a single hand stands two frame states and a pair its chain":
    # Single hand keeps orientation alone, so its axle holds rest and half turn from it.
    #   Hand to hand stands all seven of its chain.  Same-name pair stands six: its far swan
    #   is two turns from its cross, past every turn workbook offers.  Red with one full turn
    #   on one connection and half turn on two, measured 2026-11-03 (issue #698, D-5).
    for target in FRAMES:
      let stood = target.heldAbove
      checkpoint stood.key
      case target.countHolds
      of 1: check standing(stood) == @[0, 1]
      of 2: check standing(stood).len == (if target.isOverlapping: 6 else: 7)
      else: discard
