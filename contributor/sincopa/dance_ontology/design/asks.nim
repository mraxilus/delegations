## What each still card of reference asks of body simulation: which hands are joined, who
## turns and how far from rest, and so whose crown joined hands are carried over.
##
##   One list, read by `design/modelled` (which answers each) and by `design/rig`
##     (which records each), so card is asked same question wherever it is asked.
##     Second place enumerating cards would be second place to get one wrong.
##   Keyed by question, never by card's own name: page folds duplicate pictures
##     together and hands out identifiers, and it alone does that.

{.experimental: "strictFuncs".}

import std/[options, strformat]

import ../simulation/[body, hold]
import ../src/dance_ontology/[diagram, frame]
import ../src/dance_ontology/draw/terms
from ../src/dance_ontology/draw/pose import About
from ../src/dance_ontology/draw/route import overArm
from ../src/dance_ontology/rotation import HalfTurns
import ./parts


type StillAsk* = object  ## One still card, as simulation is asked it.
  key*: string  ## Question's key, as page keys its own pictures.
  links*: seq[Link]
  turns*: float  ## How far `who` turns from where hold rests, simulation's own sense.
  rest*: Facing  ## Facing hold rests at (`parts.restOf`).
  who*: Body  ## Who simulation turns: dancer at centre of turn.
  head*: Body  ## Whose crown joined hands go over: one who turns, since connection goes
                  ## round dancer whose facing turns against it.
  is_either_way*: bool  ## Whether couple may be wound to this facing either way about:
                  ## card that draws same picture turned either way fixes neither.
  over*: int  ## Lead's arm card lays over at lead's crossing, by ordinal: still holds only
              ## where pose lays it so (`walk.standsAt`).  Below nought where card names none.


func bodyOf*(who: terms.Dancer): Body =
  ## Two enums are named `Dancer` in this tree, `terms`' and `rotation`'s.
  ## `parts.MANNERS` carries `terms`' one, beside `rotation`'s `About`.
  if ord(who) == ord(terms.Dancer.Lead): Body.One else: Body.Two

func otherThan*(who: Body): Body =
  ## Name other dancer of two.
  if ord(who) == ord(Body.One): Body.Two else: Body.One

func armOf*(arm: terms.Arm): body.Arm =
  ## Translate drawing's arm into simulation's.
  if ord(arm) == ord(terms.Arm.Left): body.Arm.Left else: body.Arm.Right

func linksOf*(holds: Holds): seq[Link] =
  ## Read `parts`'s hold table: index is lead's arm, value is follow's it joins.
  for lead, follow in holds.pairs:
    if follow.isSome:
      result.add Link(ends: [(Body.One, armOf(terms.Arm(lead))), (Body.Two, armOf(follow.get))])

func holdsOf*(target: Frame): Holds =
  ## Which hands this frame joins, in `parts`'s own terms.
  for side in Side:
    if target.hold[side].isSome:
      let
        lead = (if ord(side) == ord(Side.Left): terms.Arm.Left else: terms.Arm.Right)
        follow = (if ord(target.hold[side].get) == ord(Site.LeftHand): terms.Arm.Left
                  else: terms.Arm.Right)
      result[lead] = some follow

func asked*(wind: float): float = -wind
  ## Page's turn as simulation's.  Page counts clockwise seen from above
  ## (`rotation.wayOf`, "how drawings see couple"); simulation counts anticlockwise
  ## (`body.turned`).  Every wind is flipped here, in one place, before it is
  ## asked: flipped for chains alone, A16 was stood in C03's pose and A17 in
  ## C05's, mirror of what each card draws, and every single-hand card likewise.

func restOf*(target: Frame): Facing = restOf(holdsOf(target))
  ## Name facing frame rests at.  Same reading `review_page` makes, by
  ## `parts.restOf`, and never written down.

func isRestAway*(rest: Facing): bool =
  ## Say rest as simulation is told it: Face-to-face, or follow turned half, which is
  ## Face-to-back and which simulation calls `away`.
  ##   Simulation stands couple at no other rest, and no card asks one.
  case rest
  of Facing.FaceToFace: false
  of Facing.FaceToBack: true
  else: raise newException(Defect, &"Simulation rests couple at no `{rest.name}`.")

func isRestAway*(ask: StillAsk): bool = isRestAway(ask.rest)
  ## Say card's rest as simulation is told it.


func turnerOf*(manner: Manner, amount: float): tuple[who: Body, turns: float] =
  ## Who simulation turns for this manner, and how far in its own sense, where page turns
  ## manner's own dancer `amount` turns clockwise.
  ##   Axis turn is walker's own: they turn on spot, and partner stays where they stand.
  ##   Orbit keeps walker facing centre (rule 32), so walker's relation to connection never
  ##     changes and centre dancer's does: physically, dancer at centre turns other way
  ##     about.  Architect's reading.  Simulation turns that dancer, and connection goes
  ##     round them and over their crown.  Card draws same: orbit lands on picture partner's
  ##     axis turn reaches (`parts.LUT_ROUND_BY_MANNER`).
  let walker = bodyOf(MANNERS[manner].who)
  if MANNERS[manner].about == About.Axis: (walker, asked(amount))
  else: (otherThan(walker), asked(-amount))


