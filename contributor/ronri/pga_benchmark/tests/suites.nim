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
  bound, cells, changes, dense, gaps, guard, head, inspector, markdown, measurements, model,
  notes, proposals, report,
]
import ../src/pga_benchmark/pages/[docket, evaluation, proposal, search, shell]
from ../src/pga_benchmark/evaluations import
  ENTRY_LIBRARY, algebrasEvaluated, digestEdits, functionsChanged, nanOf, successOf, timesOf


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
  SYMBOLS_EXCLUDED = ["==", "=~", "$", "*"]
    ## Exported symbols catalogue leaves out on purpose.
    ##   Poisoned equality, approximate comparison and display are predicates or text.
    ##   `*` is template forwarding to scalar `∧`, which catalogue measures once as `scale`.


macro emitChecksCompile(measurands: static seq[Measurand]): untyped =
  ## Emit one `check compiles(expression)` per measurand, with `m` and `n` bound by operand kind.
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
  ##   Operands pair pool slot i with slot j = (7i + 3) mod OBJECTS, so pairs vary.
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
          check got =~ expected  # library on images equals reference embedded


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


func isNear(got, expected: Multivector): bool =
  ## Decide whether two multivectors agree, as library's own comparison decides.
  got =~ expected


func isNear(got, expected: float): bool =
  ## Decide whether two scalars agree within library's tolerance.
  abs(got - expected) <= TOLERANCE_ABS * max(1.0, max(abs(got), abs(expected)))


macro checkFormsDense(measurands: static seq[Measurand]): untyped =
  ## Emit one test per general measurand holding its dense form to library expression.
  ##   Operands pair pool slot i with slot j = (7i + 3) mod OBJECTS, as chapters do; NaN
  ##   where library returns NaN is equality too, since conformal norms return it.
  result = newStmtList()
  let (m, n) = (ident"m", ident"n")  # plain idents, so expression and dense form bind them
  for p in measurands:
    if p.reference.len > 0: continue
    let
      expression = parseExpr(p.expression)
      dense =
        if p.arity == 2: newCall(ident(p.nameDenseOf), m, n)
        else: newCall(ident(p.nameDenseOf), m)
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



suite "Internal: Configuration":
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



suite "Internal: Surface":
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



suite "Internal: Catalogue":
  test "ids are unique":
    let ids = idsOf(CATALOGUE) & idsOf(MISSING)
    check ids.deduplicate.len == ids.len  # one gap per operation


  test "every typed cite falls under chapter 2 or wiki page, so one suite holds it":
    for p in CATALOGUE:
      if p.reference.len == 0: continue
      check p.cite.startsWith("2.") or p.cite.startsWith("wiki:")  # no cite left unheld


  test "every expression compiles against library":
    emitChecksCompile(CATALOGUE)


  test "symbols match every operator library exports":
    let exported = (
      symbolsIn(SOURCE_OPERATORS, IS_CONFORMAL) & symbolsIn(SOURCE_MULTIVECTORS, IS_CONFORMAL)
    ).filterIt(it notin SYMBOLS_EXCLUDED).deduplicate
    check symbolsOf(CATALOGUE).sorted == exported.sorted  # no exported operator unmeasured


  test "inlined names every symbol library spells as template over field read":
    for symbol in INLINED:
      let line = "template `" & symbol & "`*(m: Multivector, b: Basis): float = m.elements[b]"
      check line in SOURCE_MULTIVECTORS  # template, so C carries no function to inspect


  test "templates name every symbol library spells over another":
    for (symbol, target) in TEMPLATES:
      let line = "template `" & symbol & "`*(m: Multivector): Multivector = " & target & " m"
      check line in SOURCE_OPERATORS  # one-line template, target's function is what C holds


  test "aliases match every name library's umbrella exports":
    let
      exported = aliasesIn(SOURCE_UMBRELLA, IS_CONFORMAL)
      catalogued = (aliasesOf(CATALOGUE) & aliasesOf(MISSING)).deduplicate
    check catalogued.sorted == exported.sorted  # missing ones counted as gaps, not forgotten



suite "Chapter 2":
  checkReferences(CATALOGUE, "2.")


checkReferencesWiki(CATALOGUE)



