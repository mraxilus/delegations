## Fix Nim source by every fixer of knoller, in one order, until it settles; report each rule
##   those fixers clear (`checkFormatting`); and name what breaks rule inside each fence
##   (`heldOf`).
##   Built from checks (Article II.1): each fixer sits beside its check and reads that check's
##     own data, so each rule is written once.
##   Fixer runs where its check runs: idiom fixers on module (`.nim`) alone, every other fixer
##     in every dialect. Order keeps each fixer from undoing one before it:
##   - form first (whitespace, ending, tab in string, trailing comment, banner), so later
##     fixers read clean line ends and final comment gaps, which wrapping counts in width;
##   - entry block next, whose body moves into `proc main` (V.10): it moves lines and widens
##     none, so every later fixer reads body where it stands;
##   - content next (articles in comments, backticks of IV.4 messages, parentheses of X.4
##     conditions, `to<Target>` subject first, command form of dotted call statement),
##     since each changes width of its line;
##   - idioms next (return, stub keys, import order, import brackets, bindings, `strictFuncs`,
##     profiler import, unordered lists), since bindings indent lines and every later width
##     reads that indent;
##   - blank lines beside suites, tests and helpers, then doc position and literal defaults,
##     since doc joined or type dropped changes width wrapping measures;
##   - spacing before wrapping, since spaces it adds are width wrapping measures;
##   - wrapping last, separators, signatures, calls, continuations, then trailing separators:
##     layouts join groups with separator they read, call layout breaks line at operator where
##     no call split fits, continuation indent follows lines call layout moves, and trailing
##     separator goes only where no layout wrote one.
##   - comment last: plain `#` trailing comment of line still wide moves to own line above,
##     since no wrap reads line holding comment; next round lays out line it leaves.
##   Chain is list of steps: fixer guarded on every line, or widener (`reports.nim`), i.e. tab,
##     comment, message, condition, spacing, continuation and trailing separator fixers, which
##     read held lines.
##     Idiom fixers stay guarded: import bracket has no wrap.
##   No fixer aligns comment table: width reader sees depends on font, so no check reads it,
##     and reading holds I.4 tables.
##   Chain runs again until it changes nothing, at most `ROUNDS_MAX` times: round can enable
##     fixer that ran before it, as gap widened past `LINE_MAX` moves doc to next line, so
##     second round writes it, and `koch fix` run twice writes nothing second time.
##   Rounds run inside attempts, at most `ATTEMPTS_MAX`. First attempt holds no line, so each
##     widener repairs freely and wrapping breaks line after. Line still wide once rounds settle,
##     narrow in source as given, is held in next attempt, which runs from source as given
##     again; held lines are numbered there, and each step reads them through lines traced so
##     far. Last attempt holds every line, as chain did before wideners. Held line never widens
##     again, since widener keeps guard there and no other fixer or wrap writes wide line, so
##     held lines grow each attempt; inserted line left wide holds every line at once.
##   File whose last attempt still changes after `ROUNDS_MAX` rounds stays as written, and its
##     fix reports why (`Rule.Unsettled`), so half-settled file is never written.
##   Nimble file whose copy `atlas.lock` holds (`nimbleFile`, `lockedNimbles`) is left to
##     caller, which writes none of it and checks none of it: rewrite would leave lock's copy
##     stale, and Atlas reads that as change of package.
##   Fence's warning runs checks as dry run: same checks on source unmasked, where each marker
##     reads as plain comment and each line keeps its number, so warning counts what same lines
##     report unfenced. Finding fixer clears and finding left for hand count alike; module adds
##     idiom checks static pass runs (`checkStrictFuncs` and siblings). Fixer writes no fenced
##     line still, and warning changes no exit code.
##
##   Rejected: nimpretty, which sets one space before trailing comment where X.9 asks two,
##     and `;` between parameters where STYLE.md §5 asks `,`; fork of nimpretty's layouter,
##     second formatter whose layout rules would drift from checks; AST printer, which loses
##     comment placement and every layout hand chose. Each holds rule twice: as check, and as
##     layout.
##   Cost: file with fence takes checks twice, masked and as given; fenced catalogue of many
##     calls runs near three times as long, measured (`PROVENANCE.md`, Fences). File with no
##     fence takes them once.

{.experimental: "strictFuncs".}

import std/[algorithm, options, sequtils, strutils]
import ./[
  articles, blanks, commands, declarations, entry, fences, form, idioms, messages, precedence,
  reports, spacing, targets, views, wrapping,
]


