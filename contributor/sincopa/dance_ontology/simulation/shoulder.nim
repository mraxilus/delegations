## Where human shoulder lets its upper arm point, as two studies measured it.
##
##   Direction is read from moving shoulder joint to elbow, in body's mirrored terms: x out to
##     arm's own side, y fore, z up.  Left arm is read in mirror (`limb.ownTerms`), so one edge
##     serves both arms.
##   Engin and Chen 1987 had ten men carry upper arm round furthest boundary each reached by
##     his own effort, and fitted each boundary on mean joint axes (Table 3.3, Eq. 3.2.1).
##     Direction is allowed where one of them reached it: θ under largest of ten edges on its
##     meridian, which is their active union.
##   On lower front quarter, φ from 180 to 270 degrees, their men met own trunk (p. 55), so
##     edge there is trunk's as much as shoulder's.  There direction is also allowed where one
##     of Haering's sixteen adults reached it (union of sixteen hulls, Fig. 15a).  Nowhere else
##     do adults decide (issue 611, variant V2).
##     Cost: edge steps where quarter starts and ends, by how far adults went past men there:
##       42.1 degrees at 180 and 8.6 at 270.  Accepted -- span is Architect's ruling.
##   Edge is hard.  Past it direction is refused, with no ease, and `Outside.angle` says how
##     far: θ less edge on same meridian, positive outside, which is polar margin.
##     Cost: polar margin is not shortest arc to edge.  Within ten degrees of edge, arc is
##       under 0.6 degrees shorter for 67 of 100 recorded arms, and up to 8.6 shorter beside
##       seam at 270.  Accepted -- Architect ruled polar, measured 2026-10-11.
##   Held arm may still lie `GIVE_EDGE` past edge, as judge lets swing lie past its end.
##     Question for Architect: does edge ruled hard keep this give, or none?  Suite reads it;
##       engine does not yet.
##   Trap: arm hanging plumb lies on seam at 180, since `y_jt` is horizontal.  It is 31.6 degrees
##     inside along its meridian, yet 0.007 from edge: hair behind plumb, men decide, and refuse
##     it by about ten.  Suite trips on it.
##   Adults' edge is derived at compile time from figure's outline (`OUTLINE_ADULTS`): traced
##     out along each meridian from pole to where union's run ends, every break narrower than
##     `BREAK_ADULTS` closed, and laid straight between knots.  Knots stand `STEP_ADULTS` apart,
##     and more go between two wherever their chord misses trace by over `CHORD_ADULTS`, so
##     edge keeps union's jumps too, 5.5 degrees near 186.  Suite reads it every hundredth of
##     degree.
##     Cost: about 0.7 s of compile time in each binary that imports module.  Small importer
##       built in 2.46 s and 2.51 s, against 1.72 s and 1.87 s with edge tabled per half
##       degree, measured 2026-10-11 on four cores.  Trace strides `STRIDE_ADULTS`, so run or
##       break narrower than that may go unseen; figure itself is read to about 1.25 degrees.
##   Twist of upper arm is no part of this edge: engine keeps its own window (`rig`, issue 622).
##
##   |------------------|--------------------------------------------|----------------------------|
##   | Code             | Authority                                  | Meaning                    |
##   |------------------|--------------------------------------------|----------------------------|
##   | `POLE`           | (φ_n, θ_n) sample mean, Table 3.1, p. 19   | mean joint axis            |
##   | `axesJoint`      | x_jt, y_jt, z_jt, Eq. 3.5.1, p. 34         | joint axes of one pole     |
##   | `Polar.φ`        | φ, Eq. 3.2.1, p. 20                        | meridian, round pole       |
##   | `Polar.θ`        | θ, Eq. 3.2.1, p. 20                        | angle from pole            |
##   | `COEFFICIENTS`   | C1 to C10, Table 3.3, p. 38                | each man's edge, mean axes |
##   | `edgeMan`        | θ(φ) of Eq. 3.2.1, p. 20                   | one man's edge             |
##   | `edgeMen`        | largest θ(φ) over ten men                  | active union of ten men    |
##   | `SPAN_ADULTS`    | π < φ < 3π/2, p. 55                        | lower front quarter        |
##   | `OUTLINE_ADULTS` | Fig. 15a, lower panel, Haering 2015, p. 59 | union of sixteen hulls     |
##   | `EDGES_ADULTS`   | outer end of Fig. 15a's union, by meridian | adults' edge, knot by knot |
##   |------------------|--------------------------------------------|----------------------------|
##
##   Engin and Chen 1987: Human joint articulation and motion-resistive properties,
##     AAMRL-TR-87-011, DTIC ADA182574, chapter 3.  Pages are report's own numbers.
##   Haering 2015: PhD thesis, Université de Montréal, after Haering 2014 (J Biomech Eng 136).

