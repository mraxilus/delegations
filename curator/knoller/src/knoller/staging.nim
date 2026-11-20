## Enforce staging of compile time, and fix it (`koch fix`): each routine of compile-time family
##   carries `compileTime` alike, and none carries runtime pragma (STYLE.md §2); branch on what
##   build fixes is `when`, never `if` (STYLE.md §3).
##   Checks report nothing yet, and fixers change nothing yet.
##   Branch reads constants of other modules of its package from caller (`constants`), since rule
##     reads one file; `constantsExported` reads those of one module.

{.experimental: "strictFuncs".}

import ./reports


func checkFamilies*(path, source: string): seq[Report] =
  ## Report member of compile-time family lacking `compileTime`, and compile-time routine
  ##   carrying runtime pragma (STYLE.md §2).
  discard


func fixFamilies*(path, source: string): Fix =
  ## Add `compileTime` to each member check reports, and drop each runtime pragma.
  result.source = source


func checkBranches*(path, source: string; constants: seq[string] = @[]): seq[Report] =
  ## Report `if` whose condition reads only what build fixes, outside code compile time alone runs
  ##   (STYLE.md §3); `constants` names constants other modules of package export.
  discard


func fixBranches*(path, source: string; constants: seq[string]): Fix =
  ## Write `when` for each `if` check reports, where branch declares no name and line fits.
  result.source = source


func constantsExported*(source: string): seq[string] =
  ## Read name of each constant module exports at its level, which branch of other module of its
  ##   package reads as fixed by build.
  discard
