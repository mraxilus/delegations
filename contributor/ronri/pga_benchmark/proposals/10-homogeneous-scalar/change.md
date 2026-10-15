# Homogeneous scalar, with its norms

A new module, `pga/scalars.nim`, holds the homogeneous scalar x𝟏 + y𝟙 and its arithmetic under each
product. Under the rigid metric, the bulk norm, the weight norm and the geometric norm return it.
Under the conformal metric, the radius norm returns it.

## Add `pga/scalars.nim`

```nim
## Define homogeneous scalar x𝟏 + y𝟙, with inverse, root and exponential under each product.
##   Homogeneous scalar is basis-set type of 𝟏 and 𝟙: value x/y, kept with its weight y, as
##     homogeneous point keeps position with its weight.
##   𝟏 is unit of geometric product, and 𝟙 of antiproduct, as Lengyel's `DualNum` has `Sqrt` and
##     `AntiSqrt`. Square of other part under each, read from library's table, picks arithmetic:
##       0 under rigid metric, so pair is dual number;
##       -1 at cga4d and cga5d, so pair is complex number;
##       +1 at cga3d and cga6d, so pair is split-complex number.
##   Inverse, root and exponential under geometric product follow from that square alone, and
##     each anti form is their complement. Division is under antiproduct, as Lengyel's is.
##
##   Cost: split-complex pair has no root where bulk is below size of weight, so radius norm of
##     imaginary object stays NaN at cga3d and cga6d.
##   Cost: division of multivector is whole antiproduct of library.

{.experimental: "strictFuncs".}

import std/[math, strformat]

import ./[algebra, basis_sets, cayleys, multivectors, operators]


type ScalarHomogeneous* = MultivectorOf[{Basis.scalar, Basis.scalarAnti}]
  ## Define pair x𝟏 + y𝟙: bulk x on scalar, weight y on antiscalar.


func square(cayley: Cayley2D; part, unit: Basis): int {.compileTime.} =
  ## Read coefficient of unit in part times part from library's table of product.
  for term in cayley[part][part]:
    doAssert term.basis == unit, &"Square of part must land on unit alone; got `{term.basis}`."
    result += (if term.is_negated: -1 else: 1)


const
  SQUARE_BULK* = square(CAYLEYS_WEDGE_DOT.anti, Basis.scalar, Basis.scalarAnti)
    ## Square of 𝟏 under antiproduct, as multiple of 𝟙: 0 rigid, -1 at cga4d and cga5d, else +1.
  SQUARE_WEIGHT* = square(CAYLEYS_WEDGE_DOT.base, Basis.scalarAnti, Basis.scalar)
    ## Square of 𝟙 under geometric product, as multiple of 𝟏.

# Validate square of each unit part, which picks arithmetic of pair.
#   Sign is determinant of metric times sign of reverse of all vectors, so each algebra takes one.
static:
  doAssert SQUARE_BULK in [-1, 0, 1],
    &"Square of 𝟏 under antiproduct must be -1, 0 or 1; got `{SQUARE_BULK}`."
  doAssert SQUARE_WEIGHT == SQUARE_BULK,
    &"Complement must carry geometric product to antiproduct; got `{SQUARE_WEIGHT=}`."



#[ Arithmetic ]#

func initScalarHomogeneous*(bulk, weight: float): ScalarHomogeneous {.noinit.} =
  ## Make homogeneous scalar bulk 𝟏 + weight 𝟙.
  result[Basis.scalar] = bulk
  result[Basis.scalarAnti] = weight


func `+`*(y, z: ScalarHomogeneous): ScalarHomogeneous =
  ## Add homogeneous scalars, part by part.
  initScalarHomogeneous(
    y[Basis.scalar] + z[Basis.scalar],
    y[Basis.scalarAnti] + z[Basis.scalarAnti],
  )


func complement(z: ScalarHomogeneous): ScalarHomogeneous =
  ## Get complement of homogeneous scalar, i.e. z̅: swap parts, as 𝟏̅ = 𝟙 and 𝟙̅ = 𝟏.
  initScalarHomogeneous(z[Basis.scalarAnti], z[Basis.scalar])


func inverse*(z: ScalarHomogeneous): ScalarHomogeneous =
  ## Get inverse under geometric product, i.e. z⁻¹ with z ⟑ z⁻¹ = 𝟏: conjugate over its square size.
  ##   None where square size is zero; there result is infinite or NaN, as float division gives.
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
```

