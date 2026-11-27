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
  EntriesSandwich = object  ## Define entries of one form, by output and basis that multiplies each.
    entries: array[Basis, array[Basis, seq[TermSandwich]]]  ## Terms of each entry.
    keys: array[Basis, Bases]  ## Bases that multiply entries of each output.
    found: array[Basis, array[Basis, int]]  ## Distinct entry that each coefficient reads.
    firsts: seq[(Basis, Basis)]  ## Output and basis that first read each distinct entry.
    readers: seq[int]  ## Coefficients that read each distinct entry.


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
  ##   Builds table and cross forms, counts chain, and keeps form of fewest multiplies, adds and
  ##     subtractions, each counted once, so choice reads Cayley tables alone and holds on every
  ##     machine. Tie keeps earlier form: table, then cross.
  ##   Table form names product of each pair once. Cross pair reads one of its bases doubled:
  ##     basis in most cross pairs left, until each pair holds one, so few bases are doubled.
  ##   Cross form reads each pair across bulk and weight of `n` as chain: bulk basis times `m`
  ##     first, as bulk comes first, then weight basis. Its term keeps fold of bulk basis and
  ##     basis of `m` as pair, and weight basis as operand. Its sum stands for both orders, so
  ##     result adds it twice.
  ##   Both forms name once each entry that several coefficients read, up to sign. Entry lists its
  ##     terms in order of pairs, as table walks them, so equal entries compare term by term
  ##     among entries of same first pair.
  ##   Chain form spells 𝐧 ⟇ 𝐦 ⟇ 𝐧̰ through typed antiproducts, counted term by term from their
  ##     table. It wins where both operands hold many bases, as bivector by motor at cga5d does.
  ##   Loops walk terms, pairs, or entries of one first pair, so table at six dimensions stays
  ##     under loop bound of VM.
  func nameDoubled(b: Basis): NimNode = ident("doubled_" & $b)
  func namePair(pair: array[2, Basis]): NimNode = ident("pair_" & $pair[0] & "_" & $pair[1])
  func nameFold(pair: array[2, Basis]): NimNode = ident("fold_" & $pair[0] & "_" & $pair[1])
  func sign(terms: seq[TermSandwich]): int = (if terms[0].coefficient < 0: -1 else: 1)

  func isSame(a, b: seq[TermSandwich]): bool =
    if a.len != b.len: return false
    let s = sign(a) * sign(b)
    for x in 0 ..< a.len:
      if a[x].pair != b[x].pair or a[x].coefficient != s * b[x].coefficient: return false
    true

  func emitEntry(terms: seq[TermSandwich], factor: int, is_folded: bool): NimNode =
    for term in terms:
      let
        coefficient = factor * term.coefficient
        product = if is_folded: nameFold(term.pair) else: namePair(term.pair)
        magnitude =
          case abs(coefficient)
          of 1: product
          of 2: infix(product, "+", product)
          else: infix(newFloatLitNode(float(abs(coefficient))), "*", product)
      result =
        if result.isNil: (if coefficient < 0: prefix(magnitude, "-") else: magnitude)
        else: infix(result, if coefficient < 0: "-" else: "+", magnitude)

  func countOperations(x: NimNode): int =
    if x.kind == nnkInfix and x[0].repr in ["*", "+", "-"]: result = 1
    for child in x: result += countOperations(child)

  func countChain(): int =
    let product = CAYLEYS_WEDGE_DOT.anti
    var
      reached: Bases
      first, second: array[Basis, int]  # Terms that each output of each antiproduct sums.
    for x in B:
      for y in A:
        for term in product[x][y]:
          inc first[term.basis]
          reached.incl term.basis
    for x in reached:
      for y in B:
        for term in product[x][y]: inc second[term.basis]
    for b in Basis:
      result += first[b] + second[b]
      if first[b] > 0: result += first[b] - 1
      if second[b] > 0: result += second[b] - 1

  func share(terms: CayleySandwich): EntriesSandwich =
    var starting: array[Basis, array[Basis, seq[int]]]  # Distinct entries by their first pair.
    for output in Basis:
      for term in terms[output]:
        result.keys[output].incl term.operand
        result.entries[output][term.operand].add term
      for k in result.keys[output]:
        let
          group = result.entries[output][k]
          (i, j) = (group[0].pair[0], group[0].pair[1])
        var index = -1
        for x in starting[i][j]:
          if isSame(result.entries[result.firsts[x][0]][result.firsts[x][1]], group):
            index = x
            break
        if index < 0:
          index = result.firsts.len
          result.firsts.add (output, k)
          result.readers.add 0
          starting[i][j].add index
        inc result.readers[index]
        result.found[output][k] = index

  func readEntry(
    s: EntriesSandwich, output, k: Basis, prefix: string, is_folded: bool,
    is_named: var seq[bool], lets: NimNode,
  ): NimNode =
    let
      terms = s.entries[output][k]
      index = s.found[output][k]
    if s.readers[index] > 1 and (terms.len > 1 or abs(terms[0].coefficient) > 1):
      let name = ident(prefix & $index)
      if not is_named[index]:
        lets.add newIdentDefs(name, newEmptyNode(), emitEntry(terms, sign(terms), is_folded))
        is_named[index] = true
      if sign(terms) < 0: prefix(name, "-") else: name
    else:
      emitEntry(terms, 1, is_folded)

  func emitTable(table: CayleySandwich, weight: Bases, is_crossed: bool): NimNode =
    var tabled, folded: CayleySandwich  # Terms that table reads, and cross terms read as chain.
    for output in Basis:
      for term in table[output]:
        let (i, j) = (term.pair[0], term.pair[1])
        if is_crossed and i != j and (i in weight) != (j in weight):
          let (a, b) = if i in weight: (j, i) else: (i, j)
          folded[output].add TermSandwich(
            operand: b, pair: [a, term.operand], coefficient: term.coefficient
          )
        else:
          tabled[output].add term
    var
      pairs, folds: seq[array[2, Basis]]
      paired, folded_with: array[Basis, Bases]  # Bases that pair or fold with each so far.
      open: seq[array[2, Basis]]  # Cross pairs that no doubled basis holds yet.
      doubled: Bases
    for output in Basis:
      for term in tabled[output]:
        let (i, j) = (term.pair[0], term.pair[1])
        if j notin paired[i]:
          paired[i].incl j
          pairs.add term.pair
          if i != j: open.add term.pair
      for term in folded[output]:
        let (a, k) = (term.pair[0], term.pair[1])
        if k notin folded_with[a]:
          folded_with[a].incl k
          folds.add term.pair
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
    let
      entries_table = share(tabled)
      entries_fold = share(folded)
    result = newStmtList()
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
    for fold in folds:
      let
        ba = emitBasis(fold[0])
        bk = emitBasis(fold[1])
      products.add newIdentDefs(nameFold(fold), newEmptyNode(), quote do: `n`[`ba`] * `m`[`bk`])
    if products.len > 0: result.add products
    var
      shared = newNimNode(nnkLetSection)  # Entries that several coefficients read, named once.
      sums = newNimNode(nnkLetSection)  # Cross part of each output, which result adds twice.
      is_named_table = newSeq[bool](entries_table.firsts.len)
      is_named_fold = newSeq[bool](entries_fold.firsts.len)
      assignments = newStmtList()
    for output in Basis:
      if table[output].len == 0: continue
      var summands: seq[NimNode]
      for k in entries_table.keys[output]:
        let
          entry = readEntry(entries_table, output, k, "entry_", false, is_named_table, shared)
          bk = emitBasis(k)
        summands.add infix(entry, "*", quote do: `m`[`bk`])
      if entries_fold.keys[output].card > 0:
        var crossed: seq[NimNode]
        for b in entries_fold.keys[output]:
          let
            entry = readEntry(entries_fold, output, b, "folded_", true, is_named_fold, shared)
            bb = emitBasis(b)
          crossed.add infix(entry, "*", quote do: `n`[`bb`])
        let name = ident("crossed_" & $output)
        sums.add newIdentDefs(name, newEmptyNode(), emitSum(crossed))
        summands.add name
        summands.add name
      let
        b = emitBasis(output)
        value = emitSum(summands)
      assignments.add quote do:
        `r`[`b`] = `value`
    if shared.len > 0: result.add shared
    if sums.len > 0: result.add sums
    result.add assignments

  func emitChain(table: CayleySandwich): NimNode =
    let chained = genSym(nskLet, "chained")
    result = newStmtList(quote do:
      let `chained` = (`n` ⟇ `m`) ⟇ (~∘ `n`))
    for output in Basis:
      if table[output].len == 0: continue
      let b = emitBasis(output)
      result.add quote do:
        `r`[`b`] = `chained`[`b`]

  let table = constructSandwich(A, B)
  var weight: Bases  # Bases of `n` in its weight, as library parts it.
  for b in B:
    if CAYLEYS_PARTS.weight.round[b].len > 0: weight.incl b
  let
    tabled = emitTable(table, weight, false)
    crossed = emitTable(table, weight, true)
    counts = [countOperations(tabled), countOperations(crossed), countChain()]
  result =
    if counts[2] < counts[0] and counts[2] < counts[1]: emitChain(table)
    elif counts[1] < counts[0]: crossed
    else: tabled


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
