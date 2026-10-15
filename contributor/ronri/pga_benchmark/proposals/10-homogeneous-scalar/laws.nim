## Hold laws of homogeneous scalar x𝟏 + y𝟙, as library carrying this change exports it
##   (`homogeneous-scalar`).
##   Evaluation compiles this against library with change applied, at each algebra its claim
##     names, and exit code is verdict: every law below holds, or program stops on assertion.
##   Each law compares against product of library on whole `Multivector`, so none tests
##     emission of basis-set types against itself.
##   Samples cover each basis element and zero, where one part of root is zero, then seeded
##     pairs and multivectors with each coefficient in [-1, 1].

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[math, random, strformat]

import pga
import pga/scalars {.all.}


const
  SAMPLES = 256  ## Seeded samples each law is checked on.
  SEED = 0  ## Seed of sample generator, so every run checks same samples.
  TERMS_SERIES = 30  ## Terms of power series exponential is checked against.



#[ Laws ]#

proc sample(): ScalarHomogeneous =
  ## Sample homogeneous scalar with each part uniform in [-1, 1].
  initScalarHomogeneous(rand(-1.0..1.0), rand(-1.0..1.0))


proc sampleRooted(unit: static Basis): ScalarHomogeneous =
  ## Sample homogeneous scalar with real root.
  ##   Part on unit lies in (0, 1] under rigid metric, any part does in complex algebra, and part
  ##     on unit exceeds size of other part by (0, 1] in split-complex one.
  result = sample()
  when SQUARE_BULK == 0: result[unit] = 1.0 - rand(1.0)
  elif SQUARE_BULK == 1:
    const other = if unit == Basis.scalar: Basis.scalarAnti else: Basis.scalar
    result[unit] = abs(result[other]) + 1.0 - rand(1.0)


proc sampleWhole(): Multivector =
  ## Sample multivector with each coefficient uniform in [-1, 1].
  for basis in Basis: result[basis] = rand(-1.0..1.0)


func series(z: ScalarHomogeneous, as_anti: static bool): Multivector =
  ## Sum power series of exponential under library's product or antiproduct.
  ##   Independent of closed form.
  var term = initElement(when as_anti: Basis.scalarAnti else: Basis.scalar)
  for k in 1..TERMS_SERIES:
    result = result + term
    term = (when as_anti: term ⟇ z.toMultivector else: term ⟑ z.toMultivector) * (1 / float(k))


when IS_CONFORMAL:
  proc holdPointsRound() =
    ## Hold book's radius norm (4.45) of round point by Table 4.13: real or imaginary.
    ##   Imaginary one has no root where pair is split-complex, at cga3d and cga6d.
    for sign in [1.0, -1.0]:
      for _ in 1..SAMPLES:
        let radius = 0.1 + rand(1.0)
        var (point, distance_squared) = (initElement(Basis.origin), 0.0)
        for basis in Basis.scalar.succ..Basis.origin.pred:
          point[basis] = rand(-1.0..1.0)
          distance_squared += point[basis]^2
        point[Basis.infinity] = (distance_squared + sign * radius^2) / 2
        let
          square = (point ∘ point)[Basis.scalarAnti]
          root = normRadius(point)
        doAssert abs(square - sign * radius^2) <= TOLERANCE_ABS,
          &"Square must be 2aʷaᵘ - |a|², by Table 4.13; got `{square}` for radius `{radius}`."
        if sign > 0:
          doAssert abs(root[Basis.scalarAnti] - radius) <= TOLERANCE_ABS and
              root[Basis.scalar] == 0,
            &"Real radius norm must land on 𝟙; got `{root.toMultivector}`."
        elif SQUARE_WEIGHT == -1:
          doAssert abs(root[Basis.scalar] - radius) <= TOLERANCE_ABS and
              root[Basis.scalarAnti] == 0,
            &"Imaginary radius norm must land on 𝟏, as i; got `{root.toMultivector}`."
        else:
          doAssert root[Basis.scalar].isNaN,
            &"Split-complex pair must have no root of negative square; got `{root.toMultivector}`."


