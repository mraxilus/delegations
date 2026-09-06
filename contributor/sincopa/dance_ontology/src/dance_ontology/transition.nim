## Derive every change of frame from primitive transition helpers.
##
## Ontology names six helpers, and marks two of them with asterisk.
##   `place*` is "collect then drop" and `cut*` is "drop then collect", each
##     keeping contact through trace.  Asterisks are right, so neither is
##     primitive here.
##   Of remaining four, `flick` is `drop` led with momentum and changes no
##     frame, and `trace` slides hand along partner's body, which needs place
##     on body to slide to and so waits for rotation axis.
##   That leaves two primitives, `collect` and `drop`, and one relation: two
##     frames are one move apart exactly when one connection separates them.
##
## `place` and `cut` are kept as *compounds*.
##   Because lead thinks of each as one move even though arms do two, and
##     because workbook writes them in single cells.
##   Cost of keeping compounds beside primitives: compound is not `Move`, so
##     consumers carry second reading -- `compoundWay`, `compoundName`,
##     `compoundPhrase` beside `moves`, `label`, `phrase`.  Accepted --
##     dropping either register would misname something vocabulary or arms
##     insist on.
##
## Nothing here is table of moves.
##   Move exists between two frames exactly when difference between them is
##     one primitive, so transition relation is *classified* rather than
##     listed, and matrix in workbook becomes something to check against
##     rather than source of truth.
##   Cost of classifying instead of listing: every "what moves exist" question
##     is scan over `FRAMES` rather than lookup.  Accepted -- written table
##     could silently disagree with physics it claims to record.
##
## Every primitive is reversible: `collect` undoes `drop`, and `pass` and `cut`
## undo themselves.
##   Relation is therefore symmetric, which is strongest law module offers
##     for testing.

{.experimental: "strictFuncs".}

import std/[algorithm, options, strutils]

import ./frame



#[ Concepts ]#

type
  Helper* {.pure.} = enum ## Name primitive way one frame becomes another.
    Collect,              ## Form connection with free hand.
    Drop                  ## Break connection, releasing hand.

  Compound* {.pure.} = enum ## Name pair of primitives dance calls one move.
    Place,                  ## Hand one connection over to other lead hand.
    Cut                     ## Re-route arm around arm in its way.

  Move* = object ## Hold one primitive change of frame.
    helper*: Helper ## Primitive that carries change.
    side*: Side     ## Lead hand that acts: receiver for pass, arm that ends on
                    ## top for cut.
    to*: Frame      ## Frame couple arrives in.


const HELPER_CHANGES*: array[Helper, string] = [
  Helper.Collect: "a free hand takes a hand",
  Helper.Drop: "a held hand is released",
] ## Say what each primitive changes about frame.


const HELPER_SYNONYMS*: array[Helper, string] = [
  Helper.Collect: "",
  Helper.Drop: "flick when led with momentum",
] ## Give workbook's other word for primitive, where it has one.


const HELPER_MARKS*: array[Helper, char] = [
  Helper.Collect: 'c',
  Helper.Drop: 'd',
] ## Abbreviate each primitive to one letter printed cell has room for.
  ##
  ## For `doc/review.html`, which is document and sets its matrix as table.
  ## App draws its own matrix and points move instead, because drawing has
  ## direction to spend where printed page has only letter.


const COMPOUND_CHANGES*: array[Compound, string] = [
  Compound.Place: "one hand of the follow changes which lead hand holds it",
  Compound.Cut: "the arms exchange which one lies on top",
] ## Say what each compound changes about frame.


const COMPOUND_ORDERS*: array[Compound, string] = [
  Compound.Place: "collect, then drop",
  Compound.Cut: "drop, then collect",
] ## Give order workbook writes each compound in.


const COMPOUND_OBSTRUCTED*: array[Compound, bool] = [
  Compound.Place: false,
  Compound.Cut: true,
] ## Say whether other arm lies in path trace has to take.


const COMPOUND_MARKS*: array[Compound, char] = [
  Compound.Place: 'p',
  Compound.Cut: 'x',
] ## Abbreviate each compound for printed matrix cell, as `HELPER_MARKS` does.
  ##
  ## `cut` takes letter it does because `collect` has one it would want.


func name*(helper: Helper): string = ($helper).toLowerAscii
  ## Name primitive as ontology writes it.


func manner*(helper: Helper): string =
  ## Name primitive together with workbook's other word for it.
  if HELPER_SYNONYMS[helper].len == 0:
    helper.name
  else:
    helper.name & ", or " & HELPER_SYNONYMS[helper]


func inverse*(helper: Helper): Helper =
  ## Get primitive that undoes this one.
  case helper
  of Helper.Collect: Helper.Drop
  of Helper.Drop: Helper.Collect



