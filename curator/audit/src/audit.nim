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

when compileOption("profiler"):
  import std/nimprof

import std/[options, os, sequtils, sets, strutils]
import ./[
  checker, dependencies, domains, duplicates, english, faces, findings, form, glossary, idioms,
  justification, kinds, layout, names, plan, prompts, prose, provenance, record, toolchain,
  tree, waits, workflows,
]

export layout.Entry, layout.projectDirectories, layout.Tree


func rulesStamp*(tree: Tree): string =
  ## Compute stamp of rules documents as tree holds them; missing document digests empty.
  var contents: seq[string]
  for rule in RULES:
    var content = ""
    for e in tree:
      if e.path == rule: content = e.content
    contents.add content
  contents.stamp


proc writeRulesRows*(root: string, tree: Tree): seq[string] =
  ## Rewrite every project record's `Rules` row to tree's stamp; return paths that changed.
  ##   Record is read from tree, as checks read it, and written back only when row moves, so
  ##   diff is that row alone and duty 1's hand step is one verb.
  let stamp_now = tree.rulesStamp
  for directory in tree.projectDirectories:
    let path = directory & "/PROVENANCE.md"
    for e in tree:
      if e.path != path: continue
      let written = e.content.withRulesRow(stamp_now)
      if written != e.content:
        writeFile(root / path, written)
        result.add path


proc prunedFindings*(root: string, tree: Tree): seq[Finding] =
  ## Report `Pruned` row naming commit that never touched its record, read from git log.
  ##   Lives beside static pass rather than in it, since form of row is pure check's and
  ##   existence of commit is git's; koch runs both under `check-files` and `check`.
  ##   Needs full log: shallow clone reports true row as missing, so `check-files` job fetches
  ##   depth 0.
  for directory in tree.projectDirectories:
    let path = directory & "/PROVENANCE.md"
    for e in tree:
      if e.path != path: continue
      let named = e.content.prunedOf
      if not named.isCommitId: continue
      let touched = gitFields(root, ["log", "-z", "--format=%H", "--", path])
      if not touched.anyIt(it.strip.startsWith(named)):
        result.add finding(
          path,
          0,
          "`" & PRUNED & "` must name commit that touched this record; got `" & named & "`.",
        )


func isContributorCode(path: string, directories: openArray[string]): bool =
  ## Decide whether path is contributor's own code: inside contributor project, and not one of
  ##   its records, which curator may write too.
  for directory in directories:
    if directory.startsWith(CONTRIBUTOR & "/") and path.startsWith(directory & "/"):
      return path[directory.len + 1 .. ^1] notin PROJECT_FILES


proc lockFindings(tree: Tree, directories: openArray[string]): seq[Finding] =
  ## Compare each project's stored nimble copy against committed one.
  ##   Tree is read here rather than in `layout.nim` so layout rules stay pure text over
  ##   paths; reading lock needs JSON, which Nim marks effectful.
  for directory in directories:
    let
      nimble_path = directory.nimblePath
      lock_path = directory & "/" & LOCK_FILE
    var
      nimble, lock: string
      found_lock = false
    for e in tree:
      if e.path == nimble_path: nimble = e.content
      elif e.path == lock_path:
        lock = e.content
        found_lock = true
    if found_lock: result.add checkLockNimble(nimble_path, lock_path, lock, nimble)