## Edit `pga.nim`

```nim
import ./pga/[algebra, basis_sets, cayleys, multivectors, operators]
export algebra, basis_sets, cayleys, multivectors, operators
```

```nim
import ./pga/[algebra, basis_sets, cayleys, multivectors, operators, scalars]
export algebra, basis_sets, cayleys, multivectors, operators, scalars
```

## Edit `pga.nim`

```nim
func norm*(m: Multivector): Multivector {.inline.} = |m
  ## Get geometric norm of multivector as distance from origin.

func normalizeBulk*
```

```nim
func normalizeBulk*
```

## Edit `pga.nim`

```nim
when IS_RIGID:
  func normBulk*(m: Multivector): Multivector {.inline.} = |∙m
    ## Get bulk norm of multivector as size of bulk components.

  func normWeight*(m: Multivector): Multivector {.inline.} = |∘m
    ## Get weight norm of multivector as size of weight components.
    ##   Interpreted as collective magnitude of components that extend in direction of eₙ.
```

```nim
when IS_RIGID:
  func normBulk*(m: Multivector): ScalarHomogeneous {.inline.} =
    ## Get bulk norm of multivector as root under geometric product, i.e. ‖𝐦‖∙ = √(𝐦∙𝐦).
    ##   Size of bulk components, as `|∙` gives it, on 𝟏 of homogeneous scalar.
    sqrt(initScalarHomogeneous((m ∙ m)[Basis.scalar], 0))

  func normWeight*(m: Multivector): ScalarHomogeneous {.inline.} =
    ## Get weight norm of multivector as root under antiproduct, i.e. ‖𝐦‖∘ = √(𝐦∘𝐦).
    ##   Interpreted as collective magnitude of components that extend in direction of eₙ.
    ##   Size of weight components, as `|∘` gives it, on 𝟙 of homogeneous scalar.
    sqrtAnti(initScalarHomogeneous(0, (m ∘ m)[Basis.scalarAnti]))

  func norm*(m: Multivector): ScalarHomogeneous {.inline.} = normBulk(m) + normWeight(m)
    ## Get geometric norm of multivector as distance from origin, i.e. ‖𝐦‖ = ‖𝐦‖∙ + ‖𝐦‖∘.
    ##   Distance kept with its weight: divide by weight norm to read d𝟏 + 𝟙.
```

## Edit `pga.nim`

```nim
when IS_CONFORMAL:
  func normBulkRound*
```

```nim
when IS_CONFORMAL:
  func norm*(m: Multivector): Multivector {.inline.} = |m
    ## Get geometric norm of multivector as distance from origin.

  func normBulkRound*
```

## Edit `pga.nim`

```nim
  func normRadius*(m: Multivector): Multivector {.inline.} = |⊘m
    ## Get radius norm of multivector.
```

```nim
  func normRadius*(m: Multivector): ScalarHomogeneous {.inline.} =
    ## Get radius norm of multivector as root under antiproduct, i.e. ‖𝐦‖⊘ = √(𝐦∘𝐦), book's (4.45).
    ##   Real for real object, on 𝟙. Imaginary object has root on 𝟏, as i, at cga4d and cga5d;
    ##     split-complex pair of cga3d and cga6d has none, so NaN stays there, as `|⊘` gives.
    sqrtAnti(initScalarHomogeneous(0, (m ∘ m)[Basis.scalarAnti]))
```
