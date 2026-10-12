## Shoulder's edge held to two studies it replicates, and to what it says of every direction.
##
##   Suites are named for authority: Engin and Chen 1987, chapter 3, by report's own page
##     numbers, and Haering 2015, Fig. 15a.  Figures of authority module has no use for are held
##     here, so each correction module carries is held to print: Table 3.1's ten subjects, and
##     Table 3.2's subject-based rows.
##   Adults' edge is traced again here, apart from module: law creeps out along every hundredth
##     of degree of lower front quarter, with stride and halvings of its own.
##   Internal suite holds what no authority states: mirror, seams, straight-up arm, and
##     agreement with second reading written apart from module.

{.experimental: "strictFuncs".}

import std/[algorithm, json, math, options, os, random, strformat, strutils, tables, unittest]

from ../../design/rig as recording import KEPT_RIG
import ../../simulation/[body, limb, rig, shoulder, vector]
from ../../simulation/rigid import Mark
import ../fixtures


const
  PRINTED = 0.5e-5
    ## Half of printed fifth place, Table 3.3: figure worked from rows rounds to one printed,
    ## half way included.
  PRINTED_POLE = 0.5e-2  ## Half of printed second place, Table 3.1, likewise.
  FIT_OWN = 1.0
    ## Degrees, root mean square: man's Table 3.3 row against his own Table 3.2 edge carried
    ## onto mean axes.  Worst man reads 0.555, measured 2026-10-10.
  FIT_OTHER = 3.0
    ## Degrees, root mean square: least any other man's row fits that edge.  Nearest reads
    ## 3.867, measured 2026-10-10.
  MERIDIANS = 3600  ## Meridians laws read whole edge at, tenth of degree apart.
  SPLIT = 0.001  ## Degrees short of and past each knot of adults' edge law reads union at.
  OUTLINE = 1e-6
    ## Degrees of elevation knot may lie off figure's outline: module halves each crossing to
    ## under 1e-7 degrees along meridian, and steep outline carries that further.  Largest
    ## reads 1.7e-7, measured 2026-10-11.
  CREEP = 0.05
    ## Degrees law steps out along meridian, tracing adults' union: fifth of module's stride.
  HALVINGS = 40  ## Times law halves each crossing it steps over.
  MERIDIANS_ADULTS = 9001
    ## Meridians of lower front quarter law traces, hundredth of degree apart.
  TRACE_MISS = 0.05
    ## Degrees adults' edge may lie off law's own trace: chord of two knots misses module's trace
    ## by at most hundredth of degree at its middle, so by about twice that elsewhere.  Largest
    ## reads 0.0174, at meridian 215.97, measured 2026-10-11.
  SAMPLES_ROUND = 2000  ## Directions round trip law draws, seeded.
  SAMPLES_MIRROR = 500  ## Arms mirror law lays out, seeded.
  SAMPLES_AGREE = 5000  ## Random directions second reading is held to, seeded, past structured.
  FLOOR_AGREE = 4990
    ## Least of those clear of edge and seams, so verdict cannot turn on last bit: 5000 at
    ## seed 23, 2026-10-11.
  NEAR = 1e-9  ## Radians from edge or seam within which sample is skipped.
  STEP_SEAM = 1e-9  ## Radians either side of seam law reads edge at.
  STEP_CONTINUOUS = 1e-8  ## Radians law steps meridian by, away from seams.
  CONTINUOUS = 1e-6  ## Radians edge may move over that step: union of smooth and linear pieces.
  UP_OUTSIDE = 5.2  ## Degrees straight-up arm lies past edge: D3 of step 2's cost report.
  UP_PLACE = 0.05  ## Half of that figure's last place.
  FLOOR_SWEEPS = 1246
    ## Least arm-moments law reads from rig's sweeps: half of 2492 read 2026-10-11.  Fix may
    ## stop sweep early and shed some; reader that loses its way sheds nearly all.
  FLOOR_STILLS = 114  ## Least arm-moments law reads from rig's stills: half of 228, likewise.
  FLOOR_TURNS = 3588
    ## Least held arm-moments law reads from whole-cloth recording: half of 7176, likewise.
  KEPT_TURNS = KEPT_RIG.parentDir / "turns.json"  ## Recording of whole-cloth page, beside rig's.
  WORST_SHOWN = 12  ## Moments furthest past edge that failure lists.

  SUBJECTS: array[Man, tuple[φ, θ: float]] = [
    (57.37, 72.24), (56.52, 77.32), (55.51, 81.61), (59.72, 83.20), (58.82, 79.53),
    (62.58, 77.86), (59.43, 78.87), (57.12, 77.90), (60.98, 84.31), (64.87, 77.93),
  ]
    ## Degrees: each subject's joint axis (φ_n, θ_n), from fixed body axes (Table 3.1, p. 19).
    ##   Subject 3's θ_n prints broken; printed mean 79.08 and deviation 3.42 need 81.61.
  DEVIATION_THETA = 3.42  ## Degrees: sample deviation of θ_n printed (Table 3.1, p. 19).
  SUBJECT_BASED: array[Man, array[1..10, float]] = [
    [1.59292, -0.10675, -0.24466, -0.36233, 0.19558,
     0.44395, 0.49886, 0.06685, -0.62262, -0.42877],
    [1.18066, -0.08909, -0.07757, -0.06084, 0.11961,
     0.33650, 0.23417, -0.34872, -0.32021, -0.04841],
    [1.42229, -0.05486, -0.18374, -0.15690, 0.28160,
     0.35114, 0.34084, -0.26833, -0.30699, -0.12560],
    [1.70121, -0.10321, -0.27100, -0.32562, -0.02313,
     0.74636, 0.45572, 0.19442, -0.26271, -0.79351],
    [1.28393, -0.07031, -0.33344, -0.47247, -0.04754,
     0.67981, 0.55630, 0.44145, -0.12712, -0.61977],
    [1.57994, -0.09393, -0.33890, -0.37299, 0.39152,
     0.89132, 0.55373, 0.05622, -0.69396, -0.86106],
    [1.75422, -0.06345, -0.32748, -0.46664, -0.15587,
     0.63602, 0.62553, 0.22174, -0.22427, -0.80867],
    [1.53784, -0.12414, -0.26177, -0.41879, 0.35225,
     0.79143, 0.50138, 0.17251, -0.60433, -0.49631],
    [1.50215, -0.12424, -0.12763, -0.28346, 0.47236,
     0.53337, 0.27331, -0.00376, -0.63518, -0.39607],
    [1.43838, -0.09574, -0.29782, -0.01552, 0.28790,
     0.44899, 0.51590, -0.44247, -0.49447, -0.12844],
  ]
    ## Each man's edge on his own joint axes, C1 to C10 of Eq. 3.2.1: subject-based voluntary
    ## coefficients (Table 3.2, p. 37).
  MEAN_SPACE_BASED = [1.49896, -0.09266, -0.24693, -0.29213, 0.18903,
                      0.58438, 0.45450, 0.00604, -0.43012, -0.46720]
    ## Sample mean of each coefficient, as printed (Table 3.3, p. 38).
  VARIANCE_SPACE_BASED = [0.03091, 0.00232, 0.01395, 0.02770, 0.04548,
                          0.04255, 0.01727, 0.08065, 0.04394, 0.09848]
    ## Unbiased sample variance of each coefficient, as printed (Table 3.3, p. 38).


