## Hold each folder of protobuf schemas branch changed to version base shipped, by `buf breaking`.
##   Field numbers carry versions of format, as Architect ruled on #761, D1: field or enum value
##     is added under new number, and deleted only by reserving its number and name; none is
##     renumbered, retyped or renamed. Category `WIRE_JSON` of `buf breaking` refuses each of
##     those, naming field or value, and passes what neither bytes nor JSON text can see.
##   Shipped is schema at tip of base, not at merge base: newest version anyone may have written
##     files under is what branch must still read. Branch side is HEAD, as changed paths are.
##   Unit held is folder: each folder holding changed schema is one module of `buf`, read at tip
##     of base and at HEAD, so import between schemas of one folder resolves on both sides, and
##     message moved between them is no deletion.
##   Folder new on branch, or gone from base, has nothing shipped to hold it to, and passes.
##   Message deleted whole passes: bytes carry no message name, so format retired is decision,
##     not drift. Field of its type is deleted too, and that deletion is held.
##
##   Cost: import resolves against schema's own folder, as Nim library of Status and
##     `protobufjs` resolve it, so schema importing from another folder fails to compile here.
##   Cost: `buf` is fetched where store lacks it (`bufbuild.nim`), and only where branch changed
##     schema in folder base also holds.

{.experimental: "strictFuncs".}

import std/[json, options, os, osproc, strutils]
from ../../knoller/src/knoller/command import runGit
import ./[bufbuild, findings, tree]


const
  EXT_SCHEMA = ".proto"  ## Extension of protobuf schema (`kinds.nim`).
  CONFIG_BREAKING = "version: v2\nbreaking:\n  use:\n    - WIRE_JSON\n"
    ## Config each module carries: category holding bytes and JSON text, never file layout.
  CODE_BREAKING = 100  ## Exit code of `buf` where it found breaking change or compile error.
  SIDES = ["before", "after"]  ## Module folders under work: shipped, then branch.


func schemasChanged*(paths: openArray[string]): seq[string] =
  ## Keep changed paths that are protobuf schemas.
  for path in paths:
    if path.endsWith(EXT_SCHEMA): result.add path


func foldersChanged*(paths: openArray[string]): seq[string] =
  ## Read each folder holding changed schema, once, in order of first change; root is empty,
  ##   so git reads it as `<revision>:`.
  for path in schemasChanged(paths):
    let folder = path.splitPath.head
    if folder notin result: result.add folder


proc findingsBreaking*(output, folder: string): seq[Finding] =
  ## Read findings from lines `buf breaking --error-format json` printed, one object to line.
  ##   Path printed is under module folder of its side; finding names schema in `folder`, and
  ##     line only on branch's side, since shipped text has no line in branch.
  for line in output.splitLines:
    if line.strip.len == 0: continue
    var annotation: JsonNode
    try:
      annotation = parseJson(line)
    except JsonParsingError, ValueError:
      result.add finding(folder, 0, "Buf printed what is no finding; got `" & line & "`.")
      continue
    let
      (side, name) = annotation{"path"}.getStr.splitPath
      path = folder / name
      at = if side == SIDES[1]: annotation{"start_line"}.getInt else: 0
      message = annotation{"message"}.getStr
    if annotation{"type"}.getStr == "COMPILE":
      let shipped = if side == SIDES[0]: " as base shipped it" else: ""
      result.add finding(
        path, at,
        "Schema does not compile" & shipped & ", so no version of it is held; import only " &
          "schemas of its own folder; got `" & message & "`.",
      )
    else:
      result.add finding(
        path, at,
        "Schema change breaks version base shipped; add field or value under new number, and " &
          "delete one only by reserving its number and name; got `" & message & "`.",
      )


proc breakingFindings*(
  binary, folder: string; before, after: openArray[(string, string)]
): seq[Finding] =
  ## Run `buf breaking` of schemas `after` against schemas `before`, each `(name, text)` of
  ##   `folder`, with each side written under scratch work as module of its own.
  let work = getTempDir() / "koch_schemas_" & $getCurrentProcessId()
  for (side, schemas) in [(SIDES[0], @before), (SIDES[1], @after)]:
    createDir(work / side)
    writeFile(work / side / "buf.yaml", CONFIG_BREAKING)
    for (name, text) in schemas: writeFile(work / side / name, text)
  defer: removeDir(work)
  let (output, code) = execCmdEx(
    quoteShellCommand([binary, "breaking", SIDES[1], "--against", SIDES[0],
      "--error-format", "json"]),
    workingDir = work,
  )
  if code == 0: return
  if code != CODE_BREAKING:
    return @[finding(folder, 0, "Buf could not compare schemas of folder; got `" &
      output.strip & "`.")]
  findingsBreaking(output, folder)


proc schemasAt*(root, revision, folder: string): seq[(string, string)] =
  ## Read each schema directly in `folder` at `revision`, as `(name, text)`; none where folder
  ##   is absent there. Subfolder is module of its own, so it is never read here.
  let (listed, _, code) = runGit(root, ["ls-tree", "-z", revision & ":" & folder])
  if code != 0: return
  for entry in listed.split('\0'):
    # Entry is `<mode> <type> <object>`, tab, then name.
    let parts = entry.split('\t', 1)
    if parts.len < 2 or not parts[1].endsWith(EXT_SCHEMA): continue
    let fields = parts[0].splitWhitespace
    if fields.len < 3 or fields[1] != "blob": continue
    let (text, _, read) = runGit(root, ["cat-file", "blob", fields[2]])
    if read == 0: result.add (parts[1], text)


proc checkSchemas*(root, base: string): seq[Finding] =
  ## Hold each folder of schemas branch changed to version base shipped; fetch `buf` only where
  ##   such folder holds schema on both sides.
  var held: seq[(string, seq[(string, string)], seq[(string, string)])]
  for folder in foldersChanged(pathsChanged(root, base)):
    let
      before = schemasAt(root, base, folder)
      after = schemasAt(root, "HEAD", folder)
    if before.len > 0 and after.len > 0: held.add (folder, before, after)
  if held.len == 0: return
  let binary = bufbuildIn(rootBufbuild(getEnv(KEY_BUFBUILD)))
  if binary.isNone:
    return @[finding(
      "curator/audit/src/bufbuild.nim", 0,
      "Buf could not be fetched or checked at its pin, so no schema change is held; reason is " &
        "above; got `" & VERSION_BUFBUILD & "`.",
    )]
  for (folder, before, after) in held:
    result.add breakingFindings(binary.get, folder, before, after)
