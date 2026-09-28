## Ask body simulation for every hold turning, and write it down for whole-cloth page.
##
##   Whole-cloth page animates hold turning, and only honest way to animate two
##     bodies and their arms is to ask thing that models them.  Engine is C and
##     page is script in browser, so this program runs simulation natively and writes
##     every moment of every sweep as data; page only draws.  Nothing about
##     physics is guessed on page: where each joint is, which way arm lies, and
##     where turn runs out are all read from here.
##   Written to `design/turns.json` by its own verb, as `modelled` and `rig` are,
##     and folded into page by `pages`.  Couple stand for turn, so each sweep
##     searches every distance they may stand at, and eighteen of them cost more
##     than every `pages` run should pay.
##   Words (wrap, lock, low, high) are put on by `simulation/words`, which `verdicts`
##     reads too.  Not because simulation speaks other language -- it reuses agreed
##     words -- but because here it measures what ontology asserts, and
##     translation kept visible is evidence where assumed identity is echo.
##     Table was once written out here and again in `verdicts`, to keep it
##       visible in both.  Two copies drifted instead, so page and report gave
##       one pose two answers; one table, named for itself, is what keeps it
##       visible now.
##   Two rests, both page's own choice: cross-name holds rest face to face, and
##     same-name holds are also built face to face so turns count as sheet
##     counts.  Same-name *pair* is exception: face to face its two connections
##     lie through each other, so it is built Face-to-back -- collected there, as
##     couple would -- and its turns count from it.
##   Two ways of one sweep stand where each of them wants, so frame at nought
##     turns is reached from two stances and page shows step between them.  That
##     is what model says, not smoothing to hide.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/[json, math, options, strutils]

import ../simulation/[body, hold, limb, read, rig, vector, walk, words]


const
  HOLDS = ["L-l", "R-r", "L-r", "R-l", "L-l.R-r", "L-r.R-l"]


func armsOf(hold: string): seq[(Arm, Arm)] =
  ## Read "L-l" or "L-r.R-l": lead's hand in capitals, follow's in lower case.
  for part in hold.split('.'):
    let
      lead_arm = if part[0] == 'L': Arm.Left else: Arm.Right
      follow_arm = if part[2] == 'l': Arm.Left else: Arm.Right
    result.add (lead_arm, follow_arm)

func sameName(hold: string): bool =
  ## Decide whether hold joins each arm to arm of same name.
  for (lead_arm, follow_arm) in armsOf(hold):
    if lead_arm != follow_arm: return false
  true

func linksOf(hold: string): seq[Link] =
  ## List hold's connections, lead's arm to follow's.
  for (lead_arm, follow_arm) in armsOf(hold):
    result.add Link(ends: [(Body.One, lead_arm), (Body.Two, follow_arm)])

func restsAway(hold: string): bool =
  ## Same-name pair is built Face-to-back; every other hold Face-to-face.
  hold.contains('.') and sameName(hold)


func toMillimetres(point: Vector): JsonNode =
  ## Write point in whole millimetres.
  %*[int(round(point.x * 1000.0)), int(round(point.y * 1000.0)), int(round(point.z * 1000.0))]

func frame(moment: Moment; band: Band; links: seq[Link]): JsonNode =
  ## Record one moment as page draws it: arms, words and crossings.
  let tight = tightest(HUMAN, moment.stance, links, moment.arms)
  result = %*{
    "turn": round(moment.at * 1000.0) / 1000.0,
    "ok": true,
    "reseed": false,
    "strain": round(tight.strain * 100.0) / 100.0,
    "worst": (if links.len == 0: "" else: whose(tight.whose) & " " & dofName(tight.dof)),
    "bodies": [
      {"centre": [int(round(moment.stance[Body.One].centre.x * 1000.0)),
             int(round(moment.stance[Body.One].centre.y * 1000.0))],
       "facing": round(moment.stance[Body.One].facing * 1000.0) / 1000.0},
      {"centre": [int(round(moment.stance[Body.Two].centre.x * 1000.0)),
             int(round(moment.stance[Body.Two].centre.y * 1000.0))],
       "facing": round(moment.stance[Body.Two].facing * 1000.0) / 1000.0}],
    "connections": []}
  let cross = crossings(moment.arms)
  for i in 0 ..< links.len:
    let
      lead = moment.arms[i][armOf(links, i, Body.One)]
      follow = moment.arms[i][armOf(links, i, Body.Two)]
    var connection = %*{
      "lead": [toMillimetres(lead.shoulder), toMillimetres(lead.elbow),
               toMillimetres(lead.wrist), toMillimetres(lead.grip)],
      "follow": [toMillimetres(follow.grip), toMillimetres(follow.wrist),
                 toMillimetres(follow.elbow), toMillimetres(follow.shoulder)],
      "leadSays": said(lyingOn(HUMAN, band, links, moment.stance, moment.arms, i, Body.One), band),
      "followSays": said(
        lyingOn(HUMAN, band, links, moment.stance, moment.arms, i, Body.Two),
        band,
      )}
    if i == 0 and cross.len > 0:
      var overs = newJArray()
      for crossing in cross:
        overs.add %*{"at": [int(round(crossing.at.x * 1000.0)), int(round(crossing.at.y * 1000.0))],
                     "over": crossing.over}
      connection["cross"] = overs
    result["connections"].add connection


func frames(sweep: Swept; band: Band; links: seq[Link]): JsonNode =
  ## Every moment of both ways, in order of turn, rest once.
  ##   Negative way was walked outward from rest, so it is read back to front.
  result = newJArray()
  for i in countdown(sweep.negative.moments.high, 1):
    result.add frame(sweep.negative.moments[i], band, links)
  for moment in sweep.positive.moments:
    result.add frame(moment, band, links)

func went(way: Walk): float =
  ## How far one way got: where it stopped, else as far as it was walked.
  ##   `Walk.at` is set only where something gave.  Page reads this as edge of
  ##     what it may draw, so free way written as nought would be drawn not at
  ##     all; old solver wrote `MOST` there and page still expects that.
  if way.stopped: way.at
  elif way.moments.len > 0: abs(way.moments[^1].at)
  else: 0.0

proc sweepJson(hold, word: string; band: Band): JsonNode =
  ## Sweep one hold at one band, and record every moment and where each way ran out.
  let
    links = linksOf(hold)
    sweep = swept(HUMAN, band, links, most = MOST, away = restsAway(hold))
  result = %*{
    "restHolds": sweep.restHolds,
    "negative": round(went(sweep.negative) * 1000.0) / 1000.0,
    "positive": round(went(sweep.positive) * 1000.0) / 1000.0,
    "stoppedNegative": sweep.negative.stopped,
    "stoppedPositive": sweep.positive.stopped,
    "whyNegative": why(sweep.negative),
    "why": why(sweep.positive),
    "foundNegative": false,
    "foundPositive": false,
    "apartNegative": round(sweep.negative.apart * 1000.0) / 1000.0,
    "apartPositive": round(sweep.positive.apart * 1000.0) / 1000.0,
    "frames": (if sweep.restHolds: frames(sweep, band, links) else: newJArray())}
  stderr.writeLine hold & " " & word & ": -" & $went(sweep.negative) &
    " +" & $went(sweep.positive) &
    " (" & $(sweep.negative.moments.len + sweep.positive.moments.len) & " moments)"


proc bridge(): JsonNode =
  ## Record every sweep whole-cloth page plays, with sizes of rig it draws them at.
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
      "heights": {"hip": int(round(HUMAN.hip * 1000.0)),
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
