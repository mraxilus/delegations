## Derive arithmetic dense multivector operation must spend, from axioms of algebra itself.
##   Third comparison point beside library and typed reference: library is what is written,
##   typed reference is what sparse hand-rolled linear algebra spends, and bound is floor of
##   dense representation. Bound answers one question the other two cannot: how much of gap
##   is representation, and how much is quality of what generator emits.
##
##   Blades are bitmasks over dimensions, and metric is derived here rather than read from
##   library (Article II.8): rigid algebra's last vector squares to zero, so its metric is
##   singular and blade carrying that vector has no image; conformal algebra pairs its last
##   two vectors off diagonal, so its metric is non-singular and every blade has image.
##
##   Cost: bound counts arithmetic that survives, and assumes no common subexpression is
##     shared between result slots. Geometric-algebra products share almost none, so bound
##     is tight for products; where factoring would help, true floor sits below bound.
##   Cost: bound is derived, never measured, and record says so (Article VIII.1). What it
##     bounds is arithmetic and movement, never time.

{.experimental: "strictFuncs".}


type
  Blade* = uint32
    ## Define basis blade as bitmask, i.e. bit `i` set where basis vector `i` is factor.
  Metric* = object
    ## Define which algebra bound is derived for.
    dimensions*: int
      ## Count of basis vectors.
    is_conformal*: bool
      ## Conformal algebra pairs last two vectors; rigid algebra degenerates last one.
  Shape* {.pure.} = enum
    ## Define arithmetic shape of one operation, i.e. which rule derives its bound.
    Unknown
      ## No rule derived yet; bound is absent rather than wrong.
    Wedge
      ## Exterior product over dense operands, i.e. terms whose factors are disjoint.
    Geometric
      ## Geometric product over dense operands, i.e. terms whose shared factors have image.
    ScalarForm
      ## Bilinear form landing in one slot, e.g. inner product.
    SquaredNorm
      ## Bilinear form of operand with itself, landing in one slot.
    Norm
      ## Squared norm and one root.
    Componentwise
      ## Slot-by-slot sum or difference.
    Permutation
      ## Sign and reorder only, i.e. no multiply and no add.
    Scale
      ## Every slot times one scalar.
    Unitize
      ## Norm, one reciprocal, every slot scaled by it.
    Attitude
      ## Product against constant carrying one unit component, i.e. signed reads.
    ContractBulk
      ## Antiwedge against bulk dual of second operand.
    ContractWeight
      ## Antiwedge against weight dual of second operand.
    ExpandBulk
      ## Wedge against bulk dual of second operand.
    ExpandWeight
      ## Wedge against weight dual of second operand.
  Bound* = object
    ## Define arithmetic and movement floor of one operation over dense multivectors.
    is_derived*: bool
      ## False where shape carries no rule yet; every count below is then meaningless.
    multiplies*, adds*, divides*, roots*: int
      ## Arithmetic that survives.
    bytes_read*, bytes_written*: int
      ## Operands read once, result written once; no fill, no copy, no intermediate.


func slots*(m: Metric): int =
  ## Count components dense multivector carries, i.e. 2 raised to dimensions.
  1 shl m.dimensions


func sizeOfMultivector*(m: Metric): int =
  ## Read bytes dense multivector occupies, at eight bytes for each component.
  8 * m.slots


func isNull*(m: Metric; index: int): bool =
  ## Read whether basis vector squares to zero and carries no metric image.
  ##   Rigid algebra degenerates its last vector. Conformal algebra pairs its last two off
  ##   diagonal, so neither is singular and metric stays invertible.
  not m.is_conformal and index == m.dimensions - 1


func hasImage*(m: Metric; b: Blade): bool =
  ## Read whether blade survives metric, i.e. whether every factor carries image.
  for i in 0 ..< m.dimensions:
    if ((b shr i) and 1) == 1 and m.isNull(i): return false
  true


func wedgeTerms*(m: Metric): int =
  ## Count terms exterior product spends, i.e. ordered pairs of blades sharing no factor.
  ##   Each dimension stands in one of three states for pair: in neither, in first, in
  ##   second. So count is three raised to dimensions, and metric never enters.
  result = 1
  for _ in 0 ..< m.dimensions: result *= 3


