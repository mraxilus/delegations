## Hold laws of homogeneous scalar x𝟏 + y𝟙, as library carrying this change exports it
##   (`homogeneous-scalar`).
##   Evaluation compiles this against library with change applied, at each algebra its claim
##     names, and exit code is verdict: every law below holds, or program stops on assertion.
##   Each law compares against product, complement or norm of library, or against authority:
##     Lengyel's `DualNum` under rigid metric, `std/complex` where ε² = -1, and idempotents where
##     ε² = +1, for 𝟙 ⟑ 𝟙 = ε²𝟏.
##   Samples cover zero, basis elements and edges of each domain, then seeded pairs and
##     multivectors with each coefficient in [-1, 1].

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[complex, fenv, math, options, random, strformat]

import pga
import pga/scalars {.all.}


const
  SAMPLES = 4096  ## Seeded samples each law is checked on.
  SAMPLES_FLOOR = SAMPLES div 8  ## Fewest samples guarded law passes, so filtering guard fails.
  SEED = 0  ## Seed of sample generator, so every run checks same samples.
  TERMS_SERIES = 30  ## Terms of each power series checked against.
  SUITE_441 = [
    0.26439620787267393, -0.48037647709926767, 0.38634158509384697, -0.18453193800986453,
  ]  ## Vector 441 of pool of `tests/suites.nim` at cga4d, whose roots printed NaN.



#[ Oracles ]#

func scale(z: MultivectorScalars, factor: Coefficient): MultivectorScalars =
  ## Scale both parts of homogeneous scalar by factor.
  initMultivectorScalars(factor * z[Basis.scalar], factor * z[Basis.scalarAnti])


func product(y, z: MultivectorScalars): MultivectorScalars =
  ## Multiply homogeneous scalars through library's geometric product, i.e. y ⟑ z.
  toMultivectorScalars(y.toMultivector ⟑ z.toMultivector)


func productAnti(y, z: MultivectorScalars): MultivectorScalars =
  ## Multiply homogeneous scalars through library's antiproduct, i.e. y ⟇ z.
  toMultivectorScalars(y.toMultivector ⟇ z.toMultivector)


func series(
  z: MultivectorScalars, terms: array[TERMS_SERIES, Coefficient], as_anti: static bool
): MultivectorScalars =
  ## Sum power series Σ cₖ zᵏ under library's product or antiproduct; independent of closed forms.
  var power = when as_anti: initMultivectorScalars(0, 1) else: initMultivectorScalars(1, 0)
  for term in terms:
    result = result + power.scale(term)
    power = when as_anti: productAnti(power, z) else: product(power, z)


func constructTerms(phase: static int): array[TERMS_SERIES, Coefficient] {.compileTime.} =
  ## Construct coefficients of exponential, or of sine or cosine where phase is 1 or 0.
  ##   Exponential takes phase -1: every term 1 / k!; sine and cosine keep alternating odd or even.
  var factorial = 1.0
  for k in 0..<TERMS_SERIES:
    if k > 0: factorial *= float(k)
    result[k] =
      if phase < 0: 1 / factorial
      elif k mod 2 != phase: 0.0
      else: (if (k div 2) mod 2 == 0: 1.0 else: -1.0) / factorial


const
  TERMS_EXP = constructTerms(-1)  ## Coefficients of eᶻ.
  TERMS_SIN = constructTerms(1)  ## Coefficients of sin z.
  TERMS_COS = constructTerms(0)  ## Coefficients of cos z.


func toOption(root: MultivectorScalarsRoot[SQUARE_WEIGHT]): Option[MultivectorScalars] =
  ## Read root as optional pair, whichever type algebra gives it.
  when SQUARE_WEIGHT == -1: some(root) else: root


func size(z: MultivectorScalars): Coefficient =
  ## Get larger part of homogeneous scalar in magnitude, i.e. max(|x|, |y|).
  max(abs(z[Basis.scalar]), abs(z[Basis.scalarAnti]))


