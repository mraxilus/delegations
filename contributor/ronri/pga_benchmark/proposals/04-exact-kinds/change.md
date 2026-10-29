# Products of basis-set types, which return exactly the bases they reach

At pin, `MultivectorOf[B]` holds the coefficients of any set of bases, and the library names one
alias for each grade and each parity. Each operator still takes and returns a whole `Multivector`.
This change adds a module, `pga/basis_sets.nim`, with a form of basis-set types for each operator
that the library builds from one table. Each form returns the exact set of bases that its table
reaches. `pga.nim` exports the module, and gives each generic form its named alias beside the
alias on `Multivector`.

Each basis-set type also aligns to `alignment` of its count of coefficients. That is the largest
power of two that divides their bytes, and at most one cache line, so it pads none.

Nim reads the set of a generic type as it is spelled, so `{Basis.E1..Basis.E4}` and the four bases
listed are two types. Each alias of pin lists its bases, and `Multivector` spells the range of all
bases. So `typeReached` lists the bases it reaches, and names `Multivector` where it reaches all.
A form that reaches no basis stops the compile, since the pinned compiler instantiates no
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
## Define forms of basis-set types for each operator library builds from one table.
##   Form reads library's whole table over bases of its operands alone, and returns exact
##     `MultivectorOf` of bases it reaches. So dot is one coefficient, and bulk of bivector is
##     part of its grade. Tables stay whole, so their count grows with no type.
##   Result spells its set as aliases spell theirs, so it is their type: Nim tells sets apart by
##     spelling, and `{Basis.E1..Basis.E4}` is not `Multivector1`.
##   Squared norm reads its table with operand on both sides, as library's `as_unary` does.
##
##   Cost: forms stay generic, since one body per pair of types makes some 6 000 at cga5d;
##     each instance takes whole table as static argument, compile cost unmeasured.
##   Cost: operator library builds from no table stays on `Multivector`, as norms, `unitize`,
##     supports and `-` do; caller widens first.
##   Cost: form that reaches no basis stops compile, as bulk dual of antiscalar under rigid
##     metric does; widened call gives zero there.
##   Cost: reach is what table can produce, not what algebra guarantees; sandwich of vector
##     returns `MultivectorOdd`, though its value lies in grade 1.

{.experimental: "strictFuncs".}

import std/macros

import ./[algebra, cayleys, emitters, multivectors]



#[ Emission ]#

func emitWrites(sums: array[Basis, seq[NimNode]]): NimNode {.compileTime.} =
  ## Emit write of each reached coefficient once; every coefficient of exact type is reached, so
  ## none fills.

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


macro defineProduct(
  cayley: static Cayley2D; bases_m, bases_n: static Bases; as_unary: static bool = false
): untyped =
  ## Define product over operands' bases alone, into result of exact basis-set type.
  ##   Unary product reads 𝐦 on both sides, as library's squared norms do.
  let name_n = if as_unary: "m" else: "n"
  var sums: array[Basis, seq[NimNode]]
  for left in bases_m:
    for right in bases_n:
      for term in cayley[left][right]:
        sums[term.basis].add emitTerm("m", left, "*", name_n, right, term.is_negated)
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


func `∨`*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_WEDGE.anti, A, B) {.noinit.} =
  ## Multiply through exterior antiproduct, i.e. 𝐦 ∨ 𝐧; result holds exactly bases reached.
  defineProduct(CAYLEYS_WEDGE.anti, A, B)


func `⟑`*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_WEDGE_DOT.base, A, B) {.noinit.} =
  ## Multiply through geometric product, i.e. 𝐦 ⟑ 𝐧; result holds exactly bases reached.
  defineProduct(CAYLEYS_WEDGE_DOT.base, A, B)


func `⟇`*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_WEDGE_DOT.anti, A, B) {.noinit.} =
  ## Multiply through geometric antiproduct, i.e. 𝐦 ⟇ 𝐧; result holds exactly bases reached.
  defineProduct(CAYLEYS_WEDGE_DOT.anti, A, B)


func `∙`*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_DOT.base, A, B) {.noinit.} =
  ## Multiply through inner product, i.e. 𝐦 ∙ 𝐧; result holds scalar coefficient alone.
  defineProduct(CAYLEYS_DOT.base, A, B)


