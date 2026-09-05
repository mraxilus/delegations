## Model rotation axis of ontology, which is not finished.
##
## Workbook has twelve turn sheets, one for each combination of who turns
## (lead or follow), which way (left or right) and how far (half, one, or
## one-and-a-half turns), and all twelve are empty.
##   This module is what hand-to-hand model says about them before any of
##     them is filled in.
##   Kept separate so that nothing uncertain leaks into `frame.nim` or
##     `transition.nim`.
##     Cost of separation: turned couple is `Posture`, not `Frame`, so every
##       consumer of turning joins two models at seam `rest` marks.
##       Accepted -- certain half stays checkable against workbook while
##       this half is still being measured.
##
## Quantity rotation adds is *twist*: how far follow's body has turned
## relative to lead's.
##   It is one number for couple rather than one per arm, because both
##     bodies are rigid, so both arms see same relative rotation.
##     Cost of one number for couple: model cannot say which dancer's motion
##       stored twist, only how much is stored.  Accepted -- half of
##       workbook's twelve sheets land where other half do, so sheets do not
##       say either.
##   Two consequences follow without any measurement:
##     Rotation of whole couple stores no twist, which is why couple can
##       travel round floor all night without unwinding.
##     Parity of twist decides geometry hand-to-hand model rests on.  At
##       half turn follow's back is to lead, their left hand is now on
##       lead's left, and every connection that was crossed is parallel.
##
## This is also where hand on partner's body belongs.
##   It does not add frame: it takes turn away, because arm already around
##     partner has no twist left to give.
##   And it is what wound arm ends up on, which is what vocabulary's `wrap`
##     and `lock` name.

{.experimental: "strictFuncs".}

import std/[options, strutils]

import ./frame



#[ Concepts ]#

type
  Dancer* {.pure.} = enum ## Name two roles, which rotate independently.
    Lead, Follow

  Level* {.pure.} = enum ## Name height arm is carried at.
    ## Every level is height (rule 36 in `design/rules`): low is below
    ## shoulder about torso, high above it about neck, above is over head.
    ## Earlier reading had low and high relative -- which arm lies over which
    ## -- and that was wrong: over-under of two arms is what *wrap* says
    ## (under other arm low, over it high), not what level says.
    Low,   ## Below shoulder, about torso.
    High,  ## Above shoulder, about neck.
    Above  ## Above head, on axis couple turns about.

  Way* {.pure.} = enum ## Name which way dancer turns, seen from above.
    Clockwise,
    Anticlockwise

  About* {.pure.} = enum ## Name what dancer turns around.
    Axis,  ## Their own, so their facing changes where they stand.
    Orbit  ## Couple's centre of mass, so they travel around it.

  BodySite* {.pure.} = enum ## Name place on body arm rests on or wraps around.
    Waist, Torso, Shoulder, Neck

  Blocker* {.pure.} = enum ## Name what stops arm carrying any more twist.
    Wrap, ## Arm is carried across front of body.
    Lock  ## Arm is carried behind line of body.

  HalfTurns* = int ## Count rotation in half turns, granularity workbook uses.

  Turn* = object ## Hold one rotation of couple, one entry for each dancer.
    turns*: array[Dancer, HalfTurns] ## Half turns, positive to that dancer's right.

  Contact* = object ## Hold one lead hand resting on follow's body.
    side*: Side       ## Lead hand that rests.
    where*: BodySite  ## Place it rests on.

  Posture* = object ## Hold frame together with rotation stored in it.
    frame*: Frame
    level*: array[Side, Level]  ## Height each arm is carried at.
    contact*: Option[Contact]   ## Hand resting on follow's body, which stops turn.
    twist*: HalfTurns           ## Follow's rotation less lead's, in half turns.


