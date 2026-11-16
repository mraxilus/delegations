# Products of basis-set types, which return exactly the bases they reach

At pin, `MultivectorOf[B]` holds the coefficients of any set of bases, and the library names one
alias for each grade and each parity. Each operator still takes and returns a whole `Multivector`.
This change adds a module, `pga/basis_sets.nim`, with a form of basis-set types for each operator
that the library builds from one table. Each form returns the exact set of bases that its table
reaches. `pga.nim` exports the module, and gives each generic form its named alias beside the
alias on `Multivector`.

Each basis-set type also aligns to `alignment` of its count of coefficients. That is the largest
power of two that divides their bytes, and at most one cache line, so it pads none. The `when` of
`MultivectorOf` chooses among 8, 16, 32 and 64, so a 32-bit build follows the same rule.

Nim reads the set of a generic type as it is spelled, so `{Basis.E1..Basis.E4}` and the four bases
listed are two types. Each alias of pin lists its bases, and `Multivector` spells the range of all
bases. So `typeReached` lists the bases it reaches, and names `Multivector` where it reaches all.
A reverse keeps each basis, so `~` and `~∘` return `MultivectorOf[A]`, the type of the operand.
A form that reaches no basis stops the compile, since `MultivectorOf` of an empty set stops the
compiler at pin.

`pga/basis_sets.nim` and `pga.nim` enable `openSym`. Without it, each use of a form of two
operands prints the warning `IgnoredSymbolInjection`, which the library at pin does not print.

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

const ALIGNMENT_MAX = 64  # Cap alignment at bytes of one cache line.


func alignment(count: int): int =
  ## Get alignment of `count` coefficients: largest power of two dividing their bytes, at most
  ##   one line. Alignment divides size, so it pads no count; empty set keeps that of coefficient.
  let size = sizeof(Coefficient) * count
  max(sizeof(Coefficient), min(ALIGNMENT_MAX, size and -size))


type
  Bases* = set[Basis]  ## TODO: Make distinct.
  MultivectorOf*[B: static Bases] = object
    ## Align to `alignment` of count through `when`, as Nim rejects `align` of `B`.
    when alignment(B.card) == 64:
      elements {.align(64).}: array[B.card, Coefficient]
    elif alignment(B.card) == 32:
      elements {.align(32).}: array[B.card, Coefficient]
    elif alignment(B.card) == 16:
      elements {.align(16).}: array[B.card, Coefficient]
    elif alignment(B.card) == 8:
      elements {.align(8).}: array[B.card, Coefficient]
    else:
      elements: array[B.card, Coefficient]
```

## Add `pga/basis_sets.nim`

```nim
## Define forms of multivector subtypes for each operator library builds from one table.
##   Form reads library's whole table over bases of its operands alone, and returns exact
##     `MultivectorOf` of bases it reaches. So dot is one coefficient, and bulk of bivector is
##     part of its grade. Tables stay whole, so their count grows with no type.
##   Result spells its set as aliases spell theirs, so it is their type: Nim tells sets apart by
##     spelling, and `{Basis.E1..Basis.E4}` is not `Multivector1`.
##   Reverse and antireverse keep each basis, so they return subtype of operand.
##   Squared norm reads its table with operand on both sides, as library's `as_unary` does.
##
## Cost: forms stay generic, since one body per pair of types makes some 6 000 at cga5d;
##   each instance takes whole table as static argument, compile time unmeasured.
## Cost: operator library builds from no table stays on `Multivector`, as norms, `unitize`,
##   supports and `-` do; caller widens first.
## Cost: form that reaches no basis stops compile, as bulk dual of antiscalar under rigid
##   metric does; widened call gives zero there.
## Cost: reach is what table can produce, not what algebra guarantees; sandwich of vector
##   returns `MultivectorOdd`, though its value lies in grade 1.
##

{.experimental: "openSym".}
{.experimental: "strictFuncs".}

import std/macros

import ./[algebra, cayleys, emitters, multivectors]



#[ Emission ]#

func emitWrites(sums: array[Basis, seq[NimNode]]): NimNode {.compileTime.} =
  ## Emit write of each reached coefficient once; every coefficient of exact subtype is reached,
  ##   so none fills.

  func emitSum(terms: seq[NimNode]): NimNode =
    ## Emit sum of terms, left to right.
    result = terms[0]
    for term in terms[1 .. ^1]: result = infix(result, "+", term)

  result = newStmtList()
  for b in Basis:
    if sums[b].len != 0:
      result.add newAssignment(emitSubscript("result", b), emitSum(sums[b]))


