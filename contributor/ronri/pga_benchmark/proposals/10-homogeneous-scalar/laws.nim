## Hold laws of homogeneous scalar s𝟏 + t𝟙, as library carrying this change exports it
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


const
  SAMPLES = 4096  ## Seeded samples each law is checked on.
  SAMPLES_FLOOR = SAMPLES div 8  ## Fewest samples guarded law passes, so filtering guard fails.
  SEED = 0  ## Seed of sample generator, so every run checks same samples.
  TERMS_SERIES = 30  ## Terms of each power series checked against.
  SUITE_441 = [
    0.26439620787267393, -0.48037647709926767, 0.38634158509384697, -0.18453193800986453,
  ]  ## Vector 441 of pool of `tests/suites.nim` at cga4d, whose roots printed NaN.



#[ Oracles ]#

func scale(m: MultivectorScalars, factor: Coefficient): MultivectorScalars =
  ## Scale both parts of homogeneous scalar by factor.
  initMultivectorScalars(factor * m[Basis.scalar], factor * m[Basis.scalarAnti])


func complement(m: MultivectorScalars): MultivectorScalars =
  ## Get complement of homogeneous scalar through library's, i.e. /𝐦.
  toMultivectorScalars(/m.toMultivector)


func product(m, n: MultivectorScalars): MultivectorScalars =
  ## Multiply homogeneous scalars through library's geometric product, i.e. 𝐦 ⟑ 𝐧.
  toMultivectorScalars(m.toMultivector ⟑ n.toMultivector)


func productAnti(m, n: MultivectorScalars): MultivectorScalars =
  ## Multiply homogeneous scalars through library's antiproduct, i.e. 𝐦 ⟇ 𝐧.
  toMultivectorScalars(m.toMultivector ⟇ n.toMultivector)


func series(
  m: MultivectorScalars, terms: array[TERMS_SERIES, Coefficient], as_anti: static bool
): MultivectorScalars =
  ## Sum power series Σ cₖ 𝐦ᵏ under library's product or antiproduct; independent of closed forms.
  var power = when as_anti: initMultivectorScalars(0, 1) else: initMultivectorScalars(1, 0)
  for term in terms:
    result = result + power.scale(term)
    power = when as_anti: productAnti(power, m) else: product(power, m)


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
  TERMS_EXP = constructTerms(-1)  ## Coefficients of exp⟑𝐦.
  TERMS_SIN = constructTerms(1)  ## Coefficients of sin⟑𝐦.
  TERMS_COS = constructTerms(0)  ## Coefficients of cos⟑𝐦.


func size(m: MultivectorScalars): Coefficient =
  ## Get larger part of homogeneous scalar in magnitude, i.e. max(|s|, |t|).
  max(abs(m[Basis.scalar]), abs(m[Basis.scalarAnti]))


func isNear(actual, expected: MultivectorScalars; scale: Coefficient): bool =
  ## Decide whether pairs agree within tolerance at scale of terms that formed actual.
  ##   Product of large inverse and small part cancels to rounding of its terms, not of result.
  for basis in [Basis.scalar, Basis.scalarAnti]:
    let bound = TOLERANCE_ABS * max([1.0, scale, abs(actual[basis]), abs(expected[basis])])
    if abs(actual[basis] - expected[basis]) > bound: return false
  true


func isRooted(m: MultivectorScalars): bool =
  ## Decide whether pair has real root under geometric product, by domain of its algebra.
  let (s, t) = (m[Basis.scalar], m[Basis.scalarAnti])
  when SQUARES_WEDGE_DOT.base == -1: true
  elif SQUARES_WEDGE_DOT.base == 0: s > 0 or (s == 0 and t == 0)
  else: s >= abs(t)


func isInvertible(m: MultivectorScalars): bool =
  ## Decide whether pair has inverse: modulus s² − ε²t² beyond zero at scale of its terms.
  let
    (s, t) = (m[Basis.scalar], m[Basis.scalarAnti])
    modulus_squared = s * s - SQUARES_WEDGE_DOT.base * t * t
  abs(modulus_squared) > TOLERANCE_ABS * (s * s + abs(SQUARES_WEDGE_DOT.base) * t * t)


