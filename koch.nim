## Drive every check of repository from one compiled program, as Nim's own `koch` does.
##   Build once with `nim c koch`, then `./koch <command>`; or `nim r koch <command>`, which
##   rebuilds when sources changed, then runs (Article IX.6); warm run costs ~0.1 s.
##
##   |---------|----------------------------------------------------------------------------------|
##   | Command | Effect                                                                           |
##   |---------|----------------------------------------------------------------------------------|
##   | tree    | every static check `auditTree` composes, then `Pruned` rows against git log      |
##   | deps    | `atlas --noexec rep` in every project holding atlas.lock, or in one              |
##   | types   | restore node tools, then type-check scripts, projects one change asks            |
##   | driven  | restore, build page, drive it through real events, on that project's pin         |
##   | system  | print packages projects with `system` verb declare, one per line                 |
##   | assets  | fetch files named into store, print path of each; name none to declare           |
##   | tests   | restore, then testament over tests/t*.nim, every project or one                  |
##   | plan    | projects one change asks to compile, as JSON for CI matrix                       |
##   | scope   | changed paths against branch prefix           (--branch, --base)                 |
##   | commits | commit subjects against branch scope          (--branch, --base)                 |
##   | base    | paths branch gained against base's own rules  (--base)                           |
##   | role    | pull request's role line and labels against branch  (--branch)                   |
##   | stamp   | print rules stamp for PROVENANCE.md; --write sets every Rules row                |
##   | ci      | fetch origin/main; tree, scope, commits, base; if clean, types, tests, driven    |
##   |---------|----------------------------------------------------------------------------------|
##   Verb of one project is that project's own, in its `tools/build.nim`; koch names verb and
##     selects projects carrying it, and holds none of what it does. `types`, `drive` and
##     `system` are those. Koch learns which projects carry `drive` and `system` by reading
##     that driver's own dispatch, and which carry `types` by node manifest beside its lock;
##     never from list.
##   `types` runs on driver's compiler and `driven` on project's own, because type check
##     compiles no project code and driven check does: it builds page through JS backend.
##     So `driven` is planned like `tests`, through `plan --driven`, and reaches CI as matrix.
##   Options: `--root:<dir>` (default `.`); `--branch:<name>` (default env `BRANCH`, else
##     current git branch); `--base:<ref>` (default env `BASE`, else `origin/main`); `--all`
##     makes `plan` name every project; `--sweep` names projects whose code merged within
##     window; `--driven` keeps only those carrying driven checks;
##     `--write` makes `stamp` set every record's Rules row rather than print stamp. Second
##     argument names one project directory for `deps`, `types`, `driven`, `system`, `tests`
##     and `plan`, which then drop their scoping; `ci` passes it to `types` alone; `assets`
##     reads every argument as file; other verbs ignore it.
##     Exit: 0 clean, 1 findings, 2 usage error.
##   `role` reads pull request rather than tree, so runner hands it two inputs through env:
##     `ROLE_BODY` from event payload, and `ROLE_LABELS` from API as JSON array of label
##     names. That is why `ci` leaves it out: local run has no pull request to read.
##
##   `ci` compiles only projects whose code changed, since static pass costs about second
##     and suites cost minutes (`curator/audit/PROVENANCE.md`, Figures); push run on `main`
##     and weekly run do same against their own base, so nothing compiles every project
##     (CURATOR.md duty 11). Matrix runs each on its own pin, as `ci` does locally:
##     `compilers.nim` serves each changed project's pin from PATH, cache or fetch, so which
##     compiler PATH holds decides nothing.
##
##   Rejected: make (second toolchain, recipe tabs, untested glue); NimScript tasks (compiler
##     VM subset, script loaded on every compile, task names shadow compiler commands,
##     untestable). Chosen: compiled driver, as Nim's repository builds with `koch`.
##   Cost: root file outside any project; every check it drives is library module under
##     `curator/audit/src`, tested there; this file holds dispatch only.

{.experimental: "strictFuncs".}

import std/[json, options, os, parseopt, sequtils, strutils]
import ./curator/audit/src/[
  findings, domains, scope, commits, tree, audit, plan, base, role, assets,
]