func isNear(actual, expected: MultivectorScalars; scale: Coefficient): bool =
  ## Decide whether pairs agree within tolerance at scale of terms that formed actual.
  ##   Product of large inverse and small part cancels to rounding of its terms, not of result.
  for basis in [Basis.scalar, Basis.scalarAnti]:
    let bound = TOLERANCE_ABS * max([1.0, scale, abs(actual[basis]), abs(expected[basis])])
    if abs(actual[basis] - expected[basis]) > bound: return false
  true


func isRooted(z: MultivectorScalars): bool =
  ## Decide whether pair has real root under geometric product, by domain of its algebra.
  let (bulk, weight) = (z[Basis.scalar], z[Basis.scalarAnti])
  when SQUARE_WEIGHT == -1: true
  elif SQUARE_WEIGHT == 0: bulk > 0 or (bulk == 0 and weight == 0)
  else: bulk >= abs(weight)


func isInvertible(z: MultivectorScalars): bool =
  ## Decide whether pair has inverse: modulus x² − ε²y² beyond zero at scale of its terms.
  let
    (bulk, weight) = (z[Basis.scalar], z[Basis.scalarAnti])
    modulus_squared = bulk * bulk - Coefficient(SQUARE_WEIGHT) * weight * weight
  abs(modulus_squared) > TOLERANCE_ABS * (bulk * bulk + abs(Coefficient(SQUARE_WEIGHT)) * weight^2)


func toComplex(z: MultivectorScalars): Complex64 =
  ## Map pair to complex number, 𝟏 to 1 and 𝟙 to i, where ε² = -1.
  complex64(z[Basis.scalar], z[Basis.scalarAnti])


func toScalars(c: Complex64): MultivectorScalars =
  ## Map complex number to pair, 1 to 𝟏 and i to 𝟙, where ε² = -1.
  initMultivectorScalars(c.re, c.im)


func idempotent(
  z: MultivectorScalars, function: proc (x: float): float {.nimcall, noSideEffect.}
): MultivectorScalars =
  ## Apply function on each idempotent of split-complex pair, i.e. at x + y and at x − y.
  let
    (bulk, weight) = (z[Basis.scalar], z[Basis.scalarAnti])
    (plus, minus) = (function(bulk + weight), function(bulk - weight))
  initMultivectorScalars((plus + minus) / 2, (plus - minus) / 2)



#[ Lengyel's Dual Number ]#

func inverseLengyel(s, t: Coefficient): MultivectorScalars =
  ## Transcribe `Inverse` of `TSDualNum.h`: (1 / s, -t / s²).
  let a = 1 / s
  initMultivectorScalars(a, -t * (a * a))


func sqrtLengyel(s, t: Coefficient): MultivectorScalars =
  ## Transcribe `Sqrt` of `TSDualNum.h`: (s / √s, t / (2√s)).
  let a = 1 / math.sqrt(s)
  initMultivectorScalars(s * a, t * (a * 0.5))


func sqrtInverseLengyel(s, t: Coefficient): MultivectorScalars =
  ## Transcribe `InverseSqrt` of `TSDualNum.h`: (1 / √s, -t / (2 s√s)).
  let a = 1 / math.sqrt(s)
  initMultivectorScalars(a, -t * (a * a) * (a * 0.5))


func expLengyel(s, t: Coefficient): MultivectorScalars =
  ## Transcribe `Exp` of `TSDualNum.h`: (eˢ, t eˢ).
  let a = math.exp(s)
  initMultivectorScalars(a, t * a)


func sinLengyel(s, t: Coefficient): MultivectorScalars =
  ## Transcribe `Sin` of `TSDualNum.h`: (sin s, t cos s).
  initMultivectorScalars(math.sin(s), t * math.cos(s))


func cosLengyel(s, t: Coefficient): MultivectorScalars =
  ## Transcribe `Cos` of `TSDualNum.h`: (cos s, -t sin s).
  initMultivectorScalars(math.cos(s), -t * math.sin(s))


func tanLengyel(s, t: Coefficient): MultivectorScalars =
  ## Transcribe `Tan` of `TSDualNum.h`: (tan s, t (tan² s + 1)).
  let a = math.tan(s)
  initMultivectorScalars(a, t * (a * a + 1))



