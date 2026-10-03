## Generate dense form of every general measurand: straight-line code over dense multivector.
##   Dense form is what careful hand writes over dense multivector: each result slot assigned
##     once as sum of its terms, no zero fill, no intermediate multivector, no call. Its time
##     is what general row of docket is measured against, as reference is for typed row.
##   Generator evaluates each operation symbolically at compile time over library's own Cayley
##     tables. Slot is polynomial over operand components: sign map composes for free, product
##     multiplies polynomials, and like terms combine. Operand that is already product becomes
##     scalar temporaries first, so chain spends sum of its steps, as its bound does; operand
##     that is only map of another folds into product, as compound product's bound does.
##
##   Cost: tables are library's, so dense form shares any sign library gets wrong. Chapter
##     and wiki suites hold library to reference, and suite `Internal: Dense forms` holds
##     dense form to library.
##   Cost: generation walks every cell of every table in compile-time VM; seconds at 5D.
##   Cost: measurand without recipe here fails build, so new general row brings its own.

{.experimental: "strictFuncs".}

import std/[algorithm, macros, math, sequtils]

import pga
import pga/[algebra {.all.}, cayleys {.all.}, multivectors]

import ./[catalogue, kinds]


type
  Factor = tuple[source, slot: int]
    ## Define one factor of term: operand or temporary, and its slot.
    ##   Source `m` is 0, `n` is 1, and temporaries are 2 on.
    ##   Slot below zero reads source whole, as scalar operand or scalar temporary.
  Term = object
    ## Define one term of slot: coefficient times product of factors.
    coefficient: float
    factors: seq[Factor]
  Slots = array[Basis, seq[Term]]
    ## Define multivector symbolically: each slot is sum of its terms.
  Emitter = object
    ## Define generation state: statements so far, and source next temporary takes.
    statements: NimNode
    source_next: int


const
  SOURCE_M = 0
    ## Source of first operand.
  SOURCE_N = 1
    ## Source of second operand.
  SLOT_WHOLE = -1
    ## Slot that reads source whole, as scalar.
  TOLERANCE_COEFFICIENT = 1e-12
    ## Coefficient below which combined term vanishes.



#[ Polynomials ]#

func operandOf(source: int): Slots =
  ## Read operand whole, each slot one term of itself.
  for b in Basis: result[b] = @[Term(coefficient: 1.0, factors: @[(source, ord(b))])]


func scalarOf(source: int): Slots =
  ## Read scalar operand or temporary as multivector carrying it in scalar slot.
  result[Basis.scalar] = @[Term(coefficient: 1.0, factors: @[(source, SLOT_WHOLE)])]


func constantOf(b: Basis, coefficient = 1.0): Slots =
  ## Read unit constant on one basis element, signed.
  result[b] = @[Term(coefficient: coefficient, factors: @[])]


func degreeOf(slots: Slots): int =
  ## Read greatest count of factors any term carries.
  for terms in slots:
    for term in terms: result = max(result, term.factors.len)


func combined(terms: seq[Term]): seq[Term] =
  ## Combine terms whose factors agree, in sorted order, and drop those that cancel.
  var sorted = terms
  for term in sorted.mitems: term.factors.sort
  sorted.sort(proc (left, right: Term): int = cmp($left.factors, $right.factors))
  for term in sorted:
    if result.len > 0 and result[^1].factors == term.factors:
      result[^1].coefficient += term.coefficient
    else:
      result.add term
  result = result.filterIt(abs(it.coefficient) > TOLERANCE_COEFFICIENT)


func negated(slots: Slots): Slots =
  ## Negate every term.
  for b in Basis:
    for term in slots[b]:
      result[b].add Term(coefficient: -term.coefficient, factors: term.factors)


func summed(left, right: Slots; is_difference = false): Slots =
  ## Add or subtract slot by slot.
  let other = if is_difference: right.negated else: right
  for b in Basis: result[b] = combined(left[b] & other[b])


func mapped(slots: Slots, cayley: Cayley1D): Slots =
  ## Send each slot where one-dimensional table sends its basis element, signed.
  ##   Cell of several terms sends slot to each.
  for b in Basis:
    for destination in cayley[b]:
      for term in slots[b]:
        result[destination.basis].add Term(
          coefficient: if destination.is_negated: -term.coefficient else: term.coefficient,
          factors: term.factors,
        )


func selected(slots: Slots, grade: Grade): Slots =
  ## Keep slots of one grade, and drop rest.
  for b in LUT_BASES_BY_GRADE[grade]: result[b] = slots[b]



