## Replicate Article X.4: condition mixing `and` with `or` is parenthesised, as parser groups
##   it, and `not` over binary expression is reported for hand; fix changes nothing else, and
##   nothing second time.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/knoller/precedence


func fixed(source: string): string =
  ## Fix precedence of source, as `koch fix` does.
  fixMixtures("a.nim", source).source


func isSettled(source: string): bool =
  ## Decide whether source reports no mixture and fixes to itself again.
  checkMixtures("a.nim", source).len == 0 and fixMixtures("a.nim", source).fixed.len == 0



suite "Article X":
  test "X.4 each run of `and` between `or` takes parentheses, as parser groups it":
    check "if a and b or c: discard\n".fixed == "if (a and b) or c: discard\n"
    check "let x = a or b and c\n".fixed == "let x = a or (b and c)\n"
    check "x = a and b or c and d xor e\n".fixed == "x = (a and b) or (c and d) xor e\n"
    check "let y = not a and b.c(d) or e[0] == 1\n".fixed ==
      "let y = (not a and b.c(d)) or e[0] == 1\n"  # `not` and `==` bind inside run
    check "f(a and b or c, d)\n".fixed == "f((a and b) or c, d)\n"  # inside call
    check "if a and b or c:\n  x\n".fixed.isSettled


  test "X.4 command call holds its expression after head; space before parenthesis kept":
    check "check a and b or c\n".fixed == "check (a and b) or c\n"
    check "doAssert x.y == 1 and z or w, \"why\"\n".fixed ==
      "doAssert (x.y == 1 and z) or w, \"why\"\n"


  test "X.4 expression spans lines, delimiters bound it, and parentheses or one operator stay":
    check "if a and\n    b or c:\n  discard\n".fixed == "if (a and\n    b) or c:\n  discard\n"
    for kept in [
      "if (a and b) or c: discard\n",  # already grouped
      "if a and (b or c): discard\n",  # `or` inside group, `and` alone outside
      "let x = a and b\nlet y = c or d\n",  # two statements
      "for x in a and b or c: discard\n".replace(" or c", ""),  # loop head, no `or`
      "let s = \"a and b or c\"  # a and b or c\n",  # string and comment
      "proc f(x: int or float) = discard\n",  # type class, no `and`
      "if x.type is int and a or b: discard\n".replace(" or b", ""),  # field keyword
    ]:
      check checkMixtures("a.nim", kept).len == 0
      check kept.fixed == kept


  test "X.4 finding names line and expression; fix never writes wide line":
    let found = checkMixtures("a.nim", "let a = 1\nif a and b or c: discard\n")
    check found.mapIt(it.line) == @[2]
    check found[0].message.endsWith("got `a and b or c`.")
    let near = "if " & "x".repeat(77) & " and b or c: discard\n"  # 100 runes; parentheses 102
    check near.fixed == near
    check checkMixtures("a.nim", near).len == 1  # finding stays for hand


  test "X.4 `not` over binary expression is reported, since Nim reads `(not a) == b`":
    let found = checkNegations("a.nim", "let x = not a == b\nlet y = not a.b(c) in s\n")
    check found.mapIt(it.line) == @[1, 2]
    check found[0].message.endsWith("got `not a == b`.")
    for kept in [
      "let x = not (a == b)\n",  # parenthesised
      "let x = not a and b\n",  # `and` reads as expected
      "let x = (not a) == b\n",  # intent written
      "let x = not a.b\n",  # field, no operator
    ]:
      check checkNegations("a.nim", kept).len == 0
