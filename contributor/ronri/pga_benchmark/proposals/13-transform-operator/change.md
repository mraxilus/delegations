# One operator for the transform of a multivector, built from the types of its operands

`⟇⟇~∘` transforms 𝐦 by 𝐧 in one call: the sandwich 𝐧 ⟇ 𝐦 ⟇ 𝐧̰, which pin spells in three steps. Its
typed form builds the terms of that sandwich from the types of both operands, when the code
compiles, and writes them out in the fewer of two orders. So each value of each type transforms
exactly. A full operator takes the three steps of pin, whatever the type of 𝐦 is. `pga.nim` names
the operator `transform`, and two tests of the suite `Typed operators` hold both to the chain.
Every edit quotes text of P04.

## Edit `pga/operators.nim`

```nim
# Functions rather than templates, unlike full forms above: generic template over static bases
#   crashes compiler where called ("field 'sons' is not accessible"), in Nim 2.4.0 and devel.
```

```nim
#[ Sandwich ]#

# Sandwich 𝐧 ⟇ 𝐦 ⟇ 𝐧̰ sums terms ±𝐧ᵢ𝐦ₖ𝐧ⱼ that Cayley tables give for types of both operands,
#   when code compiles. So each value of each type transforms exactly. Full operator takes three
#   steps of pin instead, whatever type 𝐦 has.
# Sum has two orders, each written out from Cayley tables, and typed form keeps one of fewer
#   multiplies and adds. So choice reads algebra alone, and holds on every machine.
#   Matrix multiplies 𝐧 by 𝐧 first, as coefficients commute: one product per pair of 𝐧, then
#     one multiply per entry.
#   Chain multiplies 𝐧 by 𝐦 first, then by 𝐧̰: one 𝐭 serves each output, but each pair of 𝐧 is
#     read twice.
#   Neither order wins on every pair of types, so count decides.

type  # Define terms of sandwich of 𝐦 by 𝐧, by output basis.
  TermSandwich = object  ## Define one term c 𝐧ᵢ𝐧ⱼ𝐦ₖ of sandwich of 𝐦 by 𝐧.
    operand: Basis  ## Basis k of transformed multivector 𝐦.
    pair: array[2, Basis]  ## Bases i <= j of operator 𝐧; cross pair i < j reads 2𝐧ᵢ𝐧ⱼ.
    coefficient: int  ## Signed weight of product of pair, halved for cross pair.
  CayleySandwich = array[Basis, seq[TermSandwich]]  ## Define terms of sandwich per output basis.


func constructSandwich(a, b: Bases): CayleySandwich {.compileTime.} =
  ## Construct sandwich 𝐧 ⟇ 𝐦 ⟇ 𝐧̰ over bases `a` of 𝐦 and pairs of bases `b` of 𝐧.
  ##   Term 𝐧ᵢ𝐦ₖ𝐧ⱼ lands where 𝐞ᵢ ⟇ 𝐞ₖ ⟇ 𝐞̰ⱼ does. Coefficients commute, so pair i < j sums both
  ##     orders, which comes out even in each algebra, and keeps half, as its product reads
  ##     one basis doubled. So each rigid term weighs ±1.
  ##   Walks each pair and operand basis once, so no term is searched for; VM bounds iterations.
  let
    product = CAYLEYS_WEDGE_DOT.anti
    reverse = CAYLEYS_REVERSE.anti
  for i in b:
    for j in b:
      if ord(j) < ord(i): continue
      let orders = if i == j: @[(i, j)] else: @[(i, j), (j, i)]
      for k in a:
        var sums: seq[(Basis, int)]  # Coefficient of each output basis, over both orders.
        for (left, right) in orders:
          for first in product[left][k]:
            for reversed in reverse[right]:
              for second in product[first.basis][reversed.basis]:
                let sign =
                  (if first.is_negated: -1 else: 1) * (if reversed.is_negated: -1 else: 1) *
                  (if second.is_negated: -1 else: 1)
                var is_merged = false
                for sum in sums.mitems:
                  if sum[0] == second.basis:
                    sum[1] += sign
                    is_merged = true
                    break
                if not is_merged: sums.add (second.basis, sign)
        for (output, coefficient) in sums:
          if coefficient == 0: continue
          doAssert i == j or coefficient mod 2 == 0,
            "Cross pair must weigh even; got `" & $coefficient & "` at " & $output & "."
          result[output].add TermSandwich(
            operand: k, pair: [i, j], coefficient: if i == j: coefficient else: coefficient div 2
          )


func basesSandwiched(a, b: Bases): Bases {.compileTime.} =
  ## Choose bases that sandwich of bases `a` of 𝐦 by pairs of bases `b` of 𝐧 reaches.
  let table = constructSandwich(a, b)
  for output in Basis:
    if table[output].len > 0: result.incl output


macro emitSandwichedByBasis(A, B: static Bases, r, m, n: untyped): untyped =
  ## Emit one assignment per basis that sandwich of bases `A` of `m` by bases `B` of `n` reaches.
  ##   Writes out matrix and chain, then keeps one of fewer operations; tie keeps matrix.
  func countOperations(x: NimNode): int =
    ## Count multiplies and adds of emitted code, each once; negation counts none.
    ##   Add of negated term is subtraction in C, so it counts as one add.
    if x.kind == nnkInfix and (x[0].eqIdent("*") or x[0].eqIdent("+")): result = 1
    for child in x: result += countOperations(child)

  func emitMatrix(table: CayleySandwich): NimNode =
    ## Emit sandwich as matrix: product of each pair of `n` first, then each entry by basis of `m`.
    ##   Cross pair reads its second basis doubled, so each basis doubles once at most.
    ##   Entry other than one bare pair is named once, up to sign, so count reads each entry once.
    var
      products = newNimNode(nnkLetSection)
      entries = newNimNode(nnkLetSection)
      assignments = newStmtList()
      doubled: Bases
      paired: array[Basis, Bases]  # Bases that pair with each so far.
      keys: seq[string]  # Code of each named entry, first term positive.

    # Determine product of each pair once, in order table first reads it.
    for output in Basis:
      for term in table[output]:
        let
          (i, j) = (term.pair[0], term.pair[1])
          (basis_i, basis_j) = (emitBasis(i), emitBasis(j))
          name_doubled = ident("doubled_" & $j)
        if j in paired[i]: continue
        paired[i].incl j
        if i != j and j notin doubled:
          doubled.incl j
          products.add newIdentDefs(
            name_doubled, newEmptyNode(), quote do: `n`[`basis_j`] + `n`[`basis_j`]
          )
        products.add newIdentDefs(
          ident("pair_" & $i & "_" & $j),
          newEmptyNode(),
          if i == j: quote do: `n`[`basis_i`] * `n`[`basis_j`]
          else: quote do: `n`[`basis_i`] * `name_doubled`,
        )

    # Determine sum of each output over its entries, each entry signed sum of pair products.
    for output in Basis:
      if table[output].len == 0: continue
      var terms_by_operand: array[Basis, seq[TermSandwich]]
      for term in table[output]: terms_by_operand[term.operand].add term
      var summands: seq[NimNode]
      for k in Basis:
        let terms_sandwich = terms_by_operand[k]
        if terms_sandwich.len == 0: continue
        let sign = if terms_sandwich[0].coefficient < 0: -1 else: 1
        var terms: seq[NimNode]
        for term in terms_sandwich:
          let
            coefficient = sign * term.coefficient
            pair = ident("pair_" & $term.pair[0] & "_" & $term.pair[1])
            magnitude =
              if abs(coefficient) == 1: pair
              else: infix(newCall(ident"Coefficient", newLit(abs(coefficient))), "*", pair)
          terms.add(if coefficient < 0: prefix(magnitude, "-") else: magnitude)
        var entry = terms[0]
        if terms.len > 1 or entry.kind != nnkIdent:
          let key = repr(emitSum(terms))
          var index = keys.find(key)
          if index < 0:
            index = keys.len
            keys.add key
            entries.add newIdentDefs(ident("entry_" & $index), newEmptyNode(), emitSum(terms))
          entry = ident("entry_" & $index)
        let
          basis_k = emitBasis(k)
          summand = infix(entry, "*", quote do: `m`[`basis_k`])
        summands.add(if sign < 0: prefix(summand, "-") else: summand)
      let
        b = emitBasis(output)
        value = emitSum(summands)
      assignments.add quote do:
        `r`[`b`] = `value`

    # Construct body: products, then named entries, then assignments.
    result = newStmtList()
    if products.len > 0: result.add products
    if entries.len > 0: result.add entries
    result.add assignments

  func emitChain(table: CayleySandwich): NimNode =
    ## Emit sandwich as chain: 𝐭 = 𝐧 ⟇ 𝐦 first, then 𝐭 ⟇ 𝐧̰ for each basis that `table` reaches.
    ##   Both antiproducts are spelled from Cayley tables, so 𝐭 holds only bases that output reads.
    ##   Sign of antireverse folds into each term of second antiproduct.
    let
      product = CAYLEYS_WEDGE_DOT.anti
      reverse = CAYLEYS_REVERSE.anti
    var
      terms_t, terms_output: array[Basis, seq[NimNode]]  # Terms of each basis of 𝐭, of each output.
      bases_read: Bases  # Bases of 𝐭 that some output reads.

    # Determine terms ±𝐭ₓ𝐧ᵧ of each output, and bases of 𝐭 that they read.
    for x in basesMultiplied(product, B, A):
      for y in B:
        for reversed in reverse[y]:
          for destination in product[x][reversed.basis]:
            if table[destination.basis].len == 0: continue
            bases_read.incl x
            let
              (t, basis_y) = (ident("t_" & $x), emitBasis(y))
              term = quote do: `t` * `n`[`basis_y`]
            terms_output[destination.basis].add(
              if destination.is_negated xor reversed.is_negated: prefix(term, "-") else: term
            )

    # Determine terms ±𝐧ᵢ𝐦ₖ of each basis of 𝐭 that some output reads.
    for i in B:
      for k in A:
        for destination in product[i][k]:
          if destination.basis notin bases_read: continue
          let
            (basis_i, basis_k) = (emitBasis(i), emitBasis(k))
            term = quote do: `n`[`basis_i`] * `m`[`basis_k`]
          terms_t[destination.basis].add(if destination.is_negated: prefix(term, "-") else: term)

    # Construct body: each basis of 𝐭 once, then each output from them.
    var products = newNimNode(nnkLetSection)
    for x in bases_read:
      products.add newIdentDefs(ident("t_" & $x), newEmptyNode(), emitSum(terms_t[x]))
    result = newStmtList()
    if products.len > 0: result.add products
    for output in Basis:
      if table[output].len == 0: continue
      let
        b = emitBasis(output)
        value = emitSum(terms_output[output])
      result.add quote do:
        `r`[`b`] = `value`

  # Keep order of fewer operations, from sum that types of both operands give.
  let
    table = constructSandwich(A, B)
    matrix = emitMatrix(table)
    chain = emitChain(table)
  if countOperations(chain) < countOperations(matrix): chain else: matrix


func `⟇⟇~∘`*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B],
): typeof(zeroNamed[basesSandwiched(A, B)]()) {.inline, noinit.} =
  ## Transform multivector by operator of any types, i.e. 𝐧 ⟇ 𝐦 ⟇ 𝐧̰, in fewer of two orders.
  emitSandwichedByBasis(A, B, result, m, n)


func `⟇⟇~∘`*[A: static Bases](m: MultivectorOf[A], n: Multivector): Multivector {.inline.} =
  ## Transform multivector of any type by full operator, i.e. 𝐧 ⟇ 𝐦 ⟇ 𝐧̰, in three steps of pin.
  (n ⟇ m) ⟇ (~∘ n)


# Functions rather than templates, unlike full forms above: generic template over static bases
#   crashes compiler where called ("field 'sons' is not accessible"), in Nim 2.4.0 and devel.
```

