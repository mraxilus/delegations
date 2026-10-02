## Replicate Article X.1, X.2, X.9 and VIII.5: form of source, and fixes form check names.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/[findings, form, kinds]


func messages(path, source: string; kind: Kind): seq[string] =
  ## Read finding messages of source under kind.
  checkForm(path, source, kind.rule).mapIt(it.message)


func fixed(source: string, kind = Kind.Nim): Fix =
  ## Fix form of source under kind, as `koch fix` does.
  fixForm("a.nim", source, kind.rule)


func gapMessage(spaces: int): string =
  ## Render X.9 finding message for gap of given spaces.
  "Trailing comment takes two spaces before its marker (X.9); got `" & $spaces & "`."


func gapMessages(source: string): seq[string] =
  ## Read X.9 finding messages of Nim source.
  checkComments("a.nim", source).mapIt(it.message)


suite "Article X":
  test "X.1 width counts runes, not bytes":
    check messages("a.nim", "é ".repeat(49) & "éé\n", Kind.Nim).len == 0  # 100 runes pass
    check messages("a.nim", "é ".repeat(49) & "ééé\n", Kind.Nim) ==
      @["Line exceeds 100 characters; got `101`."]  # 101 runes fail, breakable
    check messages("a.nim", "é".repeat(101) & "\n", Kind.Nim).len ==
      0  # one 101-rune token has no whitespace to break at
    check messages("LICENSE.md", "x".repeat(400) & "\n", Kind.Markdown).len == 0  # exempt

  test "X.1 line over limit passes only when breaking cannot fix it":
    let
      url = "https://fonts.googleapis.com/css2?family=" & "x".repeat(150)
      link = "<link rel=\"stylesheet\" href=\"" & url & "\">"
    check link.len > LINE_MAX and link.isUnbreakable  # one token, rest fits without it
    check messages("pages/x.html", link & "\n", Kind.Html).len == 0  # URL has no whitespace
    check messages("pages/x.html", "<p>" & "word ".repeat(40) & "</p>\n", Kind.Html) ==
      @["Line exceeds 100 characters; got `207`."]  # prose always breaks
    check messages("pages/x.svg", "<svg>" & "<circle/>".repeat(200) & "</svg>\n", Kind.Svg)
      .len == 1  # minified markup runs past TOKEN_MAX
    check not ("x".repeat(TOKEN_MAX + 1)).isUnbreakable  # machine output, not URL
    check ("x".repeat(TOKEN_MAX)).isUnbreakable  # longest token exemption covers
    check not ("x".repeat(60) & " " & "y".repeat(45)).isUnbreakable  # both fit once split
    check not ("  " & "x".repeat(90) & " " & "y".repeat(20)).isUnbreakable  # reflow fixes it

  test "X.1 tabs rejected in every kind":
    check messages("a.nim", "\tx\n", Kind.Nim) == @["Line holds tab."]  # no tabs
    check messages("nim.cfg", "hints:off\t# x\n", Kind.Cfg) == @["Line holds tab."]  # cfg too

  test "X.2 banner spacing":
    let good = "x = 1\n\n\n\n#[ Section ]#\n\ny = 2\n"
    check messages("a.nim", good, Kind.Nim).len == 0  # three before, one after
    check messages("a.nim", "x = 1\n\n#[ Section ]#\n\ny = 2\n", Kind.Nim) ==
      @["Banner lacks two blank lines before it."]  # one before
    check messages("a.nim", "x = 1\n\n\n#[ Section ]#\ny = 2\n", Kind.Nim) ==
      @["Banner lacks exactly one blank line after it."]  # none after
    check messages("a.nim", "x = 1\n\n\n#[ Section ]#\n\n\ny = 2\n", Kind.Nim) ==
      @["Banner lacks exactly one blank line after it."]  # two after
    check messages("nim.cfg", "#[ Section ]#\n", Kind.Cfg).len == 0  # Nim only

  test "X.2 banner tiers":
    let nested = "x = 1\n\n\n\n#[ Parent ]#\n\n\n#[[ Child ]]#\n\ny = 2\n"
    check messages("a.nim", nested, Kind.Nim).len == 0  # child follows parent at once
    check messages("a.nim", "x = 1\n\n\n#[[ Child ]]#\n\ny = 2\n", Kind.Nim).len == 0  # two before
    check messages("a.nim", "x = 1\n\n#[[ Child ]]#\n\ny = 2\n", Kind.Nim) ==
      @["Banner lacks two blank lines before it."]  # second tier checked too
    check messages("a.nim", "x = 1\n\n\n#[[ Child ]]#\n\n\ny = 2\n", Kind.Nim) ==
      @["Banner lacks exactly one blank line after it."]  # two after, no child
    check messages("a.nim", "x = 1\n\n\n\n#[ Parent ]#\n\n#[[ Child ]]#\n\ny = 2\n", Kind.Nim) ==
      @["Banner lacks two blank lines before it."]  # child keeps its own two
    check messages("a.nim", "x = 1\n\n\n#[ A ]#\n\n\n#[ B ]#\n\ny = 2\n", Kind.Nim) ==
      @["Banner lacks exactly one blank line after it."]  # only second tier defers

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
    check messages("a.nim", exact, Kind.Nim).len == 0  # lenient check accepts three before
    check checkBanners("a.nim", "x = 1\n\n\n#[ Section ]#\n\ny = 2\n").mapIt(it.message) ==
      @["First-tier banner takes three blank lines before it (X.2); got `2`."]
    check checkBanners("a.nim", "x = 1\n\n\n\n#[[ Child ]]#\n\ny = 2\n")[0].message ==
      "Second-tier banner takes two blank lines before it (X.2); got `3`."  # exactly two
    check checkBanners("a.nim", "x = 1\n\n\n\n#[ Section ]#\ny = 2\n")[0].message ==
      "Banner takes one blank line after it (X.2); got `0`."
    check checkBanners("a.nim", "#[ Opening ]#\n\nx\n").len == 0  # nothing above: no count
    check checkBanners("a.nim", "x\n\n\n\n#[ A ]#\n\n\n\n#[ B ]#\n\ny\n").len == 0  # no count

  test "X.2 exact waits outside static pass until projects clear it through koch fix":
    check messages("a.nim", "x = 1\n\n\n#[ Section ]#\n\ny = 2\n", Kind.Nim).len == 0

  test "X.9 waits outside static pass until projects clear it through koch fix":
    check messages("a.nim", "let a = 1 # One.\n", Kind.Nim).len == 0  # pull request after wires it


