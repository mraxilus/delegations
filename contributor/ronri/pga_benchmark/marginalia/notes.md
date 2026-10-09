# Notes in the margin

Each note quotes lines of the library at pin, and says what a reader finds there. Status
`open` is work that nobody has proposed yet. Status `decide` is a choice for the Architect.
Status `proposal` names a proposal that explores the note.

`drive` holds each quote to the pin. A quote that does not occur once at pin is a finding, so
a note never points at lines that say something else.

## Every operand is dense

`pga/multivectors.nim` · proposal

```nim
type
  Multivector* = object  ## Define generalised multivector for n-dimensional PGA.
```

A point carries all 2^D slots, and each product reads every slot. Of the measurands with a
typed reference, most spend more multiplies than the reference, and this is why.

Grade restriction lives in the emission, and the tables stay whole. Proposal P04,
`exact-kinds`, explores concrete kinds that hold only the bases a product reaches.

## What an out-of-range grade does

`pga/multivectors.nim` · decide

```nim
func `{}`*[G: Grade | GradeAnti](m: Multivector, grade: G): Multivector =
  ## Select (anti)grade-vector part from multivector, i.e. ⟨𝐦⟩k or ⟨𝐦⟩𝕜.
  let g = when G is GradeAnti: grade.toBase else: grade
  for b in LUT_BASES_BY_GRADE[g]:
    result[b] = m[b]
```

`m{Grade(5)}` in a 4D algebra indexes `LUT_BASES_BY_GRADE` past its end, and raises
`IndexDefect` in debug and in release. That can be the right contract, but the doc string does
not say so.

The Architect decides: raise, return zero, or reject at compile time.

## Whether `isMixed` is part of the surface

`pga/multivectors.nim` · decide

```nim
template isMixed(m: Multivector): bool = m.grade.isNone
  ## Determine if multivector is mixed grade.
```

`isMixed` is private, and the suites reach it through `{.all.}`. A private name that works
only under `{.all.}` is the shape that once hid a broken grade table from the suites. Export it
with the other grade predicates, or let the suites define their own.

## Scalar-valued products return a whole multivector

`pga/operators.nim` · proposal

```nim
func `|∙`*(m: Multivector): Multivector {.inline.} =
  ## Get (round) bulk norm of multivector as size of (round) bulk components.
  ##   I.e. ‖𝐦‖∙ = √(𝐦∙𝐦).
  result[Basis.scalar] = (`|∙²`m)[Basis.scalar].sqrt
```

`∙ ∘`, the squared norms and the norms each write a full multivector to carry one double.
For those operations, the result alone puts them above the byte bound.

An emitter that returns `float`, for a table whose products all land in one slot, closes that.
Proposal P04, `exact-kinds`, returns the kind of exactly the bases that the result reaches,
which here is one slot.

## What the flat norms compute

`pga/operators.nim` · decide

```nim
when IS_CONFORMAL:
  func `|■`*(m: Multivector): Multivector {.inline.} =
    ## Get flat bulk norm of multivector as size of flat bulk components, i.e. ‖𝐦‖∙ = √(𝐦∙𝐦).
    result[Basis.scalar] = (m ∙ m)[Basis.scalar].sqrt

  func `|□`*(m: Multivector): Multivector {.inline.} =
    ## Get flat weight norm of multivector as size of flat weight components, i.e. ‖𝐦‖∘ = √(𝐦∘𝐦).
    result[Basis.scalarAnti] = (m ∘ m)[Basis.scalarAnti].sqrt
```

The round norms read the squared operators `|∙²` and `|∘²`. The flat norms compute `m ∙ m`
and `m ∘ m` in full. Both give the same value, so the flat norms and the round norms cannot
both be right. The correct formula is a question for the book.

## Why five conformal law suites fail

`tests/suites.nim` · open

```nim
  test "Equation 2.87-89":
```

Change `norm-ungate` removes the conformal gates, and five suites then fail: 2.87-89,
2.90-94, 2.97-98, 2.99 and 2.103. 2.88 and 2.89 compare against plain `sqrt`, which is NaN
where the weight dot is negative. 2.103 is `★𝐦 =~ /(∙𝐦)`, which is not a norm law.

## Open import of `algebra.nim` in `cayleys.nim`

`pga/cayleys.nim` · open

```nim
import ./algebra {.all.}
```

`import ./[algebra {.all.}]` opens the module boundary. This file needs `complement`,
`toFlags`, `toDigits` and the `BasisFlags` operations. They are private in `algebra.nim`, and
marked `{.used.}`.

Export them with a doc line that says they are internal. Change `imports-narrow` does the same
for `operators.nim`.

## Whether the squared norms are public

`pga/operators.nim` · decide