{.experimental: "strictFuncs".}

import std/[math, options]

import ./[body, limb, vector]


type
  Man* = range[1..10]  ## Define one of Engin and Chen's ten men, numbered as Table 3.1 does.

  Source* {.pure.} = enum  ## Define whose effort decides direction.
    Men,  ## Ten men of Engin and Chen 1987, each by his own effort.
    Adults  ## Sixteen adults of Haering 2015, on lower front quarter alone.

  Polar* = object  ## Define direction on mean joint axes, radians, i.e. (φ, θ) of Eq. 3.2.1.
    φ*: float  ## Meridian: round pole from `x_jt` toward `y_jt`, in [0, 2π).
    θ*: float  ## Angle from pole, in [0, π].

  Edge* = object  ## Define edge on one meridian, and whose it is.
    θ*: float  ## Radians from pole.
    source*: Source

  Outside* = object  ## Define how far one direction lies past edge, and whose effort decides.
    angle*: float  ## Radians: θ less edge on same meridian; positive outside, negative inside.
    source*: Source
      ## Men where one of them reached direction; adults where only adults did; else whose
      ##   edge refuses it.

  Knot* = tuple[φ, θ: float]  ## Define point of adults' edge: meridian, and edge on it, degrees.


func toRadians(degrees: float): float = degrees * PI / 180.0
  ## Convert degrees to radians.

func toDegrees(radians: float): float = radians * 180.0 / PI
  ## Convert radians to degrees.