const
  UNBOUNDED_TURNS* = high(HalfTurns)
    ## Say capacity that limits nothing, as value on capacity axis.
    ##   Named saturation rather than `Option`: capacity is compared with
    ##     `<=` everywhere, and plus infinity is honest answer for "nothing
    ##     joins bodies", not absence.
    ##     Cost of saturation constant: reader must learn that one value of
    ##       axis means never.  Accepted -- alternative wraps every
    ##       comparison in unwrap for no prevented mistake.
  CAPACITY_SINGLE* = 2 ## Hold one full turn on one hand-to-hand connection.
  CAPACITY_PAIR* = 1   ## Hold half turn on two hand-to-hand connections.
  CAPACITY_CONTACT* = 0 ## Hold nothing while hand rests on partner's body.
  CAPACITY_WRAP_LOW* = 1
    ## Hold half turn while arm is wrapped low.  Measured, not derived.
    ##   Earlier body sim claimed to derive this and did not: it priced wound
    ##     half turn at half of torso's girth by assumption, so arithmetic
    ##     only returned measurement it was fitted to.  Jointed-arm sim,
    ##     which turns body and lets arms take most comfortable pose that
    ##     holds, finds hand to hand's low wrap blocking just past half (0.56
    ##     turns) and Left to left's short of it (0.30), at shoulder's twist
    ##     (`sim/verdicts.md`) -- independent witness, not derivation, and it
    ##     agrees on one and not other; constant stays dance's measurement.
  CAPACITY_ARM* = 2
    ## Hold full turn while arm is anywhere else.  Measured for low lock;
    ## assumed for two high ones, which is next thing to dance.
    ##   Jointed-arm sim (`sim/verdicts.md`) finds Left to left's low lock
    ##     reaching whole turn, led, and blocking just past it (1.12), hand
    ##     to hand's blocking short of it (0.87); at neck it finds turn and
    ##     more one way and under half other way, elbows already folded to
    ##     their limit at rest with chests as close as stance puts them.
    ##     Disagreement, recorded rather than resolved; constant stays
    ##     dance's measurement.
  ABOVE_BLOCKS* = false
    ## Whether arm over head blocks turn.  It does in some cases and nobody
    ## has said which, so model turns freely there.
    ##   No longer on no authority for single connection: jointed-arm sim
    ##     finds hand held over follow's head turns with her, and holds
    ##     through two-and-a-half turns either way (`sim/verdicts.md`).  Two
    ##     connections above are another matter -- sim finds parallel pair
    ##     free one way and blocked at whole turn other way, crossed pair at
    ##     three quarters -- and rule 13's swan is their asserted ceiling, so
    ##     flag stays flag.



#[ Geometry ]#

func isFacing*(twist: HalfTurns): bool = twist mod 2 == 0
  ## Test whether partners still face each other after rotation.


func crossedSite*(side: Side; twist: HalfTurns): Site =
  ## Get follow hand this lead hand reaches only across midline, after
  ## rotation.
  ##
  ## This is whole of hand-to-hand model's dependence on rotation.  At half
  ## turn follow has turned their back, so hand that was across midline is
  ## now near one and every reading of frame flips with it.  Frames do not
  ## change; way they are read does.
  if isFacing(twist): crossedSite(side) else: parallelSite(side)


func parallelSite*(side: Side; twist: HalfTurns): Site =
  ## Get follow hand this lead hand reaches without crossing, after rotation.
  if isFacing(twist): parallelSite(side) else: crossedSite(side)



#[ Capacity ]#

func armCapacity*(blocker: Option[Blocker]; level: Level): HalfTurns =
  ## Get how much twist arm itself can carry, wherever it has ended up.
  ##   Measured on `Left to left`, one hand: low wrap holds half turn and
  ##     everything else holds full one.
  ##     Arm has to cross torso to wrap low, and it runs out of length before
  ##       hold does; carried behind back, or up at shoulder or neck, it has
  ##       further to go.
  ##   This is second of two ceilings, and reason there are two: first is
  ##     property of what joins couple, this one of what arm is doing.
  ##     Which of them binds is what tells wrap from lock -- see `blocker`.
  ##   Arm above head is on axis couple turns about, so it has nothing to
  ##     wind round and nothing to run out of.
  ##     One case has it blocking anyway, and this does not know it yet,
  ##       which is why `ABOVE_BLOCKS` says so out loud rather than being
  ##       quietly absent.
  if level == Level.Above:
    return UNBOUNDED_TURNS
  if blocker == some(Blocker.Wrap) and level == Level.Low:
    CAPACITY_WRAP_LOW
  else:
    CAPACITY_ARM


func capacity*(posture: Posture): HalfTurns =
  ## Get how much twist posture can store before couple must change it.
  ##
  ## Hand on follow's body gives no turn away: it is already around them.
  ## This is what closed position is, and it is why follow's turn out of it
  ## needs lead's right hand to leave back first.  Single hand-to-hand
  ## connection is roomiest, because both dancers can share turn between
  ## their two arms.  Pair binds at half that, which is why wrap is led from
  ## two hands and lock from one.
  if posture.contact.isSome:
    return CAPACITY_CONTACT
  case posture.frame.countHolds
  of 0: UNBOUNDED_TURNS # Nothing joins bodies, so nothing limits turn.
  of 1: CAPACITY_SINGLE
  else: CAPACITY_PAIR


