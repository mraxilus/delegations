## Drive every check of repository from one compiled program, as Nim's own `koch` does.
##   Build once with `nim c koch`, then `./koch <verb>`; or `nim r koch <verb>`, which
##   rebuilds when sources changed, then runs (Article IX.6); warm run costs ~0.1 s.
##   `USAGE` names every verb and option with its effect, and `./koch` alone prints it.
##     `checker.nim` holds usage, dispatch and CURATOR.md table to one verb set, so no fourth
##     copy lives here.
##
##   Verb names action and its object. `check` runs every check pull request runs, and each
##     `check-<object>` runs one of them; other verbs act (`test`, `drive`, `fetch-*`,
##     `stamp`) or print (`list-*`). CI job running verb carries verb's name, so red job names
##     command to run locally.
##   Verb of one project is that project's own, in its `tools/build.nim`; koch names verb and
##     selects projects carrying it, and holds none of what it does. `check-types` runs
##     project's `types`, `drive` its `drive`, and `list-packages` its `system`. Koch learns
##     which projects carry `drive` and `system` by reading that driver's own dispatch, and
##     which carry `types` by node manifest beside its lock; never from list.
##   `check-types` runs on driver's compiler and `drive` on project's own, because type check
##     compiles no project code and drive does: it builds page through JS backend. So `drive`
##     is planned like `test`, through `list-projects --drive`, and reaches CI as matrix.
##   Verb taking projects reads named one, else `--recent` window, else `--all`, else those
##     whose code changed against base. Verb refuses option or argument it does not read, with
##     usage and exit 2, so typo never passes as input nothing reads.
##     Exit: 0 clean, 1 findings, 2 usage error.
##   `check-role` reads pull request rather than tree, so runner hands it two inputs through
##     env: `ROLE_BODY` from event payload, and `ROLE_LABELS` from API as JSON array of label
##     names. That is why `check` leaves it out: local run has no pull request to read.
##
##   `check` compiles only projects whose code changed, since static pass costs about second
##     and suites cost minutes (`curator/audit/PROVENANCE.md`, Figures); push run on `main`
##     and weekly run do same against their own base, so nothing compiles every project
##     (CURATOR.md duty 11). Matrix runs each on its own pin, as `check` does locally:
##     `compilers.nim` serves each changed project's pin from PATH, cache or fetch, so which
##     compiler PATH holds decides nothing.
##
##   Rejected: make (second toolchain, recipe tabs, untested glue); NimScript tasks (compiler
##     VM subset, script loaded on every compile, task names shadow compiler commands,
##     untestable). Chosen: compiled driver, as Nim's repository builds with `koch`.
##   Rejected: verb and object as two words (`koch check files`), which puts second dispatch
##     inside first and makes project argument third. Hyphen keeps one word per verb.
##   Cost: root file outside any project; every check it drives is library module under
##     `curator/audit/src`, tested there; this file holds dispatch only.

{.experimental: "strictFuncs".}

import std/[json, options, os, parseopt, sequtils, strutils]
import ./curator/audit/src/[
  assets,
  audit,
  base,
  commits,
  domains,
  findings,
  hooks,
  plan,
  role,
  scope,
  tree,
]


const USAGE = """
Usage: koch <verb> [project | file...] [options]

Verbs:
  check          every check pull request runs; quick ones first, stopping on finding
  check-files    static checks over every file git lists; compiles nothing
  check-types    npm ci, then project's own `types` verb, where node manifest sits
  check-scope    branch name, and every changed path inside branch's folder
  check-commits  commits since base: subject form, scope, test before fix, body, record apart
  check-drift    charter or checker that base gained and branch lacks
  check-role     pull request's role line and label, from ROLE_BODY and ROLE_LABELS
  hook           answer one hook event named as argument, from its JSON or refs on stdin
  test           fetch deps, then testament over tests/t*.nim, on project's own pin
  drive          fetch deps, then project's own `drive` verb, on project's own pin
  fetch-deps     check out what each atlas.lock pins, and confirm checkouts match
  fetch-assets   fetch named files into store, print each path; none named prints table
  list-packages  OS packages koch and projects need, one per line
  list-projects  projects to compile, as JSON for CI matrix
  stamp          print rules stamp; --write sets every Rules row to it

Options:
  --root:<dir>     repository root (default .)
  --branch:<name>  branch to check (default env BRANCH, else current branch)
  --base:<ref>     ref to compare with (default env BASE, else origin/main)
  --all            every project, not only those whose code changed
  --recent         projects whose code merged within last week
  --drive          list-projects keeps projects carrying `drive` verb
  --write          stamp writes every Rules row rather than printing
"""
  ## Text `./koch` prints alone and on usage error; `checker.nim` reads verbs and options here.


