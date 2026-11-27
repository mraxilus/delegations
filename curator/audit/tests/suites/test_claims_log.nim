## Replicate log of claims: rows of reflection read from transcript, line of each, its key, its
##   path and project by branch, and file `stop` writes, reads back and moves.
##   Text format of each line is read back through `protoc` against `claims.proto`, field by
##     field: `--encode` refuses misspelt field, which `buf convert` drops with no error, as
##     Architect ruled on #989 (comment 7053329096).
##   Cost: round trip runs `protoc`, which `tools/build.nim` declares, so machine lacking it fails.

{.experimental: "strictFuncs".}

import std/[json, options, os, osproc, sequtils, sets, streams, strformat, strutils, tables,
  tempfiles]
import std/unittest
import ../../src/[claims_log, hooks]
import ./fixtures


const
  KINDS = ["critic", "resolver", "reviewer"]  ## Kinds templates of scratch root name.
  DELEGATE = "s1"  ## `sessionId` of each entry of reflection.
  UUID = "u9"  ## `uuid` of entry of reflection.
  STAMP = "2026-11-20T11:57:03.512Z"  ## `timestamp` of entry of reflection.
  MODEL = "model-a"  ## Model result of each call names, unless test names other.
  PROJECT = "contributor/bangu/rictadni"  ## Project rows of `BRANCH` belong to.
  BRANCH = "contributor/bangu/rictadni/outside-names"  ## Branch whose log suite writes.
  PREDICTION_REVIEWER = """## Prediction

**Subagent:** reviewer of the diff, fresh context.

- Judgement: the race leads the findings (70%). Resolution criterion: it is the first finding.
- Work: tokens summed over its requests: 100,000, 160,000 and 300,000, as the 10th, 50th and
  90th percentiles. Resolution criterion: the sum of the usage of its requests.
"""
    ## Block of reviewer: one claim with label, and one number.
  PREDICTION_CRITIC = """## Prediction

**Subagent:** critic of the report, fresh context.

- it fails one claim of the report (65%). Resolution criterion: the report of the critic.
"""
    ## Optional block of critic, with no label.
  REFLECTION = """## Reflection

**Subagent:** reviewer of the diff, 170,000 tokens and $1.10 at list price, 57 calls, 15 min.
**Critic:** 50,000 tokens and $0.35 at list price, 20 calls, 6 min.

| State | Confidence | Predicted | Result |
| --- | --- | --- | --- |
| ✅ | 70% | the race leads the findings | it leads, as "high" \| first |
| ⬜ | 80% | tokens summed over its requests: 100,000, 160,000 and 300,000 | 320,000, above |
| ⬜ | 60% | No prediction | the resolver took none |
| ⬜ | 60% | a claim of no block | none |
| ⏸️ | 65% | it fails one claim of the report | waits on the resolver |
"""
    ## Reflection whose rows are claim of reviewer, number, missed prediction, cell quoting no
    ##   claim, and claim of critic.
  REFLECTION_RACE = """## Reflection

**Subagent:** reviewer of the diff, 90,000 tokens and $0.60 at list price, 30 calls, 8 min.

| State | Confidence | Predicted | Result |
| --- | --- | --- | --- |
| ✅ | 70% | the race leads the findings | it leads |
"""
    ## Reflection on reviewer whose one row quotes claim that several blocks hold.


func lineUser(text, kind: string): string =
  ## Write transcript line of user entry holding text, from origin of kind.
  $(%*{"type": "user", "origin": {"kind": kind}, "message": {"content": text}}) & "\n"


func lineSaid(text: string, uuid = ""): string =
  ## Write transcript line of assistant entry holding text that ends model turn, as entry of
  ##   delegate `DELEGATE` at `STAMP`, with uuid.
  $(%*{"type": "assistant", "uuid": uuid, "timestamp": STAMP, "sessionId": DELEGATE, "message": {
    "content": [{"type": "text", "text": text}], "stop_reason": "end_turn",
  }}) & "\n"


func inputAgent(kind, effort, model: string): JsonNode =
  ## Write input of `Agent` call of kind, with effort and model where each is given.
  result = %*{"subagent_type": kind, "description": "Do the work", "prompt": "Do it."}
  if effort.len > 0: result["effort"] = %effort
  if model.len > 0: result["model"] = %model


