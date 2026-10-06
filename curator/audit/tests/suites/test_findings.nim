## Replicate finding record of `findings.nim` header: its order, how it renders, and how
##   report of knoller renders as finding, article where sentence of its message ends.
##   Every check reports through these, so they are held here, not only through checks.
##   Messages of knoller's checks name no article, so each text koch prints with article is held
##     here, through real check, rather than in suites of knoller.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, strutils, unittest]
import ../../../knoller/src/knoller
import ../../src/findings



suite "Findings":
  test "render locates finding, dropping parts that locate nothing":
    check finding("a/b.nim", 3, "Broke.").render == "a/b.nim:3: Broke."
    check finding("a/b.nim", 0, "Broke.").render == "a/b.nim: Broke."  # whole file
    check finding("", 0, "Broke.").render == "Broke."  # branch-level, no file to open


  test "finding is no propagation unless check says so":
    check not finding("a/b.nim", 3, "Broke.").is_propagation  # default: whoever owns path
    check finding("a/b.nim", 3, "Broke.", is_propagation = true).is_propagation


  test "order is path, then line, then message, so reports are stable":
    let scattered = @[
      finding("b.nim", 1, "Second file."),
      finding("a.nim", 9, "Later line."),
      finding("a.nim", 2, "Zebra."),
      finding("a.nim", 2, "Apple."),
    ]
    let ordered = scattered.sorted
    check ordered[0] == finding("a.nim", 2, "Apple.")  # message breaks line tie
    check ordered[1] == finding("a.nim", 2, "Zebra.")
    check ordered[2] == finding("a.nim", 9, "Later line.")  # line breaks path tie
    check ordered[3] == finding("b.nim", 1, "Second file.")
    # Same input in another order sorts same way, which is what stable output means.
    check scattered.reversed.sorted == ordered


  test "whole-file finding sorts before first line of same file":
    # `0` marks whole file and is never line one, so it leads its own file's findings.
    let found = @[finding("a.nim", 1, "Line."), finding("a.nim", 0, "File.")].sorted
    check found[0].line == 0


  test "rewrite of knoller renders as its rule and article, as koch fix prints it":
    check initReport("a.nim", 3, Rule.ExpressionSpacing).findingOf ==
      finding("a.nim", 3, "expression spacing (X.9)")
    let rendered = [
      (Rule.TrailingWhitespace, "trailing whitespace (VIII.5)"),
      (Rule.TabInString, "tab in string (X.1)"),
      (Rule.ArticleInComment, "article in comment (VI.5)"),
      (Rule.TargetSubject, "to<Target> subject first (STYLE.md §5)"),
      (Rule.ReturnResult, "return result (STYLE.md §5)"),
      (Rule.ImportRank, "import rank (X.5)"),
      (Rule.ImportBrackets, "import brackets (X.5)"),
      (Rule.ModuleBracket, "module bracket (STYLE.md §5)"),
      (Rule.SingleBindings, "single bindings (X.5)"),
      (Rule.ProfilerImport, "profiler import (STYLE.md §3)"),
      (Rule.DocPosition, "doc position (STYLE.md §5)"),
      (Rule.LiteralDefault, "literal default (X.12)"),
      (Rule.SignatureWrapping, "signature wrapping (X.3)"),
    ]
    for (rule, message) in rendered:
      check initReport("a.nim", 1, rule).findingOf.message == message  # bytes koch printed


  test "finding of knoller's check cites article where sentence ends, never propagation":
    let
      found = initReport("a.nim", 2, Rule.TrailingComment, "Comment gap; got `1`.")
      bare = initReport("a.nim", 0, Rule.FileEnding, "File ends in one newline.")
      quoting = initReport("a.nim", 1, Rule.MessageValue, "Ends as ``a; got `b`.``; got `c`.")
      sentence = "File still changes after 3 rounds of fixers, so fix leaves it as written"
      unsettled = initReport("a.nim", 0, Rule.Unsettled, sentence & "; got `3` rounds.")
    check found.findingOf == finding("a.nim", 2, "Comment gap (X.9); got `1`.")
    check not found.findingOf.is_propagation  # whoever owns path fixes it
    check bare.findingOf.message == "File ends in one newline (VIII.5)."  # sentence echoes none
    check quoting.findingOf.message == "Ends as ``a; got `b`.`` (IV.4); got `c`."  # span quotes
    # Sentence `chain.nim` gives source that never settles; suite knows no such source.
    check unsettled.findingOf.message == sentence & " (STYLE.md §5); got `3` rounds."
    let reports = @[found, initReport("b.nim", 0, Rule.FileEnding)]
    check reports.findingsOf.mapIt(it.path) == @["a.nim", "b.nim"]  # order kept


  test "value quoting `; got ` inside code span leaves article where sentence ends":
    let quoted = initReport("a.nim", 2, Rule.TrailingComment, "Sentence; got `a; got b`.")
    check quoted.findingOf.message == "Sentence (X.9); got `a; got b`."  # first mark outside span


  test "sentence ending in code span right before `; got ` takes article after span":
    check checkNegations("a.nim", "let b = not a == 3\n").findingsOf.mapIt(it.message) == @[
      "`not` over binary expression takes parentheses, since Nim reads `not a == b` as " &
      "`(not a) == b` (X.4); got `not a == 3`.",
    ]  # real message of `not-over-binary`, through its check


  test "finding of knoller's check reads as koch prints it, article where sentence ends":
    let
      fenced = "let A = 1\n" & FENCE_OFF & "\nlet B = 1+2\n" & FENCE_ON & "\n"
      crossing = "let m = f(\n  " & FENCE_OFF & "\n  1,\n)\n" & FENCE_ON & "\n"
      late = "import std/os\n" & STRICT_FUNCS & "\n"
      stub = "discard \"\"\"\naction: run\ncmd: \"nim c -r $file\"\njoinable: false\n\"\"\"\n"
      found =
          heldOf("a.nims", fenced, Dialect.Script) & faultOf("a.nim", crossing.fenceOf) &
          checkStrictFuncs("a.nim", @["import std/os"], @["import std/os"]) &
          checkStrictFuncs("a.nim", late.splitLines, late.codeOnly.splitLines) &
          checkImports("a.nim", @["import std/[strutils, os]", "import ./a", "import std/math"]) &
          checkBindings("a.nim", @["proc f() =", "  let a = 1", "  let b = 2"]) &
          checkReturns("a.nim", @["proc f(): int =", "  return result"]) &
          checkStubKeys("tests/test_a.nim", stub)
    check found.findingsOf.mapIt(it.message) == @[
      "Fence keeps its lines as written, and inside them expression-spacing breaks once at " &
      "line 3 (X.1); got lines `2` to `4`.",  # fence warning
      "Fence closes outside bracket, string or comment it opens in, so fix leaves file as " &
      "written (X.1); got `#!fix off` and `#!fix on` either side.",
      "Module carries `" & STRICT_FUNCS & "` before its imports (STYLE.md §2); got none.",
      "Module carries `" & STRICT_FUNCS & "` before its imports (STYLE.md §2); got it after.",
      "Bracket import is alphabetised (X.5); got `strutils, os`.",
      "Standard library comes first, then packages, then local modules (X.5); got `std/math`.",
      "Consecutive single bindings share one keyword (X.5); got `let` twice.",
      "Bare `return` exits early with `result`, and routine ends on value itself (STYLE.md " &
      "§5); got `return result`.",
      "Stub `cmd` leaves out `-r`, since testament runs binary itself (STYLE.md §6); got `-r`.",
      "Stub leaves out keys `testament pattern` never reads (STYLE.md §6); got `joinable`.",
    ]  # text koch prints: static pass, and `koch fix` for fence


  test "finding of knoller's check no pass of koch runs yet reads as koch would print it":
    let
      tail = "let m = \"Over \" & $LIMIT & \" bytes; got \" & $count & \".\"\n"
      found =
          checkBanners("a.nim", "x = 1\n\n\n#[ Section ]#\n\ny = 2\n") &
          checkBanners("a.nim", "x = 1\n\n\n\n#[[ Child ]]#\n\ny = 2\n") &
          checkBanners("a.nim", "x = 1\n\n\n\n#[ Section ]#\ny = 2\n") &
          checkComments("a.nim", "let a = 1 # One.\n") & checkMessages("a.nim", tail) &
          checkSpacing("a.nim", "let r = 0 .. n\n")
    check found.findingsOf.mapIt(it.message) == @[
      "First-tier banner takes three blank lines before it (X.2); got `2`.",
      "Second-tier banner takes two blank lines before it (X.2); got `3`.",
      "Banner takes one blank line after it (X.2); got `0`.",
      "Trailing comment takes two spaces before its marker (X.9); got `1`.",
      "Message ends echoing value in backticks, as ``…; got `{value}`.`` (IV.4); got `$count`.",
      "Range operator takes no space (X.9); got `0 .. n`.",
    ]  # text koch would print, once static pass runs these checks


  test "finding of rule whose checks state two articles cites rule's one, as its rewrite does":
    let
      sum = "  let depth = offset_x * bounds.forward.x + offset_y * bounds.forward.y + " &
          "offset_z * bounds.forward.z\n"
      found =
          checkSignatures("a.nim", "proc g(\n    a: int\n) = discard\n") &
          checkCalls("a.nim", "let x = foo(\n  1,\n  2\n)\n") & checkCalls("a.nim", sum) &
          checkImportBrackets("a.nim", "import std/[math]\n")
    check found.findingsOf.mapIt(it.message) == @[
      "Signature stays on one line where it fits, else wraps its parameters onto one line of " &
      "their own, else one group to line (X.3); got `3` lines.",
      "Call stays on its line where it fits, else takes one argument to line with trailing " &
      "comma (X.3); got `4` lines.",
      "Line fitting nowhere breaks after its operator of lowest precedence (STYLE.md §5); got " &
      "`101` runes.",
      "Bracket of one module drops its bracket (STYLE.md §5); got `std/[math]`.",
    ]
    for (rule, article) in [
      (Rule.SignatureWrapping, "X.3"),
      (Rule.CallWrapping, "X.3"),
      (Rule.OperatorWrapping, "STYLE.md §5"),
      (Rule.ImportBrackets, "X.5"),
      (Rule.ModuleBracket, "STYLE.md §5"),
    ]:
      check CITATIONS[rule] == article  # one article, which rewrite cites too


  test "every rule of knoller cites article":
    for rule in Rule: check CITATIONS[rule].len > 0  # array indexed by rule: none left out
