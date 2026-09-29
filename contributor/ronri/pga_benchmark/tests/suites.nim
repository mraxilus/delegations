## Replicate laws of `pga_benchmark` under one algebra; stubs beside this file pick which.
##   Every stub names its algebra on its `matrix:` line, so `nim.cfg`'s default never
##   decides what ran. Library sources are read at compile time from Atlas checkout, so
##   catalogue is held to what library exports rather than to what this project remembers.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/[algorithm, compilesettings, json, macros, options, sequtils, strutils, tables, unittest]
from std/unicode import runeLen

import ../src/pga_benchmark
import ../src/pga_benchmark/[
  bound, changes, designs, gaps, guard, head, inspector, markdown, measurements, model, notes,
  report,
]
import ../src/pga_benchmark/pages/[docket, shell, trial]
import ../src/pga_benchmark/cells
from ../src/pga_benchmark/trials import editsDigest, functionsChanged, nanOf, successOf, timesOf


const
  LIBRARY =
    "../dependencies/replications.mraxilus.gitlab.com/lengyel/projective_geometric_algebra_illuminated"
    ## Library checkout Atlas restores, relative to this file.
  SOURCE_UMBRELLA = staticRead(LIBRARY & "/pga.nim")
    ## Library umbrella, holding named aliases.
  SOURCE_OPERATORS = staticRead(LIBRARY & "/pga/operators.nim")
    ## Library operators, generated and hand-written.
  SOURCE_MULTIVECTORS = staticRead(LIBRARY & "/pga/multivectors.nim")
    ## Library arithmetic and accessors.
  EXCLUDED = ["==", "=~", "$", "*"]
    ## Exported symbols catalogue leaves out on purpose: poisoned equality, approximate
    ## comparison and display are predicates or text, and `*` is template forwarding to
    ## scalar `∧`, which catalogue measures once as `scale`.


macro expressionsCompile(measurands: static seq[Measurand]): untyped =
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
          `m` {.used.}: `kind_m`
          `n` {.used.}: `kind_n`
        check compiles(`expression`)  # expression of `id` parses and resolves against library
        check `id`.len > 0  # id names gap


macro checkReferences(measurands: static seq[Measurand]; chapter: static string): untyped =
  ## Emit one test per measurand holding library expression on images to reference on typed.
  ##   Chapter "2" takes gaps citing book equations of chapter 2; "3" takes rest, which
  ##   are motor, projection and support pages of rigidgeometricalgebra.org.
  ##   Operands pair pool slot i with slot j = (7i + 3) mod OBJECTS, so pairs vary.
  result = newStmtList()
  let (m, n) = (ident"m", ident"n")  # plain idents, so expression and reference bind them
  for p in measurands:
    if p.reference.len == 0: continue
    if (chapter == "2") != p.cite.startsWith("2."): continue
    let
      expression = parseExpr(p.expression)
      reference = parseExpr(p.reference)
      library_m = parseExpr(libraryPoolName(p.operands[0], p.grade))
      library_n = parseExpr(libraryPoolName(p.operands[1], p.grade))
      reference_m = parseExpr(referencePoolName(p.operands[0]))
      reference_n = parseExpr(referencePoolName(p.operands[1]))
      name = newLit(p.id & "  # " & p.cite)
    result.add quote do:
      test `name`:
        for i in 0 ..< OBJECTS:
          let
            j = (i * 7 + 3) mod OBJECTS
            expected = block:
              let `m` {.used.} = `reference_m`[i]
              let `n` {.used.} = `reference_n`[j]
              widen(`reference`)
            got = block:
              let `m` {.used.} = `library_m`[i]
              let `n` {.used.} = `library_n`[j]
              `expression`
          check got =~ expected  # library on images equals reference embedded
  if result.len == 0: result.add newNimNode(nnkDiscardStmt).add(newEmptyNode())


fillPools(0)


suite "Configuration":
  test "stub matrix names algebra umbrella reports":
    check DIMENSIONS in 2 .. 6  # library's own bound
    when DIMENSIONS == 4 and IS_RIGID:
      check ALGEBRA_NAME == "rga4d"  # 3D Euclidean rigid, default of nim.cfg
    when DIMENSIONS == 5 and IS_CONFORMAL:
      check ALGEBRA_NAME == "cga5d"  # 3D Euclidean conformal


suite "Surface":
  test "symbols are read under gate of their algebra":
    const FIXTURE = """
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
    check symbolsIn(FIXTURE, is_conformal = false) == @["∧", "∩", "∪", "|", "^"]  # rigid gate
    check symbolsIn(FIXTURE, is_conformal = true) == @["∧", "■", "⊟", "|", "^"]  # else gate

  test "aliases are exported plain funcs under gate of their algebra":
    const FIXTURE = """
func selectGrade*(m: Multivector, g: Grade): Multivector {.inline.} = m{g}
when IS_RIGID:
  func bulk*(m: Multivector): Multivector {.inline.} = ∙ m
when IS_CONFORMAL:
  func bulkFlat*(m: Multivector): Multivector {.inline.} = ■ m
