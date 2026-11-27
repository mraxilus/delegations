## Log each scored claim of each reflection, as text format of `claims.proto`, where role writes.
##   Claim is row of first table with column `Predicted` of `## Reflection` block of current
##     model turn, whose cell is whole claim of block call took; `No prediction`, cell quoting no
##     claim, and cell under `State` that no marker opens give none (#964). Reflection counts
##     wherever it stands in turn, below sign-off too, since its marks hold there.
##   Claim takes latest call before reflection whose block holds it, of kind line `**Subagent:**`
##     of reflection names, else of any kind, so claim of block of critic takes call of critic.
##   Kind is `subagent_type` of call, and effort is input `effort`, else `effort:` of its template
##     (`readEfforts`); model stays empty, as `D1 b` of #1025 rules, since harness keeps name of
##     model out of each file it pushes.
##   State is marker opening cell under `State`, and confidence is percentage of cell under
##     `Confidence`. Tokens and cost are first `<n> tokens` and `$<x>` of line `**Subagent:**`;
##     call of critic that line does not name reads line `**Critic:**`.
##   Number claim, whose bullet ends at percentiles (`isNumber`), takes last three numbers of its
##     text; its outcome is first number of its cell under `Result`, as GUIDE.md asks.
##   Date, delegate and address come from entry of reflection: `timestamp`, `sessionId`, `uuid`.
##   Key is delegate, id of call, position of claim in its block, and state: reflection written
##     again adds no row, and later mark of claim that waits adds one (`keysIn`).
##   Log is `claims.txtpb` of scope branch writes (`pathLog`), with project its role names; other
##     checkout writes file outside tree, with project `curator`, since root curator alone keeps
##     checkout outside grammar. `moveClaims` empties that file into log of root branch alone.
##   `stop` then commits log of branch alone, by its path, so next push carries rows with no turn
##     spent; detached checkout, branch outside grammar, merge, rebase, cherry-pick and revert
##     commit nothing (`commitClaims`, `D1 a` of #1059).
##   Text format is written here, one row to line, as exception to CONTRIBUTOR.md, Data, that
##     Architect ruled on #989 (comment 7053329096); suite reads it back through `protoc`, which
##     refuses misspelt field.
##   Text format is read here too, by `claimLine`, as `D1 a` of #964 rules (comment 7189788889):
##     each field by name, each escape of `quotedText` undone, and unknown field refused.
##   Prior of rows rolled out of log is one line, which roll writes at head of log (`linePrior`,
##     #1049). Merge by `union` can put rows before it, or join two rolls into two priors, so reader
##     reads each prior wherever it stands: log reads as prior whose keys hold keys of each other,
##     and refuses log where none does (`logText`).
##   Each key counts once, in prior that names it, else in its first row (`claimsCounted`), so row
##     that merge or replay of `stop` brings back after roll counts once.
##
##   Rejected: bytes through `protobuf_serialization`, then text through `protoc --decode`, as
##     Data asks: first dependency of audit and `protoc` at each stop of each delegate, and row
##     of 14 lines, which `union` joins into one block that `protoc` refuses.
##   Rejected: tokens summed from transcript of subagent: cost would need price of each model in
##     code, and reflection states both.
##   Cost: one claim in blocks of several calls of one kind takes latest such call alone.
##   Cost: rows waiting outside tree are lost where machine ends before `moveClaims` runs.

{.experimental: "strictFuncs".}

import std/[options, os, sequtils, sets, strformat, strutils, tables]
from std/unicode import runeLen
import ./[commits, domains, hooks, sums_exact, tree]


