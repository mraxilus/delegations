## Audit repository against CONSTITUTION.md, STYLE.md and CONTRIBUTOR.md; library umbrella.
##   Command line lives in root `koch.nim`, as Nim's own koch drives its repository; this
##   module composes static checks so koch holds dispatch only.
##   Module order is read from each module's own `import` line, never restated here: copy of
##     graph drifts from graph, and this one had, naming dependencies four modules did not
##     have and omitting `base` entirely.
##
##   Cost: tool runs once per check, so no hot path exists and Article VII figures stay
##     unmeasured by design; whole-tree audit time is recorded in PROVENANCE.md.
##   Cost: composition is `proc`, never `func`, since lock is read as JSON and Nim marks
##     `parseJson` effectful; every rule it composes stays pure.

{.experimental: "strictFuncs".}

import std/[options, sequtils, sets, strutils]
import ./[
  findings, kinds, prose, form, justification, checker, layout, provenance, glossary,
  dependencies, toolchain, plan,
]

export layout.Tree, layout.Entry, layout.projectDirs


func rulesStamp*(tree: Tree): string =
  ## Compute stamp of rules documents as tree holds them; missing document digests empty.
  var contents: seq[string]
  for rule in RULES:
    var content = ""
    for e in tree:
      if e.path == rule: content = e.content
    contents.add content
  contents.stamp


proc lockFindings(tree: Tree, dirs: openArray[string]): seq[Finding] =
  ## Compare each project's stored nimble copy against committed one.
  ##   Tree is read here rather than in `layout.nim` so layout rules stay pure text over
  ##   paths; reading lock needs JSON, which Nim marks effectful.
  for dir in dirs:
    let nimble_path = dir.nimblePath
    let lock_path = dir & "/" & LOCK_FILE
    var nimble, lock: string
    var has_lock = false
    for e in tree:
      if e.path == nimble_path: nimble = e.content
      elif e.path == lock_path:
        lock = e.content
        has_lock = true
    if has_lock: result.add checkLockNimble(nimble_path, lock_path, lock, nimble)


proc auditTree*(tree: Tree): seq[Finding] =
  ## Run every static check over tree.
  result = tree.checkLayout

  # Driver version is derived from driver project's pin, so it is never stated twice.
  let driver = tree.pinOf(DRIVER_DIR)
  if driver.isSome:
    for e in tree:
      if e.path == WORKFLOW_PATH: result.add checkDriver(e.content, driver.get)

  # Checker holds itself to rules it holds everything else to, from tree as git shows it.
  var check_paths, check_sources: seq[string]
  var koch_source, curator_source: string
  for e in tree:
    if e.path.startsWith(CHECK_DIR) or e.path == KOCH_PATH:
      check_paths.add e.path
      check_sources.add e.content
    if e.path == KOCH_PATH: koch_source = e.content
    if e.path == CURATOR_PATH: curator_source = e.content
  result.add checkDeadExports(check_paths, check_sources)
  result.add checkSuites(tree.mapIt(it.path))
  result.add checkVerbs(koch_source, curator_source)

  let stamp_now = tree.rulesStamp
  let dirs = tree.projectDirs
  result.add tree.lockFindings(dirs)
  var paths = initHashSet[string]()
  for e in tree: paths.incl e.path
  for e in tree:
    if e.kind.isNone: continue
    if e.path == "GLOSSARY.md": result.add checkGlossary(e.path, e.content)
    let rule = e.kind.get.rule
    result.add checkForm(e.path, e.content, rule)
    if rule.is_prose: result.add checkProse(e.path, e.content, rule.syntax)
    result.add checkJustification(e.path, e.content, rule)
    for dir in dirs:
      if e.path == dir & "/PROVENANCE.md":
        result.add checkProvenance(e.path, e.content, stamp_now)
        result.add checkCitations(e.path, e.content, dir & "/" & TESTS_DIR & "/", paths)
      if e.path == dir & "/GLOSSARY.md": result.add checkGlossary(e.path, e.content)
