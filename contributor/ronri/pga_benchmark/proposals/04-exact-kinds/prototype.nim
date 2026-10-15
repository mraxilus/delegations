## Prototype basis-set types of exact bases over library's tables at pin (`exact-kinds`).
##   Evaluation compiles this against library at pin, at each algebra its claim names, and exit
##     code is verdict: every law below holds, or program stops on assertion.
##   One generic object holds coefficients of any set of bases, densely, in basis order. Named
##     basis-set types are its aliases, one per grade and per parity. Product returns exact
##     basis-set type of bases its table reaches, so dot of whole multivectors is one slot, and
##     bulk of bivector is part of its grade.
##   Each basis-set type aligns to `alignmentOf` of its count of floats, from `align.nim`, so it
##     pads none.
##
##   Cost: prototype generates `∧`, `⟇`, `∙`, `∘` and round parts alone, and no squared norm,
##     since library reads each squared norm from 2D table with one operand; proposal says so.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/[macros, random, strutils]

import pga
import pga/[algebra {.all.}, cayleys {.all.}]

import ./align


type MultivectorOf*[B: static set[Basis]] = object
  ## Define multivector of bases `B` alone, coefficients dense in basis order.
  ##   Aligned to `alignmentOf` of its count through `when`, since `align` of expression of `B`
  ##     stops pinned compiler. Field stays private, as library keeps it on `Multivector`.
  when alignmentOf(card(B)) == 64:
    elements {.align(64).}: array[card(B), float]
  elif alignmentOf(card(B)) == 32:
    elements {.align(32).}: array[card(B), float]
  elif alignmentOf(card(B)) == 16:
    elements {.align(16).}: array[card(B), float]
  else:
    elements: array[card(B), float]


const
  SAMPLES = 256  ## Seeded samples each law is checked on.
  SEED = 0  ## Seed of sample generator, so every run checks same samples.



#[ Basis-Set Types ]#

func basesOfParity(is_even: bool): set[Basis] {.compileTime.} =
  ## Get bases of even or odd grade.
  for basis in Basis:
    if (int(basis.grade) mod 2 == 0) == is_even: result.incl basis


func literal(listed: set[Basis]): NimNode {.compileTime.} =
  ## Spell set of bases as literal, since `quote` cannot embed set value.
  result = nnkCurly.newTree()
  for basis in listed: result.add nnkDotExpr.newTree(ident"Basis", ident($basis))


macro defineMultivectors(): untyped =
  ## Name basis-set types as aliases of exact ones: grades and parities.
  ##   Also define `holdLayouts`, which holds size and alignment of each named one. Macro knows
  ##     each count when it runs, so it writes both numbers.
  result = newStmtList()
  var
    named: seq[(string, set[Basis])]
    laws = newStmtList()
  for grade in Grade.low..Grade.high:
    let bases = LUT_BASES_BY_GRADE[grade]
    named.add ("Kvector" & $int(grade), {bases.a .. bases.b})
  named.add ("MultivectorEven", basesOfParity(true))
  named.add ("MultivectorOdd", basesOfParity(false))
  for (name, listed) in named:
    let
      (kind, spelled) = (ident(name), literal(listed))
      (count, alignment) = (card(listed), alignmentOf(card(listed)))
      size = sizeof(float) * count
    result.add quote do:
      type `kind`* = MultivectorOf[`spelled`]
    laws.add quote do:
      doAssert sizeof(`kind`) == `size`, `name` & " must hold its floats unpadded"
      doAssert alignof(`kind`) == `alignment`, `name` & " must align to alignmentOf of its count"
      echo "exact-kinds: ", `name`, ", ", `count`, " floats, ", `size`, " bytes, aligned to ",
        `alignment`
  result.add quote do:
    proc holdLayouts() =
      ## Hold size and alignment of each named basis-set type, as macro wrote them from its count.
      `laws`


defineMultivectors()


func slotOf(listed: set[Basis], basis: Basis): int =
  ## Get dense slot of basis among listed bases: count of listed bases below it.
  for other in Basis:
    if other == basis: return
    if other in listed: inc result


template `[]`*[B: static set[Basis]](m: MultivectorOf[B], basis: static Basis): float =
  ## Read coefficient of basis from its dense slot; basis outside `B` stops compile.
  static: doAssert basis in B, "Basis must be among bases of type; got `" & $basis & "`."
  m.elements[static(slotOf(B, basis))]


