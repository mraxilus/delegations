## Hold pull request's opening role line and its labels to role its branch names, its title to
##   commit grammar, and its body to form of template.
##   Role line says who speaks; label says whose work it is. On pull request both are branch's
##     own role, since branch grammar names role and delegate on it writes under that role. So
##     one string, derived by `parseBranch`, answers for both, and check is equality rather
##     than presence.
##   Inputs arrive through environment: branch, title and body from event payload, label names
##     from API, read after job `label` of `role.yml` adds role label branch names.
##   Title holds grammar, scope and width of commit subject (`checkCommits`), since merge commit
##     takes title as its subject and `main` takes no rewrite after (pull request template).
##     `edited` event runs check again on rename.
##   Role line may stand below block harness writes above it, as Architect ruled on #845: lines
##     of block take shapes of one entry of `HARNESSES`, whole and in order. Shape is known by
##     its two ends, never by harness's words, so harness changing its words changes no rule.
##     Harness writing nothing above role line needs no entry; one writing block no entry
##     lists fails on its first pull request, and finding quotes each line above role line, so
##     curator adds its entry.
##   Body holds sections of template once each and in order, as Architect shaped it on #845:
##     What, Why, Evidence and Next steps. Each opens with summary of one to three sentences,
##     then its points; at most `CHARACTERS_BODY` characters show while each fold is closed,
##     each link counted by its text, so Architect skims whole of what merges. `body` hook
##     holds same rules before post lands by calling `checkBodyPull`, since hook holds no rule
##     of its own (`hooks.nim`).
##   Every open body is read by same rules at its next event, as Architect ruled on #845: no
##     cutoff by date or number.
##   `ledger.yml` reads same two facts daily over open items, which samples rather than gates:
##     pull request living half hour is almost never open when it runs, and it reports after
##     merge rather than before.
##
##   Role and title of branch outside grammar report nothing here: `check-scope` already fails
##     it, and expected role cannot be derived from name grammar rejects.
##   Cost: issue carries no branch, so which label it needs is judgement, and stays ledger's.
##   Cost: comment is unreachable, and is what remains of CONTRIBUTOR.md's first carried rule.
##   Cost: labels are searched for expected string rather than compared whole, since label is
##     added when work hands across and never removed.
##   Cost: stray lines in shapes of listed block pass above role line, as block itself does.
##   Cost: marker with no credit line fails, as block that is not whole.
##   Cost: italic line written in asterisks is other shape, so harness turning to it fails until
##     its entry changes.
##   Cost: marks of body are read outside code by their text alone: fold marked `open` shows its
##     points, and they count as folded; last italic line below `---` rule counts nothing,
##     whoever wrote it.
##   Cost: link written as reference counts in full, and so do link and code span wrapped over
##     line end, since `markdown.nim` reads both inside one line.

{.experimental: "strictFuncs".}

import std/[options, sequtils, strutils, unicode]
import ./[commits, domains, english, findings, markdown]


type  # TODO: Document.
  Shape = tuple[opening, closing: string]
    ## Define shape of one line harness writes above role line, known by its two ends alone.

  Harness = object  ## Define block one harness writes above role line of pull request it opens.
    name {.requiresInit.}: string  ## Harness, as its own documents name it.
    shapes {.requiresInit.}: seq[Shape]  ## Shape of each line of block, in order.