func add*(m, n: Multivector): Multivector {.inline.} = m + n
func add*(m: Multivector, s: float): Multivector {.inline.} = s + m
func `∧`*(s: float; m: Multivector): Multivector = m
func hidden(m: Multivector): Multivector = m
"""
    check aliasesIn(FIXTURE, is_conformal = false) == @["selectGrade", "bulk", "add"]  # rigid
    check aliasesIn(FIXTURE, is_conformal = true) == @["selectGrade", "bulkFlat", "add"]  # cga


suite "Catalogue":
  test "ids are unique":
    let ids = idsOf(CATALOGUE) & idsOf(MISSING)
    check ids.deduplicate.len == ids.len  # one gap per operation

  test "every expression compiles against library":
    expressionsCompile(CATALOGUE)

  test "symbols match every operator library exports":
    let exported = (
      symbolsIn(SOURCE_OPERATORS, IS_CONFORMAL) & symbolsIn(SOURCE_MULTIVECTORS, IS_CONFORMAL)
    ).filterIt(it notin EXCLUDED).deduplicate
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
  checkReferences(CATALOGUE, "2")


suite "Chapter 3":
  checkReferences(CATALOGUE, "3")


suite "Measurements":
  test "summarise reads median and minimum per object":
    check summarise([300'i64, 100, 200], 100) == (median: 2.0, minimum: 1.0)  # odd count
    check summarise([400'i64, 100, 300, 200], 100) == (median: 2.5, minimum: 1.0)  # even count

  test "every measurand yields finite positive measurements and results reach sink":
    measureCatalogue()
    check SINK != 0.0  # results folded, none dead
    for index, measurand in CATALOGUE:
      let measurement = MEASUREMENTS[Implementation.Library][index]
      check measurement.is_measured  # library implementation always has expression
      check measurement.ns_median > 0.0 and measurement.ns_median < 1.0e6  # per-object nanoseconds
      check measurement.ns_min > 0.0  # positive
      check measurement.ns_min <= measurement.ns_median  # minimum bounds median
      check MEASUREMENTS[Implementation.Reference][index].is_measured ==
        (measurand.reference.len > 0)  # reference implementation present where written


suite "Allocation":
  test "allocation gauge is live under this build":
    let before = getAllocStats()
    var control = newSeq[float](8)
    control[0] = 1.0
    let after = getAllocStats()
    check allocationsOf(after - before) > 0  # positive control: counter moved
    check control[0] == 1.0  # control kept alive

  test "no measurand allocates in either implementation":
    measureCatalogue()
    for index, measurand in CATALOGUE:
      for it in [Implementation.Library, Implementation.Reference]:
        let measurement = MEASUREMENTS[it][index]
        if measurement.is_measured:
          check measurement.allocations == 0  # heap untouched over every round


suite "Lower bound":
  test "derived counts reproduce what algebra demands":
    let m = Metric(dimensions: 4, is_conformal: false)
    check lowerBoundOf(Shape.Wedge, m, 2).multiplies == 81  # three states per dimension
    check lowerBoundOf(Shape.Wedge, m, 2).adds == 65  # one add per term past first of each slot
    check lowerBoundOf(Shape.Geometric, m, 2).multiplies == 192  # null vector drops one state
    check lowerBoundOf(Shape.ScalarForm, m, 2).multiplies == 8  # blades carrying metric image
    check lowerBoundOf(Shape.ContractBulk, m, 2).multiplies == 54  # 2.119
    check lowerBoundOf(Shape.ContractWeight, m, 2).multiplies == 27  # 2.120
    check lowerBoundOf(Shape.ExpandBulk, m, 2).multiplies == 27  # wiki:Expansions
    check lowerBoundOf(Shape.ExpandWeight, m, 2).multiplies == 54  # wiki:Expansions
    check lowerBoundOf(Shape.Scale, m, 2).multiplies == 16  # every slot times one scalar
    check lowerBoundOf(Shape.Permutation, m, 1).multiplies == 0  # sign and reorder only
    check lowerBoundOf(Shape.ConstantProduct, m, 1).multiplies == 0  # constant carries unit part

  test "unitize bound is norm, one reciprocal and one scale of each slot":
    let
      m = Metric(dimensions: 4, is_conformal: false)
      b = lowerBoundOf(Shape.Unitize, m, 1)
    check b.multiplies == 8 + 16  # squared norm, then every slot
    check b.divides == 1 and b.roots == 1  # one reciprocal over one root

  test "compound product folds its maps into one table, and bound counts that table":
    let
      rigid = Metric(dimensions: 4, is_conformal: false)
      conformal = Metric(dimensions: 5, is_conformal: true)
    check lowerBoundOf(Shape.Support, rigid, 1).multiplies == 54  # wiki:Support
    check lowerBoundOf(Shape.SupportAnti, rigid, 1).multiplies == 54  # wiki:Support
    check lowerBoundOf(Shape.Center, conformal, 1).multiplies == 162  # wiki:Conformal
    check lowerBoundOf(Shape.Container, conformal, 1).multiplies == 162  # wiki:Conformal
    check not lowerBoundOf(Shape.Support, rigid, 1).is_composed  # one table, not step sum
    check lowerBoundOf(Shape.Support, rigid, 1).bytesMoved == 256  # operand read, result written
    check lowerBoundOf(Shape.JoinCarrier, conformal, 2).multiplies == 162  # wiki:Conformal
    let partner = [Shape.Permutation, Shape.Container, Shape.JoinCarrier]
    check lowerBoundOfChain(partner, conformal, 1).multiplies == 324  # two folded tables
    check lowerBoundOfChain(partner, conformal, 1).is_composed  # sum of steps stays estimate

  test "conformal metric is not singular, so every blade carries image":
    let
      rigid = Metric(dimensions: 4, is_conformal: false)
      conformal = Metric(dimensions: 5, is_conformal: true)
    check rigid.isNull(3) and not rigid.isNull(0)  # last vector of rigid squares to zero
    check not conformal.isNull(4)  # conformal pairs last two off diagonal
    check conformal.scalarFormTerms == 32 and rigid.scalarFormTerms == 8  # every blade
    check lowerBoundOf(Shape.Geometric, conformal, 2).multiplies == 1024  # four states throughout

  test "conformal dual is signed permutation, so dual product keeps every cell of wedge":
    let conformal = Metric(dimensions: 5, is_conformal: true)
    for shape in [Shape.ContractBulk, Shape.ContractWeight, Shape.ExpandBulk,
                  Shape.ExpandWeight]:
      check lowerBoundOf(shape, conformal, 2).multiplies == 243  # every blade has image
      check lowerBoundOf(shape, conformal, 2).is_derived  # rule holds here too

  test "chain sums its steps, and step with no rule adds nothing":
    let
      rigid = Metric(dimensions: 4, is_conformal: false)
      conformal = Metric(dimensions: 5, is_conformal: true)
      projection = @[Shape.ExpandWeight, Shape.Wedge]
      b = lowerBoundOfChain(projection, rigid, 2)
    check b.multiplies == 54 + 81  # dual product, then full product
    check b.is_composed and b.is_derived  # record marks estimate as estimate
    check b.bytesMoved == 128 * 3  # two read, one written, no intermediate
    # Conformal dual product keeps every cell of wedge, so chain is two full products.
    check lowerBoundOfChain(projection, conformal, 2).multiplies == 486  # wiki:Expansions
    check lowerBoundOfChain([Shape.Unknown], rigid, 1).is_derived == false  # no step, no claim

  test "bound moves operands read once and result written once":
    let m = Metric(dimensions: 4, is_conformal: false)
    check lowerBoundOf(Shape.Wedge, m, 2).bytesMoved == 128 * 3  # two read, one written
    check lowerBoundOf(Shape.Permutation, m, 1).bytesMoved == 128 * 2  # one read, one written
    check lowerBoundOf(Shape.Unknown, m, 2).bytesMoved == 0  # no rule, so no claim


const CACHE = querySetting(SingleValueSetting.nimcacheDir)
  ## Nimcache of this test binary, which inspector suites read back.
let INSPECTED = inspectCache(CACHE)
  ## Read once: walking cache costs seconds, and two suites read same functions.


suite "Inspector":
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
    const MULTIVECTOR_MANGLED = "tyObject_Multivector__h"
    const FIXTURE = [
      "N_LIB_PRIVATE N_NIMCALL(void, XE2X88XA7__u0__OOZpgaZoperators)(" &
        MULTIVECTOR_MANGLED & "* m_p0, " & MULTIVECTOR_MANGLED & "* n_p1, " &
        MULTIVECTOR_MANGLED & "* Result) {",
      "\tNF* T1_;",
      "NF T2_;",
      MULTIVECTOR_MANGLED & " T3_;",
      "NIM_BOOL* nimErr_;",
      "{",
      "\t\tnimErr_ = nimErrorFlag();",
      "nimZeroMem(((void*) Result), sizeof(" & MULTIVECTOR_MANGLED & "));",
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
        MULTIVECTOR_MANGLED & "* m_p0, " & MULTIVECTOR_MANGLED & "* Result);",
    ].join("\n") & "\n"
    let functions = functionsIn(FIXTURE)
    check functions.len == 2  # declaration ending in `;` skipped
    check functions[0].symbol == "∧"  # head demangled
    check functions[0].params == @["Multivector", "Multivector"]  # stems in order
    check functions[0].result_stem == "Multivector" and not functions[0].is_inline  # via Result
    check functions[0].module == "OOZpgaZoperators"  # suffix after last `__`
    let c = count(functions[0].body)
    check c.multiplies == 2 and c.adds == 1 and c.subs == 1 and c.divides == 0  # as spelled
    check c.zero_fills == 1 and c.intermediates == 1 and c.checks == 2  # fills, locals, branches
    check c.calls == 1  # norm call counted, accessor read not
    check functions[1].symbol == "dot" and functions[1].params == @["Vector3", "Vector3"]
    check functions[1].result_stem == "float" and functions[1].is_inline  # via return type
    check count(functions[1].body).multiplies == 2  # inline body counted alike
    check functions[0].key == "∧(Multivector,Multivector)"  # key spells stems

  test "terms inside loops of constant bound count once per trip":
    const MULTIVECTOR_MANGLED = "tyObject_Multivector__h"
    const LOOP = [
      "N_LIB_PRIVATE N_NIMCALL(void, scale__u0__OOZpgaZops)(NF s_p0, " &
        MULTIVECTOR_MANGLED & "* m_p1, " & MULTIVECTOR_MANGLED & "* Result) {",
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
      functions = functionsIn(LOOP)
      c = count(functions[0].body)
    check c.multiplies == 16 + 1  # 16-trip loop counts its term sixteen times; unknown bound once
    check c.adds == 16  # every term inside loop is weighted
    check c.subs == 4 * 4  # nested loops multiply: `<= 3` from 0 is four trips, `< 4` four
    check c.calls == 16 and c.lines == 48  # call site per trip; lines stay static
    check totals(functions)["scale__u0__OOZpgaZops"].multiplies == 17 + 16  # callee per trip

  test "divisions count as terms, once per trip, and fold from callees":
    const MULTIVECTOR_MANGLED = "tyObject_Multivector__h"
    const DIVIDE = [
      "N_LIB_PRIVATE N_NIMCALL(void, unit__u0__OOZpgaZops)(" &
        MULTIVECTOR_MANGLED & "* m_p0, " & MULTIVECTOR_MANGLED & "* Result) {",
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
    let functions = functionsIn(DIVIDE)
    check count(functions[0].body).divides == 1  # reciprocal outside loop, once
    check count(functions[1].body).divides == 1  # callee's own division
    check totals(functions)["unit__u0__OOZpgaZops"].divides == 1 + 4  # folded once per trip
    check count(functions[0].body).multiplies == 0  # division is not multiply

  test "totals fold callees per call site":
    const FIXTURE = """
