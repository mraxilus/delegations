## Prototype homogeneous scalar, pair of scalar and antiscalar, over exact kinds of P04
##   (`homogeneous-scalar`).
##   Evaluation compiles this against changed library at each algebra its claim names, and exit code
##     is verdict: every law below holds, or program stops on assertion.
##   Homogeneous scalar is exact kind of 𝟏 and 𝟙: value x/y, kept with its weight y, as homogeneous
##     point keeps position with its weight. 𝟏 is unit of geometric product, and 𝟙 of antiproduct,
##     as Lengyel's `DualNum` has `Sqrt` and `AntiSqrt`. Square of other part under each, read from
##     library's table, is 0 under rigid metric, so pair is dual number, and -1 under conformal
##     metric, so pair is complex number. Inverse, root and exponential under geometric product
##     follow from that square alone, and each anti form is their complement. Division is under
##     antiproduct, as Lengyel's is.
##
##   Cost: norms read library's `Multivector`, since P04 emits no squared norm; record says so.

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
    ## Square of 𝟏 under antiproduct, as multiple of 𝟙: 0 under rigid metric, -1 under conformal.
  SQUARE_WEIGHT* = square(CAYLEYS_WEDGE_DOT.base, Basis.scalarAnti, Basis.scalar)
    ## Square of 𝟙 under geometric product, as multiple of 𝟏.
  SAMPLES = 256  ## Seeded samples each law is checked on.
  SEED = 0  ## Seed of sample generator, so every run checks same samples.
  TERMS_SERIES = 30  ## Terms of power series exponential is checked against.

static:
  doAssert SQUARE_BULK in [0, -1], "pair is dual or complex in every algebra of library"
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
  ##   Dual number: √x 𝟏 + y / (2√x) 𝟙, real where bulk x is positive.
  ##   Complex number: root of x + y i, so negative bulk gives root on weight, as i.
  let (bulk, weight) = (z[Basis.scalar], z[Basis.scalarAnti])
  when SQUARE_WEIGHT == 0:
    let root = sqrt(bulk)
    initScalarHomogeneous(root, weight / (2 * root))
  else:
    let size = hypot(bulk, weight)
    initScalarHomogeneous(sqrt((size + bulk) / 2), copySign(sqrt((size - bulk) / 2), weight))


func exp*(z: ScalarHomogeneous): ScalarHomogeneous =
  ## Raise e to homogeneous scalar under geometric product, i.e. e^x (C 𝟏 + S 𝟙) for z = x𝟏 + y𝟙.
  ##   Dual number: C = 1, S = y. Complex number: C = cos y, S = sin y.
  let
    (bulk, weight) = (z[Basis.scalar], z[Basis.scalarAnti])
    scale = exp(bulk)
  when SQUARE_WEIGHT == 0:
    initScalarHomogeneous(scale, scale * weight)
  else:
    initScalarHomogeneous(scale * cos(weight), scale * sin(weight))


func inverseAnti*(z: ScalarHomogeneous): ScalarHomogeneous =
  ## Get inverse under antiproduct, i.e. z⁻¹ with z ⟇ z⁻¹ = 𝟙, as complement of inverse of z̅.
  complement(inverse(complement(z)))


func sqrtAnti*(z: ScalarHomogeneous): ScalarHomogeneous =
  ## Get principal root under antiproduct, i.e. w with w ⟇ w = z, as complement of root of z̅.
  ##   Real where weight is positive under rigid metric; negative weight gives root on bulk, as i,
  ##     under conformal metric.
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

func normBulk*(m: Multivector): ScalarHomogeneous =
  ## Get bulk norm as root under geometric product, i.e. ‖𝐦‖∙ = √(𝐦∙𝐦), as wiki takes it.
  ##   Reads whole dot, since `|∙²` at pin squares round bulk alone under conformal metric.
  sqrt(initScalarHomogeneous((m ∙ m)[Basis.scalar], 0))


func normWeight*(m: Multivector): ScalarHomogeneous =
  ## Get weight norm as root under antiproduct, i.e. ‖𝐦‖∘ = √(𝐦∘𝐦), as wiki takes it.
  ##   Reads whole antidot, since `|∘²` at pin squares round weight alone under conformal metric.
  sqrtAnti(initScalarHomogeneous(0, (m ∘ m)[Basis.scalarAnti]))


when IS_CONFORMAL:
  func normRadius*(m: Multivector): ScalarHomogeneous =
    ## Get radius norm as root under antiproduct, i.e. ‖𝐦‖⊘ = √(𝐦∘𝐦), book's (4.45).
    ##   Real for real object, imaginary, on 𝟏, for imaginary one. `|⊘` at pin is NaN for latter.
    sqrtAnti(initScalarHomogeneous(0, (m ∘ m)[Basis.scalarAnti]))


func norm*(m: Multivector): ScalarHomogeneous =
  ## Get geometric norm, i.e. ‖𝐦‖ = ‖𝐦‖∙ + ‖𝐦‖∘.
  normBulk(m) + normWeight(m)


func unitize*(m: Multivector): Multivector =
  ## Unitize by division by weight norm, i.e. 𝐦̂ = 𝐦 ÷ ‖𝐦‖∘.
  m / normWeight(m)



#[ Laws ]#

proc sampleRooted(unit: static Basis): ScalarHomogeneous =
  ## Draw homogeneous scalar with real root.
  ##   Part on unit lies in (0, 1] under rigid metric, and any part does under conformal metric.
  result = sample(ScalarHomogeneous)
  when SQUARE_BULK == 0: result[unit] = 1.0 - rand(1.0)


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
        else:
          doAssert abs(root[Basis.scalar] - radius) <= 1e-12 and root[Basis.scalarAnti] == 0,
            "imaginary radius norm lands on 𝟏, as i"


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
  doAssert SQUARE_BULK == (when IS_RIGID: 0 else: -1),
    "dual under rigid metric, complex under conformal"
  when IS_CONFORMAL:
    var nan_float = 0  # float root of 𝐦∘𝐦 that gives NaN, as `|⊘` takes it at pin
  for _ in 1..SAMPLES:
    let
      (y, z) = (sample(ScalarHomogeneous), sample(ScalarHomogeneous))
      (rooted, rooted_anti) = (sampleRooted(Basis.scalar), sampleRooted(Basis.scalarAnti))
      m = sampleWhole()
      bulk = normBulk(m)
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
    doAssert not bulk[Basis.scalar].isNaN and not bulk[Basis.scalarAnti].isNaN,
      "bulk norm is never NaN"
    doAssert (bulk.toMultivector ⟑ bulk.toMultivector) =~ (m ∙ m), "‖𝐦‖∙ ⟑ ‖𝐦‖∙ = 𝐦∙𝐦"
    when IS_RIGID:
      let weight = normWeight(m)
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
      doAssert not radius[Basis.scalar].isNaN and not radius[Basis.scalarAnti].isNaN,
        "radius norm is never NaN"
      doAssert (radius.toMultivector ⟇ radius.toMultivector) =~ (m ∘ m), "‖𝐦‖⊘ ⟇ ‖𝐦‖⊘ = 𝐦∘𝐦"
      if sqrt((m ∘ m)[Basis.scalarAnti]).isNaN: inc nan_float
  when IS_CONFORMAL:
    holdRoundPoints()
    echo "homogeneous-scalar: laws hold at ", DIMENSIONS, "D conformal; float root of 𝐦∘𝐦 NaN ",
      nan_float, " of ", SAMPLES, ", radius norm NaN 0"
  else:
    echo "homogeneous-scalar: laws hold at ", DIMENSIONS, "D rigid"
  0


when isMainModule:
  quit main()
