## Replicate laws of `pga_benchmark` under one algebra; stubs beside this file pick which.
##   Every stub names its algebra on its `matrix:` line, so `nim.cfg`'s default never
##   decides what ran. Library sources are read at compile time from Atlas checkout, so
##   catalogue is held to what library exports rather than to what this project remembers.

import std/[algorithm, macros, sequtils, strutils, unittest]

import ../src/pga_benchmark
import ../src/pga_benchmark/probes


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
