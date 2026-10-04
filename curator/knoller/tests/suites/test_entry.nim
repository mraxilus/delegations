## Replicate entry block of `entry.nim` header: body moves into `proc main`, or stays with reason.

{.experimental: "strictFuncs".}

import std/unittest
import ../../src/knoller/entry


const
  ENTRY_BINDS = """
proc main(): int =
  let inside = 1
  inside

when isMainModule:
  let verb = paramStr(1)
  for path in [verb]:
    let shown = path
  try: discard
  except CatchableError as error: echo error.msg
  proc helper() =
    let helper_local = 1
else:
  let SHARED = 1
"""
    ## Entry block binding by `let`, `for` and `except … as`, and routine declared inside it.
    ##   Copy of same fixture in `curator/audit/tests/suites/test_names.nim`, which names
    ##     check reads; fix to one is finished only when other is checked.
  ENTRY_CALLS = """
when isMainModule:
  doAssert paramCount() == 1, "Usage: marks <dir>; got `" & $paramCount() & "` arguments."
  buildPages(paramStr(1))
"""
    ## Entry block of plain calls, which binds nothing.
    ##   Copy of same fixture in `curator/audit/tests/suites/test_names.nim`, which names
    ##     check reads; fix to one is finished only when other is checked.



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
