## Model frame two dancers hold, and name it in vocabulary of dance.
##
## *Frame* is everything two bodies hold at one instant: which hand of lead
## holds which hand of follow, and how arms lie where they overlap.
##   It is state of ontology.
##   Every non-rotating move is change of frame, and every change is derived
##     from three physical facts:
##     Hand holds at most one hand, and hand of follow is held by at most one
##       hand of lead.
##     Partners face each other, so lead hand reaches *opposite* hand of
##       follow without crossing midline between bodies, and *same-named*
##       hand only by crossing it.
##     When both connections cross, forearms overlap, so one arm lies over
##       other and which one is part of state, not decoration.
##       Third fact is why `Left-to-left and Right-to-right` has over/under
##         distinction and `Left-to-right and Right-to-left` does not: only
##         first pair crosses.
##       Cost of recording arm order in state: two crossing orders are two
##         frames one `cut` apart, so reader asking for *position* must strip
##         order -- see `position`.  Accepted -- merging them would offer
##         move arms forbid.
##
## Only hands connect here.
##   Hand resting on partner's body is real and is deliberately absent:
##     nothing in hand-to-hand ontology depends on it, and where it does
##     matter is in stopping turn, so it belongs with rotation axis in
##     `rotation.nim`.
##   Cost of leaving body contact out: workbook's `closed` and `half-closed`
##     states have no frame here, so `workbook.nim` defers them unchecked.
##     Accepted -- audit reports deferral rather than hiding it.

{.experimental: "strictFuncs".}

import std/options



#[ Concepts ]#

type
  Side* {.pure.} = enum ## Name side of body, and so one hand of lead.
    Left, Right

  Site* {.pure.} = enum ## Name hand of follow that one lead hand can hold.
    LeftHand, RightHand

  Frame* = object ## Hold every connection between two bodies at one instant.
    hold*: array[Side, Option[Site]] ## Hand each lead hand holds, where it holds one.
    over*: Option[Side]              ## Lead arm lying over other, where they overlap.


const SITE_OPTIONS = [
  none(Site),
  some(Site.LeftHand),
  some(Site.RightHand),
]


const OVER_OPTIONS = [
  none(Side),
  some(Side.Left),
  some(Side.Right),
]



#[ Geometry Facing Partners ]#

func parallelSite*(side: Side): Site =
  ## Get follow hand this lead hand reaches without crossing midline.
  case side
  of Side.Left: Site.RightHand
  of Side.Right: Site.LeftHand


func crossedSite*(side: Side): Site =
  ## Get follow hand this lead hand reaches only by crossing midline.
  case side
  of Side.Left: Site.LeftHand
  of Side.Right: Site.RightHand


func isCrossed*(side: Side; site: Site): bool = site == crossedSite(side)
  ## Test whether connection crosses midline between bodies.


func other*(side: Side): Side =
  ## Get opposite side of same body.
  case side
  of Side.Left: Side.Right
  of Side.Right: Side.Left


func hasOverlap*(frame: Frame): bool =
  ## Test whether both forearms cross midline and so lie on top of each other.
  frame.hold[Side.Left] == some(crossedSite(Side.Left)) and
    frame.hold[Side.Right] == some(crossedSite(Side.Right))



#[ Laws ]#

func countHolds*(frame: Frame): int =
  ## Count connections frame carries.
  for side in Side:
    if frame.hold[side].isSome:
      inc result


func usesHand*(frame: Frame; side: Side): bool = frame.hold[side].isSome
  ## Test whether one hand of lead is holding anything.


func holder*(frame: Frame; site: Site): Option[Side] =
  ## Get which hand of lead holds this hand of follow, if either does.
  for side in Side:
    if frame.hold[side] == some(site):
      return some(side)
  none(Side)


func isHeld*(frame: Frame; site: Site): bool = frame.holder(site).isSome
  ## Test whether one hand of follow is held.


func isValid*(frame: Frame): bool =
  ## Test two laws every frame obeys.
  ##   No hand is shared.
  ##     One hand of follow cannot be held by both hands of lead, and
  ##       ontology leaves out `Left-to-all` for mirrored reason: hand
  ##       joined to two things is ambiguous lead.
  ##     It is what makes state space finite.
  ##     Law is what sends hand-off through free frame rather than through
  ##       moment where two hands hold one.
  ##   Arm order is recorded exactly where forearms overlap.
  ##     So two frames that dancer cannot tell apart cannot be different
  ##       values.
  if frame.hold[Side.Left].isSome and frame.hold[Side.Left] == frame.hold[Side.Right]:
    return false
  frame.over.isSome == frame.hasOverlap