type
  State* {.pure.} = enum  ## Define state of claim, in order of enum `State` of `claims.proto`.
    Unspecified, Hit, Miss, Annulled, Waiting

  Marker* {.pure.} = enum  ## Define who marked state, in order of enum `Marker` of `claims.proto`.
    Unspecified  ## No marker named; line writes delegate, as each row of `stop` is.
    Delegate  ## Delegate, in table of its reflection.
    Resolver  ## Resolver, in table of its report.

  Number* = object  ## Define number claim: its percentiles, and value its result gives.
    low*: float  ## Lowest percentile: 5th at confidence 0.9, 10th at 0.8.
    median*: float  ## 50th percentile.
    high*: float  ## Highest percentile: 95th at confidence 0.9, 90th at 0.8.
    outcome*: Option[float]  ## First number of cell under `Result`; none where cell holds none.

  Claim* = object  ## Define one row of log: message `Claim` of `claims.proto`.
    date*: string  ## Day of reflection, as `2026-11-20`.
    delegate*: string  ## `sessionId` of entry of reflection, which names delegate.
    project*: string  ## Role string of branch that writes row, as `curator/audit`.
    kind*: string  ## Kind of call claim takes.
    call*: string  ## Id of tool use of that call.
    model*: string  ## Model of that call; `stop` leaves it empty (`D1 b` of #1025).
    effort*: string  ## Effort of that call, else of template of its kind.
    text*: string  ## Claim, as cell under `Predicted` quotes it.
    confidence*: float  ## Percentage of cell under `Confidence`, as fraction.
    state*: State  ## Marker opening cell under `State`.
    marker*: Marker  ## Who marked state; delegate where none is named.
    tokens*: int  ## Tokens line of reflection gives for call.
    cost*: float  ## Dollars line of reflection gives for call.
    address*: string  ## Delegate, `uuid` of entry of reflection, and row from 1, by `/`.
    key*: string  ## Delegate, call, position of claim in its block, and state, by `/`.
    number*: Option[Number]  ## Percentiles and outcome; none where claim is no number.
    result*: string  ## Cell under `Result`.

  Tally* = object
    ## Define tally of prior: sums of rolled rows whose model, effort, project, kind, marker and
    ##   band agree, as message `Tally` of `claims.proto`.
    model*: string  ## Model of call of each row.
    effort*: string  ## Effort of call of each row.
    project*: string  ## Role string of branch that wrote each row.
    kind*: string  ## Kind of call of each row.
    marker*: Marker  ## Who marked state of each row.
    band*: int  ## Lowest percentage of band of claim that takes baseline score; 0 for other.
    rows*: int  ## Rows tally holds.
    count*: int  ## Claims of yes or no that take baseline score.
    hits*: int  ## Of those, claims that hold.
    hits_band*: int  ## Of those, claims that hold on side of band: claim under 50% turns.
    confidence*: SumExact  ## Exact sum of confidence on side of band.
    score*: SumExact  ## Exact sum of baseline score.
    count_number*: int  ## Numbers that take score as continuous question.
    score_number*: SumExact  ## Exact sum of score of those numbers.

  Prior* = object
    ## Define prior at head of log: tallies of rows rolled out of it (#1049); no field names branch,
    ##   so two rolls of same rows write same line.
    date_first*: string  ## Earliest day of row rolled, as `2026-11-20`.
    date_last*: string  ## Latest day of row rolled.
    keys*: seq[uint64]  ## Hash of key of each row rolled (`hashKey`), ascending, each once.
    tallies*: seq[Tally]  ## One for each model, effort, project, kind, marker and band.

  Log* = object  ## Define log of claims: message `Log` of `claims.proto`.
    claims*: seq[Claim]  ## Claim of each row, in order of log.
    prior*: Option[Prior]  ## Prior at head of log; none until first roll.

  Cursor = object  ## Define place that reader of row has reached in its line.
    line: string  ## Line of row.
    at: int  ## Index of next character to read.

const
  FILE_LOG* = "claims.txtpb"  ## Log of each project, beside its record (#964).
  PATH_LOG_CURATOR* = CURATOR & "/audit/" & FILE_LOG
    ## Log of root branch of curator: `checkLayout` takes only index directly under `curator/`,
    ##   so record of checker holds it.
  KEY_CLAIMS* = "KOCH_CLAIMS_DIR"  ## Environment name overriding folder of rows outside tree.
  DIRECTORY_CLAIMS* = ".cache/koch/claims"
    ## Default folder of rows outside tree, under home, in koch's own directory.
  FILE_WAITING* = "waiting.txtpb"  ## File of rows that wait outside tree for branch.
  HEADER_LOG* = "# Log of claims of this project: one row of reflection to line, as `stop` " &
    "writes it (#964).\n#   Text format of message `Log` of `curator/audit/src/claims.proto`.\n"
    ## Comment new log opens with, which names its schema.
  FIELD_LOG = "claims"  ## Field of `Log` each row fills.
  FIELD_KEY = "key: \""  ## Opening of key of row, as `lineClaim` writes it.
  FIELD_NUMBER = "number"  ## Field of `Claim` that holds message `Number`.
  FIELDS_CLAIM* = ["date", "delegate", "project", "kind", "call", "model", "effort", "text",
    "confidence", "state", "marker", "tokens", "cost", "address", "key", FIELD_NUMBER, "result"]
    ## Fields of message `Claim` of `claims.proto` that reader of row knows.
  FIELDS_NUMBER* = ["low", "median", "high", "outcome"]
    ## Fields of message `Number` of `claims.proto` that reader of row knows.
  FIELD_PRIOR = "prior"  ## Field of `Log` that holds message `Prior`.
  FIELD_TALLIES = "tallies"  ## Field of `Prior` that holds each message `Tally`.
  FIELDS_PRIOR* = ["date_first", "date_last", "keys", FIELD_TALLIES]
    ## Fields of message `Prior` of `claims.proto` that reader of prior knows.
  FIELDS_TALLY* = ["model", "effort", "project", "kind", "marker", "band", "rows", "count", "hits",
    "hits_band", "confidence", "score", "count_number", "score_number"]
    ## Fields of message `Tally` of `claims.proto` that reader of prior knows.
  OPENING_PRIOR* = FIELD_PRIOR & " { "  ## Opening of line of prior, as `linePrior` writes it.
  OPENING_ROW* = FIELD_LOG & " { "  ## Opening of each row, as `lineClaim` writes it.
  CLOSING_ROW = " }"  ## Closing of each row, as `lineClaim` writes it.
  PATHS_OPERATION = [
    "MERGE_HEAD", "CHERRY_PICK_HEAD", "REVERT_HEAD", "rebase-merge", "rebase-apply"
  ]
    ## Paths under git directory that merge, cherry-pick, revert or rebase in progress leaves.
  MARK_COMMENT = '#'  ## Mark that opens comment line of log, as header of log does.
  COLUMNS = ["State", "Confidence", COLUMN_PREDICTED, "Result"]
    ## Columns of table of reflection, in order of their cells in `rowsTable`.
  MARKERS_STATE = [("✅", State.Hit), ("⬜", State.Miss), ("➖", State.Annulled),
    ("⏸", State.Waiting)]
    ## Markers of cell under `State`, as GUIDE.md gives them; `⏸️` opens with `⏸`.
  NAMES_STATE: array[State, string] =
    ["STATE_UNSPECIFIED", "STATE_HIT", "STATE_MISS", "STATE_ANNULLED", "STATE_WAITING"]
    ## Name of each value of enum `State` of `claims.proto`.
  NAMES_MARKER: array[Marker, string] = ["MARKER_UNSPECIFIED", "MARKER_DELEGATE", "MARKER_RESOLVER"]
    ## Name of each value of enum `Marker` of `claims.proto`.
  LABELS_CRITIC = ["**critic:**", "**critic**:"]
    ## Forms of label of line of reflection for critic, in lower case, as `LABELS_SUBAGENT`.
  WORD_TOKENS = " tokens"  ## Word after count of tokens, as line of reflection writes it.
  MARK_DOLLAR = '$'  ## Mark before cost, as line of reflection writes it.
  MARK_PERCENT = '%'  ## Mark after confidence, as cell under `Confidence` writes it.
  POINT = '.'  ## Mark between digits and decimal part of number.
  COMMA = ','  ## Mark between groups of three digits of number, as in `170,000`.
  DIGITS_GROUP = 3  ## Digits of group after comma.
  LENGTH_DATE = 10  ## Characters of day of ISO 8601 timestamp, as `2026-11-20`.
  OFFSET_FNV = 0xcbf29ce484222325'u64  ## Hash of FNV-1a, 64 bits, before first byte.
  PRIME_FNV = 0x100000001b3'u64  ## Prime of FNV-1a, 64 bits, that each byte meets.


