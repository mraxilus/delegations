## Drive every check of repository from one compiled program, as Nim's own `koch` does.
##   Build once with `nim c koch`, then `./koch <command>`; or `nim r koch <command>`, which
##   rebuilds when sources changed, then runs (Article IX.6); warm run costs ~0.1 s.
##
##   |---------|-------------------------------------------------------------------------|
##   | Command | Effect                                                                  |
##   |---------|-------------------------------------------------------------------------|
##   | tree    | layout, form, comments, provenance, glossary over files git sees        |
##   | deps    | `atlas --noexec rep` in every project holding atlas.lock, or in one     |
##   | tests   | restore, then testament over tests/t*.nim, every project or one         |
##   | plan    | projects one change asks to compile, as JSON for CI matrix              |
##   | scope   | changed paths against branch prefix           (--branch, --base)        |
##   | commits | commit subjects against branch scope          (--branch, --base)        |
##   | stamp   | print rules stamp for PROVENANCE.md                                     |
##   | ci      | fetch origin/main, then tree, changed projects, scope, commits, base    |
##   |---------|-------------------------------------------------------------------------|
##   Options: `--root:<dir>` (default `.`); `--branch:<name>` (default env `BRANCH`, else
##     current git branch); `--base:<ref>` (default env `BASE`, else `origin/main`); `--all`
##     makes `plan` name every project; `--sweep` names every project only when code merged
##     within window, else none. Second argument of `deps` and `tests` names one project
##     directory. Exit: 0 clean, 1 findings, 2 usage error.
##
##   `ci` compiles only projects whose code changed, since static pass costs tenths of
##     second and suites cost minutes. Whole repository is swept by CI matrix, one job per
##     project on its own pin, never by one local verb: pins differ, and one machine holds
##     one compiler on PATH.
##   Compiler on PATH must equal changed project's pin, else finding and no compile: wrong
##     compiler either fails confusingly or passes without testing what CI will run.
##
##   Rejected: make (second toolchain, recipe tabs, untested glue); NimScript tasks (compiler
##     VM subset, script loaded on every compile, task names shadow compiler commands,
##     untestable). Chosen: compiled driver, as Nim's repository builds with `koch`.
##   Cost: root file outside any project; every check it drives is library module under
##     `curator/audit/src`, tested there; this file holds dispatch only.

{.experimental: "strictFuncs".}

import std/[options, os, parseopt, strutils]
import ./curator/audit/src/[
  findings, domains, scope, commits, tree, dependencies, audit, plan, base,
]


const USAGE = """
Usage: koch <tree|deps|tests|plan|scope|commits|base|stamp|ci> [project]
            [--root:<dir>] [--branch:<name>] [--base:<ref>] [--all] [--sweep]
"""
  ## Text printed on usage error.


type Options = object
  ## Define parsed command line.
  command: string
  project: string
  root: string = "."
  branch: string
  base: string
  is_all: bool
  is_sweep: bool


proc parseOptions(): Option[Options] =
  ## Parse command line; `none` on unknown option or missing command.
  var options = Options()
  for kind, key, value in getopt():
    case kind
    of cmdArgument:
      if options.command.len == 0: options.command = key
      elif options.project.len == 0: options.project = key
      else: return none(Options)
    of cmdLongOption, cmdShortOption:
      case key
      of "root": options.root = value
      of "branch": options.branch = value
      of "base": options.base = value
      of "all": options.is_all = true
      of "sweep": options.is_sweep = true
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


proc run(options: Options): int =
  ## Execute command, print findings, return exit code.
  var found: seq[Finding]
  case options.command
  of "tree":
    found = options.root.readTree.auditTree
  of "deps":
    let tree = options.root.readTree
    found = restoreAll(options.root, options.dirsOf(tree))
  of "tests":
    let tree = options.root.readTree
    found = runJobs(options.root, tree.jobsFor(options.dirsOf(tree)))
  of "plan":
    let tree = options.root.readTree
    echo render(
      if options.is_sweep: sweepFor(options.root, tree, SWEEP_DAYS)
      elif options.is_all: tree.allJobs
      else: tree.jobs(changedPaths(options.root, options.baseOrDefault))
    )
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
  of "stamp":
    echo options.root.readTree.rulesStamp
    return 0
  of "ci":
    discard gitFields(options.root, ["fetch", "-q", "origin", MAIN])
    let tree = options.root.readTree
    let (branch, base) = (options.branchOrDefault, options.baseOrDefault)
    found = tree.auditTree
    found.add runJobs(options.root, tree.jobs(changedPaths(options.root, base)))
    found.add checkScope(branch, changedPaths(options.root, base), movedPaths(options.root, base))
    found.add checkCommits(branch, subjects(options.root, base))
    found.add checkBase(gainedPaths(options.root, base))
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
