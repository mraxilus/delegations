## Report project pin no compiler serves, as finding of audit.
##   Resolution itself, i.e. PATH, else cache, else fetch, is knoller's (`compilers.nim` there),
##   which audit imports; finding is audit's alone, since knoller returns no `Finding`.
##   Cost: one concern spans two projects, resolution there and its finding here, since audit
##     imports knoller and never reverse.

{.experimental: "strictFuncs".}

import ./findings


func missing*(directory, pin, bin: string): seq[Finding] =
  ## Report pin no compiler serves, naming cache koch tried, so remedy is visible.
  @[finding(
    directory, 0,
    "No compiler serves project pin, and fetching one failed; install it under `" & bin &
    "`, or make network reachable, then run again; got `" & pin & "`.",
  )]
