## Enforce Conventional Commits (Article XI.1): `type(scope): lowercase imperative summary`.
##   Types are data in `TYPES`; scope must be project name or `curator`. On project branch,
##   contributor or curator, scope must equal project, so log replays by project; curator
##   root branch accepts any valid scope, because rules propagation commits carry each
##   project's scope.
##   Merge commits are excluded upstream (`git log --no-merges`); reverts use type `revert`.
##   Subject is at most `SUBJECT_MAX` runes, same limit as line of source (XI.1). Branch
##     commits carry no ` (#N)` of squash merge, so check counts subject as author wrote it.
##   Regression rule is enforced here, not hoped for (CONTRIBUTOR.md, Tests are paramount):
##     commit immediately before every `fix` is `test` of same scope, one test to one fix with
##     nothing between them, since mistake earns test that fails before fix and passes after,
##     committed first, and log then reads as that ladder. Subjects arrive newest first, so
##     commit before element `i` is element `i + 1`.
##   Rejected: any earlier `test` of scope on branch, which one token test satisfies for every
##     later fix, so it measured order of kinds and nothing of pairing.
##   Change needing no new test is not `fix`: it is `refactor`, `chore` or `docs`. That is
##     escape, and it is honest one, since `fix` claims mistake was found.
##
##   Body (XI.4) is in sentence case, with one sentence to line: each line opens with capital,
##     digit or code span, ends with `.`, `!`, `?` or `:`, and holds no second sentence.
##     Trailer block, i.e. last paragraph of `Key: value` lines, is skipped, as is fenced or
##     indented code. List marker is read past, so list item is held as sentence too.
##   Record travels in `docs` commit of its own (CONTRIBUTOR.md, Branch): commit touching
##     `RECORD_FILE` and any file but Markdown together is finding.
##
##   Cost: imperative mood unverified; check sees lowercase first letter and no final period.
##   Cost: sentence boundary is `.`, `!` or `?` then space then capital outside code span, so
##     abbreviation such as `No. 3` reads as two sentences; STE writes such words out.
##   Cost: fix of mistake whose test already sits on `main` still needs test here, or another
##     type; check reads one branch, never whole history.
##   Cost: `!` breaking marker accepted after scope; footers pass unchecked.
##   Cost: subjects on `main` from before cap run to 136 runes; check reads one branch, so
##     history stays.

{.experimental: "strictFuncs".}

import std/[options, sequtils, strutils]
from std/unicode import runeLen
import ./[domains, findings, form]


type
  Subject* = object
    ## Define parsed commit subject.
    kind*: string  ## Commit type, member of `TYPES`.
    scope*: string  ## Project name or `curator`.
    summary*: string  ## Lowercase imperative summary without final period.

  Commit* = object
    ## Define one commit of branch as check reads it.
    subject*: string  ## First line of message.
    body*: string  ## Message after subject, trailers included.
    paths*: seq[string]  ## Paths commit touches.


const
  TYPES* = [
    "build", "chore", "ci", "docs", "feat", "fix", "perf", "refactor", "revert", "style", "test",
  ]
    ## Commit types accepted, alphabetical.
  SUBJECT_MAX* = LINE_MAX
    ## Widest commit subject allowed, in runes: same limit as line of source (Article XI.1).
  RECORD_FILE* = "PROVENANCE.md"
    ## Record that travels in commit of its own.
  TERMINALS = {'.', '!', '?', ':'}
    ## Characters body line may end on: sentence end, or colon opening list.


func parseSubject*(subject: string): Option[Subject] =
  ## Parse `type(scope)!?: summary`; `none` when any part breaks grammar.
  let
    open = subject.find('(')
    close = subject.find(')')
  if open <= 0 or close < open: return none(Subject)
  let
    kind = subject[0 ..< open]
    scope = subject[open + 1 ..< close]
  var rest = subject[close + 1 .. ^1]
  if rest.startsWith("!"): rest = rest[1 .. ^1]
  if not rest.startsWith(": "): return none(Subject)
  let
    summary = rest[2 .. ^1]
    is_summary = summary.len > 0 and summary[0] in {'a' .. 'z', '0' .. '9'} and
      not summary.endsWith(".")
  if kind notin TYPES or not (scope == CURATOR or scope.isProjectName) or not is_summary:
    return none(Subject)
  some(Subject(kind: kind, scope: scope, summary: summary))


