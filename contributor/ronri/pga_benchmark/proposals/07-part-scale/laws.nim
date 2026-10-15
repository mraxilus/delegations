## Hold comparison and grade among moved objects at every distance from origin, and weigh noise
##   each rule sees (`part-scale`).
##   Evaluation compiles this against changed library at rga3d, rga4d, cga4d and cga5d, at
##     default width and at 32 bits; exit code is verdict: every law below holds, or program
##     stops on assertion.
##   Rigid laws, at rga4d: point moved twice equals point moved once by composed motor; join
##     moved equals join of moved points; meet moved equals meet of moved planes; moved point
##     keeps grade one; plane whose normal turns by ten tolerances never equals plane it came from.
##   Laws of grade, in each algebra: multivector with coefficient not finite equals nothing, and
##     one with infinite coefficient holds no grade. At 64 bits, `grade` reads every element of
##     each population, reads it right, and agrees on it with its twin here. Twin is part scale
##     in RGA, and in CGA part scale or 16 rounding units of largest coefficient.
##   Mixed populations: motion operators, products of two of them, general multivectors; in CGA
##     products of two spheres; at cga5d transversions and dilations. One-grade populations:
##     objects moved once or 30 times, k-vectors; in CGA round objects moved by conformal motion
##     operator, and spheres of every radius.
##   Figures it prints are evidence that never gates. Rigid figure is most decimal places one
##     rule keeps with no noise in any sample: "pin" weighs coefficient against max(1, |x|, |y|),
##     as pin does and P06 alone does at 32 bits; "P07" weighs it against largest absolute value
##     of its part, bulk or weight, in either. Population figure is misreads of each zero test, as
##     `Test` names each.
##   Rigid scene sits at distance from origin: each coordinate and translation is Gaussian, with
##     deviation distance / sqrt(3). Population scene draws each coordinate with deviation of its
##     row, so its points lie about that deviation times square root of coordinate count away.
##   Helpers `largest`, `partOf` and `unitizeAntidot` serve as P11's `laws.nim` ones do; here
##     `partOf` returns index of part, and RGA uses two. Proposal does not build on P11.
##   Rigid helpers `moved`, `sampleCoordinate`, `sampleDirection`, `samplePlane` and `sampleMotor`
##     mirror those of P06's `noise.nim`, and `noisePin` mirrors `noise` there; fix to one reaches
##     each. Here `samplePoint` takes deviation of each coordinate, so rigid laws pass distance /
##     sqrt(3) and draw what `samplePoint` of P06 draws.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[fenv, math, options, random, strformat]

import pga


type
  Test {.pure.} = enum  ## Define zero test that tells one grade from mixed.
    Pin = "pin"  ## Count coefficient at most tolerance as zero, as pin does.
    ScalePart = "part"  ## Scale tolerance by largest absolute value of its part, at least one.
    ScaleLargest = "largest"  ## Scale tolerance by largest coefficient.
    Rounding16 = "part or 16"  ## Take larger of part bound and 16 rounding units of largest.
    Rounding256 = "part or 256"  ## Take larger of part bound and 256 rounding units of largest.
    Rounding4096 = "part or 4096"  ## Take larger of part bound and 4096 rounding units.
    Library = "grade"  ## Read `grade` of changed library.

  KindObject = tuple[name: string, count_points: int, is_flat: bool]
    ## Define kind of object: points it wedges, and whether it is flat; in CGA flat one wedges
    ##   infinity too.

const
  SAMPLES = 4096  ## Samples of each rigid law at each distance.
  DISTANCES = [1.0, 10.0, 100.0, 1e3, 1e4, 1e5, 1e6]  ## Distance of scene from origin, in units.
  SEED = 0  ## Seed of sample generator, so every run reads same objects.
  LAWS = ["move_twice", "join_then_move", "meet_then_move"]  ## Laws of equality, in order.
  SAMPLES_POPULATION = 1024  ## Elements of each population at each deviation.
  DEVIATIONS = [1.0, 1e2, 1e3, 1e4, 3e4, 1e5, 1e6, 1e8]  ## Deviation of each coordinate, in units.
  DEVIATIONS_KEPT = [1.0, 1e2, 1e4]  ## Deviations of objects moved from move to move.
  RADII = [1.0, 1e1, 1e2, 1e3, 1e4, 1e5, 1e6]  ## Radius of sphere about its center, in units.
  MOVES_KEPT = 30  ## Moves of object kept from move to move, unitized after each.
  NAME_ALGEBRA = (when IS_CONFORMAL: "cga" else: "rga") & $DIMENSIONS & "d"
    ## Name algebra of build.
  TWIN = (when IS_CONFORMAL: Test.Rounding16 else: Test.ScalePart)
    ## Name test that `grade` of changed library must agree with on every element.

