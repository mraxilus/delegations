## Enforce branch scope: project branch changes only its project folder.
##   Branch grammar lives in `domains.nim`; this check reads parsed prefix. Curator root
##   branch owns empty prefix, so every path passes: change of rule of content must re-stamp
##   every project (owner's decision). `main` passes: pushes to main are merges owner approved.
##
##   That empty prefix is narrowed where it reaches contributor projects. Curator propagating
##     rule writes their records, `FILES_PROJECT` from `layout.nim`, and nothing else: stamp
##     row, agreed terms, and prose rule invalidated, which is what propagation is. Source,
##     tests and nimble file stay contributor's, so duty 11 stops being prose alone.
##   Rules change reaching contributor code means changing rule or check, then letting
##     contributor apply it, which CURATOR.md duty 11 already says.
##   Content-preserving move is exempt, since registry is curator's and renaming domain or
##     project is registry change; moving file is consequence, never authorship. Only exact
##     rename counts (`pathsMoved`, 100% similarity), so edit disguised as move is caught.
##   Lock moving with its project is exempt for one line more: name of its nimble copy, which
##     `atlas rep` writes back under that name while layout names nimble file after folder.
##     Move renames file, so line must follow in same branch, and no other branch can write it
##     (#631). Line is judged exactly (`isLockMoved`), so any other edit of lock stays finding.
##
##   Held finding: finding inside project blocks only branch of role that owns that project, or
##     branch that changed its line, as Architect ruled on D1 of #871 and of #876. So check
##     that reddens project lands once rest is clean, and project clears finding in its next
##     pull request (CURATOR.md, duty 3). Root curator owns each curator project; curator of
##     one project owns that project alone; contributor owns its own. `main` holds each
##     project, since some branch holds each, and green branch must merge into green `main`.
##     `koch check` and `check-files` read same split, on hook and on runner alike.
##   Finding on line branch changed blocks it wherever it lies: curator writing into
##     contributor record clears what it wrote. Prose finding names line its block opens on,
##     so changed line owns that line too.
##   Held means inside project, records included. Finding outside every project, as root file
##     or index above project, blocks each branch, and so does propagation finding (stale stamp,
##     standard moved to root), which stays curator's wherever it lands. Scope finding is
##     branch's own change, which no project clears, so it blocks wherever it lies, as runner's
##     `check-scope` does.
##   Cost: role comes from branch name alone, as every delegate posts as one account; name
##     claiming curator role gains nothing past hook, since `check-scope` and `check-role` read
##     same name on runner.
##
##   Cost: owner may merge red pull request deliberately; check is guard, not gate.
##   Cost: curator may still rewrite contributor's prose freely, since README is writable;
##     that part duty 11 governs by reading, never by check.
##   Cost: curator may reorder contributor's files without asking, since move is exempt.
##     Content cannot change and move is visible in review, so cost is disorder, not damage.

{.experimental: "strictFuncs".}

import std/[options, sets, strutils, tables]
import ../../knoller/src/knoller
import ./[dependencies, domains, findings, layout]


func checkPropagation(path: string): seq[Finding] =
  ## Report curator writing anything but contributor project's records.
  ##   Indexes above project are curator's outright: `contributor/README.md` and
  ##   `contributor/<domain>/README.md` are theirs by repository map, and duty 6 has them
  ##   write second one whenever domain is added. Only inside project does reach narrow.
  let parts = path.split('/')
  if parts.len <= 3: return
  if parts.len == 4 and parts[3] in FILES_PROJECT: return
  result.add finding(
    path,
    0,
    "Curator writes only " & FILES_PROJECT.join(", ") & " in contributor project; change " &
      "rule or check and let contributor apply it; got `" & path & "`.",
    is_scope = true,
  )


func isLockMoved*(path_from, path_to, lock_from, lock_to: string): bool =
  ## Tell whether lock moved to other folder and changed one line alone: name of its nimble
  ##   copy, from old folder's name to new one's.
  let (parts_from, parts_to) = (path_from.split('/'), path_to.split('/'))
  if parts_from.len < 2 or parts_to.len < 2: return false
  if parts_from[^1] != FILE_LOCK or parts_to[^1] != FILE_LOCK: return false
  let
    name_from = "\"" & parts_from[^2] & EXTENSIONS[Dialect.Package] & "\""
    name_to = "\"" & parts_to[^2] & EXTENSIONS[Dialect.Package] & "\""
    (lines_from, lines_to) = (lock_from.split('\n'), lock_to.split('\n'))
  if name_from == name_to or lines_from.len != lines_to.len: return false

  # Find lines that differ; exactly one may.
  var edited: seq[int]
  for i in 0..<lines_from.len:
    if lines_from[i] != lines_to[i]: edited.add i
  if edited.len != 1: return false

  # Hold that line to key of nimble copy, and to old name swapped for new one.
  let line = lines_from[edited[0]]
  line.strip.startsWith(KEY_FILENAME) and name_from in line and
      lines_to[edited[0]] == line.replace(name_from, name_to)


func checkScope*(
  branch: string, paths: openArray[string], moved: openArray[string] = []
): seq[Finding] =
  ## Report branch name outside grammar, then each path outside branch prefix.
  if branch == MAIN: return
  let parsed = branch.parseBranch
  if parsed.isNone:
    return @[finding(
      "", 0,
      "Branch must match `contributor/<domain>/<project>/<name>`, `curator/<project>/<name>` " &
        "or `curator/<name>`; got `" & branch & "`.",
    )]
  let
    prefix = parsed.get.prefix
    is_root_curator = parsed.get.role == Role.Curator
    moved_set = moved.toHashSet
  for p in paths:
    if not p.startsWith(prefix):
      result.add finding(p, 0, "Path outside branch scope `" & prefix & "`.", is_scope = true)
    elif is_root_curator and p.startsWith(CONTRIBUTOR & "/") and p notin moved_set:
      result.add checkPropagation(p)


func prefixProject(path: string): string =
  ## Read prefix of project that path lies inside, trailing `/`; empty outside every project.
  let parts = path.split('/')
  if parts.len > 3 and parts[0] == CONTRIBUTOR: parts[0 .. 2].join("/") & "/"
  elif parts.len > 2 and parts[0] == CURATOR: parts[0 .. 1].join("/") & "/"
  else: ""


func isHeld(branch: string, f: Finding, owned: Table[string, HashSet[int]]): bool =
  ## Tell whether branch holds finding for project it lies inside, which only branch of role
  ##   owning that project must clear (duty 3); finding on line branch changed is its own.
  let project = f.path.prefixProject
  if project.len == 0 or f.is_propagation or f.is_scope: return false
  if f.line > 0 and f.line in owned.getOrDefault(f.path): return false
  if branch == MAIN: return true
  let parsed = branch.parseBranch
  if parsed.isNone: return false
  case parsed.get.role
  of Role.Curator: project.startsWith(CONTRIBUTOR & "/")
  of Role.CuratorProject, Role.Contributor: project != parsed.get.prefix


func splitHeld*(
  branch: string, found: openArray[Finding], owned = initTable[string, HashSet[int]]()
): tuple[held, own: seq[Finding]] =
  ## Split findings into those branch holds for their projects and those it must fix; `owned`
  ##   holds lines branch changed, by path (`tree.linesOwned`).
  for f in found:
    if branch.isHeld(f, owned): result.held.add f
    else: result.own.add f
