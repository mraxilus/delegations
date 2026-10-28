## Replicate laws of `pga_benchmark` under one algebra; stubs beside this file pick which.
##   Every stub names its algebra on its `matrix:` line, so `nim.cfg`'s default never
##   decides what ran. Library sources are read at compile time from Atlas checkout, so
##   catalogue is held to what library exports rather than to what this project remembers.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/[
  algorithm, compilesettings, json, macros, options, os, sequtils, strutils, tables, unittest,
]
from std/unicode import runeLen

import ../src/pga_benchmark
import ../src/pga_benchmark/[
  bound, cells, changes, definitions, dense, gaps, guard, head, inspector, markdown,
  measurements, model, notes, proposals, report, trace,
]
import ../src/pga_benchmark/pages/[
  completion, docket, evaluation, home, listing, proposal, render, search, shell,
]
from ../src/pga_benchmark/evaluations import
  ENTRY_LIBRARY, algebrasEvaluated, digestEdits, functionsChanged, compareNan, readLibrary,
  compileCost, pairTimes
from ../src/pga_benchmark/machine import entries
from ../src/pga_benchmark/unitized import nil


template suiteInProc(name: static string, body: untyped) =
  ## Run suite in proc of its own, so C of each suite is function of its own.
  ##   `suite` writes each test into function that runs module; that one function of every test
  ##     took gcc 31 s and count of its multiplies 51 s at rga4d, measured 2026-10-19.
  proc run() {.gensym.} =
    suite name:
      body
  run()


const
  LIBRARY =
    "../dependencies/replications.mraxilus.gitlab.com/lengyel/projective_geometric_algebra_illuminated"
    ## Library checkout Atlas restores, relative to this file.
  SOURCE_UMBRELLA = staticRead(LIBRARY & "/pga.nim")  ## Library umbrella, holding named aliases.
  FLOOR_FUNCTIONS_REFERENCE =
    when DIMENSIONS == 4 and IS_RIGID: 73
    elif DIMENSIONS == 5 and IS_CONFORMAL: 84
    elif DIMENSIONS == 3 and IS_RIGID: 50
    elif DIMENSIONS == 4 and IS_CONFORMAL: 66
    else: 1
    ## Reference functions own nimcache holds at pin, which optimality law must read.
    ##   Fewer means guard skips one, or reference turned template; either moves floor by choice.
  FLOOR_ROWS_BOUND =
    when DIMENSIONS == 4 and IS_RIGID: 107
    elif DIMENSIONS == 5 and IS_CONFORMAL: 130
    elif DIMENSIONS == 3 and IS_RIGID: 39
    elif DIMENSIONS == 4 and IS_CONFORMAL: 46
    else: 1
    ## Measurands with derived bound and emitted function at pin, which soundness law must read.
  SOURCE_OPERATORS = staticRead(LIBRARY & "/pga/operators.nim")
    ## Library operators, generated and hand-written.
  SOURCE_MULTIVECTORS = staticRead(LIBRARY & "/pga/multivectors.nim")
    ## Library arithmetic and accessors.
  SOURCES_REFERENCE = [
    ("reference/rigid2", staticRead("../src/pga_benchmark/reference/rigid2.nim")),
    ("reference/rigid3", staticRead("../src/pga_benchmark/reference/rigid3.nim")),
    ("reference/conformal2", staticRead("../src/pga_benchmark/reference/conformal2.nim")),
    ("reference/conformal3", staticRead("../src/pga_benchmark/reference/conformal3.nim")),
  ]
    ## Typed reference modules by tail of module path, whose docs state counts of each form.
  SYMBOLS_EXCLUDED = ["==", "=~", "$", "*"]
    ## Exported symbols catalogue leaves out on purpose.
    ##   Poisoned equality, approximate comparison and display are predicates or text.
    ##   `*` is template forwarding to scalar `∧`, which catalogue measures once as `scale`.


macro defineChecksCompile(measurands: static seq[Measurand]): untyped =
  ## Define one `check compiles(expression)` per measurand, with `m` and `n` bound by operand kind.
  ##   Kinds without typed reference yet bind to library's own multivector.
  result = newStmtList()
  let (m, n) = (ident"m", ident"n")  # plain idents, so expression's own `m` and `n` bind
  for p in measurands:
    let
      expression = parseExpr(p.expression)
      kind_m = if p.operands[0] == Kind.Scalar: ident"float" else: ident"Multivector"
      kind_n = if p.operands[1] == Kind.Scalar: ident"float" else: ident"Multivector"
      id = newLit(p.id)
    result.add quote do:
      block:
        var
          `m` {.used.}: `kind_m`  # Read by `expression` of measurand.
          `n` {.used.}: `kind_n`  # Read by `expression` of binary measurand; unary leaves it.
        check compiles(`expression`)  # expression of `id` parses and resolves against library
        check `id`.len > 0  # id names gap


func isCitedUnder(cite, section: string): bool =
  ## Decide whether cite falls under section: chapter `2.` holds its equations, page holds itself.
  cite == section or (section.endsWith(".") and cite.startsWith(section))


proc emitTestsReference(measurands: seq[Measurand], section: string): NimNode {.compileTime.} =
  ## Build one test per typed measurand cited under section, holding library to reference.
  ##   Operands pair pool element i with element j = (7i + 3) mod OBJECTS, so pairs vary.
  result = newStmtList()
  let (m, n) = (ident"m", ident"n")  # plain idents, so expression and reference bind them
  for p in measurands:
    if p.reference.len == 0 or not p.cite.isCitedUnder(section): continue
    let
      expression = parseExpr(p.expression)
      reference = parseExpr(p.reference)
      m_library = parseExpr(namePoolLibrary(p.operands[0], p.grade))
      n_library = parseExpr(namePoolLibrary(p.operands[1], p.grade))
      m_reference = parseExpr(namePoolReference(p.operands[0]))
      n_reference = parseExpr(namePoolReference(p.operands[1]))
      name = newLit(p.id & "  # " & p.cite)
    result.add quote do:
      test `name`:
        for i in 0..<OBJECTS:
          let
            j = (i * 7 + 3) mod OBJECTS
            expected = block:
              let
                `m` {.used.} = `m_reference`[i]  # Read by `reference`.
                `n` {.used.} = `n_reference`[j]  # Read by binary `reference`; unary leaves it.
              widen(`reference`)
            got = block:
              let
                `m` {.used.} = `m_library`[i]  # Read by `expression`.
                `n` {.used.} = `n_library`[j]  # Read by binary `expression`; unary leaves it.
              `expression`
          check widen(got) =~ expected  # library on images equals reference embedded


proc emitTestSkipped(): NimNode {.compileTime.} =
  ## Build placeholder test that skips where algebra carries no typed reference (Article IX.9).
  quote do:
    test "typed reference, which this algebra lacks":
      skip()


macro checkReferences(measurands: static seq[Measurand], section: static string): untyped =
  ## Emit tests of typed measurands cited under section, or one skipped test where none is.
  result = emitTestsReference(measurands, section)
  if result.len == 0: result.add emitTestSkipped()


macro checkReferencesWiki(measurands: static seq[Measurand]): untyped =
  ## Emit one suite per wiki page typed measurands cite, named `Wiki: <page>`.
  ##   Pages are those of rigidgeometricalgebra.org or conformalgeometricalgebra.org, by algebra.
  ##   One suite of one skipped test stands where algebra carries no typed reference.
  result = newStmtList()
  var pages: seq[string]
  for p in measurands:
    if p.reference.len > 0 and p.cite.startsWith("wiki:") and p.cite notin pages:
      pages.add p.cite
  for page in pages:
    let
      name = newLit("Wiki: " & page["wiki:".len .. ^1].replace('_', ' '))
      tests = emitTestsReference(measurands, page)
    result.add quote do:
      suite `name`:
        `tests`
  if pages.len == 0:
    let tests = emitTestSkipped()
    result.add quote do:
      suite "Wiki":
        `tests`


macro checkTransformsAnyNorm(measurands: static seq[Measurand]): untyped =
  ## Emit suite holding each motor transform of typed reference to library at motor scaled by 2.
  ##   Scaled motor has norm 2, so transform taking motor as unit misses factor 4 of operation.
  ##   One skipped test stands where algebra carries no transform.
  var tests = newStmtList()
  let (m, n) = (ident"m", ident"n")  # plain idents, so expression and reference bind them
  for p in measurands:
    if not p.reference.startsWith("transform("): continue
    let
      expression = parseExpr(p.expression)
      reference = parseExpr(p.reference)
      m_library = parseExpr(namePoolLibrary(p.operands[0], p.grade))
      n_library = parseExpr(namePoolLibrary(p.operands[1], p.grade))
      m_reference = parseExpr(namePoolReference(p.operands[0]))
      n_reference = parseExpr(namePoolReference(p.operands[1]))
      name = newLit(p.id & " at motor scaled by 2  # " & p.cite)
    tests.add quote do:
      test `name`:
        for i in 0..<OBJECTS:
          let
            j = (i * 7 + 3) mod OBJECTS
            expected = block:
              let
                `m` = `m_reference`[i]
                `n` = toMotor(2.0 * widen(`n_reference`[j]))
              widen(`reference`)
            got = block:
              let
                `m` = `m_library`[i]
                `n` = 2.0 * `n_library`[j]
              `expression`
          check widen(got) =~ expected  # library and reference agree at motor of norm 2
  if tests.len == 0: tests.add emitTestSkipped()
  result = quote do:
    suiteInProc "Reference: Motor of any norm":
      `tests`


func isNear[B: static Bases](got, expected: MultivectorOf[B]): bool =
  ## Decide whether two multivectors over one set of bases agree, as library's comparison decides.
  got =~ expected


func isNear(got, expected: float): bool =
  ## Decide whether two scalars agree within library's tolerance.
  abs(got - expected) <= TOLERANCE_ABS * max(1.0, max(abs(got), abs(expected)))


func isNear[T: object](got, expected: T): bool =
  ## Decide whether every field of two objects of one type agrees within library's tolerance.
  result = true
  for field_got, field_expected in fields(got, expected):
    result = result and isNear(field_got, field_expected)


macro checkFormsDense(measurands: static seq[Measurand]): untyped =
  ## Emit one test per general measurand holding its dense form to library expression.
  ##   Operands pair pool element i with element j = (7i + 3) mod OBJECTS, as chapters do; NaN
  ##   where library returns NaN is equality too, since conformal norms return it.
  result = newStmtList()
  let (m, n) = (ident"m", ident"n")  # plain idents, so expression and dense form bind them
  for p in measurands:
    if p.reference.len > 0: continue
    let
      expression = parseExpr(p.expression)
      dense =
        if p.arity == 2: newCall(ident(p.nameDense), m, n)
        else: newCall(ident(p.nameDense), m)
      pool_m = parseExpr(namePoolLibrary(p.operands[0], p.grade))
      pool_n = parseExpr(namePoolLibrary(p.operands[1], p.grade))
      name = newLit(p.id)
    result.add quote do:
      test `name`:
        for i in 0..<OBJECTS:
          let
            j = (i * 7 + 3) mod OBJECTS
            (expected, got) = block:
              let
                `m` {.used.} = `pool_m`[i]  # Read by `expression` and `dense`.
                `n` {.used.} = `pool_n`[j]  # Read by binary `expression` and `dense` alone.
              (`expression`, `dense`)
          check isAnyNan(got) == isAnyNan(expected)  # NaN exactly where library returns it
          if not isAnyNan(expected): check isNear(got, expected)  # dense form equals library


fillPools(0)



suiteInProc "Internal: Configuration":
  test "stub matrix names algebra umbrella reports":
    check DIMENSIONS in 2..6  # library's own bound
    when DIMENSIONS == 4 and IS_RIGID:
      check NAME_ALGEBRA == "rga4d"  # 3D Euclidean rigid, default of nim.cfg
    when DIMENSIONS == 5 and IS_CONFORMAL:
      check NAME_ALGEBRA == "cga5d"  # 3D Euclidean conformal
    when DIMENSIONS == 3 and IS_RIGID:
      check NAME_ALGEBRA == "rga3d"  # 2D Euclidean rigid
    when DIMENSIONS == 4 and IS_CONFORMAL:
      check NAME_ALGEBRA == "cga4d"  # 2D Euclidean conformal



suiteInProc "Internal: Surface":
  test "symbols are read under gate of their algebra":
    const fixture = """
defineOperator(
  symbols = "∧",
  docs = "x",
)
when IS_RIGID:
  defineOperator(
    symbols = "∩",
  )
  func `∪`*(m: Multivector): Multivector = m
else:
  defineOperator(
    symbols = "■",
  )
when IS_CONFORMAL:
  func `⊟`*(m: Multivector): Multivector = m
func `|`*(m: Multivector): Multivector =
  when IS_RIGID:
    result = m
  else:
    result = m
template `^`*(m: Multivector): Multivector = m
# symbols = "∨∧★∘" stays comment
"""
    check symbolsIn(fixture, is_conformal = false) == @["∧", "∩", "∪", "|", "^"]  # rigid gate
    check symbolsIn(fixture, is_conformal = true) == @["∧", "■", "⊟", "|", "^"]  # else gate


  test "aliases are exported plain funcs under gate of their algebra":
    const fixture = """
func selectGrade*(m: Multivector, g: Grade): Multivector {.inline.} = m{g}
when IS_RIGID:
  func bulk*(m: Multivector): Multivector {.inline.} = ∙ m
when IS_CONFORMAL:
  func bulkFlat*(m: Multivector): Multivector {.inline.} = ■ m
func add*(m, n: Multivector): Multivector {.inline.} = m + n
func add*(m: Multivector, s: float): Multivector {.inline.} = s + m
func `∧`*(s: float, m: Multivector): Multivector = m
func hidden(m: Multivector): Multivector = m
"""
    check aliasesIn(fixture, is_conformal = false) == @["selectGrade", "bulk", "add"]  # rigid
    check aliasesIn(fixture, is_conformal = true) == @["selectGrade", "bulkFlat", "add"]  # cga



suiteInProc "Internal: Catalogue":
  test "ids are unique":
    let ids = ids(CATALOGUE) & ids(MISSING)
    check ids.deduplicate.len == ids.len  # one gap per operation


  test "every typed cite falls under chapter 2 or wiki page, so one suite holds it":
    for p in CATALOGUE:
      if p.reference.len == 0: continue
      check p.cite.startsWith("2.") or p.cite.startsWith("wiki:")  # no cite left unheld


  test "every expression compiles against library":
    defineChecksCompile(CATALOGUE)


  test "symbols match every operator library exports":
    let exported = (
      symbolsIn(SOURCE_OPERATORS, IS_CONFORMAL) & symbolsIn(SOURCE_MULTIVECTORS, IS_CONFORMAL)
    ).filterIt(it notin SYMBOLS_EXCLUDED).deduplicate
    check symbols(CATALOGUE).sorted == exported.sorted  # no exported operator unmeasured


  test "inlined names every symbol library spells as template over field read":
    for symbol in INLINED:
      let head = "template `" & symbol & "`*[B: static Bases](m: MultivectorOf[B], b: Basis): "
      check head & "Coefficient =" in SOURCE_MULTIVECTORS  # template, so C carries no function
      check "m.elements[index[B](b)]" in SOURCE_MULTIVECTORS  # body is field read alone


  test "templates name every symbol library spells over another":
    for (symbol, target) in TEMPLATES:
      let line = "template `" & symbol & "`*(m: Multivector): Multivector = " & target & "m"
      check line in SOURCE_OPERATORS  # one-line template, target's function is what C holds


  test "aliases match every name library's umbrella exports":
    let
      exported = aliasesIn(SOURCE_UMBRELLA, IS_CONFORMAL)
      catalogued = (aliases(CATALOGUE) & aliases(MISSING)).deduplicate
    check catalogued.sorted == exported.sorted  # missing ones counted as gaps, not forgotten



suiteInProc "Chapter 2":
  checkReferences(CATALOGUE, "2.")

  test "unitize of point with negative weight keeps its sign  # 2.89":
    when declared(POOL_POINT):
      for p in POOL_POINT:
        var reversed = p
        reversed.w = -p.w  # weight below zero, as meet of operands in reverse order gives
        check widen(unitize(reversed)) =~ ^widen(reversed)  # 2.89, as library unitizes
        check unitize(reversed).w < 0.0  # 2.89, sign of weight kept
    else:
      skip()  # conformal algebras hold no typed point


checkReferencesWiki(CATALOGUE)
checkTransformsAnyNorm(CATALOGUE)



suiteInProc "Internal: Dense forms":
  checkFormsDense(CATALOGUE)



