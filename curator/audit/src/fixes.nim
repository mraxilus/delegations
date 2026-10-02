## Fix source in place where check names one mechanical fix (`koch fix`), inside branch scope.
##   Built from checks (Article II.1): each fixer sits beside its check, in `form.nim` and
##     `idioms.nim`, and reads that check's own data, so each rule is written once. This module
##     selects files, runs on each file fixers its kind's checks name, and refuses any write
##     outside scope.
##   Fix writes kind whose language has style guide alone (`KindRule.has_guide`): fixer
##     applies guide, and STYLE.md is guide of Nim alone, so Nim, NimScript and nimble are
##     written and every other kind passes through. Checks read every kind still; finding in
##     Markdown, TypeScript, YAML or shell stays for hand.
##   Inside that reach, fixer runs where its check runs: form fixers on every Nim kind, idiom
##     fixers on `.nim` alone. Form runs first, so idiom fixers read clean line ends.
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
##   Cost: fix reaches only what checks name; layout no check reads stays with reading.
##   Cost: `main` passes scope as merge target, so fix there writes wherever it finds rewrite.

{.experimental: "strictFuncs".}

import std/[options, sequtils, sets, strutils]
import ./[findings, form, idioms, kinds, layout, scope]


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


func fixSource(path, source: string, kind: Kind): Fix =
  ## Run on source each fixer its kind's checks name, form first; kind without guide passes.
  result.source = source
  if not kind.rule.has_guide: return
  result = fixForm(path, source, kind.rule)
  if kind == Kind.Nim: result = result.chain(fixIdioms(path, result.source))


func fixEntries*(
    branch: string, entries: openArray[Entry]
): tuple[written: seq[Entry], fixed, refused: seq[Finding]] =
  ## Fix each entry: entries to write, one report per rewrite, scope findings.
  ##   Where any path to write lies outside branch scope, nothing is written or reported fixed.
  for e in entries:
    if e.kind.isNone: continue
    let fix = fixSource(e.path, e.content, e.kind.get)
    if fix.source == e.content: continue
    result.written.add Entry(path: e.path, kind: e.kind, content: fix.source)
    result.fixed.add fix.fixed
  if result.written.len == 0: return
  result.refused = checkScope(branch, result.written.mapIt(it.path))
  if result.refused.len > 0:
    result.written.setLen(0)
    result.fixed.setLen(0)
