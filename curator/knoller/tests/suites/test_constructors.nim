## Replicate STYLE.md §5 on constructor package calls both ways: subject test gives one answer for
##   one routine, so check reports form fewer calls across package take, and fix writes none.
##   Case held: `initElement(Basis.origin)` and `initElement(Basis.scalar, 𝐬 / 𝑡)` beside four
##     dotted calls, lines 398 of `pga/operators.nim` and 344 of `tests/suites.nim` of PGA library
##     at `3d9696e` (rule 15 of #443). Domain: each form, each tie, and each call of neither form.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/knoller/[constructors, rules]


const
  DECLARING = "func initElement*(b: Basis, scalar = 1.0): Multivector = discard\n"
    ## Module declaring constructor of package, as `pga/multivectors.nim` does.
  OPERATORS =
    "const e = initElement(Basis.origin)\n" &
    "let h = g.basis.initElement(if g.is_negated: -1 else: 1)\n" &
    "const f = Basis.infinity.initElement()\n"
    ## Calls of `pga/operators.nim`: one prefix, two by dot.
  SUITES =
    "for b in Basis: elements[b] = b.initElement(1)\n" &
    "let e = Basis.scalar.succ.initElement\n" &
    "check x =~ initElement(Basis.scalar, s / t) + y\n"
    ## Calls of `tests/suites.nim`: two by dot, one prefix.


func reported(sources: openArray[string]): seq[(int, int, string)] =
  ## Report each call of constructor in each source, as index of source, line and message, each
  ##   of rule of conversion prefix, else message names rule it got.
  let calls = callsConstructor(sources)
  for k, source in sources:
    for report in checkConstructors("a.nim", source, calls):
      let message = if report.rule == Rule.PrefixConversion: report.message else: $report.rule
      result.add (k, report.line, message)



suite "Style §5":
  test "form fewer calls of constructor take across package reports, and fix writes none":
    let calls = callsConstructor([DECLARING, OPERATORS, SUITES])
    check calls.mapIt((it.name, it.dotted, it.prefixed)) == @[("initElement", 4, 2)]
    let found = reported([DECLARING, OPERATORS, SUITES])
    check found.mapIt((it[0], it[1])) == @[(1, 1), (2, 3)]  # each prefix call
    check found[0][2] == "Routine takes one call form on plain first argument across package, " &
      "where `4` calls take dot; got `initElement(Basis.origin)`."
    check found[1][2].endsWith("got `initElement(Basis.scalar, s / t)`.")
    let fewer = reported([DECLARING, "let a = initElement(x)\nlet b = initElement(y, 2)\n" &
      "let c = z.initElement\n"])
    check fewer.mapIt(it[1]) == @[3]  # dotted call is one fewer
    check fewer[0][2].endsWith("`2` calls take prefix call; got `z.initElement`.")
    let tie = reported([DECLARING, "let a = initElement(x)\nlet c = z.initElement(1)\n"])
    check tie.mapIt(it[1]) == @[1, 2]  # both forms where they tie
    check tie.allIt("`1` calls take each form" in it[2])


  test "call of neither form, constructor of no package, and routine of other verb count none":
    for neither in [
      "let a = initElement(x + y)\n",  # compound first argument
      "let a = initElement()\n",  # no argument
      "let a = initElement[float](x)\n",  # generic call
      "let a = initElement x\n",  # command call
      "let a = (x + y).initElement\n",  # compound receiver
      "import pga/multivectors\nlet a = multivectors.initElement(x)\n",  # module path
      "let a = initTable[string, int]()\nlet b = t.initTable\n",  # constructor no file declares
      "let a = initialize(x)\nlet b = x.initialize\n",  # `init` before no capital
      "let s = \"initElement(x)\"  # x.initElement\n",  # string and comment
    ]:
      let calls = callsConstructor([DECLARING, neither])
      check calls.mapIt(it.dotted + it.prefixed) == @[0]
    check callsConstructor(["let a = x.initFoo\nlet b = initFoo(y)\n"]).len == 0  # undeclared
