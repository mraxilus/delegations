# Basis-set types, whose products return exactly the bases they reach

A new module, `pga/basis_sets.nim`, holds one generic type for any set of bases. It names one type
for each grade and one for each parity. Each product of two basis-set types returns the exact set
of bases that its table reaches. `pga.nim` exports the module, and gives each generic operator its
named alias beside the alias on `Multivector`. Three TODOs of `pga/multivectors.nim` asked for
these types, so one TODO replaces them, for the question that stays open.

## Add `pga/basis_sets.nim`

```nim
## Define basis-set types: multivectors of one set of bases, whose products return exact set.
##   One generic object, `MultivectorOf[B]`, holds coefficients of any set `B` of bases, dense in
##     basis order. Slot of basis is count of bases of `B` below it, folded at compile time.
##   Named basis-set types are its aliases: one per grade, `Kvector0` to `KvectorN`, and one per
##     parity, `MultivectorEven` and `MultivectorOdd`. Alias adds no type.
##   Product reads library's whole table over bases of its operands alone, and returns exact
##     basis-set type of bases it reaches. So dot of whole multivectors is one slot, and bulk of
##     bivector is part of its grade. Tables stay whole, so their count grows with no type.
##   Each basis-set type aligns to `alignment` of its count of floats: largest power of two
##     dividing their bytes, at most one cache line, so it pads none.
##   `Multivector` stays whole algebra, and every operator on it stays. Basis-set type widens
##     through `toMultivector`, and narrows through `toMultivectorOf`.
##
##   Cost: products stay generic, since one body per pair of types makes some 6 000 at cga5d;
##     each instance takes whole `Cayley2D` as static argument, compile cost unmeasured.
##   Cost: only `∧`, `⟇`, `∙`, `∘` and round parts are generic; every other operator widens first.
##   Cost: reach is what table can produce, not what algebra guarantees; sandwich of vector
##     returns `MultivectorOdd`, though its value lies in grade 1.
##   Cost: pinned compiler stops on `align` of expression of `B`, so type picks among 8, 16, 32
##     and 64 through `when`.

{.experimental: "codeReordering".}
{.experimental: "strictFuncs".}

import std/macros

import ./[algebra, cayleys, multivectors]



#[ Type Definition ]#

type MultivectorOf*[B: static set[Basis]] = object
  ## Define multivector of bases `B` alone, coefficients dense in basis order.
  ##   Aligned to `alignment` of its count through `when`. Field stays private, as on `Multivector`.
  when alignment(card(B)) == 64:
    elements {.align(64).}: array[card(B), float]
  elif alignment(card(B)) == 32:
    elements {.align(32).}: array[card(B), float]
  elif alignment(card(B)) == 16:
    elements {.align(16).}: array[card(B), float]
  else:
    elements: array[card(B), float]


const ALIGNMENT_MAX = 64  ## Cap alignment at bytes of one cache line.



#[ Basis-Set Types ]#

func alignment*(count: int): int =
  ## Get alignment of `count` floats: largest power of two dividing their bytes, at most one line.
  ##   Alignment divides size, so it pads no count; empty set keeps alignment of float.
  let size = sizeof(float) * count
  max(sizeof(float), min(ALIGNMENT_MAX, size and -size))


func emitSet(listed: set[Basis]): NimNode {.compileTime.} =
  ## Emit set of bases as literal, since `quote` cannot embed set value.
  result = nnkCurly.newTree()
  for basis in listed: result.add nnkDotExpr.newTree(ident"Basis", ident($basis))


macro defineMultivectors(): untyped =
  ## Name basis-set types of each grade and of each parity, as aliases of exact ones.

  func basesOfParity(is_even: bool): set[Basis] =
    ## Get bases of even or odd grade.
    for basis in Basis:
      if (int(basis.grade) mod 2 == 0) == is_even: result.incl basis

  result = newStmtList()
  for grade in Grade.low..Grade.high:
    let
      bases = LUT_BASES_BY_GRADE[grade]
      (alias, spelled) = (ident("Kvector" & $int(grade)), emitSet({bases.a .. bases.b}))
    result.add quote do:
      type `alias`* = MultivectorOf[`spelled`]  ## Define basis-set type of one grade.
  for (name, is_even) in [("MultivectorEven", true), ("MultivectorOdd", false)]:
    let (alias, spelled) = (ident(name), emitSet(basesOfParity(is_even = is_even)))
    result.add quote do:
      type `alias`* = MultivectorOf[`spelled`]  ## Define basis-set type of one parity.


defineMultivectors()



#[ Basis-Set Accessors ]#

func slot(listed: set[Basis], basis: Basis): int {.compileTime.} =
  ## Get dense slot of listed basis: count of listed bases up to it, less itself.
  card(listed * {Basis.scalar .. basis}) - 1


template `[]`*[B: static set[Basis]](m: MultivectorOf[B], basis: static Basis): float =
  ## Read coefficient of basis from its dense slot; basis outside `B` stops compile.
  static: doAssert basis in B, "Basis must be among bases of type; got `" & $basis & "`."
  m.elements[static(slot(B, basis))]


template `[]=`*[B: static set[Basis]](m: var MultivectorOf[B], basis: static Basis, value: float) =
  ## Write coefficient of basis into its dense slot; basis outside `B` stops compile.
  static: doAssert basis in B, "Basis must be among bases of type; got `" & $basis & "`."
  m.elements[static(slot(B, basis))] = value


func coefficient*[B: static set[Basis]](m: MultivectorOf[B], basis: Basis): float =
  ## Read coefficient of basis known only at run time; basis outside `B` reads zero, its value.
  const lut_slot_by_basis = block:
    var lut: array[Basis, int]
    for listed in B: lut[listed] = slot(B, listed)
    lut
  if basis in B: m.elements[lut_slot_by_basis[basis]] else: 0.0


func bases*[B: static set[Basis]](t: typedesc[MultivectorOf[B]]): set[Basis] = B
  ## Get bases basis-set type holds.


func toMultivector*[B: static set[Basis]](m: MultivectorOf[B]): Multivector =
  ## Widen basis-set type to multivector of every basis, same coefficients.
  ##   Slot runs with walk over `B`: counting it per basis took ×1.05 to ×16.5 as long, measured
  ##     at rga4d, cga5d and rga6d on 2.1 GHz Xeon, 2026-10-15.
  var index = 0
  for basis in B:
    result[basis] = m.elements[index]
    inc index


func toMultivectorOf*[B: static set[Basis]](
  m: Multivector, t: typedesc[MultivectorOf[B]]
): MultivectorOf[B] =
  ## Narrow multivector to basis-set type `t`.
  ##   Each coefficient outside `B` must be zero within comparison tolerance, as `grade` tests it.
  var index = 0
  for basis in Basis:
    if basis in B:
      result.elements[index] = m[basis]
      inc index
    else:
      doAssert abs(m[basis]) <= TOLERANCE_ABS,
        "Coefficient outside bases of type must be zero; got `" & $m[basis] & "` at `" &
        $basis & "`."



