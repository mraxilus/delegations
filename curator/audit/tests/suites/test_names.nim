## Replicate names check as koch prints it, article where sentence ends, with words glossaries
##   admit; and renames that names check asks of `koch fix`.
##   Check itself is knoller's, and its cases are held in `curator/knoller/tests/suites/
##     test_names.nim`; here each rule renders through `findingsOf`, as static pass prints it.

{.experimental: "strictFuncs".}

import std/[sequtils, unittest]
import ../../../knoller/src/knoller
import ../../src/[findings, names]


const CASES_BROKEN = """
type
  basis_digits = distinct string
  Shape = object
    Width: int
  Space = enum
    base, Anti_Side
const lowerGlobal = 1
proc Construct_table(Count: int) =
  let Local_value = 1
"""
  ## Every kind in case of another kind.
  ##   Copy of same fixture in `curator/knoller/tests/suites/test_names.nim`, whose check reads
  ##     it; fix to one is finished only when other is checked.


func breaches(source: string; exempt: seq[string] = @[]): seq[string] =
  ## Read each message static pass prints for names of source: names check, then entry block.
  findingsOf(checkNames("x.nim", source, exempt) & checkBlockEntry("x.nim", source)).mapIt(
    it.message,
  )



suite "Names":
  test "glossary gives exemptions from standards spans and terms":
    const glossary = "# d\n\n## Standards\n\n- **SI**, BIPM, 9th: `s` and `m` (Table 2), so " &
      "`ms`.\n- **Acronyms**, Architect: `3D`, `JSON` and `fps`.\n\n## Language\n\n" &
      "**Measurand**:\nOne.\n"
    let exempt = glossary.glossaryExemptions
    for w in ["s", "m", "ms", "3D", "JSON", "fps", "Measurand"]: check w in exempt
    check "BIPM" notin exempt  # owner, not symbol
    check "func toJSON() = discard\n".breaches(exempt).len == 0  # V.9, glossary admits it
    check "func toJSON() = discard\n".breaches.len == 1  # V.9, none admits it


  test "each rule of names prints its article where sentence ends, as koch prints it":
    for (source, message) in [
      ("proc f(dir_hint: int) = discard\n",
        "Name coins abbreviation; write `directory` (V.6); got `dir_hint`."),
      ("func toJSON() = discard\n",
        "Acronym stays only where glossary lists it (V.9); got `JSON` in `toJSON`."),
      ("proc getGrade() = discard\n",
        "Action is imperative verb and property is bare noun (V.3); got `getGrade`."),
      ("const LUT_GRADE = 1\n",
        "Lookup table reads `lut_<value>_by_<key>` (V.5); got `LUT_GRADE`."),
      ("func mixed(m: int): bool = true\n",
        "Predicate `func` is `is…` in camel case (V.4); got `mixed`."),
      ("proc f(quiet: bool) = discard\n",
        "Boolean opens `is_`, `as_`, `should_`, `found_` or `has_` (V.4); got `quiet`."),
      ("var 𝐧 = 2\n", "Notation holds over case only for immutable global (III.5); got `𝐧`."),
      ("type basis_digits = int\n", "Type is `PascalCase` (V.1); got `basis_digits`."),
      ("type Space = enum\n  base, Anti\n", "Member is `PascalCase` (V.11); got `base`."),
      ("type Pair[Key, V] = object\n", "Placeholder is one capital letter (V.12); got `Key`."),
      ("type Algebra = int\nconst ALGEBRA = 1\n",
        "Global never shares its word with type (V.10); got `ALGEBRA`."),
      ("when isMainModule:\n  let verb = paramStr(1)\n",
        "Entry block holds no binding; move code that binds into `proc main` (V.10); got " &
        "`verb`."),
    ]:
      check source.breaches == @[message]  # text koch prints


  test "V.6 rename target is each declaration check reports, at its name's column":
    let
      source = "proc f(ctx: int, b: int) =\n  let tmp = ctx\n  echo tmp\n"
      renames = abbreviationRenames(source, [])
    check renames == @[(1, 7, "ctx", "context"), (2, 6, "tmp", "temporary")]
    check checkNames("a.nim", source, JARGON).len == renames.len  # check reads same set


  test "tuple binding declares names before `=` alone, never global its value names":
    const binding = "let (source, destination) = (paths[i], DIR_FONTS / face)\n"
    check binding.declarations.mapIt(it.name) == @["source", "destination"]  # V.6
    check abbreviationRenames(binding, []).len == 0  # V.6, `DIR_FONTS` is use, never declaration


  test "V.1 and V.11 rename target is each case finding, and refusal names what fix cannot prove":
    let renames = renamesCase(CASES_BROKEN, [])
    check renames.len == CASES_BROKEN.breaches.len  # V.1, V.11: check reads same set
    check renames.mapIt((it.name, it.renamed, it.rule)) == @[
      ("basis_digits", "BasisDigits", "type case (V.1)"),
      ("Width", "width", "field case (V.1)"),
      ("base", "Base", "member case (V.11)"),
      ("Anti_Side", "AntiSide", "member case (V.11)"),
      ("lowerGlobal", "LOWER_GLOBAL", "global case (V.1)"),
      ("Count", "count", "parameter case (V.1)"),
      ("Construct_table", "constructTable", "routine case (V.1)"),
      ("Local_value", "local_value", "local case (V.1)"),
    ]  # V.1, V.11
    check renames.filterIt(it.refusal.len > 0).mapIt(it.refusal) == @[
      "`$` of member reads its name", "`$` of member reads its name"]  # V.11
    check renames[5].line == 8 and renames[5].column == 21  # parameter's own token
    const local = "proc run() =\n  const WIDE = 2\n  let TMP_DIR = \"a\"\n" &
      "when isMainModule:\n  let VERB = paramStr(1)\n"
    check renamesCase(local, []).mapIt((it.renamed, it.rule)) == @[
      ("wide", "local constant case (V.1)"),
      ("temporary_directory", "abbreviation (V.6) and local constant case (V.1)"),
      ("verb", "local constant case (V.1)"),
    ]  # V.1, V.6; entry binding takes case of local, where fix moves it (V.10)
    const foreign = "type Def {.importc: \"b3Def\".} = object\n  enableSleep {.importc.}: bool\n" &
      "var counter {.exportc.}: cint\nproc pushAt(Body_id: cint) {.importc: \"b3Push\".}\n" &
      "type Side = enum\n  left = \"left\", Right\nproc Count(Count: int) = discard\n" &
      "proc do_x_y() = discard\nproc f[Key](k: Key) = discard\n"
    check renamesCase(foreign, []).mapIt((it.name, it.refusal)) == @[
      ("enableSleep", "foreign code reads name through `importc`"),
      ("counter", "foreign code reads name through `exportc`"),
      ("Body_id", ""),  # parameter crosses by place
      ("left", ""),  # member carries own string
      ("Count", "line declares `Count` twice"),
      ("Count", "line declares `Count` twice"),
      ("do_x_y", "`doXY` reads `XY` as acronym (V.9)"),
    ]  # V.1, V.11; placeholder `Key` (V.12) has no rename
    check renamesCase("when isMainModule:\n  var COUNT {.global.} = 0\n", []).len == 0  # V.10


  test "exemptions are jargon, root glossary and glossary of path's own project":
    let glossaries = @[
      ("GLOSSARY.md", "# R\n\n## Standards\n\n- **S**: `ms`.\n\n## Language\n"),
      ("curator/audit/GLOSSARY.md", "# A\n\n## Standards\n\n- **T**: `px`.\n\n## Language\n"),
      ("curator/probe/GLOSSARY.md", "# P\n\n## Standards\n\n- **U**: `au`.\n\n## Language\n"),
    ]
    let exempt = glossaries.exemptionsOf("curator/audit/src/a.nim")
    check "ms" in exempt and "px" in exempt and "lut" in exempt
    check "au" notin exempt  # other project's glossary
