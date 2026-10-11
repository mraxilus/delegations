## Hold laws of one unitize rule for any element (`unitize-general`).
##   Evaluation compiles this against changed library at each algebra its claim names; exit code
##     is verdict: every law below holds, or program stops on assertion.
##   Rule: element divides by √|𝐮∘𝐮|, as rigid unitization does; in CGA, round object divides by
##     its round weight norm instead, which is weight of its carrier 𝐮 ∧ 𝐞∞.
##   Laws: each kind Lengyel unitizes ends at unit weight; product of reflections ends at unit
##     versor; rule is homogeneous of degree one; rule commutes with rigid motion; flat has
##     𝐮∘𝐮 = ‖𝐮‖□²; unit versor keeps 𝐮∘𝐮; in CGA, element and each of its duals share divisor;
##     sphere tends to plane through jump no rule escapes;
##     plane sent through sphere and back keeps flat weight; round object moved far from origin
##     keeps round weight; each unit operator form of Lengyel's wiki divides by 1, and dilation by
##     √σ.
##   Figures it prints are evidence that never gates: worst error of each law, how each other
##     test of round object fares on same moved objects, and how motion moves element whose
##     residue lies near tolerance of grade test across it.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[math, random, strformat]

import pga


type KindObject {.pure.} = enum  ## Define kind of drawn object, as rule must treat it.
  Round  ## Round object, unitized by round weight in CGA.
  Flat  ## Flat object, unitized by flat weight in CGA and by weight in RGA.
  Operator  ## Motor or flector, unitized as versor.

when IS_CONFORMAL:
  type Selector {.pure.} = enum  ## Define test that tells round object from any other element.
    Exact = "exact grade scan"  ## Count any nonzero coefficient.
    AbsoluteAtPin = "grade at pin, 1e-9 absolute"  ## Count coefficient past 1e-9.
    Antiscalar = "antiscalar part is zero"  ## Read round object as one with no 𝟙 part.
    PartScale = "grade of P07, each part at its own scale"  ## Scale each part, at least one.
    Relative = "P11, 1e-9 of largest coefficient"  ## Scale by largest coefficient.

  type Part {.pure.} = enum  ## Define part of basis, by origin and infinity it holds.
    BulkRound  ## Neither origin nor infinity.
    WeightRound  ## Origin, not infinity.
    BulkFlat  ## Infinity, not origin.
    WeightFlat  ## Origin and infinity.


const
  SAMPLES = 2000  ## Samples of each law.
  SEED = 0  ## Seed of sample generator, so every run reads same elements.
  SCALES = [1e-100, -1e-8, 3.0, -1e8, 1e100]  ## Factors homogeneity is checked under.
  TOLERANCE_LAW = 1e-9  ## Largest relative error each law admits.
  REFLECTIONS_BACK = 10000  ## Planes sent through sphere and back.
  STEPS_FAMILY = [1.0, 1e-2, 1e-4, 1e-6, 1e-8, 0.0]  ## Weights of sphere in pencil toward plane.
  SIZES_SCENE = [1.0, 1e8]  ## Distances from origin of scenes whose objects move.
  SAMPLES_MOVED = 256  ## Moved round objects each test reads, at each distance.
  SAMPLES_BAND = 20000  ## Rotated round points whose residue lies just past grade tolerance.


func largest(m: Multivector): float =
  ## Get largest absolute coefficient of multivector.
  for b in Basis: result = max(result, abs(m[b]))


func difference(m, n: Multivector): float =
  ## Get largest absolute difference of coefficients over largest coefficient of first.
  for b in Basis: result = max(result, abs(m[b] - n[b]))
  result /= m.largest


func divisor(m: Multivector): float =
  ## Read divisor rule applies, as ratio of largest coefficients before and after.
  m.largest / (^m).largest


func dotAntiSelf(m: Multivector): float =
  ## Get antiscalar part of antidot product of multivector with itself.
  (m ∘ m)[Basis.scalarAnti]


func normWeightRound(m: Multivector): float =
  ## Get round weight norm, or weight norm in RGA.
  sqrt((`|∘²`m)[Basis.scalarAnti])


func versorUnit(versor: Multivector): Multivector =
  ## Scale versor so that its antidot square is ±𝟙.
  versor * (1 / sqrt(abs(versor.dotAntiSelf)))


func moved(element, versor: Multivector): Multivector =
  ## Move element by versor, as antisandwich 𝐯 ⟇ 𝐮 ⟇ ~𝐯.
  (versor ⟇ element) ⟇ ~∘versor


