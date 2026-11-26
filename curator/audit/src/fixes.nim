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
##     chain asks (`Fix.asked`), `fixProven` runs compiler of each pin asked once on all its
##     sources (`answered`), holds answers by path in `Context`, and fixes again each entry
##     that asked, at most `ASKS_MAX` times. Pin is that of project holding file, driver's for
##     root file, served as `resolve` of knoller serves it, so each project reads with grammar
##     of its pin: 2.2.12 lexes as names glyphs that 2.4.0 lexes as operators. Pin nothing
##     serves proves nothing, and run prints why.
##   Fixer whose rule needs more than text of one file runs first, once, on source as given,
##     from what `initContext` reads: rename of abbreviation (V.6), to case of name's kind
##     (V.1, V.11), and to cut of V.2 that words of project decide (`cuts.nim`), across files,
##     planned whole or refused whole (`names.nim`, `rewrites.nim`), one rename where several
##     rules ask at one name; type conversion `x.T` (`conversions.nim`), each from semantic pass
##     (`symbols.nim`); alias of each landmark index (V.8), from names of project
##     (`packages.nim`); marker of each private symbol sibling reaches, and drop of each
##     `{.all.}` reaching none (STYLE.md §5), from uses compiler reads (`markers.nim`); `func` of
##     each `proc` compiler proves pure (STYLE.md §1, `purity.nim`); then dead export of checker
##     (`checker.nim`), whose `*` goes where its own module calls it. Marker moves trailing doc
##     to next line, so each later report traces back to line as given. Fix of named files reads
##     tree whole, and rename writing file it leaves out is refused. File holding candidate that
##     compiles on no backend is left to hand, with its error.
##   Nimble file whose copy `atlas.lock` holds (`nimbleFile`) is never written, and layout
##     checks read none of it: rewrite would leave lock's copy stale, and Atlas reads that as
##     change of package.
##   File of project whose prose stays in its own language takes no fixer of articles, and its
##     fence warning counts none (`prose_own.nim`). Knoller takes that as mode of each file
##     (`should_drop_articles`), since list is policy of this repository, which knoller holds none
##     of.
##   Knoller reads tests, stubs and umbrella from nimble file nearest each file, and its caller
##     finds that file; koch gives that of project holding it (`nimbleProject`).
##   Knoller reads what other modules of project tell fixer of one file, and `initContext` reads
##     it over tree by project: whether file declares `formatValue`, constants each module
##     exports, defaults of configurations, and names of its modules, with aliases of library
##     it builds on, which no file of tree holds, so caller reads library from disk.
##   Uses of private symbols and pure routines come from compiler, and library from disk:
##     `readFacts` reads them under root through readers of knoller's command line
##     (`resolveMarkers`, `resolvePures`, `modulesLibrary`), so both read alike, and koch passes
##     them to `initContext`, as it passes answers of semantic pass.
##   Finding of rule resting on context that fix leaves stays for hand, as knoller's command line
##     leaves it: marker and `func` no edit writes, index whose alias no edit writes, and call
##     of constructor, which no fix writes (STYLE.md §5). Fenced line of rule reading names
##     counts in warning of its fence, which reads names too; file whose uses or pures compiler
##     resolved none warns, with reason.
##   Knoller reads fixed waits where its caller says file is drive code, and koch says so of
##     `tests/` and `tools/` of each project (`waits.isCodeDrive`), so fence warning counts them
##     where static pass reads them.
##   `checkFormatting` holds every check whose findings these fixers clear and static pass
##     does not run yet; pull request wiring its tree form, one line in `auditTree`, lands once
##     rest of tree is clean (CURATOR.md, duty 3); exact banners it holds, static pass reads
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

import std/[algorithm, options, os, sequtils, sets, strutils, tables]
import ../../knoller/src/knoller
from ../../knoller/src/knoller/command import modulesLibrary, resolveMarkers, resolvePures
import ./[
  checker, findings, glossary, kinds, layout, names, plan, prose_own, scope, symbols, toolchain,
  waits,
]



