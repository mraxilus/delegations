## Fix source in place where check names one mechanical fix (`koch fix`), inside branch scope.
##   Built from checks (Article II.1): each fixer sits beside its check, in `form.nim`,
##     `prose.nim`, `alignment.nim`, `messages.nim`, `precedence.nim`, `conversions.nim`,
##     `idioms.nim`, `checker.nim`, `blanks.nim`, `declarations.nim`, `spacing.nim` and
##     `wrapping.nim`, and reads that check's own data, so each rule is written once. This
##     module selects files, runs on each file fixers its kind's checks name, and refuses any
##     write outside scope.
##   Fix writes kind whose language has style guide alone (`KindRule.has_guide`): fixer
##     applies guide, and STYLE.md is guide of Nim alone, so Nim, NimScript and nimble are
##     written and every other kind passes through. Checks read every kind still; finding in
##     Markdown, TypeScript, YAML or shell stays for hand.
##   Inside that reach, fixer runs where its check runs: idiom fixers on `.nim` alone, every
##     other fixer on every Nim kind. Order keeps each fixer from undoing one before it:
##   - form first (whitespace, ending, tab in string, trailing comment, banner), so later
##     fixers read clean line ends and final comment gaps, which wrapping counts in width;
##   - content next (articles in comments, I.4 tables, backticks of IV.4 messages, parentheses
##     of X.4 conditions, `to<Target>` subject first), since each changes width of its line;
##   - idioms next (return, stub keys, import order, import brackets, bindings, `strictFuncs`,
##     profiler import, unordered lists), since bindings indent lines and every later width
##     reads that indent;
##   - blank lines beside suites, tests and helpers, then doc position and literal defaults,
##     since doc joined or type dropped changes width wrapping measures;
##   - spacing before wrapping, since spaces it adds are width wrapping measures;
##   - wrapping last, separators before signatures before calls before trailing separators:
##     layouts join groups with separator they read, and trailing separator goes only where no
##     layout wrote one.
##   Fixer whose rule needs more than text of one file runs first, once, on source as given,
##     from what `contextOf` reads: rename of abbreviation (V.6) across files, planned whole or
##     refused whole (`names.nim`, `rewrites.nim`), and type conversion `x.T` (`conversions.nim`),
##     each from semantic pass (`symbols.nim`); then dead export of checker (`checker.nim`),
##     whose `*` goes where its own module calls it. Fix of named files reads tree whole, and
##     rename writing file it leaves out is refused. File holding candidate that compiles on no
##     backend is left to hand, with its error.
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
##     does not run yet; pull request after projects run `koch fix` wires its tree form
##     (CURATOR.md, duty 3), one line in `auditTree`, and drops lenient banner check
##     `checkForm` runs.
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

import std/[options, sequtils, sets, strutils, tables]
import ./[alignment, blanks, checker, conversions, declarations, findings, form, glossary]
import ./[idioms, kinds, layout, messages, names, precedence, prose, rewrites, scope, spacing]
import ./[symbols, tokens, wrapping]


const
  ROUNDS_MAX = 3
    ## Rounds of whole chain at most; tree settles in two (`curator/audit/PROVENANCE.md`, Fixes).
  FENCE_OFF* = "#!fix off"  ## Marker line opening fence (Article X.1).
  FENCE_ON* = "#!fix on"  ## Marker line closing fence.
  FENCED = "#!fix fenced"
    ## Text each fenced line reads as while fixers run: whole-line comment, which no fixer writes.
  LOCK_FILE = "atlas.lock"  ## Lock holding copy of project's nimble file.
  NIMBLE_KEY = "\"nimbleFile\""  ## Key of lock's copy of nimble file, whose `filename` names it.


type
  Fence = object
    ## Define lines fence leaves alone, and line where fence cannot be read, if any.
    lines: seq[int]  ## Zero-based fenced lines, markers included, in order.
    fault: int
      ## Zero-based line fence crosses bracket or token at, or reads `FENCED`; `-1` if none.

  Context* = object
    ## Define what whole tree and semantic pass tell fixer of one file that its text cannot:
    ##   rule read across modules, and symbol each name resolves to.
    dead: seq[(string, string)]  ## Path and name of each export no other module names.
    answers: Table[string, Answer]  ## Semantic pass's answer for each file asked, by path.
    plans: seq[Plan]  ## Rename of each declaration coining abbreviation, planned or refused.


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
  for i in 0..<count:
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
      else: toSeq(t.line..t.lastLine(source)).anyIt(fences[it] != fences[t.line])
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
  result.add @[Fixer(fixArticles), fixAlignment, fixMessages, fixMixtures, fixTargets]
  if kind == Kind.Nim: result.add IDIOM_FIXERS
  result.add @[Fixer(fixBlanks), fixDocs, fixDefaults, fixSpacing]
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
    result.add e.path[0..<e.path.len - LOCK_FILE.len] & e.content[open + 1..<close]