proc drawPoint(spread = 1.0): Multivector =
  ## Draw point at random position: round point of radius zero in CGA, unit point in RGA.
  var distance_squared = 0.0
  for b in Basis.scalar.succ .. Basis.origin.pred:
    result[b] = gauss() * spread
    distance_squared += result[b]^2
  result[Basis.origin] = 1
  when IS_CONFORMAL: result[Basis.infinity] = distance_squared / 2


proc drawReflector(): Multivector =
  ## Draw random element of antigrade one: sphere or plane in CGA, plane in RGA.
  for b in Basis:
    if b.grade == Grade.high.pred: result[b] = gauss()


proc drawPlane(): Multivector =
  ## Draw plane through random points; plane is flat in CGA.
  result = drawPoint()
  when IS_CONFORMAL:
    for _ in 2 ..< DIMENSIONS - 1: result = result ∧ drawPoint()
    result = result ∧ Basis.infinity.initElement()
  else:
    for _ in 2 ..< DIMENSIONS: result = result ∧ drawPoint()


proc drawMotor(): Multivector =
  ## Draw unit rigid motor as product of two planes.
  versorUnit(drawPlane() ⟇ drawPlane())


proc drawObjects(): seq[tuple[name: string, element: Multivector, kind: KindObject]] =
  ## Draw one object of each kind Lengyel unitizes, with its name and kind.
  var element = drawPoint()
  for grade in 1 ..< DIMENSIONS:
    when IS_CONFORMAL:
      result.add (&"round of grade {grade}", element, KindObject.Round)
      if grade < DIMENSIONS - 1:
        result.add (&"flat of grade {grade + 1}", element ∧ Basis.infinity.initElement(),
          KindObject.Flat)
    else:
      result.add (&"flat of grade {grade}", element, KindObject.Flat)
    element = element ∧ drawPoint()
  result.add ("motor", drawPlane() ⟇ drawPlane(), KindObject.Operator)
  result.add ("flector", drawPlane() ⟇ drawPlane() ⟇ drawPlane(), KindObject.Operator)


proc drawElements(): seq[Multivector] =
  ## Draw objects of every kind, versors, and general multivectors of every grade.
  for (_, element, _) in drawObjects(): result.add element
  result.add drawReflector() ⟇ drawReflector()
  var general: Multivector
  for b in Basis: general[b] = gauss()
  result.add general


proc holdKinds(): float =
  ## Hold each kind at unit weight after unitize: round weight for round, flat weight for flat.
  for _ in 1..SAMPLES:
    for (name, element, kind) in drawObjects():
      let unit = ^(gauss() * 3 * element)
      when IS_CONFORMAL:
        let weight = case kind
          of KindObject.Round: unit.normWeightRound
          of KindObject.Operator: sqrt(abs(unit.dotAntiSelf))
          of KindObject.Flat: sqrt((`|□²`unit)[Basis.scalarAnti])
      else:
        let weight = unit.normWeightRound
      result = max(result, abs(weight - 1))
      doAssert abs(weight - 1) < TOLERANCE_LAW, &"{name} unitizes to weight; got `{weight}`."


proc holdVersors(): float =
  ## Hold products of two and four reflections at unit antidot square after unitize.
  for _ in 1..SAMPLES:
    for count in [2, 4]:
      var versor = drawReflector()
      for _ in 2..count: versor = versor ⟇ drawReflector()
      let square = abs((^(gauss() * 3 * versor)).dotAntiSelf)
      result = max(result, abs(square - 1))
      doAssert abs(square - 1) < TOLERANCE_LAW, &"versor unitizes to unit; got `{square}`."


proc holdHomogeneity(): float =
  ## Hold unitize(λ𝐮) = sign(λ) unitize(𝐮): divisor scales by |λ|, and branch stays.
  for _ in 1..SAMPLES:
    for element in drawElements():
      when IS_CONFORMAL:
        if abs(element.dotAntiSelf) == 0 and element.normWeightRound == 0: continue
      for scale in SCALES:
        let error = difference(float(sgn(scale)) * ^element, ^(scale * element))
        result = max(result, error)
        doAssert error < TOLERANCE_LAW, &"unitize is homogeneous; got `{error}` at `{scale}`."


