## Copy page shells into build: `pages <build>` copies `pages/app/index.html` to
##   `<build>/app/`, where build driver compiles that page's script beside it.
##   Body sim's own shell went with its live solver: engine that answers it now is C, which
##     no browser runs, so that page is rebuilt as player of sweeps run here.
##   Shells were Nim string constants while repository read no markup kind; `Html` and `Svg`
##     are registered now, so pages are committed files and this copies them.
##     Cost: page and its script are built by two steps that must agree on directory name.
##   Cost: paths are relative to project directory, as every path in build driver is.
##   Cost: runs once per build, so no hot path exists (unmeasured).

{.experimental: "strictFuncs".}

import std/os


const PAGES = "pages"
  ## Directory committed pages live in.


proc copyShells(build: string) =
  ## Copy both page shells under `build`, creating directories.
  for dir in ["app"]:
    createDir(build / dir)
    copyFile(PAGES / dir / "index.html", build / dir / "index.html")
    echo "wrote ", build / dir / "index.html"


when isMainModule:
  doAssert paramCount() == 1, "Usage: pages <build>; got `" & $paramCount() & "` arguments."
  copyShells(paramStr(1))
