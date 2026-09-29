# Examples

Worked examples that `CONSTITUTION.md` and `STYLE.md` point into. Each section names the rule
that it shows. Read an example where a rule alone does not settle a case. Transfer the
decision, and not the syntax.

The pga excerpts come from `lengyel/projective_geometric_algebra_illuminated` in the
replications repository, at commit `16dbc17`. The other excerpts come from this repository, at
commit `aaa84c8` of `main`. An excerpt is verbatim, except where its note says what changed.

## I.6: An internal that a sibling reaches

```nim
func `and`(a, b: BasisFlags): BasisFlags {.borrow, compileTime, used.} # Used in cayleys.nim.
```

From `algebra.nim`. The function stays private, and `cayleys.nim` reaches it through `{.all.}`.
The pragma silences the unused warning, and the comment names the sibling that uses it.

## II.6: A restore issues a new revision

```nim
func restoreFrom*(scene: var Scene, snapshot: Scene) =
  ## Replace scene's whole content with snapshot, at revision no earlier state carried.
  ##   Every whole-scene replacement, i.e. undo, redo, clear, load, comes through here.
  ##     Revision only ever rises and no two states front-end has drawn share one.
  let revision_live = scene.count_edits
  scene = snapshot
  scene.count_edits = max(revision_live, snapshot.count_edits) + 1
```

From `rga_visualiser/src/rga_visualiser/scene.nim`, with the loop that stamps each handle, and
its doc line, left out. The snapshot carries an old revision. A cache keyed on that revision
would serve the meshes of the undone state. So the restore issues a revision newer than any
other.

## II.7: A retreat records its cost

```text
4268078 refactor(pga): remove ast generation of cayleys due to compile times
```

The subject names what was removed, and the cost that forced the removal. A later reader can
review the decision when that cost changes.

## II.9: A copy names its sibling

```ts
/* View panel: camera numeric fields, mirroring panel.layoutView exactly. */
```

From `rga_visualiser/src/browser/view_section.ts`. The browser panel copies a desktop panel,
because the browser cannot share its dependencies. The comment names the sibling, so that a
fix to one reaches the other.

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
Scene* = object ## Define fixed-capacity arena of objects, addressed by stable handle.
  geometries: array[OBJECTS_MAX, Multivector] ## Per-handle geometry.
  labels: array[OBJECTS_MAX, Label] ## Per-handle display label.
  inks: array[OBJECTS_MAX, Ink] ## Per-handle palette entry.
```

```nim
## Three lifetimes cover everything this project still allocates dynamically:
##
##   |-----------|---------------------------------|--------------------------------------|
##   | Arena     | Reset                           | Backs                                |
##   |-----------|---------------------------------|--------------------------------------|
##   | Permanent | Never; lives until process exit | Pixel readback buffer, sized once    |
##   |           |                                 | and reused for every export.         |
##   | Export    | After each throwaway unit of    | PNG's filtered/compressed scanlines, |
##   |           | work: one PNG write, one GIF    | GIF's quantized indices and LZW      |
##   |           | sub-frame.                      | output; built once, read once.       |
##   | Frame     | On next frame's swap, so last   | Draw loop's scratch: points          |
##   | swap pair | frame's bytes survive this one. | tessellation step assembles before   |
##   |           | See `ArenaSwap`.                | emitting them.                       |
##   |-----------|---------------------------------|--------------------------------------|
```

From `rga_visualiser`: the first is `src/rga_visualiser/scene.nim`, and the second is the
header of `src/desktop/arena.nim`. The scene is a fixed arena, and a caller holds a handle
into it and never a reference. Each dynamic buffer has one arena, and the arena owns its
lifetime. A step that needs a temporary takes it from a scratch arena that is reset as a whole.

## V.9: Acronyms a layman knows, and paths in full

```text
SVG  HTML  CSS  JSON  JS  URL  ID  DoF      stay
FNV                                        spelled out
simulation/  dependencies/  binaries/  test_<name>.nim
```

From `contributor/sincopa/dance_ontology` at `327fdf6` of `main`, as the Architect ruled on #305.
The first row holds acronyms a layman meets on the web and in data. A hash function's name is
one that only its field knows, so it is spelled out. The paths spell their words in full, and
the test file carries its word before its name.

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
{.push header: "box3d/box3d.h".}
type
  WorldId* {.importc: "b3WorldId", bycopy.} = object
...
proc twistBy*(b: BodyId; torque: Vec; wake: bool) {.importc: "b3Body_ApplyTorque".}
{.pop.}
```

From `dance_ontology/sim/engine.nim`, with the middle of the block left out. One header binds
every foreign declaration in the block, and `{.pop.}` closes it. An ordinary pragma is never
pushed, so that the pragmas of a routine stay visible where it is defined.
