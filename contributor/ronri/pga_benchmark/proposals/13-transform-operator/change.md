# One operator for the transform of a multivector, built from the types of its operands

`⟇⟇~∘` transforms 𝐦 by 𝐧 in one call: the sandwich 𝐧 ⟇ 𝐦 ⟇ 𝐧̰, which pin spells in three steps. Its
typed form builds the table of that sandwich from the types of both operands, when the code
compiles. So each value of each type transforms exactly. A full operator takes the three steps of
pin, whatever the type of 𝐦 is. `pga.nim` names the operator `transform`, and two tests of the
suite `Typed operators` hold both to the chain. Every edit quotes text of P04.

## Edit `pga/operators.nim`

```nim
# Functions rather than templates, unlike full forms above: generic template over static bases
#   crashes compiler where called ("field 'sons' is not accessible"), in Nim 2.4.0 and devel.
```

```nim
#[ Sandwich ]#

# Sandwich 𝐧 ⟇ 𝐦 ⟇ 𝐧̰ reads table built from types of both operands, when code compiles:
#   pairs of bases of 𝐧, both orders summed, against bases of 𝐦. So each value of each type
#   transforms exactly, and motor type reads its antieven pairs alone. Full operator takes three
#   steps of pin instead, whatever type 𝐦 has: table over every pair of 𝐧 grows past them with
#   dimension, and code that needs speed types its operator.

type
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
  ## Emit one assignment per basis that table of bases `A` of `m` and pairs of `B` of `n` reaches.
  ##   Names product of each pair once. Cross pair reads one of its bases doubled: basis in most
  ##     cross pairs left, until each pair holds one, so few bases are doubled.
  ##   Names once each entry that several coefficients read, up to sign, so each sum of products
  ##     that table repeats is computed once. Entry lists its terms in order of pairs, as table
  ##     walks them, so equal entries compare term by term among entries of same first pair.
  ##   Loops walk terms, pairs, or entries of one first pair, so table at six dimensions stays
  ##     under loop bound of VM.
  func nameDoubled(b: Basis): NimNode = ident("doubled_" & $b)
  func namePair(pair: array[2, Basis]): NimNode = ident("pair_" & $pair[0] & "_" & $pair[1])
  func sign(terms: seq[TermSandwich]): int = (if terms[0].coefficient < 0: -1 else: 1)

  func isSame(a, b: seq[TermSandwich]): bool =
    if a.len != b.len: return false
    let s = sign(a) * sign(b)
    for x in 0 ..< a.len:
      if a[x].pair != b[x].pair or a[x].coefficient != s * b[x].coefficient: return false
    true

  func emitEntry(terms: seq[TermSandwich], factor: int): NimNode =
    for term in terms:
      let
        coefficient = factor * term.coefficient
        product = namePair(term.pair)
        magnitude =
          case abs(coefficient)
          of 1: product
          of 2: infix(product, "+", product)
          else: infix(newFloatLitNode(float(abs(coefficient))), "*", product)
      result =
        if result.isNil: (if coefficient < 0: prefix(magnitude, "-") else: magnitude)
        else: infix(result, if coefficient < 0: "-" else: "+", magnitude)

  let table = constructSandwich(A, B)
  var
    pairs: seq[array[2, Basis]]
    paired: array[Basis, Bases]  # Bases j that pair with i so far, so each term tests in one step.
    open: seq[array[2, Basis]]  # Cross pairs that no doubled basis holds yet.
    doubled: Bases
  for output in Basis:
    for term in table[output]:
      let (i, j) = (term.pair[0], term.pair[1])
      if j notin paired[i]:
        paired[i].incl j
        pairs.add term.pair
        if i != j: open.add term.pair
  while open.len > 0:
    var count: array[Basis, int]  # Open cross pairs that hold each basis.
    for pair in open:
      inc count[pair[0]]
      inc count[pair[1]]
    var best = open[0][0]
    for b in Basis:
      if count[b] > count[best]: best = b
    doubled.incl best
    var rest: seq[array[2, Basis]]
    for pair in open:
      if best notin pair: rest.add pair
    open = rest

  var
    entries: array[Basis, array[Basis, seq[TermSandwich]]]  # Terms by output and basis of `m`.
    operands: array[Basis, Bases]  # Bases of `m` that each output reads.
    found: array[Basis, array[Basis, int]]  # Distinct entry that each coefficient reads.
    firsts: seq[(Basis, Basis)]  # Output and basis of `m` that first read each distinct entry.
    readers: seq[int]  # Coefficients that read each distinct entry.
    starting: array[Basis, array[Basis, seq[int]]]  # Distinct entries by their first pair.
  for output in Basis:
    for term in table[output]:
      operands[output].incl term.operand
      entries[output][term.operand].add term
    for k in operands[output]:
      let
        terms = entries[output][k]
        (i, j) = (terms[0].pair[0], terms[0].pair[1])
      var index = -1
      for x in starting[i][j]:
        if isSame(entries[firsts[x][0]][firsts[x][1]], terms):
          index = x
          break
      if index < 0:
        index = firsts.len
        firsts.add (output, k)
        readers.add 0
        starting[i][j].add index
      inc readers[index]
      found[output][k] = index

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
        product =
          if pair[0] == pair[1]: quote do: `n`[`b0`] * `n`[`b1`]
          elif pair[0] in doubled: (let d = nameDoubled(pair[0]); quote do: `d` * `n`[`b1`])
          else: (let d = nameDoubled(pair[1]); quote do: `n`[`b0`] * `d`)
      products.add newIdentDefs(namePair(pair), newEmptyNode(), product)
    result.add products
  var
    shared = newNimNode(nnkLetSection)  # Entries that several coefficients read, named once.
    is_named = newSeq[bool](firsts.len)
    assignments = newStmtList()
  for output in Basis:
    if table[output].len == 0: continue
    var summands: seq[NimNode]
    for k in operands[output]:
      let
        terms = entries[output][k]
        index = found[output][k]
        bk = emitBasis(k)
      var entry: NimNode
      if readers[index] > 1 and (terms.len > 1 or abs(terms[0].coefficient) > 1):
        let name = ident("entry_" & $index)
        if not is_named[index]:
          shared.add newIdentDefs(name, newEmptyNode(), emitEntry(terms, sign(terms)))
          is_named[index] = true
        entry = if sign(terms) < 0: prefix(name, "-") else: name
      else:
        entry = emitEntry(terms, 1)
      summands.add infix(entry, "*", quote do: `m`[`bk`])
    let
      b = emitBasis(output)
      value = emitSum(summands)
    assignments.add quote do:
      `r`[`b`] = `value`
  if shared.len > 0: result.add shared
  result.add assignments


func `⟇⟇~∘`*[A, B: static Bases](
  m: MultivectorOf[A], n: MultivectorOf[B],
): typeof(zeroNamed[basesSandwiched(A, B)]()) {.inline, noinit.} =
  ## Transform multivector by operator of any types, i.e. 𝐧 ⟇ 𝐦 ⟇ 𝐧̰, from table of both types.
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
