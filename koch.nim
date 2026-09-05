## Drive every check of repository from one compiled program, as Nim's own `koch` does.
##   Build once with `nim c koch`, then `./koch <command>`; or `nim r koch <command>`, which
##   rebuilds when sources changed, then runs (Article IX.6); warm run costs ~0.1 s.
##
##   |---------|-------------------------------------------------------------------------|
##   | Command | Effect                                                                  |
##   |---------|-------------------------------------------------------------------------|
##   | tree    | layout, form, comments, provenance, glossary over files git sees        |
##   | deps    | `atlas --noexec rep` in every project holding atlas.lock, or in one     |
##   | tests   | testament over tests/t*.nim in every project, or in one                 |
##   | audit   | tree, then deps, then tests                                             |
##   | scope   | changed paths against branch prefix           (--branch, --base)        |
##   | commits | commit subjects against branch scope          (--branch, --base)        |
##   | stamp   | print rules stamp for PROVENANCE.md                                     |
##   | ci      | fetch origin/main, then audit, scope, commits                           |
##   |---------|-------------------------------------------------------------------------|
##   Options: `--root:<dir>` (default `.`); `--branch:<name>` (default env `BRANCH`, else
##     current git branch); `--base:<ref>` (default env `BASE`, else `origin/main`). Second
##     argument of `deps` and `tests` names one project directory. Exit: 0 clean, 1
##     findings, 2 usage error.
##
##   Rejected: make (second toolchain, recipe tabs, untested glue); NimScript tasks (compiler
##     VM subset, script loaded on every compile, task names shadow compiler commands,
##     untestable). Chosen: compiled driver, as Nim's repository builds with `koch`.
##   Cost: root file outside any project; every check it drives is library module under
##     `curator/audit/src`, tested there; this file holds dispatch only.

{.experimental: "strictFuncs".}

import std/[options, os, parseopt, strutils]
import ./curator/audit/src/[
  findings, domains, scope, commits, tree, projects, dependencies, audit,
]


const USAGE = """
Usage: koch <tree|deps|tests|audit|scope|commits|stamp|ci> [project]
            [--root:<dir>] [--branch:<name>] [--base:<ref>]
"""
  ## Text printed on usage error.


type Options = object
  ## Define parsed command line.
  command: string
  project: string
  root: string = "."
  branch: string
  base: string


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
    found = restoreAll(options.root, options.dirsOf(options.root.readTree))
  of "tests":
    found = runTests(options.root, options.dirsOf(options.root.readTree))
  of "audit":
    let tree = options.root.readTree
    found = tree.auditTree
    found.add restoreAll(options.root, tree.projectDirs)
    found.add runTests(options.root, tree.projectDirs)
  of "scope":
    found = checkScope(options.branchOrDefault, changedPaths(options.root, options.baseOrDefault))
  of "commits":
    found = checkCommits(options.branchOrDefault, subjects(options.root, options.baseOrDefault))
  of "stamp":
    echo options.root.readTree.rulesStamp
    return 0
  of "ci":
    discard gitFields(options.root, ["fetch", "-q", "origin", MAIN])
    let tree = options.root.readTree
    found = tree.auditTree
    found.add restoreAll(options.root, tree.projectDirs)
    found.add runTests(options.root, tree.projectDirs)
    let (branch, base) = (options.branchOrDefault, options.baseOrDefault)
    found.add checkScope(branch, changedPaths(options.root, base))
    found.add checkCommits(branch, subjects(options.root, base))
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
