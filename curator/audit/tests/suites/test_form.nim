## Replicate Article X.1, X.2, X.9 and VIII.5: form of source as static pass reads it, in each
##   kind; fixers of form are held in `curator/knoller/tests/suites/test_form.nim`.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/[findings, form, kinds]


func messages(path, source: string; kind: Kind): seq[string] =
  ## Read finding messages of source under kind.
  checkForm(path, source, kind.rule).mapIt(it.message)



suite "Article X":
  test "X.1 width reads as koch prints it, in runes, and `LICENSE.md` is exempt":
    check messages("a.nim", "é ".repeat(49) & "éé\n", Kind.Nim).len == 0  # 100 runes pass
    check messages("a.nim", "é ".repeat(49) & "ééé\n", Kind.Nim) ==
      @["Line exceeds 100 characters (X.1); got `101`."]  # 101 runes fail, breakable
    check messages("a.nim", "é".repeat(101) & "\n", Kind.Nim).len ==
      0  # one 101-rune token has no whitespace to break at
    check messages("LICENSE.md", "x".repeat(400) & "\n", Kind.Markdown).len == 0  # exempt
    check messages("README.md", "x ".repeat(60) & "y\n", Kind.Markdown).len == 1  # path alone


  test "X.1 line over limit passes only when breaking cannot fix it, in every kind":
    let
      url = "https://fonts.googleapis.com/css2?family=" & "x".repeat(150)
      link = "<link rel=\"stylesheet\" href=\"" & url & "\">"
    check messages("pages/x.html", link & "\n", Kind.Html).len == 0  # URL has no whitespace
    check messages("pages/x.html", "<p>" & "word ".repeat(40) & "</p>\n", Kind.Html) ==
      @["Line exceeds 100 characters (X.1); got `207`."]  # prose always breaks
    check messages("pages/x.svg", "<svg>" & "<circle/>".repeat(200) & "</svg>\n", Kind.Svg) ==
      @["Line exceeds 100 characters (X.1); got `1811`."]  # minified markup runs past TOKEN_MAX


  test "X.1 tabs rejected in every kind":
    check messages("a.nim", "\tx\n", Kind.Nim) == @["Line holds tab (X.1)."]  # no tabs
    check messages("nim.cfg", "hints:off\t# x\n", Kind.Configuration) ==
      @["Line holds tab (X.1)."]  # cfg too


  test "X.2 static pass reads banners exactly, as fixer writes them, in every kind of Nim":
    # Case held: lenient banner check of `form.nim` stood beside exact one of knoller, so static
    #   pass took two blank lines before first tier, where X.2 asks three (#557); domain is each
    #   count exact check reads, in each kind of Nim syntax, and kind of other syntax reads none.
    for (path, kind) in [
      ("a.nim", Kind.Nim), ("a.nims", Kind.NimScript), ("a.nimble", Kind.Nimble)
    ]:
      check messages(path, "x = 1\n\n\n#[ Section ]#\n\ny = 2\n", kind) ==
        @["First-tier banner takes three blank lines before it (X.2); got `2`."]
      check messages(path, "x = 1\n\n\n\n#[[ Child ]]#\n\ny = 2\n", kind) ==
        @["Second-tier banner takes two blank lines before it (X.2); got `3`."]
      check messages(path, "x = 1\n\n\n\n#[ Section ]#\ny = 2\n", kind) ==
        @["Banner takes one blank line after it (X.2); got `0`."]
      check messages(path, "x = 1\n\n\n\n#[ Parent ]#\n\n\n#[[ Child ]]#\n\ny = 2\n", kind).len == 0
    check messages("nim.cfg", "x\n\n#[ Section ]#\ny\n", Kind.Configuration).len == 0


  test "X.2 banner spacing reads as koch prints it":
    let good = "x = 1\n\n\n\n#[ Section ]#\n\ny = 2\n"
    check messages("a.nim", good, Kind.Nim).len == 0  # three before, one after
    check messages("a.nim", "x = 1\n\n#[ Section ]#\n\ny = 2\n", Kind.Nim) ==
      @["First-tier banner takes three blank lines before it (X.2); got `1`."]  # one before
    check messages("a.nim", "x = 1\n\n\n\n#[ Section ]#\ny = 2\n", Kind.Nim) ==
      @["Banner takes one blank line after it (X.2); got `0`."]  # none after
    check messages("a.nim", "x = 1\n\n\n\n#[ Section ]#\n\n\ny = 2\n", Kind.Nim) ==
      @["Banner takes one blank line after it (X.2); got `2`."]  # two after
    check messages("nim.cfg", "#[ Section ]#\n", Kind.Configuration).len == 0  # Nim only


  test "X.2 banner tiers":
    let nested = "x = 1\n\n\n\n#[ Parent ]#\n\n\n#[[ Child ]]#\n\ny = 2\n"
    check messages("a.nim", nested, Kind.Nim).len == 0  # child follows parent at once
    check messages("a.nim", "x = 1\n\n\n#[[ Child ]]#\n\ny = 2\n", Kind.Nim).len == 0  # two before
    check messages("a.nim", "x = 1\n\n#[[ Child ]]#\n\ny = 2\n", Kind.Nim) ==
      @["Second-tier banner takes two blank lines before it (X.2); got `1`."]  # tier read
    check messages("a.nim", "x = 1\n\n\n#[[ Child ]]#\n\n\ny = 2\n", Kind.Nim) ==
      @["Banner takes one blank line after it (X.2); got `2`."]  # two after, no child
    check messages("a.nim", "x = 1\n\n\n\n#[ Parent ]#\n\n#[[ Child ]]#\n\ny = 2\n", Kind.Nim) ==
      @["Second-tier banner takes two blank lines before it (X.2); got `1`."]  # child keeps two
    check messages("a.nim", "x = 1\n\n\n\n#[ A ]#\n\n\n#[ B ]#\n\ny = 2\n", Kind.Nim).len == 0


  test "X.2 side that X.2 gives no count goes unread":
    for unread in [
      "#[ Opening ]#\n\nx = 1\n",  # nothing above
      "x = 1\n\n\n\n#[ Closing ]#\n",  # nothing below
      "x = 1\n\n\n\n#[ A ]#\n#[ B ]#\n\ny = 2\n",  # banner beside banner, no parent and child
      "x = 1\n\n\n#[[ A ]]#\n\n#[ B ]#\n\ny = 2\n",
    ]:
      check messages("a.nim", unread, Kind.Nim).len == 0


  test "X.2 static pass accepts each count fixer writes":
    let exact = "x = 1\n\n\n\n#[ Parent ]#\n\n\n#[[ Child ]]#\n\ny = 2\n\n\n#[[ Sibling ]]#\n\nz\n"
    check messages("a.nim", exact, Kind.Nim).len == 0  # three before first tier, two before second


  test "X.9 waits outside static pass until projects clear it through koch fix":
    check messages("a.nim", "let a = 1 # One.\n", Kind.Nim).len == 0  # pull request after wires it



suite "Article VIII":
  test "VIII.5 whitespace and endings read as koch prints them":
    check messages("a.nim", "x = 1 \n", Kind.Nim) ==
      @["Line ends with whitespace (VIII.5)."]  # trailing
    check messages("a.nim", "x = 1\r\n", Kind.Nim) ==
      @["Line ends with CR (VIII.5); got CRLF.", "Line ends with whitespace (VIII.5)."]  # CRLF
    check messages("a.nim", "x = 1", Kind.Nim) == @["File lacks final newline (VIII.5)."]
    check messages("a.yml", "x: 1\n\n", Kind.Yaml) == @["File ends with blank line (VIII.5)."]
    check messages("a.md", "", Kind.Markdown) == @["File is empty (VIII.5)."]  # every kind
    check checkForm("a.nim", "x\ny \n", Kind.Nim.rule)[0].line == 2  # line numbers one-based
