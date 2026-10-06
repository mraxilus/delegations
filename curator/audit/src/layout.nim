## Enforce repository layout: root entries, two project roots, project shape, README views.
##   Layout is data (Article II.1): `FILES_ROOT`, `DIRECTORIES_ROOT`, `FILES_PROJECT` here plus
##   `ROOTS` and `DOMAINS`; check derives every rule from those lists and paths git reports.
##
##   Project is `curator/<project>` or `contributor/<domain>/<project>`; both keep one
##     shape: README.md, PROVENANCE.md, GLOSSARY.md, `<project>.nimble`, and `tests/` holding
##     at least one file. Packages required by nimble file demand `atlas.lock`, and nimble
##     file pins its own compiler exactly (`toolchain.nim`), since no version serves every
##     project.
##   Root folders hold README.md and folders only: `curator/` project folders,
##     `contributor/` domain folders, domain folders project folders. Each is checked at its
##     depth; unknown root directory or unregistered domain is finding, never skipped.
##   Root README.md, root folder READMEs and domain READMEs are derived views (Article I.4):
##     domain row per `DOMAINS`, `# <name>` heading, theme line per domain.
##   Top-level GLOSSARY.md carries repository's agreed words, and every project carries its
##     own; shape is checked here, agreement never is, since checker cannot know what
##     Architect selected.
##   Unregistered file kind anywhere is finding (Article VI.5), pointing at `kinds.nim`.
##   Committed page (Html, Svg) lives in project's `pages/`, what project stands behind, or
##     `mockups/`, one-off exploration kept for reference; generated markup stays under
##     ignored `build/`. Separation is declared by directory, never inferred from content.
##   No tracked path lies under `DIRECTORIES_UNTRACKED` at any depth (Article XI.3): ignore
##     file keeps them out, and forced add is what this catches.
##   Shell lives only in `DIRECTORIES_SHELL`: it is curator's hook glue, and never enters
##     project (CONTRIBUTOR.md, Boundaries).
##
##   Cost: rules read path strings, never disk, so tests feed synthetic trees and git
##     enumeration lives in `tree.nim`. Empty directories are invisible to git and so here.

{.experimental: "strictFuncs".}

import std/[algorithm, options, os, sequtils, strutils, tables]
import ../../knoller/src/knoller
import ./[dependencies, domains, findings, kinds, markdown, toolchain]


type
  Entry* = object  ## Define one file git reports: path, kind when registered, content when read.
    path*: string  ## Repository-relative, `/` separated.
    kind*: Option[Kind]  ## Registered kind; `none` leaves content unread.
    content*: string  ## File text; empty for unregistered kinds.

  Tree* = seq[Entry]  ## Define whole repository as git sees it.


const
  FILE_README* = "README.md"
    ## Index every root, every domain and every project carries, named once for all three.
  FILES_ROOT* = [
    FILE_README, "LICENSE.md", "CONSTITUTION.md", "STYLE.md", "EXAMPLES.md", "CURATOR.md",
    "COORDINATOR.md", "CONTRIBUTOR.md", "GUIDE.md", "CLAUDE.md", "GLOSSARY.md", "koch.nim",
    "koch.nim.cfg", ".gitignore", ".gitattributes",
  ]
    ## Files allowed directly at root.
  DIRECTORIES_ROOT* = [".github", ".claude", ".githooks"]
    ## Root directories unchecked inside; project roots are `ROOTS`. `.claude` holds hooks,
    ## permissions, skills and agents Claude Code loads; `.githooks` holds git's own hooks.
  FILES_PROJECT* = [FILE_README, "PROVENANCE.md", "GLOSSARY.md"]
  DIRECTORIES_UNTRACKED* = ["build", "dependencies", "node_modules"]
    ## Directories holding build output or vendored source, never tracked (Article XI.3).
    ## Files every project directory must hold, besides its nimble file.
  DIRECTORY_TESTS* = "tests"  ## Directory every project must populate.
  DIRECTORIES_PAGE* = ["pages", "mockups"]
    ## Directories committed pages live in: kept pages, then one-off mock-ups.
  DIRECTORIES_SHELL* = [".claude", ".githooks"]
    ## Root directories Shell may live in: command Claude Code runs, and hooks git runs.
  KINDS_PATH = "curator/audit/src/kinds.nim"  ## Registry named in finding for unregistered kind.


