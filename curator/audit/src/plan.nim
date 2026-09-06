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
##     wall time is slowest changed project rather than sum of all. Entry carries `kind`,
##     since version is installed by setup action and commit is built from source.
##   Cost: scoped run leaves unrelated project's rot unseen until it next changes; weekly
##     sweep over every project is guard, and it is weaker than running everything always.
##   Sweep itself is skipped in week no code merged, since rot arrives with merges. Cost:
##     rot from outside repository, such as runner image moving under pinned compiler, goes
##     unseen through quiet week; it surfaces on next sweep that runs.

{.experimental: "strictFuncs".}

import std/[algorithm, json, options, os, strutils, tables]
import ./[findings, layout, toolchain, dependencies, projects, tree]


const
  DOCS* = ["PROVENANCE.md", "GLOSSARY.md"]
    ## Project files whose change alters no behaviour, so needs no compile.
  CHECKER_FILES* = ["koch.nim", "koch.nim.cfg"]
    ## Root files driving every project's checks.
  SWEEP_DAYS* = 7
    ## Window sweep looks back over, matching weekly cron in `check.yml`. Both are named
    ## once; changing one means changing other, which CURATOR.md duty 7 says.
  CHECKER_DIR* = DRIVER_DIR & "/src"
    ## Check sources driving every project; same folder as driver project, by coincidence
    ## of koch compiling exactly what it drives.


type Job* = object
  ## Define one project to compile, with compiler it pins.
  dir*: string  ## Project directory, repository-relative.
  pin*: string  ## Exact Nim version, or commit, from project's nimble file.


func kind*(job: Job): string =
  ## Name how job's compiler is obtained, which CI branches on.
  if job.pin.isCommit: "commit" else: "version"


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


func sweepJobs*(tree: Tree, paths: openArray[string]): seq[Job] =
  ## Build sweep: every project when any code changed in window, none when nothing did.
  ##   Sweep exists to catch rot scoped runs missed, and rot arrives with merges, so week
  ##   nobody merged code has nothing to find. Record-only weeks count as nothing, by same
  ##   rule scoped runs use.
  if testSet(tree.projectDirs, paths).len == 0: return
  tree.allJobs


proc sweepFor*(root: string, tree: Tree, days: int): seq[Job] =
  ## Build sweep against window ending now; repository younger than window sweeps whole.
  let base = revBefore(root, days)
  if base.len == 0: return tree.allJobs
  tree.sweepJobs(changedPaths(root, base))


proc render*(jobs: openArray[Job]): string =
  ## Render jobs as JSON array of matrix entries, escaping through `std/json`.
  var node = newJArray()
  for job in jobs: node.add %*{"dir": job.dir, "nim": job.pin, "kind": job.kind}
  $node


proc targetsFor*(jobs: openArray[Job]): (seq[Target], seq[Finding]) =
  ## Resolve each job's pin to toolchain serving it, reporting pins nothing serves.
  ##   Pins differ between projects and one machine has one compiler on PATH, so each pin
  ##   is resolved rather than assumed: PATH when it already serves, else cache, else
  ##   fetched. Pin nothing serves is finding naming cache, and its project is dropped
  ##   rather than run by wrong compiler, which either fails confusingly or passes without
  ##   testing what CI will run.
  ##   Resolution happens once per distinct pin, since projects commonly share one.
  if jobs.len == 0: return
  let running = runningCompiler()
  let cache = cacheRoot(getEnv(CACHE_KEY))
  var bins = initTable[string, Option[string]]()
  for job in jobs:
    if job.pin notin bins: bins[job.pin] = resolve(job.pin, running, cache)
    let bin = bins[job.pin]
    if bin.isNone: result[1].add missing(job.dir, job.pin, binOf(cache, job.pin))
    else: result[0].add Target(dir: job.dir, bin: bin.get)


proc restoreJobs*(root: string, jobs: openArray[Job]): seq[Finding] =
  ## Restore each planned project's checkouts, Atlas coming from that project's toolchain.
  let (targets, found) = jobs.targetsFor
  result = found
  result.add restoreAll(root, targets)


proc runJobs*(root: string, jobs: openArray[Job]): seq[Finding] =
  ## Restore and test each planned project, each on toolchain its own pin names.
  let (targets, found) = jobs.targetsFor
  result = found
  result.add restoreAll(root, targets)
  result.add runTests(root, targets)