#[ Laws ]#

proc holdTables() =
  ## Hold square from metric, complement and pair products against library.
  let (one, one_anti) = (initElement(Basis.scalar), initElement(Basis.scalarAnti))
  doAssert (one_anti ⟑ one_anti) =~ Coefficient(SQUARE_WEIGHT) * one,
    &"Square from metric must agree with library's ⟑; got `{SQUARE_WEIGHT=}`."
  doAssert (one ⟇ one) =~ Coefficient(SQUARE_BULK) * one_anti,
    &"Square from metric must agree with library's ⟇; got `{SQUARE_BULK=}`."
  for _ in 1..SAMPLES:
    let
      y = initMultivectorScalars(rand(-1.0..1.0), rand(-1.0..1.0))
      z = initMultivectorScalars(rand(-1.0..1.0), rand(-1.0..1.0))
    doAssert complement(z).toMultivector =~ /z.toMultivector, "Complement must equal library's."
    doAssert wedgeDot(y, z) =~ product(y, z), "Pair ⟑ must equal library's."
    doAssert wedgeDotAnti(y, z) =~ productAnti(y, z), "Pair ⟇ must equal library's."


proc holdFunctions(pairs: openArray[MultivectorScalars]): array[8, int] =
  ## Hold law of each function and its anti form on pairs; count samples each guarded law passed.
  let (unit, unit_anti) = (initMultivectorScalars(1, 0), initMultivectorScalars(0, 1))
  for i, z in pairs:
    let
      (bulk, weight) = (z[Basis.scalar], z[Basis.scalarAnti])
      is_small = abs(bulk) <= 1 and abs(weight) <= 1

    # Hold inverse: z ⟑ z⁻¹ = 𝟏 and z ⟇ z⁻¹ = 𝟙, and none exactly where modulus vanishes.
    let (inverse_z, inverse_anti) = (inverse(z), inverseAnti(z))
    doAssert inverse_z.isSome == isInvertible(z), &"Inverse exists by modulus; got `{z=}`."
    doAssert inverse_anti.isSome == isInvertible(complement(z)), &"Antiinverse; got `{z=}`."
    if inverse_z.isSome:
      inc result[0]
      doAssert product(z, inverse_z.get).isNear(unit, z.size * inverse_z.get.size),
        &"z ⟑ z⁻¹ must be 𝟏; got `{z=}`."
    if inverse_anti.isSome:
      doAssert productAnti(z, inverse_anti.get).isNear(unit_anti, z.size * inverse_anti.get.size),
        &"z ⟇ z⁻¹ must be 𝟙; got `{z=}`."

    # Hold root: √z ⟑ √z = z with bulk ≥ 0, and none exactly outside domain.
    let (root, root_anti) = (sqrt(z).toOption, sqrtAnti(z).toOption)
    doAssert root.isSome == isRooted(z), &"Root exists by domain; got `{z=}`."
    doAssert root_anti.isSome == isRooted(complement(z)), &"Antiroot by domain; got `{z=}`."
    if root.isSome:
      inc result[1]
      doAssert product(root.get, root.get) =~ z and root.get[Basis.scalar] >= 0,
        &"√z ⟑ √z must be z, bulk ≥ 0; got `{root.get.toMultivector}` for `{z.toMultivector}`."
    if root_anti.isSome:
      doAssert productAnti(root_anti.get, root_anti.get) =~ z and
          root_anti.get[Basis.scalarAnti] >= 0,
        &"√z ⟇ √z must be z, weight ≥ 0; got `{root_anti.get.toMultivector}`."

    # Hold inverse root: (1 / √z)² ⟑ z = 𝟏 where root and its inverse exist.
    let root_inverse = sqrtInverse(z)
    if root_inverse.isSome:
      inc result[2]
      let square = product(root_inverse.get, root_inverse.get)
      doAssert product(square, z).isNear(unit, square.size * z.size),
        &"(1 / √z)² ⟑ z must be 𝟏; got `{z=}`."
    let root_inverse_anti = sqrtInverseAnti(z)
    if root_inverse_anti.isSome:
      let square_anti = productAnti(root_inverse_anti.get, root_inverse_anti.get)
      doAssert productAnti(square_anti, z).isNear(unit_anti, square_anti.size * z.size),
        &"(1 / √z)² ⟇ z must be 𝟙; got `{z=}`."

    # Hold exponential, sine and cosine against power series, and their addition laws.
    if is_small:
      inc result[3]
      doAssert exp(z) =~ series(z, TERMS_EXP, as_anti = false), &"eᶻ is series; got `{z=}`."
      doAssert sin(z) =~ series(z, TERMS_SIN, as_anti = false), &"sin is series; got `{z=}`."
      doAssert cos(z) =~ series(z, TERMS_COS, as_anti = false), &"cos is series; got `{z=}`."
      doAssert expAnti(z) =~ series(z, TERMS_EXP, as_anti = true), &"eᶻ under ⟇; got `{z=}`."
      doAssert sinAnti(z) =~ series(z, TERMS_SIN, as_anti = true), &"sin under ⟇; got `{z=}`."
      doAssert cosAnti(z) =~ series(z, TERMS_COS, as_anti = true), &"cos under ⟇; got `{z=}`."
    let y = pairs[(i+1) mod pairs.len]
    doAssert exp(y + z) =~ product(exp(y), exp(z)), &"e^(y + z) = eʸ ⟑ eᶻ; got `{z=}`."
    doAssert expAnti(y + z) =~ productAnti(expAnti(y), expAnti(z)), &"Same under ⟇; got `{z=}`."
    doAssert product(sin(z), sin(z)) + product(cos(z), cos(z)) =~ unit,
      &"sin² + cos² must be 𝟏; got `{z=}`."
    doAssert productAnti(sinAnti(z), sinAnti(z)) + productAnti(cosAnti(z), cosAnti(z)) =~
        unit_anti,
      &"sin² + cos² under ⟇ must be 𝟙; got `{z=}`."

    # Hold tangent: tan z ⟑ cos z = sin z, and none exactly where cosine has no inverse.
    let (tangent, tangent_anti) = (tan(z), tanAnti(z))
    doAssert tangent.isSome == isInvertible(cos(z)), &"Tangent exists by cosine; got `{z=}`."
    if tangent.isSome:
      inc result[4]
      doAssert product(tangent.get, cos(z)).isNear(sin(z), tangent.get.size * cos(z).size),
        &"tan z ⟑ cos z = sin z; got `{z=}`."
    if tangent_anti.isSome:
      let scale_anti = tangent_anti.get.size * cosAnti(z).size
      doAssert productAnti(tangent_anti.get, cosAnti(z)).isNear(sinAnti(z), scale_anti),
        &"tan z ⟇ cos z = sin z under ⟇; got `{z=}`."

    # Hold division: (y / z) ⟇ z = y, for pair and for multivector.
    let quotient = y / z
    if quotient.isSome:
      inc result[5]
      doAssert productAnti(quotient.get, z).isNear(y, quotient.get.size * z.size),
        &"(y / z) ⟇ z must be y; got `{z=}`."
      let whole = toMultivectorScalars((y.toMultivector / z).get ⟇ z.toMultivector)
      doAssert whole.isNear(y, quotient.get.size * z.size), "(𝐦 / z) ⟇ z must be 𝐦."

    # Hold authority of algebra: Lengyel's forms, complex functions, or idempotents.
    when SQUARE_WEIGHT == 0:
      doAssert exp(z) =~ expLengyel(bulk, weight), &"`Exp` of Lengyel; got `{z=}`."
      doAssert sin(z) =~ sinLengyel(bulk, weight), &"`Sin` of Lengyel; got `{z=}`."
      doAssert cos(z) =~ cosLengyel(bulk, weight), &"`Cos` of Lengyel; got `{z=}`."
      doAssert expAnti(z) =~ complement(expLengyel(weight, bulk)), "`AntiExp` of Lengyel."
      if bulk > 0:
        inc result[6]
        doAssert root.get =~ sqrtLengyel(bulk, weight), &"`Sqrt` of Lengyel; got `{z=}`."
        doAssert root_inverse.get =~ sqrtInverseLengyel(bulk, weight), "`InverseSqrt`."
        doAssert inverse_z.get =~ inverseLengyel(bulk, weight), &"`Inverse`; got `{z=}`."
      if weight > 0:
        doAssert root_anti.get =~ complement(sqrtLengyel(weight, bulk)), "`AntiSqrt` of Lengyel."
        doAssert inverse_anti.get =~ complement(inverseLengyel(weight, bulk)), "`AntiInverse`."
      if tangent.isSome:
        doAssert tangent.get =~ tanLengyel(bulk, weight), &"`Tan` of Lengyel; got `{z=}`."
    elif SQUARE_WEIGHT == -1:
      inc result[6]
      doAssert root.get =~ sqrt(z.toComplex).toScalars, &"Principal complex root; got `{z=}`."
      doAssert exp(z) =~ exp(z.toComplex).toScalars, &"Complex exponential; got `{z=}`."
      doAssert sin(z) =~ sin(z.toComplex).toScalars, &"Complex sine; got `{z=}`."
      doAssert cos(z) =~ cos(z.toComplex).toScalars, &"Complex cosine; got `{z=}`."
      if inverse_z.isSome:
        doAssert inverse_z.get =~ inv(z.toComplex).toScalars, &"Complex inverse; got `{z=}`."
      if tangent.isSome:
        doAssert tangent.get =~ tan(z.toComplex).toScalars, &"Complex tangent; got `{z=}`."
    else:
      doAssert exp(z) =~ z.idempotent(math.exp), &"Exponential on idempotents; got `{z=}`."
      doAssert sin(z) =~ z.idempotent(math.sin), &"Sine on idempotents; got `{z=}`."
      doAssert cos(z) =~ z.idempotent(math.cos), &"Cosine on idempotents; got `{z=}`."
      if root.isSome:
        inc result[6]
        doAssert root.get =~ z.idempotent(math.sqrt), &"Root on idempotents; got `{z=}`."

    # Hold root of small part without cancellation: residual of 𝟙 within few rounding errors.
    if root.isSome and abs(weight) > 0:
      let residual = abs(product(root.get, root.get)[Basis.scalarAnti] - weight)
      doAssert residual <= 8 * epsilon(Coefficient) * max(abs(bulk), abs(weight)),
        &"Root must not cancel small part; got `{residual=}` for `{z.toMultivector}`."
      inc result[7]


