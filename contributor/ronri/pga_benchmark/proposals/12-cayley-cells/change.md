# Cayley cells as edits at pin

Each cell of a Cayley table holds its terms in an array beside their count, in place of `seq`.
`BasesSigned` is that cell, and `TERMS_CELL` is its size: two terms under the conformal metric, and
one under the rigid metric. A new section, Cell Operations, gives the cell the calls that the
derivation and the operators make: `len`, `[]`, `items`, `$` and `add`. `find` and `delete` serve
`merge` alone, so they stay private and carry `{.compileTime.}`. `toBasesSigned` makes a cell of one
term, as `@[term]` did.

Each constructor builds its cell with `toBasesSigned`, and each filter empties a cell with
`default(BasesSigned)`. `merge` finds a term with `find` of the cell, so `sequtils` leaves the
imports. `slice` takes its cell as it is, since that cell holds one term or none.
`constructExomorphismMetric` takes the one term of each vector cell with `toSigned`, as the other
constructors do. Every exported table keeps its name, its dimensions and its terms.

The module doc of `pga.nim` gives the order of compile-time type bootstrapping, so it names
`BasesSigned` between `BasisSigned` and the tables.

## Edit `pga/cayleys.nim`

```nim
import std/[bitops, sequtils, strformat]
```

```nim
import std/[bitops, strformat]
```

## Edit `pga/cayleys.nim`

```nim
type  ## Define type definitions dependent on `Basis` needed for macros.
  BasisSigned* = object  ## Define signed representation of basis.
    basis*: Basis
    is_negated*: bool = false
  Cayley1D* =  ## Define data structure for constructing unary algebra operations (map).
    array[Basis, seq[BasisSigned]]
  Cayley2D* =  ## Define data structure for constructing binary algebra operations.
    array[Basis, array[Basis, seq[BasisSigned]]]  # Support conformal operators with `seq`.
    # TODO: Avoid seq as heap allocated, perhaps array with count custom type.
    #   Applies especially for 1D which only uses singular slot.
```

```nim
const TERMS_CELL = when IS_CONFORMAL: 2 else: 1
  ## Define most terms cell of Cayley table holds.
  ##   Metric pairs no vectors but 𝐞ₙ₋₁ and 𝐞ₙ.
  ##   Product of two bases thus has two terms at most under conformal metric, one under rigid.

type  ## Define type definitions dependent on `Basis` needed for macros.
  BasisSigned* = object  ## Define signed representation of basis.
    basis*: Basis
    is_negated*: bool = false
  BasesSigned* = object  ## Define cell of Cayley table, held in place with count of its terms.
    ##   Fields keep cell plain to read.
    ##   Packed form takes about half compile time and memory of this one at cga6d.
    ##     I.e. each term in 16 bits of one `uint64`, coded 2 × basis + sign + 1.
    ##       Zero marks empty slot.
    ##     Compile-time evaluator holds integer as one node and this form as several.
    terms: array[TERMS_CELL, BasisSigned]
    count: range[0..TERMS_CELL]
  Cayley1D* =  ## Define data structure for constructing unary algebra operations (map).
    array[Basis, BasesSigned]
  Cayley2D* =  ## Define data structure for constructing binary algebra operations.
    array[Basis, array[Basis, BasesSigned]]
```

## Edit `pga/cayleys.nim`

```nim
  for i in 0..DIMENSIONS: yield Order(i)
```

