# Sums and differences of any two basis-set types

`+` and `-` take two multivectors of any basis-set types, and negation takes any type. Each body
writes one assignment for each basis at compile time, so no set is read at run time. The edits of
`pga/multivectors.nim` are the patch of D3 of pga_visualiser. Its four tests stand in a suite of
their own, `Arithmetic`, at the end of `tests/suites.nim`. Every edit quotes text of pin.

## Edit `pga/multivectors.nim`

```nim
func `+`*[B: static Bases](m, n: MultivectorOf[B]): MultivectorOf[B] {.inline, noinit.} =
  ## Add multivectors, i.e. 𝐦 + 𝐧.
  for b in B:
    result[b] = m[b] + n[b]
```

```nim
func basesNamed(): seq[Bases] {.compileTime.} =
  ## List bases of each named multivector type.
  ##   I.e. each kvector, each parity vector, dual numbers, and full multivector.
  var even, odd: Bases
  for g in Grade.low..Grade.high:
    var kvector: Bases
    for b in Basis:
      if b.grade == g: kvector.incl(b)
    result.add(kvector)
  for b in Basis:
    if int(b.grade) mod 2 == 0: even.incl(b) else: odd.incl(b)
  result.add(@[even, odd, {Basis.scalar, Basis.scalarAnti}, {Basis.scalar..Basis.scalarAnti}])


func namesNamed(): seq[string] {.compileTime.} =
  ## List name of each named multivector type, in order of `basesNamed`.
  for g in Grade.low..Grade.high:
    result.add(&"Multivector{int(g)}")
  result.add(@["MultivectorEven", "MultivectorOdd", "MultivectorScalars", "Multivector"])


func basesCanonical(bases: Bases): Bases {.compileTime.} =
  ## Rebuild bases in order of basis, so equal sets reach one static value, and so one type.
  for b in bases:
    result.incl(b)


macro emitZeroNamed(i: static int): untyped =
  ## Emit zero of named type at index `i` of `basesNamed`.
  newCall(ident"default", ident(namesNamed()[i]))


func zeroNamed*[R: static Bases](): auto {.inline.} =
  ## Get zero of named type over bases `R`, else of type over `R` rebuilt in order of basis.
  ##   Computed result types read through it, since Nim compares static sets as written.
  ##     E.g. Nim 2.4.0 keeps computed {E1, E2, E3, E4} as {E1..E4}, so not as Multivector1.
  const i = basesNamed().find(Bases(R))
  when i < 0: default(MultivectorOf[basesCanonical(R)]) else: emitZeroNamed(i)


func basesCombined(a, b: Bases): Bases {.compileTime.} =
  ## Choose bases of sum or difference of multivectors with bases `a` and `b`.
  ##   I.e. shared bases if same, else smallest named type holding both, else full multivector.
  if a == b: return a
  result = {Basis.scalar..Basis.scalarAnti}
  for named in basesNamed():
    if a + b <= named and card(named) < card(result):
      result = named


func zeroCombined[A, B: static Bases](): auto {.inline.} =
  ## Get zero of type of sum or difference of multivectors with bases `A` and `B`.
  ##   One type is kept as written, so it stays itself whatever form its set is written in.
  when A == B: default(MultivectorOf[A]) else: zeroNamed[basesCombined(A, B)]()


macro emitCombinedByBasis(R, A, B: static Bases, r, m, n: untyped, op: static string): untyped =
  ## Emit one assignment per basis of `R`, each at constant basis, so no set is read at runtime.
  ##   Basis absent from an operand reads as zero.
  result = newStmtList()
  for basis in R:
    let
      b = newCall(ident"Basis", newLit(ord(basis)))
      left = quote do: `m`[`b`]
      right = quote do: `n`[`b`]
      value =
        if basis in A and basis in B: infix(left, op, right)
        elif basis in A: left
        elif basis in B: (if op == "-": prefix(right, "-") else: right)
        else: newCall(ident"Coefficient", newLit(0))
    result.add quote do:
      `r`[`b`] = `value`


macro emitNegatedByBasis(B: static Bases, r, m: untyped): untyped =
  ## Emit one negation per basis of `B`, each at constant basis, so no set is read at runtime.
  result = newStmtList()
  for basis in B:
    let b = newCall(ident"Basis", newLit(ord(basis)))
    result.add quote do:
      `r`[`b`] = -`m`[`b`]


func `+`*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B],
): typeof(zeroCombined[A, B]()) {.inline, noinit.} =
  ## Add multivectors, i.e. 𝐦 + 𝐧.
  ##   Different types promote to smallest named type holding both, else full multivector.
  emitCombinedByBasis(basesCombined(A, B), A, B, result, m, n, "+")
```