type ArmMoment = object  ## Define one arm at one moment of recording, as law reads it.
  recording: string  ## `rig sweep`, `rig still` or `turns`.
  card: string  ## Sweep, still or whole-cloth sweep it belongs to.
  who: Body  ## Whose arm.
  arm: Arm  ## Which of their two.
  at: float  ## Turns from rest, signed.
  reading: Outside  ## Upper arm against shoulder's edge.


func degrees(radians: float): float = radians * 180.0 / PI
  ## Convert radians to degrees.

func radians(degrees: float): float = degrees * PI / 180.0
  ## Convert degrees to radians.

func edgeNested(coefficients: array[1..10, float], φ: float): float =
  ## Read edge of Eq. 3.2.1 at `φ` nested, as second path to `edgeMan`'s sum of powers.
  let (c, s) = (cos(φ), sin(φ))
  ((((coefficients[9] + coefficients[10] * s) * c + coefficients[7] + coefficients[8] * s) * c +
      coefficients[5] + coefficients[6] * s) * c + coefficients[3] + coefficients[4] * s) * c +
      coefficients[1] + coefficients[2] * s

func onAxes(axes: array[3, Vector], polar: Polar): Vector =
  ## Lay `(φ, θ)` out on given joint axes, in body's mirrored terms.
  axes[0] * (sin(polar.θ) * cos(polar.φ)) + axes[1] * (sin(polar.θ) * sin(polar.φ)) +
      axes[2] * cos(polar.θ)

func isUnion(direction: Vector): bool =
  ## Decide whether adults' union holds direction: elevation from hanging under figure's
  ## outline at its plane, outline joined linearly between whole degrees.
  ##   Second reading of module's own, written apart from it.
  let
    plane = degrees(arctan2(direction.y, direction.x)) + 180.0
    elevation = degrees(arccos(clamp(-direction.z / norm(direction), -1.0, 1.0)))
    i = min(int(floor(plane)), OUTLINE_ADULTS.high - 1)
    along = plane - float(i)
  elevation <= OUTLINE_ADULTS[i] + (OUTLINE_ADULTS[i + 1] - OUTLINE_ADULTS[i]) * along

