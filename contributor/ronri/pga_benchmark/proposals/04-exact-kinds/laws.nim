## Hold laws of basis-set types, as library carrying this change exports them (`exact-kinds`).
##   Evaluation compiles this against library with change applied, at each algebra its claim
##     names, and exit code is verdict: every law below holds, or program stops on assertion.
##   Each form of basis-set types equals operator of library on whole multivectors, at each named
##     type and at pairs of types that `DIMENSIONS_SWEPT` sets. Where form stops compile, operator
##     of library gives zero there, so form loses no value. Its type holds exactly bases its table
##     reaches, and each named alias returns that type.
##   Each named basis-set type holds its coefficients unpadded, aligned to `alignment` of its
##     count.
##   Samples narrow multivector of library to each type, so laws reach no private field.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[algorithm, macros, random, sequtils, strformat, strutils, tables]

import pga


const
  SAMPLES = 256  ## Seeded samples each law is checked on.
  SEED = 0  ## Seed of sample generator, so every run checks same samples.
  DIMENSIONS_SWEPT = 4
    ## Highest dimension laws hold each product at every pair of types at; past it, vector pairs
    ##   with each type, either side. Compiler takes about 0.3 MiB per term that form emits, and
    ##   every pair at rga5d emits some 20 000 terms, whose build peaks at 7 158 MiB.
  ALIGNMENTS_NAMED = [(3, 8), (4, 32), (5, 8), (6, 16), (8, 64), (10, 16), (16, 64)]
    ## Count of coefficients of each named basis-set type, rga3d to cga5d, aligned at 64 bits.
  OPERATORS_MAPS = ["∙", "∘", "/", "\\", "~", "~∘", "★", "☆", "⊖", "|∙²", "|∘²"]
    ## Operators of one operand that every algebra builds from one table, squared norms last.
  OPERATORS_MAPS_CONFORMAL = ["■", "□", "⊟", "|■²", "|□²", "|⊘²"]
    ## Operators of one operand that conformal metric adds.
  OPERATORS_PRODUCTS = ["∧", "∨", "⟑", "⟇", "∙", "∘", "∧★", "∧☆", "∨★", "∨☆"]
    ## Operators of two operands that every algebra builds from one table.
  ALIASES_MAPS = [
    ("complementLeft", "\\"), ("complementRight", "/"), ("dualBulk", "★"), ("dualWeight", "☆"),
    ("reverse", "~"), ("reverseAnti", "~∘"), ("attitude", "⊖"),
  ]  ## Alias of each map of every algebra, beside its operator.
  ALIASES_MAPS_METRIC =
    when IS_RIGID: @[("bulk", "∙"), ("weight", "∘")]
    else:
      @[
        ("bulkRound", "∙"), ("weightRound", "∘"), ("bulkFlat", "■"), ("weightFlat", "□"),
        ("carrier", "⊟"),
      ]
    ## Alias of each map that metric names.
  ALIASES_PRODUCTS = [
    ("dot", "∙"), ("dotAnti", "∘"), ("wedge", "∧"), ("wedgeAnti", "∨"), ("wedgeDot", "⟑"),
    ("wedgeDotAnti", "⟇"), ("contractBulk", "∨★"), ("contractWeight", "∨☆"),
    ("expandBulk", "∧★"), ("expandWeight", "∧☆"),
  ]  ## Alias of each product, beside its operator.



#[ Laws ]#

func bases[B: static Bases](t: typedesc[MultivectorOf[B]]): Bases = B
  ## Get bases basis-set type holds.


proc sample[B: static Bases](t: typedesc[MultivectorOf[B]]): MultivectorOf[B] =
  ## Sample basis-set type with each coefficient uniform in [-1, 1], narrowed from multivector.
  var m: Multivector
  for basis in B: m[basis] = Coefficient(rand(-1.0..1.0))
  toMultivectorOf[bases(Multivector), B](m)


macro defineChecksLayout(): untyped =
  ## Define check of size and alignment of each named basis-set type, from its count of bases.
  result = newStmtList()
  let half = 1 shl (DIMENSIONS - 1)
  var named = @[("MultivectorEven", half), ("MultivectorOdd", half)]
  for grade in Grade.low..Grade.high:
    let bases = LUT_BASES_BY_GRADE[grade]
    named.add ("Multivector" & $int(grade), ord(bases.b) - ord(bases.a) + 1)
  for (name, count) in named:
    let
      alias = ident(name)
      (size, aligned) = (sizeof(Coefficient) * count, alignment(count))
    result.add quote do:
      doAssert sizeof(`alias`) == `size`,
        `name` & " must hold its coefficients unpadded; got `" & $sizeof(`alias`) & "`."
      doAssert alignof(`alias`) == `aligned`,
        `name` & " must align to alignment of its count; got `" & $alignof(`alias`) & "`."