#[ Products ]#

func emitRead(m: NimNode, basis: Basis): NimNode {.compileTime.} =
  ## Emit read of one coefficient of operand.
  nnkBracketExpr.newTree(m, nnkDotExpr.newTree(ident"Basis", ident($basis)))


func emitWrites(sums: array[Basis, seq[NimNode]]): NimNode {.compileTime.} =
  ## Emit write of each reached slot once; every slot of exact type is reached, so none fills.

  func emitSum(terms: seq[NimNode]): NimNode =
    ## Emit sum of terms, left to right.
    result = terms[0]
    for term in terms[1 .. ^1]: result = infix(result, "+", term)

  result = newStmtList()
  for basis in Basis:
    if sums[basis].len > 0:
      result.add newAssignment(emitRead(ident"result", basis), emitSum(sums[basis]))


macro typeReached*(cayley: static Cayley2D; bases_m, bases_n: static set[Basis]): untyped =
  ## Spell basis-set type product reaches, as literal set, so it is same type as any alias.

  func reach(cayley: Cayley2D; bases_m, bases_n: set[Basis]): set[Basis] =
    ## Get bases product reaches over operands' bases.
    for left in bases_m:
      for right in bases_n:
        for term in cayley[left][right]: result.incl term.basis

  nnkBracketExpr.newTree(ident"MultivectorOf", emitSet(reach(cayley, bases_m, bases_n)))


macro typeReached*(cayley: static Cayley1D, bases_m: static set[Basis]): untyped =
  ## Spell basis-set type map reaches, as literal set.

  func reach(cayley: Cayley1D, bases_m: set[Basis]): set[Basis] =
    ## Get bases map reaches over operand's bases.
    for basis in bases_m:
      for term in cayley[basis]: result.incl term.basis

  nnkBracketExpr.newTree(ident"MultivectorOf", emitSet(reach(cayley, bases_m)))


macro defineProduct(
  cayley: static Cayley2D; bases_m, bases_n: static set[Basis]; m, n: untyped
): untyped =
  ## Define product over operands' bases alone, into result of exact basis-set type.
  var sums: array[Basis, seq[NimNode]]
  for left in bases_m:
    for right in bases_n:
      for term in cayley[left][right]:
        let product = infix(emitRead(m, left), "*", emitRead(n, right))
        sums[term.basis].add(if term.is_negated: prefix(product, "-") else: product)
  emitWrites(sums)


