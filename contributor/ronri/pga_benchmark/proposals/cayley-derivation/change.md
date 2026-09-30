# Cayley derivation as edits at pin

Operators read the derived tables by their new names, and the suites hold the transwedge
identity that the build no longer uses. `cayleys.nim` is replaced whole, since most of it
changes.

## Edit `pga/operators.nim`

```nim
  # Determine mappings needed for each basis blade's coefficient assignment.
  var mappings: array[Basis, Option[NimNode]]
  for b in Basis:
    if filter_operand.len != 0 and b.grade notin filter_operand: continue
    if cayley[b].isNone: continue

    let destination = cayley[b].get
    if filter_product.len != 0 and destination.basis.grade notin filter_product: continue

    let mapping = nnkBracketExpr.newTree(ident"m", ident($b))
    doAssert mappings[destination.basis].isNone,
      &"Attempt to write twice to 1D basis mapping; got `{mapping}` for `{destination}`" &
      &"when `{mappings[destination.basis].get}` already present."
    mappings[destination.basis] = (
      if destination.is_negated: some(prefix(mapping, "-")) else: some(mapping)
    )
```

```nim
  # Determine reads needed for each basis blade's coefficient assignment.
  var expressions: array[Basis, seq[NimNode]]
  for b in Basis:
    if filter_operand.len != 0 and b.grade notin filter_operand: continue

    for destination in cayley[b]:
      if filter_product.len != 0 and destination.basis.grade notin filter_product: continue

      let read = nnkBracketExpr.newTree(ident"m", ident($b))
      expressions[destination.basis].add(
        if destination.is_negated: prefix(read, "-") else: read
      )
```

## Edit `pga/operators.nim`

```nim
    if filter_product.len != 0 and b.grade notin filter_product: continue
    let mapping =
      if (filter_product.len == 0 or b.grade in filter_product) and mappings[b].isSome:
        mappings[b]
      else:
        some(newFloatLitNode(0.0))

    # let mapping = mappings[b]
    # if mapping.isNone: continue
    assignments.add(
      newAssignment(nnkBracketExpr.newTree(ident"result", ident($b)), mapping.get)
```

```nim
    let terms =
      if (filter_product.len == 0 or b.grade in filter_product) and expressions[b].len != 0:
        expressions[b]
      else:
        @[newFloatLitNode(0.0)]

    var expression = terms[0]
    for term in terms[1 .. ^1]:
      expression = infix(expression, "+", term)

    assignments.add(
      newAssignment(nnkBracketExpr.newTree(ident"result", ident($b)), expression)
```

## Edit `pga/operators.nim`

```nim
  cayley = CAYLEYS_DUAL.base.right,
```

```nim
  cayley = CAYLEYS_DUAL.base,
```

## Edit `pga/operators.nim`

```nim
  cayley = CAYLEYS_DUAL.anti.right,
```

```nim
  cayley = CAYLEYS_DUAL.anti,
```

## Edit `pga/operators.nim`

```nim
  cayley = CAYLEYS_NORM_SQUARED.base,
```

```nim
  cayley = CAYLEYS_DOT.base,
```

## Edit `pga/operators.nim`

```nim
  cayley = CAYLEYS_NORM_SQUARED.anti,
```

```nim
  cayley = CAYLEYS_DOT.anti,
```

## Edit `pga/operators.nim`

```nim
  cayley = CAYLEYS_WEDGE_DOT.base.right,
```

```nim
  cayley = CAYLEYS_WEDGE_DOT.base,
```

## Edit `pga/operators.nim`

```nim
  cayley = CAYLEYS_WEDGE_DOT.anti.right,
```

```nim
  cayley = CAYLEYS_WEDGE_DOT.anti,
```

## Edit `pga/operators.nim`

```nim
  docs = "Multiply multivectors through right inner product bulk expansion, i.e. 𝐦 ∧ 𝐧★.",
  cayley = CAYLEY_EXPAND_BULK_RIGHT,
```

```nim
  docs = "Multiply multivectors through right interior product bulk expansion, i.e. 𝐦 ∧ 𝐧★.",
  cayley = CAYLEYS_EXPAND.bulk,
```

## Edit `pga/operators.nim`

```nim
  docs = "Multiply multivectors through right interior product expansion, i.e. 𝐦 ∧ 𝐧☆.",
  cayley = CAYLEYS_EXPAND.right,
```

```nim
  docs = "Multiply multivectors through right interior product weight expansion, i.e. 𝐦 ∧ 𝐧☆.",
  cayley = CAYLEYS_EXPAND.weight,
```

## Edit `pga/operators.nim`

