## Drive every check of repository from one compiled program, as Nim's own `koch` does.
##   Build once with `nim c koch`, then `./koch <verb>`; or `nim r koch <verb>`, which
##   rebuilds when sources changed, then runs (Article IX.6); warm run costs ~0.1 s.
##   `USAGE` names every verb and option with its effect, and `./koch` alone prints it.
##     `checker.nim` holds usage, dispatch and CURATOR.md table to one verb set, so no fourth
##     copy lives here.
##
##   Verb names action and its object. `check` runs every check pull request runs but
##     `check-role`, and each `check-<object>` runs one of them; other verbs act (`test`,
##     `drive`, `fix`, `fetch-*`, `stamp`) or print (`list-*`). CI job running verb carries
##     verb's name, so red job names command to run locally.
##   Verb of one project is that project's own, in its `tools/build.nim`; koch names verb and
##     selects projects carrying it, and holds none of what it does. `check-types` runs
##     project's `types`, `drive` its `drive`, `head` its `head`, and `list-packages` its
##     `system`. Koch learns which projects carry `drive`, `head` and `system` by reading that
##     driver's own dispatch, and which carry `types` by node manifest beside its lock; never
##     from list.
##   `head` is no `check-` verb, and `check` never runs it: its verdict varies with outside
##     reference rather than with code, so `head.yml` runs it daily, and merge waits on none.
##     `releases` is none either, for same reason: it asks nim-lang.org, and `nim.yml` runs it.
##   `check-types` runs on driver's compiler and `drive` on project's own, because type check
##     compiles no project code and drive does: it builds page through JS backend. So `drive`
##     is planned like `test`, through `list-projects --drive`, and reaches CI as matrix.
##   Verb taking projects reads named one, else `--recent` window, else `--all`, else those
##     whose code changed against base. Verb refuses option or argument it does not read, with
##     usage and exit 2, so typo never passes as input nothing reads.
##     Exit: 0 clean, 1 findings, 2 usage error.
##   Each verb that reports prints each finding and warning through renderer of knoller
##     (STYLE.md §3): terminal form, with text of its line from disk, where stdout is terminal,
##     else one line each; `--form` forces either, and koch of merge takes it too. Color shows at
##     terminal alone, and `NO_COLOR` set to any text drops it (`output`). Rewrite of `fix`
##     stays on one line of its own, since it is no finding.
##   `check-role` reads pull request rather than tree, so runner hands it two inputs through
##     env: `ROLE_BODY` from event payload, and `ROLE_LABELS` from API as JSON array of label
##     names. That is why `check` leaves it out: local run has no pull request to read.
##
##   `check` compiles only projects whose code changed, since static pass is cheap next to
##     suites that compile and test (`curator/audit/PROVENANCE.md`, Figures); push run on `main`
##     and weekly run do same against their own base, so nothing compiles every project
##     (CURATOR.md duty 11). Matrix runs each on its own pin, as `check` does locally:
##     `compilers.nim` of knoller serves each changed project's pin from PATH, cache or fetch, so
##     which compiler PATH holds decides nothing.
##   `check` judges clean checkout lacking base as merged with it, by koch of that merge, in
##     second tree under git dir, as runner judges merge ref (`merge.nim`); drift, branch name
##     and mark read checkout itself. Detached HEAD, as second tree holds, records no mark.
##
##   Each verb first points git at `.githooks` (`setPathHooks` of `tree.nim`), so each harness
##     running koch gets git hooks; it reads first, prints nothing, and fails no verb.
##   Rejected: verb of its own for it, which reaches only harness following instruction, and
##     adds verb to table, usage text and dispatch.
##
##   Rejected: make (second toolchain, recipe tabs, untested glue); NimScript tasks (compiler
##     VM subset, script loaded on every compile, task names shadow compiler commands,
##     untestable). Chosen: compiled driver, as Nim's repository builds with `koch`.
##   Rejected: verb and object as two words (`koch check files`), which puts second dispatch
##     inside first and makes project argument third. Hyphen keeps one word per verb.
##   Cost: root file outside any project; every check it drives is library module under
##     `curator/audit/src`, tested there; this file holds dispatch only.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[algorithm, json, options, os, parseopt, sequtils, sets, strutils, tables, terminal]
import ./curator/audit/src/[
  assets,
  audit,
  base,
  claims_log,
  claims_scores,
  commits,
  domains,
  findings,
  fixes,
  hooks,
  lags,
  merge,
  packages_node,
  plan,
  projects,
  releases,
  role,
  schemas,
  scope,
  symbols,
  tree,
]
import ./curator/knoller/src/knoller


