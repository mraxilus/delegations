## Select projects worth compiling for one change, and render them for CI matrix.
##   Static checks are cheap and stay whole-tree; compiling and running suites is not, and
##   it is only cost that grows as projects arrive. So test set is scoped and static pass is
##   not. Pair backing that is in PROVENANCE.md Figures and is not copied here: figures this
##   header carried were retired there as taken on another machine, and went on being cited
##   from here for whole day after.
##
##   Project enters test set when changed path under it is code, i.e. anything but its three
##     records, `PROJECT_FILES`: rules propagation rewrites provenance and glossary in every
##     project and changes no behaviour, so it compiles nothing while static pass still
##     verifies every stamp; README describes project and runs nothing, by same reasoning.
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
import ./[findings, checker, layout, toolchain, compilers, dependencies, projects, tree]


const
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
  ##   Records are `PROJECT_FILES`, same three `layout.nim` demands: README, provenance and
  ##   glossary describe project and run nothing, so changing one compiles nothing.
  if not path.startsWith(dir & "/"): return false
  path[dir.len + 1 .. ^1] notin PROJECT_FILES


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


func holds(tree: Tree, dir, name: string): bool =
  ## Decide whether project directory holds file of that name.
  let path = dir & "/" & name
  for e in tree:
    if e.path == path: return true


func nodeDirs*(tree: Tree, dirs: openArray[string]): seq[string] =
  ## Select projects type-checker reaches, i.e. those carrying node manifest and its lock.
  ##   Derived from tree rather than listed anywhere: project gains type check by carrying
  ##   manifest, and `check.yml` names no project, as it names none for compiler matrix.
  ##   Lock is demanded beside manifest, since `npm ci` needs one and unpinned tools would
  ##   be only thing here nothing pins.
  for dir in dirs:
    if tree.holds(dir, NODE_MANIFEST) and tree.holds(dir, NODE_LOCK): result.add dir


func driverOf*(tree: Tree, dir: string): string =
  ## Read project's build driver from tree; empty when project carries none.
  let path = dir & "/" & DRIVER_FILE
  for e in tree:
    if e.path == path: return e.content
  ""


func verbDirs*(tree: Tree, dirs: openArray[string], verb: string): seq[string] =
  ## Select projects whose build driver dispatches that verb.
  ##   Derived from driver rather than listed anywhere, same reasoning as `nodeDirs`: project
  ##   gains driven checks by carrying verb, and `check.yml` names no project. Driver is read
  ##   by same parser `checker.nim` reads koch's own dispatch with, since both hold one shape.
  for dir in dirs:
    if verb in tree.driverOf(dir).dispatchVerbs(DRIVER_CASE): result.add dir


proc systemPackages*(root: string, tree: Tree, dirs: openArray[string]): seq[string] =
  ## Read system packages every selected project declares, sorted.
  ##   Sorted so output is stable between runs: caller pipes it into installer, and list
  ##   reordering itself would read as change where nothing changed.
  var targets: seq[Target]
  for dir in tree.verbDirs(dirs, SYSTEM_VERB): targets.add Target(dir: dir)
  systemOf(root, targets).sorted


proc repositorySystem*(root: string, tree: Tree, dirs: openArray[string]): seq[string] =
  ## Read what whole machine needs: koch's own packages, plus every named project's, sorted.
  ##   Answer to "what must be installed before any of this runs" is one command rather than
  ##   prose somewhere, which is what rule koch enforces asks of every project and what koch
  ##   itself did not keep (repository issue 78).
  ##   koch's own are unconditional; project's arrive by that project declaring them, so caller
  ##   naming one project gets that project's alone and is served by `systemPackages`.
  var names: seq[string]
  for (package, _) in KOCH_SYSTEM: names.add package
  for package in systemPackages(root, tree, dirs):
    if package notin names: names.add package
  names.sorted


proc typeJobs*(root: string, tree: Tree, dirs: openArray[string]): seq[Finding] =
  ## Restore node tools and type-check every project carrying them.
  ##   No pin is resolved and no toolchain fetched: `tools/build.nim` compiles no project
  ##   code, deriving declarations by reading source as text, so project's own pin buys
  ##   nothing and building commit-pinned compiler to run build script costs minutes for
  ##   no checking. Driver's compiler runs it, as it runs whole-tree checks.
  ##   Cost: this holds only while that verb compiles no project code. One that did would
  ##   need its pin, and this would become matrix job like `project`.
  ##   Restore failing short-circuits, since type check without installed tools fails again
  ##   for second reason and reports neither clearly.
  var targets: seq[Target]
  for dir in tree.nodeDirs(dirs): targets.add Target(dir: dir)
  if targets.len == 0: return
  for target in targets: result.add restoreNode(root, target)
  if result.len > 0: return
  result.add runTypes(root, targets)


func nimbleOf*(tree: Tree, dir: string): string =
  ## Read project's nimble text from tree; empty when file is absent.
  let path = dir.nimblePath
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


func drivenOnly*(tree: Tree, jobs: openArray[Job]): seq[Job] =
  ## Keep planned jobs of projects carrying driven checks.
  ##   Filter over what `plan` already selected rather than second selection of its own, so
  ##   driven set inherits scoping, `--all` and sweep without restating any of it.
  var dirs: seq[string]
  for job in jobs: dirs.add job.dir
  let driven = tree.verbDirs(dirs, DRIVEN_VERB)
  for job in jobs:
    if job.dir in driven: result.add job


proc drivenJobs*(root: string, tree: Tree, jobs: openArray[Job]): seq[Finding] =
  ## Restore and drive each planned project carrying driven checks, on its own pin.
  ##   Pin is resolved as `runJobs` resolves it, not skipped as `typeJobs` skips it, because
  ##   driven verb compiles project code: it builds page through JS backend, so project
  ##   following its dependency onto compiler commit cannot be driven by driver's own. That
  ##   is exactly cost `typeJobs` records against itself, arriving.
  ##   Node restore joins Atlas restore for project carrying manifest, since harness runs
  ##   under node. Either restore failing short-circuits: driving without installed tools
  ##   fails again for second reason and reports neither clearly.
  let driven = tree.drivenOnly(jobs)
  if driven.len == 0: return
  let (targets, found) = driven.targetsFor
  result = found
  result.add restoreAll(root, targets)
  for target in targets:
    if tree.nodeDirs([target.dir]).len > 0: result.add restoreNode(root, target)
  if result.len > 0: return
  result.add runDriven(root, targets)