```nim
  for i in 0..DIMENSIONS: yield Order(i)



#[ Cell Operations ]#

func len*(cell: BasesSigned): int = cell.count
  ## Count terms of cell.


func `[]`*(cell: BasesSigned, i: Natural): BasisSigned =
  ## Get term of cell by position.
  assert i < cell.count, &"Attempt to read term `{i}` of cell of length `{cell.count}`."
  cell.terms[i]


func `[]`*(cell: var BasesSigned, i: Natural): var BasisSigned =
  ## Get term of cell by position, to change in place.
  assert i < cell.count, &"Attempt to read term `{i}` of cell of length `{cell.count}`."
  cell.terms[i]


iterator items*(cell: BasesSigned): BasisSigned =
  ## Yield each term of cell, in order.
  for i in 0..<cell.count: yield cell.terms[i]


func `$`*(cell: BasesSigned): string = $(@(cell.terms.toOpenArray(0, cell.count - 1)))
  ## Convert cell to string of its terms.


func add*(cell: var BasesSigned, term: BasisSigned) =
  ## Add term to cell; cell already full stops build.
  assert cell.count < TERMS_CELL,
    &"Attempt to add `{term}` to full cell `{cell}`; cell holds at most `{TERMS_CELL}`."
  cell.terms[cell.count] = term
  inc cell.count


func add*(cell: var BasesSigned, terms: BasesSigned) =
  ## Add each term of another cell to cell.
  for term in terms: cell.add(term)


func find(cell: BasesSigned, term: BasisSigned): int {.compileTime.} =
  ## Find position of term in cell; -1 where absent.
  for i in 0..<cell.count:
    if cell.terms[i] == term: return i
  -1


func delete(cell: var BasesSigned, i: Natural) {.compileTime.} =
  ## Delete term of cell by position, keeping order of rest.
  assert i < cell.count, &"Attempt to delete term `{i}` of cell of length `{cell.count}`."
  for j in i ..< cell.count - 1: cell.terms[j] = cell.terms[j + 1]
  cell.terms[cell.count - 1] = default(BasisSigned)
  dec cell.count


func toBasesSigned*(term: BasisSigned): BasesSigned =
  ## Convert signed basis to singleton cayley product cell.
  result.add(term)
```

## Edit `pga/cayleys.nim`

```nim
    result[b] = @[b.complement(chirality)]
```

```nim
    result[b] = b.complement(chirality).toBasesSigned
```

## Edit `pga/cayleys.nim`

```nim
    for b in Basis:
      result[b] = @[b.toSigned]
```

```nim
    for b in Basis:
      result[b] = b.toSigned.toBasesSigned
```

## Edit `pga/cayleys.nim`

```nim
    result[b] = @[b.reverse(spatiality)]
```

```nim
    result[b] = b.reverse(spatiality).toBasesSigned
```

## Edit `pga/cayleys.nim`

```nim
      result[b] = @[b.toSigned]

  # Adjust metric to conformal structure if necessary.
  when IS_CONFORMAL:
    result[𝐞ₙ] = @[BasisSigned(basis: 𝐞ₙ₋₁, is_negated: true)]
    result[𝐞ₙ₋₁] = @[BasisSigned(basis: 𝐞ₙ, is_negated: true)]
```

```nim
      result[b] = b.toSigned.toBasesSigned

  # Adjust metric to conformal structure if necessary.
  when IS_CONFORMAL:
    result[𝐞ₙ] = BasisSigned(basis: 𝐞ₙ₋₁, is_negated: true).toBasesSigned
    result[𝐞ₙ₋₁] = BasisSigned(basis: 𝐞ₙ, is_negated: true).toBasesSigned
```

## Edit `pga/cayleys.nim`

```nim
      bases.add(result[basis])
```

```nim
      bases.add(result[basis].toSigned)
```

## Edit `pga/cayleys.nim`

```nim
    result[operand] = @[product.basis]
```

```nim
    result[operand] = product.basis.toBasesSigned
```

## Edit `pga/cayleys.nim`

```nim
    result[operand] = @[BasisSigned(
      basis: product_complement.basis,
      is_negated: product_signed.is_negated xor product_complement.is_negated,
    )]
```

```nim
    result[operand] = BasisSigned(
      basis: product_complement.basis,
      is_negated: product_signed.is_negated xor product_complement.is_negated,
    ).toBasesSigned
```

## Edit `pga/cayleys.nim`

```nim
func toSigned(product: seq[BasisSigned]): BasisSigned {.compileTime.} =
```

```nim
func toSigned(product: BasesSigned): BasisSigned {.compileTime.} =
```

## Edit `pga/cayleys.nim`

```nim
    result[operand] = @[BasisSigned(
      basis: product_signed.basis,
      is_negated: product_signed.is_negated xor basis.is_negated,
    )]
```

```nim
    result[operand] = BasisSigned(
      basis: product_signed.basis,
      is_negated: product_signed.is_negated xor basis.is_negated,
    ).toBasesSigned
```

## Edit `pga/cayleys.nim`

