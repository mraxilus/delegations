# Arithmetic of homogeneous scalars, and the radius norm as their root

At pin, each norm returns `MultivectorScalars`, the pair s𝟏 + t𝟙 of the scalar and the antiscalar,
and takes a float root of one coefficient. A new module, `pga/scalars.nim`, gives that pair the
functions of Lengyel's `DualNum` under each product. They are an inverse, a root, an inverse root,
an exponential, a sine, a cosine and a tangent, with a division. Each is written once in ε², the
square of 𝟙, and its form under the antiproduct is derived from it at compile time. A function
without a value for some pair returns an `Option`, in every algebra.

The products of pairs are the basis-set forms `⟑` and `⟇` of P04. Under the conformal metric, the
radius norm becomes the root of 𝐦 ∘ 𝐦 under the antiproduct. So at cga4d and cga5d an imaginary
object has an imaginary radius, where pin gives NaN.

## Add `pga/scalars.nim`

```nim
## Define functions of homogeneous scalar s𝟏 + t𝟙 under each product, for any algebra.
##
## Map of names to Lengyel's `DualNum` (`TSDualNum.h`, Terathon Math Library) and notation:
##
##   |-----------------|-----------------|-----------------|
##   | Name            | Lengyel         | Notation        |
##   |-----------------|-----------------|-----------------|
##   | inverse         | Inverse         | 𝐦⟑⁻¹            |
##   | inverseAnti     | AntiInverse     | 𝐦⟇⁻¹            |
##   | sqrt            | Sqrt            | ⟑√𝐦             |
##   | sqrtAnti        | AntiSqrt        | ⟇√𝐦             |
##   | sqrtInverse     | InverseSqrt     | (⟑√𝐦)⟑⁻¹        |
##   | sqrtInverseAnti | AntiInverseSqrt | (⟇√𝐦)⟇⁻¹        |
##   | exp             | Exp             | exp⟑𝐦           |
##   | expAnti         | AntiExp         | exp⟇𝐦           |
##   | sin             | Sin             | sin⟑𝐦           |
##   | sinAnti         | AntiSin         | sin⟇𝐦           |
##   | cos             | Cos             | cos⟑𝐦           |
##   | cosAnti         | AntiCos         | cos⟇𝐦           |
##   | tan             | Tan             | tan⟑𝐦           |
##   | tanAnti         | AntiTan         | tan⟇𝐦           |
##   | /               | operator /      | 𝐦 ⟇ 𝐧⟇⁻¹        |
##   |-----------------|-----------------|-----------------|
##
## Square ε² of 𝟙 under geometric product, i.e. 𝟙 ⟑ 𝟙 = ε²𝟏, fixes arithmetic of pair:
##   0 under rigid metric, so pair is dual number, as Lengyel's `DualNum` is;
##   -1 at cga4d and cga5d, so pair is complex number;
##   +1 at cga3d and cga6d, so pair is split-complex number.
##   Symbol follows dual unit ε of `DualNum`, which writes pair s + tε with ε² = 0.
##   Coefficients s and t lie on 𝟏 and 𝟙, as basis table of `algebra.nim` names them.
## Squares are constructed from product tables, as Architect ruled for P10 on 2026-10-09.
##   Static check holds them to rev(n) det 𝖌, which 𝟙 ⟑ 𝟙 equals for any dimension and metric.
##     𝟙 ⟑ 𝟙̃ = (𝟙 • 𝟙)𝟏, where 𝟙 • 𝟙 = det 𝖌 is entry of exomorphism 𝐆 on 𝟙, by definition.
##     Reverse gives 𝟙̃ = rev(n) 𝟙, with rev(n) = (-1)^(n(n - 1)/2).
##   Check is short path from 𝐆; table is long path from 𝐆, through dual and transwedges.
##   Cost: check trusts 𝐆, as both paths start there.
## Each function is written once in ε², as f on eigenvalues of pair.
##   Dual form reduces to Lengyel's, complex to principal complex function, split-complex to f on
##     each idempotent.
##   Cost: ε² outside -1..1 needs scaling by its root, which no metric of library gives.
## Each form under antiproduct is derived from its form under geometric product at compile time.
##   Complement swaps 𝟏 and 𝟙 and carries ⟑ to ⟇, as `constructAnti` derives each table.
##     So `defineAnti` emits body again, with each name of `LUT_COMPLEMENT_BY_NAME` swapped.
##     Each call becomes call of its form under ⟇ where one is declared, so compositions follow.
##   Functions are not linear, so no table holds them, and derivation acts on their code.
##   Cost: body calls each float function through its operand, e.g. `t.sqrt`, or by module.
## Products of pairs are basis-set forms of P04, so module writes none of them.
## Absence lives in return type, never NaN, and each function has one type in every algebra.
##   Inverse, root, inverse root, tangent and division are optional, as each lacks value somewhere.
##   Each unwraps by test and `get`, as `gradeAnti` does, and never by `map`.
##     Closure for `map` allocates on heap where it captures, as generated C shows.
##   Cost: root is never none at cga4d and cga5d, yet caller there unwraps it.
## Root takes larger part by root and smaller by division, so neither cancels.
##   Cost: one branch on sign of s.
## Domain of root compares exactly, as no scale is in hand there.
##   Cost: 𝐦∘𝐦 of point on null cone rounds either side of zero, so caller compares at scale of 𝐦.
## Each definition precedes its use, as `codeReordering` cannot see functions `defineAnti` emits.
##   Cost: helpers such as `constructSquare` come before what they serve.

{.experimental: "strictFuncs".}

import std/[macros, math, options, strformat, tables]

import ./[algebra, basis_sets, cayleys {.all.}, emitters, multivectors, operators]



#[ Square Definitions ]#

func constructSquare(
  wedge_dots: Spatial[Cayley2D], spatiality: Spatiality
): Coefficient {.compileTime.} =
  ## Construct square of non-unit element of homogeneous scalar under (anti)product.
  ##   I.e. ε² of 𝟙 ⟑ 𝟙 = ε²𝟏 under geometric product, or of 𝟏 ⟇ 𝟏 = ε²𝟙 under antiproduct.
  ##   Unit must be identity of product, so pair closes under it.
  let
    (wedge_dot, unit, element) = case spatiality
      of Spatiality.Base: (wedge_dots.base, Basis.scalar, Basis.scalarAnti)
      of Spatiality.Anti: (wedge_dots.anti, Basis.scalarAnti, Basis.scalar)
    element_signed = @[BasisSigned(basis: element)]
    square = wedge_dot[element][element]
  doAssert wedge_dot[unit][element] == element_signed and
      wedge_dot[element][unit] == element_signed,
    &"Provided product whose unit is not identity; got `{wedge_dot[unit][element]}`."
  doAssert square.len <= 1 and (square.len == 0 or square[0].basis == unit),
    &"Provided product whose square leaves unit; got `{square}`."
  if square.len == 0: 0.0
  elif square[0].is_negated: -1.0
  else: 1.0


const SQUARES_WEDGE_DOT* = Spatial[Coefficient](
  base: constructSquare(CAYLEYS_WEDGE_DOT, Spatiality.Base),
  anti: constructSquare(CAYLEYS_WEDGE_DOT, Spatiality.Anti),
)
  ## Square ε² of 𝟙 under geometric product and of 𝟏 under antiproduct, read from their tables.

# Hold squares against metric, and range that arithmetic of pair covers.
#   Metrics of library give ε² in -1..1; outside, lift range by scaling by its root in
#     `cosSin` and in root of negative s.
static:
  doAssert SQUARES_WEDGE_DOT.base in [-1.0, 0.0, 1.0],
    &"Square of 𝟙 under ⟑ must be -1, 0 or 1; got `{SQUARES_WEDGE_DOT.base}`."
  doAssert SQUARES_WEDGE_DOT.anti == SQUARES_WEDGE_DOT.base,
    &"Complement must carry ⟑ to ⟇, so squares agree; got `{SQUARES_WEDGE_DOT}`."
  let
    exomorphism_antiscalar = CAYLEYS_EXOMORPHISM_METRIC.base[Basis.scalarAnti]
    reverse_antiscalar = CAYLEYS_REVERSE.base[Basis.scalarAnti][0]
    square_metric =
      if exomorphism_antiscalar.len == 0: 0.0
      elif exomorphism_antiscalar[0].is_negated xor reverse_antiscalar.is_negated: -1.0
      else: 1.0
  doAssert SQUARES_WEDGE_DOT.base == square_metric,
    &"Square of product table must equal rev(n) det 𝖌; got `{square_metric=}`."



#[ Scalar Construction ]#

func initMultivectorScalars*(s, t: Coefficient): MultivectorScalars {.noinit.} =
  ## Initialize homogeneous scalar as s𝟏 + t𝟙.
  result[Basis.scalar] = s
  result[Basis.scalarAnti] = t



#[ Derivation Macros ]#

const LUT_COMPLEMENT_BY_NAME = block:
  ## Construct LUT for complement of each name in function body.
  var lut: Table[string, string]
  for (name, name_complement) in [
    ("scalar", "scalarAnti"),  # Bases.
    ("s", "t"),  # Coefficients on bases.
    ("base", "anti"),  # Squares under each product.
    ("⟑", "⟇"),  # Products.
  ]:
    lut[name] = name_complement
    lut[name_complement] = name
  lut

# Hold swap of bases against complement table, so names swap as complement does.
static:
  for (b, b_complement) in [
    (Basis.scalar, Basis.scalarAnti), (Basis.scalarAnti, Basis.scalar)
  ]:
    let
      b_signed = @[BasisSigned(basis: b_complement)]
      complements = [CAYLEYS_COMPLEMENT.right[b], CAYLEYS_COMPLEMENT.left[b]]
    doAssert complements == [b_signed, b_signed],
      &"Complements must swap `{b}` for `{b_complement}`, unsigned; got `{complements}`."


func emitAnti(definition: NimNode, docs: string): NimNode {.compileTime.} =
  ## Emit form under antiproduct of function definition under geometric product.

  func emitComplement(node: NimNode): NimNode =
    ## Emit node with each name that complement swaps swapped, and each call under antiproduct.
    if node.kind == nnkIdent:
      return ident(LUT_COMPLEMENT_BY_NAME.getOrDefault($node, $node))
    result = node.copyNimNode
    for child in node: result.add emitComplement(child)

    # Call form under antiproduct where one is declared, as complement carries composition.
    if node.kind in {nnkCall, nnkCommand} and node[0].kind == nnkIdent:
      var call_anti = result.copyNimTree
      call_anti[0] = ident($node[0] & "Anti")
      result = nnkWhenStmt.newTree(
        nnkElifBranch.newTree(newCall(ident"declared", ident($node[0] & "Anti")), call_anti),
        nnkElse.newTree(result),
      )

  # Construct body without docs under ⟑, which docs under ⟇ replace.
  var body = newNimNode(nnkStmtList)
  for statement in definition.body:
    if statement.kind != nnkCommentStmt: body.add emitComplement(statement)

  # Construct function definition from complemented body.
  emitFunc(
    name = $definition.name & "Anti",
    docs = docs,
    params = definition.params.copyNimTree,
    pragma = definition.pragma.copyNimTree,
    body = body,
    is_public = definition[0].kind == nnkPostfix,
  )


macro defineAnti(docs: static[string], definition: untyped): untyped =
  ## Define function under geometric product, and its form under antiproduct by complement.
  ##   Form under ⟇ is derived once at compile time, as each table of antiproduct is.
  let definition_base = definition[0]
  newStmtList(definition_base, emitAnti(definition_base, docs))



#[ Inverses and Roots ]#

defineAnti(
  docs = "Get inverse of homogeneous scalar under antiproduct, i.e. 𝐦⟇⁻¹ with 𝐦 ⟇ 𝐦⟇⁻¹ = 𝟙.",
):
  func inverse*(m: MultivectorScalars): Option[MultivectorScalars] =
    ## Get inverse of homogeneous scalar under geometric product, i.e. 𝐦⟑⁻¹ with 𝐦 ⟑ 𝐦⟑⁻¹ = 𝟏.
    ##   I.e. (s𝟏 − t𝟙) / (s² − ε²t²) for 𝐦 = s𝟏 + t𝟙.
    ##   None where modulus s² − ε²t² is zero at scale of its two terms.
    ##     Zero pair has none in each algebra, as has pure 𝟙 when dual and s = ±t when split.
    let
      (s, t) = (m[Basis.scalar], m[Basis.scalarAnti])
      modulus_squared = s * s - SQUARES_WEDGE_DOT.base * t * t
      scale = s * s + abs(SQUARES_WEDGE_DOT.base) * t * t
    if abs(modulus_squared) <= TOLERANCE_ABS * scale: return
    some(initMultivectorScalars(s = s / modulus_squared, t = -t / modulus_squared))


defineAnti(
  docs = "Get principal root of homogeneous scalar under antiproduct, i.e. ⟇√𝐦 with t ≥ 0.",
):
  func sqrt*(m: MultivectorScalars): Option[MultivectorScalars] =
    ## Get principal root of homogeneous scalar under geometric product, i.e. ⟑√𝐦 with s ≥ 0.
    ##   Solve p² + ε²q² = s and 2pq = t for root p𝟏 + q𝟙, through modulus ρ = √(s² − ε²t²).
    ##   Complex pair always has root; negative s roots onto 𝟙, as i.
    ##   Dual pair needs positive s or zero; split-complex pair needs s ≥ |t|.
    let (s, t) = (m[Basis.scalar], m[Basis.scalarAnti])

    # Refuse pair outside domain of real roots.
    when SQUARES_WEDGE_DOT.base == 0:
      if s < 0 or (s == 0 and t != 0): return
    elif SQUARES_WEDGE_DOT.base == 1:
      if s < abs(t): return

    # Take larger part by root and smaller by division, so neither cancels.
    let
      modulus =
        when SQUARES_WEDGE_DOT.base == -1: hypot(s, t)
        elif SQUARES_WEDGE_DOT.base == 0: s
        else: ((s - abs(t)) * (s + abs(t))).sqrt
      size = ((abs(s) + modulus) / 2).sqrt
      root =
        if size == 0: initMultivectorScalars(s = 0, t = 0)
        elif s >= 0: initMultivectorScalars(s = size, t = t / (2 * size))
        else: initMultivectorScalars(s = abs(t) / (2 * size), t = copySign(size, t))
    some(root)


defineAnti(
  docs = "Get inverse root of homogeneous scalar under antiproduct, i.e. (⟇√𝐦)⟇⁻¹.",
):
  func sqrtInverse*(m: MultivectorScalars): Option[MultivectorScalars] =
    ## Get inverse root of homogeneous scalar under geometric product, i.e. (⟑√𝐦)⟑⁻¹.
    ##   None without root or its inverse.
    let root = sqrt(m)
    if root.isNone: return
    inverse(root.get)



#[ Exponential Family ]#

func cosSin(angle: Coefficient, square: static[Coefficient]): tuple[cos, sin: Coefficient] =
  ## Get even and odd parts of exp(angle 𝐯) for 𝐯 𝐯 = square 𝐮, i.e. its 𝐮 part and its 𝐯 part.
  ##   Unit 𝐮 is 𝟏 and 𝐯 is 𝟙 under ⟑, and 𝐮 is 𝟙 and 𝐯 is 𝟏 under ⟇.
  ##   Even part sums squareᵏ angle²ᵏ / (2k)!, and odd part sums squareᵏ angle²ᵏ⁺¹ / (2k + 1)!.
  ##   Square -1 gives cosine and sine, 0 gives 1 and angle, +1 gives their hyperbolic forms.
  when square == -1: (angle.cos, angle.sin)
  elif square == 0: (Coefficient(1), angle)
  else: (angle.cosh, angle.sinh)


defineAnti(
  docs = "Raise e to homogeneous scalar under antiproduct, i.e. exp⟇𝐦 = eᵗ (S(s) 𝟏 + C(s) 𝟙).",
):
  func exp*(m: MultivectorScalars): MultivectorScalars {.noinit.} =
    ## Raise e to homogeneous scalar under geometric product, i.e. exp⟑𝐦 = eˢ (C(t) 𝟏 + S(t) 𝟙).
    ##   C and S are even and odd parts of exp⟑(t𝟙), under ε².
    let
      (s, t) = (m[Basis.scalar], m[Basis.scalarAnti])
      (scale, parts) = (s.exp, cosSin(t, SQUARES_WEDGE_DOT.base))
    result[Basis.scalar] = scale * parts.cos
    result[Basis.scalarAnti] = scale * parts.sin


defineAnti(
  docs = """Get sine of homogeneous scalar under antiproduct, i.e. sin⟇𝐦.
  I.e. cos t S(s) 𝟏 + sin t C(s) 𝟙.""",
):
  func sin*(m: MultivectorScalars): MultivectorScalars {.noinit.} =
    ## Get sine of homogeneous scalar under geometric product, i.e. sin⟑𝐦.
    ##   I.e. sin s C(t) 𝟏 + cos s S(t) 𝟙.
    ##   C and S take -ε², as sine and cosine alternate signs of exponential series.
    let
      (s, t) = (m[Basis.scalar], m[Basis.scalarAnti])
      parts = cosSin(t, -SQUARES_WEDGE_DOT.base)
    result[Basis.scalar] = s.sin * parts.cos
    result[Basis.scalarAnti] = s.cos * parts.sin


defineAnti(
  docs = """Get cosine of homogeneous scalar under antiproduct, i.e. cos⟇𝐦.
  I.e. −sin t S(s) 𝟏 + cos t C(s) 𝟙.""",
):
  func cos*(m: MultivectorScalars): MultivectorScalars {.noinit.} =
    ## Get cosine of homogeneous scalar under geometric product, i.e. cos⟑𝐦.
    ##   I.e. cos s C(t) 𝟏 − sin s S(t) 𝟙.
    ##   C and S take -ε², as for sine.
    let
      (s, t) = (m[Basis.scalar], m[Basis.scalarAnti])
      parts = cosSin(t, -SQUARES_WEDGE_DOT.base)
    result[Basis.scalar] = s.cos * parts.cos
    result[Basis.scalarAnti] = -s.sin * parts.sin


defineAnti(
  docs = "Get tangent of homogeneous scalar under antiproduct, i.e. tan⟇𝐦 = sin⟇𝐦 ⟇ (cos⟇𝐦)⟇⁻¹.",
):
  func tan*(m: MultivectorScalars): Option[MultivectorScalars] =
    ## Get tangent of homogeneous scalar under geometric product, i.e. tan⟑𝐦 = sin⟑𝐦 ⟑ (cos⟑𝐦)⟑⁻¹.
    ##   None where cosine has no inverse, as at each pole.
    ##   Product rather than closed form over cos 2s, which cancels near pole.
    let cosine_inverse = inverse(cos(m))
    if cosine_inverse.isNone: return
    some(sin(m) ⟑ cosine_inverse.get)



#[ Division ]#

func `/`*(m, n: MultivectorScalars): Option[MultivectorScalars] =
  ## Divide homogeneous scalars under antiproduct, i.e. 𝐦 ⟇ 𝐧⟇⁻¹, as Lengyel's `DualNum` does.
  ##   None where 𝐧 has no inverse under antiproduct.
  let n_inverse_anti = inverseAnti(n)
  if n_inverse_anti.isNone: return
  some(m ⟇ n_inverse_anti.get)


func `/`*(m: Multivector, n: MultivectorScalars): Option[Multivector] =
  ## Divide multivector by homogeneous scalar under antiproduct, i.e. 𝐦 ⟇ 𝐧⟇⁻¹.
  let n_inverse_anti = inverseAnti(n)
  if n_inverse_anti.isNone: return
  some(m ⟇ n_inverse_anti.get)
```

## Edit `pga.nim`

```nim
import ./pga/[algebra, basis_sets, cayleys, multivectors, operators]
export algebra, basis_sets, cayleys, multivectors, operators
```

```nim
import std/options

import ./pga/[algebra, basis_sets, cayleys, multivectors, operators, scalars]
export algebra, basis_sets, cayleys, multivectors, operators, scalars
```

## Edit `pga.nim`

```nim
  func normRadius*(m: Multivector): MultivectorScalars {.inline.} = |⊘m
    ## Get radius norm of multivector.
```

```nim
  func normRadius*(m: Multivector): Option[MultivectorScalars] {.inline.} =
    ## Get radius norm of multivector as root under antiproduct, i.e. ‖𝐦‖⊘ = ⟇√(𝐦∘𝐦), book's (4.45).
    ##   Real for real object, on 𝟙. Imaginary object has root on 𝟏, as i, at cga4d and cga5d.
    ##   None where 𝐦∘𝐦 has no root, as for imaginary object at cga3d and cga6d.
    sqrtAnti(initMultivectorScalars(s = 0, t = (m ∘ m)[Basis.scalarAnti]))
```