proc holdNorms(): tuple[nan_float, radius_none: int] =
  ## Hold norms of library against roots of pair: bulk and weight norms under rigid metric, and
  ##   radius norm under conformal one; count float roots of 𝐦∘𝐦 that `|⊘` leaves NaN.
  doAssert sizeof(MultivectorScalars) == 2 * sizeof(Coefficient),
    &"Homogeneous scalar must hold two coefficients unpadded; got `{sizeof(MultivectorScalars)}`."
  doAssert SQUARE_BULK == 0 xor IS_CONFORMAL, "Pair must be dual under rigid metric alone."

  # Hold roots of basis elements against norms of library, where one part of root is zero.
  when IS_RIGID:
    for basis in Basis:
      let
        element = initElement(basis)
        bulk = sqrt(initMultivectorScalars((element ∙ element)[Basis.scalar], 0)).toOption
        weight = sqrtAnti(initMultivectorScalars(0, (element ∘ element)[Basis.scalarAnti]))
      doAssert bulk.isSome and bulk.get =~ |∙element,
        &"Root of 𝐞∙𝐞 under ⟑ must equal bulk norm of library; got `{bulk}`."
      doAssert weight.toOption.isSome and weight.toOption.get =~ |∘element,
        &"Root of 𝐞∘𝐞 under ⟇ must equal weight norm of library; got `{weight}`."

  # Hold norms on seeded multivectors.
  for _ in 1..SAMPLES:
    var m: Multivector
    for basis in Basis: m[basis] = rand(-1.0..1.0)
    let root_dot = sqrt(initMultivectorScalars((m ∙ m)[Basis.scalar], 0)).toOption
    if root_dot.isSome:
      doAssert product(root_dot.get, root_dot.get).toMultivector =~ (m ∙ m),
        &"√(𝐦∙𝐦) ⟑ √(𝐦∙𝐦) must be 𝐦∙𝐦; got `{root_dot.get.toMultivector}`."
    when IS_RIGID:
      let
        (bulk, weight) = (normBulk(m), normWeight(m))
        root_weight = sqrtAnti(initMultivectorScalars(0, (m ∘ m)[Basis.scalarAnti])).toOption
        unitized = norm(m) / weight
        divided = m / weight
      doAssert root_dot.isSome and root_dot.get =~ bulk,
        &"Root of 𝐦∙𝐦 under ⟑ must equal bulk norm of library; got `{root_dot}`."
      doAssert productAnti(weight, weight).toMultivector =~ (m ∘ m),
        &"‖𝐦‖∘ ⟇ ‖𝐦‖∘ must be 𝐦∘𝐦; got `{weight.toMultivector}`."
      doAssert root_weight.isSome and root_weight.get =~ weight,
        &"Root of 𝐦∘𝐦 under ⟇ must equal weight norm of library; got `{root_weight}`."
      doAssert unitized.isSome and unitized.get =~
          initMultivectorScalars((|∙m)[Basis.scalar] / (|∘m)[Basis.scalarAnti], 1),
        &"Homogeneous scalar must unitize to distance 𝟏 + 𝟙; got `{unitized}`."
      doAssert divided.isSome and divided.get =~ ^m, "Division by weight norm must equal `^`."
    else:
      let
        square = (m ∘ m)[Basis.scalarAnti]
        radius = normRadius(m).toOption
      if sqrt(square).isNaN: inc result.nan_float
      doAssert radius.isSome == (SQUARE_BULK == -1 or square >= 0),
        &"Radius norm exists exactly where pair has root; got `{radius}` for `{square=}`."
      if radius.isNone:
        inc result.radius_none
        continue
      doAssert productAnti(radius.get, radius.get).toMultivector =~ (m ∘ m),
        &"‖𝐦‖⊘ ⟇ ‖𝐦‖⊘ must be 𝐦∘𝐦; got `{radius.get.toMultivector}`."


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
          root = normRadius(point).toOption
        doAssert abs(square - sign * radius^2) <= TOLERANCE_ABS,
          &"Square must be 2aʷaᵘ - |a|², by Table 4.13; got `{square}` for radius `{radius}`."
        if sign > 0:
          doAssert root.isSome and abs(root.get[Basis.scalarAnti] - radius) <= TOLERANCE_ABS and
              root.get[Basis.scalar] == 0,
            &"Real radius norm must land on 𝟙; got `{root}`."
        elif SQUARE_WEIGHT == -1:
          doAssert root.isSome and abs(root.get[Basis.scalar] - radius) <= TOLERANCE_ABS and
              root.get[Basis.scalarAnti] == 0,
            &"Imaginary radius norm must land on 𝟏, as i; got `{root}`."
        else:
          doAssert root.isNone,
            &"Split-complex pair must have no root of negative square; got `{root}`."