suite "Internal: Dense forms":
  checkFormsDense(CATALOGUE)



suite "Internal: Measurements":
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



suite "Internal: Allocation":
  test "allocation gauge is live under this build":
    let before = getAllocStats()
    var control = newSeq[float](8)
    control[0] = 1.0
    let after = getAllocStats()
    check allocationsOf(after - before) > 0  # positive control: counter moved
    check control[0] == 1.0  # control kept alive


  test "no measurand allocates in any implementation":
    measureCatalogue()
    for index, measurand in CATALOGUE:
      for it in Implementation:
        let measurement = MEASUREMENTS[it][index]
        if measurement.is_measured:
          check measurement.allocations == 0  # heap untouched over every round



suite "Internal: Lower bound":
  test "derived counts reproduce what algebra demands":
    let m = Metric(dimensions: 4, is_conformal: false)
    check boundLowerOf(Shape.Wedge, m, 2).multiplies == 81  # three states per dimension
    check boundLowerOf(Shape.Wedge, m, 2).adds == 65  # one add per term past first of each slot
    check boundLowerOf(Shape.Geometric, m, 2).multiplies == 192  # null vector drops one state
    check boundLowerOf(Shape.FormScalar, m, 2).multiplies == 8  # blades carrying metric image
    check boundLowerOf(Shape.ContractBulk, m, 2).multiplies == 54  # 2.119
    check boundLowerOf(Shape.ContractWeight, m, 2).multiplies == 27  # 2.120
    check boundLowerOf(Shape.ExpandBulk, m, 2).multiplies == 27  # wiki:Expansions
    check boundLowerOf(Shape.ExpandWeight, m, 2).multiplies == 54  # wiki:Expansions
    check boundLowerOf(Shape.Scale, m, 2).multiplies == 16  # every slot times one scalar
    check boundLowerOf(Shape.Permutation, m, 1).multiplies == 0  # sign and reorder only
    check boundLowerOf(Shape.ProductConstant, m, 1).multiplies == 0  # constant carries unit part


  test "unitize bound is norm, one reciprocal and one scale of each slot":
    let
      m = Metric(dimensions: 4, is_conformal: false)
      b = boundLowerOf(Shape.Unitize, m, 1)
    check b.multiplies == 8 + 16  # squared norm, then every slot
    check b.divides == 1 and b.roots == 1  # one reciprocal over one root


  test "compound product folds its maps into one table, and bound counts that table":
    let
      rigid = Metric(dimensions: 4, is_conformal: false)
      conformal = Metric(dimensions: 5, is_conformal: true)
    check boundLowerOf(Shape.Support, rigid, 1).multiplies == 54  # wiki:Support
    check boundLowerOf(Shape.SupportAnti, rigid, 1).multiplies == 54  # wiki:Support
    check boundLowerOf(Shape.Center, conformal, 1).multiplies == 162  # wiki:Conformal
    check boundLowerOf(Shape.Container, conformal, 1).multiplies == 162  # wiki:Conformal
    check not boundLowerOf(Shape.Support, rigid, 1).is_chain  # one table, not step sum
    check boundLowerOf(Shape.Support, rigid, 1).bytesMoved == 256  # operand read, result written
    check boundLowerOf(Shape.JoinCarrier, conformal, 2).multiplies == 162  # wiki:Conformal
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
    check boundLowerOf(Shape.Geometric, conformal, 2).multiplies == 1024  # four states throughout


  test "conformal dual is signed permutation, so dual product keeps every cell of wedge":
    let conformal = Metric(dimensions: 5, is_conformal: true)
    for shape in [Shape.ContractBulk, Shape.ContractWeight, Shape.ExpandBulk,
                  Shape.ExpandWeight]:
      check boundLowerOf(shape, conformal, 2).multiplies == 243  # every blade has image
      check boundLowerOf(shape, conformal, 2).is_derived  # rule holds here too


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
    check boundLowerOf(Shape.Wedge, m, 2).bytesMoved == 128 * 3  # two read, one written
    check boundLowerOf(Shape.Permutation, m, 1).bytesMoved == 128 * 2  # one read, one written
    check boundLowerOf(Shape.Unknown, m, 2).bytesMoved == 0  # no rule, so no claim


