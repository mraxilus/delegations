## Replicate roll of log of claims into prior at its head, and cap of each log (#1049): each row
##   that stays, each figure roll leaves to last bit, each row prior holds once, guard against merge
##   that undoes roll, and finding of log past cap.
##   Laws over logs run on seeded random logs (`SAMPLES_LOG`, `SAMPLES_FIGURES`), and rule of row
##     that stays on each case of its small domain (`CASES_HELD`).
##   Figures of each sample come from same groups and lines that `linesTree` and `ratesTree`
##     print, read from text; one tree in git holds verb and both readers end to end.

{.experimental: "strictFuncs".}

import std/[algorithm, options, os, random, sequtils, sets, strutils, times, unittest]
import ../../src/[audit, claims_log, claims_prior, claims_scores, findings]
import ./fixtures


const  # TODO: Document.
  SAMPLES_LOG = 40  ## Random logs that law of rows prior holds reads.
  SAMPLES_FIGURES = 10
    ## Random logs that each law of figures reads: each takes 16 sets of fields at 4 states, and
    ##   Beta of each band of each group costs most of suite, about 0.3 s each log.
  ROWS_SAMPLE = 150  ## Rows of each random log.
  CASES_HELD = 375  ## Cases of rule of row that stays: 5 states, 5 others, 5 days, 3 prefixes.
  CASES_DAY = 2772  ## Cases of day in form of date: 6 years, 14 months from 0, 33 days from 0.
  DAYS_REAL = 366 + 365 + 366 + 366 + 365 + 365
    ## Of those, days calendar holds: 0000, 2000 and 2024 are leap.
  DAYS_LATEST = 365 + 366 + 365 + 365  ## Latest days that law of cutoff reads: 2023 to 2026.
  PROJECT = "contributor/bangu/rictadni"  ## Project whose log suite rolls.
  BRANCH = PROJECT & "/roll"  ## Branch that owns log of `PROJECT`.
  PATH_LOG = PROJECT & "/" & FILE_LOG  ## Log branch rolls.
  DAY_FIRST = "2026-08-01"  ## First day of random log.
  DAYS_SPAN = 120  ## Days random log spans.
  CUTOFF = "2026-10-01"  ## Cutoff of rule of row that stays.
  DELEGATES = ["s1", "s2", "s3", "s4"]  ## Sessions of random rows.
  MODELS = ["", "model-a", "model-b"]  ## Models of random rows; `stop` writes none.
  EFFORTS = ["", "low", "high", "max"]  ## Efforts of random rows.
  PROJECTS = ["curator", "curator/audit", PROJECT]  ## Projects of random rows.
  KINDS = ["", "reviewer", "critic", "builder"]  ## Kinds of random rows; empty for call of none.
  CONFIDENCES = [0.0, 0.2, 0.45, 0.5, 0.51, 0.55, 0.6, 0.65, 0.7, 0.8, 0.85, 0.9, 0.98, 0.99, 1.0]
    ## Confidences of random rows: each band, each side of 50%, and each bound of none.
  FIELDS_GROUP = [Field.Model, Field.Effort, Field.Project, Field.Kind]
    ## Fields each subset of which, with marker, groups figures; delegate is cost of roll.


proc dayAfter(first: string, days: int): string =
  ## Day `days` after first, as `2026-08-03`.
  (first.parse("yyyy-MM-dd", utc()) + initDuration(days = days)).format("yyyy-MM-dd")


proc claimRandom(at: int): Claim =
  ## Random row at position of log: fields of small sets, state of each kind, and number of tokens
  ##   or cost one row in four, whose outcome falls on either side of its percentiles.
  let
    delegate = DELEGATES.sample
    call = "toolu_" & $rand(0 .. 30)
    state = sample([State.Hit, State.Hit, State.Hit, State.Miss, State.Miss, State.Annulled,
      State.Waiting, State.Unspecified])
    marker = sample([Marker.Delegate, Marker.Delegate, Marker.Resolver, Marker.Unspecified])
    position = $rand(1 .. 5)
  result = Claim(
    date: DAY_FIRST.dayAfter(rand(0 ..< DAYS_SPAN)),
    delegate: delegate,
    project: PROJECTS.sample,
    kind: KINDS.sample,
    call: call,
    model: MODELS.sample,
    effort: EFFORTS.sample,
    text: "claim " & $at,
    confidence: CONFIDENCES.sample,
    state: state,
    marker: marker,
    address: delegate & "/u" & $at & "/1",
    key: [delegate, call, position, "STATE_" & ($state).toUpperAscii].join("/") &
      (if marker == Marker.Resolver: "/MARKER_RESOLVER" else: ""),
  )
  if rand(3) == 0:
    if rand(1) == 0:
      result.text = "tokens summed over its requests: 1,000,000, 3,000,000 and 7,000,000"
      result.number = some(Number(low: 1e6, median: 3e6, high: 7e6,
        outcome: some(rand(5e5 .. 2e7))))
    else:
      result.text = "Work: cost at list price: $0.15, $0.45 and $1.20"
      result.number = some(Number(low: 0.15, median: 0.45, high: 1.2,
        outcome: some(rand(0.05 .. 3.0))))
    result.confidence = sample([0.8, 0.9])