const
  ROUNDS_MAX = 3
    ## Rounds of whole chain at most; tree settles in two (`curator/audit/PROVENANCE.md`, Fixes).
  ATTEMPTS_MAX = 4
    ## Attempts of rounds at most, last holding every line; tree settles in two
    ##   (`PROVENANCE.md`, Wraps).
  LOCK_FILE* = "atlas.lock"  ## Lock holding copy of project's nimble file.
  NIMBLE_KEY = "\"nimbleFile\""  ## Key of lock's copy of nimble file, whose `filename` names it.


type Dialect* {.pure.} = enum  ## Define which Nim source file holds, which decides fixers it takes.
  Module  ## `.nim`, which idiom fixers read too.
  Script  ## `.nims`.
  Package  ## `.nimble`.


func stepsOf(dialect: Dialect): seq[Step] =
  ## List steps dialect takes, in order header gives.
  result = @FORM_STEPS
  result.add @[
    guarded(fixBlockEntry), guarded(fixArticles), widening(fixMessages),
    widening(fixMixtures), guarded(fixTargets), guarded(fixCommands),
  ]
  if dialect == Dialect.Module:
    for fixer in IDIOM_FIXERS: result.add guarded(fixer)
  result.add @[guarded(fixBlanks), guarded(fixDocs), guarded(fixDefaults), widening(fixSpacing)]
  result.add WRAPPING_STEPS
  result.add guarded(fixCommentsAbove)


func lockedNimbles*(files: openArray[(string, string)]): seq[string] =
  ## Read path of each nimble file whose copy `atlas.lock` beside it holds, from path and text
  ##   of each file; file of another name is passed over.
  for (path, content) in files:
    if not path.endsWith("/" & LOCK_FILE) and path != LOCK_FILE: continue
    let at = content.find(NIMBLE_KEY)
    if at < 0: continue
    let
      key = content.find("\"filename\"", at)
      open = if key < 0: -1 else: content.find('"', content.find(':', key) + 1)
      close = if open < 0: -1 else: content.find('"', open + 1)
    if close < 0: continue
    result.add path[0 ..< path.len - LOCK_FILE.len] & content[open + 1 ..< close]


func checksOf(path, view: string; dialect: Dialect): seq[Report] =
  ## Run on view each check `checkFormatting` holds that dialect takes; fence is caller's.
  let checks = [
    checkComments, checkBanners, checkMessages, checkMixtures, checkNegations, checkTargets,
    checkCommands, checkBlanks, checkDocs, checkDefaults, checkSpacing, checkSeparators,
    checkSignatures, checkCalls, checkContinuations, checkTrailing, checkCommentsAbove,
  ]
  for check in checks: result.add check(path, view)
  if dialect == Dialect.Module:
    result.add checkImportBrackets(path, view) & checkLists(path, view) & checkProfiler(path, view)


func checkFormatting*(path, source: string; dialect: Dialect): seq[Report] =
  ## Report each rule `koch fix` clears in full that static pass leaves out until projects fix,
  ##   and X.4 `not` over binary expression, which waits with them and has no fixer.
  ##   In every dialect: X.9 trailing comments and spaces, X.2 banners, IV.4 messages, X.4
  ##   conditions, STYLE.md §5 `to<Target>` calls and dotted call statements,
  ##   suites and tests, STYLE.md §1 helpers, doc position, X.12 defaults, and X.3 and STYLE.md
  ##   §5 separators, signatures, calls, operator breaks, continuations and trailing separators,
  ##   and X.1 comments above.
  ##   On `.nim` alone, as idiom checks read it: X.5 import brackets, X.10 lists and STYLE.md
  ##   §3 profiler import. Fenced lines are read by none, and fence fix cannot read is reported
  ##   alone.
  let fence = source.fenceOf
  if fence.fault >= 0: return faultOf(path, fence)
  checksOf(path, source.masked(fence), dialect).filterIt(it.line - 1 notin fence.lines)


func heldThrough(held: Held; fix, step: Fix): Held =
  ## Read held lines of source step leaves, numbered there, from lines of source as given that
  ##   fix, then step, trace back to; inserted line is held only where every line is.
  if held.is_every: return held
  for line in 1 .. step.source.count('\n') + 1:
    let given = fix.traced(step.traced(line))
    if given > 0 and held.isHeld(given): result.lines.add line


func settled(path, view: string; steps: openArray[Step]; held: Held): Option[Fix] =
  ## Run steps over view until round changes nothing, at most `ROUNDS_MAX` rounds, wideners off
  ##   held lines; fixer that would move fenced line is skipped. `none` where last round changes.
  let shape = view.fenceShape
  var fix = Fix(source: view)
  for round in 1 .. ROUNDS_MAX:
    var step = Fix(source: fix.source)
    for each in steps:
      let next = each.run(path, step.source, held.heldThrough(fix, step))
      if next.source.fenceShape != shape: continue
      step = step.chain(next)
    if step.source == fix.source: return some(fix)
    fix = fix.chain(step)
  none(Fix)


