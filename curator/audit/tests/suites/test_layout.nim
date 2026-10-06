## Replicate layout rules of `layout.nim` header, CURATOR.md and CONTRIBUTOR.md.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../../knoller/src/knoller
import ../../src/[domains, layout]
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
    check goodTree().projectDirectories ==
      @[ALPHA_DIRECTORY, AUDIT_DIRECTORY]  # sorted project directories


  test "root holds only listed entries":
    check (goodTree() & @[entry("NOTES.md", "x\n")]).paths == @["NOTES.md"]  # root file
    check (goodTree() & @[entry("COORDINATOR.md", "# Coordinator\n")]).paths.len == 0  # prompt
    check (goodTree() & @[entry("tools/x.nim", "x\n")]).paths == @["tools/x.nim"]  # root directory


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
    check tree.projectDirectories ==
      @[ALPHA_DIRECTORY, AUDIT_DIRECTORY]  # silent skip would hide project


  test "unregistered kind is finding naming registry, under curator too":
    let found = (goodTree() & @[entry("curator/audit/data.csv", "")]).checkLayout
    check found.len == 1 and "curator/audit/src/kinds.nim" in found[0].message  # VI.5
    check found[0].message.endsWith("got `data.csv`.")  # IV.4 echo value


  test "Shell lives only where hooks live":
    check (goodTree() & @[entry(".claude/hooks.sh", "#!/bin/sh\n")]).checkLayout.len == 0  # glue
    check (goodTree() & @[entry(".githooks/pre-push", "#!/bin/sh\n")]).checkLayout.len == 0  # git
    let script = ALPHA_DIRECTORY & "/tools/run.sh"
    check (goodTree() & @[entry(script, "#!/bin/sh\n")]).messages ==
      @["Shell is hook glue of curator, and lives only in `.claude/` or `.githooks/` " &
        "(CONTRIBUTOR.md, The language is Nim); got `" & script & "`."]  # project script


  test "build output and vendored source stay untracked at any depth":
    for directory in ["build", "dependencies", "node_modules"]:
      let
        path = "contributor/ronri/alpha/" & directory & "/x.nim"
        found = (goodTree() & @[entry(path, "")]).checkLayout
      check found.anyIt("Article XI.3" in it.message and it.path == path)
    let module = (goodTree() & @[entry("curator/audit/src/dependencies.nim", "")]).checkLayout
    check not module.anyIt("XI.3" in it.message)  # file named so is no directory


  test "project folder names follow grammar under both roots":
    for directory in ["contributor/ronri/Beta", "curator/Beta"]:  # both roots
      let found = (goodTree() & projectEntries(directory, "x")).checkLayout
      check found.len == 5 and found.allIt("`Beta`" in it.message)  # every file flagged


  test "project shape is complete under both roots":
    for directory in [ALPHA_DIRECTORY, AUDIT_DIRECTORY]:  # both roots, exhaustive
      for file in PROJECT_FILES:  # 3 files
        let path = directory & "/" & file
        check goodTree().without(path).paths == @[path]  # each missing file is one finding
      check goodTree().without(directory & "/tests/tall.nim").paths ==
        @[directory & "/tests"]  # tests
      let nimble = directory & "/" & directory.projectName & EXTENSIONS[Dialect.Package]
      check goodTree().without(nimble).paths == @[nimble]  # nimble file required


  test "project may nest source directories to any depth":
    let deep = goodTree() & @[
      entry(ALPHA_DIRECTORY & "/app/app.nim", "## Drive app.\n\ndiscard\n"),
      entry(ALPHA_DIRECTORY & "/design/rules.nim", "## Hold rules.\n\ndiscard\n"),
      entry(ALPHA_DIRECTORY & "/src/alpha/draw/body.nim", "## Draw body.\n\ndiscard\n"),
      entry(ALPHA_DIRECTORY & "/tools/build.nim", "## Build pages.\n\ndiscard\n"),
    ]
    check deep.checkLayout.len == 0  # depth inside project is project's own business
    check deep.projectDirectories == @[ALPHA_DIRECTORY, AUDIT_DIRECTORY]  # nesting adds no project


  test "nimble file is named after project and packages demand lock":
    let other = ALPHA_DIRECTORY & "/other.nimble"
    check (goodTree() & @[entry(other, TEXT_NIMBLE)]).messages ==
      @["Nimble file not named after project; expected `" & ALPHA_DIRECTORY & "/alpha.nimble`."]
    let
      nimble = ALPHA_DIRECTORY & "/alpha.nimble"
      requiring = goodTree().replaced(nimble, TEXT_NIMBLE & "requires \"malebolgia\"\n")
    check requiring.paths == @[ALPHA_DIRECTORY & "/atlas.lock"]  # lock demanded
    check requiring.messages[0].endsWith("got `malebolgia`.")  # package named
    check (requiring & @[entry(ALPHA_DIRECTORY & "/atlas.lock", "{}\n")]).checkLayout.len == 0  # ok


  test "top-level glossary is required":
    check goodTree().without("GLOSSARY.md").paths == @["GLOSSARY.md"]  # required at root
    check goodTree().without("GLOSSARY.md").messages == @["Top-level glossary missing."]  # named


  test "committed pages live in page directories only":
    for page_directory in PAGE_DIRECTORIES:  # 2 directories, exhaustive
      let inside = goodTree() & @[
        entry(
          ALPHA_DIRECTORY & "/" & page_directory & "/index.html",
          "<!doctype html>\n<p>x</p>\n",
        ),
        entry(AUDIT_DIRECTORY & "/" & page_directory & "/deep/frame.svg", "<svg></svg>\n"),
      ]
      check inside.checkLayout.len == 0  # page in its place, at any depth
    let stray = goodTree() & @[entry(ALPHA_DIRECTORY & "/design/stray.html", "<p>x</p>\n")]
    check stray.checkLayout.len == 1  # page elsewhere inside project
    check "`pages/` or `mockups/`" in stray.checkLayout[0].message  # names both
    let orphan = goodTree() & @[entry(CONTRIBUTOR & "/ronri/README.html", "<p>x</p>\n")]
    check orphan.checkLayout.anyIt("Page outside" in it.message)  # page outside any project


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