const USAGE = """
Usage: koch <verb> [project | file...] [options]

Verbs:
  check          every check of pull request but check-role; quick first, stopping on own finding
  check-files    static checks over every file git lists; compiles nothing
  check-types    npm ci, then project's own `types` verb, where node manifest sits
  check-scope    branch name, and every changed path inside branch's folder
  check-commits  commits since base: subject form, scope, test before fix, body, record apart
  check-drift    each charter section and checker path base changed since branch forked
  check-schemas  each folder of protobuf schemas branch changed, against version base shipped
  check-role     pull request's role line, label, title and form of body, from ROLE_* env
  claims         move rows of log of claims that wait outside tree into log of branch
  figures        figures of each log of claims, by marker, then by fields named as `kind,effort`
  hook           answer one hook event named as argument, from its JSON or refs on stdin
  test           fetch deps, then testament over tests/t*.nim, on project's own pin
  drive          fetch deps, project's own `drive` verb on its own pin, then judge its font faces
  head           fetch deps, then project's own `head` verb, on project's own pin
  releases       ask nim-lang.org for later Nim releases; exit 1 where driver lags, 2 on failure
  advisories     ask npm for advisories of each node lock; exit 1 on one, 2 on failure
  fix            apply in place each fix checks name, refusing all where path is out of scope
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
  --head           list-projects keeps projects carrying `head` verb
  --node           list-projects keeps projects carrying node manifest beside its lock
  --write          stamp writes every Rules row rather than printing
  --dry-run        fix prints each change it would make, writes none, exits 1 where any
  --form:<form>    finding form, `terminal` or `line` (default terminal at terminal, else line)
"""
  ## Text `./koch` prints alone and on usage error; `checker.nim` reads verbs and options here.


const
  FORM_TERMINAL = "terminal"  ## Value of `--form` that prints each finding in terminal form.
  FORM_LINE = "line"  ## Value of `--form` that prints each finding on one line.


type
  Flag = enum  ## Name option verb may read.
    Root, Branch, Base, All, Recent, Drive, Head, Node, Write, DryRun, FormFinding

  Options = object  ## Define parsed command line.
    command: string
    project: string
    rest: seq[string]
    root: string = "."
    branch: string
    base: string
    is_all: bool
    is_recent: bool
    is_drive: bool
    is_head: bool
    is_node: bool
    is_write: bool
    is_dry_run: bool
    form: string  ## Form `--form` names, as given; empty where none.


proc parseOptions(): Option[Options] =
  ## Parse command line; `none` on unknown option or missing command.
  var options = Options()
  for kind, key, value in getopt():
    case kind
    of cmdArgument:
      # Third argument onward is refused for every verb but `fetch-assets` and `fix`, which
      #   name files rather than one project; refusing them everywhere would make those verbs
      #   impossible and accepting them everywhere would let typo pass as argument nothing reads.
      if options.command.len == 0: options.command = key
      elif options.project.len == 0: options.project = key
      elif options.command in ["fetch-assets", "fix"]: options.rest.add key
      else: return none(Options)
    of cmdLongOption, cmdShortOption:
      case key
      of "root": options.root = value
      of "branch": options.branch = value
      of "base": options.base = value
      of "all": options.is_all = true
      of "recent": options.is_recent = true
      of "drive": options.is_drive = true
      of "head": options.is_head = true
      of "node": options.is_node = true
      of "write": options.is_write = true
      of "dry-run": options.is_dry_run = true
      of "form": options.form = value
      else: return none(Options)
    of cmdEnd: discard
  if options.command.len == 0 or options.form notin ["", FORM_TERMINAL, FORM_LINE]:
    return none(Options)
  some(options)


func given(options: Options): set[Flag] =
  ## Read options command line set; `--root:.` is default and reads as unset.
  if options.root != ".": result.incl Root
  if options.branch.len > 0: result.incl Branch
  if options.base.len > 0: result.incl Base
  if options.is_all: result.incl All
  if options.is_recent: result.incl Recent
  if options.is_drive: result.incl Drive
  if options.is_head: result.incl Head
  if options.is_node: result.incl Node
  if options.is_write: result.incl Write
  if options.is_dry_run: result.incl DryRun
  if options.form.len > 0: result.incl FormFinding


func isReadAll(options: Options, flags: set[Flag], has_project = false): bool =
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
  fieldsGit(options.root, ["rev-parse", "--abbrev-ref", "HEAD"])[0].strip


