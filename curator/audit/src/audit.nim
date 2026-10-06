## Audit repository against charter and CONTRIBUTOR.md; library umbrella.
##   Command line lives in root `koch.nim`, as Nim's own koch drives its repository; this
##   module composes static checks so koch holds dispatch only.
##   Module order is read from each module's own `import` line, never restated here: copy of
##     graph drifts from graph. Breaks Article I.5, which asks umbrella for `->` diagram.
##     Cost: reader derives order from imports rather than reading it in one place.
##
##   Cost: tool runs once per check, so no hot path exists and Article VII figures stay
##     unmeasured by design; whole-tree audit time is recorded in PROVENANCE.md.
##   Cost: composition is `proc`, never `func`, since lock is read as JSON and Nim marks
##     `parseJson` effectful; every rule it composes stays pure.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/[options, os, sequtils, sets, strutils]
import ../../knoller/src/knoller
import ./[
  checker, coverage, dependencies, domains, duplicates, english, faces, findings, form, glossary,
  idioms, justification, kinds, layout, names, plan, prompts, prose, provenance, record,
  toolchain, tree, waits, workflows,
]

export layout.Entry, layout.directoriesProject, layout.Tree


func stampRules*(tree: Tree): string =
  ## Compute stamp of rules documents as tree holds them; missing document digests empty.
  var contents: seq[string]
  for rule in RULES:
    var content = ""
    for e in tree:
      if e.path == rule: content = e.content
    contents.add content
  contents.stamp


proc writeRowsRules*(root: string, tree: Tree): seq[string] =
  ## Rewrite every project record's `Rules` row to tree's stamp; return paths that changed.
  ##   Record is read from tree, as checks read it, and written back only when row moves, so
  ##   diff is that row alone and duty 1's hand step is one verb.
  let stamp_now = tree.stampRules
  for directory in tree.directoriesProject:
    let path = directory & "/PROVENANCE.md"
    for e in tree:
      if e.path != path: continue
      let written = e.content.rewriteRowRules(stamp_now)
      if written != e.content:
        writeFile(root / path, written)
        result.add path


proc findingsPruned*(root: string, tree: Tree): seq[Finding] =
  ## Report `Pruned` row naming commit that never touched its record, read from git log.
  ##   Lives beside static pass rather than in it, since form of row is pure check's and
  ##   existence of commit is git's; koch runs both under `check-files` and `check`.
  ##   Needs full log: shallow clone reports true row as missing, so `check-files` job fetches
  ##   depth 0.
  for directory in tree.directoriesProject:
    let path = directory & "/PROVENANCE.md"
    for e in tree:
      if e.path != path: continue
      let named = e.content.prunedOf
      if not named.isIdCommit: continue
      let touched = fieldsGit(root, ["log", "-z", "--format=%H", "--", path])
      if not touched.anyIt(it.strip.startsWith(named)):
        result.add finding(
          path,
          0,
          "`" & PRUNED & "` must name commit that touched this record; got `" & named & "`.",
        )


func isCodeContributor(path: string, directories: openArray[string]): bool =
  ## Decide whether path is contributor's own code: inside contributor project, and not one of
  ##   its records, which curator may write too.
  for directory in directories:
    if directory.startsWith(CONTRIBUTOR & "/") and path.startsWith(directory & "/"):
      return path[directory.len + 1 .. ^1] notin FILES_PROJECT


proc findingsLock(tree: Tree, directories: openArray[string]): seq[Finding] =
  ## Compare each project's stored nimble copy against committed one.
  ##   Tree is read here rather than in `layout.nim` so layout rules stay pure text over
  ##   paths; reading lock needs JSON, which Nim marks effectful.
  for directory in directories:
    let
      path_nimble = directory.pathNimble
      path_lock = directory & "/" & FILE_LOCK
    var
      nimble, lock: string
      found_lock = false
    for e in tree:
      if e.path == path_nimble: nimble = e.content
      elif e.path == path_lock:
        lock = e.content
        found_lock = true
    if found_lock: result.add checkNimbleLock(path_nimble, path_lock, lock, nimble)


