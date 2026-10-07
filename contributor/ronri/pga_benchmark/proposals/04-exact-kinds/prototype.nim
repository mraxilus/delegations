## Prototype kinds of exact bases over library's derived tables (`exact-kinds`).
##   Evaluation compiles this against changed library at each algebra its claim names, and exit code
##     is verdict: every law below holds, or program stops on assertion.
##   One generic object holds coefficients of any set of bases, densely, in basis order. Named
##     kinds are its aliases, one per grade and per parity. Product returns
##     kind of exactly bases its table reaches, so dot of whole multivectors is one slot, and
##     bulk of bivector is part of its grade.
##
##   Cost: prototype generates `∧`, `⟇`, `∙`, `∘` and unary parts alone; record says so.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/[macros, random]

import pga
import pga/[algebra {.all.}, cayleys {.all.}]


type MultivectorOf*[B: static set[Basis]] = object
  ## Define multivector of bases `B` alone, coefficients dense in basis order.
  elements*: array[card(B), float]


const
  SAMPLES = 256  ## Seeded samples each law is checked on.
  SEED = 0  ## Seed of sample generator, so every run checks same samples.



#[ Kinds ]#

func basesOfParity(is_even: bool): set[Basis] {.compileTime.} =
  ## Get bases of even or odd grade.
  for basis in Basis:
    if (int(basis.grade) mod 2 == 0) == is_even: result.incl basis


func literal(listed: set[Basis]): NimNode {.compileTime.} =
  ## Spell set of bases as literal, since `quote` cannot embed set value.
  result = nnkCurly.newTree()
  for basis in listed: result.add nnkDotExpr.newTree(ident"Basis", ident($basis))


macro defineKinds(): untyped =
  ## Name kinds as aliases of exact kinds: grades and parities.
  result = newStmtList()
  var named: seq[(string, set[Basis])]
  for grade in Grade.low..Grade.high:
    let bases = LUT_BASES_BY_GRADE[grade]
    named.add ("Kvector" & $int(grade), {bases.a .. bases.b})
  named.add ("MultivectorEven", basesOfParity(true))
  named.add ("MultivectorOdd", basesOfParity(false))
  for (name, listed) in named:
    let (kind, spelled) = (ident(name), literal(listed))
    result.add quote do:
      type `kind`* = MultivectorOf[`spelled`]


defineKinds()


func slotOf(listed: set[Basis], basis: Basis): int =
  ## Get dense slot of basis among listed bases: count of listed bases below it.
  for other in Basis:
    if other == basis: return
    if other in listed: inc result


template `[]`*[B: static set[Basis]](m: MultivectorOf[B], basis: static Basis): float =
  ## Read coefficient of basis from its dense slot.
  m.elements[static(slotOf(B, basis))]


template `[]=`*[B: static set[Basis]](m: var MultivectorOf[B], basis: static Basis, value: float) =
  ## Write coefficient of basis into its dense slot.
  m.elements[static(slotOf(B, basis))] = value



#[ Products ]#

func sumOf(terms: seq[NimNode]): NimNode {.compileTime.} =
  ## Spell sum of terms, left to right.
  result = terms[0]
  for term in terms[1 .. ^1]: result = infix(result, "+", term)


func readOf(m: NimNode, basis: Basis): NimNode {.compileTime.} =
  ## Spell read of one coefficient of operand.
  nnkBracketExpr.newTree(m, nnkDotExpr.newTree(ident"Basis", ident($basis)))


func reachOf(cayley: Cayley2D; bases_m, bases_n: set[Basis]): set[Basis] {.compileTime.} =
  ## Get bases product reaches over operands' bases.
  for left in bases_m:
    for right in bases_n:
      for term in cayley[left][right]: result.incl term.basis


func reachOf(cayley: Cayley1D, bases_m: set[Basis]): set[Basis] {.compileTime.} =
  ## Get bases map reaches over operand's bases.
  for basis in bases_m:
    for term in cayley[basis]: result.incl term.basis


macro kindOf(cayley: static Cayley2D; bases_m, bases_n: static set[Basis]): untyped =
  ## Spell exact kind product reaches, as literal set, so it is same type as any alias of it.
  nnkBracketExpr.newTree(ident"MultivectorOf", literal(reachOf(cayley, bases_m, bases_n)))


macro kindOf(cayley: static Cayley1D, bases_m: static set[Basis]): untyped =
  ## Spell exact kind map reaches, as literal set.
  nnkBracketExpr.newTree(ident"MultivectorOf", literal(reachOf(cayley, bases_m)))


func writesOf(sums: array[Basis, seq[NimNode]]): NimNode {.compileTime.} =
  ## Write each reached slot of result once; every slot of exact kind is reached, so none fills.
  result = newStmtList()
  for basis in Basis:
    if sums[basis].len > 0:
      result.add newAssignment(readOf(ident"result", basis), sumOf(sums[basis]))


macro emitProduct(
  cayley: static Cayley2D; bases_m, bases_n: static set[Basis]; m, n: untyped
): untyped =
  ## Emit product over operands' bases alone, into result of exact kind.
  var sums: array[Basis, seq[NimNode]]
  for left in bases_m:
    for right in bases_n:
      for term in cayley[left][right]:
        let product = infix(readOf(m, left), "*", readOf(n, right))
        sums[term.basis].add(if term.is_negated: prefix(product, "-") else: product)
  writesOf(sums)


