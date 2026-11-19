## Hold laws of basis-set types, as library carrying this change exports them (`basis-set-forms`).
##   Evaluation compiles this against library with change applied, at each algebra its claim
##     names, and exit code is verdict: every law below holds, or program stops on assertion.
##   Each form of basis-set types equals operator of library on whole multivectors, at each named
##     type and at pairs of types that `DIMENSIONS_SWEPT` sets. Each form compiles: one that
##     reaches no basis returns type of no bases, which widens to zero, as library gives there.
##     Its type holds exactly bases its table reaches, and each named alias returns that type.
##   Scaling, norms, unitizing and operators built from others hold alike, and each alias that
##     takes any type forwards to its operator, in value and type.
##   Each named basis-set type holds its coefficients unpadded, aligned to `alignment` of its
##     count, which stops at 16 bytes.
##   Samples narrow multivector of library to each type, so laws reach no private field.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[algorithm, macros, random, sequtils, strformat, strutils, tables]

import pga
import pga/multivectors {.all.}  # Private `alignment`, which laws hold.


const
  SAMPLES = 256  ## Seeded samples each law is checked on.
  SEED = 0  ## Seed of sample generator, so every run checks same samples.
  DIMENSIONS_SWEPT = 5
    ## Highest dimension laws hold each product at every pair of types at; past it, vector pairs
    ##   with each type, either side. Every pair at cga6d builds and runs in 18 minutes, peaking
    ##   at 6 106 MiB; vector pairs there take 2 minutes and 1 196 MiB.
  ALIGNMENTS_NAMED = [(3, 8), (4, 16), (5, 8), (6, 16), (8, 16), (10, 16), (16, 16)]
    ## Count of coefficients of each named basis-set type, rga3d to cga5d, aligned at 64 bits.
  OPERATORS_MAPS = ["∙", "∘", "/", "\\", "~", "~∘", "★", "☆", "⊖", "|∙²", "|∘²"]
    ## Operators of one operand that every algebra builds from one table, squared norms last.
  OPERATORS_MAPS_CONFORMAL = ["■", "□", "⊟", "|■²", "|□²", "|⊘²"]
    ## Operators of one operand that conformal metric adds.
  OPERATORS_NORMS = ["|∙", "|∘", "|", "^∙", "^∘", "^"]
    ## Norms and unitizing of every algebra, each read from squared norm of its form.
  OPERATORS_NORMS_CONFORMAL = ["|■", "|□", "|⊘"]
    ## Norms that conformal metric adds.
  OPERATORS_COMPOSED = when IS_RIGID: @["∩", "∪"] else: @["⊞", "⊙", "⊡"]
    ## Operators that metric builds from others; partner, which reads grade, stands apart.
  OPERATORS_PRODUCTS = ["∧", "∨", "⟑", "⟇", "∙", "∘", "∧★", "∧☆", "∨★", "∨☆"]
    ## Operators of two operands that every algebra builds from one table.
  OPERATORS_SCALED = ["*", "∧"]
    ## Operators of scalar and multivector, which hold scalar on either side.
  ALIASES = [
    ("attitude(m)", "⊖m"), ("complementLeft(m)", "\\m"), ("complementRight(m)", "/m"),
    ("dualBulk(m)", "★m"), ("dualWeight(m)", "☆m"), ("negate(m)", "-m"), ("reverse(m)", "~m"),
    ("reverseAnti(m)", "~∘m"), ("norm(m)", "|m"), ("normalizeBulk(m)", "^∙m"),
    ("normalizeWeight(m)", "^∘m"), ("unitize(m)", "^m"), ("add(m, n)", "m + n"),
    ("add(m, s)", "m + s"), ("add(s, m)", "s + m"), ("subtract(m, n)", "m - n"),
    ("subtract(m, s)", "m - s"), ("subtract(s, m)", "s - m"), ("wedge(m, n)", "m ∧ n"),
    ("wedge(m, s)", "m ∧ s"), ("wedge(s, m)", "s ∧ m"), ("wedgeAnti(m, n)", "m ∨ n"),
    ("wedgeDot(m, n)", "m ⟑ n"), ("wedgeDotAnti(m, n)", "m ⟇ n"), ("dot(m, n)", "m ∙ n"),
    ("dotAnti(m, n)", "m ∘ n"), ("contractBulk(m, n)", "m ∨★ n"),
    ("contractWeight(m, n)", "m ∨☆ n"), ("expandBulk(m, n)", "m ∧★ n"),
    ("expandWeight(m, n)", "m ∧☆ n"), ("projectCentral(m, n)", "n ∨ (m ∧★ n)"),
    ("projectCentralAnti(m, n)", "n ∧ (m ∨★ n)"), ("projectOrthogonal(m, n)", "n ∨ (m ∧☆ n)"),
    ("projectOrthogonalAnti(m, n)", "n ∧ (m ∨☆ n)"),
  ]  ## Call of each alias that takes any type, beside its operator over same operands.
  ALIASES_METRIC =
    when IS_RIGID:
      @[
        ("bulk(m)", "∙m"), ("weight(m)", "∘m"), ("normBulk(m)", "|∙m"), ("normWeight(m)", "|∘m"),
        ("support(m)", "∩m"), ("supportAnti(m)", "∪m"),
      ]
    else:
      @[
        ("bulkRound(m)", "∙m"), ("weightRound(m)", "∘m"), ("bulkFlat(m)", "■m"),
        ("weightFlat(m)", "□m"), ("carrier(m)", "⊟m"), ("carrierCo(m)", "⊞m"),
        ("center(m)", "⊙m"), ("container(m)", "⊡m"), ("partner(m)", "⊛m"),
        ("normBulkRound(m)", "|∙m"), ("normWeightRound(m)", "|∘m"), ("normBulkFlat(m)", "|■m"),
        ("normWeightFlat(m)", "|□m"), ("normRadius(m)", "|⊘m"),
      ]
    ## Call of each alias that metric names, beside its operator.