template `[]=`*[B: static set[Basis]](m: var MultivectorOf[B], basis: static Basis, value: float) =
  ## Write coefficient of basis into its dense slot; basis outside `B` stops compile.
  static: doAssert basis in B, "Basis must be among bases of type; got `" & $basis & "`."
  m.elements[static(slotOf(B, basis))] = value


func coefficient*[B: static set[Basis]](m: MultivectorOf[B], basis: Basis): float =
  ## Read coefficient of basis known only at run time; basis outside `B` reads zero, its value.
  const lut_slot_by_basis = block:
    var lut: array[Basis, int]
    for listed in B: lut[listed] = slotOf(B, listed)
    lut
  if basis in B: m.elements[lut_slot_by_basis[basis]] else: 0.0


func bases[B: static set[Basis]](t: typedesc[MultivectorOf[B]]): set[Basis] = B
  ## Get bases basis-set type holds.



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
  ## Spell exact basis-set type product reaches, as literal set, so it is same type as any alias.
  nnkBracketExpr.newTree(ident"MultivectorOf", literal(reachOf(cayley, bases_m, bases_n)))


macro kindOf(cayley: static Cayley1D, bases_m: static set[Basis]): untyped =
  ## Spell exact basis-set type map reaches, as literal set.
  nnkBracketExpr.newTree(ident"MultivectorOf", literal(reachOf(cayley, bases_m)))


func writesOf(sums: array[Basis, seq[NimNode]]): NimNode {.compileTime.} =
  ## Write each reached slot of result once; every slot of exact type is reached, so none fills.
  result = newStmtList()
  for basis in Basis:
    if sums[basis].len > 0:
      result.add newAssignment(readOf(ident"result", basis), sumOf(sums[basis]))


macro defineProduct(
  cayley: static Cayley2D; bases_m, bases_n: static set[Basis]; m, n: untyped
): untyped =
  ## Define product over operands' bases alone, into result of exact basis-set type.
  var sums: array[Basis, seq[NimNode]]
  for left in bases_m:
    for right in bases_n:
      for term in cayley[left][right]:
        let product = infix(readOf(m, left), "*", readOf(n, right))
        sums[term.basis].add(if term.is_negated: prefix(product, "-") else: product)
  writesOf(sums)


macro defineMap(cayley: static Cayley1D, bases_m: static set[Basis], m: untyped): untyped =
  ## Define map over operand's bases alone, into result of exact basis-set type.
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
  defineProduct(CAYLEYS_WEDGE.base, A, B, m, n)


func `⟇`*[A, B: static set[Basis]](
  m: MultivectorOf[A], n: MultivectorOf[B]
): kindOf(CAYLEYS_WEDGE_DOT.anti, A, B) {.noinit.} =
  ## Multiply through geometric antiproduct; result holds exactly bases reached.
  defineProduct(CAYLEYS_WEDGE_DOT.anti, A, B, m, n)


func `∙`*[A, B: static set[Basis]](
  m: MultivectorOf[A], n: MultivectorOf[B]
): kindOf(CAYLEYS_DOT.base, A, B) {.noinit.} =
  ## Multiply through inner product; result holds scalar slot alone.
  defineProduct(CAYLEYS_DOT.base, A, B, m, n)


func `∘`*[A, B: static set[Basis]](
  m: MultivectorOf[A], n: MultivectorOf[B]
): kindOf(CAYLEYS_DOT.anti, A, B) {.noinit.} =
  ## Multiply through inner antiproduct; result holds antiscalar slot alone.
  defineProduct(CAYLEYS_DOT.anti, A, B, m, n)


func `∙`*[A: static set[Basis]](
  m: MultivectorOf[A],
): kindOf(CAYLEYS_PARTS.bulk.round, A) {.noinit.} =
  ## Extract bulk; result holds exactly bulk bases of operand's basis-set type.
  defineMap(CAYLEYS_PARTS.bulk.round, A, m)


func `∘`*[A: static set[Basis]](
  m: MultivectorOf[A],
): kindOf(CAYLEYS_PARTS.weight.round, A) {.noinit.} =
  ## Extract weight; result holds exactly weight bases of operand's basis-set type.
  defineMap(CAYLEYS_PARTS.weight.round, A, m)


func toMultivector*[B: static set[Basis]](m: MultivectorOf[B]): Multivector =
  ## Widen basis-set type to library's multivector, same coefficients.
  for basis in B: result[basis] = m.elements[slotOf(B, basis)]


