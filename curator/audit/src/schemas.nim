## Hold each folder of protobuf schemas branch changed to version base shipped, by `buf breaking`.
##   Field numbers carry versions of format, as Architect ruled on #761, D1: field or enum value
##     is added under new number, and deleted only by reserving its number and name; none is
##     renumbered, retyped or renamed. Category `WIRE_JSON` of `buf breaking` refuses each of
##     those, naming field or value, and passes what neither bytes nor JSON text can see.
##   Rule `FIELD_SAME_CARDINALITY` refuses field gaining or losing `optional` too, which
##     `WIRE_JSON` passes: bytes stay, but `optional` decides whether absent field reads as zero
##     or as absent, so each older file changes meaning.
##   Shipped is schema at tip of base, not at merge base: newest version anyone may have written
##     files under is what branch must still read. Branch side is HEAD, as changed paths are.
##   Unit held is folder: each folder holding changed schema is one module of `buf`, read at tip
##     of base and at HEAD, so import between schemas of one folder resolves on both sides, and
##     message moved between them is no deletion.
##   Folder new on branch, or gone from base, has nothing shipped to hold it to, and passes.
##   Message deleted whole passes: bytes carry no message name, so format retired is decision,
##     not drift. Field of its type is deleted too, and that deletion is held.
##   New package moves, as Architect ruled on #981 (comment 7053327767): `buf` pairs messages of
##     two sides by full name, and rule `FILE_SAME_PACKAGE` refuses new package of file of same
##     path. So where one package of base is gone and one new package stands, each shipped
##     schema reads under new package first (`underPackage`), and each field stays held, file
##     renamed or not.
##     New package beside `Any`, `service` or `extend` is refused, since full name of message
##       reaches data or path there; so is folder whose packages split, so that none maps to one.
##
##   Cost: import resolves against schema's own folder, as Nim library of Status and
##     `protobufjs` resolve it, so schema importing from another folder fails to compile here.
##   Cost: `buf` is fetched where store lacks it (`bufbuild.nim`), and only where branch changed
##     schema in folder base also holds.
##   Cost: package whose messages move into other package of its folder, which base holds
##     already, is held by `FILE_SAME_PACKAGE` alone, on file of same path.

{.experimental: "strictFuncs".}

import std/[algorithm, json, options, os, osproc, sequtils, strutils]
from ../../knoller/src/knoller/command import runGit
import ./[bufbuild, findings, tree]


const
  EXT_SCHEMA = ".proto"  ## Extension of protobuf schema (`kinds.nim`).
  CONFIG_BREAKING =
    "version: v2\nbreaking:\n  use:\n    - WIRE_JSON\n    - FIELD_SAME_CARDINALITY\n"
    ## Config each module carries: category holding bytes and JSON text, never file layout,
    ##   and rule holding presence of each field.
  CODE_BREAKING = 100  ## Exit code of `buf` where it found breaking change or compile error.
  OPENING_PACKAGE = "package "  ## Opening of statement that declares package of schema.
  NAME_ANY = "google.protobuf.Any"  ## Type whose data names full name of message it holds.
  OPENINGS_FULL_NAME = ["service ", "extend "]
    ## Openings of statements whose full name reaches path of method, or name of extension.
  MARKS_BEFORE_NAME = Whitespace + {'(', '<'}
    ## Marks that may stand before qualified name of type, as in `(pkg.Message)`.
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


func packageDeclared*(text: string): string =
  ## Read package schema text declares: name after `package` of first line opening with it, up to
  ##   `;`; empty where text declares none.
  for line in text.splitLines:
    let statement = line.strip
    if statement.startsWith(OPENING_PACKAGE) and statement.endsWith(";"):
      return statement[OPENING_PACKAGE.len ..< statement.high].strip
  ""


func packagesDeclared(schemas: openArray[(string, string)]): seq[string] =
  ## Read each package schemas declare, once, sorted.
  for (_, text) in schemas:
    let name = text.packageDeclared
    if name notin result: result.add name
  result.sort


func isFullNameExposed*(text: string): bool =
  ## Decide whether schema text holds `google.protobuf.Any`, or statement opening `service` or
  ##   `extend`: there full name of message reaches type URL, path of method, or name of extension.
  if NAME_ANY in text: return true
  for line in text.splitLines:
    let statement = line.strip
    if OPENINGS_FULL_NAME.anyIt(statement.startsWith(it)): return true


func underPackage*(text, old, new: string): string =
  ## Write schema text under package `new` in place of `old`: its statement `package`, and each
  ##   name qualified by `old` after space, `(` or `<`, or after `.` that opens full name.
  ##   Name that this misses fails to compile under `new`, so check refuses rather than passes.
  let
    statement = OPENING_PACKAGE & old & ";"
    qualified = old & "."
  var i = 0
  while i < text.len:
    let before = (if i > 0: text[i - 1] else: '\n')
    if before in Whitespace and text.continuesWith(statement, i):
      result.add OPENING_PACKAGE & new & ";"
      i += statement.len
      continue
    let is_opened = before == '.' and (i < 2 or text[i - 2] in MARKS_BEFORE_NAME)
    if i > 0 and (before in MARKS_BEFORE_NAME or is_opened) and text.continuesWith(qualified, i):
      result.add new & "."
      i += qualified.len
      continue
    result.add text[i]
    inc i


proc breakingFindings*(
  binary, folder: string; before, after: openArray[(string, string)]
): seq[Finding] =
  ## Run `buf breaking` of schemas `after` against schemas `before`, each `(name, text)` of
  ##   `folder`, with each side written under scratch work as module of its own.
  ##   Where one package of `before` is gone and one new package stands, `before` reads under it
  ##     (`underPackage`); new package beside full name in data, or split of packages, is finding.
  let
    gone = packagesDeclared(before).filterIt(it notin packagesDeclared(after))
    added = packagesDeclared(after).filterIt(it notin packagesDeclared(before))
    moved = "`" & gone.join("`, `") & "` to `" & added.join("`, `") & "`"
  var shipped = @before
  if gone.len > 0 and added.len > 0:
    if before.anyIt(it[1].isFullNameExposed) or after.anyIt(it[1].isFullNameExposed):
      return @[finding(folder, 0, "Schema folder takes new package beside `Any`, `service` or " &
        "`extend`, where full name of message reaches data or path; keep package; got " &
        moved & ".")]
    if gone.len != 1 or added.len != 1:
      return @[finding(folder, 0, "Schema folder changes package, and no one package of base " &
        "maps to one of branch, so no field is held; move one package whole; got " & moved & ".")]
    shipped = before.mapIt((it[0], it[1].underPackage(gone[0], added[0])))
  let work = getTempDir() / "koch_schemas_" & $getCurrentProcessId()
  for (side, schemas) in [(SIDES[0], shipped), (SIDES[1], @after)]:
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