func checkFormatting*(path, source: string; kind: Kind): seq[Finding] =
  ## Report each rule `koch fix` clears in full that static pass leaves out until projects fix,
  ##   and X.4 `not` over binary expression, which waits with them and has no fixer.
  ##   On every Nim kind: X.9 trailing comments and spaces, X.2 banners, I.4 tables, IV.4
  ##   messages, X.4 conditions, STYLE.md §5 `to<Target>` calls, suites and tests, STYLE.md §1
  ##   helpers, doc position, X.12 defaults, and X.3 and STYLE.md §5 separators, signatures,
  ##   calls and trailing separators.
  ##   On `.nim` alone, as idiom checks read it: X.5 import brackets, X.10 lists and STYLE.md
  ##   §3 profiler import. Fenced lines are read by none, and fence fix cannot read is reported
  ##   alone.
  if kind.rule.syntax != Syntax.Nim: return
  let fence = source.fenceOf
  if fence.fault >= 0: return faultOf(path, fence)
  let
    view = source.masked(fence)
    checks = [
      checkComments, checkBanners, checkAlignment, checkMessages, checkMixtures, checkNegations,
      checkTargets, checkBlanks, checkDocs, checkDefaults, checkSpacing, checkSeparators,
      checkSignatures, checkCalls, checkTrailing,
    ]
  for check in checks: result.add check(path, view)
  if kind == Kind.Nim:
    result.add checkImportBrackets(path, view) & checkLists(path, view) & checkProfiler(path, view)
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


func isNimKind(e: Entry): bool =
  ## Decide whether entry is of kind fix writes: Nim, NimScript or nimble.
  e.kind.isSome and e.kind.get.rule.has_guide


func scopeOf(tree: Tree, path: string): seq[(string, string)] =
  ## Read Nim files rename of name declared in path may reach: path's own project, and root
  ##   files, which import across projects (`koch.nim`).
  let directory = path.split('/').projectDirectory
  for e in tree:
    if e.isNimKind and (e.path.split('/').projectDirectory == directory or '/' notin e.path):
      result.add (e.path, e.content)


func renamesOf(tree: Tree; entries: openArray[Entry]; locked: openArray[string]): seq[Rename] =
  ## Read rename of each declaration in entries coining abbreviation (V.6), as names check
  ##   reads it, with words glossaries admit.
  let directories = tree.projectDirectories
  var glossaries: seq[(string, string)]
  for e in tree:
    if e.path == ROOT_GLOSSARY or directories.anyIt(e.path == it & "/" & ROOT_GLOSSARY):
      glossaries.add (e.path, e.content)
  for e in entries:
    if not e.isNimKind or e.path in locked: continue
    let exempt = glossaries.exemptionsOf(e.path)
    for (line, column, name, renamed) in abbreviationRenames(e.content, exempt):
      result.add Rename(
        path: e.path,
        line: line,
        column: column,
        name: name,
        renamed: renamed,
        rule: "abbreviation (V.6)",
      )


func semanticQueries*(
  tree: Tree, entries: openArray[Entry], locked: openArray[string] = []
): seq[Query] =
  ## Build what fixers of entries ask semantic pass: each type conversion candidate (STYLE.md
  ##   §5), and every site of each name rename of abbreviation (V.6) would write, across its
  ##   scope. File fix leaves as written asks nothing; one query holds all one file is asked.
  var asked: seq[Query]
  for e in entries:
    if e.isNimKind and e.path notin locked: asked.add conversionQuery(e.path, e.content)
  for rename in renamesOf(tree, entries, locked):
    asked.add rename.queriesOf(tree.scopeOf(rename.path))
  for query in asked:
    if query.sites.len == 0 and query.names.len == 0: continue
    var k = result.mapIt(it.path).find(query.path)
    if k < 0:
      result.add Query(path: query.path)
      k = result.high
    for site in query.sites:
      if site notin result[k].sites: result[k].sites.add site
    for name in query.names:
      if name notin result[k].names: result[k].names.add name


