## Prototype homogeneous scalar, pair of scalar and antiscalar, over basis-set types of P04
##   (`homogeneous-scalar`).
##   Evaluation compiles this against library at pin, at each algebra its claim names, and exit
##     code is verdict: every law below holds, or program stops on assertion.
##   Homogeneous scalar is basis-set type of 𝟏 and 𝟙: value x/y, kept with its weight y, as
##     homogeneous point keeps position with its weight. 𝟏 is unit of geometric product, and 𝟙 of
##     antiproduct, as Lengyel's `DualNum` has `Sqrt` and `AntiSqrt`. Square of other part under
##     each, read from library's table, picks arithmetic of pair:
##       0 under rigid metric, so pair is dual number;
##       -1 at cga4d and cga5d, so pair is complex number;
##       +1 at cga3d and cga6d, so pair is split-complex number.
##     Inverse, root and exponential under geometric product follow from that square alone, and
##     each anti form is their complement.
##     Division is under antiproduct, as Lengyel's is.
##   Bulk norm, weight norm, geometric norm and unitization stand under rigid metric alone, where
##     they equal library's. Conformal algebras keep library's four part norms (Table 4.12) and
##     unitization of P11 (`unitize-general`); there radius norm alone is homogeneous scalar.
##
##   Cost: norms read library's `Multivector`, since prototype of P04 emits no squared norm: each
##     is unary 2D table. Division of multivector is whole antiproduct of library. Record says so.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/[math, random]

import pga
import pga/cayleys

import "../04-exact-kinds/prototype" {.all.}


type ScalarHomogeneous* = MultivectorOf[{Basis.scalar, Basis.scalarAnti}]
  ## Define pair x𝟏 + y𝟙: bulk x on scalar, weight y on antiscalar.


func square(cayleys: Cayley2D; part, unit: Basis): int {.compileTime.} =
  ## Read coefficient of unit in part times part from library's table of product.
  for term in cayleys[part][part]:
    doAssert term.basis == unit, "square of part lands on unit alone"
    result += (if term.is_negated: -1 else: 1)


const
  SQUARE_BULK* = square(CAYLEYS_WEDGE_DOT.anti, Basis.scalar, Basis.scalarAnti)
    ## Square of 𝟏 under antiproduct, as multiple of 𝟙: 0 rigid, -1 at cga4d and cga5d, else +1.
  SQUARE_WEIGHT* = square(CAYLEYS_WEDGE_DOT.base, Basis.scalarAnti, Basis.scalar)
    ## Square of 𝟙 under geometric product, as multiple of 𝟏.
  SAMPLES = 256  ## Seeded samples each law is checked on.
  SEED = 0  ## Seed of sample generator, so every run checks same samples.
  TERMS_SERIES = 30  ## Terms of power series exponential is checked against.

static:
  doAssert SQUARE_BULK in [-1, 0, 1], "pair is complex, dual or split-complex in every algebra"
  doAssert SQUARE_WEIGHT == SQUARE_BULK, "complement carries geometric product to antiproduct"



#[ Arithmetic ]#

func initScalarHomogeneous*(bulk, weight: float): ScalarHomogeneous {.noinit.} =
  ## Make homogeneous scalar bulk 𝟏 + weight 𝟙.
  result[Basis.scalar] = bulk
  result[Basis.scalarAnti] = weight


func `+`*(y, z: ScalarHomogeneous): ScalarHomogeneous =
  ## Add homogeneous scalars, part by part.
  initScalarHomogeneous(
    y[Basis.scalar] + z[Basis.scalar], y[Basis.scalarAnti] + z[Basis.scalarAnti],
  )


func complement(z: ScalarHomogeneous): ScalarHomogeneous =
  ## Get complement of homogeneous scalar, i.e. z̅: swap parts, as 𝟏̅ = 𝟙 and 𝟙̅ = 𝟏.
  initScalarHomogeneous(z[Basis.scalarAnti], z[Basis.scalar])


func inverse*(z: ScalarHomogeneous): ScalarHomogeneous =
  ## Get inverse under geometric product, i.e. z⁻¹ with z ⟑ z⁻¹ = 𝟏: conjugate over its square size.
  ##   None where bulk is zero under rigid metric, or where both parts are under conformal; there
  ##     result is infinite or NaN, as float division gives.
  let
    (bulk, weight) = (z[Basis.scalar], z[Basis.scalarAnti])
    size = bulk * bulk - float(SQUARE_WEIGHT) * weight * weight
  initScalarHomogeneous(bulk / size, -weight / size)