func edgeCrept(φ: float): float =
  ## Creep out along meridian `φ`, degrees, from pole by `CREEP`, halving each crossing, to
  ## where adults' union stops holding it with break of `BREAK_ADULTS` or wider: degrees.
  func isHeld(φ, θ: float): bool = isUnion(toDirection(Polar(φ: radians(φ), θ: radians(θ))))
    ## Decide whether union holds direction `θ` from pole along meridian `φ`, both degrees.

  func crossing(φ, held, left: float): float =
    ## Narrow crossing between `held`, which union holds, and `left`, which it does not.
    var (inner, outer) = (held, left)
    for _ in 1..HALVINGS:
      let middle = (inner + outer) / 2.0
      if isHeld(φ, middle): inner = middle else: outer = middle
    inner

  # Creep out, measuring each break end to end.
  var
    stopped: Option[float]
    k = 1
  while float(k) * CREEP <= 180.0:
    let (θ, is_held) = (float(k) * CREEP, isHeld(φ, float(k) * CREEP))
    inc k
    if stopped.isNone:
      if not is_held: stopped = some(crossing(φ, θ - CREEP, θ))
    elif is_held:
      if crossing(φ, θ, θ - CREEP) - stopped.get >= BREAK_ADULTS: return stopped.get
      stopped = none(float)
    elif θ - stopped.get >= BREAK_ADULTS: return stopped.get
  stopped.get(180.0)

func armMomentsRig(kept: JsonNode): seq[ArmMoment] =
  ## Read every arm of every moment of rig recording, sweeps and stills, all four arms.
  ##   Shoulder and elbow are origins of upper arm's and forearm's links, as judge reads them
  ##     (`rigid.armPoseOf`): each link's capsule run back its radius from its first end.
  ##   Sibling: `test_asks.armOf` reads elbow off upper arm's capsule instead, as page draws
  ##     it.  Two differ by elbow's parting, up to 7.8 mm in `One hand, same name · above`.
  ##   Chest's stance is read off where each dancer faces, as recording keeps it.
  func linkOrigin(points: JsonNode, i: int, radius: float): Vector =
    let
      a: Vector = (points[6*i].getFloat, points[6*i+1].getFloat, points[6*i+2].getFloat)
      z: Vector = (points[6*i+3].getFloat, points[6*i+4].getFloat, points[6*i+5].getFloat)
    a - unit(z - a) * radius

  for (kind, items) in [("rig sweep", kept["sweeps"]), ("rig still", kept["stills"])]:
    for item in items:
      if not item.hasKey("at"): continue
      let
        card = (if kind == "rig still": item["key"].getStr
                else: item["hold"].getStr & " · " & item["band"].getStr)
        tags = item["tag"].getElems
      for m, at in item["at"].getElems:
        let (points, faces) = (item["points"][m], item["faces"][m])
        for owner in item["arm"]:
          let (who, arm) = (Body(owner[0].getInt), Arm(owner[1].getInt))
          var link: array[Mark, int]
          for i, tag in tags:
            if tag[0].getInt == ord(who) and tag[1].getInt == ord(arm):
              link[Mark(tag[2].getInt)] = i
          let
            (upper, fore) = (link[Mark.Upper], link[Mark.Fore])
            stance = Stance(
              centre: (faces[4*ord(who)].getFloat, faces[4*ord(who)+1].getFloat),
              facing: arctan2(faces[4*ord(who)+3].getFloat, faces[4*ord(who)+2].getFloat),
            )
            pose = ArmPose(
              shoulder: linkOrigin(points, upper, item["radii"][upper].getFloat),
              elbow: linkOrigin(points, fore, item["radii"][fore].getFloat),
            )
          result.add ArmMoment(recording: kind, card: card, who: who, arm: arm, at: at.getFloat,
                               reading: outside(axesOf(stance), arm, pose))

