## Replicate Article X.2 and X.9 checks of knoller's form, and its fixers, on Nim source.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/knoller/[form, reports]


func fixed(source: string): Fix =
  ## Fix form of Nim source, as `koch fix` does, each line held.
  result.source = source
  for step in FORM_STEPS: result = result.chain(step.run("a.nim", result.source, EVERY))


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


  test "fix held on no line widens it, and keeps width guard on held line":
    let
      near = "x".repeat(LINE_MAX - 4) & " # c\n"  # 100 runes; two-space gap makes 101
      spaced = "x".repeat(LINE_MAX - 4) & "  # c\n"
      tab = "let s = \"" & "x".repeat(LINE_MAX - 12) & "\t\"\n"  # 99 runes; escaped, 100
      wide_tab = "let s = \"" & "x".repeat(LINE_MAX - 11) & "\t\"\n"  # 100 runes; escaped, 101
    check fixComments("a.nim", near, Held()).source == spaced  # no line held: widens
    check fixComments("a.nim", near, Held(lines: @[1])).source == near  # its line held
    check fixComments("a.nim", near, EVERY).source == near  # every line held
    var step = Fix(source: wide_tab)
    for each in FORM_STEPS: step = step.chain(each.run("a.nim", step.source, Held()))
    check step.source == wide_tab.replace("\t", "\\t")  # tab escape widens off held lines
    check fixed(wide_tab).source == wide_tab  # and stays where every line is held
    check fixed(tab).source == tab.replace("\t", "\\t")  # escape that fits is written


  test "X.1 plain trailing comment widening its line takes own line above, where it fits":
    let
      code = "      check camera.placed(framed).pivot =~ camera.pivot"
      comment = "# Orbit turned; what it turns about did not."
      wide = code & "  " & comment & "\n"  # 101 runes
      fix = fixCommentsAbove("a.nim", "x = 1\n" & wide)
    check fix.source == "x = 1\n      " & comment & "\n" & code & "\n"  # indent of its line
    check fix.fixed.mapIt(it.line) == @[2] and fix.origin == @[1, 2, 2, 3]  # both trace to it
    check checkCommentsAbove("a.nim", wide).mapIt(it.rule) == @[Rule.CommentAbove]
    for kept in [
      code & "  " & comment.replace("# ", "## ") & "\n",  # doc, which doc position moves
      code & "  # Fits.\n",  # narrow line
      code & "  # " & "x".repeat(42) & " " & "y".repeat(51) & "\n",  # comment fits no line
      "let s = \"\"\"\nx\"\"\" & " & "y".repeat(80) & "  # Inside long string.\n",  # no line above
    ]:
      check fixCommentsAbove("a.nim", kept).source == kept
      check checkCommentsAbove("a.nim", kept).len == 0


  test "clean source passes through unchanged":
    let clean = "## Do.\n\nlet a = \"x # y\"  # Two.\n# Whole line.\n"
    check fixed(clean).source == clean and fixed(clean).fixed.len == 0  # nothing rewritten
