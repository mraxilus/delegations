## Enforce repository layout: root entries, two project roots, project shape, README views.
##   Layout is data (Article II.1): `ROOT_FILES`, `ROOT_DIRS`, `PROJECT_FILES` here plus
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
##
##   Cost: rules read path strings, never disk, so tests feed synthetic trees and git
##     enumeration lives in `tree.nim`. Empty directories are invisible to git and so here.

{.experimental: "strictFuncs".}

import std/[algorithm, options, os, sequtils, strutils, tables]
import ./[findings, domains, kinds, markdown, dependencies, toolchain]


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
    "GUIDE.md", "CLAUDE.md", "GLOSSARY.md", "koch.nim", "koch.nim.cfg", ".gitignore",
    ".gitattributes",
  ]
    ## Files allowed directly at root.
  ROOT_DIRS* = [".github"]
    ## Root directories unchecked inside; project roots are `ROOTS`.
  PROJECT_FILES* = ["README.md", "PROVENANCE.md", "GLOSSARY.md"]
    ## Files every project directory must hold, besides its nimble file.
  TESTS_DIR* = "tests"
    ## Directory every project must populate.
  PAGE_DIRS* = ["pages", "mockups"]
    ## Directories committed pages live in: kept pages, then one-off mock-ups.
  KINDS_PATH = "curator/audit/src/kinds.nim"
    ## Registry named in finding for unregistered kind.


func projectName*(dir: string): string =
  ## Read project folder name, i.e. last segment of project directory.
  dir.split('/')[^1]


func nimblePath*(dir: string): string =
  ## Read path of project's nimble file, which is named after its folder.
  dir & "/" & dir.projectName & NIMBLE_EXT


func dirOf(path: string): string =
  ## Read directory part of path, empty at root.
  let cut = path.rfind('/')
  if cut < 0: "" else: path[0 ..< cut]


func projectDir(parts: seq[string]): string =
  ## Read project directory of path parts; empty when path lies inside no project.
  if parts[0] == CURATOR and parts.len >= 3:
    CURATOR & "/" & parts[1]
  elif parts[0] == CONTRIBUTOR and parts.len >= 4 and parts[1].findDomain.isSome:
    CONTRIBUTOR & "/" & parts[1] & "/" & parts[2]
  else:
    ""


func projectDirs*(tree: Tree): seq[string] =
  ## Collect project directories present, sorted.
  for e in tree:
    let dir = e.path.split('/').projectDir
    if dir.len > 0 and dir notin result: result.add dir
  result.sort


func index(tree: Tree): Table[string, int] =
  ## Map path to position in tree.
  for i, e in tree: result[e.path] = i


func checkIndexEntry(path, child, holder, member: string): seq[Finding] =
  ## Report file directly inside folder that holds README.md and member folders only.
  if child != "README.md":
    result.add finding(
      path, 0, holder & " holds README.md and " & member & " folders only; got `" & child & "`."
    )


func checkProjectName(path, name: string): seq[Finding] =
  ## Report project folder name outside grammar.
  if not name.isProjectName:
    result.add finding(path, 0, "Project folder must match `[a-z][a-z0-9_]*`; got `" & name & "`.")


func checkPage(path: string, parts: seq[string]): seq[Finding] =
  ## Report page outside project's page directories.
  let dir = parts.projectDir
  for page_dir in PAGE_DIRS:
    if dir.len > 0 and path.startsWith(dir & "/" & page_dir & "/"): return
  result.add finding(
    path, 0,
    "Page outside `" & PAGE_DIRS.join("/` or `") & "/`; generated markup belongs under " &
      "`build/`; got `" & path & "`.",
  )


func checkEntry(e: Entry): seq[Finding] =
  ## Report entry outside layout or of unregistered kind.
  let parts = e.path.split('/')
  if e.kind.isSome and e.kind.get in {Kind.Html, Kind.Svg}:
    result.add checkPage(e.path, parts)
  if e.kind.isNone:
    let (_, base, ext) = e.path.splitFile
    result.add finding(
      e.path, 0,
      "File kind unread by checker; register it in `" & KINDS_PATH & "`; got `" & base & ext &
        "`.",
    )
  if parts.len == 1:
    if parts[0] notin ROOT_FILES:
      result.add finding(e.path, 0, "Root file outside layout; got `" & parts[0] & "`.")
    return
  let head = parts[0]
  if head in ROOT_DIRS: return
  if head == CURATOR:
    if parts.len == 2: result.add checkIndexEntry(e.path, parts[1], "Curator root", "project")
    else: result.add checkProjectName(e.path, parts[1])
    return
  if head == CONTRIBUTOR:
    if parts.len == 2:
      result.add checkIndexEntry(e.path, parts[1], "Contributor root", "domain")
    elif parts[1].findDomain.isNone:
      result.add finding(e.path, 0, "Domain folder outside registry; got `" & parts[1] & "`.")
    elif parts.len == 3:
      result.add checkIndexEntry(e.path, parts[2], "Domain folder", "project")
    else:
      result.add checkProjectName(e.path, parts[2])
    return
  result.add finding(e.path, 0, "Root directory outside layout; got `" & head & "`.")


func checkProject(tree: Tree, paths: Table[string, int], dir: string): seq[Finding] =
  ## Report missing project files, missing tests, nimble file faults, missing lock.
  for file in PROJECT_FILES:
    let path = dir & "/" & file
    if path notin paths: result.add finding(path, 0, "Project file missing.")
  let tests_prefix = dir & "/" & TESTS_DIR & "/"
  if not tree.anyIt(it.path.startsWith(tests_prefix)):
    result.add finding(
      dir & "/" & TESTS_DIR, 0, "Project tests missing; add at least one file under `tests/`."
    )

  # Demand exactly one nimble file, named after project, and lock when it requires packages.
  let nimble = dir.nimblePath
  if nimble notin paths: result.add finding(nimble, 0, "Project nimble file missing.")
  for e in tree:
    if e.path.dirOf == dir and e.path.endsWith(NIMBLE_EXT) and e.path != nimble:
      result.add finding(
        e.path, 0, "Nimble file not named after project; expected `" & nimble & "`."
      )
  if nimble in paths:
    result.add checkPin(nimble, tree[paths[nimble]].content)
    let required = tree[paths[nimble]].content.requirements
    let lock = dir & "/" & LOCK_FILE
    if required.len > 0 and lock notin paths:
      result.add finding(
        lock, 0,
        "Lock missing for required packages; run `atlas pin`; got `" & required.join(", ") &
          "`.",
      )


func checkRootViews(tree: Tree, paths: Table[string, int]): seq[Finding] =
  ## Report top-level glossary missing, and root folder READMEs missing or misnamed.
  if "GLOSSARY.md" notin paths:
    result.add finding("GLOSSARY.md", 0, "Top-level glossary missing.")
  for root in ROOTS:
    let path = root & "/README.md"
    if path notin paths:
      result.add finding(path, 0, "Root folder README missing.")
      continue
    if tree[paths[path]].content.firstNonBlank != "# " & root:
      result.add finding(path, 1, "Root folder README must open with `# " & root & "`.")


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
    let path = CONTRIBUTOR & "/" & d.folder & "/README.md"
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
  result.add checkRootViews(tree, paths)
  result.add checkDomainViews(tree, paths)
