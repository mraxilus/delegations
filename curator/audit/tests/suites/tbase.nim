discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Replicate staleness rule of `base.nim` header and CURATOR.md settings section.

import std/[strutils, unittest]
import ../src/[base, plan, provenance]


suite "Base":
  test "charter and checker govern what green means; nothing else does":
    for rule in RULES: check rule.isGoverning  # constitution, style, contributor
    check "koch.nim".isGoverning
    check "koch.nim.cfg".isGoverning
    check (CHECKER_DIR & "/layout.nim").isGoverning
    # Project's own code, records and suites do not.
    check not "contributor/ronri/alpha/src/alpha.nim".isGoverning
    check not "contributor/ronri/alpha/PROVENANCE.md".isGoverning
    check not "CURATOR.md".isGoverning  # curator-only, never stamped
    check not "README.md".isGoverning
    check not (CHECKER_DIR.replace("/src", "") & "/tests/tlayout.nim").isGoverning

  test "branch predating rules or checker is one finding naming what it lacks":
    check checkBase(newSeq[string]()).len == 0  # base gained nothing
    check checkBase(["contributor/ronri/alpha/src/alpha.nim"]).len == 0  # other project's code
    check checkBase(["CURATOR.md", "README.md"]).len == 0  # prose neither stamps nor checks

    let found = checkBase(["CONTRIBUTOR.md", "contributor/ronri/alpha/x.nim", "koch.nim"])
    check found.len == 1  # one finding, however many paths
    check found[0].path.len == 0  # branch-level, no file to open
    check found[0].message.endsWith("got `CONTRIBUTOR.md, koch.nim`.")  # only what governs

  test "each governing path is named once":
    check checkBase(["koch.nim", "koch.nim.cfg"])[0].message.endsWith(
      "got `koch.nim, koch.nim.cfg`."
    )
    check checkBase(["koch.nim", "koch.nim"])[0].message.endsWith("got `koch.nim`.")