func toComplex(m: MultivectorScalars): Complex64 =
  ## Map pair to complex number, 𝟏 to 1 and 𝟙 to i, where ε² = -1.
  complex64(m[Basis.scalar], m[Basis.scalarAnti])


func toScalars(c: Complex64): MultivectorScalars =
  ## Map complex number to pair, 1 to 𝟏 and i to 𝟙, where ε² = -1.
  initMultivectorScalars(c.re, c.im)


func idempotent(
  m: MultivectorScalars, function: proc (x: float): float {.nimcall, noSideEffect.}
): MultivectorScalars =
  ## Apply function on each idempotent of split-complex pair, i.e. at s + t and at s − t.
  let
    (s, t) = (m[Basis.scalar], m[Basis.scalarAnti])
    (plus, minus) = (function(s + t), function(s - t))
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
  ## Hold squares and products of pairs against library.
  let (one, one_anti) = (initElement(Basis.scalar), initElement(Basis.scalarAnti))
  doAssert (one_anti ⟑ one_anti) =~ SQUARES_WEDGE_DOT.base * one,
    &"Square must agree with library's ⟑; got `{SQUARES_WEDGE_DOT.base}`."
  doAssert (one ⟇ one) =~ SQUARES_WEDGE_DOT.anti * one_anti,
    &"Square must agree with library's ⟇; got `{SQUARES_WEDGE_DOT.anti}`."
  for _ in 1..SAMPLES:
    let
      m = initMultivectorScalars(rand(-1.0..1.0), rand(-1.0..1.0))
      n = initMultivectorScalars(rand(-1.0..1.0), rand(-1.0..1.0))
    doAssert (m ⟑ n) =~ product(m, n), "Pair ⟑ must equal library's."
    doAssert (m ⟇ n) =~ productAnti(m, n), "Pair ⟇ must equal library's."


