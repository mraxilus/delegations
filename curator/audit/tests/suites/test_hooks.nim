## Replicate hook decisions: scope before write, bash refusals, body shape, sign-off, push.

{.experimental: "strictFuncs".}

import std/[json, options, os, osproc, sequtils, strutils, tempfiles, unittest]
import ../../src/[findings, hooks, lags, tree]
import ./fixtures


const
  BRANCH = "contributor/ronri/pga_benchmark/gap-list"
  ROLE = "**Role:** contributor/ronri/pga_benchmark"
  SIGNOFF = """
Done.

## Sign-off

**Role:** contributor/ronri/pga_benchmark, branch `gap-list`

**Context:** This branch adds the gap list. The Architect asked for baselines. #331 was a draft.

---

**[The gap list (#331)](https://github.com/mraxilus/delegations/pull/331), draft, run 412 green.**
The gap list reads the baseline of each algebra.

| Item | Evidence, or who acts |
| --- | --- |
| ☑️ 1. Draft since it opened, another commit intended | carried 3, #331 draft |
| ✅ 2. Gap list reads each baseline | `koch check` green |
| ✅ 3. A worked example shows the gap rows | carried 5, in the pull request body |
| ⏸️ 4. Names in the tests | carried 6, D1 |
| ⬜ 5. cga5d baseline | this delegate |

**Outside a pull request.**

| Item | Evidence, or who acts |
| --- | --- |
| ☑️ 6. The answered issue is closed | carried 1, #320 |
| ✅ 7. The request of the curator is answered | carried 2, #330 |
| ⚠️ 8. `koch drive` red in pga_visualiser | contributor/ronri/pga_visualiser, fix on #332 |
| ➖ 9. Not needed: page link | carried 4: no page changed |

**Summary:** The gap list is done. Row 4 waits on D1.

**State:** blocked, at `3f2a9c1`, pushed

**Decisions:**

**D1.** Keep the names `rga4d` and `cga5d` in the tests?
- Class: blocks this delegate
- Where: #310
- Options:
  - **a. Keep:** the tests stay as they are.
  - **b. Rename:** twelve suites change.
- Recommends: **a**, because both names are the names of the authority.
- Delay costs: #331 stays a draft.

**D2.** The cga5d baseline needs 16 GB, and the runner has 7 GB.
- Class: fact
- Where: #331

**Next step:** Architect: rule on D1 in #310.
"""
  PLAIN = """
## Sign-off

**Role:** contributor/ronri/pga_benchmark, branch `gap-list`

**Context:** This branch adds the gap list.

---

**[The gap list (#331)](https://github.com/mraxilus/delegations/pull/331), ready, run 412 green.**
The gap list reads the baseline of each algebra.

| Item | Evidence, or who acts |
| --- | --- |
| ✅ 1. Gap list reads each baseline | `koch check` green |
| ✅ 2. Ready, and no commit intended | carried 3, run 412 green |
| ✅ 3. A worked example shows the gap rows | carried 5, in the pull request body |

**Outside a pull request.**

| Item | Evidence, or who acts |
| --- | --- |
| ➖ 4. Not needed: issues, requests, page link, terms | carried 1, 2, 4 and 6: none arose |

**Summary:** The gap list is done.

**State:** done, at `3f2a9c1`, pushed

**Decisions:** None.

**Next step:** Architect: merge #331.
"""
  FIVE = """
## Sign-off

**Role:** contributor/ronri/pga_benchmark, `contributor/ronri/pga_benchmark/gap-list`

**Context:** This branch adds the gap list.

| # | State | Item | Where | Evidence, or who acts |
| --- | --- | --- | --- | --- |
| 1 | ☑️ | Names stay by the ruling (carried 3) | #320 | the Architect ruled |
| 2 | ✅ | Gap list reads each baseline | `src/gaps.nim` | `koch check` green |

**Summary:** The gap list is done.

**State:** done, at `3f2a9c1`, pushed, #331 ready, run 412 green

**Decisions:** None.

**Next step:** Architect: merge #331.
"""
    ## Sign-off in form of `GUIDE.md` before #844: one table of five columns, which phone cuts.
  KINDS = ["builder", "critic", "resolver", "reviewer"]
    ## Kinds of subagent templates name, as `readKinds` reads them.
  PREDICTION = """
## Prediction

**Subagent:** builder of the block check, fresh context.
**Basis:** what this delegate knows, with no new read.

- Judgement: the race to save one shared key leads the findings (70%).
- Work: four to eight findings, each with `file:line` (60%).

**Working:** a timer of 5 seconds wakes this delegate, and the next turn starts the builder.
"""
    ## Block that predicts subagent, as last message of turn of its own (6980006567).
  REFLECTION = """
## Reflection

**Subagent:** builder of the block check, 160,000 tokens and $2.10 at list price, 57 calls.
**Critic:** 50,000 tokens and $0.70, 20 calls, 6 min.

| State | Confidence | Predicted | Result |
| --- | --- | --- | --- |
| ✅ | 70% | the race to save one shared key leads the findings | it leads, as high |
| ⬜ | 60% | four to eight findings, each with `file:line` | three, at `hooks.nim:12` |

- **Cause of each miss:** the diff was smaller than the delegate read.
"""
    ## Block that answers report of critic, each cell under `Predicted` quoting `PREDICTION`.


func messages(found: seq[Finding]): seq[string] =
  ## Read messages of findings.
  found.mapIt(it.message)


func closing(text: string): seq[string] =
  ## Read messages `checkBody` gives issue body holding text after role line, which closing
  ##   keyword binds as it binds pull request body, and no form of template binds.
  checkBody("mcp__github__issue_write", BRANCH, "", ROLE & "\n\n" & text & "\n", [], false)
    .messages


func citedBare(message: string): seq[string] =
  ## Read reference each finding of `checkReferencesBare` names, in order.
  checkReferencesBare(message).mapIt(it.message.split('`')[1])


func lineUser(text: string, kind = ""): string =
  ## Write transcript line of user entry holding text, from origin of kind where one is given.
  let entry =
    if kind.len == 0: %*{"type": "user", "message": {"content": text}}
    else: %*{"type": "user", "origin": {"kind": kind}, "message": {"content": text}}
  $entry & "\n"


func lineAssistant(text: string): string =
  ## Write transcript line of assistant entry holding text.
  $(%*{"type": "assistant", "message": {"content": [{"type": "text", "text": text}]}}) & "\n"


func linesCall(command: string): string =
  ## Write transcript lines of Bash call and its result, which arrives as user entry.
  let
    call = %*{"type": "assistant", "message": {"content": [
      {"type": "tool_use", "name": "Bash", "input": {"command": command}},
    ]}}
    answer = %*{"type": "user", "message": {"content": [{"type": "tool_result", "content": "ok"}]}}
  $call & "\n" & $answer & "\n"


func lineSaid(text: string, reason = "end_turn"): string =
  ## Write transcript line of assistant entry holding text, whose message stops for reason.
  $(%*{"type": "assistant", "message": {
    "content": [{"type": "text", "text": text}], "stop_reason": reason,
  }}) & "\n"


func lineThought(kind = "thinking"): string =
  ## Write transcript line of assistant entry holding thinking of kind, before tool call of its
  ##   message; harness keeps text of thinking empty.
  $(%*{"type": "assistant", "message": {
    "content": [{"type": kind, "thinking": "", "signature": "s"}], "stop_reason": "tool_use",
  }}) & "\n"


func linesAgent(kind: string, description = "Do the work"): string =
  ## Write transcript lines of `Agent` call of kind and its launch notice, which arrives as user
  ##   entry, as harness writes call it runs in background.
  let
    call = %*{"type": "assistant", "message": {"content": [{
      "type": "tool_use", "id": "toolu_" & kind, "name": "Agent",
      "input": {"subagent_type": kind, "description": description, "prompt": "Do it."},
    }], "stop_reason": "tool_use"}}
    answer = %*{"type": "user", "message": {"content": [{
      "type": "tool_result", "tool_use_id": "toolu_" & kind, "content": "Async agent launched.",
    }]}, "toolUseResult": {"status": "async_launched", "agentId": "a" & kind}}
  $call & "\n" & $answer & "\n"


func lineHandback(name: string, agent = "a1", is_handback = true): string =
  ## Write transcript line of hand-back of subagent of kind name, as harness writes report of
  ##   subagent that ran in background.
  $(%*{"type": "user", "isMeta": true, "origin": {
    "kind": "peer", "from": agent, "name": name, "handback": is_handback,
  }, "message": {"content": "[Subagent hand-back] Report."}}) & "\n"


func lineQueued(name: string, agent = "a1"): string =
  ## Write transcript line of hand-back that arrives inside model turn, queued as attachment.
  $(%*{"type": "attachment", "attachment": {"type": "queued_command", "prompt": "Report.",
    "origin": {"kind": "peer", "from": agent, "name": name, "handback": true},
  }}) & "\n"


func linesForeground(kind, background, status: string; agent = "a1"): string =
  ## Write transcript lines of `Agent` call of kind whose input `run_in_background` is
  ##   background, `true` or `false`, or absent where empty, and its result of status.
  var input = %*{"subagent_type": kind, "description": "Check it", "prompt": "Check."}
  if background.len > 0: input["run_in_background"] = %(background == "true")
  let
    call = %*{"type": "assistant", "message": {"content": [{
      "type": "tool_use", "id": "toolu_f" & kind, "name": "Agent", "input": input,
    }], "stop_reason": "tool_use"}}
    answer = %*{"type": "user", "message": {"content": [{
      "type": "tool_result", "tool_use_id": "toolu_f" & kind, "content": "Report.",
    }]}, "toolUseResult": {"status": status, "agentId": agent}}
  $call & "\n" & $answer & "\n"


proc blocksHeld(transcript: string, kinds: openArray[string] = KINDS): seq[string] =
  ## Read messages of findings `checkBlocks` gives transcript at stop, for kinds.
  transcript.parseTurn.subagents.checkBlocks(kinds).messages


func refusalCell(cell: string): string =
  ## Write finding of cell under `Predicted` that is neither whole claim of block call took nor
  ##   `No prediction`, as rule of D5 b of #969 states it.
  "Cell under `Predicted` is one whole claim of `## Prediction` block that call took, up to " &
    "its percentage, percentiles or resolution criterion, with or without its label, or " &
    "`No prediction` (GUIDE.md, Prediction, critic and reflection); got `" & cell & "`."


func refusalCall(kind, description: string, hint = ""): string =
  ## Write finding of call of kind that took no block, with hint after its description.
  "Call of subagent of kind takes `## Prediction` block of model turn before its own, and " &
    "after each earlier turn that starts subagent (GUIDE.md, Prediction, critic and " &
    "reflection); got none for `" & kind & "` call `" & description & "`" & hint & "."


func hintNamed(named: string): string =
  ## Write hint that block of turns call looks back over names other kind or none, as rule of
  ##   7017187857 on #969 states it; named is kind in backticks, or `no kind`.
  ", and block of such turn names " & named & ": block serves only call of kind that first " &
    "word of its `**Subagent:**` line names"


func predicting(kind: string): string =
  ## Write `PREDICTION` for subagent of kind, which first word of its `**Subagent:**` line names.
  PREDICTION.replace("**Subagent:** builder of", "**Subagent:** " & kind & " of")