func blocker*(twist: HalfTurns): Option[Blocker] =
  ## Get what arms are doing at given twist.
  ##   Size decides, not direction: half turn wraps and full turn locks,
  ##     whichever way it is danced.
  ##   This was fitted to two cells of `rotations` sheet and is now
  ##     consequence of measured one.
  ##     Low wrap holds half turn and no more (`armCapacity`), so arm carried
  ##       low that is asked for full turn cannot still be wrapped -- it has
  ##       to have gone behind back, which is lock.
  ##     Size of turn decides because arm runs out at some size.
  ##   Rejected: rule where direction decides -- one way carrying arm across
  ##     front and so wrapping, other way behind back and so locking, at
  ##     either size.
  ##     Two cells were equally well fitted by it, but it has nothing to say
  ##       about why low wrap should bind tighter than low lock, and it makes
  ##       wrap and lock two different motions rather than two depths of one.
  ##       Measurement is what chose between them.
  case abs(twist)
  of 0: none(Blocker)
  of 1: some(Blocker.Wrap)
  else: some(Blocker.Lock)


func blockerOf*(twist: HalfTurns; level: Level): Option[Blocker] =
  ## Get what blocks arm at given twist, at height it is carried.
  ##
  ## Only low or high arm is wound round anything: arm over head is on axis,
  ## so there is nothing for it to be across front of or behind line of, and
  ## it carries no blocker however far couple turns.
  if level == Level.Above: none(Blocker) else: blocker(twist)


func armsCapacity*(posture: Posture; twist: HalfTurns): HalfTurns =
  ## Get how much twist arms of posture carry between them.
  ##   Tightest arm binds.
  ##     Couple is held together by all of its connections at once, so first
  ##       arm to run out is one that stops turn -- and only arms that are
  ##       holding count, because free arm is carrying nothing and has
  ##       nothing to run out of.
  ##   With no arm holding at all there is nothing to run out: two people who
  ##     are not touching can each face wherever they like.
  if posture.frame.countHolds == 0:
    return UNBOUNDED_TURNS
  result = UNBOUNDED_TURNS
  for side in Side:
    if posture.frame.hold[side].isSome:
      result = min(result, armCapacity(blockerOf(twist, posture.level[side]),
        posture.level[side]))


func around*(blocker: Blocker; level: Level): Option[BodySite] =
  ## Get place on body wound arm is carried around.
  ##   Workbook asks whether upper and lower wrap are separate modifiers.
  ##     They are not: level at which arm is already carried decides where
  ##     it lands, so body site is derived rather than named.
  ##     Reading vocabulary's own definitions, low lock is behind back and
  ##       high lock is at shoulder of same arm; low wrap crosses torso and
  ##       high wrap goes round neck.
  ##   Nothing, for arm over head: it is on axis rather than around anything,
  ##     which is why it carries no blocker to begin with.
  if level == Level.Above:
    return none(BodySite)
  case blocker
  of Blocker.Wrap:
    case level
    of Level.Low: some(BodySite.Torso)
    of Level.High: some(BodySite.Neck)
    of Level.Above: none(BodySite)
  of Blocker.Lock:
    case level
    of Level.Low: some(BodySite.Waist)
    of Level.High: some(BodySite.Shoulder)
    of Level.Above: none(BodySite)



#[ Turning ]#

func rest*(target: Frame): Posture =
  ## Get posture of frame that has not turned, which is where hand-to-hand
  ## ontology lives.
  Posture(
    frame: target,
    level: [Level.Low, Level.Low],
    contact: none(Contact),
    twist: 0,
  )


func rests*(posture: Posture; side: Side; where: BodySite): Posture =
  ## Rest one lead hand on follow's body, which takes turn away.
  result = posture
  result.contact = some(Contact(side: side, where: where))


func rotates*(who: Dancer; amount: HalfTurns): Turn =
  ## Form turn where one dancer rotates and other holds their facing.
  result.turns[who] = amount


func together*(amount: HalfTurns): Turn =
  ## Form turn where couple rotates as one, which stores no twist.
  Turn(turns: [amount, amount])