macro emitMap(cayley: static Cayley1D, bases_m: static set[Basis], m: untyped): untyped =
  ## Emit map over operand's bases alone, into result of exact kind.
  var sums: array[Basis, seq[NimNode]]
  for basis in bases_m:
    for term in cayley[basis]:
      let read = readOf(m, basis)
      sums[term.basis].add(if term.is_negated: prefix(read, "-") else: read)
  writesOf(sums)


func `∧`*[A, B: static set[Basis]](
  m: MultivectorOf[A], n: MultivectorOf[B]
): kindOf(CAYLEYS_WEDGE.base, A, B) {.noinit.} =
  ## Multiply through exterior product; result holds exactly bases reached.
  emitProduct(CAYLEYS_WEDGE.base, A, B, m, n)


func `⟇`*[A, B: static set[Basis]](
  m: MultivectorOf[A], n: MultivectorOf[B]
): kindOf(CAYLEYS_WEDGE_DOT.anti, A, B) {.noinit.} =
  ## Multiply through geometric antiproduct; result holds exactly bases reached.
  emitProduct(CAYLEYS_WEDGE_DOT.anti, A, B, m, n)


func `∙`*[A, B: static set[Basis]](
  m: MultivectorOf[A], n: MultivectorOf[B]
): kindOf(CAYLEYS_DOT.base, A, B) {.noinit.} =
  ## Multiply through inner product; result holds scalar slot alone.
  emitProduct(CAYLEYS_DOT.base, A, B, m, n)


func `∘`*[A, B: static set[Basis]](
  m: MultivectorOf[A], n: MultivectorOf[B]
): kindOf(CAYLEYS_DOT.anti, A, B) {.noinit.} =
  ## Multiply through inner antiproduct; result holds antiscalar slot alone.
  emitProduct(CAYLEYS_DOT.anti, A, B, m, n)


func `∙`*[A: static set[Basis]](
  m: MultivectorOf[A],
): kindOf(CAYLEYS_PARTS.bulk.round, A) {.noinit.} =
  ## Extract bulk; result holds exactly bulk bases of operand's kind.
  emitMap(CAYLEYS_PARTS.bulk.round, A, m)


func `∘`*[A: static set[Basis]](
  m: MultivectorOf[A],
): kindOf(CAYLEYS_PARTS.weight.round, A) {.noinit.} =
  ## Extract weight; result holds exactly weight bases of operand's kind.
  emitMap(CAYLEYS_PARTS.weight.round, A, m)


func toMultivector*[B: static set[Basis]](m: MultivectorOf[B]): Multivector =
  ## Widen exact kind to library's multivector, same coefficients.
  for basis in B: result[basis] = m.elements[slotOf(B, basis)]



#[ Laws ]#

proc sample[B: static set[Basis]](kind: typedesc[MultivectorOf[B]]): MultivectorOf[B] =
  ## Draw one kind with every slot uniform in [-1, 1].
  for index in 0..<result.elements.len: result.elements[index] = rand(-1.0..1.0)


func basesOf[B: static set[Basis]](kind: typedesc[MultivectorOf[B]]): set[Basis] = B
  ## Get bases kind holds.


proc main(): int =
  ## Hold laws on seeded samples; print where they hold, and exit zero.
  randomize(SEED)
  let
    (p, q) = (sample(Kvector1), sample(Kvector1))
    (m, n) = (sample(MultivectorOf[{Basis.low..Basis.high}]),
        sample(MultivectorOf[{Basis.low..Basis.high}]))
    bivector = sample(Kvector2)
  doAssert (p ∧ q) is Kvector2, "vector wedge vector must be bivector, named by its alias"
  doAssert (m ∙ n) is MultivectorOf[{Basis.scalar}], "dot of whole multivectors must be scalar slot"
  doAssert sizeof(m ∙ n) == sizeof(float), "dot writes one slot, never whole multivector"
  doAssert sizeof(m ∘ n) == sizeof(float), "antidot writes one slot, never whole multivector"
  doAssert basesOf(typeof(∙bivector)) < basesOf(Kvector2), "bulk of bivector is part of grade"
  when IS_RIGID:
    doAssert basesOf(typeof(∙bivector)) + basesOf(typeof(∘bivector)) == basesOf(Kvector2),
      "bulk and weight of bivector cover its grade, under rigid metric"
  for _ in 1..SAMPLES:
    let
      (a, b) = (sample(Kvector1), sample(Kvector2))
      (u, v) = (sample(MultivectorOf[{Basis.low..Basis.high}]),
          sample(MultivectorOf[{Basis.low..Basis.high}]))
      motor = sample(MultivectorEven)
    doAssert (a ∧ b).toMultivector =~ (a.toMultivector ∧ b.toMultivector)
    doAssert ((motor ⟇ a) ⟇ motor).toMultivector =~
        ((motor.toMultivector ⟇ a.toMultivector) ⟇ motor.toMultivector)
    doAssert (u ∙ v).toMultivector =~ (u.toMultivector ∙ v.toMultivector)
    doAssert (u ∘ v).toMultivector =~ (u.toMultivector ∘ v.toMultivector)
    doAssert (∙b).toMultivector =~ ∙b.toMultivector
    doAssert (∘b).toMultivector =~ ∘b.toMultivector
  echo "exact-kinds: laws hold at ", DIMENSIONS, "D, conformal ", IS_CONFORMAL
  0


when isMainModule:
  quit main()
