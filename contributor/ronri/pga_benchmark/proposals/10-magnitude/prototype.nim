## Prototype magnitude, pair of scalar and antiscalar, over exact kinds of P04 (`magnitude`).
##   Evaluation compiles this against changed library at each algebra its claim names, and exit code
##     is verdict: every law below holds, or program stops on assertion.
##   Magnitude is exact kind of 𝟏 and 𝟙, with antiproduct P04 emits from library's table, and 𝟙
##     as its unit. Square of 𝟏 under it, read from same table, is 0 under rigid metric, so pair
##     is dual number, and -1 under conformal metric, so pair is complex number with 𝟏 as i.
##     Inverse, division, root and exponential follow from that square alone.
##
##   Cost: norms read library's `Multivector`, since P04 emits no squared norm; record says so.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/[math, random]

import pga
import pga/cayleys

import "../04-exact-kinds/prototype" {.all.}


type Magnitude* = MultivectorOf[{Basis.scalar, Basis.scalarAnti}]
  ## Define pair x𝟏 + y𝟙: bulk x on scalar, weight y on antiscalar.


func squareBulk(): int {.compileTime.} =
  ## Read 𝟙 coefficient of 𝟏 ⟇ 𝟏 from library's antiproduct table.
  for term in CAYLEYS_WEDGE_DOT.anti[Basis.scalar][Basis.scalar]:
    doAssert term.basis == Basis.scalarAnti, "square of bulk lands on antiscalar alone"
    result += (if term.is_negated: -1 else: 1)


const
  SQUARE_BULK* = squareBulk()
    ## Square of 𝟏 under antiproduct, as multiple of 𝟙: 0 under rigid metric, -1 under conformal.
  SAMPLES = 256  ## Seeded samples each law is checked on.
  SEED = 0  ## Seed of sample generator, so every run checks same samples.
  TERMS_SERIES = 30  ## Terms of power series exponential is checked against.

static: doAssert SQUARE_BULK in [0, -1], "pair is dual or complex in every algebra of library"



#[ Arithmetic ]#

func initMagnitude*(bulk, weight: float): Magnitude {.noinit.} =
  ## Make magnitude bulk 𝟏 + weight 𝟙.
  result[Basis.scalar] = bulk
  result[Basis.scalarAnti] = weight


func `+`*(y, z: Magnitude): Magnitude =
  ## Add magnitudes, part by part.
  initMagnitude(y[Basis.scalar] + z[Basis.scalar], y[Basis.scalarAnti] + z[Basis.scalarAnti])


func inverse*(z: Magnitude): Magnitude =
  ## Get inverse under antiproduct, i.e. z⁻¹ with z ⟇ z⁻¹ = 𝟙: conjugate over its square size.
  ##   None where weight is zero under rigid metric, or where both parts are under conformal; there
  ##     result is infinite or NaN, as float division gives.
  let
    (bulk, weight) = (z[Basis.scalar], z[Basis.scalarAnti])
    size = weight * weight - float(SQUARE_BULK) * bulk * bulk
  initMagnitude(-bulk / size, weight / size)


func `/`*(y, z: Magnitude): Magnitude =
  ## Divide under antiproduct, i.e. y ⟇ z⁻¹.
  y ⟇ inverse(z)


func `/`*(m: Multivector, z: Magnitude): Multivector =
  ## Divide multivector by magnitude under antiproduct, i.e. 𝐦 ⟇ z⁻¹.
  m ⟇ inverse(z).toMultivector


func sqrt*(z: Magnitude): Magnitude =
  ## Get principal root under antiproduct, i.e. w with w ⟇ w = z.
  ##   Dual number: √y 𝟙 + x / (2√y) 𝟏, real where weight y is positive.
  ##   Complex number: root of y + x i, so negative weight gives root on bulk, as i.
  let (bulk, weight) = (z[Basis.scalar], z[Basis.scalarAnti])
  when SQUARE_BULK == 0:
    let root = sqrt(weight)
    initMagnitude(bulk / (2 * root), root)
  else:
    let size = hypot(weight, bulk)
    initMagnitude(copySign(sqrt((size - weight) / 2), bulk), sqrt((size + weight) / 2))


func exp*(z: Magnitude): Magnitude =
  ## Raise e to magnitude under antiproduct, i.e. e^y (C 𝟙 + S 𝟏) for z = x𝟏 + y𝟙.
  ##   Dual number: C = 1, S = x. Complex number: C = cos x, S = sin x.
  let
    (bulk, weight) = (z[Basis.scalar], z[Basis.scalarAnti])
    scale = exp(weight)
  when SQUARE_BULK == 0:
    initMagnitude(scale * bulk, scale)
  else:
    initMagnitude(scale * sin(bulk), scale * cos(bulk))



#[ Norms ]#

func normBulk*(m: Multivector): Magnitude =
  ## Get bulk norm as magnitude, i.e. ‖𝐦‖∙ = √(𝐦∙𝐦).
  ##   Float root, as at pin: under rigid metric 𝟏 squares to zero, so pure bulk has no root under
  ##     antiproduct.
  initMagnitude(sqrt((`|∙²`m)[Basis.scalar]), 0)