func toMultivectorOf*[B: static set[Basis]](
  m: Multivector, t: typedesc[MultivectorOf[B]]
): MultivectorOf[B] =
  ## Narrow library's multivector to basis-set type `t`.
  ##   Each coefficient outside `B` must be zero within comparison tolerance, as `grade` tests it.
  for basis in Basis:
    if basis in B: result.elements[slotOf(B, basis)] = m[basis]
    else:
      doAssert abs(m[basis]) <= TOLERANCE_ABS,
        "Coefficient outside bases of type must be zero; got `" & $m[basis] & "` at `" &
        $basis & "`."



#[ Laws ]#

proc sample[B: static set[Basis]](kind: typedesc[MultivectorOf[B]]): MultivectorOf[B] =
  ## Draw one basis-set type with every slot uniform in [-1, 1].
  for index in 0..<result.elements.len: result.elements[index] = rand(-1.0..1.0)


proc main(): int =
  ## Hold laws on seeded samples; print where they hold, and exit zero.
  randomize(SEED)
  var written = sample(Kvector1)
  let
    (p, q) = (sample(Kvector1), sample(Kvector1))
    (m, n) = (sample(MultivectorOf[{Basis.low..Basis.high}]),
        sample(MultivectorOf[{Basis.low..Basis.high}]))
    bivector = sample(Kvector2)
    even = sample(MultivectorEven)
    top = sample(MultivectorOf[{Basis.scalarAnti}])
  holdLayouts()
  doAssert alignof(typeof(∙bivector)) == alignmentOf(card(bases(typeof(∙bivector)))),
    "type that product returns aligns by same rule as named ones"
  doAssert (p ∧ q) is Kvector2, "vector wedge vector must be bivector, equal to its alias"
  doAssert ($typeof(p ∧ q)).startsWith("MultivectorOf[{"),
    "alias adds no type, so type prints as generic with its bases"
  echo "exact-kinds: vector wedge vector prints as ", $typeof(p ∧ q)
  doAssert (m ∙ n) is MultivectorOf[{Basis.scalar}], "dot of whole multivectors must be scalar slot"
  doAssert sizeof(m ∙ n) == sizeof(float), "dot writes one slot, never whole multivector"
  doAssert sizeof(m ∘ n) == sizeof(float), "antidot writes one slot, never whole multivector"
  doAssert sizeof(∘p) == sizeof(float), "weight of vector writes one slot"
  doAssert sizeof(∙m) * (when IS_RIGID: 2 else: 4) == sizeof(Multivector),
    "bulk of whole holds half of bases under rigid metric, and quarter under conformal metric"
  doAssert ((even ⟇ p) ⟇ even) is MultivectorOdd,
    "sandwich of vector reaches whole odd parity, as table can produce"
  echo "exact-kinds: bytes of m ∙ n ", sizeof(m ∙ n), ", m ∘ n ", sizeof(m ∘ n), ", ∙ bivector ",
    sizeof(∙bivector), ", ∘ vector ", sizeof(∘p), ", ∙ whole ", sizeof(∙m), ", sandwich ",
    sizeof((even ⟇ p) ⟇ even), ", library ", sizeof(Multivector)
  doAssert bases(typeof(∙bivector)) < bases(Kvector2), "bulk of bivector is part of grade"
  when IS_RIGID:
    doAssert bases(typeof(∙bivector)) + bases(typeof(∘bivector)) == bases(Kvector2),
      "bulk and weight of bivector cover its grade, under rigid metric"
  doAssert card(bases(typeof(top ∧ top))) == 0 and (top ∧ top).toMultivector =~ 0.0,
    "product that reaches no basis holds no coefficient, and widens to zero"
  doAssert not compiles(p[Basis.scalar]) and not compiles(written[Basis.scalar] = 1.0),
    "basis outside bases of type must stop compile, never reach another slot"
  var expected = written.toMultivector
  written[Basis.vectorLast] = 1.0
  expected[Basis.vectorLast] = 1.0
  doAssert written.toMultivector =~ expected, "write reaches slot of its basis alone"
  var read: Multivector
  for basis in Basis: read[basis] = bivector.coefficient(basis)
  doAssert read =~ bivector.toMultivector, "read at run time equals widened, and zero outside"
  doAssert even.toMultivector.toMultivectorOf(MultivectorEven).toMultivector =~
      even.toMultivector,
    "narrow of widened returns same coefficients"
  doAssertRaises(AssertionDefect): discard m.toMultivector.toMultivectorOf(Kvector1)
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
