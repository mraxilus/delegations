## Replicate chain of `chain.nim` header: every fixer in one order until source settles, checks
##   of what fixers clear, and nimble files whose copy lock holds.
##   Fixtures copy those of `curator/audit/tests/suites/test_fixes.nim`, which drives same chain
##     through `koch fix`; fix to one is finished only when other is checked.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
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


  test "fence crossing bracket leaves source as written, and is its one finding":
    let crossing = "let a = 1+2\nlet m = f(\n  " & FENCE_OFF & "\n  1,  0,\n)\n" & FENCE_ON & "\n"
    check formatted("a.nims", crossing, Dialect.Script).source == crossing  # nothing written
    check formatted("a.nims", crossing, Dialect.Script).fixed.len == 0
    check checkFormatting("a.nims", crossing, Dialect.Script).mapIt(it.rule) == @[Rule.Fence]


  test "nimble file whose copy lock holds is named, beside its lock":
    let files = @[
      ("p/alpha/atlas.lock", LOCK),
      ("p/alpha/alpha.nimble", "version = \"0.1.0\"\n"),
      ("p/beta/beta.nimble", "version = \"0.1.0\"\n"),
    ]
    check lockedNimbles(files) == @["p/alpha/alpha.nimble"]  # lock names its copy
    check lockedNimbles([("atlas.lock", LOCK)]) == @["alpha.nimble"]  # lock at root
    check lockedNimbles([("p/alpha/atlas.lock", "{}\n")]).len == 0  # lock holding no copy