type
  Flag = enum
    ## Name option verb may read.
    Root, Branch, Base, All, Recent, Drive, Write

  Options = object
    ## Define parsed command line.
    command: string
    project: string
    rest: seq[string]
    root: string = "."
    branch: string
    base: string
    is_all: bool
    is_recent: bool
    is_drive: bool
    is_write: bool


proc parseOptions(): Option[Options] =
  ## Parse command line; `none` on unknown option or missing command.
  var options = Options()
  for kind, key, value in getopt():
    case kind
    of cmdArgument:
      # Third argument onward is refused for every verb but `fetch-assets`, which names files
      #   rather than one project; refusing them everywhere would make that verb impossible
      #   and accepting them everywhere would let typo pass as argument nothing reads.
      if options.command.len == 0: options.command = key
      elif options.project.len == 0: options.project = key
      elif options.command == "fetch-assets": options.rest.add key
      else: return none(Options)
    of cmdLongOption, cmdShortOption:
      case key
      of "root": options.root = value
      of "branch": options.branch = value
      of "base": options.base = value
      of "all": options.is_all = true
      of "recent": options.is_recent = true
      of "drive": options.is_drive = true
      of "write": options.is_write = true
      else: return none(Options)
    of cmdEnd: discard
  if options.command.len == 0: return none(Options)
  some(options)


func given(options: Options): set[Flag] =
  ## Read options command line set; `--root:.` is default and reads as unset.
  if options.root != ".": result.incl Root
  if options.branch.len > 0: result.incl Branch
  if options.base.len > 0: result.incl Base
  if options.is_all: result.incl All
  if options.is_recent: result.incl Recent
  if options.is_drive: result.incl Drive
  if options.is_write: result.incl Write


func reads(options: Options, flags: set[Flag], has_project = false): bool =
  ## Decide whether command line sets only what verb reads: those options, and project
  ##   argument only where verb takes one.
  options.given <= flags and (has_project or options.project.len == 0)


proc refused(options: Options): int =
  ## Print usage for command given something it does not read; exit code 2.
  stderr.write "koch " & options.command & ": option or argument this verb does not read.\n"
  stderr.write USAGE
  2


proc branchOrDefault(options: Options): string =
  ## Read branch from option, else env `BRANCH`, else current git branch.
  if options.branch.len > 0: return options.branch
  if existsEnv("BRANCH"): return getEnv("BRANCH")
  gitFields(options.root, ["rev-parse", "--abbrev-ref", "HEAD"])[0].strip


proc baseOrDefault(options: Options): string =
  ## Read base from option, else env `BASE`, else `origin/main`.
  if options.base.len > 0: return options.base
  getEnv("BASE", "origin/" & MAIN)


proc plannedJobs(options: Options, tree: Tree): seq[Job] =
  ## Read jobs one run asks for: named project, else window, else every project, else changed.
  if options.project.len > 0:
    tree.jobsFor([options.project.strip(chars = {'/'})])
  elif options.is_recent: recentFor(options.root, tree, RECENT_DAYS)
  elif options.is_all: tree.allJobs
  else: tree.jobs(changedPaths(options.root, options.baseOrDefault))


proc scopedDirsOf(options: Options, tree: Tree): seq[string] =
  ## Read project directories one-job check drives: named one, else those one change asks for.
  ##   Directories rather than jobs, since type check runs on driver's compiler and so needs
  ##   no pin; project pinning none is still type-checked.
  ##   `--recent` scopes to window rather than to base commit, exactly as `list-projects` does
  ##   on schedule; `--all` drops scoping.
  if options.project.len > 0: @[options.project.strip(chars = {'/'})]
  elif options.is_recent: recentFor(options.root, tree, RECENT_DAYS).mapIt(it.directory)
  elif options.is_all: tree.projectDirectories
  else: testSet(tree.projectDirectories, changedPaths(options.root, options.baseOrDefault))


proc markFile(root: string): string =
  ## Read path of check mark, in git dir git names for this checkout.
  markPath(root, gitFields(root, ["rev-parse", "--git-dir"])[0].strip)


proc refuse(found: seq[Finding], code: int): int =
  ## Print findings to stderr for hook host, and return code; zero findings return 0.
  if found.len == 0: return 0
  for f in found: stderr.write f.message & "\n"
  code


