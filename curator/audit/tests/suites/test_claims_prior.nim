## Replicate roll of log of claims into prior at its head, and cap of each log (#1049): each row
##   that stays, each figure roll leaves to last bit, each row prior holds once, guard against merge
##   that undoes roll, and finding of log past cap.
##   Laws over logs run on seeded random logs (`SAMPLES_LOG`, `SAMPLES_FIGURES`), and rule of row
##     that stays on each case of its small domain (`CASES_HELD`).
##   Figures of each sample come from same groups and lines that `linesTree` and `ratesTree`
##     print, read from text; one tree in git holds verb and both readers end to end.

{.experimental: "strictFuncs".}

import std/[options, os, random, sequtils, sets, strutils, times, unittest]
import ../../src/[audit, claims_log, claims_prior, claims_scores, findings]
import ./fixtures


const
  SAMPLES_LOG = 40  ## Random logs that law of rows prior holds reads.
  SAMPLES_FIGURES = 10
    ## Random logs that law of figures reads: each takes 16 sets of fields at 4 states, and Beta of
    ##   each band of each group costs most of suite, about 0.3 s each log.
  ROWS_SAMPLE = 150  ## Rows of each random log.
  CASES_HELD = 300  ## Cases of rule of row that stays: 5 states, 4 others, 5 days, 3 prefixes.
  CASES_DAY = 1848  ## Cases of day in form of date: 4 years, 14 months from 0, 33 days from 0.
  DAYS_REAL = 366 + 366 + 365 + 365  ## Of those, days calendar holds: 2000 and 2024 are leap.
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
  ## Text of random log of rows, as `stop` writes it.
  HEADER_LOG & toSeq(0 ..< rows).mapIt(claimRandom(it).lineClaim & "\n").join


func linesPrinted(texts: openArray[string]): seq[string] =
  ## Key and figures to last bit of each group of logs of texts, for each subset of `FIELDS_GROUP`
  ##   with marker, then base rates, as `start` prints them; line that verb `figures` prints reads
  ##   key and figures alone (`linesFigures`).
  var
    claims: seq[Claim]
    tallies: seq[Tally]
  for text in texts:
    let log = text.logText
    claims.add log.claims
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
      some(rowDated("2026-01-01", State.Miss, "s1/c/1/STATE_MISS/MARKER_RESOLVER"))]
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
    #   Domain: each month from 0 to 13 and each day from 0 to 32 of four years, two of them leap;
    #     `times.parse` is second method of which day calendar holds.
    var cases, real: int
    for year in ["2000", "2024", "2026", "2100"]:
      for month in 0 .. 13:
        for day in 0 .. 32:
          inc cases
          let date = year & "-" & ($month).align(2, '0') & "-" & ($day).align(2, '0')
          var is_real = true
          try: discard date.parse("yyyy-MM-dd", utc())
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
      for (cutoff, commit) in [("2026-09-01", "c1"), ("2026-10-15", "c2"), ("2026-12-31", "c3")]:
        text = textRolled(text, commit, cutoff, []).text
        check linesPrinted([text, other]) == before


  test "prior holds each rolled row once, names last commit, and spans first and last day rolled":
    randomize(1051)
    for sample in 0 ..< SAMPLES_LOG:
      let first = textRandom()
      var
        text = first
        rolled = 0
        dates: seq[string]
      for (cutoff, commit) in [("2026-09-01", "c1"), ("2026-10-15", "c2")]:
        let
          claims = text.logText.claims
          held = claims.isHeld(cutoff, ["s4"])
          (written, count) = textRolled(text, commit, cutoff, ["s4"])
        for k, claim in claims:
          if not held[k]: dates.add claim.date
        rolled += count
        check count == held.countIt(not it)
        check written.logText.claims == toSeq(0 ..< claims.len).filterIt(held[it]).mapIt(claims[it])
        check written.rowsHeld == first.rowsHeld  # conservation: no row lost, none twice
        check written.logText.prior.get.tallies.mapIt(it.rows).foldl(a + b, 0) == rolled
        check written.logText.prior.get.commit == commit
        check written.logText.prior.get.date_first == dates.min
        check written.logText.prior.get.date_last == dates.max
        check written.splitLines.filterIt(it.startsWith(OPENING_ROW)).allIt(it in first)
        text = written


  test "prior stands after comments of head, and text stays as it is where no row rolls":
    let text = HEADER_LOG & [rowDated("2026-01-01"),
      rowDated("2026-10-09", key = "s2/c/1/STATE_HIT")].mapIt(it.lineClaim & "\n").join
    check textRolled(text, "c1", "", []) == (text, 0)  # each day is cutoff or later
    let (written, count) = textRolled(text, "c1", CUTOFF, [])
    check count == 1
    let lines = written.splitLines
    check lines[0 .. 1] == HEADER_LOG.splitLines[0 .. 1]
    check lines[2].startsWith(OPENING_PRIOR)
    check lines[3] == rowDated("2026-10-09", key = "s2/c/1/STATE_HIT").lineClaim
    check lines.len == 5 and lines[4] == ""
    check textRolled(written, "c2", CUTOFF, []) == (written, 0)  # roll again rolls none


  test "group by delegate reads rows prior holds as one delegate, `prior`, which is cost of roll":
    let
      text = HEADER_LOG & [rowDated("2026-01-01"),
        rowDated("2026-10-09", key = "s2/c/1/STATE_HIT")].mapIt(it.lineClaim & "\n").join
      log = textRolled(text, "c1", CUTOFF, []).text.logText
    check log.claims.groups({Field.Delegate}, log.prior.get.tallies).mapIt(it.key) ==
      @[DELEGATE_PRIOR, "s2"]



