## Replicate staleness rule of `base.nim` header and CURATOR.md settings section.

{.experimental: "strictFuncs".}

import std/[os, strutils, unittest]
import ../../src/[base, plan, provenance]
import ./fixtures


const GUIDE = "# Guide\n\nSteps.\n\n## Names\n\nWords.\n\n## Toolchain\n\nPin.\n\n" &
  "## Output contract\n\nSign off.\n"
  ## Guide holding sections of content, then one of process, as `GUIDE.md` does.


func drifted(fork, base: string; path = "GUIDE.md"): Drift =
  ## Build drift where base changed one rules document since `3f2a9c1`, as `origin/main`.
  result = Drift(fork: "3f2a9c1", base: "origin/main", gained: @[path])
  result.rules_fork[RULES.find(path)] = fork
  result.rules_base[RULES.find(path)] = base



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


  test "branch older than edit of Output contract names that section and its command":
    # Case as found (#843): finding named `GUIDE.md` alone, so reading of change rested on one
    #   sentence of CONTRIBUTOR.md, and it asked for stamp that no edit of process moves.
    let found = checkBase(drifted(GUIDE, GUIDE.replace("Sign off.", "Sign off, then stop.")))
    check found.len == 1 and found[0].path == "GUIDE.md" and found[0].line == 0
    check "`git diff 3f2a9c1..origin/main -- GUIDE.md`" in found[0].message  # shows change
    check found[0].message.endsWith(
      "; sections of process move no stamp; got `## Output contract`.",
    )
    check "re-stamp" notin found[0].message
    check "as /sync says" in found[0].message  # check that sees drift names its skill


  test "drift names each changed section in order base holds, and asks for stamp where it moved":
    let both =
      checkBase(drifted(GUIDE, GUIDE.replace("Pin.", "Pin it.").replace("Sign off.", "Go.")))
    check both[0].message.endsWith("got `## Toolchain`, `## Output contract`.")
    check "re-audit" in both[0].message and "re-stamp" in both[0].message  # Toolchain is content
    check "move no stamp" notin both[0].message
    check checkBase(drifted(GUIDE, GUIDE.replace("## Names\n\nWords.\n\n", "")))[0].message
      .endsWith("got `## Names`.")  # section base dropped
    check checkBase(drifted(GUIDE, GUIDE.replace("## Toolchain", "## Toolchains")))[0].message
      .endsWith("got `## Toolchains`, `## Toolchain`.")  # rename: new heading, then old one
    check checkBase(drifted(GUIDE, GUIDE.replace("Steps.", "More steps.")))[0].message
      .endsWith("got `# Guide`.")  # opening is named by its first line
    let fenced = GUIDE.replace("Sign off.", "Sign off.\n\n```md\n## Sign-off\n```\n")
    check checkBase(drifted(fenced, fenced.replace("```\n", "```\n\nThen stop.\n")))[0].message
      .endsWith("got `## Output contract`.")  # heading quoted in fence opens no section
    check checkBase(drifted(GUIDE, GUIDE)).len == 0  # same text at both ends names nothing
    # Moved section keeps its text, yet stamp reads parts in order, so move is change too.
    let moved = GUIDE.replace("## Names\n\nWords.\n\n## Toolchain\n\nPin.\n\n",
      "## Toolchain\n\nPin.\n\n## Names\n\nWords.\n\n")
    check checkBase(drifted(GUIDE, moved))[0].message.endsWith("got `## Toolchain`, `## Names`.")
    check "re-stamp" in checkBase(drifted(GUIDE, moved))[0].message
    # Heading written twice hides move from table of texts; document still differs, so each
    #   heading base holds is named.
    let
      twice_fork = "## X\n\na\n## Y\n\nb\n## X\n\nc\n"
      twice_base = "## X\n\na\n## X\n\nc\n## Y\n\nb\n"
    check checkBase(drifted(twice_fork, twice_base))[0].message.endsWith("got `## X`, `## Y`.")


  test "each changed document is one finding, and checker one more":
    check checkBase(Drift()).len == 0  # base gained nothing
    check checkBase(Drift(gained: @["contributor/ronri/alpha/src/alpha.nim"])).len == 0
    check checkBase(Drift(gained: @["CURATOR.md", "README.md"])).len == 0  # prose stamps none

    var drift = drifted(GUIDE, GUIDE.replace("Sign off.", "Go."))
    drift.gained.add ["contributor/ronri/alpha/x.nim", "koch.nim", "CONTRIBUTOR.md"]
    drift.rules_base[RULES.find("CONTRIBUTOR.md")] = "# Contributor\n\n## Data\n\nProtobuf.\n"
    let found = checkBase(drift)
    check found.len == 3  # each changed document in `RULES` order, then checker
    check found.len == 3 and found[0].path == "CONTRIBUTOR.md" and found[1].path == "GUIDE.md"
    check found.len == 3 and "re-stamp" in found[0].message  # content of its own moved
    check found.len == 3 and "re-stamp" notin found[1].message  # process alone moved here
    check found.len == 3 and found[2].path.len == 0  # checker is branch-level, no file to open
    check found.len == 3 and found[2].message.endsWith("got `koch.nim`.")  # only what governs
    check found.len == 3 and "as /sync says" in found[2].message


  test "drift reads fork and both ends of each rules document from git":
    # Real git on throwaway repository (Article IX.5): branch forks, then base edits sign-off.
    let root = repoTemp()
    defer: removeDir(root)
    root.writeInto("GUIDE.md", GUIDE)
    discard root.git("add -A")
    discard root.git("commit -q -m 'docs(curator): write guide'")
    let fork = root.git("rev-parse --short HEAD").strip
    discard root.git("branch curator/older")
    root.writeInto("GUIDE.md", GUIDE.replace("Sign off.", "Sign off, then stop."))
    discard root.git("commit -q -am 'docs(curator): sign off at once'")
    discard root.git("checkout -q curator/older")
    let drift = readDrift(root, "main")
    check drift.fork == fork and drift.gained == @["GUIDE.md"]
    let found = checkBase(drift)
    check found.len == 1 and ("`git diff " & fork & "..main -- GUIDE.md`") in found[0].message
    check found.len == 1 and found[0].message.endsWith("got `## Output contract`.")


  test "each governing path is named once":
    check checkBase(Drift(gained: @["koch.nim", "koch.nim.cfg"]))[0].message.endsWith(
      "got `koch.nim, koch.nim.cfg`.",
    )
    check checkBase(Drift(gained: @["koch.nim", "koch.nim"]))[0].message.endsWith(
      "got `koch.nim`.",
    )