static:
  doAssert (IS_RIGID and DIMENSIONS in 3..4) or (IS_CONFORMAL and DIMENSIONS in 4..5),
    &"Laws hold rga3d, rga4d, cga4d and cga5d; got `{NAME_ALGEBRA}`."


func `$`(g: Grade): string {.borrow.}
  ## Print grade as its integer, so message echoes it.


func moved(x, product: Multivector): Multivector =
  ## Move object by unit motion or reflection operator through antisandwich, i.e. 𝐐 ⟇ 𝐱 ⟇ ~∘𝐐.
  (product ⟇ x) ⟇ ~∘product


func largest(m: Multivector): float =
  ## Get largest absolute coefficient of multivector.
  for b in Basis: result = max(result, abs(float(m[b])))


func isReadable(m: Multivector): bool =
  ## Tell whether multivector is nonzero and finite, so zero test can read it.
  for b in Basis:
    let coefficient = abs(float(m[b]))
    if coefficient != coefficient or coefficient == Inf: return false
  m.largest > 0


func partOf(b: Basis): int =
  ## Get part of basis, as `CAYLEYS_PARTS` splits it: by origin it holds, and in CGA by infinity.
  let has_origin = (initElement(b) ∧ initElement(Basis.origin)).largest == 0
  when IS_CONFORMAL:
    let has_infinity = (initElement(b) ∧ initElement(Basis.infinity)).largest == 0
    2 * int(has_infinity) + int(has_origin)
  else: int(has_origin)


func isOneGrade(m: Multivector, test: Test, parts: array[Basis, int]): bool =
  ## Tell whether test reads multivector as one grade.
  if test == Test.Library: return m.grade.isSome
  var scales = [1.0, 1.0, 1.0, 1.0]
  for b in Basis: scales[parts[b]] = max(scales[parts[b]], abs(float(m[b])))
  let rounding = epsilon(Coefficient) * m.largest
  var
    found_grade = false
    grade_first = Grade.low
  for b in Basis:
    let
      bound_part = float(TOLERANCE_ABS) * scales[parts[b]]
      bound = case test
        of Test.Pin: float(TOLERANCE_ABS)
        of Test.ScalePart: bound_part
        of Test.ScaleLargest: float(TOLERANCE_ABS) * m.largest
        of Test.Rounding16: max(bound_part, 16 * rounding)
        of Test.Rounding256: max(bound_part, 256 * rounding)
        of Test.Rounding4096: max(bound_part, 4096 * rounding)
        of Test.Library: 0.0
    if abs(float(m[b])) <= bound: continue
    if not found_grade:
      found_grade = true
      grade_first = b.grade
    elif grade_first != b.grade: return false
  true


func unitizeAntidot(element: Multivector): Multivector =
  ## Scale element so that its antidot square is ±𝟙: unit motion, reflection or flat weight.
  element * Coefficient(1 / sqrt(abs(float((element ∘ element)[Basis.scalarAnti]))))


func unitized(m: Multivector, kind: KindObject): Multivector =
  ## Divide object by its flat weight norm if flat, else by its round weight norm.
  if kind.is_flat: m.unitizeAntidot
  else: m * Coefficient(1 / sqrt(float((`|∘²`m)[Basis.scalarAnti])))


func pointAt(position: array[3, float]): Multivector =
  ## Get point at position: round point of radius zero in CGA, unit point in RGA.
  var
    distance_squared = 0.0
    i = 0
  for b in Basis.scalar.succ..Basis.origin.pred:
    result[b] = Coefficient(position[i])
    distance_squared += position[i]^2
    inc i
  result[Basis.origin] = 1
  when IS_CONFORMAL: result[Basis.infinity] = Coefficient(distance_squared / 2)


proc sampleDirection(): array[3, float] =
  ## Sample unit direction in space of algebra, Gaussian vector normalized.
  var length = 0.0
  for i in 0 ..< ord(Basis.origin) - 1:
    result[i] = gauss()
    length += result[i]^2
  for i in 0 ..< ord(Basis.origin) - 1: result[i] /= sqrt(length)


proc samplePoint(deviation: float): Multivector =
  ## Sample point whose coordinates are Gaussian with deviation.
  var position: array[3, float]
  for i in 0 ..< ord(Basis.origin) - 1: position[i] = gauss() * deviation
  pointAt(position)