#[ Laws ]#

func bases[B: static Bases](t: typedesc[MultivectorOf[B]]): Bases = B
  ## Get bases basis-set type holds.


proc sample[B: static Bases](t: typedesc[MultivectorOf[B]]): MultivectorOf[B] =
  ## Sample basis-set type with each coefficient uniform in [-1, 1], narrowed from multivector.
  var m: Multivector
  for basis in B: m[basis] = Coefficient(rand(-1.0..1.0))
  toMultivectorOf[bases(Multivector), B](m)


proc sample(t: typedesc[Coefficient]): Coefficient =
  ## Sample scalar uniform in [-1, 1].
  Coefficient(rand(-1.0..1.0))


func whole[B: static Bases](m: MultivectorOf[B]): Multivector {.inline.} = m.toMultivector
  ## Widen multivector of any type to whole multivector, as library takes it.


func whole(s: Coefficient): Coefficient {.inline.} = s
  ## Keep scalar, as library takes it.


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


func namesGraded(): seq[string] {.compileTime.} =
  ## Name named basis-set type of each grade.
  for grade in Grade.low..Grade.high: result.add "Multivector" & $int(grade)


func namesTyped(): seq[string] {.compileTime.} =
  ## Name each named basis-set type: each grade, then each parity.
  namesGraded() & @["MultivectorEven", "MultivectorOdd"]


