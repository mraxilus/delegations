discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Replicate scoped test selection of `plan.nim` header and CURATOR.md checks reference.

import std/[json, options, unittest]
import ../src/plan
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
    for dir in DIRS:
      check testSet(DIRS, [dir & "/PROVENANCE.md", dir & "/GLOSSARY.md"]).len == 0
    # Record beside code still selects, since code changed.
    check testSet(DIRS, [ALPHA_DIR & "/PROVENANCE.md", ALPHA_DIR & "/src/a.nim"]) ==
      @[ALPHA_DIR]

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

  test "plan renders as matrix entries CI reads":
    let node = parseJson(goodTree().jobs([ALPHA_DIR & "/src/alpha.nim"]).render)
    check node.kind == JArray
    check node.len == 1
    check node[0]["dir"].getStr == ALPHA_DIR
    check node[0]["nim"].getStr == PIN
    check goodTree().jobs(newSeq[string]()).render == "[]"  # empty plan skips matrix

    # Non-ASCII domain folder survives JSON, since matrix reads path back verbatim.
    let accented = @[Job(dir: "contributor/síncopa/dance_ontology", pin: "2.2.6")]
    check parseJson(accented.render)[0]["dir"].getStr ==
      "contributor/síncopa/dance_ontology"
