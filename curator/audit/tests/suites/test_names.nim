## Replicate names check: declarations read, words split, abbreviations and acronyms held.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/[findings, names]


const SOURCE = """
## Module doc with `ctx` in it, which is comment and unread.

type
  Chiral*[T] = object
    ## Define pair.
    base*: T
    dir_hint: int  # Field coins `dir`.
  Space* {.pure.} = enum
    Base, Anti

const LUT_GRADE_BY_BASIS = block:
  var lut: array[2, int]
  lut

let
  ALGEBRA* = 4
  tmp_count = 2

proc getGrade*(m: int, buf: string): int =
  ## Doc mentions "args" in string, unread.
  let text = "tmp in string stays unread"
  for i, err in ["a", "b"]:
    discard
  m

func toJSON*(x: int; dest: var string) = discard

func constructTable(
  cayley: var int, factors: seq[int], as_exclusions = false
) {.compileTime.} = discard

type Algebra = object
  args*: seq[string]
"""


func names(source: string): seq[string] =
  ## Read declared names of source, in order.
  source.declarations.mapIt(it.name)


func messages(found: seq[Finding]): seq[string] =
  ## Read messages of findings.
  found.mapIt(it.message)



suite "Names":
  test "comments and strings are blanked, newlines kept":
    let code = ("let a = \"# not comment\" # comment\nlet b = r\"raw \"\" quote\" #[ block\n" &
      "]# c").codeOnly
    check code.splitLines.len == 3
    check "comment" notin code and "quote" notin code and "block" notin code
    check "let a =" in code and "let b =" in code and code.splitLines[2].strip == "c"


  test "code-and-comments view blanks strings alone, keeping every length":
    let
      source = "let a = \"# not comment\" # comment\nlet b = '#' #[ block\n]# c"
      kept = source.codeAndComments
    check kept.len == source.len and kept.splitLines.len == 3
    check "not" notin kept and "'#'" notin kept  # string and char blanked
    check "# comment" in kept and "#[ block" in kept and kept.splitLines[2] == "]# c"
    check kept.find('#') == source.find("# comment")  # first `#` left opens comment


  test "declarations of every kind are read":
    let found = SOURCE.names
    for name in ["Chiral", "base", "dir_hint", "Space", "LUT_GRADE_BY_BASIS", "lut", "ALGEBRA",
                 "tmp_count", "getGrade", "m", "buf", "text", "i", "err", "toJSON", "x", "dest",
                 "constructTable", "cayley", "factors", "as_exclusions", "Algebra", "args"]:
      check name in found
    check "ctx" notin found and "Base" notin found  # comment word, enum member
    let kinds = SOURCE.declarations
    check kinds.filterIt(it.name == "ALGEBRA")[0].is_global
    check not kinds.filterIt(it.name == "text")[0].is_global
    check kinds.filterIt(it.name == "buf")[0].kind == NameKind.Parameter
    check kinds.filterIt(it.name == "args")[0].kind == NameKind.Field


  test "words split at underscore and case change":
    check "lut_grade_by_basis".words == @["lut", "grade", "by", "basis"]
    check "wedgeAnti".words == @["wedge", "Anti"]
    check "JSONData".words == @["JSON", "Data"]
    check "toJSON".words == @["to", "JSON"]
    check "rga4d".words == @["rga4d"]
    check "DIRECTORY_SDL3".words == @["DIRECTORY", "SDL3"]


  test "acronyms are capital runs inside camel or Pascal names":
    check "toJSON".acronyms == @["JSON"]
    check "SDL3Window".acronyms == @["SDL3"]
    check "Chiral".acronyms.len == 0 and "isMixed".acronyms.len == 0
    check "DIRECTORY_SDL3".acronyms.len == 0  # screaming holds by reading
    check "rga_visualiser".acronyms.len == 0


  test "glossary gives exemptions from standards spans and terms":
    const G = "# d\n\n## Standards\n\n- **SI**, BIPM, 9th: `s` and `m` (Table 2), so `ms`.\n" &
      "- **Acronyms**, Architect: `3D`, `JSON` and `fps`.\n\n## Language\n\n**Measurand**:\nOne.\n"
    let exempt = G.glossaryExemptions
    for w in ["s", "m", "ms", "3D", "JSON", "fps", "Measurand"]: check w in exempt
    check "BIPM" notin exempt  # owner, not symbol


  test "abbreviation, acronym, verb, lookup and global findings":
    let found = checkNames("x.nim", SOURCE, ["JSON"]).messages
    check found.anyIt("write `directory` (V.6); got `dir_hint`" in it)
    check found.anyIt("write `temporary` (V.6); got `tmp_count`" in it)
    check found.anyIt("got `buf`" in it) and found.anyIt("got `err`" in it)
    check found.anyIt("got `dest`" in it) and found.anyIt("got `args`" in it)
    check found.anyIt("(V.3); got `getGrade`" in it)
    check found.anyIt("(V.10); got `ALGEBRA`" in it)  # shares word with type Algebra
    check not found.anyIt("JSON" in it)  # exempt
    check not found.anyIt("`lut`" in it)  # jargon
    check not found.anyIt("constructTable" in it)
    check checkNames("x.nim", SOURCE, []).messages.anyIt("got `JSON` in `toJSON`" in it)
    check checkNames("y.nim", "let lut_grade = 1\n", []).messages[0].contains("(V.5)")
    check checkNames("y.nim", "let lut_grade_by_basis = 1\n", []).len == 0
    check checkNames("y.nim", "proc get*(x: int) = x\n", []).len == 0  # one word is noun


  test "foreign binding keeps library's name, and its parameters are read":
    const F = "proc getError*(): cstring {.importc: \"SDL_GetError\".}\n" &
      "proc glGetString*(name: GLenum, buf: pointer) {.importc, dynlib: \"GL\".}\n" &
      "proc getShaderiv*(shader: Uint)\n  {.importc: \"glGetShaderiv\", header: H.}\n"
    let found = checkNames("f.nim", F, []).messages
    check not found.anyIt("getError" in it) and not found.anyIt("glGetString" in it)
    check not found.anyIt("getShaderiv" in it)  # pragma on its own line
    check found.anyIt("got `buf`" in it)  # parameter is ours
    check "getError" notin F.names and "buf" in F.names


  test "V.6 abbreviation is spelled out word by word, case kept, exempt words aside":
    check "ctx".respelled([]) == "context"
    check "tmpDir".respelled([]) == "temporaryDirectory"
    check "Cfg".respelled([]) == "Configuration"
    check "CFG_PATH".respelled([]) == "CONFIGURATION_PATH"
    check "dir_hint".respelled([]) == "directory_hint"
    check "dirs".respelled([]) == "dirs"  # plural is other word, outside table
    check "ctx".respelled(["ctx"]) == "ctx"  # glossary admits it
    check "src_dir".respelled([]) == "src_directory"  # jargon of V.6 stays


  test "V.6 rename target is each declaration check reports, at its name's column":
    let
      source = "proc f(ctx: int, b: int) =\n  let tmp = ctx\n  echo tmp\n"
      renames = abbreviationRenames(source, [])
    check renames == @[(1, 7, "ctx", "context"), (2, 6, "tmp", "temporary")]
    check checkNames("a.nim", source, JARGON).len == renames.len  # check reads same set


  test "exemptions are jargon, root glossary and glossary of path's own project":
    let glossaries = @[
      ("GLOSSARY.md", "# R\n\n## Standards\n\n- **S**: `ms`.\n\n## Language\n"),
      ("curator/audit/GLOSSARY.md", "# A\n\n## Standards\n\n- **T**: `px`.\n\n## Language\n"),
      ("curator/probe/GLOSSARY.md", "# P\n\n## Standards\n\n- **U**: `au`.\n\n## Language\n"),
    ]
    let exempt = glossaries.exemptionsOf("curator/audit/src/a.nim")
    check "ms" in exempt and "px" in exempt and "lut" in exempt
    check "au" notin exempt  # other project's glossary