func emitReached(reached: Bases): NimNode {.compileTime.} =
  ## Spell type of reached bases as aliases spell theirs: `Multivector` for all, else each listed.
  ##   Form that reaches no basis is zero for any operand, and Nim instantiates no `MultivectorOf`
  ##     of empty set; so it stops compile.
  if reached.card == 0: error("Form must reach a basis; this one is zero for any operand.")
  if reached == {Basis.scalar..Basis.scalarAnti}: ident"Multivector"
  else: emitMultivectorOf(reached)


macro typeReached*(cayley: static Cayley1D, bases_m: static Bases): untyped =
  ## Spell subtype map reaches, so it is same type as any alias.
  var reached: Bases
  for b in bases_m:
    for term in cayley[b]: reached.incl term.basis
  emitReached(reached)


macro typeReached*(cayley: static Cayley2D; bases_m, bases_n: static Bases): untyped =
  ## Spell subtype product reaches, so it is same type as any alias.
  var reached: Bases
  for left in bases_m:
    for right in bases_n:
      for term in cayley[left][right]: reached.incl term.basis
  emitReached(reached)


macro defineForm(cayley: static Cayley1D, bases_m: static Bases): untyped =
  ## Define map over operand's bases alone, into result of exact subtype.
  var sums: array[Basis, seq[NimNode]]
  for b in bases_m:
    for term in cayley[b]:
      let read = emitSubscript("m", b)
      sums[term.basis].add(if term.is_negated: prefix(read, "-") else: read)
  emitWrites(sums)


macro defineForm(
  cayley: static Cayley2D; bases_m, bases_n: static Bases; as_unary: static bool = false
): untyped =
  ## Define product over operands' bases alone, into result of exact subtype.
  ##   Unary product reads 𝐦 on both sides, as library's squared norms do.
  let name_n = if as_unary: "m" else: "n"
  var sums: array[Basis, seq[NimNode]]
  for left in bases_m:
    for right in bases_n:
      for term in cayley[left][right]:
        sums[term.basis].add emitTerm("m", left, "*", name_n, right, term.is_negated)
  emitWrites(sums)



#[ Products ]#

func `∧`*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_WEDGE.base, A, B) {.inline, noinit.} =
  ## Multiply multivectors through exterior product, i.e. 𝐦 ∧ 𝐧.
  ##   Result holds exactly bases reached.
  defineForm(CAYLEYS_WEDGE.base, A, B)


func `∨`*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_WEDGE.anti, A, B) {.inline, noinit.} =
  ## Multiply multivectors through exterior antiproduct, i.e. 𝐦 ∨ 𝐧.
  ##   Result holds exactly bases reached.
  defineForm(CAYLEYS_WEDGE.anti, A, B)


func `⟑`*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_WEDGE_DOT.base, A, B) {.inline, noinit.} =
  ## Multiply multivectors through geometric product, i.e. 𝐦 ⟑ 𝐧.
  ##   Result holds exactly bases reached.
  defineForm(CAYLEYS_WEDGE_DOT.base, A, B)


func `⟇`*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_WEDGE_DOT.anti, A, B) {.inline, noinit.} =
  ## Multiply multivectors through geometric antiproduct, i.e. 𝐦 ⟇ 𝐧.
  ##   Result holds exactly bases reached.
  defineForm(CAYLEYS_WEDGE_DOT.anti, A, B)


func `∙`*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_DOT.base, A, B) {.inline, noinit.} =
  ## Multiply multivectors through inner product, i.e. 𝐦∙𝐧 = (𝐦ᵀ𝐆𝐧)𝟏.
  ##   Result holds scalar coefficient alone.
  defineForm(CAYLEYS_DOT.base, A, B)


func `∘`*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_DOT.anti, A, B) {.inline, noinit.} =
  ## Multiply multivectors through inner antiproduct, i.e. 𝐦∘𝐧 = (𝐦ᵀ𝔾𝐧)𝟙.
  ##   Result holds antiscalar coefficient alone.
  defineForm(CAYLEYS_DOT.anti, A, B)


func `∧★`*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_INTERIOR.base.bulk.right, A, B) {.inline, noinit.} =
  ## Multiply multivectors through right inner product bulk expansion, i.e. 𝐦 ∧ 𝐧★.
  ##   Result holds exactly bases reached.
  defineForm(CAYLEYS_INTERIOR.base.bulk.right, A, B)


