# Products of basis-set types, which return exactly the bases they reach

At pin, `MultivectorOf[B]` holds the coefficients of any set of bases, and the library names one
alias for each grade and each parity. Each product still takes and returns a whole `Multivector`.
This change adds a module, `pga/basis_sets.nim`, whose products of two basis-set types return the
exact set of bases that their table reaches. `pga.nim` exports the module, and gives each generic
product its named alias beside the alias on `Multivector`.

Each basis-set type also aligns to `alignment` of its count of coefficients. That is the largest
power of two that divides their bytes, and at most one cache line, so it pads none.

Nim reads the set of a generic type as it is spelled, so `{Basis.E1..Basis.E4}` and the four bases
listed are two types. Each alias of pin lists its bases, and `Multivector` spells the range of all
bases. So `typeReached` lists the bases it reaches, and names `Multivector` where it reaches all.
A product that reaches no basis stops the compile, since the pinned compiler instantiates no
`MultivectorOf` of an empty set.

P05, `multivector-align`, aligns the whole set alone, on the line that the first edit replaces. The
second to land quotes the first. Where this change lands, the whole set takes `alignment` of its
count, which is the alignment of P05.

## Edit `pga/multivectors.nim`

```nim
#[ Type Definition ]#

type
  Bases* = set[Basis]  ## TODO: Make distinct.
  MultivectorOf*[B: static Bases] = object
    elements: array[B.card, Coefficient]
```

```nim
#[ Type Definition ]#

const ALIGNMENT_MAX = 64  ## Cap alignment at bytes of one cache line.


func alignment*(count: int): int =
  ## Get alignment of `count` coefficients: largest power of two dividing their bytes, at most
  ##   one line. Alignment divides size, so it pads no count; empty set keeps that of coefficient.
  let size = sizeof(Coefficient) * count
  max(sizeof(Coefficient), min(ALIGNMENT_MAX, size and -size))


type
  Bases* = set[Basis]  ## TODO: Make distinct.
  MultivectorOf*[B: static Bases] = object
    ## Align to `alignment` of count through `when`: pinned compiler stops on `align` of `B`.
    when alignment(B.card) == 64:
      elements {.align(64).}: array[B.card, Coefficient]
    elif alignment(B.card) == 32:
      elements {.align(32).}: array[B.card, Coefficient]
    elif alignment(B.card) == 16:
      elements {.align(16).}: array[B.card, Coefficient]
    else:
      elements: array[B.card, Coefficient]
```

## Add `pga/basis_sets.nim`

