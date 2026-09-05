## Audit repository against CONSTITUTION.md, STYLE.md and CONTRIBUTOR.md; umbrella and CLI.
##
##   Order of module bootstrapping:
##     findings -> domains -> kinds -> comments -> [prose, form]
##     markdown -> [layout, provenance, glossary]
##     domains -> [scope, commits]
##     [kinds, layout] -> tree -> projects -> audit
##
##   Commands:
##     tree      layout, form, prose, provenance, glossary over files git sees
##     projects  `make check` in every project
##     scope     changed paths against branch prefix         (--branch, --base)
##     commits   commit subjects against branch scope        (--branch, --base)
##     stamp     print rules stamp for PROVENANCE.md
##     all       tree, then projects
##   Options: `--root:<dir>` (default `.`), `--branch:<name>`, `--base:<ref>` (default
##     `origin/main`).
##   Exit: 0 clean, 1 findings, 2 usage error.
##
##   Cost: tool runs once per check, so no hot path exists and Article VII figures stay
##     unmeasured by design; whole-tree audit time is recorded in PROVENANCE.md.

{.experimental: "strictFuncs".}

import std/[options, parseopt]
import ./[
  findings, kinds, prose, form, layout, provenance, glossary, scope, commits, tree, projects,
]


const USAGE = """
Usage: audit <tree|projects|scope|commits|stamp|all> [--root:<dir>] [--branch:<name>]
             [--base:<ref>]
"""
  ## Text printed on usage error.


type Options = object
  ## Define parsed command line.
  command: string
  root: string = "."
  branch: string = ""
  base: string = "origin/main"


func rulesStamp*(tree: Tree): string =
  ## Compute stamp of rules documents as tree holds them; missing document digests empty.
  var contents: seq[string]
  for rule in RULES:
    var content = ""
    for e in tree:
      if e.path == rule: content = e.content
    contents.add content
  contents.stamp


func auditTree*(tree: Tree): seq[Finding] =
  ## Run every static check over tree.
  result = tree.checkLayout
  let stamp_now = tree.rulesStamp
  let dirs = tree.projectDirs
  for e in tree:
    if e.kind.isNone: continue
    let rule = e.kind.get.rule
    result.add checkForm(e.path, e.content, rule)
    if rule.is_prose: result.add checkProse(e.path, e.content, rule.syntax)
    for dir in dirs:
      if e.path == dir & "/PROVENANCE.md": result.add checkProvenance(e.path, e.content, stamp_now)
      if e.path == dir & "/GLOSSARY.md": result.add checkGlossary(e.path, e.content)


proc parseOptions(): Option[Options] =
  ## Parse command line; `none` on unknown option or missing command.
  var options = Options()
  for kind, key, value in getopt():
    case kind
    of cmdArgument:
      if options.command.len > 0: return none(Options)
      options.command = key
    of cmdLongOption, cmdShortOption:
      case key
      of "root": options.root = value
      of "branch": options.branch = value
      of "base": options.base = value
      else: return none(Options)
    of cmdEnd: discard
  if options.command.len == 0: return none(Options)
  some(options)


proc run(options: Options): int =
  ## Execute command, print findings, return exit code.
  var found: seq[Finding]
  case options.command
  of "tree":
    found = options.root.readTree.auditTree
  of "projects":
    found = runProjects(options.root, options.root.readTree.projectDirs)
  of "scope":
    found = checkScope(options.branch, changedPaths(options.root, options.base))
  of "commits":
    found = checkCommits(options.branch, subjects(options.root, options.base))
  of "stamp":
    echo options.root.readTree.rulesStamp
    return 0
  of "all":
    let tree = options.root.readTree
    found = tree.auditTree
    found.add runProjects(options.root, tree.projectDirs)
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
