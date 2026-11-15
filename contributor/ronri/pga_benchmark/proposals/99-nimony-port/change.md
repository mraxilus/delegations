# Port of the library to Nimony

This change ports the library at pin to Nimony, the compiler that is to follow Nim 2. Each module
keeps its name, its order and its functions, and the Cayley tables stay typed by `Basis`. The
change adds `pga/basis.nim`, which declares `Basis` before the code that uses it. It splits
`pga/cayleys.nim` into the folder `pga/cayleys/`, with the types, the functions and the tables in
modules of their own, since Nimony evaluates a constant where it stands. The four macros become
templates of the same names, and one plugin program, `pga/emitters.nim`, writes the code of all
four. The suites run on `tests/unittest.nim`, a small stand-in for `std/unittest`, which Nimony
lacks.

The change builds under Nimony at 941d128 with the patches of `compiler.md`, and not under
Nim 2.4.0. `deviations.md` gives each difference from the library at pin, and why Nimony needs it.

## Replace `pga.nim` from `24dfe8f08ca1fcac`

```nim
## Projective Geometric Algebra library and reference supporting rigid and conformal metrics.
##
## Up to 9D PGAs supported, however recommendation is <= 6D.
##
## Order of compile-time type bootstrapping:
##   [Algebra, BasisDigits] -> Basis
##   Basis -> BasisSigned
##         -> Multivector
##   BasisSigned -> BasesSigned
##   BasesSigned -> [Cayley1D, Cayley2D]
##
## Under Nimony, type that plugin declares, and object type that constant uses, must come from
##   imported module, and constant must come after functions that it calls. So `basis.nim` is
##   split from Nim 2 library's `algebra.nim`, and folder `cayleys/` splits `cayleys.nim` into
##   types, functions and tables. Each module imports only modules before it:
##   pga/basis -> pga/algebra -> pga/cayleys/types -> pga/cayleys/functions
##             -> pga/cayleys/definitions -> pga/cayleys -> pga/multivectors -> pga/operators
##   pga/emitters is no module of library: it is program that emits code of each `define…`
##     template, as plugin, where Nim 2 library uses macros.
##
## All operators are derived from (anti)metric and exterior product definitions.
## Cayley tables are defined for each major operator.
## Operators' tables are used to automatically construct their associated functions.
##
## Tests ordered to match as closely with equations in Lengyel's PGAI as possible.
##
## Heap usage avoided completely so user can fully control memory management.
##   NOTE: Partially true in current implementation, but should be at end state.
##
## Operator precedence remains pre-determined by Nim.
##   E.g. `∨` is additive, `∧` is multiplicative.
##   Means that `a ∨ b ∧ c` parses as `a ∨ (b ∧ c)`, instead of `(a ∨ b) ∧ c`.
##   Recommend to always parenthesize complex operations, or used named aliases.
##
## Source files ordered to be read as reference, with optimized compiled representation.
## This file serves as documentation for underlying operators provided in `operators.nim`.
##   Each operator is also documented in case symbols are non-obvious for those unfamiliar.
## Each operator has human readable aliases for external use.
##   Operators use symbols as base form to simplify equations at cost of typability.
##   E.g. (∙𝐦 + ∘𝐦) ∨ (∙𝐧 + ∘𝐧) vs (bulk(𝐦) + weight(𝐦)).antiWedge(bulk(𝐧) + weight(𝐧))
##   All operators and aliases should have documentation.
##     Operators' documentation should specify what operator is and is called.
##     Alias' documentation should specify what operator means/represents/how it's used.
##
## Extraction operators († = conformal only):
##   |-----|-------------------|-------------|
##   |Oper.| Name              | Lengyel     |
##   |-----|-------------------|-------------|
##   | ∙   | bulk(Round)   (†) | 𝐦∙          |
##   | ∘   | weight(Round) (†) | 𝐦∘          |
##   | ■   | bulkFlat       †  | 𝐦■          |
##   | □   | weightFlat     †  | 𝐦□          |
##   | {}  | selectGrade       | ⟨𝐦⟩         |
##   | {}  | selectGradeAnti   | ⟨𝐦⟩         |
##   | []  | selectPart        | 𝐦ₑ          |
##   |-----|-------------------|-------------|
##
## Unary operators:
##   |-----|-------------------|-------------|
##   |Oper.| Name              | Lengyel     |
##   |-----|-------------------|-------------|
##   | \   | complementLeft    | 𝐦̲           |
##   | /   | complementRight   | 𝐦̅           |
##   | ★   | dualBulk          | 𝐦★          |
##   | ☆   | dualWeight        | 𝐦☆         |
##   | -   | negate            | -𝐦          |
##   | ~   | reverse           | 𝐦̃           |
##   | ~∘  | reverseAnti       | 𝐦̰           |
##   |-----|-------------------|-------------|
##
## Binary operators:
##   |-----|-------------------|-------------|
##   |Oper.| Name              | Lengyel     |
##   |-----|-------------------|-------------|
##   | +   | add               | 𝐦 + 𝐧       |
##   | ∙   | dot               | 𝐦 ∙ 𝐧       |
##   | ∘   | dotAnti           | 𝐦 ∘ 𝐧       |
##   | -   | subtract          | 𝐦 - 𝐧       |
##   | ∧   | wedge             | 𝐦 ∧ 𝐧       |
##   | ∨   | wedgeAnti         | 𝐦 ∨ 𝐧       |
##   | ⟑   | wedgeDot          | 𝐦 ⟑ 𝐧       |
##   | ⟇   | wedgeDotAnti      | 𝐦 ⟇ 𝐧       |
##   |-----|-------------------|-------------|
##
## Norm operators:
##   |-----|-------------------|-------------|
##   |Oper.| Name              | Lengyel     |
##   |-----|-------------------|-------------|
##   | |   | norm              | ‖𝐦‖         |
##   | |∙  | normBulk          | ‖𝐦‖∙        |
##   | |∘  | normWeight        | ‖𝐦‖∘        |
##   | |⊙ | normCenter      † | ‖𝐦‖⊙        |
##   | |⊘ | normRadius      † | ‖𝐦‖⊘        |
##   | ^   | unitize           | 𝐦̂           |
##   | ^∙  | normalizeBulk     | 𝐦 ÷ ‖𝐦‖∙    |
##   | ^∘  | normalizeWeight   | 𝐦 ÷ ‖𝐦‖∘    |
##   |-----|-------------------|-------------|
##
## Property operators:
##   |-----|-------------------|-------------|
##   |Oper.| Name              | Lengyel     |
##   |-----|-------------------|-------------|
##   | ⊖  | attitude          | att(𝐦)      |
##   | ⊟  | carrier         † | car(𝐦)      |
##   | ⊞  | cocarrier       † | ccr(𝐦)      |
##   | ⊙  | center          † | cen(𝐦)      |
##   | ⊡  | container       † | con(𝐦)      |
##   | ⊛  | partner         † | par(𝐦)      |
##   | ∩   | support           | sup(𝐦)      |
##   | ∪   | supportAnti       | asp(𝐦)      |
##   |-----|-------------------|-------------|
##
## Compound operators:
##   |-----|-----------------------|---------------|
##   |Oper.| Name                  | Lengyel       |
##   |-----|-----------------------|---------------|
##   | ∨★  | contractBulk          | 𝐦 ∨ 𝐧★        |
##   | ∨☆  | contractWeight        | 𝐦 ∨ 𝐧☆       |
##   | ∧★  | expandBulk            | 𝐦 ∧ 𝐧★        |
##   | ∧☆  | expandWeight          | 𝐦 ∧ 𝐧☆       |
##   | ∨∧★ | projectCentral        | 𝐧 ∨ (𝐦 ∧ 𝐧★)  |
##   | ∧∨★ | projectCentralAnti    | 𝐧 ∧ (𝐦 ∨ 𝐧★)  |
##   | ∨∧☆ | projectOrthogonal     | 𝐧 ∨ (𝐦 ∧ 𝐧☆) |
##   | ∧∨☆ | projectOrthogonalAnti | 𝐧 ∧ (𝐦 ∨ 𝐧☆) |
##   |-----|-----------------------|---------------|
##

import ./pga/[algebra, cayleys, multivectors, operators]
export cayleys, operators
export multivectors except index
# Internal helpers are exported for other modules of library, as Nimony has no `{.all.}`
#   import; this hides them from importer, as Nim 2 library keeps them private.
export algebra except BasisFlags, countSetBits, doAssert, toBasis, toDigits, toFlags, `and`,
  `not`, `xor`



#[ Extraction Operators ]#

func selectElement*(m: Multivector, b: Basis): Coefficient {.inline.} = m[b]
  ## Select specific basis element from multivector.

func selectGrade*(m: Multivector, g: Grade): Multivector {.inline.} = m{g}
  ## Select grade-vector part from multivector.

func selectGradeAnti*(m: Multivector, g: GradeAnti): Multivector {.inline.} = m{g}
  ## Select antigrade-vector part from multivector.

when IS_RIGID:
  func bulk*(m: Multivector): Multivector {.inline.} = ∙m
    ## Extract bulk of multivector.
    ##   Bulk contains object's position.

  func weight*(m: Multivector): Multivector {.inline.} = ∘m
    ## Extract weight of multivector.
    ##   Weight contains object's attitude and orientation.
    ##   Where weight is 0, object is contained by (N-1)D object at infinity.

when IS_CONFORMAL:
  func bulkFlat*(m: Multivector): Multivector {.inline.} = ■m
    ## Extract flat bulk of multivector.
    ##   Bulk contains object's position.

  func bulkRound*(m: Multivector): Multivector {.inline.} = ∙m
    ## Extract round bulk of multivector.
    ##   Bulk contains object's position.

  func weightFlat*(m: Multivector): Multivector {.inline.} = □m
    ## Extract flat weight of multivector.
    ##   Weight contains object's attitude and orientation.

  func weightRound*(m: Multivector): Multivector {.inline.} = ∘m
    ## Extract round weight of multivector.
    ##   Weight contains object's attitude and orientation.



#[ Norm Operators ]#

func norm*(m: Multivector): MultivectorScalars {.inline.} = |m
  ## Get geometric norm of multivector as distance from origin.

func normalizeBulk*(m: Multivector): Multivector {.inline.} = ^∙m
  ## Normalize multivector so bulk norm has unit scalar magnitude (𝟏).

func normalizeWeight*(m: Multivector): Multivector {.inline.} = ^∘m
  ## Normalize multivector so weight norm has unit antiscalar magnitude, i.e. |𝐦|∘ = 𝟙.

func unitize*(m: Multivector): Multivector {.inline.} = ^m
  ## Normalize multivector so weight norm has unit antiscalar magnitude, i.e. 𝐦̂ = 𝐦 / ‖𝐦‖∘.
  ##   Shorthand for weight normalization, i.e. weight has magnitude of one.
  ##   Projects higher-dimensional representations of objects into Eucledian space.
  ##     By scaling weight of 𝐦 to unit magnitude.

when IS_RIGID:
  func normBulk*(m: Multivector): MultivectorScalars {.inline.} = |∙m
    ## Get bulk norm of multivector as size of bulk components.

  func normWeight*(m: Multivector): MultivectorScalars {.inline.} = |∘m
    ## Get weight norm of multivector as size of weight components.
    ##   Interpreted as collective magnitude of components that extend in direction of eₙ.

when IS_CONFORMAL:
  func normBulkRound*(m: Multivector): MultivectorScalars {.inline.} = |∙m
    ## Get round bulk norm of multivector as size of round bulk components.

  func normWeightRound*(m: Multivector): MultivectorScalars {.inline.} = |∘m
    ## Get round weight norm of multivector as size of round weight components.

  func normBulkFlat*(m: Multivector): MultivectorScalars {.inline.} = |■m
    ## Get flat bulk norm of multivector as size of flat bulk components.

  func normWeightFlat*(m: Multivector): MultivectorScalars {.inline.} = |□m
    ## Get flat weight norm of multivector as size of flat weight components.

  func normCenter*(m: Multivector): MultivectorScalars {.inline, error: "TODO:  |⊙m".}
    ## Get center norm of multivector.

  func normRadius*(m: Multivector): MultivectorScalars {.inline.} = |⊘m
    ## Get radius norm of multivector.



#[ Property Operators ]#

func attitude*(m: Multivector): Multivector {.inline.} = ⊖m
  ## Get attitude of multivector as intersection with horizon.

when IS_RIGID:
  func support*(m: Multivector): Multivector {.inline.} = ∩m
    ## Perform orthogonal projection of origin (i.e. eₙ) onto multivector.

  func supportAnti*(m: Multivector): Multivector {.inline.} = ∪m
    ## Perform orthogonal projection of horizon (i.e. e̅ₙ) onto multivector.

when IS_CONFORMAL:
  func carrier*(m: Multivector): Multivector {.inline.} = ⊟m
    ## Get carrier of multivector as lowest dimensional flat object containing it, i.e. 𝐦 ∧ eₙ.
    ##   Has effect of annihilating flat part of multivector as eₙ ∧ eₙ = 0,
    ##   Also add eₙ to each round component, making it flat geometry.
    ##   Carrrier contains center of original multivector.

  func carrierCo*(m: Multivector): Multivector {.inline.} = ⊞m
    ## Get cocarrier of multivector as carrier of multivector's antidual, i.e. 𝐦☆ ∧ eₙ.
    ##   Antidual used over dual to make signs more favourable.
    ##   Cocarrrier contains center of original multivector.

  func center*(m: Multivector): Multivector {.inline.} = ⊙m
    ## Get center of multivector as round point with same position and radius, i.e. 𝐦⊞ ∨ 𝐦.
    ##   Center of real object is real, center of imaginary object is imaginary.

  func container*(m: Multivector): Multivector {.inline.} = ⊡m
    ## Get container of multivector as smallest sphere containing it, i.e. 𝐦 ∧ (𝐦⊟)☆.
    ##   Antidual used over dual to be consistent with expansions.
    ##   Container of real object is real, container of imaginary object is imaginary.

  func partner*(m: Multivector): Multivector {.inline.} = ⊛m
    ## Get partner of multivector as same object with squared radius of opposite sign.
    ##   I.e. (-1)^(grade(𝐦)+1) (𝐦☆)⊡ ∨ 𝐦⊟.



#[ Unary Operators ]#

func complementLeft*(m: Multivector): Multivector {.inline.} = \m
  ## Get left complement of multivector.

func complementRight*(m: Multivector): Multivector {.inline.} = /m
  ## Get right complement of multivector.

func dualBulk*(m: Multivector): Multivector {.inline.} = ★m
  ## Get right dual of multivector's bulk components.

func dualWeight*(m: Multivector): Multivector {.inline.} = ☆m
  ## Get right dual of multivector's weight components.

func negate*(m: Multivector): Multivector {.inline.} = -m
  ## Negate multivector.

func reverse*(m: Multivector): Multivector {.inline.} = ~m
  ## Reverse multivector.
  ##   I.e. rearrange vector element factors so they wedge in reverse order.

func reverseAnti*(m: Multivector): Multivector {.inline.} = ~∘m
  ## Reverse complement of multivector.
  ##   I.e. rearrange antivector element factors so they antiwedge in reverse order.



#[ Binary Operators ]#

func add*(m, n: Multivector): Multivector {.inline.} = m + n
  ## Add multivectors.

func add*(m: Multivector, s: Coefficient): Multivector {.inline.} = s + m
  ## Add multivector and scalar.

func add*(s: Coefficient, m: Multivector): Multivector {.inline.} = s + m
  ## Add scalar and multivector.

func dot*(m, n: Multivector): Multivector {.inline.} = m ∙ n
  ## Multiply multivectors through inner product between bulks.

func dotAnti*(m, n: Multivector): Multivector {.inline.} = m ∘ n
  ## Multiply multivectors through inner product between weights.

func subtract*(m, n: Multivector): Multivector {.inline.} = m - n
  ## Subtract multivectors.

func subtract*(m: Multivector, s: Coefficient): Multivector {.inline.} = m - s
  ## Subtract scalar from multivector.

func subtract*(s: Coefficient, m: Multivector): Multivector {.inline.} = s - m
  ## Subtract multivector from scalar.

func wedge*(m, n: Multivector): Multivector {.inline.} = m ∧ n
  ## Multiply multivectors by combining jointly present dimensions.
  ##   I.e. multiply through exterior product.
  ##   Also called join operation, analogous to union.

func wedge*(m: Multivector, s: Coefficient): Multivector {.inline.} = s ∧ m
  ## Multiply multivector and scalar via exterior product.
  ##   Equivalent to standard scalar product.

func wedge*(s: Coefficient, m: Multivector): Multivector {.inline.} = s ∧ m
  ## Multiply scalar and multivector via exterior product.
  ##   Equivalent to standard scalar product.

func wedgeAnti*(m: Multivector, n: Multivector): Multivector {.inline.} = m ∨ n
  ## Multiply multivectors by combining jointly abscent dimensions.
  ##   I.e. multiply through exterior antiproduct.
  ##   Also called meet operation, analogous to intersection.

func wedgeDot*(m, n: Multivector): Multivector {.inline.} = m ⟑ n
  ## Multiply multivectors through geometric product.
  ##   Incorporates wedge product, adding information.

func wedgeDotAnti*(m, n: Multivector): Multivector {.inline.} = m ⟇ n
  ## Multiply multivectors through geometric antiproduct.
  ##   Incorporates antiwedge proudct, adding information.



#[ Compound Operators ]#

func contractBulk*(m, n: Multivector): Multivector {.inline.} = m ∨★ n
  ## Multiply multivectors through right inner product bulk contraction, i.e. 𝐦 ∨ 𝐧★.

func contractWeight*(m, n: Multivector): Multivector {.inline.} = m ∨☆ n
  ## Multiply multivectors through right inner product weight contraction, i.e. 𝐦 ∨ 𝐧☆.

func expandBulk*(m, n: Multivector): Multivector {.inline.} = m ∧★ n
  ## Multiply multivectors through right inner product bulk expansion, i.e. 𝐦 ∧ 𝐧★.

func expandWeight*(m, n: Multivector): Multivector {.inline.} = m ∧☆ n
  ## Multiply multivectors through right inner product weight expansion, i.e. 𝐦 ∧ 𝐧☆.

func projectCentral*(m, n: Multivector): Multivector {.inline.} = n ∨ (m ∧★ n)
  ## TODO: Document.

func projectCentralAnti*(m, n: Multivector): Multivector {.inline.} = n ∧ (m ∨★ n)
  ## TODO: Document.

func projectOrthogonal*(m, n: Multivector): Multivector {.inline.} = n ∨ (m ∧☆ n)
  ## TODO: Document.

func projectOrthogonalAnti*(m, n: Multivector): Multivector {.inline.} = n ∧ (m ∨☆ n)
  ## TODO: Document.
```

## Add `pga/basis.nim`