func normWeight*(m: Multivector): Magnitude =
  ## Get weight norm as root of magnitude under antiproduct, i.e. ‖𝐦‖∘ = √(𝐦∘𝐦), as at pin.
  sqrt(initMagnitude(0, (`|∘²`m)[Basis.scalarAnti]))


when IS_CONFORMAL:
  func normRadius*(m: Multivector): Magnitude =
    ## Get radius norm as root of magnitude under antiproduct, i.e. ‖𝐦‖⊘ = √(𝐦∘𝐦), book's (4.45).
    ##   Real for real object, imaginary, on 𝟏, for imaginary one. `pga.nim` stubs `|⊘` at pin.
    sqrt(initMagnitude(0, (m ∘ m)[Basis.scalarAnti]))


func norm*(m: Multivector): Magnitude =
  ## Get geometric norm, i.e. ‖𝐦‖ = ‖𝐦‖∙ + ‖𝐦‖∘.
  normBulk(m) + normWeight(m)


func unitize*(m: Multivector): Multivector =
  ## Unitize by division by weight norm, i.e. 𝐦̂ = 𝐦 ÷ ‖𝐦‖∘.
  m / normWeight(m)



#[ Laws ]#

proc sampleWeighted(): Magnitude =
  ## Draw magnitude with real root: weight in (0, 1] under rigid metric, any under conformal.
  result = sample(Magnitude)
  when SQUARE_BULK == 0: result[Basis.scalarAnti] = 1.0 - rand(1.0)


proc sampleWhole(): Multivector =
  ## Draw multivector with every coefficient uniform in [-1, 1].
  for basis in Basis: result[basis] = rand(-1.0..1.0)


proc series(z: Magnitude): Multivector =
  ## Sum power series of exponential under library's antiproduct, independent of closed form.
  var term = initElement(Basis.scalarAnti)
  for k in 1..TERMS_SERIES:
    result = result + term
    term = (term ⟇ z.toMultivector) * (1 / float(k))


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
  doAssert sizeof(Magnitude) == 2 * sizeof(float) and alignof(Magnitude) == 2 * sizeof(float),
    "magnitude holds two floats, unpadded"
  doAssert (one ⟇ one) =~ float(SQUARE_BULK) * one_anti,
    "table read agrees with library's antiproduct"
  doAssert SQUARE_BULK == (when IS_RIGID: 0 else: -1),
    "dual under rigid metric, complex under conformal"
  when IS_CONFORMAL:
    var nan_float = 0  # float root of 𝐦∘𝐦 that gives NaN, as `|∘` takes it at pin
  for _ in 1..SAMPLES:
    let
      (y, z) = (sample(Magnitude), sample(Magnitude))
      rooted = sampleWeighted()
      m = sampleWhole()
    doAssert (y ⟇ z) is Magnitude, "product of magnitudes is magnitude, by table"
    doAssert (z.toMultivector ⟇ one_anti) =~ z.toMultivector, "𝟙 is unit"
    doAssert (z.toMultivector ⟇ inverse(z).toMultivector) =~ one_anti, "z ⟇ z⁻¹ = 𝟙"
    doAssert ((y / z).toMultivector ⟇ z.toMultivector) =~ y.toMultivector, "(y / z) ⟇ z = y"
    doAssert (sqrt(rooted).toMultivector ⟇ sqrt(rooted).toMultivector) =~ rooted.toMultivector,
      "√z ⟇ √z = z"
    doAssert exp(z).toMultivector =~ series(z), "exp is its power series under antiproduct"
    doAssert exp(y + z).toMultivector =~ (exp(y).toMultivector ⟇ exp(z).toMultivector),
      "exp(y + z) = exp(y) ⟇ exp(z)"
    when IS_RIGID:
      let weight = normWeight(m)
      doAssert (weight.toMultivector ⟇ weight.toMultivector) =~ (m ∘ m), "‖𝐦‖∘ ⟇ ‖𝐦‖∘ = 𝐦∘𝐦"
      doAssert weight.toMultivector =~ |∘m, "weight norm equals library's"
      doAssert norm(m).toMultivector =~ |m, "geometric norm equals library's"
      let unitized = norm(m) / weight
      doAssert unitized.toMultivector =~
          initMagnitude((|∙m)[Basis.scalar] / (|∘m)[Basis.scalarAnti], 1).toMultivector,
        "magnitude unitizes to distance 𝟏 + 𝟙"
      doAssert unitize(m) =~ ^m, "unitize equals library's"
    else:
      let radius = normRadius(m)
      doAssert not radius[Basis.scalar].isNaN and not radius[Basis.scalarAnti].isNaN,
        "radius norm is never NaN"
      doAssert (radius.toMultivector ⟇ radius.toMultivector) =~ (m ∘ m), "‖𝐦‖⊘ ⟇ ‖𝐦‖⊘ = 𝐦∘𝐦"
      if sqrt((m ∘ m)[Basis.scalarAnti]).isNaN: inc nan_float
  when IS_CONFORMAL:
    holdRoundPoints()
    echo "magnitude: laws hold at ", DIMENSIONS, "D conformal; float root of 𝐦∘𝐦 NaN ", nan_float,
      " of ", SAMPLES, ", radius norm NaN 0"
  else:
    echo "magnitude: laws hold at ", DIMENSIONS, "D rigid"
  0


when isMainModule:
  quit main()