func numbersIn*(text: string): seq[float] =
  ## Read each number of text, in order: digits, each group of three after comma, then decimal
  ##   part; mark before, as `$`, and comma or full stop after stay out, so `$1.10,` reads 1.1.
  ##   Digit after digit or point opens no number, so `1.75.0` reads 1.75 alone.
  var i = 0
  while i < text.len:
    if text[i] notin Digits or (i > 0 and text[i - 1] in Digits + {POINT}):
      inc i
      continue
    var
      stop = i
      digits = ""
    while stop < text.len and text[stop] in Digits:
      digits.add text[stop]
      inc stop
    while stop + DIGITS_GROUP < text.len and text[stop] == COMMA and
        text[stop + 1 .. stop + DIGITS_GROUP].allCharsInSet(Digits) and
        (stop + DIGITS_GROUP + 1 == text.len or text[stop + DIGITS_GROUP + 1] notin Digits):
      digits.add text[stop + 1 .. stop + DIGITS_GROUP]
      stop += DIGITS_GROUP + 1
    if stop + 1 < text.len and text[stop] == POINT and text[stop + 1] in Digits:
      digits.add POINT
      inc stop
      while stop < text.len and text[stop] in Digits:
        digits.add text[stop]
        inc stop
    result.add digits.parseFloat
    i = stop


func figuresLine(text: string, labels: openArray[string]): tuple[tokens: int, cost: float] =
  ## Read tokens and cost of first line of text that opens with one of labels, in any case:
  ##   number before first ` tokens`, and number right after first `$`; zero where none.
  for line in text.splitLines:
    let lower = line.strip(trailing = false).toLowerAscii
    if not labels.anyIt(lower.startsWith(it)): continue
    let at = line.find(WORD_TOKENS)
    if at > 0:
      let before = line[0 ..< at].numbersIn
      if before.len > 0: result.tokens = int(before[^1])
    let dollar = line.find(MARK_DOLLAR)
    if dollar >= 0 and dollar + 1 < line.len and line[dollar + 1] in Digits:
      result.cost = line[dollar + 1 .. ^1].numbersIn[0]
    return


func rowsTable(text: string): seq[array[COLUMNS.len, string]] =
  ## Read cells under each of `COLUMNS` of each row of first table of text whose header has
  ##   column `Predicted`, each collapsed; empty cell where its column is missing.
  ##   Table is run of lines opening with `|`, header first, as `findingsTable` of `hooks.nim`
  ##     reads it.
  let lines = text.splitLines
  var i = 0
  while i < lines.len:
    if not lines[i].strip.startsWith("|"):
      inc i
      continue
    var stop = i
    while stop < lines.len and lines[stop].strip.startsWith("|"): inc stop
    let header = lines[i].cellsRow
    if COLUMN_PREDICTED notin header:
      i = stop
      continue
    for line in lines[i + 1 ..< stop]:
      let cells = line.cellsRow
      if cells.isRowSeparator: continue
      var row: array[COLUMNS.len, string]
      for c, name in COLUMNS:
        let column = header.find(name)
        if column >= 0 and column < cells.len: row[c] = cells[column].collapsed
      result.add row
    return


