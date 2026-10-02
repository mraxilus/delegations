## Fix source in place where check names one mechanical fix (`koch fix`), inside branch scope.
##   Built from checks (Article II.1): each fixer sits beside its check, in `form.nim`,
##     `idioms.nim`, `spacing.nim` and `wrapping.nim`, and reads that check's own data, so each
##     rule is written once. This module selects files, runs on each file fixers its kind's
##     checks name, and refuses any write outside scope.
##   Fix writes kind whose language has style guide alone (`KindRule.has_guide`): fixer
##     applies guide, and STYLE.md is guide of Nim alone, so Nim, NimScript and nimble are
##     written and every other kind passes through. Checks read every kind still; finding in
##     Markdown, TypeScript, YAML or shell stays for hand.
##   Inside that reach, fixer runs where its check runs: form, spacing and wrapping fixers on
##     every Nim kind, idiom fixers on `.nim` alone. Order keeps each fixer from undoing one
##     before it:
##   - form first (whitespace, ending, trailing comment, banner), so later fixers read clean
##     line ends and final comment gaps, which wrapping counts in width;
##   - idioms next (return, import order, import brackets, bindings, `strictFuncs`, unordered
##     lists), since bindings indent lines and every later width reads that indent;
##   - spacing before wrapping, since spaces it adds are width wrapping measures;
##   - wrapping last, separators before signatures before calls before trailing separators:
##     layouts join groups with separator they read, and trailing separator goes only where no
##     layout wrote one.
##   Chain runs again until it changes nothing, at most `ROUNDS_MAX` times: line wrapping
##     splits can take spacing fixer refused for width, so second round writes it, and
##     `koch fix` run twice writes nothing second time.
##   Fence (Article X.1): line `#!fix off` opens fence, line `#!fix on` closes it, each marker
##     alone on its line as comment; fence left open runs to end of file. Fixers never write
##     lines of fence, markers included, and layout checks report nothing there. Each fenced
##     line reads as whole-line comment `FENCED` at its own indent while fixers run, so call,
##     signature or list holding fence reads as holding comment, and stays as written.
##     Fixer whose rewrite would move, re-indent, split or merge fenced lines is skipped for
##     that file, and its finding stays for hand. Fence crossing bracket, or string or comment
##     spanning lines, leaves whole file as written, with finding naming line.
##   Nimble file whose copy `atlas.lock` holds (`nimbleFile`) is never written, and layout
##     checks read none of it: rewrite would leave lock's copy stale, and Atlas reads that as
##     change of package.
##   `checkFormatting` holds every check whose findings these fixers clear and static pass
##     does not run yet; pull request after projects run `koch fix` wires its tree form (CURATOR.md,
##     duty 3), one line in `auditTree`, and drops lenient banner check `checkForm` runs.
##   Scope: every path fix would write goes through `scope.checkScope` for branch. One path
##     outside refuses every write, so run writes all it planned or nothing. Curator branch
##     thus never writes contributor code (`checkPropagation`), as CURATOR.md duty 11 asks.
##   Named path is file git lists, or directory holding such files; name matching nothing is
##     finding, so typo never passes as fix of nothing.
##
##   Rejected: nimpretty, which sets one space before trailing comment where X.9 asks two,
##     and `;` between parameters where STYLE.md §5 asks `,`; fork of nimpretty's layouter,
##     second formatter whose layout rules would drift from checks; AST printer, which loses
##     comment placement and every layout hand chose. Each holds rule twice: as check, and as
##     layout.
##   Rejected: fixer told of fence, i.e. each rewrite tested against fenced lines. Every fixer
##     would carry fence; masking holds it in one place, at cost of skipping fixer whole.
##   Cost: fix reaches only what checks name; layout no check reads stays with reading.
##   Cost: `main` passes scope as merge target, so fix there writes wherever it finds rewrite.
##   Cost: line reading exactly `FENCED` outside fence would be restored as fenced line, so
##     file holding one is left as written, like fence crossing bracket.

{.experimental: "strictFuncs".}

import std/[options, sequtils, sets, strutils]
import ./[findings, form, idioms, kinds, layout, names, scope, spacing, tokens, wrapping]


