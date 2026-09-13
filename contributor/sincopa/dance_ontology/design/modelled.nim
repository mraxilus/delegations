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

import std/[json, options, strformat, tables]

import ../sim/[body, hold, rig, walk]
import ../src/dance_ontology/draw/terms
import ../src/dance_ontology/frame
import ../src/dance_ontology/rotation
import ./parts


const CROWN = Band.Crown
  ## Whole reference is drawn over crown: `design/parts` picks `ABOVE_BOTH` for chains
  ## and `ABOVE_ONE`/`ABOVE_OTHER` for singles, so no card asks about any other band.


func bodyOf(who: terms.Dancer): Body =
  ## Two enums are named `Dancer` in this tree, `terms`' and `rotation`'s.
  ## `parts.MANNERS` carries `terms`' one, beside `rotation`'s `About`.
  if ord(who) == ord(terms.Dancer.Lead): Body.One else: Body.Two

func otherThan(who: Body): Body =
  if ord(who) == ord(Body.One): Body.Two else: Body.One

func armOf(a: terms.Arm): body.Arm =
  if ord(a) == ord(terms.Arm.L): body.Arm.Left else: body.Arm.Right

func linksOf(holds: Holds): seq[Link] =
  ## Read `parts`'s hold table: index is lead's arm, value is follow's it joins.
  for lead, follow in holds.pairs:
    if follow.isSome:
      result.add Link(ends: [(Body.One, armOf(terms.Arm(lead))),
                             (Body.Two, armOf(follow.get))])


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


func holdsOf(target: Frame): Holds =
  ## Which hands this frame joins, in `parts`'s own terms.
  for side in Side:
    if target.hold[side].isSome:
      let
        lead = (if ord(side) == ord(Side.Left): terms.Arm.L else: terms.Arm.R)
        follow = (if ord(target.hold[side].get) == ord(Site.LeftHand): terms.Arm.L
                  else: terms.Arm.R)
      result[lead] = some follow

func restsFacing(target: Frame): bool =
  ## Whether frame rests face to face rather than pillion lead.  Same reading
  ## `review_page` makes, by `phaseOf`, and never written down.
  if target.countHolds < 2: true else: phaseOf(holdsOf(target)) < 1e-9


proc answers(): OrderedTable[string, bool] =
  ## Every card sim can be asked about, keyed as page keys its own pictures.
  result = initOrderedTable[string, bool]()

  # `A`. Standard diagram: eight frames, each drawn at two facings.
  #   `twist` names facing *drawn* -- nought face to face, one pillion lead --
  #     and not half turns from frame's own rest, which is what this asked at
  #     first.  Frame that rests pillion is therefore at rest at twist of one,
  #     and half turn from it at nought: A10 and A12 read "at rest" for that
  #     reason, and asking them for half turn called them unreachable.
  #   A17 is last frame drawn turned other way about, and is asked so.
  func amountFor(target: Frame; twist: int): float =
    if (twist == 0) == restsFacing(target): 0.0 else: 0.5
  for i, target in FRAMES:
    let
      links = linksOf(holdsOf(target))
      away = not restsFacing(target)
    for twist in [0, 1]:
      result[&"A{i * 2 + twist + 1}"] =
        holdsAt(HUMAN, CROWN, links, amountFor(target, twist), away)
  result["A17"] = block:
    let
      target = FRAMES[^1]
      links = linksOf(holdsOf(target))
      away = not restsFacing(target)
    holdsAt(HUMAN, CROWN, links, -amountFor(target, 1), away)

  # `B` and `E`: four single-hand holds, four manners, four quarters.
  for c, single in SINGLES:
    let links = linksOf(single.holds)
    for manner in Manner:
      let
        tag = MANNERS[manner].tag
        sense = windSense(manner)
      for q in 0 ..< QUARTERS_ROUND:
        let at = sense * q.float / QUARTERS_ROUND.float
        result[&"st_{tag}_{c}_{q}"] =
          holdsAt(HUMAN, CROWN, links, at, head = bodyOf(MANNERS[manner].who))
        result[&"tr_{tag}_{c}_{q}_{(q + 1) mod QUARTERS_ROUND}"] =
          carries(links, false, manner, sense * (q + 1).float / QUARTERS_ROUND.float)
      result[&"rd_{tag}_{c}"] = carries(links, false, manner, sense)

  # `C` and `D`: two chains, seven positions each, half turn apart.
  #   Their captions count *clockwise seen from above*, which is turn's negative
  #   way, so wind's sign is flipped before it is asked.  Both chains happen to
  #   stop at same place each way, so this changes no answer today -- it is here
  #   because it would change one for hold that did not.
  for (tag, arms, away) in [("C", HAND_TO_HAND, false), ("D", PAIRED, true)]:
    let links = linksOf(arms)
    for i, w in STEPS:
      result[tag & $(i + 1)] = holdsAt(HUMAN, CROWN, links, -w, away)

  # `F` and `G`: each chain under each manner, whole chain and each half of it.
  #   These are moving cards, so they are asked whether couple carry along them
  #   rather than whether pose stands there.
  for (key, arms, away) in [("h", HAND_TO_HAND, false), ("p", PAIRED, true)]:
    let links = linksOf(arms)
    for manner in Manner:
      let
        tag = MANNERS[manner].tag
        sense = windSense(manner)
      result[&"{key}c_{tag}"] = carries(links, away, manner, sense * STEPS[^1])
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
        result[&"{key}w_{tag}_{i}"] = carries(links, away, manner, sense * far)


when isMainModule:
  var said = newJObject()
  for id, got in answers():
    said[id] = %got
  writeFile("design/modelled.json", pretty(said) & "\n")
  echo "wrote design/modelled.json: ", said.len, " answers"