const CACHE = querySetting(SingleValueSetting.nimcacheDir)
  ## Nimcache of this test binary, which inspector suites read back.
let INSPECTED = inspectCache(CACHE)
  ## Read once: walking cache costs seconds, and two suites read same functions.



suite "Internal: Inspector":
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
    check overloadOf("X5BX5D__u1__pgaZmultivectors") == 1  # overload index read back
    check overloadOf("wedge_u0__referenceZrigid3") == 0 and overloadOf("nimZeroMem") == -1  # none


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
    let functions = functionsIn([
      "N_LIB_PRIVATE N_NOINLINE(void, measure0Library_u0__m)(void);",
      "N_LIB_PRIVATE N_NOINLINE(void, measure0Library_u0__m)(void) {",
      "\tT1_ = getMonoTime_u0__stdZmonotimes();",
      "}",
    ].join("\n") & "\n")
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
      let b = p.boundOf(metric)
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
      let b = p.boundOf(metric)
      for f in INSPECTED:
        if f.symbol != p.nameDenseOf: continue
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


  test "typed reference spends no fill and no error check, so it is optimal code":
    if not CATALOGUE.anyIt(it.reference.len > 0):
      echo "    typed reference exists at rga3d, rga4d, cga4d and cga5d alone, so law skips (IX.9)"
      skip()
    else:
      var compared = 0
      for f in INSPECTED:
        if not f.module.tailModule.startsWith("reference/"): continue
        let counts = count(f.body)
        checkpoint f.key & " fills " & $counts.fills_zero & ", checks " & $counts.checks
        # Call to Nim function costs fill of its result and check of error flag after it,
        #   so form shared with another function is spelled in place or is template.
        check counts.fills_zero == 0 and counts.checks == 0  # straight line, as hand code is
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
    # Result of three floats or fewer returns by value; assigned straight into its slot, it
    #   passes through temporary that call site zero-fills, out of line where function is
    #   large, about 11 ns.
    var calls, filled = 0
    for path in walkFiles(CACHE / "*measurements.nim.c"):
      let lines = readFile(path).splitLines
      for index, line in lines:
        if "referenceZ" notin line: continue
        inc calls
        if index > 0 and lines[index - 1].startsWith("nimZeroMem") and line.startsWith("T"):
          inc filled
    check calls > 0  # loops that call reference are read
    check filled == 0  # no reference result passes through zero-filled temporary


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



suite "Internal: Guard":
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