proc sampleObject(kind: KindObject, deviation: float): Multivector =
  ## Sample object through points of deviation.
  result = samplePoint(deviation)
  for _ in 2..kind.count_points: result = result ∧ samplePoint(deviation)
  when IS_CONFORMAL:
    if kind.is_flat: result = result ∧ initElement(Basis.infinity)


proc sampleMotion(deviation: float): Multivector =
  ## Sample unit rigid motion operator, product of two flat planes through points of deviation.
  let plane: KindObject = ("plane", ord(Basis.origin) - 1, true)
  unitizeAntidot(sampleObject(plane, deviation) ⟇ sampleObject(plane, deviation))


proc sampleMovedKept(kind: KindObject, deviation: float): Multivector =
  ## Sample object, then move it by rigid motion operators, unitizing after each move.
  result = sampleObject(kind, deviation)
  for _ in 1..MOVES_KEPT: result = result.moved(sampleMotion(deviation)).unitized(kind)


proc sampleGeneral(scale: float, grade: Option[Grade]): Multivector =
  ## Sample Gaussian coefficient on every basis of grade, or on every basis, times scale.
  for b in Basis:
    if grade.isNone or b.grade == grade.get: result[b] = Coefficient(gauss() * scale)


when IS_RIGID and DIMENSIONS == 4:
  func noisePin(a, b: Multivector): float =
    ## Weigh largest difference against max(1, |x|, |y|) of its own coefficient, as pin does.
    for basis in Basis:
      let (x, y) = (float(a[basis]), float(b[basis]))
      result = max(result, abs(x - y) / max(1.0, max(abs(x), abs(y))))


  func noiseP07(a, b: Multivector): float =
    ## Weigh largest difference against largest absolute value of its part, bulk or weight, in
    ##   either.
    for (x, y) in [(∙a, ∙b), (∘a, ∘b)]:
      var scale = 1.0
      for basis in Basis: scale = max(scale, max(abs(float(x[basis])), abs(float(y[basis]))))
      for basis in Basis: result = max(result, abs(float(x[basis]) - float(y[basis])) / scale)


  func isPointPin(m: Multivector): bool =
    ## Tell whether grade of pin would read one: each slot outside point at most tolerance.
    for basis in Basis:
      if basis notin {Basis.E1, Basis.E2, Basis.E3, Basis.E4} and abs(m[basis]) > TOLERANCE_ABS:
        return false
    true


  func places(noise: float): string =
    ## Count decimal places tolerance may keep and still see no noise.
    if noise == 0: "exact" else: $int(floor(-log10(noise)))


  proc sampleCoordinate(distance: float): float =
    ## Sample one coordinate of scene at distance from origin.
    gauss(0.0, distance / sqrt(3.0))


  proc samplePlane(distance: float): Multivector =
    ## Sample unitized plane through point of scene at distance from origin.
    let
      normal = sampleDirection()
      offset = normal[0] * sampleCoordinate(distance) + normal[1] * sampleCoordinate(distance) +
          normal[2] * sampleCoordinate(distance)
    result[Basis.E423] = Coefficient(normal[0])
    result[Basis.E431] = Coefficient(normal[1])
    result[Basis.E412] = Coefficient(normal[2])
    result[Basis.E321] = Coefficient(-offset)


  proc sampleMotor(distance: float): Multivector =
    ## Sample unit motor: rotation about Gaussian angle, then translation of scene at distance.
    let (axis, angle) = (sampleDirection(), gauss(0.0, 1.5))
    var rotor, translator: Multivector
    rotor[Basis.E41] = Coefficient(axis[0] * sin(angle / 2))
    rotor[Basis.E42] = Coefficient(axis[1] * sin(angle / 2))
    rotor[Basis.E43] = Coefficient(axis[2] * sin(angle / 2))
    rotor[Basis.scalarAnti] = Coefficient(cos(angle / 2))
    translator[Basis.E23] = Coefficient(sampleCoordinate(distance) / 2)
    translator[Basis.E31] = Coefficient(sampleCoordinate(distance) / 2)
    translator[Basis.E12] = Coefficient(sampleCoordinate(distance) / 2)
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


  proc holdRigid() =
    ## Hold every rigid law at each distance, then print places each rule keeps, and grades pin
    ##   misreads.
    echo "distance law pin P07"
    for distance in DISTANCES:
      let deviation = distance / sqrt(3.0)  # Of each coordinate, as `sampleCoordinate` draws.
      var
        worst: array[LAWS.len, (float, float)]
        misread = 0
      for i in 0..<SAMPLES:
        let
          (p, q) = (samplePoint(deviation), samplePoint(deviation))
          (g, h) = (samplePlane(distance), samplePlane(distance))
          (first, second) = (sampleMotor(distance), sampleMotor(distance))
          pairs = [
            (p.moved(first).moved(second), p.moved(second ⟇ first)),
            ((^(p ∧ q)).moved(first), ^(p.moved(first) ∧ q.moved(first))),
            ((g ∨ h).moved(first), g.moved(first) ∨ h.moved(first)),
          ]
        for k, (a, b) in pairs:
          doAssert a =~ b, &"Law holds at every distance; got `{LAWS[k]}` failing at `{distance}`."
          worst[k] = (max(worst[k][0], noisePin(a, b)), max(worst[k][1], noiseP07(a, b)))
        let point_moved = p.moved(first)
        doAssert point_moved.grade.isSome and int(point_moved.grade.get) == 1,
          &"Moved point keeps grade one; got `{point_moved.grade}` at distance `{distance}`."
        if not point_moved.isPointPin: inc misread
        doAssert not (g =~ g.tilted(10 * float(TOLERANCE_ABS))),
          &"Plane turned by ten tolerances differs from its source; got equal at `{distance}`."
      for k, law in LAWS:
        echo distance, " ", law, " ", places(worst[k][0]), " ", places(worst[k][1])
      echo distance, " grade_misread_pin ", misread, " of ", SAMPLES