```nim
## Configure specific PGA, and define its `Basis` enum from digits of its basis vectors.
##
## Split from `algebra.nim` for Nimony: no signature or type section of module that calls plugin
##   sees type that plugin declares. So this module holds what `Basis` needs before it exists:
##   configuration, digit representation of bases, and their construction. Code typed over
##   `Basis` stays in `algebra.nim`, which imports and re-exports this module.

import std/[assertions, math, sequtils]



#[ Library Configuration ]#

# Allow importer to configure PGA variant and options. (e.g. `--define:pga.dimensions=3`).
const
  DIMENSIONS* {.intdefine: "pga.dimensions".} = 4
  IS_CONFORMAL* {.booldefine: "pga.is_conformal".} = false
  IS_RIGID* = not IS_CONFORMAL

const
  FLOAT_WIDTH* {.intdefine: "pga.float_width".} = 64
  FLOAT_TOLERANCE* {.intdefine: "pga.float_tolerance".} = (when FLOAT_WIDTH == 32: 4 else: 9)
    # Avoid small-value comparison failures.

type Coefficient* = (when FLOAT_WIDTH == 32: float32 else: float64)
const TOLERANCE_ABS* = Coefficient(10.pow(-FLOAT_TOLERANCE.float))

# Validate configuration options are within library scope.
#   Library allows up to 9D PGAs, however, after 6D, compile/run times are increasingly slow.
#   9D limit is implementation restriction as bases are encoded as single decimal digits.
#     Due to extremely slow performance on higher dimensions, limit is practical choice.
#     Higher dimensionality potentially supportable by including alphanumeric bases (e.g. Eca41).
#       Skipping `e` and `s` due to their pre-existing usage as prefixes.
#   Each message is constant of its own: Nimony's `{.error.}` folds only literal or constant name.
#   One `when` chain: build reports first failed check alone, as `static` block of Nim 2 library.
when DIMENSIONS notin 2..6:
  const message = "Dimensionality should be in the range 2..6; got `" & $DIMENSIONS & "`."
  {.error: message.}
elif not (IS_RIGID or DIMENSIONS >= 3):
  const message = "Conformal Geometric Algebras must have dimensionality of 3 or more " &
    "(2 Conformal + 1 Euclidean); got `" & $DIMENSIONS & "`."
  {.error: message.}
elif FLOAT_WIDTH != 32 and FLOAT_WIDTH != 64:  # Nimony has no set of `int`: `{32, 64}` crashes.
  const message = "Float width should be either 32 or 64; got `" & $FLOAT_WIDTH & "`."
  {.error: message.}



#[ Type Definitions ]#

type  ## Define independent type definitions needed at compile-time.
  Algebra = seq[seq[BasisDigits]]  ## Define data structure for generating algebras.
  BasisDigits* = distinct string  ## Define digit representation of basis.

# Borrow necessary functions for using distinct types (i.e. for added type safety).
#   Ideally Nim would have feature to auto borrow everything, but prevent interop.
func `&`(a, b: BasisDigits): BasisDigits {.borrow.}
func len*(b: BasisDigits): int {.borrow.}
iterator items*(b: BasisDigits): char =
  for d in string(b): yield d  # Nimony crashes on `(for ...)` as body.
template `[]`*(b: BasisDigits, i: int): char {.used.} = string(b)[i]  # For cayleys/functions.nim.



#[ Macro Helpers ]#

func constructAlgebra(dimensions: int): Algebra {.noinit.} =
  ## Construct algebra for `dimensions`-dimensional PGA.
  ##   Follow Lengyel's basis convention as opposed to lexicographic ordering.
  ##     For pedagogical interop with standard linear algebra and related math.
  ##   Differences from lexicographical ordering:
  ##     Order 3D 2-vectors by which basis does NOT appear (e₂₃, e₃₁, e₁₂).
  ##       Matches with quaternion imaginary units i, j, k.
  ##     Order 3D antiscalar in decending order (e₃₂₁),
  ##       so motors can be sum of sin/cos instead of difference.
  ##     Order 4D 2/3-vectors to align as right complements of basis vectors,
  ##       to consider 4x4 transformation matrix rows as planes, columns as points.
  ##       TODO: Understand statement above better.
  ##   Cost of deviation from lexicographical ordering:
  ##     Exterior product must round-trip bases through lexicographical ordering.
  ##       Required by parity-based compute optimization (see `multipleExterior`).
  ##   Keeps algebras in array by dimension, where Nim 2 library uses `Table`: Nimony's `Table`
  ##     has no `toTable`, and its `[]` raises, so each read would need `try` or `getOrQuit`.

  func toAlgebra(grades: seq[seq[string]]): Algebra =
    ## Convert digits by grade to algebra.
    ##   Nimony converts no `seq[seq[string]]` to `seq[seq[BasisDigits]]`, where Nim 2 does.
    result = @[]
    for grade in grades:
      var bases: seq[BasisDigits] = @[]
      for digits in grade: bases.add BasisDigits(digits)
      result.add bases

  func generateUpTo(algebras: var array[2..9, Algebra], dimensions: int) =
    ## Populate missing algebras up to `dimensions`-dimensional PGA.
    ##   Limited to 9 dimensions as relies on single digit representation.
    var dimension = 5
    while dimension <= dimensions:
      let prev = algebras[dimension-1]
      var curr = toAlgebra(@[@[""]])

      # Construct non-(anti)scalar bases.
      #   `concat` and `mapIt`, where Nim 2 library uses `&` and `=>`: Nimony has no `&` of seqs,
      #     and no `=>`.
      let digit_new = BasisDigits($dimension)
      for i in 1..<len(prev):
        curr.add(concat(prev[i], prev[i-1].mapIt(it & digit_new)))

      # Construct antiscalar.
      var antiscalar = ""
      for i in 1..dimension: antiscalar.add char(ord('0') + i)
      curr.add(@[antiscalar.toBasisDigits])

      # Update algebra table.
      algebras[dimension] = curr
      dimension += 1

  var algebras = default(array[2..9, Algebra])
  algebras[2] = toAlgebra(@[@[""], @["1", "2"], @["12"]])
  algebras[3] = toAlgebra(@[@[""], @["1", "2", "3"], @["23", "31", "12"], @["321"]])
  algebras[4] = toAlgebra(@[
    @[""],
    @["1", "2", "3", "4"],
    @["41", "42", "43", "23", "31", "12"],
    @["423", "431", "412", "321"],
    @["1234"],
  ])
  algebras.generateUpTo(dimensions)
  algebras[dimensions]


func toBasisNames(algebra: Algebra): array[1 shl DIMENSIONS, string] =
  ## Convert algebra's grades into names of its bases, in order.
  ##   Names in array, where Nim 2 library folds digits into `seq` for macro to name: plugin
  ##     then reads plain array, and naming stays in `toBasisName`, with its inverse `toDigits`.
  result = default(array[1 shl DIMENSIONS, string])
  var i = 0
  for grade in algebra:
    for digits in grade:
      result[i] = digits.toBasisName
      i += 1



#[ Basis Conversion ]#

func `$`*(b: BasisDigits): string =
  ## Convert basis' digits to string (without S/E prefix).
  result = ""
  for digit in b: result.add(digit)


func toBasisDigits*(digits: string): BasisDigits {.inline, noinit.} =
  ## Convert from string to digit representation of basis, checking for validity.
  let digits_valid = 1..DIMENSIONS  # `let`: each `const` costs Nimony one compiled program.
  for d in digits:
    assert ord(d) - ord('0') in digits_valid,
      "Found invalid digit `" & d & "` in digits=" & digits & "."
  BasisDigits(digits)


func toBasisName*(b: BasisDigits): string {.noinit.} =
  ## Convert basis' digits to string (with S/E prefix).
  if len(b) == 0: "S" else: "E" & $b



#[ Basis Generation ]#

template defineBasis(names: static[array[1 shl DIMENSIONS, string]]) {.plugin: "emitters".}
  ## Define bases for PGA, as `Basis` enum of `names`.
  ##   Last in module: Nimony evaluates `static(...)` where it stands, and has no `codeReordering`,
  ##     which lets Nim 2 library define bases before helpers.
  ##   No return type, where macro has `untyped`: Nimony gives every phase only to code of
  ##     plugin template without one, and declarations need each phase.

# Only for supported dimensions, so build reports message of check above alone: below 2D,
#   `constructAlgebra` has no algebra, and its constant adds error of its own. Negative value
#   still adds errors at `array[1 shl DIMENSIONS, string]` above, outside branch.
when DIMENSIONS in 2..6:
  const BASIS_NAMES = constructAlgebra(DIMENSIONS).toBasisNames
    # Constant, where Nim 2 library passes `DIMENSIONS` to macro: in body phase, as `static(...)`
    #   of this call is, Nimony evaluates no routine with nested routine ("ambiguous call"), but
    #   constant of module evaluates it.
  defineBasis(names = static(BASIS_NAMES))
```

## Replace `pga/algebra.nim` from `3169d7dc1ecd4c82`

```nim
## Construct specific PGA's `Basis` enum and related types/procedures.
##
## Example resulting interpretation of 4D RGA (3D Euclidean):
##
##   |---------|-------------------|-----|------------------------|-----|
##   | Basis   | Base Space        |Coef.| Anti Space             |Coef.|
##   |---------|-------------------|-----|------------------------|-----|
##   | S       | 𝟏 (scalar)        | s   | 𝟙 (anti-scalar)        | t   |
##   | E1      | point position  x | pˣ  | anti-plane normal    x | gˣ  |
##   | E2      | point position  y | pʸ  | anti-plane normal    y | gʸ  |
##   | E3      | point position  z | pᶻ  | anti-plane normal    z | gᶻ  |
##   | E4      | point weight      | pʷ  | anti-plane position    | gʷ  |
##   | E41     | line  direction x | lᵛˣ | anti-line  moment    x | lᵐˣ |
##   | E42     | line  direction y | lᵛʸ | anti-line  moment    y | lᵐʸ |
##   | E43     | line  direction z | lᵛᶻ | anti-line  moment    z | lᵐᶻ |
##   | E23     | line  moment    x | lᵐˣ | anti-line  direction x | lᵛˣ |
##   | E31     | line  moment    y | lᵐʸ | anti-line  direction y | lᵛʸ |
##   | E12     | line  moment    z | lᵐᶻ | anti-line  direction z | lᵛᶻ |
##   | E423    | plane normal    x | gˣ  | anti-point position  x | pˣ  |
##   | E431    | plane normal    y | gʸ  | anti-point position  y | pʸ  |
##   | E412    | plane normal    z | gᶻ  | anti-point position  z | pᶻ  |
##   | E321    | plane position    | gʷ  | anti-point weight      | pʷ  |
##   | E1234   | 𝟙 (anti-scalar)   | t   | 𝟏 (scalar)             | s   |
##   |---------|-------------------|-----|------------------------|-----|
##
##
## Example resulting interpretation of 5D CGA (3D Euclidean), antispace derived as above:
##
##   |--------|----------------------------|-----|--------------------|-------------------|---|
##   | Basis  | Base Space                 |Coef.| Round Part         |  Flat Part        |...|
##   |--------|----------------------------|-----|--------------------|-------------------|---|
##   | S      | 𝟏 (scalar)                 | s   | 𝟏 (scalar)         | s = 0             |...|
##   | E1     | point  carrier position  x | aˣ  | point  position x  | aˣ = 0            |...|
##   | E2     | point  carrier position  y | aʸ  | point  position y  | aʸ = 0            |...|
##   | E3     | point  carrier position  z | aᶻ  | point  position z  | aᶻ = 0            |...|
##   | E4     | point  carrier weight      | aʷ  | point  weight      | aʷ = 0            |...|
##   | E5     | point  flat    bulk        | aᵘ  | aᵘ = 0             | infinity          |...|
##   | E41    | dipole carrier direction x | dᵛˣ | line   direction x | dᵛˣ = 0           |...|
##   | E42    | dipole carrier direction y | dᵛʸ | line   direction y | dᵛʸ = 0           |...|
##   | E43    | dipole carrier direction z | dᵛᶻ | line   direction z | dᵛᶻ = 0           |...|
##   | E23    | dipole carrier moment    x | dᵐˣ | line   moment    x | dᵐˣ = 0           |...|
##   | E31    | dipole carrier moment    y | dᵐʸ | line   moment    y | dᵐʸ = 0           |...|
##   | E12    | dipole carrier moment    z | dᵐᶻ | line   moment    z | dᵐᶻ = 0           |...|
##   | E15    | dipole flat    position  x | dᵖˣ | dᵖˣ = 0            | point position  x |...|
##   | E25    | dipole flat    position  y | dᵖʸ | dᵖʸ = 0            | point position  y |...|
##   | E35    | dipole flat    position  z | dᵖᶻ | dᵖᶻ = 0            | point position  z |...|
##   | E45    | dipole flat    weight      | dᵖʷ | dᵖʷ = 0            | point weight      |...|
##   | E423   | circle carrier normal    x | cᵍˣ | plane  normal    x | cᵍˣ = 0           |...|
##   | E431   | circle carrier normal    y | cᵍʸ | plane  normal    y | cᵍʸ = 0           |...|
##   | E412   | circle carrier normal    z | cᵍᶻ | plane  normal    z | cᵍᶻ = 0           |...|
##   | E321   | circle carrier position  w | cᵍʷ | plane  position    | cᵍʷ = 0           |...|
##   | E415   | circle flat    direction x | cᵛˣ | cᵛˣ = 0            | line  direction x |...|
##   | E425   | circle flat    direction y | cᵛʸ | cᵛʸ = 0            | line  direction y |...|
##   | E435   | circle flat    direction z | cᵛᶻ | cᵛᶻ = 0            | line  direction z |...|
##   | E235   | circle flat    moment    x | cᵐˣ | cᵐˣ = 0            | line  moment    x |...|
##   | E315   | circle flat    moment    y | cᵐʸ | cᵐʸ = 0            | line  moment    y |...|
##   | E125   | circle flat    moment    z | cᵐᶻ | cᵐᶻ = 0            | line  moment    z |...|
##   | E1234  | sphere carrier weight      | sᵘ  | space              | sᵘ = 0            |...|
##   | E4235  | sphere flat    normal    x | sˣ  | sˣ = 0             | plane normal    x |...|
##   | E4315  | sphere flat    normal    y | sʸ  | sʸ = 0             | plane normal    y |...|
##   | E4125  | sphere flat    normal    z | sᶻ  | sᶻ = 0             | plane normal    z |...|
##   | E3215  | sphere flat    position    | sʷ  | sʷ = 0             | plane position    |...|
##   | E12345 | 𝟙 (anti-scalar)            | t   | t = 0              | 𝟙 (anti-scalar)   |...|
##   |--------|----------------------------|-----|--------------------|-------------------|---|
##

import std/[assertions, bitops, math]

import ./basis
export basis except BasisDigits, toBasisDigits, toBasisName
  # Kept here: `except` of `pga.nim` hides no name that this module re-exports.



#[ Type Definitions ]#

type  ## Define independent type definitions needed at compile-time.
  BasisFlags* = distinct uint  ## Define binary representation of 1-vectors present in basis.

type  ## Define independent type definitions needed at runtime.
  Grade* = distinct int  ## Define grade selector for multivectors.
  GradeAnti* = distinct int  ## Define antigrade selector for multivectors.

# Borrow necessary functions for using distinct types (i.e. for added type safety).
#   Ideally Nim would have feature to auto borrow everything, but prevent interop.
func `and`*(a, b: BasisFlags): BasisFlags {.borrow, used.}  # Used in cayleys/functions.nim.
func `not`*(a: BasisFlags): BasisFlags {.borrow, used.}  # Used in cayleys/functions.nim.
func `xor`*(a, b: BasisFlags): BasisFlags {.borrow, used.}  # Used in cayleys/functions.nim.
func `==`(a, b: BasisFlags): bool {.borrow.}
func countSetBits*(b: BasisFlags): int {.borrow.}
template `in`(c: char, b: BasisDigits): bool =
  let digits = string(b)  # Copy: Nimony's C takes address of `string(b)` itself, which C rejects.
  c in digits

template borrowOperationsGrade(T: typedesc) {.untyped, dirty.} =
  ## Borrow functions for performing basic operations on grades.
  ##   `{.untyped, dirty.}`, where Nim 2 library's template has neither: typed template stops
  ##     at `.borrow` ("[Bug]"), and untyped template injects routine of its body only where
  ##     routine has `inject`, or template is dirty; `dirty` keeps six routines of Nim 2 library.
  func `-`*(g, h: T): T {.borrow.}
  func `*`*(g, h: T): T {.borrow.}
  func `+`*(g, h: T): T {.borrow.}
  func `<`*(g, h: T): bool {.borrow.}
  func `<=`*(g, h: T): bool {.borrow.}
  func `==`*(g, h: T): bool {.borrow.}
borrowOperationsGrade(Grade)
borrowOperationsGrade(GradeAnti)



#[ Assertions ]#

template doAssert*(condition: bool, message: string) =
  ## Assert in every build, as Nim 2's `doAssert` does; Nimony has only `assert`.
  ##   Fails through Nimony's `failedAssertImpl`, which ends path for its init check.
  if not condition: failedAssertImpl(message)


func toBinary(x: uint): string =
  ## Format unsigned integer in binary, as `strformat`'s `:b` does; Nimony has neither.
  result = if x == 0: "0" else: ""
  var rest = x
  while rest != 0:
    result = (if (rest and 1) == 1: "1" else: "0") & result
    rest = rest shr 1



#[ Basis Iteration ]#

iterator items*(t: typedesc[Basis]): Basis =
  ## Iterate bases in order, i.e. `for b in Basis`.
  ##   Nimony's system has no `items` for enum types, where Nim 2's has.
  for b in Basis.low..Basis.high: yield b



#[ Basis Conversion ]#

func toBasis*(b: BasisDigits): Basis {.noinit, used.} =  # Used in "cayleys/functions.nim".
  ## Convert digit representation of basis to associated basis.
  b.toFlags.toBasis


func toBasis*(b: BasisFlags): Basis {.noinit.} =
  ## Convert binary flag representation of basis to associated basis.
  ##   Searches bases, where Nim 2 library builds lookup table: each `const` costs Nimony one
  ##     compiled program, and this function runs only at compile time.
  for basis in Basis:
    if basis.toFlags == b: return basis
  doAssert false, "Found invalid basis flags: " & toBinary(uint(b))


func toBasisFlags(flags: uint): BasisFlags {.inline, noinit.} =
  ## Convert from unsigned integer to flag representation of basis, checking for validity.
  let
    mask = not ((2'u^DIMENSIONS) - 1)
    digits_invalid = (flags and mask)
  assert digits_invalid == 0,
    "Found invalid flags `" & toBinary(digits_invalid) & "` in flags=" & toBinary(flags)
  BasisFlags(flags)


func toDigits*(b: Basis): BasisDigits {.noinit.} =
  ## Convert basis to ordered digit representation.
  toBasisDigits(($b)[1 .. ^1])


func toFlags*(b: Basis): BasisFlags {.noinit.} =
  ## Convert basis to binary flag representation of present 1-vectors.
  ##   Converts directly, where Nim 2 library builds lookup table: each `const` costs Nimony
  ##     one compiled program, and this function runs only at compile time.
  b.toDigits.toFlags


func toFlags*(b: BasisDigits): BasisFlags {.noinit.} =
  ## Convert digits to binary flag representation of present 1-vectors.
  var flags = 0'u
  for i in 1..DIMENSIONS:
    if char(ord('0') + i) in b:
      flags = flags or (1'u shl (i - 1))
  flags.toBasisFlags



#[ Basis Aliasing ]#


when IS_CONFORMAL:
  template infinity*(t: typedesc[Basis]): Basis = t.vectorLast
    ## Alias basis representing point at infinity (i.e. eₙ).


template origin*(t: typedesc[Basis]): Basis =
  ## Alias basis representing origin (i.e. eₙ in RGA; 𝐞ₙ₋₁ in CGA).
  when IS_RIGID: t.vectorLast else: t.vectorLast.pred


template scalar*[I: Basis | Grade | GradeAnti](t: typedesc[I]): I {.untyped.} =
  ## Alias scalar's basis and (anti)grade indices.
  ##   `.untyped`: Nimony binds generic body once at definition, where one body cannot
  ##     serve both `Basis` and distinct grades, whose `low` and `high` are other overloads.
  when I is GradeAnti:  I.high else: I.low

template scalarAnti*[I: Basis | Grade | GradeAnti](t: typedesc[I]): I {.untyped.} =
  ## Alias antiscalar's basis and (anti)grade indices.
  when I is GradeAnti:  I.low else: I.high

template vector*[G: Grade | GradeAnti](t: typedesc[G]): G =
  ## Alias grade of (anti)vectors.
  when G is GradeAnti: G(DIMENSIONS - 1) else: G(1)

template vectorAnti*[G: Grade | GradeAnti](t: typedesc[G]): G =
  ## Alias antigrade of (anti)vectors.
  when G is GradeAnti: G(1) else: G(DIMENSIONS - 1)

template vectorLast*(t: typedesc[Basis]): Basis = Basis(DIMENSIONS)
  ## Alias basis representing last vector, i.e. last grade 1 multivector element, eₙ.



#[ Grade Selection ]#

template low*[G: Grade | GradeAnti](t: typedesc[G]): G = G(0)
  ## Alias (anti)scalar's (anti)grade index.


template high*[G: Grade | GradeAnti](t: typedesc[G]): G = G(DIMENSIONS)
  ## Alias (anti)antiscalar's (anti)grade index (where antiantiscalar is scalar).


func grade*(b: Basis): Grade {.noinit.} =
  ## Count number of vector basis elements present in factorization of basis.
  ##   I.e. number of full dimensions occupied by given basis.
  const lut_grade_by_basis = block:
    ## Construct LUT for grade of basis element.
    var lut {.noinit.}: array[Basis, Grade]
    for b in Basis: lut[b] = Grade(b.toFlags.countSetBits)
    lut

  lut_grade_by_basis[b]


func gradeAnti*(b: Basis): GradeAnti {.inline, noinit.} =
  ## Count number of vector basis elements absent in factorization of basis.
  ##  I.e. number of empty dimensions unoccupied by basis.
  GradeAnti(Grade.high - b.grade)

func toAnti*(grade: Grade): GradeAnti {.inline, noinit.} = GradeAnti(Grade.high - grade)
  ## Covert grade to equivalent antigrade form.

func toBase*(grade: GradeAnti): Grade {.inline, noinit.} = Grade(GradeAnti.high - grade)
  ## Convert antigrade to equivalent grade form.
```

