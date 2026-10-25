## Replicate scoped test selection of `plan.nim` header and CURATOR.md checks reference.

{.experimental: "strictFuncs".}

import std/[json, os, sequtils, unittest]
import ../../src/[domains, plan, projects, toolchain]
import ./fixtures


const
  DIRECTORIES = [DIRECTORY_ALPHA, DIRECTORY_AUDIT]
    ## Project directories fixture tree holds, in sorted order selection returns them:
    ## `contributor` sorts before `curator`.
  DIRECTORY_IMPORTING = CURATOR & "/assayer"  ## Curator project importing knoller, besides driver.
  DIRECTORY_PROBE = CURATOR & "/probe"  ## Curator project importing no knoller.



suite "Plan":
  test "code change selects its project alone":
    check projectsTest(DIRECTORIES, [DIRECTORY_ALPHA & "/src/alpha.nim"]) ==
      @[DIRECTORY_ALPHA]  # source
    check projectsTest(DIRECTORIES, [DIRECTORY_ALPHA & "/tests/tall.nim"]) ==
      @[DIRECTORY_ALPHA]  # test
    check projectsTest(DIRECTORIES, [DIRECTORY_ALPHA & "/alpha.nimble"]) ==
      @[DIRECTORY_ALPHA]  # requirements
    check projectsTest(DIRECTORIES, [DIRECTORY_ALPHA & "/pages/index.html"]) ==
      @[DIRECTORY_ALPHA]  # page


  test "record change alone selects nothing, so rules propagation compiles nothing":
    check projectsTest(DIRECTORIES, [DIRECTORY_ALPHA & "/PROVENANCE.md"]).len == 0  # stamp only
    check projectsTest(DIRECTORIES, [DIRECTORY_ALPHA & "/GLOSSARY.md"]).len == 0  # terms only
    # README runs nothing.
    check projectsTest(DIRECTORIES, [DIRECTORY_ALPHA & "/README.md"]).len == 0
    # Nested README is code: only project's own three records describe project.
    check projectsTest(DIRECTORIES, [DIRECTORY_ALPHA & "/design/README.md"]) == @[DIRECTORY_ALPHA]
    for directory in DIRECTORIES:
      let records = [directory & "/PROVENANCE.md", directory & "/GLOSSARY.md"]
      check projectsTest(DIRECTORIES, records).len == 0
    # Record beside code still selects, since code changed.
    let mixed = [DIRECTORY_ALPHA & "/PROVENANCE.md", DIRECTORY_ALPHA & "/src/a.nim"]
    check projectsTest(DIRECTORIES, mixed) == @[DIRECTORY_ALPHA]


  test "project gains type check by carrying node manifest and its lock":
    # Nothing lists which project is type-checked: `check.yml` names no project, exactly as
    #   it names none for compiler matrix, so derivation is only place truth lives.
    check treeGood().directoriesNode(DIRECTORIES).len == 0  # fixture carries neither file
    let manifest = treeGood().with(entry(DIRECTORY_ALPHA & "/package.json", "{}\n"))
    check manifest.directoriesNode(DIRECTORIES).len == 0  # manifest without lock pins no tool
    let both = manifest.with(entry(DIRECTORY_ALPHA & "/package-lock.json", "{}\n"))
    check both.directoriesNode(DIRECTORIES) == @[DIRECTORY_ALPHA]
    # Lock alone names no tools to install, so it selects nothing either.
    let lock_alone = treeGood().with(entry(DIRECTORY_ALPHA & "/package-lock.json", "{}\n"))
    check lock_alone.directoriesNode(DIRECTORIES).len == 0


  test "type check is scoped as compiling is":
    let both = treeGood().with(
      entry(DIRECTORY_ALPHA & "/package.json", "{}\n"),
      entry(DIRECTORY_ALPHA & "/package-lock.json", "{}\n"),
    )
    # `check` narrows to changed projects first, then to node ones.
    check both.directoriesNode(projectsTest(DIRECTORIES, [DIRECTORY_ALPHA & "/src/alpha.nim"])) ==
      @[DIRECTORY_ALPHA]
    # Change to other project selects that project alone, and it carries no manifest.
    let given = projectsTest(DIRECTORIES, [DIRECTORY_AUDIT & "/tests/taudit.nim"])
    check both.directoriesNode(given).len == 0  # given only


  test "project gains driven checks by carrying that verb, read from its own driver":
    # Nothing lists which project is driven either: koch reads driver's own dispatch, so
    #   verb arriving is what selects project, exactly as manifest is for type check.
    const driver = DIRECTORY_ALPHA & "/tools/build.nim"
    check treeGood().directoriesVerb(DIRECTORIES, "drive").len == 0  # fixture carries no driver
    let quiet = treeGood().with(
      entry(driver, "case paramStr(1)\n" & "of \"web\": web()\n" & "else:\n"),
    )
    check quiet.directoriesVerb(DIRECTORIES, "drive").len == 0  # driver without verb drives nothing
    check quiet.directoriesVerb(DIRECTORIES, "web") == @[DIRECTORY_ALPHA]
    let driven = treeGood().with(
      entry(
        driver,
        "case paramStr(1)\n" & "of \"web\": web()\n" & "of \"drive\": drive()\n" & "else:\n",
      ),
    )
    check driven.directoriesVerb(DIRECTORIES, "drive") == @[DIRECTORY_ALPHA]
    # Verb named past dispatch's `else` is another case's, never this project's.
    let after = treeGood().with(
      entry(
        driver,
        "case paramStr(1)\n" & "of \"web\": web()\n" & "else:\n" & "of \"drive\": drive()\n",
      ),
    )
    check after.directoriesVerb(DIRECTORIES, "drive").len == 0


  test "driven set filters what plan already selected, so it inherits every scoping":
    const driver = DIRECTORY_ALPHA & "/tools/build.nim"
    let
      tree = treeGood().with(
        entry(driver, "case paramStr(1)\n" & "of \"drive\": drive()\n" & "else:\n"),
      )
      selected = tree.drivenOnly(tree.jobs([DIRECTORY_ALPHA & "/src/alpha.nim"]))
    check selected.len == 1
    check selected[0].directory == DIRECTORY_ALPHA
    check selected[0].pin == PIN  # drive job installs project's own pin, as `test` does
    # Change to project carrying no driven verb selects that project and drives nothing.
    check tree.drivenOnly(tree.jobs([DIRECTORY_AUDIT & "/tests/taudit.nim"])).len == 0  # filters
    # Whole-repository run narrows to driven ones too, rather than driving all.
    check tree.drivenOnly(tree.jobsAll) == selected


  test "head set is projects whose driver carries `head`, filtered as driven set is":
    # Daily run asks `--all`, so filter over every project is what selects one; driver
    #   carrying `drive` alone carries no reference to read.
    const driver = DIRECTORY_ALPHA & "/tools/build.nim"
    let
      held = treeGood().with(
        entry(
          driver,
          "case paramStr(1)\n" & "of \"drive\": drive()\n" & "of \"head\": head()\n" & "else:\n",
        ),
      )
      selected = held.carryingOnly(held.jobsAll, VERB_HEAD)
    check selected.mapIt(it.directory) == @[DIRECTORY_ALPHA]
    check selected[0].pin == PIN  # verb compiles project code, so it runs on project's pin
    check held.carryingOnly(held.jobs([DIRECTORY_AUDIT & "/tests/taudit.nim"]),
      VERB_HEAD).len == 0  # filters what plan selected
    let driven = treeGood().with(
      entry(driver, "case paramStr(1)\n" & "of \"drive\": drive()\n" & "else:\n"),
    )
    check driven.carryingOnly(driven.jobsAll, VERB_HEAD).len == 0  # `drive` alone
    check driven.carryingOnly(driven.jobsAll, VERB_DRIVEN) == driven.drivenOnly(driven.jobsAll)


  test "checker change selects the driver's project alone, never every project":
    check projectsTest(DIRECTORIES, ["koch.nim"]) == @[DIRECTORY_AUDIT]  # driver's suites read it
    check projectsTest(DIRECTORIES, ["koch.nim.cfg"]) == @[DIRECTORY_AUDIT]  # driver flags
    check projectsTest(DIRECTORIES, [DIRECTORY_CHECKER & "/layout.nim"]) ==
      @[DIRECTORY_AUDIT]  # code of that project
    check projectsTest(DIRECTORIES, ["koch.nim", DIRECTORY_CHECKER & "/plan.nim"]) ==
      @[DIRECTORY_AUDIT]  # once


  test "knoller source selects driver's project, which imports it, and knoller itself":
    let directories = [DIRECTORY_ALPHA, DIRECTORY_AUDIT, DIRECTORY_KNOLLER]
    check projectsTest(directories, [FILES_KNOLLER[0] & "/knoller/tokens.nim"]) ==
      @[DIRECTORY_AUDIT, DIRECTORY_KNOLLER]  # source both read
    check projectsTest(directories, [FILES_KNOLLER[1]]) ==
      @[DIRECTORY_AUDIT, DIRECTORY_KNOLLER]  # nimble file names pin
    check projectsTest(directories, [DIRECTORY_KNOLLER & "/tests/suites/test_tokens.nim"]) ==
      @[DIRECTORY_KNOLLER]  # knoller's suite alone, which driver never reads
    check projectsTest(directories, [DIRECTORY_KNOLLER & "/PROVENANCE.md"]).len == 0  # record
    check projectsTest(directories, [DIRECTORY_KNOLLER & "/srcs/x.nim"]) ==
      @[DIRECTORY_KNOLLER]  # folder sharing prefix is no source


  test "knoller source selects each project importing it by path, as its source reads":
    let
      directories = [DIRECTORY_IMPORTING, DIRECTORY_AUDIT, DIRECTORY_KNOLLER, DIRECTORY_PROBE]
      tree = @[
        entry(DIRECTORY_AUDIT & "/src/plan.nim", "import ../../knoller/src/knoller\n"),
        entry(DIRECTORY_IMPORTING & "/src/assayer/command.nim",
            "import ../../../knoller/src/knoller/[compilers, pins]\n"),
        entry(DIRECTORY_KNOLLER & "/src/knoller.nim", "import ./knoller/[pins]\n"),
        entry(DIRECTORY_PROBE & "/src/probe.nim", "## Names `knoller/src/knoller` in comment.\n"),
      ]
      importers = tree.directoriesImporting(directories)
      from_import = @[entry(DIRECTORY_PROBE & "/src/probe.nim",
          "from ../../knoller/src/knoller import NIM\n")]
    check importers == @[DIRECTORY_IMPORTING, DIRECTORY_AUDIT]  # comment and own path import none
    check from_import.directoriesImporting([DIRECTORY_PROBE]) == @[DIRECTORY_PROBE]  # `from` too
    check projectsTest(directories, [FILES_KNOLLER[0] & "/knoller/pins.nim"], importers) ==
        @[DIRECTORY_IMPORTING, DIRECTORY_AUDIT, DIRECTORY_KNOLLER]  # each importer, and knoller
    check projectsTest(directories, [FILES_KNOLLER[1]], importers) ==
        @[DIRECTORY_IMPORTING, DIRECTORY_AUDIT, DIRECTORY_KNOLLER]  # nimble file names pin
    check projectsTest(directories, ["koch.nim"], importers) == @[DIRECTORY_AUDIT]  # driver alone


  test "path inside no project selects nothing by itself":
    check projectsTest(DIRECTORIES, ["CONSTITUTION.md"]).len == 0  # rules reach projects by stamp
    check projectsTest(DIRECTORIES, ["README.md", "LICENSE.md"]).len == 0  # root prose
    check projectsTest(DIRECTORIES, newSeq[string]()).len == 0  # empty change


  test "jobs carry each project's own pin, and skip project pinning none":
    let
      tree = treeGood()
      selected = tree.jobs([DIRECTORY_ALPHA & "/src/alpha.nim"])
    check selected.len == 1
    check selected[0].directory == DIRECTORY_ALPHA
    check selected[0].pin == PIN
    check tree.jobsAll.len == DIRECTORIES.len  # `--all` names every project
    let unpinned = tree.replaced(DIRECTORY_ALPHA & "/alpha.nimble", "requires \"nim >= 2.2.4\"\n")
    check unpinned.jobs([DIRECTORY_ALPHA & "/src/alpha.nim"]).len == 0  # nothing to install


  test "recent window runs what merged in it, or nothing at all":
    let root = repoTemp()
    defer: removeDir(root)
    let tree = treeGood()
    # Repository younger than window holds no commit to diff from, so it sweeps whole.
    check recentFor(root, tree, 7) == tree.jobsAll  # every project
    # Window holding no merge has nothing to find, so it compiles nothing.
    check recentFor(root, tree, 0).len == 0  # quiet week


  test "koch declares what it needs, as the rule it enforces asks of every project":
    # No project here declares anything, so what comes back is koch's own alone, which
    #   makes this readable without running any project's verb.
    check systemRepository(".", treeGood(), newSeq[string]()) ==
      @["coreutils", "curl", "git", "libbrotli1", "tar"]
    check SYSTEM_KOCH.mapIt(it[0]).deduplicate.len == SYSTEM_KOCH.len  # each package once
    for (package, why) in SYSTEM_KOCH:
      check package.len > 0
      check why.len > 0  # reason in field outlives one in comment (CONTRIBUTOR.md)
      check ' ' notin package  # verb prints bare names; reason would arrive as package name


  test "plan renders as matrix entries CI reads":
    let node = parseJson(treeGood().jobs([DIRECTORY_ALPHA & "/src/alpha.nim"]).render)
    check node.kind == JArray
    check node.len == 1
    check node[0]["dir"].getStr == DIRECTORY_ALPHA
    check node[0]["nim"].getStr == PIN
    check node[0]["kind"].getStr == "version"  # CI branches on this
    check treeGood().jobs(newSeq[string]()).render == "[]"  # empty plan skips matrix

    # Non-ASCII domain folder survives JSON, since matrix reads path back verbatim.
    let built = @[Job(directory: "p", pin: COMMIT)]
    check parseJson(built.render)[0]["kind"].getStr == "commit"  # built from source

    let accented = @[Job(directory: "contributor/síncopa/dance_ontology", pin: "2.2.6")]
    check parseJson(accented.render)[0]["dir"].getStr ==
      "contributor/síncopa/dance_ontology"
