## Hold operator spacing (Article X.9): each breach whose rewrite moves no reading is reported and
##   fixed; asymmetric spacing, which lexer reads, is neither; fix changes nothing else, and
##   nothing second time.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/[findings, spacing]


func fixed(source: string): string =
  ## Fix spacing of source, as `koch fix` does.
  fixSpacing("a.nim", source).source


func isSettled(source: string): bool =
  ## Decide whether source reports no spacing finding and fixes to itself again.
  checkSpacing("a.nim", source).len == 0 and fixSpacing("a.nim", source).source == source and
    fixSpacing("a.nim", source).fixed.len == 0


suite "Spacing":
  test "binary operator spaced on neither side or wider on both takes one space each side":
    let breach = "let x = a+b*c  -  d\nlet r = 0..<n\nlet s = x[1..^1]\nlet t = a  and  b\n"
    check checkSpacing("a.nim", breach).len == 6  # `+`, `*`, `-`, `..<`, `..^`, `and`
    let mended = breach.fixed
    check mended == "let x = a + b * c - d\nlet r = 0 ..< n\nlet s = x[1 ..^ 1]\nlet t = a and b\n"
    check mended.isSettled
    check checkSpacing("a.nim", "m∧n")[0].message.endsWith("got `m∧n`.")  # glyph operator

  test "asymmetric spacing stays, since lexer reads it: `a -b` is call of prefix operand":
    for kept in ["echo -b\n", "a- b\n", "echo $x & y\n", "f(x)  -y\n"]:
      check checkSpacing("a.nim", kept).len == 0  # neither reported
      check kept.fixed == kept  # nor rewritten

  test "operator ending line takes one space before it":
    check "let s = \"a\"&\n  \"b\"\n".fixed == "let s = \"a\" &\n  \"b\"\n"
    check "let s = a  &  # Why.\n  b\n".fixed == "let s = a &  # Why.\n  b\n"  # comment ends line

  test "prefix operator is glued to its operand, but minus before number stays":
    check "let x = - y\nf(@ [1], ^ 2)\n".fixed == "let x = -y\nf(@[1], ^2)\n"
    check checkSpacing("a.nim", "let x = - 1\n").len == 0  # glued would be literal `-1`

  test "named argument takes one space each side of `=`; default and assignment stay":
    check "f(a=1, b  =  2)\n".fixed == "f(a = 1, b = 2)\n"
    for kept in ["proc f(a=1) = discard\n", "x=1\n", "let y=2\n", "Foo(a: 1)\n"]:
      check kept.fixed == kept

  test "never read: export marker, type colon, field dot, paths of imports, strings, comments":
    let kept = "import std/os, ../a\nexport b/c\nproc f*(x: int): int = x.y\n" &
      "type T* = object\n  a*: int\nlet s = \"a+b\"  # c+d\nlet q = `+`(1, 2)\nlet z = a*(b)\n"
    check checkSpacing("a.nim", kept).len == 0
    check kept.fixed == kept

  test "fix never writes wide line; finding stays for hand":
    let line = "let a = " & "x".repeat(89) & "+y\n"  # 99 runes; spaced, 101
    check checkSpacing("a.nim", line).len == 1
    check line.fixed == line

  test "clean source passes through unchanged":
    let clean = "let x = a + b\nfor i in 0 ..< n: echo -i\nf(name = 1)\n"
    check clean.isSettled
    check fixSpacing("a.nim", clean).fixed.mapIt(it.line).len == 0
