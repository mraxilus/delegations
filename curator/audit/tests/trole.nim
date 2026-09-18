discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Replicate role rule of CONTRIBUTOR.md, Say which role you are, over pull request bodies.

import std/[strutils, unicode, unittest]
import ../src/role


suite "Role":
  test "role line is first non-blank line, without its trailing comment":
    check "**Role:** curator\n\n## Intent\n".roleLine == "**Role:** curator"
    check "\n\n**Role:** curator\n".roleLine == "**Role:** curator"  # blank lines skipped
    check "  **Role:** curator  \n".roleLine == "**Role:** curator"  # surrounding space
    check "**Role:** <!-- curator, or contributor -->\n".roleLine ==
      "**Role:**"  # unfilled template keeps key alone
    check "**Role:** curator <!-- copied -->\n".roleLine == "**Role:** curator"
    check "".roleLine == ""
    check "\n \n".roleLine == ""

  test "echoed opening is cut, since body may open with whole paragraph":
    check "short".shortened == "short"
    check "é".repeat(ECHO_MAX).shortened == "é".repeat(ECHO_MAX)  # runes, never bytes
    let long = "x".repeat(ECHO_MAX + 1).shortened
    check long.runeLen == ECHO_MAX + 1 and long.endsWith("…")  # cut marked
    check checkRole("curator/mend-it", "y".repeat(200), ["curator"])[0].message.endsWith(
      "got `" & "y".repeat(ECHO_MAX) & "…`."
    )

  test "each branch arm names one role, and both halves demand it":
    for (branch, expected) in [
      ("curator/mend-it", "curator"),
      ("curator/audit/mend-it", "curator/audit"),
      ("contributor/ronri/alpha/mend-it", "contributor/ronri/alpha"),
    ]:
      check checkRole(branch, "**Role:** " & expected & "\n", [expected]).len == 0
      # Role of some other branch fails opening line and label alike.
      check checkRole(branch, "**Role:** curator/probe\n", ["curator/probe"]).len == 2

  test "missing, unfilled and mismatched opening each report once":
    let bare = checkRole("curator/mend-it", "## Intent\n", ["curator"])
    check bare.len == 1
    check bare[0].path.len == 0  # branch-level, no file to open
    check bare[0].message.endsWith("got `## Intent`.")
    check checkRole(
      "curator/mend-it", "**Role:** <!-- curator, or contributor -->\n", ["curator"]
    ).len == 1  # template opened and left unfilled
    check checkRole("curator/mend-it", "**Role:** contributor/ronri/alpha\n", ["curator"])
      .len == 1  # role of somebody else

  test "label must be present, beside any other":
    check checkRole(
      "curator/mend-it", "**Role:** curator\n", ["curator", "contributor/ronri/alpha"]
    ).len == 0  # label joins when work hands across
    let unlabelled = checkRole("curator/mend-it", "**Role:** curator\n", newSeq[string]())
    check unlabelled.len == 1
    check unlabelled[0].message.endsWith("got ``.")  # nothing to echo
    check checkRole("curator/mend-it", "**Role:** curator\n", ["curator/audit"]).len ==
      1  # near miss is miss

  test "branch outside grammar reports nothing, since scope already fails it":
    check checkRole("claude/setup-5uk08q", "", newSeq[string]()).len == 0
    check checkRole("main", "", newSeq[string]()).len == 0
    check checkRole("contributor/nowhere/alpha/work", "", newSeq[string]()).len ==
      0  # domain unregistered