proc holdFunctions(pairs: openArray[MultivectorScalars]): array[8, int] =
  ## Hold law of each function and its anti form on pairs; count samples each guarded law passed.
  let (unit, unit_anti) = (initMultivectorScalars(1, 0), initMultivectorScalars(0, 1))
  for i, m in pairs:
    let
      (s, t) = (m[Basis.scalar], m[Basis.scalarAnti])
      is_small = abs(s) <= 1 and abs(t) <= 1

    # Hold inverse: 𝐦 ⟑ 𝐦⟑⁻¹ = 𝟏 and 𝐦 ⟇ 𝐦⟇⁻¹ = 𝟙, and none exactly where modulus vanishes.
    let (inverse_m, inverse_anti) = (inverse(m), inverseAnti(m))
    doAssert inverse_m.isSome == isInvertible(m), &"Inverse exists by modulus; got `{m=}`."
    doAssert inverse_anti.isSome == isInvertible(complement(m)), &"Antiinverse; got `{m=}`."
    if inverse_m.isSome:
      inc result[0]
      doAssert product(m, inverse_m.get).isNear(unit, m.size * inverse_m.get.size),
        &"𝐦 ⟑ 𝐦⟑⁻¹ must be 𝟏; got `{m=}`."
    if inverse_anti.isSome:
      doAssert productAnti(m, inverse_anti.get).isNear(unit_anti, m.size * inverse_anti.get.size),
        &"𝐦 ⟇ 𝐦⟇⁻¹ must be 𝟙; got `{m=}`."

    # Hold root: ⟑√𝐦 ⟑ ⟑√𝐦 = 𝐦 with s ≥ 0, and none exactly outside domain.
    let (root, root_anti) = (sqrt(m), sqrtAnti(m))
    doAssert root.isSome == isRooted(m), &"Root exists by domain; got `{m=}`."
    doAssert root_anti.isSome == isRooted(complement(m)), &"Antiroot by domain; got `{m=}`."
    if root.isSome:
      inc result[1]
      doAssert product(root.get, root.get) =~ m and root.get[Basis.scalar] >= 0,
        &"⟑√𝐦 ⟑ ⟑√𝐦 must be 𝐦, s ≥ 0; got `{root.get.toMultivector}` for `{m.toMultivector}`."
    if root_anti.isSome:
      doAssert productAnti(root_anti.get, root_anti.get) =~ m and
          root_anti.get[Basis.scalarAnti] >= 0,
        &"⟇√𝐦 ⟇ ⟇√𝐦 must be 𝐦, t ≥ 0; got `{root_anti.get.toMultivector}`."

    # Hold inverse root: (⟑√𝐦)⟑⁻¹ squared, times 𝐦 under ⟑, is 𝟏 where root and inverse exist.
    let root_inverse = sqrtInverse(m)
    if root_inverse.isSome:
      inc result[2]
      let square = product(root_inverse.get, root_inverse.get)
      doAssert product(square, m).isNear(unit, square.size * m.size),
        &"Square of (⟑√𝐦)⟑⁻¹, times 𝐦, must be 𝟏; got `{m=}`."
    let root_inverse_anti = sqrtInverseAnti(m)
    if root_inverse_anti.isSome:
      let square_anti = productAnti(root_inverse_anti.get, root_inverse_anti.get)
      doAssert productAnti(square_anti, m).isNear(unit_anti, square_anti.size * m.size),
        &"Square of (⟇√𝐦)⟇⁻¹, times 𝐦, must be 𝟙; got `{m=}`."

    # Hold exponential, sine and cosine against power series, and their addition laws.
    if is_small:
      inc result[3]
      doAssert exp(m) =~ series(m, TERMS_EXP, as_anti = false), &"exp⟑ is series; got `{m=}`."
      doAssert sin(m) =~ series(m, TERMS_SIN, as_anti = false), &"sin⟑ is series; got `{m=}`."
      doAssert cos(m) =~ series(m, TERMS_COS, as_anti = false), &"cos⟑ is series; got `{m=}`."
      doAssert expAnti(m) =~ series(m, TERMS_EXP, as_anti = true), &"exp⟇ is series; got `{m=}`."
      doAssert sinAnti(m) =~ series(m, TERMS_SIN, as_anti = true), &"sin⟇ is series; got `{m=}`."
      doAssert cosAnti(m) =~ series(m, TERMS_COS, as_anti = true), &"cos⟇ is series; got `{m=}`."
    let n = pairs[(i+1) mod pairs.len]
    doAssert exp(n + m) =~ product(exp(n), exp(m)), &"exp⟑ of sum is product; got `{m=}`."
    doAssert expAnti(n + m) =~ productAnti(expAnti(n), expAnti(m)), &"Same under ⟇; got `{m=}`."
    doAssert product(sin(m), sin(m)) + product(cos(m), cos(m)) =~ unit,
      &"Squares of sin⟑𝐦 and cos⟑𝐦 must sum to 𝟏; got `{m=}`."
    doAssert productAnti(sinAnti(m), sinAnti(m)) + productAnti(cosAnti(m), cosAnti(m)) =~
        unit_anti,
      &"Squares of sin⟇𝐦 and cos⟇𝐦 must sum to 𝟙; got `{m=}`."

    # Hold tangent: tan⟑𝐦 ⟑ cos⟑𝐦 = sin⟑𝐦, and none exactly where cosine has no inverse.
    let (tangent, tangent_anti) = (tan(m), tanAnti(m))
    doAssert tangent.isSome == isInvertible(cos(m)), &"Tangent exists by cosine; got `{m=}`."
    if tangent.isSome:
      inc result[4]
      doAssert product(tangent.get, cos(m)).isNear(sin(m), tangent.get.size * cos(m).size),
        &"tan⟑𝐦 ⟑ cos⟑𝐦 must be sin⟑𝐦; got `{m=}`."
    if tangent_anti.isSome:
      let scale_anti = tangent_anti.get.size * cosAnti(m).size
      doAssert productAnti(tangent_anti.get, cosAnti(m)).isNear(sinAnti(m), scale_anti),
        &"tan⟇𝐦 ⟇ cos⟇𝐦 must be sin⟇𝐦; got `{m=}`."

    # Hold division: (𝐧 / 𝐦) ⟇ 𝐦 = 𝐧, for pair and for multivector.
    let quotient = n / m
    if quotient.isSome:
      inc result[5]
      doAssert productAnti(quotient.get, m).isNear(n, quotient.get.size * m.size),
        &"(𝐧 / 𝐦) ⟇ 𝐦 must be 𝐧; got `{m=}`."
      let whole = toMultivectorScalars((n.toMultivector / m).get ⟇ m.toMultivector)
      doAssert whole.isNear(n, quotient.get.size * m.size), "(𝐧 / 𝐦) ⟇ 𝐦 must be 𝐧, as multivector."

    # Hold authority of algebra: Lengyel's forms, complex functions, or idempotents.
    when SQUARES_WEDGE_DOT.base == 0:
      doAssert exp(m) =~ expLengyel(s, t), &"`Exp` of Lengyel; got `{m=}`."
      doAssert sin(m) =~ sinLengyel(s, t), &"`Sin` of Lengyel; got `{m=}`."
      doAssert cos(m) =~ cosLengyel(s, t), &"`Cos` of Lengyel; got `{m=}`."
      doAssert expAnti(m) =~ complement(expLengyel(t, s)), "`AntiExp` of Lengyel."
      if s > 0:
        inc result[6]
        doAssert root.get =~ sqrtLengyel(s, t), &"`Sqrt` of Lengyel; got `{m=}`."
        doAssert root_inverse.get =~ sqrtInverseLengyel(s, t), "`InverseSqrt`."
        doAssert inverse_m.get =~ inverseLengyel(s, t), &"`Inverse`; got `{m=}`."
      if t > 0:
        doAssert root_anti.get =~ complement(sqrtLengyel(t, s)), "`AntiSqrt` of Lengyel."
        doAssert inverse_anti.get =~ complement(inverseLengyel(t, s)), "`AntiInverse`."
      if tangent.isSome:
        doAssert tangent.get =~ tanLengyel(s, t), &"`Tan` of Lengyel; got `{m=}`."
    elif SQUARES_WEDGE_DOT.base == -1:
      inc result[6]
      doAssert root.get =~ sqrt(m.toComplex).toScalars, &"Principal complex root; got `{m=}`."
      doAssert exp(m) =~ exp(m.toComplex).toScalars, &"Complex exponential; got `{m=}`."
      doAssert sin(m) =~ sin(m.toComplex).toScalars, &"Complex sine; got `{m=}`."
      doAssert cos(m) =~ cos(m.toComplex).toScalars, &"Complex cosine; got `{m=}`."
      if inverse_m.isSome:
        doAssert inverse_m.get =~ inv(m.toComplex).toScalars, &"Complex inverse; got `{m=}`."
      if tangent.isSome:
        doAssert tangent.get =~ tan(m.toComplex).toScalars, &"Complex tangent; got `{m=}`."
    else:
      doAssert exp(m) =~ m.idempotent(math.exp), &"Exponential on idempotents; got `{m=}`."
      doAssert sin(m) =~ m.idempotent(math.sin), &"Sine on idempotents; got `{m=}`."
      doAssert cos(m) =~ m.idempotent(math.cos), &"Cosine on idempotents; got `{m=}`."
      if root.isSome:
        inc result[6]
        doAssert root.get =~ m.idempotent(math.sqrt), &"Root on idempotents; got `{m=}`."

    # Hold root of small part without cancellation: residual of 𝟙 within few rounding errors.
    if root.isSome and abs(t) > 0:
      let residual = abs(product(root.get, root.get)[Basis.scalarAnti] - t)
      doAssert residual <= 8 * epsilon(Coefficient) * max(abs(s), abs(t)),
        &"Root must not cancel small part; got `{residual=}` for `{m.toMultivector}`."
      inc result[7]


