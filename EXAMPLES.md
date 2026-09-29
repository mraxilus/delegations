# Examples

Worked examples that `CONSTITUTION.md` and `STYLE.md` point into. Each section names the rule
that it shows. Read an example where a rule alone does not settle a case. Transfer the
decision, and not the syntax.

The excerpts come from `lengyel/projective_geometric_algebra_illuminated` in the replications
repository, at commit `16dbc17`. An excerpt is verbatim, except where its note says what
changed. Where the reference holds nothing for a rule, the section carries an example
constructed in its vocabulary, and its note opens with "Constructed".

## I.6: An internal that a sibling reaches

```nim
func `and`(a, b: BasisFlags): BasisFlags {.borrow, compileTime, used.} # Used in cayleys.nim.
```

From `algebra.nim`. The function stays private, and `cayleys.nim` reaches it through `{.all.}`.
The pragma silences the unused warning, and the comment names the sibling that uses it.

## II.6: A restore issues a new revision

```nim
func restoreFrom*(frame: var Frame, snapshot: Frame) =
  ## Replace frame's whole content with snapshot, at revision no earlier state carried.
  ##   Every whole-frame replacement, i.e. undo, redo, clear, load, comes through here.
  ##     Revision only ever rises, so no two states any cache derived from share one.
  let revision_live = frame.count_edits
  frame = snapshot
  frame.count_edits = max(revision_live, snapshot.count_edits) + 1
```

Constructed. A `Frame` holds the multivectors that a page draws, and a cache of their unitized
forms is keyed on `count_edits`. The snapshot carries an old revision. A cache keyed on that
revision would serve the forms of the undone state. So the restore issues a revision newer
than any other.

## II.7: A retreat records its cost

```text
4268078 refactor(pga): remove ast generation of cayleys due to compile times
```

The subject names what was removed, and the cost that forced the removal. A later reader can
review the decision when that cost changes.

## II.9: A copy names its sibling

```ts
/* Basis names of 3D RGA as union type, mirroring Basis in algebra.nim exactly. */
type Basis = 'S' | 'E1' | 'E2' | 'E3' | 'E23' | 'E31' | 'E12' | 'E321'
```

Constructed. A page in TypeScript cannot import the enum. A union type is a check that its
compiler makes over the whole file, and an exported array of names gives no such check. So the
names are copied, and the comment names the sibling, so that a fix to one reaches the other.

## III.3: Related glyphs show their relation

```nim
##   | ∙   | bulk(Round)   (†) | 𝐦∙          |
##   | ∘   | weight(Round) (†) | 𝐦∘          |
##   | ■   | bulkFlat       †  | 𝐦■          |
##   | □   | weightFlat     †  | 𝐦□          |
##   | ★   | dualBulk          | 𝐦★          |
##   | ☆   | dualWeight        | 𝐦☆          |
```

From the operator tables in `pga.nim`, rows from two tables put together. A filled glyph is
the bulk, and a hollow glyph is its weight. The shape of the pair carries the relation, so
that a reader learns one rule and not six glyphs.

## IV.4 and IV.5: The special case lives in the return type

```nim
func grade*(b: Basis): Grade {.inline.} =
  ## Count number of vector basis elements present in factorization of basis.

func multiplyExterior(
  a, b: BasisSigned
): tuple[basis: BasisSigned; is_degenerate: bool] {.compileTime.} =
  ## Perform exterior product of two bases, reducing to its standard basis form.
  ##   If duplicate 1-vectors are present, `is_degenerate` returns true.

func grade*(m: Multivector): Option[Grade] =
  ## Get grade of multivector, if k-vector.
```

Three routines from `algebra.nim`, `cayleys.nim` and `multivectors.nim`, with their bodies left
out. Every basis has a grade, so the first returns the plain value. A degenerate product still
carries a basis, so the second returns it beside a named flag. A mixed multivector has no
grade, so the third returns an `Option`.

## IV.6: Arenas, a scratch arena, and handles

```nim
Pool* = object ## Define fixed-capacity arena of multivectors, addressed by stable handle.
  elements: array[HANDLES_MAX, Multivector] ## Per-handle geometry.
  grades: array[HANDLES_MAX, Option[Grade]] ## Per-handle grade, derived once per revision.
  bound: int ## Live extent; every walk stops here, never at HANDLES_MAX.
```

