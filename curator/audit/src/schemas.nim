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
##     path. So each side first builds to image, whose packages and names of types `buf` parsed
##     and resolved. Where one package of base is gone and one new package stands, shipped image
##     takes new package (`underPackage`), and branch is held against that image. So each field
##     stays held, file renamed or not.
##     Image names each type in full, so package moves by exact name: no form of statement or
##       comment, nor package nested under moved one, reads wrong.
##     New package beside `Any`, `service` or `extend` is refused, since full name of message
##       reaches data or path there; so is folder whose packages do not map one to one, by split
##       or merge.
##   Rejected: rewrite of text of each shipped schema. Read of statement by text misses forms
##     that `buf` reads, as comment before statement, and name of package nested under moved one
##     reads as moved; each miss passes break of renamed file (#996).
##
##   Cost: import resolves against schema's own folder, as Nim library of Status and
##     `protobufjs` resolve it, so schema importing from another folder fails to compile here.
##   Cost: `buf` is fetched where store lacks it (`bufbuild.nim`), and only where branch changed
##     schema in folder base also holds.
##   Cost: package whose messages move into other package of its folder, which base holds
##     already, is held by `FILE_SAME_PACKAGE` alone, on file of same path; so where file goes,
##     break of moved message passes.
##   Cost: each side builds to image before compare, so `buf` runs three times for each folder
##     held, not once.

{.experimental: "strictFuncs".}

import std/[json, options, os, osproc, sequtils, strutils]
from ../../knoller/src/knoller/command import runGit
import ./[bufbuild, findings, tree]


const  # TODO: Document.
  EXT_SCHEMA = ".proto"  ## Extension of protobuf schema (`kinds.nim`).
  CONFIG_BREAKING =
    "version: v2\nbreaking:\n  use:\n    - WIRE_JSON\n    - FIELD_SAME_CARDINALITY\n"
    ## Config each module carries: category holding bytes and JSON text, never file layout,
    ##   and rule holding presence of each field.
  CODE_BREAKING = 100  ## Exit code of `buf` where it found breaking change or compile error.
  EXT_IMAGE = ".json"  ## Extension of image that `buf build` writes of side; it selects JSON.
  NAME_ANY = ".google.protobuf.Any"  ## Full name of type whose data names message it holds.
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
      result.add finding(
        folder,
        0,
        Check.ToolSchema,
        "Buf printed what is no finding; got `" & line & "`.",
      )
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
        Check.CompileSchema,
        "Schema does not compile" & shipped & ", so no version of it is held; got `" & message &
          "`.",
        help = "import only schemas of its own folder",
      )
    else:
      result.add finding(
        path, at,
        Check.SchemaBreaking,
        "Schema change breaks version base shipped; got `" & message & "`.",
        help = "add field or value under new number, and delete one only by reserving its " &
          "number and name",
      )


func entries(node: JsonNode, key: string): seq[JsonNode] =
  ## Read list `key` of descriptor in image; empty where `buf` wrote none, as it omits empty list.
  let entry = node{key}
  if entry != nil and entry.kind == JArray: entry.elems else: @[]


func isOwn(file: JsonNode): bool =
  ## Decide whether file of image is schema of folder, and no file that schema imports.
  not file{"bufExtension", "isImport"}.getBool


func packagesBuilt(image: JsonNode): seq[string] =
  ## Read each package that schemas of image declare, once each; empty is root package.
  for file in image.entries("file"):
    let package = file{"package"}.getStr
    if file.isOwn and package notin result: result.add package


func isNameExposed(message: JsonNode): bool =
  ## Decide whether message, or one nested in it, declares extension or field of `Any`.
  if message.entries("extension").len > 0: return true
  for field in message.entries("field"):
    if field{"typeName"}.getStr == NAME_ANY: return true
  message.entries("nestedType").anyIt(it.isNameExposed)


func isFullNameExposed(image: JsonNode): bool =
  ## Decide whether schema of image holds `service`, `extend` or field of `google.protobuf.Any`:
  ##   there full name of message reaches path of method, name of extension, or type URL.
  for file in image.entries("file"):
    if not file.isOwn: continue
    if file.entries("service").len > 0 or file.entries("extension").len > 0: return true
    if file.entries("messageType").anyIt(it.isNameExposed): return true


func scopeFull(package: string): string =
  ## Write prefix of each full name in `package`: `.` and package; empty for root package.
  if package.len > 0: "." & package else: ""


func namesDefined(message: JsonNode, scope: string): seq[string] =
  ## Read full name of message under `scope`, then of each enum and message nested in it.
  let name = scope & "." & message{"name"}.getStr
  result.add name
  for nested in message.entries("enumType"): result.add name & "." & nested{"name"}.getStr
  for nested in message.entries("nestedType"): result.add nested.namesDefined(name)


