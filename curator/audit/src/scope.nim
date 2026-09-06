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
##
##   Cost: owner may merge red pull request deliberately; check is guard, not gate.
##   Cost: curator may still rewrite contributor's prose freely, since README is writable;
##     that part duty 9 governs by reading, never by check.

{.experimental: "strictFuncs".}

import std/[options, strutils]
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
  let is_curator_root = parsed.get.role == Role.Curator
  for p in paths:
    if not p.startsWith(prefix):
      result.add finding(p, 0, "Path outside branch scope `" & prefix & "`.")
    elif is_curator_root and p.startsWith(CONTRIBUTOR & "/"):
      result.add checkPropagation(p)
