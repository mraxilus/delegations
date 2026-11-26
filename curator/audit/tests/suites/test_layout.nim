## Replicate layout rules of `layout.nim` header, CURATOR.md and CONTRIBUTOR.md.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../../knoller/src/knoller
import ../../src/[domains, findings, layout]
import ./fixtures


func paths(tree: Tree): seq[string] =
  ## Read finding paths of tree.
  tree.checkLayout.mapIt(it.path)


func messages(tree: Tree): seq[string] =
  ## Read finding messages of tree.
  tree.checkLayout.mapIt(it.brief)



suite "Layout":
  test "good tree passes and lists projects under both roots":
    check treeGood().checkLayout.len == 0  # fixture is smallest passing tree
    check treeGood().directoriesProject ==
      @[DIRECTORY_PARSER, DIRECTORY_ALPHA, DIRECTORY_AUDIT]  # sorted project directories


  test "root holds only listed entries":
    check (treeGood() & @[entry("NOTES.md", "x\n")]).paths == @["NOTES.md"]  # root file
    check (treeGood() & @[entry("COORDINATOR.md", "# Coordinator\n")]).paths.len == 0  # prompt
    check (treeGood() & @[entry("tools/x.nim", "x\n")]).paths == @["tools/x.nim"]  # root directory


  test "root folders and domain folders hold README.md and folders only":
    check (treeGood() & @[entry("curator/stray.nim", "x\n")]).messages ==
      @["curator root holds README.md and project folders only; got `stray.nim`"]  # curator
    check (treeGood() & @[entry("contributor/stray.nim", "x\n")]).messages ==
      @["contributor root holds README.md and domain folders only; got `stray.nim`"]  # root
    check (treeGood() & @[entry("contributor/ronri/stray.nim", "x\n")]).messages ==
      @["domain folder holds README.md and project folders only; got `stray.nim`"]  # domain


  test "unregistered domain is reported and never becomes project":
    let tree = treeGood() & @[entry("contributor/nowhere/alpha/README.md", "# x\n")]
    check tree.messages == @["domain folder outside registry; got `nowhere`"]  # named
    check tree.directoriesProject ==
      @[DIRECTORY_PARSER, DIRECTORY_ALPHA, DIRECTORY_AUDIT]  # silent skip would hide project


  test "unregistered kind is finding naming registry, under curator too":
    let found = (treeGood() & @[entry("curator/audit/data.csv", "")]).checkLayout
    check found.len == 1 and "curator/audit/src/kinds.nim" in found[0].brief  # VI.5
    check found[0].brief.endsWith("got `data.csv`")  # IV.4 echo value


  test "Shell lives only where hooks live":
    check (treeGood() & @[entry(".claude/hooks.sh", "#!/bin/sh\n")]).checkLayout.len == 0  # glue
    check (treeGood() & @[entry(".githooks/pre-push", "#!/bin/sh\n")]).checkLayout.len == 0  # git
    let script = DIRECTORY_ALPHA & "/tools/run.sh"
    check (treeGood() & @[entry(script, "#!/bin/sh\n")]).messages ==
      @["shell is hook glue of curator, and lives only in `.claude/` or `.githooks/` " &
        "(CONTRIBUTOR.md, The language is Nim); got `" & script & "`"]  # project script


  test "build output and vendored source stay untracked at any depth":
    for directory in ["build", "dependencies", "node_modules"]:
      let
        path = "contributor/ronri/alpha/" & directory & "/x.nim"
        found = (treeGood() & @[entry(path, "")]).checkLayout
      check found.anyIt("Article XI.3" in it.brief and it.path == path)
    let module = (treeGood() & @[entry("curator/audit/src/dependencies.nim", "")]).checkLayout
    check not module.anyIt("XI.3" in it.brief)  # file named so is no directory


  test "project folder names follow grammar under both roots":
    for directory in ["contributor/ronri/Beta", "curator/Beta"]:  # both roots
      let found = (treeGood() & entriesProject(directory, "x")).checkLayout
      check found.len == 5 and found.allIt("`Beta`" in it.brief)  # every file flagged


  test "project shape is complete under both roots":
    for directory in [DIRECTORY_ALPHA, DIRECTORY_AUDIT]:  # both roots, exhaustive
      for file in FILES_PROJECT:  # 3 files
        let path = directory & "/" & file
        check treeGood().without(path).paths == @[path]  # each missing file is one finding
      check treeGood().without(directory & "/tests/tall.nim").paths ==
        @[directory & "/tests"]  # tests
      let nimble = directory & "/" & directory.nameProject & EXTENSIONS[Dialect.Package]
      check treeGood().without(nimble).paths == @[nimble]  # nimble file required


  test "project may nest source directories to any depth":
    let deep = treeGood() & @[
      entry(DIRECTORY_ALPHA & "/app/app.nim", "## Drive app.\n\ndiscard\n"),
      entry(DIRECTORY_ALPHA & "/design/rules.nim", "## Hold rules.\n\ndiscard\n"),
      entry(DIRECTORY_ALPHA & "/src/alpha/draw/body.nim", "## Draw body.\n\ndiscard\n"),
      entry(DIRECTORY_ALPHA & "/tools/build.nim", "## Build pages.\n\ndiscard\n"),
    ]
    check deep.checkLayout.len == 0  # depth inside project is project's own business
    check deep.directoriesProject ==
      @[DIRECTORY_PARSER, DIRECTORY_ALPHA, DIRECTORY_AUDIT]  # nesting adds no project


  test "nimble file is named after project and packages demand lock":
    let other = DIRECTORY_ALPHA & "/other.nimble"
    check (treeGood() & @[entry(other, TEXT_NIMBLE)]).messages ==
      @["nimble file not named after project; expected `" & DIRECTORY_ALPHA & "/alpha.nimble`"]
    let
      nimble = DIRECTORY_ALPHA & "/alpha.nimble"
      requiring = treeGood().replaced(nimble, TEXT_NIMBLE & "requires \"malebolgia\"\n")
    check requiring.paths == @[DIRECTORY_ALPHA & "/atlas.lock"]  # lock demanded
    check requiring.messages[0].endsWith("got `malebolgia`")  # package named
    check (requiring & @[entry(DIRECTORY_ALPHA & "/atlas.lock", "{}\n")]).checkLayout.len == 0  # ok


  test "nimble file of path is that of project holding it, and path at root takes none":
    # Knoller reads tests, stubs and umbrella below folder of this file, and its name names
    #   umbrella (#886). Domain: source, suite and umbrella of project under each root, and root.
    for (path, nimble) in [
      (DIRECTORY_ALPHA & "/src/alpha.nim", DIRECTORY_ALPHA & "/alpha.nimble"),  # umbrella
      (DIRECTORY_ALPHA & "/tests/suites/test_a.nim", DIRECTORY_ALPHA & "/alpha.nimble"),
      (DIRECTORY_AUDIT & "/src/audit/a.nim", DIRECTORY_AUDIT & "/audit.nimble"),
      ("koch.nim", ""),  # root lies in no project
      ("curator/README.md", ""),
    ]:
      check path.nimbleProject == nimble


  test "top-level glossary is required":
    check treeGood().without("GLOSSARY.md").paths == @["GLOSSARY.md"]  # required at root
    check treeGood().without("GLOSSARY.md").messages == @["top-level glossary missing"]  # named


  test "entry file stands at root, and CLAUDE.md imports it on line of its own, outside code":
    # Claude Code loads no import in code, and repository writes each path in backticks, so
    #   import in code span would load nothing, and no suite runs on change to `CLAUDE.md` alone.
    #   Domain: import missing, of other file, in code span, in fence, indented as code, and entry
    #   file missing, beside `CLAUDE.md` or without it.
    const
      absent = "`CLAUDE.md` imports entry file on line `@AGENTS.md` of its own, outside code, " &
        "as Claude Code loads no import in code; got `none`"
      lacking = [
        "# Claude Code\n\nRead rules.\n",  # none
        "# Claude Code\n\n@README.md\n",  # other file
        "# Claude Code\n\n`@AGENTS.md`\n",  # code span
        "# Claude Code\n\n```md\n@AGENTS.md\n```\n",  # fence
        "# Claude Code\n\n    @AGENTS.md\n",  # indented, so code
      ]
    for text in lacking:
      check treeGood().replaced("CLAUDE.md", text).messages == @[absent]
    check treeGood().replaced("CLAUDE.md", "# Claude Code\n\n@AGENTS.md\n").checkLayout.len == 0
    check treeGood().without("CLAUDE.md").checkLayout.len == 0  # Claude Code reads entry itself
    check treeGood().without("AGENTS.md").messages == @["entry file missing"]
    check treeGood().without("CLAUDE.md").without("AGENTS.md").messages ==
      @["entry file missing"]  # each harness reads it, Claude Code too


  test "committed pages live in page directories only":
    for directory_page in DIRECTORIES_PAGE:  # 2 directories, exhaustive
      let inside = treeGood() & @[
        entry(
          DIRECTORY_ALPHA & "/" & directory_page & "/index.html",
          "<!doctype html>\n<p>x</p>\n",
        ),
        entry(DIRECTORY_AUDIT & "/" & directory_page & "/deep/frame.svg", "<svg></svg>\n"),
      ]
      check inside.checkLayout.len == 0  # page in its place, at any depth
    let stray = treeGood() & @[entry(DIRECTORY_ALPHA & "/design/stray.html", "<p>x</p>\n")]
    check stray.checkLayout.len == 1  # page elsewhere inside project
    check "`pages/` or `mockups/`" in stray.checkLayout[0].brief  # names both
    let orphan = treeGood() & @[entry(CONTRIBUTOR & "/ronri/README.html", "<p>x</p>\n")]
    check orphan.checkLayout.anyIt("page outside" in it.brief)  # page outside any project


  test "README files are derived views":
    let stripped = textReadme().replace("| ronri | ronri | Computing. |\n", "")
    check treeGood().replaced("README.md", stripped).paths == @["README.md"]  # row missing
    for root in ROOTS:  # 2 roots, exhaustive
      let path = root & "/README.md"
      check treeGood().without(path).paths == @[path]  # README missing
      check treeGood().replaced(path, "# Other\n").paths == @[path]  # heading
    for d in DOMAINS:  # 5 domains, exhaustive
      let path = CONTRIBUTOR & "/" & d.folder & "/README.md"
      check treeGood().without(path).paths == @[path]  # README missing
      check treeGood().replaced(path, "# Other\n\n" & d.theme & "\n").paths == @[path]  # heading
      check treeGood().replaced(path, "# " & d.name & "\n\nOther.\n").paths == @[path]  # theme