type

  Context* = object
    ## Define what whole tree and semantic pass tell fixer of one file that its text cannot:
    ##   rule read across modules, and symbol each name resolves to.
    dead: seq[(string, string)]  ## Path and name of each export no other module names.
    answers: Table[string, Answer]  ## Semantic pass's answer for each file asked, by path.
    plans: seq[Plan]  ## Rename of each declaration coining abbreviation, planned or refused.
    proofs: Table[string, Proofs]  ## Answers of parser of project's compiler, by path.
    formatting: seq[string]
      ## Nimble file of each project declaring `formatValue`, whose interpolated strings never join.
    configurations: Table[string, Configurations]
      ## Defaults of configurations of each project, read from its modules, by nimble file.
    constants: Table[string, seq[string]]
      ## Constants modules of each project export, read as fixed by build, by nimble file.
    names: Table[string, NamesPackage]
      ## Names of each project, aliases of library it builds on among them, by nimble file.
    uses: Table[string, Uses]  ## Use of each private symbol and `{.all.}` of each file, by path.
    pures: Table[string, Pures]  ## Each `proc` compiler checks as `func` in each file, by path.

  Fixed* = tuple
    ## Define what fix of entries writes and reports, and what it asks parser.
    written: seq[Entry]  ## Entry to write, with new text.
    fixed, refused, left: seq[Finding]  ## Rewrite, scope finding, finding left.
    warned: seq[Finding]
      ## Warning: fence that keeps its lines, debug output, or file fixers do not settle.
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
  checkFormatting(
    path,
    source,
    kind.dialect,
    nimble = path.nimbleProject,
    should_drop_articles = not path.isProseOwn,
  )


func checkFormatting*(tree: Tree): seq[Finding] =
  ## Report each rule `koch fix` clears over every file of tree; nimble file whose copy
  ##   `atlas.lock` holds is read by none.
  let locked = tree.nimblesLocked
  for e in tree:
    if e.kind.isNone or e.path in locked: continue
    result.add checkFormatting(e.path, e.content, e.kind.get).toFindings


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
      result.unknown.add finding(
        path,
        0,
        Check.NameUnknown,
        "Name matches no file git lists; got `" & name & "`.",
      )


func isKindNim(e: Entry): bool =
  ## Decide whether entry is of kind fix writes: Nim, NimScript or nimble.
  e.kind.isSome and e.kind.get.rule.has_guide


func scopeRename(tree: Tree, rename: Rename): seq[(string, string)] =
  ## Read Nim files rename may reach: declaring file alone for local binding, which no other
  ##   module names; else its project, and root files, which import across projects (`koch.nim`).
  let directory = rename.path.split('/').directoryProject
  for e in tree:
    if not e.isKindNim: continue
    if rename.is_local and e.path != rename.path: continue
    if e.path.split('/').directoryProject == directory or '/' notin e.path:
      result.add (e.path, e.content)


func namesProjects(
  tree: Tree, libraries = initTable[string, seq[string]]()
): Table[string, NamesPackage] =
  ## Read names of each project from its `.nim` modules (`namesPackage`), and aliases of library
  ##   it builds on too, as `libraries` holds its modules, by nimble file; empty name stands for
  ##   files at root, which lie in no project.
  var modules: Table[string, seq[string]]
  for e in tree:
    if e.path.endsWith(".nim"): modules.mgetOrPut(e.path.nimbleProject, @[]).add e.content
  for project, sources in modules:
    result[project] = namesPackage(sources, libraries.getOrDefault(project))


