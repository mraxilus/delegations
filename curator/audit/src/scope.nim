## Enforce branch scope: project branch changes only its project folder.
##   Branch grammar lives in `domains.nim`; this check reads parsed prefix. Curator root
##   branch owns empty prefix, so every path passes: rules changes must re-stamp every
##   project (owner's decision). `main` passes: pushes to main are merges owner approved.
##
##   That empty prefix is narrowed where it reaches contributor projects. Curator propagating
##     rule writes their records, `PROJECT_FILES` from `layout.nim`, and nothing else: stamp
##     row, agreed terms, and prose rule invalidated, which is what propagation is. Source,
##     tests and nimble file stay contributor's, so duty 9 stops being prose alone.
##   Rules change reaching contributor code means changing rule or check, then letting
##     contributor apply it, which CURATOR.md duty 9 already says.
##   Content-preserving move is exempt, since registry is curator's and renaming domain or
##     project is registry change; moving file is consequence, never authorship. Only exact
##     rename counts (`movedPaths`, 100% similarity), so edit disguised as move is caught.
##
##   Cost: owner may merge red pull request deliberately; check is guard, not gate.
##   Cost: curator may still rewrite contributor's prose freely, since README is writable;
##     that part duty 9 governs by reading, never by check.
##   Cost: curator may reorder contributor's files without asking, since move is exempt.
##     Content cannot change and move is visible in review, so cost is disorder, not damage.

{.experimental: "strictFuncs".}

import std/[options, sets, strutils]
import ./[findings, domains, layout]


func checkPropagation(path: string): seq[Finding] =
  ## Report curator writing anything but contributor project's records.
  let parts = path.split('/')
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
  let prefix = parsed.get.prefix
  let is_curator_root = parsed.get.role == Role.Curator
  let is_moved = moved.toHashSet
  for p in paths:
    if not p.startsWith(prefix):
      result.add finding(p, 0, "Path outside branch scope `" & prefix & "`.")
    elif is_curator_root and p.startsWith(CONTRIBUTOR & "/") and p notin is_moved:
      result.add checkPropagation(p)