proc textRandom(rows = ROWS_SAMPLE): string =
  ## Text of random log of rows, as `stop` writes it: each key once, since `stop` writes no row
  ##   whose key log holds; row of key drawn before stays out.
  var keys: HashSet[string]
  result = HEADER_LOG
  for at in 0 ..< rows:
    let claim = claimRandom(at)
    if claim.key in keys: continue
    keys.incl claim.key
    result.add claim.lineClaim & "\n"


func linesPrinted(texts: openArray[string]): seq[string] =
  ## Key and figures to last bit of each group of logs of texts, for each subset of `FIELDS_GROUP`
  ##   with marker, then base rates, as `start` prints them; line that verb `figures` prints reads
  ##   key and figures alone (`linesFigures`).
  var
    claims: seq[Claim]
    tallies: seq[Tally]
  for text in texts:
    let log = text.logText
    claims.add log.claimsCounted
    if log.prior.isSome: tallies.add log.prior.get.tallies
  for mask in 0 ..< 1 shl FIELDS_GROUP.len:
    var fields = {Field.Marker}
    for i, field in FIELDS_GROUP:
      if (mask and (1 shl i)) != 0: fields.incl field
    result.add claims.groups(fields, tallies).mapIt(it.key & ": " & $it.figures)  # each bit
  result.add claims.linesBase(tallies)


func rowsHeld(text: string): int =
  ## Rows log text holds, in its rows and in tallies of its prior.
  let log = text.logText
  log.claims.len + (if log.prior.isSome: log.prior.get.tallies.mapIt(it.rows).foldl(a + b, 0)
    else: 0)


proc repoLog(rows: openArray[Claim]): string =
  ## Repository on `BRANCH` whose log of `PROJECT` holds rows, committed, with `union` for each log.
  result = repoTemp()
  discard result.git("checkout -q -b " & BRANCH)
  result.writeInto(".gitattributes", "claims.txtpb merge=union\n")
  result.writeInto(PATH_LOG, HEADER_LOG & rows.mapIt(it.lineClaim & "\n").join)
  discard result.git("add -A")
  discard result.git("commit -q -m 'chore(rictadni): log the claims'")


func rowDated(date: string, state = State.Hit, key = "s1/toolu_1/1/STATE_HIT"): Claim =
  ## Row of reviewer on day, in state, under key.
  Claim(date: date, delegate: key.split('/')[0], kind: "reviewer", confidence: 0.7, state: state,
    marker: Marker.Delegate, key: key)