suite "Internal: Gaps":
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

  func decisionOf(rule: Rule, algebras: seq[Algebra], gaps: seq[Gap]): Decision =
    ## Decide cause carrying rule.
    for d in CAUSES:
      if d.rule == rule: return d.decideCause(algebras, gaps)


  test "gaps are decided against reference and against zero":
    let gaps = gapsOf(algebras_fixture[0])
    check gaps.len == 4  # one per measurand
    let by = gaps.mapIt((it.measurand, it)).toTable
    check by["wedge"].status == Status.Over and "checks" in by["wedge"].metrics_over  # absolute
    check "multiplies" notin by["wedge"].metrics_over  # no reference, no relative target
    check by["wedge_point_point"].metrics_over ==
      @["multiplies", "bytes", "fills_zero", "checks", "time"]  # in decided order
    check by["select_part"].status == Status.Met  # nothing spent, nothing exceeded
    check by["transform_point_motor"].metrics_over == @["time"]  # composed expression, timing alone


  test "gap without counts or timing is unmeasured":
    let gaps = gapsOf(
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
      gaps = gapsOf(algebras_fixture[0])
      docket = docketOf(nil)
    gaps.assign(docket)
    check gaps[0].id == "G001" and gaps[3].id == "G004" and docket.next == 5  # in order
    gaps.reverse
    var again = docketOf(docket.toJson)
    gaps.assign(again)
    check gaps[0].id == "G004" and gaps[3].id == "G001" and again.next == 5  # never renumbered
    gaps.add Gap(key: "cga5d/wedge", algebra: "cga5d", measurand: "wedge")
    gaps.assign(again)
    check gaps[^1].id == "G005" and again.next == 6  # next number, never one reused


  test "causes are decided by rule with evidence":
    let
      gaps = gapsOf(algebras_fixture[0])
      checks = decisionOf(Rule.Checks, algebras_fixture, gaps)
    check checks.status == Status.Over and "1 of 3 library functions" in checks.evidence  # ∧
    check "`" & key_wedge & "` with 178" in checks.evidence  # most
    check decisionOf(Rule.Inline, algebras_fixture, gaps).evidence ==
      "1 of 3 library operators, for example rga4d `~(Multivector)`."  # light operator called
    check decisionOf(Rule.FillsZero, algebras_fixture, gaps).evidence.startsWith(
      "2 of 3")  # ∧ and ~
    check decisionOf(Rule.Terms, algebras_fixture, gaps).evidence == "1 gaps. The widest is " &
      "rga4d/wedge_point_point, which spends 81 multiplies against 12."  # widest gap named
    check decisionOf(Rule.Time, algebras_fixture, gaps).evidence ==
      "2 gaps. The worst is rga4d/wedge_point_point, at 24.1 ns against 1.3 ns."  # worst ratio
    check decisionOf(Rule.Nan, algebras_fixture, gaps).status == Status.Met  # every share zero
    check decisionOf(Rule.Compound, algebras_fixture, gaps).evidence ==
      "rga4d/transform_point_motor."  # composed expression named
    check decisionOf(Rule.Missing, algebras_fixture, gaps).status == Status.Met  # nothing missing
    check decisionOf(Rule.Cayley, algebras_fixture, gaps).status ==
      Status.Unmeasured  # not readable here


  test "causes count library functions, never reference or dense form":
    check isModuleLibrary("pga/operators")  # library's own
    check not isModuleLibrary("reference/rigid3")  # typed reference
    check not isModuleLibrary("dense")  # dense form, as bench build names it
    check not isModuleLibrary("pga_benchmark/dense")  # dense form, as test build names it


  test "rendered list fits width and names every gap":
    let (text, docket) = generate(algebras_fixture, docketOf(nil))
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


  test "wrap breaks at spaces within width and indents continuation":
    check wrap("aa bb cc", 5) == @["aa bb", "cc"]  # fits, then breaks
    check wrap("aa bb cc", 5, "  ") == @["aa bb", "  cc"]  # continuation indented
    check wrap("∧∧∧ ∧∧∧", 3) == @["∧∧∧", "∧∧∧"]  # runes, not bytes



suite "Internal: Markdown":
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



suite "Internal: Changes":
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
          Edit(path: "pga/a.nim", replacement: "new\n", digest: digestOf(library)),
        ],
      )
      stale = Change(edits: @[Edit(path: "pga/a.nim", replacement: "new\n", digest: "0")])
    check applyChange(files, stale, record).len == 1  # file moved on at head
    check applyChange(files, fresh, record).len == 0 and files["pga/a.nim"] == "new\n"  # replaced


  test "section that is neither edit nor replace is finding":
    let (_, findings) = parseChange(record, "# Sign\n\n## Rename things\n")
    check findings.len == 1 and "neither Edit nor Replace" in findings[0].message  # malformed



suite "Internal: Notes":
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



suite "Internal: Head":
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