proc runHook(root, event, input: string): int =
  ## Answer one hook event from its stdin facts; dispatch over event name.
  let branch = gitFields(root, ["rev-parse", "--abbrev-ref", "HEAD"])[0].strip
  case event
  of "path", "bash", "body", "edit", "stop":
    let
      data = input.parseJson
      tool = data{"tool_name"}.getStr
    case event
    of "path":
      if tool notin EDIT_TOOLS: return 0
      let path = insideRoot(data{"cwd"}.getStr(root), data{"tool_input", "file_path"}.getStr)
      refuse(checkEditPath(branch, path), 2)
    of "bash":
      let is_pushed = gitFields(root, ["branch", "-r", "--contains", "HEAD"]).len > 0
      refuse(checkBash(branch, data{"tool_input", "command"}.getStr, is_pushed), 2)
    of "body":
      if not isPost(tool, data{"tool_input", "body"} != nil): return 0
      let labels = data{"tool_input", "labels"}.getElems.mapIt(it.getStr)
      refuse(checkBody(
        tool, branch, data{"tool_input", "title"}.getStr, data{"tool_input", "body"}.getStr,
        labels, data{"tool_input", "method"}.getStr == "create",
      ), 2)
    of "edit":
      let
        path = insideRoot(data{"cwd"}.getStr(root), data{"tool_input", "file_path"}.getStr)
        tree = root.readTree
      var found = tree.auditTree
      found.add prunedFindings(root, tree)
      let mine = found.filterIt(it.path == path)
      if mine.len == 0: return 0
      let lines = mine.mapIt(it.path & ":" & $it.line & ": " & it.message)
      echo %*{"hookSpecificOutput": {
        "hookEventName": "PostToolUse",
        "additionalContext": "koch check-files reports " & $mine.len & " finding(s) in `" &
          path & "`; fix before push:\n" & lines.join("\n"),
      }}
      0
    else:
      # Second block after one refusal passes, so blocked turn cannot loop forever.
      if data{"stop_hook_active"}.getBool: return 0
      let turn = readFile(data{"transcript_path"}.getStr).parseTurn
      if not turn.calls.turnWrites: return 0
      let found = checkSignoff(turn.text, branch)
      if found.len == 0: return 0
      echo %*{"decision": "block", "reason": "End this turn with sign-off block (GUIDE.md, " &
        "Output contract), since it pushed or posted:\n" & found.mapIt(it.message).join("\n")}
      0
  of "start":
    var drift: seq[Finding]
    try:
      discard gitFields(root, ["fetch", "-q", "origin", MAIN])
      drift = checkBase(gainedPaths(root, "origin/" & MAIN))
    except CatchableError: discard
    echo startContext(
      branch, readFile(root / "CONTRIBUTOR.md"), "## Carry the unchecked list in the open", drift
    )
    0
  of "push":
    let mark = root.markFile
    let recorded = if fileExists(mark): readFile(mark) else: ""
    var found: seq[Finding]
    for line in input.splitLines:
      let fields = line.splitWhitespace
      if fields.len < 2 or fields[1].allCharsInSet({'0'}): continue
      found.add checkPush(recorded, gitFields(root, ["rev-parse", fields[1] & "^{tree}"])[0])
    refuse(found, 1)
  of "msg":
    let
      earlier = subjects(root, getEnv("BASE", "origin/" & MAIN))
      staged = gitFields(root, ["diff", "--cached", "-z", "--name-only"])
    refuse(checkMessage(branch, input, earlier, staged), 1)
  else:
    stderr.write "koch hook: unknown event `" & event & "`.\n"
    2