func renames(
  tree: Tree,
  entries: openArray[Entry],
  locked: openArray[string],
  names: Table[string, NamesPackage],
): seq[(Rename, string)] =
  ## Read rename of each declaration in entries, as names check reads it with words glossaries
  ##   admit, and refusal known before semantic pass: coined abbreviation (V.6), case of name's
  ##   kind (V.1, V.11), which spells abbreviation out too and takes its place, and name cut
  ##   (V.2), from axis values and words of project (`names`), which joins case rename of same
  ##   declaration into one rename of rule of case (`composed`).
  let directories = tree.directoriesProject
  var glossaries: seq[(string, string)]
  for e in tree:
    if e.path == GLOSSARY_ROOT or directories.anyIt(e.path == it & "/" & GLOSSARY_ROOT):
      glossaries.add (e.path, e.content)
  for e in entries:
    if not e.isKindNim or e.path in locked: continue
    let
      exempt = glossaries.exemptions(e.path)
      package = names.getOrDefault(e.path.nimbleProject)
      recased = renamesCase(e.content, exempt).composed(
        renamesCut(e.content, package.axes, package.words, exempt),
      )
    for (line, column, name, renamed) in renamesAbbreviation(e.content, exempt):
      if recased.anyIt(it.line == line and it.column == column): continue
      let rename = Rename(
        path: e.path,
        line: line,
        column: column,
        name: name,
        renamed: renamed,
        rule: Rule.Abbreviation,
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
  ##   §5), and every site of each name rename of abbreviation (V.6), case (V.1, V.11) or cut
  ##   (V.2) would write, across its scope; cut reads names of project from tree, as library adds
  ##   no axis value or word. File fix leaves as written, and rename refused already, ask
  ##   nothing; one query holds all one file is asked.
  var asked: seq[Query]
  for e in entries:
    if e.isKindNim and e.path notin locked: asked.add queryConversion(e.path, e.content)
  for (rename, refusal) in renames(tree, entries, locked, tree.namesProjects):
    if refusal.len == 0: asked.add rename.queries(tree.scopeRename(rename))
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


proc checkConversions*(
  root: string, tree: Tree, directories: openArray[string]
): tuple[found: seq[Finding], warned: seq[Finding]] =
  ## Report each type conversion `x.T` in Nim files under directories, as semantic pass settles
  ##   it (STYLE.md §5), so check reports what fix rewrites (D1 of #558). File holding no
  ##   candidate asks nothing; file pass cannot resolve warns at its path, with reason and no
  ##   article, under rule `type-conversion`, and finds nothing.
  var queries: seq[Query]
  for e in tree:
    if not e.isKindNim or not directories.anyIt(e.path.startsWith(it & "/")): continue
    let query = queryConversion(e.path, e.content)
    if query.sites.len > 0: queries.add query
  for answer in resolve(root, tree, queries):
    if answer.reason.len > 0:
      result.warned.add finding(
        answer.path,
        0,
        "Type conversion stays unread, since semantic pass resolved no name; got `" &
          answer.reason & "`.",
        rule = Rule.Conversion.id,
      )
      continue
    for e in tree:
      if e.path == answer.path:
        result.found.add checkConversions(e.path, e.content, answer).toFindings


proc readFacts*(
  root: string, entries: openArray[Entry], locked: openArray[string] = []
): tuple[
  uses: Table[string, Uses], pures: Table[string, Pures], libraries: Table[string, seq[string]]
] =
  ## Read, from disk under root, what fixers of entries ask beyond semantic pass of
  ##   `queriesSemantic`, through knoller's own readers, so `koch fix` reads them as command
  ##   line does: use of each private symbol and `{.all.}` (`resolveMarkers`), and each `proc`
  ##   compiler checks as `func` (`resolvePures`), by path; and modules of library each project
  ##   builds on, under each `--path` of `nim.cfg` beside its nimble file (`modulesLibrary`), by
  ##   nimble file. Each reads project of file as git lists it there, with no define, as command
  ##   line names none; file at root lies in no project, so it asks none, as nimble file
  ##   `locked` names asks none.
  let
    absolute = root.absolutePath
    files = entries.filterIt(
      it.isKindNim and it.path notin locked and it.path.nimbleProject.len > 0,
    ).mapIt((it.path, it.content))
  var toolchains = initToolchains()
  result.uses = files.resolveMarkers("", absolute, toolchains)
  result.pures = files.resolvePures("", absolute, toolchains)
  var nimbles = initTable[string, string]()  # Absolute path of each nimble file, by tree's.
  for (path, _) in files: nimbles[path.nimbleProject] = absolute / path.nimbleProject
  let libraries = nimbles.modulesLibrary
  for nimble, path in nimbles:
    if path in libraries: result.libraries[nimble] = libraries[path]


func initContext*(
  tree: Tree,
  entries: openArray[Entry] = [],
  answers: openArray[Answer] = [],
  locked: openArray[string] = [],
  uses = initTable[string, Uses](),
  pures = initTable[string, Pures](),
  libraries = initTable[string, seq[string]](),
): Context =
  ## Read what tree and semantic pass tell fixers: dead exports of checker, as static pass reads
  ##   them from its modules, `koch.nim` and its suites; answer of each file asked; and rename
  ##   of each abbreviation, case and cut in entries, refused where it would write file entries
  ##   leave out; and, by project, each file declaring `formatValue`, constants its modules export,
  ##   defaults of its configurations, and names of its modules (`namesProjects`), aliases of
  ##   library it builds on among them, as `libraries` holds its modules by nimble file.
  ##   Use of each private symbol and `{.all.}` of each file, and each `proc` compiler checks as
  ##   `func` there, as `uses` and `pures` hold them by path (`readFacts`), pass through.
  var paths, sources, suites: seq[string]
  for e in tree:
    if e.path.isExporting:
      paths.add e.path
      sources.add e.content
    if e.path.isCalling: suites.add e.content
  result.dead = exportsDead(paths, sources, suites).deduplicate
  var modules: Table[string, seq[string]]
  for e in tree:
    if not e.path.endsWith(".nim"): continue
    if e.content.isDeclaringFormatValue: result.formatting.add e.path.nimbleProject
    modules.mgetOrPut(e.path.nimbleProject, @[]).add e.content
  for project, sources in modules:
    result.configurations[project] = readConfigurations(sources)
    result.constants[project] = sources.mapIt(it.constantsExported).concat
  result.names = tree.namesProjects(libraries)
  result.uses = uses
  result.pures = pures
  for answer in answers: result.answers[answer.path] = answer
  let named = entries.mapIt(it.path)
  for (rename, refusal) in renames(tree, entries, locked, result.names):
    if refusal.len > 0:
      result.plans.add Plan(rename: rename, refusal: refusal)
      continue
    let scope = tree.scopeRename(rename)
    var fenced = initTable[string, seq[int]]()
    for (path, source) in scope: fenced[path] = source.fence.lines
    var plan = planRename(rename, scope, result.answers, fenced)
    for path in plan.edits.keys:
      if plan.refusal.len > 0: break
      if path notin named or path in locked:
        plan.refusal = "it would write `" & path & "`, which this fix leaves alone"
    result.plans.add plan


func warnUnsettled*(path: string, fix: Fix): seq[Finding] =
  ## Warn that knoller's fixers leave source as written, since they do not settle it: message
  ##   knoller gives (`Fix.unsettled`), whole file, and no article, since fault is tool's and
  ##   no rule of style; none where source settles. `koch fix` prints it after `warning:`.
  if fix.unsettled.len > 0: result.add finding(path, 0, fix.unsettled)


func fixSource(
  path, source: string; kind: Kind; fence: Fence; context: Context
): tuple[source: string, fixed, left, warned: seq[Finding], asked: seq[string]] =
  ## Write edits semantic pass, compiler and tree settle, off fenced lines, then fix rest by
  ##   knoller (`formatted`); every report names line of source as given, traced through marker
  ##   that moves trailing doc to next line (`originApplied`), then through chain. Report of rule
  ##   resting on context that no edit writes is left for hand: marker, `func`, and rule reading
  ##   names of project off fenced lines, which warning of fence counts. Source knoller cannot
  ##   settle keeps those edits alone, with warning that says why (`warnUnsettled`), since rename
  ##   planned whole reaches other files too.

  # Write edits semantic pass, names of project and compiler settle, off fenced lines, as
  #   knoller's command line writes them: renames, conversions, alias of each landmark index,
  #   then markers and `func`; marker moving trailing doc to next line alone moves line.
  var semantic: seq[Edit]
  for plan in context.plans:
    if plan.refusal.len > 0 or path notin plan.edits: continue
    semantic.add plan.edits[path]
    for (file, line) in plan.lines:
      if file == path: result.fixed.add initReport(path, line, plan.rename.rule).toFinding
  if path in context.answers:
    let (edits, reports) =
      editsConversion(path, source, context.answers[path], fence.lines, semantic)
    semantic.add edits
    result.fixed.add reports.toFindings
  let
    names = context.names.getOrDefault(path.nimbleProject)
    (aliased, aliasing) = editsLandmark(path, source, names.landmarks, fence.lines, semantic)
  semantic.add aliased
  result.fixed.add aliasing.toFindings
  let
    uses = context.uses.getOrDefault(path)
    (marks, marked) = editsMarkers(path, source, uses, fence.lines, semantic)
  semantic.add marks
  let
    pures = context.pures.getOrDefault(path)
    (funcs, purified) = editsPure(path, source, pures, fence.lines, semantic)
  semantic.add funcs
  result.fixed.add toFindings(marked & purified)

  # Leave for hand each marker and `func` no edit writes, each index alias edits leave, as
  #   choice of aliases, and each call of constructor, which no fix writes, in order of lines.
  #   Edit of marker or `func` answers one report of its rule on its line; index is read again
  #   from source alias edits wrote, which keeps its lines, as knoller reads what fixers leave.
  #   Fence warning counts fenced report of rule reading names, and reads no uses or pures.
  var
    unwritten = (marked & purified).mapIt((it.line, it.rule))
    kept: seq[Report]
  for report in checkMarkers(path, source, uses) & checkPure(path, source, pures) &
      checkLandmarks(path, source.applied(aliased), names.landmarks) &
      checkConstructors(path, source, names.calls):
    let
      at = unwritten.find((report.line, report.rule))
      is_warned = report.rule notin {Rule.UsedMarker, Rule.PureFunc} and
          report.line - 1 in fence.lines
    if at >= 0: unwritten.delete at
    elif not is_warned: kept.add report
  result.left = kept.sortedByIt(it.line).toFindings

  # Drop `*` of dead export, fenced lines read as `FENCED`; fix moving them is skipped. Fence
  #   reads edited source, whose lines marker may move, and each report traces back.
  var base = Fix(source: source.applied(semantic), origin: source.originApplied(semantic))
  let dead = context.dead.filterIt(it[0] == path).mapIt(it[1])
  if dead.len > 0:
    let
      fenced = base.source.fence
      masked = base.source.masked(fenced)
      step = fixExportsDead(path, masked, dead)
    if step.source.shapeFence == masked.shapeFence:
      base.source = step.source.restored(base.source, fenced)
      for f in step.fixed:
        var traced = f
        traced.line = base.traced(f.line)
        result.fixed.add traced

  # Run chain of knoller's fixers until source settles; unsettled source keeps edits above.
  #   Articles stay in file of project keeping its own prose (`isProseOwn`), and interpolated
  #   strings stay split in project declaring `formatValue`.
  let fix = base.chain(
    formatted(
      path,
      base.source,
      kind.dialect,
      context.proofs.getOrDefault(path),
      should_drop_articles = not path.isProseOwn,
      nimble = path.nimbleProject,
      has_format_value = path.nimbleProject in context.formatting,
      configurations = context.configurations.getOrDefault(path.nimbleProject),
      constants = context.constants.getOrDefault(path.nimbleProject),
    ),
  )
  result.source = fix.source
  result.asked = fix.asked
  result.fixed.add fix.fixed.toFindings
  result.warned = warnUnsettled(path, fix)


func fixEntry(e: Entry; locked: openArray[string]; context: Context): Fixed =
  ## Fix one entry as `fixEntries` does, scope left unread.
  if e.kind.isNone or not e.kind.get.rule.has_guide: return
  if e.path in locked:
    result.left.add finding(
      e.path,
      0,
      Check.NimbleLocked,
      "Nimble file whose copy `" & FILE_LOCK & "` holds stays as written; got its copy there.",
    )
    return
  let fence = e.content.fence
  if fence.fault >= 0:
    result.left.add checkFence(e.path, fence).toFindings
    return
  let proofs = context.proofs.getOrDefault(e.path)
  result.warned.add checkFenceHeld(
    e.path,
    e.content,
    e.kind.get.dialect,
    proofs,
    should_drop_articles = not e.path.isProseOwn,
    nimble = e.path.nimbleProject,
    is_drive = e.path.isCodeDrive,
    configurations = context.configurations.getOrDefault(e.path.nimbleProject),
    constants = context.constants.getOrDefault(e.path.nimbleProject),
    names = context.names.getOrDefault(e.path.nimbleProject),
  ).toFindings
  result.warned.add warnDebug(e.path, e.content, e.path.nimbleProject).toFindings
  let uses = context.uses.getOrDefault(e.path)
  if uses.reason.len > 0:
    result.warned.add initReport(
      e.path,
      0,
      Rule.UsedMarker,
      "Semantic pass resolved no use, so each private symbol and `{.all.}` stays as written; " &
      "got `" & uses.reason & "`.",
    ).toFinding
  let pures = context.pures.getOrDefault(e.path)
  if pures.reason.len > 0:
    result.warned.add initReport(
      e.path,
      0,
      Rule.PureFunc,
      "Compiler proved no routine pure, so each `proc` stays as written; got `" & pures.reason &
      "`.",
    ).toFinding
  if fence.lines.len > 0:
    for source in e.content.questions(proofs): result.asked.add (e.path, source)
  for plan in context.plans:
    if plan.rename.path != e.path or plan.refusal.len == 0: continue
    result.left.add finding(
      e.path,
      plan.rename.line,
      ($plan.rename.rule).capitalizeAscii & " (" & CITATIONS[plan.rename.rule] &
        ") stays for hand, since rename to `" &
        plan.rename.renamed & "` is refused: " & plan.refusal & "; got `" & plan.rename.name &
        "`.",
      rule = plan.rename.rule.id,
    )
  let entry = e.content.blockEntry
  if entry.refusal.len > 0:
    result.left.add finding(
      e.path,
      entry.bindings[0][0],
      "Entry block (V.10) stays for hand, since move into `proc main` is refused: " &
        entry.refusal & "; got `" & entry.bindings[0][1] & "`.",
      rule = Rule.BlockEntry.id,
    )
  if e.path in context.answers and context.answers[e.path].reason.len > 0:
    result.left.add finding(
      e.path,
      0,
      Check.BackendCompile,
      "File compiles on no backend of its pin, so fixers resting on semantic pass leave it; " &
        "got `" & context.answers[e.path].reason & "`.",
    )
  let fix = fixSource(e.path, e.content, e.kind.get, fence, context)
  for source in fix.asked:
    if (e.path, source) notin result.asked: result.asked.add (e.path, source)
  result.left.add fix.left
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
  ##   written with reason (nimble file `locked` names, fence fix cannot read), finding left for
  ##   hand of each rule resting on context that fix leaves, and one warning for each fence,
  ##   which keeps its lines as written, naming each rule broken among them (`checkFenceHeld`),
  ##   and for each file knoller's fixers do not settle (`warnUnsettled`).
  ##   `context` carries what tree tells fixers across modules, as `initContext` reads it,
  ##   and answers of parser; each source chain asks and no answer holds is in `asked`, source
  ##   as given too where fence holds lines, since its warning reads it.
  ##   Where any path to write lies outside branch scope, nothing is written or reported fixed.
  scoped(branch, entries.mapIt(it.fixEntry(locked, context)))


func pinFor(tree: Tree, path: string): string =
  ## Read pin of project holding path, driver's for file at root; empty where none is pinned.
  let directory = path.split('/').directoryProject
  tree.pin(if directory.len == 0: DIRECTORY_DRIVER else: directory).get("")


proc answered*(
  context: var Context; tree: Tree; asked: openArray[(string, string)]; provers: ProversPin
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


proc fixProven*(
  branch: string;
  tree: Tree;
  entries: openArray[Entry];
  locked: openArray[string];
  context: Context;
  provers: ProversPin,
): tuple[fix: Fixed, failures: seq[Finding]] =
  ## Fix entries as `fixEntries` does, ask parser of each pin what fix asked, and fix again, at
  ##   most `ASKS_MAX` times; each run that proved nothing gives one failure, for warning of
  ##   rule `needless-parentheses`, with no location and no article, as knoller prints it.
  ##   Entry that asked nothing read only sources answered, and answer once held never changes,
  ##   so each round fixes again only entries that asked.
  var
    known = context
    parts = entries.mapIt(it.fixEntry(locked, known))
  for ask in 1 .. ASKS_MAX:
    let asked = parts.mapIt(it.asked).concat
    if asked.len == 0: break
    for failure in known.answered(tree, asked, provers):
      let warning = finding("", 0, failure, rule = Rule.ParenthesesNeedless.id)
      if warning notin result.failures: result.failures.add warning
    for k, e in entries:
      if parts[k].asked.len > 0: parts[k] = e.fixEntry(locked, known)
  result.fix = scoped(branch, parts)