when IS_CONFORMAL:
  proc sampleReflector(): Multivector =
    ## Sample random element of antigrade one: sphere or plane.
    for b in Basis:
      if b.grade == Grade.high.pred: result[b] = Coefficient(gauss())


  proc sampleMotionConformal(): Multivector =
    ## Sample unit conformal motion operator, product of three pairs of random reflections.
    result = unitizeAntidot(sampleReflector() ⟇ sampleReflector())
    for _ in 1..2: result = unitizeAntidot(sampleReflector() ⟇ sampleReflector()) ⟇ result


  proc sampleSphere(center, radius: float): Multivector =
    ## Sample unitized sphere through points at radius about center, which lies at distance.
    let toward = sampleDirection()
    for i in 1..<DIMENSIONS:
      let around = sampleDirection()
      var position: array[3, float]
      for j in 0 ..< DIMENSIONS - 2: position[j] = center * toward[j] + radius * around[j]
      result = (if i == 1: pointAt(position) else: result ∧ pointAt(position))
    result = result.unitized(("sphere", DIMENSIONS - 1, false))


when IS_CONFORMAL and DIMENSIONS == 5:
  proc sampleTransversion(size: float): Multivector =
    ## Sample transversion of size in random direction, as Lengyel's wiki writes it.
    let toward = sampleDirection()
    result[Basis.E423] = Coefficient(size * toward[0] / 2)
    result[Basis.E431] = Coefficient(size * toward[1] / 2)
    result[Basis.E412] = Coefficient(size * toward[2] / 2)
    result[Basis.scalarAnti] = 1


  proc sampleDilation(factor: float): Multivector =
    ## Sample unitized dilation by factor about random unit center, as Lengyel's wiki writes it.
    let center = sampleDirection()
    result[Basis.E235] = Coefficient((1 - factor) / 2 * center[0])
    result[Basis.E315] = Coefficient((1 - factor) / 2 * center[1])
    result[Basis.E125] = Coefficient((1 - factor) / 2 * center[2])
    result[Basis.E321] = Coefficient(-(1 - factor) / 2)
    result[Basis.scalarAnti] = Coefficient((1 + factor) / 2)
    result = result.unitizeAntidot


func kinds(): seq[KindObject] =
  ## List objects of every grade: round then flat in CGA, flat in RGA.
  when IS_CONFORMAL:
    for count in 1..<DIMENSIONS: result.add (&"round of grade {count}", count, false)
    for count in 1 ..< DIMENSIONS - 1: result.add (&"flat of grade {count + 1}", count, true)
  else:
    for count in 1..<DIMENSIONS: result.add (&"flat of grade {count}", count, true)


proc holdNonFinite() =
  ## Hold that multivector with coefficient not finite equals nothing, itself included, where at
  ##   pin infinity equals any finite coefficient; and that one with infinite coefficient holds no
  ##   grade, wherever infinity lies.
  for b in Basis:
    for value in [Inf, NaN]:
      var element = samplePoint(1)
      element[b] = Coefficient(value)
      doAssert not (element =~ element),
        &"Multivector not finite equals nothing; got equal, holding `{value}` at `{b}`."
      if value == Inf:
        doAssert element.grade.isNone,
          &"Overflowed multivector holds no grade; got `{element.grade}` at `{b}`."