func armMomentsTurns(kept: JsonNode): seq[ArmMoment] =
  ## Read every held arm of every moment of whole-cloth recording: lead's points run shoulder
  ## to join, and follow's join to shoulder, in whole millimetres (`design/turns`).
  func pointOf(figures: JsonNode): Vector =
    (figures[0].getFloat / 1000.0, figures[1].getFloat / 1000.0, figures[2].getFloat / 1000.0)

  for key, sweep in kept["sweeps"].pairs:
    let
      hold = key.split('|')[0]
      parts = hold.split('.')
    for frame in sweep["frames"]:
      var stances: array[Body, Stance]
      for who in Body:
        let body_kept = frame["bodies"][ord(who)]
        stances[who] = Stance(
          centre: (body_kept["centre"][0].getFloat / 1000.0,
                   body_kept["centre"][1].getFloat / 1000.0),
          facing: body_kept["facing"].getFloat,
        )
      for i, connection in frame["connections"].getElems:
        let
          lead_arm = (if parts[i][0] == 'L': Arm.Left else: Arm.Right)
          follow_arm = (if parts[i][2] == 'l': Arm.Left else: Arm.Right)
          lead = ArmPose(shoulder: pointOf(connection["lead"][0]),
                         elbow: pointOf(connection["lead"][1]))
          follow = ArmPose(shoulder: pointOf(connection["follow"][3]),
                           elbow: pointOf(connection["follow"][2]))
        result.add ArmMoment(recording: "turns", card: key.replace('|', ' '), who: Body.One,
                             arm: lead_arm, at: frame["turn"].getFloat,
                             reading: outside(axesOf(stances[Body.One]), lead_arm, lead))
        result.add ArmMoment(recording: "turns", card: key.replace('|', ' '), who: Body.Two,
                             arm: follow_arm, at: frame["turn"].getFloat,
                             reading: outside(axesOf(stances[Body.Two]), follow_arm, follow))

func cardsKept(rig, turns: JsonNode): tuple[cards, unheld: seq[string]] =
  ## Name every sweep and still both recordings keep, as `ArmMoment.card` names it, and each
  ## still that holds no pose: one that keeps no moment and mirrors no other still.
  for sweep in rig["sweeps"]: result.cards.add sweep["hold"].getStr & " · " & sweep["band"].getStr
  for still in rig["stills"]:
    let key = still["key"].getStr
    result.cards.add key
    if not still.hasKey("at") and still{"mirror"}.getStr in ["", key]: result.unheld.add key
  for key in turns["sweeps"].keys: result.cards.add key.replace('|', ' ')

func named(moment: ArmMoment): string =
  ## Name arm-moment as pages name it: card, whose arm, turns, and how far past edge.
  let
    who = (if moment.who == Body.One: "lead" else: "follow")
    arm = (if moment.arm == Arm.Left: "left" else: "right")
  &"{moment.card} {who} {arm} {moment.at:+.2f}: {degrees(moment.reading.angle):.1f} degrees, " &
      &"{moment.reading.source}"

func outsideApart(direction: Vector): tuple[angle: float, source: Source, near: float] =
  ## Read direction against edge by second path: pole from Table 3.1's mean, axes by cross
  ## products rather than Eq. 3.5.1's closed form, men's edge nested, adults' knots scanned in
  ## order rather than halved.
  ##   `near` is least distance, radians, from either edge or from either seam.
  let
    (φ_n, θ_n) = (radians(POLE.φ), radians(POLE.θ))
    pole: Vector = (sin(θ_n) * sin(φ_n), sin(θ_n) * cos(φ_n), -cos(θ_n))
    across = unit(cross((0.0, 0.0, -1.0), pole))
    along = cross(across, pole)
    d = unit(direction)
    θ = arccos(clamp(dot(d, pole), -1.0, 1.0))
    φ = floorMod(arctan2(dot(d, across), dot(d, along)), 2.0 * PI)
  var men = -Inf
  for man in Man.low..Man.high: men = max(men, edgeNested(COEFFICIENTS[man], φ))
  var (edge_θ, source_edge) = (men, Source.Men)
  let in_span = degrees(φ) >= SPAN_ADULTS.lower and degrees(φ) <= SPAN_ADULTS.upper
  result.near = min(abs(θ - men), min(abs(φ - radians(SPAN_ADULTS.lower)),
                                      abs(φ - radians(SPAN_ADULTS.upper))))
  if in_span:
    var k = EDGES_ADULTS.low
    while k + 1 < EDGES_ADULTS.high and EDGES_ADULTS[k + 1].φ < degrees(φ): inc k
    let
      (a, z) = (EDGES_ADULTS[k], EDGES_ADULTS[k + 1])
      adults = radians(a.θ * (z.φ - degrees(φ)) / (z.φ - a.φ) +
          z.θ * (degrees(φ) - a.φ) / (z.φ - a.φ))
    result.near = min(result.near, abs(θ - adults))
    if adults > men: (edge_θ, source_edge) = (adults, Source.Adults)
  result.angle = θ - edge_θ
  result.source =
    if θ <= men: Source.Men
    elif θ <= edge_θ: Source.Adults
    else: source_edge