proc baseOrDefault(options: Options): string =
  ## Read base from option, else env `BASE`, else `origin/main`.
  if options.base.len > 0: return options.base
  getEnv("BASE", "origin/" & MAIN)


proc jobsPlanned(options: Options, tree: Tree): seq[Job] =
  ## Read jobs one run asks for: named project, else window, else every project, else changed.
  if options.project.len > 0:
    tree.jobsFor([options.project.strip(chars = {'/'})])
  elif options.is_recent: recentFor(options.root, tree, DAYS_RECENT)
  elif options.is_all: tree.jobsAll
  else: tree.jobs(pathsChanged(options.root, options.baseOrDefault))


proc directoriesScoped(options: Options, tree: Tree): seq[string] =
  ## Read project directories one-job check drives: named one, else those one change asks for.
  ##   Directories rather than jobs, since type check runs on driver's compiler and so needs
  ##   no pin; project pinning none is still type-checked.
  ##   `--recent` scopes to window rather than to base commit, exactly as `list-projects` does
  ##   on schedule; `--all` drops scoping.
  if options.project.len > 0: @[options.project.strip(chars = {'/'})]
  elif options.is_recent: recentFor(options.root, tree, DAYS_RECENT).mapIt(it.directory)
  elif options.is_all: tree.directoriesProject
  else:
    let directories = tree.directoriesProject
    projectsTest(
      directories,
      pathsChanged(options.root, options.baseOrDefault),
      tree.importersByFolder(directories),
    )


proc branch(checkout: string): string =
  ## Read branch checked out in checkout.
  fieldsGit(checkout, ["rev-parse", "--abbrev-ref", "HEAD"])[0].strip


proc refuse(found: seq[Finding], code: int): int =
  ## Print findings to stderr for hook host, each in line form, help last (ruling 7197275206 of
  ##   #1002), and return code; zero findings return 0.
  if found.len == 0: return 0
  for f in found: stderr.write f.toLine & "\n"
  code


