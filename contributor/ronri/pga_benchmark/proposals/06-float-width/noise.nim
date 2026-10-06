## Measure noise each comparison sees among unitized rigid objects, at width of this build
##   (`float-width`).
##   Evaluation compiles this against changed library at rga4d, at default width and at 32
##     bits; exit code says it ran, and figures it prints are evidence that never gates.
##   Each law computes one object two ways that agree in exact arithmetic. Noise of sample is
##     largest difference `=~` weighs, over every coefficient, as share of max(1, |a|, |b|), so
##     comparison holds while noise stays at or under `TOLERANCE_ABS`.
##   Scene sits at distance from origin: each coordinate and translation is Gaussian, with
##     deviation distance / sqrt(3).
##   Places is count of decimal places tolerance may keep and still see no noise in any sample.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/[algorithm, math, random, strutils]

import pga


const
  SAMPLES = 4096  ## Samples of each law at each distance.
  DISTANCES = [1.0, 10.0, 100.0, 1e3, 1e4, 1e5, 1e6]  ## Distance of scene from origin, in units.
  SEED = 0  ## Seed of sample generator, so every run reads same objects.

static:
  doAssert DIMENSIONS == 4 and IS_RIGID, "Noise measures rigid objects in four dimensions."


func moved(x, motor: Multivector): Multivector =
  ## Move object by unit motor, as antisandwich 𝐐 ⟇ 𝐱 ⟇ ~𝐐.
  (motor ⟇ x) ⟇ ~∘motor


func noise(a, b: Multivector): float =
  ## Weigh largest difference `=~` sees between two objects, as share of its bound.
  for basis in Basis:
    let (x, y) = (float(a[basis]), float(b[basis]))
    result = max(result, abs(x - y) / max(1.0, max(abs(x), abs(y))))


proc coordinate(distance: float): float =
  ## Draw one coordinate of scene at distance from origin.
  gauss(0.0, distance / sqrt(3.0))


proc point(distance: float): Multivector =
  ## Draw unitized point of scene at distance from origin.
  result[Basis.E1] = Coefficient(coordinate(distance))
  result[Basis.E2] = Coefficient(coordinate(distance))
  result[Basis.E3] = Coefficient(coordinate(distance))
  result[Basis.E4] = 1


proc direction(): array[3, float] =
  ## Draw unit direction, Gaussian vector normalized.
  let
    (x, y, z) = (gauss(), gauss(), gauss())
    length = sqrt(x * x + y * y + z * z)
  [x / length, y / length, z / length]


proc plane(distance: float): Multivector =
  ## Draw unitized plane through point of scene at distance from origin.
  let
    normal = direction()
    offset = normal[0] * coordinate(distance) + normal[1] * coordinate(distance) +
        normal[2] * coordinate(distance)
  result[Basis.E423] = Coefficient(normal[0])
  result[Basis.E431] = Coefficient(normal[1])
  result[Basis.E412] = Coefficient(normal[2])
  result[Basis.E321] = Coefficient(-offset)


proc motor(distance: float): Multivector =
  ## Draw unit motor: rotation about Gaussian angle, then translation of scene at distance.
  let (axis, angle) = (direction(), gauss(0.0, 1.5))
  var rotor, translator: Multivector
  rotor[Basis.E41] = Coefficient(axis[0] * sin(angle / 2))
  rotor[Basis.E42] = Coefficient(axis[1] * sin(angle / 2))
  rotor[Basis.E43] = Coefficient(axis[2] * sin(angle / 2))
  rotor[Basis.scalarAnti] = Coefficient(cos(angle / 2))
  translator[Basis.E23] = Coefficient(coordinate(distance) / 2)
  translator[Basis.E31] = Coefficient(coordinate(distance) / 2)
  translator[Basis.E12] = Coefficient(coordinate(distance) / 2)
  translator[Basis.scalarAnti] = 1
  translator ⟇ rotor


proc report(law: string, distance: float, noises: var seq[float]) =
  ## Print median and largest noise of law at distance, and places that see none.
  noises.sort
  let
    largest = noises[^1]
    places = (if largest == 0: "exact" else: $int(floor(-log10(largest))))
  echo law, " ", distance, " ", formatFloat(noises[noises.len div 2], ffScientific, 2), " ",
      formatFloat(largest, ffScientific, 2), " ", places


proc main() =
  ## Print width of this build, then noise of each law at each distance.
  randomize(SEED)
  echo "width ", FLOAT_WIDTH, " tolerance ", FLOAT_TOLERANCE
  for distance in DISTANCES:
    var twice, join, meet, incidence = newSeq[float](SAMPLES)
    for i in 0..<SAMPLES:
      let
        (p, q, g, h) = (point(distance), point(distance), plane(distance), plane(distance))
        (first, second) = (motor(distance), motor(distance))
      twice[i] = noise(p.moved(first).moved(second), p.moved(second ⟇ first))
      join[i] = noise((^(p ∧ q)).moved(first), ^(p.moved(first) ∧ q.moved(first)))
      meet[i] = noise((g ∨ h).moved(first), g.moved(first) ∨ h.moved(first))
      let r = p + Coefficient(rand(1.0)) * (q - p)
      incidence[i] = noise(^(p ∧ q) ∧ r, Multivector())
    report("move_twice", distance, twice)
    report("join_then_move", distance, join)
    report("meet_then_move", distance, meet)
    report("point_on_line", distance, incidence)


main()
