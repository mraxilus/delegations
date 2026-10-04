## Replicate chain of `chain.nim` header: every fixer in one order until source settles, checks
##   of what fixers clear, warning naming what breaks inside each fence, and nimble files whose
##   copy lock holds.
##   Fixtures copy those of `curator/audit/tests/suites/test_fixes.nim`, which drives same chain
##     through `koch fix`; fix to one is finished only when other is checked.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, strutils, unittest]
import ../../src/knoller/[chain, fences, idioms, reports]


const
  LAYOUT =
    "## Do.\n\n" & STRICT_FUNCS & "\n\nimport std/os\nimport std/strutils\n\n\n" &
    "#[ Section ]#\n\n" &
    "proc f(a: int; b: string): int {.noSideEffect, inline.} = a+b.len\n" &
    "proc g(\n    a: int\n) = discard\n" &
    "let x = foo(\n  1,\n  2,\n)\necho x\nlet y = @[\n  1,\n  2\n]\necho h(q=1)\nexport y, x\n"
    ## Nim source breaking each layout rule `checkFormatting` holds.
  FENCED_ROWS =
    "let m = matrix(\n  #!fix off\n  1,  0,\n\n  0,  1,\n  #!fix on\n)\n" &
    "let n = matrix(1+2)\n"
    ## Nim source whose hand-shaped rows fence keeps, and whose call after fence fix reaches.
  LOCK =
    "{\n  \"items\": {},\n  \"nimbleFile\": {\n    \"filename\": \"alpha.nimble\",\n" &
    "    \"content\": []\n  }\n}\n"
    ## Atlas lock holding copy of nimble file `alpha.nimble`.