const
  POLE* = (φ: 59.29, θ: 79.08)
    ## Degrees: sample mean of ten men's joint axes, from fixed body axes (Table 3.1, p. 19).
    ##   Subject 3's θ_n prints broken; mean and deviation printed need 81.61, which suite holds.
  COEFFICIENTS*: array[Man, array[1..10, float]] = [
    [1.59502, -0.13343, -0.36746, -0.36963, 0.18949,
     0.38560, 0.49613, 0.09209, -0.61517, -0.36522],
    [1.18167, -0.13492, -0.10623, -0.04934, 0.11099,
     0.29947, 0.22508, -0.37071, -0.30969, 0.01536],
    [1.42535, -0.12051, -0.14047, -0.16509, 0.26499,
     0.37472, 0.34033, -0.26402, -0.29337, -0.16580],
    [1.69959, -0.09904, -0.19982, -0.31658, -0.01759,
     0.76733, 0.45691, 0.17579, -0.26778, -0.81237],
    [1.28512, -0.07703, -0.32588, -0.47315, -0.05643,
     0.67388, 0.55654, 0.43909, -0.11917, -0.61506],
    [1.57365, -0.04192, -0.36103, -0.36639, 0.42768,
     0.91880, 0.55155, 0.03496, -0.72275, -0.88100],
    [1.75407, -0.06101, -0.33126, -0.46733, -0.15494,
     0.63562, 0.62551, 0.22275, -0.22494, -0.80821],
    [1.54165, -0.16045, -0.28826, -0.42410, 0.33518,
     0.79179, 0.50885, 0.18746, -0.59228, -0.50851],
    [1.50088, -0.09623, -0.03463, -0.28225, 0.47499,
     0.54593, 0.27331, -0.00882, -0.63813, -0.40824],
    [1.43259, -0.00208, -0.31430, -0.00739, 0.31598,
     0.45068, 0.51082, -0.44820, -0.51794, -0.12297],
  ]
    ## Each man's edge on mean joint axes, C1 to C10 of Eq. 3.2.1: space-based voluntary
    ## coefficients (Table 3.3, p. 38).
    ##   Held in man's order.  Printed rows 1 and 2 belong to men 2 and 1: each fits his own
    ##     Table 3.2 edge, carried onto mean axes, and no other, which suite holds.
    ##   C10 of man 10 prints -0.11297; printed mean and variance need -0.12297, held here.
  SPAN_ADULTS* = (lower: 180.0, upper: 270.0)
    ## Degrees of meridian where adults also decide: lower front quarter, π < φ < 3π/2, where
    ## men's arm met own trunk (p. 55).  Closed at both ends.
  OUTLINE_ADULTS* = [
    11.2, 11.6, 12.2, 12.8, 13.4, 14.1, 14.7, 15.3, 15.9, 16.6,  # plane -180
    17.2, 17.8, 18.4, 19.1, 20.3, 20.3, 21.6, 22.2, 22.8, 23.4,  # plane -170
    24.1, 24.7, 25.9, 25.9, 27.2, 27.8, 27.8, 29.1, 29.7, 30.3,  # plane -160
    31.6, 31.6, 32.8, 32.8, 34.1, 34.7, 35.3, 35.9, 36.6, 37.2,  # plane -150
    37.8, 38.4, 39.7, 40.3, 40.9, 41.6, 42.2, 42.8, 42.8, 44.7,  # plane -140
    45.3, 45.3, 46.6, 47.2, 47.2, 48.4, 49.1, 49.7, 50.3, 50.9,  # plane -130
    52.2, 52.2, 52.8, 54.1, 54.7, 55.3, 55.9, 56.6, 57.8, 57.8,  # plane -120
    59.1, 59.1, 60.3, 60.9, 61.6, 62.2, 62.8, 64.1, 64.7, 65.3,  # plane -110
    65.9, 66.4, 67.6, 67.9, 68.9, 69.8, 70.3, 70.9, 71.7, 72.5,  # plane -100
    73.3, 74.1, 74.8, 75.6, 76.4, 77.2, 78.4, 79.1, 80.3, 80.9,  # plane -90
    81.6, 82.8, 82.8, 84.1, 85.3, 85.9, 87.2, 87.2, 88.4, 89.7,  # plane -80
    90.3, 91.6, 92.2, 92.8, 93.9, 95.1, 95.4, 96.7, 97.9, 98.6,  # plane -70
    99.8, 100.4, 101.1, 102.3, 102.9, 103.6, 104.8, 105.8, 107.3, 107.9,  # plane -60
    108.9, 109.2, 109.8, 111.1, 111.4, 112.9, 113.3, 174.1, 174.1, 174.7,  # plane -50
    174.7, 174.7, 174.1, 174.1, 174.1, 174.1, 174.1, 174.1, 174.1, 174.1,  # plane -40
    174.1, 174.1, 174.1, 174.1, 174.1, 174.1, 174.1, 174.1, 174.1, 174.1,  # plane -30
    174.1, 174.1, 174.1, 174.1, 174.7, 174.7, 174.7, 165.9, 160.3, 160.3,  # plane -20
    175.9, 175.9, 167.2, 175.3, 176.6, 175.3, 175.2, 175.2, 175.1, 175.0,  # plane -10
    174.9, 174.8, 174.8, 174.7, 174.7, 174.7, 174.7, 174.7, 174.7, 174.7,  # plane 0
    174.7, 174.7, 174.1, 174.1, 174.1, 174.1, 174.1, 174.1, 173.4, 173.4,  # plane 10
    172.8, 172.8, 172.8, 172.8, 172.8, 172.8, 172.8, 172.8, 172.8, 172.8,  # plane 20
    172.8, 172.8, 172.8, 172.8, 172.8, 172.8, 172.8, 172.8, 172.8, 172.8,  # plane 30
    172.8, 172.8, 172.8, 172.8, 172.2, 172.2, 172.2, 171.6, 171.6, 171.6,  # plane 40
    171.6, 170.9, 170.9, 170.9, 170.9, 170.3, 170.3, 170.3, 170.3, 170.3,  # plane 50
    170.3, 170.3, 170.9, 170.9, 170.9, 170.9, 171.6, 171.6, 171.6, 172.2,  # plane 60
    172.2, 172.2, 172.2, 172.2, 172.8, 172.8, 172.8, 172.8, 172.2, 171.6,  # plane 70
    170.9, 169.7, 169.7, 169.7, 166.6, 165.9, 165.2, 164.5, 163.8, 163.0,  # plane 80
    162.3, 161.6, 160.9, 160.9, 160.3, 161.6, 161.6, 159.7, 159.7, 159.7,  # plane 90
    158.4, 158.4, 157.8, 157.8, 157.2, 156.6, 156.6, 155.3, 155.3, 154.7,  # plane 100
    154.1, 154.1, 152.8, 152.8, 152.2, 150.9, 150.3, 149.1, 148.4, 147.2,  # plane 110
    145.9, 145.3, 144.1, 142.8, 142.2, 140.9, 140.3, 139.1, 137.8, 137.2,  # plane 120
    135.9, 135.3, 134.1, 132.8, 132.2, 130.3, 128.4, 127.2, 124.7, 122.8,  # plane 130
    121.6, 120.9, 118.4, 92.8, 90.3, 87.8, 84.7, 82.8, 79.7, 79.1,  # plane 140
    75.9, 71.6, 70.9, 64.7, 62.8, 60.3, 57.8, 56.6, 54.1, 52.8,  # plane 150
    50.3, 46.6, 45.9, 43.4, 41.6, 39.7, 37.2, 35.9, 34.1, 31.6,  # plane 160
    28.9, 26.7, 26.6, 22.9, 20.8, 20.9, 17.9, 16.1, 15.3, 11.6,  # plane 170
    11.2,  # plane 180
  ]
    ## Degrees: largest elevation from hanging of union of sixteen hulls, eight men and eight
    ## women, on each plane of elevation, one degree apart from -180 (Haering 2015, Fig. 15a,
    ## lower panel, p. 59), as step 1 of issue 611 read it off outline.
    ##   Plane is nought out to side, ninety forward, minus ninety back.  Where labels caught
    ##     outline (planes -99 to -95, 170 to 177), step 1's pixel mask is read; where lobe near
    ##     vertical behind back joins main body (-66 to -44), main body is kept.  Over 100.9
    ##     degrees never binds on lower front quarter, so reading near vertical reaches no law.
  BREAK_ADULTS* = 3.0
    ## Degrees: break in adults' union along meridian narrower than this is closed, being
    ## inside figure's reading error of about two pixels, 1.25 degrees, each side.
  STRIDE_ADULTS = 0.25
    ## Degrees trace steps out along meridian: run or break of union narrower may go unseen.
  HALVINGS_ADULTS = 24
    ## Times trace halves each crossing it steps over, to stride over 2^24: under 1e-7 degrees.
  STEP_ADULTS = 1.0  ## Degrees of meridian between knots traced first.
  CHORD_ADULTS = 0.01
    ## Degrees chord of two knots may miss trace at its middle before knot goes there.
  NARROWEST_ADULTS = 1e-6
    ## Degrees of meridian no two knots are split under: width jump in edge is laid across.
  GIVE_EDGE* = toRadians(2.0)
    ## Radians held arm may lie past edge and still hold: two degrees, as judge gives swing past
    ## either end, `rigid.GIVE` of its twenty degree ease.  Same reason: arm leant on its wall
    ## sits that far past it, under three degrees that flesh gives, and slides along it.


