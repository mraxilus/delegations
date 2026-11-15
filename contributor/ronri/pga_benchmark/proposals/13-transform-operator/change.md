# One generated operator for the transform of a multivector by a motion operator

`constructSandwich` expands 𝐧 ⟇ 𝐦 ⟇ 𝐧̰ into a table of terms over pairs of antieven bases of 𝐧.
A third `defineOperator` turns that table into the operator `⟇⟇~∘`, and `pga.nim` names it
`transform`. Every edit quotes text of pin.

## Edit `pga/cayleys.nim`

```nim
  Spatial*[T] = object
    base*, anti*: T
```

```nim
  Spatial*[T] = object
    base*, anti*: T

type  ## Define type definitions for constructing sandwich of multivector by operator.
  TermSandwich* = object  ## Define one term c 𝐧ᵢ𝐧ⱼ𝐦ₖ of sandwich of 𝐦 by 𝐧.
    operand*: Basis  ## Basis k of transformed multivector 𝐦.
    pair*: array[2, Basis]  ## Bases i <= j of operator 𝐧; cross pair i < j reads (𝐧ᵢ + 𝐧ᵢ)𝐧ⱼ.
    coefficient*: int  ## Signed weight of product of pair, halved for cross pair.
  CayleySandwich* =  ## Define data structure for constructing sandwich of multivector by operator.
    array[Basis, seq[TermSandwich]]
```

## Edit `pga/cayleys.nim`

```nim
const
  CAYLEYS_WEDGE_DOT* = Spatial[Cayley2D](
    base: constructProductGeometric(CAYLEYS_WEDGES_TRANS.base),
    anti: constructProductGeometric(CAYLEYS_WEDGES_TRANS.anti),
  )
```

```nim
const
  CAYLEYS_WEDGE_DOT* = Spatial[Cayley2D](
    base: constructProductGeometric(CAYLEYS_WEDGES_TRANS.base),
    anti: constructProductGeometric(CAYLEYS_WEDGES_TRANS.anti),
  )

const
  CAYLEY_TRANSFORM* = constructSandwich(CAYLEYS_WEDGE_DOT.anti, CAYLEYS_REVERSE.anti)
    ## Sandwich 𝐧 ⟇ 𝐦 ⟇ 𝐧̰ over antieven bases of 𝐧, which are all that motion operator holds.
```

## Edit `pga/cayleys.nim`

```nim
#[ Basis Transformations ]#
```

```nim
func constructSandwich(product: Cayley2D, reverse: Cayley1D): CayleySandwich {.compileTime.} =
  ## Construct sandwich 𝐧 ⟇ 𝐦 ⟇ 𝐧̰ as map quadratic in antieven coefficients of 𝐧.
  ##   Term 𝐧ᵢ𝐦ₖ𝐧ⱼ lands where 𝐞ᵢ ⟇ 𝐞ₖ ⟇ 𝐞̰ⱼ does. Coefficients commute, so pair i < j sums both
  ##     orders, which comes out even in each algebra, and keeps half, as its product reads
  ##     doubled 𝐧ᵢ. So each rigid term weighs ±1.
  ##   Walks each pair and operand basis once, so no term is searched for; VM bounds iterations.
  for i in Basis:
    if int(i.gradeAnti) mod 2 != 0: continue
    for j in Basis:
      if ord(j) < ord(i) or int(j.gradeAnti) mod 2 != 0: continue
      let orders = if i == j: @[(i, j)] else: @[(i, j), (j, i)]
      for k in Basis:
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



#[ Basis Transformations ]#
```

## Edit `pga/operators.nim`

```nim
#[ Operator Macros ]#
```