func lineResult(id: string, resolved: string): string =
  ## Write transcript line of launch notice of call of id, whose result names model resolved, or
  ##   none where it is empty.
  var result_tool = %*{"status": "async_launched", "agentId": "a" & id}
  if resolved.len > 0: result_tool["resolvedModel"] = %resolved
  $(%*{"type": "user", "message": {"content": [{
    "type": "tool_result", "tool_use_id": id, "content": "Async agent launched.",
  }]}, "toolUseResult": result_tool}) & "\n"


func linesAgent(kind: string; effort = ""; id = ""; model = ""; resolved = MODEL): string =
  ## Write transcript lines of `Agent` call of kind, with input effort and model where given, and
  ##   its launch notice; id is `toolu_<kind>` where none is given.
  let
    named = (if id.len > 0: id else: "toolu_" & kind)
    call = %*{"type": "assistant", "message": {"content": [{
      "type": "tool_use", "id": named, "name": "Agent", "input": inputAgent(kind, effort, model),
    }], "stop_reason": "tool_use"}}
  $call & "\n" & lineResult(named, resolved)


func linesCalling(text, kind, effort, id: string): string =
  ## Write transcript lines of one assistant entry holding text, then `Agent` call of kind in same
  ##   message, its launch notice, and text that ends model turn.
  let entry = %*{"type": "assistant", "uuid": UUID, "timestamp": STAMP, "sessionId": DELEGATE,
    "message": {"content": [
      {"type": "text", "text": text},
      {"type": "tool_use", "id": id, "name": "Agent", "input": inputAgent(kind, effort, "")},
    ], "stop_reason": "tool_use"}}
  $entry & "\n" & lineResult(id, MODEL) & lineSaid("Done.")


func lineHandback(name: string): string =
  ## Write transcript line of hand-back of subagent of kind name.
  $(%*{"type": "user", "isMeta": true, "origin": {
    "kind": "peer", "from": "a" & name, "name": name, "handback": true,
  }, "message": {"content": "[Subagent hand-back] Report."}}) & "\n"


func linesPredicted(prediction, kind: string; effort = ""; id = ""; model = ""): string =
  ## Write transcript lines of block in turn of its own, timer, and call of kind it serves.
  lineSaid(prediction) & lineUser("timer", "task-notification") &
    linesAgent(kind, effort, id, model) & lineSaid("Started.") & lineHandback(kind)


func transcript(reflection = REFLECTION): string =
  ## Write transcript of reviewer and its critic, each with its block in turn of its own, then
  ##   reflection in last turn.
  lineUser("Review the diff.", "human") &
    linesPredicted(PREDICTION_REVIEWER, "reviewer", "medium") &
    linesPredicted(PREDICTION_CRITIC, "critic") & lineSaid(reflection, UUID)


proc claimsRead(text: string): seq[Claim] =
  ## Read claims of last turn of transcript, with effort `xhigh` for template of critic.
  text.parseTurn.subagents.claimsTurn(KINDS, {"critic": "xhigh"}.toTable, PROJECT)


proc rowKind(kind: string, n: int): string =
  ## Render row `n` of first claim of transcript under kind, one line of log, key unique to `n`.
  var each = transcript().claimsRead[0]
  each.kind = kind
  each.key = &"{each.key}/{n}"
  each.lineClaim & "\n"


proc repoBranch(branch: string): string =
  ## Make throwaway repository on branch, with identity commit of hook takes from config.
  result = repoTemp()
  for setting in ["user.name Test", "user.email test@example.invalid", "commit.gpgsign false"]:
    discard result.git("config " & setting)
  discard result.git("checkout -q -b " & branch)


proc subject(root: string): string =
  ## Read subject of last commit.
  root.git("log -1 --format=%s").strip


proc rootTemplates(): string =
  ## Make scratch root whose templates name each of `KINDS`, critic with effort `xhigh`.
  result = createTempDir("claims_", "_root")
  createDir(result / DIRECTORY_AGENTS)
  for kind in KINDS:
    let effort = (if kind == "critic": "effort: xhigh\n" else: "")
    writeFile(result / DIRECTORY_AGENTS / kind & ".md", "---\nname: " & kind & "\n" & effort &
      "---\n")


proc protoc(verb, input: string): tuple[output: string, code: int] =
  ## Run `protoc` with verb `--encode` or `--decode` of `claims.Log`, in folder of `claims.proto`,
  ##   on input; give its output whole and its exit code.
  ##   Output is read whole, never by line, since `--encode` writes bytes that reading by line
  ##     changes; input is small, so writing all of it first fills no pipe.
  let process = startProcess(
    "protoc",
    currentSourcePath().parentDir / "../../src",
    [verb & "=claims.Log", "claims.proto"],
    options = {poUsePath, poStdErrToStdOut},
  )
  process.inputStream.write(input)
  process.inputStream.close()
  result.output = process.outputStream.readAll
  result.code = process.waitForExit
  process.close


