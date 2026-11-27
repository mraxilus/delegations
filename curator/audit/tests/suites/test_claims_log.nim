## Replicate log of claims: rows of reflection read from transcript, line of each, its key, its
##   path and project by branch, and file `stop` writes, reads back and moves.
##   Text format of each line is read back through `protoc` against `claims.proto`, field by
##     field: `--encode` refuses misspelt field, which `buf convert` drops with no error, as
##     Architect ruled on #989 (comment 7053329096).
##   Cost: round trip runs `protoc`, which `tools/build.nim` declares, so machine lacking it fails.

{.experimental: "strictFuncs".}

import std/[json, options, os, osproc, sequtils, sets, streams, strutils, tables, tempfiles]
import std/unittest
import ../../src/[claims_log, hooks, sums_exact]
import ./fixtures


const
  KINDS = ["builder", "critic", "resolver", "reviewer"]  ## Kinds templates of scratch root name.
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
  PREDICTION_BULLETS = """## Prediction

**Subagent:** reviewer of the diff, fresh context.

- Judgement: The diff weakens no test. (85%). Resolution criterion: no assertion goes.
- Work: tokens summed over its requests: 100,000, 160,000 and 300,000, as the 5th, 50th and
  95th percentiles. Resolution criterion: the sum of the usage of its requests.
- Cost: cost at list price: $0.40, $0.90 and $2.00, as the 5th, 50th and 95th percentiles.
  Resolution criterion: the cost on the line `**Subagent:**` of the reflection.
- Time: time to its report, in minutes: 5, 12 and 30, as the 5th, 50th and 95th percentiles.
  Resolution criterion: the minutes on the line `**Subagent:**` of the reflection.
- Count: findings that the report ranks: 3, 6 and 11, as the 5th, 50th and 95th percentiles.
  Resolution criterion: the count of the findings that the report ranks.
"""
    ## Block of reviewer in bullets, as GUIDE.md wrote it before tables: claim of each unit.
  REFLECTION_BULLETS = """## Reflection

**Subagent:** reviewer of the diff, 170,000 tokens and $1.10 at list price, 57 calls, 15 min.

| State | Confidence | Predicted | Result |
| --- | --- | --- | --- |
| ✅ | 85% | The diff weakens no test. | Each assertion stands. |
| ✅ | 90% | tokens summed over its requests: 100,000, 160,000 and 300,000 | 170,000, inside |
| ✅ | 90% | cost at list price: $0.40, $0.90 and $2.00 | $1.10, inside |
| ✅ | 90% | time to its report, in minutes: 5, 12 and 30 | 15m, inside |
| ⬜ | 90% | Count: findings that the report ranks: 3, 6 and 11 | 12, above the 95th |
"""
    ## Reflection on `PREDICTION_BULLETS`.
  PREDICTION_TABLE = """## Prediction

**Subagent:** reviewer of the diff, fresh context.

**Judgements.** One claim.

| # | % | Judgement |
| --- | :---: | --- |
| 1 | 85% | The diff weakens no test. |

**Estimates.** Four numbers.

| # | Estimate @ 90% | 5th | 50th | 95th |
| --- | --- | ---: | ---: | ---: |
| 2 | The reviewer uses ~160k tokens. | 100k | 160k | 300k |
| 3 | The reviewer costs ~$0.90. | $0.40 | $0.90 | $2.00 |
| 4 | The reviewer takes ~12m. | 5m | 12m | 30m |
| 5 | The report ranks ~6 findings. | 3 | 6 | 11 |

**Criteria.** By number.

| # | Resolution criterion |
| --- | --- |
| 1 | No assertion goes. |
| 2 | The sum of the usage of its requests. |
| 3 | The cost on the line `**Subagent:**` of the reflection. |
| 4 | The minutes on the line `**Subagent:**` of the reflection. |
| 5 | The count of the findings that the report ranks. |
"""
    ## Block of `PREDICTION_BULLETS` in tables of comment 7200557915 on #1028.
  REFLECTION_TABLE = """## Reflection

**Subagent:** reviewer of the diff, 170,000 tokens and $1.10 at list price, 57 calls, 15 min.

**Judgements.** It held.

| # | State | % | Judgement | Result |
| --- | :---: | :---: | --- | --- |
| 1 | ✅ | 85% | The diff weakens no test. | Each assertion stands. |

**Estimates.** Three inside, one above.

| # | State | Estimate @ 90% | Result |
| --- | :---: | --- | --- |
| 2 | ✅ | The reviewer uses ~160k tokens. | 170,000, inside |
| 3 | ✅ | The reviewer costs ~$0.90. | $1.10, inside |
| 4 | ✅ | The reviewer takes ~12m. | 15m, inside |
| 5 | ⬜ | The report ranks ~6 findings. | 12, above the 95th |
"""
    ## Reflection on `PREDICTION_TABLE`, each result as `REFLECTION_BULLETS` gives it.


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