suite "Engin and Chen 1987, chapter 3":
  test "Table 3.1":
    ## Pole is sample mean of ten subjects' joint axes, subject 3's θ_n read from mean and
    ##   deviation printed.
    var (sum_φ, sum_θ) = (0.0, 0.0)
    for man in Man.low..Man.high:
      sum_φ += SUBJECTS[man].φ
      sum_θ += SUBJECTS[man].θ
    let (mean_φ, mean_θ) = (sum_φ / 10.0, sum_θ / 10.0)
    var spread = 0.0
    for man in Man.low..Man.high: spread += (SUBJECTS[man].θ - mean_θ)^2
    check abs(mean_φ - POLE.φ) <= PRINTED_POLE + TOLERANCE_ABS  # Table 3.1, p. 19
    check abs(mean_θ - POLE.θ) <= PRINTED_POLE + TOLERANCE_ABS  # Table 3.1, p. 19
    check abs(sqrt(spread / 9.0) - DEVIATION_THETA) <= PRINTED_POLE + TOLERANCE_ABS  # Table 3.1


  test "Equation 3.5.1":
    ## Joint axes are right-handed and orthonormal, z is pole, and polar reading round trips.
    let (x, y, z) = (AXES_MEAN[0], AXES_MEAN[1], AXES_MEAN[2])
    for a in AXES_MEAN: check norm(a) =~ 1.0  # 3.5.1
    check dot(x, y) =~ 0.0 and dot(y, z) =~ 0.0 and dot(z, x) =~ 0.0  # 3.5.1
    check distance(cross(x, y), z) =~ 0.0  # 3.5.1
    let pole = toPolar(z)
    check pole.θ =~ 0.0  # 3.5.1, p. 34
    var random = initRand(17)
    for _ in 0..<SAMPLES_ROUND:
      let
        polar = Polar(φ: random.rand(0.0 .. 2.0 * PI), θ: random.rand(1e-3 .. PI - 1e-3))
        again = toPolar(toDirection(polar))
      check again.θ =~ polar.θ  # 3.5.1, p. 34
      check abs(sin(again.φ - polar.φ)) < 1e-9 and cos(again.φ - polar.φ) > 0.0  # 3.5.1


  test "Table 3.3":
    ## Ten rows reproduce printed sample mean and variance of each coefficient, so C10 of man 10
    ##   is -0.12297 and not -0.11297 printed.
    for c in 1..10:
      var mean = 0.0
      for man in Man.low..Man.high: mean += COEFFICIENTS[man][c] / 10.0
      var variance = 0.0
      for man in Man.low..Man.high: variance += (COEFFICIENTS[man][c] - mean)^2 / 9.0
      check abs(mean - MEAN_SPACE_BASED[c - 1]) <= PRINTED + TOLERANCE_ABS  # Table 3.3, p. 38
      check abs(variance - VARIANCE_SPACE_BASED[c - 1]) <= PRINTED + TOLERANCE_ABS  # Table 3.3


  test "Tables 3.1 to 3.3, each man his own row":
    ## Each man's subject-based edge (Table 3.2) laid on his own axes (Table 3.1) and read on
    ##   mean axes is fitted by his own space-based row (Table 3.3) and by no other, so printed
    ##   rows 1 and 2 are men 2 and 1.
    for man in Man.low..Man.high:
      let axes = axesJoint(SUBJECTS[man])
      var squared: array[Man, float]
      for degree in 0..<360:
        let
          φ = radians(float(degree))
          read = toPolar(onAxes(axes, Polar(φ: φ, θ: edgeNested(SUBJECT_BASED[man], φ))))
        for row in Man.low..Man.high:
          squared[row] += degrees(edgeMan(row, read.φ) - read.θ)^2 / 360.0
      checkpoint &"man {man}: root mean square by row {squared}"
      for row in Man.low..Man.high:
        if row == man: check sqrt(squared[row]) < FIT_OWN  # Tables 3.1 to 3.3, pp. 19, 37, 38
        else: check sqrt(squared[row]) > FIT_OTHER  # Tables 3.1 to 3.3, pp. 19, 37, 38


  test "Equation 3.2.1":
    ## Men's edge on every meridian is largest of ten rows, each read nested apart.
    for k in 0..<MERIDIANS:
      let φ = 2.0 * PI * float(k) / float(MERIDIANS)
      var most = -Inf
      for man in Man.low..Man.high:
        check edgeMan(man, φ) =~ edgeNested(COEFFICIENTS[man], φ)  # 3.2.1, p. 20
        most = max(most, edgeNested(COEFFICIENTS[man], φ))
      check edgeMen(φ) =~ most  # 3.2.1, p. 20


  test "Lower front quarter":
    ## Adults decide on lower front quarter alone, π to 3π/2, where arm met trunk.
    for k in 0..<MERIDIANS:
      let φ = 2.0 * PI * float(k) / float(MERIDIANS)
      check isSpanAdults(φ) == (φ >= PI and φ <= 1.5 * PI)  # p. 55
      if not isSpanAdults(φ): check edge(φ).source == Source.Men  # p. 55



