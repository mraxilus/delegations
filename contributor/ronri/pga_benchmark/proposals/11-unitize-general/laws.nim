## Hold laws of one unitize rule for any element (`unitize-general`).
##   Evaluation compiles this against changed library at each algebra its claim names; exit code
##     is verdict: every law below holds, or program stops on assertion.
##   Rule: element divides by √|𝐮∘𝐮|, as rigid unitization does; in CGA, round object divides by
##     its round weight norm instead, which is weight of its carrier 𝐮 ∧ 𝐞∞.
##   Laws: each kind Lengyel unitizes ends at unit weight; product of reflections ends at unit
##     versor; rule is homogeneous of degree one; rule commutes with rigid motion; flat has
##     𝐮∘𝐮 = ‖𝐮‖□²; unit versor keeps 𝐮∘𝐮; sphere tends to plane through jump no rule escapes;
##     plane sent through sphere and back keeps flat weight; round object moved far from origin
##     keeps round weight; Lengyel's operator forms keep scale he writes.
##   Figures it prints are evidence that never gates: worst error of each law, and how each
##     other test of round object fares on same moved objects.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/[math, options, random, strformat]

import pga


const
  SAMPLES = 2000  ## Samples of each law.
  SEED = 0  ## Seed of sample generator, so every run reads same elements.
  SCALES = [1e-100, -1e-8, 3.0, -1e8, 1e100]  ## Factors homogeneity is checked under.
  TOLERANCE_LAW = 1e-9  ## Largest relative error each law admits.
  REFLECTIONS_BACK = 10000  ## Planes sent through sphere and back.
  STEPS_FAMILY = [1.0, 1e-2, 1e-4, 1e-6, 1e-8, 0.0]  ## Weights of sphere in pencil toward plane.
  SIZES_SCENE = [1.0, 1e8]  ## Distances from origin of scenes whose objects move.
  SAMPLES_MOVED = 256  ## Moved round objects each test reads, at each distance.


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


func antidot(m: Multivector): float =
  ## Get antiscalar part of antidot product of multivector with itself.
  (m ∘ m)[Basis.scalarAnti]


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


func unitVersor(versor: Multivector): Multivector =
  ## Scale versor so that its antidot square is ±𝟙.
  versor * (1 / sqrt(abs(versor.antidot)))


proc drawMotor(): Multivector =
  ## Draw unit rigid motor as product of two planes.
  unitVersor(drawPlane() ⟇ drawPlane())


func moved(element, versor: Multivector): Multivector =
  ## Move element by versor, as antisandwich 𝐯 ⟇ 𝐮 ⟇ ~𝐯.
  (versor ⟇ element) ⟇ ~∘versor


func weightRound(m: Multivector): float =
  ## Get round weight norm, or weight norm in RGA.
  sqrt((`|∘²`m)[Basis.scalarAnti])


proc drawObjects(): seq[(string, Multivector, bool)] =
  ## Draw one object of each kind Lengyel unitizes: name, element, and whether it is round.
  var element = drawPoint()
  for grade in 1 ..< DIMENSIONS:
    when IS_CONFORMAL:
      result.add (&"round of grade {grade}", element, true)
      if grade < DIMENSIONS - 1:
        result.add (&"flat of grade {grade + 1}", element ∧ Basis.infinity.initElement(), false)
    else:
      result.add (&"flat of grade {grade}", element, false)
    element = element ∧ drawPoint()
  result.add ("motor", drawPlane() ⟇ drawPlane(), false)
  result.add ("flector", drawPlane() ⟇ drawPlane() ⟇ drawPlane(), false)


proc lawKinds(): float =
  ## Hold each kind at unit weight after unitize: round weight for round, flat weight for flat.
  for _ in 1..SAMPLES:
    for (name, element, is_round) in drawObjects():
      let unit = ^(gauss() * 3 * element)
      when IS_CONFORMAL:
        let weight =
          if is_round: unit.weightRound
          elif name in ["motor", "flector"]: sqrt(abs(unit.antidot))
          else: sqrt((`|□²`unit)[Basis.scalarAnti])
      else:
        let weight = unit.weightRound
      result = max(result, abs(weight - 1))
      doAssert abs(weight - 1) < TOLERANCE_LAW, &"{name} unitizes to weight; got `{weight}`."


