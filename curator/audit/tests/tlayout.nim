discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Replicate layout rules of `layout.nim` header, CURATOR.md and CONTRIBUTOR.md.

import std/[sequtils, strutils, unittest]
import ../src/[domains, layout, dependencies]
import ./fixtures


func paths(tree: Tree): seq[string] =
  ## Read finding paths of tree.
  tree.checkLayout.mapIt(it.path)


func messages(tree: Tree): seq[string] =
  ## Read finding messages of tree.
  tree.checkLayout.mapIt(it.message)


suite "Layout":
  test "good tree passes and lists projects under both roots":
    check goodTree().checkLayout.len == 0  # fixture is smallest passing tree
    check goodTree().projectDirs == @[ALPHA_DIR, AUDIT_DIR]  # sorted project dirs

  test "root holds only listed entries":
    check (goodTree() & @[entry("NOTES.md", "x\n")]).paths == @["NOTES.md"]  # root file
    check (goodTree() & @[entry("tools/x.nim", "x\n")]).paths == @["tools/x.nim"]  # root dir

  test "root folders and domain folders hold README.md and folders only":
    check (goodTree() & @[entry("curator/stray.nim", "x\n")]).messages ==
      @["Curator root holds README.md and project folders only; got `stray.nim`."]  # curator
    check (goodTree() & @[entry("contributor/stray.nim", "x\n")]).messages ==
      @["Contributor root holds README.md and domain folders only; got `stray.nim`."]  # root
    check (goodTree() & @[entry("contributor/ronri/stray.nim", "x\n")]).messages ==
      @["Domain folder holds README.md and project folders only; got `stray.nim`."]  # domain

  test "unregistered domain is reported and never becomes project":
    let tree = goodTree() & @[entry("contributor/nowhere/alpha/README.md", "# x\n")]
    check tree.messages == @["Domain folder outside registry; got `nowhere`."]  # named
    check tree.projectDirs == @[ALPHA_DIR, AUDIT_DIR]  # silent skip would hide project

  test "unregistered kind is finding naming registry, under curator too":
    let found = (goodTree() & @[entry("curator/audit/data.csv", "")]).checkLayout
    check found.len == 1 and "curator/audit/src/kinds.nim" in found[0].message  # VI.5
    check found[0].message.endsWith("got `data.csv`.")  # IV.4 echo value

  test "project folder names follow grammar under both roots":
    for dir in ["contributor/ronri/Beta", "curator/Beta"]:  # both roots
      let found = (goodTree() & projectEntries(dir, "x")).checkLayout
      check found.len == 5 and found.allIt("`Beta`" in it.message)  # every file flagged

  test "project shape is complete under both roots":
    for dir in [ALPHA_DIR, AUDIT_DIR]:  # both roots, exhaustive
      for file in PROJECT_FILES:  # 3 files
        let path = dir & "/" & file
        check goodTree().without(path).paths == @[path]  # each missing file is one finding
      check goodTree().without(dir & "/tests/tall.nim").paths == @[dir & "/tests"]  # tests
      let nimble = dir & "/" & dir.projectName & NIMBLE_EXT
      check goodTree().without(nimble).paths == @[nimble]  # nimble file required

  test "nimble file is named after project and packages demand lock":
    let other = ALPHA_DIR & "/other.nimble"
    check (goodTree() & @[entry(other, NIMBLE_TEXT)]).messages ==
      @["Nimble file not named after project; expected `" & ALPHA_DIR & "/alpha.nimble`."]  # one
    let nimble = ALPHA_DIR & "/alpha.nimble"
    let requiring = goodTree().replaced(nimble, NIMBLE_TEXT & "requires \"malebolgia\"\n")
    check requiring.paths == @[ALPHA_DIR & "/atlas.lock"]  # lock demanded
    check requiring.messages[0].endsWith("got `malebolgia`.")  # package named
    check (requiring & @[entry(ALPHA_DIR & "/atlas.lock", "{}\n")]).checkLayout.len == 0  # ok

  test "README files are derived views":
    let stripped = readmeText().replace("| ronri | ronri | Computing. |\n", "")
    check goodTree().replaced("README.md", stripped).paths == @["README.md"]  # row missing
    for root in ROOTS:  # 2 roots, exhaustive
      let path = root & "/README.md"
      check goodTree().without(path).paths == @[path]  # README missing
      check goodTree().replaced(path, "# Other\n").paths == @[path]  # heading
    for d in DOMAINS:  # 5 domains, exhaustive
      let path = CONTRIBUTOR & "/" & d.folder & "/README.md"
      check goodTree().without(path).paths == @[path]  # README missing
      check goodTree().replaced(path, "# Other\n\n" & d.theme & "\n").paths == @[path]  # heading
      check goodTree().replaced(path, "# " & d.name & "\n\nOther.\n").paths == @[path]  # theme
