## What each still card of reference asks of body sim: which hands are joined, how
## far couple are turned from rest, and whose crown joined hands are carried over.
##
##   One list, read by `design/modelled` (which answers each) and by `design/rig`
##     (which records each), so card is asked same question wherever it is asked.
##     Second place enumerating cards would be second place to get one wrong.
##   Keyed by question, never by card's own name: page folds duplicate pictures
##     together and hands out identifiers, and it alone does that.

{.experimental: "strictFuncs".}

import std/[options, strformat]

import ../sim/[body, hold]
import ../src/dance_ontology/diagram
import ../src/dance_ontology/draw/terms
import ../src/dance_ontology/frame
from ../src/dance_ontology/rotation import HalfTurns
import ./parts


type StillAsk* = object ## One still card, as sim is asked it.
  key*: string    ## Question's key, as page keys its own pictures.
  links*: seq[Link]
  turns*: float   ## Facing, in turns from where hold rests.
  rest*: Facing   ## Facing hold rests at, among eight (`parts.restOf`).
  head*: Body     ## Whose crown joined hands go over.
  either*: bool   ## Whether couple may be wound to this facing either way about:
                  ## card that draws same picture turned either way fixes neither.


func bodyOf*(who: terms.Dancer): Body =
  ## Two enums are named `Dancer` in this tree, `terms`' and `rotation`'s.
  ## `parts.MANNERS` carries `terms`' one, beside `rotation`'s `About`.
  if ord(who) == ord(terms.Dancer.Lead): Body.One else: Body.Two

func otherThan*(who: Body): Body =
  if ord(who) == ord(Body.One): Body.Two else: Body.One

func armOf*(a: terms.Arm): body.Arm =
  if ord(a) == ord(terms.Arm.L): body.Arm.Left else: body.Arm.Right

func linksOf*(holds: Holds): seq[Link] =
  ## Read `parts`'s hold table: index is lead's arm, value is follow's it joins.
  for lead, follow in holds.pairs:
    if follow.isSome:
      result.add Link(ends: [(Body.One, armOf(terms.Arm(lead))),
                             (Body.Two, armOf(follow.get))])

func holdsOf*(target: Frame): Holds =
  ## Which hands this frame joins, in `parts`'s own terms.
  for side in Side:
    if target.hold[side].isSome:
      let
        lead = (if ord(side) == ord(Side.Left): terms.Arm.L else: terms.Arm.R)
        follow = (if ord(target.hold[side].get) == ord(Site.LeftHand): terms.Arm.L
                  else: terms.Arm.R)
      result[lead] = some follow

func asked*(wind: float): float = -wind
  ## Page's turn as sim's.  Page counts clockwise seen from above
  ## (`rotation.wayOf`, "how drawings see couple"); sim counts anticlockwise
  ## (`body.turned`).  Every wind is flipped here, in one place, before it is
  ## asked: flipped for chains alone, A16 was stood in C3's pose and A17 in
  ## C5's, mirror of what each card draws, and every single-hand card likewise.

func restOf*(target: Frame): Facing = restOf(holdsOf(target))
  ## Name facing frame rests at.  Same reading `review_page` makes, by
  ## `parts.restOf`, and never written down.

func awayFor*(rest: Facing): bool =
  ## Say rest as sim is told it: Face-to-face, or follow turned half, which is
  ## `Pillion` and which sim calls `away`.
  ##   Sim stands couple at no other rest, and no card asks one.
  case rest
  of Facing.FaceToFace: false
  of Facing.LeadBehind: true
  else: raise newException(Defect, &"Sim rests couple at no `{rest.name}`.")

func away*(a: StillAsk): bool = awayFor(a.rest)
  ## Say card's rest as sim is told it.


func stillAsks*(): seq[StillAsk] =
  ## Every still card, in page's own order: standard diagram, single-hand
  ## positions, then both chains.
  # `A`. Standard diagram: eight frames, each drawn at two facings.
  #   `twist` names facing *drawn* -- nought Face-to-face, one Pillion --
  #     and not half turns from frame's own rest.  Frame that rests Pillion is
  #     therefore at rest at twist of one, and half turn from it at nought: A10
  #     and A12 read "at rest" for that reason, and asking them for half turn
  #     called them unreachable.
  #   A17 is last frame drawn turned other way about, and is asked so.
  #   Card whose picture is same turned either way fixes neither way, and is
  #     asked either way (`either`): half turn from rest is half turn whichever
  #     way couple took it.  Same reading page makes when it decides whether to
  #     draw frame turned other way at all (A17).
  func amountFor(target: Frame; twist: int): float =
    if turnedFacing(0.0, 180.0 * twist.float) == some(restOf(target)): 0.0 else: 0.5
  func eitherWay(target: Frame): bool =
    renderFrame(target, HalfTurns(1)) == renderFrame(target, HalfTurns(-1))
  for i, target in FRAMES:
    for twist in [0, 1]:
      let amount = amountFor(target, twist)
      result.add StillAsk(key: &"A{i * 2 + twist + 1}", links: linksOf(holdsOf(target)),
                          turns: asked(amount), rest: restOf(target),
                          head: Body.Two, either: amount != 0.0 and eitherWay(target))
  block:
    let target = FRAMES[^1]
    result.add StillAsk(key: "A17", links: linksOf(holdsOf(target)),
                        turns: asked(-amountFor(target, 1)),
                        rest: restOf(target), head: Body.Two)
  # `B`: four single-hand holds, four manners, four quarters.  Hands go over
  # crown of dancer who walks under, which follows manner.
  for c, single in SINGLES:
    for manner in Manner:
      let sense = windSense(manner)
      for q in 0 ..< QUARTERS_ROUND:
        result.add StillAsk(key: &"st_{MANNERS[manner].tag}_{c}_{q}",
                            links: linksOf(single.holds),
                            turns: asked(sense * q.float / QUARTERS_ROUND.float),
                            rest: restOf(single.holds), head: bodyOf(MANNERS[manner].who))
  # `C` and `D`: two chains, seven positions each, half turn apart.
  for (tag, arms) in [("C", HAND_TO_HAND), ("D", PAIRED)]:
    for i, w in STEPS:
      result.add StillAsk(key: tag & $(i + 1), links: linksOf(arms), turns: asked(w),
                          rest: restOf(arms), head: Body.Two)
