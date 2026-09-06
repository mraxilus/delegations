## Enforce that branch carries base's rules and checker, i.e. what decides meaning of green.
##   Pull request green against yesterday's `main` can merge into today's and be false on
##   arrival: that happened, and `main` ran red until stamp was corrected. GitHub prevents it
##   with "require branches to be up to date", which is behind paid rulesets, so process
##   catches it instead.
##
##   Only two kinds of path matter. Charter (`RULES`) moves stamp every project claims, so
##     branch predating it carries claim that is already false. Checker (`isChecker`) decides
##     what audit accepts, so branch predating it was measured by older ruler.
##   Everything else may differ freely: another project's code cannot make this branch's
##     stamp false, and demanding branch be current with all of it is friction for nothing.
##
##   Cost: merging rules change reddens every open pull request until each merges base. That
##     is same cost paid setting carries, and it fires exactly when staleness is real.
##   Cost: check reads pull request time, never merge time. Branch green at ten can still
##     merge at five past after another lands. Window shrinks from days to minutes; only
##     merge queue closes it, and that is paid feature again.

{.experimental: "strictFuncs".}

import std/strutils
import ./[findings, provenance, plan]


func isGoverning*(path: string): bool =
  ## Decide whether path decides what green means, i.e. charter document or checker.
  path in RULES or path.isChecker


func checkBase*(gained: openArray[string]): seq[Finding] =
  ## Report branch predating base's rules or checker, naming what it lacks.
  var behind: seq[string]
  for path in gained:
    if path.isGoverning and path notin behind: behind.add path
  if behind.len == 0: return
  result.add finding(
    "", 0,
    "Branch predates rules or checker on base; merge base, re-audit, then push; got `" &
      behind.join(", ") & "`.",
  )