suite "Haering 2015, Fig. 15a":
  test "Fig. 15a, lower panel":
    ## Adults' edge on each meridian is outer end of union's run from pole, every break
    ##   narrower than `BREAK_ADULTS` closed.  Law creeps out along every hundredth of degree of
    ##   lower front quarter on its own, and edge lies within `TRACE_MISS` of what it finds,
    ##   jumps of union's run included.  Each knot lies on outline at its own plane, and union
    ##   holds just short of it and not just past it.
    var largest_outline = 0.0
    for knot in EDGES_ADULTS:
      let
        φ = radians(knot.φ)
        at = toDirection(Polar(φ: φ, θ: radians(knot.θ)))
        plane = degrees(arctan2(at.y, at.x)) + 180.0
        i = min(int(floor(plane)), OUTLINE_ADULTS.high - 1)
        outline = OUTLINE_ADULTS[i] + (OUTLINE_ADULTS[i + 1] - OUTLINE_ADULTS[i]) *
            (plane - float(i))
        off = abs(degrees(arccos(-at.z)) - outline)
      checkpoint &"knot at meridian {knot.φ:.7f}, edge {knot.θ:.4f}"
      check isUnion(toDirection(Polar(φ: φ, θ: radians(knot.θ - SPLIT))))  # Fig. 15a, p. 59
      check not isUnion(toDirection(Polar(φ: φ, θ: radians(knot.θ + SPLIT))))  # Fig. 15a
      check off < OUTLINE  # Fig. 15a, p. 59
      largest_outline = max(largest_outline, off)
    var
      missed: seq[string]
      largest_miss = (miss: 0.0, φ: 0.0)
    for k in 0..<MERIDIANS_ADULTS:
      let
        φ = SPAN_ADULTS.lower +
            (SPAN_ADULTS.upper - SPAN_ADULTS.lower) * float(k) / float(MERIDIANS_ADULTS - 1)
        (edge_θ, crept) = (degrees(edgeAdults(radians(φ))), edgeCrept(φ))
        miss = abs(edge_θ - crept)
      if miss > largest_miss.miss: largest_miss = (miss, φ)
      if miss >= TRACE_MISS:
        missed.add &"meridian {φ:.2f}: edge {edge_θ:.3f}, union ends {crept:.3f}"
    checkpoint &"`{missed.len}` of `{MERIDIANS_ADULTS}` meridians off trace by `{TRACE_MISS}` " &
        &"degrees or more; largest `{largest_miss.miss:.4f}` at `{largest_miss.φ:.2f}`, " &
        &"largest off outline `{largest_outline:.2e}`:\n      " & missed.join("\n      ")
    check missed.len == 0  # Fig. 15a, p. 59