## Edit `pga/multivectors.nim`

```nim
func `-`*(m: Multivector): Multivector {.inline, noinit.} =
  ## Negate multivector, i.e. −𝐦.
  for b in Basis:
    result[b] = -m[b]


func `-`*(m, n: Multivector): Multivector {.inline, noinit.} =
  ## Subtract multivectors, i.e. 𝐦 − 𝐧.
  for b in Basis:
    result[b] = m[b] - n[b]
```

```nim
func `-`*[B: static Bases](m: MultivectorOf[B]): MultivectorOf[B] {.inline, noinit.} =
  ## Negate multivector, i.e. −𝐦.
  emitNegatedByBasis(B, result, m)


func `-`*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B],
): typeof(zeroCombined[A, B]()) {.inline, noinit.} =
  ## Subtract multivectors, i.e. 𝐦 − 𝐧.
  ##   Different types promote to smallest named type holding both, else full multivector.
  emitCombinedByBasis(basesCombined(A, B), A, B, result, m, n, "-")
```

## Edit `tests/suites.nim`

```nim
suite "Chapter 5":
  test "TODO: Add remaining chapter 5 tests":
    skip()
```

```nim
suite "Chapter 5":
  test "TODO: Add remaining chapter 5 tests":
    skip()



proc sampleOf[B: static Bases](): typeof(zeroNamed[B]()) =
  ## Sample multivector over bases `B` alone, of named type where one has them.
  for b in B: result[b] = gauss(0.0, 1.0)


template checkCombined(A, B: static Bases, R: typedesc) =
  ## Check sum and difference of samples over `A` and `B` are of type `R`, exact at each basis.
  for _ in 0 ..< SAMPLES:
    let
      m = sampleOf[A]()
      n = sampleOf[B]()
      sum = m + n
      difference = m - n
    check sum is R
    check difference is R
    let (sum_full, difference_full) = (sum.toMultivector, difference.toMultivector)
    for b in Basis:
      let
        x = if b in A: m[b] else: Coefficient(0)
        y = if b in B: n[b] else: Coefficient(0)
      check sum_full[b] == x + y
      check difference_full[b] == x - y


const
  ALL = {Basis.scalar..Basis.scalarAnti}
  NAMED = basesNamed()
  VECTORS = NAMED[1]
  BIVECTORS = NAMED[2]
  EVEN = NAMED[^4]
  ODD = NAMED[^3]
  VECTOR_FIRST = {Basis.scalar.succ}
  VECTORS_FIRST = {Basis.scalar.succ, Basis.scalar.succ.succ}
  SCATTERED = {Basis.scalar.succ, Basis.scalarAnti}



suite "Arithmetic":
  test "`+`, `-`(m, n: MultivectorOf[B]): keep type of both, exact at each basis":
    checkCombined(ALL, ALL, Multivector)
    checkCombined(VECTORS, VECTORS, Multivector1)
    checkCombined(EVEN, EVEN, MultivectorEven)
    checkCombined(ODD, ODD, MultivectorOdd)
    checkCombined(SCATTERED, SCATTERED, MultivectorOf[SCATTERED])


  test "`+`, `-`(m: MultivectorOf[A], n: MultivectorOf[B]): promote to smallest named type":
    checkCombined({Basis.scalar}, BIVECTORS, MultivectorEven)
    checkCombined({Basis.scalar}, {Basis.scalarAnti}, MultivectorScalars)
    checkCombined(VECTORS, ODD, MultivectorOdd)
    when int(Grade.high) >= 3:
      checkCombined(VECTORS, NAMED[3], MultivectorOdd)
    checkCombined(VECTORS_FIRST, VECTORS, Multivector1)
    checkCombined(VECTOR_FIRST, VECTORS_FIRST, Multivector1)


  test "`+`, `-`(m: MultivectorOf[A], n: MultivectorOf[B]): else promote to full multivector":
    checkCombined(VECTORS, BIVECTORS, Multivector)
    checkCombined({Basis.scalar}, SCATTERED, Multivector)
    checkCombined(ODD, EVEN, Multivector)


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