func stateCell(cell: string): State =
  ## Read state that marker opening cell gives; `State.Unspecified` where none opens it.
  for (marker, state) in MARKERS_STATE:
    if cell.startsWith(marker): return state
  State.Unspecified


func confidenceCell(cell: string): float =
  ## Read last number before first `%` of cell, as fraction; zero where cell holds none.
  let at = cell.find(MARK_PERCENT)
  if at < 0: return 0
  let numbers = cell[0 ..< at].numbersIn
  if numbers.len > 0: numbers[^1] / 100 else: 0


func callTaken(
  subagents: Subagents; taken: openArray[int]; reflection: Block; claim, named: string
): int =
  ## Read index of latest call before reflection whose block holds claim, of kind named, else of
  ##   any kind; -1 where no call took block holding it.
  result = -1
  for k in countdown(subagents.calls.high, 0):
    let call = subagents.calls[k]
    if call.place.at >= reflection.place.at or taken[k] < 0: continue
    if claim notin subagents.predictions[taken[k]].text.claims: continue
    if named.len == 0 or call.kind == named: return k
    if result < 0: result = k


func claimsTurn*(
  subagents: Subagents; kinds: openArray[string]; efforts: Table[string, string]; project: string
): seq[Claim] =
  ## Read claim of each row of each reflection of current model turn whose cell under `Predicted`
  ##   is whole claim of block call took, and whose cell under `State` opens with marker, in order
  ##   of reflections and rows, each of project.
  let
    current = subagents.turns - 1
    taken = subagents.blocksTaken(kinds)
  for reflection in subagents.reflections:
    if reflection.place.turn != current: continue
    let
      named = reflection.text.kindNamed(kinds)
      figures_subagent = reflection.text.figuresLine(LABELS_SUBAGENT)
      figures_critic = reflection.text.figuresLine(LABELS_CRITIC)
    for n, row in reflection.text.rowsTable:
      let
        quoted = row[2]
        state = row[0].stateCell
      if quoted.len == 0 or quoted == NO_PREDICTION or state == State.Unspecified: continue
      let k = subagents.callTaken(taken, reflection, quoted, named)
      if k < 0: continue
      let
        call = subagents.calls[k]
        prediction = subagents.predictions[taken[k]].text
        figures = (if call.kind == KIND_CRITIC and call.kind != named: figures_critic
          else: figures_subagent)
      var claim = Claim(
        date: reflection.timestamp[0 ..< min(LENGTH_DATE, reflection.timestamp.len)],
        delegate: reflection.delegate,
        project: project,
        kind: call.kind,
        call: call.id,
        effort: (if call.effort.len > 0: call.effort else: efforts.getOrDefault(call.kind)),
        text: quoted,
        confidence: row[1].confidenceCell,
        state: state,
        marker: Marker.Delegate,
        tokens: figures.tokens,
        cost: figures.cost,
        address: reflection.delegate & "/" & reflection.uuid & "/" & $(n + 1),
        key: [reflection.delegate, call.id, $prediction.positionClaim(quoted), NAMES_STATE[state]]
          .join("/"),
        result: row[3],
      )
      let numbers = quoted.numbersIn
      if prediction.isNumber(quoted) and numbers.len >= 3:
        let outcome = row[3].numbersIn
        claim.number = some(Number(
          low: numbers[^3],
          median: numbers[^2],
          high: numbers[^1],
          outcome: (if outcome.len > 0: some(outcome[0]) else: none(float)),
        ))
      result.add claim


func quotedText(s: string): string =
  ## Write string as text format quotes it: `\`, `"` and each control character escaped, and
  ##   UTF-8 as it is, which text format reads.
  result = "\""
  for ch in s:
    case ch
    of '\\': result.add "\\\\"
    of '"': result.add "\\\""
    of '\n': result.add "\\n"
    of '\r': result.add "\\r"
    of '\t': result.add "\\t"
    of '\0' .. '\x08', '\x0B', '\x0C', '\x0E' .. '\x1F', '\x7F':
      result.add "\\x" & ch.ord.toHex(2)
    else: result.add ch
  result.add "\""


func lineClaim*(claim: Claim): string =
  ## Write claim as one line of log: field `claims` of `Log`, fields in order of their numbers.
  ##   Empty string, zero number and unspecified state stay out, as text format leaves defaults.
  var fields: seq[string]
  template put(name, value: string) =
    ## Add field of name and its value, as text format writes it.
    fields.add name & ": " & value
  if claim.date.len > 0: put "date", claim.date.quotedText
  if claim.delegate.len > 0: put "delegate", claim.delegate.quotedText
  if claim.project.len > 0: put "project", claim.project.quotedText
  if claim.kind.len > 0: put "kind", claim.kind.quotedText
  if claim.call.len > 0: put "call", claim.call.quotedText
  if claim.model.len > 0: put "model", claim.model.quotedText
  if claim.effort.len > 0: put "effort", claim.effort.quotedText
  if claim.text.len > 0: put "text", claim.text.quotedText
  if claim.confidence != 0: put "confidence", $claim.confidence
  if claim.state != State.Unspecified: put "state", NAMES_STATE[claim.state]
  let marker = (if claim.marker == Marker.Unspecified: Marker.Delegate else: claim.marker)
  put "marker", NAMES_MARKER[marker]
  if claim.tokens != 0: put "tokens", $claim.tokens
  if claim.cost != 0: put "cost", $claim.cost
  if claim.address.len > 0: put "address", claim.address.quotedText
  if claim.key.len > 0: put "key", claim.key.quotedText
  if claim.number.isSome:
    let number = claim.number.get
    var inside = @["low: " & $number.low, "median: " & $number.median, "high: " & $number.high]
    if number.outcome.isSome: inside.add "outcome: " & $number.outcome.get
    fields.add FIELD_NUMBER & " { " & inside.join(" ") & " }"
  if claim.result.len > 0: put "result", claim.result.quotedText
  FIELD_LOG & " { " & fields.join(" ") & " }"