proc auditTree*(tree: Tree): seq[Finding] =
  ## Run every static check over tree.
  result = tree.checkLayout

  # Driver version is derived from driver project's pin, so it is never stated twice. Every
  #   workflow installing compiler, not driver's alone: second one drifts unwatched otherwise.
  let driver = tree.pinOf(DIRECTORY_DRIVER)
  if driver.isSome:
    for e in tree:
      if e.path.startsWith(DIRECTORY_WORKFLOW):
        result.add checkDriver(e.path, e.content, driver.get)
  result.add checkKnoller(DIRECTORY_KNOLLER.pathNimble, tree.pinOf(DIRECTORY_KNOLLER), driver)

  # Every workflow, not just driver's: grant its steps outrun is `403` on runner and nothing
  #   readable here.
  for e in tree:
    if e.path.startsWith(DIRECTORY_WORKFLOW):
      result.add checkScopes(e.path, e.content)
      result.add checkWindow(e.path, e.content, DAYS_RECENT)

  # Checker holds itself to rules it holds everything else to, from tree as git shows it.
  var
    paths_check, sources_check, sources_suite: seq[string]
    source_koch, source_curator: string
  for e in tree:
    if e.path.isExporting:
      paths_check.add e.path
      sources_check.add e.content
    if e.path.isCalling: sources_suite.add e.content
    if e.path == PATH_KOCH: source_koch = e.content
    if e.path == PATH_CURATOR: source_curator = e.content
  result.add checkExportsDead(paths_check, sources_check, sources_suite)
  result.add checkSuites(tree.mapIt(it.path))
  result.add checkVerbs(source_koch, source_curator)
  result.add checkOptions(source_koch)
  let verbs = source_koch.verbsDispatch
  if verbs.len > 0:
    for e in tree:
      if e.kind.isSome and not e.path.isCodeContributor(tree.directoriesProject):
        result.add checkMentions(e.path, e.content, verbs)

  let
    stamp_now = tree.stampRules
    directories = tree.directoriesProject
  result.add tree.findingsLock(directories)
  var paths = initHashSet[string]()
  for e in tree: paths.incl e.path
  var documents, glossaries: seq[(string, string)]
  for e in tree:
    if e.kind.isNone: continue
    if e.path == GLOSSARY_ROOT:
      result.add checkGlossary(e.path, e.content)
      glossaries.add (e.path, e.content)
    let rule = e.kind.get.rule
    result.add checkForm(e.path, e.content, rule)
    if rule.is_prose: result.add checkProse(e.path, e.content, rule.syntax)
    result.add checkJustification(e.path, e.content, rule)
    if e.kind.get == Kind.Markdown:
      documents.add (e.path, e.content)
      result.add checkEnglish(e.path, e.content)
      # Root files and curator records are held to glossary's people words; contributor
      #   prose is its own, and glossary itself lists words it avoids.
      let is_governed = '/' notin e.path or e.path.startsWith(CURATOR & "/")
      if is_governed and not e.path.endsWith("GLOSSARY.md"):
        result.add checkWordsPeople(e.path, e.content)
    if e.path in PATHS_PROMPT: result.add checkPrompt(e.path, e.content)
    # Checker's own project names these families as data and carries fixture pages, so it
    #   would report itself; it holds no presentation target of its own to check. Paths of
    #   one machine it names as fixtures, for same reason.
    if not e.path.startsWith(DIRECTORY_DRIVER & "/"):
      result.add checkFaces(e.path, e.content)
      if e.kind.get != Kind.Markdown: result.add checkPathsMachine(e.path, e.content)
    if e.kind.get.rule.has_guide:
      result.add checkIdioms(e.path, e.content, e.kind.get.dialectOf).findingsOf
    for directory in directories:
      if e.path == directory & "/PROVENANCE.md":
        result.add checkProvenance(e.path, e.content, stamp_now)
        result.add checkCitations(e.path, e.content, directory & "/" & DIRECTORY_TESTS & "/", paths)
        result.add checkRecord(e.path, e.content)
      if e.path == directory & "/" & GLOSSARY_ROOT:
        result.add checkGlossary(e.path, e.content)
        glossaries.add (e.path, e.content)
  result.add checkStandardsAcross(glossaries)
  result.add checkDuplicates(documents)

  # Coverage reads project whole: faces it names anywhere against characters it writes
  #   anywhere. Checker's own project names every face as data, so faces check's exemption
  #   holds here too.
  for directory in directories:
    if directory != DIRECTORY_DRIVER: result.add tree.checkCoverage(directory)

  # TypeScript: project holding `.ts` carries `tsconfig.json` at its root, with its flags set.
  for directory in directories:
    if not tree.anyIt(it.path.startsWith(directory & "/") and it.path.endsWith(".ts")): continue
    let path_config = directory & "/tsconfig.json"
    var found_config = false
    for e in tree:
      if e.path == path_config:
        found_config = true
        result.add checkTsconfig(e.path, e.content)
    if not found_config:
      result.add finding(
        path_config,
        0,
        "Project holding TypeScript carries `tsconfig.json` at its root (CONTRIBUTOR.md, " &
          "TypeScript); got none.",
      )

  # Names: every Nim file is held to words glossaries admit, root and its own project, acronyms
  #   among them, which knoller reads no glossary for; binding of entry block is its own rule.
  for e in tree:
    if e.kind.isNone or e.kind.get notin [Kind.Nim, Kind.NimScript, Kind.Nimble]: continue
    let exempt = glossaries.exemptionsOf(e.path)
    result.add findingsOf(checkNames(e.path, e.content, exempt))
    result.add findingsOf(checkBlockEntry(e.path, e.content))
    result.add checkAcronyms(e.path, e.content, exempt)

  # Fixed waits: drive code of every project, checker's own included, since its suite holds
  #   names as strings, which Nim source is read without.
  for e in tree:
    if e.kind.isSome and e.path.isCodeDrive(directories):
      result.add checkWaits(e.path, e.content, e.kind.get)