N_NIMCALL(void, outer__u0__m)(tyObject_Multivector__h* m_p0, tyObject_Multivector__h* Result) {
inner__u0__m(m_p0, Result);
inner__u0__m(m_p0, Result);
}

N_NIMCALL(void, inner__u0__m)(tyObject_Multivector__h* m_p0, tyObject_Multivector__h* Result) {
(*Result) = (((NF) 1.0) * ((NF) 2.0));
}
"""
    let totals = totals(functionsIn(FIXTURE))
    check totals["inner__u0__m"].multiplies == 1  # own
    check totals["outer__u0__m"].multiplies == 2 and totals["outer__u0__m"].calls == 2  # twice

  test "movement models bytes from stems and counts":
    let f = CFunction(
      symbol: "∧",
      params: @["Multivector", "Multivector"],
      result_stem: "Multivector",
    )
    let m = movement(f, Counts(zero_fills: 1, intermediates: 2, copies: 1), 128)
    check m.bytes_read == 256 and m.bytes_written == 128  # two in, one out
    check m.bytes_zeroed == 128 and m.bytes_copied == 128 and m.bytes_intermediates == 256
    check m.bytes_moved == 896  # sum of every cause
    check sizeOfStem("Point", 128) == 32 and sizeOfStem("float", 128) == 8  # typed sizes
    check sizeOfStem("Unknown", 128) == 0  # unknown stems add nothing

  test "no lower bound outruns what library spends on same operation":
    let metric = Metric(dimensions: DIMENSIONS, is_conformal: IS_CONFORMAL)
    # Fold only functions law reads: folding whole cache walks every call graph of
    #   unittest itself, which costs minutes (Article IX.8).
    var roots: seq[string]
    for f in INSPECTED:
      for p in CATALOGUE:
        if f.symbol == p.emittedHead and f.name notin roots: roots.add f.name
    let total = totals(INSPECTED, roots)
    var compared = 0
    for p in CATALOGUE:
      let head = p.emittedHead
      if head.len == 0 or head in INLINED: continue
      let b = p.boundOf(metric)
      if not b.is_derived: continue
      # Operator carrying scalar overload spells same symbol at same arity, so stems of
      #   parameters are what tells two apart.
      var wants_dense, wants_scalar = 0
      for i in 0 ..< int(p.arity):
        if p.operands[i] == Kind.Scalar: inc wants_scalar else: inc wants_dense
      for f in INSPECTED:
        if f.symbol != head: continue
        var dense, scalar = 0
        for stem in f.params:
          if stem == "Multivector": inc dense elif stem == "float": inc scalar
        if dense != wants_dense or scalar != wants_scalar: continue
        # Bound is what algebra demands, so library meets it and never beats it. Totals
        #   fold callees, since bound of chain counts arithmetic wherever it is spent.
        check b.multiplies <= total[f.name].multiplies  # derivation is sound
        inc compared
    check compared > 0  # law is vacuous where nothing is compared

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
        for stem in f.params:
          if stem == "Multivector" or stem == "float": inc arity
        if arity == int(p.arity): is_found = true
      check is_found  # every spelled operator is emitted at its arity
    when IS_RIGID and DIMENSIONS == 4:
      check "wedge(Point,Point)" in keys  # typed reference reached from suites
      for f in functions:
        if f.key == "wedge(Point,Point)":
          check count(f.body).multiplies == 12 and count(f.body).subs == 6  # as documented


suite "Guard":
  const
    PATH = "baseline/rga4d.json"
    KEY = "∧(Multivector,Multivector)"

  func node(multiplies, checks, zero_fills, bytes: int): JsonNode =
    ## Shape one function as inspect does, from counts and bytes moved.
    let c = Counts(multiplies: multiplies, checks: checks, zero_fills: zero_fills)
    %*{
      "symbol": "∧", "module": "pga/operators", "params": ["Multivector", "Multivector"],
      "returns": "Multivector", "inline": false, "own": countsNode(c), "total": countsNode(c),
      "movement": movementNode(Movement(bytes_moved: bytes)),
    }

  func doc(functions: JsonNode; flags = "-d:release"; dimensions = 4): JsonNode =
    ## Shape static measurements document around functions.
    result = document(
      "static", algebraNode("rga4d", dimensions, false, 128),
      %*{"date": "2026-09-13", "machine": "m", "nim": "n", "pga": "p", "flags": flags},
    )
    result["functions"] = functions

  func one(key: string; f: JsonNode): JsonNode =
    ## Shape functions object holding one function.
    result = newJObject()
    result[key] = f

  test "equal documents pass with nothing to say":
    let
      same = one(KEY, node(81, 178, 1, 512))
      v = compare(doc(same), doc(same), PATH)
    check v.findings.len == 0 and v.improvements.len == 0  # gate silent

  test "grown count is one finding naming function, metric and both values":
    let v =
      compare(doc(one(KEY, node(81, 178, 1, 512))), doc(one(KEY, node(90, 178, 1, 512))), PATH)
    check v.findings.len == 1 and v.improvements.len == 0  # one metric grew
    check v.findings[0].render ==
      PATH & ":0: Total `multiplies` of `" & KEY & "` grew; got `90`, baseline `81`."  # IV.4

  test "shrunk count is improvement, never finding":
    let v =
      compare(doc(one(KEY, node(81, 178, 1, 512))), doc(one(KEY, node(81, 0, 1, 512))), PATH)
    check v.findings.len == 0 and v.improvements.len == 1  # baseline moves by choice
    check "checks" in v.improvements[0] and "got `0`" in v.improvements[0]  # what shrank

  test "bytes moved are gated with counts":
    let v =
      compare(doc(one(KEY, node(81, 178, 1, 512))), doc(one(KEY, node(81, 178, 1, 640))), PATH)
    check v.findings.len == 1 and "bytes_moved" in v.findings[0].message  # movement grew

  test "function absent in either document is finding":
    let before = compare(doc(one(KEY, node(81, 178, 1, 512))), doc(newJObject()), PATH)
    check before.findings.len == 1 and "absent now" in before.findings[0].message  # gone
    let after = compare(doc(newJObject()), doc(one(KEY, node(81, 178, 1, 512))), PATH)
    check after.findings.len == 1 and "absent from baseline" in after.findings[0].message  # new

  test "documents of another build are not compared":
    let
      same = one(KEY, node(81, 178, 1, 512))
      flags = compare(doc(same), doc(same, flags = "-d:danger"), PATH)
    check flags.findings.len == 1 and "`flags`" in flags.findings[0].message  # build differs
    let dims = compare(doc(same), doc(same, dimensions = 5), PATH)
    check dims.findings.len == 1 and "`dimensions`" in dims.findings[0].message  # algebra differs
    let schema = compare(doc(same), %*{"schema": 2}, PATH)
    check schema.findings.len == 1 and "Schema differs" in schema.findings[0].message  # refused


suite "Gaps":
  const KEY_WEDGE = "∧(Multivector,Multivector)"

  func functionNode(
    symbol, module: string; is_inline: bool; multiplies, checks, zero_fills, bytes: int
  ): JsonNode =
    ## Shape one inspected function.
    let c = Counts(multiplies: multiplies, checks: checks, zero_fills: zero_fills)
    %*{
      "symbol": symbol, "module": module, "params": [], "returns": "", "inline": is_inline,
      "own": countsNode(c), "total": countsNode(c),
      "movement": movementNode(Movement(bytes_moved: bytes)),
    }

  func staticDoc(): JsonNode =
    ## Shape static measurements document: two library operators, accessor, reference form.
    result = document(
      "static", algebraNode("rga4d", 4, false, 128),
      %*{"date": "2026-09-13", "machine": "m", "nim": "n", "pga": "p", "flags": "f"},
    )
    var functions = newJObject()
    functions[KEY_WEDGE] = functionNode("∧", "pga/operators", false, 81, 178, 1, 512)
    functions["wedge(Point,Point)"] = functionNode("wedge", "reference/rigid3", true, 12, 0, 0, 112)
    functions["~(Multivector)"] = functionNode("~", "pga/operators", false, 0, 0, 1, 384)
    functions["[](Multivector,Basis)"] = functionNode("[]", "pga/multivectors", true, 0, 0, 0, 136)
    result["functions"] = functions
    result["measurands"] = %*{
      "wedge": {"symbol": "∧", "library": KEY_WEDGE, "reference": ""},
      "wedge_point_point": {
        "symbol": "∧", "library": KEY_WEDGE, "reference": "wedge(Point,Point)"
      },
      "select_part": {"symbol": "[]", "library": "[](Multivector,Basis)", "reference": ""},
      "transform_point_motor": {
        "symbol": "", "library": "", "reference": "transform(Point,Motor)"
      },
    }
    result["missing"] = newJObject()

  func measurement(ns: float): JsonNode =
    ## Shape one bench measurement.
    %*{"ns_median": ns, "ns_min": ns, "allocations": 0, "nan_share": 0.0}

  func runtimeDoc(): JsonNode =
    ## Shape runtime measurements document over same measurands.
    result = document(
      "runtime", algebraNode("rga4d", 4, false, 128),
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

  let ALGEBRAS = @[
    Algebra(name: "rga4d", static_measurements: staticDoc(), runtime_measurements: runtimeDoc())
  ]

  func decidedOf(rule: Rule; algebras: seq[Algebra]; gaps: seq[Gap]): Decision =
    ## Decide cause carrying rule.
    for d in CAUSES:
      if d.rule == rule: return d.decideCause(algebras, gaps)

  test "gaps are decided against reference and against zero":
    let gaps = gapsOf(ALGEBRAS[0])
    check gaps.len == 4  # one per measurand
    let by = gaps.mapIt((it.measurand, it)).toTable
    check by["wedge"].status == Status.Over and "checks" in by["wedge"].over_on  # absolute
    check "multiplies" notin by["wedge"].over_on  # no reference, no relative target
    check by["wedge_point_point"].over_on ==
      @["multiplies", "bytes", "zero_fills", "checks", "time"]  # in decided order
    check by["select_part"].status == Status.Met  # nothing spent, nothing exceeded
    check by["transform_point_motor"].over_on == @["time"]  # composed expression, timing alone

  test "gap without counts or timing is unmeasured":
    let gaps = gapsOf(
      Algebra(name: "rga4d", static_measurements: staticDoc(), runtime_measurements: nil)
    )
    let by = gaps.mapIt((it.measurand, it)).toTable
    check by["transform_point_motor"].status == Status.Unmeasured  # nothing to decide on
    check "time" notin by["wedge_point_point"].over_on  # no bench, no time verdict

  test "docket keeps identifiers across reorder and allots next to new key":
    var
      gaps = gapsOf(ALGEBRAS[0])
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
      gaps = gapsOf(ALGEBRAS[0])
      checks = decidedOf(Rule.Checks, ALGEBRAS, gaps)
    check checks.status == Status.Over and "1 of 3 library functions" in checks.evidence  # ∧
    check "`" & KEY_WEDGE & "` with 178" in checks.evidence  # most
    check decidedOf(Rule.Inline, ALGEBRAS, gaps).evidence ==
      "1 of 3 library operators, for example rga4d `~(Multivector)`."  # light operator called
    check decidedOf(Rule.ZeroFills, ALGEBRAS, gaps).evidence.startsWith("2 of 3")  # ∧ and ~
    check decidedOf(Rule.Terms, ALGEBRAS, gaps).evidence ==
      "1 gaps. The widest is rga4d/wedge_point_point, which spends 81 multiplies against 12."
    check decidedOf(Rule.Time, ALGEBRAS, gaps).evidence ==
      "2 gaps. The worst is rga4d/wedge_point_point, at 24.1 ns against 1.3 ns."  # worst ratio
    check decidedOf(Rule.Nan, ALGEBRAS, gaps).status == Status.Met  # every share zero
    check decidedOf(Rule.Compound, ALGEBRAS, gaps).evidence ==
      "rga4d/transform_point_motor."  # composed expression named
    check decidedOf(Rule.Missing, ALGEBRAS, gaps).status == Status.Met  # nothing missing
    check decidedOf(Rule.Cayley, ALGEBRAS, gaps).status == Status.Unmeasured  # not readable here

  test "rendered list fits width and names every gap":
    let (text, docket) = generate(ALGEBRAS, docketOf(nil))
    var widest = 0
    for line in text.splitLines: widest = max(widest, runeLen(line))
    check widest <= WIDTH  # form check reads product
    check "| G002 | wedge_point_point | 81/12 | 0/0 | 512/112 | 0/0 | 178/0 | 24.1/1.3 | over |" in
      text  # cells read library/reference
    check "| G004 | transform_point_motor | – | – | – | – | – | 60.0/5.0 | over |" in
      text  # composed expression has no counts
    check "- **D05, over.**" in text and "- **D10, unmeasured.**" in text  # design verdicts
    check "Gaps: 4. Over 3, met 1, unmeasured 0." in text  # summary
    check docket.next == 5  # docket grew with gaps

  test "wrap breaks at spaces within width and indents continuation":
    check wrap("aa bb cc", 5) == @["aa bb", "cc"]  # fits, then breaks
    check wrap("aa bb cc", 5, "  ") == @["aa bb", "  cc"]  # continuation indented
    check wrap("∧∧∧ ∧∧∧", 3) == @["∧∧∧", "∧∧∧"]  # runes, not bytes


suite "Markdown":
  test "blocks keep kind, level and line they open on":
    let blocks = parseBlocks("# Title\n\nWhy it is.\nStill why.\n\n- one\n- two\n\n" &
      "| a | b |\n|---|---|\n| 1 | 2 |\n")
    check blocks.len == 4  # heading, paragraph, bullets, table
    check blocks[0].kind == BlockKind.Heading and blocks[0].level == 1  # title
    check blocks[1].lines == @["Why it is.", "Still why."] and blocks[1].line == 3  # paragraph
    check blocks[2].kind == BlockKind.Bullets and blocks[2].lines == @["one", "two"]  # list
    check blocks[3].kind == BlockKind.Table and blocks[3].lines.len == 3  # rows kept

  test "fence keeps its lines verbatim and closes on run at least as long":
    let blocks = parseBlocks("````nim\nlet a = 1\n```\n  indented\n````\nafter\n")
    check blocks[0].kind == BlockKind.Fence and blocks[0].info == "nim"  # info string
    check blocks[0].lines == @["let a = 1", "```", "  indented"]  # shorter run stays inside
    check blocks[1].kind == BlockKind.Paragraph  # fence closed

  test "inline markup renders, and everything else is escaped":
    check renderInline("`a < b` and **b** and _c_") ==
      "<code>a &lt; b</code> and <strong>b</strong> and <em>c</em>"  # three markers
    check renderInline("[site](https://x.y/z?a=1&b=2)") ==
      "<a href=\"https://x.y/z?a=1&amp;b=2\">site</a>"  # link escaped once
    check renderInline("snake_case_name <b>") == "snake_case_name &lt;b&gt;"  # no false italic

  test "table renders header row when second row divides":
    let html = renderBlocks(parseBlocks("| a | b |\n|---|---|\n| 1 | 2 |\n"))
    check "<th>a</th>" in html and "<td>1</td>" in html and "---" notin html  # header split


suite "Changes":
  const
    RECORD = "changes/sign.md"
    LIBRARY = "let x = 1\nlet y = 2\nlet z = 1\n"

  test "change reads title, why and edits in order":
    let (change, findings) = parseChange(RECORD, "# Sign\n\nWhy.\n\n## Edit `pga/a.nim`\n\n" &
      "FENCEnim\nlet y = 2\nFENCE\n\nFENCEnim\nlet y = 3\nFENCE\n".replace("FENCE", "```"))
    check findings.len == 0  # well formed
    check change.title == "Sign" and change.why.len == 1  # title and why
    check change.edits.len == 1 and change.edits[0].path == "pga/a.nim"  # one edit
    check change.edits[0].quote == "let y = 2" and change.edits[0].replacement == "let y = 3"

  test "quote found once is replaced; found twice or nowhere is finding":
    var files = {"pga/a.nim": LIBRARY}.toTable
    let
      once = Change(edits: @[Edit(path: "pga/a.nim", quote: "let y = 2", replacement: "let y = 3")])
      twice = Change(edits: @[Edit(path: "pga/a.nim", quote: " = 1", replacement: " = 4", line: 5)])
      nowhere = Change(edits: @[Edit(path: "pga/a.nim", quote: "let w", replacement: "")])
    check applyChange(files, once, RECORD).len == 0  # applies
    check files["pga/a.nim"] == "let x = 1\nlet y = 3\nlet z = 1\n"  # replaced in place
    let ambiguous = applyChange(files, twice, RECORD)
    check ambiguous.len == 1 and ambiguous[0].render ==
      RECORD & ":5: Quote must occur once in `pga/a.nim`; got `2`."  # never guess
    check applyChange(files, nowhere, RECORD).len == 1  # stale quote

  test "whole-file replacement holds to digest of file at pin":
    var files = {"pga/a.nim": LIBRARY}.toTable
    let
      fresh = Change(edits: @[
        Edit(path: "pga/a.nim", replacement: "new\n", digest: digestOf(LIBRARY))
      ])
      stale = Change(edits: @[Edit(path: "pga/a.nim", replacement: "new\n", digest: "0")])
    check applyChange(files, stale, RECORD).len == 1  # file moved on at head
    check applyChange(files, fresh, RECORD).len == 0 and files["pga/a.nim"] == "new\n"  # replaced

  test "section that is neither edit nor replace is finding":
    let (_, findings) = parseChange(RECORD, "# Sign\n\n## Rename things\n")
    check findings.len == 1 and "neither Edit nor Replace" in findings[0].message  # malformed


suite "Notes":
  const
    RECORD = "marginalia/notes.md"
    SOURCE = "Notes.\n\n## Odd grade\n\n`pga/a.nim` · decide\n\n" &
      "FENCEnim\nlet y = 2\nFENCE\n\nSay why.\n"

  test "note reads title, file, status, quote and body":
    let (notes, findings) = parseNotes(RECORD, SOURCE.replace("FENCE", "```"))
    check findings.len == 0 and notes.lead.len == 1 and notes.items.len == 1  # one note
    let note = notes.items[0]
    check note.title == "Odd grade" and note.path == "pga/a.nim" and note.status == "decide"
    check note.quote == "let y = 2" and note.body.len == 1  # anchor and body

  test "anchor is located at pin, and stale anchor is finding":
    let
      (notes, _) = parseNotes(RECORD, SOURCE.replace("FENCE", "```"))
      files = {"pga/a.nim": "let x = 1\nlet y = 2\n"}.toTable
      moved = {"pga/a.nim": "let y = 3\n"}.toTable
    check checkAnchors(notes, files, RECORD).len == 0 and notes.items[0].lineAt(files) == 2
    check checkAnchors(notes, moved, RECORD).len == 1  # quote gone from library


suite "Head":
  const PIN = "bd6b23c590d7e1da91a1ea288a1a4b94dedbf315"

  test "pin passes when library tree is head's, whatever repository commit":
    check checkHead(PIN, "tree1", "ffffffff", "tree1", "atlas.lock").len == 0  # same tree
    let lag = checkHead(PIN, "tree1", "ffffffff", "tree2", "atlas.lock")
    check lag.len == 1 and "Pin lags library head" in lag[0].message  # library moved
    check checkHead(PIN, "tree1", "", "", "atlas.lock").len == 1  # head unread is finding

  test "measurement and trial must be taken at pin":
    let
      fresh = %*{"taken": {"pga": PIN}, "edits_digest": "d1"}
      stale = %*{"taken": {"pga": "0bc4655"}, "edits_digest": "d1"}
    check checkStamp(fresh, PIN, "baseline/runtime_rga4d.json").len == 0  # at pin
    check checkStamp(stale, PIN, "baseline/runtime_rga4d.json").len == 1  # re-take
    check checkTrial(fresh, PIN, "d1", "trials/sign.json").len == 0  # current
    check checkTrial(fresh, PIN, "d2", "trials/sign.json").len == 1  # edits changed since

  test "built page must match digest it was published at, and README its URL":
    let
      built = {"docket": "a1", "marginalia": "b2"}.toTable
      register = %*{
        "docket": {"url": "https://x/1", "digest": "a1"},
        "marginalia": {"url": "https://x/2", "digest": "b0"},
        "retired": {"url": "https://x/3", "digest": "c3"},
      }
      readme = "Pages: https://x/1 and https://x/2 and https://x/3."
      findings = checkPublished(built, register, readme, "pages/published.json")
    check findings.len == 2  # marginalia changed, retired page left in register
    check "`marginalia`" in findings[0].message or "`marginalia`" in findings[1].message
    check checkPublished(built, register, "Pages: https://x/1.", "p").len == 4  # two URLs unnamed

suite "Designs":
  const
    DIRECTORY = "designs/sign"
    RECORD = "# Sign\n\nWhy.\n"

  test "design reads title, base design and claims of every known kind":
    let
      claims = %*{"builds_on": "base", "claims": [{"kind": "suites"},
        {"kind": "build", "algebra": "rga6d", "metric": "peakmem", "at_most": 0.7},
        {"kind": "program", "path": "designs/sign/p.nim", "algebras": ["rga4d"]}]}
      (design, findings) = parseDesign("sign", RECORD, "", claims, DIRECTORY)
    check findings.len == 0 and design.title == "Sign"  # well formed
    check design.builds_on == "base" and design.claims.len == 3  # chain and claims
    check design.programsOf == @["designs/sign/p.nim"]  # programs claims run

  test "unknown claim, missing title and claims that are not JSON are findings":
    let
      odd = %*{"claims": [{"kind": "vibes"}]}
      (_, unknown) = parseDesign("sign", RECORD, "", odd, DIRECTORY)
      (_, untitled) = parseDesign("sign", "Why.\n", "", %*{"claims": []}, DIRECTORY)
      (_, broken) = parseDesign("sign", RECORD, "", nil, DIRECTORY)
    check unknown.len == 1 and "`vibes`" in unknown[0].message  # never skipped in silence
    check untitled.len == 1 and untitled[0].path == DIRECTORY & "/design.md"  # needs title
    check broken.len == 1 and broken[0].path == DIRECTORY & "/claims.json"  # needs object


suite "Trials":
  func run(ns: openArray[(string, float, float)]): JsonNode =
    ## Shape one bench run: library median and NaN share per measurand.
    result = %*{"measurands": {}}
    for (id, time, nan) in ns:
      result["measurands"][id] = %*{"library": {"ns_median": time, "nan_share": nan}}

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
    check editsDigest([one], claims, @[]) == editsDigest([reworded], claims, @[])  # prose
    check editsDigest([one], claims, @[]) != editsDigest([one], %*[], @[])  # claims
    check editsDigest([one], claims, @["a"]) != editsDigest([one], claims, @["b"])  # program


suite "Cells":
  test "table reads cell for cell, sign included, in both cell shapes":
    let wedge = cells(CAYLEYS_WEDGE.base)
    check wedge["E1,E2"] == %*[{"to": "E12", "neg": false}]  # 𝐞₁ ∧ 𝐞₂ = 𝐞₁₂
    check wedge["E2,E1"] == %*[{"to": "E12", "neg": true}]  # antisymmetric
    check not wedge.hasKey("E1,E1")  # vector wedge itself vanishes
    check cells(CAYLEY_ATTITUDE).len > 0  # 1D table of `Option` cells reads too


suite "Pages":
  test "shell names faces it embeds, and assembly fills every token":
    let
      shell_text = "<title>@TITLE@</title><style>src: url(@EMBED:a.woff2@)</style>@BODY@"
      page = assemble(shell_text, "A & B", "<p>body</p>", {"a.woff2": "xyz"}.toTable)
    check facesAsked(shell_text) == @["a.woff2"]  # one face asked
    check "@" notin page and "A &amp; B" in page and "<p>body</p>" in page  # filled
    check "data:font/woff2;base64,eHl6" in page  # bytes inlined

  test "noise band is assumed until quiet trials give enough ratios":
    let quiet = %*{"algebras": {"rga4d": {"functions": {}, "times": {"a": [1.0, 1.0, 1.0]}}}}
    check bandOf([quiet]).count == 0  # too few ratios: band assumed
    check bandOf([quiet]).low < 1.0 and bandOf([quiet]).high > 1.0  # around no change

  test "every grid in shell bounds its columns, so wide content scrolls in place":
    const SHELL = staticRead("../pages/shell.html")
    var unbounded: seq[string]
    for rule in SHELL.split('}'):
      let body = rule.split('{')
      if body.len < 2 or "display: grid" notin body[^1]: continue
      if "grid-template-columns" notin body[^1]: unbounded.add body[^2].strip
    check unbounded.len == 0  # grid child of auto width widens page at phone width
    if unbounded.len > 0: echo "unbounded: ", unbounded.join(", ")

  test "docket rows carry identifiers docket file allots":
    let
      sheet = Sheet(name: "rga4d", title: "Rigid 4D", dimensions: 4,
        static_measurements: %*{"measurands": {"wedge": {"library": "∧(M,M)", "symbol": "∧"}},
          "functions": {"∧(M,M)": {"total": {"multiplies": 81}}}},
        runtime_measurements: %*{"taken": {"date": "d", "machine": "m"}, "measurands": {}})
      ids = %*{"schema": 1, "kind": "docket", "next": 8, "ids": {"rga4d/wedge": "G007"}}
    check "G007 · ∧" in docketBody([sheet], ids, [], "bd6b23c590d7", "")  # shown beside symbol

  test "verdict chips say when trial removes NaN results":
    let
      baselines = {"rga4d": %*{"measurands": {}}}.toTable
      trial_document = %*{"pin_suites": {"rga4d": {"ok": 1, "failed": 0}}, "algebras": {"rga4d": {
        "suites": {"ok": 1, "failed": 0}, "functions": {}, "times": {},
        "nan": {"norm": [0.5, 0.0]}}}}
      chips = verdictChips(trial_document, baselines, Band(low: 0.9, high: 1.1))
    check "NaN gone in 1" in chips and "chip pass" in chips  # gain named, suites held
    check "no trial" in verdictChips(nil, baselines, Band())  # absent trial is said


suite "Driver":
  const DRIVER = staticRead("../tools/build.nim")

  func dispatched(source: string): seq[string] =
    ## Read verbs driver's dispatch answers to: quoted labels of `of` branches after case.
    let start = source.find("case paramStr(1)")
    for line in source[start ..< source.len].splitLines:
      let s = line.strip
      if s.startsWith("of \""):
        result.add s[4 ..< s.find('"', 4)]

  func taught(source: string): seq[string] =
    ## Read verbs usage string teaches, between its angle brackets.
    let
      open = source.find("\"<")
      close = source.find(">", open)
    source[open + 2 ..< close].split('|')

  func tabled(source: string): seq[string] =
    ## Read verbs header table rows, first cell of each row naming one.
    for line in source.splitLines:
      if not line.startsWith("##   | "): continue
      let cell = line[7 ..< line.find('|', 7)].strip
      if cell.len > 0 and cell != "Command" and not cell.startsWith("-"): result.add cell

  test "dispatch answers to every verb usage and header teach, and no other":
    check dispatched(DRIVER).sorted == taught(DRIVER).sorted  # usage string
    check dispatched(DRIVER).sorted == tabled(DRIVER).sorted  # header table
    check "inspect" in dispatched(DRIVER) and "bench" in dispatched(DRIVER)  # README's verbs

  test "header table names files verbs write":
    check "`baseline/runtime_<algebra>.json`" in DRIVER  # what `bench` records
    check "`baseline/static_<algebra>.json`" in DRIVER  # what `baseline` records
    check "| drive     | inspect, guard," in DRIVER  # drive runs guard, not retired check
    check "`trials/<name>.json`" in DRIVER and "`pages/published.json`" in DRIVER  # what they write