## Edit `pga.nim`

```nim
##   | ∧∨☆ | projectOrthogonalAnti | 𝐧 ∧ (𝐦 ∨ 𝐧☆) |
```

```nim
##   | ∧∨☆ | projectOrthogonalAnti | 𝐧 ∧ (𝐦 ∨ 𝐧☆) |
##   | ⟇⟇~∘| transform             | 𝐧 ⟇ 𝐦 ⟇ 𝐧̰     |
```

## Edit `pga.nim`

```nim
func projectOrthogonalAnti*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B],
): auto {.inline.} = n ∧ (m ∨☆ n)
  ## Project multivector antiorthogonally onto another, i.e. 𝐧 ∧ (𝐦 ∨ 𝐧☆).
```

```nim
func projectOrthogonalAnti*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B],
): auto {.inline.} = n ∧ (m ∨☆ n)
  ## Project multivector antiorthogonally onto another, i.e. 𝐧 ∧ (𝐦 ∨ 𝐧☆).

func transform*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B],
): auto {.inline.} = m ⟇⟇~∘ n
  ## Transform multivector by operator, i.e. 𝐧 ⟇ 𝐦 ⟇ 𝐧̰, as `⟇⟇~∘` reads it.
```

## Edit `tests/suites.nim`

```nim
const EMPTY: Bases = {}
```

