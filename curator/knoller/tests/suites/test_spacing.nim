## Hold spaces inside expressions to X.9 list: each breach whose rewrite moves no reading is
##   reported and fixed; asymmetric spacing, which lexer reads, is neither; fix changes nothing
##   else, and nothing second time; fix never splits or merges token (Architect).

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/knoller/[reports, spacing, tokens]


const
  STACKED =
    "let d = (|∙ ⊖(m ∧ n)) div (|∙ (⊖m ∧ ⊖n))\nlet x = - -y\nlet z = -  -y + (+ -1)\n"
    ## Prefix operator before operand opening with operator character, which glued would merge:
    ##   glyph form of `suites.nim` of PGA library, and ASCII form.
  FIXTURES = [
    "let x = a+b*c  -  d\nlet t = a  and  b\n",
    "let r = 0..<n\nlet s = x[1..2]\nfor i in 0  ..  3: discard\nlet t = x[1..^1]\n",
    "let s = x[1 .. ^ 1]\nlet x = - y\nf(@ [1], ^ 2)\nlet y = - 1\n",
    "f(a,b ,c,  d)\nproc f(x:int, y :string) = discard\nlet t = {\"a\":1}\n",
    "func f(a, b: int;c: string ; d: char): int = a\n",
    "f( a, b )\nlet s = @[ 1 ]\nproc g() {. inline .}\nlet u = ( |∙ x)\n",
    "f(a=1, b  =  2)\nproc g(a=1)= discard\nx=1\nlet y  =2\nx=-1\n",
    "let z = PI*(a + b)\nf(c, d*[1])\n",
    STACKED,
  ]
    ## Breaches suite fixes, one of each rule, stacked prefix operators among them.


func fixed(source: string): string =
  ## Fix spacing of source, as `koch fix` does.
  fixSpacing("a.nim", source).source


func isSettled(source: string): bool =
  ## Decide whether source reports no spacing finding and fixes to itself again.
  checkSpacing("a.nim", source).len == 0 and fixSpacing("a.nim", source).source == source and
    fixSpacing("a.nim", source).fixed.len == 0


func spellings(source: string): seq[string] =
  ## Read spelling of each token of source, in order, operator tokens among them.
  source.tokens.mapIt(it.spelling(source))



