## Replicate staleness rule of `base.nim` header and CURATOR.md settings section.

{.experimental: "strictFuncs".}

import std/[strutils, unittest]
import ../../src/[base, plan, provenance]



suite "Base":
  test "charter and checker govern what green means; nothing else does":
    for rule in RULES: check rule.isGoverning  # constitution, style, contributor
    check "koch.nim".isGoverning
    check "koch.nim.cfg".isGoverning
    check (DIRECTORY_CHECKER & "/layout.nim").isGoverning
    check (FILES_KNOLLER[0] & "/knoller/tokens.nim").isGoverning  # checker imports it by path
    check (FILES_KNOLLER[1]).isGoverning  # its nimble file
    check not "curator/knoller/tests/suites/test_tokens.nim".isGoverning  # its suites do not
    # Project's own code, records and suites do not.
    check not "contributor/ronri/alpha/src/alpha.nim".isGoverning
    check not "contributor/ronri/alpha/PROVENANCE.md".isGoverning
    check not "CURATOR.md".isGoverning  # curator-only, never stamped
    check not "README.md".isGoverning
    check not (DIRECTORY_CHECKER.replace("/src", "") & "/tests/test_layout.nim").isGoverning


  test "branch predating rules or checker is one finding naming what it lacks":
    check checkBase(Drift()).len == 0  # base gained nothing
    check checkBase(Drift(gained: @["contributor/ronri/alpha/src/alpha.nim"])).len == 0
    check checkBase(Drift(gained: @["CURATOR.md", "README.md"])).len == 0  # prose stamps none

    let found = checkBase(
      Drift(gained: @["CONTRIBUTOR.md", "contributor/ronri/alpha/x.nim", "koch.nim"])
    )
    check found.len == 1  # one finding, however many paths
    check found[0].path.len == 0  # branch-level, no file to open
    check found[0].message.endsWith("got `CONTRIBUTOR.md, koch.nim`.")  # only what governs
    check "as /sync says" in found[0].message  # check that sees drift names its skill


  test "each governing path is named once":
    check checkBase(Drift(gained: @["koch.nim", "koch.nim.cfg"]))[0].message.endsWith(
      "got `koch.nim, koch.nim.cfg`.",
    )
    check checkBase(Drift(gained: @["koch.nim", "koch.nim"]))[0].message.endsWith(
      "got `koch.nim`.",
    )