suite "Internal: Proposals":
  const
    directory_sign = "proposals/01-sign"
    record_sign = "# P01: Sign\n\nWhy.\n"

  func numbered(number: int, status = "proposed"): Proposal =
    ## Read well-formed proposal at number, with status.
    let
      directory = "proposals/" & align($number, 2, '0') & "-p" & $number
      heading = "# P" & align($number, 2, '0') & ": P\n"
    parseProposal(
      heading,
      "",
      %*{"status": status, "implemented_in": "abc", "claims": []},
      directory,
    )[0]


  test "proposal reads number, title, status, base proposal and claims of every known kind":
    let
      claims = %*{"status": "proposed", "builds_on": "base", "claims": [{"kind": "suites"},
        {"kind": "build", "algebra": "rga6d", "metric": "peakmem", "at_most": 0.7},
        {"kind": "program", "path": "p.nim", "algebras": ["rga4d"]}]}
      (proposal, findings) = parseProposal(record_sign, "", claims, directory_sign)
    check findings.len == 0 and proposal.title == "Sign"  # well formed, citation read off
    check proposal.number == 1 and proposal.name == "sign"  # number, then name, from path
    check proposal.citation == "P01" and not proposal.isFrozen  # cited as RFC is
    check proposal.builds_on == "base" and proposal.claims.len == 3  # chain and claims
    check proposal.programsOf == @["proposals/01-sign/p.nim"]  # program beside its proposal


  test "unknown claim, missing title and claims that are not JSON are findings":
    let
      odd = %*{"status": "proposed", "claims": [{"kind": "vibes"}]}
      (_, unknown) = parseProposal(record_sign, "", odd, directory_sign)
      (_, untitled) = parseProposal(
        "Why.\n",
        "",
        %*{"status": "proposed", "claims": []},
        directory_sign,
      )
      (_, broken) = parseProposal(record_sign, "", nil, directory_sign)
    check unknown.len == 1 and "`vibes`" in unknown[0].message  # never skipped in silence
    check untitled.len == 1 and untitled[0].path == directory_sign & "/proposal.md"  # needs title
    check broken.len == 1 and broken[0].path == directory_sign & "/claims.json"  # needs object


  test "path without number, title without citation and unknown status are findings":
    let
      claims = %*{"status": "proposed", "claims": []}
      (_, unnumbered) = parseProposal(record_sign, "", claims, "proposals/sign")
      (_, uncited) = parseProposal("# Sign\n", "", claims, directory_sign)
      (_, unplaced) =
        parseProposal(record_sign, "", %*{"status": "dreamt", "claims": []}, directory_sign)
    check unnumbered.len == 2  # path lacks number, so title cites none it could match
    check "`01-sign`" in unnumbered[0].message  # names form path needs
    check uncited.len == 1 and "`P01: `" in uncited[0].message  # title opens with citation
    check unplaced.len == 1 and "`dreamt`" in unplaced[0].message  # three statuses only


  test "implemented proposal needs its commit, and implemented or withdrawn is frozen":
    let
      (bare, why) = parseProposal(
        record_sign,
        "",
        %*{"status": "implemented", "claims": []},
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



suite "Internal: Evaluations":
  func run(ns: openArray[(string, float, float)]): JsonNode =
    ## Build one bench run: library median and NaN share per measurand.
    result = %*{"measurands": {}}
    for (id, time, nan) in ns:
      result["measurands"][id] = %*{"library": {"ns_median": time, "share_nan": nan}}


  test "evaluation measures 3D algebras, and all four only when thorough":
    check algebrasEvaluated(false) == @["rga4d", "cga5d"]  # default, 3D Euclidean
    check algebrasEvaluated(true) == @["rga4d", "cga5d", "rga3d", "cga4d"]  # thorough adds


  test "times pair runs by measurand, median of ratios, rounded":
    let
      before = @[run([("a", 10.0, 0.0)]), run([("a", 12.0, 0.0)]), run([("a", 11.0, 0.0)])]
      after = @[run([("a", 5.0, 0.0)]), run([("a", 6.0, 0.0)]), run([("a", 5.5, 0.0)])]
      times = timesOf(before, after)
    check times["a"][0].getFloat == 11.0 and times["a"][1].getFloat == 5.5  # medians
    check times["a"][2].getFloat == 0.5  # ratio of each run, then median


  test "NaN shares that moved are kept, and only those":
    let
      before = @[run([("norm", 1.0, 0.5), ("wedge", 1.0, 0.0)])]
      after = @[run([("norm", 1.0, 0.0), ("wedge", 1.0, 0.0)])]
      moved = nanOf(before, after)
    check moved.len == 1 and moved["norm"][0].getFloat == 0.5  # signed root clears NaN
    check not moved.hasKey("wedge")  # unmoved measurand left out


  test "compiler success line gives seconds and peak memory":
    let output = "......\nHint: mm: orc\n29867 lines; 0.213s; 38.008MiB peakmem; proj: a.nim; " &
      "out: a.json [SuccessX]\n"
    check successOf(output) == (0.213, 38.008)  # both read
    check successOf("Error: type mismatch\n") == (0.0, 0.0)  # failed build reads nothing


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


  test "digest moves with edits, claims and programs, and never with prose":
    let
      edit = Edit(path: "pga/a.nim", quote: "x", replacement: "y")
      one = Change(title: "One", edits: @[edit])
      reworded = Change(title: "Other words", edits: @[edit])
      claims = %*[{"kind": "suites"}]
    check digestEdits([one], claims, @[]) == digestEdits([reworded], claims, @[])  # prose
    check digestEdits([one], claims, @[]) != digestEdits([one], %*[], @[])  # claims
    check digestEdits([one], claims, @["a"]) != digestEdits([one], claims, @["b"])  # program



suite "Internal: Figures":
  test "figure is one image alone, path resolved against proposal's directory":
    let
      node = Block(
        kind: KindBlock.Paragraph,
        line: 3,
        lines: @["![Map. Each arrow is one", "rule.](../../pages/map.svg)"],
      )
      figure = node.figureOf("proposals/01-cayley-derivation")
      inline = Block(kind: KindBlock.Paragraph, lines: @["See ![map](map.svg) here."])
    check figure.isSome and figure.get.path == "pages/map.svg"  # `..` folded
    check figure.get.caption == "Map. Each arrow is one rule." and figure.get.line == 3  # joined
    check inline.figureOf("proposals/01-p").isNone  # image inside sentence stays text


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
        nil,
        initTable[string, string](),
        figures,
        initTable[string, JsonNode](),
        Spread(),
        "bd6b23c590d7",
        "",
      )
      bare = bodyProposal(
        record,
        nil,
        initTable[string, string](),
        initTable[string, string](),
        initTable[string, JsonNode](),
        Spread(),
        "bd6b23c590d7",
        "",
      )
    check "<div class=\"figure-art\"><svg id=\"m\"></svg></div><figcaption>Map.</figcaption>" in
      body  # SVG whole, caption beneath
    check "<figure" notin bare and "Map." in bare  # absent file renders as text


  test "P01 figure names committed map that shows every rule of P01":
    const
      argument = staticRead("../proposals/01-cayley-derivation/proposal.md")
      svg = staticRead("../pages/derivation-map.svg")
    let
      (record, _) = parseProposal(
        argument,
        "",
        %*{"status": "proposed", "claims": []},
        "proposals/01-cayley-derivation",
      )
      paths = record.body.mapIt(it.figureOf(record.directory)).filterIt(it.isSome).mapIt(
        it.get.path,
      )
    check paths == @["pages/derivation-map.svg"]  # one figure, file staticRead found
    for rule in ["constructAnti", "applyMap", "applyConstant", "filterGrades", "signed sum"]:
      check rule in svg  # each of four rules marks its arrow or box



