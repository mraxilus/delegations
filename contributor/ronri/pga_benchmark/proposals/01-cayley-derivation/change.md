# Cayley derivation as edits at pin

Duals, interior products, dot, antireverse and attitude read rules that the library has, in
place of constructors of their own. Every exported table keeps its name, shape and cells. The
suites hold the transwedge identity that the dot no longer reads. `cayleys.nim` is replaced
whole, since its tables and constructors change together.

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
            contract[b][a].add(CAYLEYS_WEDGES_TRANS.base[k][a][b])
            if a.grade == b.grade: dot[a][b].add(CAYLEYS_WEDGES_TRANS.base[k][a][b])
      (contract, dot)
    check CAYLEYS_WEDGES_TRANS.base[Order(0)] == CAYLEYS_WEDGE.base  # 𝐚 ⩃₀ 𝐛 = 𝐚 ∧ 𝐛
    check REDUCTIONS[0] == CAYLEYS_INTERIOR.anti.bulk.right  # 𝐚 ⩃ₖ 𝐛 at k = gr(𝐚) is 𝐛 ∨ 𝐚★
    check REDUCTIONS[1] == CAYLEYS_DOT.base  # and at gr(𝐚) = gr(𝐛) is 𝐚 ∙ 𝐛

```

## Replace `pga/cayleys.nim` from `c7ad2e4fe4217e60`

```nim
## Define and construct Cayley tables for any PGA.
##
## Cayleys exposed to importer so they can inspect algebra's definition.
##   Three generators: metric 𝖌 on vectors, exterior product of bases, and complement.
##   Tables derive through four rules:
##     `constructAnti` conjugates table by complements, giving anti-variants
##       (antiwedge, 𝔾, antireverse, antidot).
##     `applyConstant` and `applyMap` fix or map one operand of product
##       (attitude, carrier, duals, interior products).
##     `filterGrades` keeps one grade of product (dot as scalar part of bulk contraction).
##     `constructProductsTransitional` sums wedge chains over one grade (geometric products).
##

{.experimental: "codeReordering".}
{.experimental: "strictFuncs".}

import std/[bitops, options, strformat]

import ./algebra {.all.}



#[ Type Definitions ]#

type  ## Define type definitions dependent on `Basis` needed for macros.
  BasisSigned* = object  ## Define signed representation of basis.
    basis*: Basis
    is_negated*: bool = false
  Cayley1D* =  ## Define data structure for constructing unary algebra operations (map).
    array[Basis, seq[BasisSigned]]
  Cayley2D* =  ## Define data structure for constructing binary algebra operations.
    array[Basis, array[Basis, seq[BasisSigned]]]  # Support conformal operators with `seq`.
    # TODO: Avoid seq as heap allocated, perhaps array with count custom type.
    #   Applies especially for 1D which only uses singular slot.

type  ## Define type definitions for algebraic distinctions.
  Chirality {.pure.} = enum Left, Right  ## Define distinction between PGA operation orientations.
  Partiality {.pure.} = enum Bulk, Weight  ## Define distinction between PGA's disjoint parts.
  Spatiality {.pure.} = enum Base, Anti  ## Define distinction between PGA's spacial duality.

type  ## Define type defintions for containers of algebraic distinctions.
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

## Define type definition for transwedge order.
type Order = distinct range[0..DIMENSIONS]
func `<=`(a, b: Order): bool {.borrow.}
func `==`(a, b: Order): bool {.borrow.}
iterator items(t: typedesc[Order]): Order =
  for i in 0..DIMENSIONS: yield Order(i)



#[ Cayley Definitions ]#

const
  CAYLEYS_COMPLEMENT* = Chiral[Cayley1D](
    left: constructComplement(Chirality.Left),
    right: constructComplement(Chirality.Right),
  )
  CAYLEYS_PARTS* = Partial[Formal[Cayley1D]](
    bulk: constructParts(Partiality.Bulk),
    weight: constructParts(Partiality.Weight),
  )
  CAYLEYS_REVERSE* = block:  # Antireverse conjugates reverse by complements.
    let base = constructReverse()
    Spatial[Cayley1D](
      base: base,
      anti: base.constructAnti(CAYLEYS_COMPLEMENT),
    )

