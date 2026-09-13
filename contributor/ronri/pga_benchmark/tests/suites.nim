## Replicate laws of `pga_benchmark` under one algebra; stubs beside this file pick which.
##   Every stub names its algebra on its `matrix:` line, so `nim.cfg`'s default never
##   decides what ran. Library sources are read at compile time from Atlas checkout, so
##   catalogue is held to what library exports rather than to what this project remembers.

import std/[algorithm, compilesettings, json, macros, options, sequtils, strutils, tables, unittest]
from std/unicode import runeLen

import ../src/pga_benchmark
import ../src/pga_benchmark/[baseline, gaps, inspector, model, probes, report]


const
  LIBRARY =
    "../deps/replications.mraxilus.gitlab.com/lengyel/projective_geometric_algebra_illuminated"
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


macro spellsCompile(probes: static seq[Probe]): untyped =
  ## Emit one `check compiles(spell)` per probe, with `m` and `n` bound by operand kind.
  ##   Kinds without typed reference yet bind to library's own multivector.
  result = newStmtList()
  let (m, n) = (ident"m", ident"n")  # plain idents, so spell's own `m` and `n` bind
  for p in probes:
    let spell = parseExpr(p.spell)
    let kind_m = if p.operands[0] == Kind.Scalar: ident"float" else: ident"Multivector"
    let kind_n = if p.operands[1] == Kind.Scalar: ident"float" else: ident"Multivector"
    let id = newLit(p.id)
    result.add quote do:
      block:
        var `m` {.used.}: `kind_m`
        var `n` {.used.}: `kind_n`
        check compiles(`spell`)  # spell of `id` parses and resolves against library
        check `id`.len > 0  # id names row


macro checkReferences(probes: static seq[Probe]; chapter: static string): untyped =
  ## Emit one test per probe holding library spell on images to reference on typed objects.
  ##   Chapter "2" takes rows citing book equations of chapter 2; "3" takes rest, which
  ##   are motor, projection and support pages of rigidgeometricalgebra.org.
  ##   Operands pair pool slot i with slot j = (7i + 3) mod OBJECTS, so pairs vary.
  result = newStmtList()
  let (m, n) = (ident"m", ident"n")  # plain idents, so spell and reference bind them
  for p in probes:
    if p.reference.len == 0: continue
    if (chapter == "2") != p.cite.startsWith("2."): continue
    let spell = parseExpr(p.spell)
    let reference = parseExpr(p.reference)
    let library_m = parseExpr(libraryPoolName(p.operands[0], p.grade))
    let library_n = parseExpr(libraryPoolName(p.operands[1], p.grade))
    let reference_m = parseExpr(referencePoolName(p.operands[0]))
    let reference_n = parseExpr(referencePoolName(p.operands[1]))
    let name = newLit(p.id & "  # " & p.cite)
    result.add quote do:
      test `name`:
        for i in 0 ..< OBJECTS:
          let j = (i * 7 + 3) mod OBJECTS
          let expected = block:
            let `m` {.used.} = `reference_m`[i]
            let `n` {.used.} = `reference_n`[j]
            toMultivector(`reference`)
          let got = block:
            let `m` {.used.} = `library_m`[i]
            let `n` {.used.} = `library_n`[j]
            `spell`
          check got =~ expected  # library on images equals reference embedded
  if result.len == 0: result.add newNimNode(nnkDiscardStmt).add(newEmptyNode())


fillPools(0)


suite "Configuration":
  test "stub matrix names algebra umbrella reports":
    check DIMENSIONS in 2 .. 6  # library's own bound
    when DIMENSIONS == 4 and IS_RIGID:
      check CONFIG == "rga4d"  # 3D Euclidean rigid, default of nim.cfg
    when DIMENSIONS == 5 and IS_CONFORMAL:
      check CONFIG == "cga5d"  # 3D Euclidean conformal


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
    let ids = idsOf(PROBES) & idsOf(MISSING)
    check ids.deduplicate.len == ids.len  # one row per operation

  test "every spell compiles against library":
    spellsCompile(PROBES)

  test "symbols match every operator library exports":
    let exported = (
      symbolsIn(SOURCE_OPERATORS, IS_CONFORMAL) & symbolsIn(SOURCE_MULTIVECTORS, IS_CONFORMAL)
    ).filterIt(it notin EXCLUDED).deduplicate
    check symbolsOf(PROBES).sorted == exported.sorted  # no exported operator unmeasured

  test "templates name every symbol library spells over another":
    for (symbol, target) in TEMPLATES:
      let line = "template `" & symbol & "`*(m: Multivector): Multivector = " & target & " m"
      check line in SOURCE_OPERATORS  # one-line template, target's function is what C holds

  test "aliases match every name library's umbrella exports":
    let exported = aliasesIn(SOURCE_UMBRELLA, IS_CONFORMAL)
    let catalogued = (aliasesOf(PROBES) & aliasesOf(MISSING)).deduplicate
    check catalogued.sorted == exported.sorted  # missing ones counted as gaps, not forgotten


