## Fix source in place where check names one mechanical fix (`koch fix`), inside branch scope.
##   Fixers reading text of one file alone are knoller's (`curator/knoller`), which runs them in
##     one chain until source settles (`formatted`); this module selects files, applies fixers
##     that need more than one file's text, hands rest to knoller, and refuses any write outside
##     scope.
##   Fix writes kind whose language has style guide alone (`RuleKind.has_guide`): fixer
##     applies guide, and STYLE.md is guide of Nim alone, so Nim, NimScript and nimble are
##     written and every other kind passes through. Checks read every kind still; finding in
##     Markdown, TypeScript, YAML or shell stays for hand. Each kind of Nim is dialect of
##     knoller: `.nim` module, `.nims` script, `.nimble` package.
##   Needless parentheses go where parser of project's own compiler proves it (X.4): knoller's
##     chain asks (`Fix.asked`), `provenFix` runs compiler of each pin asked once on all its
##     sources (`answered`), holds answers by path in `Context`, and fixes again each entry
##     that asked, at most `ASKS_MAX` times. Pin is that of project holding file, driver's for
##     root file, served as `resolve` of knoller serves it, so `ronri` projects read with commit
##     pin, whose glyphs 2.2.12 lexes as names. Pin nothing serves proves nothing, and run
##     prints why.
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
##     (CURATOR.md, duty 3), one line in `auditTree`; exact banners it holds, static pass reads
##     already (`form.nim`), since no project breaks them.
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
import ./[
  checker, conversions, findings, glossary, kinds, layout, names, plan, rewrites, scope, symbols,
  toolchain,
]



type

  Context* = object
    ## Define what whole tree and semantic pass tell fixer of one file that its text cannot:
    ##   rule read across modules, and symbol each name resolves to.
    dead: seq[(string, string)]  ## Path and name of each export no other module names.
    answers: Table[string, Answer]  ## Semantic pass's answer for each file asked, by path.
    plans: seq[Plan]  ## Rename of each declaration coining abbreviation, planned or refused.
    proofs: Table[string, Proofs]  ## Answers of parser of project's compiler, by path.

  Fixed* = tuple
    ## Define what fix of entries writes and reports, and what it asks parser.
    written: seq[Entry]  ## Entry to write, with new text.
    fixed, refused, left: seq[Finding]  ## Rewrite, scope finding, finding left.
    warned: seq[Finding]  ## Warning: fence that keeps its lines, or file fixers do not settle.
    asked: seq[(string, string)]  ## Path and source chain asks parser, no answer held yet.


const ASKS_MAX = 8
  ## Rounds of asking parser at most, as knoller's command line takes (`command.nim`).


func nimblesLocked*(tree: Tree): seq[string] =
  ## Read path of each nimble file whose copy `atlas.lock` beside it holds.
  nimblesLocked(tree.mapIt((it.path, it.content)))


func checkFormatting*(path, source: string; kind: Kind): seq[Report] =
  ## Report each rule `koch fix` clears in full in source of Nim syntax, as knoller reads its
  ##   dialect (`checkFormatting` there); other kind is read by none.
  if kind.rule.syntax != Syntax.Nim: return
  checkFormatting(path, source, kind.dialectOf)


func checkFormatting*(tree: Tree): seq[Finding] =
  ## Report each rule `koch fix` clears over every file of tree; nimble file whose copy
  ##   `atlas.lock` holds is read by none.
  let locked = tree.nimblesLocked
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


func isKindNim(e: Entry): bool =
  ## Decide whether entry is of kind fix writes: Nim, NimScript or nimble.
  e.kind.isSome and e.kind.get.rule.has_guide


func scopeOf(tree: Tree, rename: Rename): seq[(string, string)] =
  ## Read Nim files rename may reach: declaring file alone for local binding, which no other
  ##   module names; else its project, and root files, which import across projects (`koch.nim`).
  let directory = rename.path.split('/').directoryProject
  for e in tree:
    if not e.isKindNim: continue
    if rename.is_local and e.path != rename.path: continue
    if e.path.split('/').directoryProject == directory or '/' notin e.path:
      result.add (e.path, e.content)