func sqrt*(z: ScalarHomogeneous): ScalarHomogeneous =
  ## Get principal root under geometric product, i.e. w with w ⟑ w = z.
  ##   Dual number: √x 𝟏 + y / (2√x) 𝟙, real where bulk x is positive, and 0 where z is 0.
  ##   Complex number: root of x + y i, so negative bulk gives root on weight, as i.
  ##   Split-complex number: roots of x + y and x - y, its parts on each idempotent, real where
  ##     bulk x is at least |y|.
  let (bulk, weight) = (z[Basis.scalar], z[Basis.scalarAnti])
  when SQUARE_WEIGHT == 0:
    let root = sqrt(bulk)
    initScalarHomogeneous(root, if weight == 0: 0.0 else: weight / (2 * root))
  elif SQUARE_WEIGHT == -1:
    let size = hypot(bulk, weight)
    initScalarHomogeneous(sqrt((size + bulk) / 2), copySign(sqrt((size - bulk) / 2), weight))
  else:
    let (root_plus, root_minus) = (sqrt(bulk + weight), sqrt(bulk - weight))
    initScalarHomogeneous((root_plus + root_minus) / 2, (root_plus - root_minus) / 2)


func exp*(z: ScalarHomogeneous): ScalarHomogeneous =
  ## Raise e to homogeneous scalar under geometric product, i.e. e^x (C 𝟏 + S 𝟙) for z = x𝟏 + y𝟙.
  ##   Dual number: C = 1, S = y. Complex number: C = cos y, S = sin y.
  ##   Split-complex number: C = cosh y, S = sinh y.
  let
    (bulk, weight) = (z[Basis.scalar], z[Basis.scalarAnti])
    scale = exp(bulk)
  when SQUARE_WEIGHT == 0:
    initScalarHomogeneous(scale, scale * weight)
  elif SQUARE_WEIGHT == -1:
    initScalarHomogeneous(scale * cos(weight), scale * sin(weight))
  else:
    initScalarHomogeneous(scale * cosh(weight), scale * sinh(weight))


func inverseAnti*(z: ScalarHomogeneous): ScalarHomogeneous =
  ## Get inverse under antiproduct, i.e. z⁻¹ with z ⟇ z⁻¹ = 𝟙, as complement of inverse of z̅.
  complement(inverse(complement(z)))


func sqrtAnti*(z: ScalarHomogeneous): ScalarHomogeneous =
  ## Get principal root under antiproduct, i.e. w with w ⟇ w = z, as complement of root of z̅.
  ##   Real where weight is positive under rigid metric, and where weight is at least |bulk| in
  ##     split-complex algebra; negative weight gives root on bulk, as i, in complex one.
  complement(sqrt(complement(z)))


func expAnti*(z: ScalarHomogeneous): ScalarHomogeneous =
  ## Raise e to homogeneous scalar under antiproduct, as complement of exponential of z̅.
  complement(exp(complement(z)))


func `/`*(y, z: ScalarHomogeneous): ScalarHomogeneous =
  ## Divide under antiproduct, i.e. y ⟇ z⁻¹, as Lengyel's `DualNum` does.
  y ⟇ inverseAnti(z)


func `/`*(m: Multivector, z: ScalarHomogeneous): Multivector =
  ## Divide multivector by homogeneous scalar under antiproduct, i.e. 𝐦 ⟇ z⁻¹.
  m ⟇ inverseAnti(z).toMultivector



#[ Norms ]#

when IS_RIGID:
  func normBulk*(m: Multivector): ScalarHomogeneous =
    ## Get bulk norm as root under geometric product, i.e. ‖𝐦‖∙ = √(𝐦∙𝐦), as wiki takes it.
    ##   Reads library's whole dot, which equals `|∙²` under rigid metric.
    sqrt(initScalarHomogeneous((m ∙ m)[Basis.scalar], 0))


  func normWeight*(m: Multivector): ScalarHomogeneous =
    ## Get weight norm as root under antiproduct, i.e. ‖𝐦‖∘ = √(𝐦∘𝐦), as wiki takes it.
    ##   Reads library's whole antidot, which equals `|∘²` under rigid metric.
    sqrtAnti(initScalarHomogeneous(0, (m ∘ m)[Basis.scalarAnti]))


  func norm*(m: Multivector): ScalarHomogeneous =
    ## Get geometric norm, i.e. ‖𝐦‖ = ‖𝐦‖∙ + ‖𝐦‖∘.
    normBulk(m) + normWeight(m)


  func unitize*(m: Multivector): Multivector =
    ## Unitize by division by weight norm, i.e. 𝐦̂ = 𝐦 ÷ ‖𝐦‖∘; equals library's `^` where weight
    ##   is nonzero. Zero weight gives NaN, where `^` does nothing.
    ##   Rigid metric alone: in conformal algebras library keeps `^∘` of P11 (`unitize-general`).
    m / normWeight(m)


