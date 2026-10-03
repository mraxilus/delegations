## Replicate role rule of CONTRIBUTOR.md, Say which role you are, over pull request bodies.
##   Cost: attribution block fixture copies harness's form, so harness changing it reddens
##     runner, never this suite.

{.experimental: "strictFuncs".}

import std/[strutils, unicode, unittest]
import ../../src/role


const
  MARKER = "<!-- ccr-projects-attribution: {\"github_login\":\"octocat\"} -->"
    ## Marker line of attribution block, as harness writes it.
  CREDIT =
    "_Requested by **Octocat** · [project thread](https://claude.ai/code/project/p?thread=t)_"
    ## Credit line of attribution block, as harness writes it.



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


  test "body below attribution block reads as body alone, so thread's pull request passes":
    for attribution in [MARKER & "\n" & CREDIT & "\n", MARKER & "\n\n" & CREDIT & "\n\n"]:
      for body in [
        "**Role:** curator\n\n## Intent\n", "**Role:** curator <!-- copied -->\n",
        "**Role:** <!-- curator, or contributor -->\n", "## Intent\n", "",
      ]:
        let attributed = attribution & body
        check attributed.roleLine == body.roleLine
        check attributed.replace("\n", "\r\n").roleLine == body.roleLine  # edited on GitHub
    check (MARKER & "\n**Role:** curator\n").roleLine == "**Role:** curator"  # credit left out
    let thread = MARKER & "\n" & CREDIT & "\n\n**Role:** curator\n\n## Intent\n"
    check checkRole("curator/mend-it", thread, ["curator"]).len == 0
    let wrong = checkRole(
      "curator/mend-it", MARKER & "\n" & CREDIT & "\n**Role:** curator/probe\n", ["curator"]
    )
    check wrong.len == 1
    check wrong[0].message.endsWith("got `**Role:** curator/probe`.")  # line below block echoed


  test "attribution block is passed only whole, once and in order":
    let unclosed = CREDIT[0..^2]  # italic never closed
    for (body, opening) in [
      (CREDIT & "\n**Role:** curator\n", CREDIT),  # credit with no marker
      (CREDIT & "\n" & MARKER & "\n**Role:** curator\n", CREDIT),  # order turned
      (MARKER & "\n" & unclosed & "\n**Role:** curator\n", unclosed),  # credit not whole
      (MARKER & "\n" & CREDIT & "\n" & CREDIT & "\n**Role:** curator\n", CREDIT),  # credit twice
      (MARKER & "\n" & CREDIT & "\n" & MARKER & "\n**Role:** curator\n", ""),  # marker twice
      (MARKER & " **Role:** curator\n", ""),  # marker not whole line
      ("<!-- note -->\n**Role:** curator\n", ""),  # other comment reads as before
    ]:
      check body.roleLine == opening


  test "echoed opening is cut, since body may open with whole paragraph":
    check "short".shortened == "short"
    check "é".repeat(ECHO_MAX).shortened == "é".repeat(ECHO_MAX)  # runes, never bytes
    let long = "x".repeat(ECHO_MAX + 1).shortened
    check long.runeLen == ECHO_MAX + 1 and long.endsWith("…")  # cut marked
    check checkRole("curator/mend-it", "y".repeat(200), ["curator"])[0].message.endsWith(
      "got `" & "y".repeat(ECHO_MAX) & "…`.",
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
    # No label at all is opening's own state, so message names race rather than fault.
    check unlabelled[0].message.startsWith("Pull request carries no label")
    check "`labeled` event" in unlabelled[0].message
    let wrong = checkRole("curator/mend-it", "**Role:** curator\n", ["curator/audit"])
    check wrong.len == 1  # near miss is miss
    check wrong[0].message.startsWith("Pull request must carry label")  # fault, not race
    check "`labeled` event" notin wrong[0].message


  test "branch outside grammar reports nothing, since scope already fails it":
    check checkRole("claude/setup-5uk08q", "", newSeq[string]()).len == 0
    check checkRole("main", "", newSeq[string]()).len == 0
    check checkRole("contributor/nowhere/alpha/work", "", newSeq[string]()).len ==
      0  # domain unregistered