#[ Emission ]#

func factorNode(factor: Factor, is_scalar_m: bool): NimNode =
  ## Spell one factor: operand slot, scalar operand or temporary.
  let name = case factor.source
    of SOURCE_M: "m"
    of SOURCE_N: "n"
    else: "t" & $factor.source
  if factor.slot == SLOT_WHOLE or (factor.source == SOURCE_M and is_scalar_m): return ident(name)
  if factor.source > SOURCE_N: return ident(name & "_" & $factor.slot)
  nnkBracketExpr.newTree(ident(name), newCall(bindSym"Basis", newLit(factor.slot)))


func sumNode(terms: seq[Term], is_scalar_m = false): NimNode =
  ## Spell sum of terms, sign folded into add or subtract; zero where none.
  if terms.len == 0: return newLit(0.0)
  for index, term in terms:
    var product: NimNode = nil
    let magnitude = abs(term.coefficient)
    if abs(magnitude - 1.0) > TOLERANCE_COEFFICIENT or term.factors.len == 0:
      product = newLit(magnitude)
    for factor in term.factors:
      let node = factorNode(factor, is_scalar_m)
      product = if product.isNil: node else: infix(product, "*", node)
    let is_negative = term.coefficient < 0
    result =
      if index == 0: (if is_negative: prefix(product, "-") else: product)
      else: infix(result, if is_negative: "-" else: "+", product)


func temporaries(emitter: var Emitter, slots: Slots): Slots =
  ## Bind each non-empty slot to scalar temporary, so later product reads it as one factor.
  let source = emitter.source_next
  inc emitter.source_next
  for b in Basis:
    if slots[b].len == 0: continue
    emitter.statements.add newLetStmt(ident("t" & $source & "_" & $ord(b)), sumNode(slots[b]))
    result[b] = @[Term(coefficient: 1.0, factors: @[(source, ord(b))])]


func bindScalar(emitter: var Emitter, value: NimNode): int =
  ## Bind scalar expression to temporary, and read its source.
  result = emitter.source_next
  inc emitter.source_next
  emitter.statements.add newLetStmt(ident("t" & $result), value)


func product(emitter: var Emitter; left, right: Slots; cayley: Cayley2D): Slots =
  ## Multiply through two-dimensional table; operand already product binds temporaries first.
  let
    left_bound = if left.degreeOf > 1: emitter.temporaries(left) else: left
    right_bound = if right.degreeOf > 1: emitter.temporaries(right) else: right
  for a in Basis:
    if left_bound[a].len == 0: continue
    for b in Basis:
      if right_bound[b].len == 0: continue
      for destination in cayley[a][b]:
        let sign = if destination.is_negated: -1.0 else: 1.0
        for x in left_bound[a]:
          for y in right_bound[b]:
            result[destination.basis].add Term(
              coefficient: sign * x.coefficient * y.coefficient,
              factors: x.factors & y.factors,
            )
  for b in Basis: result[b] = combined(result[b])


func rootOf(terms: seq[Term]): NimNode =
  ## Spell square root of one slot's sum.
  newCall(bindSym"sqrt", sumNode(terms))



#[ Recipes ]#