func hashKey*(key: string): uint64 =
  ## Hash of key of row, by FNV-1a of 64 bits, as prior names each row it holds (#1049): each byte
  ##   joins by xor, then meets prime of FNV, modulo `2^64`.
  ##   Collision makes row prior holds of new one; expected chance about `n² / 2^65` for `n` keys.
  result = OFFSET_FNV
  for ch in key: result = (result xor uint64(ord(ch))) * PRIME_FNV


func lineTally(tally: Tally): string =
  ## Write tally as block `tallies` of line of prior, fields in order of their numbers, each partial
  ##   of sum as one value; empty string and zero stay out, as `lineClaim` leaves them.
  var fields: seq[string]
  template put(name, value: string) =
    ## Add field of name and its value, as text format writes it.
    fields.add name & ": " & value
  if tally.model.len > 0: put "model", tally.model.quotedText
  if tally.effort.len > 0: put "effort", tally.effort.quotedText
  if tally.project.len > 0: put "project", tally.project.quotedText
  if tally.kind.len > 0: put "kind", tally.kind.quotedText
  let marker = (if tally.marker == Marker.Unspecified: Marker.Delegate else: tally.marker)
  put "marker", NAMES_MARKER[marker]
  if tally.band != 0: put "band", $tally.band
  if tally.rows != 0: put "rows", $tally.rows
  if tally.count != 0: put "count", $tally.count
  if tally.hits != 0: put "hits", $tally.hits
  if tally.hits_band != 0: put "hits_band", $tally.hits_band
  for partial in tally.confidence.partials: put "confidence", $partial
  for partial in tally.score.partials: put "score", $partial
  if tally.count_number != 0: put "count_number", $tally.count_number
  for partial in tally.score_number.partials: put "score_number", $partial
  FIELD_TALLIES & " { " & fields.join(" ") & " }"


func linePrior*(prior: Prior): string =
  ## Write prior as one line for head of log: field `prior` of `Log`, each tally block of its own.
  var fields: seq[string]
  if prior.date_first.len > 0: fields.add "date_first: " & prior.date_first.quotedText
  if prior.date_last.len > 0: fields.add "date_last: " & prior.date_last.quotedText
  for key in prior.keys: fields.add "keys: " & $key
  for tally in prior.tallies: fields.add tally.lineTally
  OPENING_PRIOR & fields.join(" ") & CLOSING_ROW


func skipSpaces(cursor: var Cursor) =
  ## Move cursor past each space.
  while cursor.at < cursor.line.len and cursor.line[cursor.at] == ' ': inc cursor.at


func word(cursor: var Cursor): string =
  ## Read run of characters up to space, colon, brace or quote.
  while cursor.at < cursor.line.len and cursor.line[cursor.at] notin {' ', ':', '{', '}', '"'}:
    result.add cursor.line[cursor.at]
    inc cursor.at


func quoted(cursor: var Cursor): string =
  ## Read quoted text from its opening quote, undoing each escape that `quotedText` writes.
  inc cursor.at
  while cursor.at < cursor.line.len and cursor.line[cursor.at] != '"':
    if cursor.line[cursor.at] == '\\' and cursor.at + 1 < cursor.line.len:
      inc cursor.at
      case cursor.line[cursor.at]
      of 'n': result.add '\n'
      of 'r': result.add '\r'
      of 't': result.add '\t'
      of 'x':  # Slice stays inside line: short escape fails in `parseHexInt`, or at closing quote.
        result.add char(parseHexInt(cursor.line.substr(cursor.at + 1, cursor.at + 2)))
        cursor.at += 2
      else: result.add cursor.line[cursor.at]
    else: result.add cursor.line[cursor.at]
    inc cursor.at
  if cursor.at >= cursor.line.len:
    raise newException(ValueError, &"Quoted text of row has no closing quote; got `{cursor.line}`.")
  inc cursor.at


func valueName[E: enum](names: array[E, string], value: string): E =
  ## Value of enum whose name of `claims.proto` is value; `ValueError` where none is.
  for member, name in names:
    if name == value: return member
  raise newException(ValueError, &"Row of log holds no known value of enum; got `{value}`.")