func stillAsks*(): seq[StillAsk] =
  ## Every still card, in page's own order: standard diagram, single-hand
  ## positions, then both chains.

  # `A`. Standard diagram: eight frames, each drawn at two facings.
  #   `twist` names facing *drawn* -- nought Face-to-face, one Face-to-back --
  #     and not half turns from frame's own rest.  Frame that rests Face-to-back is
  #     therefore at rest at twist of one, and half turn from it at nought: A10
  #     and A12 read "at rest" for that reason, and asking them for half turn
  #     called them unreachable.
  #   A17 is last frame drawn turned other way about, and is asked so.
  #   Card whose picture is same turned either way fixes neither way, and is
  #     asked either way (`either`): half turn from rest is half turn whichever
  #     way couple took it.  Same reading page makes when it decides whether to
  #     draw frame turned other way at all (A17).
  func amountFor(target: Frame, twist: int): float =
    ## Say how far frame winds from its rest to facing `twist` draws: nought or half turn.
    if turnedFacing(0.0, 180.0 * float(twist)) == some(restOf(target)): 0.0 else: 0.5

  func isDrawnEitherWay(target: Frame): bool =
    ## Decide whether frame draws same picture wound either way about.
    renderFrame(target, HalfTurns(1)) == renderFrame(target, HalfTurns(-1))

  #   Frame that names one connection over turns whichever way puts that one over, as
  #     chain names its positions (`route.overArm`): left over at positive wind.  So it
  #     fixes way about, though it draws same picture either way: drawing puts frame's own
  #     connection over whichever way couple turned.  Asked either way, A11 stood A09's
  #     crossing, left over right.
  func senseOf(target: Frame): float =
    ## Say which way frame's half turn goes: right over winds other way.
    if target.over.isSome and target.over.get == Side.Right: -1.0 else: 1.0

  #   Wound frame of two connections lays one over at first crossing, as chain does, by its
  #     wind (`route.overArm`): frame that names its own winds whichever way puts it over.
  func overOf(target: Frame, wind: float): int =
    ## Say which of lead's arms card lays over, by ordinal, or below nought where it names none.
    if wind == 0.0 or linksOf(holdsOf(target)).len < 2: -1 else: ord(armOf(overArm(wind)))

  for i, target in FRAMES:
    for twist in [0, 1]:
      let amount = amountFor(target, twist)
      result.add StillAsk(
        key: &"A{i * 2 + twist + 1:02}",
        links: linksOf(holdsOf(target)),
        turns: asked(senseOf(target) * amount),
        rest: restOf(target),
        who: Body.Two,
        head: Body.Two,
        is_either_way: amount != 0.0 and target.over.isNone and isDrawnEitherWay(target),
        over: overOf(target, senseOf(target) * amount),
      )
  block:
    let target = FRAMES[^1]
    result.add StillAsk(
      key: "A17",
      links: linksOf(holdsOf(target)),
      turns: asked(-amountFor(target, 1)),
      rest: restOf(target),
      who: Body.Two,
      head: Body.Two,
      over: overOf(target, -amountFor(target, 1)),
    )
  # `B`: four single-hand holds, four manners, four quarters.  Page turns every manner's
  # own dancer clockwise (`parts.quarterPose`), and simulation turns whoever `turnerOf`
  # says, so each card stands as drawn: lead who turned has follow at their side.
  #   Turning follow alone stood every lead's turn with follow ahead, and orbit with hands
  #     over walker's crown: twin cards of one picture stood two poses.
  for single_index, single in SINGLES:
    for manner in Manner:
      for quarter in 0..<QUARTERS_ROUND:
        let (who, turns) = turnerOf(manner, float(quarter) / float(QUARTERS_ROUND))
        result.add StillAsk(
          key: &"st_{MANNERS[manner].tag}_{single_index}_{quarter}",
          links: linksOf(single.holds),
          turns: turns,
          rest: restOf(single.holds),
          who: who,
          head: who,
          over: -1,
        )
  # `C` and `D`: two chains, seven positions each, half turn apart.  Each wound position names
  # lead's arm on top at first crossing by its wind (`route.overArm`).
  for (tag, arms) in [("C", HAND_TO_HAND), ("D", PAIRED)]:
    for i, wind in STEPS:
      result.add StillAsk(
        key: &"{tag}{i + 1:02}",
        links: linksOf(arms),
        turns: asked(wind),
        rest: restOf(arms),
        who: Body.Two,
        head: Body.Two,
        over: (if wind == 0.0: -1 else: ord(armOf(overArm(wind)))),
      )
