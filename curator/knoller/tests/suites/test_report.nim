## Replicate two forms of finding of `report.nim` header (STYLE.md §3): terminal form, line form,
##   their color, and pick of form by terminal and flag.
##   Case held: both findings of example of #1002, drawn by hand from ruled design (2026-11-22),
##     each text as that example prints it.

{.experimental: "strictFuncs".}

import std/[options, strutils, unittest]
import ../../src/knoller/[report, reports, rules]


const  # TODO: Document.
  NAME_CUT = Notice(
    path: "pga/algebra.nim", line: 186, column: 11, span: 10, rule: "name-cut",
    summary: "name puts `anti` after the word it qualifies", actual: some("antiscalar"),
    expected: some("scalar_anti"),
    help: "rename it by hand, since `scalar_anti` would hide `scalarAnti` of line 313",
    source: some("      let antiscalar = ("),
  )
    ## Finding of knoller in library of Architect, first of example of #1002.
  WIDTH_SUBJECT = Notice(
    rule: "koch.commit-subject-width", summary: "commit subject exceeds 100 characters",
    actual: some("106"), expected: some("at most 100"),
    help: "move the detail of the subject into the body of the commit",
  )
    ## Finding of koch with no file or line, second of example of #1002.


func bare(text: string): string =
  ## Strip each escape of color from text.
  var i = 0
  while i < text.len:
    if text[i] == '\e':
      while i < text.len and text[i] != 'm': inc i
      inc i
    else:
      result.add text[i]
      inc i