#[ Classification ]#

func classify*(a, b: Frame): Option[Helper] =
  ## Get primitive taking one frame to another, where single one does.
  if a == b or not a.isValid or not b.isValid:
    return none(Helper)
  let
    moved_left = a.hold[Side.Left] != b.hold[Side.Left]
    moved_right = a.hold[Side.Right] != b.hold[Side.Right]
  if not moved_left and not moved_right:
    # Same connections, so only arm order differs, which is `cut`: arm
    # underneath has to be released and re-taken over other one.
    return none(Helper)
  if moved_left != moved_right:
    let side = if moved_left: Side.Left else: Side.Right
    if a.hold[side].isNone:
      return some(Helper.Collect)
    if b.hold[side].isNone:
      return some(Helper.Drop)
    # One hand has moved from one hand of follow to other, which is trace
    # with nothing to trace along: space between follow's hands is empty
    # air.  It becomes move once arms and body are places to hold.
    return none(Helper)
  none(Helper)


func compound*(a, b: Frame): Option[Compound] =
  ## Get compound joining two frames, where ontology names one.
  ##   Both are two primitives with name.
  ##     `place` hands one connection to lead's other hand; `cut` hands one
  ##       arm over other.
  ##   `place` is routed through free frame, letting go and taking again,
  ##     rather than through moment where both hands of lead hold one hand
  ##     of follow.
  ##     That moment is same ambiguity ontology already refuses in
  ##       `Left-to-all`, one hand joined to two things, so it is refused in
  ##       this direction too.
  ##     Lead who keeps contact through hand-off is dancing quality workbook
  ##       means by `"maintaining a connection via a trace"`; frames either
  ##       side of it are same either way.
  if a == b or not a.isValid or not b.isValid:
    return none(Compound)
  if a.hold == b.hold:
    return some(Compound.Cut)
  if a.countHolds != 1 or b.countHolds != 1:
    return none(Compound)
  let
    source = if a.hold[Side.Left].isSome: a.hold[Side.Left] else: a.hold[Side.Right]
    destination = if b.hold[Side.Left].isSome: b.hold[Side.Left] else: b.hold[Side.Right]
  if source == destination:
    return some(Compound.Place)
  none(Compound)


func actingSide*(a, b: Frame): Side =
  ## Get lead hand that carries change of frame.
  ##   Frames alone decide it; caller used to pass primitive too, and it was
  ##     never read.
  if a.hold[Side.Left] != b.hold[Side.Left]: Side.Left else: Side.Right



#[ Moves ]#

func compare(a, b: Move): int =
  ## Order moves by primitive, then by acting hand, for stable display.
  if a.helper != b.helper:
    return cmp(ord(a.helper), ord(b.helper))
  if a.side != b.side:
    return cmp(ord(a.side), ord(b.side))
  cmp(a.to.key, b.to.key)


func moves*(source: Frame): seq[Move] =
  ## Get every frame one primitive away, with primitive that reaches it.
  ##
  ## This is whole answer to "what can we do from here": frame absent from
  ## result is not reachable without intermediate frame.
  for destination in FRAMES:
    let helper = classify(source, destination)
    if helper.isNone:
      continue
    result.add Move(
      helper: helper.get,
      side: actingSide(source, destination),
      to: destination,
    )
  result.sort(compare)


func phrase*(source: Frame; move: Move): string =
  ## Say move as teacher would call it, naming both hands.
  ##
  ## Which dancer each hand belongs to is said by its case and by nothing else:
  ## `collect Right to left` is lead's right hand taking follow's left.
  ## See `leadName`.
  let hand = leadName(move.side)
  case move.helper
  of Helper.Collect:
    result = "collect " & hand & " to " & followName(move.to.hold[move.side].get)
    if move.to.hasOverlap:
      result.add ", " & (if move.to.over.get == move.side: "over" else: "under") &
        " the " & leadName(other(move.side)) & " arm"
  of Helper.Drop:
    result = "drop " & hand & " from " & followName(source.hold[move.side].get)


func compoundSide*(source, destination: Frame): Option[Side] =
  ## Get hand of lead that moves when compound is led.
  ##
  ## For `cut` it is arm that ends up on top, because that is one that let go
  ## and came back over other.  For `place` it is hand that ends up holding,
  ## because that is one that took what other let go of.
  let named = compound(source, destination)
  if named.isNone:
    return none(Side)
  case named.get
  of Compound.Cut: destination.over
  of Compound.Place:
    some(if destination.hold[Side.Left].isSome: Side.Left else: Side.Right)