proc moveFields(message: JsonNode; names: openArray[string]; old, new: string) =
  ## Write each field of message, and of each message nested in it, whose type is one of `names`
  ##   under scope `new` in place of scope `old`.
  for field in message.entries("field"):
    let name = field{"typeName"}.getStr
    if name in names: field["typeName"] = %(new & name[old.len .. ^1])
  for nested in message.entries("nestedType"): nested.moveFields(names, old, new)


proc underPackage(image: JsonNode; old, new: string) =
  ## Write image under package `new` in place of `old`: each schema of `old` declares `new`, and
  ##   each field whose type `old` defines names it under `new`. Match is by full name that `buf`
  ##   resolved, so no form of text, nor package nested under `old`, moves wrong.
  let (scope_old, scope_new) = (old.scopeFull, new.scopeFull)
  var names: seq[string]
  for file in image.entries("file"):
    if not file.isOwn or file{"package"}.getStr != old: continue
    for nested in file.entries("enumType"): names.add scope_old & "." & nested{"name"}.getStr
    for message in file.entries("messageType"): names.add message.namesDefined(scope_old)
  for file in image.entries("file"):
    if not file.isOwn: continue
    if file{"package"}.getStr == old:
      if new.len > 0: file["package"] = %new else: file.delete("package")
    for message in file.entries("messageType"): message.moveFields(names, scope_old, scope_new)


proc imageBuilt(binary, work, side: string): Option[JsonNode] =
  ## Read image that `buf build` writes of module `side` under `work`; none where it does not
  ##   compile, so that `buf breaking` names that error itself.
  let
    image = side & EXT_IMAGE
    (_, code) = execCmdEx(quoteShellCommand([binary, "build", side, "-o", image]),
      workingDir = work)
  if code == 0: return some(parseJson(readFile(work / image)))


proc breakingFindings*(
  binary, folder: string; before, after: openArray[(string, string)]
): seq[Finding] =
  ## Run `buf breaking` of schemas `after` against schemas `before`, each `(name, text)` of
  ##   `folder`, with each side written under scratch work as module of its own.
  ##   Where one package of `before` is gone and one new package stands, branch is held against
  ##     image of `before` under new package (`underPackage`); new package beside full name in
  ##     data, or packages that do not map one to one, is finding.
  let work = getTempDir() / "koch_schemas_" & $getCurrentProcessId()
  for (side, schemas) in [(SIDES[0], @before), (SIDES[1], @after)]:
    createDir(work / side)
    writeFile(work / side / "buf.yaml", CONFIG_BREAKING)
    for (name, text) in schemas: writeFile(work / side / name, text)
  defer: removeDir(work)
  var against = SIDES[0]
  let images = SIDES.mapIt(imageBuilt(binary, work, it))
  if images.allIt(it.isSome):
    let
      packages = images.mapIt(it.get.packagesBuilt)
      gone = packages[0].filterIt(it notin packages[1])
      added = packages[1].filterIt(it notin packages[0])
      moved = "`" & gone.join("`, `") & "` to `" & added.join("`, `") & "`"
    if gone.len > 0 and added.len > 0:
      if images.anyIt(it.get.isFullNameExposed):
        return @[finding(
          folder,
          0,
          Check.PackageSchema,
          "Schema folder takes new package beside `Any`, `service` or `extend`, where full name " &
            "of message reaches data or path; got " & moved & ".",
          help = "keep package",
        )]
      if gone.len != 1 or added.len != 1:
        return @[finding(
          folder,
          0,
          Check.PackageSchema,
          "Schema folder changes package, and no one package of base maps to one of branch, so " &
            "no field is held; got " & moved & ".",
          help = "move one package whole",
        )]
      images[0].get.underPackage(gone[0], added[0])
      against = SIDES[0] & EXT_IMAGE
      writeFile(work / against, $images[0].get)
  let (output, code) = execCmdEx(
    quoteShellCommand([binary, "breaking", SIDES[1], "--against", against,
      "--error-format", "json"]),
    workingDir = work,
  )
  if code == 0: return
  if code != CODE_BREAKING:
    return @[finding(folder, 0, Check.ToolSchema, "Buf could not compare schemas of folder; got `" &
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
      Check.ToolSchema,
      "Buf could not be fetched or checked at its pin, so no schema change is held; reason is " &
        "above; got `" & VERSION_BUFBUILD & "`.",
    )]
  for (folder, before, after) in held:
    result.add breakingFindings(binary.get, folder, before, after)