proc lawVersors(): float =
  ## Hold products of two and four reflections at unit antidot square after unitize.
  for _ in 1..SAMPLES:
    for count in [2, 4]:
      var versor = drawReflector()
      for _ in 2..count: versor = versor ⟇ drawReflector()
      let square = abs((^(gauss() * 3 * versor)).antidot)
      result = max(result, abs(square - 1))
      doAssert abs(square - 1) < TOLERANCE_LAW, &"versor unitizes to unit; got `{square}`."


proc drawElements(): seq[Multivector] =
  ## Draw objects of every kind, versors, and general multivectors of every grade.
  for (_, element, _) in drawObjects(): result.add element
  result.add drawReflector() ⟇ drawReflector()
  var general: Multivector
  for b in Basis: general[b] = gauss()
  result.add general


proc lawHomogeneity(): float =
  ## Hold unitize(λ𝐮) = sign(λ) unitize(𝐮): divisor scales by |λ|, and branch stays.
  for _ in 1..SAMPLES:
    for element in drawElements():
      when IS_CONFORMAL:
        if abs(element.antidot) == 0 and element.weightRound == 0: continue
      for scale in SCALES:
        let error = difference(sgn(scale).float * ^element, ^(scale * element))
        result = max(result, error)
        doAssert error < TOLERANCE_LAW, &"unitize is homogeneous; got `{error}` at `{scale}`."


proc lawCovariance(): float =
  ## Hold unitize(𝐌 ⟇ 𝐮 ⟇ ~𝐌) = 𝐌 ⟇ unitize(𝐮) ⟇ ~𝐌 for unit rigid motor 𝐌.
  for _ in 1..SAMPLES:
    let motor = drawMotor()
    for element in drawElements():
      let error = difference(element.moved(motor).`^`, (^element).moved(motor))
      result = max(result, error)
      doAssert error < TOLERANCE_LAW, &"unitize commutes with rigid motion; got `{error}`."