const
  CAYLEY_METRIC* = constructMetric()
  CAYLEYS_METRIC_EXOMORPHISM* = block:
    let base = constructMetricExomorphism(CAYLEY_METRIC)
    Spatial[Cayley1D](
      base: base,
      anti: base.constructAnti(CAYLEYS_COMPLEMENT),
    )
  CAYLEYS_WEDGE* = block:
    let base = constructProductExterior(CAYLEYS_COMPLEMENT, Spatiality.Base)
    Spatial[Cayley2D](
      base: base,
      anti: base.constructAnti(CAYLEYS_COMPLEMENT),
    )

const
  CAYLEYS_DUAL* = Spatial[Chiral[Cayley1D]](  # Complement after exomorphism, e.g. 𝐦★ = (𝐆𝐦)̅.
    base: Chiral[Cayley1D](
      left: CAYLEYS_COMPLEMENT.left.applyMap(CAYLEYS_METRIC_EXOMORPHISM.base),
      right: CAYLEYS_COMPLEMENT.right.applyMap(CAYLEYS_METRIC_EXOMORPHISM.base),
    ),
    anti: Chiral[Cayley1D](
      left: CAYLEYS_COMPLEMENT.left.applyMap(CAYLEYS_METRIC_EXOMORPHISM.anti),
      right: CAYLEYS_COMPLEMENT.right.applyMap(CAYLEYS_METRIC_EXOMORPHISM.anti),
    ),
  )

const
  CAYLEYS_WEDGES_TRANS* = Spatial[array[Order, Cayley2D]](
      # TODO: Fully ignore chirality distinction as product outputs equivalent.
      base: constructProductsTransitional(
        CAYLEYS_COMPLEMENT.left,
        CAYLEYS_DUAL.base.right,
        CAYLEYS_WEDGE,
        Chirality.Right,
        Spatiality.Base,
      ),
      anti: constructProductsTransitional(
        CAYLEYS_COMPLEMENT.left,
        CAYLEYS_DUAL.anti.right,
        CAYLEYS_WEDGE,
        Chirality.Right,
        Spatiality.Anti,
      ),
    )


const
  CAYLEYS_INTERIOR* = Spatial[Partial[Chiral[Cayley2D]]](  # Wedge with one operand dualized.
    base: Partial[Chiral[Cayley2D]](  # Alias expansion.
      bulk: Chiral[Cayley2D](
        left: CAYLEYS_WEDGE.base.applyMap(CAYLEYS_DUAL.base.left, Chirality.Left),
        right: CAYLEYS_WEDGE.base.applyMap(CAYLEYS_DUAL.base.right, Chirality.Right),
      ),
      weight: Chiral[Cayley2D](
        left: CAYLEYS_WEDGE.base.applyMap(CAYLEYS_DUAL.anti.left, Chirality.Left),
        right: CAYLEYS_WEDGE.base.applyMap(CAYLEYS_DUAL.anti.right, Chirality.Right),
      ),
    ),
    anti: Partial[Chiral[Cayley2D]](  # Alias expansion.
      bulk: Chiral[Cayley2D](
        left: CAYLEYS_WEDGE.anti.applyMap(CAYLEYS_DUAL.base.left, Chirality.Left),
        right: CAYLEYS_WEDGE.anti.applyMap(CAYLEYS_DUAL.base.right, Chirality.Right),
      ),
      weight: Chiral[Cayley2D](
        left: CAYLEYS_WEDGE.anti.applyMap(CAYLEYS_DUAL.anti.left, Chirality.Left),
        right: CAYLEYS_WEDGE.anti.applyMap(CAYLEYS_DUAL.anti.right, Chirality.Right),
      ),
    ),
  )
  CAYLEYS_DOT* = block:  # Dot is scalar part of bulk contraction; antidot conjugates it.
    var base = CAYLEYS_INTERIOR.anti.bulk.right
    base.filterGrades(products = @[Grade.low])
    Spatial[Cayley2D](
      base: base,
      anti: base.constructAnti(CAYLEYS_COMPLEMENT),
    )