func projectName*(directory: string): string =
  ## Read project folder name, i.e. last segment of project directory.
  directory.split('/')[^1]


func pathNimble*(directory: string): string =
  ## Read path of project's nimble file, which is named after its folder.
  directory & "/" & directory.projectName & EXTENSIONS[Dialect.Package]


func directoryOf(path: string): string =
  ## Read directory part of path, empty at root.
  let cut = path.rfind('/')
  if cut < 0: "" else: path[0 ..< cut]


func directoryProject*(parts: seq[string]): string =
  ## Read project directory of path parts; empty when path lies inside no project.
  if parts[0] == CURATOR and parts.len >= 3:
    CURATOR & "/" & parts[1]
  elif parts[0] == CONTRIBUTOR and parts.len >= 4 and parts[1].findDomain.isSome:
    CONTRIBUTOR & "/" & parts[1] & "/" & parts[2]
  else:
    ""


func directoriesProject*(tree: Tree): seq[string] =
  ## Collect project directories present, sorted.
  for e in tree:
    let directory = e.path.split('/').directoryProject
    if directory.len > 0 and directory notin result: result.add directory
  result.sort


func index(tree: Tree): Table[string, int] =
  ## Map path to position in tree.
  for i, e in tree: result[e.path] = i


func checkEntryIndex(path, child, holder, member: string): seq[Finding] =
  ## Report file directly inside folder that holds README.md and member folders only.
  if child != FILE_README:
    result.add finding(
      path,
      0,
      holder & " holds README.md and " & member & " folders only; got `" & child & "`.",
    )


func checkNameProject(path, name: string): seq[Finding] =
  ## Report project folder name outside grammar.
  if not name.isNameProject:
    result.add finding(path, 0, "Project folder must match `[a-z][a-z0-9_]*`; got `" & name & "`.")


func checkPage(path: string, parts: seq[string]): seq[Finding] =
  ## Report page outside project's page directories.
  let directory = parts.directoryProject
  for directory_page in DIRECTORIES_PAGE:
    if directory.len > 0 and path.startsWith(directory & "/" & directory_page & "/"): return
  result.add finding(
    path,
    0,
    "Page outside `" & DIRECTORIES_PAGE.join("/` or `") & "/`; generated markup belongs under " &
      "`build/`; got `" & path & "`.",
  )


func checkEntry(e: Entry): seq[Finding] =
  ## Report entry outside layout or of unregistered kind.
  let parts = e.path.split('/')
  for directory in parts[0 ..< parts.high]:
    if directory in DIRECTORIES_UNTRACKED:
      result.add finding(
        e.path,
        0,
        "Build output and vendored source stay untracked (Article XI.3); got `" & directory & "/`.",
      )
      break
  if e.kind.isSome and e.kind.get in {Kind.Html, Kind.Svg}:
    result.add checkPage(e.path, parts)
  if e.kind.isSome and e.kind.get == Kind.Shell and parts[0] notin DIRECTORIES_SHELL:
    result.add finding(
      e.path,
      0,
      "Shell is hook glue of curator, and lives only in `" & DIRECTORIES_SHELL.join("/` or `") &
        "/` (CONTRIBUTOR.md, The language is Nim); got `" & e.path & "`.",
    )
  if e.kind.isNone:
    let (_, base, ext) = e.path.splitFile
    result.add finding(
      e.path,
      0,
      "File kind unread by checker; register it in `" & KINDS_PATH & "`; got `" & base & ext & "`.",
    )
  if parts.len == 1:
    if parts[0] notin FILES_ROOT:
      result.add finding(e.path, 0, "Root file outside layout; got `" & parts[0] & "`.")
    return
  let head = parts[0]
  if head in DIRECTORIES_ROOT: return
  if head == CURATOR:
    if parts.len == 2: result.add checkEntryIndex(e.path, parts[1], "Curator root", "project")
    else: result.add checkNameProject(e.path, parts[1])
    return
  if head == CONTRIBUTOR:
    if parts.len == 2:
      result.add checkEntryIndex(e.path, parts[1], "Contributor root", "domain")
    elif parts[1].findDomain.isNone:
      result.add finding(e.path, 0, "Domain folder outside registry; got `" & parts[1] & "`.")
    elif parts.len == 3:
      result.add checkEntryIndex(e.path, parts[2], "Domain folder", "project")
    else:
      result.add checkNameProject(e.path, parts[2])
    return
  result.add finding(e.path, 0, "Root directory outside layout; got `" & head & "`.")