when IS_CONFORMAL:
  func divisorExact(m: Multivector): float =
    ## Read divisor of rule whose round test compares round weight with zero exactly.
    let round = (`|∘²`m)[Basis.scalarAnti]
    var
      grade_first = none(Grade)
      is_grade_single = true
      scale = 0.0
    for b in Basis: scale = max(scale, abs(m[b]))
    for b in Basis:
      if abs(m[b]) <= TOLERANCE_ABS * scale: continue
      if grade_first.isNone: grade_first = some(b.grade)
      elif grade_first.get != b.grade: is_grade_single = false
    sqrt(if round != 0 and is_grade_single: round else: abs(m.antidot))


  proc lawIdentities(): (float, float) =
    ## Hold 𝐮∘𝐮 = ‖𝐮‖□² for flat 𝐮, and 𝐮∘𝐮 kept by unit versor 𝐯 for any 𝐮.
    for _ in 1..SAMPLES:
      for (name, element, is_round) in drawObjects():
        if is_round or name in ["motor", "flector"]: continue
        let flat = (`|□²`element)[Basis.scalarAnti]
        result[0] = max(result[0], abs(element.antidot - flat) / flat)
      let versor = unitVersor(drawReflector() ⟇ drawReflector())
      var general: Multivector
      for b in Basis: general[b] = gauss()
      let moved_general = general.moved(versor)
      result[1] = max(result[1],
        abs(moved_general.antidot - general.antidot) / moved_general.largest^2)
    doAssert result[0] < TOLERANCE_LAW, &"flat has antidot of flat weight; got `{result[0]}`."
    doAssert result[1] < TOLERANCE_LAW, &"unit versor keeps antidot; got `{result[1]}`."


  func isHoldingInfinity(b: Basis): bool =
    ## Tell whether basis holds infinity, as its wedge with infinity vanishes.
    (b.initElement() ∧ Basis.infinity.initElement()).largest == 0


  func isHoldingOrigin(b: Basis): bool =
    ## Tell whether basis holds origin, as its wedge with origin vanishes.
    (b.initElement() ∧ Basis.origin.initElement()).largest == 0


  type Selector {.pure.} = enum
    ## Define test that tells round object from any other element.
    Exact = "exact grade scan"
    AbsoluteAtPin = "grade at pin, 1e-9 absolute"
    Antiscalar = "antiscalar part is zero"
    PartScale = "grade of P07, each part at its own scale"
    Relative = "P11, 1e-9 of largest coefficient"


  func isGradeSingle(m: Multivector; selector: Selector): bool =
    ## Tell whether multivector holds one grade, as selector reads zero.
    var
      scales: array[4, float] = [1.0, 1.0, 1.0, 1.0]
      scale = 0.0
    for b in Basis:
      scale = max(scale, abs(m[b]))
      let part = 2 * int(b.isHoldingInfinity) + int(b.isHoldingOrigin)
      scales[part] = max(scales[part], abs(m[b]))
    var grade_first = none(Grade)
    for b in Basis:
      let floor = case selector
        of Selector.Exact, Selector.Antiscalar: 0.0
        of Selector.AbsoluteAtPin: TOLERANCE_ABS
        of Selector.PartScale:
          TOLERANCE_ABS * scales[2 * int(b.isHoldingInfinity) + int(b.isHoldingOrigin)]
        of Selector.Relative: TOLERANCE_ABS * scale
      if abs(m[b]) <= floor: continue
      if grade_first.isNone: grade_first = some(b.grade)
      elif grade_first.get != b.grade: return false
    true


  func divisorBy(m: Multivector; selector: Selector): float =
    ## Read divisor of rule whose round object test is selector's.
    let
      round = (`|∘²`m)[Basis.scalarAnti]
      radius = abs(m.antidot)
      is_round = if selector == Selector.Antiscalar: round != 0 and m[Basis.scalarAnti] == 0
        else: m.isGradeSingle(selector) and round > TOLERANCE_ABS^2 * radius
    sqrt(if is_round: round else: radius)


  proc lawSelectors(): seq[(Selector, float, int)] =
    ## Count moved round objects each test unitizes to round weight one, near and far.
    for size in SIZES_SCENE:
      var counts: array[Selector, int]
      for _ in 1..SAMPLES_MOVED:
        var versor = unitVersor(drawReflector() ⟇ drawReflector())
        for _ in 1..2: versor = unitVersor(drawReflector() ⟇ drawReflector()) ⟇ versor
        var element = drawPoint(size)
        for _ in 2 .. 1 + rand(DIMENSIONS - 2): element = element ∧ drawPoint(size)
        let moved_element = element.moved(versor)
        for selector in Selector:
          let weight = moved_element.weightRound / moved_element.divisorBy(selector)
          if abs(weight - 1) < TOLERANCE_LAW: inc counts[selector]
      for selector in Selector: result.add (selector, size, counts[selector])
      doAssert counts[Selector.Relative] == SAMPLES_MOVED,
        &"moved round object keeps round weight; got `{counts[Selector.Relative]}`."


  proc lawFamily(): seq[float] =
    ## Hold divisor of sphere 𝐬ₜ = t𝐬 + 𝐠 at |t| until radius passes cutoff, and plane's at 1.
    let plane = unitVersor(drawPlane())
    var sphere = drawPoint()
    for _ in 2 ..< DIMENSIONS: sphere = sphere ∧ drawPoint()
    sphere = ^sphere
    for step in STEPS_FAMILY:
      let ratio = (step * sphere + plane).divisor / (if step == 0: 1.0 else: step)
      result.add ratio
      if step >= 1e-6 or step == 0:
        doAssert abs(ratio - 1) < 1e-6, &"pencil divides by round weight; got `{ratio}`."


  proc lawReflectionBack(): (int, int) =
    ## Count planes sent through sphere and back that rule, and exact zero test, treat as round.
    for _ in 1..REFLECTIONS_BACK:
      let plane = unitVersor(drawPlane())
      var sphere = drawPoint()
      for _ in 2 ..< DIMENSIONS: sphere = sphere ∧ drawPoint()
      let
        back = plane.moved(sphere).moved(sphere)
        flat = sqrt((`|□²`back)[Basis.scalarAnti])
      if abs(back.divisor / flat - 1) > TOLERANCE_LAW: inc result[0]
      if abs(back.divisorExact / flat - 1) > TOLERANCE_LAW: inc result[1]
    doAssert result[0] == 0,
      &"plane sent through sphere and back keeps flat weight; got `{result[0]}`."


  when DIMENSIONS == 5:
    proc lawOperators(): seq[(string, float, float)] =
      ## Read divisor of Lengyel's operator forms from his wiki, against scale he writes.
      let tau = [gauss(), gauss(), gauss()]
      var translation, transversion, dilation, transversion_far: Multivector
      translation[Basis.E235] = tau[0] / 2
      translation[Basis.E315] = tau[1] / 2
      translation[Basis.E125] = tau[2] / 2
      translation[Basis.scalarAnti] = 1
      transversion[Basis.E423] = tau[0] / 2
      transversion[Basis.E431] = tau[1] / 2
      transversion[Basis.E412] = tau[2] / 2
      transversion[Basis.scalarAnti] = 1
      transversion_far[Basis.E423] = 2.1e9 / 2
      transversion_far[Basis.E431] = -1.05e9 / 2
      transversion_far[Basis.scalarAnti] = 1
      let sigma = 3.0
      dilation[Basis.E235] = (1 - sigma) / 2 * 0.5
      dilation[Basis.E315] = (1 - sigma) / 2 * 0.25
      dilation[Basis.E125] = -(1 - sigma) / 2
      dilation[Basis.E321] = -(1 - sigma) / 2
      dilation[Basis.scalarAnti] = (1 + sigma) / 2
      let rotation = drawMotor()
      var transversion_near, transversion_nearer: Multivector
      transversion_near[Basis.E423] = 1e-9
      transversion_near[Basis.scalarAnti] = 1
      transversion_nearer[Basis.E423] = 1e-13
      transversion_nearer[Basis.scalarAnti] = 1
      result = @[
        ("translation", translation.divisor, 1.0),
        ("rotation about plane pair", rotation.divisor, 1.0),
        ("transversion", transversion.divisor, 1.0),
        ("dilation, sigma 3", dilation.divisor, sqrt(sigma)),
        ("transversion, half tau 1e-9", transversion_near.divisor, 1.0),
        ("transversion, half tau 1e-13", transversion_nearer.divisor, 1.0),
        ("transversion, tau 2.1e9", transversion_far.divisor, 1.0),
      ]
      for (name, found, expected) in result[0..5]:
        doAssert abs(found / expected - 1) < TOLERANCE_LAW, &"{name} divides by; got `{found}`."


