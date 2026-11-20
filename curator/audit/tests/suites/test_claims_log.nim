## Replicate log of claims: rows of reflection read from transcript, line of each, its path by
##   branch, and file `stop` writes, reads back and moves.
##   Text format of each line is read back through `buf convert` against `claims.proto`, value by
##     value, since `buf` drops unknown field with no error.
##   Cost: round trip runs `buf`, so cold store fetches it, about 33 MB, and needs network.

{.experimental: "strictFuncs".}

import std/[json, options, os, osproc, sequtils, sets, strutils, tables, tempfiles, unittest]
import ../../src/[bufbuild, claims_log, hooks]


const
  KINDS = ["critic", "resolver", "reviewer"]  ## Kinds templates of scratch root name.
  DELEGATE = "s1"  ## `sessionId` of each entry of reflection.
  UUID = "u9"  ## `uuid` of entry of reflection.
  STAMP = "2026-11-20T11:57:03.512Z"  ## `timestamp` of entry of reflection.
  MODEL = "claude-opus-5-5"  ## Model result of each call names.
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


func lineUser(text, kind: string): string =
  ## Write transcript line of user entry holding text, from origin of kind.
  $(%*{"type": "user", "origin": {"kind": kind}, "message": {"content": text}}) & "\n"


func lineSaid(text: string, uuid = ""): string =
  ## Write transcript line of assistant entry holding text that ends model turn, as entry of
  ##   delegate `DELEGATE` at `STAMP`, with uuid.
  $(%*{"type": "assistant", "uuid": uuid, "timestamp": STAMP, "sessionId": DELEGATE, "message": {
    "content": [{"type": "text", "text": text}], "stop_reason": "end_turn",
  }}) & "\n"


func linesAgent(kind: string, effort = ""): string =
  ## Write transcript lines of `Agent` call of kind, with input effort where one is given, and its
  ##   launch notice, whose result names model `MODEL`.
  var input = %*{"subagent_type": kind, "description": "Do the work", "prompt": "Do it."}
  if effort.len > 0: input["effort"] = %effort
  let
    call = %*{"type": "assistant", "message": {"content": [{
      "type": "tool_use", "id": "toolu_" & kind, "name": "Agent", "input": input,
    }], "stop_reason": "tool_use"}}
    answer = %*{"type": "user", "message": {"content": [{
      "type": "tool_result", "tool_use_id": "toolu_" & kind, "content": "Async agent launched.",
    }]}, "toolUseResult": {
      "status": "async_launched", "agentId": "a" & kind, "resolvedModel": MODEL,
    }}
  $call & "\n" & $answer & "\n"


func lineHandback(name: string): string =
  ## Write transcript line of hand-back of subagent of kind name.
  $(%*{"type": "user", "isMeta": true, "origin": {
    "kind": "peer", "from": "a" & name, "name": name, "handback": true,
  }, "message": {"content": "[Subagent hand-back] Report."}}) & "\n"


func transcript(reflection = REFLECTION): string =
  ## Write transcript of reviewer and its critic, each with its block in turn of its own, then
  ##   reflection in last turn.
  lineUser("Review the diff.", "human") & lineSaid(PREDICTION_REVIEWER) &
    lineUser("timer", "task-notification") & linesAgent("reviewer", "medium") &
    lineSaid("Started.") & lineHandback("reviewer") & lineSaid(PREDICTION_CRITIC) &
    lineUser("timer", "task-notification") & linesAgent("critic") &
    lineSaid("The critic runs.") & lineHandback("critic") & lineSaid(reflection, UUID)


proc claimsRead(text: string): seq[Claim] =
  ## Read claims of last turn of transcript, with effort `xhigh` for template of critic.
  text.parseTurn.subagents.claimsTurn(KINDS, {"critic": "xhigh"}.toTable)


proc converted(log: string): JsonNode =
  ## Read log text back through `buf convert`, as JSON of its `Log`.
  let binary = bufbuildIn(rootBufbuild(getEnv(KEY_BUFBUILD)))
  doAssert binary.isSome, "buf could not be fetched"
  let
    directory = createTempDir("claims_", "_log")
    path = directory / FILE_LOG
    schema = currentSourcePath().parentDir / "../../src/claims.proto"
  writeFile(path, log)
  let (output, code) = execCmdEx(quoteShellCommand([
    binary.get, "convert", schema, "--type", "claims.Log", "--from", path, "--to", "-#format=json"
  ]))
  removeDir(directory)
  doAssert code == 0, "buf convert failed; got `" & output & "`."
  output.parseJson