const  # TODO: Document.
  KEY_ROLE* = "**Role:**"  ## Opening of role line, bold as every prompt and template writes it.
  COMMENT_OPEN = "<!--"  ## Opening of HTML comment, which unfilled template carries after key.
  COMMENT_CLOSE = "-->"  ## Closing of HTML comment.
  SHAPE_COMMENT: Shape = (opening: COMMENT_OPEN, closing: COMMENT_CLOSE)
    ## Line of HTML comment, which renders as nothing.
  SHAPE_ITALIC: Shape = (opening: "_", closing: "_")  ## Line in italics, by underscores.
  HARNESSES = [
    Harness(name: "Claude Code", shapes: @[SHAPE_COMMENT, SHAPE_ITALIC]),
  ]
    ## Block each harness writes above role line, one entry for each harness writing one.
    ##   Claude Code writes marker naming who asked, then credit line linking its thread.
  ECHO_MAX* = 72
    ## Runes echoed back from opening line: it is whatever somebody typed, and body opening
    ## with whole paragraph would otherwise print that paragraph as finding.

  # Lines above role line finding quotes at most: twice block of longest listed harness, so
  #   block of new harness shows whole, and body whose role line stands low prints no whole
  #   opening.
  LINES_QUOTED* = block:
    var longest = 0
    for harness in HARNESSES: longest = max(longest, harness.shapes.len)
    2 * longest
  HEADINGS_PULL = ["## What", "## Why", "## Evidence", "## Next steps"]
    ## Sections of pull request body, in order template gives them.
  SENTENCES_SUMMARY = 3  ## Sentences summary opening each section holds at most.
  CHARACTERS_BODY = 2500
    ## Characters body shows at most while each fold is closed, as Architect set on #845.
  TAG_FOLD = "<details"  ## Opening of tag of fold, before `>` or attribute; read lowercased.
  TAG_FOLD_CLOSE = "</details>"  ## Tag closing fold.
  TAG_SUMMARY = "<summary"  ## Opening of tag of summary of fold, which shows while fold is closed.
  TAG_SUMMARY_CLOSE = "</summary>"  ## Tag closing summary of fold.
  RULE_FOOTER = "---"  ## Rule line over footer proxy appends.


func shortened*(line: string): string =
  ## Cut line to `ECHO_MAX` runes, marking cut where one was made.
  if line.runeLen <= ECHO_MAX: line else: line.runeSubStr(0, ECHO_MAX) & "…"


func isShaped(line: string, shape: Shape): bool =
  ## Decide whether stripped line takes shape, i.e. opens with one end and closes with other.
  line.len >= shape.opening.len + shape.closing.len and line.startsWith(shape.opening) and
    line.endsWith(shape.closing)


func linesOpening(body: string): seq[string] =
  ## Read each non-blank line of body outside fenced code, stripped, up to first role line and
  ##   with it; every such line where none stands.
  for line in body.fencedOut.splitLines:
    let s = line.strip
    if s.len == 0: continue
    result.add s
    if s.startsWith(KEY_ROLE): return


func lenBlock(lines: openArray[string]): int =
  ## Count opening lines that block of first listed harness writing them takes, whole and in
  ##   order; 0 where block of none opens lines.
  for harness in HARNESSES:
    if lines.len < harness.shapes.len: continue
    var is_block = true
    for i, shape in harness.shapes: is_block = is_block and lines[i].isShaped(shape)
    if is_block: return harness.shapes.len
  0


func lineRole*(body: string): string =
  ## Read opening line of body: first non-blank line outside fenced code below block of listed
  ##   harness, with trailing HTML comment dropped.
  ##   Unfilled template opens `**Role:** <!-- curator, or ... -->`, which then reads as key
  ##     alone and fails equality below, rather than passing as line naming no role.
  ##   Block is passed only whole and in its place, so lone marker, lone credit line or any
  ##     other comment reads as opening, and fails equality below.
  let
    lines = body.linesOpening
    at = lines.lenBlock
  if at >= lines.len: return ""
  let open = lines[at].find(COMMENT_OPEN)
  if open < 0: lines[at] else: lines[at][0 ..< open].strip


func openingQuoted*(body: string): string =
  ## Quote what finding on opening of body names, each line in backticks: each line above first
  ##   role line where line no listed block holds stands there, else opening line alone.
  ##   Quote holds role line and at most `LINES_QUOTED` lines above it, each cut to `ECHO_MAX`
  ##     runes, since body is whatever somebody typed.
  let lines = body.linesOpening
  if lines.len <= lines.lenBlock + 1 or not lines[^1].startsWith(KEY_ROLE):
    return "`" & body.lineRole.shortened & "`"
  # Quote each line above role line, since one of them is no line of listed block.
  let above = lines[0 ..< min(lines.high, LINES_QUOTED)].mapIt("`" & it.shortened & "`")
  above.join(", ") & (if lines.high > LINES_QUOTED: ", …" else: "") & " above `" &
    lines[^1].shortened & "`"