proc runHook(root, event, input: string): int =
  ## Answer one hook event from its stdin facts; dispatch over event name.
  ##   `path`, `edit` and `bash` read checkout call acts in, never root alone: subagent works
  ##     in worktree of its own, on branch of its own (GUIDE.md, Work for subagents). Call
  ##     acting in other repository is that repository's, so these three pass it unread.
  ##   `path` and `edit` read checkout and path of file write names through `fileWritten`, which
  ##     both events and suite call; file outside every checkout reads as none, so both pass it.
  ##   `path` judges through `checkPathEditMoved`, which suite calls too: name line of moved lock
  ##     passes, as `check-scope` does, against base koch compares with, i.e. env `BASE`, else
  ##     `origin/main`.
  let branch_root = root.branch
  case event
  of "path", "bash", "body", "edit", "stop":
    let
      data = input.parseJson
      tool = data{"tool_name"}.getStr
      directory = data{"cwd"}.getStr(root)
    case event
    of "path":
      if tool notin TOOLS_EDIT: return 0
      let written = fileWritten(root, directory, data{"tool_input"})
      if written.isNone: return 0
      let
        (checkout, path) = written.get
        base = getEnv("BASE", "origin/" & MAIN)
      refuse(checkPathEditMoved(checkout, checkout.branch, path, base, tool, data{"tool_input"}), 2)
    of "bash":
      let
        command = data{"tool_input", "command"}.getStr
        checkout = checkoutAt(root, directoryCommand(command, directory))
      var found: seq[Finding]
      if checkout.isSome:
        let is_pushed = fieldsGit(checkout.get, ["branch", "-r", "--contains", "HEAD"]).len > 0
        found = checkBash(checkout.get.branch, command, is_pushed)
      # Post through `gh api` speaks for delegate, so role line reads root's branch, as `body` does.
      found.add checkPosts(branch_root, command, directory)
      refuse(found, 2)
    of "body":
      if not isPost(tool, data{"tool_input", "body"} != nil): return 0
      let labels = data{"tool_input", "labels"}.getElems.mapIt(it.getStr)
      refuse(
        checkBody(
          tool,
          branch_root,
          data{"tool_input", "title"}.getStr,
          data{"tool_input", "body"}.getStr,
          labels,
          data{"tool_input", "method"}.getStr == "create",
        ),
        2,
      )
    of "edit":
      let written = fileWritten(root, directory, data{"tool_input"})
      if written.isNone: return 0
      let
        (checkout, path) = written.get
        tree = checkout.readTree
      var found = tree.auditTree
      found.add findingsPruned(checkout, tree)
      # Held finding blocks no push, so it is named apart, for its project (duty 3); base
      #   unread leaves no line owned, and `koch check` still reads it before push.
      let owned =
        try: linesOwned(checkout, tree, "origin/" & MAIN)
        except IOError: initTable[string, HashSet[int]]()
      let
        (held, own) = splitHeld(checkout.branch, found.filterIt(it.path == path), owned)
        named = contextFindings(path, held, own)
        skill = contextEdit(path)
      if named.len == 0 and skill.len == 0: return 0
      var parts: seq[string]
      if named.len > 0: parts.add named
      if skill.len > 0: parts.add skill
      echo %*{"hookSpecificOutput": {
        "hookEventName": "PostToolUse",
        "additionalContext": parts.join("\n"),
      }}
      0
    else:
      # Each row of reflection of turn reaches log of claims at every stop, reply to refusal
      #   too; key keeps row from second write, and failed write blocks no turn (`logStop`).
      let
        turn = readFile(data{"transcript_path"}.getStr).parseTurn
        kinds = readKinds(root)
      discard logStop(root, branch_root, pathWaiting(), turn.subagents)
      # Second block after one refusal passes, so blocked turn cannot loop forever.
      if data{"stop_hook_active"}.getBool: return 0
      var found = checkNumbersBare(turn.text)
      found.add checkReferencesBare(turn.text)
      found.add checkLinksReference(turn.text)
      found.add checkEndTurn(turn.text, branch_root, is_writing = turn.calls.isTurnWriting)
      # Merge commit names its pull request, so group of earlier sign-off may drop once main
      #   holds it; first-parent subjects are main's own, and failure of git reads as none.
      if turn.isSignoffEarlier and turn.text.isSignoff:
        let subjects =
          try: fieldsGit(root, ["log", "--first-parent", "-z", "--format=%s", "origin/" & MAIN])
          except IOError: @[]
        found.add checkSignoffWindow(
          turn.text, branch_root, turn.signoffs_earlier, subjects, turn.signoffs_before
        )
      let unread = checkSignoffRead(turn.text, turn.calls)
      # Blocks of subagents hold at end of every model turn, for kinds root names now.
      let blocks = turn.subagents.checkBlocks(kinds)
      if found.len == 0 and unread.len == 0 and blocks.len == 0: return 0
      let has_signoff = turn.text.isSignoff
      echo %*{"decision": "block", "reason": reasonStop(found, unread, has_signoff, blocks)}
      0
  of "prompt":
    # Line names skill of moment message holds; it adds context, and never blocks message.
    let context = contextPrompt(input.parseJson{"prompt"}.getStr)
    if context.len == 0: return 0
    echo %*{"hookSpecificOutput": {
      "hookEventName": "UserPromptSubmit",
      "additionalContext": context,
    }}
    0
  of "start":
    var
      drift: seq[Finding]
      notices: seq[string]
    try:
      discard fieldsGit(root, ["fetch", "-q", "origin", MAIN])
      drift = checkBase(readDrift(root, "origin/" & MAIN))
    except CatchableError: discard
    # Commits of lock that lag `main` read what fetch brought, or what checkout held before.
    try: notices = noticesLag(readLags(root, "origin/" & MAIN), "origin/" & MAIN)
    except CatchableError: discard
    # Nim pins that lag pin of driver read checkout as it stands; read that fails names none.
    try: notices.add noticesPin(readPins(root))
    except CatchableError: discard
    # Past figures of each kind come from logs of tree; log that reads no row names its fault.
    let rates = root.ratesTree
    # Record branch works on is read where it exists; new project has none until it writes one.
    #   File of role is read same way, in `readPrompt`, where suite reaches it.
    let record = branch_root.pathRecord
    echo contextStart(
      branch_root,
      readPrompt(root, branch_root),
      readFile(root / "CONTRIBUTOR.md"),
      "## Carry the unchecked list in the open",
      if record.len > 0 and fileExists(root / record): readFile(root / record) else: "",
      drift,
      notices,
      rates,
    )
    0
  of "push":
    let
      mark = root.fileMark
      recorded = if fileExists(mark): readFile(mark) else: ""
    var found: seq[Finding]
    for line in input.splitLines:
      let fields = line.splitWhitespace
      if fields.len < 2 or fields[1].allCharsInSet({'0'}): continue
      found.add checkPush(recorded, fieldsGit(root, ["rev-parse", fields[1] & "^{tree}"])[0])
    refuse(found, 1)
  of "msg":
    let
      earlier = subjects(root, getEnv("BASE", "origin/" & MAIN))
      staged = fieldsGit(root, ["diff", "--cached", "-z", "--name-only"])
    refuse(checkMessage(branch_root, input, earlier, staged), 1)
  else:
    stderr.write "koch hook: unknown event `" & event & "`.\n"
    2


