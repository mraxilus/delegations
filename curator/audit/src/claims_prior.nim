## Roll rows of log of claims that can change no more into prior at its head, and hold each log to
##   its cap (#1049).
##   Role that writes log rolls it, as `D2 a` of #1049 rules (comment 7200192998): verb rolls log
##     that branch of checkout writes (`pathLog`), as `koch claims` moves rows into it, so no branch
##     rolls log of other project. Figures read prior of each log (`logsTree`), so priors of tree
##     sum to one prior of repository.
##   Prior holds one tally for each model, effort, project, kind, marker and band (`toTally`), and
##     each sum of tally is exact; so each figure of each group but `delegate` reads same after
##     roll, to last bit, since exact sum takes no order.
##   Rolled claim weighs as new one (`D4 a`); prior keeps first and last day it covers, for decay
##     of old claims that #1051 adds.
##   Row stays in log where it can still change, or where prior could name it no way (`isHeld`):
##     claim that waits, until row of log before cutoff marks same claim, by same marker, in other
##       state; and each mark of claim whose waiting row stays, so that rows of one claim roll
##       together, and later roll still finds mark that settles it;
##     row of no key, since prior names each row it holds by hash of its key;
##     row of cutoff or later: first day of month that holds day `DAYS_OPEN` before latest day of
##       log (`dateCutoff`), since its delegate may write its reflection again, or replay of its
##       transcript may feed `stop` again, and `stop` writes each row whose key log lacks;
##     row of no day, whose age reads no way, as day in form of date that calendar lacks, as
##       `2026-13-45` (`isDay`);
##     row whose key opens with prefix verb names, as delegate of study that still reads its rows.
##   Two branches that roll same rows write same line of prior, so git merges two rolls as one
##     change: cutoff falls on first day of month, and so does each branch whose latest day falls
##     in one span of month; rule of row that stays reads rows before cutoff alone; prior names no
##     field of branch, its keys and tallies sort, and each sum writes canonical partials. Rolls of
##     other rows write other lines, since prior names hash of key of each row it holds.
##   Verb refuses log that differs from `HEAD`, so commit before roll holds each row roll takes.
##   Verb refuses roll while branch stands that changed log since base it shares with `HEAD`, where
##     log of that base ends in row roll takes: merge by `union` then joins that row's hunk with
##     roll's, and brings each rolled row of base back, after prior or before it (`branchesStale`).
##   Cap: log past `ROWS_LOG` rows is finding at its path (`D3 a`), which its role clears by roll.
##   Form: log that reader of figures refuses is finding at its path too, so merge that writes it
##     fails branch that makes it, rather than `koch figures` and start of whole tree.
##
##   Rejected: one prior in `curator/audit` for whole tree, which would make curator roll rows of
##     contributor project, where curator writes only records (`D2 a`).
##   Rejected: cutoff `DAYS_OPEN` days before latest day, and prior that names `HEAD`: latest day
##     and `HEAD` differ on each branch, so two rolls of one log write two lines, which `union`
##     joins into two priors.
##   Cost: group by delegate reads prior as one delegate, `DELEGATE_PRIOR`, since it keeps no
##     session; rolled row stays in git, in each commit before roll that took it.
##   Cost: row stays from `DAYS_OPEN` days to `DAYS_OPEN` and month after its day, and two branches
##     whose latest days fall on each side of month roll at two cutoffs.
##   Cost: branch that other clone alone holds, or that no fetch brought, goes unread by guard.

{.experimental: "strictFuncs".}

import std/[algorithm, options, os, sequtils, sets, strformat, strutils, tables, times]
import ./[checks, claims_log, claims_scores, findings, tree]
from ./provenance import isDateIso


const
  ROWS_LOG* = 5000
    ## Rows log of claims may hold before its role rolls it, as `D3 a` of #1049 rules.
    ##   About 3 MB at 606 bytes of row, mean of log of audit project on #1049; start hook reads
    ##     each log at each start, so cap bounds that read as well as file.
    ##   Same number of lines as `LINES_RECORD` gives record.
  DAYS_OPEN* = 30
    ## Days before latest day of log whose month, and each later, stays at roll, since delegate of
    ##   its rows may still write.
    ##   Expected, and never measured past one case: on #1049, log of audit project holds rows of
    ##     one delegate from 2026-11-21 to 2026-11-27, which still works; 30 days holds four such.
  FORMAT_DATE = "yyyy-MM-dd"  ## Form of day of row, as `2026-11-20`.
  FORMAT_MONTH = "yyyy-MM"  ## Form of month of day, as `2026-11`.
  DAY_FIRST = "-01"  ## First day of month, after its form.
  MARK_KEY = '/'  ## Mark between parts of key of row.
  PART_STATE = 3  ## Index of state among parts of key: delegate, call, position, then state.


