## Drive every project's own check, i.e. `make -C <project> check` (Article IX.6).
##   One verb per project, chosen by owner: Makefile with `check` target, so language inside
##   project stays free while repository speaks one verb.
##   Output streams through untouched; failure becomes finding at project Makefile.
##
##   Cost: projects run serially; parallelism waits until it costs minutes, unmeasured.

{.experimental: "strictFuncs".}

import std/[os, osproc]
import ./findings


proc runProjects*(root: string, dirs: openArray[string]): seq[Finding] =
  ## Run `make check` in each project directory, reporting non-zero exits.
  for dir in dirs:
    echo "== " & dir
    let code = execCmd("make -C " & (root / dir).quoteShell & " check")
    if code != 0:
      result.add finding(dir & "/Makefile", 0, "`make check` failed; got exit `" & $code & "`.")