suite "Internal: Edits":
  const source_pin = "func outer*(a: int;\n    b: int): int {.inline.} =\n  ## Doc.\n" &
    "  for x in 0 ..< a:\n    result += x\n\nimport std/math\n"
    ## Library file at pin: routine whose signature spans two lines, then top-level import.

  func edit(quote, replacement: string; digest = ""): Change =
    ## Build change of one edit to `pga/a.nim`.
    Change(edits: @[Edit(path: "pga/a.nim", quote: quote, replacement: replacement,
      digest: digest)])

  let files = {"pga/a.nim": source_pin}.toTable
    ## Library files edits read their line and context from.


  test "edit renders closed, naming routine it sits in at pin":
    let html = htmlEdits(edit("    result += x\n", "    result -= x\n"), files)
    check html.startsWith("<details class=\"edit\"><summary>") and " open" notin html  # closed
    check "<code>pga/a.nim:5</code> · replaces 1 line with 1" in html  # where, and how much
    check "inside</span><code>func outer*(a: int; b: int): int</code>" in html  # joined, bare


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


  test "whole-file replacement lists top-level signatures, operators and pragmas kept apart":
    let
      replacement = "func `==`(a, b: Order): bool {.borrow.}\nproc b*(x: int) =\n  discard\n"
      html = htmlEdits(edit("", replacement, "abc"), files)
    check "<code>func `==`(a, b: Order): bool</code><code>proc b*(x: int)</code>" in html  # bare
    check "class=\"signatures\"" notin htmlEdits(edit("import std/math\n", "import std/os\n"),
      files)  # top-level statement sits in no routine