func claimMarked(key: string): string =
  ## Claim and marker key names: key without its state, as `d/c/1/MARKER_RESOLVER` for
  ##   `d/c/1/STATE_HIT/MARKER_RESOLVER`; whole key where it holds no state.
  let parts = key.split(MARK_KEY)
  if parts.len <= PART_STATE: return key
  (parts[0 ..< PART_STATE] & parts[PART_STATE + 1 .. ^1]).join($MARK_KEY)


func isDay(date: string): bool =
  ## Whether date names day that calendar holds: form of `isDateIso`, month from 1 to 12, and day
  ##   from 1 to last of its month, leap year counted; `2026-13-45` names none.
  if not date.isDateIso: return false
  let
    year = date[0 .. 3].parseInt
    month = date[5 .. 6].parseInt
    day = date[8 .. 9].parseInt
  month in 1 .. 12 and day in 1 .. getDaysInMonth(Month(month), year)


func isHeld*(claims: openArray[Claim]; cutoff: string; prefixes: openArray[string]): seq[bool] =
  ## Whether each row stays in log, since it can still change, or since prior could name it no way:
  ##   row of no key; row of no day that calendar holds (`isDay`), or of day `cutoff` or later; row
  ##   whose key opens with one of prefixes; claim that waits, until row before cutoff marks same
  ##   claim by same marker in other state; and each row of claim whose waiting row stays.
  ##   So rows of one claim roll together, in any order of log, and rows before cutoff decide.
  var
    own: seq[bool]  # Whether row stays for reason of its own.
    settled: HashSet[string]  # Claims and markers that row before cutoff marks.
    waiting: HashSet[string]  # Claims and markers whose waiting row stays.
  for claim in claims:
    own.add claim.key.len == 0 or not claim.date.isDay or claim.date >= cutoff or
      prefixes.anyIt(claim.key.startsWith(it))
    if claim.state notin {State.Waiting, State.Unspecified} and claim.date.isDay and
        claim.date < cutoff:
      settled.incl claim.key.claimMarked
  for k, claim in claims:
    if claim.state == State.Waiting and (own[k] or claim.key.claimMarked notin settled):
      waiting.incl claim.key.claimMarked
  for k, claim in claims: result.add own[k] or claim.key.claimMarked in waiting


func textRolled*(
  text, cutoff: string; prefixes: openArray[string]
): tuple[text: string, rolled: int] =
  ## Roll each row of log text that can change no more (`isHeld`) into its prior, with tally of each
  ##   such row added; text stays as it is where no row rolls.
  ##   Comment lines of head stay first, prior follows, then each other line that stays, as written.
  let
    log = text.logText
    held = log.claims.isHeld(cutoff, prefixes)
  result.rolled = held.countIt(not it)
  if result.rolled == 0: return (text, 0)

  # Sum tally of each rolled row into tally of prior whose fields and band agree, and name its key.
  var
    prior = log.prior.get(Prior())
    tallies = prior.tallies
    by_key: Table[(string, string, string, string, Marker, int), Tally]
    hashes = prior.keys.toHashSet
  for k, claim in log.claims:
    if held[k]: continue
    tallies.add claim.toTally
    hashes.incl claim.key.hashKey
  prior.keys = hashes.toSeq.sorted
  for tally in tallies:
    let key = (tally.model, tally.effort, tally.project, tally.kind, tally.marker, tally.band)
    if key in by_key: by_key[key].add tally
    else: by_key[key] = tally
  var keys = by_key.keys.toSeq
  keys.sort
  prior.tallies = keys.mapIt(by_key[it])
  for k, claim in log.claims:
    if held[k]: continue  # Rolled row names its day, since row of no day stays.
    if prior.date_first.len == 0 or claim.date < prior.date_first: prior.date_first = claim.date
    if claim.date > prior.date_last: prior.date_last = claim.date

  # Write head, prior, then each line that stays, in order, as `logText` reads them.
  var
    lines: seq[string]
    row = 0
    is_head = true
  for line in text.splitLines:
    let stripped = line.strip
    if stripped.len == 0: continue
    if is_head and stripped[0] != '#':
      lines.add prior.linePrior
      is_head = false
    if stripped.startsWith(OPENING_PRIOR): continue
    if stripped[0] == '#':
      lines.add line
      continue
    if held[row]: lines.add line
    inc row
  result.text = lines.join("\n") & "\n"


