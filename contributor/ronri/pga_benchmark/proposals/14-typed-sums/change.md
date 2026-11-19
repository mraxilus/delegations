# Sums and differences of any two basis-set types

`+` and `-` take two multivectors of any basis-set types, a scalar beside a multivector of any
type, and negation takes any type. Two operands of one type keep that type. Two types give the
exact union of their bases, as the named type with exactly those bases where one exists. Each
body writes one assignment for each basis at compile time, so no set is read at run time. The
edits of `pga/multivectors.nim` start from the patch of D3 of pga_visualiser. Its tests stand in
a suite of their own, `Arithmetic`, at the end of `tests/suites.nim`. Every edit quotes text of
pin.

## Edit `pga/multivectors.nim`

```nim
func `+`*[B: static Bases](m, n: MultivectorOf[B]): MultivectorOf[B] {.inline, noinit.} =
  ## Add multivectors, i.e. 𝐦 + 𝐧.
  for b in B:
    result[b] = m[b] + n[b]


func `+`*(s: Coefficient, m: Multivector): Multivector {.inline, noinit.} =
  ## Add scalar and multivector, i.e. 𝐬 + 𝐦.
  result[Basis.scalar] = s + m[Basis.scalar]
  for b in Basis.scalar.succ..Basis.scalarAnti:
    result[b] = m[b]



template `+`*(m: Multivector, s: Coefficient): Multivector =
  ## Add multivector and scalar, i.e. 𝐦 + 𝐬.
  s + m
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


func zeroCombined[A, B: static Bases](): auto {.inline.} =
  ## Get zero of type of sum or difference of multivectors with bases `A` and `B`.
  ##   One type is kept as written, so it stays itself whatever form its set is written in.
  ##   Two types give exact union of their bases, as each product of a table reaches its bases.
  when A == B: default(MultivectorOf[A]) else: zeroNamed[A + B]()


macro emitCombinedByBasis(A, B: static Bases, r, m, n: untyped, op: static string): untyped =
  ## Emit one assignment per basis of union of `A` and `B`, each at constant basis.
  ##   So no set is read at runtime; basis absent from one operand reads that operand as zero.
  result = newStmtList()
  for basis in A + B:
    let
      b = newCall(ident"Basis", newLit(ord(basis)))
      left = quote do: `m`[`b`]
      right = quote do: `n`[`b`]
      value =
        if basis in A and basis in B: infix(left, op, right)
        elif basis in A: left
        elif op == "-": prefix(right, "-")
        else: right
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
  ##   Different types give exact union of their bases, named where a named type has them.
  emitCombinedByBasis(A, B, result, m, n, "+")


func `+`*[B: static Bases](
  s: Coefficient, m: MultivectorOf[B],
): typeof(zeroCombined[B, {Basis.scalar}]()) {.inline, noinit.} =
  ## Add scalar and multivector, i.e. 𝐬 + 𝐦.
  ##   Result holds bases of 𝐦 and scalar, named where a named type has them.
  var 𝐬 {.noinit.}: MultivectorOf[{Basis.scalar}]
  𝐬[Basis.scalar] = s
  emitCombinedByBasis({Basis.scalar}, B, result, 𝐬, m, "+")


func `+`*[B: static Bases](
  m: MultivectorOf[B], s: Coefficient,
): typeof(zeroCombined[B, {Basis.scalar}]()) {.inline, noinit.} =
  ## Add multivector and scalar, i.e. 𝐦 + 𝐬.
  ##   Result holds bases of 𝐦 and scalar, named where a named type has them.
  var 𝐬 {.noinit.}: MultivectorOf[{Basis.scalar}]
  𝐬[Basis.scalar] = s
  emitCombinedByBasis(B, {Basis.scalar}, result, m, 𝐬, "+")
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


func `-`*(s: Coefficient, m: Multivector): Multivector {.inline, noinit.} =
  ## Subtract multivector from scalar, i.e. 𝐬 − 𝐦.
  result[Basis.scalar] = s - m[Basis.scalar]
  for b in Basis.scalar.succ..Basis.scalarAnti:
    result[b] = -m[b]


func `-`*(m: Multivector, s: Coefficient): Multivector {.inline, noinit.} =
  ## Subtract scalar from multivector, i.e. 𝐦 − 𝐬.
  result[Basis.scalar] = m[Basis.scalar] - s
  for b in Basis.scalar.succ..Basis.scalarAnti:
    result[b] = m[b]
```

