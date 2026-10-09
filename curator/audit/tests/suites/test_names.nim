## Replicate names check as koch prints it, article where sentence ends, with words glossaries
##   admit. Renames that names check asks are knoller's, held in its suite.
##   Check itself is knoller's, and its cases are held in `curator/knoller/tests/suites/
##     test_names.nim`; here each rule renders through `findingsOf`, as static pass prints it.
##   Acronym check (V.9) is audit's, since it reads glossaries, so its cases are held here.

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


func breaches(source: string, exempt: seq[string] = @[]): seq[string] =
  ## Read each message static pass prints for names of source: names check, entry block, then
  ##   acronyms.
  let found = findingsOf(checkNames("x.nim", source, exempt) & checkBlockEntry("x.nim", source))
  (found & checkAcronyms("x.nim", source, exempt)).mapIt(it.message)



suite "Names":
  test "glossary gives exemptions from standards spans and terms":
    const glossary = "# d\n\n## Standards\n\n- **SI**, BIPM, 9th: `s` and `m` (Table 2), so " &
        "`ms`.\n- **Acronyms**, Architect: `3D`, `JSON` and `fps`.\n\n## Language\n\n" &
        "**Measurand**:\nOne.\n"
    let exempt = glossary.exemptionsGlossary
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
      ("proc f(a: Basis) =\n  let flags_a = a.toFlags\n",
        "Name holding `a` in another representation leads with `a` (V.2); got `flags_a`."),
      ("when isMainModule:\n  let verb = paramStr(1)\n",
        "Entry block holds no binding; move code that binds into `proc main` (V.10); got " &
        "`verb`."),
    ]:
      check source.breaches == @[message]  # text koch prints


  test "exemptions are jargon, root glossary and glossary of path's own project":
    let glossaries = @[
      ("GLOSSARY.md", "# R\n\n## Standards\n\n- **S**: `ms`.\n\n## Language\n"),
      ("curator/audit/GLOSSARY.md", "# A\n\n## Standards\n\n- **T**: `px`.\n\n## Language\n"),
      ("curator/probe/GLOSSARY.md", "# P\n\n## Standards\n\n- **U**: `au`.\n\n## Language\n"),
    ]
    let exempt = glossaries.exemptionsOf("curator/audit/src/a.nim")
    check "ms" in exempt and "px" in exempt and "lut" in exempt
    check "au" notin exempt  # other project's glossary
