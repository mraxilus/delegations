discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Replicate Article X.1, X.2 and VIII.5: form of source.

import std/[sequtils, strutils, unittest]
import ../src/[kinds, form]


func messages(path, source: string, kind: Kind): seq[string] =
  ## Read finding messages of source under kind.
  checkForm(path, source, kind.rule).mapIt(it.message)


suite "Article X":
  test "X.1 width counts runes, not bytes":
    check messages("a.nim", "é ".repeat(49) & "éé\n", Kind.Nim).len == 0  # 100 runes pass
    check messages("a.nim", "é ".repeat(49) & "ééé\n", Kind.Nim) ==
      @["Line exceeds 100 characters; got `101`."]  # 101 runes fail, breakable
    check messages("a.nim", "é".repeat(101) & "\n", Kind.Nim).len ==
      0  # one 101-rune token has no whitespace to break at
    check messages("LICENSE.md", "x".repeat(400) & "\n", Kind.Markdown).len == 0  # exempt

  test "X.1 line over limit passes only when breaking cannot fix it":
    let url = "https://fonts.googleapis.com/css2?family=" & "x".repeat(150)
    let link = "<link rel=\"stylesheet\" href=\"" & url & "\">"
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


suite "Article VIII":
  test "VIII.5 whitespace and endings":
    check messages("a.nim", "x = 1 \n", Kind.Nim) == @["Line ends with whitespace."]  # trailing
    check messages("a.nim", "x = 1\r\n", Kind.Nim) ==
      @["Line ends with CR; got CRLF.", "Line ends with whitespace."]  # CRLF
    check messages("a.nim", "x = 1", Kind.Nim) == @["File lacks final newline."]  # ending
    check messages("a.nim", "x = 1\n\n", Kind.Nim) == @["File ends with blank line."]  # ending
    check messages("a.nim", "", Kind.Nim) == @["File is empty."]  # empty
    check checkForm("a.nim", "x\ny \n", Kind.Nim.rule)[0].line == 2  # line numbers one-based