const
  CAYLEYS_WEDGE_DOT* = Spatial[Cayley2D](
    base: constructProductGeometric(CAYLEYS_WEDGES_TRANS.base),
    anti: constructProductGeometric(CAYLEYS_WEDGES_TRANS.anti),
  )

const
  CAYLEYS_NORM_SQUARED* = block:
    var cayleys = CAYLEYS_DOT
    cayleys.base.filterGrades(products = @[Grade.low])
    cayleys.anti.filterGrades(products = @[Grade.high])
    cayleys
  CAYLEY_ATTITUDE*: Cayley1D = block:  # 𝐦 ∨ 𝐞̄ₙ.
    var cayley = CAYLEYS_WEDGE.anti
    cayley.applyConstant(Basis.horizon, Chirality.Right)

when IS_CONFORMAL:
  const CAYLEY_CARRIER*: Cayley1D = block:
    var cayley = CAYLEYS_WEDGE.base
    cayley.applyConstant(Basis.infinity.toSigned, Chirality.Right)



#[ Operation Construction ]#

func constructComplement(chirality: Chirality): Cayley1D {.compileTime, noinit.} =
  ## Construct Cayley table for left and right complements.
  for b in Basis:
    result[b] = @[b.complement(chirality)]


func constructParts(partiality: Partiality): Formal[Cayley1D] {.compileTime, noinit.} =
  ## Construct Cayley table for (round/flat) bulk/weight.
  ##   We can derive RGA parts from metric instead, however, CGA requires explicit construction.
  ##   E.g. this is, in RGA, equivalent to applying exomporphism as 𝐆𝐦 or 𝔾𝐦.

  func constructPart(inclusions, exclusions: seq[Basis]): Cayley1D {.compileTime, noinit.} =
    ## Construct sub-slice of Cayley table respresenting identity map.
    for b in Basis:
      result[b] = @[b.toSigned]
    result.filterFactors(inclusions)
    result.filterFactors(exclusions, as_exclusions = true)

  let
    inclusions = case partiality
      of Partiality.Bulk: @[]
      of Partiality.Weight: @[Basis.origin]
    exclusions = case partiality
      of Partiality.Bulk: @[Basis.origin]
      of Partiality.Weight: @[]

  when IS_RIGID:
    Formal[Cayley1D](round: constructPart(inclusions, exclusions))
  else:
    Formal[Cayley1D](
      round: constructPart(inclusions, exclusions & @[Basis.infinity]),
      flat: constructPart(inclusions & @[Basis.infinity], exclusions),
    )


func constructReverse(): Cayley1D {.compileTime, noinit.} =
  ## Construct Cayley table for reverse; antireverse conjugates it.
  for b in Basis:
    result[b] = @[b.reverse]


func constructAnti(cayley: Cayley1D, complements: Chiral[Cayley1D]): Cayley1D {.compileTime.} =
  ## Construct anti version of 1D cayley table by applying right (left) complement before (after).
  complements.left.applyMap(cayley.applyMap(complements.right))


func constructAnti(cayley: Cayley2D, complements: Chiral[Cayley1D]): Cayley2D {.compileTime.} =
  ## Construct anti version of 2D cayley table by applying right (left) complement before (after).
  for m in Basis:
    let m_from = complements.right[m].toSigned

    for n in Basis:
      let n_from = complements.right[n].toSigned

      for term in cayley[m_from.basis][n_from.basis]:
        let product_to = complements.left[term.basis].toSigned
        result[m][n].add BasisSigned(
          basis: product_to.basis,
          is_negated: (
            m_from.is_negated xor
            n_from.is_negated xor
            term.is_negated xor
            product_to.is_negated
          ),
        )


func constructMetric(): Cayley1D {.compileTime.} =
  ## Construct metric 𝖌 simplified as 1D cayley table.
  let 𝐞ₙ = Basis(DIMENSIONS)
  for b in Basis:
    if b.grade <= Grade(1) and b != 𝐞ₙ:
      result[b] = @[b.toSigned]

  # Adjust metric to conformal structure if necessary.
  when IS_CONFORMAL:
    result[𝐞ₙ] = @[BasisSigned(basis: 𝐞ₙ.pred, is_negated: true)]
    result[𝐞ₙ.pred] = @[BasisSigned(basis: 𝐞ₙ, is_negated: true)]


