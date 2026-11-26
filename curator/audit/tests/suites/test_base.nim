## Replicate staleness rule of `base.nim` header and CURATOR.md settings section.

{.experimental: "strictFuncs".}

import std/[os, sequtils, strutils, unittest]
import ../../src/[base, findings, plan, provenance]
import ./fixtures


const
  GUIDE = "# Guide\n\nSteps.\n\n## Names\n\nWords.\n\n## Toolchain\n\nPin.\n\n" &
    "## Output contract\n\nSign off.\n"
    ## Guide holding sections of content, then one of process, as `GUIDE.md` does.
  STAMP = DIRECTORY_CHECKER & "/provenance.nim"
    ## Module holding `RULES`, `SECTIONS_PROCESS` and digest of stamp.
  HELP_MOVED = "; help: read `git diff 3f2a9c1..origin/main -- GUIDE.md`, merge base, re-audit " &
    "against each change, then re-stamp, as /sync says"
    ## Help of drift of fixture whose change moves stamp.
  HELP_PROCESS = "; help: read `git diff 3f2a9c1..origin/main -- GUIDE.md`, then merge base, as " &
    "/sync says; sections of process move no stamp"
    ## Help of drift of fixture whose change reaches section of process alone.
  HELP_STAMP = "; help: merge base, then check again, as /sync says"
    ## Help of drift of code of stamp.


func drifted(fork, base: string; path = "GUIDE.md"): Drift =
  ## Build drift where base changed one rules document since `3f2a9c1`, as `origin/main`.
  result = Drift(fork: "3f2a9c1", base: "origin/main", gained: @[path])
  result.rules_fork[RULES.find(path)] = fork
  result.rules_base[RULES.find(path)] = base