suite "Chain":
  test "every layout rule settles in one run, and second run writes nothing":
    let found = checkFormatting("a.nim", LAYOUT, Dialect.Module)
    for rule in ["(X.2)", "(X.9)", "(STYLE.md §5)", "Signature", "Call", "trailing separator",
                 "share one bracket", "alphabetised", "`=` takes"]:
      check found.anyIt(rule in it.message)  # each rule reported
    let fix = formatted("a.nim", LAYOUT, Dialect.Module)
    check fix.source == "## Do.\n\n" & STRICT_FUNCS & "\n\nimport std/[os, strutils]\n" &
      "\n\n\n#[ Section ]#\n\n" &
      "proc f(a: int, b: string): int {.inline, noSideEffect.} = a + b.len\n" &
      "proc g(a: int) = discard\n" &
      "let x = foo(1, 2)\necho x\nlet y = @[\n  1,\n  2,\n]\necho h(q = 1)\nexport x, y\n"
    check checkFormatting("a.nim", fix.source, Dialect.Module).len == 0  # all cleared
    check formatted("a.nim", fix.source, Dialect.Module).source == fix.source  # settled
    check fix.fixed.allIt(it.line in 0 .. LAYOUT.count('\n'))  # each report names line as given


  test "dialect decides idiom fixers and checks: module reads them, script does not":
    let breach = "import std/os\nimport std/strutils\nlet a = b+c\n"
    check checkFormatting("a.nims", breach, Dialect.Script).mapIt(it.message).allIt("X.9" in it)
    check checkFormatting("a.nim", breach, Dialect.Module).len == 2  # brackets too
    check formatted("a.nims", breach, Dialect.Script).source ==
      "import std/os\nimport std/strutils\nlet a = b + c\n"  # imports left to module
    check formatted("a.nim", breach, Dialect.Module).source == STRICT_FUNCS &
      "\n\nimport std/[os, strutils]\nlet a = b + c\n"  # pragma and bracket too


  test "fence keeps lines between its markers, and fix reaches every other line":
    let
      source = "## Do.\n\n" & STRICT_FUNCS & "\n\n" & FENCED_ROWS
      unfenced = source.replace("  " & FENCE_OFF & "\n", "").replace("  " & FENCE_ON & "\n", "")
    check checkFormatting("a.nim", unfenced, Dialect.Module).anyIt(it.line == 5)  # rows join
    check checkFormatting("a.nim", source, Dialect.Module).mapIt(it.line) == @[12]  # after fence
    check formatted("a.nim", source, Dialect.Module).source == source.replace("1+2", "1 + 2")


  test "fence names each rule broken inside, by count and first line, in order of `Rule`":
    let
      source = "let a = 1\n" & FENCE_OFF & "\nlet b = 1+2\nlet c = not a == b\nlet d = 3*4\n" &
        FENCE_ON & "\n"
      unfenced = source.replace(FENCE_OFF, "# Rows.").replace(FENCE_ON, "# Rows.")
      held = heldOf("a.nims", source, Dialect.Script)
    check held.len == 1 and held[0].line == 2 and held[0].rule == Rule.FenceHeld  # at marker
    check held[0].message == "Fence keeps its lines as written, and inside them " &
      "not-over-binary breaks once at line 4 and expression-spacing 2 times from line 3 " &
      "(X.1); got lines `2` to `6`."  # rule left for hand and rule fixer clears alike
    check checkFormatting("a.nims", unfenced, Dialect.Script).mapIt((it.line, it.rule)).sorted ==
      @[(3, Rule.ExpressionSpacing), (4, Rule.NotOverBinary), (5, Rule.ExpressionSpacing)]
      # same lines report same unfenced
    check formatted("a.nims", source, Dialect.Script).source == source  # fenced lines unwritten


  test "each fence gives one line: clean one breaks nothing, and open one runs to last line":
    let
      source = "let a = 1+2\n" & FENCE_OFF & "\nlet b = 1+2\n" & FENCE_ON & "\nlet c = 3\n" &
        FENCE_OFF & "\nlet d = 4\n"
      held = heldOf("a.nims", source, Dialect.Script)
    check held.mapIt(it.line) == @[2, 6]  # one for each fence
    check held[0].message.contains(" expression-spacing breaks once at line 3 (X.1)")  # 1 outside
    check held[1].message == "Fence keeps its lines as written, and nothing inside breaks a " &
      "rule (X.1); got lines `6` to `7`."
    check heldOf("a.nims", "let a = 1+2\n", Dialect.Script).len == 0  # no fence, no line


  test "fence of module counts idiom checks too, and script reads none":
    let source = FENCE_OFF & "\nlet a = 1\nlet b = 2\nproc f(): int =\n  return result\n"
    check heldOf("a.nim", source, Dialect.Module)[0].message.contains(
      "inside them return-result breaks once at line 5 and single-bindings once at line 2 (X.1)",
    )
    check heldOf("a.nims", source, Dialect.Script)[0].message.contains("nothing inside breaks")


  test "fence crossing bracket leaves source as written, and is its one finding":
    let crossing = "let a = 1+2\nlet m = f(\n  " & FENCE_OFF & "\n  1,  0,\n)\n" & FENCE_ON & "\n"
    check formatted("a.nims", crossing, Dialect.Script).source == crossing  # nothing written
    check formatted("a.nims", crossing, Dialect.Script).fixed.len == 0
    check checkFormatting("a.nims", crossing, Dialect.Script).mapIt(it.rule) == @[Rule.Fence]
    check heldOf("a.nims", crossing, Dialect.Script).len == 0  # fault, and no warning


  test "nimble file whose copy lock holds is named, beside its lock":
    let files = @[
      ("p/alpha/atlas.lock", LOCK),
      ("p/alpha/alpha.nimble", "version = \"0.1.0\"\n"),
      ("p/beta/beta.nimble", "version = \"0.1.0\"\n"),
    ]
    check lockedNimbles(files) == @["p/alpha/alpha.nimble"]  # lock names its copy
    check lockedNimbles([("atlas.lock", LOCK)]) == @["alpha.nimble"]  # lock at root
    check lockedNimbles([("p/alpha/atlas.lock", "{}\n")]).len == 0  # lock holding no copy
