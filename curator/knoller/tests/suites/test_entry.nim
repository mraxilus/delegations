## Replicate entry block of `entry.nim` header: binding there reported, and body moved into
##   `proc main`, or left with reason.

{.experimental: "strictFuncs".}

import std/[sequtils, unittest]
import ../../src/knoller/[entry, names, reports]
import ./sources



suite "Entry block":
  test "V.10 entry block stays where routine would read it otherwise, and refusal says why":
    let refused = [
      ("when isMainModule:\n  var count {.global.} = 0\n",
        "`{.global.}` binds at module level alone"),
      ("when isMainModule:\n  let code = run()\n  quit code\n",
        "`quit` at block's own indent returns value, which `quit main()` would carry"),
      (ENTRY_BINDS, "`main` stands in module already"),
      ("when isMainModule and defined(js):\n  let a = 1\n",
        "`when isMainModule and defined(js):` guards more than `isMainModule`"),
      ("when isMainModule:\n  import std/os\n  let a = paramStr(1)\n",
        "`import` stands at module level alone"),
      ("when isMainModule:\n  when defined(posix):\n    import std/posix\n  let a = 1\n",
        "`import` stands at module level alone"),  # at any depth of block
      ("when isMainModule:\n  proc shown*() = discard\n  let a = 1\n",
        "export marker of `shown` stands at module level alone"),
      ("when isMainModule:\n  let a = 1\nwhen isMainModule:\n  echo 2\n",
        "module holds `2` entry blocks"),
    ]
    for (source, refusal) in refused:
      check source.blockEntry.refusal == refusal  # V.10
      check fixBlockEntry("a.nim", source).source == source  # V.10, block stays
    check ENTRY_CALLS.blockEntry.refusal.len == 0  # V.10, block binding nothing moves nothing
    check fixBlockEntry("a.nim", ENTRY_CALLS).source == ENTRY_CALLS  # V.10


  test "V.10 entry block holds no binding, each one finding, and block of calls passes":
    let found = checkBlockEntry("a.nim", ENTRY_BINDS)
    check found.mapIt((it.line, it.rule)) == @[
      (6, Rule.BlockEntry), (7, Rule.BlockEntry), (8, Rule.BlockEntry), (10, Rule.BlockEntry),
    ]  # `let`, `for`, `let` under it, `except … as`; routine inside block is local
    for (name, report) in zip(["verb", "path", "shown", "error"], found):
      check report.message ==
        "Entry block holds no binding; move code that binds into `proc main`; got `" & name &
          "`."  # V.10, name echoed
    check checkBlockEntry("a.nim", ENTRY_CALLS).len == 0  # V.10, calls bind nothing
    check checkBlockEntry("a.nim", "when isMainModule:\n  quit main()\n").len == 0  # V.10
    let refused = "when isMainModule:\n  var count {.global.} = 0\n"
    check checkBlockEntry("a.nim", refused).len == 1  # block fix leaves still reports
    check checkBlockEntry("a.nim", fixBlockEntry("a.nim", "when isMainModule:\n  let a = 1\n")
      .source).len == 0  # block fix moves reports none


  test "V.10 entry block moves into documented `proc main`, and block calls it":
    const
      entry = "import std/os\n\n\nwhen isMainModule:\n  let verb = paramStr(1)\n" &
        "  for path in [verb]:\n    echo path\n# After block.\n"
      moved = "import std/os\n\n\nproc main() =\n  ## TODO: Document.\n  let verb = paramStr(1)\n" &
        "  for path in [verb]:\n    echo path\n\n\nwhen isMainModule:\n  main()\n# After block.\n"
    let fix = fixBlockEntry("a.nim", entry)
    check fix.source == moved  # V.10
    check fix.fixed.mapIt(it.line) == @[5, 6]  # V.10, each binding check names
    check fix.origin == @[1, 2, 3, 0, 0, 5, 6, 7, 0, 0, 4, 0, 8, 9]  # report traces to source
    check checkBlockEntry("a.nim", entry).len == 2  # V.10, each binding
    check checkBlockEntry("a.nim", moved).len == 0 and checkNames("a.nim", moved, []).len == 0
    check fixBlockEntry("a.nim", moved).source == moved  # V.10, second fix changes nothing
    const branched = "when isMainModule:  # Run.\n  let a = 1\n  echo a\nelse:\n  discard\n"
    check fixBlockEntry("a.nim", branched).source == "proc main() =\n  ## TODO: Document.\n" &
      "  let a = 1\n  echo a\n\n\nwhen isMainModule:  # Run.\n  main()\nelse:\n  discard\n"
    const nested = "when isMainModule:\n  let code = run()\n  if code != 0: quit code\n"
    check nested.blockEntry.refusal.len == 0  # V.10, `quit` inside branch moves
