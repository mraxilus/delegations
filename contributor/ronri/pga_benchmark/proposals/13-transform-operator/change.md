# One operator for the transform of a multivector, built from the types of its operands

`⟇⟇~∘` transforms 𝐦 by the operator 𝐧, i.e. 𝐧 ⟇ 𝐦 ⟇ 𝐧̰. Its typed form builds the table of that
sandwich from the types of both operands, when the code compiles. So each value of each type
transforms exactly. Two full multivectors take the three steps of pin. `pga.nim` names the operator
`transform`, and two tests of the suite `Typed operators` hold both to the chain. Every edit quotes
text of P04.

## Edit `pga/operators.nim`

```nim
# Functions rather than templates, unlike full forms above: generic template over static bases
#   crashes compiler where called ("field 'sons' is not accessible"), in Nim 2.4.0 and devel.
```

```nim
#[ Sandwich ]#

# Sandwich 𝐧 ⟇ 𝐦 ⟇ 𝐧̰ reads table built from types of both operands, when code compiles:
#   pairs of bases of 𝐧, both orders summed, against bases of 𝐦. So each value of each type
#   transforms exactly, and motor type reads its antieven pairs alone. Two full multivectors take
#   three steps of pin instead, since table over every pair grows past them with dimension.

type
  TermSandwich = object  ## Define one term c 𝐧ᵢ𝐧ⱼ𝐦ₖ of sandwich of 𝐦 by 𝐧.
    operand: Basis  ## Basis k of transformed multivector 𝐦.
    pair: array[2, Basis]  ## Bases i <= j of operator 𝐧; cross pair i < j reads (𝐧ᵢ + 𝐧ᵢ)𝐧ⱼ.
    coefficient: int  ## Signed weight of product of pair, halved for cross pair.
  CayleySandwich = array[Basis, seq[TermSandwich]]  ## Define terms of sandwich per output basis.


func constructSandwich(a, b: Bases): CayleySandwich {.compileTime.} =
  ## Construct sandwich 𝐧 ⟇ 𝐦 ⟇ 𝐧̰ over bases `a` of 𝐦 and pairs of bases `b` of 𝐧.
  ##   Term 𝐧ᵢ𝐦ₖ𝐧ⱼ lands where 𝐞ᵢ ⟇ 𝐞ₖ ⟇ 𝐞̰ⱼ does. Coefficients commute, so pair i < j sums both
  ##     orders, which comes out even in each algebra, and keeps half, as its product reads
  ##     doubled 𝐧ᵢ. So each rigid term weighs ±1.
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


macro emitSandwichedByBasis(R, A, B: static Bases, r, m, n: untyped): untyped =
  ## Emit one assignment per basis of `R`, from table of bases `A` of `m` and pairs of `B` of `n`.
  ##   Names doubled basis and product of each pair once, so each coefficient reads products alone.
  let table = constructSandwich(A, B)
  var
    pairs: seq[array[2, Basis]]
    doubled: Bases
  for output in R:
    for term in table[output]:
      if term.pair notin pairs: pairs.add term.pair
      if term.pair[0] != term.pair[1]: doubled.incl term.pair[0]

  func nameDoubled(b: Basis): NimNode = ident("doubled_" & $b)
  func namePair(pair: array[2, Basis]): NimNode = ident("pair_" & $pair[0] & "_" & $pair[1])

  result = newStmtList()
  if pairs.len > 0:
    var products = newNimNode(nnkLetSection)
    for x in doubled:
      let bx = emitBasis(x)
      products.add newIdentDefs(nameDoubled(x), newEmptyNode(), quote do: `n`[`bx`] + `n`[`bx`])
    for pair in pairs:
      let
        b0 = emitBasis(pair[0])
        b1 = emitBasis(pair[1])
        first = (if pair[0] == pair[1]: (quote do: `n`[`b0`]) else: nameDoubled(pair[0]))
      products.add newIdentDefs(namePair(pair), newEmptyNode(), quote do: `first` * `n`[`b1`])
    result.add products
  for output in R:
    var operands: seq[Basis]
    for term in table[output]:
      if term.operand notin operands: operands.add term.operand
    var summands: seq[NimNode]
    for k in operands:
      var weight: NimNode = nil
      for term in table[output]:
        if term.operand != k: continue
        let
          product = namePair(term.pair)
          magnitude =
            case abs(term.coefficient)
            of 1: product
            of 2: infix(product, "+", product)
            else: infix(newFloatLitNode(float(abs(term.coefficient))), "*", product)
        weight =
          if weight.isNil: (if term.coefficient < 0: prefix(magnitude, "-") else: magnitude)
          else: infix(weight, if term.coefficient < 0: "-" else: "+", magnitude)
      let bk = emitBasis(k)
      summands.add infix(weight, "*", quote do: `m`[`bk`])
    let
      b = emitBasis(output)
      value = emitSum(summands)
    result.add quote do:
      `r`[`b`] = `value`


func `⟇⟇~∘`*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B],
): typeof(zeroNamed[basesSandwiched(A, B)]()) {.inline, noinit.} =
  ## Transform multivector by operator of any types, i.e. 𝐧 ⟇ 𝐦 ⟇ 𝐧̰, from table of both types.
  emitSandwichedByBasis(basesSandwiched(A, B), A, B, result, m, n)


func `⟇⟇~∘`*(m, n: Multivector): Multivector {.inline.} =
  ## Transform full multivector by full operator, i.e. 𝐧 ⟇ 𝐦 ⟇ 𝐧̰, through three steps of pin.
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
  ## TODO: Document.
```

```nim
func projectOrthogonalAnti*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B],
): auto {.inline.} = n ∧ (m ∨☆ n)
  ## TODO: Document.

func transform*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B],
): auto {.inline.} = m ⟇⟇~∘ n
  ## Transform multivector by operator, i.e. 𝐧 ⟇ 𝐦 ⟇ 𝐧̰, reading table of both types.
```

## Edit `tests/suites.nim`

```nim
const EMPTY: Bases = {}
```

```nim
template checkTypedSandwich(A, B: static Bases) =
  ## Check typed sandwich of samples over `A` by samples over `B` near chain of full forms.
  ##   Table and chain sum their terms in other orders, so they agree within tolerance alone.
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


  test "Sandwich: equal chain exactly for full operands, and alias reads operator":
    for (m, n, _) in sampleMultivectors():
      checkSame(m ⟇⟇~∘ n, (n ⟇ m) ⟇ (~∘ n))
    let (v, e) = (sampleOf[VECTORS](), sampleOf[EVEN]())
    check transform(v, e).toMultivector =~ (v ⟇⟇~∘ e).toMultivector
```