proc run(options: Options): int =
  ## Execute command, print findings, return exit code.
  var found: seq[Finding]
  case options.command
  of "check":
    # Checks costing about second run first, and any finding among them stops run before
    #   types, suites and drive, which cost minutes and run again once finding is fixed.
    #   Cost: suite failure shows only after static pass is clean.
    if not options.reads({Root, Branch, Base}): return options.refused
    discard gitFields(options.root, ["fetch", "-q", "origin", MAIN])
    let
      tree = options.root.readTree
      (branch, base) = (options.branchOrDefault, options.baseOrDefault)
    found = tree.auditTree
    found.add prunedFindings(options.root, tree)
    found.add checkScope(branch, changedPaths(options.root, base), movedPaths(options.root, base))
    found.add checkHistory(branch, branchCommits(options.root, base))
    found.add checkBase(gainedPaths(options.root, base))
    if found.len > 0:
      found.report
      echo "Types, suites and drive not run; fix findings above, then run again."
      return 1
    found.add typeJobs(options.root, tree, options.scopedDirsOf(tree))
    found.add ciJobs(options.root, tree, tree.jobs(changedPaths(options.root, base)))
    # Green run on clean tree records tree hash, which `pre-push` hook compares against
    #   pushed commit; dirty tree records nothing, since no commit holds exactly what passed.
    if found.len == 0:
      if gitFields(options.root, ["status", "--porcelain"]).len == 0:
        writeFile(
          options.root.markFile, gitFields(options.root, ["rev-parse", "HEAD^{tree}"])[0]
        )
        echo "Tree hash recorded for pre-push hook."
      else: echo "Working tree not clean; nothing recorded for pre-push hook."
  of "check-files":
    if not options.reads({Root}): return options.refused
    let tree = options.root.readTree
    found = tree.auditTree
    found.add prunedFindings(options.root, tree)
  of "check-types":
    if not options.reads({Root, Base, All, Recent}, has_project = true):
      return options.refused
    let tree = options.root.readTree
    found = typeJobs(options.root, tree, options.scopedDirsOf(tree))
  of "check-scope":
    if not options.reads({Root, Branch, Base}): return options.refused
    let base = options.baseOrDefault
    found = checkScope(
      options.branchOrDefault, changedPaths(options.root, base), movedPaths(options.root, base)
    )
  of "check-commits":
    if not options.reads({Root, Branch, Base}): return options.refused
    let commits = branchCommits(options.root, options.baseOrDefault)
    found = checkHistory(options.branchOrDefault, commits)
  of "check-drift":
    if not options.reads({Root, Base}): return options.refused
    found = checkBase(gainedPaths(options.root, options.baseOrDefault))
  of "check-role":
    # Pull request's own two facts, which runner alone holds: they arrive through environment,
    #   never interpolated into script, as branch and event kind already do.
    if not options.reads({Root, Branch}): return options.refused
    let
      named = getEnv("ROLE_LABELS").strip
      labels =
        if named.len == 0: newSeq[string]()
        else: named.parseJson.getElems.mapIt(it.getStr)
    found = checkRole(options.branchOrDefault, getEnv("ROLE_BODY"), labels)
  of "hook":
    # Event name arrives as argument; facts arrive on stdin in event's own protocol, and
    #   answer leaves in that protocol too: exit 2 with stderr refuses tool before it runs,
    #   JSON on stdout feeds context or blocks stop, exit 1 refuses git hook.
    if not options.reads({Root}, has_project = true): return options.refused
    return runHook(options.root, options.project, stdin.readAll)
  of "test":
    if not options.reads({Root, Base, All, Recent}, has_project = true):
      return options.refused
    let tree = options.root.readTree
    found = runJobs(options.root, options.plannedJobs(tree))
  of "drive":
    if not options.reads({Root, Base, All, Recent}, has_project = true):
      return options.refused
    let tree = options.root.readTree
    found = drivenJobs(options.root, tree, options.plannedJobs(tree))
  of "fetch-deps":
    if not options.reads({Root, Base, All, Recent}, has_project = true):
      return options.refused
    let tree = options.root.readTree
    found = restoreJobs(options.root, options.plannedJobs(tree))
  of "fetch-assets":
    # Fetched file is repository's, never one project's: two targets pinning one file would
    #   hold two copies of one digest. Store holds digest; caller names which files it wants,
    #   so what is shared is bytes rather than choice.
    if not options.reads({}, has_project = true): return options.refused
    let root = storeRoot(getEnv(ASSETS_KEY))
    var wanted = options.rest
    if options.project.len > 0: wanted.insert(options.project, 0)
    # Naming no file asks for declaration rather than for bytes: consumer checking whether
    #   name is declared reads published rows, never this module's source.
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
  of "list-packages":
    # Named project answers for that project, which is what runner asks per matrix job.
    #   Named none answers for machine: koch's own packages and every project's, unscoped,
    #   since question is what must be installed rather than what one change touched.
    if not options.reads({Root}, has_project = true): return options.refused
    let
      tree = options.root.readTree
      named =
        if options.project.len > 0:
          systemPackages(options.root, tree, [options.project.strip(chars = {'/'})])
        else: repositorySystem(options.root, tree, tree.projectDirectories)
    for package in named: echo package
    return 0
  of "list-projects":
    if not options.reads({Root, Base, All, Recent, Drive}, has_project = true):
      return options.refused
    let
      tree = options.root.readTree
      jobs = options.plannedJobs(tree)
    echo render(if options.is_drive: tree.drivenOnly(jobs) else: jobs)
    return 0
  of "stamp":
    # Printing serves record written by hand; writing serves duty 1, where every record
    #   moves at once.
    if not options.reads({Root, Write}): return options.refused
    let tree = options.root.readTree
    if options.is_write:
      for path in writeRulesRows(options.root, tree): echo path
    else: echo tree.rulesStamp
    return 0
  else:
    stderr.write USAGE
    return 2
  found.report
  if found.len == 0: 0 else: 1


proc main(): int =
  ## Parse options and run; `./koch` alone prints usage, and usage error exits 2.
  let options = parseOptions()
  if options.isNone:
    stderr.write USAGE
    return 2
  options.get.run


when isMainModule:
  quit main()
