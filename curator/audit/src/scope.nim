## Enforce branch scope: project branch changes only its project folder.
##   Branch grammar lives in `domains.nim`; this check reads parsed prefix. Curator root
##   branch owns empty prefix, so every path passes: rules changes must re-stamp every
##   project (owner's decision). `main` passes: pushes to main are merges owner approved.
##
##   That empty prefix is narrowed where it reaches contributor projects. Curator propagating
##     rule writes their records, `PROJECT_FILES` from `layout.nim`, and nothing else: stamp
##     row, agreed terms, and prose rule invalidated, which is what propagation is. Source,
##     tests and nimble file stay contributor's, so duty 11 stops being prose alone.
##   Rules change reaching contributor code means changing rule or check, then letting
##     contributor apply it, which CURATOR.md duty 11 already says.
##   Content-preserving move is exempt, since registry is curator's and renaming domain or
##     project is registry change; moving file is consequence, never authorship. Only exact
##     rename counts (`movedPaths`, 100% similarity), so edit disguised as move is caught.
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
import ./[domains, findings, layout]


func checkPropagation(path: string): seq[Finding] =
  ## Report curator writing anything but contributor project's records.
  ##   Indexes above project are curator's outright: `contributor/README.md` and
  ##   `contributor/<domain>/README.md` are theirs by repository map, and duty 6 has them
  ##   write second one whenever domain is added. Only inside project does reach narrow.
  let parts = path.split('/')
  if parts.len <= 3: return
  if parts.len == 4 and parts[3] in PROJECT_FILES: return
  result.add finding(
    path, 0,
    "Curator writes only " & PROJECT_FILES.join(", ") & " in contributor project; change " &
      "rule or check and let contributor apply it; got `" & path & "`.",
  )


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
    is_curator_root = parsed.get.role == Role.Curator
    is_moved = moved.toHashSet
  for p in paths:
    if not p.startsWith(prefix):
      result.add finding(p, 0, "Path outside branch scope `" & prefix & "`.")
    elif is_curator_root and p.startsWith(CONTRIBUTOR & "/") and p notin is_moved:
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
