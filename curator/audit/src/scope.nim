## Enforce branch scope: project branch changes only its project folder.
##   Branch grammar lives in `domains.nim`; this check reads parsed prefix. Curator root
##   branch owns empty prefix, so every path passes: rules changes must re-stamp every
##   project (owner's decision). `main` passes: pushes to main are merges owner approved.
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
      "Branch must match `contributor/<domain>/<project>/<name>`, `curator/<project>/<name>` " &
        "or `curator/<name>`; got `" & branch & "`.",
    )]
  let prefix = parsed.get.prefix
  for p in paths:
    if not p.startsWith(prefix):
      result.add finding(p, 0, "Path outside branch scope `" & prefix & "`.")