suite "Rows that stay":
  test "row of cutoff or later, of no day, or of prefix named stays, and each other marked rolls":
    # Domain: each state, each other row of same claim, each kind of day, and each prefix.
    var cases = 0
    let others = [none(Claim), some(rowDated("2026-01-01", State.Hit, "s1/c/1/STATE_HIT")),
      some(rowDated("2026-01-01", State.Waiting, "s1/c/1/STATE_WAITING/MARKER_RESOLVER")),
      some(rowDated("2026-01-01", State.Miss, "s1/c/1/STATE_MISS/MARKER_RESOLVER")),
      some(rowDated(CUTOFF, State.Hit, "s1/c/1/STATE_HIT"))]  # mark of cutoff or later settles none
    for state in State:
      for k, other in others:
        for date in ["", "2026-13", "2026-09-30", CUTOFF, "2026-10-02"]:
          for prefixes in [newSeq[string](), @["s1/c"], @["s2"]]:
            inc cases
            var row = rowDated(date, state, "s1/c/1/STATE_" & ($state).toUpperAscii)
            row.marker = Marker.Delegate
            let
              claims = (if other.isSome: @[row, other.get] else: @[row])
              is_held = claims.isHeld(CUTOFF, prefixes)[0]
              is_settled = k == 1  # other row marks claim, by same marker, in other state
            if date.len != 10 or date >= CUTOFF or prefixes == @["s1/c"]:
              check is_held  # may still change, or age reads no way
            elif state == State.Waiting:
              check is_held == not is_settled  # waits until same marker marks claim again
            else:
              check not is_held  # marked, and older than cutoff
    check cases == CASES_HELD


  test "waiting claim of resolver settles by row of resolver alone":
    let
      waiting = rowDated("2026-01-01", State.Waiting, "s1/c/2/STATE_WAITING/MARKER_RESOLVER")
      by_resolver = rowDated("2026-01-02", State.Hit, "s1/c/2/STATE_HIT/MARKER_RESOLVER")
      by_delegate = rowDated("2026-01-02", State.Hit, "s1/c/2/STATE_HIT")
    check @[waiting, by_resolver].isHeld(CUTOFF, []) == @[false, false]
    check @[waiting, by_delegate].isHeld(CUTOFF, []) == @[true, false]
    check @[waiting, waiting].isHeld(CUTOFF, []) == @[true, true]  # wait twice settles none


  test "row whose day has form of date but names no day of calendar stays, as row of no day":
    # Case as found on #1049: `2026-13-45` reads as date, so it rolled, or raised as latest day.
    #   Then critic of #1049 found year `0000`, which pattern `yyyy` refuses, so roll raised.
    #   Domain: each month from 0 to 13 and each day from 0 to 32 of six years, three of them leap;
    #     `times.parse` with astronomical year `uuuu` is second method of which day calendar holds.
    var cases, real: int
    for year in ["0000", "0001", "2000", "2024", "2026", "2100"]:
      for month in 0 .. 13:
        for day in 0 .. 32:
          inc cases
          let date = year & "-" & ($month).align(2, '0') & "-" & ($day).align(2, '0')
          var is_real = true
          try: discard date.parse("uuuu-MM-dd", utc())
          except TimeParseError: is_real = false
          if is_real: inc real
          check @[rowDated(date)].isHeld("9999-12-31", []) == @[not is_real]  # rolls if real
    check cases == CASES_DAY
    check real == DAYS_REAL



