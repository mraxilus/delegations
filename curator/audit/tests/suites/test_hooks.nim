## Replicate hook decisions: scope before write, bash refusals, body shape, sign-off, push.

{.experimental: "strictFuncs".}

import std/[os, osproc, sequtils, strutils, tempfiles, unittest]
import ../../src/[findings, hooks]
import ./fixtures


const
  BRANCH = "contributor/ronri/pga_benchmark/gap-list"
  ROLE = "**Role:** contributor/ronri/pga_benchmark"
  SIGNOFF = """
Done.

## Sign-off

**Role:** contributor/ronri/pga_benchmark, `gap-list`

**Context:** This branch adds the gap list. The Architect asked for baselines. #331 was a draft.

| # | State | Item | Where | Evidence, or who acts |
| --- | --- | --- | --- | --- |
| 1 | ☑️ | Names stay by the ruling (carried 3) | #320 | the Architect ruled |
| 2 | ✅ | Gap list reads each baseline | `src/gaps.nim` | `koch check` green |
| 3 | ⚠️ | `koch drive` red in rga_visualiser | #332 | contributor/ronri/rga_visualiser, fix |
| 4 | ⏸️ | Names in the tests | #310 | D1 |
| 5 | ⬜ | cga5d baseline | `tests/` | this delegate |

**Summary:** The gap list is done. Row 4 waits on D1.

**State:** blocked, at `3f2a9c1`, pushed, #331 draft

**Decisions:**

**D1.** Keep the names `rga4d` and `cga5d` in the tests?
- Class: blocks this delegate
- Where: #310
- Options:
  - a. Keep: the tests stay as they are.
  - b. Rename: twelve suites change.
- Recommends: a, because both names are the names of the authority.
- Delay costs: #331 stays a draft.

**D2.** The cga5d baseline needs 16 GB, and the runner has 7 GB.
- Class: fact
- Where: #331

**Next step:** Architect: rule on D1 in #310.
"""
  PLAIN = """
## Sign-off

**Role:** contributor/ronri/pga_benchmark, `gap-list`

**Context:** This branch adds the gap list.

| # | State | Item | Where | Evidence, or who acts |
| --- | --- | --- | --- | --- |
| 1 | ✅ | Gap list reads each baseline | `src/gaps.nim` | `koch check` green |

**Summary:** The gap list is done.

**State:** done, at `3f2a9c1`, pushed, #331 ready

**Decisions:** None.

**Next step:** Architect: merge #331.
"""


func messages(found: seq[Finding]): seq[string] =
  ## Read messages of findings.
  found.mapIt(it.message)


func citedBare(message: string): seq[string] =
  ## Read reference each finding of `checkReferencesBare` names, in order.
  checkReferencesBare(message).mapIt(it.message.split('`')[1])