func renamesOf(
  tree: Tree, entries: openArray[Entry], locked: openArray[string]
): seq[(Rename, string)] =
  ## Read rename of each declaration in entries, as names check reads it with words glossaries
  ##   admit, and refusal known before semantic pass: coined abbreviation (V.6), and case of
  ##   name's kind (V.1, V.11), which spells abbreviation out too and takes its place.
  let directories = tree.directoriesProject
  var glossaries: seq[(string, string)]
  for e in tree:
    if e.path == GLOSSARY_ROOT or directories.anyIt(e.path == it & "/" & GLOSSARY_ROOT):
      glossaries.add (e.path, e.content)
  for e in entries:
    if not e.isKindNim or e.path in locked: continue
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


func queriesSemantic*(
  tree: Tree, entries: openArray[Entry], locked: openArray[string] = []
): seq[Query] =
  ## Build what fixers of entries ask semantic pass: each type conversion candidate (STYLE.md
  ##   §5), and every site of each name rename of abbreviation (V.6) or case (V.1, V.11) would
  ##   write, across its scope. File fix leaves as written, and rename refused already, ask
  ##   nothing; one query holds all one file is asked.
  var asked: seq[Query]
  for e in entries:
    if e.isKindNim and e.path notin locked: asked.add queryConversion(e.path, e.content)
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
  result.dead = exportsDead(paths, sources, suites).deduplicate
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


func unsettledOf*(path: string, fix: Fix): seq[Finding] =
  ## Warn that knoller's fixers leave source as written, since they do not settle it: message
  ##   knoller gives (`Fix.unsettled`), whole file, and no article, since fault is tool's and
  ##   no rule of style; none where source settles. `koch fix` prints it after `warning:`.
  if fix.unsettled.len > 0: result.add finding(path, 0, fix.unsettled)


func fixSource(
  path, source: string; kind: Kind; fence: Fence; context: Context
): tuple[source: string, fixed, warned: seq[Finding], asked: seq[string]] =
  ## Write edits semantic pass and tree settle, off fenced lines, then fix rest by knoller
  ##   (`formatted`); none of those edits moves line, so every report names line of source as
  ##   given. Source knoller cannot settle keeps those edits alone, with warning that says why
  ##   (`unsettledOf`), since rename planned whole reaches other files too.

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
    let step = fixExportsDead(path, base.masked(fence), dead)
    if step.source.shapeFence == base.masked(fence).shapeFence:
      base = step.source.restored(base, fence)
      result.fixed.add step.fixed

  # Run chain of knoller's fixers until source settles; unsettled source keeps edits above.
  let fix = formatted(path, base, kind.dialectOf, context.proofs.getOrDefault(path))
  result.source = fix.source
  result.asked = fix.asked
  result.fixed.add fix.fixed.findingsOf
  result.warned = path.unsettledOf(fix)


func partOf(e: Entry; locked: openArray[string]; context: Context): Fixed =
  ## Fix one entry as `fixEntries` does, scope left unread.
  if e.kind.isNone or not e.kind.get.rule.has_guide: return
  if e.path in locked:
    result.left.add finding(
      e.path,
      0,
      "Nimble file whose copy `" & FILE_LOCK & "` holds stays as written; got its copy there.",
    )
    return
  let fence = e.content.fenceOf
  if fence.fault >= 0:
    result.left.add faultOf(e.path, fence).findingsOf
    return
  let proofs = context.proofs.getOrDefault(e.path)
  result.warned.add heldOf(e.path, e.content, e.kind.get.dialectOf, proofs).findingsOf
  if fence.lines.len > 0:
    for source in e.content.questionsOf(proofs): result.asked.add (e.path, source)
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
  for source in fix.asked:
    if (e.path, source) notin result.asked: result.asked.add (e.path, source)
  result.warned.add fix.warned
  if fix.source == e.content: return
  result.written.add Entry(path: e.path, kind: e.kind, content: fix.source)
  result.fixed.add fix.fixed


