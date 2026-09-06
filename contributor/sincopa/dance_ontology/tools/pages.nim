## Copy page shells into build: `pages <build>` copies `pages/app/index.html` and
##   `pages/sim/index.html` to `<build>/app/` and `<build>/sim/`, where build driver compiles
##   each page's script beside it.
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
  for dir in ["app", "sim"]:
    createDir(build / dir)
    copyFile(PAGES / dir / "index.html", build / dir / "index.html")
    echo "wrote ", build / dir / "index.html"


when isMainModule:
  doAssert paramCount() == 1, "Usage: pages <build>; got `" & $paramCount() & "` arguments."
  copyShells(paramStr(1))