suite "Chapter 2":
  checkReferences(PROBES, "2")


suite "Chapter 3":
  checkReferences(PROBES, "3")


suite "Probes":
  test "summarise reads median and minimum per object":
    check summarise([300'i64, 100, 200], 100) == (median: 2.0, minimum: 1.0)  # odd count
    check summarise([400'i64, 100, 300, 200], 100) == (median: 2.5, minimum: 1.0)  # even count

  test "every probe yields finite positive figures and results reach sink":
    runProbes()
    check SINK != 0.0  # results folded, none dead
    for index, probe in PROBES:
      let figure = FIGURES[Side.Library][index]
      check figure.is_measured  # library side always spelled
      check figure.ns_median > 0.0 and figure.ns_median < 1.0e6  # per-object nanoseconds
      check figure.ns_min > 0.0 and figure.ns_min <= figure.ns_median  # minimum bounds median
      check FIGURES[Side.Reference][index].is_measured == (probe.reference.len > 0)  # side present


suite "Allocation":
  test "allocation gauge is live under this build":
    let before = getAllocStats()
    var control = newSeq[float](8)
    control[0] = 1.0
    let after = getAllocStats()
    check allocationsOf(after - before) > 0  # positive control: counter moved
    check control[0] == 1.0  # control kept alive

  test "no probe allocates on either side":
    runProbes()
    for index, probe in PROBES:
      for side in [Side.Library, Side.Reference]:
        let figure = FIGURES[side][index]
        if figure.is_measured:
          check figure.allocations == 0  # heap untouched over every round


suite "Inspector":
  test "mangled names demangle to symbols":
    check demangle("XE2X88XA7__u0__OOZdepsZpgaZoperators") == "∧"  # non-ASCII bytes
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

  test "functions are split and counted from fixture C":
    const MV = "tyObject_Multivector__h"
    const FIXTURE = [
      "N_LIB_PRIVATE N_NIMCALL(void, XE2X88XA7__u0__OOZpgaZoperators)(" & MV & "* m_p0, " &
        MV & "* n_p1, " & MV & "* Result) {",
      "\tNF* T1_;",
      "NF T2_;",
      MV & " T3_;",
      "NIM_BOOL* nimErr_;",
      "{",
      "\t\tnimErr_ = nimErrorFlag();",
      "nimZeroMem(((void*) Result), sizeof(" & MV & "));",
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
      "static N_INLINE(NF, dot_u0__referenceZrigid3)(tyObject_Vec3__h* a_p0, " &
        "tyObject_Vec3__h* b_p1) {",
      "\tNF result;",
      "result = ((((NF) (*a_p0).x) * ((NF) (*b_p1).x)) + (((NF) (*a_p0).y) * ((NF) (*b_p1).y)));",
      "\treturn result;",
      "}",
      "",
      "N_LIB_PRIVATE N_NIMCALL(void, declared__u0__mod)(" & MV & "* m_p0, " & MV & "* Result);",
    ].join("\n") & "\n"
    let functions = functionsIn(FIXTURE)
    check functions.len == 2  # declaration ending in `;` skipped
    check functions[0].symbol == "∧"  # head demangled
    check functions[0].params == @["Multivector", "Multivector"]  # stems in order
    check functions[0].result_stem == "Multivector" and not functions[0].is_inline  # via Result
    check functions[0].module == "OOZpgaZoperators"  # suffix after last `__`
    let c = count(functions[0].body)
    check c.multiplies == 2 and c.adds == 1 and c.subs == 1  # terms as spelled
    check c.zero_fills == 1 and c.temporaries == 1 and c.checks == 2  # fills, locals, branches
    check c.calls == 1  # norm call counted, accessor read not
    check functions[1].symbol == "dot" and functions[1].params == @["Vec3", "Vec3"]
    check functions[1].result_stem == "float" and functions[1].is_inline  # via return type
    check count(functions[1].body).multiplies == 2  # inline body counted alike
    check functions[0].key == "∧(Multivector,Multivector)"  # key spells stems

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
      symbol: "∧", params: @["Multivector", "Multivector"], result_stem: "Multivector"
    )
    let m = movement(f, Counts(zero_fills: 1, temporaries: 2, copies: 1), 128)
    check m.bytes_read == 256 and m.bytes_written == 128  # two in, one out
    check m.bytes_zeroed == 128 and m.bytes_copied == 128 and m.bytes_temporaries == 256
    check m.bytes_moved == 896  # sum of every cause
    check sizeOfStem("Point", 128) == 32 and sizeOfStem("float", 128) == 8  # typed sizes
    check sizeOfStem("Unknown", 128) == 0  # unknown stems add nothing

  test "own nimcache holds every catalogued symbol at its arity":
    const CACHE = querySetting(SingleValueSetting.nimcacheDir)
    let functions = inspectCache(CACHE)
    var keys: seq[string]
    for f in functions: keys.add f.key
    for p in PROBES:
      if p.symbol.len == 0: continue
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


suite "Baseline":
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
    ## Shape inspect document around functions.
    result = document(
      "inspect", configNode("rga4d", dimensions, false, 128),
      %*{"date": "2026-09-13", "machine": "m", "nim": "n", "pga": "p", "flags": flags},
    )
    result["functions"] = functions

  func one(key: string; f: JsonNode): JsonNode =
    ## Shape functions object holding one function.
    result = newJObject()
    result[key] = f

  test "equal documents pass with nothing to say":
    let same = one(KEY, node(81, 178, 1, 512))
    let v = compare(doc(same), doc(same), PATH)
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

  test "function absent on either side is finding":
    let before = compare(doc(one(KEY, node(81, 178, 1, 512))), doc(newJObject()), PATH)
    check before.findings.len == 1 and "absent now" in before.findings[0].message  # gone
    let after = compare(doc(newJObject()), doc(one(KEY, node(81, 178, 1, 512))), PATH)
    check after.findings.len == 1 and "absent from baseline" in after.findings[0].message  # new

  test "documents of another build are not compared":
    let same = one(KEY, node(81, 178, 1, 512))
    let flags = compare(doc(same), doc(same, flags = "-d:danger"), PATH)
    check flags.findings.len == 1 and "`flags`" in flags.findings[0].message  # build differs
    let dims = compare(doc(same), doc(same, dimensions = 5), PATH)
    check dims.findings.len == 1 and "`dimensions`" in dims.findings[0].message  # algebra differs
    let schema = compare(doc(same), %*{"schema": 2}, PATH)
    check schema.findings.len == 1 and "Schema differs" in schema.findings[0].message  # refused


suite "Gaps":
  const KEY_WEDGE = "∧(Multivector,Multivector)"

  func fn(
    symbol, module: string; is_inline: bool; multiplies, checks, zero_fills, bytes: int
  ): JsonNode =
    ## Shape one inspected function.
    let c = Counts(multiplies: multiplies, checks: checks, zero_fills: zero_fills)
    %*{
      "symbol": symbol, "module": module, "params": [], "returns": "", "inline": is_inline,
      "own": countsNode(c), "total": countsNode(c),
      "movement": movementNode(Movement(bytes_moved: bytes)),
    }

  func inspectDoc(): JsonNode =
    ## Shape inspect document: two library operators, one accessor, one reference form.
    result = document(
      "inspect", configNode("rga4d", 4, false, 128),
      %*{"date": "2026-09-13", "machine": "m", "nim": "n", "pga": "p", "flags": "f"},
    )
    var functions = newJObject()
    functions[KEY_WEDGE] = fn("∧", "pga/operators", false, 81, 178, 1, 512)
    functions["wedge(Point,Point)"] = fn("wedge", "reference/rigid3", true, 12, 0, 0, 112)
    functions["~(Multivector)"] = fn("~", "pga/operators", false, 0, 0, 1, 384)
    functions["[](Multivector,Basis)"] = fn("[]", "pga/multivectors", true, 0, 0, 0, 136)
    result["functions"] = functions
    result["probes"] = %*{
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

  func figure(ns: float): JsonNode =
    ## Shape one bench figure.
    %*{"ns_median": ns, "ns_min": ns, "allocations": 0, "nan_share": 0.0}

  func benchDoc(): JsonNode =
    ## Shape bench document over same probes.
    result = document(
      "bench", configNode("rga4d", 4, false, 128),
      %*{
        "date": "2026-09-13", "machine": "m", "rounds": 3, "objects": 64,
        "is_allocation_measured": true,
      },
    )
    result["probes"] = %*{
      "wedge": {"library": figure(24.1), "reference": newJNull()},
      "wedge_point_point": {"library": figure(24.1), "reference": figure(1.3)},
      "select_part": {"library": figure(0.5), "reference": newJNull()},
      "transform_point_motor": {"library": figure(60.0), "reference": figure(5.0)},
    }

  let ALGEBRAS = @[Algebra(config: "rga4d", inspect: inspectDoc(), bench: benchDoc())]

  func decidedOf(rule: Rule; algebras: seq[Algebra]; rows: seq[Row]): Decided =
    ## Decide design gap carrying rule.
    for d in DESIGNS:
      if d.rule == rule: return d.decideDesign(algebras, rows)

  test "rows are decided against reference and against zero":
    let rows = rowsOf(ALGEBRAS[0])
    check rows.len == 4  # one per probe
    let by = rows.mapIt((it.probe, it)).toTable
    check by["wedge"].status == Status.Open and "checks" in by["wedge"].open_on  # absolute
    check "multiplies" notin by["wedge"].open_on  # no reference, no relative target
    check by["wedge_point_point"].open_on ==
      @["multiplies", "bytes", "zero_fills", "checks", "time"]  # in decided order
    check by["select_part"].status == Status.Closed  # nothing spent, nothing exceeded
    check by["transform_point_motor"].open_on == @["time"]  # composed spell, timing alone

  test "row without counts or timing is unmeasured":
    let rows = rowsOf(Algebra(config: "rga4d", inspect: inspectDoc(), bench: nil))
    let by = rows.mapIt((it.probe, it)).toTable
    check by["transform_point_motor"].status == Status.Unmeasured  # nothing to decide on
    check "time" notin by["wedge_point_point"].open_on  # no bench, no time verdict

  test "register keeps identifiers across reorder and allots next to new key":
    var rows = rowsOf(ALGEBRAS[0])
    var register = registerOf(nil)
    rows.assign(register)
    check rows[0].id == "G001" and rows[3].id == "G004" and register.next == 5  # in order
    rows.reverse
    var again = registerOf(register.toJson)
    rows.assign(again)
    check rows[0].id == "G004" and rows[3].id == "G001" and again.next == 5  # never renumbered
    rows.add Row(key: "cga5d/wedge", config: "cga5d", probe: "wedge")
    rows.assign(again)
    check rows[^1].id == "G005" and again.next == 6  # next number, never one reused

  test "design gaps are decided by rule with evidence":
    let rows = rowsOf(ALGEBRAS[0])
    let checks = decidedOf(Rule.Checks, ALGEBRAS, rows)
    check checks.status == Status.Open and "1 of 3 library functions" in checks.evidence  # ∧
    check "`" & KEY_WEDGE & "` with 178" in checks.evidence  # most
    check decidedOf(Rule.Inline, ALGEBRAS, rows).evidence ==
      "1 of 3 library operators, e.g. rga4d `~(Multivector)`."  # light operator called
    check decidedOf(Rule.ZeroFills, ALGEBRAS, rows).evidence.startsWith("2 of 3")  # ∧ and ~
    check decidedOf(Rule.Terms, ALGEBRAS, rows).evidence ==
      "1 rows; widest rga4d/wedge_point_point spends 81 multiplies against 12."  # widest
    check decidedOf(Rule.Time, ALGEBRAS, rows).evidence ==
      "2 rows; worst rga4d/wedge_point_point at 24.1 ns against 1.3 ns."  # worst ratio
    check decidedOf(Rule.Nan, ALGEBRAS, rows).status == Status.Closed  # every share zero
    check decidedOf(Rule.Compound, ALGEBRAS, rows).evidence ==
      "rga4d/transform_point_motor."  # composed spell named
    check decidedOf(Rule.Missing, ALGEBRAS, rows).status == Status.Closed  # nothing missing
    check decidedOf(Rule.Cayley, ALGEBRAS, rows).status == Status.Unmeasured  # not readable here

  test "rendered list fits width and names every row":
    let (text, register) = generate(ALGEBRAS, registerOf(nil))
    var widest = 0
    for line in text.splitLines: widest = max(widest, runeLen(line))
    check widest <= WIDTH  # form check reads product
    check "| G002 | wedge_point_point | 81/12 | 512/112 | 0/0 | 178/0 | 24.1/1.3 | open |" in
      text  # cells read library/reference
    check "| G004 | transform_point_motor | – | – | – | – | 60.0/5.0 | open |" in
      text  # composed spell has no counts
    check "- **D05, open.**" in text and "- **D10, unmeasured.**" in text  # design verdicts
    check "Rows: 4; open 3, closed 1, unmeasured 0." in text  # summary
    check register.next == 5  # register grew with rows

  test "wrap breaks at spaces within width and indents continuation":
    check wrap("aa bb cc", 5) == @["aa bb", "cc"]  # fits, then breaks
    check wrap("aa bb cc", 5, "  ") == @["aa bb", "  cc"]  # continuation indented
    check wrap("∧∧∧ ∧∧∧", 3) == @["∧∧∧", "∧∧∧"]  # runes, not bytes
