## Hold pull request's opening role line and its labels to role its branch names, and its title
##   to commit grammar.
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
##   `ledger.yml` reads same two facts daily over open items, which samples rather than gates:
##     pull request living half hour is almost never open when it runs, and it reports after
##     merge rather than before.
##
##   Branch outside grammar reports nothing here: `check-scope` already fails it, and expected role
##     cannot be derived from name grammar rejects.
##   Cost: issue carries no branch, so which label it needs is judgement, and stays ledger's.
##   Cost: comment is unreachable, and is what remains of CONTRIBUTOR.md's first carried rule.
##   Cost: labels are searched for expected string rather than compared whole, since label is
##     added when work hands across and never removed.
##   Cost: stray lines in shapes of listed block pass above role line, as block itself does.
##   Cost: italic line written in asterisks is other shape, so harness turning to it fails until
##     its entry changes.

{.experimental: "strictFuncs".}

import std/[options, sequtils, strutils, unicode]
import ./[commits, domains, findings, markdown]


type
  Shape = tuple[opening, closing: string]
    ## Define shape of one line harness writes above role line, known by its two ends alone.

  Harness = object  ## Define block one harness writes above role line of pull request it opens.
    name {.requiresInit.}: string  ## Harness, as its own documents name it.
    shapes {.requiresInit.}: seq[Shape]  ## Shape of each line of block, in order.


const
  KEY_ROLE* = "**Role:**"  ## Opening of role line, bold as every prompt and template writes it.
  COMMENT_OPEN* = "<!--"  ## Opening of HTML comment, which unfilled template carries after key.
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
  LINES_QUOTED* = block:
    ## Lines above role line finding quotes at most: twice block of longest listed harness, so
    ##   block of new harness shows whole, and body whose role line stands low prints no whole
    ##   opening.
    var longest = 0
    for harness in HARNESSES: longest = max(longest, harness.shapes.len)
    2 * longest
  HEADINGS_PULL* = ["## Intent", "## Scope", "## Verification", "## Record", "## Notes"]
    ## Headings pull request template gives.
  SENTENCES_SUMMARY = 3  ## Sentences summary opening each section holds at most.
  CHARACTERS_BODY = 2500  ## Characters body shows at most while each fold is closed.


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
  ##   Block is passed only whole and in its place, so lone marker, stray credit line or any
  ##     other comment still reads as opening.
  let
    lines = body.linesOpening
    at = lines.lenBlock
  if at >= lines.len: return ""
  let open = lines[at].find(COMMENT_OPEN)
  if open < 0: lines[at] else: lines[at][0 ..< open].strip


func openingQuoted*(body: string): string =
  ## Quote what finding on opening of body names, each line in backticks: each line above first
  ##   role line where line no listed block holds stands there, else opening line alone.
  ##   Quote holds at most `LINES_QUOTED` lines, each cut to `ECHO_MAX` runes, since body is
  ##     whatever somebody typed.
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
      "Pull request must open with `" & KEY_ROLE & " " & expected &
        "`, which its branch names; got " & body.openingQuoted & ".",
    )
  if expected notin labels:
    result.add finding(
      "",
      0,
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
      "Pull request title must match `type(scope): lowercase summary` without final period, " &
        "since merge commit takes it as subject; got `" & title.shortened & "`.",
    )
  elif scope.isSome and parsed.get.scope != scope.get:
    result.add finding(
      "",
      0,
      "Pull request title scope must be `" & scope.get & "`; got `" & title.shortened & "`.",
    )
  if title.runeLen > SUBJECT_MAX:
    result.add finding(
      "",
      0,
      "Pull request title exceeds " & $SUBJECT_MAX & " characters; got `" & $title.runeLen & "`.",
    )


func textShown(body: string): string =
  ## Read text body shows while each fold is closed, as count of `CHARACTERS_BODY` reads it.
  ##   TODO: Drop comments, folds but their summaries, marks of links, and footer of proxy.
  body


func checkBodyPull*(body: string): seq[Finding] =
  ## Report pull request body out of form of template.
  ##   TODO: Hold its sections, their summaries and characters it shows.
  discard