```nim
## Define products of basis-set types, which return exact set of bases they reach.
##   Product reads library's whole table over bases of its operands alone, and returns exact
##     `MultivectorOf` of bases it reaches. So dot of whole multivectors is one slot, and bulk of
##     bivector is part of its grade. Tables stay whole, so their count grows with no type.
##   Result spells its set as aliases spell theirs, so it is their type: Nim tells sets apart by
##     spelling, and `{Basis.E1..Basis.E4}` is not `Multivector1`.
##
##   Cost: products stay generic, since one body per pair of types makes some 6 000 at cga5d;
##     each instance takes whole `Cayley2D` as static argument, compile cost unmeasured.
##   Cost: only `∧`, `⟇`, `∙`, `∘` and round parts are generic; every other operator widens first.
##   Cost: reach is what table can produce, not what algebra guarantees; sandwich of vector
##     returns `MultivectorOdd`, though its value lies in grade 1.

{.experimental: "strictFuncs".}

import std/macros

import ./[algebra, cayleys, emitters, multivectors]



#[ Emission ]#

func emitWrites(sums: array[Basis, seq[NimNode]]): NimNode {.compileTime.} =
  ## Emit write of each reached slot once; every slot of exact type is reached, so none fills.

  func emitSum(terms: seq[NimNode]): NimNode =
    ## Emit sum of terms, left to right.
    result = terms[0]
    for term in terms[1 .. ^1]: result = infix(result, "+", term)

  result = newStmtList()
  for b in Basis:
    if sums[b].len > 0:
      result.add newAssignment(emitSubscript("result", b), emitSum(sums[b]))


func emitReached(reached: Bases): NimNode {.compileTime.} =
  ## Spell type of reached bases as aliases spell theirs: `Multivector` for all, else each listed.
  ##   Product that reaches no basis is zero for any operands, and pinned compiler instantiates no
  ##     empty set, firstOrd(tyEmpty); so it stops compile.
  if reached.card == 0: error("Product must reach a basis; this one is zero for any operands.")
  if reached == {Basis.scalar..Basis.scalarAnti}: ident"Multivector"
  else: emitMultivectorOf(reached)


macro typeReached*(cayley: static Cayley2D; bases_m, bases_n: static Bases): untyped =
  ## Spell basis-set type product reaches, so it is same type as any alias.
  var reached: Bases
  for left in bases_m:
    for right in bases_n:
      for term in cayley[left][right]: reached.incl term.basis
  emitReached(reached)


macro typeReached*(cayley: static Cayley1D, bases_m: static Bases): untyped =
  ## Spell basis-set type map reaches, so it is same type as any alias.
  var reached: Bases
  for b in bases_m:
    for term in cayley[b]: reached.incl term.basis
  emitReached(reached)


macro defineProduct(cayley: static Cayley2D; bases_m, bases_n: static Bases): untyped =
  ## Define product over operands' bases alone, into result of exact basis-set type.
  var sums: array[Basis, seq[NimNode]]
  for left in bases_m:
    for right in bases_n:
      for term in cayley[left][right]:
        sums[term.basis].add emitTerm("m", left, "*", "n", right, term.is_negated)
  emitWrites(sums)


macro defineMap(cayley: static Cayley1D, bases_m: static Bases): untyped =
  ## Define map over operand's bases alone, into result of exact basis-set type.
  var sums: array[Basis, seq[NimNode]]
  for b in bases_m:
    for term in cayley[b]:
      let read = emitSubscript("m", b)
      sums[term.basis].add(if term.is_negated: prefix(read, "-") else: read)
  emitWrites(sums)



#[ Products ]#

func `∧`*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_WEDGE.base, A, B) {.noinit.} =
  ## Multiply through exterior product, i.e. 𝐦 ∧ 𝐧; result holds exactly bases reached.
  defineProduct(CAYLEYS_WEDGE.base, A, B)


func `⟇`*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_WEDGE_DOT.anti, A, B) {.noinit.} =
  ## Multiply through geometric antiproduct, i.e. 𝐦 ⟇ 𝐧; result holds exactly bases reached.
  defineProduct(CAYLEYS_WEDGE_DOT.anti, A, B)


func `∙`*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_DOT.base, A, B) {.noinit.} =
  ## Multiply through inner product, i.e. 𝐦 ∙ 𝐧; result holds scalar slot alone.
  defineProduct(CAYLEYS_DOT.base, A, B)


func `∘`*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_DOT.anti, A, B) {.noinit.} =
  ## Multiply through inner antiproduct, i.e. 𝐦 ∘ 𝐧; result holds antiscalar slot alone.
  defineProduct(CAYLEYS_DOT.anti, A, B)


func `∙`*[A: static Bases](
  m: MultivectorOf[A],
): typeReached(CAYLEYS_PARTS.bulk.round, A) {.noinit.} =
  ## Extract (round) bulk, i.e. 𝐦∙; result holds exactly bulk bases of operand's type.
  defineMap(CAYLEYS_PARTS.bulk.round, A)


func `∘`*[A: static Bases](
  m: MultivectorOf[A],
): typeReached(CAYLEYS_PARTS.weight.round, A) {.noinit.} =
  ## Extract (round) weight, i.e. 𝐦∘; result holds exactly weight bases of operand's type.
  defineMap(CAYLEYS_PARTS.weight.round, A)
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

  func bulk*[A: static Bases](
    m: MultivectorOf[A],
  ): typeReached(CAYLEYS_PARTS.bulk.round, A) {.inline.} = ∙m
    ## Extract bulk of basis-set type, into exact basis-set type reached.

  func weight*[A: static Bases](
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

  func bulkRound*[A: static Bases](
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

  func weightRound*[A: static Bases](
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

func dot*[A, B: static Bases](
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

func dotAnti*[A, B: static Bases](
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

func wedge*[A, B: static Bases](
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

func wedgeDotAnti*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_WEDGE_DOT.anti, A, B) {.inline.} = m ⟇ n
  ## Multiply basis-set types through geometric antiproduct, into exact basis-set type reached.
```