func checkRole*(branch, body: string; labels: openArray[string]): seq[Finding] =
  ## Report pull request whose opening line or labels do not name role its branch names.
  let parsed = branch.parseBranch
  if parsed.isNone: return
  let expected = parsed.get.nameRole
  if body.lineRole != KEY_ROLE & " " & expected:
    result.add finding(
      "",
      0,
      Check.LineRole,
      "Pull request must open with `" & KEY_ROLE & " " & expected &
        "`, which its branch names; got " & body.openingQuoted & ".",
      expected = some(KEY_ROLE & " " & expected),
    )
  if expected notin labels:
    result.add finding(
      "",
      0,
      Check.LabelRole,
      "Pull request must carry label `" & expected & "`, which job `label` of `role.yml` adds " &
        "from its branch; got `" & labels.join(", ") & "`.",
    )


func checkTitle*(branch, title: string): seq[Finding] =
  ## Report pull request title outside commit grammar, or with scope its branch does not carry.
  if branch.parseBranch.isNone: return
  let
    parsed = title.parseSubject
    scope = branch.scopeRequired
  if parsed.isNone:
    result.add finding(
      "",
      0,
      Check.TitlePull,
      "Pull request title must match `type(scope): lowercase summary` without final period, " &
        "since merge commit takes it as subject; got `" & title.shortened & "`.",
    )
  elif scope.isSome and parsed.get.scope != scope.get:
    result.add finding(
      "",
      0,
      Check.ScopeTitle,
      "Pull request title scope must be `" & scope.get & "`; got `" & title.shortened & "`.",
    )
  if title.runeLen > SUBJECT_MAX:
    result.add finding(
      "",
      0,
      Check.WidthTitle,
      "Pull request title exceeds " & $SUBJECT_MAX & " characters; got `" & $title.runeLen & "`.",
      expected = some("at most " & $SUBJECT_MAX),
    )


func codeBlanked(text: string): string =
  ## Blank fenced code and each code span of text, line ends kept, so offset of mark read in
  ##   result names same byte of text.
  var is_inside = false
  for line in text.splitLines(keepEol = true):
    let
      is_fence = line.strip.startsWith("```")
      content = line.strip(leading = false, chars = {'\r', '\n'})
    if is_fence: is_inside = not is_inside
    result.add(if is_fence or is_inside: ' '.repeat(content.len) else: content.blankSpansCode)
    result.add line[content.len .. ^1]


func commentsOut(text: string): string =
  ## Drop each HTML comment outside code, since it renders as nothing; comment left open runs
  ##   to end of text.
  let marked = text.codeBlanked
  var at = 0  # Offset past last comment dropped.
  while true:
    let open = marked.find(COMMENT_OPEN, at)
    if open < 0: break
    result.add text[at ..< open]
    let close = marked.find(COMMENT_CLOSE, open + COMMENT_OPEN.len)
    if close < 0: return
    at = close + COMMENT_CLOSE.len
  result.add text[at .. ^1]


func spansFold(marked: string): seq[Slice[int]] =
  ## Find span of each outer fold of text whose code `marked` blanks, lowercased: from tag
  ##   opening it to past tag closing it, or to end where none closes it.
  var
    depth = 0
    opened = 0  # Offset where outer fold opens.
    i = 0
  while i < marked.len:
    let stop = i + TAG_FOLD.len
    if marked.continuesWith(TAG_FOLD, i) and stop < marked.len and
        marked[stop] in {'>'} + Whitespace:
      if depth == 0: opened = i
      inc depth
      i = stop
    elif depth > 0 and marked.continuesWith(TAG_FOLD_CLOSE, i):
      dec depth
      i += TAG_FOLD_CLOSE.len
      if depth == 0: result.add opened ..< i
    else: inc i
  if depth > 0: result.add opened ..< marked.len


func spanSummary(marked: string, fold: Slice[int]): Slice[int] =
  ## Find span of text of first summary inside fold, between its tags; empty where fold holds
  ##   none whole.
  let tag = marked.find(TAG_SUMMARY, fold.a, fold.b)
  if tag < 0: return 1 .. 0
  let
    start = marked.find('>', tag) + 1
    finish = marked.find(TAG_SUMMARY_CLOSE, start, fold.b)
  if start == 0 or finish < 0: 1 .. 0 else: start ..< finish