func emitHold(operator: string, names: seq[string], held, empty: NimNode): NimNode {.compileTime.} =
  ## Emit law of one form at one type or pair: equal to library on whole operands. Count it held,
  ##   and count it again where its type holds no basis. Name `Coefficient` samples scalar.
  let
    symbol = nnkAccQuoted.newTree(ident(operator))
    message = newLit("Form must equal operator of library at " & operator & " of " &
      names.join(" and ") & ".")
    (kind_m, kind_n) = (ident(names[0]), ident(names[^1]))
    key =
      if names.len == 1: operator & "𝐦"
      elif names[0] == "Coefficient": "s " & operator & " 𝐦"
      elif names[1] == "Coefficient": "𝐦 " & operator & " s"
      else: "𝐦 " & operator & " 𝐧"
  if names.len == 1:
    return quote do:
      `held`.inc `key`
      if card(bases(typeof(`symbol`(sample(`kind_m`))))) == 0: `empty`.inc `key`
      for _ in 1..SAMPLES:
        let m = sample(`kind_m`)
        doAssert `symbol`(m).toMultivector =~ `symbol`(whole(m)).toMultivector, `message`
  quote do:
    `held`.inc `key`
    if card(bases(typeof(`symbol`(sample(`kind_m`), sample(`kind_n`))))) == 0: `empty`.inc `key`
    for _ in 1..SAMPLES:
      let (m, n) = (sample(`kind_m`), sample(`kind_n`))
      doAssert `symbol`(m, n).toMultivector =~ `symbol`(whole(m), whole(n)).toMultivector,
        `message`


macro holdForms(held, empty: CountTable[string]): untyped =
  ## Hold each form to operator of library, at each named type and at pairs of named types and
  ##   whole multivector; count, by operator, instances held and ones that reach no basis.
  ##   Pairs are every pair up to `DIMENSIONS_SWEPT`, and vector with each type past it.
  ##   Two whole multivectors keep operator of library, so no pair holds them both.
  ##   Partner reads grade of its operand, so it holds at each grade alone.
  result = newStmtList()
  let
    names = namesTyped()
    maps = @OPERATORS_MAPS & @OPERATORS_NORMS & OPERATORS_COMPOSED & (
      if IS_CONFORMAL: @OPERATORS_MAPS_CONFORMAL & @OPERATORS_NORMS_CONFORMAL else: @[])
  for operator in maps:
    for name in names: result.add emitHold(operator, @[name], held, empty)
  if IS_CONFORMAL:
    for name in namesGraded(): result.add emitHold("⊛", @[name], held, empty)
  for operator in OPERATORS_SCALED:
    for name in names:
      result.add emitHold(operator, @["Coefficient", name], held, empty)
      result.add emitHold(operator, @[name, "Coefficient"], held, empty)
  for operator in OPERATORS_PRODUCTS:
    for left in names & "Multivector":
      for right in names & "Multivector":
        if left == right and left == "Multivector": continue
        if DIMENSIONS > DIMENSIONS_SWEPT and "Multivector1" notin [left, right]: continue
        result.add emitHold(operator, @[left, right], held, empty)


macro holdAliases(): untyped =
  ## Hold each alias that takes any type to its operator, in type and value, and to library on
  ##   whole operands. Operand `m` takes each named type, `n` vector and `s` scalar.
  ##   Partner reads grade of its operand, so it holds at each grade alone.
  result = newStmtList()
  for (call, expression) in @ALIASES & ALIASES_METRIC:
    let names = if call == "partner(m)": namesGraded() else: namesTyped()
    for name in names:
      let
        (aliased, forwarded) = (parseExpr(call), parseExpr(expression))
        widened = copyNimTree(aliased)
        message_type = newLit(call & " must return type of its operator at " & name & ".")
        message_value = newLit(call & " must forward to its operator at " & name & ".")
        message_whole = newLit(call & " must equal library on whole operands at " & name & ".")
      var operands = newNimNode(nnkLetSection)
      for k in 1..<aliased.len:
        let
          operand = aliased[k].strVal
          kind =
            case operand
            of "m": ident(name)
            of "n": ident("Multivector1")
            else: ident("Coefficient")
        widened[k] = newCall(ident("whole"), ident(operand))
        operands.add newIdentDefs(ident(operand), newEmptyNode(), newCall(ident("sample"), kind))
      result.add quote do:
        block:
          `operands`
          doAssert typeof(`aliased`) is typeof(`forwarded`), `message_type`
          doAssert `aliased`.toMultivector =~ `forwarded`.toMultivector, `message_value`
          doAssert `aliased`.toMultivector =~ `widened`.toMultivector, `message_whole`


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


