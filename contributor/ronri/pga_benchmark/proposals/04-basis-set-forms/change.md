# Forms of basis-set types, which return exactly the bases they reach

At pin, `MultivectorOf[B]` holds the coefficients of any set of bases, and the library names one
alias for each grade and each parity. Each operator still takes and returns a whole `Multivector`.
This change gives each operator that the library builds from one table a form for any basis-set
types. Each form returns the exact set of bases that its table reaches, as the named type with
those bases where one exists. Scaling, the norms, unitizing, the supports and the conformal
operators built from others take any type too, through those forms.

The forms are the code of the patch of D1 of pga_visualiser, which the Architect ruled to take
(D51 b). Three private templates define each map, product and squared norm in one call each (D10
b), inside `pga/operators.nim` (D11 b). Each writes one assignment for each basis that its result
holds, at compile time, so no set is read at run time. Two whole multivectors still reach the
operators of pin, since Nim prefers a function that is not generic.

A form that reaches no basis returns the type of no bases, whose value converts to zero (D9 b).
`MultivectorOf` counts its bases through `Bases(B)`, and each loop over the set of a type skips an
empty one, so that type compiles. Each basis-set type aligns to `alignment` of its count of
coefficients: the largest power of two that divides their bytes, and at most 16 (D13 b). So no
count pads, and raw storage from `alloc` stays valid.

Each alias of `pga.nim` whose operator takes any type takes any type too, and returns `auto`
(D12 b). So an alias forwards to its operator over the same types, as III.2 asks. The selections
of a grade keep `Multivector`, and `normCenter` keeps its stop.

This change builds on P14, `typed-sums`: the forms name their result types through its
`zeroNamed`. Its tests stand in a new suite `Typed operators`, after the suite `Arithmetic` of
P14. Every edit quotes text of pin as P14 leaves it.

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

const ALIGNMENT_MAX = 16  # Cap alignment at bytes `alloc` gives, so raw storage stays valid.


func alignment(count: int): int =
  ## Get alignment of `count` coefficients: largest power of two dividing their bytes, at most
  ##   16. Alignment divides size, so it pads no count; empty set keeps that of coefficient.
  let size = sizeof(Coefficient) * count
  max(sizeof(Coefficient), min(ALIGNMENT_MAX, size and -size))


type
  Bases* = set[Basis]  ## TODO: Make distinct.
  MultivectorOf*[B: static Bases] = object
    ## Align to `alignment` of count through `when`, as Nim rejects `align` of `B`.
    ##   Count reads `Bases(B).card`: bare `B.card` of `{}` crashes compiler (firstOrd(tyEmpty)).
    when alignment(Bases(B).card) == 16:
      elements {.align(16).}: array[Bases(B).card, Coefficient]
    elif alignment(Bases(B).card) == 8:
      elements {.align(8).}: array[Bases(B).card, Coefficient]
    else:
      elements: array[Bases(B).card, Coefficient]
```

## Edit `pga/multivectors.nim`

```nim
func `=~`*[B: static Bases](m, n: MultivectorOf[B]): bool =
  ## Compare approximate equality between multivectors, i.e. 𝐦 ≈ 𝐧.
  for b in B:
    if not (m[b] =~ n[b]):
      return false
  true
```

```nim
func `=~`*[B: static Bases](m, n: MultivectorOf[B]): bool =
  ## Compare approximate equality between multivectors, i.e. 𝐦 ≈ 𝐧.
  when Bases(B).card > 0:  # Skip empty set: its `index` returns empty range, which Nim refuses.
    for b in B:
      if not (m[b] =~ n[b]):
        return false
  true
```

## Edit `pga/multivectors.nim`

```nim
func toMultivectorOf*[A, B: static Bases](m: MultivectorOf[A]): MultivectorOf[B] {.inline.} =
  ## Convert between compatible multivector forms.
  for b in A:
```

```nim
func toMultivectorOf*[A, B: static Bases](m: MultivectorOf[A]): MultivectorOf[B] {.inline.} =
  ## Convert between compatible multivector forms.
  when Bases(A).card > 0:  # Skip empty set: its `index` returns empty range, which Nim refuses.
    result = convertByBasis[A, B](m)


func convertByBasis[A, B: static Bases](m: MultivectorOf[A]): MultivectorOf[B] {.inline.} =
  ## Convert multivector of at least one basis between compatible forms, basis by basis.
  for b in A:
```

## Edit `pga/multivectors.nim`

```nim
    if b in B:
      result[b] = m[b]
```

```nim
    when Bases(B).card > 0:  # Skip empty set: its `index` returns empty range, which Nim refuses.
      if b in B:
        result[b] = m[b]
```

## Edit `pga/multivectors.nim`

```nim
func toMultivector*[B: static Bases](m: MultivectorOf[B]): Multivector {.inline.} =
  ## TODO: Define via macro.
  for b in B:
    result[b] = m[b]
```

```nim
func toMultivector*[B: static Bases](m: MultivectorOf[B]): Multivector {.inline.} =
  ## TODO: Define via macro.
  when Bases(B).card > 0:  # Skip empty set: its `index` returns empty range, which Nim refuses.
    for b in B:
      result[b] = m[b]
```

## Edit `pga/operators.nim`

```nim
  func `⊛`*(m: Multivector): Multivector =
    ## Get partner of multivector, i.e. (-1)^(grade(𝐦)+1) (𝐦☆)⊡ ∨ 𝐦⊟.
    let sign = Coefficient(-1^(int(m.grade.get) + 1))
    sign * ⊡(☆m) ∨ ⊟m
```

```nim
  func `⊛`*(m: Multivector): Multivector =
    ## Get partner of multivector, i.e. (-1)^(grade(𝐦)+1) (𝐦☆)⊡ ∨ 𝐦⊟.
    let sign = Coefficient(-1^(int(m.grade.get) + 1))
    sign * ⊡(☆m) ∨ ⊟m



#[ Typed Operators ]#