proc auditTree*(tree: Tree): seq[Finding] =
  ## Run every static check over tree.
  result = tree.checkLayout

  # Driver version is derived from driver project's pin, so it is never stated twice. Every
  #   workflow installing compiler, not driver's alone: second one drifts unwatched otherwise.
  let driver = tree.pinOf(DRIVER_DIRECTORY)
  if driver.isSome:
    for e in tree:
      if e.path.startsWith(WORKFLOW_DIRECTORY):
        result.add checkDriver(e.path, e.content, driver.get)

  # Every workflow, not just driver's: grant its steps outrun is `403` on runner and nothing
  #   readable here.
  for e in tree:
    if e.path.startsWith(WORKFLOW_DIRECTORY):
      result.add checkScopes(e.path, e.content)
      result.add checkWindow(e.path, e.content, RECENT_DAYS)

  # Checker holds itself to rules it holds everything else to, from tree as git shows it.
  var
    check_paths, check_sources, suite_sources: seq[string]
    koch_source, curator_source: string
  for e in tree:
    if e.path.startsWith(CHECK_DIRECTORY) or e.path == KOCH_PATH:
      check_paths.add e.path
      check_sources.add e.content
    if e.path.startsWith(SUITE_DIRECTORY): suite_sources.add e.content
    if e.path == KOCH_PATH: koch_source = e.content
    if e.path == CURATOR_PATH: curator_source = e.content
  result.add checkDeadExports(check_paths, check_sources, suite_sources)
  result.add checkSuites(tree.mapIt(it.path))
  result.add checkVerbs(koch_source, curator_source)
  result.add checkOptions(koch_source)
  let verbs = koch_source.dispatchVerbs
  if verbs.len > 0:
    for e in tree:
      if e.kind.isSome and not e.path.isContributorCode(tree.projectDirectories):
        result.add checkMentions(e.path, e.content, verbs)

  let
    stamp_now = tree.rulesStamp
    directories = tree.projectDirectories
  result.add tree.lockFindings(directories)
  var paths = initHashSet[string]()
  for e in tree: paths.incl e.path
  var documents, glossaries: seq[(string, string)]
  for e in tree:
    if e.kind.isNone: continue
    if e.path == ROOT_GLOSSARY:
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
        result.add checkPeopleWords(e.path, e.content)
    if e.path in PROMPT_PATHS: result.add checkPrompt(e.path, e.content)
    # Checker's own project names these families as data and carries fixture pages, so it
    #   would report itself; it holds no presentation target of its own to check. Paths of
    #   one machine it names as fixtures, for same reason.
    if not e.path.startsWith(DRIVER_DIRECTORY & "/"):
      result.add checkFaces(e.path, e.content)
      if e.kind.get != Kind.Markdown: result.add checkMachinePaths(e.path, e.content)
    if e.kind.get == Kind.Nim: result.add checkIdioms(e.path, e.content)
    for directory in directories:
      if e.path == directory & "/PROVENANCE.md":
        result.add checkProvenance(e.path, e.content, stamp_now)
        result.add checkCitations(e.path, e.content, directory & "/" & TESTS_DIRECTORY & "/", paths)
        result.add checkRecord(e.path, e.content)
      if e.path == directory & "/" & ROOT_GLOSSARY:
        result.add checkGlossary(e.path, e.content)
        glossaries.add (e.path, e.content)
  result.add checkStandardsAcross(glossaries)
  result.add checkDuplicates(documents)

  # TypeScript: project holding `.ts` carries `tsconfig.json` at its root, with its flags set.
  for directory in directories:
    if not tree.anyIt(it.path.startsWith(directory & "/") and it.path.endsWith(".ts")): continue
    let config_path = directory & "/tsconfig.json"
    var found_config = false
    for e in tree:
      if e.path == config_path:
        found_config = true
        result.add checkTsconfig(e.path, e.content)
    if not found_config:
      result.add finding(
        config_path,
        0,
        "Project holding TypeScript carries `tsconfig.json` at its root (CONTRIBUTOR.md, " &
          "TypeScript); got none.",
      )

  # Names: every Nim file is held to words glossaries admit, root and its own project.
  for e in tree:
    if e.kind.isNone or e.kind.get notin [Kind.Nim, Kind.NimScript, Kind.Nimble]: continue
    result.add checkNames(e.path, e.content, glossaries.exemptionsOf(e.path))

  # Fixed waits: drive code of every project, checker's own included, since its suite holds
  #   names as strings, which Nim source is read without.
  for e in tree:
    if e.kind.isSome and e.path.isDriveCode(directories):
      result.add checkWaits(e.path, e.content, e.kind.get)