func reflect*(frame: Frame): Frame =
  ## Mirror frame through plane between bodies, swapping left and right.
  ##
  ## Reflection is symmetry of physics, so whole ontology is invariant under
  ## it.  Anywhere it is not, asymmetry has come from idiom rather than from
  ## bodies.
  for side in Side:
    result.hold[other(side)] =
      if frame.hold[side].isNone:
        none(Site)
      else:
        case frame.hold[side].get
        of Site.LeftHand: some(Site.RightHand)
        of Site.RightHand: some(Site.LeftHand)
  result.over =
    if frame.over.isNone: none(Side) else: some(other(frame.over.get))



#[ Enumeration ]#

func constructFrames(): seq[Frame] {.compileTime.} =
  ## Enumerate every valid frame, ordered by lead's left hand then right.
  for left in SITE_OPTIONS:
    for right in SITE_OPTIONS:
      for over in OVER_OPTIONS:
        var frame = Frame(over: over)
        frame.hold[Side.Left] = left
        frame.hold[Side.Right] = right
        if frame.isValid:
          result.add frame


const FRAMES* = constructFrames()
  ## Hold every frame two facing humanoid bodies can take hand to hand.


func frameIndex*(frame: Frame): Option[int] =
  ## Get position of frame in `FRAMES`, where frame is valid.
  ##   Absence is typed rather than in-range: invalid frame has no position,
  ##     not position of -1 that reader must know to test for.
  for index, candidate in FRAMES:
    if candidate == frame:
      return some index
  none(int)



#[ Naming ]#

func leadName*(side: Side): string =
  ## Name hand of lead, capitalised as ontology writes it.
  ##
  ## Case is whole of how two dancers are told apart in this vocabulary:
  ## `Left` is lead's and `left` is follow's, in frame's name and in move's
  ## alike.  So nothing anywhere needs to say *whose* hand it means, and
  ## nothing should: name that said it would be repeating what its own first
  ## letter has already said.
  case side
  of Side.Left: "Left"
  of Side.Right: "Right"


func followName*(site: Site): string =
  ## Name hand of follow, in lower case as ontology writes it.
  ##
  ## Lower case is what marks it as follow's; see `leadName`.
  case site
  of Site.LeftHand: "left"
  of Site.RightHand: "right"


func describeConnection*(side: Side; site: Site; joiner = "-to-"): string =
  ## Name one connection, as `Left-to-left` or `Left to left`.
  leadName(side) & joiner & followName(site)


func briefName*(side: Side): string = leadName(side)[0 .. 0]
  ## Abbreviate hand of lead to one letter that says which.


func briefName*(site: Site): string = followName(site)[0 .. 0]
  ## Abbreviate hand of follow to one letter that says which.


# At most one of two hands is ever filled, and which one is whole of what
# drawing needs to know to ink word: model's own two types are what keep
# dancers' hands apart, so they are what this hands back rather than one
# side and flag beside it.
type Named* = tuple ## One stretch of name, and hand it names.
  text: string         ## Letters, as they were written.
  lead: Option[Side]   ## Lead's hand, where this stretch names one.
  follow: Option[Site] ## Follow's hand, where this stretch names one.


func named*(said: string): seq[Named] =
  ## Break name into stretches, marking each word that names hand.
  ##
  ## Case is whole of what says whose hand word means -- `Left` is lead's
  ## where `left` is follow's, throughout ontology -- so name can be *read*
  ## for its hands rather than carrying them alongside as second thing to
  ## keep in step.  `collect Left to left` says which two hands it joins in
  ## letters it is already made of.
  ##   Which is why this takes finished name rather than being folded into
  ##     naming: `phrase`, `label` and `compoundName` all spell hands one
  ##     way, and reader of any of them can be told apart same way.
  ##   Words are stretches of letters; everything else -- spaces, commas,
  ##     hyphens in `Left-to-left` -- rides along with words it sits between,
  ##     so name comes back in order it was written and joins back into
  ##     itself exactly.
  var
    plain = ""
    word = ""

  func hand(word: string): Named =
    ## Read one word as hand, where it is one.
    ##   Abbreviations count as much as words.  `brief` shortens name to its
    ##     letters precisely because letter has case and so says whose hand
    ##     it is on its own, and `L to l` in matrix's margin is same sentence
    ##     as `Left to left` in drawing.
    ##   `L` and `l` are only one-letter words this vocabulary has, so
    ##     nothing else can be caught by reading them.
    for side in Side:
      if word == leadName(side) or word == briefName(side):
        return ("", some side, none(Site))
    for site in Site:
      if word == followName(site) or word == briefName(site):
        return ("", none(Side), some site)
    ("", none(Side), none(Site))

  func flush(text: string): seq[Named] =
    if text.len > 0: @[(text, none(Side), none(Site))] else: @[]

  for character in said & " ":
    if character in {'a'..'z', 'A'..'Z'}:
      word.add character
      continue
    let read = hand(word)
    if read.lead.isSome or read.follow.isSome:
      result.add flush(plain)
      result.add (word, read.lead, read.follow)
      plain = ""
    else:
      plain.add word
    plain.add character
    word = ""
  # Trailing space this walked one character past is not part of name.
  plain.setLen(plain.len - 1)
  result.add flush(plain)


