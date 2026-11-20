## Replicate STYLE.md §5 on `to<Target>` call of compound argument: it stays prefix call, so no
##   parentheses hide it; fix gives group's parentheses to call, and writes nothing second time.
##   Case held: `(not b.toFlags and mask).toBasis` and `(|𝐦).toMultivector` stayed by dot, lines
##     617 of `pga/cayleys.nim` and 344 of `tests/suites.nim` of PGA library at `3d9696e`
##     (rule 15 of #443); `test_regressions.nim` holds both through whole chain.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/knoller/[prefixes, rules]


func fixed(source: string): string =
  ## Fix `to<Target>` calls of compound argument in source, as `koch fix` does.
  fixPrefixes("a.nim", source).source


func isSettled(source: string): bool =
  ## Decide whether source reports no prefix finding and fixes to itself again.
  checkPrefixes("a.nim", source).len == 0 and fixPrefixes("a.nim", source).fixed.len == 0


func nested(depth: int): string =
  ## Write line of `to<Target>` call nested `depth` deep, each around compound argument.
  result = "(a + b).toX"
  for _ in 2 .. depth: result = "(" & result & " + c).toX"
  result = "let m = " & result & "\n"



suite "Style §5":
  test "`to<Target>` of compound argument by dot becomes prefix call, group's parentheses its own":
    for (given, written) in [
      ("let b = (not f.toFlags and mask).toBasis.toSigned\n",
       "let b = toBasis(not f.toFlags and mask).toSigned\n"),  # chain goes on after call
      ("check ^((|m).toMultivector) =~ x\n", "check ^(toMultivector(|m)) =~ x\n"),  # operator
      ("let s = ($rule).toLowerAscii\n", "let s = toLowerAscii($rule)\n"),  # `to` and capital
      ("let m = (a + b).toMultivector\n", "let m = toMultivector(a + b)\n"),
      ("let m = (-v).toMultivector\n", "let m = toMultivector(-v)\n"),
      ("let m = (a + b).toX(c)\n", "let m = toX(a + b, c)\n"),  # arguments follow group
      ("let m = (a + b).toX()\n", "let m = toX(a + b)\n"),  # empty call
      ("let m = ((a + b).toX + c).toY\n", "let m = toY(toX(a + b) + c)\n"),  # inner first
    ]:
      check given.fixed == written
      check written.isSettled
    let found = checkPrefixes("a.nim", "let a = 1\nlet m = (a + b).toMultivector\n")
    check found.mapIt((it.line, it.rule)) == @[(2, Rule.PrefixConversion)]
    check found[0].message.endsWith("got `(a + b).toMultivector`.")
    check fixPrefixes("a.nim", "let m = (a + b).toX\n").fixed.mapIt(it.line) == @[1]


  test "fixer takes 8 passes at most, inner call first, so deeper nest waits for next run":
    # Case of review of record: `PASSES_MAX` held no case; each pass writes calls whose spans
    #   hold none, so nest of 8 settles in one run, and nest of 9 leaves its outer call.
    check nested(8).fixed.isSettled
    let left = nested(9).fixed
    check checkPrefixes("a.nim", left).len == 1
    check left.fixed.isSettled


  test "plain group, literal, tuple, call and other name stay; generic and wrapped call report":
    for kept in [
      "let m = (a).toMultivector\n",  # one plain operand: no compound
      "let m = (a.b[0]).toMultivector\n",  # plain operand with field and index
      "let m = (1).toMultivector\n",  # one literal
      "let m = (a, b).toMultivector\n",  # tuple is no group
      "let m = f(a + b).toMultivector\n",  # parentheses of call
      "let m = (a + b).len\n",  # no `to<Target>`
      "let m = (a + b).topology\n",  # no capital after `to`
      "let m = toMultivector(a + b)\n",  # prefix call already
      "let s = \"(a + b).toX\"  # (a + b).toX\n",  # string and comment
    ]:
      check kept.isSettled
    for (reported, line) in [
      ("let m = (a + b).toX[float]\n", 1),  # generic call
      ("let m = (a +\n    b).toX\n", 2),  # group spans lines
      ("let m = (a + b).toX(\n  c,\n)\n", 1),  # arguments span lines
    ]:
      check checkPrefixes("a.nim", reported).mapIt(it.line) == @[line]
      check reported.fixed == reported  # hand writes layout it chose
