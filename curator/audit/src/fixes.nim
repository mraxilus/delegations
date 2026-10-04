## Fix source in place where check names one mechanical fix (`koch fix`), inside branch scope.
##   Fixers reading text of one file alone are knoller's (`curator/knoller`), which runs them in
##     one chain until source settles (`formatted`); this module selects files, applies fixers
##     that need more than one file's text, hands rest to knoller, and refuses any write outside
##     scope.
##   Fix writes kind whose language has style guide alone (`KindRule.has_guide`): fixer
##     applies guide, and STYLE.md is guide of Nim alone, so Nim, NimScript and nimble are
##     written and every other kind passes through. Checks read every kind still; finding in
##     Markdown, TypeScript, YAML or shell stays for hand. Each kind of Nim is dialect of
##     knoller: `.nim` module, `.nims` script, `.nimble` package.
##   Fixer whose rule needs more than text of one file runs first, once, on source as given,
##     from what `contextOf` reads: rename of abbreviation (V.6), and to case of name's kind
##     (V.1, V.11), across files, planned whole or refused whole (`names.nim`, `rewrites.nim`),
##     one rename where both rules ask at one name; and type conversion `x.T`
##     (`conversions.nim`), each from semantic pass (`symbols.nim`); then dead export of checker
##     (`checker.nim`), whose `*` goes where its own module calls it. Fix of named files reads
##     tree whole, and rename writing file it leaves out is refused. File holding candidate
##     that compiles on no backend is left to hand, with its error.
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
##   Cost: fix reaches only what checks name; layout no check reads stays with reading.
##   Cost: `main` passes scope as merge target, so fix there writes wherever it finds rewrite.

{.experimental: "strictFuncs".}

import std/[options, sequtils, sets, strutils, tables]
import ../../knoller/src/knoller
import ./[checker, conversions, findings, glossary, kinds, layout, names, rewrites, scope, symbols]



type

  Context* = object
    ## Define what whole tree and semantic pass tell fixer of one file that its text cannot:
    ##   rule read across modules, and symbol each name resolves to.
    dead: seq[(string, string)]  ## Path and name of each export no other module names.
    answers: Table[string, Answer]  ## Semantic pass's answer for each file asked, by path.
    plans: seq[Plan]  ## Rename of each declaration coining abbreviation, planned or refused.


func dialectOf(kind: Kind): Dialect =
  ## Read dialect of knoller kind of Nim source is: module, script or package.
  case kind
  of Kind.NimScript: Dialect.Script
  of Kind.Nimble: Dialect.Package
  else: Dialect.Module


func lockedNimbles*(tree: Tree): seq[string] =
  ## Read path of each nimble file whose copy `atlas.lock` beside it holds.
  lockedNimbles(tree.mapIt((it.path, it.content)))


func checkFormatting*(path, source: string; kind: Kind): seq[Report] =
  ## Report each rule `koch fix` clears in full in source of Nim syntax, as knoller reads its
  ##   dialect (`checkFormatting` there); other kind is read by none.
  if kind.rule.syntax != Syntax.Nim: return
  checkFormatting(path, source, kind.dialectOf)


func checkFormatting*(tree: Tree): seq[Finding] =
  ## Report each rule `koch fix` clears over every file of tree; nimble file whose copy
  ##   `atlas.lock` holds is read by none.
  let locked = tree.lockedNimbles
  for e in tree:
    if e.kind.isNone or e.path in locked: continue
    result.add checkFormatting(e.path, e.content, e.kind.get).findingsOf


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


func scopeOf(tree: Tree, rename: Rename): seq[(string, string)] =
  ## Read Nim files rename may reach: declaring file alone for local binding, which no other
  ##   module names; else its project, and root files, which import across projects (`koch.nim`).
  let directory = rename.path.split('/').projectDirectory
  for e in tree:
    if not e.isNimKind: continue
    if rename.is_local and e.path != rename.path: continue
    if e.path.split('/').projectDirectory == directory or '/' notin e.path:
      result.add (e.path, e.content)