```nim
      cayley[operand] = @[]
      continue

    # Filter by product.
    let product_signed = cayley[operand].toSigned
    if (products.len != 0 and product_signed.basis notin products) or
        (as_exclusions and product_signed.basis in products):
      cayley[operand] = @[]
```

```nim
      cayley[operand] = default(BasesSigned)
      continue

    # Filter by product.
    let product_signed = cayley[operand].toSigned
    if (products.len != 0 and product_signed.basis notin products) or
        (as_exclusions and product_signed.basis in products):
      cayley[operand] = default(BasesSigned)
```

## Edit `pga/cayleys.nim`

```nim
        cayley[m][n] = @[]

    for n in Basis:
      if cayley[m][n].len == 0: continue

      # Filter by n operands.
      if (operands_n.len != 0 and n notin operands_n) or (as_exclusions and n in operands_n):
        cayley[m][n] = @[]
        continue

      # Filter by product.
      for b in cayley[m][n]:
        if (products.len != 0 and b.basis notin products) or
            (as_exclusions and b.basis in products):
          cayley[m][n] = @[]  # TODO: Remove only matching elements.
```

```nim
        cayley[m][n] = default(BasesSigned)

    for n in Basis:
      if cayley[m][n].len == 0: continue

      # Filter by n operands.
      if (operands_n.len != 0 and n notin operands_n) or (as_exclusions and n in operands_n):
        cayley[m][n] = default(BasesSigned)
        continue

      # Filter by product.
      for b in cayley[m][n]:
        if (products.len != 0 and b.basis notin products) or
            (as_exclusions and b.basis in products):
          cayley[m][n] = default(BasesSigned)  # TODO: Remove only matching elements.
```

## Edit `pga/cayleys.nim`

```nim
      cayley[operand] = @[]
      continue

    # Filter by product grade.
    let product_signed = cayley[operand].toSigned
    if (products.len != 0 and product_signed.basis.grade notin products) or
        (as_exclusions and product_signed.basis.grade in products):
      cayley[operand] = @[]
```

```nim
      cayley[operand] = default(BasesSigned)
      continue

    # Filter by product grade.
    let product_signed = cayley[operand].toSigned
    if (products.len != 0 and product_signed.basis.grade notin products) or
        (as_exclusions and product_signed.basis.grade in products):
      cayley[operand] = default(BasesSigned)
```

## Edit `pga/cayleys.nim`

```nim
        cayley[m][n] = @[]

    for n in Basis:
      if cayley[m][n].len == 0: continue

      # Filter by n operands.
      if (operands_n.len != 0 and n.grade notin operands_n) or
          (as_exclusions and n.grade in operands_n):
        cayley[m][n] = @[]
        continue

      # Filter by product.
      for b in cayley[m][n]:
        if (products.len != 0 and b.basis.grade notin products) or
            (as_exclusions and b.basis.grade in products):
          cayley[m][n] = @[]  # TODO: Remove only matching elements.
```

```nim
        cayley[m][n] = default(BasesSigned)

    for n in Basis:
      if cayley[m][n].len == 0: continue

      # Filter by n operands.
      if (operands_n.len != 0 and n.grade notin operands_n) or
          (as_exclusions and n.grade in operands_n):
        cayley[m][n] = default(BasesSigned)
        continue

      # Filter by product.
      for b in cayley[m][n]:
        if (products.len != 0 and b.basis.grade notin products) or
            (as_exclusions and b.basis.grade in products):
          cayley[m][n] = default(BasesSigned)  # TODO: Remove only matching elements.
```

## Edit `pga/cayleys.nim`

```nim
    if should_filter:
      cayley[operand] = @[]
```

```nim
    if should_filter:
      cayley[operand] = default(BasesSigned)
```

## Edit `pga/cayleys.nim`

```nim
          position = destination[m][n].findIt(it == term_cancel)
```

```nim
          position = destination[m][n].find(term_cancel)
```

## Edit `pga/cayleys.nim`

```nim
    result[b] = if terms.len == 1: @[terms.toSigned] else: @[]
```

```nim
    result[b] = terms
```

## Edit `pga.nim`

```nim
##   BasisSigned -> [Cayley1D, Cayley2D]
```

```nim
##   BasisSigned -> BasesSigned -> [Cayley1D, Cayley2D]
```