func `∘`*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_DOT.anti, A, B) {.noinit.} =
  ## Multiply through inner antiproduct, i.e. 𝐦 ∘ 𝐧; result holds antiscalar coefficient alone.
  defineProduct(CAYLEYS_DOT.anti, A, B)


func `∧★`*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_INTERIOR.base.bulk.right, A, B) {.noinit.} =
  ## Multiply through right bulk expansion, i.e. 𝐦 ∧ 𝐧★; result holds exactly bases reached.
  defineProduct(CAYLEYS_INTERIOR.base.bulk.right, A, B)


func `∧☆`*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_INTERIOR.base.weight.right, A, B) {.noinit.} =
  ## Multiply through right weight expansion, i.e. 𝐦 ∧ 𝐧☆; result holds exactly bases reached.
  defineProduct(CAYLEYS_INTERIOR.base.weight.right, A, B)


func `∨★`*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_INTERIOR.anti.bulk.right, A, B) {.noinit.} =
  ## Multiply through right bulk contraction, i.e. 𝐦 ∨ 𝐧★; result holds exactly bases reached.
  defineProduct(CAYLEYS_INTERIOR.anti.bulk.right, A, B)


func `∨☆`*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_INTERIOR.anti.weight.right, A, B) {.noinit.} =
  ## Multiply through right weight contraction, i.e. 𝐦 ∨ 𝐧☆; result holds exactly bases reached.
  defineProduct(CAYLEYS_INTERIOR.anti.weight.right, A, B)



#[ Parts ]#

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


when IS_CONFORMAL:
  func `■`*[A: static Bases](
    m: MultivectorOf[A],
  ): typeReached(CAYLEYS_PARTS.bulk.flat, A) {.noinit.} =
    ## Extract flat bulk, i.e. 𝐦■; result holds exactly flat bulk bases of operand's type.
    defineMap(CAYLEYS_PARTS.bulk.flat, A)


  func `□`*[A: static Bases](
    m: MultivectorOf[A],
  ): typeReached(CAYLEYS_PARTS.weight.flat, A) {.noinit.} =
    ## Extract flat weight, i.e. 𝐦□; result holds exactly flat weight bases of operand's type.
    defineMap(CAYLEYS_PARTS.weight.flat, A)



#[ Maps ]#

func `/`*[A: static Bases](
  m: MultivectorOf[A],
): typeReached(CAYLEYS_COMPLEMENT.right, A) {.noinit.} =
  ## Get right complement, i.e. 𝐦̅; result holds complement of each basis of operand's type.
  defineMap(CAYLEYS_COMPLEMENT.right, A)