proc holdPopulations() =
  ## Read every population with each zero test, print misreads of each, and hold `grade` right on
  ##   every population at 64 bits.

  template tally(label: string, is_one_grade_expected: bool, sampled: untyped) =
    ## Sample elements of one population, then print and add misreads of each test.
    block:
      var
        misreads: array[Test, int]
        count = 0
        count_apart = 0
      for _ in 1..SAMPLES_POPULATION:
        let element = sampled
        if not element.isReadable: continue
        inc count
        for test in Test:
          if element.isOneGrade(test, parts) != is_one_grade_expected: inc misreads[test]
        if element.isOneGrade(Test.Library, parts) != element.isOneGrade(TWIN, parts):
          inc count_apart
      var line = label & ": " & $count & " read"
      for test in Test:
        line.add ", " & $test & " " & $misreads[test]
        totals[test] += misreads[test]
      echo line
      when FLOAT_WIDTH == 64:
        doAssert count == SAMPLES_POPULATION,
          "`grade` reads every element of " & label & "; got `" & $count & "` read."
        doAssert misreads[Test.Library] == 0,
          "`grade` reads " & label & " right; got `" & $misreads[Test.Library] & "` misread."
        doAssert count_apart == 0,
          "`grade` agrees with its twin on " & label & "; got `" & $count_apart & "` apart."

  var
    parts: array[Basis, int]
    totals: array[Test, int]
  for b in Basis: parts[b] = b.partOf
  echo "population: elements read, then misreads of each zero test"

  # Tally mixed populations: motion operators and their products; in CGA products of spheres,
  # and at cga5d transversions and dilations.
  for deviation in DEVIATIONS:
    tally(&"motion operator of two planes, deviation {deviation:.0e}", false,
      sampleMotion(deviation))
  for deviation in DEVIATIONS:
    tally(&"product of two motion operators, deviation {deviation:.0e}", false,
      unitizeAntidot(sampleMotion(deviation) ⟇ sampleMotion(deviation)))
  when IS_CONFORMAL:
    let sphere: KindObject = ("sphere", DIMENSIONS - 1, false)
    for deviation in DEVIATIONS:
      tally(&"product of two spheres, deviation {deviation:.0e}", false,
        unitizeAntidot(sampleObject(sphere, deviation) ⟇ sampleObject(sphere, deviation)))
  when IS_CONFORMAL and DIMENSIONS == 5:
    for deviation in DEVIATIONS:
      tally(&"transversion, size {deviation:.0e}", false, sampleTransversion(deviation))
    for deviation in DEVIATIONS[1..^1]:
      tally(&"dilation, factor {deviation:.0e}", false, sampleDilation(deviation))

  # Tally one-grade populations: objects moved once, in CGA moved conformally, and spheres.
  for kind in kinds():
    for deviation in DEVIATIONS:
      tally(&"{kind.name} moved once, deviation {deviation:.0e}", true,
        sampleObject(kind, deviation).moved(sampleMotion(deviation)).unitized(kind))
  when IS_CONFORMAL:
    for kind in kinds():
      if kind.is_flat: continue
      for deviation in DEVIATIONS:
        tally(&"{kind.name} moved by conformal motion operator, deviation {deviation:.0e}",
          true, sampleObject(kind, deviation).moved(sampleMotionConformal()).unitized(kind))
    for center in [0.0, 1e3]:
      for radius in RADII:
        tally(&"sphere at distance {center:.0e}, radius {radius:.0e}", true,
          sampleSphere(center, radius))

  # Tally kept objects, then general multivectors and k-vectors.
  for kind in kinds():
    for deviation in DEVIATIONS_KEPT:
      tally(&"{kind.name} moved {MOVES_KEPT} times, deviation {deviation:.0e}", true,
        sampleMovedKept(kind, deviation))
  for scale in [1.0, 1e6]:
    tally(&"general multivector, scale {scale:.0e}", false, sampleGeneral(scale, none(Grade)))
    for grade in Grade.low..Grade.high:
      tally(&"vector of grade {int(grade)}, scale {scale:.0e}", true,
        sampleGeneral(scale, some(grade)))
  var line = "total misreads"
  for test in Test: line.add ", " & $test & " " & $totals[test]
  echo line


proc main() =
  ## Print width of this build, then hold laws of its algebra.
  randomize(SEED)
  echo "width ", FLOAT_WIDTH, " tolerance ", FLOAT_TOLERANCE
  when IS_RIGID and DIMENSIONS == 4: holdRigid()
  holdPopulations()
  holdNonFinite()  # Last, so populations draw from seed alone.


main()