func scoped(branch: string; parts: openArray[Fixed]): Fixed =
  ## Join parts of entries; where any path to write lies outside branch scope, nothing is
  ##   written or reported fixed.
  for part in parts:
    result.written.add part.written
    result.fixed.add part.fixed
    result.left.add part.left
    result.warned.add part.warned
    result.asked.add part.asked
  if result.written.len == 0: return
  result.refused = checkScope(branch, result.written.mapIt(it.path))
  if result.refused.len > 0:
    result.written.setLen(0)
    result.fixed.setLen(0)


func fixEntries*(
  branch: string, entries: openArray[Entry], locked: openArray[string] = [], context = Context()
): Fixed =
  ## Fix each entry: entries to write, one report per rewrite, scope findings, files left as
  ##   written with reason (nimble file `locked` names, fence fix cannot read), and one warning
  ##   for each fence, which keeps its lines as written, naming each rule broken among them
  ##   (`heldOf`), and for each file knoller's fixers do not settle (`unsettledOf`). `context`
  ##   carries what tree tells fixers across modules (`contextOf`), and answers of parser; each
  ##   source chain asks and no answer holds is in `asked`, source as given too where fence
  ##   holds lines, since its warning reads it.
  ##   Where any path to write lies outside branch scope, nothing is written or reported fixed.
  scoped(branch, entries.mapIt(it.partOf(locked, context)))


func pinFor(tree: Tree, path: string): string =
  ## Read pin of project holding path, driver's for file at root; empty where none is pinned.
  let directory = path.split('/').directoryProject
  tree.pinOf(if directory.len == 0: DIRECTORY_DRIVER else: directory).get("")


proc answered*(
  context: var Context; tree: Tree; asked: openArray[(string, string)]; provers: ProverOf
): seq[string] =
  ## Ask parser of each pin what `asked` holds and no answer holds yet, one run for each pin on
  ##   all its sources, and hold answers by path; return why each run proved nothing, empty
  ##   where all answered. Path of no pin is answered none, with reason.
  var
    pins: seq[string]
    questions: seq[seq[(string, string)]]
  for (path, source) in asked:
    if source in context.proofs.getOrDefault(path).answers: continue
    let pin = tree.pinFor(path)
    var k = pins.find(pin)
    if k < 0:
      pins.add pin
      questions.add @[]
      k = pins.high
    if (path, source) notin questions[k]: questions[k].add (path, source)
  for k, pin in pins:
    let
      sources = questions[k].mapIt(it[1]).deduplicate
      proving =
        if pin.len == 0:
          Proving(
            answers: newSeq[seq[int]](sources.len),
            failure: "Parser proved no removal, since project pins no compiler; got `" &
              questions[k][0][0] & "`.",
          )
        else: provers(pin)(sources)
    for (path, source) in questions[k]:
      context.proofs.mgetOrPut(path, Proofs()).answers[source] =
        proving.answers[sources.find(source)]
    if proving.failure.len > 0 and proving.failure notin result: result.add proving.failure


proc provenFix*(
  branch: string;
  tree: Tree;
  entries: openArray[Entry];
  locked: openArray[string];
  context: Context;
  provers: ProverOf,
): tuple[fix: Fixed, failures: seq[string]] =
  ## Fix entries as `fixEntries` does, ask parser of each pin what fix asked, and fix again, at
  ##   most `ASKS_MAX` times; each run that proved nothing gives one failure, for warning, led
  ##   by rule id: `needless-parentheses: <message>`.
  ##   Entry that asked nothing read only sources answered, and answer once held never changes,
  ##   so each round fixes again only entries that asked.
  var
    known = context
    parts = entries.mapIt(it.partOf(locked, known))
  for ask in 1 .. ASKS_MAX:
    let asked = parts.mapIt(it.asked).concat
    if asked.len == 0: break
    for failure in known.answered(tree, asked, provers):
      let line = Rule.NeedlessParentheses.id & ": " & failure
      if line notin result.failures: result.failures.add line
    for k, e in entries:
      if parts[k].asked.len > 0: parts[k] = e.partOf(locked, known)
  result.fix = scoped(branch, parts)
