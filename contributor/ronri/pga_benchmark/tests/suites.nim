## Replicate laws of `pga_benchmark` under one algebra; stubs beside this file pick which.
##   Every stub names its algebra on its `matrix:` line, so `nim.cfg`'s default never
##   decides what ran. Library sources are read at compile time from Atlas checkout, so
##   catalogue is held to what library exports rather than to what this project remembers.

import std/[algorithm, macros, sequtils, unittest]

import ../src/pga_benchmark


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
