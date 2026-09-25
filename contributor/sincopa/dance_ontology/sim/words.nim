## Translate what sim reads into words dance agreed.
##
##   Sim names what it measures for body: torso band, fore aspect, elbow
##     forward.  Dance names same readings low, wrap and elbow forward.  This
##     module is only place where one becomes other.
##   Report (`verdicts`) and page data (`turns`) both once carried own copy of
##     this table, deliberately, so translation stayed visible in each.  Two
##     copies drifted: report named elbow folded forward and page did not, so
##     one pose carried two answers, and reader comparing page against report
##     met disagreement that neither file admitted.
##     Cost of one table: module sits under `sim`, which otherwise puts no
##       word of dance on anything it measures.  Accepted -- translation is
##       still visible, in one file that names itself, and evidence is that
##       both readers quote same table rather than that each writes one.
##   Words are `GLOSSARY.md`'s, and `tests/suites/tglossary` holds every string here
##     to it.
##
##   |---------------------------|------------------|
##   | Sim reads                 | Dance says       |
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
##   |---------------------------|------------------|

{.experimental: "strictFuncs".}

import std/options

import ./[body, hold, read, rig, walk]


const BANDS* = [("low", Band.Torso), ("high", Band.Neck), ("above", Band.Crown)]
  ## Name each band, in order report and page tabulate them.


func bandName*(band: Band): string =
  ## Name band as dance names height arm is carried at.
  for (word, which) in BANDS:
    if which == band:
      return word
  raise newException(Defect, "No word names band; got `" & $band & "`.")


func whose*(h: Hand): string =
  ## Name dancer whose arm reading is about.
  if h.body == Body.One: "lead's" else: "follow's"


func said*(lying: Option[Lying]; band: Band): string =
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
    held = if lying.get.pressing: "" else: " (led)"
    elbow =
      if lying.get.elbowFore and lying.get.aspect == Aspect.Aft: ", elbow forward" else: ""
  way & " " & at & held & elbow


func dofName*(dof: Dof): string =
  ## Name freedom that ran out, joint first.
  case dof
  of Dof.Extend: "shoulder, behind"
  of Dof.Across: "shoulder, across"
  of Dof.Twist: "shoulder, twist"
  of Dof.Bend: "elbow"
  of Dof.Wrist: "wrist"


func why*(w: Walk): string =
  ## Say what refuses, in few words that table cell or page can show.
  ##   Short register.  `hold.says` answers same question in whole sentence,
  ##     for viewer that has room for one.
  if not w.stopped: return "no block"
  case w.why
  of Stop.None: "holds"
  of Stop.Reach: whose(w.whose) & " reach"
  of Stop.Twist: whose(w.whose) & " shoulder, twist"
  of Stop.Elbow: whose(w.whose) & " elbow"
  of Stop.Wrist: whose(w.whose) & " wrist"
  of Stop.Swing: whose(w.whose) & " shoulder, swing"
  of Stop.Through: whose(w.whose) & " arm through a body"
  of Stop.Arms: "arm through arm"
