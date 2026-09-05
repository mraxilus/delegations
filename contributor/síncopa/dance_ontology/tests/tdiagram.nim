discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Test that picture of frame says what frame is, at any size.
##
## Every view is built on this drawing, and most of them draw it small: as
## node on map, as header on matrix, as card in atlas.  What
## picture says has to survive being shrunk, because reader who cannot read it
## cannot read anything else on page.

{.experimental: "strictFuncs".}

import std/[options, sequtils, strutils, unittest]

import ../src/dance_ontology


suite "the picture":
  test "the lead's hands are squares and the follow's are circles":
    # Which hand is whose was said only by captions over and under
    # picture, and those are first thing to go when it is drawn small --
    # they are gone from this drawing entirely.  Shape survives any size, so
    # picture says whose hand it is as vocabulary does: by
    # mark itself, not by word beside it.  Nothing else in drawing may
    # be rect or circle, which is why count is exact -- bodies are
    # arcs and chevrons are polylines.
    for target in FRAMES:
      let picture = renderFrame(target)
      check picture.count("<rect") == 2
      check picture.count("<circle") == 2

  test "a free hand fades and a held one does not":
    # Fill cannot say this any more, and should not: fill says *level*
    # hand is held at -- solid low, dotted high, hatched above -- and frame
    # knows no level, so every hand here is hollow outline that means none
    # was said.  Claiming level to mean "held" would be drawing something
    # model does not know.  Half strength says it instead, and connection
    # running out of hand says it again.
    for target in FRAMES:
      # Two hands to connection, one of lead's and one of follow's.
      check renderFrame(target).count("opacity=\"0.5\"") ==
        4 - 2 * target.countHolds

  test "every frame is drawn in the one space, whatever it holds":
    # Coordinate has to mean same place in every frame, because views
    # put frames side by side and read one against another.
    var boxes: seq[string] = @[]
    for target in FRAMES:
      let picture = renderFrame(target)
      let start = picture.find("viewBox=\"")
      check start >= 0
      let box = picture[start .. picture.find('"', start + 9)]
      if box notin boxes:
        boxes.add box
    check boxes.len == 1

  test "a picture names the frame it draws, for a reader who cannot see it":
    for target in FRAMES:
      check renderFrame(target).contains("<title>" & target.describe & "</title>")

  test "turned back to front, the follow's hands change sides":
    # Picture's half of `crossedSite`.  At half turn hand that was
    # across couple's midline is near one, and drawing that left
    # follow's hands where they were would contradict one place
    # hand-to-hand model reads rotation.  Follow's whole body turns now,
    # and their hands ride round on it.
    for target in FRAMES:
      if target.countHolds == 0:
        continue
      let facing = renderFrame(target, 0)
      check renderFrame(target, 2) == facing
      check renderFrame(target, -2) == facing
      check renderFrame(target, 1) != facing
      check renderFrame(target, 1) == renderFrame(target, -1)

  test "a connection is drawn in its two hands' own colours":
    # So line itself says which named hands are joined -- `Left to right`
    # runs blue into orange along its whole length -- instead of leaving it to
    # two marks that vanish at node size.  Deep half is lead's, which
    # is what still says whose end is whose when both hands share hue, as
    # they do in `Left to left`.
    for target in FRAMES:
      var inks: seq[string] = @[]
      for piece in renderFrame(target).split("<path "):
        # Connection is one thing drawn at connection's own width;
        # rims that make up body are thinner.
        if not piece.contains("stroke-width=\"3.4\""):
          continue
        let at = piece.find("stroke=\"") + 8
        inks.add piece[at ..< piece.find('"', at)]
      # Two halves to every connection, and no half of any other colour.
      check inks.len == 2 * target.countHolds
      check inks.countIt(it.contains("-deep")) == target.countHolds
      for side in Side:
        if target.hold[side].isNone:
          continue
        let
          near = if side == Side.Left: "--left-deep" else: "--right-deep"
          far = if target.hold[side].get == Site.LeftHand: "--left,"
                else: "--right,"
        check inks.anyIt(it.contains(near))
        check inks.anyIt(it.contains(far))

  test "both dancers say which way they face, in every picture":
    # This used to be mark that appeared only when follow had turned, on
    # reasoning that mark on every picture is furniture.  There are
    # bodies in picture now, and body always faces somewhere -- so
    # chevron is not furniture, it is one part of dancer that carries
    # their orientation, and what varies is where it points rather than
    # whether it is there.  Both dancers get one, always.
    for target in FRAMES:
      for twist in [-3, -2, -1, 0, 1, 2, 3]:
        check renderFrame(target, twist).count("<polyline") == 2
      # And turning shows, in every frame -- including `free`, which
      # old drawing could not tell apart from itself turned.
      check renderFrame(target, 1) != renderFrame(target, 0)