suite "Prior":
  test "roll leaves each figure of each group but delegate, and each base rate, to last bit":
    # Done of #1049: figures that `koch figures` and `start` print stay same after roll, over each
    #   of three rolls of growing cutoff, beside log of other project that rolls none.
    randomize(1049)
    for sample in 0 ..< SAMPLES_FIGURES:
      let other = textRandom()
      var text = textRandom()
      let before = linesPrinted([text, other])
      for cutoff in ["2026-09-01", "2026-10-15", "2026-12-31"]:
        text = textRolled(text, cutoff, []).text
        check linesPrinted([text, other]) == before


  test "prior holds each rolled row once, and spans first and last day rolled":
    randomize(1051)
    for sample in 0 ..< SAMPLES_LOG:
      let first = textRandom()
      var
        text = first
        rolled = 0
        dates: seq[string]
      for cutoff in ["2026-09-01", "2026-10-15"]:
        let
          claims = text.logText.claims
          held = claims.isHeld(cutoff, ["s4"])
          (written, count) = textRolled(text, cutoff, ["s4"])
        for k, claim in claims:
          if not held[k]: dates.add claim.date
        rolled += count
        check count == held.countIt(not it)
        check written.logText.claims == toSeq(0 ..< claims.len).filterIt(held[it]).mapIt(claims[it])
        check written.rowsHeld == first.rowsHeld  # conservation: no row lost, none twice
        check written.logText.prior.get.tallies.mapIt(it.rows).foldl(a + b, 0) == rolled
        check written.logText.prior.get.date_first == dates.min
        check written.logText.prior.get.date_last == dates.max
        check written.splitLines.filterIt(it.startsWith(OPENING_ROW)).allIt(it in first)
        text = written


  test "prior stands after comments of head, and text stays as it is where no row rolls":
    let text = HEADER_LOG & [rowDated("2026-01-01"),
      rowDated("2026-10-09", key = "s2/c/1/STATE_HIT")].mapIt(it.lineClaim & "\n").join
    check textRolled(text, "", []) == (text, 0)  # each day is cutoff or later
    let (written, count) = textRolled(text, CUTOFF, [])
    check count == 1
    let lines = written.splitLines
    check lines[0 .. 1] == HEADER_LOG.splitLines[0 .. 1]
    check lines[2].startsWith(OPENING_PRIOR)
    check lines[3] == rowDated("2026-10-09", key = "s2/c/1/STATE_HIT").lineClaim
    check lines.len == 5 and lines[4] == ""
    check textRolled(written, CUTOFF, []) == (written, 0)  # roll again rolls none


  test "group by delegate reads rows prior holds as one delegate, `prior`, which is cost of roll":
    let
      text = HEADER_LOG & [rowDated("2026-01-01"),
        rowDated("2026-10-09", key = "s2/c/1/STATE_HIT")].mapIt(it.lineClaim & "\n").join
      log = textRolled(text, CUTOFF, []).text.logText
    check log.claims.groups({Field.Delegate}, log.prior.get.tallies).mapIt(it.key) ==
      @[DELEGATE_PRIOR, "s2"]


  test "line of prior is one function of rows it rolls, in any order of log and split into rolls":
    # Prior names no field of branch, its tallies sort, and each sum writes canonical partials; so
    #   two branches that roll same rows write same line, which git merges as one change (#1049).
    randomize(1052)
    for sample in 0 ..< SAMPLES_LOG:
      let text = textRandom()
      var rows = text.splitLines.filterIt(it.startsWith(OPENING_ROW))
      rows.shuffle
      let
        whole = textRolled(text, "2026-10-15", ["s4"]).text
        line = whole.splitLines.filterIt(it.startsWith(OPENING_PRIOR))
        reordered = textRolled(HEADER_LOG & rows.mapIt(it & "\n").join, "2026-10-15", ["s4"]).text
        split = textRolled(textRolled(text, "2026-09-01", ["s4"]).text, "2026-10-15", ["s4"]).text
      check line.len == 1
      check reordered.splitLines.filterIt(it.startsWith(OPENING_PRIOR)) == line
      check split.splitLines.filterIt(it.startsWith(OPENING_PRIOR)) == line


  test "prior names hash of key of each row it rolls, so rolls of other rows write other lines":
    # Two rolls of rows that differ, as of two branches, then never write one line, though their
    #   tallies agree; `union` keeps both lines, and reader refuses them (#1049).
    check ["", "a", "foobar"].mapIt(it.hashKey) ==
      @[0xcbf29ce484222325'u64, 0xaf63dc4c8601ec8c'u64, 0x85944171f73967e8'u64]  # FNV-1a, 64 bits
    randomize(1053)
    for sample in 0 ..< SAMPLES_LOG:
      let
        text = textRandom()
        claims = text.logText.claims
        held = claims.isHeld("2026-10-15", ["s4"])
        prior = textRolled(text, "2026-10-15", ["s4"]).text.logText.prior.get
        other = textRolled(text, "2026-10-15", []).text.logText.prior.get
        rolled = toSeq(0 ..< claims.len).filterIt(not held[it]).mapIt(claims[it].key.hashKey)
      check prior.keys == rolled.sorted.deduplicate(isSorted = true)  # ascending, each once
      check (prior.keys == other.keys) == (prior.linePrior == other.linePrior)
      check prior.keys != other.keys  # rows of `s4` roll too
    let keyless = Claim(date: "2026-01-01", kind: "reviewer", confidence: 0.7, state: State.Hit)
    check @[keyless].isHeld(CUTOFF, []) == @[true]  # prior names no row of no key


  test "copies of rows, before prior or after it, count none, and next roll drops each of them":
    # Merge by `union` can bring row back on each side of prior, or join one row twice (#1049).
    randomize(1055)
    for sample in 0 ..< SAMPLES_FIGURES:
      let
        text = textRandom()
        rows = text.splitLines.filterIt(it.startsWith(OPENING_ROW))
        rolled = textRolled(text, "2026-10-15", ["s4"]).text
      var lines = rolled.splitLines.filterIt(it.len > 0)
      for copy in 0 ..< 20: lines.insert(rows.sample, rand(2 .. lines.len))  # after head
      let
        copied = lines.mapIt(it & "\n").join
        again = textRolled(copied, "2026-10-15", ["s4"])
        keys = again.text.logText.claims.mapIt(it.key)
      check linesPrinted([copied]) == linesPrinted([text])
      check again.rolled == 0
      check again.text.splitLines.filterIt(it.startsWith(OPENING_PRIOR)) ==
        rolled.splitLines.filterIt(it.startsWith(OPENING_PRIOR))
      check keys.toHashSet == rolled.logText.claims.mapIt(it.key).toHashSet
      check keys.len == keys.toHashSet.len  # each key once
      check linesPrinted([again.text]) == linesPrinted([text])


  test "log of two priors reads as prior that holds rows of other, as `union` joins two rolls":
    # Two rolls of whole log at two cutoffs, each with each row that it keeps, as `union` joins
    #   them where each changed whole log (#1049).
    randomize(1054)
    for sample in 0 ..< SAMPLES_FIGURES:
      let
        text = textRandom()
        early = textRolled(text, "2026-09-01", []).text
        late = textRolled(text, "2026-10-15", []).text
        merged = HEADER_LOG & (early.splitLines & late.splitLines)
          .filterIt(it.len > 0 and it[0] != '#').mapIt(it & "\n").join
      check linesPrinted([merged]) == linesPrinted([text])
      check textRolled(merged, "2026-10-15", []) == (late, 0)  # one prior again, each row once


  test "roll writes one prior at head again, where merge put it after rows or twice":
    let
      row = rowDated("2026-06-01", key = "s1/c/1/STATE_HIT").lineClaim & "\n"
      prior = Prior(keys: @[7'u64],
        tallies: @[Tally(kind: "reviewer", marker: Marker.Delegate, rows: 1)]).linePrior & "\n"
    for text in [HEADER_LOG & row & prior, HEADER_LOG & prior & prior & row,
        HEADER_LOG & prior & row & prior]:
      check textRolled(text, "2026-05-01", []) == (HEADER_LOG & prior & row, 0)



suite "Roll of branch":
  test "verb rolls log of branch alone, before first day of month 30 days before its latest day":
    # Latest day 2026-03-01; 30 days before it is 2026-01-30, across month of 28 days, so cutoff is
    #   first day of that month, 2026-01-01, across year.
    let
      rows = @[rowDated("2025-12-30", key = "s1/c/1/STATE_HIT"),
        rowDated("2025-12-31", key = "s1/c/2/STATE_HIT"),
        rowDated("2026-01-01", key = "s1/c/3/STATE_HIT"),
        rowDated("2026-03-01", key = "s1/c/4/STATE_HIT")]
      root = repoLog(rows)
      before = (linesTree(root, "kind,effort,project,model"), ratesTree(root))
    check DAYS_OPEN == 30
    check rollLog(root, BRANCH, []) == (2, PATH_LOG)
    let log = readFile(root / PATH_LOG).logText
    check log.claims == rows[2 .. 3]
    check (log.prior.get.date_first, log.prior.get.date_last) == ("2025-12-30", "2025-12-31")
    check (linesTree(root, "kind,effort,project,model"), ratesTree(root)) == before
    removeDir(root)


  test "cutoff is first day of month that holds day 30 days before latest day, for each day":
    # Two branches whose latest days fall 30 days after one month take one cutoff, so they roll
    #   same rows. Domain: each latest day from 2023 to 2026, beside row of day calendar lacks.
    var
      day = "2023-01-01".parse("yyyy-MM-dd", utc())
      cases = 0
      before = ""
    while day.year <= 2026:
      let
        back = (day - initDuration(days = DAYS_OPEN)).format("yyyy-MM-dd")
        cutoff = dateCutoff([rowDated(day.format("yyyy-MM-dd")), rowDated("2026-13-45")])
      check cutoff[0 .. 7] == back[0 .. 7]  # month of day 30 days before
      check cutoff[8 .. 9] == "01"  # first day of that month
      check cutoff >= before  # cutoff never moves back as latest day moves on
      before = cutoff
      inc cases
      day = day + initDuration(days = 1)
    check cases == DAYS_LATEST
    check dateCutoff([rowDated(""), rowDated("2026-13-45")]) == ""  # no day that calendar holds


  test "two branches that roll same rows write one line of prior, which git merges as one change":
    # Case as found on #1049: cutoff counted back from latest day of each branch, and prior named
    #   `HEAD`, so two rolls of same rows wrote two lines, which `union` joined into two priors.
    #   Claim that waits settles on branch `a` alone, by its mark after cutoff, so it stays on each.
    let
      base = @[rowDated("2026-01-01", key = "s1/c/1/STATE_HIT"),
        rowDated("2026-01-02", key = "s1/c/2/STATE_HIT"),
        rowDated("2026-01-03", State.Waiting, "s1/c/5/STATE_WAITING"),
        rowDated("2026-05-10", key = "s1/c/3/STATE_HIT"),
        rowDated("2026-06-01", key = "s1/c/4/STATE_HIT")]
      root = repoLog(base)
    var lines: seq[string]
    for (name, rows) in [("a", @[rowDated("2026-06-05", key = "sa/c/1/STATE_HIT"),
        rowDated("2026-06-05", key = "s1/c/5/STATE_HIT")]),
        ("b", @[rowDated("2026-06-15", key = "sb/c/1/STATE_HIT")])]:
      let branch = PROJECT & "/" & name
      discard root.git("checkout -q -b " & branch & " " & BRANCH)
      writeFile(root / PATH_LOG, readFile(root / PATH_LOG) & rows.mapIt(it.lineClaim & "\n").join)
      discard root.git("commit -q -am 'chore(rictadni): log the claims'")
      check rollLog(root, branch, []).rolled == 2  # rows before 2026-05-01 that settle
      discard root.git("commit -q -am 'chore(rictadni): roll the log'")
      lines.add readFile(root / PATH_LOG).splitLines.filterIt(it.startsWith(OPENING_PRIOR))
    check lines.len == 2 and lines[0] == lines[1]
    discard root.git("merge -q " & PROJECT & "/a -m 'chore(rictadni): merge a'")
    let merged = readFile(root / PATH_LOG)
    check merged.splitLines.filterIt(it.startsWith(OPENING_PRIOR)) == lines[0 .. 0]
    check merged.logText.claims.mapIt(it.key).toHashSet == ["s1/c/5/STATE_WAITING",
      "s1/c/3/STATE_HIT", "s1/c/4/STATE_HIT", "sa/c/1/STATE_HIT", "s1/c/5/STATE_HIT",
      "sb/c/1/STATE_HIT"].toHashSet
    check merged.rowsLog == 6  # each row once
    removeDir(root)


  test "verb holds rows of prefix named, and refuses log that differs from `HEAD`":
    let
      rows = @[rowDated("2026-01-01", key = "s1/c/1/STATE_HIT"),
        rowDated("2026-01-01", key = "s2/c/1/STATE_HIT"), rowDated("2026-06-01")]
      root = repoLog(rows)
    writeFile(root / PATH_LOG, readFile(root / PATH_LOG) & rowDated("2026-06-02").lineClaim & "\n")
    expect IOError: discard rollLog(root, BRANCH, [])  # row no commit holds
    discard root.git("checkout -q -- " & PATH_LOG)
    check rollLog(root, BRANCH, ["s2"]) == (1, PATH_LOG)
    check readFile(root / PATH_LOG).logText.claims == rows[1 .. 2]
    removeDir(root)


  test "verb rolls log whose latest day by text names no day of calendar, and keeps its row":
    # Case as found on #1049: `2026-13-45` sorts after each real day, so `dateCutoff` parsed it,
    #   raised, and `koch roll` exited 1.
    let
      rows = @[rowDated("2026-01-01", key = "s1/c/1/STATE_HIT"),
        rowDated("2026-13-45", key = "s1/c/2/STATE_HIT"),
        rowDated("2026-06-01", key = "s1/c/3/STATE_HIT")]
      root = repoLog(rows)
    check rollLog(root, BRANCH, []) == (1, PATH_LOG)
    check readFile(root / PATH_LOG).logText.claims == rows[1 .. 2]
    removeDir(root)


  test "verb rolls log of first two years of calendar, and keeps rows of their last 30 days":
    # Case as found by critic of #1049: year `0000` raised, and `0001` formatted cutoff as year
    #   `0001`, so it rolled rows of last 30 days. Domain: year 0, year 1 past its first month,
    #   and first day of year 0, whose cutoff falls in year before it.
    for (days, rolled) in [
      (@["0000-01-01", "0000-06-01"], 1), (@["0001-01-01", "0001-01-20"], 0), (@["0000-01-01"], 0),
    ]:
      var rows: seq[Claim]
      for index, day in days: rows.add rowDated(day, key = "s1/c/" & $(index + 1) & "/STATE_HIT")
      let root = repoLog(rows)
      check rollLog(root, BRANCH, []) == (rolled, PATH_LOG)
      check readFile(root / PATH_LOG).logText.claims == rows[rolled .. ^1]
      removeDir(root)


  test "verb refuses branch outside grammar, and rolls none where log is absent":
    let root = repoLog([rowDated("2026-01-01")])
    expect IOError: discard rollLog(root, "HEAD", [])
    expect IOError: discard rollLog(root, "claude/roll", [])
    check rollLog(root, "contributor/bangu/ricysoho/roll", []) ==
      (0, "contributor/bangu/ricysoho/" & FILE_LOG)
    removeDir(root)


  test "row that merge by `union` brings back after roll counts once, in each order of merge":
    # Case as found on #1049: branch forked before rows that roll takes, with rows of its own,
    #   merges by `union` and brings each rolled row back, after prior or before it, by order of
    #   merge. After prior it counted twice, and before it reader refused log; guard that refused
    #   such roll read only branches of its own clone.
    let
      old = @[rowDated("2026-01-01", key = "s1/c/1/STATE_HIT"),
        rowDated("2026-01-02", key = "s1/c/2/STATE_HIT")]
      root = repoLog(old)
    discard root.git("branch stale")
    writeFile(root / PATH_LOG, readFile(root / PATH_LOG) &
      rowDated("2026-06-01", key = "s1/c/3/STATE_HIT").lineClaim & "\n")
    discard root.git("commit -q -am 'chore(rictadni): log the claims'")
    discard root.git("checkout -q stale")
    writeFile(root / PATH_LOG, readFile(root / PATH_LOG) &
      rowDated("2026-06-02", key = "s3/c/1/STATE_HIT").lineClaim & "\n")
    discard root.git("commit -q -am 'chore(rictadni): log the claims'")
    discard root.git("checkout -q -b plain " & BRANCH)
    discard root.git("merge -q stale -m 'chore(rictadni): merge stale'")
    let expected = (linesTree(root, "kind"), ratesTree(root))  # each row once, with no roll
    discard root.git("checkout -q " & BRANCH)
    check rollLog(root, BRANCH, []) == (2, PATH_LOG)
    discard root.git("commit -q -am 'chore(rictadni): roll the log'")
    for (name, ours, theirs) in [("after", BRANCH, "stale"), ("before", "stale", BRANCH)]:
      discard root.git("checkout -q -b " & name & " " & ours)
      discard root.git("merge -q " & theirs & " -m 'chore(rictadni): merge'")
      check readFile(root / PATH_LOG).rowsLog == 4  # 2 rolled rows back, beside 2 others
      check (linesTree(root, "kind"), ratesTree(root)) == expected
      check rollLog(root, BRANCH, []) == (0, PATH_LOG)  # next roll drops each copy
      check readFile(root / PATH_LOG).rowsLog == 2
      check readFile(root / PATH_LOG).splitLines[2].startsWith(OPENING_PRIOR)  # head again
      check (linesTree(root, "kind"), ratesTree(root)) == expected
      discard root.git("commit -q -am 'chore(rictadni): roll the log'")
    removeDir(root)


  test "row that `stop` writes again after roll counts once, as replay of reflection writes it":
    # Log holds no key that prior holds, so `stop` writes row again whose key roll took (#1049).
    let
      rows = @[rowDated("2026-01-01", key = "s1/c/1/STATE_HIT"),
        rowDated("2026-06-01", key = "s1/c/2/STATE_HIT")]
      root = repoLog(rows)
    check rollLog(root, BRANCH, []) == (1, PATH_LOG)
    discard root.git("commit -q -am 'chore(rictadni): roll the log'")
    let before = (linesTree(root, "kind"), ratesTree(root))
    check appendClaims(root, BRANCH, root / "waiting.txtpb", rows[0 .. 0]) == 1
    check (linesTree(root, "kind"), ratesTree(root)) == before
    discard root.git("commit -q -am 'chore(rictadni): log the claims'")
    check rollLog(root, BRANCH, []) == (0, PATH_LOG)
    check readFile(root / PATH_LOG).logText.claims == rows[1 .. 1]
    removeDir(root)



suite "Cap of log":
  test "log past 5,000 rows is finding at its path, and comment, blank and prior lines count none":
    # `D3 a` of #1049 (comment 7200192998): each log holds at most 5,000 rows.
    check ROWS_LOG == 5000
    let path = PATH_LOG
    for rows in [0, 1, ROWS_LOG - 1, ROWS_LOG, ROWS_LOG + 1, ROWS_LOG + 2]:
      let
        text = HEADER_LOG & Prior(date_first: "2026-01-01").linePrior & "\n\n" &
          (Claim(text: "a").lineClaim & "\n").repeat(rows)
        found = checkCap(path, text)
      check found.len == ord(rows > ROWS_LOG)
      if found.len > 0:
        check found[0].rule == "koch.log-length"
        check found[0].path == path
        check found[0].brief.contains("got `" & $rows & "`")


  test "static pass names log past its cap, and log at its cap passes":
    let
      path = DIRECTORY_ALPHA & "/" & FILE_LOG
      row = Claim(text: "a").lineClaim & "\n"
    check treeGood().with(entry(path, HEADER_LOG & row.repeat(ROWS_LOG))).auditTree.len == 0
    let found = treeGood().with(entry(path, HEADER_LOG & row.repeat(ROWS_LOG + 1))).auditTree
    check found.mapIt((it.path, it.rule)) == @[(path, "koch.log-length")]



suite "Form of log":
  test "merge by union of two rolls that hold different rows is finding at path of log":
    # Case as found on #1049: two branches each roll one log, and `union` joins their two priors,
    #   which reader refuses; `koch figures` then exits 1, start prints no base rate, and `koch
    #   check` passes. Each branch also holds old row of its own, so its roll takes other rows.
    let
      base = @[rowDated("2026-01-01", key = "s1/c/1/STATE_HIT"),
        rowDated("2026-01-02", key = "s1/c/2/STATE_HIT"),
        rowDated("2026-06-01", key = "s1/c/3/STATE_HIT")]
      root = repoLog(base)
    for (name, delegate) in [("a", "s2"), ("b", "s3")]:
      let branch = PROJECT & "/" & name
      discard root.git("checkout -q -b " & branch & " " & BRANCH)
      writeFile(root / PATH_LOG, readFile(root / PATH_LOG) &
        rowDated("2026-01-10", key = delegate & "/c/1/STATE_HIT").lineClaim & "\n" &
        rowDated("2026-06-02", key = delegate & "/c/2/STATE_HIT").lineClaim & "\n")
      discard root.git("commit -q -am 'chore(rictadni): log the claims'")
      check rollLog(root, branch, []).rolled == 3  # two old rows of base, and old row of branch
      discard root.git("commit -q -am 'chore(rictadni): roll the log'")
    discard root.git("merge -q " & PROJECT & "/a -m 'chore(rictadni): merge a'")
    let
      merged = readFile(root / PATH_LOG)
      path = DIRECTORY_ALPHA & "/" & FILE_LOG
    expect ValueError: discard merged.logText  # reader of figures and start refuses it
    check treeGood().with(entry(path, merged)).auditTree.mapIt((it.path, it.rule)) ==
      @[(path, "koch.log-form")]
    removeDir(root)


  test "each line that reader refuses is one finding at path of log, and log it reads is none":
    let
      path = DIRECTORY_ALPHA & "/" & FILE_LOG
      row = rowDated("2026-01-01").lineClaim & "\n"
      prior = Prior(date_first: "2025-12-01", date_last: "2025-12-02",
        tallies: @[Tally(kind: "reviewer", marker: Marker.Delegate, rows: 2)]).linePrior & "\n"
    # Empty log is finding of its own, of form of file (VIII.5).
    for text in [HEADER_LOG, HEADER_LOG & row, HEADER_LOG & prior & row]:
      check treeGood().with(entry(path, text)).auditTree.len == 0
    for line in ["rows { text: \"a\" }", "claims { dat: \"2026-11-20\" }",
        "claims { state: STATE_GOOD }", "claims { text: \"open }", "claims { } text: \"a\" }",
        "prior { tallies { hit: 1 } }", "prior { tallies { marker: MARKER_GOOD } }"]:
      let found = treeGood().with(entry(path, HEADER_LOG & row & line & "\n")).auditTree
      check found.mapIt((it.path, it.rule)) == @[(path, "koch.log-form")]