suite "Article VIII":
  test "VIII.5 whitespace and endings":
    check messages("a.nim", "x = 1 \n", Kind.Nim) == @["Line ends with whitespace."]  # trailing
    check messages("a.nim", "x = 1\r\n", Kind.Nim) ==
      @["Line ends with CR; got CRLF.", "Line ends with whitespace."]  # CRLF
    check messages("a.nim", "x = 1", Kind.Nim) == @["File lacks final newline."]  # ending
    check messages("a.nim", "x = 1\n\n", Kind.Nim) == @["File ends with blank line."]  # ending
    check messages("a.nim", "", Kind.Nim) == @["File is empty."]  # empty
    check checkForm("a.nim", "x\ny \n", Kind.Nim.rule)[0].line == 2  # line numbers one-based


suite "Fixes":
  test "trailing whitespace is cut, CR of CRLF ending among it, and nothing else":
    let fix = fixed("a = 1 \nb = 2\r\nc = 3\t\n  # Keep  this.\nd = \" \"\n")
    check fix.source == "a = 1\nb = 2\nc = 3\n  # Keep  this.\nd = \" \"\n"  # those three alone
    check fix.fixed.mapIt(it.line) == @[1, 2, 3]  # one report per line
    check fix.fixed[0].message == "trailing whitespace (VIII.5)"  # rule named
    check checkForm("a.nim", fix.source, Kind.Nim.rule).len == 0  # check reports none
    check fixed(fix.source).source == fix.source and fixed(fix.source).fixed.len == 0  # idempotent

  test "ending becomes exactly one newline; empty file has no one fix":
    for dirty in ["a = 1\nb = 2", "a = 1\nb = 2\n\n\n"]:  # lacking, then blank lines
      let fix = fixed(dirty)
      check fix.source == "a = 1\nb = 2\n"  # body kept
      check fix.fixed.mapIt(it.line) == @[0]  # whole file
      check checkForm("a.nim", fix.source, Kind.Nim.rule).len == 0  # check reports none
      check fixed(fix.source).fixed.len == 0  # idempotent
    check fixed("").source == "" and fixed("").fixed.len == 0  # empty stays, finding and all

  test "X.9 gap becomes two spaces, and code, string and comment text stay":
    let
      dirty = "let a = \"# x\" # One.\nlet b = 2     ## Aligned.\nlet c = 3  # Two.\n" &
        "# Whole  line.\nlet d = 4#Glued.\n"
      fix = fixed(dirty)
    check fix.source == "let a = \"# x\"  # One.\nlet b = 2  ## Aligned.\nlet c = 3  # Two.\n" &
      "# Whole  line.\nlet d = 4  #Glued.\n"  # gaps alone move
    check fix.fixed.mapIt(it.line) == @[1, 2, 5]  # one report per line
    check checkComments("a.nim", fix.source).len == 0  # check reports none
    check checkForm("a.nim", fix.source, Kind.Nim.rule).len == 0  # nor does rest of form
    check fixed(fix.source).source == fix.source  # idempotent
    check fixed("a: 1 # b\n", Kind.Yaml).source == "a: 1 # b\n"  # Nim syntax alone

  test "X.2 run beside banner takes count exact check reads, and nothing else moves":
    let
      dirty = "x = 1\n#[ Parent ]#\n#[[ Child ]]#\n\n\n\ny = 2\n\n\n\n\n#[[ Sibling ]]#\nz\n"
      fix = fixed(dirty)
    check fix.source ==
      "x = 1\n\n\n\n#[ Parent ]#\n\n\n#[[ Child ]]#\n\ny = 2\n\n\n#[[ Sibling ]]#\n\nz\n"
    check fix.fixed.mapIt(it.line) == @[2, 3, 3, 12, 12]  # banner each run stands beside
    check checkBanners("a.nim", fix.source).len == 0
    check fixed(fix.source).source == fix.source  # idempotent
    check fixed("x\n#[ A ]#\ny\n", Kind.Cfg).source == "x\n#[ A ]#\ny\n"  # Nim syntax alone

  test "fix never writes line width check reports":
    let near = "x".repeat(LINE_MAX - 4) & " # c\n"  # 100 runes; two-space gap makes 101
    check fixed(near).source == near  # left to hand
    check gapMessages(near) == @[gapMessage(1)]  # finding stays

  test "clean source passes through unchanged":
    let clean = "## Do.\n\nlet a = \"x # y\"  # Two.\n# Whole line.\n"
    check fixed(clean).source == clean and fixed(clean).fixed.len == 0  # nothing rewritten
    check fixed("# Text.\n", Kind.Markdown).fixed.len == 0  # every kind read