proc main() =
  ## Check every law, then print worst error of each as evidence.
  randomize(SEED)
  let algebra = (if IS_CONFORMAL: "cga" else: "rga") & $DIMENSIONS & "d"
  echo &"{algebra}: kinds Lengyel unitizes, worst |weight - 1|: {lawKinds():.1e}"
  echo &"{algebra}: products of reflections, worst |antidot square - 1|: {lawVersors():.1e}"
  echo &"{algebra}: homogeneity, worst error: {lawHomogeneity():.1e}"
  echo &"{algebra}: covariance under rigid motion, worst error: {lawCovariance():.1e}"
  when IS_CONFORMAL:
    let (flat_identity, versor_identity) = lawIdentities()
    echo &"{algebra}: flat antidot against flat weight squared, worst error: {flat_identity:.1e}"
    echo &"{algebra}: antidot kept by unit versor, worst error: {versor_identity:.1e}"
    for (selector, size, count) in lawSelectors():
      echo &"{algebra}: moved round objects at distance {size:.0e}, unitized right by " &
        &"{$selector}: {count} of {SAMPLES_MOVED}"
    let family = lawFamily()
    for i, step in STEPS_FAMILY:
      echo &"{algebra}: pencil t = {step:.0e}, divisor over |t|: {family[i]:.6f}"
    let (count_rule, count_exact) = lawReflectionBack()
    echo &"{algebra}: planes through sphere and back misread, rule {count_rule}, " &
      &"exact test {count_exact}, of {REFLECTIONS_BACK}"
    when DIMENSIONS == 5:
      for (name, found, expected) in lawOperators():
        echo &"{algebra}: {name}, divisor {found:.6g}, scale written {expected:.6g}"


when isMainModule: main()
