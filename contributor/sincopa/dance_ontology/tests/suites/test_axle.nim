## Hold axle drawing to its own claims.
##
## Axle has no page yet -- Explorer's Dance view is graph-first and
## rotation exploration lives in design workbench -- so these laws are
## what keeps it from rotting while it waits: drawing still says what
## its header says it says.

{.experimental: "strictFuncs".}

import std/[options, strutils, unittest]

import ../../src/dance_ontology



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
    var told: seq[string] = @[]
    for stood in frameStates():
      for chunk in renderAxle(stood).split("class=\"turn-name\"")[1 .. ^1]:
        let
          said = chunk[0..<chunk.find("</text>")]
          name = said[said.find('>') + 1 .. ^1]
        if name notin told:
          told.add name
    check told.len == 2 * MOST_TURN  # Every size of turn, either way.
    for name in told:
      let words = name.split(' ')
      check words[^1] in ["clockwise", "anticlockwise"]
      check "right" notin words
      check "left" notin words