func checkProject(tree: Tree, paths: Table[string, int], directory: string): seq[Finding] =
  ## Report missing project files, missing tests, nimble file faults, missing lock.
  for file in FILES_PROJECT:
    let path = directory & "/" & file
    if path notin paths: result.add finding(path, 0, "Project file missing.")
  let prefix_tests = directory & "/" & DIRECTORY_TESTS & "/"
  if not tree.anyIt(it.path.startsWith(prefix_tests)):
    result.add finding(
      directory & "/" & DIRECTORY_TESTS,
      0,
      "Project tests missing; add at least one file under `tests/`.",
    )

  # Demand exactly one nimble file, named after project, and lock when it requires packages.
  let nimble = directory.pathNimble
  if nimble notin paths: result.add finding(nimble, 0, "Project nimble file missing.")
  for e in tree:
    let is_nimble = e.path.endsWith(EXTENSIONS[Dialect.Package])
    if e.path.directoryOf == directory and is_nimble and e.path != nimble:
      result.add finding(
        e.path,
        0,
        "Nimble file not named after project; expected `" & nimble & "`.",
      )
  if nimble in paths:
    result.add checkPin(nimble, tree[paths[nimble]].content)
    let
      required = tree[paths[nimble]].content.requirements
      lock = directory & "/" & FILE_LOCK
    if required.len > 0 and lock notin paths:
      result.add finding(
        lock,
        0,
        "Lock missing for required packages; run `atlas pin`; got `" & required.join(", ") & "`.",
      )


func checkViewsRoot(tree: Tree, paths: Table[string, int]): seq[Finding] =
  ## Report top-level glossary missing, and root folder READMEs missing or misnamed.
  if "GLOSSARY.md" notin paths:
    result.add finding("GLOSSARY.md", 0, "Top-level glossary missing.")
  for root in ROOTS:
    let path = root & "/" & FILE_README
    if path notin paths:
      result.add finding(path, 0, "Root folder README missing.")
      continue
    if tree[paths[path]].content.firstNonBlank != "# " & root:
      result.add finding(path, 1, "Root folder README must open with `# " & root & "`.")


func checkViewsDomain(tree: Tree, paths: Table[string, int]): seq[Finding] =
  ## Report root and domain README files disagreeing with `DOMAINS`.
  if FILE_README in paths:
    let rows = tree[paths[FILE_README]].content.rowsTable
    for d in DOMAINS:
      if @[d.folder, d.name, d.theme] notin rows:
        result.add finding(
          FILE_README,
          0,
          "Domain table lacks row `| " & d.folder & " | " & d.name & " | " & d.theme & " |`.",
        )
  for d in DOMAINS:
    let path = CONTRIBUTOR & "/" & d.folder & "/" & FILE_README
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
  for directory in tree.directoriesProject: result.add checkProject(tree, paths, directory)
  result.add checkViewsRoot(tree, paths)
  result.add checkViewsDomain(tree, paths)