suiteInProc "Internal: Measurements":
  test "every pool starts on cache line":
    # Pool off line puts 128-byte multivector across three lines, not two, and typed object
    #   across lines in other patterns, so library and reference read different layouts.
    template heldToLine(pool: untyped) =
      checkpoint astToStr(pool) & " starts at " & $(cast[uint](addr pool[0]) mod 64)
      check cast[uint](addr pool[0]) mod 64 == 0  # first object starts on line
    heldToLine(POOL_GENERAL)
    heldToLine(POOL_GRADED[0])
    heldToLine(POOL_SCALAR)
    when declared(POOL_POINT):
      heldToLine(POOL_POINT)
      heldToLine(POOL_LINE)
      heldToLine(POOL_MOTOR)
      heldToLine(POOL_POINT_WIDENED)
      heldToLine(POOL_LINE_WIDENED)
      heldToLine(POOL_MOTOR_WIDENED)
    when declared(POOL_PLANE):
      heldToLine(POOL_PLANE)
      heldToLine(POOL_PLANE_WIDENED)
    when declared(POOL_POINTROUND):
      heldToLine(POOL_POINTROUND)
      heldToLine(POOL_DIPOLE)
      heldToLine(POOL_CIRCLE)
      heldToLine(POOL_POINTROUND_WIDENED)
      heldToLine(POOL_DIPOLE_WIDENED)
      heldToLine(POOL_CIRCLE_WIDENED)
    when declared(POOL_SPHERE):
      heldToLine(POOL_SPHERE)
      heldToLine(POOL_SPHERE_WIDENED)


  test "summarise reads median and minimum per object":
    check summarise([300'i64, 100, 200], 100) == (median: 2.0, minimum: 1.0)  # odd count
    check summarise([400'i64, 100, 300, 200], 100) == (median: 2.5, minimum: 1.0)  # even count


  test "timing instrument reads clock and records finite, ordered measurements of every measurand":
    # Instrument reads real clock, as Article IX.12 lets its test do; no limit on time decides.
    measureCatalogue()
    check SINK != 0.0  # results folded, none dead
    for index, measurand in CATALOGUE:
      let measurement = MEASUREMENTS[Implementation.Library][index]
      check measurement.is_measured  # library implementation always has expression
      check measurement.ns_min <= measurement.ns_median  # minimum bounds median
      check MEASUREMENTS[Implementation.Reference][index].is_measured ==
          (measurand.reference.len > 0)  # reference implementation present where written
      check MEASUREMENTS[Implementation.Dense][index].is_measured ==
          (measurand.reference.len == 0)  # dense form present on every general measurand
    check MEASUREMENTS[Implementation.Library].anyIt(it.ns_median > 0.0)  # clock was read


  test "runs combine to median of run medians, least minimum, and each run's median":
    func run(library, reference: float): JsonNode =
      ## Build one run's document: one measurand, both implementations.
      %*{"taken": {"date": "2026-09-30"}, "measurands": {"wedge": {
        "library": {"ns_median": library, "ns_min": library - 1.0, "share_nan": 0.0},
        "reference": {"ns_median": reference, "ns_min": reference - 1.0, "share_nan": 0.0}}}}
    let
      combined = combineRuns([run(12.0, 4.0), run(10.0, 5.0), run(11.0, 3.0)])
      library = combined{"measurands", "wedge", "library"}
    check combined{"taken", "runs"}.getInt == 3  # run count recorded
    check library{"ns_median"}.getFloat == 11.0 and library{"ns_min"}.getFloat == 9.0  # combined
    check library{"ns_runs"} == %*[12.0, 10.0, 11.0]  # run order kept, pairs with reference
    check combined{"measurands", "wedge", "reference", "ns_runs"} == %*[4.0, 5.0, 3.0]  # paired
    check median([4.0, 1.0, 3.0, 2.0]) == 2.5  # even count, mean of middle two



suiteInProc "Internal: Allocation":
  test "allocation gauge is live under this build":
    let before = getAllocStats()
    var control = newSeq[float](8)
    control[0] = 1.0
    let after = getAllocStats()
    check countAllocations(after - before) > 0  # positive control: counter moved
    check control[0] == 1.0  # control kept alive


  test "no measurand allocates in any implementation":
    measureCatalogue()
    for index, measurand in CATALOGUE:
      for it in Implementation:
        let measurement = MEASUREMENTS[it][index]
        if measurement.is_measured:
          check measurement.allocations == 0  # heap untouched over every round



suiteInProc "Internal: Lower bound":
  test "derived counts reproduce what algebra demands":
    let m = Metric(dimensions: 4, is_conformal: false)
    check boundLower(Shape.Wedge, m, 2).multiplies == 81  # three states per dimension
    check boundLower(Shape.Wedge, m, 2).adds == 65  # one add per term past first of each sum
    check boundLower(Shape.Geometric, m, 2).multiplies == 192  # null vector drops one state
    check boundLower(Shape.FormScalar, m, 2).multiplies == 8  # blades carrying metric image
    check boundLower(Shape.ContractBulk, m, 2).multiplies == 54  # 2.119
    check boundLower(Shape.ContractWeight, m, 2).multiplies == 27  # 2.120
    check boundLower(Shape.ExpandBulk, m, 2).multiplies == 27  # wiki:Expansions
    check boundLower(Shape.ExpandWeight, m, 2).multiplies == 54  # wiki:Expansions
    check boundLower(Shape.Scale, m, 2).multiplies == 16  # every coefficient times one scalar
    check boundLower(Shape.Permutation, m, 1).multiplies == 0  # sign and reorder only
    check boundLower(Shape.ProductConstant, m, 1).multiplies == 0  # constant carries unit part


  test "unitize bound is norm, one reciprocal and one scale of each coefficient":
    let
      m = Metric(dimensions: 4, is_conformal: false)
      b = boundLower(Shape.Unitize, m, 1)
    check b.multiplies == 8 + 16  # squared norm, then every coefficient
    check b.divides == 1 and b.roots == 1  # one reciprocal over one root


  test "part norm counts blades of one part, and radius norm counts whole form":
    let
      rigid = Metric(dimensions: 4, is_conformal: false)
      conformal = Metric(dimensions: 5, is_conformal: true)
    check boundLower(Shape.NormPartSquared, rigid, 1).multiplies == 8  # 2.87, bulk of 16
    check boundLower(Shape.NormPartSquared, conformal, 1).multiplies == 8  # Table 4.12
    check boundLower(Shape.NormPart, conformal, 1).roots == 1  # Table 4.12, one root
    check boundLower(Shape.NormSquared, conformal, 1).multiplies == 32  # 4.45, whole antidot
    check boundLower(Shape.Unitize, conformal, 1).multiplies == 8 + 32  # Section 4.3


  test "compound product folds its maps into one table, and bound counts that table":
    let
      rigid = Metric(dimensions: 4, is_conformal: false)
      conformal = Metric(dimensions: 5, is_conformal: true)
    check boundLower(Shape.Support, rigid, 1).multiplies == 54  # wiki:Support
    check boundLower(Shape.SupportAnti, rigid, 1).multiplies == 54  # wiki:Support
    check boundLower(Shape.Center, conformal, 1).multiplies == 162  # wiki:Conformal
    check boundLower(Shape.Container, conformal, 1).multiplies == 162  # wiki:Conformal
    check not boundLower(Shape.Support, rigid, 1).is_chain  # one table, not step sum
    check boundLower(Shape.Support, rigid, 1).bytesMoved == 256  # operand read, result written
    check boundLower(Shape.JoinCarrier, conformal, 2).multiplies == 162  # wiki:Conformal
    let partner = [Shape.Permutation, Shape.Container, Shape.JoinCarrier]
    check boundLowerOfChain(partner, conformal, 1).multiplies == 324  # two folded tables
    check boundLowerOfChain(partner, conformal, 1).is_chain  # sum of steps stays estimate


  test "conformal metric is not singular, so every blade carries image":
    let
      rigid = Metric(dimensions: 4, is_conformal: false)
      conformal = Metric(dimensions: 5, is_conformal: true)
    check rigid.isNull(3) and not rigid.isNull(0)  # last vector of rigid squares to zero
    check not conformal.isNull(4)  # conformal pairs last two off diagonal
    check conformal.termsFormScalar == 32 and rigid.termsFormScalar == 8  # every blade
    check boundLower(Shape.Geometric, conformal, 2).multiplies == 1024  # four states throughout


  test "conformal dual is signed permutation, so dual product keeps every cell of wedge":
    let conformal = Metric(dimensions: 5, is_conformal: true)
    for shape in [Shape.ContractBulk, Shape.ContractWeight, Shape.ExpandBulk,
                  Shape.ExpandWeight]:
      check boundLower(shape, conformal, 2).multiplies == 243  # every blade has image
      check boundLower(shape, conformal, 2).is_derived  # rule holds here too


  test "chain sums its steps, and step with no rule adds nothing":
    let
      rigid = Metric(dimensions: 4, is_conformal: false)
      conformal = Metric(dimensions: 5, is_conformal: true)
      projection = @[Shape.ExpandWeight, Shape.Wedge]
      b = boundLowerOfChain(projection, rigid, 2)
    check b.multiplies == 54 + 81  # dual product, then full product
    check b.is_chain and b.is_derived  # record marks estimate as estimate
    check b.bytesMoved == 128 * 3  # two read, one written, no intermediate
    # Conformal dual product keeps every cell of wedge, so chain is two full products.
    check boundLowerOfChain(projection, conformal, 2).multiplies == 486  # wiki:Expansions
    check boundLowerOfChain([Shape.Unknown], rigid, 1).is_derived == false  # no step, no claim


  test "bound moves operands read once and result written once":
    let m = Metric(dimensions: 4, is_conformal: false)
    check boundLower(Shape.Wedge, m, 2).bytesMoved == 128 * 3  # two read, one written
    check boundLower(Shape.Permutation, m, 1).bytesMoved == 128 * 2  # one read, one written
    check boundLower(Shape.Unknown, m, 2).bytesMoved == 0  # no rule, so no claim


const CACHE = querySetting(SingleValueSetting.nimcacheDir)
  ## Nimcache of this test binary, which inspector suites read back.
let INSPECTED = inspectCache(CACHE, STEMS_MULTIVECTOR)
  ## Read once: walking cache costs seconds, and two suites read same functions.



suiteInProc "Internal: Inspector":
  test "function that runs this module holds no suite, so gcc compiles each suite apart":
    # Case: each `suite` at module level wrote its tests into one C function, 8.1 MB at rga4d;
    #   gcc took 31 s on it, measured 2026-10-19. With each suite in its own proc it holds 0.4 MB.
    var is_found = false
    for f in INSPECTED:
      if f.name == "NimMainModule":
        is_found = true
        check f.body.len < 2_000_000
    check is_found

  test "mangled names demangle to symbols":
    check demangle("XE2X88XA7__u0__OOZdependenciesZpgaZoperators") == "∧"  # non-ASCII bytes
    check demangle("barXE2X88X99__u0__pgaZoperators") == "|∙"  # special word then bytes
    check demangle("roofXE2X88X98__u0__pgaZoperators") == "^∘"  # roof is `^`
    check demangle("tildeXE2X88X98__u0__pgaZoperators") == "~∘"  # tilde is `~`
    check demangle("X7BX7D__u0__probes") == "{}"  # generic instantiated where used
    check demangle("X5BX5D__u1__pgaZmultivectors") == "[]"  # accessor
    check demangle("slash__u0__pgaZoperators") == "/"  # encoded head keeps its underscore
    check demangle("backslash__u0__pgaZoperators") == "\\"  # longest word first
    check demangle("minus__u1__pgaZmultivectors") == "-"  # ASCII operator alone
    check demangle("wedge_u0__referenceZrigid3") == "wedge"  # plain identifier
    check demangle("dualBulk_u1__referenceZrigid3") == "dualBulk"  # overload index stripped
    check demangle("nimZeroMem") == "nimZeroMem"  # no suffix at all
    check overloadIndex("X5BX5D__u1__pgaZmultivectors") == 1  # overload index read back
    check overloadIndex("wedge_u0__referenceZrigid3") == 0
    check overloadIndex("nimZeroMem") == -1  # none


  test "set of enum reads as its stem with no hash, so key holds on every machine":
    # Case: at 3d9696e, `index` formats `set[Basis]`, and key held mangled hash of set type,
    #   which differs between this machine and CI runner, so guard found 24 functions moved.
    const fixture = [
      "N_LIB_PRIVATE N_NIMCALL(NimStringV2, dollar___u0__OOZpgaZmultivectors)(" &
        "tySet_tyEnum_Basis__GwNZjTO9bxGEIf59by1p9aEeA x_p0) {",
      "}",
    ].join("\n")
    let found = functionsIn(fixture)
    check found.len == 1
    if found.len == 1:
      check found[0].parameters == @["set[Basis]"]

  test "functions are split and counted from fixture C":
    const
      multivector_mangled = "tyObject_Multivector__h"
      fixture = [
        "N_LIB_PRIVATE N_NIMCALL(void, XE2X88XA7__u0__OOZpgaZoperators)(" &
        multivector_mangled & "* m_p0, " & multivector_mangled & "* n_p1, " &
        multivector_mangled & "* Result) {",
        "\tNF* T1_;",
        "NF T2_;",
        multivector_mangled & " T3_;",
        "NIM_BOOL* nimErr_;",
        "{",
        "\t\tnimErr_ = nimErrorFlag();",
        "nimZeroMem(((void*) Result), sizeof(" & multivector_mangled & "));",
        "T2_ = X5BX5D__u1__OOZpgaZmultivectors(m_p0, ((tyEnum_Basis__h) 1));",
        "if (NIM_UNLIKELY((*nimErr_))) {",
        "\tgoto BeforeRet_;",
        "}",
        "(*T1_) = ((((NF) T2_) * ((NF) T2_)) + (((NF) T2_) * ((NF) T2_)));",
        "(*T1_) = (((NF) T2_) - ((NF) T2_));",
        "barXE2X88X99__u0__OOZpgaZoperators(m_p0, ((&T3_)));",
        "if (NIM_UNLIKELY((*nimErr_))) {",
        "\tgoto BeforeRet_;",
        "}",
        "}",
        "\tBeforeRet_: ;",
        "}",
        "",
        "static N_INLINE(NF, dot_u0__referenceZrigid3)(tyObject_Vector3__h* a_p0, " &
        "tyObject_Vector3__h* b_p1) {",
        "\tNF result;",
        "result = ((((NF) (*a_p0).x) * ((NF) (*b_p1).x)) + (((NF) (*a_p0).y) * ((NF) (*b_p1).y)));",
        "\treturn result;",
        "}",
        "",
        "N_LIB_PRIVATE N_NIMCALL(void, declared__u0__mod)(" &
        multivector_mangled & "* m_p0, " & multivector_mangled & "* Result);",
      ].join("\n") & "\n"
    let functions = functionsIn(fixture)
    check functions.len == 2  # declaration ending in `;` skipped
    check functions[0].symbol == "∧"  # head demangled
    check functions[0].parameters == @["Multivector", "Multivector"]  # stems in order
    check functions[0].stem_result == "Multivector" and not functions[0].is_inline  # via Result
    check functions[0].module == "OOZpgaZoperators"  # suffix after last `__`
    let c = count(functions[0].body)
    check c.multiplies == 2 and c.adds == 1 and c.subtractions == 1 and c.divides == 0  # as spelled
    check c.fills_zero == 1 and c.intermediates == 1 and c.checks == 2  # fills, locals, branches
    check c.calls == 1  # norm call counted, accessor read not
    check functions[1].symbol == "dot"  # second declaration
    check functions[1].parameters == @["Vector3", "Vector3"]  # both parameters
    check functions[1].stem_result == "float" and functions[1].is_inline  # via return type
    check count(functions[1].body).multiplies == 2  # inline body counted alike
    check functions[0].key == "∧(Multivector,Multivector)"  # key spells stems


  test "definition marked noinline reads as function":
    let functions = functionsIn(
      [
        "N_LIB_PRIVATE N_NOINLINE(void, measure0Library_u0__m)(void);",
        "N_LIB_PRIVATE N_NOINLINE(void, measure0Library_u0__m)(void) {",
        "\tT1_ = getMonoTime_u0__stdZmonotimes();",
        "}",
      ].join("\n") & "\n",
    )
    check functions.len == 1  # declaration skipped, definition read
    check functions[0].name == "measure0Library_u0__m" and not functions[0].is_inline  # head
    check "getMonoTime" in functions[0].body  # body runs to its closing brace


  test "terms inside loops of constant bound count once per trip":
    const
      multivector_mangled = "tyObject_Multivector__h"
      loop = [
        "N_LIB_PRIVATE N_NIMCALL(void, scale__u0__OOZpgaZops)(NF s_p0, " &
        multivector_mangled & "* m_p1, " & multivector_mangled & "* Result) {",
        "NI i_1;",
        "NI res_1;",
        "i_1 = ((NI) 0);",
        "{",
        "\twhile (1) {",
        "\tNF T3_;",
        "if ((!((i_1 < ((NI) 16))))) {",
        "\tgoto LA7;",
        "}",
        "T3_ = (((NF) (*m_p1).data[i_1]) * ((NF) s_p0));",
        "(*Result).data[i_1] = (((NF) T3_) + ((NF) 1.0));",
        "halve__u0__OOZpgaZops(((&(*Result).data[i_1])));",
        "i_1 += ((NI) 1);",
        "}",
        "LA7: ;",
        "}",
        "res_1 = ((NI) 0);",
        "{",
        "\twhile (1) {",
        "if ((!((res_1 <= ((NI) 3))))) {",
        "\tgoto LA9;",
        "}",
        "{",
        "\tNI j_1;",
        "j_1 = ((NI) 0);",
        "\twhile (1) {",
        "if ((!((j_1 < ((NI) 4))))) {",
        "\tgoto LA11;",
        "}",
        "(*Result).data[j_1] = (((NF) (*m_p1).data[j_1]) - ((NF) s_p0));",
        "j_1 += ((NI) 1);",
        "}",
        "LA11: ;",
        "}",
        "res_1 += ((NI) 1);",
        "}",
        "LA9: ;",
        "}",
        "{",
        "\twhile (1) {",
        "if ((!((i_1 < L_1)))) {",
        "\tgoto LA13;",
        "}",
        "(*Result).data[0] = (((NF) s_p0) * ((NF) s_p0));",
        "i_1 += ((NI) 1);",
        "}",
        "LA13: ;",
        "}",
        "}",
        "",
        "static N_INLINE(void, halve__u0__OOZpgaZops)(NF* x_p0) {",
        "(*x_p0) = (((NF) (*x_p0)) * ((NF) 0.5));",
        "}",
      ].join("\n") & "\n"
    let
      functions = functionsIn(loop)
      c = count(functions[0].body)
    check c.multiplies == 16 + 1  # 16-trip loop counts its term sixteen times; unknown bound once
    check c.adds == 16  # every term inside loop is weighted
    check c.subtractions == 4 * 4  # nested loops multiply: `<= 3` from 0 is four trips, `< 4` four
    check c.calls == 16 and c.lines == 48  # call site per trip; lines stay static
    check totals(functions)["scale__u0__OOZpgaZops"].multiplies == 17 + 16  # callee per trip


  test "divisions count as terms, once per trip, and fold from callees":
    const
      multivector_mangled = "tyObject_Multivector__h"
      divide = [
        "N_LIB_PRIVATE N_NIMCALL(void, unit__u0__OOZpgaZops)(" &
        multivector_mangled & "* m_p0, " & multivector_mangled & "* Result) {",
        "NF n_1;",
        "NI i_1;",
        "n_1 = (((NF) 1.0) / ((NF) (*m_p0).data[0]));",
        "i_1 = ((NI) 0);",
        "{",
        "\twhile (1) {",
        "if ((!((i_1 < ((NI) 4))))) {",
        "\tgoto LA7;",
        "}",
        "slasheq__u0__system(((&(*Result).data[i_1])), n_1);",
        "i_1 += ((NI) 1);",
        "}",
        "LA7: ;",
        "}",
        "}",
        "",
        "static N_INLINE(void, slasheq__u0__system)(NF* x_p0, NF y_p1) {",
        "(*x_p0) = (((NF) (*x_p0)) / ((NF) y_p1));",
        "}",
      ].join("\n") & "\n"
    let functions = functionsIn(divide)
    check count(functions[0].body).divides == 1  # reciprocal outside loop, once
    check count(functions[1].body).divides == 1  # callee's own division
    check totals(functions)["unit__u0__OOZpgaZops"].divides == 1 + 4  # folded once per trip
    check count(functions[0].body).multiplies == 0  # division is not multiply


  test "totals fold callees per call site":
    const fixture = """
N_NIMCALL(void, outer__u0__m)(tyObject_Multivector__h* m_p0, tyObject_Multivector__h* Result) {
inner__u0__m(m_p0, Result);
inner__u0__m(m_p0, Result);
}

N_NIMCALL(void, inner__u0__m)(tyObject_Multivector__h* m_p0, tyObject_Multivector__h* Result) {
(*Result) = (((NF) 1.0) * ((NF) 2.0));
}
"""
    let totals = totals(functionsIn(fixture))
    check totals["inner__u0__m"].multiplies == 1  # own
    check totals["outer__u0__m"].multiplies == 2 and totals["outer__u0__m"].calls == 2  # twice
    let rooted = totals(functionsIn(fixture), ["outer__u0__m"])
    check rooted["outer__u0__m"] == totals["outer__u0__m"]  # fold from root agrees with whole
    check "inner__u0__m" notin rooted  # callee counted, never reported unasked


  test "movement models bytes from stems and counts":
    let f = FunctionC(
      symbol: "∧",
      parameters: @["Multivector", "Multivector"],
      stem_result: "Multivector",
    )
    let m = movement(f, Counts(fills_zero: 1, intermediates: 2, copies: 1), 128)
    check m.bytes_read == 256 and m.bytes_written == 128  # two in, one out
    check m.bytes_zeroed == 128 and m.bytes_copied == 128  # one width each
    check m.bytes_intermediates == 256  # two locals, one width each
    check m.bytes_moved == 896  # sum of every cause
    check sizeOfStem("Point", 128) == 32 and sizeOfStem("float", 128) == 8  # typed sizes
    check sizeOfStem("Unknown", 128) == 0  # unknown stems add nothing
    check sizeOfStem("Point", 64, "referenceZrigid2") == 24  # 2D point, not 3D one
    check sizeOfStem("Circle", 128, "referenceZconformal2") == 32  # 2D circle, not 3D one


  test "no lower bound outruns what library spends on same operation":
    let metric = Metric(dimensions: DIMENSIONS, is_conformal: IS_CONFORMAL)
    # Fold only functions law reads: folding whole cache walks every call graph of
    #   unittest itself, which costs minutes (Article IX.8).
    var roots: seq[string]
    for f in INSPECTED:
      for p in CATALOGUE:
        if f.symbol == p.headEmitted and f.name notin roots: roots.add f.name
    let total = totals(INSPECTED, roots)
    var
      rows_derived = 0
      rows_compared = 0
    for p in CATALOGUE:
      let head = p.headEmitted
      if head.len == 0 or head in INLINED: continue
      let b = p.boundLower(metric)
      if not b.is_derived: continue
      inc rows_derived
      var is_compared = false
      # Operator carrying scalar overload spells same symbol at same arity, so stems of
      #   parameters are what tells two apart.
      var operands_dense, operands_scalar = 0
      for i in 0..<int(p.arity):
        if p.operands[i] == Kind.Scalar: inc operands_scalar else: inc operands_dense
      for f in INSPECTED:
        if f.symbol != head: continue
        var dense, scalar = 0
        for stem in f.parameters:
          if stem == "Multivector": inc dense elif stem == "float": inc scalar
        if dense != operands_dense or scalar != operands_scalar: continue
        # Bound is what algebra demands, so library meets it and never beats it. Totals
        #   fold callees, since bound of chain counts arithmetic wherever it is spent.
        check b.multiplies <= total[f.name].multiplies  # derivation is sound
        is_compared = true
      if is_compared: inc rows_compared
    check rows_derived >= FLOOR_ROWS_BOUND  # guard skips no derived bound
    check rows_compared == rows_derived  # every derived bound meets its library function


  test "dense form spends multivector lower bound, and moves only operands and result":
    let metric = Metric(dimensions: DIMENSIONS, is_conformal: IS_CONFORMAL)
    var roots: seq[string]
    for f in INSPECTED:
      if f.symbol.startsWith("dense"): roots.add f.name
    let total = totals(INSPECTED, roots)
    var compared = 0
    for p in CATALOGUE:
      if p.reference.len > 0: continue
      let b = p.boundLower(metric)
      for f in INSPECTED:
        if f.symbol != p.nameDense: continue
        let counts = total[f.name]
        checkpoint p.id & " spends " & $counts.multiplies & " against " & $b.multiplies
        if b.is_derived and b.is_chain:
          # Chain bound sums steps over dense operands; step reading zeros of one before it
          #   spends less, so dense form may stand below estimate and never above it.
          check counts.multiplies <= b.multiplies  # chain at or below its estimate
        elif b.is_derived:
          check counts.multiplies == b.multiplies  # one rule, met exactly
        check counts.fills_zero == 0 and counts.intermediates == 0  # no fill, no local
        check counts.copies == 0 and counts.calls == 0 and counts.checks == 0  # straight line
        inc compared
        break
    check compared == CATALOGUE.countIt(it.reference.len == 0)  # every general row has one


  test "typed reference spends no fill, no copy and no error check, so it is optimal code":
    if not CATALOGUE.anyIt(it.reference.len > 0):
      echo "    typed reference exists at rga3d, rga4d, cga4d and cga5d alone, so law skips (IX.9)"
      skip()
    else:
      var compared = 0
      for f in INSPECTED:
        if not f.module.tailModule.startsWith("reference/"): continue
        let counts = count(f.body)
        checkpoint f.key & " fills " & $counts.fills_zero & ", copies " & $counts.copies &
            ", checks " & $counts.checks
        # Call to Nim function costs fill of its result and check of error flag after it,
        #   so form shared with another function is spelled in place. Result built in
        #   temporary and copied whole is written twice, so form writes it once from scalars.
        check counts.fills_zero == 0 and counts.copies == 0 and counts.checks == 0  # as hand code
        inc compared
      check compared >= FLOOR_FUNCTIONS_REFERENCE  # guard skips no reference function

  test "doc of each typed reference form states multiplies, adds and divides its C spends":
    func countsStated(source: string): Table[string, array[3, int]] =
      ## Read multiplies, adds with subtractions, and divides each form's doc states, keyed as
      ##   inspector keys its C, e.g. `wedge(Point,Point)`.
      var key = ""
      for line in source.splitLines:
        if line.startsWith("func ") and "*(" in line:
          let params = line[line.find("*(") + 2 ..< line.find("):")]
          var names, stems: seq[string]
          for part in params.split(", "):
            let at = part.find(": ")
            names.add(if at < 0: part else: part[0 ..< at])
            if at >= 0:
              for _ in names: stems.add part[at + 2 .. ^1]
              names.setLen 0
          key = line["func ".len ..< line.find("*(")] & "(" & stems.join(",") & ")"
          result[key] = [0, 0, 0]
        elif key.len > 0 and line.startsWith("  ##"):
          let words = line.splitWhitespace
          for i in 1 ..< words.len:
            if not words[i - 1].allCharsInSet(Digits): continue
            case words[i].strip(chars = {',', '.', ';'})
            of "mul": result[key][0] += words[i - 1].parseInt
            of "add", "sub": result[key][1] += words[i - 1].parseInt
            of "div": result[key][2] += words[i - 1].parseInt
            else: discard
        else:
          key = ""

    if not CATALOGUE.anyIt(it.reference.len > 0):
      echo "    typed reference exists at rga3d, rga4d, cga4d and cga5d alone, so law skips (IX.9)"
      skip()
    else:
      var
        stated: Table[string, array[3, int]]
        compared = 0
      for (module, source) in SOURCES_REFERENCE:
        for key, counts in source.countsStated: stated[module & " " & key] = counts
      for f in INSPECTED:
        let module = f.module.tailModule
        if not module.startsWith("reference/"): continue
        let
          counts = count(f.body)
          spent = [counts.multiplies, counts.adds + counts.subtractions, counts.divides]
        checkpoint f.key & " states " & $stated.getOrDefault(module & " " & f.key) & ", spends " &
            $spent
        check stated.getOrDefault(module & " " & f.key, [-1, -1, -1]) == spent  # doc reads C
        inc compared
      check compared >= FLOOR_FUNCTIONS_REFERENCE  # guard skips no reference function


  test "each timed loop sits in C function of its own":
    # One function holding every loop puts error check after each call; compiler's estimate
    #   of reaching code below drains to zero, so it optimises rest for size, and library's
    #   loops stay scalar while straight-line forms vectorise.
    var functions_timing = 0
    for path in walkFiles(CACHE / "*measurements.nim.c"):
      for f in functionsIn(readFile(path)):
        let clocks = f.body.count("getMonoTime")
        if clocks == 0: continue
        inc functions_timing
        checkpoint f.name & " reads clock " & $clocks & " times"
        check clocks == 2  # one timed loop: clock read before and after each round
    let pairs_measured = CATALOGUE.len + CATALOGUE.countIt(it.reference.len > 0) +
        (if HAS_FORMS_DENSE: CATALOGUE.countIt(it.reference.len == 0) else: 0)
    checkpoint $functions_timing & " timing functions for " & $pairs_measured & " measured pairs"
    check functions_timing == pairs_measured  # one function per measurand per implementation


  test "timed loop binds result returned by value, so no temporary is zero-filled":
    # Result of three floats or fewer returns by value; assigned straight into its element, it
    #   passed under Nim 2.3.1 through temporary that call site zero-filled, out of line where
    #   function is large, about 11 ns; Nim 2.4.0 assigns it in place. Reference returns so, and
    #   library's norms return two scalars so.
    let returning_scalars = INSPECTED.filterIt(it.stem_result == "MultivectorScalars")
        .mapIt(it.name)
    var calls, filled, calls_library, filled_library = 0
    for path in walkFiles(CACHE / "*measurements.nim.c"):
      let source = readFile(path)
      for f in functionsIn(source):
        if not f.name.startsWith("measure"): continue  # timed loops alone, not callees
        let lines = f.body.splitLines
        for index, line in lines:
          for name in returning_scalars:
            let at = line.find(" = " & name & "(")
            if at < 0: continue
            inc calls_library
            let target = line[0..<at].split({' ', '\t', ';'})[^1]  # after any line marker
            if index > 0 and lines[index-1].strip.startsWith("nimZeroMem") and
                ("(&" & target & ")") in lines[index-1]:
              inc filled_library
      let lines = source.splitLines
      for index, line in lines:
        if "referenceZ" notin line: continue
        inc calls
        if index > 0 and lines[index-1].startsWith("nimZeroMem") and line.startsWith("T"):
          inc filled
    check calls > 0  # loops that call reference are read
    check filled == 0  # no reference result passes through zero-filled temporary
    check calls_library > 0  # loops that call library's norms are read
    check filled_library == 0  # no norm's two scalars pass through zero-filled temporary


  test "own nimcache holds every catalogued symbol at its arity":
    let functions = INSPECTED
    var keys: seq[string]
    for f in functions: keys.add f.key
    for p in CATALOGUE:
      if p.symbol.len == 0: continue
      if p.symbol in INLINED: continue  # template over field read emits no function
      var is_found = false
      for f in functions:
        if f.symbol != p.emitted: continue
        var arity = 0
        for stem in f.parameters:
          if stem == "Multivector" or stem == "float": inc arity
        if arity == int(p.arity): is_found = true
      check is_found  # every spelled operator is emitted at its arity
    when IS_RIGID and DIMENSIONS == 4:
      check "wedge(Point,Point)" in keys  # typed reference reached from suites
      for f in functions:
        if f.key == "wedge(Point,Point)":
          check count(f.body).multiplies == 12 and count(f.body).subtractions == 6  # as documented
    when IS_RIGID and DIMENSIONS == 3:
      check "wedge(Point,Point)" in keys  # typed reference reached from suites
      for f in functions:
        if f.key == "wedge(Point,Point)":
          check count(f.body).multiplies == 6 and count(f.body).subtractions == 3  # as documented



suiteInProc "Internal: Unitized":
  # Program `unitized` times Lengyel's code in homogeneous form against form whose point has
  #   w = 1; suite holds each form to its pair, and each row of its record to C of its forms.

  test "unitized form agrees with homogeneous form where weight is one":
    when IS_RIGID and DIMENSIONS == 4:
      template checkLayout(U: typedesc, i, j: int) =
        ## Hold every form of layout U to its homogeneous form, on elements i and j of pools.
        let
          (a, b) = (POOL_POINT[i], POOL_POINT[j])
          p = unitized.PointHomogeneous(x: a.x, y: a.y, z: a.z, w: 1.0)
          q = unitized.PointHomogeneous(x: b.x, y: b.y, z: b.z, w: 1.0)
          (p_unit, q_unit) = (U(x: a.x, y: a.y, z: a.z), U(x: b.x, y: b.y, z: b.z))
          line = unitized.Line(
            vx: POOL_LINE[i].v.x, vy: POOL_LINE[i].v.y, vz: POOL_LINE[i].v.z,
            mx: POOL_LINE[i].m.x, my: POOL_LINE[i].m.y, mz: POOL_LINE[i].m.z,
          )
          plane = unitized.Plane(
            x: POOL_PLANE[j].x, y: POOL_PLANE[j].y, z: POOL_PLANE[j].z, w: POOL_PLANE[j].w,
          )
          motor = unitized.Motor(
            vx: POOL_MOTOR[j].v.x, vy: POOL_MOTOR[j].v.y, vz: POOL_MOTOR[j].v.z,
            vw: POOL_MOTOR[j].vw, mx: POOL_MOTOR[j].m.x, my: POOL_MOTOR[j].m.y,
            mz: POOL_MOTOR[j].m.z, mw: POOL_MOTOR[j].mw,
          )
        var
          (line_homogeneous, line_unit) = (unitized.Line(), unitized.Line())
          (plane_homogeneous, plane_unit) = (unitized.Plane(), unitized.Plane())
          (moved_homogeneous, moved_unit) = (unitized.PointHomogeneous(), U())
        unitized.join(p, q, line_homogeneous)
        unitized.join(p_unit, q_unit, line_unit)
        check isNear(line_homogeneous, line_unit)  # w = 1 drops each product with w, nothing else
        unitized.join(line, p, plane_homogeneous)
        unitized.join(line, p_unit, plane_unit)
        check isNear(plane_homogeneous, plane_unit)  # w = 1 drops each product of moment with w
        check isNear(unitized.meet(p, plane), unitized.meet(p_unit, plane))  # drops w times g.w
        unitized.antisupport(p, plane_homogeneous)
        unitized.antisupport(p_unit, plane_unit)
        check isNear(plane_homogeneous, plane_unit)  # w = 1 drops each product with w
        unitized.transform(p, motor, moved_homogeneous)
        unitized.transform(p_unit, motor, moved_unit)
        let moved_expected =
          U(x: moved_homogeneous.x, y: moved_homogeneous.y, z: moved_homogeneous.z)
        check moved_homogeneous.w == 1.0  # motor keeps weight of point
        check isNear(moved_expected, moved_unit)  # w = 1 drops each product with w
        for weight in [a.w, -a.w]:
          let point = unitized.PointHomogeneous(x: a.x, y: a.y, z: a.z, w: weight)
          var
            unit_book = unitized.PointHomogeneous()
            unit_code = U()
          unitized.unitizeBook(point, unit_book)
          unitized.unitizeCode(point, unit_code)
          let unit_signed = U(
            x: unit_book.x * unit_book.w, y: unit_book.y * unit_book.w,
            z: unit_book.z * unit_book.w,
          )
          check isNear(abs(unit_book.w), 1.0) and unit_book.w * weight > 0.0  # 2.89, sign kept
          check isNear(unit_code, unit_signed)  # code divides by signed w, so differs by its sign
      for i in 0..<OBJECTS:
        let j = (i * 7 + 3) mod OBJECTS  # pair elements as bench pairs them
        checkLayout(unitized.PointUnitized, i, j)
        checkLayout(unitized.PointPadded, i, j)
    else:
      skip()  # forms of Lengyel's code are of projective 3D space, which rga4d alone models


  test "each row of unitized record saves multiplies that C of its two forms differs by":
    # Case: record held `"saved": -1` on row `unitize, book against code`, from literal that
    #   `pass` of `unitized.nim` passed; code's unitize spares one multiply, so row saves 1.
    when IS_RIGID and DIMENSIONS == 4:
      const
        record = staticRead("../baseline/unitized.json")  ## Takes of `unitized`, as committed.
        rows_recorded = 2 * 2 * 6  ## Rows record holds: two takes of two sizes, six operations.
        lut_forms_by_row = {
          "join two points": (
            "join(PointHomogeneous,PointHomogeneous,Line)",
            "join(PointUnitized,PointUnitized,Line)",
          ),
          "join line and point":
            ("join(Line,PointHomogeneous,Plane)", "join(Line,PointUnitized,Plane)"),
          "meet point and plane": ("meet(PointHomogeneous,Plane)", "meet(PointUnitized,Plane)"),
          "antisupport":
            ("antisupport(PointHomogeneous,Plane)", "antisupport(PointUnitized,Plane)"),
          "transform by motor": (
            "transform(PointHomogeneous,Motor,PointHomogeneous)",
            "transform(PointUnitized,Motor,PointUnitized)",
          ),
          "unitize, book against code": (
            "unitizeBook(PointHomogeneous,PointHomogeneous)",
            "unitizeCode(PointHomogeneous,PointUnitized)",
          ),
        }.toTable
          ## Homogeneous form and unitized form each row times, keyed as inspector keys them.
      var multiplies: Table[string, int]
      for f in INSPECTED: multiplies[f.key] = count(f.body).multiplies
      var rows_read = 0
      for take in parseJson(record)["takes"]:
        for size, timing in take:
          for name, row in timing["rows"]:
            checkpoint size & " objects: " & name
            check name in lut_forms_by_row  # every row names its two forms
            if name notin lut_forms_by_row: continue
            let
              (key_homogeneous, key_unit) = lut_forms_by_row[name]
              key_padded = key_unit.replace("PointUnitized", "PointPadded")
            for key in [key_homogeneous, key_unit, key_padded]:
              check key in multiplies  # form reached from suite above, so its C is read
            if [key_homogeneous, key_unit, key_padded].anyIt(it notin multiplies): continue
            let saved = multiplies[key_homogeneous] - multiplies[key_unit]
            check row["saved"].getInt == saved  # record states what C spares, sign included
            check multiplies[key_padded] == multiplies[key_unit]  # pad costs no arithmetic
            inc rows_read
      check rows_read == rows_recorded  # guard skipped no row
    else:
      skip()  # forms of Lengyel's code are of projective 3D space, which rga4d alone models


  test "each timed call of unitized reads its operands in place, so no copy stalls a load":
    # Case: `pass` copied each operand into temporary, as `T48_ = (*pools_p0).unitized.items[i_8]`,
    #   since result shared root `pools`. Vectorised join read 16 bytes across two stores of that
    #   copy, so no store forwarded, and record held unitized join at ×2.2 of homogeneous one.
    when IS_RIGID and DIMENSIONS == 4:
      const
        forms = ["join", "meet", "antisupport", "transform", "unitizeBook", "unitizeCode"]
          ## Forms that timed loops call, as C names them before overload index.
        calls_timed = 6 * 4  ## Calls that timed loops make: six rows, four layouts each.
      var sink = 0.0
      let timing = unitized.take(16, 1, 1, sink)  # reaches `pass`, so its C is read
      check timing["rows"].len == 6  # one row for each operation
      var calls_read = 0
      for f in INSPECTED:
        if f.symbol != "pass" or not f.module.endsWith("unitized"): continue
        for line in f.body.splitLines:
          if not forms.anyIt((it & "_u") in line): continue
          checkpoint line.strip
          check "(&T" notin line  # operand read in place, never through copied temporary
          inc calls_read
      check calls_read == calls_timed  # every timed call read
    else:
      skip()  # forms of Lengyel's code are of projective 3D space, which rga4d alone models



suiteInProc "Internal: Guard":
  const
    path = "baseline/rga4d.json"
    key = "∧(Multivector,Multivector)"

  func node(multiplies, checks, fills_zero, bytes: int): JsonNode =
    ## Build one function as inspect does, from counts and bytes moved.
    let c = Counts(multiplies: multiplies, checks: checks, fills_zero: fills_zero)
    %*{
      "symbol": "∧", "module": "pga/operators", "params": ["Multivector", "Multivector"],
      "returns": "Multivector", "inline": false, "own": nodeCounts(c), "total": nodeCounts(c),
      "movement": nodeMovement(Movement(bytes_moved: bytes)),
    }

  func documentStatic(functions: JsonNode, flags = "-d:release", dimensions = 4): JsonNode =
    ## Build static measurements document around functions.
    result = document(
      "static",
      nodeAlgebra("rga4d", dimensions, false, 128),
      %*{"date": "2026-09-13", "machine": "m", "nim": "n", "pga": "p", "flags": flags},
    )
    result["functions"] = functions

  func one(name: string, f: JsonNode): JsonNode =
    ## Build functions object holding one function.
    result = newJObject()
    result[name] = f


  test "equal documents pass with nothing to say":
    let
      same = one(key, node(81, 178, 1, 512))
      v = compare(documentStatic(same), documentStatic(same), path)
    check v.findings.len == 0 and v.improvements.len == 0  # gate silent


  test "grown count is one finding naming function, metric and both values":
    let
      before = documentStatic(one(key, node(81, 178, 1, 512)))
      v = compare(before, documentStatic(one(key, node(90, 178, 1, 512))), path)
    check v.findings.len == 1 and v.improvements.len == 0  # one metric grew
    check v.findings[0].render ==
        path & ":0: Total `multiplies` of `" & key & "` grew; got `90`, baseline `81`."  # IV.4


  test "shrunk count is improvement, never finding":
    let
      before = documentStatic(one(key, node(81, 178, 1, 512)))
      v = compare(before, documentStatic(one(key, node(81, 0, 1, 512))), path)
    check v.findings.len == 0 and v.improvements.len == 1  # baseline moves by choice
    check "checks" in v.improvements[0] and "got `0`" in v.improvements[0]  # what shrank


  test "bytes moved are gated with counts":
    let
      before = documentStatic(one(key, node(81, 178, 1, 512)))
      v = compare(before, documentStatic(one(key, node(81, 178, 1, 640))), path)
    check v.findings.len == 1 and "bytes_moved" in v.findings[0].message  # movement grew


  test "function absent in either document is finding":
    let
      present = documentStatic(one(key, node(81, 178, 1, 512)))
      absent = documentStatic(newJObject())
      before = compare(present, absent, path)
    check before.findings.len == 1 and "absent now" in before.findings[0].message  # gone
    let after = compare(absent, present, path)
    check after.findings.len == 1 and "absent from baseline" in after.findings[0].message  # new


  test "documents of another build are not compared":
    let
      same = one(key, node(81, 178, 1, 512))
      flags = compare(documentStatic(same), documentStatic(same, flags = "-d:danger"), path)
    check flags.findings.len == 1 and "`flags`" in flags.findings[0].message  # build differs
    let algebras = compare(documentStatic(same), documentStatic(same, dimensions = 5), path)
    check algebras.findings.len == 1 and "`dimensions`" in algebras.findings[0].message  # differs
    let schema = compare(documentStatic(same), %*{"schema": 2}, path)
    check schema.findings.len == 1 and "Schema differs" in schema.findings[0].message  # refused


  test "lower bound that moves either way or vanishes is finding":
    func bounded(bound: JsonNode): JsonNode =
      ## Build static document whose one measurand `wedge` carries bound given; none for nil.
      result = documentStatic(newJObject())
      result["measurands"] = %*{"wedge": {}}
      if not bound.isNil: result["measurands"]["wedge"]["bound"] = bound
    func multiplies(count: int): JsonNode =
      ## Build lower bound of count multiplies, other fields fixed.
      %*{"multiplies": count, "adds": 0, "divides": 0, "roots": 0, "bytes_moved": 384}
    let
      baseline = bounded(multiplies(81))
      same = compare(baseline, bounded(multiplies(81)), path)
      shrunk = compare(baseline, bounded(multiplies(64)), path)
      grown = compare(baseline, bounded(multiplies(90)), path)
      gone = compare(baseline, bounded(nil), path)
    check same.findings.len == 0 and same.improvements.len == 0  # derivation unchanged
    check shrunk.findings.len == 1 and shrunk.findings[0].render ==
        path & ":0: Lower bound `multiplies` of `wedge` moved; got `64`, baseline `81`."  # IV.4
    check grown.findings.len == 1 and "got `90`" in grown.findings[0].message  # equality gate
    check gone.findings.len == 1 and
        gone.findings[0].message == "Lower bound absent now; got `wedge`."  # bound lost



suiteInProc "Internal: Machine":
  const
    path = "baseline/machine_rga4d.json"
    symbols = """
0000000000001000 0000000000000100 T machine_drive
0000000000002000 0000000000000040 t wrapper0_u0__machine
0000000000003000 0000000000000040 t wrapper1_u0__machine
0000000000004000 0000000000000020 t unitize__pgaZnorms_u3
0000000000005000 0000000000000008 B SINK
0000000000004020 0000000000000000 t sizeless
                 U sqrt@GLIBC_2.2.5
"""
      ## Symbols as `nm -S` prints them: driver, two wrappers, callee, data, sizeless, foreign.
    written = "machine_drive\t109000\nadd\t10a000\nunitize\t10b000\n"
      ## Entries as `machine` writes them, binary loaded `0x108000` past its file addresses.
    trace = """
==1== Lackey, an example Valgrind tool
I  00109000,4
 S 1ffefff000,8
I  0010a000,4
 L 00200000,8
 L 00200008,8
I  0010a004,3
 S 00300000,16
I  0010a010,3
 S 00500000,8
I  0010a010,3
 S 00500008,8
I  0010a017,5
 S 1ffeffef00,8
I  0010c000,4
 M 00300000,8
I  0010c004,1
 L 1ffeffef00,8
I  0010a01c,1
 L 1ffefff008,8
I  00109010,4
 S 00400000,8
I  0010b000,4
I  07000000,4
 L 07100000,32
I  0010b004,1
I  00109020,4
==1== Exit
"""
      ## Trace of driver calling two wrappers: first stores, fills two words by `rep`, and calls
      ##   function of binary that modifies; second runs one instruction in shared object.

  func tallied(text: string): Tally =
    ## Read trace text into tally over fixture entries and symbols.
    result = initTally(parseEntries(written), parseSymbols(symbols))
    for line in text.splitLines: result.read(line)

  func documentMachine(node: JsonNode; compiler_c = "gcc 13.3.0"; id = "add"): JsonNode =
    ## Build machine document holding one measurand's work.
    result = document(
      "machine",
      nodeAlgebra("rga4d", 4, false, 128),
      %*{
        "date": "2026-10-21", "machine": "m", "nim": "n", "pga": "p", "flags": "-d:release",
        "compiler_c": compiler_c, "tracer": "valgrind-3.22.0 --tool=lackey",
      },
    )
    result["measurands"] = newJObject()
    result["measurands"][id] = node

  func work(instructions, bytes_written: int; is_shared_reached = false): JsonNode =
    ## Build work of one wrapper.
    nodeWork(Work(
      instructions: instructions,
      bytes_read: 417,
      bytes_written: bytes_written,
      is_shared_reached: is_shared_reached,
    ))

  let statics = %*{
    "measurands": {"add": {"library": "+(Multivector,Multivector)"}, "sandwich": {"library": ""}},
    "functions": {"+(Multivector,Multivector)": {
      "total": {"fills_zero": 1, "copies": 0}, "movement": {"bytes_moved": 512},
    }},
  }
    ## Static document beside machine one: `add` names library function, `sandwich` composes.


  test "symbols keep functions of binary with size, and skip data and foreign ones":
    check parseSymbols(symbols).mapIt(it.name) == @[
      "machine_drive", "wrapper0_u0__machine", "wrapper1_u0__machine", "unitize__pgaZnorms_u3",
      "sizeless",
    ]  # data `B` and undefined `U` skipped; sizeless kept, and counts in no extent


  test "work of wrapper runs from its entry to first instruction back in driver":
    let works = tallied(trace).works
    check works.mapIt(it[0]) == @["add", "unitize"]  # order `machine` listed
    check works[0][1] == Work(
      instructions: 8,  # own four, return among them, `rep` twice, callee's two; never driver's
      bytes_read: 40,  # two loads, callee's modify, two returns
      bytes_written: 48,  # store, two words of `rep`, call's push, callee's modify
      is_shared_reached: false,  # callee lies in binary's text
    )
    check works[1][1] == Work(
      instructions: 3, bytes_read: 32, bytes_written: 0, is_shared_reached: true
    )  # instruction at `0x7000000` lies past binary's text


  test "trace ending inside wrapper, or missing one, is refused":
    let cut = trace[0 ..< trace.find("I  00109010")]
    expect ValueError: discard tallied(cut).works  # ends inside `add`
    let half = trace[0 ..< trace.find("I  0010b000")]
    expect ValueError: discard tallied(half).works  # holds no work of `unitize`
    expect ValueError: discard tallied(trace & "I  0010a000,4\nI  00109000,4\n").works  # twice


  test "entries open with driver, and symbol table sizes it":
    expect ValueError: discard initTally(parseEntries("add\t10a000\n"), parseSymbols(symbols))
    expect ValueError: discard initTally(parseEntries(written), parseSymbols(""))
    expect ValueError: discard initTally(
      parseEntries(written & "subtract\t10a000\n"), parseSymbols(symbols)
    )  # two measurands share one entry
    expect ValueError: discard parseEntries("add 10a000\n")  # tab separates name and address


  test "copy is read apart, and its wrapper says whether they agree":
    let parsed = parseEntries(written & "add\t10a020\tcopy\nunitize\t10b020\tcopy\n")
    check parsed.mapIt(it.is_copy) == @[false, false, false, true, true]
    var tally = initTally(parsed, parseSymbols(symbols))
    for line in (trace & "I  0010a020,4\n L 00200000,8\nI  00109030,4\n" &
        "I  0010b020,4\nI  07000000,4\n L 07100000,32\nI  0010b024,1\nI  00109040,4\n").splitLines:
      tally.read(line)
    let works = tally.works
    check works.mapIt(it[1].is_copy_apart) == @[true, false]  # copy of `add` runs 1 of 8
    check nodeWork(works[0][1]){"is_copy_apart"}.getBool  # document says so
    var unread = initTally(parseEntries(written & "add\t10a020\tcopy\n"), parseSymbols(symbols))
    for line in trace.splitLines: unread.read(line)
    expect ValueError: discard unread.works  # copy listed and never run
    expect ValueError: discard parseEntries("add\t10a000\ttwin\n")  # mark other than `copy`


  test "equal machine documents pass with nothing to say":
    let v = compareMachine(documentMachine(work(82, 392)), documentMachine(work(82, 392)),
        statics, path)
    check v.findings.len == 0 and v.improvements.len == 0  # zero band holds


  test "grown machine measurement is finding, with static count of its function beside it":
    let v = compareMachine(documentMachine(work(82, 392)), documentMachine(work(83, 392)),
        statics, path)
    check v.findings.len == 1 and v.improvements.len == 0  # one instruction more is growth
    check v.findings[0].render == path & ":0: Machine `instructions` of `add` grew; got `83`, " &
        "baseline `82`, beside static `+(Multivector,Multivector)` of `1` fills, `0` copies " &
        "and `512` bytes moved."  # VII.10, IV.4
    let composed = compareMachine(
      documentMachine(work(900, 392), id = "sandwich"),
      documentMachine(work(900, 520), id = "sandwich"),
      statics,
      path,
    )
    check composed.findings.len == 1 and composed.findings[0].message.endsWith(
      "got `520`, baseline `392`, and no static function names it."
    )  # measurand composing several calls names no library function


  test "shrunk machine measurement is improvement, never finding":
    let v = compareMachine(documentMachine(work(82, 392)), documentMachine(work(82, 264)),
        statics, path)
    check v.findings.len == 0 and v.improvements.len == 1  # baseline moves by choice
    check "`bytes_written` of `add` shrank; got `264`" in v.improvements[0]  # what shrank


  test "machine document of another compiler is refused, never compared":
    let v = compareMachine(
      documentMachine(work(82, 392)),
      documentMachine(work(90, 392), compiler_c = "clang 18.1.3"),
      statics,
      path,
    )
    check v.findings.len == 1 and v.findings[0].message ==
        "Build `compiler_c` differs; got `clang 18.1.3`, baseline `gcc 13.3.0`."  # VII.11
    let static_kind = compareMachine(documentMachine(work(82, 392)),
        document("static", newJObject(), newJObject()), statics, path)
    check static_kind.findings.len == 1 and "Kind differs" in static_kind.findings[0].message


  test "wrapper reaching shared object is finding, though its counts hold":
    let v = compareMachine(
      documentMachine(work(82, 392)),
      documentMachine(work(82, 392, is_shared_reached = true)),
      statics,
      path,
    )
    check v.findings.len == 1 and v.findings[0].message.endsWith("zero no longer; got `add`.")


  test "wrapper whose copy reads other counts is finding":
    var apart = documentMachine(work(82, 392))
    apart["measurands"]["add"]["is_copy_apart"] = %true
    let v = compareMachine(documentMachine(work(82, 392)), apart, statics, path)
    check v.findings.len == 1 and v.findings[0].message.endsWith(
      "moves with code around it; got `add`."
    )  # coupling through C file, which three flags of gcc lift


  test "measurand absent in either machine document is finding":
    let
      present = documentMachine(work(82, 392))
      other = documentMachine(work(82, 392), id = "subtract")
      v = compareMachine(present, other, statics, path)
    check v.findings.mapIt(it.message) == @[
      "Measurand absent now; got `add`.", "Measurand absent from baseline; got `subtract`."
    ]


  test "each wrapper is its own function behind boundary optimiser cannot see through":
    # VII.9: gcc's `noipa` keeps driver from inlining, cloning, folding or dropping each call.
    let listed = entries()
    check listed.len == 2 * CATALOGUE.len + 1  # driver, then wrapper and copy per measurand
    check listed.mapIt(it.address).deduplicate.len == listed.len  # no two share one entry
    check listed[1 .. CATALOGUE.len].mapIt(it.name) == CATALOGUE.mapIt(it.id)  # in order
    check listed[1 .. CATALOGUE.len].allIt(not it.is_copy)
    check listed[CATALOGUE.len + 1 .. ^1].mapIt(it.name) == CATALOGUE.mapIt(it.id)  # then copies
    check listed[CATALOGUE.len + 1 .. ^1].allIt(it.is_copy)
    var declared = 0
    for path in walkFiles(CACHE / "*machine.nim.c"):
      for line in readFile(path).splitLines:
        if line.startsWith("__attribute__((noinline, noipa))") and line.endsWith(";"):
          inc declared
    check declared == 2 * CATALOGUE.len + 1  # every wrapper, copy and driver declared so



suiteInProc "Internal: Gaps":
  const key_wedge = "∧(Multivector,Multivector)"

  func nodeFunction(
    symbol, module: string; is_inline: bool; multiplies, checks, fills_zero, bytes: int
  ): JsonNode =
    ## Build one inspected function.
    let c = Counts(multiplies: multiplies, checks: checks, fills_zero: fills_zero)
    %*{
      "symbol": symbol, "module": module, "params": [], "returns": "", "inline": is_inline,
      "own": nodeCounts(c), "total": nodeCounts(c),
      "movement": nodeMovement(Movement(bytes_moved: bytes)),
    }

  func documentStaticFixture(): JsonNode =
    ## Build static measurements document: two library operators, accessor, reference form.
    result = document(
      "static",
      nodeAlgebra("rga4d", 4, false, 128),
      %*{"date": "2026-09-13", "machine": "m", "nim": "n", "pga": "p", "flags": "f"},
    )
    var functions = newJObject()
    functions[key_wedge] = nodeFunction("∧", "pga/operators", false, 81, 178, 1, 512)
    functions["wedge(Point,Point)"] = nodeFunction("wedge", "reference/rigid3", true, 12, 0, 0, 112)
    functions["~(Multivector)"] = nodeFunction("~", "pga/operators", false, 0, 0, 1, 384)
    functions["[](Multivector,Basis)"] = nodeFunction("[]", "pga/multivectors", true, 0, 0, 0, 136)
    result["functions"] = functions
    result["measurands"] = %*{
      "wedge": {"symbol": "∧", "library": key_wedge, "reference": ""},
      "wedge_point_point": {
        "symbol": "∧", "library": key_wedge, "reference": "wedge(Point,Point)"
      },
      "select_part": {"symbol": "[]", "library": "[](Multivector,Basis)", "reference": ""},
      "transform_point_motor": {
        "symbol": "", "library": "", "reference": "transform(Point,Motor)"
      },
    }
    result["missing"] = newJObject()

  func measurement(ns: float): JsonNode =
    ## Build one bench measurement.
    %*{"ns_median": ns, "ns_min": ns, "allocations": 0, "share_nan": 0.0}

  func documentRuntimeFixture(): JsonNode =
    ## Build runtime measurements document over same measurands.
    result = document(
      "runtime",
      nodeAlgebra("rga4d", 4, false, 128),
      %*{
        "date": "2026-09-13", "machine": "m", "rounds": 3, "objects": 64,
        "is_allocation_measured": true,
      },
    )
    result["measurands"] = %*{
      "wedge": {"library": measurement(24.1), "reference": newJNull()},
      "wedge_point_point": {"library": measurement(24.1), "reference": measurement(1.3)},
      "select_part": {"library": measurement(0.5), "reference": newJNull()},
      "transform_point_motor": {"library": measurement(60.0), "reference": measurement(5.0)},
    }

  let algebras_fixture = @[
    Algebra(
      name: "rga4d",
      measurements_static: documentStaticFixture(),
      measurements_runtime: documentRuntimeFixture(),
    ),
  ]

  func decideRule(rule: Rule, algebras: seq[Algebra], gaps: seq[Gap]): Decision =
    ## Decide cause carrying rule.
    for d in CAUSES:
      if d.rule == rule: return d.decideCause(algebras, gaps)


  test "gaps are decided against reference and against zero":
    let gaps = gapsAlgebra(algebras_fixture[0])
    check gaps.len == 4  # one per measurand
    let by = gaps.mapIt((it.measurand, it)).toTable
    check by["wedge"].status == Status.Over and "checks" in by["wedge"].metrics_over  # absolute
    check "multiplies" notin by["wedge"].metrics_over  # no reference, no relative target
    check by["wedge_point_point"].metrics_over ==
        @["multiplies", "bytes", "fills_zero", "checks", "time"]  # in decided order
    check by["select_part"].status == Status.Met  # nothing spent, nothing exceeded
    check by["transform_point_motor"].metrics_over == @["time"]  # composed expression, timing alone


  test "gap without counts or timing is unmeasured":
    let gaps = gapsAlgebra(
      Algebra(
        name: "rga4d",
        measurements_static: documentStaticFixture(),
        measurements_runtime: nil,
      ),
    )
    let by = gaps.mapIt((it.measurand, it)).toTable
    check by["transform_point_motor"].status == Status.Unmeasured  # nothing to decide on
    check "time" notin by["wedge_point_point"].metrics_over  # no bench, no time verdict


  test "docket keeps identifiers across reorder and allots next to new key":
    var
      gaps = gapsAlgebra(algebras_fixture[0])
      docket = toDocket(nil)
    gaps.assign(docket)
    check gaps[0].id == "G001" and gaps[3].id == "G004" and docket.next == 5  # in order
    gaps.reverse
    var again = toDocket(docket.toJson)
    gaps.assign(again)
    check gaps[0].id == "G004" and gaps[3].id == "G001" and again.next == 5  # never renumbered
    gaps.add Gap(key: "cga5d/wedge", algebra: "cga5d", measurand: "wedge")
    gaps.assign(again)
    check gaps[^1].id == "G005" and again.next == 6  # next number, never one reused


  test "causes are decided by rule with evidence":
    let
      gaps = gapsAlgebra(algebras_fixture[0])
      checks = decideRule(Rule.Checks, algebras_fixture, gaps)
    check checks.status == Status.Over and "1 of 3 library functions" in checks.evidence  # ∧
    check "`" & key_wedge & "` with 178" in checks.evidence  # most
    check decideRule(Rule.Inline, algebras_fixture, gaps).evidence ==
        "1 of 3 library operators, for example rga4d `~(Multivector)`."  # light operator called
    check decideRule(Rule.FillsZero, algebras_fixture, gaps).evidence.startsWith(
      "2 of 3")  # ∧ and ~
    check decideRule(Rule.Terms, algebras_fixture, gaps).evidence == "1 gaps. The widest is " &
        "rga4d/wedge_point_point, which spends 81 multiplies against 12."  # widest gap named
    check decideRule(Rule.Time, algebras_fixture, gaps).evidence ==
        "2 gaps. The worst is rga4d/wedge_point_point, at 24.1 ns against 1.3 ns."  # worst ratio
    check decideRule(Rule.Nan, algebras_fixture, gaps).status == Status.Met  # every share zero
    check decideRule(Rule.Compound, algebras_fixture, gaps).evidence ==
        "rga4d/transform_point_motor."  # composed expression named
    check decideRule(Rule.Missing, algebras_fixture, gaps).status == Status.Met  # nothing missing
    check decideRule(Rule.Cayley, algebras_fixture, gaps).status ==
        Status.Unmeasured  # not readable here


  test "causes count library functions, never reference or dense form":
    check isModuleLibrary("pga/operators")  # library's own
    check not isModuleLibrary("reference/rigid3")  # typed reference
    check not isModuleLibrary("dense")  # dense form, as bench build names it
    check not isModuleLibrary("pga_benchmark/dense")  # dense form, as test build names it


  test "rendered list fits width and names every gap":
    let (text, docket) = generate(algebras_fixture, toDocket(nil))
    var widest = 0
    for line in text.splitLines: widest = max(widest, runeLen(line))
    check widest <= WIDTH  # form check reads product
    check "| G002 | wedge_point_point | 81/12 | 0/0 | 512/112 | 0/0 | 178/0 | 24.1/1.3 | over |" in
        text  # cells read library/reference
    check "| G004 | transform_point_motor | – | – | – | – | – | 60.0/5.0 | over |" in
        text  # composed expression has no counts
    check "- **D05, over.**" in text and "- **D10, unmeasured.**" in text  # proposal verdicts
    check "Gaps: 4. Over 3, met 1, unmeasured 0." in text  # summary
    check docket.next == 5  # docket grew with gaps


  test "restamped runtime names commit bench ran at":
    var restamped_runtime = documentRuntimeFixture()
    restamped_runtime["taken"]["measured_at"] = %"d9be8ae"
    let
      algebras_carried = @[Algebra(
        name: "rga4d",
        measurements_static: documentStaticFixture(),
        measurements_runtime: restamped_runtime,
      )]
      (text, _) = generate(algebras_carried, toDocket(nil))
      (text_timed, _) = generate(algebras_fixture, toDocket(nil))
    check "It ran at pga `d9be8ae`, which emits the same C as the pin." in
        text.splitWhitespace.join(" ")  # header names commit timed at
    check "emits the same C" notin text_timed  # measured at stamp says nothing more


  test "wrap breaks at spaces within width and indents continuation":
    check wrap("aa bb cc", 5) == @["aa bb", "cc"]  # fits, then breaks
    check wrap("aa bb cc", 5, "  ") == @["aa bb", "  cc"]  # continuation indented
    check wrap("∧∧∧ ∧∧∧", 3) == @["∧∧∧", "∧∧∧"]  # runes, not bytes



suiteInProc "Internal: Markdown":
  test "blocks keep kind, level and line they open on":
    let blocks = parseBlocks(
      "# Title\n\nWhy it is.\nStill why.\n\n- one\n- two\n\n" & "| a | b |\n|---|---|\n| 1 | 2 |\n",
    )
    check blocks.len == 4  # heading, paragraph, bullets, table
    check blocks[0].kind == KindBlock.Heading and blocks[0].level == 1  # title
    check blocks[1].lines == @["Why it is.", "Still why."] and blocks[1].line == 3  # paragraph
    check blocks[2].kind == KindBlock.Bullets and blocks[2].lines == @["one", "two"]  # list
    check blocks[3].kind == KindBlock.Table and blocks[3].lines.len == 3  # rows kept


  test "fence keeps its lines verbatim and closes on run at least as long":
    let blocks = parseBlocks("````nim\nlet a = 1\n```\n  indented\n````\nafter\n")
    check blocks[0].kind == KindBlock.Fence and blocks[0].language == "nim"  # after opening run
    check blocks[0].lines == @["let a = 1", "```", "  indented"]  # shorter run stays inside
    check blocks[1].kind == KindBlock.Paragraph  # fence closed


  test "inline markup renders, and everything else is escaped":
    check renderInline("`a < b` and **b** and _c_") ==
        "<code>a &lt; b</code> and <strong>b</strong> and <em>c</em>"  # three markers
    check renderInline("[site](https://x.y/z?a=1&b=2)") ==
        "<a href=\"https://x.y/z?a=1&amp;b=2\">site</a>"  # link escaped once
    check renderInline("snake_case_name <b>") == "snake_case_name &lt;b&gt;"  # no false italic


  test "table renders header row when second row divides":
    let html = renderBlocks(parseBlocks("| a | b |\n|---|---|\n| 1 | 2 |\n"))
    check "<th>a</th>" in html and "<td>1</td>" in html and "---" notin html  # header split


  test "fenced line takes one line: its newline breaks it, so its span flows inline":
    const shell_html = staticRead("../pages/shell.html")
    check "</span>\n<span class=\"cl\">" in renderFence(@["a", "b"], "")  # copy keeps newline
    for rule in shell_html.split('}'):
      let body = rule.split('{')
      if body.len < 2 or body[^2].strip != "pre.code .cl": continue
      check "display: block" notin body[^1]  # block line after newline doubles each line
    check "pre.code code { padding: 0;" in shell_html  # inline pad would indent first line alone


  test "Nim fence marks keywords, declared name, doc comment, comment, literal and pragma":
    check renderNim("func `∧`*[A: static set[Basis]](m: Of[A]): int {.noinit.} =") ==
        "<span class=\"kw\">func</span> <span class=\"nm\">`∧`</span>*[A: " &
        "<span class=\"kw\">static</span> set[Basis]](m: Of[A]): int " &
        "<span class=\"pr\">{.noinit.}</span> ="  # name after declaring keyword alone
    check renderNim("  ## Read `B` < 2.") ==
        "  <span class=\"doc\">## Read `B` &lt; 2.</span>"  # doc comment whole, escaped
    check renderNim("let s = \"# no \\\" end\"  # yes") ==
        "<span class=\"kw\">let</span> s = " &
        "<span class=\"st\">&quot;# no \\&quot; end&quot;</span>  " &
        "<span class=\"cm\"># yes</span>"  # hash in literal opens no comment
    check renderNim("format(proc(m: K))") ==
        "format(<span class=\"kw\">proc</span>(m: K))"  # keyword whole word, type names none


  test "fence marks Nim alone, and shell colours each mark it makes":
    const shell_html = staticRead("../pages/shell.html")
    check "<span class=\"kw\">func</span>" in renderFence(@["func a"], "nim")  # Nim marked
    check "class=\"kw\"" notin renderFence(@["func a"], "")  # other language stays plain
    for class in ["kw", "nm", "doc", "cm", "st", "pr"]:
      check "pre.code ." & class & ", .diff ." & class & " {" in shell_html  # drawn, in diff too



suiteInProc "Internal: Definitions":
  const source = """## Module doc.

import std/strutils

type  ## Kinds of thing.
  Kind* = enum  ## Kinds.
    A, B
  Thing* = object
    field: int

const LIMIT = 3  ## Limit.

func f*(x: int): int =
  ## Double x.
  x * 2

when defined(fast):
  func `+`(
    a: int
  ): int =
    ## Triple a.
    a * 3

suite "S":
  test "t":
    check true

defineIt(
  name = "x",
)"""


  test "definitions split routines, members, imports and statements, under when and suite":
    let found = splitDefinitions(source.splitLines)
    check found.mapIt(it.kind & " " & it.name) == @[
      "doc module", "import ", "type Kind", "type Thing", "const LIMIT", "func f", "func +",
      "test t", "statement defineIt( name = \"x\", )",
    ]  # section members apart, operator unticked, statement named by its head
    check found[5].head.len == 1 and found[5].doc == @["  ## Double x."] and
        found[5].body == @["  x * 2"]  # head, doc and body apart
    check found[6].head.len == 3 and found[6].context == "when defined(fast)"  # head spans lines
    check found[7].context == "suite \"S\""  # test under its suite
    check found[3].first == 7 and found[3].body == @["    field: int"]  # member keeps its fields


  test "pairs by same head first, then in order, and removed stands after what it followed":
    let
      before = splitDefinitions(@[
        "func a(x: int): int = x", "func a(x: float): float = x", "func b(): int = 1",
        "func d(): int = 2",
      ])
      after = splitDefinitions(@[
        "func a(x: float): float = -x", "func a(x: int): int = x", "func c(): int = 1",
        "func d(): int = 2",
      ])
    check pairDefinitions(before, after).mapIt((it.before, it.after)) ==
        @[(1, 0), (0, 1), (2, -1), (-1, 2), (3, 3)]  # overloads by head, rename as two


suiteInProc "Internal: Changes":
  const
    record = "changes/sign.md"
    library = "let x = 1\nlet y = 2\nlet z = 1\n"


  test "change reads title, why and edits in order":
    let (change, findings) = parseChange(
      record,
      "# Sign\n\nWhy.\n\n## Edit `pga/a.nim`\n\n" &
      "FENCEnim\nlet y = 2\nFENCE\n\nFENCEnim\nlet y = 3\nFENCE\n".replace("FENCE", "```"),
    )
    check findings.len == 0  # well formed
    check change.title == "Sign" and change.why.len == 1  # title and why
    check change.edits.len == 1 and change.edits[0].path == "pga/a.nim"  # one edit
    check change.edits[0].quote == "let y = 2"  # first fence quotes
    check change.edits[0].replacement == "let y = 3"  # second fence replaces


  test "quote found once is replaced; found twice or nowhere is finding":
    var files = {"pga/a.nim": library}.toTable
    let
      once = Change(edits: @[Edit(path: "pga/a.nim", quote: "let y = 2", replacement: "let y = 3")])
      twice = Change(edits: @[Edit(path: "pga/a.nim", quote: " = 1", replacement: " = 4", line: 5)])
      nowhere = Change(edits: @[Edit(path: "pga/a.nim", quote: "let w", replacement: "")])
    check applyChange(files, once, record).len == 0  # applies
    check files["pga/a.nim"] == "let x = 1\nlet y = 3\nlet z = 1\n"  # replaced in place
    let ambiguous = applyChange(files, twice, record)
    check ambiguous.len == 1 and ambiguous[0].render ==
        record & ":5: Quote must occur once in `pga/a.nim`; got `2`."  # never guess
    check applyChange(files, nowhere, record).len == 1  # stale quote


  test "whole-file replacement holds to digest of file at pin":
    var files = {"pga/a.nim": library}.toTable
    let
      fresh = Change(
        edits: @[
          Edit(
            kind: KindEdit.Replace,
            path: "pga/a.nim",
            replacement: "new\n",
            digest: digest(library),
          ),
        ],
      )
      stale = Change(
        edits: @[
          Edit(kind: KindEdit.Replace, path: "pga/a.nim", replacement: "new\n", digest: "0"),
        ],
      )
    check applyChange(files, stale, record).len == 1  # file moved on at head
    check applyChange(files, fresh, record).len == 0 and files["pga/a.nim"] == "new\n"  # replaced


  test "new file is added where absent; file standing at its path is finding":
    let (change, findings) = parseChange(
      record,
      "# Sign\n\n## Add `pga/b.nim`\n\nFENCEnim\nlet b = 1\nFENCE\n".replace("FENCE", "```"),
    )
    check findings.len == 0 and change.edits.len == 1  # well formed
    check change.edits[0].kind == KindEdit.Add and change.edits[0].path == "pga/b.nim"  # new file
    var files = {"pga/a.nim": library}.toTable
    check applyChange(files, change, record).len == 0  # applies
    check files["pga/b.nim"] == "let b = 1\n"  # added whole
    check files["pga/a.nim"] == library  # other file untouched
    let again = applyChange(files, change, record)
    check again.len == 1 and "holds file already" in again[0].message  # never overwrite


  test "section that is neither edit, replace nor add is finding":
    let (_, findings) = parseChange(record, "# Sign\n\n## Rename things\n")
    check findings.len == 1 and "neither Edit, Replace nor Add" in findings[0].message  # malformed



suiteInProc "Internal: Notes":
  const
    record = "marginalia/notes.md"
    source = "Notes.\n\n## Odd grade\n\n`pga/a.nim` · decide\n\n" &
        "FENCEnim\nlet y = 2\nFENCE\n\nSay why.\n"


  test "note reads title, file, status, quote and body":
    let (notes, findings) = parseNotes(record, source.replace("FENCE", "```"))
    check findings.len == 0 and notes.lead.len == 1 and notes.items.len == 1  # one note
    let note = notes.items[0]
    check note.title == "Odd grade" and note.path == "pga/a.nim"  # heading, then file
    check note.status == "decide"  # verdict after file
    check note.quote == "let y = 2" and note.body.len == 1  # anchor and body


  test "anchor is located at pin, and stale anchor is finding":
    let
      (notes, _) = parseNotes(record, source.replace("FENCE", "```"))
      files = {"pga/a.nim": "let x = 1\nlet y = 2\n"}.toTable
      moved = {"pga/a.nim": "let y = 3\n"}.toTable
    check checkAnchors(notes, files, record).len == 0  # quote found once
    check notes.items[0].lineAt(files) == 2  # located where it stands
    check checkAnchors(notes, moved, record).len == 1  # quote gone from library



suiteInProc "Internal: Head":
  const pin = "bd6b23c590d7e1da91a1ea288a1a4b94dedbf315"


  test "pin passes when library tree is head's, whatever repository commit":
    check checkHead(pin, "tree1", "ffffffff", "tree1", "atlas.lock").len == 0  # same tree
    let lag = checkHead(pin, "tree1", "ffffffff", "tree2", "atlas.lock")
    check lag.len == 1 and "Pin lags library head" in lag[0].message  # library moved
    check checkHead(pin, "tree1", "", "", "atlas.lock").len == 1  # head unread is finding


  test "measurement and evaluation must be taken at pin":
    let
      fresh = %*{"taken": {"pga": pin}, "edits_digest": "d1"}
      stale = %*{"taken": {"pga": "0bc4655"}, "edits_digest": "d1"}
    check checkStamp(fresh, pin, "baseline/runtime_rga4d.json").len == 0  # at pin
    check checkStamp(stale, pin, "baseline/runtime_rga4d.json").len == 1  # re-take
    check checkEvaluation(fresh, pin, "d1", "evaluations/sign.json").len == 0  # current
    check checkEvaluation(fresh, pin, "d2", "evaluations/sign.json").len == 1  # edits changed since


  test "built page must match digest it was published at, and README its URL":
    let
      built = {"docket": "a1", "marginalia": "b2"}.toTable
      publications = %*{
        "docket": {"url": "https://x/1", "digest": "a1"},
        "marginalia": {"url": "https://x/2", "digest": "b0"},
        "retired": {"url": "https://x/3", "digest": "c3"},
      }
      readme = "Pages: https://x/1 and https://x/2 and https://x/3."
      findings = checkPublished(built, publications, readme, "pages/published.json")
    check findings.len == 2  # marginalia changed, retired page left in publications
    check "`marginalia`" in findings[0].message or
        "`marginalia`" in findings[1].message  # changed page named
    check checkPublished(built, publications, "Pages: https://x/1.", "p").len == 4  # URLs unnamed


  test "digest of C reads every file by name, and leaves pin's commit out":
    let
      at_pin = @[("b.nim.c", "x = \"" & pin & "\";"), ("a.nim.c", "y")]
      at_head = @[("a.nim.c", "y"), ("b.nim.c", "x = \"ffff\";")]
    check digestSources(at_pin, pin) == digestSources(at_head, "ffff")  # order and commit aside
    check digestSources(at_pin, pin) != digestSources(@[("a.nim.c", "y")], pin)  # file gone
    check digestSources(@[("a.nim.c", "y")], pin) !=
        digestSources(@[("a.nim.c", "z")], pin)  # one byte of C moved


  test "digest names type hashes by order, so checkouts at two paths take one digest":
    let
      here = @[("a.nim.c", "typedef struct tyObject_M__IkjEFFLcwCB5cipET7bBTw M;\nM x;")]
      there = @[("a.nim.c", "typedef struct tyObject_M__Y6c3NLon59ae9aWWHEZFTy0Q M;\nM x;")]
      reshaped = @[("a.nim.c", "typedef struct tyObject_M__Y6c3NLon59ae9aWWHEZFTy0Q M;\nM y;")]
    check digestSources(here, pin) == digestSources(there, pin)  # hash alone differs
    check digestSources(here, pin) != digestSources(reshaped, pin)  # body still counts
    check digestSources(@[("a.nim.c", "f__u12();")], pin) !=
        digestSources(@[("a.nim.c", "f__u13();")], pin)  # short suffix is no hash


  test "digest leaves out header full build writes, so it reads as C alone at any path":
    const
      generated = "/* Generated by Nim Compiler v2.3.1 */\n"
      body = "#define NIM_INTBITS 64\nint x;\n"
      here = "/* Compiled for: Linux, amd64, gcc */\n/* Command for C compiler:\n" &
          "   gcc -c -O3 -o /a/cache/@ma.nim.c.o /a/cache/@ma.nim.c */\n"
      there = "/* Compiled for: Linux, amd64, gcc */\n/* Command for C compiler:\n" &
          "   gcc -c -O3 -o /b/c/cache/@ma.nim.c.o /b/c/cache/@ma.nim.c */\n"
    let alone = digestSources(@[("a.nim.c", generated & body)], pin)
    check digestSources(@[("a.nim.c", generated & here & body)], pin) == alone  # full build
    check digestSources(@[("a.nim.c", generated & there & body)], pin) == alone  # other path
    check digestSources(@[("a.nim.c", generated & body & "int y;\n")], pin) != alone  # body


  test "restamp moves stamp only where builds emit C figures were timed on":
    const old = "0bc4655"
    let
      digests = %*{"plain": "d1", "alloc": "d2"}
      timed = %*{"taken": {"pga": old, "date": "2026-10-03"}, "digest_c": digests}
      moved = restamped(timed, digests, pin)
    check checkRestamp(digests, digests, old, pin, "r.json", "run `bench`").len == 0  # same C
    check checkRestamp(digests, %*{"plain": "d1", "alloc": "d3"}, old, pin, "r.json",
      "run `bench`").len == 1  # one build moved
    check checkRestamp(nil, digests, pin, pin, "r.json", "run `bench`").len == 0  # at pin, first
    check checkRestamp(nil, digests, old, pin, "r.json", "run `bench`").len == 1  # away, none
    check checkRestamp(nil, digests, "", pin, "r.json", "run `bench`").len == 1  # edits moved
    check moved{"taken", "pga"}.getStr == pin  # stamp at pin
    check moved{"taken", "measured_at"}.getStr == old  # names commit timed at
    check moved{"taken", "date"}.getStr == "2026-10-03"  # date of timing kept
    check restamped(moved, digests, "ffff"){"taken", "measured_at"}.getStr == old  # first stays
    check not restamped(%*{"taken": {"pga": pin}}, digests, pin)["taken"].hasKey(
      "measured_at")  # backfill at own pin
    check stampMoved(%*{"pga": old}, pin)["pga"].getStr == pin  # stamp alone


  test "evaluation at pin with digest at every algebra leaves restamp nothing to move":
    let
      done = %*{"taken": {"pga": pin}, "edits_digest": "d1",
        "algebras": {"rga4d": {"digest_c": {"pristine": "a", "changed": "b"}}}}
      bare = %*{"taken": {"pga": pin}, "edits_digest": "d1", "algebras": {"rga4d": {}}}
    check done.isRestamped(pin, "d1")  # nothing to move
    check not bare.isRestamped(pin, "d1")  # digest to take
    check not done.isRestamped(pin, "d2")  # edits moved
    check not done.isRestamped("ffff", "d1")  # pin moved


  test "restamped figures name commit they were measured at":
    check measuredAt(%*{"pga": pin}) == ""  # measured at stamp
    check measuredAt(%*{"pga": pin, "measured_at": "0bc4655aa"}) ==
        " at pga <code>0bc4655</code>"  # restamped
    check measuredAt(nil) == ""  # no stamp



suiteInProc "Internal: Proposals":
  const
    directory_sign = "proposals/01-sign"
    shape = "\n**What it is.** It.\n\n**What it is for.** For.\n\n**What it costs.** Cost.\n" &
      "\n## Problem\n\n## Idea\n\n## Alternatives\n\n## Costs\n\n## Open decisions\n" &
      "\n## Landing\n\n## Evidence\n"
      ## Argument of standard shape, after its title.
    record_sign = "# P01: Sign\n" & shape

  func numbered(number: int, status = "proposed", bases: seq[int] = @[]): Proposal =
    ## Read well-formed proposal at number, with status, building on proposals `bases` number.
    let
      directory = "proposals/" & align($number, 2, '0') & "-p" & $number
      heading = "# P" & align($number, 2, '0') & ": P\n"
    parseProposal(
      heading,
      "",
      %*{
        "status": status,
        "implemented_in": "abc",
        "builds_on": bases.mapIt("p" & $it),
        "claims": [],
      },
      directory,
    )[0]


  test "summary is three labelled paragraphs and sections are seven, in order, else finding":
    let
      claims = %*{"status": "proposed", "builds_on": [], "claims": []}
      (_, loose) = parseProposal("# P01: Sign\n\nWhy.\n", "", claims, directory_sign)
      (_, swapped) = parseProposal(
        record_sign.replace("## Problem", "## Spare").replace("## Idea", "## Problem")
          .replace("## Spare", "## Idea"),
        "",
        claims,
        directory_sign,
      )
    check loose.len == 2 and "`unlabelled paragraph`" in loose[0].message  # summary needs labels
    check "got ``" in loose[1].message  # sections absent
    check swapped.len == 1 and "got `Idea`, `Problem`, `Alternatives`" in swapped[0].message
      # order


  test "proposal reads number, title, status, base proposals and claims of every known kind":
    let
      claims = %*{"status": "proposed", "builds_on": ["base"], "claims": [{"kind": "suites"},
        {"kind": "build", "algebra": "rga6d", "metric": "peakmem", "at_most": 0.7},
        {"kind": "program", "path": "p.nim", "algebras": ["rga4d"]}]}
      (proposal, findings) = parseProposal(record_sign, "", claims, directory_sign)
    check findings.len == 0 and proposal.title == "Sign"  # well formed, citation read off
    check proposal.number == 1 and proposal.name == "sign"  # number, then name, from path
    check proposal.citation == "P01" and not proposal.isFrozen  # cited as RFC is
    check proposal.builds_on == @["base"] and proposal.claims.len == 3  # bases and claims
    check proposal.programs == @["proposals/01-sign/p.nim"]  # program beside its proposal
    let
      claims_base = %*{"status": "proposed", "builds_on": [], "claims": [
        {"kind": "program", "path": "a.nim", "algebras": ["rga4d"]}]}
      (base, _) = parseProposal("# P04: Base\n\nWhy.\n", "", claims_base, "proposals/04-base")
    check programs([base, proposal]) ==
      @["proposals/04-base/a.nim", "proposals/01-sign/p.nim"]  # base first, then own


  test "unknown claim, missing title and claims that are not JSON are findings":
    let
      odd = %*{"status": "proposed", "builds_on": [], "claims": [{"kind": "vibes"}]}
      (_, unknown) = parseProposal(record_sign, "", odd, directory_sign)
      (_, untitled) = parseProposal(
        "Why.\n",
        "",
        %*{"status": "proposed", "builds_on": [], "claims": []},
        directory_sign,
      )
      (_, broken) = parseProposal(record_sign, "", nil, directory_sign)
    check unknown.len == 1 and "`vibes`" in unknown[0].message  # never skipped in silence
    check untitled.len == 1 and untitled[0].path == directory_sign & "/proposal.md"  # needs title
    check broken.len == 1 and broken[0].path == directory_sign & "/claims.json"  # needs object


  test "suites or program claim builds with its defines, and defines elsewhere are findings":
    let
      defined = %*{"status": "proposed", "builds_on": [], "claims": [
        {"kind": "suites", "defines": ["pga.float_width=32"]},
        {"kind": "program", "path": "p.nim", "algebras": ["rga4d"], "defines": ["a=1", "b=2"]}]}
      (proposal, findings) = parseProposal(record_sign, "", defined, directory_sign)
      misplaced = %*{"status": "proposed", "builds_on": [], "claims": [
        {"kind": "tables", "pairs": [], "algebras": ["rga4d"], "defines": ["a=1"]}]}
      unformed = %*{"status": "proposed", "builds_on": [], "claims": [
        {"kind": "suites", "defines": ["pga.float_width"]}, {"kind": "suites", "defines": "a=1"}]}
    check findings.len == 0 and proposal.claims.len == 2  # both kinds take defines
    check flagsDefine(proposal.claims[0]) == @["-d:pga.float_width=32"]  # spelled as flag
    check flagsDefine(proposal.claims[1]) == @["-d:a=1", "-d:b=2"]  # in order named
    check flagsDefine(%*{"kind": "suites"}).len == 0  # claim naming none builds as default
    check parseProposal(record_sign, "", misplaced, directory_sign)[1].len == 1  # other kind
    check parseProposal(record_sign, "", unformed, directory_sign)[1].len == 2  # each form


  test "path without number, title without citation and unknown status are findings":
    let
      claims = %*{"status": "proposed", "builds_on": [], "claims": []}
      (_, unnumbered) = parseProposal(record_sign, "", claims, "proposals/sign")
      (_, uncited) = parseProposal("# Sign\n" & shape, "", claims, directory_sign)
      (_, unplaced) =
        parseProposal(
          record_sign,
          "",
          %*{"status": "dreamt", "builds_on": [], "claims": []},
          directory_sign,
        )
    check unnumbered.len == 2  # path lacks number, so title cites none it could match
    check "`01-sign`" in unnumbered[0].message  # names form path needs
    check uncited.len == 1 and "`P01: `" in uncited[0].message  # title opens with citation
    check unplaced.len == 1 and "`dreamt`" in unplaced[0].message  # three statuses only


  test "implemented proposal needs its commit, and implemented or withdrawn is frozen":
    let
      (bare, why) = parseProposal(
        record_sign,
        "",
        %*{"status": "implemented", "builds_on": [], "claims": []},
        directory_sign,
      )
    check why.len == 1 and "`implemented_in`" in why[0].message  # commit it landed in
    check bare.isImplemented and bare.isFrozen  # frozen as well
    check numbered(1, "withdrawn").isFrozen and not numbered(1, "withdrawn").isImplemented
    check numbered(1, "implemented").implemented_in == "abc"  # commit read from claims


  test "numbers are unique and gapless, so none is freed or taken twice":
    check checkNumbers([numbered(1), numbered(2)]).len == 0  # one, then two
    check checkNumbers([numbered(1), numbered(1)]).len == 1  # taken twice
    let skipped = checkNumbers([numbered(1), numbered(3)])
    check skipped.len == 1 and "`P02`" in skipped[0].message  # two was freed


  test "builds on must list names, and absent list is finding, since proposal states its bases":
    let
      (_, single) = parseProposal(
        record_sign,
        "",
        %*{"status": "proposed", "builds_on": "base", "claims": []},
        directory_sign,
      )
      (_, silent) =
        parseProposal(record_sign, "", %*{"status": "proposed", "claims": []}, directory_sign)
    check single.len == 1 and "`\"base\"`" in single[0].message  # string is no list
    check silent.len == 1 and "`none`" in silent[0].message  # silence states nothing


  test "dependencies come each after its bases, once, so diamond applies four changes in order":
    let
      diamond = [numbered(1), numbered(2, bases = @[1]), numbered(3, bases = @[1]),
        numbered(4, bases = @[3, 2])]
      (order, findings) = dependencies(diamond, diamond[3])
    check findings.len == 0 and order.mapIt(it.name) == @["p1", "p3", "p2"]  # base first, once
    check dependencies(diamond, diamond[0])[0].len == 0  # root needs nothing
    check dependents(diamond, diamond[0]).mapIt(it.name) == @["p2", "p3", "p4"]  # downstream
    check dependents(diamond, diamond[2]).mapIt(it.name) == @["p4"]  # through one edge
    check dependents(diamond, diamond[3]).len == 0  # leaf blocks nothing
    check basesToward(diamond, diamond[3], diamond[0]).mapIt(it.name) == @["p2", "p3"]
      # reached through both, in number order
    check basesToward(diamond, diamond[3], diamond[1]).len == 0  # direct base needs no path


  test "implemented base drops out, and cycle, unknown or withdrawn base is finding":
    let
      landed = [numbered(1, "implemented"), numbered(2, bases = @[1])]
      looped = [numbered(1, bases = @[2]), numbered(2, bases = @[1])]
      lost = [numbered(1, bases = @[7])]
      dropped = [numbered(1, "withdrawn"), numbered(2, bases = @[1])]
      (cycle, why_cycle) = dependencies(looped, looped[0])
      (_, why_lost) = dependencies(lost, lost[0])
      (_, why_dropped) = dependencies(dropped, dropped[1])
    let (held, why_held) = dependencies(landed, landed[1])
    check held.len == 0 and why_held.len == 0  # library holds base
    check dependents(landed, landed[0]).len == 0  # rejecting landed one blocks nothing
    check cycle.mapIt(it.name) == @["p2"] and why_cycle.len == 1  # walk stops, once
    check "cycle" in why_cycle[0].message and why_cycle[0].path == looped[0].directory
    check why_lost.len == 1 and "`p7`" in why_lost[0].message  # names unknown base
    check why_dropped.len == 1 and "`P01`" in why_dropped[0].message  # cites withdrawn one



suiteInProc "Internal: Evaluations":
  func run(ns: openArray[(string, float, float)]): JsonNode =
    ## Build one bench run: library median and NaN share per measurand.
    result = %*{"measurands": {}}
    for (id, time, nan) in ns:
      result["measurands"][id] = %*{"library": {"ns_median": time, "share_nan": nan}}


  test "evaluation measures 3D algebras, and all four only when thorough":
    check algebrasEvaluated(false) == @["rga4d", "cga5d"]  # default, 3D Euclidean
    check algebrasEvaluated(true) == @["rga4d", "cga5d", "rga3d", "cga4d"]  # thorough adds


  test "library read refuses checkout that holds no Nim file":
    let
      missing = getTempDir() / "pga_benchmark_library_missing"
      empty = getTempDir() / "pga_benchmark_library_empty"
    removeDir missing
    createDir empty
    expect IOError:
      discard readLibrary(missing)  # page would quote no line of library
    expect IOError:
      discard readLibrary(empty)  # checkout that failed to restore
    removeDir empty


  test "times pair runs by measurand, median of ratios, rounded":
    let
      before = @[run([("a", 10.0, 0.0)]), run([("a", 12.0, 0.0)]), run([("a", 11.0, 0.0)])]
      after = @[run([("a", 5.0, 0.0)]), run([("a", 6.0, 0.0)]), run([("a", 5.5, 0.0)])]
      times = pairTimes(before, after)
    check times["a"][0].getFloat == 11.0 and times["a"][1].getFloat == 5.5  # medians
    check times["a"][2].getFloat == 0.5  # ratio of each run, then median


  test "NaN shares that moved are kept, and only those":
    let
      before = @[run([("norm", 1.0, 0.5), ("wedge", 1.0, 0.0)])]
      after = @[run([("norm", 1.0, 0.0), ("wedge", 1.0, 0.0)])]
      moved = compareNan(before, after)
    check moved.len == 1 and moved["norm"][0].getFloat == 0.5  # signed root clears NaN
    check not moved.hasKey("wedge")  # unmoved measurand left out


  test "compiler success line gives seconds and peak memory":
    let output = "......\nHint: mm: orc\n29867 lines; 0.213s; 38.008MiB peakmem; proj: a.nim; " &
        "out: a.json [SuccessX]\n"
    check compileCost(output) == (0.213, 38.008)  # both read
    check compileCost("Error: type mismatch\n") == (0.0, 0.0)  # failed build reads nothing


  test "build claim compiles library alone, so no module of harness sets its peak":
    for line in ENTRY_LIBRARY.splitLines:
      check line.len == 0 or line == "import pga"  # inspector change once moved P01 to ×0.76


  test "function on one side only is null on other, so document prints":
    let
      counts = %*{"total": {"multiplies": 3}, "movement": {"bytes_moved": 8}}
      before = %*{"functions": {"f(M)": counts}}
      after = %*{"functions": {"f(M)": counts, "g(M)": counts}}
      moved = functionsChanged(before, after)
    check moved.len == 1 and moved["g(M)"]["before"].kind == JNull  # new function
    check functionsChanged(after, before)["g(M)"]["after"].kind == JNull  # gone function
    check pretty(moved).len > 0  # prints, where nil node crashed


  test "dense form changed build leaves out is no moved function, where one it holds still is":
    let
      counts = %*{"total": {"multiplies": 3}, "movement": {"bytes_moved": 8}}
      other = %*{"total": {"multiplies": 4}, "movement": {"bytes_moved": 8}}
      before = %*{"functions": {"f(M)": counts, "denseF(M)": counts},
        "measurands": {"f": {"library": "f(M)", "dense": "denseF(M)"}}}
      left_out = %*{"functions": {"f(M)": counts}}
      held = %*{"functions": {"f(M)": counts, "denseF(M)": other}}
    check functionsChanged(before, left_out).len == 0  # built without dense forms by design
    check functionsChanged(before, held).len == 1  # dense form built and moved


  test "digest moves with edits, claims and programs, and never with prose":
    let
      edit = Edit(path: "pga/a.nim", quote: "x", replacement: "y")
      one = Change(title: "One", edits: @[edit])
      reworded = Change(title: "Other words", edits: @[edit])
      claims = %*[{"kind": "suites"}]
    check digestEdits([one], claims, @[]) == digestEdits([reworded], claims, @[])  # prose
    check digestEdits([one], claims, @[]) != digestEdits([one], %*[], @[])  # claims
    check digestEdits([one], claims, @["a"]) != digestEdits([one], claims, @["b"])  # program



suiteInProc "Internal: Figures":
  test "figure is one image alone, path resolved against proposal's directory":
    let
      node = Block(
        kind: KindBlock.Paragraph,
        line: 3,
        lines: @["![Map. Each arrow is one", "rule.](../../pages/map.svg)"],
      )
      figure = node.figure("proposals/01-cayley-derivation")
      inline = Block(kind: KindBlock.Paragraph, lines: @["See ![map](map.svg) here."])
    check figure.isSome and figure.get.path == "pages/map.svg"  # `..` folded
    check figure.get.caption == "Map. Each arrow is one rule." and figure.get.line == 3  # joined
    check inline.figure("proposals/01-p").isNone  # image inside sentence stays text


  test "proposal page names each define its claims build with":
    let
      record = Proposal(number: 1, name: "p", directory: "proposals/01-p", title: "P",
        claims: newJArray())
      evaluation = %*{"algebras": {}, "claims": [
        {"kind": "suites", "defines": ["pga.float_width=32"], "passed": true, "detail": []},
        {"kind": "program", "path": "w.nim", "algebras": ["rga4d"], "passed": true,
          "detail": []}]}
      body = bodyProposal(
        record,
        [record],
        evaluation,
        initTable[string, string](),
        initTable[string, string](),
        initTable[string, JsonNode](),
        Spread(),
        initTable[string, string](),
        "bd6b23c590d7",
        "",
      )
    check ("changed library, with " & code("pga.float_width=32")) in body  # define named
    check ("runs clean at rga4d</li>") in body  # claim naming none reads as before


  test "proposal page embeds SVG figure names, with caption beneath":
    let
      node = Block(kind: KindBlock.Paragraph, lines: @["![Map.](../../pages/map.svg)"])
      record = Proposal(
        number: 1,
        name: "p",
        directory: "proposals/01-p",
        title: "P",
        body: @[node],
        claims: newJArray(),
      )
      figures = {"pages/map.svg": "<svg id=\"m\"></svg>"}.toTable
      body = bodyProposal(
        record,
        [record],
        nil,
        initTable[string, string](),
        figures,
        initTable[string, JsonNode](),
        Spread(),
        initTable[string, string](),
        "bd6b23c590d7",
        "",
      )
      bare = bodyProposal(
        record,
        [record],
        nil,
        initTable[string, string](),
        initTable[string, string](),
        initTable[string, JsonNode](),
        Spread(),
        initTable[string, string](),
        "bd6b23c590d7",
        "",
      )
    check "<div class=\"figure-art\"><svg id=\"m\"></svg></div><figcaption>Map.</figcaption>" in
        body  # SVG whole, caption beneath
    check "<figure" notin bare and "Map." in bare  # absent file renders as text


  test "proposal page opens with summary card, then five sections, then code and evidence apart":
    let
      record = Proposal(
        number: 1,
        name: "p",
        directory: "proposals/01-p",
        title: "P",
        body: parseBlocks("**What it is.** It.\n\n**What it is for.** For.\n\n" &
          "**What it costs.** Cost.\n\n## Problem\n\nWhy.\n\n## Landing\n\nAfter P02.\n\n" &
          "## Laws\n\nArgument.\n"),
        claims: newJArray(),
      )
      body = bodyProposal(
        record,
        [record],
        nil,
        initTable[string, string](),
        initTable[string, string](),
        initTable[string, JsonNode](),
        Spread(),
        initTable[string, string](),
        "bd6b23c590d7",
        " · <a href=\"u\">docket</a>",
      )
    check "<dl class=\"summary\"><div><dt>What it is</dt><dd>It.</dd></div>" in body  # labelled
    check body.find("</dl>") < body.find("id=\"p-problem\"")  # card before sections
    var at = 0
    for (mark, name) in [("1", "problem"), ("2", "idea"), ("3", "alternatives"), ("4", "costs"),
        ("5", "open-decisions"), ("A", "code"), ("B", "evidence")]:
      let found = body.find("id=\"p-" & name & "\"><h2><span class=\"num\">" & mark)
      check found > at  # each section marked, in order
      at = found
    check "<section class=\"block prose appendix\" id=\"p-code\">" in body  # appendix opens
    check body.find("After P02.") > body.find("id=\"p-code\"")  # landing inside code
    check body.find("Argument.") > body.find("id=\"p-evidence\"")  # other section last
    check body.find("<footer class=\"pages\"><a href=\"u\">docket</a></footer>") > at  # links last


  test "P01 links library map where it is published, and map shows every rule of P01":
    const
      argument = staticRead("../proposals/01-cayley-derivation/proposal.md")
      svg = staticRead("../pages/derivation-map.svg")
      published = staticRead("../pages/published.json")
    let url = parseJson(published){"progress", "url"}.getStr
    check url.len > 0 and "](" & url & ")" in argument  # P01 links map at its publication
    for rule in ["constructAnti", "applyMap", "applyConstant", "constructProductsTransitional"]:
      check rule in svg  # each of three rules marks its line or box



suiteInProc "Internal: Edits":
  const source_pin = "func outer*(a: int;\n    b: int): int {.inline.} =\n  ## Doc.\n" &
      "  for x in 0 ..< a:\n    result += x\n\nimport std/math\n"
    ## Library file at pin: routine whose signature spans two lines, then top-level import.

  func edit(quote, replacement: string; digest = ""): Change =
    ## Build change of one edit to `pga/a.nim`: whole-file replacement where digest is given.
    let kind = if digest.len > 0: KindEdit.Replace else: KindEdit.Quote
    Change(edits: @[Edit(kind: kind, path: "pga/a.nim", quote: quote, replacement: replacement,
      digest: digest)])

  let files = {"pga/a.nim": source_pin}.toTable
    ## Library files edits read their line and context from.


  test "edit renders open as diff under list of files, naming routine it sits in at pin":
    let
      html = htmlEdits(edit("    result += x\n", "    result -= x\n"), files)
      counts = "<span class=\"removed\">-1</span> <span class=\"added\">+1</span>"
    check html.startsWith("<ul class=\"files\"><li><code>pga/a.nim</code> " & counts)  # files
    check "<details class=\"edit\" open><summary>" in html  # open
    check "<code>pga/a.nim:5</code> · " & counts in html  # where, and how much
    check "inside</span><code>func outer*(a: int; b: int): int</code>" in html  # joined, bare
    check "<tr class=\"removed\"><td class=\"ln\">5</td><td class=\"ln\"></td>" &
        "<td class=\"sign\">-</td><td class=\"text\">    result += x</td></tr>" in html  # before
    check "<tr class=\"added\"><td class=\"ln\"></td><td class=\"ln\">5</td>" &
        "<td class=\"sign\">+</td><td class=\"text\">    result -= x</td></tr>" in html  # after


  test "diff keeps context beside change and folds longer unchanged run to its count":
    var lines: seq[string]
    for index in 1..20: lines.add "let x" & $index & " = " & $index
    var changed = lines
    changed[9] = "let x10 = 0"
    let
      quote = lines.join("\n")
      html = htmlEdits(edit(quote, changed.join("\n")), {"pga/a.nim": quote & "\n"}.toTable)
    check "<tr class=\"fold\"><td colspan=\"4\">6 unchanged lines</td></tr>" in html  # head
    check "<tr class=\"fold\"><td colspan=\"4\">7 unchanged lines</td></tr>" in html  # tail
    check ">let x7 = 7<" in html and ">let x13 = 13<" in html  # three lines beside change
    check ">let x6 = 6<" notin html and ">let x14 = 14<" notin html  # rest folded
    check html.find(">let x10 = 10<") < html.find(">let x10 = 0<")  # removal before addition


  test "new file renders every line added, numbered from one":
    let
      change = Change(
        edits: @[
          Edit(kind: KindEdit.Add, path: "pga/b.nim", replacement: "let a = 1\nlet b = 2\n"),
        ],
      )
      html = htmlEdits(change, files)
    check "adds <code>pga/b.nim</code> · <span class=\"removed\">-0</span>" in html  # where
    check "<td class=\"ln\"></td><td class=\"ln\">2</td><td class=\"sign\">+</td>" &
        "<td class=\"text\">let b = 2</td>" in html  # numbered after alone


  test "edit inside routine whose header closes at its own indent names that routine":
    let
      source = "macro define(\n  symbols: string;\n): untyped =\n  ## Doc.\n  var x = 1\n"
      html = htmlEdits(edit("  var x = 1\n", "  var x = 2\n"), {"pga/a.nim": source}.toTable)
    check "inside</span><code>macro define(symbols: string): untyped</code>" in html  # as pga


  test "edit that defines routines lists their signatures, nested ones left out":
    let
      replacement = "func added(x: int): int =\n  func helper(): int = 1\n  x + helper()\n\n" &
          "test \"adds\":\n  check added(1) == 2\n"
      html = htmlEdits(edit("import std/math\n", replacement), files)
    check "defines</span><code>func added(x: int): int</code><code>test &quot;adds&quot;</code>" in
        html  # outer routine and test, body dropped
    check "helper" notin html.split("</summary>")[0]  # nested routine stays in body


  test "whole-file replacement lists signatures file lacked, operators and pragmas kept apart":
    let
      replacement = "func `==`(a, b: Order): bool {.borrow.}\nproc b*(x: int) =\n  discard\n"
      html = htmlEdits(edit("", replacement, "abc"), files)
    check "<code>func `==`(a, b: Order): bool</code><code>proc b*(x: int)</code>" in html  # bare
    let kept = htmlEdits(edit("", source_pin & replacement, "abc"), files)
    check "func outer" notin kept.split("</summary>")[0]  # signature file held is left out
    check "class=\"signatures\"" notin htmlEdits(edit("import std/math\n", "import std/os\n"),
      files)  # top-level statement sits in no routine



  test "code folds each file, shows signature and doc of each change, and folds its body":
    let
      source = "func f*(): int =\n  ## Doc f.\n  1\n\nfunc h(): int = 3\n"
      change = Change(edits: @[
        Edit(kind: KindEdit.Quote, path: "pga/b.nim", quote: "  1\n", replacement: "  2\n"),
        Edit(kind: KindEdit.Quote, path: "pga/b.nim", quote: "func h(): int = 3\n",
          replacement: "func g(): int =\n  ## Doc g.\n  4\n"),
      ])
      html = htmlCode(change, {"pga/b.nim": source}.toTable)
    check html.startsWith("<details class=\"file\"><summary><code>pga/b.nim</code>")  # closed
    check "1 changed · 1 added · 1 removed" in html  # tally of definitions
    check "<details class=\"body\"><summary>body · 1 line · " in html  # body folded, counted
    check " open><summary>body" notin html  # every body closed at rest
    check html.find("Doc f.") < html.find("<details class=\"body\">")  # doc above body
    check html.find("badge removed") < html.find("badge added")  # removal before addition


  test "added file names its status once, and runs bare lines as one block":
    let
      change = Change(edits: @[Edit(kind: KindEdit.Add, path: "pga/n.nim",
        replacement: "import std/math\nimport std/strutils\n\nfunc k*(): int =\n" &
          "  ## Doc k.\n  5\n")])
      html = htmlCode(change, initTable[string, string]())
    check "<span class=\"status\">added</span>" in html  # file says it is new
    check "class=\"badge" notin html  # each definition says it no more
    check html.count("<div class=\"definition added\">") == 2  # imports together, then routine


  test "change outside every definition shows as other lines":
    let html = htmlCode(
      Change(edits: @[Edit(kind: KindEdit.Quote, path: "pga/c.nim", quote: "# TODO: one.\n",
        replacement: "# TODO: two.\n")]),
      {"pga/c.nim": "# TODO: one.\nfunc z(): int = 0\n"}.toTable,
    )
    check "other lines</span>" in html and "TODO: two." in html  # comment reaches page
    check "definition changed" notin html  # routine beside it is unchanged


  test "evidence shows one row per function that moved, gains first, and counts rest":
    let
      baselines = {"rga4d": %*{"measurands": {
        "a": {"library": "f(M)", "symbol": "∧"}, "b": {"library": "f(M)", "symbol": "∧"},
        "c": {"library": "g(M)", "symbol": "∨"}, "d": {"library": "k(M)", "symbol": "∙"}}}}.toTable
      counts = %*{"multiplies": 10, "bytes_moved": 100}
      evaluation = %*{"pin_suites": {"rga4d": {"ok": 3, "failed": 0}}, "algebras": {"rga4d": {
        "suites": {"ok": 3, "failed": 0},
        "functions": {
          "f(M)": {"before": counts, "after": {"multiplies": 5, "bytes_moved": 50}},
          "g(M)": {"before": counts, "after": counts},
          "k(M)": {"before": counts, "after": {"multiplies": 20, "bytes_moved": 100}},
          "h(M)": {"before": counts, "after": counts}},
        "times": {"a": [10.0, 5.0, 0.5], "b": [10.0, 6.0, 0.6], "c": [10.0, 10.0, 1.0],
          "d": [10.0, 15.0, 1.5]}}}}
      html = htmlEvidence(evaluation, baselines, Spread(low: 0.9, high: 1.1, count: 30))
    check html.count("<tr><td>") == 2  # f and k; g stayed within spread
    check html.find("<code>f(M)</code>") < html.find("<code>k(M)</code>")  # gain before loss
    check "<span class=\"serves\">a, b</span>" in html  # operations f serves, named once
    check "class=\"gain\"" in html and "class=\"loss\"" in html  # each side drawn
    check "1 operation whose function moved stayed within spread." in html  # rest counted
    check "Other functions moved: <code>h(M)</code>." in html  # helper named


suiteInProc "Internal: Search":
  test "row shows while its words hold every word typed, case folded in ASCII":
    const words = "wedge_point_point g007 ∧ wedge point"
    check isFound(words, "")  # nothing typed shows every row
    check isFound(words, "  ")  # blanks alone are no word
    check isFound(words, "WEDGE")  # case folds, as row words do
    check isFound(words, "g00 ∧")  # each word may be part of one
    check not isFound(words, "wedge dot")  # one word missing hides row
    check not isFound(words, "Ⅹ")  # symbol absent hides row



suiteInProc "Internal: Cells":
  test "table reads cell for cell, sign included, in both cell shapes":
    let wedge = cells(CAYLEYS_WEDGE.base)
    check wedge["E1,E2"] == %*[{"to": "E12", "neg": false}]  # 𝐞₁ ∧ 𝐞₂ = 𝐞₁₂
    check wedge["E2,E1"] == %*[{"to": "E12", "neg": true}]  # antisymmetric
    check not wedge.hasKey("E1,E1")  # vector wedge itself vanishes
    check cells(CAYLEY_ATTITUDE).len > 0  # 1D table reads too



suiteInProc "Internal: Pages":
  let ids_docket = %*{"ids": {"rga4d/wedge": "G001", "rga4d/wedge_point_point": "G002"}}
    ## Docket file allotting both rows of `sheetDocket`.

  func sheetDocket(multiplies_library, multiplies_reference: int; runtime: JsonNode): Sheet =
    ## Build one algebra: general and typed wedge over one library function, bound of 54.
    let bound = %*{"multiplies": 54, "bytes_moved": 384, "shape": "Wedge", "is_chain": false}
    Sheet(
      name: "rga4d",
      title: "Rigid 4D",
      dimensions: 4,
      measurements_static: %*{
        "measurands": {
          "wedge": {"library": "∧(M,M)", "dense": "denseWedge(M,M)", "symbol": "∧",
            "bound": bound},
          "wedge_point_point": {"library": "∧(M,M)", "reference": "wedge(P,P)", "symbol": "∧",
            "bound": bound},
        },
        "functions": {
          "∧(M,M)": {"total": {"multiplies": multiplies_library},
            "movement": {"bytes_moved": 512}},
          "wedge(P,P)": {"total": {"multiplies": multiplies_reference},
            "movement": {"bytes_moved": 112}},
        },
      },
      measurements_runtime: %*{"taken": {"date": "d", "machine": "m"}, "measurands": runtime},
    )


  test "shell names font faces it embeds, and assembly fills every token":
    let
      text_shell =
        "<title>@TITLE@</title><style>src: url(@EMBED:a.woff2@) url(@EMBED:b.ttf@)</style>@BODY@"
      page = assemble(
        text_shell,
        "A & B",
        "<p>body</p>",
        {"a.woff2": "xyz", "b.ttf": "uvw"}.toTable,
      )
    check fontFacesAsked(text_shell) == @["a.woff2", "b.ttf"]  # both font faces asked, in order
    check "@" notin page and "A &amp; B" in page and "<p>body</p>" in page  # filled
    check "data:font/woff2;base64,eHl6" in page  # WOFF2 bytes inlined as WOFF2
    check "data:font/ttf;base64,dXZ3" in page  # TrueType bytes inlined as TrueType


  test "page renders inside skeleton publish host serves, and carries none of its own":
    const shell_html = staticRead("../pages/shell.html")
    let
      page = "<title>T</title><p>∧</p>"
      document = hosted(page)
      (opening, closing) = SKELETON_HOST
    check document.startsWith("<!doctype html>")  # standards mode, as host serves it
    check "<meta charset=\"utf-8\">" in opening  # page's text read as UTF-8
    check "name=\"viewport\"" in opening  # phone width laid out as on host
    check document[opening.len .. ^(closing.len+1)] == page  # page whole, unchanged
    check opening.endsWith("<body>") and closing.startsWith("</body>")  # page inside body
    for tag in ["<!doctype", "<html", "<head", "<body", "<meta"]:
      check tag notin shell_html.toLowerAscii  # shell holds no skeleton, so none doubles


  test "bold letter with bar mark is boxed with its mark, and tags, SVG and script pass as are":

    func stripped(html: string): string =
      ## Drop tags, leaving text reader copies.
      var is_tag = false
      for c in html:
        if c == '<': is_tag = true
        elif c == '>': is_tag = false
        elif not is_tag: result.add c

    const shell_html = staticRead("../pages/shell.html")
    let
      prose = "<p>Below, 𝐜̱ is left, (𝐜̄∧𝐚) right, and 𝐆̲𝐦̲̅ both.</p>"
      marked = htmlMarked(prose)
      kept = "<svg><text>𝐜̱</text></svg><script>let a = \"𝐜̱\"</script><p title=\"𝐜̱\">c̄</p>"
    check "<span class=\"word\"><span class=\"mark under\">𝐜̱</span></span>" in marked
      # bar under, mark kept in box
    check "<span class=\"word\">(<span class=\"mark over\">𝐜̄</span>∧𝐚)</span>" in marked
      # whole word kept on one line
    check "<span class=\"mark under tall\">𝐆̲</span><span class=\"mark under over\">𝐦̲̅</span>" in
        marked  # capital is tall, two marks draw two bars
    check "over tall" in htmlMarked("𝐛̄") and "tall" notin htmlMarked("𝐞̄")  # ascender only
    check stripped(marked) == stripped(prose)  # text reader copies is text source holds
    check htmlMarked(kept) == kept  # SVG, script, attribute and Latin letter pass as they are
    for rule in [".mark.under::after", ".mark.over::before", ".mark.over.tall::before", ".word"]:
      check rule in shell_html  # shell draws each box marking makes


  test "every Noto font face ships whole, as TrueType of its own release":
    for font_face in FONT_FACES:
      if font_face.toLowerAscii.startsWith("noto"):
        check font_face.endsWith(".ttf")  # Article X.8: Noto font face whole, never subset


  test "spread is assumed until quiet evaluations give enough ratios":
    let quiet = %*{"algebras": {"rga4d": {"functions": {}, "times": {"a": [1.0, 1.0, 1.0]}}}}
    check spread([quiet]).count == 0  # too few ratios: spread assumed
    check spread([quiet]).low < 1.0 and spread([quiet]).high > 1.0  # around no change


  test "every grid in shell and docket bounds its columns, so wide content scrolls in place":
    const shell_html = staticRead("../pages/shell.html")
    let
      docket = bodyDocket([sheetDocket(81, 12, %*{})], ids_docket, [], "bd6b23c590d7", "")
      style_docket = docket.split("<style>")[1].split("</style>")[0]
    var unbounded: seq[string]
    for rule in (shell_html & style_docket).split('}'):
      let body = rule.split('{')
      if body.len < 2 or "display: grid" notin body[^1]: continue
      if "grid-template-columns" notin body[^1]: unbounded.add body[^2].strip
    checkpoint "unbounded: " & unbounded.join(", ")
    check unbounded.len == 0  # grid child of auto width widens page at phone width


  test "rule through class and bare tag never outranks one-class rule of element it reaches":
    # Case: Performance summary drew its bars over each other at 1100 px, as Architect found.
    #   Shell's `.summary div`, written for proposal page's summary card, reached docket's
    #   `div.summary` too, and outranked `.aggregate`, `.bars` and `.bar` on their columns.
    # Domain: every element docket and proposal page draw, under every rule they ship.
    const
      shell_html = staticRead("../pages/shell.html")
      characters_name = {'a'..'z', '0'..'9', '-', '_'}  # Class name, as pages spell it.
      characters_tag = {'a'..'z', '0'..'9'}
      tags_void = ["br", "hr", "img", "input", "link", "meta", "source", "wbr"]

    func rules(css: string):
        (Table[string, seq[string]], seq[tuple[name, tag: string, properties: seq[string]]]) =
      ## Read properties of each one-class rule by class, and each rule through class and tag.
      ##   Rule inside `@media` counts as one outside, since either can apply.
      var
        text = css
        start = text.find("/*")
      while start >= 0:
        text.delete(start .. text.find("*/", start) + 1)
        start = text.find("/*")
      for rule in text.split('}'):
        let parts = rule.split('{')
        if parts.len < 2: continue
        let properties = parts[^1].split(';').mapIt(it.split(':')[0].strip).filterIt(it.len > 0)
        for selector in parts[^2].split(','):
          let words = selector.splitWhitespace
          if words.len == 0 or words.len > 2 or not words[0].startsWith('.'): continue
          let name = words[0][1..^1]
          if not name.allCharsInSet(characters_name): continue
          if words.len == 1: result[0].mgetOrPut(name, @[]).add properties
          elif words[1].allCharsInSet(characters_tag): result[1].add (name, words[1], properties)

    func outranked(body, css: string): seq[string] =
      ## Name each property rule through ancestor's class and bare tag takes from element's own
      ##   one-class rule, as `.summary div` over `.bar` on `display`.
      ##   Class and tag outrank one class, so own rule loses wherever both set property.
      let (rules_class, rules_tag) = rules(css)
      var
        open: seq[tuple[tag: string, classes: seq[string]]]  # Elements open, outermost first.
        at = body.find('<')
      while at >= 0:
        let
          stop = body.find('>', at)
          inside = body[at+1..<stop]
        at = body.find('<', stop)

        # Close innermost open element of tag; skip comment and doctype.
        if inside.startsWith('/'):
          var index = open.high
          while index >= 0 and open[index].tag != inside[1..^1]: dec index
          if index >= 0: open.setLen(index)
          continue
        if inside.startsWith('!'): continue

        # Read tag and classes; script and style hold no element.
        let
          tag = inside.splitWhitespace[0]
          start = inside.find(" class=\"")
          classes =
            if start < 0: @[]
            else: inside[start+8..<inside.find('"', start + 8)].splitWhitespace
        if tag in ["script", "style"]: at = body.find("</" & tag, stop)

        # Gather what ancestors' rules set on tag, then name what element's own rules lose.
        var reaching: seq[(string, string)]
        for (_, classes_ancestor) in open:
          for (name, tag_rule, properties) in rules_tag:
            if tag_rule != tag or name notin classes_ancestor: continue
            for property in properties: reaching.add ("." & name & " " & tag, property)
        for name in classes:
          for (rule, property) in reaching:
            if property notin rules_class.getOrDefault(name): continue
            result.add "`" & rule & "` over `." & name & "` on `" & property & "`"
        if tag notin tags_void and tag notin ["script", "style"]: open.add (tag, classes)
      result = result.deduplicate

    func styles(body: string): string =
      ## Read rules page carries in its own `style` elements.
      for part in body.split("<style>")[1..^1]: result.add part.split("</style>")[0] & "\n"

    let
      overlay = Overlay(
        name: "p",
        title: "P01: P",
        url: "u",
        functions: {"rga4d": %*{"∧(M,M)": {"after": {"multiplies": 54, "bytes_moved": 384}}}}
          .toTable,
      )
      docket = bodyDocket([sheetDocket(81, 12, %*{})], ids_docket, [overlay], "bd6b23c590d7", "")
      record = Proposal(
        number: 1,
        name: "p",
        directory: "proposals/01-p",
        title: "P",
        body: parseBlocks("**What it is.** It.\n\n## Problem\n\nWhy.\n"),
        claims: newJArray(),
      )
      proposal = bodyProposal(
        record,
        [record],
        nil,
        initTable[string, string](),
        initTable[string, string](),
        initTable[string, JsonNode](),
        Spread(),
        initTable[string, string](),
        "bd6b23c590d7",
        "",
      )
    for body in [docket, proposal]:
      let found = outranked(body, shell_html & styles(body))
      checkpoint "outranked: " & found.join(", ")
      check found.len == 0  # own rule of element holds, so no page's rule reshapes another's
    check "<dl class=\"summary\">" in proposal  # proposal page's card still read


  test "every stack holds each family of sans stack before any family shell does not ship":
    const shell_html = staticRead("../pages/shell.html")
    var shipped, gaps: seq[string]
    for rule in shell_html.split("@font-face")[1..^1]:
      let family = rule.split('"')[1]
      if family notin shipped: shipped.add family
    var stacks: seq[seq[string]]  # sans first, then serif and mono
    for name in ["sans", "serif", "mono"]:
      let
        at = shell_html.find("--" & name & ": ") + name.len + 4
        families = shell_html[at..<shell_html.find(';', at)].split(',')
      stacks.add @[]
      for family in families:
        let bare = family.strip.strip(chars = {'"'})
        if bare notin shipped: break
        stacks[^1].add bare
    for stack in stacks[1..^1]:
      for family in stacks[0]:
        if family notin stack: gaps.add stack[0] & " stack lacks " & family
    checkpoint "gaps: " & gaps.join(", ")
    check gaps.len == 0  # Article X.8: stack falls to font face page ships, never to system


  test "docket rows carry identifiers docket file allots":
    let
      sheet = Sheet(
        name: "rga4d",
        title: "Rigid 4D",
        dimensions: 4,
        measurements_static: %*{"measurands": {"wedge": {"library": "∧(M,M)", "symbol": "∧"}},
          "functions": {"∧(M,M)": {"total": {"multiplies": 81}}}},
        measurements_runtime: %*{"taken": {"date": "d", "machine": "m"}, "measurands": {}},
      )
      ids = %*{"schema": 1, "kind": "docket", "next": 8, "ids": {"rga4d/wedge": "G007"}}
    check "G007 · ∧" in bodyDocket([sheet], ids, [], "bd6b23c590d7", "")  # shown beside symbol


  test "docket measures typed row against reference, general row against multivector bound":
    let
      body = bodyDocket([sheetDocket(81, 12, %*{})], ids_docket, [], "bd6b23c590d7", "")
    check "library 81 multiplies, reference 12, multivector lower bound 54\"" in body  # typed
    check "library 81 multiplies, multivector lower bound 54\"" in body  # general, no tick
    check ">×6.75<" in body and ">×1.50<" in body  # each over what it is measured against
    check body.count("<b style=") == 2  # tick at multivector bound, typed row only, both counts


  test "header names each date runs were taken on, with algebras timed then":
    var later = sheetDocket(81, 12, %*{})
    later.name = "rga3d"
    later.title = "Rigid 3D"
    later.measurements_runtime["taken"]["date"] = %"e"
    let
      both = bodyDocket([sheetDocket(81, 12, %*{}), later], ids_docket, [], "bd6b23c590d7", "")
      one = bodyDocket([sheetDocket(81, 12, %*{})], ids_docket, [], "bd6b23c590d7", "")
    check "time d for Rigid 4D, e for Rigid 3D, m" in both  # each algebra under its own date
    check "time d, m" in one  # one date stays plain


  test "time bar is median of run ratios, and each run is one tick":
    let
      runs = %*{"wedge_point_point": {
        "library": {"ns_median": 11.0, "share_nan": 0.0, "ns_runs": [12.0, 10.0, 11.0]},
        "reference": {"ns_median": 4.0, "share_nan": 0.0, "ns_runs": [4.0, 5.0, 3.0]}}}
      body = bodyDocket([sheetDocket(81, 12, runs)], ids_docket, [], "bd6b23c590d7", "")
    check ">×3.00<" in body  # median of 3.00, 2.00 and 3.67; ratio of medians reads 2.75
    check "runs ×3.00 ×2.00 ×3.67" in body  # each run named, in run order
    check body.count("<s style=") == 3  # one tick for each run


  test "general row times against its dense form":
    let
      runs = %*{"wedge": {
        "library": {"ns_median": 8.5, "share_nan": 0.0, "ns_runs": [8.0, 9.0]},
        "dense": {"ns_median": 3.5, "share_nan": 0.0, "ns_runs": [4.0, 3.0]}}}
      body = bodyDocket([sheetDocket(81, 12, runs)], ids_docket, [], "bd6b23c590d7", "")
    check "library 8.5 ns, dense form 3.5 ns" in body  # general row names what it times against
    check ">×2.50<" in body and body.count("<s style=") == 2  # median of 2.00 and 3.00, two ticks


  test "each dropdown option has rule that reads it, and each row class that rule wants":
    let
      runs = %*{"wedge_point_point": {
        "library": {"ns_median": 11.0, "share_nan": 0.0, "ns_runs": [12.0, 10.0, 11.0]},
        "reference": {"ns_median": 4.0, "share_nan": 0.0, "ns_runs": [4.0, 5.0, 3.0]}}}
      body = bodyDocket([sheetDocket(81, 12, runs)], ids_docket, [], "bd6b23c590d7", "")

    func tagOpening(body, measurand: string): string =
      ## Read opening tag of row naming measurand.
      let
        at = body.find("<span class=\"n\">" & measurand & "</span>")
        start = body.rfind("<details ", last = at)
      body[start..body.find('>', start)]

    let (typed, general) = (tagOpening(body, "wedge_point_point"), tagOpening(body, "wedge"))
    for select in ["sort", "show", "operation", "operand"]:
      check "<select id=\"" & select & "\">" in body  # dropdown, never radio
    check "type=\"radio\" name=\"sort\"" notin body and "name=\"show\"" notin body  # none left
    for key in ["bytes", "multiplies", "time", "spread", "divides", "checks"]:
      check "--o-" & key & ":" in typed  # rank under every sort
      check "option[value=\"" & key & "\"]:checked) details.row { order: var(--o-" & key in body
    for name_class in ["over-multiplies", "over-bytes", "over-time", "over", "typed"]:
      check " " & name_class & " " in typed or " " & name_class & "\"" in typed  # 81>12, ×3
      check "value=\"" & name_class & "\"]:checked) details.row:not(." & name_class & ")" in body
    check "over-time" notin general and "at-bound" notin general  # untimed; 512 bytes > 384
    check "--o-spread:0" in typed and "--o-spread:1" in general  # runs spread; none sorts last
    check "operation-wedge operand-point" in typed and "operand-" notin general  # id split
    check ":not(.operation-wedge)" in body and ":not(.operand-point)" in body  # one rule each
    check "<option value=\"wedge\" class=\"in-rga4d\">wedge ∧</option>" in body  # symbol beside


  test "search box finds row by its words, and shell hides row script marks unfound":
    const
      shell_html = staticRead("../pages/shell.html")
      source_find = staticRead("../src/pga_benchmark/pages/find.nim")
    let
      sheets = [sheetDocket(81, 12, %*{})]
      body = bodyDocket(sheets, ids_docket, [], "bd6b23c590d7", "filter()")
      bare = bodyDocket(sheets, ids_docket, [], "bd6b23c590d7", "")
    check "<input type=\"search\" id=\"find\"" in body and body.count("<script>") == 1  # one
    check "<script>filter()</script>" in body and "<script>" notin bare  # as driver passes it
    check "data-find=\"wedge_point_point g002 ∧ wedge point point\"" in body  # id, kinds, lower
    check "data-find=\"wedge g001 ∧ wedge\"" in body  # general row: no operand kind
    check "classList.add(\"unfound\")" in source_find and
        "details.row.unfound { display: none; }" in shell_html  # script marks, shell hides


  test "typed id splits at longest operand kind, one kind per operand":
    let
      sheet = Sheet(
        name: "cga5d",
        title: "Conformal 5D",
        dimensions: 5,
        measurements_static: %*{"measurands": {
          "bulk_flat_round_point": {"library": "■(M)", "reference": "bulkFlat(R)", "arity": 1},
          "wedge_round_point_dipole": {"library": "∧(M,M)", "reference": "wedge(R,D)",
            "arity": 2}},
          "functions": {}},
        measurements_runtime: %*{"taken": {"date": "d", "machine": "m"}, "measurands": {}},
      )
      body = bodyDocket([sheet], %*{"ids": {}}, [], "bd6b23c590d7", "")
    check "operation-bulk_flat operand-round_point" in body  # round point, never point
    check "operation-wedge operand-round_point operand-dipole" in body  # both, in id order
    check "operand-point" notin body and "operation-bulk_flat_round" notin body  # no half kind


  test "count over reference that spends none reads its excess, never infinite ratio":
    let body = bodyDocket([sheetDocket(81, 0, %*{})], ids_docket, [], "bd6b23c590d7", "")
    check ">81 over 0<" in body and "class=\"open\"" in body  # bar runs to axis end
    check "×inf" notin body and "×nan" notin body  # no ratio divides by zero


  test "proposal draws one bar per count, segment per fate of each operation, counts beside":

    func buildOverlay(title, url: string; functions: JsonNode): Overlay =
      ## Build one proposal changing functions of `rga4d` alone.
      Overlay(name: title, title: title, url: url, functions: {"rga4d": functions}.toTable)

    let
      overlays = [
        buildOverlay("P01: Swap", "u", %*{"∧(M,M)": {"after": {"multiplies": 81,
          "bytes_moved": 384}}}),
        buildOverlay("P02: Drop", "", %*{"∧(M,M)": {"after": nil}}),
        buildOverlay("P03: Keep", "", %*{}),
      ]
      body = bodyDocket([sheetDocket(54, 12, %*{})], ids_docket, overlays, "bd6b23c590d7", "")
      bar = "<i class=\"$1\" style=\"left:0.00%;width:100.00%\"></i></div><span class=\"v\">$2<"
    check body.count("<a href=\"u\">P01: Swap</a>") == 1  # link once, over its algebras
    check "<p>P02: Drop</p>" in body  # unpublished proposal named, unlinked
    check bar % ["lost", "1 → 0 of 1"] in body  # 54 at bound of 54, then 81 over it
    check bar % ["gained", "0 → 1 of 1"] in body  # 512 over 384, then 384 at it
    check bar % ["lost", "1 of 1 → 0 of 0"] in body  # dropped function leaves its count
    check "<div class=\"track\"></div><span class=\"v\">0 of 1 → 0 of 0<" in body  # none at it
    check bar % ["kept", "1 → 1 of 1"] in body  # untouched function keeps its fate
    check "Rigid 4D, multiplies: 1 of 1 at bound now, 0 of 1 with proposal; 0 brought to it, " &
        "1 taken off it" in body  # tip says every count
    check "class=\"gained\">brought to bound by proposal</span>" in body  # legend names fate
    check "/" notin body[body.find("Proposals against")..<body.find("How each figure")].replace(
        "</", "")  # no count left as fraction text


  test "verdict chips say when evaluation removes NaN results":
    let
      baselines = {"rga4d": %*{"measurands": {}}}.toTable
      document_evaluation = %*{
        "pin_suites": {"rga4d": {"ok": 1, "failed": 0}}, "algebras": {"rga4d": {
        "suites": {"ok": 1, "failed": 0}, "functions": {}, "times": {},
        "nan": {"norm": [0.5, 0.0]}}}}
      chips = chipsVerdict(document_evaluation, baselines, Spread(low: 0.9, high: 1.1))
    check "NaN gone in 1" in chips and "chip pass" in chips  # gain named, suites held
    check "no evaluation" in chipsVerdict(nil, baselines, Spread())  # absent evaluation is said



  test "home quotes docket's count of operations at multivector bound on multiplies":
    check countAtBound(sheetDocket(54, 12, %*{}), ids_docket) == (1, 1)  # at bound of 54
    check countAtBound(sheetDocket(81, 12, %*{}), ids_docket) == (0, 1)  # over it


  test "every page opens with bar to home and each view, linked where published":
    let
      urls = {"home": "https://x/h", "docket": "https://x/d"}.toTable
      docket = htmlViews(urls, "docket")
      proposal = htmlViews(urls, "proposals", is_view = false)
    check "<a href=\"https://x/h\">PGA benchmark</a>" in docket  # home linked first
    check "<a class=\"here\" aria-current=\"page\" href=\"https://x/d\">Performance</a>" in
        docket  # view page is marked as current page
    check "<span>Progress</span>" in docket  # unpublished view named, unlinked
    check "<span class=\"here\">Proposals</span>" in proposal  # its view marked, not page
    check docket.find("Progress") < docket.find("Performance") and
        docket.find("Performance") < docket.find("Proposals")  # views in order


  test "home shows one card per view, its figure, and link where view is published":
    let body = bodyHome(
      [
        Card(name: "a", title: "Map", url: "https://x/a", figure: "2/4", measure: "boxes",
          text: "What."),
        Card(name: "b", title: "Docket", figure: "1/1", measure: "at bound", text: "How."),
      ],
      "bd6b23c590d7",
    )
    check "<a class=\"tile\" href=\"https://x/a\"><h2>Map</h2><p class=\"headline\"><b>2/4</b> " &
        "boxes</p><p>What.</p></a>" in body  # published view linked
    check "<div class=\"tile\"><h2>Docket</h2>" in body  # unpublished one unlinked
    check "pga <code>bd6b23c</code>" in body  # pin named



suiteInProc "Internal: Proposal list":
  func listed(number: int, status = "proposed", bases: seq[int] = @[]): Proposal =
    ## Build proposal at number, titled after it, with status and bases by number.
    let citation = "P" & align($number, 2, '0')
    parseProposal(
      "# " & citation & ": Title " & $number & "\n",
      "",
      %*{"status": status, "implemented_in": "abc", "builds_on": bases.mapIt("p" & $it),
        "claims": []},
      "proposals/" & align($number, 2, '0') & "-p" & $number,
    )[0]

  let
    chain = @[listed(1), listed(2, bases = @[1]), listed(3, bases = @[2]), listed(4, "implemented"),
      listed(5)]
    urls = {"p1": "https://example.org/p1", "p3": ""}.toTable


  test "proposal page states what it depends on and what rejection blocks, through which one":
    let
      body = bodyProposal(
        chain[1],
        chain,
        nil,
        initTable[string, string](),
        initTable[string, string](),
        initTable[string, JsonNode](),
        Spread(),
        urls,
        "bd6b23c590d7",
        "",
      )
      root = htmlDependencies(chain, chain[0], urls)
      leaf = htmlDependencies(chain, chain[2], urls)
    check "<dt>Depends on</dt><dd><span><a href=\"https://example.org/p1\">P01</a> Title 1" &
        "</span></dd>" in body  # base cited, linked and titled
    check "<dt>Blocks if rejected</dt><dd><span>P03 Title 3</span></dd>" in body
      # unpublished one cited, unlinked
    check "<dt>Depends on</dt><dd><span class=\"none\">none</span></dd>" in root  # needs none
    check "P03 Title 3 (through P02)" in root  # downstream named with path
    check "P01</a> Title 1 (through P02)" in leaf  # upstream named with path
    check "Blocks if rejected</dt><dd><span class=\"none\">none</span>" in leaf  # leaf blocks none


  test "graph draws undecided proposals alone, one arrow per base, deeper ones further right":
    let
      graph = htmlGraph(chain)
      decided = htmlGraph([listed(1, "implemented")])
    check graph.count("class=\"node\"") == 4 and graph.count("class=\"edge\"") == 2
      # P04 left out
    check "<label class=\"node\" for=\"pick-p1\" title=\"P01: Title 1\"" in graph
      # box selects proposal for reading
    check "style=\"left: 8px; top: 8px; width: 264px" in graph  # P01 first column, first row
    check "left: 356px; top: 8px" in graph and "left: 704px; top: 8px" in graph  # P02, then P03
    check "left: 8px; top: 100px" in graph  # P05 under P01, since it builds on none
    check decided == ""  # nothing undecided, nothing drawn


  test "list page names every proposal, with standing, claims, dependencies and blocks":
    let
      evaluations =
        {"p1": %*{"algebras": {}, "claims": [{"passed": true}, {"passed": false}]}}.toTable
      body = htmlListing(
        chain,
        evaluations,
        initTable[string, string](),
        initTable[string, string](),
        initTable[string, JsonNode](),
        Spread(),
        urls,
        "bd6b23c590d7",
      )
      page = bodyListing(chain, 2, 3, body, "", "bd6b23c590d7")
    check "5 proposals · 4 undecided · 2 changes · 3 notes · pga <code>bd6b23c</code>" in page
      # counts in header
    for number in 1..5:
      check "Title " & $number & "</td>" in body  # every proposal, frozen one too
    check "<span class=\"chip fail\">1 of 2 hold</span>" in body  # one claim fails
    check "<span class=\"chip pass\">implemented</span>" in body  # frozen one stands so
    check "<td>P02, P03</td></tr>" in body  # P01 blocks both downstream
    check "<td><a href=\"https://example.org/p1\">P01</a>, P02</td>" in body  # P03 needs both
    check "<div class=\"graph\"" in body  # graph drawn above table


  test "list page holds every proposal whole behind its checkbox, none checked at rest":
    let body = htmlListing(
      chain,
      initTable[string, JsonNode](),
      initTable[string, string](),
      initTable[string, string](),
      initTable[string, JsonNode](),
      Spread(),
      urls,
      "bd6b23c590d7",
    )
    for number in 1..5:
      let id = "pick-p" & $number
      check "<input class=\"pick\" type=\"checkbox\" id=\"" & id & "\"><article" in body
        # checkbox stands right before reading it shows
      check body.count(" for=\"" & id & "\"") == 2 + (if number == 4: 0 else: 1)
        # table row, close, and graph box where undecided
      check "body:has(#" & id & ":checked) [for=\"" & id & "\"]" in body  # labels mark choice
    check "\" checked" notin body and "checked=" notin body  # page opens with none selected
    check "<h2>P02: Title 2</h2>" in body and "<h4>Claims</h4>" in body  # nested one level down
    check "<a href=\"https://example.org/p1\">its own page</a>" in body  # published page linked
    check "<button class=\"clear\" type=\"reset\">" in body  # one control clears all


  test "Proposals page opens on proposals tab, with marginalia in tab beside it":
    let page = bodyListing(chain, 0, 0, "<p>L</p>", "<p>M</p>", "bd6b23c590d7")
    check page.count(" checked") == 1 and "id=\"view-proposals\" checked>" in page
      # proposals shown at rest, and nothing else checked
    check "<section class=\"view view-proposals\"><p>L</p></section>" in page  # proposals tab
    check "<section class=\"view view-marginalia\"><p>M</p></section>" in page  # marginalia tab
    for name in ["proposals", "marginalia"]:
      check "body:has(#view-" & name & ":checked) .view:not(.view-" & name & ")" in page
        # each tab hides other



suiteInProc "Internal: Library map":
  const
    svg_fixture = "<rect class=\"block\" x=\"8\" y=\"0\" width=\"864\" height=\"300\"/>\n" &
      "<text class=\"blockname\" x=\"22\" y=\"19\">Products</text>\n" &
      "<g data-table=\"CAYLEYS_W.base\"><rect class=\"fixed\" x=\"0\" y=\"20\"/>\n" &
      "  <text>w</text></g>\n" &
      "<g data-ids=\"wedge\"><rect class=\"fixed\" x=\"0\" y=\"40\"/><text>∧</text></g>\n" &
      "<g class=\"faded\">\n<g data-ids=\"support\"><rect class=\"fixed\" x=\"0\" y=\"60\"/>\n" &
      "  <text>∩</text></g>\n</g>\n" &
      "<g class=\"faded\">\n<g data-ids=\"distance\"><rect class=\"fixed\" x=\"0\" y=\"80\"/>\n" &
      "  <text>d</text><text>(a, b)</text></g>\n</g>\n" &
      "<g data-table=\"CAYLEY_M\">\n<rect class=\"input\" x=\"0\" y=\"100\"/></g>\n"
      ## Map of one block: table alone, table, composite, missing, and input.
    cayleys = "const\n  CAYLEYS_W* = block:\n    x\n  CAYLEY_M* = y\n  CAYLEY_P = z\n"
      ## Library declaring two tables, and one table it keeps private.
    operators = "macro defineOperator(symbols: string) = discard\n\ndefineOperator(\n" &
      "  symbols = \"∧\",\n  cayley = CAYLEYS_W.base,\n)\n"
      ## Library building wedge alone from table.
  let
    catalogue = %*{"measurands": {"wedge": {"symbol": "∧", "alias": "wedge"},
      "support": {"symbol": "∩", "alias": "support"}}, "missing": {}}
      ## Catalogue holding wedge and support; distance it lacks.
    library = toLibrary(
      {PATH_CAYLEYS: cayleys, PATH_OPERATORS: operators}.toTable,
      [catalogue],
    )


  test "library is read from its source: tables it exports, and operations built from them":
    check library.tables == @["CAYLEYS_W", "CAYLEY_M"]  # private table left out
    check library.symbols == @["∧"] and library.served == @["CAYLEYS_W"]  # macro itself skipped
    check library.operations["support"].spelling == "∩"  # catalogue read


  test "box reads table, composite or missing, and map that fades each box so agrees":
    let boxes = boxes(svg_fixture)
    check boxes.mapIt(it.state(library)) == @[StateBox.Tabled, StateBox.Tabled,
        StateBox.Composed, StateBox.Missing, StateBox.Tabled]
    check boxes.mapIt(it.is_faded) == @[false, false, true, true, false]  # wrapper read
    check boxes[3].title == "d, (a, b)" and boxes[3].section == "Products"  # lines parted
    check boxes[4].is_input  # input holds no state of its own
    check checkMap(boxes, library, "m.svg").len == 0  # drawn as library holds it


  test "check names box drawn against its state, and table or operation no box stands for":
    let
      drawn = svg_fixture.replace("<g class=\"faded\">\n<g data-ids=\"support\"",
        "<g>\n<g data-ids=\"support\"")
      grown = toLibrary(
        {PATH_CAYLEYS: cayleys & "  CAYLEYS_X* = q\n", PATH_OPERATORS: operators &
          "defineOperator(\n  symbols = r\"∨\",\n  cayley = CAYLEYS_W.anti,\n)\n"}.toTable,
        [catalogue],
      )
      findings = checkMap(boxes(drawn), grown, "m.svg").mapIt(it.message)
    check findings.len == 3
    check "Box `∩` is drawn solid, where library at pin holds it as composite" in findings[0]
    check findings[1].endsWith("got `∨`.")  # raw literal read, and no box stands for it
    check findings[2].endsWith("got `CAYLEYS_X`.")  # table no box or operator names


  test "page writes state on each box, and counts boxes by state":
    let body = bodyCompletion(svg_fixture, library, "bd6b23c590d7", "https://x/p01")
    check "<g data-ids=\"distance\" data-state=\"missing\">" in body  # state on box
    check "<g data-ids=\"support\" data-state=\"composite\">" in body
    check "<dt>2/4</dt>" in body  # input not counted
    check "as <a href=\"https://x/p01\">P01</a> lays them out" in body  # P01 linked
    check "<td>Products</td><td>∩</td><td><code>∩</code></td><td><span class=\"chip " &
        "status\">from other operators</span></td>" in body  # row of composite box


  test "library map agrees with library at pin and catalogue at every algebra":
    const
      svg = staticRead("../pages/derivation-map.svg")
      sources = [staticRead(LIBRARY & "/" & PATH_CAYLEYS),
        staticRead(LIBRARY & "/" & PATH_OPERATORS)]
      catalogues = [staticRead("../baseline/static_rga4d.json"),
        staticRead("../baseline/static_cga5d.json"), staticRead("../baseline/static_rga3d.json"),
        staticRead("../baseline/static_cga4d.json")]
    let
      pinned = toLibrary(
        {PATH_CAYLEYS: sources[0], PATH_OPERATORS: sources[1]}.toTable,
        catalogues.mapIt(parseJson(it)),
      )
      findings = checkMap(boxes(svg), pinned, "pages/derivation-map.svg")
    checkpoint findings.mapIt(it.message).join("\n")
    check findings.len == 0  # map lags no table, and fades each box as library builds it



suiteInProc "Internal: Render":
  const fixture = staticRead("fixtures/control_render.json")  ## Control page of layout.


  test "control fixture expects one crowded card, and its page writes each card it names":
    let
      cards = cards(parseJson(fixture))
      body = bodyControl(cards)
    check crowdedExpected(cards).len > 0  # control proves something
    check cards.anyIt(not it.is_crowded)  # one card keeps margins of shell, unexpected
    for card in cards:
      let opening = "<details class=\"card\" id=\"" & card.id & "\" open>"
      check opening in body  # each card on page, open, by id
      check crowdedExpected(cards).contains("details#" & card.id & ".card") == card.is_crowded
    check body.count("margin-top: 0 !important") == cards.countIt(it.is_crowded)  # crowded alone


  test "crowded pair reads as finding at its page, and control passes on cards it expects":
    let
      expected = @["details#crowded.card"]
      crowded = %*{
        "proposals": [{"element": "details#change-x.card", "between": "p, p", "gap": 0}],
        "control": [{"element": "details#crowded.card", "between": "p, p", "gap": 0}],
      }
    check checkCrowded(crowded, expected, "control", "h").mapIt(it.render) == @[
      "h/proposals.html:0: details#change-x.card: Blocks of card touch; got `p, p` at `0 px`.",
    ]  # page's pair is finding, control's expected pair is not


  test "crowded control card absent is blind, and one nobody expects is finding":
    let
      expected = @["details#crowded.card"]
      blind = checkCrowded(%*{"control": []}, expected, "control", "h")
    check blind.len == 1 and "Check is blind" in blind[0].message  # read missed it
    let spaced = %*{"control": [
      {"element": "details#crowded.card", "between": "p, p", "gap": 0},
      {"element": "details#spaced.card", "between": "p, p", "gap": 0}]}
    check checkCrowded(spaced, expected, "control", "h").len == 1  # shell left spaced card crowded
    let none = checkCrowded(newJObject(), [], "control", "h")
    check none.len == 1 and "proves nothing" in none[0].message  # vacuous control refused


  test "harness reads control of layout for layout alone, and of font faces for text alone":
    let pages = ["h/docket.html", "h/home.html"]
    check argumentsHarness(
      "f/written.json", "b/crowded.json", "h/control_render.html", pages, some("f/control.html")
    ) == @[
      "f/written.json", "b/crowded.json", "h/docket.html", "h/home.html",
      "--layout-only", "h/control_render.html", "--text-only", "f/control.html",
    ]  # each page read for both, control of layout never for text, so out of `written.json`
    check argumentsHarness(
      "f/written.json", "b/crowded.json", "h/control_render.html", pages, none(string)
    ) == @[
      "f/written.json", "b/crowded.json", "h/docket.html", "h/home.html",
      "--layout-only", "h/control_render.html",
    ]  # no control page of font faces, so `written.json` holds pages alone



suiteInProc "Internal: Driver":
  const
    driver = staticRead("../tools/build.nim")  ## Dispatcher: header table, usage and packages.
    verbs = staticRead("../tools/verbs.nim")  ## Program every verb compiling project code runs.

  func dispatched(source: string): seq[string] =
    ## Read verbs driver's dispatch answers to: quoted labels of `of` branches after case.
    let start = source.find("case paramStr(1)")
    for line in source[start..<source.len].splitLines:
      let s = line.strip
      if s.startsWith("of \""):
        result.add s[4..<s.find('"', 4)]

  func taught(source: string): seq[string] =
    ## Read verbs usage string teaches, between its angle brackets, across its literals.
    let
      start = source.find("USAGE =")
      text = source[start..<source.find("##", start)].multiReplace(("\" &", ""), ("\"", ""))
      joined = text.splitWhitespace.join
    joined[joined.find('<')+1..<joined.find('>')].split('|')

  func tabled(source: string): seq[string] =
    ## Read verbs header table rows, first cell of each row naming one.
    for line in source.splitLines:
      if not line.startsWith("##   | "): continue
      let cell = line[7..<line.find('|', 7)].strip
      if cell.len > 0 and cell != "Command" and not cell.startsWith("-"): result.add cell

  func imports(source: string): seq[string] =
    ## Read path each `import` or `from` statement of source names first, as written.
    for line in source.splitLines:
      let s = line.strip
      if s.startsWith("#"): continue
      for opener in ["import ", "from "]:
        let at = s.find(opener)
        if at < 0 or (at > 0 and not s[0..<at].endsWith(": ")): continue
        result.add s[at+opener.len .. ^1].split(' ')[0]

  func branched(source: string): Table[string, string] =
    ## Read body of each dispatch branch, keyed by verb, up to next branch or `else:`.
    var verb = ""
    for line in source[source.find("case paramStr(1)")..<source.len].splitLines:
      let s = line.strip
      if s == "else:": break
      if s.startsWith("of \""):
        verb = s[4..<s.find('"', 4)]
        result[verb] = s[s.find(':', 4+verb.len)+1 .. ^1]
      elif verb.len > 0:
        result[verb].add "\n" & s


  test "drive holds code to pin alone, and verb head alone reads library head":
    let
      start = verbs.find("proc drive() =")
      body = verbs[start..<verbs.find("\n\n\n", start)]
    check "checkoutChecked()" in body and "headChecked" notin body  # drive reads no head
    check "of \"head\": report(headChecked(commitPga()))" in verbs  # head's verdict, exit code


  test "dispatch answers to every verb usage and header teach, and no other":
    check dispatched(driver).sorted == taught(driver).sorted  # usage string
    check dispatched(driver).sorted == tabled(driver).sorted  # header table
    check "inspect" in dispatched(driver) and "bench" in dispatched(driver)  # README's verbs
    check "types" in dispatched(driver)  # what `koch check-types` runs over `package.json`


  test "dispatcher imports standard library alone, so type check compiles no project code":
    let imports = imports(driver)
    check imports.len > 0  # reader finds dispatcher's imports
    for path in imports:
      check path.startsWith("std/")  # CONTRIBUTOR.md, TypeScript and Node
    check imports(verbs).anyIt(it.startsWith("../src/"))  # reader sees project import


  test "dispatcher hands on every verb but types and system, and verbs answers each":
    let branches = branched(driver)
    var handed: seq[string]
    for verb, body in branches:
      if "delegated()" in body: handed.add verb
    check handed.sorted == dispatched(verbs).sorted  # each verb handed on is answered there
    check "types" notin handed and "system" notin handed  # neither compiles project code
    check "types()" in branches["drive"] and "browser()" in branches["drive"]  # readied first


  test "drive builds every page once, and renders each page it builds":
    let
      start = verbs.find("proc drive() =")
      body = verbs[start..<verbs.find("\n\n\n", start)]
    check body.count("pagesBuilt(") == 1  # one build serves digests and render alike
    check "pinnedChecked(pin, built)" in body  # digests of that build
    check "renderedChecked(built, font_faces)" in body  # render of that build
    check "(\"nodejs\"," in driver  # node that render runs under, declared


  test "dispatcher declares libbrotli1 exactly while pages ship woff2 font face":
    let is_woff2_shipped = FONT_FACES.anyIt(it.endsWith(".woff2"))
    check is_woff2_shipped  # Commit Mono ships as `woff2` at pin, so law below reads something
    check ("(\"libbrotli1\"," in driver) == is_woff2_shipped  # CONTRIBUTOR.md, Pages and assets


  test "render runs harness on command line render.nim builds, and judges crowded file it writes":
    let
      start = verbs.find("proc renderedChecked(")
      body = verbs[start..<verbs.find("\n\n\n", start)]
    check "argumentsHarness(PATH_WRITTEN, PATH_CROWDED," in body  # held by `Internal: Render`
    check "checkCrowded(readDocument(PATH_CROWDED)" in body  # judge reads file harness writes


  test "header table names files verbs write":
    check "`baseline/runtime_<algebra>.json`" in driver  # what `bench` records
    check "`baseline/static_<algebra>.json`" in driver  # what `baseline` records
    check "| drive     | inspect, guard," in driver  # drive runs guard, not retired check
    check "`build/font-faces/written.json`" in driver  # what drive writes for `koch drive`
    check "`evaluations/<name>.json`" in driver  # what evaluate writes
    check "`pages/published.json`" in driver  # what published writes
