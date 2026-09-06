## Ask body sim for every hold turning, and write it down for page.
##
##   Whole-cloth page animates hold turning, and only honest way to
##     animate two bodies and their arms is to ask thing that models
##     them.  Solving pose is too slow to do in browser at every frame,
##     so this program runs sim natively, sweeps every hold at every
##     height, and writes every moment of every sweep as data; page only
##     draws.  Nothing about physics is guessed on page: where each
##     joint is, which way arm lies, and where turn runs out are all
##     read from here.
##   Design directory may import sim; sim imports nothing back.
##     Words (wrap, lock, low, high) are put on here, as `sim/verdicts`
##     does.  Not because sim speaks other language -- it reuses agreed
##     words -- but because here it measures what ontology asserts, and
##     translation kept visible is evidence where assumed identity is echo.
##   Two rests, both page's own choice: cross-name holds rest face to
##     face, and same-name holds are also built face to face so
##     turns count as sheet counts (away rest is half turn along).
##     Same-name *pair* is exception: face to face its two
##     connections lie through each other, so it is built at away rest
##     -- collected there, as couple would -- and its turns count from it.

{.experimental: "strictFuncs".}

import std/[json, math, options, strutils, tables]

import ../sim/[body, limb, read, rig, solve, sweep, vec]


const
  APART = 0.40 ## Stance, in metres: same one `sim/verdicts` asks at.
  HOLDS = ["L-l", "R-r", "L-r", "R-l", "L-l.R-r", "L-r.R-l"]
  BANDS = [("low", Band.Torso), ("high", Band.Neck), ("above", Band.Crown)]


func armsOf(hold: string): seq[(Arm, Arm)] =
  ## Read "L-l" or "L-r.R-l": lead's hand in capitals, follow's in
  ## lower case.
  for part in hold.split('.'):
    let
      a = if part[0] == 'L': Arm.Left else: Arm.Right
      b = if part[2] == 'l': Arm.Left else: Arm.Right
    result.add (a, b)

func sameName(hold: string): bool =
  for (a, b) in armsOf(hold):
    if a != b: return false
  true

func rested(hold: string; band: Band): State =
  ## Build hold at rest its turns are counted from.
  result = State(rig: HUMAN, stance: facing(HUMAN, APART), band: band)
  if hold.contains('.') and sameName(hold):
    result.stance[Body.Two].facing = result.stance[Body.Two].facing - PI
  for (a, b) in armsOf(hold):
    result.links.add Link(ends: [(Body.One, a), (Body.Two, b)])


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

func whose(s: State; link, arm: int): string =
  if s.links[link].ends[arm].body == Body.One: "his" else: "her"

func why(s: State; v: Verdict): string =
  ## Say what refuses, in few words that page can show.
  case v.reason
  of Reason.None: "holds"
  of Reason.Reach: whose(s, v.link, v.arm) & " reach"
  of Reason.Shoulder, Reason.Twist, Reason.Elbow, Reason.Wrist:
    whose(s, v.link, v.arm) & " " & dofName(v.dof)
  of Reason.Through:
    let part = case v.part
      of Part.Torso: "torso"
      of Part.Neck: "neck"
      of Part.Head: "head"
    whose(s, v.link, v.arm) & " arm through " &
      (if v.whose == Body.One: "his " else: "her ") & part
  of Reason.Arms: "arm through arm"
  of Reason.Band: "the hands out of their height"

func strained(s: State; v: Verdict): string =
  ## Name joint nearest its edge.
  if v.n == 0: return ""
  var worst = -1.0
  for i in 0 ..< v.n:
    if v.fits[i].strain > worst:
      worst = v.fits[i].strain
      result = whose(s, i, v.fits[i].strainedArm) & " " & dofName(v.fits[i].strainedDof)


func mm(p: Vec): JsonNode =
  %*[int(round(p.x * 1000.0)), int(round(p.y * 1000.0)), int(round(p.z * 1000.0))]

func frame(m: Moment; band: Band): JsonNode =
  let
    s = m.state
    v = m.verdict
  result = %*{
    "t": round(m.turn * 1000.0) / 1000.0,
    "ok": v.ok,
    "reseed": m.reseeded,
    "strain": round(v.strain * 100.0) / 100.0,
    "worst": strained(s, v),
    "bodies": [
      {"c": [int(round(s.stance[Body.One].centre.x * 1000.0)),
             int(round(s.stance[Body.One].centre.y * 1000.0))],
       "f": round(s.stance[Body.One].facing * 1000.0) / 1000.0},
      {"c": [int(round(s.stance[Body.Two].centre.x * 1000.0)),
             int(round(s.stance[Body.Two].centre.y * 1000.0))],
       "f": round(s.stance[Body.Two].facing * 1000.0) / 1000.0}],
    "cn": []}
  let cross = crossings(s, v)
  for i in 0 ..< v.n:
    let
      him = v.fits[i].arms[armOf(s, i, Body.One)]
      her = v.fits[i].arms[armOf(s, i, Body.Two)]
    var cj = %*{
      "him": [mm(him.s), mm(him.e), mm(him.w), mm(him.g)],
      "her": [mm(her.g), mm(her.w), mm(her.e), mm(her.s)],
      "himSays": said(lyingOn(s, v, i, Body.One), band),
      "herSays": said(lyingOn(s, v, i, Body.Two), band)}
    if i == 0 and cross.len > 0:
      var overs = newJArray()
      for c in cross:
        overs.add %*{"at": [int(round(c.at.x * 1000.0)), int(round(c.at.y * 1000.0))],
                     "over": c.over}
      cj["cross"] = overs
    result["cn"].add cj


proc sweepJson(hold: string; word: string; band: Band; sw: Sweep): JsonNode =
  result = %*{
    "restHolds": sw.restHolds,
    "neg": round(sw.neg.at * 1000.0) / 1000.0,
    "pos": round(sw.pos.at * 1000.0) / 1000.0,
    "stoppedNeg": sw.neg.stopped,
    "stoppedPos": sw.pos.stopped,
    "whyNeg": (if sw.neg.stopped: why(sw.rest, sw.neg.why) else: "no block"),
    "why": (if sw.pos.stopped: why(sw.rest, sw.pos.why) else: "no block"),
    "foundNeg": sw.neg.foundAnyway,
    "foundPos": sw.pos.foundAnyway,
    "frames": []}
  for m in sw.moments:
    result["frames"].add frame(m, band)
  stderr.writeLine hold & " " & word & ": -" & $sw.neg.at & " +" & $sw.pos.at &
    " (" & $sw.moments.len & " moments)"


proc bridge(): JsonNode =
  result = %*{
    "apart": int(round(APART * 1000.0)),
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
  # Every hold at every height is its own sweep; they are run side by side,
  # long ones -- over head, where nothing blocks -- handed out first
  # so no core is left sweeping alone at end, and written in order.
  var
    jobs: seq[Job]
    slot: Table[string, int]
  for (word, band) in [BANDS[2], BANDS[1], BANDS[0]]:
    for hold in HOLDS:
      slot[hold & "|" & word] = jobs.len
      jobs.add Job(rest: rested(hold, band), who: Body.Two, most: MOST)
  let sweeps = sweptAll(jobs)
  for hold in HOLDS:
    for (word, band) in BANDS:
      let key = hold & "|" & word
      result["sweeps"][key] = sweepJson(hold, word, band, sweeps[slot[key]])


when isMainModule:
  writeFile("build/design/turns.js", "var TURNS = " & $bridge() & ";\n")
  echo "wrote build/design/turns.js"
