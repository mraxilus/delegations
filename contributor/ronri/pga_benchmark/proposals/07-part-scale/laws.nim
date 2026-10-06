## Hold comparison among unitized rigid objects at every distance from origin, and weigh noise
##   each rule sees (`part-scale`).
##   Evaluation compiles this against changed library at rga4d, at default width and at 32
##     bits; exit code is verdict: every law below holds, or program stops on assertion.
##   Laws: point moved twice equals point moved once by composed motor; join moved equals join
##     of moved points; meet moved equals meet of moved planes; moved point keeps grade one;
##     plane whose normal turns by ten tolerances never equals plane it came from.
##   Figures it prints are evidence that never gates. Each is most decimal places one rule keeps
##     with no noise in any sample: "now" weighs coefficient against max(1, |x|, |y|), as pin
##     does; "part" weighs it against largest magnitude of its part, bulk or weight, in either.
##   Scene sits at distance from origin: each coordinate and translation is Gaussian, with
##     deviation distance / sqrt(3).

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/[math, options, random, strformat]

import pga


const
  SAMPLES = 4096  ## Samples of each law at each distance.
  DISTANCES = [1.0, 10.0, 100.0, 1e3, 1e4, 1e5, 1e6]  ## Distance of scene from origin, in units.
  SEED = 0  ## Seed of sample generator, so every run reads same objects.
  LAWS = ["move_twice", "join_then_move", "meet_then_move"]  ## Laws of equality, in order.

static:
  doAssert DIMENSIONS == 4 and IS_RIGID, "Laws hold rigid objects in four dimensions."


func moved(x, motor: Multivector): Multivector =
  ## Move object by unit motor, as antisandwich 𝐐 ⟇ 𝐱 ⟇ ~𝐐.
  (motor ⟇ x) ⟇ ~∘motor


func noiseNow(a, b: Multivector): float =
  ## Weigh largest difference against max(1, |x|, |y|) of its own coefficient, as pin does.
  for basis in Basis:
    let (x, y) = (float(a[basis]), float(b[basis]))
    result = max(result, abs(x - y) / max(1.0, max(abs(x), abs(y))))


func noisePart(a, b: Multivector): float =
  ## Weigh largest difference against largest magnitude of its part, bulk or weight, in either.
  for (x, y) in [(∙a, ∙b), (∘a, ∘b)]:
    var scale = 1.0
    for basis in Basis: scale = max(scale, max(abs(float(x[basis])), abs(float(y[basis]))))
    for basis in Basis: result = max(result, abs(float(x[basis]) - float(y[basis])) / scale)


func isPointNow(m: Multivector): bool =
  ## Tell whether grade of pin would read one: each slot outside point at most tolerance.
  for basis in Basis:
    if basis notin {Basis.E1, Basis.E2, Basis.E3, Basis.E4} and abs(m[basis]) > TOLERANCE_ABS:
      return false
  true


func places(noise: float): string =
  ## Count decimal places tolerance may keep and still see no noise.
  if noise == 0: "exact" else: $int(floor(-log10(noise)))


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


func tilted(g: Multivector, angle: float): Multivector =
  ## Turn unit normal of plane by angle toward axis at right angle to it, keeping its position.
  let
    n = [float(g[Basis.E423]), float(g[Basis.E431]), float(g[Basis.E412])]
    seed = (if abs(n[0]) < 0.9: [1.0, 0.0, 0.0] else: [0.0, 1.0, 0.0])
    along = seed[0] * n[0] + seed[1] * n[1] + seed[2] * n[2]
    side = [seed[0] - along * n[0], seed[1] - along * n[1], seed[2] - along * n[2]]
    length = sqrt(side[0] * side[0] + side[1] * side[1] + side[2] * side[2])
  result = g
  result[Basis.E423] = Coefficient(n[0] * cos(angle) + side[0] / length * sin(angle))
  result[Basis.E431] = Coefficient(n[1] * cos(angle) + side[1] / length * sin(angle))
  result[Basis.E412] = Coefficient(n[2] * cos(angle) + side[2] / length * sin(angle))


proc main() =
  ## Hold every law at each distance, then print places each rule keeps, and grades pin misreads.
  randomize(SEED)
  echo "width ", FLOAT_WIDTH, " tolerance ", FLOAT_TOLERANCE
  echo "distance law now part"
  for distance in DISTANCES:
    var
      worst: array[LAWS.len, (float, float)]
      misread = 0
    for i in 0..<SAMPLES:
      let
        (p, q, g, h) = (point(distance), point(distance), plane(distance), plane(distance))
        (first, second) = (motor(distance), motor(distance))
        pairs = [
          (p.moved(first).moved(second), p.moved(second ⟇ first)),
          ((^(p ∧ q)).moved(first), ^(p.moved(first) ∧ q.moved(first))),
          ((g ∨ h).moved(first), g.moved(first) ∨ h.moved(first)),
        ]
      for k, (a, b) in pairs:
        doAssert a =~ b, &"Law {LAWS[k]} holds at distance {distance}."
        worst[k] = (max(worst[k][0], noiseNow(a, b)), max(worst[k][1], noisePart(a, b)))
      let point_moved = p.moved(first)
      doAssert point_moved.grade.isSome and int(point_moved.grade.get) == 1,
          &"Moved point keeps grade one at distance {distance}."
      if not point_moved.isPointNow: inc misread
      doAssert not (g =~ g.tilted(10 * float(TOLERANCE_ABS))),
          &"Plane turned by ten tolerances differs at distance {distance}."
    for k, law in LAWS:
      echo distance, " ", law, " ", places(worst[k][0]), " ", places(worst[k][1])
    echo distance, " grade_misread_now ", misread, " of ", SAMPLES


main()