# Each operator above takes full multivectors. Each below takes multivectors of any types, and
#   returns type its Cayley table gives: bases that bases of its operands reach, and no more.
#   Named type holds result where one has those bases, through `zeroNamed`, as for `+`.
#   Written per basis at compile time, as `+` is, so no set is read at runtime.
#   Two full multivectors still reach full operators above, since Nim prefers them to generics.
#   Each sum keeps order of full operator, less terms whose operand bases are absent.
#     So each coefficient equals full operator's on same operands, exactly.

func basesMapped(cayley: Cayley1D, a: Bases): Bases {.compileTime.} =
  ## Choose bases that map `cayley` sends bases `a` to.
  for x in a:
    for destination in cayley[x]:
      result.incl(destination.basis)


func basesMultiplied(cayley: Cayley2D, a, b: Bases): Bases {.compileTime.} =
  ## Choose bases that product `cayley` sends pairs of bases from `a` and `b` to.
  for x in a:
    for y in b:
      for destination in cayley[x][y]:
        result.incl(destination.basis)


func emitSum(terms: seq[NimNode]): NimNode {.compileTime.} =
  ## Emit sum of terms in their order, or zero where there are none.
  if terms.len == 0:
    return newCall(ident"Coefficient", newLit(0))
  result = terms[0]
  for term in terms[1 .. ^1]:
    result = infix(result, "+", term)


func emitBasis(b: Basis): NimNode {.compileTime.} =
  ## Emit basis as constant, so each subscript reads constant index.
  newCall(ident"Basis", newLit(ord(b)))


macro emitMappedByBasis(cayley: static Cayley1D, R, A: static Bases, r, m: untyped): untyped =
  ## Emit one assignment per basis of `R`, summing each term that `cayley` sends there from `A`.
  var terms: array[Basis, seq[NimNode]]
  for x in A:
    for destination in cayley[x]:
      let
        b = emitBasis(x)
        term = quote do: `m`[`b`]
      terms[destination.basis].add(if destination.is_negated: prefix(term, "-") else: term)
  result = newStmtList()
  for basis in R:
    let
      b = emitBasis(basis)
      value = emitSum(terms[basis])
    result.add quote do:
      `r`[`b`] = `value`


macro emitMultipliedByBasis(
  cayley: static Cayley2D, R, A, B: static Bases, r, m, n: untyped
): untyped =
  ## Emit one assignment per basis of `R`, summing each term that `cayley` sends there.
  ##   Pairs run over bases of `A` from `m`, then over bases of `B` from `n`, as full operator's do.
  var terms: array[Basis, seq[NimNode]]
  for x in A:
    for y in B:
      for destination in cayley[x][y]:
        let
          bx = emitBasis(x)
          by = emitBasis(y)
          term = quote do: `m`[`bx`] * `n`[`by`]
        terms[destination.basis].add(if destination.is_negated: prefix(term, "-") else: term)
  result = newStmtList()
  for basis in R:
    let
      b = emitBasis(basis)
      value = emitSum(terms[basis])
    result.add quote do:
      `r`[`b`] = `value`


macro emitScaledByBasis(B: static Bases, r, s, m: untyped): untyped =
  ## Emit one product with scalar per basis of `B`, each at constant basis.
  result = newStmtList()
  for basis in B:
    let b = emitBasis(basis)
    result.add quote do:
      `r`[`b`] = `s` * `m`[`b`]


template defineMapTyped(symbol, cayley: untyped) =
  ## Define typed form of map `symbol`: any type in, type that `cayley` reaches out.
  func symbol*[A: static Bases](
    m: MultivectorOf[A],
  ): typeof(zeroNamed[basesMapped(cayley, A)]()) {.inline, noinit.} =
    ## Map multivector of any type, returning bases its Cayley table reaches.
    emitMappedByBasis(cayley, basesMapped(cayley, A), A, result, m)


template defineProductTyped(symbol, cayley: untyped) =
  ## Define typed form of product `symbol`: any two types in, type that `cayley` reaches out.
  func symbol*[A, B: static Bases](
    m: MultivectorOf[A], n: MultivectorOf[B],
  ): typeof(zeroNamed[basesMultiplied(cayley, A, B)]()) {.inline, noinit.} =
    ## Multiply multivectors of any types, returning bases their Cayley table reaches.
    emitMultipliedByBasis(cayley, basesMultiplied(cayley, A, B), A, B, result, m, n)


template defineSquaredTyped(symbol, cayley: untyped) =
  ## Define typed form of squared norm `symbol`: any type in, type that `cayley` reaches out.
  func symbol*[A: static Bases](
    m: MultivectorOf[A],
  ): typeof(zeroNamed[basesMultiplied(cayley, A, A)]()) {.inline, noinit.} =
    ## Square multivector of any type through its norm, returning bases its table reaches.
    emitMultipliedByBasis(cayley, basesMultiplied(cayley, A, A), A, A, result, m, m)


defineMapTyped(`∙`, CAYLEYS_PARTS.bulk.round)
defineMapTyped(`∘`, CAYLEYS_PARTS.weight.round)
when IS_CONFORMAL:
  defineMapTyped(`■`, CAYLEYS_PARTS.bulk.flat)
  defineMapTyped(`□`, CAYLEYS_PARTS.weight.flat)
