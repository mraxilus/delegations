## Replicate hook decisions: scope before write, bash refusals, body shape, sign-off, push.

{.experimental: "strictFuncs".}

import std/[algorithm, json, options, os, osproc, sequtils, strutils, tempfiles, unittest]
import ../../src/[findings, hooks, lags, markdown, tree]
import ./[fixtures, fixtures_claims]


const  # TODO: Document.
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
  RULE_CELL = "cell under `Predicted` is one whole claim of `## Prediction` block that call " &
    "took, up to its confidence, percentiles or resolution criterion, or before final full " &
    "stop of bullet with none, with or without its label of one word that opens with capital, " &
    "or `No prediction` (curator/audit/PROVENANCE.md, Quotes of claims)"
    ## Rule that finding of each cell under `Predicted` states, as rules of D2 c, D5 b,
    ##   7017902016, 7018501890 and 7022872980 of #969 give it; record states it, since GUIDE.md
    ##   states tables alone (#1028).
  REFUSAL_NO_TABLE = "reflection holds table of claims: table whose header holds `#`, " &
    "`Judgement` or `Estimate @ 90%`, in form of judgements or estimates (GUIDE.md, Prediction, " &
    "critic and reflection), or table whose header holds `Predicted`, as block of bullets takes " &
    "it (curator/audit/PROVENANCE.md, Quotes of claims)"
    ## Finding of reflection with no table of claims: each form cites text that states it.
  REFUSAL_OUTCOME_BULLETS = "cell under `Result` of number of bullets marked ✅ or ⬜ opens with " &
    "its value, bare in unit its text names, with no scale for cost or time, or with mark of " &
    "that unit: `$` for cost, `s`, `m` or `h` for time (curator/audit/PROVENANCE.md, Quotes of " &
    "claims); got `"
    ## Start of finding of result of number of bullets that reads no value in unit of its text.
  REFUSAL_OUTCOME = "cell under `Result` of estimate marked ✅ or ⬜ opens with its value in unit " &
    "of its cells: `$` for cost, `s`, `m` or `h` for time, bare number for tokens or count " &
    "(GUIDE.md, Prediction, critic and reflection); got `"
    ## Start of finding of result of estimate of table that reads no value in unit of its cells.
  NUMBERS_BULLETS = "## Prediction\n\n**Subagent:** builder of the fix, fresh context.\n\n" &
    "- Work: tokens summed over its requests: 100,000, 160,000 and 300,000, as the 5th, 50th " &
    "and 95th percentiles.\n- Cost: cost at list price: $0.40, $0.90 and $2.00, as the 5th, " &
    "50th and 95th percentiles.\n- Time: time to its report, in minutes: 5, 12 and 30, as the " &
    "5th, 50th and 95th percentiles.\n- Count: findings that the report ranks: 3, 6 and 11, as " &
    "the 5th, 50th and 95th percentiles.\n"
    ## Block of bullets of number of each unit, as GUIDE.md wrote it before tables.
  CLAIMS_BULLETS = ["tokens summed over its requests: 100,000, 160,000 and 300,000",
    "cost at list price: $0.40, $0.90 and $2.00", "time to its report, in minutes: 5, 12 and 30",
    "Count: findings that the report ranks: 3, 6 and 11"]
    ## Claim of each number of `NUMBERS_BULLETS`, in order, as cell quotes it.


func messages(found: seq[Finding]): seq[string] =
  ## Read messages of findings.
  found.mapIt(it.brief)


func closing(text: string): seq[string] =
  ## Read messages `checkBody` gives issue body holding text after role line, which closing
  ##   keyword binds as it binds pull request body, and no form of template binds.
  checkBody("mcp__github__issue_write", BRANCH, "", ROLE & "\n\n" & text & "\n", [], false)
    .messages


func citedBare(message: string): seq[string] =
  ## Read reference each finding of `checkReferencesBare` names, in order.
  checkReferencesBare(message).mapIt(it.brief.split('`')[1])


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


proc rulesHeld(transcript: string, kinds: openArray[string] = KINDS): seq[string] =
  ## Read id of each finding `checkBlocks` gives transcript at stop, for kinds.
  transcript.parseTurn.subagents.checkBlocks(kinds).mapIt(it.rule)


func refusalCell(cell: string): string =
  ## Write finding of cell under `Predicted` that is neither whole claim of block call took nor
  ##   `No prediction`, as rules of D5 b, 7017902016 and 7018501890 of #969 state it.
  RULE_CELL & "; got `" & cell & "`"


func refusalEmpty(row: int): string =
  ## Write finding of empty cell under `Predicted` in row, which states rule as `refusalCell`
  ##   does, so it names `No prediction` as form of miss.
  RULE_CELL & "; got empty cell in row `" & $row & "`"


func refusalCall(kind, description: string, hint = ""): string =
  ## Write finding of call of kind that took no block, with hint after its description.
  "call of subagent of kind takes `## Prediction` block of model turn before its own, and " &
    "after each earlier turn that starts subagent (GUIDE.md, Prediction, critic and " &
    "reflection); got none for `" & kind & "` call `" & description & "`" & hint


func hintNamed(named: string): string =
  ## Write hint that block of turns call looks back over names other kind or none, as rule of
  ##   7017187857 on #969 states it; named is kind in backticks, or `no kind`.
  ", and block of such turn names " & named & ": block serves only call of kind that first " &
    "word of its `**Subagent:**` line names"


func predicting(kind: string): string =
  ## Write `PREDICTION` for subagent of kind, which first word of its `**Subagent:**` line names.
  PREDICTION.replace("**Subagent:** builder of", "**Subagent:** " & kind & " of")


proc quoted(bullets, cell: string): seq[string] =
  ## Read findings of reflection whose one row holds cell under `Predicted`, after report of
  ##   critic, where block that call of `reviewer` took holds bullets alone.
  ##   Its result opens with bare value, which number of bullets of each unit reads (#1028).
  let prediction = "## Prediction\n\n**Subagent:** reviewer of the diff, fresh context.\n\n" &
    bullets & "\n"
  blocksHeld(lineUser("Review the diff.", "human") & lineSaid(prediction) &
    lineUser("<task-notification>timer</task-notification>", "task-notification") &
    linesAgent("reviewer") & lineSaid("Started.") & lineHandback("reviewer", "areviewer") &
    linesAgent("critic") & lineSaid("The critic runs.") & lineHandback("critic") &
    lineSaid("## Reflection\n\n| State | Confidence | Predicted | Result |\n" &
      "| --- | --- | --- | --- |\n| ✅ | 70% | " & cell & " | 1, it holds |\n"))


proc heldReflection(prediction, reflection: string): seq[string] =
  ## Read findings `checkBlocks` gives reflection after report of critic, where call of `builder`
  ##   took block prediction of turn of its own.
  blocksHeld(lineUser("Build it.", "human") & lineSaid(prediction) &
    lineUser("<task-notification>timer</task-notification>", "task-notification") &
    linesAgent("builder") & lineSaid("Started.") & lineHandback("builder", "abuilder") &
    linesAgent("critic") & lineSaid("The critic runs.") & lineHandback("critic") &
    lineSaid(reflection))


proc heldBlock(prediction: string): seq[string] =
  ## Read findings `checkBlocks` gives turn whose last message is block prediction.
  blocksHeld(lineUser("Build it.", "human") & lineSaid(prediction))


func mended(reflection: string): string =
  ## Write reflection with each part of claim of `QUOTES_PART` as whole claim.
  result = reflection
  for (part, whole) in QUOTES_PART: result = result.replace(part, whole)


func blockEstimate(text: string, cells: array[3, string], has_criterion = true): string =
  ## Write block of one estimate of text with cells, and its criterion where asked.
  "## Prediction\n\n**Subagent:** builder of the fix, fresh context.\n\n" &
    "**Estimates.** One estimate.\n\n| # | Estimate @ 90% | 5th | 50th | 95th |\n" &
    "| --- | --- | ---: | ---: | ---: |\n| 1 | " & text & " | " & cells.join(" | ") & " |\n\n" &
    (if has_criterion: "| # | Resolution criterion |\n| --- | --- |\n| 1 | The line. |\n" else: "")


func isNear(value, expected: float): bool =
  ## Decide whether value lies within one part in `10^12` of expected one, or of one near zero.
  abs(value - expected) <= 1e-12 * max(1.0, abs(expected))