func transcriptOne(prediction, kind, reflection: string): string =
  ## Write transcript of one call of kind, with block prediction in turn of its own, then
  ##   reflection in last turn.
  lineUser("Do the work.", "human") & linesPredicted(prediction, kind) & lineSaid(reflection, UUID)


func transcript(reflection = REFLECTION): string =
  ## Write transcript of reviewer and its critic, each with its block in turn of its own, then
  ##   reflection in last turn.
  lineUser("Review the diff.", "human") &
    linesPredicted(PREDICTION_REVIEWER, "reviewer", "medium") &
    linesPredicted(PREDICTION_CRITIC, "critic") & lineSaid(reflection, UUID)


proc claimsRead(text: string): seq[Claim] =
  ## Read claims of last turn of transcript, with effort `xhigh` for template of critic.
  text.parseTurn.subagents.claimsTurn(KINDS, {"critic": "xhigh"}.toTable, PROJECT)


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


func positionClaim(text, claim: string): int =
  ## Read number of first claim of block text whose forms hold claim, as key of its row names it;
  ##   0 where none does.
  for forecast in text.forecasts:
    if claim in forecast.forms: return forecast.position


func isNumber(text, claim: string): bool =
  ## Decide whether first claim of block text whose forms hold claim is number, as log reads it.
  for forecast in text.forecasts:
    if claim in forecast.forms: return forecast.is_number



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


  test "reflection of tables writes eight rows of case as found, each with its unit (#1028)":
    # Case as found: example of comment 7200557915, which `D1 a` of comment 7218520265 rules;
    #   rows 2, 4 and 5 as posted quote part of their claim, so they give none until mended.
    var whole = REFLECTION_TABLES_POSTED
    for (part, claim) in QUOTES_PART: whole = whole.replace(part, claim)
    let
      posted = transcriptOne(PREDICTION_TABLES, "builder", REFLECTION_TABLES_POSTED).claimsRead
      claims = transcriptOne(PREDICTION_TABLES, "builder", whole).claimsRead
    check posted.mapIt(it.key.split('/')[2]) == @["1", "3", "6", "7", "8"]
    check claims.len == 8
    check claims.mapIt(it.text) == PREDICTION_TABLES.forecasts.mapIt(it.forms[0])
    check claims.mapIt(it.confidence) == @[0.8, 0.8, 0.75, 0.75, 0.55, 0.9, 0.9, 0.9]
    check claims.allIt(it.state == State.Hit and it.kind == "builder")
    check claims.allIt((it.tokens, it.cost) == (39_100_000, 14.4))
    check claims.mapIt(it.key) == toSeq(1..8).mapIt(DELEGATE & "/toolu_builder/" & $it &
      "/STATE_HIT")
    check claims.mapIt(it.address) == toSeq(1..8).mapIt(DELEGATE & "/" & UUID & "/" & $it)
    check claims[0 .. 4].allIt(it.number.isNone)
    check claims[5].number == some(Number(low: 5e6, median: 15e6, high: 45e6,
      outcome: some(39_100_000.0), unit: UnitNumber.Tokens))
    check claims[6].number == some(Number(low: 2.5, median: 7, high: 20, outcome: some(14.4),
      unit: UnitNumber.Cost))
    check claims[7].number == some(Number(low: 20, median: 50, high: 120, outcome: some(47.0),
      unit: UnitNumber.Time))
    check claims[7].result == "47m, inside"


  test "claim of bullets and its claim of tables give equal rows, but text of number (#1028)":
    # Domain: judgement, and number of each unit, each scale of cells, and hit and miss.
    let
      bullets = transcriptOne(PREDICTION_BULLETS, "reviewer", REFLECTION_BULLETS).claimsRead
      table = transcriptOne(PREDICTION_TABLE, "reviewer", REFLECTION_TABLE).claimsRead
    check bullets.len == 5 and table.len == 5
    check bullets.mapIt(it.number.map(proc (n: Number): UnitNumber = n.unit)) == @[
      none(UnitNumber), some(UnitNumber.Tokens), some(UnitNumber.Cost), some(UnitNumber.Time),
      some(UnitNumber.Count)]
    check bullets[0].text == table[0].text  # judgement quotes one text in either form
    for k in 0 ..< bullets.len:
      var (a, b) = (bullets[k], table[k])
      check a.number.isSome == (k > 0)
      (a.text, b.text) = ("", "")
      check a == b
    check bullets[4].number.get == Number(low: 3, median: 6, high: 11, outcome: some(12.0),
      unit: UnitNumber.Count)


  test "each state writes its row, and estimate that waits or is annulled takes no outcome":
    var whole = REFLECTION_TABLES_POSTED
    for (part, claim) in QUOTES_PART: whole = whole.replace(part, claim)
    const row = "| 8 | ✅ | The builder takes ~50m. | 47m, inside |"
    for (marker, state) in [("✅", State.Hit), ("⬜", State.Miss), ("➖", State.Annulled),
        ("⏸️", State.Waiting)]:
      for (cell, outcome) in [("47m, inside", some(47.0)), ("waits on the merge", none(float))]:
        let
          changed = whole.replace(row, row.replace("✅", marker).replace("47m, inside", cell))
          claims = transcriptOne(PREDICTION_TABLES, "builder", changed).claimsRead
        check claims.len == 8
        check claims[7].state == state
        check claims[7].key.endsWith("/8/" & ["STATE_UNSPECIFIED", "STATE_HIT", "STATE_MISS",
          "STATE_ANNULLED", "STATE_WAITING"][ord(state)])
        check claims[7].number.get.outcome == outcome
    let unmarked = whole.replace(row, row.replace("| ✅ |", "| yes |"))
    check transcriptOne(PREDICTION_TABLES, "builder", unmarked).claimsRead.len == 7


  test "sample reflection of GUIDE.md writes one row for each claim of sample prediction":
    # Delegate copies form from samples, so their rows reach log whole, in either form.
    const guide = staticRead("../../../../GUIDE.md")
    func sample(heading: string): string =
      ## Read text of sample in fence that opens with heading.
      let at = guide.find("```md\n" & heading & "\n")
      guide[at + "```md\n".len ..< guide.find("\n```", at)] & "\n"
    let
      prediction = sample(HEADING_PREDICTION)
      claims = transcriptOne(prediction, "reviewer", sample(HEADING_REFLECTION)).claimsRead
    check prediction.forecasts.len > 0
    check claims.len == prediction.forecasts.len
    check claims.mapIt(it.key.split('/')[2]) == prediction.forecasts.mapIt($it.position)
    check claims.filterIt(it.number.isSome).allIt(it.number.get.unit != UnitNumber.Unspecified and
      it.number.get.outcome.isSome)


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
    claims.add transcriptOne(PREDICTION_TABLE, "reviewer", REFLECTION_TABLE).claimsRead
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
      "unit: UNIT_TOKENS", "unit: UNIT_COST", "unit: UNIT_TIME", "unit: UNIT_COUNT", "low: 0.4",
    ]:
      check decoded.splitLines.anyIt(it.strip == field)
    check lines.mapIt(it.claimLine) == claims  # each field `protoc` printed, as claim holds it
    check protoc("--encode", "claims { dat: \"2026-11-20\" }\n").code != 0  # misspelt field


  test "reader reads each row of writer back into same claim, and each row of log in order":
    var claims = transcript().claimsRead
    claims.add transcriptOne(PREDICTION_TABLE, "reviewer", REFLECTION_TABLE).claimsRead
    check claims.anyIt(it.number.isSome and it.number.get.unit == UnitNumber.Count)
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


  test "prior writes one line, and protoc and reader read each field of it back (#1049)":
    let
      prior = Prior(date_first: "2026-11-20", date_last: "2026-11-21",
        keys: @[3'u64, 14695981039346656037'u64],
        tallies: @[
          Tally(model: "model-a", effort: "high", project: "curator", kind: "reviewer",
            marker: Marker.Resolver, band: 71, rows: 5, count: 4, hits: 3, hits_band: 2,
            confidence: [2.9e-17, 3.05].toSumExact,
            score: [-2.5e-15, 120.5].toSumExact, count_number: 1,
            score_number: [77.69379682749334].toSumExact),
          Tally(kind: "quote \" kind", marker: Marker.Delegate, rows: 1),
        ])
      line = prior.linePrior
      (encoded, code) = protoc("--encode", HEADER_LOG & line & "\n" &
        transcript().claimsRead.mapIt(it.lineClaim & "\n").join)
    check '\n' notin line
    check code == 0
    let (decoded, back) = protoc("--decode", encoded)
    check back == 0
    for field in [  # as `protoc` prints each field of prior it read, by name
      "date_first: \"2026-11-20\"", "date_last: \"2026-11-21\"", "keys: 3",
      "keys: 14695981039346656037",
      "model: \"model-a\"", "effort: \"high\"", "project: \"curator\"", "kind: \"reviewer\"",
      "marker: MARKER_RESOLVER", "band: 71", "rows: 5", "count: 4", "hits: 3", "hits_band: 2",
      "confidence: 2.9e-17", "confidence: 3.05", "score: -2.5e-15", "score: 120.5",
      "count_number: 1", "kind: \"quote \\\" kind\"",
      "score_number: 77.693796827493344",  # `protoc` prints 17 digits where 15 read no way back
      "marker: MARKER_DELEGATE", "rows: 1",
    ]:
      check decoded.splitLines.anyIt(it.strip == field)
    check line.priorLine == prior  # each partial to last bit
    check Prior().linePrior.priorLine == Prior()
    check protoc("--encode", "prior { tallies { hit: 1 } }\n").code != 0  # misspelt field


  test "log reads prior wherever merge puts it, and refuses two priors where none holds other":
    # Merge by `union` puts rows before prior, or joins two rolls, as their order of merge falls.
    let
      rows = transcript().claimsRead.mapIt(it.lineClaim & "\n").join
      prior = Prior(date_first: "2026-11-20", keys: @[1'u64],
        tallies: @[Tally(kind: "reviewer", rows: 2)]).linePrior & "\n"
      wider = Prior(keys: @[1'u64, 2],
        tallies: @[Tally(kind: "reviewer", rows: 3)]).linePrior & "\n"
      other = Prior(keys: @[2'u64], tallies: @[Tally(kind: "reviewer", rows: 2)]).linePrior & "\n"
      tallied = Prior(keys: @[1'u64], tallies: @[Tally(kind: "critic", rows: 2)]).linePrior & "\n"
    check (HEADER_LOG & rows).logText == Log(claims: transcript().claimsRead)
    check (HEADER_LOG & prior & rows).logText.prior.get.date_first == "2026-11-20"
    check (HEADER_LOG & prior & rows).claimsLog == transcript().claimsRead
    check (HEADER_LOG & prior & rows).rowsLog == transcript().claimsRead.len
    check (HEADER_LOG & rows & prior).logText.prior.get.keys == @[1'u64]  # after row
    check (HEADER_LOG & prior & prior).logText.prior.get.keys == @[1'u64]  # same line twice
    check (HEADER_LOG & prior & rows & wider).logText.prior.get.keys == @[1'u64, 2]
    check (HEADER_LOG & wider & rows & prior).logText.prior.get.keys == @[1'u64, 2]
    expect ValueError: discard (HEADER_LOG & prior & other).logText  # neither holds other
    expect ValueError: discard (HEADER_LOG & prior & tallied).logText  # same rows, other tallies
    expect ValueError: discard priorLine("prior { tallies { tallies { rows: 1 } } }")
    expect ValueError: discard priorLine("prior { claims { rows: 1 } }")  # block of no tally
    expect ValueError: discard priorLine("prior { tallies { hit: 1 } }")
    expect ValueError: discard priorLine("prior { rows: 1 }")  # field of tally outside it
    expect ValueError: discard priorLine("prior { tallies { marker: MARKER_GOOD } }")
    expect ValueError: discard priorLine("prior { tallies { band: \"a\" } }")
    expect ValueError: discard priorLine("prior { date_first: \"a\" } x }")


  test "each key counts once: in prior that names it, else in its first row; row of no key always":
    let
      a = Claim(text: "a", key: "s1/c/1/STATE_HIT", marker: Marker.Delegate)
      b = Claim(text: "b", key: "s1/c/2/STATE_HIT", marker: Marker.Delegate)
      keyless = Claim(text: "none", marker: Marker.Delegate)
      log = Log(claims: @[a, b, keyless, a, keyless, b],
        prior: some(Prior(keys: @[b.key.hashKey], tallies: @[Tally(rows: 1)])))
    check log.claimsCounted == @[a, keyless, keyless]
    check Log(claims: @[a, a, b]).claimsCounted == @[a, b]


  test "claim that names no marker reads back as marked by delegate, as its line writes it":
    check Claim(text: "a").lineClaim.claimLine == Claim(text: "a", marker: Marker.Delegate)


  test "reader knows each field of schema, and no field that schema lacks":
    let schema = readFile(currentSourcePath().parentDir / "../../src/claims.proto")
    check schema.fieldsMessage("Claim") == @FIELDS_CLAIM
    check schema.fieldsMessage("Number") == @FIELDS_NUMBER
    check schema.fieldsMessage("Log") == @["claims", "prior"]
    check schema.fieldsMessage("Prior") == @FIELDS_PRIOR
    check schema.fieldsMessage("Tally") == @FIELDS_TALLY


  test "reader refuses row that writer writes no way, and unknown field, value or block":
    expect ValueError: discard claimLine("rows { text: \"a\" }")
    expect ValueError: discard claimLine("claims { dat: \"2026-11-20\" }")
    expect ValueError: discard claimLine("claims { state: STATE_GOOD }")
    expect ValueError: discard claimLine("claims { text: \"open }")
    expect ValueError: discard claimLine("claims { result { low: 1 } }")
    expect ValueError: discard claimLine("claims { number { mean: 1 } }")
    expect ValueError: discard claimLine("claims { number { unit: UNIT_GOOD } }")
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
    let prior = Prior(date_first: "2026-11-20",
      tallies: @[Tally(kind: "reviewer", marker: Marker.Delegate, rows: 2)])
    writeFile(project, HEADER_LOG & prior.linePrior & "\n")
    check root.logsTree == @[Log(prior: some(prior)), Log(claims: claims[0..0])]
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
