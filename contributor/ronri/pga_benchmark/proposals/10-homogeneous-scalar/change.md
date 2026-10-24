# Arithmetic of homogeneous scalars, and the radius norm as their root

At pin, each norm returns `MultivectorScalars`, the pair x𝟏 + y𝟙 of the scalar and the antiscalar,
and takes a float root of one coefficient. A new module, `pga/scalars.nim`, gives that pair the
functions of Lengyel's `DualNum` under each product. They are an inverse, a root, an inverse root,
an exponential, a sine, a cosine and a tangent, with a division. Each is written once in ε², the
square of 𝟙, and a function without a value for some pair returns an `Option`. Under the conformal
metric, the radius norm becomes the root of 𝐦 ∘ 𝐦 under the antiproduct. So at cga4d and cga5d an
imaginary object has an imaginary radius, where pin gives NaN.

## Add `pga/scalars.nim`

```nim
## Define functions of homogeneous scalar x𝟏 + y𝟙 under each product, for any algebra.
##
## Map of names to Lengyel's `DualNum` (`TSDualNum.h`, Terathon Math Library) and notation:
##
##   |-----------------|-----------------|-----------------|
##   | Name            | Lengyel         | Notation        |
##   |-----------------|-----------------|-----------------|
##   | inverse         | Inverse         | z⁻¹             |
##   | sqrt            | Sqrt            | √z              |
##   | sqrtInverse     | InverseSqrt     | 1 / √z          |
##   | exp             | Exp             | eᶻ              |
##   | sin             | Sin             | sin z           |
##   | cos             | Cos             | cos z           |
##   | tan             | Tan             | tan z           |
##   | inverseAnti     | AntiInverse     | z⁻¹ under ⟇     |
##   | sqrtAnti        | AntiSqrt        | √z under ⟇      |
##   | sqrtInverseAnti | AntiInverseSqrt | 1 / √z under ⟇  |
##   | expAnti         | AntiExp         | eᶻ under ⟇      |
##   | sinAnti         | AntiSin         | sin z under ⟇   |
##   | cosAnti         | AntiCos         | cos z under ⟇   |
##   | tanAnti         | AntiTan         | tan z under ⟇   |
##   | /               | operator /      | y ⟇ z⁻¹         |
##   |-----------------|-----------------|-----------------|
##
## Square ε² of 𝟙, i.e. 𝟙 ⟑ 𝟙 = ε²𝟏, fixes arithmetic of pair:
##   0 under rigid metric, so pair is dual number, as Lengyel's `DualNum` is;
##   -1 at cga4d and cga5d, so pair is complex number;
##   +1 at cga3d and cga6d, so pair is split-complex number.
##   Symbol follows dual unit ε of `DualNum`, which writes pair s + tε with ε² = 0.
## ε² is read from library's table of geometric product, and static check holds it to metric 𝖌.
##   Check holds it equal to rev(n) det 𝖌, for any dimension and metric, so table that disagrees
##     with metric fails build.
##   𝟙 ⟑ 𝟙̃ = (𝟙 • 𝟙)𝟏, where 𝟙 • 𝟙 = det 𝖌 is entry of exomorphism 𝐆 on 𝟙.
##   Reverse gives 𝟙̃ = rev(n) 𝟙, with rev(n) = (-1)^(n(n - 1)/2), so 𝟙 ⟑ 𝟙 = rev(n) det 𝖌 𝟏.
##   Determinant takes off-diagonal null pair of conformal metric as it is, and degenerate metric
##     gives 0 whatever sign of reverse.
##   Check compares two paths from 𝐆: short one takes its entry on 𝟙 with sign of reverse, long one
##     runs through dual and transwedges to product table.
## Each function is written once in ε², as f on eigenvalues of pair.
##   Dual form reduces to Lengyel's, complex to principal complex function, split-complex to f on
##     each idempotent.
##   Cost: ε² outside -1..1 needs scaling by its root, which no metric of library gives.
## Each form under antiproduct is complement of its form under geometric product.
##   Complement swaps 𝟏 and 𝟙 and carries ⟑ to ⟇, as library derives each antiproduct.
##   Cost: two swaps for each call, unmeasured.
## Absence lives in return type, never NaN.
##   Inverse, inverse root, tangent and division are optional, as each lacks value somewhere.
##   Root is plain where every pair has root, as in complex algebra, else optional.
##   Cost: caller spanning algebras branches on `MultivectorScalarsRoot`.
## Root takes larger part by root and smaller by division, so neither cancels.
##   Cost: one branch on sign of bulk.
## Domain of root compares exactly, as no scale is in hand there.
##   Cost: 𝐦∘𝐦 of point on null cone rounds either side of zero, so caller compares at scale of 𝐦.

{.experimental: "strictFuncs".}

import std/[math, options, strformat]

import ./[algebra, cayleys, multivectors, operators]



#[ Type Definitions ]#

type MultivectorScalarsRoot*[S: static int] =
  (when S == -1: MultivectorScalars else: Option[MultivectorScalars])
  ## Define root under square `S` of non-unit part: plain where every pair has root, else optional.
  ##   Only complex pair, `S` = -1, has root of each pair.



#[ Square Of Antiscalar ]#

func coefficient(terms: seq[BasisSigned], target: Basis): int {.compileTime.} =
  ## Sum signed coefficients of target in entry of library's table.
  ##   Empty entry gives 0, as degenerate metric leaves exomorphism of 𝟙 empty.
  ##   Term landing on other basis fails build, since pair would not close under product.
  for term in terms:
    doAssert term.basis == target, &"Entry must land on `{target}` alone; got `{term.basis}`."
    result += (if term.is_negated: -1 else: 1)


const
  SQUARE_WEIGHT* =
      coefficient(CAYLEYS_WEDGE_DOT.base[Basis.scalarAnti][Basis.scalarAnti], Basis.scalar)
    ## Square ε² of 𝟙 under geometric product, read from library's table, i.e. 𝟙 ⟑ 𝟙 = ε²𝟏.
  SQUARE_BULK* =
      coefficient(CAYLEYS_WEDGE_DOT.anti[Basis.scalar][Basis.scalar], Basis.scalarAnti)
    ## Square ε² of 𝟏 under antiproduct, read from library's table, i.e. 𝟏 ⟇ 𝟏 = ε²𝟙.

# Validate squares read from product tables against metric, and block of 𝟏 and 𝟙 pair assumes.
#   Metrics of library give ε² in -1..1; outside, lift range by scaling by its root in
#     `cosSin` and in root of negative bulk.
static:
  doAssert SQUARE_WEIGHT in -1..1,
    &"Square of 𝟙 under ⟑ must be -1, 0 or 1; got `{SQUARE_WEIGHT}`."
  doAssert SQUARE_BULK == SQUARE_WEIGHT,
    &"Complement must carry ⟑ to ⟇, so squares agree; got `{SQUARE_BULK=}`."
  let squares_metric = [
    coefficient(CAYLEYS_REVERSE.base[Basis.scalarAnti], Basis.scalarAnti) *
        coefficient(CAYLEYS_EXOMORPHISM_METRIC.base[Basis.scalarAnti], Basis.scalarAnti),
    coefficient(CAYLEYS_REVERSE.anti[Basis.scalar], Basis.scalar) *
        coefficient(CAYLEYS_EXOMORPHISM_METRIC.anti[Basis.scalar], Basis.scalar),
  ]
  doAssert squares_metric == [SQUARE_WEIGHT, SQUARE_BULK],
    &"Squares of product tables must equal rev(n) det 𝖌; got `{squares_metric}`."
  let units = [
    coefficient(CAYLEYS_WEDGE_DOT.base[Basis.scalar][Basis.scalarAnti], Basis.scalarAnti),
    coefficient(CAYLEYS_WEDGE_DOT.base[Basis.scalarAnti][Basis.scalar], Basis.scalarAnti),
  ]
  doAssert units == [1, 1], &"𝟏 must be unit of ⟑ on each side of 𝟙; got `{units}`."



#[ Pair Arithmetic ]#

func initMultivectorScalars*(bulk, weight: Coefficient): MultivectorScalars {.noinit.} =
  ## Make homogeneous scalar bulk 𝟏 + weight 𝟙.
  result[Basis.scalar] = bulk
  result[Basis.scalarAnti] = weight


func complement(z: MultivectorScalars): MultivectorScalars =
  ## Get complement of homogeneous scalar, i.e. z̅: swap parts, as 𝟏̅ = 𝟙 and 𝟙̅ = 𝟏.
  ##   Not inline, so `Option.map` takes it as callback.
  initMultivectorScalars(z[Basis.scalarAnti], z[Basis.scalar])


func wedgeDot(y, z: MultivectorScalars): MultivectorScalars =
  ## Multiply homogeneous scalars through geometric product, i.e. y ⟑ z, as Lengyel's `WedgeDot`.
  ##   Reads block of table that static check holds: 𝟏 is unit, and 𝟙 ⟑ 𝟙 = ε²𝟏.
  ##   TODO: Take basis-set product once P04 emits it.
  let
    (y_bulk, y_weight) = (y[Basis.scalar], y[Basis.scalarAnti])
    (z_bulk, z_weight) = (z[Basis.scalar], z[Basis.scalarAnti])
  initMultivectorScalars(
    y_bulk * z_bulk + Coefficient(SQUARE_WEIGHT) * y_weight * z_weight,
    y_bulk * z_weight + y_weight * z_bulk,
  )


func wedgeDotAnti(y, z: MultivectorScalars): MultivectorScalars {.inline.} =
  ## Multiply homogeneous scalars through antiproduct, i.e. y ⟇ z, as complement of y̅ ⟑ z̅.
  complement(wedgeDot(complement(y), complement(z)))



#[ Inverse and Root ]#

func inverse*(z: MultivectorScalars): Option[MultivectorScalars] =
  ## Get inverse under geometric product, i.e. z⁻¹ = (x𝟏 − y𝟙) / (x² − ε²y²) for z = x𝟏 + y𝟙.
  ##   None where modulus x² − ε²y² is zero at scale of its two terms.
  ##     Zero pair has none in each algebra, as has pure 𝟙 when dual and x = ±y when split.
  let
    (bulk, weight) = (z[Basis.scalar], z[Basis.scalarAnti])
    modulus_squared = bulk * bulk - Coefficient(SQUARE_WEIGHT) * weight * weight
    scale = bulk * bulk + abs(Coefficient(SQUARE_WEIGHT)) * weight * weight
  if abs(modulus_squared) <= TOLERANCE_ABS * scale: return none(MultivectorScalars)
  some(initMultivectorScalars(bulk / modulus_squared, -weight / modulus_squared))


func sqrt*(z: MultivectorScalars): MultivectorScalarsRoot[SQUARE_WEIGHT] =
  ## Get principal root under geometric product, i.e. √z with √z ⟑ √z = z and bulk ≥ 0.
  ##   Solve b² + ε²a² = x and 2ab = y through modulus ρ = √(x² − ε²y²), as b² = (x + ρ) / 2.
  ##   Complex pair always has root; negative bulk roots onto 𝟙, as i.
  ##   Dual pair needs positive bulk or zero; split-complex pair needs bulk ≥ |weight|.
  let (bulk, weight) = (z[Basis.scalar], z[Basis.scalarAnti])

  # Refuse pair outside domain of real roots.
  when SQUARE_WEIGHT == 0:
    if bulk < 0 or (bulk == 0 and weight != 0): return none(MultivectorScalars)
  elif SQUARE_WEIGHT == 1:
    if bulk < abs(weight): return none(MultivectorScalars)

  # Take larger part by root and smaller by division, so neither cancels.
  let
    modulus =
      when SQUARE_WEIGHT == -1: hypot(bulk, weight)
      elif SQUARE_WEIGHT == 0: bulk
      else: math.sqrt((bulk - abs(weight)) * (bulk + abs(weight)))
    size = math.sqrt((abs(bulk) + modulus) / 2)
    root =
      if size == 0: initMultivectorScalars(0, 0)
      elif bulk >= 0: initMultivectorScalars(size, weight / (2 * size))
      else: initMultivectorScalars(abs(weight) / (2 * size), copySign(size, weight))
  when SQUARE_WEIGHT == -1: root else: some(root)


func sqrtInverse*(z: MultivectorScalars): Option[MultivectorScalars] =
  ## Get inverse root under geometric product, i.e. 1 / √z; none without root or its inverse.
  when SQUARE_WEIGHT == -1: inverse(sqrt(z)) else: sqrt(z).flatMap(inverse)



#[ Exponential Family ]#

func cosSin(angle: Coefficient, square: static int): tuple[cos, sin: Coefficient] =
  ## Get even and odd parts of e^(angle 𝐯) for 𝐯 ⟑ 𝐯 = square 𝟏, i.e. its 𝟏 part and its 𝐯 part.
  ##   Even part sums squareᵏ angle²ᵏ / (2k)!, and odd part sums squareᵏ angle²ᵏ⁺¹ / (2k + 1)!.
  ##   Square -1 gives cosine and sine, 0 gives 1 and angle, +1 gives their hyperbolic forms.
  ##   Named for Lengyel's `CosSin`, which returns both parts at once.
  when square == -1: (math.cos(angle), math.sin(angle))
  elif square == 0: (Coefficient(1), angle)
  else: (math.cosh(angle), math.sinh(angle))


func exp*(z: MultivectorScalars): MultivectorScalars =
  ## Raise e to homogeneous scalar under geometric product, i.e. eᶻ = eˣ (C(y) 𝟏 + S(y) 𝟙).
  ##   C and S are even and odd parts of e^(y𝟙), under ε².
  let
    (bulk, weight) = (z[Basis.scalar], z[Basis.scalarAnti])
    (scale, parts) = (math.exp(bulk), cosSin(weight, SQUARE_WEIGHT))
  initMultivectorScalars(scale * parts.cos, scale * parts.sin)


func sin*(z: MultivectorScalars): MultivectorScalars =
  ## Get sine under geometric product, i.e. sin z = sin x C(y) 𝟏 + cos x S(y) 𝟙.
  ##   C and S take -ε², as sine and cosine alternate signs of exponential series.
  let
    (bulk, weight) = (z[Basis.scalar], z[Basis.scalarAnti])
    parts = cosSin(weight, -SQUARE_WEIGHT)
  initMultivectorScalars(math.sin(bulk) * parts.cos, math.cos(bulk) * parts.sin)


func cos*(z: MultivectorScalars): MultivectorScalars =
  ## Get cosine under geometric product, i.e. cos z = cos x C(y) 𝟏 − sin x S(y) 𝟙.
  ##   C and S take -ε², as for sine.
  let
    (bulk, weight) = (z[Basis.scalar], z[Basis.scalarAnti])
    parts = cosSin(weight, -SQUARE_WEIGHT)
  initMultivectorScalars(math.cos(bulk) * parts.cos, -math.sin(bulk) * parts.sin)


func tan*(z: MultivectorScalars): Option[MultivectorScalars] =
  ## Get tangent under geometric product, i.e. tan z = sin z ⟑ (cos z)⁻¹.
  ##   None where cosine has no inverse, as at each pole.
  ##   Product rather than closed form over cos 2x, which cancels near pole.
  let cosine_inverse = inverse(cos(z))
  if cosine_inverse.isNone: return none(MultivectorScalars)
  some(wedgeDot(sin(z), cosine_inverse.get))



#[ Forms Under Antiproduct ]#

func inverseAnti*(z: MultivectorScalars): Option[MultivectorScalars] {.inline.} =
  ## Get inverse under antiproduct, i.e. z⁻¹ with z ⟇ z⁻¹ = 𝟙, as complement of z̅⁻¹.
  inverse(complement(z)).map(complement)

func sqrtAnti*(z: MultivectorScalars): MultivectorScalarsRoot[SQUARE_BULK] {.inline.} =
  ## Get principal root under antiproduct, i.e. w with w ⟇ w = z, as complement of √z̅.
  when SQUARE_BULK == -1: complement(sqrt(complement(z)))
  else: sqrt(complement(z)).map(complement)

func sqrtInverseAnti*(z: MultivectorScalars): Option[MultivectorScalars] {.inline.} =
  ## Get inverse root under antiproduct, as complement of inverse root of z̅.
  sqrtInverse(complement(z)).map(complement)

func expAnti*(z: MultivectorScalars): MultivectorScalars {.inline.} =
  ## Raise e to homogeneous scalar under antiproduct, as complement of exponential of z̅.
  complement(exp(complement(z)))

func sinAnti*(z: MultivectorScalars): MultivectorScalars {.inline.} =
  ## Get sine under antiproduct, as complement of sine of z̅.
  complement(sin(complement(z)))

func cosAnti*(z: MultivectorScalars): MultivectorScalars {.inline.} =
  ## Get cosine under antiproduct, as complement of cosine of z̅.
  complement(cos(complement(z)))

func tanAnti*(z: MultivectorScalars): Option[MultivectorScalars] {.inline.} =
  ## Get tangent under antiproduct, as complement of tangent of z̅.
  tan(complement(z)).map(complement)



#[ Division ]#

func `/`*(y, z: MultivectorScalars): Option[MultivectorScalars] =
  ## Divide under antiproduct, i.e. y ⟇ z⁻¹, as Lengyel's `DualNum` does.
  ##   None where z has no inverse under antiproduct.
  let inverse_anti = inverseAnti(z)
  if inverse_anti.isNone: return none(MultivectorScalars)
  some(wedgeDotAnti(y, inverse_anti.get))


func `/`*(m: Multivector, z: MultivectorScalars): Option[Multivector] =
  ## Divide multivector by homogeneous scalar under antiproduct, i.e. 𝐦 ⟇ z⁻¹.
  ##   Cost: whole antiproduct of library, as no basis-set product exists at pin.
  let inverse_anti = inverseAnti(z)
  if inverse_anti.isNone: return none(Multivector)
  some(m ⟇ inverse_anti.get.toMultivector)
```

## Edit `pga.nim`

```nim
import ./pga/[algebra, cayleys, multivectors, operators]
export algebra, cayleys, multivectors, operators
```

```nim
import ./pga/[algebra, cayleys, multivectors, operators, scalars]
export algebra, cayleys, multivectors, operators, scalars
```

## Edit `pga.nim`

```nim
  func normRadius*(m: Multivector): MultivectorScalars {.inline.} = |⊘m
    ## Get radius norm of multivector.
```

```nim
  func normRadius*(m: Multivector): MultivectorScalarsRoot[SQUARE_BULK] {.inline.} =
    ## Get radius norm of multivector as root under antiproduct, i.e. ‖𝐦‖⊘ = √(𝐦∘𝐦), book's (4.45).
    ##   Real for real object, on 𝟙. Imaginary object has root on 𝟏, as i, at cga4d and cga5d;
    ##     split-complex pair of cga3d and cga6d has none, so radius norm is optional there.
    sqrtAnti(initMultivectorScalars(0, (m ∘ m)[Basis.scalarAnti]))
```