func constructMetricExomorphism(metric: Cayley1D): Cayley1D {.compileTime, noinit.} =
  ## Construct metric exomorphism 𝐆 from metric 𝖌 simplified as 1D cayley table.
  ##   𝖌 expands to 𝐆 via 𝐆(𝐦 ∧ 𝐧) = (𝐆𝐦) ∧ (𝐆𝐧).
  ##   Likewise with `constructAnti` applied on output:
  ##     𝔾 via 𝔾𝐦 = 𝐆̲𝐦̲̅, i.e. right complement of 𝐦, left complement of result.
  ##     Equivalent to expanding as 𝔾 via 𝔾(𝐦 ∨ 𝐧) = (𝔾𝐦) ∨ (𝔾𝐧).
  result = metric

  for operand in Basis:
    if operand.grade < Grade(2): continue
    var 
      bases: seq[BasisSigned]
      is_degenerate = false

    # Determine if any vector component of basis is degenerate.
    for d in operand.toDigits:
      let basis = BasisDigits($d).toBasis
      if result[basis].len == 0:
        is_degenerate = true
        break
      bases.add(result[basis])
    if is_degenerate: continue

    # Reconstruct resulting signed basis from vector components.
    var product = multiplyExterior(bases[0], bases[1])
    assert not product.is_degenerate
    if len(bases) > 2:
      for i in 2 ..< len(bases):
        product = multiplyExterior(product.basis, bases[i])

    result[operand] = @[product.basis]


func constructProductExterior(
  complements: Chiral[Cayley1D], spatiality: Spatiality
): Cayley2D {.compileTime.} =
  ## Construct Cayley table for specific exterior/(anti)wedge product.
  for m in Basis:
    for n in Basis:
      # Retrieve product reduction if not degenerate.
      let product = case spatiality
        of Spatiality.Base: multiplyExterior(m.toSigned, n.toSigned)
        of Spatiality.Anti: multiplyExterior(
          complements.right[m].toSigned, 
          complements.right[n].toSigned
        )
      if product.is_degenerate: continue

      # Construct exterior product mappings.
      result[m][n].add(case spatiality
        of Spatiality.Base: product.basis
        of Spatiality.Anti:
          let product_complement = complements.left[product.basis.basis].toSigned
          BasisSigned(
            basis: product_complement.basis,
            is_negated: product.basis.is_negated xor product_complement.is_negated,
          )
      )


func constructProductGeometric(wedges_trans: array[Order, Cayley2D]): Cayley2D {.compileTime.} =
  ## Construct Cayley table for specific geometric product.
  for order in Order:
    let
      k = int(order)
      is_negated = (k * (k - 1) div 2 and 1) == 1
    result.merge(wedges_trans[order], as_negated = is_negated)


func constructProductsTransitional(
  complement: Cayley1D,
  dual: Cayley1D,
  wedges: Spatial[Cayley2D],
  chirality: Chirality,
  spatiality: Spatiality,
): array[Order, Cayley2D] {.compileTime.} =
  ## Construct Cayley tables for each order of specific transitional product.
  for order in Order:
    result[order] = constructProductTransitional(
      order,
      complement,
      dual,
      wedges,
      chirality,
      spatiality,
    )