const
  ROUNDS_MAX = 3
    ## Rounds of whole chain at most; tree settles in two (`curator/audit/PROVENANCE.md`, Fixes).
  FENCE_OFF* = "#!fix off"
    ## Marker line opening fence (Article X.1).
  FENCE_ON* = "#!fix on"
    ## Marker line closing fence.
  FENCED = "#!fix fenced"
    ## Text each fenced line reads as while fixers run: whole-line comment, which no fixer writes.
  LOCK_FILE = "atlas.lock"
    ## Lock holding copy of project's nimble file.
  NIMBLE_KEY = "\"nimbleFile\""
    ## Key of lock's copy of nimble file, whose `filename` names it.


type Fence = object
  ## Define lines fence leaves alone, and line where fence cannot be read, if any.
  lines: seq[int]  ## Zero-based fenced lines, markers included, in order.
  fault: int  ## Zero-based line fence crosses bracket or token at, or reads `FENCED`; `-1` if none.


func fenceOf(source: string): Fence =
  ## Read fenced lines of Nim source, and first line where fence cannot be read.
  ##   Marker is comment token opening its line, so marker inside string or block comment is none.
  result.fault = -1
  let
    tokens = source.tokens
    partners = tokens.partners
    lines = source.split('\n')
    count = if source.endsWith("\n"): lines.len - 1 else: lines.len
  var markers = newSeq[string](lines.len)
  for k, t in tokens:
    if t.kind != TokenKind.Comment: continue
    if k == 0 or tokens[k - 1].lastLine(source) < t.line:
      markers[t.line] = t.spelling(source).strip
  var
    fences = newSeqWith(lines.len, -1)  # Fence each line lies in, by count; `-1` outside.
    opened = 0
    is_open = false
  for i in 0 ..< count:
    if markers[i] == FENCE_OFF and not is_open:
      is_open = true
      inc opened
    if is_open: fences[i] = opened
    if markers[i] == FENCE_ON: is_open = false
    if fences[i] >= 0: result.lines.add i
    if lines[i].strip == FENCED and result.fault < 0: result.fault = i
  if result.lines.len == 0: return

  # Bracket pair whose ends lie in two places, or token whose lines do, crosses fence.
  for k, t in tokens:
    let crossed =
      if partners[k] > k: fences[tokens[partners[k]].line] != fences[t.line]
      else: toSeq(t.line .. t.lastLine(source)).anyIt(fences[it] != fences[t.line])
    if crossed:
      result.fault = if result.fault < 0: t.line else: min(result.fault, t.line)
      return


func masked(source: string, fence: Fence): string =
  ## Read each fenced line as `FENCED` at its own indent; blank line at none.
  var lines = source.split('\n')
  for i in fence.lines:
    lines[i] = (if lines[i].strip.len == 0: "" else: ' '.repeat(lines[i].indentOf)) & FENCED
  lines.join("\n")


func fenceShape(source: string): seq[(int, bool)] =
  ## Read indent of each `FENCED` line, and whether one stands right above it.
  let lines = source.split('\n')
  for i, line in lines:
    if line.strip != FENCED: continue
    result.add (line.indentOf, i > 0 and lines[i - 1].strip == FENCED)


func restored(fixed, source: string; fence: Fence): string =
  ## Write each fenced line back, in order, in place of `FENCED` line standing for it.
  let original = source.split('\n')
  var
    lines = fixed.split('\n')
    k = 0
  for line in lines.mitems:
    if line.strip != FENCED: continue
    line = original[fence.lines[k]]
    inc k
  lines.join("\n")


func faultOf(path: string, fence: Fence): seq[Finding] =
  ## Report fence fix cannot read, which leaves file as written.
  if fence.fault < 0: return
  result.add finding(
    path,
    fence.fault + 1,
    "Fence closes outside bracket, string or comment it opens in, so fix leaves file as " &
      "written (X.1); got `" & FENCE_OFF & "` and `" & FENCE_ON & "` either side.",
  )


func fixersOf(kind: Kind): seq[Fixer] =
  ## List fixers kind's checks name, in order header gives.
  result = kind.rule.formFixers
  if kind == Kind.Nim: result.add IDIOM_FIXERS
  result.add Fixer(fixSpacing)
  result.add WRAPPING_FIXERS


func lockedNimbles*(tree: Tree): seq[string] =
  ## Read path of each nimble file whose copy `atlas.lock` beside it holds.
  for e in tree:
    if not e.path.endsWith("/" & LOCK_FILE) and e.path != LOCK_FILE: continue
    let at = e.content.find(NIMBLE_KEY)
    if at < 0: continue
    let
      key = e.content.find("\"filename\"", at)
      open = if key < 0: -1 else: e.content.find('"', e.content.find(':', key) + 1)
      close = if open < 0: -1 else: e.content.find('"', open + 1)
    if close < 0: continue
    result.add e.path[0 ..< e.path.len - LOCK_FILE.len] & e.content[open + 1 ..< close]


