discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Replicate layout rules of `layout.nim` header, CURATOR.md and CONTRIBUTOR.md.

import std/[sequtils, strutils, unittest]
import ../src/[domains, layout]
import ./fixtures


func paths(tree: Tree): seq[string] =
  ## Read finding paths of tree.
  tree.checkLayout.mapIt(it.path)


suite "Layout":
  test "good tree passes and lists projects":
    check goodTree().checkLayout.len == 0  # fixture is smallest passing tree
    check goodTree().projectDirs == @["curator", "ronri/alpha"]  # sorted project dirs

  test "root holds only listed entries":
    check (goodTree() & @[entry("NOTES.md", "x\n")]).paths == @["NOTES.md"]  # root file
    check (goodTree() & @[entry("tools/x.nim", "x\n")]).paths == @["tools/x.nim"]  # root dir
    check (goodTree() & @[entry("ronri/stray.nim", "x\n")]).paths == @["ronri/stray.nim"]  # domain

  test "unregistered kind is finding naming registry":
    let found = (goodTree() & @[entry("ronri/alpha/data.csv", "")]).checkLayout
    check found.len == 1 and "kinds.nim" in found[0].message  # VI.5 points at registry
    check found[0].message.endsWith("got `data.csv`.")  # IV.4 echo value

  test "project folder names follow grammar":
    let found = (goodTree() & projectEntries("ronri/Beta", "x")).checkLayout
    check found.len == 5 and found.allIt("`Beta`" in it.message)  # every file flagged

  test "project shape is complete":
    for file in PROJECT_FILES:  # 4 files, exhaustive
      let path = "ronri/alpha/" & file
      check goodTree().without(path).paths == @[path]  # each missing file is one finding
    check goodTree().without("ronri/alpha/tests/tall.nim").paths == @["ronri/alpha/tests"]  # tests
    check goodTree().replaced("ronri/alpha/Makefile", "all:\n\ttrue\n").paths ==
      @["ronri/alpha/Makefile"]  # `check` target

  test "target forms":
    check "check:\n".hasTarget("check") and "check :\n".hasTarget("check")  # both spellings
    check "check: deps\n".hasTarget("check")  # dependencies after colon
    check ".PHONY: check\n\ncheck:\n".hasTarget("check")  # phony line is not target
    check not "checks:\n".hasTarget("check") and not ".PHONY: check\n".hasTarget("check")  # near

  test "root Makefile declares every documented target":
    for target in ROOT_TARGETS:  # 7 targets, exhaustive
      let stripped = ROOT_MAKEFILE_TEXT.replace(target & ":\n\ttrue\n", "")
      let found = goodTree().replaced("Makefile", stripped).checkLayout
      let message = "Root Makefile lacks target; got `" & target & "`."
      check found.len == 1 and found[0].message == message  # missing target named
    let superset = goodTree().replaced("ronri/alpha/Makefile", ROOT_MAKEFILE_TEXT)
    check superset.checkLayout.len == 0  # project may declare more than check

  test "README files are derived views of DOMAINS":
    let stripped = readmeText().replace("| ronri | ronri | Computing. |\n", "")
    check goodTree().replaced("README.md", stripped).paths == @["README.md"]  # row missing
    for d in DOMAINS:  # 5 domains, exhaustive
      let path = d.folder & "/README.md"
      check goodTree().without(path).paths == @[path]  # README missing
      check goodTree().replaced(path, "# Other\n\n" & d.theme & "\n").paths == @[path]  # heading
      check goodTree().replaced(path, "# " & d.name & "\n\nOther.\n").paths == @[path]  # theme