```nim
  docs = "Multiply multivectors through right interior product contraction, i.e. 𝐦 ∨ 𝐧★.",
  cayley = CAYLEYS_CONTRACT.right,
```

```nim
  docs = "Multiply multivectors through right interior product bulk contraction, i.e. 𝐦 ∨ 𝐧★.",
  cayley = CAYLEYS_CONTRACT.bulk,
```

## Edit `pga/operators.nim`

```nim
  docs = "Multiply multivectors through right inner product weight contraction, i.e. 𝐦 ∨ 𝐧☆.",
  cayley = CAYLEY_CONTRACT_WEIGHT_RIGHT,
```

```nim
  docs = "Multiply multivectors through right interior product weight contraction, i.e. 𝐦 ∨ 𝐧☆.",
  cayley = CAYLEYS_CONTRACT.weight,
```

## Edit `pga/operators.nim`

```nim
#     right: CAYLEY_EXPAND_WEIGHT_RIGHT,
```

```nim
#     right: CAYLEYS_EXPAND.weight,
```

## Edit `pga/operators.nim`

```nim
#     right: CAYLEY_CONTRACT_WEIGHT_RIGHT,
```

```nim
#     right: CAYLEYS_CONTRACT.weight,
```

## Edit `pga/operators.nim`

```nim
#     right: CAYLEY_CONTRACT_BULK_RIGHT,
```

```nim
#     right: CAYLEYS_CONTRACT.bulk,
```

## Edit `pga/operators.nim`

```nim
#     right: CAYLEY_EXPAND_BULK_RIGHT,
```

```nim
#     right: CAYLEYS_EXPAND.bulk,
```

## Edit `pga/operators.nim`

```nim
  func `∩`*(m: Multivector): Multivector =
    ## Get right support of multivector, i.e. 𝐦∩ = 𝐦 ∨ (𝐞ₙ ∧ 𝐦☆).
    const 𝐞ₙ = initElement(Basis.origin)
    m ∨ (𝐞ₙ ∧ ☆ m)

  func `∪`*(m: Multivector): Multivector =
    ## Get right antisupport of multivector, i.e. 𝐦∪ = 𝐦 ∧ (𝐞̄ₙ ∨ 𝐦★).
    let 𝐞̄ₙ = block:
      let h = Basis.horizon
      h.basis.initElement(if h.is_negated: -1 else: 1)
    m ∧ (𝐞̄ₙ ∨ ★ m)

when IS_CONFORMAL:
  func `⊞`*(m: Multivector): Multivector =
    ## Get cocarrier of multivector, i.e. 𝐦☆ ∧ 𝐞ₙ.
    const 𝐞ₙ = Basis.infinity.initElement()
    ☆(m) ∧ 𝐞ₙ

  func `⊙`*(m: Multivector): Multivector = ⊞ m ∨ m
    ## Get center of multivector, i.e. 𝐦⊞ ∨ 𝐦.

  func `⊡`*(m: Multivector): Multivector = m ∧ ☆( ⊟ m)
    ## Get container of multivector, i.e. 𝐦 ∧ (𝐦⊟)☆.

```

```nim
  defineOperator(
    symbols = "∩",
    docs = "Get right support of multivector, i.e. 𝐦∩ = 𝐦 ∨ (𝐞ₙ ∧ 𝐦☆).",
    cayley = CAYLEY_SUPPORT,
    as_unary = true,
  )
  defineOperator(
    symbols = "∪",
    docs = "Get right antisupport of multivector, i.e. 𝐦∪ = 𝐦 ∧ (𝐞̄ₙ ∨ 𝐦★).",
    cayley = CAYLEY_SUPPORT_ANTI,
    as_unary = true,
  )

when IS_CONFORMAL:
  defineOperator(
    symbols = "⊞",
    docs = "Get cocarrier of multivector, i.e. 𝐦☆ ∧ 𝐞ₙ.",
    cayley = CAYLEY_CARRIER_CO,
  )
  defineOperator(
    symbols = "⊙",
    docs = "Get center of multivector, i.e. 𝐦⊞ ∨ 𝐦.",
    cayley = CAYLEY_CENTER,
    as_unary = true,
  )
  defineOperator(
    symbols = "⊡",
    docs = "Get container of multivector, i.e. 𝐦 ∧ (𝐦⊟)☆.",
    cayley = CAYLEY_CONTAINER,
    as_unary = true,
  )

```

## Edit `tests/suites.nim`

```nim
import ../pga/[algebra {.all.}, multivectors {.all.}, operators {.all.}]
```

```nim
import ../pga/[algebra {.all.}, cayleys {.all.}, multivectors {.all.}, operators {.all.}]
```