func recipeOf(emitter: var Emitter; id: string; m, n: Slots): Slots =
  ## Evaluate measurand symbolically, as library defines it, from its tables.

  func norm(emitter: var Emitter, m: Slots, cayley: Cayley2D, b: Basis): Slots =
    ## Read root of one slot of operand's product with itself, in that slot alone.
    let root = emitter.bindScalar(rootOf(emitter.product(m, m, cayley)[b]))
    result[b] = @[Term(coefficient: 1.0, factors: @[(root, SLOT_WHOLE)])]

  func unitized(emitter: var Emitter, m: Slots, cayley: Cayley2D, b: Basis): Slots =
    ## Scale operand by reciprocal of root of one slot of its product with itself, unless zero.
    let
      root = ident("t" & $emitter.bindScalar(rootOf(emitter.product(m, m, cayley)[b])))
      reciprocal = emitter.bindScalar(quote do:
        if `root` != 0: 1.0 / `root` else: 1.0)
    for a in Basis:
      for term in m[a]:
        result[a].add Term(
          coefficient: term.coefficient,
          factors: term.factors & @[(reciprocal, SLOT_WHOLE)],
        )

  func container(emitter: var Emitter, m: Slots): Slots =
    ## Read container, i.e. `m ∧ (m⊟)☆`.
    when IS_CONFORMAL:
      emitter.product(m, m.mapped(CAYLEY_CARRIER).mapped(CAYLEYS_DUAL.anti.right),
        CAYLEYS_WEDGE.base)
    else: m

  func cocarrier(emitter: var Emitter, m: Slots): Slots =
    ## Read cocarrier, i.e. `m☆ ∧ 𝐞∞`.
    when IS_CONFORMAL:
      emitter.product(m.mapped(CAYLEYS_DUAL.anti.right), constantOf(Basis.infinity),
        CAYLEYS_WEDGE.base)
    else: m

  case id
  of "wedge": emitter.product(m, n, CAYLEYS_WEDGE.base)
  of "wedge_anti": emitter.product(m, n, CAYLEYS_WEDGE.anti)
  of "wedge_dot": emitter.product(m, n, CAYLEYS_WEDGE_DOT.base.right)
  of "wedge_dot_anti": emitter.product(m, n, CAYLEYS_WEDGE_DOT.anti.right)
  of "dot": emitter.product(m, n, CAYLEYS_DOT.base)
  of "dot_anti": emitter.product(m, n, CAYLEYS_DOT.anti)
  of "contract_bulk": emitter.product(m, n, CAYLEYS_CONTRACT.right)
  of "contract_weight": emitter.product(m, n, CAYLEY_CONTRACT_WEIGHT_RIGHT)
  of "expand_bulk": emitter.product(m, n, CAYLEY_EXPAND_BULK_RIGHT)
  of "expand_weight": emitter.product(m, n, CAYLEYS_EXPAND.right)
  of "add": summed(m, n)
  of "subtract": summed(m, n, is_difference = true)
  of "project_central":
    emitter.product(n, emitter.product(m, n, CAYLEY_EXPAND_BULK_RIGHT), CAYLEYS_WEDGE.anti)
  of "project_central_anti":
    emitter.product(n, emitter.product(m, n, CAYLEYS_CONTRACT.right), CAYLEYS_WEDGE.base)
  of "project_orthogonal":
    emitter.product(n, emitter.product(m, n, CAYLEYS_EXPAND.right), CAYLEYS_WEDGE.anti)
  of "project_orthogonal_anti":
    emitter.product(n, emitter.product(m, n, CAYLEY_CONTRACT_WEIGHT_RIGHT), CAYLEYS_WEDGE.base)
  of "scale":
    var scale: Cayley2D
    for b in Basis: scale[Basis.scalar][b] = @[BasisSigned(basis: b)]
    emitter.product(m, n, scale)
  of "bulk": m.mapped(CAYLEYS_PARTS.bulk.round)
  of "weight": m.mapped(CAYLEYS_PARTS.weight.round)
  of "complement_right": m.mapped(CAYLEYS_COMPLEMENT.right)
  of "complement_left": m.mapped(CAYLEYS_COMPLEMENT.left)
  of "reverse": m.mapped(CAYLEYS_REVERSE.base)
  of "reverse_anti": m.mapped(CAYLEYS_REVERSE.anti)
  of "dual_bulk": m.mapped(CAYLEYS_DUAL.base.right)
  of "dual_weight": m.mapped(CAYLEYS_DUAL.anti.right)
  of "negate": m.negated
  of "norm_bulk_squared": emitter.product(m, m, CAYLEYS_NORM_SQUARED.base)
  of "norm_weight_squared": emitter.product(m, m, CAYLEYS_NORM_SQUARED.anti)
  of "norm_bulk": emitter.norm(m, CAYLEYS_NORM_SQUARED.base, Basis.scalar)
  of "norm_weight": emitter.norm(m, CAYLEYS_NORM_SQUARED.anti, Basis.scalarAnti)
  of "norm":
    when IS_RIGID:
      summed(emitter.norm(m, CAYLEYS_NORM_SQUARED.base, Basis.scalar),
        emitter.norm(m, CAYLEYS_NORM_SQUARED.anti, Basis.scalarAnti))
    else:
      summed(emitter.norm(m, CAYLEYS_DOT.base, Basis.scalar),
        emitter.norm(m, CAYLEYS_DOT.anti, Basis.scalarAnti))
  of "normalize_bulk": emitter.unitized(m, CAYLEYS_NORM_SQUARED.base, Basis.scalar)
  of "normalize_weight", "unitize":
    emitter.unitized(m, CAYLEYS_NORM_SQUARED.anti, Basis.scalarAnti)
  of "attitude": m.mapped(CAYLEY_ATTITUDE)
  of "select_grade": m.selected(Grade(1))
  of "select_grade_anti": m.selected(GradeAnti(1).toBase)
  else:
    when IS_RIGID:
      case id
      of "support":
        let origin = constantOf(Basis.origin)
        emitter.product(m, emitter.product(origin, m.mapped(CAYLEYS_DUAL.anti.right),
          CAYLEYS_WEDGE.base), CAYLEYS_WEDGE.anti)
      of "support_anti":
        let horizon = constantOf(Basis.horizon.basis,
          if Basis.horizon.is_negated: -1.0 else: 1.0)
        emitter.product(m, emitter.product(horizon, m.mapped(CAYLEYS_DUAL.base.right),
          CAYLEYS_WEDGE.anti), CAYLEYS_WEDGE.base)
      else: raiseAssert("No dense form for `" & id & "`.")
    else:
      case id
      of "bulk_flat": m.mapped(CAYLEYS_PARTS.bulk.flat)
      of "weight_flat": m.mapped(CAYLEYS_PARTS.weight.flat)
      of "norm_bulk_flat": emitter.norm(m, CAYLEYS_DOT.base, Basis.scalar)
      of "norm_weight_flat": emitter.norm(m, CAYLEYS_DOT.anti, Basis.scalarAnti)
      of "carrier": m.mapped(CAYLEY_CARRIER)
      of "carrier_co": emitter.cocarrier(m)
      of "center": emitter.product(emitter.cocarrier(m), m, CAYLEYS_WEDGE.anti)
      of "container": emitter.container(m)
      of "partner":
        emitter.product(emitter.container(m.mapped(CAYLEYS_DUAL.anti.right)),
          m.mapped(CAYLEY_CARRIER), CAYLEYS_WEDGE.anti)
      else: raiseAssert("No dense form for `" & id & "`.")