proc holdCovariance(): float =
  ## Hold unitize(𝐌 ⟇ 𝐮 ⟇ ~𝐌) = 𝐌 ⟇ unitize(𝐮) ⟇ ~𝐌 for unit rigid motor 𝐌.
  for _ in 1..SAMPLES:
    let motor = drawMotor()
    for element in drawElements():
      let error = difference(element.moved(motor).`^`, (^element).moved(motor))
      result = max(result, error)
      doAssert error < TOLERANCE_LAW, &"unitize commutes with rigid motion; got `{error}`."


when IS_CONFORMAL:
  func isHoldingInfinity(b: Basis): bool =
    ## Tell whether basis holds infinity, as its wedge with infinity vanishes.
    (b.initElement() ∧ Basis.infinity.initElement()).largest == 0


  func isHoldingOrigin(b: Basis): bool =
    ## Tell whether basis holds origin, as its wedge with origin vanishes.
    (b.initElement() ∧ Basis.origin.initElement()).largest == 0


  func partOf(b: Basis): Part =
    ## Get part of basis, by origin and infinity it holds.
    Part(2 * int(b.isHoldingInfinity) + int(b.isHoldingOrigin))


  func divisorExact(m: Multivector): float =
    ## Read divisor of rule whose round test compares round weight with zero exactly.
    let round = (`|∘²`m)[Basis.scalarAnti]
    var
      found_grade = false
      grade_first = Grade.low
      is_grade_single = true
      scale = 0.0
    for b in Basis: scale = max(scale, abs(m[b]))
    for b in Basis:
      if abs(m[b]) <= TOLERANCE_ABS * scale: continue
      if not found_grade:
        found_grade = true
        grade_first = b.grade
      elif grade_first != b.grade: is_grade_single = false
    sqrt(if round != 0 and is_grade_single: round else: abs(m.dotAntiSelf))


  func isGradeSingle(m: Multivector, selector: Selector): bool =
    ## Tell whether multivector holds one grade, as selector reads zero.
    var
      scales: array[Part, float] = [1.0, 1.0, 1.0, 1.0]
      scale = 0.0
      found_grade = false
      grade_first = Grade.low
    for b in Basis:
      scale = max(scale, abs(m[b]))
      scales[b.partOf] = max(scales[b.partOf], abs(m[b]))
    for b in Basis:
      let floor = case selector
        of Selector.Exact, Selector.Antiscalar: 0.0
        of Selector.AbsoluteAtPin: TOLERANCE_ABS
        of Selector.PartScale: TOLERANCE_ABS * scales[b.partOf]
        of Selector.Relative: TOLERANCE_ABS * scale
      if abs(m[b]) <= floor: continue
      if not found_grade:
        found_grade = true
        grade_first = b.grade
      elif grade_first != b.grade: return false
    true


  func divisorBy(m: Multivector, selector: Selector): float =
    ## Read divisor of rule whose round object test is selector's.
    let
      round = (`|∘²`m)[Basis.scalarAnti]
      radius = abs(m.dotAntiSelf)
      is_round = if selector == Selector.Antiscalar: round != 0 and m[Basis.scalarAnti] == 0
        else: m.isGradeSingle(selector) and round > TOLERANCE_ABS^2 * radius
    sqrt(if is_round: round else: radius)


  proc holdIdentities(): tuple[error_flat, error_versor: float] =
    ## Hold 𝐮∘𝐮 = ‖𝐮‖□² for flat 𝐮, and 𝐮∘𝐮 kept by unit versor 𝐯 for any 𝐮.
    for _ in 1..SAMPLES:
      for (_, element, kind) in drawObjects():
        if kind != KindObject.Flat: continue
        let flat = (`|□²`element)[Basis.scalarAnti]
        result.error_flat = max(result.error_flat, abs(element.dotAntiSelf - flat) / flat)
      let versor = versorUnit(drawReflector() ⟇ drawReflector())
      var general: Multivector
      for b in Basis: general[b] = gauss()
      let general_moved = general.moved(versor)
      result.error_versor = max(result.error_versor,
        abs(general_moved.dotAntiSelf - general.dotAntiSelf) / general_moved.largest^2)
    doAssert result.error_flat < TOLERANCE_LAW,
      &"flat has antidot of flat weight; got `{result.error_flat}`."
    doAssert result.error_versor < TOLERANCE_LAW,
      &"unit versor keeps antidot; got `{result.error_versor}`."


  proc holdDuality(): float =
    ## Hold W(★𝐮) = W(☆𝐮) = W(𝐮): each dual permutes basis up to sign, and keeps both norms.
    for _ in 1..SAMPLES:
      for element in drawElements():
        let found = element.divisor
        for dual in [★element, ☆element]:
          let error = abs(dual.divisor / found - 1)
          result = max(result, error)
          doAssert error < TOLERANCE_LAW, &"dual shares divisor of element; got `{error}`."


  proc countSelectors(): seq[tuple[selector: Selector, size: float, count: int]] =
    ## Count moved round objects each test unitizes to round weight one, near and far.
    for size in SIZES_SCENE:
      var counts: array[Selector, int]
      for _ in 1..SAMPLES_MOVED:
        var versor = versorUnit(drawReflector() ⟇ drawReflector())
        for _ in 1..2: versor = versorUnit(drawReflector() ⟇ drawReflector()) ⟇ versor
        var element = drawPoint(size)
        for _ in 2 .. 1 + rand(DIMENSIONS - 2): element = element ∧ drawPoint(size)
        let element_moved = element.moved(versor)
        for selector in Selector:
          let weight = element_moved.normWeightRound / element_moved.divisorBy(selector)
          if abs(weight - 1) < TOLERANCE_LAW: inc counts[selector]
      for selector in Selector: result.add (selector, size, counts[selector])
      doAssert counts[Selector.Relative] == SAMPLES_MOVED,
        &"moved round object keeps round weight; got `{counts[Selector.Relative]}`."


  proc holdPencil(): seq[float] =
    ## Hold divisor of sphere 𝐬ₜ = t𝐬 + 𝐠 at |t|, and plane's at 1: divisor jumps at t = 0.
    let plane = versorUnit(drawPlane())
    var sphere = drawPoint()
    for _ in 2 ..< DIMENSIONS: sphere = sphere ∧ drawPoint()
    sphere = ^sphere
    for step in STEPS_FAMILY:
      let found = (step * sphere + plane).divisor
      result.add found
      let expected = (if step == 0: 1.0 else: step)
      doAssert abs(found / expected - 1) < 1e-6,
        &"pencil divides by round weight, and plane by 1; got `{found}` at `{step}`."


  proc countReflectionsBack(): tuple[rule, exact: int] =
    ## Count planes sent through sphere and back that rule, and exact zero test, treat as round.
    for _ in 1..REFLECTIONS_BACK:
      let plane = versorUnit(drawPlane())
      var sphere = drawPoint()
      for _ in 2 ..< DIMENSIONS: sphere = sphere ∧ drawPoint()
      let
        back = plane.moved(sphere).moved(sphere)
        flat = sqrt((`|□²`back)[Basis.scalarAnti])
      if abs(back.divisor / flat - 1) > TOLERANCE_LAW: inc result.rule
      if abs(back.divisorExact / flat - 1) > TOLERANCE_LAW: inc result.exact
    doAssert result.rule == 0,
      &"plane sent through sphere and back keeps flat weight; got `{result.rule}`."


  when DIMENSIONS == 5:
    proc readOperators(): seq[tuple[name: string, found, expected: float]] =
      ## Read divisor of Lengyel's operator forms from his wiki, against divisor rule must give.
      let
        tau = [gauss(), gauss(), gauss()]
        angle = rand(2 * PI)
      var translation, rotation, transversion, dilation: Multivector
      translation[Basis.E235] = tau[0] / 2
      translation[Basis.E315] = tau[1] / 2
      translation[Basis.E125] = tau[2] / 2
      translation[Basis.scalarAnti] = 1
      rotation[Basis.E435] = sin(angle / 2)
      rotation[Basis.scalarAnti] = cos(angle / 2)
      transversion[Basis.E423] = tau[0] / 2
      transversion[Basis.E431] = tau[1] / 2
      transversion[Basis.E412] = tau[2] / 2
      transversion[Basis.scalarAnti] = 1
      let sigma = 3.0
      dilation[Basis.E235] = (1 - sigma) / 2 * 0.5
      dilation[Basis.E315] = (1 - sigma) / 2 * 0.25
      dilation[Basis.E125] = -(1 - sigma) / 2
      dilation[Basis.E321] = -(1 - sigma) / 2
      dilation[Basis.scalarAnti] = (1 + sigma) / 2
      var transversion_near, transversion_nearer, transversion_far: Multivector
      transversion_near[Basis.E423] = 1e-9
      transversion_near[Basis.scalarAnti] = 1
      transversion_nearer[Basis.E423] = 1e-13
      transversion_nearer[Basis.scalarAnti] = 1
      transversion_far[Basis.E423] = 2.1e9 / 2
      transversion_far[Basis.E431] = -1.05e9 / 2
      transversion_far[Basis.scalarAnti] = 1
      result = @[
        ("translation", translation.divisor, 1.0),
        ("rotation about z axis", rotation.divisor, 1.0),
        ("transversion", transversion.divisor, 1.0),
        ("dilation, sigma 3", dilation.divisor, sqrt(sigma)),
        ("transversion, half tau 1e-9", transversion_near.divisor, 1.0),
        ("transversion, half tau 1e-13", transversion_nearer.divisor, 1.0),
        ("transversion, tau (2.1e9, -1.05e9, 0)", transversion_far.divisor, 1.0),
      ]
      for (name, found, expected) in result[0..5]:
        doAssert abs(found / expected - 1) < TOLERANCE_LAW, &"{name} divides by; got `{found}`."


    proc readBand(): tuple[at_origin, translated: float, flips: int] =
      ## Read divisor of round point at origin with residue 2e-9 on 𝟙, before and after
      ##   translation by 10; count rotations about origin that move residue just past
      ##   tolerance across it, as largest coefficient grows.
      var point, translation, origin: Multivector
      point[Basis.origin] = 1
      point[Basis.scalarAnti] = 2e-9
      translation[Basis.E235] = 10 / 2
      translation[Basis.scalarAnti] = 1
      result.at_origin = point.divisor
      result.translated = point.moved(translation).divisor
      origin[Basis.origin] = 1
      for _ in 1..SAMPLES_BAND:
        var planes: array[2, Multivector]
        for plane in planes.mitems:
          plane = origin ∧ drawPoint() ∧ drawPoint() ∧ Basis.infinity.initElement()
        var element = drawPoint()
        element[Basis.scalarAnti] = 1.0000001e-9 * element.largest
        let rotated = element.moved(versorUnit(planes[0] ⟇ planes[1]))
        if abs(rotated.divisor / element.divisor - 1) > TOLERANCE_LAW: inc result.flips


