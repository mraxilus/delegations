## Ask body sim about every card reference draws, and write down which it agrees with.
##
##   Reference page carries two tags on each cell.  `kept` is Architect's, given by eye
##     on floor.  `modelled` is this one: whether sim reaches what card draws.  Goal is
##     both at hundred per cent, and gap between them is work left.
##   Written here rather than on page because asking sim costs minutes and page is
##     markup.  Same arrangement `design/turns` uses, and same reason.
##   Tag must not touch pins.  `review_page.drawingOf` cuts cards back out of built page
##     by collecting their `svg` elements alone, so badge outside drawing changes no pin
##     and no kept card is re-drawn by adding this.
##   Answers are keyed by question, never by card's own name: page already folds
##     duplicate pictures together and hands out identifiers, and second place doing
##     that would be second place to get it wrong.
##   Four manners are two motions.  Orbit about couple's centre is change of world
##     frame and moves neither dancer with respect to other, so manner that orbits is
##     physically turn of *other* dancer, other way about.  Architect's reading, and it
##     is what `sim/rigid` is asked.  What survives is whose crown hands are over: couple
##     raise them over dancer who walks under, which follows manner, not physics.
##   Card sim has not been asked about is absent, and gets no tag: unasked reads as
##     unasked rather than as disagreement.

{.experimental: "strictFuncs".}

import std/[json, strformat, tables]

import ../sim/[hold, rig, walk]
import ../src/dance_ontology/rotation
import ./[asks, parts]


const CROWN = Band.Crown
  ## Whole reference is drawn over crown: `design/parts` picks `ABOVE_BOTH` for chains
  ## and `ABOVE_ONE`/`ABOVE_OTHER` for singles, so no card asks about any other band.


proc carries(links: seq[Link]; away: bool; manner: Manner; turns: float): bool =
  ## Whether this hold carries this far under this manner, in its positive sense.
  ##   Couple stand for turn they are about to take, so question goes straight to
  ##     `walk.reaches`, which asks it of every distance couple may stand at and
  ##     answers at first that carries it.  Sweeping once and reading several
  ##     answers off it would be cheaper, but it would pin whole manner to one
  ##     distance again, which is what Architect ruled against.
  let
    walks = bodyOf(MANNERS[manner].who)
    turner = if ord(MANNERS[manner].about) == ord(About.Axis): walks
             else: otherThan(walks)
    # Orbit is other dancer turned other way about, so its sense is flipped.
    flip = ord(MANNERS[manner].about) != ord(About.Axis)
    way = (if flip: -turns else: turns)
  reaches(HUMAN, CROWN, links, way, away = away, who = turner, head = walks)


proc answers(): OrderedTable[string, bool] =
  ## Every card sim can be asked about, keyed as page keys its own pictures.
  result = initOrderedTable[string, bool]()

  # Every still, as `asks` lists them: built at its facing and asked whether
  # any pose holds there.
  for a in stillAsks():
    result[a.key] = holdsAt(HUMAN, CROWN, a.links, a.turns, a.away, a.head,
                          either = a.either)

  # `B` and `E`: four single-hand holds, four manners, four quarters, moving.
  for c, single in SINGLES:
    let links = linksOf(single.holds)
    for manner in Manner:
      let
        tag = MANNERS[manner].tag
        sense = windSense(manner)
      for q in 0 ..< QUARTERS_ROUND:
        result[&"tr_{tag}_{c}_{q}_{(q + 1) mod QUARTERS_ROUND}"] =
          carries(links, false, manner, asked(sense * (q + 1).float / QUARTERS_ROUND.float))
      result[&"rd_{tag}_{c}"] = carries(links, false, manner, sense)

  # `F` and `G`: each chain under each manner, whole chain and each half of it.
  #   These are moving cards, so they are asked whether couple carry along them
  #   rather than whether pose stands there.
  for (key, arms, away) in [("h", HAND_TO_HAND, false), ("p", PAIRED, true)]:
    let links = linksOf(arms)
    for manner in Manner:
      let
        tag = MANNERS[manner].tag
        sense = windSense(manner)
      result[&"{key}c_{tag}"] = carries(links, away, manner, asked(sense * STEPS[^1]))
      for i in 0 ..< STEPS.len - 1:
        # Edge is walked entire, so what it asks of couple is its *furthest*
        # wound end, kept with its own sign, and not where it happens to
        # finish.  Chain runs from swan in to frame and out to other swan, so
        # magnitude falls then rises: asking destination alone made first edge,
        # which leaves far swan, read as easy as its near end, while last edge,
        # which arrives at other swan, read as hard as its far one.  Architect
        # saw it at once -- they are same edge mirrored.
        let far = (if abs(STEPS[i]) > abs(STEPS[i + 1]): STEPS[i]
                   else: STEPS[i + 1])
        result[&"{key}w_{tag}_{i}"] = carries(links, away, manner, asked(sense * far))


when isMainModule:
  var said = newJObject()
  for id, got in answers():
    said[id] = %got
  writeFile("design/modelled.json", pretty(said) & "\n")
  echo "wrote design/modelled.json: ", said.len, " answers"