proc holdRadius(): tuple[float_nan, root_none, point_nan, point_none, point_imaginary: int] =
  ## Hold root of 𝐦∘𝐦 under ⟇ against library's radius norm, on seeded and null-cone samples.
  ##   Point on null cone has radius zero, so 𝐦∘𝐦 rounds either side of zero.
  when IS_CONFORMAL:
    for _ in 1..SAMPLES:
      var m: Multivector
      for basis in Basis: m[basis] = rand(-1.0..1.0)
      let
        dot_anti = toMultivectorScalars(m ∘ m)
        radius = sqrtAnti(dot_anti).toOption
      if (|⊘m)[Basis.scalarAnti].isNaN: inc result.float_nan
      if radius.isNone: inc result.root_none
      else:
        doAssert productAnti(radius.get, radius.get) =~ dot_anti, "‖𝐦‖⊘ ⟇ ‖𝐦‖⊘ must be 𝐦∘𝐦."
        if dot_anti[Basis.scalarAnti] >= 0:
          doAssert radius.get =~ |⊘m, "Real radius norm must equal library's."
    for _ in 1..SAMPLES:
      let weight = rand(0.5..2.0)  # Weight other than 1, so rounding of 𝐦∘𝐦 shows.
      var (point, distance_squared) = (initElement(Basis.origin, weight), 0.0)
      for basis in Basis.scalar.succ..Basis.origin.pred:
        point[basis] = weight * rand(-1.0..1.0)
        distance_squared += point[basis]^2
      point[Basis.infinity] = distance_squared / (2 * weight)
      let radius = sqrtAnti(toMultivectorScalars(point ∘ point)).toOption
      if (|⊘point)[Basis.scalarAnti].isNaN: inc result.point_nan
      if radius.isNone: inc result.point_none
      elif radius.get[Basis.scalar] > 0: inc result.point_imaginary