func textShown(body: string): string =
  ## Read text body shows while each fold is closed, as count of `CHARACTERS_BODY` reads it.
  ##   Marks are read outside code alone: comment shows nothing, fold from `<details>` to its
  ##     `</details>` shows text of its `<summary>` alone, and link shows its text alone.
  ##   Last italic line below `---` rule is footer proxy appends after hook reads body, so it
  ##     shows nothing, and hook and runner count alike.
  ##   `\r` shows nothing, since body edited on GitHub ends each line with `\r\n`.
  let
    text = body.replace("\r", "").commentsOut
    marked = text.codeBlanked.toLowerAscii
  var is_hidden = newSeq[bool](text.len)

  # Hide each fold, but text of its summary.
  for fold in marked.spansFold:
    let summary = marked.spanSummary(fold)
    for k in fold:
      if k notin summary: is_hidden[k] = true

  # Hide marks of each link, so it shows its text alone.
  var at = 0  # Offset of line in text.
  for line in marked.splitLines(keepEol = true):
    for (start, stop) in line.spansLink([]):
      is_hidden[at + start] = true
      for k in at + line.find(']', start + 1) ..< at + stop: is_hidden[k] = true
    at += line.len

  # Gather text that no mark hides.
  var shown = ""
  for k, c in text:
    if not is_hidden[k]: shown.add c

  # Drop footer of proxy: last italic line, below `---` rule.
  var
    lines = shown.splitLines
    last = lines.high
  while last >= 0 and lines[last].strip.len == 0: dec last
  var rule = last - 1
  while rule >= 0 and lines[rule].strip.len == 0: dec rule
  if rule >= 0 and lines[rule].strip == RULE_FOOTER and lines[last].strip.isShaped(SHAPE_ITALIC):
    lines.setLen(rule)
  lines.join("\n").strip


func checkSummary(part: Section): seq[Finding] =
  ## Report section opening with no summary of one to three sentences before its points.
  ##   Summary is first prose block, on first line holding text: list item, table, quotation,
  ##     heading, fenced code or HTML tag there opens none.
  let lines = part.text.splitLines
  var first = 1  # Index of first line holding text, below heading.
  while first < lines.len and lines[first].strip.len == 0: inc first
  let
    opening = if first < lines.len: lines[first].strip else: ""
    found = part.text.blocks
    is_summary = opening.len > 0 and opening.markerLen == 0 and not opening.startsWith("<") and
      found.len > 0 and found[0].line == first + 1
    count = if is_summary: found[0].text.sentences.len else: 0
    got =
      if not is_summary: "`" & opening.shortened & "`"
      elif count > SENTENCES_SUMMARY: "`" & $count & "` sentences"
      else: ""
  if got.len > 0:
    result.add finding(
      "",
      0,
      Check.SummarySection,
      "Section `" & part.heading & "` opens with summary of one to three sentences, then its " &
        "points; got " & got & ".",
    )


func checkBodyPull*(body: string): seq[Finding] =
  ## Report pull request body out of form of template: its sections, their summaries, and
  ##   characters it shows.
  ##   Headings are read through `sections`, outside fenced code and comments, so example that
  ##     quotes heading, as body of #895 quotes sign-off, cuts no section.
  let
    parts = body.replace("\r", "").commentsOut.sections[1 .. ^1]
    headings = parts.mapIt(it.heading)
  if headings != @HEADINGS_PULL:
    let
      named = HEADINGS_PULL[0 ..< ^1].mapIt("`" & it & "`").join(", ")
      got = if headings.len == 0: "``" else: headings.mapIt("`" & it & "`").join(", ")
    result.add finding(
      "",
      0,
      Check.HeadingsBody,
      "Pull request body holds " & named & " and `" & HEADINGS_PULL[^1] & "`, once each and " &
        "in that order; got " & got & ".",
    )
  for part in parts:
    if part.heading in HEADINGS_PULL: result.add part.checkSummary
  let shown = body.textShown.runeLen
  if shown > CHARACTERS_BODY:
    result.add finding(
      "",
      0,
      Check.LengthBody,
      "Pull request body shows at most " & $CHARACTERS_BODY & " characters while each fold " &
        "is closed, with each link counted by its text; got `" & $shown & "`.",
      expected = some("at most " & $CHARACTERS_BODY),
      help = "fold long output in `<details>`",
    )
