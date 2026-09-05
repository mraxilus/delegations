## Enforce repository layout: root entries, domain folders, project shape, README tables.
##   Layout is data (Article II.1): `ROOT_FILES`, `ROOT_DIRS`, `PROJECT_FILES` here plus
##   `DOMAINS`; check derives every rule from those lists and paths git reports.
##
##   Project is any directory `<domain>/<project>` or `curator`; both keep one shape:
##     README.md, PROVENANCE.md, GLOSSARY.md, Makefile with `check` target, and `tests/`
##     holding at least one file. Domain folder holds README.md and project folders only.
##   Root README.md and each domain README.md are checked as derived views of `DOMAINS`
##     (Article I.4): row per domain in root table; name heading and theme line per domain.
##   Root Makefile must declare every target documents name (`ROOT_TARGETS`), so `make ci`
##     in CONTRIBUTOR.md never points at nothing.
##   Unregistered file kind anywhere is finding (Article VI.5), pointing at `kinds.nim`.
##
##   Cost: rules read path strings, never disk, so tests feed synthetic trees and git
##     enumeration lives in `tree.nim`. Empty directories are invisible to git and so here.

{.experimental: "strictFuncs".}

import std/[algorithm, options, os, sequtils, strutils, tables]
import ./[findings, domains, kinds, markdown]


type
  Entry* = object
    ## Define one file git reports: path, kind when registered, content when read.
    path*: string        ## Repository-relative, `/` separated.
    kind*: Option[Kind]  ## Registered kind; `none` leaves content unread.
    content*: string     ## File text; empty for unregistered kinds.

  Tree* = seq[Entry]
    ## Define whole repository as git sees it.


const
  ROOT_FILES* = [
    "README.md", "LICENSE.md", "CONSTITUTION.md", "STYLE.md", "CURATOR.md", "CONTRIBUTOR.md",
    "CLAUDE.md", "Makefile", ".gitignore", ".gitattributes",
  ]
    ## Files allowed directly at root.
  ROOT_DIRS* = [".github", CURATOR]
    ## Directories allowed at root besides domain folders.
  PROJECT_FILES* = ["README.md", "PROVENANCE.md", "GLOSSARY.md", "Makefile"]
    ## Files every project directory must hold.
  ROOT_TARGETS* = ["check", "ci", "tree", "projects", "scope", "commits", "stamp"]
    ## Targets root Makefile must declare; CURATOR.md, CONTRIBUTOR.md and README.md name them.
  TESTS_DIR* = "tests"
    ## Directory every project must populate.


func projectDirs*(tree: Tree): seq[string] =
  ## Collect project directories present: `curator` and each `<domain>/<project>`.
  for e in tree:
    let parts = e.path.split('/')
    var dir = ""
    if parts[0] == CURATOR and parts.len >= 2: dir = CURATOR
    elif parts[0].findDomain.isSome and parts.len >= 3: dir = parts[0] & "/" & parts[1]
    else: continue
    if dir notin result: result.add dir
  result.sort


func hasTarget*(makefile, name: string): bool =
  ## Decide whether Makefile declares target, i.e. line `name:` or `name :`.
  for line in makefile.splitLines:
    if line.startsWith(name) and line[name.len .. ^1].strip(trailing = false).startsWith(":"):
      return true
  false


func index(tree: Tree): Table[string, int] =
  ## Map path to position in tree.
  for i, e in tree: result[e.path] = i


func checkEntry(e: Entry): seq[Finding] =
  ## Report entry outside layout or of unregistered kind.
  let parts = e.path.split('/')
  if e.kind.isNone:
    let (_, base, ext) = e.path.splitFile
    result.add finding(
      e.path, 0,
      "File kind unread by checker; register it in `curator/src/kinds.nim`; got `" &
        base & ext & "`.",
    )
  if parts.len == 1:
    if parts[0] notin ROOT_FILES:
      result.add finding(e.path, 0, "Root file outside layout; got `" & parts[0] & "`.")
    return
  let head = parts[0]
  if head in ROOT_DIRS: return
  if head.findDomain.isNone:
    result.add finding(e.path, 0, "Root directory outside layout; got `" & head & "`.")
    return
  if parts.len == 2 and parts[1] != "README.md":
    result.add finding(
      e.path, 0, "Domain folder holds README.md and project folders only; got `" & parts[1] & "`."
    )
  if parts.len >= 3 and not parts[1].isProjectName:
    result.add finding(
      e.path, 0, "Project folder must match `[a-z][a-z0-9_]*`; got `" & parts[1] & "`."
    )


func checkProject(tree: Tree, paths: Table[string, int], dir: string): seq[Finding] =
  ## Report missing project files, missing tests, and Makefile lacking `check`.
  for file in PROJECT_FILES:
    let path = dir & "/" & file
    if path notin paths: result.add finding(path, 0, "Project file missing.")
  let tests_prefix = dir & "/" & TESTS_DIR & "/"
  if not tree.anyIt(it.path.startsWith(tests_prefix)):
    result.add finding(
      dir & "/" & TESTS_DIR, 0, "Project tests missing; add at least one file under `tests/`."
    )
  let makefile = dir & "/Makefile"
  if makefile in paths and not tree[paths[makefile]].content.hasTarget("check"):
    result.add finding(makefile, 0, "Makefile lacks `check` target.")


func checkRootMakefile(tree: Tree, paths: Table[string, int]): seq[Finding] =
  ## Report root Makefile targets documents name but Makefile lacks.
  if "Makefile" notin paths: return
  for target in ROOT_TARGETS:
    if not tree[paths["Makefile"]].content.hasTarget(target):
      result.add finding("Makefile", 0, "Root Makefile lacks target; got `" & target & "`.")


func checkDomainViews(tree: Tree, paths: Table[string, int]): seq[Finding] =
  ## Report root and domain README files disagreeing with `DOMAINS`.
  if "README.md" in paths:
    let rows = tree[paths["README.md"]].content.tableRows
    for d in DOMAINS:
      if @[d.folder, d.name, d.theme] notin rows:
        result.add finding(
          "README.md", 0,
          "Domain table lacks row `| " & d.folder & " | " & d.name & " | " & d.theme & " |`.",
        )
  for d in DOMAINS:
    let path = d.folder & "/README.md"
    if path notin paths:
      result.add finding(path, 0, "Domain README missing.")
      continue
    let content = tree[paths[path]].content
    if content.firstNonBlank != "# " & d.name:
      result.add finding(path, 1, "Domain README must open with `# " & d.name & "`.")
    if d.theme notin content.splitLines:
      result.add finding(path, 0, "Domain README lacks theme line `" & d.theme & "`.")


func checkLayout*(tree: Tree): seq[Finding] =
  ## Report every layout violation in tree.
  let paths = tree.index
  for e in tree: result.add e.checkEntry
  for dir in tree.projectDirs: result.add checkProject(tree, paths, dir)
  result.add checkRootMakefile(tree, paths)
  result.add checkDomainViews(tree, paths)
