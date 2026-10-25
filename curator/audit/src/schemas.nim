## Hold each FlatBuffers schema branch changed to version base shipped, through `flatc --conform`.
##   Schema carries versions of format, as Architect ruled on #755: field is added with default
##     or marked deprecated, and never removed, moved, retyped, renumbered or given new default.
##     `flatc --conform <shipped> <changed>` refuses each of those, naming field or enum value.
##   Shipped is schema at tip of base, not at merge base: newest version anyone may have written
##     files under is what branch must still read.
##   Schema new on branch, or gone from base, has nothing shipped to hold it to, and passes.
##
##   Cost: `include` of shipped schema resolves against branch's tree, so included schema is held
##     only where branch changed it too, and then against its own shipped text.
##   Cost: `flatc` is built where store lacks it (`flatc.nim`), about 1 minute on 4 cores, and
##     only when branch changed schema.
##   Cost: schema deleted on branch passes; format retired is decision, not drift.

{.experimental: "strictFuncs".}

import std/[options, os, osproc, strutils]
from ../../knoller/src/knoller/command import runGit
import ./[findings, flatc, tree]


const EXT_SCHEMA = ".fbs"  ## Extension of FlatBuffers schema (`kinds.nim`).


func schemasChanged*(paths: openArray[string]): seq[string] =
  ## Keep changed paths that are FlatBuffers schemas.
  for path in paths:
    if path.endsWith(EXT_SCHEMA): result.add path


func reason(output: string): string =
  ## Read why `flatc` refused: its line naming what does not conform, else its last line.
  for line in output.splitLines:
    if "conform" in line: return line.strip
  for line in output.splitLines:
    if line.strip.len > 0: result = line.strip


proc conformFindings*(binary, root: string; shipped: openArray[(string, string)]): seq[Finding] =
  ## Run `flatc --conform` of each schema under `root` against its shipped text.
  ##   Shipped text is written apart, under its own path, so its `include` resolves as branch's.
  let work = getTempDir() / "koch_schemas_" & $getCurrentProcessId()
  createDir(work)
  defer: removeDir(work)
  for (path, text) in shipped:
    let before = work / path
    createDir(before.parentDir)
    writeFile(before, text)
    let (output, code) = execCmdEx(quoteShellCommand([
      binary, "--conform", before, "--conform-includes", root, "-I", root, root / path,
    ]))
    if code != 0:
      result.add finding(
        path, 0,
        "Schema change breaks version base shipped; add field with default or mark it " &
          "deprecated, and never remove, move, retype or renumber; got `" & output.reason & "`.",
      )


proc schemasShipped(root, base: string): seq[(string, string)] =
  ## Read each schema branch changed and still holds, with its text at tip of base.
  for path in schemasChanged(pathsChanged(root, base)):
    if not fileExists(root / path): continue
    let (text, _, code) = runGit(root, ["show", base & ":" & path])
    if code == 0: result.add (path, text)


proc checkSchemas*(root, base: string): seq[Finding] =
  ## Hold each schema branch changed to version base shipped; build `flatc` only where one is.
  let shipped = schemasShipped(root, base)
  if shipped.len == 0: return
  let folder = flatcIn(rootFlatc(getEnv(KEY_FLATC)))
  if folder.isNone:
    return @[finding(
      "curator/audit/src/flatc.nim", 0,
      "Flatc could not be fetched, patched or built at its pin, so no schema change is held; " &
        "got `" & KEY_BUILD & "`.",
    )]
  conformFindings(folder.get / "bin" / "flatc", root, shipped)