func `\`*[A: static Bases](
  m: MultivectorOf[A],
): typeReached(CAYLEYS_COMPLEMENT.left, A) {.noinit.} =
  ## Get left complement, i.e. 𝐦̲; result holds complement of each basis of operand's type.
  defineMap(CAYLEYS_COMPLEMENT.left, A)


func `~`*[A: static Bases](
  m: MultivectorOf[A],
): typeReached(CAYLEYS_REVERSE.base, A) {.noinit.} =
  ## Get reverse, i.e. 𝐦̃; result holds bases of operand's type.
  defineMap(CAYLEYS_REVERSE.base, A)


func `~∘`*[A: static Bases](
  m: MultivectorOf[A],
): typeReached(CAYLEYS_REVERSE.anti, A) {.noinit.} =
  ## Get antireverse, i.e. 𝐦̰; result holds bases of operand's type.
  defineMap(CAYLEYS_REVERSE.anti, A)


func `★`*[A: static Bases](
  m: MultivectorOf[A],
): typeReached(CAYLEYS_DUAL.base.right, A) {.noinit.} =
  ## Get right dual of bulk, i.e. 𝐦★; result holds exactly bases reached.
  defineMap(CAYLEYS_DUAL.base.right, A)


func `☆`*[A: static Bases](
  m: MultivectorOf[A],
): typeReached(CAYLEYS_DUAL.anti.right, A) {.noinit.} =
  ## Get right dual of weight, i.e. 𝐦☆; result holds exactly bases reached.
  defineMap(CAYLEYS_DUAL.anti.right, A)


func `⊖`*[A: static Bases](
  m: MultivectorOf[A],
): typeReached(CAYLEY_ATTITUDE, A) {.noinit.} =
  ## Get attitude, i.e. ⊖𝐦 = 𝐦 ∨ 𝐞̄ₙ; result holds exactly bases reached.
  defineMap(CAYLEY_ATTITUDE, A)


when IS_CONFORMAL:
  func `⊟`*[A: static Bases](
    m: MultivectorOf[A],
  ): typeReached(CAYLEY_CARRIER, A) {.noinit.} =
    ## Get carrier, i.e. 𝐦 ∧ 𝐞ₙ; result holds exactly bases reached.
    defineMap(CAYLEY_CARRIER, A)



#[ Squared Norms ]#

func `|∙²`*[A: static Bases](
  m: MultivectorOf[A],
): typeReached(CAYLEYS_NORM_SQUARED.bulk.round, A, A) {.noinit.} =
  ## Get (round) bulk squared norm, i.e. ‖𝐦‖∙² = 𝐦 ∙ 𝐦; result holds scalar coefficient alone.
  defineProduct(CAYLEYS_NORM_SQUARED.bulk.round, A, A, as_unary = true)


func `|∘²`*[A: static Bases](
  m: MultivectorOf[A],
): typeReached(CAYLEYS_NORM_SQUARED.weight.round, A, A) {.noinit.} =
  ## Get (round) weight squared norm, i.e. ‖𝐦‖∘² = 𝐦 ∘ 𝐦; result holds antiscalar alone.
  defineProduct(CAYLEYS_NORM_SQUARED.weight.round, A, A, as_unary = true)


when IS_CONFORMAL:
  func `|■²`*[A: static Bases](
    m: MultivectorOf[A],
  ): typeReached(CAYLEYS_NORM_SQUARED.bulk.flat, A, A) {.noinit.} =
    ## Get flat bulk squared norm; result holds scalar coefficient alone.
    defineProduct(CAYLEYS_NORM_SQUARED.bulk.flat, A, A, as_unary = true)


  func `|□²`*[A: static Bases](
    m: MultivectorOf[A],
  ): typeReached(CAYLEYS_NORM_SQUARED.weight.flat, A, A) {.noinit.} =
    ## Get flat weight squared norm; result holds antiscalar coefficient alone.
    defineProduct(CAYLEYS_NORM_SQUARED.weight.flat, A, A, as_unary = true)


  func `|⊘²`*[A: static Bases](
    m: MultivectorOf[A],
  ): typeReached(CAYLEYS_NORM_SQUARED_RADIUS, A, A) {.noinit.} =
    ## Get squared radius norm, i.e. ‖𝐦‖⊘² = 𝐦 ∘ 𝐦; result holds antiscalar coefficient alone.
    defineProduct(CAYLEYS_NORM_SQUARED_RADIUS, A, A, as_unary = true)
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
  func bulkFlat*(m: Multivector): Multivector {.inline.} = ■m
    ## Extract flat bulk of multivector.
    ##   Bulk contains object's position.
```

```nim
  func bulkFlat*(m: Multivector): Multivector {.inline.} = ■m
    ## Extract flat bulk of multivector.
    ##   Bulk contains object's position.

  func bulkFlat*[A: static Bases](
    m: MultivectorOf[A],
  ): typeReached(CAYLEYS_PARTS.bulk.flat, A) {.inline.} = ■m
    ## Extract flat bulk of basis-set type, into exact basis-set type reached.
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
  func weightFlat*(m: Multivector): Multivector {.inline.} = □m
    ## Extract flat weight of multivector.
    ##   Weight contains object's attitude and orientation.
```

```nim
  func weightFlat*(m: Multivector): Multivector {.inline.} = □m
    ## Extract flat weight of multivector.
    ##   Weight contains object's attitude and orientation.

  func weightFlat*[A: static Bases](
    m: MultivectorOf[A],
  ): typeReached(CAYLEYS_PARTS.weight.flat, A) {.inline.} = □m
    ## Extract flat weight of basis-set type, into exact basis-set type reached.
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
func attitude*(m: Multivector): Multivector {.inline.} = ⊖m
  ## Get attitude of multivector as intersection with horizon.
```