defineMapTyped(`/`, CAYLEYS_COMPLEMENT.right)
defineMapTyped(`\`, CAYLEYS_COMPLEMENT.left)
defineMapTyped(`~`, CAYLEYS_REVERSE.base)
defineMapTyped(`~∘`, CAYLEYS_REVERSE.anti)
defineMapTyped(`★`, CAYLEYS_DUAL.base.right)
defineMapTyped(`☆`, CAYLEYS_DUAL.anti.right)
defineMapTyped(`⊖`, CAYLEY_ATTITUDE)
when IS_CONFORMAL:
  defineMapTyped(`⊟`, CAYLEY_CARRIER)

defineProductTyped(`∧`, CAYLEYS_WEDGE.base)
defineProductTyped(`∨`, CAYLEYS_WEDGE.anti)
defineProductTyped(`∙`, CAYLEYS_DOT.base)
defineProductTyped(`∘`, CAYLEYS_DOT.anti)
defineProductTyped(`⟑`, CAYLEYS_WEDGE_DOT.base)
defineProductTyped(`⟇`, CAYLEYS_WEDGE_DOT.anti)
defineProductTyped(`∧★`, CAYLEYS_INTERIOR.base.bulk.right)
defineProductTyped(`∧☆`, CAYLEYS_INTERIOR.base.weight.right)
defineProductTyped(`∨★`, CAYLEYS_INTERIOR.anti.bulk.right)
defineProductTyped(`∨☆`, CAYLEYS_INTERIOR.anti.weight.right)

defineSquaredTyped(`|∙²`, CAYLEYS_NORM_SQUARED.bulk.round)
defineSquaredTyped(`|∘²`, CAYLEYS_NORM_SQUARED.weight.round)
when IS_CONFORMAL:
  defineSquaredTyped(`|■²`, CAYLEYS_NORM_SQUARED.bulk.flat)
  defineSquaredTyped(`|□²`, CAYLEYS_NORM_SQUARED.weight.flat)
  defineSquaredTyped(`|⊘²`, CAYLEYS_NORM_SQUARED_RADIUS)


# Functions rather than templates, unlike full forms above: generic template over static bases
#   crashes compiler where called ("field 'sons' is not accessible"), in Nim 2.4.0 and devel.

func `∧`*[B: static Bases](
  s: Coefficient, m: MultivectorOf[B],
): MultivectorOf[B] {.inline, noinit.} =
  ## Multiply scalar and multivector of any type via exterior product, keeping its type.
  emitScaledByBasis(B, result, s, m)


func `∧`*[B: static Bases](
  m: MultivectorOf[B], s: Coefficient,
): MultivectorOf[B] {.inline, noinit.} =
  ## Multiply multivector of any type and scalar via exterior product, keeping its type.
  emitScaledByBasis(B, result, s, m)


func `*`*[B: static Bases](
  s: Coefficient, m: MultivectorOf[B],
): MultivectorOf[B] {.inline, noinit.} =
  ## Multiply scalar and multivector of any type via exterior product, keeping its type.
  emitScaledByBasis(B, result, s, m)


func `*`*[B: static Bases](
  m: MultivectorOf[B], s: Coefficient,
): MultivectorOf[B] {.inline, noinit.} =
  ## Multiply multivector of any type and scalar via exterior product, keeping its type.
  emitScaledByBasis(B, result, s, m)


func coefficientOr[B: static Bases](m: MultivectorOf[B], b: static Basis): Coefficient {.inline.} =
  ## Read coefficient of `b` from typed result, or zero where its type lacks `b`.
  when b in Bases(B): m[b] else: Coefficient(0)


func `|∙`*[B: static Bases](m: MultivectorOf[B]): MultivectorScalars {.inline.} =
  ## Get (round) bulk norm of multivector of any type, i.e. ‖𝐦‖∙ = √(𝐦∙𝐦).
  result[Basis.scalar] = coefficientOr(`|∙²`m, Basis.scalar).sqrt

func `|∘`*[B: static Bases](m: MultivectorOf[B]): MultivectorScalars {.inline.} =
  ## Get (round) weight norm of multivector of any type, i.e. ‖𝐦‖∘ = √(𝐦∘𝐦).
  result[Basis.scalarAnti] = coefficientOr(`|∘²`m, Basis.scalarAnti).sqrt

when IS_CONFORMAL:
  func `|■`*[B: static Bases](m: MultivectorOf[B]): MultivectorScalars {.inline.} =
    ## Get flat bulk norm of multivector of any type.
    result[Basis.scalar] = coefficientOr(`|■²`m, Basis.scalar).sqrt

  func `|□`*[B: static Bases](m: MultivectorOf[B]): MultivectorScalars {.inline.} =
    ## Get flat weight norm of multivector of any type.
    result[Basis.scalarAnti] = coefficientOr(`|□²`m, Basis.scalarAnti).sqrt

  func `|⊘`*[B: static Bases](m: MultivectorOf[B]): MultivectorScalars {.inline.} =
    ## Get radius norm of multivector of any type.
    result[Basis.scalarAnti] = coefficientOr(`|⊘²`m, Basis.scalarAnti).sqrt


func `|`*[B: static Bases](m: MultivectorOf[B]): MultivectorScalars {.inline.} =
  ## Get geometric norm of multivector of any type, as norm of full multivector reads it.
  when IS_RIGID:
    result[Basis.scalar] = (|∙m)[Basis.scalar]
    result[Basis.scalarAnti] = (|∘m)[Basis.scalarAnti]
  else:
    result[Basis.scalar] = (|■m)[Basis.scalar]
    result[Basis.scalarAnti] = (|□m)[Basis.scalarAnti]


func `^∙`*[B: static Bases](m: MultivectorOf[B]): MultivectorOf[B] {.inline, noinit.} =
  ## Normalize multivector of any type so bulk norm has unit scalar magnitude, keeping its type.
  ##   Performs no-op where bulk norm is 0.
  let
    m_norm_bulk = coefficientOr(`|∙²`m, Basis.scalar).sqrt
    reciprocal = if m_norm_bulk != 0: 1.0 / m_norm_bulk else: 1.0
  emitScaledByBasis(B, result, reciprocal, m)

func `^∘`*[B: static Bases](m: MultivectorOf[B]): MultivectorOf[B] {.inline, noinit.} =
  ## Normalize multivector of any type so weight norm has unit antiscalar magnitude, keeping type.
  ##   Performs no-op where weight norm is 0.
  let
    m_norm_weight = coefficientOr(`|∘²`m, Basis.scalarAnti).sqrt
    reciprocal = if m_norm_weight != 0: 1.0 / m_norm_weight else: 1.0
  emitScaledByBasis(B, result, reciprocal, m)

func `^`*[B: static Bases](m: MultivectorOf[B]): MultivectorOf[B] {.inline.} = ^∘m
  ## Normalize multivector of any type so weight norm has unit antiscalar magnitude, i.e. unitize.


# Each operator built from others above takes any type through typed forms of those others.
#   So its type is what their tables reach in turn, which may hold bases where terms cancel.

when IS_RIGID:
  func `∩`*[B: static Bases](m: MultivectorOf[B]): auto {.inline.} =
    ## Get right support of multivector of any type, i.e. 𝐦∩ = 𝐦 ∨ (𝐞ₙ ∧ 𝐦☆).
    var 𝐞ₙ {.noinit.}: typeof(zeroNamed[{Basis.origin}]())
    𝐞ₙ[Basis.origin] = 1
    m ∨ (𝐞ₙ ∧ ☆m)

  func `∪`*[B: static Bases](m: MultivectorOf[B]): auto {.inline.} =
    ## Get right antisupport of multivector of any type, i.e. 𝐦∪ = 𝐦 ∧ (𝐞̄ₙ ∨ 𝐦★).
    const h = Basis.horizon
    var 𝐞̄ₙ {.noinit.}: typeof(zeroNamed[{h.basis}]())
    𝐞̄ₙ[h.basis] = (if h.is_negated: -1 else: 1)
    m ∧ (𝐞̄ₙ ∨ ★m)

when IS_CONFORMAL:
  func `⊞`*[B: static Bases](m: MultivectorOf[B]): auto {.inline.} =
    ## Get cocarrier of multivector of any type, i.e. 𝐦☆ ∧ 𝐞ₙ.
    var 𝐞ₙ {.noinit.}: typeof(zeroNamed[{Basis.infinity}]())
    𝐞ₙ[Basis.infinity] = 1
    ☆m ∧ 𝐞ₙ

  func `⊙`*[B: static Bases](m: MultivectorOf[B]): auto {.inline.} = ⊞m ∨ m
    ## Get center of multivector of any type, i.e. 𝐦⊞ ∨ 𝐦.

  func `⊡`*[B: static Bases](m: MultivectorOf[B]): auto {.inline.} = m ∧ ☆(⊟m)
    ## Get container of multivector of any type, i.e. 𝐦 ∧ (𝐦⊟)☆.

  func `⊛`*[B: static Bases](m: MultivectorOf[B]): auto {.inline.} =
    ## Get partner of multivector of any type, i.e. (-1)^(grade(𝐦)+1) (𝐦☆)⊡ ∨ 𝐦⊟.
    let sign = Coefficient(-1^(int(m.toMultivector.grade.get) + 1))
    sign * ⊡(☆m) ∨ ⊟m
```

## Edit `pga.nim`

```nim
when IS_RIGID:
  func bulk*(m: Multivector): Multivector {.inline.} = ∙m
    ## Extract bulk of multivector.
    ##   Bulk contains object's position.

  func weight*(m: Multivector): Multivector {.inline.} = ∘m
    ## Extract weight of multivector.
    ##   Weight contains object's attitude and orientation.
    ##   Where weight is 0, object is contained by (N-1)D object at infinity.

when IS_CONFORMAL:
  func bulkFlat*(m: Multivector): Multivector {.inline.} = ■m
    ## Extract flat bulk of multivector.
    ##   Bulk contains object's position.

  func bulkRound*(m: Multivector): Multivector {.inline.} = ∙m
    ## Extract round bulk of multivector.
    ##   Bulk contains object's position.

  func weightFlat*(m: Multivector): Multivector {.inline.} = □m
    ## Extract flat weight of multivector.
    ##   Weight contains object's attitude and orientation.

  func weightRound*(m: Multivector): Multivector {.inline.} = ∘m
    ## Extract round weight of multivector.
    ##   Weight contains object's attitude and orientation.
```

```nim
when IS_RIGID:
  func bulk*[A: static Bases](m: MultivectorOf[A]): auto {.inline.} = ∙m
    ## Extract bulk of multivector.
    ##   Bulk contains object's position.

  func weight*[A: static Bases](m: MultivectorOf[A]): auto {.inline.} = ∘m
    ## Extract weight of multivector.
    ##   Weight contains object's attitude and orientation.
    ##   Where weight is 0, object is contained by (N-1)D object at infinity.

when IS_CONFORMAL:
  func bulkFlat*[A: static Bases](m: MultivectorOf[A]): auto {.inline.} = ■m
    ## Extract flat bulk of multivector.
    ##   Bulk contains object's position.

  func bulkRound*[A: static Bases](m: MultivectorOf[A]): auto {.inline.} = ∙m
    ## Extract round bulk of multivector.
    ##   Bulk contains object's position.

  func weightFlat*[A: static Bases](m: MultivectorOf[A]): auto {.inline.} = □m
    ## Extract flat weight of multivector.
    ##   Weight contains object's attitude and orientation.

  func weightRound*[A: static Bases](m: MultivectorOf[A]): auto {.inline.} = ∘m
    ## Extract round weight of multivector.
    ##   Weight contains object's attitude and orientation.
```

## Edit `pga.nim`

```nim
func norm*(m: Multivector): MultivectorScalars {.inline.} = |m
  ## Get geometric norm of multivector as distance from origin.

func normalizeBulk*(m: Multivector): Multivector {.inline.} = ^∙m
  ## Normalize multivector so bulk norm has unit scalar magnitude (𝟏).

func normalizeWeight*(m: Multivector): Multivector {.inline.} = ^∘m
  ## Normalize multivector so weight norm has unit antiscalar magnitude, i.e. |𝐦|∘ = 𝟙.

func unitize*(m: Multivector): Multivector {.inline.} = ^m
  ## Normalize multivector so weight norm has unit antiscalar magnitude, i.e. 𝐦̂ = 𝐦 / ‖𝐦‖∘.
  ##   Shorthand for weight normalization, i.e. weight has magnitude of one.
  ##   Projects higher-dimensional representations of objects into Eucledian space.
  ##     By scaling weight of 𝐦 to unit magnitude.

when IS_RIGID:
  func normBulk*(m: Multivector): MultivectorScalars {.inline.} = |∙m
    ## Get bulk norm of multivector as size of bulk components.

  func normWeight*(m: Multivector): MultivectorScalars {.inline.} = |∘m
    ## Get weight norm of multivector as size of weight components.
    ##   Interpreted as collective magnitude of components that extend in direction of eₙ.

when IS_CONFORMAL:
  func normBulkRound*(m: Multivector): MultivectorScalars {.inline.} = |∙m
    ## Get round bulk norm of multivector as size of round bulk components.

  func normWeightRound*(m: Multivector): MultivectorScalars {.inline.} = |∘m
    ## Get round weight norm of multivector as size of round weight components.

  func normBulkFlat*(m: Multivector): MultivectorScalars {.inline.} = |■m
    ## Get flat bulk norm of multivector as size of flat bulk components.

  func normWeightFlat*(m: Multivector): MultivectorScalars {.inline.} = |□m
    ## Get flat weight norm of multivector as size of flat weight components.

  func normCenter*(m: Multivector): MultivectorScalars {.inline, error: "TODO:  |⊙m".}
    ## Get center norm of multivector.

  func normRadius*(m: Multivector): MultivectorScalars {.inline.} = |⊘m
    ## Get radius norm of multivector.
```

```nim
func norm*[A: static Bases](m: MultivectorOf[A]): auto {.inline.} = |m
  ## Get geometric norm of multivector as distance from origin.

func normalizeBulk*[A: static Bases](m: MultivectorOf[A]): auto {.inline.} = ^∙m
  ## Normalize multivector so bulk norm has unit scalar magnitude (𝟏).

func normalizeWeight*[A: static Bases](m: MultivectorOf[A]): auto {.inline.} = ^∘m
  ## Normalize multivector so weight norm has unit antiscalar magnitude, i.e. |𝐦|∘ = 𝟙.

func unitize*[A: static Bases](m: MultivectorOf[A]): auto {.inline.} = ^m
  ## Normalize multivector so weight norm has unit antiscalar magnitude, i.e. 𝐦̂ = 𝐦 / ‖𝐦‖∘.
  ##   Shorthand for weight normalization, i.e. weight has magnitude of one.
  ##   Projects higher-dimensional representations of objects into Eucledian space.
  ##     By scaling weight of 𝐦 to unit magnitude.

when IS_RIGID:
  func normBulk*[A: static Bases](m: MultivectorOf[A]): auto {.inline.} = |∙m
    ## Get bulk norm of multivector as size of bulk components.

  func normWeight*[A: static Bases](m: MultivectorOf[A]): auto {.inline.} = |∘m
    ## Get weight norm of multivector as size of weight components.
    ##   Interpreted as collective magnitude of components that extend in direction of eₙ.

when IS_CONFORMAL:
  func normBulkRound*[A: static Bases](m: MultivectorOf[A]): auto {.inline.} = |∙m
    ## Get round bulk norm of multivector as size of round bulk components.

  func normWeightRound*[A: static Bases](m: MultivectorOf[A]): auto {.inline.} = |∘m
    ## Get round weight norm of multivector as size of round weight components.

  func normBulkFlat*[A: static Bases](m: MultivectorOf[A]): auto {.inline.} = |■m
    ## Get flat bulk norm of multivector as size of flat bulk components.

  func normWeightFlat*[A: static Bases](m: MultivectorOf[A]): auto {.inline.} = |□m
    ## Get flat weight norm of multivector as size of flat weight components.

  func normCenter*(m: Multivector): MultivectorScalars {.inline, error: "TODO:  |⊙m".}
    ## Get center norm of multivector.

  func normRadius*[A: static Bases](m: MultivectorOf[A]): auto {.inline.} = |⊘m
    ## Get radius norm of multivector.
```

## Edit `pga.nim`

```nim
func attitude*(m: Multivector): Multivector {.inline.} = ⊖m
  ## Get attitude of multivector as intersection with horizon.

when IS_RIGID:
  func support*(m: Multivector): Multivector {.inline.} = ∩m
    ## Perform orthogonal projection of origin (i.e. eₙ) onto multivector.

  func supportAnti*(m: Multivector): Multivector {.inline.} = ∪m
    ## Perform orthogonal projection of horizon (i.e. e̅ₙ) onto multivector.

when IS_CONFORMAL:
  func carrier*(m: Multivector): Multivector {.inline.} = ⊟m
    ## Get carrier of multivector as lowest dimensional flat object containing it, i.e. 𝐦 ∧ eₙ.
    ##   Has effect of annihilating flat part of multivector as eₙ ∧ eₙ = 0,
    ##   Also add eₙ to each round component, making it flat geometry.
    ##   Carrrier contains center of original multivector.

  func carrierCo*(m: Multivector): Multivector {.inline.} = ⊞m
    ## Get cocarrier of multivector as carrier of multivector's antidual, i.e. 𝐦☆ ∧ eₙ.
    ##   Antidual used over dual to make signs more favourable.
    ##   Cocarrrier contains center of original multivector.

  func center*(m: Multivector): Multivector {.inline.} = ⊙m
    ## Get center of multivector as round point with same position and radius, i.e. 𝐦⊞ ∨ 𝐦.
    ##   Center of real object is real, center of imaginary object is imaginary.

  func container*(m: Multivector): Multivector {.inline.} = ⊡m
    ## Get container of multivector as smallest sphere containing it, i.e. 𝐦 ∧ (𝐦⊟)☆.
    ##   Antidual used over dual to be consistent with expansions.
    ##   Container of real object is real, container of imaginary object is imaginary.

  func partner*(m: Multivector): Multivector {.inline.} = ⊛m
    ## Get partner of multivector as same object with squared radius of opposite sign.
    ##   I.e. (-1)^(grade(𝐦)+1) (𝐦☆)⊡ ∨ 𝐦⊟.
```

```nim
func attitude*[A: static Bases](m: MultivectorOf[A]): auto {.inline.} = ⊖m
  ## Get attitude of multivector as intersection with horizon.

when IS_RIGID:
  func support*[A: static Bases](m: MultivectorOf[A]): auto {.inline.} = ∩m
    ## Perform orthogonal projection of origin (i.e. eₙ) onto multivector.

  func supportAnti*[A: static Bases](m: MultivectorOf[A]): auto {.inline.} = ∪m
    ## Perform orthogonal projection of horizon (i.e. e̅ₙ) onto multivector.

when IS_CONFORMAL:
  func carrier*[A: static Bases](m: MultivectorOf[A]): auto {.inline.} = ⊟m
    ## Get carrier of multivector as lowest dimensional flat object containing it, i.e. 𝐦 ∧ eₙ.
    ##   Has effect of annihilating flat part of multivector as eₙ ∧ eₙ = 0,
    ##   Also add eₙ to each round component, making it flat geometry.
    ##   Carrrier contains center of original multivector.

  func carrierCo*[A: static Bases](m: MultivectorOf[A]): auto {.inline.} = ⊞m
    ## Get cocarrier of multivector as carrier of multivector's antidual, i.e. 𝐦☆ ∧ eₙ.
    ##   Antidual used over dual to make signs more favourable.
    ##   Cocarrrier contains center of original multivector.

  func center*[A: static Bases](m: MultivectorOf[A]): auto {.inline.} = ⊙m
    ## Get center of multivector as round point with same position and radius, i.e. 𝐦⊞ ∨ 𝐦.
    ##   Center of real object is real, center of imaginary object is imaginary.

  func container*[A: static Bases](m: MultivectorOf[A]): auto {.inline.} = ⊡m
    ## Get container of multivector as smallest sphere containing it, i.e. 𝐦 ∧ (𝐦⊟)☆.
    ##   Antidual used over dual to be consistent with expansions.
    ##   Container of real object is real, container of imaginary object is imaginary.

  func partner*[A: static Bases](m: MultivectorOf[A]): auto {.inline.} = ⊛m
    ## Get partner of multivector as same object with squared radius of opposite sign.
    ##   I.e. (-1)^(grade(𝐦)+1) (𝐦☆)⊡ ∨ 𝐦⊟.
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

func negate*(m: Multivector): Multivector {.inline.} = -m
  ## Negate multivector.

func reverse*(m: Multivector): Multivector {.inline.} = ~m
  ## Reverse multivector.
  ##   I.e. rearrange vector element factors so they wedge in reverse order.

func reverseAnti*(m: Multivector): Multivector {.inline.} = ~∘m
  ## Reverse complement of multivector.
  ##   I.e. rearrange antivector element factors so they antiwedge in reverse order.
```

```nim
func complementLeft*[A: static Bases](m: MultivectorOf[A]): auto {.inline.} = \m
  ## Get left complement of multivector.

func complementRight*[A: static Bases](m: MultivectorOf[A]): auto {.inline.} = /m
  ## Get right complement of multivector.

func dualBulk*[A: static Bases](m: MultivectorOf[A]): auto {.inline.} = ★m
  ## Get right dual of multivector's bulk components.

func dualWeight*[A: static Bases](m: MultivectorOf[A]): auto {.inline.} = ☆m
  ## Get right dual of multivector's weight components.

func negate*[A: static Bases](m: MultivectorOf[A]): auto {.inline.} = -m
  ## Negate multivector.

func reverse*[A: static Bases](m: MultivectorOf[A]): auto {.inline.} = ~m
  ## Reverse multivector.
  ##   I.e. rearrange vector element factors so they wedge in reverse order.

func reverseAnti*[A: static Bases](m: MultivectorOf[A]): auto {.inline.} = ~∘m
  ## Reverse complement of multivector.
  ##   I.e. rearrange antivector element factors so they antiwedge in reverse order.
```

## Edit `pga.nim`

```nim
func add*(m, n: Multivector): Multivector {.inline.} = m + n
  ## Add multivectors.

func add*(m: Multivector, s: Coefficient): Multivector {.inline.} = s + m
  ## Add multivector and scalar.

func add*(s: Coefficient, m: Multivector): Multivector {.inline.} = s + m
  ## Add scalar and multivector.

func dot*(m, n: Multivector): Multivector {.inline.} = m ∙ n
  ## Multiply multivectors through inner product between bulks.

func dotAnti*(m, n: Multivector): Multivector {.inline.} = m ∘ n
  ## Multiply multivectors through inner product between weights.

func subtract*(m, n: Multivector): Multivector {.inline.} = m - n
  ## Subtract multivectors.

func subtract*(m: Multivector, s: Coefficient): Multivector {.inline.} = m - s
  ## Subtract scalar from multivector.

func subtract*(s: Coefficient, m: Multivector): Multivector {.inline.} = s - m
  ## Subtract multivector from scalar.

func wedge*(m, n: Multivector): Multivector {.inline.} = m ∧ n
  ## Multiply multivectors by combining jointly present dimensions.
  ##   I.e. multiply through exterior product.
  ##   Also called join operation, analogous to union.

func wedge*(m: Multivector, s: Coefficient): Multivector {.inline.} = s ∧ m
  ## Multiply multivector and scalar via exterior product.
  ##   Equivalent to standard scalar product.

func wedge*(s: Coefficient, m: Multivector): Multivector {.inline.} = s ∧ m
  ## Multiply scalar and multivector via exterior product.
  ##   Equivalent to standard scalar product.

func wedgeAnti*(m: Multivector, n: Multivector): Multivector {.inline.} = m ∨ n
  ## Multiply multivectors by combining jointly abscent dimensions.
  ##   I.e. multiply through exterior antiproduct.
  ##   Also called meet operation, analogous to intersection.

func wedgeDot*(m, n: Multivector): Multivector {.inline.} = m ⟑ n
  ## Multiply multivectors through geometric product.
  ##   Incorporates wedge product, adding information.

func wedgeDotAnti*(m, n: Multivector): Multivector {.inline.} = m ⟇ n
  ## Multiply multivectors through geometric antiproduct.
  ##   Incorporates antiwedge proudct, adding information.
```

```nim
func add*[A, B: static Bases](m: MultivectorOf[A], n: MultivectorOf[B]): auto {.inline.} = m + n
  ## Add multivectors.

func add*[A: static Bases](m: MultivectorOf[A], s: Coefficient): auto {.inline.} = s + m
  ## Add multivector and scalar.

func add*[A: static Bases](s: Coefficient, m: MultivectorOf[A]): auto {.inline.} = s + m
  ## Add scalar and multivector.

func dot*[A, B: static Bases](m: MultivectorOf[A], n: MultivectorOf[B]): auto {.inline.} = m ∙ n
  ## Multiply multivectors through inner product between bulks.

func dotAnti*[A, B: static Bases](m: MultivectorOf[A], n: MultivectorOf[B]): auto {.inline.} = m ∘ n
  ## Multiply multivectors through inner product between weights.

func subtract*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B],
): auto {.inline.} = m - n
  ## Subtract multivectors.

func subtract*[A: static Bases](m: MultivectorOf[A], s: Coefficient): auto {.inline.} = m - s
  ## Subtract scalar from multivector.

func subtract*[A: static Bases](s: Coefficient, m: MultivectorOf[A]): auto {.inline.} = s - m
  ## Subtract multivector from scalar.

func wedge*[A, B: static Bases](m: MultivectorOf[A], n: MultivectorOf[B]): auto {.inline.} = m ∧ n
  ## Multiply multivectors by combining jointly present dimensions.
  ##   I.e. multiply through exterior product.
  ##   Also called join operation, analogous to union.

func wedge*[A: static Bases](m: MultivectorOf[A], s: Coefficient): auto {.inline.} = s ∧ m
  ## Multiply multivector and scalar via exterior product.
  ##   Equivalent to standard scalar product.

func wedge*[A: static Bases](s: Coefficient, m: MultivectorOf[A]): auto {.inline.} = s ∧ m
  ## Multiply scalar and multivector via exterior product.
  ##   Equivalent to standard scalar product.

func wedgeAnti*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B],
): auto {.inline.} = m ∨ n
  ## Multiply multivectors by combining jointly abscent dimensions.
  ##   I.e. multiply through exterior antiproduct.
  ##   Also called meet operation, analogous to intersection.

func wedgeDot*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B],
): auto {.inline.} = m ⟑ n
  ## Multiply multivectors through geometric product.
  ##   Incorporates wedge product, adding information.

func wedgeDotAnti*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B],
): auto {.inline.} = m ⟇ n
  ## Multiply multivectors through geometric antiproduct.
  ##   Incorporates antiwedge proudct, adding information.
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

func projectCentral*(m, n: Multivector): Multivector {.inline.} = n ∨ (m ∧★ n)
  ## TODO: Document.

func projectCentralAnti*(m, n: Multivector): Multivector {.inline.} = n ∧ (m ∨★ n)
  ## TODO: Document.

func projectOrthogonal*(m, n: Multivector): Multivector {.inline.} = n ∨ (m ∧☆ n)
  ## TODO: Document.

func projectOrthogonalAnti*(m, n: Multivector): Multivector {.inline.} = n ∧ (m ∨☆ n)
  ## TODO: Document.
```

```nim
func contractBulk*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B],
): auto {.inline.} = m ∨★ n
  ## Multiply multivectors through right inner product bulk contraction, i.e. 𝐦 ∨ 𝐧★.

func contractWeight*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B],
): auto {.inline.} = m ∨☆ n
  ## Multiply multivectors through right inner product weight contraction, i.e. 𝐦 ∨ 𝐧☆.

func expandBulk*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B],
): auto {.inline.} = m ∧★ n
  ## Multiply multivectors through right inner product bulk expansion, i.e. 𝐦 ∧ 𝐧★.

func expandWeight*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B],
): auto {.inline.} = m ∧☆ n
  ## Multiply multivectors through right inner product weight expansion, i.e. 𝐦 ∧ 𝐧☆.

func projectCentral*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B],
): auto {.inline.} = n ∨ (m ∧★ n)
  ## TODO: Document.

func projectCentralAnti*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B],
): auto {.inline.} = n ∧ (m ∨★ n)
  ## TODO: Document.

func projectOrthogonal*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B],
): auto {.inline.} = n ∨ (m ∧☆ n)
  ## TODO: Document.

func projectOrthogonalAnti*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B],
): auto {.inline.} = n ∧ (m ∨☆ n)
  ## TODO: Document.
```

## Edit `tests/suites.nim`

```nim
proc sampleOf[B: static Bases](): typeof(zeroNamed[B]()) =
  ## Sample multivector over bases `B` alone, of named type where one has them.
  for b in B: result[b] = gauss(0.0, 1.0)
```

```nim
proc sampleOf[B: static Bases](): typeof(zeroNamed[B]()) =
  ## Sample multivector over bases `B` alone, of named type where one has them.
  when Bases(B).card > 0:  # Skip empty set: its `index` returns empty range, which Nim refuses.
    for b in B: result[b] = gauss(0.0, 1.0)
```

## Edit `tests/suites.nim`

```nim
  test "`-`(m: MultivectorOf[B]): keep type, exact at each basis":
    for _ in 0 ..< SAMPLES:
      let
        m = sampleOf[SCATTERED]()
        v = sampleOf[VECTORS]()
      check -m is MultivectorOf[SCATTERED]
      check -v is Multivector1
      for b in SCATTERED: check (-m)[b] == -m[b]
      for b in VECTORS: check (-v)[b] == -v[b]
```

```nim
  test "`-`(m: MultivectorOf[B]): keep type, exact at each basis":
    for _ in 0 ..< SAMPLES:
      let
        m = sampleOf[SCATTERED]()
        v = sampleOf[VECTORS]()
      check -m is MultivectorOf[SCATTERED]
      check -v is Multivector1
      for b in SCATTERED: check (-m)[b] == -m[b]
      for b in VECTORS: check (-v)[b] == -v[b]



template checkSame(typed, full: untyped) =
  ## Check typed result equals full result exactly at each basis.
  ##   NaN matches NaN alone: conformal norms take root of negative square, typed and full alike.
  block:
    let (t, f) = (typed.toMultivector, full.toMultivector)
    for b in Basis: check t[b] == f[b] or (t[b].isNaN and f[b].isNaN)


template checkTypedMap(operator: untyped, A: static Bases) =
  ## Check typed `operator` on samples over `A` equals full `operator` exactly at each basis.
  ##   Also check its type holds each basis that full `operator` reaches, and no other.
  block:
    var reached: Bases
    for _ in 0 ..< SAMPLES:
      let
        m = sampleOf[A]()
        full = operator(m.toMultivector)
      checkSame(operator(m), full)
      for b in Basis:
        if full[b] != 0: reached.incl(b)
    check basesType(operator(sampleOf[A]())) == reached


template checkTypedProduct(operator: untyped, A, B: static Bases) =
  ## Check typed `operator` on samples over `A` and `B` equals full `operator` exactly.
  ##   Also check its type holds each basis that full `operator` reaches, and no other.
  block:
    var reached: Bases
    for _ in 0 ..< SAMPLES:
      let
        m = sampleOf[A]()
        n = sampleOf[B]()
        full = operator(m.toMultivector, n.toMultivector)
      checkSame(operator(m, n), full)
      for b in Basis:
        if full[b] != 0: reached.incl(b)
    check basesType(operator(sampleOf[A](), sampleOf[B]())) == reached


template checkTypedComposed(operator: untyped, A: static Bases) =
  ## Check typed `operator` built from others, on samples over `A`, equals full `operator` exactly.
  ##   Also check its type holds each basis that full `operator` reaches.
  block:
    var reached: Bases
    for _ in 0 ..< SAMPLES:
      let
        m = sampleOf[A]()
        full = operator(m.toMultivector)
      checkSame(operator(m), full)
      for b in Basis:
        if full[b] != 0: reached.incl(b)
    check reached <= basesType(operator(sampleOf[A]()))


template checkTypedComposedAll(A: static Bases) =
  ## Check each typed operator built from others on samples over `A`, partner aside.
  when IS_RIGID:
    checkTypedComposed(`∩`, A)
    checkTypedComposed(`∪`, A)
  when IS_CONFORMAL:
    checkTypedComposed(`⊞`, A)
    checkTypedComposed(`⊙`, A)
    checkTypedComposed(`⊡`, A)


template checkTypedMaps(A: static Bases) =
  ## Check each typed map on samples over `A`.
  checkTypedMap(`∙`, A)
  checkTypedMap(`∘`, A)
  checkTypedMap(`/`, A)
  checkTypedMap(`\`, A)
  checkTypedMap(`~`, A)
  checkTypedMap(`~∘`, A)
  checkTypedMap(`★`, A)
  checkTypedMap(`☆`, A)
  checkTypedMap(`⊖`, A)
  checkTypedMap(`|∙²`, A)
  checkTypedMap(`|∘²`, A)
  when IS_CONFORMAL:
    checkTypedMap(`■`, A)
    checkTypedMap(`□`, A)
    checkTypedMap(`⊟`, A)
    checkTypedMap(`|■²`, A)
    checkTypedMap(`|□²`, A)
    checkTypedMap(`|⊘²`, A)


template checkTypedProducts(A, B: static Bases) =
  ## Check each typed product on samples over `A` and `B`.
  checkTypedProduct(`∧`, A, B)
  checkTypedProduct(`∨`, A, B)
  checkTypedProduct(`∙`, A, B)
  checkTypedProduct(`∘`, A, B)
  checkTypedProduct(`⟑`, A, B)
  checkTypedProduct(`⟇`, A, B)
  checkTypedProduct(`∧★`, A, B)
  checkTypedProduct(`∧☆`, A, B)
  checkTypedProduct(`∨★`, A, B)
  checkTypedProduct(`∨☆`, A, B)


template checkTypedScaling(A: static Bases) =
  ## Check typed scaling, norms and unitizing on samples over `A` equal full forms exactly.
  ##   Also check scaling and unitizing keep type of sample.
  for _ in 0 ..< SAMPLES:
    let
      m = sampleOf[A]()
      f = m.toMultivector
      s = gauss(0.0, 1.0)
    check (s ∧ m) is typeof(m)
    check (m ∧ s) is typeof(m)
    check (s * m) is typeof(m)
    check (m * s) is typeof(m)
    check ^∙m is typeof(m)
    check ^∘m is typeof(m)
    check ^m is typeof(m)
    checkSame(s ∧ m, s ∧ f)
    checkSame(m ∧ s, f ∧ s)
    checkSame(s * m, s * f)
    checkSame(m * s, f * s)
    checkSame(^∙m, ^∙f)
    checkSame(^∘m, ^∘f)
    checkSame(^m, ^f)
    checkSame(|∙m, |∙f)
    checkSame(|∘m, |∘f)
    checkSame(|m, |f)
    when IS_CONFORMAL:
      checkSame(|■m, |■f)
      checkSame(|□m, |□f)
      checkSame(|⊘m, |⊘f)


const EMPTY: Bases = {}



suite "Typed operators":
  test "Maps: equal full maps exactly, typed by bases their tables reach":
    checkTypedMaps(VECTORS)
    checkTypedMaps(BIVECTORS)
    checkTypedMaps(EVEN)
    checkTypedMaps(ODD)
    checkTypedMaps(SCATTERED)
    checkTypedMaps(EMPTY)


  test "Products: equal full products exactly, typed by bases their tables reach":
    checkTypedProducts(VECTORS, VECTORS)
    checkTypedProducts(VECTORS, BIVECTORS)
    checkTypedProducts(BIVECTORS, VECTORS)
    checkTypedProducts(EVEN, EVEN)
    checkTypedProducts(EVEN, ODD)
    checkTypedProducts(SCATTERED, VECTORS)
    checkTypedProducts({Basis.scalar}, ALL)
    checkTypedProducts(VECTORS, EMPTY)


  test "Products: take named type where table reaches one, empty type where it reaches none":
    let
      v = sampleOf[VECTORS]()
      a = sampleOf[{Basis.scalarAnti}]()
    check v ∧ v is Multivector2
    check v ∙ v is Multivector0
    check basesType(v ∧ a) == EMPTY
    check (v ∧ a).toMultivector =~ Multivector()
    check (v ∧ a) + v is Multivector1


  test "Operators built from others: equal full forms exactly":
    checkTypedComposedAll(VECTORS)
    checkTypedComposedAll(BIVECTORS)
    checkTypedComposedAll(EVEN)
    checkTypedComposedAll(ODD)
    checkTypedComposedAll(SCATTERED)
    when IS_CONFORMAL:
      # Partner reads grade of its operand, so k-vectors alone.
      checkTypedComposed(`⊛`, VECTORS)
      checkTypedComposed(`⊛`, BIVECTORS)


  test "Scaling, norms and unitizing: equal full forms exactly, scaling keeps type":
    checkTypedScaling(VECTORS)
    checkTypedScaling(EVEN)
    checkTypedScaling(SCATTERED)
```