suite "Internal: Shoulder's edge as law reads it":
  test "a direction and its mirror read the same, left arm in mirror":
    ## Left arm is right arm in mirror (`limb.ownTerms`), so one edge serves both: arm laid out
    ##   on either side along same direction in own terms reads same, from any stance.
    var random = initRand(19)
    for _ in 0..<SAMPLES_MIRROR:
      let
        stance = Stance(centre: (random.rand(-2.0..2.0), random.rand(-2.0..2.0)),
                        facing: random.rand(-10.0..10.0))
        direction = unit((random.rand(-1.0..1.0), random.rand(-1.0..1.0),
                          random.rand(-1.0..1.0)))
        (twist, bend, wrist, roll) = (random.rand(-1.5..1.5), random.rand(0.0..2.4),
                                      random.rand(0.0..1.0), random.rand(-PI..PI))
        left = placed(HUMAN, stance, Arm.Left, direction, twist, bend, wrist, roll)
        right = placed(HUMAN, stance, Arm.Right, direction, twist, bend, wrist, roll)
        (read_left, read_right) = (outside(axesOf(stance), Arm.Left, left),
                                   outside(axesOf(stance), Arm.Right, right))
      check abs(read_left.angle - read_right.angle) < 1e-9
      check abs(read_left.angle - outside(direction).angle) < 1e-9
      if abs(read_left.angle) > 1e-9: check read_left.source == read_right.source


  test "the edge steps only where adults start and stop deciding, by how far past men":
    ## Men's edge is largest of smooth curves and adults' is laid straight between knots, so each
    ##   is continuous.  At each seam of `SPAN_ADULTS` edge steps by adults' edge less men's
    ##   where adults went further, and by nothing where they did not.
    for k in 0..<MERIDIANS:
      let φ = 2.0 * PI * (float(k) + 0.5) / float(MERIDIANS)
      check abs(edge(φ + STEP_CONTINUOUS).θ - edge(φ).θ) < CONTINUOUS
    for seam in [SPAN_ADULTS.lower, SPAN_ADULTS.upper]:
      let
        φ = radians(seam)
        (inside_span, beyond) =
          if seam == SPAN_ADULTS.lower: (φ + STEP_SEAM, φ - STEP_SEAM)
          else: (φ - STEP_SEAM, φ + STEP_SEAM)
        step = max(0.0, edgeAdults(φ) - edgeMen(φ))
      checkpoint &"seam {seam}: steps {degrees(step):.2f} degrees"
      check abs(edge(inside_span).θ - edge(beyond).θ - step) < CONTINUOUS
      check edge(beyond).source == Source.Men
      for θ in [0.5, 1.2, 1.8, 2.4]:
        let
          inner = outside(toDirection(Polar(φ: inside_span, θ: θ))).angle
          outer = outside(toDirection(Polar(φ: beyond, θ: θ))).angle
        check abs(outer - inner - step) < CONTINUOUS


  test "the arm straight up lies 5.2 degrees outside, by the men's edge":
    ## Known before law: straight up is 5.2 degrees past edge (D3 of step 2's cost report).
    let up = outside((0.0, 0.0, 1.0))
    check abs(degrees(up.angle) - UP_OUTSIDE) < UP_PLACE
    check up.source == Source.Men
    check not up.isInside


  test "the arm hanging plumb lies inside by what the adults reached alone, on the seam at 180":
    ## Ten men's union leaves hanging arm out by 10.5 degrees (step 1 of issue 611); adults
    ##   decide there, on lower front quarter, and hold it.
    ##   Trap: `y_jt` is horizontal, so plumb lies on seam, and degree behind it men decide alone.
    let
      plumb = toPolar((0.0, 0.0, -1.0))
      down = outside((0.0, 0.0, -1.0))
      behind = outside((0.0, -sin(radians(1.0)), -cos(radians(1.0))))
    check down.isInside
    check down.source == Source.Adults
    check plumb.θ > edgeMen(plumb.φ)
    check plumb.φ =~ PI
    check not behind.isInside
    check behind.source == Source.Men


  test "seeded directions agree with a second reading written apart":
    ## Structured first: six axes, pole and its far end, and directions on both seams; then
    ##   random directions over whole sphere.  Sample within `NEAR` of edge or seam is
    ##   skipped, and count that passed is held to `FLOOR_AGREE`.
    var corpus: seq[Vector] = @[
      (1.0, 0.0, 0.0), (-1.0, 0.0, 0.0), (0.0, 1.0, 0.0), (0.0, -1.0, 0.0),
      (0.0, 0.0, 1.0), (0.0, 0.0, -1.0), AXES_MEAN[2], -AXES_MEAN[2],
    ]
    for seam in [SPAN_ADULTS.lower, SPAN_ADULTS.upper]:
      for θ in [0.3, 0.9, 1.5, 2.1, 2.7]:
        for offset in [-1e-3, 1e-3]:
          corpus.add toDirection(Polar(φ: radians(seam) + offset, θ: θ))
    let structured = corpus.len
    var random = initRand(23)
    while corpus.len < structured + SAMPLES_AGREE:
      let candidate: Vector = (random.rand(-1.0..1.0), random.rand(-1.0..1.0),
                               random.rand(-1.0..1.0))
      if norm(candidate) > 1e-3 and norm(candidate) <= 1.0: corpus.add unit(candidate)
    var agreed = 0
    for i, direction in corpus:
      let (module_read, apart) = (outside(direction), outsideApart(direction))
      if apart.near < NEAR: continue
      check abs(module_read.angle - apart.angle) < 1e-9
      check module_read.source == apart.source
      check module_read.isInside == (apart.angle <= 0.0)
      if i >= structured: inc agreed
    check agreed >= FLOOR_AGREE



