## Ask body sim for every hold turning, and write it down for whole-cloth page.
##
##   Whole-cloth page animates hold turning, and only honest way to animate two
##     bodies and their arms is to ask thing that models them.  Engine is C and
##     page is script in browser, so this program runs sim natively and writes
##     every moment of every sweep as data; page only draws.  Nothing about
##     physics is guessed on page: where each joint is, which way arm lies, and
##     where turn runs out are all read from here.
##   Written to `design/turns.json` by its own verb, as `modelled` and `rig` are,
##     and folded into page by `pages`.  Couple stand for turn, so each sweep
##     searches every distance they may stand at, and eighteen of them cost more
##     than every `pages` run should pay.
##   Words (wrap, lock, low, high) are put on here, as `sim/verdicts` does.  Not
##     because sim speaks other language -- it reuses agreed words -- but because
##     here it measures what ontology asserts, and translation kept visible is
##     evidence where assumed identity is echo.
##   Two rests, both page's own choice: cross-name holds rest face to face, and
##     same-name holds are also built face to face so turns count as sheet
##     counts.  Same-name *pair* is exception: face to face its two connections
##     lie through each other, so it is built pillion lead -- collected there, as
##     couple would -- and its turns count from it.
##   Two ways of one sweep stand where each of them wants, so frame at nought
##     turns is reached from two stances and page shows step between them.  That
##     is what model says, not smoothing to hide.

{.experimental: "strictFuncs".}

import std/[json, math, options, strutils]

import ../sim/[body, hold, limb, read, rig, vec, walk]


const
  HOLDS = ["L-l", "R-r", "L-r", "R-l", "L-l.R-r", "L-r.R-l"]
  BANDS = [("low", Band.Torso), ("high", Band.Neck), ("above", Band.Crown)]


func armsOf(hold: string): seq[(Arm, Arm)] =
  ## Read "L-l" or "L-r.R-l": lead's hand in capitals, follow's in lower case.
  for part in hold.split('.'):
    let
      a = if part[0] == 'L': Arm.Left else: Arm.Right
      b = if part[2] == 'l': Arm.Left else: Arm.Right
    result.add (a, b)

func sameName(hold: string): bool =
  for (a, b) in armsOf(hold):
    if a != b: return false
  true

func linksOf(hold: string): seq[Link] =
  for (a, b) in armsOf(hold):
    result.add Link(ends: [(Body.One, a), (Body.Two, b)])

func restsAway(hold: string): bool =
  ## Same-name pair is built pillion lead; every other hold face to face.
  hold.contains('.') and sameName(hold)


func said(lying: Option[Lying]; band: Band): string =
  ## Write where held arm lies, in sheet's words -- only translation.
  if band == Band.Crown:
    return "above"
  if lying.isNone:
    return "open"
  let
    way = if lying.get.aspect == Aspect.Fore: "wrap" else: "lock"
    at = if lying.get.band == Band.Torso: "low" else: "high"
    held = if lying.get.pressing: "" else: " (led)"
  way & " " & at & held

func dofName(dof: Dof): string =
  case dof
  of Dof.Extend: "shoulder, behind"
  of Dof.Across: "shoulder, across"
  of Dof.Twist: "shoulder, twist"
  of Dof.Bend: "elbow"
  of Dof.Wrist: "wrist"

func whose(h: Hand): string =
  if h.body == Body.One: "his" else: "her"

func why(w: Walk): string =
  ## Say what refuses, in few words that page can show.
  if not w.stopped: return "no block"
  case w.why
  of Stop.None: "holds"
  of Stop.Reach: whose(w.whose) & " reach"
  of Stop.Twist: whose(w.whose) & " shoulder, twist"
  of Stop.Elbow: whose(w.whose) & " elbow"
  of Stop.Wrist: whose(w.whose) & " wrist"
  of Stop.Swing: whose(w.whose) & " shoulder, swing"
  of Stop.Through: whose(w.whose) & " arm through body"
  of Stop.Arms: "arm through arm"


func mm(p: Vec): JsonNode =
  %*[int(round(p.x * 1000.0)), int(round(p.y * 1000.0)), int(round(p.z * 1000.0))]