```nim
func attitude*(m: Multivector): Multivector {.inline.} = ⊖m
  ## Get attitude of multivector as intersection with horizon.

func attitude*[A: static Bases](
  m: MultivectorOf[A],
): typeReached(CAYLEY_ATTITUDE, A) {.inline.} = ⊖m
  ## Get attitude of basis-set type, into exact basis-set type reached.
```

## Edit `pga.nim`

```nim
  func carrier*(m: Multivector): Multivector {.inline.} = ⊟m
    ## Get carrier of multivector as lowest dimensional flat object containing it, i.e. 𝐦 ∧ eₙ.
    ##   Has effect of annihilating flat part of multivector as eₙ ∧ eₙ = 0,
    ##   Also add eₙ to each round component, making it flat geometry.
    ##   Carrrier contains center of original multivector.
```

```nim
  func carrier*(m: Multivector): Multivector {.inline.} = ⊟m
    ## Get carrier of multivector as lowest dimensional flat object containing it, i.e. 𝐦 ∧ eₙ.
    ##   Has effect of annihilating flat part of multivector as eₙ ∧ eₙ = 0,
    ##   Also add eₙ to each round component, making it flat geometry.
    ##   Carrrier contains center of original multivector.

  func carrier*[A: static Bases](
    m: MultivectorOf[A],
  ): typeReached(CAYLEY_CARRIER, A) {.inline.} = ⊟m
    ## Get carrier of basis-set type, into exact basis-set type reached.
```

## Edit `pga.nim`

```nim
func complementLeft*(m: Multivector): Multivector {.inline.} = \m
  ## Get left complement of multivector.

func complementRight*(m: Multivector): Multivector {.inline.} = /m
  ## Get right complement of multivector.

func dualBulk*(m: Multivector): Multivector {.inline.} = ★m
  ## Get right dual of multivector's bulk components.

func dualWeight*(m: Multivector): Multivector {.inline.} = ☆m
  ## Get right dual of multivector's weight components.
```

```nim
func complementLeft*(m: Multivector): Multivector {.inline.} = \m
  ## Get left complement of multivector.

func complementLeft*[A: static Bases](
  m: MultivectorOf[A],
): typeReached(CAYLEYS_COMPLEMENT.left, A) {.inline.} = \m
  ## Get left complement of basis-set type, into exact basis-set type reached.

func complementRight*(m: Multivector): Multivector {.inline.} = /m
  ## Get right complement of multivector.

func complementRight*[A: static Bases](
  m: MultivectorOf[A],
): typeReached(CAYLEYS_COMPLEMENT.right, A) {.inline.} = /m
  ## Get right complement of basis-set type, into exact basis-set type reached.

func dualBulk*(m: Multivector): Multivector {.inline.} = ★m
  ## Get right dual of multivector's bulk components.

func dualBulk*[A: static Bases](
  m: MultivectorOf[A],
): typeReached(CAYLEYS_DUAL.base.right, A) {.inline.} = ★m
  ## Get right dual of bulk of basis-set type, into exact basis-set type reached.

func dualWeight*(m: Multivector): Multivector {.inline.} = ☆m
  ## Get right dual of multivector's weight components.

func dualWeight*[A: static Bases](
  m: MultivectorOf[A],
): typeReached(CAYLEYS_DUAL.anti.right, A) {.inline.} = ☆m
  ## Get right dual of weight of basis-set type, into exact basis-set type reached.
```

## Edit `pga.nim`

```nim
func reverse*(m: Multivector): Multivector {.inline.} = ~m
  ## Reverse multivector.
  ##   I.e. rearrange vector element factors so they wedge in reverse order.

func reverseAnti*(m: Multivector): Multivector {.inline.} = ~∘m
  ## Reverse complement of multivector.
  ##   I.e. rearrange antivector element factors so they antiwedge in reverse order.
```

