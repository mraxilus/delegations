## Translate what simulation reads into words dance agreed.
##
##   Simulation names what it measures for body: torso band, fore aspect, elbow
##     forward.  Dance names same readings low, wrap and elbow forward.  This
##     module is only place where one becomes other.
##   Report (`verdicts`) and laws (`test_asks`, `test_words`) read this one table.
##     Rejected: copy in each, which can drift until one pose carries two answers.
##     Cost: module sits under `simulation`, which otherwise puts no word of dance on anything it
##       measures.  Accepted: translation stays visible, in one file that names itself.
##   Words are `GLOSSARY.md`'s, and `tests/suites/test_glossary` holds every string here
##     to it.
##
##   |---------------------------|------------------|
##   | Simulation reads          | Dance says       |
##   |---------------------------|------------------|
##   | Band.Torso                | low              |
##   | Band.Neck                 | high             |
##   | Band.Crown                | above            |
##   | Aspect.Fore               | wrap             |
##   | Aspect.Aft                | lock             |
##   | no reading at all         | open             |
##   | not pressing              | (led)            |
##   | elbow fore, aspect aft    | , elbow forward  |
##   | Body.One                  | lead's           |
##   | Body.Two                  | follow's         |
##   | quarters each sees other  | facing           |
##   |---------------------------|------------------|

{.experimental: "strictFuncs".}

import std/[options, strutils]

import ./[body, hold, read, rig, walk]


const BANDS* = [("low", Band.Torso), ("high", Band.Neck), ("above", Band.Crown)]
  ## Name each band, in order report tabulates them.

const SIDES = ["Face", "Starboard", "Back", "Port"]
  ## Name side each dancer turns to other, by quarters clockwise from own front
  ## at which they see other (`body.quartersTo`).
  ##   Port and starboard name sides of body, so facing never reads as hold.

const FACINGS* =
  block:
    var each: array[16, ((int, int), string)]
    for by_lead in 0..3:
      for by_follow in 0..3:
        each[by_lead*4+by_follow] = ((by_lead, by_follow),
          SIDES[by_lead] & "-to-" & SIDES[by_follow].toLowerAscii)
    each
  ## Name each state two stand in to one another: where lead sees follow, then
  ## where follow sees lead.  Name gives lead's side, then follow's, as
  ## glossary does, such as `Face-to-port`.


func bandName*(band: Band): string =
  ## Name band as dance names height arm is carried at.
  for (word, which) in BANDS:
    if which == band:
      return word
  raise newException(Defect, "No word names band; got `" & $band & "`.")


func facingName*(stance: array[Body, Stance]): Option[string] =
  ## Name state two stand in to one another, as dance names it (`FACINGS`).
  ##   None between quarters, where body sees other at no one side.
  let (lead, follow) = (quartersTo(stance, Body.One), quartersTo(stance, Body.Two))
  if lead.isSome and follow.isSome:
    for (seen, name) in FACINGS:
      if seen == (lead.get, follow.get):
        return some(name)
  none(string)


func whose(hand: Hand): string =
  ## Name dancer whose arm reading is about.
  if hand.body == Body.One: "lead's" else: "follow's"


func said*(lying: Option[Lying], band: Band): string =
  ## Write where held arm lies, in words dance uses.
  ##   Arm over head is on axis couple turn about, so it winds round nothing
  ##     and carries no modifier: band alone answers.
  ##   Elbow forward is named only behind back, where it is what lets arm
  ##     reach at all, and where drawing cannot show it.
  if band == Band.Crown:
    return bandName(band)
  if lying.isNone:
    return "open"
  let
    way = if lying.get.aspect == Aspect.Fore: "wrap" else: "lock"
    at = bandName(lying.get.band)
    held = if lying.get.is_pressing: "" else: " (led)"
    elbow =
      if lying.get.is_elbow_fore and lying.get.aspect == Aspect.Aft: ", elbow forward" else: ""
  way & " " & at & held & elbow


func why*(walk: Walk): string =
  ## Say what refuses, in few words that table cell or page can show.
  ##   Short register.  `hold.says` answers same question in whole sentence,
  ##     for viewer that has room for one.
  if not walk.is_stopped: return "no block"
  case walk.why
  of Stop.None: "holds"
  of Stop.Span: whose(walk.whose.get) & " span"
  of Stop.Twist: whose(walk.whose.get) & " shoulder, twist"
  of Stop.Elbow: whose(walk.whose.get) & " elbow"
  of Stop.Wrist: whose(walk.whose.get) & " wrist"
  of Stop.Swing: whose(walk.whose.get) & " shoulder, swing"
  of Stop.Through: whose(walk.whose.get) & " arm through a body"
  of Stop.Arms: "arm through arm"
  of Stop.Crossed: "arms cross above elbow"
  of Stop.Band: whose(walk.whose.get) & " hand off band"