## Replace `pga/cayleys.nim` from `4aa7a2507c537c06`

```nim
## Define and construct Cayley tables for any PGA.
##
## Cayleys exposed to importer so they can inspect algebra's definition.
##
## Folder `cayleys/` holds types, functions and tables, each in module of its own, for Nimony.
##   This module re-exports tables, and types that Nim 2 library makes public. `except` hides
##     name alone: call still finds routine of `cayleys/types.nim` through type of its argument.

import ./cayleys/[definitions, types]
export definitions
export types except Chirality, Order, Partiality, Spatiality, toBasesSigned,
  Left, Right, Bulk, Weight, Base, Anti  # Fields of enums: hiding type leaves them visible.
```

## Add `pga/cayleys/types.nim`

```nim
## Define types of Cayley tables and of algebraic distinctions.
##
## Module of its own for Nimony: Nimony evaluates `const` while it still checks signatures of its
##   module, so type of same module is not yet complete there, and constant tables fail to build
##   ("expression expected; tag: efld"). Types in module of their own are complete.
##   Names are exported for `functions.nim` and `definitions.nim`; `../cayleys.nim` re-exports
##     types that Nim 2 library keeps public.

import std/assertions

import ../algebra



#[ Type Definitions ]#

type  ## Define type definitions dependent on `Basis` needed for macros.
  BasisSigned* = object  ## Define signed representation of basis.
    basis*: Basis
    is_negated*: bool = false
  BasesSigned* = object  ## Define signed bases of Cayley table cell, as their sum.
    ##   Array with count, where Nim 2 library uses `seq`: plugin then reads table as plain value.
    ##   One term for metric of each basis, and second where metric pairs conformal vectors
    ##     (see `constructMetric`). `add` stops build where cell needs more.
    elements: array[(when IS_CONFORMAL: 2 else: 1), BasisSigned]
    count: int
  Cayley1D* =  ## Define data structure for constructing unary algebra operations (map).
    array[Basis, BasesSigned]
  Cayley2D* =  ## Define data structure for constructing binary algebra operations.
    array[Basis, array[Basis, BasesSigned]]  # Support conformal operators with second term.

type  ## Define type definitions for algebraic distinctions.
  Chirality* {.pure.} = enum Left, Right  ## Define distinction between PGA operation orientations.
  Partiality* {.pure.} = enum Bulk, Weight  ## Define distinction between PGA's disjoint parts.
  Spatiality* {.pure.} = enum Base, Anti  ## Define distinction between PGA's spacial duality.

type  ## Define type defintions for containers of algebraic distinctions.
  Chiral*[T] = object
    left*, right*: T
  Formal*[T] = object
    when IS_CONFORMAL:
      flat*, round*: T
    else:
      round*: T
  Partial*[T] = object
    bulk*, weight*: T
  Spatial*[T] = object
    base*, anti*: T

## Define type definition for transwedge order.
type Order* = distinct range[0..DIMENSIONS]
#func `<=`(a, b: Order): bool {.borrow.}
func `==`*(a, b: Order): bool {.borrow.}
iterator items*(t: typedesc[Order]): Order =
  for i in 0..DIMENSIONS: yield Order(i)



#[ Cell Operations ]#

func `$`*(b: BasisSigned): string =
  ## Convert signed basis to string, as Nim 2's generic object `$` does for messages.
  ##   Nimony gives objects no generic `$`.
  "(basis: " & $b.basis & ", is_negated: " & $b.is_negated & ")"


func `$`*(cell: BasesSigned): string =
  ## Convert cell to string, as Nim 2's `$` of `seq` does for messages.
  result = "@["
  for i in 0..<cell.count:
    if i > 0: result.add ", "
    result.add $cell.elements[i]
  result.add "]"


func len*(cell: BasesSigned): int {.inline.} = cell.count
  ## Count signed bases in cell.


func checked(i: int, cell: BasesSigned): int {.inline.} =
  ## Check position against count of cell, with text of index check of `seq`.
  assert i >= 0 and i < cell.count,
    (if cell.count == 0: "index out of bounds, the container is empty"
     else: "index " & $i & " not in 0 .. " & $(cell.count - 1))
  i


template `[]`*(cell: BasesSigned, i: int): BasisSigned = cell.elements[i.checked(cell)]
  ## Get signed basis at position in cell; its fields are assignable where cell is.

template `[]=`*(cell: var BasesSigned, i: int, b: BasisSigned) =
  ## Set signed basis at position in cell, as element of `seq` is set.
  cell.elements[i.checked(cell)] = b

iterator items*(cell: BasesSigned): BasisSigned =
  ## Iterate signed bases of cell in order.
  for i in 0..<cell.count: yield cell.elements[i]


func add*(cell: var BasesSigned, b: BasisSigned) =
  ## Append signed basis to cell.
  doAssert cell.count < cell.elements.len,
    "Cell of Cayley table needs more terms than `BasesSigned` holds; got `" & $b & "` for `" &
    $cell & "`."
  cell.elements[cell.count] = b
  cell.count += 1


func add*(cell: var BasesSigned, others: BasesSigned) =
  ## Append signed bases of other cell.
  for b in others: cell.add b


func add*(bases: var seq[BasisSigned], cell: BasesSigned) =
  ## Append signed bases of cell to sequence, as `add` of `seq` to `seq` does.
  for b in cell: bases.add b


func find*(cell: BasesSigned, b: BasisSigned): int =
  ## Find position of signed basis in cell, or -1, as `find` of `seq` does.
  for i in 0..<cell.count:
    if cell.elements[i] == b: return i
  -1


func delete*(cell: var BasesSigned, i: int) =
  ## Delete signed basis at position, keeping order of rest, as `delete` of `seq` does.
  doAssert i >= 0 and i < cell.count,
    "index out of bounds: '" & $i & "' < '" & $cell.count & "' failed"
  for j in i ..< cell.count - 1: cell.elements[j] = cell.elements[j + 1]
  cell.count -= 1
  cell.elements[cell.count] = default(BasisSigned)  # Equal cells stay equal values.


func toBasesSigned*(b: BasisSigned): BasesSigned =
  ## Convert signed basis to cell of one term.
  result = default(BasesSigned)
  result.add b



#[ Table Operations ]#

iterator pairs*[T](a: array[Basis, T]): (Basis, T) =
  ## Iterate bases with elements of array that they index, as `pairs` of array does under Nim 2.
  ##   Nimony's `pairs` gives position in array as `int`.
  for b in Basis: yield (b, a[b])
```

## Add `pga/cayleys/functions.nim`

```nim
## Construct Cayley tables, and transform bases and tables.
##
## Module of its own for Nimony, where Nim 2 library keeps functions in `cayleys.nim` after its
##   tables (`codeReordering`): Nimony evaluates `const` where it stands, so `definitions.nim`
##   imports functions that its tables call. Those are exported, as is `horizon` for
##   `operators.nim`, and `../cayleys.nim` re-exports none: Nim 2 library keeps them private.

import std/[assertions, bitops, sequtils, strutils]

import ../[algebra, basis]
import ./types



#[ Operation Construction ]#

func constructComplement*(chirality: Chirality): Cayley1D {.noinit.} =
  ## Construct Cayley table for left and right complements.
  for b in Basis:
    result[b] = b.complement(chirality).toBasesSigned


func constructParts*(partiality: Partiality): Formal[Cayley1D] {.noinit.} =
  ## Construct Cayley table for (round/flat) bulk/weight.
  ##   We can derive RGA parts from metric instead, however, CGA requires explicit construction.
  ##   E.g. this is, in RGA, equivalent to applying exomporphism as 𝐆𝐦 or 𝔾𝐦.

  func constructPart(inclusions, exclusions: seq[Basis]): Cayley1D {.noinit.} =
    ## Construct sub-slice of Cayley table respresenting identity map.
    for b in Basis:
      result[b] = b.toSigned.toBasesSigned
    result.filterFactors(inclusions)
    result.filterFactors(exclusions, as_exclusions = true)

  let  # Element type given to `inclusions`: Nimony infers none for `@[]` of first branch.
    inclusions: seq[Basis] = case partiality
      of Partiality.Bulk: @[]
      of Partiality.Weight: @[Basis.origin]
    exclusions = case partiality
      of Partiality.Bulk: @[Basis.origin]
      of Partiality.Weight: @[]

  when IS_RIGID:
    Formal[Cayley1D](round: constructPart(inclusions, exclusions))
  else:
    Formal[Cayley1D](  # `concat`: Nimony has no `&` of seqs.
      round: constructPart(inclusions, concat(exclusions, @[Basis.infinity])),
      flat: constructPart(concat(inclusions, @[Basis.infinity]), exclusions),
    )

func constructNormsSquared*(
  parts: Partial[Formal[Cayley1D]],
  partiality: Partiality,
): Formal[Cayley2D] =
  ## Construct unary 2D cayley tables for squared norms from parts.

  func constructNormSquared(part: Cayley1D, partiality: Partiality): Cayley2D =
    ## Construct unary 2D cayley table for squared norm from specific part.
    result = default(Cayley2D)
    let destination = case partiality:
        of Partiality.Bulk: Basis.scalar
        of Partiality.Weight: Basis.scalarAnti
    for b in Basis:
      if part[b].len == 0: continue
      assert part[b].toSigned == b.toSigned,
        "Provided part that is not 1-1 mapping; got `" & $part[b] & "` for `" & $b & "`."
      result[b][b].add(destination.toSigned)

  let parts_partial = case partiality
      of Partiality.Bulk: parts.bulk
      of Partiality.Weight: parts.weight
  when IS_RIGID:
    Formal[Cayley2D](round: constructNormSquared(parts_partial.round, partiality))
  else:
    Formal[Cayley2D](
      round: constructNormSquared(parts_partial.round, partiality),
      flat: constructNormSquared(parts_partial.flat, partiality),
    )


func constructReverse*(spatiality: Spatiality): Cayley1D {.noinit.} =
  ## Construct Cayley table for (anti)reverse.
  for b in Basis:
    result[b] = b.reverse(spatiality).toBasesSigned


func constructAnti*(cayley: Cayley1D, complements: Chiral[Cayley1D]): Cayley1D =
  ## Construct anti version of 1D cayley table by applying right (left) complement before (after).
  result = default(Cayley1D)
  for m in Basis:
    let operand = complements.right[m].toSigned

    for term in cayley[operand.basis]:
      let product = complements.left[term.basis].toSigned
      result[m].add BasisSigned(
        basis: product.basis,
        is_negated: operand.is_negated xor term.is_negated xor product.is_negated,
      )


func constructAnti*(cayley: Cayley2D, complements: Chiral[Cayley1D]): Cayley2D =
  ## Construct anti version of 2D cayley table by applying right (left) complement before (after).
  result = default(Cayley2D)
  for m in Basis:
    let m_from = complements.right[m].toSigned

    for n in Basis:
      let n_from = complements.right[n].toSigned

      for term in cayley[m_from.basis][n_from.basis]:
        let product_to = complements.left[term.basis].toSigned
        result[m][n].add BasisSigned(
          basis: product_to.basis,
          is_negated: (
            m_from.is_negated xor
            n_from.is_negated xor
            term.is_negated xor
            product_to.is_negated
          ),
        )


func constructMetric*(): Cayley1D =
  ## Construct metric 𝖌 simplified as 1D cayley table.
  result = default(Cayley1D)
  let
    𝐞ₙ = Basis.vectorLast
    𝐞ₙ₋₁ = 𝐞ₙ.pred
  for b in Basis:
    if b.grade <= Grade.vector and b != 𝐞ₙ:
      result[b] = b.toSigned.toBasesSigned

  # Adjust metric to conformal structure if necessary.
  when IS_CONFORMAL:
    result[𝐞ₙ] = BasisSigned(basis: 𝐞ₙ₋₁, is_negated: true).toBasesSigned
    result[𝐞ₙ₋₁] = BasisSigned(basis: 𝐞ₙ, is_negated: true).toBasesSigned


func constructExomorphismMetric*(metric: Cayley1D): Cayley1D {.noinit.} =
  ## Construct metric exomorphism 𝐆 from metric 𝖌 simplified as 1D cayley table.
  ##   𝖌 expands to 𝐆 via 𝐆(𝐦 ∧ 𝐧) = (𝐆𝐦) ∧ (𝐆𝐧).
  ##   Likewise with `constructAnti` applied on output:
  ##     𝔾 via 𝔾𝐦 = 𝐆̲𝐦̲̅, i.e. right complement of 𝐦, left complement of result.
  ##     Equivalent to expanding as 𝔾 via 𝔾(𝐦 ∨ 𝐧) = (𝔾𝐦) ∨ (𝔾𝐧).
  result = metric

  for operand in Basis:
    if operand.grade <= Grade.vector: continue
    var
      bases: seq[BasisSigned] = @[]
      is_degenerate = false

    # Determine if any vector component of basis is degenerate.
    for d in operand.toDigits:
      let basis = BasisDigits($d).toBasis
      if result[basis].len == 0:
        is_degenerate = true
        break
      bases.add(result[basis])
    if is_degenerate: continue

    # Reconstruct resulting signed basis from vector components.
    var product = multiplyExterior(bases[0], bases[1])
    assert not product.is_degenerate
    if len(bases) > 2:
      for i in 2..<bases.len:
        product = multiplyExterior(product.basis, bases[i])

    result[operand] = product.basis.toBasesSigned


func constructDual*(
  exomorphisms: Spatial[Cayley1D],
  complements: Chiral[Cayley1D],
  spatiality: Spatiality,
  chirality: Chirality,
): Cayley1D =
  ## Construct Cayley table for left/right (anti)dual.
  result = default(Cayley1D)
  let
    exomorphism = case spatiality
      of Spatiality.Base: exomorphisms.base
      of Spatiality.Anti: exomorphisms.anti
    complement = case chirality
      of Chirality.Left: complements.left
      of Chirality.Right: complements.right

  for operand, product in exomorphism:
    if product.len == 0: continue
    let
      product_signed = product.toSigned
      product_complement = complement[product_signed.basis].toSigned
    result[operand] = BasisSigned(
      basis: product_complement.basis,
      is_negated: product_signed.is_negated xor product_complement.is_negated,
    ).toBasesSigned


func constructProductExterior*(
  complements: Chiral[Cayley1D], spatiality: Spatiality
): Cayley2D =
  ## Construct Cayley table for specific exterior/(anti)wedge product.
  result = default(Cayley2D)
  for m in Basis:
    for n in Basis:
      # Retrieve product reduction if not degenerate.
      let product = case spatiality
        of Spatiality.Base: multiplyExterior(m.toSigned, n.toSigned)
        of Spatiality.Anti: multiplyExterior(
          complements.right[m].toSigned,
          complements.right[n].toSigned,
        )
      if product.is_degenerate: continue

      # Construct exterior product mappings.
      result[m][n].add(case spatiality
        of Spatiality.Base: product.basis
        of Spatiality.Anti:
          let product_complement = complements.left[product.basis.basis].toSigned
          BasisSigned(
            basis: product_complement.basis,
            is_negated: product.basis.is_negated xor product_complement.is_negated,
          )
      )


func constructProductInterior*(
  duals: Spatial[Chiral[Cayley1D]],
  wedges: Spatial[Cayley2D],
  space_dual: Spatiality,
  space_wedge: Spatiality,
  chirality: Chirality,
): Cayley2D =
  ## Construct Cayley table for specific interior product.
  result = default(Cayley2D)
  let
    dual = case space_dual
      of Spatiality.Base:
        case chirality
        of Chirality.Left: duals.base.left
        of Chirality.Right: duals.base.right
      of Spatiality.Anti:
        case chirality
        of Chirality.Left: duals.anti.left
        of Chirality.Right: duals.anti.right
    wedge = case space_wedge
      of Spatiality.Base: wedges.base
      of Spatiality.Anti: wedges.anti

  for m in Basis:
    for n in Basis:
      # Skip if necessary dual is degenerate.
      let is_degenerate = case chirality
        of Chirality.Left: dual[m].len == 0
        of Chirality.Right: dual[n].len == 0
      if is_degenerate: continue

      # Retrieve product reduction.
      let
        dual_signed = case chirality
          of Chirality.Left: dual[m].toSigned
          of Chirality.Right: dual[n].toSigned
        product = case chirality
          of Chirality.Left: wedge[dual_signed.basis][n]
          of Chirality.Right: wedge[m][dual_signed.basis]

      # Construct interior product mappings.
      for term in product:
        result[m][n].add BasisSigned(
          basis: term.basis,
          is_negated: dual_signed.is_negated xor term.is_negated,
        )