func fieldsLine(line, opening, nested: string): seq[tuple[block_at: int, name, value: string]] =
  ## Read each field of one line of text format that opens with opening, in order, each with index
  ##   from 0 of block `nested` that holds it, or -1 outside each; each block opens with field of
  ##   empty name. `ValueError` for line that opens or closes otherwise, ends inside field, opens
  ##   block of other field or block in block, names field with no colon, or holds text after its
  ##   closing brace.
  if not (line.startsWith(opening) and line.endsWith(CLOSING_ROW)):
    raise newException(ValueError, &"Line of log opens or closes in no known way; got `{line}`.")
  var
    cursor = Cursor(line: line, at: opening.len)
    block_at = -1
    blocks = 0
  while true:
    cursor.skipSpaces
    if cursor.at >= line.len:
      raise newException(ValueError, &"Line of log ends inside field; got `{line}`.")
    if line[cursor.at] == '}':
      inc cursor.at
      if block_at < 0: break
      block_at = -1
      continue
    let name = cursor.word
    cursor.skipSpaces
    if cursor.at < line.len and line[cursor.at] == '{':
      if name != nested or block_at >= 0:
        raise newException(ValueError, &"Line of log opens block of no known field; got `{name}`.")
      block_at = blocks
      inc blocks
      inc cursor.at
      result.add (block_at, "", "")
      continue
    if cursor.at >= line.len or line[cursor.at] != ':':
      raise newException(ValueError, &"Field of log has no colon after its name; got `{name}`.")
    inc cursor.at
    cursor.skipSpaces
    let value = (if cursor.at < line.len and line[cursor.at] == '"': cursor.quoted
      else: cursor.word)
    result.add (block_at, name, value)
  if cursor.at != line.len:
    raise newException(ValueError, &"Line of log holds text after its closing brace; got `{line}`.")


func claimLine*(line: string): Claim =
  ## Read claim of one row that `lineClaim` writes, each field by its name; `ValueError` for row
  ##   that `fieldsLine` refuses, or that holds unknown field or value.
  for (block_at, name, value) in line.fieldsLine(OPENING_ROW, FIELD_NUMBER):
    if block_at >= 0:
      case name
      of "": result.number = some(Number())
      of "low": result.number.get.low = value.parseFloat
      of "median": result.number.get.median = value.parseFloat
      of "high": result.number.get.high = value.parseFloat
      of "outcome": result.number.get.outcome = some(value.parseFloat)
      else: raise newException(ValueError, &"Number of row holds unknown field; got `{name}`.")
      continue
    case name
    of "date": result.date = value
    of "delegate": result.delegate = value
    of "project": result.project = value
    of "kind": result.kind = value
    of "call": result.call = value
    of "model": result.model = value
    of "effort": result.effort = value
    of "text": result.text = value
    of "confidence": result.confidence = value.parseFloat
    of "state": result.state = NAMES_STATE.valueName(value)
    of "marker": result.marker = NAMES_MARKER.valueName(value)
    of "tokens": result.tokens = value.parseInt
    of "cost": result.cost = value.parseFloat
    of "address": result.address = value
    of "key": result.key = value
    of "result": result.result = value
    else: raise newException(ValueError, &"Row of log holds unknown field; got `{name}`.")


func priorLine*(line: string): Prior =
  ## Read prior of line that `linePrior` writes, each field by its name; `ValueError` for line that
  ##   `fieldsLine` refuses, or that holds unknown field or value.
  var tallies: seq[Tally]
  for (block_at, name, value) in line.fieldsLine(OPENING_PRIOR, FIELD_TALLIES):
    if block_at >= 0:
      if name.len == 0:
        tallies.add Tally()
        continue
      template tally: untyped = tallies[block_at]  # Alias; `let` would copy tally written.
      case name
      of "model": tally.model = value
      of "effort": tally.effort = value
      of "project": tally.project = value
      of "kind": tally.kind = value
      of "marker": tally.marker = NAMES_MARKER.valueName(value)
      of "band": tally.band = value.parseInt
      of "rows": tally.rows = value.parseInt
      of "count": tally.count = value.parseInt
      of "hits": tally.hits = value.parseInt
      of "hits_band": tally.hits_band = value.parseInt
      of "confidence": tally.confidence.add value.parseFloat
      of "score": tally.score.add value.parseFloat
      of "count_number": tally.count_number = value.parseInt
      of "score_number": tally.score_number.add value.parseFloat
      else: raise newException(ValueError, &"Tally of prior holds unknown field; got `{name}`.")
      continue
    case name
    of "date_first": result.date_first = value
    of "date_last": result.date_last = value
    of "keys": result.keys.add value.parseBiggestUInt
    else: raise newException(ValueError, &"Prior of log holds unknown field; got `{name}`.")
  result.tallies = tallies