func checkCommits*(branch: string, subjects: openArray[string]): seq[Finding] =
  ## Report subjects outside grammar and, on project branch, scopes not its project.
  let
    parsed_branch = branch.parseBranch
    expected =
      if parsed_branch.isSome and parsed_branch.get.role != Role.Curator:
        some(parsed_branch.get.scope)
      else:
        none(string)
  # Regression rule: `test` of same scope is commit immediately before `fix` it covers.
  for i in countdown(subjects.high, 0):
    let parsed = subjects[i].parseSubject
    if parsed.isNone or parsed.get.kind != "fix": continue
    let
      before = if i < subjects.high: subjects[i + 1].parseSubject else: none(Subject)
      is_paired = before.isSome and before.get.kind == "test" and
        before.get.scope == parsed.get.scope
    if not is_paired:
      result.add finding(
        "",
        0,
        "Fix needs `test(" & parsed.get.scope & ")` as commit immediately before it; mistake " &
          "earns test that fails before fix (CONTRIBUTOR.md, Tests are paramount); got `" &
          subjects[i] & "`.",
      )

  for s in subjects:
    let parsed = s.parseSubject
    if parsed.isNone:
      result.add finding(
        "",
        0,
        "Commit subject must match `type(scope): lowercase summary` without final period; got `" &
          s & "`.",
      )
    elif expected.isSome and parsed.get.scope != expected.get:
      result.add finding("", 0, "Commit scope must be `" & expected.get & "`; got `" & s & "`.")
    if s.runeLen > SUBJECT_MAX:
      result.add finding(
        "",
        0,
        "Commit subject exceeds " & $SUBJECT_MAX & " characters; got `" & $s.runeLen & "`.",
      )


func isTrailer(line: string): bool =
  ## Decide whether line is git trailer, i.e. `Key: value` with hyphenated key.
  let colon = line.find(": ")
  colon > 0 and line[0] in {'A' .. 'Z', 'a' .. 'z'} and
    line[0 ..< colon].allCharsInSet({'A' .. 'Z', 'a' .. 'z', '0' .. '9', '-'})


func sentenceLines(body: string): seq[string] =
  ## Read body lines held to XI.4: trailer block, blank, fenced and indented lines dropped.
  var paragraphs: seq[seq[string]] = @[@[]]
  for line in body.splitLines:
    if line.strip.len == 0:
      if paragraphs[^1].len > 0: paragraphs.add @[]
    else: paragraphs[^1].add line
  if paragraphs[^1].len == 0: paragraphs.setLen(paragraphs.len - 1)
  if paragraphs.len > 0 and paragraphs[^1].allIt(it.isTrailer):
    paragraphs.setLen(paragraphs.len - 1)
  var is_fence = false
  for paragraph in paragraphs:
    for line in paragraph:
      if line.strip.startsWith("```"):
        is_fence = not is_fence
        continue
      if is_fence or line.startsWith("    "): continue
      result.add line


func checkBody*(subject, body: string): seq[Finding] =
  ## Report body line outside sentence case, or holding other than one sentence (XI.4).
  for line in body.sentenceLines:
    var text = line.strip
    for marker in ["- ", "* "]:
      if text.startsWith(marker): text = text[marker.len .. ^1]
    var
      prose = ""
      is_span = false
    for c in text:
      if c == '`': is_span = not is_span
      elif not is_span: prose.add c
    let excerpt = (if text.len > 60: text[0 ..< 60] & "…" else: text)
    if text.len > 0 and text[0] notin {'A' .. 'Z', '0' .. '9', '`', '"'}:
      result.add finding(
        "",
        0,
        "Commit body is in sentence case (XI.4); got `" & excerpt & "` in `" & subject & "`.",
      )
    if text.len > 0 and text[^1] notin TERMINALS:
      result.add finding(
        "",
        0,
        "Commit body holds one sentence to line, and this one runs on (XI.4); got `" & excerpt &
          "` in `" & subject & "`.",
      )
    for k in 0 ..< prose.len - 2:
      if prose[k] in {'.', '!', '?'} and prose[k + 1] == ' ' and prose[k + 2] in {'A' .. 'Z'}:
        result.add finding(
          "",
          0,
          "Commit body holds one sentence to line (XI.4); got two in `" & excerpt & "` in `" &
            subject & "`.",
        )
        break


func checkRecordCommit*(subject: string, paths: openArray[string]): seq[Finding] =
  ## Report commit touching record and code together (CONTRIBUTOR.md, Branch).
  let
    has_record = paths.anyIt(it == RECORD_FILE or it.endsWith("/" & RECORD_FILE))
    code = paths.filterIt(not it.endsWith(".md"))
  if has_record and code.len > 0:
    result.add finding(
      "",
      0,
      "Record travels in `docs` commit of its own (CONTRIBUTOR.md, Branch); got `" & code[0] &
        "` beside it in `" & subject & "`.",
    )


func checkHistory*(branch: string, commits: openArray[Commit]): seq[Finding] =
  ## Run every commit check over branch's commits, newest first: subject, ladder, body, paths.
  result = checkCommits(branch, commits.mapIt(it.subject))
  for c in commits:
    result.add checkBody(c.subject, c.body)
    result.add checkRecordCommit(c.subject, c.paths)
