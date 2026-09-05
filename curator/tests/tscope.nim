discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Replicate scope rules of `scope.nim` header and CONTRIBUTOR.md boundaries.

import std/[sequtils, strutils, unittest]
import ../src/[domains, scope]


const OUTSIDE = @["README.md", "curator/src/audit.nim", "ronri/beta/x.nim", "bangu/other/x.nim"]
  ## Paths outside `<domain>/alpha/` for every domain.


suite "Scope":
  test "main and curator branches pass every path":
    check checkScope(MAIN, OUTSIDE).len == 0  # main is merge target
    check checkScope("curator/rules", OUTSIDE).len == 0  # curator exempt

  test "contributor branch confined to project prefix":
    for d in DOMAINS:  # 5 domains, exhaustive
      let branch = d.folder & "/alpha/work"
      let inside = @[d.folder & "/alpha/x.nim", d.folder & "/alpha/tests/t.nim"]
      check checkScope(branch, inside).len == 0  # inside prefix
      let found = checkScope(branch, inside & OUTSIDE)
      check found.mapIt(it.path) == OUTSIDE  # each outside path named
      let message = "Path outside branch scope `" & d.folder & "/alpha/`."
      check found.allIt(it.message == message)  # prefix named
    check checkScope("ronri/alpha/work", ["ronri/alpha_2/x.nim"]).len == 1  # prefix is folder

  test "branch outside grammar is one finding naming branch":
    let found = checkScope("claude/setup", ["README.md"])
    check found.len == 1 and found[0].path.len == 0  # branch-level
    check found[0].message.endsWith("got `claude/setup`.")  # IV.4 echo value