#[ Functions ]#

macro emitDenseForms*(): untyped =
  ## Emit one dense form per general measurand, named by `denseNameOf`.
  ##   Partner carries sign of its operand's grade, as library's does; grade is read as
  ##   library reads it, from first component beyond tolerance, and sign flips, never scales.
  result = newStmtList()
  for p in CATALOGUE:
    if p.reference.len > 0: continue
    let
      name = ident(p.denseNameOf)
      (m, n) = (ident"m", ident"n")
      is_scalar_m = p.operands[0] == Kind.Scalar
    if p.id == "select_part":
      let body = parseExpr(p.expression)
      result.add quote do:
        func `name`*(`m`: Multivector): float {.inline.} = `body`
      continue
    var emitter = Emitter(statements: newStmtList(), source_next: SOURCE_N + 1)
    let
      slot_m = if is_scalar_m: scalarOf(SOURCE_M) else: operandOf(SOURCE_M)
      slots = emitter.recipeOf(p.id, slot_m, operandOf(SOURCE_N))
      is_partner = p.id == "partner"
    var body = emitter.statements
    let is_negated = ident"is_negated"  # plain ident, since `quote` hides names it declares
    if is_partner:
      # Scan unrolled at build: loop over `Basis` guards its counter against overflow in
      #   release build, and partner then checks error flag that dense form never raises.
      var scan = nnkIfExpr.newTree()
      for b in Basis:
        let component = nnkBracketExpr.newTree(m, newCall(bindSym"Basis", newLit(ord(b))))
        scan.add nnkElifExpr.newTree(
          quote do: `component` > TOLERANCE_ABS or `component` < -TOLERANCE_ABS,
          newLit(int(b.grade) mod 2 == 0),
        )
      scan.add nnkElseExpr.newTree(newLit(true))  # zero reads as grade 0, as library reads it
      body.add newLetStmt(is_negated, scan)
    for b in Basis:
      let target = nnkBracketExpr.newTree(ident"result", newCall(bindSym"Basis", newLit(ord(b))))
      if is_partner and slots[b].len > 0:
        # Sum bound once and flipped after, since select over two sums spells each twice.
        let value = ident("value_" & $ord(b))
        body.add newLetStmt(value, sumNode(slots[b], is_scalar_m))
        body.add newAssignment(target, quote do: (if `is_negated`: -`value` else: `value`))
      else:
        body.add newAssignment(target, sumNode(slots[b], is_scalar_m))
    let type_m = if is_scalar_m: ident"float" else: ident"Multivector"
    result.add(
      if p.arity == 2:
        quote do:
          func `name`*(`m`: `type_m`, `n`: Multivector): Multivector {.inline, noinit.} =
            `body`
      else:
        quote do:
          func `name`*(`m`: Multivector): Multivector {.inline, noinit.} =
            `body`
    )


emitDenseForms()