func fieldsMessage(schema, message: string): seq[string] =
  ## Read name of each field of message of schema text, in order of lines.
  var is_inside = false
  for line in schema.splitLines:
    let row = line.strip
    if row.startsWith("message " & message & " {"):
      is_inside = true
    elif is_inside and row.startsWith("}"):
      break
    elif is_inside and row.len > 0 and not row.startsWith("//"):
      let
        words = row.split({' ', '='}).filterIt(it.len > 0)
        at = (if words[0] in ["optional", "repeated"]: 2 else: 1)
      if words.len > at: result.add words[at]



suite "Log of claims":
  test "each number of text reads with its groups and decimal part, and nothing around it":
    check "100,000, 160,000 and 300,000".numbersIn == @[100_000.0, 160_000.0, 300_000.0]
    check "$0.06, $0.13 and $0.30".numbersIn == @[0.06, 0.13, 0.30]
    check "52 of 60, 2.4°, 1,23".numbersIn == @[52.0, 60.0, 2.4, 1.0, 23.0]
    check "1.75.0 and 9.".numbersIn == @[1.75, 9.0]  # digit after point opens no number
    check "none here".numbersIn.len == 0


  test "claim has position of its bullet, with or without label, and number ends at percentiles":
    let number = "tokens summed over its requests: 100,000, 160,000 and 300,000"
    check PREDICTION_REVIEWER.positionClaim("Judgement: the race leads the findings") == 1
    check PREDICTION_REVIEWER.positionClaim("the race leads the findings") == 1
    check PREDICTION_REVIEWER.positionClaim(number) == 2
    check PREDICTION_REVIEWER.positionClaim("the race leads") == 0
    check PREDICTION_REVIEWER.isNumber("Work: " & number)
    check PREDICTION_REVIEWER.isNumber(number)
    check not PREDICTION_REVIEWER.isNumber("the race leads the findings")
    check not PREDICTION_REVIEWER.isNumber("tokens summed over its requests")
    let ninety = PREDICTION_REVIEWER.replace("as the 10th, 50th and\n  90th",
      "as the 5th, 50th and\n  95th")
    check ninety != PREDICTION_REVIEWER
    check ninety.isNumber(number)  # 90% coverage, as GUIDE.md writes it (7191274618)


  test "each row quoting claim of block call took is claim, with its call, marks and figures":
    let claims = transcript().claimsRead
    check claims.mapIt(it.text) == @[
      "the race leads the findings",
      "tokens summed over its requests: 100,000, 160,000 and 300,000",
      "it fails one claim of the report",
    ]
    let first = claims[0]
    check first.date == "2026-11-20"
    check first.delegate == DELEGATE
    check first.project == PROJECT
    check (first.kind, first.call) == ("reviewer", "toolu_reviewer")
    check first.model == ""  # `D1 b` of #1025: row names no model
    check first.effort == "medium"  # input of call, ahead of template
    check first.confidence == 0.7
    check first.state == State.Hit
    check (first.tokens, first.cost) == (170_000, 1.1)
    check first.address == DELEGATE & "/" & UUID & "/1"
    check first.key == DELEGATE & "/toolu_reviewer/1/STATE_HIT"
    check first.result == "it leads, as \"high\" | first"
    check first.number.isNone


  test "number takes its percentiles from its text, and its outcome from its result":
    let number = transcript().claimsRead[1]
    check number.state == State.Miss
    check number.confidence == 0.8
    check number.key == DELEGATE & "/toolu_reviewer/2/STATE_MISS"
    check number.number.isSome
    let percentiles = number.number.get
    check (percentiles.low, percentiles.median, percentiles.high) == (1e5, 1.6e5, 3e5)
    check percentiles.outcome == some(320_000.0)
    let silent = transcript(REFLECTION.replace("320,000, above", "above")).claimsRead[1]
    check silent.number.get.outcome.isNone


  test "claim of block of critic takes call of critic, with its line and effort of template":
    let critic = transcript().claimsRead[2]
    check (critic.kind, critic.call) == ("critic", "toolu_critic")
    check critic.effort == "xhigh"
    check (critic.tokens, critic.cost) == (50_000, 0.35)
    check critic.state == State.Waiting
    check critic.address == DELEGATE & "/" & UUID & "/5"
    check critic.key == DELEGATE & "/toolu_critic/1/STATE_WAITING"


  test "critic that line `**Subagent:**` names reads that line, as replay of critic does":
    let
      reflection = "## Reflection\n\n**Subagent:** critic of replay C2, 12,709,459 tokens and " &
        "$5.57 at list price, 40 calls, 31 min.\n\n| State | Confidence | Predicted | Result " &
        "|\n| --- | --- | --- | --- |\n| ✅ | 65% | it fails one claim of the report | it does |\n"
      text = lineUser("Check the report.", "human") &
        linesPredicted(PREDICTION_CRITIC, "critic", "max") & lineSaid(reflection, UUID)
      claims = text.claimsRead
    check claims.len == 1
    check (claims[0].kind, claims[0].effort) == ("critic", "max")
    check (claims[0].tokens, claims[0].cost) == (12_709_459, 5.57)


  test "claim takes latest call before reflection, of kind that reflection names":
    # Two calls of reviewer, critic, and reviewer after reflection each hold one claim;
    #   reflection names reviewer, so second call of reviewer takes it.
    let
      critic = PREDICTION_CRITIC.replace("it fails one claim of the report",
        "the race leads the findings")
      text = lineUser("Review the diff.", "human") &
        linesPredicted(PREDICTION_REVIEWER, "reviewer", "low", "toolu_r1") &
        linesPredicted(PREDICTION_REVIEWER, "reviewer", "high", "toolu_r2") &
        linesPredicted(critic, "critic", "", "toolu_c1") & lineSaid(PREDICTION_REVIEWER) &
        lineUser("timer", "task-notification") &
        linesCalling(REFLECTION_RACE, "reviewer", "max", "toolu_r3")
      claims = text.claimsRead
    check claims.len == 1
    check (claims[0].call, claims[0].effort) == ("toolu_r2", "high")


  test "row names no model, whatever result or input of call names (`D1 b` of #1025)":
    let
      text = lineUser("Review the diff.", "human") &
        lineSaid(PREDICTION_REVIEWER) & lineUser("timer", "task-notification") &
        linesAgent("reviewer", "", "", "opus", "") & lineSaid("Started.") &
        lineHandback("reviewer") & lineSaid(REFLECTION_RACE, UUID)
      claims = text.claimsRead
    check claims.len == 1
    check claims[0].model == ""  # input names `opus`, and result names none
    check claims[0].effort == ""  # neither call nor template of reviewer names one
    check transcript().claimsRead.allIt(it.model == "")  # each result names `MODEL`


  test "missed prediction, cell quoting no claim, row with no marker, and earlier turn give none":
    let rows = transcript().claimsRead
    check rows.allIt(it.text notin ["No prediction", "a claim of no block"])
    check transcript(REFLECTION.replace("| ✅ | 70% |", "| yes | 70% |")).claimsRead.len == 2
    check (transcript() & lineSaid("Done.")).claimsRead.len == 0  # reflection is of earlier turn


  test "line writes each field in order of schema, escaped, and leaves out each default":
    let claim = transcript().claimsRead[0]
    check claim.lineClaim == "claims { date: \"2026-11-20\" delegate: \"s1\" project: " &
      "\"contributor/bangu/rictadni\" kind: \"reviewer\" call: \"toolu_reviewer\" " &
      "effort: \"medium\" text: \"the race leads the findings\" " &
      "confidence: 0.7 state: STATE_HIT marker: MARKER_DELEGATE tokens: 170000 cost: 1.1 " &
      "address: \"s1/u9/1\" key: \"s1/toolu_reviewer/1/STATE_HIT\" result: " &
      "\"it leads, as \\\"high\\\" | first\" }"
    check Claim(text: "a\\b\n\t\x01").lineClaim ==
        "claims { text: \"a\\\\b\\n\\t\\x01\" marker: MARKER_DELEGATE }"
    check Claim(text: "a", marker: Marker.Resolver).lineClaim ==
        "claims { text: \"a\" marker: MARKER_RESOLVER }"
    # `stop` writes no model (`D1 b` of #1025), and schema keeps field, so writer still writes it.
    check Claim(kind: "reviewer", model: "model-a", text: "a").lineClaim ==
        "claims { kind: \"reviewer\" model: \"model-a\" text: \"a\" marker: MARKER_DELEGATE }"


  test "protoc and reader read each line back, field by field, and protoc refuses misspelt field":
    # `D1 a` of #964 (comment 7189788889): suite holds reader to `protoc` on same rows.
    var claims = transcript().claimsRead
    claims.add Claim(text: "quote \" slash \\ tab \t mark ✅ 2.4°", state: State.Annulled,
      marker: Marker.Delegate)
    claims.add Claim(text: "a\\b\n\t\x01", state: State.Hit, marker: Marker.Delegate)
    claims.add Claim(text: "b", state: State.Miss, marker: Marker.Resolver)
    claims.add Claim(model: "model-a", text: "m", state: State.Hit, marker: Marker.Delegate)
    let
      lines = claims.mapIt(it.lineClaim)
      (encoded, code) = protoc("--encode", HEADER_LOG & lines.mapIt(it & "\n").join)
    check code == 0
    let (decoded, back) = protoc("--decode", encoded)
    check back == 0
    check decoded.count("claims {") == claims.len
    for field in [  # as `protoc` prints each field it read, by name, from first row and others
      "date: \"2026-11-20\"", "delegate: \"s1\"", "project: \"contributor/bangu/rictadni\"",
      "kind: \"reviewer\"", "call: \"toolu_reviewer\"",
      "effort: \"medium\"", "text: \"the race leads the findings\"", "confidence: 0.7",
      "state: STATE_HIT", "marker: MARKER_DELEGATE", "tokens: 170000", "cost: 1.1",
      "address: \"s1/u9/1\"", "key: \"s1/toolu_reviewer/1/STATE_HIT\"",
      "result: \"it leads, as \\\"high\\\" | first\"", "low: 100000", "median: 160000",
      "high: 300000", "outcome: 320000", "state: STATE_WAITING", "state: STATE_ANNULLED",
      "text: \"quote \\\" slash \\\\ tab \\t mark \\342\\234\\205 2.4\\302\\260\"",
      "text: \"a\\\\b\\n\\t\\001\"", "marker: MARKER_RESOLVER", "model: \"model-a\"",
    ]:
      check decoded.splitLines.anyIt(it.strip == field)
    check lines.mapIt(it.claimLine) == claims  # each field `protoc` printed, as claim holds it
    check protoc("--encode", "claims { dat: \"2026-11-20\" }\n").code != 0  # misspelt field


  test "reader reads each row of writer back into same claim, and each row of log in order":
    var claims = transcript().claimsRead
    claims.add Claim(text: "quote \" slash \\ tab \t mark ✅ 2.4°", state: State.Annulled,
      marker: Marker.Delegate)
    claims.add Claim(text: "a\\b\n\t\x01", state: State.Hit, marker: Marker.Resolver)
    claims.add Claim(text: "carriage \r return", state: State.Hit, marker: Marker.Delegate)
    claims.add Claim(text: "n", state: State.Miss, marker: Marker.Delegate,
      number: some(Number(low: 0.15, median: 0.45, high: 1.2)))
    check claims.anyIt(it.number.isSome and it.number.get.outcome.isSome)
    for claim in claims:
      check claim.lineClaim.claimLine == claim
    check claimsLog(HEADER_LOG & claims.mapIt(it.lineClaim & "\n").join & "\n") == claims


  test "claim that names no marker reads back as marked by delegate, as its line writes it":
    check Claim(text: "a").lineClaim.claimLine == Claim(text: "a", marker: Marker.Delegate)


  test "reader knows each field of schema, and no field that schema lacks":
    let schema = readFile(currentSourcePath().parentDir / "../../src/claims.proto")
    check schema.fieldsMessage("Claim") == @FIELDS_CLAIM
    check schema.fieldsMessage("Number") == @FIELDS_NUMBER


  test "reader refuses row that writer writes no way, and unknown field, value or block":
    expect ValueError: discard claimLine("rows { text: \"a\" }")
    expect ValueError: discard claimLine("claims { dat: \"2026-11-20\" }")
    expect ValueError: discard claimLine("claims { state: STATE_GOOD }")
    expect ValueError: discard claimLine("claims { text: \"open }")
    expect ValueError: discard claimLine("claims { result { low: 1 } }")
    expect ValueError: discard claimLine("claims { number { mean: 1 } }")
    expect ValueError: discard claimLine("claims { } text: \"a\" }")  # text after closing brace
    expect ValueError: discard claimLine("claims { number { number { low: 1 } } }")  # in block
    expect ValueError: discard claimLine("claims { text \"a\" }")  # no colon after name
    # Rows whose one fault is block in block, and name with no colon, so no other check refuses
    #   them: each reads as claim where its check is gone.
    expect ValueError: discard claimLine("claims { number { number { low: 1 } }")
    expect ValueError: discard claimLine("claims { confidence 0.7 }")
    expect ValueError: discard claimLine("claims { text: \"\\x\" }")  # escape cut short
    expect ValueError: discard claimLine("claims { text: \"\\x0\" }")


  test "tree joins rows of each log it holds, by order of path, and reads no other file":
    let
      root = createTempDir("claims_", "_tree")
      claims = transcript().claimsRead
      project = root / PROJECT / FILE_LOG
      curator = root / PATH_LOG_CURATOR
    check execCmdEx("git init -q", workingDir = root).exitCode == 0
    check root.claimsTree.len == 0  # no log yet
    createDir(project.parentDir)
    createDir(curator.parentDir)
    writeFile(curator, HEADER_LOG & claims[0].lineClaim & "\n")
    writeFile(project, HEADER_LOG & claims[1 .. ^1].mapIt(it.lineClaim & "\n").join)
    writeFile(root / "curator/other.txtpb", "rows { text: \"none\" }\n")
    check root.claimsTree == claims[1 .. ^1] & claims[0..0]  # `contributor/` sorts first
    writeFile(curator, HEADER_LOG & "claims { text: \"open }\n")
    expect ValueError: discard root.claimsTree
    removeDir(root)


  test "driver of audit declares `protoc` that suite reads log with":
    let (output, code) = execCmdEx(
      "nim r --hints:off tools/build.nim system",
      workingDir = currentSourcePath().parentDir / "../..",
    )
    check code == 0
    check output.splitLines.anyIt(it.strip == "protobuf-compiler")


  test "escaped quote in text is no key, so only field opens one":
    let line = Claim(text: "key: \"x\"", key: "s/c/1/STATE_HIT").lineClaim
    check line.keysIn == ["s/c/1/STATE_HIT"].toHashSet
    check "claims { text: \"none\" }".keysIn.len == 0


  test "branch names log and project in scope it writes, and checkout outside grammar names none":
    check pathLog(BRANCH) == PROJECT & "/claims.txtpb"
    check pathLog("curator/knoller/rule-names") == "curator/knoller/claims.txtpb"
    check pathLog("curator/claims-log") == PATH_LOG_CURATOR
    for branch in ["HEAD", "main", "claude/fix-x", "contributor/nowhere/x/y"]:
      check pathLog(branch) == ""
    check projectBranch(BRANCH) == PROJECT
    check projectBranch("curator/audit/rule-names") == "curator/audit"
    check projectBranch("curator/claims-log") == "curator"
    check projectBranch("HEAD") == "curator"  # root curator alone keeps checkout detached


  test "rows reach log of branch once each, and wait outside tree for checkout of none":
    let
      root = createTempDir("claims_", "_root")
      waiting = root / "outside" / FILE_WAITING
      claims = transcript().claimsRead
      path = root / pathLog(BRANCH)
    check appendClaims(root, BRANCH, waiting, claims) == claims.len
    let first = readFile(path)
    check first == HEADER_LOG & claims.mapIt(it.lineClaim & "\n").join
    check appendClaims(root, BRANCH, waiting, claims) == 0  # each key written once
    check readFile(path) == first
    check not fileExists(waiting)
    check appendClaims(root, "HEAD", waiting, claims[0 .. 1]) == 2  # no branch, so rows wait
    check appendClaims(root, "HEAD", waiting, claims) == 1  # two of them wait already
    check readFile(waiting).startsWith(HEADER_LOG)
    check readFile(waiting).keysIn == claims.mapIt(it.key).toHashSet
    let other = createTempDir("claims_", "_other")
    check appendClaims(other, BRANCH, waiting, claims) == 0  # each waits, so log takes none
    check not fileExists(other / pathLog(BRANCH))
    removeDir(root)
    removeDir(other)


  test "stop logs reflection written again once, and later mark of claim that waits once more":
    let
      root = rootTemplates()
      waiting = root / "outside" / FILE_WAITING
      first = transcript()
      again = first & lineSaid(REFLECTION.replace("| ⬜ | 60% | a claim of no block | none |\n",
        ""), "u10")
      later = again & lineSaid("## Reflection\n\n**Subagent:** critic of the report.\n\n" &
        "| State | Confidence | Predicted | Result |\n| --- | --- | --- | --- |\n" &
        "| ✅ | 65% | it fails one claim of the report | the resolver marks it |\n", "u11")
    check logStop(root, BRANCH, waiting, first.parseTurn.subagents) == 3
    check logStop(root, BRANCH, waiting, first.parseTurn.subagents) == 0  # reply reads it again
    check logStop(root, BRANCH, waiting, again.parseTurn.subagents) == 0  # same keys
    check logStop(root, BRANCH, waiting, later.parseTurn.subagents) == 1
    let keys = readFile(root / pathLog(BRANCH)).keysIn
    check DELEGATE & "/toolu_critic/1/STATE_WAITING" in keys
    check DELEGATE & "/toolu_critic/1/STATE_HIT" in keys
    check keys.len == 4
    removeDir(root)


  test "stop whose log cannot be written counts none and raises nothing":
    let root = rootTemplates()
    createDir(root / "contributor/bangu")
    writeFile(root / PROJECT, "")  # project folder is file, so log cannot go under it
    check logStop(root, BRANCH, root / FILE_WAITING, transcript().parseTurn.subagents) == -1
    check not fileExists(root / FILE_WAITING)
    removeDir(root)


  test "stop commits new rows of log alone, by its path, and nothing where a guard holds":
    # Ruling `D1 a` of #1059: hook commits log, so next push carries rows with no turn spent.
    #   Domain: branch of contributor, of curator project and of root curator; change staged for
    #   other path; rows of one, two and three kinds; log new and tracked; no new row; row lost;
    #   detached checkout, branch outside grammar, and merge, cherry-pick, revert and rebase.
    var count = 0  # Rows rendered, so each row is new.

    proc row(kind: string): string =
      ## Render new row of claim of transcript under kind.
      inc count
      kind.rowKind(count)

    # Branch of contributor: log new to git, then tracked, with change staged for other path.
    let
      root = repoBranch(BRANCH)
      path = pathLog(BRANCH)
    root.writeInto(path, HEADER_LOG & row("reviewer"))
    root.writeInto("other.txt", "staged\n")
    discard root.git("add other.txt")
    check commitClaims(root, BRANCH)  # log new to git
    check root.subject == "chore(rictadni): log the claims of the reviewer"
    check root.git("show --name-only --format= HEAD").strip == path
    check root.git("diff --cached --name-only").strip == "other.txt"  # other path stays staged
    check root.git("status --porcelain -- " & path).len == 0
    check not commitClaims(root, BRANCH)  # no new row
    root.writeInto(path, readFile(root / path) & row("builder") & row("critic") & row("builder"))
    check commitClaims(root, BRANCH)
    check root.subject == "chore(rictadni): log the claims of the builder and the critic"
    root.writeInto(path, readFile(root / path) & row("builder") & row("critic") & row("resolver"))
    check commitClaims(root, BRANCH)
    check root.subject ==
        "chore(rictadni): log the claims of the builder, the critic and the resolver"
    root.writeInto(path, HEADER_LOG & row("surveyor"))  # each earlier row lost
    check not commitClaims(root, BRANCH)
    check root.subject ==
        "chore(rictadni): log the claims of the builder, the critic and the resolver"
    removeDir(root)

    # Branch of curator project, and root branch of curator, whose log record of checker holds.
    for (branch, scope) in [("curator/knoller/rule-docs", "knoller"), ("curator/claims", "audit")]:
      let other = repoBranch(branch)
      other.writeInto(pathLog(branch), HEADER_LOG & row("reviewer"))
      checkpoint branch
      check commitClaims(other, branch)
      check other.subject == &"chore({scope}): log the claims of the reviewer"
      removeDir(other)

    # Branch outside grammar and detached checkout name no log.
    let outside = repoBranch("claude/setup")
    outside.writeInto(PATH_LOG_CURATOR, HEADER_LOG & row("reviewer"))
    check not commitClaims(outside, "claude/setup")  # branch outside grammar logs no path
    discard outside.git("checkout -q --detach")
    check not commitClaims(outside, "HEAD")  # detached checkout of root curator
    removeDir(outside)

    # Merge, cherry-pick, revert or rebase in progress commits nothing.
    for name in ["MERGE_HEAD", "CHERRY_PICK_HEAD", "REVERT_HEAD", "rebase-merge", "rebase-apply"]:
      let busy = repoBranch(BRANCH)
      busy.writeInto(pathLog(BRANCH), HEADER_LOG & row("reviewer"))
      let at = busy / busy.git("rev-parse --git-path " & name).strip
      if name.startsWith("rebase"): createDir(at) else: writeFile(at, "")
      checkpoint name
      check not commitClaims(busy, BRANCH)
      check busy.subject == "chore(curator): init"
      removeDir(busy)


  test "stop commits no log right after test commit, so fix can follow it, and commits after fix":
    # Case held: review of #1059's build, whose `ladder.sh` committed `test(rictadni)`, then a
    #   row, which hook committed, so commit hook refused `fix(rictadni)` after it.
    #   Domain: `test` of scope of branch and of other scope, then `fix`, `docs` and `chore`.
    let
      root = repoBranch(BRANCH)
      path = pathLog(BRANCH)
    for (n, scope) in [(1, "rictadni"), (2, "audit")]:
      root.writeInto(&"probe{n}.txt", "probe\n")
      discard root.git(&"add probe{n}.txt")
      discard root.git(&"commit -q -m 'test({scope}): hold the probe'")
      root.writeInto(path, (if n == 1: HEADER_LOG else: readFile(root / path)) &
          rowKind("reviewer", n))
      checkpoint scope
      check not commitClaims(root, BRANCH)
      check root.subject == &"test({scope}): hold the probe"
      root.writeInto(&"probe{n}.txt", "fixed\n")
      discard root.git(&"add probe{n}.txt")
      discard root.git(&"commit -q -m 'fix({scope}): mend the probe'")
      check commitClaims(root, BRANCH)
      check root.subject == "chore(rictadni): log the claims of the reviewer"
    for kind in ["docs", "chore"]:
      root.writeInto(path, readFile(root / path) & rowKind("critic", 10 + kind.len))
      discard root.git(&"commit -q --allow-empty -m '{kind}(rictadni): mark the probe'")
      checkpoint kind
      check commitClaims(root, BRANCH)
    removeDir(root)


  test "stop commits log that index holds and HEAD lacks, as any new log":
    # Case held: E1 of `cases.sh` of review of #1059's build: new log staged, so `ls-files` read
    #   it as tracked, `show HEAD:` failed, and each later stop failed again.
    #   Domain: new log staged, and log of HEAD with new rows staged.
    let
      root = repoBranch(BRANCH)
      path = pathLog(BRANCH)
    root.writeInto(path, HEADER_LOG & rowKind("reviewer", 1))
    discard root.git("add -- " & path)
    check commitClaims(root, BRANCH)
    check root.git("status --porcelain -- " & path).len == 0
    root.writeInto(path, readFile(root / path) & rowKind("critic", 2))
    discard root.git("add -- " & path)
    check commitClaims(root, BRANCH)
    check root.subject == "chore(rictadni): log the claims of the critic"
    removeDir(root)


  test "rows waiting outside tree move into log of root branch once each, and file goes":
    let
      root = createTempDir("claims_", "_move")
      waiting = root / "outside" / FILE_WAITING
      claims = transcript().claimsRead
      branch = "curator/claims-log"
    check appendClaims(root, "HEAD", waiting, claims) == claims.len
    for other in ["claude/fix-x", BRANCH, "curator/audit/rule-names"]:
      check moveClaims(root, other, waiting) == (0, "")  # rows of root curator stay waiting
    check fileExists(waiting)
    discard appendClaims(root, branch, root / "none.txtpb", claims[0 .. 0])
    check moveClaims(root, branch, waiting) == (claims.len - 1, PATH_LOG_CURATOR)
    check not fileExists(waiting)
    let text = readFile(root / PATH_LOG_CURATOR)
    check text.startsWith(HEADER_LOG)
    check text.keysIn == claims.mapIt(it.key).toHashSet
    check text.count(claims[0].key) == 1
    removeDir(root)


  test "effort of each template reads by its kind, and template naming none adds none":
    let root = createTempDir("claims_", "_templates")
    createDir(root / DIRECTORY_AGENTS)
    writeFile(root / DIRECTORY_AGENTS / "critic.md", "---\nname: critic\neffort: xhigh\n---\n")
    writeFile(root / DIRECTORY_AGENTS / "driver.md", "---\nname: driver\n---\n")
    check readEfforts(root) == {"critic": "xhigh"}.toTable
    check readKinds(root) == @["critic", "driver"]
    removeDir(root)