func logText*(text: string): Log =
  ## Read prior and claim of each row of log text, in order; blank line and comment line, as header
  ##   of log, read as none. Prior reads wherever it stands, and log of several priors reads as one
  ##   whose keys hold keys of each other, as `union` joins two rolls of rows one of other.
  ##   `ValueError` where no prior holds keys of each other, and for two priors of same keys and
  ##   other tallies.
  var priors: seq[Prior]
  for line in text.splitLines:
    let row = line.strip
    if row.len == 0 or row[0] == MARK_COMMENT: continue
    if row.startsWith(OPENING_PRIOR): priors.add row.priorLine
    else: result.claims.add row.claimLine
  if priors.len == 0: return
  var widest = priors[0]
  for prior in priors:
    if prior.keys.len > widest.keys.len: widest = prior
  let keys = widest.keys.toHashSet
  for prior in priors:
    let is_other = prior.keys.len == widest.keys.len and prior != widest
    if is_other or not (prior.keys.toHashSet <= keys):
      raise newException(ValueError, "Two priors of log hold other rows, as merge of two rolls " &
        "that differ writes; got `" & $prior.keys.len & "` and `" & $widest.keys.len & "` key(s).")
  result.prior = some(widest)


func claimsCounted*(log: Log): seq[Claim] =
  ## Claims of rows of log that count, in order: each key once, in prior that names it (`hashKey`),
  ##   else in its first row; row of no key counts each time, since prior names none.
  var seen = (if log.prior.isSome: log.prior.get.keys.toHashSet else: initHashSet[uint64]())
  for claim in log.claims:
    if claim.key.len > 0:
      let hash = claim.key.hashKey
      if hash in seen: continue
      seen.incl hash
    result.add claim


func claimsLog*(text: string): seq[Claim] =
  ## Read claim of each row of log text, in order, as `logText` reads it, copies included.
  text.logText.claims


func rowsLog*(text: string): int =
  ## Count rows of log text: lines that open with `claims {`, as `lineClaim` writes each.
  text.splitLines.countIt(it.startsWith(OPENING_ROW))


func keysIn*(text: string): HashSet[string] =
  ## Read key of each row of log text: quoted value after first `key: "` of each line.
  ##   Quote inside string is escaped, so `key: "` stands only where field opens.
  for line in text.splitLines:
    let at = line.find(FIELD_KEY)
    if at < 0: continue
    let
      start = at + FIELD_KEY.len
      stop = line.find('"', start)
    if stop > start: result.incl line[start ..< stop]


func pathLog*(branch: string): string =
  ## Read path from root of log branch writes rows to; empty where branch is outside grammar, as
  ##   checkout of root curator, which keeps `main` detached, is.
  let parsed = branch.parseBranch
  if parsed.isNone: return ""
  case parsed.get.role
  of Role.Curator: PATH_LOG_CURATOR
  of Role.CuratorProject, Role.Contributor: parsed.get.prefix & FILE_LOG


func projectBranch*(branch: string): string =
  ## Read project rows of branch belong to: role string of branch inside grammar, else `curator`,
  ##   since root curator alone keeps checkout outside it (CURATOR.md, Branch and commits).
  let parsed = branch.parseBranch
  if parsed.isSome: parsed.get.nameRole else: CURATOR


proc logsTree*(root: string): seq[Log] =
  ## Read each log of claims that tree holds, in order of its path (`listPaths`), so figures join
  ##   log of each project (#964), and sum prior of each into one prior of repository (#1049).
  for path in root.listPaths:
    if path.extractFilename == FILE_LOG: result.add readFile(root / path).logText


proc claimsTree*(root: string): seq[Claim] =
  ## Read claim of each row that counts of each log of claims that tree holds, in order of its path
  ##   (`claimsCounted`).
  for log in root.logsTree: result.add log.claimsCounted


proc pathWaiting*(): string =
  ## Read path of file of rows that wait outside tree: under `KEY_CLAIMS` where set, else under
  ##   home.
  let root = getEnv(KEY_CLAIMS)
  (if root.len > 0: root else: getHomeDir() / DIRECTORY_CLAIMS) / FILE_WAITING


proc writeLines(path, text: string) =
  ## Add lines of text to end of file at path, opening it with `HEADER_LOG` where it is new;
  ##   whole file goes to path at once, through file beside it.
  var before = (if fileExists(path): readFile(path) else: HEADER_LOG)
  if before.len > 0 and not before.endsWith("\n"): before.add "\n"
  createDir(path.parentDir)
  let written = path & ".new"
  writeFile(written, before & text)
  moveFile(written, path)


proc appendClaims*(root, branch, waiting: string; claims: openArray[Claim]): int =
  ## Add each claim whose key neither log of branch nor file `waiting` holds to log of branch, else
  ##   to `waiting`; count claims written.
  let
    relative = branch.pathLog
    path = (if relative.len > 0: root / relative else: waiting)
  var
    known: HashSet[string]
    text = ""
  for file in [path, waiting]:
    if fileExists(file): known.incl readFile(file).keysIn
  for claim in claims:
    if claim.key in known: continue
    known.incl claim.key
    text.add claim.lineClaim & "\n"
    inc result
  if text.len > 0: writeLines(path, text)