suite "Internal: Search":
  test "row shows while its words hold every word typed, case folded in ASCII":
    const words = "wedge_point_point g007 ∧ wedge point"
    check isFound(words, "")  # nothing typed shows every row
    check isFound(words, "  ")  # blanks alone are no word
    check isFound(words, "WEDGE")  # case folds, as row words do
    check isFound(words, "g00 ∧")  # each word may be part of one
    check not isFound(words, "wedge dot")  # one word missing hides row
    check not isFound(words, "Ⅹ")  # symbol absent hides row



suite "Internal: Cells":
  test "table reads cell for cell, sign included, in both cell shapes":
    let wedge = cells(CAYLEYS_WEDGE.base)
    check wedge["E1,E2"] == %*[{"to": "E12", "neg": false}]  # 𝐞₁ ∧ 𝐞₂ = 𝐞₁₂
    check wedge["E2,E1"] == %*[{"to": "E12", "neg": true}]  # antisymmetric
    check not wedge.hasKey("E1,E1")  # vector wedge itself vanishes
    check cells(CAYLEY_ATTITUDE).len > 0  # 1D table reads too



suite "Internal: Pages":
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


  test "shell names faces it embeds, and assembly fills every token":
    let
      text_shell =
        "<title>@TITLE@</title><style>src: url(@EMBED:a.woff2@) url(@EMBED:b.ttf@)</style>@BODY@"
      page = assemble(
        text_shell,
        "A & B",
        "<p>body</p>",
        {"a.woff2": "xyz", "b.ttf": "uvw"}.toTable,
      )
    check facesAsked(text_shell) == @["a.woff2", "b.ttf"]  # both faces asked, in order
    check "@" notin page and "A &amp; B" in page and "<p>body</p>" in page  # filled
    check "data:font/woff2;base64,eHl6" in page  # WOFF2 bytes inlined as WOFF2
    check "data:font/ttf;base64,dXZ3" in page  # TrueType bytes inlined as TrueType


  test "every Noto face ships whole, as TrueType of its own release":
    for face in FACES:
      if face.toLowerAscii.startsWith("noto"):
        check face.endsWith(".ttf")  # Article X.8: Noto face whole, never subset


  test "spread is assumed until quiet evaluations give enough ratios":
    let quiet = %*{"algebras": {"rga4d": {"functions": {}, "times": {"a": [1.0, 1.0, 1.0]}}}}
    check spreadOf([quiet]).count == 0  # too few ratios: spread assumed
    check spreadOf([quiet]).low < 1.0 and spreadOf([quiet]).high > 1.0  # around no change


  test "every grid in shell bounds its columns, so wide content scrolls in place":
    const shell_html = staticRead("../pages/shell.html")
    var unbounded: seq[string]
    for rule in shell_html.split('}'):
      let body = rule.split('{')
      if body.len < 2 or "display: grid" notin body[^1]: continue
      if "grid-template-columns" notin body[^1]: unbounded.add body[^2].strip
    checkpoint "unbounded: " & unbounded.join(", ")
    check unbounded.len == 0  # grid child of auto width widens page at phone width


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
    check "G007 · ∧" in bodyDocket([sheet], ids, [], "bd6b23c590d7", "", "")  # shown beside symbol


  test "docket measures typed row against reference, general row against multivector bound":
    let
      body = bodyDocket([sheetDocket(81, 12, %*{})], ids_docket, [], "bd6b23c590d7", "", "")
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
      both = bodyDocket([sheetDocket(81, 12, %*{}), later], ids_docket, [], "bd6b23c590d7", "", "")
      one = bodyDocket([sheetDocket(81, 12, %*{})], ids_docket, [], "bd6b23c590d7", "", "")
    check "time d for Rigid 4D, e for Rigid 3D, m" in both  # each algebra under its own date
    check "time d, m" in one  # one date stays plain


  test "time bar is median of run ratios, and each run is one tick":
    let
      runs = %*{"wedge_point_point": {
        "library": {"ns_median": 11.0, "share_nan": 0.0, "ns_runs": [12.0, 10.0, 11.0]},
        "reference": {"ns_median": 4.0, "share_nan": 0.0, "ns_runs": [4.0, 5.0, 3.0]}}}
      body = bodyDocket([sheetDocket(81, 12, runs)], ids_docket, [], "bd6b23c590d7", "", "")
    check ">×3.00<" in body  # median of 3.00, 2.00 and 3.67; ratio of medians reads 2.75
    check "runs ×3.00 ×2.00 ×3.67" in body  # each run named, in run order
    check body.count("<s style=") == 3  # one tick for each run


  test "general row times against its dense form":
    let
      runs = %*{"wedge": {
        "library": {"ns_median": 8.5, "share_nan": 0.0, "ns_runs": [8.0, 9.0]},
        "dense": {"ns_median": 3.5, "share_nan": 0.0, "ns_runs": [4.0, 3.0]}}}
      body = bodyDocket([sheetDocket(81, 12, runs)], ids_docket, [], "bd6b23c590d7", "", "")
    check "library 8.5 ns, dense form 3.5 ns" in body  # general row names what it times against
    check ">×2.50<" in body and body.count("<s style=") == 2  # median of 2.00 and 3.00, two ticks


  test "each dropdown option has rule that reads it, and each row class that rule wants":
    let
      runs = %*{"wedge_point_point": {
        "library": {"ns_median": 11.0, "share_nan": 0.0, "ns_runs": [12.0, 10.0, 11.0]},
        "reference": {"ns_median": 4.0, "share_nan": 0.0, "ns_runs": [4.0, 5.0, 3.0]}}}
      body = bodyDocket([sheetDocket(81, 12, runs)], ids_docket, [], "bd6b23c590d7", "", "")

    func tagOf(body, measurand: string): string =
      ## Read opening tag of row naming measurand.
      let
        at = body.find("<span class=\"n\">" & measurand & "</span>")
        start = body.rfind("<details ", last = at)
      body[start..body.find('>', start)]

    let (typed, general) = (tagOf(body, "wedge_point_point"), tagOf(body, "wedge"))
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
      body = bodyDocket(sheets, ids_docket, [], "bd6b23c590d7", "", "filter()")
      bare = bodyDocket(sheets, ids_docket, [], "bd6b23c590d7", "", "")
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
      body = bodyDocket([sheet], %*{"ids": {}}, [], "bd6b23c590d7", "", "")
    check "operation-bulk_flat operand-round_point" in body  # round point, never point
    check "operation-wedge operand-round_point operand-dipole" in body  # both, in id order
    check "operand-point" notin body and "operation-bulk_flat_round" notin body  # no half kind


  test "count over reference that spends none reads its excess, never infinite ratio":
    let body = bodyDocket([sheetDocket(81, 0, %*{})], ids_docket, [], "bd6b23c590d7", "", "")
    check ">81 over 0<" in body and "class=\"open\"" in body  # bar runs to axis end
    check "×inf" notin body and "×nan" notin body  # no ratio divides by zero


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