suite "Base":
  test "charter and code of stamp govern drift; checker and everything else do not (#893)":
    for rule in RULES: check rule.isGoverning  # constitution, style, contributor
    check STAMP.isGoverning  # checker code, yet change there can move every stamp
    # Checker reaches branch through merge `koch check` judges (`merge.nim`), as runner judges
    #   merge ref, so drift of it bought parity alone.
    check not "koch.nim".isGoverning
    check not "koch.nim.cfg".isGoverning
    check not (DIRECTORY_CHECKER & "/layout.nim").isGoverning
    check not (FILES_KNOLLER[0] & "/knoller/tokens.nim").isGoverning  # checker imports it by path
    check not (FILES_KNOLLER[1]).isGoverning  # its nimble file
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
    check "`git diff 3f2a9c1..origin/main -- GUIDE.md`" in found[0].brief  # shows change
    check found[0].brief.endsWith("; got `## Output contract`" & HELP_PROCESS)
    check "re-stamp" notin found[0].brief
    check "as /sync says" in found[0].brief  # check that sees drift names its skill


  test "drift names each changed section in order base holds, and asks for stamp where it moved":
    let both =
      checkBase(drifted(GUIDE, GUIDE.replace("Pin.", "Pin it.").replace("Sign off.", "Go.")))
    check both[0].brief.endsWith("got `## Toolchain`, `## Output contract`" & HELP_MOVED)
    check "re-audit" in both[0].brief and "re-stamp" in both[0].brief  # Toolchain is content
    check "move no stamp" notin both[0].brief
    check checkBase(drifted(GUIDE, GUIDE.replace("## Names\n\nWords.\n\n", "")))[0].brief
      .endsWith("got `## Names`" & HELP_MOVED)  # section base dropped
    check checkBase(drifted(GUIDE, GUIDE.replace("## Toolchain", "## Toolchains")))[0].brief
      .endsWith("got `## Toolchains`, `## Toolchain`" & HELP_MOVED)  # rename: new, then old
    check checkBase(drifted(GUIDE, GUIDE.replace("Steps.", "More steps.")))[0].brief
      .endsWith("got `# Guide`" & HELP_MOVED)  # opening is named by its first line
    let fenced = GUIDE.replace("Sign off.", "Sign off.\n\n```md\n## Sign-off\n```\n")
    check checkBase(drifted(fenced, fenced.replace("```\n", "```\n\nThen stop.\n")))[0].brief
      .endsWith("got `## Output contract`" & HELP_PROCESS)  # heading in fence opens no section
    check checkBase(drifted(GUIDE, GUIDE)).len == 0  # same text at both ends names nothing
    # Moved section keeps its text, yet stamp reads parts in order, so move is change too.
    let moved = GUIDE.replace("## Names\n\nWords.\n\n## Toolchain\n\nPin.\n\n",
      "## Toolchain\n\nPin.\n\n## Names\n\nWords.\n\n")
    check checkBase(drifted(GUIDE, moved))[0].brief
      .endsWith("got `## Toolchain`, `## Names`" & HELP_MOVED)
    check "re-stamp" in checkBase(drifted(GUIDE, moved))[0].brief
    # Heading written twice hides move from table of texts; document still differs, so each
    #   heading base holds is named.
    let
      twice_fork = "## X\n\na\n## Y\n\nb\n## X\n\nc\n"
      twice_base = "## X\n\na\n## X\n\nc\n## Y\n\nb\n"
    check checkBase(drifted(twice_fork, twice_base))[0].brief
      .endsWith("got `## X`, `## Y`" & HELP_MOVED)


  test "each changed document is one finding, and code of stamp one more; checker none":
    check checkBase(Drift()).len == 0  # base gained nothing
    check checkBase(Drift(gained: @["contributor/ronri/alpha/src/alpha.nim"])).len == 0
    check checkBase(Drift(gained: @["CURATOR.md", "README.md"])).len == 0  # prose stamps none
    check checkBase(Drift(gained: @["koch.nim", DIRECTORY_CHECKER & "/layout.nim"])).len == 0

    var drift = drifted(GUIDE, GUIDE.replace("Sign off.", "Go."))
    drift.gained.add ["contributor/ronri/alpha/x.nim", "koch.nim", "CONTRIBUTOR.md", STAMP]
    drift.rules_base[RULES.find("CONTRIBUTOR.md")] = "# Contributor\n\n## Data\n\nProtobuf.\n"
    let found = checkBase(drift)
    check found.len == 3  # each changed document in `RULES` order, then code of stamp
    check found.len == 3 and found[0].path == "CONTRIBUTOR.md" and found[1].path == "GUIDE.md"
    check found.len == 3 and "re-stamp" in found[0].brief  # content of its own moved
    check found.len == 3 and "re-stamp" notin found[1].brief  # process alone moved here
    check found.len == 3 and found[2].path.len == 0  # branch-level, no file to open
    check found.len == 3 and found[2].brief.endsWith("got `" & STAMP & "`" & HELP_STAMP)  # alone
    check found.len == 3 and "as /sync says" in found[2].brief


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
    check found.len == 1 and ("`git diff " & fork & "..main -- GUIDE.md`") in found[0].brief
    check found.len == 1 and found[0].brief.endsWith(
      "got `## Output contract`" & HELP_PROCESS.replace("3f2a9c1..origin/main", fork & "..main"),
    )


  test "code of stamp is named once, as module whose change can move every stamp":
    # Case as second record review of #893 found it: finding said change there moves every
    #   stamp, where one of five merges that changed module moved none.
    let found = checkBase(Drift(gained: @[STAMP, STAMP, "koch.nim"]))
    check found.len == 1 and found[0].brief.endsWith("got `" & STAMP & "`" & HELP_STAMP)
    check found.len == 1 and "which can move every stamp" in found[0].brief


  test "branch older than change of checker alone passes drift, and older than charter fails":
    # Done as #893 asks it: fixture branch predating change of checker alone passes, and
    #   `merge.nim` judges it with checker of base; one predating charter or code of stamp fails.
    #   Real git on throwaway repository (Article IX.5).
    let root = repoTemp()
    defer: removeDir(root)
    root.writeInto("GUIDE.md", GUIDE)
    root.writeInto("koch.nim", "discard\n")
    root.writeInto(STAMP, "discard\n")
    discard root.git("add -A")
    discard root.git("commit -q -m 'docs(curator): write guide'")
    discard root.git("branch curator/older")
    root.writeInto("koch.nim", "discard 1\n")
    root.writeInto(DIRECTORY_CHECKER & "/layout.nim", "discard\n")
    root.writeInto(FILES_KNOLLER[0] & "/knoller.nim", "discard\n")
    discard root.git("add -A")
    discard root.git("commit -q -m 'feat(audit): change checker alone'")
    discard root.git("checkout -q curator/older")
    check checkBase(readDrift(root, "main")).len == 0

    # Code of stamp can move every stamp, so it still drifts, and so does charter.
    discard root.git("checkout -q main")
    root.writeInto(STAMP, "discard 2\n")
    discard root.git("commit -q -am 'feat(audit): move code of stamp'")
    discard root.git("checkout -q curator/older")
    let moved = checkBase(readDrift(root, "main"))
    check moved.len == 1 and moved[0].brief.endsWith("got `" & STAMP & "`" & HELP_STAMP)
    check moved.anyIt(it.rule == "koch.drift")
    discard root.git("checkout -q main")
    root.writeInto("GUIDE.md", GUIDE.replace("Pin.", "Pin it."))
    discard root.git("commit -q -am 'docs(curator): pin it'")
    discard root.git("checkout -q curator/older")
    let found = checkBase(readDrift(root, "main"))
    check found.len == 2 and found[0].path == "GUIDE.md" and "re-stamp" in found[0].brief
    check found.len == 2 and "; got `## Toolchain`; help: read `git diff " in found[0].brief