func `∧☆`*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_INTERIOR.base.weight.right, A, B) {.inline, noinit.} =
  ## Multiply multivectors through right interior product expansion, i.e. 𝐦 ∧ 𝐧☆.
  ##   Result holds exactly bases reached.
  defineForm(CAYLEYS_INTERIOR.base.weight.right, A, B)


func `∨★`*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_INTERIOR.anti.bulk.right, A, B) {.inline, noinit.} =
  ## Multiply multivectors through right interior product contraction, i.e. 𝐦 ∨ 𝐧★.
  ##   Result holds exactly bases reached.
  defineForm(CAYLEYS_INTERIOR.anti.bulk.right, A, B)


func `∨☆`*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_INTERIOR.anti.weight.right, A, B) {.inline, noinit.} =
  ## Multiply multivectors through right inner product weight contraction, i.e. 𝐦 ∨ 𝐧☆.
  ##   Result holds exactly bases reached.
  defineForm(CAYLEYS_INTERIOR.anti.weight.right, A, B)



#[ Parts ]#

func `∙`*[A: static Bases](
  m: MultivectorOf[A],
): typeReached(CAYLEYS_PARTS.bulk.round, A) {.inline, noinit.} =
  ## Extract (round) bulk of multivector, i.e. 𝐦∙.
  ##   Result holds exactly bulk bases of operand's subtype.
  defineForm(CAYLEYS_PARTS.bulk.round, A)


func `∘`*[A: static Bases](
  m: MultivectorOf[A],
): typeReached(CAYLEYS_PARTS.weight.round, A) {.inline, noinit.} =
  ## Extract (round) weight of multivector, i.e. 𝐦∘.
  ##   Result holds exactly weight bases of operand's subtype.
  defineForm(CAYLEYS_PARTS.weight.round, A)


when IS_CONFORMAL:
  func `■`*[A: static Bases](
    m: MultivectorOf[A],
  ): typeReached(CAYLEYS_PARTS.bulk.flat, A) {.inline, noinit.} =
    ## Extract flat bulk of multivector, i.e. 𝐦■.
    ##   Result holds exactly flat bulk bases of operand's subtype.
    defineForm(CAYLEYS_PARTS.bulk.flat, A)


  func `□`*[A: static Bases](
    m: MultivectorOf[A],
  ): typeReached(CAYLEYS_PARTS.weight.flat, A) {.inline, noinit.} =
    ## Extract flat weight of multivector, i.e. 𝐦□.
    ##   Result holds exactly flat weight bases of operand's subtype.
    defineForm(CAYLEYS_PARTS.weight.flat, A)



#[ Maps ]#

func `/`*[A: static Bases](
  m: MultivectorOf[A],
): typeReached(CAYLEYS_COMPLEMENT.right, A) {.inline, noinit.} =
  ## Get right complement of multivector, i.e. 𝐦̅.
  ##   Result holds complement of each basis of operand's subtype.
  defineForm(CAYLEYS_COMPLEMENT.right, A)