suite "Spacing":
  test "binary operator spaced on neither side or wider on both takes one space each side":
    let breach = "let x = a+b*c  -  d\nlet t = a  and  b\n"
    check checkSpacing("a.nim", breach).len == 4  # `+`, `*`, `-`, `and`
    let mended = breach.fixed
    check mended == "let x = a + b * c - d\nlet t = a and b\n"
    check mended.isSettled
    check checkSpacing("a.nim", "m∧n")[0].message.endsWith("got `m∧n`.")  # glyph operator


  test "range operator takes no space, unless piece binds tighter or glued tokens would merge":
    for (breach, mended) in [
      ("let r = 2 .. 6\n", "let r = 2..6\n"),
      ("let r = 0 ..< n\n", "let r = 0..<n\n"),
      ("let r = x in 2 .. 6\n", "let r = x in 2..6\n"),  # looser `in` ends piece
      ("let r = a.b .. c.d\n", "let r = a.b..c.d\n"),  # field stands inside piece
      ("let r = range[0 .. 3]\n", "let r = range[0..3]\n"),
      ("let r = x == b .. c\n", "let r = x == b..c\n"),  # looser `==` ends piece
      ("let r = i + 1..<n\n", "let r = i + 1 ..< n\n"),  # `+` binds tighter than range
      ("let r = s[1 ..^ 1]\n", "let r = s[1..^1]\n"),  # compound operator stays whole
      ("let r = 'a'  ..  'z'\n", "let r = 'a'..'z'\n"),
    ]:
      check checkSpacing("a.nim", breach).len == 1
      check breach.fixed == mended
      check mended.isSettled
    check checkSpacing("a.nim", "let r = 2 .. 6\n")[0].message.startsWith(
      "Range operator takes no space",
    )
    check checkSpacing("a.nim", "let r = i + 1..<n\n")[0].message.startsWith(
      "Range operator takes one space on each side where",
    )
    for kept in [
      "let r = i + 1 ..< len(d)\n",  # `+` binds tighter than range
      "let r = m ∧ n .. k\n",  # glyph binds at 9
      "let s = x[1 .. ^1]\n",  # glued, `..^` would lex one operator
      "let s = 0 .. -1\n",  # glued, `..-` would lex one operator
      "let r = f(i + 1)..n\n",  # spaces inside bracket do not count
    ]:
      check kept.isSettled
    check "let s = a..\n  b\n".fixed == "let s = a ..\n  b\n"  # range ending line takes one before
    check "let s = x[1 .. ^ 1]\n".fixed == "let s = x[1 .. ^1]\n"  # `^` after range is prefix
    for kept in ["echo a ..b\n", "let s = a.. b\n"]:
      check checkSpacing("a.nim", kept).len == 0  # asymmetric, as for binary operator
      check kept.fixed == kept


  test "asymmetric spacing stays, since lexer reads it: `a -b` is call of prefix operand":
    for kept in ["echo -b\n", "a- b\n", "echo $x & y\n", "f(x)  -y\n", "a ⊖b\n"]:
      check checkSpacing("a.nim", kept).len == 0  # neither reported
      check kept.fixed == kept  # nor rewritten


  test "operator ending line takes one space before it":
    check "let s = \"a\"&\n  \"b\"\n".fixed == "let s = \"a\" &\n  \"b\"\n"
    check "let s = a  &  # Why.\n  b\n".fixed == "let s = a &  # Why.\n  b\n"  # comment ends line


  test "prefix operator is glued to its operand, but minus before number stays":
    check "let x = - y\nf(@ [1], ^ 2)\n".fixed == "let x = -y\nf(@[1], ^2)\n"
    check checkSpacing("a.nim", "let x = - 1\n").len == 0  # glued would be literal `-1`


  test "prefix operator before operator keeps one space, since glued pair lexes one operator":
    check STACKED.fixed ==
        "let d = (|∙ ⊖(m ∧ n)) div (|∙(⊖m ∧ ⊖n))\nlet x = - -y\nlet z = - -y + (+ -1)\n"
    check STACKED.fixed.isSettled  # spaced form passes check
    for kept in ["let d = (|∙ ⊖(m ∧ n))\n", "let x = - -y\n", "let x = + -1\n", "f($ -x)\n"]:
      check kept.isSettled  # `|∙⊖`, `--`, `+-` and `$-` would each lex as one operator
    let found = checkSpacing("a.nim", "let x = -  -y\n")
    check found.len == 1
    check found[0].message.startsWith("Prefix operator takes one space before operand it would")
    check found[0].message.endsWith("got `-  -y`.")


  test "fix reads every token as written, operator tokens among them, so splits and merges none":
    for source in FIXTURES:
      check source.fixed.spellings == source.spellings
      check source.fixed.isSettled


  test "comma and colon take no space before them and one after":
    check "f(a,b ,c,  d)\n".fixed == "f(a, b, c, d)\n"
    check "proc f(x:int, y :string) = discard\nlet t = {\"a\":1}\n".fixed ==
      "proc f(x: int, y: string) = discard\nlet t = {\"a\": 1}\n"
    check checkSpacing("a.nim", "f(a,b)\n")[0].message.startsWith("Comma takes")
    check checkSpacing("a.nim", "let a: int\nlet e = {:}\n").len == 0  # empty table stays


  test "semicolon takes no space before it and one after, as comma does":
    check "func f(a, b: int;c: string ; d: char): int = a\n".fixed ==
      "func f(a, b: int; c: string; d: char): int = a\n"
    check "a = 1;b = 2\n".fixed == "a = 1; b = 2\n"
    check checkSpacing("a.nim", "f(a, b: int;c: X)\n")[0].message.startsWith("Semicolon takes")
    check "proc f(a, b: int;\n       c: X) = discard\n".isSettled  # line break is not gap


  test "bracket holds no space inside it, and prefix operator after it glues":
    check "f( a, b )\nlet s = @[ 1 ]\nproc g() {. inline .}\nlet u = ( |∙ x)\n".fixed ==
      "f(a, b)\nlet s = @[1]\nproc g() {.inline.}\nlet u = (|∙x)\n"
    check checkSpacing("a.nim", "f( a)\n")[0].message.startsWith("Bracket holds")


  test "gap that would merge two tokens stays: `[:`, colon after operator":
    for kept in ["let a = b[ : c]\n", "type T = object\n  x* : int\n"]:
      check kept.fixed == kept


  test "`=` takes one space each side, wherever it stands":
    check "f(a=1, b  =  2)\nproc g(a=1)= discard\nx=1\nlet y  =2\n".fixed ==
      "f(a = 1, b = 2)\nproc g(a = 1) = discard\nx = 1\nlet y = 2\n"
    check checkSpacing("a.nim", "x=1\n")[0].message.startsWith("`=` takes one space")
    for kept in ["Foo(a: 1)\n", "proc f() =\n  discard\n"]:
      check kept.fixed == kept
    check "x=-1\n".fixed == "x =- 1\n"  # `=-` is one operator, as lexer reads it


  test "never read: export marker, type colon, field dot, paths of imports, strings, comments":
    let kept = "import std/os, ../a\nexport b/c\nproc f*(x: int): int = x.y\n" &
      "type T* = object\n  a*, b*: int\nlet s = \"a+b\"  # c+d\nlet q = `+`(1, 2)\n" &
      "proc `+`*(a, b: T): T = a\nvar u*, v*: int\n"
    check checkSpacing("a.nim", kept).len == 0
    check kept.fixed == kept


  test "glued `*` after name inside expression multiplies, since such name declares nothing":
    check "let z = PI*(a + b)\nf(c, d*[1])\n".fixed == "let z = PI * (a + b)\nf(c, d * [1])\n"


  test "fix never writes wide line; finding stays for hand":
    let line = "let a = " & "x".repeat(89) & "+y\n"  # 99 runes; spaced, 101
    check checkSpacing("a.nim", line).len == 1
    check line.fixed == line


  test "fix held on no line widens it, and keeps width guard on held line":
    let
      line = "let a = " & "x".repeat(89) & "+y\n"  # 99 runes; spaced, 101
      spaced = "let a = " & "x".repeat(89) & " + y\n"
    check fixSpacing("a.nim", line, Held()).source == spaced  # no line held: widens
    check fixSpacing("a.nim", line, Held(lines: @[2])).source == spaced  # other line held
    check fixSpacing("a.nim", line, Held(lines: @[1])).source == line  # its line held
    check fixSpacing("a.nim", line, EVERY).source == line  # every line held, as two arguments


  test "clean source passes through unchanged":
    let clean = "let x = a + b\nfor i in 0..<n: echo -i\nf(name = 1, b: 2)\n"
    check clean.isSettled
    check fixSpacing("a.nim", clean).fixed.mapIt(it.line).len == 0