proc holdNorms(): tuple[nan_float, radius_none: int] =
  ## Hold norms of library against roots of pair: bulk and weight norms under rigid metric, and
  ##   radius norm under conformal one; count float roots of 𝐦∘𝐦 that `|⊘` leaves NaN.
  doAssert sizeof(MultivectorScalars) == 2 * sizeof(Coefficient),
    &"Homogeneous scalar must hold two coefficients unpadded; got `{sizeof(MultivectorScalars)}`."
  doAssert (SQUARES_WEDGE_DOT.anti == 0) xor IS_CONFORMAL,
    "Pair must be dual under rigid metric alone."

  # Hold roots of basis elements against norms of library, where one part of root is zero.
  when IS_RIGID:
    for basis in Basis:
      let
        element = initElement(basis)
        bulk = sqrt(initMultivectorScalars((element ∙ element)[Basis.scalar], 0))
        weight = sqrtAnti(initMultivectorScalars(0, (element ∘ element)[Basis.scalarAnti]))
      doAssert bulk.isSome and bulk.get =~ |∙element,
        &"Root of 𝐞∙𝐞 under ⟑ must equal bulk norm of library; got `{bulk}`."
      doAssert weight.isSome and weight.get =~ |∘element,
        &"Root of 𝐞∘𝐞 under ⟇ must equal weight norm of library; got `{weight}`."

  # Hold norms on seeded multivectors.
  for _ in 1..SAMPLES:
    var m: Multivector
    for basis in Basis: m[basis] = rand(-1.0..1.0)
    let root_dot = sqrt(initMultivectorScalars((m ∙ m)[Basis.scalar], 0))
    if root_dot.isSome:
      doAssert product(root_dot.get, root_dot.get).toMultivector =~ (m ∙ m),
        &"⟑√(𝐦∙𝐦), squared under ⟑, must be 𝐦∙𝐦; got `{root_dot.get.toMultivector}`."
    when IS_RIGID:
      let
        (bulk, weight) = (normBulk(m), normWeight(m))
        root_weight = sqrtAnti(initMultivectorScalars(0, (m ∘ m)[Basis.scalarAnti]))
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
        radius = normRadius(m)
      if sqrt(square).isNaN: inc result.nan_float
      doAssert radius.isSome == (SQUARES_WEDGE_DOT.anti == -1 or square >= 0),
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
          root = normRadius(point)
        doAssert abs(square - sign * radius^2) <= TOLERANCE_ABS,
          &"Square must be 2aʷaᵘ - |a|², by Table 4.13; got `{square}` for radius `{radius}`."
        if sign > 0:
          doAssert root.isSome and abs(root.get[Basis.scalarAnti] - radius) <= TOLERANCE_ABS and
              root.get[Basis.scalar] == 0,
            &"Real radius norm must land on 𝟙; got `{root}`."
        elif SQUARES_WEDGE_DOT.base == -1:
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
        radius = sqrtAnti(dot_anti)
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
      let radius = sqrtAnti(toMultivectorScalars(point ∘ point))
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
    doAssert radius.isSome, "Complex pair must have root."
    doAssert radius.get =~ initMultivectorScalars(0.6657714603000752, 0),
      &"Radius norm must be imaginary 0.665771𝟏; got `{radius.get.toMultivector}`."
    doAssert productAnti(radius.get, radius.get) =~ dot_anti, "‖𝐦‖⊘ ⟇ ‖𝐦‖⊘ must be 𝐦∘𝐦."


