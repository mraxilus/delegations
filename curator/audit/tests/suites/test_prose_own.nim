## Replicate list of `prose_own.nim` header: projects whose prose stays in their own language, and
##   check holding each entry to tree (VI.5, VI.8).

{.experimental: "strictFuncs".}

import std/[os, sequtils, strutils, unittest]
import ../../src/[domains, prose_own]
import ./fixtures


const SUITE = "tests/suites/test_prose_own.nim"  ## Suite entry names, relative to its project.



suite "Article VI":
  test "VI.5, VI.8 path inside listed project keeps its own prose, at any depth, and no other":
    for path in [
      DIRECTORY_PARSER & "/README.md",
      DIRECTORY_PARSER & "/src/lojban_parser/prose.nim",
      DIRECTORY_PARSER & "/" & SUITE,
    ]:
      check path.isProseOwn  # record, source and suite alike
    for path in [
      DIRECTORY_TAGGER & "/README.md",
      DIRECTORY_PARSER & "_extra/README.md",
      CONTRIBUTOR & "/bangu/README.md",
      DIRECTORY_PARSER,
      "README.md",
    ]:
      check not path.isProseOwn  # other project, longer name, domain index, bare folder, root


  test "VI.5, VI.8 entry whose project tree lacks is finding at list, naming its directory":
    let
      listed = ProjectProseOwn(
        directory: DIRECTORY_PARSER,
        issue: 818,
        suite: SUITE,
        should_demand_suite: false,
      )
      found = entriesProject(DIRECTORY_ALPHA, "x").checkProjectsProseOwn([listed])
    check entriesProject(DIRECTORY_PARSER, "x").checkProjectsProseOwn([listed]).len == 0  # held
    check found.mapIt((it.path, it.line)) == @[(PATH_PROSE_OWN, 0)]  # entry is what to change
    check found[0].message.endsWith("got `" & DIRECTORY_PARSER & "`.")  # IV.4 echo value


  test "VI.5, VI.8 suite entry demands is finding where tree lacks it, at that suite":
    let
      demanding = ProjectProseOwn(
        directory: DIRECTORY_PARSER,
        issue: 818,
        suite: SUITE,
        should_demand_suite: true,
      )
      tree = entriesProject(DIRECTORY_PARSER, "x")
      found = tree.checkProjectsProseOwn([demanding])
    check found.mapIt(it.path) == @[DIRECTORY_PARSER & "/" & SUITE]  # inside project (duty 3)
    check found[0].message.endsWith("got `" & DIRECTORY_PARSER & "/" & SUITE & "`.")
    let written = tree.with(entry(DIRECTORY_PARSER & "/" & SUITE, "## Hold prose.\n"))
    check written.checkProjectsProseOwn([demanding]).len == 0  # suite present
    let elsewhere = tree.with(entry(DIRECTORY_AUDIT & "/" & SUITE, "## Hold prose.\n"))
    check elsewhere.checkProjectsProseOwn([demanding]).len == 1  # same name elsewhere holds none
    var waiting = demanding
    waiting.should_demand_suite = false
    check tree.checkProjectsProseOwn([waiting]).len == 0  # suite not demanded yet


  test "VI.5, VI.8 path finding at list names is path of this module":
    # Finding on entry whose project tree lacks names `PATH_PROSE_OWN`; moved module would leave it
    #   naming file that does not exist, and each test above would still pass.
    let root = currentSourcePath().parentDir.parentDir.parentDir.parentDir.parentDir
    check fileExists(root / PATH_PROSE_OWN)  # constant leads to this module


  test "VI.5, VI.8 entry demands its suite once its project holds it":
    # Entry that demands no suite gives no finding where tree lacks its suite, so suite could go
    #   unseen; demand follows suite once tree holds it.
    let root = currentSourcePath().parentDir.parentDir.parentDir.parentDir.parentDir
    var held = 0  # Entries whose project holds its suite, so loop checks at least one.
    for p in PROJECTS_PROSE_OWN:
      if fileExists(root / p.directory / p.suite):
        inc held
        check p.should_demand_suite  # suite present, so audit demands it
    check held >= 1  # floor: suite of ricyso'o stands in tree
