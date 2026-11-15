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
  PATHS_COPIED = ["app", "src", "tools", "atlas.config", "atlas.lock", "nim.cfg"]
    ## Each entry of checkout that driver may read beside nimble file; `dependencies/` is none.
  PATH_NIM = getCurrentCompilerExe()  ## Compiler that builds this suite, which runs driver too.
  FLOOR_PACKAGES = 6  ## Least packages `system` prints: 6 printed on 2026-11-15.


func pathsCopied(directory: string): seq[string] =
  ## Read each entry that driver may read in project whose folder is `directory`: nimble file
  ##   takes name of folder, so move of folder renames it, and copy follows.
  @PATHS_COPIED & (directory.lastPathPart & ".nimble")


proc copyProject(source, target: string) =
  ## Copy each entry that driver may read from project in `source` into `target`.
  for path in pathsCopied(source):
    if dirExists(source / path):
      copyDir(source / path, target / path)
    else:
      createDir(target)
      copyFile(source / path, target / path)


suite "Driver before restore of packages":
  test "Driver prints each system package in copy of project that holds no package":
    let
      directory = getTempDir() / ("lojban_tagger_driver_" & $getCurrentProcessId())
      cache = directory / "nimcache"
    removeDir(directory)
    copyProject(DIRECTORY_PROJECT, directory)
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


  test "Copy holds nimble file of project whose folder takes another name, as move gives":
    ## Regression of #939, as found on 2026-11-15: on branch that moves this folder to
    ##   `contributor/bangu/rictadni`, copy stopped with
    ##   `OSError: No such file or directory: …/rictadni/lojban_tagger.nimble`.
    let
      root = getTempDir() / ("lojban_tagger_folders_" & $getCurrentProcessId())
      source = root / "rictadni"
      target = root / "copy"
    removeDir(root)
    for path in ["app", "src", "tools"]: createDir(source / path)
    for path in ["atlas.config", "atlas.lock", "nim.cfg", "rictadni.nimble"]:
      writeFile(source / path, "")
    var is_copied = false
    try:
      copyProject(source, target)
      is_copied = fileExists(target / "rictadni.nimble")
    except OSError as error:
      checkpoint "refused: " & error.msg
    removeDir(root)
    check is_copied