when IS_CONFORMAL:
  func normRadius*(m: Multivector): ScalarHomogeneous =
    ## Get radius norm as root under antiproduct, i.e. ‖𝐦‖⊘ = √(𝐦∘𝐦), book's (4.45).
    ##   Real for real object, on 𝟙. Imaginary object has root on 𝟏, as i, at cga4d and cga5d,
    ##     where `|⊘` at pin is NaN; split-complex pair at cga3d and cga6d has none, so NaN stays.
    sqrtAnti(initScalarHomogeneous(0, (m ∘ m)[Basis.scalarAnti]))



#[ Laws ]#

proc sampleRooted(unit: static Basis): ScalarHomogeneous =
  ## Draw homogeneous scalar with real root.
  ##   Part on unit lies in (0, 1] under rigid metric, any part does in complex algebra, and part
  ##     on unit exceeds other part's size by (0, 1] in split-complex one.
  result = sample(ScalarHomogeneous)
  when SQUARE_BULK == 0: result[unit] = 1.0 - rand(1.0)
  elif SQUARE_BULK == 1:
    const other = if unit == Basis.scalar: Basis.scalarAnti else: Basis.scalar
    result[unit] = abs(result[other]) + 1.0 - rand(1.0)


proc sampleWhole(): Multivector =
  ## Draw multivector with every coefficient uniform in [-1, 1].
  for basis in Basis: result[basis] = rand(-1.0..1.0)


proc series(z: ScalarHomogeneous; is_anti: static bool): Multivector =
  ## Sum power series of exponential under library's product or antiproduct, independent of
  ##   closed form.
  var term = initElement(when is_anti: Basis.scalarAnti else: Basis.scalar)
  for k in 1..TERMS_SERIES:
    result = result + term
    term = (when is_anti: term ⟇ z.toMultivector else: term ⟑ z.toMultivector) * (1 / float(k))


when IS_CONFORMAL:
  proc holdRoundPoints() =
    ## Hold book's radius norm (4.45) of round point, √(2aʷaᵘ - |a|²) by Table 4.13: real or
    ##   imaginary, never NaN.
    for sign in [1.0, -1.0]:
      for _ in 1..SAMPLES:
        let radius = 0.1 + rand(1.0)
        var (point, distance_squared) = (initElement(Basis.origin), 0.0)
        for basis in Basis(1)..Basis(DIMENSIONS - 2):
          point[basis] = rand(-1.0..1.0)
          distance_squared += point[basis] ^ 2
        point[Basis.infinity] = (distance_squared + sign * radius ^ 2) / 2
        let
          square = (point ∘ point)[Basis.scalarAnti]
          root = normRadius(point)
        doAssert abs(square - sign * radius ^ 2) <= 1e-12, "a ∘ a = 2aʷaᵘ - |a|², by Table 4.13"
        if sign > 0:
          doAssert abs(root[Basis.scalarAnti] - radius) <= 1e-12 and root[Basis.scalar] == 0,
            "real radius norm lands on 𝟙"
        elif SQUARE_WEIGHT == -1:
          doAssert abs(root[Basis.scalar] - radius) <= 1e-12 and root[Basis.scalarAnti] == 0,
            "imaginary radius norm lands on 𝟏, as i"
        else:
          doAssert root[Basis.scalar].isNaN, "split-complex pair has no root of negative square"