func constructProductTransitional(
  order: Order,
  complement: Cayley1D,
  dual: Cayley1D,
  wedges: Spatial[Cayley2D],
  chirality: Chirality,
  spatiality: Spatiality,
): Cayley2D {.compileTime.} =
  ## Construct Cayley table for selected order of specific transitional product.

  # Determine orientation of wedges.
  let
    wedge_outer = case spatiality
      of Spatiality.Base: wedges.anti
      of Spatiality.Anti: wedges.base
    wedge_inner = case spatiality
      of Spatiality.Base: wedges.base
      of Spatiality.Anti: wedges.anti

  for c in Basis:  # Note: Nesting likely required due to nature of transitive product.

    # Skip over grades of different orders.
    let c_order = case spatiality
      of Spatiality.Base: Order(c.grade)
      of Spatiality.Anti: Order(c.gradeAnti)
    if c_order != order: continue

    # Detect if dual degenerates.
    if dual[c].len == 0: continue

    # Determine sides for each operator.
    let
      c_complement = complement[c].toSigned
      c_dual = dual[c].toSigned
      operators = case chirality
        of Chirality.Left: Chiral[Basis](left: c_dual.basis, right: c_complement.basis)
        of Chirality.Right: Chiral[Basis](left: c_complement.basis, right: c_dual.basis)

    for m in Basis:

      # Reduce left side product.
      let products_left = wedge_outer[operators.left][m]
      if products_left.len == 0: continue

      for n in Basis:

        # Reduce right side product.
        let products_right = wedge_outer[n][operators.right]
        if products_right.len == 0: continue

        # Reduce product between both sides.
        let
          product_left = products_left.toSigned
          product_right = products_right.toSigned
          products_center = wedge_inner[product_left.basis][product_right.basis]
        if products_center.len == 0: continue

        # Construct transitional product mappings.
        let
          product_center = products_center.toSigned
          is_negated = (
            c_dual.is_negated xor
            c_complement.is_negated xor
            product_left.is_negated xor
            product_center.is_negated xor
            product_right.is_negated
          )
        result[m][n].add BasisSigned(basis: product_center.basis, is_negated: is_negated)



#[ Basis Transformations ]#

func complement(b: Basis, chirality: Chirality): BasisSigned {.compileTime.} =
  ## Get complement of basis (right by default).
  let
    mask = Basis.scalarAnti.toFlags
    antibasis = (not b.toFlags and mask).toBasis.toSigned
    antiscalar = case chirality
      of Chirality.Left: multiplyExterior(antibasis, b.toSigned)
      of Chirality.Right: multiplyExterior(b.toSigned, antibasis)
  BasisSigned(basis: antibasis.basis, is_negated: antiscalar.basis.is_negated)


func reverse(b: Basis): BasisSigned {.compileTime.} =
  ## Get reverse of basis.
  let
    grade = int(b.grade)
    parity = ((int(grade * (grade - 1)) div 2) and 1) == 1
  BasisSigned(basis: b, is_negated: parity)


func multiplyExterior(
  a, b: BasisSigned
): tuple[basis: BasisSigned, is_degenerate: bool] {.compileTime.} =
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


func toSigned(b: Basis): BasisSigned {.compileTime, noinit.} = BasisSigned(basis: b)
  ## Convert basis to signed basis assuming positive.


func toSigned(product: seq[BasisSigned]): BasisSigned {.compileTime.} =
  ## Convert cayley product cell to signed basis where is singleton.
  assert product.len == 1, &"Attempt to extract singular product term from `{product}`."
  product[0]


#[ Cayley Transformations ]#

func applyConstant(
  cayley: var Cayley2D, basis: BasisSigned, chirality: Chirality
): Cayley1D {.compileTime, noinit.} =
  ## Collapse 2D cayley into 1D by applying contstant unit basis to left or right operand.

  case chirality
    of Chirality.Left:
      cayley.filterBases(operands_m = @[basis.basis])
    of Chirality.Right:
      cayley.filterBases(operands_n = @[basis.basis])

  result = cayley.slice(basis.basis, chirality)

  for operand in Basis:
    if result[operand].len == 0: continue
    let product_signed = result[operand].toSigned
    result[operand] = @[BasisSigned(
      basis: product_signed.basis,
      is_negated: product_signed.is_negated xor basis.is_negated,
    )]


func applyMap(cayley: Cayley1D, map: Cayley1D): Cayley1D {.compileTime.} =
  ## Apply map to operand of 1D cayley, i.e. cayley(map(𝐦)).
  ##   Map runs first, cayley second; several terms distribute and opposing terms cancel.
  for operand in Basis:
    for term_map in map[operand]:
      for term in cayley[term_map.basis]:
        result[operand].mergeTerm BasisSigned(
          basis: term.basis,
          is_negated: term_map.is_negated xor term.is_negated,
        )