const USAGE = """
Usage: koch <tree|deps|types|driven|system|assets|tests|plan|scope|commits|base|role|stamp|ci>
            [project|asset...]
            [--root:<dir>] [--branch:<name>] [--base:<ref>] [--all] [--sweep] [--driven]
            [--write]
"""
  ## Text printed on usage error.


type Options = object
  ## Define parsed command line.
  command: string
  project: string
  rest: seq[string]
  root: string = "."
  branch: string
  base: string
  is_all: bool
  is_sweep: bool
  is_driven: bool
  is_write: bool


proc parseOptions(): Option[Options] =
  ## Parse command line; `none` on unknown option or missing command.
  var options = Options()
  for kind, key, value in getopt():
    case kind
    of cmdArgument:
      # Third argument onward is refused for every verb but `assets`, which names files
      #   rather than one project; refusing them everywhere would make that verb impossible
      #   and accepting them everywhere would let typo pass as argument nothing reads.
      if options.command.len == 0: options.command = key
      elif options.project.len == 0: options.project = key
      elif options.command == "assets": options.rest.add key
      else: return none(Options)
    of cmdLongOption, cmdShortOption:
      case key
      of "root": options.root = value
      of "branch": options.branch = value
      of "base": options.base = value
      of "all": options.is_all = true
      of "sweep": options.is_sweep = true
      of "driven": options.is_driven = true
      of "write": options.is_write = true
      else: return none(Options)
    of cmdEnd: discard
  if options.command.len == 0: return none(Options)
  some(options)


proc branchOrDefault(options: Options): string =
  ## Read branch from option, else env `BRANCH`, else current git branch.
  if options.branch.len > 0: return options.branch
  if existsEnv("BRANCH"): return getEnv("BRANCH")
  gitFields(options.root, ["rev-parse", "--abbrev-ref", "HEAD"])[0].strip


proc baseOrDefault(options: Options): string =
  ## Read base from option, else env `BASE`, else `origin/main`.
  if options.base.len > 0: return options.base
  getEnv("BASE", "origin/" & MAIN)


proc dirsOf(options: Options, tree: Tree): seq[string] =
  ## Read project directories command drives: named one, else every project.
  if options.project.len > 0: @[options.project.strip(chars = {'/'})] else: tree.projectDirs


proc plannedJobs(options: Options, tree: Tree): seq[Job] =
  ## Read jobs one run asks for: named project, else sweep, else every project, else changed.
  if options.project.len > 0:
    tree.jobsFor([options.project.strip(chars = {'/'})])
  elif options.is_sweep: sweepFor(options.root, tree, SWEEP_DAYS)
  elif options.is_all: tree.allJobs
  else: tree.jobs(changedPaths(options.root, options.baseOrDefault))


proc scopedDirsOf(options: Options, tree: Tree): seq[string] =
  ## Read project directories one-job check drives: named one, else those one change asks for.
  ##   Scoped where `tests` is not, because CI runs these as one job each rather than through
  ##   matrix `plan` already scoped, and scoping has to live somewhere.
  ##   `--sweep` scopes to window rather than to base commit, exactly as `plan` does on
  ##   schedule; `--all` drops scoping.
  if options.project.len > 0: @[options.project.strip(chars = {'/'})]
  elif options.is_sweep: sweepFor(options.root, tree, SWEEP_DAYS).mapIt(it.dir)
  elif options.is_all: tree.projectDirs
  else: testSet(tree.projectDirs, changedPaths(options.root, options.baseOrDefault))