proc moveClaims*(root, branch, waiting: string): tuple[moved: int, path: string] =
  ## Move each row of file `waiting` whose key log of branch lacks into that log, then remove
  ##   `waiting`; count rows moved, with path of log from root. Only root branch of curator takes
  ##   them, since their project is `curator`; path is empty for each other branch, and `waiting`
  ##   then stays.
  let parsed = branch.parseBranch
  if parsed.isNone or parsed.get.role != Role.Curator: return
  result.path = PATH_LOG_CURATOR
  if not fileExists(waiting): return
  let
    path = root / result.path
    known = (if fileExists(path): readFile(path).keysIn else: initHashSet[string]())
  var text = ""
  for line in readFile(waiting).splitLines:
    if not line.startsWith(FIELD_LOG & " "): continue
    let keys = line.keysIn
    if keys.len > 0 and keys.toSeq[0] in known: continue
    text.add line & "\n"
    inc result.moved
  if text.len > 0: writeLines(path, text)
  removeFile(waiting)


proc logStop*(root, branch, waiting: string; subagents: Subagents): int =
  ## Add claims of current model turn to log of branch, else to `waiting`, as `stop` does at each
  ##   stop; count claims written, or -1 where read or write fails. Error goes to stderr, so log
  ##   that cannot be written refuses no turn.
  try:
    appendClaims(
      root, branch, waiting,
      subagents.claimsTurn(readKinds(root), readEfforts(root), branch.projectBranch),
    )
  except IOError, OSError:
    stderr.writeLine "Log of claims is not written; got `" & getCurrentExceptionMsg() & "`."
    -1


func phraseKinds(kinds: openArray[string]): string =
  ## Render kinds as subject of commit of log names them: `reviewer`, `builder and the critic`,
  ##   or `builder, the critic and the resolver`.
  if kinds.len < 2: kinds.join
  else: kinds[0 ..< ^1].join(", the ") & " and the " & kinds[^1]


func messageClaims(path: string, kinds: openArray[string]): (string, string) =
  ## Render subject and body of commit of log at path that adds rows of kinds; scope is folder
  ##   holding log, as `audit` for log of root branch of curator.
  ##   Subject wider than `SUBJECT_MAX` names subagents, since commit hook refuses it otherwise.
  let
    opening = &"chore({path.parentDir.extractFilename}): log the claims of the "
    named = opening & kinds.phraseKinds
    subject = if named.runeLen <= SUBJECT_MAX: named else: opening & "subagents"
  (subject, "The `stop` hook commits the rows of each reflection, by the path of the log alone.")


proc isOperationGit(root: string): bool =
  ## Decide whether merge, cherry-pick, revert or rebase is in progress in checkout at root.
  for name in PATHS_OPERATION:
    let at = fieldsGit(root, ["rev-parse", "--path-format=absolute", "--git-path", name])[0].strip
    if fileExists(at) or dirExists(at): return true


proc commitClaims*(root, branch: string): bool =
  ## Commit log of claims of branch alone, by its path, where it holds rows that `HEAD` lacks and
  ##   lost none of its rows; true where commit lands, as `D1 a` of #1059 rules.
  ##   Branch outside grammar or detached checkout commits nothing, since `pathLog` gives none,
  ##     and neither does merge, cherry-pick, revert or rebase in progress: rows wait in tree.
  ##   Change staged for other path stays staged, since commit takes path alone (`--only`).
  ##   Commit hook reads message as any other, and commit stays local, so next push carries it.
  ##   Log that lost row commits nothing, since hand that removed it decides its commit. Log waits
##     too while last commit is `test`, so its `fix` comes right after it.
  ##   Failure of git commits nothing and raises nothing, so log that cannot commit refuses no
  ##     turn; error goes to stderr, and log that hook staged is unstaged again, so index stays.
  let relative = branch.pathLog
  if relative.len == 0 or not fileExists(root / relative): return false
  var is_added = false  # Hook staged log itself, so refused commit unstages it again.
  try:
    if root.isOperationGit: return false
    # Commit right after `test` waits, since its `fix` must follow it (CONTRIBUTOR.md, Tests
    #   are paramount); first stop after fix commits rows.
    let last = fieldsGit(root, ["log", "-1", "--format=%s"]).join.strip.parseSubject
    if last.isSome and last.get.kind == "test": return false
    let
      tracked = fieldsGit(root, ["ls-tree", "-z", "--name-only", "HEAD", "--", relative]).len > 0
      before = (if tracked: fieldsGit(root, ["show", "HEAD:" & relative]).join else: "")
      rows_before = before.splitLines.filterIt(it.startsWith(OPENING_ROW)).toHashSet
      rows_now = readFile(root / relative).splitLines.filterIt(it.startsWith(OPENING_ROW))
      added = rows_now.filterIt(it notin rows_before)
    if added.len == 0 or not (rows_before <= rows_now.toHashSet): return false
    let
      (subject, body) = relative.messageClaims(added.mapIt(it.claimLine.kind).deduplicate)
      is_staged = fieldsGit(root, ["diff", "--cached", "--name-only", "-z", "--", relative]).len > 0
    discard fieldsGit(root, ["add", "--", relative])
    is_added = not is_staged
    discard fieldsGit(
      root, ["commit", "--quiet", "--only", "-m", subject, "-m", body, "--", relative]
    )
    true
  except IOError, OSError, ValueError:
    stderr.writeLine "Log of claims is not committed; got `" & getCurrentExceptionMsg() & "`."
    if is_added:
      try: discard fieldsGit(root, ["reset", "--quiet", "--", relative])
      except IOError: discard
    false