func axesJoint*(pole: tuple[φ, θ: float]): array[3, Vector] =
  ## Read joint axes `x_jt`, `y_jt`, `z_jt` of pole given in degrees, in body's mirrored
  ## terms, i.e. Eq. 3.5.1 (p. 34).
  ##   Fixed body axes run fore, out to arm's side, and down: z about fixed body's down by
  ##     φ_n, then about turned y by θ_n.  Body's mirrored terms take them as y, x and -z.
  let
    (φ, θ) = (toRadians(pole.φ), toRadians(pole.θ))
    x_fixed: Vector = (cos(θ) * cos(φ), cos(θ) * sin(φ), -sin(θ))
    y_fixed: Vector = (-sin(φ), cos(φ), 0.0)
    z_fixed: Vector = (sin(θ) * cos(φ), sin(θ) * sin(φ), cos(θ))
  [(x_fixed.y, x_fixed.x, -x_fixed.z), (y_fixed.y, y_fixed.x, -y_fixed.z),
   (z_fixed.y, z_fixed.x, -z_fixed.z)]

const AXES_MEAN* = axesJoint(POLE)  ## Mean joint axes, `x_jt`, `y_jt` and `z_jt`, whose z is pole.


func toPolar*(direction: Vector): Polar =
  ## Read direction in body's mirrored terms on mean joint axes; any length but nought.
  let
    d = unit(direction)
    x = dot(AXES_MEAN[0], d)
    y = dot(AXES_MEAN[1], d)
  Polar(φ: floorMod(arctan2(y, x), 2.0 * PI), θ: arccos(clamp(dot(AXES_MEAN[2], d), -1.0, 1.0)))