```nim
func `-`*[B: static Bases](m: MultivectorOf[B]): MultivectorOf[B] {.inline, noinit.} =
  ## Negate multivector, i.e. −𝐦.
  emitNegatedByBasis(B, result, m)


func `-`*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B],
): typeof(zeroCombined[A, B]()) {.inline, noinit.} =
  ## Subtract multivectors, i.e. 𝐦 − 𝐧.
  ##   Different types give exact union of their bases, named where a named type has them.
  emitCombinedByBasis(A, B, result, m, n, "-")


func `-`*[B: static Bases](
  s: Coefficient, m: MultivectorOf[B],
): typeof(zeroCombined[B, {Basis.scalar}]()) {.inline, noinit.} =
  ## Subtract multivector from scalar, i.e. 𝐬 − 𝐦.
  ##   Result holds bases of 𝐦 and scalar, named where a named type has them.
  var 𝐬 {.noinit.}: MultivectorOf[{Basis.scalar}]
  𝐬[Basis.scalar] = s
  emitCombinedByBasis({Basis.scalar}, B, result, 𝐬, m, "-")


func `-`*[B: static Bases](
  m: MultivectorOf[B], s: Coefficient,
): typeof(zeroCombined[B, {Basis.scalar}]()) {.inline, noinit.} =
  ## Subtract scalar from multivector, i.e. 𝐦 − 𝐬.
  ##   Result holds bases of 𝐦 and scalar, named where a named type has them.
  var 𝐬 {.noinit.}: MultivectorOf[{Basis.scalar}]
  𝐬[Basis.scalar] = s
  emitCombinedByBasis(B, {Basis.scalar}, result, m, 𝐬, "-")
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


func basesType[B: static Bases](m: MultivectorOf[B]): Bases =
  ## Read bases of type of multivector.
  B


func coefficientOr[B: static Bases](m: MultivectorOf[B], b: Basis): Coefficient =
  ## Read coefficient of basis, or zero where type lacks it.
  if b in B: m[b] else: Coefficient(0)


template checkCombined(A, B: static Bases, R: typedesc) =
  ## Check sum and difference of samples over `A` and `B` are of type `R`, exact at each basis.
  ##   `R` holds exact union of `A` and `B`.
  for _ in 0 ..< SAMPLES:
    let
      m = sampleOf[A]()
      n = sampleOf[B]()
      sum = m + n
      difference = m - n
    check sum is R
    check difference is R
    check basesType(sum) == A + B
    for b in Basis:
      let (x, y) = (m.coefficientOr(b), n.coefficientOr(b))
      check sum.coefficientOr(b) == x + y
      check difference.coefficientOr(b) == x - y


template checkUnion(A, B: static Bases) =
  ## Check sum and difference of samples over `A` and `B` take exact union of their bases.
  checkCombined(A, B, typeof(zeroNamed[A + B]()))


template checkScaled(B: static Bases) =
  ## Check sums and differences of scalar and sample over `B` hold `B` and scalar, exact.
  for _ in 0 ..< SAMPLES:
    let
      m = sampleOf[B]()
      s = gauss(0.0, 1.0)
    for r in [s + m, m + s, s - m, m - s]:
      check r is typeof(zeroNamed[B + {Basis.scalar}]())
      check basesType(r) == B + {Basis.scalar}
    for b in Basis:
      let (x, t) = (m.coefficientOr(b), if b == Basis.scalar: s else: Coefficient(0))
      check (s + m).coefficientOr(b) == t + x
      check (m + s).coefficientOr(b) == x + t
      check (s - m).coefficientOr(b) == t - x
      check (m - s).coefficientOr(b) == x - t


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


  test "`+`, `-`(m: MultivectorOf[A], n: MultivectorOf[B]): take named type of exact union":
    checkCombined({Basis.scalar}, {Basis.scalarAnti}, MultivectorScalars)
    checkCombined(VECTORS, ODD, MultivectorOdd)
    checkCombined(VECTORS_FIRST, VECTORS, Multivector1)
    checkCombined(ODD, EVEN, Multivector)


  test "`+`, `-`(m: MultivectorOf[A], n: MultivectorOf[B]): else take exact union":
    checkUnion({Basis.scalar}, VECTORS)
    checkUnion({Basis.scalar}, BIVECTORS)
    checkUnion(VECTORS, BIVECTORS)
    checkUnion(VECTOR_FIRST, VECTORS_FIRST)
    checkUnion({Basis.scalar}, SCATTERED)


  test "`+`, `-`(m: MultivectorOf[A], n: MultivectorOf[B]): give one type in either order":
    let
      s = sampleOf[{Basis.scalar}]()
      v = sampleOf[VECTORS]()
      w = sampleOf[SCATTERED]()
    check typeof(s + v) is typeof(v + s)
    check typeof(s - v) is typeof(v - s)
    check typeof(w + v) is typeof(v + w)


  test "`+`, `-`(s: Coefficient, m: MultivectorOf[B]): hold bases of 𝐦 and scalar, exact":
    checkScaled(ALL)
    checkScaled(VECTORS)
    checkScaled(EVEN)
    checkScaled(SCATTERED)
    checkScaled({Basis.scalar})


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