```nim
## Two lifetimes cover everything this program allocates at runtime:
##
##   |--------|--------------------------------|-------------------------------------|
##   | Arena  | Reset                          | Backs                               |
##   |--------|--------------------------------|-------------------------------------|
##   | Frame  | On next frame's swap, so last  | Draw loop's scratch: coefficients   |
##   |        | frame's bytes survive this one | one projection step assembles       |
##   |        |                                | before emitting them.               |
##   | Export | After each unit of work, i.e.  | One rendered table of products,     |
##   |        | one table written              | built once, read once.              |
##   |--------|--------------------------------|-------------------------------------|
```

Constructed. The pool is a fixed arena, and a caller holds a handle into it and never a
reference. Each dynamic buffer has one arena, and the arena owns its lifetime. A step that
needs a temporary takes it from a scratch arena that is reset as a whole.

## V.9: Acronyms a layman knows, and paths in full

```text
3D  ID  JSON  URL                                          stay
PGA  RGA  CGA                                              spelled out
projective_geometric_algebra/  tests/rigid/  test_rigid_3d.nim
```

Constructed. The first row holds acronyms that a layman meets at school, on the web and in
data. Only the field knows the names of the algebras, so a path spells them out, as the
directory of the reference does. The reference keeps `pga.nim` and `tests/rga/`, which this
rule postdates. The test file carries its word before its name.

## VI.7 and VIII.1: A claim names its register

```nim
## Heap usage avoided completely so user can fully control memory management.
##   NOTE: Partially true in current implementation, but should be at end state.
```

```nim
  # TODO: Create LUT for all possible valid basisflags instead of computing each call.
  #   Not even sure if this will provide a speed-up.
```

From the header of `pga.nim`, and from `isNegatedByJoinLexicographic` in `cayleys.nim`. The
first claim is intended, and it says so. The second cost is expected but not measured, and it
says so.

## VIII.2: The convention of the authority, and its cost

```nim
func constructAlgebra(dimensions: int): Algebra {.compileTime.} =
  ##   Follow Lengyel's basis convention as opposed to lexicographic ordering.
  ##     For pedagogical interop with standard linear algebra and related math.
  ##   Cost of deviation from lexicographical ordering:
  ##     Exterior product must round-trip bases through lexicographical ordering.
```

```nim
  #   I.e. must first map from canonical to lexicographical, compute parity, then map back.
  #   All due to using Lengyel's ordering, chosen for interop with standard linear algebra.
```

From `algebra.nim`, with the list of differences left out, and from `multiplyExterior` in
`cayleys.nim`. The definition gives the choice, the reason and the cost. The place where the
cost falls names the convention again.

## IX.3: A guard, and a floor on what passed

```nim
test "Equation 2.99":
  var passed = 0
  for 𝐦, 𝐧, _ in randMultivectors():
    if 𝐦.grade.isNone or 𝐧.grade.isNone: continue
    if 𝐦.grade.get + 𝐧.grade.get != Grade.high: continue
    inc passed
    ...
  check passed >= SAMPLES_FLOOR
```

Changed from `tests/suites.nim`: the counter and the floor are the form that IX.3 asks for, and
the reference has only the guards. The guards pass between one sample in eight and one in five,
by dimension. Without the floor, a guard that rejects every sample leaves a test that passes
with no evidence.

## X.2: Two tiers of banner

```nim
#[ Dynamic Operators ]#


#[[ Wedge ]]#

func `∧`*(s: float; m: Multivector): Multivector {.inline, noinit.} =
```

Changed from `operators.nim`: the reference writes the second tier as `#[ Wedge ]#`, and X.2
marks it with `#[[ ]]#`. A child that follows its parent at once keeps its own two blank
lines.

## STYLE, section 2: A push over foreign bindings

```nim
{.push header: "reference/cayley.h".}
type
  CayleyEntry* {.importc: "cayley_entry", bycopy.} = object
...
proc wedgeReference*(a, b: cint): CayleyEntry {.importc: "cayley_wedge".}
{.pop.}
```

Constructed. The reference binds no foreign code, so this oracle for the tests, a C table of
the wedge product, is invented. One header binds every foreign declaration in the block, and
`{.pop.}` closes it. An ordinary pragma is never pushed, so that the pragmas of a routine stay
visible where it is defined.
