## Replicate finding record of `findings.nim` header: its order, how it renders, and how
##   report of knoller renders as finding.
##   Every check reports through these, so they are held here, not only through checks.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, unittest]
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
      (Rule.SingleBindings, "single bindings (X.5)"),
      (Rule.ProfilerImport, "profiler import (STYLE.md §3)"),
      (Rule.DocPosition, "doc position (STYLE.md §5)"),
      (Rule.LiteralDefault, "literal default (X.12)"),
      (Rule.SignatureWrapping, "signature wrapping (X.3)"),
    ]
    for (rule, message) in rendered:
      check initReport("a.nim", 1, rule).findingOf.message == message  # bytes koch printed


  test "finding of knoller's check renders its message as written, never propagation":
    let found = initReport("a.nim", 2, Rule.TrailingComment, "Comment gap; got `1`.")
    check found.findingOf == finding("a.nim", 2, "Comment gap; got `1`.")
    check not found.findingOf.is_propagation  # whoever owns path fixes it
    let reports = @[found, initReport("b.nim", 0, Rule.FileEnding)]
    check reports.findingsOf.mapIt(it.path) == @["a.nim", "b.nim"]  # order kept


  test "every rule of knoller cites article":
    for rule in Rule: check CITATIONS[rule].len > 0  # array indexed by rule: none left out