func describe*(frame: Frame): string =
  ## Name frame in vocabulary of ontology.
  ##
  ## Frame that holds nothing is `free`, and it was `open` until that name
  ## proved to be taken: dancers call hand-to-hand frame -- one named here
  ## `Left-to-right and Right-to-left` -- open position.  Reader who knows
  ## dance would meet `open` on picture with no connection in it at all and
  ## read it as one with two.  `free` is what frame already is, and says so
  ## in word this vocabulary already uses for hand nobody holds: it is frame
  ## where all four of them are.
  case frame.countHolds
  of 0:
    "free"
  of 1:
    let side = if frame.hold[Side.Left].isSome: Side.Left else: Side.Right
    describeConnection(side, frame.hold[side].get, " to ")
  else:
    let first = if frame.over.isSome: frame.over.get else: Side.Left
    let joiner = if frame.over.isSome: " over " else: " and "
    describeConnection(first, frame.hold[first].get) & joiner &
      describeConnection(other(first), frame.hold[other(first)].get)


func brief*(frame: Frame): string =
  ## Name frame in as few letters as still say which frame it is.
  ##   `Left-to-left over Right-to-right` is name, and where name will not
  ##     fit -- down side of matrix, across top of it -- choice is between
  ##     abbreviating it and wrapping it over three lines.
  ##     Wrapped, reader has to parse paragraph per axis; abbreviated,
  ##       `L-to-l over R-to-r` is read in one glance.
  ##   Nothing is lost, because hand's case is whole of what says whose it
  ##     is and letter has case: `L` is lead's where `l` is follow's, exactly
  ##     as words are.  See `leadName`.
  ##   Frame that holds nothing is not abbreviated: `free` is already as
  ##     short as shortest of these, so there is nothing to take out of it.
  ##     It must still be repeated here rather than deferred to `describe`,
  ##     which is trap in this pair -- two names are only same by agreeing,
  ##     and nothing but this note says they must.
  case frame.countHolds
  of 0:
    "free"
  of 1:
    let side = if frame.hold[Side.Left].isSome: Side.Left else: Side.Right
    briefName(side) & " to " & briefName(frame.hold[side].get)
  else:
    let first = if frame.over.isSome: frame.over.get else: Side.Left
    let joiner = if frame.over.isSome: " over " else: " and "
    briefName(first) & "-to-" & briefName(frame.hold[first].get) & joiner &
      briefName(other(first)) & "-to-" & briefName(frame.hold[other(first)].get)


func position*(frame: Frame): string =
  ## Name frame position: which hands hold what, without order of arms.
  ##
  ## Workbook asks whether two crossing orders are one position or two.
  ## They are one position and two states.  No couple can pass between them
  ## without `cut`, so machine that merged them would offer move arms forbid;
  ## naming scheme that separated them would report new position every time
  ## arm changed height.  Keeping both readings costs one function.
  var plain = frame
  plain.over = none(Side)
  plain.describe


func key*(frame: Frame): string =
  ## Encode frame as short stable identifier for storage and markup.
  for side in Side:
    result.add(
      if frame.hold[side].isNone:
        '-'
      else:
        case frame.hold[side].get
        of Site.LeftHand: 'l'
        of Site.RightHand: 'r'
    )
  result.add(
    if frame.over.isNone: '.'
    elif frame.over.get == Side.Left: 'L'
    else: 'R'
  )


func slug*(frame: Frame): string =
  ## Form file-safe name for frame, from name it is described by.
  for character in frame.describe:
    if character in {'a'..'z', '0'..'9'}:
      result.add character
    elif character in {'A'..'Z'}:
      result.add chr(ord(character) + 32)
    elif result.len > 0 and result[^1] != '-':
      result.add '-'


func fromKey*(key: string): Option[Frame] =
  ## Decode frame identifier, rejecting anything that is not valid frame.
  if key.len != 3:
    return none(Frame)
  var frame = Frame()
  for index, side in [Side.Left, Side.Right]:
    frame.hold[side] =
      case key[index]
      of '-': none(Site)
      of 'l': some(Site.LeftHand)
      of 'r': some(Site.RightHand)
      else: return none(Frame)
  frame.over =
    case key[2]
    of '.': none(Side)
    of 'L': some(Side.Left)
    of 'R': some(Side.Right)
    else: return none(Frame)
  if frame.isValid: some(frame) else: none(Frame)