suite "Internal: Driver":
  const driver = staticRead("../tools/build.nim")

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
    joined[joined.find('<') + 1..<joined.find('>')].split('|')

  func tabled(source: string): seq[string] =
    ## Read verbs header table rows, first cell of each row naming one.
    for line in source.splitLines:
      if not line.startsWith("##   | "): continue
      let cell = line[7..<line.find('|', 7)].strip
      if cell.len > 0 and cell != "Command" and not cell.startsWith("-"): result.add cell


  test "drive holds code to pin alone, and verb head alone reads library head":
    let
      start = driver.find("proc drive() =")
      body = driver[start..<driver.find("\n\n\n", start)]
    check "checkoutChecked()" in body and "headChecked" notin body  # drive reads no head
    check "of \"head\": report(headChecked(commitPga()))" in driver  # head's verdict, exit code


  test "dispatch answers to every verb usage and header teach, and no other":
    check dispatched(driver).sorted == taught(driver).sorted  # usage string
    check dispatched(driver).sorted == tabled(driver).sorted  # header table
    check "inspect" in dispatched(driver) and "bench" in dispatched(driver)  # README's verbs


  test "header table names files verbs write":
    check "`baseline/runtime_<algebra>.json`" in driver  # what `bench` records
    check "`baseline/static_<algebra>.json`" in driver  # what `baseline` records
    check "| drive     | inspect, guard," in driver  # drive runs guard, not retired check
    check "`evaluations/<name>.json`" in driver  # what evaluate writes
    check "`pages/published.json`" in driver  # what published writes
