## Replicate scoped test selection of `plan.nim` header and CURATOR.md checks reference.

{.experimental: "strictFuncs".}

import std/[json, os, sequtils, unittest]
import ../../src/[plan, projects, toolchain]
import ./fixtures


const DIRECTORIES = [ALPHA_DIRECTORY, AUDIT_DIRECTORY]
  ## Project directories fixture tree holds, in sorted order selection returns them:
  ## `contributor` sorts before `curator`.



suite "Plan":
  test "code change selects its project alone":
    check testSet(DIRECTORIES, [ALPHA_DIRECTORY & "/src/alpha.nim"]) == @[ALPHA_DIRECTORY]  # source
    check testSet(DIRECTORIES, [ALPHA_DIRECTORY & "/tests/tall.nim"]) == @[ALPHA_DIRECTORY]  # test
    check testSet(DIRECTORIES, [ALPHA_DIRECTORY & "/alpha.nimble"]) ==
      @[ALPHA_DIRECTORY]  # requirements
    check testSet(DIRECTORIES, [ALPHA_DIRECTORY & "/pages/index.html"]) ==
      @[ALPHA_DIRECTORY]  # page


  test "record change alone selects nothing, so rules propagation compiles nothing":
    check testSet(DIRECTORIES, [ALPHA_DIRECTORY & "/PROVENANCE.md"]).len == 0  # stamp only
    check testSet(DIRECTORIES, [ALPHA_DIRECTORY & "/GLOSSARY.md"]).len == 0  # terms only
    check testSet(DIRECTORIES, [ALPHA_DIRECTORY & "/README.md"]).len == 0  # README runs nothing
    # Nested README is code: only project's own three records describe project.
    check testSet(DIRECTORIES, [ALPHA_DIRECTORY & "/design/README.md"]) == @[ALPHA_DIRECTORY]
    for directory in DIRECTORIES:
      let records = [directory & "/PROVENANCE.md", directory & "/GLOSSARY.md"]
      check testSet(DIRECTORIES, records).len == 0
    # Record beside code still selects, since code changed.
    let mixed = [ALPHA_DIRECTORY & "/PROVENANCE.md", ALPHA_DIRECTORY & "/src/a.nim"]
    check testSet(DIRECTORIES, mixed) == @[ALPHA_DIRECTORY]


  test "project gains type check by carrying node manifest and its lock":
    # Nothing lists which project is type-checked: `check.yml` names no project, exactly as
    #   it names none for compiler matrix, so derivation is only place truth lives.
    check goodTree().nodeDirectories(DIRECTORIES).len == 0  # fixture carries neither file
    let manifest = goodTree().with(entry(ALPHA_DIRECTORY & "/package.json", "{}\n"))
    check manifest.nodeDirectories(DIRECTORIES).len == 0  # manifest without lock pins no tool
    let both = manifest.with(entry(ALPHA_DIRECTORY & "/package-lock.json", "{}\n"))
    check both.nodeDirectories(DIRECTORIES) == @[ALPHA_DIRECTORY]
    # Lock alone names no tools to install, so it selects nothing either.
    let lock_alone = goodTree().with(entry(ALPHA_DIRECTORY & "/package-lock.json", "{}\n"))
    check lock_alone.nodeDirectories(DIRECTORIES).len == 0


  test "type check is scoped as compiling is":
    let both = goodTree().with(
      entry(ALPHA_DIRECTORY & "/package.json", "{}\n"),
      entry(ALPHA_DIRECTORY & "/package-lock.json", "{}\n"),
    )
    # `check` narrows to changed projects first, then to node ones.
    check both.nodeDirectories(testSet(DIRECTORIES, [ALPHA_DIRECTORY & "/src/alpha.nim"])) ==
      @[ALPHA_DIRECTORY]
    # Change to other project selects that project alone, and it carries no manifest.
    let given = testSet(DIRECTORIES, [AUDIT_DIRECTORY & "/tests/taudit.nim"])
    check both.nodeDirectories(given).len == 0  # given only


  test "project gains driven checks by carrying that verb, read from its own driver":
    # Nothing lists which project is driven either: koch reads driver's own dispatch, so
    #   verb arriving is what selects project, exactly as manifest is for type check.
    const driver = ALPHA_DIRECTORY & "/tools/build.nim"
    check goodTree().verbDirectories(DIRECTORIES, "drive").len == 0  # fixture carries no driver
    let quiet = goodTree().with(
      entry(driver, "case paramStr(1)\n" & "of \"web\": web()\n" & "else:\n"),
    )
    check quiet.verbDirectories(DIRECTORIES, "drive").len == 0  # driver without verb drives nothing
    check quiet.verbDirectories(DIRECTORIES, "web") == @[ALPHA_DIRECTORY]
    let driven = goodTree().with(
      entry(
        driver,
        "case paramStr(1)\n" & "of \"web\": web()\n" & "of \"drive\": drive()\n" & "else:\n",
      ),
    )
    check driven.verbDirectories(DIRECTORIES, "drive") == @[ALPHA_DIRECTORY]
    # Verb named past dispatch's `else` is another case's, never this project's.
    let after = goodTree().with(
      entry(
        driver,
        "case paramStr(1)\n" & "of \"web\": web()\n" & "else:\n" & "of \"drive\": drive()\n",
      ),
    )
    check after.verbDirectories(DIRECTORIES, "drive").len == 0


  test "driven set filters what plan already selected, so it inherits every scoping":
    const driver = ALPHA_DIRECTORY & "/tools/build.nim"
    let
      tree = goodTree().with(
        entry(driver, "case paramStr(1)\n" & "of \"drive\": drive()\n" & "else:\n"),
      )
      selected = tree.drivenOnly(tree.jobs([ALPHA_DIRECTORY & "/src/alpha.nim"]))
    check selected.len == 1
    check selected[0].directory == ALPHA_DIRECTORY
    check selected[0].pin == PIN  # drive job installs project's own pin, as `test` does
    # Change to project carrying no driven verb selects that project and drives nothing.
    check tree.drivenOnly(tree.jobs([AUDIT_DIRECTORY & "/tests/taudit.nim"])).len == 0  # filters
    # Whole-repository run narrows to driven ones too, rather than driving all.
    check tree.drivenOnly(tree.allJobs) == selected


  test "head set is projects whose driver carries `head`, filtered as driven set is":
    # Daily run asks `--all`, so filter over every project is what selects one; driver
    #   carrying `drive` alone carries no reference to read.
    const driver = ALPHA_DIRECTORY & "/tools/build.nim"
    let
      held = goodTree().with(
        entry(
          driver,
          "case paramStr(1)\n" & "of \"drive\": drive()\n" & "of \"head\": head()\n" & "else:\n",
        ),
      )
      selected = held.carryingOnly(held.allJobs, HEAD_VERB)
    check selected.mapIt(it.directory) == @[ALPHA_DIRECTORY]
    check selected[0].pin == PIN  # verb compiles project code, so it runs on project's pin
    check held.carryingOnly(held.jobs([AUDIT_DIRECTORY & "/tests/taudit.nim"]),
      HEAD_VERB).len == 0  # filters what plan selected
    let driven = goodTree().with(
      entry(driver, "case paramStr(1)\n" & "of \"drive\": drive()\n" & "else:\n"),
    )
    check driven.carryingOnly(driven.allJobs, HEAD_VERB).len == 0  # `drive` alone
    check driven.carryingOnly(driven.allJobs, DRIVEN_VERB) == driven.drivenOnly(driven.allJobs)


  test "checker change selects the driver's project alone, never every project":
    check testSet(DIRECTORIES, ["koch.nim"]) == @[AUDIT_DIRECTORY]  # driver's suites read it
    check testSet(DIRECTORIES, ["koch.nim.cfg"]) == @[AUDIT_DIRECTORY]  # driver flags
    check testSet(DIRECTORIES, [CHECKER_DIRECTORY & "/layout.nim"]) ==
      @[AUDIT_DIRECTORY]  # code of that project
    check testSet(DIRECTORIES, ["koch.nim", CHECKER_DIRECTORY & "/plan.nim"]) ==
      @[AUDIT_DIRECTORY]  # once


  test "knoller source selects driver's project, which imports it, and knoller itself":
    let directories = [ALPHA_DIRECTORY, AUDIT_DIRECTORY, KNOLLER_DIRECTORY]
    check testSet(directories, [KNOLLER_FILES[0] & "/knoller/tokens.nim"]) ==
      @[AUDIT_DIRECTORY, KNOLLER_DIRECTORY]  # source both read
    check testSet(directories, [KNOLLER_FILES[1]]) ==
      @[AUDIT_DIRECTORY, KNOLLER_DIRECTORY]  # nimble file names pin
    check testSet(directories, [KNOLLER_DIRECTORY & "/tests/suites/test_tokens.nim"]) ==
      @[KNOLLER_DIRECTORY]  # knoller's suite alone, which driver never reads
    check testSet(directories, [KNOLLER_DIRECTORY & "/PROVENANCE.md"]).len == 0  # record
    check testSet(directories, [KNOLLER_DIRECTORY & "/srcs/x.nim"]) ==
      @[KNOLLER_DIRECTORY]  # folder sharing prefix is no source


  test "path inside no project selects nothing by itself":
    check testSet(DIRECTORIES, ["CONSTITUTION.md"]).len == 0  # rules reach projects by stamp
    check testSet(DIRECTORIES, ["README.md", "LICENSE.md"]).len == 0  # root prose
    check testSet(DIRECTORIES, newSeq[string]()).len == 0  # empty change


  test "jobs carry each project's own pin, and skip project pinning none":
    let
      tree = goodTree()
      selected = tree.jobs([ALPHA_DIRECTORY & "/src/alpha.nim"])
    check selected.len == 1
    check selected[0].directory == ALPHA_DIRECTORY
    check selected[0].pin == PIN
    check tree.allJobs.len == DIRECTORIES.len  # `--all` names every project
    let unpinned = tree.replaced(ALPHA_DIRECTORY & "/alpha.nimble", "requires \"nim >= 2.2.4\"\n")
    check unpinned.jobs([ALPHA_DIRECTORY & "/src/alpha.nim"]).len == 0  # nothing to install


  test "recent window runs what merged in it, or nothing at all":
    let root = tempRepo()
    defer: removeDir(root)
    let tree = goodTree()
    # Repository younger than window holds no commit to diff from, so it sweeps whole.
    check recentFor(root, tree, 7) == tree.allJobs  # every project
    # Window holding no merge has nothing to find, so it compiles nothing.
    check recentFor(root, tree, 0).len == 0  # quiet week


  test "koch declares what it needs, as the rule it enforces asks of every project":
    # No project here declares anything, so what comes back is koch's own alone, which
    #   makes this readable without running any project's verb.
    check repositorySystem(".", goodTree(), newSeq[string]()) ==
      @["coreutils", "curl", "git", "libbrotli1", "tar"]
    check KOCH_SYSTEM.mapIt(it[0]).deduplicate.len == KOCH_SYSTEM.len  # each package once
    for (package, why) in KOCH_SYSTEM:
      check package.len > 0
      check why.len > 0  # reason in field outlives one in comment (CONTRIBUTOR.md)
      check ' ' notin package  # verb prints bare names; reason would arrive as package name


  test "plan renders as matrix entries CI reads":
    let node = parseJson(goodTree().jobs([ALPHA_DIRECTORY & "/src/alpha.nim"]).render)
    check node.kind == JArray
    check node.len == 1
    check node[0]["dir"].getStr == ALPHA_DIRECTORY
    check node[0]["nim"].getStr == PIN
    check node[0]["kind"].getStr == "version"  # CI branches on this
    check goodTree().jobs(newSeq[string]()).render == "[]"  # empty plan skips matrix

    # Non-ASCII domain folder survives JSON, since matrix reads path back verbatim.
    let built = @[Job(directory: "p", pin: COMMIT)]
    check parseJson(built.render)[0]["kind"].getStr == "commit"  # built from source

    let accented = @[Job(directory: "contributor/síncopa/dance_ontology", pin: "2.2.6")]
    check parseJson(accented.render)[0]["dir"].getStr ==
      "contributor/síncopa/dance_ontology"