proc output(options: Options, file = stdout): tuple[form: Form, is_colored: bool] =
  ## Read form each finding prints in on file, and whether it takes color: form `--form` names,
  ##   else terminal form where file is terminal (STYLE.md §3); color at terminal alone, and
  ##   `NO_COLOR` set to any text drops it.
  let
    is_terminal = file.isatty
    forced =
      if options.form == FORM_TERMINAL: some(Form.Terminal)
      elif options.form == FORM_LINE: some(Form.Line)
      else: none(Form)
    form = formOutput(is_terminal, forced)
  (form, form == Form.Terminal and isColored(is_terminal, getEnv("NO_COLOR")))


proc sourcesRead(root: string, found: openArray[Finding]): Table[string, string] =
  ## Read text of each file finding names at its line, from disk under root, so terminal form
  ##   shows that line; path naming no file reads none.
  for f in found:
    if f.line > 0 and f.path.len > 0 and f.path notin result and fileExists(root / f.path):
      result[f.path] = readFile(root / f.path)


proc report(found: seq[Finding], options: Options) =
  ## Print findings, then count, through renderer in form options ask (`findings.report`).
  let (form, is_colored) = options.output
  found.report(form, is_colored, options.root.sourcesRead(found))


proc warn(found: seq[Finding], options: Options) =
  ## Print each finding as warning, through renderer in form options ask, with no count; terminal
  ##   form takes blank line after last.
  let
    (form, is_colored) = options.output
    lines = found.rendered(form, is_colored, options.root.sourcesRead(found), is_warning = true)
  for line in lines: echo line
  if form == Form.Terminal and found.len > 0: echo ""


proc reportHeld(held: seq[Finding], options: Options) =
  ## Print findings branch holds for their projects, which each clears in its next pull request
  ##   (CURATOR.md, duty 3); nothing where none is held.
  if held.len == 0: return
  echo "Held for their projects (CURATOR.md, duty 3, and the skill /enact); each clears them " &
    "in its next pull request:"
  held.report(options)


proc checkInPlace(options: Options; branch, base: string): int =
  ## Run every check of `koch check` on checkout itself, then record mark where all pass; exit
  ##   code. `judgeCheckout` of `merge.nim` calls it for checkout it judges in place.
  ##   Static checks run first, since they are cheap next to types, suites and drive, which
  ##     compile and test; any finding among them stops run before those, which run again once
  ##     finding is fixed.
  ##   Cost: suite failure shows only after static pass is clean.
  ##   Cost: no suite runs `main` of koch, so this order, and call of `recordMark` after green
  ##     run, hold by hand: read on 2026-11-15, and run that day as `nim r koch check` in place
  ##     on branch holding `origin/main`, which recorded tree of HEAD
  ##     (`curator/audit/PROVENANCE.md`, Merge with base).
  let tree = options.root.readTree
  var found = tree.auditTree
  found.add findingsPruned(options.root, tree)
  found.add checkScope(branch, pathsChanged(options.root, base), pathsMoved(options.root, base))
  found.add checkHistory(branch, commitsBranch(options.root, base))
  found.add checkBase(readDrift(options.root, base))
  found.add checkSchemas(options.root, base)

  # Finding inside project blocks only branch of role owning it (duty 3), and finding on line
  #   branch changed blocks it wherever it lies; rest blocks here.
  let (held, own) = splitHeld(branch, found, linesOwned(options.root, tree, base))
  held.reportHeld(options)
  # Commit of lock that lags `main` is named, and fails nothing (D2 of #927); start prints same.
  for line in noticesLag(readLags(options.root, "origin/" & MAIN), "origin/" & MAIN): echo line
  # Nim pin that lags pin of driver is named, and fails nothing (GUIDE.md, Toolchain); start too.
  for line in noticesPin(readPins(options.root)): echo line
  if own.len > 0:
    own.report(options)
    echo "Types, suites and drive not run; fix findings above, then run again."
    return 1

  # Compile and test, then ask semantic pass, which runs once restore stands (D1 of #558).
  found = own
  found.add runJobsType(options.root, tree, options.directoriesScoped(tree))
  let jobs = tree.jobs(pathsChanged(options.root, base))
  found.add runJobsCi(options.root, tree, jobs)
  let (converted, unread) = checkConversions(options.root, tree, jobs.mapIt(it.directory))
  found.add converted
  unread.warn(options)

  # Green run records tree for `pre-push` hook, where checkout is clean and on branch.
  if found.len == 0: options.root.recordMark
  found.report(options)
  if found.len == 0: 0 else: 1


