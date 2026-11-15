## Hold that driver runs before Atlas restores any package, as `koch list-packages` runs it.
##   Regression of CI job 132944576548, as found on 2026-11-15: `koch list-packages` printed
##     nothing, and stub stopped at `test_exchanges.nim:449` with
##     `/bin/sh: 1: protoc: not found`.
##   CI installs each package that `system` prints before it restores `dependencies/`
##     (`.github/workflows/check.yml`); driver that does not compile there prints none.
##   Copy of project without `dependencies/` stands in for that checkout: relative import into
##     clone resolves wherever clone stands, so compile in project itself proves nothing.
##   Cost: copy, compile and run of driver took 1.30 s to 1.53 s over three runs on 2026-11-15,
##     against 94.72 s for whole stub.

{.experimental: "strictFuncs".}

import std/[os, osproc, sequtils, strutils, unittest]

from ../../tools/build {.all.} import SYSTEM


const
  DIRECTORY_PROJECT = currentSourcePath().parentDir.parentDir.parentDir
    ## Folder of this project, two above `tests/suites/`.
  PATHS_COPIED = [
    "app", "src", "tools", "atlas.config", "atlas.lock", "lojban_tagger.nimble", "nim.cfg",
  ]
    ## Each entry of checkout that driver may read; `dependencies/` is none of them.
  PATH_NIM = getCurrentCompilerExe()  ## Compiler that builds this suite, which runs driver too.
  FLOOR_PACKAGES = 6  ## Least packages `system` prints: 6 printed on 2026-11-15.


suite "Driver before restore of packages":
  test "Driver prints each system package in copy of project that holds no package":
    let
      directory = getTempDir() / ("lojban_tagger_driver_" & $getCurrentProcessId())
      cache = directory / "nimcache"
    removeDir(directory)
    for path in PATHS_COPIED:
      let (source, target) = (DIRECTORY_PROJECT / path, directory / path)
      if dirExists(source):
        copyDir(source, target)
      else:
        createDir(target.parentDir)
        copyFile(source, target)
    let (output, code) = execCmdEx(
      quoteShell(PATH_NIM) & " r --hints:off --nimcache:" & quoteShell(cache) &
        " tools/build.nim system",
      options = {poUsePath},
      workingDir = directory,
    )
    removeDir(directory)
    checkpoint "printed: " & output
    let printed = output.splitLines.filterIt(it.len > 0)
    check code == 0
    check printed == SYSTEM.mapIt(it[0])
    check printed.len >= FLOOR_PACKAGES
    check "protobuf-compiler" in printed
