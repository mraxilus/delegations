## Select projects worth compiling for one change, and render them for CI matrix.
##   Static checks are cheap and stay whole-tree; compiling and running suites is not, and
##   it is only cost that grows as projects arrive (0.11 s to 0.245 s static against 14.7 s
##   to 62.7 s suites when `dance_ontology` landed, PROVENANCE.md Figures). So test set is
##   scoped and static pass is not.
##
##   Project enters test set when changed path under it is code, i.e. anything but its
##     `PROVENANCE.md` or `GLOSSARY.md`: rules propagation rewrites those two in every
##     project and changes no behaviour, so it compiles nothing while static pass still
##     verifies every stamp.
##   Change to koch or to check sources selects every project, because how each is checked
##     changed. Those files are curator's alone and move rarely, so common case stays small.
##   Path inside no project selects nothing by itself.
##
##   Rendered plan drives one CI job per project, each installing that project's own pin, so
##     wall time is slowest changed project rather than sum of all.
##   Cost: scoped run leaves unrelated project's rot unseen until it next changes; weekly
##     sweep over every project is guard, and it is weaker than running everything always.

{.experimental: "strictFuncs".}

import std/[algorithm, json, options, strutils]
import ./[findings, layout, toolchain, dependencies, projects]


const
  DOCS* = ["PROVENANCE.md", "GLOSSARY.md"]
    ## Project files whose change alters no behaviour, so needs no compile.
  CHECKER_FILES* = ["koch.nim", "koch.nim.cfg"]
    ## Root files driving every project's checks.
  CHECKER_DIR* = DRIVER_DIR & "/src"
    ## Check sources driving every project; same folder as driver project, by coincidence
    ## of koch compiling exactly what it drives.


type Job* = object
  ## Define one project to compile, with compiler it pins.
  dir*: string  ## Project directory, repository-relative.
  pin*: string  ## Exact Nim version from project's nimble file.


func isChecker*(path: string): bool =
  ## Decide whether path drives how every project is checked.
  path in CHECKER_FILES or path.startsWith(CHECKER_DIR & "/")


func isCode*(dir, path: string): bool =
  ## Decide whether changed path is code of project, i.e. inside it and not its record.
  if not path.startsWith(dir & "/"): return false
  path[dir.len + 1 .. ^1] notin DOCS


func testSet*(dirs, paths: openArray[string]): seq[string] =
  ## Select projects one change asks to compile, sorted.
  for path in paths:
    if path.isChecker: return (@dirs).sorted
  for dir in dirs:
    for path in paths:
      if isCode(dir, path):
        result.add dir
        break
  result.sort


func nimbleOf*(tree: Tree, dir: string): string =
  ## Read project's nimble text from tree; empty when file is absent.
  let path = dir & "/" & dir.projectName & NIMBLE_EXT
  for e in tree:
    if e.path == path: return e.content
  ""


func pinOf*(tree: Tree, dir: string): Option[string] =
  ## Read exact Nim pin project declares; `none` when nimble file or pin is absent.
  tree.nimbleOf(dir).nimPin


func jobsFor*(tree: Tree, dirs: openArray[string]): seq[Job] =
  ## Build one job per directory, carrying its pin; unpinned project is skipped, since
  ##   `layout.nim` already reports it and matrix cannot install version nobody named.
  for dir in dirs:
    let pin = tree.pinOf(dir)
    if pin.isSome: result.add Job(dir: dir, pin: pin.get)


func jobs*(tree: Tree, paths: openArray[string]): seq[Job] =
  ## Build jobs for projects one change asks to compile.
  tree.jobsFor(testSet(tree.projectDirs, paths))


func allJobs*(tree: Tree): seq[Job] =
  ## Build jobs for every project, for scheduled sweep rather than for one change.
  tree.jobsFor(tree.projectDirs)


proc render*(jobs: openArray[Job]): string =
  ## Render jobs as JSON array of matrix entries, escaping through `std/json`.
  var node = newJArray()
  for job in jobs: node.add %*{"dir": job.dir, "nim": job.pin}
  $node


proc runJobs*(root: string, jobs: openArray[Job]): seq[Finding] =
  ## Restore and test each planned project, refusing any pin compiler on PATH cannot serve.
  ##   Mismatched project is reported and skipped rather than compiled: wrong compiler
  ##   either fails confusingly or passes without testing what CI will run.
  if jobs.len == 0: return
  let running = runningVersion()
  var dirs: seq[string]
  for job in jobs:
    let mismatch = checkRunning(job.dir, job.pin, running)
    if mismatch.len > 0: result.add mismatch
    else: dirs.add job.dir
  result.add restoreAll(root, dirs)
  result.add runTests(root, dirs)