func compoundName*(source, destination: Frame): string =
  ## Name compound and hand of follow it moves, as `label` names move.
  let
    named = compound(source, destination)
    side = compoundSide(source, destination)
  if named.isNone or side.isNone:
    return ""
  ($named.get).toLowerAscii & " " & followName(destination.hold[side.get].get)


func compoundWay*(source, destination: Frame): seq[Move] =
  ## Get two moves compound is led as, in order lead leads them.
  ##
  ## Not `route`, which takes any shortest path and takes first one it finds.
  ## `cut` has two of those -- either arm can let go and come back over other
  ## -- and only one of them is one vocabulary means, which is arm that ends
  ## up on top letting go and coming back.  Page that danced `route`'s answer
  ## while printing this one's would be doing one thing and saying another,
  ## which for validator is whole of what it must not do.
  let
    named = compound(source, destination)
    taking = compoundSide(source, destination)
  if named.isNone or taking.isNone:
    return @[]
  # Cut is one arm letting go and coming back on other side of other arm, so
  # same arm does both.  Place is hand passed between two arms, so one that
  # is holding lets go and one that is not takes.
  let leaving =
    case named.get
    of Compound.Cut: taking.get
    of Compound.Place: other(taking.get)
  var away = source
  away.hold[leaving] = none(Site)
  away.over = none(Side)
  if away == source or not away.isValid:
    return @[]
  @[Move(helper: Helper.Drop, side: leaving, to: away),
    Move(helper: Helper.Collect, side: taking.get, to: destination)]


func compoundPhrase*(source, destination: Frame): string =
  ## Say compound as teacher would call it, with every hand named.
  let named = compound(source, destination)
  if named.isNone:
    return ""
  let
    side = compoundSide(source, destination).get
    hand = followName(destination.hold[side].get)
  case named.get
  of Compound.Cut:
    "cut " & hand & ": drop " & leadName(side) & ", then collect it back over " &
      "the " & leadName(other(side)) & " arm"
  of Compound.Place:
    "place " & hand & " from " & leadName(other(side)) & " into " &
      leadName(side)


func label*(source: Frame; move: Move): seq[string] =
  ## Name move in fewest words that still say what to do, line by line.
  ##   `collect` has to say which hand of follow it takes, because same hand
  ##     of lead can reach either, and it has to say over or under where both
  ##     arms cross, because that is whole difference between two frames it
  ##     could arrive in.
  ##   `drop` says which hand it lets go of, for same reason read other way
  ##     round.
  ##     It used to say only `drop`, on grounds that hand which acts is
  ##       already holding one thing, so nothing is left to choose.  True of
  ##       *lead's* hand and beside point: reader looking at drawing cannot
  ##       see which of lead's hands acts except by reading ink, so bare
  ##       `drop` left them to work out what was being released.  Now every
  ##       label names hand, and `collect left` and `drop left` are two
  ##       directions of one line.
  ##   Hand named is follow's, and is said to be by its case alone: `left` is
  ##     follow's where `Left` would be lead's, throughout ontology.
  ##     Which hand of *lead* acts is left to ink words are written in, which
  ##       is what drawing has that sentence does not.
  ##   Lines are short so that words fit where drawing has room for them,
  ##     which is usually beside line rather than along it.
  case move.helper
  of Helper.Collect:
    result = @["collect " & followName(move.to.hold[move.side].get)]
    if move.to.hasOverlap:
      result.add(if move.to.over.get == move.side: "over" else: "under")
  of Helper.Drop:
    # Frame being left is where hold still exists, which is why this reads
    # `source` where collect reads `to`.
    result = @["drop " & followName(source.hold[move.side].get)]



#[ Routes ]#

func route*(source, destination: Frame): seq[Move] =
  ## Get shortest sequence of primitives joining two frames, if one exists.
  ##
  ## Workbook records compound cells such as `place, collect`; route of
  ## length greater than one is same thing, derived instead of written down.
  if source == destination or source.frameIndex.isNone or
      destination.frameIndex.isNone:
    return @[]
  let home = source.frameIndex.get
  var
    reached = newSeq[bool](FRAMES.len)
    arrival = newSeq[Move](FRAMES.len)
    origin = newSeq[int](FRAMES.len)
    queue = @[home]
  reached[home] = true
  var head = 0
  while head < queue.len:
    let current = queue[head]
    inc head
    for move in moves(FRAMES[current]):
      # Move's destination is always valid frame, so absence here is internal
      # impossibility and unwrap is assertion.
      let next = move.to.frameIndex.get
      if reached[next]:
        continue
      reached[next] = true
      arrival[next] = move
      origin[next] = current
      if move.to == destination:
        var step = next
        while step != home:
          result.insert(arrival[step], 0)
          step = origin[step]
        return result
      queue.add next
  @[]