suite "Internal: Every upper arm the simulation recorded, against shoulder's edge":
  test "every arm-moment of both recordings points inside the edge, within the judge's give":
    ## Regression of issue 611, each mistake as it found it:
    ##   D01 and D07: follow's upper arm runs behind own neck, at 1.50 and -1.50 turns.
    ##   `One hand, same name · above`: follow's right arm, which holds nothing, lies behind own
    ##     neck from 0.58 turns to 2.50.
    ##   C01: follow's right upper arm is raised past vertical, 29 degrees back, at 1.50 turns.
    ##   Domain: every arm-moment of `design/rig.json`, all four arms of every sweep and still,
    ##     and every held arm-moment of `design/turns.json`.  Each recording yields at least its
    ##     floor; still that holds no pose yields none, and is named.
    ##   Arm may lie past edge by `GIVE_EDGE` and still hold, as judge lets swing do.
    ##   Quoted moment no longer recorded, since no pose holds there or sweep stops short of it,
    ##     is answered: domain holds whatever card records.  Card itself must stay kept, and
    ##     where card records any arm in range, quoted arm must be among them.
    ##   Red before its fix, read 2026-10-11: 2517 of 9896 arm-moments past edge by more than
    ##     give, 2837 past it at all, every quoted moment among them.
    ##   Rig's sweeps record moment they stop at (`seen.shownAsked`), so sweep judge stops at edge
    ##     records arm past give, and fails here.  Design allows that stop and this law does
    ##     not; none stops so on 2026-10-11, and Architect rules which holds.
    let
      (rig, turns) = (parseFile(KEPT_RIG), parseFile(KEPT_TURNS))
      moments = armMomentsRig(rig) & armMomentsTurns(turns)
      kept = cardsKept(rig, turns)
      quoted = [
        (card: "D01", who: Body.Two, arm: Arm.Right, lower: 1.50, upper: 1.50),
        (card: "D07", who: Body.Two, arm: Arm.Left, lower: -1.50, upper: -1.50),
        (card: "One hand, same name · above", who: Body.Two, arm: Arm.Right, lower: 0.58,
         upper: 2.50),
        (card: "C01", who: Body.Two, arm: Arm.Right, lower: 1.50, upper: 1.50),
      ]
    var
      past: seq[ArmMoment]
      past_any = 0
      read, by_recording, by_card: CountTable[string]
    for moment in moments:
      read.inc moment.recording
      if moment.reading.angle > 0.0: inc past_any
      if moment.reading.angle <= GIVE_EDGE: continue
      past.add moment
      by_recording.inc moment.recording
      by_card.inc moment.card
    past.sort(proc (a, b: ArmMoment): int = cmp(b.reading.angle, a.reading.angle))
    by_recording.sort
    by_card.sort
    var cards: seq[string]
    for card, count in by_card: cards.add &"{card} {count}"
    var recordings: seq[string]
    for kind, count in by_recording: recordings.add &"{kind} {count}"
    var worst: seq[string]
    for moment in past[0..<min(past.len, WORST_SHOWN)]: worst.add moment.named
    checkpoint &"Arm-moments read: `{read[\"rig sweep\"]}` of rig's sweeps, " &
        &"`{read[\"rig still\"]}` of its stills, `{read[\"turns\"]}` held in whole-cloth " &
        &"recording.  Stills holding no pose: `{kept.unheld.join(\", \")}`."
    check read["rig sweep"] >= FLOOR_SWEEPS
    check read["rig still"] >= FLOOR_STILLS
    check read["turns"] >= FLOOR_TURNS
    checkpoint &"`{past.len}` of `{moments.len}` arm-moments lie past edge by more than " &
        &"`{degrees(GIVE_EDGE):.1f}` degrees, and `{past_any}` past it at all.\n" &
        "    By recording: " & recordings.join(", ") & ".\n" &
        "    By card: " & cards.join(", ") & ".\n" &
        "    Worst:\n      " & worst.join("\n      ")
    var cases: seq[string]
    for (card, who, arm, lower, upper) in quoted:
      var
        in_range, found, beyond = 0
        worst_case = ArmMoment(reading: Outside(angle: -Inf))
      for moment in moments:
        if moment.card != card or moment.at < lower - 1e-9 or moment.at > upper + 1e-9: continue
        inc in_range
        if moment.who != who or moment.arm != arm: continue
        inc found
        if moment.reading.angle > GIVE_EDGE: inc beyond
        if moment.reading.angle > worst_case.reading.angle: worst_case = moment
      checkpoint &"Quoted: `{card}`, {who} {arm}, {lower:+.2f} to {upper:+.2f} turns: `{found}` " &
          &"of `{in_range}` arm-moments recorded there."
      check card in kept.cards
      if in_range > 0: check found > 0
      if beyond > 0: cases.add &"{beyond} of {found} past, worst {worst_case.named}"
    checkpoint "Quoted by issue 611:\n      " & cases.join("\n      ")
    check cases.len == 0
    check past.len == 0