proc main(): int =
  ## Hold laws on seeded samples; print where they hold, and exit zero.
  randomize(SEED)
  let (one, one_anti) = (initElement(Basis.scalar), initElement(Basis.scalarAnti))
  doAssert sizeof(ScalarHomogeneous) == 2 * sizeof(float) and
      alignof(ScalarHomogeneous) == 2 * sizeof(float),
    &"Homogeneous scalar must hold two floats unpadded; got `{sizeof(ScalarHomogeneous)}` bytes."
  doAssert (one ⟇ one) =~ float(SQUARE_BULK) * one_anti,
    &"Table read must agree with library's antiproduct; got `{SQUARE_BULK=}`."
  doAssert (one_anti ⟑ one_anti) =~ float(SQUARE_WEIGHT) * one,
    &"Table read must agree with library's geometric product; got `{SQUARE_WEIGHT=}`."
  doAssert SQUARE_BULK == 0 xor IS_CONFORMAL, "Pair must be dual under rigid metric alone."

  # Hold roots of zero, and norms of each basis element, where one part of root is zero.
  let zero = initScalarHomogeneous(0, 0)
  doAssert sqrt(zero).toMultivector =~ 0.0 and sqrtAnti(zero).toMultivector =~ 0.0,
    &"Root of zero must be zero; got `{sqrt(zero).toMultivector}`."
  when IS_RIGID:
    for basis in Basis:
      let
        element = initElement(basis)
        (bulk, weight) = (normBulk(element), normWeight(element))
      doAssert bulk.toMultivector =~ |∙element,
        &"Bulk norm of basis element must equal library's; got `{bulk.toMultivector}`."
      doAssert weight.toMultivector =~ |∘element,
        &"Weight norm of basis element must equal library's; got `{weight.toMultivector}`."
      doAssert norm(element).toMultivector =~ |element,
        &"Geometric norm of element must equal library's; got `{norm(element)[Basis.scalar]}`."

  # Hold arithmetic and norms on seeded samples.
  when IS_CONFORMAL:
    var
      nan_float = 0  # Count float roots of 𝐦∘𝐦 that give NaN, as `|⊘` takes it.
      nan_radius = 0  # Count radius norms that give NaN, at split-complex algebras alone.
  for _ in 1..SAMPLES:
    let
      (y, z) = (sample(), sample())
      (rooted, rooted_anti) = (sampleRooted(Basis.scalar), sampleRooted(Basis.scalarAnti))
      m = sampleWhole()
      root_dot = sqrt(initScalarHomogeneous((m ∙ m)[Basis.scalar], 0))
    doAssert complement(z).toMultivector =~ /z.toMultivector, "Complement must equal library's."
    doAssert (z.toMultivector ⟑ one) =~ z.toMultivector, "𝟏 must be unit of geometric product."
    doAssert (z.toMultivector ⟑ inverse(z).toMultivector) =~ one, "z ⟑ z⁻¹ must be 𝟏."
    doAssert (sqrt(rooted).toMultivector ⟑ sqrt(rooted).toMultivector) =~ rooted.toMultivector,
      &"√z ⟑ √z must be z; got `{sqrt(rooted).toMultivector}` for `{rooted.toMultivector}`."
    doAssert exp(z).toMultivector =~ series(z, as_anti = false),
      "Exp must be its power series under geometric product."
    doAssert exp(y + z).toMultivector =~ (exp(y).toMultivector ⟑ exp(z).toMultivector),
      "Exp of sum must be product of exps under geometric product."
    doAssert (y ⟇ z) is ScalarHomogeneous,
      "Antiproduct of homogeneous scalars must be homogeneous scalar, by table."
    doAssert (z.toMultivector ⟇ one_anti) =~ z.toMultivector, "𝟙 must be unit of antiproduct."
    doAssert (z.toMultivector ⟇ inverseAnti(z).toMultivector) =~ one_anti, "z ⟇ z⁻¹ must be 𝟙."
    doAssert ((y / z).toMultivector ⟇ z.toMultivector) =~ y.toMultivector,
      "(y / z) ⟇ z must be y."
    doAssert (sqrtAnti(rooted_anti).toMultivector ⟇ sqrtAnti(rooted_anti).toMultivector) =~
        rooted_anti.toMultivector,
      &"√z ⟇ √z must be z; got `{sqrtAnti(rooted_anti).toMultivector}`."
    doAssert expAnti(z).toMultivector =~ series(z, as_anti = true),
      "Exp must be its power series under antiproduct."
    doAssert expAnti(y + z).toMultivector =~
        (expAnti(y).toMultivector ⟇ expAnti(z).toMultivector),
      "Exp of sum must be product of exps under antiproduct."
    if SQUARE_WEIGHT != 1 or (m ∙ m)[Basis.scalar] >= 0:
      doAssert not root_dot[Basis.scalar].isNaN and not root_dot[Basis.scalarAnti].isNaN,
        &"Root of 𝐦∙𝐦 must not be NaN where pair has root; got `{root_dot.toMultivector}`."
      doAssert (root_dot.toMultivector ⟑ root_dot.toMultivector) =~ (m ∙ m),
        &"√(𝐦∙𝐦) ⟑ √(𝐦∙𝐦) must be 𝐦∙𝐦; got `{root_dot.toMultivector}`."
    when IS_RIGID:
      let (bulk, weight) = (normBulk(m), normWeight(m))
      doAssert (weight.toMultivector ⟇ weight.toMultivector) =~ (m ∘ m),
        &"‖𝐦‖∘ ⟇ ‖𝐦‖∘ must be 𝐦∘𝐦; got `{weight.toMultivector}`."
      doAssert bulk.toMultivector =~ |∙m,
        &"Bulk norm must equal library's; got `{bulk.toMultivector}`."
      doAssert weight.toMultivector =~ |∘m,
        &"Weight norm must equal library's; got `{weight.toMultivector}`."
      doAssert norm(m).toMultivector =~ |m,
        &"Geometric norm must equal library's; got `{norm(m).toMultivector}`."
      let unitized = norm(m) / weight
      doAssert unitized.toMultivector =~
          initScalarHomogeneous((|∙m)[Basis.scalar] / (|∘m)[Basis.scalarAnti], 1).toMultivector,
        &"Homogeneous scalar must unitize to distance 𝟏 + 𝟙; got `{unitized.toMultivector}`."
      doAssert m / weight =~ ^m, &"Division by weight norm must equal `^`; got `{m / weight}`."
    else:
      let radius = normRadius(m)
      if sqrt((m ∘ m)[Basis.scalarAnti]).isNaN: inc nan_float
      if radius[Basis.scalar].isNaN or radius[Basis.scalarAnti].isNaN:
        doAssert SQUARE_WEIGHT == 1,
          &"Radius norm must not be NaN in complex algebra; got `{radius.toMultivector}`."
        inc nan_radius
        continue
      doAssert (radius.toMultivector ⟇ radius.toMultivector) =~ (m ∘ m),
        &"‖𝐦‖⊘ ⟇ ‖𝐦‖⊘ must be 𝐦∘𝐦; got `{radius.toMultivector}`."
  when IS_CONFORMAL:
    holdPointsRound()
    echo "homogeneous-scalar: laws hold at ", DIMENSIONS, "D conformal; float root of 𝐦∘𝐦 NaN ",
      nan_float, " of ", SAMPLES, ", radius norm NaN ", nan_radius
  else:
    echo "homogeneous-scalar: laws hold at ", DIMENSIONS, "D rigid"
  0


when isMainModule:
  quit main()