```nim
func reverse*(m: Multivector): Multivector {.inline.} = ~m
  ## Reverse multivector.
  ##   I.e. rearrange vector element factors so they wedge in reverse order.

func reverse*[A: static Bases](
  m: MultivectorOf[A],
): typeReached(CAYLEYS_REVERSE.base, A) {.inline.} = ~m
  ## Reverse basis-set type, into same basis-set type.

func reverseAnti*(m: Multivector): Multivector {.inline.} = ~∘m
  ## Reverse complement of multivector.
  ##   I.e. rearrange antivector element factors so they antiwedge in reverse order.

func reverseAnti*[A: static Bases](
  m: MultivectorOf[A],
): typeReached(CAYLEYS_REVERSE.anti, A) {.inline.} = ~∘m
  ## Get antireverse of basis-set type, into same basis-set type.
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
func wedgeAnti*(m: Multivector, n: Multivector): Multivector {.inline.} = m ∨ n
  ## Multiply multivectors by combining jointly abscent dimensions.
  ##   I.e. multiply through exterior antiproduct.
  ##   Also called meet operation, analogous to intersection.

func wedgeDot*(m, n: Multivector): Multivector {.inline.} = m ⟑ n
  ## Multiply multivectors through geometric product.
  ##   Incorporates wedge product, adding information.
```

```nim
func wedgeAnti*(m: Multivector, n: Multivector): Multivector {.inline.} = m ∨ n
  ## Multiply multivectors by combining jointly abscent dimensions.
  ##   I.e. multiply through exterior antiproduct.
  ##   Also called meet operation, analogous to intersection.

func wedgeAnti*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_WEDGE.anti, A, B) {.inline.} = m ∨ n
  ## Multiply basis-set types through exterior antiproduct, into exact basis-set type reached.

func wedgeDot*(m, n: Multivector): Multivector {.inline.} = m ⟑ n
  ## Multiply multivectors through geometric product.
  ##   Incorporates wedge product, adding information.

func wedgeDot*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_WEDGE_DOT.base, A, B) {.inline.} = m ⟑ n
  ## Multiply basis-set types through geometric product, into exact basis-set type reached.
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

## Edit `pga.nim`

```nim
func contractBulk*(m, n: Multivector): Multivector {.inline.} = m ∨★ n
  ## Multiply multivectors through right inner product bulk contraction, i.e. 𝐦 ∨ 𝐧★.

func contractWeight*(m, n: Multivector): Multivector {.inline.} = m ∨☆ n
  ## Multiply multivectors through right inner product weight contraction, i.e. 𝐦 ∨ 𝐧☆.

func expandBulk*(m, n: Multivector): Multivector {.inline.} = m ∧★ n
  ## Multiply multivectors through right inner product bulk expansion, i.e. 𝐦 ∧ 𝐧★.

func expandWeight*(m, n: Multivector): Multivector {.inline.} = m ∧☆ n
  ## Multiply multivectors through right inner product weight expansion, i.e. 𝐦 ∧ 𝐧☆.
```

```nim
func contractBulk*(m, n: Multivector): Multivector {.inline.} = m ∨★ n
  ## Multiply multivectors through right inner product bulk contraction, i.e. 𝐦 ∨ 𝐧★.

func contractBulk*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_INTERIOR.anti.bulk.right, A, B) {.inline.} = m ∨★ n
  ## Multiply basis-set types through right bulk contraction, into exact basis-set type reached.

func contractWeight*(m, n: Multivector): Multivector {.inline.} = m ∨☆ n
  ## Multiply multivectors through right inner product weight contraction, i.e. 𝐦 ∨ 𝐧☆.

func contractWeight*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_INTERIOR.anti.weight.right, A, B) {.inline.} = m ∨☆ n
  ## Multiply basis-set types through right weight contraction, into exact basis-set type reached.

func expandBulk*(m, n: Multivector): Multivector {.inline.} = m ∧★ n
  ## Multiply multivectors through right inner product bulk expansion, i.e. 𝐦 ∧ 𝐧★.

func expandBulk*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_INTERIOR.base.bulk.right, A, B) {.inline.} = m ∧★ n
  ## Multiply basis-set types through right bulk expansion, into exact basis-set type reached.

func expandWeight*(m, n: Multivector): Multivector {.inline.} = m ∧☆ n
  ## Multiply multivectors through right inner product weight expansion, i.e. 𝐦 ∧ 𝐧☆.

func expandWeight*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_INTERIOR.base.weight.right, A, B) {.inline.} = m ∧☆ n
  ## Multiply basis-set types through right weight expansion, into exact basis-set type reached.
```