suite "Log of claims":
  test "each number of text reads with its groups and decimal part, and nothing around it":
    check "100,000, 160,000 and 300,000".numbersIn == @[100_000.0, 160_000.0, 300_000.0]
    check "$0.06, $0.13 and $0.30".numbersIn == @[0.06, 0.13, 0.30]
    check "52 of 60, 2.4°, 1,23".numbersIn == @[52.0, 60.0, 2.4, 1.0, 23.0]
    check "1.75.0 and 9.".numbersIn == @[1.75, 9.0]  # digit after point opens no number
    check "none here".numbersIn.len == 0


  test "number is claim that its percentiles end, with or without label":
    check PREDICTION_REVIEWER.isNumber(
      "Work: tokens summed over its requests: 100,000, 160,000 and 300,000")
    check PREDICTION_REVIEWER.isNumber(
      "tokens summed over its requests: 100,000, 160,000 and 300,000")
    check not PREDICTION_REVIEWER.isNumber("the race leads the findings")
    check not PREDICTION_REVIEWER.isNumber("tokens summed over its requests")


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
    check first.kind == "reviewer"
    check first.model == MODEL
    check first.effort == "medium"  # input of call, ahead of template
    check first.confidence == 0.7
    check first.state == State.Hit
    check (first.tokens, first.cost) == (170_000, 1.1)
    check first.address == DELEGATE & "/" & UUID & "/1"
    check first.result == "it leads, as \"high\" | first"
    check first.number.isNone


  test "number takes its percentiles from its text, and its outcome from its result":
    let number = transcript().claimsRead[1]
    check number.state == State.Miss
    check number.confidence == 0.8
    check number.address == DELEGATE & "/" & UUID & "/2"
    check number.number.isSome
    let percentiles = number.number.get
    check (percentiles.low, percentiles.median, percentiles.high) == (1e5, 1.6e5, 3e5)
    check percentiles.outcome == some(320_000.0)
    let silent = transcript(REFLECTION.replace("320,000, above", "above")).claimsRead[1]
    check silent.number.get.outcome.isNone


  test "claim of block of critic takes call of critic, with its line and effort of template":
    let critic = transcript().claimsRead[2]
    check critic.kind == "critic"
    check critic.effort == "xhigh"
    check (critic.tokens, critic.cost) == (50_000, 0.35)
    check critic.state == State.Waiting
    check critic.address == DELEGATE & "/" & UUID & "/5"


  test "critic that line `**Subagent:**` names reads that line, as replay of critic does":
    let
      reflection = "## Reflection\n\n**Subagent:** critic of replay C2, 12,709,459 tokens and " &
        "$5.57 at list price, 40 calls, 31 min.\n\n| State | Confidence | Predicted | Result " &
        "|\n| --- | --- | --- | --- |\n| ✅ | 65% | it fails one claim of the report | it does |\n"
      text = lineUser("Check the report.", "human") & lineSaid(PREDICTION_CRITIC) &
        lineUser("timer", "task-notification") & linesAgent("critic", "max") &
        lineSaid("The critic runs.") & lineHandback("critic") & lineSaid(reflection, UUID)
      claims = text.claimsRead
    check claims.len == 1
    check (claims[0].kind, claims[0].effort) == ("critic", "max")
    check (claims[0].tokens, claims[0].cost) == (12_709_459, 5.57)


  test "missed prediction, cell quoting no claim, and reflection of earlier turn give no claim":
    let rows = transcript().claimsRead
    check rows.allIt(it.text notin ["No prediction", "a claim of no block"])
    check (transcript() & lineSaid("Done.")).claimsRead.len == 0  # reflection is of earlier turn


  test "line writes each field in order of schema, escaped, and leaves out each default":
    let claim = transcript().claimsRead[0]
    check claim.lineClaim == "claims { date: \"2026-11-20\" delegate: \"s1\" kind: \"reviewer\" " &
      "model: \"claude-opus-5-5\" effort: \"medium\" text: \"the race leads the findings\" " &
      "confidence: 0.7 state: STATE_HIT marker: MARKER_DELEGATE tokens: 170000 cost: 1.1 " &
      "address: \"s1/u9/1\" result: \"it leads, as \\\"high\\\" | first\" }"
    check Claim(text: "a\\b\n\t\x01").lineClaim ==
      "claims { text: \"a\\\\b\\n\\t\\x01\" marker: MARKER_DELEGATE }"


  test "buf reads each line back against schema, value by value":
    var claims = transcript().claimsRead
    claims.add Claim(text: "quote \" slash \\ tab \t mark ✅ 2.4°", state: State.Annulled)
    let
      log = HEADER_LOG & claims.mapIt(it.lineClaim & "\n").join
      read = log.converted["claims"].getElems
    check read.len == claims.len
    for k, claim in claims:
      check read[k]{"text"}.getStr == claim.text
      check read[k]{"date"}.getStr == claim.date
      check read[k]{"kind"}.getStr == claim.kind
      check read[k]{"model"}.getStr == claim.model
      check read[k]{"effort"}.getStr == claim.effort
      check read[k]{"confidence"}.getFloat == claim.confidence
      check read[k]{"marker"}.getStr == "MARKER_DELEGATE"
      check read[k]{"tokens"}.getStr("0").parseInt == claim.tokens  # int64 reads as string
      check read[k]{"cost"}.getFloat == claim.cost
      check read[k]{"address"}.getStr == claim.address
      check read[k]{"result"}.getStr == claim.result
    check read.mapIt(it{"state"}.getStr) ==
      @["STATE_HIT", "STATE_MISS", "STATE_WAITING", "STATE_ANNULLED"]
    let number = read[1]{"number"}
    check (number{"low"}.getFloat, number{"median"}.getFloat, number{"high"}.getFloat) ==
      (1e5, 1.6e5, 3e5)
    check number{"outcome"}.getFloat == 320_000.0
    check read[0]{"number"} == nil


  test "escaped quote in text is no address, so only field opens one":
    let line = Claim(text: "address: \"x\"", address: "s/u/1").lineClaim
    check line.addressesIn == ["s/u/1"].toHashSet
    check "claims { text: \"none\" }".addressesIn.len == 0


  test "branch names log in scope it writes, and checkout outside grammar names none":
    check pathLog("contributor/bangu/rictadni/outside-names") ==
      "contributor/bangu/rictadni/claims.txtpb"
    check pathLog("curator/knoller/rule-names") == "curator/knoller/claims.txtpb"
    check pathLog("curator/claims-log") == PATH_LOG_CURATOR
    for branch in ["HEAD", "main", "claude/fix-x", "contributor/nowhere/x/y"]:
      check pathLog(branch) == ""


  test "rows reach log of branch once each, and wait outside tree for checkout of none":
    let
      root = createTempDir("claims_", "_root")
      waiting = root / "outside" / FILE_WAITING
      claims = transcript().claimsRead
      branch = "contributor/bangu/rictadni/outside-names"
      path = root / pathLog(branch)
    check appendClaims(root, branch, waiting, claims) == claims.len
    let first = readFile(path)
    check first == HEADER_LOG & claims.mapIt(it.lineClaim & "\n").join
    check appendClaims(root, branch, waiting, claims) == 0  # each address written once
    check readFile(path) == first
    check not fileExists(waiting)
    check appendClaims(root, "HEAD", waiting, claims[0 .. 1]) == 2  # no branch, so rows wait
    check appendClaims(root, "HEAD", waiting, claims) == 1  # two of them wait already
    check readFile(waiting).startsWith(HEADER_LOG)
    check readFile(waiting).addressesIn == claims.mapIt(it.address).toHashSet
    let other = createTempDir("claims_", "_other")
    check appendClaims(other, branch, waiting, claims) == 0  # each waits, so log takes none
    check not fileExists(other / pathLog(branch))
    removeDir(root)
    removeDir(other)


  test "rows waiting outside tree move into log of branch once each, and file goes":
    let
      root = createTempDir("claims_", "_move")
      waiting = root / "outside" / FILE_WAITING
      claims = transcript().claimsRead
      branch = "curator/claims-log"
    check appendClaims(root, "HEAD", waiting, claims) == claims.len
    check moveClaims(root, "claude/fix-x", waiting) == (0, "")  # branch writes no log
    check fileExists(waiting)
    discard appendClaims(root, branch, root / "none.txtpb", claims[0 .. 0])
    check moveClaims(root, branch, waiting) == (claims.len - 1, PATH_LOG_CURATOR)
    check not fileExists(waiting)
    let text = readFile(root / PATH_LOG_CURATOR)
    check text.startsWith(HEADER_LOG)
    check text.addressesIn == claims.mapIt(it.address).toHashSet
    check text.count(claims[0].address) == 1
    removeDir(root)


  test "effort of each template reads by its kind, and template naming none adds none":
    let root = createTempDir("claims_", "_templates")
    createDir(root / DIRECTORY_AGENTS)
    writeFile(root / DIRECTORY_AGENTS / "critic.md", "---\nname: critic\neffort: xhigh\n---\n")
    writeFile(root / DIRECTORY_AGENTS / "driver.md", "---\nname: driver\n---\n")
    check readEfforts(root) == {"critic": "xhigh"}.toTable
    check readKinds(root) == @["critic", "driver"]
    removeDir(root)