func frame(m: Moment; band: Band; links: seq[Link]): JsonNode =
  let tight = tightest(HUMAN, m.stance, links, m.arms)
  result = %*{
    "t": round(m.at * 1000.0) / 1000.0,
    "ok": true,
    "reseed": false,
    "strain": round(tight.strain * 100.0) / 100.0,
    "worst": (if links.len == 0: "" else: whose(tight.whose) & " " & dofName(tight.dof)),
    "bodies": [
      {"c": [int(round(m.stance[Body.One].centre.x * 1000.0)),
             int(round(m.stance[Body.One].centre.y * 1000.0))],
       "f": round(m.stance[Body.One].facing * 1000.0) / 1000.0},
      {"c": [int(round(m.stance[Body.Two].centre.x * 1000.0)),
             int(round(m.stance[Body.Two].centre.y * 1000.0))],
       "f": round(m.stance[Body.Two].facing * 1000.0) / 1000.0}],
    "cn": []}
  let cross = crossings(m.arms)
  for i in 0 ..< links.len:
    let
      him = m.arms[i][armOf(links, i, Body.One)]
      her = m.arms[i][armOf(links, i, Body.Two)]
    var cj = %*{
      "him": [mm(him.s), mm(him.e), mm(him.w), mm(him.g)],
      "her": [mm(her.g), mm(her.w), mm(her.e), mm(her.s)],
      "himSays": said(lyingOn(HUMAN, band, links, m.stance, m.arms, i, Body.One), band),
      "herSays": said(lyingOn(HUMAN, band, links, m.stance, m.arms, i, Body.Two), band)}
    if i == 0 and cross.len > 0:
      var overs = newJArray()
      for c in cross:
        overs.add %*{"at": [int(round(c.at.x * 1000.0)), int(round(c.at.y * 1000.0))],
                     "over": c.over}
      cj["cross"] = overs
    result["cn"].add cj


func frames(sw: Swept; band: Band; links: seq[Link]): JsonNode =
  ## Every moment of both ways, in order of turn, rest once.
  ##   Negative way was walked outward from rest, so it is read back to front.
  result = newJArray()
  for i in countdown(sw.neg.moments.high, 1):
    result.add frame(sw.neg.moments[i], band, links)
  for m in sw.pos.moments:
    result.add frame(m, band, links)

func went(w: Walk): float =
  ## How far one way got: where it stopped, else as far as it was walked.
  ##   `Walk.at` is set only where something gave.  Page reads this as edge of
  ##     what it may draw, so free way written as nought would be drawn not at
  ##     all; old solver wrote `MOST` there and page still expects that.
  if w.stopped: w.at
  elif w.moments.len > 0: abs(w.moments[^1].at)
  else: 0.0

proc sweepJson(hold, word: string; band: Band): JsonNode =
  let
    links = linksOf(hold)
    sw = swept(HUMAN, band, links, most = MOST, away = restsAway(hold))
  result = %*{
    "restHolds": sw.restHolds,
    "neg": round(went(sw.neg) * 1000.0) / 1000.0,
    "pos": round(went(sw.pos) * 1000.0) / 1000.0,
    "stoppedNeg": sw.neg.stopped,
    "stoppedPos": sw.pos.stopped,
    "whyNeg": why(sw.neg),
    "why": why(sw.pos),
    "foundNeg": false,
    "foundPos": false,
    "apartNeg": round(sw.neg.apart * 1000.0) / 1000.0,
    "apartPos": round(sw.pos.apart * 1000.0) / 1000.0,
    "frames": (if sw.restHolds: frames(sw, band, links) else: newJArray())}
  stderr.writeLine hold & " " & word & ": -" & $went(sw.neg) & " +" & $went(sw.pos) &
    " (" & $(sw.neg.moments.len + sw.pos.moments.len) & " moments)"


proc bridge(): JsonNode =
  result = %*{
    "step": STEP,
    "most": MOST,
    "rig": {
      "torsoAcross": int(round(halfBreadth(HUMAN, Part.Torso) * 1000.0)),
      "torsoDeep": int(round(halfDepth(HUMAN, Part.Torso) * 1000.0)),
      "neck": int(round(halfBreadth(HUMAN, Part.Neck) * 1000.0)),
      "head": int(round(halfBreadth(HUMAN, Part.Head) * 1000.0)),
      "shoulder": int(round(HUMAN.shoulderOut * 1000.0)),
      "limb": int(round(HUMAN.limb * 1000.0)),
      "z": {"hip": int(round(HUMAN.hip * 1000.0)),
            "torso": int(round(HUMAN.top[Part.Torso] * 1000.0)),
            "neck": int(round(HUMAN.top[Part.Neck] * 1000.0)),
            "head": int(round(HUMAN.top[Part.Head] * 1000.0)),
            "shoulder": int(round(HUMAN.shoulderUp * 1000.0))}},
    "sweeps": {}}
  for hold in HOLDS:
    for (word, band) in BANDS:
      result["sweeps"][hold & "|" & word] = sweepJson(hold, word, band)


when isMainModule:
  writeFile("design/turns.json", pretty(bridge()) & "\n")
  echo "wrote design/turns.json"