## Edit `tests/suites.nim`

```nim
  test "TODO: Add chapter 5 tests":
    skip()
```

```nim
  test "TODO: Add chapter 5 tests":
    skip()


suite "Transwedge":
  test "Order 0 is wedge, order gr(𝐚) is bulk contraction, equal grades give dot":
    const REDUCTIONS = block:
      var contract, dot: Cayley2D
      for k in Order:
        for a in Basis:
          if Order(a.grade) != k: continue
          for b in Basis:
            contract[b][a].add(CAYLEYS_WEDGES_TRANS[k][a][b])
            if a.grade == b.grade: dot[a][b].add(CAYLEYS_WEDGES_TRANS[k][a][b])
      (contract, dot)
    check CAYLEYS_WEDGES_TRANS[Order(0)] == CAYLEYS_WEDGE.base  # 𝐚 ⩃₀ 𝐛 = 𝐚 ∧ 𝐛
    check REDUCTIONS[0] == CAYLEYS_CONTRACT.bulk  # 𝐚 ⩃ₖ 𝐛 at k = gr(𝐚) is 𝐛 ∨ 𝐚★
    check REDUCTIONS[1] == CAYLEYS_DOT.base  # and at gr(𝐚) = gr(𝐛) is 𝐚 ∙ 𝐛

```

## Replace `pga/cayleys.nim` from `677be54bc12ef779`