proc dateCutoff*(claims: openArray[Claim]): string =
  ## First day of month that holds day `DAYS_OPEN` before latest day of claims that calendar holds
  ##   (`isDay`), as `2026-10-01` for latest day `2026-11-27`; empty where no claim names such day,
  ##   so parse never meets day that calendar lacks.
  var latest = ""
  for claim in claims:
    if claim.date.isDay and claim.date > latest: latest = claim.date
  if latest.len == 0: return ""
  (latest.parse(FORMAT_DATE, utc()) - initDuration(days = DAYS_OPEN)).format(FORMAT_MONTH) &
      DAY_FIRST


proc branchesStale*(root, path: string; removed: HashSet[string]): seq[string] =
  ## Branches whose log at path changed since base they share with `HEAD`, where log of that base
  ##   ends in line roll removes: merge by `union` joins hunk of their rows with hunk of roll, and
  ##   brings rows of base back.
  ##   Each local and remote branch is read, as fetch last left it; branch of no shared base reads
  ##     as none.
  let names = fieldsGit(root, ["for-each-ref", "--format=%(refname:short)%00", "refs/heads",
    "refs/remotes"])
  for name in names.mapIt(it.strip):
    if name.len == 0 or name.endsWith("/HEAD"): continue
    var base = ""
    try: base = fieldsGit(root, ["merge-base", "HEAD", name])[0].strip
    except IOError: continue
    let text_base = textAt(root, base, path)
    if text_base == textAt(root, name, path): continue
    let lines = text_base.splitLines.filterIt(it.strip.len > 0)
    if lines.len > 0 and lines[^1].strip in removed: result.add name


proc rollLog*(
  root, branch: string; prefixes: openArray[string]
): tuple[rolled: int, path: string] =
  ## Roll each row of log of branch that can change no more into its prior (`textRolled`), before
  ##   cutoff of its rows (`dateCutoff`); count rows rolled, with path of log from root. `IOError`
  ##   for branch outside grammar, for log that differs from `HEAD`, and for roll that merge of
  ##   other branch undoes.
  result.path = branch.pathLog
  if result.path.len == 0:
    raise newException(IOError, &"Branch outside grammar owns no log of claims; got `{branch}`.")
  if not fileExists(root / result.path): return
  if fieldsGit(root, ["status", "--porcelain", "-z", "--", result.path]).len > 0:
    raise newException(IOError, "Log differs from `HEAD`, so no commit holds each row that roll " &
      &"takes; commit it first; got `{result.path}`.")
  let
    text = readFile(root / result.path)
    (written, rolled) = textRolled(text, text.claimsLog.dateCutoff, prefixes)
  if rolled == 0: return
  let
    removed = text.splitLines.mapIt(it.strip).toHashSet -
        written.splitLines.mapIt(it.strip).toHashSet
    stale = branchesStale(root, result.path, removed)
  if stale.len > 0:
    raise newException(IOError, "Branch changed log since its base, whose last row roll takes, " &
      "so merge by `union` would bring rolled rows back; merge it, or merge `main` into it, " &
      &"first; got `{stale.join(\", \")}`.")
  writeFile(root / result.path, written)
  result.rolled = rolled


func checkCap*(path, source: string): seq[Finding] =
  ## Report log of claims past `ROWS_LOG` rows (`D3 a` of #1049), at its path.
  let count = source.rowsLog
  if count > ROWS_LOG:
    result.add finding(
      path,
      0,
      Check.LengthLog,
      "Log of claims over " & $ROWS_LOG & " rows (#1049); got `" & $count & "`.",
      expected = some("at most " & $ROWS_LOG),
      help = "roll it on branch of its project: `nim r koch roll`",
    )


func checkFormLog*(path, source: string): seq[Finding] =
  ## Report log of claims that reader of figures and start refuses (`logText`), at its path, so
  ##   merge that joins two rolls fails branch that makes it, and never tree that reads it later.
  try: discard source.logText
  except ValueError as error:
    result.add finding(
      path,
      0,
      Check.FormLog,
      "Log of claims reads no way (#1049); got `" & error.msg & "`.",
      help = "mend line it names; where merge joined two rolls, revert one, merge, and roll again",
    )