func applyMap(cayley: Cayley2D, map: Cayley1D, chirality: Chirality): Cayley2D {.compileTime.} =
  ## Apply map to left or right operand of 2D cayley.
  ##   I.e. cayley(map(𝐦), 𝐧) for left and cayley(𝐦, map(𝐧)) for right.
  for m in Basis:
    for n in Basis:
      let mapped = case chirality
        of Chirality.Left: map[m]
        of Chirality.Right: map[n]
      for term_map in mapped:
        let product = case chirality
          of Chirality.Left: cayley[term_map.basis][n]
          of Chirality.Right: cayley[m][term_map.basis]
        for term in product:
          result[m][n].mergeTerm BasisSigned(
            basis: term.basis,
            is_negated: term_map.is_negated xor term.is_negated,
          )


func filterBases(
  cayley: var Cayley1D,
  operands = default(seq[Basis]),
  products = default(seq[Basis]),
  as_exclusions = false,
) {.compileTime.} =
  ## Filter out specific operands/products from 1D cayley table by bases.
  for operand in Basis:
    if cayley[operand].len == 0: continue

    # Filter by operand.
    if (operands.len != 0 and operand notin operands) or (as_exclusions and operand in operands):
      cayley[operand] = @[]
      continue

    # Filter by product.
    let product_signed = cayley[operand].toSigned
    if (products.len != 0 and product_signed.basis notin products) or
        (as_exclusions and product_signed.basis in products):
      cayley[operand] = @[]


func filterBases(
  cayley: var Cayley2D,
  operands_m = default(seq[Basis]),
  operands_n = default(seq[Basis]),
  products = default(seq[Basis]),
  as_exclusions = false,
) {.compileTime.} =
  ## Filter out specific operands/products from 2D cayley table by bases.
  for m in Basis:

    # Filter by m operands.
    if (operands_m.len != 0 and m notin operands_m) or (as_exclusions and m in operands_m):
      for n in Basis:
        cayley[m][n] = @[]

    for n in Basis:
      if cayley[m][n].len == 0: continue

      # Filter by n operands.
      if (operands_n.len != 0 and n notin operands_n) or (as_exclusions and n in operands_n):
        cayley[m][n] = @[]
        continue

      # Filter by product.
      for b in cayley[m][n]:
        if (products.len != 0 and b.basis notin products) or 
            (as_exclusions and b.basis in products):
          cayley[m][n] = @[] # TODO: Remove only matching elements.
          break


func filterGrades(
  cayley: var Cayley1D,
  operands = default(seq[Grade]),
  products = default(seq[Grade]),
  as_exclusions = false,
) {.compileTime.} =
  ## Filter out specific operands/products from 1D cayley table by grades.
  for operand in Basis:
    if cayley[operand].len == 0: continue

    # Filter by operand grade.
    if (operands.len != 0 and operand.grade notin operands) or
        (as_exclusions and operand.grade in operands):
      cayley[operand] = @[]
      continue

    # Filter by product grade.
    let product_signed = cayley[operand].toSigned
    if (products.len != 0 and product_signed.basis.grade notin products) or
        (as_exclusions and product_signed.basis.grade in products):
      cayley[operand] = @[]


func filterGrades(
  cayley: var Cayley2D,
  operands_m = default(seq[Grade]),
  operands_n = default(seq[Grade]),
  products = default(seq[Grade]),
  as_exclusions = false;
) {.compileTime.} =
  ## Filter out specific operands/products from 2D cayley table by bases.
  for m in Basis:

    # Filter by m operands.
    if (operands_m.len != 0 and m.grade notin operands_m) or
        (as_exclusions and m.grade in operands_m):
      for n in Basis:
        cayley[m][n] = @[]

    for n in Basis:
      if cayley[m][n].len == 0: continue

      # Filter by n operands.
      if (operands_n.len != 0 and n.grade notin operands_n) or
          (as_exclusions and n.grade in operands_n):
        cayley[m][n] = @[]
        continue

      # Filter by product.
      for b in cayley[m][n]:
        if (products.len != 0 and b.basis.grade notin products) or
            (as_exclusions and b.basis.grade in products):
          cayley[m][n] = @[] # TODO: Remove only matching elements.
          break