macro defineMap(cayley: static Cayley1D, bases_m: static set[Basis], m: untyped): untyped =
  ## Define map over operand's bases alone, into result of exact basis-set type.
  var sums: array[Basis, seq[NimNode]]
  for basis in bases_m:
    for term in cayley[basis]:
      let read = emitRead(m, basis)
      sums[term.basis].add(if term.is_negated: prefix(read, "-") else: read)
  emitWrites(sums)


func `∧`*[A, B: static set[Basis]](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_WEDGE.base, A, B) {.noinit.} =
  ## Multiply through exterior product, i.e. 𝐦 ∧ 𝐧; result holds exactly bases reached.
  defineProduct(CAYLEYS_WEDGE.base, A, B, m, n)


func `⟇`*[A, B: static set[Basis]](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_WEDGE_DOT.anti, A, B) {.noinit.} =
  ## Multiply through geometric antiproduct, i.e. 𝐦 ⟇ 𝐧; result holds exactly bases reached.
  defineProduct(CAYLEYS_WEDGE_DOT.anti, A, B, m, n)


func `∙`*[A, B: static set[Basis]](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_DOT.base, A, B) {.noinit.} =
  ## Multiply through inner product, i.e. 𝐦 ∙ 𝐧; result holds scalar slot alone.
  defineProduct(CAYLEYS_DOT.base, A, B, m, n)


func `∘`*[A, B: static set[Basis]](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_DOT.anti, A, B) {.noinit.} =
  ## Multiply through inner antiproduct, i.e. 𝐦 ∘ 𝐧; result holds antiscalar slot alone.
  defineProduct(CAYLEYS_DOT.anti, A, B, m, n)


func `∙`*[A: static set[Basis]](
  m: MultivectorOf[A],
): typeReached(CAYLEYS_PARTS.bulk.round, A) {.noinit.} =
  ## Extract (round) bulk, i.e. 𝐦∙; result holds exactly bulk bases of operand's type.
  defineMap(CAYLEYS_PARTS.bulk.round, A, m)


func `∘`*[A: static set[Basis]](
  m: MultivectorOf[A],
): typeReached(CAYLEYS_PARTS.weight.round, A) {.noinit.} =
  ## Extract (round) weight, i.e. 𝐦∘; result holds exactly weight bases of operand's type.
  defineMap(CAYLEYS_PARTS.weight.round, A, m)
```

## Edit `pga.nim`

```nim
##   Basis -> BasisSigned
##         -> Multivector
```

```nim
##   Basis -> BasisSigned
##         -> [Multivector, MultivectorOf]
```

## Edit `pga.nim`

```nim
import ./pga/[algebra, cayleys, multivectors, operators]
export algebra, cayleys, multivectors, operators
```

```nim
import ./pga/[algebra, basis_sets, cayleys, multivectors, operators]
export algebra, basis_sets, cayleys, multivectors, operators
```

## Edit `pga.nim`

```nim
  func weight*(m: Multivector): Multivector {.inline.} = ∘m
    ## Extract weight of multivector.
    ##   Weight contains object's attitude and orientation.
    ##   Where weight is 0, object is contained by (N-1)D object at infinity.
```

```nim
  func weight*(m: Multivector): Multivector {.inline.} = ∘m
    ## Extract weight of multivector.
    ##   Weight contains object's attitude and orientation.
    ##   Where weight is 0, object is contained by (N-1)D object at infinity.

  func bulk*[A: static set[Basis]](
    m: MultivectorOf[A],
  ): typeReached(CAYLEYS_PARTS.bulk.round, A) {.inline.} = ∙m
    ## Extract bulk of basis-set type, into exact basis-set type reached.

  func weight*[A: static set[Basis]](
    m: MultivectorOf[A],
  ): typeReached(CAYLEYS_PARTS.weight.round, A) {.inline.} = ∘m
    ## Extract weight of basis-set type, into exact basis-set type reached.
```

## Edit `pga.nim`

```nim
  func bulkRound*(m: Multivector): Multivector {.inline.} = ∙m
    ## Extract round bulk of multivector.
    ##   Bulk contains object's position.
```

```nim
  func bulkRound*(m: Multivector): Multivector {.inline.} = ∙m
    ## Extract round bulk of multivector.
    ##   Bulk contains object's position.

  func bulkRound*[A: static set[Basis]](
    m: MultivectorOf[A],
  ): typeReached(CAYLEYS_PARTS.bulk.round, A) {.inline.} = ∙m
    ## Extract round bulk of basis-set type, into exact basis-set type reached.
```

## Edit `pga.nim`

```nim
  func weightRound*(m: Multivector): Multivector {.inline.} = ∘m
    ## Extract round weight of multivector.
    ##   Weight contains object's attitude and orientation.