func namesTyped(): seq[string] {.compileTime.} =
  ## Name each named basis-set type: each grade, then each parity.
  for grade in Grade.low..Grade.high: result.add "Multivector" & $int(grade)
  result.add ["MultivectorEven", "MultivectorOdd"]


func emitHold(
  operator: string, names: seq[string], held, stopped: NimNode
): NimNode {.compileTime.} =
  ## Emit law of one form at one type or pair: equal to library where it compiles, else zero.
  let
    symbol = nnkAccQuoted.newTree(ident(operator))
    label = operator & " of " & names.join(" and ")
    (message_held, message_zero) = (
      newLit("Form must equal operator of library at " & label & "."),
      newLit("Form that stops compile must be zero in library at " & label & "."),
    )
    (kind_m, kind_n) = (ident(names[0]), ident(names[^1]))
    key = if names.len == 1: operator & "𝐦" else: "𝐦 " & operator & " 𝐧"
  if names.len == 1:
    return quote do:
      when compiles(`symbol`(sample(`kind_m`))):
        `held`.inc `key`
        for _ in 1..SAMPLES:
          let m = sample(`kind_m`)
          doAssert `symbol`(m).toMultivector =~ `symbol`(m.toMultivector), `message_held`
      else:
        `stopped`.inc `key`
        for _ in 1..SAMPLES:
          let m = sample(`kind_m`)
          doAssert `symbol`(m.toMultivector) =~ Coefficient(0), `message_zero`
  quote do:
    when compiles(`symbol`(sample(`kind_m`), sample(`kind_n`))):
      `held`.inc `key`
      for _ in 1..SAMPLES:
        let (m, n) = (sample(`kind_m`), sample(`kind_n`))
        doAssert `symbol`(m, n).toMultivector =~ `symbol`(m.toMultivector, n.toMultivector),
          `message_held`
    else:
      `stopped`.inc `key`
      for _ in 1..SAMPLES:
        let (m, n) = (sample(`kind_m`), sample(`kind_n`))
        doAssert `symbol`(m.toMultivector, n.toMultivector) =~ Coefficient(0), `message_zero`


macro holdForms(held, stopped: CountTable[string]): untyped =
  ## Hold each form to operator of library, at each named type and at pairs of named types and
  ##   whole multivector; count, by operator, instances that compile and ones that stop.
  ##   Pairs are every pair up to `DIMENSIONS_SWEPT`, and vector with each type past it.
  ##   Two whole multivectors keep operator of library, so no pair holds them both.
  result = newStmtList()
  let
    names = namesTyped()
    maps = @OPERATORS_MAPS & (if IS_CONFORMAL: @OPERATORS_MAPS_CONFORMAL else: @[])
  for operator in maps:
    for name in names: result.add emitHold(operator, @[name], held, stopped)
  for operator in OPERATORS_PRODUCTS:
    for left in names & "Multivector":
      for right in names & "Multivector":
        if left == right and left == "Multivector": continue
        if DIMENSIONS > DIMENSIONS_SWEPT and "Multivector1" notin [left, right]: continue
        result.add emitHold(operator, @[left, right], held, stopped)


macro holdAliases(): untyped =
  ## Hold each alias of form to its operator, in value and type, at each named type where
  ##   operator compiles; product pairs vector with each named type.
  result = newStmtList()
  let names = namesTyped()
  for (alias, operator) in @ALIASES_MAPS & ALIASES_MAPS_METRIC:
    let (name, symbol) = (ident(alias), nnkAccQuoted.newTree(ident(operator)))
    for kind in names.mapIt(ident(it)):
      result.add quote do:
        when compiles(`symbol`(sample(`kind`))):
          let m = sample(`kind`)
          doAssert typeof(`name`(m)) is typeof(`symbol`(m)),
            `alias` & " must return type of its operator."
          doAssert `name`(m).toMultivector =~ `symbol`(m).toMultivector,
            `alias` & " must forward to its operator."
  for (alias, operator) in ALIASES_PRODUCTS:
    let (name, symbol) = (ident(alias), nnkAccQuoted.newTree(ident(operator)))
    for kind in names.mapIt(ident(it)):
      result.add quote do:
        when compiles(`symbol`(sample(Multivector1), sample(`kind`))):
          let (m, n) = (sample(Multivector1), sample(`kind`))
          doAssert typeof(`name`(m, n)) is typeof(`symbol`(m, n)),
            `alias` & " must return type of its operator."
          doAssert `name`(m, n).toMultivector =~ `symbol`(m, n).toMultivector,
            `alias` & " must forward to its operator."