func `\`*[A: static Bases](
  m: MultivectorOf[A],
): typeReached(CAYLEYS_COMPLEMENT.left, A) {.inline, noinit.} =
  ## Get left complement of multivector, i.e. 𝐦̲.
  ##   Result holds complement of each basis of operand's subtype.
  defineForm(CAYLEYS_COMPLEMENT.left, A)


func `~`*[A: static Bases](
  m: MultivectorOf[A],
): MultivectorOf[A] {.inline, noinit.} =
  ## Get reverse of multivector, i.e. 𝐦̃.
  ##   Result keeps operand's subtype.
  defineForm(CAYLEYS_REVERSE.base, A)


func `~∘`*[A: static Bases](
  m: MultivectorOf[A],
): MultivectorOf[A] {.inline, noinit.} =
  ## Get antireverse of multivector, i.e. 𝐦̰.
  ##   Result keeps operand's subtype.
  defineForm(CAYLEYS_REVERSE.anti, A)


func `★`*[A: static Bases](
  m: MultivectorOf[A],
): typeReached(CAYLEYS_DUAL.base.right, A) {.inline, noinit.} =
  ## Get right dual of multivector's bulk components, i.e. 𝐦★.
  ##   Result holds exactly bases reached.
  defineForm(CAYLEYS_DUAL.base.right, A)


func `☆`*[A: static Bases](
  m: MultivectorOf[A],
): typeReached(CAYLEYS_DUAL.anti.right, A) {.inline, noinit.} =
  ## Get right dual of multivector's weight components, i.e. 𝐦☆.
  ##   Result holds exactly bases reached.
  defineForm(CAYLEYS_DUAL.anti.right, A)


func `⊖`*[A: static Bases](
  m: MultivectorOf[A],
): typeReached(CAYLEY_ATTITUDE, A) {.inline, noinit.} =
  ## Get attitude of multivector, i.e. ⊖𝐦 = 𝐦 ∨ 𝐞̄ₙ.
  ##   Result holds exactly bases reached.
  defineForm(CAYLEY_ATTITUDE, A)


when IS_CONFORMAL:
  func `⊟`*[A: static Bases](
    m: MultivectorOf[A],
  ): typeReached(CAYLEY_CARRIER, A) {.inline, noinit.} =
    ## Get carrier of multivector, i.e. 𝐦 ∧ 𝐞ₙ.
    ##   Result holds exactly bases reached.
    defineForm(CAYLEY_CARRIER, A)



#[ Squared Norms ]#

func `|∙²`*[A: static Bases](
  m: MultivectorOf[A],
): typeReached(CAYLEYS_NORM_SQUARED.bulk.round, A, A) {.inline, noinit.} =
  ## Get (round) bulk squared norm of multivector.
  ##   Result holds scalar coefficient alone.
  defineForm(CAYLEYS_NORM_SQUARED.bulk.round, A, A, as_unary = true)


func `|∘²`*[A: static Bases](
  m: MultivectorOf[A],
): typeReached(CAYLEYS_NORM_SQUARED.weight.round, A, A) {.inline, noinit.} =
  ## Get (round) weight squared norm of multivector.
  ##   Result holds antiscalar coefficient alone.
  defineForm(CAYLEYS_NORM_SQUARED.weight.round, A, A, as_unary = true)


when IS_CONFORMAL:
  func `|■²`*[A: static Bases](
    m: MultivectorOf[A],
  ): typeReached(CAYLEYS_NORM_SQUARED.bulk.flat, A, A) {.inline, noinit.} =
    ## Get flat bulk squared norm of multivector.
    ##   Result holds scalar coefficient alone.
    defineForm(CAYLEYS_NORM_SQUARED.bulk.flat, A, A, as_unary = true)


  func `|□²`*[A: static Bases](
    m: MultivectorOf[A],
  ): typeReached(CAYLEYS_NORM_SQUARED.weight.flat, A, A) {.inline, noinit.} =
    ## Get flat weight squared norm of multivector.
    ##   Result holds antiscalar coefficient alone.
    defineForm(CAYLEYS_NORM_SQUARED.weight.flat, A, A, as_unary = true)


  func `|⊘²`*[A: static Bases](
    m: MultivectorOf[A],
  ): typeReached(CAYLEYS_NORM_SQUARED_RADIUS, A, A) {.inline, noinit.} =
    ## Get squared radius norm of multivector, i.e. ‖𝐦‖⊘² = 𝐦∘𝐦.
    ##   Result holds antiscalar coefficient alone.
    defineForm(CAYLEYS_NORM_SQUARED_RADIUS, A, A, as_unary = true)
```

## Edit `pga.nim`

```nim
{.experimental: "strictFuncs".}
```

```nim
{.experimental: "openSym".}
{.experimental: "strictFuncs".}
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
  func bulk*(m: Multivector): Multivector {.inline.} = ∙m
    ## Extract bulk of multivector.
    ##   Bulk contains object's position.

  func weight*(m: Multivector): Multivector {.inline.} = ∘m
    ## Extract weight of multivector.
    ##   Weight contains object's attitude and orientation.
    ##   Where weight is 0, object is contained by (N-1)D object at infinity.
```