macro holdTypesKept(): untyped =
  ## Hold type of each operation that keeps type of its operand: scaling, either side, and each
  ##   unitizing. Hold each norm to scalar and antiscalar, as library gives it.
  result = newStmtList()
  for name in namesTyped():
    let kind = ident(name)
    result.add quote do:
      doAssert typeof(sample(Coefficient) * sample(`kind`)) is `kind` and
          typeof(sample(`kind`) * sample(Coefficient)) is `kind` and
          typeof(sample(Coefficient) ∧ sample(`kind`)) is `kind` and
          typeof(sample(`kind`) ∧ sample(Coefficient)) is `kind`,
        "Scaling must keep type of " & `name` & "."
      doAssert typeof(^∙sample(`kind`)) is `kind` and typeof(^∘sample(`kind`)) is `kind` and
          typeof(^sample(`kind`)) is `kind`,
        "Unitizing must keep type of " & `name` & "."
      doAssert typeof(|∙sample(`kind`)) is MultivectorScalars and
          typeof(|∘sample(`kind`)) is MultivectorScalars and
          typeof(|sample(`kind`)) is MultivectorScalars,
        "Norm must give scalar and antiscalar at " & `name` & ", as library does."


proc holdAlignment() =
  ## Hold alignment of every count of coefficients, then of each count named types reach.
  doAssert alignment(0) == sizeof(Coefficient), "Empty set must keep alignment of coefficient."
  for count in 1..64:
    let (size, aligned) = (sizeof(Coefficient) * count, alignment(count))
    doAssert aligned in [4, 8, 16], &"Alignment must be power of two to 16; got `{aligned}`."
    doAssert size mod aligned == 0, &"Alignment must pad no count; got `{aligned}` at `{count}`."
    doAssert aligned == 16 or size mod (2 * aligned) != 0,
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
    none = top ∧ top
  doAssert alignof(typeof(p ∧ m)) == alignment(card(bases(typeof(p ∧ m)))),
    "Type product returns must align by same rule as named ones."
  doAssert (p ∧ q) is Multivector2, "Vector wedge vector must be bivector, equal to its alias."
  doAssert ($typeof(p ∧ q)).startsWith("MultivectorOf[{"),
    "Alias must add no type, so type prints as generic with its bases."
  echo "basis-set-forms: vector wedge vector prints as ", $typeof(p ∧ q)
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
  echo "basis-set-forms: bytes of p ∙ m ", sizeof(p ∙ m), ", p ∘ m ", sizeof(p ∘ m),
    ", ∙ bivector ", sizeof(∙bivector), ", ∘ vector ", sizeof(∘p), ", ∙ whole ", sizeof(∙m),
    ", sandwich ", sizeof((even ⟇ p) ⟇ even), ", no basis ", sizeof(none), ", library ",
    sizeof(Multivector)
  echo "basis-set-forms: bytes of ‖p‖∙² ", sizeof(`|∙²`(p)), ", / p ", sizeof(/p), ", ★ p ",
    sizeof(★p), ", ☆ p ", sizeof(☆p), ", p ⟑ q ", sizeof(p ⟑ q)
  # Bivectors hold no bulk at rga2d, where grade 2 is antiscalar, nor at cga3d.
  doAssert bases(typeof(∙bivector)) < bases(Multivector2), "Bulk of bivector must be part of grade."
  when IS_RIGID:
    doAssert bases(typeof(∙bivector)) + bases(typeof(∘bivector)) == bases(Multivector2),
      "Bulk and weight of bivector must cover its grade, under rigid metric."
  doAssert card(bases(typeof(none))) == 0,
    "Product that reaches no basis must take type of no bases."
  doAssert none.toMultivector =~ Coefficient(0), "Type of no bases must widen to zero."
  doAssert card(bases(typeof(none ∧ p))) == 0 and card(bases(typeof(∙none))) == 0,
    "Form of type of no bases must reach no basis again."
  doAssert (none + p) is Multivector1 and (p - none) is Multivector1,
    "Sum with type of no bases must keep type of other operand."
  doAssert (none + p).toMultivector =~ p.toMultivector and
      (p - none).toMultivector =~ p.toMultivector,
    "Sum with type of no bases must keep value of other operand."
  doAssert not compiles(p[Basis.scalar]),
    "Static basis outside bases of type must stop compile, so product reads fixed indexes alone."
  doAssert wedge(p, q).toMultivector =~ (p ∧ q).toMultivector, "Alias must forward to operator."
  doAssert `|∙²`(p) is Multivector0, "Bulk squared norm of vector must be one scalar."
  doAssert sizeof(`|∙²`(p)) == sizeof(Coefficient) and sizeof(`|∘²`(p)) == sizeof(Coefficient),
    "Squared norm of vector must write one coefficient, never whole multivector."
  doAssert `|∙²`(m) is Multivector, "Squared norm of whole multivector must stay library's."
  when IS_RIGID:
    doAssert card(bases(typeof(★top))) == 0,
      "Bulk dual of antiscalar reaches no basis, so it must take type of no bases."
  holdTypesGraded()
  holdTypesKept()
  holdAliases()
  var held, empty: CountTable[string]
  holdForms(held, empty)
  echo "basis-set-forms: forms hold at ", toSeq(held.values).foldl(a + b), " types and pairs, ",
    toSeq(empty.values).foldl(a + b, 0), " of them with no basis, each zero in library"
  echo "basis-set-forms: no basis by operator ",
    toSeq(empty.keys).sorted.mapIt(it & " " & $empty[it]).join(", ")
  for _ in 1..SAMPLES:
    let
      (a, b, c) = (sample(Multivector1), sample(Multivector2), sample(Multivector1))
      (u, v) = (sample(MultivectorOdd), sample(Multivector))
      motor = sample(MultivectorEven)
    doAssert (a ∧ c).toMultivector =~ (a.toMultivector ∧ c.toMultivector),
      &"Wedge must equal library's; got `{(a ∧ c).toMultivector}`."
    doAssert (a ∧ b).toMultivector =~ (a.toMultivector ∧ b.toMultivector),
      &"Wedge must equal library's; got `{(a ∧ b).toMultivector}`."
    doAssert ((motor ⟇ a) ⟇ motor).toMultivector =~
        ((motor.toMultivector ⟇ a.toMultivector) ⟇ motor.toMultivector),
      &"Antiproduct must equal library's; got `{((motor ⟇ a) ⟇ motor).toMultivector}`."
    doAssert (u ∙ v).toMultivector =~ (u.toMultivector ∙ v.toMultivector),
      &"Dot must equal library's; got `{(u ∙ v).toMultivector}`."
    doAssert (u ∘ v).toMultivector =~ (u.toMultivector ∘ v.toMultivector),
      &"Antidot must equal library's; got `{(u ∘ v).toMultivector}`."
    doAssert (∙b).toMultivector =~ ∙b.toMultivector,
      &"Bulk must equal library's; got `{(∙b).toMultivector}`."
    doAssert (∘b).toMultivector =~ ∘b.toMultivector,
      &"Weight must equal library's; got `{(∘b).toMultivector}`."
  echo "basis-set-forms: laws hold at ", DIMENSIONS, "D, conformal ", IS_CONFORMAL
  0


when isMainModule:
  quit main()
