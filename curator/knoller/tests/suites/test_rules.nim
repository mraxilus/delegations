## Replicate naming of rules in `rules.nim` header: id is slug of name, one for each rule; and
##   message of check names its rule's article nowhere, since caller cites it.
##   Case held: message citing article in its text, as `blanks.nim:237`, `declarations.nim:278`
##     and `chain.nim:292` did, read where check runs; domain is every string literal of every
##     module under `src/`, read as tokens, so message no suite drives yet is read too.

{.experimental: "strictFuncs".}

import std/[os, sequtils, strutils, unittest]
import ../../src/knoller/[blanks, chain, declarations, fences, reports, rules, tokens]


const DIRECTORY_SOURCE = currentSourcePath().parentDir.parentDir.parentDir / "src"
  ## Package sources whose every string literal names no article.


func isCiting(text: string): bool =
  ## Decide whether text cites article of charter: `§`, or `(` opening Roman numeral and `.`.
  if "§" in text: return true
  for k, c in text:
    if c != '(': continue
    var i = k + 1
    while i < text.len and text[i] in {'I', 'V', 'X'}: inc i
    if i > k + 1 and i < text.len and text[i] == '.': return true



suite "Rules":
  test "id is slug of name: lowercase words joined by hyphen":
    check Rule.SpacingExpression.id == "expression-spacing"  # space becomes hyphen
    check Rule.SubjectTarget.id == "to-target-subject-first"  # bracket run folds into one
    check Rule.StrictFuncs.id == "strictfuncs"  # case folds
    check Rule.Fence.id == "fence"  # one word stays
    check Rule.FenceHeld.id == "fence-held"


  test "every rule has id of its own, so output names one rule":
    var ids: seq[string]
    for rule in Rule: ids.add rule.id
    check ids.deduplicate.len == ids.len  # no two rules share id
    check ids.allIt(it.len > 0 and it[0] != '-' and it[^1] != '-')  # hyphen joins, never ends


  test "message citing article reads as citation, and one citing none reads as none":
    for found in [
      "Suite takes three blank lines before it (X.2); got `0`.",  # `blanks.nim:237`
      "Parameter states its type only where default does not fix it (X.12); got " &
      "`n: int = 1`.",  # `declarations.nim:278`
      "Fence keeps its lines as written, and inside them expression-spacing breaks once at " &
      "line 3 (X.1); got lines `2` to `4`.",  # `chain.nim:292`
      "Module carries `strictFuncs` before its imports (STYLE.md §2); got none.",
    ]:
      check found.isCiting  # each as found
    check not "Suite takes three blank lines before it; got `0`.".isCiting
    check not "Group `(a)` and Roman `IV` cite nothing; got `(1.5)`.".isCiting


  test "message of check names no article, since caller cites one for each rule":
    let
      suites = "import std/unittest\nsuite \"A\":\n  test \"a\":\n    check true\n"
      defaults = "proc f(n: int = 1) = discard\n"
      fenced = "let A = 1\n" & FENCE_OFF & "\nlet B = 1+2\n" & FENCE_ON & "\n"
      found =
          checkBlanks("tests/test_a.nim", suites) & checkDefaults("a.nim", defaults) &
          heldOf("a.nims", fenced, Dialect.Script)
    check found.mapIt(it.rule) == @[Rule.LinesBlankTest, Rule.DefaultLiteral, Rule.FenceHeld]
    check found.mapIt(it.message) == @[
      "Suite takes three blank lines before it; got `0`.",  # `blanks.nim:237`
      # `declarations.nim:278`
      "Parameter states its type only where default does not fix it; got `n: int = 1`.",
      "Fence keeps its lines as written, and inside them expression-spacing breaks once at " &
      "line 3; got lines `2` to `4`.",  # `chain.nim:292`
    ]
    var
      cited: seq[string]
      count = 0
    for path in walkDirRec(DIRECTORY_SOURCE):
      if not path.endsWith(".nim"): continue
      let source = readFile(path)
      for t in source.tokens:
        if t.kind != KindToken.Text: continue
        inc count
        if t.spelling(source).isCiting: cited.add path.extractFilename & ":" & $(t.line + 1)
    check cited == newSeq[string]()  # every string literal of every module
    check count > 0  # walk read literals, so check above is not vacuous