```nim
  func bulk*(m: Multivector): Multivector {.inline.} = ∙m
    ## Extract bulk of multivector.
    ##   Bulk contains object's position.

  func bulk*[A: static Bases](
    m: MultivectorOf[A],
  ): typeReached(CAYLEYS_PARTS.bulk.round, A) {.inline.} = ∙m
    ## Extract bulk of multivector subtype, into exact subtype reached.

  func weight*(m: Multivector): Multivector {.inline.} = ∘m
    ## Extract weight of multivector.
    ##   Weight contains object's attitude and orientation.
    ##   Where weight is 0, object is contained by (N-1)D object at infinity.

  func weight*[A: static Bases](
    m: MultivectorOf[A],
  ): typeReached(CAYLEYS_PARTS.weight.round, A) {.inline.} = ∘m
    ## Extract weight of multivector subtype, into exact subtype reached.
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
    ## Extract flat bulk of multivector subtype, into exact subtype reached.
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
    ## Extract round bulk of multivector subtype, into exact subtype reached.
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
    ## Extract flat weight of multivector subtype, into exact subtype reached.
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
    ## Extract round weight of multivector subtype, into exact subtype reached.
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
  ## Get attitude of multivector subtype, into exact subtype reached.
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
    ## Get carrier of multivector subtype, into exact subtype reached.
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
  ## Get left complement of multivector subtype, into exact subtype reached.

func complementRight*(m: Multivector): Multivector {.inline.} = /m
  ## Get right complement of multivector.

func complementRight*[A: static Bases](
  m: MultivectorOf[A],
): typeReached(CAYLEYS_COMPLEMENT.right, A) {.inline.} = /m
  ## Get right complement of multivector subtype, into exact subtype reached.

func dualBulk*(m: Multivector): Multivector {.inline.} = ★m
  ## Get right dual of multivector's bulk components.

func dualBulk*[A: static Bases](
  m: MultivectorOf[A],
): typeReached(CAYLEYS_DUAL.base.right, A) {.inline.} = ★m
  ## Get right dual of bulk of multivector subtype, into exact subtype reached.

func dualWeight*(m: Multivector): Multivector {.inline.} = ☆m
  ## Get right dual of multivector's weight components.

func dualWeight*[A: static Bases](
  m: MultivectorOf[A],
): typeReached(CAYLEYS_DUAL.anti.right, A) {.inline.} = ☆m
  ## Get right dual of weight of multivector subtype, into exact subtype reached.
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

func reverse*[A: static Bases](m: MultivectorOf[A]): MultivectorOf[A] {.inline.} = ~m
  ## Reverse multivector subtype, into same subtype.

func reverseAnti*(m: Multivector): Multivector {.inline.} = ~∘m
  ## Reverse complement of multivector.
  ##   I.e. rearrange antivector element factors so they antiwedge in reverse order.

func reverseAnti*[A: static Bases](m: MultivectorOf[A]): MultivectorOf[A] {.inline.} = ~∘m
  ## Get antireverse of multivector subtype, into same subtype.
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
  ## Multiply multivector subtypes through inner product, into exact subtype reached.
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
  ## Multiply multivector subtypes through inner antiproduct, into exact subtype reached.
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
  ## Multiply multivector subtypes through exterior product, into exact subtype reached.
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
  ## Multiply multivector subtypes through exterior antiproduct, into exact subtype reached.

func wedgeDot*(m, n: Multivector): Multivector {.inline.} = m ⟑ n
  ## Multiply multivectors through geometric product.
  ##   Incorporates wedge product, adding information.

func wedgeDot*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_WEDGE_DOT.base, A, B) {.inline.} = m ⟑ n
  ## Multiply multivector subtypes through geometric product, into exact subtype reached.
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
  ## Multiply multivector subtypes through geometric antiproduct, into exact subtype reached.
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
  ## Multiply multivector subtypes through right bulk contraction, into exact subtype reached.

func contractWeight*(m, n: Multivector): Multivector {.inline.} = m ∨☆ n
  ## Multiply multivectors through right inner product weight contraction, i.e. 𝐦 ∨ 𝐧☆.

func contractWeight*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_INTERIOR.anti.weight.right, A, B) {.inline.} = m ∨☆ n
  ## Multiply multivector subtypes through right weight contraction, into exact subtype reached.

func expandBulk*(m, n: Multivector): Multivector {.inline.} = m ∧★ n
  ## Multiply multivectors through right inner product bulk expansion, i.e. 𝐦 ∧ 𝐧★.

func expandBulk*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_INTERIOR.base.bulk.right, A, B) {.inline.} = m ∧★ n
  ## Multiply multivector subtypes through right bulk expansion, into exact subtype reached.

func expandWeight*(m, n: Multivector): Multivector {.inline.} = m ∧☆ n
  ## Multiply multivectors through right inner product weight expansion, i.e. 𝐦 ∧ 𝐧☆.

func expandWeight*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_INTERIOR.base.weight.right, A, B) {.inline.} = m ∧☆ n
  ## Multiply multivector subtypes through right weight expansion, into exact subtype reached.
```