```

```nim
  func weightRound*(m: Multivector): Multivector {.inline.} = ∘m
    ## Extract round weight of multivector.
    ##   Weight contains object's attitude and orientation.

  func weightRound*[A: static set[Basis]](
    m: MultivectorOf[A],
  ): typeReached(CAYLEYS_PARTS.weight.round, A) {.inline.} = ∘m
    ## Extract round weight of basis-set type, into exact basis-set type reached.
```

## Edit `pga.nim`

```nim
func dot*(m, n: Multivector): Multivector {.inline.} = m ∙ n
  ## Multiply multivectors through inner product between bulks.
```

```nim
func dot*(m, n: Multivector): Multivector {.inline.} = m ∙ n
  ## Multiply multivectors through inner product between bulks.

func dot*[A, B: static set[Basis]](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_DOT.base, A, B) {.inline.} = m ∙ n
  ## Multiply basis-set types through inner product, into exact basis-set type reached.
```

## Edit `pga.nim`

```nim
func dotAnti*(m, n: Multivector): Multivector {.inline.} = m ∘ n
  ## Multiply multivectors through inner product between weights.
```

```nim
func dotAnti*(m, n: Multivector): Multivector {.inline.} = m ∘ n
  ## Multiply multivectors through inner product between weights.

func dotAnti*[A, B: static set[Basis]](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_DOT.anti, A, B) {.inline.} = m ∘ n
  ## Multiply basis-set types through inner antiproduct, into exact basis-set type reached.
```

## Edit `pga.nim`

```nim
func wedge*(m, n: Multivector): Multivector {.inline.} = m ∧ n
  ## Multiply multivectors by combining jointly present dimensions.
  ##   I.e. multiply through exterior product.
  ##   Also called join operation, analogous to union.
```

```nim
func wedge*(m, n: Multivector): Multivector {.inline.} = m ∧ n
  ## Multiply multivectors by combining jointly present dimensions.
  ##   I.e. multiply through exterior product.
  ##   Also called join operation, analogous to union.

func wedge*[A, B: static set[Basis]](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_WEDGE.base, A, B) {.inline.} = m ∧ n
  ## Multiply basis-set types through exterior product, into exact basis-set type reached.
```

## Edit `pga.nim`

```nim
func wedgeDotAnti*(m, n: Multivector): Multivector {.inline.} = m ⟇ n
  ## Multiply multivectors through geometric antiproduct.
  ##   Incorporates antiwedge proudct, adding information.
```

```nim
func wedgeDotAnti*(m, n: Multivector): Multivector {.inline.} = m ⟇ n
  ## Multiply multivectors through geometric antiproduct.
  ##   Incorporates antiwedge proudct, adding information.

func wedgeDotAnti*[A, B: static set[Basis]](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_WEDGE_DOT.anti, A, B) {.inline.} = m ⟇ n
  ## Multiply basis-set types through geometric antiproduct, into exact basis-set type reached.
```

## Edit `pga/multivectors.nim`

```nim
# TODO: Represent multivector primitives using more compact data types.
#   E.g. Point, Line, Plane, Volume, Motor, Flector.
#   At cost of additional meta-programming, this affords:
#     - More optimization with SoA (how much more over SIMD of multivectors?),
#     - Simpler reasoning about objects resulting from operations.
#     - IDE support for recognizing resulting objects from operations.
#   Perhaps base library should only contain full multivector operations for simplicity?
#     I.e. to serve more as learning reference, optimising where necessary.
# TODO: Dynamically create subsets of multivectors for compact operators.
#   Related to compact data types todo above.
#   E.g. Point is Kvector1, Line is Kvector2, Plane is Kvector3.
#   Point wedge Point is Line, i.e. Kv1 wedge Kv1 is Kv2.
#     Kvector0 = object
#       elements: array[S..S, float]
#      Kvector1 = object
#       elements: array[E1..E4, float]
#     Kvector2 = object
#       elements: array[E41..E21, float]
#     Kvector3 = object
#       elements: array[E413..E321, float]
#     Kvector4 = object
#       elements: array[E1234..E1234, float]
# TODO: Create dynamic BasisEven/BasisOdd enums with converters to/from Basis.
#    Related to slices missing from compact types above, namely for motors/flectors.
#    E.g. BasisEven is all even grade Basis: E41..E21, E1234.
#    This is limitation of Nim as ranges from enums must be contiguous.
#    We could get around this by, in Basis, listing all even grades first, then all odd.
#      But that would complicate understanding/usage, and cause hard to debug issues.
#        E.g. In 4D RGA, Basis.origin.succ would now be E413 instead of E41.
#        Technically we could override pred/succ/items/etc. to be transparent to user.
#        Though all of this would complicate code dramatically.
```

```nim
# TODO: Measure SoA over arrays of basis-set types (`basis_sets.nim`) against SIMD of multivectors.
```