func constructProductInterior*(
  wedges_trans: array[Order, Cayley2D], spatiality: Spatiality, as_inner = false
): Cayley2D =
  ## Construct Cayley table for specific interior product.
  ##   Note: space must agree with provided transwedges.
  result = default(Cayley2D)
  for k in Order:
    for m in Basis:

      # Reduce transwedge to interior.
      let m_order = case spatiality
        of Spatiality.Base: Order(m.grade)
        of Spatiality.Anti: Order(m.gradeAnti)
      if m_order != k: continue

      for n in Basis:
        if as_inner and m.grade == n.grade:  # Reduce interior to inner.
          result[m][n].add(wedges_trans[k][m][n])
        elif not as_inner:
          result[n][m].add(wedges_trans[k][m][n])



func constructProductGeometric*(wedges_trans: array[Order, Cayley2D]): Cayley2D =
  ## Construct Cayley table for specific geometric product.
  result = default(Cayley2D)
  for order in Order:
    let
      k = int(order)
      is_negated = (k * (k - 1) div 2 and 1) == 1
    result.merge(wedges_trans[order], as_negated = is_negated)


func constructProductsTransitional*(
  complement: Cayley1D,
  dual: Cayley1D,
  wedges: Spatial[Cayley2D],
  chirality: Chirality,
  spatiality: Spatiality,
): array[Order, Cayley2D] =
  ## Construct Cayley tables for each order of specific transitional product.
  result = default(array[Order, Cayley2D])
  for order in Order:
    result[order] = constructProductTransitional(
      order,
      complement,
      dual,
      wedges,
      chirality,
      spatiality,
    )


func constructProductTransitional(
  order: Order,
  complement: Cayley1D,
  dual: Cayley1D,
  wedges: Spatial[Cayley2D],
  chirality: Chirality,
  spatiality: Spatiality,
): Cayley2D =
  ## Construct Cayley table for selected order of specific transitional product.
  result = default(Cayley2D)

  # Determine orientation of wedges.
  let
    wedge_outer = case spatiality
      of Spatiality.Base: wedges.anti
      of Spatiality.Anti: wedges.base
    wedge_inner = case spatiality
      of Spatiality.Base: wedges.base
      of Spatiality.Anti: wedges.anti

  for c in Basis:  # Note: Nesting likely required due to nature of transitive product.

    # Skip over grades of different orders.
    let c_order = case spatiality
      of Spatiality.Base: Order(c.grade)
      of Spatiality.Anti: Order(c.gradeAnti)
    if c_order != order: continue

    # Detect if dual degenerates.
    if dual[c].len == 0: continue

    # Determine sides for each operator.
    let
      c_complement = complement[c].toSigned
      c_dual = dual[c].toSigned
      operators = case chirality
        of Chirality.Left: Chiral[Basis](left: c_dual.basis, right: c_complement.basis)
        of Chirality.Right: Chiral[Basis](left: c_complement.basis, right: c_dual.basis)

    for m in Basis:

      # Reduce left side product.
      let products_left = wedge_outer[operators.left][m]
      if products_left.len == 0: continue

      for n in Basis:

        # Reduce right side product.
        let products_right = wedge_outer[n][operators.right]
        if products_right.len == 0: continue

        # Reduce product between both sides.
        let
          product_left = products_left.toSigned
          product_right = products_right.toSigned
          products_center = wedge_inner[product_left.basis][product_right.basis]
        if products_center.len == 0: continue

        # Construct transitional product mappings.
        let
          product_center = products_center.toSigned
          is_negated = (
            c_dual.is_negated xor
            c_complement.is_negated xor
            product_left.is_negated xor
            product_center.is_negated xor
            product_right.is_negated
          )
        result[m][n].add BasisSigned(basis: product_center.basis, is_negated: is_negated)



#[ Basis Transformations ]#

func complement(b: Basis, chirality: Chirality): BasisSigned =
  ## Get complement of basis (right by default).
  let
    mask = Basis.scalarAnti.toFlags
    antibasis = (not b.toFlags and mask).toBasis.toSigned
    antiscalar = case chirality
      of Chirality.Left: multiplyExterior(antibasis, b.toSigned)
      of Chirality.Right: multiplyExterior(b.toSigned, antibasis)
  BasisSigned(basis: antibasis.basis, is_negated: antiscalar.basis.is_negated)


func reverse(b: Basis, spatiality: Spatiality): BasisSigned =
  ## Get specific reverse of basis.
  let
    grade = case spatiality
      of Spatiality.Base: int(b.grade)
      of Spatiality.Anti: int(b.gradeAnti)
    parity = ((int(grade * (grade - 1)) div 2) and 1) == 1
  BasisSigned(basis: b, is_negated: parity)


func multiplyExterior(
  a, b: BasisSigned
): tuple[basis: BasisSigned, is_degenerate: bool] =
  ## Perform exterior product of two bases, reducing to its standard basis form.
  ##   If duplicate 1-vectors are present, `is_degenerate` returns true.
  ##   Uses bit operations instead of inverting vectors anti-commutively, remaining equivalent.
  result = default(tuple[basis: BasisSigned, is_degenerate: bool])

  # Degenerate in presence of duplicate vectors.
  let (a_flags, b_flags) = (a.basis.toFlags, b.basis.toFlags)
  if countSetBits(a_flags) + countSetBits(b_flags) != countSetBits(a_flags xor b_flags):
    result.is_degenerate = true
    return

  # Determine parity in parts (equivalent to counting inversions and anti-commuting).
  #   If lexicographical ordering, this would simplify to parity of joining left and right inputs.
  #   Instead parity of two inputs and final output must be found relative to canonical ordering.
  #   I.e. must first map from canonical to lexicographical, compute parity, then map back.
  #   All due to using Lengyel's ordering, chosen for interop with standard linear algebra.
  let
    parity_a = isNegatedFromOrderLexicographic(a.basis) xor a.is_negated
    parity_b = isNegatedFromOrderLexicographic(b.basis) xor b.is_negated
    parity_order = isNegatedByJoinLexicographic(a_flags, b_flags)
    basis_product = toBasis(a_flags xor b_flags)
    parity_product = isNegatedFromOrderLexicographic(basis_product)
  result.basis = BasisSigned(
    basis: basis_product,
    is_negated: parity_a xor parity_b xor parity_order xor parity_product,
  )


func toSigned*(b: Basis): BasisSigned {.noinit.} = BasisSigned(basis: b)
  ## Convert basis to signed basis assuming positive.


func toSigned(product: BasesSigned): BasisSigned =
  ## Convert cayley product cell to signed basis where is singleton.
  assert product.len == 1, "Attempt to extract singular product term from `" & $product & "`."
  product[0]



#[ Cayley Transformations ]#

func applyConstant*(
  cayley: var Cayley2D, basis: BasisSigned, chirality: Chirality
): Cayley1D {.noinit.} =
  ## Collapse 2D cayley into 1D by applying contstant unit basis to left or right operand.

  case chirality
    of Chirality.Left:
      cayley.filterBases(operands_m = @[basis.basis])
    of Chirality.Right:
      cayley.filterBases(operands_n = @[basis.basis])

  result = cayley.slice(basis.basis, chirality)

  for operand in Basis:
    if result[operand].len == 0: continue
    let product_signed = result[operand].toSigned
    result[operand] = BasisSigned(
      basis: product_signed.basis,
      is_negated: product_signed.is_negated xor basis.is_negated,
    ).toBasesSigned


func filterBases(
  cayley: var Cayley1D,
  operands = default(seq[Basis]),
  products = default(seq[Basis]),
  as_exclusions = false,
) =
  ## Filter out specific operands/products from 1D cayley table by bases.
  for operand in Basis:
    if cayley[operand].len == 0: continue

    # Filter by operand.
    if (operands.len != 0 and operand notin operands) or (as_exclusions and operand in operands):
      cayley[operand] = default(BasesSigned)
      continue

    # Filter by product.
    let product_signed = cayley[operand].toSigned
    if (products.len != 0 and product_signed.basis notin products) or
        (as_exclusions and product_signed.basis in products):
      cayley[operand] = default(BasesSigned)


func filterBases*(
  cayley: var Cayley2D,
  operands_m: seq[Basis] = default(seq[Basis]),
  operands_n: seq[Basis] = default(seq[Basis]),
  products: seq[Basis] = default(seq[Basis]),
  as_exclusions = false,
) =
  ## Filter out specific operands/products from 2D cayley table by bases.
  ##   Type given to each parameter that defaults to call: `applyConstant` calls this filter
  ##     above its declaration, where Nimony types such parameter as `auto`.
  for m in Basis:

    # Filter by m operands.
    if (operands_m.len != 0 and m notin operands_m) or (as_exclusions and m in operands_m):
      for n in Basis:
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
          break


func filterGrades(
  cayley: var Cayley1D,
  operands = default(seq[Grade]),
  products = default(seq[Grade]),
  as_exclusions = false,
) =
  ## Filter out specific operands/products from 1D cayley table by grades.
  for operand in Basis:
    if cayley[operand].len == 0: continue

    # Filter by operand grade.
    if (operands.len != 0 and operand.grade notin operands) or
        (as_exclusions and operand.grade in operands):
      cayley[operand] = default(BasesSigned)
      continue

    # Filter by product grade.
    let product_signed = cayley[operand].toSigned
    if (products.len != 0 and product_signed.basis.grade notin products) or
        (as_exclusions and product_signed.basis.grade in products):
      cayley[operand] = default(BasesSigned)


func filterGrades*(
  cayley: var Cayley2D,
  operands_m = default(seq[Grade]),
  operands_n = default(seq[Grade]),
  products = default(seq[Grade]),
  as_exclusions = false,
) =
  ## Filter out specific operands/products from 2D cayley table by bases.
  for m in Basis:

    # Filter by m operands.
    if (operands_m.len != 0 and m.grade notin operands_m) or
        (as_exclusions and m.grade in operands_m):
      for n in Basis:
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
          break


func filterFactors(
  cayley: var Cayley1D, factors: seq[Basis], as_exclusions = false
) =
  ## Filter out specific operands/products from 1D cayley table.
  for f in factors:
    assert countSetBits(f.toFlags) == 1,
      "Attempt to filter with non-grade 1 basis factor: `f=" & $f & "`."

  for operand in Basis:

    # Determine if basis contains filtered vector factor.
    let operand_flags = operand.toFlags
    var should_filter = false
    for f in factors:
      let flags_overlap = f.toFlags and operand_flags
      if (as_exclusions and int(flags_overlap) != 0) or
          (not as_exclusions and int(flags_overlap) == 0):
        should_filter = true
        break
    if should_filter:
      cayley[operand] = default(BasesSigned)


func merge(destination: var Cayley2D, source: Cayley2D, as_negated = false) =
  ## Merge two 2D cayley tables in place, simplifying/cancelling opposing terms.
  for m in Basis:
    for n in Basis:
      for term in source[m][n]:

        # Cancel out opposing (or matching) terms found after merge.
        #   Cancels matching where `as_negated=true`.
        let
          is_negated = not term.is_negated xor as_negated
          term_cancel = BasisSigned(basis: term.basis, is_negated: is_negated)
          position = destination[m][n].find(term_cancel)
        if position != -1:
          destination[m][n].delete(position)
          continue

        # Add term if not cancelled.
        destination[m][n].add BasisSigned(
          basis: term.basis,
          is_negated: term.is_negated xor as_negated,
        )


func negate(cayley: var Cayley1D) {.used.} =  # Not used; provided for completion.
  ## Negate all signed basis of 1D cayley table in place.
  for operand in Basis:
    if cayley[operand].len == 0: continue
    cayley[operand][0].is_negated = not cayley[operand].toSigned.is_negated


func negate*(cayley: var Cayley2D) =
  ## Negate all signed basis of 2D cayley table in place.
  for m in Basis:
    for n in Basis:
      for term in 0..<cayley[m][n].len:
        cayley[m][n][term].is_negated = not cayley[m][n][term].is_negated


func slice*(
  cayley: Cayley2D, operand: Basis, chirality: Chirality
): Cayley1D {.noinit.} =
  ## Extract vertical slice of 2D cayley as 1D map.
  for b in Basis:
    let terms = case chirality
      of Chirality.Left: cayley[operand][b]
      of Chirality.Right: cayley[b][operand]
    assert terms.len <= 1,
      "Attempt to convert 2D cayley to 1D with non-singleton product values;" &
      " got `" & $terms & "` for `" & $chirality & "` `" & $operand & "`."
    result[b] = if terms.len == 1: terms.toSigned.toBasesSigned else: default(BasesSigned)



#[ Basis Ordering ]#

func isNegatedFromOrderLexicographic(b: Basis): bool =
  ## Determine if canonically ordered basis is negated relative to lexicographical order.
  ##   Counts directly, where Nim 2 library builds lookup table: each `const` costs Nimony one
  ##     compiled program, and this function runs only at compile time.
  let digits = b.toDigits
  var inversions = 0
  for i in 0..<len(digits):
    for j in i + 1 ..< len(digits):
      if digits[i] > digits[j]:
        inversions += 1

  # Determine if parity (negation) bit set.
  (inversions and 1) == 1


func isNegatedByJoinLexicographic(a, b: BasisFlags): bool =
  ## Determine if joining two lexicographically ordered bases negates result.
  let a_flags = uint(a)
  var
    b_flags_remaining = uint(b)
    swaps = 0

  # Count `a` flags greater than each `b` flag (i.e. requires swap).
  while b_flags_remaining != 0:
    let
      offset_b_flags_min = trailingZeroBits(b_flags_remaining)  # Nimony's `countTrailingZeroBits`.
      count_flags_where_a_greater = countSetBits(a_flags shr (offset_b_flags_min + 1))
    swaps += count_flags_where_a_greater

    # Clear `b` flags already accounted for.
    b_flags_remaining = b_flags_remaining and (b_flags_remaining - 1)

  # Determine if parity (negation) bit remains set.
  (swaps and 1) == 1



#[ Basis Aliasing ]#

func horizon*(t: typedesc[Basis]): BasisSigned =
  ## Alias basis representing horizon (i.e. 𝐞̄ₙ in RGA; 𝐞̄ₙ₋₁ in CGA).
  ##   TODO: Is 𝐞̄ₙ₋₁ horizion in conformal?
  Basis.origin.complement(Chirality.Right)
```

## Add `pga/cayleys/definitions.nim`

```nim
## Define Cayley tables of algebra's operations.
##
## Module of its own for Nimony, where Nim 2 library defines tables first in `cayleys.nim`
##   (`codeReordering`): Nimony evaluates `const` where it stands, so tables import functions
##   that they call from `functions.nim`.

import ../algebra
import ./[functions, types]



#[ Cayley Definitions ]#

const
  CAYLEYS_COMPLEMENT* = Chiral[Cayley1D](
    left: constructComplement(Chirality.Left),
    right: constructComplement(Chirality.Right),
  )
  CAYLEYS_PARTS* = Partial[Formal[Cayley1D]](
    bulk: constructParts(Partiality.Bulk),
    weight: constructParts(Partiality.Weight),
  )
  CAYLEYS_REVERSE* = Spatial[Cayley1D](
    base: constructReverse(Spatiality.Base),
    anti: constructReverse(Spatiality.Anti),
  )

const
  CAYLEY_METRIC* = constructMetric()
  CAYLEYS_EXOMORPHISM_METRIC* = block:
    let base = constructExomorphismMetric(CAYLEY_METRIC)
    Spatial[Cayley1D](
      base: base,
      anti: base.constructAnti(CAYLEYS_COMPLEMENT),
    )
  CAYLEYS_WEDGE* = block:
    let base = constructProductExterior(CAYLEYS_COMPLEMENT, Spatiality.Base)
    Spatial[Cayley2D](
      base: base,
      anti: base.constructAnti(CAYLEYS_COMPLEMENT),
    )

const
  CAYLEYS_DUAL* = Spatial[Chiral[Cayley1D]](
    base: Chiral[Cayley1D](
      left: constructDual(
        CAYLEYS_EXOMORPHISM_METRIC, CAYLEYS_COMPLEMENT, Spatiality.Base, Chirality.Left
      ),
      right: constructDual(
        CAYLEYS_EXOMORPHISM_METRIC, CAYLEYS_COMPLEMENT, Spatiality.Base, Chirality.Right
      ),
    ),
    anti: Chiral[Cayley1D](
      left: constructDual(
        CAYLEYS_EXOMORPHISM_METRIC, CAYLEYS_COMPLEMENT, Spatiality.Anti, Chirality.Left
      ),
      right: constructDual(
        CAYLEYS_EXOMORPHISM_METRIC, CAYLEYS_COMPLEMENT, Spatiality.Anti, Chirality.Right
      ),
    ),
  )

const
  CAYLEYS_WEDGES_TRANS* = Spatial[array[Order, Cayley2D]](
    base: constructProductsTransitional(
      CAYLEYS_COMPLEMENT.left,
      CAYLEYS_DUAL.base.right,
      CAYLEYS_WEDGE,
      Chirality.Right,
      Spatiality.Base,
    ),
    anti: constructProductsTransitional(
      CAYLEYS_COMPLEMENT.left,
      CAYLEYS_DUAL.anti.right,
      CAYLEYS_WEDGE,
      Chirality.Right,
      Spatiality.Anti,
    ),
  )


const
  # TODO: Derive from base operators.
  CAYLEYS_INTERIOR* = Spatial[Partial[Chiral[Cayley2D]]](
    base: Partial[Chiral[Cayley2D]](
      bulk: Chiral[Cayley2D](
        left: constructProductInterior(
          CAYLEYS_DUAL,
          CAYLEYS_WEDGE,
          space_dual = Spatiality.Base,
          space_wedge = Spatiality.Base,
          Chirality.Left,
        ),
        right: constructProductInterior(
          CAYLEYS_DUAL,
          CAYLEYS_WEDGE,
          space_dual = Spatiality.Base,
          space_wedge = Spatiality.Base,
          Chirality.Right,
        ),
      ),
      weight: Chiral[Cayley2D](
        left: constructProductInterior(
          CAYLEYS_DUAL,
          CAYLEYS_WEDGE,
          space_dual = Spatiality.Anti,
          space_wedge = Spatiality.Base,
          Chirality.Left,
        ),
        right: constructProductInterior(
          CAYLEYS_DUAL,
          CAYLEYS_WEDGE,
          space_dual = Spatiality.Anti,
          space_wedge = Spatiality.Base,
          Chirality.Right,
        ),
      ),
    ),
    anti: Partial[Chiral[Cayley2D]](
      bulk: Chiral[Cayley2D](
        left: constructProductInterior(
          CAYLEYS_DUAL,
          CAYLEYS_WEDGE,
          space_dual = Spatiality.Base,
          space_wedge = Spatiality.Anti,
          Chirality.Left,
        ),
        right: constructProductInterior(
          CAYLEYS_DUAL,
          CAYLEYS_WEDGE,
          space_dual = Spatiality.Base,
          space_wedge = Spatiality.Anti,
          Chirality.Right,
        ),
      ),
      weight: Chiral[Cayley2D](
        left: constructProductInterior(
          CAYLEYS_DUAL,
          CAYLEYS_WEDGE,
          space_dual = Spatiality.Anti,
          space_wedge = Spatiality.Anti,
          Chirality.Left,
        ),
        right: constructProductInterior(
          CAYLEYS_DUAL,
          CAYLEYS_WEDGE,
          space_dual = Spatiality.Anti,
          space_wedge = Spatiality.Anti,
          Chirality.Right,
        ),
      ),
    ),
  )
  CAYLEYS_DOT* = block:
    # TODO: Filter grade of bulk contraction instead of using transwedge.
    let base =
      constructProductInterior(CAYLEYS_WEDGES_TRANS.base, Spatiality.Base, as_inner = true)
    Spatial[Cayley2D](
      base: base,
      anti: base.constructAnti(CAYLEYS_COMPLEMENT),
    )

