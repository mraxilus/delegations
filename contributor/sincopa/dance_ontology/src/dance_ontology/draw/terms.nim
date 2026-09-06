## Name what drawing of couple is made of: sides, levels, holds.
##
##   This is vocabulary that rules speak in, and drawing replicates.
##     It sat beside rules themselves while marks were being settled
##     and only workbench drew them; app draws them now, so
##     words move to where drawing is and ledger stays where
##     argument is (`design/rules.nim`, which re-exports this).
##   Settle table encodes rules 4 to 6 once; where hand lands and which
##     way its line goes round are derived from it, never restated.
##     Cost of one table: reader of `body` or `route` follows lookup here
##       to see what dance says.  Accepted -- alternative is same
##       fact written twice, which is how two of these rules were broken.
##   These names deliberately overlap `dance_ontology/rotation`'s, and do not
##     mean same things: `Way` is lock against wrap here and clockwise
##     against anticlockwise there.  No module may import both -- see
##     `draw/scene`, which is only place two vocabularies meet and
##     keeps them apart by touching only one of them.

{.experimental: "strictFuncs".}

import std/options


type
  Dancer* {.pure.} = enum ## Name one of couple.
    Lead, Follow
  Arm* {.pure.} = enum ## Name side of body, and so one hand of dancer.
    L, R               ## Letter is markup's own key.
  Level* {.pure.} = enum ## Name height connection is held at.
    ## Every level is height (rule 36); which arm passes over which is
    ##   wrap's business, not level's (rule 38).
    Low,               ## Below shoulder, about torso.
    High,              ## Above shoulder, about neck.
    Above              ## Above head.
  Way* {.pure.} = enum ## Name what held arm does at its level.
    Lock, ## Arm bent behind back (low), or bent to shoulder of
          ## same arm (high) -- round back either way (rule 37).
    Wrap  ## Arm crossed round front of body, under (low) or
          ## over (high) dancer's other arm (rule 38).
  Slot* {.pure.} = enum ## Name one of three spots hand can settle on side.
    Front,             ## Slightly towards dancer's own front.
    Default,           ## Where arm hangs.
    Back               ## Slightly towards dancer's own back.
  Whose* {.pure.} = enum ## Say which dancer's side settling hand lands on.
    Own, Other
  Sends* {.pure.} = enum ## Say which way round body hold sends its line.
    FrontWay, BackWay
  Settle* = tuple ## Hold what one lock or wrap does to its hand and its line.
    whose: Whose       ## Whose side hand settles on.
    slot: Slot         ## How far round that side it sits.
    sends: Sends       ## Which way round body line goes.


func settleOf*(level: Option[Level]; way: Option[Way]): Option[Settle] =
  ## Get what this hold does to its hand and its line, where rules 4 to 6
  ## say anything.
  ##   Rules 4 and 5 name *other* hand; rule 6 names current one.
  ##   Hold that names no level, or level without lock or wrap, has no
  ##     settle: there is no knowing which spot it means (rule 2's reading).
  ##   `above` never locks or wraps (rule 8), so it has no settle either.
  if level.isNone or way.isNone:
    return none(Settle)
  let settled: Option[Settle] =
    case level.get
    of Level.Low:
      case way.get
      of Way.Wrap: some (Whose.Other, Slot.Front, Sends.FrontWay)  # rule 4
      of Way.Lock: some (Whose.Other, Slot.Back, Sends.BackWay)    # rule 5
    of Level.High:
      case way.get
      of Way.Wrap: some (Whose.Other, Slot.Front, Sends.FrontWay)  # rule 4
      of Way.Lock: some (Whose.Own, Slot.Back, Sends.BackWay)      # rule 6
    of Level.Above:
      none(Settle)                                                 # rule 8
  settled


const WRAP_MIN* = 170 ## Least degrees line must hug body for lock or
                      ## wrap to be one at all.
  ##   Rule 7 asks for `"no less than just under 1/2 of the circumference"`.
  ##   Arcs this geometry produces are quantised at 0, 51, 90, 141 and
  ##     180 degrees, so any threshold in that last gap picks out same
  ##     set; 170 sits squarely in it, and `checks` asserts gap holds.


type
  Holds* = array[Arm, Option[Arm]]
    ## What each lead hand holds: follow's own side, where one is held.
  Levels* = array[Arm, Option[Level]]
    ## Level of each held connection, where one has been said.
  Ways* = array[Arm, Option[Way]]
    ## Whether each connection locks or wraps, where that has been said.


func other*(arm: Arm): Arm =
  ## Get opposite side.
  if arm == Arm.L: Arm.R else: Arm.L


func word*(level: Level): string =
  ## Write level as rules and pages say it.
  case level
  of Level.Low: "low"
  of Level.High: "high"
  of Level.Above: "above"

func word*(way: Way): string =
  ## Write way as rules and pages say it.
  case way
  of Way.Lock: "lock"
  of Way.Wrap: "wrap"

func word*(slot: Slot): string =
  ## Write slot as pages say it.
  case slot
  of Slot.Front: "front"
  of Slot.Default: "default"
  of Slot.Back: "back"


func handName*(arm: Arm): string =
  ## Write follow's hand as hold names it.
  ##   Lower case, because case carries meaning across whole project:
  ##     lead's hands are `Left` and `Right`, follow's `left` and `right`.
  if arm == Arm.L: "left" else: "right"
