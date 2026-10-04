## Replicate Article X.2 and X.9 checks of knoller's form, and its fixers, on Nim source.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/knoller/[form, reports]


func fixed(source: string): Fix =
  ## Fix form of Nim source, as `koch fix` does.
  result.source = source
  for fixer in FORM_FIXERS: result = result.chain(fixer("a.nim", result.source))


func gapMessage(spaces: int): string =
  ## Render X.9 finding message for gap of given spaces.
  "Trailing comment takes two spaces before its marker (X.9); got `" & $spaces & "`."


func gapMessages(source: string): seq[string] =
  ## Read X.9 finding messages of Nim source.
  checkComments("a.nim", source).mapIt(it.message)



suite "Article X":
  test "X.9 trailing comment takes exactly two spaces before its marker":
    check gapMessages("let a = 1  # Two.\n").len == 0  # two pass
    check gapMessages("let a = 1 # One.\n") == @[gapMessage(1)]  # one fails
    check gapMessages("let a = 1# None.\n") == @[gapMessage(0)]  # glued fails
    check gapMessages("  a: int     ## Field.\n") == @[gapMessage(5)]  # aligned column fails
    check gapMessages("let a = \"x\" # One.\n") == @[gapMessage(1)]  # after string
    check checkComments("a.nim", "a = 1\nb = 2 # c\n")[0].line == 2  # line named
    check COMMENT_GAP == 2  # X.9 count, stated once


  test "X.9 reads code alone: string, whole comment and block hold no trailing comment":
    check gapMessages("let a = \"x # y\"\n").len == 0  # `#` inside string
    check gapMessages("let a = '#'\n").len == 0  # `#` as char
    check gapMessages("# Whole line.\n  ## Doc line.\n").len == 0  # no code
    check gapMessages("#[ a\nb # c\n]#\n").len == 0  # inside block comment
    check gapMessages("let a = \"\"\"\nb # c\n\"\"\"\n").len == 0  # long string
    check gapMessages("{.used.}  # Used in b.nim.\n").len == 0  # pragma


  test "X.2 exact: three blank lines before first tier, two before second, one after either":
    let exact = "x = 1\n\n\n\n#[ Parent ]#\n\n\n#[[ Child ]]#\n\ny = 2\n\n\n#[[ Sibling ]]#\n\nz\n"
    check checkBanners("a.nim", exact).len == 0
    check checkBanners("a.nim", "x = 1\n\n\n#[ Section ]#\n\ny = 2\n").mapIt(it.message) ==
      @["First-tier banner takes three blank lines before it (X.2); got `2`."]
    check checkBanners("a.nim", "x = 1\n\n\n\n#[[ Child ]]#\n\ny = 2\n")[0].message ==
      "Second-tier banner takes two blank lines before it (X.2); got `3`."  # exactly two
    check checkBanners("a.nim", "x = 1\n\n\n\n#[ Section ]#\ny = 2\n")[0].message ==
      "Banner takes one blank line after it (X.2); got `0`."
    check checkBanners("a.nim", "#[ Opening ]#\n\nx\n").len == 0  # nothing above: no count
    check checkBanners("a.nim", "x\n\n\n\n#[ A ]#\n\n\n\n#[ B ]#\n\ny\n").len == 0  # no count



suite "Fixes":
  test "fix never writes line width check reports":
    let near = "x".repeat(LINE_MAX - 4) & " # c\n"  # 100 runes; two-space gap makes 101
    check fixed(near).source == near  # left to hand
    check gapMessages(near) == @[gapMessage(1)]  # finding stays


  test "clean source passes through unchanged":
    let clean = "## Do.\n\nlet a = \"x # y\"  # Two.\n# Whole line.\n"
    check fixed(clean).source == clean and fixed(clean).fixed.len == 0  # nothing rewritten