```nim
template checkTypedSandwich(A, B: static Bases) =
  ## Check typed sandwich of samples over `A` by samples over `B` near chain of full forms.
  ##   Operator and chain sum their terms in other orders, so they agree within tolerance alone.
  ##   Also check its type holds each basis that chain reaches, and no other.
  block:
    var reached: Bases
    for _ in 0 ..< SAMPLES:
      let
        m = sampleOf[A]()
        n = sampleOf[B]()
        (f, g) = (m.toMultivector, n.toMultivector)
        chain = (g ⟇ f) ⟇ (~∘ g)
      check (m ⟇⟇~∘ n).toMultivector =~ chain
      for b in Basis:
        if abs(chain[b]) > TOLERANCE_ABS: reached.incl(b)
    check basesType(sampleOf[A]() ⟇⟇~∘ sampleOf[B]()) == reached


const EMPTY: Bases = {}
```

## Edit `tests/suites.nim`

```nim
  test "Scaling, norms and unitizing: equal full forms exactly, scaling keeps type":
    checkTypedScaling(VECTORS)
    checkTypedScaling(EVEN)
    checkTypedScaling(SCATTERED)
```

```nim
  test "Scaling, norms and unitizing: equal full forms exactly, scaling keeps type":
    checkTypedScaling(VECTORS)
    checkTypedScaling(EVEN)
    checkTypedScaling(SCATTERED)


  test "Sandwich: near chain of full forms, typed by bases its table reaches":
    checkTypedSandwich(ALL, EVEN)
    checkTypedSandwich(ALL, ODD)
    checkTypedSandwich(VECTORS, EVEN)
    checkTypedSandwich(VECTORS, ODD)
    checkTypedSandwich(BIVECTORS, EVEN)
    checkTypedSandwich(EVEN, ODD)
    checkTypedSandwich(SCATTERED, VECTORS)


  test "Sandwich: equal chain exactly for full operator, and alias reads operator":
    for (m, n, _) in sampleMultivectors():
      let (v, e) = (sampleOf[VECTORS](), sampleOf[EVEN]())
      checkSame(m ⟇⟇~∘ n, (n ⟇ m) ⟇ (~∘ n))
      checkSame(v ⟇⟇~∘ n, (n ⟇ v) ⟇ (~∘ n))
      checkSame(e ⟇⟇~∘ n, (n ⟇ e) ⟇ (~∘ n))
      checkSame(transform(v, n), v ⟇⟇~∘ n)
    check (sampleOf[VECTORS]() ⟇⟇~∘ sampleOf[ALL]()) is Multivector
    let (v, e) = (sampleOf[VECTORS](), sampleOf[EVEN]())
    check transform(v, e).toMultivector =~ (v ⟇⟇~∘ e).toMultivector
```