```nim
#[ Operator Macros ]#

macro defineOperator(
  symbols, docs: static[string];
  cayley: static[CayleySandwich];
): untyped =
  ## Construct sandwich of multivector by operator using provided table.
  ##   Names product of each pair of operator once, so each coefficient reads products alone.

  # Determine pairs read, and bases of operator that cross pairs read doubled.
  var
    pairs: seq[array[2, Basis]]
    doubled: set[Basis]
  for b in Basis:
    for term in cayley[b]:
      if term.pair notin pairs: pairs.add term.pair
      if term.pair[0] != term.pair[1]: doubled.incl term.pair[0]

  # Name each doubled basis, then product of each pair.
  func nameDoubled(b: Basis): NimNode = ident("doubled_" & $b)
  func namePair(pair: array[2, Basis]): NimNode = ident("pair_" & $pair[0] & "_" & $pair[1])
  var products = newNimNode(nnkLetSection)
  for b in doubled:
    let source = nnkBracketExpr.newTree(ident"n", ident($b))
    products.add newIdentDefs(nameDoubled(b), newEmptyNode(), infix(source, "+", source))
  for pair in pairs:
    let
      first =
        if pair[0] == pair[1]: nnkBracketExpr.newTree(ident"n", ident($pair[0]))
        else: nameDoubled(pair[0])
      second = nnkBracketExpr.newTree(ident"n", ident($pair[1]))
    products.add newIdentDefs(namePair(pair), newEmptyNode(), infix(first, "*", second))

  # Construct each coefficient as sum over operand bases of weighted products times operand.
  var assignments = newStmtList(products)
  for b in Basis:
    var operands: seq[Basis]
    for term in cayley[b]:
      if term.operand notin operands: operands.add term.operand
    var expression = newFloatLitNode(0.0)
    for (index, k) in operands.pairs:
      var weight: NimNode = nil
      for term in cayley[b]:
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
      let summand = infix(weight, "*", nnkBracketExpr.newTree(ident"m", ident($k)))
      expression = if index == 0: summand else: infix(expression, "+", summand)
    assignments.add newAssignment(nnkBracketExpr.newTree(ident"result", ident($b)), expression)

  # Construct function definition from generated assignments.
  emitFunc(
    name = symbols,
    docs = docs,
    params = nnkFormalParams.newTree(
      ident"Multivector",
      nnkIdentDefs.newTree(ident"m", ident"n", ident"Multivector", newEmptyNode()),
    ),
    pragma = nnkPragma.newTree(ident"inline", ident"noinit"),
    body = assignments,
    is_quoted = true,
    is_public = true,
  )
```

## Edit `pga/operators.nim`

```nim
defineOperator(
  symbols = "⟇",
  docs = "Multiply multivectors through geometric antiproduct, i.e. 𝐦 ⟇ 𝐧.",
  cayley = CAYLEYS_WEDGE_DOT.anti,
)
```

```nim
defineOperator(
  symbols = "⟇",
  docs = "Multiply multivectors through geometric antiproduct, i.e. 𝐦 ⟇ 𝐧.",
  cayley = CAYLEYS_WEDGE_DOT.anti,
)
defineOperator(
  symbols = "⟇⟇~∘",
  docs = "Transform multivector by motion operator, i.e. 𝐧 ⟇ 𝐦 ⟇ 𝐧̰, reading antieven part of 𝐧.",
  cayley = CAYLEY_TRANSFORM,
)
```

## Edit `pga.nim`

```nim
##   | ∧☆  | expandWeight          | 𝐦 ∧ 𝐧☆       |
```

```nim
##   | ∧☆  | expandWeight          | 𝐦 ∧ 𝐧☆       |
##   | ⟇⟇~∘| transform             | 𝐧 ⟇ 𝐦 ⟇ 𝐧̰     |
```

## Edit `pga.nim`

```nim
func expandWeight*(m, n: Multivector): Multivector {.inline.} = m ∧☆ n
  ## Multiply multivectors through right inner product weight expansion, i.e. 𝐦 ∧ 𝐧☆.
```

```nim
func expandWeight*(m, n: Multivector): Multivector {.inline.} = m ∧☆ n
  ## Multiply multivectors through right inner product weight expansion, i.e. 𝐦 ∧ 𝐧☆.

func transform*(m, n: Multivector): Multivector {.inline.} = m ⟇⟇~∘ n
  ## Transform multivector by motion operator, i.e. 𝐧 ⟇ 𝐦 ⟇ 𝐧̰, reading antieven part of 𝐧.
```