proc main(): int =
  ## Hold laws on structured and seeded samples; print counts where they hold, and exit zero.
  randomize(SEED)
  holdTables()
  var pairs: seq[MultivectorScalars]
  for (s, t) in [
    (0.0, 0.0), (1.0, 0.0), (-1.0, 0.0), (0.0, 1.0), (0.0, -1.0), (1.0, 1.0), (1.0, -1.0),
    (-1.0, 1.0), (2.0, 1.0), (1.0, 2.0), (1.0, 1e-10), (-1.0, 1e-10), (1e-10, 1.0),
    (-0.44325163735009460, 0.0), (0.0, -0.44325163735009460), (PI / 2, 0.0),
  ]:
    pairs.add initMultivectorScalars(s, t)
  for _ in 1..SAMPLES: pairs.add initMultivectorScalars(rand(-1.0..1.0), rand(-1.0..1.0))
  let passed = holdFunctions(pairs)
  for count in passed:
    doAssert count >= SAMPLES_FLOOR, &"Guard must pass floor of samples; got `{passed}`."
  let radius = holdRadius()
  holdSuiteSample()
  let norms = holdNorms()
  when IS_CONFORMAL: holdPointsRound()
  let
    kind = if IS_CONFORMAL: "conformal" else: "rigid"
    square = SQUARES_WEDGE_DOT.base
  echo &"homogeneous-scalar: laws hold at {DIMENSIONS}D {kind}, ε² = {square}, " &
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
