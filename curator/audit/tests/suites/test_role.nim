## Replicate role rule of CONTRIBUTOR.md, Say which role you are, over pull request bodies.
##   Block fixture copies form Claude Code writes today; rule reads its shapes alone, so
##     second fixture with other words holds that harness changing its words fails nothing.

{.experimental: "strictFuncs".}

import std/[strutils, unicode, unittest]
import ../../src/[checker, markdown, role]


const
  MARKER = "<!-- ccr-projects-attribution: {\"github_login\":\"octocat\"} -->"
    ## Marker line of block Claude Code writes above role line, as it writes it.
  CREDIT =
    "_Requested by **Octocat** · [project thread](https://claude.ai/code/project/p?thread=t)_"
    ## Credit line of block Claude Code writes above role line, as it writes it.



suite "Role":
  test "role line is first non-blank line, without its trailing comment":
    check "**Role:** curator\n\n## Intent\n".lineRole == "**Role:** curator"
    check "\n\n**Role:** curator\n".lineRole == "**Role:** curator"  # blank lines skipped
    check "  **Role:** curator  \n".lineRole == "**Role:** curator"  # surrounding space
    check "**Role:** <!-- curator, or contributor -->\n".lineRole ==
      "**Role:**"  # unfilled template keeps key alone
    check "**Role:** curator <!-- copied -->\n".lineRole == "**Role:** curator"
    check "".lineRole == ""
    check "\n \n".lineRole == ""


  test "body below block of listed harness reads as body alone, so thread's pull request passes":
    for attribution in [MARKER & "\n" & CREDIT & "\n", MARKER & "\n\n" & CREDIT & "\n\n"]:
      for body in [
        "**Role:** curator\n\n## Intent\n", "**Role:** curator <!-- copied -->\n",
        "**Role:** <!-- curator, or contributor -->\n", "## Intent\n", "",
      ]:
        let attributed = attribution & body
        check attributed.lineRole == body.lineRole
        check attributed.replace("\n", "\r\n").lineRole == body.lineRole  # edited on GitHub
    let thread = MARKER & "\n" & CREDIT & "\n\n**Role:** curator\n\n## Intent\n"
    check checkRole("curator/mend-it", thread, ["curator"]).len == 0
    let wrong = checkRole(
      "curator/mend-it",
      MARKER & "\n" & CREDIT & "\n**Role:** curator/probe\n",
      ["curator"],
    )
    check wrong.len == 1
    check wrong[0].message.endsWith("got `**Role:** curator/probe`.")  # line below block echoed


  test "block of listed harness is passed only whole, once and in order":
    let unclosed = CREDIT[0 ..^ 2]  # italic never closed
    for (body, opening) in [
      (MARKER & "\n**Role:** curator\n", ""),  # marker alone, credit left out
      (CREDIT & "\n**Role:** curator\n", CREDIT),  # credit with no marker
      (CREDIT & "\n" & MARKER & "\n**Role:** curator\n", CREDIT),  # order turned
      (MARKER & "\n" & unclosed & "\n**Role:** curator\n", ""),  # credit not whole
      (MARKER & "\n" & CREDIT & "\n" & CREDIT & "\n**Role:** curator\n", CREDIT),  # credit twice
      (MARKER & "\n" & CREDIT & "\n" & MARKER & "\n**Role:** curator\n", ""),  # marker twice
      (MARKER & " **Role:** curator\n", ""),  # marker not whole line
      ("<!-- note -->\n**Role:** curator\n", ""),  # comment alone is no block
    ]:
      check body.lineRole == opening


  test "block is known by shape of each line, never by words of harness (#845)":
    # Architect ruled on #845: entry of each harness lists shapes of its lines. Claude Code writes
    #   one line of HTML comment, then one italic line, so other words in that shape pass.
    for (marker, credit) in [
      (MARKER, CREDIT),  # as harness writes them today
      ("<!-- marker of any harness -->", "_Credit in any words_"),  # words changed
      ("<!---->", "__"),  # each shape at its shortest
    ]:
      let body = marker & "\n" & credit & "\n\n**Role:** curator\n"
      check body.lineRole == "**Role:** curator"
      check body.replace("\n", "\r\n").lineRole == "**Role:** curator"  # edited on GitHub
      check checkRole("curator/mend-it", body, ["curator"]).len == 0
    for body in [
      "<!-- marker -->\n*Credit*\n**Role:** curator\n",  # italic by asterisks
      "<!-- marker\n-->\n_Credit_\n**Role:** curator\n",  # comment over two lines
      "<!-- marker -->\n_\n**Role:** curator\n",  # one mark opens and closes nothing
    ]:
      check body.lineRole == ""  # first line, its comment dropped
      check checkRole("curator/mend-it", body, ["curator"]).len == 1


  test "finding quotes each line above role line that no listed harness writes (#845)":
    # Harness writing block `role.nim` does not list fails on its first pull request, and
    #   finding quotes block, so curator adds its entry.
    let lone = checkRole("curator/mend-it", "<!-- note -->\n**Role:** curator\n", ["curator"])
    check lone.len == 1
    check lone[0].message.endsWith("got `<!-- note -->` above `**Role:** curator`.")
    let stray = MARKER & "\n" & CREDIT & "\nStray line.\n\n**Role:** curator\n"
    check checkRole("curator/mend-it", stray, ["curator"])[0].message.endsWith(
      "got `" & MARKER.shortened & "`, `" & CREDIT.shortened & "`, `Stray line.` above " &
        "`**Role:** curator`.",
    )  # whole block quoted, each line cut
    var many = ""
    for i in 0 .. LINES_QUOTED: many.add "line " & $i & "\n"
    let quoted = checkRole("curator/mend-it", many & "**Role:** curator\n", ["curator"])
    check quoted[0].message.endsWith(
      "`line " & $(LINES_QUOTED - 1) & "`, … above `**Role:** curator`.",
    )
    check "`line " & $LINES_QUOTED & "`" notin quoted[0].message  # quote cut at bound
    let fenced = checkRole("curator/mend-it", "## What\n\n```md\n**Role:** curator\n```\n", [])
    check fenced[0].message.endsWith("got `## What`.")  # role line in fence is example only


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


  test "label must be present, beside any other, and finding names job that adds it":
    check checkRole(
      "curator/mend-it", "**Role:** curator\n", ["curator", "contributor/ronri/alpha"]
    ).len == 0  # label joins when work hands across
    # Job `label` adds label before `check-role` reads list (#845), so empty list is fault too.
    for labels in [newSeq[string](), @["curator/audit"]]:  # none, and near miss
      let found = checkRole("curator/mend-it", "**Role:** curator\n", labels)
      check found.len == 1
      check found[0].message == "Pull request must carry label `curator`, which job `label` of " &
        "`role.yml` adds from its branch; got `" & labels.join(", ") & "`."


  test "branch outside grammar reports nothing, since scope already fails it":
    check checkRole("claude/setup-5uk08q", "", newSeq[string]()).len == 0
    check checkRole("main", "", newSeq[string]()).len == 0
    check checkRole("contributor/nowhere/alpha/work", "", newSeq[string]()).len ==
      0  # domain unregistered


  test "title holds grammar, scope and width of commit subject":
    # Merge commit takes title as subject, and `main` takes no rewrite after (#463).
    check checkTitle("curator/mend-it", "docs(curator): order the sign-off").len == 0
    check checkTitle("curator/mend-it", "fix(pga_visualiser): mend it").len == 0  # any scope
    let charter = checkTitle("curator/mend-it", "Charter: label architect, linked names")
    check charter.len == 1
    check charter[0].message.startsWith("Pull request title must match")
    check checkTitle("curator/mend-it", "docs(curator): order it.").len == 1  # final period
    check checkTitle("curator/mend-it", "docs(curator): Order it").len == 1  # capital summary
    let scoped = checkTitle("contributor/ronri/pga_visualiser/x", "feat(pga_benchmark): add it")
    check scoped.len == 1
    check scoped[0].message.startsWith("Pull request title scope must be `pga_visualiser`")
    check checkTitle("curator/audit/x", "feat(curator): add it").len == 1  # project branch
    let wide = checkTitle("curator/mend-it", "docs(curator): " & "a".repeat(90))
    check wide.len == 1 and wide[0].message.startsWith("Pull request title exceeds 100")
    check checkTitle("claude/setup-5uk08q", "Anything at all").len == 0  # scope fails it


  test "template of pull request holds each heading body hook asks for, and no carried rule (#844)":
    # Carried rule that concerns no item stands in ➖ row of sign-off, so body names none of them.
    const template_pull = staticRead("../../../../.github/pull_request_template.md")
    for heading in HEADINGS_PULL:
      check heading in template_pull.linesHeading
    check "carried" notin template_pull.section("## Record").toLowerAscii