macro holdTypesGraded(): untyped =
  ## Hold type of each map whose reach follows from grade: reverse and antireverse keep each
  ##   named type, and each complement takes grade k to grade N - k.
  result = newStmtList()
  for name in namesTyped():
    let kind = ident(name)
    result.add quote do:
      doAssert typeof(~sample(`kind`)) is `kind`, "Reverse must keep type of " & `name` & "."
      doAssert typeof(~∘sample(`kind`)) is `kind`, "Antireverse must keep type of " & `name` & "."
  for grade in Grade.low..Grade.high:
    let
      kind = ident("Multivector" & $int(grade))
      complement = ident("Multivector" & $(int(Grade.high) - int(grade)))
    result.add quote do:
      doAssert typeof(/sample(`kind`)) is `complement`, "Right complement must take k to N - k."
      doAssert typeof(\sample(`kind`)) is `complement`, "Left complement must take k to N - k."


proc holdAlignment() =
  ## Hold alignment of every count of coefficients, then of each count named types reach.
  for count in 0..64:
    let (size, aligned) = (sizeof(Coefficient) * count, alignment(count))
    doAssert aligned in [4, 8, 16, 32, 64], &"Alignment must be power of two; got `{aligned}`."
    doAssert size mod aligned == 0, &"Alignment must pad no count; got `{aligned}` at `{count}`."
    doAssert count == 0 or aligned == 64 or size mod (2 * aligned) != 0,
      &"Alignment must be largest that pads none; got `{aligned}` at `{count}`."
  for (count, aligned) in ALIGNMENTS_NAMED:
    if sizeof(Coefficient) != 8: break  # Table holds 64-bit coefficients.
    doAssert alignment(count) == aligned,
      &"Named type must align as proposal tables it; got `{alignment(count)}` at `{count}`."