func tableColumns(
  text, header: string, columns: openArray[int], names: openArray[string] = []
): string =
  ## Write text whose table that line header opens holds its columns of indices given, in that
  ##   order, each cell with them; header holds names in their place where given.
  var lines = text.split('\n')
  let start = lines.find(header)
  doAssert start >= 0, header
  var k = start
  while k < lines.len and lines[k].startsWith("|"):
    let cells = lines[k][1 ..< ^1].split('|').mapIt(it.strip)
    lines[k] = "| " & (if k == start and names.len > 0: @names else: columns.mapIt(cells[it]))
      .join(" | ") & " |"
    inc k
  lines.join("\n")



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
      refusals_scope = @["path outside branch scope `contributor/ronri/pga_benchmark/`"]
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
    check checkPathEdit(branch, nimble).anyIt(it.rule == "koch.contributor-files")
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
    check checkBash("main", "git commit -m x", false).messages[0].contains("never commit to `main`")
    check checkBash("main", "git commit -m x", false)[0].rule == "koch.commit-to-main"
    check checkBash("claude/tool-named", "git push -u origin claude/tool-named", false).len == 1
    check checkBash(BRANCH, "git push -u origin " & BRANCH, false).len == 0
    check checkBash(BRANCH, "git push --force", false).messages[0].contains("XI.2")
    check checkBash(BRANCH, "git push --force", false)[0].rule == "koch.history-rewrite"
    check checkBash(BRANCH, "git push -f origin x", false).len == 1
    check checkBash(BRANCH, "git push --no-verify -u origin x", false).messages[0].contains(
      "duty 3",
    )  # pre-push hook skipped
    check checkBash(BRANCH, "git push --no-verify -u origin x", false)[0].rule == "koch.push-verify"
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
      .messages[0] == "post must open with `" & ROLE & "`; got `Hello.`; expect `" & ROLE & "`"
    let noted = "<!-- note -->\n" & ROLE & "\n\nOne short claim.\n"
    check checkBody("mcp__github__add_issue_comment", BRANCH, "", noted, [], false).messages ==
      @["post must open with `" & ROLE & "`; got `<!-- note -->` above `" & ROLE & "`; expect `" &
        ROLE & "`"]
    check checkBody("mcp__github__add_issue_comment", BRANCH, "", noted, [], false)[0].rule ==
      "koch.post-role"
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
    check checkBody("mcp__github__issue_write", BRANCH, "fix(x): do thing", good, ["bug"], true)
      .mapIt(it.rule) == @["koch.issue-title", "koch.issue-label"]
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
        .mapIt(it.startsWith("pull request body holds `## What`")) == @[true]
      check checkBody(tool, BRANCH, "t", form.replace("One point.", "It fixes #12."), [], is_create)
        .messages.mapIt(it.startsWith("body holds closing keyword")) == @[true]
      check checkBody(tool, BRANCH, "t", form.replace("One point.", "It fixes #12."), [], is_create)
        .mapIt(it.rule) == @["koch.closing-keyword"]


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
      "body holds closing keyword before issue only on line of its own, as `Closes #783`, " &
        "since GitHub closes issue whatever sentence says; got `Closes #783`; help: drop " &
        "keyword, or put issue first, as `#783 stays open`",
      "sentence must hold at most 25 words (ASD-STE100); got `Machine counts under valgrind " &
        "and gcc 13.3.0, on ...`; help: split it",
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
    check checkSignoff("Done.\n", BRANCH)[0].rule == "koch.sign-off"
    check checkSignoff(SIGNOFF & "\n## After\n", BRANCH)
      .messages.anyIt("nothing follows sign-off" in it)  # heading rule, not Next step rule
    check checkSignoff(SIGNOFF.replace("**Summary:**", "**Gist:**"), BRANCH)
      .messages.anyIt("lacks `**Summary:**`" in it)
    check checkSignoff(SIGNOFF.replace("**Role:** contributor/ronri", "**Role:** curator"), BRANCH)
      .messages.anyIt("role must be" in it)
    check checkSignoff(SIGNOFF & "\nTrailing.\n", BRANCH)
      .messages.anyIt("nothing follows Next step" in it)


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
      .messages.anyIt("state is one of" in it and "got `stuck`" in it)  # word, not branch
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
    check reason.splitLines[1].startsWith("koch.turn-end: message=\"turn that pushed")  # line form


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
      .messages.anyIt("labelled `curator`" in it)
    check checkSignoffRead(curator, [Call(name: "mcp__github__actions_list")])[0].rule ==
      "koch.issue-read"

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
    check checkEndTurn("Pushed.\n", BRANCH, is_writing = true).messages.anyIt("turn that" in it)
    check checkEndTurn("Pushed.\n\n**Working:**\n", BRANCH, is_writing = true)
      .messages.anyIt("turn that" in it)  # names nothing
    check checkEndTurn(working & "\nMore.\n", BRANCH, is_writing = true)
      .messages.anyIt("turn that" in it)  # working line is last
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
    check checkEndTurn(quoted, BRANCH, is_writing = true).messages.anyIt("turn that" in it)
    check checkEndTurn(quoted, BRANCH, is_writing = true).anyIt(it.rule == "koch.turn-end")
    check checkEndTurn(quoted & "\n" & SIGNOFF, BRANCH, is_writing = true).len == 0  # real one
    check checkSignoffRead(quoted, []).len == 0


  test "message names issue and pull request by link first, then by number alone":
    # Long form once, as one link of short description and number (GUIDE.md, Output contract).
    const linked = "[the ledger fix (#456)](https://x/456), [#457] and " &
      "[the fixers (#441)][#441].\n\n[#457]: https://x/457\n[#441]: https://x/441\n"
    check checkNumbersBare(linked).len == 0
    check checkNumbersBare("Merged #463.\n").messages.anyIt("`#463` bare before any link" in it)
    check checkNumbersBare("Merged #463.\n").anyIt(it.rule == "koch.bare-number")
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
    check checkLinksReference("[the fixers (#441)][#441].\n\n[#441]: https://x/441\n")[0].rule ==
      "koch.reference-link"
    check checkLinksReference("```\n[#441]: https://x/441\n```\n").len == 0  # code
    check checkLinksReference("[#1]: https://x/1\n[#2]: https://x/2\n").len == 1  # once


  test "message cites each charter reference by short description, never bare":
    # Short description and its reference, as `names read head first (V.2)` (GUIDE.md, Output
    #   contract). Each passing form stands beside bare `V.2`, so stub reporting nothing fails it
    #   as stub reporting every reference does.
    check checkReferencesBare("X.9 says so.\n").messages == @[
      "message cites `X.9` with no description (GUIDE.md, Output contract); help: cite each " &
        "article and duty first by short description and its reference, as " &
        "`expression spacing (X.9)`, then reference alone",
    ]
    check checkReferencesBare("X.9 says so.\n").anyIt(it.rule == "koch.bare-reference")
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
      .messages.anyIt("class is" in it)
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
      .messages.anyIt("recommends names letter" in it)
    let period = SIGNOFF.replace("- Recommends: **a**,", "- Recommends: **a**. Keep,")
    check checkSignoff(period, BRANCH).len == 0  # letter closed by period
    check checkSignoff(SIGNOFF.replace("- Recommends: **a**, because", "- Because"), BRANCH)
      .messages.anyIt("lacks `Recommends:`" in it)
    check checkSignoff(SIGNOFF.replace("in the tests?", "in the tests."), BRANCH)
      .messages.anyIt("ends with `?`" in it)
    let asks = SIGNOFF.replace("- Where: #331\n", "- Where: #331\n- Options:\n  - a. Buy: x.\n")
    check checkSignoff(asks, BRANCH).messages.anyIt("offers no option" in it)  # fact asks nothing
    check checkSignoff(asks, BRANCH).anyIt(it.rule == "koch.decision")
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
      .messages.anyIt("recommends names letter" in it and "got `c`" in it)


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
    check checkSignoff(bare, BRANCH).anyIt(it.rule == "koch.sign-off-groups")

    # Row holds two cells, and its first opens with state, number and claim.
    const row = "| ✅ 2. Gap list reads each baseline | `koch check` green |"
    check checkSignoff(
      SIGNOFF.replace(row, "| ✅ 2. Gap list reads each baseline | `src/` | `koch check` green |"),
      BRANCH,
    ).messages.anyIt("holds two cells" in it and "got `3`" in it)
    check checkSignoff(
      SIGNOFF.replace(row, "| ✅ 2. Gap list reads each baseline | `src/` | `koch check` green |"),
      BRANCH,
    ).anyIt(it.rule == "koch.sign-off-rows")
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
    check checkSignoff(SIGNOFF.replace("carried 3,", "carried 9,"), BRANCH)
      .anyIt(it.rule == "koch.carried-rules")

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
    check checkPush("abc", "def").anyIt(it.rule == "koch.push-check")
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
    check checkMessage(BRANCH, joined, [], []).anyIt(it.rule == "koch.commit-subject")
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
      "hook reads `gh api` post before command runs, so body from shell variable or stdin is " &
        "unread; got `/w/$DIR/x.md`; help: name file by literal path",
    ]
    check checkPosts(BRANCH, post & "-F body=@$DIR/x.md", "/w").anyIt(it.rule == "koch.post-body")
    check checkPosts(BRANCH, post & "-F body=@`pwd`/x.md", "/w")
      .messages.anyIt("literal path" in it)  # backtick
    check checkPosts(BRANCH, post & "-F body=@- <<'EOF'\nText.\nEOF", "/w")
      .messages.anyIt("got `-`; help: name file by literal path" in it)  # stdin
    check checkPosts(BRANCH, "cd \"$W\" && " & post & "-F body=@x.md", "/w")
      .messages.anyIt("literal path" in it)  # directory unknown
    check checkPosts(BRANCH, post & "--input -", "/w").messages.anyIt("literal path" in it)
    check checkPosts(BRANCH, post & "-f body=\"$(cat x.md)\"", "/w")
      .messages.anyIt("before shell expands it" in it)
    let directory = createTempDir("delegations_", "_posts")
    defer: removeDir(directory)
    let missing = directory / "absent.md"
    check checkPosts(BRANCH, post & "-F body=@" & missing, "/w").messages == @[
      "hook reads `gh api` post before command runs, so it cannot read file command itself " &
        "writes; got missing `" & missing & "`; help: write file in earlier call",
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
        Check.Drift,
        "Base changed sections; read `git diff a..origin/main -- GUIDE.md`; got `## Output " &
          "contract`.",
      )
      stamp = finding(
        "", 0, Check.Drift, "Branch predates code of stamp on base; got `provenance.nim`."
      )
      drifted = contextStart("curator/x", "", "", "## List", "", @[drift, stamp])
    check "\n  GUIDE.md: koch.drift: actual=\"## Output contract\" message=\"base changed " &
      "sections" in drifted  # line form, as each hook prints finding
    check "\n  koch.drift: actual=\"provenance.nim\" message=\"branch predates code of stamp on " &
      "base\"\n" in drifted  # each
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


  test "start prints past figures of each kind under their line, after lags, and none where none":
    # GUIDE.md, Prediction, critic and reflection: once log of claims exists, start prints past
    #   figures of each kind, as base rate (#964); lines come from `linesBase`, each indented.
    let
      rates = @["Base rate of `reviewer`: 1 of 1 claims held, mean baseline score 58.5"]
      lag = "Commit of lock lags main."
      text = contextStart("curator/x", "", "", "## List", "", @[], [lag], rates)
      heading = "\nPast figures of each kind, from logs of claims (GUIDE.md, Prediction, critic " &
          "and reflection):\n"
    check heading & "  " & rates[0] & "\n" in text
    check text.find(heading) > text.find(lag)
    check "Past figures" notin contextStart("curator/x", "", "", "## List", "", @[], [lag])


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
    check checkSignoffWindow(fewer, BRANCH, [SIGNOFF], []).anyIt(it.rule == "koch.kept-groups")
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
      path & ":3: message=\"own\"",
      "koch check-files holds 1 finding(s) in `" & path & "` for its project, which clears " &
        "them in its next pull request (CURATOR.md, duty 3):",
      path & ":5: message=\"held\"",
    ]  # each finding in line form, as each hook prints it
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
    check missing.len == 1 and missing[0].endsWith("got none for `builder` call `Build it`")

    # Block in turn of call, and block in thinking, each add their hint (`D3 a` of 6982373798).
    for before in [asked, asked & read & wake]:
      let inside = blocksHeld(before & lineSaid(PREDICTION, "tool_use") & linesAgent("builder") &
        started)
      check inside.len == 1 and inside[0].endsWith("block stands in earlier turn")
      check rulesHeld(before & lineSaid(PREDICTION, "tool_use") & linesAgent("builder") &
        started) == @["koch.prediction"]
    for kind in ["thinking", "redacted_thinking"]:
      let thought = blocksHeld(asked & read & wake & lineThought(kind) & linesAgent("builder") &
        started)
      check thought.len == 1 and thought[0].endsWith("reaches neither chat nor hook")
    check blocksHeld(asked & read & wake & lineThought() & lineSaid("Now.", "tool_use") &
      linesAgent("builder") & started).allIt("thinking" notin it)  # text before call

    # Block or thinking after call, in its turn, adds no hint, since each hint reads what stands
    #   before call.
    for after in [lineSaid(PREDICTION, "tool_use"), lineThought()]:
      let late = blocksHeld(asked & read & wake & linesAgent("builder") & after & started)
      check late == @["call of subagent of kind takes `## Prediction` block of model turn before " &
        "its own, and after each earlier turn that starts subagent (GUIDE.md, Prediction, " &
        "critic and reflection); got none for `builder` call `Do the work`"]

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
      refused = "got none for `reviewer` call `Do the work`"
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
    #   later call: kind, exempt kind, type no template names, and no type, which harness runs
    #   as general subagent (C1 of critic of pairing build), in background or foreground.
    for kind in ["builder", "critic", "resolver", "web-fetch", "general-purpose", ""]:
      for between in [linesAgent(kind), linesForeground(kind, "false", "completed")]:
        let found = blocksHeld(asked & lineSaid(predicted & "\n" & predicted) & wake & between &
          started & called)
        check found.len == 1 and found[0].endsWith(refused)

    # Block in turn that starts subagent, before or after its call, is no evidence, and adds no
    #   hint; block in turn of call adds its hint, after turns with no block.
    for kind in ["builder", "web-fetch"]:
      for earlier in [lineSaid(predicted, "tool_use") & linesAgent(kind),
          linesAgent(kind) & lineSaid(predicted, "tool_use")]:
        check blocksHeld(asked & earlier & started & waited & called) == @["call of subagent of " &
          "kind takes `## Prediction` block of model turn before its own, and after each " &
          "earlier turn that starts subagent (GUIDE.md, Prediction, critic and reflection); " &
          "got none for `reviewer` call `Do the work`"]
    let inside = blocksHeld(asked & lineSaid(predicted) & wake & linesAgent("web-fetch") &
      started & waited & wake & lineSaid(predicted, "tool_use") & linesAgent("reviewer") & started)
    check inside.len == 1 and inside[0].endsWith("block stands in earlier turn")

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
    check rulesHeld(mended & lineSaid(REFLECTION)) == @["koch.reflection-table"]


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

    # Ruling 7022770415 of #969: hook skips `Agent` call whose result has `is_error` and no
    #   `agentId`, so such call takes no block and ends no turns that later call looks back over;
    #   call that launched keeps its effect. Case as found is probe Q5 of critic of D1 c: build
    #   `05cb3bbd` read call that harness rejects as call, so it refused its retry.
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
    check blocksHeld(rejected).len == 0

    func answered(kind: string; error, answer: JsonNode; is_foreground = false): string =
      ## Write transcript lines of `Agent` call of kind and its result, whose item holds error as
      ##   `is_error` and whose entry holds answer as `toolUseResult`; each is absent where nil.
      var
        input = %*{"subagent_type": kind, "description": "Build the fix", "prompt": "Do it."}
        item = %*{"type": "tool_result", "tool_use_id": "toolu_r" & kind, "content": "Error."}
        entry = %*{"type": "user", "message": {"content": []}}
      if is_foreground: input["run_in_background"] = %false
      if error != nil: item["is_error"] = error
      entry["message"]["content"].add item
      if answer != nil: entry["toolUseResult"] = answer
      $(%*{"type": "assistant", "message": {"content": [{
        "type": "tool_use", "id": "toolu_r" & kind, "name": "Agent", "input": input,
      }], "stop_reason": "tool_use"}}) & "\n" & $entry & "\n"

    proc retried(between: string): seq[string] =
      ## Read findings of retry of builder whose block stands before call that between writes.
      blocksHeld(build & timer &
        lineSaid(predictedProbe("builder", "the builder adds two commits")) & wake & between &
        lineSaid("The call was answered.") & lineUser("Try again.", "human") &
        linesAgent("builder", "Build the fix") & ran)

    # Result with `is_error` and no `agentId` skips call of each type, so retry takes block;
    #   `toolUseResult` that is text, absent, or object with no agent or empty one names none.
    let
      error = %true
      unnamed = [%"Error: The tool use was rejected.", nil, %*{"status": "error"},
        %*{"agentId": ""}]
    for kind in ["builder", "critic", "resolver", "web-fetch", ""]:
      for answer in unnamed:
        check retried(answered(kind, error, answer)).len == 0

    # Call that launched names its agent, so it keeps its effect with `is_error` too: it takes
    #   block of its kind and ends turns, so retry is refused. So does result with no `is_error`,
    #   or with one that is false or no boolean.
    for kind in ["builder", "web-fetch"]:
      check retried(answered(kind, error, %*{"agentId": "a1", "status": "completed"})) ==
        @[refusalCall("builder", "Build the fix")]
      for flag in [nil, %false, %"true", %1]:
        check retried(answered(kind, flag, %"Error: The tool use was rejected.")) ==
          @[refusalCall("builder", "Build the fix")]

    # Skipped call of current turn asks for no block, and skipped call of critic in foreground
    #   gives no report; call that launched still asks for each.
    let read = lineSaid("Read.")
    check blocksHeld(build & read & wake & answered("builder", error, %"Error.") & ran).len == 0
    check blocksHeld(build & read & wake & answered("builder", error, %*{"agentId": "a1"}) & ran) ==
      @[refusalCall("builder", "Build the fix")]
    check blocksHeld(build & read & wake &
      answered("critic", error, %"Error.", is_foreground = true) & ran).len == 0
    check blocksHeld(build & read & wake &
      answered("critic", error, %*{"agentId": "a1"}, is_foreground = true) & ran).anyIt(
      it.startsWith("report of critic takes `## Reflection` block"))

    # Skip drops rejected call alone: call of its kind that launched before it keeps block it
    #   took, so reflection that quotes that block passes (break X3 of critic of last build,
    #   which dropped each earlier call of kind of rejected call too).
    check blocksHeld(build & timer &
      lineSaid(predictedProbe("builder", "the builder adds two commits")) & wake &
      linesAgent("builder", "Build the fix") & ran & lineHandback("builder", "abuilder") &
      checked & answered("builder", error, %"Error: The tool use was rejected.") &
      lineSaid(reflectedProbe("the builder adds two commits"))).len == 0

    # Kind is first word after `**Subagent:**` on first line of block that opens with it, after
    #   any indent, up to whitespace. Ruling 7022770415 of #969: before match, word drops case,
    #   backticks, bold or italic marks, and final comma, so `**Subagent:** Builder of the fix`
    #   names `builder`. Ruling 7027197745 of #969: label reads in any case, with its colon
    #   inside or outside bold, and word drops final full stop or colon too, so line
    #   `**subagent:** builder. of the fix` names `builder`. Block with no such line, or whose
    #   word is no kind, names no kind and serves no call, and hint says so. Cases as found are
    #   probes S02 to S16
    #   of critic of pairing build: build `05cb3bbd` read word as written, so kind with capital,
    #   as table of guide spells it, or in backticks, italics or bold, or with comma, named none;
    #   build `9d4b7eff` read label as written, so S05, S10 and S15 named none.
    proc heldAfter(text: string, kinds: openArray[string] = KINDS): seq[string] =
      ## Read findings of builder call after block that holds text, then one claim, in turn
      ##   before its own.
      blocksHeld(build & lineSaid("## Prediction\n\n" & text & "\n\n- Judgement: it builds " &
        "(70%).") & wake & linesAgent("builder", "Build the fix") & ran, kinds)

    for text in ["**Subagent:** builder of the fix.", "  **Subagent:** builder of the fix.",
        "**Subagent:**  builder\tof the fix.", "**Subagent:** builder",
        "**Subagent:**builder of the fix.", "**Subagent:** builder (fresh context) of the fix.",
        "**Basis:** none.\n**Subagent:** builder of the fix.",
        "- Judgement: it is first (70%).\n\n**Subagent:** builder of the fix.",
        "**Subagent:** builder of the fix.\n**Subagent:** reviewer of the diff.",
        "**Subagent:** Builder of the fix.", "**Subagent:** `builder` of the fix.",
        "**Subagent:** builder, fresh context.", "**Subagent:** *builder* of the fix.",
        "**Subagent:** **builder** of the fix.", "**Subagent:** BUILDER, of the fix.",
        "**Subagent:** builder: the fix.", "**Subagent:** builder. Of the fix.",
        "**Subagent**: builder of the fix.", "**subagent:** builder of the fix.",
        "**SUBAGENT:** builder of the fix.", "**subagent**: builder of the fix.",
        "**subagent:** builder. of the fix", "**Subagent:** `builder`. of the fix.",
        "**Subagent:** **builder**: of the fix.", "  **sUbAgEnT**:  Builder,\tof the fix."]:
      check heldAfter(text).len == 0
    check heldAfter("**Subagent:** reviewer of the diff.\n**Subagent:** builder of the fix.") ==
      @[refusalCall("builder", "Build the fix", hintNamed("`reviewer`"))]  # first line alone
    for first in ["**Subagent:**", "**Subagent:** the builder of the fix."]:
      check heldAfter(first & "\n**Subagent:** builder of the fix.") ==
        @[refusalCall("builder", "Build the fix", hintNamed("no kind"))]  # first line names none

    # Word keeps each other mark, second final mark, and its words, and label keeps its marks
    #   but colon, so each of these names no kind; strike and semicolon are such marks (X5 of
    #   critic of last build).
    for text in ["**Basis:** what this delegate knows.", "**Subagent:**",
        "**Subagent:**\nbuilder of the fix.", "**Subagent:** the builder of the fix.",
        "**Subagent:** a builder of the fix.", "**Subagent:** builders of the fix.",
        "**Subagent:** builder,, of the fix.", "**Subagent:** ,builder of the fix.",
        "**Subagent:** builder.. of the fix.", "**Subagent:** builder,. of the fix.",
        "**Subagent:** builder:, of the fix.", "**Subagent:** builder; of the fix.",
        "**Subagent:** ~~builder~~ of the fix.", "**Subagent:** .builder of the fix.",
        "**Subagent:** \"builder\" of the fix.", "**Subagent:** (builder) of the fix.",
        "**Subagent:** b`uild`er of the fix.", "**Subagent:** ** builder of the fix.",
        "**Subagent:** builder of the fix.", "**Subagent:** surveyor of the fix.",
        "**Subagent:** web-fetch of the page.", "Subagent: builder of the fix.",
        "**Subagent** builder of the fix.", "__Subagent:__ builder of the fix.",
        "*Subagent:* builder of the fix.", "***Subagent:*** builder of the fix.",
        "**Subagent:**: builder of the fix.", "**Sub agent:** builder of the fix.",
        "- **Subagent:** builder of the fix.", "The **Subagent:** builder of the fix.",
        "> **Subagent:** builder of the fix.", "```\n**Subagent:** builder of the fix.\n```"]:
      check heldAfter(text) == @[refusalCall("builder", "Build the fix", hintNamed("no kind"))]
    let repository = readKinds(currentSourcePath().parentDir / "../../../..")
    check heldAfter("**Subagent:** surveyor of the fix.", repository) ==
      @[refusalCall("builder", "Build the fix", hintNamed("`surveyor`"))]  # kind of templates

    # Kind that word names is name its template gives: hint gives that name, and call of
    #   template whose name holds capital takes block whose word holds none.
    check heldAfter("**Subagent:** **Reviewer**, of the diff.") ==
      @[refusalCall("builder", "Build the fix", hintNamed("`reviewer`"))]
    check blocksHeld(build & lineSaid("## Prediction\n\n**Subagent:** builder of the fix.\n\n" &
      "- Judgement: it builds (70%).") & wake & linesAgent("Builder", "Build the fix") & ran,
      ["Builder"]).len == 0

    # Law: word of each kind, in each case, inside each mark of code, italic or bold, with final
    #   comma, full stop or colon or none, outside or inside marks, names that kind, exempt kind
    #   too, so its call takes block and reflection quotes its claim; so does plain word after
    #   label in each case, with colon inside or outside bold (7022770415, 7027197745).
    const
      wraps = ["", "`", "*", "**", "***", "_", "__"]
        ## Marks that word may stand inside: none, code, italic, bold, and both.
      ends = [",", ".", ":"]
        ## Marks after word that match drops, once, outside or inside marks.
      labels = ["**Subagent:**", "**subagent:**", "**SUBAGENT:**", "**Subagent**:",
        "**sUbAgEnT**:"]
        ## Forms of label: cases of letters, with colon inside or outside bold.
      forms = 816
        ## Cases of law: kinds of `KINDS` in four cases, each in 46 forms of marks after first
        ##   label, and plain after each of five labels.
    var lenient = 0
    for kind in KINDS:
      for word in [kind, kind.capitalizeAscii, kind.toUpperAscii,
          toSeq(kind.pairs).mapIt(if it[0] mod 2 == 0: it[1].toUpperAscii else: it[1]).join]:
        var lines = labels.mapIt(it & " " & word)
        for wrap in wraps:
          lines.add labels[0] & " " & wrap & word & wrap
          for mark in ends:
            lines.add labels[0] & " " & wrap & word & wrap & mark
            if wrap.len > 0: lines.add labels[0] & " " & wrap & word & mark & wrap
        for line in lines:
          check blocksHeld(build & lineSaid("## Prediction\n\n" & line &
            " of the fix.\n\n- Judgement: it builds (70%).") & wake &
            linesAgent(kind, "Do it") & ran & lineHandback(kind, "a" & kind) & checked &
            lineSaid(reflectedProbe("it builds"))).len == 0
          inc lenient
    check lenient == forms

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

    # Exempt call takes only block of its own kind, never block of other exempt kind (C3 of
    #   critic of pairing build); call of type no template names, or of no type, takes none,
    #   though block names no kind, so reflection quotes none of it.
    for (prediction, count) in [(predicting("resolver"), 0), (PREDICTION, 2),
        (predicting("critic"), 2)]:
      check blocksHeld(review & lineSaid(prediction) & wake & linesAgent("resolver") & ran &
        checked & lineSaid(REFLECTION)).len == count

    # Exempt call looks back over turns any call does: block of critic before call of builder
    #   serves no later critic (C25), and of two blocks of critic it takes nearest (C26).
    let
      refused = @[refusalCell("the race to save one shared key leads the findings"),
        refusalCell("four to eight findings, each with `file:line`")]
      far = named("critic", "the critic fails one claim")
      near = named("critic", "the critic holds each claim")
    check blocksHeld(review & lineSaid(predicting("critic")) & wake &
      linesAgent("builder", "Build the fix") & ran & lineHandback("builder", "abuilder") &
      checked & lineSaid(REFLECTION)) == refused
    check blocksHeld(review & lineSaid(far) & wake & lineSaid(near) & wake & checked &
      lineSaid(reflectedProbe("the critic fails one claim", "the critic holds each claim"))) ==
      @[refusalCell("the critic fails one claim")]

    # Two blocks of one kind in two text items of one turn, with tool call between them: call
    #   takes earliest, so reflection that quotes it passes, and claim of later one is refused
    #   (C12).
    check blocksHeld(build & lineSaid(named("builder", "claim 1 holds"), "tool_use") &
      linesCall("ls") & lineSaid(named("builder", "claim 2 holds")) & wake &
      linesAgent("builder") & ran & lineHandback("builder", "abuilder") & checked &
      lineSaid(reflectedProbe("claim 1 holds", "claim 2 holds"))) ==
      @[refusalCell("claim 2 holds")]

    # Cost: later block of kind, written before call, replaces earlier block of that kind, as
    #   guide states (7022770415). So of two blocks for two subagents of one kind, first call
    #   takes block of nearer turn, and reflection that quotes other one is refused (probe F4).
    check blocksHeld(review & lineSaid(named("reviewer", "diff one has a race")) &
      lineUser("Review diff two too.", "human") &
      lineSaid(named("reviewer", "diff two has no race")) & wake &
      linesAgent("reviewer", "Review diff one") & ran & lineHandback("reviewer", "areviewer") &
      checked & lineSaid(reflectedProbe("diff one has a race"))) ==
      @[refusalCell("diff one has a race")]
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
    check alone.splitLines == @[LINE_BLOCKS, "message=\"call of `builder`\""]  # line form
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
        @["report of critic takes `## Reflection` block of its own after it, above any " &
          "sign-off or working line (GUIDE.md, Prediction, critic and reflection); got none " &
          "for report `1` of `1` in this turn"]
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
      missing = @["report of critic takes `## Reflection` block of its own after it, above " &
        "any sign-off or working line (GUIDE.md, Prediction, critic and reflection); got none " &
        "for report `1` of `1` in this turn"]
    check blocksHeld(taken & lineSaid("The critic held each claim.\n\n" & working & "\n" &
      REFLECTION)) == missing
    check rulesHeld(taken & lineSaid("The critic held each claim.\n\n" & working & "\n" &
      REFLECTION)) == @["koch.reflection"]

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
      blocksHeld(before & lineSaid("## Reflection\n\n**Subagent:** builder, 160,000 tokens and " &
        "$2.10 at list price.\n\n" & table & "\n- **Change:** none.\n"))
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

    # Reflection quotes nothing with no table, no row, or empty cell; record states table of
    #   bullets, since GUIDE.md states tables alone (#1028).
    const bullets = "holds `Predicted`, as block of bullets takes it (curator/audit/PROVENANCE.md"
    check reflected("No table.").anyIt(bullets in it)
    check reflected("| State | Result |\n| --- | --- |\n| ✅ | it leads |").anyIt(bullets in it)
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
        ("Judgement: ", "no test is weakened"),
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
      for cell in cells: rows.add "| ✅ | 70% | " & cell & " | 1, it holds |\n"
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
    #   refused, and so is claim of bullet with no mark that keeps its final full stop
    #   (7017902016).
    for cell in ["the race leads the findings (70%)",
        "Judgement: the race leads the findings (70%)", "the race leads the findings (70%).",
        "the race leads the findings (70%). Resolution criterion: it is the first finding.",
        "tokens summed over its requests: 100,000, 160,000 and 300,000, as the 10th, 50th and " &
          "90th percentiles", "10th 150, 50th 260, 90th 420.", "no test is weakened.",
        "Judgement: no test is weakened."]:
      check reflected([cell]) == @[refusalCell(cell)]

    # Claim ends at its confidence, last percentage in brackets of any count of digits before
    #   first of `, as the 10th` and `. Resolution criterion`, in any order, or before its end
    #   (7018501890, test below); with no percentage there, at that first mark; with none, it
    #   runs to end of bullet, before one final full stop (7017902016, test below). Claim whose
    #   percentiles come first runs to them, and keeps each percentage (7023048202, test below).
    for (bullet, claim) in [("- a b (5%) c", "a b"), ("- a b (70%) c", "a b"),
        ("- a b (100%) c", "a b"), ("- a b, as the 10th c", "a b"),
        ("- a b, as the 5th c", "a b"), ("- a b, as the 10th c, as the 5th d", "a b"),
        ("- a b (70%), as the 5th c. Resolution criterion: d", "a b (70%)"),
        ("- a b, as the 5th c (70%). Resolution criterion: d", "a b"),
        ("- a b. Resolution criterion: c", "a b"),
        ("- a b (70%), as the 10th c. Resolution criterion: d", "a b (70%)"),
        ("- a b, as the 10th c (70%). Resolution criterion: d", "a b"),
        ("- a b. Resolution criterion: c (70%), as the 10th d", "a b"),
        ("- a b. Resolution criterion: c, as the 10th d (70%)", "a b"),
        ("- a b c (60%) d (70%)", "a b c (60%) d"), ("- a b", "a b"), ("- a b.", "a b")]:
      check passes(bullet, claim)
      check passes(bullet, bullet[2 .. ^1]) == (bullet[2 .. ^1] == claim)

    # Brackets with no percentage in them, and other words, end nothing, so claim reads them;
    #   criterion in lower case is mark, by choice of delegate (test below).
    for bullet in ["- a (duty 2) b", "- a (70 %) b", "- a (about 70%) b", "- a(70%) b",
        "- a (%) b", "- a (70% b", "- a, as the 50th b", "- a as the 10th b",
        "- a as the 5th b", "- a, as the 95th b"]:
      check passes(bullet, bullet[2 .. ^1])
      check not passes(bullet, "a")
    check passes("- a. resolution criterion. b", "a")
    check not passes("- a. resolution criterion. b", "a. resolution criterion. b")

    # Label is one word that opens with capital, then `: `, at start of claim (7018501890, test
    #   below); `: ` of resolution criterion alone opens none.
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


  test "claim with no mark ends before one final full stop of its bullet (7017902016 of #969)":
    # Ruling 7017902016 of #969: claim with no percentage, no percentiles and no resolution
    #   criterion ends before one final full stop of its bullet. Case as found is stop of entry
    #   882 of copy of transcript of delegate on #962 (record at `522cae46`, Runs of block check):
    #   reflection quoted two bullets of block of entry 817 that hold no mark, and cut final full
    #   stop of each, which build `b8491db8` refused.
    let
      asked = lineUser("Research the practice of forecasting.", "human")
      calls = lineUser("<task-notification>timer</task-notification>", "task-notification") &
        linesAgent("researcher") & lineSaid("Started.") &
        lineHandback("researcher", "aresearcher") & linesAgent("critic") &
        lineSaid("The critic runs.") & lineHandback("critic")
    proc passes(bullets, cell: string): bool =
      ## Decide whether cell passes, where block that call of `researcher` took holds bullets
      ##   alone.
      blocksHeld(asked & lineSaid("## Prediction\n\n**Subagent:** researcher of forecasting " &
        "practice, fresh context.\n\n" & bullets & "\n") & calls & lineSaid("## Reflection\n\n" &
        "| State | Confidence | Predicted | Result |\n| --- | --- | --- | --- |\n| ✅ | 80% | " &
        cell & " | 1, it holds |\n"), ["critic", "researcher"]).len == 0

    # Case as found: each cell drops final full stop of its bullet, and passes; cell that keeps
    #   it is refused. Text before `: ` of each bullet is several words, so it is no label, and
    #   part after it is refused (7018501890, test below).
    const found = "- Tokens, summed over its requests: 10th percentile 1 million, median 3 " &
      "million, 90th percentile 8 million.\n- Cost at list price: 10th percentile $1.50, median " &
      "$3.50, 90th percentile $8."
    for cell in ["Tokens, summed over its requests: 10th percentile 1 million, median 3 " &
        "million, 90th percentile 8 million",
        "Cost at list price: 10th percentile $1.50, median $3.50, 90th percentile $8"]:
      check passes(found, cell)
      check not passes(found, cell & ".")
    for cell in ["10th percentile 1 million, median 3 million, 90th percentile 8 million",
        "10th percentile $1.50, median $3.50, 90th percentile $8"]:
      check not passes(found, cell)
      check not passes(found, cell & ".")

    # Claim with no mark ends before one final full stop, whatever whitespace or wrap ends its
    #   bullet, and before no other mark; full stop inside claim stays, and so does one before
    #   mark, since claim with mark ends at mark.
    for (bullet, cells, refused) in [
        ("- a b", @["a b"], @["a b.", "a"]),
        ("- a b.", @["a b"], @["a b.", "a"]),
        ("- a b..", @["a b."], @["a b..", "a b"]),
        ("- a b.\t ", @["a b"], @["a b."]),
        ("- a\n  b.", @["a b"], @["a b.", "a"]),
        ("- a. b.", @["a. b"], @["a. b.", "a"]),
        ("- Judgement: a b.", @["Judgement: a b", "a b"], @["Judgement: a b.", "a b."]),
        ("- a b?", @["a b?"], @["a b"]),
        ("- a b!", @["a b!"], @["a b"]),
        ("- a b.)", @["a b.)"], @["a b.", "a b"]),
        ("- a b. (70%)", @["a b."], @["a b", "a b. (70%)"]),
        ("- a b. (70%).", @["a b."], @["a b", "a b. (70%)"]),
        ("- a b., as the 10th c.", @["a b."], @["a b"]),
        ("- a b. Resolution criterion: c.", @["a b"], @["a b.", "a b. Resolution criterion: c"]),
        ("- a b (70%).", @["a b"], @["a b.", "a b (70%)"])]:
      for cell in cells: check passes(bullet, cell)
      for cell in refused: check not passes(bullet, cell)


  test "confidence ends claim: last percentage in brackets before its marks (7018501890 of #969)":
    # Ruling 7018501890 of #969: claim runs up to its own confidence, last percentage in brackets
    #   before its percentiles, its resolution criterion or its end; percentage inside text of
    #   claim stays in claim. So for `- the replay refuses 2 of 54 stops (4%) or fewer (70%).`,
    #   cell `the replay refuses 2 of 54 stops (4%) or fewer` passes, and its part is refused.
    #   Cases as found are probes M1 and M2 of critic of build of D5 b: build `b8491db8` ended
    #   claim at its first percentage, so it refused whole claim and passed its part.
    const found = "- Result: the replay refuses 2 of 54 stops (4%) or fewer (70%). Resolution " &
      "criterion: the report says so.\n- Judgement: no test is weakened (85%). Resolution " &
      "criterion: the report says so."
    for cell in ["the replay refuses 2 of 54 stops (4%) or fewer",
        "Result: the replay refuses 2 of 54 stops (4%) or fewer", "no test is weakened"]:
      check quoted(found, cell).len == 0
    for cell in ["the replay refuses 2 of 54 stops", "Result: the replay refuses 2 of 54 stops",
        "the replay refuses 2 of 54 stops (4%) or fewer (70%)"]:
      check quoted(found, cell) == @[refusalCell(cell)]

    # Example of ruling, with no label and no resolution criterion.
    const example = "- the replay refuses 2 of 54 stops (4%) or fewer (70%)."
    check quoted(example, "the replay refuses 2 of 54 stops (4%) or fewer").len == 0
    for cell in ["the replay refuses 2 of 54 stops", "the replay refuses 2 of 54 stops (4%)",
        "the replay refuses 2 of 54 stops (4%) or fewer (70%)",
        "the replay refuses 2 of 54 stops (4%) or fewer (70%)."]:
      check quoted(example, cell) == @[refusalCell(cell)]

    # Law over one to three percentages, with words after last one or none, before each end:
    #   claim runs up to last percentage and keeps each one before it; cut before earlier one,
    #   claim that keeps last one, and whole bullet are refused. Claim with percentiles runs up
    #   to them and keeps each percentage (7023048202), so each cut before them is refused.
    const
      ends = ["", ".", ". Resolution criterion: z.", ", as the 10th z."]
        ## Ends of bullet after its words: none, full stop, and each mark.
      layouts = 24
        ## Bullets of law: three counts of percentages, two tails, and each end.
    var laid = 0
    for count in 1 .. 3:
      for tail in ["", " y"]:
        for ending in ends:
          var
            text = "w0"
            cuts: seq[string]  # Text before each percentage, in order.
          for n in 1 .. count:
            cuts.add text
            text.add " (" & $(10 * n) & "%)"
            if n < count: text.add " w" & $n
          let bullet = "- " & text & tail & ending
          if ending.startsWith(", as the 10th"):
            check quoted(bullet, text & tail).len == 0
            for cell in cuts & (if tail.len > 0: @[text] else: @[]) & @[bullet[2 .. ^1]]:
              check quoted(bullet, cell) == @[refusalCell(cell)]
          else:
            check quoted(bullet, cuts[^1]).len == 0
            for cell in cuts[0 ..< cuts.high] & @[text, bullet[2 .. ^1]]:
              check quoted(bullet, cell) == @[refusalCell(cell)]
          inc laid
    check laid == layouts

    # Percentage after first mark is no confidence, and two percentages may stand side by side.
    for (bullet, claim, refused) in [
        ("- a (10%) b. Resolution criterion: c (20%).", "a", @["a (10%) b"]),
        ("- a (10%) b, as the 10th c (20%). Resolution criterion: d (30%).", "a (10%) b", @["a"]),
        ("- a b. Resolution criterion: c (20%).", "a b", @["a b. Resolution criterion: c"]),
        ("- a (10%) (20%).", "a (10%)", @["a", "a (10%) (20%)"]),
        ("- a (10%) b. (20%).", "a (10%) b.", @["a", "a (10%) b"])]:
      check quoted(bullet, claim).len == 0
      for cell in refused: check quoted(bullet, cell) == @[refusalCell(cell)]

    # Mark between two percentages ends no claim, full stop too, so confidence stays last one
    #   (KC3 of critic of claim build).
    for joint in [". ", ", ", "; ", " "]:
      let bullet = "- a (10%)" & joint & "b (20%)."
      check quoted(bullet, "a (10%)" & joint & "b").len == 0
      check quoted(bullet, "a") == @[refusalCell("a")]

    # Mark that stands twice in bullet ends claim at its first place (KC1).
    for (bullet, refused) in [
        ("- a. Resolution criterion: b. Resolution criterion: c.", "a. Resolution criterion: b"),
        ("- a, as the 10th b, as the 10th c.", "a, as the 10th b"),
        ("- a (70%). Resolution criterion: b (20%). Resolution criterion: c.",
          "a (70%). Resolution criterion: b")]:
      check quoted(bullet, "a").len == 0
      check quoted(bullet, refused) == @[refusalCell(refused)]


  test "percentage in brackets may hold decimal part, as `(62.5%)` (D5 b of #969)":
    # Ruling 7016134603, D5 b of #969: claim runs up to its percentage, which ruling 7018501890
    #   names its confidence; digits alone narrowed it. Case as found is probe M6 of critic of
    #   build of D5 b: build `b8491db8` read no percentage in `(62.5%)`, so it refused claim cut
    #   before it, and passed claim that keeps it.
    const found = "- Judgement: the race to save one shared key leads the findings (62.5%). " &
      "Resolution criterion: the report says so.\n- Judgement: no test is weakened (85%). " &
      "Resolution criterion: the report says so."
    for cell in ["the race to save one shared key leads the findings",
        "Judgement: the race to save one shared key leads the findings"]:
      check quoted(found, cell).len == 0
    for cell in ["the race to save one shared key leads the findings (62.5%)",
        "Judgement: the race to save one shared key leads the findings (62.5%)"]:
      check quoted(found, cell) == @[refusalCell(cell)]

    # Percentage is digits, then point and digits where it has decimal part, then `%)`; other
    #   text in brackets is none, so claim keeps it.
    for percentage in ["(0.5%)", "(62.5%)", "(99.99%)", "(100.0%)", "(7%)", "(05%)"]:
      let whole = "a b " & percentage & " c"
      check quoted("- " & whole & ".", "a b").len == 0
      check quoted("- " & whole & ".", whole) == @[refusalCell(whole)]
    for brackets in ["(62.%)", "(.5%)", "(62,5%)", "(6.2.5%)", "(62.5 %)", "(62. 5%)",
        "(62 .5%)", "( 62.5%)", "(62.5)", "(62.5%", "(62..5%)"]:
      let whole = "a b " & brackets & " c"
      check quoted("- " & whole & ".", whole).len == 0
      check quoted("- " & whole & ".", "a b") == @[refusalCell("a b")]

    # Decimal percentage is confidence where it stands last, and stays in claim where it does not,
    #   as in claim with percentiles (7023048202).
    for (bullet, claim) in [("- a (1.5%) b (62.5%).", "a (1.5%) b"),
        ("- a (62.5%) b (70%).", "a (62.5%) b"), ("- a b (62.5%)", "a b"),
        ("- a b (62.5%), as the 10th c.", "a b (62.5%)")]:
      check quoted(bullet, claim).len == 0
      check quoted(bullet, bullet[2 .. ^1]) == @[refusalCell(bullet[2 .. ^1])]


  test "claim with percentiles runs to them, and keeps each percentage (7023048202 of #969)":
    # Ruling 7023048202 of #969: percentiles of number claim state its confidence, so claim with
    #   percentiles takes no confidence in brackets. It runs to its percentiles, and percentage in
    #   brackets in its text, as `(10% cached)`, stays in claim. Cases as found are probe F11 of
    #   critic of claim build and cost that record named: build `1f4d159a` ended such claim at
    #   last percentage of its text, so it refused cell that quotes claim whole.
    const found = "- Work: refused stops (of 54): 2 (4%), 3 (6%) and 5 (9%), as the 10th, 50th " &
      "and 90th percentiles. Resolution criterion: the replay."
    for cell in ["refused stops (of 54): 2 (4%), 3 (6%) and 5 (9%)",
        "Work: refused stops (of 54): 2 (4%), 3 (6%) and 5 (9%)"]:
      check quoted(found, cell).len == 0
    for cell in ["refused stops (of 54): 2 (4%), 3 (6%) and 5", "refused stops (of 54): 2",
        "refused stops (of 54): 2 (4%), 3 (6%) and 5 (9%), as the 10th, 50th and 90th " &
          "percentiles"]:
      check quoted(found, cell) == @[refusalCell(cell)]

    # Example of ruling, and cost that record named, whose expected result changes by ruling.
    const
      cached = "- Work: tokens: 1, 2 and 3 million (10% cached), as the 10th, 50th and 90th " &
        "percentiles."
      ranged = "- Work: a (5%) b: 1, 2 and 3, as the 10th, 50th and 90th percentiles."
    check quoted(cached, "tokens: 1, 2 and 3 million (10% cached)").len == 0
    check quoted(cached, "tokens: 1, 2 and 3 million") ==
      @[refusalCell("tokens: 1, 2 and 3 million")]
    for cell in ["a (5%) b: 1, 2 and 3", "Work: a (5%) b: 1, 2 and 3"]:
      check quoted(ranged, cell).len == 0
    for cell in ["Work: a", "a"]: check quoted(ranged, cell) == @[refusalCell(cell)]

    # Percentiles must be first mark: percentage after them ends nothing, and criterion before
    #   them leaves claim at its confidence, since percentiles then belong to criterion.
    for (bullet, claim, refused) in [
        ("- Work: tokens: 1, 2 and 3, as the 10th, 50th and 90th percentiles (80%). Resolution " &
          "criterion: the sum.", "tokens: 1, 2 and 3", @["tokens: 1, 2 and 3, as the 10th"]),
        ("- a (5%) b (70%), as the 10th c (20%).", "a (5%) b (70%)", @["a (5%) b", "a"]),
        ("- a (5%) b (70%). Resolution criterion: c, as the 10th d.", "a (5%) b",
          @["a (5%) b (70%)", "a"]),
        ("- a (62.5%) b (7.5%), as the 10th c.", "a (62.5%) b (7.5%)", @["a (62.5%) b", "a"])]:
      check quoted(bullet, claim).len == 0
      for cell in refused: check quoted(bullet, cell) == @[refusalCell(cell)]


  test "criterion with or without bold, in any case, is mark that ends claim (choice on #969)":
    # Choice of delegate, which no comment names: mark of resolution criterion is read with or
    #   without bold marks and in any case of letters, so `**Resolution criterion:**` and
    #   `Resolution Criterion:` end claim too, and percentage of criterion is no confidence.
    #   Cases as found are probes F02, F03 and F07 of critic of claim build: build `1f4d159a`
    #   read words of samples alone, so percentage of such criterion ended claim. Ruling
    #   7027197745 of #969: after full stop, criterion in italics, in bold, or in both ends claim
    #   too, as `. *Resolution criterion:*`; build `9d4b7eff` read italics as text.
    for (found, refused) in [
        ("- Judgement: the race leads the findings (70%). **Resolution criterion:** the critic " &
          "holds at least 4 of 5 claims (80%).", "the race leads the findings (70%). " &
          "**Resolution criterion:** the critic holds at least 4 of 5 claims"),
        ("- Judgement: the race leads the findings (70%). **Resolution criterion:** it is the " &
          "first finding.", "the race leads the findings (70%)"),
        ("- Judgement: the race leads the findings (70%). Resolution Criterion: at least 4 of 5 " &
          "claims (80%) hold.", "the race leads the findings (70%). Resolution Criterion: at " &
          "least 4 of 5 claims")]:
      check quoted(found, "the race leads the findings").len == 0
      check quoted(found, refused) == @[refusalCell(refused)]

    # Law: words of criterion in each case, plain, or in each form of italics, bold or both, with
    #   colon inside or outside marks, end claim at confidence before them, or at them where none
    #   stands there (7027197745).
    const
      cases = ["Resolution criterion", "resolution criterion", "Resolution Criterion",
        "RESOLUTION CRITERION", "rEsOlUtIoN cRiTeRiOn"]
        ## Cases of letters of words of criterion.
      wraps = [("*", "*"), ("_", "_"), ("**", "**"), ("__", "__"), ("***", "***"),
        ("_**", "**_"), ("**_", "_**"), ("*__", "__*"), ("__*", "*__"), ("___", "___")]
        ## Opening and closing of each form of italics, bold, and both.
      marks = 210
        ## Bullets of law: each case, plain and in twenty forms of marks, with confidence before
        ##   or none.
    var laid = 0
    for words in cases:
      var forms = @[words & ":"]
      for (opening, closing) in wraps:
        forms.add opening & words & ":" & closing
        forms.add opening & words & closing & ":"
      for form in forms:
        for (bullet, claim) in [("- a (70%). " & form & " b (80%).", "a"),
            ("- a c. " & form & " b (80%).", "a c")]:
          check quoted(bullet, claim).len == 0
          check quoted(bullet, bullet[2 .. ^2]) == @[refusalCell(bullet[2 .. ^2])]
          inc laid
    check laid == marks

    # Choice leaves out each other form, so later percentage stays confidence there: criterion
    #   after semicolon or comma, in italics there too, plural, on next line with no full stop,
    #   with no space after full stop, in four marks, struck, and other words (probes F04, F05
    #   and F06).
    for form in ["; resolution criterion:", ", resolution criterion:", "; *Resolution criterion:*",
        ". Resolution criteria:", "\n  Resolution criterion:", ".*Resolution criterion:*",
        ". ****Resolution criterion:****", ". ~~Resolution criterion:~~", ". Criterion:",
        ". Resolution:"]:
      let bullet = "- a (70%)" & form & " b (80%)."
      check quoted(bullet, "a") == @[refusalCell("a")]
      check quoted(bullet, ("a (70%)" & form & " b").splitWhitespace.join(" ")).len == 0

    # Of two forms of criterion in one bullet, first one ends claim, whichever form it is, as
    #   first of `, as the 10th` and criterion does.
    for (first, second) in [("Resolution criterion:", "**Resolution criterion:**"),
        ("**Resolution criterion:**", "Resolution criterion:"),
        ("resolution criterion:", "Resolution Criterion:"),
        ("*Resolution criterion:*", "Resolution criterion:"),
        ("Resolution criterion:", "_**Resolution criterion:**_")]:
      let bullet = "- a (70%). " & first & " b (80%). " & second & " c (90%)."
      check quoted(bullet, "a").len == 0
      check quoted(bullet, "a (70%). " & first & " b") ==
        @[refusalCell("a (70%). " & first & " b")]


  test "label is one word that opens with capital, then `: ` (7018501890 of #969)":
    # Ruling 7018501890 of #969: label is one word that opens with capital, then `: `, as
    #   `Judgement:` or `Work:`; colon inside sentence makes no label, so cell quotes whole claim
    #   there. Cases as found are probes M3, M4 and M5 of critic of build of D5 b: build
    #   `b8491db8` read text before first `: ` of claim as label, so it passed part after colon
    #   of claim with no label (M4), and claim without its words before colon (M5). Ruling
    #   7022872980 makes bold label (M3) label, so cell may drop it (test below).
    for (found, cells, refused) in [
        ("- **Judgement:** the race to save one shared key leads the findings (70%). " &
          "Resolution criterion: the report says so.",
          @["**Judgement:** the race to save one shared key leads the findings",
            "the race to save one shared key leads the findings"],
          @["Judgement: the race to save one shared key leads the findings"]),
        ("- the refusal names one cause: the missing block (70%). Resolution criterion: the " &
          "report says so.", @["the refusal names one cause: the missing block"],
          @["the missing block", "the refusal names one cause"]),
        ("- Cost at list price: $15 to $35 (60%). Resolution criterion: the sum of its requests.",
          @["Cost at list price: $15 to $35"], @["$15 to $35", "list price: $15 to $35"])]:
      for cell in cells: check quoted(found, cell).len == 0
      for cell in refused: check quoted(found, cell) == @[refusalCell(cell)]

    # Label of one word whose first is capital, then `: `, at start of claim: claim passes with it
    #   and without it, and part after first `: ` of rest of claim is refused. Ruling 7022872980
    #   makes any run with no space such word, as `Q1` (test below).
    for label in ["Judgement", "Work", "Result", "Cost", "Tokens", "A", "NOTE", "WorK", "Q1",
        "Follow-up", "Judgement's", "Judgement."]:
      let bullet = "- " & label & ": a: b (70%)."
      for cell in [label & ": a: b", "a: b"]: check quoted(bullet, cell).len == 0
      for cell in ["b", label & ": b", "a"]: check quoted(bullet, cell) == @[refusalCell(cell)]

    # Other text before `: ` is no label, so cell quotes whole claim: word in lower case, two or
    #   more words, word that opens with mark, and words of sentence. Bold word before `: ` is
    #   label (7027197745, test below).
    for opening in ["judgement", "jUDGEMENT", "work", "Cost at list price", "Big Work",
        "Tokens, summed over its requests", "*Judgement*", "`Judgement`", "_Judgement_",
        "the refusal names one cause"]:
      let bullet = "- " & opening & ": a b (70%)."
      check quoted(bullet, opening & ": a b").len == 0
      check quoted(bullet, "a b") == @[refusalCell("a b")]

    # Capital word and `: ` inside claim make no label: label opens claim.
    for (bullet, whole, refused) in [
        ("- a Judgement: b (70%).", "a Judgement: b", @["b", "Judgement: b", "a"]),
        ("- the hook says Work: b c (70%).", "the hook says Work: b c", @["b c", "Work: b c"]),
        ("- Judgement:  a b (70%).", "Judgement: a b", @["Judgement:", "Judgement: a"]),
        ("- Judgement: (70%).", "Judgement:", @["Judgement"])]:
      check quoted(bullet, whole).len == 0
      for cell in refused: check quoted(bullet, cell) == @[refusalCell(cell)]

    # Other label before whole claim, label before claim that has none, and label twice are
    #   refused.
    for (bullet, refused) in [
        ("- Judgement: a b (70%).", @["Work: a b", "Result: a b", "judgement: a b",
          "Judgement: Judgement: a b", "Work: Judgement: a b"]),
        ("- a b (70%).", @["Judgement: a b", "Work: a b"]),
        ("- Cost at list price: a b (70%).", @["Cost: a b", "Work: Cost at list price: a b"])]:
      for cell in refused: check quoted(bullet, cell) == @[refusalCell(cell)]

    # Cell that differs from claim only in case of one letter is refused, with label or without.
    const
      claimed = "- Judgement: the Race leads (70%)."
        ## Bullet whose claim holds letters of each case, in its label and after it.
      letters = 33
        ## Letters of `Judgement: the Race leads` and of `the Race leads`, each flipped once.
    var flipped = 0
    for claim in ["Judgement: the Race leads", "the Race leads"]:
      check quoted(claimed, claim).len == 0
      for i, c in claim:
        if c notin Letters: continue
        var cell = claim
        cell[i] = (if c.isUpperAscii: c.toLowerAscii else: c.toUpperAscii)
        check quoted(claimed, cell) == @[refusalCell(cell)]
        inc flipped
    check flipped == letters


  test "label in bold is label, so cell may drop it (7022872980 of #969)":
    # Ruling 7022872980 of #969: label in bold, as `**Judgement:**`, is label, so cell may drop
    #   it. Case as found is probe M3 of critic of build of D5 b, as test above holds it: build
    #   `1f4d159a` read bold label as text, so it refused cell that drops it.
    # Ruling 7027197745 of #969: bold label with its colon outside bold, `__Judgement:__` and
    #   `***Judgement:***` are labels too. Cases as found are in D2 of report of last build,
    #   and its critic: build `9d4b7eff` read each as text, so it refused cell that drops it.
    # Label and its colon in each form of bold, then space, at start of claim: claim passes with
    #   it and without it; part after first `: ` of rest, label with no bold or no colon, and
    #   claim that drops label but keeps its marks are refused.
    const forms = [("**", ":**"), ("**", "**:"), ("__", ":__"), ("***", ":***")]
      ## Opening and closing of each form of bold label, with colon inside or outside bold.
    for (opening, closing) in forms:
      for label in ["Judgement", "Work", "Result", "Cost", "A", "NOTE", "WorK", "Q1", "Follow-up"]:
        let
          bold = opening & label & closing
          bullet = "- " & bold & " a: b (70%)."
        for cell in [bold & " a: b", "a: b"]: check quoted(bullet, cell).len == 0
        for cell in ["b", bold & " b", label & ": a: b", opening & label & opening & " a: b",
            opening & opening & " a: b", closing & " a: b"]:
          check quoted(bullet, cell) == @[refusalCell(cell)]

    # Other bold or marked text makes no label, so cell quotes whole claim: italic, bold of
    #   underscores or bold and italic with colon outside, italic around bold, bold around
    #   italic, two words, lower case, empty bold, space inside bold, and no space after.
    for opening in ["*Judgement:*", "_Judgement:_", "__Judgement__:", "***Judgement***:",
        "_**Judgement:**_", "**_Judgement:_**", "**Big Work:**", "**judgement:**", "**:**",
        "** Judgement:**", "**Judgement: **", "**Judgement** :"]:
      let bullet = "- " & opening & " a b (70%)."
      check quoted(bullet, opening & " a b").len == 0
      check quoted(bullet, "a b") == @[refusalCell("a b")]
    for opening in ["**Judgement:**", "**Judgement**:"]:
      check quoted("- " & opening & "a b (70%).", opening & "a b").len == 0
      check quoted("- " & opening & "a b (70%).", "a b") == @[refusalCell("a b")]

    # Claim drops one label alone, bold or not, at its start; bold label inside claim is text.
    for (bullet, cells, refused) in [
        ("- **Judgement:** Work: b (70%).", @["**Judgement:** Work: b", "Work: b"], @["b"]),
        ("- Judgement: **Work:** b (70%).", @["Judgement: **Work:** b", "**Work:** b"], @["b"]),
        ("- a **Judgement:** b (70%).", @["a **Judgement:** b"], @["b", "**Judgement:** b"])]:
      for cell in cells: check quoted(bullet, cell).len == 0
      for cell in refused: check quoted(bullet, cell) == @[refusalCell(cell)]


  test "label is any run with no space that opens with capital, then `: ` (7022872980 of #969)":
    # Ruling 7022872980 of #969: label is any run with no space that opens with capital letter,
    #   then `: `, so `Q1:` and `Follow-up:` are labels. Cases as found are probes F21 and F22 of
    #   critic of claim build: build `1f4d159a` read label as letters alone, so it refused cell
    #   that drops `Follow-up:` or `Q1:`.
    for (found, cell) in [
        ("- Follow-up: the critic asks for one more test (60%). Resolution criterion: its " &
          "report.", "the critic asks for one more test"),
        ("- Q1: the race leads the findings (70%). Resolution criterion: it is first.",
          "the race leads the findings")]:
      check quoted(found, cell).len == 0
      check quoted(found, found[2 ..< found.find(" (")]).len == 0

    # Law: capital letter, then each class of character, is label, in each form of bold or not
    #   (7027197745); run that opens with other character, or holds space, is none.
    const
      tails = ["", "1", "bc", "-up", "'s", ".", "_b", "/b", "(b)", "#2", "`b`", "*b", ":"]
        ## Rest of run after its capital: none, digit, letters, and each mark.
      openings = ["a1", "1a", "-a", "'a", ".a", "_a", "`a`", "(a)", "#a", "R b", "R1 b"]
        ## Runs that open with no capital, or hold space.
      laws = 120
        ## Bullets of law: each tail and each opening, plain and in four forms of bold.
    var laid = 0
    for (runs, is_label) in [(tails.mapIt("R" & it), true), (openings.toSeq, false)]:
      for run in runs:
        for label in [run & ": ", "**" & run & ":** ", "**" & run & "**: ", "__" & run & ":__ ",
            "***" & run & ":*** "]:
          let bullet = "- " & label & "a: b (70%)."
          check quoted(bullet, label & "a: b").len == 0
          check (quoted(bullet, "a: b").len == 0) == is_label
          check quoted(bullet, "b") == @[refusalCell("b")]
          inc laid
    check laid == laws


  test "finding of empty cell names `No prediction` as form of miss (D2 c of #969)":
    # Ruling 7015791554, D2 c of #969: row of missing prediction holds exactly `No prediction`
    #   under `Predicted`, and guide names form. Case as found is item 13 of part 5 of report of
    #   critic of build of D5 b: finding of empty cell asked for claim word for word alone, and
    #   named no `No prediction`, though cell left empty most likely counts missed prediction.
    const
      header = "| State | Confidence | Predicted | Result |\n| --- | --- | --- | --- |\n"
      missing = "| ⬜ | - | No prediction | it never ran |\n"
        ## Row of missing prediction, which passes wherever its reflection stands.
    let
      asked = lineUser("Build the check.", "human")
      wake = lineUser("<task-notification>timer</task-notification>", "task-notification")
      calls = wake & linesAgent("builder") & lineSaid("Started.") &
        lineHandback("builder", "abuilder") & linesAgent("critic") & lineSaid("The critic runs.") &
        lineHandback("critic")
      taken = asked & lineSaid(PREDICTION) & calls
      missed = asked & lineSaid("Read.") & calls
      alone = asked & wake & linesAgent("critic") & lineSaid("The critic runs.") &
        lineHandback("critic")

    # Empty cell in each row, two empty cells, short row, and cell of whitespace alone, where call
    #   took block, where no call took one, and where critic alone ran: finding states rule of
    #   each cell, `No prediction` in it.
    for before in [taken, missed, alone]:
      for (rows, found) in [
          ("| ⬜ | 60% |  | missed |\n", @[refusalEmpty(1)]),
          (missing & "| ⬜ | 60% |  | missed |\n" & missing, @[refusalEmpty(2)]),
          (missing & missing & "| ⬜ | 60% |  | missed |\n", @[refusalEmpty(3)]),
          ("| ⬜ | 60% |  | a |\n| ⬜ | 60% |  | b |\n", @[refusalEmpty(1), refusalEmpty(2)]),
          ("| ⬜ | 60% |\n", @[refusalEmpty(1)]),
          ("| ⬜ | 60% |  \t  | missed |\n", @[refusalEmpty(1)])]:
        let held = blocksHeld(before & lineSaid("## Reflection\n\n" & header & rows))
        check held == found
        check held.allIt("`No prediction` (curator/audit/PROVENANCE.md, Quotes of claims)" in it)


  test "claim reads `\\|` as `|`, as cell does (7022872980 of #969)":
    # Ruling 7022872980 of #969: check reads `\|` as `|` in claim too, as it does in cell, so
    #   cell that quotes such claim with `\|` passes. Case as found is cost that record named:
    #   build `1f4d159a` kept `\|` in claim, so cell that copied it was refused, and only cell
    #   that wrote `\\|` quoted it. Expected result of that check changes by ruling.
    const piped = "- Judgement: a \\| b (70%)."
    for cell in ["a \\| b", "Judgement: a \\| b"]: check quoted(piped, cell).len == 0
    for cell in ["a \\\\| b", "Judgement: a \\\\| b"]:
      check quoted(piped, cell) == @[refusalCell(cell.replace("\\\\|", "\\|"))]

    # Law: each count of pipes up to three, each one bare or escaped in block, quotes as cell that
    #   escapes each one, and refuses cell that escapes any one twice.
    const pipes = 14  ## Bullets of law: two forms of each of one, two and three pipes.
    var laid = 0
    for count in 1 .. 3:
      for mask in 0 ..< (1 shl count):  # Pipe `n` is escaped in block where bit `n` is set.
        var written, cell: string
        for n in 0 ..< count:
          written.add "w" & $n & (if (mask shr n and 1) == 1: " \\| " else: " | ")
          cell.add "w" & $n & " \\| "
        let bullet = "- " & written & "end (70%)."
        check quoted(bullet, cell & "end").len == 0
        for n in 0 ..< count:
          let twice = cell.replace("w" & $n & " \\| ", "w" & $n & " \\\\| ") & "end"
          check quoted(bullet, twice).len == 1
        inc laid
    check laid == pipes

    # Two backslashes before pipe of block read as one, as in cell, and other escape stays.
    check quoted("- a \\\\| b (70%).", "a \\\\| b").len == 0
    check quoted("- a \\\\| b (70%).", "a \\| b") == @[refusalCell("a | b")]
    check quoted("- a \\* b (70%).", "a \\* b").len == 0
    check quoted("- Q\\|1: a (70%).", "a").len == 0  # pipe of label reads first


  test "line right under claim that opens item ends claim (choice on #969)":
    # Choice of delegate, which no comment names: line right under claim that Markdown opens as
    #   item, as `1. ` or marker with tab, ends that claim, since Markdown reads it as new item.
    #   Cases as found are probes F08 and F09 of critic of claim build: build `1f4d159a` read such
    #   line as text of claim above it, so its percentage became confidence of that claim.
    for (bullets, cells) in [
        ("- Judgement: the race leads the findings (70%). Resolution criterion: it is first.\n" &
          "- Judgement: no test is weakened (85%).\n1. Work: four commits (60%).",
          @["the race leads the findings", "no test is weakened"]),
        ("- Judgement: no test is weakened (85%).\n-\tWork: four commits (60%).",
          @["no test is weakened"])]:
      for cell in cells: check quoted(bullets, cell).len == 0
      check quoted(bullets, "four commits") == @[refusalCell("four commits")]  # opens no claim

    # Law: each form under claim `a b`, or under claim `a b d` that wraps once, at each indent,
    #   ends claim where pandoc 3.1.3 of GFM breaks paragraph, and goes on with claim where it
    #   reads text of claim. Below two columns each marker of item ends claim; from two, line
    #   stands inside bullet, where only marker or number of value 1 with text after it ends
    #   claim (CommonMark, List items), so `01.` does as `1.` does. Cases as found are `01. c` and
    #   `001) c` of critic of last build, where build `9d4b7eff` compared text `01` with `1`, and
    #   its breaks X9 and X2, which no test caught: wrapped claim, and colon after number.
    const
      indents = ["", " ", "  ", "   ", "    ", "\t", "     "]
        ## Indents of zero to five columns, tab as four.
      forms = [("1. c", true), ("1) c", true), ("1.\tc", true), ("-\tc", true), ("*\tc", true),
        ("+\tc", true), ("- c", true), ("* c", true), ("01. c", true), ("001) c", true),
        ("2. c", false), ("10) c", false), ("123456789. c", false), ("2.\tc", false),
        ("0. c", false), ("02. c", false), ("1.", false), ("2)", false), ("*", false),
        ("+", false), ("1. ", false)]
        ## Lines that open item below two columns, and whether they open one from two columns.
      texts = ["1234567890. c", "1.c", "1: c", "c", "c (70%)"]
        ## Lines that open no item: ten digits, no space after mark, colon, and text.
      openers = [("- a b\n", "a b"), ("- a b\n  d\n", "a b d")]
        ## Claims above each line: on one line, and wrapped once.
      lines = 364
        ## Cases of law: each form and each text at each indent, under each claim.
    var laid = 0
    for (opener, claim) in openers:
      for indent in indents:
        let is_inside = indent.len >= 2 or indent == "\t"
        for (form, is_inside_item) in @forms & texts.mapIt((it, false)):
          let
            bullets = opener & indent & form
            is_item = form notin texts and (not is_inside or is_inside_item)
          check (quoted(bullets, claim).len == 0) == is_item
          inc laid
    check laid == lines


  test "costs of read of claim stay as record names them (#969)":
    # Record, Quotes of claims, names these costs, which critic of build of D5 b found by probe;
    #   each holds here so that change to it shows.
    # Indent of one to three spaces, `1.`, or tab after marker opens no claim, so no cell quotes
    #   that bullet.
    for bullet in [" - a b (70%).", "   - a b (70%).", "-\ta b (70%).", "*\ta b (70%).",
        "1. a b (70%).", "1) a b (70%)."]:
      for cell in ["a b", bullet.strip.split(maxsplit = 1)[1]]:
        check quoted(bullet, cell) == @[refusalCell(cell)]

    # Bullet that is no claim, as question, reads as one.
    check quoted("- Judgement: does it hold?", "does it hold?").len == 0

    # Percentage in brackets after confidence, before mark or end, is last one, so claim runs
    #   past its confidence up to it (probe F20 of critic of claim build).
    const after = "- Judgement: the replay refuses fewer stops (70%), as 2 of 54 (4%). " &
      "Resolution criterion: the replay."
    for cell in ["the replay refuses fewer stops (70%), as 2 of 54",
        "Judgement: the replay refuses fewer stops (70%), as 2 of 54"]:
      check quoted(after, cell).len == 0
    check quoted(after, "the replay refuses fewer stops") ==
      @[refusalCell("the replay refuses fewer stops")]

    # From six columns of indent, Markdown reads line under claim as text of claim, yet item or
    #   bullet there ends claim, as each does at two columns (test of line under claim above).
    for form in ["1. c", "1) c", "-\tc", "- c", "* c"]:
      check quoted("- a b\n      " & form, "a b").len == 0
      check quoted("- a b\n      " & form, "a b " & form.splitWhitespace.join(" ")).len == 1

    # Capital word and colon that open claim make label, whatever sentence they open, as `Koch:`
    #   of probe F17 of critic of claim build (7022872980); capital outside `A` to `Z` makes none.
    const capital = "- Koch: the check passes at the head (80%). Resolution criterion: the log."
    for cell in ["Koch: the check passes at the head", "the check passes at the head"]:
      check quoted(capital, cell).len == 0
    check quoted("- Écart: a b (70%).", "Écart: a b").len == 0
    check quoted("- Écart: a b (70%).", "a b") == @[refusalCell("a b")]

    # Each capital from `A` to `Z` opens label (break X14 of critic of last build, which dropped
    #   `Z`).
    for capital in 'A' .. 'Z':
      check quoted("- " & capital & "b: a (70%).", "a").len == 0

    # Words of percentiles read in lower case alone, so `, As the 10th` opens none, and claim
    #   runs to its criterion (break X1 of critic of last build, which read them in any case).
    const upper = "- Work: cost: $1, $2 and $3, As the 10th, 50th and 90th percentiles. " &
      "Resolution criterion: the usage."
    check quoted(upper, "cost: $1, $2 and $3, As the 10th, 50th and 90th percentiles").len == 0
    check quoted(upper, "cost: $1, $2 and $3") == @[refusalCell("cost: $1, $2 and $3")]

    # Words of criterion that claim quotes in its text end it there, as mark does (critic of
    #   last build), so cell quotes claim up to them.
    const quoting = "- Judgement: the hook reads `. **Resolution criterion:**` as mark (70%). " &
      "Resolution criterion: the report."
    check quoted(quoting, "the hook reads `").len == 0
    check quoted(quoting, "the hook reads `. **Resolution criterion:**` as mark") ==
      @[refusalCell("the hook reads `. **Resolution criterion:**` as mark")]


  test "costs of read of value and of tables of claims stay as record names them (#1028)":
    # Record, Quotes of claims, names these costs, which builder of mends measured by probe and
    #   critic of mends (finding 6) found no suite to hold; each holds here so that change shows.
    # Scale that value does not name, as `bn` or `Mio`, reads as text, so result reads digits
    #   before it, and logs that wrong value with no finding.
    let
      whole = REFLECTION_TABLES_POSTED.mended
      line = whole.splitLines.filterIt(it.startsWith("| 6 |"))[0]
    #   Point before such scale makes no count, so cell of tokens takes refusal there.
    for cell in ["39.1 bn, inside", "39.1 Mio, inside"]:
      check cell.valueAt.get.amount == 39.1
    for cell in ["39 bn, inside", "39 Mio, inside"]:
      check cell.valueAt.get.amount == 39.0
      check heldReflection(PREDICTION_TABLES, whole.replace(line,
        line.replace("39.1M, inside", cell))).len == 0

    # Three digits of other figure after one space read as group, as `5 100-line files` reads
    #   5,100, and result of count takes it with no finding.
    check "5 100-line files".valueAt.get.amount == 5100.0
    check "5 100-line files".outcomeResult(UnitNumber.Count).get == 5100.0

    # Header with none of columns that make table of claims, as `| No. | % | Judgements |`, reads
    #   as no table, so block reads 3 claims of 8, and takes 5 findings, from its criteria alone.
    let off = PREDICTION_TABLES.replace("| # | % | Judgement |", "| No. | % | Judgements |")
    check off.forecasts.len == 3
    check heldBlock(off).len == 5
    check heldBlock(off).allIt(it.startsWith("row of table of criteria of block names"))


  test "block of tables reads each claim from its row, by its number (7200557915 of #1028)":
    # Case as found: example of comment 7200557915, which `D1 a` of comment 7218520265 rules.
    let read = PREDICTION_TABLES.forecasts
    check read.mapIt(it.position) == toSeq(1..8)
    check read.allIt(it.is_row and it.forms.len == 1)
    check read[0].forms == @["Its last commit passes `nim r koch check` with 0 findings."]
    check read[7].forms == @["The builder takes ~50m."]
    check read.mapIt(it.is_number) == @[false, false, false, false, false, true, true, true]
    check read.mapIt(it.confidence.get) == @[0.8, 0.8, 0.75, 0.75, 0.55, 0.9, 0.9, 0.9]
    check read[0 .. 4].allIt(it.estimate.isNone)
    check read[5].estimate == some(Estimate(low: 5e6, median: 15e6, high: 45e6,
      unit: UnitNumber.Tokens))
    check read[6].estimate == some(Estimate(low: 2.5, median: 7, high: 20, unit: UnitNumber.Cost))
    check read[7].estimate == some(Estimate(low: 20, median: 50, high: 120, unit: UnitNumber.Time))
    check PREDICTION_TABLES.findingsPrediction.len == 0  # each claim has its criterion
    check heldBlock(PREDICTION_TABLES).len == 0

    # Hook skips sentence above each table: block with no label or sentence reads same claims.
    var bare = PREDICTION_TABLES
    for line in PREDICTION_TABLES.splitLines:
      if line.startsWith("**Judgements.**") or line.startsWith("**Estimates.**") or
          line.startsWith("**Criteria.**") or line == "its 90% range.":
        bare = bare.replace(line & "\n", "")
    check bare != PREDICTION_TABLES
    check bare.forecasts == read

    # Rows 2, 4 and 5 of reflection as posted quote part of their claim, so each is refused, as
    #   D5 b of #969 refuses part of claim; whole quotes pass.
    let refusals = heldReflection(PREDICTION_TABLES, REFLECTION_TABLES_POSTED)
    check refusals.len == 3
    for k, (part, _) in QUOTES_PART:
      check refusals[k] == "row of table of judgements or estimates of reflection names claim " &
        "of `## Prediction` block that call took by its number under `#`, and quotes that " &
        "claim whole, or holds `No prediction` (GUIDE.md, Prediction, critic and reflection); " &
        "got `" & $[2, 4, 5][k] & "` and `" & part & "`"
    check heldReflection(PREDICTION_TABLES, REFLECTION_TABLES_POSTED.mended).len == 0


  test "value of cell reads its marks of unit and scale, and nothing past them (7194411522)":
    # Domain: each mark of cost, form of digits, scale and mark of time, as cells of estimate
    #   and opening of result write them; `M` of million and `m` of minutes differ by case.
    const
      costs = ["", "$"]
      digits = [("5", 5.0), ("0.5", 0.5), ("1,500", 1500.0), ("12.25", 12.25)]
      scales = [("", 1.0), ("k", 1e3), ("M", 1e6)]
      times = [("", 1.0), ("s", 1.0 / 60), ("m", 1.0), ("h", 60.0)]
    var count = 0
    for cost in costs:
      for (written, amount) in digits:
        for (scale, factor) in scales:
          for (time, minutes) in times:
            let cell = cost & written & scale & time
            if cost.len > 0 and time.len > 0:
              check cell.valueAt.isNone  # cost and time at once
              continue
            let value = cell.valueAt
            check value.isSome and value.get.stop == cell.len
            check value.get.amount.isNear(amount * factor * minutes)
            check value.get.unit == (if cost.len > 0: UnitNumber.Cost
              elif time.len > 0: UnitNumber.Time else: UnitNumber.Unspecified)
            check (cell & ", inside").valueAt == value  # result opens with value
            check (cell & "x").valueAt.isNone  # letter runs on
            if scale.len + time.len > 0: check (cell & "0").valueAt.isNone  # digit runs on
            inc count
    check count == 2 * 4 * 3 * 4 - 4 * 3 * 3  # each form but those of cost and time at once
    check "39.1M".valueAt.get.amount == 39_100_000.0  # point moves before parse, so exact
    check "39,100,000".valueAt.get.amount == "39.1M".valueAt.get.amount
    check "1.2345k".valueAt.get.amount == 1234.5
    for cell in ["", "$", "k", "m", "~5", "-5", " 5", "$m5", "five"]:
      check cell.valueAt.isNone
    check "5 m".valueAt.get.stop == 1  # space ends value, so cell `5 m` is no whole value
    check "1,23".valueAt.isNone  # comma before digit that opens no group runs on (#1028)


  test "estimate takes unit of its cells, in one unit, rising (7194411522 of #1028)":
    func estimate(text: string, cells: array[3, string]): Option[Estimate] =
      ## Read estimate of block of one estimate of text with cells.
      blockEstimate(text, cells).forecasts[0].estimate
    check estimate("~2 tokens.", ["1", "2", "3"]).get.unit == UnitNumber.Tokens
    check estimate("~2 TOKENS.", ["1", "2", "3"]).get.unit == UnitNumber.Tokens  # any case
    check estimate("Tokens: ~2.", ["1", "2", "3"]).get.unit == UnitNumber.Tokens
    check estimate("~2 findings.", ["1", "2", "3"]).get.unit == UnitNumber.Count
    check estimate("~2 tokenset.", ["1", "2", "3"]).get.unit == UnitNumber.Count  # no word
    check estimate("~2 token.", ["1", "2", "3"]).get.unit == UnitNumber.Count
    check estimate("~$2 in tokens.", ["$1", "$2", "$3"]).get.unit == UnitNumber.Cost  # cell first
    check estimate("~2m.", ["1s", "2m", "3h"]) == some(Estimate(low: 1.0 / 60, median: 2,
      high: 180, unit: UnitNumber.Time))
    check estimate("~1M tokens.", ["500k", "1M", "1.5M"]) == some(Estimate(low: 5e5,
      median: 1e6, high: 1.5e6, unit: UnitNumber.Tokens))

    # Cells of two units, cells that do not rise, and cells that are no whole value are each
    #   refused, as finding of block, and give no estimate.
    let rule = "estimate states its 5th, 50th and 95th percentiles under their columns, each " &
      "cell one value, of one unit, each above one before: `$` for cost, `s`, `m` or `h` for " &
      "time, bare number for tokens or count, each scaled by `k` or `M` where it needs " &
      "(GUIDE.md, Prediction, critic and reflection)"
    var refused: seq[array[3, string]] = @[["$1", "2", "3"], ["1m", "2", "3"], ["$1", "2m", "3h"],
      ["1", "1", "2"], ["1", "2", "2"], ["2", "2", "2"], ["2k", "1M", "900"],
      ["~1", "2", "3"], ["1 m", "2m", "3m"], ["", "2", "3"], ["one", "2", "3"]]
    for cells in [["1 m", "2 m", "3 m"], ["1", "2", "3 findings"], ["$1", "$2", "$3 each"]]:
      refused.add cells  # value of one unit opens each cell, and text runs on past it
    for order in [[1, 3, 2], [2, 1, 3], [2, 3, 1], [3, 1, 2], [3, 2, 1]]:
      refused.add [$order[0], $order[1], $order[2]]  # each order of 1, 2 and 3 but rising
    for cells in refused:
      check estimate("~2 findings.", cells).isNone
      check heldBlock(blockEstimate("~2 findings.", cells)) ==
        @[rule & "; got `" & cells.join("`, `") & "` for claim `1`"]
    check heldBlock(blockEstimate("~2 findings.", ["1", "2", "3"])).len == 0


  test "each claim of tables takes number of its own, text, confidence and criterion (#1028)":
    func without(text, line: string): string =
      ## Write text with line, and its newline, taken out.
      doAssert line & "\n" in text
      text.replace(line & "\n", "")
    func refusal(rule, got: string): string =
      ## Write finding of block that rule states, with what it got.
      rule & " (GUIDE.md, Prediction, critic and reflection); got " & got
    const
      criterion = "claim takes its resolution criterion in row of its number of table with " &
        "column `Resolution criterion`"
      number = "row of table of judgements or estimates of block opens with number of its own " &
        "under `#`, as digits alone, from 1"
      row_criteria = "row of table of criteria of block names, by its number under `#` as digits " &
        "alone, from 1, claim of block that no other row names"
      confidence = "judgement states its confidence alone under `%`, as `70%` or `62.5%`"
      text = "claim of table states its text under `Judgement` or `Estimate @ 90%`"
      row3 = "| 3 | The critic finds no HTTP request in the code that `start` runs. |"

    # Missing criterion, empty one, and one of no number each leave claim with none.
    check heldBlock(PREDICTION_TABLES.without(row3)) ==
      @[refusal(criterion, "none for claim `3`")]
    check rulesHeld(lineUser("Build it.", "human") & lineSaid(PREDICTION_TABLES.without(row3))) ==
      @["koch.prediction-tables"]
    check heldBlock(PREDICTION_TABLES.replace(row3, "| 3 |  |")) ==
      @[refusal(criterion, "none for claim `3`")]
    check heldBlock(PREDICTION_TABLES.replace(row3, row3.replace("| 3 |", "| 3. |"))) ==
      @[refusal(criterion, "none for claim `3`"), refusal(row_criteria, "`3.`")]
    let none = PREDICTION_TABLES[0 ..< PREDICTION_TABLES.find("**Criteria.**")]
    check heldBlock(none) == toSeq(1..8).mapIt(refusal(criterion, "none for claim `" & $it & "`"))

    # Number of row is whole number from 1, of its own across both tables.
    const row1 = "| 1 | 80% | Its last commit passes `nim r koch check` with 0 findings. |"
    for cell in ["", "0", "#1", "1.", "x", "1 2"]:
      check heldBlock(PREDICTION_TABLES.replace(row1, row1.replace("| 1 |", "| " & cell & " |"))) ==
        @[refusal(number, "`" & cell & "`")]
    check heldBlock(PREDICTION_TABLES.replace("| 6 | The builder", "| 3 | The builder")) ==
      @[refusal(number, "`3`")]

    # Confidence of judgement is percentage alone; text of claim is never empty.
    for cell in ["", "80", "80 %", "(80%)", "eighty", "80%."]:
      check heldBlock(PREDICTION_TABLES.replace("| 1 | 80% |", "| 1 | " & cell & " |")) ==
        @[refusal(confidence, "`" & cell & "` for claim `1`")]
    check heldBlock(PREDICTION_TABLES.replace("| 1 | 80% |", "| 1 | 62.5% |")).len == 0
    check PREDICTION_TABLES.replace("| 1 | 80% |", "| 1 | 62.5% |").forecasts[0].confidence ==
      some(0.625)
    check heldBlock(PREDICTION_TABLES.replace(row1, "| 1 | 80% |  |")) ==
      @[refusal(text, "empty cell for claim `1`")]

    # Block of bullets takes none of these, so block of delegate that runs at merge still serves.
    check heldBlock(PREDICTION).len == 0


  test "each table of claims of block holds its form whole, and each criterion names claim (#1028)":
    # Case as found: header one character off its form read as no table and gave no finding at
    #   stop of its own turn, so reflection was refused later, where no mend serves call. Domain:
    #   each column of each form dropped or one character off, each order of columns, and each
    #   criterion of no claim or of claim that other row names (GUIDE.md, Prediction, critic and
    #   reflection).
    const
      forms = [
        ("| # | % | Judgement |", @["#", "%", "Judgement"]),
        ("| # | Estimate @ 90% | 5th | 50th | 95th |",
          @["#", "Estimate @ 90%", "5th", "50th", "95th"]),
        ("| # | Resolution criterion |", @["#", "Resolution criterion"]),
      ]
      rule = "table of block whose header holds `#`, `Judgement`, `Estimate @ 90%` or " &
        "`Resolution criterion` holds each column of one form: `#`, `%` and `Judgement`, or `#`, " &
        "`Estimate @ 90%`, `5th`, `50th` and `95th`, or `#` and `Resolution criterion` " &
        "(GUIDE.md, Prediction, critic and reflection); got `"
      orphan = "row of table of criteria of block names, by its number under `#` as digits " &
        "alone, from 1, claim of block that no other row names (GUIDE.md, Prediction, critic " &
        "and reflection); got `"
    func header(names: openArray[string]): string =
      ## Write header row of names, as table of fixture writes it.
      "| " & names.join(" | ") & " |"
    for (line, names) in [(forms[0][0], @["#", "%", "Judgements"]),
        (forms[1][0], @["#", "Estimate @90%", "5th", "50th", "95th"])]:
      let changed = PREDICTION_TABLES.tableColumns(line, toSeq(0 ..< names.len), names)
      check heldBlock(changed) == @[rule & names.header & "`"]  # case as found
      check heldReflection(changed, REFLECTION_TABLES_POSTED.mended).len > 0  # its rows read none

    # Table that drops column of its form, or holds column one character off, takes one finding,
    #   and its rows read as none; criteria are held to claims only once each table holds form.
    var count = 0
    for (line, names) in forms:
      for k, column in names:
        let kept = toSeq(0 ..< names.len).filterIt(it != k)
        var offs = @[column & "s", column[0 ..< ^1]]
        if column[0] in Letters: offs.add (if column[0].isUpperAscii: column.toLowerAscii
          else: column.capitalizeAscii)
        let dropped = PREDICTION_TABLES.tableColumns(line, kept)
        check heldBlock(dropped) == @[rule & kept.mapIt(names[it]).header & "`"]
        check dropped.forecasts.len == PREDICTION_TABLES.forecasts.len -
          (if line == forms[0][0]: 5 elif line == forms[1][0]: 3 else: 0)
        for off in offs:
          var named = names
          named[k] = off
          check heldBlock(PREDICTION_TABLES.tableColumns(line, toSeq(0 ..< names.len), named)) ==
            @[rule & named.header & "`"]
          inc count
    check count == 3 * 2 + 5 * 2 + 2 * 2 + 3  # added, dropped, and case of each opening letter

    # Each order of columns of each form reads same claims, since hook reads columns by name; table
    #   with extra column, or with no column that names form, reads too.
    for (line, names) in forms:
      var order = toSeq(0 ..< names.len)
      while true:
        let moved = PREDICTION_TABLES.tableColumns(line, order)
        check heldBlock(moved).len == 0
        check moved.forecasts == PREDICTION_TABLES.forecasts
        if not order.nextPermutation: break
    check heldBlock(blockEstimate("~2 findings.", ["1", "2", "3"], has_criterion = false) &
      "\n| # | Resolution criterion | Note |\n| --- | --- | --- |\n| 1 | The line. | x |\n")
      .len == 0
    check heldBlock(PREDICTION_TABLES.replace("**Working:**",
      "| Option | Cost |\n| --- | --- |\n| a | $1 |\n\n**Working:**")).len == 0

    # Criterion of number of no claim, or of claim of other row, is refused, as is row of no
    #   number (finding 5 of critic of mends).
    const row8 = "| 8 | The minutes on the line `**Subagent:**` of the reflection. |"
    for number in 0 .. 10:
      let extra = PREDICTION_TABLES.replace(row8, row8 & "\n| " & $number & " | A criterion. |")
      check heldBlock(extra) == @[orphan & $number & "`"]
    check heldBlock(PREDICTION_TABLES.replace(row8, row8 & "\n| x | A note. |")) == @[orphan & "x`"]


  test "number under `#` of each table of claims of block is digits alone, from 1 (#1028)":
    # Case as found (finding 5 of critic of mends): row `6.` of criteria beside row `6`, and row
    #   of criteria with no number, passed, so two criteria could name one claim. Domain: each
    #   cell that is no digits alone, or 0, under `#` of each table of claims of block.
    const
      number = "row of table of judgements or estimates of block opens with number of its own " &
        "under `#`, as digits alone, from 1 (GUIDE.md, Prediction, critic and reflection); got `"
      row_criteria = "row of table of criteria of block names, by its number under `#` as digits " &
        "alone, from 1, claim of block that no other row names (GUIDE.md, Prediction, critic " &
        "and reflection); got `"
      row6 = "| 6 | The tokens on the line `**Subagent:**` of the reflection. |"
      row7 = "| 7 | The builder costs ~$7.00. | $2.50 | $7.00 | $20.00 |"
    check heldBlock(PREDICTION_TABLES.replace(row6, row6 & "\n| 6. | The line. |")) ==
      @[row_criteria & "6.`"]  # case as found
    check heldBlock(PREDICTION_TABLES.replace(row6, row6 & "\n|  | The line. |")) ==
      @[row_criteria & "`"]
    var count = 0
    for cell in ["", "0", "6.", "#6", "x", "6 7", "-6", "+6", "6a", "(6)", "６"]:
      check heldBlock(PREDICTION_TABLES.replace(row6, row6 & "\n| " & cell & " | The line. |")) ==
        @[row_criteria & cell & "`"]
      check heldBlock(PREDICTION_TABLES.replace(row7, row7.replace("| 7 |", "| " & cell & " |"))) ==
        @[number & cell & "`"]
      inc count
    check count == 11
    check heldBlock(PREDICTION_TABLES.replace(row6, row6 & "\n| 06 | The line. |")) ==
      @[row_criteria & "6`"]  # digits alone read past leading zero, so claim is named twice
    check heldBlock(PREDICTION_TABLES).len == 0


  test "block of tables holds no bullet beside them, as bullet and row take one key (#1028)":
    # Case as found: bullet at position 1 and row 1 of table of one block took one key of log,
    #   so `appendClaims` dropped one row. Domain: bullet of each marker before, between and
    #   after tables, with number of claim of table or none, and two bullets.
    const rule = "block that holds table whose header holds `#`, `Judgement`, `Estimate @ 90%` " &
      "or `Resolution criterion` holds no bullet beside it (GUIDE.md, Prediction, critic and " &
      "reflection); got `"
    let found = PREDICTION_TABLES.replace("**Judgements.**",
      "- Work: four to eight findings (60%).\n\n**Judgements.**")
    check found.forecasts.mapIt(it.position).count(1) == 2  # bullet and row share one number
    check heldBlock(found) == @[rule & "Work: four to eight findings`"]  # case as found
    for marker in ["-", "*", "+"]:
      for before in ["**Judgements.**", "**Estimates.**", "**Criteria.**", "**Working:**"]:
        for (bullet, claim) in [("Work: four to eight findings (60%).",
            "Work: four to eight findings"), ("the report ranks 9 findings (60%).",
            "the report ranks 9 findings")]:
          let text = PREDICTION_TABLES.replace(before, marker & " " & bullet & "\n\n" & before)
          check heldBlock(text) == @[rule & claim & "`"]
    let two = PREDICTION_TABLES.replace("**Criteria.**",
      "- Work: a (60%).\n- Work: b (70%).\n\n**Criteria.**")
    check heldBlock(two) == @[rule & "Work: a`", rule & "Work: b`"]
    check heldBlock(PREDICTION).len == 0  # bullets alone, as block of delegate that runs at merge

    # Table of claims that reads no row of claims, as one of criteria alone or one character off
    #   its form, still makes bullet beside it refused, as its rows share numbers too.
    let criteria = "## Prediction\n\n**Subagent:** builder of the fix, fresh context.\n\n" &
      "- Work: four to eight findings (60%).\n\n| # | Resolution criterion |\n| --- | --- |\n" &
      "| 1 | The line. |\n"
    check heldBlock(criteria)[0] == rule & "Work: four to eight findings`"
    check heldBlock(criteria.replace("| # | Resolution criterion |",
      "| # | Resolution criteria |"))[0] == rule & "Work: four to eight findings`"


  test "bullet with indent, or item of number, under basis passes, as it holds no claim (#1028)":
    # Case as found (finding 3 of third critic): bullet indented under `**Basis:**` passed, where
    #   GUIDE.md said hook refuses bullet beside tables. Domain: each marker of bullet at each
    #   indent of one to four spaces or tab, and item of number, under basis of block of tables;
    #   none reads as claim, so none takes key of log that row takes; bullet with no indent does.
    const
      basis = "**Basis:** what this delegate knows, with no new read."
      rule = "block that holds table whose header holds `#`, `Judgement`, `Estimate @ 90%` " &
        "or `Resolution criterion` holds no bullet beside it (GUIDE.md, Prediction, critic and " &
        "reflection); got `"
    func listed(opening: string): string =
      ## Write block of tables whose basis lists two items, each opening with opening.
      PREDICTION_TABLES.replace(basis, "**Basis:** what this delegate knows:\n\n" & opening &
        "the diff of `main`\n" & opening & "the report")
    var count = 0
    for marker in ["- ", "* ", "+ "]:
      for indent in [" ", "  ", "   ", "    ", "\t"]:
        check listed(indent & marker).forecasts.len == 8  # claims of tables alone
        check heldBlock(listed(indent & marker)).len == 0
        inc count
      check heldBlock(listed(marker)) == @[rule & "the diff of `main``", rule & "the report`"]
    check count == 3 * 5
    for item in ["1. ", "1) ", "  1. "]:
      check heldBlock(listed(item)).len == 0 and listed(item).forecasts.len == 8


  test "block is held at stop of its own turn, and its mend of later turn serves call (#1028)":
    # Delegate mends block in reply, which is later turn, so block of that turn serves call.
    let
      broken = PREDICTION_TABLES.replace("| 1 | 80% |", "| 1 | 80 |")
      text = lineUser("Build it.", "human") & lineSaid(broken) &
        lineSaid(PREDICTION_TABLES) &
        lineUser("<task-notification>timer</task-notification>", "task-notification") &
        linesAgent("builder") & lineSaid("Started.")
      subagents = text.parseTurn.subagents
    check heldBlock(broken).len == 1
    check subagents.predictions.len == 2
    check subagents.blocksTaken(KINDS) == @[1]
    check blocksHeld(text).len == 0  # broken block stands in earlier turn


  test "row of reflection quotes claim by its number and its text (7200557915 of #1028)":
    let whole = REFLECTION_TABLES_POSTED.mended
    func refusal(number, text: string): string =
      ## Write finding of row of table with `#` that quotes no claim.
      "row of table of judgements or estimates of reflection names claim of `## Prediction` " &
        "block that call took by its number under `#`, and quotes that claim whole, or holds " &
        "`No prediction` (GUIDE.md, Prediction, critic and reflection); got `" & number &
        "` and `" & text & "`"
    const three = "It adds no network call to the start hook."
    check heldReflection(PREDICTION_TABLES, whole.replace("| 3 | ✅ |", "| 4 | ✅ |")) ==
      @[refusal("4", three)]  # number of other claim
    check heldReflection(PREDICTION_TABLES, whole.replace("| 3 | ✅ |", "| 9 | ✅ |")) ==
      @[refusal("9", three)]  # number of no claim
    check heldReflection(PREDICTION_TABLES, whole.replace("| 3 | ✅ |", "| three | ✅ |")) ==
      @[refusal("three", three)]
    check heldReflection(PREDICTION_TABLES, whole.replace(three, "It adds no network call.")) ==
      @[refusal("3", "It adds no network call.")]
    check heldReflection(PREDICTION_TABLES, whole.replace(three,
      three.replace(" ", "   "))).len == 0  # each run of whitespace reads as one space
    check heldReflection(PREDICTION_TABLES, whole.replace("| 8 | ✅ | The builder takes ~50m.",
      "| 7 | ✅ | The builder takes ~50m.")) == @[refusal("7", "The builder takes ~50m.")]
    check heldReflection(PREDICTION_TABLES, whole.replace("| 3 | ✅ | 75% | " & three,
      "| 3 | ✅ | 75% | ")) == @["row of table of judgements or estimates of reflection names " &
      "claim of `## Prediction` block that call took by its number under `#`, and quotes that " &
      "claim whole, or holds `No prediction` (GUIDE.md, Prediction, critic and reflection); " &
      "got empty cell in row `3`"]

    # Missed prediction holds `No prediction`, whatever its number; reflection with no table of
    #   claims, and table with no row, are refused.
    let missed = "## Reflection\n\n| # | State | % | Judgement | Result |\n" &
      "| --- | --- | --- | --- | --- |\n| – | ⬜ | – | No prediction | started before it |\n"
    check heldReflection(PREDICTION_TABLES, missed).len == 0
    check heldReflection(PREDICTION_TABLES, "## Reflection\n\nNone.\n") == @[REFUSAL_NO_TABLE]
    check heldReflection(PREDICTION_TABLES, "## Reflection\n\n| # | State | Estimate @ 90% | " &
      "Result |\n| --- | --- | --- | --- |\n") == @["table of reflection holds row under its " &
      "header; got none under `| # | State | Estimate @ 90% | Result |`"]

    # Bullets of delegate that runs at merge quote either way: cell under `Predicted` quotes claim
    #   of table, and row with `#` quotes bullet by its position, with or without its label.
    check heldReflection(PREDICTION_TABLES, "## Reflection\n\n| State | Confidence | " &
      "Predicted | Result |\n| --- | --- | --- | --- |\n| ✅ | 75% | " & three & " | yes |\n").len ==
      0
    for (number, cell) in [("1", "the race to save one shared key leads the findings"),
        ("1", "Judgement: the race to save one shared key leads the findings"),
        ("2", "four to eight findings, each with `file:line`")]:
      let reflection = "## Reflection\n\n| # | State | % | Judgement | Result |\n" &
        "| --- | --- | --- | --- | --- |\n| " & number & " | ✅ | 70% | " & cell & " | yes |\n"
      check heldReflection(PREDICTION, reflection).len == 0
      check heldReflection(PREDICTION, reflection.replace("| " & number & " |", "| 3 |")) ==
        @[refusal("3", cell)]

    # Block that holds bullets and tables reads claims of both, so row quotes claim of either.
    let
      mixed = PREDICTION_TABLES.replace("**Judgements.**",
        "- Work: four to eight findings (60%).\n\n**Judgements.**")
      bullet = "## Reflection\n\n| # | State | % | Judgement | Result |\n" &
        "| --- | --- | --- | --- | --- |\n| 1 | ✅ | 60% | four to eight findings | five |\n"
    check mixed.forecasts.len == 9
    check mixed.forecasts[0].forms == @["Work: four to eight findings", "four to eight findings"]
    check heldReflection(mixed, whole).len == 0
    check heldReflection(mixed, bullet).len == 0


  test "each table of claims of reflection holds its form whole (7200557915 of #1028)":
    # Case as found: `| # | State | Estimate | Result |` read as no table and gave no finding, so
    #   log lost three estimates. Domain: each column of each form dropped or one character off,
    #   each order of columns, and table that names no form (GUIDE.md, Prediction, critic and
    #   reflection).
    const
      forms = [
        ("| # | State | % | Judgement | Result |", @["#", "State", "%", "Judgement", "Result"]),
        ("| # | State | Estimate @ 90% | Result |", @["#", "State", "Estimate @ 90%", "Result"]),
      ]
      rule = "table of reflection whose header holds `#`, `Judgement` or `Estimate @ 90%` holds " &
        "each column of one form: `#`, `State`, `%`, `Judgement` and `Result`, or `#`, `State`, " &
        "`Estimate @ 90%` and `Result` (GUIDE.md, Prediction, critic and reflection); got `"
    func header(names: openArray[string]): string =
      ## Write header row of names, as table of fixture writes it.
      "| " & names.join(" | ") & " |"
    let
      whole = REFLECTION_TABLES_POSTED.mended
      found = whole.tableColumns(forms[1][0], toSeq(0 ..< 4), ["#", "State", "Estimate", "Result"])
    check heldReflection(PREDICTION_TABLES, found) ==
      @[rule & "| # | State | Estimate | Result |`"]  # case as found
    check found.rowsReflection.len == 5  # its rows read as none
    let alone = "## Reflection\n\n" & found[found.find("| # | State | Estimate |") .. ^1]
    check heldReflection(PREDICTION_TABLES, alone) == @[rule & "| # | State | Estimate | Result |`"]

    # Table that drops column of its form, or holds column one character off, takes one finding,
    #   and its rows read as none.
    var count = 0
    for (line, names) in forms:
      for k, column in names:
        let kept = toSeq(0 ..< names.len).filterIt(it != k)
        var offs = @[column & "s", column[0 ..< ^1]]
        if column[0] in Letters: offs.add column.toLowerAscii
        let dropped = whole.tableColumns(line, kept)
        check heldReflection(PREDICTION_TABLES, dropped) == @[rule & kept.mapIt(names[it]).header &
          "`"]
        check dropped.rowsReflection.len == (if line == forms[0][0]: 3 else: 5)
        for off in offs:
          var named = names
          named[k] = off
          let changed = whole.tableColumns(line, toSeq(0 ..< names.len), named)
          check heldReflection(PREDICTION_TABLES, changed) == @[rule & named.header & "`"]
          inc count
    check count == 5 * 2 + 4 * 2 + 3 + 3  # added, dropped, and case of each opening letter

    # Each order of columns reads same rows, since hook reads columns by name; table with no
    #   column that names form, and table with column `Predicted`, read as before.
    for (line, names) in forms:
      var order = toSeq(0 ..< names.len)
      while true:
        let moved = whole.tableColumns(line, order)
        check heldReflection(PREDICTION_TABLES, moved).len == 0
        check moved.rowsReflection == whole.rowsReflection
        if not order.nextPermutation: break
    check heldReflection(PREDICTION_TABLES, whole & "\n| Test | Result |\n| --- | --- |\n" &
      "| suites | pass |\n").len == 0


  test "table of claims is one whose header holds column GUIDE.md names for block or reflection":
    # Case as found (finding 4 of critic of mends, #1028): reflection that adds `| # | Cause |` was
    #   refused, though GUIDE.md named no table of claims by `#`, and `| Claim | Resolution
    #   criterion | Met |` was refused by rule that names no `Resolution criterion`. Domain: each
    #   column of each form, and column of none, with other column, added to block and reflection.
    const
      guide = staticRead("../../../../GUIDE.md")
      block_naming = ["#", "Judgement", "Estimate @ 90%", "Resolution criterion"]
      reflection_naming = ["#", "Judgement", "Estimate @ 90%"]
      form_block = "table of block whose header holds `#`, `Judgement`, `Estimate @ 90%` or " &
        "`Resolution criterion` holds each column of one form: `#`, `%` and `Judgement`, or `#`, " &
        "`Estimate @ 90%`, `5th`, `50th` and `95th`, or `#` and `Resolution criterion` " &
        "(GUIDE.md, Prediction, critic and reflection); got `"
      form_reflection = "table of reflection whose header holds `#`, `Judgement` or " &
        "`Estimate @ 90%` holds each column of one form: `#`, `State`, `%`, `Judgement` and " &
        "`Result`, or `#`, `State`, `Estimate @ 90%` and `Result` (GUIDE.md, Prediction, critic " &
        "and reflection); got `"
    check "**A table of a block is a table of claims where its header holds `#`, `Judgement`, " &
      "`Estimate @ 90%` or `Resolution criterion`.** A table of a reflection is one where its " &
      "header holds `#`, `Judgement` or `Estimate @ 90%`." in guide.collapsed
    let whole = REFLECTION_TABLES_POSTED.mended
    check heldReflection(PREDICTION_TABLES, whole & "\n| # | Cause |\n| --- | --- |\n| 5 | The " &
      "critic read the evidence. |\n") == @[form_reflection & "| # | Cause |`"]  # case as found
    check heldReflection(PREDICTION_TABLES, whole & "\n| Claim | Resolution criterion | Met |\n" &
      "| --- | --- | --- |\n| 5 | The report names such a claim. | yes |\n").len == 0
    var count = 0
    for column in ["#", "Judgement", "Estimate @ 90%", "Resolution criterion", "%", "State",
        "Result", "5th", "Cause"]:
      let
        table = "| " & column & " | Note |\n| --- | --- |\n| 5 | A note. |\n"
        in_block = heldBlock(PREDICTION_TABLES.replace("**Working:**", table & "\n**Working:**"))
        in_reflection = heldReflection(PREDICTION_TABLES, whole & "\n" & table)
      check in_block == (if column in block_naming: @[form_block & "| " & column & " | Note |`"]
        else: @[])
      check in_reflection == (if column in reflection_naming:
        @[form_reflection & "| " & column & " | Note |`"] else: @[])
      count += int(column in block_naming) + int(column in reflection_naming)
    check count == 4 + 3

    # Each refusal that turns on table of claims names each column that makes one there.
    for (refusal, naming) in [(form_block, @block_naming), (form_reflection, @reflection_naming),
        (REFUSAL_NO_TABLE, @reflection_naming), (heldBlock(PREDICTION_TABLES.replace(
        "**Working:**", "- a (60%).\n\n**Working:**"))[0], @block_naming)]:
      let named = refusal[0 ..< refusal.find("(GUIDE.md")]
      check naming.allIt("`" & it & "`" in named)
      check ("`Resolution criterion`" in named) == ("Resolution criterion" in naming)


  test "result of estimate hit or missed opens with its value in unit of its cells (#1028)":
    # Domain: each state, against each form of result of each unit of case as found.
    let whole = REFLECTION_TABLES_POSTED.mended
    const
      rule = "cell under `Result` of estimate marked ✅ or ⬜ opens with its value in unit of " &
        "its cells: `$` for cost, `s`, `m` or `h` for time, bare number for tokens or count " &
        "(GUIDE.md, Prediction, critic and reflection)"
      forms = [
        ("| 6 |", "39.1M, inside", @["39.1M, inside", "39,100,000, inside", "39100000"],
          @["inside", "$39.1M, inside", "39.1m, inside", "~39.1M"]),
        ("| 7 |", "$14.40, inside", @["$14.40, inside", "$14.4"],
          @["14.40, inside", "inside", "$14.40m", "14.40$"]),
        ("| 8 |", "47m, inside", @["47m, inside", "2820s, inside", "0.8h"],
          @["47, inside", "47 min, inside", "47M, inside", "$47m"]),
      ]
    for (row, written, held, refused) in forms:
      for state in ["✅", "⬜", "➖", "⏸️"]:
        let line = whole.splitLines.filterIt(it.startsWith(row))[0]
        for cell in held & refused:
          let
            changed = line.replace("| ✅ |", "| " & state & " |").replace(written, cell)
            found = heldReflection(PREDICTION_TABLES, whole.replace(line, changed))
          if cell in refused and state in ["✅", "⬜"]:
            check found == @[rule & "; got `" & cell & "` for claim `" & row[2 .. ^3] & "`"]
          else: check found.len == 0


  test "result of number of bullets hit or missed opens with value in unit of its text (#1028)":
    # Case as found: bullet of tokens took `170k, inside`, and bullet of time `1.5h, inside`, as
    #   first number of cell, with no finding. Domain: each unit of bullet, each form of value,
    #   each state, under `Predicted` and under `#`; bare value reads in unit text names, as its
    #   percentiles stand bare, and value of other unit is refused, as is cell that opens with no
    #   value (finding 1 of critic of mends).
    const
      numbers = "## Prediction\n\n**Subagent:** builder of the fix, fresh context.\n\n" &
        "- Work: tokens summed over its requests: 100,000, 160,000 and 300,000, as the 5th, " &
        "50th and 95th percentiles.\n- Cost: cost at list price: $0.40, $0.90 and $2.00, as " &
        "the 5th, 50th and 95th percentiles.\n- Time: time to its report, in minutes: 5, 12 and " &
        "30, as the 5th, 50th and 95th percentiles.\n- Count: findings that the report ranks: " &
        "3, 6 and 11, as the 5th, 50th and 95th percentiles.\n"
      rule = REFUSAL_OUTCOME_BULLETS
      forms = [
        ("tokens summed over its requests: 100,000, 160,000 and 300,000",
          @["170,000, inside", "170000", "170k, inside", "0.17M"],
          @["$170k", "170m, inside", "inside", "~170k"]),
        ("cost at list price: $0.40, $0.90 and $2.00",
          @["$1.10, inside", "1.10", "$1.1k"], @["1.10m", "inside"]),
        ("time to its report, in minutes: 5, 12 and 30",
          @["15m, inside", "15, inside", "1.5h", "900s"], @["$15", "inside"]),
        ("Count: findings that the report ranks: 3, 6 and 11", @["12, above the 95th", "1.2k"],
          @["$12", "12m"]),
      ]
    var count = 0
    for k, (claim, held, refused) in forms:
      for state in ["✅", "⬜", "➖", "⏸️"]:
        for cell in held & refused:
          for table in ["| State | Confidence | Predicted | Result |\n| --- | --- | --- | --- |\n" &
              "| " & state & " | 90% | ", "| # | State | Estimate @ 90% | Result |\n" &
              "| --- | --- | --- | --- |\n| " & $(k + 1) & " | " & state & " | "]:
            let found = heldReflection(numbers, "## Reflection\n\n" & table & claim & " | " & cell &
              " |\n")
            if cell in refused and state in ["✅", "⬜"]:
              check found == @[rule & cell & "` for claim `" & $(k + 1) & "`"]
              inc count
            else: check found.len == 0
    check count == 2 * 2 * (4 + 2 + 2 + 2)  # two states and two tables of each refused cell

    # Number whose text names no unit, as `Cost: $0.40, …`, takes value of any mark, as it takes no
    #   score (GUIDE.md before tables: label names no unit but `Count:`).
    let unnamed = "## Prediction\n\n**Subagent:** builder of the fix, fresh context.\n\n- Cost: " &
      "$0.40, $0.90 and $2.00, as the 5th, 50th and 95th percentiles.\n"
    for cell in ["$1.10, inside", "1.10, inside", "15m, inside", "1.1k"]:
      check heldReflection(unnamed, "## Reflection\n\n| State | Confidence | Predicted | Result " &
        "|\n| --- | --- | --- | --- |\n| ✅ | 90% | $0.40, $0.90 and $2.00 | " & cell & " |\n")
        .len == 0


  test "result of number of bullets that opens with no value is refused, as log reads none (#1028)":
    # Case as found (finding 1 of critic of mends): each cell below logged no outcome with no
    #   finding, as check read only cell that opens with value. Domain: each state of each case,
    #   and each result of scored number of log of root curator (`RESULTS_LOGGED`), through hook
    #   and through reader of log; hook refuses each result whose value log reads as none.
    const found = [(0, "s08, 170,000, inside"), (1, "m01: $1.10, inside"), (0, "✅ 170,000"),
      (1, "✅ $1.10, in $0.40–$2.00"), (2, "r1: 15"), (0, "~170k, inside"), (1, "about $1.10")]
    for (k, cell) in found:
      check cell.outcomeResult(CLAIMS_BULLETS[k].unitText, as_bare = true).isNone
      for state in ["✅", "⬜", "➖", "⏸️"]:
        let held = heldReflection(NUMBERS_BULLETS, "## Reflection\n\n| State | Confidence | " &
          "Predicted | Result |\n| --- | --- | --- | --- |\n| " & state & " | 90% | " &
          CLAIMS_BULLETS[k] & " | " & cell & " |\n")
        check held == (if state in ["✅", "⬜"]:
          @[REFUSAL_OUTCOME_BULLETS & cell & "` for claim `" & $(k + 1) & "`"] else: @[])

    # Of results logged, these read value row holds, these read other value, as cell of four
    #   places of cost whose row of #963 logged cents, and hook refuses these, as label, marker
    #   or word before value, or no value, as `r01: $0.16`, `✅ $0.35` or `⬜`.
    const
      read_same = 148  ## Results that read value row logged.
      read_other = 17  ## Results that read value of four places, where row logged cents.
      refused_logged = 186  ## Results that hook refuses, as they read no value.
    var same, other, refused = 0
    for (text, cell, logged) in RESULTS_LOGGED:
      let
        prediction = "## Prediction\n\n**Subagent:** builder of the fix, fresh context.\n\n- " &
          text & ", as the 5th, 50th and 95th percentiles.\n"
        held = heldReflection(prediction, "## Reflection\n\n| State | Confidence | Predicted " &
          "| Result |\n| --- | --- | --- | --- |\n| ✅ | 90% | " & text & " | " & cell & " |\n")
        outcome = cell.outcomeResult(text.unitText, as_bare = true)
      check held == (if outcome.isNone: @[REFUSAL_OUTCOME_BULLETS & cell & "` for claim `1`"]
        else: @[])
      if outcome.isNone: inc refused
      elif outcome.get == logged: inc same
      else:
        check abs(outcome.get - logged) < 0.005  # four places, where row logged cents
        inc other
    check (same, other, refused) == (read_same, read_other, refused_logged)
    check RESULTS_LOGGED.len == read_same + read_other + refused_logged


  test "value reads scale and groups after one space, and result refuses what space leaves (#1028)":
    # Case as found: `39.1 M, inside`, `39.1 million, inside` and `39 100 000, inside` took 39.1 or
    #   39, since space ended value. Choice: each reads whole, since result that hook refuses keeps
    #   row of its first write with no outcome. Domain: each form of digits, each scale after one
    #   space in each case, groups after spaces, and digit, letter or word of time after space.
    for cell in ["39.1 M, inside", "39.1 million, inside", "39 100 000, inside"]:
      check cell.valueAt.get.amount == 39_100_000.0  # case as found
      check cell.valueAt.get.stop == cell.find(',')
    const
      digits = [("5", 5.0), ("0.5", 0.5), ("12.25", 12.25), ("1,500", 1500.0), ("1 500", 1500.0)]
      scales = [("k", 1e3), ("M", 1e6), ("thousand", 1e3), ("Thousand", 1e3), ("million", 1e6),
        ("MILLION", 1e6), ("billion", 1e9)]
    for (written, amount) in digits:
      check written.valueAt.get.amount == amount and written.valueAt.get.stop == written.len
      for (scale, factor) in scales:
        let cell = written & " " & scale
        check cell.valueAt.get.amount.isNear(amount * factor)
        check (cell & ", inside").valueAt.get.stop == cell.len
        check ("$" & cell).valueAt.get.unit == UnitNumber.Cost
        check (cell & "s").valueAt.get.stop == written.len  # word runs on, so no scale
        check (cell & "0").valueAt.isNone  # digit runs on
    check "1 00".valueAt.get.stop == 1  # group holds three digits
    check "1 0000".valueAt.get.stop == 1
    check "1,000 000".valueAt.get.stop == 5  # one mark of group to value; result refuses rest
    check "1 000,000".valueAt.isNone  # comma before digit runs on (#1028)
    check "1  000".valueAt.get.stop == 1  # one space alone
    check "5 m".valueAt.get.stop == 1 and "5 K".valueAt.get.stop == 1  # no scale of these

    # Result of estimate or of bullet refuses digit, letter or word of time after space, which
    #   value cannot read; each state but hit and miss passes.
    let whole = REFLECTION_TABLES_POSTED.mended
    const
      outcome = "cell under `Result` of estimate marked ✅ or ⬜ opens with its value in unit of " &
        "its cells: `$` for cost, `s`, `m` or `h` for time, bare number for tokens or count " &
        "(GUIDE.md, Prediction, critic and reflection); got `"
      forms = [
        ("| 6 |", "39.1M, inside", @["39.1 M, inside", "39.1 million, inside",
          "39 100 000, inside", "39 100 k", "0.0391 billion"],
          @["39 1, inside", "39.1 K, inside", "39.1 B", "39.1 h", "39 100 000 0"]),
        ("| 7 |", "$14.40, inside", @["$14.40 at list price", "$0.0144 k"], @["$14.40 m", "$14 4"]),
        ("| 8 |", "47m, inside", @["47m, inside"],
          @["47 m, inside", "0.8 h", "2820 s", "47 minutes", "1 Hour"]),
      ]
    var count = 0
    for (row, written, held, refused) in forms:
      let line = whole.splitLines.filterIt(it.startsWith(row))[0]
      for state in ["✅", "⬜", "➖", "⏸️"]:
        for cell in held & refused:
          let
            changed = line.replace("| ✅ |", "| " & state & " |").replace(written, cell)
            found = heldReflection(PREDICTION_TABLES, whole.replace(line, changed))
          if cell in refused and state in ["✅", "⬜"]:
            check found == @[outcome & cell & "` for claim `" & row[2 .. ^3] & "`"]
            inc count
          else: check found.len == 0
    check count == 2 * (5 + 2 + 5)
    const
      numbers = "## Prediction\n\n**Subagent:** builder of the fix, fresh context.\n\n" &
        "- Work: tokens summed over its requests: 100,000, 160,000 and 300,000, as the 5th, " &
        "50th and 95th percentiles.\n- Time: time to its report, in minutes: 5, 12 and 30, as " &
        "the 5th, 50th and 95th percentiles.\n"
      bullets = REFUSAL_OUTCOME_BULLETS
    for (k, claim, held, refused) in [
        (1, "tokens summed over its requests: 100,000, 160,000 and 300,000",
          @["170 k, inside", "170 000, inside"], @["170 K", "170 0, inside"]),
        (2, "time to its report, in minutes: 5, 12 and 30", @["15, inside"],
          @["1.5 h, inside", "15 min", "900 s"])]:
      for cell in held & refused:
        let found = heldReflection(numbers, "## Reflection\n\n| State | Confidence | Predicted | " &
          "Result |\n| --- | --- | --- | --- |\n| ✅ | 90% | " & claim & " | " & cell & " |\n")
        check found == (if cell in refused: @[bullets & cell & "` for claim `" & $k & "`"]
          else: @[])


  test "result refuses scale of bare cost or time, two marks of group, and other space (#1028)":
    # Case as found (finding 2 of critic of mends): bullet of time took `15 M, inside` as
    #   15,000,000 minutes, result `39 100,000, inside` took 39,100, and `39.1 M` with no-break
    #   space took 39.1, each with no finding. Domain: each scale on bare value of each unit of
    #   bullets, each order of two marks of group, comma before digit, and each space of Unicode
    #   before group, scale or mark of time; cell reads each run of ASCII whitespace as one space.
    proc bullet(k: int, cell: string): seq[string] =
      ## Read findings of reflection whose one row quotes number `k` of `NUMBERS_BULLETS`.
      heldReflection(NUMBERS_BULLETS, "## Reflection\n\n| State | Confidence | Predicted | " &
        "Result |\n| --- | --- | --- | --- |\n| ✅ | 90% | " & CLAIMS_BULLETS[k] & " | " & cell &
        " |\n")
    func refusal(k: int, cell: string): seq[string] =
      ## Write finding of result of number `k` of `NUMBERS_BULLETS` that reads no value.
      @[REFUSAL_OUTCOME_BULLETS & cell & "` for claim `" & $(k + 1) & "`"]
    check bullet(2, "15 M, inside") == refusal(2, "15 M, inside")  # case as found

    # Bare value takes unit of cost or time of its text with no scale alone, as `M` of million
    #   and `m` of minutes differ by case alone; tokens and count read each scale.
    var count = 0
    for scale in ["k", " k", "M", " M", " thousand", " million"]:
      for k in 0 .. 3:
        let cell = "15" & scale & ", inside"
        if k in [1, 2]:
          check bullet(k, cell) == refusal(k, cell)
          inc count
        else: check bullet(k, cell).len == 0
      check bullet(1, "$15" & scale).len == 0  # mark of cost reads its scale
    check count == 6 * 2

    # Value with two marks of group, or comma before digit that opens no group, reads none.
    let
      whole = REFLECTION_TABLES_POSTED.mended
      line = whole.splitLines.filterIt(it.startsWith("| 6 |"))[0]
    proc estimate(cell: string): seq[string] =
      ## Read findings of mended reflection whose result of estimate 6, of tokens, is cell.
      heldReflection(PREDICTION_TABLES, whole.replace(line, line.replace("39.1M, inside", cell)))
    for cell in ["39 100,000, inside", "39,100 000, inside", "39 100 000,000", "39,100,000 000",
        "39,1M, inside", "1,5"]:
      check estimate(cell) == @[REFUSAL_OUTCOME & cell & "` for claim `6`"]
      check bullet(0, cell) == refusal(0, cell)
    for text in ["39 100,000", "1 000,000", "1,23", "1,5h", "$1,10", "12,5k"]:
      check text.valueAt.isNone
    check bullet(1, "$1,10, inside") == refusal(1, "$1,10, inside")
    check bullet(2, "1,5h, inside") == refusal(2, "1,5h, inside")
    check bullet(0, "170,000, inside").len == 0 and estimate("39,100,000, inside").len == 0

    # Each space of Unicode before group, scale or mark of time runs on: no-break, figure,
    #   narrow no-break and thin space, as value reads group and scale after ASCII space alone.
    count = 0
    for space in ["\u00A0", "\u2007", "\u202F", "\u2009"]:
      for (written, after) in [("39.1", "M"), ("39.1", "k"), ("39.1", "million"),
          ("39", "100 000"), ("0.0391", "Billion")]:
        let cell = written & space & after & ", inside"
        check estimate(cell) == @[REFUSAL_OUTCOME & cell & "` for claim `6`"]
        check bullet(0, cell) == refusal(0, cell)
        inc count
      check bullet(2, "1.5" & space & "h") == refusal(2, "1.5" & space & "h")
      check bullet(2, "15" & space & "inside").len == 0  # word after space ends value
    check count == 4 * 5
    check estimate("39.1 M, inside").len == 0  # one ASCII space reads scale


  test "value reads none where mark but space joins its digits, or point opens count (#1028)":
    # Case as found (finding 1 of third critic): cell of tokens logged 1.234 for `1.234.567,
    #   inside`, and 170 for `170_000, inside` and `170'000, inside`; bullets logged 1.234 for
    #   `1.234.567`, 170 for `170.000`, and 15 for `15:30, inside` of time; line gave 170 tokens
    #   for `170.000 tokens`, and `39.1` with zero-width space before `M` gave 39.1. Domain: each
    #   ASCII mark but `|`, and marks of group of Unicode, glued between digits, in cell, bullets
    #   and line; each rune of no width before group, scale or mark of time; point in each unit.
    proc bullet(k: int, cell: string): seq[string] =
      ## Read findings of reflection whose one row quotes number `k` of `NUMBERS_BULLETS`.
      heldReflection(NUMBERS_BULLETS, "## Reflection\n\n| State | Confidence | Predicted | " &
        "Result |\n| --- | --- | --- | --- |\n| ✅ | 90% | " & CLAIMS_BULLETS[k] & " | " & cell &
        " |\n")
    func refusal(k: int, cell: string): seq[string] =
      ## Write finding of result of number `k` of `NUMBERS_BULLETS` that reads no value.
      @[REFUSAL_OUTCOME_BULLETS & cell & "` for claim `" & $(k + 1) & "`"]
    let
      whole = REFLECTION_TABLES_POSTED.mended
      row = whole.splitLines.filterIt(it.startsWith("| 6 |"))[0]
    proc estimate(cell: string): seq[string] =
      ## Read findings of mended reflection whose result of estimate 6, of tokens, is cell.
      heldReflection(PREDICTION_TABLES, whole.replace(row, row.replace("39.1M, inside", cell)))
    proc lined(written: string): seq[string] =
      ## Read findings of mended reflection whose line gives figures written.
      heldReflection(PREDICTION_TABLES, whole.replace("39,100,000 tokens and $14.40", written))
    for cell in ["1.234.567, inside", "170_000, inside", "170'000, inside"]:
      check estimate(cell) == @[REFUSAL_OUTCOME & cell & "` for claim `6`"]  # case as found
    for (k, cell) in [(0, "1.234.567"), (0, "170.000"), (2, "15:30, inside"),
        (0, "39.1\u200BM, inside")]:
      check bullet(k, cell) == refusal(k, cell)  # case as found
    check "**Subagent:** builder, 170.000 tokens and $1.10".figuresLine(LABELS_SUBAGENT).tokens
      .isNone  # case as found
    check lined("170.000 tokens and $14.40").len == 1

    # Mark glued between value and digit makes none, as it groups digits or parts two values; comma
    #   before three digits reads as group, and point as decimal part, which count refuses.
    const marks = "!\"#$%&'()*+,-./:;<=>?@[\\]^_`{}~"
    var count = 0
    for mark in marks:
      let (thousands, part) = ("170" & mark & "000", "170" & mark & "5")
      if mark == ',':
        check thousands.valueAt.get.amount == 170_000.0 and part.valueAt.isNone
      elif mark == '.':
        check thousands.valueAt.get.amount == 170.0 and part.valueAt.get.amount == 170.5
      else:
        check thousands.valueAt.isNone and part.valueAt.isNone
        check estimate(thousands & ", inside") ==
          @[REFUSAL_OUTCOME & thousands & ", inside` for claim `6`"]
        for k in 0 .. 3: check bullet(k, thousands) == refusal(k, thousands)
        check lined(thousands & " tokens and $14.40").len == 1
        check lined("39,100,000 tokens and $" & thousands).len == 1
        inc count
    check count == marks.len - 2
    for mark in ["\u2019", "\u02BC", "\u00B7", "\u066C", "\u2032"]:  # marks of group of Unicode
      let thousands = "170" & mark & "000"
      check thousands.valueAt.isNone
      check estimate(thousands & ", inside") ==
        @[REFUSAL_OUTCOME & thousands & ", inside` for claim `6`"]
      check bullet(0, thousands) == refusal(0, thousands)
      check lined(thousands & " tokens and $14.40").len == 1

    # Rune of no width after value runs on as space does, so group, scale or mark of time after it
    #   reads none; mark that ends value after it reads value.
    count = 0
    for rune in ["\u00AD", "\u200B", "\u200C", "\u200D", "\u2060", "\uFEFF"]:
      for (written, after) in [("39.1", "M"), ("39.1", "k"), ("39", "100,000"), ("39", "5"),
          ("0.0391", "billion")]:
        let cell = written & rune & after & ", inside"
        check estimate(cell) == @[REFUSAL_OUTCOME & cell & "` for claim `6`"]
        check bullet(0, cell) == refusal(0, cell)
        inc count
      check bullet(2, "1.5" & rune & "h") == refusal(2, "1.5" & rune & "h")
      check lined("39.1" & rune & "M tokens and $14.40").len == 1
      check lined("39,100,000 tokens and $14.40" & rune & "k").len == 1
      check estimate("39,100,000" & rune & ", inside").len == 0
      check bullet(1, "$1.10" & rune & ", inside").len == 0
    check count == 6 * 5

    # Tokens and count read point only where scale moves it, as each is count; cost and time read
    #   it as decimal part, as `$1.10` and `1.5h`.
    for cell in ["170.000", "170.5", "39.1 bn", "1.0"]:
      check estimate(cell & ", inside") == @[REFUSAL_OUTCOME & cell & ", inside` for claim `6`"]
      for k in [0, 3]: check bullet(k, cell) == refusal(k, cell)
      check lined(cell & " tokens and $14.40").len == 1
    for cell in ["39.1M", "39100k", "0.0391 billion", "39,100,000"]:
      check estimate(cell & ", inside").len == 0
      check lined(cell & " tokens and $14.40").len == 0
    for (k, cell) in [(0, "0.17M"), (3, "1.2k"), (1, "1.10"), (1, "$1.10"), (2, "1.5"),
        (2, "1.5h")]:
      check bullet(k, cell).len == 0
    check lined("39,100,000 tokens and $14.405").len == 0


  test "line `**Subagent:**` gives tokens and cost as cell reads value, or is refused (#1028)":
    # Case as found (findings 2 and 3 of critic of mends): line gave 0 tokens with no finding for
    #   `**170,000** tokens`, `` `170,000` tokens `` and `39.1 K tokens`, and 2,170,000 for
    #   `builder of round 2 170 000 tokens`. Domain: each mark of emphasis or code around each
    #   figure, each scale that cell reads or refuses, group after space, each form of cost, and
    #   reflection with no such line, which takes no finding.
    const
      rule = "line `**Subagent:**` of reflection gives tokens right before ` tokens` and cost " &
        "at `$`, each one plain value after space, as cell holds it, and value of tokens holds " &
        "no group after space (GUIDE.md, Prediction, critic and reflection); got `"
      figures = "39,100,000 tokens and $14.40"
      opening = "**Subagent:** builder of the weekly release check, "
    let whole = REFLECTION_TABLES_POSTED.mended
    proc lined(written: string): seq[string] =
      ## Read findings of mended reflection whose line gives figures written.
      heldReflection(PREDICTION_TABLES, whole.replace(figures, written))
    func refusal(written: string): seq[string] =
      ## Write finding of line that gives figures written.
      @[rule & opening & written & " at list price, 120 calls, 47 min.`"]
    for written in ["**170,000** tokens and $14.40", "`170,000` tokens and $14.40",
        "39.1 K tokens and $14.40"]:
      check lined(written) == refusal(written)  # case as found
    check heldReflection(PREDICTION_TABLES, whole.replace(opening & "39,100,000 tokens",
      "**Subagent:** builder of round 2 170 000 tokens")) == @[rule & "**Subagent:** builder " &
      "of round 2 170 000 tokens and $14.40 at list price, 120 calls, 47 min.`"]
    check lined(figures).len == 0
    let flow = lineUser("Build it.", "human") & lineSaid(PREDICTION_TABLES) &
      lineUser("<task-notification>timer</task-notification>", "task-notification") &
      linesAgent("builder") & lineSaid("Started.") & lineHandback("builder", "abuilder") &
      linesAgent("critic") & lineSaid("The critic runs.") & lineHandback("critic")
    check rulesHeld(flow & lineSaid(whole.replace(figures, "39.1 K tokens and $14.40"))) ==
      @["koch.reflection-line"]  # check of its own, apart from table

    # Mark of emphasis or code around figure makes none, as cell reads value with none; so does
    #   any mark but space before figure, as `~`.
    var count = 0
    for mark in ["**", "*", "_", "__", "***", "`"]:
      for written in [mark & "39,100,000" & mark & " tokens and $14.40",
          "39,100,000 tokens and " & mark & "$14.40" & mark, mark & "39,100,000 tokens" & mark &
          " and $14.40"]:
        check lined(written) == refusal(written)
        inc count
    check count == 6 * 3

    # Each scale that cell reads gives tokens, and each that cell refuses gives none; space
    #   before group joins value to number before it, as `round 2 170 000`, so it gives none.
    for written in ["39.1M", "39100k", "39.1 M", "39.1 million", "0.0391 billion", "39,100 k",
        "39100000", "0.0391 Billion"]:
      check lined(written & " tokens and $14.40").len == 0
    for written in ["39.1 K", "39.1 Mio", "39.1m", "$39.1M", "39 100 000", "170 000",
        "2 170,000", "39.1\u00A0M", "0", "39,100,000.5", "~39.1M", "39.1M-"]:
      check lined(written & " tokens and $14.40") == refusal(written & " tokens and $14.40")
    for space in ["\u00A0", "\u202F", "\t"]:  # space but ASCII space opens no word `tokens`
      check lined("39,100,000" & space & "tokens and $14.40") ==
        refusal("39,100,000" & space & "tokens and $14.40")

    # Cost reads first `$` as cell reads value, with no group after space and nothing after it
    #   that value cannot read.
    for written in ["$14.40", "$0.0144k", "$0.0144 k", "$14.4"]:
      check lined("39,100,000 tokens and " & written).len == 0
    for written in ["$1,10", "$14 40", "14.40 dollars", "$0", "$14.40 m", "$ 14.40"]:
      check lined("39,100,000 tokens and " & written) ==
        refusal("39,100,000 tokens and " & written)

    # Reflection with no line `**Subagent:**` takes no finding of line, as GUIDE.md asks line of
    #   it and no rule of hook does.
    let bare = whole.replace(whole.splitLines[2] & "\n" & whole.splitLines[3], "")
    check opening notin bare
    check heldReflection(PREDICTION_TABLES, bare).len == 0


  test "line `**Subagent:**` that gives two figures of tokens or two costs is refused (#1028)":
    # Case as found (probe of line of critic of mends, rerun at head of mends): `builder at $3.00
    #   per 1M tokens, 170,000 tokens and $1.10` gave 1,000,000 tokens and $3.00, with no finding.
    #   Domain: one, two or no figure before ` tokens`, and one, two or no `$` that opens figure,
    #   on line of subagent; mark that opens no figure, as `$` in code, counts none.
    const
      rule = "line `**Subagent:**` of reflection gives tokens right before ` tokens` and cost " &
        "at `$`, each one plain value after space, as cell holds it, and value of tokens holds " &
        "no group after space (GUIDE.md, Prediction, critic and reflection); got `"
      figures = "39,100,000 tokens and $14.40"
      opening = "**Subagent:** builder of the weekly release check, "
    let whole = REFLECTION_TABLES_POSTED.mended
    proc lined(written: string): seq[string] =
      ## Read findings of mended reflection whose line gives figures written.
      heldReflection(PREDICTION_TABLES, whole.replace(figures, written))
    func refusal(written: string): seq[string] =
      ## Write finding of line that gives figures written.
      @[rule & opening & written & " at list price, 120 calls, 47 min.`"]
    const found = "at $3.00 per 1M tokens, 170,000 tokens and $1.10"
    check lined(found) == refusal(found)  # case as found
    for written in ["39,100,000 tokens, of them 12,000 tokens of output, and $14.40",
        "39,100,000 tokens and $14.40, $0.50 of it cached",
        "39,100,000 tokens and $14.40, as $3 per 1M tokens"]:
      check lined(written) == refusal(written)
    for written in ["39,100,000 tokens, of `$HOME`, and $14.40",
        "of tokens, 39,100,000 tokens and $14.40", "39,100,000 tokens and $14.40 (US$ at list)",
        "39,100,000 tokens (12,000 output tokens) and $14.40"]:
      check lined(written).len == 0  # one figure of each; other mark opens none
    check lined("of tokens and $14.40") == refusal("of tokens and $14.40")

    # Log writes neither figure of such line, as hook refuses it.
    let read = whole.replace(figures, found).figuresLine(LABELS_SUBAGENT)
    check read.tokens.isNone and read.cost.isNone
    check whole.replace(figures, "of tokens, 39,100,000 tokens and $14.40")
      .figuresLine(LABELS_SUBAGENT).tokens == some(39_100_000)


  test "line `**Subagent:**` runs on to blank line or label in bold, so wrap gives figures (#1028)":
    # Case as found (finding 5 of third critic): sample line of GUIDE.md wrapped before `$1.10`
    #   took refusal, as `figuresLine` read first line alone. Domain: sample line wrapped at each
    #   space, and at each space at once; line that ends at blank line, or at each form of label
    #   in bold, as line of critic; line that runs on past bold that is no label, not into bullet.
    const
      guide = staticRead("../../../../GUIDE.md")
      spaces = 17  ## Places where sample line wraps, one at each space.
    let
      start = guide.find("```md\n" & HEADING_PREDICTION & "\n")
      prediction = guide[start + "```md\n".len ..< guide.find("\n```", start)] & "\n"
      opening = guide.find("```md\n" & HEADING_REFLECTION & "\n")
      reflection = guide[opening + "```md\n".len ..< guide.find("\n```", opening)] & "\n"
      at = reflection.find("**Subagent:**")
      paragraph = reflection[at ..< reflection.find("\n\n", at)]
      flat = paragraph.splitLines.mapIt(it.strip).join(" ")
    proc held(line: string): seq[string] =
      ## Read findings of samples of GUIDE.md whose line of reflection is line.
      blocksHeld(lineUser("Review the diff.", "human") & lineSaid(prediction) &
        lineUser("<task-notification>timer</task-notification>", "task-notification") &
        linesAgent("reviewer") & lineSaid("Started.") & lineHandback("reviewer", "areviewer") &
        lineSaid(reflection.replace(paragraph, line)))
    func figures(text: string): (Option[int], Option[float]) =
      ## Read tokens and cost of line `**Subagent:**` of text.
      let read = text.figuresLine(LABELS_SUBAGENT)
      (read.tokens, read.cost)
    check held(flat.replace(" $1.10", "\n$1.10")).len == 0  # case as found
    var count = 0
    for i, c in flat:
      if c != ' ': continue
      let wrapped = flat[0 ..< i] & "\n" & flat[i + 1 .. ^1]
      check held(wrapped).len == 0
      check wrapped.figures == (some(170_000), some(1.1))
      check wrapped.figuresLine(LABELS_SUBAGENT).line == flat
      inc count
    check count == spaces
    check held(flat.replace(" ", "\n  ")).len == 0  # each word on line of its own, indented

    # Blank line ends line, so figure after it gives none; label in bold of each form ends it, so
    #   line of critic after it adds no figure, as bullet does; bold that is no label runs on.
    let line = "**Subagent:** reviewer, 170,000 tokens and $1.10,"
    check (line & "\n\n57 calls.").figures == (some(170_000), some(1.1))
    check "**Subagent:** reviewer,\n\n170,000 tokens and $1.10.".figures ==
      (none(int), none(float))
    for label in ["**Critic:**", "**Critic**:", "**critic:**", "**Judgements.**",
        "**Not predicted:**", "  **Critic:**"]:
      check (line & "\n" & label & " 50,000 tokens and $0.35.").figures ==
        (some(170_000), some(1.1))
    for text in ["**Subagent:** reviewer,\n**fresh** context, 170,000 tokens and $1.10.",
        "**Subagent:** reviewer,\n**Critic** 170,000 tokens and $1.10."]:
      check text.figures == (some(170_000), some(1.1))  # bold that is no label runs on
    check (line & "\n50,000 tokens of the critic.").figures == (none(int), some(1.1))
    check (line & "\n- **Not predicted:** a fee of $2.").figures == (some(170_000), some(1.1))
    check held(flat.replace(" $1.10", "\n$1.10 and $2")) == @["line `**Subagent:**` of " &
      "reflection gives tokens right before ` tokens` and cost at `$`, each one plain value " &
      "after space, as cell holds it, and value of tokens holds no group after space (GUIDE.md, " &
      "Prediction, critic and reflection); got `" & flat.replace(" $1.10", " $1.10 and $2") & "`"]


  test "line `**Subagent:**` ends at bullet, table, quote or heading under it (#1028)":
    # Case as found (probe of fourth builder, after line ran on): line of no tokens with bullet
    #   right under it that gives `39,000 tokens` gave 39,000 tokens with no finding. Domain: each
    #   opening of other block under line that gives no figure, and under line that gives both;
    #   text that opens no block, which runs on; and hook and log at case as found.
    const
      opening = "**Subagent:** builder of the fix, "
      found = opening & "$1.10 at list price.\n- **Not predicted:** the 39,000 tokens of the " &
        "critic."
      blocks = ["- ", "* ", "+ ", "1. ", "2) ", "  - ", "| 5 | ", "> ", "# ", "## ", "###### "]
    func figures(text: string): (Option[int], Option[float]) =
      ## Read tokens and cost of line `**Subagent:**` of text.
      let read = text.figuresLine(LABELS_SUBAGENT)
      (read.tokens, read.cost)
    check found.figures == (none(int), some(1.1))  # case as found
    let whole = REFLECTION_TABLES_POSTED.mended
    check heldReflection(PREDICTION_TABLES, whole.replace("39,100,000 tokens and $14.40 at list " &
      "price,\n120 calls, 47 min.", "$14.40 at list price.\n- **Not predicted:** the 39,000 " &
      "tokens of the critic.")).len == 1  # line gives no tokens

    # Each opening of block ends line, so its figure adds none; text that opens none runs on.
    var count = 0
    for start in blocks:
      check (opening & "57 calls.\n" & start & "170,000 tokens and $1.10.").figures ==
        (none(int), none(float))
      check (opening & "39,000 tokens and $0.35.\n" & start & "170,000 tokens and $1.10.")
        .figures == (some(39_000), some(0.35))
      inc count
    check count == blocks.len
    for text in ["#962 holds", "####### seven", "-x", "1.5 hours"]:
      check (opening & "57 calls,\n" & text & " 170,000 tokens and $1.10.").figures ==
        (some(170_000), some(1.1))


  test "line `**Subagent:**` ends at full stop, label of each form, break or HTML (#1028)":
    # Case as found (fourth critic, R2, R3, S2 to S5 and K2): line that gives no tokens ran on
    #   into line under it that gives `39,000 tokens`, as `__Critic:__ …`, break and sentence,
    #   comment of HTML or plain sentence, and logged that figure with no finding; line
    #   `**Critic:**` ran on too. Domain: line that ends with full stop above each such line; line
    #   with no full stop above each form of label, each break and each HTML block; line of
    #   critic; right read of plain label under full line; and wrap, which still runs on.
    const
      ended = "**Subagent:** builder of the fix, $1.10 at list price, 57 calls."
      open = "**Subagent:** builder of the fix, $1.10 at list price, 57 calls,"
      unders = ["__Critic:__ critic of the report, 39,000 tokens, 12 calls.",
        "***Critic:*** critic of the report, 39,000 tokens.", "Critic: critic, 39,000 tokens.",
        "The critic used 39,000 tokens.", "<!-- critic: 39,000 tokens -->"]
      breaks = ["***", "___", "---", "- - -", "<!-- critic -->", "<details>"]
    func figures(text: string, labels = LABELS_SUBAGENT): (Option[int], Option[float]) =
      ## Read tokens and cost of line of labels of text.
      let read = text.figuresLine(labels)
      (read.tokens, read.cost)
    check (ended & "\n" & unders[0]).figures == (none(int), some(1.1))  # case as found
    var count = 0
    for under in unders:
      check (ended & "\n" & under).figures == (none(int), some(1.1))
      inc count
    for under in unders[0 .. 2]:
      check (open & "\n" & under).figures == (none(int), some(1.1))  # label of each form
      inc count
    for mark in breaks:
      check (open & "\n" & mark & "\nThe critic used 39,000 tokens.").figures ==
        (none(int), some(1.1))
      inc count
    check count == unders.len + 3 + breaks.len
    check ("**Critic:** critic of the report, $0.50 at list price, 12 calls, 4 min.\nIt read " &
      "the 170,000 tokens of the report.").figures(LABELS_CRITIC) == (none(int), some(0.5))
    check ("**Subagent:** reviewer, 170,000 tokens and $1.10 at list price, 57 calls, 15 min." &
      "\nCritic: critic of the report, 39,000 tokens and $0.50, 12 calls.").figures ==
      (some(170_000), some(1.1))  # right read stays
    check "**Subagent:** builder of the fix,\n170,000 tokens and $1.10.".figures ==
      (some(170_000), some(1.1))  # wrap runs on


  test "each refusal of bullets cites section that states its rule (#1028)":
    # Case as found: `RULE_CELL` of `hooks.nim` cited GUIDE.md, Prediction, critic and reflection,
    #   whose rules name tables alone since #1028, so refusal of bullets cited rule that is gone.
    #   Domain: refusal of cell, of empty cell, and of reflection with no table, for bullets.
    const
      guide = staticRead("../../../../GUIDE.md")
      record = staticRead("../../PROVENANCE.md")
      heading = "### Prediction, critic and reflection"
      cited = "(curator/audit/PROVENANCE.md, Quotes of claims)"
    func textSection(text, heading: string): string =
      ## Read `##` section of heading of text, fenced lines blank, each run of whitespace as one.
      text.sections.filterIt(it.heading == heading)[0].text.fencedOut.collapsed
    let
      work = guide.textSection("## Work for subagents")
      start = work.find(heading)
      rules = work[start ..< work.find("### ", start + heading.len)]
      quotes = record.textSection("## Quotes of claims")
    check start >= 0
    check rules.count("`" & COLUMN_PREDICTED & "`") == 1  # guide states tables alone (#1028)
    check "The hook also reads the first table of a reflection whose header holds `" &
      COLUMN_PREDICTED & "` as one, for a block of bullets." in rules  # as table of claims alone
    check "A cell under `Predicted` is one whole claim of a block that a call took, or " &
      "`No prediction`." in quotes  # record states rule of cell
    check "**A claim of bullets is a bullet" in quotes  # and where claim of bullets ends

    # Each refusal that rules of bullets alone state cites record, and never guide.
    const bullet = "- Judgement: the race leads the findings (70%)."
    let refusals = quoted(bullet, "the race") & quoted(bullet, "") &
      heldReflection(PREDICTION, "## Reflection\n\nNone.\n")
    check refusals == @[refusalCell("the race"), refusalEmpty(1), REFUSAL_NO_TABLE]
    check refusals.allIt(cited in it)
    check refusals[0 .. 1].allIt("GUIDE.md" notin it)  # cell is rule of bullets alone


  test "samples of GUIDE.md hold shape that block checks read (#962)":
    # Delegate copies form from samples, so sample reflection quotes sample prediction, which
    #   call takes, as section reads as committed; reviewer takes no critic (`D3 a` of #1024).
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
      lineSaid(sample(HEADING_REFLECTION))
    check transcript.parseTurn.subagents.predictions.len == 1
    check blocksHeld(transcript).len == 0

    # Samples take tables of claims of `D1 a` of #1028 (comment 7218520265): each claim stands in
    #   row of its number, with its criterion, and each row of reflection names claim by number.
    let read = sample(HEADING_PREDICTION).forecasts
    check read.len == 6 and read.allIt(it.is_row)
    check read.mapIt(it.position) == toSeq(1..6)
    check sample(HEADING_PREDICTION).findingsPrediction.len == 0
    check blocksHeld(lineUser("Review the diff.", "human") &
      lineSaid(sample(HEADING_PREDICTION))).len == 0  # stop of turn of block
    check read.filterIt(it.estimate.isSome).mapIt(it.estimate.get.unit) ==
      @[UnitNumber.Tokens, UnitNumber.Cost, UnitNumber.Time]
    let rows = sample(HEADING_REFLECTION).rowsReflection
    check rows.len == 6 and rows.allIt(it.is_numbered)
    check rows.mapIt(it.number.get) == toSeq(1..6)