proc main() =
  ## Check every law, then print worst error of each as evidence.
  randomize(SEED)
  let algebra = (if IS_CONFORMAL: "cga" else: "rga") & $DIMENSIONS & "d"
  echo &"{algebra}: kinds Lengyel unitizes, worst |weight - 1|: {holdKinds():.1e}"
  echo &"{algebra}: products of reflections, worst |antidot square - 1|: {holdVersors():.1e}"
  echo &"{algebra}: homogeneity, worst error: {holdHomogeneity():.1e}"
  echo &"{algebra}: covariance under rigid motion, worst error: {holdCovariance():.1e}"
  when IS_CONFORMAL:
    let (error_flat, error_versor) = holdIdentities()
    echo &"{algebra}: flat antidot against flat weight squared, worst error: {error_flat:.1e}"
    echo &"{algebra}: antidot kept by unit versor, worst error: {error_versor:.1e}"
    echo &"{algebra}: duality, worst relative error of divisor: {holdDuality():.1e}"
    for (selector, size, count) in countSelectors():
      echo &"{algebra}: moved round objects at distance {size:.0e}, unitized right by " &
        &"{$selector}: {count} of {SAMPLES_MOVED}"
    let pencil = holdPencil()
    for i, step in STEPS_FAMILY:
      if step == 0: echo &"{algebra}: pencil t = 0, divisor: {pencil[i]:.6f}"
      else: echo &"{algebra}: pencil t = {step:.0e}, divisor over |t|: {pencil[i] / step:.6f}"
    let (count_rule, count_exact) = countReflectionsBack()
    echo &"{algebra}: planes through sphere and back misread, rule {count_rule}, " &
      &"exact test {count_exact}, of {REFLECTIONS_BACK}"
    when DIMENSIONS == 5:
      for (name, found, expected) in readOperators():
        echo &"{algebra}: {name}, divisor {found:.6g}, expected {expected:.6g}"
      let (at_origin, translated, flips) = readBand()
      echo &"{algebra}: round point with residue 2e-9 on antiscalar, divisor at origin " &
        &"{at_origin:.3g}, translated by 10 {translated:.3g}"
      echo &"{algebra}: residue 1.0000001e-9 of largest coefficient, rotations about origin " &
        &"that change branch: {flips} of {SAMPLES_BAND}"


when isMainModule: main()
