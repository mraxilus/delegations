discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Replicate scope rules of `scope.nim` header and CONTRIBUTOR.md boundaries.

import std/[sequtils, strutils, unittest]
import ../src/[domains, scope]


const OUTSIDE = @[
  "README.md", "curator/audit/src/audit.nim", "curator/probe/README.md",
  "contributor/ronri/beta/x.nim", "contributor/bangu/other/x.nim",
]
  ## Paths outside `contributor/<domain>/alpha/` for every domain.


suite "Scope":
  test "main and curator root branches pass every path":
    check checkScope(MAIN, OUTSIDE).len == 0  # main is merge target
    check checkScope("curator/rules", OUTSIDE).len == 0  # empty prefix

  test "contributor branch confined to project prefix":
    for d in DOMAINS:  # 5 domains, exhaustive
      let prefix = "contributor/" & d.folder & "/alpha/"
      let inside = @[prefix & "x.nim", prefix & "tests/t.nim"]
      check checkScope("contributor/" & d.folder & "/alpha/work", inside).len == 0  # inside
      let found = checkScope("contributor/" & d.folder & "/alpha/work", inside & OUTSIDE)
      check found.mapIt(it.path) == OUTSIDE  # each outside path named
      check found.allIt(it.message == "Path outside branch scope `" & prefix & "`.")  # prefix
    check checkScope("contributor/ronri/alpha/work", ["contributor/ronri/alpha_2/x.nim"]).len ==
      1  # prefix is whole folder

  test "curator project branch confined to its folder":
    let paths = [
      "curator/audit/src/x.nim", "README.md", "curator/probe/README.md",
      "contributor/ronri/alpha/x.nim", "curator/audit_2/x.nim",
    ]
    let found = checkScope("curator/audit/work", paths)
    check found.mapIt(it.path) == paths[1 .. ^1].toSeq  # everything but its own folder
    check found.allIt(it.message == "Path outside branch scope `curator/audit/`.")  # prefix

  test "branch outside grammar is one finding naming branch":
    for branch in ["claude/setup", "ronri/alpha/work"]:  # harness name, old form
      let found = checkScope(branch, ["README.md"])
      check found.len == 1 and found[0].path.len == 0  # branch-level
      check found[0].message.endsWith("got `" & branch & "`.")  # IV.4 echo value