suite "Hooks":
  test "role string grammar":
    check "curator".isStringRole and "curator/audit".isStringRole
    check "coordinator".isStringRole  # role with no branch
    check not "coordinator/library".isStringRole  # its own thread holds coordinator
    check "contributor/ronri/pga_benchmark".isStringRole
    check not "contributor/nowhere/x".isStringRole and not "owner".isStringRole
    check not "contributor/ronri/pga_benchmark/gap-list".isStringRole  # branch, not role


  test "path relative to root, and write outside scope refused":
    check insideRoot("/home/u/repo", "/home/u/repo/src/a.nim") == "src/a.nim"
    check insideRoot("/home/u/repo/", "/tmp/x") == "/tmp/x"
    check checkPathEdit(BRANCH, "contributor/ronri/pga_benchmark/src/a.nim").len == 0
    check checkPathEdit(BRANCH, "CONSTITUTION.md").len == 1  # outside project
    check checkPathEdit("curator/x", "contributor/ronri/pga_benchmark/src/a.nim").len == 1
    check checkPathEdit("curator/x", "contributor/ronri/pga_benchmark/GLOSSARY.md").len == 0


  test "write outside repository passes, and scope of branch still holds inside it (#847)":
    # Case as found: scratch file such as `/tmp/x/y.md` was refused as path outside folder of
    #   branch, and every write on branch outside grammar. Directory in no repository reads as
    #   root (`checkoutAt`), so `insideRoot` hands file on whole, as `koch hook path` reads it.
    let
      root = repoTemp()
      scratch = createTempDir("delegations_", "_scratch")
    defer: removeDir(root)
    defer: removeDir(scratch)
    let checkout = checkoutAt(root, scratch / "x")
    check checkout == some(root)  # no repository, so root's branch judges
    let outside = insideRoot(checkout.get, scratch / "x" / "y.md")
    check outside == scratch / "x" / "y.md"  # handed on whole
    # Domain: every branch form passes file no commit reaches, and judges each file inside.
    for branch in [BRANCH, "curator/audit/x", "curator/x", "claude/tool-named", "main"]:
      check checkPathEdit(branch, outside).messages == newSeq[string]()  # refusal names branch
    let
      own = insideRoot(root, root / "contributor/ronri/pga_benchmark/src/a.nim")
      other = insideRoot(root, root / "CONSTITUTION.md")
    check checkPathEdit(BRANCH, own).len == 0
    check checkPathEdit(BRANCH, other).len == 1  # inside repository, outside folder of branch
    check checkPathEdit("curator/audit/x", other).len == 1
    check checkPathEdit("claude/tool-named", own).len == 1  # branch outside grammar


  test "write hook reads path in normal form, from each tool, through links (#883)":
    # Case as found on #883: `<root>//CONSTITUTION.md` read as `/CONSTITUTION.md`, and `..` from
    #   folder outside and link to root read as outside, so each passed; NotebookEdit names
    #   `notebook_path`, so hook judged directory of call in its place.
    proc refused(root: string, input: JsonNode, branch: string = BRANCH): seq[string] =
      ## Read refusals of write, through routine `koch hook path` and `koch hook edit` call.
      let written = fileWritten(root, root, input)
      if written.isNone: return
      checkPathEdit(branch, written.get.path).messages

    # Lay out root, and scratch folder holding link to root and link to file inside it.
    let
      root = repoTemp()
      other = repoTemp()
      scratch = createTempDir("delegations_", "_links")
      constitution = root / "CONSTITUTION.md"
      refusals_scope = @["Path outside branch scope `contributor/ronri/pga_benchmark/`."]
    defer: removeDir(root)
    defer: removeDir(other)
    defer: removeDir(scratch)
    root.writeInto("CONSTITUTION.md", "# Constitution\n")
    createSymlink(root, scratch / "root")
    createSymlink(constitution, scratch / "rules.md")

    # Normal form drops `.`, `..` and doubled slash; relative path resolves against directory.
    for written in [
      root & "/./CONSTITUTION.md",
      root & "//CONSTITUTION.md",
      root & "/contributor/ronri/pga_benchmark/../../../CONSTITUTION.md",
      scratch & "/../" & root.lastPathPart & "/CONSTITUTION.md",
    ]:
      check pathWritten(%*{"file_path": written}, "/w") == constitution
      check refused(root, %*{"file_path": written}) == refusals_scope
    check pathWritten(%*{"file_path": "sub/../CONSTITUTION.md"}, root) == constitution
    # Write tool drops `..` as text, before link ahead of it resolves, so hook does too.
    check pathWritten(%*{"file_path": scratch & "/root/../x.md"}, "/w").pathReal == scratch / "x.md"
    check fileWritten(root, root, %*{"file_path": scratch & "/root/../x.md"}).isNone

    # Resolve link to place file system writes: link to directory for new file, link to file whole.
    check pathReal(scratch / "root" / "new.md") == root / "new.md"
    check pathReal(scratch / "root" / "CONSTITUTION.md") == constitution
    check pathReal(scratch / "rules.md") == constitution
    check pathReal(scratch / "x" / "y.md") == scratch / "x" / "y.md"  # nothing to resolve
    check refused(root, %*{"file_path": scratch / "root" / "CONSTITUTION.md"}) == refusals_scope
    check refused(root, %*{"file_path": scratch / "rules.md"}) == refusals_scope

    # Read notebook NotebookEdit names, never directory of call.
    let notebook = %*{"notebook_path": root / "notes.ipynb"}
    check pathWritten(notebook, root) == root / "notes.ipynb"
    check refused(root, notebook) == refusals_scope
    check refused(root, %*{"notebook_path": root / "contributor/ronri/pga_benchmark/a.ipynb"})
      .len == 0
    check pathWritten(%*{"file_path": "a.md", "notebook_path": "b.ipynb"}, "/w") == "/w/a.md"

    # Read checkout and path inside it, which `path` judges and `edit` audits; none outside.
    let inside = some((checkout: root, path: "CONSTITUTION.md"))
    check fileWritten(root, root, %*{"file_path": root & "//CONSTITUTION.md"}) == inside
    check fileWritten(scratch / "root", root, %*{"file_path": constitution}) == inside
    check fileWritten(root, root, %*{"file_path": scratch / "x" / "y.md"}).isNone  # no repository
    check fileWritten(scratch / "root", root, %*{"file_path": scratch / "x.md"}).isNone
    check fileWritten(root, root, %*{"file_path": other / "a.md"}).isNone  # other repository

    # Domain: path in normal form inside folder of branch passes, and curator stays out of code.
    let code = root & "/./contributor/ronri/pga_benchmark/src/a.nim"
    check refused(root, %*{"file_path": code}).len == 0
    check refused(root, %*{"file_path": code}, "curator/x").len == 1  # records alone


  test "write hook reads text write leaves, from input of each tool (#950)":
    # `path` judges write before it lands, so it applies input of tool to text before write. Edit
    #   tool refuses `old_string` text lacks, and repeated one without `replace_all`, so first
    #   occurrence is one it replaces wherever it writes.
    func written(tool: string, input: JsonNode): Option[string] =
      ## Read text write leaves in file holding `a b a`.
      textWritten(tool, "a b a\n", input)

    # Read whole text of Write, and each edit applied as tool applies it.
    check written("Write", %*{"content": "c\n"}) == some("c\n")
    check written("Edit", %*{"old_string": "a", "new_string": "c"}) == some("c b a\n")  # first
    check written("Edit", %*{"old_string": "a", "new_string": "c", "replace_all": false}) ==
      some("c b a\n")
    check written("Edit", %*{"old_string": "a", "new_string": "c", "replace_all": true}) ==
      some("c b c\n")  # each occurrence
    check written("MultiEdit", %*{"edits": [
      {"old_string": "a", "new_string": "c"},
      {"old_string": "c b", "new_string": "d"},
    ]}) == some("d a\n")  # in order, each on text edit before it leaves

    # Give none where tool names no text, or would refuse.
    for (tool, input) in [
      ("Write", %*{"file_path": "x"}),  # no content
      ("Edit", %*{"old_string": "d", "new_string": "c"}),  # text lacks it
      ("Edit", %*{"old_string": "", "new_string": "c"}),  # names nothing to replace
      ("Edit", %*{"new_string": "c"}),
      ("Edit", %*{"old_string": "a"}),
      ("MultiEdit", %*{"edits": [
        {"old_string": "a", "new_string": "c", "replace_all": true},
        {"old_string": "a", "new_string": "d"},
      ]}),  # second edit finds none of what first replaced
      ("MultiEdit", %*{"edits": newJArray()}),  # no edit
      ("MultiEdit", %*{"file_path": "x"}),
      ("NotebookEdit", %*{"new_source": "c"}),  # no text of file
      ("Bash", %*{"content": "c\n", "old_string": "a", "new_string": "c"}),  # no write tool
    ]:
      check written(tool, input).isNone


  test "path hook passes name line of moved lock alone, as check-scope does (#950)":
    # Case as found: in move of `lojban_tagger` to `contributor/bangu/rictadni`, `path` refused
    #   Edit tool on name line of its lock, though `check-scope` passed that line (#950).
    #   Domain: that line from each write tool, with move staged and committed; other line, other
    #   name, lock that stayed, file other than lock, branch of other role, base git lacks, and
    #   directory in no repository.
    proc refused(
      checkout, branch, path, tool: string; input: JsonNode; base = "main"
    ): seq[string] =
      ## Read refusals of write, through routine `koch hook path` calls.
      checkPathEditMoved(checkout, branch, path, base, tool, input).messages

    # Commit project and its lock on `main`, beside project that stays; move it with `git mv`.
    let
      root = repoTemp()
      scratch = createTempDir("delegations_", "_scratch")
      directory_from = "contributor/bangu/lojban_tagger"
      lock = DIRECTORY_TAGGER & "/atlas.lock"
      stayed = DIRECTORY_PARSER & "/atlas.lock"
      nimble = DIRECTORY_TAGGER & "/rictadni.nimble"
      branch = "curator/move-tagger"
      (name_from, name_to) = ("\"lojban_tagger.nimble\"", "\"rictadni.nimble\"")
    defer: removeDir(root)
    defer: removeDir(scratch)
    root.writeInto(directory_from & "/lojban_tagger.nimble", TEXT_NIMBLE)
    root.writeInto(
      directory_from & "/atlas.lock", lockWith(TEXT_NIMBLE).replace("\"probe.nimble\"", name_from)
    )
    root.writeInto(DIRECTORY_PARSER & "/ricysoho.nimble", TEXT_NIMBLE)
    root.writeInto(
      stayed, lockWith(TEXT_NIMBLE).replace("\"probe.nimble\"", "\"ricysoho.nimble\"")
    )
    discard root.git("add -A")
    discard root.git("commit -q -m 'build(rictadni): pin'")
    discard root.git("checkout -q -b " & branch)
    discard root.git("mv " & directory_from & " " & DIRECTORY_TAGGER)
    discard root.git("mv " & DIRECTORY_TAGGER & "/lojban_tagger.nimble " & nimble)
    let
      text = readFile(root / lock)
      edit_name = %*{"old_string": name_from, "new_string": name_to}
      edit_version = %*{"old_string": "0.1.0", "new_string": "0.2.0"}
      refusal = checkPathEdit(branch, lock).messages
    check refusal.len == 1  # scope alone refuses each write of lock

    # Pass name line from each write tool, with move staged.
    check refused(root, branch, lock, "Edit", edit_name).len == 0
    check refused(root, branch, lock, "Write", %*{"content": text.replace(name_from, name_to)})
      .len == 0
    check refused(root, branch, lock, "MultiEdit", %*{"edits": [edit_name]}).len == 0

    # Refuse each other write of that lock, as scope refuses it.
    for (tool, input) in [
      ("Edit", edit_version),  # other line
      ("Edit", %*{"old_string": name_from, "new_string": "\"gamma.nimble\""}),  # name of no folder
      ("MultiEdit", %*{"edits": [edit_name, edit_version]}),  # other line beside name line
      ("Write", %*{"content": text.replace(name_from, name_to) & "\n"}),  # line added
      ("Edit", %*{"old_string": name_to, "new_string": name_from}),  # text lacks it
      ("NotebookEdit", %*{"new_source": name_to}),  # tool names no text of file
    ]:
      check refused(root, branch, lock, tool, input) == refusal

    # Refuse lock that stayed, file other than lock, branch of other role, and git that fails.
    let refusal_stayed = checkPathEdit(branch, stayed).messages
    check refusal_stayed.len == 1
    check refused(root, branch, stayed, "Edit", %*{
      "old_string": "\"ricysoho.nimble\"", "new_string": name_to,
    }) == refusal_stayed
    check refused(root, branch, stayed, "Write", %*{"content": readFile(root / stayed)}) ==
      refusal_stayed  # its own text, one line from old text of moved lock
    check refused(root, branch, nimble, "Edit", edit_version) ==
      checkPathEdit(branch, nimble).messages
    for other in ["contributor/bangu/lojban_tagger/move", "curator/audit/move"]:
      let refusal_other = checkPathEdit(other, lock).messages
      check refusal_other.len == 1
      check refused(root, other, lock, "Edit", edit_name) == refusal_other
    check refused(root, branch, lock, "Edit", edit_name, base = "origin/main") == refusal
    check refused(scratch, branch, lock, "Edit", edit_name) == refusal  # no repository

    # Pass name line once move is committed too.
    discard root.git("commit -q -m 'refactor(rictadni): move lojban_tagger here'")
    check refused(root, branch, lock, "Edit", edit_name).len == 0


  test "git commands read through shell operators and options":
    check commandsGit("git -c a=b push -u origin x && echo ok") == @[@["push", "-u", "origin", "x"]]
    check commandsGit("cd x; git commit -m 'a' | cat") == @[@["commit", "-m", "'a'"]]
    check commandsGit("ls -la").len == 0


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


  test "post neither asks for footer nor refuses one, as Architect ruled on #845":
    # Each form passes: none, plain, proxy's, both as body of #574 held them, and one above text.
    const
      plain = "_Generated by [Claude Code](https://claude.ai/code)_"
      session = "_Generated by [Claude Code](https://claude.ai/code/session_" &
          "01PDwEo3G1FGkHxFcUV8WBMt)_"
    for body in [
      ROLE & "\n\nText.\n",
      ROLE & "\n\nText.\n\n---\n" & plain & "\n",
      ROLE & "\n\nText.\n\n---\n" & session & "\n",
      ROLE & "\n\nText.\n\n---\n" & session & "\n\n\n---\n" & plain & "\n",
      ROLE & "\n\n" & session & "\n\nText.\n",
    ]:
      for tool in ["mcp__github__add_issue_comment", "mcp__github__issue_write"]:
        check checkBody(tool, BRANCH, "", body, [], false).len == 0


  test "body holds role line, English and issue shape":
    const foot = "\n\n---\n_Generated by [Claude Code](https://claude.ai/code)_"
    let good = ROLE & "\n\nOne short claim.\n" & foot
    check checkBody("mcp__github__add_issue_comment", BRANCH, "", good, [], false).len == 0
    let coordinator = "**Role:** coordinator\n\nOne short claim.\n" & foot
    check checkBody("mcp__github__add_issue_comment", "main", "", coordinator, [], false)
      .len == 0  # no branch holds coordinator, so none is compared
    let no_role = "Hello.\n" & foot
    check checkBody("mcp__github__add_issue_comment", BRANCH, "", no_role, [], false)
      .messages[0] == "Post must open with `" & ROLE & "`; got `Hello.`."  # opening alone
    let noted = "<!-- note -->\n" & ROLE & "\n\nOne short claim.\n"
    check checkBody("mcp__github__add_issue_comment", BRANCH, "", noted, [], false).messages ==
      @["Post must open with `" & ROLE & "`; got `<!-- note -->` above `" & ROLE & "`."]
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


  test "pull request body takes form of template on each create and each update (#845)":
    # `check-role` reads body at each event, so hook reads each update too (review of #845).
    let
      form = bodyPull(ROLE)
      old = ROLE & "\n\n## Intent\n\nX.\n\n## Scope\n\n- a\n\n## Verification\n\nGreen.\n\n" &
        "## Record\n\n- a\n\n## Notes\n\nNone.\n"  # template before #845
    for tool in TOOLS_PULL:
      let is_create = tool == "mcp__github__create_pull_request"
      check checkBody(tool, BRANCH, "t", form, [], is_create).len == 0
      check checkBody(tool, BRANCH, "t", old, [], is_create).messages
        .mapIt(it.startsWith("Pull request body holds `## What`")) == @[true]
      check checkBody(tool, BRANCH, "t", form.replace("One point.", "It fixes #12."), [], is_create)
        .messages.mapIt(it.startsWith("Body holds closing keyword")) == @[true]


  test "example of #845 is refused on two rules alone, which form keeps (#845)":
    # Review of #845 ran example through hooks of `main`: keyword closing #783 inside point, and
    #   point of 26 words. So template asks for `Closes #N` alone on last line of Next steps.
    check checkBody(
      "mcp__github__create_pull_request",
      BRANCH,
      "feat(pga_benchmark): propose maps-noalias",
      BODY_EXAMPLE,
      [],
      true,
    ).messages == @[
      "Body holds closing keyword before issue only on line of its own, as `Closes #783`, " &
        "since GitHub closes issue whatever sentence says; drop keyword, or put issue first, " &
        "as `#783 stays open`; got `Closes #783`.",
      "Sentence must hold at most 25 words; split it (ASD-STE100); got `Machine counts under " &
        "valgrind and gcc 13.3.0, on ...`.",
    ]


  test "closing keyword stands before issue only on line of its own (#859)":
    let found = closing("So this pull request does not close #859.")  # body of #860, as found
    check found.len == 1
    check found.anyIt("got `close #859`" in it and "#859 stays open" in it)
    check closing("It fixes #12 in passing.").anyIt("got `fixes #12`" in it)
    check closing("It resolves https://github.com/mraxilus/delegations/issues/7 too.")
      .anyIt("got `resolves https://github.com/mraxilus/delegations/issues/7`" in it)
    check closing("Closes #859").len == 0  # line of its own: GitHub closes, as meant
    check closing("closes: #859").len == 0
    check closing("Text.\n\n  Fixed #3  \n\nMore.").len == 0
    check closing("So #859 stays open after this pull request merges.").len == 0
    check closing("It Fixed: mraxilus/delegations#3 here.")
      .anyIt("got `Fixed: mraxilus/delegations#3`" in it)
    check closing("It does not close\n#859 at all.").len == 1  # GitHub reads across line break
    check closing("Closes #859, closes #860").len == 2  # line holds two references
    check closing("Closes #859 and more").len == 1
    check closing("It enclosed #5 and prefixes #6.").len == 0  # keyword inside word
    check closing("It closes the #5.").len == 0  # word between keyword and issue
    check closing("Write `does not close #859` never.").len == 0  # code span
    check closing("```text\nSo it does not close #859.\n```").len == 0  # fenced code
    const foot = "\n\n---\n_Generated by [Claude Code](https://claude.ai/code)_"
    let fixes = ROLE & "\n\nIt fixes #12.\n" & foot
    check checkBody("mcp__github__issue_write", BRANCH, "A claim", fixes, ["curator"], true)
      .len == 1  # issue body as pull request body
    check checkBody("mcp__github__add_issue_comment", BRANCH, "", fixes, [], false)
      .len == 0  # comment closes nothing


  test "sign-off shape":
    check checkSignoff(SIGNOFF, BRANCH).messages == newSeq[string]()
    check checkSignoff(PLAIN, BRANCH).messages == newSeq[string]()  # no decision
    check checkSignoff("Done.\n", BRANCH).messages[0].contains("holds no")
    check checkSignoff(SIGNOFF & "\n## After\n", BRANCH)
      .messages.anyIt("Nothing follows sign-off" in it)  # heading rule, not Next step rule
    check checkSignoff(SIGNOFF.replace("**Summary:**", "**Gist:**"), BRANCH)
      .messages.anyIt("lacks `**Summary:**`" in it)
    check checkSignoff(SIGNOFF.replace("**Role:** contributor/ronri", "**Role:** curator"), BRANCH)
      .messages.anyIt("role must be" in it)
    check checkSignoff(SIGNOFF & "\nTrailing.\n", BRANCH)
      .messages.anyIt("Nothing follows Next step" in it)


  test "sign-off parts come in order Architect set":
    # Order is role, context, rule line, work, summary, state, decisions, next step (GUIDE.md).
    const context = "**Context:** This branch adds the gap list. The Architect asked for " &
      "baselines. #331 was a draft.\n\n"
    let work_first = SIGNOFF.replace(context, "").replace("**Summary:**", context & "**Summary:**")
    check checkSignoff(work_first, BRANCH)
      .messages.anyIt("`---` in its order" in it)  # context comes before work
    const state = "**State:** blocked, at `3f2a9c1`, pushed\n\n"
    let state_early = SIGNOFF.replace(state, "").replace("**Context:**", state & "**Context:**")
    check checkSignoff(state_early, BRANCH)
      .messages.anyIt("lacks `**State:**` in its order" in it)  # state follows summary
    const summary = "**Summary:** The gap list is done. Row 4 waits on D1.\n\n"
    let summary_last = SIGNOFF.replace(summary, "").replace("**Next", summary & "**Next")
    check checkSignoff(summary_last, BRANCH)
      .messages.anyIt("lacks `**State:**` in its order" in it)  # summary comes before state
    check checkSignoff(SIGNOFF.replace("---\n", ""), BRANCH)
      .messages.anyIt("lacks `---` in its order" in it)  # rule line opens work


  test "sign-off state and decisions label":
    const state = "**State:** blocked, at `3f2a9c1`, pushed\n"
    check checkSignoff(SIGNOFF.replace(state, ""), BRANCH)
      .messages.anyIt("lacks `**State:**`" in it)
    check checkSignoff(SIGNOFF.replace("**State:** blocked", "**State:** stuck"), BRANCH)
      .messages.anyIt("state is one of" in it and "got `stuck`." in it)  # word, not branch
    let spaced = checkSignoff(SIGNOFF.replace("**State:** blocked,", "**State:** blocked"), BRANCH)
      .messages
    check spaced.len == 1 and "state line gives state word" in spaced[0]  # word ends at space too
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


  test "sign-off role line and state line take their short forms (#844)":
    # Case as found: role line named whole branch, and state line pull request and run too,
    #   which bold line of each pull request now gives.
    let five = checkSignoff(FIVE, BRANCH).messages
    check five.anyIt("as `, branch `gap-list``" in it)
    check five.anyIt("leaves pull request and run to its bold line" in it)
    # Domain: role, then word `branch` and last part of branch; state word, head and push alone.
    check checkSignoff(SIGNOFF.replace(", branch `gap-list`", ", `gap-list`"), BRANCH)
      .messages.anyIt("got `, `gap-list``" in it)
    check checkSignoff(SIGNOFF.replace(", branch `gap-list`", ""), BRANCH)
      .messages.anyIt("closes with word `branch`" in it)
    check checkSignoff(SIGNOFF.replace("pushed\n", "not pushed\n"), BRANCH)
      .messages == newSeq[string]()
    for state in [
      "**State:** blocked, at `3f2a9c1`, pushed, #331 draft",
      "**State:** blocked, at 3f2a9c1, pushed",
      "**State:** blocked, at `head`, pushed",
      "**State:** blocked, pushed",
    ]:
      check checkSignoff(SIGNOFF.replace("**State:** blocked, at `3f2a9c1`, pushed", state), BRANCH)
        .messages.anyIt("state line gives" in it)
    for other in ["claude/tool-named", "main"]:
      check checkSignoff(SIGNOFF.replace(", branch `gap-list`", ", at `main`"), other)
        .messages == newSeq[string]()  # branch outside grammar fixes no role


  test "stop hook asks for diff of each error alone, never whole message or its lines again":
    # Message stands on screen once hook reads it, so resent message reads twice (D1 of #570),
    #   and so does each paragraph sent again around one mended phrase.
    let
      ended = checkEndTurn("Pushed.\n", BRANCH, is_writing = true)
      reason = reasonStop(ended & checkNumbersBare("See #12.\n"), [])
    check reason.startsWith("Mend message that ends this turn (GUIDE.md, Output contract).")
    check "Reply with a diff of each error alone: one `diff` block" in reason
    check "each wrong phrase after `-`, that phrase mended after `+`" in reason
    check "never send it, a line of it, or its sign-off again" in reason
    check reason.splitLines.len == 3  # reason line, then one line for each finding
    check "got neither" in reason.splitLines[1]


  test "stop hook asks for read of unread queue, and no diff for it (#742)":
    # What waits in queue can change sign-off, so delegate reads it and names it in one line.
    let
      unread = checkSignoffRead(PLAIN, [])
      reason = reasonStop([], unread)
      both = reasonStop(checkNumbersBare("See #12.\n"), unread)
    check reason.startsWith("Read queue before this sign-off stands (GUIDE.md, Output contract)")
    check "take first what waits there, and reply with one line naming it, and no diff" in reason
    check "Mend message" notin reason
    check reason.splitLines.len == 2  # reason line, then finding
    check both.startsWith("Mend message") and "Read queue before" in both
    check both.splitLines.len == 4  # each reason line, each before its finding


  test "sign-off follows read of open issues of its role, in its turn (#742)":
    # Case as found: curator signed off `done` on 2026-10-24 from turn that read runs alone,
    #   while request #730 on label `curator` waited 13 hours unread.
    const
      list = "mcp__github__list_issues"
      role = "contributor/ronri/pga_benchmark, branch `gap-list`"
    let curator = PLAIN.replace(role, "curator, at main")
    check checkSignoffRead(curator, [Call(name: "mcp__github__actions_list")])
      .messages.anyIt("labelled `curator`" in it and "got none" in it)

    # Tool read counts where it names role label or none, and asks for more than closed issues.
    check checkSignoffRead(curator, [Call(name: list, labels: @["curator"], state: "open")])
      .len == 0
    check checkSignoffRead(curator, [Call(name: list, labels: @["curator"])]).len == 0  # both
    check checkSignoffRead(curator, [Call(name: list, state: "open")]).len == 0  # every label
    check checkSignoffRead(curator, [Call(name: list, labels: @["curator"], state: "closed")])
      .len == 1
    check checkSignoffRead(curator, [Call(name: list, labels: @["architect"])]).len == 1

    # Shell read counts through `gh issue list` and `gh api`, in each form of flag `gh` takes.
    for command in [
      "gh issue list --label curator",
      "gh issue list -l curator --limit 10",
      "gh issue ls --label=curator",
      "gh issue list -lcurator",
      "gh issue list -l 'architect,curator'",
      "cd /x && gh issue list --state open -l curator",
      "gh issue list",
      "gh api 'repos/o/r/issues?labels=curator&state=open'",
      "gh api repos/{owner}/{repo}/issues",
    ]:
      check checkSignoffRead(curator, [Call(name: "Bash", command: command)]).len == 0
    for command in [
      "gh issue list -l curator --state closed",
      "gh issue list -s closed -l curator",
      "gh issue view 730",
      "gh pr list -l curator",
      "gh api 'repos/o/r/issues?labels=curator&state=closed'",
      "gh api repos/o/r/issues/730/comments",
      "gh api 'search/issues?q=label:curator'",
    ]:
      check checkSignoffRead(curator, [Call(name: "Bash", command: command)]).len == 1

    # Role comes from sign-off: contributor reads its own label, coordinator reads `architect`.
    const encoded = "gh api 'repos/o/r/issues?labels=contributor%2Fronri%2Fpga_benchmark'"
    check checkSignoffRead(PLAIN, [Call(name: "Bash", command: encoded)]).len == 0
    check checkSignoffRead(PLAIN, [Call(name: list, labels: @["curator"])]).len == 1
    let coordinator = PLAIN.replace(role, "coordinator")
    check checkSignoffRead(coordinator, [Call(name: list, labels: @["architect"])]).len == 0
    check checkSignoffRead(coordinator, [Call(name: list, labels: @["coordinator"])]).len == 1

    # Message with no sign-off, or role line naming no role string, asks nothing here.
    check checkSignoffRead("Done.\n", []).len == 0
    check checkSignoffRead(PLAIN.replace("contributor/ronri/pga_benchmark", "maintainer"), [])
      .len == 0


  test "turn ends with sign-off once delegate stops, else with working line":
    # Sign-off only when done, blocked or waiting; working line while work runs (GUIDE.md).
    const working = "Pushed.\n\n**Working:** run 890 of `check`, whose result wakes me.\n"
    check checkEndTurn(SIGNOFF, BRANCH, is_writing = true).len == 0
    check checkEndTurn(working, BRANCH, is_writing = true).len == 0
    check checkEndTurn("Pushed.\n", BRANCH, is_writing = true).messages.anyIt("got neither" in it)
    check checkEndTurn("Pushed.\n\n**Working:**\n", BRANCH, is_writing = true)
      .messages.anyIt("got neither" in it)  # names nothing
    check checkEndTurn(working & "\nMore.\n", BRANCH, is_writing = true)
      .messages.anyIt("got neither" in it)  # working line is last
    check checkEndTurn(SIGNOFF.replace("**Summary:**", "**Gist:**"), BRANCH, is_writing = true)
      .messages.anyIt("lacks `**Summary:**`" in it)  # sign-off read in full
    let working_state = PLAIN.replace("**State:** done", "**State:** working")
    check checkEndTurn(working_state, BRANCH, is_writing = true)
      .messages.anyIt("got `working`" in it and "**Working:**" in it)  # no state for work


  test "sign-off takes shape check whatever its turn did, and one quoted in fence is none (#844)":
    # Ruling on #844: each message that holds sign-off takes shape check, and not only message of
    #   turn that pushed or posted, since sign-off can close turn that wrote nothing.
    let gist = SIGNOFF.replace("**Summary:**", "**Gist:**")
    check checkEndTurn(gist, BRANCH, is_writing = false)
      .messages.anyIt("lacks `**Summary:**`" in it)
    check checkEndTurn(SIGNOFF, BRANCH, is_writing = false).messages == newSeq[string]()
    check checkEndTurn("Read.\n", BRANCH, is_writing = false).len == 0  # no sign-off, none asked
    # Sign-off in fence is quoted example, so message holds none, and no read follows it.
    let quoted = "The form:\n\n```md\n" & gist & "```\n"
    check checkEndTurn(quoted, BRANCH, is_writing = false).len == 0
    check checkEndTurn(quoted, BRANCH, is_writing = true).messages.anyIt("got neither" in it)
    check checkEndTurn(quoted & "\n" & SIGNOFF, BRANCH, is_writing = true).len == 0  # real one
    check checkSignoffRead(quoted, []).len == 0


  test "message names issue and pull request by link first, then by number alone":
    # Long form once, as one link of short description and number (GUIDE.md, Output contract).
    const linked = "[the ledger fix (#456)](https://x/456), [#457] and " &
      "[the fixers (#441)][#441].\n\n[#457]: https://x/457\n[#441]: https://x/441\n"
    check checkNumbersBare(linked).len == 0
    check checkNumbersBare("Merged #463.\n").messages.anyIt("`#463` bare before any link" in it)
    check checkNumbersBare("[the ledger fix (#456)](https://x/456) merged, so #456 closes.\n")
      .len == 0  # after its link, number alone
    check checkNumbersBare("Merged #456.\n\n[The ledger fix (#456)](https://x/456) holds.\n")
      .len == 1  # bare before its link
    check checkNumbersBare("#456 is [the ledger fix (#456)](https://x/456).\n").len == 1  # line
    check checkNumbersBare("| 1 | ✅ | Gap list | #331 | green |\n\nThen #331 waits.\n")
      .len == 0  # row names its item
    check checkNumbersBare("See `#463` and\n```\n#464\n```\n").len == 0  # code
    check checkNumbersBare("``run `#463` here``\n").len == 0  # span of two backticks
    check checkNumbersBare("Undefined [#465] stays bare.\n").len == 1  # no definition
    check checkNumbersBare("&#169; and x/y#12 and a#3\n").len == 0  # reference, fragment
    check checkNumbersBare("#463 then #463 again, and #7\n").len == 2  # each number once


  test "message writes each link inline, since reference link defined below shows raw":
    # Claude Code shows `[text][label]` as text where its definition stands below it.
    check checkLinksReference("[the ledger fix (#456)](https://x/456) merged.\n").len == 0
    check checkLinksReference("[the fixers (#441)][#441].\n\n[#441]: https://x/441\n")
      .messages.anyIt("`[#441]` by reference" in it)
    check checkLinksReference("```\n[#441]: https://x/441\n```\n").len == 0  # code
    check checkLinksReference("[#1]: https://x/1\n[#2]: https://x/2\n").len == 1  # once


  test "message cites each charter reference by short description, never bare":
    # Short description and its reference, as `names read head first (V.2)` (GUIDE.md, Output
    #   contract). Each passing form stands beside bare `V.2`, so stub reporting nothing fails it
    #   as stub reporting every reference does.
    check checkReferencesBare("X.9 says so.\n").messages == @[
      "Message cites `X.9` with no description; cite each article and duty first by short " &
        "description and its reference, as `expression spacing (X.9)`, then reference alone " &
        "(GUIDE.md, Output contract).",
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
    check citedBare("Expression spacing (X.9) holds, so X.9 alone after it.\n").len == 0
    check citedBare("A check that reddens a project (duty 3), then Duty 3 alone.\n").len == 0
    check citedBare("X.9 first, then expression spacing (X.9).\n") == @["X.9"]  # bare before


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
    check checkSignoff(SIGNOFF.replace("  - **b. Rename:** twelve suites change.\n", ""), BRANCH)
      .messages.anyIt("offers 2 to 4 options; got `1`" in it)
    const more = "  - c. Drop: x.\n  - d. Wait: x.\n  - e. Ask: x.\n- Recommends:"
    check checkSignoff(SIGNOFF.replace("- Recommends:", more), BRANCH)
      .messages.anyIt("offers 2 to 4 options; got `5`" in it)
    check checkSignoff(SIGNOFF.replace("a. Keep:", "a. Keep both names here:"), BRANCH)
      .messages.anyIt("at most 3 words" in it)
    check checkSignoff(SIGNOFF.replace("a. Keep:", "a. Keep the tests."), BRANCH)
      .messages.anyIt("`<letter>. <label>: <consequence>`" in it)  # no colon closes label
    check checkSignoff(SIGNOFF.replace("- Recommends: **a**,", "- Recommends: **c**,"), BRANCH)
      .messages.anyIt("Recommends names letter" in it)
    let period = SIGNOFF.replace("- Recommends: **a**,", "- Recommends: **a**. Keep,")
    check checkSignoff(period, BRANCH).len == 0  # letter closed by period
    check checkSignoff(SIGNOFF.replace("- Recommends: **a**, because", "- Because"), BRANCH)
      .messages.anyIt("lacks `Recommends:`" in it)
    check checkSignoff(SIGNOFF.replace("in the tests?", "in the tests."), BRANCH)
      .messages.anyIt("ends with `?`" in it)
    let asks = SIGNOFF.replace("- Where: #331\n", "- Where: #331\n- Options:\n  - a. Buy: x.\n")
    check checkSignoff(asks, BRANCH).messages.anyIt("offers no option" in it)  # fact asks nothing
    let picks = SIGNOFF.replace("- Where: #331\n", "- Where: #331\n- Recommends: a\n")
    check checkSignoff(picks, BRANCH).messages.anyIt("picks no option" in it)


  test "sign-off decision reads label of each option and its pick through bold (#844)":
    # Case as found: example of #844 sets each label and pick in bold, and hook read `D1` as
    #   offering no option, and its pick as `**a**`.
    check checkSignoff(SIGNOFF, BRANCH).messages == newSeq[string]()
    let plain = SIGNOFF
      .replace("  - **a. Keep:**", "  - a. Keep:")
      .replace("  - **b. Rename:**", "  - b. Rename:")
      .replace("- Recommends: **a**,", "- Recommends: a,")
    check checkSignoff(plain, BRANCH).messages == newSeq[string]()  # bold is no rule
    check checkSignoff(SIGNOFF.replace("**a. Keep:**", "**a. Keep**:"), BRANCH)
      .messages == newSeq[string]()  # colon after bold
    # Domain: bold hides no rule of option or pick.
    check checkSignoff(SIGNOFF.replace("**a. Keep:**", "**a. Keep both names here:**"), BRANCH)
      .messages.anyIt("at most 3 words" in it)
    check checkSignoff(SIGNOFF.replace("**a. Keep:**", "**a. Keep the tests.**"), BRANCH)
      .messages.anyIt("`<letter>. <label>: <consequence>`" in it)
    check checkSignoff(SIGNOFF.replace("- Recommends: **a**,", "- Recommends: **c**,"), BRANCH)
      .messages.anyIt("Recommends names letter" in it and "got `c`" in it)


  test "sign-off rows name who acts":
    check checkSignoff(SIGNOFF.replace("carried 6, D1 |", "carried 6, the Architect |"), BRANCH)
      .messages.anyIt("names decision it waits on" in it)
    check checkSignoff(SIGNOFF.replace("carried 6, D1 |", "carried 6, D3 |"), BRANCH)
      .messages.anyIt("names decision it waits on" in it)  # no such decision
    check checkSignoff(SIGNOFF.replace("contributor/ronri/pga_visualiser, fix", "they fix"), BRANCH)
      .messages.anyIt("opens second cell with role string" in it)
    check checkSignoff(
      SIGNOFF.replace("contributor/ronri/pga_visualiser, fix", "outside, GitHub fixes runner"),
      BRANCH,
    ).messages == newSeq[string]()
    # Carried tag may open second cell, and role string then follows it.
    const answered = "| ✅ 7. The request of the curator is answered | carried 2, #330 |"
    check checkSignoff(
      SIGNOFF.replace(answered, "| ⚠️ 7. The request of the curator waits | carried 2, curator |"),
      BRANCH,
    ).messages == newSeq[string]()
    check checkSignoff(
      SIGNOFF.replace(answered, "| ⚠️ 7. The request of the curator waits | carried 2, they act |"),
      BRANCH,
    ).messages.anyIt("got `they` in row `7`" in it)


  test "sign-off holds group for each pull request, each with table of two columns (#844)":
    # Case as found: table of five columns of each sign-off before #844, which phone cuts past its
    #   first column, and which holds work of each pull request in one table.
    let five = checkSignoff(FIVE, BRANCH).messages
    check five.anyIt("lacks `---` in its order" in it)
    check five.anyIt("follows bold line of its group" in it)
    check five.anyIt(
      "opens with header `| Item | Evidence, or who acts |`; got `| # | State | Item |" in it
    )
    check five.anyIt("`**Outside a pull request.**` once" in it and "got `0`" in it)
    check five.allIt("holds two cells" notin it)  # rows under header out of shape go unread

    # Bold line of group links its pull request and gives its state.
    const pull = "**[The gap list (#331)](https://github.com/mraxilus/delegations/pull/331), draft"
    check checkSignoff(SIGNOFF.replace(pull, "**The gap list (#331), draft"), BRANCH)
      .messages.anyIt("links its pull request and gives its state" in it)
    check checkSignoff(SIGNOFF.replace("/pull/331)", "/issues/331)"), BRANCH)
      .messages.anyIt("links its pull request and gives its state" in it)
    check checkSignoff(SIGNOFF.replace("/pull/331), draft", "/pull/331), open"), BRANCH)
      .messages.anyIt("one of draft, ready, merged, closed; got `open`" in it)
    for state in ["ready", "merged", "closed"]:
      check checkSignoff(SIGNOFF.replace("/pull/331), draft", "/pull/331), " & state), BRANCH)
        .messages == newSeq[string]()

    # One group for each pull request, and work outside one in last table, once.
    let
      at_pull = SIGNOFF.find("**[The gap list")
      at_outside = SIGNOFF.find("**Outside a pull request.**")
      group = SIGNOFF[at_pull ..< at_outside]
      outside = SIGNOFF[at_outside ..< SIGNOFF.find("**Summary:**")]
    check checkSignoff(SIGNOFF.replace(outside, ""), BRANCH)
      .messages.anyIt("`**Outside a pull request.**` once" in it and "got `0`" in it)
    check checkSignoff(SIGNOFF.replace(outside, outside & outside), BRANCH)
      .messages.anyIt("`**Outside a pull request.**` once" in it and "got `2`" in it)
    check checkSignoff(SIGNOFF.replace(group & outside, outside & group), BRANCH)
      .messages.anyIt("after each group of pull request" in it)
    check checkSignoff(SIGNOFF.replace(group, group & group), BRANCH)
      .messages.anyIt("one group for each pull request; got `#331` twice" in it)
    let bare = SIGNOFF.replace(group, group[group.find("| Item |") .. ^1])
    check checkSignoff(bare, BRANCH).messages.anyIt("follows bold line of its group" in it)

    # Row holds two cells, and its first opens with state, number and claim.
    const row = "| ✅ 2. Gap list reads each baseline | `koch check` green |"
    check checkSignoff(
      SIGNOFF.replace(row, "| ✅ 2. Gap list reads each baseline | `src/` | `koch check` green |"),
      BRANCH,
    ).messages.anyIt("holds two cells" in it and "got `3`" in it)
    for first in ["✅ Gap list reads", "✅ 2 Gap list reads", "✅ 2. "]:
      check checkSignoff(SIGNOFF.replace("✅ 2. Gap list reads each baseline", first), BRANCH)
        .messages.anyIt("opens first cell with state, number and claim" in it)
    for first in ["🟢 2. Gap list reads", "Gap list reads"]:
      check checkSignoff(SIGNOFF.replace("✅ 2. Gap list reads each baseline", first), BRANCH)
        .messages.anyIt(
          "opens first cell with state, one of ☑️ ✅ ⚠️ ⏸️ ⬜ ➖" in it and
            "got `" & first.splitWhitespace[0] & "`" in it
        )  # state that no marker gives is named, with markers that are
    check checkSignoff(SIGNOFF.replace("| this delegate |", "| |"), BRANCH)
      .messages.anyIt("holds evidence, or who acts" in it and "row `5`" in it)
    check checkSignoff(SIGNOFF.replace("| `koch check` green |", "| |"), BRANCH)
      .messages.anyIt("holds evidence, or who acts" in it and "row `2`" in it)

    # Rows number from 1 across tables, and sort by state inside each table.
    check checkSignoff(SIGNOFF.replace("| ☑️ 6. The answered", "| ☑️ 1. The answered"), BRANCH)
      .messages.anyIt("numbered from 1 in order across its tables; got `1`" in it)
    check checkSignoff(SIGNOFF.replace("| ⏸️ 4.", "| ⏸️ 6."), BRANCH)
      .messages.anyIt("numbered from 1 in order across its tables; got `6`" in it)
    check checkSignoff(SIGNOFF.replace("| ✅ 2.", "| ⬜ 2."), BRANCH)
      .messages.anyIt("sort ☑️ ✅ ⚠️ ⏸️ ⬜ ➖ inside each table" in it)  # ⬜ before ✅
    const review = "none arose |\n| ⬜ 5. Review asked | this delegate |\n"
    check checkSignoff(PLAIN.replace("none arose |\n", review), BRANCH)
      .messages.anyIt("sort ☑️ ✅ ⚠️ ⏸️ ⬜ ➖ inside each table" in it)  # ➖ closes its table


  test "sign-off names each carried rule beside its item, or in ➖ row (#844)":
    # Case as found: rule that did not apply went to body of pull request, so sign-off showed
    #   only some rules, each tagged in its item cell.
    check checkSignoff(FIVE, BRANCH)
      .messages.allIt("carried rule" notin it)  # table unread, so no tag of it counts
    const draft = "| ☑️ 1. Draft since it opened, another commit intended | carried 3, #331 draft |"
    let tagged = SIGNOFF.replace(draft, "| ☑️ 1. Draft since it opened (carried 3) | #331 |")
    check checkSignoff(tagged, BRANCH)
      .messages.anyIt("names each carried rule" in it and "got none for `3`" in it)
    check checkSignoff(SIGNOFF.replace("carried 3,", "carried 9,"), BRANCH)
      .messages.anyIt("names rule 1 to 6; got `9`" in it)

    # Rule may stand beside two items, and never beside one and in ➖ row too.
    check checkSignoff(SIGNOFF.replace("| `koch check` green |", "| carried 5, green |"), BRANCH)
      .messages == newSeq[string]()
    check checkSignoff(SIGNOFF.replace("carried 4: no page", "carried 4 and 5: no page"), BRANCH)
      .messages.anyIt("never in both; got `5`" in it)

    # ➖ row names its rules by tag, once, in table of work outside pull request.
    const unneeded = "| ➖ 9. Not needed: page link | carried 4: no page changed |"
    let untagged = SIGNOFF.replace(unneeded, "| ➖ 9. Not needed: page link | no page |")
    check checkSignoff(untagged, BRANCH)
      .messages.anyIt("➖ row names each carried rule" in it and "got `no page` in row `9`" in it)
    check checkSignoff(SIGNOFF.replace(unneeded & "\n", ""), BRANCH)
      .messages.anyIt("got none for `4`" in it)
    let
      second = "| ➖ 10. Not needed: terms | carried 6: no term arose |"
      twice = SIGNOFF.replace(unneeded, unneeded & "\n" & second).replace("carried 6, D1", "D1")
    check checkSignoff(twice, BRANCH).messages.anyIt("holds one ➖ row; got `2`" in it)
    let inside = SIGNOFF
      .replace(unneeded & "\n", "")
      .replace("| this delegate |", "| this delegate |\n| ➖ 6. Not needed: page link | carried 4 |")
      .replace("| ☑️ 6.", "| ☑️ 7.").replace("| ✅ 7.", "| ✅ 8.").replace("| ⚠️ 8.", "| ⚠️ 9.")
    check checkSignoff(inside, BRANCH)
      .messages.anyIt("stands in table `**Outside a pull request.**`; got it in row `6`" in it)
    # Tag joins its numbers by comma and `and`; word `carried` before no number is prose.
    check checkSignoff(PLAIN, BRANCH).messages == newSeq[string]()  # `carried 1, 2, 4 and 6`
    check checkSignoff(SIGNOFF.replace("| `koch check` green |", "| carried over, green |"), BRANCH)
      .messages == newSeq[string]()


  test "sign-off folds done rows of pull request into one row past twelve (#844)":
    # Fold names first and last item it holds, so count of items stays readable.
    const
      first = "| ☑️ 1. Draft since it opened, another commit intended | carried 3, #331 draft |\n"
      second = "| ✅ 2. Gap list reads each baseline | `koch check` green |\n"
      folded = "| ☑️ 1–2. Draft, and gap list reads baselines | carried 3, `koch check` green |\n"
    check checkSignoff(SIGNOFF.replace(first & second, folded), BRANCH)
      .messages == newSeq[string]()
    check checkSignoff(SIGNOFF.replace(first & second, folded.replace("1–2", "1-2")), BRANCH)
      .messages == newSeq[string]()  # hyphen reads as dash
    check checkSignoff(SIGNOFF.replace(first & second, folded.replace("1–2", "2–1")), BRANCH)
      .messages.anyIt("numbered from 1 in order across its tables" in it)
    check checkSignoff(SIGNOFF.replace("| ⬜ 5. cga5d", "| ⬜ 5–6. cga5d"), BRANCH)
      .messages.anyIt("folds done rows alone" in it and "row `5`" in it)


  test "example sign-off of GUIDE.md holds shape that stop hook reads (#844)":
    # Delegate copies form from example, so example passes hook that holds form, on branch whose
    #   role it names.
    const
      guide = staticRead("../../../../GUIDE.md")
      opening = "```md\n" & HEADING_SIGNOFF & "\n"
    let at = guide.find(opening)
    check at >= 0
    if at >= 0:
      let example = guide[at + "```md\n".len ..< guide.find("\n```", at)]
      check checkSignoff(example, "contributor/bangu/rictadni/lujvo-search")
        .messages == newSeq[string]()


  test "push and commit message":
    check checkPush("abc\n", "abc").len == 0
    check checkPush("abc", "def").messages[0].contains("exact commit")
    check pathMark("/repo", ".git") == "/repo/.git/koch-check"
    check pathMark("/repo/wt", "/repo/.git/worktrees/wt") ==
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
    check directoryCommand("git commit -m x", "/work/tree") == "/work/tree"
    check directoryCommand("git -C /other commit", "/work/tree") == "/other"
    check directoryCommand("git -C sub commit", "/work/tree") == "/work/tree/sub"
    check directoryCommand("cd /other && git push", "/work/tree") == "/other"
    check directoryCommand("cd \"sub\" && git -C deeper push", "/work") == "/work/sub/deeper"
    check directoryCommand("ls && git status", "/work") == "/work"


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
    let text = contextStart(BRANCH, "", "## List\n\n1. one\n\n## Next\n", "## List", "", @[])
    check "Role: contributor/ronri/pga_benchmark" in text and "CONTRIBUTOR.md" in text
    check "1. one" in text and "## Sign-off" in text and "**Working:**" in text
    check "outside grammar" in contextStart("claude/x", "", "", "## List", "", @[])
    # Drift prints each finding of `check-drift`: sections changed and command that shows them,
    #   so start asks for new stamp only where finding does (#843).
    let
      drift = finding(
        "GUIDE.md",
        0,
        "Base changed sections; read `git diff a..origin/main -- GUIDE.md`; got `## Output " &
          "contract`.",
      )
      stamp = finding("", 0, "Branch predates code of stamp on base; got `provenance.nim`.")
      drifted = contextStart("curator/x", "", "", "## List", "", @[drift, stamp])
    check "\n  GUIDE.md: Base changed sections" in drifted and "`## Output contract`" in drifted
    check "\n  Branch predates code of stamp on base; got `provenance.nim`.\n" in drifted  # each
    check "re-stamp" notin drifted
    # Drift names charter and code of stamp alone, since checker reaches branch through merge
    #   `koch check` judges (#893).
    check "Base changed charter or code of stamp since this branch forked" in drifted
    check "checker" notin drifted
    check isTurnWriting([Call(name: "Bash", command: "git push -u origin x")])
    check isTurnWriting([Call(name: "mcp__github__issue_write", has_body: true)])
    check not isTurnWriting([Call(name: "mcp__github__update_pull_request")])  # draft toggle
    check not isTurnWriting([Call(name: "Bash", command: "git status"), Call(name: "Read")])
    const issue = "gh api repos/o/r/issues/7/"
    check isTurnWriting([Call(name: "Bash", command: issue & "comments -F body=@x.md")])  # post
    check not isTurnWriting([Call(name: "Bash", command: issue & "labels -f 'labels[]=curator'")])


  test "start prints each commit of lock that lags main, after drift, as koch check does":
    # D2 of #927: `koch check` and start name each commit of lock that names folder of this
    #   repository and lags `main`, with its count; lines come from `noticesLag` once, so both
    #   print same lines, and none where nothing lags.
    let
      knoller = Locked(
        lock: "curator/assayer/atlas.lock",
        name: "knoller",
        folder: "curator/knoller",
        commit: "11403468a97c0d3ae922182d894606e2688504e9",
      )
      notices = noticesLag([Lag(locked: knoller, count: some(5), is_held: true)], "origin/main")
      drift = finding("GUIDE.md", 0, "Base changed sections; got `## Output contract`.")
      text = contextStart("curator/x", "", "", "## List", "", @[drift], notices)
    check notices.len == 2  # heading and one item
    check "\n" & notices.join("\n") & "\n" in text  # each line, unchanged
    check text.find(notices[1]) > text.find("GUIDE.md: Base changed")  # after drift
    check notices[0] notin contextStart("curator/x", "", "", "## List", "", @[drift])  # none lags


  test "start prints headings of record branch works on, with line each opens on (#843)":
    # Case as found: `GUIDE.md`, `How to build on a project`, asked delegate to read whole record,
    #   and record of pga_visualiser holds about 93,000 tokens over 47 sections; task reads few.
    check pathRecord(BRANCH) == "contributor/ronri/pga_benchmark/PROVENANCE.md"
    check pathRecord("curator/probe/rings") == "curator/probe/PROVENANCE.md"
    check pathRecord("curator/rules") == "curator/audit/PROVENANCE.md"  # checker is root work
    check pathRecord("claude/x").len == 0  # outside grammar
    let
      record = "# Provenance\n\n| Field | Value |\n\n## Build\n\nText.\n\n```md\n## Quoted\n" &
        "```\n\n## Open questions\n\n- One.\n"
      text = contextStart(BRANCH, "", "## List\n\n1. one\n", "## List", record, @[])
    check "Record `contributor/ronri/pga_benchmark/PROVENANCE.md`" in text
    check "\n5: ## Build\n13: ## Open questions\n" in text  # each heading, line it opens on
    check "## Quoted" notin text  # heading quoted in fence opens no section
    check text.endsWith(LINE_CARRIED)  # carried list stays last
    check "Record" notin contextStart(BRANCH, "", "## List\n", "## List", "", @[])  # none written


  test "start prints reading order from file of role, and holds no copy of its own (#891)":
    # Case as found: start printed `CONSTITUTION.md`, `STYLE.md`, `GLOSSARY.md`, then `CURATOR.md`,
    #   then `GUIDE.md` to curator, while `CURATOR.md`, Read first, puts `CONTRIBUTOR.md` second
    #   and itself fourth. Domain: each arm of grammar, file of role lacking heading, and branch
    #   outside grammar, as coordinator's reads until its trial.
    const
      heading = "## Read first, in this order"  # `HEADING_READ` of `prompts.nim`
      curator = "# Curator\n\n" & heading & "\n\n1. Charter.\n2. `CONTRIBUTOR.md`.\n" &
        "4. This file to the end.\n\n## Duties\n\nDo.\n"
      contributor = "# Contributor\n\n" & heading & "\n\n1. Charter.\n\n## List\n\n1. one\n"
    check pathPrompt("curator/rules") == "CURATOR.md"  # curator root
    check pathPrompt("curator/probe/rings") == "CURATOR.md"  # one curator project
    check pathPrompt(BRANCH) == "CONTRIBUTOR.md"
    check pathPrompt("claude/x").len == 0  # outside grammar
    let text = contextStart("curator/rules", curator, contributor, "## List", "", @[])
    check text.startsWith("Role: curator, on branch `curator/rules`.\n\nRead first, from " &
      "`CURATOR.md`:\n1. Charter.\n2. `CONTRIBUTOR.md`.\n4. This file to the end.\n\n")
    check "Do." notin text  # next section stays out
    check "then GUIDE.md" notin text  # no copy of list of its own
    check "\nRead first, from `CONTRIBUTOR.md`:\n1. Charter.\n\n" in
      contextStart(BRANCH, contributor, contributor, "## List", "", @[])
    let lacking = "# Curator\n\nDuties.\n"  # prompt check reports it
    check "Duties." notin contextStart("curator/rules", lacking, contributor, "## List", "", @[])
    check "Read first" notin contextStart("claude/x", "", contributor, "## List", "", @[])


  test "start reads file of role that branch names, from root of checkout":
    # Koch passes this text to `contextStart`, and no suite runs `main` of koch, so read is held
    #   here, over scratch root. Domain: curator branch, contributor branch, branch outside
    #   grammar, and root lacking file of role.
    let root = createTempDir("delegations_", "_prompts")
    defer: removeDir(root)
    writeFile(root / "CURATOR.md", "# Curator\n")
    writeFile(root / "CONTRIBUTOR.md", "# Contributor\n")
    check readPrompt(root, "curator/rules") == "# Curator\n"
    check readPrompt(root, BRANCH) == "# Contributor\n"
    check readPrompt(root, "claude/x").len == 0  # outside grammar, though root holds both
    removeFile(root / "CONTRIBUTOR.md")
    check readPrompt(root, BRANCH).len == 0  # root lacking file of role


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


  test "transcript parse keeps labels and state that list of issues filters on (#742)":
    const transcript =
      "{\"type\":\"user\",\"message\":{\"content\":\"read queue\"}}\n" &
      "{\"type\":\"assistant\",\"message\":{\"content\":[{\"type\":\"tool_use\"," &
      "\"name\":\"mcp__github__list_issues\",\"input\":{\"labels\":[\"curator\"]," &
      "\"state\":\"OPEN\"}}]}}\n"
    let turn = transcript.parseTurn
    check turn.calls.len == 1 and turn.calls[0].labels == @["curator"]
    check turn.calls[0].state == "open"


  test "sign-off keeps each item of sign-off before it, since message of Architect (#844)":
    # Case as found on #844: second sign-off after one message of Architect drops item of first,
    #   which Architect never read, since Architect reads latest sign-off alone.
    let
      dropped = SIGNOFF
        .replace("| ⬜ 5. cga5d baseline | this delegate |\n", "")
        .replace("| ☑️ 6.", "| ☑️ 5.").replace("| ✅ 7.", "| ✅ 6.")
        .replace("| ⚠️ 8.", "| ⚠️ 7.").replace("| ➖ 9.", "| ➖ 8.")
      asked = lineUser("Add the gap list.", "human") & lineAssistant(SIGNOFF)
      turn = (asked & linesCall("git push") & lineAssistant(dropped)).parseTurn
    check checkSignoff(dropped, BRANCH).messages == newSeq[string]()  # shape holds alone
    check turn.text == dropped and turn.signoffs_earlier == @[SIGNOFF]
    let found = checkSignoffWindow(turn.text, BRANCH, turn.signoffs_earlier, []).messages
    check found.len == 1
    check found.anyIt("got `4` items in `#331`, which held `5`" in it)
    check found.anyIt("`⬜ 5. cga5d baseline`" in it)  # refusal quotes what group held

    # Wake, report of other session and refusal of hook are no message of Architect.
    const notice = "<task-notification>\n<status>completed</status>\n</task-notification>"
    for wake in [
      lineUser(notice, "task-notification"),
      lineUser("Another Claude session sent a message: done.", "peer"),
      lineUser("Stop hook feedback:\nMend message."),
      lineUser("This session is being continued from a previous conversation."),
    ]:
      let woken = (asked & wake & lineAssistant(dropped)).parseTurn
      check woken.signoffs_earlier == @[SIGNOFF]
      check checkSignoffWindow(woken.text, BRANCH, woken.signoffs_earlier, []).len == 1
    check (asked & lineUser("D1 b", "human") & lineAssistant(dropped)).parseTurn
      .signoffs_earlier.len == 0  # message of Architect starts window again

    # Where no entry carries `origin.kind`, window starts with turn, as before field existed.
    check (lineUser("Add the gap list.") & lineAssistant(SIGNOFF) & lineUser(notice) &
      lineAssistant(dropped)).parseTurn.signoffs_earlier.len == 0
    check (lineUser("Add the gap list.") & lineAssistant(SIGNOFF) & linesCall("git push") &
      lineAssistant(dropped)).parseTurn.signoffs_earlier == @[SIGNOFF]

    # Where entries carry `origin.kind` and none is `human`, window holds whole transcript.
    check (lineUser("Add the gap list.", "peer") & lineAssistant(SIGNOFF) &
      lineUser(notice, "task-notification") & lineAssistant(dropped)).parseTurn
      .signoffs_earlier == @[SIGNOFF]

    # Earlier message counts where it holds sign-off outside fence.
    let quoted = lineAssistant("The form:\n\n```md\n" & SIGNOFF & "```\n")
    check (lineUser("Add the gap list.", "human") & quoted & lineAssistant("Pushed.") &
      lineAssistant(dropped)).parseTurn
      .signoffs_earlier.len == 0


  test "group of pull request leaves sign-off once it merges, or once it shows closed (#844)":
    # Merge commit names its pull request on `main`, and close shows on GitHub alone, so group
    #   of closed pull request shows `closed` once, then drops.
    let
      at_pull = SIGNOFF.find("**[The gap list")
      gone = SIGNOFF.replace(SIGNOFF[at_pull ..< SIGNOFF.find("**Outside a pull request.**")], "")
    check checkSignoffWindow(gone, BRANCH, [SIGNOFF], [])
      .messages.anyIt("got none for `#331`" in it and "`⬜ 5. cga5d baseline`" in it)
    for subject in [
      "feat(pga_benchmark): add the gap list (#331)",
      "Merge pull request #331 from mraxilus/contributor/ronri/pga_benchmark/gap-list",
    ]:
      check checkSignoffWindow(gone, BRANCH, [SIGNOFF], [subject]).len == 0
    for subject in [
      "feat(pga_benchmark): add the gap list (#3310)",
      "Merge pull request #33 from mraxilus/x",
      "fix(pga_benchmark): read #331 again",
      "feat(pga_benchmark): (#331) first",
    ]:
      check checkSignoffWindow(gone, BRANCH, [SIGNOFF], [subject]).len == 1
    let
      closed = SIGNOFF.replace("/pull/331), draft", "/pull/331), closed")
      merged = SIGNOFF.replace("/pull/331), draft", "/pull/331), merged")
    check checkSignoffWindow(gone, BRANCH, [closed], []).len == 0
    check checkSignoffWindow(gone, BRANCH, [merged], []).len == 1  # word alone, main holds none


  test "group may not shrink, and fold counts each item that it names (#844)":
    # Item keeps its place when its words change, so count of items, and no match of words,
    #   holds group (Question 2 of #844).
    const three =
      "| ☑️ 1. Draft since it opened, another commit intended | carried 3, #331 draft |\n" &
      "| ✅ 2. Gap list reads each baseline | `koch check` green |\n" &
      "| ✅ 3. A worked example shows the gap rows | carried 5, in the pull request body |\n"
    let
      folded = SIGNOFF.replace(three, "| ☑️ 1–3. Draft, list and example | carried 3 and 5 |\n")
      short = SIGNOFF.replace(three, "| ☑️ 1–2. Draft and list | carried 3 and 5 |\n")
      worded = SIGNOFF.replace("Gap list reads each baseline", "The list holds each baseline")
    check checkSignoffWindow(folded, BRANCH, [SIGNOFF], []).len == 0
    check checkSignoffWindow(short, BRANCH, [SIGNOFF], [])
      .messages.anyIt("got `4` items in `#331`, which held `5`" in it)
    check checkSignoffWindow(worded, BRANCH, [SIGNOFF], []).len == 0
    check checkSignoffWindow(PLAIN, BRANCH, [PLAIN], []).len == 0  # same sign-off again

    # Work outside pull request may not shrink either, and ➖ row names no item.
    let fewer = SIGNOFF
      .replace("| ✅ 7. The request of the curator is answered | carried 2, #330 |\n", "")
      .replace("| ⚠️ 8.", "| ⚠️ 7.").replace("| ➖ 9.", "| ➖ 8.")
      .replace("carried 4:", "carried 2 and 4:")
    check checkSignoff(fewer, BRANCH).messages == newSeq[string]()  # shape holds alone
    check checkSignoffWindow(fewer, BRANCH, [SIGNOFF], [])
      .messages.anyIt("got `2` items in `Outside a pull request.`, which held `3`" in it)
    let applied = SIGNOFF
      .replace("| ➖ 9. Not needed: page link | carried 4: no page changed |\n", "")
      .replace("carried 5, in the pull", "carried 4 and 5, in the pull")
    check checkSignoff(applied, BRANCH).messages == newSeq[string]()
    check checkSignoffWindow(applied, BRANCH, [SIGNOFF], []).len == 0


  test "sign-off is compared with last sign-off of window that passed (#844)":
    # Refused sign-off can lack items, and stop after its refusal passes unread, so replay of
    #   verdicts over window skips it.
    let dropped = SIGNOFF
      .replace("| ⬜ 5. cga5d baseline | this delegate |\n", "")
      .replace("| ☑️ 6.", "| ☑️ 5.").replace("| ✅ 7.", "| ✅ 6.")
      .replace("| ⚠️ 8.", "| ⚠️ 7.").replace("| ➖ 9.", "| ➖ 8.")
    check checkSignoffWindow(SIGNOFF, BRANCH, [SIGNOFF, dropped], []).len == 0
    check checkSignoffWindow(dropped, BRANCH, [SIGNOFF, dropped], []).len == 1
    check checkSignoffWindow(dropped, BRANCH, [], []).len == 0  # first of window
    check checkSignoffWindow(dropped, BRANCH, [FIVE], []).len == 0  # form before #844 reads none
    check checkSignoffWindow(dropped, BRANCH, [FIVE, SIGNOFF], []).len == 1
    let gist = SIGNOFF.replace("**Summary:**", "**Gist:**")
    check checkSignoffWindow(dropped, BRANCH, [gist], []).len == 0  # refused for its shape
    let stuck = SIGNOFF.replace("**State:** blocked", "**State:** stuck")
    check checkSignoffWindow(dropped, BRANCH, [stuck], []).len == 0  # groups read, shape refused
    check checkSignoffWindow(dropped, BRANCH, [dropped, SIGNOFF], []).len == 1  # last, not first

    # Sign-off whose groups do not read takes findings of its shape alone, so group that it holds
    #   is never named as dropped.
    for unread in [gist, SIGNOFF.replace("/pull/331), draft", "/issues/331), draft")]:
      check checkSignoff(unread, BRANCH).len > 0
      check checkSignoffWindow(unread, BRANCH, [SIGNOFF], []).len == 0


  test "group of open pull request comes back past message of Architect (D3 a of #895)":
    # Ruling `D3 a` on #895: short reply of Architect drops no work it has not read, and after
    #   compaction hook alone still reads earlier sign-off. Work outside pull request starts again.
    let
      dropped = SIGNOFF
        .replace("| ⬜ 5. cga5d baseline | this delegate |\n", "")
        .replace("| ☑️ 6.", "| ☑️ 5.").replace("| ✅ 7.", "| ✅ 6.")
        .replace("| ⚠️ 8.", "| ⚠️ 7.").replace("| ➖ 9.", "| ➖ 8.")
      at_pull = SIGNOFF.find("**[The gap list")
      gone = SIGNOFF.replace(SIGNOFF[at_pull ..< SIGNOFF.find("**Outside a pull request.**")], "")
      fewer = SIGNOFF
        .replace("| ✅ 7. The request of the curator is answered | carried 2, #330 |\n", "")
        .replace("| ⚠️ 8.", "| ⚠️ 7.").replace("| ➖ 9.", "| ➖ 8.")
        .replace("carried 4:", "carried 2 and 4:")
      fewest = fewer
        .replace("| ☑️ 6. The answered issue is closed | carried 1, #320 |\n", "")
        .replace("| ⚠️ 7.", "| ⚠️ 6.").replace("| ➖ 8.", "| ➖ 7.")
        .replace("carried 2 and 4:", "carried 1, 2 and 4:")
      asked = lineUser("Add the gap list.", "human") & lineAssistant(SIGNOFF) &
        lineUser("D1 b", "human")
    check checkSignoff(fewest, BRANCH).messages == newSeq[string]()  # shape holds alone

    # Case as found: sign-off after message of Architect drops row of open pull request.
    let turn = (asked & lineAssistant(dropped)).parseTurn
    check turn.signoffs_earlier.len == 0 and turn.signoffs_before == @[@[SIGNOFF]]
    check checkSignoffWindow(turn.text, BRANCH, turn.signoffs_earlier, [], turn.signoffs_before)
      .messages.anyIt("got `4` items in `#331`, which held `5`" in it)

    # Spans: one list for each, oldest first, empty one left out, and one before first message.
    check (asked & lineAssistant(fewer) & lineUser("D1 a", "human") & lineAssistant(dropped))
      .parseTurn.signoffs_before == @[@[SIGNOFF], @[fewer]]
    check (lineUser("Go.", "human") & asked & lineAssistant(dropped)).parseTurn
      .signoffs_before == @[@[SIGNOFF]]
    check (lineUser("Brief.", "peer") & lineAssistant(SIGNOFF) & lineUser("D1 b", "human") &
      lineAssistant(dropped)).parseTurn.signoffs_before == @[@[SIGNOFF]]

    # Group of open pull request comes back past message, and work outside one starts again.
    check checkSignoffWindow(gone, BRANCH, [], [], [@[SIGNOFF]])
      .messages.anyIt("got none for `#331`" in it)
    check checkSignoffWindow(dropped, BRANCH, [], [], [@[SIGNOFF]]).len == 1
    check checkSignoffWindow(fewer, BRANCH, [], [], [@[SIGNOFF]]).len == 0
    check checkSignoffWindow(fewer, BRANCH, [SIGNOFF], []).len == 1  # same span holds it

    # Merge that `main` names, or `closed` shown once, lets group drop past message too.
    const merge = "feat(pga_benchmark): add the gap list (#331)"
    check checkSignoffWindow(gone, BRANCH, [], [merge], [@[SIGNOFF]]).len == 0
    let closed = SIGNOFF.replace("/pull/331), draft", "/pull/331), closed")
    check checkSignoffWindow(gone, BRANCH, [], [], [@[closed]]).len == 0

    # Replay judges each earlier sign-off by rule of its own span: base is last that passed.
    check checkSignoffWindow(dropped, BRANCH, [], [], [@[SIGNOFF], @[dropped]])
      .len == 1  # refused in its span, so no base
    check checkSignoffWindow(dropped, BRANCH, [dropped], [], [@[SIGNOFF]])
      .len == 1  # refused in this span too
    check checkSignoffWindow(fewest, BRANCH, [fewer], [], [@[SIGNOFF]])
      .len == 1  # fewer passed past message, so it is base in its own span
    check checkSignoffWindow(SIGNOFF, BRANCH, [], [], [@[FIVE], @[SIGNOFF]]).len == 0

    # Where no entry carries `origin.kind`, spans cannot be told apart, so turn alone compares.
    let bare = (lineUser("Add the gap list.") & lineAssistant(SIGNOFF) & lineUser("D1 b") &
      lineAssistant(gone)).parseTurn
    check bare.signoffs_earlier.len == 0 and bare.signoffs_before.len == 0
    check checkSignoffWindow(bare.text, BRANCH, bare.signoffs_earlier, [], bare.signoffs_before)
      .len == 0

    # Replay keeps each rule of span: refused sign-off of this span leaves base where it was.
    check checkSignoffWindow(fewer, BRANCH, [SIGNOFF, fewer], []).len == 1
    # One list holds each sign-off of its span, and call of earlier turn is no call of this one.
    check (lineUser("Add the gap list.", "human") & lineAssistant(SIGNOFF) & lineAssistant(fewer) &
      lineUser("D1 b", "human") & lineAssistant(dropped)).parseTurn
      .signoffs_before == @[@[SIGNOFF, fewer]]
    check (lineUser("Add the gap list.", "human") & linesCall("git push") & lineAssistant(SIGNOFF) &
      lineUser("D1 b", "human") & lineAssistant(dropped)).parseTurn
      .calls.len == 0

    # Koch reads subjects of `main` and compares groups only where earlier sign-off exists.
    check not Turn().isSignoffEarlier
    check Turn(signoffs_earlier: @[SIGNOFF]).isSignoffEarlier
    check Turn(signoffs_before: @[@[SIGNOFF]]).isSignoffEarlier  # one before message counts


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
      hooks_script = staticRead("../../../../.claude/hooks.sh")
      stub_nim = "#!/bin/sh\n" &
        "echo \"$*\" >> \"$LOG_BUILDS\"\n" &
        "for a in \"$@\"; do case \"$a\" in -o:*) out=\"${a#-o:}\" ;; esac; done\n" &
        "[ -n \"${out:-}\" ] || exit 1\n" &
        "mkdir -p \"$(dirname \"$out\")\"\n" &
        "printf '#!/bin/sh\\necho \"built from %s\"\\n' \"$(cat koch.nim)\" > \"$out\"\n" &
        "chmod +x \"$out\"\n"
    let
      root = repoTemp()
      toolchain = createTempDir("delegations_", "_nim")
    defer: removeDir(root)
    defer: removeDir(toolchain)
    toolchain.writeInto("0.0.1/bin/nim", stub_nim)
    inclFilePermissions(toolchain / "0.0.1" / "bin" / "nim", {fpUserExec})
    root.writeInto(".claude/hooks.sh", hooks_script)
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


  test "each hook that sees moment of skill names that skill (D2 a of #870)":
    # Description of skill leaves model to notice moment; hook sees it, so names skill.
    let mended = checkNumbersBare("See #12.\n")
    check reasonStop(mended, [], has_signoff = true).splitLines[^1] ==
      "The skill /sign-off holds these steps."
    check "/sign-off" notin reasonStop(mended, [])  # plain message holds no sign-off
    check "/sync" in contextStart("curator/x", "", "", "## List", "", @[finding("", 0, "d")])
    check "/sync" notin contextStart("curator/x", "", "", "## List", "", @[])
    check contextStart(BRANCH, "", "## List\n\n1. one\n", "## List", "", @[]).endsWith(
      "The skill /triage reports each item of this list that is not met.")
    check "/propose-term" in contextEdit("contributor/ronri/pga_benchmark/GLOSSARY.md")
    check "/propose-term" in contextEdit("GLOSSARY.md")
    check "/record" in contextEdit("curator/audit/PROVENANCE.md")
    check contextEdit("README.md").len == 0


  test "edit hook names held findings apart from those to fix before push":
    # Case as found: curator edits contributor record where check that landed left finding;
    #   held finding blocks no push, and duty 3 forbids curator to fix it.
    let
      path = "contributor/ronri/alpha/README.md"
      own = finding(path, 3, "Own.")
      held = finding(path, 5, "Held.")
    check contextFindings(path, [held], [own]).splitLines == @[
      "koch check-files reports 1 finding(s) in `" & path & "`; fix before push:",
      path & ":3: Own.",
      "koch check-files holds 1 finding(s) in `" & path & "` for its project, which clears " &
        "them in its next pull request (CURATOR.md, duty 3):",
      path & ":5: Held.",
    ]
    check "fix before push" notin contextFindings(path, [held], [])
    check contextFindings(path, [], []).len == 0


  test "prompt names skill whose moment message of Architect holds, and none otherwise":
    for ruling in ["D1 a", "a", "D1 a, D2 b", "D1a", "D2 what does a mean?"]:
      check "/rule" in contextPrompt(ruling)
    for asking in ["status", "Recheck the status of everything", "tell me the merge order",
        "check your duties", "Anything left on your plate?", "Update the list"]:
      check "/triage" in contextPrompt(asking)
    check "/merged" in contextPrompt("trackball merged")
    let both = contextPrompt("Merged some, update the list")
    check "/merged" in both and "/triage" in both
    for plain in ["why is capnproto excluded?", "Is decide already a skill", "yes, build it"]:
      check contextPrompt(plain).len == 0


  test "prompt reads no notice of harness, which opens with tag, as message of Architect":
    # End of background task arrives as prompt that holds `<status>completed</status>`, whose
    #   word `status` would name `/triage` on each such notice.
    const notice = "<task-notification>\n<task-id>b1</task-id>\n<status>completed</status>\n" &
      "<summary>Background command \"Wait for the run\" completed</summary>\n</task-notification>"
    check contextPrompt(notice).len == 0
    check contextPrompt("  \n<system-reminder>\nPR merged; update the list\n</system-reminder>")
      .len == 0
    check "/triage" in contextPrompt("status <- this one")  # message that opens with words


  test "model turn ends where model stops, and user entry of text inside it opens none (#962)":
    # Case as found in transcript of delegate on #962: body of skill arrives as `user` entry of
    #   text after `Skill` call whose message stops for `tool_use`, and model goes on; so do
    #   summary of compaction and notice of restart. `parseTurn` reads each as message of person.
    let
      skill = $(%*{"type": "user", "isMeta": true, "message": {"content": [
        {"type": "text", "text": "Base directory for this skill: /x"},
      ]}}) & "\n"
      split = lineUser("Rule.", "human") & linesCall("ls") & skill & linesAgent("builder") &
        lineSaid("Started.") & lineUser("Next.", "human") & linesAgent("reviewer") &
        lineSaid("Done.")
      subagents = split.parseTurn.subagents
    check subagents.turns == 2
    check subagents.calls.mapIt(it.place.turn) == @[0, 1]  # body of skill opens no turn
    check subagents.texts.mapIt(it.turn) == @[0, 1]

    # Each stop reason but `tool_use` ends turn; entry with none ends none.
    for reason in ["end_turn", "max_tokens", "stop_sequence", "refusal", "pause_turn"]:
      check (lineSaid("One.", reason) & lineSaid("Two.")).parseTurn.subagents.turns == 2
    check (lineSaid("One.", "tool_use") & lineSaid("Two.")).parseTurn.subagents.turns == 1
    check (lineAssistant("One.") & lineSaid("Two.")).parseTurn.subagents.turns == 1

    # Reason that is no string, as JSON `null`, ends no turn either.
    for reason in [newJNull(), %1, %true, %*["end_turn"], %*{"type": "end_turn"}]:
      let entry = %*{"type": "assistant", "message": {
        "content": [{"type": "text", "text": "One."}]
      }}
      entry["message"]["stop_reason"] = reason
      check ($entry & "\n" & lineSaid("Two.")).parseTurn.subagents.turns == 1

    # Entries of one message end one turn, at its last entry, as harness writes each item apart.
    func lineItem(message: string, item: JsonNode): string =
      ## Write transcript line of entry of message holding item, which stops for `end_turn`.
      $(%*{"type": "assistant", "message": {
        "id": message, "content": [item], "stop_reason": "end_turn",
      }}) & "\n"
    let
      thought = %*{"type": "thinking", "thinking": ""}
      said = %*{"type": "text", "text": "Said."}
    check (lineItem("m1", thought) & lineItem("m1", said) & lineSaid("Next.")).parseTurn
      .subagents.turns == 2
    check (lineItem("m0", thought) & lineItem("m1", said) & lineSaid("Next.")).parseTurn
      .subagents.turns == 3

    # End of last message closes current turn, and opens none.
    check lineSaid("Only.").parseTurn.subagents.turns == 1
    check (lineSaid("Only.") & lineUser("Queued.")).parseTurn.subagents.turns == 1
    check "".parseTurn.subagents.turns == 1


  test "block is `## Prediction` outside fence, to next heading of level 1 or 2 (#962)":
    proc blocks(texts: varargs[string]): seq[string] =
      ## Read text of each prediction block of one assistant entry, holding texts as its items.
      let entry = %*{"type": "assistant", "message": {
        "content": texts.mapIt(%*{"type": "text", "text": it}), "stop_reason": "end_turn",
      }}
      ($entry & "\n").parseTurn.subagents.predictions.mapIt(it.text)

    check blocks("Intro.\n\n## Prediction\n\n- a (70%).\n\n## Next\n\nb") == @["\n- a (70%).\n"]
    check blocks("  ## Prediction  \n- a\n# Title\nb") == @["- a"]  # strip; level 1 ends it
    check blocks("## Prediction\n- a\n**Working:** a timer wakes me.\n- b") == @["- a"]
    check blocks("## Prediction\n- a\n### Basis\n- b\n#962 holds\n- c") ==
      @["- a\n### Basis\n- b\n#962 holds\n- c"]  # deeper heading and `#962` end nothing
    check blocks("## Prediction\n- a\n## Prediction\n- b") == @["- a", "- b"]
    check blocks("## Prediction\n- a", "- b") == @["- a"]  # item ends its own block
    check blocks("## Prediction\n- a\n```\n## Next\n```\n- b") == @["- a\n\n\n\n- b"]
    check blocks("Sample:\n\n```md\n## Prediction\n- a\n```\n").len == 0  # quoted in fence
    check blocks("Sample:\n\n```md", "## Prediction\n- a\n```").len == 0  # fence crosses items
    for heading in ["### Prediction", "## Predictions", "## Prediction:", "**Prediction**"]:
      check blocks(heading & "\n- a").len == 0
    check blocks("~~~\n## Prediction\n- a\n~~~") == @["- a\n~~~"]  # cost: tilde fence is text
    check blocks("    ## Prediction\n- a") == @["- a"]  # cost: indented code is text


  test "call of kind takes block of model turn before its own, which starts no subagent (#962)":
    # Ruling 6980006567: prediction is last message of turn of its own, timer wakes delegate, and
    #   next turn starts subagent. `D2 a` of 6982373798: block serves only from turn that starts
    #   no subagent. D1 c of #969 replaces its limit to next turn (test below).
    let
      asked = lineUser("Build the check.", "human")
      read = lineSaid("Read.")
      wake = lineUser("<task-notification>timer</task-notification>", "task-notification")
      started = lineSaid("Started.")
    check blocksHeld(asked & lineSaid(PREDICTION) & wake & linesAgent("builder") & started)
      .len == 0

    # Missing prediction names call, and asks for no block (6979936148).
    let missing = blocksHeld(asked & read & wake & linesAgent("builder", "Build it") & started)
    check missing.len == 1 and missing[0].endsWith("got none for `builder` call `Build it`.")

    # Block in turn of call, and block in thinking, each add their hint (`D3 a` of 6982373798).
    for before in [asked, asked & read & wake]:
      let inside = blocksHeld(before & lineSaid(PREDICTION, "tool_use") & linesAgent("builder") &
        started)
      check inside.len == 1 and inside[0].endsWith("block stands in earlier turn.")
    for kind in ["thinking", "redacted_thinking"]:
      let thought = blocksHeld(asked & read & wake & lineThought(kind) & linesAgent("builder") &
        started)
      check thought.len == 1 and thought[0].endsWith("reaches neither chat nor hook.")
    check blocksHeld(asked & read & wake & lineThought() & lineSaid("Now.", "tool_use") &
      linesAgent("builder") & started).allIt("thinking" notin it)  # text before call

    # Block or thinking after call, in its turn, adds no hint, since each hint reads what stands
    #   before call.
    for after in [lineSaid(PREDICTION, "tool_use"), lineThought()]:
      let late = blocksHeld(asked & read & wake & linesAgent("builder") & after & started)
      check late == @["Call of subagent of kind takes `## Prediction` block of model turn before " &
        "its own, and after each earlier turn that starts subagent (GUIDE.md, Prediction, " &
        "critic and reflection); got none for `builder` call `Do the work`."]

    # Block in turn that starts subagent of any type is no evidence, though it names kind of call;
    #   block two turns back is, since D1 c of #969 (test below).
    check blocksHeld(asked & lineSaid(PREDICTION) & wake & lineSaid("Waiting.") & wake &
      linesAgent("builder") & started).len == 0
    for kind in ["web-fetch", "builder"]:
      check blocksHeld(asked & linesAgent(kind) & lineSaid(predicting("reviewer")) & wake &
        linesAgent("reviewer") & started).anyIt("`reviewer`" in it)

    # One block serves one call, earliest call of its kind first; call of other kind takes block
    #   that names its kind, and exempt call takes only block of its own kind (7017187857).
    let two = blocksHeld(asked & lineSaid(PREDICTION) & wake & linesAgent("builder") &
      linesAgent("reviewer") & started)
    check two.len == 1 and "`reviewer`" in two[0]
    check blocksHeld(asked & lineSaid(PREDICTION) & wake & linesAgent("builder", "First") &
      linesAgent("builder", "Second") & started) == @[refusalCall("builder", "Second")]
    check blocksHeld(asked & lineSaid(PREDICTION & "\n" & predicting("reviewer")) & wake &
      linesAgent("builder") & linesAgent("reviewer") & started).len == 0
    check blocksHeld(asked & lineSaid(PREDICTION) & wake & linesAgent("critic") &
      linesAgent("builder") & started).len == 0

    # Each call takes earliest free block of turn before: of n blocks and m calls, blocks after
    #   first m are taken by no call, so cell that quotes one of them is finding, in text of
    #   D5 b of #969.
    const header = "| State | Confidence | Predicted | Result |\n| --- | --- | --- | --- |\n"
    for n in 1 .. 3:
      for m in 1 .. n:
        var blocks, rows: seq[string]
        for b in 1 .. n:
          blocks.add "## Prediction\n\n**Subagent:** builder of claim " & $b &
            ".\n\n- Judgement: claim " & $b & " holds (70%)."
          rows.add "| ✅ | 70% | claim " & $b & " holds | it holds |"
        let found = blocksHeld(asked & lineSaid(blocks.join("\n\n")) & wake &
          linesAgent("builder").repeat(m) & started & lineHandback("builder", "abuilder") &
          linesAgent("critic") & lineSaid("The critic runs.") & lineHandback("critic") &
          lineSaid("## Reflection\n\n" & header & rows.join("\n") & "\n"))
        check found == toSeq(m + 1 .. n).mapIt(refusalCell("claim " & $it & " holds"))

    # Kinds `critic` and `resolver` are exempt, named here and not read from code; each other
    #   kind is held.
    for kind in ["critic", "resolver"]:
      check blocksHeld(asked & read & wake & linesAgent(kind) & started).len == 0
    for kind in ["builder", "reviewer"]:
      check blocksHeld(asked & read & wake & linesAgent(kind) & started).len == 1

    # Each other kind of this repository is held, so no kind joins exempt kinds in silence, as
    #   critic of fixes on #962 found for `surveyor`.
    let repository = readKinds(currentSourcePath().parentDir / "../../../..")
    var held = 0
    for kind in repository:
      if kind notin ["critic", "resolver"]:
        check blocksHeld(asked & read & wake & linesAgent(kind) & started, repository).len == 1
        inc held
    check held >= 1  # loop holds at least one kind

    # Type no template names is tool use; with no folder, no type is kind.
    for kind in ["general-purpose", "web-fetch", "Explore"]:
      check blocksHeld(asked & read & wake & linesAgent(kind) & started).len == 0
    check blocksHeld(asked & read & wake & linesAgent("builder") & started, []).len == 0

    # Call of such type takes no block, so later call of kind in its turn takes it, as critic of
    #   hook on #962 found for `web-fetch` in foreground.
    for kind in ["general-purpose", "web-fetch", "Explore"]:
      check blocksHeld(asked & lineSaid(predicting("reviewer")) & wake &
        linesForeground(kind, "false", "completed") & linesAgent("reviewer") & started).len == 0

    # Call of earlier turn was held at its own stop.
    check blocksHeld(asked & read & wake & linesAgent("builder") & started &
      lineUser("Thanks.", "human") & lineSaid("Noted.")).len == 0


  test "block serves later call across turns that start no subagent (D1 c of #969)":
    # Ruling 7014974932, D1 c of #969: block of prediction serves later call of subagent, where no
    #   subagent starts between them, whatever count of turns between; hook looks back from turn
    #   of call, past each turn that starts no subagent. Ruling replaces limit to next turn of
    #   `D2 a` of 6982373798, and block in turn of its call stays no evidence. Cases as found are
    #   those D1 of #969 asks about: reply to refusal, and wake by hand-back or by message of
    #   Architect, between block and call.
    const
      header = "| State | Confidence | Predicted | Result |\n| --- | --- | --- | --- |\n"
      refused = "got none for `reviewer` call `Do the work`."
    let
      asked = lineUser("Review the diff.", "human")
      wake = lineUser("<task-notification>timer</task-notification>", "task-notification")
      started = lineSaid("Started.")
      refusal = lineUser("Stop hook feedback:\nMend message that ends this turn.") &
        $(%*{"type": "attachment", "attachment": {"type": "hook_blocking_error"}}) & "\n"
      reply = refusal & lineSaid("```diff\n- see #964\n+ see [the log (#964)](x)\n```")
      handback = lineHandback("builder", "abuilder") & lineSaid("The builder reported.")
      message = lineUser("Is the reviewer running?", "human") & lineSaid("Not yet.")
      waited = wake & lineSaid("Waiting.")
      called = wake & linesAgent("reviewer") & started
      predicted = predicting("reviewer")  # Block that names kind of call, as 7017187857 asks.
    for between in [reply, handback, message]:
      check blocksHeld(asked & lineSaid(predicted) & between & called).len == 0

    # Block serves call at each count of turns between them, and across each kind of turn at once.
    for count in 0 .. 4:
      check blocksHeld(asked & lineSaid(predicted) & waited.repeat(count) & called).len == 0
    check blocksHeld(asked & lineSaid(predicted) & reply & handback & message & waited & called)
      .len == 0

    # Call of any type between them ends turns hook looks back over, so block left over serves no
    #   later call: kind, exempt kind and type no template names, in background or foreground.
    for kind in ["builder", "critic", "resolver", "web-fetch", "general-purpose"]:
      for between in [linesAgent(kind), linesForeground(kind, "false", "completed")]:
        let found = blocksHeld(asked & lineSaid(predicted & "\n" & predicted) & wake & between &
          started & called)
        check found.len == 1 and found[0].endsWith(refused)

    # Block in turn that starts subagent, before or after its call, is no evidence, and adds no
    #   hint; block in turn of call adds its hint, after turns with no block.
    for kind in ["builder", "web-fetch"]:
      for earlier in [lineSaid(predicted, "tool_use") & linesAgent(kind),
          linesAgent(kind) & lineSaid(predicted, "tool_use")]:
        check blocksHeld(asked & earlier & started & waited & called) == @["Call of subagent of " &
          "kind takes `## Prediction` block of model turn before its own, and after each " &
          "earlier turn that starts subagent (GUIDE.md, Prediction, critic and reflection); " &
          "got none for `reviewer` call `Do the work`."]
    let inside = blocksHeld(asked & lineSaid(predicted) & wake & linesAgent("web-fetch") &
      started & waited & wake & lineSaid(predicted, "tool_use") & linesAgent("reviewer") & started)
    check inside.len == 1 and inside[0].endsWith("block stands in earlier turn.")

    # Each call takes block of nearest of turns hook looks back over (7017187857): of n blocks,
    #   one in each turn, and m calls, blocks before last m are taken by no call.
    for n in 1 .. 3:
      for m in 1 .. n:
        var turns, rows: seq[string]
        for b in 1 .. n:
          turns.add lineSaid("## Prediction\n\n**Subagent:** builder of claim " & $b &
            ".\n\n- Judgement: claim " & $b & " holds (70%).")
          rows.add "| ✅ | 70% | claim " & $b & " holds | it holds |"
        let found = blocksHeld(asked & turns.join(wake) & wake &
          linesAgent("builder").repeat(m) & started & lineHandback("builder", "abuilder") &
          linesAgent("critic") & lineSaid("The critic runs.") & lineHandback("critic") &
          lineSaid("## Reflection\n\n" & header & rows.join("\n") & "\n"))
        check found == toSeq(1 .. n - m).mapIt(refusalCell("claim " & $it & " holds"))

    # Calls of one turn share turns hook looks back over, and each takes block that names its
    #   kind; exempt call takes only block of its own kind, and none ahead of other calls.
    check blocksHeld(asked & lineSaid(PREDICTION) & waited & wake & lineSaid(predicted) & wake &
      linesAgent("critic") & linesAgent("builder") & linesAgent("reviewer") & started).len == 0
    let short = blocksHeld(asked & lineSaid(PREDICTION) & waited & wake & linesAgent("critic") &
      linesAgent("builder") & linesAgent("reviewer") & started)
    check short.len == 1 and short[0].endsWith(refused)

    # Reflection quotes block that call took across turns, and block of earlier call stays taken
    #   once later call starts.
    let flow = asked & lineSaid(PREDICTION) & reply & message & wake & linesAgent("builder") &
      started & lineHandback("builder", "abuilder") & linesAgent("critic") &
      lineSaid("The critic runs.") & lineHandback("critic")
    check blocksHeld(flow & lineSaid(REFLECTION)).len == 0

    # Block that reply to refusal writes again serves call, since call takes block of nearest
    #   turn (7017187857), so reflection quotes block as written again, and not as first written.
    let mended = asked & lineSaid(PREDICTION) & refusal &
      lineSaid(PREDICTION.replace("four to eight", "five to nine")) & wake &
      linesAgent("builder") & started & lineHandback("builder", "abuilder") &
      linesAgent("critic") & lineSaid("The critic runs.") & lineHandback("critic")
    check blocksHeld(mended & lineSaid(REFLECTION.replace("four to eight", "five to nine")))
      .len == 0
    check blocksHeld(mended & lineSaid(REFLECTION)) ==
      @[refusalCell("four to eight findings, each with `file:line`")]


  test "block serves only call of kind it names, nearest turn first (7017187857 of #969)":
    # Ruling 7017187857 of #969, how block pairs: block serves only call of kind that its
    #   `**Subagent:**` line names, as `**Subagent:** reviewer of …`, so late block for reviewer
    #   serves no builder and no critic; it replaces pairing by order alone. Same comment, which
    #   block: where turns before call hold more than one free block for it, call takes block of
    #   nearest earlier turn, and earliest block inside that turn; it replaces "earliest" of
    #   ruling on timer (6980006567). Cases as found are probes of critic of D1 c of #969, where
    #   build `61233948` refused Q1, which keeps guide, and passed Q2 and Q3, whose block was
    #   written after call it names.
    const
      header = "| State | Confidence | Predicted | Result |\n| --- | --- | --- | --- |\n"
      layouts = 48
        ## Cases of law of nearest turn: each layout of one or two blocks to turn, over two or
        ##   three turns, with each count of calls up to count of blocks.
    func predictedProbe(kind, claim: string): string =
      ## Write block of probe for subagent of kind, holding one claim, with its working line.
      "## Prediction\n\n**Subagent:** " & kind & " of the fix, fresh context.\n**Basis:** what " &
        "this delegate knows, with no new read.\n\n- Judgement: " & claim & " (60%). " &
        "Resolution criterion: the report says so.\n\n**Working:** a timer of 5 seconds wakes " &
        "this delegate, and the next turn starts it."

    func reflectedProbe(cells: varargs[string]): string =
      ## Write reflection of probe, whose rows hold cells under `Predicted`.
      "## Reflection\n\n**Subagent:** builder, 170,000 tokens and $1.10 at list price, 57 " &
        "calls, 15 min.\n**Critic:** 50,000 tokens and $0.35 at list price, 20 calls, 6 min." &
        "\n\n" & header & cells.mapIt("| ✅ | 60% | " & it & " | it holds |").join("\n") &
        "\n\n- **Cause of each miss:** none.\n- **Change:** none."

    func named(kind, claim: string): string =
      ## Write block for subagent of kind, holding one claim.
      "## Prediction\n\n**Subagent:** " & kind & " of the fix.\n\n- Judgement: " & claim & " (70%)."

    let
      timer = linesCall("sleep 5")
      wake = lineUser("<task-notification>timer</task-notification>", "task-notification")
      ran = lineSaid("It runs.\n\n**Working:** the subagent runs, and its report wakes this " &
        "delegate.")
      review = lineUser("Review the diff of curator/asset-fetch.", "human")
      build = lineUser("Build the fix of curator/asset-fetch.", "human")
      checked = linesAgent("critic", "Critic of the fix") & ran & lineHandback("critic", "acritic")

    # Q1: block for reviewer, then plan changes, and block for builder stands in turn just before
    #   its call, as guide asks; builder takes its own block, and reflection that quotes it passes.
    let guided = review & timer &
      lineSaid(predictedProbe("reviewer", "the reviewer finds no race")) &
      lineUser("Build the fix first, then review it.", "human") & timer &
      lineSaid(predictedProbe("builder", "the builder adds two commits")) & wake &
      linesAgent("builder", "Build the fix") & ran & lineHandback("builder", "abuilder") & checked &
      lineSaid(reflectedProbe("the builder adds two commits"))
    check blocksHeld(guided).len == 0

    # Q2: block for reviewer, written after its call, serves no later builder; hint names kind of
    #   block.
    let late = review & linesAgent("reviewer", "Review the fix") & ran &
      lineUser("Where is the prediction?", "human") &
      lineSaid(predictedProbe("reviewer", "the reviewer finds no race")) &
      lineHandback("reviewer", "areviewer") & lineSaid("The reviewer reported.") &
      lineUser("Go on.", "human") & linesAgent("builder", "Build the fix") & ran
    check blocksHeld(late) == @[refusalCall("builder", "Build the fix", hintNamed("`reviewer`"))]

    # Q3: block for reviewer, written after its report, serves no critic, so reflection that
    #   quotes it is refused.
    let hindsight = review & linesAgent("reviewer", "Review the fix") & ran &
      lineHandback("reviewer", "areviewer") &
      lineSaid(predictedProbe("reviewer", "the reviewer finds no race")) &
      lineUser("Run the critic.", "human") & lineSaid("Noted.") & wake & checked &
      lineSaid(reflectedProbe("the reviewer finds no race"))
    check blocksHeld(hindsight) == @[refusalCell("the reviewer finds no race")]

    # Q4: optional block of critic, written after report of builder, serves critic called two
    #   turns later, as break Z2 of critic of D1 c asks.
    let optional = build & timer &
      lineSaid(predictedProbe("builder", "the builder adds two commits")) & wake &
      linesAgent("builder", "Build the fix") & ran & lineHandback("builder", "abuilder") & timer &
      lineSaid(predictedProbe("critic", "the critic fails one claim")) &
      lineUser("Is the critic running?", "human") & lineSaid("Not yet.") & wake & checked &
      lineSaid(reflectedProbe("the builder adds two commits", "the critic fails one claim"))
    check blocksHeld(optional).len == 0

    # Block six or more turns back serves its call, as break Z1 of critic of D1 c asks.
    for count in 5 .. 8:
      check blocksHeld(build & timer & lineSaid(predictedProbe("builder", "it holds")) &
        (wake & lineSaid("Waiting.")).repeat(count) & wake &
        linesAgent("builder", "Build the fix") & ran).len == 0

    # Three groups of calls: block for reviewer before call of `web-fetch` serves no later
    #   reviewer, as break Z3 of critic of D1 c asks.
    let grouped = build & timer &
      lineSaid(predictedProbe("builder", "the builder adds two commits")) & wake &
      linesAgent("builder", "Build the fix") & ran & lineHandback("builder", "abuilder") & timer &
      lineSaid(predictedProbe("reviewer", "the reviewer finds no race")) & wake &
      linesAgent("web-fetch", "Read the page") & lineSaid("Fetched.") &
      lineUser("Go on.", "human") & linesAgent("reviewer", "Review the fix") & ran
    check blocksHeld(grouped) == @[refusalCall("reviewer", "Review the fix")]

    # Cost, probe Q5: call that harness rejects starts no subagent, yet takes block and ends turns
    #   that later call looks back over, so its retry is refused.
    let
      rejection = $(%*{"type": "assistant", "message": {"content": [{
        "type": "tool_use", "id": "toolu_rejected", "name": "Agent",
        "input": {"subagent_type": "builder", "description": "Build the fix", "prompt": "Do it."},
      }], "stop_reason": "tool_use"}}) & "\n" & $(%*{"type": "user", "message": {"content": [{
        "type": "tool_result", "tool_use_id": "toolu_rejected", "is_error": true,
        "content": "The tool use was rejected.",
      }]}, "toolUseResult": "Error: The tool use was rejected."}) & "\n"
      rejected = build & timer &
        lineSaid(predictedProbe("builder", "the builder adds two commits")) & wake & rejection &
        lineSaid("The call was rejected.") & lineUser("Try again.", "human") &
        linesAgent("builder", "Build the fix") & ran
    check blocksHeld(rejected) == @[refusalCall("builder", "Build the fix")]

    # Kind is first word after `**Subagent:**` on first line of block that opens with it, after
    #   any indent, as written up to whitespace; block with no such line, or whose word is no
    #   kind, names no kind and serves no call, and hint says so.
    proc heldAfter(text: string, kinds: openArray[string] = KINDS): seq[string] =
      ## Read findings of builder call after block that holds text, then one claim, in turn
      ##   before its own.
      blocksHeld(build & lineSaid("## Prediction\n\n" & text & "\n\n- Judgement: it builds " &
        "(70%).") & wake & linesAgent("builder", "Build the fix") & ran, kinds)

    for text in ["**Subagent:** builder of the fix.", "  **Subagent:** builder of the fix.",
        "**Subagent:**  builder\tof the fix.", "**Subagent:** builder",
        "**Basis:** none.\n**Subagent:** builder of the fix.",
        "- Judgement: it is first (70%).\n\n**Subagent:** builder of the fix.",
        "**Subagent:** builder of the fix.\n**Subagent:** reviewer of the diff."]:
      check heldAfter(text).len == 0
    check heldAfter("**Subagent:** reviewer of the diff.\n**Subagent:** builder of the fix.") ==
      @[refusalCall("builder", "Build the fix", hintNamed("`reviewer`"))]  # first line alone
    for text in ["**Basis:** what this delegate knows.", "**Subagent:**",
        "**Subagent:** Builder of the fix.", "**Subagent:** the builder of the fix.",
        "**Subagent:** `builder` of the fix.", "**Subagent:** builder, fresh context.",
        "**Subagent:** surveyor of the fix.", "**Subagent:** web-fetch of the page.",
        "Subagent: builder of the fix.", "**Subagent** builder of the fix.",
        "- **Subagent:** builder of the fix.", "The **Subagent:** builder of the fix.",
        "```\n**Subagent:** builder of the fix.\n```"]:
      check heldAfter(text) == @[refusalCall("builder", "Build the fix", hintNamed("no kind"))]
    let repository = readKinds(currentSourcePath().parentDir / "../../../..")
    check heldAfter("**Subagent:** surveyor of the fix.", repository) ==
      @[refusalCall("builder", "Build the fix", hintNamed("`surveyor`"))]  # kind of templates

    # Hint names what nearest free block names, earliest first inside its turn; it stands where
    #   no call took that block, inside turns call looks back over, and hint of turn of call
    #   follows it.
    let nameless = "## Prediction\n\n- Judgement: it builds (70%)."
    check blocksHeld(build & lineSaid(predicting("reviewer")) & wake &
      lineSaid(predicting("critic") & "\n" & nameless) & wake &
      linesAgent("builder", "Build the fix") & ran) ==
      @[refusalCall("builder", "Build the fix", hintNamed("`critic`"))]
    check blocksHeld(build & lineSaid(predicting("reviewer")) & wake &
      lineSaid(nameless & "\n\n" & predicting("critic")) & wake &
      linesAgent("builder", "Build the fix") & ran) ==
      @[refusalCall("builder", "Build the fix", hintNamed("no kind"))]
    check blocksHeld(build & lineSaid(predicting("reviewer")) & wake & linesAgent("reviewer") &
      linesAgent("builder", "Build the fix") & ran) == @[refusalCall("builder", "Build the fix")]
    check blocksHeld(build & lineSaid(predicting("reviewer")) & wake & linesAgent("web-fetch") &
      ran & wake & linesAgent("builder", "Build the fix") & ran) ==
      @[refusalCall("builder", "Build the fix")]
    check blocksHeld(build & lineSaid(predicting("reviewer")) & wake &
      lineSaid(PREDICTION, "tool_use") & linesAgent("builder", "Build the fix") & ran) ==
      @[refusalCall("builder", "Build the fix", hintNamed("`reviewer`") & ", and block in turn " &
        "of call, which is no evidence: block stands in earlier turn")]

    # Exempt call takes only block of its own kind; call of type no template names, or of no
    #   type, takes none, though block names no kind, so reflection quotes none of it.
    for (prediction, count) in [(predicting("resolver"), 0), (PREDICTION, 2)]:
      check blocksHeld(review & lineSaid(prediction) & wake & linesAgent("resolver") & ran &
        checked & lineSaid(REFLECTION)).len == count
    for kind in ["", "web-fetch"]:
      check blocksHeld(review & lineSaid(nameless) & wake & linesAgent(kind) & ran & checked &
        lineSaid(reflectedProbe("it builds"))) == @[refusalCell("it builds")]

    # Calls of two kinds in one turn each take block of own kind from nearest turn, in either
    #   order of calls, so claims of blocks of farther turn are refused.
    for calls in [@["reviewer", "builder"], @["builder", "reviewer"]]:
      check blocksHeld(review &
        lineSaid(named("builder", "b0") & "\n\n" & named("reviewer", "r0")) & wake &
        lineSaid(named("reviewer", "r1") & "\n\n" & named("builder", "b1")) & wake &
        calls.mapIt(linesAgent(it)).join & ran & checked & lineSaid("## Reflection\n\n" & header &
        ["b0", "r0", "r1", "b1"].mapIt("| ✅ | 70% | " & it & " | it holds |").join("\n") & "\n")) ==
        @[refusalCell("b0"), refusalCell("r0")]

    # Each layout of one or two blocks to turn, over two and three turns: m calls of one kind in
    #   one turn take first m blocks, nearest turn first and earliest first inside it, and claim
    #   of each other block is refused.
    var cases = 0
    for turns in 2 .. 3:
      for mask in 0 ..< (1 shl turns):  # Turn `t` holds two blocks where bit `t` is set.
        var
          texts: seq[string]  # Blocks of each turn, earliest turn first.
          numbers: seq[seq[int]]  # Number of each block of each turn, from 1.
          count = 0
        for t in 0 ..< turns:
          var blocks: seq[string]
          numbers.add @[]
          for _ in 0 .. (mask shr t and 1):
            inc count
            numbers[^1].add count
            blocks.add named("builder", "claim " & $count & " holds")
          texts.add blocks.join("\n\n")
        var order: seq[int]  # Numbers of blocks, nearest turn first, earliest first inside it.
        for t in countdown(turns - 1, 0): order.add numbers[t]
        let rows = toSeq(1 .. count).mapIt("| ✅ | 70% | claim " & $it & " holds | it holds |")
        for m in 1 .. count:
          let found = blocksHeld(build & texts.mapIt(lineSaid(it)).join(wake) & wake &
            linesAgent("builder").repeat(m) & ran & lineHandback("builder", "abuilder") &
            checked & lineSaid("## Reflection\n\n" & header & rows.join("\n") & "\n"))
          check found == toSeq(1 .. count).filterIt(it notin order[0 ..< m])
            .mapIt(refusalCell("claim " & $it & " holds"))
          inc cases
    check cases == layouts


  test "kinds are names of front matter of templates under `.claude/agents`, read at stop":
    # No suite runs `main` of koch, so read is held here, over scratch root.
    let root = createTempDir("delegations_", "_kinds")
    defer: removeDir(root)
    check readKinds(root).len == 0  # missing folder gives no kinds
    let agents = root / DIRECTORY_AGENTS
    createDir(agents)
    writeFile(agents / "builder.md", "---\nname: builder\nmodel: opus\n---\n\nYou are.\n")
    writeFile(agents / "critic.md", "---\ndescription: Check.\nname: \"critic\"\n---\n")
    writeFile(agents / "notes.txt", "---\nname: notes\n---\n")  # no template
    writeFile(agents / "draft.md", "name: draft\n")  # no front matter
    writeFile(agents / "late.md", "---\nmodel: opus\n---\nname: late\n")  # name below matter
    writeFile(agents / "nested.md", "---\nmetadata:\n  name: nested\n---\n")  # name of inner map
    check readKinds(root) == @["builder", "critic"]

    # Each exempt kind is template of this repository, so no rename leaves it dead.
    let repository = readKinds(currentSourcePath().parentDir / "../../../..")
    check KINDS_EXEMPT.allIt(it in repository) and "builder" in repository


  test "refusal of blocks takes part of its own after diff and queue, and asks no diff (#962)":
    # Ruling 6979936148: reply names missing prediction as miss, and no block follows call.
    let
      blocks = @[finding("", 0, "Call of `builder`.")]
      alone = reasonStop([], [], blocks = blocks)
      every = reasonStop(
        checkNumbersBare("See #12.\n"), checkSignoffRead(PLAIN, []), has_signoff = true,
        blocks = blocks,
      )
    check alone.splitLines == @[LINE_BLOCKS, "Call of `builder`."]
    check "Reply with a diff" notin alone and "write no block for it" in alone
    check every.startsWith("Mend message") and every.find("Read queue") < every.find(LINE_BLOCKS)
    check every.splitLines[^1] == LINE_SIGNOFF


  test "report of critic takes reflection of its own after it, above any sign-off (#962)":
    # Ruling 6974524232: turn that receives report of critic holds `## Reflection` block, before
    #   any sign-off or working line. Shapes of report are those transcript of delegate on #962
    #   holds, and result of call in foreground, which harness gave its call of `web-fetch`.
    let
      taken = lineUser("Build the check.", "human") & lineSaid(PREDICTION) &
        lineUser("<task-notification>timer</task-notification>", "task-notification") &
        linesAgent("builder") & lineSaid("Started.") & lineHandback("builder", "abuilder") &
        linesAgent("critic") & lineSaid("The critic runs.")
      read = lineSaid("Read.")
      reflected = lineSaid(REFLECTION)
      report = lineHandback("critic")
      queued = lineUser("Next.", "human") & linesCall("ls") & lineQueued("critic")
    for shape in [report, linesForeground("critic", "false", "completed"), queued]:
      check blocksHeld(taken & shape & read) ==
        @["Report of critic takes `## Reflection` block of its own after it, above any " &
          "sign-off or working line (GUIDE.md, Prediction, critic and reflection); got none " &
          "for report `1` of `1` in this turn."]
      check blocksHeld(taken & shape & reflected).len == 0

    # Hand-back of other kind, entry that is no hand-back, launch notice and result of call in
    #   background each are no report.
    for other in [lineHandback("builder"), lineHandback("critic", is_handback = false),
        lineQueued("builder"), linesForeground("critic", "false", "async_launched"),
        linesForeground("critic", "true", "completed"), linesForeground("critic", "", "completed"),
        linesForeground("web-fetch", "false", "completed")]:
      check blocksHeld(taken & other & read).len == 0

    # Attachment of type other than `queued_command` is no report, whatever its origin.
    for kind in ["hook_blocking_error", "task_reminder", "hook_additional_context"]:
      let attached = $(%*{"type": "attachment", "attachment": {"type": kind, "origin": {
        "kind": "peer", "from": "a1", "name": "critic", "handback": true,
      }}}) & "\n"
      check blocksHeld(taken & attached & read).len == 0

    # Result whose agent sends later hand-back points at it, so two entries make one report.
    let pointed = taken & linesForeground("critic", "false", "completed", "a9") &
      lineHandback("critic", "a9")
    check blocksHeld(pointed & reflected).len == 0
    check blocksHeld(pointed & read).len == 1

    # Later hand-back of other agent points at no result, and nor does any where result names no
    #   agent, so result stays report: case of critic of hook on #962, hand-back of builder.
    for (agent, later) in [("a9", lineHandback("builder", "abuilder")),
        ("a9", lineQueued("builder", "abuilder")), ("", lineHandback("builder", ""))]:
      let alone = taken & linesForeground("critic", "false", "completed", agent) & later
      check blocksHeld(alone & read).len == 1
      check blocksHeld(alone & reflected).len == 0

    # Later hand-back of other critic agent points at no result either, so turn holds two
    #   reports, as critic of fixes on #962 found.
    for later in [lineHandback("critic", "a8"), lineQueued("critic", "a8")]:
      let twice = taken & linesForeground("critic", "false", "completed", "a9") & later
      check blocksHeld(twice & reflected).anyIt("got none for report `2` of `2`" in it)

    # Each report takes heading after it, earliest report first.
    let before = lineUser("Next.", "human") & lineSaid(REFLECTION, "tool_use") & linesCall("ls")
    check blocksHeld(taken & before & lineQueued("critic") & read).len == 1
    let two = taken & lineHandback("critic", "a1") & lineSaid(REFLECTION, "tool_use") &
      linesCall("ls") & lineQueued("critic", "a2")
    check blocksHeld(two & read).anyIt("got none for report `2` of `2`" in it)
    check blocksHeld(two & reflected).len == 0
    let one = blocksHeld(taken & lineHandback("critic", "a1") & linesCall("ls") &
      lineQueued("critic", "a2") & reflected)
    check one.len == 1 and "got none for report `2` of `2`" in one[0]  # one heading, two reports

    # In last text of turn, heading counts above first sign-off alone; in fence, it counts not.
    const signed = "## Sign-off\n\n**Role:** curator, at `main`\n"
    check blocksHeld(taken & report & lineSaid(signed & "\n" & REFLECTION)).len == 1
    check blocksHeld(taken & report & lineSaid(REFLECTION & "\n" & signed)).len == 0
    check blocksHeld(taken & report & lineSaid(signed & "\n" & REFLECTION & "\n" & signed)).len ==
      1  # first of two sign-offs
    check blocksHeld(taken & report & lineSaid(signed & "\n" & REFLECTION, "tool_use") &
      linesCall("ls") & lineSaid("Done.")).len == 0  # earlier text of turn
    check blocksHeld(taken & report & lineSaid("Form:\n\n```md\n" & REFLECTION & "```\n")).len == 1

    # Report of earlier turn was held at its own stop.
    check blocksHeld(taken & report & read & lineUser("Next.", "human") & lineSaid("Noted.")).len ==
      0

    # Refusal asks for missing reflection now, and for mend of cell that is no whole claim of
    #   block, as D5 b of #969 asks.
    let reason = reasonStop([], [], blocks = @[finding("", 0, "Report of critic.")])
    check "Write each missing reflection now" in reason
    check "mend each cell under `Predicted` that is no whole claim of block that call took" in
      reason


  test "reflection counts above first sign-off or working line of last text of turn (#962)":
    # Case as found by critic of hook on #962: reflection below working line of last text of
    #   turn counted, so turn passed. Ruling 6974524232 asks for it before any sign-off or
    #   working line.
    const
      signed = "## Sign-off\n\n**Role:** curator, at `main`\n"
      working = "**Working:** the resolver runs next.\n"
    let
      taken = lineUser("Build the check.", "human") & lineSaid(PREDICTION) &
        lineUser("<task-notification>timer</task-notification>", "task-notification") &
        linesAgent("builder") & lineSaid("Started.") & lineHandback("builder", "abuilder") &
        linesAgent("critic") & lineSaid("The critic runs.") & lineHandback("critic")
      missing = @["Report of critic takes `## Reflection` block of its own after it, above " &
        "any sign-off or working line (GUIDE.md, Prediction, critic and reflection); got none " &
        "for report `1` of `1` in this turn."]
    check blocksHeld(taken & lineSaid("The critic held each claim.\n\n" & working & "\n" &
      REFLECTION)) == missing

    # Heading counts where it stands above each sign-off and working line of last text: each
    #   order of reflection `R`, sign-off `S` and working line `W`, each of last two or not, and
    #   two working lines around it, as critic of fixes on #962 found.
    for order in ["R", "RS", "SR", "RW", "WR", "RSW", "RWS", "SRW", "SWR", "WRS", "WSR", "WRW"]:
      var parts: seq[string]
      for part in order:
        parts.add(if part == 'R': REFLECTION elif part == 'S': signed else: working)
      check blocksHeld(taken & lineSaid(parts.join("\n"))) ==
        (if order[0] == 'R': newSeq[string]() else: missing)

    # Working line of earlier text of turn, or in fence, ends nothing.
    check blocksHeld(taken & lineSaid(working & "\n" & REFLECTION, "tool_use") & linesCall("ls") &
      lineSaid("Done.")).len == 0
    check blocksHeld(taken & lineSaid("Form:\n\n```md\n" & working & "```\n\n" & REFLECTION))
      .len == 0

    # Line that ends block of prediction is line that ends reflections that count, and no other.
    for (line, is_working) in [("**Working:** x", true), ("  **Working:** x", true),
        ("**Working:**", true), ("Then **Working:** x", false), ("Working: x", false)]:
      let ended = lineSaid("## Prediction\n- a\n" & line & "\n- b").parseTurn.subagents
      check (ended.predictions.mapIt(it.text) == @["- a"]) == is_working
      check (blocksHeld(taken & lineSaid(line & "\n" & REFLECTION)) == missing) == is_working


  test "each cell under `Predicted` quotes block that call took, word for word (#962)":
    # Ruling 6975486646: hook refuses reflection whose cells under `Predicted` stand in no earlier
    #   block. Ruling 6980006567: reflection quotes only block that call used.
    const header = "| State | Confidence | Predicted | Result |\n| --- | --- | --- | --- |\n"
    let
      asked = lineUser("Build the check.", "human")
      wake = lineUser("<task-notification>timer</task-notification>", "task-notification")
      calls = wake & linesAgent("builder") & lineSaid("Started.") &
        lineHandback("builder", "abuilder") & linesAgent("critic") & lineSaid("The critic runs.") &
        lineHandback("critic")
      taken = asked & lineSaid(PREDICTION) & calls
    proc reflected(table: string, before = taken): seq[string] =
      ## Read findings of reflection holding table, after report of critic.
      blocksHeld(before & lineSaid("## Reflection\n\n**Subagent:** builder.\n\n" & table &
        "\n- **Change:** none.\n"))
    check blocksHeld(taken & lineSaid(REFLECTION)).len == 0

    # Whitespace collapses on both sides, and `\|` reads as `|`.
    let wrapped = PREDICTION.replace("shared key leads", "shared key\n  leads")
      .replace("each with `file:line`", "each with `a | b`")
    check reflected(header &
      "| ✅ | 70% |  the race  to save one shared key leads the findings | it leads |").len == 0
    check reflected(header & "| ✅ | 70% | the race to save one shared key leads the findings | " &
      "it leads |\n| ⬜ | 60% | four to eight findings, each with `a \\| b` | three |",
      asked & lineSaid(wrapped) & calls).len == 0

    # Case as found: sample of `GUIDE.md` before #962 quotes claims short, with percentage;
    #   refusal states rule of D5 b of #969.
    check reflected(header & "| ✅ | 70% | The race leads (70%) | it leads |") ==
      @[refusalCell("The race leads (70%)")]

    # Block in turn of call, and block no call took, are no quote.
    let late = asked & lineSaid("Read.") & wake & lineSaid(PREDICTION, "tool_use") &
      linesAgent("builder") & lineSaid("Started.") & lineHandback("builder", "abuilder") &
      linesAgent("critic") & lineSaid("The critic runs.") & lineHandback("critic")
    check blocksHeld(late & lineSaid(REFLECTION)).len == 2
    let unused = asked & lineSaid(PREDICTION) & wake & lineSaid("No subagent.") &
      lineHandback("critic")
    check blocksHeld(unused & lineSaid(REFLECTION)).len == 2

    # Prediction of critic is optional, and block that names `critic` serves its call; block for
    #   other kind serves no critic, so reflection quotes none of it (7017187857).
    for (kind, count) in [("critic", 0), ("builder", 2), ("reviewer", 2)]:
      let critic = asked & lineSaid(predicting(kind)) & wake & linesAgent("critic") &
        lineSaid("The critic runs.") & lineHandback("critic")
      check blocksHeld(critic & lineSaid(REFLECTION)).len == count

    # Reflection quotes nothing with no table, no row, or empty cell.
    check reflected("No table.").anyIt("column `Predicted` (GUIDE.md" in it)
    check reflected("| State | Result |\n| --- | --- |\n| ✅ | it leads |")
      .anyIt("column `Predicted` (GUIDE.md" in it)
    check reflected(header).anyIt("got none under `| State | Confidence | Predicted |" in it)
    check reflected(header & "| ✅ | 70% |  | it leads |").anyIt("empty cell in row `1`" in it)
    check reflected(header & "| ✅ | 70% |").anyIt("empty cell in row `1`" in it)  # short row

    # Row whose cell is `-` is row: separator holds dashes or colons in each cell, not in one.
    check reflected(header & "| ⬜ | - | the race to save one shared key leads the findings | - |")
      .len == 0

    # Each reflection of turn takes quote check, also one below sign-off or working line, which
    #   answers no report.
    for cut in ["## Sign-off\n\n**Role:** curator, at `main`\n", "**Working:** it runs.\n"]:
      check blocksHeld(taken & lineSaid(REFLECTION & "\n" & cut & "\n## Reflection\n\n" & header &
        "| ⬜ | 60% | not quoted | x |\n")) == @[refusalCell("not quoted")]

    # First table with column `Predicted` is read, and no other.
    check reflected("| Item | Cost |\n| --- | --- |\n| run | $1 |\n\n" & header &
      "| ✅ | 70% | the race to save one shared key leads the findings | it leads |\n\n" & header &
      "| ✅ | 1% | not quoted | x |").len == 0

    # Reflection of earlier turn was held at its own stop.
    check blocksHeld(taken & lineSaid("## Reflection\n\nNo table.\n") & lineUser("Next.", "human") &
      lineSaid("Noted.")).len == 0


  test "each cell is whole claim of block call took, or `No prediction` (D2 c and D5 b of #969)":
    # Ruling 7016134603, D5 b of #969: each cell under `Predicted` equals one claim of block that
    #   call took, with or without its label; claim runs up to its percentage, its percentiles or
    #   its resolution criterion, and runs of whitespace collapse as before. Ruling 7015791554,
    #   D2 c of #969: reflection counts missing prediction in row of its own, whose cell holds
    #   exactly `No prediction`, with cause of miss under `Result`; quote check passes that one
    #   exact cell. Cases as found are costs of record, Blocks of subagents: cell standing in
    #   block passed, as `-`, and reflection of missing prediction where no call took block
    #   could not pass.
    const
      header = "| State | Confidence | Predicted | Result |\n| --- | --- | --- | --- |\n"
      predicted = """
## Prediction

**Subagent:** reviewer of the diff, fresh context.
**Basis:** what this delegate knows, with no new read.

- Judgement: the race leads the findings (70%). Resolution criterion: it is the first finding.
- Work: tokens summed over its requests: 100,000, 160,000 and 300,000, as the 10th, 50th and
  90th percentiles. Resolution criterion: the sum of the usage of its requests.
- Calls: 10th 150, 50th 260, 90th 420. Resolution criterion: the count of its calls.
- Judgement: no test is weakened.

**Working:** a timer of 5 seconds wakes this delegate, and the next turn starts the reviewer.
"""
        ## Block in form of `GUIDE.md`, with each mark that ends claim, and bullet with none.
      claims = [
        ("Judgement: ", "the race leads the findings"),
        ("Work: ", "tokens summed over its requests: 100,000, 160,000 and 300,000"),
        ("Calls: ", "10th 150, 50th 260, 90th 420"),
        ("Judgement: ", "no test is weakened."),
      ]
        ## Label and claim of each bullet of `predicted`, as rulings cut them.
      fragments = 111
        ## Runs of words of `claims` that are neither claim nor claim without its label.
    let
      asked = lineUser("Review the diff.", "human")
      wake = lineUser("<task-notification>timer</task-notification>", "task-notification")
      calls = wake & linesAgent("reviewer") & lineSaid("Started.") &
        lineHandback("reviewer", "areviewer") & linesAgent("critic") &
        lineSaid("The critic runs.") & lineHandback("critic")
      taken = asked & lineSaid(predicted) & calls
    proc reflected(cells: openArray[string]; before = taken): seq[string] =
      ## Read findings of reflection whose rows hold cells under `Predicted`, after report of
      ##   critic.
      var rows = ""
      for cell in cells: rows.add "| ✅ | 70% | " & cell & " | it holds |\n"
      blocksHeld(before & lineSaid("## Reflection\n\n" & header & rows))
    proc passes(bullets, cell: string): bool =
      ## Decide whether cell passes, where block that call took holds bullets alone, after line
      ##   that names kind of call (7017187857).
      reflected([cell], asked & lineSaid("## Prediction\n\n**Subagent:** reviewer of the diff." &
        "\n\n" & bullets & "\n") & calls).len == 0

    # Each claim passes, with and without its label, one to table and all in one.
    for (label, claim) in claims:
      check reflected([label & claim]).len == 0
      check reflected([claim]).len == 0
    check reflected(claims.mapIt(it[0] & it[1]) & claims.mapIt(it[1])).len == 0

    # Each other run of words of claim is fragment, and refused: each word alone, cut that drops
    #   end or start of claim, and part after second `: `.
    var runs = 0
    for (label, claim) in claims:
      let words = (label & claim).splitWhitespace
      for first in 0 ..< words.len:
        for last in first ..< words.len:
          let cell = words[first .. last].join(" ")
          if cell in [label & claim, claim]: continue
          check reflected([cell]) == @[refusalCell(cell)]
          inc runs
    check runs == fragments

    # Marker of bullet, cut inside word, and line of block that is no bullet each are no claim.
    for cell in ["-", "- Judgement: the race leads the findings", "he race leads the findings",
        "the race leads the finding", "reviewer of the diff, fresh context.",
        "**Basis:** what this delegate knows, with no new read."]:
      check reflected([cell]) == @[refusalCell(cell)]

    # Claim that keeps its percentage, percentiles, resolution criterion or whole bullet is
    #   refused, and so is claim of bullet with no mark cut before end of bullet.
    for cell in ["the race leads the findings (70%)",
        "Judgement: the race leads the findings (70%)", "the race leads the findings (70%).",
        "the race leads the findings (70%). Resolution criterion: it is the first finding.",
        "tokens summed over its requests: 100,000, 160,000 and 300,000, as the 10th, 50th and " &
          "90th percentiles", "10th 150, 50th 260, 90th 420.", "no test is weakened"]:
      check reflected([cell]) == @[refusalCell(cell)]

    # Claim ends at first mark, in any order: percentage in brackets of any count of digits,
    #   `, as the 10th`, or `. Resolution criterion`; with none, it runs to end of bullet.
    for (bullet, claim) in [("- a b (5%) c", "a b"), ("- a b (70%) c", "a b"),
        ("- a b (100%) c", "a b"), ("- a b, as the 10th c", "a b"),
        ("- a b. Resolution criterion: c", "a b"),
        ("- a b (70%), as the 10th c. Resolution criterion: d", "a b"),
        ("- a b, as the 10th c (70%). Resolution criterion: d", "a b"),
        ("- a b. Resolution criterion: c (70%), as the 10th d", "a b"),
        ("- a b. Resolution criterion: c, as the 10th d (70%)", "a b"),
        ("- a b c (60%) d (70%)", "a b c"), ("- a b", "a b"), ("- a b.", "a b.")]:
      check passes(bullet, claim)
      check passes(bullet, bullet[2 .. ^1]) == (bullet[2 .. ^1] == claim)

    # Brackets with no percentage in them, and other words, end nothing, so claim reads them.
    for bullet in ["- a (duty 2) b", "- a (70 %) b", "- a (about 70%) b", "- a(70%) b",
        "- a (%) b", "- a (70% b", "- a, as the 50th b", "- a as the 10th b",
        "- a. resolution criterion. b"]:
      check passes(bullet, bullet[2 .. ^1])
      check not passes(bullet, "a")

    # Label is text before first `: ` of claim; `: ` of resolution criterion alone opens none.
    for (bullet, cells, refused) in [
        ("- Judgement: a b (70%).", @["Judgement: a b", "a b"], @["Judgement:", "b"]),
        ("- Judgement: a: b (70%).", @["Judgement: a: b", "a: b"], @["b", "Judgement: a"]),
        ("- a b. Resolution criterion: c d.", @["a b"], @["c d.", "a b. Resolution criterion"]),
        ("- Judgement:a b (70%).", @["Judgement:a b"], @["a b"])]:
      for cell in cells: check passes(bullet, cell)
      for cell in refused: check not passes(bullet, cell)

    # Bullet runs over each line to next blank line or bullet, indented or not, whitespace
    #   collapsed, so claim and its mark may wrap; nested bullet ends it and opens no claim.
    for (bullets, claim) in [("- Judgement: a\n  b (70%)", "a b"),
        ("- Judgement: a\nb (70%)", "a b"), ("- a b\n  (70%) c", "a b"),
        ("- a b, as the\n  10th c", "a b"), ("- a b.\n  Resolution criterion: c", "a b"),
        ("- a  b\t(70%)", "a b"), ("- a b\n- c d (70%)", "c d")]:
      check passes(bullets, claim)
    for (bullets, claim, refused) in [("- a b\n\n  c (70%)", "a b", "a b c"),
        ("- a b\n- c d (70%)", "a b", "a b - c d"), ("- a b\n  - c d (70%)", "a b", "c d"),
        ("- a b\n  - c d (70%)", "a b", "a b - c d"), ("- a b\n  * c d (70%)", "a b", "a b * c d")]:
      check passes(bullets, claim)
      check not passes(bullets, refused)

    # Bullet opens with `-`, `*` or `+` and space, at no indent; other line opens no claim.
    for marker in ["-", "*", "+"]:
      check passes(marker & " a b (70%)", "a b")
    for bullets in ["  - a b (70%)", "\t- a b (70%)", "1. a b (70%)", "-a b (70%)", "a b (70%)",
        "> - a b (70%)"]:
      check not passes(bullets, "a b")

    # Pipe of claim reads as `\|` in cell.
    check passes("- a `x | y` b (70%)", "a `x \\| y` b")

    # `No prediction` passes where no call took block, where critic alone ran, and where call
    #   took block, beside claims; its whitespace collapses, as each cell's does.
    let
      missed = asked & lineSaid("Read.") & calls
      alone = asked & wake & linesAgent("critic") & lineSaid("The critic runs.") &
        lineHandback("critic")
    for before in [missed, alone, taken]:
      check reflected(["No prediction"], before).len == 0
      check reflected(["No  prediction", "No\tprediction"], before).len == 0
    check reflected(claims.mapIt(it[1]) & @["No prediction", "No prediction"]).len == 0

    # Each other case of letters, and each mark or word added, is refused.
    var cased = 0
    for i, c in "No prediction":
      if c notin Letters: continue
      var cell = "No prediction"
      cell[i] = (if c.isUpperAscii: c.toLowerAscii else: c.toUpperAscii)
      for before in [missed, alone, taken]:
        check reflected([cell], before) == @[refusalCell(cell)]
      inc cased
    check cased == "Noprediction".len
    for cell in ["no prediction", "NO PREDICTION", "No prediction.", "No prediction:",
        "No predictions", "Noprediction", "No prediction (70%)", "No prediction of builder"]:
      for before in [missed, alone, taken]:
        check reflected([cell], before) == @[refusalCell(cell)]

    # Claim of block no call took is refused, with its label or without it: block in turn of
    #   call, and block of turn after which no call starts.
    let
      late = asked & lineSaid("Read.") & wake & lineSaid(predicted, "tool_use") &
        linesAgent("reviewer") & lineSaid("Started.") & lineHandback("reviewer", "areviewer") &
        linesAgent("critic") & lineSaid("The critic runs.") & lineHandback("critic")
      unused = asked & lineSaid(predicted) & wake & lineSaid("No subagent.") &
        lineHandback("critic")
    for before in [late, unused]:
      for (label, claim) in claims:
        for cell in [label & claim, claim]:
          check reflected([cell], before) == @[refusalCell(cell)]


  test "samples of GUIDE.md hold shape that block checks read (#962)":
    # Delegate copies form from samples, so sample reflection quotes sample prediction, which
    #   call takes, as section reads as committed.
    const guide = staticRead("../../../../GUIDE.md")
    func sample(heading: string): string =
      ## Read text of sample in fence that opens with heading; empty where guide holds none.
      let at = guide.find("```md\n" & heading & "\n")
      if at < 0: return ""
      guide[at + "```md\n".len ..< guide.find("\n```", at)] & "\n"
    check sample(HEADING_PREDICTION).len > 0 and sample(HEADING_REFLECTION).len > 0
    let transcript = lineUser("Review the diff.", "human") & lineSaid(sample(HEADING_PREDICTION)) &
      lineUser("<task-notification>timer</task-notification>", "task-notification") &
      linesAgent("reviewer") & lineSaid("Started.") & lineHandback("reviewer", "areviewer") &
      linesAgent("critic") & lineSaid("The critic runs.") & lineHandback("critic") &
      lineSaid(sample(HEADING_REFLECTION))
    check transcript.parseTurn.subagents.predictions.len == 1
    check blocksHeld(transcript).len == 0