func geometricTerms*(m: Metric): int =
  ## Count terms geometric product spends, i.e. pairs whose shared factors carry image.
  ##   Dimension carrying image stands in four states for pair; null dimension loses state
  ##   where both operands carry it, leaving three.
  result = 1
  for i in 0 ..< m.dimensions:
    result *= (if m.isNull(i): 3 else: 4)


func scalarFormTerms*(m: Metric): int =
  ## Count terms bilinear form landing in one slot spends, i.e. blades carrying image.
  for b in 0 ..< m.slots:
    if m.hasImage(Blade(b)): inc result


func popcount(b: Blade): int =
  ## Count factors blade carries.
  var v = b
  while v != 0:
    result += int(v and 1)
    v = v shr 1


func dualProductTerms*(m: Metric; as_weight, as_expand: bool): int =
  ## Count terms product against dual of second operand spends, in rigid algebra only.
  ##   Bulk dual drops blade carrying null vector, and weight dual keeps only that blade.
  ##   Antiwedge with dual of `n` needs first operand to contain `n`, which two raised to
  ##   dimensions less grade of `n` counts; wedge needs it contained in `n` instead, which
  ##   two raised to grade of `n` counts.
  for raw in 0 ..< m.slots:
    let n = Blade(raw)
    let carries_null = not m.hasImage(n)
    if carries_null != as_weight: continue
    let grade = n.popcount
    result += 1 shl (if as_expand: grade else: m.dimensions - grade)


func boundOf*(shape: Shape; m: Metric; arity: range[1 .. 2]): Bound =
  ## Derive floor of one operation from its shape and algebra.
  ##   Movement is operands read once and result written once, since dense operation needs
  ##   no fill, no copy and no intermediate to be correct.
  let size = m.sizeOfMultivector
  result.bytes_read = size * arity
  result.bytes_written = size
  result.is_derived = shape != Shape.Unknown

  case shape
  of Shape.Unknown:
    # No rule, so movement is absent too rather than stated without ground.
    result.bytes_read = 0
    result.bytes_written = 0
  of Shape.Wedge:
    result.multiplies = m.wedgeTerms
    result.adds = m.wedgeTerms - m.slots
  of Shape.Geometric:
    result.multiplies = m.geometricTerms
    result.adds = m.geometricTerms - m.slots
  of Shape.ScalarForm, Shape.SquaredNorm:
    result.multiplies = m.scalarFormTerms
    result.adds = m.scalarFormTerms - 1
    result.bytes_written = 8
  of Shape.Norm:
    result.multiplies = m.scalarFormTerms
    result.adds = m.scalarFormTerms - 1
    result.roots = 1
    result.bytes_written = 8
  of Shape.Componentwise:
    result.adds = m.slots
  of Shape.Permutation:
    discard
  of Shape.Scale:
    result.multiplies = m.slots
    result.bytes_read = size + 8
  of Shape.Unitize:
    # Norm of operand, one reciprocal, then every slot times that reciprocal.
    result.multiplies = m.scalarFormTerms + m.slots
    result.adds = m.scalarFormTerms - 1
    result.roots = 1
    result.divides = 1
  of Shape.Attitude:
    # Constant carries one unit component, so every surviving term is signed read.
    discard
  of Shape.ContractBulk, Shape.ContractWeight, Shape.ExpandBulk, Shape.ExpandWeight:
    # Bulk and weight split on degenerate vector, which only rigid metric carries. Conformal
    #   metric is non-singular, so this rule says nothing there and floor stays absent.
    if m.is_conformal:
      result = Bound()
    else:
      let as_weight = shape in {Shape.ContractWeight, Shape.ExpandWeight}
      let as_expand = shape in {Shape.ExpandBulk, Shape.ExpandWeight}
      result.multiplies = m.dualProductTerms(as_weight, as_expand)
      result.adds = max(0, result.multiplies - m.slots)


func bytesMoved*(b: Bound): int =
  ## Read bytes floor moves, i.e. operands read plus result written.
  b.bytes_read + b.bytes_written