const
  CAYLEYS_WEDGE_DOT* = Spatial[Cayley2D](
    base: constructProductGeometric(CAYLEYS_WEDGES_TRANS.base),
    anti: constructProductGeometric(CAYLEYS_WEDGES_TRANS.anti),
  )

const
  CAYLEYS_NORM_SQUARED* = Partial[Formal[Cayley2D]](
    bulk: constructNormsSquared(CAYLEYS_PARTS, Partiality.Bulk),
    weight: constructNormsSquared(CAYLEYS_PARTS, Partiality.Weight),
  )
when IS_CONFORMAL:
  const CAYLEYS_NORM_SQUARED_RADIUS* = block:
    var cayley = CAYLEYS_DOT.anti
    cayley.filterGrades(products = @[Grade.high])
    cayley

const
  CAYLEY_ATTITUDE*: Cayley1D = block:
    var cayley = CAYLEYS_WEDGE.anti
    cayley.filterBases(operands_n = @[Basis.horizon.basis])
    if Basis.horizon.is_negated: cayley.negate()
    cayley.slice(Basis.horizon.basis, Chirality.Right)

when IS_CONFORMAL:
  const CAYLEY_CARRIER*: Cayley1D = block:
    var cayley = CAYLEYS_WEDGE.base
    cayley.applyConstant(Basis.infinity.toSigned, Chirality.Right)
```

## Replace `pga/multivectors.nim` from `17defb086d8fae40`

```nim
## Define fundamental geometric types of PGA.

# TODO: Represent multivector primitives using more compact data types.
#   E.g. Point, Line, Plane, Volume, Motor, Flector.
#   At cost of additional meta-programming, this affords:
#     - More optimization with SoA (how much more over SIMD of multivectors?),
#     - Simpler reasoning about objects resulting from operations.
#     - IDE support for recognizing resulting objects from operations.
#   Perhaps base library should only contain full multivector operations for simplicity?
#     I.e. to serve more as learning reference, optimising where necessary.
# TODO: Implement SIMD cayley table based macros for operating on arrays of Multivectors.

import std/[math, options, parseutils, strutils, unicode]

import ./algebra



#[ Type Definition ]#

type
  Bases* = set[Basis]  ## TODO: Make distinct.
  MultivectorOf*[B: static Bases] = object
    elements: array[B.card, Coefficient]
  Multivector* = MultivectorOf[{Basis.scalar..Basis.scalarAnti}]
    ## Define generalised multivector for n-dimensional PGA.
  MultivectorScalars* = MultivectorOf[{Basis.scalar, Basis.scalarAnti}]
    ## Define generalised dual numbers for n-dimensional PGA.


func constructLutKvector(): array[Grade.low..Grade.high, set[Basis]] =
  ## Construct LUT for kvector basis sets.
  ##   Outside plugin, which sees values but no `Basis`: Nimony runs plugin as program of its own.
  result = default(array[Grade.low..Grade.high, set[Basis]])
  for b in Basis:
    result[b.grade].incl(b)

func constructVectorParity(as_odd = false): set[Basis] =
  ## Construct parity vector basis set.
  result = {}
  for b in Basis:
    let is_even = int(b.grade) mod 2 == 0
    if (not as_odd and is_even) or (as_odd and not is_even):
      result.incl(b)

template defineMultivectors(
  kvectors: static[array[Grade.low..Grade.high, set[Basis]]];
  even, odd: static[set[Basis]];
) {.plugin: "emitters".}
  ## Define specialized subtypes for n-dimensional PGA.
  ##   This indirection is necessary as enums must be contiguous (e.g. for scalars/even/odd).
  ##     The ideal would be using sub ranges (e.g. E1..E4 for grade 1, E41..E12 for grade 2).
  ##   Plugin receives basis sets as values, and emits one type per set.
  ##   No return type, where macro has `untyped`: Nimony gives every phase only to code of
  ##     plugin template without one, and declarations need each phase.

defineMultivectors(
  kvectors = static(constructLutKvector()),
  even = static(constructVectorParity()),
  odd = static(constructVectorParity(as_odd = true)),
)



#[ Multivector Accessors ]#

func index*[B: static Bases](b: Basis): range[0 .. B.card-1] {.inline, noinit.} =
  ## Convert basis to subset index.
  ##   Note: returns range instead of int, avoiding uncecessary checks in generated output.
  ##   Counts with table of `{Basis.scalar..b}` for each `b`, where Nim 2 library builds table of
  ##     index for each `B`: Nimony's `const` in generic runs without `B`, and folds no set
  ##     comparison, so test compares `card` instead. Range set of run-time `b` is loop, one
  ##     basis per pass. Table stays in `index`: Nimony writes it once per instance, into C of
  ##     main module, where C compiler folds constant `b`; other modules read it as `extern const`.
  ##   States bound with `{.assume.}`: Nimony proves range at compile time, and cannot bound
  ##     `ord(b)` or `card(...) - 1` alone. Holds: `b` is in `B`, as checked.
  let i =
    when B.card == card({Basis.scalar..Basis.scalarAnti}):
      ord(b)
    else:
      const bases_up_to = block:
        var lut {.noinit.}: array[Basis, Bases]
        for b in Basis:
          lut[b] = {Basis.scalar..b}
        lut

      doAssert b in B,
        "Attempt invalid basis access on multivector; got `" & $b & "` for `" & $B & "`."
      card(B * bases_up_to[b]) - 1
  {.assume: 0 <= i and i < B.card.}
  i


template `[]`*[B: static Bases](m: MultivectorOf[B], b: Basis): Coefficient =
  ## Get coefficient of specific basis from multivector.
  ##   No `static(...)` branch, where Nim 2 library has one: Nimony decides `when` of template
  ##     where template is defined, so that branch never runs; `index` result needs no check.
  m.elements[index[B](b)]


template `[]=`*[B: static Bases](m: var MultivectorOf[B], b: Basis, c: Coefficient) =
  ## Set coefficient of specific basis in multivector.
  ##   Replaces Nim 2 library's `var` template: Nimony has no overloading on `var`, and
  ##     needs `[]=` for `m[b] = c`. Expansion of `[]` stays assignable, so `m[b] += c` works.
  m.elements[index[B](b)] = c


func `{}`*[G: Grade | GradeAnti](m: Multivector, grade: G): Multivector {.untyped.} =
  ## Select (anti)grade-vector part from multivector, i.e. ⟨𝐦⟩k or ⟨𝐦⟩𝕜.
  ##   `.untyped`: Nimony binds generic body once at definition, and only `GradeAnti`
  ##     has `toBase`.
  result = default(Multivector)
  let g = when G is GradeAnti: grade.toBase else: grade
  let bases = LUT_BASES_BY_GRADE[g]
  for b in bases.a .. bases.b:  # Nimony has no `items` for stored `Slice`.
    result[b] = m[b]


const LUT_BASES_BY_GRADE*: array[Grade.low..Grade.high, Slice[Basis]] = block:
  var
    lut {.noinit.}: array[Grade.low..Grade.high, Slice[Basis]]
    offset = 0
  for g in Grade.low..Grade.high:
    let coefficient_binomial = binom(int(Grade.high), int(g))
    lut[g] =
      if g == Grade.low or g == Grade.high: Basis(offset)..Basis(offset)
      else: Basis(offset)..<Basis(offset + coefficient_binomial)
    offset += coefficient_binomial
  lut



#[ Multivector Construction ]#