suite "Hooks":
  test "role string grammar":
    check "curator".isRoleString and "curator/audit".isRoleString
    check "coordinator".isRoleString  # role with no branch
    check not "coordinator/library".isRoleString  # its own thread holds coordinator
    check "contributor/ronri/pga_benchmark".isRoleString
    check not "contributor/nowhere/x".isRoleString and not "owner".isRoleString
    check not "contributor/ronri/pga_benchmark/gap-list".isRoleString  # branch, not role


  test "path relative to root, and write outside scope refused":
    check insideRoot("/home/u/repo", "/home/u/repo/src/a.nim") == "src/a.nim"
    check insideRoot("/home/u/repo/", "/tmp/x") == "/tmp/x"
    check checkEditPath(BRANCH, "contributor/ronri/pga_benchmark/src/a.nim").len == 0
    check checkEditPath(BRANCH, "CONSTITUTION.md").len == 1  # outside project
    check checkEditPath("curator/x", "contributor/ronri/pga_benchmark/src/a.nim").len == 1
    check checkEditPath("curator/x", "contributor/ronri/pga_benchmark/GLOSSARY.md").len == 0


  test "git commands read through shell operators and options":
    check gitCommands("git -c a=b push -u origin x && echo ok") == @[@["push", "-u", "origin", "x"]]
    check gitCommands("cd x; git commit -m 'a' | cat") == @[@["commit", "-m", "'a'"]]
    check gitCommands("ls -la").len == 0


  test "bash refusals":
    check checkBash("main", "git commit -m x", false).messages[0].contains("Never commit to `main`")
    check checkBash("claude/tool-named", "git push -u origin claude/tool-named", false).len == 1
    check checkBash(BRANCH, "git push -u origin " & BRANCH, false).len == 0
    check checkBash(BRANCH, "git push --force", false).messages[0].contains("XI.2")
    check checkBash(BRANCH, "git push -f origin x", false).len == 1
    check checkBash(BRANCH, "git push --no-verify -u origin x", false).messages[0].contains(
      "duty 3",
    )  # pre-push hook skipped
    check checkBash(BRANCH, "git commit --no-verify -m x", false).len == 0  # push alone
    check checkBash(BRANCH, "git commit --amend --no-edit", true).len == 1  # pushed head
    check checkBash(BRANCH, "git commit --amend --no-edit", false).len == 0  # local head
    check checkBash(BRANCH, "git rebase origin/main", true).len == 1
    check checkBash(BRANCH, "git status", true).len == 0


  test "write without body is no post, so label-only update passes unread":
    check isPost("mcp__github__issue_write", has_body = true)
    check not isPost("mcp__github__issue_write", has_body = false)  # labels alone
    check not isPost("mcp__github__update_pull_request", has_body = false)  # draft toggle
    check not isPost("Read", has_body = true)  # not GitHub write tool


  test "body holds role line, footer, English and issue shape":
    const foot = "\n\n---\n_Generated by [Claude Code](https://claude.ai/code)_"
    let good = ROLE & "\n\nOne short claim.\n" & foot
    check checkBody("mcp__github__add_issue_comment", BRANCH, "", good, [], false).len == 0
    let coordinator = "**Role:** coordinator\n\nOne short claim.\n" & foot
    check checkBody("mcp__github__add_issue_comment", "main", "", coordinator, [], false)
      .len == 0  # no branch holds coordinator, so none is compared
    let no_role = "Hello.\n" & foot
    check checkBody("mcp__github__add_issue_comment", BRANCH, "", no_role, [], false)
      .messages[0].contains("must open with `" & ROLE & "`")
    check checkBody("mcp__github__add_issue_comment", BRANCH, "", ROLE & "\n\nText.\n", [], false)
      .messages[0].contains("footer")
    let long = ROLE & "\n\n" & "word ".repeat(26).strip & ".\n" & foot
    check checkBody("mcp__github__add_issue_comment", BRANCH, "", long, [], false)
      .messages.anyIt("25 words" in it)
    let issue = checkBody(
      "mcp__github__issue_write",
      BRANCH,
      "fix(x): do thing",
      good,
      ["bug"],
      true,
    ).messages
    check issue.anyIt("claim" in it) and issue.anyIt("role label" in it)
    check checkBody("mcp__github__issue_write", BRANCH, "A claim", good, ["curator"], true).len == 0
    check checkBody("mcp__github__issue_write", BRANCH, "Any title", good, ["curator"], false)
      .len == 0  # update reads neither title nor labels
    check checkBody("mcp__github__issue_write", BRANCH, "A claim", good, ["coordinator"], true)
      .messages.anyIt("never `coordinator`" in it)  # brief carries label of role it starts
    check checkBody(
      "mcp__github__issue_write",
      BRANCH,
      "A claim",
      good,
      ["curator", "coordinator"],
      true,
    ).messages.anyIt("never `coordinator`" in it)  # no item is coordinator's
    check checkBody(
      "mcp__github__issue_write",
      BRANCH,
      "A claim",
      good,
      ["curator", "architect"],
      true,
    ).len == 0  # queue label beside role label


  test "pull request body keeps template headings and shows change":
    const head = ROLE & "\n\n## Intent\n\nX.\n\n## Scope\n\n- a\n\n"
    let shown =
      head & "## Verification\n\n<!-- t -->\nGreen.\n\n## Record\n\n- a\n\n## Notes\n\nNone.\n"
    check checkBody("mcp__github__create_pull_request", BRANCH, "t", shown, [], true).len == 0
    let unshown = head & "## Verification\n\n<!-- t -->\n\n## Record\n\n- a\n\n## Notes\n\nNone.\n"
    check checkBody("mcp__github__create_pull_request", BRANCH, "t", unshown, [], true)
      .messages.anyIt("show change" in it)
    let missing = head & "## Verification\n\nGreen.\n\n## Notes\n\nNone.\n"
    check checkBody("mcp__github__create_pull_request", BRANCH, "t", missing, [], true)
      .messages.anyIt("`## Record`" in it)


  test "sign-off shape":
    check checkSignoff(SIGNOFF, BRANCH).len == 0
    check checkSignoff(PLAIN, BRANCH).len == 0  # no decision
    check checkSignoff("Done.\n", BRANCH).messages[0].contains("holds no")
    check checkSignoff(SIGNOFF & "\n## After\n", BRANCH)
      .messages.anyIt("Nothing follows sign-off" in it)  # heading rule, not Next step rule
    check checkSignoff(SIGNOFF.replace("**Summary:**", "**Gist:**"), BRANCH)
      .messages.anyIt("lacks `**Summary:**`" in it)
    check checkSignoff(SIGNOFF.replace("**Role:** contributor/ronri", "**Role:** curator"), BRANCH)
      .messages.anyIt("role must be" in it)
    check checkSignoff(SIGNOFF.replace("| 2 | ✅ |", "| 2 | ⬜ |"), BRANCH)
      .messages.anyIt("sort" in it)  # ⬜ before ⚠️
    check checkSignoff(SIGNOFF.replace("| `koch check` green |", "| |"), BRANCH)
      .messages.anyIt("needs evidence" in it)
    check checkSignoff(SIGNOFF.replace("| 4 | ⏸️ |", "| 6 | ⏸️ |"), BRANCH)
      .messages.anyIt("numbered" in it)
    check checkSignoff(SIGNOFF.replace("(carried 3)", "(carried 9)"), BRANCH)
      .messages.anyIt("1 to 6" in it)
    check checkSignoff(SIGNOFF & "\nTrailing.\n", BRANCH)
      .messages.anyIt("Nothing follows Next step" in it)
    check checkSignoff(SIGNOFF.replace("| 2 | ✅ |", "| 2 | 🟢 |"), BRANCH)
      .messages.anyIt("one of" in it)


  test "sign-off parts come in order Architect set":
    # Order is role, context, table, summary, state, decisions, next step (GUIDE.md).
    const context = "**Context:** This branch adds the gap list. The Architect asked for " &
      "baselines. #331 was a draft.\n\n"
    let table_first = SIGNOFF.replace(context, "").replace("**Summary:**", context & "**Summary:**")
    check checkSignoff(table_first, BRANCH)
      .messages.anyIt("| # |" in it and "in its order" in it)  # context comes before table
    const state = "**State:** blocked, at `3f2a9c1`, pushed, #331 draft\n\n"
    let state_early = SIGNOFF.replace(state, "").replace("**Context:**", state & "**Context:**")
    check checkSignoff(state_early, BRANCH)
      .messages.anyIt("lacks `**State:**` in its order" in it)  # state follows summary
    const summary = "**Summary:** The gap list is done. Row 4 waits on D1.\n\n"
    let summary_last = SIGNOFF.replace(summary, "").replace("**Next", summary & "**Next")
    check checkSignoff(summary_last, BRANCH)
      .messages.anyIt("lacks `**State:**` in its order" in it)  # summary comes before state


  test "sign-off state and decisions label":
    const state = "**State:** blocked, at `3f2a9c1`, pushed, #331 draft\n"
    check checkSignoff(SIGNOFF.replace(state, ""), BRANCH)
      .messages.anyIt("lacks `**State:**`" in it)
    check checkSignoff(SIGNOFF.replace("**State:** blocked", "**State:** stuck"), BRANCH)
      .messages.anyIt("state is one of" in it and "got `stuck`." in it)  # word, not branch
    check checkSignoff(SIGNOFF.replace("**State:** blocked,", "**State:** blocked"), BRANCH)
      .len == 0  # word ends at space too
    let unblocked = SIGNOFF.replace("- Class: blocks this delegate", "- Class: has a workaround: x")
    check checkSignoff(unblocked, BRANCH).messages.anyIt("exactly when" in it)  # blocked, no block
    check checkSignoff(unblocked.replace("**State:** blocked", "**State:** waiting"), BRANCH)
      .len == 0
    check checkSignoff(SIGNOFF.replace("**State:** blocked", "**State:** waiting"), BRANCH)
      .messages.anyIt("exactly when" in it)  # block, not blocked
    check checkSignoff(PLAIN.replace("**Decisions:** None.", "**Decisions:**"), BRANCH)
      .messages.anyIt("writes `**Decisions:** None.`" in it)
    check checkSignoff(SIGNOFF.replace("**Decisions:**\n", "**Decisions:** Two.\n"), BRANCH)
      .messages.anyIt("stands alone" in it)


  test "turn ends with sign-off once delegate stops, else with working line":
    # Sign-off only when done, blocked or waiting; working line while work runs (GUIDE.md).
    const working = "Pushed.\n\n**Working:** run 890 of `check`, whose result wakes me.\n"
    check checkEndTurn(SIGNOFF, BRANCH).len == 0
    check checkEndTurn(working, BRANCH).len == 0
    check checkEndTurn("Pushed.\n", BRANCH).messages.anyIt("got neither" in it)
    check checkEndTurn("Pushed.\n\n**Working:**\n", BRANCH)
      .messages.anyIt("got neither" in it)  # names nothing
    check checkEndTurn(working & "\nMore.\n", BRANCH)
      .messages.anyIt("got neither" in it)  # working line is last
    check checkEndTurn(SIGNOFF.replace("**Summary:**", "**Gist:**"), BRANCH)
      .messages.anyIt("lacks `**Summary:**`" in it)  # sign-off read in full
    check checkEndTurn(PLAIN.replace("**State:** done", "**State:** working"), BRANCH)
      .messages.anyIt("got `working`" in it and "**Working:**" in it)  # no state for work


  test "message names issue and pull request by link, never by bare number":
    # Short description and number, as one link (GUIDE.md, Output contract).
    const linked = "[the ledger fix (#456)](https://x/456), [#457] and " &
      "[the fixers (#441)][#441].\n\n[#457]: https://x/457\n[#441]: https://x/441\n"
    check checkNumbersBare(linked).len == 0
    check checkNumbersBare("Merged #463.\n").messages.anyIt("`#463` outside link" in it)
    check checkNumbersBare("See `#463` and\n```\n#464\n```\n").len == 0  # code
    check checkNumbersBare("``run `#463` here``\n").len == 0  # span of two backticks
    check checkNumbersBare("Undefined [#465] stays bare.\n").len == 1  # no definition
    check checkNumbersBare("&#169; and x/y#12 and a#3\n").len == 0  # reference, fragment
    check checkNumbersBare("#463 then #463 again, and #7\n").len == 2  # each number once


  test "message cites each charter reference by short description, never bare":
    # Short description and its reference, as `names read head first (V.2)` (GUIDE.md, Output
    #   contract). Each passing form stands beside bare `V.2`, so stub reporting nothing fails it
    #   as stub reporting every reference does.
    check checkReferencesBare("X.9 says so.\n").messages == @[
      "Message cites `X.9` with no description; cite each article and duty by short " &
        "description and its reference, as `expression spacing (X.9)` (GUIDE.md, Output contract).",
    ]
    check citedBare("It holds under V.2 here.\n") == @["V.2"]
    check citedBare("Then duty 3 waits.\n") == @["duty 3"]
    check citedBare("(X.9) opens the line.\n") == @["X.9"]
    check citedBare("- (X.9) opens a bullet.\n") == @["X.9"]
    check citedBare("Spacing (X.9 stays open.\n") == @["X.9"]  # no closing parenthesis
    check citedBare("Expression spacing (X.9) holds, and V.2 alone.\n") == @["V.2"]
    check citedBare("No evidence (Article VIII.1) holds, and V.2 alone.\n") == @["V.2"]
    check citedBare("Both hold here (X.2, X.9), and V.2 alone.\n") == @["V.2"]  # one parenthesis
    check citedBare("A check that reddens a project (duty 3), and V.2 alone.\n") == @["V.2"]
    check citedBare("See `X.9`, and V.2 alone.\n") == @["V.2"]  # code span
    check citedBare("```\nX.9 and duty 3\n```\nV.2 alone.\n") == @["V.2"]  # fenced code
    check citedBare("[X.9](https://x/9) and [IV.4], and V.2 alone.\n\n[IV.4]: https://x/4\n") ==
      @["V.2"]  # inline link, and shortcut link message defines
    check citedBare("Nim 2.2.12, D1, D2, §5, MIX.3, IX.2.1 and a/V.2, and V.2 alone.\n") ==
      @["V.2"]  # version, decision, section, longer token
    check citedBare("X.9 then X.9 again, Duty 3 and duty 3.\n") == @["X.9", "Duty 3"]  # once


  test "sign-off decision is card coordinator lifts unchanged":
    check checkSignoff(SIGNOFF.replace("**D2.**", "**D3.**"), BRANCH)
      .messages.anyIt("numbered from D1" in it)
    check checkSignoff(SIGNOFF.replace("- Class: fact\n", ""), BRANCH)
      .messages.anyIt("lacks `Class:`" in it)
    check checkSignoff(SIGNOFF.replace("- Where: #310\n", ""), BRANCH)
      .messages.anyIt("lacks `Where:`" in it)
    check checkSignoff(SIGNOFF.replace("- Class: fact", "- Class: urgent"), BRANCH)
      .messages.anyIt("Class is" in it)
    const others = "- Class: blocks this delegate and "
    check checkSignoff(
      SIGNOFF.replace("- Class: blocks this delegate", others & "the visualiser"),
      BRANCH,
    ).messages.anyIt("role string; got `the visualiser`" in it)
    check checkSignoff(
      SIGNOFF.replace("- Class: blocks this delegate", others & "curator, curator/audit"),
      BRANCH,
    ).len == 0


  test "sign-off decision offers two to four short options and picks one":
    check checkSignoff(SIGNOFF.replace("  - b. Rename: twelve suites change.\n", ""), BRANCH)
      .messages.anyIt("offers 2 to 4 options; got `1`" in it)
    const more = "  - c. Drop: x.\n  - d. Wait: x.\n  - e. Ask: x.\n- Recommends:"
    check checkSignoff(SIGNOFF.replace("- Recommends:", more), BRANCH)
      .messages.anyIt("offers 2 to 4 options; got `5`" in it)
    check checkSignoff(SIGNOFF.replace("a. Keep:", "a. Keep both names here:"), BRANCH)
      .messages.anyIt("at most 3 words" in it)
    check checkSignoff(SIGNOFF.replace("a. Keep:", "a. Keep the tests."), BRANCH)
      .messages.anyIt("`<letter>. <label>: <consequence>`" in it)  # no colon closes label
    check checkSignoff(SIGNOFF.replace("- Recommends: a,", "- Recommends: c,"), BRANCH)
      .messages.anyIt("Recommends names letter" in it)
    check checkSignoff(SIGNOFF.replace("- Recommends: a,", "- Recommends: a. Keep,"), BRANCH)
      .len == 0  # letter closed by period
    check checkSignoff(SIGNOFF.replace("- Recommends: a, because", "- Because"), BRANCH)
      .messages.anyIt("lacks `Recommends:`" in it)
    check checkSignoff(SIGNOFF.replace("in the tests?", "in the tests."), BRANCH)
      .messages.anyIt("ends with `?`" in it)
    let asks = SIGNOFF.replace("- Where: #331\n", "- Where: #331\n- Options:\n  - a. Buy: x.\n")
    check checkSignoff(asks, BRANCH).messages.anyIt("offers no option" in it)  # fact asks nothing
    let picks = SIGNOFF.replace("- Where: #331\n", "- Where: #331\n- Recommends: a\n")
    check checkSignoff(picks, BRANCH).messages.anyIt("picks no option" in it)


  test "sign-off rows name who acts":
    check checkSignoff(SIGNOFF.replace("| #310 | D1 |", "| #310 | the Architect rules |"), BRANCH)
      .messages.anyIt("names decision it waits on" in it)
    check checkSignoff(SIGNOFF.replace("| #310 | D1 |", "| #310 | D3 |"), BRANCH)
      .messages.anyIt("names decision it waits on" in it)  # no such decision
    check checkSignoff(SIGNOFF.replace("contributor/ronri/rga_visualiser, fix", "they fix"), BRANCH)
      .messages.anyIt("opens last cell with role string" in it)
    check checkSignoff(
      SIGNOFF.replace("contributor/ronri/rga_visualiser, fix", "outside, GitHub fixes runner"),
      BRANCH,
    ).len == 0


  test "push and commit message":
    check checkPush("abc\n", "abc").len == 0
    check checkPush("abc", "def").messages[0].contains("exact commit")
    check markPath("/repo", ".git") == "/repo/.git/koch-check"
    check markPath("/repo/wt", "/repo/.git/worktrees/wt") ==
      "/repo/.git/worktrees/wt/koch-check"  # worktree's own dir, where `.git` is file
    check checkMessage(BRANCH, "feat(pga_benchmark): add gaps\n\nBody.\n", [], []).len == 0
    check checkMessage(BRANCH, "Add gaps", [], []).len == 1  # not conventional
    check checkMessage(BRANCH, "Merge branch 'main' into " & BRANCH, [], []).len == 0  # git's own
    check checkMessage(
      BRANCH, "# comment\nfix(pga_benchmark): x", ["feat(pga_benchmark): y"], []
    ).len == 1  # fix without test before it
    # Body and staged paths reach commit check too, so hook says before commit lands.
    let wrapped = "feat(pga_benchmark): add gaps\n\nGaps read baseline of each\nalgebra.\n"
    check checkMessage(BRANCH, wrapped, [], []).messages.anyIt("runs on" in it)
    let staged =
      ["contributor/ronri/pga_benchmark/PROVENANCE.md", "contributor/ronri/pga_benchmark/a.nim"]
    check checkMessage(BRANCH, "docs(pga_benchmark): record gaps", [], staged).len == 1
    # Comment lines and everything below scissors are git's, never body.
    let verbose =
      "feat(pga_benchmark): add gaps\n# Please enter.\n# ------------------------ >8\ndiff x\n"
    check checkMessage(BRANCH, verbose, [], []).len == 0


  test "subject is first paragraph, as git reads it, and earlier subjects stay with check-commits":
    # Git joins lines before first blank line into subject, so line under subject is subject too.
    let joined = "feat(pga_benchmark): add gaps\nGaps read baseline of each algebra.\n"
    check checkMessage(BRANCH, joined, [], []).messages.anyIt("add gaps Gaps read" in it)
    # `--amend` runs hook while old head is still among earlier subjects.
    check checkMessage(BRANCH, "feat(pga_benchmark): add gaps\n", ["Old bad subject."], []).len == 0
    # Same bad subject written again is still new finding: one earlier copy cancels one.
    check checkMessage(BRANCH, "Old bad subject.\n", ["Old bad subject."], []).len > 0


  test "git command reads checkout it acts in, so worktree holds its own branch":
    check commandDirectory("git commit -m x", "/work/tree") == "/work/tree"
    check commandDirectory("git -C /other commit", "/work/tree") == "/other"
    check commandDirectory("git -C sub commit", "/work/tree") == "/work/tree/sub"
    check commandDirectory("cd /other && git push", "/work/tree") == "/other"
    check commandDirectory("cd \"sub\" && git -C deeper push", "/work") == "/work/sub/deeper"
    check commandDirectory("ls && git status", "/work") == "/work"


  test "gh api write reads as tool whose rules it shares":
    # Each endpoint of map, with method; owner and repo as placeholder or variable pass too.
    const writes = [
      ("repos/o/r/issues/7/comments", "POST", "add_issue_comment"),
      ("repos/o/r/issues -f title=T", "POST", "issue_write"),
      ("-X PATCH repos/o/r/issues/7", "PATCH", "issue_write"),
      ("--method patch /repos/{owner}/{repo}/issues/comments/9", "PATCH", "update_issue_comment"),
      ("repos/$REPO/pulls -f head=h -f base=main", "POST", "create_pull_request"),
      ("-XPATCH repos/o/r/pulls/7", "PATCH", "update_pull_request"),
      ("repos/o/r/pulls/7/reviews -f event=COMMENT", "POST", "pull_request_review_write"),
      ("repos/o/r/pulls/7/comments", "POST", "add_comment_to_pending_review"),
      ("repos/o/r/pulls/7/comments/9/replies", "POST", "add_reply_to_pull_request_comment"),
      ("--method=PATCH repos/o/r/pulls/comments/9", "PATCH", "add_reply_to_pull_request_comment"),
    ]
    for (arguments, action, tool) in writes:
      let read = requests("gh api " & arguments & " -F body=@x.md", "/w")
      check read.len == 1 and read[0].action == action and read[0].tool == "mcp__github__" & tool
      check read[0].isPost and read[0].path == "/w/x.md" and read[0].is_create == (action == "POST")
    const issue = "gh api repos/o/r/issues -f title='A claim' -f 'labels[]=curator' -f body=x " &
      "-f labels[]=architect"
    check requests(issue, "")[0].title == "A claim"
    check requests(issue, "")[0].labels == @["curator", "architect"]


  test "gh api body reads whole, from text, file or input":
    const post = "gh api repos/o/r/issues/7/comments "
    let quoted = requests(post & "-f body='One claim.\n\nTwo.' | cat", "")
    check quoted.len == 1 and quoted[0].body == "One claim.\n\nTwo."  # quotes span newline
    check requests(post & "-f \"body=Say \\\"so\\\" now.\"", "")[0].body == "Say \"so\" now."
    let code = requests(post & "-f body='Run `koch check`; $5.'", "")[0]
    check code.body == "Run `koch check`; $5." and code.expansion.len == 0  # single quotes
    check requests(post & "-f body=\"$(cat x.md)\"", "")[0]
      .expansion == "body=$(cat x.md)"  # shell expands it after hook reads
    check requests(post & "-f body=@x.md", "/w")[0].body == "@x.md"  # `-f` reads no file
    let input = requests("gh api -X PATCH repos/o/r/issues/7 --input body.json", "/w")[0]
    check input.path == "/w/body.json" and input.is_input and input.isPost
    check requests("gh api repos/o/r/issues --input=/t/i.json", "/w")[0].path == "/t/i.json"
    let heredoc = "cat > x.md <<'EOF'\nIt doesn't.\n" & post & "-f body=x\nEOF\n" & post &
      "-F body=@x.md"
    check requests(heredoc, "/w").mapIt(it.path) == @["/w/x.md"]  # heredoc text is no command


  test "gh api write with no body, read, or other endpoint is no post":
    let labels = requests("gh api repos/o/r/issues/7/labels -f 'labels[]=curator'", "")[0]
    check labels.action == "POST" and labels.tool == "" and not labels.isPost
    let draft = requests("gh api -X PATCH repos/o/r/pulls/7 -F draft=true", "")[0]
    check draft.tool == "mcp__github__update_pull_request" and not draft.isPost  # no body
    let read = requests("gh api repos/o/r/issues/7/comments --jq '.[].body'", "")[0]
    check read.action == "GET" and read.tool == "" and not read.isPost
    let ready = requests("gh api -X POST ccr/ready_for_review -f repo=o/r -F pull_number=7", "")[0]
    check ready.tool == "" and not ready.isPost


  test "gh api file resolves against directory command acts in":
    const post = "gh api repos/o/r/issues/7/comments -F body=@y.md"
    check requests("cd x && " & post, "/w")[0].path == "/w/x/y.md"
    check requests("cd /a; cd b\n" & post, "/w")[0].path == "/a/b/y.md"
    check requests(post & " && cd z", "/w")[0].path == "/w/y.md"  # later `cd` moves nothing
    check requests("cd \"$W\" && " & post, "/w")[0].path == "/w/$W/y.md"


  test "gh api body hook cannot read is refused with its mend":
    # Hook runs before command: shell variable, stdin and file command writes are unread.
    const post = "gh api repos/o/r/issues/7/comments "
    check checkPosts(BRANCH, post & "-F body=@$DIR/x.md", "/w").messages == @[
      "Hook reads `gh api` post before command runs, so body from shell variable or stdin is " &
        "unread; name file by literal path; got `/w/$DIR/x.md`.",
    ]
    check checkPosts(BRANCH, post & "-F body=@`pwd`/x.md", "/w")
      .messages.anyIt("literal path" in it)  # backtick
    check checkPosts(BRANCH, post & "-F body=@- <<'EOF'\nText.\nEOF", "/w")
      .messages.anyIt("literal path; got `-`" in it)  # stdin
    check checkPosts(BRANCH, "cd \"$W\" && " & post & "-F body=@x.md", "/w")
      .messages.anyIt("literal path" in it)  # directory unknown
    check checkPosts(BRANCH, post & "--input -", "/w").messages.anyIt("literal path" in it)
    check checkPosts(BRANCH, post & "-f body=\"$(cat x.md)\"", "/w")
      .messages.anyIt("before shell expands it" in it)
    let directory = createTempDir("delegations_", "_posts")
    defer: removeDir(directory)
    let missing = directory / "absent.md"
    check checkPosts(BRANCH, post & "-F body=@" & missing, "/w").messages == @[
      "Hook reads `gh api` post before command runs, so it cannot read file command itself " &
        "writes; write file in earlier call; got missing `" & missing & "`.",
    ]
    check checkPosts(BRANCH, "gh api repos/o/r/issues/7/labels -f 'labels[]=$L'", "/w").len == 0


  test "gh api body is held as tool's body, read from file it names":
    # Real files, read as `bash` hook reads them before command runs (Article IX.5).
    const foot = "\n\n---\n_Generated by [Claude Code](https://claude.ai/code)_\n"
    let directory = createTempDir("delegations_", "_posts")
    defer: removeDir(directory)
    directory.writeInto("long.md", ROLE & "\n\n" & "word ".repeat(26) & "end.\n" & foot)
    directory.writeInto("short.md", ROLE & "\n\nOne short claim.\n" & foot)
    const post = "gh api repos/o/r/issues/7/comments -F body=@"
    check checkPosts(BRANCH, post & "long.md", directory).messages.anyIt("25 words" in it)
    check checkPosts(BRANCH, post & "short.md", directory).len == 0
    check checkPosts(BRANCH, "cd " & directory & " && " & post & "long.md", "/").len > 0
    check checkPosts(BRANCH, "gh api repos/o/r/issues/7/comments -f body='Hello.'", directory)
      .messages.anyIt("must open with" in it)  # inline body
    directory.writeInto("issue.json", """{"title": "fix(x): do", "labels": ["bug"], "body": "x"}""")
    let issue = checkPosts(BRANCH, "gh api repos/o/r/issues --input issue.json", directory).messages
    check issue.anyIt("claim" in it) and issue.anyIt("role label" in it)
    directory.writeInto("labels.json", "{\"labels\": [\"curator\"]}")
    check checkPosts(BRANCH, "gh api -X PATCH repos/o/r/issues/7 --input labels.json", directory)
      .len == 0  # no body, so no post
    directory.writeInto("broken.json", "{")
    check checkPosts(BRANCH, "gh api -X PATCH repos/o/r/issues/7 --input broken.json", directory)
      .messages.anyIt("JSON object" in it)


  test "start context and turn writes":
    let text = startContext(BRANCH, "## List\n\n1. one\n\n## Next\n", "## List", @[])
    check "Role: contributor/ronri/pga_benchmark" in text and "CONTRIBUTOR.md" in text
    check "1. one" in text and "## Sign-off" in text and "**Working:**" in text
    check "outside grammar" in startContext("claude/x", "", "## List", @[])
    check "re-stamp" in startContext("curator/x", "", "## List", @[finding("", 0, "d")])
    check isTurnWriting([Call(name: "Bash", command: "git push -u origin x")])
    check isTurnWriting([Call(name: "mcp__github__issue_write", has_body: true)])
    check not isTurnWriting([Call(name: "mcp__github__update_pull_request")])  # draft toggle
    check not isTurnWriting([Call(name: "Bash", command: "git status"), Call(name: "Read")])
    const issue = "gh api repos/o/r/issues/7/"
    check isTurnWriting([Call(name: "Bash", command: issue & "comments -F body=@x.md")])  # post
    check not isTurnWriting([Call(name: "Bash", command: issue & "labels -f 'labels[]=curator'")])


  test "transcript parse finds calls since last message of person":
    const transcript =
      "{\"type\":\"user\",\"message\":{\"content\":[{\"type\":\"text\",\"text\":\"do it\"}]}}\n" &
      "{\"type\":\"assistant\",\"message\":{\"content\":[{\"type\":\"tool_use\"," &
      "\"name\":\"Bash\",\"input\":{\"command\":\"git push\"}}]}}\n" &
      "{\"type\":\"user\",\"message\":{\"content\":[{\"type\":\"tool_result\"," &
      "\"content\":\"ok\"}]}}\n" &
      "{\"type\":\"assistant\",\"message\":{\"content\":[{\"type\":\"text\"," &
      "\"text\":\"Done.\\n\\n## Sign-off\"}]}}\n"
    let turn = transcript.parseTurn
    check turn.calls.len == 1 and turn.calls[0].command == "git push"
    check turn.text.startsWith("Done.")
    check turn.calls.isTurnWriting


  test "hook binary is built again where source at HEAD moves, and only there":
    # Stub compiler writes binary printing `koch.nim` it read, so output names source of binary
    #   hook ran; real git and real `sh` run hook file itself (Article IX.5).
    proc runHook(root, toolchain, event: string): string =
      ## Run hook file of root for event, with stub compiler of toolchain first on `PATH`.
      let command = "KNOLLER_NIM_DIR=" & toolchain.quoteShell & " LOG_BUILDS=" &
        (toolchain / "builds.log").quoteShell & " CLAUDE_ENV_FILE= sh " &
        (root / ".claude" / "hooks.sh").quoteShell & " " & event
      execCmdEx(command).output.strip

    const
      script_hooks = staticRead("../../../../.claude/hooks.sh")
      stub_nim = "#!/bin/sh\n" &
        "echo \"$*\" >> \"$LOG_BUILDS\"\n" &
        "for a in \"$@\"; do case \"$a\" in -o:*) out=\"${a#-o:}\" ;; esac; done\n" &
        "[ -n \"${out:-}\" ] || exit 1\n" &
        "mkdir -p \"$(dirname \"$out\")\"\n" &
        "printf '#!/bin/sh\\necho \"built from %s\"\\n' \"$(cat koch.nim)\" > \"$out\"\n" &
        "chmod +x \"$out\"\n"
    let
      root = tempRepo()
      toolchain = createTempDir("delegations_", "_nim")
    defer: removeDir(root)
    defer: removeDir(toolchain)
    toolchain.writeInto("0.0.1/bin/nim", stub_nim)
    inclFilePermissions(toolchain / "0.0.1" / "bin" / "nim", {fpUserExec})
    root.writeInto(".claude/hooks.sh", script_hooks)
    root.writeInto("curator/audit/audit.nimble", "requires \"nim == 0.0.1\"\n")
    root.writeInto("curator/audit/src/checks.nim", "discard\n")
    root.writeInto("koch.nim.cfg", "")
    root.writeInto("koch.nim", "a")
    discard root.git("add -A")
    discard root.git("commit -q -m 'chore(curator): source a'")
    check runHook(root, toolchain, "start") == "built from a"  # start builds

    # Commit and switch of branch move source at HEAD; edit in progress does not.
    root.writeInto("koch.nim", "b")
    discard root.git("commit -q -am 'chore(curator): source b'")
    check runHook(root, toolchain, "path") == "built from b"  # commit moved source
    let builds = readFile(toolchain / "builds.log").countLines
    check runHook(root, toolchain, "path") == "built from b"
    check readFile(toolchain / "builds.log").countLines == builds  # same HEAD, no build
    root.writeInto("koch.nim", "c")
    check runHook(root, toolchain, "path") == "built from b"  # edit in progress
    check readFile(toolchain / "builds.log").countLines == builds
    discard root.git("checkout -q -- koch.nim")
    discard root.git("checkout -q -b old HEAD~1")
    check runHook(root, toolchain, "path") == "built from a"  # switch of branch

    # Knoller, which checker imports by path, moves key as checker source does. Source alone,
    #   without nimble file, holds order of key's paths too (`hooks.sh`, Trap).
    discard root.git("checkout -q -")
    check runHook(root, toolchain, "path") == "built from b"
    let built = readFile(toolchain / "builds.log").countLines
    root.writeInto("curator/knoller/src/knoller.nim", "discard\n")
    discard root.git("add -A")
    discard root.git("commit -q -m 'chore(curator): source of knoller'")
    check runHook(root, toolchain, "path") == "built from b"
    check readFile(toolchain / "builds.log").countLines == built + 1  # knoller source moved key