func renamesOf(
  tree: Tree, entries: openArray[Entry], locked: openArray[string]
): seq[(Rename, string)] =
  ## Read rename of each declaration in entries, as names check reads it with words glossaries
  ##   admit, and refusal known before semantic pass: coined abbreviation (V.6), and case of
  ##   name's kind (V.1, V.11), which spells abbreviation out too and takes its place.
  let directories = tree.projectDirectories
  var glossaries: seq[(string, string)]
  for e in tree:
    if e.path == ROOT_GLOSSARY or directories.anyIt(e.path == it & "/" & ROOT_GLOSSARY):
      glossaries.add (e.path, e.content)
  for e in entries:
    if not e.isNimKind or e.path in locked: continue
    let
      exempt = glossaries.exemptionsOf(e.path)
      recased = renamesCase(e.content, exempt)
    for (line, column, name, renamed) in abbreviationRenames(e.content, exempt):
      if recased.anyIt(it.line == line and it.column == column): continue
      let rename = Rename(
        path: e.path,
        line: line,
        column: column,
        name: name,
        renamed: renamed,
        rule: "abbreviation (V.6)",
      )
      result.add (rename, "")
    for r in recased:
      let rename = Rename(
        path: e.path,
        line: r.line,
        column: r.column,
        name: r.name,
        renamed: r.renamed,
        rule: r.rule,
        is_local: r.is_local,
      )
      result.add (rename, r.refusal)


func semanticQueries*(
  tree: Tree, entries: openArray[Entry], locked: openArray[string] = []
): seq[Query] =
  ## Build what fixers of entries ask semantic pass: each type conversion candidate (STYLE.md
  ##   §5), and every site of each name rename of abbreviation (V.6) or case (V.1, V.11) would
  ##   write, across its scope. File fix leaves as written, and rename refused already, ask
  ##   nothing; one query holds all one file is asked.
  var asked: seq[Query]
  for e in entries:
    if e.isNimKind and e.path notin locked: asked.add conversionQuery(e.path, e.content)
  for (rename, refusal) in renamesOf(tree, entries, locked):
    if refusal.len == 0: asked.add rename.queriesOf(tree.scopeOf(rename))
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
  ##   of each abbreviation and case in entries, refused where it would write file entries
  ##   leave out.
  var paths, sources, suites: seq[string]
  for e in tree:
    if e.path.isExporting:
      paths.add e.path
      sources.add e.content
    if e.path.isCalling: suites.add e.content
  result.dead = deadExports(paths, sources, suites).deduplicate
  for answer in answers: result.answers[answer.path] = answer
  let named = entries.mapIt(it.path)
  for (rename, refusal) in renamesOf(tree, entries, locked):
    if refusal.len > 0:
      result.plans.add Plan(rename: rename, refusal: refusal)
      continue
    let scope = tree.scopeOf(rename)
    var fenced = initTable[string, seq[int]]()
    for (path, source) in scope: fenced[path] = source.fenceOf.lines
    var plan = planRename(rename, scope, result.answers, fenced)
    for path in plan.edits.keys:
      if plan.refusal.len > 0: break
      if path notin named or path in locked:
        plan.refusal = "it would write `" & path & "`, which this fix leaves alone"
    result.plans.add plan


func fixSource(
  path, source: string; kind: Kind; fence: Fence; context: Context
): tuple[source: string, fixed: seq[Finding]] =
  ## Write edits semantic pass and tree settle, off fenced lines, then fix rest by knoller
  ##   (`formatted`); none of those edits moves line, so every report names line of source as
  ##   given.

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

  # Drop `*` of dead export, fenced lines read as `FENCED`; fix moving them is skipped.
  let dead = context.dead.filterIt(it[0] == path).mapIt(it[1])
  if dead.len > 0:
    let step = fixDeadExports(path, base.masked(fence), dead)
    if step.source.fenceShape == base.masked(fence).fenceShape:
      base = step.source.restored(base, fence)
      result.fixed.add step.fixed

  # Run chain of knoller's fixers until source settles.
  let fix = formatted(path, base, kind.dialectOf)
  result.source = fix.source
  result.fixed.add fix.fixed.findingsOf


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
      result.left.add faultOf(e.path, fence).findingsOf
      continue
    for plan in context.plans:
      if plan.rename.path != e.path or plan.refusal.len == 0: continue
      result.left.add finding(
        e.path,
        plan.rename.line,
        plan.rename.rule.capitalizeAscii & " stays for hand, since rename to `" &
          plan.rename.renamed & "` is refused: " & plan.refusal & "; got `" & plan.rename.name &
          "`.",
      )
    let entry = e.content.blockEntry
    if entry.refusal.len > 0:
      result.left.add finding(
        e.path,
        entry.bindings[0][0],
        "Entry block (V.10) stays for hand, since move into `proc main` is refused: " &
          entry.refusal & "; got `" & entry.bindings[0][1] & "`.",
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
