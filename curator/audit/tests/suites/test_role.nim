## Replicate rules CONTRIBUTOR.md sets for pull request: role line, label, title and form of body.
##   Block fixture copies form Claude Code writes today; rule reads its shapes alone, so
##     second fixture with other words holds that harness changing its words fails nothing.
##   Suite reads `textShown` through `{.all.}`, since laws of count read text it gives.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unicode, unittest]
import ../../src/[markdown, role {.all.}]
import ./fixtures


const
  MARKER = "<!-- ccr-projects-attribution: {\"github_login\":\"octocat\"} -->"
    ## Marker line of block Claude Code writes above role line, as it writes it.
  CREDIT =
    "_Requested by **Octocat** · [project thread](https://claude.ai/code/project/p?thread=t)_"
    ## Credit line of block Claude Code writes above role line, as it writes it.
  TEMPLATE_PULL = staticRead("../../../../.github/pull_request_template.md")
    ## Template of pull request body, as tree holds it.



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


  test "template of pull request holds each section of form, in order, and no carried rule (#844)":
    # Carried rule that concerns no item stands in ➖ row of sign-off, so body names none of them.
    check TEMPLATE_PULL.sections[1 .. ^1].mapIt(it.heading) == @HEADINGS_PULL
    check "carried" notin TEMPLATE_PULL.toLowerAscii


  test "body holds four sections once each, in their order, read outside fenced code (#845)":
    # Architect ruled on #845: What, Why, Evidence and Next steps, in place of five sections.
    let form = bodyPull("**Role:** curator")
    check checkBodyPull(form).len == 0
    check checkBodyPull(form.replace("\n", "\r\n")).len == 0  # edited on GitHub
    let old = "**Role:** curator\n\n## Intent\n\nX.\n\n## Scope\n\nX.\n\n## Verification\n\n" &
      "X.\n\n## Record\n\nX.\n\n## Notes\n\nX.\n"  # template before #845
    check checkBodyPull(old).mapIt(it.message) == @[
      "Pull request body holds `## What`, `## Why`, `## Evidence` and `## Next steps`, once " &
        "each and in that order; got `## Intent`, `## Scope`, `## Verification`, `## Record`, " &
        "`## Notes`.",
    ]
    let turned = form.replace("## Why", "## X").replace("## Evidence", "## Why")
      .replace("## X", "## Evidence")
    for (body, got) in [
      (form.replace("## Next steps\n\nNothing remains.\n", ""),
        "`## What`, `## Why`, `## Evidence`"),  # one missing
      (form & "\n## Why\n\nAgain.\n",
        "`## What`, `## Why`, `## Evidence`, `## Next steps`, `## Why`"),  # one twice
      (turned, "`## What`, `## Evidence`, `## Why`, `## Next steps`"),  # order turned
      ("**Role:** curator\n\nText.\n", "``"),  # none
    ]:
      check checkBodyPull(body).mapIt(it.message.endsWith("got " & got & ".")) == @[true]
    for body in [
      form.replace("The suites pass.\n", "The suites pass.\n\n```md\n## Sign-off\n```\n"),
      form.replace("Nothing remains.\n", "Nothing remains.\n\n<!--\n## Notes\n-->\n"),
      form.replace("- One point.\n", "- One point.\n\n### Detail\n\nMore.\n"),
    ]:
      check checkBodyPull(body).len == 0  # fence, comment and subheading cut no section


  test "each section opens with summary of one to three sentences, then its points (#845)":
    let form = bodyPull("**Role:** curator")
    for opening in [
      "- A point first.", "1. A numbered point.", "| a | b |", "> Quoted.",
      "```text\nOutput.\n```", "<details><summary>Output</summary>\n\nLong.\n\n</details>",
      "### Detail\n\nMore.",
    ]:
      let found = checkBodyPull(form.replace("This adds one check.", opening))
      check found.mapIt(it.message) == @[
        "Section `## What` opens with summary of one to three sentences, then its points; " &
          "got `" & opening.splitLines[0] & "`.",
      ]
    let unfilled = checkBodyPull(form.replace("This adds one check.\n\n- One point.", "<!-- -->"))
    check unfilled.len == 1 and unfilled[0].message.endsWith("got ``.")  # comment alone
    check checkBodyPull(TEMPLATE_PULL).mapIt(it.message.endsWith("got ``.")) == @[true].cycle(4)
    for summary in [
      "One. Two. Three.", "This adds one\ncheck.", "**What:** this adds one check.",
    ]:
      check checkBodyPull(form.replace("This adds one check.", summary)).len == 0
    check checkBodyPull(form.replace("This adds one check.", "One. Two. Three. Four."))
      .mapIt(it.message) == @[
        "Section `## What` opens with summary of one to three sentences, then its points; " &
          "got `4` sentences.",
      ]


  test "text shown drops comments, folds but their summaries, marks of links, footer of proxy":
    # Count reads what Architect skims while each fold is closed (#845), and marks outside code.
    for (body, shown) in [
      ("See [the gap list (#331)](https://github.com/o/r/pull/331) now.",
        "See the gap list (#331) now."),
      ("Run `[a](b)` here.", "Run `[a](b)` here."),  # link in code span shows whole
      ("A <!-- hidden --> B", "A  B"),
      ("A\n\n<!-- open to end", "A"),
      ("`<!--` opens comment.", "`<!--` opens comment."),  # mark in code span shows
      ("A\n\n<details><summary>Worked example</summary>\n\nLong output.\n\n</details>\n\nB",
        "A\n\nWorked example\n\nB"),
      ("A\n\n<DETAILS>\n\nLong.\n\n</DETAILS>\n\nB", "A\n\n\n\nB"),  # no summary, any case
      ("A\n\n<details><summary>Out</summary>\n<details><summary>In</summary>\nX\n" &
        "</details>\n</details>\nB", "A\n\nOut\nB"),  # fold inside fold
      ("A\n\n<details><summary>S</summary>\n\nLong, never closed.", "A\n\nS"),
      ("A\n\n<details open><summary>S</summary>\n\nLong.\n\n</details>\n\nB",
        "A\n\nS\n\nB"),  # cost: fold marked `open` counts as folded
      ("A\n\n</details>\n\n<details><summary>S</summary>\n\nLong.\n\n</details>\n\nB",
        "A\n\n</details>\n\nS\n\nB"),  # closing tag with no fold open closes none
      ("Write `<details>` around output.", "Write `<details>` around output."),
      ("```\n<details>\n```\nA", "```\n<details>\n```\nA"),  # tag in fenced code
      ("A\n\n---\n_Generated by [Claude Code](https://claude.ai/code/session_x)_\n", "A"),
      ("A\n\n---\n\n_Generated by [Claude Code](https://claude.ai/code/session_x)_\n",
        "A"),  # blank line between rule and footer
      ("A\n\n_Note in italics._", "A\n\n_Note in italics._"),  # no rule above it
      ("A\n\n---\nB", "A\n\n---\nB"),  # no italic line below rule
      ("A\r\nB\r\n", "A\nB"),
    ]:
      check body.textShown == shown
    const credit = "🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\n" &
      "https://claude.ai/code/session_01JwuSfA3CRBTcCGri8Ph3ND"
    check credit.textShown.runeLen == 85  # credit of harness counts, by its link text (#845)


  test "body shows at most 2500 characters while each fold is closed, link by its text (#845)":
    let
      form = bodyPull("**Role:** curator")
      full = form & "é".repeat(CHARACTERS_BODY - (form & "é").textShown.runeLen + 1)
    check full.textShown.runeLen == CHARACTERS_BODY
    check full.textShown.len > CHARACTERS_BODY  # `é` takes two bytes, so count reads characters
    check checkBodyPull(full).len == 0
    check checkBodyPull(full & "x").mapIt(it.message) == @[
      "Pull request body shows at most 2500 characters while each fold is closed, with each " &
        "link counted by its text; fold long output in `<details>`; got `2501`.",
    ]
    for body in [
      full.replace("The suites pass.", "The [suites](https://github.com/o/r/actions/runs/1) pass."),
      full.replace("\n", "\r\n"),  # edited on GitHub, as runner reads it
      full & "\n\n---\n_Generated by [Claude Code](https://claude.ai/code/session_x)_",
    ]:
      check checkBodyPull(body).len == 0  # link, line end and footer of proxy cost no room


  test "example of #845 takes form, and shows 2108 characters with each link by its text":
    # Review of #845 counts 2,046 characters outside fold, by link text; summary of fold shows
    #   too, 62 characters and its line end.
    check checkBodyPull(BODY_EXAMPLE).len == 0
    check BODY_EXAMPLE.textShown.runeLen == 2108