func stored*(posture: Posture; motion: Turn): HalfTurns =
  ## Get twist that turn would leave stored, whether or not it can be.
  ##
  ## Turn is taken as one motion rather than as one dancer after other,
  ## because couple does not pass through state where only one of them has
  ## moved.
  posture.twist + motion.turns[Dancer.Follow] - motion.turns[Dancer.Lead]


func holds*(posture: Posture; twist: HalfTurns): bool =
  ## Test whether posture can stand at given twist.
  ##   Two ceilings, and posture has to be under both: what joins couple can
  ##     only give away so much turn, and arm can only carry so much wherever
  ##     it has wound up.
  ##     One definition, so that everything that refuses turn refuses it for
  ##       same reason.
  ##   On hold that has been measured neither ceiling is slack: arm's is what
  ##     makes full turn into lock rather than wrap, and hold's is what
  ##     refuses one-and-a-half.
  abs(twist) <= posture.capacity and abs(twist) <= posture.armsCapacity(twist)


func turn*(posture: Posture; motion: Turn): Option[Posture] =
  ## Turn couple, refusing turn that arms cannot hold.
  ##
  ## Refusal is what matters: turn beyond posture's capacity is not turn
  ## couple can do, it is turn plus change of frame, and change of frame has
  ## to be led.
  let reached = posture.stored(motion)
  if not posture.holds(reached):
    return none(Posture)
  var turned = posture
  turned.twist = reached
  some(turned)



#[ What There Is ]#

const
  MOST_TURN* = 3
    ## Largest turn workbook's sheets record, in half turns.
    ##
    ## One-and-a-half turns.  Not claim that nothing larger is dancable, only
    ## that nothing larger is written down, so it is where enumerating stops.
  TURN_WAYS* = [1, -1] ## To turning dancer's right, then to their left.


func normalised*(posture: Posture): Posture =
  ## Put arms that are not holding back down.
  ##
  ## Height of free arm cannot stop turn, so two postures differing only in
  ## where free hand is carried are one posture.  Enumerating without this
  ## would count each of them twice and claim more states than there are.
  result = posture
  for side in Side:
    if posture.frame.hold[side].isNone:
      result.level[side] = Level.Low


func postures*(): seq[Posture] =
  ## Get every posture that model derives: frame, heights it is held at, and
  ## every twist those two can stand at.
  ##
  ## Hand-to-hand half has `FRAMES`; this is its opposite number, and
  ## rotation views are built on it as frame views are built on that.  Hand
  ## resting on body is left out: it gives whole turn away, so it adds no
  ## posture that turning can reach.
  for target in FRAMES:
    for left in Level:
      for right in Level:
        let held = normalised(Posture(frame: target, level: [left, right],
          contact: none(Contact), twist: 0))
        if held.level != [left, right]:
          continue
        for twist in -MOST_TURN .. MOST_TURN:
          if not held.holds(twist):
            continue
          var stood = held
          stood.twist = twist
          result.add stood


type
  Refusal* {.pure.} = enum ## Say what stops turn that cannot be taken.
    Hold, ## What joins couple cannot give that much turn away.
    Arm   ## Arm cannot carry that much, wherever it has wound up.

  Offer* = object ## Hold one turn out of posture, taken or refused.
    who*: Dancer            ## Dancer who turns; other holds their facing.
    amount*: HalfTurns      ## Half turns, positive to that dancer's right.
    to*: Posture            ## Where it lands, or would land if it could.
    refused*: Option[Refusal] ## Why it cannot be taken, where it cannot.


func refusal*(posture: Posture; twist: HalfTurns): Option[Refusal] =
  ## Say which ceiling refuses twist, if either does.
  ##
  ## Hold is named first where both would refuse, because it is one that
  ## dancer can do something about: letting hand go changes hold, and
  ## nothing changes how far arm reaches.
  if abs(twist) > posture.capacity:
    some(Refusal.Hold)
  elif abs(twist) > posture.armsCapacity(twist):
    some(Refusal.Arm)
  else:
    none(Refusal)