func initElement*(b: Basis, scalar: Coefficient = 1'f): Multivector =
  ## Construct multivector with single basis element.
  result = default(Multivector)
  result[b] = scalar


func parseFloat(s: string): Coefficient =
  ## Parse coefficient from literal, as Nim 2's `strutils.parseFloat` does for constructors.
  ##   Nimony has no `strutils.parseFloat`; `parseutils.parseFloat` returns characters read.
  ##     It reads `infinity`, and no lone `.`, where Nim 2 does reverse.
  ##   Rejects partial input with text of Nim 2, which raises `ValueError`; Nimony routine
  ##     raises only where marked, so assertion stops program instead.
  var value = 0.0
  doAssert s.len != 0 and parseutils.parseFloat(s, value) == s.len, "invalid float: " & s
  Coefficient(value)


template defineBasisElementConstructors(bases: static[set[Basis]]) {.plugin: "emitters".}
  ## Generate UFCS and literal constructors for each basis element.
  ##   Plugin receives bases as value, and emits two functions per basis.

defineBasisElementConstructors(static({Basis.scalar.succ..Basis.scalarAnti}))



#[ Multivector Comparison ]#

func `==`*(m, n: Multivector): bool {.error:
  "Use approximate comparison, `=~`, or compare elements directly."
.}


func `=~`(a, b: Coefficient): bool =
  ## Compare approximate equality between scalars, i.e. 𝐬 ≈ 𝐬.
  ##   `float(...)`: Nim 2 types `max(1.0, x)` as 64-bit, also where `Coefficient` is 32-bit, so
  ##     its tolerance is 64-bit; Nimony types it as `x`.
  abs(a - b) <= TOLERANCE_ABS * max(1.0, float(max(abs(a), abs(b))))


func `=~`*(m: Multivector, s: Coefficient): bool =
  ## Compare approximate equality between multivector and scalar, i.e. 𝐦 ≈ 𝐬.

  # TODO: Scale tolerance based on max of parts in isolation (not max overall).
  if not (m[Basis.scalar] =~ s):
    return false
  for b in Basis.scalar.succ..Basis.scalarAnti:
    if not (m[b] =~ 0.0):
      return false
  true


template `=~`*(s: Coefficient, m: Multivector): bool =
  ## Compare approximate equality between scalar and multivector, i.e. 𝐬 ≈ 𝐦.
  m =~ s


# func `=~`*(m, n: Multivector): bool =
#   ## Compare approximate equality between multivectors, i.e. 𝐦 ≈ 𝐧.
#   for b in Basis:
#     if not (m[b] =~ n[b]):
#       return false
#   true


func `=~`*[B: static Bases](m, n: MultivectorOf[B]): bool =
  ## Compare approximate equality between multivectors, i.e. 𝐦 ≈ 𝐧.
  for b in B:
    if not (m[b] =~ n[b]):
      return false
  true



#[ Multivector Conversion ]#


func toMultivectorOf*[A, B: static Bases](m: MultivectorOf[A]): MultivectorOf[B] {.inline.} =
  ## Convert between compatible multivector forms.
  result = default(MultivectorOf[B])
  for b in A:
    doAssert b in B or m[b] =~ 0.0,
      "Attempt to convert mutlivector with coefficient conflict; got `" & $m[b] & "` for `" &
      $b & "`."
    if b in B:
      result[b] = m[b]


# TODO: Define to converters for every compatible multivector forms.
#   I.e. for all compatible demotions and promotion to full multivector.

func toMultivector*[B: static Bases](m: MultivectorOf[B]): Multivector {.inline.} =
  ## TODO: Define via macro.
  result = default(Multivector)
  for b in B:
    result[b] = m[b]

func toMultivectorScalars*[B: static Bases](m: MultivectorOf[B]): MultivectorScalars {.inline.} =
  ## TODO: Define via macro.
  toMultivectorOf[B, {Basis.scalar, Basis.scalarAnti}](m)



#[ Multivector Arithmetic ]#

func `+`*[B: static Bases](m, n: MultivectorOf[B]): MultivectorOf[B] {.inline, noinit.} =
  ## Add multivectors, i.e. 𝐦 + 𝐧.
  for b in B:
    result[b] = m[b] + n[b]


func `+`*(s: Coefficient, m: Multivector): Multivector {.inline, noinit.} =
  ## Add scalar and multivector, i.e. 𝐬 + 𝐦.
  result[Basis.scalar] = s + m[Basis.scalar]
  for b in Basis.scalar.succ..Basis.scalarAnti:
    result[b] = m[b]



template `+`*(m: Multivector, s: Coefficient): Multivector =
  ## Add multivector and scalar, i.e. 𝐦 + 𝐬.
  s + m


func `-`*(m: Multivector): Multivector {.inline, noinit.} =
  ## Negate multivector, i.e. −𝐦.
  for b in Basis:
    result[b] = -m[b]


func `-`*(m, n: Multivector): Multivector {.inline, noinit.} =
  ## Subtract multivectors, i.e. 𝐦 − 𝐧.
  for b in Basis:
    result[b] = m[b] - n[b]


func `-`*(s: Coefficient, m: Multivector): Multivector {.inline, noinit.} =
  ## Subtract multivector from scalar, i.e. 𝐬 − 𝐦.
  result[Basis.scalar] = s - m[Basis.scalar]
  for b in Basis.scalar.succ..Basis.scalarAnti:
    result[b] = -m[b]


func `-`*(m: Multivector, s: Coefficient): Multivector {.inline, noinit.} =
  ## Subtract scalar from multivector, i.e. 𝐦 − 𝐬.
  result[Basis.scalar] = m[Basis.scalar] - s
  for b in Basis.scalar.succ..Basis.scalarAnti:
    result[b] = m[b]



#[ Multivector Queries ]#

func formatSigned(c: Coefficient): string =
  ## Format coefficient with sign, as `fmt"{c:+1G}"` does.
  ##   Nimony has no `strformat`; `formatFloat` is what `strformat` of Nim 2 calls for `G`.
  result = formatFloat(float(c), precision = -1).toUpperAscii
  if not result.startsWith("-"): result = "+" & result


func `$`*(m: Multivector): string =
  ## Convert multivector to readable string representation.
  result = ""

  # Format all non-scalar elements.
  const codepoint_subscript_zero = 0x2080
  for b in Basis:
    if abs(m[b]) > TOLERANCE_ABS:
      # Convert digits to subscript.
      let b_string = $b
      var subscript = ""
      for c in b_string[1 .. ^1]:
        let offset = ord(c) - ord('0')
        subscript.add Rune(codepoint_subscript_zero + offset)
      let postfix = case b
        of Basis.scalar: "𝟏"
        of Basis.scalarAnti: "𝟙"
        else: "𝐞" & subscript
      result = result & " " & formatSigned(m[b]) & postfix

  # Handle case where all elements are epsilon.
  if result == "": return "0𝟏"

  # Cleanup formatting.
  for e in ["𝟏", "𝐞", "𝟙"]:  # Simplify unit vectors.
    result = result.replace("+1" & e, "+" & e).replace("-1" & e, "-" & e)
  if result.startsWith(" +"): result = result[2 .. ^1]  # Clean up prefix.
  result = result.replace(" +", " + ").replace(" -", " - ")  # Add sign spacing.


func grade*(m: Multivector): Option[Grade] =
  ## Get grade of multivector, if k-vector.
  result = none[Grade]()
  var found_grade = false
  for b in Basis:
    if abs(m[b]) <= TOLERANCE_ABS: continue

    if result.isNone:
      found_grade = true
      result = some(b.grade)
    elif result.get != b.grade:  # Detect mixed grade.
      return none[Grade]()

  if not found_grade: result = some(Grade.low)  # Assume 0𝟏 is grade 0.


func gradeAnti*(m: Multivector): Option[GradeAnti] =
  ## Get antigrade of multivector, if k-antivector.
  result = none[GradeAnti]()
  let grade = m.grade
  if grade.isNone: return
  some(GradeAnti(Grade.high - grade.get))


template isMixed*(m: Multivector): bool = m.grade.isNone
  ## Determine if multivector is mixed grade.
```

## Replace `pga/operators.nim` from `0cc880da7691782b`

```nim
## TODO: Document.

# TODO: Implement in-place options for unary operators.
#         Maybe best to use template for defining both at once?

import std/[math, options]

import ./[algebra, cayleys, multivectors]
from ./cayleys/functions import horizon  # Where Nim 2 library imports `cayleys {.all.}`.



#[ Operator Macros ]#

# TODO: Can actually filter operands/product at cayley table step.
#   That way can filter by grade aor basis.
#   Similar to merge/negate.
template defineOperator(
  symbols, docs: static[string];
  cayley: static[Cayley1D];
) {.plugin: "emitters".}
  ## Construct multivector mapping variant using provided Cayley table.
  ##   Nim 2 library uses macro, which Nimony runs without access to library code.
  ##   Plugin receives table as value, through `static(...)` at call site.
  ##   No return type, where macro has `untyped`: Nimony gives every phase only to code of
  ##     plugin template without one, and declarations need each phase.


template defineOperator(
  symbols, docs: static[string];
  cayley: static[Cayley2D];
  as_unary: static[bool] = false;
) {.plugin: "emitters".}
  ## Construct multivector product variant using provided Cayley table.



#[ Operator Definitions ]#

defineOperator(
  symbols = "∙",
  docs = "Extract (round) bulk of multivector, i.e. 𝐦∙.",
  cayley = static(CAYLEYS_PARTS.bulk.round),
)
defineOperator(
  symbols = "∘",
  docs = "Extract (round) weight of multivector, i.e. 𝐦∘.",
  cayley = static(CAYLEYS_PARTS.weight.round),
)
when IS_CONFORMAL:
  defineOperator(
    symbols = "■",
    docs = "Extract flat bulk of multivector, i.e. 𝐦■.",
    cayley = static(CAYLEYS_PARTS.bulk.flat),
  )
  defineOperator(
    symbols = "□",
    docs = "Extract flat weight of multivector, i.e. 𝐦□.",
    cayley = static(CAYLEYS_PARTS.weight.flat),
  )

defineOperator(
  symbols = "/",
  docs = "Get right complement of multivector, i.e. 𝐦̅.",
  cayley = static(CAYLEYS_COMPLEMENT.right),
)
defineOperator(
  symbols = r"\",
  docs = "Get left complement of multivector, i.e. 𝐦̲.",
  cayley = static(CAYLEYS_COMPLEMENT.left),
)
defineOperator(
  symbols = "~",
  docs = "Get reverse of multivector, i.e. 𝐦̃.",
  cayley = static(CAYLEYS_REVERSE.base),
)
defineOperator(
  symbols = r"~∘",
  docs = "Get antireverse of multivector, i.e. 𝐦̰.",
  cayley = static(CAYLEYS_REVERSE.anti),
)

defineOperator(
  symbols = "★",
  docs = "Get right dual of multivector's bulk components, i.e. 𝐦★.",
  cayley = static(CAYLEYS_DUAL.base.right),
)

defineOperator(
  symbols = "☆",
  docs = "Get right dual of multivector's weight components, i.e. 𝐦☆.",
  cayley = static(CAYLEYS_DUAL.anti.right),
)

defineOperator(
  symbols = "∧",
  docs = "Multiply multivectors through exterior product, i.e. 𝐦 ∧ 𝐧.",
  cayley = static(CAYLEYS_WEDGE.base),
)
defineOperator(
  symbols = "∨",
  docs = "Multiply multivectors through exterior antiproduct, i.e. 𝐦 ∨ 𝐧.",
  cayley = static(CAYLEYS_WEDGE.anti),
)

defineOperator(
  symbols = "∙",
  docs = "Multiply multivectors through inner product, i.e. 𝐦∙𝐧 = (𝐦ᵀ𝐆𝐧)𝟏.",
  cayley = static(CAYLEYS_DOT.base),
)
defineOperator(
  symbols = "∘",
  docs = "Multiply multivectors through inner antiproduct, i.e. 𝐦∘𝐧 = (𝐦ᵀ𝔾𝐧)𝟙.",
  cayley = static(CAYLEYS_DOT.anti),
)

when IS_RIGID:
  defineOperator(
    symbols = "|∙²",
    docs = """Get bulk squared norm of multivector, i.e. ‖𝐦‖∙² = 𝐦∙𝐦.""",
    cayley = static(CAYLEYS_NORM_SQUARED.bulk.round),
    as_unary = true,
  )
  defineOperator(
    symbols = "|∘²",
    docs = """Get weight squared norm of multivector, i.e. ‖𝐦‖∘² = 𝐦∘𝐦.""",
    cayley = static(CAYLEYS_NORM_SQUARED.weight.round),
    as_unary = true,
  )
when IS_CONFORMAL:
  defineOperator(
    symbols = "|∙²",
    docs = """Get round bulk squared norm of multivector.""",
    cayley = static(CAYLEYS_NORM_SQUARED.bulk.round),
    as_unary = true,
  )
  defineOperator(
    symbols = "|∘²",
    docs = """Get round weight squared norm of multivector,
    as squared size of round weight components.""",
    cayley = static(CAYLEYS_NORM_SQUARED.weight.round),
    as_unary = true,
  )
  defineOperator(
    symbols = "|■²",
    docs = """Get flat bulk squared norm of multivector.""",
    cayley = static(CAYLEYS_NORM_SQUARED.bulk.flat),
    as_unary = true,
  )
  defineOperator(
    symbols = "|□²",
    docs = """Get flat weight squared norm of multivector.""",
    cayley = static(CAYLEYS_NORM_SQUARED.weight.flat),
    as_unary = true,
  )
  defineOperator(
    symbols = "|⊘²",
    docs = """Get squared radius norm of multivector, i.e. ‖𝐦‖⊘² = 𝐦∘𝐦.""",
    cayley = static(CAYLEYS_NORM_SQUARED_RADIUS),
    as_unary = true,
  )
defineOperator(
  symbols = "⊖",
  docs = "Get attitude of multivector, i.e. ⊖𝐦 = 𝐦 ∨ 𝐞̄ₙ.",
  cayley = static(CAYLEY_ATTITUDE),
)
when IS_CONFORMAL:
  defineOperator(
    symbols = "⊟",
    docs = "Get carrier of multivector, i.e. 𝐦 ∧ 𝐞ₙ.",
    cayley = static(CAYLEY_CARRIER),
  )


defineOperator(
  symbols = "⟑",
  docs = "Multiply multivectors through geometric product, i.e. 𝐦 ⟑ 𝐧.",
  cayley = static(CAYLEYS_WEDGE_DOT.base),
)
defineOperator(
  symbols = "⟇",
  docs = "Multiply multivectors through geometric antiproduct, i.e. 𝐦 ⟇ 𝐧.",
  cayley = static(CAYLEYS_WEDGE_DOT.anti),
)

defineOperator(
  symbols = "∧★",
  docs = "Multiply multivectors through right inner product bulk expansion, i.e. 𝐦 ∧ 𝐧★.",
  cayley = static(CAYLEYS_INTERIOR.base.bulk.right),
)

defineOperator(
  symbols = "∧☆",
  docs = "Multiply multivectors through right interior product expansion, i.e. 𝐦 ∧ 𝐧☆.",
  cayley = static(CAYLEYS_INTERIOR.base.weight.right),
)

defineOperator(
  symbols = "∨★",
  docs = "Multiply multivectors through right interior product contraction, i.e. 𝐦 ∨ 𝐧★.",
  cayley = static(CAYLEYS_INTERIOR.anti.bulk.right),
)

defineOperator(
  symbols = "∨☆",
  docs = "Multiply multivectors through right inner product weight contraction, i.e. 𝐦 ∨ 𝐧☆.",
  cayley = static(CAYLEYS_INTERIOR.anti.weight.right),
)



#[ Dynamic Operators ]#


#[ Wedge ]#

func `∧`*(s: Coefficient, m: Multivector): Multivector {.inline, noinit.} =
  ## Multiply scalar and multivector via exterior product, i.e. 𝐬 ∧ 𝐦.
  for b in Basis:
    result[b] = s * m[b]

template `∧`*(m: Multivector, s: Coefficient): Multivector =
  ## Multiply multivector and scalar via exterior product, i.e. 𝐦 ∧ 𝐬.
  s ∧ m

template `*`*(s: Coefficient, m: Multivector): Multivector =
  ## Multiply scalar and multivector via exterior product, i.e. 𝐬 ∧ 𝐦.
  s ∧ m

template `*`*(m: Multivector, s: Coefficient): Multivector =
  ## Multiply multivector and scalar via exterior product, i.e. 𝐦 ∧ 𝐬.
  s ∧ m



#[ Norms ]#

func `|∙`*(m: Multivector): MultivectorScalars {.inline.} =
  ## Get (round) bulk norm of multivector as size of (round) bulk components.
  ##   I.e. ‖𝐦‖∙ = √(𝐦∙𝐦).
  result = default(MultivectorScalars)
  result[Basis.scalar] = (`|∙²`m)[Basis.scalar].sqrt

func `|∘`*(m: Multivector): MultivectorScalars {.inline.} =
  ## Get (round) weight norm of multivector as size of (round) weight components.
  ##   I.e. ‖𝐦‖∘ = √(𝐦∘𝐦).
  result = default(MultivectorScalars)
  result[Basis.scalarAnti] = (`|∘²`m)[Basis.scalarAnti].sqrt

when IS_CONFORMAL:
  func `|■`*(m: Multivector): MultivectorScalars {.inline.} =
    ## Get flat bulk norm of multivector.
    result = default(MultivectorScalars)
    result[Basis.scalar] = (`|■²`m)[Basis.scalar].sqrt

  func `|□`*(m: Multivector): MultivectorScalars {.inline.} =
    ## Get flat weight norm of multivector.
    result = default(MultivectorScalars)
    result[Basis.scalarAnti] = (`|□²`m)[Basis.scalarAnti].sqrt

  func `|⊘`*(m: Multivector): MultivectorScalars {.inline.} =
    ## Get radius norm of multivector.
    ##   Taken from antidot to avoid square root of negative.
    result = default(MultivectorScalars)
    result[Basis.scalarAnti] = (`|⊘²`m)[Basis.scalarAnti].sqrt


func `|`*(m: Multivector): MultivectorScalars {.inline.} =
  ## Get geometric norm of multivector as distance from origin.
  ##   I.e. for all objects in RGA, ‖𝐦‖ = ‖𝐦‖∙ + ‖𝐦‖∘,
  ##     or for equivalent flat objects in CGA, ‖𝐦‖ = ‖𝐦‖■ + ‖𝐦‖□.
  result = default(MultivectorScalars)
  when IS_RIGID:
    result[Basis.scalar] = (|∙m)[Basis.scalar]
    result[Basis.scalarAnti] = (|∘m)[Basis.scalarAnti]
  else:
    # TODO: Does conformal even have base geometric norm?
    #   From reading it should be, for objects which are:
    #     Flat - Geonorm is ratio between flat bulk and weight norms.
    #       I.e. distance form flat object to origin.
    #     Round - Geonorm is ration between round bulk and weight norms.
    #       I.e. distance from object to carrier geometry.
    result[Basis.scalar] = (|■m)[Basis.scalar]
    result[Basis.scalarAnti] = (|□m)[Basis.scalarAnti]



#[ Unitize ]#

func `^∙`*(m: Multivector): Multivector {.inline, noinit.} =
  ## Normalize multivector so bulk norm has unit scalar magnitude (𝟏), i.e. 𝐦̂∙ = 𝐦 ÷ ‖𝐦‖∙.
  ##   Performs no-op where bulk norm is 0.
  ##   `float(...)` and `Coefficient(...)`: Nim 2 types `1.0 / x` as 64-bit, also where
  ##     `Coefficient` is 32-bit, and narrows product; Nimony types it as `x`, and narrows nothing.
  let
    m_norm_bulk = (`|∙²`m)[Basis.scalar].sqrt
    reciprocal = if m_norm_bulk != 0: 1.0 / float(m_norm_bulk) else: 1.0
  for b in Basis:
    result[b] = Coefficient(m[b] * reciprocal)

func `^∘`*(m: Multivector): Multivector {.inline, noinit.} =
  ## Normalize multivector so weight norm has unit antiscalar magnitude (𝟙).
  ##   I.e. 𝐦̂∘ = 𝐦 ÷ ‖𝐦‖∘.
  ##   Performs no-op where weight norm is 0.
  ##   `float(...)` and `Coefficient(...)`: as in `^∙`.
  let
    m_norm_weight = (`|∘²`m)[Basis.scalarAnti].sqrt
    reciprocal = if m_norm_weight != 0: 1.0 / float(m_norm_weight) else: 1.0
  for b in Basis:
    result[b] = Coefficient(m[b] * reciprocal)

template `^`*(m: Multivector): Multivector = ^∘m
  ## Normalize multivector so weight norm has unit antiscalar magnitude (𝟙).
  ##   I.e. 𝐦̂ = 𝐦 ÷ ‖𝐦‖∘.
  ##   Shorthand for weight normalization, i.e. unitization.



#[ Support ]#

when IS_RIGID:
  func `∩`*(m: Multivector): Multivector =
    ## Get right support of multivector, i.e. 𝐦∩ = 𝐦 ∨ (𝐞ₙ ∧ 𝐦☆).
    const 𝐞ₙ = initElement(Basis.origin)
    m ∨ (𝐞ₙ ∧ ☆m)

  func `∪`*(m: Multivector): Multivector =
    ## Get right antisupport of multivector, i.e. 𝐦∪ = 𝐦 ∧ (𝐞̄ₙ ∨ 𝐦★).
    const 𝐞̄ₙ = block:
      let h = Basis.horizon
      h.basis.initElement(Coefficient(if h.is_negated: -1 else: 1))
    m ∧ (𝐞̄ₙ ∨ ★m)

when IS_CONFORMAL:
  func `⊞`*(m: Multivector): Multivector =
    ## Get cocarrier of multivector, i.e. 𝐦☆ ∧ 𝐞ₙ.
    const 𝐞ₙ = Basis.infinity.initElement()
    ☆m ∧ 𝐞ₙ

  func `⊙`*(m: Multivector): Multivector = ⊞m ∨ m
    ## Get center of multivector, i.e. 𝐦⊞ ∨ 𝐦.

  func `⊡`*(m: Multivector): Multivector = m ∧ ☆(⊟m)
    ## Get container of multivector, i.e. 𝐦 ∧ (𝐦⊟)☆.

  func `⊛`*(m: Multivector): Multivector =
    ## Get partner of multivector, i.e. (-1)^(grade(𝐦)+1) (𝐦☆)⊡ ∨ 𝐦⊟.
    let sign = Coefficient(-1^(int(m.grade.get) + 1))
    sign * ⊡(☆m) ∨ ⊟m
```

## Replace `pga/emitters.nim` from `fc17dca16b76e851`

```nim
## Emit code of library's templates, as one Nimony plugin program.
##
## Nim 2 library emits code from macros, through helpers of this module. Nimony replaces macros
##   with plugins: programs of their own, which read and write NIF trees. So this module is
##   program for every template of library: `defineBasis` (`basis.nim`), `defineMultivectors` and
##   `defineBasisElementConstructors` (`multivectors.nim`), and `defineOperator` (`operators.nim`).
##   It runs emitter of template that call names.
##   Cost: change to program rebuilds it, each module that declares its templates, and each
##     importer of such module.
## Each template takes value that library constructs, through `static(...)`: names of bases for
##   `defineBasis`, and data structure over `Basis` for each other. So program reads plain literal
##   values: object as `(oconstr T (kv field value)*)`, array as `(aconstr T element*)`, set as
##   `(setconstr T element*)`, enum value as symbol, e.g. `E12`.
##   Program has no `Basis`, and asks compiler for order of its fields (`needTypes`): compiler
##     then runs program again for same call, with declaration of `Basis`.
##   `defineBasis` asks nothing.
## Program writes declarations as parser writes them (`nim-parsed` NIF), and compiler checks them
##   again in caller's scope. Docs of function travel as comment in its body, which compiler skips.
## Imports `plugins`, where Nim 2 library uses `std/macros`: plugin that imports Nim parser builds
##   it, with plugins it needs, before it runs.

import std/[options, unicode]

import plugins



#[ Plugin Input ]#

proc name(n: NifCursor): string =
  ## Read name of enum value or other symbol, without module suffix, e.g. `E12`.
  if n.kind == Ident: identText(n) else: symBasename(n.symId)


proc children(n: NifCursor, first = 0): seq[NifCursor] =
  ## Read children of tree from position `first`, e.g. elements of `(aconstr T element*)`.
  result = @[]
  var child = firstChild(n)
  var i = 0
  while child.hasMore:
    if i >= first: result.add child
    i += 1
    skip child


proc field(value: NifCursor, field_name: string): NifCursor =
  ## Read field of object value, i.e. `(oconstr T (kv field value)*)`, which names every field.
  result = default(NifCursor)
  for kv in children(value, first = 1):
    let pair = children(kv)
    if pair[0].name == field_name: return pair[1]


proc toInt(n: NifCursor): int = int(intValue(firstChild(n)))
  ## Read integer value, past its type suffix, i.e. `(suf 1 "i64")`.


proc toBool(n: NifCursor): bool = n.exprKind == TrueX
  ## Read boolean literal, i.e. `(true)` or `(false)`.


proc toStr(n: NifCursor): string =
  ## Read string literal, past suffix of raw or triple quoted string, e.g. `(suf "\\" "R")`.
  if n.kind == StrLit: stringValue(n) else: stringValue(firstChild(n))


proc fields(definitions: NifCursor, enum_type: SymId): Option[seq[string]] =
  ## Read names of enum fields in order, where compiler gave declaration (`needTypes`).
  ##   Declaration reads `(type :Name <export> <typevars> <pragmas> (enum <base> (efld ...)*))`.
  for declaration in children(definitions):
    let slots = children(declaration)
    if slots[0].symId != enum_type: continue
    var names: seq[string] = @[]
    for field in children(slots[4], first = 1): names.add firstChild(field).name
    return some(names)
  none[seq[string]]()


proc toBases(s: NifCursor, bases_all: seq[string]): seq[string] =
  ## Read `set[Basis]` as names of its bases in `Basis` order, expanding ranges `(range a b)`.
  var present = newSeq[bool](bases_all.len)
  for element in children(s, first = 1):
    let (first, last) =
      if element.otherKind == RangeU: (children(element)[0], children(element)[1])
      else: (element, element)
    for i in bases_all.find(first.name) .. bases_all.find(last.name): present[i] = true
  result = @[]
  for i, b in bases_all:
    if present[i]: result.add b


proc typeElement(s: NifCursor): SymId = firstChild(firstChild(s)).symId
  ## Read element type of set value, i.e. `Basis` of `(setconstr (set Basis) ...)`.


proc typeIndex(table: NifCursor): NifCursor =
  ## Read index type of array value, e.g. `Basis` of `(aconstr (array T (rangetype Basis a b)) x*)`,
  ##   or `(i 64)` where array has integer index.
  result = children(firstChild(table))[1]
  if result.kind == TagLit: result = firstChild(result)



#[ Cayley Tables ]#

type  ## Define types of `cayleys/types.nim` as program reads them, with `seq` for each array.
  BasisSigned = object  ## Define signed basis, by position of basis in `Basis`.
    basis: int
    is_negated: bool
  BasesSigned = seq[BasisSigned]  ## Define signed bases of Cayley table cell, as their sum.
  Cayley1D = seq[BasesSigned]  ## Define cell for each basis, in `Basis` order.
  Cayley2D = seq[Cayley1D]  ## Define row for each basis, in `Basis` order.


proc toBasesSigned(cell: NifCursor, bases_all: seq[string]): BasesSigned =
  ## Read cell, i.e. `(oconstr BasesSigned (kv elements (aconstr T term*)) (kv count n))`.
  result = @[]
  let
    count = toInt(cell.field("count"))
    terms = children(cell.field("elements"), first = 1)
  for i in 0..<count:
    result.add BasisSigned(
      basis: bases_all.find(terms[i].field("basis").name),
      is_negated: terms[i].field("is_negated").toBool,
    )


proc toCayley1D(table: NifCursor, bases_all: seq[string]): Cayley1D =
  ## Read 1D Cayley table, i.e. `array[Basis, BasesSigned]`.
  result = @[]
  for cell in children(table, first = 1): result.add toBasesSigned(cell, bases_all)


proc toCayley2D(table: NifCursor, bases_all: seq[string]): Cayley2D =
  ## Read 2D Cayley table, i.e. `array[Basis, array[Basis, BasesSigned]]`.
  result = @[]
  for row in children(table, first = 1): result.add toCayley1D(row, bases_all)



#[ Syntax Emitters ]#

proc emitExport(t: var NifBuilder, is_public: bool) =
  ## Emit export slot of declaration, where Nim 2 library wraps name in `postfix(name, "*")`.
  if is_public: t.addIdent "x" else: t.addEmptyNode


proc emitIdent(name: string): NifBuilder =
  ## Emit identifier, where Nim 2 library uses `ident(name)`.
  result = createTree()
  result.addIdent name


proc emitCall(callee: string, arguments: varargs[NifBuilder]): NifBuilder =
  ## Emit call, where Nim 2 library uses `newCall(ident(callee), arguments)`.
  result = createTree()
  result.withTree CallX, NoLineInfo:
    result.addIdent callee
    for argument in arguments: result.addTree argument


proc emitInfix(left: NifBuilder, operator: string, right: NifBuilder): NifBuilder =
  ## Emit infix operation, where Nim 2 library uses `infix(left, operator, right)`.
  result = createTree()
  result.withTree InfixX, NoLineInfo:
    result.addIdent operator
    result.addTree left
    result.addTree right


proc emitPrefix(term: NifBuilder, operator: string): NifBuilder =
  ## Emit prefix operation, where Nim 2 library uses `prefix(term, operator)`.
  result = createTree()
  result.withTree PrefixX, NoLineInfo:
    result.addIdent operator
    result.addTree term


proc emitFunc(
  name, docs: string; params, pragma, body: NifBuilder; is_quoted = false; is_public = false
): NifBuilder =
  ## Emit AST of function definition.
  ##   I.e. `(func name x . . (params ...) type (pragmas ...) . (stmts ...))`.
  result = createTree()
  result.withTree FuncS, NoLineInfo:
    if is_quoted:
      result.withTree QuotedX, NoLineInfo: result.addIdent name
    else:
      result.addIdent name
    result.emitExport is_public
    result.addEmptyNode  # Term rewriting pattern.
    result.addEmptyNode  # Generic parameters.
    result.addTree params  # Parameters, then result type.
    result.addTree pragma
    result.addEmptyNode  # Effects.
    result.withTree StmtsS, NoLineInfo:
      result.withTree CommentS, NoLineInfo: result.addStrLit docs
      result.addTree body


proc emitParams(result_type: string, names: seq[string], kind: NifBuilder): NifBuilder =
  ## Emit parameters of one type, each as `(param name . . type .)`, then result type, which
  ##   Nim 2 puts first in `nnkFormalParams`.
  result = createTree()
  result.withTree ParamsU, NoLineInfo:
    for name in names:
      result.withTree ParamU, NoLineInfo:
        result.addIdent name
        result.addEmptyNode  # Export.
        result.addEmptyNode  # Pragmas.
        result.addTree kind
        result.addEmptyNode  # Default.
  result.addIdent result_type


proc emitPragma(names: seq[string]): NifBuilder =
  ## Emit pragmas of declaration, or empty slot for none, where Nim 2 library uses `newEmptyNode()`.
  result = createTree()
  if names.len == 0:
    result.addEmptyNode
  else:
    result.withTree PragmasU, NoLineInfo:
      for name in names: result.addIdent name


proc emitTypeDef(
  name: string; pragma, body: NifBuilder; is_public = false
): NifBuilder =
  ## Emit AST of type definition.
  ##   I.e. `(type name x . (pragmas ...) body)`.
  result = createTree()
  result.withTree TypeS, NoLineInfo:
    result.addIdent name
    result.emitExport is_public
    result.addEmptyNode  # Generic parameters.
    result.addTree pragma
    result.addTree body


proc emitSubscript(operand: string, basis: string): NifBuilder =
  ## Emit AST of subscript operator for basis indexed object, e.g. `m[Basis.E1]`.
  result = createTree()
  result.withTree AtX, NoLineInfo:
    result.addIdent operand
    result.addIdent basis


proc emitTerm(
  left_name: string,
  left_basis: string,
  operator: string,
  right_name: string,
  right_basis: string,
  as_negated = false,
): NifBuilder =
  ## Emit AST of signed term for multivector basis assignment, e.g. `-(m[Basis.E1]*n[Basis.E2])`.
  let
    left = emitSubscript(left_name, left_basis)
    right = emitSubscript(right_name, right_basis)
    term = emitInfix(left, operator, right)
  if as_negated: emitPrefix(term, "-") else: term


proc emitMultivectorOf(bases: seq[string]): NifBuilder =
  ## Emit AST of `MultivectorOf` from presecibed set of bases.
  result = createTree()
  result.withTree AtX, NoLineInfo:
    result.addIdent "MultivectorOf"
    result.withTree CurlyX, NoLineInfo:
      for b in bases:
        result.withTree DotX, NoLineInfo:
          result.addIdent "Basis"
          result.addIdent b



#[ Basis Generation ]#

proc emitEnumBasis(names: seq[string]): NifBuilder =
  ## Emit enum to represent bases for `dimensions`-dimensional PGA.
  ##   I.e. `type Basis* {.pure.} = enum ...`.
  var fields = createTree()
  fields.withTree EnumT, NoLineInfo:
    fields.addEmptyNode  # Base type.
    for name in names:
      fields.withTree EfldU, NoLineInfo:
        fields.addIdent name
        fields.addEmptyNode4  # Export, pragmas, type, value.
  emitTypeDef("Basis", pragma = emitPragma(@["pure"]), body = fields, is_public = true)



#[ Multivector Generation ]#

proc emitMultivectors(kvectors: seq[seq[string]]; even, odd: seq[string]): NifBuilder =
  ## Emit specialized subtypes for n-dimensional PGA.
  result = createTree()  # NIF has no type section: each `type` declares one type.

  # Define kvectors.
  for grade, bases in kvectors:
    result.addTree emitTypeDef(
      name = "Multivector" & $grade,
      pragma = emitPragma(@[]),
      body = emitMultivectorOf(bases),
      is_public = true,
    )

  # Define parity vectors.
  let parities = [("MultivectorEven", even), ("MultivectorOdd", odd)]
  for (name, bases) in parities:
    result.addTree emitTypeDef(
      name,
      pragma = emitPragma(@[]),
      body = emitMultivectorOf(bases),
      is_public = true,
    )


proc emitBasisElementConstructors(bases: seq[string]): NifBuilder =
  ## Emit UFCS and literal constructors for each basis element.
  result = createTree()
  for b in bases:

    # Construct UFCS basis element constructor function.
    result.addTree emitFunc(
      name = toLower(b),
      docs = "Initialize multivector as singular " & b & " basis element via UFCS shorthand.",
      params = emitParams("Multivector", @["f"], emitIdent"Coefficient"),
      pragma = emitPragma(@[]),
      body = emitCall("initElement", emitIdent(b), emitIdent"f"),
      is_public = true,
    )

    # Construct literal basis element constructor function.
    var kind_literal = createTree()
    kind_literal.withTree AtX, NoLineInfo:  # `static[string]`
      kind_literal.addIdent "static"
      kind_literal.addIdent "string"
    result.addTree emitFunc(
      name = toLower(b),
      docs = "Initialize multivector as singular " & b & " basis element via literal shorthand.",
      params = emitParams("Multivector", @["s"], kind_literal),
      pragma = emitPragma(@[]),
      body = emitCall("initElement", emitIdent(b), emitCall("parseFloat", emitIdent"s")),
      is_public = true,
    )



#[ Operator Generation ]#

proc emitAssignments(expressions: seq[seq[NifBuilder]], bases_all: seq[string]): NifBuilder =
  ## Emit collated assignments for each basis element, e.g. `result[E1] = t₀ + t₁`, or `0.0`.
  result = createTree()
  result.withTree StmtsS, NoLineInfo:
    for b, terms in expressions:
      # Sum terms from left, or assign zero.
      var expression = createTree()
      if terms.len == 0:
        expression.addFloatLit 0.0
      else:
        expression.addTree terms[0]
      for i in 1..<terms.len:  # Index, not slice: builder is not copied.
        expression = emitInfix(expression, "+", terms[i])

      result.withTree AsgnS, NoLineInfo:
        result.addTree emitSubscript("result", bases_all[b])
        result.addTree expression


proc emitOperator(symbols, docs: string; cayley: Cayley1D; bases_all: seq[string]): NifBuilder =
  ## Emit multivector mapping variant using provided Cayley table.

  # Determine mappings needed for each basis element's coefficient assignment.
  var expressions = newSeq[seq[NifBuilder]](bases_all.len)
  for b, cell in cayley:
    for destination in cell:
      let source = emitSubscript("m", bases_all[b])
      expressions[destination.basis].add(
        if destination.is_negated: emitPrefix(source, "-") else: source
      )

  # Construct function definition from generated assignments.
  emitFunc(
    name = symbols,
    docs = docs,
    params = emitParams("Multivector", @["m"], emitIdent"Multivector"),
    pragma = emitPragma(@["inline", "noinit"]),
    body = emitAssignments(expressions, bases_all),
    is_quoted = true,
    is_public = true,
  )


proc emitOperator(
  symbols, docs: string; cayley: Cayley2D; bases_all: seq[string]; as_unary = false
): NifBuilder =
  ## Emit multivector product variant using provided Cayley table.

  # Determine calculations needed for each basis element's coefficient assignment.
  var expressions = newSeq[seq[NifBuilder]](bases_all.len)
  for m, row in cayley:
    for n, cell in row:
      for destination in cell:
        expressions[destination.basis].add emitTerm(
          "m", bases_all[m], "*", (if not as_unary: "n" else: "m"), bases_all[n],
          as_negated = destination.is_negated,
        )

  # Construct function definition from generated assignments.
  let names = if not as_unary: @["m", "n"] else: @["m"]
  emitFunc(
    name = symbols,
    docs = docs,
    params = emitParams("Multivector", names, emitIdent"Multivector"),
    pragma = emitPragma(@["inline", "noinit"]),
    body = emitAssignments(expressions, bases_all),
    is_quoted = true,
    is_public = true,
  )



#[ Program ]#

proc emitStatements(code: NifBuilder): NifBuilder =
  ## Emit code as statement list, which is one tree for several declarations. Also for enum:
  ##   after lone `(type ...)`, importer finds no `$` for it.
  result = createTree()
  result.withTree StmtsS, NoLineInfo: result.addTree code


proc emit(call, definitions: NifCursor): NifBuilder =
  ## Emit code for call of template, or ask compiler for `Basis` fields, which emitters need.
  let
    callee = pluginName(call)
    arguments = children(call, first = 1)
  for argument in arguments:
    if argument.kind == Symbol:  # Compiler takes name of constant for `static[T]`, unevaluated.
      return errorTree(
        "argument must be `static(...)` value, not name of constant; got `" & argument.name & "`",
        argument,
      )
  if callee == "defineBasis":
    var names: seq[string] = @[]
    for element in children(arguments[0], first = 1): names.add toStr(element)
    return emitStatements(emitEnumBasis(names))

  # Read names of `Basis` fields, from type of argument that holds bases.
  var basis_type: SymId
  if callee == "defineMultivectors":
    basis_type = typeElement(arguments[1])
  elif callee == "defineBasisElementConstructors":
    basis_type = typeElement(arguments[0])
  elif callee == "defineOperator":
    let index_type = typeIndex(arguments[2])
    if index_type.kind != Symbol:  # Nimony, as Nim 2, matches same-shaped array of `int` index.
      return errorTree("`cayley` must be indexed by `Basis`, not by integer", call)
    basis_type = index_type.symId
  else:
    return errorTree("plugin `emitters` emits no template `" & callee & "`", call)
  let found = fields(definitions, basis_type)
  if found.isNone: return needTypes(basis_type)
  let bases_all = found.get

  if callee == "defineMultivectors":
    var kvectors: seq[seq[string]] = @[]
    for bases in children(arguments[0], first = 1): kvectors.add toBases(bases, bases_all)
    let (even, odd) = (toBases(arguments[1], bases_all), toBases(arguments[2], bases_all))
    return emitStatements(emitMultivectors(kvectors, even, odd))
  if callee == "defineBasisElementConstructors":
    return emitStatements(emitBasisElementConstructors(toBases(arguments[0], bases_all)))
  let (symbols, docs) = (toStr(arguments[0]), toStr(arguments[1]))
  if arguments.len == 3:
    let cayley = toCayley1D(arguments[2], bases_all)
    return emitStatements(emitOperator(symbols, docs, cayley, bases_all))
  emitStatements(emitOperator(
    symbols, docs, toCayley2D(arguments[2], bases_all), bases_all, as_unary = toBool(arguments[3])
  ))


proc main() =
  ## Read call of template, and write its code in place of call.
  let
    call = loadPluginInput()  # `(stmts name argument*)`
    definitions = loadTypeDefinitions()  # Declarations that plugin asked for with `needTypes`.
  saveTree emit(call, definitions)


main()
```

## Replace `tests/suites.nim` from `a4a5af0a9f812900`

```nim
## TODO: Document.
# TODO: Check which tests should be modified for CGA (after full CGA support).

import std/[assertions, math, options, random]

import ../pga
import ../pga/[algebra, basis, multivectors, operators]
import ./unittest

randomize(0)


proc gauss(mu = 0.0, sigma = 1.0): float =
  ## Sample normal distribution through ratio of uniforms, as `gauss` of Nim 2's `std/random`.
  ##   Nimony's `std/random` has no `gauss`. Its generator and seeding are those of Nim 2's,
  ##     so samples agree with Nim 2's up to rounding.
  let k = sqrt(2.0 / E)
  var
    a = 0.0
    b = 0.0
  while true:
    a = rand(1.0)
    b = (2.0 * rand(1.0) - 1.0) * k
    if b * b <= -4.0 * a * a * ln(a): break
  mu + sigma * (b / a)


const SAMPLES = 512

let ELEMENTS = block:  # `let`: each `const` costs Nimony one compiled program.
  var elements {.noinit.}: array[Basis, Multivector]
  for b in Basis: elements[b] = b.initElement(1)
  elements

let
  𝟏 = ELEMENTS[Basis.scalar]
  𝐞ₙ₋₁ = ELEMENTS[Basis.vectorLast.pred]
  𝐞ₙ = ELEMENTS[Basis.vectorLast]
  𝟙 = ELEMENTS[Basis.scalarAnti]


proc sampleMultivector*(grades = default(seq[Grade]), mu = 0.0, sigma = 1.0): Multivector =
  result = default(Multivector)
  for b in Basis:
    if len(grades) == 0 or b.grade in grades:
      result[b] = Coefficient(gauss(mu, sigma))  # Nimony narrows `float` only on request.

var MULTIVECTORS: array[SAMPLES, Multivector]
for i in 1..ELEMENTS.len: MULTIVECTORS[i] = ELEMENTS[Basis(i-1)]
  # First element intentionally 0.
for i in len(ELEMENTS) + 1 ..< SAMPLES:
  # TODO: Sample likely troublesome values with small probability.
  #   E.g. 0, NaNs, (-)inf, basis elements.

  # Sample kvectors with small probability, otherwise mixed grade.
  #   E.g. vectors (points), bivectors (lines), trivectors (planes), etc.
  let grades = if rand(1'f) > 0.1: @[Grade(rand(DIMENSIONS - 1))] else: @[]
  MULTIVECTORS[i] = sampleMultivector(grades)


iterator enumerateBasis(): (Basis, lent Multivector) =
  for b in Basis: yield (b, ELEMENTS[b])


iterator enumerateBasisPair(): (Basis, Basis, lent Multivector, lent Multivector) =
  for b in Basis:
    for c in Basis:
      yield (b, c, ELEMENTS[b], ELEMENTS[c])


iterator sampleMultivectors(
  count: int = SAMPLES,
): (lent Multivector, lent Multivector, lent Multivector) {.sideEffect.} =  # Draws random.
  const i_max = len(MULTIVECTORS) - 1
  var c = count
  while c > 0:
    yield (MULTIVECTORS[rand(i_max)], MULTIVECTORS[rand(i_max)], MULTIVECTORS[rand(i_max)])
    dec c


# TODO: Add sqrt, abs, div, exp, etc. to library when homogeneous scalars are in.
func sqrt(m: Multivector): MultivectorScalars =
  ## Find square root of dual number, i.e. √𝐦.
  result = default(MultivectorScalars)
  let (s, t) = (m[Basis.scalar], m[Basis.scalarAnti])
  if s != 0:
    result[Basis.scalar] = s.sqrt
    result[Basis.scalarAnti] = t / (2 * s.sqrt)

func sqrtAnti(m: Multivector): MultivectorScalars =
  ## Find square root of dual number, i.e. √𝐦.
  result = default(MultivectorScalars)
  let (s, t) = (m[Basis.scalar], m[Basis.scalarAnti])
  if t != 0:
    result[Basis.scalar] = s / (2 * t.sqrt)
    result[Basis.scalarAnti] = t.sqrt



func abs(m: Multivector): Multivector =
  ## Find absolute value of multivector elementwise, i.e. |𝐦|.
  result = default(Multivector)
  for b in Basis: result[b] = m[b].abs


func `div`*(m: Multivector, norm: Coefficient): Multivector =
  ## Divide multivector by scalar norm magnitude.
  ##   No-op if `norm` magnitude is 0.
  result = m
  if norm != 0:
    for b in Basis:
      result[b] /= norm


func `div`*(m: Multivector, norm: MultivectorScalars): Multivector =
  ## Divide multivector by bulk xor weight norm magnitude.
  ##   I.e. 𝐦 / `norm` = 𝐦 / (‖𝐧‖𝟏 + ‖𝐧‖𝟙).
  ##   `norm` should have singular non-zero value at either 𝟏 or 𝟙.
  ##   No-op if `norm`'s magnitude is 0.
  assert norm[Basis.scalar] == 0 or norm[Basis.scalarAnti] == 0,
    "`norm=" & $norm.toMultivector & "` must be a bulk xor weight norm, not geometric norm."
  m div (norm[Basis.scalar] + norm[Basis.scalarAnti])



suite "Internal":
  test "`$`(b: BasisDigits): string":
    let  # Run time: routines of library are no compile-time-only routines.
      a = $BasisDigits("")
      b = $BasisDigits("1")
      c = $BasisDigits("412")
    check a == ""
    check b == "1"
    check c == "412"


  test "`$`(m: Multivector): string":
    let 𝐞₁ = Basis.scalar.succ.initElement
    check $𝟏 == "𝟏"
    check $𝐞₁ == "𝐞₁"
    check $(𝟏 + 𝐞₁) == "𝟏 + 𝐞₁"


  test "toBasisName(b: BasisDigits): string":
    let
      a = BasisDigits("").toBasisName
      b = BasisDigits("1").toBasisName
      c = BasisDigits("412").toBasisName
    check a == "S"
    check b == "E1"
    check c == "E412"



suite "Chapter 2":
  test "Equation 2.1":
    for b, 𝐮 in enumerateBasis():
      if b.grade == Grade(1):
        check 𝐮 ∧ 𝐮 =~ 0


  test "Equation 2.2-4":
    for b, c, 𝐮, 𝐯 in enumerateBasisPair():
      if b.grade == Grade(1) and c.grade == Grade(1):
        check (𝐮 + 𝐯) ∧ (𝐮 + 𝐯) =~ 0  # 2.2a
        check (𝐮 ∧ 𝐮) + (𝐮 ∧ 𝐯) + (𝐯 ∧ 𝐮) + (𝐯 ∧ 𝐯) =~ 0  # 2.2b
        check (𝐮 ∧ 𝐯) + (𝐯 ∧ 𝐮) =~ 0  # 2.3
        check 𝐮 ∧ 𝐯 =~ -(𝐯 ∧ 𝐮)  # 2.4


  test "Equation X.X":
    for b, 𝐮 in enumerateBasis():
      if b == Basis.scalar:
        check 𝐮 ∧ 𝐮 =~ 𝟏
      elif b == Basis.scalarAnti:
        check 𝐮 ∨ 𝐮 =~ 𝟙
      else:
        check 𝐮 ∧ 𝐮 =~ 0
        check 𝐮 ∨ 𝐮 =~ 0


  test "Equation 2.13":
    var 𝐦 = ELEMENTS[Basis.scalar.succ]  # 1'e1
    for b in Basis:
      if b.grade == Grade(1) and b != Basis.scalar.succ:
        𝐦 = 𝐦 ∧ ELEMENTS[b]  # 1'e1 ∧ 1'e2 ∧ ... ∧ 1'en

    # Handle special case due to Lengyel's choice of basis order.
    let antiscalar = if DIMENSIONS != 3: 𝟙 else: -𝟙

    check 𝐦 =~ antiscalar


  test "Equation 2.16":
    for b, _ in enumerateBasis():
      check int(b.grade) + int(b.gradeAnti) == DIMENSIONS
      check b.grade >= Grade.low and b.grade <= Grade.high
      check b.gradeAnti >= GradeAnti.low and b.gradeAnti <= GradeAnti.high


  test "Equation 2.17":
    for b, c, 𝐮, 𝐯 in enumerateBasisPair():
      let grade_expect = b.grade + c.grade
      if int(grade_expect) in 0..DIMENSIONS:
        check (𝐮 ∧ 𝐯){grade_expect} =~ 𝐮 ∧ 𝐯
      else:
        check 𝐮 ∧ 𝐯 =~ 0


  test "Equation 2.18":
    for b, c, 𝐮, 𝐯 in enumerateBasisPair():
      let sign = Coefficient(-1^(int(b.grade) * int(c.grade)))
      check 𝐮 ∧ 𝐯 =~ sign ∧ (𝐯 ∧ 𝐮)


  test "Equation 2.19-20":
    for _, 𝐮 in enumerateBasis():
      check 𝐮 ∧ /𝐮 =~ 𝟙  # 2.19
      check \𝐮 ∧ 𝐮 =~ 𝟙  # 2.20


  test "Equation 2.21":
    for b, 𝐮 in enumerateBasis():
      var 𝐮̅ = /𝐮
      for c in Basis:
        𝐮̅[c] = Coefficient(-1^(int(b.grade) * int(b.gradeAnti))) * 𝐮̅[c]
      check \𝐮 =~ 𝐮̅


  test "Equation 2.22-23":
    for b, 𝐮 in enumerateBasis():
      check \(/𝐮) =~ 𝐮  # 2.22a
      check /(\𝐮) =~ 𝐮  # 2.22b
      check /(/𝐮) =~ \(\𝐮)  # 2.23a
      check /(/𝐮) =~ Coefficient(-1^(int(b.grade) * int(b.gradeAnti))) ∧ 𝐮  # 2.23b


  test "Equation 2.24":
    let 𝑠 = 123'f
    for 𝐦, 𝐧, _ in sampleMultivectors():
      check /(𝑠 ∧ 𝐦) =~ 𝑠 ∧ /𝐦  # 2.24a
      check /(𝐦 + 𝐧) =~ /𝐦 + /𝐧  # 2.24b


  test "Equation 2.25-27":
    for _, _, 𝐮, 𝐯 in enumerateBasisPair():
      check 𝐮 ∨ 𝐯 =~ \(/𝐮 ∧ /𝐯)  # 2.25
      check /(𝐮 ∨ 𝐯) =~ /𝐮 ∧ /𝐯  # 2.26a
      check \(𝐮 ∨ 𝐯) =~ \𝐮 ∧ \𝐯  # 2.26b
      check /(𝐮 ∧ 𝐯) =~ /𝐮 ∨ /𝐯  # 2.27a
      check \(𝐮 ∧ 𝐯) =~ \𝐮 ∨ \𝐯  # 2.27b


  test "Equation 2.28":
    var 𝐦 = /ELEMENTS[Basis.scalar.succ]  # 1'e1
    for b in Basis:
      if b.grade == Grade(1) and b != Basis.scalar.succ:
        𝐦 = 𝐦 ∨ /ELEMENTS[b]  # 1'e1 ∨ 1'e2 ∨ ... ∨ 1'en

    # Handle special case due to Lengyel's choice of basis order.
    let scalar = if DIMENSIONS != 3: 𝟏 else: -𝟏

    check 𝐦 =~ scalar


  test "Equation 2.29-30":
    for b, c, 𝐮, 𝐯 in enumerateBasisPair():
      if 𝐮.isMixed or 𝐯.isMixed: continue
      let u_vee_v = 𝐮 ∨ 𝐯
      if u_vee_v =~ 0: continue
      check u_vee_v.gradeAnti.get == 𝐮.gradeAnti.get + 𝐯.gradeAnti.get  # 2.29
      check u_vee_v.grade.get == 𝐮.grade.get + 𝐯.grade.get - Grade.high  # 2.30


  test "Equation 2.31":
    for b, c, 𝐮, 𝐯 in enumerateBasisPair():
      if b.gradeAnti == GradeAnti(1) and c.gradeAnti == GradeAnti(1):
        check 𝐮 ∨ 𝐯 =~ -(𝐯 ∨ 𝐮)


  test "Equation 2.32":
    for b, c, 𝐮, 𝐯 in enumerateBasisPair():
      let sign = Coefficient(-1^(int(b.gradeAnti) * int(c.gradeAnti)))
      check 𝐮 ∨ 𝐯 =~ sign ∧ (𝐯 ∨ 𝐮)


  test "Equation 2.68-70":
    for 𝐦, 𝐧, _ in sampleMultivectors():
      when IS_RIGID:
        check (∙𝐦 + ∘𝐦) ∧ (∙𝐧 + ∘𝐧) =~ 𝐦 ∧ 𝐧  # 2.68
        check (∙𝐦 ∧ ∙𝐧) + (∙𝐦 ∧ ∘𝐧) + (∘𝐦 ∧ ∙𝐧) =~ (𝐦 ∧ 𝐧)  # 2.69
        check ∙𝐦 ∧ ∙𝐧 =~ ∙(𝐦 ∧ 𝐧)  # 2.70a
        check (∙𝐦 ∧ ∘𝐧) + (∘𝐦 ∧ ∙𝐧) =~ ∘(𝐦 ∧ 𝐧)  # 2.70b

      when IS_CONFORMAL:
        check (∙𝐦 + ∘𝐦 + ■𝐦 + □𝐦) ∧ (∙𝐧 + ∘𝐧 + ■𝐧 + □𝐧) =~ 𝐦 ∧ 𝐧  # 2.68
        check 𝐦 ∧ 𝐧 =~ (
          (∙𝐦 ∧ ∙𝐧) + (∙𝐦 ∧ ∘𝐧) + (∙𝐦 ∧ ■𝐧) + (∙𝐦 ∧ □𝐧) + (∘𝐦 ∧ ∙𝐧) +
          (∘𝐦 ∧ ∘𝐧) + (∘𝐦 ∧ ■𝐧) + (∘𝐦 ∧ □𝐧) + (■𝐦 ∧ ∙𝐧) + (■𝐦 ∧ ∘𝐧) +
          (■𝐦 ∧ ■𝐧) + (■𝐦 ∧ □𝐧) + (□𝐦 ∧ ∙𝐧) + (□𝐦 ∧ ∘𝐧) + (□𝐦 ∧ ■𝐧) +
          (□𝐦 ∧ □𝐧)
        )  # 2.69
        check ∙𝐦 ∧ ∙𝐧 =~ ∙(𝐦 ∧ 𝐧)  # 2.70a
        # TODO: Find out how other parts should distribute (2.70b/c/d).


  test "Equation 2.71-72":
    for 𝐦, 𝐧, _ in sampleMultivectors():
      when IS_RIGID:
        check (∙𝐦 + ∘𝐦) ∨ (∙𝐧 + ∘𝐧) =~ 𝐦 ∨ 𝐧  # 2.71a
        check (∙𝐦 ∨ ∘𝐧) + (∘𝐦 ∨ ∙𝐧) + (∘𝐦 ∨ ∘𝐧) =~ 𝐦 ∨ 𝐧  # 2.71b
        check (∙𝐦 ∨ ∘𝐧) + (∘𝐦 ∨ ∙𝐧) =~ ∙(𝐦 ∨ 𝐧)  # 2.72a
        check ∘𝐦 ∨ ∘𝐧 =~ ∘(𝐦 ∨ 𝐧)  # 2.72b

      when IS_CONFORMAL:
        check (∙𝐦 + ∘𝐦 + ■𝐦 + □𝐦) ∨ (∙𝐧 + ∘𝐧 + ■𝐧 + □𝐧) =~ 𝐦 ∨ 𝐧  # 2.71a
        check 𝐦 ∨ 𝐧 =~ (
          (∙𝐦 ∨ ∙𝐧) + (∙𝐦 ∨ ∘𝐧) + (∙𝐦 ∨ ■𝐧) + (∙𝐦 ∨ □𝐧) + (∘𝐦 ∨ ∙𝐧) +
          (∘𝐦 ∨ ∘𝐧) + (∘𝐦 ∨ ■𝐧) + (∘𝐦 ∨ □𝐧) + (■𝐦 ∨ ∙𝐧) + (■𝐦 ∨ ∘𝐧) +
          (■𝐦 ∨ ■𝐧) + (■𝐦 ∨ □𝐧) + (□𝐦 ∨ ∙𝐧) + (□𝐦 ∨ ∘𝐧) + (□𝐦 ∨ ■𝐧) +
          (□𝐦 ∨ □𝐧)
        )  # 2.69
        check □𝐦 ∨ □𝐧 =~ □(𝐦 ∨ 𝐧)  # 2.70a
      # TODO: Find out how other parts should distribute (2.70a/b/c/d).


  test "Equation 2.73":
    let horizon = if IS_RIGID: 𝐞ₙ else: 𝐞ₙ₋₁
    for 𝐦, _, _ in sampleMultivectors():
      check ⊖𝐦 =~ 𝐦 ∨ /horizon


  test "Equation 2.76":
    for 𝐦, 𝐧, _ in sampleMultivectors():
      check 𝐦 ∘ 𝐧 =~ /(\𝐦 ∙ \𝐧)


  test "Equation 2.87-89":
    when IS_RIGID:
      for 𝐦, _, _ in sampleMultivectors():
        #echo &"{|∙𝐦=}, {sqrt(𝐦 ∙ 𝐦)=}"
        check |∙𝐦 =~ sqrt(𝐦 ∙ 𝐦)  # 2.87
        check |∘𝐦 =~ sqrtAnti(𝐦 ∘ 𝐦)  # 2.88
        check ^𝐦 =~ 𝐦 div |∘𝐦  # 2.89a
        check ^𝐦 =~ 𝐦 div sqrtAnti(𝐦 ∘ 𝐦)  # 2.89b

    when IS_CONFORMAL: skip()


  test "Equation 2.90-94":
    when IS_RIGID:
      for 𝐦, _, _ in sampleMultivectors():
        let
          𝐬 = (|𝐦)[Basis.scalar]
          𝑡 = (|𝐦)[Basis.scalarAnti]
        check |𝐦 =~ |∙𝐦 + |∘𝐦  # 2.90a
        #echo &"{𝐦=}\n{|𝐦=}, {sqrt(𝐦 ∙ 𝐦)=}, {sqrtAnti(𝐦 ∘ 𝐦)=}, {sqrt(𝐦 ∙ 𝐦) + sqrtAnti(𝐦 ∘ 𝐦)}"
        check |𝐦 =~ sqrt(𝐦 ∙ 𝐦) + sqrtAnti(𝐦 ∘ 𝐦)  # 2.90b
        if 𝑡 != 0:
          check ^((|𝐦).toMultivector) =~ initElement(Basis.scalar, 𝐬 / 𝑡) + 𝟙  # 2.94

    when IS_CONFORMAL: skip()


  test "Equation 2.97-98":
    when IS_RIGID:
      for 𝐦, 𝐧, _ in sampleMultivectors():
        let
          distance_a = toMultivector(|∙(⊖(𝐦 ∧ 𝐧))) div |∙(⊖𝐦 ∧ ⊖𝐧)
          distance_b = |∙(⊖(𝐦 ∧ 𝐧)) + |∘(𝐦 ∧ ⊖𝐧)
          distance_b_unitized = (^(distance_b.toMultivector)){Grade.scalar}
        check distance_a =~ distance_b_unitized

    when IS_CONFORMAL: skip()


  test "Equation 2.99":
    when IS_RIGID:
      for 𝐦, 𝐧, _ in sampleMultivectors():
        if 𝐦.grade.isNone or 𝐧.grade.isNone: continue
        if 𝐦.grade.get + 𝐧.grade.get != Grade.high: continue
        let
          distance_a = (𝐦 ∨ 𝐧) + toMultivector(|∘(𝐦 ∧ ⊖𝐧))
          distance_b = |∙(⊖(𝐦 ∧ 𝐧)) + |∘(𝐦 ∧ ⊖𝐧)
        check abs(^distance_a) =~ ^toMultivector(distance_b)

    when IS_CONFORMAL: skip()


  test "Equation 2.103":
    when IS_RIGID:
      for 𝐦, _, _ in sampleMultivectors():
        check ★𝐦 =~ /(∙𝐦)  # 2.103a
        check ☆𝐦 =~ /(∘𝐦)  # 2.103b

    when IS_CONFORMAL: skip()


  test "Equation 2.107-109":
    for 𝐦, 𝐧, _ in sampleMultivectors():
      check ★(𝐦 ∧ 𝐧) =~ ★𝐦 ∨ ★𝐧  # 2.107
      check ☆(𝐦 ∨ 𝐧) =~ ☆𝐦 ∧ ☆𝐧  # 2.109


  test "Equation 2.119-120":
    for 𝐦, 𝐧, _ in sampleMultivectors():
      if 𝐦.grade.isNone or 𝐧.grade.isNone: continue
      let (𝐦_grade, 𝐧_grade) = (𝐦.grade.get, 𝐧.grade.get)
      if 𝐦_grade != 𝐧_grade: continue
      check 𝐦 ∨ ★𝐧 =~ 𝐦 ∙ 𝐧  # 2.119
      check 𝐦 ∨ ☆𝐧 =~ (𝐦 ∘ 𝐧) ∨ 𝟏  # 2.120


  test "Equation 2.121":
    for 𝐦, 𝐧, 𝐨 in sampleMultivectors():
      check 𝐦 ∨ ★(𝐧 ∧ 𝐨) =~ 𝐦 ∨ ★𝐧 ∨ ★𝐨


  test "Equation 2.122":
    for 𝐦, 𝐧, 𝐨 in sampleMultivectors():
      if 𝐦.grade.isNone or 𝐧.grade.isNone or 𝐨.grade.isNone: continue
      let (𝐦_grade, 𝐧_grade, 𝐨_grade) = (𝐦.grade.get, 𝐧.grade.get, 𝐨.grade.get)
      if 𝐦_grade - 𝐧_grade != 𝐨_grade: continue
      check (𝐦 ∨★ 𝐧) ∙ 𝐨 =~ 𝐦 ∨ ★𝐧 ∨ ★𝐨  # 2.122a
      check (𝐦 ∨★ 𝐧) ∙ 𝐨 =~ 𝐦 ∨ ★(𝐧 ∧ 𝐨)  # 2.122b


  test "Equation 2.123":
    for 𝐦, 𝐧, 𝐨 in sampleMultivectors():
      if 𝐦.grade.isNone or 𝐧.grade.isNone or 𝐨.grade.isNone: continue
      let (𝐦_grade, 𝐧_grade, 𝐨_grade) = (𝐦.grade.get, 𝐧.grade.get, 𝐨.grade.get)
      if 𝐦_grade != 𝐧_grade + 𝐨_grade: continue
      check (𝐦 ∨★ 𝐧) ∙ 𝐨 =~ 𝐦 ∙ (𝐧 ∧ 𝐨)

  test "TODO: Add remaining chapter 2 tests":
    skip()



suite "Chapter 3":
  test "TODO: Add remaining chapter 3 tests":
    skip()



suite "Chapter 4":
  test "Equation 4.45":
    skip()
    # when IS_RIGID: skip()
    # when IS_CONFORMAL:
    #   for 𝐦, 𝐧, 𝐨 in sampleMultivectors():
    #     echo &"{𝐦=}, {|⊘𝐦=}, {sqrt(𝐦 ∘ 𝐦)=}"
    #     check |⊘𝐦 =~ sqrt(𝐦 ∘ 𝐦)


  test "TODO: Add remaining chapter 4 tests":
    skip()



suite "Chapter 5":
  test "TODO: Add remaining chapter 5 tests":
    skip()


exitOnFailure()  # Last code of each test program: Nimony has no exit hook.
```

## Add `tests/unittest.nim`

```nim
## Provide minimal `std/unittest` for test suites, since Nimony ships none.
##   Same status lines as Nim 2's module, i.e. `[Suite]`, `[OK]`, `[FAILED]` and `[SKIPPED]`,
##     so counts compare line for line with Nim 2 run.
##   Exits with 1 at first failed check under `-d:nimUnittestAbortOnError:on`, as Nim 2's module
##     does, and as test command of Nim 2 library asks. Without it, `exitOnFailure` exits with 1
##     after last suite, as Nim 2's module does when program ends, since Nimony has no exit hook.

import std/syncio

type TestStatus* = enum OK, FAILED, SKIPPED

const nimUnittestAbortOnError {.booldefine.} = false  ## Quit at first failed check.

var
  testStatus: TestStatus = OK  ## Status of test that runs now.
  testsFailed: int = 0  ## Count of failed tests so far.


template suite*(name: string, body: untyped) =
  ## Group tests under name.
  echo "\n[Suite] ", name
  body


template test*(name: string, body: untyped) =
  ## Run test body, then print its status.
  testStatus = OK
  block:
    body
  echo "  [", $testStatus, "] ", name
  if testStatus == FAILED: inc testsFailed


template check*(condition: untyped) =
  ## Fail test where condition is false.
  if not condition:
    testStatus = FAILED
    echo "    Check failed: ", astToStr(condition)
    when nimUnittestAbortOnError: quit 1


template skip*() =
  ## Mark test as skipped.
  testStatus = SKIPPED


template exitOnFailure*() =
  ## Exit with 1 where any test failed.
  if testsFailed > 0: quit 1
```

## Replace `tests/rga2d/test_rga2d.nim` from `d547dc49be5603d4`

```nim
discard """
action: run
cmd: "nim c --hints:on -d:testing -d:nimUnittestAbortOnError:on $options $file"
matrix: "-d:pga.dimensions=2 -d:pga.is_conformal=false"
"""

include "../suites.nim"
```

## Replace `tests/rga3d/test_rga3d.nim` from `493f8f0f7c7f462a`

```nim
discard """
action: run
cmd: "nim c --hints:on -d:testing -d:nimUnittestAbortOnError:on $options $file"
matrix: "-d:pga.dimensions=3 -d:pga.is_conformal=false"
"""

include "../suites.nim"
```

## Replace `tests/rga4d/test_rga4d.nim` from `903451850440e421`

```nim
discard """
action: run
cmd: "nim c --hints:on -d:testing -d:nimUnittestAbortOnError:on $options $file"
matrix: "-d:pga.dimensions=4 -d:pga.is_conformal=false"
"""

include "../suites.nim"
```

## Replace `tests/rga5d/test_rga5d.nim` from `c2b95eeded73cd30`

```nim
discard """
action: run
cmd: "nim c --hints:on -d:testing -d:nimUnittestAbortOnError:on $options $file"
matrix: "-d:pga.dimensions=5 -d:pga.is_conformal=false"
"""

include "../suites.nim"
```

## Replace `tests/rga6d/test_rga6d.nim` from `ad23bbc328373b81`

```nim
discard """
action: run
cmd: "nim c --hints:on -d:testing -d:nimUnittestAbortOnError:on $options $file"
matrix: "-d:pga.dimensions=6 -d:pga.is_conformal=false"
"""

include "../suites.nim"
```

## Replace `tests/cga3d/test_cga3d.nim` from `2837e5f73f5af7a8`

```nim
discard """
action: run
cmd: "nim c --hints:on -d:testing -d:nimUnittestAbortOnError:on $options $file"
matrix: "-d:pga.dimensions=3 -d:pga.is_conformal=true"
"""

include "../suites.nim"
```

## Replace `tests/cga4d/test_cga4d.nim` from `d0ec63c9e65d4a11`

```nim
discard """
action: run
cmd: "nim c --hints:on -d:testing -d:nimUnittestAbortOnError:on $options $file"
matrix: "-d:pga.dimensions=4 -d:pga.is_conformal=true"
"""

include "../suites.nim"
```

## Replace `tests/cga5d/test_cga5d.nim` from `6ab24b81aa365f06`

```nim
discard """
action: run
cmd: "nim c --hints:on -d:testing -d:nimUnittestAbortOnError:on $options $file"
matrix: "-d:pga.dimensions=5 -d:pga.is_conformal=true"
"""

include "../suites.nim"
```

## Replace `tests/cga6d/test_cga6d.nim` from `d79b910818c3883f`

```nim
discard """
action: run
cmd: "nim c --hints:on -d:testing -d:nimUnittestAbortOnError:on $options $file"
matrix: "-d:pga.dimensions=6 -d:pga.is_conformal=true"
"""

include "../suites.nim"
```
