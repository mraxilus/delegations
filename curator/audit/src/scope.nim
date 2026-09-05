## Enforce branch scope: contributor branch changes only its project folder.
##   Branch grammar lives in `domains.nim`; this check reads parsed role and prefix.
##   `main` passes: pushes to main are merges owner already approved.
##   Curator branches pass every path: rules changes must re-stamp every project (owner's
##     decision), so no prefix could hold.
##
##   Cost: owner may merge red pull request deliberately; check is guard, not gate.

{.experimental: "strictFuncs".}

import std/[options, strutils]
import ./[findings, domains]


func checkScope*(branch: string, paths: openArray[string]): seq[Finding] =
  ## Report branch name outside grammar, then each path outside branch prefix.
  if branch == MAIN: return
  let parsed = branch.parseBranch
  if parsed.isNone:
    return @[finding(
      "", 0,
      "Branch must match `<domain>/<project>/<name>` or `curator/<name>`; got `" & branch & "`.",
    )]
  let b = parsed.get
  if b.role == Role.Curator: return
  for p in paths:
    if not p.startsWith(b.prefix):
      result.add finding(p, 0, "Path outside branch scope `" & b.prefix & "`.")