suite "Report":
  test "terminal form prints each part finding holds, as example of #1002 draws it":
    check NAME_CUT.render(Form.Terminal) == [
      "pga/algebra.nim:186:11  name-cut",
      "",
      "  name puts `anti` after the word it qualifies",
      "",
      "   186 │       let antiscalar = (",
      "       │           ──────────",
      "",
      "  actual  antiscalar",
      "  expect  scalar_anti",
      "",
      "  help: rename it by hand, since `scalar_anti` would hide `scalarAnti` of line 313",
    ].join("\n")
    check WIDTH_SUBJECT.render(Form.Terminal) == [
      "koch.commit-subject-width",
      "",
      "  commit subject exceeds 100 characters",
      "",
      "  actual  106",
      "  expect  at most 100",
      "",
      "  help: move the detail of the subject into the body of the commit",
    ].join("\n")  # no location, so no source line (ruling `D3 a` of #1002)


  test "line form prints finding on one line, each value quoted, help last (ruling 7197275206)":
    check NAME_CUT.render(Form.Line) == "pga/algebra.nim:186:11: name-cut: actual=\"antiscalar\" " &
      "expect=\"scalar_anti\" message=\"name puts `anti` after the word it qualifies\" " &
      "help=\"rename it by hand, since `scalar_anti` would hide `scalarAnti` of line 313\""
    check WIDTH_SUBJECT.render(Form.Line) == "koch.commit-subject-width: actual=\"106\" " &
      "expect=\"at most 100\" message=\"commit subject exceeds 100 characters\" " &
      "help=\"move the detail of the subject into the body of the commit\""
    check "help=" notin Notice(rule: "r", summary: "s").render(Form.Line)  # none held, none printed
    check Notice(rule: "r", summary: "s", help: "say \"hi\"").render(Form.Line) ==
      "r: message=\"s\" help=\"say \\\"hi\\\"\""  # help quoted as each value is


  test "location holds only parts finding holds, each behind part before it (D3 of #1002)":
    check Notice(rule: "tab", summary: "line holds tab").render(Form.Line) ==
      "tab: message=\"line holds tab\""
    check Notice(path: "a.nim", rule: "tab", summary: "line holds tab").render(Form.Line) ==
      "a.nim: tab: message=\"line holds tab\""
    check Notice(path: "a.nim", line: 3, rule: "tab", summary: "s").render(Form.Line) ==
      "a.nim:3: tab: message=\"s\""
    check Notice(path: "a.nim", line: 3, column: 2, rule: "tab", summary: "s").render(Form.Line) ==
      "a.nim:3:2: tab: message=\"s\""
    check Notice(path: "a.nim", line: 3, rule: "tab", summary: "s").render(Form.Terminal) ==
      "a.nim:3  tab\n\n  s"  # no text of line read, so no source line


  test "terminal form shows source line where it holds line and text, and marker where column":
    let at = Notice(path: "a.nim", line: 7, rule: "tab", summary: "s", source: some("x = 1"))
    check at.render(Form.Terminal) == "a.nim:7  tab\n\n  s\n\n     7 │ x = 1"  # no marker
    let past = Notice(
      path: "a.nim", line: 7, column: 6, rule: "trailing-whitespace", summary: "s",
      source: some("x = 1"),
    )
    check past.render(Form.Terminal).splitLines[^1] == "       │      ─"  # one rune at least
    let wide = Notice(
      path: "a.nim", line: 12345, column: 1, rule: "r", summary: "s", source: some("x")
    )
    check wide.render(Form.Terminal).splitLines[^2 .. ^1] == @["  12345 │ x", "        │ ─"]


  test "source line past window shows window around marker, each cut edge marked `…`":
    let
      text = "x".repeat(100) & "y" & "z".repeat(50)
      past = Notice(
        path: "a.nim", line: 1, column: 101, span: 1, rule: "line-width", summary: "s",
        source: some(text),
      )
    check past.render(Form.Terminal).splitLines[^2 .. ^1] == @[
      "     1 │ …" & "x".repeat(29) & "y" & "z".repeat(50),
      "       │ " & ' '.repeat(30) & "─",
    ]  # 80 runes reach end of line, so window starts 29 runes before span, and right stays whole
    let start = Notice(
      path: "a.nim", line: 1, column: 1, rule: "r", summary: "s", source: some("w".repeat(90))
    )
    check start.render(Form.Terminal).splitLines[^2] == "     1 │ " & "w".repeat(80) & "…"
    let whole = Notice(
      path: "a.nim", line: 1, rule: "r", summary: "s", source: some("v".repeat(90))
    )
    check whole.render(Form.Terminal).splitLines[^1] == "     1 │ " & "v".repeat(80) & "…"
    let middle = Notice(
      path: "a.nim", line: 1, column: 101, span: 3, rule: "r", summary: "s",
      source: some("a".repeat(100) & "bcd" & "e".repeat(100)),
    )
    check middle.render(Form.Terminal).splitLines[^2 .. ^1] == @[
      "     1 │ …" & "a".repeat(20) & "bcd" & "e".repeat(57) & "…",
      "       │ " & ' '.repeat(21) & "───",
    ]  # 20 runes before span where line runs on past window


  test "column and span count runes, as width counts them":
    let glyphs = Notice(
      path: "a.nim", line: 2, column: 5, span: 2, rule: "r", summary: "s",
      source: some("let 𝐞∞ = 1"),
    )
    check glyphs.render(Form.Terminal).splitLines[^1] == "       │     ──"


  test "control character of source line prints as its picture, so marker stays under its rune":
    let tabbed = Notice(
      path: "a.nim", line: 1, column: 1, span: 1, rule: "tab", summary: "line holds tab",
      source: some("\tx = 1\r"),
    )
    check tabbed.render(Form.Terminal).splitLines[^2 .. ^1] == @["     1 │ ␉x = 1␍", "       │ ─"]


  test "terminal form quotes value that blank or control character would hide, so empty shows":
    check Notice(rule: "r", summary: "s", actual: some(""), expected: some(" x")).render(
      Form.Terminal
    ) == "r\n\n  s\n\n  actual  \"\"\n  expect  \" x\""  # each value stays visible (IV.4)
    let tabbed = Notice(rule: "r", summary: "s", actual: some("a\tb"))
    check tabbed.render(Form.Terminal).splitLines[^1] == "  actual  \"a\\tb\""


  test "line form escapes quote, backslash and control character, and keeps other text as written":
    check "say \"hi\"\\".quoted == "\"say \\\"hi\\\"\\\\\""
    check "a\nb\r\tc".quoted == "\"a\\nb\\r\\tc\""
    check "\x01\x7F".quoted == "\"\\x01\\x7F\""
    check "𝐞∞ é".quoted == "\"𝐞∞ é\""
    for c in '\0' .. '\x7F':
      let line = Notice(path: "a.nim", rule: "r", summary: $c, actual: some($c)).render(Form.Line)
      check '\n' notin line and '\r' notin line  # one line, whatever value holds


  test "terminal form colors each part where asked, and color adds escapes alone":
    let colored = NAME_CUT.render(Form.Terminal, is_colored = true)
    check "\e[36mpga/algebra.nim:186:11\e[0m  \e[2mname-cut\e[0m" in colored  # cyan, then dim
    check "  \e[1mname puts" in colored  # summary bold
    check "\e[1;31m──────────\e[0m" in colored  # marker bold red
    check "\e[31mantiscalar\e[0m = (" in colored  # span of source line red
    check "\e[1;31mactual\e[0m  \e[31mantiscalar\e[0m" in colored
    check "\e[1;32mexpect\e[0m  \e[32mscalar_anti\e[0m" in colored
    check "\e[1;36mhelp\e[0m: rename" in colored
    check colored.bare == NAME_CUT.render(Form.Terminal)
    check NAME_CUT.render(Form.Line, is_colored = true) == NAME_CUT.render(Form.Line)  # never


  test "warning prints in both forms, marked after its rule (ruling `D2 a` of #1002)":
    let held = Notice(
      path: "a.nim", line: 2, rule: "fence-held", summary: "fence keeps its lines as written",
      is_warning: true,
    )
    check held.render(Form.Terminal) ==
      "a.nim:2  fence-held warning\n\n  fence keeps its lines as written"
    check held.render(Form.Line) ==
      "a.nim:2: fence-held warning: message=\"fence keeps its lines as written\""
    let colored = held.render(Form.Terminal, is_colored = true)
    check "\e[2mfence-held\e[0m \e[1;33mwarning\e[0m" in colored  # dim rule, bold yellow mark
    check "warning" notin NAME_CUT.render(Form.Terminal)  # finding left for hand takes no mark


  test "findings print in order given: blank line between two in terminal form, none in line form":
    let pair = [Notice(rule: "a", summary: "one"), Notice(rule: "b", summary: "two")]
    check pair.render(Form.Terminal) == "a\n\n  one\n\nb\n\n  two"
    check pair.render(Form.Line) == "a: message=\"one\"\nb: message=\"two\""


  test "terminal picks form where no flag forces one, and `NO_COLOR` set to any text drops color":
    check formOutput(is_terminal = true) == Form.Terminal
    check formOutput(is_terminal = false) == Form.Line
    check formOutput(is_terminal = true, forced = some(Form.Line)) == Form.Line
    check formOutput(is_terminal = false, forced = some(Form.Terminal)) == Form.Terminal
    check isColored(is_terminal = true, no_color = "")
    check not isColored(is_terminal = true, no_color = "1")
    check not isColored(is_terminal = true, no_color = "0")  # any text, as no-color.org reads it
    check not isColored(is_terminal = false, no_color = "")


  test "short text holds each part finding holds, as test of each check compares it (`D3 c`)":
    check NAME_CUT.brief == "name puts `anti` after the word it qualifies; got `antiscalar`; " &
      "expect `scalar_anti`; help: rename it by hand, since `scalar_anti` would hide " &
      "`scalarAnti` of line 313"
    check Notice(rule: "r", summary: "s").brief == "s"  # no value, no help
    check Notice(rule: "r", summary: "s", actual: some("")).brief == "s; got ``"  # empty shows
    check Notice(rule: "r", summary: "s", actual: some("it below `x`")).brief ==
      "s; got it below `x`"  # value holding code span of its own prints bare


  test "report reads as notice: sentence lowercase as summary, value after `; got ` as actual":
    let width = initReport(
      "a.nim", 3, Rule.LineWidth, "Line exceeds 100 characters; got `101`.",
      expected = some("at most 100"),
    )
    check width.toNotice == Notice(
      path: "a.nim", line: 3, rule: "line-width", summary: "line exceeds 100 characters",
      actual: some("101"), expected: some("at most 100"),
    )
    check width.brief == "line exceeds 100 characters; got `101`; expect `at most 100`"
    check initReport("a.nim", 0, Rule.FileEnding, "File is empty.").brief == "file is empty"
    check initReport("a.nim", 1, Rule.LineEnding, "Line ends with CR; got CRLF.").toNotice.actual ==
      some("CRLF")  # value echoed bare stays as written
    check initReport("a.nim", 1, Rule.Tab, "Line holds tab; got ``.").toNotice.actual == some("")
    check initReport("a.nim", 1, Rule.Tab, "CRLF ends line.").toNotice.summary ==
      "CRLF ends line"  # word in capitals keeps its case
    let quoting = initReport(
      "a.nim", 2, Rule.ValueMessage, "Message reads ``…; got `{v}`.``; got `x`."
    )
    check quoting.toNotice.summary == "message reads ``…; got `{v}`.``"  # quote holds its `; got `
    check quoting.toNotice.actual == some("x")
    check initReport("a.nim", 4, Rule.FenceHeld, "Fence holds.").toNotice(is_warning = true).
      render(Form.Line) == "a.nim:4: fence-held warning: message=\"fence holds\""


  test "message of check of another tool reads as notice, under id its caller gives":
    # Domain: check whose rule no `Rule` names, as each check of koch (D4 of #1002).
    let words = initNotice(
      "a.md", 3, "koch.sentence-words",
      "Sentence holds at most 25 words (ASD-STE100); got `One two`.", help = "split it",
    )
    check words == Notice(
      path: "a.md", line: 3, rule: "koch.sentence-words",
      summary: "sentence holds at most 25 words (ASD-STE100)", actual: some("One two"),
      help: "split it",
    )  # article stays in summary, as koch cites it (D1 of #1002)
    check initNotice("", 0, "koch.x", "Branch holds no commit.").brief == "branch holds no commit"
    let tab = initReport("a.nim", 2, Rule.Tab, "Line holds tab; got `x`.", column = 5, span = 1)
    check tab.toNotice(some("a\tb"), is_warning = true) == initNotice(
      "a.nim", 2, "tab", "Line holds tab; got `x`.", column = 5, span = 1, source = some("a\tb"),
      is_warning = true,
    )  # report reads as its message does, under id of its rule