func widened(view: string, fix: Fix): seq[int] =
  ## Read line of view each wide line of fix traces to, where that line was narrow; `0` for
  ##   inserted line.
  let
    given = view.split('\n')
    lines = fix.source.split('\n')
  for k, line in lines:
    if not line.isWide: continue
    let traced = fix.traced(k + 1)
    if traced == 0 or not given[traced - 1].isWide: result.add traced


func attempted(
  path, view: string; steps: openArray[Step]
): tuple[fix: Option[Fix], attempts: int] =
  ## Settle view, each attempt holding every line attempts before left wide, until none is left;
  ##   last attempt holds every line. Attempt that does not settle, holds no new line, or leaves
  ##   inserted line wide, goes to last at once; `none` where last does not settle.
  var held = Held()
  while result.attempts + 1 < ATTEMPTS_MAX:
    inc result.attempts
    let fix = settled(path, view, steps, held)
    if fix.isNone: break
    let wide = view.widened(fix.get)
    if wide.len == 0: return (fix, result.attempts)
    let grown = (held.lines & wide).sorted.deduplicate(isSorted = true)
    if 0 in wide or grown == held.lines: break
    held.lines = grown
  inc result.attempts
  result.fix = settled(path, view, steps, EVERY)


func formattedBy(path, source: string; steps: openArray[Step]): Fix =
  ## Run steps on source until it settles, as `formatted` does; source that does not settle stays
  ##   as written, and its fix reports why.
  let fence = source.fenceOf
  if fence.fault >= 0: return Fix(source: source)
  let fix = attempted(path, source.masked(fence), steps).fix
  if fix.isNone:
    let report = initReport(
      path,
      0,
      Rule.Unsettled,
      "File still changes after " & $ROUNDS_MAX & " rounds of fixers, so fix leaves it as " &
          "written (STYLE.md §5); got `" & $ROUNDS_MAX & "` rounds.",
    )
    return Fix(source: source, left: @[report])
  result = fix.get
  result.source = result.source.restored(source, fence)


func formatted*(path, source: string; dialect: Dialect): Fix =
  ## Run on source each fixer dialect takes, in order header gives, until source settles;
  ##   fenced lines read as `FENCED`, and fixer that would move them is skipped. Source whose
  ##   fence cannot be read stays as written, and `checkFormatting` reports why; source that does
  ##   not settle stays as written too, and its fix reports why (`Fix.left`).
  formattedBy(path, source, dialect.stepsOf)


func heldOf*(path, source: string; dialect: Dialect): seq[Report] =
  ## Report each run of fenced lines, markers included, as one warning at its first line: each
  ##   rule broken inside it, in order of `Rule`, with count and first line, so whoever runs fix
  ##   sees what fence keeps. Fence fix cannot read gives none, since `checkFormatting` reports
  ##   it alone.
  ##   Checks read source unmasked, so marker reads as plain comment and each line keeps its
  ##     number; module reads idiom checks static pass runs too. Source with no fence runs none.
  let fence = source.fenceOf
  if fence.fault >= 0 or fence.lines.len == 0: return
  var found = checksOf(path, source, dialect)
  if dialect == Dialect.Module:
    let (lines, code) = (source.splitLines, source.codeOnly.splitLines)
    found.add checkStrictFuncs(path, lines, code) & checkImports(path, code) &
      checkBindings(path, code) & checkReturns(path, code) & checkStubKeys(path, source)

  # Count each rule broken inside each run, keep its first line, and name each in `Rule` order.
  for run in fence.runsOf:
    var counts, firsts: array[Rule, int]
    for report in found:
      if report.line - 1 notin run: continue
      if counts[report.rule] == 0 or report.line < firsts[report.rule]:
        firsts[report.rule] = report.line
      inc counts[report.rule]
    var breaks: seq[string]
    for rule in Rule:
      if counts[rule] == 0: continue
      let
        verb = if breaks.len == 0: " breaks " else: " "
        times = if counts[rule] == 1: "once at line " else: $counts[rule] & " times from line "
      breaks.add rule.id & verb & times & $firsts[rule]
    let inside =
      if breaks.len == 0: "nothing inside breaks a rule"
      elif breaks.len == 1: "inside them " & breaks[0]
      else: "inside them " & breaks[0 .. ^2].join(", ") & " and " & breaks[^1]
    result.add initReport(
      path,
      run.a + 1,
      Rule.FenceHeld,
      "Fence keeps its lines as written, and " & inside & " (X.1); got lines `" & $(run.a + 1) &
        "` to `" & $(run.b + 1) & "`.",
    )
