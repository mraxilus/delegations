discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Replicate scoped test selection of `plan.nim` header and CURATOR.md checks reference.

import std/[json, options, unittest]
import ../src/[plan, projects]
import ./fixtures


const DIRS = [ALPHA_DIR, AUDIT_DIR]
  ## Project directories fixture tree holds, in sorted order selection returns them:
  ## `contributor` sorts before `curator`.


suite "Plan":
  test "code change selects its project alone":
    check testSet(DIRS, [ALPHA_DIR & "/src/alpha.nim"]) == @[ALPHA_DIR]  # source
    check testSet(DIRS, [ALPHA_DIR & "/tests/tall.nim"]) == @[ALPHA_DIR]  # test
    check testSet(DIRS, [ALPHA_DIR & "/alpha.nimble"]) == @[ALPHA_DIR]  # requirements
    check testSet(DIRS, [ALPHA_DIR & "/pages/index.html"]) == @[ALPHA_DIR]  # page

  test "record change alone selects nothing, so rules propagation compiles nothing":
    check testSet(DIRS, [ALPHA_DIR & "/PROVENANCE.md"]).len == 0  # stamp only
    check testSet(DIRS, [ALPHA_DIR & "/GLOSSARY.md"]).len == 0  # terms only
    check testSet(DIRS, [ALPHA_DIR & "/README.md"]).len == 0  # README runs nothing either
    # Nested README is code: only project's own three records describe project.
    check testSet(DIRS, [ALPHA_DIR & "/design/README.md"]) == @[ALPHA_DIR]
    for dir in DIRS:
      check testSet(DIRS, [dir & "/PROVENANCE.md", dir & "/GLOSSARY.md"]).len == 0
    # Record beside code still selects, since code changed.
    check testSet(DIRS, [ALPHA_DIR & "/PROVENANCE.md", ALPHA_DIR & "/src/a.nim"]) ==
      @[ALPHA_DIR]

  test "project gains type check by carrying node manifest and its lock":
    # Nothing lists which project is type-checked: `check.yml` names no project, exactly as
    #   it names none for compiler matrix, so derivation is only place truth lives.
    check goodTree().nodeDirs(DIRS).len == 0  # fixture carries neither file
    let manifest = goodTree().with(entry(ALPHA_DIR & "/package.json", "{}\n"))
    check manifest.nodeDirs(DIRS).len == 0  # manifest without lock pins no tool, so no
    let both = manifest.with(entry(ALPHA_DIR & "/package-lock.json", "{}\n"))
    check both.nodeDirs(DIRS) == @[ALPHA_DIR]
    # Lock alone names no tools to install, so it selects nothing either.
    check goodTree().with(entry(ALPHA_DIR & "/package-lock.json", "{}\n")).nodeDirs(DIRS).len == 0

  test "type check is scoped as compiling is, so records propagation type-checks nothing":
    let both = goodTree().with(
      entry(ALPHA_DIR & "/package.json", "{}\n"),
      entry(ALPHA_DIR & "/package-lock.json", "{}\n"),
    )
    # `ci` narrows to changed projects first, then to node ones; record change narrows away.
    check both.nodeDirs(testSet(DIRS, [ALPHA_DIR & "/PROVENANCE.md"])).len == 0
    check both.nodeDirs(testSet(DIRS, [ALPHA_DIR & "/src/alpha.nim"])) == @[ALPHA_DIR]
    # Change to other project selects that project alone, and it carries no manifest.
    check both.nodeDirs(testSet(DIRS, [AUDIT_DIR & "/tests/taudit.nim"])).len == 0
    # Checker change selects every project, so it type-checks node ones too: how each is
    #   checked changed, and that reaches this check exactly as it reaches compiling.
    check both.nodeDirs(testSet(DIRS, ["koch.nim"])) == @[ALPHA_DIR]

  test "project gains driven checks by carrying that verb, read from its own driver":
    # Nothing lists which project is driven either: koch reads driver's own dispatch, so
    #   verb arriving is what selects project, exactly as manifest is for type check.
    const DRIVER = ALPHA_DIR & "/tools/build.nim"
    check goodTree().verbDirs(DIRS, "drive").len == 0  # fixture carries no driver
    let quiet = goodTree().with(entry(DRIVER,
      "case paramStr(1)\n" &
      "of \"web\": web()\n" &
      "else:\n"))
    check quiet.verbDirs(DIRS, "drive").len == 0  # driver without verb drives nothing
    check quiet.verbDirs(DIRS, "web") == @[ALPHA_DIR]
    let driven = goodTree().with(entry(DRIVER,
      "case paramStr(1)\n" &
      "of \"web\": web()\n" &
      "of \"drive\": drive()\n" &
      "else:\n"))
    check driven.verbDirs(DIRS, "drive") == @[ALPHA_DIR]
    # Verb named past dispatch's `else` is another case's, never this project's.
    let after = goodTree().with(entry(DRIVER,
      "case paramStr(1)\n" &
      "of \"web\": web()\n" &
      "else:\n" &
      "of \"drive\": drive()\n"))
    check after.verbDirs(DIRS, "drive").len == 0

  test "driven set filters what plan already selected, so it inherits every scoping":
    const DRIVER = ALPHA_DIR & "/tools/build.nim"
    let tree = goodTree().with(entry(DRIVER,
      "case paramStr(1)\n" & "of \"drive\": drive()\n" & "else:\n"))
    # Record change selects nothing to compile, so it selects nothing to drive.
    check tree.drivenOnly(tree.jobs([ALPHA_DIR & "/PROVENANCE.md"])).len == 0
    let selected = tree.drivenOnly(tree.jobs([ALPHA_DIR & "/src/alpha.nim"]))
    check selected.len == 1
    check selected[0].dir == ALPHA_DIR
    check selected[0].pin == PIN  # driven job installs project's own pin, as `tests` does
    # Change to project carrying no driven verb selects that project and drives nothing.
    check tree.drivenOnly(tree.jobs([AUDIT_DIR & "/tests/taudit.nim"])).len == 0
    # Checker change selects every project, so it drives driven ones: how each is checked
    #   changed, and that reaches this check exactly as it reaches compiling.
    check tree.drivenOnly(tree.jobs([CHECKER_DIR & "/plan.nim"])) == selected
    # Sweep and whole-repository runs narrow to driven ones too, rather than driving all.
    check tree.drivenOnly(tree.allJobs) == selected
    check tree.drivenOnly(tree.sweepJobs([ALPHA_DIR & "/src/alpha.nim"])) == selected

  test "checker change selects every project, because how each is checked changed":
    check testSet(DIRS, ["koch.nim"]) == @DIRS  # driver
    check testSet(DIRS, ["koch.nim.cfg"]) == @DIRS  # driver flags
    check testSet(DIRS, [CHECKER_DIR & "/layout.nim"]) == @DIRS  # check source
    check isChecker(CHECKER_DIR & "/layout.nim")
    check not isChecker(AUDIT_DIR & "/tests/tlayout.nim")  # checker's own suite is code

  test "path inside no project selects nothing by itself":
    check testSet(DIRS, ["CONSTITUTION.md"]).len == 0  # rules reach projects by stamp
    check testSet(DIRS, ["README.md", "LICENSE.md"]).len == 0  # root prose
    check testSet(DIRS, newSeq[string]()).len == 0  # empty change

  test "jobs carry each project's own pin, and skip project pinning none":
    let tree = goodTree()
    check tree.pinOf(AUDIT_DIR) == some(PIN)  # fixture pin
    let selected = tree.jobs([ALPHA_DIR & "/src/alpha.nim"])
    check selected.len == 1
    check selected[0].dir == ALPHA_DIR
    check selected[0].pin == PIN
    check tree.allJobs.len == DIRS.len  # sweep names every project
    let unpinned = tree.replaced(
      ALPHA_DIR & "/alpha.nimble", "requires \"nim >= 2.2.4\"\n"
    )
    check unpinned.jobs([ALPHA_DIR & "/src/alpha.nim"]).len == 0  # nothing to install

  test "sweep runs whole repository, or nothing at all":
    let tree = goodTree()
    # Code merged in window: every project, since rot can land anywhere.
    check tree.sweepJobs([ALPHA_DIR & "/src/alpha.nim"]).len == DIRS.len
    check tree.sweepJobs([CHECKER_DIR & "/layout.nim"]).len == DIRS.len
    # Nothing merged, or records only: sweep skips itself entirely.
    check tree.sweepJobs(newSeq[string]()).len == 0  # quiet week
    check tree.sweepJobs([ALPHA_DIR & "/PROVENANCE.md"]).len == 0  # stamps only
    check tree.sweepJobs(["README.md"]).len == 0  # root prose only
    check SWEEP_DAYS == 7  # window matches weekly cron in check.yml

  test "koch declares what it needs, as the rule it enforces asks of every project":
    # Repository issue 78: koch held every project to declaration it kept only in prose.
    #   No project here declares anything, so what comes back is koch's own alone -- which is
    #   what makes this readable without running any project's verb.
    check repositorySystem(".", goodTree(), newSeq[string]()) == @["curl", "git"]
    check KOCH_SYSTEM.len == 2
    for (package, why) in KOCH_SYSTEM:
      check package.len > 0
      check why.len > 0  # reason in field outlives one in comment (CONTRIBUTOR.md)
      check ' ' notin package  # verb prints bare names; reason would arrive as package name

  test "plan renders as matrix entries CI reads":
    let node = parseJson(goodTree().jobs([ALPHA_DIR & "/src/alpha.nim"]).render)
    check node.kind == JArray
    check node.len == 1
    check node[0]["dir"].getStr == ALPHA_DIR
    check node[0]["nim"].getStr == PIN
    check node[0]["kind"].getStr == "version"  # CI branches on this
    check goodTree().jobs(newSeq[string]()).render == "[]"  # empty plan skips matrix

    # Non-ASCII domain folder survives JSON, since matrix reads path back verbatim.
    let built = @[Job(dir: "p", pin: "295bafc0d7e9a0c9a3ba0d9b39b5b0b6a4c1d2e3")]
    check parseJson(built.render)[0]["kind"].getStr == "commit"  # built from source

    let accented = @[Job(dir: "contributor/síncopa/dance_ontology", pin: "2.2.6")]
    check parseJson(accented.render)[0]["dir"].getStr ==
      "contributor/síncopa/dance_ontology"