func filterFactors(
  cayley: var Cayley1D, factors: seq[Basis], as_exclusions = false
) {.compileTime.} =
  ## Filter out specific operands/products from 1D cayley table.
  for f in factors:
    assert countSetBits(f.toFlags) == 1,
      &"Attempt to filter with non-grade 1 basis factor: `{f=}`."

  for operand in Basis:

    # Determine if basis contains filtered vector factor.
    let operand_flags = operand.toFlags
    var should_filter = false
    for f in factors:
      let flags_overlap = f.toFlags and operand_flags
      if (as_exclusions and int(flags_overlap) != 0) or
          (not as_exclusions and int(flags_overlap) == 0):
        should_filter = true
        break
    if should_filter:
      cayley[operand] = @[]


func mergeTerm(cell: var seq[BasisSigned], term: BasisSigned, as_negated = false) {.compileTime.} =
  ## Merge term into cell, cancelling opposing term when found, else adding term.
  ##   Cancels matching where `as_negated = true`.
  let
    is_negated = not term.is_negated xor as_negated
    term_cancel = BasisSigned(basis: term.basis, is_negated: is_negated)
    position = cell.find(term_cancel)
  if position != -1:
    cell.delete(position)
    return
  cell.add BasisSigned(basis: term.basis, is_negated: term.is_negated xor as_negated)


func merge(destination: var Cayley2D, source: Cayley2D, as_negated = false) {.compileTime.} =
  ## Merge two 2D cayley tables in place, simplifying/cancelling opposing terms.
  for m in Basis:
    for n in Basis:
      for term in source[m][n]:
        destination[m][n].mergeTerm(term, as_negated)


func negate(cayley: var Cayley1D) {.compileTime.} =
  ## Negate all signed basis of 1D cayley table in place.
  for operand in Basis:
    if cayley[operand].len == 0: continue
    cayley[operand][0].is_negated = not cayley[operand].toSigned.is_negated


func negate(cayley: var Cayley2D) {.compileTime.} =
  ## Negate all signed basis of 2D cayley table in place.
  for m in Basis:
    for n in Basis:
      for term in 0..<cayley[m][n].len:
        cayley[m][n][term].is_negated = not cayley[m][n][term].is_negated


func slice(
  cayley: Cayley2D, operand: Basis, chirality: Chirality
): Cayley1D {.compileTime, noinit.} =
  ## Extract vertical slice of 2D cayley as 1D map.
  for b in Basis:
    let terms = case chirality
      of Chirality.Left: cayley[operand][b]
      of Chirality.Right: cayley[b][operand]
    assert terms.len <= 1,
      &"Attempt to convert 2D cayley to 1D with non-singleton product values;" &
      &" got `{terms}` for `{chirality}` `{operand}`."
    result[b] = if terms.len == 1: @[terms.toSigned] else: @[]


func collapse(cayley: Cayley2D): Cayley1D {.compileTime.} =
  ## Collapse 2D cayley to 1D map.
  # TODO: Covert 1D cayley to seq as well so this is possible.
  #   This will vastly simplify operator emission macros,
  #     and also allow for simpler sandwiching.
  discard



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
  var 
    b_flags_remaining = uint(b)
    swaps = 0

  # Count `a` flags greater than each `b` flag (i.e. requires swap).
  while b_flags_remaining != 0:
    let 
      offset_b_flags_min = countTrailingZeroBits(b_flags_remaining)
      count_flags_where_a_greater = countSetBits(a_flags shr (offset_b_flags_min + 1))
    swaps += count_flags_where_a_greater

    # Clear `b` flags already accounted for.
    b_flags_remaining = b_flags_remaining and (b_flags_remaining - 1)

  # Determine if parity (negation) bit remains set.
  (swaps and 1) == 1



#[ Basis Aliasing ]#

func horizon(t: typedesc[Basis]): BasisSigned {.compileTime.} =
  ## Alias basis representing horizon (i.e. 𝐞̄ₙ in RGA; 𝐞̄ₙ₋₁ in CGA).
  ##   TODO: Is 𝐞̄ₙ₋₁ horizion in conformal?
  Basis.origin.complement(Chirality.Right)
```