func toDirection*(polar: Polar): Vector =
  ## Read unit direction in body's mirrored terms back off mean joint axes.
  AXES_MEAN[0] * (sin(polar.θ) * cos(polar.φ)) + AXES_MEAN[1] * (sin(polar.θ) * sin(polar.φ)) +
      AXES_MEAN[2] * cos(polar.θ)


func edgeMan*(man: Man, φ: float): float =
  ## Read one man's edge on meridian `φ`, radians, i.e. θ(φ) = Σ cosⁿ⁻¹φ (C₂ₙ₋₁ + C₂ₙ sin φ)
  ## for n from 1 to 5 (Eq. 3.2.1).
  let (c, s) = (cos(φ), sin(φ))
  var power = 1.0
  for n in 1..5:
    result += power * (COEFFICIENTS[man][2 * n - 1] + COEFFICIENTS[man][2 * n] * s)
    power *= c

func edgeMen*(φ: float): float =
  ## Read edge of men's active union on meridian `φ`, radians: largest of ten.
  result = -Inf
  for man in Man.low..Man.high: result = max(result, edgeMan(man, φ))

func isSpanAdults*(φ: float): bool =
  ## Decide whether adults also decide on meridian `φ`, radians.
  φ >= toRadians(SPAN_ADULTS.lower) and φ <= toRadians(SPAN_ADULTS.upper)

func edgeTraced(φ: float): float {.compileTime.} =
  ## Trace meridian `φ`, degrees, out from pole to where union of sixteen adults stops holding
  ## it, every break narrower than `BREAK_ADULTS` closed: outer end of run that holds pole, in
  ## degrees.
  ##   Each crossing is halved down, so break is measured end to end and not by stride.
  func isHeld(θ: float, across: Vector): bool =
    ## Decide whether union holds direction `θ` from pole toward `across`: elevation from
    ## hanging under outline at its plane, outline straight between whole degrees.
    ##   Arithmetic written out, since compile time pays for each call.
    let
      (c, s) = (cos(θ * PI / 180.0), sin(θ * PI / 180.0))
      (x, y, z) = (AXES_MEAN[2].x * c + across.x * s, AXES_MEAN[2].y * c + across.y * s,
                   AXES_MEAN[2].z * c + across.z * s)
      plane = arctan2(y, x) * 180.0 / PI + 180.0
      i = min(int(plane), OUTLINE_ADULTS.high - 1)
    arccos(clamp(-z, -1.0, 1.0)) * 180.0 / PI <=
        OUTLINE_ADULTS[i] + (OUTLINE_ADULTS[i + 1] - OUTLINE_ADULTS[i]) * (plane - float(i))

  func crossing(held, left: float, across: Vector): float =
    ## Narrow crossing between `held`, which union holds, and `left`, which it does not.
    var (inner, outer) = (held, left)
    for _ in 1..HALVINGS_ADULTS:
      let middle = (inner + outer) / 2.0
      if isHeld(middle, across): inner = middle else: outer = middle
    inner

  # Stride out from pole; close each break narrower than `BREAK_ADULTS`, end at first wider.
  let across = AXES_MEAN[0] * cos(toRadians(φ)) + AXES_MEAN[1] * sin(toRadians(φ))
  var
    θ = 0.0
    stopped: Option[float]
  while θ + STRIDE_ADULTS <= 180.0:
    θ += STRIDE_ADULTS
    let is_held = isHeld(θ, across)
    if stopped.isNone:
      if not is_held: stopped = some(crossing(θ - STRIDE_ADULTS, θ, across))
    elif is_held:
      if crossing(θ, θ - STRIDE_ADULTS, across) - stopped.get >= BREAK_ADULTS: return stopped.get
      stopped = none(float)
    elif θ - stopped.get >= BREAK_ADULTS: return stopped.get
  stopped.get(180.0)