func checkFormatting*(path, source: string; kind: Kind): seq[Finding] =
  ## Report each rule `koch fix` clears in full that static pass leaves out until projects fix.
  ##   X.9 trailing comments and operator spacing, X.2 banners, X.3 and STYLE.md §5
  ##   separators, signatures, calls and trailing separators, on every Nim kind; X.5 import
  ##   brackets and X.10 lists on `.nim`, as idiom checks read it. Fenced lines are read by
  ##   none, and fence fix cannot read is reported alone.
  if kind.rule.syntax != Syntax.Nim: return
  let fence = source.fenceOf
  if fence.fault >= 0: return faultOf(path, fence)
  let
    view = source.masked(fence)
    checks = [
      checkComments, checkBanners, checkSpacing, checkSeparators, checkSignatures, checkCalls,
      checkTrailing,
    ]
  for check in checks: result.add check(path, view)
  if kind == Kind.Nim: result.add checkImportBrackets(path, view) & checkLists(path, view)
  result = result.filterIt(it.line - 1 notin fence.lines)


func checkFormatting*(tree: Tree): seq[Finding] =
  ## Report each rule `koch fix` clears over every file of tree; nimble file whose copy
  ##   `atlas.lock` holds is read by none.
  let locked = tree.lockedNimbles
  for e in tree:
    if e.kind.isNone or e.path in locked: continue
    result.add checkFormatting(e.path, e.content, e.kind.get)


func entriesNamed*(
  tree: Tree, names: openArray[string]
): tuple[entries: seq[Entry], unknown: seq[Finding]] =
  ## Select entries names give, each once: file git lists, or every file under directory.
  ##   Name matching nothing is reported, never skipped.
  var seen = initHashSet[string]()
  for name in names:
    var path = name.strip(leading = false, chars = {'/'})
    if path.startsWith("./"): path = path[2 .. ^1]
    var found_file = false
    for e in tree:
      if e.path != path and not e.path.startsWith(path & "/"): continue
      found_file = true
      if seen.containsOrIncl(e.path): continue
      result.entries.add e
    if not found_file:
      result.unknown.add finding(path, 0, "Name matches no file git lists; got `" & name & "`.")


func fixSource(path, source: string; kind: Kind; fence: Fence): Fix =
  ## Run on source each fixer its kind's checks name, in order header gives, until source
  ##   settles; fenced lines read as `FENCED`, and fixer that would move them is skipped.
  let shape = source.masked(fence).fenceShape
  result.source = source.masked(fence)
  for round in 1 .. ROUNDS_MAX:
    var step = Fix(source: result.source)
    for fixer in kind.fixersOf:
      let next = fixer(path, step.source)
      if next.source.fenceShape != shape: continue
      step = step.chain(next)
    if step.source == result.source: break
    result = result.chain(step)
  result.source = result.source.restored(source, fence)


func fixEntries*(
  branch: string, entries: openArray[Entry], locked: openArray[string] = []
): tuple[written: seq[Entry], fixed, refused, left: seq[Finding]] =
  ## Fix each entry: entries to write, one report per rewrite, scope findings, and files left
  ##   as written with reason: nimble file `locked` names, fence fix cannot read.
  ##   Where any path to write lies outside branch scope, nothing is written or reported fixed.
  for e in entries:
    if e.kind.isNone or not e.kind.get.rule.has_guide: continue
    if e.path in locked:
      result.left.add finding(
        e.path,
        0,
        "Nimble file whose copy `" & LOCK_FILE & "` holds stays as written; got its copy there.",
      )
      continue
    let fence = e.content.fenceOf
    if fence.fault >= 0:
      result.left.add faultOf(e.path, fence)
      continue
    let fix = fixSource(e.path, e.content, e.kind.get, fence)
    if fix.source == e.content: continue
    result.written.add Entry(path: e.path, kind: e.kind, content: fix.source)
    result.fixed.add fix.fixed
  if result.written.len == 0: return
  result.refused = checkScope(branch, result.written.mapIt(it.path))
  if result.refused.len > 0:
    result.written.setLen(0)
    result.fixed.setLen(0)
