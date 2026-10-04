## Fix Nim source by every fixer of knoller, in one order, until it settles; and report each
##   rule those fixers clear (`checkFormatting`).
##   Built from checks (Article II.1): each fixer sits beside its check and reads that check's
##     own data, so each rule is written once.
##   Fixer runs where its check runs: idiom fixers on module (`.nim`) alone, every other fixer
##     in every dialect. Order keeps each fixer from undoing one before it:
##   - form first (whitespace, ending, tab in string, trailing comment, banner), so later
##     fixers read clean line ends and final comment gaps, which wrapping counts in width;
##   - entry block next, whose body moves into `proc main` (V.10): it moves lines and widens
##     none, so every later fixer reads body where it stands;
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
##   Chain runs again until it changes nothing, at most `ROUNDS_MAX` times: line wrapping
##     splits can take spacing fixer refused for width, so second round writes it, and
##     `koch fix` run twice writes nothing second time.
##   Nimble file whose copy `atlas.lock` holds (`nimbleFile`, `lockedNimbles`) is left to
##     caller, which writes none of it and checks none of it: rewrite would leave lock's copy
##     stale, and Atlas reads that as change of package.
##
##   Rejected: nimpretty, which sets one space before trailing comment where X.9 asks two,
##     and `;` between parameters where STYLE.md §5 asks `,`; fork of nimpretty's layouter,
##     second formatter whose layout rules would drift from checks; AST printer, which loses
##     comment placement and every layout hand chose. Each holds rule twice: as check, and as
##     layout.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils]
import ./[
  alignment, articles, blanks, declarations, entry, fences, form, idioms, messages, precedence,
  reports, spacing, targets, wrapping,
]


const
  ROUNDS_MAX = 3
    ## Rounds of whole chain at most; tree settles in two (`curator/audit/PROVENANCE.md`, Fixes).
  LOCK_FILE* = "atlas.lock"  ## Lock holding copy of project's nimble file.
  NIMBLE_KEY = "\"nimbleFile\""  ## Key of lock's copy of nimble file, whose `filename` names it.


type Dialect* {.pure.} = enum  ## Define which Nim source file holds, which decides fixers it takes.
  Module  ## `.nim`, which idiom fixers read too.
  Script  ## `.nims`.
  Package  ## `.nimble`.


func fixersOf(dialect: Dialect): seq[Fixer] =
  ## List fixers dialect takes, in order header gives.
  result = @FORM_FIXERS
  result.add fixBlockEntry
  result.add @[Fixer(fixArticles), fixAlignment, fixMessages, fixMixtures, fixTargets]
  if dialect == Dialect.Module: result.add IDIOM_FIXERS
  result.add @[Fixer(fixBlanks), fixDocs, fixDefaults, fixSpacing]
  result.add WRAPPING_FIXERS


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


func checkFormatting*(path, source: string; dialect: Dialect): seq[Report] =
  ## Report each rule `koch fix` clears in full that static pass leaves out until projects fix,
  ##   and X.4 `not` over binary expression, which waits with them and has no fixer.
  ##   In every dialect: X.9 trailing comments and spaces, X.2 banners, I.4 tables, IV.4
  ##   messages, X.4 conditions, STYLE.md §5 `to<Target>` calls, suites and tests, STYLE.md §1
  ##   helpers, doc position, X.12 defaults, and X.3 and STYLE.md §5 separators, signatures,
  ##   calls and trailing separators.
  ##   On `.nim` alone, as idiom checks read it: X.5 import brackets, X.10 lists and STYLE.md
  ##   §3 profiler import. Fenced lines are read by none, and fence fix cannot read is reported
  ##   alone.
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
  if dialect == Dialect.Module:
    result.add checkImportBrackets(path, view) & checkLists(path, view) & checkProfiler(path, view)
  result = result.filterIt(it.line - 1 notin fence.lines)


func formatted*(path, source: string; dialect: Dialect): Fix =
  ## Run on source each fixer dialect takes, in order header gives, until source settles;
  ##   fenced lines read as `FENCED`, and fixer that would move them is skipped. Source whose
  ##   fence cannot be read stays as written, and `checkFormatting` reports why.
  let fence = source.fenceOf
  if fence.fault >= 0: return Fix(source: source)
  result.source = source.masked(fence)
  let shape = result.source.fenceShape
  for round in 1 .. ROUNDS_MAX:
    var step = Fix(source: result.source)
    for fixer in dialect.fixersOf:
      let next = fixer(path, step.source)
      if next.source.fenceShape != shape: continue
      step = step.chain(next)
    if step.source == result.source: break
    result = result.chain(step)
  result.source = result.source.restored(source, fence)
