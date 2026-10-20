## Enforce branch scope: project branch changes only its project folder.
##   Branch grammar lives in `domains.nim`; this check reads parsed prefix. Curator root
##   branch owns empty prefix, so every path passes: rules changes must re-stamp every
##   project (owner's decision). `main` passes: pushes to main are merges owner approved.
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
##   Held finding: curator branch whose check or rule reddens contributor project waits for
##     that project to fix (CURATOR.md, duty 3), and never fixes it itself. `koch check` holds
##     such finding apart and blocks on rest, so pre-push hook passes without `--no-verify`;
##     runner still reads whole tree, so pull request stays red until project fixes.
##   Held means inside contributor project, records included, since duty 3 forbids fixing
##     there too; propagation finding (stale stamp, standard moved to root) stays curator's.
##   Contributor branch holds nothing: finding in its project is its own, and finding in
##     another project means base is red, which no branch hides.
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

import std/[options, sets, strutils]
import ../../knoller/src/knoller
import ./[domains, findings, layout]


const KEY_FILENAME = "\"filename\":"  ## Key of lock line naming nimble copy, as Atlas writes it.


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
      result.add finding(p, 0, "Path outside branch scope `" & prefix & "`.")
    elif is_root_curator and p.startsWith(CONTRIBUTOR & "/") and p notin moved_set:
      result.add checkPropagation(p)


func isHeld(branch: string, f: Finding): bool =
  ## Tell whether curator branch holds finding for contributor project to fix (duty 3).
  let parsed = branch.parseBranch
  if parsed.isNone or parsed.get.role == Role.Contributor or f.is_propagation: return false
  let parts = f.path.split('/')
  parts.len > 3 and parts[0] == CONTRIBUTOR


func splitHeld*(branch: string, found: openArray[Finding]): tuple[held, own: seq[Finding]] =
  ## Split findings into those branch holds for their projects and those it must fix.
  for f in found:
    if branch.isHeld(f): result.held.add f
    else: result.own.add f