```nim
defineOperator(
  symbols = "|∙²",
  docs = """Get (round) bulk squared norm of multivector,
  as squared size of (round) bulk components.
  I.e. ‖𝐦‖∙² = 𝐦∙𝐦.""",
  cayley = CAYLEYS_NORM_SQUARED.base,
  as_unary = true,
)
```

`|∙²` and `|∘²` are useful in their own right. Neither has an alias or a row in the operator
tables of `pga.nim`. `²` is not an operator character, so a caller must spell each in
backticks.

If they are public, they need aliases and table rows. If they only serve other operators,
make them private.

## Projections chain full products through intermediates

`pga.nim` · open

```nim
func projectCentral*(m, n: Multivector): Multivector {.inline.} = n ∨ (m ∧★ n)
```

Each projection chains a dual product and a full product. So it fills, holds intermediates
and copies. Its multiplies are at the bound, and its bytes are not. A generated two-step chain
removes the intermediates; the docket shows each projection against the bound.

## `Formal.round` under the rigid metric

`pga/cayleys.nim` · decide

```nim
  Formal*[T] = object
    when IS_CONFORMAL:
      flat*, round*: T
    else:
      round*: T
```

Under the rigid metric, `Formal` has one field, `round`, and nothing in a rigid algebra is
round. Change `doc-comments-2` says so in a comment. A rename moves every `CAYLEYS_PARTS`
call site with it, so the Architect decides.

## Unary part extractions against their fill

`pga/operators.nim` · open

```nim
      ident"Multivector",
      nnkIdentDefs.newTree(ident"m", ident"Multivector", newEmptyNode()),
    ),
    pragma = nnkPragma.newTree(ident"inline", ident"noinit"),
```

Unary operators write every slot, with `noinit`. The bench fills each result array with
zeros once, and the compiler can delete each store of zero that repeats that fill. So the
bench can favour a form that fills over one that writes every slot. Timed alone, the form
that writes every slot does not lose.

## Binary products against their fill

`pga/operators.nim` · open

```nim
    params = nnkFormalParams.newTree(ident"Multivector", ident_defs),
    pragma = nnkPragma.newTree(ident"inline", ident"noinit"),
```

Binary products also write every slot, with `noinit`. The same effect of the bench applies:
`∨★` measured slower than a form with a fill, and timed alone it does not lose.

## Partner scans grade at run time

`pga/operators.nim` · open

```nim
  func `⊛`*(m: Multivector): Multivector =
    ## Get partner of multivector, i.e. (-1)^(grade(𝐦)+1) (𝐦☆)⊡ ∨ 𝐦⊟.
    let sign = float(-1^(int(m.grade.get) + 1))
    sign * ⊡(☆m) ∨ ⊟m
```

`⊛` reads `m.grade.get`, which scans every slot. The sign (−1)^(grade+1) can fold into the
first table, by the grade of the first factor of each term. That is exact under the
homogeneity that `⊛` already asserts.

Partner is then a two-step chain of generated products. Change `partner-guard` asserts the
precondition until then.

## Whether 𝐞̄ₙ₋₁ is the conformal horizon

`pga/cayleys.nim` · decide

```nim
func horizon(t: typedesc[Basis]): BasisSigned {.compileTime.} =
  ## Alias basis representing horizon (i.e. 𝐞̄ₙ in RGA; 𝐞̄ₙ₋₁ in CGA).
  ##   TODO: Is 𝐞̄ₙ₋₁ horizion in conformal?
  Basis.origin.complement(Chirality.Right)
```

The library asks this in a TODO. At 5D, the typed reference defines the attitude as
`𝐚 ∨ 𝐞̄₄`, and the generated attitude passes the conformal suite against it. The other conformal
dimensions are unchecked.

## Norm returns a multivector for two doubles

`pga.nim` · proposal

```nim
func norm*(m: Multivector): Multivector {.inline.} = |m
  ## Get geometric norm of multivector as distance from origin.
```

The book writes ‖𝐦‖ = s𝟏 + t𝟙, and a `Multivector` result mirrors that exactly. The cost is
movement: `|` fills and writes all 2^D slots to hand back two. Proposal P04, `exact-kinds`,
leaves the norm out, since the norm takes a root of a squared norm.

## Support is three dense products

`pga.nim` · proposal

```nim
  func support*(m: Multivector): Multivector {.inline.} = ∩m
    ## Perform orthogonal projection of origin (i.e. eₙ) onto multivector.

  func supportAnti*(m: Multivector): Multivector {.inline.} = ∪m
    ## Perform orthogonal projection of horizon (i.e. e̅ₙ) onto multivector.
```

`∩` is `m ∨ (𝐞ₙ ∧ ☆ m)`: a dual, a wedge with a constant basis element, and an antiwedge.
The wedge with one basis element is a signed selection, not a full product. Proposal P01,
`cayley-derivation`, generates `∩` and `∪` as one table each, through map operators.