suite "Roll of branch":
  test "verb rolls log of branch alone, names `HEAD`, and keeps last days of log":
    # Latest day 2026-03-01, so cutoff is 30 days before, 2026-01-30, across month of 28 days.
    let
      rows = @[rowDated("2026-01-28", key = "s1/c/1/STATE_HIT"),
        rowDated("2026-01-29", key = "s1/c/2/STATE_HIT"),
        rowDated("2026-01-30", key = "s1/c/3/STATE_HIT"),
        rowDated("2026-03-01", key = "s1/c/4/STATE_HIT")]
      root = repoLog(rows)
      head = root.git("rev-parse HEAD").strip
      before = (linesTree(root, "kind,effort,project,model"), ratesTree(root))
    check DAYS_OPEN == 30
    check rollLog(root, BRANCH, []) == (2, PATH_LOG)
    let log = readFile(root / PATH_LOG).logText
    check log.claims == rows[2 .. 3]
    check log.prior.get.commit == head
    check (log.prior.get.date_first, log.prior.get.date_last) == ("2026-01-28", "2026-01-29")
    check (linesTree(root, "kind,effort,project,model"), ratesTree(root)) == before
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


  test "verb refuses branch outside grammar, and rolls none where log is absent":
    let root = repoLog([rowDated("2026-01-01")])
    expect IOError: discard rollLog(root, "HEAD", [])
    expect IOError: discard rollLog(root, "claude/roll", [])
    check rollLog(root, "contributor/bangu/ricysoho/roll", []) ==
      (0, "contributor/bangu/ricysoho/" & FILE_LOG)
    removeDir(root)


  test "verb refuses roll while branch stands whose base log ends in row roll takes":
    # Case as found on #1049, by hand with git 2.43.0: branch forked before rows that roll takes,
    #   and with rows of its own, merges by `union` and brings each rolled row of its base back.
    let
      old = @[rowDated("2026-01-01", key = "s1/c/1/STATE_HIT"),
        rowDated("2026-01-02", key = "s1/c/2/STATE_HIT")]
      root = repoLog(old)
    discard root.git("branch stale")
    discard root.git("branch idle")
    writeFile(root / PATH_LOG, readFile(root / PATH_LOG) &
      rowDated("2026-06-01", key = "s1/c/3/STATE_HIT").lineClaim & "\n")
    discard root.git("commit -q -am 'chore(rictadni): log the claims'")
    discard root.git("branch fresh")
    for (branch, key) in [("stale", "s3/c/1/STATE_HIT"), ("fresh", "s4/c/1/STATE_HIT")]:
      discard root.git("checkout -q " & branch)
      writeFile(root / PATH_LOG, readFile(root / PATH_LOG) & rowDated("2026-06-02", key = key)
        .lineClaim & "\n")
      discard root.git("commit -q -am 'chore(rictadni): log the claims'")
    discard root.git("checkout -q " & BRANCH)
    let removed = old.mapIt(it.lineClaim).toHashSet
    check branchesStale(root, PATH_LOG, removed) == @["stale"]  # idle changed no log
    expect IOError: discard rollLog(root, BRANCH, [])
    check readFile(root / PATH_LOG).logText.prior.isNone  # refused roll writes nothing
    # Merge of stale branch after roll is what guard refuses: its rows come back, beside prior.
    #   Cutoff is that of verb: 30 days before latest day, 2026-06-01.
    let rolled = textRolled(readFile(root / PATH_LOG), "c1", "2026-05-02", []).text
    writeFile(root / PATH_LOG, rolled)
    discard root.git("commit -q -am 'chore(rictadni): roll the log'")
    discard root.git("merge -q stale -m 'chore(rictadni): merge stale'")
    check readFile(root / PATH_LOG).rowsLog == 4  # 2 rolled rows back, beside 2 others
    check readFile(root / PATH_LOG).rowsHeld == 6  # 4 rows, and 2 of them twice
    discard root.git("reset -q --hard HEAD~1")
    discard root.git("merge -q fresh -m 'chore(rictadni): merge fresh'")
    check readFile(root / PATH_LOG).rowsHeld == 4  # fresh merges clean, each row once
    removeDir(root)



suite "Cap of log":
  test "log past 5,000 rows is finding at its path, and comment, blank and prior lines count none":
    # `D3 a` of #1049 (comment 7200192998): each log holds at most 5,000 rows.
    check ROWS_LOG == 5000
    let path = PATH_LOG
    for rows in [0, 1, ROWS_LOG - 1, ROWS_LOG, ROWS_LOG + 1, ROWS_LOG + 2]:
      let
        text = HEADER_LOG & Prior(commit: "c1").linePrior & "\n\n" &
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