proc holdSuiteSample() =
  ## Hold roots of vector 441 of suite's pool at cga4d, whose antiroot printed `[nan, nan]`.
  when IS_CONFORMAL and DIMENSIONS == 4:
    var 𝐦: Multivector
    for k, coefficient in SUITE_441: 𝐦[Basis(k+1)] = coefficient
    let
      dot_anti = toMultivectorScalars(𝐦 ∘ 𝐦)
      radius = sqrtAnti(dot_anti)
    doAssert (|⊘𝐦)[Basis.scalarAnti].isNaN, "Float root of library prints NaN, as found."
    doAssert radius =~ initMultivectorScalars(0.6657714603000752, 0),
      &"Radius norm must be imaginary 0.665771𝟏; got `{radius.toMultivector}`."
    doAssert productAnti(radius, radius) =~ dot_anti, "‖𝐦‖⊘ ⟇ ‖𝐦‖⊘ must be 𝐦∘𝐦."


proc main(): int =
  ## Hold laws on structured and seeded samples; print counts where they hold, and exit zero.
  randomize(SEED)
  holdTables()
  var pairs: seq[MultivectorScalars]
  for (bulk, weight) in [
    (0.0, 0.0), (1.0, 0.0), (-1.0, 0.0), (0.0, 1.0), (0.0, -1.0), (1.0, 1.0), (1.0, -1.0),
    (-1.0, 1.0), (2.0, 1.0), (1.0, 2.0), (1.0, 1e-10), (-1.0, 1e-10), (1e-10, 1.0),
    (-0.44325163735009460, 0.0), (0.0, -0.44325163735009460), (PI / 2, 0.0),
  ]:
    pairs.add initMultivectorScalars(bulk, weight)
  for _ in 1..SAMPLES: pairs.add initMultivectorScalars(rand(-1.0..1.0), rand(-1.0..1.0))
  let passed = holdFunctions(pairs)
  for count in passed:
    doAssert count >= SAMPLES_FLOOR, &"Guard must pass floor of samples; got `{passed}`."
  let radius = holdRadius()
  holdSuiteSample()
  let norms = holdNorms()
  when IS_CONFORMAL: holdPointsRound()
  let kind = if IS_CONFORMAL: "conformal" else: "rigid"
  echo &"homogeneous-scalar: laws hold at {DIMENSIONS}D {kind}, ε² = {SQUARE_WEIGHT}, " &
      &"{pairs.len} pairs; passed inverse {passed[0]}, root {passed[1]}, inverse root " &
      &"{passed[2]}, series " &
      &"{passed[3]}, tangent {passed[4]}, quotient {passed[5]}, authority {passed[6]}, small " &
      &"part {passed[7]}"
  when IS_CONFORMAL:
    echo &"  radius of {SAMPLES} multivectors: `|⊘` NaN {radius.float_nan}, antiroot none " &
        &"{radius.root_none}; of {SAMPLES} null points: `|⊘` NaN {radius.point_nan}, antiroot " &
        &"none {radius.point_none}, imaginary {radius.point_imaginary}"
    echo &"  radius norm of {SAMPLES} multivectors: float root NaN {norms.nan_float}, " &
        &"`normRadius` none {norms.radius_none}"
  0


when isMainModule:
  quit main()