func knotsTraced(): seq[Knot] {.compileTime.} =
  ## Trace adults' edge at knots `STEP_ADULTS` apart over `SPAN_ADULTS`, and between two knots
  ## wherever their chord misses trace at its middle by over `CHORD_ADULTS`, down to knots
  ## `NARROWEST_ADULTS` apart.  In order of meridian.
  ##   Middle alone is read, so feature that spares middle of its chord goes unseen; suite reads
  ##     edge every hundredth of degree.
  func split(a, z: Knot, knots: var seq[Knot]) =
    ## Put knots between `a` and `z`, in order, while chord misses trace.
    if z.φ - a.φ <= NARROWEST_ADULTS: return
    let middle = (φ: (a.φ + z.φ) / 2.0, θ: edgeTraced((a.φ + z.φ) / 2.0))
    if abs(middle.θ - (a.θ + z.θ) / 2.0) <= CHORD_ADULTS: return
    split(a, middle, knots)
    knots.add middle
    split(middle, z, knots)

  # Trace even knots, then split each chord that misses.
  let count = int(round((SPAN_ADULTS.upper - SPAN_ADULTS.lower) / STEP_ADULTS))
  result.add (φ: SPAN_ADULTS.lower, θ: edgeTraced(SPAN_ADULTS.lower))
  for k in 1..count:
    let
      φ = SPAN_ADULTS.lower + STEP_ADULTS * float(k)
      (a, z) = (result[^1], (φ: φ, θ: edgeTraced(φ)))
    split(a, z, result)
    result.add z

const
  TRACED_ADULTS = knotsTraced()
    ## Knots of adults' edge as trace finds them, at compile time alone, so `EDGES_ADULTS`
    ## knows its length.
  EDGES_ADULTS* = block:
    ## Adults' edge over `SPAN_ADULTS`, knot by knot in order of meridian, degrees: where union
    ## of Haering's sixteen adults ends along each meridian of mean joint axes (Fig. 15a, p. 59).
    var edges: array[TRACED_ADULTS.len, Knot]
    for i, knot in TRACED_ADULTS: edges[i] = knot
    edges


func edgeAdults*(φ: float): float =
  ## Read edge of adults' union on meridian `φ` of `SPAN_ADULTS`, radians, straight between
  ## knots of `EDGES_ADULTS`.
  let degrees = clamp(toDegrees(φ), SPAN_ADULTS.lower, SPAN_ADULTS.upper)

  # Halve knots down to two either side of meridian.
  var (low, high) = (EDGES_ADULTS.low, EDGES_ADULTS.high)
  while high - low > 1:
    let middle = (low + high) div 2
    if EDGES_ADULTS[middle].φ <= degrees: low = middle else: high = middle
  let (a, z) = (EDGES_ADULTS[low], EDGES_ADULTS[high])
  toRadians(a.θ + (z.θ - a.θ) * (degrees - a.φ) / (z.φ - a.φ))

func edge*(φ: float): Edge =
  ## Read edge on meridian `φ`, radians: men's, and adults' where they also decide and went
  ## further.
  let men = edgeMen(φ)
  if isSpanAdults(φ):
    let adults = edgeAdults(φ)
    if adults > men: return Edge(θ: adults, source: Source.Adults)
  Edge(θ: men, source: Source.Men)


func outside*(direction: Vector): Outside =
  ## Read how far direction in body's mirrored terms lies past edge on its meridian.
  let
    polar = toPolar(direction)
    bound = edge(polar.φ)
  result.angle = polar.θ - bound.θ
  result.source =
    if polar.θ <= edgeMen(polar.φ): Source.Men
    elif result.angle <= 0.0: Source.Adults
    else: bound.source

func outside*(axes: Axes, arm: Arm, pose: ArmPose): Outside =
  ## Read how far upper arm of `pose` lies past edge, left arm in mirror.
  outside(ownTerms(axes, arm, pose.elbow) - ownTerms(axes, arm, pose.shoulder))

func isInside*(reading: Outside): bool = reading.angle <= 0.0
  ## Decide whether direction is allowed: on edge or inside it.
