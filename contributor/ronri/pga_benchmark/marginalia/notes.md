# Notes in the margin

Each note quotes lines of the library at pin, and says what a reader finds there. Status
`open` is work that nobody has proposed yet. Status `decide` is a choice for the Architect.
Status `proposal` names a proposal that explores the note. Status `ruled` is a choice that the
Architect made, with what it costs.

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

## What the conformal norms compute

`pga/operators.nim` · open

```nim
when IS_CONFORMAL:
  func `|■`*(m: Multivector): Multivector {.inline.} =
    ## Get flat bulk norm of multivector as size of flat bulk components, i.e. ‖𝐦‖∙ = √(𝐦∙𝐦).
    result[Basis.scalar] = (m ∙ m)[Basis.scalar].sqrt

  func `|□`*(m: Multivector): Multivector {.inline.} =
    ## Get flat weight norm of multivector as size of flat weight components, i.e. ‖𝐦‖∘ = √(𝐦∘𝐦).
    result[Basis.scalarAnti] = (m ∘ m)[Basis.scalarAnti].sqrt
```

The round norms read the squared operators `|∙²` and `|∘²`, and the flat norms compute `m ∙ m`
and `m ∘ m` in full. So all four take the dot or the antidot of the whole multivector. Under the
conformal metric the antimetric is the negative of the metric, so `m ∘ m` is exactly `-(m ∙ m)`.
One root of the two is then NaN for each nonzero multivector. Of the 256 seeded multivectors of
P10, `|∘` gives NaN for 114 at cga5d and 141 at cga4d, and `|∙` gives NaN for each other one.

The book splits a conformal object into four parts, by its factors of e4 and e5, in Section 4.3.
The round bulk, round weight, flat bulk and flat weight norms each measure the size of one part,
in Table 4.12. For each round object 𝐮 • 𝐮 = −r², in (4.44), and the radius norm is √(𝐮 ∘ 𝐮), in
(4.45). So at pin, `|∙` and `|■` give NaN for each real round object. `|∘` and `|□` give the value
of the radius norm, which `pga.nim` lists as `|⊘` and stubs, and neither gives a weight norm of the
book. Change `conformal-norms` moves them to the four norms of the book, and fills `|⊙` and `|⊘`.

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
movement: `|` fills and writes all 2^D slots to hand back two. Proposal P10, `magnitude`, holds
the pair as a kind of P04, `exact-kinds`, with a root and a division of its own.

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

## Unitization keeps the sign of the weight

`pga.nim` · ruled

```nim
func unitize*(m: Multivector): Multivector {.inline.} = ^m
  ## Normalize multivector so weight norm has unit antiscalar magnitude, i.e. 𝐦̂ = 𝐦 / ‖𝐦‖∘.
  ##   Shorthand for weight normalization, i.e. weight has magnitude of one.
  ##   Projects higher-dimensional representations of objects into Eucledian space.
  ##     By scaling weight of 𝐦 to unit magnitude.
```

`^` divides by the weight norm, which is a root and so positive. So a negative weight stays
negative, and w = −2 unitizes to w = −1. The book asks only that the round weight norm have unit
magnitude, in Section 4.3, and the wiki asks only w² = 1 of a point. `unitize` projects into
Euclidean space only where the weight is positive. Elsewhere (x, y, z) holds the mirror image of
the position, and a caller divides by w to read it. The order of operands sets the sign: planes
x = 1, y = 2 and z = 3 meet at (1, 2, 3, 1) as g1 ∨ g2 ∨ g3, and at (−1, −2, −3, −1) as
g2 ∨ g1 ∨ g3. `^` leaves both as they are.

Lengyel's code fixes the sign where the weight is one coordinate. `Unitize` divides a point and a
round point by the signed w, so w = 1, and for a point it returns `Point3D`, three floats with an
implicit w. It multiplies a sphere by −1/u, so u = −1, since `Dual` of a round point with w = 1 is
the sphere with u = −1 and the same center. Lines, planes, dipoles and circles keep their sign in
both. The Architect chose the rule of the book on 2026-10-10, since `unitize` takes any
multivector, and the sign of the code needs the type of the object. The typed reference here takes
the same rule.

In 64-bit floats, a unitized point takes 24 bytes in place of 32, and it spends less:

| Operation | Homogeneous | Unitized | Saved |
|-----------|-------------|----------|-------|
| Join of two points | 12 mul, 6 sub | 6 mul, 6 sub | 6 mul |
| Join of line and point | 12 mul, 8 add | 9 mul, 8 add | 3 mul |
| Meet of point and plane | 4 mul, 3 add | 3 mul, 3 add | 1 mul |
| Antisupport | 6 mul, 2 add | 3 mul, 2 add | 3 mul |
| Transform by motor | 25 mul, 18 add | 21 mul, 18 add | 4 mul |
| Unitize, book against code | 1 abs, 1 div, 4 mul | 1 div, 3 mul | 1 abs, 1 mul |

The verb `unitized` times each pair twice, and `baseline/unitized.json` holds the medians, taken
on 2026-10-10 on linux amd64, 4 cores. Each ratio is unitized time over homogeneous time, over
1024 points in cache and 1,048,576 streamed from memory. Padded is the unitized point in 32
bytes, so it shows the saved arithmetic apart from the smaller layout.

| Operation | In cache | Padded, in cache | From memory | Padded, from memory |
|-----------|----------|------------------|-------------|---------------------|
| Join of two points | ×2.19 to ×2.26 | ×2.20 to ×2.27 | ×0.66 to ×0.88 | ×0.77 to ×1.03 |
| Join of line and point | ×1.06 to ×1.08 | ×1.06 to ×1.07 | ×0.79 to ×0.80 | ×0.94 to ×0.96 |
| Meet of point and plane | ×0.96 | ×0.98 | ×0.92 to ×1.06 | ×0.95 to ×0.99 |
| Antisupport | ×0.90 | ×0.98 to ×0.99 | ×0.89 to ×0.90 | ×0.96 to ×0.97 |
| Transform by motor | ×0.84 | ×0.85 | ×0.93 to ×0.99 | ×0.98 to ×1.04 |
| Unitize, code against book | ×1.06 to ×1.08 | ×1.07 to ×1.08 | ×0.95 to ×0.99 | ×0.98 to ×1.05 |

The null pair reads ×0.99 to ×1.00 in cache, and ×0.84 to ×1.09 from memory. In cache the
transform gains a sixth in both layouts, so its saved multiplies show. The join of two points
loses ×2.2 in both layouts, likely because the homogeneous join vectorises into packed
multiplies and the unitized one does not. From memory, three floats in place of four save a fifth
on the join of line and point, and padded they save almost nothing, so bytes carry that gain. The
saving is small and selective, and only a typed point with an implicit weight reaches it.