func contextOf*(
  tree: Tree,
  entries: openArray[Entry] = [],
  answers: openArray[Answer] = [],
  locked: openArray[string] = [],
): Context =
  ## Read what tree and semantic pass tell fixers: dead exports of checker, as static pass reads
  ##   them from its modules, `koch.nim` and its suites; answer of each file asked; and rename
  ##   of each abbreviation in entries, refused where it would write file entries leave out.
  var paths, sources, suites: seq[string]
  for e in tree:
    if e.path.startsWith(CHECK_DIRECTORY) or e.path == KOCH_PATH:
      paths.add e.path
      sources.add e.content
    if e.path.startsWith(SUITE_DIRECTORY): suites.add e.content
  result.dead = deadExports(paths, sources, suites).deduplicate
  for answer in answers: result.answers[answer.path] = answer
  let named = entries.mapIt(it.path)
  for rename in renamesOf(tree, entries, locked):
    let scope = tree.scopeOf(rename.path)
    var fenced = initTable[string, seq[int]]()
    for (path, source) in scope: fenced[path] = source.fenceOf.lines
    var plan = planRename(rename, scope, result.answers, fenced)
    for path in plan.edits.keys:
      if plan.refusal.len > 0: break
      if path notin named or path in locked:
        plan.refusal = "it would write `" & path & "`, which this fix leaves alone"
    result.plans.add plan


func fixSource(path, source: string; kind: Kind; fence: Fence; context: Context): Fix =
  ## Run on source each fixer its kind's checks name, in order header gives, until source
  ##   settles; fenced lines read as `FENCED`, and fixer that would move them is skipped.
  ##   Fixers that semantic pass and tree inform run first, once, on source as given.

  # Write edits semantic pass settles, off fenced lines; no line moves, so fence holds.
  var renamed: seq[Edit]
  for plan in context.plans:
    if plan.refusal.len > 0 or path notin plan.edits: continue
    renamed.add plan.edits[path]
    for (file, line) in plan.lines:
      if file == path: result.fixed.add finding(path, line, plan.rename.rule)
  var base = source.applied(renamed)
  if path in context.answers:
    let (edits, reports) =
      conversionEdits(path, source, context.answers[path], fence.lines, renamed)
    base = source.applied(renamed & edits)
    result.fixed.add reports
  let shape = base.masked(fence).fenceShape
  result.source = base.masked(fence)
  let dead = context.dead.filterIt(it[0] == path).mapIt(it[1])
  if dead.len > 0:
    let step = fixDeadExports(path, result.source, dead)
    if step.source.fenceShape == shape: result = result.chain(step)
  for round in 1..ROUNDS_MAX:
    var step = Fix(source: result.source)
    for fixer in kind.fixersOf:
      let next = fixer(path, step.source)
      if next.source.fenceShape != shape: continue
      step = step.chain(next)
    if step.source == result.source: break
    result = result.chain(step)
  result.source = result.source.restored(source, fence)


func fixEntries*(
  branch: string, entries: openArray[Entry], locked: openArray[string] = [], context = Context()
): tuple[written: seq[Entry], fixed, refused, left: seq[Finding]] =
  ## Fix each entry: entries to write, one report per rewrite, scope findings, and files left
  ##   as written with reason: nimble file `locked` names, fence fix cannot read. `context`
  ##   carries what tree tells fixers across modules (`contextOf`).
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
    for plan in context.plans:
      if plan.rename.path != e.path or plan.refusal.len == 0: continue
      result.left.add finding(
        e.path,
        plan.rename.line,
        "Rename to `" & plan.rename.renamed & "` refused, so " & plan.rename.rule &
          " stays for hand; got " & plan.refusal & ".",
      )
    if e.path in context.answers and context.answers[e.path].reason.len > 0:
      result.left.add finding(
        e.path,
        0,
        "File compiles on no backend of its pin, so fixers resting on semantic pass leave it; " &
          "got `" & context.answers[e.path].reason & "`.",
      )
    let fix = fixSource(e.path, e.content, e.kind.get, fence, context)
    if fix.source == e.content: continue
    result.written.add Entry(path: e.path, kind: e.kind, content: fix.source)
    result.fixed.add fix.fixed
  if result.written.len == 0: return
  result.refused = checkScope(branch, result.written.mapIt(it.path))
  if result.refused.len > 0:
    result.written.setLen(0)
    result.fixed.setLen(0)