proc run(options: Options): int =
  ## Execute command, print findings, return exit code.
  var found: seq[Finding]
  case options.command
  of "check":
    # Clean checkout lacking base is judged as merged with it, by koch of that merge, as runner
    #   judges merge ref, and any other checkout in place (`judgeCheckout`); drift, branch name
    #   and mark read this checkout.
    #   Cost: no suite runs this arm, so its fetch, and proc giving `checkInPlace` branch and
    #     base, hold by hand (`curator/audit/PROVENANCE.md`, Merge with base).
    if not options.isReadAll({Root, Branch, Base, FormFinding}): return options.refused
    let (branch, base) = (options.branchOrDefault, options.baseOrDefault)
    # Base runner compares with is fetched fresh; koch of merge is handed commit, fetching none.
    if base == "origin/" & MAIN: discard fieldsGit(options.root, ["fetch", "-q", "origin", MAIN])
    var toolchains = initToolchains()
    let (form, is_colored) = options.output
    return judgeCheckout(
      options.root,
      base,
      branch,
      toolchains,
      proc(): int = options.checkInPlace(branch, base),
      options.form,
      form,
      is_colored,
    )
  of "check-files":
    if not options.isReadAll({Root, Branch, Base, FormFinding}): return options.refused
    let tree = options.root.readTree
    found = tree.auditTree
    found.add findingsPruned(options.root, tree)
    # Runner holds as hook does, so check that reddens project lands once rest is clean.
    let (held, own) = splitHeld(
      options.branchOrDefault, found, linesOwned(options.root, tree, options.baseOrDefault)
    )
    held.reportHeld(options)
    found = own
  of "check-types":
    if not options.isReadAll({Root, Base, All, Recent, FormFinding}, has_project = true):
      return options.refused
    let tree = options.root.readTree
    found = runJobsType(options.root, tree, options.directoriesScoped(tree))
  of "check-scope":
    if not options.isReadAll({Root, Branch, Base, FormFinding}): return options.refused
    let base = options.baseOrDefault
    found = checkScope(
      options.branchOrDefault,
      pathsChanged(options.root, base),
      pathsMoved(options.root, base),
    )
  of "check-commits":
    if not options.isReadAll({Root, Branch, Base, FormFinding}): return options.refused
    let commits = commitsBranch(options.root, options.baseOrDefault)
    found = checkHistory(options.branchOrDefault, commits)
  of "check-drift":
    if not options.isReadAll({Root, Base, FormFinding}): return options.refused
    found = checkBase(readDrift(options.root, options.baseOrDefault))
  of "check-schemas":
    if not options.isReadAll({Root, Base, FormFinding}): return options.refused
    found = checkSchemas(options.root, options.baseOrDefault)
  of "check-role":
    # Pull request's own facts, which runner alone holds: they arrive through environment,
    #   never interpolated into script, as branch and event kind already do.
    if not options.isReadAll({Root, Branch, FormFinding}): return options.refused
    let
      named = getEnv("ROLE_LABELS").strip
      labels =
        if named.len == 0: newSeq[string]()
        else: named.parseJson.getElems.mapIt(it.getStr)
    found = checkRole(options.branchOrDefault, getEnv("ROLE_BODY"), labels)
    found.add checkTitle(options.branchOrDefault, getEnv("ROLE_TITLE"))
    found.add checkBodyPull(getEnv("ROLE_BODY"))
  of "claims":
    # Rows of checkout outside grammar wait outside tree, as root curator's do, since hook
    #   never writes in detached checkout; branch inside grammar takes them into its log.
    if not options.isReadAll({Root}): return options.refused
    let
      branch = options.root.branch
      (moved, path) = moveClaims(options.root, branch, pathWaiting())
    if path.len == 0:
      stderr.writeLine "Rows outside tree are of root curator, so root branch alone takes them; " &
        "got `" & branch & "`."
      return 1
    echo $moved & " row(s) moved to `" & path & "`."
    return 0
  of "figures":
    # Logs of each project join, as #964 asks; argument names fields of groups, as `kind,effort`.
    if not options.isReadAll({Root}, has_project = true): return options.refused
    var lines: seq[string]
    # Row or field that reads no way, and root that holds no repository, each name fault.
    try: lines = linesTree(options.root, options.project)
    except CatchableError as error:
      stderr.writeLine error.msg
      return 1
    for line in lines: echo line
    return 0
  of "hook":
    # Event name arrives as argument; facts arrive on stdin in event's own protocol, and
    #   answer leaves in that protocol too: exit 2 with stderr refuses tool before it runs,
    #   JSON on stdout feeds context or blocks stop, exit 1 refuses git hook.
    if not options.isReadAll({Root}, has_project = true): return options.refused
    return runHook(options.root, options.project, stdin.readAll)
  of "test":
    if not options.isReadAll({Root, Base, All, Recent, FormFinding}, has_project = true):
      return options.refused
    let
      tree = options.root.readTree
      jobs = options.jobsPlanned(tree)
    found = runJobs(options.root, jobs)
    let (converted, unread) = checkConversions(options.root, tree, jobs.mapIt(it.directory))
    found.add converted
    unread.warn(options)
  of "drive":
    if not options.isReadAll({Root, Base, All, Recent, FormFinding}, has_project = true):
      return options.refused
    let tree = options.root.readTree
    found = runJobsDriven(options.root, tree, options.jobsPlanned(tree))
  of "head":
    if not options.isReadAll({Root, Base, All, Recent, FormFinding}, has_project = true):
      return options.refused
    let tree = options.root.readTree
    found = jobsHead(options.root, tree, options.jobsPlanned(tree))
  of "releases":
    # Asks reach nim-lang.org, whose answer moves with no commit here, so `nim.yml` runs verb
    #   weekly and `check` never does; search and lines are `releases.nim`'s, offline in suite.
    #   Failure of search exits 2, as usage error does, so `nim.yml` reads exit 1 as lag alone.
    if not options.isReadAll({Root}): return options.refused
    let (lines, named, failure) = checkReleases(readPins(options.root), askRelease)
    for line in lines: echo line
    if failure.len > 0:
      stderr.write "koch releases: " & failure & "\n"
      return 2
    found = named
  of "advisories":
    # Asks reach npm registry, whose answer moves with no commit here, so `npm.yml` runs verb
    #   weekly and `check` never does; search and lines are `packages_node.nim`'s, offline in
    #   suite. Failure of search exits 2, so `npm.yml` reads exit 1 as advisory alone.
    if not options.isReadAll({Root, Base, All, Recent}, has_project = true):
      return options.refused
    let
      tree = options.root.readTree
      directories = tree.directoriesNode(options.directoriesScoped(tree))
    # Project named with no lock asks npm nothing, so its exit 0 would close issue of lock it lost.
    if options.project.len > 0 and directories.len == 0:
      stderr.write "koch advisories: project carries no node manifest beside its lock; got `" &
        options.project & "`.\n"
      return 2
    let (lines, named, failure) =
      checkAdvisories(readLocked(options.root, directories), askAudit, askLatest)
    for line in lines: echo line
    if failure.len > 0:
      stderr.write "koch advisories: " & failure & "\n"
      return 2
    found = named
  of "fix":
    # Fixers, file selection and scope refusal live in `fixes.nim`; koch writes and prints.
    #   Named files or directories come first, else projects `--recent`, `--all` or change
    #   selects, as every verb taking projects reads them. Dry run writes nothing, prints each
    #   change as `path:line: <rule> to fix`, and exits 1 where any would apply. File fix
    #   leaves as written, i.e. locked nimble file or fence it cannot read, prints with reason.
    #   Each fence prints as warning naming each rule broken inside it, so lines no fixer reads
    #   stay in view; so does each file knoller's fixers do not settle, with no article, since
    #   fault is tool's. Exit code ignores warnings.
    #   Compiler and disk under root give what fixers read across project (`fixes.readFacts`).
    #   Names of each project entries name, and renames they ask, are read once, for semantic
    #   pass and fixers alike (`fixes.renames`); pass then runs on files holding candidate text
    #   cannot settle (`symbols.nim`). Parser of each project's pin proves each needless group
    #   (`fixes.fixProven`); run that proved nothing prints one warning saying why.
    if not options.isReadAll(
      {Root, Branch, Base, All, Recent, DryRun, FormFinding}, has_project = true
    ):
      return options.refused
    let
      tree = options.root.readTree
      named = (if options.project.len > 0: @[options.project] else: @[]) & options.rest
      (entries, unknown) = tree.entriesNamed(
        if named.len > 0: named else: options.directoriesScoped(tree)
      )
    if unknown.len > 0:
      unknown.report(options)
      return 1
    let
      locked = tree.nimblesLocked
      (uses, pures, libraries) = readFacts(options.root, entries, locked)
      names = tree.namesEntries(entries, libraries)
      renamed = tree.renames(entries, locked, names)
      answers = resolve(options.root, tree, tree.queriesSemantic(entries, locked, renamed))
      (fix, failures) = fixProven(
        options.branchOrDefault,
        tree,
        entries,
        locked,
        initContext(tree, entries, answers, locked, uses, pures, names, renamed),
        proversPin(initToolchains()),
      )
      (written, fixed, refused, left, warned, _) = fix
      (form, is_colored) = options.output
      sources = options.root.sourcesRead(left & warned)
    var lines = left.rendered(form, is_colored, sources)
    lines.add warned.rendered(form, is_colored, sources, is_warning = true)
    for failure in failures: lines.add [failure].rendered(form, is_colored, is_warning = true)
    if form == Form.Terminal and lines.len > 0: lines.add ""
    for line in lines: echo line
    if refused.len > 0:
      refused.report(options)
      echo "Nothing written; fix writes only inside branch scope."
      return 1
    let outcome = if options.is_dry_run: " to fix" else: " fixed"
    if not options.is_dry_run:
      for e in written: writeFile(options.root / e.path, e.content)
    for f in fixed.sorted: echo f.render & outcome
    echo $fixed.len & outcome & "."
    return if options.is_dry_run and fixed.len > 0: 1 else: 0
  of "fetch-deps":
    if not options.isReadAll({Root, Base, All, Recent, FormFinding}, has_project = true):
      return options.refused
    let tree = options.root.readTree
    found = restoreJobs(options.root, options.jobsPlanned(tree))
  of "fetch-assets":
    # Fetched file is repository's, never one project's: two targets pinning one file would
    #   hold two copies of one digest. Store holds digest; caller names which files it wants,
    #   so what is shared is bytes rather than choice.
    if not options.isReadAll({FormFinding}, has_project = true): return options.refused
    let root = rootStore(getEnv(KEY_ASSETS))
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
        found.add(if file.digestDeclared.len == 0: unknown(file) else: unfetched(file))
      else: echo path
    if found.len == 0: return 0
  of "list-packages":
    # Named project answers for that project, which is what runner asks per matrix job.
    #   Named none answers for machine: koch's own packages and every project's, unscoped,
    #   since question is what must be installed rather than what one change touched.
    #   Driver that fails is named on stderr, since runner pipes stdout into installer, and exit
    #   is 1, so step that installs goes red rather than suite that needs package (#934).
    if not options.isReadAll({Root, FormFinding}, has_project = true): return options.refused
    let
      tree = options.root.readTree
      (named, failed) =
        if options.project.len > 0:
          packagesSystem(options.root, tree, [options.project.strip(chars = {'/'})])
        else: systemRepository(options.root, tree, tree.directoriesProject)
    let (form, is_colored) = options.output(stderr)
    for package in named: echo package
    for line in failed.rendered(form, is_colored): stderr.write line & "\n"
    return if failed.len > 0: 1 else: 0
  of "list-projects":
    if not options.isReadAll({Root, Base, All, Recent, Drive, Head, Node}, has_project = true):
      return options.refused
    let tree = options.root.readTree
    var jobs = options.jobsPlanned(tree)
    if options.is_drive: jobs = tree.drivenOnly(jobs)
    if options.is_head: jobs = tree.carryingOnly(jobs, VERB_HEAD)
    if options.is_node: jobs = jobs.filterIt(tree.directoriesNode([it.directory]).len > 0)
    echo render(jobs)
    return 0
  of "stamp":
    # Printing serves record written by hand; writing serves duty 1, where every record
    #   moves at once.
    if not options.isReadAll({Root, Write}): return options.refused
    let tree = options.root.readTree
    if options.is_write:
      for path in writeRowsRules(options.root, tree): echo path
    else: echo tree.stampRules
    return 0
  else:
    stderr.write USAGE
    return 2
  found.report(options)
  if found.len == 0: 0 else: 1


proc main(): int =
  ## Parse options, point git at hooks of checkout, and run; `./koch` alone prints usage, and
  ##   usage error exits 2.
  let options = parseOptions()
  if options.isNone:
    stderr.write USAGE
    return 2
  options.get.root.setPathHooks
  options.get.run


when isMainModule:
  quit main()