func turnsOf*(posture: Posture): seq[Offer] =
  ## Get every turn out of posture, refused ones included.
  ##   Every turn workbook has sheet for: either dancer, either way, by half,
  ##     whole or one-and-a-half.
  ##     Twelve of them, which is twelve sheets -- and half of them land where
  ##       other half do, because turn is stored as one number for couple
  ##       and it does not care which of them moved.
  ##   Refused ones are carried rather than dropped.
  ##     Page that listed only what can be danced would be menu; what makes
  ##       it validator is that it can say what cannot be danced, and why.
  ##   On axis only.
  ##     Dancer can also turn about couple's centre of mass rather than their
  ##       own -- `About.Orbit` -- and how much twist that stores is not
  ##       something this model has been told.
  ##     Offering orbit before knowing that would be page inventing move,
  ##       which is one thing it is for not doing.
  for who in Dancer:
    for way in TURN_WAYS:
      for size in 1 .. MOST_TURN:
        let
          amount = size * way
          motion = rotates(who, amount)
          reached = posture.stored(motion)
        var landing = posture
        landing.twist = reached
        result.add Offer(who: who, amount: amount, to: landing,
          refused: posture.refusal(reached))



#[ Naming ]#

const TURN_NAMES* = ["", "half a turn", "one turn", "one and a half turns"]
  ## Name each size of turn as workbook's sheets name it.


func wayOf*(amount: HalfTurns): Way =
  ## Get which way turn of this sign goes.
  ##
  ## Clockwise seen from above, which is how drawings see couple, and unlike
  ## dancer's own right and left it means same thing whichever of them is
  ## turning.
  if amount >= 0: Way.Clockwise else: Way.Anticlockwise


func wayName*(way: Way): string =
  ## Name way round as vocabulary names it.
  case way
  of Way.Clockwise: "clockwise"
  of Way.Anticlockwise: "anticlockwise"


func turnName*(amount: HalfTurns): string =
  ## Name turn by its size and way it goes.
  if amount == 0:
    return "no turn"
  TURN_NAMES[min(abs(amount), TURN_NAMES.high)] & " " & wayName(wayOf(amount))


func aboutName*(about: About): string =
  ## Name what dancer turns around, as vocabulary names it.
  ##   No page speaks these words yet; design workbench words its own
  ##     captions.  Kept for page that stands postures in links, which this
  ##     module exists ahead of.
  case about
  of About.Axis: "on axis"
  of About.Orbit: "on orbit"


func levelName*(level: Level): string = ($level).toLowerAscii
  ## Name height arm is carried at.


func armName*(posture: Posture): string =
  ## Name what arms are doing, where they are doing anything.
  ##
  ## Height comes first because it is what decides how far arm can go: low
  ## wrap and high wrap are one blocker at two heights, and it is height that
  ## says which of them runs out first.
  let what = blockerOf(posture.twist, posture.level[Side.Left])
  if what.isNone:
    return ""
  var heights: seq[string] = @[]
  for side in Side:
    if posture.frame.hold[side].isSome and
        levelName(posture.level[side]) notin heights:
      heights.add levelName(posture.level[side])
  (if heights.len == 1: heights[0] & " " else: "") &
    ($what.get).toLowerAscii


func describe*(posture: Posture): string =
  ## Name posture: frame it is held in, and what turning has done to it.
  if posture.twist == 0:
    return posture.frame.describe
  result = posture.frame.describe & ", " & turnName(posture.twist)
  let arms = posture.armName
  if arms.len > 0:
    result.add ", " & arms


func key*(posture: Posture): string =
  ## Form identifier for posture, for page to name one by.
  result = posture.frame.key & ":"
  for side in Side:
    result.add(if posture.level[side] == Level.High: "H" else: "L")
  result.add ":" & $posture.twist


func fromPostureKey*(key: string): Option[Posture] =
  ## Decode posture identifier, rejecting anything model does not derive.
  ##
  ## Rejecting will be what matters, as it is for frame: posture that model
  ## does not stand at could not then be arrived at by asking for it in link.
  ## No page decodes posture key yet -- this is `key`'s inverse, written with
  ## it so two cannot drift before they are needed.
  let parts = key.split(':')
  if parts.len != 3 or parts[1].len != 2:
    return none(Posture)
  let target = fromKey(parts[0])
  if target.isNone:
    return none(Posture)
  var stood = target.get.rest
  for index, side in [Side.Left, Side.Right]:
    stood.level[side] = if parts[1][index] == 'H': Level.High else: Level.Low
  var twist: int
  try:
    twist = parseInt(parts[2])
  except ValueError:
    return none(Posture)
  stood = normalised(stood)
  if not stood.holds(twist):
    return none(Posture)
  stood.twist = twist
  some(stood)