proc main(): int =
  ## Hold laws on seeded samples; print where they hold, and exit zero.
  randomize(SEED)
  let (one, one_anti) = (initElement(Basis.scalar), initElement(Basis.scalarAnti))
  doAssert sizeof(ScalarHomogeneous) == 2 * sizeof(float) and
    alignof(ScalarHomogeneous) == 2 * sizeof(float), "homogeneous scalar holds two floats, unpadded"
  doAssert (one ⟇ one) =~ float(SQUARE_BULK) * one_anti,
    "table read agrees with library's antiproduct"
  doAssert (one_anti ⟑ one_anti) =~ float(SQUARE_WEIGHT) * one,
    "table read agrees with library's geometric product"
  doAssert SQUARE_BULK == 0 xor IS_CONFORMAL, "dual under rigid metric alone"
  let zero = initScalarHomogeneous(0, 0)
  doAssert sqrt(zero).toMultivector =~ 0.0 and sqrtAnti(zero).toMultivector =~ 0.0,
    "root of zero is zero, never NaN"
  when IS_RIGID:
    for basis in Basis:
      let element = initElement(basis)
      doAssert normBulk(element).toMultivector =~ |∙element,
        "bulk norm of basis element equals library's, zero weight part included"
      doAssert normWeight(element).toMultivector =~ |∘element,
        "weight norm of basis element equals library's, zero bulk part included"
      doAssert norm(element).toMultivector =~ |element, "geometric norm of basis element"
  when IS_CONFORMAL:
    var
      nan_float = 0  # float root of 𝐦∘𝐦 that gives NaN, as `|⊘` takes it at pin
      nan_radius = 0  # radius norm that gives NaN, at split-complex algebras alone
  for _ in 1..SAMPLES:
    let
      (y, z) = (sample(ScalarHomogeneous), sample(ScalarHomogeneous))
      (rooted, rooted_anti) = (sampleRooted(Basis.scalar), sampleRooted(Basis.scalarAnti))
      m = sampleWhole()
      root_dot = sqrt(initScalarHomogeneous((m ∙ m)[Basis.scalar], 0))
    doAssert complement(z).toMultivector =~ /z.toMultivector, "complement equals library's"
    doAssert (z.toMultivector ⟑ one) =~ z.toMultivector, "𝟏 is unit of geometric product"
    doAssert (z.toMultivector ⟑ inverse(z).toMultivector) =~ one, "z ⟑ z⁻¹ = 𝟏"
    doAssert (sqrt(rooted).toMultivector ⟑ sqrt(rooted).toMultivector) =~ rooted.toMultivector,
      "√z ⟑ √z = z"
    doAssert exp(z).toMultivector =~ series(z, is_anti = false),
      "exp is its power series under geometric product"
    doAssert exp(y + z).toMultivector =~ (exp(y).toMultivector ⟑ exp(z).toMultivector),
      "exp(y + z) = exp(y) ⟑ exp(z)"
    doAssert (y ⟇ z) is ScalarHomogeneous,
      "antiproduct of homogeneous scalars is homogeneous scalar, by table"
    doAssert (z.toMultivector ⟇ one_anti) =~ z.toMultivector, "𝟙 is unit of antiproduct"
    doAssert (z.toMultivector ⟇ inverseAnti(z).toMultivector) =~ one_anti, "z ⟇ z⁻¹ = 𝟙"
    doAssert ((y / z).toMultivector ⟇ z.toMultivector) =~ y.toMultivector, "(y / z) ⟇ z = y"
    doAssert (sqrtAnti(rooted_anti).toMultivector ⟇ sqrtAnti(rooted_anti).toMultivector) =~
        rooted_anti.toMultivector,
      "√z ⟇ √z = z"
    doAssert expAnti(z).toMultivector =~ series(z, is_anti = true),
      "exp is its power series under antiproduct"
    doAssert expAnti(y + z).toMultivector =~
        (expAnti(y).toMultivector ⟇ expAnti(z).toMultivector),
      "exp(y + z) = exp(y) ⟇ exp(z)"
    if SQUARE_WEIGHT != 1 or (m ∙ m)[Basis.scalar] >= 0:
      doAssert not root_dot[Basis.scalar].isNaN and not root_dot[Basis.scalarAnti].isNaN,
        "root of 𝐦∙𝐦 is never NaN, but where split-complex pair has none"
      doAssert (root_dot.toMultivector ⟑ root_dot.toMultivector) =~ (m ∙ m),
        "√(𝐦∙𝐦) ⟑ √(𝐦∙𝐦) = 𝐦∙𝐦"
    when IS_RIGID:
      let (bulk, weight) = (normBulk(m), normWeight(m))
      doAssert (weight.toMultivector ⟇ weight.toMultivector) =~ (m ∘ m), "‖𝐦‖∘ ⟇ ‖𝐦‖∘ = 𝐦∘𝐦"
      doAssert bulk.toMultivector =~ |∙m, "bulk norm equals library's"
      doAssert weight.toMultivector =~ |∘m, "weight norm equals library's"
      doAssert norm(m).toMultivector =~ |m, "geometric norm equals library's"
      let unitized = norm(m) / weight
      doAssert unitized.toMultivector =~
          initScalarHomogeneous((|∙m)[Basis.scalar] / (|∘m)[Basis.scalarAnti], 1).toMultivector,
        "homogeneous scalar unitizes to distance 𝟏 + 𝟙"
      doAssert unitize(m) =~ ^m, "unitize equals library's"
    else:
      let radius = normRadius(m)
      if sqrt((m ∘ m)[Basis.scalarAnti]).isNaN: inc nan_float
      if radius[Basis.scalar].isNaN or radius[Basis.scalarAnti].isNaN:
        doAssert SQUARE_WEIGHT == 1, "radius norm is never NaN in complex algebra"
        inc nan_radius
        continue
      doAssert (radius.toMultivector ⟇ radius.toMultivector) =~ (m ∘ m), "‖𝐦‖⊘ ⟇ ‖𝐦‖⊘ = 𝐦∘𝐦"
  when IS_CONFORMAL:
    holdRoundPoints()
    echo "homogeneous-scalar: laws hold at ", DIMENSIONS, "D conformal; float root of 𝐦∘𝐦 NaN ",
      nan_float, " of ", SAMPLES, ", radius norm NaN ", nan_radius
  else:
    echo "homogeneous-scalar: laws hold at ", DIMENSIONS, "D rigid"
  0


when isMainModule:
  quit main()
