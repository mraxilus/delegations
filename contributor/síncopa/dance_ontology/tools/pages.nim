## Write page shells from their Nim hosts: `pages <build>` writes `<build>/app/index.html`
##   and `<build>/sim/index.html`, where `make pages` compiles each page's script beside it.
##   Markup lives in Nim modules because repository reads only registered file kinds.
##   Cost: runs once per build, so no hot path exists (unmeasured).

{.experimental: "strictFuncs".}

import std/os

import ../app/shell as app_shell
import ../sim/shell as sim_shell


proc writeShells(build: string) =
  ## Write both shells under `build`, creating directories.
  for (dir, markup) in [("app", app_shell.SHELL), ("sim", sim_shell.SHELL)]:
    createDir(build / dir)
    writeFile(build / dir / "index.html", markup)
    echo "wrote ", build / dir / "index.html"


when isMainModule:
  doAssert paramCount() == 1, "Usage: pages <build>; got `" & $paramCount() & "` arguments."
  writeShells(paramStr(1))