proc main(): int =
  ## Hold laws on seeded samples; print where they hold, and exit zero.
  randomize(SEED)
  holdAlignment()
  defineChecksLayout()
  let
    (p, q) = (sample(Multivector1), sample(Multivector1))
    (m, n) = (sample(Multivector), sample(Multivector))
    bivector = sample(Multivector2)
    even = sample(MultivectorEven)
    top = sample(MultivectorOf[{Basis.scalarAnti}])
  doAssert alignof(typeof(p ∧ m)) == alignment(card(bases(typeof(p ∧ m)))),
    "Type product returns must align by same rule as named ones."
  doAssert (p ∧ q) is Multivector2, "Vector wedge vector must be bivector, equal to its alias."
  doAssert ($typeof(p ∧ q)).startsWith("MultivectorOf[{"),
    "Alias must add no type, so type prints as generic with its bases."
  echo "exact-kinds: vector wedge vector prints as ", $typeof(p ∧ q)
  doAssert (m ∙ n) is Multivector,
    "Product of two whole multivectors must stay library's, so no caller sees change."
  doAssert (p ∙ m) is Multivector0, "Dot of vector and whole multivector must be scalar."
  doAssert ((p ∧ q) ⟇ (m ∧ n)) is Multivector,
    "Product that reaches every basis must be `Multivector`, so library takes it."
  doAssert sizeof(p ∙ m) == sizeof(Coefficient),
    "Dot must write one coefficient, never whole multivector."
  doAssert sizeof(p ∘ m) == sizeof(Coefficient),
    "Antidot must write one coefficient, never whole multivector."
  doAssert sizeof(∘p) == sizeof(Coefficient), "Weight of vector must write one coefficient."
  doAssert (∙m) is Multivector, "Bulk of whole multivector must stay library's."
  doAssert ((even ⟇ p) ⟇ even) is MultivectorOdd,
    "Sandwich of vector must reach whole odd parity, as table can produce."
  echo "exact-kinds: bytes of p ∙ m ", sizeof(p ∙ m), ", p ∘ m ", sizeof(p ∘ m), ", ∙ bivector ",
    (when compiles(∙bivector): sizeof(∙bivector) else: 0), ", ∘ vector ", sizeof(∘p),
    ", ∙ whole ", sizeof(∙m), ", sandwich ", sizeof((even ⟇ p) ⟇ even), ", library ",
    sizeof(Multivector)
  echo "exact-kinds: bytes of ‖p‖∙² ", sizeof(`|∙²`(p)), ", / p ", sizeof(/p), ", ★ p ",
    sizeof(★p), ", ☆ p ", sizeof(☆p), ", p ⟑ q ", sizeof(p ⟑ q)
  # Bivectors hold no bulk at rga2d, where grade 2 is antiscalar, nor at cga3d.
  when compiles(∙bivector):
    doAssert bases(typeof(∙bivector)) < bases(Multivector2),
      "Bulk of bivector must be part of grade."
    when IS_RIGID:
      doAssert bases(typeof(∙bivector)) + bases(typeof(∘bivector)) == bases(Multivector2),
        "Bulk and weight of bivector must cover its grade, under rigid metric."
  doAssert not compiles(top ∧ top), "Product that reaches no basis must stop compile."
  doAssert not compiles(p[Basis.scalar]),
    "Static basis outside bases of type must stop compile, so product reads fixed indexes alone."
  doAssert wedge(p, q).toMultivector =~ (p ∧ q).toMultivector, "Alias must forward to operator."
  doAssert `|∙²`(p) is Multivector0, "Bulk squared norm of vector must be one scalar."
  doAssert sizeof(`|∙²`(p)) == sizeof(Coefficient) and sizeof(`|∘²`(p)) == sizeof(Coefficient),
    "Squared norm of vector must write one coefficient, never whole multivector."
  doAssert `|∙²`(m) is Multivector, "Squared norm of whole multivector must stay library's."
  when IS_RIGID:
    doAssert not compiles(★top), "Bulk dual of antiscalar is zero, so it must stop compile."
  holdTypesGraded()
  holdAliases()
  var held, stopped: CountTable[string]
  holdForms(held, stopped)
  echo "exact-kinds: forms hold at ", toSeq(held.values).foldl(a + b), " types and pairs; ",
    toSeq(stopped.values).foldl(a + b, 0), " stop compile, each zero in library"
  echo "exact-kinds: stops by operator ",
    toSeq(stopped.keys).sorted.mapIt(it & " " & $stopped[it]).join(", ")
  for _ in 1..SAMPLES:
    let
      (a, b, c) = (sample(Multivector1), sample(Multivector2), sample(Multivector1))
      (u, v) = (sample(MultivectorOdd), sample(Multivector))
      motor = sample(MultivectorEven)
    doAssert (a ∧ c).toMultivector =~ (a.toMultivector ∧ c.toMultivector),
      &"Wedge must equal library's; got `{(a ∧ c).toMultivector}`."
    when compiles(a ∧ b):  # Vector wedge bivector reaches no basis at rga2d.
      doAssert (a ∧ b).toMultivector =~ (a.toMultivector ∧ b.toMultivector),
        &"Wedge must equal library's; got `{(a ∧ b).toMultivector}`."
    doAssert ((motor ⟇ a) ⟇ motor).toMultivector =~
        ((motor.toMultivector ⟇ a.toMultivector) ⟇ motor.toMultivector),
      &"Antiproduct must equal library's; got `{((motor ⟇ a) ⟇ motor).toMultivector}`."
    doAssert (u ∙ v).toMultivector =~ (u.toMultivector ∙ v.toMultivector),
      &"Dot must equal library's; got `{(u ∙ v).toMultivector}`."
    doAssert (u ∘ v).toMultivector =~ (u.toMultivector ∘ v.toMultivector),
      &"Antidot must equal library's; got `{(u ∘ v).toMultivector}`."
    when compiles(∙b):
      doAssert (∙b).toMultivector =~ ∙b.toMultivector,
        &"Bulk must equal library's; got `{(∙b).toMultivector}`."
    when compiles(∘b):
      doAssert (∘b).toMultivector =~ ∘b.toMultivector,
        &"Weight must equal library's; got `{(∘b).toMultivector}`."
  echo "exact-kinds: laws hold at ", DIMENSIONS, "D, conformal ", IS_CONFORMAL
  0


when isMainModule:
  quit main()