```nim
## Define and construct Cayley tables for any PGA.
##
## Cayleys exposed to importer so they can inspect algebra's definition.
##   Three generators: metric 𝖌 on vectors, exterior product of bases, and complement.
##   Every other table derives through four rules:
##     `constructAnti` conjugates table by complements, giving every anti-variant
##       (antiwedge, 𝔾, ☆, antireverse, antidot, antiproduct).
##     `applyConstant` and `applyMap` fix or map one operand of product
##       (attitude, carrier, duals, interior products, compound products).
##     `filterGrades` keeps one grade of product (dot as scalar part of bulk contraction).
##     `constructProductsTransitional` sums wedge chains over one grade (geometric product).
##   Cost of `seq` cell in 1D as in 2D: heap at compile time only; buys one cell shape for
##     both orders, so sums of maps and constants of several terms need no second path.

{.experimental: "codeReordering".}
{.experimental: "strictFuncs".}

import std/[bitops, sequtils, strformat]

import ./[algebra {.all.}]



#[ Type Definitions ]#

type Order = distinct range[0..DIMENSIONS]
func `==`(a, b: Order): bool {.borrow.}
iterator items(t: typedesc[Order]): Order =
  for i in 0..DIMENSIONS: yield Order(i)


type ## Define type definitions dependent on `Basis` needed for macros.
  BasisSigned* = object ## Define signed representation of basis.
    basis*: Basis
    is_negated*: bool = false
  Cayley1D* = ## Define data structure for constructing unary algebra operations (map).
    array[Basis, seq[BasisSigned]] # Empty cell is absence; several terms sum.
  Cayley2D* = ## Define data structure for constructing binary algebra operations.
    array[Basis, array[Basis, seq[BasisSigned]]] # Support conformal operators with `seq`.
    # TODO: Avoid seq as heap allocated, perhaps array with count custom type.

type
  Chiral*[T] = object
    left*, right*: T
  Formal*[T] = object
    when IS_CONFORMAL:
      flat*, round*: T
    else:
      round*: T
  Partial*[T] = object
    bulk*, weight*: T
  Spatial*[T] = object
    base*, anti*: T



#[ Cayley Definitions ]#

const
  CAYLEYS_COMPLEMENT* = Chiral[Cayley1D](
    left: constructComplement(Chirality.Left),
    right: constructComplement(Chirality.Right),
  )
  CAYLEYS_REVERSE* = block: # Antireverse conjugates reverse by complements.
    let reverse = constructReverse()
    Spatial[Cayley1D](base: reverse, anti: reverse.constructAnti(CAYLEYS_COMPLEMENT))

const
  CAYLEY_METRIC* = constructMetric(DIMENSIONS, IS_CONFORMAL)
  CAYLEYS_METRIC_EXOMORPHISM* = block: # 𝔾 conjugates 𝐆 by complements, i.e. 𝔾𝐦 = (𝐆𝐦̲)̅.
    let metric_exomorphism = constructMetricExomorphism(CAYLEY_METRIC)
    Spatial[Cayley1D](
      base: metric_exomorphism,
      anti: metric_exomorphism.constructAnti(CAYLEYS_COMPLEMENT),
    )

const
  CAYLEYS_PARTS* = Partial[Formal[Cayley1D]]( # Weight conjugates bulk under rigid metric only.
    bulk: constructParts(as_weight = false),
    weight: constructParts(as_weight = true),
  )

const
  CAYLEYS_DUAL* = block: # Right complement after exomorphism, i.e. 𝐦★ = (𝐆𝐦)̅; ☆ conjugates ★.
    let dual = CAYLEYS_COMPLEMENT.right.applyMap(CAYLEYS_METRIC_EXOMORPHISM.base)
    Spatial[Cayley1D](base: dual, anti: dual.constructAnti(CAYLEYS_COMPLEMENT))

const
  CAYLEYS_WEDGE* = block: # Antiwedge conjugates wedge by complements, i.e. 𝐦 ∨ 𝐧 = (𝐦̲ ∧ 𝐧̲)̅.
    let wedge = constructProductExterior()
    Spatial[Cayley2D](base: wedge, anti: wedge.constructAnti(CAYLEYS_COMPLEMENT))
  CAYLEYS_WEDGES_TRANS* = constructProductsTransitional( # Σ𝐜 (𝐜̄ ∨ 𝐚) ∧ (𝐛 ∨ 𝐜★), one per order.
    CAYLEYS_COMPLEMENT.left, CAYLEYS_DUAL.base, CAYLEYS_WEDGE
  )
  CAYLEYS_WEDGE_DOT* = block: # Antiproduct conjugates geometric product by complements.
    let wedge_dot = constructProductGeometric(CAYLEYS_WEDGES_TRANS)
    Spatial[Cayley2D](base: wedge_dot, anti: wedge_dot.constructAnti(CAYLEYS_COMPLEMENT))

const
  # Interior products feed one dual into right operand of wedge or antiwedge.
  #   Transwedge of order gr(𝐚) reduces to 𝐛 ∨ 𝐚★ as well; suite holds it, build takes map.
  CAYLEYS_CONTRACT* = Partial[Cayley2D]( # 𝐦 ∨ 𝐧★ and 𝐦 ∨ 𝐧☆.
    bulk: CAYLEYS_WEDGE.anti.applyMap(CAYLEYS_DUAL.base, Chirality.Right),
    weight: CAYLEYS_WEDGE.anti.applyMap(CAYLEYS_DUAL.anti, Chirality.Right),
  )
  CAYLEYS_EXPAND* = Partial[Cayley2D]( # 𝐦 ∧ 𝐧★ and 𝐦 ∧ 𝐧☆.
    bulk: CAYLEYS_WEDGE.base.applyMap(CAYLEYS_DUAL.base, Chirality.Right),
    weight: CAYLEYS_WEDGE.base.applyMap(CAYLEYS_DUAL.anti, Chirality.Right),
  )
  CAYLEYS_DOT* = block: # Dot is scalar part of bulk contraction; antidot conjugates it.
    var dot = CAYLEYS_CONTRACT.bulk
    dot.filterGrades(products = @[Grade.low])
    Spatial[Cayley2D](base: dot, anti: dot.constructAnti(CAYLEYS_COMPLEMENT))
  CAYLEY_ATTITUDE*: Cayley1D = # 𝐦 ∨ 𝐞̄ₙ.
    CAYLEYS_WEDGE.anti.applyConstant(Basis.horizon, Chirality.Right)

when IS_CONFORMAL:
  const
    CAYLEY_CARRIER*: Cayley1D = # 𝐦 ∧ 𝐞ₙ.
      CAYLEYS_WEDGE.base.applyConstant(Basis.infinity.toSigned, Chirality.Right)
    CAYLEY_CARRIER_CO*: Cayley1D = # 𝐦☆ ∧ 𝐞ₙ, i.e. dual, then carrier.
      CAYLEY_CARRIER.applyMap(CAYLEYS_DUAL.anti)
    CAYLEY_CENTER*: Cayley2D = # 𝐦⊞ ∨ 𝐦, read with both operands 𝐦.
      CAYLEYS_WEDGE.anti.applyMap(CAYLEY_CARRIER_CO, Chirality.Left)
    CAYLEY_CONTAINER*: Cayley2D = # 𝐦 ∧ (𝐦⊟)☆, read with both operands 𝐦.
      CAYLEYS_WEDGE.base.applyMap(
        CAYLEYS_DUAL.anti.applyMap(CAYLEY_CARRIER),
        Chirality.Right,
      )

when IS_RIGID:
  const
    CAYLEY_SUPPORT*: Cayley2D = # 𝐦 ∨ (𝐞ₙ ∧ 𝐦☆), read with both operands 𝐦.
      CAYLEYS_WEDGE.anti.applyMap(
        CAYLEYS_WEDGE.base
          .applyConstant(Basis.origin.toSigned, Chirality.Left)
          .applyMap(CAYLEYS_DUAL.anti),
        Chirality.Right,
      )
    CAYLEY_SUPPORT_ANTI*: Cayley2D = # 𝐦 ∧ (𝐞̄ₙ ∨ 𝐦★), read with both operands 𝐦.
      CAYLEYS_WEDGE.base.applyMap(
        CAYLEYS_WEDGE.anti
          .applyConstant(Basis.horizon, Chirality.Left)
          .applyMap(CAYLEYS_DUAL.base),
        Chirality.Right,
      )



#[ Operation Construction ]#

func constructComplement(chirality: Chirality): Cayley1D {.compileTime.} =
  ## Construct Cayley table for left and right complements.
  for b in Basis:
    result[b] = @[b.complement(chirality)]


func constructReverse(): Cayley1D {.compileTime.} =
  ## Construct Cayley table for reverse; antireverse comes from `constructAnti`.
  for b in Basis:
    result[b] = @[b.reverse]


func constructMetric(dimensions: int; is_conformal: bool): Cayley1D {.compileTime.} =
  ## Construct metric 𝖌 simplified as 1D cayley table.
  let 𝐞ₙ = Basis(dimensions)
  for b in Basis:
    if b.grade <= Grade(1) and b != 𝐞ₙ:
      result[b] = @[b.toSigned]

  # Adjust metric to conformal structure if necessary.
  if is_conformal:
    result[𝐞ₙ] = @[BasisSigned(basis: 𝐞ₙ.pred, is_negated: true)]
    result[𝐞ₙ.pred] = @[BasisSigned(basis: 𝐞ₙ, is_negated: true)]


func constructMetricExomorphism(metric: Cayley1D): Cayley1D {.compileTime.} =
  ## Construct metric exomorphism 𝐆 from metric 𝖌 simplified as 1D cayley table.
  ##   𝖌 expands to 𝐆 via 𝐆(𝐦 ∧ 𝐧) = (𝐆𝐦) ∧ (𝐆𝐧)
  result = metric

  for b in Basis:
    if b.grade < Grade(2): continue
    var bases: seq[BasisSigned]
    var is_degenerate = false

    # Determine if any vector component of basis is degenerate.
    for d in b.toDigits:
      let basis = BasisDigits($d).toBasis
      if result[basis].len == 0:
        is_degenerate = true
        break
      bases.add(result[basis].single)
    if is_degenerate: continue

    # Reconstruct resulting signed basis from vector components.
    var product = multiplyExterior(bases[0], bases[1])
    assert not product.is_degenerate
    if len(bases) > 2:
      for i in 2 ..< len(bases):
        product = multiplyExterior(product.basis, bases[i])

    result[b] = @[product.basis]


func constructParts(as_weight: bool): Formal[Cayley1D] {.compileTime.} =
  ## Construct Cayley table for (round/flat) bulk/weight.
  ##   RGA can be derived from metric instead, however CGA requires explicit construction.
  ##   E.g. In RGA, equivalent to applying exomporphism as .

  func constructPart(inclusions, exclusions: seq[Basis]): Cayley1D {.compileTime.} =
    ## TODO: Document.
    var identity: Cayley1D
    for b in Basis:
      identity[b] = @[b.toSigned]
    identity.filterFactors(inclusions)
    identity.filterFactors(exclusions, as_exclusions = true)
    identity

  when IS_RIGID:
    let (inclusions, exclusions) =
      if not as_weight: (@[], @[Basis.origin])
      else: (@[Basis.origin], @[])
    Formal[Cayley1D](round: constructPart(inclusions, exclusions))
  else:
    let (inclusions, exclusions) =
      if not as_weight: (@[], @[Basis.origin])
      else: (@[Basis.origin], @[])
    Formal[Cayley1D](
      round: constructPart(inclusions, exclusions & @[Basis.infinity]),
      flat: constructPart(inclusions & @[Basis.infinity], exclusions),
    )


func constructProductExterior(): Cayley2D {.compileTime.} =
  ## Construct Cayley table for exterior/wedge product, from `multiplyExterior` alone.
  ##   Antiwedge comes from `constructAnti`, not from second path here.
  for a in Basis:
    for b in Basis:
      let product = multiplyExterior(a.toSigned, b.toSigned)
      if product.is_degenerate: continue
      result[a][b].add(product.basis)


func constructProductGeometric(wedges_trans: array[Order, Cayley2D]): Cayley2D {.compileTime.} =
  ## Construct Cayley table for geometric product, as signed sum over orders of transwedge.
  for order in Order:
    let
      k = int(order)
      is_negated = (k*(k-1) div 2 and 1) == 1
    result.merge(wedges_trans[order], as_negated = is_negated)


func constructProductsTransitional(
  complement, dual: Cayley1D; wedges: Spatial[Cayley2D]
): array[Order, Cayley2D] {.compileTime.} =
  ## Construct Cayley tables for each order of transitional product.
  ##   Order 0 is wedge, order gr(𝐚) is bulk contraction, and signed sum is geometric product.
  for order in Order:
    result[order] = constructProductTransitional(order, complement, dual, wedges)


func constructProductTransitional(
  order: Order; complement, dual: Cayley1D; wedges: Spatial[Cayley2D]
): Cayley2D {.compileTime.} =
  ## Construct Cayley table for one order of transitional product.
  ##   Sum over bases 𝐜 of one grade, i.e. Σ𝐜 (𝐜̄ ∨ 𝐚) ∧ (𝐛 ∨ 𝐜★).
  ##   Which operand meets 𝐜̄ and which meets 𝐜★ changes nothing, so no chirality here.
  for c in Basis:

    # Skip over bases of other orders, and bases without dual.
    if Order(c.grade) != order or dual[c].len == 0: continue
    let (c_complement, c_dual) = (complement[c].single, dual[c].single)

    for a in Basis:

      # Reduce left side antiproduct.
      let products_left = wedges.anti[c_complement.basis][a]
      if len(products_left) == 0: continue
      doAssert len(products_left) == 1

      for b in Basis:

        # Reduce right side antiproduct.
        let products_right = wedges.anti[b][c_dual.basis]
        if len(products_right) == 0: continue
        doAssert len(products_right) == 1

        # Reduce product between both sides.
        let
          (product_left, product_right) = (products_left[0], products_right[0])
          products_center = wedges.base[product_left.basis][product_right.basis]
        if len(products_center) == 0: continue
        doAssert len(products_center) == 1

        # Construct transitional product mappings.
        let
          product_center = products_center[0]
          is_negated = (
            c_dual.is_negated xor
            c_complement.is_negated xor
            product_left.is_negated xor
            product_center.is_negated xor
            product_right.is_negated
          )
        result[a][b].add(BasisSigned(basis: product_center.basis, is_negated: is_negated))



#[ Map Operations ]#

func applyConstant(
  cayley: Cayley2D; basis: BasisSigned; chirality: Chirality
): Cayley1D {.compileTime.} =
  ## Apply constant unit basis to left or right operand, collapsing 2D cayley into 1D map.
  ##   I.e. cayley(𝐞, 𝐦) for left and cayley(𝐦, 𝐞) for right, with sign of 𝐞 carried.
  result = cayley.slice(basis.basis, chirality)
  if basis.is_negated: result.negate()


func applyMap(cayley: Cayley1D; map: Cayley1D): Cayley1D {.compileTime.} =
  ## Apply map to operand of 1D cayley, i.e. cayley(map(𝐦)).
  ##   Map runs first, cayley second; several terms distribute and opposing terms cancel.
  for b in Basis:
    for b_map in map[b]:
      for b_to in cayley[b_map.basis]:
        result[b].mergeTerm(BasisSigned(
          basis: b_to.basis,
          is_negated: b_map.is_negated xor b_to.is_negated,
        ))


func applyMap(
  cayley: Cayley2D; map: Cayley1D; chirality: Chirality
): Cayley2D {.compileTime.} =
  ## Apply map to left or right operand of 2D cayley.
  ##   I.e. cayley(map(𝐦), 𝐧) for left and cayley(𝐦, map(𝐧)) for right.
  ##   Product with map in one operand emits as one table, so no intermediate multivector.
  for a in Basis:
    for b in Basis:
      let mapped = case chirality
        of Chirality.Left: map[a]
        of Chirality.Right: map[b]
      for b_map in mapped:
        let product = case chirality
          of Chirality.Left: cayley[b_map.basis][b]
          of Chirality.Right: cayley[a][b_map.basis]
        for term in product:
          result[a][b].mergeTerm(BasisSigned(
            basis: term.basis,
            is_negated: b_map.is_negated xor term.is_negated,
          ))


func constructAnti(map: Cayley1D; complements: Chiral[Cayley1D]): Cayley1D {.compileTime.} =
  ## Construct anti-variant of map by conjugating with complements, i.e. (map 𝐦̲)̅.
  ##   Right complement into operand, left complement out of product.
  for b in Basis:
    let b_from = complements.right[b].single
    for b_map in map[b_from.basis]:
      let b_to = complements.left[b_map.basis].single
      result[b].mergeTerm(BasisSigned(
        basis: b_to.basis,
        is_negated: b_from.is_negated xor b_map.is_negated xor b_to.is_negated,
      ))


func constructAnti(cayley: Cayley2D; complements: Chiral[Cayley1D]): Cayley2D {.compileTime.} =
  ## Construct anti-variant of product by conjugating with complements, i.e. (𝐦̲ ∘ 𝐧̲)̅.
  ##   Right complement into each operand, left complement out of product.
  for a in Basis:
    for b in Basis:
      let (a_from, b_from) = (complements.right[a].single, complements.right[b].single)
      for term in cayley[a_from.basis][b_from.basis]:
        let b_to = complements.left[term.basis].single
        result[a][b].mergeTerm(BasisSigned(
          basis: b_to.basis,
          is_negated: (
            a_from.is_negated xor b_from.is_negated xor term.is_negated xor b_to.is_negated
          ),
        ))



#[ Basis Transformations ]#

func complement(b: Basis; chirality: Chirality): BasisSigned {.compileTime.} =
  ## Get complement of basis (right by default).
  let
    mask = Basis.scalarAnti.toFlags
    antibasis = (not b.toFlags and mask).toBasis.toSigned
    antiscalar = (
      case chirality:
      of Chirality.Left: multiplyExterior(antibasis, b.toSigned)
      of Chirality.Right: multiplyExterior(b.toSigned, antibasis)
    )
  BasisSigned(basis: antibasis.basis, is_negated: antiscalar.basis.is_negated)


func reverse(b: Basis): BasisSigned {.compileTime.} =
  ## Get reverse of basis, i.e. sign (−1)^(g(g−1)/2) by grade g.
  let
    grade = int(b.grade)
    parity = ((int(grade * (grade - 1)) div 2) and 1) == 1
  BasisSigned(basis: b, is_negated: parity)


func multiplyExterior(
  a, b: BasisSigned
): tuple[basis: BasisSigned; is_degenerate: bool] {.compileTime.} =
  ## Perform exterior product of two bases, reducing to its standard basis form.
  ##   If duplicate 1-vectors are present, `is_degenerate` returns true.
  ##   Uses bit operations instead of inverting vectors anti-commutively, remaining equivalent.

  # Degenerate in presence of duplicate vectors.
  let (a_flags, b_flags) = (a.basis.toFlags, b.basis.toFlags)
  if countSetBits(a_flags) + countSetBits(b_flags) != countSetBits(a_flags xor b_flags):
    result.is_degenerate = true
    return

  # Determine parity in parts (equivalent to counting inversions and anti-commuting).
  #   If lexicographical ordering, this would simplify to parity of joining left and right inputs.
  #   Instead parity of two inputs and final output must be found relative to canonical ordering.
  #   I.e. must first map from canonical to lexicographical, compute parity, then map back.
  #   All due to using Lengyel's ordering, chosen for interop with standard linear algebra.
  let
    parity_a = isNegatedFromOrderLexicographic(a.basis) xor a.is_negated
    parity_b = isNegatedFromOrderLexicographic(b.basis) xor b.is_negated
    parity_order = isNegatedByJoinLexicographic(a_flags, b_flags)
    basis_product = toBasis(a_flags xor b_flags)
    parity_product = isNegatedFromOrderLexicographic(basis_product)
  result.basis = BasisSigned(
    basis: basis_product,
    is_negated: parity_a xor parity_b xor parity_order xor parity_product,
  )


func toSigned(b: Basis): BasisSigned {.compileTime.} = BasisSigned(basis: b)


func single(cell: seq[BasisSigned]): BasisSigned {.compileTime.} =
  ## Get sole term of cell of permutation map (complement, dual, metric).
  assert cell.len == 1, &"Attempt to read sole term of cell without exactly one; got `{cell}`."
  cell[0]



#[ Cell Operations ]#

func mergeTerm(cell: var seq[BasisSigned]; term: BasisSigned; as_negated = false) {.compileTime.} =
  ## Merge term into cell, cancelling opposing term when found, else adding term.
  ##   Cancels matching where `as_negated = true`.
  let
    is_negated = not term.is_negated xor as_negated
    term_cancel = BasisSigned(basis: term.basis, is_negated: is_negated)
    position = cell.find(term_cancel)
  if position != -1:
    cell.delete(position)
    return
  cell.add(BasisSigned(basis: term.basis, is_negated: term.is_negated xor as_negated))


func merge(destination: var Cayley2D; source: Cayley2D; as_negated = false) {.compileTime.} =
  ## Merge two 2D cayley tables in place, simplifying/cancelling opposing terms.
  for bm in Basis:
    for bn in Basis:
      for term in source[bm][bn]:
        destination[bm][bn].mergeTerm(term, as_negated)


func negate(cayley: var Cayley1D) {.compileTime.} =
  ## Negate all signed basis of 1D cayley table in place.
  for b in Basis:
    for term in cayley[b].mitems:
      term.is_negated = not term.is_negated


func slice(
  cayley: Cayley2D; operand: Basis; chirality: Chirality
): Cayley1D {.compileTime.} =
  ## Extract slice of 2D cayley at constant operand as 1D map.
  for b in Basis:
    result[b] = case chirality
      of Chirality.Left: cayley[operand][b]
      of Chirality.Right: cayley[b][operand]


func filterGrades(
  cayley: var Cayley2D;
  operands_m: seq[Grade] = default(seq[Grade]);
  operands_n: seq[Grade] = default(seq[Grade]);
  products: seq[Grade] = default(seq[Grade]);
  as_exclusions = false;
) {.compileTime.} =
  ## Filter out specific operands/products from 2D cayley table by grades.
  ##   Empty selection keeps all; `as_exclusions` inverts selection.
  for bm in Basis:
    for bn in Basis:
      if operands_m.len != 0 and (bm.grade in operands_m) == as_exclusions or
          operands_n.len != 0 and (bn.grade in operands_n) == as_exclusions:
        cayley[bm][bn] = @[]
        continue
      if products.len != 0:
        cayley[bm][bn].keepItIf((it.basis.grade in products) != as_exclusions)


func filterFactors(
  cayley: var Cayley1D; factors: seq[Basis]; as_exclusions = false
) {.compileTime.} =
  ## Filter out specific operands/products from 1D cayley table.
  for f in factors:
    assert countSetBits(f.toFlags) == 1,
      &"Attempt to filter with non-grade 1 basis factor: `{f=}`."

  for b in Basis:

    # Determine if basis contains filtered vector factor.
    let b_flags = b.toFlags
    var should_filter = false
    for f in factors:
      let flags_overlap = f.toFlags and b_flags
      if ((as_exclusions and int(flags_overlap) != 0) or
          (not as_exclusions and int(flags_overlap) == 0)):
        should_filter = true
        break
    if should_filter:
      cayley[b] = @[]


# func swap(cayley: var Cayley2D) {.compileTime.} =
#   ## Swap order of operands, TODO: negating result due to anticommutivity.
#   for bm in Basis:
#     for bn in Basis:
#       if bm == bn: continue
#       let (a, b) = (cayley[bm][bn], cayley[bn][bm])
#       cayley[bm][bn] = b
#       cayley[bn][bm] = a



#[ Basis Ordering ]#

func isNegatedFromOrderLexicographic(b: Basis): bool {.compileTime.} =
  ## Determine if canonically ordered basis is negated relative to lexicographical order.
  const lut_parity_by_basis = block:
    var lut: array[Basis, bool]
    for basis in Basis:
      let digits = basis.toDigits
      var inversions = 0
      for i in 0..<len(digits):
        for j in i + 1 ..< len(digits):
          if digits[i] > digits[j]:
            inversions += 1

      # Determine if parity (negation) bit set.
      lut[basis] = (inversions and 1) == 1
    lut

  lut_parity_by_basis[b]


func isNegatedByJoinLexicographic(a, b: BasisFlags): bool {.compileTime.} =
  ## Determine if joining two lexicographically ordered bases negates result.
  let a_flags = uint(a)
  var b_flags_remaining = uint(b)
  var swaps = 0

  # Count a flags greater than each b flag (i.e. requires swap).
  while b_flags_remaining != 0:
    let offset_b_flags_min = countTrailingZeroBits(b_flags_remaining)
    let count_flags_where_a_greater = countSetBits(a_flags shr (offset_b_flags_min + 1))
    swaps += count_flags_where_a_greater

    # Clear b flags already accounted for.
    b_flags_remaining = b_flags_remaining and (b_flags_remaining - 1)

  # Determine if parity (negation) bit remains set.
  (swaps and 1) == 1



#[ Basis Aliasing ]#

func horizon(t: typedesc[Basis]): BasisSigned {.compileTime.} =
  ## Alias basis representing horizon (i.e. 𝐞̄ₙ in RGA; 𝐞̄ₙ₋₁ in CGA).
  ##   TODO: Is 𝐞̄ₙ₋₁ horizion in conformal?
  Basis.origin.complement(Chirality.Right)
```