proc run(options: Options): int =
  ## Execute command, print findings, return exit code.
  var found: seq[Finding]
  case options.command
  of "tree":
    let tree = options.root.readTree
    found = tree.auditTree
    found.add prunedFindings(options.root, tree)
  of "deps":
    let tree = options.root.readTree
    found = restoreJobs(options.root, tree.jobsFor(options.dirsOf(tree)))
  of "types":
    let tree = options.root.readTree
    found = typeJobs(options.root, tree, options.scopedDirsOf(tree))
  of "driven":
    let tree = options.root.readTree
    found = drivenJobs(options.root, tree, options.plannedJobs(tree))
  of "system":
    # Named project answers for that project, which is what runner asks per matrix job.
    #   Named none answers for machine: koch's own packages and every project's, unscoped,
    #   since question is what must be installed rather than what one change touched.
    let tree = options.root.readTree
    let named =
      if options.project.len > 0: systemPackages(options.root, tree, options.dirsOf(tree))
      else: repositorySystem(options.root, tree, tree.projectDirs)
    for package in named: echo package
    return 0
  of "assets":
    # Fetched file is repository's, never one project's: two targets pinned four of same
    #   files byte for byte before this (repository issue 116). Store holds digest; caller
    #   names which files it wants, so what is shared is bytes rather than choice.
    let root = storeRoot(getEnv(ASSETS_KEY))
    var wanted = options.rest
    if options.project.len > 0: wanted.insert(options.project, 0)
    # Naming no file asks for declaration rather than for bytes: consumer checking whether
    #   name is declared reads published rows, never this module's source (issue 134).
    if wanted.len == 0:
      stdout.write declaration()
      return 0
    for file in wanted:
      let path = assetIn(root, file)
      if path.len == 0:
        found.add(if file.declaredDigest.len == 0: unknown(file) else: @[finding(
          "curator/audit/src/assets.nim", 0,
          "Asset is declared but could not be fetched or checked; got `" & file & "`.",
        )])
      else: echo path
    if found.len == 0: return 0
  of "tests":
    let tree = options.root.readTree
    found = runJobs(options.root, tree.jobsFor(options.dirsOf(tree)))
  of "plan":
    let tree = options.root.readTree
    let jobs = options.plannedJobs(tree)
    echo render(if options.is_driven: tree.drivenOnly(jobs) else: jobs)
    return 0
  of "scope":
    let base = options.baseOrDefault
    found = checkScope(
      options.branchOrDefault, changedPaths(options.root, base), movedPaths(options.root, base)
    )
  of "commits":
    found = checkCommits(options.branchOrDefault, subjects(options.root, options.baseOrDefault))
  of "base":
    found = checkBase(gainedPaths(options.root, options.baseOrDefault))
  of "role":
    # Pull request's own two facts, which runner alone holds: they arrive through environment,
    #   never interpolated into script, as branch and event kind already do.
    let named = getEnv("ROLE_LABELS").strip
    let labels =
      if named.len == 0: newSeq[string]()
      else: named.parseJson.getElems.mapIt(it.getStr)
    found = checkRole(options.branchOrDefault, getEnv("ROLE_BODY"), labels)
  of "stamp":
    # Printing serves record written by hand; writing serves duty 1, where every record moves
    #   at once and four hand edits were one step too many (curator review, C10).
    let tree = options.root.readTree
    if options.is_write:
      for path in writeRulesRows(options.root, tree): echo path
    else: echo tree.rulesStamp
    return 0
  of "ci":
    # Checks costing about second run first, and any finding among them stops run before
    #   types, suites and drive, which cost minutes and run again once finding is fixed.
    #   Cost: suite failure shows only after static pass is clean.
    discard gitFields(options.root, ["fetch", "-q", "origin", MAIN])
    let tree = options.root.readTree
    let (branch, base) = (options.branchOrDefault, options.baseOrDefault)
    found = tree.auditTree
    found.add prunedFindings(options.root, tree)
    found.add checkScope(branch, changedPaths(options.root, base), movedPaths(options.root, base))
    found.add checkCommits(branch, subjects(options.root, base))
    found.add checkBase(gainedPaths(options.root, base))
    if found.len > 0:
      found.report
      echo "Types, suites and drive not run; fix findings above, then run again."
      return 1
    found.add typeJobs(options.root, tree, options.scopedDirsOf(tree))
    found.add ciJobs(options.root, tree, tree.jobs(changedPaths(options.root, base)))
  else:
    stderr.write USAGE
    return 2
  found.report
  if found.len == 0: 0 else: 1


proc main(): int =
  ## Parse options and run; usage error exits 2.
  let options = parseOptions()
  if options.isNone:
    stderr.write USAGE
    return 2
  options.get.run


when isMainModule:
  quit main()
